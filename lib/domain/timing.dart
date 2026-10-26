import 'dart:convert';
import 'dart:math' show max, min;
import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';
import 'models.dart';
import 'arrangement.dart';

/// Largest timing payload that is parsed and retained. The raw text is stored
/// twice in a song file (decoded `raw` asset plus `rawBytesBase64`, each
/// base64), so this keeps a valid track well inside the 12 MiB file limit.
const maxTimingBytes = 3 * 1024 * 1024;

/// Latest cue time accepted (7 days); the song codec enforces the same bound.
const _maxCueUs = 604800000000;
const _maxLrcTimestampsPerLine = 64;
const _maxCues = 100000;

/// Profile and recording change how a document is interpreted, so they take part
/// in the id; without either the id is the historic `source:hash(raw)`.
String _trackId(
  String source,
  String raw, {
  String? profile,
  String? recordingId,
}) {
  final key = profile == null && recordingId == null
      ? raw
      : '$raw\u0000${profile ?? ''}\u0000${recordingId ?? ''}';
  return '$source:${sha256.convert(utf8.encode(key)).toString().substring(0, 20)}';
}

/// `prefix[i]` is the number of grapheme clusters in `text.substring(0, i)`,
/// built in one pass so per-word offsets do not rescan the line.
List<int> _graphemePrefix(String text) {
  final prefix = List<int>.filled(text.length + 1, 0);
  var unit = 0, count = 0;
  for (final cluster in text.characters) {
    prefix[unit] = count;
    count++;
    for (var i = 1; i <= cluster.length; i++) {
      prefix[unit + i] = count;
    }
    unit += cluster.length;
  }
  return prefix;
}

/// A user-imported timing file defines its own timeline; it makes no claim about
/// an independently selected catalog recording. Exact ordered text is required.
TimingTrack bindImportedTiming(TimingTrack track, String body) {
  if (track.status == TimingStatus.invalid ||
      track.status == TimingStatus.unsupported ||
      track.cues.isEmpty) {
    return track;
  }
  final same = lyricOrderHash(track.sourceLyrics) == lyricOrderHash(body);
  return track.copyWith(
    status: same ? TimingStatus.usable : TimingStatus.incompatible,
    origin: 'user',
    lyricHash: lyricOrderHash(track.sourceLyrics),
    extra: {
      ...track.extra,
      'binding': {
        'origin': 'user-imported-file',
        'arrangementLyricHash': lyricOrderHash(body),
        'recordingVerified': false,
        'applicability': same ? 'usable' : 'incompatible',
        if (same) 'occurrences': timingOccurrenceMap(track, body),
      },
    },
  );
}

List<JsonMap> timingOccurrenceMap(TimingTrack track, String body) {
  final result = <JsonMap>[];
  final sourceLines = track.sourceLyrics.split('\n');
  var target = 0;
  for (var source = 0; source < sourceLines.length; source++) {
    if (lyricLines(sourceLines[source]).isEmpty) continue;
    result.add({'source': 'line-$source', 'target': 'line-${target++}'});
  }
  return result;
}

/// Retains exact input bytes, including non-UTF-8 imports, in the same song file.
/// If encoding cannot be established, bytes survive with inactive timing.
TimingTrack parseTimingBytes(
  List<int> bytes, {
  required String sourceDocumentId,
  required String format,
  String? recordingId,
  String? encoding,
  String? profile,
}) {
  if (bytes.length > maxTimingBytes) {
    // Over-limit input is rejected without retaining its bytes: keeping them
    // would make the whole song unsaveable.
    return TimingTrack(
      id: '$sourceDocumentId:${sha256.convert(bytes)}',
      sourceDocumentId: sourceDocumentId,
      sourceLyrics: '',
      format: format,
      recordingId: recordingId,
      status: TimingStatus.invalid,
      extra: {
        'parseError':
            'Timing payload exceeds ${maxTimingBytes ~/ (1024 * 1024)} MiB.',
      },
    );
  }
  var detected = encoding?.toLowerCase();
  String? text;
  try {
    if (bytes.length >= 2 && bytes[0] == 255 && bytes[1] == 254) {
      detected = 'utf-16le';
    }
    if (bytes.length >= 2 && bytes[0] == 254 && bytes[1] == 255) {
      detected = 'utf-16be';
    }
    if (detected == 'utf-16le' || detected == 'utf-16be') {
      final offset =
          bytes.length >= 2 &&
              ((bytes[0] == 255 && bytes[1] == 254) ||
                  (bytes[0] == 254 && bytes[1] == 255))
          ? 2
          : 0;
      if ((bytes.length - offset).isOdd) {
        throw const FormatException('Invalid UTF-16 byte length.');
      }
      text = String.fromCharCodes([
        for (var i = offset; i < bytes.length; i += 2)
          detected == 'utf-16le'
              ? bytes[i] | bytes[i + 1] << 8
              : bytes[i] << 8 | bytes[i + 1],
      ]);
    } else if (detected == 'iso-8859-1' || detected == 'latin1') {
      text = latin1.decode(bytes);
    } else {
      text = utf8.decode(bytes);
      if (text.startsWith('\uFEFF')) text = text.substring(1);
      detected = 'utf-8';
    }
  } catch (_) {
    /* Retention does not require successful decoding. */
  }
  final track = text == null
      ? TimingTrack(
          id: '$sourceDocumentId:${sha256.convert(bytes)}',
          sourceDocumentId: sourceDocumentId,
          sourceLyrics: '',
          format: format,
          recordingId: recordingId,
          status: TimingStatus.unsupported,
          extra: {'parseError': 'The original text encoding is not supported.'},
        )
      : format == 'ttml'
      ? parseTtml(
          text,
          sourceDocumentId: sourceDocumentId,
          recordingId: recordingId,
          profile: profile,
        )
      : parseLrc(
          text,
          sourceDocumentId: sourceDocumentId,
          recordingId: recordingId,
        );
  return track.copyWith(
    extra: {
      ...track.extra,
      'rawBytesBase64': base64.encode(bytes),
      'rawByteHash': sha256.convert(bytes).toString(),
      'rawEncoding': detected ?? 'unknown',
    },
  );
}

/// Microseconds for an LRC `mm:ss.fff` pair, or null when the value cannot be
/// represented safely (huge minute counts overflow `int.parse`).
int? _lrcUs(String minutes, String seconds) {
  if (minutes.length > 9) return null;
  final m = int.tryParse(minutes);
  final sec = double.tryParse(seconds);
  if (m == null || sec == null || !sec.isFinite) return null;
  return ((m * 60 + sec) * 1000000).round();
}

/// Stable sort by start time: equal timestamps keep their source order.
void _sortCues(List<TimingCue> cues) {
  final indexed = [for (var i = 0; i < cues.length; i++) (i, cues[i])];
  indexed.sort((a, b) {
    final c = a.$2.startUs.compareTo(b.$2.startUs);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  for (var i = 0; i < cues.length; i++) {
    cues[i] = indexed[i].$2;
  }
}

TimingTrack parseLrc(
  String raw, {
  required String sourceDocumentId,
  String? recordingId,
}) {
  final id = _trackId(sourceDocumentId, raw);
  final cues = <TimingCue>[], lyrics = <String>[];
  var status = TimingStatus.unverified;
  var enhanced = false;
  final offsetMatch = RegExp(
    r'\[offset:\s*([+-]?\d+)\]',
    caseSensitive: false,
  ).firstMatch(raw);
  // Clamped to a day so the millisecond-to-microsecond product cannot overflow.
  final offsetUs =
      (int.tryParse(offsetMatch?.group(1) ?? '') ?? 0).clamp(
        -86400000,
        86400000,
      ) *
      1000;
  if (raw.length > maxTimingBytes || utf8.encode(raw).length > maxTimingBytes) {
    return TimingTrack(
      id: id,
      sourceDocumentId: sourceDocumentId,
      sourceLyrics: '',
      format: 'lrc',
      status: TimingStatus.invalid,
      extra: {
        'parseError':
            'Timing payload exceeds ${maxTimingBytes ~/ (1024 * 1024)} MiB.',
      },
    );
  }
  final timestamp = RegExp(r'\[(\d+):(\d{2}(?:\.\d+)?)\]');
  // Only consecutive tags at the start of a line are time tags; a "[12:30]"
  // inside the lyric text belongs to the text.
  final leadingTags = RegExp(r'^(?:\s*\[\d+:\d{2}(?:\.\d+)?\])+');
  final markerPattern = RegExp(r'<(\d+):(\d{2}(?:\.\d+)?)>');
  var overflow = false;
  lines:
  for (final line in raw.replaceAll('\r\n', '\n').split('\n')) {
    final tags = leadingTags.firstMatch(line);
    if (tags == null) continue;
    final times = timestamp.allMatches(tags.group(0)!).toList();
    if (times.isEmpty) continue;
    if (times.length > _maxLrcTimestampsPerLine) {
      overflow = true;
      break;
    }
    final content = line.substring(tags.end);
    final wordMarkers = markerPattern.allMatches(content).toList();
    final text = content.replaceAll(markerPattern, '').trim();
    final prefix = wordMarkers.isEmpty ? const <int>[] : _graphemePrefix(text);
    final firstRaw = _lrcUs(times.first.group(1)!, times.first.group(2)!);
    for (final time in times) {
      if (cues.length > _maxCues) {
        overflow = true;
        break lines;
      }
      final rawUs = _lrcUs(time.group(1)!, time.group(2)!);
      // LRC [offset:+n] makes lyrics appear n ms sooner: timestamp minus offset.
      // Times that land before zero are clamped rather than rejecting the file.
      final startUs = rawUs == null ? 0 : max(0, rawUs - offsetUs);
      // Word markers are written once, relative to the first timestamp; every
      // repeated timestamp shifts them by its distance from the first.
      final shiftUs = rawUs == null || firstRaw == null ? 0 : rawUs - firstRaw;
      final occurrence = 'line-${lyrics.length}';
      lyrics.add(text);
      if (rawUs == null ||
          startUs > 604800000000 ||
          double.parse(time.group(2)!) >= 60) {
        status = TimingStatus.invalid;
      }
      cues.add(
        TimingCue(
          id: '$id:${cues.length}',
          occurrenceId: occurrence,
          text: text,
          startUs: startUs,
          originalBegin: time.group(0),
        ),
      );
      if (wordMarkers.isNotEmpty) enhanced = true;
      var cursor = 0;
      for (var i = 0; i < wordMarkers.length; i++) {
        if (cues.length > _maxCues) {
          overflow = true;
          break lines;
        }
        final marker = wordMarkers[i];
        final word = content
            .substring(
              marker.end,
              i + 1 < wordMarkers.length
                  ? wordMarkers[i + 1].start
                  : content.length,
            )
            .trim();
        if (word.isEmpty) continue;
        final wordIndex = text.indexOf(word, cursor);
        if (wordIndex < 0) {
          status = TimingStatus.invalid;
          continue;
        }
        final markerUs = _lrcUs(marker.group(1)!, marker.group(2)!);
        final wordStart = markerUs == null
            ? 0
            : max(0, markerUs - offsetUs + shiftUs);
        if (markerUs == null ||
            wordStart > 604800000000 ||
            double.parse(marker.group(2)!) >= 60) {
          status = TimingStatus.invalid;
        }
        cues.add(
          TimingCue(
            id: '$id:${cues.length}',
            occurrenceId: occurrence,
            text: word,
            startUs: wordStart,
            graphemeStart: prefix[wordIndex],
            graphemeEnd: prefix[wordIndex + word.length],
            originalBegin: marker.group(0),
          ),
        );
        cursor = wordIndex + word.length;
      }
    }
  }
  if (overflow || cues.isEmpty || cues.length > _maxCues) {
    status = TimingStatus.invalid;
  }
  _sortCues(cues);
  final orderedLines = cues.where((cue) => cue.graphemeStart == null).toList();
  final occurrenceMap = {
    for (var i = 0; i < orderedLines.length; i++)
      orderedLines[i].occurrenceId: 'line-$i',
  };
  final orderedCues = cues
      .map(
        (cue) => TimingCue(
          id: cue.id,
          occurrenceId: occurrenceMap[cue.occurrenceId]!,
          text: cue.text,
          startUs: cue.startUs,
          endUs: cue.endUs,
          graphemeStart: cue.graphemeStart,
          graphemeEnd: cue.graphemeEnd,
          voice: cue.voice,
          originalBegin: cue.originalBegin,
          originalEnd: cue.originalEnd,
          extra: cue.extra,
        ),
      )
      .toList();
  final text = orderedLines.map((cue) => cue.text).join('\n');
  return TimingTrack(
    id: id,
    sourceDocumentId: sourceDocumentId,
    sourceLyrics: text,
    format: enhanced ? 'enhanced-lrc' : 'lrc',
    raw: raw,
    recordingId: recordingId,
    // Invalid normalized values never contaminate an otherwise readable saved file.
    // The exact raw input remains available for repair/reprocessing.
    cues: status == TimingStatus.invalid ? const [] : orderedCues,
    status: status,
    granularity: enhanced ? 'word' : 'line',
    lyricHash: lyricOrderHash(text),
    extra: {
      'parserVersion': 'verse-lrc-1',
      'offsetUs': offsetUs,
      'offsetConvention': 'subtracted-once',
      'precision': 'source decimal fraction',
    },
  );
}

TimingTrack parseTtml(
  String raw, {
  required String sourceDocumentId,
  String? recordingId,
  String? profile,
}) {
  final id = _trackId(
    sourceDocumentId,
    raw,
    profile: profile,
    recordingId: recordingId,
  );
  var text = '';
  try {
    if (raw.length > maxTimingBytes ||
        utf8.encode(raw).length > maxTimingBytes ||
        RegExp(
          r'<!\s*(?:DOCTYPE|ENTITY)',
          caseSensitive: false,
        ).hasMatch(raw)) {
      throw const FormatException(
        'XML entities and oversized timing documents are not supported.',
      );
    }
    final document = XmlDocument.parse(raw);
    final root = document.rootElement;
    String? attr(XmlElement e, String name) {
      for (final a in e.attributes) {
        if (a.name.local == name) return a.value;
      }
      return null;
    }

    final hasTiming = root.descendants.whereType<XmlElement>().any(
      (e) => e.attributes.any(
        (a) => {'begin', 'end', 'dur'}.contains(a.name.local),
      ),
    );
    final unisonProfile =
        root.name.local == 'tt' &&
        const {
          'https://composer.boidu.dev/ttml',
          'https://composer.betterlyrics.org/ttml',
        }.contains(attr(root, 'composer')) &&
        attr(root, 'timeBase') == 'media';
    final lrcRedProfile =
        profile == 'lrc-red' &&
        root.attributes.any(
          (a) =>
              a.name.local == 'timing' &&
              a.name.namespaceUri == 'http://lrc.red/lyric-ttml-internal' &&
              a.value == 'Word',
        );
    if (profile == 'lrc-red' && !lrcRedProfile) {
      throw const FormatException(
        'The lrc.red timing profile marker is missing or invalid.',
      );
    }
    final appleProfile =
        profile == 'apple-lyrics' ||
        root.attributes.any(
          (a) => a.value == 'http://itunes.apple.com/lyric-ttml-extensions',
        );
    final absoluteClockProfile = appleProfile || unisonProfile || lrcRedProfile;
    text = root.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'p')
        .map((p) => p.innerText.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
    final declaredFrameRate = double.tryParse(attr(root, 'frameRate') ?? '');
    final frameRate = declaredFrameRate ?? 30;
    final multiplier = (attr(root, 'frameRateMultiplier') ?? '1 1').split(
      RegExp(r'\s+'),
    );
    final effectiveFrames =
        frameRate * double.parse(multiplier[0]) / double.parse(multiplier[1]);
    final subFrameRate = double.tryParse(attr(root, 'subFrameRate') ?? '') ?? 1;
    // TTML: without ttp:tickRate the tick rate is frameRate * subFrameRate when
    // a frame rate is declared, and 1 tick per second otherwise.
    final tickRate =
        double.tryParse(attr(root, 'tickRate') ?? '') ??
        (declaredFrameRate == null ? 1.0 : effectiveFrames * subFrameRate);
    if (effectiveFrames <= 0 || tickRate <= 0 || subFrameRate <= 0) {
      throw const FormatException('Invalid timebase.');
    }
    int time(String expr) {
      final partialClock = RegExp(
        r'^(\d+):(\d{2}(?:\.\d+)?)$',
      ).firstMatch(expr);
      if (absoluteClockProfile && partialClock != null) {
        final minutesText = partialClock[1]!;
        final minutes = int.tryParse(minutesText);
        final seconds = double.tryParse(partialClock[2]!);
        if (minutesText.length > 9 ||
            minutes == null ||
            seconds == null ||
            seconds >= 60) {
          throw const FormatException('Invalid clock seconds.');
        }
        final microseconds = ((minutes * 60 + seconds) * 1000000).round();
        if (microseconds > 604800000000) {
          throw const FormatException('Clock time exceeds seven days.');
        }
        return microseconds;
      }
      final clock = RegExp(
        r'^(\d+):(\d{2}):(\d{2}(?:\.\d+)?)$',
      ).firstMatch(expr);
      if (clock != null) {
        return ((int.parse(clock[1]!) * 3600 +
                    int.parse(clock[2]!) * 60 +
                    double.parse(clock[3]!)) *
                1000000)
            .round();
      }
      final frames = RegExp(
        r'^(\d+):(\d{2}):(\d{2}):(\d+)(?:\.(\d+))?$',
      ).firstMatch(expr);
      if (frames != null) {
        return ((int.parse(frames[1]!) * 3600 +
                    int.parse(frames[2]!) * 60 +
                    int.parse(frames[3]!) +
                    (int.parse(frames[4]!) +
                            (double.tryParse(frames[5] ?? '') ?? 0) /
                                subFrameRate) /
                        effectiveFrames) *
                1000000)
            .round();
      }
      final offset = RegExp(
        r'^([+-]?\d+(?:\.\d+)?)(h|m|s|ms|f|t)$',
      ).firstMatch(expr);
      if (offset == null) {
        if (lrcRedProfile && RegExp(r'^\d+(?:\.\d+)?$').hasMatch(expr)) {
          final seconds = double.tryParse(expr);
          if (seconds == null ||
              !seconds.isFinite ||
              seconds < 0 ||
              seconds > 604800) {
            throw const FormatException('Invalid or out-of-range seconds.');
          }
          return (seconds * 1000000).round();
        }
        throw FormatException('Unsupported time expression: $expr');
      }
      final units = {
        'h': 3600.0,
        'm': 60.0,
        's': 1.0,
        'ms': 0.001,
        'f': 1 / effectiveFrames,
        't': 1 / tickRate,
      };
      return (double.parse(offset[1]!) * units[offset[2]!]! * 1000000).round();
    }

    final cues = <TimingCue>[];
    final lyrics = <String>[];
    var unsupported = false;
    var wordTiming = false;
    final ranges = <XmlElement, (int, int?)>{};
    final timed = <XmlElement, bool>{};
    void resolve(
      XmlElement node,
      int parentStart,
      int? parentEnd,
      int depth, [
      bool? parentTimed,
    ]) {
      if (depth > 64) {
        throw const FormatException('XML timing nesting exceeds 64 levels.');
      }
      if (attr(node, 'timeContainer') == 'seq') unsupported = true;
      final begin = attr(node, 'begin');
      // Apple's published lyric profile and Unison's declared media-clock
      // profile use absolute child clocks. Generic TTML retains W3C
      // parent-relative timing semantics.
      final base = absoluteClockProfile ? 0 : parentStart;
      var start = begin == null ? parentStart : base + time(begin);
      final explicitEnd = attr(node, 'end'), duration = attr(node, 'dur');
      int? end = explicitEnd != null
          ? base + time(explicitEnd)
          : duration != null
          ? start + time(duration)
          : parentEnd;
      // A child that begins after its parent has ended can never be active;
      // clamp it to the parent's end instead of rejecting the whole document.
      if (parentEnd != null && start > parentEnd) {
        if (lrcRedProfile) {
          throw const FormatException(
            'Child cue begins after its parent ends.',
          );
        }
        start = parentEnd;
        end = parentEnd;
      }
      if (parentEnd != null && end != null && end > parentEnd) {
        if (lrcRedProfile) {
          throw const FormatException('Child cue ends after its parent ends.');
        }
        end = parentEnd;
      }
      if (start < 0 || end != null && end < start) {
        throw const FormatException('Invalid cue interval.');
      }
      // The song file format rejects cues beyond this bound, so a track that
      // exceeds it must not be accepted (it could never be read back).
      if (start > _maxCueUs || end != null && end > _maxCueUs) {
        throw const FormatException('Cue time exceeds the supported range.');
      }
      timed[node] =
          (parentTimed ?? false) ||
          begin != null ||
          explicitEnd != null ||
          duration != null;
      ranges[node] = (start, end);
      for (final child in node.childElements) {
        resolve(child, start, end, depth + 1, timed[node]);
      }
    }

    resolve(root, 0, null, 0);
    String content(XmlElement e) {
      final buffer = StringBuffer();
      void walk(XmlNode n) {
        if (n is XmlText) buffer.write(n.value);
        if (n is XmlElement && n.name.local == 'br') {
          buffer.write('\n');
          return;
        }
        for (final c in n.children) {
          walk(c);
        }
      }

      walk(e);
      return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    for (final p in root.descendants.whereType<XmlElement>().where(
      (e) => e.name.local == 'p',
    )) {
      final line = content(p);
      if (line.isEmpty) continue;
      final occurrence = 'line-${lyrics.length}';
      lyrics.add(line);
      final timedSpans = p.descendants
          .whereType<XmlElement>()
          .where(
            (e) =>
                e.name.local == 'span' &&
                (attr(e, 'begin') != null ||
                    attr(e, 'end') != null ||
                    attr(e, 'dur') != null),
          )
          .toList();
      var range = ranges[p]!;
      // A paragraph with no timing of its own or inherited must not invent a
      // 0s start: derive it from its timed spans, or leave the line untimed.
      var lineTimed = timed[p] ?? false;
      if (!lineTimed && timedSpans.isNotEmpty) {
        final spanRanges = timedSpans.map((e) => ranges[e]!).toList();
        final ends = spanRanges.map((r) => r.$2).toList();
        range = (
          spanRanges.map((r) => r.$1).reduce(min),
          ends.contains(null) ? null : ends.cast<int>().reduce(max),
        );
        lineTimed = true;
      }
      if (lineTimed) {
        cues.add(
          TimingCue(
            id: '$id:${cues.length}',
            occurrenceId: occurrence,
            text: line,
            startUs: range.$1,
            endUs: range.$2,
            voice: attr(p, 'agent'),
            originalBegin: attr(p, 'begin'),
            originalEnd: attr(p, 'end'),
          ),
        );
      }
      var cursor = 0;
      final prefix = timedSpans.isEmpty ? const <int>[] : _graphemePrefix(line);
      for (final span in timedSpans) {
        if (cues.length > _maxCues) {
          throw const FormatException('Too many timing cues.');
        }
        final word = content(span);
        if (word.isEmpty) continue;
        // Nested timing spans may overlap. Their own exact grapheme range is retained.
        var index = line.indexOf(word, cursor);
        if (index < 0) index = line.indexOf(word);
        if (index < 0) {
          throw const FormatException(
            'TTML span does not match its source text.',
          );
        }
        final spanRange = ranges[span]!;
        cues.add(
          TimingCue(
            id: '$id:${cues.length}',
            occurrenceId: occurrence,
            text: word,
            startUs: spanRange.$1,
            endUs: spanRange.$2,
            graphemeStart: prefix[index],
            graphemeEnd: prefix[index + word.length],
            voice: attr(span, 'agent') ?? attr(p, 'agent'),
            originalBegin: attr(span, 'begin'),
            originalEnd: attr(span, 'end'),
          ),
        );
        cursor = index + word.length;
        wordTiming = true;
      }
    }
    text = lyrics.join('\n');
    if (cues.length > _maxCues) {
      throw const FormatException('Too many timing cues.');
    }
    _sortCues(cues);
    return TimingTrack(
      id: id,
      sourceDocumentId: sourceDocumentId,
      sourceLyrics: text,
      format: 'ttml',
      raw: raw,
      recordingId: recordingId,
      cues: cues,
      status: unsupported || !hasTiming
          ? TimingStatus.unsupported
          : cues.isEmpty
          ? TimingStatus.invalid
          : TimingStatus.unverified,
      granularity: wordTiming ? 'word' : 'line',
      lyricHash: lyricOrderHash(text),
      extra: {
        'parserVersion': 'verse-ttml-4',
        'timingProfile': appleProfile
            ? 'apple-lyrics'
            : unisonProfile
            ? 'unison-ttml'
            : lrcRedProfile
            ? 'lrc-red-ttml'
            : 'w3c-ttml',
        'frameRate': effectiveFrames,
        'tickRate': tickRate,
        'subFrameRate': subFrameRate,
        if (unsupported)
          'parseError':
              'Sequential TTML containers are retained but not activated.',
        if (!hasTiming)
          'parseError':
              'This TTML document contains lyrics without cue timestamps.',
      },
    );
  } catch (error) {
    return TimingTrack(
      id: id,
      sourceDocumentId: sourceDocumentId,
      sourceLyrics: text,
      format: 'ttml',
      raw: raw,
      recordingId: recordingId,
      status: TimingStatus.invalid,
      extra: {'parserVersion': 'verse-ttml-4', 'parseError': error.toString()},
    );
  }
}
