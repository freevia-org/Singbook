import 'arrangement.dart';

/// A conservative estimate based on the harmony in one saved chord chart.
///
/// [separation] is a normalized score margin over the next candidate, not a
/// statistical probability. The estimate is display-only: callers must not
/// persist it as source metadata or use it to establish recording identity.
class ChordKeyEstimate {
  const ChordKeyEstimate({
    required this.key,
    required this.separation,
    required this.chordCount,
    required this.distinctRoots,
  });

  final String key;
  final double separation;
  final int chordCount;
  final int distinctRoots;
}

/// Estimates a key from chord roots, qualities, bass notes and cadences.
///
/// The estimator abstains when the chart is too sparse or its best key is too
/// close to another candidate. It analyzes the whole chart; a first chord by
/// itself never establishes a key.
ChordKeyEstimate? estimateChordKey(String body) {
  final chords = <_Chord>[], groups = <List<_Chord>>[];
  var group = <_Chord>[], sawSectionHeading = false;
  var flatSpellings = 0, sharpSpellings = 0;
  void finishGroup() {
    if (group.isNotEmpty) groups.add(group);
    group = <_Chord>[];
  }

  for (final line in parseArrangement(body)) {
    if (sectionLabelForLine(line) != null) {
      sawSectionHeading = true;
      finishGroup();
      continue;
    }
    if (line.text.trim().isEmpty && line.chords.isEmpty) {
      finishGroup();
      continue;
    }
    if (line.directive) continue;
    for (final anchor in line.chords) {
      final chord = _Chord.parse(anchor.chord);
      if (chord == null) continue;
      chords.add(chord);
      group.add(chord);
      if (chord.rootText.contains('b') || chord.rootText.contains('♭')) {
        flatSpellings++;
      } else if (chord.rootText.contains('#') || chord.rootText.contains('♯')) {
        sharpSpellings++;
      }
    }
  }
  finishGroup();

  final estimate = _estimateChords(chords, flatSpellings, sharpSpellings);
  if (estimate == null) return null;
  if (sawSectionHeading || groups.length > 1) {
    final sectionKeys = <String>{};
    for (final section in groups) {
      final local = _estimateChords(section, flatSpellings, sharpSpellings);
      if (local != null) sectionKeys.add(_keyIdentity(local.key));
    }
    if (sectionKeys.length > 1) return null;
  }
  return estimate;
}

String _keyIdentity(String key) {
  final minor = key.toLowerCase().endsWith('m');
  final root = minor ? key.substring(0, key.length - 1) : key;
  return '${_Chord._pitch(root)}:${minor ? 'minor' : 'major'}';
}

ChordKeyEstimate? _estimateChords(
  List<_Chord> chords,
  int flatSpellings,
  int sharpSpellings,
) {
  final roots = chords.map((chord) => chord.root).toSet();
  if (chords.length < 6 || roots.length < 3) return null;

  final candidates = <_ScoredKey>[
    for (var tonic = 0; tonic < 12; tonic++)
      _scoreKey(chords, tonic, _Mode.major),
    for (var tonic = 0; tonic < 12; tonic++)
      _scoreKey(chords, tonic, _Mode.minor),
  ]..sort((a, b) => b.score.compareTo(a.score));

  final best = candidates.first;
  final runnerUp = candidates[1];
  final margin = best.score - runnerUp.score;
  final separation = margin / chords.length;
  final relativeTonic = best.mode == _Mode.major
      ? (best.tonic + 9) % 12
      : (best.tonic + 3) % 12;
  final relativeAmbiguity =
      runnerUp.mode != best.mode &&
      runnerUp.tonic == relativeTonic &&
      margin < chords.length * 0.65;
  if (margin < 2.0 || separation < 0.32 || relativeAmbiguity) return null;

  final flatNames = flatSpellings > sharpSpellings;
  final names = flatNames ? _flatNames : _sharpNames;
  return ChordKeyEstimate(
    key: '${names[best.tonic]}${best.mode == _Mode.minor ? 'm' : ''}',
    separation: separation,
    chordCount: chords.length,
    distinctRoots: roots.length,
  );
}

enum _Mode { major, minor }

class _ScoredKey {
  const _ScoredKey(this.tonic, this.mode, this.score);
  final int tonic;
  final _Mode mode;
  final double score;
}

class _Chord {
  const _Chord(this.root, this.bass, this.quality, this.rootText);

  final int root, bass;
  final _Quality quality;
  final String rootText;

  static final _pattern = RegExp(r'^([A-G])([#b♯♭]{0,2})(.*)$');

  static _Chord? parse(String symbol) {
    if (RegExp(r'^N\.?C\.?$', caseSensitive: false).hasMatch(symbol)) {
      return null;
    }
    final normalized = symbol.replaceAll('♯', '#').replaceAll('♭', 'b');
    final bassMatch = RegExp(r'/([A-G][#b]{0,2})$').firstMatch(normalized);
    final chordText = bassMatch == null
        ? normalized
        : normalized.substring(0, bassMatch.start);
    final match = _pattern.firstMatch(chordText);
    if (match == null) return null;
    final rootText = '${match[1]}${match[2]}';
    final root = _pitch(rootText);
    final bass = bassMatch == null ? root : _pitch(bassMatch[1]!);
    if (root == null || bass == null) return null;

    final suffix = match[3]!;
    final lowerSuffix = suffix.toLowerCase();
    final quality =
        lowerSuffix.startsWith('dim') ||
            lowerSuffix.startsWith('°') ||
            lowerSuffix.startsWith('ø') ||
            lowerSuffix.startsWith('o')
        ? _Quality.other
        : lowerSuffix.startsWith('aug') || suffix.startsWith('+')
        ? _Quality.other
        : lowerSuffix.startsWith('sus')
        ? _Quality.other
        : (suffix.startsWith('m') && !suffix.startsWith('maj')) ||
              suffix.startsWith('-')
        ? _Quality.minor
        : _Quality.major;
    return _Chord(root, bass, quality, rootText);
  }

  static int? _pitch(String note) {
    final match = _pattern.firstMatch(note);
    if (match == null || match[3]!.isNotEmpty) return null;
    const natural = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
    final pitch = natural[match[1]];
    if (pitch == null) return null;
    final accidental = match[2]!.replaceAll('b', '♭');
    final offset = accidental
        .split('')
        .fold<int>(
          0,
          (sum, value) => sum + (value == '#' || value == '♯' ? 1 : -1),
        );
    return (pitch + offset + 12) % 12;
  }
}

enum _Quality { major, minor, other }

_ScoredKey _scoreKey(List<_Chord> chords, int tonic, _Mode mode) {
  final scale = mode == _Mode.major
      ? const [0, 2, 4, 5, 7, 9, 11]
      : const [0, 2, 3, 5, 7, 8, 10];
  final qualities = mode == _Mode.major
      ? const [
          _Quality.major,
          _Quality.minor,
          _Quality.minor,
          _Quality.major,
          _Quality.major,
          _Quality.minor,
          _Quality.other,
        ]
      : const [
          _Quality.minor,
          _Quality.other,
          _Quality.major,
          _Quality.minor,
          _Quality.major,
          _Quality.major,
          _Quality.major,
        ];
  final degreeWeights = mode == _Mode.major
      ? const [1.8, 0.65, 0.55, 1.0, 1.65, 0.7, 0.25]
      : const [1.65, 0.25, 0.85, 0.75, 1.2, 0.8, 0.55];
  var score = 0.0;

  for (final chord in chords) {
    final degree = (chord.root - tonic + 12) % 12;
    final index = scale.indexOf(degree);
    if (index >= 0) {
      final expected = qualities[index];
      score += expected == chord.quality
          ? 1.1 + degreeWeights[index]
          : _borrowedChordScore(mode, degree, chord.quality);
    } else if (chord.quality == _Quality.major &&
        _isSecondaryDominant(chord.root, tonic, scale)) {
      score += 0.6;
    } else {
      score -= 0.75;
    }

    // Pedal-tone slash chords are useful context. They count modestly so one
    // held bass note cannot determine the key by itself.
    if (chord.bass == tonic) score += 0.35;
  }

  if (chords.last.root == tonic) score += 2.0;
  if (chords.first.root == tonic) score += 0.35;
  for (var i = 1; i < chords.length; i++) {
    final previous = (chords[i - 1].root - tonic + 12) % 12;
    final current = (chords[i].root - tonic + 12) % 12;
    if (previous == 7 && current == 0) score += 2.0;
    if (mode == _Mode.major && previous == 5 && current == 0) {
      score += 0.7;
    }
  }

  return _ScoredKey(tonic, mode, score);
}

double _borrowedChordScore(_Mode mode, int degree, _Quality quality) {
  if (mode == _Mode.major &&
      ((degree == 5 && quality == _Quality.minor) ||
          (degree == 10 && quality == _Quality.major))) {
    // The minor iv and flat VII are common in major-key popular music.
    return 0.45;
  }
  if (mode == _Mode.major && degree == 2 && quality == _Quality.major) {
    // The major II often functions as V/V.
    return 0.35;
  }
  if (mode == _Mode.minor &&
      ((degree == 7 && quality == _Quality.major) ||
          (degree == 11 && quality == _Quality.major))) {
    // Natural/harmonic-minor mixture commonly changes the fifth or seventh.
    return 0.4;
  }
  return -0.7;
}

bool _isSecondaryDominant(int root, int tonic, List<int> scale) {
  for (final degree in scale) {
    final target = (tonic + degree) % 12;
    if ((root - target + 12) % 12 == 7) return true;
  }
  return false;
}

const _sharpNames = [
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
const _flatNames = [
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
