import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/reviewed_chart_artist.dart';

const _chartId = '/a/wsa/beyonce-halo-chords-s190194';

void main() {
  SongCandidate candidate({
    String providerId = 'songsterr',
    String id = _chartId,
    String artist = 'Beyoncé',
    String title = 'Halo',
    Object? providerArtistId = '87340',
    Object? providerSongId = '190194',
    JsonMap metadata = const {},
    Map<String, String> recordingIds = const {},
  }) => SongCandidate(
    providerId: providerId,
    id: id,
    artist: artist,
    title: title,
    metadata: metadata,
    recordingIds: recordingIds,
    extra: {
      'providerArtistId': ?providerArtistId,
      'providerSongId': ?providerSongId,
    },
  );

  test('returns reviewed evidence for the exact artist ID/name pairs', () {
    final search = reviewedChartArtistCredit(candidate());
    final resolved = reviewedChartArtistCredit(
      candidate(artist: 'Beyonce Knowles', providerArtistId: '6487'),
    );

    expect(search, isNotNull);
    expect(search!.canonicalName, 'Beyoncé');
    expect(search.sourceName, 'Beyoncé');
    expect(search.providerArtistId, '87340');
    expect(search.providerSongId, '190194');
    expect(
      search.evidenceUrls,
      contains('https://www.sonymusic.fr/artist/beyonce/'),
    );
    expect(resolved, isNotNull);
    expect(resolved!.sourceName, 'Beyonce Knowles');
    expect(reviewedChartArtistCredit(candidate(artist: 'BEYONCÉ')), isNotNull);
    expect(
      sameReviewedChartArtist(
        candidate(),
        candidate(artist: 'Beyonce Knowles', providerArtistId: '6487'),
      ),
      isTrue,
    );
  });

  test('keeps source credit and provider IDs in serialized evidence', () {
    final original = candidate(
      artist: 'Beyonce Knowles',
      providerArtistId: '6487',
    );
    final originalJson = original.toJson();
    final evidence = reviewedChartArtistCredit(original)!.toJson();

    expect(originalJson['artist'], 'Beyonce Knowles');
    expect(originalJson['providerArtistId'], '6487');
    expect(evidence['canonicalName'], 'Beyoncé');
    expect(evidence['sourceName'], 'Beyonce Knowles');
    expect(evidence['providerArtistId'], '6487');
    expect(evidence['providerSongId'], '190194');
    expect(evidence['evidenceUrls'], isA<List<String>>());
  });

  test('rejects missing, unknown, malformed, or mismatched artist IDs', () {
    expect(
      reviewedChartArtistCredit(candidate(providerArtistId: null)),
      isNull,
    );
    expect(reviewedChartArtistCredit(candidate(providerSongId: null)), isNull);
    expect(
      reviewedChartArtistCredit(candidate(providerArtistId: 6487)),
      isNull,
    );
    for (final id in ['0', '0006487', '+6487', '6487x', '1234567890123456']) {
      expect(
        reviewedChartArtistCredit(candidate(providerArtistId: id)),
        isNull,
        reason: id,
      );
    }
    expect(
      reviewedChartArtistCredit(candidate(providerArtistId: '999999')),
      isNull,
    );
    expect(
      reviewedChartArtistCredit(
        candidate(artist: 'Beyonce Knowles', providerArtistId: '87340'),
      ),
      isNull,
    );
    expect(
      reviewedChartArtistCredit(
        candidate(artist: 'Beyoncé', providerArtistId: '6487'),
      ),
      isNull,
    );
    expect(
      reviewedChartArtistCredit(
        candidate(artist: 'Beyonce Kñowles', providerArtistId: '6487'),
      ),
      isNull,
    );
  });

  test('rejects another provider and invalid or tricked chart paths', () {
    expect(reviewedChartArtistCredit(candidate(providerId: 'genius')), isNull);
    for (final id in [
      'https://www.songsterr.com/a/wsa/beyonce-halo-chords-s190194',
      '/a/wsa/../beyonce-halo-chords-s190194',
      '/a/wsa/beyonce%2fhalo-chords-s190194',
      '/a/wsa/beyonce-halo-chords-s190194?next=/other',
      '/a/wsa/beyonce-halo-chords-s190194#fragment',
      r'/a/wsa/beyonce\halo-chords-s190194',
    ]) {
      expect(reviewedChartArtistCredit(candidate(id: id)), isNull, reason: id);
    }
    expect(
      reviewedChartArtistCredit(candidate(providerSongId: '190195')),
      isNull,
    );
  });

  test(
    'same reviewed artist also requires same provider chart and full title',
    () {
      final search = candidate();
      final resolved = candidate(
        artist: 'Beyonce Knowles',
        providerArtistId: '6487',
      );
      expect(sameReviewedChartArtist(search, resolved), isTrue);
      expect(
        sameReviewedChartArtist(
          search,
          candidate(providerId: 'another-provider'),
        ),
        isFalse,
      );
      expect(
        sameReviewedChartArtist(
          search,
          candidate(id: '/a/wsa/beyonce-halo-live-chords-s190194'),
        ),
        isFalse,
      );
      expect(
        sameReviewedChartArtist(search, candidate(title: 'Halo (Live)')),
        isFalse,
      );
      expect(
        sameReviewedChartArtist(search, candidate(title: 'Halo Part 2')),
        isFalse,
      );
      expect(
        sameReviewedChartArtist(
          search,
          candidate(artist: 'Beyoncé', providerArtistId: 'unknown'),
        ),
        isFalse,
      );
    },
  );

  test('reviewed credit never overrides conflicting performance evidence', () {
    final search = candidate(metadata: {'edition': 'studio'});
    final resolved = candidate(
      artist: 'Beyonce Knowles',
      providerArtistId: '6487',
      metadata: {'edition': 'live'},
    );
    expect(sameReviewedChartArtist(search, resolved), isFalse);
    expect(
      sameReviewedChartArtist(
        candidate(recordingIds: {'isrc': 'USAA10000001'}),
        candidate(
          artist: 'Beyonce Knowles',
          providerArtistId: '6487',
          recordingIds: {'isrc': 'USAA10000002'},
        ),
      ),
      isFalse,
    );
    expect(
      sameReviewedChartArtist(candidate(title: ''), candidate(title: '')),
      isFalse,
    );
  });
}
