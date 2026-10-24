import 'dart:io';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:flutter/services.dart';
import 'sync_protocol.dart';

abstract interface class DriveAuthorization {
  bool get configured;
  bool get isConnected;
  String? get accountId;
  String? get accountEmail;
  Future<void> connect();
  Future<bool> restore();
  Future<String> accessToken();
  Future<void> disconnect();
}

/// Optional capability: an authorization that can discard a rejected (HTTP 401)
/// token and silently obtain a new one. Kept separate so existing
/// [DriveAuthorization] implementations stay valid.
abstract interface class RefreshableAuthorization {
  Future<String> refreshAccessToken();
}

/// Optional identity detail used to show the connected Google account.
abstract interface class ProfilePhotoAuthorization {
  String? get accountPhotoUrl;
}

/// Runs an initializer at most once *successfully*: a failure is not cached,
/// so a transient error (no network, Play services busy) can be retried.
class InitializationGate {
  Future<void>? _pending;
  Future<void> run(Future<void> Function() initialize) {
    final existing = _pending;
    if (existing != null) return existing;
    // Future() defers the call, so _pending is assigned before it can fail.
    final attempt = Future<void>(initialize);
    _pending = attempt;
    attempt.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_pending, attempt)) _pending = null;
      },
    );
    return attempt;
  }

  bool get started => _pending != null;
}

/// Google sign-in for Drive appData access (`google_sign_in` 7.x).
///
/// No confidential client secret and no backend. OAuth registration identifiers
/// are public application configuration, not credentials for a shared account.
///
/// Identifiers (all in one Google Cloud project, see
/// docs/google-oauth-setup.md and lib/sync/SETUP.md):
///  * Android: an *Android* OAuth client (package `org.freevia.singbook` + the
///    SHA-1 of each signing certificate) must exist, but its id is never passed
///    to the app. What the app needs is the id of a *Web application* OAuth
///    client in the same project: `--dart-define=VERSE_GOOGLE_SERVER_CLIENT_ID`
///    (passed as `serverClientId`; Credential Manager rejects sign-in without
///    it).
///  * iOS: an *iOS* OAuth client for the bundle id:
///    `--dart-define=VERSE_GOOGLE_IOS_CLIENT_ID` (passed as `clientId`), plus
///    the reversed client id URL scheme in `Info.plist`.
///  * macOS: an iOS-type OAuth client for the shared Apple bundle id. Use
///    `VERSE_GOOGLE_MACOS_CLIENT_ID` when supplied, otherwise reuse
///    `VERSE_GOOGLE_IOS_CLIENT_ID` (Google documents iOS OAuth client IDs for
///    both iOS and macOS applications).
///  * Android needs nothing else natively: `INTERNET` is already declared and
///    the plugin brings its own activity/Play services wiring.
class GoogleDriveAuth
    implements
        DriveAuthorization,
        RefreshableAuthorization,
        ProfilePhotoAuthorization {
  GoogleDriveAuth({
    this.serverClientId = const String.fromEnvironment(
      'VERSE_GOOGLE_SERVER_CLIENT_ID',
    ),
    this.iosClientId = const String.fromEnvironment(
      'VERSE_GOOGLE_IOS_CLIENT_ID',
    ),
    this.macosClientId = const String.fromEnvironment(
      'VERSE_GOOGLE_MACOS_CLIENT_ID',
    ),
    @visibleForTesting this.isMacOSOverride,
    this.loadSavedIdentity,
    this.saveSavedIdentity,
    @visibleForTesting this.isAndroidOverride,
    @visibleForTesting this.configuredOverride,
  });
  final String serverClientId, iosClientId, macosClientId;
  final bool? isMacOSOverride;
  final Future<Map<String, String>?> Function()? loadSavedIdentity;
  final Future<void> Function(Map<String, String>?)? saveSavedIdentity;
  final bool? isAndroidOverride;
  final bool? configuredOverride;
  static const scopes = ['https://www.googleapis.com/auth/drive.appdata'];
  static const driveFileScopes = ['https://www.googleapis.com/auth/drive.file'];
  String get _appleClientId =>
      macosClientId.endsWith('.apps.googleusercontent.com')
      ? macosClientId
      : iosClientId;
  bool get _isAndroid => isAndroidOverride ?? Platform.isAndroid;
  bool get _isMacOS => isMacOSOverride ?? Platform.isMacOS;
  static final InitializationGate _gate = InitializationGate();
  GoogleSignInAccount? _account;
  String? _restoredId, _restoredEmail, _restoredPhotoUrl;
  int _epoch = 0;
  int _restoreGeneration = 0;
  Future<void> _identityWrites = Future<void>.value();
  @override
  bool get configured =>
      configuredOverride ??
      (_isAndroid
          ? serverClientId.endsWith('.apps.googleusercontent.com')
          : (Platform.isIOS &&
                    iosClientId.endsWith('.apps.googleusercontent.com')) ||
                (_isMacOS &&
                    _appleClientId.endsWith('.apps.googleusercontent.com')));
  @override
  bool get isConnected => _account != null || _restoredId != null;
  @override
  String? get accountId => _account?.id ?? _restoredId;
  @override
  String? get accountEmail => _account?.email ?? _restoredEmail;
  @override
  String? get accountPhotoUrl => _account?.photoUrl ?? _restoredPhotoUrl;
  Future<void> _initialize() async {
    if (!configured) throw const SyncException('not_configured');
    try {
      await _gate.run(
        () => GoogleSignIn.instance.initialize(
          clientId: Platform.isIOS
              ? iosClientId
              : (_isMacOS ? _appleClientId : null),
          serverClientId: serverClientId.isEmpty ? null : serverClientId,
        ),
      );
    } catch (_) {
      throw const SyncException('sign_in_failed');
    }
  }

  @override
  Future<void> connect() async {
    final epoch = ++_epoch;
    ++_restoreGeneration;
    await _initialize();
    final existing = _account;
    if (existing != null) {
      // Restored session whose authorization lapsed: re-consent for the same
      // account without asking the user to pick it again.
      try {
        await existing.authorizationClient.authorizeScopes(scopes);
        if (epoch == _epoch) {
          await _remember(existing.id, existing.email, existing.photoUrl);
        }
        return;
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          throw const SyncException('cancelled');
        }
      } catch (_) {}
    }
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: scopes,
      );
      // This method is called from a user gesture, so any consent prompt is
      // attached to the explicit Connect action rather than a background sync.
      await account.authorizationClient.authorizeScopes(scopes);
      if (epoch != _epoch) return;
      _account = account;
      _restoredId = _restoredEmail = _restoredPhotoUrl = null;
      await _remember(account.id, account.email, account.photoUrl);
    } on GoogleSignInException catch (e) {
      throw SyncException(
        e.code == GoogleSignInExceptionCode.canceled
            ? 'cancelled'
            : 'sign_in_failed',
      );
    } on SyncException {
      rethrow;
    } catch (_) {
      throw const SyncException('sign_in_failed');
    }
  }

  /// Never throws: restoring a previous session is a best-effort convenience
  /// used only after an explicit account action.
  @override
  Future<bool> restore() async {
    final epoch = _epoch;
    final generation = ++_restoreGeneration;
    try {
      if (_account != null) return true;
      if (!configured) return false;
      if (_isAndroid) {
        final identity = await loadSavedIdentity?.call();
        if (!_restoreIsCurrent(epoch, generation)) return false;
        final id = identity?['id'], email = identity?['email'];
        if (id == null || id.isEmpty || email == null || email.isEmpty) {
          return false;
        }
        await _initialize();
        final tokens = await _androidTokens(id: id, email: email);
        if (tokens == null ||
            !_restoreIsCurrent(epoch, generation) ||
            _account != null) {
          return false;
        }
        _restoredId = id;
        _restoredEmail = email;
        _restoredPhotoUrl = identity?['photoUrl'];
        return true;
      }
      await _initialize();
      final account = await GoogleSignIn.instance
          .attemptLightweightAuthentication();
      if (account == null || !_restoreIsCurrent(epoch, generation)) {
        return false;
      }
      // Signed in even if the access token needs user interaction to renew:
      // the first request then reports `authorization_required` and the UI
      // offers to sign in again, instead of silently losing the account.
      _account = account;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Only a lapsed grant / needed user interaction is `authorization_required`
  /// (it stops automatic sync until the user reconnects). Every other failure
  /// (offline, Play services busy, platform timeout, interrupted) is transient
  /// and reported as `network`, so the back-off retry applies.
  @visibleForTesting
  static SyncException mapAuthorizationFailure(Object error) {
    if (error is SyncException) return error;
    if (error is GoogleSignInException) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.userMismatch:
        case GoogleSignInExceptionCode.uiUnavailable:
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          return const SyncException('authorization_required');
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.unknownError:
          return const SyncException('network');
      }
    }
    return const SyncException('network');
  }

  @override
  Future<String> accessToken() async {
    final account = _account;
    if (account == null && _restoredId != null && _isAndroid) {
      try {
        final tokens = await _androidTokens();
        if (tokens == null) throw const SyncException('authorization_required');
        return tokens.accessToken;
      } catch (error) {
        throw mapAuthorizationFailure(error);
      }
    }
    if (account == null) throw const SyncException('not_signed_in');
    final GoogleSignInClientAuthorization? authorization;
    try {
      authorization = await account.authorizationClient.authorizationForScopes(
        scopes,
      );
    } catch (error) {
      throw mapAuthorizationFailure(error);
    }
    if (authorization == null) {
      throw const SyncException('authorization_required');
    }
    return authorization.accessToken;
  }

  /// Drops the token Drive rejected and silently asks the platform for a new
  /// one. It never shows UI; if consent is gone the user must press Connect.
  @override
  Future<String> refreshAccessToken() async {
    final account = _account;
    if (account == null && _restoredId != null && _isAndroid) {
      try {
        final stale = await _androidTokens();
        if (stale != null) {
          await GoogleSignInPlatform.instance.clearAuthorizationToken(
            ClearAuthorizationTokenParams(accessToken: stale.accessToken),
          );
        }
      } catch (_) {}
      return accessToken();
    }
    if (account == null) throw const SyncException('not_signed_in');
    try {
      final stale = await account.authorizationClient.authorizationForScopes(
        scopes,
      );
      if (stale != null) {
        await account.authorizationClient.clearAuthorizationToken(
          accessToken: stale.accessToken,
        );
      }
    } catch (_) {
      // Clearing is best effort; fetching below decides the outcome.
    }
    return accessToken();
  }

  @override
  Future<void> disconnect() async {
    // Sign out from this device; never delete the user's Drive files or the
    // local library. The grant is revoked on a best-effort basis so a later
    // sign-in asks for consent again; a failure (offline) falls back to a
    // plain sign-out.
    final account = _account;
    final restoredId = _restoredId, restoredEmail = _restoredEmail;
    ++_epoch;
    ++_restoreGeneration;
    _account = null;
    _restoredId = _restoredEmail = _restoredPhotoUrl = null;
    await _remember(null, null, null);
    if (!_gate.started) return;
    try {
      final authorization = await account?.authorizationClient
          .authorizationForScopes(scopes);
      if (authorization != null) {
        await account!.authorizationClient.clearAuthorizationToken(
          accessToken: authorization.accessToken,
        );
      } else if (restoredId != null && restoredEmail != null && _isAndroid) {
        final authorization = await _androidTokens(
          id: restoredId,
          email: restoredEmail,
        );
        if (authorization != null) {
          await GoogleSignInPlatform.instance.clearAuthorizationToken(
            ClearAuthorizationTokenParams(
              accessToken: authorization.accessToken,
            ),
          );
        }
      }
    } catch (_) {}
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // The local session is dropped regardless of the platform result.
      }
    }
  }

  Future<void> _remember(String? id, String? email, String? photoUrl) async {
    final save = saveSavedIdentity;
    if (save == null) return;
    final identity = id == null || email == null
        ? null
        : {'id': id, 'email': email, 'photoUrl': ?photoUrl};
    final write = _identityWrites
        .catchError((Object _) {})
        .then<void>((_) => save(identity));
    _identityWrites = write;
    await write;
  }

  bool _restoreIsCurrent(int epoch, int generation) =>
      epoch == _epoch && generation == _restoreGeneration;

  Future<ClientAuthorizationTokenData?> _androidTokens({
    String? id,
    String? email,
  }) => GoogleSignInPlatform.instance.clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters(
      request: AuthorizationRequestDetails(
        scopes: scopes,
        userId: id ?? _restoredId,
        email: email ?? _restoredEmail,
        promptIfUnauthorized: false,
      ),
    ),
  );
}

/// Authorization for the one visible folder granted through Google Picker.
/// Kept separate from `drive.appdata`: Google's mobile Picker flow requires
/// the `drive.file` scope on its own.
class GoogleDriveFileAuthorization
    implements DriveAuthorization, RefreshableAuthorization {
  GoogleDriveFileAuthorization(this.identity);
  final DriveAuthorization identity;
  static const _channel = MethodChannel('org.freevia.singbook/rich_clipboard');
  static const _tokenCacheDuration = Duration(minutes: 45);
  String? _cachedToken;
  DateTime? _tokenValidUntil;
  Future<String>? _tokenRequest;
  bool _tokenRequestForced = false;

  @override
  bool get configured => identity.configured;
  @override
  bool get isConnected => identity.isConnected;
  @override
  String? get accountId => identity.accountId;
  @override
  String? get accountEmail => identity.accountEmail;
  @override
  Future<void> connect() => identity.connect();
  @override
  Future<bool> restore() => identity.restore();
  @override
  Future<void> disconnect() => identity.disconnect();

  @override
  Future<String> accessToken() => _accessToken();

  @override
  Future<String> refreshAccessToken() => _accessToken(force: true);

  Future<String> _accessToken({bool force = false}) async {
    if (!identity.isConnected) throw const SyncException('not_signed_in');
    final cached = _cachedToken;
    if (!force &&
        cached != null &&
        _tokenValidUntil?.isAfter(DateTime.now()) == true) {
      return cached;
    }
    final pending = _tokenRequest;
    if (pending != null) {
      if (!force || _tokenRequestForced) return pending;
      // A rejected token needs a real native renewal, even when an ordinary
      // token lookup was already in flight. Concurrent force calls then share
      // the one forced request started after this ordinary lookup settles.
      try {
        await pending;
      } catch (_) {
        // The explicit forced lookup still gets its own native attempt.
      }
      return _accessToken(force: true);
    }
    final request = _requestAccessToken(force: force);
    _tokenRequest = request;
    _tokenRequestForced = force;
    try {
      final token = await request;
      _cachedToken = token;
      _tokenValidUntil = DateTime.now().add(_tokenCacheDuration);
      return token;
    } finally {
      if (identical(_tokenRequest, request)) _tokenRequest = null;
    }
  }

  Future<String> _requestAccessToken({required bool force}) async {
    try {
      final token = await _channel.invokeMethod<String>(
        'driveFileAccessToken',
        {
          'accountEmail': identity.accountEmail,
          if (force) 'forceRefresh': true,
        },
      );
      if (token == null || token.isEmpty) {
        throw const SyncException('drive_file_authorization_required');
      }
      return token;
    } on PlatformException catch (error) {
      throw SyncException(switch (error.code) {
        'authorization_required' => 'drive_file_authorization_required',
        'account_mismatch' => 'drive_file_authorization_required',
        'cancelled' => 'cancelled',
        _ => 'network',
      });
    }
  }
}
