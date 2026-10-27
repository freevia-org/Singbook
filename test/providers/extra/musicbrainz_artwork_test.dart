import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/metadata.dart';
import 'package:singbook/providers/provider.dart';

const _recording = '12345678-1234-1234-1234-123456789abc';
const _releaseA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _releaseB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _album = 'Invented Album';

Map<String, dynamic> _recordingData({
  List<Map<String, dynamic>>? releases,
  int? releaseCount,
}) => {
  'id': _recording,
  'title': 'Invented Track',
  'length': 201000,
  'artist-credit': [
    {
      'name': 'Invented Artist',
      'artist': {'id': '11111111-1111-4111-8111-111111111111'},
    },
  ],
  'releases':
      releases ??
      [
        {'id': _releaseA, 'title': _album},
      ],
  'release-count': ?releaseCount,
};

Map<String, dynamic> _releaseData({
  String id = _releaseA,
  String title = _album,
  String recordingId = _recording,
  bool front = true,
  bool artwork = true,
  bool darkened = false,
  int? count,
}) => {
  'id': id,
  'title': title,
  'cover-art-archive': {
    'artwork': artwork,
    'front': front,
    'darkened': darkened,
    'count': ?count,
  },
  'media': [
    {
      'tracks': [
        {
          'recording': {'id': recordingId},
        },
      ],
    },
  ],
};

SongCandidate _selection({
  String? album = _album,
  Map<String, dynamic> metadata = const {},
}) => SongCandidate(
  providerId: 'library',
  id: 'local-recording',
  title: 'Invented Track',
  artist: 'Invented Artist',
  album: album,
  durationSeconds: 201,
  recordingIds: {'musicbrainz': _recording},
  metadata: metadata,
);

http.Response _json(Object value, {int status = 200}) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

typedef Handler = Future<http.Response> Function(http.Request request);

({MusicBrainzProvider provider, ProviderTransport transport}) _provider(
  Handler handler,
) {
  final transport = ProviderTransport(
    client: MockClient(handler),
    hostInterval: Duration.zero,
    maxRetries: 0,
  );
  return (provider: MusicBrainzProvider(transport), transport: transport);
}

Matcher _code(String code) =>
    isA<ProviderException>().having((error) => error.code, 'code', code);

void main() {
  test(
    'unique exact release returns fixed CAA front preview and unknown rights',
    () async {
      final requests = <Uri>[];
      final pair = _provider((request) async {
        requests.add(request.url);
        if (request.url.path.startsWith('/ws/2/release/')) {
          return _json(_releaseData());
        }
        return _json(_recordingData());
      });
      addTearDown(pair.transport.close);

      final result = await pair.provider.resolve(_selection());
      final url = 'https://coverartarchive.org/release/$_releaseA/front-500';

      expect(result.candidate.id, _recording);
      expect(result.candidate.recordingIds, {'musicbrainz': _recording});
      expect(result.candidate.title, 'Invented Track');
      expect(result.candidate.artist, 'Invented Artist');
      expect(result.candidate.album, _album);
      expect(result.candidate.metadata['musicbrainzReleaseId'], _releaseA);
      expect(result.metadata['durationSeconds'], 201);
      expect(result.metadata['album'], _album);
      expect(result.metadata['artworkUrl'], url);
      expect(result.metadata['musicbrainzReleaseId'], _releaseA);
      expect(result.metadata['artworkAssets'], [
        {
          'url': url,
          'sourceUrl': 'https://musicbrainz.org/release/$_releaseA',
          'credit': 'Cover Art Archive (MusicBrainz release $_releaseA)',
          'recordingId': _recording,
          'releaseId': _releaseA,
          'role': 'frontCoverPreview',
          'rights': {'status': 'unknown'},
        },
      ]);
      expect(result.metadata['artworkAssets'][0].containsKey('offline'), false);
      expect(requests.any((uri) => uri.host == 'coverartarchive.org'), false);
      expect(result.extra['coverArtArchive']['status'], 'available');
      expect(
        result.extra['coverArtArchive']['releaseEvidence']['provenance'],
        'normalized MusicBrainz release response',
      );
      expect(
        result.extra['coverArtArchive']['releaseEvidence']['data'],
        _releaseData(),
      );
    },
  );

  test(
    'explicit release is directly validated even beyond a truncated first page',
    () async {
      final ids = [
        for (var i = 0; i < 25; i++)
          {
            'id': 'aaaaaaaa-aaaa-4aaa-8aaa-${i.toString().padLeft(12, '0')}',
            'title': 'Visible wrong album',
          },
      ];
      var releaseFetches = 0;
      final pair = _provider((request) async {
        if (request.url.path.startsWith('/ws/2/release/')) {
          releaseFetches++;
          expect(request.url.path, '/ws/2/release/$_releaseB');
          expect(request.url.queryParameters['inc'], 'recordings');
          return _json(
            _releaseData(id: _releaseB, title: 'Exact release outside page'),
          );
        }
        return _json(_recordingData(releases: ids, releaseCount: 101));
      });
      addTearDown(pair.transport.close);
      final result = await pair.provider.resolve(
        _selection(album: null, metadata: {'musicbrainzReleaseId': _releaseB}),
      );
      expect(releaseFetches, 1);
      expect(result.metadata['musicbrainzReleaseId'], _releaseB);
      expect(result.candidate.album, 'Exact release outside page');
      expect(result.metadata['album'], 'Exact release outside page');
      expect(result.candidate.metadata['musicbrainzReleaseId'], _releaseB);
      expect(result.extra['coverArtArchive']['status'], 'available');
    },
  );

  test(
    'one release overall is usable when the selection has no album',
    () async {
      final pair = _provider((request) async {
        if (request.url.path.startsWith('/ws/2/release/')) {
          return _json(_releaseData());
        }
        return _json(_recordingData());
      });
      addTearDown(pair.transport.close);
      final result = await pair.provider.resolve(_selection(album: null));
      expect(result.metadata['musicbrainzReleaseId'], _releaseA);
      expect(result.extra['coverArtArchive']['status'], 'available');
    },
  );

  test(
    'album selection requires one distinct exact-title release ID',
    () async {
      var releaseFetches = 0;
      final pair = _provider((request) async {
        if (request.url.path.startsWith('/ws/2/release/')) releaseFetches++;
        return _json(
          _recordingData(
            releases: [
              {'id': _releaseA, 'title': _album},
              {'id': _releaseB, 'title': _album},
            ],
          ),
        );
      });
      addTearDown(pair.transport.close);
      final result = await pair.provider.resolve(_selection());
      expect(releaseFetches, 0);
      expect(result.metadata.containsKey('artworkUrl'), false);
      expect(result.metadata['durationSeconds'], 201);
      expect(result.extra['coverArtArchive']['code'], 'release_ambiguous');
    },
  );

  for (final truncated in [
    _recordingData(
      releases: [
        for (var i = 0; i < 25; i++) {'id': _releaseA, 'title': _album},
      ],
    ),
    _recordingData(
      releases: [
        {'id': _releaseA, 'title': _album},
      ],
      releaseCount: 2,
    ),
  ]) {
    test(
      'incomplete MusicBrainz release list cannot infer uniqueness',
      () async {
        var releaseFetches = 0;
        final pair = _provider((request) async {
          if (request.url.path.startsWith('/ws/2/release/')) releaseFetches++;
          return _json(truncated);
        });
        addTearDown(pair.transport.close);
        final result = await pair.provider.resolve(_selection());
        expect(releaseFetches, 0);
        expect(result.metadata['durationSeconds'], 201);
        expect(
          result.extra['coverArtArchive']['code'],
          'release_list_truncated',
        );
      },
    );
  }

  for (final releasePatch in [
    {'title': 'Different Imaginary Album'},
    {'recordingId': '99999999-9999-4999-8999-999999999999'},
    {'front': false},
    {'darkened': true},
    {'front': true, 'count': 0},
    {'front': true, 'artwork': false},
  ]) {
    test(
      'release album, track binding and front art are required: $releasePatch',
      () async {
        final pair = _provider((request) async {
          if (request.url.path.startsWith('/ws/2/release/')) {
            return _json(
              _releaseData(
                title: releasePatch['title'] as String? ?? _album,
                recordingId:
                    releasePatch['recordingId'] as String? ?? _recording,
                front: releasePatch['front'] as bool? ?? true,
                artwork: releasePatch['artwork'] as bool? ?? true,
                darkened: releasePatch['darkened'] as bool? ?? false,
                count: releasePatch['count'] as int?,
              ),
            );
          }
          return _json(_recordingData());
        });
        addTearDown(pair.transport.close);
        final result = await pair.provider.resolve(_selection());
        expect(result.metadata.containsKey('artworkUrl'), false);
        expect(result.metadata['durationSeconds'], 201);
        expect(result.extra['coverArtArchive']['status'], 'omitted');
      },
    );
  }

  test(
    'malformed explicit ID does not fall back to release list or release group',
    () async {
      var releaseFetches = 0;
      final pair = _provider((request) async {
        if (request.url.path.startsWith('/ws/2/release/')) releaseFetches++;
        return _json(
          _recordingData(
            releases: [
              {
                'id': 'not-a-release-id',
                'title': _album,
                'release-group': {'id': _releaseA},
              },
            ],
          ),
        );
      });
      addTearDown(pair.transport.close);
      final result = await pair.provider.resolve(
        _selection(metadata: {'musicbrainzReleaseId': 'malformed'}),
      );
      expect(releaseFetches, 0);
      expect(result.metadata['durationSeconds'], 201);
      expect(
        result.extra['coverArtArchive']['code'],
        'invalid_explicit_release_id',
      );
    },
  );

  test(
    'malformed release ID cannot fall back to a valid release-group ID',
    () async {
      var releaseFetches = 0;
      final pair = _provider((request) async {
        if (request.url.path.startsWith('/ws/2/release/')) releaseFetches++;
        return _json(
          _recordingData(
            releases: [
              {
                'id': 'not-a-release-id',
                'title': _album,
                'release-group': {'id': _releaseA},
              },
            ],
          ),
        );
      });
      addTearDown(pair.transport.close);
      final result = await pair.provider.resolve(_selection());
      expect(releaseFetches, 0);
      expect(result.metadata['durationSeconds'], 201);
      expect(result.extra['coverArtArchive']['code'], 'invalid_release_id');
    },
  );

  test('release response with another release ID is rejected', () async {
    final pair = _provider((request) async {
      if (request.url.path.startsWith('/ws/2/release/')) {
        return _json(_releaseData(id: _releaseB));
      }
      return _json(_recordingData());
    });
    addTearDown(pair.transport.close);
    final result = await pair.provider.resolve(_selection());
    expect(result.metadata['durationSeconds'], 201);
    expect(result.metadata.containsKey('artworkUrl'), false);
    expect(result.extra['coverArtArchive']['code'], 'invalid_response');
  });

  test(
    'malformed media or track structures cannot prove release membership',
    () async {
      for (final media in [
        'invalid',
        [
          {'tracks': 'invalid'},
        ],
        [
          {
            'tracks': [
              {'recording': 'invalid'},
            ],
          },
        ],
      ]) {
        final pair = _provider((request) async {
          if (request.url.path.startsWith('/ws/2/release/')) {
            return _json({..._releaseData(), 'media': media});
          }
          return _json(_recordingData());
        });
        addTearDown(pair.transport.close);
        final result = await pair.provider.resolve(_selection());
        expect(result.metadata.containsKey('artworkUrl'), false);
        expect(
          result.extra['coverArtArchive']['code'],
          'recording_not_on_release',
        );
      }
    },
  );

  test('release request failure preserves valid recording metadata', () async {
    final pair = _provider((request) async {
      if (request.url.path.startsWith('/ws/2/release/')) {
        return _json({}, status: 403);
      }
      return _json(_recordingData());
    });
    addTearDown(pair.transport.close);
    final result = await pair.provider.resolve(_selection());
    expect(result.candidate.id, _recording);
    expect(result.metadata['durationSeconds'], 201);
    expect(result.metadata.containsKey('artworkUrl'), false);
    expect(result.extra['coverArtArchive']['code'], 'access_denied');
  });

  test('transient release request failure is not cached', () async {
    var releaseFetches = 0;
    final pair = _provider((request) async {
      if (request.url.path.startsWith('/ws/2/release/')) {
        releaseFetches++;
        return releaseFetches == 1
            ? _json({}, status: 503)
            : _json(_releaseData());
      }
      return _json(_recordingData());
    });
    addTearDown(pair.transport.close);
    final first = await pair.provider.resolve(_selection());
    final second = await pair.provider.resolve(_selection());
    expect(first.metadata.containsKey('artworkUrl'), false);
    expect(second.metadata['musicbrainzReleaseId'], _releaseA);
    expect(releaseFetches, 2);
  });

  test(
    'successful release detail is cached while recording resolution remains fresh',
    () async {
      var recordingFetches = 0;
      var releaseFetches = 0;
      final pair = _provider((request) async {
        if (request.url.path.startsWith('/ws/2/release/')) {
          releaseFetches++;
          return _json(_releaseData());
        }
        recordingFetches++;
        return _json(_recordingData());
      });
      addTearDown(pair.transport.close);
      await pair.provider.resolve(_selection());
      await pair.provider.resolve(_selection());
      expect(recordingFetches, 2);
      expect(releaseFetches, 1);
    },
  );

  test(
    'optional deadline includes queue wait and never sends a late release request',
    () async {
      var releaseFetches = 0;
      final transport = ProviderTransport(
        client: MockClient((request) async {
          if (request.url.path.startsWith('/ws/2/release/')) {
            releaseFetches++;
            return _json(_releaseData());
          }
          return _json(_recordingData());
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      addTearDown(transport.close);
      final provider = MusicBrainzProvider(
        transport,
        artworkTimeout: const Duration(milliseconds: 100),
      );
      final result = await provider.resolve(_selection());
      expect(result.candidate.id, _recording);
      expect(result.metadata['durationSeconds'], 201);
      expect(result.extra['coverArtArchive']['code'], 'timeout');
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(releaseFetches, 0);
    },
  );

  test(
    'slow retrying optional release cannot withhold recording metadata',
    () async {
      var releaseFetches = 0;
      final transport = ProviderTransport(
        client: MockClient((request) async {
          if (request.url.path.startsWith('/ws/2/release/')) {
            releaseFetches++;
            return http.Response(
              '{}',
              503,
              headers: {'content-type': 'application/json', 'retry-after': '8'},
            );
          }
          return _json(_recordingData());
        }),
        hostInterval: Duration.zero,
        maxRetries: 2,
      );
      addTearDown(transport.close);
      final provider = MusicBrainzProvider(
        transport,
        artworkTimeout: const Duration(milliseconds: 1500),
      );
      final watch = Stopwatch()..start();
      final result = await provider.resolve(_selection());
      expect(result.candidate.id, _recording);
      expect(result.metadata['durationSeconds'], 201);
      expect(result.metadata.containsKey('artworkUrl'), isFalse);
      expect(result.extra['coverArtArchive']['code'], 'timeout');
      expect(watch.elapsed, lessThan(const Duration(seconds: 4)));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(releaseFetches, 1);
    },
  );

  test(
    'cancellation during optional release lookup still propagates',
    () async {
      final cancel = CancellationToken();
      final pair = _provider((request) async {
        if (request.url.path.startsWith('/ws/2/release/')) {
          return _json(_releaseData());
        }
        Timer(const Duration(milliseconds: 30), cancel.cancel);
        return _json(_recordingData());
      });
      addTearDown(pair.transport.close);
      await expectLater(
        pair.provider.resolve(_selection(), cancel: cancel),
        throwsA(_code('cancelled')),
      );
    },
  );
}
