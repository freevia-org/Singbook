import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/core/catalogs.dart';
import 'package:singbook/providers/core/charts.dart';
import 'package:singbook/providers/core/common.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/core/youtube_music.dart';

const words =
    'A paper satellite sails above the desk tonight\nOur quiet room remembers all the stories from the rain';
Matcher errorCode(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);
ProviderTransport wire(
  FutureOr<http.Response> Function(http.Request) handler, {
  Duration timeout = const Duration(seconds: 2),
  int maxBytes = 4 * 1024 * 1024,
}) => ProviderTransport(
  client: MockClient((request) async => handler(request)),
  hostInterval: Duration.zero,
  timeout: timeout,
  maxBytes: maxBytes,
  retryBaseDelay: const Duration(milliseconds: 1),
);
http.Response jsonResponse(Object value, [int code = 200]) => http.Response(
  jsonEncode(value),
  code,
  headers: {'content-type': 'application/json'},
);

class _SlowAbortClient extends http.BaseClient {
  final abortObserved = Completer<void>();
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is! http.AbortableRequest) {
      throw StateError('Expected an abortable request');
    }
    await request.abortTrigger;
    abortObserved.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    throw http.ClientException('Native abort cleanup finished', request.url);
  }

  @override
  void close() => closed = true;
}

JsonMap lrcRecord({int id = 1, String artist = 'Fixture Ensemble'}) => {
  'id': id,
  'trackName': 'Paper Satellites',
  'artistName': artist,
  'albumName': 'Test Record',
  'duration': 123,
  'plainLyrics': words,
  'syncedLyrics':
      '[00:01.000]A paper satellite sails above the desk tonight\n[00:07.250]Our quiet room remembers all the stories from the rain',
  'instrumental': false,
};
SongCandidate candidate({
  String provider = 'fixture',
  String id = '1',
  String title = 'Paper Satellites',
  String artist = 'Fixture Ensemble',
  String? album,
  double? duration,
}) => SongCandidate(
  providerId: provider,
  id: id,
  title: title,
  artist: artist,
  album: album,
  durationSeconds: duration,
);

class FixtureProvider implements LyricsProvider {
  FixtureProvider({
    this.id = 'fixture',
    this.caps = const {'lyrics'},
    this.hits = const [],
    this.result,
    this.fail,
  });
  final String id;
  final Set<String> caps;
  final List<SongCandidate> hits;
  final SourceResult? result;
  final ProviderException? fail;
  int calls = 0;
  @override
  ProviderDefinition get definition =>
      ProviderDefinition(id: id, name: id, capabilities: caps);
  @override
  Future<List<SongCandidate>> search(
    String q, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    return hits;
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate c, {
    CancellationToken? cancel,
  }) async {
    calls++;
    cancel?.throwIfCancelled();
    if (fail != null) throw fail!;
    return result ?? SourceResult(candidate: c, body: words);
  }
}

void main() {
  group('transport', () {
    test(
      'classifies denial, rate limit, missing and redirects without following',
      () async {
        for (final pair in {
          403: 'access_denied',
          429: 'rate_limited',
          404: 'unavailable',
          302: 'redirect',
        }.entries) {
          final t = wire((request) {
            expect(request.followRedirects, false);
            return http.Response('private upstream body', pair.key);
          });
          await expectLater(
            t.getText(Uri.parse('https://example.org/')),
            throwsA(errorCode(pair.value)),
          );
          await t.close();
        }
      },
    );
    test(
      'invalid JSON, plaintext URLs and response bounds are rejected',
      () async {
        final t = wire((_) => http.Response('not JSON', 200), maxBytes: 20);
        await expectLater(
          t.requestJson(Uri.parse('https://example.org/')),
          throwsA(errorCode('invalid_response')),
        );
        expect(
          () => t.getText(Uri.parse('http://example.org/')),
          throwsA(errorCode('invalid_url')),
        );
        await t.close();
        final large = wire((_) => http.Response('x' * 21, 200), maxBytes: 20);
        await expectLater(
          large.getText(Uri.parse('https://example.org/')),
          throwsA(errorCode('invalid_response')),
        );
        await large.close();
      },
    );
    test('timeout and cancellation surface promptly', () async {
      final t = wire((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response('ok', 200);
      }, timeout: const Duration(milliseconds: 15));
      await expectLater(
        t.getText(Uri.parse('https://example.org/')),
        throwsA(errorCode('timeout')),
      );
      await t.close();
      final token = CancellationToken()..cancel();
      final t2 = wire((_) => throw StateError('must not request'));
      expect(
        () => t2.getText(Uri.parse('https://example.org/'), cancel: token),
        throwsA(errorCode('cancelled')),
      );
      await t2.close();
    });
    test('close drains native cleanup after a timed out request', () async {
      final client = _SlowAbortClient();
      final t = ProviderTransport(
        client: client,
        timeout: const Duration(milliseconds: 10),
        hostInterval: Duration.zero,
      );
      await expectLater(
        t.getText(Uri.parse('https://example.org/')),
        throwsA(errorCode('timeout')),
      );
      await client.abortObserved.future;
      expect(client.closed, false);
      await t.close();
      expect(client.closed, true);
    });
    test(
      'same-host requests are serialized while separate hosts can progress',
      () async {
        var inFlight = 0, maxInFlight = 0;
        final t = wire((_) async {
          inFlight++;
          if (inFlight > maxInFlight) maxInFlight = inFlight;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          inFlight--;
          return http.Response('ok', 200);
        });
        await Future.wait(
          List.generate(4, (_) => t.getText(Uri.parse('https://example.org/'))),
        );
        expect(maxInFlight, 1);
        await t.close();
      },
    );
  });
  group('Genius', () {
    test('extracts only recognized lyric containers, removes excluded UI', () {
      final result = GeniusProvider.extractLyrics(
        '<h1>Not lyrics</h1><div data-lyrics-container="true">First invented line<br>Second <a>invented</a> line<button>Share</button><span aria-hidden="true">Hidden</span></div>',
      );
      expect(result, 'First invented line\nSecond invented line');
      expect(
        () => GeniusProvider.extractLyrics('<html>Access denied</html>'),
        throwsA(errorCode('extraction_failed')),
      );
    });
    test(
      'token goes only to API, details supply verified album omitted by search',
      () async {
        final t = wire((request) {
          if (request.url.host == 'api.genius.com') {
            expect(request.headers['authorization'], 'Bearer fixture-token');
            return jsonResponse({
              'response': {
                'song': {
                  'id': 1,
                  'title': 'Paper Satellites',
                  'primary_artist': {'name': 'Fixture Ensemble'},
                  'album': {'name': 'Test Record'},
                  'url': 'https://genius.com/fixture-lyrics',
                },
              },
            });
          }
          expect(request.headers.containsKey('authorization'), false);
          return http.Response(
            '<div data-lyrics-container="true">${words.replaceAll('\n', '<br>')}</div>',
            200,
          );
        });
        final r = await GeniusProvider(
          t,
          token: 'fixture-token',
        ).resolve(candidate(provider: 'genius'));
        expect(r.candidate.album, 'Test Record');
        expect(r.body, words);
        await t.close();
      },
    );
    test('unconfigured builds fail explicitly', () async {
      final t = wire((_) => throw StateError('no request'));
      await expectLater(
        GeniusProvider(t, token: '').search('song'),
        throwsA(errorCode('not_configured')),
      );
      await t.close();
    });
  });
  group('timed catalogs', () {
    test(
      'LRCLIB retains raw LRC, fractional timestamps and independent plain text',
      () async {
        final t = wire((_) => jsonResponse(lrcRecord()));
        final p = LrclibProvider(t);
        final r = await p.resolve(candidate(provider: 'lrclib'));
        expect(r.timingTracks.single.raw, lrcRecord()['syncedLyrics']);
        expect(r.timingTracks.single.cues.last.startUs, 7250000);
        expect(r.body, words);
        await t.close();
      },
    );
    test('LRCLIB rejects a returned different ID', () async {
      final t = wire((_) => jsonResponse(lrcRecord(id: 2)));
      await expectLater(
        LrclibProvider(t).resolve(candidate(provider: 'lrclib')),
        throwsA(errorCode('invalid_response')),
      );
      await t.close();
    });
    test('SyncLRC preserves both line and karaoke versions', () async {
      final row = {
        'id': 'a' * 32,
        'track': 'Paper Satellites',
        'artist': 'Fixture Ensemble',
        'album': 'Test Record',
        'duration': 123,
        'lyrics': {
          'plain': words,
          'synced': '[00:01.00]First invented line',
          'karaoke': '[00:01.00]<00:01.00>First <00:01.50>invented line',
        },
      };
      final t = wire(
            (_) => jsonResponse({
              'results': [row],
            }),
          ),
          p = SyncLrcProvider(t);
      final results = await p.search('Paper Satellites Fixture Ensemble');
      final r = await p.resolve(results.single);
      expect(r.timingTracks.length, 2);
      expect(r.timingTracks.last.granularity, 'word');
      expect(r.timingTracks.last.raw, (row['lyrics'] as Map)['karaoke']);
      await t.close();
    });
    test('Better Lyrics keeps TTML word boundaries and end times', () async {
      const ttml =
          '<tt xmlns="http://www.w3.org/ns/ttml"><body><div><p begin="1.25s" end="4.5s"><span begin="0s" end="0.75s">Paper </span><span begin="0.75s" end="2.75s">satellites</span></p></div></body></tt>';
      final t = wire(
        (r) => jsonResponse(
          r.url.host == 'lrclib.net' ? lrcRecord() : {'ttml': ttml},
        ),
      );
      final r = await BetterLyricsProvider(
        t,
      ).resolve(candidate(provider: 'betterlyrics'));
      expect(r.timingTracks.single.raw, ttml);
      expect(r.timingTracks.single.cues.any((c) => c.endUs == 2000000), true);
      expect(r.timingTracks.single.granularity, 'word');
      await t.close();
    });
  });
  test('Better Lyrics refusing an uncached song means unavailable', () async {
    final t = wire(
      (r) => r.url.host == 'lrclib.net'
          ? jsonResponse(lrcRecord())
          : http.Response(
              '{"error":"API key required"}',
              401,
              headers: {'content-type': 'application/json'},
            ),
    );
    await expectLater(
      BetterLyricsProvider(t).resolve(candidate(provider: 'betterlyrics')),
      throwsA(
        isA<ProviderException>().having((e) => e.code, 'code', 'unavailable'),
      ),
    );
    await t.close();
  });
  group('matching and discovery', () {
    test(
      'unsupported raw timing survives a timing-only provider result',
      () async {
        const raw = '<tt><body><p begin="future:timebase"></p></body></tt>';
        final t = wire(
          (request) => jsonResponse(
            request.url.host == 'lrclib.net' ? lrcRecord() : {'ttml': raw},
          ),
        );
        final result = await BetterLyricsProvider(
          t,
        ).resolve(candidate(provider: 'betterlyrics'));
        expect(result.body, '');
        expect(result.extra['timingOnly'], true);
        expect(result.timingTracks.single.raw, raw);
        expect(result.timingTracks.single.status, TimingStatus.invalid);
        final provider = FixtureProvider(
          result: SourceResult(
            candidate: candidate(),
            body: '',
            timingTracks: result.timingTracks,
          ),
        );
        final found = await findMatchingSource(provider, candidate());
        expect(found.timingTracks.single.raw, raw);
        await t.close();
      },
    );
    test(
      'conflicting known recording identifiers reject otherwise identical metadata',
      () {
        const a = SongCandidate(
          providerId: 'one',
          id: '1',
          title: 'Song',
          artist: 'Artist',
          recordingIds: {'isrc': 'AAA'},
        );
        const b = SongCandidate(
          providerId: 'two',
          id: '2',
          title: 'Song',
          artist: 'Artist',
          recordingIds: {'isrc': 'BBB'},
        );
        expect(sameSong(a, b), false);
      },
    );
    test(
      'intraword chord anchors do not split words during corroboration',
      () async {
        final plain = FixtureProvider();
        final chart = FixtureProvider(
          id: 'chart',
          caps: {'lyrics', 'chords'},
          hits: [candidate(provider: 'chart')],
          result: SourceResult(
            candidate: candidate(provider: 'chart'),
            body: words.replaceFirst('paper', 'pa[C]per'),
          ),
        );
        final found = await SourceDiscoveryService([
          chart,
          plain,
        ]).discover(candidate());
        expect(
          found.firstWhere((r) => r.candidate.providerId == 'chart').matchKind,
          MatchKind.sameSong,
        );
      },
    );
    test(
      'a tiny reference does not invalidate an independently matched full chord sheet',
      () async {
        final chart = FixtureProvider(
          id: 'chart',
          caps: {'lyrics', 'chords'},
          result: SourceResult(
            candidate: candidate(provider: 'chart'),
            body: '[C]$words',
          ),
        );
        final plain = FixtureProvider(
          hits: [candidate()],
          result: SourceResult(candidate: candidate(), body: 'Paper satellite'),
        );
        final found = await SourceDiscoveryService([
          chart,
          plain,
        ]).discover(candidate(provider: 'chart'));
        expect(
          found.firstWhere((r) => r.candidate.providerId == 'chart').matchKind,
          MatchKind.sameSong,
        );
      },
    );
    test(
      'same-source detail may fill a live album without rejecting selected recording',
      () {
        expect(
          sameSong(
            candidate(title: 'Paper Satellites (Live)'),
            candidate(
              title: 'Paper Satellites (Live)',
              album: 'Live at the Test Room',
            ),
          ),
          true,
        );
        expect(
          sameSong(candidate(), candidate(artist: 'Different Artist')),
          false,
        );
        expect(
          sameSong(candidate(), candidate(title: 'Paper Satellites (Live)')),
          false,
        );
        expect(
          sameSong(candidate(duration: 123), candidate(duration: 153)),
          false,
        );
      },
    );
    test('studio and live albums cannot be treated as same recording', () {
      expect(
        sameSong(
          candidate(album: 'Studio Record'),
          candidate(album: 'Live at the Test Room'),
        ),
        false,
      );
    });
    test(
      'wrong detail identity is retained as rejected, never accepted',
      () async {
        final p = FixtureProvider(
          result: SourceResult(
            candidate: candidate(artist: 'Wrong Artist'),
            body: words,
          ),
        );
        final r = await findMatchingSource(p, candidate());
        expect(r.matchKind, MatchKind.rejected);
      },
    );
    test(
      'metadata-only verified results survive discovery without invented lyrics',
      () async {
        final p = FixtureProvider(
          caps: {'metadata'},
          result: SourceResult(
            candidate: candidate(),
            body: '',
            metadata: {'year': 2020},
          ),
        );
        final results = await SourceDiscoveryService([p]).discover(candidate());
        expect(results.single.body, '');
        expect(results.single.metadata['year'], 2020);
      },
    );
    test('one failed source does not erase successful sources', () async {
      final good = FixtureProvider(),
          bad = FixtureProvider(
            id: 'bad',
            hits: [candidate(provider: 'bad')],
            fail: const ProviderException('access_denied'),
          );
      final checks = <ProviderCheck>[];
      final results = await SourceDiscoveryService([
        good,
        bad,
      ]).discover(candidate(), onProgress: checks.add);
      expect(results.length, 1);
      expect(
        checks.any(
          (c) =>
              c.providerId == 'bad' &&
              c.state == 'failed' &&
              c.code == 'access_denied',
        ),
        true,
      );
    });
    test('incomplete chart rejected after full reference arrives', () async {
      final plain = FixtureProvider();
      final chart = FixtureProvider(
        id: 'chart',
        caps: {'lyrics', 'chords'},
        hits: [candidate(provider: 'chart')],
        result: SourceResult(
          candidate: candidate(provider: 'chart'),
          body: '[C]A paper satellite',
        ),
      );
      final results = await SourceDiscoveryService([
        chart,
        plain,
      ]).discover(candidate());
      expect(
        results.firstWhere((r) => r.candidate.providerId == 'chart').matchKind,
        MatchKind.rejected,
      );
    });
    test(
      'catalog contains exactly the eight implemented Songbook adapters',
      () async {
        final t = wire((_) => throw StateError('no network'));
        expect(
          createCoreProviders(transport: t).map((p) => p.definition.id).toSet(),
          {
            'genius',
            'songsterr',
            'ultimateguitar',
            'lrclib',
            'youtubemusic',
            'lyricsovh',
            'synclrc',
            'betterlyrics',
          },
        );
        await t.close();
      },
    );
  });
  group('chord sheets', () {
    const path = '/a/wsa/fixture-ensemble-paper-satellites-chords-s123';
    JsonMap chord(String root, {String suffix = '', String? bass}) => {
      'type': 'chord',
      'chord': {
        'baseNote': {'name': root},
        'firstNote': {'name': bass ?? root},
        'chordType': {'suffix': suffix},
      },
    };
    JsonMap text(String value) => {'type': 'text', 'text': value};
    String page(List<JsonMap> rows, {int id = 123}) =>
        '<link rel="canonical" href="https://www.songsterr.com$path"><script id="state" type="application/json">${jsonEncode({
          'chords': {
            'current': {'songId': id, 'title': 'Paper Satellites', 'artist': 'Fixture Ensemble'},
          },
          'chordpro': {'current': rows},
        })}</script>';
    List<JsonMap> lines() => [
      {
        'type': 'line',
        'line': [
          text('🌟 Our '),
          chord('C', suffix: 'maj7'),
          text('invented first line'),
        ],
      },
      {
        'type': 'line',
        'line': [
          text('A second invented verse'),
          chord('G', suffix: '7', bass: 'B'),
        ],
      },
    ];
    test(
      'Songsterr anchors its own words and slash chords without moving Unicode',
      () {
        final r = SongsterrProvider.parsePage(page(lines()), path);
        expect(
          r.body,
          '🌟 Our [Cmaj7]invented first line\nA second invented verse[G7/B]',
        );
      },
    );
    test('Songsterr skips a chord it could not name', () {
      final r = SongsterrProvider.parsePage(
        page([
          ...lines(),
          {
            'type': 'line',
            'line': [
              text('A third invented '),
              {'type': 'chord', 'chord': null},
              text('line'),
            ],
          },
        ]),
        path,
      );
      expect(r.body.split('\n').last, 'A third invented line');
    });
    test('Songsterr rejects unknown rows, tabs-only and wrong identity', () {
      expect(
        () => SongsterrProvider.parsePage(
          page([
            ...lines(),
            {'type': 'unknown'},
          ]),
          path,
        ),
        throwsA(errorCode('invalid_response')),
      );
      expect(
        () => SongsterrProvider.parsePage(page([], id: 999), path),
        throwsA(errorCode('invalid_response')),
      );
      expect(
        () => SongsterrProvider.parsePage(
          page([
            {
              'type': 'line',
              'line': [chord('C')],
            },
          ]),
          path,
        ),
        throwsA(errorCode('unavailable')),
      );
    });
    test(
      'Songsterr does not use interface capo default as source metadata',
      () {
        final r = SongsterrProvider.parsePage(
          page([
            {'type': 'capo', 'text': '2'},
            ...lines(),
          ]),
          path,
        );
        expect(r.metadata['capo'], 2);
        expect(r.metadata.containsKey('key'), false);
      },
    );
    test(
      'Ultimate Guitar pairs chord rows with lyric lines and retains intro/outro',
      () {
        const raw =
            'Contributor introduction.\n[Intro]\n[ch]C[/ch]  [ch]G/B[/ch] (2x)\n[Verse 1]\n[tab][ch]C[/ch]       [ch]F#m7[/ch]\nA paper satellite sails[/tab]\n[tab]     [ch]D[/ch]       [ch]G/B[/ch]\nAbove an empty desk at night[/tab]\n[Outro]\n[ch]C[/ch]';
        final body = UltimateGuitarProvider.parseText(raw);
        expect(body.contains('Contributor'), false);
        expect(body.contains('[C]A paper [F#m7]satellite sails'), true);
        expect(body.contains('Above[D] an empt[G/B]y desk at night'), true);
        expect(body.endsWith('[C]'), true);
      },
    );
    test('Ultimate Guitar keeps a footnoted chord row over its lyrics', () {
      const raw =
          '[tab][ch]G[/ch]                  [ch]Am[/ch]  *\n'
          'A paper satellite sails tonight[/tab]\n'
          '[tab][ch]D[/ch]\nAbove an empty desk at night[/tab]';
      final body = UltimateGuitarProvider.parseText(raw);
      expect(body, startsWith('[G]A paper satellite s'));
      expect(body, contains('[Am]'));
      expect(body, isNot(contains('*')));
    });
    test('Ultimate Guitar reads "o" as a diminished chord', () {
      const raw =
          '[tab][ch]C#o[/ch]      [ch]Bo7[/ch]\nA paper satellite sails[/tab]\n'
          '[tab][ch]D[/ch]\nAbove an empty desk at night[/tab]';
      final body = UltimateGuitarProvider.parseText(raw);
      expect(body, contains('[C#dim]'));
      expect(body, contains('[Bdim7]'));
    });
    test(
      'Ultimate Guitar rejects invalid tags and charts without meaningful words',
      () {
        expect(
          () => UltimateGuitarProvider.parseText('[ch]Invalid[/ch]\n$words'),
          throwsA(errorCode('invalid_response')),
        );
        expect(
          () => UltimateGuitarProvider.parseText('[ch]C[/ch]\n[ch]G[/ch]'),
          throwsA(errorCode('unavailable')),
        );
      },
    );
    test(
      'plain source text cannot introduce ChordPro chords or directives',
      () {
        expect(
          plainToChordPro('Text [C] notation\n{title: fake}'),
          r'Text \[C\] notation'
          '\n'
          r'\{title: fake\}',
        );
        expect(plainToChordPro('[Verse 1]'), '{comment: Verse 1}');
      },
    );
  });
  group('YouTube Music', () {
    test('lyrics require the lyrics shelf, not a video description or URL', () {
      expect(
        () => YoutubeMusicProvider.parseLyrics({
          'videoDetails': {'shortDescription': 'Lyrics here'},
        }),
        throwsA(errorCode('unavailable')),
      );
      final r = YoutubeMusicProvider.parseLyrics({
        'contents': {
          'sectionListRenderer': {
            'contents': [
              {
                'musicDescriptionShelfRenderer': {
                  'description': {
                    'runs': [
                      {'text': words},
                    ],
                  },
                  'footer': {
                    'runs': [
                      {'text': 'Source: Fixture'},
                    ],
                  },
                },
              },
            ],
          },
        },
      });
      expect(r.lyrics, words);
      expect(r.attribution, 'Source: Fixture');
    });
    test('lyrics placeholders do not become successful sources', () {
      expect(
        () => YoutubeMusicProvider.parseLyrics({
          'contents': {
            'sectionListRenderer': {
              'contents': [
                {
                  'musicDescriptionShelfRenderer': {
                    'description': {
                      'runs': [
                        {'text': 'No lyrics available'},
                      ],
                    },
                  },
                },
              ],
            },
          },
        }),
        throwsA(errorCode('unavailable')),
      );
    });
  });
}
