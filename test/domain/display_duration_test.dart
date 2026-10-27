import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

const _selected = SongCandidate(
  providerId: 'lyrics',
  id: 's',
  title: 'Harbor Song',
  artist: 'The Mariners',
);

// Invented lyrics only.
const _lyrics =
    'Paper lanterns drifting over quiet harbor water\n'
    'Every window glowing softly as the evening falls';

SourceResult _catalog(String id, String album, double seconds) => SourceResult(
  candidate: SongCandidate(
    providerId: id,
    id: id,
    title: 'Harbor Song',
    artist: 'The Mariners',
    album: album,
    durationSeconds: seconds,
  ),
  body: _lyrics,
  matchKind: MatchKind.sameSong,
);

SongDocument _combine(List<SourceResult> others) => combineSources(_selected, [
  SourceResult(
    candidate: _selected,
    body: _lyrics,
    matchKind: MatchKind.sameRecording,
    metadata: const {'album': 'Harbor Lights'},
  ),
  ...others,
]);

void main() {
  test('a remastered or artist-prefixed album lends its duration', () {
    expect(
      _combine([
        _catalog('a', 'Harbor Lights (Remastered 2009)', 243),
      ]).metadata['durationSeconds'],
      243,
    );
    expect(
      _combine([
        _catalog('b', 'The Mariners - Harbor Lights', 243.36),
      ]).metadata['durationSeconds'],
      243.36,
    );
  });

  test('another edition of the album lends nothing', () {
    expect(
      _combine([
        _catalog('c', 'Harbor Lights... Naked', 234),
      ]).metadata.containsKey('durationSeconds'),
      isFalse,
    );
  });

  test(
    'duration conflicts retain ranked alternatives and choose deterministically',
    () {
    final close = _combine([
      _catalog('a', 'Harbor Lights (Remastered 2009)', 243),
      _catalog('b', 'The Mariners - Harbor Lights', 244.5),
    ]);
    expect(close.metadata['durationSeconds'], 243);
    final apart = _combine([
      _catalog('a', 'Harbor Lights (Remastered 2009)', 243),
      _catalog('b', 'The Mariners - Harbor Lights', 260),
    ]);
    expect(apart.metadata['durationSeconds'], 243);
    expect(apart.extra['fieldOrigins']['durationSeconds'], 'a:a');
    final claims = (apart.extra['evidenceRanking'] as Map)['claims'] as List;
    expect(
      claims
          .whereType<Map>()
          .where((claim) => claim['field'] == 'metadata.durationSeconds')
          .map((claim) => claim['value']),
      containsAll([243, 260]),
    );
  });

  test('a live or acoustic edition of the album lends nothing', () {
    for (final album in ['Harbor Lights (Live)', 'Harbor Lights - Acoustic']) {
      expect(
        _combine([
          _catalog('a', album, 250),
        ]).metadata.containsKey('durationSeconds'),
        isFalse,
        reason: album,
      );
    }
  });

  test('duration ties keep all claims and resolve reproducibly', () {
    // 103, 104 and 105 agree within three seconds; 100 does not.
    final majority = _combine([
      _catalog('a', 'Harbor Lights', 100),
      _catalog('b', 'Harbor Lights', 103),
      _catalog('c', 'Harbor Lights', 104),
      _catalog('d', 'Harbor Lights', 105),
    ]);
    expect(majority.metadata['durationSeconds'], inInclusiveRange(103, 105));
    // Two of four is no majority.
    final split = _combine([
      _catalog('a', 'Harbor Lights', 100),
      _catalog('b', 'Harbor Lights', 101),
      _catalog('c', 'Harbor Lights', 110),
      _catalog('d', 'Harbor Lights', 111),
    ]);
    expect(split.metadata['durationSeconds'], isNotNull);
    expect(split.extra['fieldOrigins']['durationSeconds'], isNotNull);
    final splitClaims = (split.extra['evidenceRanking'] as Map)['claims'] as List;
    expect(
      splitClaims
          .whereType<Map>()
          .where((claim) => claim['field'] == 'metadata.durationSeconds')
          .map((claim) => claim['value']),
      containsAll([100, 101, 110, 111]),
    );
    // [100, 103] and [103, 106] are equally supported. Keep both claims,
    // and require the tie-break to be independent of result arrival order.
    final tied = _combine([
      _catalog('a', 'Harbor Lights', 100),
      _catalog('b', 'Harbor Lights', 103),
      _catalog('c', 'Harbor Lights', 106),
    ]);
    final tiedReversed = _combine([
      _catalog('c', 'Harbor Lights', 106),
      _catalog('b', 'Harbor Lights', 103),
      _catalog('a', 'Harbor Lights', 100),
    ]);
    expect(tied.metadata['durationSeconds'], isNotNull);
    expect(
      tiedReversed.metadata['durationSeconds'],
      tied.metadata['durationSeconds'],
    );
    expect(
      tied.extra['fieldOrigins']['durationSeconds'],
      tiedReversed.extra['fieldOrigins']['durationSeconds'],
    );
    final tiedClaims = (tied.extra['evidenceRanking'] as Map)['claims'] as List;
    expect(
      tiedClaims
          .whereType<Map>()
          .where((claim) => claim['field'] == 'metadata.durationSeconds')
          .map((claim) => claim['value']),
      containsAll([100, 103, 106]),
    );
  });
}
