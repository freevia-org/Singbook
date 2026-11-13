import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/core/youtube_music.dart';
import 'package:singbook/providers/provider.dart';

import 'configurable_provider_test.dart' show code, entry, transport;

const _lyrics =
    'Amber lanterns glow across the quiet harbor\n'
    'Silver rain returns beneath the evening sky\n'
    'Morning opens every window on the distant shore';
const _selection = SongCandidate(
  providerId: 'catalog',
  id: 'selected',
  title: 'Amber Song',
  artist: 'Example Artist',
);

class _Scripted implements LyricsProvider {
  _Scripted(this.ids, this.answer);
  final List<String> ids;
  final SourceResult Function(SongCandidate candidate) answer;
  final resolved = <String>[];

  @override
  final definition = const ProviderDefinition(
    id: 'words',
    name: 'Words',
    capabilities: {'catalog', 'lyrics'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [
    for (final id in ids)
      SongCandidate(
        providerId: 'words',
        id: id,
        title: 'Amber Song',
        artist: 'Example Artist',
      ),
  ];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolved.add(candidate.id);
    return answer(candidate);
  }
}

Map<String, dynamic> _ytRow(
  String id, {
  Object? pageType = 'MUSIC_PAGE_TYPE_ARTIST',
  List<Object?> thumbnails = const [],
  bool flexColumns = true,
}) => {
  'musicResponsiveListItemRenderer': {
    'playlistItemData': {'videoId': id},
    if (flexColumns)
      'flexColumns': [
        {
          'musicResponsiveListItemFlexColumnRenderer': {
            'text': {
              'runs': [
                {'text': 'Paper Satellites'},
              ],
            },
          },
        },
        {
          'musicResponsiveListItemFlexColumnRenderer': {
            'text': {
              'runs': [
                {
                  'text': 'Fixture Ensemble',
                  'navigationEndpoint': {
                    'browseEndpoint': {
                      'browseId': 'UC12345',
                      'browseEndpointContextSupportedConfigs': {
                        'browseEndpointContextMusicConfig': {
                          'pageType': pageType,
                        },
                      },
                    },
                  },
                },
              ],
            },
          },
        },
      ],
    'thumbnail': {
      'musicThumbnailRenderer': {
        'thumbnail': {'thumbnails': thumbnails},
      },
    },
  },
};

Map<String, dynamic> _ytSearch(List<Object?> rows) => {
  'contents': {
    'sectionListRenderer': {
      'contents': [
        {
          'musicShelfRenderer': {'contents': rows},
        },
      ],
    },
  },
};

void main() {
  group('discovery candidate isolation', () {
    test('a parser crash on one candidate leaves the next one usable', () async {
      final provider = _Scripted(['a', 'b'], (candidate) {
        if (candidate.id == 'a') throw StateError('parser bug');
        return SourceResult(candidate: candidate, body: _lyrics);
      });
      final result = await findMatchingSource(provider, _selection);
      expect(provider.resolved, ['a', 'b']);
      expect(result.candidate.id, 'b');
      expect(result.matchKind, isNot(MatchKind.rejected));
    });

    test('only unreadable candidates still report invalid_response', () async {
      final provider = _Scripted([
        'a',
        'b',
      ], (_) => throw const FormatException('bad page'));
      await expectLater(
        findMatchingSource(provider, _selection),
        throwsA(code('invalid_response')),
      );
      expect(provider.resolved, ['a', 'b']);
    });

    test('evidence states describe each candidate, not earlier ones', () async {
      final provider = _Scripted(['a', 'b', 'c'], (candidate) {
        if (candidate.id == 'a') {
          return const SourceResult(
            candidate: SongCandidate(
              providerId: 'words',
              id: 'a',
              title: 'Another Tune Entirely',
              artist: 'Example Artist',
            ),
            body: _lyrics,
          );
        }
        if (candidate.id == 'b') throw const ProviderException('unavailable');
        return SourceResult(candidate: candidate, body: _lyrics);
      });
      final result = await findMatchingSource(provider, _selection);
      final rows =
          (result.extra['discoveryEvidence'] as Map)['searchCandidates']
              as List;
      final states = {
        for (final row in rows)
          ((row as Map)['candidate'] as Map)['id']: row['state'],
      };
      expect(states, {'a': 'rejected', 'b': 'unavailable', 'c': 'accepted'});
    });
  });

  group('YouTube Music rows', () {
    test('odd field types cost at most their own row', () {
      final rows = YoutubeMusicProvider.parseSearch(
        _ytSearch([
          _ytRow(
            'aaaaaaaaaaa',
            pageType: 7,
            thumbnails: [
              {'url': 'https://i.ytimg.com/small.jpg', 'width': 'wide'},
              {'url': 'https://i.ytimg.com/large.jpg', 'width': 544},
            ],
          ),
          _ytRow('ccccccccccc', flexColumns: false),
          _ytRow('bbbbbbbbbbb'),
        ]),
      );
      expect(rows.map((row) => row.id), ['aaaaaaaaaaa', 'bbbbbbbbbbb']);
      expect(rows.first.artist, 'Fixture Ensemble');
      expect(
        rows.first.metadata['artworkUrl'],
        'https://i.ytimg.com/large.jpg',
      );
    });

    test('a response with only unusable rows is still a shape error', () {
      expect(
        () => YoutubeMusicProvider.parseSearch(
          _ytSearch([_ytRow('ccccccccccc', flexColumns: false)]),
        ),
        throwsA(code('invalid_response')),
      );
    });
  });

  group('YouTube Music client-version retry', () {
    http.Response homepage() => http.Response(
      '<script>ytcfg.set(${jsonEncode({'INNERTUBE_CLIENT_VERSION': 'fixture.1'})});</script>',
      200,
    );
    http.Response found() => http.Response(
      jsonEncode(_ytSearch(const [])),
      200,
      headers: {'content-type': 'application/json'},
    );

    test('a connection failure keeps the cached version, unretried', () async {
      var home = 0, posts = 0, offline = false;
      final t = ProviderTransport(
        client: MockClient((request) async {
          if (request.url.path == '/') {
            home++;
            return homepage();
          }
          posts++;
          if (offline) throw http.ClientException('no route');
          return found();
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      try {
        final provider = YoutubeMusicProvider(t);
        await provider.search('fixture');
        offline = true;
        await expectLater(provider.search('fixture'), throwsA(code('network')));
        expect(home, 1);
        expect(posts, 2);
        offline = false;
        await provider.search('fixture');
        expect(home, 1);
      } finally {
        await t.close();
      }
    });

    test('an HTTP client error still refreshes the version once', () async {
      var home = 0, posts = 0, reject = false;
      final t = ProviderTransport(
        client: MockClient((request) async {
          if (request.url.path == '/') {
            home++;
            return homepage();
          }
          posts++;
          if (reject) {
            reject = false;
            return http.Response('bad client', 400);
          }
          return found();
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      try {
        final provider = YoutubeMusicProvider(t);
        await provider.search('fixture');
        reject = true;
        expect(await provider.search('fixture'), isEmpty);
        expect(home, 2);
        expect(posts, 3);
      } finally {
        await t.close();
      }
    });
  });

  group('catalog-defined sources', () {
    test('an unparsable optional link drops the link, not the search', () async {
      final provider = ConfigurableProvider(
        entry(
          searchResponse: 'json',
          itemsPath: 'results',
          searchFields: {
            'id': 'id',
            'title': 'title',
            'artist': 'artist',
            'url': 'page',
          },
          resolveResponse: 'json',
          resolveFields: {
            'body': 'lyrics',
            'title': 'title',
            'artist': 'artist',
          },
        ),
        transport(
          (request) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 's1',
                  'title': 'A Song',
                  'artist': 'The Band',
                  'page': 'http://[::1',
                },
                {
                  'id': 's2',
                  'title': 'A Song',
                  'artist': 'The Band',
                  'page': '/song/s2',
                },
              ],
            }),
            200,
          ),
        ),
      );
      final rows = await provider.search('A Song');
      expect(rows.map((row) => row.id), ['s1', 's2']);
      expect(rows.first.url, isNull);
      expect(rows.last.url, 'https://lyrics.example.com/song/s2');
    });

    test('absurdly nested HTML is an extraction failure, not a crash', () async {
      final deep = '${'<div>' * 2000}<span class="song">x</span>';
      final provider = ConfigurableProvider(
        entry(
          searchResponse: 'html',
          itemSelector: '.song',
          searchFields: {
            'id': {'selector': '.title', 'attribute': 'data-id'},
            'title': {'selector': '.title'},
            'artist': {'selector': '.artist'},
          },
          resolveResponse: 'html',
          resolveFields: {
            'body': {'selector': '.lyrics'},
            'title': {'selector': 'h1'},
            'artist': {'selector': '.artist'},
          },
        ),
        transport((request) async => http.Response(deep, 200)),
      );
      await expectLater(
        provider.search('A Song'),
        throwsA(code('extraction_failed')),
      );
      await expectLater(
        provider.resolve(
          const SongCandidate(
            providerId: 'catalog_test',
            id: 's1',
            title: 'A Song',
            artist: 'The Band',
          ),
        ),
        throwsA(code('extraction_failed')),
      );
    });
  });
}
