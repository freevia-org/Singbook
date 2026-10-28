import 'arrangement.dart' show parseArrangement;
import 'lyric_word_identity.dart' show foldLyricVowelAccents;

/// Checks whether chart lyrics agree with a full recording lyric reference.
///
/// The default requires the same near-complete coverage as ordinary chart
/// agreement. [allowPartial] adds a more limited proof for a separately
/// validated alternate-performer chart: several chord-bearing lyric lines
/// must match the reference closely and in order. It does not claim that the
/// chart contains the full song.
bool contextualChartLyricsMatch(
  String chart,
  String reference, {
  bool allowPartial = false,
}) {
  final chartWords = _words(chart);
  final referenceWords = _words(reference);
  if (_strictAgreement(chartWords, referenceWords)) return true;
  if (!allowPartial) return false;

  final referenceVocabulary = referenceWords.toSet();
  if (referenceVocabulary.isEmpty) return false;
  final fragments = <List<String>>[];
  final compactFragments = <List<String>>[];
  final compactReference = referenceWords.join();
  var chordBearingLines = 0;
  var compactChordBearingLines = 0;
  for (final line in parseArrangement(chart)) {
    if (line.directive) continue;
    final words = _words(line.text);
    if (words.length < 3) continue;
    // Layout extraction can split or join words around chord anchors. Exact
    // letter-order matches are stronger evidence than token boundaries.
    if (compactReference.contains(words.join())) {
      compactFragments.add(words);
      if (line.chords.isNotEmpty) compactChordBearingLines++;
    }
    final matched = words.where(referenceVocabulary.contains).length;
    if (matched / words.length < .7) continue;
    fragments.add(words);
    if (line.chords.isNotEmpty) chordBearingLines++;
  }
  if (compactFragments.length >= 4 &&
      compactChordBearingLines >= 2 &&
      compactFragments
              .expand((line) => line)
              .toSet()
              .intersection(referenceVocabulary)
              .length >=
          12) {
    return true;
  }
  if (fragments.length < 4 || chordBearingLines < 2) return false;

  final fragment = fragments.expand((line) => line).toList();
  final unique = fragment.toSet();
  final shared = unique.intersection(referenceVocabulary);
  if (shared.length < 12 || shared.length / unique.length < .90) return false;

  final referenceBigrams = _bigrams(referenceWords);
  final fragmentBigrams = _bigrams(fragment);
  if (fragmentBigrams.isEmpty) return false;
  final matchedBigrams = fragmentBigrams.intersection(referenceBigrams);
  return matchedBigrams.length / fragmentBigrams.length >= .75;
}

List<String> _words(String body) => _normalizedIdentity(
  foldLyricVowelAccents(body)
      .replaceAll(RegExp(r'\{[^}\n]*\}'), ' ')
      .replaceAll(RegExp(r'(?<!\\)\[[^\]\n]*\]'), ''),
).split(' ').where((word) => word.isNotEmpty).toList();

String _normalizedIdentity(String text) => text
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

bool _strictAgreement(List<String> chart, List<String> reference) {
  final chartUnique = chart.toSet();
  final referenceUnique = reference.toSet();
  final common = chartUnique.intersection(referenceUnique);
  if (common.length < 12 ||
      common.length / chartUnique.length < .8 ||
      common.length / referenceUnique.length < .85) {
    return false;
  }
  final chartBigrams = _bigrams(chart);
  final referenceBigrams = _bigrams(reference);
  final commonBigrams = chartBigrams.intersection(referenceBigrams);
  return chartBigrams.isNotEmpty &&
      referenceBigrams.isNotEmpty &&
      commonBigrams.length / chartBigrams.length >= .65 &&
      commonBigrams.length / referenceBigrams.length >= .65;
}

Set<String> _bigrams(List<String> words) => {
  for (var i = 1; i < words.length; i++) '${words[i - 1]} ${words[i]}',
};
