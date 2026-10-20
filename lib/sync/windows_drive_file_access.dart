import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../providers/native_client.dart';
import 'desktop_oauth_flow.dart';
import 'drive_file_access.dart';
import 'google_auth.dart';
import 'sync_protocol.dart';
import 'windows_google_auth.dart';

const _fileScope = 'https://www.googleapis.com/auth/drive.file';

class _RevokedFileGrant extends SyncException {
  const _RevokedFileGrant() : super('drive_file_authorization_required');
}

class _Account {
  const _Account(this.id, this.email, this.epoch);
  final String id, email;
  final int epoch;
}

class _FileSession {
  const _FileSession({
    required this.id,
    required this.email,
    required this.permissionId,
    required this.refreshToken,
    this.accessToken,
    this.expiresAt,
  });
  final String id, email, permissionId, refreshToken;
  final String? accessToken;
  final int? expiresAt;

  String persisted() => jsonEncode({
    'id': id,
    'email': email,
    'permissionId': permissionId,
    'refreshToken': refreshToken,
  });
}

/// The Google Picker's separate, narrow Drive grant for the connected account.
/// Only explicit picker calls open a browser. Background sync can restore and
/// refresh this grant without adding scopes to the appData identity grant.
class WindowsDriveFileAccess implements DriveFileAccessCapability {
  WindowsDriveFileAccess({
    required this.identity,
    required this.clientId,
    this.clientSecret = '',
    DesktopCredentialStore? credentials,
    DesktopOAuthFlow? flow,
    http.Client? client,
    DateTime Function()? clock,
  }) : _credentials = credentials ?? WindowsCredentialStore(),
       _flow = flow ?? DesktopOAuthFlow(),
       _client = client ?? createNativeHttpClient(),
       _clock = clock ?? DateTime.now;

  final DriveAuthorization identity;
  final String clientId, clientSecret;
  final DesktopCredentialStore _credentials;
  final DesktopOAuthFlow _flow;
  final http.Client _client;
  final DateTime Function() _clock;
  late final _FileAuthorization _authorization = _FileAuthorization(this);
  _FileSession? _session;
  Future<void> _writes = Future.value();
  Future<_FileSession?>? _reading;
  String? _readKey;
  int? _readEpoch;
  Future<String>? _refreshing;
  String? _refreshKey;
  int? _refreshEpoch;
  int _epoch = 0;
  bool _picking = false;

  @override
  DriveAuthorization get fileAuthorization => _authorization;

  bool get _configured =>
      identity.configured &&
      RegExp(
        r'^[A-Za-z0-9._-]+\.apps\.googleusercontent\.com$',
      ).hasMatch(clientId);

  String _key(String id) =>
      'google_drive_file_${sha256.convert(utf8.encode('$clientId\u0000$id'))}';

  static String _email(String value) => value.trim().toLowerCase();

  _Account _account() {
    if (!_configured) throw const SyncException('not_configured');
    final id = identity.accountId, email = identity.accountEmail;
    if (!identity.isConnected ||
        id == null ||
        id.isEmpty ||
        email == null ||
        email.trim().isEmpty) {
      throw const SyncException('not_signed_in');
    }
    return _Account(id, email, _epoch);
  }

  bool _current(_Account account) =>
      account.epoch == _epoch &&
      identity.isConnected &&
      identity.accountId == account.id &&
      _email(identity.accountEmail ?? '') == _email(account.email);

  void _check(_Account account) {
    if (!_current(account)) throw const SyncException('cancelled');
  }

  Future<_FileSession?> _load(_Account account) async {
    _check(account);
    final cached = _session;
    if (cached != null &&
        cached.id == account.id &&
        _email(cached.email) == _email(account.email)) {
      return cached;
    }
    final key = _key(account.id);
    if (_readKey == key && _readEpoch == account.epoch && _reading != null) {
      return _reading!;
    }
    final pending = _read(account, key);
    _reading = pending;
    _readKey = key;
    _readEpoch = account.epoch;
    try {
      return await pending;
    } finally {
      if (identical(_reading, pending)) _reading = null;
    }
  }

  Future<_FileSession?> _read(_Account account, String key) async {
    try {
      await _writes;
      _check(account);
      final saved = await _credentials.read(key);
      _check(account);
      if (saved == null || utf8.encode(saved).length > 2560) return null;
      final value = jsonDecode(saved);
      if (value is! Map ||
          value['id'] != account.id ||
          value['email'] is! String ||
          _email(value['email'] as String) != _email(account.email) ||
          value['permissionId'] is! String ||
          (value['permissionId'] as String).isEmpty ||
          value['refreshToken'] is! String ||
          (value['refreshToken'] as String).isEmpty) {
        return null;
      }
      final session = _FileSession(
        id: account.id,
        email: account.email,
        permissionId: value['permissionId'] as String,
        refreshToken: value['refreshToken'] as String,
      );
      _session = session;
      return session;
    } on FormatException {
      return null;
    } on SyncException {
      rethrow;
    } catch (_) {
      throw const SyncException('network');
    }
  }

  Future<void> _queue(Future<void> Function() action) {
    final pending = _writes.then((_) => action());
    _writes = pending.then<void>((_) {}, onError: (Object _) {});
    return pending;
  }

  Future<void> _persist(
    _Account account,
    _FileSession next,
    _FileSession? previous,
  ) {
    final encoded = next.persisted();
    if (utf8.encode(encoded).length > 2560) {
      throw const SyncException('drive_file_authorization_required');
    }
    return _queue(() async {
      _check(account);
      final key = _key(account.id);
      await _credentials.write(key, encoded);
      if (!_current(account)) {
        // Cancellation during an asynchronous vault write must not replace a
        // prior usable grant. A queued clearAccount delete runs after rollback.
        if (previous == null) {
          await _credentials.delete(key);
        } else {
          await _credentials.write(key, previous.persisted());
        }
        throw const SyncException('cancelled');
      }
    });
  }

  @override
  Future<String> pickFolder({String? accountEmail}) async =>
      (await _pick(folders: true, accountEmail: accountEmail)).single;

  @override
  Future<List<String>> pickChordProFiles({String? accountEmail}) =>
      _pick(folders: false, accountEmail: accountEmail);

  Future<List<String>> _pick({
    required bool folders,
    String? accountEmail,
  }) async {
    final initial = _account();
    if (accountEmail != null && _email(accountEmail) != _email(initial.email)) {
      throw const SyncException('drive_file_authorization_required');
    }
    if (_picking) throw const SyncException('sync_in_progress');
    _picking = true;
    // Supersede a pending silent renewal, keeping its old grant until the
    // picker has produced a verified replacement for this exact account.
    ++_epoch;
    final account = _account();
    try {
      final previous = await _load(account);
      final grant = await _flow.pickDriveFiles(
        clientId: clientId,
        accountEmail: account.email,
        folders: folders,
      );
      _check(account);
      final ids = grant.fileIds.toSet().toList();
      if (ids.isEmpty ||
          (folders && ids.length != 1) ||
          ids.any((id) => !RegExp(r'^[A-Za-z0-9_-]{1,256}$').hasMatch(id))) {
        throw SyncException(folders ? 'folder_not_selected' : 'cancelled');
      }
      final tokens = await _tokens({
        'grant_type': 'authorization_code',
        'code': grant.code,
        'code_verifier': grant.verifier,
        'redirect_uri': grant.redirectUri,
      });
      _check(account);
      _scope(tokens, mustBePresent: true);
      final refresh = tokens['refresh_token'];
      if (refresh is! String || refresh.isEmpty) {
        throw const SyncException('drive_file_authorization_required');
      }
      final token = _token(tokens);
      final permission = await _verifyAccount(account, token);
      _check(account);
      if (folders) await _verifyFolder(account, token, ids.single);
      _check(account);
      final next = _FileSession(
        id: account.id,
        email: account.email,
        permissionId: permission,
        refreshToken: refresh,
        accessToken: token,
        expiresAt: _expiry(tokens),
      );
      await _persist(account, next, previous);
      _check(account);
      _session = next;
      return List.unmodifiable(ids);
    } on SyncException {
      rethrow;
    } catch (_) {
      throw const SyncException('network');
    } finally {
      _picking = false;
    }
  }

  Future<String> _accessToken({bool force = false}) async {
    final account = _account();
    final session = await _load(account);
    _check(account);
    if (session == null) {
      throw const SyncException('drive_file_authorization_required');
    }
    if (!force &&
        session.accessToken != null &&
        session.expiresAt != null &&
        session.expiresAt! > _clock().millisecondsSinceEpoch + 60000) {
      return session.accessToken!;
    }
    if (_picking) throw const SyncException('sync_in_progress');
    final key = _key(account.id);
    if (_refreshKey == key &&
        _refreshEpoch == account.epoch &&
        _refreshing != null) {
      return _refreshing!;
    }
    final pending = _renew(account, session);
    _refreshing = pending;
    _refreshKey = key;
    _refreshEpoch = account.epoch;
    try {
      return await pending;
    } finally {
      if (identical(_refreshing, pending)) _refreshing = null;
    }
  }

  Future<String> _renew(_Account account, _FileSession previous) async {
    try {
      final tokens = await _tokens({
        'grant_type': 'refresh_token',
        'refresh_token': previous.refreshToken,
      });
      _check(account);
      _scope(tokens, mustBePresent: false);
      final token = _token(tokens);
      final permission = await _verifyAccount(account, token);
      _check(account);
      if (permission != previous.permissionId) {
        throw const SyncException('drive_file_authorization_required');
      }
      final replacement = tokens['refresh_token'];
      final next = _FileSession(
        id: account.id,
        email: account.email,
        permissionId: permission,
        refreshToken: replacement is String && replacement.isNotEmpty
            ? replacement
            : previous.refreshToken,
        accessToken: token,
        expiresAt: _expiry(tokens),
      );
      await _persist(account, next, previous);
      _check(account);
      _session = next;
      return token;
    } on _RevokedFileGrant {
      if (_current(account) && identical(_session, previous)) {
        _session = null;
        await _queue(() => _credentials.delete(_key(account.id)));
      }
      rethrow;
    } on SyncException {
      rethrow;
    } catch (_) {
      throw const SyncException('network');
    }
  }

  Future<Map<String, dynamic>> _tokens(Map<String, String> body) async {
    final response = await _client
        .post(
          Uri.https('oauth2.googleapis.com', '/token'),
          body: {
            'client_id': clientId,
            if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
            ...body,
          },
        )
        .timeout(const Duration(seconds: 30));
    final value = jsonDecode(response.body);
    if (value is! Map<String, dynamic>) throw const SyncException('network');
    if (response.statusCode != 200) {
      if (value['error'] == 'invalid_grant') throw const _RevokedFileGrant();
      if (value['error'] == 'invalid_client') {
        throw const SyncException('not_configured');
      }
      final errorDescription = value['error_description'];
      if (value['error'] == 'invalid_request' &&
          errorDescription is String &&
          errorDescription.toLowerCase().contains('client_secret')) {
        throw const SyncException('not_configured');
      }
      throw const SyncException('network');
    }
    return value;
  }

  static void _scope(
    Map<String, dynamic> tokens, {
    required bool mustBePresent,
  }) {
    final raw = tokens['scope'];
    if (raw == null && !mustBePresent) return;
    final scopes = raw is String
        ? raw.trim().split(RegExp(r'\s+')).toSet()
        : <String>{};
    if (scopes.length != 1 || !scopes.contains(_fileScope)) {
      throw const SyncException('drive_file_authorization_required');
    }
  }

  static String _token(Map<String, dynamic> tokens) {
    final token = tokens['access_token'];
    if (token is! String ||
        token.isEmpty ||
        tokens['token_type'] is! String ||
        (tokens['token_type'] as String).toLowerCase() != 'bearer') {
      throw const SyncException('network');
    }
    return token;
  }

  int _expiry(Map<String, dynamic> tokens) {
    final seconds = tokens['expires_in'];
    if (seconds is! int || seconds <= 0 || seconds > 86400) {
      throw const SyncException('network');
    }
    return _clock().add(Duration(seconds: seconds)).millisecondsSinceEpoch;
  }

  Future<String> _verifyAccount(_Account account, String token) async {
    _check(account);
    final response = await _client
        .get(
          Uri.https('www.googleapis.com', '/drive/v3/about', {
            'fields': 'user(emailAddress,permissionId)',
          }),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 30));
    _check(account);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const SyncException('drive_file_authorization_required');
    }
    if (response.statusCode != 200) throw const SyncException('network');
    final value = jsonDecode(response.body);
    final user = value is Map ? value['user'] : null;
    if (user is! Map ||
        user['emailAddress'] is! String ||
        _email(user['emailAddress'] as String) != _email(account.email) ||
        user['permissionId'] is! String ||
        (user['permissionId'] as String).isEmpty) {
      throw const SyncException('drive_file_authorization_required');
    }
    return user['permissionId'] as String;
  }

  Future<void> _verifyFolder(_Account account, String token, String id) async {
    final response = await _client
        .get(
          Uri.https('www.googleapis.com', '/drive/v3/files/$id', {
            'fields': 'id,mimeType,trashed',
          }),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 30));
    _check(account);
    if (response.statusCode != 200) {
      throw const SyncException('folder_not_selected');
    }
    final folder = jsonDecode(response.body);
    if (folder is! Map ||
        folder['id'] != id ||
        folder['trashed'] != false ||
        folder['mimeType'] != 'application/vnd.google-apps.folder') {
      throw const SyncException('folder_not_selected');
    }
  }

  /// Signs out the current grant, or removes a captured old account after a
  /// successful identity switch. Deletion follows pending writes so an old
  /// response cannot resurrect its grant.
  Future<void> clearAccount({String? accountId}) async {
    final id = accountId ?? identity.accountId ?? _session?.id;
    cancel();
    _session = null;
    if (id != null) await _queue(() => _credentials.delete(_key(id)));
  }

  /// Cancels consent/renewal without deleting a previously granted session.
  void cancel() {
    ++_epoch;
    _flow.cancel();
  }
}

class _FileAuthorization
    implements DriveAuthorization, RefreshableAuthorization {
  _FileAuthorization(this.owner);
  final WindowsDriveFileAccess owner;
  @override
  bool get configured => owner._configured;
  @override
  bool get isConnected => owner.identity.isConnected;
  @override
  String? get accountId => owner.identity.accountId;
  @override
  String? get accountEmail => owner.identity.accountEmail;
  @override
  Future<void> connect() => owner.identity.connect();
  @override
  Future<bool> restore() => owner.identity.restore();
  @override
  Future<void> disconnect() => owner.identity.disconnect();
  @override
  Future<String> accessToken() => owner._accessToken();
  @override
  Future<String> refreshAccessToken() => owner._accessToken(force: true);
}
