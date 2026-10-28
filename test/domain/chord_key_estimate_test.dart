import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/chord_key_estimate.dart';

void main() {
  test('boundary tonic does not treat repeated ii chords as the home key', () {
    const body = '[F] [Gm] [Bb] [C] [Gm] [F]';

    expect(chartSupportsDeclaredTonic(body, 'Gm'), isTrue);
    expect(chartSupportsBoundaryTonic(body, 'Gm'), isFalse);
    expect(chartSupportsBoundaryTonic(body, 'F'), isTrue);
  });

  test(
    'boundary tonic supports modal charts when the scale estimate differs',
    () {
      const body = '[D] [C] [G] [D] [C] [G]';

      expect(chartSupportsBoundaryTonic(body, 'D'), isTrue);
    },
  );

  test(
    'boundary tonic survives a contrasting bridge between matching ends',
    () {
      const body = '''
[Am]
[C] [G] [D] [F] [C] [G] [D] [F]
[Am]
''';

      expect(chartSupportsBoundaryTonic(body, 'Am'), isTrue);
    },
  );

  test('boundary tonic parses extended and slash chords after directives', () {
    const body = '''
{comment: Intro}
{start_of_verse}
[Fmaj7/A] [G7] [C]
''';

    expect(chartSupportsBoundaryTonic(body, 'F'), isTrue);
    expect(chartSupportsBoundaryTonic('[C] [G] [Am7/G]', 'Am'), isTrue);
  });

  test(
    'power chords support either mode, while incompatible quality does not',
    () {
      expect(chartSupportsBoundaryTonic('[D5] [F] [G]', 'D'), isTrue);
      expect(chartSupportsBoundaryTonic('[D5] [F] [G]', 'Dm'), isTrue);
      expect(chartSupportsBoundaryTonic('[Fm] [C] [G]', 'F'), isFalse);
    },
  );

  test('boundary tonic abstains for absent chords or an invalid key', () {
    expect(chartSupportsBoundaryTonic('', 'C'), isFalse);
    expect(
      chartSupportsBoundaryTonic('{start_of_verse}\n[N.C.]', 'C'),
      isFalse,
    );
    expect(chartSupportsBoundaryTonic('[C] [G] [F]', 'H'), isFalse);
  });

  test(
    'estimates E major from the chart harmony, not its first chord alone',
    () {
      const body = '''
[E] [A/E] [Am/E] [E]
[E] [A/E] [C#m] [F#]
[G#m] [F#] [B] [B/A]
[E] [A/E] [C#m] [F#]
[D/F#] [A/E] [E]
''';

      final estimate = estimateChordKey(body);

      expect(estimate, isNotNull);
      expect(estimate!.key, 'E');
      expect(estimate.chordCount, 19);
      expect(estimate.distinctRoots, 7);
      expect(estimate.separation, greaterThanOrEqualTo(0.32));
    },
  );

  test('abstains when the relative major and minor are too close', () {
    const body = '''
[Am] [F] [C] [G]
[Am] [F] [C] [G]
''';

    expect(estimateChordKey(body), isNull);
  });

  test('abstains when two major tonics explain the chart similarly', () {
    const body = '''
[Ab] [Db] [Eb] [Fm] [Ab]
[Db] [Eb] [Fm] [Ab]
''';

    expect(estimateChordKey(body), isNull);
  });

  test('abstains when well-supported sections point to different keys', () {
    const body = '''
[Verse 1]
[C] [F] [G] [C] [Am] [F] [G] [C]
[Verse 2]
[C] [F] [G] [C] [Am] [F] [G] [C]
[Verse 3]
[C] [F] [G] [C] [Am] [F] [G] [C]
[Bridge]
[D] [G] [A] [D] [Bm] [G] [A] [D]
''';

    expect(estimateChordKey(body), isNull);
  });

  test('abstains for a sparse chart', () {
    expect(estimateChordKey('[E] [A] [B]'), isNull);
  });

  test('slash bass notes do not count as chord roots', () {
    expect(estimateChordKey('[C/G] [C/G] [C/G] [C/G] [C/G] [C/G]'), isNull);
  });

  test('supports flat spelling when the chart consistently uses flats', () {
    const body = '''
[Ab] [Fm] [Db] [Eb] [Ab]
[Fm] [Db] [Eb] [Ab]
''';

    expect(estimateChordKey(body)?.key, 'Ab');
  });

  test('uppercase M chord suffixes retain major quality', () {
    const body = '''
[CM7] [Fmaj7] [G7] [Am7]
[Dm7] [G7] [CM7] [Fmaj7]
[G7] [Am7] [Dm7] [G7] [CM7]
''';

    expect(estimateChordKey(body)?.key, 'C');
  });

  test('every recognized section heading splits local key analysis', () {
    const cMajor = '[C] [F] [G] [C] [Am] [F] [G] [C]';
    const dMajor = '[D] [G] [A] [D] [Bm] [G] [A] [D]';
    for (final heading in [
      '[Post-Chorus]',
      '[Hook]',
      '[Breakdown]',
      '[Coda]',
      '[Tag]',
      '[Ending]',
      '{start_of_post_chorus}',
      '{start_of_hook}',
      '{start_of_breakdown}',
      '{start_of_coda}',
      '{start_of_tag}',
      '{start_of_ending}',
    ]) {
      expect(
        estimateChordKey('$cMajor\n$heading\n$dMajor'),
        isNull,
        reason: 'section heading $heading must prevent a cross-section key',
      );
    }
  });

  test('a measured key settles a key the chords leave open', () {
    const body = '''
[Am] [F] [C] [G]
[Am] [F] [C] [G]
''';
    expect(estimateChordKey(body, hint: 'Am')?.key, 'Am');
    expect(estimateChordKey(body, hint: 'C')?.key, 'C');
    // A key outside the chords' signature is no evidence.
    expect(estimateChordKey(body, hint: 'E'), isNull);
    // A clear estimate is never overridden.
    const clear = '''
[E] [A/E] [Am/E] [E]
[E] [A/E] [C#m] [F#]
[G#m] [F#] [B] [B/A]
[E] [A/E] [C#m] [F#]
[D/F#] [A/E] [E]
''';
    expect(estimateChordKey(clear, hint: 'C#m')?.key, 'E');
  });

  test('keys take their conventional names', () {
    const sharps = '''
[D#] [G#] [A#] [D#] [Cm] [G#] [A#] [D#]
[D#] [G#] [A#] [D#] [Cm] [G#] [A#] [D#]
''';
    expect(estimateChordKey(sharps)?.key, 'Eb');
    const cSharp = '''
[C#] [F#] [G#] [C#] [A#m] [F#] [G#] [C#]
[C#] [F#] [G#] [C#] [A#m] [F#] [G#] [C#]
''';
    expect(estimateChordKey(cSharp)?.key, 'Db');
  });

  test('ranked API returns alternatives for relatively ambiguous harmony', () {
    const body = '''
[Am] [F] [C] [G]
[Am] [F] [C] [G]
''';
    expect(estimateChordKey(body), isNull);
    final ranked = rankChordKeyCandidates(body);
    expect(ranked, hasLength(24));
    expect(ranked.map((item) => item.rank), List.generate(24, (i) => i + 1));
    expect(ranked.every((item) => item.chordCount == 8), isTrue);
  });

  test('ranked API analyzes modulation globally without section veto', () {
    const body = '''
[Verse]
[C] [F] [G] [C] [Am] [F] [G] [C]
[Bridge]
[D] [G] [A] [D] [Bm] [G] [A] [D]
''';
    expect(estimateChordKey(body), isNull);
    final ranked = rankChordKeyCandidates(body);
    expect(ranked, hasLength(24));
    expect(ranked.first.chordCount, 16);
  });

  test('ranked API needs at least three chords and two chord roots', () {
    expect(rankChordKeyCandidates('[C]'), isEmpty);
    expect(rankChordKeyCandidates('[C] [C]'), isEmpty);
    expect(rankChordKeyCandidates('[C/G] [C/G] [C/G] [C/G]'), isEmpty);
  });

  test('hint breaks near ambiguity but does not override clear harmony', () {
    const ambiguous = '[Am] [F] [C] [G]\n[Am] [F] [C] [G]';
    expect(rankChordKeyCandidates(ambiguous, hint: 'Am').first.key, 'Am');
    expect(rankChordKeyCandidates(ambiguous, hint: 'C').first.key, 'C');
    const clear = '''
[E] [A/E] [Am/E] [E]
[E] [A/E] [C#m] [F#]
[G#m] [F#] [B] [B/A]
[E] [A/E] [C#m] [F#]
[D/F#] [A/E] [E]
''';
    expect(rankChordKeyCandidates(clear, hint: 'C#m').first.key, 'E');
  });

  test('enharmonic chart spellings have the same ranked key identities', () {
    const sharp = '''
[C#] [F#] [G#] [C#] [A#m] [F#] [G#] [C#]
[C#] [F#] [G#] [C#] [A#m] [F#] [G#] [C#]
''';
    const flat = '''
[Db] [Gb] [Ab] [Db] [Bbm] [Gb] [Ab] [Db]
[Db] [Gb] [Ab] [Db] [Bbm] [Gb] [Ab] [Db]
''';
    String identity(String key) {
      final minor = key.endsWith('m');
      final root = minor ? key.substring(0, key.length - 1) : key;
      const pitches = {
        'C': 0, 'B#': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
        'E': 4, 'Fb': 4, 'E#': 5, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7,
        'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11, 'Cb': 11,
      };
      return '${pitches[root]}:${minor ? 'minor' : 'major'}';
    }
    final sharpIds = rankChordKeyCandidates(sharp).map((item) => identity(item.key));
    final flatIds = rankChordKeyCandidates(flat).map((item) => identity(item.key));
    expect(sharpIds, flatIds);
  });
}
