import 'arrangement.dart' show lyricLines;

/// Keeps a fuller same-response lyric variant only when it contains the
/// primary text in order and stays within conservative expansion bounds.
///
/// This deliberately does not merge text. The selected value is one complete
/// provider-supplied variant, so timing tracks remain bound to their own raw
/// source and can be checked by the existing exact lyric hash path.
String preferCompatibleLyrics(String primary, Iterable<String> alternatives) {
  final baseLines = _normalizedLines(primary);
  if (baseLines.isEmpty) {
    for (final alternative in alternatives) {
      if (alternative.trim().isNotEmpty) return alternative;
    }
    return primary;
  }
  final baseWords = baseLines.fold<int>(0, (n, line) => n + _words(line));
  if (baseLines.length < 2 || baseWords < 8) return primary;

  var bestText = primary;
  var bestLines = baseLines;
  var bestWords = baseWords;
  for (final alternative in alternatives) {
    final candidateLines = _normalizedLines(alternative);
    final candidateWords = candidateLines.fold<int>(
      0,
      (n, line) => n + _words(line),
    );
    if (candidateLines.length <= bestLines.length ||
        candidateWords <= bestWords ||
        candidateLines.length > baseLines.length * 3 ||
        candidateWords > baseWords * 3 ||
        !_isOrderedSubsequence(bestLines, candidateLines)) {
      continue;
    }
    bestText = alternative;
    bestLines = candidateLines;
    bestWords = candidateWords;
  }
  return bestText;
}

List<String> _normalizedLines(String body) => [
  for (final line in lyricLines(body))
    if (_normalize(line).isNotEmpty) _normalize(line),
];

String _normalize(String line) => line
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

int _words(String line) =>
    line.split(' ').where((word) => word.isNotEmpty).length;

bool _isOrderedSubsequence(List<String> subset, List<String> whole) {
  var index = 0;
  for (final line in whole) {
    if (line == subset[index]) {
      index++;
      if (index == subset.length) return true;
    }
  }
  return false;
}
