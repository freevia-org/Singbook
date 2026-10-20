import 'dart:convert';
import 'package:characters/characters.dart';
import 'models.dart';
import 'arrangement.dart';
import 'timing.dart' show timingOccurrenceMap;

SourceResult? bestLyricsFallback(Iterable<SourceResult> sources) {
  final candidates =
      sources
          .where((source) => plainLyrics(source.body).trim().isNotEmpty)
          .toList()
        ..sort((a, b) {
          int rank(SourceResult source) =>
              _norm(plainLyrics(source.body)).length.clamp(0, 100000) * 1000 +
              lyricLines(source.body).length.clamp(0, 100) +
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

void _syncMapFieldContributors(
  String field,
  Map<String, Map<String, Set<String>>> mapEntryContributors,
  Map<String, Set<String>> fieldContributors,
) {
  final contributors = <String>{
    for (final sourceIds
        in mapEntryContributors[field]?.values ?? const <Set<String>>[])
      ...sourceIds,
  };
  if (contributors.isEmpty) {
    fieldContributors.remove(field);
  } else {
    fieldContributors[field] = contributors;
  }
}

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
      offsets.addAll(List.filled(character.length, index));
    }
    pendingSeparator = false;
  }
  return (text: normalized.toString(), offsets: offsets);
}

/// Match lyric phrases rather than provider line breaks. Every character in
/// the comparison stream retains its location in the unchanged base lyrics.
Map<int, List<ChordAnchor>> _phraseChords(
  List<ArrangementLine> target,
  String chart,
) {
  final text = StringBuffer();
  final locations = <({int line, int offset})>[];
  final normalizedLines = <int, String>{};
  for (var line = 0; line < target.length; line++) {
    if (target[line].directive) continue;
    final normalized = _normalizedLine(target[line].text);
    normalizedLines[line] = normalized.text;
    if (normalized.text.isEmpty) continue;
    if (text.isNotEmpty) {
      text.write(' ');
      locations.add((line: line, offset: 0));
    }
    text.write(normalized.text);
    locations.addAll([
      for (final offset in normalized.offsets) (line: line, offset: offset),
    ]);
  }
  final haystack = text.toString();
  final words = RegExp(r'\S+').allMatches(haystack).toList();
  final phraseIndex = <int, Map<String, List<int>>>{};
  List<int> startsFor(String phrase) {
    final tokens = phrase.split(' ');
    final count = tokens.length.clamp(1, 3);
    final index = phraseIndex.putIfAbsent(count, () {
      final value = <String, List<int>>{};
      for (var i = 0; i + count <= words.length; i++) {
        final key = haystack.substring(
          words[i].start,
          words[i + count - 1].end,
        );
        value.putIfAbsent(key, () => []).add(words[i].start);
      }
      return value;
    });
    return index[tokens.take(count).join(' ')] ?? const [];
  }

  final phrases = <String, List<ArrangementLine>>{};
  for (final line in parseArrangement(chart)) {
    final phrase = _normalizedLine(line.text).text;
    if (line.directive || line.chords.isEmpty || phrase.isEmpty) continue;
    phrases.putIfAbsent(phrase, () => []).add(line);
  }
  final result = <int, List<ChordAnchor>>{};
  // Bound synchronous matching even for deliberately repetitive documents.
  // Unplaced chart data remains in the original source document.
  var comparisonBudget = (haystack.length + chart.length) * 8;
  phrasesLoop:
  for (final entry in phrases.entries) {
    // Repeated words can have different harmonies in different sections.
    if (entry.value.map(_chordSignature).toSet().length != 1) continue;
    final donor = entry.value.first;
    final normalized = _normalizedLine(donor.text);
    final matches = <({int start, int end, bool wholeLine})>[];
    for (final start in startsFor(entry.key)) {
      comparisonBudget -= entry.key.length;
      if (comparisonBudget < 0) break phrasesLoop;
      final end = start + entry.key.length;
      if (!haystack.startsWith(entry.key, start) ||
          (start > 0 && haystack[start - 1] != ' ') ||
          (end < haystack.length && haystack[end] != ' ')) {
        continue;
      }
      final first = locations[start];
      final last = locations[end - 1];
      final wholeLine =
          first.line == last.line && normalizedLines[first.line] == entry.key;
      // Short phrases require a whole-line match; common one-word fragments
      // are insufficient evidence for a chord placement inside another line.
      if (entry.key.split(' ').length < 3 && !wholeLine) {
        continue;
      }
      matches.add((start: start, end: end, wholeLine: wholeLine));
    }
    // A single partial phrase does not identify which of several different
    // passages shares its harmony. Require enough agreeing donor occurrences
    // for those placements. Complete repeated lyric lines retain the existing
    // whole-line overlay behavior.
    final ambiguous = matches.length > entry.value.length;
    for (final match in matches) {
      if (ambiguous && !match.wholeLine) continue;
      final start = match.start, end = match.end;
      for (final chord in donor.chords) {
        var index = normalized.offsets
            .where((offset) => offset < chord.offset)
            .length;
        while (index < normalized.text.length &&
            normalized.text[index] == ' ') {
          index++;
        }
        final atEnd = index >= normalized.text.length;
        final location = locations[atEnd ? end - 1 : start + index];
        final offset = location.offset + (atEnd ? 1 : 0);
        final line = target[location.line];
        if (line.chords.isNotEmpty ||
            (offset > 0 &&
                line.text.characters.elementAt(offset - 1) == '\\')) {
          continue;
        }
        final anchors = result.putIfAbsent(location.line, () => []);
        if (!anchors.any((a) => a.offset == offset && a.chord == chord.chord)) {
          anchors.add(ChordAnchor(offset, chord.chord));
        }
      }
    }
  }
  result.removeWhere((_, anchors) {
    final byOffset = <int, Set<String>>{};
    for (final anchor in anchors) {
      byOffset.putIfAbsent(anchor.offset, () => {}).add(anchor.chord);
    }
    return byOffset.values.any((chords) => chords.length > 1);
  });
  return result;
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

({String body, List<String> sourceIds}) _overlaySections(
  String body,
  List<SourceResult> sources,
  SourceResult base,
) {
  List<String> lyricLinesFor(String value) => [
    for (final line in parseArrangement(value))
      if (!line.directive && sectionLabelForLine(line) == null)
        _normalizedLine(line.text).text,
  ].where((line) => line.isNotEmpty).toList();

  final baseLines = lyricLinesFor(body);
  if (baseLines.isEmpty) return (body: body, sourceIds: const []);

  Map<int, String> sectionsByLyricLine(String value) {
    final sections = <int, String>{};
    var lyricIndex = 0;
    String? pending;
    for (final line in parseArrangement(value)) {
      final label = sectionLabelForLine(line);
      if (label != null) {
        pending = label;
        continue;
      }
      if (line.directive) continue;
      if (_normalizedLine(line.text).text.isEmpty) continue;
      if (pending != null) {
        sections.putIfAbsent(lyricIndex, () => pending!);
        pending = null;
      }
      lyricIndex++;
    }
    return sections;
  }

  final existing = sectionsByLyricLine(body);
  final votes = <int, Map<String, Set<String>>>{};
  for (final source in sources) {
    if (source.id == base.id || source.body.trim().isEmpty) continue;
    final sourceLines = lyricLinesFor(source.body);
    if (sourceLines.length != baseLines.length) continue;
    var aligned = true;
    for (var index = 0; index < baseLines.length; index++) {
      if (sourceLines[index] != baseLines[index]) {
        aligned = false;
        break;
      }
    }
    if (!aligned) continue;
    for (final entry in sectionsByLyricLine(source.body).entries) {
      if (existing.containsKey(entry.key)) continue;
      votes
          .putIfAbsent(entry.key, () => {})
          .putIfAbsent(entry.value, () => <String>{})
          .add(source.id);
    }
  }
  if (votes.isEmpty) return (body: body, sourceIds: const []);

  final selectedLabels = <int, String>{};
  final contributors = <String>{};
  for (final entry in votes.entries) {
    final labels = entry.value.entries.toList()
      ..sort((a, b) {
        final count = b.value.length.compareTo(a.value.length);
        return count != 0 ? count : a.key.compareTo(b.key);
      });
    if (labels.length > 1 && labels[0].value.length == labels[1].value.length) {
      continue;
    }
    selectedLabels[entry.key] = labels.first.key;
    contributors.addAll(labels.first.value);
  }
  if (selectedLabels.isEmpty) return (body: body, sourceIds: const []);

  final rawLines = body.replaceAll('\r\n', '\n').split('\n');
  final arrangement = parseArrangement(body);
  final output = <String>[];
  var lyricIndex = 0;
  for (var index = 0; index < arrangement.length; index++) {
    final line = arrangement[index];
    final label = selectedLabels[lyricIndex];
    if (!line.directive &&
        sectionLabelForLine(line) == null &&
        _normalizedLine(line.text).text.isNotEmpty) {
      if (label != null) output.add('{comment: $label}');
      lyricIndex++;
    }
    output.add(rawLines[index]);
  }
  return (body: output.join('\n'), sourceIds: contributors.toList()..sort());
}

int _notePitch(String note) {
  const naturals = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  return (naturals[note[0].toUpperCase()]! +
          note
              .substring(1)
              .split('')
              .fold<int>(
                0,
                (value, accidental) =>
                    value + (accidental == '#' || accidental == '♯' ? 1 : -1),
              )) %
      12;
}

final _explicitKey = RegExp(
  r'^([A-G][#b♯♭]{0,2})\s*(m|min|minor|maj|major)?$',
  caseSensitive: false,
);
String? _keyIdentity(Object? value) {
  if (value is! String) return null;
  final match = _explicitKey.firstMatch(value.trim());
  if (match == null) return null;
  final mode = match[2]?.toLowerCase();
  return '${_notePitch(match[1]!)}:${const {'m', 'min', 'minor'}.contains(mode) ? 'minor' : 'major'}';
}

// This compares transposition and triad identity, not interchangeable voicings.
// Plain/dominant/major-seventh extensions can agree on the source key without
// replacing any chords. Alterations, suspensions and slash basses stay distinct.
String? _harmonyIdentity(String chord) {
  final match = RegExp(
    r'^([A-G][#b♯♭]{0,2})(.*?)(?:/([A-G][#b♯♭]{0,2}))?$',
  ).firstMatch(chord);
  if (match == null) return null;
  final suffix = match[2]!;
  final String quality;
  if (RegExp(r'^(?:(?:maj|M)?(?:6|7|9|11|13))?$').hasMatch(suffix)) {
    quality = 'major';
  } else if (RegExp(r'^(?:m|min)(?:6|7|9|11|13)?$').hasMatch(suffix)) {
    quality = 'minor';
  } else {
    quality = suffix.replaceAll('♯', '#').replaceAll('♭', 'b');
  }
  final root = _notePitch(match[1]!);
  return '$root:$quality:${match[3] == null ? root : _notePitch(match[3]!)}';
}

bool _compatibleMetadataKeySource(SongDocument song, SourceResult source) {
  final selected =
      song.selectedRecording ??
      SongCandidate(
        providerId: 'library',
        id: song.id,
        title: song.title,
        artist: song.artist,
      );
  if (!_sameSong(selected, source.candidate) ||
      _version(selected.title) != _version(source.candidate.title) ||
      selected.recordingIds.entries.any(
        (entry) =>
            source.candidate.recordingIds.containsKey(entry.key) &&
            source.candidate.recordingIds[entry.key] != entry.value,
      ) ||
      (selected.durationSeconds != null &&
          source.candidate.durationSeconds != null &&
          (selected.durationSeconds! - source.candidate.durationSeconds!)
                  .abs() >
              3)) {
    return false;
  }
  for (final field in const ['capo', 'tuning', 'timeSignature']) {
    final base = song.metadata[field] ?? selected.metadata[field];
    final donor = source.metadata[field] ?? source.candidate.metadata[field];
    if (_hasMetadata(base) != _hasMetadata(donor)) return false;
    if (!_hasMetadata(base)) continue;
    String normalize(Object? value) {
      if (field == 'tuning') {
        final text = value is List ? value.join(' ') : value.toString();
        return text
            .toLowerCase()
            .split(RegExp(r'[\s,\[\]]+'))
            .where((note) => note.isNotEmpty)
            .join(' ');
      }
      return value.toString().trim().toLowerCase();
    }

    if (normalize(base) != normalize(donor)) return false;
  }
  return true;
}

/// Recovers a supplied key only from charts corroborated against the actual
/// saved chords. Catalog keys and the first chord are not key evidence. This is
/// also usable for old saved imports, without rewriting their library records.
({String key, List<String> sourceIds})? corroboratedArrangementKey(
  SongDocument song,
) {
  if (_hasMetadata(song.metadata['key']) ||
      jsonMap(song.extra['fieldOrigins'])['key'] == 'user' ||
      !song.hasChords) {
    return null;
  }
  final selected =
      song.selectedRecording ??
      SongCandidate(
        providerId: 'library',
        id: song.id,
        title: song.title,
        artist: song.artist,
      );
  final lines = parseArrangement(song.body);
  final plain = [
    for (final line in lines)
      ArrangementLine(line.text, const [], directive: line.directive),
  ];
  final claims = <String, ({String key, List<String> sourceIds})>{};
  for (final source in song.sources) {
    if (!source.hasChords ||
        !(const {
              MatchKind.sameSong,
              MatchKind.sameRecording,
            }.contains(source.matchKind) ||
            // A shortened chart can be rejected as a full lyric replacement,
            // while still supplying a key corroborated against chosen chords.
            (source.matchKind == MatchKind.rejected &&
                source.matchReason == 'incomplete_or_different_lyrics')) ||
        source.extra['pendingMatchCheck'] == true ||
        !_sameSong(source.candidate, selected) ||
        _version(source.candidate.title) != _version(selected.title)) {
      continue;
    }
    final key = _keyIdentity(source.metadata['key']) != null
        ? source.metadata['key'] as String
        : source.candidate.metadata['key'];
    final identity = _keyIdentity(key);
    if (identity == null) continue;
    var compatible = true;
    for (final field in const ['capo', 'tuning', 'timeSignature']) {
      final baseValue = song.metadata[field];
      final donorValue =
          source.metadata[field] ?? source.candidate.metadata[field];
      String normalize(Object? value) {
        // ChordPro headers serialize list tuning as "[E, A, ...]". Compare
        // those saved headers with the provider's equivalent string array.
        if (field == 'tuning') {
          final text = value is List ? value.join(' ') : value.toString();
          return text
              .toLowerCase()
              .split(RegExp(r'[\s,\[\]]+'))
              .where((note) => note.isNotEmpty)
              .join(' ');
        }
        return value.toString().trim().toLowerCase();
      }

      // Unknown capo/tuning cannot prove that displayed shapes sound alike.
      if ((_hasMetadata(baseValue) != _hasMetadata(donorValue)) ||
          (_hasMetadata(baseValue) &&
              normalize(baseValue) != normalize(donorValue))) {
        compatible = false;
        break;
      }
    }
    if (!compatible) continue;
    final aligned = _phraseChords(plain, source.body);
    var agreements = 0, contradicts = false;
    final roots = <String>{}, matchedLines = <int>{};
    for (final entry in aligned.entries) {
      for (final anchor in entry.value) {
        final donor = _harmonyIdentity(anchor.chord);
        if (donor == null) continue;
        final previous = lines[entry.key].chords.where(
          (a) => a.offset == anchor.offset,
        );
        if (previous.isEmpty) continue;
        if (previous.any((a) => _harmonyIdentity(a.chord) != donor)) {
          contradicts = true;
          break;
        }
        agreements++;
        roots.add(donor.split(':').first);
        matchedLines.add(entry.key);
      }
      if (contradicts) break;
    }
    if (contradicts ||
        agreements < 3 ||
        roots.length < 3 ||
        matchedLines.length < 2 ||
        !roots.contains(identity.split(':').first)) {
      continue;
    }
    final claim = claims.putIfAbsent(
      identity,
      () => (key: (key as String).trim(), sourceIds: []),
    );
    claim.sourceIds.add(source.id);
  }
  // A relative-major/minor disagreement cannot be resolved by matching roots.
  return claims.length == 1 ? claims.values.single : null;
}

/// Returns one non-conflicting provider key for this song.
///
/// A key attached to a chord chart must first pass the stricter chord
/// corroboration above. A lyrics-only source can still contribute its
/// explicit key when it is positively matched to the same song and edition;
/// a bare catalog/search candidate or an unverified result cannot. If
/// providers disagree, leave the field unresolved rather than picking the
/// first result. This keeps key metadata independent from which provider's
/// lyrics were selected while retaining its source provenance.
({String key, List<String> sourceIds})? sourcedArrangementKey(
  SongDocument song,
) {
  if (_hasMetadata(song.metadata['key']) ||
      jsonMap(song.extra['fieldOrigins'])['key'] == 'user') {
    return null;
  }
  final claims = <String, ({String key, List<String> sourceIds})>{};
  for (final source in song.sources) {
    if (source.hasChords ||
        !const {
          MatchKind.sameSong,
          MatchKind.sameRecording,
        }.contains(source.matchKind) ||
        source.extra['pendingMatchCheck'] == true ||
        !_compatibleMetadataKeySource(song, source)) {
      continue;
    }
    final key = _keyIdentity(source.metadata['key']) != null
        ? source.metadata['key'] as String
        : source.candidate.metadata['key'];
    final identity = _keyIdentity(key);
    if (identity == null) continue;
    final claim = claims.putIfAbsent(
      identity,
      () => (key: (key as String).trim(), sourceIds: []),
    );
    claim.sourceIds.add(source.id);
  }

  // Chord-bearing metadata remains subject to line-level corroboration.
  final chartClaim = corroboratedArrangementKey(song);
  if (chartClaim != null) {
    final identity = _keyIdentity(chartClaim.key)!;
    final claim = claims.putIfAbsent(identity, () => chartClaim);
    for (final id in chartClaim.sourceIds) {
      if (!claim.sourceIds.contains(id)) claim.sourceIds.add(id);
    }
  }
  return claims.length == 1 ? claims.values.single : null;
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
  final plain = [
    for (final line in lines)
      ArrangementLine(line.text, const [], directive: line.directive),
  ];
  final candidates =
      <
        ({
          SourceResult source,
          Map<int, List<ChordAnchor>> chords,
          int coverage,
          int confidence,
        })
      >[];
  for (final source in sources) {
    if (!source.hasChords ||
        !_compatibleArrangementSetup(base, source, selected)) {
      continue;
    }
    final chords = _phraseChords(plain, source.body);
    final coverage = chords.entries.fold<int>(
      0,
      (n, entry) =>
          n + (lines[entry.key].chords.isEmpty ? entry.value.length : 0),
    );
    if (coverage == 0) continue;
    final confidence = recordingCompatible(selected, source)
        ? 2
        : source.matchKind == MatchKind.sameSong
        ? 1
        : 0;
    candidates.add((
      source: source,
      chords: chords,
      coverage: coverage,
      confidence: confidence,
    ));
  }
  candidates.sort((a, b) {
    final confidence = b.confidence.compareTo(a.confidence);
    if (confidence != 0) return confidence;
    final score = b.coverage.compareTo(a.coverage);
    return score != 0 ? score : a.source.id.compareTo(b.source.id);
  });
  final chartChords = <int, List<ChordAnchor>>{
    for (var i = 0; i < lines.length; i++)
      if (lines[i].chords.isNotEmpty) i: lines[i].chords,
  };
  SourceResult? primary = base.hasChords ? base : null;
  final contributorIds = <String>[];
  for (final candidate in candidates) {
    if (primary != null) {
      if (!_compatibleArrangementSetup(primary, candidate.source, selected)) {
        continue;
      }
      var agrees = false, contradicts = false;
      for (final entry in candidate.chords.entries) {
        final previous = chartChords[entry.key];
        if (previous == null) continue;
        for (final anchor in entry.value) {
          final sameOffset = previous.where((a) => a.offset == anchor.offset);
          if (sameOffset.isEmpty) continue;
          if (sameOffset.any((a) => a.chord != anchor.chord)) {
            contradicts = true;
          } else {
            agrees = true;
          }
        }
      }
      Object? explicitSetupValue(SourceResult source, String key) =>
          source.metadata[key] ?? source.candidate.metadata[key];
      final primaryKey = explicitSetupValue(primary, 'key');
      final donorKey = explicitSetupValue(candidate.source, 'key');
      final explicitSetup =
          primaryKey != null &&
          donorKey != null &&
          const ['capo', 'tuning', 'timeSignature'].every(
            (key) =>
                (explicitSetupValue(primary!, key) == null) ==
                (explicitSetupValue(candidate.source, key) == null),
          );
      if (contradicts || (!agrees && !explicitSetup)) continue;
    }
    var added = false;
    for (final entry in candidate.chords.entries) {
      if (chartChords.containsKey(entry.key)) continue;
      chartChords[entry.key] = entry.value;
      added = true;
    }
    if (added) {
      primary ??= candidate.source;
      contributorIds.add(candidate.source.id);
    }
  }
  if (contributorIds.isEmpty) return (body: body, sourceIds: const []);

  final rawLines = body.split('\n');
  final output = <String>[];
  var applied = false;
  for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    final line = lines[lineIndex];
    final rawLine = rawLines[lineIndex];
    final chords = chartChords[lineIndex];
    if (line.directive || line.chords.isNotEmpty || chords == null) {
      output.add(rawLine);
      continue;
    }
    if (chords.isEmpty) {
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
    sourceIds: applied ? contributorIds : const [],
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
      _norm(plainLyrics(s.body)).length.clamp(0, 100000) * 1000 +
      lyricLines(s.body).length.clamp(0, 100) +
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
  final merged = preferredSourceId == null
      ? _overlayChords(
          best.body,
          accepted.where((source) => source.id != best.id).toList(),
          selected,
          best,
        )
      : (body: best.body, sourceIds: const <String>[]);
  final sectionMerged = preferredSourceId == null
      ? _overlaySections(
          merged.body,
          accepted.where((source) => source.id != best.id).toList(),
          best,
        )
      : (body: merged.body, sourceIds: const <String>[]);
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
  metadata.removeWhere((_, value) => !_hasMetadata(value));
  final selectedDuration =
      _validDuration(selected.durationSeconds) ??
      _validDuration(selected.metadata['durationSeconds']) ??
      _validDuration(selected.metadata['duration']);
  if (selectedDuration == null) {
    metadata.remove('durationSeconds');
  } else {
    metadata['durationSeconds'] = selectedDuration;
  }
  metadata.removeWhere((key, _) => arrangementFields.contains(key));
  final origins = <String, dynamic>{
    for (final k in metadata.keys) k: selected.identity,
  };
  final fieldContributors = <String, Set<String>>{
    for (final k in metadata.keys) k: {selected.identity},
  };
  final mapEntryContributors = <String, Map<String, Set<String>>>{
    for (final entry in metadata.entries)
      if (entry.value is Map)
        entry.key: {
          for (final mapKey in jsonMap(entry.value).keys)
            mapKey: {selected.identity},
        },
  };
  final selectedMapEntryKeys = <String, Set<String>>{
    for (final entry in metadata.entries)
      if (entry.value is Map)
        entry.key: {
          for (final item in jsonMap(entry.value).entries)
            if (_hasMetadata(item.value)) item.key,
        },
  };
  final chordSourceIds = <String>{
    if (best.hasChords) best.id,
    ...merged.sourceIds,
  }.toList();
  if (chordSourceIds.isNotEmpty) origins['chords'] = chordSourceIds.first;
  final sectionSourceIds = <String>{
    if (parseArrangement(
      best.body,
    ).any((line) => sectionLabelForLine(line) != null))
      best.id,
    ...sectionMerged.sourceIds,
  }.toList()..sort();
  if (sectionSourceIds.isNotEmpty) {
    origins['sections'] = sectionSourceIds.first;
    fieldContributors['sections'] = sectionSourceIds.toSet();
  }
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
      fieldContributors['durationSeconds'] = {best.id};
    }
  }
  // Metadata providers often expose useful fields that did not exist when the
  // app's canonical metadata schema was written. Keep combining safe facts by
  // default, while excluding merge-control, provider-internal, and separately
  // scoped data. Recording-specific fields need verified recording identity;
  // arrangement fields have the stricter chord-source rule above.
  const recordingFields = {
    'album',
    'artworkUrl',
    'duration',
    'durationSeconds',
    'mediaLinks',
    'recording',
    'releaseDate',
    'year',
  };
  const nonFactFields = {
    'identityScope',
    'query',
    'record',
    'rights',
    'url',
    'providerId',
    'id',
    'title',
    'artist',
    'lyrics',
    'body',
    'hasLyrics',
    'pendingMatchCheck',
    'sourceId',
    'timingTracks',
    'fieldOrigins',
    'fieldContributors',
    'conflicts',
  };
  final remaining = matching.where((s) => s.id != best.id).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  for (final source in [best, ...remaining]) {
    final candidateDuration =
        _validDuration(source.candidate.durationSeconds) ??
        _validDuration(source.candidate.metadata['durationSeconds']) ??
        _validDuration(source.candidate.metadata['duration']);
    final facts = {
      ...source.candidate.metadata,
      if (source.candidate.album != null) 'album': source.candidate.album,
      'durationSeconds': candidateDuration,
      ...source.metadata,
    };
    final sourceDuration =
        _validDuration(source.metadata['durationSeconds']) ??
        candidateDuration ??
        _validDuration(facts['duration']);
    if (facts.containsKey('duration') &&
        _validDuration(facts['duration']) == null) {
      facts.remove('duration');
    }
    if (facts.containsKey('durationSeconds') && sourceDuration == null) {
      facts.remove('durationSeconds');
    } else if (sourceDuration != null) {
      facts['durationSeconds'] = sourceDuration;
    }
    final sameRecording = recordingCompatible(selected, source);
    // A catalog search hit may lack duration or album although its resolved
    // lyrics identify the album. A matching album can supply missing display
    // facts without claiming recording identity or activating its timing.
    final knownAlbum = metadata['album'];
    final foundAlbum = source.candidate.album ?? source.metadata['album'];
    final knownDuration = _validDuration(metadata['durationSeconds']);
    final scoped =
        source.candidate.metadata['identityScope'] ??
        source.metadata['identityScope'] ??
        source.extra['identityScope'];
    final imageScoped = scoped == 'image';
    if (scoped == 'recording' && !sameRecording) continue;
    final matchingAlbumDisplay =
        source.matchKind == MatchKind.sameSong &&
        !{
          'composition',
          'work',
          'arrangement',
          'artist',
          'image',
        }.contains(scoped) &&
        selected.recordingIds.isEmpty &&
        knownAlbum is String &&
        knownAlbum.trim().isNotEmpty &&
        foundAlbum is String &&
        _norm(knownAlbum) == _norm(foundAlbum) &&
        _version(selected.title) == _version(source.candidate.title) &&
        (knownDuration == null ||
            sourceDuration == null ||
            (knownDuration - sourceDuration).abs() <= 3);
    for (final entry in facts.entries) {
      if (!_hasMetadata(entry.value)) continue;
      final isArrangement = arrangementFields.contains(entry.key);
      if (isArrangement && !arrangementSourceIds.contains(source.id)) continue;
      if (nonFactFields.contains(entry.key) || imageScoped) continue;
      final isRecordingField = recordingFields.contains(entry.key);
      if (isRecordingField &&
          !sameRecording &&
          !(matchingAlbumDisplay &&
              const {'duration', 'durationSeconds'}.contains(entry.key))) {
        continue;
      }
      if (!metadata.containsKey(entry.key) &&
          conflicts.containsKey(entry.key)) {
        (conflicts[entry.key] as List<dynamic>).add({
          'sourceId': source.id,
          'value': entry.value,
        });
        fieldContributors.putIfAbsent(entry.key, () => {}).add(source.id);
        continue;
      }
      if (entry.value is Map && !metadata.containsKey(entry.key)) {
        final available = <String, dynamic>{};
        for (final mapEntry in jsonMap(entry.value).entries) {
          if (!_hasMetadata(mapEntry.value)) continue;
          final conflictKey = '${entry.key}.${mapEntry.key}';
          if (conflicts.containsKey(conflictKey)) {
            (conflicts[conflictKey] as List<dynamic>).add({
              'sourceId': source.id,
              'value': mapEntry.value,
            });
          } else {
            available[mapEntry.key] = mapEntry.value;
          }
        }
        if (available.isEmpty) continue;
        metadata[entry.key] = available;
        origins[entry.key] = source.id;
        mapEntryContributors[entry.key] = {
          for (final mapKey in available.keys) mapKey: {source.id},
        };
        _syncMapFieldContributors(
          entry.key,
          mapEntryContributors,
          fieldContributors,
        );
        continue;
      }
      if (!metadata.containsKey(entry.key) || metadata[entry.key] == null) {
        metadata[entry.key] = entry.value;
        origins[entry.key] = source.id;
        fieldContributors[entry.key] = {source.id};
        if (entry.value is Map) {
          mapEntryContributors[entry.key] = {
            for (final mapKey in jsonMap(entry.value).keys) mapKey: {source.id},
          };
        }
      } else {
        if (jsonEncode(metadata[entry.key]) == jsonEncode(entry.value)) {
          if (entry.value is Map) {
            final contributors = mapEntryContributors.putIfAbsent(
              entry.key,
              () => {
                for (final mapKey in jsonMap(entry.value).keys)
                  mapKey: {origins[entry.key] ?? selected.identity},
              },
            );
            for (final mapKey in jsonMap(entry.value).keys) {
              if (_hasMetadata(jsonMap(entry.value)[mapKey]) &&
                  !conflicts.containsKey('${entry.key}.$mapKey')) {
                contributors.putIfAbsent(mapKey, () => {}).add(source.id);
              }
            }
            _syncMapFieldContributors(
              entry.key,
              mapEntryContributors,
              fieldContributors,
            );
          } else {
            fieldContributors.putIfAbsent(entry.key, () => {}).add(source.id);
          }
          continue;
        }
        if (entry.value is! Map) {
          fieldContributors.putIfAbsent(entry.key, () => {}).add(source.id);
        }
        // Lists are additive credits, links, identifiers and other source
        // facts. Arrangement setup arrays (notably tuning) remain one choice.
        if (!isArrangement &&
            metadata[entry.key] is List &&
            entry.value is List) {
          final seen = <String>{};
          final values = [
            for (final value in [
              ...metadata[entry.key] as List,
              ...entry.value as List,
            ])
              if (seen.add(jsonEncode(value))) value,
          ];
          if (values.length > (metadata[entry.key] as List).length) {
            metadata[entry.key] = values;
            fieldContributors.putIfAbsent(entry.key, () => {}).add(source.id);
          }
          continue;
        }
        if (!isArrangement &&
            metadata[entry.key] is Map &&
            entry.value is Map) {
          final current = Map<String, dynamic>.from(
            jsonMap(metadata[entry.key]),
          );
          final contributors = mapEntryContributors.putIfAbsent(
            entry.key,
            () => {
              for (final mapKey in current.keys)
                mapKey: {origins[entry.key] ?? selected.identity},
            },
          );
          var changed = false;
          for (final mapEntry in jsonMap(entry.value).entries) {
            if (!_hasMetadata(mapEntry.value)) continue;
            final conflictKey = '${entry.key}.${mapEntry.key}';
            if (conflicts.containsKey(conflictKey)) {
              (conflicts[conflictKey] as List<dynamic>).add({
                'sourceId': source.id,
                'value': mapEntry.value,
              });
              continue;
            }
            if (!current.containsKey(mapEntry.key) ||
                !_hasMetadata(current[mapEntry.key])) {
              current[mapEntry.key] = mapEntry.value;
              contributors[mapEntry.key] = {source.id};
              changed = true;
            } else if (jsonEncode(current[mapEntry.key]) !=
                jsonEncode(mapEntry.value)) {
              final values =
                  conflicts.putIfAbsent(
                        conflictKey,
                        () => <dynamic>[
                          for (final priorSource
                              in contributors[mapEntry.key] ??
                                  {origins[entry.key] ?? selected.identity})
                            {
                              'sourceId': priorSource,
                              'value': current[mapEntry.key],
                            },
                        ],
                      )
                      as List<dynamic>;
              values.add({'sourceId': source.id, 'value': mapEntry.value});
              if (!(selectedMapEntryKeys[entry.key]?.contains(mapEntry.key) ??
                  false)) {
                current.remove(mapEntry.key);
                contributors.remove(mapEntry.key);
                changed = true;
              }
            } else {
              contributors.putIfAbsent(mapEntry.key, () => {}).add(source.id);
            }
          }
          if (changed) {
            if (current.isEmpty) {
              metadata.remove(entry.key);
              origins.remove(entry.key);
              fieldContributors.remove(entry.key);
              mapEntryContributors.remove(entry.key);
            } else {
              metadata[entry.key] = current;
              _syncMapFieldContributors(
                entry.key,
                mapEntryContributors,
                fieldContributors,
              );
            }
          } else {
            _syncMapFieldContributors(
              entry.key,
              mapEntryContributors,
              fieldContributors,
            );
          }
          continue;
        }
        final priorOrigin = origins[entry.key];
        final values =
            conflicts.putIfAbsent(
                  entry.key,
                  () => <dynamic>[
                    {'sourceId': priorOrigin, 'value': metadata[entry.key]},
                  ],
                )
                as List<dynamic>;
        values.add({'sourceId': source.id, 'value': entry.value});
        // Keep an explicit selected-candidate fact, but don't let iteration
        // order silently choose between conflicting provider claims.
        if (priorOrigin != selected.identity && !isArrangement) {
          metadata.remove(entry.key);
          origins.remove(entry.key);
          fieldContributors.remove(entry.key);
        }
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
  final song = SongDocument(
    id: newId(),
    title: selected.title,
    artist: selected.artist,
    body: inferSectionDirectives(sectionMerged.body),
    metadata: metadata,
    sources: results,
    timingTracks: tracks.values.toList(),
    selectedRecording: selected,
    activeTimingTrackId: usable.isEmpty ? null : usable.first.id,
    extra: {
      'selectedSourceId': best.id,
      'fieldOrigins': origins,
      'fieldContributors': {
        for (final entry in fieldContributors.entries)
          entry.key: entry.value.toList(),
      },
      if (conflicts.isNotEmpty) 'conflicts': conflicts,
      'recommendation':
          'Combined lyrics, chords, timing, and metadata from matching sources.',
      if (chordSourceIds.isNotEmpty) 'chordSourceIds': chordSourceIds,
      if (sectionSourceIds.isNotEmpty) 'sectionSourceIds': sectionSourceIds,
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
  final corroboratedKey = corroboratedArrangementKey(song);
  final recoveredKey = sourcedArrangementKey(song);
  if (recoveredKey != null) {
    metadata['key'] = recoveredKey.key;
    origins['key'] = recoveredKey.sourceIds.first;
    (song.extra['fieldContributors'] as Map<String, dynamic>)['key'] =
        recoveredKey.sourceIds;
    song.extra['keySourceIds'] = recoveredKey.sourceIds;
    if (corroboratedKey != null &&
        _keyIdentity(corroboratedKey.key) == _keyIdentity(recoveredKey.key)) {
      song.extra['corroboratedKeySourceIds'] = corroboratedKey.sourceIds;
    }
  }
  return song;
}

bool _hasMetadata(Object? value) =>
    value != null &&
    (value is! String || value.trim().isNotEmpty) &&
    (value is! Iterable || value.isNotEmpty) &&
    (value is! Map || value.isNotEmpty);
