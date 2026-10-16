import 'models.dart';

/// Providers that supplied the chosen lyrics, retained metadata, or usable
/// timing. Provenance can retain rejected alternatives; those are not evidence
/// that their content contributed to the combined version.
Set<String> contributingProviderIds(SongDocument song) {
  final sourceIds = <String>{
    if (song.extra['selectedSourceId'] is String)
      song.extra['selectedSourceId'] as String,
  };
  final chordSources = song.extra['chordSourceIds'];
  if (chordSources is List) {
    sourceIds.addAll(chordSources.whereType<String>());
  }
  for (final origin in jsonMap(song.extra['fieldOrigins']).entries) {
    final value = song.metadata[origin.key];
    if (value != null && value != '' && origin.value is String) {
      sourceIds.add(origin.value as String);
    }
  }
  for (final track in song.timingTracks) {
    if (track.status != TimingStatus.usable || track.cues.isEmpty) continue;
    final sourceId = jsonMap(track.extra['binding'])['sourceId'];
    if (sourceId is String) sourceIds.add(sourceId);
  }
  return {
    for (final source in song.sources)
      if ((source.matchKind != MatchKind.rejected ||
              source.id == song.extra['selectedSourceId']) &&
          sourceIds.contains(source.id))
        source.candidate.providerId,
    if (song.selectedRecording case final recording?)
      if (sourceIds.contains(recording.identity) ||
          (song.title.isNotEmpty &&
              song.title == recording.title &&
              song.artist == recording.artist))
        recording.providerId,
  };
}
