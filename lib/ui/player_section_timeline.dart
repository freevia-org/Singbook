import 'verse_ui_state.dart';

const _estimatedBoundaryToleranceSeconds = 0.000001;

/// Returns lyric lines that participate in estimated playback positions.
///
/// Section headings, blank rows, and chord-only rows are visual structure,
/// not lyric positions. Sharing this filter keeps section seeks aligned with
/// the reader's estimated current-line highlight.
List<LyricLineData> estimatedTimelineLines(List<LyricLineData> lines) =>
    List.unmodifiable(
      lines.where(
        (line) =>
            line.section == null &&
            !line.isBlank &&
            line.text.trim().isNotEmpty,
      ),
    );

Map<String, double> _estimatedLineStartTimes(
  List<LyricLineData> lines,
  double durationSeconds,
) {
  if (!durationSeconds.isFinite || durationSeconds <= 0) return const {};
  final visibleLines = estimatedTimelineLines(lines);
  if (visibleLines.isEmpty) return const {};
  return Map.unmodifiable({
    for (var index = 0; index < visibleLines.length; index++)
      visibleLines[index].id: durationSeconds * index / visibleLines.length,
  });
}

/// Returns the estimated start time used for [lineId], or null when the line
/// is not a lyric line in this timeline or the duration is invalid.
double? estimatedLineStartSeconds(
  List<LyricLineData> lines,
  String lineId,
  double durationSeconds,
) => _estimatedLineStartTimes(lines, durationSeconds)[lineId];

/// Resolves the lyric line at [progressSeconds] using the same boundaries as
/// section markers. The small tolerance makes an exact seek to a marker select
/// the line at that marker even if the fraction calculation rounds down.
String? estimatedLineIdAtPosition(
  List<LyricLineData> lines, {
  required double progressSeconds,
  required double durationSeconds,
}) {
  if (!progressSeconds.isFinite ||
      !durationSeconds.isFinite ||
      durationSeconds <= 0) {
    return null;
  }
  final visibleLines = estimatedTimelineLines(lines);
  if (visibleLines.isEmpty) return null;
  final starts = _estimatedLineStartTimes(visibleLines, durationSeconds);
  final progress = progressSeconds.clamp(0.0, durationSeconds).toDouble();
  var current = visibleLines.first.id;
  for (final line in visibleLines.skip(1)) {
    final start = starts[line.id]!;
    if (start > progress + _estimatedBoundaryToleranceSeconds) break;
    current = line.id;
  }
  return current;
}

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

  final visibleLines = estimatedTimelineLines(lines);
  if (visibleLines.isEmpty) return const [];

  final estimatedPositions = _estimatedLineStartTimes(
    visibleLines,
    durationSeconds,
  );

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
