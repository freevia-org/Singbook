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
// Lyric lines no chart writes, so the lyrics stay the combined text.
const _tail = [
  'Morning carries salt and cedar through the open door',
  'Little boats are waiting where the gulls begin to call',
];

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

  test('a chart line joining two lyric lines splits its chords', () {
    const lyrics = [
      'Paper lanterns drifting over',
      'quiet harbor water tonight oh oh',
      'Bells are ringing gently',
      'down the empty market halls',
    ];
    final doc = _combine(
      [...lyrics, ..._tail].join('\n'),
      [
        '[G]Paper lanterns drifting [C]over the quiet harbor [D]water tonight',
        '[Em]Bells are ringing [C]gently down all the empty [G]market halls',
      ].join('\n'),
    );
    final chords = _chordsByLine(doc.body);
    expect(chords[lyrics[0]], ['G', 'C']);
    // Ad-libs the chart does not write do not stop the match.
    expect(chords[lyrics[1]], ['D']);
    expect(chords[lyrics[2]], ['Em', 'C']);
    expect(chords[lyrics[3]], ['G']);
  });

  test('chords keep their order when the chart has an extra word', () {
    const line = 'Someone hums a tune along the river road';
    final doc = _combine(
      [line, ..._verse.skip(1), ..._tail].join('\n'),
      [
        '[G]Someone hums a tune along the ri[D]ver [C]again road',
        '[Em]Bells are ringing [D]gently down the empty market halls',
      ].join('\n'),
    );
    final first = parseArrangement(
      doc.body,
    ).firstWhere((arranged) => arranged.text == line);
    expect([for (final chord in first.chords) chord.chord], ['G', 'D', 'C']);
    expect(first.chords.last.offset, line.indexOf('road'));
  });

  test('a repeated chorus takes the chords of its own section', () {
    final doc = _combine(
      [_verse[0], _chorus, _verse[1], _chorus, ..._tail].join('\n'),
      [
        '[G]Someone hums a tune along the [C]winding river road',
        '[C]Paper lanterns drifting over the [G]quiet harbor water',
        '[Em]Bells are ringing gently down the [D]empty market halls',
        '[D]Paper lanterns drifting over the [A]quiet harbor water',
        // An unambiguous line on each side lets order decide.
        '[G]Morning carries salt and cedar [C]through the open door',
      ].join('\n'),
    );
    final choruses = [
      for (final line in parseArrangement(doc.body))
        if (line.text == _chorus) [for (final c in line.chords) c.chord],
    ];
    expect(choruses, [
      ['C', 'G'],
      ['D', 'A'],
    ]);
  });

  test('a partly chorded chorus fills its other lines from the first', () {
    final doc = _combine(
      [
        '[Chorus]',
        _chorus,
        'Every window glowing softly as the evening falls',
        '',
        '[Verse]',
        _verse[0],
        '',
        '[Chorus]',
        'Silver lanterns drifting over sleepy harbor water',
        'Every candle burning slowly as the morning calls',
      ].join('\n'),
      [
        '[G]Paper lanterns drifting [C]over quiet harbor water',
        '[Em]Every window glowing [D]softly as the evening falls',
        '[A]Someone hums a tune along the [E]winding river road',
        '[G]Silver lanterns drifting [C]over sleepy harbor water',
      ].join('\n'),
    );
    final chords = _chordsByLine(doc.body);
    expect(chords['Silver lanterns drifting over sleepy harbor water'], [
      'G',
      'C',
    ]);
    expect(chords['Every candle burning slowly as the morning calls'], [
      'Em',
      'D',
    ]);
  });

  test('a chord on a word the lyrics lack moves to the nearest word', () {
    const target = 'We need the lanterns near the harbor tonight';
    final doc = _combine(
      [target, ..._tail].join('\n'),
      'We really [D]really need the lanterns near the harbor tonight',
    );
    final line = parseArrangement(
      doc.body,
    ).firstWhere((line) => line.text == target);
    expect(line.chords.single.chord, 'D');
    expect(line.chords.single.offset, target.indexOf('need'));
  });

  test('a repeat whose chorded copies disagree takes no chords', () {
    final doc = _combine(
      [
        _verse[0],
        _chorus,
        _verse[1],
        _chorus,
        _tail[0],
        _chorus,
        _tail[1],
      ].join('\n'),
      [
        '[G]Someone hums a tune along the [C]winding river road',
        '[C]Paper lanterns drifting over the [G]quiet harbor water',
        '[Em]Bells are ringing gently down the [D]empty market halls',
        '[D]Paper lanterns drifting over the [A]quiet harbor water',
        '[G]Morning carries salt and cedar [C]through the open door',
        '[G]Little boats are waiting where the [C]gulls begin to call',
      ].join('\n'),
    );
    final repeats = [
      for (final line in parseArrangement(doc.body))
        if (line.text == _chorus) [for (final c in line.chords) c.chord],
    ];
    expect(repeats, [
      ['C', 'G'],
      ['D', 'A'],
      isEmpty,
    ]);
  });

  test('section fill abstains when earlier choruses disagree', () {
    final doc = _combine(
      [
        '[Verse]',
        _verse[0],
        '',
        '[Chorus]',
        _chorus,
        '',
        '[Verse]',
        _verse[1],
        '',
        '[Chorus]',
        _chorus,
        '',
        '[Verse]',
        _tail[0],
        '',
        '[Chorus]',
        _chorus,
        '',
        '[Outro]',
        _tail[1],
      ].join('\n'),
      [
        '[G]Someone hums a tune along the [C]winding river road',
        '[C]Paper lanterns drifting over the [G]quiet harbor water',
        '[Em]Bells are ringing gently down the [D]empty market halls',
        '[D]Paper lanterns drifting over the [A]quiet harbor water',
        '[G]Morning carries salt and cedar [C]through the open door',
        '[G]Little boats are waiting where the [C]gulls begin to call',
      ].join('\n'),
    );
    final repeats = [
      for (final line in parseArrangement(doc.body))
        if (line.text == _chorus) [for (final c in line.chords) c.chord],
    ];
    expect(repeats, [
      ['C', 'G'],
      ['D', 'A'],
      isEmpty,
    ]);
  });

  test('a short lyric line joins the next one to meet the chart line', () {
    const lyrics = [
      'Little darling',
      'the quiet harbor water waits for us',
      'Someone hums a tune along the river road doo doo doo doo',
    ];
    final doc = _combine(
      [...lyrics, ..._tail].join('\n'),
      [
        "[D]Little darlin', the quiet [G]harbor water waits for [A]us",
        '[Em]Someone hums a tune along the [C]river road',
      ].join('\n'),
    );
    final chords = _chordsByLine(doc.body);
    // "darlin'" is the same word as "darling".
    expect(chords[lyrics[0]], ['D']);
    expect(chords[lyrics[1]], ['G', 'A']);
    // Vocables the chart leaves out do not stop the match.
    expect(chords[lyrics[2]], ['Em', 'C']);
  });

  test('a key-checked chart with a capo fills lines in the main chart\'s '
      'shapes', () {
    final lyrics = [..._verse, _chorus, ..._tail];
    final doc = combineSources(_selected, [
      SourceResult(
        candidate: _selected,
        body: lyrics.join('\n'),
        matchKind: MatchKind.sameRecording,
      ),
      // Eb shapes, no capo: it gives the verse.
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'songsterr',
          id: 's',
          title: 'Harbor Song',
          artist: 'Test Artist',
        ),
        body: [
          '[Eb]Someone hums a tune along the [Bb]winding river road',
          '[Cm]Bells are ringing gently down the [Ab]empty market halls',
        ].join('\n'),
        matchKind: MatchKind.sameSong,
        extra: const {'partialLyrics': true, 'keyConsensus': true},
      ),
      // C shapes at capo 3 sound the same; its chorus moves to Eb shapes.
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'u',
          title: 'Harbor Song',
          artist: 'Test Artist',
        ),
        body: '[C]Paper lanterns drifting over [G]quiet harbor water',
        matchKind: MatchKind.sameSong,
        metadata: const {'capo': 3},
        extra: const {'partialLyrics': true, 'keyConsensus': true},
      ),
    ]);
    final chords = _chordsByLine(doc.body);
    expect(chords[_verse[0]], ['Eb', 'Bb']);
    expect(chords[_chorus], ['Eb', 'Bb']);
    // The moved chart's capo does not become the song's.
    expect(doc.metadata.containsKey('capo'), isFalse);
  });
}
