import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/sync/desktop_oauth_flow.dart';
import 'package:singbook/sync/drive_file_access.dart';
import 'package:singbook/sync/google_auth.dart';
import 'package:singbook/sync/sync_protocol.dart';
import 'package:singbook/sync/windows_google_auth.dart';

class _MemoryCredentials implements DesktopCredentialStore {
  final values = <String, String>{};
  Completer<void>? readWait;
  Completer<void>? deleteWait;
  Completer<void>? deleteStarted;
  String? failPrimaryWriteId;
  int reads = 0;
  @override
  Future<String?> read(String key) async {
    reads++;
    final snapshot = values[key];
    await readWait?.future;
    return snapshot;
  }

  @override
  Future<void> write(String key, String value) async {
    if (utf8.encode(value).length > 2560) throw StateError('vault_blob_limit');
    if (failPrimaryWriteId != null &&
        !key.startsWith('google_drive_file_') &&
        (jsonDecode(value) as Map<String, dynamic>)['id'] ==
            failPrimaryWriteId) {
      throw StateError('vault_write_failed');
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (deleteStarted?.isCompleted == false) deleteStarted!.complete();
    await deleteWait?.future;
    values.remove(key);
  }
}

Matcher code(String value) =>
    isA<SyncException>().having((e) => e.code, 'code', value);

class _PrimaryFileFixture {
  static const clientId = 'desktop.apps.googleusercontent.com';
  static const fileScope = 'https://www.googleapis.com/auth/drive.file';
  final vault = _MemoryCredentials();
  final browserUrls = <Uri>[];
  String id = 'primary-account';
  String email = 'primary@example.com';
  bool denyPrimary = false;
  bool revokePrimary = false;
  int primaryRefreshes = 0;
  int fileRefreshes = 0;
  int aboutRequests = 0;
  Completer<void>? fileRefreshGate;
  Completer<void>? fileRefreshStarted;
  Completer<void>? revokeGate;
  Completer<void>? revokeStarted;

  late final client = MockClient((request) async {
    expect(request.url.scheme, 'https');
    if (request.url.path == '/v1/userinfo') {
      expect(request.headers['Authorization'], 'Bearer primary-access');
      return http.Response(
        jsonEncode({'sub': id, 'email': email, 'email_verified': true}),
        200,
      );
    }
    if (request.url.path == '/drive/v3/about') {
      aboutRequests++;
      expect(
        request.headers['Authorization'],
        anyOf('Bearer file-access', 'Bearer file-renewed'),
      );
      expect(
        request.url.queryParameters['fields'],
        'user(emailAddress,permissionId)',
      );
      return http.Response(
        jsonEncode({
          'user': {'emailAddress': email, 'permissionId': 'permission-$id'},
        }),
        200,
      );
    }
    if (request.url.path == '/drive/v3/files/selected-folder') {
      return http.Response(
        '{"id":"selected-folder","mimeType":"application/vnd.google-apps.folder","trashed":false}',
        200,
      );
    }
    if (request.url.path == '/revoke') {
      revokeStarted?.complete();
      await revokeGate?.future;
      return http.Response('', 200);
    }
    expect(request.url.path, '/token');
    final params = Uri.splitQueryString(request.body);
    expect(params['client_id'], clientId);
    final refresh = params['grant_type'] == 'refresh_token';
    final file = refresh
        ? params['refresh_token'] == 'file-refresh'
        : params['code'] == 'file-code';
    if (refresh && file) {
      fileRefreshes++;
      fileRefreshStarted?.complete();
      await fileRefreshGate?.future;
    } else if (refresh) {
      primaryRefreshes++;
      expect(params['refresh_token'], 'primary-refresh');
      if (revokePrimary) return http.Response('{"error":"invalid_grant"}', 400);
    } else {
      expect(params['code'], file ? 'file-code' : 'primary-code');
      expect(params['code_verifier']!.length, greaterThanOrEqualTo(43));
      expect(params['redirect_uri'], startsWith('http://127.0.0.1:'));
    }
    return http.Response(
      jsonEncode({
        'access_token': file
            ? (refresh ? 'file-renewed' : 'file-access')
            : 'primary-access',
        'refresh_token': file ? 'file-refresh' : 'primary-refresh',
        'expires_in': 3600,
        'token_type': 'Bearer',
        'scope': file
            ? fileScope
            : 'openid https://www.googleapis.com/auth/drive.appdata email profile',
      }),
      200,
    );
  });

  WindowsGoogleDriveAuth createAuth() => WindowsGoogleDriveAuth(
    clientId: clientId,
    credentials: vault,
    client: client,
    clock: () => DateTime.utc(2026, 10, 19),
    flow: DesktopOAuthFlow(
      openBrowser: (uri) async {
        browserUrls.add(uri);
        final file = uri.queryParameters['scope'] == fileScope;
        await callback(uri, {
          'state': uri.queryParameters['state']!,
          if (!file && denyPrimary)
            'error': 'access_denied'
          else ...{
            'code': file ? 'file-code' : 'primary-code',
            if (file)
              'picked_file_ids':
                  uri.queryParameters['allow_folder_selection'] == 'true'
                  ? 'selected-folder'
                  : 'song-one,song-two',
          },
        });
        return true;
      },
    ),
  );
}

Future<int> callback(Uri authorization, Map<String, String> query) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse(
      authorization.queryParameters['redirect_uri']!,
    ).replace(queryParameters: query);
    final response = await (await client.getUrl(uri)).close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}

void main() {
  test(
    'blocked browser launch still cancels and closes its callback port',
    () async {
      final launch = Completer<bool>();
      final opened = Completer<Uri>();
      final flow = DesktopOAuthFlow(
        openBrowser: (uri) {
          opened.complete(uri);
          return launch.future;
        },
      );
      final authorization = flow.authorize(clientId: 'test', scopes: []);
      final failure = expectLater(authorization, throwsA(code('cancelled')));
      final url = await opened.future;
      flow.cancel();
      await failure.timeout(const Duration(seconds: 2));
      final client = HttpClient();
      try {
        await expectLater(
          client.getUrl(Uri.parse(url.queryParameters['redirect_uri']!)),
          throwsA(isA<SocketException>()),
        );
      } finally {
        client.close(force: true);
      }
      launch.complete(true);
    },
  );

  test('blocked browser launch respects the authorization deadline', () async {
    final launch = Completer<bool>();
    final flow = DesktopOAuthFlow(
      openBrowser: (_) => launch.future,
      timeout: const Duration(milliseconds: 30),
    );
    await expectLater(
      flow.authorize(clientId: 'test', scopes: []),
      throwsA(code('cancelled')),
    ).timeout(const Duration(seconds: 2));
    launch.complete(true);
  });
  test(
    'real loopback accepts only matching state and sends S256 PKCE',
    () async {
      late Uri authorization;
      final flow = DesktopOAuthFlow(
        openBrowser: (uri) async {
          authorization = uri;
          expect(uri.scheme, 'https');
          expect(uri.host, 'accounts.google.com');
          expect(uri.queryParameters['code_challenge_method'], 'S256');
          expect(
            Uri.parse(uri.queryParameters['redirect_uri']!).host,
            '127.0.0.1',
          );
          expect(Uri.parse(uri.queryParameters['redirect_uri']!).path, isEmpty);
          expect(
            await callback(uri, {'state': 'wrong', 'code': 'untrusted'}),
            400,
          );
          expect(
            await callback(uri, {
              'state': uri.queryParameters['state']!,
              'code': 'accepted',
            }),
            200,
          );
          return true;
        },
      );
      final result = await flow.authorize(clientId: 'test', scopes: ['scope']);
      expect(result.code, 'accepted');
      expect(result.verifier.length, inInclusiveRange(43, 128));
      expect(
        authorization.queryParameters['code_challenge'],
        base64Url
            .encode(sha256.convert(ascii.encode(result.verifier)).bytes)
            .replaceAll('=', ''),
      );
      final client = HttpClient();
      try {
        await expectLater(
          client.getUrl(Uri.parse(result.redirectUri)),
          throwsA(isA<SocketException>()),
        );
      } finally {
        client.close(force: true);
      }
    },
  );

  test(
    'loopback page does not claim sign-in succeeded before token exchange',
    () async {
      final client = HttpClient();
      try {
        final flow = DesktopOAuthFlow(
          openBrowser: (authorization) async {
            final redirect =
                Uri.parse(
                  authorization.queryParameters['redirect_uri']!,
                ).replace(
                  queryParameters: {
                    'state': authorization.queryParameters['state']!,
                    'code': 'received-code',
                  },
                );
            final response = await (await client.getUrl(redirect)).close();
            final body = await utf8.decoder.bind(response).join();
            expect(response.statusCode, HttpStatus.ok);
            expect(body, contains('Return to Singbook to finish signing in'));
            expect(body, isNot(contains('✓')));
            return true;
          },
        );
        final grant = await flow.authorize(clientId: 'test', scopes: []);
        expect(grant.code, 'received-code');
      } finally {
        client.close(force: true);
      }
    },
  );

  test(
    'loopback denial, failed launch, timeout and cancellation close listeners',
    () async {
      final denied = DesktopOAuthFlow(
        openBrowser: (uri) async {
          await callback(uri, {
            'state': uri.queryParameters['state']!,
            'error': 'access_denied',
          });
          return true;
        },
      );
      await expectLater(
        denied.authorize(clientId: 'test', scopes: []),
        throwsA(code('cancelled')),
      );
      final failed = DesktopOAuthFlow(openBrowser: (_) async => false);
      await expectLater(
        failed.authorize(clientId: 'test', scopes: []),
        throwsA(code('sign_in_failed')),
      );
      final timeout = DesktopOAuthFlow(
        openBrowser: (_) async => true,
        timeout: const Duration(milliseconds: 30),
      );
      await expectLater(
        timeout.authorize(clientId: 'test', scopes: []),
        throwsA(code('cancelled')),
      );
      late DesktopOAuthFlow cancelled;
      cancelled = DesktopOAuthFlow(
        openBrowser: (_) async {
          cancelled.cancel();
          return true;
        },
      );
      await expectLater(
        cancelled.authorize(clientId: 'test', scopes: []),
        throwsA(code('cancelled')),
      );
    },
  );

  group('primary Windows auth file capability lifecycle', () {
    late _PrimaryFileFixture fixture;

    setUp(() => fixture = _PrimaryFileFixture());
    tearDown(() => fixture.client.close());

    test(
      'primary scopes stay narrow and both picker delegates cache their grant',
      () async {
        final auth = fixture.createAuth();
        expect(auth, isA<DriveFileAccessCapability>());
        await auth.connect();
        expect(fixture.browserUrls, hasLength(1));
        expect(
          fixture.browserUrls.single.queryParameters['scope']!
              .split(' ')
              .toSet(),
          {
            'https://www.googleapis.com/auth/drive.appdata',
            'openid',
            'email',
            'profile',
          },
        );
        expect(fixture.vault.values, hasLength(1));

        expect(
          await auth.pickFolder(accountEmail: fixture.email),
          'selected-folder',
        );
        expect(await auth.fileAuthorization.accessToken(), 'file-access');
        expect(await auth.pickChordProFiles(accountEmail: fixture.email), [
          'song-one',
          'song-two',
        ]);
        expect(fixture.browserUrls, hasLength(3));
        for (final url in fixture.browserUrls.skip(1)) {
          expect(url.queryParameters['scope'], _PrimaryFileFixture.fileScope);
          expect(url.queryParameters['include_granted_scopes'], 'false');
          expect(url.queryParameters['login_hint'], fixture.email);
        }
        expect(
          fixture.browserUrls[1].queryParameters['allow_folder_selection'],
          'true',
        );
        expect(
          fixture.browserUrls[2].queryParameters['allow_multiple'],
          'true',
        );
        expect(await auth.fileAuthorization.accessToken(), 'file-access');
        expect(fixture.fileRefreshes, 0);
        expect(fixture.aboutRequests, 2);
        expect(fixture.vault.values, hasLength(2));
      },
    );

    test(
      'restart restores separate primary and file grants without opening consent',
      () async {
        final original = fixture.createAuth();
        await original.connect();
        await original.pickFolder();
        final opened = fixture.browserUrls.length;
        final restarted = fixture.createAuth();
        expect(await restarted.restore(), isTrue);
        expect(await restarted.fileAuthorization.accessToken(), 'file-renewed');
        expect(await restarted.fileAuthorization.accessToken(), 'file-renewed');
        expect(restarted.fileAuthorization.accountId, restarted.accountId);
        expect(fixture.primaryRefreshes, 1);
        expect(fixture.fileRefreshes, 1);
        expect(fixture.browserUrls, hasLength(opened));
        for (final encoded in fixture.vault.values.values) {
          expect(jsonDecode(encoded), isNot(contains('accessToken')));
        }
      },
    );

    for (final initializeFileFacade in [false, true]) {
      test(
        'primary disconnect clears saved file grant with facade initialized=$initializeFileFacade',
        () async {
          final original = fixture.createAuth();
          await original.connect();
          await original.pickFolder();
          final restarted = fixture.createAuth();
          expect(await restarted.restore(), isTrue);
          if (initializeFileFacade) {
            expect(
              await restarted.fileAuthorization.accessToken(),
              'file-renewed',
            );
          }
          expect(fixture.vault.values, hasLength(2));
          await restarted.disconnect();
          expect(restarted.isConnected, isFalse);
          expect(fixture.vault.values, isEmpty);
          await expectLater(
            restarted.fileAuthorization.accessToken(),
            throwsA(code('not_signed_in')),
          );
        },
      );
    }

    test(
      'primary account switch deletes the old file grant before new selection',
      () async {
        final auth = fixture.createAuth();
        await auth.connect();
        await auth.pickFolder();
        final oldFileKey = fixture.vault.values.keys.singleWhere(
          (key) => key.startsWith('google_drive_file_'),
        );
        fixture.id = 'second-account';
        fixture.email = 'second@example.com';
        await auth.connect();
        expect(auth.accountId, 'second-account');
        expect(fixture.vault.values, isNot(contains(oldFileKey)));
        expect(fixture.vault.values, hasLength(1));
        await expectLater(
          auth.fileAuthorization.accessToken(),
          throwsA(code('drive_file_authorization_required')),
        );
        expect(await auth.pickFolder(), 'selected-folder');
        expect(await auth.fileAuthorization.accessToken(), 'file-access');
        final fileKey = fixture.vault.values.keys.singleWhere(
          (key) => key.startsWith('google_drive_file_'),
        );
        expect(fileKey, isNot(oldFileKey));
      },
    );

    test(
      'failed primary account-switch persistence preserves the prior identity and file grant',
      () async {
        final auth = fixture.createAuth();
        await auth.connect();
        await auth.pickFolder();
        final oldId = auth.accountId;
        final oldEmail = auth.accountEmail;
        final saved = Map<String, String>.of(fixture.vault.values);
        fixture.id = 'second-account';
        fixture.email = 'second@example.com';
        fixture.vault.failPrimaryWriteId = fixture.id;

        await expectLater(auth.connect(), throwsA(code('sign_in_failed')));
        expect(auth.isConnected, isTrue);
        expect(auth.accountId, oldId);
        expect(auth.accountEmail, oldEmail);
        expect(fixture.vault.values, saved);
        expect(await auth.accessToken(), 'primary-access');
        expect(await auth.fileAuthorization.accessToken(), 'file-access');
        expect(fixture.fileRefreshes, 0);
      },
    );

    test(
      'cancelled primary reconnect preserves both existing grants',
      () async {
        final auth = fixture.createAuth();
        await auth.connect();
        await auth.pickFolder();
        final saved = Map<String, String>.of(fixture.vault.values);
        fixture.denyPrimary = true;
        await expectLater(auth.connect(), throwsA(code('cancelled')));
        expect(auth.isConnected, isTrue);
        expect(auth.accountId, fixture.id);
        expect(fixture.vault.values, saved);
        expect(await auth.accessToken(), 'primary-access');
        expect(await auth.fileAuthorization.accessToken(), 'file-access');
      },
    );

    test(
      'revoked primary grant also deletes a file grant never loaded after restart',
      () async {
        final original = fixture.createAuth();
        await original.connect();
        await original.pickFolder();
        final restarted = fixture.createAuth();
        expect(await restarted.restore(), isTrue);
        fixture.revokePrimary = true;
        await expectLater(
          restarted.refreshAccessToken(),
          throwsA(code('authorization_required')),
        );
        expect(restarted.isConnected, isFalse);
        expect(fixture.vault.values, isEmpty);
        await expectLater(
          restarted.fileAuthorization.accessToken(),
          throwsA(code('not_signed_in')),
        );
      },
    );

    test(
      'reconnect waits for primary and file deletion and remote revocation',
      () async {
        final auth = fixture.createAuth();
        await auth.connect();
        await auth.pickFolder();
        final opened = fixture.browserUrls.length;
        fixture.vault.deleteWait = Completer<void>();
        fixture.vault.deleteStarted = Completer<void>();
        fixture.revokeGate = Completer<void>();
        fixture.revokeStarted = Completer<void>();
        final disconnect = auth.disconnect();
        try {
          await fixture.vault.deleteStarted!.future;
          await expectLater(auth.connect(), throwsA(code('sync_busy')));
          expect(fixture.browserUrls, hasLength(opened));
          fixture.vault.deleteWait!.complete();
          await fixture.revokeStarted!.future;
          expect(fixture.vault.values, isEmpty);
          await expectLater(auth.connect(), throwsA(code('sync_busy')));
          expect(fixture.browserUrls, hasLength(opened));
        } finally {
          if (!fixture.vault.deleteWait!.isCompleted) {
            fixture.vault.deleteWait!.complete();
          }
          fixture.revokeGate!.complete();
          await disconnect;
        }
        await auth.connect();
        expect(auth.isConnected, isTrue);
        expect(await auth.accessToken(), 'primary-access');
        expect(fixture.vault.values, hasLength(1));
      },
    );

    test(
      'primary signout prevents a pending file renewal from restoring credentials',
      () async {
        final auth = fixture.createAuth();
        await auth.connect();
        await auth.pickFolder();
        fixture.fileRefreshGate = Completer<void>();
        fixture.fileRefreshStarted = Completer<void>();
        final pending = (auth.fileAuthorization as RefreshableAuthorization)
            .refreshAccessToken();
        final failure = expectLater(pending, throwsA(code('cancelled')));
        await fixture.fileRefreshStarted!.future;
        await auth.disconnect();
        fixture.fileRefreshGate!.complete();
        await failure;
        expect(auth.isConnected, isFalse);
        expect(fixture.vault.values, isEmpty);
      },
    );
  });

  group('Windows Drive authorization', () {
    late _MemoryCredentials vault;
    late WindowsGoogleDriveAuth auth;
    late MockClient client;
    late DateTime now;
    var refreshCount = 0;
    var invalidGrant = false;
    var invalidClient = false;
    var missingClientSecret = false;
    var invalidRequest = false;
    var malformedErrorDescription = false;
    var malformedRefresh = false;
    var deniedScope = false;
    Completer<void>? refreshWait;
    const clientId = 'desktop.apps.googleusercontent.com';

    setUp(() {
      vault = _MemoryCredentials();
      now = DateTime.utc(2026, 1, 1);
      refreshCount = 0;
      invalidGrant = invalidClient = missingClientSecret = invalidRequest =
          false;
      malformedErrorDescription = false;
      malformedRefresh = deniedScope = false;
      refreshWait = null;
      client = MockClient((request) async {
        expect(request.url.scheme, 'https');
        if (request.url.path == '/v1/userinfo') {
          expect(request.headers['Authorization'], 'Bearer granted-access');
          return http.Response(
            jsonEncode({
              'sub': 'account-id',
              'email': 'user@example.com',
              'email_verified': true,
            }),
            200,
          );
        }
        if (request.url.path == '/revoke') return http.Response('', 200);
        final params = Uri.splitQueryString(request.body);
        expect(params['client_id'], clientId);
        if (params['grant_type'] == 'refresh_token') {
          refreshCount++;
          await refreshWait?.future;
          if (invalidGrant) {
            return http.Response('{"error":"invalid_grant"}', 400);
          }
          if (invalidClient) {
            return http.Response('{"error":"invalid_client"}', 401);
          }
          if (malformedRefresh) return http.Response('{}', 200);
          expect(params['refresh_token'], 'refresh-token');
          return http.Response(
            jsonEncode({
              'access_token': 'renewed-access',
              'expires_in': 3600,
              'token_type': 'Bearer',
            }),
            200,
          );
        }
        expect(params['code_verifier']!.length, greaterThanOrEqualTo(43));
        expect(params['code'], 'grant-code');
        expect(params['redirect_uri'], startsWith('http://127.0.0.1:'));
        expect(params, isNot(contains('client_secret')));
        if (missingClientSecret) {
          return http.Response(
            '{"error":"invalid_request","error_description":"Missing required parameter: CLIENT_SECRET"}',
            400,
          );
        }
        if (invalidRequest) {
          if (malformedErrorDescription) {
            return http.Response(
              '{"error":"invalid_request","error_description":7}',
              400,
            );
          }
          return http.Response('{"error":"invalid_request"}', 400);
        }
        return http.Response(
          jsonEncode({
            'access_token': 'granted-access',
            'refresh_token': 'refresh-token',
            'expires_in': 3600,
            'token_type': 'Bearer',
            'scope': deniedScope
                ? 'openid'
                : 'openid https://www.googleapis.com/auth/drive.appdata https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile',
          }),
          200,
        );
      });
      auth = WindowsGoogleDriveAuth(
        clientId: clientId,
        credentials: vault,
        client: client,
        clock: () => now,
        flow: DesktopOAuthFlow(
          openBrowser: (uri) async {
            await callback(uri, {
              'state': uri.queryParameters['state']!,
              'code': 'grant-code',
            });
            return true;
          },
        ),
      );
    });

    test(
      'connect, restart restore, expiry, refresh and sign out preserve account identity',
      () async {
        await auth.connect();
        expect(auth.accountId, 'account-id');
        expect(await auth.accessToken(), 'granted-access');
        expect(vault.values.values.single, contains('refresh-token'));
        final restarted = WindowsGoogleDriveAuth(
          clientId: clientId,
          credentials: vault,
          client: client,
          clock: () => now,
        );
        expect(await restarted.restore(), isTrue);
        expect(restarted.accountEmail, 'user@example.com');
        now = now.add(const Duration(hours: 2));
        expect(await restarted.accessToken(), 'renewed-access');
        expect(refreshCount, 2);
        expect(await restarted.refreshAccessToken(), 'renewed-access');
        expect(refreshCount, 3);
        await restarted.disconnect();
        expect(vault.values, isEmpty);
        expect(restarted.isConnected, isFalse);
        await expectLater(
          restarted.accessToken(),
          throwsA(code('not_signed_in')),
        );
      },
    );

    test(
      'concurrent renewal coalesces and sign out prevents stale session resurrection',
      () async {
        await auth.connect();
        now = now.add(const Duration(hours: 2));
        refreshWait = Completer<void>();
        final first = auth.accessToken();
        final second = auth.accessToken();
        final failure1 = expectLater(first, throwsA(code('not_signed_in')));
        final failure2 = expectLater(second, throwsA(code('not_signed_in')));
        await Future<void>.delayed(Duration.zero);
        await auth.disconnect();
        refreshWait!.complete();
        await Future.wait([failure1, failure2]);
        expect(refreshCount, 1);
        expect(vault.values, isEmpty);
        expect(auth.isConnected, isFalse);
      },
    );

    test(
      'revoked grants require reconnect and missing Drive scope is rejected',
      () async {
        await auth.connect();
        invalidGrant = true;
        await expectLater(
          auth.refreshAccessToken(),
          throwsA(code('authorization_required')),
        );
        expect(await auth.restore(), isFalse);
        expect(vault.values, isEmpty);
        invalidGrant = false;
        await auth.connect();
        expect(auth.isConnected, isTrue);
        await auth.disconnect();
        deniedScope = true;
        await expectLater(
          auth.connect(),
          throwsA(code('authorization_required')),
        );
        expect(vault.values, isEmpty);
      },
    );

    test(
      'explicit missing client_secret response is a configuration error',
      () async {
        missingClientSecret = true;
        await expectLater(
          auth.connect(),
          throwsA(code('oauth_client_configuration')),
        );
        expect(auth.isConnected, isFalse);
        expect(vault.values, isEmpty);
      },
    );

    test(
      'generic invalid_request is not treated as missing configuration',
      () async {
        invalidRequest = true;
        await expectLater(auth.connect(), throwsA(code('network')));
        expect(auth.isConnected, isFalse);
        expect(vault.values, isEmpty);
      },
    );

    test(
      'non-string invalid_request description remains an exchange error',
      () async {
        invalidRequest = true;
        malformedErrorDescription = true;
        await expectLater(auth.connect(), throwsA(code('network')));
        expect(auth.isConnected, isFalse);
        expect(vault.values, isEmpty);
      },
    );

    test(
      'client configuration failure preserves the saved grant for recovery',
      () async {
        await auth.connect();
        final saved = Map.of(vault.values);
        now = now.add(const Duration(hours: 2));
        invalidClient = true;
        await expectLater(
          auth.refreshAccessToken(),
          throwsA(code('oauth_client_configuration')),
        );
        expect(auth.isConnected, isTrue);
        expect(vault.values, saved);
        final restarted = WindowsGoogleDriveAuth(
          clientId: clientId,
          credentials: vault,
          client: client,
          clock: () => now,
        );
        expect(await restarted.restore(), isFalse);
        expect(vault.values, saved);
        invalidClient = false;
        expect(await restarted.restore(), isTrue);
        expect(await restarted.accessToken(), 'renewed-access');
        expect(restarted.accountId, 'account-id');
      },
    );

    test(
      'malformed token responses preserve credentials and recover on retry',
      () async {
        await auth.connect();
        final saved = Map.of(vault.values);
        malformedRefresh = true;
        await expectLater(auth.refreshAccessToken(), throwsA(code('network')));
        expect(vault.values, saved);
        expect(auth.isConnected, isTrue);
        malformedRefresh = false;
        expect(await auth.refreshAccessToken(), 'renewed-access');
      },
    );

    test('concurrent restore shares one credential read and renewal', () async {
      await auth.connect();
      vault.readWait = Completer<void>();
      final restarted = WindowsGoogleDriveAuth(
        clientId: clientId,
        credentials: vault,
        client: client,
        clock: () => now,
      );
      final first = restarted.restore();
      final second = restarted.restore();
      await Future<void>.delayed(Duration.zero);
      expect(vault.reads, 1);
      vault.readWait!.complete();
      expect(await Future.wait([first, second]), [true, true]);
      expect(refreshCount, 1);
      expect(await restarted.accessToken(), 'renewed-access');
    });

    test(
      'large access tokens remain in RAM and fit the native vault boundary',
      () async {
        final largeToken = 'a' * 2048;
        final largeAuth = WindowsGoogleDriveAuth(
          clientId: clientId,
          credentials: vault,
          client: MockClient((request) async {
            if (request.url.path == '/v1/userinfo') {
              return http.Response(
                '{"sub":"account","email":"user@example.com","email_verified":true}',
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'access_token': largeToken,
                'refresh_token': 'r' * 512,
                'expires_in': 3600,
                'token_type': 'Bearer',
                'scope': 'openid https://www.googleapis.com/auth/drive.appdata',
              }),
              200,
            );
          }),
          flow: DesktopOAuthFlow(
            openBrowser: (uri) async {
              await callback(uri, {
                'state': uri.queryParameters['state']!,
                'code': 'large-grant',
              });
              return true;
            },
          ),
        );
        await largeAuth.connect();
        expect(await largeAuth.accessToken(), largeToken);
        final stored =
            jsonDecode(vault.values.values.single) as Map<String, dynamic>;
        expect(stored, isNot(contains('accessToken')));
        expect(stored['refreshToken'], 'r' * 512);
        expect(
          utf8.encode(vault.values.values.single).length,
          lessThanOrEqualTo(2560),
        );
      },
    );

    test(
      'unconfigured and corrupt vault sessions fail without launching browser',
      () async {
        final empty = WindowsGoogleDriveAuth(clientId: '', credentials: vault);
        expect(empty.configured, isFalse);
        expect(await empty.restore(), isFalse);
        await expectLater(empty.connect(), throwsA(code('not_configured')));
        await auth.connect();
        vault.values[vault.values.keys.single] = '{"refreshToken":42}';
        final restarted = WindowsGoogleDriveAuth(
          clientId: clientId,
          credentials: vault,
        );
        expect(await restarted.restore(), isFalse);
        expect(restarted.isConnected, isFalse);
      },
    );
  });
}
