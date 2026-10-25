import 'dart:convert';
import 'dart:math' as math;
import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'models.dart';
import 'edition_identity.dart';
import 'metadata_enrichment.dart';
import 'arrangement.dart';
import 'artist_credit.dart';
import 'chord_key_estimate.dart' show estimateChordKey;
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
  return artist == _identityNorm(b.artist) && title == _baseTitle(b.title);
}

/// A chord site's arrangement of [b]'s song: chord sites may credit only
/// the main artist of "Main & Others" or "Main feat. Guest", and may drop a
/// leading article. Only for charts whose lyrics discovery has corroborated.
bool _sameArrangedSong(SongCandidate a, SongCandidate b) {
  String title(String value) =>
      _baseTitle(value).replaceFirst(RegExp(r'^(?:the|a|an) '), '');
  final song = title(a.title);
  if (song.isEmpty || song != title(b.title)) return false;
  return artistCreditsMatch(a.artist, b.artist, _identityNorm);
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

/// Whether a chart's declared (sounding) key fits its own chords played with
/// [capo]. A chart whose chords give no key estimate is not contradicted.
bool declaredKeyFitsChords(String chart, String declared, Object? capo) {
  final estimate = estimateChordKey(chart)?.key;
  if (estimate == null) return true;
  return _keyDistance(estimate, declared) == _capoOf(capo);
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
  if (!explicitEditionsCompatible(
    selected,
    result.candidate,
    metadata: result.metadata,
    extra: result.extra,
  )) {
    return false;
  }
  if (selected.providerId == 'wikisource' ||
      result.candidate.providerId == 'wikisource' ||
      selected.metadata['identityScope'] == 'historicalText' ||
      result.candidate.metadata['identityScope'] == 'historicalText' ||
      result.metadata['identityScope'] == 'historicalText' ||
      result.extra['identityScope'] == 'historicalText') {
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
  final selectedScope = selected.metadata['identityScope'];
  final foundScope = found.metadata['identityScope'];
  const nonRecordingScopes = {
    'composition',
    'work',
    'artist',
    'image',
    'historicalText',
  };
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
    // A chart the combined arrangement moved into the majority key is judged
    // in that key (see [_keyCorrectedBody] and [declaredKeyAfterShift]).
    final shift = jsonMap(song.extra['chordKeyShifts'])[source.id];
    final shifted = shift is int && shift % 12 != 0;
    final declared = _keyIdentity(source.metadata['key']) != null
        ? source.metadata['key'] as String
        : source.candidate.metadata['key'];
    final key = shifted
        ? declaredKeyAfterShift(
            source.body,
            declared is String ? declared : null,
            source.metadata['capo'] ?? source.candidate.metadata['capo'],
            shift,
          )
        : declared;
    final identity = _keyIdentity(key);
    if (identity == null) continue;
    // A label contradicting the chart's own chords is not evidence of a key.
    if (!shifted &&
        !declaredKeyFitsChords(
          source.body,
          key as String,
          source.metadata['capo'] ?? source.candidate.metadata['capo'],
        )) {
      continue;
    }
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
    final aligned = _phraseChords(
      plain,
      shifted ? transposeBody(source.body, shift) : source.body,
    );
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
  if (!explicitEditionsCompatible(
    selected,
    donor.candidate,
    metadata: donor.metadata,
    extra: donor.extra,
  )) {
    return false;
  }
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
({String body, int lines}) _fillRepeatedSections(String body) {
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
      word: match[0]!
          .toLowerCase()
          .replaceFirst(RegExp(r"in'$"), 'ing')
          .replaceAll("'", ''),
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
  List<(int, int)> pairs,
) {
  final aligned = {for (final (a, b) in pairs) a: b};
  final anchors = <(int?, int, String)>[];
  // Chords keep their order: a chord never lands before the previous one,
  // or on its word unless both sat on one chart word.
  int? previous, previousWord;
  var ended = false;
  for (final chord in line.chords) {
    final index = from.indexWhere((word) => chord.offset < word.end);
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
        ? (chord.offset - from[index].start).clamp(0, target.end - target.start)
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
  final donors = [
    for (final line in parseArrangement(chart))
      if (!line.directive &&
          line.chords.isNotEmpty &&
          plainText(line.text) &&
          _lineWords(line.text).length >= 3 &&
          _lineWords(line.text).length <= 40)
        (line: line, words: _lineWords(line.text)),
  ];
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
    for (var i = 0; i < target.length; i++)
      if (!target[i].directive &&
          plainText(target[i].text) &&
          _lineWords(target[i].text).isNotEmpty &&
          _lineWords(target[i].text).length <= 40)
        (index: i, words: known(_lineWords(target[i].text))),
  ];
  if (donors.isEmpty ||
      lyrics.isEmpty ||
      donors.length * lyrics.length > 40000) {
    return const {};
  }
  // A match covers one lyric line, or two adjacent ones ([span] 2) whose
  // words are compared as one line.
  bool joinable(int l) =>
      l + 1 < lyrics.length && lyrics[l + 1].index == lyrics[l].index + 1;
  _Words wordsOf(int l, int span) => span == 1
      ? lyrics[l].words
      : [...lyrics[l].words, ...lyrics[l + 1].words];
  final pairsOf = <(int, int, int), List<(int, int)>>{};
  List<(int, int)> pairs(int d, int l, int span) => pairsOf.putIfAbsent((
    d,
    l,
    span,
  ), () => _alignWords(donors[d].words, wordsOf(l, span)));
  double similarity(int d, int l, [int span = 1]) {
    if (span == 2 && !joinable(l)) return 0;
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
  double joined(int d, int l) {
    final value = similarity(d, l, 2);
    return value > 0 &&
            !contained(d, l, 2) &&
            value > similarity(d, l) &&
            (!joinable(l) || value > similarity(d, l + 1))
        ? value
        : 0;
  }

  final score = List.generate(rows + 1, (_) => List.filled(columns + 2, 0.0));
  for (var d = rows - 1; d >= 0; d--) {
    for (var l = columns - 1; l >= 0; l--) {
      final match = similarity(d, l);
      final pair = joined(d, l);
      var best = score[d + 1][l] > score[d][l + 1]
          ? score[d + 1][l]
          : score[d][l + 1];
      if (match > 0 && match + score[d + 1][l + 1] > best) {
        best = match + score[d + 1][l + 1];
      }
      if (pair > 0 && 2 * pair + score[d + 1][l + 2] > best) {
        best = 2 * pair + score[d + 1][l + 2];
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
  final matched = <(int, int, int)>[];
  // The same lyric text left uncovered elsewhere makes the place where a
  // match lands as arbitrary as an ambiguous chart line.
  final covered = <int>{};
  String textOf(int l, int span) =>
      wordsOf(l, span).map((word) => word.word).join(' ');
  bool repeatedElsewhere(int l, int span) {
    final text = textOf(l, span);
    for (var other = 0; other < columns; other++) {
      if (other == l ||
          covered.contains(other) ||
          (span == 2 && (!joinable(other) || covered.contains(other + 1)))) {
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
    final pair = joined(d, l);
    if (pair > 0 && score[d][l] == 2 * pair + score[d + 1][l + 2]) {
      matched.add((d, l, 2));
      d++;
      l += 2;
    } else if (match > 0 && score[d][l] == match + score[d + 1][l + 1]) {
      matched.add((d, l, 1));
      d++;
      l++;
    } else if (score[d + 1][l] >= score[d][l + 1]) {
      d++;
    } else {
      l++;
    }
  }
  for (final (_, l, span) in matched) {
    covered.addAll([l, if (span == 2) l + 1]);
  }
  final result = <int, List<ChordAnchor>>{};
  void place(int d, int l, int span) {
    final words = wordsOf(l, span);
    final split = lyrics[l].words.length;
    for (final (word, inWord, chord) in _mapChordWords(
      donors[d].line,
      donors[d].words,
      words,
      pairs(d, l, span),
    )) {
      // Chords after the last word stay at the end of the last line.
      final second = word == null ? span == 2 : word >= split;
      final line = lyrics[second ? l + 1 : l].index;
      final offset = word == null
          ? target[line].text.length
          : words[word].start + inWord;
      result.putIfAbsent(line, () => []).add(ChordAnchor(offset, chord));
    }
  }

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
    if (tied) continue;
    if (weak((d, l, span)) &&
        (!matched.take(m).any((match) => !weak(match)) ||
            !matched.skip(m + 1).any((match) => !weak(match)))) {
      continue;
    }
    place(d, l, span);
  }
  // Leftover lyric lines: the single closest chart line, if unambiguous.
  for (var l = 0; l < columns; l++) {
    if (result.containsKey(lyrics[l].index)) continue;
    var best = -1;
    var bestScore = 0.0;
    var ambiguous = false;
    for (var d = 0; d < rows; d++) {
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

({String body, List<String> sourceIds, Set<String> movedIds}) _overlayChords(
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
    final donorBody = _keyCorrectedBody(source);
    // Lines whose wording differs slightly between sources (an extra "let it
    // be", a contraction) are aligned word by word where exact phrases fail.
    final chords = {
      ..._fuzzyLineChords(plain, donorBody),
      for (final entry in _phraseChords(plain, donorBody).entries)
        if (entry.value.isNotEmpty) entry.key: entry.value,
    };
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
      if (move != 0 && _keyConsensusRank(candidate.source) > 0) {
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
      // Discovery's key check placing both charts in the key most charts
      // share also shows they can be read together.
      final checkedSameKey =
          primary.extra.containsKey('keyConsensus') &&
          candidate.source.extra.containsKey('keyConsensus') &&
          _keyConsensusRank(primary) > 0 &&
          _keyConsensusRank(candidate.source) > 0;
      if (contradicts || (!agrees && !explicitSetup && !checkedSameKey)) {
        continue;
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
    return (body: body, sourceIds: const [], movedIds: const <String>{});
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
  );
}

SongDocument combineSources(
  SongCandidate selected,
  List<SourceResult> results, {
  String? preferredSourceId,
  bool allowRejectedPreferredSource = false,
  List<HistoricalCacheUse> historicalCacheUses = const [],
}) {
  bool historicalMatches(SourceResult source) =>
      explicitHistoricalWorkMatches(selected, source) ||
      historicalCacheUses.any((use) => use.allows(selected, source));
  final matching = results.where((s) {
    final wikiSource = s.candidate.providerId == 'wikisource';
    final allowedRejectedAlternative =
        allowRejectedPreferredSource &&
        s.id == preferredSourceId &&
        !wikiSource;
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
        : ((_sameSong(s.candidate, selected) ||
                      (s.hasChords &&
                          s.extra['requiresLyricsAgreement'] == true &&
                          _sameArrangedSong(s.candidate, selected))) &&
                  editionAllowed) ||
              allowedRejectedAlternative;
    return identityMatches &&
        (s.matchKind != MatchKind.rejected ||
            wikiSource && historicalMatches(s) ||
            allowedRejectedAlternative);
  }).toList();
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
      (s.hasChords && s.extra['keyConsensus'] != false ? 500 : 0);
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
          _keyCorrectedBody(best),
          accepted.where((source) => source.id != best.id).toList(),
          selected,
          best,
        )
      : (
          body: best.body,
          sourceIds: const <String>[],
          movedIds: const <String>{},
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
    if (scoped == 'recording' && !sameRecording) continue;
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
      ? _fillRepeatedSections(sectioned)
      : (body: sectioned, lines: 0);
  final finalBody = filled.body;
  final song = SongDocument(
    id: newId(),
    title: selected.title,
    artist: selected.artist.trim().isNotEmpty
        ? selected.artist
        : historicalAuthor ?? selected.artist,
    body: finalBody,
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
          },
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
