import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/sync/google_oauth_token_client.dart';
import 'package:singbook/sync/icloud_auth.dart';
import 'package:singbook/sync/icloud_store.dart';
import 'package:singbook/sync/sync_protocol.dart';
import 'package:singbook/sync/windows_google_auth.dart';

class _Revoked extends SyncException {
  const _Revoked() : super('revoked_for_test');
}

class _CountingVault implements DesktopCredentialStore {
  final values = <String, String>{};
  int writes = 0;
  bool failWrites = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    writes++;
    if (failWrites) throw StateError('vault_write_failed');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
}

Matcher code(String value) =>
    isA<SyncException>().having((e) => e.code, 'code', value);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shared id checks keep each caller\'s limit', () {
    test('client ids', () {
      expect(isGoogleClientId('a.b-c_1.apps.googleusercontent.com'), isTrue);
      expect(
        isGoogleClientId('a.b.apps.googleusercontent.com', allowDots: false),
        isFalse,
      );
      expect(
        isGoogleClientId('a-b_1.apps.googleusercontent.com', allowDots: false),
        isTrue,
      );
      expect(isGoogleClientId('.apps.googleusercontent.com'), isFalse);
      expect(isGoogleClientId('a.apps.googleusercontent.com.evil'), isFalse);
      expect(isGoogleClientId('a b.apps.googleusercontent.com'), isFalse);
    });

    test('Drive ids', () {
      expect(isDriveId('Ab_-9', maxLength: 200), isTrue);
      expect(isDriveId('', maxLength: 200), isFalse);
      expect(isDriveId('a' * 200, maxLength: 200), isTrue);
      expect(isDriveId('a' * 201, maxLength: 200), isFalse);
      expect(isDriveId('a' * 201, maxLength: 256), isTrue);
      expect(isDriveId('a' * 257, maxLength: 512), isTrue);
      expect(isDriveId('a' * 513, maxLength: 512), isFalse);
      expect(isDriveId('a/b', maxLength: 200), isFalse);
      expect(isDriveId('abc\n', maxLength: 200), isFalse);
    });
  });

  group('GoogleOAuthTokenClient', () {
    GoogleOAuthTokenClient tokens(
      http.Response response, {
      bool lenient = false,
      bool exactBearer = true,
      void Function(Map<String, String>)? seen,
    }) => GoogleOAuthTokenClient(
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://oauth2.googleapis.com/token');
        seen?.call(request.bodyFields);
        return response;
      }),
      clientId: 'id.apps.googleusercontent.com',
      clientSecret: 'secret',
      invalidGrant: () => const _Revoked(),
      clock: () => DateTime.utc(2026),
      malformedBodyIsNetwork: lenient,
      exactBearerTokenType: exactBearer,
    );

    test('sends the client and returns the decoded response', () async {
      Map<String, String>? sent;
      final result = await tokens(
        http.Response('{"access_token":"t"}', 200),
        seen: (fields) => sent = fields,
      ).request({'grant_type': 'refresh_token', 'refresh_token': 'r'});
      expect(result, {'access_token': 't'});
      expect(sent, {
        'client_id': 'id.apps.googleusercontent.com',
        'client_secret': 'secret',
        'grant_type': 'refresh_token',
        'refresh_token': 'r',
      });
    });

    test('maps token endpoint errors', () async {
      Future<void> fails(String body, Matcher error) => expectLater(
        tokens(http.Response(body, 400)).request(const {}),
        throwsA(error),
      );
      await fails('{"error":"invalid_grant"}', isA<_Revoked>());
      await fails(
        '{"error":"invalid_client"}',
        code('oauth_client_configuration'),
      );
      await fails(
        '{"error":"invalid_request","error_description":"client_secret is missing"}',
        code('oauth_client_configuration'),
      );
      await fails('{"error":"invalid_request"}', code('network'));
      await fails('{"error":"server_error"}', code('network'));
    });

    test(
      'a body that is not a JSON object keeps each grant\'s behaviour',
      () async {
        await expectLater(
          tokens(http.Response('[]', 200), lenient: true).request(const {}),
          throwsA(code('network')),
        );
        await expectLater(
          tokens(http.Response('[]', 200)).request(const {}),
          throwsA(isA<TypeError>()),
        );
        for (final lenient in [true, false]) {
          await expectLater(
            tokens(
              http.Response('<html>', 502),
              lenient: lenient,
            ).request(const {}),
            throwsA(isA<FormatException>()),
          );
        }
      },
    );

    test('token type strictness is the caller\'s', () {
      final strict = tokens(http.Response('', 200));
      final relaxed = tokens(http.Response('', 200), exactBearer: false);
      const lower = {'access_token': 't', 'token_type': 'bearer'};
      const exact = {'access_token': 't', 'token_type': 'Bearer'};
      expect(strict.accessToken(exact), 't');
      expect(relaxed.accessToken(exact), 't');
      expect(relaxed.accessToken(lower), 't');
      expect(() => strict.accessToken(lower), throwsA(code('network')));
      for (final client in [strict, relaxed]) {
        expect(
          () => client.accessToken(const {'access_token': 't'}),
          throwsA(code('network')),
        );
        expect(
          () => client.accessToken(const {
            'access_token': '',
            'token_type': 'Bearer',
          }),
          throwsA(code('network')),
        );
      }
    });

    test('expiry is bounded and uses the clock', () {
      final client = tokens(http.Response('', 200));
      expect(
        client.expiry(const {'expires_in': 3600}),
        DateTime.utc(2026).millisecondsSinceEpoch + 3600000,
      );
      for (final bad in [0, -1, 86401, '3600', null]) {
        expect(
          () => client.expiry({'expires_in': bad}),
          throwsA(code('network')),
        );
      }
    });
  });

  group('desktop account token renewal', () {
    const clientId = 'desktop.apps.googleusercontent.com';
    final key = 'google_drive_${sha256.convert(utf8.encode(clientId))}';
    late _CountingVault vault;
    String? rotated;
    WindowsGoogleDriveAuth auth() => WindowsGoogleDriveAuth(
      clientId: clientId,
      credentials: vault,
      client: MockClient((request) async {
        expect(request.url.path, '/token');
        return http.Response(
          jsonEncode({
            'access_token': 'renewed',
            'token_type': 'Bearer',
            'expires_in': 3600,
            'refresh_token': ?rotated,
          }),
          200,
        );
      }),
    );
    setUp(() {
      rotated = null;
      vault = _CountingVault()
        ..values[key] = jsonEncode({
          'id': 'account',
          'email': 'a@example.com',
          'refreshToken': 'refresh-1',
        });
    });

    test('does not rewrite an unchanged stored session', () async {
      final restored = auth();
      expect(await restored.restore(), isTrue);
      expect(await restored.accessToken(), 'renewed');
      expect(await restored.refreshAccessToken(), 'renewed');
      expect(vault.writes, 0);
      expect(jsonDecode(vault.values[key]!)['refreshToken'], 'refresh-1');
    });

    test('does not depend on a writable vault', () async {
      vault.failWrites = true;
      final restored = auth();
      expect(await restored.restore(), isTrue);
      expect(await restored.accessToken(), 'renewed');
      expect(restored.accountId, 'account');
    });

    test('stores a rotated refresh token', () async {
      rotated = 'refresh-2';
      final restored = auth();
      expect(await restored.restore(), isTrue);
      expect(vault.writes, 1);
      expect(jsonDecode(vault.values[key]!)['refreshToken'], 'refresh-2');
      // The same token again is not a rotation.
      expect(await restored.refreshAccessToken(), 'renewed');
      expect(vault.writes, 1);
    });

    test('a rotated token that cannot be stored is still reported', () async {
      rotated = 'refresh-2';
      vault.failWrites = true;
      final restored = auth();
      // Restoring keeps the identity; the renewal itself fails as before.
      expect(await restored.restore(), isTrue);
      await expectLater(restored.accessToken(), throwsA(code('network')));
    });
  });

  group('iCloud native calls', () {
    const channel = MethodChannel('org.freevia.singbook/icloud_sync');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('that never answer end as icloud_unavailable', () async {
      final never = Completer<Object?>();
      final methods = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) {
        methods.add(call.method);
        if (call.method == 'status') {
          return Future.value({'available': true, 'recordName': 'user'});
        }
        return never.future;
      });
      final authorization = ICloudAuthorization(
        channel: channel,
        supportedOverride: true,
      );
      await authorization.connect();
      final store = ICloudSyncStore(
        authorization: authorization,
        channel: channel,
        callTimeout: const Duration(milliseconds: 20),
      );

      await expectLater(
        store.readFile('11111111-1111-4111-8111-111111111111'),
        throwsA(code('icloud_unavailable')),
      );
      await expectLater(store.listFiles(), throwsA(code('icloud_unavailable')));
      expect(methods, ['status', 'read', 'list']);
      never.complete(null);
    });
  });
}
