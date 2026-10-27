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
  test('conflicting supplied keys weigh the chosen chart home key', () {
    final chart = _source(
      'chart',
      body:
          '[D]Amber lanterns glow above the quiet water\n'
          '[G]Silver rain returns beneath the evening sky\n'
          '[A]Every window keeps a little golden light\n'
          '[D]Morning carries every dream back home',
      metadata: {'capo': 5},
    );
    final first = _source(
      'first',
      body: '',
      metadata: {'key': 'C'},
      extra: {'metadataOnly': true},
    );
    final second = _source(
      'second',
      body: '',
      metadata: {'key': 'G'},
      extra: {'metadataOnly': true},
    );
    final combined = combineSources(_selected, [chart, first, second]);
    expect(combined.metadata['key'], 'G');
    expect(combined.metadata['capo'], 5);
    expect(
      _claims(combined, 'metadata.key').map((c) => c['value']),
      containsAll(['C', 'G']),
    );
    expect(
      combined.sources.singleWhere((s) => s.id == first.id).metadata['key'],
      'C',
    );
  });
  test('capo shape declaration is retained alongside its sounding reading', () {
    final chart = _source(
      'chart',
      body:
          '[C]Amber lanterns glow above the quiet water\n'
          '[F]Silver rain returns beneath the evening sky\n'
          '[G]Every window keeps a little golden light\n'
          '[C]Morning carries every dream back home',
      metadata: {'key': 'C', 'capo': 2},
    );
    final key = _source(
      'metadata',
      body: '',
      metadata: {'key': 'D'},
      extra: {'metadataOnly': true},
    );
    final combined = combineSources(_selected, [chart, key]);
    expect(combined.metadata['key'], 'D');
    expect(combined.metadata['capo'], 2);
    expect(
      combined.sources.singleWhere((s) => s.id == chart.id).metadata['key'],
      'C',
    );
    expect(
      _claims(
        combined,
        'metadata.key',
      ).where((c) => c['sourceId'] == chart.id).map((c) => c['value']),
      containsAll(['C', 'D']),
    );
  });

  test('already sounding capo declaration is not transposed twice', () {
    final chart = _source(
      'chart',
      body:
          '[C]Amber lanterns glow above the quiet water\n'
          '[F]Silver rain returns beneath the evening sky\n'
          '[G]Every window keeps a little golden light\n'
          '[C]Morning carries every dream back home',
      metadata: {'key': 'D', 'capo': 2},
    );
    final combined = combineSources(_selected, [chart]);
    expect(combined.metadata['key'], 'D');
    expect(combined.sources.single.metadata['key'], 'D');
  });
  test(
    'same-song recording donors retain native identity without assigning it to the selection',
    () {
      final donor = _source(
        'musicbrainz',
        body: '',
        metadata: {
          'identityScope': 'song',
          'musicbrainzRecordingId': 'another-recording',
          'musicbrainzReleaseId': 'another-release',
          'isrcs': ['USAAA2400001'],
          'relationships': [
            {'type': 'performance', 'target': 'another-recording'},
          ],
          'customTag': 'retained-song-fact',
        },
        extra: {'metadataOnly': true},
      );
      final combined = combineSources(_selected, [_source('lyrics'), donor]);
      for (final field in [
        'musicbrainzRecordingId',
        'musicbrainzReleaseId',
        'isrcs',
        'relationships',
      ]) {
        expect(combined.metadata, isNot(contains(field)));
        expect(
          combined.sources
              .singleWhere((source) => source.id == donor.id)
              .metadata[field],
          donor.metadata[field],
        );
        expect(
          _claims(
            combined,
            'metadata.$field',
          ).every((claim) => claim['contextCompatible'] == false),
          isTrue,
        );
      }
      expect(combined.metadata['customTag'], 'retained-song-fact');
      expect(combined.selectedRecording?.identity, _selected.identity);
    },
  );

  test(
    'native chart consensus can supersede unresolved search setup without rejecting relative modes',
    () {
      const body =
          '[A]Amber lanterns [Bm]glow above the quiet water\n'
          '[F#m]Silver rain [D]returns beneath the evening sky[A]\n'
          '[A]Every window [Bm]keeps a little golden light\n'
          '[F#m]Morning carries [D]every dream back home[A]';
      for (final declaration in ['D', 'F#m']) {
        final observed = _candidate(
          'charts',
          id: 'unresolved',
          metadata: {'key': declaration},
        );
        final first = _source(
          'charts',
          body: body,
          extra: {
            'discoveryEvidence': {
              'searchCandidates': [
                {'candidate': observed.toJson()},
              ],
            },
          },
        );
        final combined = combineSources(_selected, [
          _source('lyrics'),
          first,
          _source('another-chart', body: body),
        ]);
        expect(
          combined.metadata['key'] ?? rankedChordKeyEstimate(combined),
          declaration == 'D' ? 'A' : 'F#m',
        );
        final claim = _claims(
          combined,
          'metadata.key',
        ).firstWhere((claim) => claim['sourceId'] == observed.identity);
        expect(claim['contextCompatible'], isTrue);
        if (declaration == 'D') {
          expect(
            claim['qualitySignals']['unresolvedSearchVsChartConsensus'],
            -8,
          );
        } else {
          expect(
            claim['qualitySignals'] ?? {},
            isNot(contains('unresolvedSearchVsChartConsensus')),
          );
        }
      }
    },
  );

  test(
    'song-scoped recording evidence offers a setup without claiming recording identity',
    () {
      final chart = _source(
        'chart',
        body:
            '[G]Amber lanterns [Am]glow above the quiet water\n'
            '[C]Silver rain [D]returns beneath the evening sky\n'
            '[G]Every window [Am]keeps a little golden light\n'
            '[C]Morning carries [D]every dream back home',
      );
      final analysis = _source(
        'analysis',
        body: '',
        extra: {
          'keyRecording': {
            'key': 'A',
            'ids': ['USAAA2400001'],
            'selectedIdentity': _selected.identity,
            'recordingScope': 'song',
          },
        },
      );
      final combined = combineSources(_selected, [
        _source('lyrics'),
        chart,
        analysis,
      ]);
      expect(combined.metadata['key'], 'A');
      expect(combined.metadata['capo'], 2);
      final reading = _claims(
        combined,
        'metadata.key',
      ).singleWhere((claim) => claim['providerId'] == 'recording-key-analysis');
      expect(reading['matchQuality'], 'sameSong');
      expect(reading['sourceScope'], 'song');
      final view = combined.sources.singleWhere(
        (source) => source.extra['recordingArrangement'] is Map,
      );
      expect(view.extra['recordingArrangement']['recordingScope'], 'song');
      expect(recordingCompatible(_selected, view), isFalse);
      expect(
        combined.sources
            .singleWhere((source) => source.id == chart.id)
            .metadata['capo'],
        isNull,
      );
    },
  );

  test(
    'archived compound payloads still expose separate arrangement views',
    () {
      final earlier = _source(
        'chart',
        metadata: {'capo': 1},
        body:
            '[Dm]Amber lanterns [F]glow above the quiet water\n'
            '[C]Silver rain [Bb]returns beneath the evening sky\n'
            'Version 2\nCapo VI\n'
            '[Am]Every window [C]keeps a little golden light\n'
            '[G]Morning carries [F]every dream back home',
      );
      final current = _source('chart', body: '');
      final combined = combineSources(_selected, [
        _source('lyrics'),
        earlier,
        current,
      ]);
      final parent = combined.sources.singleWhere(
        (source) =>
            source.extra['retainedPayloadView'] == true &&
            source.extra['hasArrangementViews'] == true,
      );
      expect(parent.body, earlier.body);
      final views = combined.sources.where(
        (source) => source.extra['parentSourceId'] == parent.id,
      );
      expect(
        views.map((source) => source.metadata['capo']),
        containsAll([1, 6]),
      );
      expect(combined.extra['chordSourceIds'], isNot(contains(parent.id)));
    },
  );

  test(
    'saved same-ID payload alternatives remain actionable on recombination',
    () {
      final earlier = _source(
        'chart',
        metadata: {'key': 'Em'},
        body:
            '[Em]Amber lanterns [C]glow above the quiet water\n'
            '[G]Silver rain [D]returns beneath the evening sky\n'
            '[Em]Every window [C]keeps a little golden light\n'
            '[G]Morning carries [D]every dream back home',
      );
      final later = _source('chart', body: '', metadata: {'language': 'en'});
      final first = combineSources(_selected, [
        _source('lyrics'),
        earlier,
        later,
      ]);
      expect(first.metadata['key'], 'Em');
      expect(first.hasChords, isTrue);
      final reopened = SongDocument.fromJson(first.toJson());
      final second = combineSources(_selected, reopened.sources);
      expect(second.metadata['key'], 'Em');
      expect(second.hasChords, isTrue);
      expect(second.body, first.body);
      expect(
        second.sources.any((source) => source.body == earlier.body),
        isTrue,
      );
      expect(
        second.sources
            .singleWhere((source) => source.id == later.id)
            .extra['sourceEvidenceSnapshots'],
        hasLength(2),
      );
      final third = combineSources(
        _selected,
        SongDocument.fromJson(second.toJson()).sources,
      );
      expect(
        third.sources.map((source) => source.id).toSet(),
        second.sources.map((source) => source.id).toSet(),
      );
    },
  );

  test('a recording setup competes with and preserves the published capo', () {
    final chart = _source(
      'chart',
      metadata: {'capo': 3},
      body:
          '[Em]Amber lanterns [G]glow above the quiet water\n'
          '[D]Silver rain [C]returns beneath the evening sky\n'
          '[Em]Every window [G]keeps a little golden light\n'
          '[D]Morning carries [C]every dream back home',
    );
    final analysis = _source(
      'analysis',
      body: '',
      extra: {
        'keyRecording': {
          'key': 'F#m',
          'ids': ['USAAA2400001'],
          'selectedIdentity': _selected.identity,
        },
      },
    );
    final combined = combineSources(_selected, [
      _source('lyrics'),
      chart,
      analysis,
    ]);
    expect(combined.metadata['key'], 'F#m');
    expect(combined.metadata['capo'], 2);
    final original = combined.sources.singleWhere(
      (source) => source.id == chart.id,
    );
    expect(original.body, chart.body);
    expect(original.metadata['capo'], 3);
    final derived = combined.sources.singleWhere(
      (source) => source.extra['recordingArrangement'] is Map,
    );
    expect(derived.candidate.id, chart.candidate.id);
    expect(derived.body, chart.body);
    expect(derived.metadata['capo'], 2);
    expect(derived.candidate.metadata['capo'], 2);
    expect(derived.extra['parentCandidate'], chart.candidate.toJson());
    expect(recordingCompatible(_selected, derived), isFalse);
    final capoDecision =
        (_ranking(combined)['appliedFields'] as Map)['metadata.capo'] as Map;
    expect(capoDecision['origin'], 'inferred');
    expect(combined.extra['chordSourceIds'], contains(derived.id));
    final restored = SongDocument.fromJson(combined.toJson());
    expect(
      restored.sources.map((source) => source.id),
      containsAll([chart.id, derived.id]),
    );
  });

  test(
    'conflicting recording signatures retain competing setups across recombination',
    () {
      final chart = _source(
        'chart',
        metadata: {'capo': 3},
        body:
            '[Em]Amber lanterns [G]glow above the quiet water\n'
            '[D]Silver rain [C]returns beneath the evening sky\n'
            '[Em]Every window [G]keeps a little golden light\n'
            '[D]Morning carries [C]every dream back home',
      );
      final analyses = [
        for (final key in ['F#m', 'Am'])
          _source(
            'analysis',
            id: key,
            body: '',
            extra: {
              'keyRecording': {
                'key': key,
                'ids': ['USAAA2400001'],
                'selectedIdentity': _selected.identity,
              },
            },
          ),
      ];
      final first = combineSources(_selected, [
        _source('lyrics'),
        chart,
        analyses.first,
      ]);
      final combined = combineSources(_selected, [
        ...SongDocument.fromJson(first.toJson()).sources,
        analyses.last,
      ]);
      expect(
        combined.sources
            .where((source) => source.extra['recordingArrangement'] is Map)
            .map((source) => source.metadata['capo'])
            .toSet(),
        {2, 5},
      );
      expect(
        combined.sources
            .singleWhere((source) => source.id == chart.id)
            .metadata['capo'],
        3,
      );
      expect(
        _claims(combined, 'metadata.key')
            .where((claim) => claim['providerId'] == 'recording-key-analysis')
            .map((claim) => claim['value']),
        containsAll(['F#m', 'Am']),
      );
    },
  );

  test('a search preview cannot shadow a later resolved chart', () {
    final resolved = _source(
      'charts',
      id: 'resolved',
      metadata: {'capo': 9},
      body:
          '[Em]Amber lanterns [G]glow above the quiet water\n'
          '[D]Silver rain [C]returns beneath the evening sky\n'
          '[Em]Every window [G]keeps a little golden light\n'
          '[D]Morning carries [C]every dream back home',
      extra: {
        'keyRecording': {
          'key': 'C#m',
          'ids': ['USAAA2400001'],
          'selectedIdentity': _selected.identity,
        },
      },
    );
    final alternate = _source(
      'charts',
      id: 'alternate',
      body:
          '[Dm]Amber lanterns [F]glow above the quiet water\n'
          '[C]Silver rain [Bb]returns beneath the evening sky\n'
          '[Dm]Every window [F]keeps a little golden light\n'
          '[C]Morning carries [Bb]every dream back home',
      extra: {
        'discoveryEvidence': {
          'searchCandidates': [
            {'candidate': resolved.candidate.toJson()},
          ],
        },
      },
    );
    for (final charts in [
      [alternate, resolved],
      [resolved, alternate],
    ]) {
      final combined = combineSources(_selected, [
        _source('lyrics'),
        ...charts,
      ]);
      expect(combined.metadata['key'], 'C#m');
      expect(combined.metadata['capo'], 9);
      expect(combined.extra['chordSourceIds'], contains(resolved.id));
      expect(combined.extra['chordSourceIds'], isNot(contains(alternate.id)));
      expect(
        combined.sources
            .singleWhere((source) => source.id == alternate.id)
            .extra['discoveryEvidence'],
        isNotNull,
      );
    }
  });

  test(
    'a ranked key with an agreeing source declaration is reported as sourced',
    () {
      final analysis = _source(
        'analysis-holder',
        body: '',
        extra: {
          'keyRecording': {
            'key': 'Em',
            'ids': ['USAAA2400001'],
            'source': 'ReccoBeats',
          },
        },
      );
      final chart = _source(
        'chart',
        body:
            '[Em]Amber [Am]lanterns [B7]glow [Em]above the quiet water\n'
            '[Am]Silver rain [B7]returns [Em]beneath the evening sky\n'
            '[Em]Every window [Am]keeps a [B7]little golden light\n'
            '[Em]Morning carries every dream back home',
      );
      final combined = combineSources(_selected, [
        _source('lyrics'),
        chart,
        analysis,
      ]);
      expect(combined.metadata['key'], 'Em');
      expect(combined.extra['keySourceIds'], contains(analysis.id));
      final decision =
          (_ranking(combined)['appliedFields'] as Map)['metadata.key'] as Map;
      expect(decision['origin'], 'provider');
      expect(decision['sourceId'], analysis.id);
      expect(decision['matchQuality'], 'sameSong');
    },
  );

  test('recording key evidence survives selection of another chart', () {
    final analysis = _source(
      'analysis-holder',
      body: '',
      extra: {
        'keyRecording': {
          'key': 'Em',
          'ids': ['USAAA2400001'],
          'source': 'ReccoBeats',
          'selectedIdentity': _selected.identity,
        },
      },
    );
    final chart = _source(
      'chart',
      body:
          '[Em]Amber lanterns [C]glow above the quiet water\n'
          '[G]Silver rain [D]returns beneath the evening sky\n'
          '[Em]Every window [C]keeps a little golden light\n'
          '[G]Morning carries [D]every dream back home',
    );
    final combined = combineSources(_selected, [
      _source('lyrics'),
      chart,
      analysis,
    ]);
    expect(combined.metadata['key'], 'Em');
    expect(combined.extra['keySourceIds'], contains(analysis.id));
    final recording = _claims(
      combined,
      'metadata.key',
    ).singleWhere((claim) => claim['providerId'] == 'recording-key-analysis');
    expect(recording['matchQuality'], 'sameRecording');
    expect(recording['origin'], 'provider');
    expect(combined.extra['chordSourceIds'], contains(chart.id));
  });

  test(
    'supported minor declaration can supersede an API relative-major reading',
    () {
      final chart = _source(
        'chart',
        metadata: {'key': 'Am'},
        body:
            '[Am]Amber lanterns [F]glow above the quiet water\n'
            '[C]Silver rain [G]returns beneath the evening sky\n'
            '[Am]Every window [F]keeps a little golden light\n'
            '[C]Morning carries [G]every dream back home',
      );
      final analysis = _source(
        'analysis-holder',
        body: '',
        extra: {
          'keyRecording': {
            'key': 'C',
            'ids': ['USAAA2400001'],
            'source': 'ReccoBeats',
            'selectedIdentity': _selected.identity,
          },
        },
      );
      final combined = combineSources(_selected, [
        _source('lyrics'),
        chart,
        analysis,
      ]);
      expect(combined.metadata['key'], 'Am');
      final reading = _claims(
        combined,
        'metadata.key',
      ).singleWhere((claim) => claim['providerId'] == 'recording-key-analysis');
      expect(reading['value'], 'C');
      expect(reading['qualitySignals']['relativeModeConflict'], -20);
      expect(
        combined.sources
            .singleWhere((source) => source.id == analysis.id)
            .extra['keyRecording']['key'],
        'C',
      );
    },
  );

  test(
    'chart search metadata can match a title article without a full fetch',
    () {
      final observation = _candidate(
        'chart-provider',
        id: 'known-key',
        title: 'The Lantern Song',
        metadata: {'key': 'Em'},
      );
      const unrelated = SongCandidate(
        providerId: 'chart-provider',
        id: 'wrong-artist',
        title: 'The Lantern Song',
        artist: 'Another Artist',
        metadata: {'key': 'F#'},
      );
      final chart = _source(
        'chart-provider',
        title: 'The Lantern Song',
        body:
            '[Em]Amber lanterns [C]glow above the quiet water\n'
            '[G]Silver rain [D]returns beneath the evening sky\n'
            '[Em]Every window [C]keeps a little golden light\n'
            '[G]Morning carries [D]every dream back home',
        extra: {
          'requiresLyricsAgreement': true,
          'discoveryEvidence': {
            'capabilities': ['chords'],
            'searchCandidates': [
              {'candidate': observation.toJson(), 'state': 'eligible'},
              {'candidate': unrelated.toJson(), 'state': 'returned'},
            ],
          },
        },
      );
      final combined = combineSources(_selected, [_source('lyrics'), chart]);
      expect(combined.metadata['key'], 'Em');
      expect(combined.extra['keySourceIds'], contains(observation.identity));
      expect(
        _claims(combined, 'metadata.key').singleWhere(
          (claim) => claim['sourceId'] == unrelated.identity,
        )['contextCompatible'],
        isFalse,
      );
    },
  );

  test('a longer chart cannot mask its negative key-consistency evidence', () {
    final good = _source(
      'reliable-chart',
      body:
          '[G]Amber lanterns [B]glow above [C]the quiet [Cm]water\n'
          '[G]Silver rain [B]returns beneath [C]the evening [Cm]sky',
      metadata: {'key': 'G'},
      extra: {'keyConsensus': true},
    );
    final earlierOutlier = _source(
      'long-outlier',
      body:
          '[F]Amber lanterns [A]glow above [Bb]the quiet [Bbm]water\n'
          '[F]Silver rain [A]returns beneath [Bb]the evening [Bbm]sky\n'
          '[F]Every window [A]keeps a [Bb]little golden [Bbm]light\n'
          '[F]Morning carries [A]every [Bb]dream back [Bbm]home',
    );
    final outlier = earlierOutlier.copyWith(
      extra: {
        'keyConsensus': false,
        'discoveryEvidence': {
          'acceptedPayloads': [earlierOutlier.toJson()],
        },
      },
    );
    for (final sources in [
      [good, outlier],
      [outlier, good],
    ]) {
      final combined = combineSources(_selected, [
        _source('lyrics'),
        ...sources,
      ]);
      expect(combined.metadata['key'], 'G');
      expect(combined.body, contains('[G]Amber'));
      expect(combined.body, isNot(contains('[F]')));
      expect(combined.sources.map((source) => source.id), contains(outlier.id));
      final raw =
          combined.sources
                  .singleWhere((source) => source.id == outlier.id)
                  .extra['discoveryEvidence']
              as Map;
      expect(
        (raw['acceptedPayloads'] as List).single.containsKey('keyConsensus'),
        isFalse,
      );
    }
  });

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
