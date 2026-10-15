/// Formats [seconds] as `m:ss`, rounding to the nearest second.
String formatDuration(double seconds) {
  final total = seconds.round();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
}
