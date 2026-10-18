import 'verse_ui_state.dart';

const _estimatedBoundaryToleranceSeconds = 0.000001;

/// Returns lyric rows that participate in estimated playback positions.
///
/// Blank rows and chord-only rows are visual structure, not lyric positions.
/// Named sections with no lyric rows get a separate slot in the estimated
/// timeline below.
bool _isEstimatedLyricLine(LyricLineData line) =>
    line.section == null && !line.isBlank && line.text.trim().isNotEmpty;

List<LyricLineData> estimatedTimelineLines(List<LyricLineData> lines) =>
    List.unmodifiable(lines.where(_isEstimatedLyricLine));

/// Adds one estimated time slot for each named section that has no lyric rows.
/// The heading ID represents that section while playback is in its slot.
List<String> _estimatedTimelineEventIds(List<LyricLineData> lines) {
  final events = <String>[];
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (line.section != null) {
      var hasLyrics = false;
      for (
        var next = index + 1;
        next < lines.length && lines[next].section == null;
        next++
      ) {
        if (_isEstimatedLyricLine(lines[next])) {
          hasLyrics = true;
          break;
        }
      }
      if (!hasLyrics) events.add(line.id);
    } else if (_isEstimatedLyricLine(line)) {
      events.add(line.id);
    }
  }
  return events;
}

Map<String, double> _estimatedLineStartTimes(
  List<LyricLineData> lines,
  double durationSeconds,
) {
  if (!durationSeconds.isFinite || durationSeconds <= 0) return const {};
  final events = _estimatedTimelineEventIds(lines);
  if (events.isEmpty) return const {};
  return Map.unmodifiable({
    for (var index = 0; index < events.length; index++)
      events[index]: durationSeconds * index / events.length,
  });
}

/// Returns the estimated start time used for [lineId], including headings for
/// lyric-free sections, or null when it is not in the timeline.
double? estimatedLineStartSeconds(
  List<LyricLineData> lines,
  String lineId,
  double durationSeconds,
) => _estimatedLineStartTimes(lines, durationSeconds)[lineId];

/// Resolves the active lyric or lyric-free section at [progressSeconds] using
/// the same boundaries as section markers. The small tolerance makes an exact
/// seek to a marker select its timeline event even if rounding falls short.
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
  final events = _estimatedTimelineEventIds(lines);
  if (events.isEmpty) return null;
  final starts = _estimatedLineStartTimes(lines, durationSeconds);
  final progress = progressSeconds.clamp(0.0, durationSeconds).toDouble();
  var current = events.first;
  for (final lineId in events.skip(1)) {
    final start = starts[lineId]!;
    if (start > progress + _estimatedBoundaryToleranceSeconds) break;
    current = lineId;
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

  final estimatedPositions = _estimatedLineStartTimes(lines, durationSeconds);

  final markers = <PlayerSectionMarker>[];
  for (var index = 0; index < lines.length; index++) {
    final heading = lines[index];
    final name = heading.section?.trim();
    if (name == null || name.isEmpty) continue;

    var lineIndex = index + 1;
    while (lineIndex < lines.length && lines[lineIndex].section == null) {
      if (_isEstimatedLyricLine(lines[lineIndex])) break;
      lineIndex++;
    }
    final hasLyrics =
        lineIndex < lines.length &&
        lines[lineIndex].section == null &&
        _isEstimatedLyricLine(lines[lineIndex]);
    final lineId = hasLyrics ? lines[lineIndex].id : heading.id;
    final rawStart = hasLyrics
        ? timedLineStarts[lineId] ?? estimatedPositions[lineId]
        : estimatedPositions[heading.id];
    final start = rawStart?.clamp(0.0, durationSeconds).toDouble();
    if (start == null || !start.isFinite) continue;

    // Repeated headings can share a start when a chart has no intervening line.
    if (markers.any((marker) => marker.startSeconds == start)) continue;
    markers.add(
      PlayerSectionMarker(name: name, startSeconds: start, lineId: lineId),
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
