import 'models.dart';

/// A positive, finite length of at most a day, in seconds; null otherwise.
double? displaySeconds(Object? value) {
  if (value is! num) return null;
  final seconds = value.toDouble();
  return seconds.isFinite && seconds > 0 && seconds <= 86400 ? seconds : null;
}

/// The album a row states: its own field, then [metadata] (a resolved
/// source's facts, when there is one), then the row's metadata.
String? candidateAlbum(SongCandidate candidate, [JsonMap metadata = const {}]) {
  for (final value in [
    candidate.album,
    metadata['album'],
    candidate.metadata['album'],
  ]) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

/// The length a row states, read in the same order as [candidateAlbum].
double? candidateDuration(
  SongCandidate candidate, [
  JsonMap metadata = const {},
]) =>
    displaySeconds(candidate.durationSeconds) ??
    displaySeconds(metadata['durationSeconds']) ??
    displaySeconds(candidate.metadata['durationSeconds']) ??
    displaySeconds(metadata['duration']) ??
    displaySeconds(candidate.metadata['duration']);
