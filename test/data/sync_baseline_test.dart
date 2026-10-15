import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';

void main() {
  sqfliteFfiInit();
  late LibraryRepository repo;
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('verse-baseline-');
    repo = await LibraryRepository.open(
      path: '${dir.path}/lib.sqlite',
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  SongDocument song(String id, String body) =>
      SongDocument(id: id, title: id, artist: 'A', body: body);

  test('baselines are stored per account and can be forgotten', () async {
    expect(await repo.loadSyncBaselines('acc1'), isEmpty);
    const row = SyncBaseline(kind: 'song', id: 's', cloudHash: 'c', localHash: 'l');
    await repo.writeSyncBaselines(
      'acc1',
      puts: [
        row,
        const SyncBaseline(kind: 'setlist', id: 'x', cloudHash: 'c2', localHash: 'l2'),
      ],
    );
    await repo.writeSyncBaselines('acc2', puts: [row]);
    final one = await repo.loadSyncBaselines('acc1');
    expect(one.keys, unorderedEquals(['song:s', 'setlist:x']));
    expect(one['song:s']!.cloudHash, 'c');
    await repo.writeSyncBaselines(
      'acc1',
      puts: [
        const SyncBaseline(kind: 'song', id: 's', cloudHash: 'new', localHash: 'l'),
      ],
      removeKeys: ['setlist:x'],
    );
    final after = await repo.loadSyncBaselines('acc1');
    expect(after.keys, ['song:s']);
    expect(after['song:s']!.cloudHash, 'new');
    await repo.clearSyncBaselines(exceptAccount: 'acc2');
    expect(await repo.loadSyncBaselines('acc1'), isEmpty);
    expect(await repo.loadSyncBaselines('acc2'), hasLength(1));
    await repo.clearSyncBaselines();
    expect(await repo.loadSyncBaselines('acc2'), isEmpty);
  });

  test('applySyncChanges records the baseline in the same transaction',
      () async {
    final result = await repo.applySyncChanges(
      [song('a', 'one')],
      const [],
      expectedSongHashes: {'a': null},
      expectedSetlistHashes: const {},
      syncAccount: 'acc',
      baselineCloudHashes: {'song:a': 'cloud-1'},
    );
    expect(result['savedSongIds'], ['a']);
    final stored = (await repo.loadSyncBaselines('acc'))['song:a']!;
    expect(stored.cloudHash, 'cloud-1');
    expect(stored.localHash, await repo.getSongHash('a'));
    expect(await repo.database.query('outbox'), isEmpty,
        reason: 'a download is not a local edit');

    // A refused write (the song changed meanwhile) leaves the baseline alone.
    await repo.saveSong(song('a', 'edited'));
    final refused = await repo.applySyncChanges(
      [song('a', 'remote')],
      const [],
      expectedSongHashes: {'a': stored.localHash},
      expectedSetlistHashes: const {},
      syncAccount: 'acc',
      baselineCloudHashes: {'song:a': 'cloud-2'},
    );
    expect(refused['conflictingSongIds'], ['a']);
    expect((await repo.loadSyncBaselines('acc'))['song:a']!.cloudHash, 'cloud-1');

    // Deleting forgets the item; unrelated accounts are untouched.
    await repo.writeSyncBaselines(
      'other',
      puts: [const SyncBaseline(kind: 'song', id: 'a', cloudHash: 'x', localHash: 'y')],
    );
    final hash = await repo.getSongHash('a');
    await repo.applySyncChanges(
      const [],
      const [],
      expectedSongHashes: {'a': hash},
      expectedSetlistHashes: const {},
      deletedSongIds: ['a'],
      syncAccount: 'acc',
      baselineCloudHashes: {'song:a': null},
    );
    expect(await repo.getSong('a'), isNull);
    expect(await repo.loadSyncBaselines('acc'), isEmpty);
    expect(await repo.loadSyncBaselines('other'), hasLength(1));
  });

  test('without a syncAccount no baseline is written', () async {
    await repo.applySyncChanges(
      [song('a', 'one')],
      const [],
      expectedSongHashes: {'a': null},
      expectedSetlistHashes: const {},
      baselineCloudHashes: {'song:a': 'c'},
    );
    expect(await repo.database.query('sync_items'), isEmpty);
  });

  test('the outbox is acknowledged only up to the mark taken before', () async {
    await repo.saveSong(song('a', '1'));
    final mark = await repo.outboxMark();
    await repo.saveSong(song('b', '2'));
    await repo.clearOutboxThrough(mark);
    final left = await repo.database.query('outbox');
    expect(left.map((r) => r['object_id']), ['b']);
    expect(await repo.outboxMark(), greaterThan(mark));
  });

  test('getSongRaw returns the stored document with its hash', () async {
    await repo.saveSong(song('a', 'text'));
    final raw = (await repo.getSongRaw('a'))!;
    expect(raw.document, contains('text'));
    expect(raw.hash, await repo.getSongHash('a'));
    expect(await repo.getSongRaw('missing'), isNull);
  });

  test('a version 1 database gains the sync table when opened', () async {
    final path = '${dir.path}/old.sqlite';
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE songs (id TEXT PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL, album TEXT, favorite INTEGER NOT NULL DEFAULT 0, document TEXT NOT NULL, content_hash TEXT NOT NULL, lyric_hash TEXT NOT NULL, source_identity TEXT, revision INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE outbox (id TEXT PRIMARY KEY, object_id TEXT NOT NULL, object_kind TEXT NOT NULL, action TEXT NOT NULL, revision INTEGER, created_at TEXT NOT NULL)',
          );
        },
      ),
    );
    await old.close();
    final upgraded = await LibraryRepository.open(
      path: path,
      factory: databaseFactoryFfi,
    );
    addTearDown(upgraded.close);
    expect(await upgraded.loadSyncBaselines('x'), isEmpty);
    await upgraded.writeSyncBaselines(
      'x',
      puts: [const SyncBaseline(kind: 'song', id: 's', cloudHash: 'c', localHash: 'l')],
    );
    expect(await upgraded.loadSyncBaselines('x'), hasLength(1));
  });
}
