import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  final watcher = await _NativeScreenshotWatcher.start();
  final expectedScreenshots = <String>{};
  try {
    await integrationDriver(
      onScreenshot: (name, image, [args]) async {
        final safeName = _safeName(name);
        if (safeName == null) return false;
        expectedScreenshots.add(safeName);
        final output = File(
          path.join(_outputDirectory.path, '$safeName-flutter.png'),
        );
        await _outputDirectory.create(recursive: true);
        await output.writeAsBytes(image, flush: true);
        return true;
      },
    );
  } finally {
    await watcher.close();
  }

  expectedScreenshots.addAll(watcher.requestedScreenshots);
  if (expectedScreenshots.isEmpty) {
    throw StateError('No screenshot checkpoints were received from the app.');
  }
  final missed = expectedScreenshots.difference(watcher.capturedScreenshots);
  if (missed.isNotEmpty) {
    throw StateError(
      'No full-device screenshot was captured for: ${missed.join(', ')}',
    );
  }
}

final _outputDirectory = Directory(_screenshotDirectory());

String _screenshotDirectory() {
  final configured = Platform.environment['SINGBOOK_SCREENSHOT_DIR']?.trim();
  if (configured == null || configured.isEmpty) {
    return path.join(Directory.current.path, 'artifacts', 'singbook-e2e');
  }
  return path.isAbsolute(configured)
      ? path.normalize(configured)
      : path.normalize(path.join(Directory.current.path, configured));
}

String? _safeName(String name) {
  final safe = name
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
  return safe.isEmpty ? null : safe;
}

class _NativeScreenshotWatcher {
  _NativeScreenshotWatcher(this._process, this.serial);

  final Process _process;
  final String serial;
  final requestedScreenshots = <String>{};
  final capturedScreenshots = <String>{};
  final _pending = <Future<void>>[];
  late final StreamSubscription<String> _subscription;
  String? _failure;
  var _closed = false;

  static Future<_NativeScreenshotWatcher> start() async {
    final serial = await _resolveSerial();
    final clearLog = await Process.run(_adbExecutable(), [
      '-s',
      serial,
      'logcat',
      '-c',
    ]);
    if (clearLog.exitCode != 0) {
      throw StateError(
        'Could not clear stale adb logcat markers: ${clearLog.stderr}',
      );
    }
    final process = await Process.start(_adbExecutable(), [
      '-s',
      serial,
      'logcat',
      '-v',
      'brief',
      '-s',
      'flutter:I',
    ]);
    unawaited(process.stderr.drain<void>());
    final watcher = _NativeScreenshotWatcher(process, serial);
    watcher._subscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          watcher._onLine,
          onError: (Object error) {
            watcher._failure ??= 'adb logcat failed: $error';
          },
        );
    return watcher;
  }

  void _onLine(String line) {
    final match = RegExp(
      r'SINGBOOK_E2E_CAPTURE:([A-Za-z0-9._-]+)',
    ).firstMatch(line);
    if (match == null) return;
    final name = _safeName(match.group(1)!);
    if (name == null || capturedScreenshots.contains(name)) return;
    requestedScreenshots.add(name);
    final capture = _capture(name);
    _pending.add(capture);
  }

  Future<void> _capture(String name) async {
    try {
      final window = await Process.run(
        _adbExecutable(),
        ['-s', serial, 'shell', 'dumpsys', 'window'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (window.exitCode != 0 ||
          !RegExp(
            r'mCurrentFocus=.*org\.freevia\.singbook(?:[/\s}]|$)',
          ).hasMatch(window.stdout as String)) {
        throw StateError('org.freevia.singbook is not the focused window');
      }

      final remotePath = '/sdcard/singbook-e2e-$name.png';
      final screen = await Process.run(
        _adbExecutable(),
        ['-s', serial, 'shell', 'screencap', '-p', remotePath],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (screen.exitCode != 0) {
        throw StateError('adb screencap failed: ${screen.stderr}');
      }
      final destination = File(
        path.join(_outputDirectory.path, '$name-device.png'),
      );
      await _outputDirectory.create(recursive: true);
      final pull = await Process.run(
        _adbExecutable(),
        ['-s', serial, 'pull', remotePath, destination.path],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      await Process.run(_adbExecutable(), [
        '-s',
        serial,
        'shell',
        'rm',
        '-f',
        remotePath,
      ]);
      if (pull.exitCode != 0) {
        throw StateError('adb pull failed: ${pull.stderr}');
      }
      final png = await destination
          .openRead(0, 8)
          .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
      if (png.length < 8 ||
          png[0] != 0x89 ||
          png[1] != 0x50 ||
          png[2] != 0x4e ||
          png[3] != 0x47) {
        throw StateError('adb returned an invalid PNG');
      }
      capturedScreenshots.add(name);
      stdout.writeln('Captured full-device checkpoint $name for $serial.');
    } catch (error) {
      _failure ??= '$name: $error';
      stderr.writeln('Full-device capture failed for $name: $error');
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    // Let logcat deliver markers that are still buffered in the pipe.
    await Future<void>.delayed(const Duration(milliseconds: 750));
    _process.kill();
    await _subscription.cancel();
    await Future.wait(_pending);
    if (_failure != null) throw StateError(_failure!);
  }
}

/// The device whose logcat is cleared and captured. An explicit
/// SINGBOOK_ADB_SERIAL / ANDROID_SERIAL always wins; otherwise the single
/// attached device is used, and several attached devices are refused instead of
/// clearing the logs of the wrong one.
Future<String> _resolveSerial() async {
  final configured =
      Platform.environment['SINGBOOK_ADB_SERIAL'] ??
      Platform.environment['ANDROID_SERIAL'];
  if (configured != null && configured.trim().isNotEmpty) {
    return configured.trim();
  }
  final listing = await Process.run(_adbExecutable(), ['devices']);
  final devices = listing.exitCode != 0
      ? <String>[]
      : [
          for (final line in const LineSplitter().convert(
            listing.stdout as String,
          ))
            if (RegExp(r'^(\S+)\s+device').firstMatch(line) case final m?)
              m.group(1)!,
        ];
  if (devices.length > 1) {
    throw StateError(
      'Several adb devices are attached (${devices.join(', ')}); set '
      'SINGBOOK_ADB_SERIAL so the right device is used.',
    );
  }
  return devices.isEmpty ? 'emulator-5554' : devices.single;
}

String _adbExecutable() {
  if (!Platform.isWindows) return 'adb';
  final sdk =
      Platform.environment['ANDROID_SDK_ROOT'] ??
      Platform.environment['ANDROID_HOME'] ??
      (Platform.environment['LOCALAPPDATA'] == null
          ? null
          : path.join(Platform.environment['LOCALAPPDATA']!, 'Android', 'Sdk'));
  return sdk == null ? 'adb' : path.join(sdk, 'platform-tools', 'adb.exe');
}
