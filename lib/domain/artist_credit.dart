import 'edition_identity.dart';
import 'models.dart';

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

/// Compatibility for saved Genius rows parsed before joint primary credits
/// were retained. This only enriches the artist credit of the identical catalog
/// record, with structured evidence; it never matches a solo to another duet ID.
bool sameGeniusPrimaryCredit(
  SongCandidate a,
  SongCandidate b,
  String Function(String) normalize,
) {
  if (a.providerId != 'genius' ||
      b.providerId != 'genius' ||
      a.id != b.id ||
      !RegExp(r'^\d+$').hasMatch(a.id) ||
      !explicitEditionsCompatible(a, b)) {
    return false;
  }
  for (final candidate in [a, b]) {
    for (final facts in [candidate.metadata, candidate.extra]) {
      final scope = facts['identityScope'];
      if (scope != null && scope != 'recording') return false;
    }
  }
  for (final entry in a.recordingIds.entries) {
    if (b.recordingIds.containsKey(entry.key) &&
        b.recordingIds[entry.key] != entry.value) {
      return false;
    }
  }
  if (a.album != null && b.album != null) {
    final first = recordingVersionMarkers(a.album!, album: true);
    final second = recordingVersionMarkers(b.album!, album: true);
    if (first.difference(second).isNotEmpty ||
        second.difference(first).isNotEmpty) {
      return false;
    }
  }
  // Callers retain their existing duration checks. Harmless album packaging
  // corrections do not become stricter merely because a credit is enriched.

  bool enriches(SongCandidate old, SongCandidate full) {
    final credits = full.metadata['credits'];
    if (credits is! List) return false;
    final names = <String>[];
    final seen = <String>{};
    for (final credit in credits) {
      if (credit is! Map ||
          credit['role'] != 'Artist' ||
          credit['name'] is! String) {
        continue;
      }
      final name = (credit['name'] as String).trim();
      if (name.isNotEmpty && seen.add(normalize(name))) names.add(name);
    }
    return names.length > 1 &&
        normalize(old.artist) == normalize(names.first) &&
        normalize(full.artist) == normalize(names.join(' & '));
  }

  return enriches(a, b) || enriches(b, a);
}
