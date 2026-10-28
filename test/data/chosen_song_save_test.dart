import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/song_identity.dart';
import 'package:singbook/domain/timing.dart';
import 'package:singbook/providers/core/service.dart';

SongCandidate candidate(
  String provider, {
  String title = 'A Song',
  String artist = 'An Artist',
}) => SongCandidate(
  providerId: provider,
  id: 'song',
  title: title,
  artist: artist,
);

SongDocument version(
  String id,
  String provider,
  String body, {
  String title = 'A Song',
  String artist = 'An Artist',
  bool favorite = false,
  DateTime? createdAt,
  JsonMap metadata = const {},
  JsonMap extra = const {},
  String? extensionError,
  List<String> extensions = const [],
}) {
  final selected = candidate(provider, title: title, artist: artist);
  final parsed = parseLrc(
    '[00:01]${plainLyrics(body)}',
    sourceDocumentId: '$provider:song',
  ).copyWith(status: TimingStatus.usable, lyricHash: lyricOrderHash(body));
  // Providers can reuse one timing ID even when the fetched lyrics change.
  final track = TimingTrack.fromJson({
    ...parsed.toJson(),
    'id': '$provider:timing',
  });
  return SongDocument(
    id: id,
    title: title,
    artist: artist,
    body: body,
    selectedRecording: selected,
    favorite: favorite,
    createdAt: createdAt,
    metadata: metadata,
    extra: {'selectedSourceId': selected.identity, ...extra},
    sources: [
      SourceResult(
        candidate: selected,
        body: body,
        matchKind: MatchKind.sameSong,
        timingTracks: [track],
      ),
    ],
    timingTracks: [track],
    activeTimingTrackId: track.id,
    extensionError: extensionError,
    preservedExtensions: extensions,
  );
}

void main() {
  sqfliteFfiInit();
  late Directory temp;
  late LibraryRepository repo;
  late String path;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('singbook-overwrite-');
    path = '${temp.path}/library.db';
    repo = await LibraryRepository.open(
      path: path,
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() async {
    await repo.close();
    await temp.delete(recursive: true);
  });
  Future<void> reopen() async {
    await repo.close();
    repo = await LibraryRepository.open(
      path: path,
      factory: databaseFactoryFfi,
    );
  }

  test(
    'derived arrangement identities and raw parent survive save reopen and resave',
    () async {
      const lyrics =
          'Amber lanterns cross the quiet harbor\nSilver windows catch the morning sunlight';
      final selected = candidate('catalog');
      final chartCandidate = candidate('chart');
      const rawChart =
          'Capo II\n[C]Amber lanterns cross the quiet harbor\n'
          '[G]Silver windows catch the morning sunlight\nArrangement 2\nCapo IV\n'
          '[Bb]Amber lanterns cross the quiet harbor\n[F]Silver windows catch the morning sunlight';
      final combined = combineSources(selected, [
        SourceResult(
          candidate: selected,
          body: lyrics,
          matchKind: MatchKind.sameRecording,
        ),
        SourceResult(
          candidate: chartCandidate,
          body: rawChart,
          metadata: const {'key': 'D', 'capo': 2},
          matchKind: MatchKind.sameSong,
        ),
      ]);
      final expectedIds = combined.sources.map((source) => source.id).toSet();
      expect(
        combined.sources.where((source) => source.arrangementId != null),
        hasLength(2),
      );
      final saved = await repo.saveChosenSong(combined);
      await reopen();
      final restored = (await repo.getSong(saved.id))!;
      expect(restored.body, combined.body);
      expect(restored.sources.map((source) => source.id).toSet(), expectedIds);
      expect(
        restored.sources
            .singleWhere((source) => source.id == chartCandidate.identity)
            .body,
        rawChart,
      );
      for (final view in restored.sources.where(
        (source) => source.arrangementId != null,
      )) {
        expect(view.candidate.id, chartCandidate.id);
        expect(view.extra['parentSourceId'], chartCandidate.identity);
      }
      final resaved = await repo.saveChosenSong(restored);
      expect(resaved.sources.map((source) => source.id).toSet(), expectedIds);
      expect(
        resaved.sources.map((source) => source.id),
        hasLength(expectedIds.length),
      );
    },
  );

  test(
    'cross-provider overwrite survives reopen with local relationships and extras',
    () async {
      final date = DateTime.utc(2020);
      await repo.saveSong(
        version(
          'local',
          'old',
          '[C]Old lyric',
          favorite: true,
          createdAt: date,
          metadata: {'album': 'Old', 'x_verse_player_transpose': 3},
          extra: {
            'futureField': {
              'sentinel': [1, 'kept'],
            },
            'combinedSelection': 'old:song',
            'combinedFallbackSource': true,
          },
          extensions: ['{x_custom: retained}'],
        ),
      );
      await repo.saveSetlist(
        SetlistDocument(
          id: 'set',
          name: 'Practice',
          entries: [
            const SetlistEntry(
              id: 'entry',
              songId: 'local',
              overrides: {'capo': 2},
            ),
          ],
        ),
      );
      final incoming = version(
        'fresh',
        'new',
        '[D]New lyric',
        metadata: {'album': 'New'},
      );
      final saved = await repo.saveChosenSong(incoming);
      expect(saved.id, 'local');
      await reopen();
      final stored = (await repo.getSong('local'))!;
      expect(await repo.listSongs(), hasLength(1));
      expect(stored.body, '[D]New lyric');
      expect(stored.metadata['album'], 'New');
      expect(stored.metadata['x_verse_player_transpose'], 3);
      expect(stored.favorite, isTrue);
      expect(stored.createdAt, date);
      expect(stored.revision, 2);
      expect(stored.selectedRecording!.identity, 'new:song');
      expect(stored.extra['futureField'], {
        'sentinel': [1, 'kept'],
      });
      expect(stored.extra.containsKey('combinedSelection'), isFalse);
      expect(stored.extra.containsKey('combinedFallbackSource'), isFalse);
      expect(stored.preservedExtensions, contains('{x_custom: retained}'));
      final entry = (await repo.getSetlist('set'))!.entries.single;
      expect(entry.songId, 'local');
      expect(entry.overrides, {'capo': 2});
      expect(stored.activeTimingTrackId, incoming.activeTimingTrackId);
      expect(stored.extensionError, isNull);
    },
  );

  test(
    'provider timing ID reuse retains each archived raw payload through repeated reopen',
    () async {
      await repo.saveSong(version('local', 'same', '[C]First lyric'));
      await repo.saveChosenSong(version('second', 'same', '[D]Second lyric'));
      await reopen();
      var stored = (await repo.getSong('local'))!;
      final first = stored.sources
          .singleWhere((s) => s.body == '[C]First lyric')
          .timingTracks
          .single;
      expect(first.status, TimingStatus.stale);
      expect(first.raw, '[00:01]First lyric');
      expect(first.cues.single.text, 'First lyric');
      final firstId = first.id;
      await repo.saveChosenSong(version('third', 'same', '[E]Third lyric'));
      await reopen();
      stored = (await repo.getSong('local'))!;
      expect(stored.sources, hasLength(3));
      final historical = stored.sources.where(
        (s) => s.body != '[E]Third lyric',
      );
      expect(
        historical.map((s) => s.timingTracks.single.id).toSet(),
        hasLength(2),
      );
      expect(
        historical.map((s) => s.timingTracks.single.status),
        everyElement(TimingStatus.stale),
      );
      expect(
        stored.sources
            .singleWhere((s) => s.body == '[C]First lyric')
            .timingTracks
            .single
            .id,
        firstId,
      );
      expect(
        historical.map((s) => s.timingTracks.single.raw),
        containsAll(['[00:01]First lyric', '[00:01]Second lyric']),
      );
      final active = stored.timingTracks.singleWhere(
        (t) => t.id == stored.activeTimingTrackId,
      );
      expect(active.raw, '[00:01]Third lyric');
      expect(active.status, TimingStatus.usable);
      expect(stored.extensionError, isNull);
    },
  );

  test(
    'concurrent cross-provider saves create only one logical song',
    () async {
      await Future.wait([
        repo.saveChosenSong(version('one', 'one', 'First lyric')),
        repo.saveChosenSong(version('two', 'two', 'Second lyric')),
      ]);
      await reopen();
      expect(await repo.listSongs(), hasLength(1));
      expect((await repo.listSongs()).single.revision, 2);
    },
  );

  test(
    'exact reference beats older metadata match and edited display fields',
    () async {
      await repo.saveSong(
        version('older', 'other', 'Older lyric', createdAt: DateTime.utc(2019)),
      );
      await repo.saveSong(
        version(
          'exact',
          'same',
          'Original lyric',
          createdAt: DateTime.utc(2020),
        ).copyWith(title: 'My edited title', artist: 'My edited artist'),
      );
      final saved = await repo.saveChosenSong(
        version('incoming', 'same', 'New lyric'),
      );
      expect(saved.id, 'exact');
      expect((await repo.getSong('older'))!.body, 'Older lyric');
      expect(await repo.listSongs(), hasLength(2));
    },
  );

  test(
    'legacy combined reference matches but conflict copies remain independent',
    () async {
      await repo.saveSong(
        SongDocument(
          id: 'legacy',
          title: 'Edited',
          artist: 'Edited',
          body: 'Old',
          extra: {'combinedSelection': 'same:song'},
        ),
      );
      await repo.saveSong(
        version(
          'conflict',
          'same',
          'Conflict',
          createdAt: DateTime.utc(2018),
          extra: {
            'syncConflict': {'reason': 'edited'},
          },
        ),
      );
      expect(
        (await repo.saveChosenSong(version('new', 'same', 'New'))).id,
        'legacy',
      );
      expect((await repo.getSong('conflict'))!.body, 'Conflict');
    },
  );

  test(
    'ambiguous matches choose earliest date then id without purging duplicates',
    () async {
      for (final id in ['b', 'a']) {
        await repo.saveSong(
          version(id, id, 'Original $id', createdAt: DateTime.utc(2020)),
        );
      }
      expect(
        (await repo.saveChosenSong(version('new', 'new', 'Chosen'))).id,
        'a',
      );
      expect((await repo.getSong('b'))!.body, 'Original b');
      expect(await repo.listSongs(), hasLength(2));
    },
  );

  test(
    'identity is punctuation tolerant but retains artists and edition words',
    () async {
      expect(
        librarySongIdentity('Don’t Stop!', 'The Artist'),
        librarySongIdentity("DONT STOP", 'the artist'),
      );
      expect(
        librarySongIdentity('Song (Live)', 'Artist'),
        isNot(librarySongIdentity('Song', 'Artist')),
      );
      expect(
        librarySongIdentity('Song', 'Artist A'),
        isNot(librarySongIdentity('Song', 'Artist B')),
      );
      expect(librarySongIdentity('Song', ''), isNull);
      await repo.saveChosenSong(version('base', 'one', 'Base'));
      await repo.saveChosenSong(
        version('live', 'two', 'Live', title: 'A Song (Live)'),
      );
      await repo.saveChosenSong(
        version('artist', 'three', 'Other', artist: 'Another Artist'),
      );
      expect(await repo.listSongs(), hasLength(3));
    },
  );

  test(
    'opaque matched extension fails without changing local data or creating a duplicate',
    () async {
      await repo.saveSong(
        version(
          'opaque',
          'old',
          'Old',
          extensionError: 'unsupported',
          extensions: ['{x_verse: 99 opaque}'],
        ),
      );
      final hash = await repo.getSongHash('opaque');
      await expectLater(
        repo.saveChosenSong(version('new', 'new', 'New')),
        throwsFormatException,
      );
      expect(await repo.getSongHash('opaque'), hash);
      expect(await repo.listSongs(), hasLength(1));
    },
  );

  test(
    'file import and stale editor compare-and-set keep their non-clobbering behavior',
    () async {
      final original = version('local', 'old', 'Original');
      await repo.saveSong(original);
      final before = await repo.getSongHash('local');
      final imported = await repo.saveImportedSong(
        version('local', 'new', 'Imported'),
      );
      expect(imported.id, isNot('local'));
      await repo.saveChosenSong(version('fresh', 'old', 'Chosen'));
      expect(
        await repo.saveSongIfUnchanged(
          original.copyWith(body: 'Stale edit'),
          before,
        ),
        isFalse,
      );
      expect((await repo.getSong('local'))!.body, 'Chosen');
      expect((await repo.getSong(imported.id))!.body, 'Imported');
    },
  );

  test(
    'controller comparison save replaces an entry written after its cached library snapshot',
    () async {
      final app = AppController(
        repository: repo,
        discovery: SourceDiscoveryService([]),
      );
      addTearDown(app.dispose);
      await app.initialize();
      await repo.saveSong(version('persisted', 'old', '[C]Old lyric'));
      final incoming = version('incoming', 'new', '[D]New lyric');
      app.selection = incoming.selectedRecording;
      app.results = incoming.sources;
      final saved = await app.saveResult(source: incoming.sources.single);
      expect(saved.id, 'persisted');
      expect(app.songs, hasLength(1));
      expect(app.songs.single.body, '[D]New lyric');
      final combined = await app.saveResult();
      expect(combined.id, 'persisted');
      expect(await repo.listSongs(), hasLength(1));
    },
  );
}
