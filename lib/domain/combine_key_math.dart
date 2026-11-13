part of 'combine.dart';

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
  // A non-finite number (JSON `1e999` decodes to infinity) has no integer
  // value; treat it like an unreadable capo instead of throwing.
  final value = capo is num
      ? (capo.isFinite ? capo.toInt() : null)
      : int.tryParse('${capo ?? ''}');
  return value == null || value < 0 ? 0 : value % 12;
}

bool _isExplicitZeroCapo(Object? capo) => capo is num
    ? capo.isFinite && capo == 0
    : capo is String && capo.trim() == '0';

/// A tuning's notes, lower case and single-spaced, whether it was given as
/// a list or as text ("[E, A, D, G, B, E]" and "E A D G B E" are equal).
String _normalizedTuning(Object? tuning) =>
    (tuning is List ? tuning.join(' ') : '$tuning')
        .toLowerCase()
        .split(RegExp(r'[\s,\[\]]+'))
        .where((note) => note.isNotEmpty)
        .join(' ');

bool _isStandardTuning(Object? tuning) =>
    tuning != null && _normalizedTuning(tuning) == 'e a d g b e';

bool _compatibleChartTuning(Object? selected, Object? donor) {
  if (!_hasMetadata(selected) && !_hasMetadata(donor)) return true;
  if (!_hasMetadata(selected)) return _isStandardTuning(donor);
  if (!_hasMetadata(donor)) return _isStandardTuning(selected);
  return _normalizedTuning(selected) == _normalizedTuning(donor);
}

/// Whether a chart's declared (sounding) key fits its own chords played with
/// [capo]. A chart whose chords give no key estimate is not contradicted.
bool declaredKeyFitsChords(String chart, String declared, Object? capo) {
  final estimate = estimateChordKey(chart)?.key;
  if (estimate == null) return true;
  return _keyDistance(estimate, declared) == _capoOf(capo);
}

bool _keyFitsKnownChords(SongDocument song, String key) {
  // [declaredKeyFitsChords] with a known estimate, estimating only once.
  final estimate = estimateChordKey(song.body)?.key;
  return estimate != null &&
      _keyDistance(estimate, key) ==
          _capoOf(
            _nonemptyFallback(
              song.metadata['capo'],
              song.selectedRecording?.metadata['capo'],
            ),
          );
}

Object? _nonemptyFallback(Object? preferred, Object? fallback) =>
    _hasMetadata(preferred) ? preferred : fallback;

/// The evidence behind one key claim, computed once per claim instead of on
/// every comparison of a sort.
class _KeyClaimEvidence {
  _KeyClaimEvidence(this._song, this.claim);
  final SongDocument _song;
  final ({String key, List<String> sourceIds}) claim;

  late final int distinctProviders = _song.sources
      .where((source) => claim.sourceIds.contains(source.id))
      .map((source) => source.candidate.providerId)
      .toSet()
      .length;
  late final int recordingMatches = _song.sources
      .where(
        (source) =>
            claim.sourceIds.contains(source.id) &&
            source.matchKind == MatchKind.sameRecording,
      )
      .map((source) => source.candidate.providerId)
      .toSet()
      .length;
  late final bool fitsKnownChords = _keyFitsKnownChords(_song, claim.key);
}

int _keyEvidenceCompare(_KeyClaimEvidence a, _KeyClaimEvidence b) {
  final providers = b.distinctProviders.compareTo(a.distinctProviders);
  if (providers != 0) return providers;
  final recordings = b.recordingMatches.compareTo(a.recordingMatches);
  if (recordings != 0) return recordings;
  if (a.fitsKnownChords != b.fitsKnownChords) {
    return a.fitsKnownChords ? -1 : 1;
  }
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
