import 'package:flutter/foundation.dart';

import 'drive_file_access.dart';
import 'google_auth.dart';
import 'google_drive_folder_picker.dart';
import 'sync_protocol.dart';

typedef MobileFileAuthorizationBuilder =
    DriveAuthorization Function(DriveAuthorization identity);

typedef _Account = ({String id, String email, int epoch});

/// Pairs Android's Picker and narrow file authorization with the same primary
/// account. No access token or 45-minute delegate cache survives a request.
class MobileDriveFileAccess implements DriveFileAccessCapability {
  MobileDriveFileAccess({
    required this.identity,
    GoogleDriveFolderPicker? picker,
    MobileFileAuthorizationBuilder? authorizationBuilder,
    TargetPlatform? platformOverride,
    bool? isWebOverride,
  }) : _picker = picker ?? GoogleDriveFolderPicker(),
       _authorizationBuilder =
           authorizationBuilder ?? GoogleDriveFileAuthorization.new,
       _platform = platformOverride ?? defaultTargetPlatform,
       _isWeb = isWebOverride ?? kIsWeb;

  final DriveAuthorization identity;
  final GoogleDriveFolderPicker _picker;
  final MobileFileAuthorizationBuilder _authorizationBuilder;
  final TargetPlatform _platform;
  final bool _isWeb;
  late final _MobileFileAuthorization _authorization = _MobileFileAuthorization(
    this,
  );
  final _pending = <(_Account, bool), Future<String>>{};
  int _epoch = 0;
  bool _picking = false;

  bool get available => !_isWeb && _platform == TargetPlatform.android;
  @override
  DriveAuthorization get fileAuthorization => _authorization;

  static String _email(String email) => email.trim().toLowerCase();

  void _ensureAvailable() {
    if (!available) throw const SyncException('folder_picker_unavailable');
  }

  _Account _account({String? accountEmail}) {
    _ensureAvailable();
    if (!identity.configured) throw const SyncException('not_configured');
    final id = identity.accountId, email = identity.accountEmail;
    if (!identity.isConnected ||
        id == null ||
        id.isEmpty ||
        email == null ||
        email.trim().isEmpty) {
      throw const SyncException('not_signed_in');
    }
    if (accountEmail != null && _email(accountEmail) != _email(email)) {
      throw const SyncException('drive_file_authorization_required');
    }
    return (id: id, email: email, epoch: _epoch);
  }

  bool _current(_Account account) =>
      available &&
      identity.configured &&
      identity.isConnected &&
      _epoch == account.epoch &&
      identity.accountId == account.id &&
      _email(identity.accountEmail ?? '') == _email(account.email);

  void _check(_Account account) {
    if (!_current(account)) throw const SyncException('cancelled');
  }

  /// Call before direct primary auth lifecycle actions, including a reconnect
  /// to the same account. It invalidates observations, never the native grant.
  void invalidate() {
    ++_epoch;
    _pending.clear();
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
    _account(accountEmail: accountEmail);
    if (_picking) throw const SyncException('sync_in_progress');
    _picking = true;
    invalidate();
    final account = _account(accountEmail: accountEmail);
    try {
      final ids = folders
          ? [await _picker.pickFolder(accountEmail: account.email)]
          : await _picker.pickChordProFiles(accountEmail: account.email);
      _check(account);
      if (ids.isEmpty) throw const SyncException('cancelled');
      if (ids.length > 10000 ||
          ids.any((id) => !RegExp(r'^[A-Za-z0-9_-]{1,512}$').hasMatch(id))) {
        throw const SyncException('folder_picker_failed');
      }
      return List<String>.unmodifiable(ids.toSet());
    } finally {
      _picking = false;
    }
  }

  Future<String> _token({bool force = false}) async {
    final account = _account();
    final key = (account, force);
    final existing = _pending[key];
    if (existing != null) return existing;
    final pending = _requestToken(account, force);
    _pending[key] = pending;
    try {
      return await pending;
    } finally {
      if (identical(_pending[key], pending)) _pending.remove(key);
    }
  }

  Future<String> _requestToken(_Account account, bool force) async {
    _check(account);
    // A new native delegate bypasses GoogleDriveFileAuthorization's local
    // token cache. Pin its identity arguments before any asynchronous work.
    final delegate = _authorizationBuilder(_PinnedIdentity(this, account));
    final token = force && delegate is RefreshableAuthorization
        ? await (delegate as RefreshableAuthorization).refreshAccessToken()
        : await delegate.accessToken();
    _check(account);
    if (token.isEmpty) {
      throw const SyncException('drive_file_authorization_required');
    }
    return token;
  }
}

class _MobileFileAuthorization
    implements DriveAuthorization, RefreshableAuthorization {
  _MobileFileAuthorization(this.owner);
  final MobileDriveFileAccess owner;
  @override
  bool get configured => owner.available && owner.identity.configured;
  @override
  bool get isConnected => owner.available && owner.identity.isConnected;
  @override
  String? get accountId => owner.available ? owner.identity.accountId : null;
  @override
  String? get accountEmail =>
      owner.available ? owner.identity.accountEmail : null;
  @override
  Future<void> connect() async {
    owner._ensureAvailable();
    owner.invalidate();
    await owner.identity.connect();
  }

  @override
  Future<bool> restore() async {
    owner._ensureAvailable();
    owner.invalidate();
    return owner.identity.restore();
  }

  @override
  Future<void> disconnect() async {
    owner._ensureAvailable();
    owner.invalidate();
    await owner.identity.disconnect();
  }

  @override
  Future<String> accessToken() => owner._token();
  @override
  Future<String> refreshAccessToken() => owner._token(force: true);
}

/// Used only by the file-token delegate, not as a replacement primary auth.
class _PinnedIdentity implements DriveAuthorization {
  _PinnedIdentity(this.owner, this.account);
  final MobileDriveFileAccess owner;
  final _Account account;
  @override
  bool get configured => owner._current(account);
  @override
  bool get isConnected => owner._current(account);
  @override
  String get accountId => account.id;
  @override
  String get accountEmail => account.email;
  @override
  Future<void> connect() =>
      Future<void>.error(const SyncException('authorization_required'));
  @override
  Future<bool> restore() async => owner._current(account);
  @override
  Future<String> accessToken() => Future<String>.error(
    const SyncException('drive_file_authorization_required'),
  );
  @override
  Future<void> disconnect() =>
      Future<void>.error(const SyncException('authorization_required'));
}
