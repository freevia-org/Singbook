import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:verse_mobile/providers/core/catalogs.dart';
import 'package:verse_mobile/providers/core/charts.dart';
import 'package:verse_mobile/providers/core/common.dart';
import 'package:verse_mobile/providers/core/service.dart';
import 'package:verse_mobile/providers/core/youtube_music.dart';
import 'package:verse_mobile/providers/provider.dart';

const words =
    'A paper satellite sails above the desk tonight\nOur quiet room remembers all the stories from the rain';
Matcher errorCode(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);
ProviderTransport wire(FutureOr<http.Response> Function(http.Request) handler) =>
    ProviderTransport(
      client: MockClient((request) async => handler(request)),
      hostInterval: Duration.zero,
      timeout: const Duration(seconds: 2),
      retryBaseDelay: const Duration(milliseconds: 1),
    );
http.Response json(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> geniusHit(int id, {String? title, Object? art}) => {
  'type': 'song',
  'result': {
    'id': id,
    'title': ?title,
    'primary_artist': {'name': 'Fixture Ensemble'},
    'url': 'https://genius.com/fixture-$id',
    'song_art_image_url': ?art,
  },
};

Map<String, dynamic> lrcRow(int id, {Object? track = 'Paper Satellites'}) => {
  'id': id,
  'trackName': track,
  'artistName': 'Fixture Ensemble',
  'albumName': 'Test Record',
  'duration': 123,
  'plainLyrics': words,
};

Map<String, dynamic> ytRow(String id, {int columns = 2, List? thumbnails}) => {
  'musicResponsiveListItemRenderer': {
    'playlistItemData': {'videoId': id},
    'flexColumns': [
      for (var i = 0; i < columns; i++)
        {
          'musicResponsiveListItemFlexColumnRenderer': {
            'text': i == 0
                ? {
                    'runs': [
                      {'text': 'Paper Satellites'},
                    ],
                  }
                : {
                    'runs': [
                      {
                        'text': 'Fixture Ensemble',
                        'navigationEndpoint': {
                          'browseEndpoint': {
                            'browseId': 'UC12345',
                            'browseEndpointContextSupportedConfigs': {
                              'browseEndpointContextMusicConfig': {
                                'pageType': 'MUSIC_PAGE_TYPE_ARTIST',
                              },
                            },
                          },
                        },
                      },
                    ],
                  },
          },
        },
    ],
    'thumbnail': {
      'musicThumbnailRenderer': {'thumbnail': {'thumbnails': thumbnails ?? []}},
    },
  },
};

Map<String, dynamic> ytSearch(List rows) => {
  'contents': {
    'sectionListRenderer': {
      'contents': [
        {
          'musicShelfRenderer': {'contents': rows},
        },
      ],
    },
  },
};

class _FailingProvider implements LyricsProvider {
  _FailingProvider(this.hits, this.error);
  final List<SongCandidate> hits;
  final ProviderException error;
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'fixture',
    name: 'fixture',
    capabilities: {'lyrics'},
  );
  @override
  Future<List<SongCandidate>> search(String q, {CancellationToken? cancel}) async =>
      hits;
  @override
  Future<SourceResult> resolve(
    SongCandidate c, {
    CancellationToken? cancel,
  }) async => throw error;
}

SongCandidate song(String id) => SongCandidate(
  providerId: 'fixture',
  id: id,
  title: 'Paper Satellites',
  artist: 'Fixture Ensemble',
);

void main() {
  group('malformed search rows are skipped, not fatal', () {
    test('Genius', () async {
      final t = wire(
        (_) => json({
          'response': {
            'hits': [
              geniusHit(1, title: 'Paper Satellites'),
              geniusHit(2), // no title
              {'type': 'song', 'result': 'not an object'},
              geniusHit(3, title: 'Second Song'),
            ],
          },
        }),
      );
      final p = GeniusProvider(t, token: 'fixture-token');
      expect((await p.search('x')).map((s) => s.id), ['1', '3']);
      await t.close();
      final bad = wire(
        (_) => json({
          'response': {
            'hits': [geniusHit(2), geniusHit(4)],
          },
        }),
      );
      await expectLater(
        GeniusProvider(bad, token: 't').search('x'),
        throwsA(errorCode('invalid_response')),
      );
      await bad.close();
      final shapeless = wire((_) => json({'response': {}}));
      await expectLater(
        GeniusProvider(shapeless, token: 't').search('x'),
        throwsA(errorCode('invalid_response')),
      );
      await shapeless.close();
      final none = wire((_) => json({'response': {'hits': []}}));
      expect(await GeniusProvider(none, token: 't').search('x'), isEmpty);
      await none.close();
    });
    test('LRCLIB', () async {
      final t = wire(
        (_) => json([lrcRow(1), lrcRow(2, track: null), 'junk', lrcRow(3)]),
      );
      final p = LrclibProvider(t);
      expect((await p.search('x')).map((s) => s.id), ['1', '3']);
      await t.close();
      final bad = wire((_) => json([lrcRow(1, track: null), 7]));
      await expectLater(
        LrclibProvider(bad).search('x'),
        throwsA(errorCode('invalid_response')),
      );
      await bad.close();
    });
    test('Lyrics.ovh', () async {
      final good = {
        'id': 5,
        'title': 'Paper Satellites',
        'artist': {'name': 'Fixture Ensemble'},
        'album': {'title': 'Test Record'},
        'duration': 100,
      };
      final t = wire(
        (_) => json({
          'data': [
            good,
            {'id': 'x', 'title': 'No id'},
            null,
          ],
        }),
      );
      expect((await LyricsOvhProvider(t).search('x')).length, 1);
      await t.close();
    });
    test('SyncLRC', () async {
      Map<String, dynamic> row(Object id) => {
        'id': id,
        'track': 'Paper Satellites',
        'artist': 'Fixture Ensemble',
        'duration': 123,
        'lyrics': {'plain': words},
      };
      final t = wire(
        (_) => json({
          'results': [row('a' * 32), row('nope'), 'junk', row('b' * 32)],
        }),
      );
      expect((await SyncLrcProvider(t).search('x')).length, 2);
      await t.close();
    });
    test('YouTube Music search', () {
      final results = YoutubeMusicProvider.parseSearch(
        ytSearch([
          ytRow('abcdefghijk'),
          ytRow('zzzzzzzzzzz', columns: 1), // broken row
          ytRow('short'), // invalid video id
          ytRow('bcdefghijkl'),
        ]),
      );
      expect(results.map((s) => s.id), ['abcdefghijk', 'bcdefghijkl']);
      expect(
        () => YoutubeMusicProvider.parseSearch(
          ytSearch([ytRow('abcdefghijk', columns: 1)]),
        ),
        throwsA(errorCode('invalid_response')),
      );
      expect(YoutubeMusicProvider.parseSearch(ytSearch([])), isEmpty);
    });
  });

  group('SyncLRC resolve', () {
    // Incompressible text so the record cannot be carried in the selection id.
    final bulky = List.generate(
      900,
      (i) => '${(i * 2654435761).toRadixString(36)}${i * 7919 % 10007}',
    ).join(' ');
    test('carries the chosen record so resolve makes no request', () async {
      final target = {
        'id': 'a' * 32,
        'track': 'Paper Satellites',
        'artist': 'Fixture Ensemble',
        'album': 'Fixtures',
        'duration': 123,
        'lyrics': {
          'plain': words,
          'synced': '[00:01.00]First invented line',
          'karaoke': '[00:01.00]<00:01.00>First <00:01.50>line',
        },
      };
      var calls = 0;
      final t = wire((_) {
        calls++;
        return json({'results': [target]});
      });
      final selection = (await SyncLrcProvider(t).search('paper')).single;
      expect(selection.metadata.containsKey('record'), isFalse);
      expect(selection.id.length, lessThan(16384));
      calls = 0;
      final r = await SyncLrcProvider(t).resolve(selection);
      expect(calls, 0);
      expect(r.timingTracks, hasLength(2));
      expect(r.candidate.id, selection.id);
      expect(r.candidate.album, 'Fixtures');
      expect(r.candidate.metadata.containsKey('record'), isFalse);
      await t.close();
    });
    test('an oversized record falls back to searching again', () async {
      final target = {
        'id': 'a' * 32,
        'track': 'Paper Satellites',
        'artist': 'Fixture Ensemble',
        'lyrics': {'plain': bulky, 'synced': '[00:01.00]$bulky'},
      };
      var calls = 0;
      final t = wire((_) {
        calls++;
        return json({'results': [target]});
      });
      final selection = (await SyncLrcProvider(t).search('paper')).single;
      expect(selection.id.length, lessThanOrEqualTo(16384));
      calls = 0;
      final r = await SyncLrcProvider(t).resolve(selection);
      expect(calls, 1);
      expect(r.timingTracks, hasLength(1));
      await t.close();
    });
    test('finds the record via an exact title/artist query when the original ranked it low', () async {
      final queries = <String>[];
      Map<String, dynamic> row(String id, String title) => {
        'id': id,
        'track': title,
        'artist': 'Fixture Ensemble',
        'duration': 123,
        'lyrics': {'plain': bulky, 'synced': '[00:01.00]$bulky'},
      };
      final target = row('a' * 32, 'Paper Satellites');
      final t = wire((request) {
        final q = request.url.queryParameters['q']!;
        queries.add(q);
        return json({
          'results': q == 'Paper Satellites Fixture Ensemble'
              ? [target]
              : [for (var i = 0; i < 10; i++) row('${i}b' * 16, 'Other $i')],
        });
      });
      final p = SyncLrcProvider(t);
      // Search with a vague query that returns the target...
      final vague = wire(
        (_) => json({
          'results': [target],
        }),
      );
      final selection = (await SyncLrcProvider(vague).search('paper')).single;
      await vague.close();
      final r = await p.resolve(selection);
      expect(r.timingTracks, hasLength(1));
      expect(queries, ['paper', 'Paper Satellites Fixture Ensemble']);
      await t.close();
    });
    test('unavailable when no query finds it', () async {
      final target = {
        'id': 'a' * 32,
        'track': 'Paper Satellites',
        'artist': 'Fixture Ensemble',
        'lyrics': {'plain': bulky},
      };
      final vague = wire((_) => json({'results': [target]}));
      final selection = (await SyncLrcProvider(vague).search('paper')).single;
      await vague.close();
      final t = wire((_) => json({'results': []}));
      await expectLater(
        SyncLrcProvider(t).resolve(selection),
        throwsA(errorCode('unavailable')),
      );
      await t.close();
    });
  });

  group('blocked pages are not extraction failures', () {
    const cloudflare =
        '<html><head><title>Just a moment...</title></head><body><div id="challenge-platform"></div></body></html>';
    test('Genius, Ultimate Guitar and Songsterr', () {
      expect(
        () => GeniusProvider.extractLyrics(cloudflare),
        throwsA(
          isA<ProviderException>()
              .having((e) => e.code, 'code', 'blocked')
              .having((e) => e.message, 'message', 'cloudflare'),
        ),
      );
      expect(
        () => UltimateGuitarProvider.parseSearch(cloudflare),
        throwsA(errorCode('blocked')),
      );
      expect(
        () => UltimateGuitarProvider.parseSearch('<html><body>Hi</body></html>'),
        throwsA(errorCode('extraction_failed')),
      );
      expect(
        () => SongsterrProvider.parseSearch(
          '<html><body><div class="g-recaptcha"></div></body></html>',
        ),
        throwsA(errorCode('blocked')),
      );
    });
    test('Genius accepts the alternate container class', () {
      expect(
        GeniusProvider.extractLyrics(
          '<div class="Lyrics__Container-sc-1">First invented line<br>Second line</div>',
        ),
        'First invented line\nSecond line',
      );
    });
    test('YouTube Music reports the consent page and never sends a consent cookie', () async {
      final cookies = <String?>[];
      final t = wire((request) {
        cookies.add(request.headers['Cookie']);
        return http.Response(
          '<html><form action="https://consent.youtube.com/save">Before you continue to YouTube</form></html>',
          200,
        );
      });
      await expectLater(
        YoutubeMusicProvider(t).search('paper'),
        throwsA(
          isA<ProviderException>()
              .having((e) => e.code, 'code', 'blocked')
              .having((e) => e.message, 'message', 'consent_required'),
        ),
      );
      expect(cookies, [null]);
      await t.close();
    });
    test('YouTube Music consent redirect is also blocked/consent_required', () async {
      final t = wire(
        (_) => http.Response(
          '',
          302,
          headers: {'location': 'https://consent.youtube.com/m?continue=x'},
        ),
      );
      await expectLater(
        YoutubeMusicProvider(t).search('paper'),
        throwsA(
          isA<ProviderException>()
              .having((e) => e.code, 'code', 'blocked')
              .having((e) => e.message, 'message', 'consent_required'),
        ),
      );
      await t.close();
    });
    test('a changed page still reports extraction_failed', () async {
      final t = wire((_) => http.Response('<html>nothing here</html>', 200));
      await expectLater(
        YoutubeMusicProvider(t).search('paper'),
        throwsA(errorCode('extraction_failed')),
      );
      await t.close();
    });
  });

  group('failures are recorded for every attempted candidate', () {
    test('extraction failures are aggregated, not only the first', () async {
      final provider = _FailingProvider([
        song('1'),
        song('2'),
      ], const ProviderException('extraction_failed', 'layout'));
      await expectLater(
        findMatchingSource(provider, song('0')),
        throwsA(
          isA<ProviderException>()
              .having((e) => e.code, 'code', 'extraction_failed')
              .having((e) => e.message, 'message', allOf(contains('1 '), contains('2 '))),
        ),
      );
    });
    test('blocked is surfaced at once', () async {
      final provider = _FailingProvider([
        song('1'),
      ], const ProviderException('blocked', 'cloudflare'));
      await expectLater(
        findMatchingSource(provider, song('0')),
        throwsA(errorCode('blocked')),
      );
    });
  });

  group('untrusted URLs', () {
    test('artwork and media links keep only safe https URLs on expected hosts', () {
      final song = GeniusProvider.parseSong({
        'id': 9,
        'title': 'Paper Satellites',
        'primary_artist': {'name': 'Fixture Ensemble'},
        'url': 'https://genius.com/fixture',
        'song_art_image_url': 'https://tracker.example/pixel.png',
        'header_image_url': 'https://images.genius.com/header.jpg',
        'media': [
          {'type': 'video', 'provider': 'youtube', 'url': 'http://youtube.com/x'},
          {'type': 'video', 'provider': 'youtube', 'url': 'https://u:p@youtube.com/x'},
          {'type': 'video', 'provider': 'youtube', 'url': 'https://127.0.0.1/x'},
          {'type': 'video', 'provider': 'youtube', 'url': 'javascript:alert(1)'},
          {'type': 'video', 'provider': 'youtube', 'url': 'https://www.youtube.com/watch?v=abcdefghijk'},
        ],
      });
      expect(song.metadata['artworkUrl'], 'https://images.genius.com/header.jpg');
      final links = song.metadata['mediaLinks'] as List;
      expect(links.map((l) => l['url']), [
        'https://www.youtube.com/watch?v=abcdefghijk',
      ]);
    });
    test('Lyrics.ovh upgrades Deezer http art and drops foreign hosts', () async {
      final t = wire(
        (_) => json({
          'data': [
            {
              'id': 5,
              'title': 'Paper Satellites',
              'artist': {'name': 'Fixture Ensemble'},
              'album': {
                'title': 'A',
                'cover_xl': 'https://evil.example/cover.jpg',
                'cover_big': 'http://cdn-images.dzcdn.net/images/cover/big.jpg',
              },
            },
          ],
        }),
      );
      final song = (await LyricsOvhProvider(t).search('x')).single;
      expect(
        song.metadata['artworkUrl'],
        'https://cdn-images.dzcdn.net/images/cover/big.jpg',
      );
      await t.close();
    });
    test('YouTube Music thumbnails are limited to Google/YouTube image hosts', () {
      final results = YoutubeMusicProvider.parseSearch(
        ytSearch([
          ytRow(
            'abcdefghijk',
            thumbnails: [
              {'url': 'https://evil.example/a.jpg', 'width': 900},
              {'url': 'https://lh3.googleusercontent.com/a=w120', 'width': 120},
            ],
          ),
        ]),
      );
      expect(
        results.single.metadata['artworkUrl'],
        'https://lh3.googleusercontent.com/a=w120',
      );
    });
    test('httpsUrl rejects userinfo, ports, IP literals and local names', () {
      for (final bad in [
        'http://example.org/',
        'https://user@example.org/',
        'https://example.org:8080/',
        'https://10.0.0.1/a',
        'https://[::1]/a',
        'https://localhost/a',
        'https://printer.local/a',
        'https://intranet/a',
        'https://example.org/a b',
        'ftp://example.org/',
        42,
        null,
      ]) {
        expect(httpsUrl(bad), isNull, reason: '$bad');
      }
      expect(httpsUrl('https://example.org/a?b=c'), 'https://example.org/a?b=c');
    });
  });

  group('rights metadata stays conservative', () {
    test('plain-text sources record unknown rights with a user-responsibility note', () {
      final r = lyricsResult(
        const SongCandidate(
          providerId: 'lrclib',
          id: '1',
          title: 'Paper Satellites',
          artist: 'Fixture Ensemble',
        ),
        words,
        attribution: 'LRCLIB',
      );
      final rights = r.extra['rights'] as Map;
      expect(rights['status'], 'unknown');
      expect(rights['note'], contains('responsibility'));
    });
  });
}
