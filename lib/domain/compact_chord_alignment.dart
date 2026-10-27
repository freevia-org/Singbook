import 'package:characters/characters.dart';

import 'arrangement.dart' show ArrangementLine, ChordAnchor, parseArrangement;
import 'lyric_word_identity.dart' show foldLyricVowelAccents;

const _maxTargetLines = 300;
const _maxDonorLines = 200;
const _maxLineLetters = 2048;
const _maxLineComparisons = 60000;
const _maxOccurrences = 5000;
const _maxAnchorOperations = 100000;
final _letter = RegExp(r'^\p{L}$', unicode: true);
final _word = RegExp(r'[\p{L}\p{N}]+', unicode: true);

class _CompactText {
  const _CompactText(
    this.value,
    this.starts,
    this.ends,
    this.graphemeLetterCounts,
    this.letterIndexAt,
  );

  final String value;
  final List<int> starts;
  final List<int> ends;
  final List<int> graphemeLetterCounts;
  final Map<int, int> letterIndexAt;
}

_CompactText _compact(String text) {
  final letters = StringBuffer();
  final starts = <int>[];
  final ends = <int>[];
  final graphemeLetterCounts = <int>[0];
  final letterIndexAt = <int, int>{};
  var compactOffset = 0;
  var graphemeOffset = 0;
  for (final cluster in text.characters) {
    final normalized = foldLyricVowelAccents(cluster).toLowerCase();
    for (final rune in normalized.runes) {
      final value = String.fromCharCode(rune);
      if (!_letter.hasMatch(value)) continue;
      letterIndexAt[compactOffset] = starts.length;
      letters.write(value);
      starts.add(graphemeOffset);
      ends.add(graphemeOffset + 1);
      compactOffset += value.length;
    }
    graphemeOffset++;
    graphemeLetterCounts.add(starts.length);
  }
  return _CompactText(
    letters.toString(),
    starts,
    ends,
    graphemeLetterCounts,
    letterIndexAt,
  );
}

String _placementSignature(List<ChordAnchor> anchors) => anchors
    .map((anchor) => '${anchor.offset}\u0000${anchor.chord}')
    .join('\u0001');

String? _preferExplicitChord(Set<String> chords) {
  if (chords.length == 1) return chords.single;
  if (chords.length != 2) return null;
  String? root(String chord) {
    final match = RegExp(r'^([A-G](?:#|b|♯|♭)?)(.*)$').firstMatch(chord);
    return match?.group(1)?.toUpperCase();
  }

  String suffix(String chord) =>
      RegExp(r'^([A-G](?:#|b|♯|♭)?)(.*)$').firstMatch(chord)?.group(2) ?? '';

  final fifth = chords.where((chord) => suffix(chord) == '5').toList();
  final explicit = chords.where((chord) {
    final ending = suffix(chord).toLowerCase();
    return ending.isEmpty || ending == 'm' || ending == 'min';
  }).toList();
  if (fifth.length == 1 &&
      explicit.length == 1 &&
      root(fifth.single) == root(explicit.single)) {
    return explicit.single;
  }
  return null;
}

List<ChordAnchor>? _resolveSpan(List<List<ChordAnchor>> alternatives) {
  if (alternatives.isEmpty) return null;
  final expectedOffsets = alternatives.first
      .map((anchor) => anchor.offset)
      .toList();
  for (final anchors in alternatives) {
    if (anchors.length != expectedOffsets.length) return null;
    for (var i = 0; i < anchors.length; i++) {
      if (anchors[i].offset != expectedOffsets[i]) return null;
    }
  }
  final resolved = <ChordAnchor>[];
  for (var index = 0; index < expectedOffsets.length; index++) {
    final chord = _preferExplicitChord({
      for (final alternative in alternatives) alternative[index].chord,
    });
    if (chord == null) return null;
    resolved.add(ChordAnchor(expectedOffsets[index], chord));
  }
  return resolved;
}

/// Aligns full lyric lines from [chart] to exact letter-order substrings in
/// individual [target] lyric lines. Returned offsets are grapheme offsets,
/// matching [ChordAnchor] and [parseArrangement]; target text is never changed.
///
/// Ambiguous target lines are omitted when matching donor lines disagree on
/// chord placements. Repeated identical placements are returned only once.
Map<int, List<ChordAnchor>> compactLineChords(
  List<ArrangementLine> target,
  String chart,
) {
  if (target.length > _maxTargetLines) return const {};
  final donors = parseArrangement(chart)
      .where((line) => !line.directive && line.chords.isNotEmpty)
      .take(_maxDonorLines + 1)
      .toList();
  if (donors.length > _maxDonorLines) return const {};

  final donorRows = <({ArrangementLine line, _CompactText compact})>[];
  for (final line in donors) {
    if (_word.allMatches(line.text).length < 3) continue;
    final compact = _compact(line.text);
    if (compact.starts.length < 12 ||
        compact.starts.length > _maxLineLetters ||
        line.chords.length > 128) {
      continue;
    }
    donorRows.add((line: line, compact: compact));
  }

  final placements = <int, Map<String, Map<String, List<ChordAnchor>>>>{};
  var comparisons = 0;
  var occurrences = 0;
  var anchorOperations = 0;
  for (var targetIndex = 0; targetIndex < target.length; targetIndex++) {
    final line = target[targetIndex];
    if (line.directive || line.text.isEmpty) continue;
    final compactTarget = _compact(line.text);
    if (compactTarget.starts.length > _maxLineLetters) continue;
    for (final donor in donorRows) {
      comparisons++;
      if (comparisons > _maxLineComparisons) return const {};
      var matchAt = compactTarget.value.indexOf(donor.compact.value);
      while (matchAt >= 0) {
        occurrences++;
        if (occurrences > _maxOccurrences) return const {};
        // Every compact character is a Unicode letter, so the UTF-16 start
        // maps back to its corresponding source letter index.
        final matchLetter = compactTarget.letterIndexAt[matchAt];
        if (matchLetter == null) {
          matchAt = compactTarget.value.indexOf(
            donor.compact.value,
            matchAt + 1,
          );
          continue;
        }
        final mapped = <ChordAnchor>[];
        for (final chord in donor.line.chords) {
          anchorOperations++;
          if (anchorOperations > _maxAnchorOperations) return const {};
          final lettersBefore =
              donor.compact.graphemeLetterCounts[chord.offset
                  .clamp(0, donor.compact.graphemeLetterCounts.length - 1)
                  .toInt()];
          final int targetOffset;
          if (lettersBefore >= donor.compact.starts.length) {
            targetOffset =
                compactTarget.ends[matchLetter + donor.compact.ends.length - 1];
          } else {
            targetOffset = compactTarget.starts[matchLetter + lettersBefore];
          }
          mapped.add(ChordAnchor(targetOffset, chord.chord));
        }
        mapped.sort((a, b) {
          final byOffset = a.offset.compareTo(b.offset);
          return byOffset != 0 ? byOffset : a.chord.compareTo(b.chord);
        });
        final signature = _placementSignature(mapped);
        final spanKey =
            '$matchLetter:${matchLetter + donor.compact.ends.length}';
        placements
                .putIfAbsent(targetIndex, () => {})
                .putIfAbsent(spanKey, () => {})[signature] =
            mapped;
        matchAt = compactTarget.value.indexOf(donor.compact.value, matchAt + 1);
      }
    }
  }

  final result = <int, List<ChordAnchor>>{};
  for (final entry in placements.entries) {
    final candidates = <int, Set<String>>{};
    for (final span in entry.value.values) {
      final resolved = _resolveSpan(span.values.toList());
      if (resolved == null) continue;
      for (final anchor in resolved) {
        candidates.putIfAbsent(anchor.offset, () => {}).add(anchor.chord);
      }
    }
    final anchors = <ChordAnchor>[];
    for (final candidate in candidates.entries) {
      final chord = _preferExplicitChord(candidate.value);
      if (chord != null) anchors.add(ChordAnchor(candidate.key, chord));
    }
    anchors.sort((a, b) => a.offset.compareTo(b.offset));
    if (anchors.isNotEmpty) result[entry.key] = anchors;
  }
  return result;
}
