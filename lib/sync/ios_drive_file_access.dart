import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'desktop_oauth_flow.dart';
import 'sync_protocol.dart';
import 'windows_drive_file_access.dart';
import 'windows_google_auth.dart';

/// Reuses the account-bound grant, refresh and migration implementation with
/// an iOS system-browser callback and device-only Keychain storage.
class IOSDriveFileAccess extends WindowsDriveFileAccess {
  IOSDriveFileAccess({
    required super.identity,
    super.clientId = const String.fromEnvironment('VERSE_GOOGLE_IOS_CLIENT_ID'),
    DesktopCredentialStore? credentials,
    IOSPickerOAuthFlow? flow,
  }) : super(
         credentials: credentials ?? WindowsCredentialStore(),
         flow: flow ?? IOSPickerOAuthFlow(),
       );
}

/// Google's native mobile Picker uses drive.file alone and returns selected
/// IDs with an authorization code. OAuth state and PKCE bind that code to this
/// request. The shared grant layer validates the actual Drive account/folder
/// before saving tokens or adopting files; login_hint is not identity proof.
class IOSPickerOAuthFlow extends DesktopOAuthFlow {
  IOSPickerOAuthFlow({
    this._channel = const MethodChannel('org.freevia.singbook/oauth_browser'),
    super.timeout,
  });

  final MethodChannel _channel;
  bool _busy = false;
  int _epoch = 0;

  static String _nonce() => base64Url
      .encode(List.generate(32, (_) => Random.secure().nextInt(256)))
      .replaceAll('=', '');

  @override
  Future<DesktopPickerGrant> pickDriveFiles({
    required String clientId,
    required String accountEmail,
    bool folders = false,
  }) async {
    if (_busy) throw const SyncException('sync_in_progress');
    if (!RegExp(
      r'^[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$',
    ).hasMatch(clientId)) {
      throw const SyncException('not_configured');
    }
    _busy = true;
    final epoch = ++_epoch;
    final state = _nonce(), verifier = _nonce();
    final scheme = clientId.split('.').reversed.join('.');
    final redirect = '$scheme:/oauthredirect';
    final request = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': redirect,
      'response_type': 'code',
      'scope': 'https://www.googleapis.com/auth/drive.file',
      'access_type': 'offline',
      'include_granted_scopes': 'false',
      'prompt': 'consent',
      'trigger_onepick': 'true',
      'login_hint': accountEmail,
      'allow_multiple': folders ? 'false' : 'true',
      if (folders) 'allow_folder_selection': 'true',
      if (folders) 'mimetypes': 'application/vnd.google-apps.folder',
      'state': state,
      'code_challenge': base64Url
          .encode(sha256.convert(utf8.encode(verifier)).bytes)
          .replaceAll('=', ''),
      'code_challenge_method': 'S256',
    });
    try {
      final raw = await _channel
          .invokeMethod<String>('authorize', {
            'url': request.toString(),
            'callbackScheme': scheme,
          })
          .timeout(
            timeout,
            onTimeout: () {
              cancel();
              throw const SyncException('cancelled');
            },
          );
      if (epoch != _epoch || raw == null) {
        throw const SyncException('cancelled');
      }
      final callback = Uri.tryParse(raw);
      if (callback == null ||
          callback.scheme != scheme ||
          callback.hasAuthority ||
          callback.path != '/oauthredirect' ||
          callback.hasFragment) {
        throw const SyncException('drive_file_authorization_required');
      }
      final query = callback.queryParametersAll;
      if (query['state']?.length != 1 ||
          query['state']!.single != state ||
          query.values.any((values) => values.length != 1)) {
        throw const SyncException('drive_file_authorization_required');
      }
      if (query.containsKey('error')) {
        throw SyncException(
          query['error']!.single == 'access_denied'
              ? 'cancelled'
              : 'drive_file_authorization_required',
        );
      }
      final code = query['code']?.single;
      if (code == null || code.isEmpty) {
        throw const SyncException('drive_file_authorization_required');
      }
      final ids =
          query['picked_file_ids']?.single
              .split(',')
              .where((id) => id.isNotEmpty)
              .toList() ??
          const <String>[];
      return (
        code: code,
        verifier: verifier,
        redirectUri: redirect,
        fileIds: ids,
      );
    } on PlatformException catch (error) {
      throw SyncException(switch (error.code) {
        'cancelled' => 'cancelled',
        'busy' => 'sync_in_progress',
        'not_configured' => 'not_configured',
        _ => 'drive_file_authorization_required',
      });
    } finally {
      _busy = false;
    }
  }

  @override
  void cancel() {
    ++_epoch;
    unawaited(_channel.invokeMethod<void>('cancel').catchError((Object _) {}));
  }
}
