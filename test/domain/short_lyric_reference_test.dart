import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/short_lyric_reference.dart';

const _phrase = 'amber bell carries quiet dreams across silver water';
const _reference = '''
amber bell carries quiet dreams across silver water
amber bell carries quiet dreams across silver water
oh amber bell carries quiet dreams across silver water
amber bell carries quiet dreams across silver water ah
''';
const _chart = '''
amber bell carries quiet dreams across silver water
amber bell carries quiet dreams across silver water
amber bell carries quiet dreams across silver water
amber bell carries quiet dreams across silver water
''';

void main() {
  test('accepts a near-complete repeated short-vocabulary reference', () {
    expect(isShortRecordingLyricBody(_reference), isTrue);
    expect(shortRecordingLyricAgreement(_chart, _reference), isTrue);
  });

  test('rejects changed words and reordered sequences', () {
    final wrongWord = _chart.replaceFirst('quiet', 'restless');
    final reordered = _chart.replaceFirst(
      _phrase,
      'amber bell carries dreams quiet across silver water',
    );

    expect(shortRecordingLyricAgreement(wrongWord, _reference), isFalse);
    expect(shortRecordingLyricAgreement(reordered, _reference), isFalse);
  });

  test('rejects a shared refrain excerpt and added chart words', () {
    final excerpt = List.filled(3, _phrase).join('\n');
    final extraVerse = '$_chart\n$_phrase again';

    expect(shortRecordingLyricAgreement(excerpt, _reference), isFalse);
    expect(shortRecordingLyricAgreement(extraVerse, _reference), isFalse);
  });

  test('removes ChordPro directives and unescaped chord labels only', () {
    final chart = '''
{title: invented song}
[C]amber [G]bell carries quiet dreams across silver water
[Am]amber bell carries quiet dreams across silver water
[F]amber bell carries quiet dreams across silver water
[Dm]amber bell carries quiet dreams across silver water
''';

    expect(shortRecordingLyricAgreement(chart, _reference), isTrue);
    expect(
      shortRecordingLyricAgreement(r'\[C]amber bell', _reference),
      isFalse,
    );
  });

  test('requires sufficient reference length and distinct vocabulary', () {
    final twelveUnique = '''
amber bell carries quiet dreams across silver water
restless lanterns follow distant voices beyond morning
amber bell carries quiet dreams across silver water
restless lanterns follow distant voices beyond morning
''';
    final tooShort = List.filled(2, _phrase).join('\n');
    final generic = List.filled(8, 'la la la').join('\n');

    expect(isShortRecordingLyricBody(twelveUnique), isFalse);
    expect(isShortRecordingLyricBody(tooShort), isFalse);
    expect(isShortRecordingLyricBody(generic), isFalse);
    expect(shortRecordingLyricAgreement(_chart, tooShort), isFalse);
  });

  test('enforces word-count, vocabulary, and line-count boundaries', () {
    final sixUnique = 'amber bell carries quiet dreams across';
    final minBody = List.filled(4, sixUnique).join('\n'); // 24 words.
    final maxBody = List.filled(40, sixUnique).join('\n'); // 240 words.
    final tooLong = '$maxBody\namber'; // 241 words.
    final fiveUnique = List.filled(
      6,
      'amber bell carries quiet dreams',
    ).join('\n');
    final threeLines = List.filled(3, '$_phrase amber').join('\n');

    expect(isShortRecordingLyricBody(minBody), isTrue);
    expect(isShortRecordingLyricBody(maxBody), isTrue);
    expect(isShortRecordingLyricBody(tooLong), isFalse);
    expect(isShortRecordingLyricBody(fiveUnique), isFalse);
    expect(isShortRecordingLyricBody(threeLines), isFalse);
  });

  test('keeps ñ and RTL letters distinct while matching accents', () {
    const reference = '''
el niño canta junto al río bajo la luna
el niño canta junto al río bajo la luna
el niño canta junto al río bajo la luna
el niño canta junto al río bajo la luna
''';
    const accentlessChart = '''
el nino canta junto al rio bajo la luna
el nino canta junto al rio bajo la luna
el nino canta junto al rio bajo la luna
el nino canta junto al rio bajo la luna
''';
    const rtl = '''
أغنية جميلة تشرق فوق المدينة كل صباح
أغنية جميلة تشرق فوق المدينة كل صباح
أغنية جميلة تشرق فوق المدينة كل صباح
أغنية جميلة تشرق فوق المدينة كل صباح
''';

    expect(isShortRecordingLyricBody(reference), isTrue);
    expect(shortRecordingLyricAgreement(accentlessChart, reference), isFalse);
    expect(isShortRecordingLyricBody(rtl), isTrue);
    expect(shortRecordingLyricAgreement(rtl, rtl), isTrue);
  });
}
