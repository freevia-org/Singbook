import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/core/recording_key.dart';
import 'package:singbook/providers/provider.dart';

ProviderTransport _transport(Object body, List<Uri> requests) =>
    ProviderTransport(
      hostInterval: Duration.zero,
      client: MockClient((request) async {
        requests.add(request.url);
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

Map<String, Object?> _feature(String isrc, int key, int mode, num tempo) => {
  'id': 'id-$isrc',
  'isrc': isrc,
  'key': key,
  'mode': mode,
  'tempo': tempo,
};

void main() {
  test('one vote per recording decides the key', () async {
    final requests = <Uri>[];
    final service = RecordingKeyService(
      _transport({
        'content': [
          // The same audio listed twice must not outvote other recordings.
          _feature('USRE19100010', 9, 1, 77.4),
          _feature('USRE19100010', 9, 1, 77.4),
          _feature('USRE10201368', 9, 1, 77.2),
          _feature('GBXXX0000001', 0, 1, 154.8),
        ],
      }, requests),
    );
    final found = await service.lookup(
      spotifyIds: const ['1kgdslQYmeTR4thk9whoRw'],
      isrcs: const ['usre19100010', 'not-an-isrc'],
    );
    expect(found?.key, 'A');
    expect(found?.ids, ['USRE19100010', 'USRE10201368']);
    expect(found?.tempo, 77);
    expect(requests.single.host, 'api.reccobeats.com');
    expect(
      requests.single.queryParameters['ids'],
      '1kgdslQYmeTR4thk9whoRw,USRE19100010',
    );
  });

  test('minor keys, ties and malformed rows', () async {
    Future<RecordingKey?> lookup(List<Object?> content) => RecordingKeyService(
      _transport({'content': content}, []),
    ).lookup(isrcs: const ['USRE19100010']);

    expect((await lookup([_feature('A', 4, 0, 90)]))?.key, 'Em');
    expect(
      await lookup([_feature('A', 4, 0, 90), _feature('B', 7, 1, 90)]),
      isNull,
    );
    expect(
      await lookup([
        {'isrc': 'A', 'key': -1, 'mode': 1},
        {'isrc': 'B', 'key': 12, 'mode': 1},
        {'isrc': 'C', 'key': 3, 'mode': 2},
        'garbage',
      ]),
      isNull,
    );
  });

  test('no identifiers means no request', () async {
    final requests = <Uri>[];
    final found = await RecordingKeyService(
      _transport({'content': []}, requests),
    ).lookup(spotifyIds: const ['short'], isrcs: const ['nope']);
    expect(found, isNull);
    expect(requests, isEmpty);
  });

  test('identifiers come from Spotify links and ISRC metadata', () {
    final ids = recordingIdentifiers(
      const SourceResult(
        candidate: SongCandidate(
          providerId: 'genius',
          id: '1',
          title: 'Song',
          artist: 'Artist',
          metadata: {
            'mediaLinks': [
              {
                'kind': 'audio',
                'url': 'https://open.spotify.com/track/1kgdslQYmeTR4thk9whoRw',
              },
              {'kind': 'audio', 'url': 'https://open.spotify.com/album/abc'},
              {'kind': 'video', 'url': 'https://youtube.com/watch?v=x'},
            ],
          },
        ),
        body: '',
        metadata: {
          'isrcs': ['USRE19100010', 'bad'],
        },
      ),
    );
    expect(ids.spotify, ['1kgdslQYmeTR4thk9whoRw']);
    expect(ids.isrcs, ['USRE19100010']);
  });
}
