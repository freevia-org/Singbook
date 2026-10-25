import 'package:flutter_test/flutter_test.dart';
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

const _selection = SongCandidate(
  providerId: 'lyrics',
  id: 'song',
  title: 'Harbor Song',
  artist: 'Test Artist',
);

class _Provider implements LyricsProvider {
  _Provider(this.id, this.body, {this.chords = true});
  final String id, body;
  final bool chords;

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
    SongCandidate(
      providerId: id,
      id: '$id-1',
      title: 'Harbor Song',
      artist: 'Test Artist',
    ),
  ];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(candidate: candidate, body: body);
}

Future<SourceResult> _chartResult(String chart) async {
  final results = await SourceDiscoveryService([
    _Provider('lyrics', _lines.join('\n'), chords: false),
    _Provider('ug', chart),
  ]).discover(_selection);
  return results.firstWhere((r) => r.candidate.providerId == 'ug');
}

void main() {
  test('a chart with notes among the song lines is a chord donor', () async {
    final chart = [
      'Capo 2, standard tuning, strumming D DU UDU',
      'e|--0--2--3--2--0--|',
      'http://tabs.example/harbor-song-chords.html',
      'This one sounds better if you skip the intro and alternate',
      for (final line in _lines)
        '[G]${line.split(' ').take(3).join(' ')} '
            '[D]${line.split(' ').skip(3).join(' ')}',
      'Solo x2 then repeat chorus, ending on G',
    ].join('\n');
    final result = await _chartResult(chart);
    expect(result.matchKind, MatchKind.sameSong);
    expect(result.extra['partialLyrics'], isTrue);
  });

  test('another song under the same title is still rejected', () async {
    final chart = [
      '[G]Copper kettles rattle on a crowded kitchen stove',
      '[D]Grandma counts the spoons beneath a flickering lamp',
      '[G]Thunder rolls along the hills behind the orchard',
      '[D]Muddy boots are drying on the porch beside the ramp',
      '[G]Crickets argue loudly in the tall September grass',
    ].join('\n');
    final result = await _chartResult(chart);
    expect(result.matchKind, MatchKind.rejected);
  });
}
