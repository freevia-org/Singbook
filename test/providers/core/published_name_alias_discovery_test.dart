import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

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
}
