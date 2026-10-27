import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/chords_and_tabs.dart';
import 'package:singbook/providers/provider.dart';

const _search = '''
<form role="search" action="/songs/search/" method="post">
  <input name="search">
</form>
<a href="/song/name/artist-test-song">
  <span class="songtype typechords">chords</span>
  <b>Artist - Test Song</b><span class="version">ver. 1</span>
</a>
<a href="/song/name/artist-tab-song">
  <span class="songtype typetabs">tabs</span><b>Artist - Tab Song</b>
</a>
<a href="https://evil.example/song/name/artist-test-song">
  <span class="songtype typechords">chords</span><b>Artist - Test Song</b>
</a>
''';

String _page({
  String artist = 'Artist',
  String title = 'Test Song',
  String chartType = 'typechords',
  String chart =
      '<div class="song"><sup>C</sup>Morning light<sup>G7</sup> shines.</div>'
      '<div class="song"><sup>F</sup>Bright skies.</div>',
  String badges = '<span class="x-badge">Tuning: E A D G B E</span>',
}) =>
    '''
<!doctype html>
<html><head>
<link rel="canonical" href="https://www.chords-and-tabs.net/song/name/artist-test-song">
<script type="application/ld+json">{"@type":"MusicRecording","name":"$title","byArtist":{"@type":"MusicGroup","name":"$artist"}}</script>
</head><body>
<h1><a>$artist</a> - $title</h1>
<span class="songtype $chartType">chords</span>
<div id="snippet--snippetXteView" class="xte-view">$badges$chart</div>
</body></html>
''';

class _Harness {
  _Harness({required String search, required String page}) {
    client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.startsWith('/songs/search/')) {
        return http.Response(search, 200);
      }
      if (request.url.path == '/song/name/artist-test-song') {
        return http.Response(page, 200);
      }
      return http.Response('not found', 404);
    });
    transport = ProviderTransport(
      client: client,
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    provider = ChordsAndTabsProvider(transport);
  }

  late final MockClient client;
  final requests = <http.Request>[];
  late final ProviderTransport transport;
  late final ChordsAndTabsProvider provider;

  Future<void> close() => transport.close();
}

Matcher _failure(String code) =>
    isA<ProviderException>().having((error) => error.code, 'code', code);

void main() {
  test(
    'extended chords and flat tuning retain their actual musical spelling',
    () {
      final candidate = ChordsAndTabsProvider.parseSearch(
        _search,
        'Artist Test Song',
      ).single;
      final result = ChordsAndTabsProvider.parsePage(
        _page(
          chart:
              '<div class="song"><sup>A7sus4</sup>Morning <sup>Bbmaj7/F</sup>light <sup>Cadd9</sup>shines.</div>',
          badges: '<span class="x-badge">Tuning: Eb Ab Db Gb Bb Eb</span>',
        ),
        candidate,
      );
      expect(result.body, '[A7sus4]Morning [Bbmaj7/F]light [Cadd9]shines.');
      expect(result.metadata['tuning'], ['Eb', 'Ab', 'Db', 'Gb', 'Bb', 'Eb']);
    },
  );

  test(
    'visible plain artist-title heading can supply identity without JSON-LD',
    () {
      final candidate = ChordsAndTabsProvider.parseSearch(
        _search,
        'Artist Test Song',
      ).single;
      final page = _page()
          .replaceAll(RegExp(r'<script[^>]*>.*?</script>'), '')
          .replaceFirst(
            '<h1><a>Artist</a> - Test Song</h1>',
            '<h1>Artist - Test Song</h1>',
          );
      final result = ChordsAndTabsProvider.parsePage(page, candidate);
      expect(result.body, contains('[C]Morning'));
    },
  );

  test(
    'search returns chord sheets with exact artist and title identity',
    () async {
      final harness = _Harness(search: _search, page: _page());
      addTearDown(harness.close);

      final results = await harness.provider.search('Artist Test Song');
      expect(results, hasLength(1));
      expect(results.single.providerId, 'chordsandtabs');
      expect(results.single.id, '/song/name/artist-test-song');
      expect(results.single.title, 'Test Song');
      expect(results.single.artist, 'Artist');
      expect(
        results.single.url,
        'https://www.chords-and-tabs.net/song/name/artist-test-song',
      );
      expect(harness.requests.single.method, 'GET');
      expect(
        harness.requests.single.url.path,
        '/songs/search/Artist%20Test%20Song',
      );
    },
  );

  test(
    'search matches diacritic variants without rewriting source identity',
    () {
      final search = _search
          .replaceFirst('Artist - Test Song', 'Hugo Blanco - Moliendo cafe')
          .replaceFirst(
            '/song/name/artist-test-song',
            '/song/name/hugo-blanco-moliendo-cafe',
          );
      final results = ChordsAndTabsProvider.parseSearch(
        search,
        'Moliendo Café Hugo Blanco',
      );
      expect(results, hasLength(1));
      expect(results.single.title, 'Moliendo cafe');
      expect(results.single.artist, 'Hugo Blanco');
    },
  );

  test('resolve preserves each chord at its source word position', () async {
    final harness = _Harness(search: _search, page: _page());
    addTearDown(harness.close);
    final candidate = (await harness.provider.search(
      'Artist Test Song',
    )).single;

    final result = await harness.provider.resolve(candidate);
    expect(result.body, contains('[C]Morning light[G7] shines.'));
    expect(result.body, contains('[F]Bright skies.'));
    expect(result.metadata['tuning'], ['E', 'A', 'D', 'G', 'B', 'E']);
    expect(result.metadata, isNot(contains('key')));
    expect(result.metadata, isNot(contains('capo')));
    expect(result.extra['chartInstrument'], 'guitar');
    expect(result.attribution, 'Chords and Tabs');
    expect((result.extra['rights'] as Map)['permissions'], {
      'status': 'unknown',
    });
    expect((result.extra['rights'] as Map)['sourceUrl'], candidate.url);
  });

  test('rejects a different page identity and tab-only chart', () async {
    final candidate = ChordsAndTabsProvider.parseSearch(
      _search,
      'Artist Test Song',
    ).single;
    expect(
      () => ChordsAndTabsProvider.parsePage(
        _page(artist: 'Different artist'),
        candidate,
      ),
      throwsA(_failure('identity_mismatch')),
    );
    expect(
      () => ChordsAndTabsProvider.parsePage(
        _page(chartType: 'typetabs'),
        candidate,
      ),
      throwsA(_failure('unavailable')),
    );
  });

  test('rejects instrument-only rows and invalid chart paths', () {
    final candidate = ChordsAndTabsProvider.parseSearch(
      _search,
      'Artist Test Song',
    ).single;
    expect(
      () => ChordsAndTabsProvider.parsePage(
        _page(chart: '<div class="song">|--0--2--3--|</div>'),
        candidate,
      ),
      throwsA(_failure('unavailable')),
    );
    expect(
      ChordsAndTabsProvider.parseSearch(
        _search.replaceFirst(
          '/song/name/artist-test-song',
          '/song/name/../escape',
        ),
        'Artist Test Song',
      ),
      isEmpty,
    );
  });

  test('identifies blocked search pages', () {
    expect(
      () => ChordsAndTabsProvider.parseSearch(
        '<html><head><title>Access denied</title></head></html>',
        'Artist Test Song',
      ),
      throwsA(_failure('blocked')),
    );
  });

  test(
    'cancellation and malformed query are surfaced before requests',
    () async {
      final harness = _Harness(search: _search, page: _page());
      addTearDown(harness.close);
      final token = CancellationToken()..cancel();
      await expectLater(
        harness.provider.search('Artist Test Song', cancel: token),
        throwsA(_failure('cancelled')),
      );
      await expectLater(
        harness.provider.search(' '),
        throwsA(_failure('invalid_query')),
      );
      expect(harness.requests, isEmpty);
    },
  );
}
