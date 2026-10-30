import 'edition_identity.dart';
import 'models.dart';

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
    // Broadcast lengths, edits and script labels describe a release, not a
    // name, and would otherwise make unrelated titles share an alias.
    r'\b(?:version|ver|live|acoustic|unplugged|translation|translated|translate|feat|featuring|ft|remix|remaster(?:ed)?|edit|cover|karaoke|instrumental|demo|tv|size|extended|ost|soundtrack|radio|mono|stereo|bonus|reprise|romanized|romaji)\b',
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

/// A matching publisher's Latin-script text is an alternative representation,
/// not a word-for-word corroboration of the selected non-Latin lyrics.
bool publishedLyricScriptAlternative(
  SongCandidate selected,
  SongCandidate source,
  String referenceBody,
  String sourceBody,
) {
  if ((publishedNameVariants(selected.title).length < 2 &&
          publishedNameVariants(selected.artist).length < 2) ||
      !publishedNamesMatch(selected.title, source.title) ||
      !publishedNamesMatch(selected.artist, source.artist) ||
      !explicitEditionsCompatible(selected, source) ||
      selected.recordingIds.entries.any(
        (entry) =>
            source.recordingIds.containsKey(entry.key) &&
            source.recordingIds[entry.key] != entry.value,
      )) {
    return false;
  }
  final selectedEditions = recordingVersionMarkers(
    selected.album ?? '',
    album: true,
  );
  final sourceEditions = recordingVersionMarkers(
    source.album ?? '',
    album: true,
  );
  if ((selectedEditions.difference(sourceEditions).isNotEmpty ||
          sourceEditions.difference(selectedEditions).isNotEmpty) &&
      (selected.album != null && source.album != null ||
          !recordingVersionMarkers(
            selected.title,
          ).containsAll({...selectedEditions, ...sourceEditions}))) {
    return false;
  }
  final letter = RegExp(r'\p{L}', unicode: true);
  final latin = RegExp(r'\p{Script=Latin}', unicode: true);
  ({int total, int latin}) counts(String body) {
    final text = body.replaceAll(RegExp(r'\{[^}\n]*\}|\[[^\]\n]*\]'), '');
    var total = 0, latinCount = 0;
    for (final match in letter.allMatches(text).take(10000)) {
      total++;
      if (latin.hasMatch(match[0]!)) latinCount++;
    }
    return (total: total, latin: latinCount);
  }

  final reference = counts(referenceBody), alternative = counts(sourceBody);
  return reference.total >= 24 &&
      alternative.total >= 24 &&
      reference.latin / reference.total < .25 &&
      alternative.latin / alternative.total > .9;
}
