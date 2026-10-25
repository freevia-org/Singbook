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

  test('durations within three seconds agree; wider ones abstain', () {
    final close = _combine([
      _catalog('a', 'Harbor Lights (Remastered 2009)', 243),
      _catalog('b', 'The Mariners - Harbor Lights', 244.5),
    ]);
    expect(close.metadata['durationSeconds'], 243);
    final apart = _combine([
      _catalog('a', 'Harbor Lights (Remastered 2009)', 243),
      _catalog('b', 'The Mariners - Harbor Lights', 260),
    ]);
    expect(apart.metadata.containsKey('durationSeconds'), isFalse);
  });
}
