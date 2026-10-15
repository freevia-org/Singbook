import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';

/// Regression tests for the R1 data-layer review.
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
    String title = 'A title',
    String artist = 'Artist',
    String body = '[C]A lyric',
    JsonMap extra = const {},
  }) => SongDocument(
    id: id,
    title: title,
    artist: artist,
    body: body,
    extra: extra,
  );

  group('R1-09 Unicode search', () {
    test('matches Cyrillic and accented text regardless of case', () async {
      await repo.saveSong(
        song('1', title: 'Привет', artist: 'Éternel', body: '[Am]Здравствуй'),
      );
      expect(await repo.listSongs(query: 'привет'), hasLength(1));
      expect(await repo.listSongs(query: 'ПРИВЕТ'), hasLength(1));
      expect(await repo.listSongs(query: 'éternel'), hasLength(1));
      expect(await repo.listSongs(query: 'ÉTERNEL'), hasLength(1));
      // Lyrics are searched without the chord markup in the way.
      expect(await repo.listSongs(query: 'здравствуй'), hasLength(1));
      expect(await repo.listSongs(query: 'Am'), isEmpty);
      expect(await repo.listSongs(query: 'другое'), isEmpty);
    });

    test('lyrics search ignores chords splitting a word', () async {
      await repo.saveSong(song('1', body: 'Hel[C]lo world'));
      expect(await repo.listSongs(query: 'hello'), hasLength(1));
    });

    test('setlist search is Unicode aware', () async {
      await repo.saveSetlist(SetlistDocument(id: 'a', name: 'Привет'));
      expect((await repo.listSetlists(query: 'привет')).map((s) => s.id), [
        'a',
      ]);
    });

    test('a version 2 database is upgraded and its songs stay searchable', () async {
      final dir = await Directory.systemTemp.createTemp('r1-upgrade-');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/v2.sqlite';
      final document = ChordProCodec().encode(
        song('old', title: 'Привет', body: 'Здравствуй'),
      );
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE songs (id TEXT PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL, album TEXT, favorite INTEGER NOT NULL DEFAULT 0, document TEXT NOT NULL, content_hash TEXT NOT NULL, lyric_hash TEXT NOT NULL, source_identity TEXT, revision INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
            );
            await db.execute(
              'CREATE TABLE setlist_entries (id TEXT PRIMARY KEY, setlist_id TEXT NOT NULL, song_id TEXT NOT NULL, position INTEGER NOT NULL, overrides TEXT NOT NULL)',
            );
            await db.insert('songs', {
              'id': 'old',
              'title': 'Привет',
              'artist': 'Artist',
              'document': document,
              'content_hash': 'h',
              'lyric_hash': 'l',
              'revision': 1,
              'created_at': '2020-01-01T00:00:00.000Z',
              'updated_at': '2020-01-01T00:00:00.000Z',
            });
          },
        ),
      );
      await old.close();
      final upgraded = await LibraryRepository.open(
        path: path,
        factory: databaseFactoryFfi,
      );
      addTearDown(upgraded.close);
      expect(await upgraded.listSongs(query: 'привет'), hasLength(1));
      expect(await upgraded.listSongs(query: 'здравствуй'), hasLength(1));
      final indexes = await upgraded.database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'setlist_entries_song'",
      );
      expect(indexes, hasLength(1));
    });

    test('new databases index setlist entries by song', () async {
      final indexes = await repo.database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'setlist_entries_song'",
      );
      expect(indexes, hasLength(1));
    });
  });

  group('R1-24 pagination', () {
    test('an offset without a limit skips rows', () async {
      for (var i = 0; i < 5; i++) {
        await repo.saveSong(
          song('s$i').copyWith(updatedAt: DateTime.utc(2020, 1, 1 + i)),
        );
      }
      final all = (await repo.listSongs()).map((s) => s.id).toList();
      expect(all, hasLength(5));
      expect(
        (await repo.listSongs(offset: 2)).map((s) => s.id),
        all.sublist(2),
      );
      expect(
        (await repo.listSongs(limit: 2, offset: 1)).map((s) => s.id),
        all.sublist(1, 3),
      );
    });
  });

  group('R1-12 mustNotExist', () {
    test(
      'null hash writes unconditionally unless the song must be absent',
      () async {
        await repo.saveSong(song('1', body: 'first'));
        expect(
          await repo.saveSongIfUnchanged(song('1', body: 'second'), null),
          isTrue,
        );
        expect(
          await repo.saveSongIfUnchanged(
            song('1', body: 'third'),
            null,
            mustNotExist: true,
          ),
          isFalse,
        );
        expect((await repo.getSong('1'))!.body, 'second');
        expect(
          await repo.saveSongIfUnchanged(song('new'), null, mustNotExist: true),
          isTrue,
        );
      },
    );

    test('same for setlists', () async {
      await repo.saveSetlist(SetlistDocument(id: 'l', name: 'one'));
      expect(
        await repo.saveSetlistIfUnchanged(
          SetlistDocument(id: 'l', name: 'two'),
          null,
          mustNotExist: true,
        ),
        isFalse,
      );
      expect((await repo.getSetlist('l'))!.name, 'one');
      expect(
        await repo.saveSetlistIfUnchanged(
          SetlistDocument(id: 'm', name: 'new'),
          null,
          mustNotExist: true,
        ),
        isTrue,
      );
    });
  });

  group('R1-10 collection import of setlists', () {
    test('a differing local setlist with the same id is kept', () async {
      final a = song('a');
      await repo.saveSong(a);
      await repo.saveSetlist(
        SetlistDocument(
          id: 'list',
          name: 'Local',
          notes: 'mine',
          entries: [const SetlistEntry(id: 'e1', songId: 'a')],
        ),
      );
      await repo.importCollection(
        [a],
        [
          SetlistDocument(
            id: 'list',
            name: 'Imported',
            entries: [const SetlistEntry(id: 'e2', songId: 'a')],
          ),
        ],
      );
      final local = (await repo.getSetlist('list'))!;
      expect(local.name, 'Local');
      expect(local.notes, 'mine');
      final lists = await repo.listSetlists();
      expect(lists, hasLength(2));
      final copy = lists.singleWhere((l) => l.id != 'list');
      expect(copy.name, 'Imported');
      expect(copy.entries.single.songId, 'a');
    });

    test('an identical setlist is a no-op', () async {
      final a = song('a');
      await repo.saveSong(a);
      final list = SetlistDocument(
        id: 'list',
        name: 'Same',
        entries: [const SetlistEntry(id: 'e1', songId: 'a')],
      );
      await repo.saveSetlist(list);
      await repo.importCollection([a], [list]);
      expect(await repo.listSetlists(), hasLength(1));
    });

    test(
      'entries for songs that do not exist are dropped, not fatal',
      () async {
        await repo.importCollection(
          [song('a')],
          [
            SetlistDocument(
              id: 'list',
              name: 'Shared',
              entries: [
                const SetlistEntry(id: 'e1', songId: 'a'),
                const SetlistEntry(id: 'e2', songId: 'ghost'),
              ],
            ),
          ],
        );
        expect(await repo.getSong('a'), isNotNull);
        expect((await repo.getSetlist('list'))!.entries.map((e) => e.songId), [
          'a',
        ]);
      },
    );
  });

  group('R1-15/16 saveImportedSong merge', () {
    test('CRLF provider text matches the stored copy', () async {
      await repo.saveSong(
        song(
          '1',
          body: 'Line one\nLine two',
          extra: {'selectedSourceId': 'p:1'},
        ),
      );
      final saved = await repo.saveImportedSong(
        song(
          'other',
          body: 'Line one\r\nLine two',
          extra: {'selectedSourceId': 'p:1'},
        ),
      );
      expect(saved.id, '1');
      expect(await repo.listSongs(), hasLength(1));
    });

    test('provenance maps merge key by key', () async {
      await repo.saveSong(
        song(
          '1',
          extra: {
            'selectedSourceId': 'p:1',
            'fieldOrigins': {'title': 'user'},
          },
        ),
      );
      final saved = await repo.saveImportedSong(
        song(
          'n',
          extra: {
            'selectedSourceId': 'p:1',
            'fieldOrigins': {'album': 'p:1', 'title': 'p:1'},
          },
        ),
      );
      expect(saved.extra['fieldOrigins'], {'title': 'user', 'album': 'p:1'});
    });

    test(
      'an existing song with an opaque extension is not merged into',
      () async {
        final opaque = ChordProCodec().decode(
          '{title: Old}\n{x_verse: 1 json-base64url 2}\n{x_verse_data: 1/2 abcd}\n\nBody',
        );
        expect(opaque.extensionError, isNotNull);
        await repo.saveSong(opaque.copyWith(id: 'op'));
        final saved = await repo.saveImportedSong(
          song('new', body: 'Body'),
          existingId: 'op',
        );
        expect(saved.id, isNot('op'));
        expect(await repo.listSongs(), hasLength(2));
        expect((await repo.getSong('op'))!.extensionError, isNotNull);
      },
    );
  });
}
