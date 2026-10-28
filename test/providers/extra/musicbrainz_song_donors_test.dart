import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/metadata.dart';
import 'package:singbook/providers/provider.dart';

String _id(int index) =>
    '${index.toString().padLeft(8, '0')}-0000-4000-8000-000000000001';
Map<String, dynamic> _row(
  int index, {
  String artist = 'Performer',
  String title = 'Harbor Song',
  String? version,
  bool knownFacts = false,
}) => {
  'id': _id(index),
  'title': title,
  'length': knownFacts ? 181000 : 180000 + index * 1000,
  'disambiguation': ?version,
  'artist-credit': [
    {
      'name': artist,
      'artist': {'id': '11111111-1111-4111-8111-111111111111'},
    },
  ],
  'releases': [
    {
      'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'title': knownFacts ? 'Known Album' : 'Album $index',
    },
  ],
  'isrcs': ['USAAA240000$index'],
};

const _selection = SongCandidate(
  providerId: 'catalog',
  id: 'song',
  title: 'Harbor Song',
  artist: 'Performer',
);

({MusicBrainzProvider provider, ProviderTransport transport}) _provider(
  List<Uri> requests, {
  int count = 5,
  String? badSearchArtist,
  String? badSearchTitle,
  String? version,
  bool knownFacts = false,
  bool failFirstDetail = false,
  CancellationToken? cancelOnDetail,
}) {
  final transport = ProviderTransport(
    hostInterval: Duration.zero,
    maxRetries: 0,
    client: MockClient((request) async {
      requests.add(request.url);
      expect(request.url.host, 'musicbrainz.org');
      expect(request.url.path, isNot(startsWith('/ws/2/release/')));
      final search = request.url.path == '/ws/2/recording/';
      if (!search) cancelOnDetail?.cancel();
      if (!search && failFirstDetail && request.url.path.endsWith(_id(1))) {
        return http.Response('invalid-json', 200);
      }
      final index = search
          ? 0
          : int.parse(request.url.pathSegments.last.substring(0, 8));
      final data = search
          ? {
              'recordings': [
                for (var i = count; i >= 1; i--)
                  _row(
                    i,
                    knownFacts: knownFacts,
                    artist: badSearchArtist ?? 'Performer',
                    title: badSearchTitle ?? 'Harbor Song',
                    version: version,
                  ),
              ],
            }
          : {
              ..._row(index, knownFacts: knownFacts),
              'relations': [
                {
                  'type': 'free streaming',
                  'url': {
                    'resource':
                        'https://open.spotify.com/track/${index.toString().padLeft(22, '0')}',
                  },
                },
              ],
            };
      return http.Response(
        jsonEncode(data),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  return (provider: MusicBrainzProvider(transport), transport: transport);
}

List<SourceResult> _donors(SourceResult source) => [
  source,
  for (final raw in source.extra['providerAlternatives'] as List? ?? const [])
    SourceResult.fromJson(Map<String, dynamic>.from(raw as Map)),
];

void main() {
  test(
    'ambiguous recordings retain five donors with only three detail operations',
    () async {
      final requests = <Uri>[];
      final pair = _provider(requests);
      addTearDown(pair.transport.close);
      final source = await findMatchingSource(pair.provider, _selection);
      final donors = _donors(source);
      expect(source.candidate.id, _id(1));
      expect(donors.map((donor) => donor.candidate.id), [
        for (var i = 1; i <= 5; i++) _id(i),
      ]);
      expect(
        donors.every((donor) => donor.matchKind == MatchKind.sameSong),
        isTrue,
      );
      expect(
        donors.every((donor) => donor.metadata['identityScope'] == 'song'),
        isTrue,
      );
      expect(
        donors.every((donor) => !recordingCompatible(_selection, donor)),
        isTrue,
      );
      expect(requests, hasLength(4));
      expect(requests.first.queryParameters['limit'], '12');
      expect(
        donors
            .take(3)
            .every(
              (donor) => donor.extra['recordingDetail']['state'] == 'resolved',
            ),
        isTrue,
      );
      expect(
        donors
            .skip(3)
            .every((donor) => donor.extra['searchEvidenceOnly'] == true),
        isTrue,
      );
      expect(
        donors
            .skip(3)
            .every(
              (donor) =>
                  donor.extra['recordingDetail']['state'] == 'not_attempted',
            ),
        isTrue,
      );
      expect(donors[0].metadata['isrcs'], ['USAAA2400001']);
      expect(donors[0].metadata['mediaLinks'], [
        {
          'kind': 'audio',
          'url': 'https://open.spotify.com/track/0000000000000000000001',
          'label': 'Spotify',
        },
      ]);
      expect(donors[0].extra['nativeRecording']['id'], _id(1));
      expect(
        donors.last.candidate.extra['musicbrainzSearchRecording']['id'],
        _id(5),
      );
      expect(
        donors.every((donor) => !donor.metadata.containsKey('artworkUrl')),
        isTrue,
      );
    },
  );

  test(
    'known album and duration cannot certify an ambiguous primary as selected recording',
    () async {
      final requests = <Uri>[];
      final pair = _provider(requests, count: 2, knownFacts: true);
      addTearDown(pair.transport.close);
      const selected = SongCandidate(
        providerId: 'catalog',
        id: 'song',
        title: 'Harbor Song',
        artist: 'Performer',
        album: 'Known Album',
        durationSeconds: 181,
      );
      final source = await findMatchingSource(pair.provider, selected);
      expect(source.matchKind, MatchKind.sameSong);
      expect(recordingCompatible(selected, source), isFalse);
      expect(source.candidate.album, 'Known Album');
      expect(source.candidate.durationSeconds, 181);
      expect(
        source.extra['nativeCandidate']['metadata']['identityScope'],
        'recording',
      );
      expect(_donors(source), hasLength(2));
    },
  );

  test(
    'a failed detail retains its search evidence while another donor succeeds',
    () async {
      final requests = <Uri>[];
      final pair = _provider(requests, count: 3, failFirstDetail: true);
      addTearDown(pair.transport.close);
      final source = await pair.provider.resolve(_selection);
      expect(source.candidate.id, _id(2));
      final failed = _donors(
        source,
      ).singleWhere((donor) => donor.candidate.id == _id(1));
      expect(failed.extra['searchEvidenceOnly'], isTrue);
      expect(failed.extra['recordingDetail'], {
        'state': 'failed',
        'code': 'invalid_response',
      });
      expect(
        failed.candidate.extra['musicbrainzSearchRecording']['id'],
        _id(1),
      );
      expect(requests, hasLength(4));
    },
  );

  for (final invalid in ['artist', 'title', 'edition']) {
    test('a conflicting $invalid does not gain ambiguity retention', () async {
      final requests = <Uri>[];
      final pair = _provider(
        requests,
        badSearchArtist: invalid == 'artist' ? 'Other Performer' : null,
        badSearchTitle: invalid == 'title' ? 'Different Song' : null,
        version: invalid == 'edition' ? 'live' : null,
      );
      addTearDown(pair.transport.close);
      final selected = invalid == 'edition'
          ? const SongCandidate(
              providerId: 'catalog',
              id: 'song',
              title: 'Harbor Song',
              artist: 'Performer',
              metadata: {'version': 'studio'},
            )
          : _selection;
      await expectLater(
        pair.provider.resolve(selected),
        throwsA(
          isA<ProviderException>().having(
            (error) => error.code,
            'code',
            'unavailable',
          ),
        ),
      );
      expect(requests, hasLength(1));
    });
  }

  test(
    'cancellation during details stops without publishing a partial replacement',
    () async {
      final requests = <Uri>[];
      final cancel = CancellationToken();
      final pair = _provider(requests, cancelOnDetail: cancel);
      addTearDown(pair.transport.close);
      await expectLater(
        pair.provider.resolve(_selection, cancel: cancel),
        throwsA(
          isA<ProviderException>().having(
            (error) => error.code,
            'code',
            'cancelled',
          ),
        ),
      );
      expect(requests, hasLength(2));
    },
  );
}
