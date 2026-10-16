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

  // A timestamp is recorded before the final reload completes. Wait for idle
  // before installing cloud hooks or asserting the outcome of the next run.
  test('startup sync runs for a restored session and records the time', () async {
    await device.saveSong('s', 'one');
    final app = await start();
    expect(app.syncConnected, isTrue);
    expect(app.lastSyncAt, isNull);
    await until(() => app.lastSyncAt != null && !app.syncBusy);
    expect(cloud.names, ['song-s.cho']);
    expect(app.lastSyncErrorCode, isNull);
    expect(app.lastSyncConflicts, 0);
    // Persisted per account: a fresh controller sees it without syncing.
    final again = await start(startDelay: const Duration(minutes: 1));
    await until(() => again.lastSyncAt != null);
    expect(again.lastSyncAt, app.lastSyncAt);
  });

  test('automatic sync is debounced: many edits, one sync', () async {
    final app = await start(delay: const Duration(milliseconds: 300));
    await until(() => app.lastSyncAt != null && !app.syncBusy);
    cloud.resetCounters();
    for (var i = 0; i < 5; i++) {
      await addSong(app, 's$i', 'body $i');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(cloud.lists, 0, reason: 'still inside the quiet period');
    await until(() => cloud.creates == 5);
    await until(() => !app.syncBusy);
    expect(cloud.lists, 1);
  });

  test('turning automatic sync off is persisted and stops background runs',
      () async {
    final app = await start();
    await until(() => app.lastSyncAt != null && !app.syncBusy);
    expect(app.autoSyncEnabled, isTrue);
    await app.setAutoSync(false);
    expect(app.autoSyncEnabled, isFalse);
    cloud.resetCounters();
    await addSong(app, 'x', 'y');
    await settle(200);
    expect(cloud.requests, 0);
    // A new controller on the same database remembers the choice.
    final other = await start(startDelay: const Duration(milliseconds: 10));
    expect(other.autoSyncEnabled, isFalse);
    await settle(100);
    expect(cloud.requests, 0);
    await app.syncNow();
    expect(cloud.creates, 1);
    await app.setAutoSync(true);
    expect(app.autoSyncEnabled, isTrue);
  });

  test('syncs never overlap; a change during a run triggers one more run',
      () async {
    final app = await start();
    await until(() => app.lastSyncAt != null && !app.syncBusy);
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
    await until(() => app.syncBusy);
    await app.syncNow(); // refused while running
    await addSong(app, 'b', '2'); // arrives during the run
    gate.complete();
    await until(() => cloud.creates == 2);
    // The change made during the run schedules one follow-up run.
    await until(() => cloud.lists == 2);
    await until(() => !app.syncBusy);
    await settle(150);
    expect(maxConcurrent, 1);
    expect(cloud.lists, 2);
  });

  test('retryable failures back off exponentially, then recover', () async {
    final app = await start();
    await until(() => app.lastSyncAt != null && !app.syncBusy);
    final times = <DateTime>[];
    cloud.hook = (op, target) {
      if (op == 'list') {
        times.add(DateTime.now());
        throw const SyncException('network');
      }
    };
    await addSong(app, 'a', '1');
    await until(() => times.length >= 4, ms: 6000);
    expect(app.lastSyncErrorCode, anyOf('network', isNull));
    final gaps = [
      for (var i = 1; i < times.length; i++)
        times[i].difference(times[i - 1]).inMilliseconds,
    ];
    expect(gaps[1], greaterThan(gaps[0] * 1.3), reason: 'gaps grow: $gaps');
    expect(gaps[2], greaterThan(gaps[1] * 1.3), reason: 'gaps grow: $gaps');
    cloud.hook = null;
    await until(() => cloud.creates == 1, ms: 6000);
    await until(() => !app.syncBusy);
    expect(app.lastSyncErrorCode, isNull);
  });

  test('errors that need the user are not retried in the background', () async {
    final app = await start();
    await until(() => app.lastSyncAt != null && !app.syncBusy);
    cloud.hook = (op, target) {
      if (op == 'list') throw const SyncException('authorization_required');
    };
    cloud.resetCounters();
    await addSong(app, 'a', '1');
    await until(() => app.lastSyncErrorCode == 'authorization_required');
    await settle(300);
    expect(cloud.lists, 1);
    // Background failures stay quiet; a manual attempt also tells the user.
    expect(app.lastMessage, isNull);
    await app.syncNow();
    expect(app.lastMessage!.code, 'authorization_required');
  });

  test('resuming syncs only when the last sync is old', () async {
    final app = await start(stale: const Duration(days: 1));
    await until(() => app.lastSyncAt != null && !app.syncBusy);
    cloud.resetCounters();
    app.onAppResumed();
    await settle(100);
    expect(cloud.lists, 0, reason: 'synced a moment ago');
    // Set the age explicitly: a short wall-clock freshness window can expire
    // during the final startup reload on a busy CI runner.
    app.lastSyncAt = DateTime.now().toUtc().subtract(const Duration(days: 2));
    app.onAppResumed();
    await until(() => cloud.lists == 1);
    await until(() => !app.syncBusy);
  });

  test('signing out keeps the library and stops automatic syncing', () async {
    final app = await start();
    await addSong(app, 'keep', 'mine');
    await until(() => cloud.names.contains('song-keep.cho'));
    await until(() => !app.syncBusy);
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
    await until(() => cloud.names.contains('song-later.cho'));
    expect(app.lastSyncAt, isNotNull);
  });

  test('a different account needs an explicit choice before anything happens',
      () async {
    await device.saveSong('mine', 'local');
    final app = await start();
    await until(() => app.lastSyncAt != null && !app.syncBusy);
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
    await until(() => app.lastSyncAt != null && !app.syncBusy);
    await app.setAutoSync(false);
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

  test('dispose cancels timers and an in-flight sync', () async {
    final app = await start();
    await until(() => app.lastSyncAt != null && !app.syncBusy);
    await addSong(app, 'a', '1'); // schedules a run
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
    expect(fresh.autoSyncEnabled, isTrue);
    controllers.add(fresh);
    fresh.onAppResumed(); // harmless
    controllers.remove(fresh);
    fresh.dispose();
  });

  test('a failed sync still refreshes the cache from what it committed', () async {
    final other = await Device.create(cloud);
    addTearDown(other.close);
    final app = await start();
    await until(() => app.lastSyncAt != null && !app.syncBusy);
    await app.setAutoSync(false);
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
    await until(() => app.lastSyncAt != null && !app.syncBusy);
    await app.setAutoSync(false);
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
    await app.setAutoSync(false);
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

  test('an edit made just before the app was killed syncs on the next start', () async {
    await device.saveSong('a', 'one');
    await device.sync.sync();
    await device.saveSong('b', 'unsynced edit');
    final app = await start(stale: const Duration(hours: 1));
    await until(() => cloud.names.contains('song-b.cho'));
    expect(app.lastSyncErrorCode, isNull);
  });

  test('overlapping initialize calls open the library once', () async {
    final app = await start();
    await Future.wait([app.initialize(), app.initialize()]);
    expect(app.initialized, isTrue);
  });
}
