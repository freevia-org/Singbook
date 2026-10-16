import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/sync/google_drive_sync.dart';
import '../sync/support.dart';

class _QuietCatalog implements LyricsProvider {
  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: 'genius',
    name: 'Catalog',
    capabilities: {'lyrics', 'search'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw UnimplementedError();
}

Future<void> until(bool Function() condition, {int ms = 4000}) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('condition not reached in time');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

Future<void> settle([int ms = 150]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late MemoryCloud cloud;
  late Device device;
  final controllers = <AppController>[];

  Future<AppController> start({
    Device? on,
    bool signedIn = true,
    Duration delay = const Duration(milliseconds: 40),
    Duration startDelay = const Duration(milliseconds: 20),
    Duration stale = const Duration(minutes: 5),
    Duration backoff = const Duration(milliseconds: 40),
  }) async {
    final d = on ?? device;
    d.auth.connected = signedIn;
    final app = AppController(
      repository: d.repo,
      discovery: SourceDiscoveryService([_QuietCatalog()]),
      sync: d.sync,
      autoSyncDelay: delay,
      autoSyncStartDelay: startDelay,
      autoSyncStaleAfter: stale,
      autoSyncBackoff: backoff,
      autoSyncMaxBackoff: const Duration(seconds: 1),
    );
    controllers.add(app);
    await app.initialize();
    return app;
  }

  setUp(() async {
    cloud = MemoryCloud();
    device = await Device.create(cloud);
  });
  tearDown(() async {
    for (final app in controllers) {
      app.dispose();
    }
    controllers.clear();
    await settle(30);
    await device.close();
  });

  Future<void> addSong(AppController app, String id, String body) => app.saveSong(
    SongDocument(id: id, title: id, artist: 'A', body: body),
  );

  test('startup does no cloud work; manual sync records the time', () async {
    await device.saveSong('s', 'one');
    final app = await start();
    expect(app.syncConnected, isTrue);
    expect(app.lastSyncAt, isNull);
    expect(cloud.requests, 0);
    expect(app.autoSyncEnabled, isFalse);
    await app.syncNow();
    expect(cloud.names, ['song-s.cho']);
    expect(app.lastSyncErrorCode, isNull);
    expect(app.lastSyncConflicts, 0);
    final syncedAt = app.lastSyncAt;
    cloud.resetCounters();
    final again = await start(startDelay: const Duration(milliseconds: 10));
    expect(again.lastSyncAt, isNull);
    expect(cloud.requests, 0, reason: 'startup only reads local state');
    await again.syncNow();
    expect(again.lastSyncAt, isNotNull);
    expect(again.lastSyncAt!.isBefore(syncedAt!), isFalse);
    expect(cloud.lists, 1, reason: 'the explicit action performs a fresh sync');
  });

  test('local edits never start cloud work; explicit sync uploads them', () async {
    final app = await start(delay: const Duration(milliseconds: 300));
    cloud.resetCounters();
    for (var i = 0; i < 5; i++) {
      await addSong(app, 's$i', 'body $i');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await settle(350);
    expect(cloud.requests, 0);
    await app.syncNow();
    expect(cloud.creates, 5);
    expect(cloud.lists, 1);
  });

  test('legacy auto-sync setting cannot activate cloud work',
      () async {
    await device.repo.setSetting('app', {'autoSync': true});
    final app = await start();
    expect(app.autoSyncEnabled, isFalse);
    cloud.resetCounters();
    await addSong(app, 'x', 'y');
    await settle(200);
    expect(cloud.requests, 0);
    final other = await start(startDelay: const Duration(milliseconds: 10));
    expect(other.autoSyncEnabled, isFalse);
    await settle(100);
    expect(cloud.requests, 0);
    await app.setAutoSync(true);
    expect(app.autoSyncEnabled, isFalse);
    await settle(100);
    expect(cloud.requests, 0);
    await app.syncNow();
    expect(cloud.creates, 1);
  });

  test('a change during a manual run does not schedule a follow-up run',
      () async {
    final app = await start();
    final gate = Completer<void>();
    var concurrent = 0, maxConcurrent = 0;
    cloud.hook = (op, target) async {
      if (op != 'list') return;
      concurrent++;
      maxConcurrent = maxConcurrent < concurrent ? concurrent : maxConcurrent;
      await gate.future;
      concurrent--;
    };
    cloud.resetCounters();
    await addSong(app, 'a', '1');
    final running = app.syncNow();
    await until(() => app.syncBusy);
    await addSong(app, 'b', '2'); // remains queued for the next manual run
    gate.complete();
    await running;
    expect(cloud.creates, 2, reason: 'the manual run sees both local edits');
    expect(cloud.lists, 1);
    expect(maxConcurrent, 1);
    cloud.hook = null;
    await app.syncNow();
    expect(cloud.creates, 2);
    expect(cloud.lists, 2, reason: 'only the second explicit action retries');
  });

  test('failed sync waits for an explicit manual retry', () async {
    final app = await start();
    final times = <DateTime>[];
    cloud.hook = (op, target) {
      if (op == 'list') {
        times.add(DateTime.now());
        throw const SyncException('network');
      }
    };
    await addSong(app, 'a', '1');
    await app.syncNow();
    expect(times, hasLength(1));
    expect(app.lastSyncErrorCode, 'network');
    await settle(250);
    expect(times, hasLength(1), reason: 'no scheduled retry');
    cloud.hook = null;
    await app.syncNow();
    expect(cloud.creates, 1);
    expect(app.lastSyncErrorCode, isNull);
  });

  test('errors that need the user are not retried in the background', () async {
    final app = await start();
    cloud.hook = (op, target) {
      if (op == 'list') throw const SyncException('authorization_required');
    };
    cloud.resetCounters();
    await addSong(app, 'a', '1');
    await settle(300);
    expect(cloud.lists, 0);
    expect(app.lastMessage, isNull);
    await app.syncNow();
    expect(app.lastMessage!.code, 'authorization_required');
    expect(cloud.lists, 1);
  });

  test('resuming never syncs; only the explicit action reaches Drive', () async {
    final app = await start(stale: const Duration(days: 1));
    cloud.resetCounters();
    app.onAppResumed();
    await settle(100);
    expect(cloud.requests, 0);
    await app.syncNow();
    expect(cloud.lists, 1);
  });

  test('sign-in and local edits do not sync until Sync now', () async {
    final app = await start();
    await addSong(app, 'keep', 'mine');
    expect(cloud.requests, 0);
    await app.syncNow();
    expect(cloud.names, contains('song-keep.cho'));
    await app.signOutFromSync();
    expect(app.syncConnected, isFalse);
    expect(app.lastSyncAt, isNull);
    expect(app.songs.map((s) => s.id), ['keep']);
    cloud.resetCounters();
    await addSong(app, 'later', 'x');
    await settle(200);
    expect(cloud.requests, 0);
    await app.signInForSync();
    expect(app.syncConnected, isTrue);
    expect(cloud.requests, 0);
    await app.syncNow();
    await until(() => cloud.names.contains('song-later.cho'));
    expect(app.lastSyncAt, isNotNull);
  });

  test('a different account needs an explicit choice before anything happens',
      () async {
    await device.saveSong('mine', 'local');
    final app = await start();
    await app.syncNow();
    await app.signOutFromSync();
    device.auth.id = 'person-b';
    await app.signInForSync();
    expect(app.syncConnected, isTrue);
    expect(app.lastSyncErrorCode, 'account_changed');
    expect(app.syncAccountChangePending, isTrue);
    expect(app.syncPreviousAccountEmail, 'person-a@example.test');
    cloud.resetCounters();
    await app.syncNow();
    expect(app.lastSyncErrorCode, 'account_changed');
    await settle(150);
    expect(cloud.requests, 0, reason: 'no silent merge, no background retry');
    await app.adoptAccount(mergeLocal: true);
    expect(app.lastSyncErrorCode, isNull);
    expect(app.syncAccountChangePending, isFalse);
    expect(app.songs.map((s) => s.id), ['mine']);
    expect(app.lastSyncAt, isNotNull);
  });

  test('conflicts and unusable remote files are reported by code', () async {
    final other = await Device.create(cloud);
    addTearDown(other.close);
    await other.saveSong('s', 'base');
    await other.sync.sync();
    final app = await start();
    await app.syncNow();
    await app.saveSong((await app.loadSong('s'))!.copyWith(body: 'mine'));
    await other.editSong('s', 'theirs');
    await other.sync.sync();
    await app.syncNow();
    expect(app.lastSyncConflicts, 1);
    expect(app.songs, hasLength(2));
    cloud.put('song-bad.cho', 'garbage', properties: {'kind': 'song', 'hash': syncHash('other')});
    await app.syncNow();
    expect(app.lastSyncConflicts, 0);
    expect(app.lastSyncErrorCode, 'invalid_remote_data');
    cloud.remove('song-bad.cho');
    await app.syncNow();
    expect(app.lastSyncErrorCode, isNull);
  });

  test('dispose prevents local edits from causing cloud work', () async {
    final app = await start();
    await addSong(app, 'a', '1');
    cloud.resetCounters();
    controllers.remove(app);
    app.dispose();
    await settle(200);
    expect(cloud.requests, 0);
  });

  test('sync before initialize and without configuration stay handled', () async {
    final fresh = AppController(
      discovery: SourceDiscoveryService([_QuietCatalog()]),
    );
    await fresh.signInForSync();
    expect(fresh.lastSyncErrorCode, 'not_initialized');
    expect(fresh.autoSyncEnabled, isFalse);
    controllers.add(fresh);
    fresh.onAppResumed(); // harmless
    controllers.remove(fresh);
    fresh.dispose();
  });

  test('a failed sync still refreshes the cache from what it committed', () async {
    final other = await Device.create(cloud);
    addTearDown(other.close);
    final app = await start();
    for (var i = 0; i < 3; i++) {
      await other.saveSong('p$i', 'body $i');
    }
    await other.sync.sync();
    var reads = 0;
    cloud.hook = (op, target) {
      if (op == 'read' && ++reads == 3) throw const SyncException('network');
    };
    await app.syncNow();
    cloud.hook = null;
    expect(app.lastSyncErrorCode, 'network');
    expect(app.songs, hasLength(2), reason: 'pulled items are committed');
    final pulled = app.songs.first;
    expect(app.songHash(pulled.id), isNotNull);
    expect(await app.saveSong(pulled.copyWith(body: 'edited')), isTrue);
  });

  test('a wiped cloud asks before deleting; the user can keep or confirm', () async {
    final app = await start();
    await app.syncNow();
    for (var i = 0; i < 6; i++) {
      await addSong(app, 'w$i', 'body $i');
    }
    await app.syncNow();
    expect(cloud.names, hasLength(6));
    for (final name in List.of(cloud.names)) {
      cloud.remove(name);
    }
    await app.syncNow();
    expect(app.lastSyncErrorCode, 'remote_listing_suspicious');
    expect(app.syncSuspiciousDeletionCount, 6);
    expect(app.songs, hasLength(6));
    await app.keepLocalAfterRemoteDeletions();
    expect(app.lastSyncErrorCode, isNull);
    expect(cloud.names, hasLength(6));
    expect(app.songs, hasLength(6));
    for (final name in List.of(cloud.names)) {
      cloud.remove(name);
    }
    await app.syncNow();
    expect(app.lastSyncErrorCode, 'remote_listing_suspicious');
    await app.confirmRemoteDeletions();
    expect(app.lastSyncErrorCode, isNull);
    expect(app.songs, isEmpty);
  });

  test('a favourite tap flips the stored value, not a stale snapshot', () async {
    final app = await start();
    await addSong(app, 'f', 'x');
    final snapshot = app.songs.single;
    expect(snapshot.favorite, isFalse);
    // Changed elsewhere (e.g. by a sync) while the UI still shows the snapshot.
    await device.repo.saveSong((await device.repo.getSong('f'))!.copyWith(favorite: true));
    await app.toggleFavorite(snapshot);
    expect((await app.loadSong('f'))!.favorite, isFalse);
  });

  test('concurrent writes leave the cache and hashes on the newest state', () async {
    final app = await start();
    await Future.wait([
      addSong(app, 'c1', 'one'),
      addSong(app, 'c2', 'two'),
      addSong(app, 'c3', 'three'),
    ]);
    expect(app.songs.map((s) => s.id).toSet(), {'c1', 'c2', 'c3'});
    for (final id in ['c1', 'c2', 'c3']) {
      expect(app.songHash(id), await device.repo.getSongHash(id));
    }
  });

  test('an edit made before shutdown stays local on next start', () async {
    await device.saveSong('a', 'one');
    await device.sync.sync();
    await device.saveSong('b', 'unsynced edit');
    final app = await start(stale: const Duration(hours: 1));
    expect(cloud.names, isNot(contains('song-b.cho')));
    await app.syncNow();
    expect(cloud.names, contains('song-b.cho'));
    expect(app.lastSyncErrorCode, isNull);
  });

  test('overlapping initialize calls open the library once', () async {
    final app = await start();
    await Future.wait([app.initialize(), app.initialize()]);
    expect(app.initialized, isTrue);
  });
}
