import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:singbook/application/youtube_music_consent_entry.dart';
import 'package:singbook/providers/youtube_music_session.dart';

/// Deliberately contains no upstream URL, browser error text or cookie value.
class LocalYoutubeSessionException implements Exception {
  const LocalYoutubeSessionException(this.code);
  final String code;
}

abstract interface class LocalYoutubeBrowser {
  Future<Map<String, String>> cookies();
  Future<void> clearCookies();
  Future<bool> review(Uri entry, Duration timeout);
  Future<void> close();
}

bool localYoutubeUrlAllowed(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      !uri.hasPort &&
      {'music.youtube.com', 'consent.youtube.com'}.contains(uri.host);
}

/// A rendered chooser is recorded separately from an anonymous Music return.
/// Google may legitimately decide not to show a chooser in this browser. That
/// return is not evidence that a person made a choice; cookies still must exist
/// and live provider probes must pass before reporting source health.
class LocalYoutubeNavigation {
  String url = 'about:blank';
  bool sawDecision = false;
  bool entryRequested = false, musicLoaded = false;
  void start(Uri entry) {
    if (!localYoutubeUrlAllowed(entry.toString()) ||
        entry.host != 'consent.youtube.com' ||
        entry.path != '/m') {
      throw const LocalYoutubeSessionException('invalid_consent_entry');
    }
    entryRequested = true;
  }

  bool get atMusic => Uri.tryParse(url)?.host == 'music.youtube.com';
  bool get canCapture =>
      entryRequested && musicLoaded && atMusic && localYoutubeUrlAllowed(url);
  void loaded() {
    if (localYoutubeUrlAllowed(url) &&
        Uri.parse(url).host == 'consent.youtube.com' &&
        Uri.parse(url).path == '/m') {
      sawDecision = true;
    }
    if (atMusic && localYoutubeUrlAllowed(url)) musicLoaded = true;
  }
}

/// Chrome applies URL matching first; this is an additional bridge boundary.
Map<String, String> localYoutubeCookies(List<dynamic> cookies, DateTime now) {
  final values = <String, String>{};
  for (final raw in cookies) {
    if (raw is! Map) continue;
    final name = raw['name'], value = raw['value'];
    final expires = raw['expires'];
    if (!{'SOCS', 'CONSENT'}.contains(name) ||
        value is! String ||
        !{
          '.youtube.com',
          'youtube.com',
          'music.youtube.com',
          '.music.youtube.com',
        }.contains(raw['domain']) ||
        raw['path'] != '/' ||
        (expires is num &&
            expires > 0 &&
            expires <= now.millisecondsSinceEpoch / 1000)) {
      continue;
    }
    values[name as String] = value;
  }
  final validated = YoutubeMusicSession()..setConsentCookies(values);
  return {
    for (final name in ['SOCS', 'CONSENT'])
      if (validated.cookieHeader != null &&
          validated.cookieHeader!
              .split('; ')
              .any((c) => c.startsWith('$name=')))
        name: values[name]!,
  };
}

List<String> localYoutubeProxyArguments(Map<String, String> env) {
  final raw =
      [
            'HTTPS_PROXY',
            'https_proxy',
            'HTTP_PROXY',
            'http_proxy',
            'ALL_PROXY',
            'all_proxy',
          ]
          .map((name) => env[name])
          .whereType<String>()
          .where((v) => v.isNotEmpty)
          .firstOrNull;
  if (raw == null) return const [];
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      !{'http', 'https', 'socks5'}.contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      !{'', '/'}.contains(uri.path)) {
    throw const LocalYoutubeSessionException('unsupported_proxy');
  }
  return [
    '--proxy-server=${Uri(scheme: uri.scheme, host: uri.host, port: uri.hasPort ? uri.port : null)}',
  ];
}

/// Exact keys for scoped deletion, without retaining values or account cookies.
List<Map<String, dynamic>> localYoutubeCookieDeletions(List<dynamic> cookies) =>
    [
      for (final raw in cookies)
        if (raw is Map &&
            {'SOCS', 'CONSENT'}.contains(raw['name']) &&
            {
              '.youtube.com',
              'youtube.com',
              'music.youtube.com',
              '.music.youtube.com',
              'consent.youtube.com',
              '.consent.youtube.com',
            }.contains(raw['domain']) &&
            raw['path'] == '/')
          {
            'name': raw['name'],
            'domain': raw['domain'],
            'path': raw['path'],
            if (raw['partitionKey'] is Map) 'partitionKey': raw['partitionKey'],
          },
    ];

/// A separate browser-owned cookie jar, outside the repository. No normal
/// Chrome/Edge profile is opened; no portable cookie jar is exported or imported.
class LocalYoutubeSession {
  LocalYoutubeSession({
    Directory? directory,
    String? browserExecutable,
    this.openBrowser,
  }) : directory = directory ?? defaultDirectory(),
       browserExecutable = browserExecutable ?? findBrowser();

  final Directory directory;
  final String? browserExecutable;
  final Future<LocalYoutubeBrowser> Function(bool interactive)? openBrowser;
  File get _marker => File('${directory.path}/maintenance-profile.json');

  static Directory defaultDirectory() {
    final env = Platform.environment;
    final base = Platform.isWindows ? env['LOCALAPPDATA'] : env['HOME'];
    if (base == null || base.isEmpty) {
      throw const LocalYoutubeSessionException('local_data_directory_missing');
    }
    return Directory(
      Platform.isWindows
          ? '$base/Freevia/SingbookMaintenance/YouTubeMusic'
          : Platform.isMacOS
          ? '$base/Library/Application Support/Freevia/SingbookMaintenance/YouTubeMusic'
          : '${env['XDG_DATA_HOME'] ?? '$base/.local/share'}/freevia/singbook-maintenance/youtube-music',
    );
  }

  static String? findBrowser() {
    final env = Platform.environment;
    final candidates = Platform.isWindows
        ? [
            '${env['ProgramFiles']}/Google/Chrome/Application/chrome.exe',
            '${env['ProgramFiles(x86)']}/Microsoft/Edge/Application/msedge.exe',
            '${env['LOCALAPPDATA']}/Google/Chrome/Application/chrome.exe',
          ]
        : Platform.isMacOS
        ? [
            '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
            '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
          ]
        : [
            '/usr/bin/google-chrome',
            '/usr/bin/chromium',
            '/usr/bin/chromium-browser',
          ];
    return candidates.where((p) => File(p).existsSync()).firstOrNull;
  }

  Future<bool> _prepare({required bool create}) async {
    if (!await directory.exists()) {
      if (!create) return false;
      await directory.create(recursive: true);
      if (!Platform.isWindows) {
        final result = await Process.run('chmod', ['700', directory.path]);
        if (result.exitCode != 0) {
          throw const LocalYoutubeSessionException('profile_permissions');
        }
      }
      await _writeMarker(false);
    }
    if (!await _marker.exists()) {
      throw const LocalYoutubeSessionException('foreign_profile_refused');
    }
    return true;
  }

  Future<bool> _hasSession() async {
    try {
      final value = jsonDecode(await _marker.readAsString());
      if (value is! Map || value['schemaVersion'] != 1) {
        throw const LocalYoutubeSessionException('invalid_profile_marker');
      }
      return value['sessionCaptured'] == true;
    } on LocalYoutubeSessionException {
      rethrow;
    } catch (_) {
      throw const LocalYoutubeSessionException('invalid_profile_marker');
    }
  }

  Future<void> _writeMarker(
    bool captured, {
    bool choicePagePresented = false,
  }) => _marker.writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'sessionCaptured': captured,
      'choicePagePresented': captured && choicePagePresented,
    }),
    flush: true,
  );

  Future<YoutubeMusicSession> restore() async {
    final session = YoutubeMusicSession();
    if (!await _prepare(create: false) || !await _hasSession()) return session;
    return _withBrowser(
      interactive: false,
      action: (browser) async {
        session.setConsentCookies(await browser.cookies());
        if (!session.hasConsent) await _writeMarker(false);
        return session;
      },
    );
  }

  Future<YoutubeMusicSession> consent({
    http.Client? entryClient,
    Duration timeout = const Duration(minutes: 5),
    void Function(String)? onStatus,
  }) async {
    await _prepare(create: true);
    // The resolver is anonymous even when this dedicated profile has cookies.
    final entry = await resolveYoutubeMusicConsentEntry(client: entryClient);
    return _withBrowser(
      interactive: true,
      action: (browser) async {
        var completed = false;
        try {
          await _writeMarker(false);
          await browser.clearCookies();
          onStatus?.call(
            'Choose your cookie preference in the dedicated Google window. Do not sign in.',
          );
          final choicePresented = await browser.review(entry, timeout);
          final session = YoutubeMusicSession()
            ..setConsentCookies(await browser.cookies());
          if (!session.hasConsent) {
            throw const LocalYoutubeSessionException('decision_cookie_missing');
          }
          await _writeMarker(true, choicePagePresented: choicePresented);
          completed = true;
          onStatus?.call(
            choicePresented
                ? 'Google consent page visited; YouTube Music browser session saved locally.'
                : 'Google did not request a choice. Anonymous YouTube Music browser session saved locally.',
          );
          return session;
        } finally {
          if (!completed) {
            try {
              await _writeMarker(false);
            } finally {
              await browser.clearCookies().catchError((_) {});
            }
          }
        }
      },
    );
  }

  Future<void> clear() async {
    if (!await _prepare(create: false)) return;
    await _withBrowser(
      interactive: false,
      beforeOpen: () => _writeMarker(false),
      action: (browser) async {
        await browser.clearCookies();
        if ((await browser.cookies()).isNotEmpty) {
          throw const LocalYoutubeSessionException('clear_failed');
        }
      },
    );
  }

  Future<T> _withBrowser<T>({
    required bool interactive,
    Future<void> Function()? beforeOpen,
    required Future<T> Function(LocalYoutubeBrowser) action,
  }) async {
    final executable = browserExecutable;
    final lock = await File(
      '${directory.path}/maintenance.lock',
    ).open(mode: FileMode.append);
    LocalYoutubeBrowser? browser;
    try {
      try {
        await lock.lock(FileLock.exclusive);
      } catch (_) {
        throw const LocalYoutubeSessionException('profile_busy');
      }
      await beforeOpen?.call();
      if (executable == null && openBrowser == null) {
        throw const LocalYoutubeSessionException('chrome_or_edge_required');
      }
      browser = openBrowser != null
          ? await openBrowser!(interactive)
          : await _OwnedBrowser.start(
              executable!,
              Directory('${directory.path}/browser'),
              interactive: interactive,
            );
      return await action(browser);
    } on LocalYoutubeSessionException {
      rethrow;
    } catch (_) {
      throw const LocalYoutubeSessionException('browser_session_failed');
    } finally {
      try {
        await browser?.close();
      } finally {
        await lock.close();
      }
    }
  }
}

class _OwnedBrowser implements LocalYoutubeBrowser {
  _OwnedBrowser(this.process, this.cdp, this.sessionId, this.targetId);
  final Process process;
  final _Cdp cdp;
  final String sessionId, targetId;

  static Future<_OwnedBrowser> start(
    String executable,
    Directory profile, {
    required bool interactive,
  }) async {
    await profile.create(recursive: true);
    final portFile = File('${profile.path}/DevToolsActivePort');
    final previous = await portFile.exists()
        ? await portFile.readAsString()
        : null;
    final process = await Process.start(executable, [
      '--user-data-dir=${profile.path}',
      '--remote-debugging-address=127.0.0.1',
      '--remote-debugging-port=0',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-sync',
      '--disable-background-mode',
      ...localYoutubeProxyArguments(Platform.environment),
      if (!interactive) '--headless=new',
      '--new-window',
      'about:blank',
    ]);
    unawaited(process.stdout.drain<void>());
    unawaited(process.stderr.drain<void>());
    _Cdp? cdp;
    try {
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (DateTime.now().isBefore(deadline)) {
        if (await portFile.exists()) {
          final current = await portFile.readAsString();
          if (current != previous) {
            final lines = current.trim().split('\n');
            final port = int.tryParse(lines.first.trim());
            if (lines.length == 2 &&
                port != null &&
                port > 0 &&
                port < 65536 &&
                RegExp(
                  r'^/devtools/browser/[A-Za-z0-9-]+$',
                ).hasMatch(lines[1].trim())) {
              cdp = await _Cdp.connect(
                'ws://127.0.0.1:$port${lines[1].trim()}',
              );
              break;
            }
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (cdp == null) {
        throw const LocalYoutubeSessionException('browser_start_timeout');
      }
      final targets = await cdp.send('Target.getTargets');
      final page = (targets['targetInfos'] as List).cast<Map>().firstWhere(
        (p) => p['type'] == 'page' && p['url'] == 'about:blank',
      );
      final target = page['targetId'] as String;
      final attached = await cdp.send('Target.attachToTarget', {
        'targetId': target,
        'flatten': true,
      });
      return _OwnedBrowser(
        process,
        cdp,
        attached['sessionId'] as String,
        target,
      );
    } catch (_) {
      if (cdp != null) {
        await cdp.send('Browser.close').catchError((_) => <String, dynamic>{});
        await cdp.close();
      }
      process
          .kill(); // Only the process just launched for our separate profile.
      rethrow;
    }
  }

  Future<Map<String, dynamic>> send(
    String method, [
    Map<String, dynamic> params = const {},
  ]) => cdp.send(method, params, sessionId);

  @override
  Future<Map<String, String>> cookies() async {
    final result = await send('Network.getCookies', {
      'urls': ['https://music.youtube.com/'],
    });
    return localYoutubeCookies(result['cookies'] as List, DateTime.now());
  }

  @override
  Future<void> clearCookies() async {
    final result = await send('Network.getCookies', {
      'urls': ['https://music.youtube.com/', 'https://consent.youtube.com/'],
    });
    for (final key in localYoutubeCookieDeletions(result['cookies'] as List)) {
      // Delete the exact stored domain/path; URL-only deletion can leave a
      // parent-domain cookie behind in Chromium.
      await send('Network.deleteCookies', key);
    }
  }

  @override
  Future<bool> review(Uri entry, Duration timeout) async {
    final done = Completer<void>();
    final navigation = LocalYoutubeNavigation();
    final handlers = <Future<void>>{};
    void fail(String code) {
      if (!done.isCompleted) {
        done.completeError(LocalYoutubeSessionException(code));
      }
    }

    Future<void> event(Map<String, dynamic> event) async {
      final params = (event['params'] as Map?)?.cast<String, dynamic>() ?? {};
      if (event['method'] == 'Target.targetCreated') {
        final target = params['targetInfo'] as Map;
        if (target['type'] == 'page' && target['targetId'] != targetId) {
          await cdp.send('Target.closeTarget', {
            'targetId': target['targetId'],
          });
        }
      }
      if (event['sessionId'] != sessionId) return;
      switch (event['method']) {
        case 'Fetch.requestPaused':
          final request = params['request'] as Map;
          final allowed = localYoutubeUrlAllowed(request['url'] as String);
          await send(allowed ? 'Fetch.continueRequest' : 'Fetch.failRequest', {
            'requestId': params['requestId'],
            if (!allowed) 'errorReason': 'BlockedByClient',
          });
          if (!allowed) fail('navigation_blocked');
        case 'Fetch.authRequired':
          await send('Fetch.continueWithAuth', {
            'requestId': params['requestId'],
            'authChallengeResponse': {'response': 'CancelAuth'},
          });
          fail('authentication_not_supported');
        case 'Page.frameNavigated':
          final frame = params['frame'] as Map;
          if (frame['parentId'] == null) {
            navigation.url = frame['url'] as String;
            if (!localYoutubeUrlAllowed(navigation.url)) {
              fail('navigation_blocked');
            }
          }
        case 'Page.loadEventFired':
          navigation.loaded();
          if (navigation.canCapture && !done.isCompleted) done.complete();
        case 'Inspector.detached':
          fail('consent_cancelled');
      }
    }

    final subscription = cdp.events.listen((eventData) {
      late final Future<void> pending;
      pending = event(eventData)
          .catchError((_) {
            fail('browser_session_failed');
          })
          .whenComplete(() => handlers.remove(pending));
      handlers.add(pending);
    }, onDone: () => fail('consent_cancelled'));
    // Install an error listener immediately; navigation can fail before await.
    final completion = done.future.timeout(
      timeout,
      onTimeout: () =>
          throw const LocalYoutubeSessionException('consent_timeout'),
    );
    unawaited(completion.catchError((_) {}));
    try {
      await send('Page.enable');
      await cdp.send('Target.setDiscoverTargets', {'discover': true});
      await cdp.send('Browser.setDownloadBehavior', {'behavior': 'deny'});
      await send('Fetch.enable', {
        'patterns': [
          {'resourceType': 'Document', 'requestStage': 'Request'},
        ],
        'handleAuthRequests': true,
      });
      navigation.start(entry);
      final result = await send('Page.navigate', {'url': entry.toString()});
      if (result['errorText'] != null) fail('consent_navigation_failed');
      await completion;
      return navigation.sawDecision;
    } finally {
      await subscription.cancel();
      await Future.wait(handlers.toList());
    }
  }

  @override
  Future<void> close() async {
    await cdp.send('Browser.close').catchError((_) => <String, dynamic>{});
    await cdp.close();
    try {
      await process.exitCode.timeout(const Duration(seconds: 5));
    } catch (_) {
      process.kill();
    }
  }
}

/// Minimal local protocol client: no evaluation, DOM inspection or script
/// injection. Protocol errors are replaced by stable, value-free codes.
class _Cdp {
  _Cdp(this.socket) {
    socket.listen(
      (raw) {
        if (raw is! String || raw.length > 2 * 1024 * 1024) return;
        final message = (jsonDecode(raw) as Map).cast<String, dynamic>();
        final id = message['id'];
        if (id is int) {
          final pending = _pending.remove(id);
          if (message['error'] != null) {
            pending?.completeError(
              const LocalYoutubeSessionException('browser_protocol_failed'),
            );
          } else {
            pending?.complete(
              (message['result'] as Map).cast<String, dynamic>(),
            );
          }
        } else {
          _events.add(message);
        }
      },
      onError: (_) => _closed(),
      onDone: _closed,
    );
  }
  final WebSocket socket;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  int _next = 0;
  Stream<Map<String, dynamic>> get events => _events.stream;
  static Future<_Cdp> connect(String url) async =>
      _Cdp(await WebSocket.connect(url).timeout(const Duration(seconds: 5)));
  Future<Map<String, dynamic>> send(
    String method, [
    Map<String, dynamic> params = const {},
    String? sessionId,
  ]) async {
    final id = ++_next;
    final done = Completer<Map<String, dynamic>>();
    _pending[id] = done;
    try {
      socket.add(
        jsonEncode({
          'id': id,
          'method': method,
          'params': params,
          'sessionId': ?sessionId,
        }),
      );
      return await done.future.timeout(const Duration(seconds: 8));
    } finally {
      _pending.remove(id);
    }
  }

  void _closed() {
    for (final done in _pending.values) {
      done.completeError(const LocalYoutubeSessionException('browser_closed'));
    }
    _pending.clear();
    if (!_events.isClosed) unawaited(_events.close());
  }

  Future<void> close() async {
    await socket.close();
    _closed();
  }
}
