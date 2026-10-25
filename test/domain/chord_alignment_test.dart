import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

// Invented lyrics and chords only.
const _verse = [
  'Someone hums a tune along the winding river road',
  'Bells are ringing gently down the empty market halls',
];
const _chorus = 'Paper lanterns drifting over quiet harbor water';

const _selected = SongCandidate(
  providerId: 'lyrics',
  id: 's',
  title: 'Harbor Song',
  artist: 'Test Artist',
);

SongDocument _combine(String lyrics, String chart) =>
    combineSources(_selected, [
      SourceResult(
        candidate: _selected,
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'u',
          title: 'Harbor Song',
          artist: 'Test Artist',
        ),
        body: chart,
        matchKind: MatchKind.sameSong,
        extra: const {'partialLyrics': true},
      ),
    ]);

Map<String, List<String>> _chordsByLine(String body) => {
  for (final line in parseArrangement(body))
    if (line.text.trim().isNotEmpty && !line.directive)
      line.text: [for (final chord in line.chords) chord.chord],
};

void main() {
  test('a line worded slightly differently still gets its chords', () {
    final doc = _combine(
      [..._verse, _chorus].join('\n'),
      [
        '[G]Someone hums a [C]tune along the river road',
        '[Em]Bells are ringing [D]gently down the empty market halls',
        '[C]Paper lanterns [G]drifting over quiet harbor water',
      ].join('\n'),
    );
    final chords = _chordsByLine(doc.body);
    expect(chords[_verse[0]], ['G', 'C']);
    expect(chords[_verse[1]], ['Em', 'D']);
    // The chord stays on its word although a word is missing in the chart.
    final first = parseArrangement(
      doc.body,
    ).firstWhere((line) => line.text == _verse[0]);
    expect(first.chords[1].offset, _verse[0].indexOf('tune'));
  });

  test('a chorus written once fills its repeats, backing vocals included', () {
    final doc = _combine(
      [
        _verse[0],
        _chorus,
        '',
        _verse[1],
        '$_chorus (oh quiet water)',
      ].join('\n'),
      [
        '[G]Someone hums a tune along the [C]winding river road',
        '[C]Paper lanterns [G]drifting over quiet harbor water',
      ].join('\n'),
    );
    final chords = _chordsByLine(doc.body);
    expect(chords[_chorus], ['C', 'G']);
    expect(chords['$_chorus (oh quiet water)'], ['C', 'G']);
  });

  test('equally close chart lines with different chords place nothing', () {
    final doc = _combine(
      ['Lanterns drift over the harbor tonight', ..._verse].join('\n'),
      [
        '[G]Lanterns drift over the harbor today',
        '[D]Lanterns drift over the harbor always',
        '[G]Someone hums a tune along the [C]winding river road',
      ].join('\n'),
    );
    expect(
      _chordsByLine(doc.body)['Lanterns drift over the harbor tonight'],
      isEmpty,
    );
  });
}
