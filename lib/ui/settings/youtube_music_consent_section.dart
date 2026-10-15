import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../application/youtube_music_consent.dart';

/// Labels are supplied by the settings screen's localization boundary.
class YoutubeConsentLabels {
  const YoutubeConsentLabels({
    required this.title,
    required this.explanation,
    required this.connect,
    required this.saved,
    required this.clear,
    required this.instructions,
    required this.notReady,
    required this.navigationBlocked,
    required this.loadFailed,
    required this.clearFailed,
    required this.done,
    required this.retry,
  });
  final String title, explanation, connect, saved, clear, instructions;
  final String notReady,
      navigationBlocked,
      loadFailed,
      clearFailed,
      done,
      retry;
}

class YoutubeMusicConsentSection extends StatefulWidget {
  const YoutubeMusicConsentSection({
    super.key,
    required this.labels,
    required this.hasConsent,
    required this.onComplete,
    required this.onClear,
    this.openBrowser,
  });
  final YoutubeConsentLabels labels;
  final bool hasConsent;
  final Future<bool> Function() onComplete, onClear;
  final Future<bool?> Function(BuildContext, Future<bool> Function())?
  openBrowser;

  @override
  State<YoutubeMusicConsentSection> createState() =>
      _YoutubeMusicConsentSectionState();
}

class _YoutubeMusicConsentSectionState
    extends State<YoutubeMusicConsentSection> {
  bool _busy = false;
  bool? _saved;
  String? _error;

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = widget.openBrowser != null
          ? await widget.openBrowser!(context, widget.onComplete)
          : await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => YoutubeMusicConsentScreen(
                  labels: widget.labels,
                  onComplete: widget.onComplete,
                ),
              ),
            );
      if (!mounted) return;
      if (result == true) _saved = true;
    } catch (_) {
      if (mounted) _error = widget.labels.loadFailed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    var cleared = false;
    try {
      cleared = await widget.onClear();
    } catch (_) {
      /* Safe localized outcome. */
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _saved = false;
      if (!cleared) _error = widget.labels.clearFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final saved = _saved ?? widget.hasConsent;
    return Padding(
      key: const ValueKey('youtube-music-consent'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labels.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(labels.explanation),
          if (saved)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                labels.saved,
                key: const ValueKey('youtube-consent-saved'),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('youtube-consent-connect'),
                onPressed: _busy ? null : _connect,
                icon: const Icon(Icons.open_in_browser_rounded),
                label: Text(labels.connect),
              ),
              // Keep clear available even after a partially failed native clear.
              TextButton(
                key: const ValueKey('youtube-consent-clear'),
                onPressed: _busy ? null : _clear,
                child: Text(labels.clear),
              ),
              if (_busy)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A real, anonymous Google page. There are no JS channels, script injection,
/// automated choices, cookie fabrication, or embedded Google account login.
class YoutubeMusicConsentScreen extends StatefulWidget {
  const YoutubeMusicConsentScreen({
    super.key,
    required this.labels,
    required this.onComplete,
  });
  final YoutubeConsentLabels labels;
  final Future<bool> Function() onComplete;

  @override
  State<YoutubeMusicConsentScreen> createState() =>
      _YoutubeMusicConsentScreenState();
}

class _YoutubeMusicConsentScreenState extends State<YoutubeMusicConsentScreen> {
  WebViewController? _web;
  final _navigation = YoutubeMusicConsentNavigation();
  bool _atMusic = false, _busy = false;
  bool _blockedLoad = false;
  int _webEpoch = 0;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final epoch = ++_webEpoch;
    try {
      final web = WebViewController(
        onPermissionRequest: (request) {
          request.deny();
        },
      );
      await web.setJavaScriptMode(JavaScriptMode.unrestricted);
      await web.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (epoch != _webEpoch) return NavigationDecision.prevent;
            if (_blockedLoad) return NavigationDecision.prevent;
            if (isYoutubeMusicConsentUrl(request.url)) {
              return NavigationDecision.navigate;
            }
            if (request.isMainFrame && mounted) {
              setState(() {
                _atMusic = false;
                _error = widget.labels.navigationBlocked;
              });
            }
            return NavigationDecision.prevent;
          },
          onPageStarted: (url) {
            if (epoch != _webEpoch || !mounted) return;
            if (_blockedLoad) return;
            _navigation.started(url);
            // Android's pre-navigation callback does not cover every POST.
            // Stop an unexpected main-frame load before presenting a login.
            if (!isYoutubeMusicConsentUrl(url)) {
              _stopBlockedLoad();
              return;
            }
            if (mounted) {
              setState(() {
                _atMusic = false;
                _error = null;
              });
            }
          },
          onProgress: (value) {
            if (epoch == _webEpoch && mounted) {
              setState(() => _progress = value);
            }
          },
          onPageFinished: (url) {
            if (epoch != _webEpoch || !mounted) return;
            if (_blockedLoad) return;
            _navigation.finished(url);
            if (mounted) {
              setState(
                () => _atMusic = _error == null && _navigation.canFinish,
              );
            }
          },
          onWebResourceError: (error) {
            if (epoch != _webEpoch || !mounted) return;
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _atMusic = false;
                _error = widget.labels.loadFailed;
              });
            }
          },
          onHttpAuthRequest: (request) {
            request.onCancel();
          },
        ),
      );
      if (!mounted || epoch != _webEpoch) return;
      setState(() => _web = web);
      await web.loadRequest(Uri.parse('https://music.youtube.com/'));
    } catch (_) {
      if (mounted && epoch == _webEpoch) {
        setState(() => _error = widget.labels.loadFailed);
      }
    }
  }

  Future<void> _finish() async {
    if (!_atMusic || _busy) return;
    setState(() => _busy = true);
    var saved = false;
    try {
      final currentUrl = await _web?.currentUrl();
      if (currentUrl != null && isYoutubeMusicReturnUrl(currentUrl)) {
        saved = await widget.onComplete();
      }
    } catch (_) {
      /* No platform text. */
    }
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = widget.labels.notReady;
      });
    }
  }

  Future<void> _stopBlockedLoad() async {
    if (_blockedLoad) return;
    if (mounted) {
      setState(() {
        _blockedLoad = true;
        _atMusic = false;
        _error = widget.labels.navigationBlocked;
      });
    }
    try {
      // The public controller has no stopLoading API. Hide its platform view
      // immediately and replace its document, so no login form is usable.
      await _web?.loadHtmlString('<!doctype html><html><body></body></html>');
    } catch (_) {
      // The blocked page still cannot complete the consent flow.
    }
  }

  Future<void> _retry() async {
    _navigation.reset();
    setState(() {
      _web = null;
      _blockedLoad = false;
      _atMusic = false;
      _error = null;
      _progress = 0;
    });
    // A new controller also isolates any late blank-document callbacks from
    // the blocked view. The native consent jar remains shared with this app.
    await _initialize();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return Scaffold(
      appBar: AppBar(
        title: Text(labels.title),
        actions: [
          IconButton(
            tooltip: labels.retry,
            onPressed: _web == null ? null : _retry,
            icon: const Icon(Icons.refresh_rounded),
          ),
          TextButton(
            onPressed: _atMusic && !_busy ? _finish : null,
            child: Text(labels.done),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(labels.instructions),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            if (_progress < 100 || _busy)
              LinearProgressIndicator(value: _busy ? null : _progress / 100),
            Expanded(
              child: _web == null || _blockedLoad
                  ? const SizedBox.shrink()
                  : WebViewWidget(controller: _web!),
            ),
          ],
        ),
      ),
    );
  }
}
