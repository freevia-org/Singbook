import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serializes fullscreen changes so a late enter cannot outlive an exit.
class PlayerFullScreen {
  static const _channel = MethodChannel('org.freevia.singbook/fullscreen');
  Future<void> _pending = Future<void>.value();
  bool _disposed = false;
  String? _requestedMode;

  void listenForNativeToggle(VoidCallback onToggle, {VoidCallback? onExit}) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      _channel.setMethodCallHandler((call) async {
        if (_disposed) return;
        if (call.method == 'toggleRequested') onToggle();
        if (call.method == 'exited') onExit?.call();
      });
    }
  }

  void setEnabled(bool enabled) {
    // Keep the existing explicit-fullscreen API for callers that only control
    // the optional lyrics-only mode. The shell uses setReaderState so Android
    // can keep its navigation bar hidden throughout the reader route.
    if (_disposed) return;
    final mode = enabled ? 'fullscreen' : 'inactive';
    if (_requestedMode == mode) return;
    _requestedMode = mode;
    _enqueue(mode, legacyFullscreenEnabled: enabled);
  }

  void setReaderState({required bool active, required bool fullScreen}) {
    if (_disposed) return;
    final mode = active ? (fullScreen ? 'fullscreen' : 'reader') : 'inactive';
    if (_requestedMode == mode) return;
    final restoreOtherPlatformUi =
        _requestedMode == 'fullscreen' && mode != 'fullscreen';
    _requestedMode = mode;
    _enqueue(mode, restoreOtherPlatformUi: restoreOtherPlatformUi);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      _channel.setMethodCallHandler(null);
    }
    _requestedMode = 'inactive';
    _enqueue('inactive', legacyFullscreenEnabled: false);
  }

  void _enqueue(
    String mode, {
    bool? legacyFullscreenEnabled,
    bool restoreOtherPlatformUi = false,
  }) {
    _pending = _pending
        .then((_) async {
          if (kIsWeb) return;
          final shouldUpdateOtherPlatformUi =
              mode == 'fullscreen' ||
              legacyFullscreenEnabled != null ||
              restoreOtherPlatformUi;
          switch (defaultTargetPlatform) {
            case TargetPlatform.android:
              // Flutter's immersive SystemUiMode is ignored at target SDK 36.
              if (legacyFullscreenEnabled != null) {
                await _channel.invokeMethod<void>(
                  'setEnabled',
                  legacyFullscreenEnabled,
                );
              } else {
                await _channel.invokeMethod<void>('setMode', mode);
              }
            case TargetPlatform.macOS:
            case TargetPlatform.windows:
            case TargetPlatform.linux:
              if (shouldUpdateOtherPlatformUi) {
                await _channel.invokeMethod<void>(
                  'setEnabled',
                  mode == 'fullscreen',
                );
              }
            case TargetPlatform.iOS:
              if (shouldUpdateOtherPlatformUi) {
                await SystemChrome.setEnabledSystemUIMode(
                  mode == 'fullscreen'
                      ? SystemUiMode.immersiveSticky
                      : SystemUiMode.edgeToEdge,
                );
              }
            default:
              // Platforms without a native runner retain the reader layout.
              break;
          }
        })
        .catchError((Object error) {
          debugPrint('Player fullscreen unavailable: $error');
        });
  }
}
