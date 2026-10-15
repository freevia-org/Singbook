import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';

void main() {
  late LibraryRepository repo;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() => repo.close());
  SongDocument song(String body) =>
      SongDocument(id: 's', title: 'T', artist: 'A', body: body);
  Future<int> outbox(String kind) async => (await repo.database.query(
    'outbox',
    where: 'object_kind = ?',
    whereArgs: [kind],
  )).length;

  test('saveSongIfUnchanged applies on match, absent, or null expectation', () async {
    expect(
      await repo.saveSongIfUnchanged(song('one'), 'whatever'),
      isTrue,
      reason: 'absent song',
    );
    final h1 = await repo.getSongHash('s');
    expect(await repo.saveSongIfUnchanged(song('two'), h1), isTrue);
    expect(await repo.saveSongIfUnchanged(song('three'), null), isTrue);
    expect((await repo.getSong('s'))!.body, 'three');
  });

  test('saveSongIfUnchanged refuses a stale hash and writes nothing', () async {
    await repo.saveSong(song('one'));
    final stale = await repo.getSongHash('s');
    await repo.saveSong(song('newer'));
    final queued = await outbox('song');
    expect(await repo.saveSongIfUnchanged(song('mine'), stale), isFalse);
    expect((await repo.getSong('s'))!.body, 'newer');
    expect(await outbox('song'), queued);
  });

  test('a sync apply racing a stale save: no overwrite', () async {
    await repo.saveSong(song('one'));
    final stale = await repo.getSongHash('s');
    final applied = repo.applySyncChanges(
      [song('from sync')],
      const [],
      expectedSongHashes: {'s': stale},
      expectedSetlistHashes: const {},
    );
    final save = repo.saveSongIfUnchanged(song('mine'), stale);
    final result = await applied;
    expect((result['savedSongIds'] as List), ['s']);
    expect(await save, isFalse);
    expect((await repo.getSong('s'))!.body, 'from sync');
  });

  test('saveSetlistIfUnchanged compares and sets atomically', () async {
    await repo.saveSong(song('x'));
    SetlistDocument set(String name) => SetlistDocument(
      id: 'l',
      name: name,
      entries: [const SetlistEntry(id: 'e', songId: 's')],
    );
    expect(await repo.saveSetlistIfUnchanged(set('one'), 'any'), isTrue);
    final h1 = await repo.getSetlistHash('l');
    await repo.saveSetlist(set('newer'));
    expect(await repo.saveSetlistIfUnchanged(set('stale'), h1), isFalse);
    expect((await repo.getSetlist('l'))!.name, 'newer');
    final h2 = await repo.getSetlistHash('l');
    expect(await repo.saveSetlistIfUnchanged(set('fresh'), h2), isTrue);
    expect((await repo.getSetlist('l'))!.name, 'fresh');
  });

  test('setlists applied from sync are not echoed into the outbox', () async {
    await repo.saveSong(song('x'));
    await repo.database.delete('outbox');
    await repo.applySyncChanges(
      const [],
      [
        SetlistDocument(
          id: 'l',
          name: 'Remote',
          entries: [const SetlistEntry(id: 'e', songId: 's')],
        ),
      ],
      expectedSongHashes: const {},
      expectedSetlistHashes: {'l': null},
    );
    expect(await repo.getSetlist('l'), isNotNull);
    expect(await outbox('setlist'), 0);
    // A remote song deletion still modifies local setlists genuinely.
    await repo.applySyncChanges(
      const [],
      const [],
      expectedSongHashes: {'s': await repo.getSongHash('s')},
      expectedSetlistHashes: const {},
      deletedSongIds: ['s'],
    );
    expect(await outbox('setlist'), 1);
  });
}
