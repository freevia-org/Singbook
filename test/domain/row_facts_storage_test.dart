import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/search_grouping.dart';

const _row = SongCandidate(
  providerId: 'catalog',
  id: 'song',
  title: 'Quiet Harbor',
  artist: 'Example Artist',
);

SourceResult _lyrics() => SourceResult(
  candidate: const SongCandidate(
    providerId: 'lyrics',
    id: 'song',
    title: 'Quiet Harbor',
    artist: 'Example Artist',
  ),
  body: 'Amber lanterns glow above the quiet harbor tonight',
  matchKind: MatchKind.sameSong,
);

void main() {
  final selected = withRowFacts(
    _row,
    album: 'Harbor Lights',
    durationSeconds: 215,
  );

  test('a search row\'s album and length fill what no source stated', () {
    final song = combineSources(selected, [_lyrics()]);
    expect(song.metadata['album'], 'Harbor Lights');
    expect(song.metadata['durationSeconds'], 215);
    // The borrowed facts are not stored under their transient keys anywhere
    // in the saved document.
    expect(jsonEncode(song.toJson()), isNot(contains('searchRow')));
  });

  test('the selected row\'s own album is kept over the search row\'s', () {
    const own = SongCandidate(
      providerId: 'catalog',
      id: 'song',
      title: 'Quiet Harbor',
      artist: 'Example Artist',
      album: 'Own Album',
    );
    final song = combineSources(
      withRowFacts(own, album: 'Harbor Lights', durationSeconds: 215),
      [_lyrics()],
    );
    expect(song.metadata['album'], 'Own Album');
    expect(jsonEncode(song.toJson()), isNot(contains('searchRow')));
  });
}
