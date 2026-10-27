/// Returns the original name and, when it is explicitly published in
/// parentheses after a non-Latin name, its safe Latin-script alias.
///
/// This intentionally does not transliterate names or accept edition,
/// translation, or featuring qualifiers as aliases.
List<String> publishedNameVariants(String value) {
  final original = value.trim();
  if (original.isEmpty) return const [];
  final variants = <String>[original];
  final match = RegExp(r'^(.+?)\s*\(([^()]*)\)\s*$').firstMatch(original);
  if (match == null) return variants;
  final publishedName = match[1]!.trim();
  final alias = match[2]!.trim();
  if (publishedName.isEmpty || alias.isEmpty) return variants;

  final letters = RegExp(r'\p{L}', unicode: true);
  final latin = RegExp(r'\p{Script=Latin}', unicode: true);
  final outsideLetters = letters.allMatches(publishedName).toList();
  final aliasLetters = letters.allMatches(alias).toList();
  if (outsideLetters.isEmpty ||
      !outsideLetters.any((letter) => !latin.hasMatch(letter[0]!)) ||
      aliasLetters.isEmpty ||
      aliasLetters.any((letter) => !latin.hasMatch(letter[0]!))) {
    return variants;
  }

  final words = alias.toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}]+', unicode: true),
    ' ',
  );
  if (RegExp(
    r'\b(?:version|live|acoustic|unplugged|translation|translated|translate|feat|featuring|ft|remix|remaster(?:ed)?|edit|cover|karaoke|instrumental|demo)\b',
  ).hasMatch(words)) {
    return variants;
  }
  variants.add(alias);
  return variants;
}

/// Compares names by normalized equality, including only explicitly
/// published aliases returned by [publishedNameVariants].
bool publishedNamesMatch(String first, String second) {
  String normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp("['‘’]"), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  final left = publishedNameVariants(first).map(normalize).toSet();
  final right = publishedNameVariants(second).map(normalize).toSet();
  return left.intersection(right).any((value) => value.isNotEmpty);
}
