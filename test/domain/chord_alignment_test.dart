import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chord_key_estimate.dart';
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

  test('explicitly scoped capo charts transpose into the primary shapes', () {
    const selectedEb = SongCandidate(
      providerId: 'catalog',
      id: 'harbor-eb',
      title: 'Harbor Song',
      artist: 'Test Artist',
      metadata: {'key': 'Eb', 'capo': 0},
    );
    final lyrics = [..._verse, _chorus, ..._tail].join('\n');
    final primary = [
      '[Eb]Someone hums a tune along the [Bb]winding river road',
      _verse[1],
      _chorus,
      _tail[0],
      _tail[1],
    ].join('\n');
    final document = combineSources(selectedEb, [
      SourceResult(
        candidate: selectedEb,
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: selectedEb,
        body: primary,
        matchKind: MatchKind.sameRecording,
        metadata: const {'key': 'Eb', 'capo': 0},
        extra: const {'keyConsensus': true},
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'harbor-c-capo3',
          title: 'Harbor Song',
          artist: 'Test Artist',
        ),
        body: [
          '[C]Paper lanterns drifting over the [G]quiet harbor water',
          '[Am]Morning carries salt and cedar [F]through the open door',
          '[C]Little boats are waiting where the [G]gulls begin to call',
        ].join('\n'),
        matchKind: MatchKind.sameSong,
        metadata: const {'key': 'Eb', 'capo': 3},
        extra: const {'partialLyrics': true, 'keyConsensus': true},
      ),
    ]);

    expect(_chordsByLine(document.body)[_verse[0]], ['Eb', 'Bb']);
    expect(_chordsByLine(document.body)[_chorus], ['Eb', 'Bb']);
    expect(_chordsByLine(document.body)[_tail[0]], ['Cm', 'Ab']);
    expect(_chordsByLine(document.body)[_tail[1]], ['Eb', 'Bb']);
    expect(document.metadata['key'], 'Eb');
    expect(document.metadata['capo'], 0);
    expect(document.extra['chordSourceIds'], contains('ug:harbor-c-capo3'));
  });

  test(
    'capo difference is not merged without checked sounding-key evidence',
    () {
      const selectedEb = SongCandidate(
        providerId: 'catalog',
        id: 'harbor-eb',
        title: 'Harbor Song',
        artist: 'Test Artist',
        metadata: {'key': 'Eb', 'capo': 0},
      );
      final lyrics = [..._verse, _chorus, ..._tail].join('\n');
      final primary = [
        '[Eb]${_verse[0]}',
        _verse[1],
        _chorus,
        ..._tail,
      ].join('\n');
      final document = combineSources(selectedEb, [
        SourceResult(
          candidate: selectedEb,
          body: lyrics,
          matchKind: MatchKind.sameRecording,
        ),
        SourceResult(
          candidate: selectedEb,
          body: primary,
          matchKind: MatchKind.sameRecording,
          metadata: const {'key': 'Eb', 'capo': 0},
          extra: const {'keyConsensus': true},
        ),
        SourceResult(
          candidate: const SongCandidate(
            providerId: 'ug',
            id: 'harbor-c-capo3',
            title: 'Harbor Song',
            artist: 'Test Artist',
          ),
          body: '[C]Paper lanterns drifting over the [G]quiet harbor water',
          matchKind: MatchKind.sameSong,
          metadata: const {'key': 'Eb', 'capo': 3},
        ),
      ]);

      expect(_chordsByLine(document.body)[_verse[0]], ['Eb']);
      expect(_chordsByLine(document.body)[_chorus], isEmpty);
      expect(document.metadata['capo'], 0);
    },
  );

  test('an incomplete rejected chart may add chords on shared lyric phrases', () {
    const selected = SongCandidate(
      providerId: 'genius',
      id: 'three-little-birds',
      title: 'Three Little Birds',
      artist: 'Bob Marley & The Wailers',
    );
    const lyrics = '''Rise up this mornin'
Smile with the rising sun
Three little birds sit by my doorstep
Singin' sweet songs
Of melodies pure and true
Singin', this is my message to you-ou-ou''';
    const chart = '''[A]Rise up this mornin'
[E]Smile with the rising sun
[A]Three little birds sit by my doorstep
[D]Singin' sweet songs
[E]Of melodies pure and true
[D]Singin', this is my message to [A]you-ou-ou''';
    final document = combineSources(selected, [
      SourceResult(
        candidate: selected,
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'three-little-birds-chart',
          title: 'Three Little Birds',
          artist: 'Bob Marley',
        ),
        body: chart,
        metadata: const {
          'key': 'A',
          'capo': 0,
          'tuning': ['E', 'A', 'D', 'G', 'B', 'E'],
        },
        matchKind: MatchKind.rejected,
        matchReason: 'incomplete_or_different_lyrics',
        extra: const {'requiresLyricsAgreement': true},
      ),
    ]);

    expect(_chordsByLine(document.body)["Rise up this mornin'"], ['A']);
    expect(_chordsByLine(document.body)['Smile with the rising sun'], ['E']);
    expect(
      _chordsByLine(document.body)['Three little birds sit by my doorstep'],
      ['A'],
    );
    expect(document.metadata['key'], 'A');
    expect(document.extra['keySourceIds'], contains('ug:three-little-birds-chart'));
    expect(document.extra['selectedSourceId'], 'genius:three-little-birds');
  });

  test('a rejected partial chart contributes only its aligned phrase', () {
    const selected = SongCandidate(
      providerId: 'genius',
      id: 'three-little-birds',
      title: 'Three Little Birds',
      artist: 'Bob Marley & The Wailers',
    );
    const lyrics = '''Rise up this mornin'
Smile with the rising sun
Three little birds sit by my doorstep''';
    const onePhrase = '''[A]Rise up this mornin'
[E]Some unrelated phrase''';
    final onePhraseDocument = combineSources(selected, [
      SourceResult(
        candidate: selected,
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'one-phrase-chart',
          title: 'Three Little Birds',
          artist: 'Bob Marley',
        ),
        body: onePhrase,
        metadata: const {'key': 'A', 'capo': 0},
        matchKind: MatchKind.rejected,
        matchReason: 'incomplete_or_different_lyrics',
        extra: const {'requiresLyricsAgreement': true},
      ),
    ]);
    final partialLines = _chordsByLine(onePhraseDocument.body);
    expect(partialLines["Rise up this mornin'"], ['A']);
    expect(partialLines['Smile with the rising sun'], isEmpty);
    expect(partialLines['Three little birds sit by my doorstep'], isEmpty);
    expect(onePhraseDocument.body, isNot(contains('Some unrelated phrase')));

    const chart = '''[A]Rise up this mornin'
[E]Smile with the rising sun
[A]Three little birds sit by my doorstep''';
    final pendingDocument = combineSources(selected, [
      SourceResult(
        candidate: selected,
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'pending-chart',
          title: 'Three Little Birds',
          artist: 'Bob Marley & The Wailers',
        ),
        body: chart,
        metadata: const {'key': 'A', 'capo': 0},
        matchKind: MatchKind.rejected,
        matchReason: 'incomplete_or_different_lyrics',
        extra: const {'pendingMatchCheck': true},
      ),
    ]);
    final pendingLines = _chordsByLine(pendingDocument.body);
    expect(pendingLines["Rise up this mornin'"], ['A']);
    expect(pendingLines['Smile with the rising sun'], ['E']);
    expect(pendingLines['Three little birds sit by my doorstep'], ['A']);
    expect(pendingDocument.extra['pendingChordSourceIds'], ['ug:pending-chart']);
    final pendingKey = (pendingDocument.extra['evidenceRanking'] as Map)
        ['appliedFields']['metadata.key'] as Map;
    expect(pendingKey['sourceId'], 'ug:pending-chart');
    expect(pendingKey['provisional'], isTrue);
  });

  test('an alternate-tuning chart keeps its anchors and tuning together', () {
    const selected = SongCandidate(
      providerId: 'genius',
      id: 'three-little-birds',
      title: 'Three Little Birds',
      artist: 'Bob Marley & The Wailers',
    );
    const lyrics = '''Rise up this mornin'
Smile with the rising sun
Three little birds sit by my doorstep''';
    const chart = '''[A]Rise up this mornin'
[E]Smile with the rising sun
[A]Three little birds sit by my doorstep''';
    final document = combineSources(selected, [
      SourceResult(
        candidate: selected,
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'alternate-tuning-chart',
          title: 'Three Little Birds',
          artist: 'Bob Marley',
        ),
        body: chart,
        metadata: const {
          'key': 'A',
          'capo': 0,
          'tuning': ['D', 'A', 'D', 'G', 'B', 'E'],
        },
        matchKind: MatchKind.rejected,
        matchReason: 'incomplete_or_different_lyrics',
        extra: const {'requiresLyricsAgreement': true},
      ),
    ]);

    expect(_chordsByLine(document.body)['Rise up this mornin\''], ['A']);
    expect(_chordsByLine(document.body)['Smile with the rising sun'], ['E']);
    expect(
      _chordsByLine(document.body)['Three little birds sit by my doorstep'],
      ['A'],
    );
    expect(document.metadata['tuning'], ['D', 'A', 'D', 'G', 'B', 'E']);
    expect(document.extra['fieldContributors']['tuning'],
        contains('ug:alternate-tuning-chart'));
  });

  test('phrase overlap cannot bypass recording-specific chart identity', () {
    const selected = SongCandidate(
      providerId: 'genius',
      id: 'three-little-birds',
      title: 'Three Little Birds',
      artist: 'Bob Marley & The Wailers',
    );
    const lyrics = '''Rise up this mornin'
Smile with the rising sun
Three little birds sit by my doorstep''';
    const chart = '''[A]Rise up this mornin'
[E]Smile with the rising sun
[A]Three little birds sit by my doorstep''';
    final document = combineSources(selected, [
      SourceResult(
        candidate: selected,
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'recording-scoped-chart',
          title: 'Three Little Birds',
          artist: 'Bob Marley',
        ),
        body: chart,
        metadata: const {'key': 'A', 'capo': 0},
        matchKind: MatchKind.rejected,
        matchReason: 'incomplete_or_different_lyrics',
        extra: const {
          'requiresLyricsAgreement': true,
          'requiresRecordingLyricsAgreement': true,
        },
      ),
    ]);

    expect(
      _chordsByLine(document.body).values.every((chords) => chords.isEmpty),
      isTrue,
    );
    expect(document.metadata['key'], isNull);
  });

  test('a rejected chart retains supported capo and declared key context', () {
    const selected = SongCandidate(
      providerId: 'genius',
      id: 'lantern-song',
      title: 'Lantern Song',
      artist: 'Test Artist',
    );
    const lyrics = '''Lanterns drift above the quiet harbor
Moonlight follows boats across the water
Morning finds the nets along the shore''';
    final capoed = combineSources(selected, [
      SourceResult(
        candidate: selected,
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'capoed-lantern-chart',
          title: 'Lantern Song',
          artist: 'Test Artist',
        ),
        body: '[Am]Lanterns drift above the quiet harbor\n'
            '[F]Moonlight follows boats across the water\n'
            '[C]Morning finds the nets along the shore [G]',
        metadata: const {'key': 'Em', 'capo': 7},
        matchKind: MatchKind.rejected,
        matchReason: 'incomplete_or_different_lyrics',
        extra: const {'keyConsensus': true},
      ),
    ]);
    final capoedLines = _chordsByLine(capoed.body);
    expect(capoedLines['Lanterns drift above the quiet harbor'], ['Am']);
    expect(capoedLines['Moonlight follows boats across the water'], ['F']);
    expect(capoedLines['Morning finds the nets along the shore'], ['C', 'G']);
    expect(capoed.metadata['key'], 'Em');
    expect(capoed.metadata['capo'], 7);
    expect(capoed.extra['fieldContributors']['key'],
        contains('ug:capoed-lantern-chart'));

    final nonconsensus = combineSources(selected, [
      SourceResult(
        candidate: selected,
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ug',
          id: 'nonconsensus-lantern-chart',
          title: 'Lantern Song',
          artist: 'Test Artist',
        ),
        body: '[G]Lanterns drift above the quiet harbor\n'
            '[D]Moonlight follows boats across the water\n'
            '[C]Morning finds the nets along the shore',
        metadata: const {'key': 'G', 'capo': 0},
        matchKind: MatchKind.rejected,
        matchReason: 'incomplete_or_different_lyrics',
        extra: const {'keyConsensus': false},
      ),
    ]);
    final nonconsensusLines = _chordsByLine(nonconsensus.body);
    expect(nonconsensusLines['Lanterns drift above the quiet harbor'], ['G']);
    expect(nonconsensusLines['Moonlight follows boats across the water'], ['D']);
    expect(nonconsensusLines['Morning finds the nets along the shore'], ['C']);
    expect(nonconsensus.metadata['key'], 'G');
    expect(nonconsensus.metadata['capo'], 0);
  });

  test('unscoped same-song donor cannot add uncorroborated anchors', () {
    const selected = SongCandidate(
      providerId: 'catalog',
      id: 'lantern-song',
      title: 'Lantern Song',
      artist: 'Test Artist',
    );
    const first = 'Lanterns drift over the harbor tonight';
    const second = 'Moonlight follows boats across the water';
    const third = 'Quiet waves return beneath the bridge';
    final document = combineSources(selected, [
      SourceResult(
        candidate: selected,
        body: '[G]Lanterns drift over the [D]harbor tonight\n'
            '[D]Moonlight follows [C]boats across the water\n$third',
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'chordie',
          id: 'lantern-song-donor',
          title: 'Lantern Song',
          artist: 'Test Artist',
        ),
        body: '[G]Lanterns drift over the [D]harbor tonight\n'
            '[D]Moonlight follows [C]boats across the water\n[C]$third',
        matchKind: MatchKind.sameSong,
      ),
    ]);

    expect(_chordsByLine(document.body)[first], ['G', 'D']);
    expect(_chordsByLine(document.body)[second], ['D', 'C']);
    expect(_chordsByLine(document.body)[third], isEmpty);
    expect(document.extra['chordSourceIds'], ['catalog:lantern-song']);
  });

  test('overlapping readings of a repeated phrase do not interleave', () {
    const line = 'la la la la la la la la';
    final doc = _combine(
      [line, ..._verse, ..._tail].join('\n'),
      [
        '[E]la la la la la la [D]la',
        '[E]la la la la la la [D]la',
        '[G]Someone hums a tune along the [C]winding river road',
      ].join('\n'),
    );
    final chords = parseArrangement(
      doc.body,
    ).firstWhere((l) => l.text == line).chords.map((c) => c.chord).toList();
    // Either one reading or none; never E E D D.
    expect(chords, anyOf(isEmpty, ['E', 'D']));
  });

  test('the one chart that gave the chords names the key when few reach '
      'the lyrics', () {
    // The chart's intro carries the cadences; only two of its chords reach
    // the lyric lines, too few for an estimate of their own.
    final doc = _combine(
      [_verse[0], _chorus, ..._tail].join('\n'),
      [
        '[E] [A] [B7] [E] [C#m] [A] [B7] [E]',
        '[E] [A] [B7] [E] [C#m] [A] [B7] [E]',
        '[E]Someone hums a tune along the [B7]winding river road',
      ].join('\n'),
    );
    expect(estimateChordKey(doc.body), isNull);
    expect(checkedChordKeyEstimate(doc), 'E');
  });

  test('lyrics with enough chords whose key is open stay open', () {
    // The lyric lines carry a full but ambiguous loop (Am F C G: A minor or
    // C major); the chart's cadential intro must not decide for them.
    final doc = _combine(
      [_verse[0], _verse[1], _chorus, ..._tail].join('\n'),
      [
        '[E] [A] [B7] [E] [C#m] [A] [B7] [E]',
        '[Am]Someone hums a tune [F]along the [C]winding river [G]road',
        '[Am]Bells are ringing [F]gently down the [C]empty market [G]halls',
      ].join('\n'),
    );
    expect(doc.metadata['key'], isNull);
    expect(checkedChordKeyEstimate(doc), 'Am');
    final keyDecision = (doc.extra['evidenceRanking'] as Map)
        ['appliedFields']['metadata.key'] as Map;
    expect(keyDecision['inferred'], isTrue);
  });
}
