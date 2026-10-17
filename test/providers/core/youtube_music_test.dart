import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

http.Response homepage() => http.Response(
  '<script>ytcfg.set({"INNERTUBE_CLIENT_VERSION":"fixture.1"});</script>',
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
  test('search uses anonymous HTTP requests without cookies', () async {
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
        everyElement(isNull),
      );
    } finally {
      await t.close();
    }
  });

  test('resolve uses anonymous HTTP requests without cookies', () async {
    final requests = <http.Request>[];
    final t = transport((request) {
      requests.add(request);
      if (request.url.path == '/') return homepage();
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
        requests.map((request) => request.url.host),
        everyElement('music.youtube.com'),
      );
      expect(
        requests.map((request) => request.headers['cookie']),
        everyElement(isNull),
      );
      expect(requests.map((request) => request.url.path), [
        '/',
        '/youtubei/v1/next',
        '/youtubei/v1/browse',
      ]);
    } finally {
      await t.close();
    }
  });

  test('consent redirect stays blocked and does not open a web flow', () async {
    var requests = 0;
    final t = transport((request) {
      requests++;
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
}
