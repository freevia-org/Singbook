import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

// Invented lyrics only. Exact ordered wording makes the chart fixture safe to
// use for corroboration without embedding copyrighted material.
const _lyrics = [
  'Harbor lanterns gather where the quiet river bends',
  'Silver windows carry evening over winding stone streets',
  'A distant bell reminds the sailors to return home',
  'Lantern keeper draws a map of falling summer stars',
  'Every narrow bridge glows softly through the midnight rain',
  'We leave the harbor when the pale morning rises',
  'Across the water songs remember how the tide turns',
  'Home is waiting where the small boats rest at dawn',
];
final _lyricsText = _lyrics.join('\n');
const _album = 'Moon Harbor (Original Motion Picture Soundtrack)';
const _coverArt = 'https://art.example.test/moon-harbor.png';
const _writer = 'Avery North';

const _selected = SongCandidate(
  providerId: 'genius',
  id: 'recording-42',
  title: 'Harbor Song',
  artist: 'The Lantern Coast',
  durationSeconds: 214,
  metadata: {'identityScope': 'recording'},
  recordingIds: {'isrc': 'US-TEST-0042'},
);

SongCandidate _enrichedRecording() => SongCandidate(
  providerId: 'genius',
  id: _selected.id,
  title: _selected.title,
  artist: _selected.artist,
  album: _album,
  durationSeconds: _selected.durationSeconds,
  metadata: {
    'identityScope': 'recording',
    'artworkUrl': _coverArt,
    'credits': [
      {'role': 'writer', 'name': _writer},
    ],
  },
  recordingIds: _selected.recordingIds,
);

String _chartBody(Map<int, String> chords) => [
  for (var i = 0; i < _lyrics.length; i++)
    '${chords.containsKey(i) ? '[${chords[i]}]' : ''}${_lyrics[i]}',
].join('\n');

final _composerChartBody = _chartBody(const {
  0: 'C',
  1: 'G',
  2: 'Am',
  3: 'F',
  4: 'C',
});
final _soundtrackChartBody = _chartBody(const {
  0: 'C',
  2: 'Am',
  5: 'F',
  7: 'G',
});

class _RecordingLyrics implements LyricsProvider {
  _RecordingLyrics({String? body, this.hold = false})
    : body = body ?? _lyricsText;

  final String body;
  final bool hold;
  final started = Completer<CancellationToken?>();
  final release = Completer<void>();
  final resolvedIds = <String>[];

  @override
  final definition = const ProviderDefinition(
    id: 'genius',
    name: 'Catalog and lyrics',
    capabilities: {'catalog', 'lyrics'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_enrichedRecording()];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolvedIds.add(candidate.id);
    if (!started.isCompleted) started.complete(cancel);
    if (hold) await release.future;
    cancel?.throwIfCancelled();
    final enriched = _enrichedRecording();
    return SourceResult(
      candidate: enriched,
      body: body,
      metadata: {'album': _album, 'artworkUrl': _coverArt},
    );
  }
}

class _OtherLyrics implements LyricsProvider {
  @override
  final definition = const ProviderDefinition(
    id: 'lrclib',
    name: 'Other lyrics catalog',
    capabilities: {'catalog', 'lyrics'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [
    const SongCandidate(
      providerId: 'lrclib',
      id: 'different-recording',
      title: 'Harbor Song',
      artist: 'The Lantern Coast',
    ),
  ];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(candidate: candidate, body: _lyricsText);
}

class _ContextChart implements LyricsProvider {
  _ContextChart(
    this.definition,
    this.rows, {
    String? body,
    this.holdResolve = false,
  }) : body = body ?? _composerChartBody;

  @override
  final ProviderDefinition definition;
  final List<SongCandidate> rows;
  final String body;
  final bool holdResolve;
  final startedSearch = Completer<void>();
  final startedResolve = Completer<CancellationToken?>();
  final releaseResolve = Completer<void>();
  final queries = <String>[];
  final resolvedIds = <String>[];

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    queries.add(query);
    if (!startedSearch.isCompleted) startedSearch.complete();
    return rows;
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolvedIds.add(candidate.id);
    if (!startedResolve.isCompleted) startedResolve.complete(cancel);
    if (holdResolve) await releaseResolve.future;
    cancel?.throwIfCancelled();
    return SourceResult(candidate: candidate, body: body);
  }
}

_ContextChart _composerChart({String? body, bool hold = false}) =>
    _ContextChart(
      const ProviderDefinition(
        id: 'songsterr',
        name: 'Songsterr',
        capabilities: {'catalog', 'lyrics', 'chords'},
      ),
      const [
        SongCandidate(
          providerId: 'songsterr',
          id: 'composer-chart-1',
          title: 'Harbor Song',
          artist: _writer,
        ),
      ],
      body: body,
      holdResolve: hold,
    );

_ContextChart _soundtrackChart({String? body}) => _ContextChart(
  const ProviderDefinition(
    id: 'ultimateguitar',
    name: 'Ultimate Guitar',
    capabilities: {'catalog', 'lyrics', 'chords'},
  ),
  const [
    SongCandidate(
      providerId: 'ultimateguitar',
      id: 'soundtrack-chart-1',
      title: 'Moon Harbor - Harbor Song',
      artist: 'Misc Soundtrack',
    ),
  ],
  body: body ?? _soundtrackChartBody,
);

Future<void> _waitForInitialChartSearches(
  Iterable<_ContextChart> charts,
) async {
  await Future.wait(
    charts.map(
      (chart) => chart.startedSearch.future.timeout(const Duration(seconds: 2)),
    ),
  );
}

void main() {
  test('unverified same-ID lyrics cannot authorize a contextual chart', () {
    final pending = SourceResult(
      candidate: _enrichedRecording(),
      body: _lyricsText,
      matchKind: MatchKind.unverified,
    );
    final chart = SourceResult(
      candidate: _composerChart().rows.single,
      body: _composerChartBody,
      matchKind: MatchKind.sameSong,
      extra: const {
        'requiresLyricsAgreement': true,
        'requiresRecordingLyricsAgreement': true,
      },
    );
    final combined = combineSources(_selected, [pending, chart]);
    expect(plainLyrics(combined.body), _lyricsText);
    expect(
      parseArrangement(combined.body).any((line) => line.chords.isNotEmpty),
      isFalse,
    );
    expect(contributingProviderIds(combined), isNot(contains('songsterr')));
  });
  test(
    'deferred composer and soundtrack charts reuse searches and preserve selected recording lyrics',
    () async {
      final reference = _RecordingLyrics(hold: true);
      final composer = _composerChart();
      final soundtrack = _soundtrackChart();
      final discovery = SourceDiscoveryService([
        reference,
        composer,
        soundtrack,
      ]).discover(_selected);
      await reference.started.future.timeout(const Duration(seconds: 2));
      await _waitForInitialChartSearches([composer, soundtrack]);
      expect(composer.resolvedIds, isEmpty);
      expect(soundtrack.resolvedIds, isEmpty);
      reference.release.complete();
      final results = await discovery;

      expect(composer.queries, hasLength(1));
      expect(soundtrack.queries, hasLength(1));
      expect(composer.resolvedIds, ['composer-chart-1']);
      expect(soundtrack.resolvedIds, ['soundtrack-chart-1']);

      final acceptedCharts = results
          .where(
            (source) =>
                {
                  'songsterr',
                  'ultimateguitar',
                }.contains(source.candidate.providerId) &&
                source.hasChords &&
                source.matchKind != MatchKind.rejected,
          )
          .toList();
      expect(acceptedCharts, hasLength(2));
      expect(
        acceptedCharts.every(
          (source) => !recordingCompatible(_selected, source),
        ),
        isTrue,
        reason:
            'context match admits a donor; it does not create a recording identity',
      );

      final combined = combineSources(_selected, results);
      expect(plainLyrics(combined.body), _lyricsText);
      expect(combined.body, contains('[C]'));
      expect(
        parseArrangement(
          combined.body,
        ).where((line) => line.chords.isNotEmpty).length,
        greaterThan(4),
        reason:
            'complementary anchors let both charts contribute distinct line placements',
      );
      expect(combined.metadata['album'], _album);
      expect(combined.metadata['artworkUrl'], _coverArt);
      expect(
        contributingProviderIds(combined),
        containsAll({'genius', 'songsterr', 'ultimateguitar'}),
      );
      final chordIds = (combined.extra['chordSourceIds'] as List)
          .cast<String>();
      expect(
        chordIds,
        containsAll([
          'songsterr:composer-chart-1',
          'ultimateguitar:soundtrack-chart-1',
        ]),
      );
    },
  );

  test(
    'a same-song lyric result from another provider is insufficient context without a recording-compatible reference',
    () async {
      final reference = _RecordingLyrics(body: 'Harbor song, harbor song.');
      final composer = _composerChart();
      final soundtrack = _soundtrackChart();
      final results = await SourceDiscoveryService([
        reference,
        _OtherLyrics(),
        composer,
        soundtrack,
      ]).discover(_selected);

      expect(composer.queries, hasLength(1));
      expect(soundtrack.queries, hasLength(1));
      expect(composer.resolvedIds, isEmpty);
      expect(soundtrack.resolvedIds, isEmpty);
      expect(
        results.where(
          (source) =>
              {
                'songsterr',
                'ultimateguitar',
              }.contains(source.candidate.providerId) &&
              source.hasChords &&
              source.matchKind != MatchKind.rejected,
        ),
        isEmpty,
      );
    },
  );

  test(
    'combineSources does not treat contextual flags as evidence without recording-compatible lyrics',
    () {
      final otherRecording = SourceResult(
        candidate: const SongCandidate(
          providerId: 'lrclib',
          id: 'same-song-other-recording',
          title: 'Harbor Song',
          artist: 'The Lantern Coast',
          album: _album,
          metadata: {
            'credits': [
              {'role': 'writer', 'name': _writer},
            ],
          },
        ),
        body: _lyricsText,
        matchKind: MatchKind.sameSong,
      );
      final contextualChart = SourceResult(
        candidate: const SongCandidate(
          providerId: 'songsterr',
          id: 'contextual-only',
          title: 'Harbor Song',
          artist: _writer,
        ),
        body: _composerChartBody,
        matchKind: MatchKind.sameSong,
        extra: const {
          'requiresLyricsAgreement': true,
          'requiresRecordingLyricsAgreement': true,
        },
      );

      expect(recordingCompatible(_selected, otherRecording), isFalse);
      final combined = combineSources(_selected, [
        otherRecording,
        contextualChart,
      ]);
      expect(plainLyrics(combined.body), _lyricsText);
      expect(combined.hasChords, isFalse);
      expect(combined.extra['chordSourceIds'] ?? const [], isEmpty);
    },
  );

  test(
    'unrelated soundtrack work and a named cover artist do not trigger contextual fetches',
    () async {
      final unrelatedFilm = _ContextChart(
        const ProviderDefinition(
          id: 'songsterr',
          name: 'Songsterr',
          capabilities: {'catalog', 'lyrics', 'chords'},
        ),
        const [
          SongCandidate(
            providerId: 'songsterr',
            id: 'other-film-chart',
            title: 'Other Moon - Harbor Song',
            artist: 'Misc Soundtrack',
          ),
        ],
      );
      final namedCover = _ContextChart(
        const ProviderDefinition(
          id: 'ultimateguitar',
          name: 'Ultimate Guitar',
          capabilities: {'catalog', 'lyrics', 'chords'},
        ),
        const [
          SongCandidate(
            providerId: 'ultimateguitar',
            id: 'cover-artist-chart',
            title: 'Harbor Song',
            artist: 'The Night Sailors',
          ),
        ],
      );
      await SourceDiscoveryService([
        _RecordingLyrics(),
        unrelatedFilm,
        namedCover,
      ]).discover(_selected);

      expect(unrelatedFilm.queries, hasLength(1));
      expect(namedCover.queries, hasLength(1));
      expect(unrelatedFilm.resolvedIds, isEmpty);
      expect(namedCover.resolvedIds, isEmpty);
    },
  );

  test(
    'a contextual chart sharing only a refrain is not accepted or combined',
    () async {
      const differentWords = [
        'Copper mountains watch the sleepy valley open wide',
        'Paper kites are lifting past the distant railway station',
        'Every traveler follows footprints through the orchard grass',
        'Summer rain is tapping on the windows of the train',
        'All the city lights are fading from the northern sky',
        'A quiet road will carry us beyond the old stone wall',
      ];
      final chartText = [
        for (final line in differentWords) '[D]$line',
        '[C]${_lyrics[0]}',
        '[G]${_lyrics[1]}',
      ].join('\n');
      final composer = _composerChart(body: chartText);
      final results = await SourceDiscoveryService([
        _RecordingLyrics(),
        composer,
      ]).discover(_selected);

      expect(composer.queries, hasLength(1));
      expect(composer.resolvedIds, ['composer-chart-1']);
      expect(
        results.where(
          (source) =>
              source.candidate.providerId == 'songsterr' &&
              source.hasChords &&
              source.matchKind != MatchKind.rejected,
        ),
        isEmpty,
      );
      final combined = combineSources(_selected, results);
      expect(plainLyrics(combined.body), _lyricsText);
      expect(combined.extra['chordSourceIds'] ?? const [], isEmpty);
    },
  );

  test(
    'global and provider cancellation during reference resolution prevent deferred chart resolution',
    () async {
      for (final cancelProviderOnly in [false, true]) {
        final reference = _RecordingLyrics(hold: true);
        final composer = _composerChart();
        final soundtrack = _soundtrackChart();
        final globalCancel = CancellationToken();
        final referenceCancel = CancellationToken();
        final discovery =
            SourceDiscoveryService([reference, composer, soundtrack]).discover(
              _selected,
              cancel: globalCancel,
              providerCancellation: {'genius': referenceCancel},
            );
        await reference.started.future.timeout(const Duration(seconds: 2));
        await _waitForInitialChartSearches([composer, soundtrack]);

        if (cancelProviderOnly) {
          referenceCancel.cancel();
        } else {
          globalCancel.cancel();
        }
        reference.release.complete();
        if (cancelProviderOnly) {
          await discovery.timeout(const Duration(seconds: 2));
        } else {
          await expectLater(
            discovery,
            throwsA(
              isA<ProviderException>().having(
                (e) => e.code,
                'code',
                'cancelled',
              ),
            ),
          );
        }

        expect(composer.resolvedIds, isEmpty);
        expect(soundtrack.resolvedIds, isEmpty);
        expect(composer.queries, hasLength(1));
        expect(soundtrack.queries, hasLength(1));
      }
    },
  );

  test(
    'contextual timeout cancels the lookup token and ignores a late chart response',
    () async {
      final composer = _composerChart(hold: true);
      final checks = <ProviderCheck>[];
      final discovery = SourceDiscoveryService([_RecordingLyrics(), composer])
          .discover(
            _selected,
            alternativeTimeout: const Duration(milliseconds: 30),
            onProgress: checks.add,
          );
      final lookupToken = await composer.startedResolve.future.timeout(
        const Duration(seconds: 2),
      );
      expect(lookupToken, isNotNull);
      final results = await discovery.timeout(const Duration(seconds: 2));
      expect(lookupToken!.isCancelled, isTrue);
      composer.releaseResolve.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        results.where(
          (source) =>
              source.candidate.id == 'composer-chart-1' &&
              source.hasChords &&
              source.matchKind != MatchKind.rejected,
        ),
        isEmpty,
      );
      expect(
        checks.where(
          (check) =>
              check.result?.candidate.id == 'composer-chart-1' &&
              check.result!.hasChords &&
              check.result!.matchKind != MatchKind.rejected,
        ),
        isEmpty,
        reason:
            'the late transport response cannot publish after discover returns',
      );
      expect(composer.queries, hasLength(1));
      expect(composer.resolvedIds, ['composer-chart-1']);
    },
  );
}
