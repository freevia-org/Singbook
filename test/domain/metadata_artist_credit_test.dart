import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/metadata_artist_credit.dart';
import 'package:singbook/domain/lyric_word_identity.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart' show normalizedIdentity;

const mbid = '123e4567-e89b-42d3-a456-426614174000';
const artistId = '223e4567-e89b-42d3-a456-426614174001';

String normalize(String value) => normalizedIdentity(value);

SongCandidate genius({
  String artist = 'Stan Getz & João Gilberto',
  List<JsonMap>? credits,
}) => SongCandidate(
  providerId: 'genius',
  id: '184030',
  title: 'The Girl from Ipanema',
  artist: artist,
  metadata: {
    'credits':
        credits ??
        [
          {'role': 'Artist', 'name': 'Stan Getz'},
          {'role': 'Artist', 'name': 'João Gilberto'},
          {'role': 'Featured artist', 'name': 'Antônio Carlos Jobim'},
          {'role': 'Featured artist', 'name': 'Astrud Gilberto'},
        ],
  },
);

SongCandidate musicBrainz({
  String? artist,
  List<JsonMap>? artistCredits,
  String scope = 'recording',
  Map<String, String>? ids,
}) => SongCandidate(
  providerId: 'musicbrainz',
  id: mbid,
  title: 'The Girl from Ipanema',
  artist: artist ?? 'Stan Getz / João Gilberto feat. Antônio Carlos Jobim',
  recordingIds: {'musicbrainz': mbid, ...?ids},
  metadata: {
    'identityScope': scope,
    'artistCredits':
        artistCredits ??
        [
          {'name': 'Stan Getz', 'musicbrainzId': artistId, 'joinPhrase': ' / '},
          {
            'name': 'João Gilberto',
            'musicbrainzId': '323e4567-e89b-42d3-a456-426614174002',
            'joinPhrase': ' feat. ',
          },
          {
            'name': 'Antônio Carlos Jobim',
            'musicbrainzId': '423e4567-e89b-42d3-a456-426614174003',
            'joinPhrase': '',
          },
        ],
  },
);

void main() {
  group('musicBrainzArtistCreditEvidence', () {
    test(
      'accepts complete primary and explicitly supported featured credits',
      () {
        final result = musicBrainzArtistCreditEvidence(
          genius(),
          musicBrainz(),
          normalize,
        );
        expect(result, isNotNull);
        expect(result!['method'], 'musicbrainz-artist-credit');
        expect(result['primaryArtists'], ['stan getz', 'joão gilberto']);
        expect(result['featuredArtists'], ['antonio carlos jobim']);
        expect(result['musicbrainzArtistCredits'], hasLength(3));
      },
    );

    test('ignores accents while retaining ñ in normalization', () {
      final g = genius(
        artist: 'José & Peñ a',
        credits: [
          {'role': 'Artist', 'name': 'José'},
          {'role': 'Artist', 'name': 'Peñ a'},
        ],
      );
      final m = musicBrainz(
        artist: 'Jose / Peñ a',
        artistCredits: [
          {'name': 'Jose', 'musicbrainzId': artistId, 'joinPhrase': ' / '},
          {
            'name': 'Peñ a',
            'musicbrainzId': '323e4567-e89b-42d3-a456-426614174002',
            'joinPhrase': '',
          },
        ],
      );
      expect(musicBrainzArtistCreditEvidence(g, m, normalize), isNotNull);
      expect(foldLyricVowelAccents('café año'), 'cafe año');
    });

    test(
      'permits source featured-credit subsets while requiring all primary names',
      () {
        final onlyRequiredFeatured = genius(
          credits: [
            {'role': 'Artist', 'name': 'Stan Getz'},
            {'role': 'Artist', 'name': 'João Gilberto'},
            {'role': 'Featured artist', 'name': 'Antônio Carlos Jobim'},
          ],
        );
        expect(
          musicBrainzArtistCreditEvidence(
            onlyRequiredFeatured,
            musicBrainz(),
            normalize,
          ),
          isNotNull,
        );
        final missingPrimary = genius(
          artist: 'Stan Getz',
          credits: [
            {'role': 'Artist', 'name': 'Stan Getz'},
            {'role': 'Featured artist', 'name': 'Antônio Carlos Jobim'},
          ],
        );
        expect(
          musicBrainzArtistCreditEvidence(
            missingPrimary,
            musicBrainz(),
            normalize,
          ),
          isNull,
        );
      },
    );

    test(
      'matches one Genius joint Artist credit to two MusicBrainz primary nodes',
      () {
        final grouped = genius(
          credits: [
            {'role': 'Artist', 'name': 'Stan Getz & João Gilberto'},
            {'role': 'Featured artist', 'name': 'Antônio Carlos Jobim'},
          ],
        );
        expect(
          musicBrainzArtistCreditEvidence(grouped, musicBrainz(), normalize),
          isNotNull,
        );
      },
    );

    test('rejects missing, wrong-role, or extra featured evidence', () {
      for (final credits in [
        [
          {'role': 'Artist', 'name': 'Stan Getz'},
          {'role': 'Artist', 'name': 'João Gilberto'},
        ],
        [
          {'role': 'Artist', 'name': 'Stan Getz'},
          {'role': 'Artist', 'name': 'João Gilberto'},
          {'role': 'Writer', 'name': 'Antônio Carlos Jobim'},
        ],
        [
          {'role': 'Artist', 'name': 'Stan Getz'},
          {'role': 'Artist', 'name': 'João Gilberto'},
          {'role': 'Featured artist', 'name': 'Wrong Person'},
        ],
      ]) {
        expect(
          musicBrainzArtistCreditEvidence(
            genius(credits: credits),
            musicBrainz(),
            normalize,
          ),
          isNull,
        );
      }
    });

    test(
      'rejects malformed source credits, reconstruction mismatch, duplicates, and overlong lists',
      () {
        final valid = musicBrainz().metadata['artistCredits'] as List;
        final malformed = [
          <JsonMap>[],
          [
            valid.first as JsonMap,
            {...valid[1] as JsonMap, 'musicbrainzId': 'bad'},
          ],
          [valid.first as JsonMap, valid.first as JsonMap],
          [...valid, ...valid, ...valid],
          [
            valid.first as JsonMap,
            {...valid[1] as JsonMap, 'joinPhrase': ' with '},
          ],
        ];
        for (final source in malformed) {
          expect(
            musicBrainzArtistCreditEvidence(
              genius(),
              musicBrainz(artistCredits: source.cast<JsonMap>()),
              normalize,
            ),
            isNull,
          );
        }
        expect(
          musicBrainzArtistCreditEvidence(
            genius(),
            musicBrainz(
              artist:
                  'Stan Getz feat. João Gilberto feat. Antônio Carlos Jobim',
            ),
            normalize,
          ),
          isNull,
        );
      },
    );

    test('requires the correct provider identity and recording scope', () {
      expect(
        musicBrainzArtistCreditEvidence(
          genius(),
          musicBrainz(scope: 'release'),
          normalize,
        ),
        isNull,
      );
      expect(
        musicBrainzArtistCreditEvidence(
          genius(),
          musicBrainz(ids: {'isrc': 'USABC1234567'}),
          normalize,
        ),
        isNotNull,
      );
      final wrongProvider = SongCandidate(
        providerId: 'musicbrainz',
        id: 'x',
        title: 'x',
        artist: 'x',
      );
      expect(
        musicBrainzArtistCreditEvidence(genius(), wrongProvider, normalize),
        isNull,
      );
      for (final id in ['0', '0184030', '999999999999999999999']) {
        final invalidId = SongCandidate(
          providerId: 'genius',
          id: id,
          title: 'Song',
          artist: 'Stan Getz & João Gilberto',
          metadata: genius().metadata,
        );
        expect(
          musicBrainzArtistCreditEvidence(invalidId, musicBrainz(), normalize),
          isNull,
        );
      }
    });

    test(
      'rejects contradictory shared recording IDs and incompatible editions',
      () {
        final g = SongCandidate(
          providerId: 'genius',
          id: '184030',
          title: 'Song',
          artist: 'Stan Getz & João Gilberto',
          recordingIds: {'isrc': 'USABC1234567'},
          metadata: {
            'credits': [
              {'role': 'Artist', 'name': 'Stan Getz'},
              {'role': 'Artist', 'name': 'João Gilberto'},
              {'role': 'Featured artist', 'name': 'Antônio Carlos Jobim'},
            ],
          },
        );
        expect(
          musicBrainzArtistCreditEvidence(
            g,
            musicBrainz(ids: {'isrc': 'USXYZ1234567'}),
            normalize,
          ),
          isNull,
        );
        final live = SongCandidate(
          providerId: 'genius',
          id: '184030',
          title: 'Song',
          artist: 'Stan Getz & João Gilberto',
          album: 'Album (Live)',
          metadata: genius().metadata,
        );
        final studioMb = SongCandidate(
          providerId: 'musicbrainz',
          id: mbid,
          title: 'Song',
          artist: 'Stan Getz / João Gilberto feat. Antônio Carlos Jobim',
          album: 'Album (Studio)',
          recordingIds: {'musicbrainz': mbid},
          metadata: musicBrainz().metadata,
        );
        expect(
          musicBrainzArtistCreditEvidence(live, studioMb, normalize),
          isNull,
        );
      },
    );

    test(
      'accepts a supported join between featured names and rejects duplicate Genius credits',
      () {
        final multipleFeatures = musicBrainz(
          artist:
              'Stan Getz / João Gilberto feat. Antônio Carlos Jobim & Astrud Gilberto',
          artistCredits: [
            {
              'name': 'Stan Getz',
              'musicbrainzId': artistId,
              'joinPhrase': ' / ',
            },
            {
              'name': 'João Gilberto',
              'musicbrainzId': '323e4567-e89b-42d3-a456-426614174002',
              'joinPhrase': ' feat. ',
            },
            {
              'name': 'Antônio Carlos Jobim',
              'musicbrainzId': '423e4567-e89b-42d3-a456-426614174003',
              'joinPhrase': ' & ',
            },
            {
              'name': 'Astrud Gilberto',
              'musicbrainzId': '523e4567-e89b-42d3-a456-426614174004',
              'joinPhrase': '',
            },
          ],
        );
        expect(
          musicBrainzArtistCreditEvidence(
            genius(),
            multipleFeatures,
            normalize,
          ),
          isNotNull,
        );
        final duplicate = genius(
          credits: [
            {'role': 'Artist', 'name': 'Stan Getz'},
            {'role': 'Artist', 'name': 'Stan Getz'},
            {'role': 'Artist', 'name': 'João Gilberto'},
          ],
        );
        expect(
          musicBrainzArtistCreditEvidence(duplicate, musicBrainz(), normalize),
          isNull,
        );
      },
    );
  });
}
