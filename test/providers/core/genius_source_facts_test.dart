import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/catalogs.dart';
import 'package:singbook/providers/core/recording_key.dart';

const words =
    'Harbor lanterns gather where the quiet river bends\nSilver windows carry evening over winding stone streets';
SongCandidate candidate({
  Object? appleId = '878762106',
  Object? location = 'Studio A',
  Object? display = 'April 1964',
}) => GeniusProvider.parseSong({
  'id': 123,
  'title': 'Invented Harbor',
  'primary_artist': {'name': 'Synthetic Artist'},
  'url': 'https://genius.com/invented-harbor-lyrics',
  'recording_location': location,
  'release_date': null,
  'release_date_for_display': display,
  'apple_music_id': appleId,
});
void main() {
  test(
    'retains explicit location and month display without inventing exact date or recording ID',
    () {
      final c = candidate();
      expect(c.metadata['recordingLocation'], 'Studio A');
      expect(c.metadata['releaseDateDisplay'], 'April 1964');
      expect(c.metadata.containsKey('releaseDate'), false);
      expect(c.metadata.containsKey('year'), false);
      expect(c.recordingIds, isEmpty);
      expect(c.extra['sourceCatalogIdentifiers'], {
        'appleMusicTrackId': '878762106',
      });
      expect(c.metadata.containsKey('mediaLinks'), false);
      final ids = recordingIdentifiers(SourceResult(candidate: c, body: words));
      expect(ids.spotify, isEmpty);
      expect(ids.isrcs, isEmpty);
    },
  );
  test('bounds source fields and rejects malformed identifier claims', () {
    for (final id in [
      null,
      0,
      -1,
      1.2,
      true,
      '0',
      '01',
      '123x',
      '123456789012345678901',
    ]) {
      expect(candidate(appleId: id).extra, isEmpty, reason: '$id');
    }
    expect(candidate(appleId: 42).extra['sourceCatalogIdentifiers'], {
      'appleMusicTrackId': '42',
    });
    expect(
      candidate(location: 'Studio\u202e A').metadata['recordingLocation'],
      'Studio A',
    );
    final c = candidate(location: 'x' * 301, display: {'date': 'not text'});
    expect(c.metadata.containsKey('recordingLocation'), false);
    expect(c.metadata.containsKey('releaseDateDisplay'), false);
  });
  test(
    'own recording facts retain contributor provenance and survive source export',
    () {
      final c = candidate();
      final source = SourceResult(
        candidate: c,
        body: words,
        matchKind: MatchKind.sameRecording,
      );
      final song = combineSources(c, [source]);
      expect(song.metadata['recordingLocation'], 'Studio A');
      expect(song.metadata['releaseDateDisplay'], 'April 1964');
      expect(song.extra['fieldOrigins']['recordingLocation'], source.id);
      final decoded = ChordProCodec().decode(ChordProCodec().encode(song));
      expect(decoded.metadata['recordingLocation'], 'Studio A');
      expect(decoded.metadata['releaseDateDisplay'], 'April 1964');
      expect(decoded.sources.single.candidate.extra, c.extra);
      expect(decoded.sources.single.candidate.recordingIds, isEmpty);
    },
  );
  test(
    'same-song performer/album similarity cannot donate recording facts',
    () {
      final c = candidate(location: null, display: null, appleId: null);
      final own = SourceResult(
        candidate: c,
        body: words,
        matchKind: MatchKind.sameRecording,
      );
      final foreign = SourceResult(
        candidate: SongCandidate(
          providerId: 'other',
          id: 'different',
          title: c.title,
          artist: c.artist,
        ),
        body: words,
        metadata: {
          'recordingLocation': 'Other Studio',
          'releaseDateDisplay': 'May 1980',
        },
        matchKind: MatchKind.sameSong,
      );
      final song = combineSources(c, [own, foreign]);
      expect(song.metadata.containsKey('recordingLocation'), false);
      expect(song.metadata.containsKey('releaseDateDisplay'), false);
      expect(song.body, words);
    },
  );
}
