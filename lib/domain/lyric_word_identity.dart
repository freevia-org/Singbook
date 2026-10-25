/// Comparison-only normalization for transcriptions that omit vowel accents.
/// It never rewrites displayed lyrics, artists or titles. Distinct consonants
/// such as ñ remain distinct; matching still needs the surrounding lyric text.
String foldLyricVowelAccents(String text) {
  const groups = {
    'a': 'áàâäÁÀÂÄ',
    'e': 'éèêëÉÈÊË',
    'i': 'íìîïÍÌÎÏ',
    'o': 'óòôöÓÒÔÖ',
    'u': 'úùûüÚÙÛÜ',
  };
  var result = text;
  for (final entry in groups.entries) {
    result = result.replaceAllMapped(RegExp('[${entry.value}]'), (match) {
      final original = match[0]!;
      return original == original.toUpperCase()
          ? entry.key.toUpperCase()
          : entry.key;
    });
  }
  return result.replaceAllMapped(
    RegExp(r'([aeiouAEIOU])[\u0300\u0301\u0302\u0308]+'),
    (match) => match[1]!,
  );
}
