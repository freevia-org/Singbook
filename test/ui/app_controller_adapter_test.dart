import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late AppController app;
  late AppControllerAdapter ui;

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(repository: repository);
    await app.initialize();
    ui = AppControllerAdapter(app);
  });

  tearDown(() async {
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  test(
    'saving an online version records the opened song in recent history',
    () async {
      const candidate = SongCandidate(
        providerId: 'genius',
        id: 'original-demo',
        title: 'Original demo',
        artist: 'Test artist',
      );
      app.selection = candidate;
      app.results = [
        SourceResult(
          candidate: candidate,
          body: '[C]Our original demo words',
          matchKind: MatchKind.sameRecording,
        ),
      ];
      app.combined = _song();

      await ui.saveSelectedVersion();

      final saved = app.songs.single;
      expect(ui.state.route, VerseRoute.reader);
      expect(app.recent.single.objectKind, 'song');
      expect(app.recent.single.objectId, saved.id);
      await ui.back();
      expect(ui.state.recent.single.id, saved.id);
    },
  );

  test('explicit version duration survives save and reader reopen', () async {
    const selected = SongCandidate(
      providerId: 'genius',
      id: 'amazing-grace',
      title: 'Amazing Grace',
      artist: 'Judy Collins',
      durationSeconds: 90,
    );
    const source = SourceResult(
      candidate: SongCandidate(
        providerId: 'lrclib',
        id: 'amazing-grace-recording',
        title: 'Amazing Grace',
        artist: 'Judy Collins',
      ),
      body: 'Amazing grace, how sweet the sound',
      metadata: {'durationSeconds': 247},
      matchKind: MatchKind.sameSong,
    );
    app.selection = selected;
    app.results = [source];
    app.combined = combineSources(selected, app.results);
    ui.selectVersion(source.id);

    await ui.saveSelectedVersion();
    final saved = app.songs.single;

    expect(saved.metadata['durationSeconds'], 247);
    expect(ui.state.song?.id, saved.id);
    expect(ui.state.readerDurationEstimated, isFalse);
    expect(ui.state.readerSource, isNotNull);
    await ui.back();
    await ui.openSong(saved.id);
    expect(ui.state.song?.durationSeconds, 247);
  });

  test(
    'resaving a source repairs stale duration without replacing user edits',
    () async {
      const selected = SongCandidate(
        providerId: 'genius',
        id: 'amazing-grace',
        title: 'Amazing Grace',
        artist: 'Judy Collins',
        durationSeconds: 90,
      );
      const source = SourceResult(
        candidate: SongCandidate(
          providerId: 'lrclib',
          id: 'amazing-grace-recording',
          title: 'Amazing Grace',
          artist: 'Judy Collins',
        ),
        body: 'Amazing grace, how sweet the sound',
        metadata: {'durationSeconds': 247},
        matchKind: MatchKind.sameSong,
      );
      final previous = combineSources(selected, [source]).copyWith(
        id: 'existing-song',
        body: '[D]My edited lyric stays here',
        metadata: {'durationSeconds': 90, 'key': 'D'},
        extra: {
          ...combineSources(selected, [source]).extra,
          'savedSourceId': source.id,
          'fieldOrigins': {'durationSeconds': selected.identity, 'key': 'user'},
        },
      );
      await app.saveSong(previous);
      app.selection = selected;
      app.results = [source];
      app.combined = combineSources(selected, [source]);
      ui.selectVersion(source.id);

      await ui.saveSelectedVersion();

      final repaired = app.findSong('existing-song')!;
      expect(app.songs, hasLength(1));
      expect(repaired.metadata['durationSeconds'], 247);
      expect(repaired.metadata['key'], 'D');
      expect(repaired.body, '[D]My edited lyric stays here');
      expect(repaired.extra['fieldOrigins']['durationSeconds'], source.id);
    },
  );

  test(
    'resave uses candidate metadata as duration provenance fallback',
    () async {
      const selected = SongCandidate(
        providerId: 'genius',
        id: 'amazing-grace',
        title: 'Amazing Grace',
        artist: 'Judy Collins',
        durationSeconds: 90,
      );
      const previousSource = SourceResult(
        candidate: SongCandidate(
          providerId: 'lrclib',
          id: 'amazing-grace-recording',
          title: 'Amazing Grace',
          artist: 'Judy Collins',
          metadata: {'durationSeconds': 90},
        ),
        body: 'Amazing grace, how sweet the sound',
        matchKind: MatchKind.sameSong,
      );
      final previousCombined = combineSources(selected, [
        previousSource,
      ], preferredSourceId: previousSource.id);
      await app.saveSong(
        previousCombined.copyWith(
          extra: {
            ...previousCombined.extra,
            'savedSourceId': previousSource.id,
          },
        ),
      );

      const updatedSource = SourceResult(
        candidate: SongCandidate(
          providerId: 'lrclib',
          id: 'amazing-grace-recording',
          title: 'Amazing Grace',
          artist: 'Judy Collins',
          metadata: {'durationSeconds': 247},
        ),
        body: 'Amazing grace, how sweet the sound',
        matchKind: MatchKind.sameSong,
      );
      app.selection = selected;
      app.results = [updatedSource];
      app.combined = combineSources(selected, [updatedSource]);
      ui.selectVersion(updatedSource.id);

      await ui.saveSelectedVersion();

      expect(app.songs, hasLength(1));
      expect(app.songs.single.metadata['durationSeconds'], 247);
      expect(
        app.songs.single.extra['fieldOrigins']['durationSeconds'],
        updatedSource.id,
      );
    },
  );

  test('resaving a source preserves a user-edited duration', () async {
    const selected = SongCandidate(
      providerId: 'genius',
      id: 'amazing-grace',
      title: 'Amazing Grace',
      artist: 'Judy Collins',
      durationSeconds: 90,
    );
    const source = SourceResult(
      candidate: SongCandidate(
        providerId: 'lrclib',
        id: 'amazing-grace-recording',
        title: 'Amazing Grace',
        artist: 'Judy Collins',
      ),
      body: 'Amazing grace, how sweet the sound',
      metadata: {'durationSeconds': 247},
      matchKind: MatchKind.sameSong,
    );
    final combined = combineSources(selected, [source]);
    final edited = combined.copyWith(
      id: 'edited-song',
      metadata: {'durationSeconds': 111},
      extra: {
        ...combined.extra,
        'savedSourceId': source.id,
        'fieldOrigins': {'durationSeconds': 'user'},
      },
    );
    await app.saveSong(edited);
    app.selection = selected;
    app.results = [source];
    app.combined = combined;
    ui.selectVersion(source.id);

    await ui.saveSelectedVersion();

    expect(app.songs, hasLength(1));
    expect(app.findSong('edited-song')!.metadata['durationSeconds'], 111);
  });

  test(
    'repository ignores invalid imported durations on source re-save',
    () async {
      const selected = SongCandidate(
        providerId: 'genius',
        id: 'amazing-grace',
        title: 'Amazing Grace',
        artist: 'Judy Collins',
        durationSeconds: 90,
      );
      const goodSource = SourceResult(
        candidate: SongCandidate(
          providerId: 'lrclib',
          id: 'amazing-grace-recording',
          title: 'Amazing Grace',
          artist: 'Judy Collins',
        ),
        body: 'Amazing grace, how sweet the sound',
        metadata: {'durationSeconds': 247},
        matchKind: MatchKind.sameSong,
      );
      final saved = await repository.saveImportedSong(
        combineSources(selected, [
          goodSource,
        ], preferredSourceId: goodSource.id).copyWith(
          extra: {
            ...combineSources(selected, [
              goodSource,
            ], preferredSourceId: goodSource.id).extra,
            'savedSourceId': goodSource.id,
          },
        ),
      );

      for (final invalid in <double>[
        0,
        -1,
        double.infinity,
        double.nan,
        86401,
      ]) {
        final invalidSource = SourceResult(
          candidate: SongCandidate(
            providerId: goodSource.candidate.providerId,
            id: goodSource.candidate.id,
            title: goodSource.candidate.title,
            artist: goodSource.candidate.artist,
            durationSeconds: invalid,
          ),
          body: goodSource.body,
          metadata: {'durationSeconds': invalid},
          matchKind: MatchKind.sameSong,
        );
        final incoming =
            combineSources(selected, [
              invalidSource,
            ], preferredSourceId: invalidSource.id).copyWith(
              metadata: {'durationSeconds': invalid},
              extra: {
                ...combineSources(selected, [
                  invalidSource,
                ], preferredSourceId: invalidSource.id).extra,
                'savedSourceId': invalidSource.id,
                'fieldOrigins': {'durationSeconds': invalidSource.id},
              },
            );

        final merged = await repository.saveImportedSong(
          incoming,
          existingId: saved.id,
        );

        expect(merged.id, saved.id);
        expect(merged.metadata['durationSeconds'], 247, reason: '$invalid');
        expect(merged.sources.single.candidate.durationSeconds, isNull);
        expect(
          merged.sources.single.metadata,
          isNot(contains('durationSeconds')),
        );
      }
    },
  );

  test('editing a query clears stale search errors immediately', () async {
    app.query = 'signal';
    app.errorCode = 'search_failed';

    ui.setQuery('signal ');

    expect(app.errorCode, isNull);
    expect(ui.state.searchState, LoadState.loading);
    expect(ui.state.searchError, isNull);
  });

  test('catalog matching ignores filters only known after discovery', () async {
    ui.setSearchFilter('field', 'lyrics');
    ui.setQuery('signal');
    app.query = 'signal';
    app.suggestions = [
      const SongCandidate(
        providerId: 'catalog',
        id: 'one',
        title: 'Signal One',
        artist: 'The Signals',
        metadata: {'language': 'bg', 'hasTiming': false, 'hasChords': false},
      ),
      const SongCandidate(
        providerId: 'catalog',
        id: 'two',
        title: 'Signal Two',
        artist: 'The Signals',
        metadata: {'language': 'en', 'hasTiming': true, 'hasChords': true},
      ),
    ];
    ui.setSearchFilter('timedOnly', true);
    ui.setSearchFilter('language', 'uk');

    expect(ui.state.searchFilters.field, 'all');
    expect(ui.state.autocomplete.map((item) => item.id), [
      'catalog:one',
      'catalog:two',
    ]);
  });

  test(
    'filtering a selected source saves the source currently shown as selected',
    () async {
      ui.dispose();
      app.dispose();
      const selected = SongCandidate(
        providerId: 'plain',
        id: 'sample-song',
        title: 'Sample Song',
        artist: 'Test Artist',
      );
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([
          _StatusProvider(
            id: 'plain',
            capabilities: const {'lyrics'},
            selected: selected,
            body: 'A plain lyric line\nAnother plain line',
          ),
          _StatusProvider(
            id: 'chords',
            capabilities: const {'lyrics'},
            selected: selected,
            body: '[C]A chord lyric line\n[G]Another chord line',
          ),
        ]),
      );
      await app.initialize();
      app.settings['catalog'] = 'plain';
      ui = AppControllerAdapter(app);
      ui.setQuery('sample song');
      await ui.submitSearch();
      await ui.selectReference(
        const SearchReferenceData(
          id: 'plain:sample-song',
          title: 'Sample Song',
          artist: 'Test Artist',
        ),
      );
      expect(
        ui.state.comparison,
        isNotNull,
        reason:
            'selection=${app.selection?.identity}; query=${ui.state.query}; '
            'suggestions=${app.suggestions.map((item) => item.identity).toList()}; '
            'results=${app.results.map((item) => item.id).toList()}; '
            'combined=${app.combined?.extra['selectedSourceId']}',
      );
      ui.selectVersion('plain:sample-song');

      ui.setSearchFilter('chordsOnly', true);
      final displayedSelection = ui.state.comparison!.selected;
      expect(displayedSelection?.id, 'combined');
      expect(ui.state.comparison!.selectedVersionId, 'combined');

      await ui.saveSelectedVersion();

      final saved = app.songs.single;
      expect(
        saved.extra['selectedSourceId'],
        app.combined!.extra['selectedSourceId'],
      );
      expect(saved.extra['selectedSourceId'], isNot('plain:sample-song'));
    },
  );

  test('saving is blocked when filters leave no usable selection', () async {
    ui.dispose();
    app.dispose();
    const selected = SongCandidate(
      providerId: 'plain',
      id: 'sample-song',
      title: 'Sample Song',
      artist: 'Test Artist',
    );
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([
        _StatusProvider(
          id: 'plain',
          capabilities: const {'lyrics'},
          selected: selected,
          body: 'A plain lyric line\nAnother plain line',
        ),
      ]),
    );
    await app.initialize();
    app.settings['catalog'] = 'plain';
    ui = AppControllerAdapter(app);
    ui.setQuery('sample song');
    await ui.submitSearch();
    await ui.selectReference(
      const SearchReferenceData(
        id: 'plain:sample-song',
        title: 'Sample Song',
        artist: 'Test Artist',
      ),
    );
    ui.setSearchFilter('chordsOnly', true);

    expect(ui.state.comparison!.selected, isNull);
    await ui.saveSelectedVersion();

    expect(app.songs, isEmpty);
  });

  test('version duration falls back to valid result metadata', () async {
    ui.dispose();
    app.dispose();
    const selected = SongCandidate(
      providerId: 'plain',
      id: 'sample-song',
      title: 'Sample Song',
      artist: 'Test Artist',
      durationSeconds: double.infinity,
    );
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([
        _StatusProvider(
          id: 'plain',
          capabilities: const {'lyrics'},
          selected: selected,
          body: 'A plain lyric line\nAnother plain line',
          resultMetadata: const {'durationSeconds': 247},
        ),
      ]),
    );
    await app.initialize();
    app.settings['catalog'] = 'plain';
    ui = AppControllerAdapter(app);
    ui.setQuery('sample song');
    await ui.submitSearch();
    await ui.selectReference(
      const SearchReferenceData(
        id: 'plain:sample-song',
        title: 'Sample Song',
        artist: 'Test Artist',
      ),
    );

    expect(ui.state.comparison!.alternatives.single.durationSeconds, 247);
    expect(ui.state.comparison!.suggested!.durationSeconds, 247);
  });

  test(
    'autocomplete ranks song matches and removes release calendar pages',
    () {
      ui.setQuery('Amazing Grace Judy Collins');
      app.query = 'Amazing Grace Judy Collins';
      app.suggestions = [
        const SongCandidate(
          providerId: 'genius',
          id: 'unrelated',
          title: 'Some Other Song',
          artist: 'Another Artist',
        ),
        const SongCandidate(
          providerId: 'genius',
          id: 'live',
          title: 'Amazing Grace (Live)',
          artist: 'Judy Collins',
        ),
        const SongCandidate(
          providerId: 'genius',
          id: 'calendar',
          title: 'Singles Release Calendar',
          artist: 'Genius',
        ),
        const SongCandidate(
          providerId: 'catalog',
          id: 'editorial',
          title: 'A Music Story',
          artist: 'Editorial Desk',
          metadata: {'kind': 'editorial'},
        ),
        const SongCandidate(
          providerId: 'genius',
          id: 'match',
          title: 'Amazing Grace',
          artist: 'Judy Collins',
        ),
      ];

      expect(ui.state.autocomplete.map((item) => item.id), [
        'genius:match',
        'genius:live',
        'genius:unrelated',
      ]);
    },
  );

  test(
    'provider checks preserve found metadata and timing-only matches',
    () async {
      ui.dispose();
      app.dispose();
      const selected = SongCandidate(
        providerId: 'catalog',
        id: 'sample-song',
        title: 'Sample Song',
        artist: 'Test Artist',
        album: 'Demo Album',
        durationSeconds: 120,
      );
      final providers = [
        _StatusProvider(
          id: 'catalog',
          capabilities: const {'lyrics'},
          body: 'A line of lyrics from the catalog',
          selected: selected,
        ),
        _StatusProvider(
          id: 'timing-only',
          capabilities: const {'timing'},
          timingOnly: true,
          selected: selected,
        ),
        _StatusProvider(
          id: 'metadata-only',
          capabilities: const {'metadata'},
          metadataOnly: true,
          selected: selected,
        ),
        _StatusProvider(
          id: 'failed-provider',
          capabilities: const {'lyrics'},
          failureCode: 'network_error',
          selected: selected,
        ),
        _StatusProvider(
          id: 'unavailable-provider',
          capabilities: const {'lyrics'},
          failureCode: 'unavailable',
          selected: selected,
        ),
      ];
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(providers),
      );
      await app.initialize();
      app.settings['catalog'] = 'catalog';
      ui = AppControllerAdapter(app);

      ui.setQuery('sample song');
      await ui.submitSearch();
      await ui.selectReference(
        const SearchReferenceData(
          id: 'catalog:sample-song',
          title: 'Sample Song',
          artist: 'Test Artist',
        ),
      );

      final comparison = ui.state.comparison!;
      final checks = {
        for (final check in comparison.providerChecks) check.id: check.state,
      };
      expect(checks['timing-only'], 'found');
      expect(checks['metadata-only'], 'found');
      expect(checks['failed-provider'], 'failed');
      expect(checks['unavailable-provider'], 'unavailable');
      expect(
        comparison.providerChecks
            .where(
              (check) =>
                  check.state == 'failed' || check.state == 'unavailable',
            )
            .length,
        2,
      );
    },
  );

  test('estimated progress ignores available timing cues', () async {
    final track = _track(
      extra: {
        'binding': {
          'occurrences': [
            {'source': 'line-0', 'target': 'line-0'},
          ],
        },
      },
    );
    await app.saveSong(_song(timingTracks: [track]));
    app.settings['timingMode'] = 'estimated';

    await ui.openSong('song');
    await ui.seek(45);

    expect(ui.state.currentLineId, 'line-1');
  });

  test('timed cues follow their saved occurrence binding', () async {
    final track = _track(
      extra: {
        'binding': {
          'occurrences': [
            {'source': 'line-0', 'target': 'line-1'},
          ],
        },
      },
    );
    await app.saveSong(_song(timingTracks: [track]));
    app.settings['timingMode'] = 'timed';

    await ui.openSong('song');
    await ui.seek(0);

    expect(ui.state.currentLineId, 'line-1');
  });

  test(
    'reader state reports timing availability and estimated duration',
    () async {
      await app.saveSong(
        _song(timingTracks: [_track()], metadata: {'durationSeconds': 0}),
      );
      app.settings['timingMode'] = 'timed';

      await ui.openSong('song');
      expect(ui.state.readerHasTiming, isTrue);
      expect(ui.state.readerDurationEstimated, isTrue);

      await ui.setTimingMode('estimated');
      expect(ui.state.readerHasTiming, isFalse);
    },
  );

  test('playback speed accepts supported session values', () async {
    await app.saveSong(_song());
    await ui.openSong('song');

    await ui.setPlaybackSpeed(1.5);
    expect(ui.state.playbackSpeed, 1.5);
    await ui.setPlaybackSpeed(3);
    expect(ui.state.playbackSpeed, 1.5);
  });

  test(
    'reader can reopen its comparison and return to cached search',
    () async {
      ui.dispose();
      app.dispose();
      const selected = SongCandidate(
        providerId: 'catalog',
        id: 'sample-song',
        title: 'Sample Song',
        artist: 'Test Artist',
      );
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([
          _StatusProvider(
            id: 'catalog',
            capabilities: const {'lyrics'},
            selected: selected,
            body: 'A complete sample song lyric arrangement',
          ),
        ]),
      );
      await app.initialize();
      app.settings['catalog'] = 'catalog';
      ui = AppControllerAdapter(app);
      ui.setQuery('sample song');
      await ui.submitSearch();
      await ui.selectReference(
        const SearchReferenceData(
          id: 'catalog:sample-song',
          title: 'Sample Song',
          artist: 'Test Artist',
        ),
      );
      expect(app.results, isNotEmpty);
      expect(app.combined, isNotNull);
      await ui.saveSelectedVersion();

      expect(
        ui.state.readerCanCompareVersions,
        isTrue,
        reason:
            'reference=${ui.state.comparison?.reference.id}; '
            'recording=${ui.state.song?.id}; '
            'selection=${app.selection?.identity}; '
            'songs=${app.songs.length}',
      );
      await ui.compareCurrentSongVersions();
      expect(ui.state.comparison, isNotNull);
      expect(ui.state.comparison!.suggested!.providerName, 'catalog');
      expect(
        ui.state.comparison!.suggested!.underlyingSourceId,
        'catalog:sample-song',
      );
      expect(ui.state.comparison!.suggested!.savedSongId, app.songs.single.id);

      await ui.openSong(app.songs.single.id);
      ui.changeSearchSong();
      expect(ui.state.query, 'sample song');
      expect(ui.state.autocomplete.map((item) => item.id), [
        'catalog:sample-song',
      ]);
    },
  );

  test(
    'source previews keep the full arrangement and skip setup rows in summaries',
    () async {
      const selected = SongCandidate(
        providerId: 'catalog',
        id: 'preview-song',
        title: 'Preview Song',
        artist: 'Test Artist',
        metadata: {'genre': 'folk'},
      );
      const source = SourceResult(
        candidate: SongCandidate(
          providerId: 'lyrics',
          id: 'preview-song',
          title: 'Preview Song',
          artist: 'Test Artist',
        ),
        body:
            '{title: Preview Song}\n[Intro]\ne|--0---\nA9sus4     x05435\n'
            'A/G   3x222x or x-10-x-9-10-9\nCapo: 2\n[C]First words\n'
            '{start_of_verse:1}\n[G]Second words\n[Chorus]\n'
            '[D]Third words\n[E]Fourth words',
        matchKind: MatchKind.sameSong,
      );
      ui.dispose();
      app.dispose();
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([]),
      );
      await app.initialize();
      ui = AppControllerAdapter(app);
      ui.setQuery('preview song');
      await ui.submitSearch();
      app.suggestions = [selected];
      await ui.selectReference(
        const SearchReferenceData(
          id: 'catalog:preview-song',
          title: 'Preview Song',
          artist: 'Test Artist',
        ),
      );
      app.results = [source];
      app.combined = combineSources(selected, app.results);
      app.notifyListeners();

      final version = ui.state.comparison!.alternatives.single;
      expect(version.bodyLines.length, 12);
      expect(version.bodyLines[1].section, 'Intro');
      expect(version.bodyLines[6].chords.single.graphemeOffset, 0);
      expect(version.bodyPreview.map((line) => line.text), [
        'First words',
        'Second words',
        'Third words',
      ]);
      expect(version.bodyLines.last.text, 'Fourth words');
      final combined = ui.state.comparison!.suggested!;
      expect(
        {
          for (final item in combined.contributions)
            item.providerName: item.roles,
        },
        {
          'lyrics': ['lyrics', 'chords'],
          'catalog': ['metadata'],
        },
      );
    },
  );

  test(
    'malformed chord-shape tokens stay visible without unbounded matching',
    () async {
      final malformed = [
        'A${'m' * 2000} xxxxx!',
        'A${'1' * 2000} xxxxx!',
        'A${'m' * 24} xxxxx!',
        'A${'1' * 24} xxxxx!',
        'e|${' ' * 2000}!',
        '123456789',
      ];
      await app.saveSong(_song(body: malformed.join('\n')));
      await ui.openSong('song');
      expect(ui.state.songLines.map((line) => line.text), malformed);
      expect(
        ui.state.songLines.every((line) => !line.isArrangementNote),
        isTrue,
      );
    },
  );

  test(
    'stream updates keep first arrival order and rejected explicit choice selected',
    () async {
      const selected = SongCandidate(
        providerId: 'catalog',
        id: 'ordered-song',
        title: 'Ordered Song',
        artist: 'Test Artist',
      );
      const first = SourceResult(
        candidate: SongCandidate(
          providerId: 'first',
          id: 'ordered-song',
          title: 'Ordered Song',
          artist: 'Test Artist',
        ),
        body: 'First provider lyrics that are long enough',
        matchKind: MatchKind.sameSong,
      );
      const second = SourceResult(
        candidate: SongCandidate(
          providerId: 'second',
          id: 'ordered-song',
          title: 'Ordered Song',
          artist: 'Test Artist',
        ),
        body: '[C]Second provider lyrics that are long enough',
        matchKind: MatchKind.sameSong,
      );
      const rejected = SourceResult(
        candidate: SongCandidate(
          providerId: 'second',
          id: 'ordered-song',
          title: 'Ordered Song',
          artist: 'Test Artist',
        ),
        body: '[G]Rejected provider lyrics that are long enough',
        matchKind: MatchKind.rejected,
      );
      ui.dispose();
      app.dispose();
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([]),
      );
      await app.initialize();
      ui = AppControllerAdapter(app);
      ui.setQuery('ordered song');
      await ui.submitSearch();
      app.suggestions = [selected];
      await ui.selectReference(
        const SearchReferenceData(
          id: 'catalog:ordered-song',
          title: 'Ordered Song',
          artist: 'Test Artist',
        ),
      );
      app.results = [first, second];
      app.discovering = true;
      app.combined = combineSources(selected, [first]);
      app.notifyListeners();
      ui.selectVersion(second.id);

      expect(ui.state.comparison!.alternatives.map((item) => item.id), [
        first.id,
        second.id,
      ]);
      expect(ui.state.comparison!.selectedVersionId, second.id);
      expect(ui.state.comparison!.alternatives.last.isChecking, isTrue);

      // Provider progress replaces its result and appends it to the controller
      // list. The adapter retains its first-seen position across that update.
      app.results = [first, second.copyWith(timingTracks: const [])];
      app.results = [app.results.last, app.results.first];
      app.notifyListeners();
      expect(ui.state.comparison!.alternatives.map((item) => item.id), [
        first.id,
        second.id,
      ]);

      app.results = [first, rejected];
      app.discovering = false;
      app.combined = combineSources(selected, [first]);
      app.notifyListeners();

      expect(ui.state.comparison!.alternatives.map((item) => item.id), [
        first.id,
        rejected.id,
      ]);
      expect(ui.state.comparison!.selectedVersionId, second.id);
      expect(ui.state.comparison!.selected!.id, second.id);
      expect(ui.state.comparison!.selected!.isUsableVersion, isTrue);
      expect(ui.state.comparison!.selected!.canSave, isTrue);
      await ui.saveSelectedVersion();
      expect(app.songs, hasLength(1));
      expect(
        app.songs.single.body,
        '[G]Rejected provider lyrics that are long enough',
      );
    },
  );

  test(
    'explicit version choice survives asynchronous discovery completion',
    () async {
      ui.dispose();
      app.dispose();
      const selected = SongCandidate(
        providerId: 'catalog',
        id: 'sample-song',
        title: 'Sample Song',
        artist: 'Test Artist',
      );
      final releaseSlowProvider = Completer<void>();
      final firstResult = Completer<void>();
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([
          _StatusProvider(
            id: 'catalog',
            capabilities: const {'lyrics'},
            selected: selected,
            body: 'A complete sample song lyric arrangement',
          ),
          _StatusProvider(
            id: 'other',
            capabilities: const {'lyrics'},
            selected: selected,
            body: 'A complete sample song lyric arrangement',
            waitBeforeResolve: releaseSlowProvider.future,
          ),
        ]),
      );
      await app.initialize();
      app.settings['catalog'] = 'catalog';
      ui = AppControllerAdapter(app);
      app.addListener(() {
        if (app.results.isNotEmpty && !firstResult.isCompleted) {
          firstResult.complete();
        }
      });
      ui.setQuery('sample song');
      await ui.submitSearch();
      final selecting = ui.selectReference(
        const SearchReferenceData(
          id: 'catalog:sample-song',
          title: 'Sample Song',
          artist: 'Test Artist',
        ),
      );
      await firstResult.future.timeout(const Duration(seconds: 2));
      ui.selectVersion('catalog:sample-song');
      expect(
        ui.state.comparison?.selected?.id,
        'catalog:sample-song',
        reason: 'explicit selection remains visible while discovery is active',
      );
      releaseSlowProvider.complete();
      await selecting;

      expect(ui.state.comparison?.selectedVersionId, 'catalog:sample-song');
    },
  );

  test(
    'an explicit rejected choice survives the discovery completion callback',
    () async {
      ui.dispose();
      app.dispose();
      const candidate = SongCandidate(
        providerId: 'first',
        id: 'stream',
        title: 'Stream Song',
        artist: 'Test Artist',
      );
      const source = SourceResult(
        candidate: candidate,
        body: '[C]The first available arrangement',
        matchKind: MatchKind.sameSong,
      );
      final discovery = _StreamingDiscovery(candidate, source);
      app = AppController(repository: repository, discovery: discovery);
      await app.initialize();
      ui = AppControllerAdapter(app);
      ui.setQuery('stream song');
      await ui.submitSearch();
      final selecting = ui.selectReference(
        const SearchReferenceData(
          id: 'first:stream',
          title: 'Stream Song',
          artist: 'Test Artist',
        ),
      );
      await discovery.started.future;
      ui.selectVersion(source.id);
      expect(ui.state.comparison?.selectedVersionId, source.id);
      const alternative = SourceResult(
        candidate: SongCandidate(
          providerId: 'other',
          id: 'stream',
          title: 'Stream Song',
          artist: 'Test Artist',
        ),
        body: 'The complete matching song arrangement',
        matchKind: MatchKind.sameSong,
      );
      discovery.finished.complete([
        const SourceResult(
          candidate: candidate,
          body: '[C]The first available arrangement',
          matchKind: MatchKind.rejected,
        ),
        alternative,
      ]);
      await selecting;
      expect(ui.state.comparison?.selectedVersionId, source.id);
      expect(ui.state.comparison?.selected?.canSave, isTrue);
      await ui.saveSelectedVersion();
      expect(app.songs, hasLength(1));
      expect(app.songs.single.body, source.body);
    },
  );

  test(
    'combined remains the default when every lyric match is unverified',
    () async {
      ui.dispose();
      app.dispose();
      const candidate = SongCandidate(
        providerId: 'catalog',
        id: 'stream',
        title: 'Stream Song',
        artist: 'Test Artist',
      );
      const rejected = SourceResult(
        candidate: SongCandidate(
          providerId: 'songsterr',
          id: 'stream',
          title: 'Stream Song',
          artist: 'Test Artist',
        ),
        body: '[C]A result that failed the automatic match check',
        matchKind: MatchKind.rejected,
      );
      final discovery = _StreamingDiscovery(candidate, rejected);
      app = AppController(repository: repository, discovery: discovery);
      await app.initialize();
      ui = AppControllerAdapter(app);
      ui.setQuery('stream song');
      await ui.submitSearch();
      final selecting = ui.selectReference(
        const SearchReferenceData(
          id: 'catalog:stream',
          title: 'Stream Song',
          artist: 'Test Artist',
        ),
      );
      await discovery.started.future;
      discovery.finished.complete([rejected]);
      await selecting;

      expect(ui.state.comparison?.suggested?.id, 'combined');
      expect(ui.state.comparison?.selectedVersionId, 'combined');
      expect(ui.state.comparison?.suggested?.matchSummary, 'identity_mismatch');
      expect(ui.state.comparison?.alternatives.single.canSave, isTrue);
      await ui.saveSelectedVersion();
      expect(app.songs, hasLength(1));
      expect(app.songs.single.body, rejected.body);
    },
  );

  test('saving a combined preview preserves pending chord checks', () async {
    const candidate = SongCandidate(
      providerId: 'catalog',
      id: 'pending-chart-song',
      title: 'Pending Chart Song',
      artist: 'Test Artist',
    );
    const chart = SourceResult(
      candidate: candidate,
      body: '[C]A lyric line with pending chord verification',
      matchKind: MatchKind.sameRecording,
    );
    app.selection = candidate;
    app.results = [chart];
    app.discovering = true;
    app.combined = combineSources(candidate, [
      chart.copyWith(extra: {'pendingMatchCheck': true}),
    ]);

    final saved = await app.saveResult();

    expect(saved.extra['pendingChordSourceIds'], [chart.id]);
    expect(saved.sources.single.extra['pendingMatchCheck'], isTrue);
  });

  test('pending combined chord preview shows its status before save', () async {
    ui.dispose();
    app.dispose();
    const candidate = SongCandidate(
      providerId: 'catalog',
      id: 'pending-preview-song',
      title: 'Pending Preview Song',
      artist: 'Test Artist',
      album: 'Test Album',
      durationSeconds: 120,
    );
    const lyrics = SourceResult(
      candidate: candidate,
      body:
          'First lyric line\nSecond lyric line\nThird lyric line\nFourth lyric line',
      matchKind: MatchKind.sameRecording,
    );
    const chart = SourceResult(
      candidate: SongCandidate(
        providerId: 'chart-provider',
        id: 'pending-preview-song',
        title: 'Pending Preview Song',
        artist: 'Test Artist',
        album: 'Test Album',
        durationSeconds: 120,
      ),
      body: '[C]First lyric line\n[F]Second lyric line',
      matchKind: MatchKind.sameRecording,
    );
    final discovery = _StreamingDiscovery(
      candidate,
      lyrics,
      additionalSources: [chart],
    );
    app = AppController(repository: repository, discovery: discovery);
    await app.initialize();
    ui = AppControllerAdapter(app);
    ui.setQuery('pending preview song');
    await ui.submitSearch();
    final selecting = ui.selectReference(
      const SearchReferenceData(
        id: 'catalog:pending-preview-song',
        title: 'Pending Preview Song',
        artist: 'Test Artist',
      ),
    );
    await discovery.started.future;

    expect(ui.state.comparison?.suggested?.matchSummary, 'pending');
    expect(ui.state.comparison?.suggested?.sameRecording, isFalse);
    ui.selectVersion(chart.id);
    expect(ui.state.comparison?.selected?.sameRecording, isFalse);
    expect(ui.state.comparison?.selected?.matchSummary, 'pending');
    expect(ui.state.comparison?.selected?.canSave, isTrue);
    ui.selectVersion('combined');
    await ui.saveSelectedVersion();
    expect(app.songs.single.extra['pendingChordSourceIds'], [chart.id]);

    discovery.finished.complete([lyrics, chart]);
    await selecting;
  });

  test('sameRecording labels reflect conflicting recording metadata', () async {
    ui.dispose();
    app.dispose();
    const candidate = SongCandidate(
      providerId: 'catalog',
      id: 'duration-conflict-song',
      title: 'Duration Conflict Song',
      artist: 'Test Artist',
      album: 'Test Album',
      durationSeconds: 120,
    );
    const lyrics = SourceResult(
      candidate: candidate,
      body:
          'First lyric line\nSecond lyric line\nThird lyric line\nFourth lyric line',
      matchKind: MatchKind.sameRecording,
    );
    const chart = SourceResult(
      candidate: SongCandidate(
        providerId: 'chart-provider',
        id: 'duration-conflict-song',
        title: 'Duration Conflict Song',
        artist: 'Test Artist',
        album: 'Test Album',
        durationSeconds: 150,
      ),
      body: '[C]First lyric line\n[F]Second lyric line',
      matchKind: MatchKind.sameRecording,
      matchReason: 'same_recording',
    );
    final discovery = _StreamingDiscovery(
      candidate,
      lyrics,
      additionalSources: [chart],
    );
    app = AppController(repository: repository, discovery: discovery);
    await app.initialize();
    ui = AppControllerAdapter(app);
    ui.setQuery('duration conflict song');
    await ui.submitSearch();
    final selecting = ui.selectReference(
      const SearchReferenceData(
        id: 'catalog:duration-conflict-song',
        title: 'Duration Conflict Song',
        artist: 'Test Artist',
      ),
    );
    await discovery.started.future;
    discovery.finished.complete([lyrics, chart]);
    await selecting;

    final comparison = ui.state.comparison!;
    expect(comparison.suggested?.sameRecording, isFalse);
    expect(comparison.suggested?.matchSummary, 'identity_mismatch');
    ui.selectVersion(chart.id);
    expect(ui.state.comparison?.selected?.sameRecording, isFalse);
    expect(ui.state.comparison?.selected?.matchSummary, 'identity_mismatch');
    expect(ui.state.comparison?.selected?.canSave, isTrue);
  });

  test(
    'repeated setlist occurrences advance from the selected entry',
    () async {
      await app.saveSong(_song(metadata: {'key': 'C', 'capo': 1}));
      await app.saveSong(
        _song(id: 'other', title: 'Other', body: 'Other line'),
      );
      await app.saveSetlist(
        SetlistDocument(
          id: 'setlist',
          name: 'Set',
          entries: const [
            SetlistEntry(
              id: 'first',
              songId: 'song',
              overrides: {'key': 'D', 'capo': 3},
            ),
            SetlistEntry(
              id: 'second',
              songId: 'song',
              overrides: {'key': 'E', 'capo': 4},
            ),
            SetlistEntry(id: 'third', songId: 'other'),
          ],
        ),
      );

      await ui.openSetlistEntry('setlist', 'first');
      expect(ui.displayedKey, 'D');
      expect(ui.displayedCapo, 3);
      expect(ui.state.songLines.first.chords.single.symbol, 'D');

      await ui.nextSong();
      expect(ui.state.song?.id, 'song');
      expect(ui.displayedKey, 'E');
      expect(ui.displayedCapo, 4);
      expect(ui.state.songLines.first.chords.single.symbol, 'E');
      await ui.nextSong();

      expect(ui.state.song?.id, 'other');
      await ui.previousSong();
      expect(ui.state.song?.id, 'song');
      expect(ui.displayedKey, 'E');
      expect(ui.displayedCapo, 4);
      expect(ui.state.songLines.first.chords.single.symbol, 'E');
      await ui.previousSong();
      expect(ui.state.song?.id, 'song');
      expect(ui.displayedKey, 'D');
      expect(ui.displayedCapo, 3);
      expect(ui.state.songLines.first.chords.single.symbol, 'D');

      await ui.openSong('song');
      expect(ui.displayedKey, 'C');
      expect(ui.displayedCapo, 1);
      expect(ui.state.songLines.first.chords.single.symbol, 'C');
      expect(app.findSong('song')?.metadata['key'], 'C');
      expect(app.findSong('song')?.metadata['capo'], 1);
    },
  );

  test('readable ChordPro editor omits internal payload headers', () async {
    await app.saveSong(
      _song(extra: {'retained': true}, metadata: {'key': 'C', 'capo': 2}),
    );
    await ui.editSong('song');

    expect(ui.editableChordPro, contains('{title: Song}'));
    expect(ui.editableChordPro, contains('[C]First line'));
    expect(ui.editableChordPro, isNot(contains('{x_verse')));
    expect(ui.editableChordPro, isNot(contains('base64')));

    final edited = ui.editableChordPro
        .replaceFirst('First', 'Edited')
        .replaceFirst('{artist: Artist}', '{artist: }')
        .replaceFirst('{key: C}', '{key: }')
        .replaceFirst('{capo: 2}', '{capo: }');
    await ui.saveLyricsEdit(edited);
    expect(app.findSong('song')!.extra['retained'], true);
    expect(app.findSong('song')!.artist, '');
    expect(app.findSong('song')!.metadata, isNot(contains('key')));
    expect(app.findSong('song')!.metadata, isNot(contains('capo')));
  });
}

SongDocument _song({
  String id = 'song',
  String title = 'Song',
  String body = '[C]First line\n[G]Second line',
  List<TimingTrack> timingTracks = const [],
  JsonMap metadata = const {},
  JsonMap extra = const {},
}) => SongDocument(
  id: id,
  title: title,
  artist: 'Artist',
  body: body,
  metadata: metadata,
  timingTracks: timingTracks,
  activeTimingTrackId: timingTracks.isEmpty ? null : timingTracks.single.id,
  extra: extra,
);

TimingTrack _track({JsonMap extra = const {}}) => TimingTrack(
  id: 'track',
  sourceDocumentId: 'provider',
  sourceLyrics: 'First line\nSecond line',
  format: 'lrc',
  status: TimingStatus.usable,
  cues: const [
    TimingCue(
      id: 'cue',
      occurrenceId: 'line-0',
      text: 'First line',
      startUs: 0,
    ),
  ],
  extra: extra,
);

class _StreamingDiscovery extends SourceDiscoveryService {
  _StreamingDiscovery(
    this.candidate,
    this.source, {
    this.additionalSources = const [],
  }) : super([]);
  final SongCandidate candidate;
  final SourceResult source;
  final List<SourceResult> additionalSources;
  final started = Completer<void>();
  final finished = Completer<List<SourceResult>>();
  @override
  Future<List<SongCandidate>> search(
    String query, {
    String? providerId,
    CancellationToken? cancel,
  }) async => [candidate];
  @override
  Future<List<SourceResult>> discover(
    SongCandidate selection, {
    Set<String>? enabledIds,
    void Function(ProviderCheck)? onProgress,
    CancellationToken? cancel,
    Duration alternativeTimeout = const Duration(seconds: 30),
  }) async {
    for (final result in [source, ...additionalSources]) {
      onProgress?.call(
        ProviderCheck(
          providerId: result.candidate.providerId,
          state: 'found',
          result: result,
        ),
      );
    }
    started.complete();
    return finished.future;
  }
}

class _StatusProvider implements LyricsProvider {
  const _StatusProvider({
    required this.id,
    required this.capabilities,
    required this.selected,
    this.body = '',
    this.timingOnly = false,
    this.metadataOnly = false,
    this.resultMetadata = const {},
    this.failureCode,
    this.waitBeforeResolve,
  });

  final String id;
  final Set<String> capabilities;
  final SongCandidate selected;
  final String body;
  final bool timingOnly, metadataOnly;
  final JsonMap resultMetadata;
  final String? failureCode;
  final Future<void>? waitBeforeResolve;

  @override
  ProviderDefinition get definition =>
      ProviderDefinition(id: id, name: id, capabilities: capabilities);

  SongCandidate get _candidate => SongCandidate(
    providerId: id,
    id: selected.id,
    title: selected.title,
    artist: selected.artist,
    album: selected.album,
    durationSeconds: selected.durationSeconds,
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_candidate];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    await waitBeforeResolve;
    if (failureCode != null) throw ProviderException(failureCode!);
    return SourceResult(
      candidate: _candidate,
      body: body,
      metadata: {if (metadataOnly) 'title': 'Sample Song', ...resultMetadata},
      timingTracks: timingOnly
          ? const [
              TimingTrack(
                id: 'raw-timing',
                sourceDocumentId: 'timing-only',
                sourceLyrics: '',
                format: 'lrc',
                raw: '[00:01.00]A timing-only line',
              ),
            ]
          : const [],
      matchKind: MatchKind.sameSong,
    );
  }
}
