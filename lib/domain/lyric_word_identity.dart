import 'song_identity.dart' show normalizeNameIdentity;

final _chordProDirective = RegExp(r'\{[^}\n]*\}');
final _bracketedText = RegExp(r'(?<!\\)\[[^\]\n]*\]');

/// The words of a lyric or chart body for comparison: accents folded,
/// directives and bracketed chords or labels removed, names normalized.
List<String> lyricIdentityWords(String body) => normalizeNameIdentity(
  foldLyricVowelAccents(
    body,
  ).replaceAll(_chordProDirective, ' ').replaceAll(_bracketedText, ''),
).split(' ').where((word) => word.isNotEmpty).toList();

/// Comparison-only normalization for transcriptions that omit vowel accents.
/// It never rewrites displayed lyrics, artists or titles. Distinct consonants
/// such as ñ remain distinct; matching still needs the surrounding lyric text.
String foldLyricVowelAccents(String text) {
  var result = text;
  for (final (vowel, accented) in _accentedVowels) {
    result = result.replaceAllMapped(accented, (match) {
      final original = match[0]!;
      return original == original.toUpperCase() ? vowel.toUpperCase() : vowel;
    });
  }
  return result.replaceAllMapped(_combiningAccents, (match) => match[1]!);
}

final _accentedVowels = [
  for (final entry in const {
    'a': 'áàâäÁÀÂÄ',
    'e': 'éèêëÉÈÊË',
    'i': 'íìîïÍÌÎÏ',
    'o': 'óòôöÓÒÔÖ',
    'u': 'úùûüÚÙÛÜ',
  }.entries)
    (entry.key, RegExp('[${entry.value}]')),
];
final _combiningAccents = RegExp(r'([aeiouAEIOU])[\u0300\u0301\u0302\u0308]+');
