import 'dart:io';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
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
///  * Android needs nothing else natively: `INTERNET` is already declared and
///    the plugin brings its own activity/Play services wiring.
class GoogleDriveAuth implements DriveAuthorization, RefreshableAuthorization {
  GoogleDriveAuth({
    this.serverClientId = const String.fromEnvironment(
      'VERSE_GOOGLE_SERVER_CLIENT_ID',
    ),
    this.iosClientId = const String.fromEnvironment(
      'VERSE_GOOGLE_IOS_CLIENT_ID',
    ),
    this.loadSavedIdentity,
    this.saveSavedIdentity,
    @visibleForTesting this.isAndroidOverride,
    @visibleForTesting this.configuredOverride,
  });
  final String serverClientId, iosClientId;
  final Future<Map<String, String>?> Function()? loadSavedIdentity;
  final Future<void> Function(Map<String, String>?)? saveSavedIdentity;
  final bool? isAndroidOverride;
  final bool? configuredOverride;
  static const scopes = ['https://www.googleapis.com/auth/drive.appdata'];
  bool get _isAndroid => isAndroidOverride ?? Platform.isAndroid;
  static final InitializationGate _gate = InitializationGate();
  GoogleSignInAccount? _account;
  String? _restoredId, _restoredEmail;
  int _epoch = 0;
  int _restoreGeneration = 0;
  Future<void> _identityWrites = Future<void>.value();
  @override
  bool get configured =>
      configuredOverride ??
      (Platform.isAndroid
          ? serverClientId.endsWith('.apps.googleusercontent.com')
          : Platform.isIOS &&
                iosClientId.endsWith('.apps.googleusercontent.com'));
  @override
  bool get isConnected => _account != null || _restoredId != null;
  @override
  String? get accountId => _account?.id ?? _restoredId;
  @override
  String? get accountEmail => _account?.email ?? _restoredEmail;
  Future<void> _initialize() async {
    if (!configured) throw const SyncException('not_configured');
    try {
      await _gate.run(
        () => GoogleSignIn.instance.initialize(
          clientId: Platform.isIOS ? iosClientId : null,
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
        if (epoch == _epoch) await _remember(existing.id, existing.email);
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
      _restoredId = _restoredEmail = null;
      await _remember(account.id, account.email);
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

  /// Never throws: restoring a previous session is a best-effort convenience at
  /// startup and must not be able to break application initialisation.
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
        return true;
      }
      await _initialize();
      final account = await GoogleSignIn.instance
          .attemptLightweightAuthentication();
      if (account == null || !_restoreIsCurrent(epoch, generation)) return false;
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
      authorization = await account.authorizationClient
          .authorizationForScopes(scopes);
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
    _restoredId = _restoredEmail = null;
    await _remember(null, null);
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

  Future<void> _remember(String? id, String? email) async {
    final save = saveSavedIdentity;
    if (save == null) return;
    final identity = id == null || email == null
        ? null
        : {'id': id, 'email': email};
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
