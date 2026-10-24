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
    r'live|acoustic|remix|instrumental|karaoke|demo|remaster(?:ed)?|mix|version|edit|mono|stereo|session|unplugged|cover';

/// Title identity without bracketed credits such as "(Leonard Cohen)" or
/// "(feat. Someone)". Brackets naming an edition ("(Live)", "(Wedding
/// Version)") stay, because they name another recording.
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
  /// Members never disagree on a known album or duration (see
  /// [groupSearchRecordings]).
  String? get album =>
      _album(representative) ?? members.map(_album).nonNulls.firstOrNull;
  double? get durationSeconds =>
      _duration(representative) ?? members.map(_duration).nonNulls.firstOrNull;
  String? get artworkUrl =>
      _artwork(representative) ?? members.map(_artwork).nonNulls.firstOrNull;
}

class _Group {
  _Group(this.key, this.baseKey, SongCandidate row, int index)
    : album = _album(row),
      duration = _duration(row) {
    add(row, index);
  }

  /// Exact title, artist and edition; null for a row that stays alone.
  final String? key;

  /// [key] with bracketed credits removed from the title.
  final String? baseKey;
  final members = <({SongCandidate row, int index})>[];
  String? album;
  double? duration;

  int get first => members.first.index;

  void add(SongCandidate row, int index) {
    members.add((row: row, index: index));
    album ??= _album(row);
    duration ??= _duration(row);
  }

  bool agreesWith(String? otherAlbum, double? otherDuration) =>
      !(album != null &&
          otherAlbum != null &&
          _albumIdentity(album!) != _albumIdentity(otherAlbum)) &&
      !(duration != null &&
          otherDuration != null &&
          (duration! - otherDuration).abs() > 3);

  bool compatible(SongCandidate row) => !members.any(
    (member) =>
        member.row.recordingIds.entries.any(
          (e) =>
              row.recordingIds.containsKey(e.key) &&
              row.recordingIds[e.key] != e.value,
        ) ||
        !explicitEditionsCompatible(member.row, row),
  );
}

/// Collapses search rows that name the same recording into one group, keeping
/// the rows' rank order (a group sits where its best ranked row was).
///
/// Rows join a group when they have the same title, artist and explicit
/// edition text, compatible editions and no conflicting recording IDs, and do
/// not contradict the group's known album or duration (within 3 seconds). A
/// row without album or duration joins the first matching group.
///
/// Groups whose titles differ only by a bracketed credit ("Hallelujah" and
/// "Hallelujah (Leonard Cohen)") merge only when both know a duration and the
/// durations agree, so a credit alone never joins two recordings.
///
/// Grouping only shapes the list: every row keeps its identity, and the
/// representative is what a tap opens. Historical text and non-recording
/// scopes stay alone.
List<SearchRecordingGroup> groupSearchRecordings(
  Iterable<SongCandidate> ranked, {
  String? preferredProviderId,
}) {
  final groups = <_Group>[];
  var index = 0;
  for (final row in ranked) {
    final title = _identity(row.title), artist = _identity(row.artist);
    if (_ungroupable(row) || title.isEmpty || artist.isEmpty) {
      groups.add(_Group(null, null, row, index++));
      continue;
    }
    final edition = _edition(row);
    final key = '$title\u0000$artist\u0000$edition';
    final album = _album(row), duration = _duration(row);
    final group = groups
        .where(
          (group) =>
              group.key == key &&
              group.agreesWith(album, duration) &&
              group.compatible(row),
        )
        .firstOrNull;
    if (group != null) {
      group.add(row, index++);
    } else {
      final base = _baseTitle(row.title);
      groups.add(
        _Group(
          key,
          base.isEmpty ? null : '$base\u0000$artist\u0000$edition',
          row,
          index++,
        ),
      );
    }
  }
  // Merge credit-only title variants, earlier groups absorbing later ones.
  for (var i = 0; i < groups.length; i++) {
    final target = groups[i];
    if (target.baseKey == null || target.duration == null) continue;
    for (var j = i + 1; j < groups.length; j++) {
      final other = groups[j];
      if (other.baseKey != target.baseKey ||
          other.duration == null ||
          !target.agreesWith(other.album, other.duration) ||
          other.members.any((member) => !target.compatible(member.row))) {
        continue;
      }
      for (final member in other.members) {
        target.add(member.row, member.index);
      }
      groups.removeAt(j--);
    }
  }
  return [
    for (final group in groups..sort((a, b) => a.first.compareTo(b.first)))
      () {
        final members = [
          for (final member
              in group.members..sort((a, b) => a.index.compareTo(b.index)))
            member.row,
        ];
        return SearchRecordingGroup._(
          List.unmodifiable(members),
          members
                  .where((member) => member.providerId == preferredProviderId)
                  .firstOrNull ??
              members.first,
        );
      }(),
  ];
}
