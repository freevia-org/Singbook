import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/contextual_chart_lyrics.dart';

const _reference = '''
Harbor lanterns gather where the quiet river bends
Silver windows carry evening over winding stone streets
A distant bell reminds the sailors to return home
Lantern keeper draws a map of falling summer stars
Every narrow bridge glows softly through the midnight rain
We leave the harbor when the pale morning rises
Across the water songs remember how the tide turns
Home is waiting where the small boats rest at dawn
''';

const _partial = '''
[C]Harbor lanterns gather where the quiet river bends
[G]Silver windows carry evening over winding stone streets
[Am]A distant bell reminds the sailors to return home
[F]Lantern keeper draws a map of falling summer stars
''';

void main() {
  test(
    'exact fragment text survives word splits introduced around chord anchors',
    () {
      final split = _partial
          .replaceAll('lanterns', 'lan terns')
          .replaceAll('windows', 'win dows')
          .replaceAll('sailors', 'sai lors')
          .replaceAll('summer', 'sum mer');
      expect(
        contextualChartLyricsMatch(split, _reference, allowPartial: true),
        isTrue,
      );
    },
  );

  test('strict mode keeps whole-song coverage requirements', () {
    expect(contextualChartLyricsMatch(_partial, _reference), isFalse);
    expect(
      contextualChartLyricsMatch(_partial, _reference, allowPartial: true),
      isTrue,
    );
  });

  test('rejects unrelated text even when it has enough lines and chords', () {
    const wrong = '''
[C]Copper mountains watch the sleepy valley open wide
[G]Paper kites are lifting past the distant railway station
[Am]Every traveler follows footprints through the orchard grass
[F]Summer rain is tapping on the windows of the train
''';
    expect(
      contextualChartLyricsMatch(wrong, _reference, allowPartial: true),
      isFalse,
    );
  });

  test('rejects a short refrain without enough distinct matching words', () {
    const refrain = '''
[C]Harbor lanterns gather where the quiet river bends
[G]Harbor lanterns gather where the quiet river bends
''';
    expect(
      contextualChartLyricsMatch(refrain, _reference, allowPartial: true),
      isFalse,
    );
  });

  test('requires multiple chord-bearing lyric lines', () {
    const unchorded = '''
Harbor lanterns gather where the quiet river bends
Silver windows carry evening over winding stone streets
A distant bell reminds the sailors to return home
Lantern keeper draws a map of falling summer stars
''';
    expect(
      contextualChartLyricsMatch(unchorded, _reference, allowPartial: true),
      isFalse,
    );
  });

  test('requires fragment bigram order to match the reference', () {
    const reordered = '''
[C]bends river quiet the where gather lanterns Harbor
[G]streets stone winding over evening carry windows Silver
[Am]home return to sailors the reminds bell distant A
[F]stars summer falling of map a draws keeper Lantern
''';
    expect(
      contextualChartLyricsMatch(reordered, _reference, allowPartial: true),
      isFalse,
    );
  });
  test(
    'a minor transcription difference does not invalidate a matching fragment',
    () {
      final changed = _partial.replaceFirst(
        'lanterns gather',
        'gather lanterns',
      );
      expect(
        contextualChartLyricsMatch(changed, _reference, allowPartial: true),
        isTrue,
      );
    },
  );
}
