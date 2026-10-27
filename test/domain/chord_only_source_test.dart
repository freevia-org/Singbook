import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

const chart = SongCandidate(
  providerId: 'chart',
  id: 'instrumental-1',
  title: 'Synthetic Instrumental',
  artist: '',
  metadata: {
    'instrumental': true,
    'hasLyrics': false,
    'identityScope': 'arrangement',
  },
);
SourceResult source({
  MatchKind kind = MatchKind.sameSong,
  Map<String, dynamic> extra = const {},
}) => SourceResult(
  candidate: chart,
  body: '{comment: A (repeat 2x)}\n[C] [C] [G] [G]',
  matchKind: kind,
  attribution: 'Synthetic chart credit',
  metadata: {'key': 'C'},
  extra: extra,
);

class ChartProvider implements LyricsProvider {
  ChartProvider({this.chords = true});
  final bool chords;
  var resolves = 0;
  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: 'chart',
    name: 'Synthetic chart',
    capabilities: {'lyrics', if (chords) 'chords'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [chart];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolves++;
    return source();
  }
}

void main() {
  test(
    'preferred exact chart stays eligible when matching lyrics are also found',
    () {
      const selected = SongCandidate(
        providerId: 'chart',
        id: 'selected-arrangement',
        title: 'Synthetic Song',
        artist: 'Known Artist',
        metadata: {'identityScope': 'arrangement'},
      );
      final selectedChart = SourceResult(
        candidate: selected,
        body:
            '[C]Ashes drift softly across the cold mountain while the river follows home',
        matchKind: MatchKind.sameSong,
        attribution: 'Synthetic chart credit',
      );
      final matchingLyrics = SourceResult(
        candidate: const SongCandidate(
          providerId: 'lyrics',
          id: 'synthetic-song',
          title: 'Synthetic Song',
          artist: 'Known Artist',
        ),
        body:
            'Gentle flowers awaken beneath the morning sky while our hearts remember yesterday',
        matchKind: MatchKind.sameSong,
      );

      final saved = combineSources(selected, [
        selectedChart,
        matchingLyrics,
      ], preferredSourceId: selectedChart.id);

      expect(saved.body, selectedChart.body);
      expect(
        saved.sources.map((source) => source.id),
        containsAll([selectedChart.id, matchingLyrics.id]),
      );
    },
  );

  test(
    'explicit own-source instrumental chart saves without invented lyrics',
    () {
      final result = source();
      final saved = combineSources(chart, [
        result,
      ], preferredSourceId: result.id);
      expect(saved.body, result.body);
      expect(saved.sources.single.toJson(), result.toJson());
      expect(saved.metadata['key'], 'C');
      expect(combineSources(chart, [result]).body, result.body);
    },
  );
  test('a selected source chart is never a foreign recording donor', () {
    final result = source();
    const foreign = SongCandidate(
      providerId: 'other',
      id: 'other-1',
      title: 'Synthetic Instrumental',
      artist: 'Known artist',
    );
    expect(
      () => combineSources(foreign, [result], preferredSourceId: result.id),
      throwsFormatException,
    );
    const unknownForeign = SongCandidate(
      providerId: 'other',
      id: 'unknown',
      title: 'Synthetic Instrumental',
      artist: '',
    );
    expect(
      () => combineSources(unknownForeign, [result]),
      throwsFormatException,
    );
  });
  test(
    'pending/rejected or uncorroborated chord-only source cannot bypass save checks',
    () {
      for (final result in [
        source(kind: MatchKind.rejected),
        source(kind: MatchKind.unverified),
        source(extra: {'pendingMatchCheck': true}),
        source(extra: {'requiresLyricsAgreement': true}),
        source(extra: {'requiresRecordingLyricsAgreement': true}),
      ]) {
        expect(
          () => combineSources(
            chart,
            [result],
            preferredSourceId: result.id,
            allowRejectedPreferredSource: true,
          ),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'only explicit selected chord-provider rows can resolve instrumental flags',
    () async {
      final own = ChartProvider();
      final result = await findMatchingSource(own, chart);
      expect(own.resolves, 1);
      expect(result.matchKind, MatchKind.sameSong);
      final external = ChartProvider();
      const foreign = SongCandidate(
        providerId: 'other',
        id: 'other-1',
        title: 'Synthetic Instrumental',
        artist: '',
      );
      await expectLater(
        findMatchingSource(external, foreign),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'unavailable'),
        ),
      );
      expect(external.resolves, 0);
      final lyricsOnly = ChartProvider(chords: false);
      await expectLater(
        findMatchingSource(lyricsOnly, chart),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'unavailable'),
        ),
      );
      expect(lyricsOnly.resolves, 0);
    },
  );
}
