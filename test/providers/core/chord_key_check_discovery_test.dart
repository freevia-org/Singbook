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
