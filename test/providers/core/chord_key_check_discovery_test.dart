import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/core/recording_key.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

// Invented lyrics and chords only.
const _lines = [
  'Paper lanterns drifting over quiet harbor water',
  'Every window glowing softly as the evening falls',
  'Someone hums a tune along the winding river road',
  'Bells are ringing gently down the empty market halls',
  'Morning carries salt and cedar through the open door',
  'Little boats are waiting where the gulls begin to call',
];

String _chart(List<String> chords) => [
  for (var i = 0; i < _lines.length; i++)
    '[${chords[(i * 2) % chords.length]}]${_lines[i].split(' ').take(3).join(' ')} '
        '[${chords[(i * 2 + 1) % chords.length]}]${_lines[i].split(' ').skip(3).join(' ')}',
].join('\n');

final _inG = _chart(['G', 'C', 'Em', 'A', 'Bm', 'D', 'C', 'G']);
final _inE = _chart(['E', 'A', 'C#m', 'F#', 'G#m', 'B', 'A', 'E']);
final _inE2 = _chart(['E', 'A', 'C#m7', 'F#7', 'G#m', 'B7', 'A', 'E']);

// The same E progression over a different song's words, under the same
// title and artist.
const _otherLines = [
  'Copper kettles rattle on a crowded kitchen stove',
  'Grandma counts the spoons beneath a flickering lamp',
  'Thunder rolls along the hills behind the orchard',
  'Muddy boots are drying on the porch beside the ramp',
  'Crickets argue loudly in the tall September grass',
  'Somebody forgot the bicycle out in the damp',
];
String _otherChart(List<String> chords) => [
  for (var i = 0; i < _otherLines.length; i++)
    '[${chords[i % chords.length]}]${_otherLines[i]}',
].join('\n');

const _selection = SongCandidate(
  providerId: 'lyrics',
  id: 'song',
  title: 'Harbor Song',
  artist: 'Test Artist',
);

class _Provider implements LyricsProvider {
  _Provider(
    this.id,
    this.charts, {
    this.chords = true,
    this.onResolve,
    this.labels = const {},
    this.capos = const {},
  });

  final String id;
  final Map<String, String> charts;
  final bool chords;
  final Map<String, String> labels;
  final Map<String, int> capos;
  final void Function(String chartId)? onResolve;
  final resolved = <String>[];

  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: id,
    name: id,
    capabilities: {'lyrics', if (chords) 'chords'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [
    for (final chartId in charts.keys)
      SongCandidate(
        providerId: id,
        id: chartId,
        title: 'Harbor Song',
        artist: 'Test Artist',
      ),
  ];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolved.add(candidate.id);
    onResolve?.call(candidate.id);
    return SourceResult(
      candidate: candidate,
      body: charts[candidate.id]!,
      metadata: {'key': ?labels[candidate.id], 'capo': ?capos[candidate.id]},
    );
  }
}

class _MetadataProvider implements LyricsProvider {
  _MetadataProvider(
    this.id, {
    this.version = 'album version',
    this.duration = 262,
  });
  final String id, version;
  final double duration;
  @override
  ProviderDefinition get definition =>
      ProviderDefinition(id: id, name: id, capabilities: {'metadata'});
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [];
  @override
  Future<SourceResult> resolve(
    SongCandidate selection, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: SongCandidate(
      providerId: id,
      id: 'album-recording',
      title: selection.title,
      artist: selection.artist,
      album: 'Harbor Album',
      durationSeconds: duration,
      metadata: {'identityScope': 'recording', 'version': version},
    ),
    body: '',
    metadata: {
      'isrcs': ['USAAA2400001'],
      'version': version,
    },
    extra: {'metadataOnly': true},
  );
}

void main() {
  test('disagreeing charts are double checked and marked by key', () async {
    final ug = _Provider('ug', {
      'a-in-g': _inG,
      'b-in-e': _inE,
      'c-in-e': _inE2,
    });
    final songsterr = _Provider('songsterr', {'s-in-e': _inE});
    final results = await SourceDiscoveryService([
      _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
      ug,
      songsterr,
    ]).discover(_selection);

    final chartG = results.firstWhere((r) => r.candidate.id == 'a-in-g');
    final chartE = results.firstWhere((r) => r.candidate.id == 's-in-e');
    expect(chartG.extra['keyConsensus'], isFalse);
    expect(chartG.extra['keyShift'], 9);
    expect(chartE.extra['keyConsensus'], isTrue);
    expect(chartE.extra.containsKey('keyShift'), isFalse);
    // Extra charts were only votes: they are not offered as versions.
    expect(results.where((r) => r.candidate.id == 'b-in-e'), isEmpty);
    expect(ug.resolved, containsAll(['a-in-g', 'b-in-e', 'c-in-e']));
  });

  test('the same shapes with another capo are double checked', () async {
    final g = _chart(['G', 'C', 'D7', 'G', 'Em', 'C', 'D7', 'G']);
    final ug = _Provider('ug', {'a': g, 'b': g.replaceAll('D7]', 'D]')});
    final results = await SourceDiscoveryService([
      _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
      ug,
      _Provider('songsterr', {'s': g}, capos: {'s': 2}),
    ]).discover(_selection);
    expect(ug.resolved, contains('b'));
    // G shapes with capo 2 sound in A; the two G charts move it down.
    expect(
      results
          .firstWhere((r) => r.candidate.providerId == 'songsterr')
          .extra['keyShift'],
      10,
    );
  });

  test('agreeing charts need no double check', () async {
    final ug = _Provider('ug', {'b-in-e': _inE, 'c-in-e': _inE2});
    final songsterr = _Provider('songsterr', {'s-in-e': _inE});
    final results = await SourceDiscoveryService([
      _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
      ug,
      songsterr,
    ]).discover(_selection);

    expect(ug.resolved, ['b-in-e']);
    expect(results.where((r) => r.extra.containsKey('keyConsensus')), isEmpty);
  });

  test('charts with unrelated lyrics cannot vote', () async {
    final ug = _Provider('ug', {
      'a-in-g': _inG,
      'x-other-e': _otherChart(['E', 'A', 'C#m', 'B']),
      'y-other-e': _otherChart(['E', 'A7', 'C#m7', 'B7']),
    });
    final results = await SourceDiscoveryService([
      _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
      ug,
      _Provider('songsterr', {'s-in-e': _inE}),
    ]).discover(_selection);

    // One accepted chart in each key and no valid votes: no majority.
    expect(ug.resolved, containsAll(['x-other-e', 'y-other-e']));
    expect(results.where((r) => r.extra.containsKey('keyConsensus')), isEmpty);
  });

  test('a provider disabled during the key check drops out', () async {
    final ugCancel = CancellationToken();
    final ug = _Provider(
      'ug',
      {'a-in-g': _inG, 'b-in-e': _inE, 'c-in-e': _inE2},
      onResolve: (id) {
        if (id != 'a-in-g') ugCancel.cancel();
      },
    );
    final results = await SourceDiscoveryService([
      _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
      ug,
      _Provider('songsterr', {'s-in-e': _inE}),
    ]).discover(_selection, providerCancellation: {'ug': ugCancel});

    expect(results.where((r) => r.extra.containsKey('keyConsensus')), isEmpty);
  });

  test('cancelling during the key check stops discovery', () async {
    final cancel = CancellationToken();
    final ug = _Provider(
      'ug',
      {'a-in-g': _inG, 'b-in-e': _inE, 'c-in-e': _inE2},
      onResolve: (id) {
        if (id != 'a-in-g') cancel.cancel();
      },
    );
    await expectLater(
      SourceDiscoveryService([
        _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
        ug,
        _Provider('songsterr', {'s-in-e': _inE}),
      ]).discover(_selection, cancel: cancel),
      throwsA(
        isA<ProviderException>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
  });

  group('recording key', () {
    // A cadential progression the key estimator commits to, in G.
    final clearG = _chart(['G', 'C', 'D7', 'G', 'Em', 'C', 'D7', 'G']);
    const recorded = SongCandidate(
      providerId: 'lyrics',
      id: 'song',
      title: 'Harbor Song',
      artist: 'Test Artist',
      metadata: {
        'mediaLinks': [
          {
            'kind': 'audio',
            'url': 'https://open.spotify.com/track/1kgdslQYmeTR4thk9whoRw',
          },
        ],
      },
    );
    RecordingKeyService service(
      int key,
      List<Uri> requests,
    ) => RecordingKeyService(
      ProviderTransport(
        hostInterval: Duration.zero,
        client: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            jsonEncode({
              'content': [
                {
                  'isrc': 'USRE19100010',
                  'href':
                      'https://open.spotify.com/track/1kgdslQYmeTR4thk9whoRw',
                  'key': key,
                  'mode': 1,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
    List<SourceResult> chartsOf(List<SourceResult> results) =>
        results.where((r) => r.hasChords).toList();

    const fallbackSelection = SongCandidate(
      providerId: 'lyrics',
      id: 'song',
      title: 'Harbor Song',
      artist: 'Test Artist',
      metadata: {
        'album': 'Harbor Album',
        'durationSeconds': 262,
        'mediaLinks': [
          {
            'kind': 'audio',
            'url': 'https://open.spotify.com/track/1kgdslQYmeTR4thk9whoRw',
          },
        ],
      },
    );
    RecordingKeyService fallbackService(
      List<Uri> requests, {
      bool exactWorks = false,
      bool failExact = false,
      int fallbackKey = 7,
      void Function()? onFallback,
    }) => RecordingKeyService(
      ProviderTransport(
        hostInterval: Duration.zero,
        client: MockClient((request) async {
          requests.add(request.url);
          final fallback = request.url.queryParameters['ids'] == 'USAAA2400001';
          if (fallback) onFallback?.call();
          return http.Response(
            jsonEncode({
              'content': [
                if (fallback || exactWorks)
                  {
                    'isrc': fallback ? 'USAAA2400001' : 'USRE19100010',
                    if (!fallback)
                      'href':
                          'https://open.spotify.com/track/1kgdslQYmeTR4thk9whoRw',
                    'key': fallback ? fallbackKey : 7,
                    'mode': 1,
                  },
              ],
            }),
            !fallback && failExact ? 503 : 200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
    List<LyricsProvider> fallbackProviders({
      bool wrongEdition = false,
      double duration = 262,
    }) => [
      _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
      _Provider('ug', {'g': clearG}),
      _MetadataProvider(
        'metadata',
        version: wrongEdition ? 'live' : 'album version',
        duration: duration,
      ),
    ];
    test(
      'empty exact analysis falls back without claiming recording identity',
      () async {
        final requests = <Uri>[];
        final results = await SourceDiscoveryService(
          fallbackProviders(),
          recordingKeys: fallbackService(requests),
        ).discover(fallbackSelection);
        expect(requests.map((uri) => uri.queryParameters['ids']), [
          '1kgdslQYmeTR4thk9whoRw',
          'USAAA2400001',
        ]);
        final chart = chartsOf(results).single;
        final evidence = chart.extra['keyRecording'] as Map;
        expect(evidence['key'], 'G');
        expect(evidence['recordingScope'], 'song');
        expect(evidence, isNot(contains('selectedIdentity')));
        expect(evidence['identifierSourceIds'], ['metadata:album-recording']);
        expect(evidence['identifierProviders'], ['metadata']);
        expect(chart.extra, isNot(contains('keyShift')));
      },
    );
    test(
      'song-scoped analysis is retained without authorizing a chart shift',
      () async {
        final requests = <Uri>[];
        final results = await SourceDiscoveryService(
          [
            _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
            _Provider('ug', {'g': clearG}, labels: {'g': 'C'}),
            _MetadataProvider('metadata'),
          ],
          recordingKeys: fallbackService(requests, fallbackKey: 0),
        ).discover(fallbackSelection);
        final chart = chartsOf(results).single;
        expect(chart.extra['keyRecording'], containsPair('key', 'C'));
        expect(
          chart.extra['keyRecording'],
          containsPair('recordingScope', 'song'),
        );
        expect(chart.extra, isNot(contains('keyShift')));
      },
    );
    test('a conflicting edition cannot supply fallback identifiers', () async {
      final requests = <Uri>[];
      final results =
          await SourceDiscoveryService(
            fallbackProviders(wrongEdition: true),
            recordingKeys: fallbackService(requests),
          ).discover(
            SongCandidate(
              providerId: fallbackSelection.providerId,
              id: fallbackSelection.id,
              title: fallbackSelection.title,
              artist: fallbackSelection.artist,
              metadata: {...fallbackSelection.metadata, 'version': 'studio'},
            ),
          );
      expect(requests.map((uri) => uri.queryParameters['ids']), [
        '1kgdslQYmeTR4thk9whoRw',
      ]);
      expect(chartsOf(results).single.extra, isNot(contains('keyRecording')));
    });
    test(
      'a different length recording cannot supply fallback identifiers',
      () async {
        final requests = <Uri>[];
        final results = await SourceDiscoveryService(
          fallbackProviders(duration: 225),
          recordingKeys: fallbackService(requests),
        ).discover(fallbackSelection);
        expect(requests.map((uri) => uri.queryParameters['ids']), [
          '1kgdslQYmeTR4thk9whoRw',
        ]);
        expect(chartsOf(results).single.extra, isNot(contains('keyRecording')));
        expect(
          results.any((source) => source.candidate.providerId == 'metadata'),
          isTrue,
          reason:
              'The alternative recording metadata remains evidence even when it cannot identify this analysis.',
        );
      },
    );
    test(
      'an exact analysis prevents fallback and retains recording scope',
      () async {
        final requests = <Uri>[];
        final results = await SourceDiscoveryService(
          fallbackProviders(),
          recordingKeys: fallbackService(requests, exactWorks: true),
        ).discover(fallbackSelection);
        expect(requests, hasLength(1));
        final evidence = chartsOf(results).single.extra['keyRecording'] as Map;
        expect(evidence['recordingScope'], 'recording');
        expect(evidence['selectedIdentity'], fallbackSelection.identity);
      },
    );
    test(
      'a failed exact request does not trigger a fallback request',
      () async {
        final requests = <Uri>[];
        await SourceDiscoveryService(
          fallbackProviders(),
          recordingKeys: fallbackService(requests, failExact: true),
        ).discover(fallbackSelection);
        expect(requests, isNotEmpty);
        expect(
          requests.every(
            (uri) => uri.queryParameters['ids'] == '1kgdslQYmeTR4thk9whoRw',
          ),
          isTrue,
        );
      },
    );
    test(
      'disabling a fallback identifier provider removes its analysis',
      () async {
        final requests = <Uri>[];
        final disabled = CancellationToken();
        final results =
            await SourceDiscoveryService(
              fallbackProviders(),
              recordingKeys: fallbackService(
                requests,
                onFallback: disabled.cancel,
              ),
            ).discover(
              fallbackSelection,
              providerCancellation: {'metadata': disabled},
            );
        expect(requests, hasLength(2));
        expect(chartsOf(results).single.extra, isNot(contains('keyRecording')));
      },
    );

    test('a recording key agreeing with a label moves the chart', () async {
      final requests = <Uri>[];
      final results = await SourceDiscoveryService([
        _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
        _Provider('ug', {'g': clearG}, labels: {'g': 'C'}),
      ], recordingKeys: service(0, requests)).discover(recorded);

      final chart = chartsOf(results).single;
      expect(chart.extra['keyShift'], 5);
      expect(chart.extra['keyRecording'], containsPair('key', 'C'));
      expect(requests.single.queryParameters['ids'], '1kgdslQYmeTR4thk9whoRw');
    });

    test('a recording key alone does not move a chart', () async {
      final results = await SourceDiscoveryService([
        _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
        _Provider('ug', {'g': clearG}),
      ], recordingKeys: service(0, [])).discover(recorded);

      expect(chartsOf(results).single.extra.containsKey('keyShift'), isFalse);
    });

    test('a provider disabled during the lookup loses its recording', () async {
      final disabled = CancellationToken();
      final recording = RecordingKeyService(
        ProviderTransport(
          hostInterval: Duration.zero,
          client: MockClient((request) async {
            disabled.cancel();
            return http.Response(
              jsonEncode({
                'content': [
                  {
                    'isrc': 'USRE19100010',
                    'href':
                        'https://open.spotify.com/track/1kgdslQYmeTR4thk9whoRw',
                    'key': 0,
                    'mode': 1,
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      final results = await SourceDiscoveryService(
        [
          _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
          _Provider('ug', {'g': clearG}, labels: {'g': 'C'}),
        ],
        recordingKeys: recording,
      ).discover(recorded, providerCancellation: {'lyrics': disabled});
      final chart = chartsOf(results).single;
      expect(chart.extra.containsKey('keyShift'), isFalse);
      expect(chart.extra.containsKey('keyRecording'), isFalse);
    });

    test(
      'a provider disabled during the chart lookups loses its recording',
      () async {
        final disabled = CancellationToken();
        final results = await SourceDiscoveryService(
          [
            _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
            _Provider(
              'ug',
              {'g': clearG, 'g2': clearG},
              labels: {'g': 'C'},
              onResolve: (id) {
                if (id == 'g2') disabled.cancel();
              },
            ),
          ],
          recordingKeys: service(0, []),
        ).discover(recorded, providerCancellation: {'lyrics': disabled});
        final chart = chartsOf(results).single;
        expect(chart.extra.containsKey('keyShift'), isFalse);
        expect(chart.extra.containsKey('keyRecording'), isFalse);
      },
    );

    test('an agreeing recording key is kept for naming the key', () async {
      final results = await SourceDiscoveryService([
        _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
        _Provider('ug', {'g': clearG}),
      ], recordingKeys: service(7, [])).discover(recorded);
      final chart = chartsOf(results).single;
      expect(chart.extra['keyRecording'], containsPair('key', 'G'));
      expect(chart.extra.containsKey('keyConsensus'), isFalse);
    });

    test('without the service no recording key is requested', () async {
      final results = await SourceDiscoveryService([
        _Provider('lyrics', {'song': _lines.join('\n')}, chords: false),
        _Provider('ug', {'g': clearG}, labels: {'g': 'C'}),
      ]).discover(recorded);
      // The contradicting label alone ties with the chart: nothing moves.
      expect(chartsOf(results).single.extra.containsKey('keyShift'), isFalse);
    });
  });
}
