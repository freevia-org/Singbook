import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/google_auth.dart';
import 'package:singbook/sync/sync_protocol.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('org.freevia.singbook/rich_clipboard');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late GoogleDriveFileAuthorization auth;
  Completer<String>? ordinary;
  bool failForce = false;

  setUp(() {
    calls = [];
    ordinary = null;
    failForce = false;
    auth = GoogleDriveFileAuthorization(FakeAuth()..connected = true);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      expect(call.method, 'driveFileAccessToken');
      final args = call.arguments as Map;
      expect(args['accountEmail'], 'person-a@example.test');
      if (args['forceRefresh'] == true) {
        if (failForce) {
          throw PlatformException(code: 'drive_authorization_failed');
        }
        return 'renewed-token';
      }
      return ordinary?.future ?? 'cached-native-token';
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'forced renewal crosses the native boundary and updates the Dart cache',
    () async {
      expect(await auth.accessToken(), 'cached-native-token');
      expect(await auth.accessToken(), 'cached-native-token');
      expect(calls, hasLength(1));
      expect(await auth.refreshAccessToken(), 'renewed-token');
      expect(calls, hasLength(2));
      expect((calls.last.arguments as Map)['forceRefresh'], isTrue);
      expect(await auth.accessToken(), 'renewed-token');
      expect(calls, hasLength(2));
    },
  );

  test('force failure never falls back to a rejected token', () async {
    await auth.accessToken();
    failForce = true;
    await expectLater(
      auth.refreshAccessToken(),
      throwsA(isA<SyncException>().having((e) => e.code, 'code', 'network')),
    );
    expect(calls, hasLength(2));
    expect((calls.last.arguments as Map)['forceRefresh'], isTrue);
  });

  test(
    'force during an ordinary lookup waits then shares one native renewal',
    () async {
      ordinary = Completer<String>();
      final first = auth.accessToken();
      // Let the channel handler observe the first request without completing it.
      await Future<void>.delayed(Duration.zero);
      final forcedA = auth.refreshAccessToken();
      final forcedB = auth.refreshAccessToken();
      ordinary!.complete('cached-native-token');
      expect(await first, 'cached-native-token');
      expect(await forcedA, 'renewed-token');
      expect(await forcedB, 'renewed-token');
      expect(
        calls.where((call) => (call.arguments as Map)['forceRefresh'] == true),
        hasLength(1),
      );
    },
  );
}
