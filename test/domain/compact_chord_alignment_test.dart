import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/compact_chord_alignment.dart';

String _render(String text, List<ChordAnchor> anchors) {
  final graphemes = text.characters.toList();
  final at = <int, List<String>>{};
  for (final anchor in anchors) {
    at.putIfAbsent(anchor.offset, () => []).add(anchor.chord);
  }
  final output = StringBuffer();
  for (var offset = 0; offset <= graphemes.length; offset++) {
    for (final chord in at[offset] ?? const <String>[]) {
      output.write('[$chord]');
    }
    if (offset < graphemes.length) output.write(graphemes[offset]);
  }
  return output.toString();
}

void main() {
  test(
    'maps split and joined donor words, including an internal-word anchor',
    () {
      const lyric = 'the rain softly falls beyond the hills today';
      final target = [const ArrangementLine(lyric, [])];
      final placed = compactLineChords(
        target,
        'the [C]rain so ft[G]ly falls beyond the hills today',
      );

      expect(
        placed[0]!.map((anchor) => (anchor.offset, anchor.chord)).toList(),
        [(lyric.indexOf('rain'), 'C'), (lyric.indexOf('ly'), 'G')],
      );
      expect(target.single.text, lyric);
      expect(parseArrangement(_render(lyric, placed[0]!)).single.text, lyric);
    },
  );

  test('folds vowel accents and keeps grapheme target offsets and text', () {
    const lyric = '🎵 Cielíto mi corazón brilla';
    final target = [const ArrangementLine(lyric, [])];
    final placed = compactLineChords(target, 'Cielito mi corazon [Am]brilla');

    expect(placed[0]!.map((anchor) => (anchor.offset, anchor.chord)).toList(), [
      (lyric.substring(0, lyric.indexOf('brilla')).characters.length, 'Am'),
    ]);
    expect(
      lyric.characters.skip(placed[0]!.single.offset).join(),
      startsWith('brilla'),
    );
    expect(target.single.text, lyric);
    final reconstructed = parseArrangement(_render(lyric, placed[0]!)).single;
    expect(reconstructed.text, lyric);
    expect(reconstructed.chords.single.offset, placed[0]!.single.offset);
  });

  test('maps an end anchor to the end of the matched letters', () {
    const lyric = 'the moon is shining tonight';
    final placed = compactLineChords([
      const ArrangementLine(lyric, []),
    ], 'the moon is shining tonight[C]');

    expect(placed[0]!.map((anchor) => (anchor.offset, anchor.chord)).toList(), [
      (lyric.characters.length, 'C'),
    ]);
  });

  test('abstains when matching donors disagree on placement or chord', () {
    const lyric = 'the bright morning sun is rising';
    final target = [const ArrangementLine(lyric, [])];

    expect(
      compactLineChords(
        target,
        'the [C]bright morning sun is rising\n'
        'the bright morning [G]sun is rising',
      ),
      isEmpty,
    );
    expect(
      compactLineChords(
        target,
        'the [C]bright morning sun is rising\n'
        'the [G]bright morning sun is rising',
      ),
      isEmpty,
    );
  });

  test('deduplicates identical donor placements', () {
    final placed = compactLineChords(
      [const ArrangementLine('the bright morning sun is rising', [])],
      'the [C]bright morning sun is rising\n'
      'the [C]bright morning sun is rising',
    );

    expect(placed[0]!.map((anchor) => (anchor.offset, anchor.chord)).toList(), [
      (4, 'C'),
    ]);
  });

  test('merges disjoint exact lyric spans on one target line', () {
    const lyric = 'when the morning light comes and the evening stars appear';
    final placed = compactLineChords(
      [const ArrangementLine(lyric, [])],
      'when the morning light[C] comes\n'
      'and the evening stars[G] appear',
    );

    expect(placed[0]!.map((anchor) => (anchor.offset, anchor.chord)).toList(), [
      (lyric.indexOf('comes'), 'C'),
      (lyric.indexOf('appear'), 'G'),
    ]);
  });

  test('prefers a matching full chord over a power fifth in either order', () {
    final target = [const ArrangementLine('when the morning light comes', [])];
    for (final chart in [
      'when the morning light[C] comes\n'
          'when the morning light[C5] comes',
      'when the morning light[C5] comes\n'
          'when the morning light[C] comes',
    ]) {
      final placed = compactLineChords(target, chart);
      expect(
        placed[0]!.map((anchor) => (anchor.offset, anchor.chord)).toList(),
        [(target.single.text.indexOf('comes'), 'C')],
      );
    }
  });

  test('skips a disputed span but keeps independent matched spans', () {
    const lyric = 'when the morning light comes and the evening stars appear';
    final placed = compactLineChords(
      [const ArrangementLine(lyric, [])],
      'when the morning light[C] comes\n'
      'when the morning light[G] comes\n'
      'and the evening stars[D] appear',
    );

    expect(placed[0]!.map((anchor) => (anchor.offset, anchor.chord)).toList(), [
      (lyric.indexOf('appear'), 'D'),
    ]);
  });

  test(
    'does not spread one partial phrase across different lyric contexts',
    () {
      final target = [
        const ArrangementLine('Amber lanterns glow above the river', []),
        const ArrangementLine('Amber lanterns glow beyond the station', []),
      ];

      expect(compactLineChords(target, '[C]Amber lanterns glow'), isEmpty);
    },
  );

  test('allows one partial phrase across repeated exact lyric contexts', () {
    const lyric = 'Amber lanterns glow above the river';
    final target = [
      const ArrangementLine(lyric, []),
      const ArrangementLine(lyric, []),
    ];
    final placed = compactLineChords(target, '[C]Amber lanterns glow');

    expect(placed.keys, {0, 1});
    expect(placed[0]!.single.chord, 'C');
    expect(placed[1]!.single.chord, 'C');
  });

  test(
    'ignores reordered or unrelated lyrics, directives, and chord-only lines',
    () {
      final target = [
        const ArrangementLine('the bright morning sun is rising', []),
        const ArrangementLine('unrelated words beneath the stars tonight', []),
      ];
      final placed = compactLineChords(
        target,
        '{start_of_verse}\n'
        '[C][G]\n'
        'rising is sun morning bright the[D]\n'
        'unrelated tune about open skies tonight[E]',
      );

      expect(placed, isEmpty);
      expect(target.map((line) => line.text), [
        'the bright morning sun is rising',
        'unrelated words beneath the stars tonight',
      ]);
    },
  );

  test('requires at least three words and twelve letters in the donor', () {
    final target = [
      const ArrangementLine('we go now and the sunlight shines', []),
      const ArrangementLine('the sun is shining brightly today', []),
    ];
    expect(compactLineChords(target, 'we [C]go now'), isEmpty);
    expect(compactLineChords(target, 'sunlight [C]shines'), isEmpty);
    expect(
      compactLineChords(target, 'the [C]sun is shining brightly today'),
      isNotEmpty,
    );
  });
}
