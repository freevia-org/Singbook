import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

// Invented lyrics; the chord progressions mirror a chart in G and the same
// chart in E.
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
final _lyrics = _lines.join('\n');
// A cadential progression the key estimator commits to (E).
final _clearE = _chart(['E', 'A', 'B7', 'E', 'C#m', 'A', 'B7', 'E']);

const _selected = SongCandidate(
  providerId: 'lyrics',
  id: 'song',
  title: 'Harbor Song',
  artist: 'Test Artist',
);

SourceResult _source(
  String providerId,
  String body, [
  JsonMap extra = const {},
]) => SourceResult(
  candidate: SongCandidate(
    providerId: providerId,
    id: providerId,
    title: 'Harbor Song',
    artist: 'Test Artist',
  ),
  body: body,
  matchKind: MatchKind.sameSong,
  extra: extra,
);

List<String> _chords(String body) => [
  for (final line in parseArrangement(body))
    for (final anchor in line.chords) anchor.chord,
];

void main() {
  test('detects a chart transposed from another', () {
    expect(chordTransposition(_inG, _inG), 0);
    expect(chordTransposition(_inG, _inE), 9);
    expect(chordTransposition(_inE, _inG), 3);
    expect(chordTransposition(_inG, _lyrics), isNull);
  });

  test('finds the majority key, counting copied charts once', () {
    final majority = chordKeyMajority([
      _inG,
      _inE,
      _inE.replaceAll('B]', 'B7]'),
      _inG,
    ]);
    expect(majority, [9, 0, 0, 9]);
    // A G chart and its copy against one E chart is a tie of distinct charts.
    expect(chordKeyMajority([_inG, _inE, _inG]), isNull);
  });

  test('a plurality without a majority moves nothing', () {
    final inA = transposeBody(_inG, 2), inD = transposeBody(_inG, 7);
    final inE2 = _inE.replaceAll('B]', 'B7]');
    // 2 of 4 distinct charts in E.
    expect(chordKeyMajority([_inG, _inE, inE2, inA]), isNull);
    // 2 of 5 distinct charts in E.
    expect(chordKeyMajority([_inG, _inE, inE2, inA, inD]), isNull);
    // 3 of 4 is a majority.
    final inE3 = _inE.replaceAll('A]', 'A7]');
    expect(chordKeyMajority([_inG, _inE, inE2, inE3]), [9, 0, 0, 0]);
  });

  test('combining moves a transposed chart into the majority key', () {
    final doc = combineSources(_selected, [
      _source('lyrics', _lyrics),
      _source('ug', _inG, {
        'keyConsensus': false,
        'keyShift': 9,
        'keyEstimate': 'E',
      }),
    ]);
    expect(_chords(doc.body).take(6), ['E', 'A', 'C#m', 'F#', 'G#m', 'B']);
    expect(doc.extra['chordKeyShifts'], {'ug:ug': 9});
    expect(checkedChordKeyEstimate(doc), 'E');
    // The saved source keeps its published chart.
    expect(doc.sources.firstWhere((s) => s.id == 'ug:ug').body, _inG);
    // An edited chart no longer carries the estimate.
    expect(
      checkedChordKeyEstimate(doc.copyWith(body: '${doc.body}\n')),
      isNull,
    );
  });

  test('majority-key charts are preferred over transposed ones', () {
    final doc = combineSources(_selected, [
      _source('lyrics', _lyrics),
      _source('ug', _inG, {'keyConsensus': false}),
      _source('songsterr', _inE, {'keyConsensus': true}),
    ]);
    expect(_chords(doc.body).first, 'E');
  });

  SourceResult labelled(String body, String key, {JsonMap extra = const {}}) =>
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'ug',
          title: 'Harbor Song',
          artist: 'Test Artist',
        ),
        body: body,
        matchKind: MatchKind.sameSong,
        metadata: {'key': key},
        extra: extra,
      );

  test('a declared key that fits its chords moves with them', () {
    expect(declaredKeyAfterShift(_inG, 'G', null, 9), 'E');
    final doc = combineSources(_selected, [
      _source('lyrics', _lyrics),
      labelled(_inG, 'G', extra: const {'keyConsensus': false, 'keyShift': 9}),
    ]);
    expect(doc.metadata['key'], 'E');
  });

  test('a label contradicting its chords can settle the key', () {
    final inC = transposeBody(_clearE, 8);
    // The C chart says it is in E; with the E chart that is a majority.
    expect(chordKeyMajority([_clearE, inC], declaredKeys: [null, 'E']), [0, 4]);
    // Its label already names the majority key, so it is kept as is.
    expect(declaredKeyAfterShift(inC, 'E', null, 4), 'E');
    final doc = combineSources(_selected, [
      _source('lyrics', _lyrics),
      labelled(inC, 'E', extra: const {'keyConsensus': false, 'keyShift': 4}),
    ]);
    expect(_chords(doc.body).first, 'E');
    expect(doc.metadata['key'], 'E');
  });

  test('a contradicting label without a correction names no key', () {
    final inC = transposeBody(_clearE, 8);
    expect(declaredKeyFitsChords(inC, 'E', null), isFalse);
    final doc = combineSources(_selected, [
      _source('lyrics', _lyrics),
      labelled(inC, 'E'),
    ]);
    expect(doc.metadata.containsKey('key'), isFalse);
  });

  test('charts are compared by sounding key, capo included', () {
    final inBm = transposeBody(_inG, 2), shapesWithCapo = _inG;
    // G shapes with capo 2 sound like the chart written in A.
    expect(
      chordKeyMajority(
        [inBm, shapesWithCapo, transposeBody(inBm, 0).replaceAll('A]', 'A7]')],
        capos: [null, 2, null],
      ),
      isNull,
    );
    expect(chordKeyMajority([inBm, shapesWithCapo], capos: [null, 2]), isNull);
  });

  test('an explicit version choice keeps its published key', () {
    final source = labelled(transposeBody(_clearE, 8), 'E');
    final doc = combineSources(
      _selected,
      [_source('lyrics', _lyrics), source],
      preferredSourceId: 'ug:ug',
      allowRejectedPreferredSource: true,
    );
    expect(doc.metadata['key'], 'E');
  });

  test('an explicit version choice keeps the published chart', () {
    final doc = combineSources(
      _selected,
      [
        _source('lyrics', _lyrics),
        _source('ug', _inG, {'keyConsensus': false, 'keyShift': 9}),
      ],
      preferredSourceId: 'ug:ug',
      allowRejectedPreferredSource: true,
    );
    expect(_chords(doc.body).first, 'G');
    expect(doc.extra.containsKey('chordKeyShifts'), isFalse);
  });
}
