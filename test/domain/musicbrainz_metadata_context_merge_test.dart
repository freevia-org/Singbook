import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

const selected = SongCandidate(
  providerId: 'genius',
  id: '821238',
  title: 'Harbor Song',
  artist: 'Stan Getz & João Gilberto',
  durationSeconds: 322.826,
);
const lyrics =
    'Harbor lanterns gather where the quiet river bends\nSilver windows carry evening over winding stone streets\nA distant bell reminds the sailors to return home';
SongCandidate resolved({String id = '821238'}) => SongCandidate(
  providerId: 'genius',
  id: id,
  title: selected.title,
  artist: selected.artist,
  album: 'Getz/Gilberto',
  durationSeconds: 322.826,
  metadata: {
    'credits': [
      {'role': 'Artist', 'name': selected.artist},
      {'role': 'Featured artist', 'name': 'Antônio Carlos Jobim'},
    ],
  },
);
SourceResult metadata({
  double duration = 322.826,
  Map<String, String> ids = const {},
  String body = '',
  MatchKind kind = MatchKind.sameSong,
  bool pending = false,
}) => SourceResult(
  candidate: SongCandidate(
    providerId: 'musicbrainz',
    id: 'fd889e33-a067-498f-bbf8-9ffe305bde16',
    title: selected.title,
    artist: 'Stan Getz / João Gilberto featuring Antônio Carlos Jobim',
    album: 'Getz/Gilberto',
    durationSeconds: duration,
    recordingIds: {
      'musicbrainz': 'fd889e33-a067-498f-bbf8-9ffe305bde16',
      ...ids,
    },
    metadata: {
      'identityScope': 'recording',
      'artistCredits': [
        {
          'name': 'Stan Getz',
          'musicbrainzId': '223e4567-e89b-42d3-a456-426614174001',
          'joinPhrase': ' / ',
        },
        {
          'name': 'João Gilberto',
          'musicbrainzId': '323e4567-e89b-42d3-a456-426614174002',
          'joinPhrase': ' featuring ',
        },
        {
          'name': 'Antônio Carlos Jobim',
          'musicbrainzId': '423e4567-e89b-42d3-a456-426614174003',
          'joinPhrase': '',
        },
      ],
    },
  ),
  body: body,
  matchKind: kind,
  metadata: {
    'isrcs': ['USPR36301961'],
    'moodTags': ['metadata-context-proof'],
  },
  extra: {'metadataOnly': true, if (pending) 'pendingMatchCheck': true},
);
void main() {
  test(
    'resolved selected lyrics admit structured metadata without replacing lyric body or claiming recording equality',
    () {
      final reference = SourceResult(
        candidate: resolved(),
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      );
      final donor = metadata();
      final song = combineSources(selected, [reference, donor]);
      expect(song.body, lyrics);
      expect(song.metadata['artistCredits'], hasLength(3));
      expect(song.extra['fieldOrigins']['artistCredits'], donor.id);
      expect(song.metadata['moodTags'], isNull);
      expect(song.metadata['isrcs'], isNull);
      expect(
        song.sources.singleWhere((s) => s.id == donor.id).matchKind,
        MatchKind.sameSong,
      );
      expect(song.metadata['key'], isNull);
    },
  );
  test(
    'matching display credit cannot authorize malformed structured artist IDs',
    () {
      final original = metadata();
      final candidate = SongCandidate.fromJson({
        ...original.candidate.toJson(),
        'artist': selected.artist,
        'metadata': {
          'identityScope': 'recording',
          'artistCredits': [
            {
              'name': selected.artist,
              'musicbrainzId': 'wrong',
              'joinPhrase': '',
            },
          ],
        },
      });
      final donor = SourceResult(
        candidate: candidate,
        body: '',
        matchKind: MatchKind.sameSong,
        extra: {'metadataOnly': true},
      );
      final song = combineSources(selected, [
        SourceResult(
          candidate: resolved(),
          body: lyrics,
          matchKind: MatchKind.sameRecording,
        ),
        donor,
      ]);
      expect(song.metadata['artistCredits'], isNull);
      expect(song.body, lyrics);
    },
  );
  for (final scenario in [
    'missing reference',
    'other identity',
    'duration',
    'pending',
    'unverified',
    'body',
  ]) {
    test('context rejects $scenario', () {
      final reference = SourceResult(
        candidate: scenario == 'missing reference'
            ? selected
            : resolved(id: scenario == 'other identity' ? '999' : '821238'),
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      );
      final donor = metadata(
        duration: scenario == 'duration' ? 400 : 322.826,
        pending: scenario == 'pending',
        kind: scenario == 'unverified'
            ? MatchKind.unverified
            : MatchKind.sameSong,
        body: scenario == 'body' ? 'Other lyric text' : '',
      );
      final song = combineSources(selected, [reference, donor]);
      expect(song.metadata['artistCredits'], isNull);
      expect(song.body, lyrics);
    });
  }
}
