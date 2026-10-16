import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../tool/src/local_youtube_session.dart';

http.Client entry() => MockClient((request) async {
  expect(request.url.toString(), 'https://music.youtube.com/');
  expect(request.headers.containsKey('Cookie'), isFalse);
  return http.Response(
    '',
    302,
    headers: {
      'location': Uri.https('consent.youtube.com', '/m', {
        'continue': 'https://music.youtube.com/?cbrd=1',
        'gl': 'BG',
        'hl': 'bg',
        'm': '0',
        'pc': 'ytm',
        'cm': '2',
        'src': '1',
      }).toString(),
    },
  );
});

class FakeBrowser implements LocalYoutubeBrowser {
  Map<String, String> jar = {};
  bool cancel = false,
      failClear = false,
      failClose = false,
      presentsChoice = true;
  Future<void> Function()? afterReview;
  int closes = 0, reviews = 0;
  @override
  Future<Map<String, String>> cookies() async => Map.of(jar);
  @override
  Future<void> clearCookies() async {
    if (failClear) throw const LocalYoutubeSessionException('clear_failed');
    jar.clear();
  }

  @override
  Future<bool> review(Uri url, Duration timeout) async {
    expect(url.host, 'consent.youtube.com');
    reviews++;
    jar = {'SOCS': 'synthetic-decision'};
    await afterReview?.call();
    if (cancel) throw const LocalYoutubeSessionException('consent_cancelled');
    return presentsChoice;
  }

  @override
  Future<void> close() async {
    closes++;
    if (failClose) throw const LocalYoutubeSessionException('close_failed');
  }
}

void main() {
  test(
    'validated entry required; chooser presentation and anonymous return differ',
    () {
      for (final url in [
        'https://accounts.google.com/',
        'http://music.youtube.com/',
        'https://user@music.youtube.com/',
        'https://music.youtube.com:8443/',
        'https://music.youtube.com.evil.test/',
      ]) {
        expect(localYoutubeUrlAllowed(url), isFalse);
      }
      final state = LocalYoutubeNavigation();
      state.url = 'https://music.youtube.com/';
      state.loaded();
      expect(state.canCapture, isFalse);
      state.start(Uri.parse('https://consent.youtube.com/m?gl=BG'));
      state.url = 'https://consent.youtube.com/help';
      state.loaded();
      state.url = 'https://music.youtube.com/';
      state.loaded();
      expect(state.canCapture, isTrue);
      expect(state.sawDecision, isFalse);
      state.url = 'https://consent.youtube.com/m?gl=BG';
      state.loaded();
      state.url = 'https://music.youtube.com/?cbrd=1';
      state.loaded();
      expect(state.canCapture, isTrue);
    },
  );

  test(
    'bridge drops auth, foreign-host, wrong-path, expired and invalid cookies',
    () {
      Map<String, Object> cookie(
        String name,
        String value, {
        String domain = '.youtube.com',
        String path = '/',
        num expires = -1,
      }) => {
        'name': name,
        'value': value,
        'domain': domain,
        'path': path,
        'expires': expires,
      };
      final now = DateTime.utc(2026, 10, 16);
      expect(
        localYoutubeCookies([
          cookie('SOCS', 'synthetic-good'),
          cookie('SID', 'synthetic-auth'),
          cookie('CONSENT', 'synthetic-host', domain: 'consent.youtube.com'),
          cookie('CONSENT', 'synthetic-path', path: '/watch'),
          cookie(
            'CONSENT',
            'synthetic-expired',
            expires: now.millisecondsSinceEpoch / 1000 - 1,
          ),
          cookie('CONSENT', 'invalid; cookie'),
          cookie('CONSENT', 'synthetic-good=='),
        ], now),
        {'SOCS': 'synthetic-good', 'CONSENT': 'synthetic-good=='},
      );
    },
  );

  test('proxy settings preserved without exposing proxy credentials', () {
    expect(localYoutubeProxyArguments({}), isEmpty);
    expect(
      localYoutubeProxyArguments({'HTTPS_PROXY': 'http://proxy.test:8080'}),
      ['--proxy-server=http://proxy.test:8080'],
    );
    expect(
      localYoutubeProxyArguments({
        'HTTPS_PROXY': '',
        'https_proxy': 'http://lowercase.test:8080',
        'ALL_PROXY': 'socks5://fallback.test:1080',
      }),
      ['--proxy-server=http://lowercase.test:8080'],
    );
    for (final name in ['ALL_PROXY', 'all_proxy']) {
      expect(
        localYoutubeProxyArguments({name: 'socks5://fallback.test:1080'}),
        ['--proxy-server=socks5://fallback.test:1080'],
      );
    }
    for (final value in [
      'http://user:secret@proxy.test:8080',
      'http://proxy.test/?secret=x',
      'file:///tmp/proxy',
      'not a proxy',
    ]) {
      expect(
        () => localYoutubeProxyArguments({'HTTPS_PROXY': value}),
        throwsA(
          isA<LocalYoutubeSessionException>().having(
            (e) => e.code,
            'code',
            'unsupported_proxy',
          ),
        ),
      );
    }
  });

  test(
    'clear targets exact parent-domain keys and excludes unrelated cookies',
    () {
      expect(
        localYoutubeCookieDeletions([
          {
            'name': 'SOCS',
            'value': 'synthetic-private',
            'domain': '.youtube.com',
            'path': '/',
          },
          {'name': 'CONSENT', 'domain': 'consent.youtube.com', 'path': '/'},
          {'name': 'SID', 'domain': '.youtube.com', 'path': '/'},
          {'name': 'SOCS', 'domain': 'foreign.test', 'path': '/'},
          {'name': 'SOCS', 'domain': '.youtube.com', 'path': '/unrelated'},
        ]),
        [
          {'name': 'SOCS', 'domain': '.youtube.com', 'path': '/'},
          {'name': 'CONSENT', 'domain': 'consent.youtube.com', 'path': '/'},
        ],
      );
    },
  );

  group('owned profile lifecycle', () {
    late Directory temporary, profile;
    late FakeBrowser browser;
    late List<bool> openings;
    late LocalYoutubeSession session;
    setUp(() async {
      temporary = await Directory.systemTemp.createTemp(
        'singbook-local-session-test-',
      );
      profile = Directory('${temporary.path}/owned-profile');
      browser = FakeBrowser();
      openings = [];
      session = LocalYoutubeSession(
        directory: profile,
        openBrowser: (interactive) async {
          openings.add(interactive);
          return browser;
        },
      );
    });
    tearDown(() async {
      final resolved = await temporary.resolveSymbolicLinks();
      final parent = await Directory.systemTemp.resolveSymbolicLinks();
      if (!resolved.startsWith(
        '$parent${Platform.pathSeparator}singbook-local-session-test-',
      )) {
        throw StateError(
          'Refusing cleanup outside the owned temporary test directory',
        );
      }
      await temporary.delete(recursive: true);
    });

    test(
      'fresh restore never opens a browser or makes an origin request',
      () async {
        expect((await session.restore()).hasConsent, isFalse);
        expect(openings, isEmpty);
        expect(await profile.exists(), isFalse);
      },
    );

    test('refuses an existing unmarked browser directory', () async {
      await profile.create();
      await expectLater(
        session.restore(),
        throwsA(
          isA<LocalYoutubeSessionException>().having(
            (e) => e.code,
            'code',
            'foreign_profile_refused',
          ),
        ),
      );
      expect(openings, isEmpty);
    });

    test(
      'completed session restores on a later invocation without exporting a jar',
      () async {
        expect(
          (await session.consent(entryClient: entry())).hasConsent,
          isTrue,
        );
        final marker = await File(
          '${profile.path}/maintenance-profile.json',
        ).readAsString();
        expect(jsonDecode(marker), {
          'schemaVersion': 1,
          'sessionCaptured': true,
          'choicePagePresented': true,
        });
        expect(marker.contains('synthetic-decision'), isFalse);
        final later = LocalYoutubeSession(
          directory: profile,
          openBrowser: (interactive) async {
            openings.add(interactive);
            return browser;
          },
        );
        expect((await later.restore()).hasConsent, isTrue);
        expect(openings, [true, false]);
        expect(browser.closes, 2);
      },
    );

    test('anonymous return records no presented choice', () async {
      browser.presentsChoice = false;
      final messages = <String>[];
      expect(
        (await session.consent(
          entryClient: entry(),
          onStatus: messages.add,
        )).hasConsent,
        isTrue,
      );
      final marker = jsonDecode(
        await File('${profile.path}/maintenance-profile.json').readAsString(),
      );
      expect(marker['sessionCaptured'], isTrue);
      expect(marker['choicePagePresented'], isFalse);
      expect(messages.last, contains('did not request a choice'));
    });

    test(
      'failed browser startup while clearing prevents later reuse',
      () async {
        await session.consent(entryClient: entry());
        final unavailable = LocalYoutubeSession(
          directory: profile,
          openBrowser: (_) async =>
              throw const LocalYoutubeSessionException('browser_start_timeout'),
        );
        await expectLater(
          unavailable.clear(),
          throwsA(isA<LocalYoutubeSessionException>()),
        );
        final count = openings.length;
        expect((await session.restore()).hasConsent, isFalse);
        expect(openings, hasLength(count));
      },
    );

    test(
      'cancelled review cannot restore a partially created cookie',
      () async {
        browser.cancel = true;
        await expectLater(
          session.consent(entryClient: entry()),
          throwsA(
            isA<LocalYoutubeSessionException>().having(
              (e) => e.code,
              'code',
              'consent_cancelled',
            ),
          ),
        );
        expect(browser.jar, isEmpty);
        expect((await session.restore()).hasConsent, isFalse);
        expect(openings, [true]);
        expect(browser.closes, 1);
      },
    );

    test(
      'clear prevents restoration; a failed native clear also disables reuse',
      () async {
        await session.consent(entryClient: entry());
        browser.failClear = true;
        await expectLater(
          session.clear(),
          throwsA(isA<LocalYoutubeSessionException>()),
        );
        expect((await session.restore()).hasConsent, isFalse);
        browser.failClear = false;
        await session.clear();
        expect(browser.jar, isEmpty);
        expect((await session.restore()).hasConsent, isFalse);
        expect(browser.closes, 3);
      },
    );

    test('failed marker write still clears partial decision cookies', () async {
      browser.afterReview = () async {
        await File('${profile.path}/maintenance-profile.json').delete();
        await Directory('${profile.path}/maintenance-profile.json').create();
      };
      await expectLater(
        session.consent(entryClient: entry()),
        throwsA(isA<LocalYoutubeSessionException>()),
      );
      expect(browser.jar, isEmpty);
      expect(browser.closes, 1);
    });

    test('failed browser close always releases the profile lock', () async {
      browser.failClose = true;
      await expectLater(
        session.consent(entryClient: entry()),
        throwsA(isA<LocalYoutubeSessionException>()),
      );
      browser.failClose = false;
      expect((await session.restore()).hasConsent, isTrue);
      expect(browser.closes, 2);
    });

    test(
      'expired native state disables saved marker and remains absent',
      () async {
        await session.consent(entryClient: entry());
        browser.jar.clear();
        expect((await session.restore()).hasConsent, isFalse);
        final count = openings.length;
        expect((await session.restore()).hasConsent, isFalse);
        expect(openings, hasLength(count));
      },
    );
  });
}
