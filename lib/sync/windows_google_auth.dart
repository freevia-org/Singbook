import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../providers/native_client.dart';
import 'desktop_oauth_flow.dart';
import 'drive_file_access.dart';
import 'google_auth.dart';
import 'sync_protocol.dart';
import 'windows_drive_file_access.dart';

class _InvalidOAuthGrant extends SyncException {
  const _InvalidOAuthGrant() : super('authorization_required');
}

/// Tokens and identity are stored together in the current Windows user's
/// Credential Manager, separately from the portable library and its backups.
abstract interface class DesktopCredentialStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class WindowsCredentialStore implements DesktopCredentialStore {
  static const _channel = MethodChannel(
    'org.freevia.singbook/secure_credentials',
  );
  @override
  Future<String?> read(String key) =>
      _channel.invokeMethod<String>('read', {'key': key});
  @override
  Future<void> write(String key, String value) =>
      _channel.invokeMethod<void>('write', {'key': key, 'value': value});
  @override
  Future<void> delete(String key) =>
      _channel.invokeMethod<void>('delete', {'key': key});
}

class WindowsGoogleDriveAuth
    implements
        DriveAuthorization,
        RefreshableAuthorization,
        ProfilePhotoAuthorization,
        DriveFileAccessCapability {
  WindowsGoogleDriveAuth({
    this.clientId = const String.fromEnvironment(
      'SINGBOOK_GOOGLE_DESKTOP_CLIENT_ID',
    ),
    this.clientSecret = const String.fromEnvironment(
      'SINGBOOK_GOOGLE_DESKTOP_CLIENT_SECRET',
    ),
    DesktopCredentialStore? credentials,
    DesktopOAuthFlow? flow,
    http.Client? client,
    DateTime Function()? clock,
  }) : _credentials = credentials ?? WindowsCredentialStore(),
       _flow = flow ?? DesktopOAuthFlow(),
       _client = client ?? createNativeHttpClient(),
       _clock = clock ?? DateTime.now;

  final String clientId, clientSecret;
  final DesktopCredentialStore _credentials;
  final DesktopOAuthFlow _flow;
  final http.Client _client;
  final DateTime Function() _clock;
  static const scopes = [
    ...GoogleDriveAuth.scopes,
    'openid',
    'email',
    'profile',
  ];
  Map<String, dynamic>? _session;
  Future<void> _writes = Future.value();
  Future<String>? _refresh;
  Future<bool>? _restore;
  Future<void>? _disconnect;
  bool _connecting = false;
  int _epoch = 0;
  WindowsDriveFileAccess? _files;

  WindowsDriveFileAccess get _fileAccess => _files ??= WindowsDriveFileAccess(
    identity: this,
    clientId: clientId,
    clientSecret: clientSecret,
    credentials: _credentials,
    flow: _flow,
    client: _client,
    clock: _clock,
  );

  @override
  DriveAuthorization get fileAuthorization => _fileAccess.fileAuthorization;

  @override
  Future<String> pickFolder({String? accountEmail}) =>
      _fileAccess.pickFolder(accountEmail: accountEmail);

  @override
  Future<List<String>> pickChordProFiles({String? accountEmail}) =>
      _fileAccess.pickChordProFiles(accountEmail: accountEmail);

  String get _key => 'google_drive_${sha256.convert(utf8.encode(clientId))}';
  @override
  bool get configured => RegExp(
    r'^[A-Za-z0-9._-]+\.apps\.googleusercontent\.com$',
  ).hasMatch(clientId);
  @override
  bool get isConnected => _session != null;
  @override
  String? get accountId => _session?['id'] as String?;
  @override
  String? get accountEmail => _session?['email'] as String?;
  @override
  String? get accountPhotoUrl => _session?['photoUrl'] as String?;

  Future<void> _write(Map<String, dynamic>? session) async {
    // Cache access tokens in memory, keeping large JWTs out of the vault blob.
    final persisted = session == null
        ? null
        : <String, dynamic>{
            'id': session['id'],
            'email': session['email'],
            'refreshToken': session['refreshToken'],
            if (session['photoUrl'] case final String photo
                when photo.length <= 512)
              'photoUrl': photo,
          };
    final write = _writes
        .catchError((Object _) {})
        .then(
          (_) => session == null
              ? _credentials.delete(_key)
              : _credentials.write(_key, jsonEncode(persisted)),
        );
    _writes = write;
    await write;
  }

  @override
  Future<void> connect() async {
    if (!configured) throw const SyncException('not_configured');
    if (_connecting || _disconnect != null) {
      throw const SyncException('sync_busy');
    }
    _connecting = true;
    final epoch = ++_epoch;
    try {
      final grant = await _flow.authorize(clientId: clientId, scopes: scopes);
      if (epoch != _epoch) throw const SyncException('cancelled');
      final tokens = await _tokens({
        'grant_type': 'authorization_code',
        'code': grant.code,
        'code_verifier': grant.verifier,
        'redirect_uri': grant.redirectUri,
      });
      final granted = (tokens['scope'] as String? ?? '').split(' ').toSet();
      // Google can canonicalize email/profile aliases in the token response.
      if (!granted.containsAll(GoogleDriveAuth.scopes) ||
          !granted.contains('openid')) {
        throw const SyncException('authorization_required');
      }
      final refreshToken = tokens['refresh_token'];
      if (refreshToken is! String || refreshToken.isEmpty) {
        throw const SyncException('authorization_required');
      }
      final token = _accessToken(tokens);
      final response = await _client
          .get(
            Uri.https('openidconnect.googleapis.com', '/v1/userinfo'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw const SyncException('sign_in_failed');
      }
      final identity = jsonDecode(response.body) as Map<String, dynamic>;
      if (identity['sub'] is! String ||
          (identity['sub'] as String).isEmpty ||
          identity['email'] is! String ||
          (identity['email'] as String).isEmpty ||
          identity['email_verified'] != true) {
        throw const SyncException('sign_in_failed');
      }
      if (epoch != _epoch) throw const SyncException('cancelled');
      final previousAccount = accountId;
      final session = <String, dynamic>{
        'id': identity['sub'],
        'email': identity['email'],
        if (identity['picture'] is String) 'photoUrl': identity['picture'],
        'refreshToken': refreshToken,
        'accessToken': token,
        'expiresAt': _expiry(tokens),
      };
      await _write(session);
      if (epoch != _epoch) throw const SyncException('cancelled');
      _session = session;
      if (previousAccount != null && previousAccount != accountId) {
        // Keep the old grant usable if persisting the new primary identity
        // fails. Cleanup targets its captured key after the switch commits.
        await _fileAccess.clearAccount(accountId: previousAccount);
      }
    } on SyncException {
      rethrow;
    } catch (_) {
      throw const SyncException('sign_in_failed');
    } finally {
      _connecting = false;
    }
  }

  @override
  Future<bool> restore() =>
      _restore ??= _restoreSession().whenComplete(() => _restore = null);

  Future<bool> _restoreSession() async {
    if (!configured) return false;
    if (_session != null) return _validateRestoredSession();
    final epoch = _epoch;
    try {
      await _writes;
      final saved = await _credentials.read(_key);
      if (saved == null || epoch != _epoch) return false;
      final session = jsonDecode(saved) as Map<String, dynamic>;
      if (['id', 'email', 'refreshToken'].any(
        (key) => session[key] is! String || (session[key] as String).isEmpty,
      )) {
        return false;
      }
      if (session['photoUrl'] != null && session['photoUrl'] is! String) {
        return false;
      }
      if (epoch != _epoch) return false;
      _session = session;
      return _validateRestoredSession();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _validateRestoredSession() async {
    try {
      await accessToken();
      return _session != null;
    } on SyncException catch (error) {
      // Offline restoration retains identity. A revoked grant was invalidated
      // by refresh, letting the explicit Connect action reopen the browser.
      return error.code == 'network' && _session != null;
    }
  }

  @override
  Future<String> accessToken() async {
    final session = _session;
    if (session == null) throw const SyncException('not_signed_in');
    final expires = session['expiresAt'];
    if (session['accessToken'] is String &&
        expires is int &&
        expires > _clock().millisecondsSinceEpoch + 60000) {
      return session['accessToken'] as String;
    }
    return refreshAccessToken();
  }

  @override
  Future<String> refreshAccessToken() {
    if (_session == null) {
      return Future.error(const SyncException('not_signed_in'));
    }
    return _refresh ??= _refreshToken().whenComplete(() => _refresh = null);
  }

  Future<String> _refreshToken() async {
    final session = _session!;
    final epoch = _epoch;
    try {
      final tokens = await _tokens({
        'grant_type': 'refresh_token',
        'refresh_token': session['refreshToken'] as String,
      });
      if (epoch != _epoch) throw const SyncException('not_signed_in');
      final token = _accessToken(tokens);
      final updated = {
        ...session,
        'accessToken': token,
        'expiresAt': _expiry(tokens),
        if (tokens['refresh_token'] is String)
          'refreshToken': tokens['refresh_token'],
      };
      await _write(updated);
      if (epoch != _epoch) throw const SyncException('not_signed_in');
      _session = updated;
      return token;
    } on SyncException catch (error) {
      if (error is _InvalidOAuthGrant && epoch == _epoch) {
        try {
          await _fileAccess.clearAccount();
        } finally {
          if (epoch == _epoch) {
            _session = null;
            await _write(null);
          }
        }
      }
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
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      if (error['error'] == 'invalid_grant') {
        throw const _InvalidOAuthGrant();
      }
      if (error['error'] == 'invalid_client') {
        throw const SyncException('oauth_client_configuration');
      }
      // An explicit response that diagnoses a missing client_secret is a
      // client configuration error. Desktop OAuth secrets are optional in
      // general; do not infer this from a generic invalid_request. Never
      // include the remote description in app state or logs.
      final errorDescription = error['error_description'];
      if (error['error'] == 'invalid_request' &&
          errorDescription is String &&
          errorDescription.toLowerCase().contains('client_secret')) {
        throw const SyncException('oauth_client_configuration');
      }
      throw const SyncException('network');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _accessToken(Map<String, dynamic> tokens) {
    final token = tokens['access_token'];
    if (token is! String || token.isEmpty || tokens['token_type'] != 'Bearer') {
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

  @override
  Future<void> disconnect() => _disconnect ??= _disconnectSession()
      .whenComplete(() => _disconnect = null);

  Future<void> _disconnectSession() async {
    ++_epoch;
    _flow.cancel();
    final refreshToken = _session?['refreshToken'];
    final clearFiles = _fileAccess.clearAccount();
    _session = null;
    // Queue both deletions before yielding so a later reconnect writes after
    // them rather than having its new identity erased by this sign-out.
    final clearPrimary = _write(null);
    await Future.wait<void>([clearFiles, clearPrimary]);
    if (refreshToken is! String) return;
    try {
      await _client
          .post(
            Uri.https('oauth2.googleapis.com', '/revoke'),
            body: {'token': refreshToken},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Local sign-out remains complete when revocation is temporarily offline.
    }
  }
}
