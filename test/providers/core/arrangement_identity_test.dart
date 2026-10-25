import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

class _Chords implements LyricsProvider {
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'chords',
    name: 'Chords',
    capabilities: {'lyrics', 'chords'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => const [];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) => throw UnimplementedError();
}

SongCandidate _song(String title, String artist, [String provider = 'x']) =>
    SongCandidate(
      providerId: provider,
      id: title,
      title: title,
      artist: artist,
    );

// Invented lyrics only.
const _lines = [
  'Paper lanterns drifting over quiet harbor water',
  'Every window glowing softly as the evening falls',
  'Someone hums a tune along the winding river road',
  'Bells are ringing gently down the empty market halls',
];

void main() {
  test('chord sites may credit only the main artist and drop "The"', () {
    final chords = _Chords();
    expect(
      sameArrangement(
        _song('Harbor Lights', 'The Mariners & The Crew'),
        _song('Harbor Lights', 'The Mariners'),
        chords,
      ),
      isTrue,
    );
    expect(
      sameArrangement(
        _song('The Harbor of the Lights', 'The Mariners'),
        _song('Harbor Of The Lights', 'The Mariners'),
        chords,
      ),
      isTrue,
    );
    expect(
      sameArrangement(
        _song('Harbor Lights', 'The Mariners & The Crew'),
        _song('Harbor Lights', 'The Crew'),
        chords,
      ),
      isFalse,
    );
  });

  test('a corroborated chart crediting the main artist gives chords', () {
    const selected = SongCandidate(
      providerId: 'lyrics',
      id: 'l',
      title: 'The Harbor Song',
      artist: 'The Mariners & The Crew',
    );
    SongDocument combine(JsonMap extra) => combineSources(selected, [
      SourceResult(
        candidate: selected,
        body: _lines.join('\n'),
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: _song('Harbor Song', 'The Mariners', 'chords'),
        body: [for (final line in _lines) '[G]$line'].join('\n'),
        matchKind: MatchKind.sameSong,
        extra: extra,
      ),
    ]);
    // Discovery marks arrangement-only matches and corroborates their words.
    final doc = combine(const {'requiresLyricsAgreement': true});
    expect(
      parseArrangement(doc.body).where((l) => l.chords.isNotEmpty).length,
      _lines.length,
    );
    // Without that mark the stricter identity rule applies.
    expect(combine(const {}).hasChords, isFalse);
  });
}
