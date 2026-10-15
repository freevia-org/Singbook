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

  test('startup sync runs for a restored session and records the time', () async {
    await device.saveSong('s', 'one');
    final app = await start();
    expect(app.syncConnected, isTrue);
    expect(app.lastSyncAt, isNull);
    await until(() => app.lastSyncAt != null);
    expect(cloud.names, ['song-s.cho']);
    expect(app.lastSyncErrorCode, isNull);
    expect(app.lastSyncConflicts, 0);
    // Persisted per account: a fresh controller sees it without syncing.
    final again = await start(startDelay: const Duration(minutes: 1));
    expect(again.lastSyncAt, app.lastSyncAt);
  });

  test('automatic sync is debounced: many edits, one sync', () async {
    final app = await start(delay: const Duration(milliseconds: 300));
    await until(() => app.lastSyncAt != null);
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
    await until(() => app.lastSyncAt != null);
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
    await until(() => app.lastSyncAt != null);
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
    await until(() => app.lastSyncAt != null);
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
    await until(() => app.lastSyncAt != null);
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
    final app = await start(stale: const Duration(milliseconds: 150));
    await until(() => app.lastSyncAt != null);
    cloud.resetCounters();
    app.onAppResumed();
    await settle(100);
    expect(cloud.lists, 0, reason: 'synced a moment ago');
    await settle(150);
    app.onAppResumed();
    await until(() => cloud.lists == 1);
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
    await until(() => app.lastSyncAt != null);
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
    await until(() => app.lastSyncAt != null);
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
}
