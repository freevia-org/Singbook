import 'dart:convert';

/// Selects a single ready adb device from `adb devices` output.
///
/// When [configuredSerial] is non-empty, it must identify a ready device in
/// the successful listing. Without an explicit serial, exactly one ready
/// device must be present. This keeps callers from guessing a target when the
/// listing is unavailable or ambiguous.
String selectAdbDeviceSerial({
  required String stdout,
  required int exitCode,
  String? configuredSerial,
}) {
  if (exitCode != 0) {
    throw StateError('Could not list adb devices (exit code $exitCode).');
  }

  final readySerials = <String>[];
  for (final line in const LineSplitter().convert(stdout)) {
    final columns = line.trim().split(RegExp(r'\s+'));
    if (columns.length >= 2 && columns[1] == 'device') {
      readySerials.add(columns.first);
    }
  }

  final explicit = configuredSerial?.trim() ?? '';
  if (explicit.isNotEmpty) {
    if (readySerials.contains(explicit)) return explicit;
    throw StateError('Configured adb device is not ready or not attached.');
  }

  if (readySerials.length == 1) return readySerials.single;
  if (readySerials.isEmpty) {
    throw StateError('No ready adb device is attached.');
  }
  throw StateError(
    'Several adb devices are ready (${readySerials.join(', ')}); set '
    'SINGBOOK_ADB_SERIAL so the right device is used.',
  );
}
