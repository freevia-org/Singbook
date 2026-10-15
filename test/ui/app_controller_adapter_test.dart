import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
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

class _StatusProvider implements LyricsProvider {
  const _StatusProvider({
    required this.id,
    required this.capabilities,
    required this.selected,
    this.body = '',
    this.timingOnly = false,
    this.metadataOnly = false,
    this.failureCode,
  });

  final String id;
  final Set<String> capabilities;
  final SongCandidate selected;
  final String body;
  final bool timingOnly, metadataOnly;
  final String? failureCode;

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
    if (failureCode != null) throw ProviderException(failureCode!);
    return SourceResult(
      candidate: _candidate,
      body: body,
      metadata: metadataOnly ? const {'title': 'Sample Song'} : const {},
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
