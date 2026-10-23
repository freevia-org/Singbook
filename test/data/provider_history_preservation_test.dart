import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';

const _sourceId = 'fixture_catalog:work-1';
const _body = 'silver lantern crosses the quiet harbor';
const _historyBodyA = 'archived synthetic verse alpha';
const _historyBodyB = 'archived synthetic verse beta';
const _historyRawA = '[00:11.00]$_historyBodyA';
const _historyRawB = '[00:12.00]$_historyBodyB';

SongCandidate _candidate({String album = 'Fixture Album'}) => SongCandidate(
  providerId: 'fixture_catalog',
  id: 'work-1',
  title: 'Invented Harbor Song',
  artist: 'Fixture Artist',
  album: album,
  metadata: {'album': album, 'fixtureFact': 'candidate-$album'},
);

TimingTrack _track({
  required String raw,
  String id = 'fixture_catalog:reused-track',
  TimingStatus status = TimingStatus.usable,
}) {
  final parsed = parseLrc(
    raw,
    sourceDocumentId: 'fixture_catalog:work-1',
    recordingId: _sourceId,
  );
  return TimingTrack.fromJson({
    ...parsed.toJson(),
    'id': id,
    'status': status.name,
  });
}

SongDocument _chosen({
  String id = 'incoming',
  String body = _body,
  String album = 'Fixture Album',
  String raw = '[00:01.00]$_body',
  String? customMetadata,
  DateTime? retrievedAt,
}) {
  final selected = _candidate(album: album);
  final timing = _track(raw: raw);
  final source = SourceResult(
    candidate: selected,
    body: body,
    metadata: {'album': album, 'sourceFact': 'source-$album'},
    timingTracks: [timing],
    matchKind: MatchKind.sameRecording,
    attribution: 'Synthetic fixture',
    retrievedAt: retrievedAt,
    extra: {
      'rights': {'status': 'unknown', 'attribution': 'Synthetic fixture'},
    },
  );
  return SongDocument(
    id: id,
    title: 'Invented Harbor Song',
    artist: 'Fixture Artist',
    body: body,
    metadata: {'album': album, 'customFact': ?customMetadata},
    selectedRecording: selected,
    sources: [source],
    timingTracks: [timing],
    activeTimingTrackId: timing.id,
    extra: {'selectedSourceId': selected.identity},
  );
}

SongDocument _standaloneTimingDocument({
  String id = 'standalone-song',
  List<TimingTrack> timingTracks = const [],
  String? activeTimingTrackId,
  DateTime? retrievedAt,
}) {
  final selected = _candidate();
  return SongDocument(
    id: id,
    title: 'Invented Harbor Song',
    artist: 'Fixture Artist',
    body: _body,
    metadata: const {'album': 'Fixture Album'},
    selectedRecording: selected,
    sources: [
      SourceResult(
        candidate: selected,
        body: _body,
        metadata: const {'album': 'Fixture Album'},
        matchKind: MatchKind.sameRecording,
        retrievedAt: retrievedAt,
      ),
    ],
    timingTracks: timingTracks,
    activeTimingTrackId: activeTimingTrackId,
    createdAt: DateTime.utc(2020, 1, 1),
    extra: {'selectedSourceId': selected.identity},
  );
}

SongDocument _savedVersion(Map value) =>
    SongDocument.fromJson(Map<String, dynamic>.from(value));

SongDocument _chosenWithMetadata({
  required JsonMap metadata,
  required JsonMap extra,
}) {
  final base = _chosen();
  return base.copyWith(
    metadata: {...base.metadata, ...metadata},
    extra: {...base.extra, ...extra},
  );
}

JsonMap _archivedSource(String suffix) {
  final isA = suffix == 'a';
  final candidate = SongCandidate(
    providerId: 'fixture_archive',
    id: 'history-$suffix',
    title: 'Invented Harbor Song',
    artist: 'Fixture Artist',
    metadata: {'album': 'Archive $suffix'},
  );
  final source = SourceResult(
    candidate: candidate,
    body: isA ? _historyBodyA : _historyBodyB,
    metadata: {'historyMarker': suffix},
    timingTracks: [
      _track(
        raw: isA ? _historyRawA : _historyRawB,
        id: 'fixture_archive:timing-$suffix',
      ),
    ],
    matchKind: MatchKind.sameRecording,
    extra: {
      'rights': {'status': 'unknown'},
    },
  );
  return source.toJson();
}

SongDocument _currentWithSourceHistory(List<JsonMap> history) {
  final current = _chosen(album: 'Current Release');
  final source = current.sources.single;
  return current.copyWith(
    sources: [
      source.copyWith(
        extra: {...source.extra, 'previousSourceVersions': history},
      ),
    ],
  );
}

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late String path;
  late LibraryRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'singbook-provider-history-',
    );
    path = '${directory.path}${Platform.pathSeparator}library.db';
    repository = await LibraryRepository.open(
      path: path,
      factory: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  Future<void> reopen() async {
    await repository.close();
    repository = await LibraryRepository.open(
      path: path,
      factory: databaseFactoryFfi,
    );
  }

  Future<void> checkDisjointHistoryUnion(
    Future<SongDocument> Function(SongDocument) save,
  ) async {
    await save(_currentWithSourceHistory([_archivedSource('a')]));
    await save(_currentWithSourceHistory([_archivedSource('b')]));
    await save(_currentWithSourceHistory([_archivedSource('b')]));
    await reopen();

    final saved = (await repository.getSong('incoming'))!;
    expect(saved.body, _body);
    expect(saved.sources, hasLength(1));
    final current = saved.sources.single;
    expect(current.id, _sourceId);
    expect(current.body, _body);
    expect(current.metadata['album'], 'Current Release');
    expect(current.timingTracks.map((track) => track.raw), [
      '[00:01.00]$_body',
    ]);

    final rawHistory = current.extra['previousSourceVersions'] as List;
    expect(rawHistory, hasLength(2));
    final history = [
      for (final value in rawHistory)
        SourceResult.fromJson(Map<String, dynamic>.from(value as Map)),
    ];
    expect(history.map((source) => source.body).toSet(), {
      _historyBodyA,
      _historyBodyB,
    });
    expect(
      history
          .expand((source) => source.timingTracks.map((track) => track.raw))
          .toSet(),
      {_historyRawA, _historyRawB},
    );
    expect(
      history.every(
        (source) =>
            !source.extra.containsKey('previousSourceVersions') &&
            !source.extra.containsKey('unparsedSourceHistory'),
      ),
      isTrue,
    );
    expect(saved.timingTracks.map((track) => track.raw), ['[00:01.00]$_body']);
    expect(saved.activeTimingTrackId, current.timingTracks.single.id);
    expect(
      saved.timingTracks.any(
        (track) => track.raw == _historyRawA || track.raw == _historyRawB,
      ),
      isFalse,
    );
  }

  test(
    'saveChosenSong unions disjoint source histories idempotently',
    () async {
      await checkDisjointHistoryUnion(repository.saveChosenSong);
    },
  );

  test(
    'saveImportedSong unions disjoint source histories idempotently',
    () async {
      await checkDisjointHistoryUnion(repository.saveImportedSong);
    },
  );

  test('import preserves an absent-field user removal tombstone', () async {
    await repository.saveImportedSong(
      _chosenWithMetadata(
        metadata: const {},
        extra: {
          'fieldOrigins': {'genre': 'user'},
        },
      ),
    );
    await repository.saveImportedSong(
      _chosenWithMetadata(
        metadata: {'genre': 'folk'},
        extra: {
          'fieldOrigins': {'genre': 'fixture:genre'},
        },
      ),
    );
    await reopen();

    final saved = (await repository.getSong('incoming'))!;
    expect(saved.metadata, isNot(contains('genre')));
    expect(jsonMap(saved.extra['fieldOrigins'])['genre'], 'user');
  });

  test(
    'import does not merge provider values into a user-owned list',
    () async {
      await repository.saveImportedSong(
        _chosenWithMetadata(
          metadata: {
            'composers': ['User credited composer'],
          },
          extra: {
            'fieldOrigins': {'composers': 'user'},
            'fieldContributors': {
              'composers': ['user-list'],
            },
          },
        ),
      );
      await repository.saveImportedSong(
        _chosenWithMetadata(
          metadata: {
            'composers': ['Provider suggested composer'],
          },
          extra: {
            'fieldOrigins': {'composers': 'fixture:source'},
            'fieldContributors': {
              'composers': ['fixture:source'],
            },
          },
        ),
      );
      await reopen();

      final saved = (await repository.getSong('incoming'))!;
      expect(saved.metadata['composers'], ['User credited composer']);
      expect(jsonMap(saved.extra['fieldOrigins'])['composers'], 'user');
      expect(jsonMap(saved.extra['fieldContributors'])['composers'], [
        'user-list',
      ]);
    },
  );

  test(
    'import transfers provenance when it fills a blank automatic field',
    () async {
      await repository.saveImportedSong(
        _chosenWithMetadata(
          metadata: {'composer': ''},
          extra: {
            'fieldOrigins': {'composer': 'fixture:old'},
            'fieldContributors': {
              'composer': ['fixture:old'],
            },
          },
        ),
      );
      await repository.saveImportedSong(
        _chosenWithMetadata(
          metadata: {'composer': 'New fixture composer'},
          extra: {
            'fieldOrigins': {'composer': 'fixture:new'},
            'fieldContributors': {
              'composer': ['fixture:new'],
            },
          },
        ),
      );
      await reopen();

      final saved = (await repository.getSong('incoming'))!;
      expect(saved.metadata['composer'], 'New fixture composer');
      expect(jsonMap(saved.extra['fieldOrigins'])['composer'], 'fixture:new');
      expect(jsonMap(saved.extra['fieldContributors'])['composer'], [
        'fixture:new',
      ]);
    },
  );

  test(
    'import route retains same-body metadata variants and deduplicates timestamp refreshes',
    () async {
      await repository.saveImportedSong(_chosen(album: 'First Release'));
      await repository.saveImportedSong(
        _chosen(album: 'Second Release', retrievedAt: DateTime.utc(2026, 1, 1)),
      );
      await repository.saveImportedSong(
        _chosen(album: 'Second Release', retrievedAt: DateTime.utc(2026, 2, 1)),
      );
      await reopen();

      final saved = (await repository.getSong('incoming'))!;
      expect(saved.sources, hasLength(2));
      expect(saved.sources.map((source) => source.metadata['album']).toSet(), {
        'First Release',
        'Second Release',
      });
      expect(
        saved.sources
            .map((source) => source.candidate.metadata['fixtureFact'])
            .toSet(),
        {'candidate-First Release', 'candidate-Second Release'},
      );
    },
  );

  test(
    'import route archives reused timing ID payloads without replacing active raw data',
    () async {
      const firstRaw = '[00:01.00]$_body';
      const secondRaw = '[00:02.00]$_body';
      await repository.saveImportedSong(_chosen(raw: firstRaw));
      await repository.saveImportedSong(
        _chosen(raw: secondRaw, retrievedAt: DateTime.utc(2026, 3, 1)),
      );
      await repository.saveImportedSong(
        _chosen(raw: secondRaw, retrievedAt: DateTime.utc(2026, 4, 1)),
      );
      await reopen();

      final saved = (await repository.getSong('incoming'))!;
      expect(saved.sources, hasLength(2));
      expect(saved.timingTracks, hasLength(2));
      final oldSource = saved.sources.singleWhere(
        (source) => source.timingTracks.single.raw == firstRaw,
      );
      final incomingSource = saved.sources.singleWhere(
        (source) => source.timingTracks.single.raw == secondRaw,
      );
      final oldTrack = oldSource.timingTracks.single;
      final incomingTrack = incomingSource.timingTracks.single;
      expect(oldTrack.raw, firstRaw);
      expect(oldTrack.cues.single.startUs, 1000000);
      expect(oldTrack.status, TimingStatus.usable);
      expect(incomingTrack.id, startsWith('history:'));
      expect(incomingTrack.id, isNot(oldTrack.id));
      expect(incomingTrack.raw, secondRaw);
      expect(incomingTrack.cues.single.startUs, 2000000);
      expect(incomingTrack.status, TimingStatus.stale);

      final active = saved.timingTracks.singleWhere(
        (track) => track.id == saved.activeTimingTrackId,
      );
      expect(active.raw, firstRaw);
      expect(active.status, TimingStatus.usable);
    },
  );

  test(
    'same source and body retain both metadata payloads after SQLite reopen',
    () async {
      await repository.saveChosenSong(_chosen(album: 'First Release'));
      await repository.saveChosenSong(_chosen(album: 'Second Release'));
      await reopen();

      final saved = (await repository.getSong('incoming'))!;
      expect(saved.sources, hasLength(2));
      expect(saved.sources.map((source) => source.metadata['album']).toSet(), {
        'First Release',
        'Second Release',
      });
      expect(
        saved.sources
            .map((source) => source.candidate.metadata['fixtureFact'])
            .toSet(),
        {'candidate-First Release', 'candidate-Second Release'},
      );
      expect(
        saved.sources.every(
          (source) => jsonMap(source.extra['rights'])['status'] == 'unknown',
        ),
        isTrue,
      );
      expect(saved.body, _body);
    },
  );

  test(
    'same-ID timing payload changes retain old raw cues as stale history',
    () async {
      const firstRaw = '[00:01.00]$_body';
      const secondRaw = '[00:02.00]$_body';
      await repository.saveChosenSong(_chosen(raw: firstRaw));
      await repository.saveChosenSong(_chosen(raw: secondRaw));
      await reopen();

      final saved = (await repository.getSong('incoming'))!;
      expect(saved.sources, hasLength(2));
      final oldSource = saved.sources.singleWhere(
        (source) => source.timingTracks.single.raw == firstRaw,
      );
      final newSource = saved.sources.singleWhere(
        (source) => source.timingTracks.single.raw == secondRaw,
      );
      final oldTrack = oldSource.timingTracks.single;
      final activeSourceTrack = newSource.timingTracks.single;
      expect(oldTrack.id, isNot(activeSourceTrack.id));
      expect(oldTrack.status, TimingStatus.stale);
      expect(oldTrack.raw, firstRaw);
      expect(oldTrack.cues.single.startUs, 1000000);
      expect(activeSourceTrack.raw, secondRaw);
      expect(activeSourceTrack.cues.single.startUs, 2000000);

      final active = saved.timingTracks.singleWhere(
        (track) => track.id == saved.activeTimingTrackId,
      );
      expect(active.raw, secondRaw);
      expect(active.status, TimingStatus.usable);
    },
  );

  test(
    'explicit replacement keeps prior edited body and metadata recoverable',
    () async {
      final selected = _candidate(album: 'Local Edition');
      await repository.saveSong(
        SongDocument(
          id: 'local-song',
          title: 'My edited title',
          artist: 'My edited artist',
          body: 'user rearranged local words',
          metadata: {
            'album': 'My local album edit',
            'privateNote': 'keep this snapshot',
          },
          selectedRecording: selected,
          extra: {'selectedSourceId': selected.identity},
        ),
      );
      final incoming =
          _chosen(
            id: 'new-result',
            album: 'Incoming Release',
            body: 'incoming canonical lyrics',
          ).copyWith(
            title: 'Incoming title',
            artist: 'Incoming artist',
            metadata: {'album': 'Incoming Release', 'newFact': 'current'},
          );

      await repository.saveChosenSong(incoming);
      await reopen();
      final saved = (await repository.getSong('local-song'))!;
      expect(saved.body, 'incoming canonical lyrics');
      expect(saved.metadata['newFact'], 'current');
      final history = saved.extra['previousSavedVersions'] as List;
      expect(history, hasLength(1));
      final prior = Map<String, dynamic>.from(history.single as Map);
      expect(prior['body'], 'user rearranged local words');
      expect(prior['metadata'], {
        'album': 'My local album edit',
        'privateNote': 'keep this snapshot',
      });
    },
  );

  test(
    'repeated identical payload does not grow versions and keeps earlier facts',
    () async {
      await repository.saveChosenSong(_chosen(album: 'First Release'));
      final repeated = _chosen(album: 'Second Release');
      await repository.saveChosenSong(repeated);
      final historyAfterSecondSave =
          ((await repository.getSong(
                        'incoming',
                      ))!.extra['previousSavedVersions']
                      as List? ??
                  const [])
              .length;
      await repository.saveChosenSong(repeated);
      await reopen();

      final saved = (await repository.getSong('incoming'))!;
      expect(saved.sources, hasLength(2));
      expect(saved.sources.map((source) => source.metadata['album']).toSet(), {
        'First Release',
        'Second Release',
      });
      expect(
        saved.sources.map((source) => source.timingTracks.single.raw).toSet(),
        {'[00:01.00]$_body'},
      );
      expect(
        (saved.extra['previousSavedVersions'] as List? ?? const []).length,
        historyAfterSecondSave,
      );
    },
  );

  test(
    'chosen replacement archives omitted standalone global timing and stays idempotent',
    () async {
      const raw = '[00:07.25]$_body';
      final originalTrack = _track(raw: raw, id: 'manual:global-only');
      await repository.saveSong(
        _standaloneTimingDocument(
          timingTracks: [originalTrack],
          activeTimingTrackId: originalTrack.id,
          retrievedAt: DateTime.utc(2025, 1, 1),
        ),
      );
      await reopen();

      final beforeReplacement = (await repository.getSong('standalone-song'))!;
      expect(beforeReplacement.sources.single.timingTracks, isEmpty);
      expect(beforeReplacement.timingTracks.single.raw, raw);
      expect(
        beforeReplacement.timingTracks.single.cues.single.startUs,
        7250000,
      );
      expect(beforeReplacement.activeTimingTrackId, originalTrack.id);

      await repository.saveChosenSong(
        _standaloneTimingDocument(retrievedAt: DateTime.utc(2026, 1, 1)),
      );
      await repository.saveChosenSong(
        _standaloneTimingDocument(retrievedAt: DateTime.utc(2026, 2, 1)),
      );
      await reopen();

      final saved = (await repository.getSong('standalone-song'))!;
      expect(saved.body, _body);
      expect(saved.sources.single.timingTracks, isEmpty);
      expect(saved.timingTracks, isEmpty);
      expect(saved.activeTimingTrackId, isNull);
      final history = saved.extra['previousSavedVersions'] as List;
      expect(history, hasLength(1));
      final archived = _savedVersion(history.single as Map);
      expect(archived.body, _body);
      expect(archived.selectedRecording?.identity, _sourceId);
      expect(archived.sources.single.timingTracks, isEmpty);
      expect(archived.timingTracks.single.id, originalTrack.id);
      expect(archived.timingTracks.single.raw, raw);
      expect(archived.timingTracks.single.cues.single.startUs, 7250000);
      expect(archived.activeTimingTrackId, originalTrack.id);
    },
  );

  test(
    'chosen replacement archives standalone timing while keeping incoming timing active',
    () async {
      final oldTrack = _track(
        raw: '[00:08.00]$_body',
        id: 'manual:old-global-only',
      );
      final incomingTrack = _track(
        raw: '[00:09.50]$_body',
        id: 'manual:new-global-only',
      );
      await repository.saveSong(
        _standaloneTimingDocument(
          timingTracks: [oldTrack],
          activeTimingTrackId: oldTrack.id,
        ),
      );
      await reopen();
      final beforeReplacement = (await repository.getSong('standalone-song'))!;
      expect(beforeReplacement.sources.single.timingTracks, isEmpty);
      expect(beforeReplacement.timingTracks.single.raw, oldTrack.raw);
      expect(beforeReplacement.activeTimingTrackId, oldTrack.id);

      await repository.saveChosenSong(
        _standaloneTimingDocument(
          timingTracks: [incomingTrack],
          activeTimingTrackId: incomingTrack.id,
          retrievedAt: DateTime.utc(2026, 3, 1),
        ),
      );
      await reopen();

      final saved = (await repository.getSong('standalone-song'))!;
      expect(saved.timingTracks.map((track) => track.raw), [incomingTrack.raw]);
      expect(saved.timingTracks.single.cues.single.startUs, 9500000);
      expect(saved.activeTimingTrackId, incomingTrack.id);
      expect(saved.sources.single.timingTracks, isEmpty);
      final history = saved.extra['previousSavedVersions'] as List;
      expect(history, hasLength(1));
      final archived = _savedVersion(history.single as Map);
      expect(archived.timingTracks.single.raw, oldTrack.raw);
      expect(archived.timingTracks.single.cues.single.startUs, 8000000);
      expect(archived.activeTimingTrackId, oldTrack.id);
      expect(
        saved.timingTracks.any((track) => track.id == oldTrack.id),
        isFalse,
      );
    },
  );

  test(
    'active standalone timing selection change preserves the old selected payload as history',
    () async {
      final first = _track(raw: '[00:10.00]$_body', id: 'manual:selection-a');
      final second = _track(raw: '[00:11.00]$_body', id: 'manual:selection-b');
      await repository.saveSong(
        _standaloneTimingDocument(
          timingTracks: [first, second],
          activeTimingTrackId: first.id,
        ),
      );
      await reopen();
      final beforeReplacement = (await repository.getSong('standalone-song'))!;
      expect(beforeReplacement.sources.single.timingTracks, isEmpty);
      expect(beforeReplacement.timingTracks.map((track) => track.raw), [
        first.raw,
        second.raw,
      ]);
      expect(beforeReplacement.activeTimingTrackId, first.id);

      await repository.saveChosenSong(
        _standaloneTimingDocument(
          timingTracks: [first, second],
          activeTimingTrackId: second.id,
          retrievedAt: DateTime.utc(2026, 4, 1),
        ),
      );
      await reopen();

      final saved = (await repository.getSong('standalone-song'))!;
      expect(saved.timingTracks.map((track) => track.raw), [
        first.raw,
        second.raw,
      ]);
      expect(saved.activeTimingTrackId, second.id);
      final history = saved.extra['previousSavedVersions'] as List;
      expect(history, hasLength(1));
      final archived = _savedVersion(history.single as Map);
      expect(archived.timingTracks.map((track) => track.raw), [
        first.raw,
        second.raw,
      ]);
      expect(archived.activeTimingTrackId, first.id);
      expect(
        archived.timingTracks
            .map((track) => track.cues.single.startUs)
            .toList(),
        [10000000, 11000000],
      );
    },
  );

  test('stale compare-and-set remains non-clobbering after reopen', () async {
    await repository.saveSong(
      SongDocument(
        id: 'local',
        title: 'Fixture',
        artist: 'Fixture Artist',
        body: 'saved once',
      ),
    );
    final staleHash = await repository.getSongHash('local');
    await repository.saveSong(
      SongDocument(
        id: 'local',
        title: 'Fixture',
        artist: 'Fixture Artist',
        body: 'newer persisted edit',
      ),
    );
    expect(
      await repository.saveSongIfUnchanged(
        SongDocument(
          id: 'local',
          title: 'Fixture',
          artist: 'Fixture Artist',
          body: 'stale editor write',
        ),
        staleHash,
      ),
      isFalse,
    );
    await reopen();
    expect((await repository.getSong('local'))!.body, 'newer persisted edit');
  });
}
