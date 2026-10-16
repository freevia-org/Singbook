import 'dart:convert';
import 'package:characters/characters.dart';
import 'models.dart';
import 'arrangement.dart';
import 'timing.dart' show timingOccurrenceMap;

SourceResult? bestLyricsFallback(Iterable<SourceResult> sources) {
  final candidates = sources
      .where((source) => plainLyrics(source.body).trim().isNotEmpty)
      .toList()
    ..sort((a, b) {
      int rank(SourceResult source) =>
          lyricLines(source.body).length.clamp(0, 100) * 1000 +
          plainLyrics(source.body).length.clamp(0, 100000) +
          (source.hasChords ? 500 : 0);
      final quality = rank(b).compareTo(rank(a));
      return quality != 0 ? quality : a.id.compareTo(b.id);
    });
  return candidates.isEmpty ? null : candidates.first;
}

String _norm(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();
double? _validDuration(Object? value) {
  if (value is! num) return null;
  final seconds = value.toDouble();
  return seconds.isFinite && seconds > 0 && seconds <= 86400 ? seconds : null;
}

String _version(String title) => RegExp(
  r'\b(live|acoustic|remix|instrumental|karaoke|demo)\b',
  caseSensitive: false,
).allMatches(title).map((m) => m.group(0)!.toLowerCase()).join(' ');
const _versionWords =
    r'(?:live|acoustic|remix|instrumental|karaoke|demo|remaster(?:ed)?|mix|version|edit|mono|stereo)';
// "(Remastered 2011)" and "- Remastered 2011" / "- Live" / "- 2011 Mix" are
// edition qualifiers, not part of the song's name.
final _bracketQualifier = RegExp(
  r'\s*[\(\[][^\)\]]*\b' + _versionWords + r'\b[^\)\]]*[\)\]]',
  caseSensitive: false,
);
final _dashQualifier = RegExp(
  r'\s+[-\u2013\u2014]\s+(?=.*\b' + _versionWords + r'\b).*$',
  caseSensitive: false,
);
String _baseTitle(String title) => _norm(
  title.replaceAll(_bracketQualifier, '').replaceAll(_dashQualifier, ''),
);
bool _sameSong(SongCandidate a, SongCandidate b) {
  final artist = _norm(a.artist), title = _baseTitle(a.title);
  // Two unknown (empty) artists or titles are not evidence of the same song.
  if (artist.isEmpty || title.isEmpty) return false;
  return artist == _norm(b.artist) && title == _baseTitle(b.title);
}

bool _hasRecordingIdentityScope(SongCandidate candidate) =>
    candidate.metadata['identityScope'] == 'recording';
bool _demonstrationTimingSelected(
  SongCandidate selected,
  SourceResult source,
  TimingTrack track,
) =>
    track.extra['recordingEvidence'] != 'sourceDemonstrationOnly' ||
    (_hasRecordingIdentityScope(selected) &&
        (selected.identity == source.candidate.identity ||
            selected.recordingIds.entries.any(
              (e) => source.candidate.recordingIds[e.key] == e.value,
            )));
bool recordingCompatible(SongCandidate selected, SourceResult result) {
  if (result.matchKind == MatchKind.rejected ||
      !_sameSong(selected, result.candidate)) {
    return false;
  }
  final found = result.candidate;
  if (_version(selected.title) != _version(found.title)) return false;
  for (final entry in selected.recordingIds.entries) {
    if (found.recordingIds.containsKey(entry.key) &&
        found.recordingIds[entry.key] != entry.value) {
      return false;
    }
  }
  if (selected.durationSeconds != null &&
      found.durationSeconds != null &&
      (selected.durationSeconds! - found.durationSeconds!).abs() > 3) {
    return false;
  }
  // Provider identity can name a composition, work, artist, or image. Only
  // treat identical candidate IDs as recording evidence when that identity
  // is explicitly scoped to a recording (or is a legacy unscoped ID).
  final selectedScope = selected.metadata['identityScope'];
  final foundScope = found.metadata['identityScope'];
  const nonRecordingScopes = {'composition', 'work', 'artist', 'image'};
  if (selected.identity == found.identity &&
      !nonRecordingScopes.contains(selectedScope) &&
      !nonRecordingScopes.contains(foundScope)) {
    return true;
  }
  if (selected.recordingIds.entries.any(
    (e) => found.recordingIds[e.key] == e.value,
  )) {
    return true;
  }
  return result.matchKind == MatchKind.sameRecording &&
      selected.album != null &&
      found.album != null &&
      _norm(selected.album!) == _norm(found.album!) &&
      selected.durationSeconds != null &&
      found.durationSeconds != null;
}

bool _completeChart(String chart, String reference) {
  List<String> words(String value) =>
      _norm(plainLyrics(value)).split(' ').where((w) => w.isNotEmpty).toList();
  final a = words(chart), b = words(reference);
  if (a.length < 12 || b.length < 12) return true;
  Map<String, int> counts(List<String> list) {
    final m = <String, int>{};
    for (final x in list) {
      m[x] = (m[x] ?? 0) + 1;
    }
    return m;
  }

  double coverage(List<String> left, List<String> right) {
    final available = counts(right);
    var matched = 0;
    for (final word in left) {
      if ((available[word] ?? 0) > 0) {
        matched++;
        available[word] = available[word]! - 1;
      }
    }
    return matched / left.length;
  }

  List<String> bigrams(List<String> values) => [
    for (var i = 0; i < values.length - 1; i++) '${values[i]} ${values[i + 1]}',
  ];
  return coverage(a, b) >= .80 &&
      coverage(b, a) >= .85 &&
      coverage(bigrams(a), bigrams(b)) >= .65 &&
      coverage(bigrams(b), bigrams(a)) >= .65;
}

String _lineKey(ArrangementLine line) => _norm(line.text);

final _literalChordTokenPattern = RegExp(
  chordPattern.pattern.replaceFirst(r'(?<!\\)', ''),
);

String _escapeLiteralChordTokens(String text) {
  final output = StringBuffer();
  var cursor = 0;
  for (final match in _literalChordTokenPattern.allMatches(text)) {
    output.write(_escapeBackslashes(text.substring(cursor, match.start)));
    output.write('\\');
    output.write(match[0]);
    cursor = match.end;
  }
  output.write(_escapeBackslashes(text.substring(cursor)));
  return output.toString();
}

String _escapeBackslashes(String text) => text.replaceAll('\\', '\\\\');

({String text, List<int> offsets}) _normalizedLine(String text) {
  final normalized = StringBuffer();
  final offsets = <int>[];
  var pendingSeparator = false;
  final graphemes = text.characters.toList();
  final letterOrNumber = RegExp(r'[\p{L}\p{N}]', unicode: true);
  for (var index = 0; index < graphemes.length; index++) {
    final lowered = graphemes[index].toLowerCase().characters;
    final kept = lowered.where(letterOrNumber.hasMatch).toList();
    if (kept.isEmpty) {
      if (normalized.isNotEmpty) pendingSeparator = true;
      continue;
    }
    if (pendingSeparator && normalized.isNotEmpty) {
      normalized.write(' ');
      offsets.add(index);
    }
    for (final character in kept) {
      normalized.write(character);
      offsets.add(index);
    }
    pendingSeparator = false;
  }
  return (text: normalized.toString(), offsets: offsets);
}

List<ChordAnchor>? _remapChordAnchors(
  ArrangementLine donor,
  ArrangementLine target,
) {
  final source = _normalizedLine(donor.text);
  final destination = _normalizedLine(target.text);
  if (source.text.isEmpty || source.text != destination.text) return null;
  final sourceGraphemes = donor.text.characters.toList();
  final targetGraphemes = target.text.characters.toList();
  return [
    for (final chord in donor.chords)
      _remapChordAnchor(
        chord,
        source,
        sourceGraphemes.length,
        destination,
        targetGraphemes.length,
      ),
  ];
}

ChordAnchor _remapChordAnchor(
  ChordAnchor chord,
  ({String text, List<int> offsets}) source,
  int sourceLength,
  ({String text, List<int> offsets}) destination,
  int targetLength,
) {
  final sourceAnchor = chord.offset.clamp(0, sourceLength);
  var normalizedOffset = source.offsets
      .where((offset) => offset < sourceAnchor)
      .length;
  while (normalizedOffset < destination.text.length &&
      destination.text[normalizedOffset] == ' ') {
    normalizedOffset++;
  }
  final targetOffset = normalizedOffset >= destination.offsets.length
      ? targetLength
      : destination.offsets[normalizedOffset];
  return ChordAnchor(targetOffset, chord.chord);
}

String _chordSignature(ArrangementLine line) {
  final graphemes = line.text.characters.toList();
  return line.chords
      .map((chord) {
        final prefix = _normalizedLine(
          graphemes.take(chord.offset.clamp(0, graphemes.length)).join(),
        );
        return '${prefix.text.length}:${chord.chord}';
      })
      .join('|');
}

Object? _setupValue(SourceResult source, SongCandidate selected, String key) =>
    source.metadata[key] ??
    source.candidate.metadata[key] ??
    selected.metadata[key];

bool _compatibleArrangementSetup(
  SourceResult base,
  SourceResult donor,
  SongCandidate selected,
) {
  for (final key in const ['key', 'capo', 'tuning', 'timeSignature']) {
    final baseValue = _setupValue(base, selected, key);
    final donorValue = _setupValue(donor, selected, key);
    if (baseValue == null || donorValue == null) continue;
    final normalizedBase = baseValue is String
        ? baseValue.trim().toLowerCase()
        : jsonEncode(baseValue);
    final normalizedDonor = donorValue is String
        ? donorValue.trim().toLowerCase()
        : jsonEncode(donorValue);
    if (normalizedBase != normalizedDonor) return false;
  }
  return true;
}

({String body, List<String> sourceIds}) _overlayChords(
  String body,
  List<SourceResult> sources,
  SongCandidate selected,
  SourceResult base,
) {
  final lines = parseArrangement(body);
  final lyricsByLine = <String, int>{};
  for (final line in lines) {
    final key = _lineKey(line);
    if (key.isNotEmpty) {
      lyricsByLine.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  SourceResult? chartSource;
  var bestScore = -1;
  for (final source in sources) {
    if (!source.hasChords ||
        !_compatibleArrangementSetup(base, source, selected)) {
      continue;
    }
    final chartLines = parseArrangement(source.body);
    final keys = chartLines
        .where((line) => line.chords.isNotEmpty)
        .map(_lineKey)
        .where((key) => key.isNotEmpty)
        .toSet();
    final coverage = keys.fold<int>(
      0,
      (score, key) => score + (lyricsByLine[key] ?? 0),
    );
    if (coverage == 0) continue;
    final confidence = recordingCompatible(selected, source)
        ? 2
        : source.matchKind == MatchKind.sameSong
        ? 1
        : 0;
    final score = coverage * 100 + confidence;
    if (score > bestScore ||
        (score == bestScore &&
            (chartSource == null || source.id.compareTo(chartSource.id) < 0))) {
      bestScore = score;
      chartSource = source;
    }
  }
  if (chartSource == null) return (body: body, sourceIds: const []);

  final charts = <String, List<ArrangementLine>>{};
  for (final line in parseArrangement(chartSource.body)) {
    final key = _lineKey(line);
    if (key.isEmpty || line.chords.isEmpty) continue;
    charts.putIfAbsent(key, () => []).add(line);
  }
  if (charts.isEmpty) return (body: body, sourceIds: const []);

  final rawLines = body.split('\n');
  final output = <String>[];
  var applied = false;
  for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    final line = lines[lineIndex];
    final rawLine = rawLines[lineIndex];
    final key = _lineKey(line);
    final matches = charts[key];
    if (line.directive || line.chords.isNotEmpty || matches == null) {
      output.add(rawLine);
      continue;
    }
    if (matches.map(_chordSignature).toSet().length > 1) {
      output.add(rawLine);
      continue;
    }
    final chords = _remapChordAnchors(matches.first, line);
    if (chords == null || chords.isEmpty) {
      output.add(rawLine);
      continue;
    }
    final characters = line.text.characters.toList();
    final safeChords =
        chords
            .where(
              (chord) =>
                  chord.offset == 0 || characters[chord.offset - 1] != '\\',
            )
            .toList()
          ..sort((a, b) => a.offset.compareTo(b.offset));
    if (safeChords.isEmpty) {
      output.add(rawLine);
      continue;
    }
    applied = true;
    final buffer = StringBuffer();
    var cursor = 0;
    for (final chord in safeChords) {
      final offset = chord.offset.clamp(cursor, characters.length);
      if (offset > cursor) {
        buffer.write(
          _escapeLiteralChordTokens(
            characters.skip(cursor).take(offset - cursor).join(),
          ),
        );
        cursor = offset;
      }
      buffer.write('[${chord.chord}]');
    }
    buffer.write(_escapeLiteralChordTokens(characters.skip(cursor).join()));
    output.add(buffer.toString());
  }
  return (
    body: output.join('\n'),
    sourceIds: applied ? [chartSource.id] : const [],
  );
}

SongDocument combineSources(
  SongCandidate selected,
  List<SourceResult> results, {
  String? preferredSourceId,
  bool allowRejectedPreferredSource = false,
}) {
  final matching = results
      .where(
        (s) =>
            (s.matchKind != MatchKind.rejected ||
                (allowRejectedPreferredSource && s.id == preferredSourceId)) &&
            (_sameSong(s.candidate, selected) ||
                (allowRejectedPreferredSource && s.id == preferredSourceId)),
      )
      .toList();
  final accepted = matching
      .where((s) => plainLyrics(s.body).trim().isNotEmpty)
      .toList();
  if (accepted.isEmpty) {
    throw const FormatException('No matching lyrics are available to save.');
  }
  final references =
      accepted
          .where((s) => !s.hasChords && s.matchKind != MatchKind.unverified)
          .toList()
        ..sort(
          (a, b) =>
              plainLyrics(
                    b.body,
                  ).length.compareTo(plainLyrics(a.body).length) !=
                  0
              ? plainLyrics(b.body).length.compareTo(plainLyrics(a.body).length)
              : a.id.compareTo(b.id),
        );
  final eligible = accepted
      .where(
        (source) =>
            (allowRejectedPreferredSource && source.id == preferredSourceId) ||
            !source.hasChords ||
            references.isEmpty ||
            _completeChart(source.body, references.first.body),
      )
      .toList();
  if (eligible.isEmpty) {
    throw const FormatException('No complete matching lyrics are available.');
  }
  int rank(SourceResult s) =>
      lyricLines(s.body).length.clamp(0, 100) * 1000 +
      plainLyrics(s.body).length.clamp(0, 100000) +
      (recordingCompatible(selected, s)
          ? 300
          : s.matchKind == MatchKind.sameSong
          ? 200
          : 0) +
      (s.hasChords ? 500 : 0);
  eligible.sort((a, b) {
    final score = rank(b).compareTo(rank(a));
    return score != 0 ? score : a.id.compareTo(b.id);
  });
  final preferred = eligible.where((s) => s.id == preferredSourceId);
  if (preferredSourceId != null && preferred.isEmpty) {
    throw const FormatException(
      'The selected source does not contain a complete matching arrangement.',
    );
  }
  final best = preferred.isEmpty ? eligible.first : preferred.first;
  final merged = preferredSourceId == null && !best.hasChords
      ? _overlayChords(
          best.body,
          accepted.where((source) => source.id != best.id).toList(),
          selected,
          best,
        )
      : (body: best.body, sourceIds: const <String>[]);
  const arrangementFields = {
    'key',
    'capo',
    'tuning',
    'tempo',
    'timeSignature',
    'difficulty',
    'arrangement',
  };
  final metadata = <String, dynamic>{
    ...selected.metadata,
    if (selected.album != null) 'album': selected.album,
  };
  final selectedDuration =
      _validDuration(selected.durationSeconds) ??
      _validDuration(selected.metadata['durationSeconds']);
  if (selectedDuration == null) {
    metadata.remove('durationSeconds');
  } else {
    metadata['durationSeconds'] = selectedDuration;
  }
  metadata.removeWhere((key, _) => arrangementFields.contains(key));
  final origins = <String, dynamic>{
    for (final k in metadata.keys) k: selected.identity,
  };
  final chordSourceIds = <String>{
    if (best.hasChords) best.id,
    ...merged.sourceIds,
  }.toList();
  if (chordSourceIds.isNotEmpty) origins['chords'] = chordSourceIds.first;
  final sourcesById = {for (final source in matching) source.id: source};
  final arrangementSourceIds = <String>{best.id};
  for (final sourceId in chordSourceIds) {
    final source = sourcesById[sourceId];
    if (source != null &&
        (recordingCompatible(selected, source) ||
            merged.sourceIds.contains(sourceId))) {
      arrangementSourceIds.add(sourceId);
    }
  }
  final conflicts = <String, dynamic>{};
  // An explicit version choice should carry the duration shown on that
  // version card. Automatic combination keeps the selected catalog record's
  // metadata as the default, as it has no user-selected source to prefer.
  if (preferredSourceId != null) {
    final preferredDuration =
        _validDuration(best.candidate.durationSeconds) ??
        _validDuration(best.metadata['durationSeconds']) ??
        _validDuration(best.candidate.metadata['durationSeconds']);
    if (preferredDuration != null) {
      metadata['durationSeconds'] = preferredDuration;
      origins['durationSeconds'] = best.id;
    }
  }
  const songFields = {
    'genre',
    'language',
    'composer',
    'lyricist',
    'writers',
    'copyright',
    'license',
    'licenseUrl',
    'attribution',
  };
  for (final source in [best, ...matching.where((s) => s.id != best.id)]) {
    final candidateDuration =
        _validDuration(source.candidate.durationSeconds) ??
        _validDuration(source.candidate.metadata['durationSeconds']);
    final facts = {
      ...source.candidate.metadata,
      if (source.candidate.album != null) 'album': source.candidate.album,
      'durationSeconds': candidateDuration,
      ...source.metadata,
    };
    final sourceDuration =
        _validDuration(source.metadata['durationSeconds']) ??
        candidateDuration ??
        _validDuration(facts['durationSeconds']);
    if (facts.containsKey('durationSeconds') && sourceDuration == null) {
      facts.remove('durationSeconds');
    } else if (sourceDuration != null) {
      facts['durationSeconds'] = sourceDuration;
    }
    final sameRecording = recordingCompatible(selected, source);
    for (final entry in facts.entries) {
      if (entry.value == null || entry.value == '') continue;
      final isArrangement = arrangementFields.contains(entry.key);
      if (isArrangement && !arrangementSourceIds.contains(source.id)) continue;
      if (!isArrangement && !songFields.contains(entry.key) && !sameRecording) {
        continue;
      }
      if (!metadata.containsKey(entry.key) || metadata[entry.key] == null) {
        metadata[entry.key] = entry.value;
        origins[entry.key] = source.id;
      } else if (jsonEncode(metadata[entry.key]) != jsonEncode(entry.value)) {
        (conflicts[entry.key] ??= <dynamic>[]).add({
          'sourceId': source.id,
          'value': entry.value,
        });
      }
    }
  }
  final tracks = <String, TimingTrack>{};
  for (final source in results) {
    for (final track in source.timingTracks) {
      if (tracks.containsKey(track.id)) continue;
      var status = track.status;
      if (status != TimingStatus.invalid &&
          status != TimingStatus.unsupported) {
        status = source.matchKind == MatchKind.rejected
            ? TimingStatus.incompatible
            : !_demonstrationTimingSelected(selected, source, track)
            ? TimingStatus.unverified
            : !recordingCompatible(selected, source)
            ? TimingStatus.unverified
            : lyricOrderHash(track.sourceLyrics) != lyricOrderHash(best.body)
            ? TimingStatus.incompatible
            : TimingStatus.usable;
      }
      tracks[track.id] = track.copyWith(
        status: status,
        lyricHash: lyricOrderHash(track.sourceLyrics),
        extra: {
          ...track.extra,
          'binding': {
            'arrangementLyricHash': lyricOrderHash(best.body),
            'sourceId': source.id,
            'recordingVerified':
                recordingCompatible(selected, source) &&
                _demonstrationTimingSelected(selected, source, track),
            if (status == TimingStatus.usable)
              'occurrences': timingOccurrenceMap(track, best.body),
          },
        },
      );
    }
  }
  final usable = tracks.values.where((t) => t.status == TimingStatus.usable);
  return SongDocument(
    id: newId(),
    title: selected.title,
    artist: selected.artist,
    body: inferSectionDirectives(merged.body),
    metadata: metadata,
    sources: results,
    timingTracks: tracks.values.toList(),
    selectedRecording: selected,
    activeTimingTrackId: usable.isEmpty ? null : usable.first.id,
    extra: {
      'selectedSourceId': best.id,
      'fieldOrigins': origins,
      if (conflicts.isNotEmpty) 'conflicts': conflicts,
      'recommendation':
          'Combined lyrics, chords, timing, and metadata from matching sources.',
      if (chordSourceIds.isNotEmpty) 'chordSourceIds': chordSourceIds,
      if (chordSourceIds.any(
        (sourceId) => sourcesById[sourceId]?.extra['pendingMatchCheck'] == true,
      ))
        'pendingChordSourceIds': chordSourceIds
            .where(
              (sourceId) =>
                  sourcesById[sourceId]?.extra['pendingMatchCheck'] == true,
            )
            .toList(),
      'excludedIncompleteSourceIds': accepted
          .where((s) => !eligible.contains(s))
          .map((s) => s.id)
          .toList(),
    },
  );
}
