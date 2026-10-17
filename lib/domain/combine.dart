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
      fieldContributors['durationSeconds'] = {best.id};
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
    'composers',
    'lyricists',
    'credits',
    'genres',
    'compositionYear',
    'wikidataId',
    'description',
    'types',
    'performerIds',
    'partOf',
    'publicationDates',
    'durationClaims',
    'externalIdentifiers',
    'wikimediaCommonsFile',
    'licensedImages',
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
      if (!isArrangement &&
          !songFields.contains(entry.key) &&
          !sameRecording &&
          !(matchingAlbumDisplay &&
              const {'duration', 'durationSeconds'}.contains(entry.key))) {
        continue;
      }
      if (!metadata.containsKey(entry.key) || metadata[entry.key] == null) {
        metadata[entry.key] = entry.value;
        origins[entry.key] = source.id;
        fieldContributors[entry.key] = {source.id};
      } else if (jsonEncode(metadata[entry.key]) != jsonEncode(entry.value)) {
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
      'fieldContributors': {
        for (final entry in fieldContributors.entries)
          entry.key: entry.value.toList(),
      },
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

bool _hasMetadata(Object? value) =>
    value != null &&
    (value is! String || value.trim().isNotEmpty) &&
    (value is! Iterable || value.isNotEmpty) &&
    (value is! Map || value.isNotEmpty);
