import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/core/youtube_music.dart';
import 'package:singbook/providers/provider.dart';

ProviderTransport transport(
  FutureOr<http.Response> Function(http.Request) fn,
) => ProviderTransport(
  client: MockClient((request) async => fn(request)),
  hostInterval: Duration.zero,
  timeout: const Duration(seconds: 2),
  maxRetries: 0,
);

http.Response json(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response homepage([
  Map<String, Object?> extra = const {},
]) => http.Response(
  '<script>ytcfg.set(${jsonEncode({'INNERTUBE_CLIENT_VERSION': 'fixture.1', ...extra})});</script>',
  200,
);

http.Response upgradeHomepage() => http.Response(
  '<img src="/img/on_platform_logo_dark.svg"><a href="https://www.google.com/chrome/index.html">Upgrade</a>',
  200,
);

Map<String, dynamic> emptySearch() => {
  'contents': {
    'sectionListRenderer': {'contents': <Object>[]},
  },
};

Map<String, dynamic> selectedTrack() => {
  'contents': {
    'singleColumnMusicWatchNextResultsRenderer': {
      'tabbedRenderer': {
        'watchNextTabbedResultsRenderer': {
          'tabs': [
            {
              'tabRenderer': {
                'content': {
                  'musicQueueRenderer': {
                    'content': {
                      'playlistPanelRenderer': {
                        'contents': [
                          {
                            'playlistPanelVideoRenderer': {
                              'selected': true,
                              'videoId': 'abcdefghijk',
                              'title': {
                                'runs': [
                                  {'text': 'Paper Satellites'},
                                ],
                              },
                              'shortBylineText': {
                                'simpleText': 'Fixture Ensemble',
                              },
                              'thumbnail': {'thumbnails': <Object>[]},
                            },
                          },
                        ],
                      },
                    },
                  },
                },
              },
            },
            {
              'tabRenderer': {
                'endpoint': {
                  'browseEndpoint': {
                    'browseId': 'MPLYfixture',
                    'browseEndpointContextSupportedConfigs': {
                      'browseEndpointContextMusicConfig': {
                        'pageType': 'MUSIC_PAGE_TYPE_TRACK_LYRICS',
                      },
                    },
                  },
                },
              },
            },
          ],
        },
      },
    },
  },
};

void main() {
  test('upgrade-page fallback version uses the injected UTC date', () async {
    final requests = <http.Request>[];
    final t = transport((request) {
      requests.add(request);
      return request.url.path == '/' ? upgradeHomepage() : json(emptySearch());
    });
    try {
      final frozen = DateTime.utc(2026, 10, 27, 12);
      final provider = createCoreProviders(
        transport: t,
        clock: () => frozen,
      ).whereType<YoutubeMusicProvider>().single;
      expect(await provider.search('Moliendo Café Hugo Blanco'), isEmpty);
      final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
      final client = (body['context'] as Map)['client'] as Map;
      expect(client['clientVersion'], '1.20261027.01.00');
    } finally {
      await t.close();
    }
  });

  test(
    'cached config expires after one hour according to the injected clock',
    () async {
      var now = DateTime.utc(2026, 10, 27, 12);
      var homeRequests = 0;
      final t = transport((request) {
        if (request.url.path == '/') {
          homeRequests++;
          return homepage();
        }
        return json(emptySearch());
      });
      try {
        final provider = YoutubeMusicProvider(t, clock: () => now);
        await provider.search('fixture');
        expect(homeRequests, 1);
        now = now.add(const Duration(minutes: 59));
        await provider.search('fixture');
        expect(homeRequests, 1);
        now = now.add(const Duration(minutes: 2));
        await provider.search('fixture');
        expect(homeRequests, 2);
      } finally {
        await t.close();
      }
    },
  );

  for (final visitor in <Object>[
    'anonymous-fixture-visitor',
    'malformed\r\nvisitor',
    42,
    'v' * 4097,
  ]) {
    for (final nested in [false, true]) {
      test(
        'ignores ${nested ? 'nested' : 'top-level'} visitor ${visitor is String ? visitor.length : 'type'}',
        () async {
          final requests = <http.Request>[];
          final t = transport((request) {
            requests.add(request);
            return request.url.path == '/'
                ? homepage(
                    nested
                        ? {
                            'INNERTUBE_CLIENT_VERSION': null,
                            'INNERTUBE_CONTEXT': {
                              'client': {
                                'clientVersion': 'fixture.1',
                                'visitorData': visitor,
                              },
                            },
                          }
                        : {'VISITOR_DATA': visitor},
                  )
                : json(emptySearch());
          });
          try {
            expect(await YoutubeMusicProvider(t).search('fixture'), isEmpty);
            expect(requests, hasLength(2));
            for (final request in requests) {
              expect(request.headers['x-goog-visitor-id'], isNull);
            }
            final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
            final client = (body['context'] as Map)['client'] as Map;
            expect(client['clientVersion'], 'fixture.1');
            expect(client.containsKey('visitorData'), isFalse);
          } finally {
            await t.close();
          }
        },
      );
    }
  }
  test('invalid client version is still rejected', () async {
    var posts = 0;
    final t = transport((request) {
      if (request.url.path == '/') {
        return homepage({
          'INNERTUBE_CLIENT_VERSION': 'invalid\r\nversion',
          'VISITOR_DATA': 'unused',
        });
      }
      posts++;
      return json(emptySearch());
    });
    try {
      await expectLater(
        YoutubeMusicProvider(t).search('fixture'),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'extraction_failed',
          ),
        ),
      );
      expect(posts, 0);
    } finally {
      await t.close();
    }
  });
  test('search carries only the fixed anonymous consent marker', () async {
    final requests = <http.Request>[];
    final t = transport((request) {
      requests.add(request);
      return request.url.path == '/' ? homepage() : json(emptySearch());
    });
    try {
      expect(await YoutubeMusicProvider(t).search('fixture'), isEmpty);
      expect(requests, hasLength(2));
      expect(
        requests.map((request) => request.url.host),
        everyElement('music.youtube.com'),
      );
      expect(
        requests.map((request) => request.headers['cookie']),
        everyElement('SOCS=CAI'),
      );
      expect(
        requests.map((request) => request.headers['authorization']),
        everyElement(isNull),
      );
    } finally {
      await t.close();
    }
  });

  test(
    'resolve carries the same marker through next and lyrics browse',
    () async {
      final requests = <http.Request>[];
      final t = transport((request) {
        requests.add(request);
        if (request.url.path == '/') {
          return homepage({'VISITOR_DATA': 'must-not-be-replayed'});
        }
        if (request.url.path.endsWith('/next')) return json(selectedTrack());
        return json({
          'contents': {
            'sectionListRenderer': {
              'contents': [
                {
                  'musicDescriptionShelfRenderer': {
                    'description': {
                      'simpleText': 'First invented line\nSecond invented line',
                    },
                    'footer': {'simpleText': 'YouTube Music'},
                  },
                },
              ],
            },
          },
        });
      });
      try {
        final result = await YoutubeMusicProvider(t).resolve(
          const SongCandidate(
            providerId: 'youtubemusic',
            id: 'abcdefghijk',
            title: 'Paper Satellites',
            artist: 'Fixture Ensemble',
          ),
        );
        expect(result.body, contains('First invented line'));
        expect(
          requests.map((request) => request.headers['x-goog-visitor-id']),
          everyElement(isNull),
        );
        expect(
          requests.skip(1).map((request) => request.body),
          everyElement(isNot(contains('must-not-be-replayed'))),
        );
        expect(
          requests.map((request) => request.url.host),
          everyElement('music.youtube.com'),
        );
        expect(
          requests.map((request) => request.headers['cookie']),
          everyElement('SOCS=CAI'),
        );
        expect(requests.map((request) => request.url.path), [
          '/',
          '/youtubei/v1/next',
          '/youtubei/v1/browse',
        ]);
      } finally {
        await t.close();
      }
    },
  );

  test('consent redirect stays blocked and does not open a web flow', () async {
    var requests = 0;
    final t = transport((request) {
      requests++;
      expect(request.url.host, 'music.youtube.com');
      expect(request.headers['cookie'], 'SOCS=CAI');
      return http.Response(
        '',
        302,
        headers: {'location': 'https://consent.youtube.com/m?continue=x'},
      );
    });
    try {
      await expectLater(
        YoutubeMusicProvider(t).search('fixture'),
        throwsA(
          isA<ProviderException>()
              .having((error) => error.code, 'code', 'blocked')
              .having((error) => error.message, 'message', 'consent_required'),
        ),
      );
      expect(requests, 1);
    } finally {
      await t.close();
    }
  });

  test('another source does not inherit the YouTube request marker', () async {
    final requests = <http.Request>[];
    final t = transport((request) {
      requests.add(request);
      if (request.url.host == 'genius.com') {
        return http.Response('fixture', 200);
      }
      return request.url.path == '/' ? homepage() : json(emptySearch());
    });
    try {
      await YoutubeMusicProvider(t).search('fixture');
      await t.getText(Uri.parse('https://genius.com/fixture'));
      expect(requests.last.url.host, 'genius.com');
      expect(requests.last.headers['cookie'], isNull);
      expect(requests.last.headers['authorization'], isNull);
    } finally {
      await t.close();
    }
  });
}
