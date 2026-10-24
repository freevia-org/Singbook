import 'edition_identity.dart';
import 'models.dart';

String _identity(String value) => value
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

String? _album(SongCandidate candidate) {
  for (final value in [candidate.album, candidate.metadata['album']]) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

double? _seconds(Object? value) {
  if (value is! num) return null;
  final seconds = value.toDouble();
  return seconds.isFinite && seconds > 0 && seconds <= 86400 ? seconds : null;
}

double? _duration(SongCandidate candidate) =>
    _seconds(candidate.durationSeconds) ??
    _seconds(candidate.metadata['durationSeconds']) ??
    _seconds(candidate.metadata['duration']);

String? _artwork(SongCandidate candidate) {
  final value = candidate.metadata['artworkUrl'];
  final uri = value is String ? Uri.tryParse(value.trim()) : null;
  return uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? (value as String).trim()
      : null;
}

/// Album identity without release-format suffixes, so "Hallelujah - EP" and
/// "Hallelujah" name the same release.
String _albumIdentity(String album) => _identity(
  album.replaceAll(
    RegExp(
      r'\s*(?:[-–—]\s*(?:ep|single)|[(\[](?:ep|single)[)\]])\s*$',
      caseSensitive: false,
    ),
    '',
  ),
);

const _editionWords =
    r'live|acoustic|remix|instrumental|karaoke|demo|remaster(?:ed)?|mix|version|edit|mono|stereo|session|unplugged|cover|part|pt|reprise|interlude|intro|outro|medley|vol(?:ume)?';

/// Title identity without bracketed credits such as "(Leonard Cohen)" or
/// "(feat. Someone)". Brackets naming an edition or part ("(Live)", "(Wedding
/// Version)", "(Part 2)") stay, because they name another recording.
String _baseTitle(String title) => _identity(
  title.replaceAllMapped(RegExp(r'\s*[(\[]([^()\[\]]*)[)\]]'), (match) {
    final inner = match[1]!;
    return RegExp(
          '\\b(?:$_editionWords)\\b',
          caseSensitive: false,
        ).hasMatch(inner)
        ? match[0]!
        : '';
  }),
);

/// Explicit edition text, such as a "Live" version field. Rows group only with
/// the same text, so a labelled edition is never folded into unlabelled rows
/// (which [explicitEditionsCompatible] alone would allow, as absence is
/// unknown there).
String _edition(SongCandidate candidate) => {
  for (final map in [candidate.metadata, candidate.extra])
    for (final key in ['version', 'edition', 'recording'])
      if (map[key] is String && _identity(map[key] as String).isNotEmpty)
        _identity(map[key] as String),
}.join(' ');

/// Rows that never join a group: they name something other than one
/// recording, or still await a match check.
bool _ungroupable(SongCandidate candidate) {
  const scopes = {
    'historicalText',
    'composition',
    'work',
    'artist',
    'image',
    'arrangement',
  };
  return candidate.providerId == 'wikisource' ||
      scopes.contains(candidate.metadata['identityScope']) ||
      scopes.contains(candidate.extra['identityScope']) ||
      candidate.metadata['pendingMatchCheck'] == true ||
      candidate.extra['pendingMatchCheck'] == true;
}

/// One recording found by one or more catalogs in a search.
class SearchRecordingGroup {
  SearchRecordingGroup._(this.members, this.representative);

  /// Every row of this recording, in search rank order.
  final List<SongCandidate> members;

  /// The row opened for the group: the preferred catalog's row when the
  /// group has one, otherwise the best ranked row.
  final SongCandidate representative;

  /// Display facts: the representative's own value, else the first member's.
  /// Members never disagree on a known album (see [groupSearchRecordings]);
  /// catalogs may report slightly different durations for one recording.
  String? get album =>
      _album(representative) ?? members.map(_album).nonNulls.firstOrNull;
  double? get durationSeconds =>
      _duration(representative) ?? members.map(_duration).nonNulls.firstOrNull;
  String? get artworkUrl =>
      _artwork(representative) ?? members.map(_artwork).nonNulls.firstOrNull;
}

class _Group {
  _Group(this.key, SongCandidate row) {
    add(row);
  }

  /// Title without credits, artist and edition; null for a row kept alone.
  final String? key;
  final members = <SongCandidate>[];
  String? album;

  void add(SongCandidate row) {
    members.add(row);
    album ??= _album(row);
  }

  bool accepts(SongCandidate row) {
    final other = _album(row);
    if (album != null &&
        other != null &&
        _albumIdentity(album!) != _albumIdentity(other)) {
      return false;
    }
    return !members.any(
      (member) =>
          member.recordingIds.entries.any(
            (e) =>
                row.recordingIds.containsKey(e.key) &&
                row.recordingIds[e.key] != e.value,
          ) ||
          !explicitEditionsCompatible(member, row),
    );
  }
}

/// Collapses search rows that name the same recording into one group, keeping
/// the rows' rank order (a group sits where its best ranked row was).
///
/// Rows join a group when their title (ignoring bracketed credits such as
/// "(Leonard Cohen)"), artist and explicit edition text match, their albums
/// match or one is unknown (EP and single suffixes ignored), editions are
/// compatible and recording IDs do not conflict. A row without an album joins
/// the first matching group. Durations never split a group: catalogs report
/// one recording with different lengths.
///
/// Grouping only shapes the list: every row keeps its identity, and the
/// representative is what a tap opens. Historical text and non-recording
/// scopes stay alone.
List<SearchRecordingGroup> groupSearchRecordings(
  Iterable<SongCandidate> ranked, {
  String? preferredProviderId,
}) {
  final groups = <_Group>[];
  for (final row in ranked) {
    final artist = _identity(row.artist);
    final base = _baseTitle(row.title);
    final title = base.isNotEmpty ? base : _identity(row.title);
    if (_ungroupable(row) || title.isEmpty || artist.isEmpty) {
      groups.add(_Group(null, row));
      continue;
    }
    final key = '$title\u0000$artist\u0000${_edition(row)}';
    final group = groups
        .where((group) => group.key == key && group.accepts(row))
        .firstOrNull;
    if (group != null) {
      group.add(row);
    } else {
      groups.add(_Group(key, row));
    }
  }
  return [
    for (final group in groups)
      SearchRecordingGroup._(
        List.unmodifiable(group.members),
        group.members
                .where((member) => member.providerId == preferredProviderId)
                .firstOrNull ??
            group.members.first,
      ),
  ];
}
