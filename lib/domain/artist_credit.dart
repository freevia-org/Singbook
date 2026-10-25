/// Whether two artist credits name the same act on a chord site: equal, or
/// one is the other's main credit ("Bob Marley" for "Bob Marley & The
/// Wailers", "Lady Gaga" for "Lady Gaga feat. Someone"). Only "&" and
/// featuring credits separate artists; "Florence and the Machine" and
/// "Florence + The Machine" are band names, not "Florence". A leading "The"
/// is ignored.
bool artistCreditsMatch(String a, String b, String Function(String) normalize) {
  // Chord sites often drop a leading article ("Goo Goo Dolls").
  String name(String artist) =>
      normalize(artist).replaceFirst(RegExp(r'^the '), '');
  final first = name(a), second = name(b);
  if (first.isEmpty || second.isEmpty) return false;
  if (first == second) return true;
  String main(String artist) => name(artist.split(_separators).first);
  return main(a) == second || first == main(b);
}

final _separators = RegExp(
  r'\s*(?:&|\bfeat\.?|\bft\.?|\bfeaturing\b)\s*',
  caseSensitive: false,
);
