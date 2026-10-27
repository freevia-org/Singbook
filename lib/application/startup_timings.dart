import 'package:flutter/foundation.dart';

/// Opt-in stage durations only: never library paths, queries, accounts or data.
class StartupTimings {
  static final _clock = Stopwatch();
  static bool _enabled = false;

  static void start(List<String> arguments) {
    _enabled = arguments.contains('--startup-timings');
    if (_enabled) {
      _clock.start();
      mark('dart_entry');
    }
  }

  static void mark(String stage) {
    if (_enabled) {
      debugPrint('Singbook startup: $stage ${_clock.elapsedMilliseconds}ms');
    }
  }
}
