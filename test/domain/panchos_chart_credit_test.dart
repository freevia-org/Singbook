import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/reviewed_chart_artist.dart';
import 'package:singbook/providers/core/charts.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

const _selected = SongCandidate(
  providerId: 'genius',
  id: 'fixture',
  title: 'Bésame Mucho',
  artist: 'Los Panchos',
);
const _lines = [
  'Paper lanterns gather where the quiet river bends',
  'Silver windows carry evening over winding stone streets',
  'A distant bell reminds the sailors to return home',
  'Every narrow bridge glows softly through the midnight rain',
];

class _FixtureProvider implements LyricsProvider {
  _FixtureProvider(this.chords, {this.differentLyrics = false});
  final bool chords, differentLyrics;
  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: chords ? 'ultimateguitar' : 'genius',
    name: 'Fixture',
    capabilities: {'lyrics', 'catalog', if (chords) 'chords'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [chords ? chart() : _selected];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: candidate,
    body: differentLyrics
        ? 'Copper kettles rattle through the crowded kitchen\n'
              'Heavy thunder climbs across the distant mountain\n'
              'Bright red apples fall into the orchard basket\n'
              'Someone counts the spoons before the feast begins'
        : [for (final line in _lines) '${chords ? '[C]' : ''}$line'].join('\n'),
  );
}

SongCandidate chart({
  String artist = 'Los Panchos (Trio Los Panchos)',
  String artistId = '325614',
  String songId = '4155044',
  String chartId = '1643189',
  String id = '/tab/1643189',
  JsonMap metadata = const {},
  Map<String, String> recordingIds = const {},
}) => SongCandidate(
  providerId: 'ultimateguitar',
  id: id,
  title: 'Bésame Mucho',
  artist: artist,
  metadata: metadata,
  recordingIds: recordingIds,
  extra: {
    'providerArtistId': artistId,
    'providerSongId': songId,
    'providerChartId': chartId,
  },
);

void main() {
  test(
    'reviewed alias still requires the selected recording lyrics to agree',
    () async {
      for (final different in [false, true]) {
        final results = await SourceDiscoveryService([
          _FixtureProvider(false),
          _FixtureProvider(true, differentLyrics: different),
        ]).discover(_selected);
        final donor = results.firstWhere(
          (r) => r.candidate.providerId == 'ultimateguitar',
        );
        expect(
          donor.matchKind,
          different ? MatchKind.rejected : MatchKind.sameSong,
        );
        if (!different) {
          expect(donor.extra['requiresLyricsAgreement'], isTrue);
          expect(donor.extra['artistIdentityEvidence'], isA<Map>());
          expect(donor.candidate.artist, 'Los Panchos (Trio Los Panchos)');
        }
      }
    },
  );

  test('reviewed group name preserves provider IDs and raw source credit', () {
    final source = chart();
    final credit = reviewedChartArtistCredit(source)!;
    expect(credit.canonicalName, 'Los Panchos');
    expect(credit.sourceName, source.artist);
    expect(credit.toJson()['providerChartId'], '1643189');
    expect(credit.providerSongId, '4155044');
    expect(source.artist, 'Los Panchos (Trio Los Panchos)');
    expect(
      sameReviewedChartArtist(source, chart(artist: 'Trio Los Panchos')),
      isTrue,
    );
  });

  test(
    'unknown credits, IDs and malformed paths never gain alias evidence',
    () {
      for (final source in [
        chart(artistId: '123'),
        chart(artist: 'Los Panchos (Pedro Infante)'),
        chart(artist: 'Pedro Infante'),
        chart(artist: 'Los Panchos & Friends'),
        chart(songId: ''),
        chart(songId: '04155044'),
        chart(chartId: '1643190'),
      chart(chartId: '0', id: '/tab/0'),
      chart(chartId: '01643189', id: '/tab/01643189'),
      chart(chartId: '1234567890123456', id: '/tab/1234567890123456'),
        chart(id: '/tab/1643189?x=1'),
        chart(id: '/tab/1643189#x'),
        chart(id: 'https://tabs.ultimate-guitar.com/tab/1643189'),
        chart(id: '/tab/%2f/1643189'),
      ]) {
        expect(reviewedChartArtistCredit(source), isNull);
      }
      expect(
        sameReviewedChartArtist(chart(), chart(songId: '4155045')),
        isFalse,
      );
      expect(
        sameReviewedChartArtist(
          chart(metadata: {'edition': 'Studio'}),
          chart(metadata: {'edition': 'Live'}),
        ),
        isFalse,
      );
      expect(
        sameReviewedChartArtist(
          chart(recordingIds: {'isrc': 'A'}),
          chart(recordingIds: {'isrc': 'B'}),
        ),
        isFalse,
      );
    },
  );

  test(
    'group alias permits an arrangement, without asserting same recording',
    () {
      const selected = SongCandidate(
        providerId: 'genius',
        id: '1766558',
        title: 'Bésame Mucho',
        artist: 'Los Panchos',
      );
      final provider = UltimateGuitarProvider(ProviderTransport());
      expect(sameSong(selected, chart()), isFalse);
      expect(sameArrangement(selected, chart(), provider), isTrue);
      expect(
        sameArrangement(selected, chart(artistId: '123'), provider),
        isFalse,
      );
      expect(
        sameArrangement(selected, chart(artist: 'Pedro Infante'), provider),
        isFalse,
      );
    },
  );
}
