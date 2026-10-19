import 'verse_ui_state.dart';

const _estimatedBoundaryToleranceSeconds = 0.000001;

final _progressionNote = RegExp(
  r'^(?:(?:[x×]\s*\d{1,2}|\d{1,2}\s*[x×])|bis|twice|repeat(?:\s*[x×]?\s*\d{1,2})?)$',
  caseSensitive: false,
);

bool _isChordProgression(LyricLineData line) {
  if (line.section != null || line.isArrangementNote || line.chords.isEmpty) {
    return false;
  }
  final text = line.text.replaceAll(RegExp(r'[\s|:()\[\].-]+'), '').trim();
  return text.isEmpty || text.length <= 32 && _progressionNote.hasMatch(text);
}

bool _isEstimatedLyricLine(LyricLineData line) =>
    line.section == null &&
    !line.isBlank &&
    !line.isArrangementNote &&
    !_isChordProgression(line) &&
    line.text.trim().isNotEmpty;

double _progressionWeight(LyricLineData line) {
  final text = line.text.toLowerCase();
  final repeat = RegExp(
    r'(?:[x×]\s*(\d{1,2})|(\d{1,2})\s*[x×])',
  ).firstMatch(text);
  final count = repeat == null
      ? (text.contains('bis') ||
                text.contains('twice') ||
                text.contains('repeat')
            ? 2
            : 1)
      : int.parse(repeat.group(1) ?? repeat.group(2)!);
  // A progression is a phrase-sized estimate, not a claim about its bars.
  return ((line.chords.length / 4).clamp(1, 4) * count.clamp(1, 8))
      .clamp(1, 8)
      .toDouble();
}

List<({String id, double weight})> _estimatedEvents(List<LyricLineData> lines) {
  final accompaniment = <String>{};
  var lyricAhead = false;
  for (final line in lines.reversed) {
    if (line.section != null ||
        line.isArrangementNote ||
        line.isBlank && line.chords.isEmpty) {
      lyricAhead = false;
    } else if (_isEstimatedLyricLine(line)) {
      lyricAhead = true;
    } else if (_isChordProgression(line) && lyricAhead) {
      // Separate chord rows directly above singing accompany the lyric.
      accompaniment.add(line.id);
    }
  }
  final events = <({String id, double weight})>[];
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (line.section != null) {
      var hasLyrics = false;
      var progressions = 0.0;
      var end = index + 1;
      for (; end < lines.length && lines[end].section == null; end++) {
        if (_isEstimatedLyricLine(lines[end])) hasLyrics = true;
        if (_isChordProgression(lines[end])) {
          progressions += _progressionWeight(lines[end]);
        }
      }
      if (!hasLyrics) {
        // Keep a lyric-free section seekable at its heading, and allow a
        // longer hold for progressions/repeats without inventing timestamps.
        events.add((
          id: line.id,
          weight: (1 + progressions / 2).clamp(1, 4).toDouble(),
        ));
        index = end - 1;
      }
    } else if (_isEstimatedLyricLine(line)) {
      events.add((id: line.id, weight: 1));
    } else if (_isChordProgression(line) && !accompaniment.contains(line.id)) {
      events.add((id: line.id, weight: _progressionWeight(line)));
    }
  }
  return events;
}

/// Music positions include standalone progressions and lyric-free sections.
List<LyricLineData> estimatedTimelineLines(List<LyricLineData> lines) {
  final ids = _estimatedEvents(lines).map((event) => event.id).toSet();
  return List.unmodifiable(lines.where((line) => ids.contains(line.id)));
}

/// Unknown lengths remain a rough chart estimate, with additional allowance
/// for instrumental phrases. Catalog/recording evidence should take priority.
double estimateChartDuration(List<LyricLineData> lines) {
  final events = _estimatedEvents(lines);
  final total = events.fold<double>(0, (sum, event) => sum + event.weight);
  return (total * 3.4).clamp(90, 600).toDouble();
}

Map<String, double> estimatedLineStartTimes(
  List<LyricLineData> lines,
  double durationSeconds,
) {
  if (!durationSeconds.isFinite || durationSeconds <= 0) return const {};
  final events = _estimatedEvents(lines);
  if (events.isEmpty) return const {};
  final total = events.fold<double>(0, (sum, event) => sum + event.weight);
  var elapsed = 0.0;
  final starts = <String, double>{};
  for (final event in events) {
    starts[event.id] = durationSeconds * elapsed / total;
    elapsed += event.weight;
  }
  return Map.unmodifiable(starts);
}

/// Returns the estimated start time used for [lineId], including headings for
/// lyric-free sections, or null when it is not in the timeline.
double? estimatedLineStartSeconds(
  List<LyricLineData> lines,
  String lineId,
  double durationSeconds,
) => estimatedLineStartTimes(lines, durationSeconds)[lineId];

/// Resolves the active lyric or lyric-free section at [progressSeconds] using
/// the same boundaries as section markers. The small tolerance makes an exact
/// seek to a marker select its timeline event even if rounding falls short.
String? estimatedLineIdAtPosition(
  List<LyricLineData> lines, {
  required double progressSeconds,
  required double durationSeconds,
  Map<String, double>? lineStartTimes,
}) {
  if (!progressSeconds.isFinite ||
      !durationSeconds.isFinite ||
      durationSeconds <= 0) {
    return null;
  }
  final starts =
      lineStartTimes ?? estimatedLineStartTimes(lines, durationSeconds);
  if (starts.isEmpty) return null;
  final progress = progressSeconds.clamp(0.0, durationSeconds).toDouble();
  var current = starts.keys.first;
  for (final lineId in starts.keys.skip(1)) {
    final start = starts[lineId]!;
    if (start > progress + _estimatedBoundaryToleranceSeconds) break;
    current = lineId;
  }
  return current;
}

/// Builds timeline markers at the first lyric line in each named section.
///
/// Saved recording cue starts take precedence when supplied. Unmapped sections
/// use the player's weighted estimated pace, keeping navigation available even
/// when a song has no active timing track.
List<PlayerSectionMarker> buildPlayerSectionMarkers({
  required List<LyricLineData> lines,
  required double durationSeconds,
  Map<String, double> timedLineStarts = const {},
  bool useEstimatedFallback = true,
}) {
  if (lines.isEmpty || !durationSeconds.isFinite || durationSeconds <= 0) {
    return const [];
  }

  final estimatedPositions = estimatedLineStartTimes(lines, durationSeconds);

  final markers = <PlayerSectionMarker>[];
  for (var index = 0; index < lines.length; index++) {
    final heading = lines[index];
    final name = heading.section?.trim();
    if (name == null || name.isEmpty) continue;

    var lineIndex = index + 1;
    while (lineIndex < lines.length && lines[lineIndex].section == null) {
      if (useEstimatedFallback
          ? estimatedPositions.containsKey(lines[lineIndex].id)
          : _isEstimatedLyricLine(lines[lineIndex])) {
        break;
      }
      lineIndex++;
    }
    final hasPosition =
        lineIndex < lines.length &&
        lines[lineIndex].section == null &&
        (useEstimatedFallback
            ? estimatedPositions.containsKey(lines[lineIndex].id)
            : _isEstimatedLyricLine(lines[lineIndex]));
    if (!hasPosition && !useEstimatedFallback) continue;
    final lineId = hasPosition ? lines[lineIndex].id : heading.id;
    final rawStart =
        timedLineStarts[lineId] ??
        (useEstimatedFallback ? estimatedPositions[lineId] : null);
    final start = rawStart?.clamp(0.0, durationSeconds).toDouble();
    if (start == null || !start.isFinite) continue;

    // Repeated headings can share a start when a chart has no intervening line.
    if (markers.any((marker) => marker.startSeconds == start)) continue;
    markers.add(
      PlayerSectionMarker(name: name, startSeconds: start, lineId: lineId),
    );
  }
  markers.sort((a, b) => a.startSeconds.compareTo(b.startSeconds));
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
