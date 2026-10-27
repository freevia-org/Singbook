import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/published_name_alias.dart';

void main() {
  test('accepts only an explicitly published Latin alias', () {
    expect(publishedNameVariants('上を向いて歩こう (SUKIYAKI)'), [
      '上を向いて歩こう (SUKIYAKI)',
      'SUKIYAKI',
    ]);
    expect(publishedNamesMatch('上を向いて歩こう (SUKIYAKI)', 'Sukiyaki'), isTrue);
    expect(publishedNamesMatch('坂本九 (Kyu Sakamoto)', 'Kyu Sakamoto'), isTrue);
    expect(publishedNamesMatch('坂本九', 'Kyu Sakamoto'), isFalse);
  });

  test('does not treat qualifiers or Latin-only parentheses as aliases', () {
    for (final qualifier in [
      'Version',
      'Live',
      'Acoustic',
      'Translation',
      'Translated',
      'feat. Kyu Sakamoto',
      'Remix',
    ]) {
      final name = '上を向いて歩こう ($qualifier)';
      expect(publishedNameVariants(name), [name], reason: qualifier);
    }
    for (final name in [
      'Sukiyaki (Kyu Sakamoto)',
      '上を向いて歩こう (すきやき)',
      '上を向いて歩こう (Sukiyaki) live',
    ]) {
      expect(publishedNameVariants(name), [name], reason: name);
    }
  });
}
