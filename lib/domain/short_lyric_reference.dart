import 'lyric_word_identity.dart';

/// Whether a lyrics body is a sufficiently complete, short-vocabulary
/// reference for the narrow recording-lyrics comparison.
///
/// Body shape alone cannot establish completeness or recording identity.
/// Callers must require a matched recording reference. Sparse refrains and
/// longer-vocabulary lyrics do not qualify for this narrow comparison.
bool isShortRecordingLyricBody(String body) {
  final words = _words(body);
  final nonemptyLines = body
      .split('\n')
      .where((line) => _words(line).isNotEmpty)
      .length;
  final vocabulary = words.toSet();
  return words.length >= 24 &&
      words.length <= 240 &&
      vocabulary.length >= 6 &&
      vocabulary.length <= 11 &&
      nonemptyLines >= 4;
}

/// Checks for near-whole-sequence agreement when a complete reference uses a
/// small vocabulary. [chart] may omit at most two words, but must preserve the
/// order of every remaining word and may not add or change words.
///
/// This is intentionally stricter than a general lyric similarity check: a
/// shared refrain or a reordered excerpt is not enough to identify a
/// recording.
bool shortRecordingLyricAgreement(String chart, String reference) {
  if (!isShortRecordingLyricBody(reference)) return false;

  final chartWords = _words(chart);
  final referenceWords = _words(reference);
  if (chartWords.isEmpty ||
      chartWords.toSet().length < 6 ||
      chartWords.length < referenceWords.length * .94 ||
      referenceWords.length - chartWords.length > 2) {
    return false;
  }

  var chartIndex = 0;
  var omissions = 0;
  for (final referenceWord in referenceWords) {
    if (chartIndex < chartWords.length &&
        chartWords[chartIndex] == referenceWord) {
      chartIndex++;
    } else {
      omissions++;
      if (omissions > 2) return false;
    }
  }
  return chartIndex == chartWords.length && omissions <= 2;
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
