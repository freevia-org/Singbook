import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the display on while a song plays, so a singer reading from the
/// screen is not interrupted by the device timeout.
abstract class ScreenAwake {
  Future<void> enable();
  Future<void> disable();
}

/// [ScreenAwake] backed by the `wakelock_plus` plugin.
class WakelockScreenAwake implements ScreenAwake {
  const WakelockScreenAwake();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}

ScreenAwake _defaultScreenAwake = const WakelockScreenAwake();

/// The wake lock the player uses unless it is given one.
ScreenAwake get defaultScreenAwake => _defaultScreenAwake;

/// Replaces the default wake lock; tests pass a fake and restore the original.
@visibleForTesting
set defaultScreenAwake(ScreenAwake value) => _defaultScreenAwake = value;
