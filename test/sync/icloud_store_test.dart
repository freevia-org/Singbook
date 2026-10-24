import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/icloud_auth.dart';
import 'package:singbook/sync/icloud_store.dart';
import 'package:singbook/sync/sync_protocol.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('org.freevia.singbook/icloud_sync');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const meta = {
    'id': '11111111-1111-4111-8111-111111111111',
    'name': 'song-abc.cho',
    'properties': {'verseSchema': '2'},
    'changeTag': 'tag-1',
    'size': 4,
  };
  late ICloudAuthorization auth;
  late ICloudSyncStore store;
  late String liveTag;
  final calls = <MethodCall>[];
  setUp(() async {
    calls.clear();
    liveTag = 'tag-1';
    auth = ICloudAuthorization(channel: channel);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'status':
          return {'available': true, 'recordName': 'user-record'};
        case 'list':
          return [meta];
        case 'get':
          return {...meta, 'changeTag': liveTag};
        case 'read':
          return {'content': 'body'};
        case 'create':
          return {...meta, 'id': '22222222-2222-4222-8222-222222222222'};
        case 'update':
          expect((call.arguments as Map)['changeTag'], liveTag);
          liveTag = 'tag-2';
          return {...meta, 'changeTag': liveTag};
        case 'delete':
          return null;
      }
      return null;
    });
    await auth.restore();
    store = ICloudSyncStore(authorization: auth, channel: channel);
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('namespaces account and sends identity on each store request', () async {
    expect(auth.accountId, 'icloud:user-record');
    expect((await store.listFiles()).single.id, meta['id']);
    expect((calls.last.arguments as Map)['accountID'], 'icloud:user-record');
  });

  test(
    'read, create, update and delete preserve the sync protocol fields',
    () async {
      expect(await store.readFile(meta['id']! as String), 'body');
      await store.createFile('song-abc.cho', 'body', {'hash': 'x'});
      await store.getFile(meta['id']! as String);
      calls.clear();
      await store.updateFile(meta['id']! as String, 'next', {'hash': 'y'});
      expect((calls.last.arguments as Map)['changeTag'], 'tag-1');
      expect(calls.where((call) => call.method == 'get'), isEmpty);
      calls.clear();
      await store.deleteFile(meta['id']! as String);
      expect((calls.last.arguments as Map)['changeTag'], 'tag-2');
      expect(calls.where((call) => call.method == 'get'), isEmpty);
    },
  );

  test(
    'rejects uncanonical names and unavailable account before cloud access',
    () async {
      expect(
        () => store.createFile('../song.cho', 'x', {}),
        throwsA(isA<SyncException>()),
      );
      await auth.disconnect();
      await expectLater(store.listFiles(), throwsA(isA<SyncException>()));
    },
  );

  test('bounds cloud listing and file body size', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'list'
          ? List.filled(40001, meta)
          : {'content': 'x' * (maxSyncFileBytes + 1)},
    );
    await expectLater(store.listFiles(), throwsA(isA<SyncException>()));
    await expectLater(
      store.readFile(meta['id']! as String),
      throwsA(isA<SyncException>()),
    );
  });

  test('surfaces a stale CloudKit change tag as a sync conflict', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'get') return meta;
      if (call.method == 'update') {
        throw PlatformException(code: 'sync_conflict');
      }
      return null;
    });
    await store.getFile(meta['id']! as String);
    calls.clear();
    await expectLater(
      store.updateFile(meta['id']! as String, 'new body', {}),
      throwsA(
        isA<SyncException>().having(
          (error) => error.code,
          'code',
          'sync_conflict',
        ),
      ),
    );
    final attempted = calls.singleWhere((call) => call.method == 'update');
    expect((attempted.arguments as Map)['changeTag'], 'tag-1');
  });

  test(
    'rejects malformed record IDs and empty change tags from CloudKit',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'get') return {...meta, 'id': 'not-a-uuid'};
        if (call.method == 'list') {
          return [
            {...meta, 'changeTag': ''},
          ];
        }
        return null;
      });
      await expectLater(
        store.getFile(meta['id']! as String),
        throwsA(
          isA<SyncException>().having(
            (error) => error.code,
            'code',
            'invalid_remote_data',
          ),
        ),
      );
      await expectLater(
        store.listFiles(),
        throwsA(
          isA<SyncException>().having(
            (error) => error.code,
            'code',
            'invalid_remote_data',
          ),
        ),
      );
    },
  );

  test(
    'does not invent an update precondition without an observed version',
    () async {
      await expectLater(
        store.updateFile(meta['id']! as String, 'new body', {}),
        throwsA(
          isA<SyncException>().having(
            (error) => error.code,
            'code',
            'sync_conflict',
          ),
        ),
      );
      expect(calls.where((call) => call.method == 'update'), isEmpty);
    },
  );

  test(
    'fails closed when the native identity changes during an operation',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'list') {
          throw PlatformException(code: 'account_unavailable');
        }
        return null;
      });
      await expectLater(
        store.listFiles(),
        throwsA(
          isA<SyncException>().having(
            (error) => error.code,
            'code',
            'account_unavailable',
          ),
        ),
      );
    },
  );

  test(
    'account switch discards tags observed under the previous account',
    () async {
      await store.getFile(meta['id']! as String);
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'status') {
          return {'available': true, 'recordName': 'different-user'};
        }
        return meta;
      });
      await auth.restore();
      calls.clear();
      await expectLater(
        store.updateFile(meta['id']! as String, 'new body', {}),
        throwsA(
          isA<SyncException>().having(
            (error) => error.code,
            'code',
            'sync_conflict',
          ),
        ),
      );
      expect(calls, isEmpty);
    },
  );
}
