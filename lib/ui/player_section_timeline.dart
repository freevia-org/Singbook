import 'verse_ui_state.dart';

/// Builds timeline markers at the first lyric line in each named section.
///
/// Saved recording cue starts take precedence when supplied. Unmapped sections
/// use the player's even-line estimated pace, keeping navigation available even
/// when a song has no active timing track.
List<PlayerSectionMarker> buildPlayerSectionMarkers({
  required List<LyricLineData> lines,
  required double durationSeconds,
  Map<String, double> timedLineStarts = const {},
}) {
  if (lines.isEmpty || !durationSeconds.isFinite || durationSeconds <= 0) {
    return const [];
  }

  final visibleLines = <LyricLineData>[];
  for (final line in lines) {
    if (line.section == null && !line.isBlank && line.text.trim().isNotEmpty) {
      visibleLines.add(line);
    }
  }
  if (visibleLines.isEmpty) return const [];

  final estimatedPositions = <String, double>{};
  for (var index = 0; index < visibleLines.length; index++) {
    estimatedPositions[visibleLines[index].id] =
        durationSeconds * index / visibleLines.length;
  }

  final markers = <PlayerSectionMarker>[];
  for (var index = 0; index < lines.length; index++) {
    final heading = lines[index];
    final name = heading.section?.trim();
    if (name == null || name.isEmpty) continue;

    var lineIndex = index + 1;
    while (lineIndex < lines.length && lines[lineIndex].section == null) {
      final candidate = lines[lineIndex];
      if (!candidate.isBlank && candidate.text.trim().isNotEmpty) break;
      lineIndex++;
    }
    if (lineIndex >= lines.length || lines[lineIndex].section != null) continue;

    final line = lines[lineIndex];
    if (line.isBlank || line.text.trim().isEmpty) continue;
    final rawStart = timedLineStarts[line.id] ?? estimatedPositions[line.id];
    final start = rawStart?.clamp(0.0, durationSeconds).toDouble();
    if (start == null || !start.isFinite) continue;

    // Repeated headings can share a start when a chart has no intervening line.
    if (markers.any((marker) => marker.startSeconds == start)) continue;
    markers.add(
      PlayerSectionMarker(name: name, startSeconds: start, lineId: line.id),
    );
  }
  return List.unmodifiable(markers);
}

/// Resolves section-aware previous/next navigation for the player controls.
///
/// Forward jumps to the next marker. Back restarts the current section after
/// its opening moment, and otherwise moves to the previous section.
double? playerSectionSkipTarget({
  required List<PlayerSectionMarker> markers,
  required double progressSeconds,
  required double durationSeconds,
  required int direction,
}) {
  if (markers.isEmpty || direction == 0) return null;
  final ordered = [...markers]
    ..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));
  final progress = progressSeconds.clamp(0.0, durationSeconds).toDouble();

  if (direction > 0) {
    return ordered
        .where((marker) => marker.startSeconds > progress + .5)
        .firstOrNull
        ?.startSeconds;
  }

  final currentIndex = ordered.lastIndexWhere(
    (marker) => marker.startSeconds <= progress + .5,
  );
  if (currentIndex < 0) return 0;
  final current = ordered[currentIndex];
  if (progress - current.startSeconds > 2) return current.startSeconds;
  return currentIndex > 0 ? ordered[currentIndex - 1].startSeconds : 0;
}
