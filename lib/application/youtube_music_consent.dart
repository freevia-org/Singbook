import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../providers/youtube_music_session.dart';

/// Anonymous Google consent state. Cookie values never enter app settings,
/// library documents, Drive sync, diagnostics, or the cloud maintenance job.
class YoutubeMusicConsent {
  YoutubeMusicConsent({
    YoutubeMusicSession? session,
    MethodChannel? channel,
    bool? supported,
  }) : session = session ?? YoutubeMusicSession(),
       _channel =
           channel ??
           const MethodChannel('org.freevia.singbook/youtube_music_session'),
       supported =
           supported ??
           (!kIsWeb &&
               {
                 TargetPlatform.android,
                 TargetPlatform.iOS,
               }.contains(defaultTargetPlatform));

  final YoutubeMusicSession session;
  final MethodChannel _channel;
  final bool supported;

  /// Supplied by the app shell; headless maintenance never opens a UI.
  Future<bool> Function()? onConsentRequired;
  Future<bool> requestConsent() async {
    if (!supported) return false;
    return await onConsentRequired?.call() ?? false;
  }

  int _epoch = 0;
  Future<bool>? _clearing;

  Future<bool> restore() => capture();

  /// Reads an existing decision from the native jar on launch or after Google's
  /// page returns to Music. A return without eligible cookies cannot succeed.
  Future<bool> capture() async {
    if (!supported) return false;
    final epoch = _epoch;
    final clearing = _clearing;
    if (clearing != null && !await clearing) return false;
    if (epoch != _epoch) return false;
    try {
      final values = await _channel
          .invokeMapMethod<String, String>('getConsentCookies')
          .timeout(const Duration(seconds: 5));
      if (epoch != _epoch) return false;
      session.setConsentCookies(values ?? const {});
      return session.hasConsent;
    } catch (_) {
      // Native/platform messages can contain URLs. Never log or export them.
      return false;
    }
  }

  Future<bool> clear() {
    _epoch++;
    session.clear();
    return _clearing ??= _clearNative().whenComplete(() => _clearing = null);
  }

  Future<bool> _clearNative() async {
    if (!supported) return false;
    try {
      await _channel
          .invokeMethod<void>('clearConsentCookies')
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Only Google's anonymous consent page and its YouTube Music return address
/// may navigate in the app. Account login, arbitrary links and plaintext fail.
bool isYoutubeMusicConsentUrl(String raw) {
  final url = Uri.tryParse(raw);
  return url != null &&
      url.scheme == 'https' &&
      url.userInfo.isEmpty &&
      (!url.hasPort || url.port == 443) &&
      {'music.youtube.com', 'consent.youtube.com'}.contains(url.host);
}

bool isYoutubeMusicReturnUrl(String raw) =>
    isYoutubeMusicConsentUrl(raw) && Uri.parse(raw).host == 'music.youtube.com';

/// Initial Music loads are not evidence of a Google consent decision. Only
/// a consent-page visit followed by the Music return can finish this flow.
class YoutubeMusicConsentNavigation {
  bool _sawConsent = false;
  bool canFinish = false;
  // A Music return can restore existing cookies without implying that a new
  // consent choice was presented. Native capture still requires real cookies.
  bool canRestoreSession = false;

  void reset() {
    _sawConsent = false;
    canFinish = false;
    canRestoreSession = false;
  }

  void started(String url) {
    canFinish = false;
    canRestoreSession = false;
  }

  void finished(String url) {
    // A server redirect through this host is not evidence that Google's
    // decision page was presented to the person using the app.
    if (isYoutubeMusicConsentUrl(url) &&
        Uri.parse(url).host == 'consent.youtube.com') {
      _sawConsent = true;
    }
    canRestoreSession = isYoutubeMusicReturnUrl(url);
    canFinish = _sawConsent && canRestoreSession;
  }
}
