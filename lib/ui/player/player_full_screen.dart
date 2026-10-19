import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serializes system-bar changes so a late enter cannot outlive an exit.
class PlayerFullScreen {
  static const _channel = MethodChannel('org.freevia.singbook/fullscreen');
  Future<void> _pending = Future<void>.value();
  bool _disposed = false;

  void setEnabled(bool enabled) {
    if (!_disposed) _enqueue(enabled);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _enqueue(false);
  }

  void _enqueue(bool enabled) {
    _pending = _pending
        .then((_) async {
          if (kIsWeb) return;
          switch (defaultTargetPlatform) {
            case TargetPlatform.android:
              // Flutter's immersive SystemUiMode is ignored at target SDK 36.
              await _channel.invokeMethod<void>('setEnabled', enabled);
            case TargetPlatform.iOS:
              await SystemChrome.setEnabledSystemUIMode(
                enabled
                    ? SystemUiMode.immersiveSticky
                    : SystemUiMode.edgeToEdge,
              );
            default:
              // Other platforms still gain the reader's distraction-free layout.
              break;
          }
        })
        .catchError((Object error) {
          debugPrint('Player system bars unavailable: $error');
        });
  }
}
