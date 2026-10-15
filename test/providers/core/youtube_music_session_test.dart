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
}
