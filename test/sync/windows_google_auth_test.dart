import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/sync/desktop_oauth_flow.dart';
import 'package:singbook/sync/sync_protocol.dart';
import 'package:singbook/sync/windows_google_auth.dart';

class _MemoryCredentials implements DesktopCredentialStore {
  final values = <String, String>{};
  Completer<void>? readWait;
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
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
}

Matcher code(String value) =>
    isA<SyncException>().having((e) => e.code, 'code', value);

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

  group('Windows Drive authorization', () {
    late _MemoryCredentials vault;
    late WindowsGoogleDriveAuth auth;
    late MockClient client;
    late DateTime now;
    var refreshCount = 0;
    var invalidGrant = false;
    var deniedScope = false;
    Completer<void>? refreshWait;
    const clientId = 'desktop.apps.googleusercontent.com';

    setUp(() {
      vault = _MemoryCredentials();
      now = DateTime.utc(2026, 1, 1);
      refreshCount = 0;
      invalidGrant = deniedScope = false;
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
