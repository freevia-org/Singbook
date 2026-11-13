import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'models.dart';
import 'edition_identity.dart';
import 'metadata_enrichment.dart';
import 'arrangement.dart';
import 'artist_credit.dart';
import 'reviewed_chart_artist.dart';
import 'metadata_artist_credit.dart';
import 'published_name_alias.dart';
import 'search_grouping.dart' show rowAlbumKey, rowDurationKey, withoutRowFacts;
import 'arrangement_context.dart';
import 'contextual_chart_lyrics.dart';
import 'compact_chord_alignment.dart';
import 'lyric_word_identity.dart';
import 'short_lyric_reference.dart';
import 'chord_key_estimate.dart'
    show
        estimateChordKey,
        ChordKeyEstimate,
        rankChordKeyCandidates,
        chartSupportsDeclaredTonic,
        chartSupportsBoundaryTonic;
import 'evidence_ranking.dart';
import 'evidence_values.dart';
import 'source_evidence.dart';
import 'chart_arrangements.dart';
import 'timing.dart' show timingOccurrenceMap;

part 'combine_alignment.dart';
part 'combine_evidence_views.dart';
part 'combine_historical.dart';
part 'combine_key_math.dart';
part 'combine_ranking.dart';

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

String _norm(String text) => normalizedEvidenceText(text);

/// Whether [source], found as the same song, may lend display facts to
/// [selected] through a matching album name.
bool _lendsAlbumDisplay(
  SongCandidate selected,
  SourceResult source,
  String album,
) {
  final scoped =
      source.candidate.metadata['identityScope'] ??
      source.metadata['identityScope'] ??
      source.extra['identityScope'];
  final found = source.candidate.album ?? source.metadata['album'];
  return source.matchKind == MatchKind.sameSong &&
      !{
        'composition',
        'work',
        'arrangement',
        'artist',
        'image',
      }.contains(scoped) &&
      album.trim().isNotEmpty &&
      found is String &&
      _sameDisplayAlbum(album, found, selected.artist) &&
      _version(selected.title) == _version(source.candidate.title);
}

double? _sourceDuration(SourceResult source) =>
    _validDuration(source.metadata['durationSeconds']) ??
    _validDuration(source.candidate.durationSeconds) ??
    _validDuration(source.candidate.metadata['durationSeconds']) ??
    _validDuration(source.candidate.metadata['duration']) ??
    _validDuration(source.metadata['duration']);

/// The range of the durations that fall within one three-second window and
/// make up a strict majority of [durations]; null when none does, or when two
/// different windows are equally supported ([100, 103, 106]).
(double, double)? _majorityDurationRange(List<double> durations) {
  final sorted = [...durations]..sort();
  final windows = <(double, double)>{};
  var bestCount = 0;
  for (var start = 0; start < sorted.length; start++) {
    var end = start;
    while (end + 1 < sorted.length && sorted[end + 1] - sorted[start] <= 3) {
      end++;
    }
    final count = end - start + 1;
    if (count > bestCount) {
      bestCount = count;
      windows.clear();
    }
    if (count == bestCount) windows.add((sorted[start], sorted[end]));
  }
  return bestCount * 2 > sorted.length && windows.length == 1
      ? windows.single
      : null;
}

/// Whether two catalog album names name the same release for display:
/// equal once the artist's name, years, anniversaries and packaging words
/// ("Remastered", "Deluxe Edition") are set aside. "Let It Be (Remastered
/// 2009)" and "The Beatles - Let It Be" match "Let It Be"; "Let It Be...
/// Naked" and "Hotel California (Live)" keep their own words and do not.
bool _sameDisplayAlbum(String a, String b, String artist) {
  final artistWords = _norm(artist).split(' ').toSet();
  Set<String> words(String album) => {
    for (final word in _norm(album).split(' '))
      if (word.isNotEmpty &&
          !artistWords.contains(word) &&
          !_albumPackaging.contains(word) &&
          !RegExp(r'^(?:(?:19|20)\d\d|\d+(?:st|nd|rd|th))$').hasMatch(word))
        word,
  };
  final first = words(a), second = words(b);
  return first.isNotEmpty &&
      first.length == second.length &&
      first.containsAll(second);
}

const _albumPackaging = {
  'remaster',
  'remastered',
  'deluxe',
  'edition',
  'expanded',
  'anniversary',
  'special',
  'version',
  'bonus',
  'track',
  'tracks',
  'disc',
  'cd',
  'cd1',
  'cd2',
  'the',
};

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
// Catalogs and charts often omit apostrophes (e.g. "It's" / "Its"). Keep
// identity handling consistent with discovery without changing lyric phrase
// offsets or treating other word boundaries as interchangeable.
String _identityNorm(String text) => identityEvidenceText(text);
String _baseTitle(String title) => _identityNorm(
  title.replaceAll(_bracketQualifier, '').replaceAll(_dashQualifier, ''),
);
bool _sameSong(SongCandidate a, SongCandidate b) {
  final artist = _identityNorm(a.artist), title = _baseTitle(a.title);
  // Two unknown (empty) artists or titles are not evidence of the same song.
  if (artist.isEmpty || title.isEmpty) return false;
  final titles = publishedNameVariants(a.title).map(_baseTitle).toSet();
  return publishedNameVariants(b.title).map(_baseTitle).any(titles.contains) &&
      (artist == _identityNorm(b.artist) ||
          publishedNamesMatch(a.artist, b.artist) ||
          sameGeniusPrimaryCredit(a, b, _identityNorm) ||
          sameReviewedChartArtist(a, b) ||
          musicBrainzArtistCreditEvidence(a, b, _identityNorm) != null);
}

/// A chord site's arrangement of [b]'s song: chord sites may credit only
/// the main artist of "Main & Others" or "Main feat. Guest", and may drop a
/// leading article. Only for charts whose lyrics discovery has corroborated.
bool _sameArrangedSong(SongCandidate a, SongCandidate b) {
  if (_recordingIdsConflict(a, b)) return false;
  String title(String value) => _baseTitle(
    foldLyricVowelAccents(value),
  ).replaceFirst(RegExp(r'^(?:the|a|an) '), '');
  final songs = publishedNameVariants(
    a.title,
  ).map(title).where((s) => s.isNotEmpty).toSet();
  if (!publishedNameVariants(b.title).map(title).any(songs.contains)) {
    return false;
  }
  final artistA = reviewedChartArtistCredit(a)?.canonicalName ?? a.artist;
  final artistB = reviewedChartArtistCredit(b)?.canonicalName ?? b.artist;
  return artistCreditsMatch(
        artistA,
        artistB,
        (value) => _identityNorm(foldLyricVowelAccents(value)),
      ) ||
      publishedNamesMatch(artistA, artistB);
}

/// Whether [b] names a different recording than [a] under an identifier
/// scheme both carry. A scheme only one of them knows is not a conflict.
bool _recordingIdsConflict(SongCandidate a, SongCandidate b) =>
    a.recordingIds.entries.any(
      (entry) =>
          b.recordingIds.containsKey(entry.key) &&
          b.recordingIds[entry.key] != entry.value,
    );

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
  if (result.extra['recordingArrangement'] is Map ||
      result.extra['alternatePerformerChart'] == true) {
    return false;
  }
  if (!explicitEditionsCompatible(
    selected,
    result.candidate,
    metadata: result.metadata,
    extra: result.extra,
  )) {
    return false;
  }
  const nonRecordingScopes = {
    'composition',
    'work',
    'artist',
    'image',
    'arrangement',
    'historicalText',
  };
  final scopes = [
    selected.metadata['identityScope'],
    selected.extra['identityScope'],
    result.candidate.metadata['identityScope'],
    result.candidate.extra['identityScope'],
    result.metadata['identityScope'],
    result.extra['identityScope'],
  ];
  if (selected.providerId == 'wikisource' ||
      result.candidate.providerId == 'wikisource' ||
      scopes.any((scope) => scope == 'historicalText')) {
    return false;
  }
  if (result.matchKind == MatchKind.rejected ||
      !_sameSong(selected, result.candidate)) {
    return false;
  }
  final found = result.candidate;
  if (_version(selected.title) != _version(found.title)) return false;
  if (_recordingIdsConflict(selected, found)) return false;
  if (selected.durationSeconds != null &&
      found.durationSeconds != null &&
      (selected.durationSeconds! - found.durationSeconds!).abs() > 3) {
    return false;
  }
  // Provider identity can name a composition, work, artist, or image. Only
  // treat identical candidate IDs as recording evidence when that identity
  // is explicitly scoped to a recording (or is a legacy unscoped ID).
  if (selected.identity == found.identity &&
      !scopes.any(nonRecordingScopes.contains)) {
    return true;
  }
  if (selected.recordingIds.entries.any(
    (e) => found.recordingIds[e.key] == e.value,
  )) {
    return true;
  }
  // Album and duration can associate ordinary recording search results, but
  // they cannot turn a composition/arrangement-level source into a recording.
  if (scopes.any(nonRecordingScopes.contains)) return false;
  return result.matchKind == MatchKind.sameRecording &&
      selected.album != null &&
      found.album != null &&
      _norm(selected.album!) == _norm(found.album!) &&
      selected.durationSeconds != null &&
      found.durationSeconds != null;
}

bool _completeChart(String chart, String reference) {
  List<String> words(String value) => _norm(
    foldLyricVowelAccents(plainLyrics(value)),
  ).split(' ').where((w) => w.isNotEmpty).toList();
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
  final displayLabels = <String, Set<String>>{};
  String sectionIdentity(String label) => label
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceFirstMapped(
        RegExp(r'^(pre|post)[ -]?chorus(?=\s|$)'),
        (match) => '${match.group(1)}-chorus',
      );
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
      final identity = sectionIdentity(entry.value);
      displayLabels.putIfAbsent(identity, () => <String>{}).add(entry.value);
      votes
          .putIfAbsent(entry.key, () => {})
          .putIfAbsent(identity, () => <String>{})
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
    // Vote on section identity, but keep a deterministic provider display label.
    final spellings = displayLabels[labels.first.key]!.toList()..sort();
    selectedLabels[entry.key] = spellings.first;
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

/// The recording a saved song was chosen for, or the library entry itself
/// for a song saved without one.
SongCandidate _selectedOrLibrary(SongDocument song) =>
    song.selectedRecording ??
    SongCandidate(
      providerId: 'library',
      id: song.id,
      title: song.title,
      artist: song.artist,
    );

bool _compatibleMetadataKeySource(SongDocument song, SourceResult source) {
  final selected = _selectedOrLibrary(song);
  if (!explicitEditionsCompatible(
        selected,
        source.candidate,
        metadata: source.metadata,
        extra: source.extra,
      ) ||
      !_sameSong(selected, source.candidate) ||
      _version(selected.title) != _version(source.candidate.title) ||
      _recordingIdsConflict(selected, source.candidate) ||
      (selected.durationSeconds != null &&
          source.candidate.durationSeconds != null &&
          (selected.durationSeconds! - source.candidate.durationSeconds!)
                  .abs() >
              3)) {
    return false;
  }
  return _arrangementKeySetupMismatchFields(song, source).isEmpty;
}

/// Recovers a supplied key only from charts corroborated against the actual
/// saved chords. Catalog keys and the first chord are not key evidence. This is
/// also usable for old saved imports, without rewriting their library records.
Map<String, ({String key, List<String> sourceIds})>
_corroboratedArrangementKeyClaims(SongDocument song) {
  if (_hasMetadata(song.metadata['key']) ||
      jsonMap(song.extra['fieldOrigins'])['key'] == 'user' ||
      !song.hasChords) {
    return const {};
  }
  final selected = _selectedOrLibrary(song);
  final lines = parseArrangement(song.body);
  final plain = [
    for (final line in lines)
      ArrangementLine(line.text, const [], directive: line.directive),
  ];
  final claims = <String, ({String key, List<String> sourceIds})>{};
  final chordSourceIds =
      _listOrEmpty(song.extra['chordSourceIds']).whereType<String>().toSet();
  for (final source in song.sources) {
    final contributingChartCreditMatches =
        source.extra['requiresLyricsAgreement'] == true &&
        chordSourceIds.contains(source.id) &&
        _sameArrangedSong(source.candidate, selected);
    if (!source.hasChords ||
        !_keyClaimSourceEligible(
          source,
          selected,
          contributingChartCredit: contributingChartCreditMatches,
        )) {
      continue;
    }
    // A chart the combined arrangement moved into the majority key is judged
    // in that key (see [_keyCorrectedBody] and [declaredKeyAfterShift]).
    final shift = jsonMap(song.extra['chordKeyShifts'])[source.id];
    final shifted = shift is int && shift % 12 != 0;
    final donorCapo = _nonemptyFallback(
      source.metadata['capo'],
      source.candidate.metadata['capo'],
    );
    final declared = _keyIdentity(source.metadata['key']) != null
        ? source.metadata['key'] as String
        : source.candidate.metadata['key'];
    final key = shifted
        ? declaredKeyAfterShift(
            source.body,
            declared is String ? declared : null,
            donorCapo,
            shift,
          )
        : declared;
    final identity = _keyIdentity(key);
    if (identity == null) continue;
    // A label contradicting the chart's own chords is not evidence of a key.
    if (!shifted &&
        !declaredKeyFitsChords(source.body, key as String, donorCapo)) {
      continue;
    }
    if (_arrangementKeySetupMismatchFields(song, source).isNotEmpty) continue;
    // A positively identified source key that agrees with a known harmony
    // reading of the saved chart does not depend on its lyric line layout.
    // Keep chord-anchor corroboration below for sparse or modulating charts.
    if (_keyFitsKnownChords(song, key as String)) {
      final claim = claims.putIfAbsent(
        identity,
        () => (key: key.trim(), sourceIds: []),
      );
      claim.sourceIds.add(source.id);
      continue;
    }
    final keyEvidenceBody = shifted
        ? transposeBody(source.body, shift)
        : source.body;
    // Rejected main-artist chart aliases reach this branch only when that
    // exact chart supplied the saved chord anchors. Reuse the fuzzy line
    // aligner that admitted those anchors; requiring exact phrase alignment
    // here would discard a key whose chord placements were already checked.
    final aligned = contributingChartCreditMatches
        ? _fuzzyLineChords(plain, keyEvidenceBody)
        : _phraseChords(plain, keyEvidenceBody);
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
    final soundingRoots = {
      for (final root in roots)
        ((int.parse(root) + _capoOf(donorCapo)) % 12).toString(),
    };
    if (contradicts ||
        agreements < 3 ||
        roots.length < 3 ||
        matchedLines.length < 2 ||
        !soundingRoots.contains(identity.split(':').first)) {
      continue;
    }
    final claim = claims.putIfAbsent(
      identity,
      () => (key: key.trim(), sourceIds: []),
    );
    claim.sourceIds.add(source.id);
  }
  // Resolve competing verified claims by distinct provider count first,
  // then recording-level match quality, then fit to the saved arrangement.
  // An exact evidence tie stays unresolved; key identity order is not evidence.
  return claims;
}

/// Whether a chord chart may offer its declared key for corroboration
/// against the saved arrangement. Shared by the key recovery itself and by
/// its diagnostics, so the two cannot disagree about which charts took part.
bool _keyClaimSourceEligible(
  SourceResult source,
  SongCandidate selected, {
  required bool contributingChartCredit,
}) =>
    (const {
          MatchKind.sameSong,
          MatchKind.sameRecording,
        }.contains(source.matchKind) ||
        // A shortened chart can be rejected as a full lyric replacement,
        // while still supplying a key corroborated against chosen chords.
        (source.matchKind == MatchKind.rejected &&
            source.matchReason == 'incomplete_or_different_lyrics')) &&
    !source.hasPendingMatchCheck &&
    (_sameSong(source.candidate, selected) ||
        // A positively accepted same-song chart can carry a different
        // provider credit from the selected catalog artist. The match
        // verdict is useful only together with the edition guard below,
        // setup compatibility, and phrase/chord corroboration against the
        // saved arrangement; it never promotes a rejected or pending chart.
        source.matchKind == MatchKind.sameSong ||
        contributingChartCredit) &&
    _version(source.candidate.title) == _version(selected.title);

({String key, List<String> sourceIds})? _bestKeyClaim(
  SongDocument song,
  Map<String, ({String key, List<String> sourceIds})> claims,
) {
  if (claims.isEmpty) return null;
  final ranked = [
    for (final claim in claims.values) _KeyClaimEvidence(song, claim),
  ]..sort(_keyEvidenceCompare);
  if (ranked.length > 1 && _keyEvidenceCompare(ranked[0], ranked[1]) == 0) {
    return null;
  }
  return ranked.first.claim;
}

({String key, List<String> sourceIds})? corroboratedArrangementKey(
  SongDocument song,
) => _bestKeyClaim(song, _corroboratedArrangementKeyClaims(song));

List<String> _arrangementKeySetupMismatchFields(
  SongDocument song,
  SourceResult source,
) {
  final selected = _selectedOrLibrary(song);
  final mismatches = <String>[];
  for (final field in const ['capo', 'tuning', 'timeSignature']) {
    final baseValue = _nonemptyFallback(
      song.metadata[field],
      selected.metadata[field],
    );
    final donorValue = _nonemptyFallback(
      source.metadata[field],
      source.candidate.metadata[field],
    );
    if (field == 'capo' &&
        !_hasMetadata(baseValue) &&
        _hasMetadata(donorValue) &&
        _isExplicitZeroCapo(donorValue)) {
      continue;
    }
    if (field == 'tuning') {
      if (!_compatibleChartTuning(baseValue, donorValue)) {
        mismatches.add(field);
      }
      continue;
    }
    if (_hasMetadata(baseValue) != _hasMetadata(donorValue) ||
        _hasMetadata(baseValue) &&
            '$baseValue'.trim().toLowerCase() !=
                '$donorValue'.trim().toLowerCase()) {
      mismatches.add(field);
    }
  }
  return mismatches;
}

/// Redacted setup diagnostics for evaluating chart key claims.
List<JsonMap> arrangementKeySetupDiagnostics(SongDocument song) {
  if (_hasMetadata(song.metadata['key']) ||
      jsonMap(song.extra['fieldOrigins'])['key'] == 'user' ||
      !song.hasChords) {
    return const [];
  }
  final selected = _selectedOrLibrary(song);
  final chordSourceIds =
      _listOrEmpty(song.extra['chordSourceIds']).whereType<String>().toSet();
  final diagnostics = <JsonMap>[];
  for (final source in song.sources) {
    final declared = _keyIdentity(source.metadata['key']) != null
        ? source.metadata['key']
        : source.candidate.metadata['key'];
    if (!source.hasChords || _keyIdentity(declared) == null) continue;
    final chartCredit =
        source.extra['requiresLyricsAgreement'] == true &&
        chordSourceIds.contains(source.id) &&
        _sameArrangedSong(source.candidate, selected);
    final basicEligible = _keyClaimSourceEligible(
      source,
      selected,
      contributingChartCredit: chartCredit,
    );
    Object? selectedSetup(String field) =>
        _nonemptyFallback(song.metadata[field], selected.metadata[field]);
    Object? candidateSetup(String field) => _nonemptyFallback(
      source.metadata[field],
      source.candidate.metadata[field],
    );
    final diagnostic = <String, Object?>{
      'sourceId': source.id,
      'providerId': source.candidate.providerId,
      'candidateKey': declared,
      'basicEligible': basicEligible,
      'keyFitsOwnChart': null,
      'setupMismatchFields': <String>[],
      'setupValues': {
        for (final field in const ['capo', 'tuning', 'timeSignature'])
          field: {
            'selected': selectedSetup(field),
            'candidate': candidateSetup(field),
          },
      },
      'standardTuningDefaultCompatible': _compatibleChartTuning(
        selectedSetup('tuning'),
        candidateSetup('tuning'),
      ),
    };
    diagnostics.add(diagnostic);
    if (!basicEligible) continue;
    final shift = jsonMap(song.extra['chordKeyShifts'])[source.id];
    final shifted = shift is int && shift % 12 != 0;
    final capo = candidateSetup('capo');
    final key = shifted
        ? declaredKeyAfterShift(source.body, declared as String, capo, shift)
        : declared;
    if (_keyIdentity(key) == null) continue;
    final fits =
        shifted || declaredKeyFitsChords(source.body, key as String, capo);
    diagnostic['keyFitsOwnChart'] = fits;
    if (fits) {
      diagnostic['setupMismatchFields'] = _arrangementKeySetupMismatchFields(
        song,
        source,
      );
    }
  }
  return diagnostics;
}

/// Returns the best supported provider key for this song.
///
/// A key attached to a chord chart must first pass the stricter chord
/// corroboration above. A lyrics-only source can still contribute its
/// explicit key when it is positively matched to the same song and edition;
/// a bare catalog/search candidate or an unverified result cannot. When
/// sources disagree, independent corroboration and recording-level matches
/// determine the winner, with fit to saved chords as the final evidence tie
/// breaker. Section or bridge arrangement differences do not affect home key.
({String key, List<String> sourceIds})? sourcedArrangementKey(
  SongDocument song,
) {
  if (_hasMetadata(song.metadata['key']) ||
      jsonMap(song.extra['fieldOrigins'])['key'] == 'user') {
    return null;
  }
  final ranked = jsonMap(song.extra['evidenceRanking']);
  final rankedSourceIds = _listOrEmpty(ranked['claims'])
      .whereType<Map>()
      .map((claim) => claim['sourceId'])
      .toSet();
  final hasAdditionalEvidence = song.sources.any(
    (source) => !rankedSourceIds.contains(source.id),
  );
  if (ranked['version'] == 1 &&
      ranked['selectionMode'] != 'explicitSource' &&
      !hasAdditionalEvidence) {
    // A new combined document has already compared these source claims.
    // Do not resurrect a weaker key over its ranked inferred choice.
    return null;
  }
  final claims = <String, ({String key, List<String> sourceIds})>{};
  for (final source in song.sources) {
    if (source.hasChords ||
        !const {
          MatchKind.sameSong,
          MatchKind.sameRecording,
        }.contains(source.matchKind) ||
        source.hasPendingMatchCheck ||
        !_compatibleMetadataKeySource(song, source)) {
      continue;
    }
    final key = _keyIdentity(source.metadata['key']) != null
        ? source.metadata['key'] as String
        : source.candidate.metadata['key'];
    final identity = _keyIdentity(key);
    if (identity == null) continue;
    if (song.hasChords &&
        !declaredKeyFitsChords(
          song.body,
          key as String,
          _nonemptyFallback(
            source.metadata['capo'],
            source.candidate.metadata['capo'],
          ),
        )) {
      continue;
    }
    final claim = claims.putIfAbsent(
      identity,
      () => (key: (key as String).trim(), sourceIds: []),
    );
    claim.sourceIds.add(source.id);
  }

  // Chord-bearing metadata remains subject to line-level corroboration.
  for (final entry in _corroboratedArrangementKeyClaims(song).entries) {
    final claim = claims.putIfAbsent(entry.key, () => entry.value);
    for (final id in entry.value.sourceIds) {
      if (!claim.sourceIds.contains(id)) claim.sourceIds.add(id);
    }
  }
  return _bestKeyClaim(song, claims);
}

Object? _setupValue(SourceResult source, SongCandidate selected, String key) {
  for (final value in [
    source.metadata[key],
    source.candidate.metadata[key],
    selected.metadata[key],
  ]) {
    if (_hasMetadata(value)) return value;
  }
  return null;
}

bool _compatibleArrangementSetup(
  SourceResult base,
  SourceResult donor,
  SongCandidate selected, {
  bool allowCapoDifference = false,
}) {
  if (!explicitEditionsCompatible(
    selected,
    donor.candidate,
    metadata: donor.metadata,
    extra: donor.extra,
  )) {
    return false;
  }
  for (final key in const ['key', 'capo', 'tuning', 'timeSignature']) {
    if (key == 'capo' && allowCapoDifference) continue;
    final baseValue = _setupValue(base, selected, key);
    final donorValue = _setupValue(donor, selected, key);
    if (baseValue == null || donorValue == null) continue;
    final normalizedBase = baseValue is String
        ? baseValue.trim().toLowerCase()
        : _valueKey(baseValue);
    final normalizedDonor = donorValue is String
        ? donorValue.trim().toLowerCase()
        : _valueKey(donorValue);
    if (normalizedBase != normalizedDonor) return false;
  }
  return true;
}

String _bodyHash(String body) => sha256.convert(utf8.encode(body)).toString();

String? _agreedKeyEstimate(List<SourceResult> sources) {
  final keys = {
    for (final source in sources)
      if (source.extra['keyEstimate'] case final String key) key,
  };
  return keys.length == 1 ? keys.single : null;
}

/// A key for [body] (in chord shapes) when its chords alone leave a relative
/// major and minor open and the recording key measured for its chord
/// [sources] names one of them.
String? _recordingHintedEstimate(
  String body,
  List<SourceResult> sources,
  Object? capo,
) {
  if (estimateChordKey(body) != null) return null;
  final measured = {
    for (final source in sources)
      if (jsonMap(source.extra['keyRecording'])['key'] case final String key)
        key,
  };
  if (measured.length != 1) return null;
  return estimateChordKey(
    body,
    hint: transposeChord(measured.single, (12 - _capoOf(capo)) % 12),
  )?.key;
}

/// The key of the one chart that gave all of [body]'s chords, estimated from
/// the whole chart, when [body] holds too few chords for any estimate (fewer
/// than six, or fewer than three roots). A body with enough chords whose key
/// the estimator left open stays open.
String? _singleChartEstimate(String body, List<SourceResult> sources) {
  if (sources.length != 1) return null;
  final chords = [
    for (final line in parseArrangement(body))
      for (final anchor in line.chords) anchor.chord,
  ];
  final roots = {
    for (final chord in chords)
      if (RegExp(r'^[A-G][#b♯♭]?').firstMatch(chord) case final match?)
        match[0],
  };
  if (chords.length >= 6 && roots.length >= 3) return null;
  return estimateChordKey(_keyCorrectedBody(sources.single))?.key;
}

/// The key discovery estimated from the majority of a song's chord charts,
/// while the song still holds the exact chart it was estimated for. Like
/// [estimateChordKey], it is display-only.
String? checkedChordKeyEstimate(SongDocument song) {
  final estimate = jsonMap(song.extra['chordKeyEstimate']);
  final key = estimate['key'];
  return key is String && estimate['bodyHash'] == _bodyHash(song.body)
      ? key
      : null;
}

/// The winning inferred home key from the persisted evidence comparison.
/// It remains an estimate, bound to the exact saved chart, not a provider fact.
String? rankedChordKeyEstimate(SongDocument song) =>
    jsonMap(song.extra['chordKeyEstimate'])['ranked'] == true
    ? checkedChordKeyEstimate(song)
    : null;

bool rankedKeyNeedsReview(SongDocument song) =>
    jsonMap(
      jsonMap(
        jsonMap(song.extra['evidenceRanking'])['appliedFields'],
      )['metadata.key'],
    )['provisional'] ==
    true;

/// 2 for a chart discovery found in the majority key, 1 when no check was
/// needed or possible or the chart was moved into that key, 0 for a chart
/// transposed from it by an unknown amount.
int _keyConsensusRank(SourceResult source) =>
    switch (source.extra['keyConsensus']) {
      true => 2,
      false => source.extra['keyShift'] is int ? 1 : 0,
      _ => 1,
    };

({
  String body,
  List<String> sourceIds,
  Set<String> movedIds,
  bool contextApplied,
})
_overlayChords(
  String body,
  List<SourceResult> sources,
  SongCandidate selected,
  SourceResult base, {
  Map<String, int> evidenceScores = const {},
  ({String body, Map<SourceResult, Map<int, List<ChordAnchor>>> bySource})?
  alignedLineChords,
}) {
  final lines = parseArrangement(body);
  // Alignments the caller already computed against these exact lyric lines.
  final knownLineChords = alignedLineChords != null &&
          alignedLineChords.body == body
      ? alignedLineChords.bySource
      : const <SourceResult, Map<int, List<ChordAnchor>>>{};
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
  final contextSources = <String>{};
  for (final source in sources) {
    if (!source.hasChords ||
        !_compatibleArrangementSetup(
          base,
          source,
          selected,
          allowCapoDifference: true,
        )) {
      continue;
    }
    final donorBody = _keyCorrectedBody(source);
    // Lines whose wording differs slightly between sources (an extra "let it
    // be", a contraction) are aligned word by word where exact phrases fail.
    final contexts = _exactContextChords(plain, donorBody);
    final fuzzy =
        knownLineChords[source] ?? _fuzzyLineChords(plain, donorBody);
    final phrases = _phraseChords(plain, donorBody);
    final priorChords = {
      ...fuzzy,
      for (final entry in phrases.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value,
    };
    final chords = {...fuzzy, ...contexts};
    for (final entry in phrases.entries) {
      if (entry.value.isEmpty) continue;
      final fuzzyConflicts = entry.value.any(
        (anchor) => (fuzzy[entry.key] ?? const <ChordAnchor>[]).any(
          (existing) =>
              existing.offset == anchor.offset &&
              existing.chord != anchor.chord,
        ),
      );
      if (fuzzyConflicts) {
        // Two matchers selected different chords at the same lyric onset.
        // Without a source-level confidence ranking, leave this line unplaced.
        chords.remove(entry.key);
        continue;
      }
      final context = contexts[entry.key];
      // Keep every exact phrase placement. A complete exact context may add
      // anchors only when it preserves all of those positions and symbols.
      final agrees =
          context != null &&
          entry.value.every(
            (anchor) => context.any(
              (other) =>
                  other.offset == anchor.offset && other.chord == anchor.chord,
            ),
          );
      if (!agrees) chords[entry.key] = entry.value;
    }
    // Some page layouts split words around chord anchors. Recover placements
    // only where the complete donor line has the same ordered letters, keeping
    // the selected lyrics and any placement already established above.
    final compact = compactLineChords(plain, donorBody);
    for (final entry in compact.entries) {
      if (chords[entry.key]?.isNotEmpty ?? false) continue;
      chords[entry.key] = entry.value;
      contextSources.add(source.id);
    }
    if (contexts.entries.any(
      (entry) =>
          identical(chords[entry.key], entry.value) &&
          entry.value.any(
            (anchor) => !(priorChords[entry.key] ?? const <ChordAnchor>[]).any(
              (prior) =>
                  prior.offset == anchor.offset && prior.chord == anchor.chord,
            ),
          ),
    )) {
      contextSources.add(source.id);
    }
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
    final evidence = (evidenceScores[b.source.id] ?? 0).compareTo(
      evidenceScores[a.source.id] ?? 0,
    );
    if (evidence != 0) return evidence;
    // Discovery double checks disagreeing charts against more charts of the
    // song; a chart transposed from the key most charts share (for example a
    // capo chart in G of a song recorded in E) comes last.
    final key = _keyConsensusRank(
      b.source,
    ).compareTo(_keyConsensusRank(a.source));
    if (key != 0) return key;
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
  // Donors whose chords were moved into the primary chart's shapes.
  final movedIds = <String>{};
  for (var candidate in candidates) {
    if (primary != null) {
      // A chart played with another capo sounds the same once its chords
      // move by the capo difference: C shapes at capo 3 are Eb shapes at no
      // capo. Charts still transposed from the majority key by an unknown
      // amount are not moved.
      final move =
          (_capoOf(_setupValue(candidate.source, selected, 'capo')) -
              _capoOf(_setupValue(primary, selected, 'capo'))) %
          12;
      if (move != 0) {
        final primaryKey = _setupValue(primary, selected, 'key');
        final donorKey = _setupValue(candidate.source, selected, 'key');
        final primaryCapo = _setupValue(primary, selected, 'capo');
        final donorCapo = _setupValue(candidate.source, selected, 'capo');
        // A capo move needs an affirmative discovery check. When both capo
        // values are explicit, also require matching sounding-key claims that
        // fit each chart's shapes. Older charts with an unspecified primary
        // capo retain the established keyConsensus-based conversion path.
        final explicitCapos = primaryCapo != null && donorCapo != null;
        if (candidate.source.extra['keyConsensus'] != true ||
            (explicitCapos &&
                (primaryKey is! String ||
                    donorKey is! String ||
                    _keyIdentity(primaryKey) != _keyIdentity(donorKey) ||
                    !declaredKeyFitsChords(
                      _keyCorrectedBody(primary),
                      primaryKey,
                      primaryCapo,
                    ) ||
                    !declaredKeyFitsChords(
                      _keyCorrectedBody(candidate.source),
                      donorKey,
                      donorCapo,
                    )))) {
          continue;
        }
        final flats = _chartSpelling(_keyCorrectedBody(primary));
        candidate = (
          source: candidate.source,
          chords: {
            for (final entry in candidate.chords.entries)
              entry.key: [
                for (final anchor in entry.value)
                  ChordAnchor(
                    anchor.offset,
                    transposeChord(anchor.chord, move, flats: flats),
                  ),
              ],
          },
          coverage: candidate.coverage,
          confidence: candidate.confidence,
        );
        movedIds.add(candidate.source.id);
      }
      if (!_compatibleArrangementSetup(
        primary,
        candidate.source,
        selected,
        allowCapoDifference: true,
      )) {
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
      // Discovery's key check placing both charts in the key most charts
      // share also shows they can be read together.
      final checkedSameKey =
          primary.extra.containsKey('keyConsensus') &&
          candidate.source.extra.containsKey('keyConsensus') &&
          _keyConsensusRank(primary) > 0 &&
          _keyConsensusRank(candidate.source) > 0;
      // Sources carrying this flag reached _overlayChords only after the
      // selected-recording lyric-context gate accepted them in combineSources.
      final contextualLyricsChecked =
          candidate.source.extra['requiresRecordingLyricsAgreement'] == true;
      if (contradicts ||
          (!agrees &&
              !explicitSetup &&
              !checkedSameKey &&
              !contextualLyricsChecked)) {
        continue;
      }
      // A same-song chart without a compatible explicit arrangement setup or
      // affirmative key consensus may confirm overlapping anchors, but those
      // agreements cannot validate its otherwise unmatched changes. Keep only
      // exact agreements in that case; repeated-line alignment must not let
      // one matching chorus chord authorize new chords elsewhere in the song.
      if (candidate.confidence < 2 &&
          !explicitSetup &&
          !checkedSameKey &&
          !contextualLyricsChecked) {
        candidate = (
          source: candidate.source,
          chords: {
            for (final entry in candidate.chords.entries)
              if (chartChords[entry.key] case final previous?)
                entry.key: [
                  for (final anchor in entry.value)
                    if (previous.any(
                      (known) =>
                          known.offset == anchor.offset &&
                          known.chord == anchor.chord,
                    ))
                      anchor,
                ],
          },
          coverage: candidate.coverage,
          confidence: candidate.confidence,
        );
      }
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
  if (contributorIds.isEmpty) {
    return (
      body: body,
      sourceIds: const [],
      movedIds: const <String>{},
      contextApplied: false,
    );
  }
  // Charts often write a repeated chorus once, and repeats vary in backing
  // vocals ("(stand by me)"). A lyric line whose words, outside brackets,
  // equal a line that received chords takes those chords at the same word
  // positions, unless it already has chords.
  // A line whose chorded copies disagree on harmony has no single chords
  // to lend.
  final chordsByText = <String, int>{};
  final harmonies = <String, Set<String>>{};
  for (var i = 0; i < lines.length; i++) {
    final chords = chartChords[i];
    final text = _repeatKey(lines[i].text);
    if (chords != null && chords.isNotEmpty && text.isNotEmpty) {
      chordsByText.putIfAbsent(text, () => i);
      harmonies
          .putIfAbsent(text, () => {})
          .add(chords.map((chord) => chord.chord).join(' '));
    }
  }
  chordsByText.removeWhere((text, _) => harmonies[text]!.length > 1);
  for (var i = 0; i < lines.length; i++) {
    // An aligned line may carry an empty chord list; that is not a choice.
    if ((chartChords[i]?.isNotEmpty ?? false) || lines[i].directive) continue;
    final from = chordsByText[_repeatKey(lines[i].text)];
    if (from == null) continue;
    final moved = _retargetChords(
      lines[from].text,
      lines[i].text,
      chartChords[from]!,
    );
    if (moved != null) chartChords[i] = moved;
  }

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
    movedIds: applied ? movedIds : const <String>{},
    contextApplied: applied && contributorIds.any(contextSources.contains),
  );
}

/// Builds the selected chart and its metadata. A compact explicit Save
/// expects provider evidence to be staged separately in the library.
SongDocument combineSources(
  SongCandidate selected,
  List<SourceResult> results, {
  String? preferredSourceId,
  bool allowRejectedPreferredSource = false,
  bool compactExplicitSave = false,
  List<HistoricalCacheUse> historicalCacheUses = const [],
}) =>
    // The search row's displayed facts fill only what no source stated, and
    // never enter the selection that is ranked and stored.
    _combineSources(
      withoutRowFacts(selected),
      results,
      rowAlbum: selected.metadata[rowAlbumKey],
      rowDuration: selected.metadata[rowDurationKey],
      preferredSourceId: preferredSourceId,
      allowRejectedPreferredSource: allowRejectedPreferredSource,
      compactExplicitSave: compactExplicitSave,
      historicalCacheUses: historicalCacheUses,
    );

SongDocument _combineSources(
  SongCandidate selected,
  List<SourceResult> results, {
  required Object? rowAlbum,
  required Object? rowDuration,
  String? preferredSourceId,
  bool allowRejectedPreferredSource = false,
  bool compactExplicitSave = false,
  List<HistoricalCacheUse> historicalCacheUses = const [],
}) {
  final inputSources = List<SourceResult>.of(results);
  // Every identity and key check below is a pure function of this selection
  // and one source or chart body, so one cache serves the whole combination.
  final scoreCache = _MergeScoreCache(selected);
  bool sameRecordingAsSelected(SourceResult source) =>
      scoreCache.sameRecording(source);
  results = _retainedSourceEvidence(selected, results);
  results = [
    ...results,
    ..._recordingArrangementViews(selected, results, scoreCache),
  ];
  bool materialSource(SourceResult source) =>
      source.extra['hasArrangementViews'] != true ||
      source.id == preferredSourceId;
  // Contextual composer/work credits can authorize a chart only through a
  // resolved full lyric reference belonging to this selected recording.
  bool enoughLyricEvidence(SourceResult source) =>
      _norm(
            plainLyrics(source.body),
          ).split(' ').where((word) => word.isNotEmpty).toSet().length >=
          12 ||
      source.matchKind == MatchKind.sameRecording &&
          sameRecordingAsSelected(source) &&
          isShortRecordingLyricBody(source.body);
  final arrangementContexts = results
      .where(
        (source) =>
            !source.hasChords &&
            source.matchKind != MatchKind.rejected &&
            source.matchKind != MatchKind.unverified &&
            !source.hasPendingMatchCheck &&
            source.extra['requiresLyricsAgreement'] != true &&
            source.extra['requiresRecordingLyricsAgreement'] != true &&
            sameRecordingAsSelected(source) &&
            enoughLyricEvidence(source),
      )
      .toList();
  bool metadataContextMatches(SourceResult source) {
    if (source.candidate.providerId != 'musicbrainz' ||
        source.extra['metadataOnly'] != true ||
        source.body.trim().isNotEmpty ||
        source.hasChords ||
        source.hasPendingMatchCheck ||
        !const {
          MatchKind.sameSong,
          MatchKind.sameRecording,
        }.contains(source.matchKind)) {
      return false;
    }
    bool knownFactsAgree(SongCandidate reference) {
      if (_recordingIdsConflict(reference, source.candidate)) return false;
      final a = reference.durationSeconds, b = source.candidate.durationSeconds;
      return a == null ||
          b == null ||
          (a - b).abs() <= math.min(15, math.max(8, a * 0.02));
    }

    if (!knownFactsAgree(selected)) return false;
    return arrangementContexts.any(
      (reference) =>
          reference.candidate.identity == selected.identity &&
          knownFactsAgree(reference.candidate) &&
          _sameSong(reference.candidate, source.candidate) &&
          musicBrainzArtistCreditEvidence(
                reference.candidate,
                source.candidate,
                _identityNorm,
              ) !=
              null,
    );
  }

  bool contextMatches(SourceResult chart) => arrangementContexts.any(
    (reference) =>
        contextualArrangementCandidate(
          reference.candidate,
          chart.candidate,
          allowAlternatePerformers:
              chart.extra['alternatePerformerChart'] == true,
        ) &&
        (chart.extra['alternatePerformerChart'] != true ||
            contextualChartLyricsMatch(
              chart.body,
              reference.body,
              allowPartial: true,
            )) &&
        explicitEditionsCompatible(
          reference.candidate,
          chart.candidate,
          metadata: chart.metadata,
          extra: chart.extra,
        ),
  );
  bool historicalMatches(SourceResult source) =>
      explicitHistoricalWorkMatches(selected, source) ||
      historicalCacheUses.any((use) => use.allows(selected, source));
  // A canonical arrangement selection with no artist credit authorizes only
  // its own resolved source. It never matches another provider by title alone.
  bool selectedArrangementMatches(SourceResult source) =>
      source.candidate.identity == selected.identity &&
      source.candidate.metadata['identityScope'] == 'arrangement' &&
      _identityNorm(source.candidate.title).isNotEmpty &&
      _identityNorm(source.candidate.title) == _identityNorm(selected.title) &&
      _identityNorm(source.candidate.artist) ==
          _identityNorm(selected.artist) &&
      source.hasChords &&
      !source.hasPendingMatchCheck &&
      source.extra['requiresLyricsAgreement'] != true &&
      source.extra['requiresRecordingLyricsAgreement'] != true &&
      !_recordingIdsConflict(selected, source.candidate) &&
      const {
        MatchKind.sameSong,
        MatchKind.sameRecording,
      }.contains(source.matchKind) &&
      explicitEditionsCompatible(
        selected,
        source.candidate,
        metadata: source.metadata,
        extra: source.extra,
      );
  final lyricReferences = results
      .where(
        (source) =>
            materialSource(source) &&
            !source.hasChords &&
            const {
              MatchKind.sameSong,
              MatchKind.sameRecording,
            }.contains(source.matchKind) &&
            source.extra['requiresLyricsAgreement'] != true &&
            source.extra['requiresRecordingLyricsAgreement'] != true &&
            (_sameSong(selected, source.candidate) ||
                historicalMatches(source)) &&
            enoughLyricEvidence(source),
      )
      .toList();
  // A longer same-song performance must not bypass the selected short
  // recording's stricter ordered-sequence proof.
  final shortRecordingReferences = lyricReferences
      .where(
        (reference) =>
            reference.matchKind == MatchKind.sameRecording &&
            sameRecordingAsSelected(reference) &&
            isShortRecordingLyricBody(reference.body),
      )
      .toList();
  final donorReferences = shortRecordingReferences.isEmpty
      ? lyricReferences
      : shortRecordingReferences;
  final matching = results.where((s) {
    final wikiSource = s.candidate.providerId == 'wikisource';
    final searchMetadataMatches =
        s.extra['searchEvidenceOnly'] == true &&
        s.extra['searchArrangementMatch'] == true;
    final allowedRejectedAlternative =
        allowRejectedPreferredSource &&
        s.id == preferredSourceId &&
        !wikiSource;
    // A coverage rejection describes a weaker partial arrangement, not a
    // different song. Retain and rank its dimensions against stronger data.
    final coverageOnlyAlternative =
        (s.matchKind == MatchKind.rejected &&
        s.matchReason == 'incomplete_or_different_lyrics' &&
        (_sameSong(selected, s.candidate) ||
            s.extra['requiresLyricsAgreement'] == true &&
                _sameArrangedSong(selected, s.candidate)) &&
        explicitEditionsCompatible(
          selected,
          s.candidate,
          metadata: s.metadata,
          extra: s.extra,
        ));

    if (!allowedRejectedAlternative &&
        s.id != preferredSourceId &&
        s.hasChords &&
        shortRecordingReferences.isNotEmpty &&
        (!(coverageOnlyAlternative ||
                const {
                  MatchKind.sameSong,
                  MatchKind.sameRecording,
                }.contains(s.matchKind)) ||
            !shortRecordingReferences.any(
              (reference) =>
                  shortRecordingLyricAgreement(s.body, reference.body),
            ))) {
      return false;
    }
    final requiresRecordingContext =
        s.extra['requiresRecordingLyricsAgreement'] == true;
    if (!allowedRejectedAlternative &&
        requiresRecordingContext &&
        (!(coverageOnlyAlternative ||
                const {
                  MatchKind.sameSong,
                  MatchKind.sameRecording,
                }.contains(s.matchKind)) ||
            !s.hasChords ||
            !contextMatches(s))) {
      return false;
    }
    if (!allowedRejectedAlternative &&
        s.extra['requiresLyricsAgreement'] == true &&
        (!(coverageOnlyAlternative ||
                const {
                  MatchKind.sameSong,
                  MatchKind.sameRecording,
                }.contains(s.matchKind)) ||
            !donorReferences.any(
              (reference) =>
                  !isShortRecordingLyricBody(reference.body) ||
                  shortRecordingLyricAgreement(s.body, reference.body),
            ))) {
      return false;
    }
    final editionAllowed =
        explicitEditionsCompatible(
          selected,
          s.candidate,
          metadata: s.metadata,
          extra: s.extra,
        ) ||
        s.id == preferredSourceId;
    final identityMatches = wikiSource
        ? historicalMatches(s)
        : ((selectedArrangementMatches(s) ||
                      searchMetadataMatches ||
                      _sameSong(s.candidate, selected) ||
                      metadataContextMatches(s) ||
                      (s.hasChords &&
                          s.extra['requiresLyricsAgreement'] == true &&
                          (_sameArrangedSong(s.candidate, selected) ||
                              requiresRecordingContext &&
                                  contextMatches(s)))) &&
                  editionAllowed) ||
              allowedRejectedAlternative;
    return identityMatches &&
        (s.matchKind != MatchKind.rejected ||
            coverageOnlyAlternative ||
            wikiSource && historicalMatches(s) ||
            allowedRejectedAlternative);
  }).toList();
  bool? hasLyricBase;
  bool matchingHasLyrics() => hasLyricBase ??= matching.any(
    (s) => materialSource(s) && plainLyrics(s.body).trim().isNotEmpty,
  );
  final accepted = matching
      .where(
        (s) =>
            materialSource(s) &&
            (plainLyrics(s.body).trim().isNotEmpty ||
                (selectedArrangementMatches(s) &&
                    (s.id == preferredSourceId ||
                        preferredSourceId == null && !matchingHasLyrics()))),
      )
      .toList();
  if (accepted.isEmpty) {
    throw const FormatException('No matching lyrics are available to save.');
  }
  // Use resolved selected-recording text as the chart completeness reference
  // when it is available; another performance's longer lyric page must not
  // make a compatible chart appear incomplete.
  final resolvedLyricAnchors = preferredSourceId == null
      ? accepted
            .where((source) => sameRecordingAsSelected(source))
            .toList()
      : <SourceResult>[];
  final referencePool = resolvedLyricAnchors.isEmpty
      ? accepted
      : resolvedLyricAnchors;
  final references =
      referencePool
          .where((s) => !s.hasChords && s.matchKind != MatchKind.unverified)
          .toList()
        ..sort((a, b) {
          final length = scoreCache
              .plainLyricLength(b.body)
              .compareTo(scoreCache.plainLyricLength(a.body));
          return length != 0 ? length : a.id.compareTo(b.id);
        });
  final eligible = accepted
      .where(
        (source) =>
            preferredSourceId == null ||
            (allowRejectedPreferredSource && source.id == preferredSourceId) ||
            (source.id == preferredSourceId &&
                selectedArrangementMatches(source)) ||
            !source.hasChords ||
            references.isEmpty ||
            _completeChart(source.body, references.first.body),
      )
      .toList();
  if (eligible.isEmpty) {
    throw const FormatException('No complete matching lyrics are available.');
  }
  // Once a source has resolved lyrics against the selected recording, a
  // longer same-song result from another performance must not replace them.
  // Keep the normal fallback when no recording-compatible lyrics are present;
  // a user-selected source also remains authoritative below.
  final omitExplicitDiagnostics =
      compactExplicitSave && preferredSourceId != null;
  final evidencePlan = omitExplicitDiagnostics
      ? null
      : _rankSourceCombination(
          selected,
          results,
          scores: scoreCache,
          lyricSourceIds: eligible.map((s) => s.id).toSet(),
          chartSourceIds: matching
              .where((s) => s.hasChords && materialSource(s))
              .map((s) => s.id)
              .toSet(),
          factSourceIds: matching.map((s) => s.id).toSet(),
          metadataContextMatches: metadataContextMatches,
          preferredSourceId: preferredSourceId,
        );
  final chordScores = <String, int>{};
  final SourceResult best;
  SourceResult? chartWinner;
  if (preferredSourceId == null) {
    final plan = evidencePlan!;
    final lyricScores = <String, int>{};
    for (final item in plan.claims) {
      final scores = switch (item.claim.field) {
        'lyrics' => lyricScores,
        'chords' => chordScores,
        _ => null,
      };
      scores?.update(
        item.claim.sourceId,
        (n) => math.max(n, item.score),
        ifAbsent: () => item.score,
      );
    }
    final selectedLyrics = plan.chosenByField['lyrics'];
    final rankedEligible = [...eligible]
      ..sort((a, b) {
        final chosen = (b.id == selectedLyrics?.sourceId ? 1 : 0).compareTo(
          a.id == selectedLyrics?.sourceId ? 1 : 0,
        );
        if (chosen != 0) return chosen;
        final score = (lyricScores[b.id] ?? 0).compareTo(
          lyricScores[a.id] ?? 0,
        );
        return score != 0 ? score : a.id.compareTo(b.id);
      });
    best = rankedEligible.first;
    final selectedChart = plan.chosenByField['chords'];
    chartWinner = matching
        .where((s) => s.id == selectedChart?.sourceId && s.hasChords)
        .firstOrNull;
    if (chartWinner != null) {
      chordScores[chartWinner.id] = (chordScores[chartWinner.id] ?? 0) + 10000;
    }
  } else {
    final preferred = eligible
        .where((s) => s.id == preferredSourceId)
        .firstOrNull;
    if (preferred == null) {
      throw const FormatException(
        'The selected source does not contain a complete matching arrangement.',
      );
    }
    best = preferred;
  }
  final keepBaseChords =
      preferredSourceId != null ||
      best.hasChords && (chartWinner == null || chartWinner.id == best.id);
  final initialBody = preferredSourceId != null
      ? best.body
      : keepBaseChords
      ? _keyCorrectedBody(best)
      : _withoutChordAnchors(_keyCorrectedBody(best));
  final overlayBase = chartWinner == null || keepBaseChords
      ? best
      : SourceResult(
          candidate: chartWinner.candidate,
          body: initialBody,
          arrangementId: chartWinner.arrangementId,
          metadata: chartWinner.metadata,
          matchKind: chartWinner.matchKind,
          matchReason: chartWinner.matchReason,
          extra: chartWinner.extra,
        );
  final chordOverlaySources = <SourceResult>[
    if (preferredSourceId == null)
      ...matching.where(
        (source) =>
            source.hasChords &&
            materialSource(source) &&
            (!keepBaseChords || source.id != best.id),
      ),
  ];
  // A chart rejected only for incomplete/different lyric coverage can still
  // supply chords when multiple chart lines align clearly with the selected
  // lyrics. It never becomes a lyric, section, or general-metadata donor.
  // Limit this path to a lyric-only selected base with no accepted chord
  // chart, so it cannot compete with a qualified arrangement.
  final fallbackLineChords =
      Map<SourceResult, Map<int, List<ChordAnchor>>>.identity();
  if (preferredSourceId == null &&
      !best.hasChords &&
      !accepted.any((source) => source.hasChords)) {
    final plain = [
      for (final line in parseArrangement(best.body))
        ArrangementLine(line.text, const [], directive: line.directive),
    ];
    for (final source in results) {
      if (!materialSource(source)) continue;
      final chartCreditMatches =
          source.extra['requiresLyricsAgreement'] == true &&
          _sameArrangedSong(source.candidate, selected);
      if (source.matchKind != MatchKind.rejected ||
          source.matchReason != 'incomplete_or_different_lyrics' ||
          !source.hasChords ||
          source.hasPendingMatchCheck ||
          source.extra['requiresRecordingLyricsAgreement'] == true ||
          !(_sameSong(source.candidate, selected) || chartCreditMatches) ||
          _version(source.candidate.title) != _version(selected.title) ||
          !explicitEditionsCompatible(
            selected,
            source.candidate,
            metadata: source.metadata,
            extra: source.extra,
          )) {
        continue;
      }
      if (shortRecordingReferences.isNotEmpty &&
          !shortRecordingReferences.any(
            (reference) =>
                shortRecordingLyricAgreement(source.body, reference.body),
          )) {
        continue;
      }
      final selectedCapo = _setupValue(best, selected, 'capo');
      final donorCapo =
          source.metadata['capo'] ?? source.candidate.metadata['capo'];
      final donorKey =
          source.metadata['key'] ?? source.candidate.metadata['key'];
      final selectedTuning = _setupValue(best, selected, 'tuning');
      final donorTuning =
          source.metadata['tuning'] ?? source.candidate.metadata['tuning'];
      // This chord-only fallback does not have a primary chart to establish
      // a transposition target. Keep the donor in the selected shape/capo
      // system and reject a known key-consensus failure instead of silently
      // importing capoed or shifted shapes as if they were untransposed.
      if (_capoOf(selectedCapo) != _capoOf(donorCapo) ||
          !_compatibleChartTuning(selectedTuning, donorTuning) ||
          source.extra['keyConsensus'] == false ||
          (donorKey is String &&
              donorKey.trim().isNotEmpty &&
              !declaredKeyFitsChords(source.body, donorKey, donorCapo))) {
        continue;
      }
      final anchored = _fuzzyLineChords(plain, _keyCorrectedBody(source));
      // Phrase anchors can satisfy ordinary lyrics-agreement requirements
      // for this chord-only overlay. Recording-specific agreement remains a
      // separate identity gate above and is never waived by text overlap.
      final matchedLines = anchored.entries
          .where((entry) => entry.value.isNotEmpty)
          .length;
      final matchedAnchors = anchored.values.fold<int>(
        0,
        (total, chords) => total + chords.length,
      );
      if (matchedLines >= 2 && matchedAnchors >= 3) {
        chordOverlaySources.add(source);
        fallbackLineChords[source] = anchored;
      }
    }
  }
  final merged = preferredSourceId == null
      ? _overlayChords(
          initialBody,
          chordOverlaySources,
          selected,
          overlayBase,
          evidenceScores: chordScores,
          // The fallback aligned each donor's corrected chart with the lines
          // of [best.body]; they are reusable only for that same text.
          alignedLineChords: (body: best.body, bySource: fallbackLineChords),
        )
      : (
          body: best.body,
          sourceIds: const <String>[],
          movedIds: const <String>{},
          contextApplied: false,
        );
  final sectionMerged = preferredSourceId == null
      ? _overlaySections(
          merged.body,
          accepted.where((source) => source.id != best.id).toList(),
          best,
        )
      : (body: merged.body, sourceIds: const <String>[]);
  const arrangementFields = _rankedArrangementFields;
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
    if (keepBaseChords && best.hasChords) best.id,
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
  // A search-evidence entry can share its ID with the fetched source; the
  // fetched one carries the chart and its key shift.
  final sourcesById = <String, SourceResult>{};
  for (final source in matching) {
    final known = sourcesById[source.id];
    if (known == null ||
        known.extra['searchEvidenceOnly'] == true &&
            source.extra['searchEvidenceOnly'] != true) {
      sourcesById[source.id] = source;
    }
  }
  final arrangementSourceIds = <String>{best.id};
  for (final sourceId in chordSourceIds) {
    final source = sourcesById[sourceId];
    // A chart whose chords were moved into the main chart's shapes no longer
    // has its own key or capo.
    if (source != null &&
        !merged.movedIds.contains(sourceId) &&
        (sameRecordingAsSelected(source) ||
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
    'releaseDateDisplay',
    'recordingLocation',
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
  // Only an explicit source choice folds source facts in here; automatic
  // combination applies ranked metadata below instead.
  final explicitSources = preferredSourceId == null
      ? const <SourceResult>[]
      : [
          best,
          ...matching.where((s) => s.id != best.id).toList()
            ..sort((a, b) => a.id.compareTo(b.id)),
        ];
  // Catalogs list one release with slightly different durations, and other
  // masters or edits under the same album name. Lend a display duration only
  // from the one group of agreeing durations (within three seconds) that more
  // album-matching sources support than any other.
  final displayAlbum =
      metadata['album'] ??
      explicitSources
          .where((source) => sameRecordingAsSelected(source))
          .map((source) => source.candidate.album ?? source.metadata['album'])
          .whereType<String>()
          .firstOrNull;
  final displayDurations = _majorityDurationRange([
    if (displayAlbum is String && selected.recordingIds.isEmpty)
      for (final source in explicitSources.skip(1))
        if (_lendsAlbumDisplay(selected, source, displayAlbum))
          ?_sourceDuration(source),
  ]);
  for (final source in explicitSources) {
    final candidateDuration =
        _validDuration(source.candidate.durationSeconds) ??
        _validDuration(source.candidate.metadata['durationSeconds']) ??
        _validDuration(source.candidate.metadata['duration']);
    final facts = <String, dynamic>{
      ...source.candidate.metadata,
      if (source.candidate.album != null) 'album': source.candidate.album,
      'durationSeconds': candidateDuration,
    };
    for (final entry in source.metadata.entries) {
      if (!_hasMetadata(entry.value)) continue;
      facts[entry.key] = _mergeMetadataFact(
        facts[entry.key],
        entry.value,
        mergeLists: !arrangementFields.contains(entry.key),
      );
    }
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
    final sameRecording = sameRecordingAsSelected(source);
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
    final creditContext = !sameRecording && metadataContextMatches(source);
    if (scoped == 'recording' && !sameRecording && !creditContext) continue;
    if (creditContext) {
      // Credit agreement can map performer names to artist IDs. It does not
      // authorize any recording-specific fact, including ISRCs or keys.
      facts.removeWhere((key, _) => key != 'artistCredits');
    }
    final matchingAlbumDisplay =
        selected.recordingIds.isEmpty &&
        knownAlbum is String &&
        knownAlbum.trim().isNotEmpty &&
        foundAlbum is String &&
        _lendsAlbumDisplay(selected, source, knownAlbum) &&
        sourceDuration != null &&
        displayDurations != null &&
        sourceDuration >= displayDurations.$1 &&
        sourceDuration <= displayDurations.$2 &&
        (knownDuration == null || (knownDuration - sourceDuration).abs() <= 3);
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
        if (_valueKey(metadata[entry.key]) == _valueKey(entry.value)) {
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
              if (seen.add(_valueKey(value))) value,
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
            } else if (_valueKey(current[mapEntry.key]) !=
                _valueKey(mapEntry.value)) {
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
        // Catalogs measure one release a little differently (243.0 and
        // 243.36 seconds): within three seconds the difference is kept as a
        // conflict but does not discard the duration.
        final current = metadata[entry.key];
        final closeDurations =
            entry.key == 'durationSeconds' &&
            current is num &&
            entry.value is num &&
            (current - (entry.value as num)).abs() <= 3;
        // Keep an explicit selected-candidate fact, but don't let iteration
        // order silently choose between conflicting provider claims.
        if (priorOrigin != selected.identity &&
            !isArrangement &&
            !closeDurations) {
          metadata.remove(entry.key);
          origins.remove(entry.key);
          fieldContributors.remove(entry.key);
        }
      }
    }
  }
  final tracks = <String, TimingTrack>{};
  late final arrangementLyricHash = lyricOrderHash(best.body);
  for (final source in results) {
    late final sameRecording = sameRecordingAsSelected(source);
    for (final track in source.timingTracks) {
      if (tracks.containsKey(track.id)) continue;
      final sourceLyricHash = lyricOrderHash(track.sourceLyrics);
      final timingSelected = _demonstrationTimingSelected(
        selected,
        source,
        track,
      );
      var status = track.status;
      if (status != TimingStatus.invalid &&
          status != TimingStatus.unsupported) {
        status = source.matchKind == MatchKind.rejected
            ? TimingStatus.incompatible
            : !timingSelected
            ? TimingStatus.unverified
            : !sameRecording
            ? TimingStatus.unverified
            : sourceLyricHash != arrangementLyricHash
            ? TimingStatus.incompatible
            : TimingStatus.usable;
      }
      tracks[track.id] = track.copyWith(
        status: status,
        lyricHash: sourceLyricHash,
        extra: {
          ...track.extra,
          'binding': {
            'arrangementLyricHash': arrangementLyricHash,
            'sourceId': source.id,
            'recordingVerified': sameRecording && timingSelected,
            if (status == TimingStatus.usable)
              'occurrences': timingOccurrenceMap(track, best.body),
          },
        },
      );
    }
  }
  final usable = tracks.values.where((t) => t.status == TimingStatus.usable);
  final historicalAuthors = accepted
      .where(
        (source) =>
            source.candidate.providerId == 'wikisource' &&
            historicalMatches(source),
      )
      .map((source) => source.candidate.artist.trim())
      .where((artist) => artist.isNotEmpty)
      .toList();
  final historicalAuthorIdentities = historicalAuthors
      .map(_identityNorm)
      .toSet();
  final historicalAuthor = historicalAuthorIdentities.length == 1
      ? historicalAuthors.first
      : null;
  final sectioned = inferSectionDirectives(sectionMerged.body);
  final filled = preferredSourceId == null && chordSourceIds.isNotEmpty
      ? _fillRepeatedSections(
          sectioned,
          requireMatchingLyrics: merged.contextApplied,
        )
      : (body: sectioned, lines: 0);
  final finalBody = filled.body;
  // The search row's album and length fill only what no source stated.
  for (final (field, value) in [
    ('album', rowAlbum),
    ('durationSeconds', _validDuration(rowDuration)),
  ]) {
    if (_hasMetadata(metadata[field]) || value is! Object) continue;
    if (value is String && value.trim().isEmpty) continue;
    metadata[field] = value;
    origins[field] = selected.identity;
    fieldContributors[field] = {selected.identity};
  }
  final song = SongDocument(
    id: newId(),
    title: selected.title,
    artist: selected.artist.trim().isNotEmpty
        ? selected.artist
        : historicalAuthor ?? selected.artist,
    body: finalBody,
    metadata: metadata,
    sources: _sourceDocuments(inputSources, results),
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
      // Chord sources whose chart was moved into the key most charts share.
      if (preferredSourceId == null &&
          chordSourceIds.any((id) => sourcesById[id]?.extra['keyShift'] is int))
        'chordKeyShifts': {
          for (final id in chordSourceIds)
            if (sourcesById[id]?.extra['keyShift'] case final int shift)
              id: shift,
        },
      if (sectionSourceIds.isNotEmpty) 'sectionSourceIds': sectionSourceIds,
      // Lines that took the chords of an earlier section of the same kind.
      if (filled.lines > 0) 'chordsFromSections': filled.lines,
      // A display-only key estimate from discovery's chord key double check,
      // valid only for this exact chart (see [checkedChordKeyEstimate]).
      if (preferredSourceId == null)
        if (_agreedKeyEstimate([
              for (final id in chordSourceIds) ?sourcesById[id],
            ])
            case final String sounding)
          'chordKeyEstimate': {
            // The estimate is a sounding key; the chart is read in shapes.
            'key': transposeChord(
              sounding,
              (12 - _capoOf(metadata['capo'])) % 12,
            ),
            'bodyHash': _bodyHash(finalBody),
          }
        else if (_recordingHintedEstimate(finalBody, [
              for (final id in chordSourceIds) ?sourcesById[id],
            ], metadata['capo'])
            case final String shapes)
          'chordKeyEstimate': {
            'key': shapes,
            'bodyHash': _bodyHash(finalBody),
            'hint': 'recording',
          }
        else if (_singleChartEstimate(finalBody, [
              for (final id in chordSourceIds) ?sourcesById[id],
            ])
            case final String shapes)
          'chordKeyEstimate': {
            'key': shapes,
            'bodyHash': _bodyHash(finalBody),
            'hint': 'chart',
          },
      if (chordSourceIds.any(
        (sourceId) => sourcesById[sourceId]?.hasPendingMatchCheck == true,
      ))
        'pendingChordSourceIds': chordSourceIds
            .where(
              (sourceId) => sourcesById[sourceId]?.hasPendingMatchCheck == true,
            )
            .toList(),
      'excludedIncompleteSourceIds': accepted
          .where((s) => !eligible.contains(s))
          .map((s) => s.id)
          .toList(),
    },
  );
  final corroboratedKey = preferredSourceId == null
      ? null
      : corroboratedArrangementKey(song);
  final recoveredKey = preferredSourceId == null
      ? null
      : sourcedArrangementKey(song);
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
  if (preferredSourceId == null) {
    // Placement can supersede the initially preferred chart. Reconcile setup
    // and key against the surviving anchors, including any capo conversion.
    final appliedPlan = _rankSourceCombination(
      selected,
      results,
      scores: scoreCache,
      lyricSourceIds: {best.id},
      chartSourceIds: chordSourceIds
          .where((id) => !merged.movedIds.contains(id))
          .toSet(),
      factSourceIds: matching.map((source) => source.id).toSet(),
      metadataContextMatches: metadataContextMatches,
    );
    _applyRankedMetadata(song, appliedPlan);
    (song.extra['evidenceRanking']
        as Map<String, dynamic>)['initialSelection'] = {
      'chosenByField': {
        for (final entry in evidencePlan!.chosenByField.entries)
          if (const {
            'lyrics',
            'chords',
            'metadata.key',
            'metadata.capo',
            'metadata.tuning',
          }.contains(entry.key))
            entry.key: {
              'sourceId': entry.value.sourceId,
              'value': entry.value.value,
            },
      },
      'alternatives': [
        for (final option in evidencePlan.claims)
          if (option.claim.field == 'chords' ||
              option.claim.field == 'metadata.key' &&
                  (option.claim.origin != EvidenceOrigin.inferred ||
                      option.rank < 3))
            option.toJson(),
      ],
    };
    (song.extra['evidenceRanking']
        as Map<String, dynamic>)['arrangementBinding'] = {
      'bodyHash': _bodyHash(song.body),
      'chordSourceIds': chordSourceIds,
      'transposedSourceIds': merged.movedIds.toList()..sort(),
    };
  } else if (evidencePlan != null) {
    song.extra['evidenceRanking'] = {
      'version': 1,
      ...evidencePlan.toJson(),
      'selectionMode': 'explicitSource',
    };
  }
  final enriched = enrichCombinedDisplayMetadata(
    song,
    isSameRecording: recordingCompatible,
  );
  return omitExplicitDiagnostics
      ? enriched.copyWith(sources: const [])
      : enriched;
}

/// A string that is equal for equal metadata values, for comparing and
/// de-duplicating them. A value JSON cannot encode (an infinite number from
/// an overflowing literal) compares by its text instead of throwing.
String _valueKey(Object? value) {
  try {
    return jsonEncode(value);
  } on Object {
    return '$value';
  }
}

/// Persisted and imported evidence is untrusted: a field expected to hold a
/// list may hold anything. A value of another type reads as no entries.
List<dynamic> _listOrEmpty(Object? value) =>
    value is List ? value : const <dynamic>[];

bool _hasMetadata(Object? value) => hasEvidenceValue(value);

/// Combines nonempty resolved metadata with facts from its search candidate.
/// Null and blank values mean the resolved response omitted a fact; they do
/// not erase a usable search-hit value. Nested maps retain candidate entries
/// while allowing nonempty resolved entries to take precedence.
Object? _mergeMetadataFact(
  Object? existing,
  Object? incoming, {
  bool mergeLists = false,
}) {
  if (!_hasMetadata(incoming)) return existing;
  if (existing is List && incoming is List) {
    if (!mergeLists) return incoming;
    final seen = <String>{};
    return [
      for (final value in [...existing, ...incoming])
        if (seen.add(_valueKey(value))) value,
    ];
  }
  if (existing is! Map || incoming is! Map) return incoming;

  final merged = jsonMap(existing);
  for (final entry in jsonMap(incoming).entries) {
    if (!_hasMetadata(entry.value)) continue;
    final prior = merged[entry.key];
    merged[entry.key] = _mergeMetadataFact(prior, entry.value);
  }
  return merged;
}
