import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';

void main() {
  test('cached parses match a fresh parse and are not shared mutably', () {
    const body = '{title: x}\n[Em]Amber lanterns [C]glow\n\nplain line';
    final first = parseArrangement(body);
    final second = parseArrangement(body);
    expect(identical(first, second), isFalse);
    first.removeLast();
    expect(parseArrangement(body).length, second.length);
    expect(second.map((l) => l.text), [
      '{title: x}',
      'Amber lanterns glow',
      '',
      'plain line',
    ]);
    expect(second[1].chords.map((c) => (c.offset, c.chord)), [
      (0, 'Em'),
      (15, 'C'),
    ]);
    expect(second[0].directive, isTrue);
    expect(plainLyrics(body), plainLyrics(body));
  });

  test('the cache stays bounded and still returns correct results', () {
    for (var i = 0; i < 300; i++) {
      expect(parseArrangement('[G]line $i').single.text, 'line $i');
    }
    expect(parseArrangement('[G]line 0').single.text, 'line 0');
  });
}
