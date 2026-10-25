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

String _chart(List<String> chords) => [
  for (var i = 0; i < _lines.length; i++)
    '[${chords[(i * 2) % chords.length]}]${_lines[i].split(' ').take(3).join(' ')} '
        '[${chords[(i * 2 + 1) % chords.length]}]${_lines[i].split(' ').skip(3).join(' ')}',
].join('\n');

final _inG = _chart(['G', 'C', 'Em', 'A', 'Bm', 'D', 'C', 'G']);
final _inE = _chart(['E', 'A', 'C#m', 'F#', 'G#m', 'B', 'A', 'E']);
final _inE2 = _chart(['E', 'A', 'C#m7', 'F#7', 'G#m', 'B7', 'A', 'E']);

const _selection = SongCandidate(
  providerId: 'lyrics',
  id: 'song',
  title: 'Harbor Song',
  artist: 'Test Artist',
);

class _Provider implements LyricsProvider {
  _Provider(this.id, this.charts, {this.chords = true});

  final String id;
  final Map<String, String> charts;
  final bool chords;
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
    return SourceResult(candidate: candidate, body: charts[candidate.id]!);
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
}
