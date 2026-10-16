import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/chordpro.dart';
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
    List<TimingTrack> tracks = const [],
  }) => SongDocument(
    id: id,
    title: 'A title',
    artist: 'Artist',
    body: body,
    timingTracks: tracks,
    extra: {'selectedSourceId': 'source:1'},
  );
  test(
    'starts empty and stores complete documents and safe settings',
    () async {
      expect(await repo.listSongs(), isEmpty);
      final original = song(
        '1',
        tracks: [parseLrc('[00:01]A lyric', sourceDocumentId: 'source:1')],
      );
      await repo.saveSong(original);
      expect(
        (await repo.getSong('1'))!.timingTracks.single.raw,
        '[00:01]A lyric',
      );
      await repo.setSetting('preferences', {
        'theme': 'dark',
        'locale': 'uk',
        'enabled': ['genius'],
      });
      expect((await repo.getSetting('preferences'))['locale'], 'uk');
      expect(await repo.getSetting('missing'), isNull);
    },
  );
  test(
    'editing song preserves setlist entries and repeated occurrences',
    () async {
      await repo.saveSong(song('1'));
      await repo.saveSetlist(
        SetlistDocument(
          id: 'list',
          name: 'Practice',
          entries: [
            const SetlistEntry(id: 'first', songId: '1'),
            const SetlistEntry(
              id: 'repeat',
              songId: '1',
              overrides: {'capo': 2},
            ),
          ],
        ),
      );
      await repo.saveSong(song('1', body: '[D]New lyric'));
      final list = (await repo.getSetlist('list'))!;
      expect(list.entries.map((e) => e.id), ['first', 'repeat']);
      expect(list.entries.last.overrides['capo'], 2);
    },
  );
  test(
    'invalid setlist replacement rolls back old entries and metadata',
    () async {
      await repo.saveSong(song('1'));
      await repo.saveSetlist(
        SetlistDocument(
          id: 'list',
          name: 'Old',
          entries: [const SetlistEntry(id: 'entry', songId: '1')],
        ),
      );
      await expectLater(
        repo.saveSetlist(
          SetlistDocument(
            id: 'list',
            name: 'Broken',
            entries: [const SetlistEntry(id: 'invalid', songId: 'missing')],
          ),
        ),
        throwsA(anything),
      );
      final list = (await repo.getSetlist('list'))!;
      expect(list.name, 'Old');
      expect(list.entries.single.id, 'entry');
    },
  );
  test(
    'backup snapshot includes library and app preferences together',
    () async {
      await repo.saveSong(song('1'));
      await repo.saveSetlist(
        SetlistDocument(
          id: 'list',
          name: 'Practice',
          entries: [
            const SetlistEntry(id: 'first', songId: '1'),
            const SetlistEntry(
              id: 'repeat',
              songId: '1',
              overrides: {'capo': 2},
            ),
          ],
        ),
      );
      await repo.setSetting('app', {'themeMode': 'dark'});
      final snapshot = await repo.backupSnapshot();
      expect(snapshot.songs.map((value) => value.id), ['1']);
      expect(snapshot.setlists.single.entries.map((entry) => entry.id), [
        'first',
        'repeat',
      ]);
      expect(snapshot.setlists.single.entries.last.overrides['capo'], 2);
      expect(snapshot.appSettings['themeMode'], 'dark');
      expect(snapshot.libraryFingerprint, isNotEmpty);
    },
  );

  test(
    'backup replace is atomic and preserves repeated entries and overrides',
    () async {
      await repo.saveSong(song('old'));
      await repo.saveSong(song('incoming'));
      await repo.saveSetlist(
        SetlistDocument(
          id: 'old-list',
          name: 'Old',
          entries: [const SetlistEntry(id: 'old-entry', songId: 'old')],
        ),
      );
      final expected = (await repo.backupSnapshot()).libraryFingerprint;
      final replacement = SetlistDocument(
        id: 'new-list',
        name: 'New',
        notes: 'Keep these notes',
        entries: [
          const SetlistEntry(id: 'first', songId: 'incoming'),
          const SetlistEntry(
            id: 'repeat',
            songId: 'incoming',
            overrides: {'capo': 3},
          ),
        ],
      );
      await repo.replaceLibrary(
        [song('incoming', body: '[D]New lyric')],
        [replacement],
        appSettings: {'themeMode': 'light'},
        expectedLibraryFingerprint: expected,
      );
      expect((await repo.listSongs()).map((value) => value.id), ['incoming']);
      final stored = (await repo.listSetlists()).single;
      expect(stored.id, 'new-list');
      expect(stored.notes, 'Keep these notes');
      expect(stored.entries.map((entry) => entry.id), ['first', 'repeat']);
      expect(stored.entries.last.overrides['capo'], 3);
      expect((await repo.getSetting('app'))['themeMode'], 'light');
    },
  );

  test(
    'backup replace rejects a stale preview before changing local data',
    () async {
      await repo.saveSong(song('1'));
      final expected = (await repo.backupSnapshot()).libraryFingerprint;
      await repo.saveSong(song('1', body: '[G]Changed after preview'));
      await expectLater(
        repo.replaceLibrary(
          [song('replacement')],
          [],
          expectedLibraryFingerprint: expected,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'stale_backup_preview',
          ),
        ),
      );
      expect((await repo.listSongs()).map((value) => value.id), ['1']);
      expect((await repo.getSong('1'))!.body, '[G]Changed after preview');
    },
  );
  test(
    'backup restore guard includes preferences written after preview',
    () async {
      await repo.saveSong(song('1'));
      final expected = (await repo.backupSnapshot()).libraryFingerprint;
      await repo.setSetting('app', {
        'themeMode': 'dark',
        'accountHint': 'local',
      });
      await expectLater(
        repo.importCollection(
          [song('replacement')],
          const [],
          appSettings: {'themeMode': 'light'},
          expectedLibraryFingerprint: expected,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'stale_backup_preview',
          ),
        ),
      );
      expect((await repo.listSongs()).map((value) => value.id), ['1']);
      expect((await repo.getSetting('app'))['themeMode'], 'dark');
      expect((await repo.getSetting('app'))['accountHint'], 'local');
    },
  );
  test('repeated import merges newly found timing into original ID', () async {
    final first = await repo.saveImportedSong(song('1'));
    final second = await repo.saveImportedSong(
      song(
        '2',
        tracks: [parseLrc('[00:01]A lyric', sourceDocumentId: 'lrclib:1')],
      ),
    );
    expect(second.id, first.id);
    expect(await repo.listSongs(), hasLength(1));
    expect((await repo.getSong('1'))!.timingTracks, hasLength(1));
    final alternative = await repo.saveImportedSong(
      song('3', body: '[G]A lyric'),
    );
    expect(alternative.id, '3');
    expect(await repo.listSongs(), hasLength(2));
  });
  test('history clear preserves songs setlists and favorite flags', () async {
    await repo.saveSong(song('1').copyWith(favorite: true));
    await repo.saveSetlist(
      SetlistDocument(id: 'list', name: 'Practice', favorite: true),
    );
    for (var i = 0; i < 4; i++) {
      await repo.addActivity(
        ActivityEntry(
          id: 'event-$i',
          objectId: '1',
          objectKind: 'song',
          action: 'open',
          occurredAt: DateTime.utc(2026, 1, i + 1),
        ),
      );
    }
    expect((await repo.listActivity(limit: 2)).map((a) => a.id), [
      'event-3',
      'event-2',
    ]);
    expect((await repo.listActivity(limit: 2, offset: 2)).map((a) => a.id), [
      'event-1',
      'event-0',
    ]);
    await repo.clearActivity();
    expect(await repo.listActivity(), isEmpty);
    expect(await repo.listSongs(favoritesOnly: true), hasLength(1));
    expect(await repo.listSetlists(favoritesOnly: true), hasLength(1));
  });
  test('song deletion cascades entries but does not delete setlists', () async {
    await repo.saveSong(song('1'));
    await repo.saveSetlist(
      SetlistDocument(
        id: 'list',
        name: 'Practice',
        entries: [const SetlistEntry(id: 'entry', songId: '1')],
      ),
    );
    await repo.deleteSong('1');
    expect((await repo.getSetlist('list'))!.entries, isEmpty);
    final outbox = await repo.database.query(
      'outbox',
      where: 'action = ?',
      whereArgs: ['delete'],
    );
    expect(outbox.single['object_id'], '1');
  });
  test('library filters do not interpret SQL wildcard input', () async {
    await repo.saveSong(song('1'));
    expect(await repo.listSongs(query: 'A lyric'), hasLength(1));
    expect(await repo.listSongs(query: '%'), isEmpty);
  });
  test(
    're-discovery preserves edited arrangement and stores new timing as stale',
    () async {
      await repo.saveSong(
        song('1', body: '[D]My changed lyric').copyWith(favorite: true),
      );
      final track = parseLrc(
        '[00:01]A lyric',
        sourceDocumentId: 'lrclib:1',
      ).copyWith(status: TimingStatus.usable);
      final merged = await repo.saveImportedSong(
        song('2', tracks: [track]),
        existingId: '1',
      );
      expect(merged.id, '1');
      expect(merged.body, '[D]My changed lyric');
      expect(merged.favorite, isTrue);
      expect(merged.timingTracks.single.status, TimingStatus.stale);
    },
  );
  test(
    'collection import commits songs and setlists together or neither',
    () async {
      await expectLater(
        repo.importCollection(
          [song('1')],
          [
            SetlistDocument(
              id: 'list',
              name: 'Broken',
              // Not JSON-encodable: the write fails after the song was stored.
              entries: [
                SetlistEntry(
                  id: 'entry',
                  songId: '1',
                  overrides: {'bad': Object()},
                ),
              ],
            ),
          ],
        ),
        throwsA(anything),
      );
      expect(await repo.listSongs(), isEmpty);
      expect(await repo.database.query('outbox'), isEmpty);
      await repo.importCollection(
        [song('1')],
        [
          SetlistDocument(
            id: 'list',
            name: 'Good',
            entries: [const SetlistEntry(id: 'entry', songId: '1')],
          ),
        ],
      );
      expect((await repo.getSetlist('list'))!.entries.single.songId, '1');
    },
  );
  test(
    'conditional sync cannot overwrite edits made during network request',
    () async {
      await repo.saveSong(song('1'));
      final before = await repo.getSongHash('1');
      await repo.saveSong(song('1', body: 'Locally edited'));
      final report = await repo.applySyncChanges(
        [song('1', body: 'Remote edited'), song('2')],
        [],
        expectedSongHashes: {'1': before, '2': null},
        expectedSetlistHashes: {},
      );
      expect(report['conflictingSongIds'], ['1']);
      expect(report['savedSongIds'], ['2']);
      expect((await repo.getSong('1'))!.body, 'Locally edited');
      final current = await repo.getSongHash('1');
      await repo.applySyncChanges(
        [],
        [],
        expectedSongHashes: {'1': before},
        expectedSetlistHashes: {},
        deletedSongIds: ['1'],
      );
      expect(await repo.getSong('1'), isNotNull);
      await repo.applySyncChanges(
        [],
        [],
        expectedSongHashes: {'1': current},
        expectedSetlistHashes: {},
        deletedSongIds: ['1'],
      );
      expect(await repo.getSong('1'), isNull);
    },
  );
  test(
    'conditional setlist sync rejects stale hashes and absent expectations',
    () async {
      await repo.saveSetlist(SetlistDocument(id: 'list', name: 'Old'));
      final before = await repo.getSetlistHash('list');
      await repo.saveSetlist(SetlistDocument(id: 'list', name: 'Local edit'));
      final result = await repo.applySyncChanges(
        [],
        [
          SetlistDocument(id: 'list', name: 'Remote edit'),
          SetlistDocument(id: 'new', name: 'No expectation'),
        ],
        expectedSongHashes: {},
        expectedSetlistHashes: {'list': before},
      );
      expect(result['conflictingSetlistIds'], ['list', 'new']);
      expect((await repo.getSetlist('list'))!.name, 'Local edit');
    },
  );
  test(
    'opaque future extension keeps its full model on repository reads',
    () async {
      final opaque = SongDocument(
        id: 'opaque',
        title: 'Future',
        artist: 'Artist',
        body: 'A lyric',
        metadata: {'album': 'Album', 'tempo': 94},
        timingTracks: [
          parseLrc('[00:01]A lyric', sourceDocumentId: 'opaque-source'),
        ],
        extra: {
          'custom': {'kept': true},
        },
        preservedExtensions: [
          '{x_verse: 2 future 1}',
          '{x_verse_data: 1/1 e30}',
        ],
        extensionError: 'Unsupported',
      );
      await repo.saveSong(opaque);
      final restored = (await repo.getSong('opaque'))!;
      expect(restored.id, 'opaque');
      expect(restored.metadata['album'], 'Album');
      expect(restored.timingTracks.single.raw, '[00:01]A lyric');
      expect(restored.preservedExtensions, opaque.preservedExtensions);
      expect((await repo.listSongs()).single.toJson(), restored.toJson());

      final rawBefore = (await repo.getSongRaw('opaque'))!;
      final editedMetadata = SongDocument(
        id: restored.id,
        title: restored.title,
        artist: restored.artist,
        body: restored.body,
        metadata: {...restored.metadata, 'localOnlyMetadata': 'Changed'},
        sources: restored.sources,
        timingTracks: restored.timingTracks,
        favorite: restored.favorite,
        createdAt: restored.createdAt,
        updatedAt: restored.updatedAt,
        selectedRecording: restored.selectedRecording,
        activeTimingTrackId: restored.activeTimingTrackId,
        revision: restored.revision + 1,
        extra: restored.extra,
        preservedExtensions: restored.preservedExtensions,
        extensionError: restored.extensionError,
      );
      await repo.saveSong(editedMetadata);
      final rawAfter = (await repo.getSongRaw('opaque'))!;
      expect(rawAfter.document, rawBefore.document);
      expect(rawAfter.hash, isNot(rawBefore.hash));
      expect(await repo.saveSongIfUnchanged(restored, rawBefore.hash), isFalse);

      await repo.saveSong(
        SongDocument(
          id: restored.id,
          title: restored.title,
          artist: restored.artist,
          body: restored.body,
          metadata: restored.metadata,
          createdAt: restored.createdAt,
          updatedAt: restored.updatedAt,
        ),
      );
      final columns = await repo.database.query(
        'songs',
        columns: const ['full_document', 'full_document_hash'],
        where: 'id = ?',
        whereArgs: const ['opaque'],
      );
      expect(columns.single['full_document'], isNull);
      expect(columns.single['full_document_hash'], isNull);
    },
  );

  test(
    'large opaque sidecar is chunk-read by get, list, and backup snapshot',
    () async {
      final large = SongDocument(
        id: 'large-opaque',
        title: 'Large future song',
        artist: 'Band',
        body: 'Words',
        extra: {'largeField': 'x' * (140 * 1024)},
        preservedExtensions: ['{x_verse: unsupported}'],
        extensionError: 'Unsupported x_verse extension',
      );
      await repo.saveSong(large);

      expect(
        (await repo.getSong(large.id))!.extra['largeField'],
        large.extra['largeField'],
      );
      expect(
        (await repo.listSongs()).single.extra['largeField'],
        large.extra['largeField'],
      );
      final snapshot = await repo.backupSnapshot();
      expect(
        snapshot.songs.single.extra['largeField'],
        large.extra['largeField'],
      );
    },
  );

  test('version 3 database upgrades without changing stored song identity', () async {
    final directory = await Directory.systemTemp.createTemp('singbook-v3-');
    final path = '${directory.path}${Platform.pathSeparator}library.db';
    const legacyOpaqueDocument =
        '{title:Legacy opaque}\n{artist:Band}\n{x_verse: 2 future 1}\n{x_verse_data: 1/1 e30}\n\nWords';
    final legacyCreatedAt = DateTime.utc(2020, 1, 1);
    final legacyUpdatedAt = DateTime.utc(2020, 1, 2);
    final legacyOpaqueCreatedAt = DateTime.utc(2017, 4, 3, 2, 1);
    final legacyDocument = ChordProCodec().encode(
      SongDocument(
        id: 'legacy-id',
        title: 'Legacy',
        artist: 'Band',
        body: '[C]Old words',
        createdAt: legacyCreatedAt,
        updatedAt: legacyUpdatedAt,
        revision: 7,
      ),
    );
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE songs (id TEXT PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL, album TEXT, favorite INTEGER NOT NULL DEFAULT 0, document TEXT NOT NULL, content_hash TEXT NOT NULL, lyric_hash TEXT NOT NULL, source_identity TEXT, revision INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, search_text TEXT)',
          );
          await db.execute(
            'CREATE INDEX songs_title_artist ON songs(title COLLATE NOCASE,artist COLLATE NOCASE)',
          );
          await db.execute(
            'CREATE INDEX songs_source ON songs(source_identity,lyric_hash)',
          );
          await db.execute(
            'CREATE TABLE setlists (id TEXT PRIMARY KEY, name TEXT NOT NULL, notes TEXT NOT NULL, favorite INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE setlist_entries (id TEXT PRIMARY KEY, setlist_id TEXT NOT NULL REFERENCES setlists(id) ON DELETE CASCADE, song_id TEXT NOT NULL REFERENCES songs(id) ON DELETE CASCADE, position INTEGER NOT NULL, overrides TEXT NOT NULL, UNIQUE(setlist_id,position))',
          );
          await db.execute(
            'CREATE INDEX setlist_entries_song ON setlist_entries(song_id)',
          );
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE activity (id TEXT PRIMARY KEY, object_id TEXT NOT NULL, object_kind TEXT NOT NULL, action TEXT NOT NULL, occurred_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE INDEX activity_order ON activity(occurred_at DESC,id DESC)',
          );
          await db.execute(
            'CREATE TABLE outbox (id TEXT PRIMARY KEY, object_id TEXT NOT NULL, object_kind TEXT NOT NULL, action TEXT NOT NULL, revision INTEGER, created_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE sync_items (account TEXT NOT NULL, kind TEXT NOT NULL, item_id TEXT NOT NULL, cloud_hash TEXT NOT NULL, local_hash TEXT NOT NULL, PRIMARY KEY(account,kind,item_id))',
          );
          await db.insert('songs', {
            'id': 'legacy-id',
            'title': 'Legacy',
            'artist': 'Band',
            'favorite': 0,
            'document': legacyDocument,
            'content_hash': sha256
                .convert(utf8.encode(legacyDocument))
                .toString(),
            'lyric_hash': 'legacy-lyrics',
            'revision': 7,
            'created_at': legacyCreatedAt.toIso8601String(),
            'updated_at': legacyUpdatedAt.toIso8601String(),
            'search_text': 'legacy\nband\nold words',
          });
          await db.insert('songs', {
            'id': 'legacy-opaque-id',
            'title': 'Legacy opaque',
            'artist': 'Band',
            'favorite': 0,
            'document': legacyOpaqueDocument,
            'content_hash': 'legacy-opaque-hash',
            'lyric_hash': 'legacy-opaque-lyrics',
            'revision': 4,
            'created_at': legacyOpaqueCreatedAt.toIso8601String(),
            'updated_at': '2020-01-02T00:00:00.000Z',
            'search_text': 'legacy opaque\nband\nwords',
          });
        },
      ),
    );
    await old.close();

    final upgraded = await LibraryRepository.open(
      path: path,
      factory: databaseFactoryFfi,
    );
    final restored = (await upgraded.getSong('legacy-id'))!;
    expect(restored.title, 'Legacy');
    expect(restored.revision, 7);
    final raw = (await upgraded.getSongRaw('legacy-id'))!;
    expect(raw.document, legacyDocument);
    expect(raw.hash, sha256.convert(utf8.encode(legacyDocument)).toString());
    final expectedOpaqueCreatedAt = legacyOpaqueCreatedAt;
    expect(
      (await upgraded.getSong('legacy-opaque-id'))!.createdAt,
      expectedOpaqueCreatedAt,
    );
    final listedOpaque = (await upgraded.listSongs()).singleWhere(
      (song) => song.id == 'legacy-opaque-id',
    );
    expect(listedOpaque.createdAt, expectedOpaqueCreatedAt);
    final snapshot = await upgraded.backupSnapshot();
    final snapshotOpaque = snapshot.songs.singleWhere(
      (song) => song.id == 'legacy-opaque-id',
    );
    expect(snapshotOpaque.createdAt, expectedOpaqueCreatedAt);
    final backupRestore = decodeLibraryPackage(
      encodeLibraryPackage(snapshot.songs, snapshot.setlists),
    );
    expect(
      backupRestore.songs
          .singleWhere((song) => song.id == 'legacy-opaque-id')
          .createdAt,
      expectedOpaqueCreatedAt,
    );
    final opaqueRow = await upgraded.database.query(
      'songs',
      columns: const ['document'],
      where: 'id = ?',
      whereArgs: const ['legacy-opaque-id'],
    );
    expect(opaqueRow.single['document'], legacyOpaqueDocument);
    expect(
      (await upgraded.database.rawQuery(
        'PRAGMA user_version',
      )).single.values.single,
      4,
    );
    await upgraded.close();
    await directory.delete(recursive: true);
  });
}
