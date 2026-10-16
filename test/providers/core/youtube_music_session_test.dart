import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/core/youtube_music.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/youtube_music_session.dart';

ProviderTransport transport(
  FutureOr<http.Response> Function(http.Request) fn,
) => ProviderTransport(
  client: MockClient((request) async => fn(request)),
  hostInterval: Duration.zero,
  timeout: const Duration(seconds: 2),
  maxRetries: 0,
);

http.Response homepage() => http.Response(
  '''<script>ytcfg.set({"INNERTUBE_CLIENT_VERSION":"fixture.1"});</script>''',
  200,
);

void main() {
  test(
    'consent recovery shares one review and retries with saved cookies',
    () async {
      final session = YoutubeMusicSession();
      final choice = Completer<bool>();
      var reviews = 0, homepages = 0;
      final t = transport((request) {
        if (request.url.path == '/') {
          homepages++;
          if (request.headers['cookie'] == null) {
            return http.Response(
              '',
              302,
              headers: {'location': 'https://consent.youtube.com/m'},
            );
          }
          return homepage();
        }
        expect(request.headers['cookie'], 'SOCS=fixture-choice');
        return http.Response(
          '{"contents":{"sectionListRenderer":{"contents":[]}}}',
          200,
        );
      });
      final provider = YoutubeMusicProvider(
        t,
        session: session,
        onConsentRequired: () {
          reviews++;
          return choice.future;
        },
      );
      try {
        final a = provider.search('fixture');
        final b = provider.search('another fixture');
        while (reviews == 0) {
          await Future<void>.delayed(Duration.zero);
        }
        session.setConsentCookies({'SOCS': 'fixture-choice'});
        choice.complete(true);
        expect(await a, isEmpty);
        expect(await b, isEmpty);
        expect(reviews, 1);
        expect(homepages, 2);
      } finally {
        await t.close();
      }
    },
  );

  for (final cancelled in [false, true]) {
    test('dismissed/cancelled consent never retries: $cancelled', () async {
      final session = YoutubeMusicSession();
      final choice = Completer<bool>();
      final cancel = CancellationToken();
      var requests = 0, reviews = 0;
      final t = transport((request) {
        requests++;
        return http.Response(
          '',
          302,
          headers: {'location': 'https://consent.youtube.com/m'},
        );
      });
      final provider = YoutubeMusicProvider(
        t,
        session: session,
        onConsentRequired: () {
          reviews++;
          return choice.future;
        },
      );
      try {
        final result = expectLater(
          provider.search('fixture', cancel: cancel),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.code,
              'code',
              cancelled ? 'cancelled' : 'blocked',
            ),
          ),
        );
        while (reviews == 0) {
          await Future<void>.delayed(Duration.zero);
        }
        if (cancelled) {
          cancel.cancel();
          session.setConsentCookies({'SOCS': 'fixture-choice'});
        }
        choice.complete(cancelled);
        await result;
        expect(requests, 1);
        expect(reviews, 1);
      } finally {
        await t.close();
      }
    });
  }

  test('an unresolved consent redirect opens at most one review', () async {
    final session = YoutubeMusicSession();
    var reviews = 0;
    final t = transport(
      (request) => http.Response(
        '',
        302,
        headers: {'location': 'https://consent.youtube.com/m'},
      ),
    );
    try {
      await expectLater(
        YoutubeMusicProvider(
          t,
          session: session,
          onConsentRequired: () async {
            reviews++;
            session.setConsentCookies({'SOCS': 'fixture-choice'});
            return true;
          },
        ).search('fixture'),
        throwsA(isA<ProviderException>()),
      );
      expect(reviews, 1);
    } finally {
      await t.close();
    }
  });

  test('session filters to bounded anonymous consent cookies', () {
    final session = YoutubeMusicSession();
    expect(session.hasConsent, isFalse);
    expect(session.cookieHeader, isNull);
    session.setConsentCookies({
      'SOCS': 'fixture-token',
      'CONSENT': 'fixture-token==',
      'SID': 'private-account-cookie',
      'AUTH': 'private',
      'bad;name': 'value',
    });
    expect(session.hasConsent, isTrue);
    expect(session.cookieHeader, 'SOCS=fixture-token; CONSENT=fixture-token==');
    final revision = session.revision;
    session.setConsentCookies({'SOCS': 'bad\r\nX-Evil: yes'});
    expect(session.cookieHeader, isNull);
    expect(session.revision, revision + 1);
    session.clear();
    expect(session.hasConsent, isFalse);
  });

  test(
    'default provider sends no cookie and consent page stays blocked',
    () async {
      final seen = <String?>[];
      final t = transport((request) {
        seen.add(request.headers['cookie']);
        return http.Response(
          '<html><form action="https://consent.youtube.com/save">Before you continue</form></html>',
          200,
        );
      });
      try {
        await expectLater(
          YoutubeMusicProvider(t).search('fixture'),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.message,
              'reason',
              'consent_required',
            ),
          ),
        );
        expect(seen, [null]);
      } finally {
        await t.close();
      }
    },
  );

  test('only consent cookies reach fixed YouTube Music requests', () async {
    final session = YoutubeMusicSession()
      ..setConsentCookies({'SOCS': 'fixture', 'SID': 'must-not-send'});
    final seen = <http.Request>[];
    final t = transport((request) {
      seen.add(request);
      return request.url.path == '/'
          ? homepage()
          : http.Response(
              '{"contents":{"sectionListRenderer":{"contents":[]}}}',
              200,
            );
    });
    try {
      await YoutubeMusicProvider(t, session: session).search('fixture');
      expect(seen.map((r) => r.url.host).toSet(), {'music.youtube.com'});
      expect(
        seen.map((r) => r.headers['cookie']),
        everyElement('SOCS=fixture'),
      );
      expect(seen.last.headers['origin'], 'https://music.youtube.com');
    } finally {
      await t.close();
    }
  });

  test('consent cookies are stripped from an allowed www redirect', () async {
    final session = YoutubeMusicSession()
      ..setConsentCookies({'SOCS': 'fixture'});
    final seen = <http.Request>[];
    final t = transport((request) {
      seen.add(request);
      if (request.url.host == 'music.youtube.com' && request.url.path == '/') {
        return http.Response(
          '',
          302,
          headers: {'location': 'https://www.music.youtube.com/'},
        );
      }
      return request.url.path == '/'
          ? homepage()
          : http.Response(
              '{"contents":{"sectionListRenderer":{"contents":[]}}}',
              200,
            );
    });
    try {
      await YoutubeMusicProvider(t, session: session).search('fixture');
      expect(seen[0].headers['cookie'], 'SOCS=fixture');
      expect(seen[1].url.host, 'www.music.youtube.com');
      expect(seen[1].headers['cookie'], isNull);
      expect(seen.last.url.host, 'music.youtube.com');
      expect(seen.last.headers['cookie'], 'SOCS=fixture');
    } finally {
      await t.close();
    }
  });

  test(
    'a saved decision does not bypass a renewed Google consent requirement',
    () async {
      var calls = 0;
      final session = YoutubeMusicSession()
        ..setConsentCookies({'SOCS': 'fixture'});
      final t = transport((request) {
        calls++;
        expect(request.url.host, 'music.youtube.com');
        return http.Response(
          '',
          302,
          headers: {
            'location': 'https://consent.youtube.com/m?continue=synthetic',
          },
        );
      });
      try {
        await expectLater(
          YoutubeMusicProvider(t, session: session).search('fixture'),
          throwsA(
            isA<ProviderException>()
                .having((error) => error.code, 'code', 'blocked')
                .having((error) => error.message, 'reason', 'consent_required'),
          ),
        );
        expect(calls, 1);
      } finally {
        await t.close();
      }
    },
  );

  test(
    'session revision discards an in-flight stale homepage config',
    () async {
      final firstStarted = Completer<void>();
      final finishFirst = Completer<void>();
      final seen = <http.Request>[];
      var homeCount = 0;
      final t = transport((request) async {
        seen.add(request);
        if (request.url.path == '/') {
          homeCount++;
          if (homeCount == 1) {
            firstStarted.complete();
            await finishFirst.future;
          }
          return homepage();
        }
        return http.Response(
          '{"contents":{"sectionListRenderer":{"contents":[]}}}',
          200,
        );
      });
      final session = YoutubeMusicSession();
      try {
        final search = YoutubeMusicProvider(
          t,
          session: session,
        ).search('fixture');
        await firstStarted.future;
        session.setConsentCookies({'SOCS': 'new-fixture'});
        finishFirst.complete();
        await search;
        expect(homeCount, 2);
        expect(
          seen.where((r) => r.url.path == '/').last.headers['cookie'],
          'SOCS=new-fixture',
        );
        expect(seen.last.headers['cookie'], 'SOCS=new-fixture');
      } finally {
        if (!finishFirst.isCompleted) finishFirst.complete();
        await t.close();
      }
    },
  );

  test('clearing during an API request discards its response', () async {
    final apiStarted = Completer<void>();
    final finishApi = Completer<void>();
    final session = YoutubeMusicSession()
      ..setConsentCookies({'SOCS': 'fixture'});
    final t = transport((request) async {
      if (request.url.path == '/') return homepage();
      apiStarted.complete();
      await finishApi.future;
      return http.Response(
        '{"contents":{"sectionListRenderer":{"contents":[]}}}',
        200,
      );
    });
    try {
      final search = YoutubeMusicProvider(
        t,
        session: session,
      ).search('fixture');
      await apiStarted.future;
      session.clear();
      finishApi.complete();
      await expectLater(
        search,
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
    } finally {
      if (!finishApi.isCompleted) finishApi.complete();
      await t.close();
    }
  });

  for (final cached in [false, true]) {
    test(
      'clear prevents a queued ${cached ? 'API' : 'homepage'} cookie send',
      () async {
        final blockerStarted = Completer<void>();
        final releaseBlocker = Completer<void>();
        final seen = <http.Request>[];
        final session = YoutubeMusicSession()
          ..setConsentCookies({'SOCS': 'old-fixture'});
        final t = transport((request) async {
          seen.add(request);
          if (request.url.path == '/queue-blocker') {
            blockerStarted.complete();
            await releaseBlocker.future;
            return http.Response('ok', 200);
          }
          return request.url.path == '/'
              ? homepage()
              : http.Response(
                  '{"contents":{"sectionListRenderer":{"contents":[]}}}',
                  200,
                );
        });
        final provider = YoutubeMusicProvider(t, session: session);
        try {
          if (cached) await provider.search('warmup');
          final blocker = t.getText(
            Uri.parse('https://music.youtube.com/queue-blocker'),
          );
          await blockerStarted.future;
          final queued = provider.search('queued');
          // All request-setup microtasks run before this timer. The held host
          // queue prevents either homepage or cached API dispatch until release.
          await Future<void>.delayed(Duration.zero);
          final beforeClear = seen.length;
          final outcome = cached
              ? expectLater(
                  queued,
                  throwsA(
                    isA<ProviderException>().having(
                      (e) => e.code,
                      'code',
                      'cancelled',
                    ),
                  ),
                )
              : expectLater(queued, completes);
          session.clear();
          releaseBlocker.complete();
          await blocker;
          await outcome;
          final afterClear = seen.skip(beforeClear);
          expect(
            afterClear.map((r) => r.headers['cookie']),
            everyElement(isNull),
          );
          if (cached) {
            expect(afterClear, isEmpty);
          } else {
            // The stale homepage was cancelled; a fresh anonymous attempt may
            // still proceed, without transmitting the removed consent choice.
            expect(afterClear.where((r) => r.url.path == '/'), hasLength(1));
          }
        } finally {
          if (!releaseBlocker.isCompleted) releaseBlocker.complete();
          await t.close();
        }
      },
    );
  }
}
