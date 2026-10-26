import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/transport.dart';

const recording = 'fd889e33-a067-498f-bbf8-9ffe305bde16';
JsonMap row({
  String album = 'Getz/Gilberto',
  String title = 'The Girl from Ipanema',
}) => {
  'id': recording,
  'title': title,
  'length': 322826,
  'artist-credit': [
    {
      'name': 'Stan Getz',
      'joinphrase': ' / ',
      'artist': {'id': '223e4567-e89b-42d3-a456-426614174001'},
    },
    {
      'name': 'João Gilberto',
      'joinphrase': ' featuring ',
      'artist': {'id': '323e4567-e89b-42d3-a456-426614174002'},
    },
    {
      'name': 'Antônio Carlos Jobim',
      'artist': {'id': '423e4567-e89b-42d3-a456-426614174003'},
    },
  ],
  'releases': [
    {'id': 'release', 'title': album},
  ],
  'isrcs': ['USPR36301961'],
};
SongCandidate selection({bool feature = true}) => SongCandidate(
  providerId: 'genius',
  id: '821238',
  title: 'The Girl from Ipanema',
  artist: 'Stan Getz & João Gilberto',
  album: 'Getz/Gilberto',
  durationSeconds: 322.826,
  metadata: {
    'credits': [
      {'role': 'Artist', 'name': 'Stan Getz & João Gilberto'},
      {
        'role': feature ? 'Featured artist' : 'Writer',
        'name': 'Antônio Carlos Jobim',
      },
    ],
  },
);
MusicBrainzProvider provider(List<Uri> requests, List<JsonMap> rows) =>
    MusicBrainzProvider(
      ProviderTransport(
        hostInterval: Duration.zero,
        client: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('/$recording')
                  ? row()
                  : {'recordings': rows},
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
void main() {
  test(
    'album-scoped individual credit search retains source joins and recording metadata',
    () async {
      final requests = <Uri>[];
      final result = await provider(requests, [row()]).resolve(selection());
      expect(requests, hasLength(2));
      expect(
        requests.first.queryParameters['query'],
        'recording:"The Girl from Ipanema" AND artistname:"Stan Getz" AND artistname:"João Gilberto" AND release:"Getz/Gilberto"',
      );
      expect(
        result.candidate.artist,
        'Stan Getz / João Gilberto featuring Antônio Carlos Jobim',
      );
      expect(result.candidate.recordingIds, {'musicbrainz': recording});
      expect(result.metadata['isrcs'], ['USPR36301961']);
      expect(result.extra['artistIdentityEvidence'], isNotNull);
      expect(result.extra['metadataOnly'], true);
      expect(result.body, isEmpty);
      expect(result.matchKind, MatchKind.unverified);
    },
  );
  for (final invalid in [
    'wrong album',
    'wrong title',
    'unsupported feature',
    'ambiguous',
  ]) {
    test('rejects $invalid before recording fetch', () async {
      final requests = <Uri>[];
      final rows = invalid == 'wrong album'
          ? [row(album: 'Getz/Gilberto #2')]
          : invalid == 'wrong title'
          ? [row(title: 'Other song')]
          : invalid == 'ambiguous'
          ? [row(), row()]
          : [row()];
      await expectLater(
        provider(
          requests,
          rows,
        ).resolve(selection(feature: invalid != 'unsupported feature')),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            invalid == 'ambiguous' ? 'ambiguous_match' : 'unavailable',
          ),
        ),
      );
      expect(requests, hasLength(1));
    });
  }
}
