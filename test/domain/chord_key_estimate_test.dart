import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/chord_key_estimate.dart';

void main() {
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
}
