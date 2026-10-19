import '../domain/combine.dart' show recordingCompatible;
import '../domain/models.dart';
import '../domain/song_identity.dart';

enum PlayerDurationKind {
  metadata,
  selectedRecording,
  recordingSource,
  catalogEstimate,
  chartEstimate,
}

class PlayerDuration {
  const PlayerDuration(this.seconds, this.kind);
  final double seconds;
  final PlayerDurationKind kind;
  bool get estimated =>
      kind == PlayerDurationKind.catalogEstimate ||
      kind == PlayerDurationKind.chartEstimate;
}

double? _seconds(Object? value) {
  if (value is! num) return null;
  final seconds = value.toDouble();
  return seconds.isFinite && seconds > 0 && seconds <= 86400 ? seconds : null;
}

List<double> _candidateDurations(SongCandidate candidate) => [
  for (final value in [
    candidate.durationSeconds,
    candidate.metadata['durationSeconds'],
    candidate.metadata['duration'],
  ])
    ?_seconds(value),
];

List<double> _sourceDurations(SourceResult source) => [
  ..._candidateDurations(source.candidate),
  for (final value in [
    source.metadata['durationSeconds'],
    source.metadata['duration'],
  ])
    ?_seconds(value),
];

double? _agreedDuration(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  if (sorted.last - sorted.first > 3) return null;
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

bool _recordingScope(Object? scope) => scope == null || scope == 'recording';

bool _accepted(SourceResult source) =>
    (source.matchKind == MatchKind.sameSong ||
        source.matchKind == MatchKind.sameRecording) &&
    source.extra['pendingMatchCheck'] != true;

Object? _sourceScope(SourceResult source) =>
    source.candidate.metadata['identityScope'] ??
    source.metadata['identityScope'] ??
    source.extra['identityScope'];

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

String? _albumIdentity(Object? value, String title) {
  if (value is! String || value.trim().isEmpty) return null;
  var album = value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  // These labels do not name another album or venue. Performance labels may
  // be omitted only when the exact matching title already retains that label.
  album = album.replaceAll(
    RegExp(r'\((?:deluxe|expanded)(?: edition)?\)'),
    ' ',
  );
  for (final label in const ['live', 'acoustic']) {
    if (RegExp('\\b$label\\b', caseSensitive: false).hasMatch(title)) {
      album = album.replaceAll('($label)', ' ');
    }
  }
  final normalized = _normalize(album);
  return normalized.isEmpty ? null : normalized;
}

String? _referenceAlbum(SongDocument song, SongCandidate selected) {
  for (final album in [song.metadata['album'], selected.album]) {
    if (album is String && album.trim().isNotEmpty) return album;
  }
  for (final source in song.sources) {
    if (!_accepted(source) || source.candidate.identity != selected.identity) {
      continue;
    }
    final album = source.candidate.album ?? source.metadata['album'];
    if (album is String && album.trim().isNotEmpty) return album;
  }
  return null;
}

bool _conflictingClaims(List<SourceResult> sources, String title) {
  final ids = <String, String>{};
  final versions = <String, String>{};
  var live = false, studio = false;
  String? knownAlbum;
  for (final source in sources) {
    final album = _albumIdentity(
      source.candidate.album ?? source.metadata['album'],
      title,
    );
    if (album != null) {
      if (knownAlbum != null && knownAlbum != album) return true;
      knownAlbum = album;
    }
    for (final entry in source.candidate.recordingIds.entries) {
      final previous = ids[entry.key];
      if (previous != null && previous != entry.value) return true;
      ids[entry.key] = entry.value;
    }
    for (final key in const ['recording', 'versionTitle', 'edition']) {
      final value = source.candidate.metadata[key] ?? source.metadata[key];
      if (value is! String || value.trim().isEmpty) continue;
      final normalized = _normalize(value);
      final previous = versions[key];
      if (previous != null && previous != normalized) return true;
      versions[key] = normalized;
    }
    final description = [
      source.candidate.title,
      source.candidate.album ?? source.metadata['album'] ?? '',
      source.candidate.metadata['recording'] ??
          source.metadata['recording'] ??
          '',
    ].join(' ');
    live |= RegExp(r'\blive\b', caseSensitive: false).hasMatch(description);
    studio |= RegExp(r'\bstudio\b', caseSensitive: false).hasMatch(description);
  }
  return live && studio;
}

bool _compatibleClaim(
  SongCandidate reference,
  SourceResult source,
  String? album,
) {
  if (!_accepted(source) ||
      !_recordingScope(reference.metadata['identityScope']) ||
      !_recordingScope(_sourceScope(source))) {
    return false;
  }
  final identity = librarySongIdentity(reference.title, reference.artist);
  if (identity == null ||
      identity !=
          librarySongIdentity(
            source.candidate.title,
            source.candidate.artist,
          )) {
    return false;
  }
  final selectedAlbum = _albumIdentity(album, reference.title);
  final foundAlbum = _albumIdentity(
    source.candidate.album ?? source.metadata['album'],
    reference.title,
  );
  if (selectedAlbum != null &&
      foundAlbum != null &&
      selectedAlbum != foundAlbum) {
    return false;
  }
  for (final entry in reference.recordingIds.entries) {
    final found = source.candidate.recordingIds[entry.key];
    if (found != null && found != entry.value) return false;
  }
  for (final key in const ['recording', 'versionTitle', 'edition']) {
    final selected = reference.metadata[key];
    final found = source.candidate.metadata[key] ?? source.metadata[key];
    if (selected is String &&
        found is String &&
        selected.trim().isNotEmpty &&
        found.trim().isNotEmpty &&
        _normalize(selected) != _normalize(found)) {
      return false;
    }
  }
  return true;
}

double _cueEndLowerBound(SongDocument song) {
  var seconds = 0.0;
  for (final track in song.timingTracks) {
    if (track.id != song.activeTimingTrackId ||
        track.status != TimingStatus.usable) {
      continue;
    }
    for (final cue in track.cues) {
      final end = (cue.endUs ?? cue.startUs) / 1000000;
      if (_seconds(end) != null && end > seconds) seconds = end;
    }
  }
  return seconds;
}

/// A display/scrolling duration, never a recording identity or cue binding.
/// Catalog consensus remains estimated: agreement cannot prove a performance.
/// The callback is lazy so known durations do not parse the arrangement.
PlayerDuration resolvePlayerDuration(
  SongDocument song, {
  required double Function() estimate,
}) {
  if (_seconds(song.metadata['durationSeconds']) case final seconds?) {
    return PlayerDuration(seconds, PlayerDurationKind.metadata);
  }
  final selected = song.selectedRecording;
  if (selected != null &&
      selected.providerId.trim().isNotEmpty &&
      selected.id.trim().isNotEmpty &&
      _recordingScope(selected.metadata['identityScope'])) {
    final selectedDuration = _agreedDuration(_candidateDurations(selected));
    if (selectedDuration != null) {
      return PlayerDuration(
        selectedDuration,
        PlayerDurationKind.selectedRecording,
      );
    }
    final recordingClaims = <double>[];
    for (final source in song.sources) {
      if (_accepted(source) &&
          _recordingScope(_sourceScope(source)) &&
          recordingCompatible(selected, source)) {
        recordingClaims.addAll(_sourceDurations(source));
      }
    }
    if (_agreedDuration(recordingClaims) case final seconds?) {
      return PlayerDuration(seconds, PlayerDurationKind.recordingSource);
    }

    final providers = <String, List<double>>{};
    final compatible = <SourceResult>[];
    final album = _referenceAlbum(song, selected);
    for (final source in song.sources) {
      if (!_compatibleClaim(selected, source, album)) continue;
      final values = _sourceDurations(source);
      final provider = source.candidate.providerId.trim();
      if (values.isEmpty || provider.isEmpty) continue;
      providers.putIfAbsent(provider, () => []).addAll(values);
      compatible.add(source);
    }
    // A provider duplicated in the saved history cannot corroborate itself.
    // Conflicting compatible claims block consensus instead of majority voting.
    if (providers.length >= 2 &&
        !_conflictingClaims(compatible, selected.title)) {
      final all = providers.values.expand((values) => values).toList();
      if (_agreedDuration(all) != null) {
        final independent = [
          for (final values in providers.values) _agreedDuration(values)!,
        ];
        final consensus = _agreedDuration(independent)!;
        if (consensus >= _cueEndLowerBound(song)) {
          return PlayerDuration(consensus, PlayerDurationKind.catalogEstimate);
        }
      }
    }
  }
  var seconds = estimate();
  if (_seconds(seconds) == null) seconds = 90;
  // A usable cue can extend the estimated clock, but its last lyric does not
  // establish the recording's total duration or change any cue timestamp.
  final cueFloor = _cueEndLowerBound(song);
  if (cueFloor > seconds) seconds = cueFloor;
  return PlayerDuration(seconds, PlayerDurationKind.chartEstimate);
}
