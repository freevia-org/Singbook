import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

const _selected = SongCandidate(
  providerId: 'catalog',
  id: 'selected',
  title: 'Lantern Song',
  artist: 'The Singers',
);

const _lyrics = '''
Amber lanterns glow above the quiet water
Silver rain returns beneath the evening sky
Every window keeps a little golden light
Morning carries every dream back home
''';

SongCandidate _candidate(
  String provider, {
  String id = 'song',
  String title = 'Lantern Song',
  Map<String, dynamic> metadata = const {},
  Map<String, String> recordingIds = const {},
}) => SongCandidate(
  providerId: provider,
  id: id,
  title: title,
  artist: 'The Singers',
  metadata: metadata,
  recordingIds: recordingIds,
);

SourceResult _source(
  String provider, {
  String body = _lyrics,
  String id = 'song',
  String title = 'Lantern Song',
  Map<String, dynamic> metadata = const {},
  Map<String, dynamic> candidateMetadata = const {},
  Map<String, String> recordingIds = const {},
  MatchKind match = MatchKind.sameSong,
  String? matchReason,
  Map<String, dynamic> extra = const {},
}) => SourceResult(
  candidate: _candidate(
    provider,
    id: id,
    title: title,
    metadata: candidateMetadata,
    recordingIds: recordingIds,
  ),
  body: body,
  metadata: metadata,
  matchKind: match,
  matchReason: matchReason,
  extra: extra,
);

Map<String, dynamic> _ranking(SongDocument song) =>
    Map<String, dynamic>.from(song.extra['evidenceRanking'] as Map);

List<Map<String, dynamic>> _claims(SongDocument song, String field) => [
  for (final raw in _ranking(song)['claims'] as List)
    if (raw is Map && raw['field'] == field) Map<String, dynamic>.from(raw),
];

void main() {
  test(
    'matching search key declarations supersede an unsupported relative-key guess',
    () {
      final candidate = _candidate(
        'chart-provider',
        id: 'search-version',
        metadata: {'key': 'Em'},
      );
      final chart = _source(
        'chart-provider',
        body:
            '[Em]Amber lanterns [C]glow above the quiet water\n'
            '[G]Silver rain [D]returns beneath the evening sky\n'
            '[Em]Every window [C]keeps a little golden light\n'
            '[G]Morning carries [D]every dream back home',
        extra: {
          'discoveryEvidence': {
            'searchCandidates': [
              {'candidate': candidate.toJson(), 'state': 'not_resolved'},
            ],
          },
        },
      );
      final combined = combineSources(_selected, [_source('lyrics'), chart]);
      expect(combined.metadata['key'], 'Em');
      expect(combined.extra['keySourceIds'], contains(candidate.identity));
      final declaration = _claims(
        combined,
        'metadata.key',
      ).firstWhere((claim) => claim['sourceId'] == candidate.identity);
      expect(declaration['matchQuality'], 'sameSong');
      expect(declaration['origin'], 'provider');
      final retainedSearch =
          combined.sources
                  .singleWhere((source) => source.id == chart.id)
                  .extra['discoveryEvidence']
              as Map;
      expect(
        (retainedSearch['searchCandidates'] as List).single['candidate']['id'],
        candidate.id,
      );
    },
  );

  test(
    'declared modal tonic outranks a scale model without contrary sources',
    () {
      final chart = _source(
        'chart-provider',
        body:
            '[Am]Amber lanterns [D7]glow above the quiet water\n'
            '[Am]Silver rain [D7]returns beneath the evening sky\n'
            '[Am]Every window [D7]keeps a little golden light\n'
            '[Am]Morning carries [D7]every dream back home',
        metadata: {'key': 'Am'},
      );
      final combined = combineSources(_selected, [_source('lyrics'), chart]);
      expect(combined.metadata['key'], 'Am');
      expect(combined.extra['keySourceIds'], contains(chart.id));
      expect(
        _claims(combined, 'metadata.key').any(
          (claim) => claim['origin'] == 'inferred' && claim['value'] == 'D',
        ),
        isTrue,
      );
    },
  );

  test(
    'same source identity preserves distinct raw diagnostics and candidate facts',
    () {
      final first = _source(
        'provider',
        candidateMetadata: {'catalogNote': 'first'},
        extra: {'resolveFailure': 'earlier attempt'},
      );
      final second = _source(
        'provider',
        candidateMetadata: {'catalogNote': 'second'},
        extra: {'resolveFailure': 'later attempt'},
      );
      final combined = combineSources(_selected, [first, second]);
      final restored = SongDocument.fromJson(
        jsonDecode(jsonEncode(combined.toJson())),
      );
      expect(restored.sources, hasLength(1));
      final snapshots =
          restored.sources.single.extra['sourceEvidenceSnapshots'] as List;
      expect(
        snapshots.map((source) => source['resolveFailure']),
        unorderedEquals(['earlier attempt', 'later attempt']),
      );
      expect(
        _claims(
          restored,
          'metadata.catalogNote',
        ).map((claim) => claim['value']),
        containsAll(['first', 'second']),
      );
    },
  );

  test('raw matching and wrong identity sources survive JSON round trip', () {
    final evidence = [
      _source('lyrics', body: _lyrics, metadata: {'language': 'en'}),
      _source(
        'archive',
        id: 'different-work',
        title: 'Another Song',
        body: '[C]A separate song with chords',
        metadata: {'key': 'C', 'catalogNote': 'retain this claim'},
        match: MatchKind.rejected,
      ),
    ];
    final combined = combineSources(_selected, evidence);
    final restored = SongDocument.fromJson(combined.toJson());

    expect(
      restored.sources.map((source) => source.id).toSet(),
      evidence.map((source) => source.id).toSet(),
    );
    final rejected = restored.sources.singleWhere(
      (source) => source.id == 'archive:different-work',
    );
    expect(rejected.metadata['catalogNote'], 'retain this claim');
    expect(
      _claims(restored, 'metadata.catalogNote').any(
        (claim) =>
            claim['sourceId'] == rejected.id &&
            claim['value'] == 'retain this claim' &&
            claim['contextCompatible'] == false,
      ),
      isTrue,
    );
    expect(_ranking(restored)['retainedSourceCount'], evidence.length);
  });

  test(
    'stronger setup claim wins while conflicting claims remain in ledger',
    () {
      final selectedRecording = SongCandidate(
        providerId: 'catalog',
        id: 'selected',
        title: 'Lantern Song',
        artist: 'The Singers',
        recordingIds: const {'isrc': 'recording-a'},
      );
      final weaker = _source(
        'provider-weak',
        body: _lyrics,
        metadata: {'key': 'D'},
        recordingIds: const {'isrc': 'recording-b'},
        match: MatchKind.sameSong,
      );
      final stronger = _source(
        'provider-strong',
        body: _lyrics,
        metadata: {'key': 'C'},
        recordingIds: const {'isrc': 'recording-a'},
        match: MatchKind.sameRecording,
      );
      final combined = combineSources(selectedRecording, [weaker, stronger]);
      final keyClaims = _claims(combined, 'metadata.key');

      expect(combined.metadata['key'], 'C');
      expect(keyClaims.map((claim) => claim['value']).toSet(), {'C', 'D'});
      expect(keyClaims.any((claim) => claim['sourceId'] == weaker.id), isTrue);
      expect(
        keyClaims.any((claim) => claim['sourceId'] == stronger.id),
        isTrue,
      );
    },
  );

  test(
    'distinct provider corroboration scores above repeated same-provider claims',
    () {
      final repeated = combineSources(_selected, [
        _source('provider-a', id: 'one', metadata: {'genre': 'folk'}),
        _source('provider-a', id: 'two', metadata: {'genre': 'folk'}),
      ]);
      final independent = combineSources(_selected, [
        _source('provider-a', id: 'one', metadata: {'genre': 'folk'}),
        _source('provider-a', id: 'two', metadata: {'genre': 'folk'}),
        _source('provider-b', id: 'three', metadata: {'genre': 'folk'}),
      ]);
      int sourceScore(SongDocument song, String sourceId) =>
          _claims(song, 'metadata.genre')
              .where((claim) => claim['sourceId'] == sourceId)
              .map((claim) => claim['score'] as int)
              .reduce((a, b) => a > b ? a : b);

      expect(
        sourceScore(independent, 'provider-a:one'),
        greaterThan(sourceScore(repeated, 'provider-a:one')),
      );
    },
  );

  test(
    'recording-compatible short lyrics outrank a longer weaker alternative',
    () {
      const shortRecordingLyrics = '''
Lanterns glow softly softly softly softly softly
Rain returns softly softly softly softly softly
Windows shine softly softly softly softly softly
Dreams come home softly softly softly softly softly
''';
      final selectedRecording = SongCandidate(
        providerId: 'catalog',
        id: 'selected',
        title: 'Lantern Song',
        artist: 'The Singers',
        recordingIds: const {'isrc': 'recording-a'},
      );
      final short = _source(
        'recording-source',
        id: 'recording',
        body: shortRecordingLyrics,
        recordingIds: const {'isrc': 'recording-a'},
        match: MatchKind.sameRecording,
      );
      final longer = _source(
        'other-performance',
        id: 'performance',
        body:
            'An expanded intro\n$_lyrics\nA new final verse with many extra words',
        recordingIds: const {'isrc': 'recording-b'},
        match: MatchKind.sameSong,
      );

      final combined = combineSources(selectedRecording, [longer, short]);

      expect(combined.extra['selectedSourceId'], short.id);
      expect(
        _ranking(combined)['chosenByField']['lyrics']['sourceId'],
        short.id,
      );
    },
  );

  test(
    'key claim survives bridge disagreement and setup stays attached to chart',
    () {
      const chartBody =
          '[F#m]Amber lanterns glow\n[Bm]Silver rain returns\n'
          '[D]Across the sleepy water\n[C#]Morning brings a melody';
      final bridge = _source(
        'bridge-source',
        body: _lyrics,
        metadata: {'key': 'C'},
        match: MatchKind.sameSong,
      );
      final selectedRecording = SongCandidate(
        providerId: 'catalog',
        id: 'selected',
        title: 'Lantern Song',
        artist: 'The Singers',
        recordingIds: const {'isrc': 'recording-a'},
      );
      final chart = _source(
        'chart-source',
        body: chartBody,
        metadata: {
          'key': 'F#m',
          'capo': 0,
          'tuning': 'E A D G B E',
          'timeSignature': '4/4',
        },
        recordingIds: const {'isrc': 'recording-a'},
        match: MatchKind.sameRecording,
        extra: {'keyConsensus': true},
      );
      final combined = combineSources(selectedRecording, [chart, bridge]);
      final keyClaims = _claims(combined, 'metadata.key');

      expect(
        keyClaims.any(
          (claim) => claim['sourceId'] == chart.id && claim['value'] == 'F#m',
        ),
        isTrue,
      );
      expect(
        keyClaims.any(
          (claim) => claim['sourceId'] == bridge.id && claim['value'] == 'C',
        ),
        isTrue,
      );
      expect(combined.metadata['key'], 'F#m');
      expect(combined.metadata['capo'], 0);
      expect(combined.metadata['tuning'], 'E A D G B E');
      expect(combined.metadata['timeSignature'], '4/4');
    },
  );

  test(
    'conflicting ties and ledger alternatives are stable under input permutation',
    () {
      final first = _source('provider-a', metadata: {'key': 'D'});
      final second = _source('provider-b', metadata: {'key': 'E'});
      final forward = combineSources(_selected, [first, second]);
      final reverse = combineSources(_selected, [second, first]);
      final forwardRanking = jsonEncode(_ranking(forward));
      final reverseRanking = jsonEncode(_ranking(reverse));

      expect(forwardRanking, reverseRanking);
      expect(
        _claims(forward, 'metadata.key').map((claim) => claim['value']).toSet(),
        {'D', 'E'},
      );
      expect(_ranking(forward)['ambiguousFields'], contains('metadata.key'));
    },
  );

  test(
    'partial chart claims key and contributes aligned chords without replacing lyrics',
    () {
      const partialBody =
          '[C]Amber lanterns glow above the quiet water\n[F]Silver rain returns beneath the evening sky';
      final lyrics = _source('lyrics-provider', body: _lyrics);
      final partialChart = _source(
        'chart-provider',
        body: partialBody,
        metadata: {'key': 'C', 'capo': 0, 'tuning': 'E A D G B E'},
        match: MatchKind.rejected,
        matchReason: 'incomplete_or_different_lyrics',
      );
      final combined = combineSources(_selected, [lyrics, partialChart]);

      expect(
        combined.body,
        contains('Amber lanterns glow above the quiet water'),
      );
      expect(combined.body, contains('[C]'));
      expect(combined.extra['selectedSourceId'], lyrics.id);
      expect(
        _claims(combined, 'metadata.key').any(
          (claim) =>
              claim['sourceId'] == partialChart.id && claim['value'] == 'C',
        ),
        isTrue,
      );
    },
  );
}
