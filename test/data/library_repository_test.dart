import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:verse_mobile/data/library_repository.dart';
import 'package:verse_mobile/domain/models.dart';
import 'package:verse_mobile/domain/timing.dart';

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
              entries: [const SetlistEntry(id: 'entry', songId: 'missing')],
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
    'opaque future extension keeps database identity stable across reopen',
    () async {
      final opaque = SongDocument(
        id: 'opaque',
        title: 'Future',
        artist: 'Artist',
        body: 'A lyric',
        preservedExtensions: [
          '{x_verse: 2 future 1}',
          '{x_verse_data: 1/1 e30}',
        ],
        extensionError: 'Unsupported',
      );
      await repo.saveSong(opaque);
      expect((await repo.getSong('opaque'))!.id, 'opaque');
      expect((await repo.listSongs()).single.id, 'opaque');
    },
  );
}
