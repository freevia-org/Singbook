import 'dart:convert';
import 'dart:math' as math;
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
import 'search_grouping.dart' show rowAlbumKey, rowDurationKey;
import 'arrangement_context.dart';
import 'contextual_chart_lyrics.dart';
import 'compact_chord_alignment.dart';
import 'lyric_word_identity.dart';
import 'short_lyric_reference.dart';
import 'chord_key_estimate.dart'
    show
        estimateChordKey,
        rankChordKeyCandidates,
        chartSupportsDeclaredTonic,
        chartSupportsBoundaryTonic;
import 'evidence_ranking.dart';
import 'source_evidence.dart';
import 'chart_arrangements.dart';
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
String _identityNorm(String text) =>
    _norm(text.replaceAll(RegExp("['‘’]"), ''));
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
  for (final entry in a.recordingIds.entries) {
    if (b.recordingIds.containsKey(entry.key) &&
        b.recordingIds[entry.key] != entry.value) {
      return false;
    }
  }
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
const _pitchClasses = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};

/// Pitch-class counts of a chart's chord roots, one per chord occurrence.
List<int> _rootHistogram(String chart) {
  final counts = List<int>.filled(12, 0);
  for (final line in parseArrangement(chart)) {
    for (final anchor in line.chords) {
      final match = RegExp(
        r'^([A-G])([#b♯♭]?)',
      ).firstMatch(anchor.chord.trim());
      if (match == null) continue;
      var pitch = _pitchClasses[match[1]!]!;
      if (match[2] == '#' || match[2] == '♯') pitch++;
      if (match[2] == 'b' || match[2] == '♭') pitch--;
      counts[pitch % 12]++;
    }
  }
  return counts;
}

double _similarity(List<int> a, List<int> b, int shift) {
  var dot = 0.0, normA = 0.0, normB = 0.0;
  for (var pitch = 0; pitch < 12; pitch++) {
    final x = a[pitch].toDouble(), y = b[(pitch + shift) % 12].toDouble();
    dot += x * y;
    normA += x * x;
    normB += y * y;
  }
  return normA == 0 || normB == 0 ? 0 : dot / math.sqrt(normA * normB);
}

/// Semitones (0-11) that move chart [a]'s chord roots onto chart [b]'s: 0 when
/// both are in the same key, 9 when [a] is in G and [b] the same progression
/// in E. Null when either chart is too sparse or the two do not look like one
/// progression in any key.
int? chordTransposition(String a, String b) {
  final first = _rootHistogram(a), second = _rootHistogram(b);
  if (first.fold<int>(0, (n, c) => n + c) < 8 ||
      second.fold<int>(0, (n, c) => n + c) < 8) {
    return null;
  }
  var best = 0;
  var bestScore = -1.0;
  for (var shift = 0; shift < 12; shift++) {
    final score = _similarity(first, second, shift);
    if (score > bestScore) {
      best = shift;
      bestScore = score;
    }
  }
  if (bestScore < .85) return null;
  // A close second reading in the original key keeps the charts together.
  return _similarity(first, second, 0) >= bestScore - .05 ? 0 : best;
}

/// Semitones from key [from] up to key [to], comparing a minor key by its
/// relative major ("Am" and "C" are 0 apart). Null when either is not a key.
int? _keyDistance(String from, String to) {
  int? major(String key) {
    final identity = _keyIdentity(key);
    if (identity == null) return null;
    final parts = identity.split(':');
    final pitch = int.parse(parts[0]);
    return parts[1] == 'minor' ? (pitch + 3) % 12 : pitch;
  }

  final a = major(from), b = major(to);
  return a == null || b == null ? null : (b - a + 12) % 12;
}

/// Semitones from chart [a] played with [capoA] to chart [b] played with
/// [capoB]: the difference in sounding key, or null when the chords do not
/// line up.
int? soundingTransposition(String a, Object? capoA, String b, Object? capoB) {
  final shapes = chordTransposition(a, b);
  return shapes == null
      ? null
      : (shapes + _capoOf(capoB) - _capoOf(capoA)) % 12;
}

int _capoOf(Object? capo) {
  final value = capo is num ? capo.toInt() : int.tryParse('${capo ?? ''}');
  return value == null || value < 0 ? 0 : value % 12;
}

bool _isExplicitZeroCapo(Object? capo) => capo is num
    ? capo.isFinite && capo == 0
    : capo is String && capo.trim() == '0';

bool _isStandardTuning(Object? tuning) {
  final text = tuning is List ? tuning.join(' ') : tuning?.toString();
  if (text == null) return false;
  return text
          .toLowerCase()
          .split(RegExp(r'[\s,\[\]]+'))
          .where((note) => note.isNotEmpty)
          .join(' ') ==
      'e a d g b e';
}

bool _compatibleChartTuning(Object? selected, Object? donor) {
  if (!_hasMetadata(selected) && !_hasMetadata(donor)) return true;
  if (!_hasMetadata(selected)) return _isStandardTuning(donor);
  if (!_hasMetadata(donor)) return _isStandardTuning(selected);
  String normalize(Object? value) =>
      (value is List ? value.join(' ') : '$value')
          .toLowerCase()
          .split(RegExp(r'[\s,\[\]]+'))
          .where((note) => note.isNotEmpty)
          .join(' ');
  return normalize(selected) == normalize(donor);
}

/// Whether a chart's declared (sounding) key fits its own chords played with
/// [capo]. A chart whose chords give no key estimate is not contradicted.
bool declaredKeyFitsChords(String chart, String declared, Object? capo) {
  final estimate = estimateChordKey(chart)?.key;
  if (estimate == null) return true;
  return _keyDistance(estimate, declared) == _capoOf(capo);
}

bool _keyFitsKnownChords(SongDocument song, String key) {
  return estimateChordKey(song.body) != null &&
      declaredKeyFitsChords(
        song.body,
        key,
        _nonemptyFallback(
          song.metadata['capo'],
          song.selectedRecording?.metadata['capo'],
        ),
      );
}

Object? _nonemptyFallback(Object? preferred, Object? fallback) =>
    _hasMetadata(preferred) ? preferred : fallback;

int _keyEvidenceCompare(
  SongDocument song,
  ({String key, List<String> sourceIds}) a,
  ({String key, List<String> sourceIds}) b,
) {
  int distinctProviders(({String key, List<String> sourceIds}) claim) => song
      .sources
      .where((source) => claim.sourceIds.contains(source.id))
      .map((source) => source.candidate.providerId)
      .toSet()
      .length;
  int recordingMatches(({String key, List<String> sourceIds}) claim) => song
      .sources
      .where(
        (source) =>
            claim.sourceIds.contains(source.id) &&
            source.matchKind == MatchKind.sameRecording,
      )
      .map((source) => source.candidate.providerId)
      .toSet()
      .length;
  final providers = distinctProviders(b).compareTo(distinctProviders(a));
  if (providers != 0) return providers;
  final recordings = recordingMatches(b).compareTo(recordingMatches(a));
  if (recordings != 0) return recordings;
  final aFits = _keyFitsKnownChords(song, a.key);
  final bFits = _keyFitsKnownChords(song, b.key);
  if (aFits != bFits) return aFits ? -1 : 1;
  return 0;
}

/// The declared key to keep for a chart whose chords were moved [shift]
/// semitones into the majority key: unchanged when it already fits the moved
/// chords (its label was right and its chords were not), moved with the
/// chords when it fitted the original chords, otherwise none.
String? declaredKeyAfterShift(
  String chart,
  String? declared,
  Object? capo,
  int shift,
) {
  if (declared == null || declared.trim().isEmpty) return null;
  final key = declared.trim();
  if (declaredKeyFitsChords(transposeBody(chart, shift), key, capo)) {
    final estimate = estimateChordKey(chart)?.key;
    // Without an estimate both readings fit; the label moves with the chords.
    if (estimate != null) return key;
  }
  return declaredKeyFitsChords(chart, key, capo)
      ? transposeChord(key, shift)
      : null;
}

/// Whether keys [a] and [b] share a tonic or are relative major and minor
/// ("D" and "Bm"), the confusion typical of keys measured from audio.
bool keysAgree(String a, String b) => _keyDistance(a, b) == 0;

/// A chart's estimated sounding key: the estimate from its chord shapes,
/// raised by its capo. Null when the chords give no estimate.
String? soundingChartKey(String chart, Object? capo) {
  final estimate = estimateChordKey(chart)?.key;
  if (estimate == null) return null;
  final frets = _capoOf(capo);
  return frets == 0 ? estimate : transposeChord(estimate, frets);
}

/// How far each of [charts] sounds from the key most charts are written in.
/// See [chordKeyVerdict], which also reports how a [recordingKey] voted.
List<int?>? chordKeyMajority(
  List<String> charts, {
  List<Object?> capos = const [],
  List<String?> declaredKeys = const [],
  List<bool> anchors = const [],
  String? recordingKey,
}) => chordKeyVerdict(
  charts,
  capos: capos,
  declaredKeys: declaredKeys,
  anchors: anchors,
  recordingKey: recordingKey,
)?.shifts;

/// How far each of [charts] sounds from the key most charts are written in.
///
/// Each chart is compared with the first, by its chord shapes plus its
/// [capos] entry. Identical chord sequences (one chart copied to another
/// site) vote once. A chart whose [declaredKeys] entry contradicts its own
/// chords also votes for the key its label names. A [recordingKey] measured
/// from the recording's audio votes too, placed through any chart whose
/// chords give an estimate; a relative major or minor counts as agreeing.
///
/// One key wins with more than half of all distinct votes. Without such a
/// majority, recording-level evidence (charts marked in [anchors], such as
/// Songsterr transcriptions, and [recordingKey]) decides when exactly one key
/// has both recording-level support and at least one other distinct vote: a
/// plurality of crowd charts alone never moves a chart.
///
/// `shifts` has one entry per chart: the semitones that move its chords into
/// the winning key, keeping its capo (0 when it is already there), or null
/// when its key could not be compared. `recordingAgrees` tells whether the
/// recording key voted for the winner. Returns null without a winner.
({List<int?> shifts, bool recordingAgrees})? chordKeyVerdict(
  List<String> charts, {
  List<Object?> capos = const [],
  List<String?> declaredKeys = const [],
  List<bool> anchors = const [],
  String? recordingKey,
}) {
  if (charts.isEmpty) return null;
  int capo(int i) => i < capos.length ? _capoOf(capos[i]) : 0;
  final shapes = [
    0,
    for (final chart in charts.skip(1)) chordTransposition(charts.first, chart),
  ];
  final sounds = [
    for (var i = 0; i < charts.length; i++)
      shapes[i] == null ? null : (shapes[i]! + capo(i)) % 12,
  ];
  final votes = <int, Set<String>>{};
  final special = <String>{};
  for (var i = 0; i < charts.length; i++) {
    final sound = sounds[i];
    if (sound == null) continue;
    final sequence = [
      for (final line in parseArrangement(charts[i]))
        for (final anchor in line.chords) anchor.chord.trim(),
    ].join(' ');
    votes.putIfAbsent(sound, () => {}).add(sequence);
    if (i < anchors.length && anchors[i]) special.add(sequence);
    final declared = i < declaredKeys.length ? declaredKeys[i] : null;
    final estimate = declared == null ? null : estimateChordKey(charts[i])?.key;
    if (declared == null || estimate == null) continue;
    final distance = _keyDistance(estimate, declared);
    if (distance == null || distance == capo(i)) continue;
    votes
        .putIfAbsent((shapes[i]! + distance) % 12, () => {})
        .add('label:$sequence');
  }
  int? recordingClass;
  if (recordingKey != null) {
    for (var i = 0; i < charts.length && recordingClass == null; i++) {
      final sound = sounds[i];
      final sounding = sound == null ? null : soundingChartKey(charts[i], null);
      if (sound == null || sounding == null) continue;
      // [sounding] is the chart's shape key; add its capo to compare.
      final distance = _keyDistance(sounding, recordingKey);
      if (distance == null) continue;
      recordingClass = (sound - capo(i) + distance + 12) % 12;
    }
    if (recordingClass != null) {
      const vote = 'recording';
      votes.putIfAbsent(recordingClass, () => {}).add(vote);
      special.add(vote);
    }
  }
  if (votes.length < 2 && charts.length < 2) return null;
  final ranked = votes.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  if (ranked.isEmpty) return null;
  final total = votes.values.fold<int>(0, (n, set) => n + set.length);
  int? winner = ranked.first.value.length * 2 > total && votes.length > 1
      ? ranked.first.key
      : null;
  if (winner == null) {
    final supported = [
      for (final entry in votes.entries)
        if (entry.value.any(special.contains) &&
            entry.value.any((vote) => !special.contains(vote)))
          entry.key,
    ];
    if (supported.length == 1) winner = supported.single;
  }
  if (winner == null) return null;
  return (
    shifts: [
      for (final sound in sounds)
        sound == null ? null : (winner - sound + 12) % 12,
    ],
    recordingAgrees: recordingClass == winner,
  );
}

/// A chord chart moved into the key most charts share, when discovery found
/// it transposed (`keyShift`). Saved sources keep their published chart; only
/// the automatically combined arrangement uses the corrected key.
String _keyCorrectedBody(SourceResult source) {
  final shift = source.extra['keyShift'];
  final estimate = source.extra['keyEstimate'];
  return shift is int && shift % 12 != 0 && source.hasChords
      ? transposeBody(
          source.body,
          shift,
          flats: estimate is String ? _flatKey(estimate) : null,
        )
      : source.body;
}

/// Whether a key is conventionally written with flats (F, Bb, Eb, Ab, Db,
/// Gb and their relative minors).
bool _flatKey(String key) => const {
  'F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb', //
  'Dm', 'Gm', 'Cm', 'Fm', 'Bbm', 'Ebm', 'Abm',
}.contains(key.trim());

/// The note spelling a chart's chords use: flats when its roots are mostly
/// flat, sharps when mostly sharp, otherwise its estimated key's spelling.
bool? _chartSpelling(String body) {
  var flats = 0, sharps = 0;
  for (final line in parseArrangement(body)) {
    for (final anchor in line.chords) {
      final root = RegExp(r'^[A-G]([#b♯♭]?)').firstMatch(anchor.chord);
      final accidental = root?.group(1) ?? '';
      if (accidental == 'b' || accidental == '♭') flats++;
      if (accidental == '#' || accidental == '♯') sharps++;
    }
  }
  if (flats != sharps) return flats > sharps;
  final key = estimateChordKey(body)?.key;
  return key == null ? null : _flatKey(key);
}

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

bool explicitHistoricalWorkMatches(
  SongCandidate selected,
  SourceResult source,
) {
  final candidate = source.candidate;
  final metadata = source.metadata;
  final revision = metadata['revision'];
  final selectedPageId = int.tryParse(selected.id);
  if (source.matchKind != MatchKind.sameSong ||
      source.matchReason != 'explicit_historical_work' ||
      selected.providerId != 'wikisource' ||
      candidate.providerId != 'wikisource' ||
      !RegExp(r'^[1-9]\d*$').hasMatch(selected.id) ||
      selectedPageId == null ||
      selectedPageId <= 0 ||
      candidate.id != selected.id ||
      _identityNorm(selected.title) != _identityNorm(candidate.title) ||
      (selected.artist.trim().isNotEmpty &&
          _identityNorm(selected.artist) != _identityNorm(candidate.artist)) ||
      metadata['identityScope'] != 'historicalText' ||
      candidate.metadata['identityScope'] != 'historicalText' ||
      metadata['resolvedPageId'] != selected.id ||
      candidate.metadata['resolvedPageId'] != selected.id ||
      metadata['resolvedTitle'] != candidate.title ||
      candidate.metadata['resolvedTitle'] != candidate.title ||
      revision is! int ||
      revision <= 0 ||
      candidate.metadata['revision'] is! int ||
      candidate.metadata['revision'] != revision ||
      source.extra['revision'] is! String ||
      source.extra['revision'] != revision.toString()) {
    return false;
  }
  final tags = metadata['copyrightTags'];
  final candidateTags = candidate.metadata['copyrightTags'];
  if (tags is! List ||
      tags.isEmpty ||
      jsonEncode(tags) != jsonEncode(candidateTags)) {
    return false;
  }
  final rights = jsonMap(source.extra['rights']);
  final permissions = jsonMap(rights['permissions']);
  final rightsTags = permissions['tags'];
  return rights['source'] == 'wikisource' &&
      rights['sourceId'] == selected.id &&
      rights['license'] is String &&
      (rights['license'] as String).trim().isNotEmpty &&
      permissions['status'] == 'per_work_and_jurisdiction' &&
      rightsTags is List &&
      rightsTags.isNotEmpty &&
      jsonEncode(tags) == jsonEncode(rightsTags);
}

String _historicalPayload(Object? value) {
  Object? ordered(Object? item) {
    if (item is Map) {
      final keys = item.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: ordered(item[key])};
    }
    if (item is List) return item.map(ordered).toList();
    return item;
  }

  return jsonEncode(ordered(value));
}

/// An unchanged version read from the local library, never fresh extraction
/// proof. This capability is not serialized. Production callers construct it
/// only at AppController's repository-backed saved comparison boundary.
class HistoricalCacheUse {
  HistoricalCacheUse._(this._source, this._payload, this._selection);
  final SourceResult _source;
  final String _payload, _selection;

  static HistoricalCacheUse? fromLibrarySnapshot(
    SongDocument stored,
    SongCandidate selected,
    SourceResult source,
  ) {
    if (stored.extensionError != null ||
        !_legacyHistoricalWork(stored, selected, source)) {
      return null;
    }
    final payload = _historicalPayload(source.toJson());
    if (!stored.sources.any(
      (item) => _historicalPayload(item.toJson()) == payload,
    )) {
      return null;
    }
    return HistoricalCacheUse._(
      source,
      payload,
      _historicalPayload(selected.toJson()),
    );
  }

  bool allows(SongCandidate selected, SourceResult source) =>
      identical(source, _source) &&
      _selection == _historicalPayload(selected.toJson()) &&
      _payload == _historicalPayload(source.toJson());

  /// Carry only an already authorized unchanged object into the synchronous
  /// save snapshot. A new provider result with the same ID cannot acquire use.
  HistoricalCacheUse? capture(
    SongCandidate selected,
    SourceResult original,
    SourceResult snapshot,
  ) =>
      allows(selected, original) &&
          _payload == _historicalPayload(snapshot.toJson())
      ? HistoricalCacheUse._(snapshot, _payload, _selection)
      : null;
}

bool _legacyHistoricalWork(
  SongDocument stored,
  SongCandidate selected,
  SourceResult source,
) {
  final found = source.candidate;
  final metadata = source.metadata;
  final anchor =
      stored.selectedRecording ??
      (stored.extra['selectedSourceId'] == source.id ? found : null);
  if (anchor == null ||
      _historicalPayload(anchor.toJson()) !=
          _historicalPayload(selected.toJson()) ||
      selected.providerId != 'wikisource' ||
      found.providerId != 'wikisource' ||
      !RegExp(r'^[1-9]\d*$').hasMatch(selected.id) ||
      int.tryParse(selected.id) == null ||
      found.id != selected.id ||
      _identityNorm(selected.title).isEmpty ||
      _identityNorm(selected.title) != _identityNorm(found.title) ||
      (selected.artist.trim().isNotEmpty &&
          _identityNorm(selected.artist) != _identityNorm(found.artist)) ||
      selected.metadata['identityScope'] != 'historicalText' ||
      found.metadata['identityScope'] != 'historicalText' ||
      metadata['identityScope'] != 'historicalText' ||
      source.extra['sourceDocumentId'] != source.id ||
      source.extra['userSelectedImport'] != true ||
      plainLyrics(source.body).trim().isEmpty) {
    return false;
  }
  final acceptedLegacy =
      source.matchKind == MatchKind.sameSong &&
          source.matchReason == 'same_song' ||
      source.matchKind == MatchKind.sameRecording &&
          source.matchReason == 'same_recording';
  // The original matcher rejected the newly populated author even though the
  // person had selected that exact page and explicitly saved its source card.
  final rejectedAuthorFill =
      source.matchKind == MatchKind.rejected &&
      source.matchReason == 'identity_mismatch' &&
      stored.selectedRecording != null &&
      selected.artist.trim().isEmpty &&
      found.artist.trim().isNotEmpty &&
      stored.extra['savedSourceId'] == source.id &&
      stored.extra['selectedSourceId'] == source.id;
  if (!acceptedLegacy && !rejectedAuthorFill) return false;
  for (final facts in [found.metadata, metadata]) {
    if (facts.containsKey('resolvedPageId') &&
            facts['resolvedPageId'] != selected.id ||
        facts.containsKey('resolvedTitle') &&
            facts['resolvedTitle'] != found.title) {
      return false;
    }
  }
  final tags = metadata['copyrightTags'];
  final rights = jsonMap(source.extra['rights']);
  final permissions = jsonMap(rights['permissions']);
  final revision = metadata['revision'];
  if (tags is! List ||
      tags.isEmpty ||
      tags.any(
        (tag) =>
            tag is! String ||
            !RegExp(
              r'^Template:(?:PD-|Cc-by|CC0)',
              caseSensitive: false,
            ).hasMatch(tag),
      ) ||
      _historicalPayload(tags) !=
          _historicalPayload(found.metadata['copyrightTags']) ||
      _historicalPayload(tags) != _historicalPayload(permissions['tags']) ||
      rights['source'] != 'wikisource' ||
      rights['sourceId'] != selected.id ||
      permissions['status'] != 'per_work_and_jurisdiction' ||
      rights['license'] != tags.join('; ') ||
      revision is! int ||
      revision <= 0 ||
      found.metadata['revision'] != revision ||
      source.extra.containsKey('revision') &&
          source.extra['revision'] != revision.toString()) {
    return false;
  }
  bool pageUrl(Object? value) {
    if (value == null) return true;
    if (value is! String) return false;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'en.wikisource.org' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort && uri.port != 443) {
      return false;
    }
    if (uri.queryParameters.containsKey('curid')) {
      return (uri.path.isEmpty || uri.path == '/') &&
          uri.queryParameters.length == 1 &&
          uri.queryParametersAll['curid']?.length == 1 &&
          uri.queryParameters['curid'] == selected.id;
    }
    if (!uri.path.startsWith('/wiki/') || uri.hasQuery) return false;
    try {
      return _identityNorm(
            Uri.decodeComponent(uri.path.substring(6)).replaceAll('_', ' '),
          ) ==
          _identityNorm(found.title);
    } on FormatException {
      return false;
    }
  }

  return pageUrl(selected.url) &&
      pageUrl(found.url) &&
      pageUrl(rights['sourceUrl']) &&
      (!rights.containsKey('licenseUrl') ||
          rights['licenseUrl'] ==
              'https://en.wikisource.org/wiki/Wikisource:Copyright_policy');
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

final _normalizedLineLetterOrNumber = RegExp(r'[\p{L}\p{N}]', unicode: true);

({String text, List<int> offsets}) _normalizedLine(String text) {
  // Most lyric text is ASCII. Avoid building grapheme and RegExp objects for
  // every character while retaining the same normalized-to-original offsets.
  if (text.codeUnits.every((unit) => unit < 0x80)) {
    final normalized = StringBuffer();
    final offsets = <int>[];
    var pendingSeparator = false;
    for (var index = 0; index < text.length; index++) {
      var unit = text.codeUnitAt(index);
      if (unit >= 0x41 && unit <= 0x5a) unit += 0x20;
      final isLetterOrNumber =
          (unit >= 0x61 && unit <= 0x7a) || (unit >= 0x30 && unit <= 0x39);
      if (!isLetterOrNumber) {
        if (normalized.isNotEmpty) pendingSeparator = true;
        continue;
      }
      if (pendingSeparator && normalized.isNotEmpty) {
        normalized.write(' ');
        offsets.add(index);
      }
      normalized.writeCharCode(unit);
      offsets.add(index);
      pendingSeparator = false;
    }
    return (text: normalized.toString(), offsets: offsets);
  }

  final normalized = StringBuffer();
  final offsets = <int>[];
  var pendingSeparator = false;
  final graphemes = text.characters.toList();
  for (var index = 0; index < graphemes.length; index++) {
    final lowered = graphemes[index].toLowerCase().characters;
    final kept = lowered.where(_normalizedLineLetterOrNumber.hasMatch).toList();
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
    // Four-word keys avoid scanning every repeated three-word opening while
    // remaining a necessary prefix for every valid full-phrase occurrence.
    final count = tokens.length.clamp(1, 4);
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
  // Text already given chords by a phrase; another placement may not overlap
  // it, or two readings of one passage ("na na na ...") would interleave.
  final claimed = <(int, int)>[];
  bool overlapsClaimed(int start, int end) =>
      claimed.any((range) => start < range.$2 && range.$1 < end);
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
      // Overlapping occurrences of one phrase are one passage.
      if (matches.isNotEmpty && start < matches.last.end) continue;
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
      if (overlapsClaimed(start, end)) continue;
      claimed.add((start, end));
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

bool _compatibleMetadataKeySource(SongDocument song, SourceResult source) {
  final selected =
      song.selectedRecording ??
      SongCandidate(
        providerId: 'library',
        id: song.id,
        title: song.title,
        artist: song.artist,
      );
  if (!explicitEditionsCompatible(
        selected,
        source.candidate,
        metadata: source.metadata,
        extra: source.extra,
      ) ||
      !_sameSong(selected, source.candidate) ||
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
    final base = _nonemptyFallback(
      song.metadata[field],
      selected.metadata[field],
    );
    final donor = _nonemptyFallback(
      source.metadata[field],
      source.candidate.metadata[field],
    );
    if (field == 'capo' &&
        !_hasMetadata(base) &&
        _hasMetadata(donor) &&
        _isExplicitZeroCapo(donor)) {
      continue;
    }
    if (field == 'tuning') {
      if (!_compatibleChartTuning(base, donor)) return false;
      continue;
    }
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
Map<String, ({String key, List<String> sourceIds})>
_corroboratedArrangementKeyClaims(SongDocument song) {
  if (_hasMetadata(song.metadata['key']) ||
      jsonMap(song.extra['fieldOrigins'])['key'] == 'user' ||
      !song.hasChords) {
    return const {};
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
  final chordSourceIds =
      (song.extra['chordSourceIds'] as List?)?.whereType<String>().toSet() ??
      const <String>{};
  for (final source in song.sources) {
    final contributingChartCreditMatches =
        source.extra['requiresLyricsAgreement'] == true &&
        chordSourceIds.contains(source.id) &&
        _sameArrangedSong(source.candidate, selected);
    if (!source.hasChords ||
        !(const {
              MatchKind.sameSong,
              MatchKind.sameRecording,
            }.contains(source.matchKind) ||
            // A shortened chart can be rejected as a full lyric replacement,
            // while still supplying a key corroborated against chosen chords.
            (source.matchKind == MatchKind.rejected &&
                source.matchReason == 'incomplete_or_different_lyrics')) ||
        source.hasPendingMatchCheck ||
        !(_sameSong(source.candidate, selected) ||
            // A positively accepted same-song chart can carry a different
            // provider credit from the selected catalog artist. The match
            // verdict is useful only together with the edition guard above,
            // setup compatibility below, and phrase/chord corroboration
            // against the saved arrangement; it never promotes a rejected
            // or pending chart.
            (source.matchKind == MatchKind.sameSong &&
                _version(source.candidate.title) == _version(selected.title)) ||
            contributingChartCreditMatches) ||
        _version(source.candidate.title) != _version(selected.title)) {
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

({String key, List<String> sourceIds})? _bestKeyClaim(
  SongDocument song,
  Map<String, ({String key, List<String> sourceIds})> claims,
) {
  if (claims.isEmpty) return null;
  final ranked = claims.values.toList()
    ..sort((a, b) => _keyEvidenceCompare(song, a, b));
  if (ranked.length > 1 &&
      _keyEvidenceCompare(song, ranked[0], ranked[1]) == 0) {
    return null;
  }
  return ranked.first;
}

({String key, List<String> sourceIds})? corroboratedArrangementKey(
  SongDocument song,
) => _bestKeyClaim(song, _corroboratedArrangementKeyClaims(song));

List<String> _arrangementKeySetupMismatchFields(
  SongDocument song,
  SourceResult source,
) {
  final selected =
      song.selectedRecording ??
      SongCandidate(
        providerId: 'library',
        id: song.id,
        title: song.title,
        artist: song.artist,
      );
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
  final selected =
      song.selectedRecording ??
      SongCandidate(
        providerId: 'library',
        id: song.id,
        title: song.title,
        artist: song.artist,
      );
  final chordSourceIds =
      (song.extra['chordSourceIds'] as List?)?.whereType<String>().toSet() ??
      const <String>{};
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
    final basicEligible =
        (const {
              MatchKind.sameSong,
              MatchKind.sameRecording,
            }.contains(source.matchKind) ||
            source.matchKind == MatchKind.rejected &&
                source.matchReason == 'incomplete_or_different_lyrics') &&
        !source.hasPendingMatchCheck &&
        (_sameSong(source.candidate, selected) || chartCredit) &&
        _version(source.candidate.title) == _version(selected.title);
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
  final rankedSourceIds = (ranked['claims'] as List? ?? const [])
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
    if (value == null ||
        value is String && value.trim().isEmpty ||
        value is Iterable && value.isEmpty ||
        value is Map && value.isEmpty) {
      continue;
    }
    return value;
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
        : jsonEncode(baseValue);
    final normalizedDonor = donorValue is String
        ? donorValue.trim().toLowerCase()
        : jsonEncode(donorValue);
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

/// Section kinds whose later instances usually repeat an earlier one's
/// harmony.
const _repeatingSections = {'verse', 'chorus', 'pre-chorus', 'refrain'};

/// Charts often give chords for the first verse only ("same as verse 1"). A
/// lyric line without chords in a later section takes the chords of the same
/// line in the most recent earlier section of the same kind (verse, chorus,
/// pre-chorus, refrain) with as many lyric lines, if that line has chords.
/// Chords keep their relative word positions. Lines with escapes or
/// non-plain characters are left alone.
({String body, int lines}) _fillRepeatedSections(
  String body, {
  bool requireMatchingLyrics = false,
}) {
  final raw = body.split('\n');
  final parsed = parseArrangement(body);
  final sections = <({String kind, List<int> lyrics})>[];
  String? kind;
  var lyrics = <int>[];
  void close() {
    if (kind != null && lyrics.isNotEmpty) {
      sections.add((kind: kind, lyrics: lyrics));
    }
    lyrics = <int>[];
  }

  for (var i = 0; i < parsed.length; i++) {
    final label = sectionLabelForLine(parsed[i]);
    if (label != null) {
      close();
      kind = label.toLowerCase().replaceAll(RegExp(r'\s*\d+$'), '').trim();
      continue;
    }
    if (parsed[i].directive) {
      if (RegExp(r'^\s*\{(end_of_|eo)').hasMatch(parsed[i].text)) {
        close();
        kind = null;
      }
      continue;
    }
    if (parsed[i].text.trim().isEmpty) continue;
    lyrics.add(i);
  }
  close();
  var filled = 0;
  for (var s = 0; s < sections.length; s++) {
    final target = sections[s];
    if (!_repeatingSections.contains(target.kind)) continue;
    final models = sections
        .take(s)
        .where(
          (section) =>
              section.kind == target.kind &&
              section.lyrics.length == target.lyrics.length,
        )
        .toList();
    if (models.isEmpty) continue;
    for (var n = 0; n < target.lyrics.length; n++) {
      final index = target.lyrics[n];
      final to = parsed[index];
      if (to.chords.isNotEmpty) continue;
      // The most recent earlier section of this kind with chords on this
      // line; none when such sections disagree on its chords.
      final chorded = models
          .where((section) => parsed[section.lyrics[n]].chords.isNotEmpty)
          .toList();
      if (chorded.isEmpty ||
          chorded
                  .map(
                    (section) => parsed[section.lyrics[n]].chords
                        .map((chord) => chord.chord)
                        .join(' '),
                  )
                  .toSet()
                  .length >
              1) {
        continue;
      }
      final model = chorded.last;
      final from = parsed[model.lyrics[n]];
      if (raw[index].contains('\\') ||
          to.text.characters.length != to.text.length ||
          from.text.characters.length != from.text.length) {
        continue;
      }
      final fromWords = _lineWords(from.text), toWords = _lineWords(to.text);
      if (fromWords.isEmpty || toWords.isEmpty) continue;
      if (requireMatchingLyrics &&
          _repeatKey(from.text) != _repeatKey(to.text)) {
        continue;
      }
      final anchors = <ChordAnchor>[];
      for (final chord in from.chords) {
        final word = fromWords.indexWhere((w) => chord.offset < w.end);
        final position = word < 0
            ? toWords.length - 1
            : fromWords.length == 1
            ? 0
            : (word * (toWords.length - 1) / (fromWords.length - 1)).round();
        anchors.add(
          ChordAnchor(
            word < 0 ? to.text.length : toWords[position].start,
            chord.chord,
          ),
        );
      }
      final buffer = StringBuffer();
      var cursor = 0;
      for (final chord
          in anchors..sort((a, b) => a.offset.compareTo(b.offset))) {
        buffer.write(
          _escapeLiteralChordTokens(to.text.substring(cursor, chord.offset)),
        );
        buffer.write('[${chord.chord}]');
        cursor = chord.offset;
      }
      buffer.write(_escapeLiteralChordTokens(to.text.substring(cursor)));
      raw[index] = buffer.toString();
      filled++;
    }
  }
  return (body: raw.join('\n'), lines: filled);
}

final _wordToken = RegExp(r"[\p{L}\p{N}']+", unicode: true);

/// A line's words, lower case and without apostrophes; a dropped "g"
/// ("darlin'") is restored, as charts and lyrics spell it either way.
List<({String word, int start, int end})> _lineWords(String text) => [
  for (final match in _wordToken.allMatches(text))
    (
      word: foldLyricVowelAccents(
        match[0]!.toLowerCase(),
      ).replaceFirst(RegExp(r"in'$"), 'ing').replaceAll("'", ''),
      start: match.start,
      end: match.end,
    ),
];

typedef _Words = List<({String word, int start, int end})>;

/// Vocables sung around the lyrics that charts often leave out.
const _interjections = {
  'oh',
  'ooh',
  'oooh',
  'ah',
  'ahh',
  'aah',
  'uh',
  'whoa',
  'woah',
  'woo',
  'yeah',
  'yeh',
  'hey',
  'na',
  'la',
  'da',
  'doo',
  'dum',
  'ba',
  'sha',
  'mm',
  'mmm',
  'hmm',
  'ha',
  'oh-oh',
  'ay',
  'ayy',
  'eh',
  'o',
};

/// [line]'s chords moved onto words [to] through word alignment [pairs]
/// (from-index, to-index): each chord's target word index and offset inside
/// that word, or a null index for a chord after the last word. An unaligned
/// chord word borrows the position of the nearest aligned word that keeps
/// the chords in order.
List<(int?, int, String)> _mapChordWords(
  ArrangementLine line,
  _Words from,
  _Words to,
  List<(int, int)> pairs, {
  Map<int, int> trailingWordOverrides = const {},
}) {
  final aligned = {for (final (a, b) in pairs) a: b};
  final anchors = <(int?, int, String)>[];
  // Chords keep their order: a chord never lands before the previous one,
  // or on its word unless both sat on one chart word.
  int? previous, previousWord;
  var ended = false;
  for (final chord in line.chords) {
    final override = trailingWordOverrides[chord.offset];
    final index =
        override ?? from.indexWhere((word) => chord.offset < word.end);
    if (index < 0 || ended) {
      ended = true;
      anchors.add((null, 0, chord.chord));
      continue;
    }
    bool free(int probe) =>
        probe >= 0 &&
        probe < from.length &&
        aligned.containsKey(probe) &&
        (previous == null ||
            aligned[probe]! > previous ||
            (index == previousWord && aligned[probe] == previous));
    // The nearest free aligned word; the earlier one on a tie.
    int? probe;
    for (
      var distance = 0;
      distance < from.length && probe == null;
      distance++
    ) {
      if (free(index - distance)) {
        probe = index - distance;
      } else if (free(index + distance)) {
        probe = index + distance;
      }
    }
    if (probe == null) {
      // No aligned word left: the chord follows the line's last word.
      if (previous == null) continue;
      ended = true;
      anchors.add((null, 0, chord.chord));
      continue;
    }
    final target = to[aligned[probe]!];
    final inWord = probe == index
        ? (override == null
                  ? chord.offset - from[index].start
                  : from[index].end - from[index].start)
              .clamp(0, target.end - target.start)
        : 0;
    previous = aligned[probe]!;
    previousWord = index;
    anchors.add((previous, inWord, chord.chord));
  }
  return anchors;
}

/// The share of words two lines have in order. A line of four or more words
/// written almost entirely inside a longer one (at most 2.5 times as long),
/// as charts that write a repeated phrase once or break lines differently
/// do, counts as the weakest acceptable similarity, 0.8.
double _lineSimilarity(_Words a, _Words b, List<(int, int)> pairs) {
  final longer = a.length > b.length ? a.length : b.length;
  final shorter = a.length > b.length ? b.length : a.length;
  final overall = pairs.length / longer;
  if (overall >= .8) return overall;
  return shorter >= 4 && longer <= shorter * 2.5 && pairs.length / shorter >= .9
      ? .8
      : overall;
}

/// Chart lines placed on [target] lines by word alignment, where exact
/// phrase placement found none. Line similarity is the share of words in
/// order (longest common subsequence); 80% is required. Lyric words the
/// chart never writes (ad-libs, backing vocals) are left out of the
/// comparison when most of a line's words remain.
///
/// First the chart and the lyrics are aligned line by line in order (a
/// sequence alignment), so a lyric repeated with different chords in
/// different sections takes the chords of its own section. A chart line may
/// cover two adjacent lyric lines, as charts that join short lines do. Lyric
/// lines left over (a chorus the chart writes once) then take the chords of
/// the single closest chart line; equally close chart lines with different
/// chords place nothing. A lyric line of fewer than three words takes part
/// only joined with the next line; chart lines of fewer than three words,
/// and lines whose offsets are not plain characters, are skipped.
Map<int, List<ChordAnchor>> _fuzzyLineChords(
  List<ArrangementLine> target,
  String chart,
) {
  bool plainText(String text) => text.characters.length == text.length;
  final parsedDonors = parseArrangement(chart);
  final wordCache = <String, _Words>{};
  _Words lineWords(String text) =>
      wordCache.putIfAbsent(text, () => _lineWords(text));
  final donors =
      <
        ({
          ArrangementLine line,
          _Words words,
          Map<int, int> trailingWordOverrides,
        })
      >[];
  final donorRanges = <(int, int)>[];
  for (var i = 0; i < parsedDonors.length; i++) {
    final line = parsedDonors[i];
    if (line.directive || line.chords.isEmpty || !plainText(line.text)) {
      continue;
    }
    final words = lineWords(line.text);
    if (words.length < 3 || words.length > 40) continue;
    donors.add((line: line, words: words, trailingWordOverrides: const {}));
    donorRanges.add((i, i + 1));
  }
  final eligibleTargets = <({int index, _Words words})>[];
  for (var i = 0; i < target.length; i++) {
    final line = target[i];
    if (line.directive || !plainText(line.text)) continue;
    final words = lineWords(line.text);
    if (words.isNotEmpty && words.length <= 40) {
      eligibleTargets.add((index: i, words: words));
    }
  }
  final targetLineCount = eligibleTargets.length;
  if (targetLineCount == 0) return const {};
  final donorLimit = 40000 ~/ targetLineCount;
  if (donors.length > donorLimit) return const {};
  final contextDonors =
      <
        ({
          ArrangementLine line,
          _Words words,
          Map<int, int> trailingWordOverrides,
        })
      >[];
  final contextRanges = <(int, int)>[];
  // Chord charts often split one lyric paragraph into several very short
  // rows. Compare bounded adjacent runs as one word stream, retaining each
  // chord's offset within that stream. Only short, chorded rows participate;
  // blank lines, directives, long rows, and non-plain grapheme offsets break
  // the context so unrelated sections cannot lend placement evidence.
  for (var start = 0; start < parsedDonors.length; start++) {
    final first = parsedDonors[start];
    if (first.directive ||
        first.chords.isEmpty ||
        !plainText(first.text) ||
        lineWords(first.text).length > 6 ||
        lineWords(first.text).isEmpty) {
      continue;
    }
    final text = StringBuffer();
    final chords = <ChordAnchor>[];
    var joinedLength = 0;
    var wordCount = 0;
    final internalTrailingWordOverrides = <int, int>{};
    var previousTrailingWordOverrides = <int, int>{};
    for (var end = start; end < parsedDonors.length && end < start + 8; end++) {
      final line = parsedDonors[end];
      final words = lineWords(line.text);
      if (line.directive ||
          line.chords.isEmpty ||
          !plainText(line.text) ||
          words.isEmpty ||
          words.length > 6) {
        break;
      }
      if (end > start) {
        text.write(' ');
        joinedLength++;
        internalTrailingWordOverrides.addAll(previousTrailingWordOverrides);
      }
      final lineStart = joinedLength;
      final firstWordIndex = wordCount;
      text.write(line.text);
      joinedLength += line.text.length;
      wordCount += words.length;
      chords.addAll(
        line.chords.map(
          (chord) => ChordAnchor(lineStart + chord.offset, chord.chord),
        ),
      );
      previousTrailingWordOverrides = {
        for (final chord in line.chords)
          if (chord.offset == line.text.length)
            lineStart + chord.offset: firstWordIndex + words.length - 1,
      };
      if (end > start && wordCount >= 3) {
        final combined = ArrangementLine(
          text.toString(),
          List.unmodifiable(chords),
        );
        contextDonors.add((
          line: combined,
          words: lineWords(combined.text),
          trailingWordOverrides: Map.unmodifiable(
            internalTrailingWordOverrides,
          ),
        ));
        contextRanges.add((start, end + 1));
      }
    }
  }
  // Keep context candidates from the whole chart when the DP work budget is
  // tight. Taking only the first candidates biases chord coverage toward the
  // start of a long song. The even sample preserves a spread across the full
  // source order while keeping donors × target lines within the old budget.
  final availableContexts = donorLimit - donors.length;
  if (contextDonors.length <= availableContexts) {
    donors.addAll(contextDonors);
    donorRanges.addAll(contextRanges);
  } else if (availableContexts > 0) {
    for (var i = 0; i < availableContexts; i++) {
      final index = ((i + .5) * contextDonors.length / availableContexts)
          .floor();
      donors.add(contextDonors[index]);
      donorRanges.add(contextRanges[index]);
    }
  }
  final donorOrder = [for (var i = 0; i < donors.length; i++) i]
    ..sort((a, b) {
      final byStart = donorRanges[a].$1.compareTo(donorRanges[b].$1);
      if (byStart != 0) return byStart;
      final byEnd = donorRanges[a].$2.compareTo(donorRanges[b].$2);
      return byEnd != 0 ? byEnd : a.compareTo(b);
    });
  final orderedDonors = [for (final i in donorOrder) donors[i]];
  final orderedRanges = [for (final i in donorOrder) donorRanges[i]];
  donors
    ..clear()
    ..addAll(orderedDonors);
  donorRanges
    ..clear()
    ..addAll(orderedRanges);
  final vocabulary = {
    for (final donor in donors)
      for (final word in donor.words) word.word,
  };
  _Words known(_Words words) {
    // Interjections the chart never writes ("doo doo", "oh") always go.
    final sung = [
      for (final word in words)
        if (vocabulary.contains(word.word) ||
            !_interjections.contains(word.word))
          word,
    ];
    final kept = [
      for (final word in sung)
        if (vocabulary.contains(word.word)) word,
    ];
    if (kept.length >= 3 && kept.length >= words.length * .6) return kept;
    return sung.length >= 3 ? sung : words;
  }

  // Lines of one or two words take part only joined with the next line.
  final lyrics = [
    for (final target in eligibleTargets)
      (index: target.index, words: known(target.words)),
  ];
  if (donors.isEmpty ||
      lyrics.isEmpty ||
      donors.length * lyrics.length > 40000) {
    return const {};
  }
  // A context can span up to three adjacent target lines.
  bool joinable(int l, int span) =>
      l + span <= lyrics.length &&
      List.generate(
        span - 1,
        (i) => i,
      ).every((i) => lyrics[l + i + 1].index == lyrics[l + i].index + 1);
  _Words wordsOf(int l, int span) => [
    for (var i = 0; i < span; i++) ...lyrics[l + i].words,
  ];
  final pairsOf = <(int, int, int), List<(int, int)>>{};
  List<(int, int)> pairs(int d, int l, int span) => pairsOf.putIfAbsent((
    d,
    l,
    span,
  ), () => _alignWords(donors[d].words, wordsOf(l, span)));
  double similarity(int d, int l, [int span = 1]) {
    if (span > 1 && !joinable(l, span)) return 0;
    if (wordsOf(l, span).length < 3) return 0;
    final value = _lineSimilarity(
      donors[d].words,
      wordsOf(l, span),
      pairs(d, l, span),
    );
    return value >= .8 ? value : 0;
  }

  // A containment match (most of one line inside a longer one) is weaker:
  // it needs anchors like an ambiguous line and never fills leftovers.
  bool contained(int d, int l, [int span = 1]) {
    final words = wordsOf(l, span).length;
    final longer = donors[d].words.length > words
        ? donors[d].words.length
        : words;
    return pairs(d, l, span).length / longer < .8;
  }

  // Ordered alignment: maximise the summed similarity of matched lyric
  // lines. Joining two lines counts for both, but only when it fits better
  // than either line alone and is not a containment match.
  final rows = donors.length, columns = lyrics.length;
  double joined(int d, int l, int span) {
    final value = similarity(d, l, span);
    if (span < 2 || value == 0 || contained(d, l, span)) return 0;
    for (var part = 0; part < span; part++) {
      if (value <= similarity(d, l + part)) return 0;
    }
    return value;
  }

  final score = List.generate(rows + 1, (_) => List.filled(columns + 2, 0.0));
  for (var d = rows - 1; d >= 0; d--) {
    for (var l = columns - 1; l >= 0; l--) {
      final match = similarity(d, l);
      var best = score[d + 1][l] > score[d][l + 1]
          ? score[d + 1][l]
          : score[d][l + 1];
      if (match > 0 && match + score[d + 1][l + 1] > best) {
        best = match + score[d + 1][l + 1];
      }
      for (var span = 2; span <= 3 && l + span <= columns; span++) {
        final context = joined(d, l, span);
        if (context > 0 && span * context + score[d + 1][l + span] > best) {
          best = span * context + score[d + 1][l + span];
        }
      }
      score[d][l] = best;
    }
  }
  // Chart text written more than once with different chords is ambiguous;
  // order may resolve it only between unambiguous matches on both sides.
  final signatures = <String, Set<String>>{};
  for (final donor in donors) {
    signatures
        .putIfAbsent(_repeatKey(donor.line.text), () => {})
        .add(_chordSignature(donor.line));
  }
  bool ambiguousDonor(int d) =>
      signatures[_repeatKey(donors[d].line.text)]!.length > 1;
  var matched = <(int, int, int)>[];
  // The same lyric text left uncovered elsewhere makes the place where a
  // match lands as arbitrary as an ambiguous chart line.
  final covered = <int>{};
  String textOf(int l, int span) =>
      wordsOf(l, span).map((word) => word.word).join(' ');
  bool repeatedElsewhere(int l, int span) {
    final text = textOf(l, span);
    for (var other = 0; other < columns; other++) {
      if (other == l ||
          !joinable(other, span) ||
          List.generate(
            span,
            (i) => i,
          ).any((i) => covered.contains(other + i))) {
        continue;
      }
      if (textOf(other, span) == text) return true;
    }
    return false;
  }

  bool weak((int, int, int) match) =>
      ambiguousDonor(match.$1) ||
      contained(match.$1, match.$2, match.$3) ||
      repeatedElsewhere(match.$2, match.$3);
  var d = 0, l = 0;
  while (d < rows && l < columns) {
    final match = similarity(d, l);
    var span = 1;
    var contextScore = match > 0 ? match + score[d + 1][l + 1] : -1.0;
    for (
      var candidateSpan = 2;
      candidateSpan <= 3 && l + candidateSpan <= columns;
      candidateSpan++
    ) {
      final candidate = joined(d, l, candidateSpan);
      final candidateScore =
          candidateSpan * candidate + score[d + 1][l + candidateSpan];
      if (candidate > 0 && candidateScore > contextScore) {
        span = candidateSpan;
        contextScore = candidateScore;
      }
    }
    if (span > 1 && score[d][l] == contextScore) {
      matched.add((d, l, span));
      d++;
      l += span;
    } else if (match > 0 && score[d][l] == contextScore) {
      matched.add((d, l, 1));
      d++;
      l++;
    } else if (score[d + 1][l] >= score[d][l + 1]) {
      d++;
    } else {
      l++;
    }
  }
  // Original chart rows and their combined contexts can describe the same
  // source passage. Keep ownership of each source interval with one match so
  // an overlapping virtual row cannot lend the same chord evidence twice.
  final owned = <(int, int, int)>[];
  for (final match in matched) {
    final range = donorRanges[match.$1];
    final overlap = owned.where((other) {
      final prior = donorRanges[other.$1];
      return range.$1 < prior.$2 && prior.$1 < range.$2;
    }).toList();
    if (overlap.isEmpty) {
      owned.add(match);
      continue;
    }
    double scoreFor((int, int, int) value) =>
        similarity(value.$1, value.$2, value.$3);
    final best = overlap
        .map(scoreFor)
        .fold(scoreFor(match), (a, b) => a > b ? a : b);
    if (scoreFor(match) != best) continue;
    if (overlap.any((other) => scoreFor(other) == best)) {
      owned.removeWhere(overlap.contains);
      continue;
    }
    owned.removeWhere(overlap.contains);
    owned.add(match);
  }
  matched = owned;
  matched.sort((a, b) {
    final source = donorRanges[a.$1].$1.compareTo(donorRanges[b.$1].$1);
    return source != 0 ? source : a.$2.compareTo(b.$2);
  });
  for (final (_, l, span) in matched) {
    covered.addAll(List.generate(span, (i) => l + i));
  }
  final result = <int, List<ChordAnchor>>{};
  void place(int d, int l, int span) {
    final words = wordsOf(l, span);
    final boundaries = <int>[];
    var count = 0;
    for (var part = 0; part < span; part++) {
      count += lyrics[l + part].words.length;
      boundaries.add(count);
    }
    for (final (word, inWord, chord) in _mapChordWords(
      donors[d].line,
      donors[d].words,
      words,
      pairs(d, l, span),
      trailingWordOverrides: donors[d].trailingWordOverrides,
    )) {
      // Chords after the last word stay at the end of the last line.
      final localWord = word ?? words.length - 1;
      var part = boundaries.indexWhere((boundary) => localWord < boundary);
      if (part < 0) part = span - 1;
      final priorBoundary = part == 0 ? 0 : boundaries[part - 1];
      final line = lyrics[l + part].index;
      final offset = word == null
          ? target[line].text.length
          : lyrics[l + part].words[word - priorBoundary].start + inWord;
      result.putIfAbsent(line, () => []).add(ChordAnchor(offset, chord));
    }
  }

  final abstainedLyrics = <int>{};
  for (var m = 0; m < matched.length; m++) {
    final (d, l, span) = matched[m];
    // Another chart line between the neighbouring matches that fits this
    // lyric equally well with different chords makes the choice arbitrary.
    final low = m == 0 ? 0 : matched[m - 1].$1 + 1;
    final high = m + 1 == matched.length ? rows : matched[m + 1].$1;
    final value = similarity(d, l, span);
    var tied = false;
    for (var other = low; other < high && !tied; other++) {
      tied =
          other != d &&
          similarity(other, l, span) == value &&
          _chordSignature(donors[other].line) !=
              _chordSignature(donors[d].line);
    }
    if (tied) {
      abstainedLyrics.addAll(List.generate(span, (i) => lyrics[l + i].index));
      continue;
    }
    if (weak((d, l, span)) &&
        (!matched.take(m).any((match) => !weak(match)) ||
            !matched.skip(m + 1).any((match) => !weak(match)))) {
      abstainedLyrics.addAll(List.generate(span, (i) => lyrics[l + i].index));
      continue;
    }
    place(d, l, span);
  }
  // Leftover lyric lines: the single closest chart line, if unambiguous.
  // A source interval selected by the ordered alignment is never recycled for
  // a leftover line, even when placement abstains because that match is weak
  // or ambiguous. Otherwise one chord phrase could be reused elsewhere.
  final placedRanges = <(int, int)>[
    for (final (d, _, _) in matched) donorRanges[d],
  ];
  for (var l = 0; l < columns; l++) {
    if (result.containsKey(lyrics[l].index) ||
        abstainedLyrics.contains(lyrics[l].index)) {
      continue;
    }
    var best = -1;
    var bestScore = 0.0;
    var ambiguous = false;
    for (var d = 0; d < rows; d++) {
      final range = donorRanges[d];
      if (placedRanges.any(
        (used) => range.$1 < used.$2 && used.$1 < range.$2,
      )) {
        continue;
      }
      final value = similarity(d, l);
      if (value == 0 || contained(d, l)) continue;
      if (value > bestScore) {
        best = d;
        bestScore = value;
        ambiguous = false;
      } else if (value == bestScore &&
          _chordSignature(donors[d].line) !=
              _chordSignature(donors[best].line)) {
        ambiguous = true;
      }
    }
    if (best < 0 || ambiguous) continue;
    place(best, l, 1);
    placedRanges.add(donorRanges[best]);
  }
  result.removeWhere((_, anchors) => anchors.isEmpty);
  return result;
}

/// Index pairs of the longest common subsequence of two word lists.
List<(int, int)> _alignWords(
  List<({String word, int start, int end})> a,
  List<({String word, int start, int end})> b,
) {
  final table = List.generate(
    a.length + 1,
    (_) => List.filled(b.length + 1, 0),
  );
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = b.length - 1; j >= 0; j--) {
      table[i][j] = a[i].word == b[j].word
          ? table[i + 1][j + 1] + 1
          : (table[i + 1][j] > table[i][j + 1]
                ? table[i + 1][j]
                : table[i][j + 1]);
    }
  }
  final pairs = <(int, int)>[];
  var i = 0, j = 0;
  while (i < a.length && j < b.length) {
    if (a[i].word == b[j].word) {
      pairs.add((i, j));
      i++;
      j++;
    } else if (table[i + 1][j] >= table[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return pairs;
}

final _bracketed = RegExp(r'\([^()]*\)|\[[^\[\]]*\]');

/// A lyric line's words outside brackets, for finding repeats of a line.
String _repeatKey(String text) => _norm(text.replaceAll(_bracketed, ' '));

/// [chords] placed on [from] moved to the same words of [to], whose words
/// outside brackets are the same. Null when a chord cannot be placed.
List<ChordAnchor>? _retargetChords(
  String from,
  String to,
  List<ChordAnchor> chords,
) {
  List<({int start, int end})> words(String text) {
    final masked = text.replaceAllMapped(
      _bracketed,
      (match) => ' ' * match[0]!.length,
    );
    return [
      for (final match in RegExp(r'\S+').allMatches(masked))
        (start: match.start, end: match.end),
    ];
  }

  final source = words(from), target = words(to);
  if (source.isEmpty || source.length != target.length) return null;
  final fromCharacters = from.characters.length == from.length;
  final toCharacters = to.characters.length == to.length;
  // Offsets count grapheme clusters; only plain lines map one to one.
  if (!fromCharacters || !toCharacters) return null;
  final moved = <ChordAnchor>[];
  for (final chord in chords) {
    var index = source.indexWhere((word) => chord.offset < word.end);
    if (index < 0) {
      moved.add(ChordAnchor(to.length, chord.chord));
      continue;
    }
    final inWord = (chord.offset - source[index].start).clamp(
      0,
      target[index].end - target[index].start,
    );
    moved.add(ChordAnchor(target[index].start + inWord, chord.chord));
  }
  return moved;
}

/// Exact whole-line contexts for charts whose rows subdivide lyric paragraphs.
/// Complete contexts provide exact evidence independently of fuzzy alignment.
/// Source intervals may support repeated identical contexts, but cannot lend
/// overlapping evidence to different contexts. Conflicting occurrences abstain.
Map<int, List<ChordAnchor>> _exactContextChords(
  List<ArrangementLine> target,
  String chart,
) {
  if (chart.length > 200000 || target.length > 5000) return const {};
  final source = parseArrangement(chart);
  bool usable(ArrangementLine line) =>
      !line.directive &&
      sectionLabelForLine(line) == null &&
      line.text.length <= 2000 &&
      line.text.characters.length == line.text.length &&
      _lineWords(line.text).isNotEmpty;
  final groups =
      <
        String,
        ({
          List<(int, int, String)> anchors,
          String signature,
          List<(int, int)> ranges,
        })
      >{};
  final ambiguous = <String>{};
  var budget = 100000;
  for (var start = 0; start < source.length; start++) {
    final tokens = <String>[];
    final anchors = <(int, int, String)>[];
    for (var end = start; end < source.length && end < start + 8; end++) {
      final line = source[end];
      if (!usable(line)) break;
      final words = _lineWords(line.text);
      if (tokens.length + words.length > 80) break;
      budget -= words.length;
      if (budget < 0) return const {};
      for (final chord in line.chords) {
        final next = words.indexWhere((word) => chord.offset < word.end);
        final word = next < 0 ? words.length - 1 : next;
        final inside = next < 0
            ? words[word].end - words[word].start
            : (chord.offset - words[word].start).clamp(
                0,
                words[word].end - words[word].start,
              );
        anchors.add((tokens.length + word, inside, chord.chord));
      }
      tokens.addAll(words.map((word) => word.word));
      if (end == start ||
          tokens.length < 12 ||
          tokens.toSet().length < 6 ||
          anchors.isEmpty) {
        continue;
      }
      final key = tokens.join(' ');
      final signature = jsonEncode(
        anchors.map((a) => [a.$1, a.$2, a.$3]).toList(),
      );
      final prior = groups[key];
      if (prior != null) {
        if (prior.signature != signature) ambiguous.add(key);
        prior.ranges.add((start, end + 1));
      } else {
        groups[key] = (
          anchors: List.of(anchors),
          signature: signature,
          ranges: [(start, end + 1)],
        );
      }
    }
  }
  final matches =
      <
        ({
          String key,
          int start,
          int end,
          List<({int line, int start, int end})> words,
        })
      >[];
  for (var start = 0; start < target.length; start++) {
    final tokens = <String>[];
    final locations = <({int line, int start, int end})>[];
    for (var end = start; end < target.length && end < start + 3; end++) {
      if (!usable(target[end])) break;
      final words = _lineWords(target[end].text);
      if (tokens.length + words.length > 80) break;
      budget -= words.length;
      if (budget < 0) return const {};
      tokens.addAll(words.map((word) => word.word));
      locations.addAll(
        words.map((word) => (line: end, start: word.start, end: word.end)),
      );
      final key = tokens.join(' ');
      if (groups.containsKey(key) && !ambiguous.contains(key)) {
        matches.add((
          key: key,
          start: start,
          end: end + 1,
          words: List.of(locations),
        ));
      }
    }
  }
  matches.sort((a, b) {
    final length = b.words.length.compareTo(a.words.length);
    return length != 0 ? length : a.start.compareTo(b.start);
  });
  final claimedLines = <int>{};
  final used = <({int start, int end, String key})>[];
  final result = <int, List<ChordAnchor>>{};
  for (final match in matches) {
    if (List.generate(
      match.end - match.start,
      (i) => match.start + i,
    ).any(claimedLines.contains)) {
      continue;
    }
    final group = groups[match.key]!;
    final available = group.ranges.where(
      (range) => !used.any(
        (prior) =>
            prior.key != match.key &&
            range.$1 < prior.end &&
            prior.start < range.$2,
      ),
    );
    if (available.isEmpty) continue;
    final mapped = <int, List<ChordAnchor>>{};
    var conflict = false;
    for (final (word, inside, chord) in group.anchors) {
      final location = match.words[word];
      final offset =
          location.start + inside.clamp(0, location.end - location.start);
      final line = mapped.putIfAbsent(location.line, () => []);
      if (line.any(
        (anchor) => anchor.offset == offset && anchor.chord != chord,
      )) {
        conflict = true;
        break;
      }
      if (!line.any(
        (anchor) => anchor.offset == offset && anchor.chord == chord,
      )) {
        line.add(ChordAnchor(offset, chord));
      }
    }
    if (conflict) continue;
    result.addAll(mapped);
    claimedLines.addAll(
      List.generate(match.end - match.start, (i) => match.start + i),
    );
    final range = available.first;
    used.add((start: range.$1, end: range.$2, key: match.key));
  }
  return result;
}

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
}) {
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
    final fuzzy = _fuzzyLineChords(plain, donorBody);
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

SongDocument combineSources(
  SongCandidate selected,
  List<SourceResult> results, {
  String? preferredSourceId,
  bool allowRejectedPreferredSource = false,
  List<HistoricalCacheUse> historicalCacheUses = const [],
}) {
  final inputSources = List<SourceResult>.of(results);
  results = _retainedSourceEvidence(selected, results);
  results = [...results, ..._recordingArrangementViews(selected, results)];
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
          recordingCompatible(selected, source) &&
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
            recordingCompatible(selected, source) &&
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
      for (final id in reference.recordingIds.entries) {
        if (source.candidate.recordingIds.containsKey(id.key) &&
            source.candidate.recordingIds[id.key] != id.value) {
          return false;
        }
      }
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
      !selected.recordingIds.entries.any(
        (entry) =>
            source.candidate.recordingIds.containsKey(entry.key) &&
            source.candidate.recordingIds[entry.key] != entry.value,
      ) &&
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
            recordingCompatible(selected, reference) &&
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
            .where((source) => recordingCompatible(selected, source))
            .toList()
      : <SourceResult>[];
  final referencePool = resolvedLyricAnchors.isEmpty
      ? accepted
      : resolvedLyricAnchors;
  final references =
      referencePool
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
  final rankedEligible = [...eligible];
  final evidencePlan = _rankSourceCombination(
    selected,
    results,
    lyricSourceIds: eligible.map((s) => s.id).toSet(),
    chartSourceIds: matching
        .where((s) => s.hasChords && materialSource(s))
        .map((s) => s.id)
        .toSet(),
    factSourceIds: matching.map((s) => s.id).toSet(),
    metadataContextMatches: metadataContextMatches,
    preferredSourceId: preferredSourceId,
  );
  final lyricScores = <String, int>{};
  final chordScores = <String, int>{};
  for (final item in evidencePlan.claims) {
    if (item.claim.field == 'lyrics') {
      lyricScores.update(
        item.claim.sourceId,
        (n) => math.max(n, item.score),
        ifAbsent: () => item.score,
      );
    }
    if (item.claim.field == 'chords') {
      chordScores.update(
        item.claim.sourceId,
        (n) => math.max(n, item.score),
        ifAbsent: () => item.score,
      );
    }
  }
  final selectedLyrics = evidencePlan.chosenByField['lyrics'];
  rankedEligible.sort((a, b) {
    final chosen = (b.id == selectedLyrics?.sourceId ? 1 : 0).compareTo(
      a.id == selectedLyrics?.sourceId ? 1 : 0,
    );
    if (chosen != 0) return chosen;
    final score = (lyricScores[b.id] ?? 0).compareTo(lyricScores[a.id] ?? 0);
    return score != 0 ? score : a.id.compareTo(b.id);
  });
  final preferred = eligible.where((s) => s.id == preferredSourceId);
  if (preferredSourceId != null && preferred.isEmpty) {
    throw const FormatException(
      'The selected source does not contain a complete matching arrangement.',
    );
  }
  final best = preferred.isEmpty ? rankedEligible.first : preferred.first;
  final selectedChart = evidencePlan.chosenByField['chords'];
  final chartWinner = matching
      .where((s) => s.id == selectedChart?.sourceId && s.hasChords)
      .firstOrNull;
  if (chartWinner != null) {
    chordScores[chartWinner.id] = (chordScores[chartWinner.id] ?? 0) + 10000;
  }
  final keepBaseChords =
      preferredSourceId != null ||
      best.hasChords && (chartWinner == null || chartWinner.id == best.id);
  final initialBody = keepBaseChords
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
  if (!best.hasChords && !accepted.any((source) => source.hasChords)) {
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
  }..removeWhere((key, _) => key == rowAlbumKey || key == rowDurationKey);
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
  final sourcesById = {for (final source in matching) source.id: source};
  final arrangementSourceIds = <String>{best.id};
  for (final sourceId in chordSourceIds) {
    final source = sourcesById[sourceId];
    // A chart whose chords were moved into the main chart's shapes no longer
    // has its own key or capo.
    if (source != null &&
        !merged.movedIds.contains(sourceId) &&
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
  final remaining = matching.where((s) => s.id != best.id).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  // Catalogs list one release with slightly different durations, and other
  // masters or edits under the same album name. Lend a display duration only
  // from the one group of agreeing durations (within three seconds) that more
  // album-matching sources support than any other.
  final displayAlbum =
      metadata['album'] ??
      [best, ...remaining]
          .where((source) => recordingCompatible(selected, source))
          .map((source) => source.candidate.album ?? source.metadata['album'])
          .whereType<String>()
          .firstOrNull;
  final displayDurations = _majorityDurationRange([
    if (displayAlbum is String && selected.recordingIds.isEmpty)
      for (final source in remaining)
        if (_lendsAlbumDisplay(selected, source, displayAlbum))
          ?_sourceDuration(source),
  ]);
  for (final source
      in preferredSourceId == null
          ? const <SourceResult>[]
          : [best, ...remaining]) {
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
    // A transposed chart's chords were moved into the majority key (its capo
    // still applies); keep its declared key only where it fits them. Without
    // such a correction, a chord chart whose declared key contradicts its
    // own chords cannot name the combined key.
    final keyShift = source.extra['keyShift'];
    final declared = facts['key'];
    if (preferredSourceId == null && keyShift is int && keyShift % 12 != 0) {
      final kept = declaredKeyAfterShift(
        source.body,
        declared is String ? declared : null,
        facts['capo'],
        keyShift,
      );
      if (kept == null) {
        facts.remove('key');
      } else {
        facts['key'] = kept;
      }
    } else if (preferredSourceId == null &&
        source.hasChords &&
        declared is String &&
        declared.trim().isNotEmpty &&
        !declaredKeyFitsChords(source.body, declared.trim(), facts['capo'])) {
      facts.remove('key');
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
  metadata.removeWhere((key, _) => key == rowAlbumKey || key == rowDurationKey);
  for (final (field, value) in [
    ('album', selected.metadata[rowAlbumKey]),
    ('durationSeconds', _validDuration(selected.metadata[rowDurationKey])),
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
        for (final entry in evidencePlan.chosenByField.entries)
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
  } else {
    song.extra['evidenceRanking'] = {
      'version': 1,
      ...evidencePlan.toJson(),
      'selectionMode': 'explicitSource',
    };
  }
  return enrichCombinedDisplayMetadata(
    song,
    isSameRecording: recordingCompatible,
  );
}

bool _hasMetadata(Object? value) =>
    value != null &&
    (value is! String || value.trim().isNotEmpty) &&
    (value is! Iterable || value.isNotEmpty) &&
    (value is! Map || value.isNotEmpty);

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
        if (seen.add(jsonEncode(value))) value,
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

/// Resolve every payload already returned by discovery without another fetch.
/// The original envelope remains intact, including failed search observations.
List<SourceResult> _sourceDocuments(
  List<SourceResult> input,
  List<SourceResult> observations,
) {
  final documents = <String, SourceResult>{};
  final snapshots = <String, List<JsonMap>>{};
  for (final source in input) {
    documents[source.id] = source;
    snapshots.putIfAbsent(source.id, () => []).add(source.toJson());
  }
  for (final source in observations) {
    if (source.extra['searchEvidenceOnly'] == true) continue;
    documents.putIfAbsent(source.id, () => source);
  }
  for (final entry in snapshots.entries) {
    if (entry.value.length < 2) continue;
    final source = documents[entry.key]!;
    documents[entry.key] = source.copyWith(
      extra: {...source.extra, 'sourceEvidenceSnapshots': entry.value},
    );
  }
  return documents.values.toList();
}

List<SourceResult> _retainedSourceEvidence(
  SongCandidate selected,
  List<SourceResult> input,
) {
  final result = <SourceResult>[];
  final seen = <String>{};
  final currentById = {for (final source in input) source.id: source};
  String fingerprint(SourceResult source, {bool payloadOnly = false}) {
    final values = {...source.toJson()};
    if (payloadOnly) {
      values.remove('discoveryEvidence');
      values.remove('providerAlternatives');
    }
    try {
      return jsonEncode(values);
    } on Object {
      return values.toString();
    }
  }

  void add(SourceResult source, {bool snapshot = false}) {
    if (snapshot &&
        result.any(
          (existing) =>
              fingerprint(existing, payloadOnly: true) ==
              fingerprint(source, payloadOnly: true),
        )) {
      return;
    }
    final current = currentById[source.id];
    if (source.arrangementId == null &&
        current != null &&
        source.body.trim().isNotEmpty &&
        source.body != current.body) {
      final viewId =
          'snapshot-${_bodyHash(jsonEncode({
            'body': source.body,
            'metadata': {...source.candidate.metadata, ...source.metadata},
          })).substring(0, 16)}';
      source = SourceResult(
        candidate: source.candidate,
        body: source.body,
        metadata: source.metadata,
        timingTracks: source.timingTracks,
        matchKind: source.matchKind,
        attribution: source.attribution,
        matchReason: source.matchReason,
        retrievedAt: source.retrievedAt,
        arrangementId: viewId,
        extra: {
          ...source.extra,
          'parentSourceId': source.id,
          'parentCandidate': source.candidate.toJson(),
          'retainedPayloadView': true,
        },
      );
    }
    if (seen.add(fingerprint(source))) result.add(source);
  }

  void payload(Object? raw, {String? rejectedReason}) {
    if (raw is! Map || raw['candidate'] is! Map) return;
    try {
      final data = jsonMap(raw);
      final candidate = SongCandidate.fromJson(jsonMap(data['candidate']));
      final arrangementId = data['arrangementId'];
      final observedId = arrangementId is String
          ? '${candidate.identity}#arrangement=$arrangementId'
          : candidate.identity;
      final current = currentById[observedId];
      if (current != null) {
        // Discovery snapshots precede chart corroboration. Apply the current
        // derived context to every view of this ID; retain published/raw facts.
        for (final key in const [
          'keyConsensus',
          'keyShift',
          'keyEstimate',
          'keyRecording',
          'pendingMatchCheck',
          'requiresLyricsAgreement',
          'requiresRecordingLyricsAgreement',
          'alternatePerformerChart',
          'lyricRepresentation',
          'lyricRepresentationEvidence',
          'partialLyricSupport',
        ]) {
          data.remove(key);
          if (current.extra.containsKey(key)) data[key] = current.extra[key];
        }
      }
      // A terminal rejection supersedes an earlier tentative acceptance of
      // this same source. The original observation stays in its envelope.
      final currentRejection = current?.matchKind == MatchKind.rejected;
      add(
        SourceResult.fromJson({
          ...data,
          if (rejectedReason != null) 'matchKind': MatchKind.rejected.name,
          'matchReason': ?rejectedReason,
          if (currentRejection) 'matchKind': MatchKind.rejected.name,
          if (currentRejection) 'matchReason': current!.matchReason,
          if (current?.hasPendingMatchCheck == true) 'pendingMatchCheck': true,
        }),
        snapshot: true,
      );
    } on Object {
      // Malformed envelopes remain preserved on the original source. They
      // cannot safely become a resolved source document.
    }
  }

  // Canonical resolved results must precede every discovery observation. An
  // earlier provider envelope can mention a later result's ID; that preview
  // must not supply the body or setup used to check the resolved chart.
  for (final source in currentById.values) {
    add(source);
  }
  for (final source in input) {
    add(source);
  }
  for (final source in input) {
    final envelope = jsonMap(source.extra['discoveryEvidence']);
    for (final raw
        in source.extra['sourceEvidenceSnapshots'] as List? ?? const []) {
      payload(raw);
    }
    for (final raw in envelope['acceptedPayloads'] as List? ?? const []) {
      payload(raw);
    }
    for (final raw in envelope['rejectedPayloads'] as List? ?? const []) {
      final entry = jsonMap(raw);
      payload(entry['payload'], rejectedReason: entry['reason'] as String?);
    }
    for (final raw
        in source.extra['providerAlternatives'] as List? ?? const []) {
      payload(raw);
    }
    for (final raw in envelope['searchCandidates'] as List? ?? const []) {
      final candidate = jsonMap(jsonMap(raw)['candidate']);
      if (candidate.isEmpty) continue;
      try {
        final observation = SongCandidate.fromJson(candidate);
        final chartProvider =
            source.hasChords ||
            (envelope['capabilities'] is List &&
                (envelope['capabilities'] as List).contains('chords'));
        add(
          SourceResult(
            candidate: observation,
            body: '',
            matchKind: MatchKind.unverified,
            extra: {
              'searchEvidenceOnly': true,
              'discoveredBy': source.id,
              'searchArrangementMatch':
                  chartProvider &&
                  observation.providerId == source.candidate.providerId &&
                  _sameArrangedSong(selected, observation),
            },
          ),
        );
      } on Object {
        // The unparsed search observation is still in its discovery envelope.
      }
    }
  }
  final interpreted = <SourceResult>[];
  final viewsById = <String, SourceResult>{};
  for (final source in result) {
    if (source.arrangementId != null &&
        source.extra['retainedPayloadView'] != true) {
      viewsById.putIfAbsent(source.id, () => source);
      continue;
    }
    final views = splitChartArrangements(source);
    if (views.isEmpty) {
      interpreted.add(source);
      continue;
    }
    interpreted.add(
      source.copyWith(
        extra: {
          ...source.extra,
          'hasArrangementViews': true,
          'arrangementViewIds': views.map((view) => view.id).toList(),
        },
      ),
    );
    for (final view in views) {
      viewsById.putIfAbsent(view.id, () => view);
    }
  }
  return [...interpreted, ...viewsById.values];
}

const _rankedArrangementFields = {
  'key',
  'capo',
  'tuning',
  'tempo',
  'timeSignature',
  'difficulty',
  'arrangement',
};
const _rankedRecordingFields = {
  'album',
  'artworkUrl',
  'duration',
  'durationSeconds',
  'mediaLinks',
  'recording',
  'releaseDate',
  'releaseDateDisplay',
  'recordingLocation',
  'recordingId',
  'recordingIds',
  'isrc',
  'isrcs',
  'musicbrainzRecordingId',
  'musicbrainzReleaseId',
  'relationships',
  'year',
};
const _rankedControlFields = {
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
  'evidenceOrigin',
  'sourceOrigin',
  'lineageId',
  'sourceLineageId',
  'providerLineage',
};

Iterable<JsonMap> _recordingAnalyses(SourceResult source) sync* {
  final primary = jsonMap(source.extra['keyRecording']);
  if (primary.isEmpty) return;
  yield primary;
  for (final raw
      in primary['alternatives'] is List
          ? primary['alternatives'] as List
          : const []) {
    if (raw is! Map) continue;
    yield {
      ...jsonMap(raw),
      for (final field in const [
        'recordingScope',
        'selectedIdentity',
        'identifierSourceIds',
        'identifierProviders',
      ])
        if (primary.containsKey(field)) field: primary[field],
    };
  }
}

bool _recordingKeyBound(
  SongCandidate selected,
  List<SourceResult> sources,
  JsonMap recording,
) {
  if (recording['recordingScope'] == 'song') return false;
  final ids = (recording['ids'] as List? ?? const [])
      .whereType<String>()
      .toSet();
  if (ids.isEmpty) return false;
  if (recording['selectedIdentity'] == selected.identity) return true;
  final known = <String>{...selected.recordingIds.values};
  void addMetadata(JsonMap metadata) {
    if (metadata['isrc'] is String) known.add(metadata['isrc'] as String);
    if (metadata['isrcs'] is List) {
      known.addAll((metadata['isrcs'] as List).whereType<String>());
    }
    for (final raw
        in metadata['mediaLinks'] is List
            ? metadata['mediaLinks'] as List
            : const []) {
      final url = jsonMap(raw)['url'];
      final uri = url is String ? Uri.tryParse(url) : null;
      if (uri?.host == 'open.spotify.com' &&
          uri!.pathSegments.length >= 2 &&
          uri.pathSegments[uri.pathSegments.length - 2] == 'track') {
        known.add(uri.pathSegments.last);
      }
    }
  }

  addMetadata(selected.metadata);
  for (final source in sources.where(
    (source) => recordingCompatible(selected, source),
  )) {
    known.addAll(source.candidate.recordingIds.values);
    addMetadata(source.candidate.metadata);
    addMetadata(source.metadata);
  }
  return ids.any(known.contains);
}

/// Keep the published setup and offer a separately labelled playable setup
/// for a bound recording key. Only the capo changes; source text stays exact.
/// Conflicting recording signatures produce competing options, never a veto.
List<SourceResult> _recordingArrangementViews(
  SongCandidate selected,
  List<SourceResult> sources,
) {
  final targets = <String>[];
  for (final source in sources) {
    for (final recording in _recordingAnalyses(source)) {
      final key = recording['key'];
      if (key is String &&
          _keyIdentity(key) != null &&
          (_recordingKeyBound(selected, sources, recording) ||
              const {
                    MatchKind.sameSong,
                    MatchKind.sameRecording,
                  }.contains(source.matchKind) &&
                  _sameArrangedSong(selected, source.candidate))) {
        targets.add(key);
      }
    }
  }
  targets.sort();
  final signatures = <String>[];
  for (final target in targets) {
    if (!signatures.any((key) => _keyDistance(key, target) == 0)) {
      signatures.add(target);
    }
  }
  final views = <String, SourceResult>{};
  for (final target in signatures) {
    final bound = sources.any(
      (source) => _recordingAnalyses(source).any((recording) {
        final key = recording['key'];
        return key is String &&
            _keyDistance(key, target) == 0 &&
            _recordingKeyBound(selected, sources, recording);
      }),
    );
    for (final source in sources) {
      if (!source.hasChords ||
          source.extra['hasArrangementViews'] == true ||
          source.extra['recordingArrangement'] is Map ||
          source.extra['searchEvidenceOnly'] == true ||
          source.hasPendingMatchCheck ||
          !const {
            MatchKind.sameSong,
            MatchKind.sameRecording,
          }.contains(source.matchKind) ||
          !_sameArrangedSong(selected, source.candidate) ||
          !explicitEditionsCompatible(
            selected,
            source.candidate,
            metadata: source.metadata,
            extra: source.extra,
          ) ||
          source.extra['keyShift'] is int && source.extra['keyShift'] != 0) {
        continue;
      }
      // Published key declarations remain independent competitors. Derive a
      // setup only where the chart has no literal key to contradict or rewrite.
      if (_keyIdentity(_setupValue(source, selected, 'key')) != null) continue;
      final hypotheses = rankChordKeyCandidates(source.body);
      if (hypotheses.isEmpty) continue;
      final oldCapo = _capoOf(_setupValue(source, selected, 'capo'));
      final sounding = transposeChord(hypotheses.first.key, oldCapo);
      final shift = _keyDistance(sounding, target);
      if (shift == null ||
          shift == 0 ||
          _chartSupportsSoundingKey(source, selected, target)) {
        continue;
      }
      final newCapo = (oldCapo + shift) % 12;
      final descriptor = {
        'parentSourceId': source.id,
        'bodyHash': _bodyHash(source.body),
        'publishedCapo': oldCapo,
        'capo': newCapo,
        'recordingKey': target,
        'recordingScope': bound ? 'recording' : 'song',
        'basis': bound
            ? 'bound_recording_key_and_chart_harmony'
            : 'same_song_key_and_chart_harmony',
      };
      final id =
          'recording-${_bodyHash(jsonEncode(descriptor)).substring(0, 16)}';
      final view = SourceResult(
        candidate: SongCandidate.fromJson({
          ...source.candidate.toJson(),
          'metadata': {...source.candidate.metadata, 'capo': newCapo},
        }),
        body: source.body,
        metadata: {...source.metadata, 'capo': newCapo},
        matchKind: MatchKind.sameSong,
        matchReason: source.matchReason,
        attribution: source.attribution,
        retrievedAt: source.retrievedAt,
        arrangementId: id,
        extra: {
          for (final entry in source.extra.entries)
            if (!const {
              'discoveryEvidence',
              'providerAlternatives',
              'originalPayload',
              'sourceEvidenceSnapshots',
              'keyConsensus',
              'keyShift',
              'keyEstimate',
              'keyRecording',
            }.contains(entry.key))
              entry.key: entry.value,
          'parentSourceId': source.id,
          'parentCandidate': source.candidate.toJson(),
          'recordingArrangement': descriptor,
        },
      );
      views.putIfAbsent(view.id, () => view);
    }
  }
  return views.values.toList();
}

bool _chartSupportsSoundingKey(
  SourceResult source,
  SongCandidate selected,
  String key,
) {
  final body = _keyCorrectedBody(source);
  final capo = _capoOf(_setupValue(source, selected, 'capo'));
  final shape = transposeChord(key, (12 - capo) % 12);
  if (chartSupportsDeclaredTonic(body, shape)) return true;
  final estimate = estimateChordKey(body);
  if (estimate != null) {
    return _keyDistance(transposeChord(estimate.key, capo), key) == 0;
  }
  return rankChordKeyCandidates(
    body,
  ).take(3).any((candidate) => _keyDistance(candidate.key, shape) == 0);
}

double _lyricVocabularyCoverage(String reference, String candidate) {
  final words = _norm(
    plainLyrics(reference),
  ).split(' ').where((w) => w.isNotEmpty).toSet();
  if (words.isEmpty) return 0;
  final available = _norm(plainLyrics(candidate)).split(' ').toSet();
  return words.intersection(available).length / words.length;
}

String _withoutChordAnchors(String body) {
  final raw = body.split('\n');
  final lines = parseArrangement(body);
  return [
    for (var i = 0; i < lines.length; i++)
      lines[i].chords.isEmpty
          ? raw[i]
          : _escapeLiteralChordTokens(lines[i].text),
  ].join('\n');
}

EvidenceClaim _rebuildClaim(
  EvidenceClaim claim, {
  Object? value,
  EvidenceMatchQuality? matchQuality,
  EvidenceHarmonyFit? harmonyFit,
  EvidenceSourceScope? sourceScope,
  String? contextId,
  String? equivalenceKey,
  bool? contextCompatible,
  String? incompatibilityReason,
  Map<String, int>? qualitySignals,
}) => EvidenceClaim(
  field: claim.field,
  value: value ?? claim.value,
  sourceId: claim.sourceId,
  providerId: claim.providerId,
  lineageId: claim.lineageId,
  matchQuality: matchQuality ?? claim.matchQuality,
  sourceScope: sourceScope ?? claim.sourceScope,
  origin: claim.origin,
  harmonyFit: harmonyFit ?? claim.harmonyFit,
  contextId: contextId ?? claim.contextId,
  contextCompatible: contextCompatible ?? claim.contextCompatible,
  supportsCorroboration: claim.supportsCorroboration,
  incompatibilityReason: incompatibilityReason ?? claim.incompatibilityReason,
  equivalenceKey: equivalenceKey ?? claim.equivalenceKey,
  qualitySignals: qualitySignals ?? claim.qualitySignals,
);

EvidenceRanking _rankSourceCombination(
  SongCandidate selected,
  List<SourceResult> sources, {
  required Set<String> lyricSourceIds,
  required Set<String> chartSourceIds,
  required Set<String> factSourceIds,
  required bool Function(SourceResult) metadataContextMatches,
  String? preferredSourceId,
}) {
  final byId = <String, SourceResult>{};
  final ordered = [...sources]
    ..sort((a, b) {
      final match = a.matchKind.index.compareTo(b.matchKind.index);
      return match != 0
          ? match
          : _bodyHash(a.body).compareTo(_bodyHash(b.body));
    });
  for (final source in sources) {
    byId.putIfAbsent(source.id, () => source);
  }
  final lyrics = ordered
      .where(
        (s) => lyricSourceIds.contains(s.id) && plainLyrics(s.body).isNotEmpty,
      )
      .toList();
  final charts = ordered
      .where((s) => chartSourceIds.contains(s.id) && s.hasChords)
      .toList();
  final recordingEvidence =
      <({SourceResult source, JsonMap data, String key, bool bound})>[
        for (final source in sources)
          for (final analysis in _recordingAnalyses(source))
            if (analysis['key'] case final String key)
              if (_keyIdentity(key) != null)
                (
                  source: source,
                  data: analysis,
                  key: key,
                  bound: _recordingKeyBound(selected, sources, analysis),
                ),
      ];
  // All matching charts remain witnesses even when only one contributes
  // anchors to the saved body. Provider identity deduplicates copied versions.
  final chartKeyLeads = <({String key, String provider})>[
    for (final source in ordered)
      if (factSourceIds.contains(source.id) &&
          source.hasChords &&
          source.extra['hasArrangementViews'] != true &&
          source.extra['recordingArrangement'] is! Map &&
          !source.hasPendingMatchCheck)
        if (rankChordKeyCandidates(source.body).firstOrNull case final lead?)
          (
            key: transposeChord(
              lead.key,
              _capoOf(_setupValue(source, selected, 'capo')),
            ),
            provider: source.candidate.providerId,
          ),
  ];
  final references = [...lyrics]
    ..sort((a, b) {
      final recording = (recordingCompatible(selected, b) ? 1 : 0).compareTo(
        recordingCompatible(selected, a) ? 1 : 0,
      );
      return recording != 0
          ? recording
          : lyricLines(b.body).length.compareTo(lyricLines(a.body).length);
    });
  final reference = references.firstOrNull;
  final displayAlbum =
      selected.album ??
      selected.metadata['album'] ??
      references
          .where((source) => recordingCompatible(selected, source))
          .map((source) => source.metadata['album'] ?? source.candidate.album)
          .whereType<String>()
          .firstOrNull;
  final maximumWords = lyrics.fold<int>(
    1,
    (n, s) => math.max(n, _norm(plainLyrics(s.body)).split(' ').length),
  );
  bool compatible(SourceResult source, String field) {
    if (field == 'lyrics') {
      return lyricSourceIds.contains(source.id) &&
          (preferredSourceId == null || source.id == preferredSourceId);
    }
    if (field == 'chords') {
      return chartSourceIds.contains(source.id) &&
          (preferredSourceId == null || source.id == preferredSourceId);
    }
    if (!field.startsWith('metadata.')) return false;
    final top = field.substring(9).split('.').first;
    if (_rankedControlFields.contains(top)) return false;
    if (_rankedArrangementFields.contains(top) &&
        top != 'key' &&
        !chartSourceIds.contains(source.id) &&
        !lyricSourceIds.contains(source.id)) {
      return false;
    }
    if (source.id == selected.identity) return true;
    if (!factSourceIds.contains(source.id)) return false;
    if (!recordingCompatible(selected, source) &&
        metadataContextMatches(source)) {
      return top == 'artistCredits';
    }
    if (top == 'artistCredits' &&
        source.candidate.providerId == 'musicbrainz' &&
        !recordingCompatible(selected, source) &&
        !metadataContextMatches(source)) {
      return false;
    }
    final scope =
        source.metadata['identityScope'] ??
        source.candidate.metadata['identityScope'];
    if (scope == 'image') return false;
    final leaf = field.split('.').last.toLowerCase();
    if ((_rankedRecordingFields.contains(top) ||
            const {
              'isrc',
              'isrcs',
              'recordingid',
              'recordingids',
            }.contains(leaf)) &&
        !recordingCompatible(selected, source)) {
      return const {'duration', 'durationSeconds'}.contains(top) &&
          selected.recordingIds.isEmpty &&
          displayAlbum is String &&
          _lendsAlbumDisplay(selected, source, displayAlbum);
    }
    return true;
  }

  Map<String, int> quality(SourceResult source, String field) {
    if (field == 'metadata.key' && source.extra['searchEvidenceOnly'] == true) {
      final declared = _setupValue(source, selected, 'key');
      if (declared is String && _keyIdentity(declared) != null) {
        final supporting = chartKeyLeads
            .where((lead) => _keyDistance(lead.key, declared) == 0)
            .map((lead) => lead.provider)
            .toSet()
            .length;
        final contraryConsensus = chartKeyLeads.any(
          (lead) =>
              _keyDistance(lead.key, declared) != 0 &&
              chartKeyLeads
                      .where((other) => _keyDistance(other.key, lead.key) == 0)
                      .map((other) => other.provider)
                      .toSet()
                      .length >=
                  math.max(2, supporting + 1),
        );
        if (contraryConsensus) {
          return const {'unresolvedSearchVsChartConsensus': -8};
        }
      }
    }
    if (const {
      'metadata.duration',
      'metadata.durationSeconds',
    }.contains(field)) {
      final duration = _sourceDuration(source);
      if (duration == null) return const {};
      final peers = ordered
          .where(
            (other) =>
                compatible(other, field) &&
                _sourceDuration(other) != null &&
                (_sourceDuration(other)! - duration).abs() <= 3,
          )
          .map((other) => other.candidate.providerId)
          .toSet()
          .length;
      return {'durationAgreement': (peers - 1) * 6};
    }
    if (field == 'lyrics') {
      final count = _norm(plainLyrics(source.body)).split(' ').length;
      return {
        'completeness': (12 * count / maximumWords).round(),
        if (reference != null)
          'referenceAgreement':
              (12 * _lyricVocabularyCoverage(reference.body, source.body))
                  .round(),
      };
    }
    if (field == 'chords') {
      final peers = charts.where(
        (other) => _compatibleArrangementSetup(source, other, selected),
      );
      final peerText = peers
          .map((other) => ' ${_norm(plainLyrics(other.body))} ')
          .toList();
      final referenceLines = reference == null
          ? <String>[]
          : lyricLines(
              reference.body,
            ).map(_norm).where((line) => line.isNotEmpty).toList();
      final covered = referenceLines
          .where((line) => peerText.any((text) => text.contains(' $line ')))
          .length;
      return {
        if (reference != null)
          'phraseCoverage':
              (16 * _lyricVocabularyCoverage(reference.body, source.body))
                  .round(),
        'chartedLines': parseArrangement(
          source.body,
        ).where((line) => line.chords.isNotEmpty).length.clamp(0, 12),
        if (referenceLines.isNotEmpty)
          'compatibleChartCoverage': (16 * covered / referenceLines.length)
              .round(),
        if (source.extra['keyConsensus'] == true) 'sourceKeyAgreement': 6,
        if (source.extra['keyConsensus'] == false)
          'sourceKeyAgreement': source.extra['keyShift'] is int ? -6 : -12,
        if (source.extra['alternatePerformerChart'] == true)
          'alternatePerformerChart': -8,
        if (source.extra['alternatePerformerChart'] == true &&
            reference != null &&
            !contextualChartLyricsMatch(source.body, reference.body))
          'partialLyricSupport': -6,
        if (source.extra['recordingArrangement'] is Map)
          'derivedRecordingSetup':
              jsonMap(source.extra['recordingArrangement'])['recordingScope'] ==
                  'song'
              ? -10
              : -6,
        if (recordingEvidence.any((evidence) => evidence.bound))
          'recordingKeyAgreement':
              recordingEvidence
                  .where((evidence) => evidence.bound)
                  .any(
                    (evidence) => _chartSupportsSoundingKey(
                      source,
                      selected,
                      evidence.key,
                    ),
                  )
              ? 6
              : -8,
        if (!recordingEvidence.any((evidence) => evidence.bound) &&
            recordingEvidence.isNotEmpty)
          'songKeyAgreement':
              recordingEvidence.any(
                (evidence) =>
                    _chartSupportsSoundingKey(source, selected, evidence.key),
              )
              ? 4
              : -4,
      };
    }
    return const {};
  }

  EvidenceHarmonyFit chartFit(SourceResult chart, Object value) {
    if (value is! String || _keyIdentity(value) == null) {
      return EvidenceHarmonyFit.neutral;
    }
    final capo = _capoOf(_setupValue(chart, selected, 'capo'));
    final shapeKey = transposeChord(value, (12 - capo) % 12);
    if (chartSupportsDeclaredTonic(_keyCorrectedBody(chart), shapeKey)) {
      return EvidenceHarmonyFit.fitting;
    }
    if (estimateChordKey(_keyCorrectedBody(chart)) == null) {
      final hypotheses = rankChordKeyCandidates(_keyCorrectedBody(chart));
      final capo = _capoOf(_setupValue(chart, selected, 'capo'));
      return hypotheses
              .take(3)
              .any(
                (hypothesis) =>
                    _keyDistance(transposeChord(hypothesis.key, capo), value) ==
                    0,
              )
          ? EvidenceHarmonyFit.fitting
          : EvidenceHarmonyFit.neutral;
    }
    return declaredKeyFitsChords(
          _keyCorrectedBody(chart),
          value,
          _setupValue(chart, selected, 'capo'),
        )
        ? EvidenceHarmonyFit.fitting
        : EvidenceHarmonyFit.conflicting;
  }

  EvidenceHarmonyFit fit(SourceResult source, String field, Object value) {
    if (charts.isEmpty) return EvidenceHarmonyFit.neutral;
    // A declaration may fit one of several available arrangements. Judge it
    // against all of them; pair compatibility binds it to the chosen chart.
    final fits = charts.map((chart) => chartFit(chart, value)).toSet();
    if (fits.contains(EvidenceHarmonyFit.fitting)) {
      return EvidenceHarmonyFit.fitting;
    }
    return fits.length == 1 && fits.contains(EvidenceHarmonyFit.conflicting)
        ? EvidenceHarmonyFit.conflicting
        : EvidenceHarmonyFit.neutral;
  }

  final raw = collectSourceEvidence(
    selected,
    sources,
    compatible: compatible,
    sameRecording: (source) => recordingCompatible(selected, source),
    sourceOrigin: (source, field) =>
        field == 'metadata.capo' && source.extra['recordingArrangement'] is Map
        ? EvidenceOrigin.inferred
        : EvidenceOrigin.provider,
    qualitySignals: quality,
    keyFit: fit,
    preferredSourceId: preferredSourceId,
  );
  final claims = <EvidenceClaim>[
    for (final claim in raw)
      _rebuildClaim(
        claim,
        matchQuality: byId[claim.sourceId]?.hasPendingMatchCheck == true
            ? EvidenceMatchQuality.unverified
            : claim.field.startsWith('metadata.') &&
                  byId[claim.sourceId]?.extra['searchEvidenceOnly'] == true &&
                  factSourceIds.contains(claim.sourceId) &&
                  (_sameSong(selected, byId[claim.sourceId]!.candidate) ||
                      byId[claim.sourceId]?.extra['searchArrangementMatch'] ==
                          true)
            ? EvidenceMatchQuality.sameSong
            : byId[claim.sourceId]?.matchReason ==
                      'incomplete_or_different_lyrics' &&
                  claim.contextCompatible
            ? EvidenceMatchQuality.sameSong
            : null,
        contextId: const {'lyrics', 'chords'}.contains(claim.field)
            ? claim.sourceId
            : null,
        sourceScope:
            claim.field == 'metadata.key' &&
                claim.sourceScope == EvidenceSourceScope.unknown
            ? EvidenceSourceScope.arrangement
            : null,
        equivalenceKey: claim.field == 'metadata.key'
            ? _keyIdentity(claim.value)
            : null,
        contextCompatible:
            claim.value is num && !(claim.value as num).isFinite ||
                const {
                      'metadata.duration',
                      'metadata.durationSeconds',
                    }.contains(claim.field) &&
                    _validDuration(claim.value) == null
            ? false
            : null,
        incompatibilityReason:
            claim.value is num && !(claim.value as num).isFinite
            ? 'non_finite_numeric_claim'
            : const {
                    'metadata.duration',
                    'metadata.durationSeconds',
                  }.contains(claim.field) &&
                  _validDuration(claim.value) == null
            ? 'invalid_duration_claim'
            : null,
      ),
  ];
  // Keep the published declaration alongside its equivalent in the corrected
  // chart's context. Moving a chart must not leave its old key label active.
  for (var i = 0, count = claims.length; i < count; i++) {
    final claim = claims[i];
    if (claim.field != 'metadata.key' || claim.value is! String) continue;
    final source = byId[claim.sourceId];
    final shift = source?.extra['keyShift'];
    if (source == null || shift is! int || shift % 12 == 0) continue;
    final corrected = declaredKeyAfterShift(
      source.body,
      claim.value as String,
      _setupValue(source, selected, 'capo'),
      shift,
    );
    if (corrected == null || _keyIdentity(corrected) == claim.normalizedValue) {
      continue;
    }
    claims[i] = _rebuildClaim(
      claim,
      contextCompatible: false,
      incompatibilityReason: 'published_key_before_chart_transposition',
    );
    claims.add(
      _rebuildClaim(
        claim,
        value: corrected,
        equivalenceKey: _keyIdentity(corrected),
        harmonyFit: fit(source, claim.field, corrected),
      ),
    );
  }
  // Publishers use both shape-key and sounding-key labels on capo charts.
  // Retain the literal declaration and rank its arithmetic sounding reading
  // as another interpretation of that same source, never as another vote.
  for (var i = 0, count = claims.length; i < count; i++) {
    final claim = claims[i];
    if (claim.field != 'metadata.key' ||
        claim.value is! String ||
        !claim.contextCompatible) {
      continue;
    }
    final source = byId[claim.sourceId];
    if (source == null || !source.hasChords) continue;
    final capo = _capoOf(_setupValue(source, selected, 'capo'));
    if (capo == 0 || _keyIdentity(claim.value) == null) continue;
    final sounding = transposeChord(claim.value as String, capo);
    final lead = rankChordKeyCandidates(_keyCorrectedBody(source)).firstOrNull;
    final shapeSupport =
        lead != null && _keyIdentity(lead.key) == _keyIdentity(claim.value);
    claims.add(
      _rebuildClaim(
        claim,
        value: sounding,
        equivalenceKey: _keyIdentity(sounding),
        contextId: source.id,
        harmonyFit: fit(source, claim.field, sounding),
        qualitySignals: {
          ...claim.qualitySignals,
          'capoShapeInterpretation': shapeSupport ? 4 : -4,
        },
      ),
    );
  }
  // Inferred alternatives are kept separately from every provider declaration.
  // Ambiguity and section changes affect their rank, not their availability.
  for (final source in charts) {
    final measuredHint = jsonMap(source.extra['keyRecording'])['key'];
    final shapeHint =
        measuredHint is String && _keyIdentity(measuredHint) != null
        ? transposeChord(
            measuredHint,
            (12 - _capoOf(_setupValue(source, selected, 'capo'))) % 12,
          )
        : null;
    final hypotheses = rankChordKeyCandidates(
      _keyCorrectedBody(source),
      hint: shapeHint,
    );
    for (final hypothesis in hypotheses) {
      final key = transposeChord(
        hypothesis.key,
        _capoOf(_setupValue(source, selected, 'capo')),
      );
      claims.add(
        EvidenceClaim(
          field: 'metadata.key',
          value: key,
          sourceId: source.id,
          providerId: source.candidate.providerId,
          contextId: source.id,
          equivalenceKey: _keyIdentity(key),
          matchQuality: source.hasPendingMatchCheck
              ? EvidenceMatchQuality.unverified
              : switch (source.matchKind) {
                  MatchKind.sameRecording => EvidenceMatchQuality.sameRecording,
                  MatchKind.sameSong => EvidenceMatchQuality.sameSong,
                  MatchKind.rejected
                      when source.matchReason ==
                          'incomplete_or_different_lyrics' =>
                    EvidenceMatchQuality.sameSong,
                  _ => EvidenceMatchQuality.unverified,
                },
          sourceScope: EvidenceSourceScope.arrangement,
          origin: EvidenceOrigin.inferred,
          supportsCorroboration: hypothesis.rank == 1,
          harmonyFit: fit(source, 'metadata.key', key),
          contextCompatible:
              preferredSourceId == null || source.id == preferredSourceId,
          qualitySignals: {
            'harmonicRank': (12 - hypothesis.rank * 3).clamp(-20, 9),
          },
        ),
      );
    }
    final consensus = source.extra['keyEstimate'];
    if (consensus is String && _keyIdentity(consensus) != null) {
      claims.add(
        EvidenceClaim(
          field: 'metadata.key',
          value: consensus,
          sourceId: source.id,
          providerId: 'chord-consensus',
          lineageId: 'discovery-key-consensus',
          contextId: source.id,
          equivalenceKey: _keyIdentity(consensus),
          matchQuality: EvidenceMatchQuality.sameSong,
          sourceScope: EvidenceSourceScope.arrangement,
          origin: EvidenceOrigin.inferred,
          supportsCorroboration: false,
          qualitySignals: const {'chartCrossCheck': 8},
          contextCompatible:
              preferredSourceId == null || source.id == preferredSourceId,
          harmonyFit: fit(source, 'metadata.key', consensus),
        ),
      );
    }
  }
  final analysed = <String>{};
  for (final observation in recordingEvidence) {
    final source = observation.source;
    final measured = observation.key;
    final ids =
        (observation.data['ids'] as List? ?? const [])
            .whereType<String>()
            .toList()
          ..sort();
    final identifierWitness =
        (observation.data['identifierSourceIds'] is List
                ? observation.data['identifierSourceIds'] as List
                : const [])
            .whereType<String>()
            .map((id) => byId[id])
            .whereType<SourceResult>()
            .where((witness) => witness.extra['searchEvidenceOnly'] != true)
            .firstOrNull ??
        source;
    final witnessId = byId.containsKey(identifierWitness.candidate.identity)
        ? identifierWitness.candidate.identity
        : identifierWitness.id;
    if (!analysed.add('$witnessId:$measured:${ids.join(',')}')) continue;
    final supportingMode = <String>{}, opposingMode = <String>{};
    for (final declaration in claims.where(
      (claim) =>
          claim.field == 'metadata.key' &&
          claim.origin != EvidenceOrigin.inferred &&
          claim.providerId != 'recording-key-analysis' &&
          claim.contextCompatible &&
          claim.matchQuality.index >= EvidenceMatchQuality.sameSong.index &&
          claim.value is String &&
          _keyDistance(claim.value as String, measured) == 0 &&
          claim.harmonyFit == EvidenceHarmonyFit.fitting,
    )) {
      final identity =
          byId[declaration.sourceId]?.candidate.identity ??
          declaration.sourceId;
      (_keyIdentity(declaration.value) == _keyIdentity(measured)
              ? supportingMode
              : opposingMode)
          .add(identity);
    }
    final measuredFit = fit(source, 'metadata.key', measured);
    final estimatedCharts = [
      for (final chart in charts)
        if (estimateChordKey(_keyCorrectedBody(chart)) case final estimate?)
          (
            source: chart,
            key: transposeChord(
              estimate.key,
              _capoOf(_setupValue(chart, selected, 'capo')),
            ),
          ),
    ];
    final localTonicOnly =
        measuredFit == EvidenceHarmonyFit.fitting &&
        estimatedCharts.isNotEmpty &&
        estimatedCharts.every((chart) {
          final capo = _capoOf(_setupValue(chart.source, selected, 'capo'));
          return _keyIdentity(chart.key) != _keyIdentity(measured) &&
              !chartSupportsBoundaryTonic(
                _keyCorrectedBody(chart.source),
                transposeChord(measured, (12 - capo) % 12),
              );
        });
    claims.add(
      EvidenceClaim(
        field: 'metadata.key',
        value: measured,
        sourceId: witnessId,
        providerId: 'recording-key-analysis',
        lineageId: 'recording-analysis:${ids.join(',')}',
        equivalenceKey: _keyIdentity(measured),
        matchQuality: observation.bound
            ? EvidenceMatchQuality.sameRecording
            : EvidenceMatchQuality.sameSong,
        sourceScope: observation.bound
            ? EvidenceSourceScope.recording
            : EvidenceSourceScope.song,
        origin: EvidenceOrigin.provider,
        qualitySignals: {
          'algorithmicModeUncertainty': -12,
          if (localTonicOnly) 'algorithmicLocalTonicOnly': -12,
          'recordingAgreement':
              (((observation.data['ids'] as List? ?? const [])
                              .whereType<String>()
                              .map((id) => id.toUpperCase())
                              .toSet()
                              .length -
                          1) *
                      2)
                  .clamp(0, 6),
          if (opposingMode.length > supportingMode.length)
            'relativeModeConflict': -20,
        },
        contextCompatible:
            (observation.bound || factSourceIds.contains(source.id)) &&
            (preferredSourceId == null || source.id == preferredSourceId),
        harmonyFit: localTonicOnly ? EvidenceHarmonyFit.neutral : measuredFit,
      ),
    );
  }
  // A subdominant chord can support a local tonic without establishing the
  // song's home key. When published assertions actually conflict, use the
  // chosen charts' clear home-key estimates to separate those assertions.
  // Inference alone never creates a counterclaim to an uncontested source.
  final clearChartKeys = <String>[
    for (final chart in charts)
      if (estimateChordKey(_keyCorrectedBody(chart)) case final estimate?)
        transposeChord(
          estimate.key,
          _capoOf(_setupValue(chart, selected, 'capo')),
        ),
  ];
  final declarations = claims
      .where(
        (claim) =>
            claim.field == 'metadata.key' &&
            claim.origin != EvidenceOrigin.inferred &&
            claim.contextCompatible &&
            claim.value is String &&
            _keyIdentity(claim.value) != null,
      )
      .toList();
  if (clearChartKeys.isNotEmpty) {
    for (var i = 0; i < claims.length; i++) {
      final claim = claims[i];
      if (!declarations.contains(claim) ||
          !declarations.any(
            (other) =>
                other.sourceId != claim.sourceId &&
                _keyIdentity(other.value) != _keyIdentity(claim.value),
          )) {
        continue;
      }
      // A relative major/minor dispute (C against Am) is a real contest, but
      // a chart estimate of the relative key cannot settle its mode.
      final value = claim.value as String;
      final fit =
          clearChartKeys.any((key) => _keyIdentity(key) == _keyIdentity(value))
          ? 8
          : clearChartKeys.any((key) => _keyDistance(key, value) == 0)
          ? 0
          : -8;
      claims[i] = _rebuildClaim(
        claim,
        qualitySignals: {...claim.qualitySignals, 'contestedHomeKeyFit': fit},
      );
    }
  }
  bool pairCompatible(EvidenceClaim a, EvidenceClaim b) {
    if (a.field.startsWith('${b.field}.') ||
        b.field.startsWith('${a.field}.')) {
      return false;
    }
    EvidenceClaim? chart;
    EvidenceClaim? lyric;
    if (a.field == 'chords') chart = a;
    if (b.field == 'chords') chart = b;
    if (a.field == 'lyrics') lyric = a;
    if (b.field == 'lyrics') lyric = b;
    if (chart != null && lyric != null) {
      final c = byId[chart.sourceId], l = byId[lyric.sourceId];
      return c != null &&
          l != null &&
          _lyricVocabularyCoverage(l.body, c.body) > 0;
    }
    if (chart == null) return true;
    final other = identical(chart, a) ? b : a;
    final source = byId[chart.sourceId];
    if (source == null) return false;
    if (other.field == 'metadata.key') {
      if (other.origin == EvidenceOrigin.inferred && other.contextId != null) {
        return other.contextId == chart.sourceId;
      }
      final published = _setupValue(source, selected, 'key');
      final shift = source.extra['keyShift'];
      final declared = published is String && shift is int && shift % 12 != 0
          ? declaredKeyAfterShift(
              source.body,
              published,
              _setupValue(source, selected, 'capo'),
              shift,
            )
          : published;
      if (other.value is String) {
        final body = _keyCorrectedBody(source);
        final hypotheses = rankChordKeyCandidates(body);
        if (hypotheses.isEmpty) return true;
        final capo = _capoOf(_setupValue(source, selected, 'capo'));
        final shapeKey = transposeChord(
          other.value as String,
          (12 - capo) % 12,
        );
        final harmonicallyCompatible =
            chartSupportsDeclaredTonic(body, shapeKey) ||
            hypotheses
                .take(3)
                .any(
                  (hypothesis) => _keyDistance(hypothesis.key, shapeKey) == 0,
                );
        if (!harmonicallyCompatible) return false;
      }
      if (declared is String &&
          !declaredKeyFitsChords(
            _keyCorrectedBody(source),
            declared,
            _setupValue(source, selected, 'capo'),
          )) {
        return true;
      }
      return declared is! String ||
          other.value is! String ||
          _keyDistance(declared, other.value as String) == 0 ||
          _keyDistance(
                transposeChord(
                  declared,
                  _capoOf(_setupValue(source, selected, 'capo')),
                ),
                other.value as String,
              ) ==
              0;
    }
    if (other.field == 'metadata.capo') {
      return _capoOf(other.value) ==
          _capoOf(_setupValue(source, selected, 'capo'));
    }
    if (other.field == 'metadata.tuning') {
      return _compatibleChartTuning(
        other.value,
        _setupValue(source, selected, 'tuning'),
      );
    }
    if (other.field == 'metadata.timeSignature') {
      final known = _setupValue(source, selected, 'timeSignature');
      return !_hasMetadata(known) ||
          known.toString().trim() == other.value.toString().trim();
    }
    return true;
  }

  return rankEvidenceClaims(
    claims,
    compatibleWithChosen: (candidate, chosen) =>
        chosen.every((other) => pairCompatible(candidate, other)),
    fieldWeights: const {'lyrics': 4, 'chords': 4, 'metadata.key': 2},
    // This compatibility model depends on a claim's value, arrangement context
    // and whether a key is inferred. Equivalent metadata provenance can share
    // one search state without pruning a distinct arrangement option.
    combinationStateKey: (claim) => jsonEncode([
      claim.normalizedValue,
      claim.contextId,
      claim.field == 'metadata.key' && claim.origin == EvidenceOrigin.inferred,
    ]),
  );
}

void _applyRankedMetadata(SongDocument song, EvidenceRanking ranking) {
  final origins = jsonMap(song.extra['fieldOrigins']);
  final contributors = jsonMap(song.extra['fieldContributors']);
  final decisions = <String, dynamic>{};
  final writtenFields = <String>{};
  final conflicts = jsonMap(song.extra['conflicts']);
  final fieldOptions = <String, List<RankedEvidenceClaim>>{};
  for (final option in ranking.claims) {
    if (option.claim.field.startsWith('metadata.') &&
        option.claim.matchQuality != EvidenceMatchQuality.rejected &&
        option.claim.origin != EvidenceOrigin.inferred) {
      fieldOptions.putIfAbsent(option.claim.field, () => []).add(option);
    }
  }
  for (final field in fieldOptions.entries) {
    if (field.value
            .map((option) => option.claim.normalizedValue)
            .toSet()
            .length <
        2) {
      continue;
    }
    final seen = <String>{};
    conflicts[field.key.substring(9)] = [
      for (final option in field.value)
        if (seen.add(
          '${option.claim.sourceId}:${option.claim.normalizedValue}',
        ))
          {
            'sourceId': option.claim.sourceId,
            'value': evidenceDiagnosticValue(option.claim.value),
          },
    ];
  }
  final entries = ranking.chosenByField.entries.toList()
    ..sort((a, b) {
      final keyLast = (a.key == 'metadata.key' ? 1 : 0).compareTo(
        b.key == 'metadata.key' ? 1 : 0,
      );
      return keyLast != 0 ? keyLast : a.key.compareTo(b.key);
    });
  for (final entry in entries) {
    if (!entry.key.startsWith('metadata.')) continue;
    final path = entry.key.substring(9).split('.');
    var claim = entry.value;
    if (entry.key == 'metadata.key' &&
        claim.origin == EvidenceOrigin.inferred) {
      final declaration = ranking.claims
          .where(
            (option) =>
                option.claim.field == entry.key &&
                option.claim.contextCompatible &&
                option.claim.origin != EvidenceOrigin.inferred &&
                option.claim.matchQuality.index >=
                    EvidenceMatchQuality.sameSong.index &&
                option.claim.normalizedValue == claim.normalizedValue,
          )
          .firstOrNull;
      if (declaration != null) claim = declaration.claim;
    }
    if (writtenFields.add(path.first)) contributors.remove(path.first);
    if (path.first == 'key' && claim.origin == EvidenceOrigin.inferred) {
      final shapeKey = transposeChord(
        claim.value.toString(),
        (12 - _capoOf(song.metadata['capo'])) % 12,
      );
      song.extra['chordKeyEstimate'] = {
        'key': shapeKey,
        'bodyHash': _bodyHash(song.body),
        'ranked': true,
      };
      song.metadata.remove('key');
      origins.remove('key');
      contributors.remove('key');
      decisions[entry.key] = {
        'value': claim.value,
        'sourceId': claim.sourceId,
        'inferred': true,
      };
      continue;
    }
    Object value = claim.value;
    final sameValueSources = ranking.claims
        .where(
          (other) =>
              other.claim.field == entry.key &&
              other.claim.contextCompatible &&
              (entry.key != 'metadata.key' ||
                  other.claim.origin != EvidenceOrigin.inferred) &&
              other.claim.normalizedValue == claim.normalizedValue,
        )
        .map((other) => other.claim.sourceId)
        .toSet();
    if (value is List && !_rankedArrangementFields.contains(path.first)) {
      final seen = <String>{};
      value = [
        for (final option in ranking.claims.where(
          (other) =>
              other.claim.field == entry.key && other.claim.contextCompatible,
        ))
          if (option.claim.value is List)
            for (final item in option.claim.value as List)
              if (seen.add(jsonEncode(item))) item,
      ];
      sameValueSources.addAll(
        ranking.claims
            .where(
              (other) =>
                  other.claim.field == entry.key &&
                  other.claim.contextCompatible &&
                  other.claim.value is List,
            )
            .map((other) => other.claim.sourceId),
      );
    }
    Map<String, dynamic> target = song.metadata;
    for (final part in path.take(path.length - 1)) {
      final child = jsonMap(target[part]);
      target[part] = child;
      target = child;
    }
    target[path.last] = value;
    origins[path.first] = claim.sourceId;
    contributors[path.first] = {
      ...?((contributors[path.first] as List?)?.whereType<String>()),
      ...sameValueSources,
    }.toList()..sort();
    if (path.first == 'key') {
      song.extra['keySourceIds'] = sameValueSources.toList()..sort();
    }
    decisions[entry.key] = {
      'value': value,
      'sourceId': claim.sourceId,
      'providerId': claim.providerId,
      'origin': claim.origin.name,
      'matchQuality': claim.matchQuality.name,
      'provisional':
          claim.matchQuality == EvidenceMatchQuality.unverified ||
          ranking.ambiguousFields.contains(entry.key),
    };
  }
  song.extra['fieldOrigins'] = origins;
  song.extra['fieldContributors'] = contributors;
  if (conflicts.isNotEmpty) song.extra['conflicts'] = conflicts;
  song.extra['evidenceRanking'] = {
    'version': 1,
    ...ranking.toJson(),
    'appliedFields': decisions,
    'retainedSourceCount': song.sources.length,
  };
}
