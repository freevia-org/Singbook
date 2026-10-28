import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart' show jsonMap;
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';

const _selected = SongCandidate(
  providerId: 'genius',
  id: 'selected-recording',
  title: '上を向いて歩こう (SUKIYAKI)',
  artist: '坂本九 (Kyu Sakamoto)',
);

const _latinCandidate = SongCandidate(
  providerId: 'latinlyrics',
  id: 'catalog-row-1',
  title: 'Sukiyaki',
  artist: 'Kyu Sakamoto',
);

const _latinChartCandidate = SongCandidate(
  providerId: 'chordcatalog',
  id: 'sukiyaki-chart',
  title: 'Sukiyaki',
  artist: 'Kyu Sakamoto',
);

const _nativeJapaneseLyrics =
    '青い雨が静かな窓を叩く\n'
    '遠い灯りが川辺に揺れる\n'
    '白い船が朝の霧を進む\n'
    '小さな庭に夏の花が咲く\n'
    '長い道を一人で歩き続ける\n'
    '夜明け前に鳥の声が響く\n'
    '丘の上で風が髪を揺らす\n'
    '赤い雲が水平線に溶ける\n'
    '古い時計が昼の時を告げる\n'
    '砂の道に足跡が残る\n'
    '木々の影が広場を包む\n'
    '星の光が遠く瞬く';

const _romanizedChartBody =
    '[C]Aoi ame ga shizuka na mado wo tataku\n'
    '[G]Tooi akari ga kawabe ni yureru\n'
    '[Am]Shiroi fune ga asa no kiri wo susumu\n'
    '[F]Chiisana niwa ni natsu no hana ga saku\n'
    '[C]Nagai michi wo hitori de aruki tsuzukeru\n'
    '[G]Yoake mae ni tori no koe ga hibiku\n'
    '[C]Oka no ue de kaze ga kami wo yurasu\n'
    '[G]Akai kumo ga suiheisen ni tokeru\n'
    '[Am]Furui tokei ga hiru no toki wo tsugeru\n'
    '[F]Suna no michi ni ashiato ga nokoru\n'
    '[C]Kigi no kage ga hiroba wo tsutsumu\n'
    '[G]Hoshi no hikari ga tooku matataku';

class _JapaneseRecordingLyricsProvider implements LyricsProvider {
  _JapaneseRecordingLyricsProvider({this.body = _nativeJapaneseLyrics});

  final String body;

  @override
  final definition = const ProviderDefinition(
    id: 'genius',
    name: 'Genius fixture',
    capabilities: {'catalog', 'lyrics'},
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
  }) async => SourceResult(
    candidate: candidate,
    body: body,
    matchKind: MatchKind.sameRecording,
  );
}

class _RomanizedChordProvider implements LyricsProvider {
  _RomanizedChordProvider({this.body = _romanizedChartBody});

  final SongCandidate candidate = _latinChartCandidate;
  final String body;
  final queries = <String>[];

  @override
  final definition = const ProviderDefinition(
    id: 'chordcatalog',
    name: 'Chord Catalog fixture',
    capabilities: {'catalog', 'lyrics', 'chords'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    queries.add(query);
    return query.contains('上を向いて歩こう')
        ? const []
        : query.toLowerCase().contains('sukiyaki') &&
              query.toLowerCase().contains('kyu sakamoto')
        ? [candidate]
        : const [];
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate requested, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: candidate,
    body: body,
    matchKind: MatchKind.sameSong,
  );
}

class _ChordProvider implements LyricsProvider {
  @override
  final definition = const ProviderDefinition(
    id: 'chordcatalog',
    name: 'Chord Catalog',
    capabilities: {'catalog', 'lyrics', 'chords'},
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
  }) async => SourceResult(candidate: candidate, body: '');
}

class _LatinLyricsProvider implements LyricsProvider {
  final queries = <String>[];

  @override
  final definition = const ProviderDefinition(
    id: 'latinlyrics',
    name: 'Latin Lyrics',
    capabilities: {'catalog', 'lyrics'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    queries.add(query);
    return RegExp(r'^[A-Za-z ]+$').hasMatch(query) ? [_latinCandidate] : [];
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: candidate,
    body:
        'A quiet invented lyric continues across this long line\n'
        'Another invented line keeps the fixture away from real song text',
  );
}

class _ContextualLatinLyricsProvider extends _LatinLyricsProvider
    implements ContextualLyricsSearch {
  final selections = <String>[];

  @override
  bool canReuseSearchForSelection(
    SongCandidate selection,
    List<SongCandidate> candidates,
  ) {
    selections.add('reuse:${selection.id}:${candidates.length}');
    return false;
  }

  @override
  Future<List<SongCandidate>> searchForSelection(
    SongCandidate selection, {
    required String fallbackQuery,
    CancellationToken? cancel,
  }) {
    selections.add('search:${selection.id}:$fallbackQuery');
    return search(fallbackQuery, cancel: cancel);
  }
}

Map<String, Object?> _builtinEntry(String id) => {
  'id': id,
  'name': id,
  'adapter': 'builtin',
  'status': 'active',
  'revision': 1,
  'capabilities': ['catalog', 'lyrics', if (id == 'chordcatalog') 'chords'],
  'enabledByDefault': true,
  'accessMode': 'public',
  'website': 'https://example.org/',
  'hosts': <String>[],
};

SourceCatalog _catalogFor(List<String> providerIds) => SourceCatalog.fromJson({
  'schemaVersion': 1,
  'extractionSchemaVersion': 1,
  'revision': 1,
  'publishedAt': '2026-10-28T00:00:00Z',
  'sources': [for (final id in providerIds) _builtinEntry(id)],
});

void main() {
  test(
    'sameSong accepts published aliases but rejects qualifiers and ID conflicts',
    () {
      expect(sameSong(_selected, _latinCandidate), isTrue);
      for (final invalid in [
        const SongCandidate(
          providerId: 'latinlyrics',
          id: 'live',
          title: 'Sukiyaki (Live)',
          artist: 'Kyu Sakamoto',
        ),
        const SongCandidate(
          providerId: 'latinlyrics',
          id: 'featured',
          title: 'Sukiyaki',
          artist: 'Kyu Sakamoto feat. Another Singer',
        ),
        const SongCandidate(
          providerId: 'latinlyrics',
          id: 'conflicting-isrc',
          title: 'Sukiyaki',
          artist: 'Kyu Sakamoto',
          recordingIds: {'isrc': 'USAAA0000001'},
        ),
      ]) {
        final selected = invalid.id == 'conflicting-isrc'
            ? const SongCandidate(
                providerId: 'genius',
                id: 'selected-recording',
                title: '上を向いて歩こう (SUKIYAKI)',
                artist: '坂本九 (Kyu Sakamoto)',
                recordingIds: {'isrc': 'USAAA0000002'},
              )
            : _selected;
        expect(sameSong(selected, invalid), isFalse, reason: invalid.id);
      }
      expect(
        sameSong(
          const SongCandidate(
            providerId: 'genius',
            id: 'studio',
            title: '上を向いて歩こう (SUKIYAKI)',
            artist: '坂本九 (Kyu Sakamoto)',
            album: 'Studio Album',
          ),
          const SongCandidate(
            providerId: 'latinlyrics',
            id: 'live',
            title: 'Sukiyaki',
            artist: 'Kyu Sakamoto',
            album: 'Live at Harbor',
          ),
        ),
        isFalse,
        reason: 'published aliases do not override explicit edition evidence',
      );
      expect(
        sameArrangement(
          _selected,
          const SongCandidate(
            providerId: 'chordcatalog',
            id: 'chart',
            title: 'Sukiyaki',
            artist: 'Kyu Sakamoto',
          ),
          _ChordProvider(),
        ),
        isTrue,
      );
    },
  );

  test(
    'Latin alias fallback preserves the provider native candidate',
    () async {
      final provider = _LatinLyricsProvider();
      final sources = await SourceDiscoveryService([
        provider,
      ]).discover(_selected);
      final source = sources.single;

      expect(provider.queries, [
        '上を向いて歩こう (SUKIYAKI) 坂本九 (Kyu Sakamoto)',
        'SUKIYAKI Kyu Sakamoto',
      ]);
      expect(source.matchKind, MatchKind.sameSong);
      expect(source.candidate.id, 'catalog-row-1');
      expect(source.candidate.title, 'Sukiyaki');
      expect(source.candidate.artist, 'Kyu Sakamoto');
    },
  );

  test(
    'combined song keeps native lyrics source and a playable Latin chart',
    () {
      const nativeLyrics = SourceResult(
        candidate: _selected,
        matchKind: MatchKind.sameRecording,
        body:
            '青い雨が静かな窓を叩く\n'
            '遠い灯りが川辺に揺れる\n'
            '白い船が朝の霧を進む\n'
            '小さな庭に夏の花が咲く\n'
            '長い道を一人で歩き続ける\n'
            '夜明け前に鳥の声が響く',
      );
      const chartCandidate = SongCandidate(
        providerId: 'chordcatalog',
        id: 'sukiyaki-chart',
        title: 'Sukiyaki',
        artist: 'Kyu Sakamoto',
      );
      const latinChart = SourceResult(
        candidate: chartCandidate,
        matchKind: MatchKind.sameSong,
        body:
            '[C]Aoi ame ga shizuka na mado wo tataku\n'
            '[G]Tooi akari ga kawabe ni yureru\n'
            '[Am]Shiroi fune ga asa no kiri wo susumu\n'
            '[F]Chiisana niwa ni natsu no hana ga saku\n'
            '[C]Nagai michi wo hitori de aruki tsuzukeru\n'
            '[G]Yoake mae ni tori no koe ga hibiku',
      );
      final combined = combineSources(_selected, [nativeLyrics, latinChart]);

      expect(combined.body, latinChart.body);
      expect(combined.hasChords, isTrue);
      expect(
        combined.sources.map((source) => source.candidate.identity).toSet(),
        {_selected.identity, chartCandidate.identity},
      );
      expect(
        combined.sources
            .singleWhere(
              (source) => source.candidate.providerId == 'chordcatalog',
            )
            .candidate
            .title,
        'Sukiyaki',
      );
      expect(
        combined.sources
            .singleWhere((source) => source.candidate.providerId == 'genius')
            .candidate
            .artist,
        '坂本九 (Kyu Sakamoto)',
      );
    },
  );

  test(
    'discovery accepts a published Latin-script chart without claiming lyric agreement',
    () async {
      final japanese = _JapaneseRecordingLyricsProvider();
      final chartProvider = _RomanizedChordProvider();
      final sources = await SourceDiscoveryService([
        japanese,
        chartProvider,
      ]).discover(_selected);
      final native = sources.singleWhere(
        (source) => source.candidate.providerId == 'genius',
      );
      final chart = sources.singleWhere(
        (source) => source.candidate.providerId == 'chordcatalog',
      );
      final evidence = Map<String, dynamic>.from(
        chart.extra['lyricRepresentationEvidence'] as Map,
      );

      expect(chartProvider.queries, [
        '上を向いて歩こう (SUKIYAKI) 坂本九 (Kyu Sakamoto)',
        'SUKIYAKI Kyu Sakamoto',
      ]);
      expect(chart.matchKind, isNot(MatchKind.rejected));
      expect(chart.extra['lyricRepresentation'], 'latin_script_alternative');
      expect(
        evidence['basis'],
        'publisher_name_alias_and_different_writing_system',
      );
      expect(evidence['wordAgreementEstablished'], isFalse);
      expect(native.candidate.title, _selected.title);
      expect(native.candidate.artist, _selected.artist);
      expect(native.body, _nativeJapaneseLyrics);
      expect(chart.candidate.title, 'Sukiyaki');
      expect(chart.candidate.artist, 'Kyu Sakamoto');
      expect(chart.body, _romanizedChartBody);

      final combined = combineSources(_selected, sources);
      expect(combined.hasChords, isTrue);
      expect(
        parseArrangement(combined.body).any((line) => line.chords.isNotEmpty),
        isTrue,
      );
      expect(
        combined.sources.map((source) => source.candidate.providerId).toSet(),
        containsAll(['genius', 'chordcatalog']),
      );

      final restored = ChordProCodec().decode(ChordProCodec().encode(combined));
      final restoredNative = restored.sources.singleWhere(
        (source) => source.candidate.providerId == 'genius',
      );
      final restoredChart = restored.sources.singleWhere(
        (source) => source.candidate.providerId == 'chordcatalog',
      );
      expect(restoredNative.body, _nativeJapaneseLyrics);
      expect(restoredChart.body, _romanizedChartBody);
      expect(
        restoredChart.extra['lyricRepresentation'],
        'latin_script_alternative',
      );
      expect(
        jsonMap(
          restoredChart.extra['lyricRepresentationEvidence'],
        )['wordAgreementEstablished'],
        isFalse,
      );
      expect(restored.hasChords, isTrue);
    },
  );

  test(
    'configured runtime chart wrapper keeps Latin alias fallback available',
    () async {
      final japanese = _JapaneseRecordingLyricsProvider();
      final chartProvider = _RomanizedChordProvider();
      final runtime = SourceCatalogRuntime(
        builtins: [japanese, chartProvider],
        createProvider: (_) => throw StateError('No dynamic adapters expected'),
      )..apply(_catalogFor(['genius', 'chordcatalog']));
      final configuredChart = runtime.providers.singleWhere(
        (provider) => provider.definition.id == 'chordcatalog',
      );

      expect(configuredChart.definition.enabledByDefault, isTrue);
      expect(configuredChart, isNot(isA<ContextualLyricsSearch>()));
      final sources = await SourceDiscoveryService(
        runtime.providers,
      ).discover(_selected);
      final native = sources.singleWhere(
        (source) => source.candidate.providerId == 'genius',
      );
      final chart = sources.singleWhere(
        (source) => source.candidate.providerId == 'chordcatalog',
      );

      expect(chartProvider.queries, [
        '上を向いて歩こう (SUKIYAKI) 坂本九 (Kyu Sakamoto)',
        'SUKIYAKI Kyu Sakamoto',
      ]);
      expect(chart.matchKind, MatchKind.sameSong);
      expect(chart.body, _romanizedChartBody);
      expect(native.body, _nativeJapaneseLyrics);
      expect(chart.candidate.title, 'Sukiyaki');
      expect(chart.candidate.artist, 'Kyu Sakamoto');
    },
  );

  test(
    'configured contextual delegates retain and forward their capability',
    () async {
      final delegate = _ContextualLatinLyricsProvider();
      final runtime = SourceCatalogRuntime(
        builtins: [delegate],
        createProvider: (_) => throw StateError('No dynamic adapters expected'),
      )..apply(_catalogFor(['latinlyrics']));
      final configured = runtime.providers.single;

      expect(configured, isA<ContextualLyricsSearch>());
      final contextual = configured as ContextualLyricsSearch;
      expect(
        contextual.canReuseSearchForSelection(_selected, const []),
        isFalse,
      );
      final result = await contextual.searchForSelection(
        _selected,
        fallbackQuery: 'Sukiyaki Kyu Sakamoto',
      );
      expect(delegate.selections, [
        'reuse:${_selected.id}:0',
        'search:${_selected.id}:Sukiyaki Kyu Sakamoto',
      ]);
      expect(result.single.id, _latinCandidate.id);
    },
  );

  test(
    'two Latin lyric bodies do not receive a script-alternative bypass',
    () async {
      const unrelatedLatinLyrics =
          'Quartz zephyrs navigate violet lanterns\n'
          'Crimson thistles orbit silent marigolds\n'
          'Amber galaxies fold sapphire terraces\n'
          'Winter orchids measure copper constellations\n'
          'Velvet comets circle lilac observatories\n'
          'Brisk eucalyptus dances near cobalt marble';
      const unrelatedLatinChart =
          '[C]Ravens ignite cedar mountains\n'
          '[G]Saffron rivers awaken ancient turbines\n'
          '[Am]Fossil feathers cross granite valleys\n'
          '[F]Opal engines whisper beneath moss\n'
          '[C]Indigo currents surround bronze sculptures\n'
          '[G]Jasmine shadows climb sandstone towers';
      final chartProvider = _RomanizedChordProvider(body: unrelatedLatinChart);
      final sources = await SourceDiscoveryService([
        _JapaneseRecordingLyricsProvider(body: unrelatedLatinLyrics),
        chartProvider,
      ]).discover(_selected);
      final chart = sources.singleWhere(
        (source) => source.candidate.providerId == 'chordcatalog',
      );

      expect(chart.matchKind, MatchKind.rejected);
      expect(chart.matchReason, 'incomplete_or_different_lyrics');
      expect(chart.extra, isNot(contains('lyricRepresentation')));
    },
  );
}
