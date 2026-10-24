import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/icloud_auth.dart';
import 'package:singbook/sync/sync_protocol.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('org.freevia.singbook/icloud_sync');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'uses the current private CloudKit identity without creating credentials',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'available': true, 'recordName': 'record-1'},
      );
      final auth = ICloudAuthorization(
        channel: channel,
        supportedOverride: true,
      );
      expect(await auth.restore(), isTrue);
      expect(auth.accountId, 'icloud:record-1');
      expect(auth.accountEmail, isNull);
      expect(auth.configured, isTrue);
    },
  );

  test('unavailable account fails closed', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'available': false},
    );
    final auth = ICloudAuthorization(channel: channel, supportedOverride: true);
    expect(await auth.restore(), isFalse);
    expect(auth.isConnected, isFalse);
    expect(auth.accountId, isNull);
    await expectLater(
      auth.connect(),
      throwsA(
        isA<SyncException>().having(
          (error) => error.code,
          'code',
          'icloud_unavailable',
        ),
      ),
    );
  });
}
