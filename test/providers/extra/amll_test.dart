import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/amll.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/source_catalog.dart';

const _ttml =
    '''<tt xmlns="http://www.w3.org/ns/ttml" xmlns:amll="http://music.apple.com/lyric-ttml-internal" amll:timing="Word"><body><div><p begin="1" end="2">Synthetic line</p></div></body></tt>''';

Map<String, Object?> _item({
  int id = 269710089745311,
  List<String> titles = const ['Example', 'Example (Live)'],
  List<String> artists = const ['Artist A', 'Artist B'],
  List<String> albums = const ['Album'],
  String lyrics = _ttml,
  bool includeLyrics = true,
}) => {
  'id': id,
  'filename': 'example.ttml',
  'musicNames': titles,
  'artistNames': artists,
  'albumNames': albums,
  'ncmMusicIds': ['123'],
  'qqMusicIds': [],
  'appleMusicIds': [],
  'spotifyIds': [],
  'isrcs': ['USAAA1234567'],
  'authorIds': ['42'],
  'authorUsernames': ['Lyric Contributor'],
  if (includeLyrics) 'format': 'ttml',
  if (includeLyrics) 'lyrics': lyrics,
};

Map<String, Object?> _envelope(Object data) => {'status': 200, 'data': data};

class _Harness {
  _Harness({
    Object? searchItems,
    Object? detail,
    this.detailStatus = 200,
    bool omitSearchItems = false,
    bool omitPagination = false,
  }) {
    final total = searchItems is List ? searchItems.length : 1;
    client = MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/v1/lyrics/search') {
        return http.Response(
          jsonEncode(
            _envelope({
              if (!omitSearchItems)
                'items': searchItems ?? [_item(includeLyrics: false)],
              if (!omitPagination)
                'pagination': {
                  'page': 1,
                  'pageSize': 30,
                  'total': total,
                  'totalPages': total == 0 ? 0 : 1,
                  'hasMore': false,
                },
            }),
          ),
          200,
        );
      }
      if (request.url.path == '/v1/lyrics/get') {
        return http.Response(
          jsonEncode(detail ?? _envelope(_item())),
          detailStatus,
        );
      }
      return http.Response('unexpected', 404);
    });
    transport = ProviderTransport(
      client: client,
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    provider = AmllProvider(transport, requestInterval: Duration.zero);
  }
  late final MockClient client;
  late final ProviderTransport transport;
  late final AmllProvider provider;
  int detailStatus = 200;
  final requests = <http.Request>[];
  Future<void> close() => transport.close();
}

void main() {
  test(
    'configured app lookup uses separate fields and keeps document-only identity',
    () async {
      final h = _Harness();
      try {
        final entry = SourceCatalog.fromJson({
          'schemaVersion': 1,
          'extractionSchemaVersion': 1,
          'revision': 1,
          'publishedAt': '2026-10-27T00:00:00Z',
          'sources': [
            {
              'id': 'amll',
              'name': 'AMLL',
              'adapter': 'builtin',
              'revision': 1,
              'status': 'active',
              'enabledByDefault': true,
              'accessMode': 'publicApi',
              'website': 'https://amll.dev',
              'hosts': [],
              'capabilities': [
                'catalog',
                'lyrics',
                'metadata',
                'lineTiming',
                'wordTiming',
              ],
              'probes': [],
            },
          ],
        }).sources.single;
        final configured = ConfiguredBuiltinProvider(entry, h.provider);
        final result = await findMatchingSource(
          configured,
          const SongCandidate(
            providerId: 'other',
            id: 'external',
            title: 'Example',
            artist: 'Artist A & Artist B',
            album: 'Album',
          ),
        );
        expect(h.requests.first.url.queryParameters, {
          'musicName': 'Example',
          'albumName': 'Album',
          'page': '1',
          'pageSize': '30',
        });
        expect(result.matchKind, MatchKind.sameSong);
        expect(result.candidate.recordingIds, isEmpty);
        expect(result.metadata['identityScope'], 'arrangement');
        expect(
          result.timingTracks.single.extra['recordingEvidence'],
          'sourceDemonstrationOnly',
        );
      } finally {
        await h.close();
      }
    },
  );

  test(
    'single artist contextual lookup and cache require complete current identities',
    () async {
      final h = _Harness(
        searchItems: [
          _item(artists: ['Artist A'], includeLyrics: false),
        ],
      );
      try {
        const selection = SongCandidate(
          providerId: 'other',
          id: 'x',
          title: 'Example',
          artist: 'Artist A',
          album: 'Album',
        );
        final rows = await h.provider.searchForSelection(
          selection,
          fallbackQuery: 'ignored',
        );
        expect(h.requests.single.url.queryParameters, {
          'musicName': 'Example',
          'artistName': 'Artist A',
          'albumName': 'Album',
          'page': '1',
          'pageSize': '30',
        });
        expect(h.provider.canReuseSearchForSelection(selection, rows), true);
        final restored = rows
            .map(
              (row) => SongCandidate.fromJson(
                jsonDecode(jsonEncode(row.toJson())) as Map<String, dynamic>,
              ),
            )
            .toList();
        expect(
          h.provider.canReuseSearchForSelection(selection, restored),
          true,
        );
        expect(h.provider.canReuseSearchForSelection(selection, []), false);
        expect(
          h.provider.canReuseSearchForSelection(
            const SongCandidate(
              providerId: 'other',
              id: 'x',
              title: 'Example',
              artist: 'Artist B',
              album: 'Album',
            ),
            rows,
          ),
          false,
        );
        expect(
          h.provider.canReuseSearchForSelection(
            const SongCandidate(
              providerId: 'other',
              id: 'x',
              title: 'Example',
              artist: 'Artist A',
              album: 'Another album',
            ),
            rows,
          ),
          false,
        );
      } finally {
        await h.close();
      }
    },
  );
  test(
    'search builds bounded document candidates with all artist and alias credits',
    () async {
      final h = _Harness();
      try {
        final candidates = await h.provider.search('Example');
        expect(candidates, hasLength(1));
        final song = candidates.single;
        expect(song.id, '269710089745311');
        expect(song.title, 'Example');
        expect(song.artist, 'Artist A & Artist B');
        expect(song.extra['sourceArtistNames'], ['Artist A', 'Artist B']);
        expect(song.extra['sourceTitleAliases'], ['Example', 'Example (Live)']);
        expect(h.requests.single.url.queryParameters, {
          'q': 'Example',
          'page': '1',
          'pageSize': '30',
        });
      } finally {
        await h.close();
      }
    },
  );

  test(
    'resolve preserves source payload, contributors and unverified TTML timing; successful detail is cached',
    () async {
      final h = _Harness();
      try {
        final selected = (await h.provider.search('Example')).single;
        final first = await h.provider.resolve(selected);
        final second = await h.provider.resolve(selected);
        expect(first.body, contains('Synthetic line'));
        expect(first.matchKind, MatchKind.unverified);
        expect(first.timingTracks.single.raw, _ttml);
        expect(first.timingTracks.single.extra['timingProfile'], 'amll-ttml');
        expect(first.extra['amll']['authorUsernames'], ['Lyric Contributor']);
        expect(first.extra['amll']['authorIds'], ['42']);
        expect(
          first.extra['originalPayload']['contentType'],
          'application/json',
        );
        expect(
          base64Decode(first.extra['originalPayload']['base64']),
          utf8.encode(jsonEncode(_envelope(_item()))),
        );
        expect(second.timingTracks.single.raw, _ttml);
        expect(
          h.requests.where((r) => r.url.path == '/v1/lyrics/get'),
          hasLength(1),
        );
        expect(first.attribution, contains('Lyric Contributor'));
      } finally {
        await h.close();
      }
    },
  );

  test('selection accepts title alias and reordered full credits', () async {
    final h = _Harness();
    try {
      final selected = (await h.provider.search('Example')).single;
      final alias = SongCandidate(
        providerId: selected.providerId,
        id: selected.id,
        title: 'Example (Live)',
        artist: 'Artist B & Artist A',
        album: 'Album',
        extra: selected.extra,
      );
      expect((await h.provider.resolve(alias)).candidate.title, 'Example');
    } finally {
      await h.close();
    }
  });

  test(
    'rejects changed identity, malformed IDs, oversized contributor arrays and invalid TTML',
    () async {
      final mismatch = _Harness(
        detail: _envelope(_item(artists: ['Artist A'])),
      );
      try {
        final selected = (await mismatch.provider.search('Example')).single;
        await expectLater(
          mismatch.provider.resolve(selected),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.code,
              'code',
              'identity_mismatch',
            ),
          ),
        );
        final malicious = SongCandidate(
          providerId: 'amll',
          id: '1/../2',
          title: selected.title,
          artist: selected.artist,
        );
        await expectLater(
          mismatch.provider.resolve(malicious),
          throwsA(isA<ProviderException>()),
        );
        expect(
          mismatch.requests.where((r) => r.url.path == '/v1/lyrics/get'),
          hasLength(1),
        );
      } finally {
        await mismatch.close();
      }

      final oversized = _Harness(
        searchItems: [
          _item(artists: List.filled(31, 'A'), includeLyrics: false),
        ],
      );
      try {
        await expectLater(
          oversized.provider.search('x'),
          throwsA(isA<ProviderException>()),
        );
      } finally {
        await oversized.close();
      }

      final invalid = _Harness(detail: _envelope(_item(lyrics: '<not-ttml/>')));
      try {
        final selected = (await invalid.provider.search('Example')).single;
        await expectLater(
          invalid.provider.resolve(selected),
          throwsA(isA<ProviderException>()),
        );
      } finally {
        await invalid.close();
      }
    },
  );

  test(
    'validates search schema and format rules for search versus detail',
    () async {
      final validSearch = _Harness();
      try {
        expect(await validSearch.provider.search('Example'), hasLength(1));
      } finally {
        await validSearch.close();
      }

      final wrongSearchFormat = _Harness(
        searchItems: [_item(includeLyrics: false)..['format'] = 'json'],
      );
      try {
        await expectLater(
          wrongSearchFormat.provider.search('Example'),
          throwsA(isA<ProviderException>()),
        );
      } finally {
        await wrongSearchFormat.close();
      }

      for (final omitItems in [true, false]) {
        final malformedSearch = _Harness(
          omitSearchItems: omitItems,
          omitPagination: !omitItems,
        );
        try {
          await expectLater(
            malformedSearch.provider.search('Example'),
            throwsA(isA<ProviderException>()),
          );
        } finally {
          await malformedSearch.close();
        }
      }

      final emptySearch = _Harness(searchItems: []);
      try {
        expect(await emptySearch.provider.search('Example'), isEmpty);
      } finally {
        await emptySearch.close();
      }

      for (final detailItem in [
        _item()..remove('format'),
        _item()..['format'] = 'json',
      ]) {
        final invalidDetail = _Harness(detail: _envelope(detailItem));
        try {
          final selected = (await invalidDetail.provider.search(
            'Example',
          )).single;
          await expectLater(
            invalidDetail.provider.resolve(selected),
            throwsA(isA<ProviderException>()),
          );
        } finally {
          await invalidDetail.close();
        }
      }
    },
  );

  test('cached detail is rechecked against every selected identity', () async {
    final h = _Harness();
    try {
      final selected = (await h.provider.search('Example')).single;
      await h.provider.resolve(selected);
      final changed = SongCandidate(
        providerId: selected.providerId,
        id: selected.id,
        title: selected.title,
        artist: selected.artist,
        extra: {
          ...selected.extra,
          'sourceArtistNames': ['Different Artist'],
        },
      );
      await expectLater(
        h.provider.resolve(changed),
        throwsA(
          isA<ProviderException>().having(
            (error) => error.code,
            'code',
            'identity_mismatch',
          ),
        ),
      );
      expect(
        h.requests.where((request) => request.url.path == '/v1/lyrics/get'),
        hasLength(1),
      );
    } finally {
      await h.close();
    }
  });

  test(
    'failed detail fetch is not cached and can be retried successfully',
    () async {
      final h = _Harness(detailStatus: 403);
      try {
        final selected = (await h.provider.search('Example')).single;
        await expectLater(
          h.provider.resolve(selected),
          throwsA(isA<ProviderException>()),
        );
        h.detailStatus = 200;
        expect((await h.provider.resolve(selected)).timingTracks, hasLength(1));
        expect(
          h.requests.where((request) => request.url.path == '/v1/lyrics/get'),
          hasLength(2),
        );
      } finally {
        await h.close();
      }
    },
  );

  test(
    'rejects noncanonical decimal IDs without interpolating them into URLs',
    () async {
      final h = _Harness();
      try {
        final selected = (await h.provider.search('Example')).single;
        for (final id in ['+1', ' 1', '01', '1 ']) {
          final malformed = SongCandidate(
            providerId: 'amll',
            id: id,
            title: selected.title,
            artist: selected.artist,
            extra: selected.extra,
          );
          await expectLater(
            h.provider.resolve(malformed),
            throwsA(isA<ProviderException>()),
          );
        }
        expect(
          h.requests.where((r) => r.url.path == '/v1/lyrics/get'),
          isEmpty,
        );
      } finally {
        await h.close();
      }
    },
  );

  test(
    'preserves transport denial status and cancellation avoids API calls',
    () async {
      for (final status in [403, 429]) {
        final h = _Harness(detailStatus: status);
        try {
          final selected = (await h.provider.search('Example')).single;
          await expectLater(
            h.provider.resolve(selected),
            throwsA(isA<ProviderException>()),
          );
          expect(
            h.requests.where((r) => r.url.path == '/v1/lyrics/get'),
            hasLength(1),
          );
        } finally {
          await h.close();
        }
      }

      final cancelled = _Harness();
      try {
        final token = CancellationToken()..cancel();
        await expectLater(
          cancelled.provider.search('Example', cancel: token),
          throwsA(isA<ProviderException>()),
        );
        expect(cancelled.requests, isEmpty);
      } finally {
        await cancelled.close();
      }
    },
  );
}
