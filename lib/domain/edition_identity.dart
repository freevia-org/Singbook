import 'models.dart';
import 'song_identity.dart' show normalizeNameIdentity;

final _nonWordRun = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
final _editionNoun = RegExp(r'\b(?:version|recording|edition)\b');
final _spaceRun = RegExp(r'\s+');
final _performanceNoun = RegExp(
  r'\b(?:version|recording|performance|session)\b',
);

/// A bracketed or dash-separated qualifier at the end of or inside a title.
final _titleQualifier = RegExp(r'\(([^()]*)\)|\[([^\[\]]*)\]|\s[-–—]\s(.+)$');

const _familyWords =
    r'\b(studio|live|acoustic|remix|instrumental|karaoke|demo|remaster(?:ed)?|mono|stereo|radio edit)\b';
final _familyWord = RegExp(_familyWords, caseSensitive: false);

/// Case-sensitive on purpose: it only reads names [_normalizeEdition] made.
final _normalizedFamilyWord = RegExp(_familyWords);

String _normalizeEdition(String value) => value
    .toLowerCase()
    .replaceAll(_nonWordRun, ' ')
    .replaceAll(_editionNoun, ' ')
    .replaceAll(_spaceRun, ' ')
    .trim();

Set<String> _families(String value) =>
    _familyWord.allMatches(value).map((match) {
      final text = match.group(0)!.toLowerCase();
      return text == 'remastered' ? 'remaster' : text;
    }).toSet();

bool _contradictory(Set<String> families) =>
    (families.contains('studio') && families.contains('live')) ||
    (families.contains('mono') && families.contains('stereo'));

bool _descriptorsOnly(String name) =>
    name.replaceAll(_normalizedFamilyWord, '').trim().isEmpty;

({Set<String> names, Set<String> families}) _evidence(
  SongCandidate candidate,
  JsonMap metadata,
  JsonMap extra,
) {
  final names = <String>{};
  final families = <String>{};
  for (final map in [candidate.metadata, candidate.extra, metadata, extra]) {
    for (final key in ['version', 'edition', 'disambiguation', 'recording']) {
      final value = map[key];
      if (value is! String || value.trim().isEmpty) continue;
      families.addAll(_families(value));
      if (key == 'version' || key == 'edition') {
        final name = _normalizeEdition(value);
        if (name.isNotEmpty) names.add(name);
      }
    }
  }
  for (final match in _titleQualifier.allMatches(candidate.title)) {
    families.addAll(_families(match[1] ?? match[2] ?? match[3]!));
  }
  return (names: names, families: families);
}

/// Absence is unknown, not a studio/version claim. Contradictory explicit
/// edition evidence cannot establish recording, timing, or arrangement trust.
bool explicitEditionsCompatible(
  SongCandidate selected,
  SongCandidate candidate, {
  JsonMap selectedMetadata = const {},
  JsonMap selectedExtra = const {},
  JsonMap metadata = const {},
  JsonMap extra = const {},
}) {
  final first = _evidence(selected, selectedMetadata, selectedExtra);
  final second = _evidence(candidate, metadata, extra);
  if (_contradictory(first.families) ||
      _contradictory(second.families) ||
      _contradictory({...first.families, ...second.families})) {
    return false;
  }
  if ((first.names.length > 1 && !first.names.every(_descriptorsOnly)) ||
      (second.names.length > 1 && !second.names.every(_descriptorsOnly))) {
    return false;
  }
  if (first.names.isNotEmpty &&
      second.names.isNotEmpty &&
      !(first.names.length == 1 &&
          second.names.length == 1 &&
          first.names.single == second.names.single) &&
      !(first.names.every(_descriptorsOnly) &&
          second.names.every(_descriptorsOnly))) {
    return false;
  }
  return true;
}

/// Explicit performance markers shared by catalog validation and legacy credit
/// enrichment. Album packaging changes do not imply another performance.
Set<String> recordingVersionMarkers(String value, {bool album = false}) {
  final labels = album
      ? [value]
      : _titleQualifier
            .allMatches(value)
            .map((m) => m[1] ?? m[2] ?? m[3]!)
            .toList();
  final result = <String>{};
  for (final label in labels) {
    final text = normalizeNameIdentity(label);
    var remaining = text;
    final found = <String>{};
    for (final marker in [
      'live',
      'acoustic',
      'unplugged',
      'karaoke',
      'instrumental',
      'sped up',
      'slowed',
      'nightcore',
    ]) {
      final matches = RegExp('(?:^|\\s)$marker(?:\\s|\$)').hasMatch(text);
      if (!matches) continue;
      if (album) {
        final explicit =
            RegExp(
              '(?:[\\[(]\\s*|\\s[-–—]\\s+)$marker\\b',
              caseSensitive: false,
            ).hasMatch(value) ||
            (marker == 'live'
                ? RegExp(
                    r'^live(?:\s+\d{4})?\s*$|\blive\s+(?:at|in|from|on)\b|^live\s+\d{4}',
                    caseSensitive: false,
                  ).hasMatch(value)
                : RegExp('^$marker\\b', caseSensitive: false).hasMatch(value));
        if (!explicit) continue;
      }
      final version = marker == 'unplugged' ? 'acoustic' : marker;
      if (album) {
        result.add(version);
      } else {
        found.add(version);
        remaining = remaining.replaceAll(RegExp('\\b$marker\\b'), ' ');
      }
    }
    if (!album && remaining.replaceAll(_performanceNoun, ' ').trim().isEmpty) {
      result.addAll(found);
    }
  }
  return result;
}
