import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/core/charts.dart';
import 'package:singbook/providers/provider.dart';

// Invented lyric text; real public artist IDs exercise the reviewed binding.
const _lines = [
  'Harbor lanterns gather where the quiet river bends',
  'Silver windows carry evening over winding stone streets',
  'A distant bell reminds the sailors to return home',
  'Every narrow bridge glows softly through the midnight rain',
];
final _words = _lines.join('\n');
final _body = [
  for (var i = 0; i < _lines.length; i++)
    '[${['C', 'G', 'Am', 'F'][i]}]${_lines[i]}',
].join('\n');
const _path = '/a/wsa/beyonce-halo-chords-s190194';
const _selected = SongCandidate(
  providerId: 'genius',
  id: 'recording',
  title: 'Halo',
  artist: 'Beyoncé',
  album: 'Selected Album',
  metadata: {
    'identityScope': 'recording',
    'artworkUrl': 'https://art.example.test/original.png',
  },
);
const _search = SongCandidate(
  providerId: 'songsterr',
  id: _path,
  title: 'Halo',
  artist: 'Beyoncé',
  extra: {'providerArtistId': '87340', 'providerSongId': '190194'},
);

SongCandidate _resolved({
  String artist = 'Beyonce Knowles',
  String artistId = '6487',
  String id = _path,
  String title = 'Halo',
}) => SongCandidate(
  providerId: 'songsterr',
  id: id,
  title: title,
  artist: artist,
  extra: {'providerArtistId': artistId, 'providerSongId': '190194'},
);

class _Lyrics implements LyricsProvider {
  @override
  final definition = const ProviderDefinition(
    id: 'genius',
    name: 'Lyrics',
    capabilities: {'catalog', 'lyrics'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_selected];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: _selected,
    body: _words,
    metadata: _selected.metadata,
  );
}

class _Charts implements LyricsProvider {
  _Charts({SongCandidate? resolved, String? body})
    : resolved = resolved ?? _resolved(),
      body = body ?? _body;
  final SongCandidate resolved;
  final String body;
  @override
  final definition = const ProviderDefinition(
    id: 'songsterr',
    name: 'Charts',
    capabilities: {'catalog', 'lyrics', 'chords'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_search];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: resolved,
    body: body,
    metadata: const {'artworkUrl': 'https://art.example.test/chart.png'},
  );
}

void main() {
  test(
    'Songsterr parsing retains artist and song IDs through credit changes',
    () {
      String page(Map<String, Object> state) =>
          '<a href="$_path">chart</a><script id="state" type="application/json">${jsonEncode(state)}</script>';
      final search = SongsterrProvider.parseSearch(
        page({
          'songs': {
            'songs': {
              'list': [
                {
                  'songId': 190194,
                  'artistId': 87340,
                  'artist': 'Beyoncé',
                  'title': 'Halo',
                  'hasChords': true,
                },
              ],
            },
          },
        }),
      ).single;
      final resolved = SongsterrProvider.parsePage(
        page({
          'chords': {
            'current': {
              'songId': 190194,
              'artistId': 6487,
              'artist': 'Beyonce Knowles',
              'title': 'Halo',
            },
          },
          'chordpro': {
            'current': [
              for (final line in _lines.take(2))
                {
                  'type': 'line',
                  'line': [
                    {
                      'type': 'chord',
                      'chord': {
                        'baseNote': {'name': 'C'},
                        'firstNote': {'name': 'C'},
                        'chordType': {'suffix': ''},
                      },
                    },
                    {'type': 'text', 'text': line},
                  ],
                },
            ],
          },
        }),
        _path,
      );
      expect(search.extra['providerArtistId'], '87340');
      expect(search.extra['providerSongId'], '190194');
      expect(resolved.candidate.extra['providerArtistId'], '6487');
      expect(resolved.candidate.extra['providerSongId'], '190194');
      expect(sameSong(search, resolved.candidate), isTrue);
      expect(sameSong(_selected, resolved.candidate), isFalse);
      expect(resolved.candidate.artist, 'Beyonce Knowles');
    },
  );

  test(
    'reviewed source artist IDs reconcile one chart without rewriting its credit',
    () async {
      final results = await SourceDiscoveryService([
        _Lyrics(),
        _Charts(),
      ]).discover(_selected);
      final chart = results.singleWhere((r) => r.hasChords);
      expect(chart.matchKind, MatchKind.sameSong);
      expect(chart.extra['requiresLyricsAgreement'], isTrue);
      expect(chart.extra['artistIdentityEvidence'], isA<Map>());
      expect(chart.candidate.artist, 'Beyonce Knowles');
      expect(chart.candidate.extra['providerArtistId'], '6487');
      expect(sameSong(_selected, chart.candidate), isFalse);
      expect(recordingCompatible(_selected, chart), isFalse);
      final combined = combineSources(_selected, results);
      expect(plainLyrics(combined.body), _words);
      expect(contributingProviderIds(combined), contains('songsterr'));
      expect(combined.artist, 'Beyoncé');
      expect(combined.metadata['artworkUrl'], _selected.metadata['artworkUrl']);
    },
  );

  test(
    'matching words do not rescue unreviewed artist IDs or named covers',
    () async {
      for (final invalid in [
        _resolved(artistId: '99999'),
        _resolved(artist: 'Beyonce Tribute'),
        _resolved(artistId: '87340'),
        _resolved(id: '/a/wsa/beyonce-halo-chords-s190195'),
        _resolved(title: 'Halo (Live)'),
      ]) {
        final results = await SourceDiscoveryService([
          _Lyrics(),
          _Charts(resolved: invalid),
        ]).discover(_selected);
        expect(
          results.where(
            (r) => r.hasChords && r.matchKind != MatchKind.rejected,
          ),
          isEmpty,
        );
      }
    },
  );

  test(
    'reviewed artist aliases still need matching recording lyrics',
    () async {
      final results = await SourceDiscoveryService([
        _Lyrics(),
        _Charts(
          body:
              '[C]Copper kettles rattle loudly on the kitchen stove\n'
              '[G]Grandma counts the spoons beneath a flickering lamp\n'
              '[Am]Muddy boots are drying by a forgotten bicycle\n'
              '[F]Thunder rolls along the hills beyond the orchard',
        ),
      ]).discover(_selected);
      expect(
        results.where((r) => r.hasChords && r.matchKind != MatchKind.rejected),
        isEmpty,
      );
    },
  );

  test('reference cancellation withdraws a reviewed alias donor', () async {
    final token = CancellationToken();
    var published = false;
    final results = await SourceDiscoveryService([_Lyrics(), _Charts()])
        .discover(
          _selected,
          providerCancellation: {'genius': token},
          onProgress: (check) {
            if (!published &&
                check.result?.hasChords == true &&
                check.result?.matchKind != MatchKind.rejected) {
              published = true;
              token.cancel();
            }
          },
        );
    expect(published, isTrue);
    expect(
      results.where((r) => r.hasChords && r.matchKind != MatchKind.rejected),
      isEmpty,
    );
  });
}
