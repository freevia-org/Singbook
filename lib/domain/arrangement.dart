import 'dart:convert';
import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'models.dart';

final chordPattern = RegExp(
  r'(?<!\\)\[((?:[A-G](?:#|b|♯|♭){0,2}(?:(?:maj|min|dim|aug|sus|add|omit|no|M|m|Δ|ø|°)|\d{1,2}|[#b♯♭+−-]\d{0,2}|\/(?:9|11|13)|\([A-Za-z0-9#b♯♭,+−-]{1,20}\))*(?:\/[A-G](?:#|b|♯|♭){0,2})?|N\.?C\.?))\]',
);
String unescapeChordPro(String text) =>
    text.replaceAllMapped(RegExp(r'\\([\\\[\]{}#])'), (m) => m[1]!);
bool containsChords(String body) => chordPattern.hasMatch(body);
String plainLyrics(String body) => lyricLines(body).join('\n');
List<String> lyricLines(String body) {
  final result = <String>[];
  var chorus = <String>[];
  var inChorus = false;
  for (final line in body.replaceAll('\r\n', '\n').split('\n')) {
    if (RegExp(
      r'^\s*\{(?:start_of_chorus|soc)(?::[^}]*)?\}\s*$',
      caseSensitive: false,
    ).hasMatch(line)) {
      inChorus = true;
      chorus = [];
      continue;
    }
    if (RegExp(
      r'^\s*\{(?:end_of_chorus|eoc)\}\s*$',
      caseSensitive: false,
    ).hasMatch(line)) {
      inChorus = false;
      continue;
    }
    if (RegExp(
      r'^\s*\{chorus(?::[^}]*)?\}\s*$',
      caseSensitive: false,
    ).hasMatch(line)) {
      if (chorus.isEmpty) {
        result.add('[unresolved chorus]');
      } else {
        result.addAll(chorus);
      }
      continue;
    }
    if (RegExp(
      r'^\s*(?:\{.*\}|#.*|\[(?:verse|chorus|bridge|intro|outro|instrumental)[^\]]*\])\s*$',
      caseSensitive: false,
    ).hasMatch(line)) {
      continue;
    }
    final text = unescapeChordPro(
      line.replaceAll(chordPattern, ''),
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) continue;
    result.add(text);
    if (inChorus) chorus.add(text);
  }
  return result;
}

String lyricOrderHash(String body) =>
    sha256.convert(utf8.encode(jsonEncode(lyricLines(body)))).toString();

class ChordAnchor {
  final int offset;
  final String chord;
  const ChordAnchor(this.offset, this.chord);
}

class ArrangementLine {
  final String text;
  final List<ChordAnchor> chords;
  final bool directive;
  const ArrangementLine(this.text, this.chords, {this.directive = false});
}

final _sectionNamePattern = RegExp(
  r'^\s*((?:pre[- ]?chorus|post[- ]?chorus|verse|chorus|bridge|intro|outro|instrumental|interlude|solo|refrain|hook|breakdown|coda|tag|ending)(?:\s+(?:\d+|[A-D]))?(?:\s+\([^\r\n]*\))?)\s*$',
  caseSensitive: false,
);
final _commentDirectivePattern = RegExp(
  r'^\s*\{comment\s*:\s*(.*?)\}\s*$',
  caseSensitive: false,
);
final _sectionDirectivePattern = RegExp(
  r'^\s*\{start_of_(pre_chorus|post_chorus|verse|chorus|bridge|intro|outro|instrumental|interlude|solo|refrain|hook|breakdown|coda|tag|ending)(?:\s*:\s*(\d+))?\}\s*$',
  caseSensitive: false,
);

String? _sectionName(String value) =>
    _sectionNamePattern.firstMatch(value)?.group(1)?.trim();

/// Returns a human-readable label for recognized section lines.
///
/// ChordPro comments that are not section headings remain directives but do
/// not become section labels in the reader or player.
String? sectionLabelForLine(ArrangementLine line) {
  if (line.directive) {
    final comment = _commentDirectivePattern.firstMatch(line.text);
    if (comment != null) return _sectionName(comment.group(1)!);

    final section = _sectionDirectivePattern.firstMatch(line.text);
    if (section == null) return null;
    final kind = section
        .group(1)!
        .split('_')
        .map((part) {
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join('-');
    final suffix = section.group(2);
    return suffix == null ? kind : '$kind $suffix';
  }

  final bracketed = RegExp(r'^\s*\[([^\]]+)\]\s*$').firstMatch(line.text);
  return bracketed == null ? null : _sectionName(bracketed.group(1)!);
}

List<ArrangementLine> parseArrangement(String body) =>
    body.split('\n').map((line) {
      if (line.trimLeft().startsWith('{')) {
        return ArrangementLine(line, const [], directive: true);
      }
      final chords = <ChordAnchor>[];
      for (final m in chordPattern.allMatches(line)) {
        chords.add(
          ChordAnchor(
            unescapeChordPro(
              line.substring(0, m.start).replaceAll(chordPattern, ''),
            ).characters.length,
            m.group(1)!,
          ),
        );
      }
      return ArrangementLine(
        unescapeChordPro(line.replaceAll(chordPattern, '')),
        chords,
      );
    }).toList();

String transposeChord(String chord, int semitones) {
  const sharp = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  const flat = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];
  const pitches = {
    'C': 0,
    'B#': 0,
    'C#': 1,
    'Db': 1,
    'D': 2,
    'D#': 3,
    'Eb': 3,
    'E': 4,
    'Fb': 4,
    'E#': 5,
    'F': 5,
    'F#': 6,
    'Gb': 6,
    'G': 7,
    'G#': 8,
    'Ab': 8,
    'A': 9,
    'A#': 10,
    'Bb': 10,
    'B': 11,
    'Cb': 11,
  };
  if (RegExp(r'^N\.?C\.?$').hasMatch(chord)) return chord;
  final normalized = chord.replaceAll('♯', '#').replaceAll('♭', 'b');
  final rootPattern = RegExp(r'(^|/)([A-G][#b]{0,2})');
  // Spelling follows the accidental on the root/bass notes only; a lowercase
  // "b" elsewhere (C#7b9, Cadd9b5) is a chord alteration, not a flat note.
  final useFlats = rootPattern
      .allMatches(normalized)
      .any((m) => m.group(2)!.length > 1 && m.group(2)![1] == 'b');
  final notes = useFlats ? flat : sharp;
  return normalized.replaceAllMapped(rootPattern, (match) {
    final note = match.group(2)!;
    final pitch =
        pitches[note] ??
        ((pitches[note[0]]! +
                note
                    .substring(1)
                    .split('')
                    .fold<int>(0, (n, s) => n + (s == '#' ? 1 : -1))) %
            12);
    return '${match.group(1)}${notes[(pitch + semitones) % 12]}';
  });
}

String transposeBody(String body, int semitones) => body.replaceAllMapped(
  chordPattern,
  (match) => '[${transposeChord(match.group(1)!, semitones)}]',
);

SongDocument editSong(
  SongDocument song, {
  String? body,
  String? title,
  String? artist,
  JsonMap? metadata,
}) {
  final changed =
      body != null && lyricOrderHash(body) != lyricOrderHash(song.body);
  final recordingChanged =
      artist != null && artist != song.artist ||
      metadata != null &&
          [
            'durationSeconds',
            'recordingIds',
            'version',
          ].any((key) => jsonEncode(metadata[key]) != jsonEncode(song.metadata[key]));
  final origins = jsonMap(song.extra['fieldOrigins']);
  if (title != null && title != song.title) origins['title'] = 'user';
  if (artist != null && artist != song.artist) origins['artist'] = 'user';
  if (metadata != null) {
    for (final key in {...metadata.keys, ...song.metadata.keys}) {
      if (jsonEncode(metadata[key]) != jsonEncode(song.metadata[key])) {
        origins[key] = 'user';
      }
    }
  }
  return song.copyWith(
    title: title,
    artist: artist,
    body: body,
    metadata: metadata,
    extra: {...song.extra, if (origins.isNotEmpty) 'fieldOrigins': origins},
    timingTracks: changed || recordingChanged
        ? song.timingTracks
              .map(
                (track) => track.status == TimingStatus.usable
                    ? track.copyWith(status: TimingStatus.stale)
                    : track,
              )
              .toList()
        : null,
    clearActiveTiming: changed || recordingChanged,
  );
}

/// Removes timing track [trackId] everywhere it is stored: the song's own list
/// and every source that references it. Encoding merges both lists, so removing
/// it from only one of them would bring the track back on the next save. The
/// active track selection is cleared when it pointed at the removed track.
SongDocument removeTimingTrack(SongDocument song, String trackId) {
  final inSong = song.timingTracks.any((t) => t.id == trackId);
  final inSources = song.sources.any(
    (s) => s.timingTracks.any((t) => t.id == trackId),
  );
  if (!inSong && !inSources) return song;
  return song.copyWith(
    timingTracks: [
      for (final track in song.timingTracks)
        if (track.id != trackId) track,
    ],
    sources: [
      for (final source in song.sources)
        source.timingTracks.any((t) => t.id == trackId)
            ? source.copyWith(
                timingTracks: [
                  for (final track in source.timingTracks)
                    if (track.id != trackId) track,
                ],
              )
            : source,
    ],
    clearActiveTiming: song.activeTimingTrackId == trackId,
  );
}
