import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';

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
  SongDocument song(
    String id, {
    String body = '[C]A lyric',
    String title = 'A title',
    List<TimingTrack> tracks = const [],
  }) => SongDocument(
    id: id,
    title: title,
    artist: 'Artist',
    body: body,
    timingTracks: tracks,
  );
  Future<int> outboxCount([String? kind]) async => (await repo.database.query(
    'outbox',
    where: kind == null ? null : 'object_kind = ?',
    whereArgs: kind == null ? null : [kind],
  )).length;

  group('conflicting imports', () {
    test('collection import forks a differing song and keeps local edits', () async {
      await repo.saveSong(song('x', body: 'Local edit'));
      await repo.importCollection(
        [song('x', body: 'Imported text'), song('y')],
        [
          SetlistDocument(
            id: 'list',
            name: 'Imported',
            entries: [const SetlistEntry(id: 'e1', songId: 'x')],
          ),
        ],
      );
      expect((await repo.getSong('x'))!.body, 'Local edit');
      final songs = await repo.listSongs();
      expect(songs, hasLength(3));
      final fork = songs.singleWhere((s) => s.body == 'Imported text');
      expect(fork.id, isNot('x'));
      // The imported setlist points at the imported copy.
      expect((await repo.getSetlist('list'))!.entries.single.songId, fork.id);
    });

    test('identical re-import is a no-op', () async {
      final original = song('x');
      await repo.saveSong(original);
      final before = await outboxCount();
      await repo.importCollection([original], const []);
      expect(await repo.listSongs(), hasLength(1));
      expect(await outboxCount(), before);
    });

    test('saveImportedSong forks a differing song with the same id', () async {
      await repo.saveSong(song('x', body: 'Local edit'));
      final saved = await repo.saveImportedSong(song('x', body: 'Other'));
      expect(saved.id, isNot('x'));
      expect((await repo.getSong('x'))!.body, 'Local edit');
      expect((await repo.getSong(saved.id))!.body, 'Other');
    });
  });

  group('search', () {
    test('does not match base64 x_verse_data payload', () async {
      final track = parseLrc(
        [for (var i = 0; i < 40; i++) '[00:${(i + 10)}]Line $i'].join('\n'),
        sourceDocumentId: 'x:1',
      );
      await repo.saveSong(song('1', tracks: [track]));
      final document =
          (await repo.database.query('songs')).single['document'] as String;
      final dataLine = document
          .split('\n')
          .firstWhere((l) => l.startsWith('{x_verse_data:'));
      final fragment = dataLine.split(' ').last.substring(40, 56);
      expect(document, contains(fragment));
      expect(await repo.listSongs(query: fragment), isEmpty);
      expect(await repo.listSongs(query: 'x_verse'), isEmpty);
      expect(await repo.listSongs(query: 'A lyric'), hasLength(1));
      expect(await repo.listSongs(query: 'artist'), hasLength(1));
    });

    test('setlist search escapes LIKE wildcards', () async {
      await repo.saveSetlist(SetlistDocument(id: 'a', name: 'A_B'));
      await repo.saveSetlist(SetlistDocument(id: 'b', name: 'AxB'));
      expect((await repo.listSetlists(query: '_')).map((s) => s.id), ['a']);
      expect(await repo.listSetlists(query: '%'), isEmpty);
      expect(await repo.listSetlists(query: 'A'), hasLength(2));
    });
  });

  group('setlists', () {
    test('entry id collisions across setlists are regenerated', () async {
      await repo.saveSong(song('1'));
      SetlistDocument list(String id) => SetlistDocument(
        id: id,
        name: id,
        entries: [
          const SetlistEntry(id: 'same', songId: '1'),
          const SetlistEntry(id: 'same', songId: '1'),
        ],
      );
      await repo.saveSetlist(list('one'));
      await repo.saveSetlist(list('two'));
      final one = (await repo.getSetlist('one'))!;
      final two = (await repo.getSetlist('two'))!;
      expect(one.entries, hasLength(2));
      expect(two.entries, hasLength(2));
      final ids = [...one.entries, ...two.entries].map((e) => e.id).toSet();
      expect(ids, hasLength(4));
      // Re-saving the same setlist keeps its own ids stable.
      await repo.saveSetlist(one);
      expect(
        (await repo.getSetlist('one'))!.entries.map((e) => e.id),
        one.entries.map((e) => e.id),
      );
    });

    test('collection import with colliding entry ids succeeds', () async {
      await repo.saveSong(song('1'));
      await repo.saveSetlist(
        SetlistDocument(
          id: 'local',
          name: 'Local',
          entries: [const SetlistEntry(id: 'e', songId: '1')],
        ),
      );
      await repo.importCollection(
        [song('2')],
        [
          SetlistDocument(
            id: 'imported',
            name: 'Imported',
            entries: [const SetlistEntry(id: 'e', songId: '2')],
          ),
        ],
      );
      expect((await repo.getSetlist('local'))!.entries.single.id, 'e');
      final imported = (await repo.getSetlist('imported'))!;
      expect(imported.entries.single.songId, '2');
      expect(imported.entries.single.id, isNot('e'));
    });

    test('deleting a song touches and queues affected setlists', () async {
      await repo.saveSong(song('1'));
      await repo.saveSong(song('2'));
      final old = DateTime.utc(2020);
      await repo.saveSetlist(
        SetlistDocument(
          id: 'list',
          name: 'L',
          updatedAt: old,
          entries: [
            const SetlistEntry(id: 'a', songId: '1'),
            const SetlistEntry(id: 'b', songId: '2'),
          ],
        ),
      );
      await repo.saveSetlist(SetlistDocument(id: 'other', name: 'O'));
      final before = await outboxCount('setlist');
      await repo.deleteSong('1');
      final list = (await repo.getSetlist('list'))!;
      expect(list.entries.map((e) => e.id), ['b']);
      expect(list.updatedAt.isAfter(old), isTrue);
      expect((await repo.getSetlist('other'))!.updatedAt.year, isNot(2020));
      final queued = await repo.database.query(
        'outbox',
        where: 'object_kind = ? AND object_id = ?',
        whereArgs: ['setlist', 'list'],
      );
      expect(queued.length, greaterThan(0));
      // Exactly one new setlist outbox row: the untouched setlist is not queued.
      expect(await outboxCount('setlist'), before + 1);
    });
  });

  group('sync', () {
    test('setlist referencing a song deleted in the same batch conflicts', () async {
      await repo.saveSong(song('1'));
      await repo.saveSong(song('2'));
      final result = await repo.applySyncChanges(
        const [],
        [
          SetlistDocument(
            id: 'new',
            name: 'N',
            entries: [
              const SetlistEntry(id: 'n1', songId: '1'),
              const SetlistEntry(id: 'n2', songId: '2'),
            ],
          ),
          SetlistDocument(
            id: 'ok',
            name: 'OK',
            entries: [const SetlistEntry(id: 'o1', songId: '2')],
          ),
        ],
        expectedSongHashes: {'1': await repo.getSongHash('1')},
        expectedSetlistHashes: {'new': null, 'ok': null},
        deletedSongIds: ['1'],
      );
      expect(result['conflictingSetlistIds'], ['new']);
      expect(await repo.getSetlist('new'), isNull);
      expect(result['savedSetlistIds'], ['ok']);
      expect(
        (result['savedSetlistHashes'] as Map)['ok'],
        await repo.getSetlistHash('ok'),
      );
    });

    test('saved hash matches stored state when entry ids were regenerated', () async {
      await repo.saveSong(song('1'));
      await repo.saveSetlist(
        SetlistDocument(
          id: 'a',
          name: 'A',
          entries: [const SetlistEntry(id: 'dup', songId: '1')],
        ),
      );
      final result = await repo.applySyncChanges(
        const [],
        [
          SetlistDocument(
            id: 'b',
            name: 'B',
            entries: [const SetlistEntry(id: 'dup', songId: '1')],
          ),
        ],
        expectedSongHashes: const {},
        expectedSetlistHashes: {'b': null},
      );
      expect(
        (result['savedSetlistHashes'] as Map)['b'],
        await repo.getSetlistHash('b'),
      );
    });
  });
}
