import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

// Original invented text. Alternate performances share a refrain but cannot
// replace the selected recording's full verse as chord corroboration evidence.
const _original = [
  'Amber windows shine across the quiet harbor water',
  'Paper lanterns drift beneath the silver evening clouds',
  'Every footstep carries distant echoes from the shore',
  'We return together as the morning bells ring out',
];
const _alternate = [
  'Electric towers scatter neon colors through the crowded city',
  'Dancers follow thunder as the midnight engines roar awake',
  'Scarlet sparks are rising over rooftops bright with summer rain',
  'Velvet voices call beyond the avenues of restless strangers',
  'Amber windows shine across the quiet harbor water',
  'Paper lanterns drift beneath the silver evening clouds',
];
const _selected = SongCandidate(
  providerId: 'catalog',
  id: 'original',
  title: 'Harbor Song',
  artist: 'Lanterns',
);

class _Provider implements LyricsProvider {
  _Provider(this.id, this.body, {this.chords = false});
  final String id, body;
  final bool chords;
  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: id,
    name: id,
    capabilities: {'lyrics', if (chords) 'chords'},
  );
  SongCandidate get candidate => SongCandidate(
    providerId: id,
    id: id == 'catalog' ? 'original' : 'chart',
    title: 'Harbor Song',
    artist: 'Lanterns',
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [candidate];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(candidate: candidate, body: body);
}

void main() {
  test(
    'longer same-song remix cannot disqualify original-recording chords',
    () async {
      for (final reverse in [false, true]) {
        final providers = [
          _Provider('catalog', _original.join('\n')),
          _Provider('lyricsovh', _alternate.join('\n')),
          _Provider(
            'chords',
            [for (final line in _original) '[G]$line'].join('\n'),
            chords: true,
          ),
        ];
        final results = await SourceDiscoveryService(
          reverse ? providers.reversed.toList() : providers,
        ).discover(_selected);
        final chart = results.singleWhere(
          (r) => r.candidate.providerId == 'chords',
        );
        expect(chart.matchKind, isNot(MatchKind.rejected));
      }
    },
  );
  test(
    'without selected-recording lyrics, same-song corroboration remains available',
    () async {
      final results = await SourceDiscoveryService([
        _Provider('lyricsovh', _original.join('\n')),
        _Provider(
          'chords',
          [for (final line in _original) '[G]$line'].join('\n'),
          chords: true,
        ),
      ]).discover(_selected);
      expect(
        results.singleWhere((r) => r.hasChords).matchKind,
        isNot(MatchKind.rejected),
      );
    },
  );
}
