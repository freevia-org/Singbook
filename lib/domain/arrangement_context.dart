import 'edition_identity.dart';
import 'models.dart';

/// Whether [chart] is safe to resolve for lyric corroboration against
/// [selected]. A true result only admits a candidate to the lyrics check; it
/// never says that the chart belongs to the selected recording.
bool contextualArrangementCandidate(
  SongCandidate selected,
  SongCandidate chart,
) {
  if (!const {'songsterr', 'ultimateguitar'}.contains(chart.providerId)) {
    return false;
  }
  bool selectedScopeAllowed(SongCandidate candidate) {
    for (final facts in [candidate.metadata, candidate.extra]) {
      if (facts.containsKey('identityScope') &&
          facts['identityScope'] != 'recording') {
        return false;
      }
    }
    return true;
  }

  bool chartScopeAllowed(SongCandidate candidate) {
    for (final facts in [candidate.metadata, candidate.extra]) {
      if (facts.containsKey('identityScope') &&
          !{'recording', 'arrangement'}.contains(facts['identityScope'])) {
        return false;
      }
    }
    return true;
  }

  if (!selectedScopeAllowed(selected) ||
      !chartScopeAllowed(chart) ||
      !explicitEditionsCompatible(selected, chart)) {
    return false;
  }
  for (final entry in selected.recordingIds.entries) {
    if (chart.recordingIds.containsKey(entry.key) &&
        chart.recordingIds[entry.key] != entry.value) {
      return false;
    }
  }

  final songTitle = _words(selected.title);
  if (songTitle.isEmpty) return false;
  final chartTitle = _words(chart.title);

  // Direct composer/author evidence is accepted only from structured credits
  // in a supported role. Artist names, featured performers, labels, and
  // arbitrary metadata text are not treated as composition evidence.
  if (chartTitle == songTitle &&
      _selectedCreativeCreditNames(selected).contains(_words(chart.artist))) {
    return true;
  }

  final work = _soundtrackWork(selected.album);
  if (work == null) return false;
  final chartArtist = _words(chart.artist);
  if (chartTitle == songTitle && chartArtist == work) return true;

  // Category-style chart credits are accepted only when the title explicitly
  // anchors the exact song to the selected work. This prevents generic
  // soundtrack/film categories from widening the search across works.
  const categories = {
    'misc soundtrack',
    'misc cartoons',
    'misc television',
    'misc musicals',
    'misc movies',
    'misc broadway',
  };
  if (chart.providerId != 'ultimateguitar' ||
      !categories.contains(chartArtist)) {
    return false;
  }
  final match = RegExp(
    r'^\s*(.+?)\s+[-–—]\s+(.+?)\s*$',
  ).firstMatch(chart.title);
  return match != null &&
      _words(match[1]!) == work &&
      _words(match[2]!) == songTitle;
}

Set<String> _selectedCreativeCreditNames(SongCandidate selected) {
  const allowedRoles = {'writer', 'composer', 'music'};
  final names = <String>{};
  for (final facts in [selected.metadata, selected.extra]) {
    final credits = facts['credits'];
    if (credits is! List) continue;
    for (final raw in credits) {
      if (raw is! Map) continue;
      final role = raw['role'], name = raw['name'];
      if (role is String &&
          name is String &&
          allowedRoles.contains(_words(role)) &&
          _words(name).isNotEmpty) {
        names.add(_words(name));
      }
    }
  }
  return names;
}

/// Extract a work name only from a narrow, explicit album suffix.
String? _soundtrackWork(String? album) {
  if (album == null) return null;
  final match = RegExp(
    r'^\s*(.+?)\s*(?:\(\s*(?:original\s+motion\s+picture\s+soundtrack|motion\s+picture\s+soundtrack|original\s+soundtrack)\s*\)|\[\s*(?:original\s+motion\s+picture\s+soundtrack|motion\s+picture\s+soundtrack|original\s+soundtrack)\s*\])\s*$',
    caseSensitive: false,
  ).firstMatch(album);
  if (match == null) return null;
  final work = _words(match[1]!);
  return work.isEmpty ? null : work;
}

/// Comparison-only word normalization: punctuation and apostrophes are
/// ignored, but edition and part words remain in the comparison.
String _words(String value) => value
    .toLowerCase()
    .replaceAll(RegExp("['’‘]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();
