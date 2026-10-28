import 'dart:convert';

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
  <b>Artist - Test Song</b>
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
  String? canonical =
      'https://www.chords-and-tabs.net/song/name/artist-test-song',
}) =>
    '''
<!doctype html>
<html><head>
${canonical == null ? '' : '<link rel="canonical" href="$canonical">'}
<script type="application/ld+json">{"@type":"MusicRecording","name":"$title","byArtist":{"@type":"MusicGroup","name":"$artist"}}</script>
</head><body>
<h1><a>$artist</a> - $title</h1>
<span class="songtype $chartType">chords</span>
<div id="snippet--snippetXteView" class="xte-view">$badges$chart</div>
</body></html>
''';

class _Harness {
  _Harness({
    required String search,
    required String page,
    List<int>? pageBytes,
  }) {
    client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.startsWith('/songs/search/')) {
        return http.Response(search, 200);
      }
      if (request.url.path == '/song/name/artist-test-song') {
        return http.Response.bytes(pageBytes ?? utf8.encode(page), 200);
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
  test('the native candidate is disabled until explicitly enabled', () async {
    final harness = _Harness(search: _search, page: _page());
    addTearDown(harness.transport.close);
    expect(harness.provider.definition.enabledByDefault, isFalse);
  });
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

  test('resolved metadata comes only from the validated chart page', () {
    final parsed = ChordsAndTabsProvider.parseSearch(
      _search,
      'Artist Test Song',
    ).single;
    final selected = SongCandidate(
      providerId: parsed.providerId,
      id: parsed.id,
      title: parsed.title,
      artist: parsed.artist,
      url: parsed.url,
      album: 'Caller Album',
      durationSeconds: 222,
      metadata: const {
        'key': 'F#m',
        'isrc': 'CALLER-ISRC',
        'album': 'Caller Metadata Album',
        'artworkUrl': 'https://caller.example/artwork.jpg',
        'artistEvidence': {'name': 'Caller Artist'},
        'mediaLinks': [
          {'url': 'https://caller.example/recording'},
        ],
        'identityScope': 'recording',
      },
      recordingIds: const {'isrc': 'CALLER-ISRC'},
      extra: const {'callerEvidence': true},
    );

    final absentKey = ChordsAndTabsProvider.parsePage(_page(), selected);
    expect(absentKey.candidate.title, 'Test Song');
    expect(absentKey.candidate.artist, 'Artist');
    expect(absentKey.candidate.album, isNull);
    expect(absentKey.candidate.durationSeconds, isNull);
    expect(absentKey.candidate.recordingIds, isEmpty);
    expect(absentKey.candidate.extra, isEmpty);
    expect(absentKey.metadata, {
      'identityScope': 'arrangement',
      'sourceChartType': 'chords',
      'tuning': ['E', 'A', 'D', 'G', 'B', 'E'],
    });

    final pageKey = ChordsAndTabsProvider.parsePage(
      _page(badges: '<span class="x-badge">Key: C</span>'),
      selected,
    );
    expect(pageKey.metadata['key'], 'C');
    expect(pageKey.metadata, isNot(contains('isrc')));
    expect(pageKey.metadata, isNot(contains('album')));
    expect(pageKey.metadata, isNot(contains('artworkUrl')));
    expect(pageKey.metadata, isNot(contains('artistEvidence')));
    expect(pageKey.metadata, isNot(contains('mediaLinks')));
  });

  test('visible title and artist cannot contradict structured identity', () {
    final candidate = ChordsAndTabsProvider.parseSearch(
      _search,
      'Artist Test Song',
    ).single;
    for (final heading in [
      '<h1><a>Wrong Artist</a> - Test Song</h1>',
      '<h1><a>Artist</a> - Wrong Song</h1>',
    ]) {
      expect(
        () => ChordsAndTabsProvider.parsePage(
          _page().replaceFirst('<h1><a>Artist</a> - Test Song</h1>', heading),
          candidate,
        ),
        throwsA(_failure('identity_mismatch')),
      );
    }
    expect(
      () => ChordsAndTabsProvider.parsePage(
        _page().replaceFirst(
          '<h1><a>Artist</a> - Test Song</h1>',
          '<h1>Wrong visible title</h1>',
        ),
        candidate,
      ),
      throwsA(_failure('extraction_failed')),
    );
  });

  test('legacy chart type excludes alternate arrangement labels', () {
    final candidate = ChordsAndTabsProvider.parseSearch(
      _search,
      'Test Song',
    ).single;
    final page = _page().replaceFirst(
      '<body>',
      '<body><div class="song-versions"><a><span class="songtype typeukulele">'
          'ukulele</span>ver. 3</a></div>',
    );
    final result = ChordsAndTabsProvider.parsePage(page, candidate);
    expect(result.metadata['sourceChartType'], 'chords');
    expect(result.extra['chartInstrument'], 'guitar');
  });

  String versionPage(String label) => _page().replaceFirst(
    '<span class="songtype typechords">chords</span>',
    '<a class="x-ddm-but sub-title">'
        '<span class="songtype typechords">chords</span><span>$label</span></a>'
        '<div class="song-versions">'
        '<a><span class="songtype typetabs">tabs</span>ver. 4</a>'
        '<a><span class="songtype typechords">chords</span>ver. 99</a></div>',
  );

  test(
    'search version hints constrain selection without becoming page facts',
    () {
      final search = _search.replaceFirst(
        '<b>Artist - Test Song</b>',
        '<b>Artist - Test Song</b><span class="version">ver. 4</span>',
      );
      final candidate = ChordsAndTabsProvider.parseSearch(
        search,
        'Test Song',
      ).single;
      expect(candidate.metadata['searchChartVersionHint'], 4);
      expect(candidate.metadata['searchChartTypeHint'], 'chords');
      final result = ChordsAndTabsProvider.parsePage(
        versionPage('ver. 4'),
        candidate,
      );
      expect(result.metadata['sourceChartVersion'], 4);
      expect(result.metadata, isNot(contains('searchChartVersionHint')));
      expect(
        () => ChordsAndTabsProvider.parsePage(versionPage('ver. 5'), candidate),
        throwsA(_failure('identity_mismatch')),
      );
      expect(
        () => ChordsAndTabsProvider.parsePage(_page(), candidate),
        throwsA(_failure('extraction_failed')),
      );
      expect(
        ChordsAndTabsProvider.parseSearch('$search$search', 'Test Song'),
        hasLength(1),
      );
      expect(
        ChordsAndTabsProvider.parseSearch(
          '$search${search.replaceFirst('ver. 4', 'ver. 5')}',
          'Test Song',
        ),
        isEmpty,
      );
    },
  );

  test(
    'selected chart version is independent of other arrangements and caller',
    () {
      final candidate = ChordsAndTabsProvider.parseSearch(
        _search,
        'Artist Test Song',
      ).single;
      final selected = SongCandidate.fromJson({
        ...candidate.toJson(),
        'metadata': {'sourceChartVersion': 88, 'sourceChartType': 'tabs'},
      });
      final result = ChordsAndTabsProvider.parsePage(
        versionPage('ver. 4'),
        selected,
      );
      expect(result.metadata['sourceChartVersion'], 4);
      expect(result.metadata['sourceChartType'], 'chords');
      expect(result.candidate.metadata, result.metadata);
      expect(result.candidate.id, candidate.id);
      expect(
        ChordsAndTabsProvider.parsePage(_page(), candidate).metadata,
        isNot(contains('sourceChartVersion')),
      );
    },
  );

  test(
    'invalid or contradictory selected versions fail without choosing first',
    () {
      final candidate = ChordsAndTabsProvider.parseSearch(
        _search,
        'Artist Test Song',
      ).single;
      for (final label in ['ver. 0', 'ver. -1', 'ver. 10000', 'ver. unknown']) {
        expect(
          () => ChordsAndTabsProvider.parsePage(versionPage(label), candidate),
          throwsA(_failure('invalid_response')),
        );
      }
      expect(
        () => ChordsAndTabsProvider.parsePage(
          versionPage('ver. 4').replaceFirst(
            '</body>',
            '<a class="x-ddm-but sub-title"><span class="songtype typechords">'
                'chords</span>ver. 5</a></body>',
          ),
          candidate,
        ),
        throwsA(_failure('invalid_response')),
      );
    },
  );

  test(
    'decoded parser snapshot is retained without claiming exact HTTP bytes',
    () {
      final candidate = ChordsAndTabsProvider.parseSearch(
        _search,
        'Test Song',
      ).single;
      final page = _page();
      final result = ChordsAndTabsProvider.parsePage(page, candidate);
      final payload = result.extra['originalPayload'] as Map;
      expect(utf8.decode(base64Decode(payload['base64'] as String)), page);
      expect(payload['httpBodyBytesExact'], isFalse);
      expect(payload['contentType'], 'text/html');
      expect(result.extra['parserVersion'], 'chordsandtabs-2');
      final reopened = SourceResult.fromJson(
        jsonDecode(jsonEncode(result.toJson())),
      );
      expect(reopened.extra['originalPayload'], payload);
    },
  );

  test(
    'resolve retains exact UTF-8 HTTP bytes including BOM and accents',
    () async {
      final page = _page(
        chart: '<div class="song"><sup>C</sup>Caf\u00e9 morning.</div>',
      );
      final bytes = [0xef, 0xbb, 0xbf, ...utf8.encode(page)];
      final harness = _Harness(search: _search, page: page, pageBytes: bytes);
      addTearDown(harness.close);
      final selected = (await harness.provider.search('Test Song')).single;
      final result = await harness.provider.resolve(selected);
      final payload = result.extra['originalPayload'] as Map;
      expect(base64Decode(payload['base64'] as String), bytes);
      expect(payload['httpBodyBytesExact'], isTrue);
      expect(result.body, '[C]Caf\u00e9 morning.');
    },
  );

  test('malformed UTF-8 and oversized decoded source are rejected', () async {
    final candidate = ChordsAndTabsProvider.parseSearch(
      _search,
      'Test Song',
    ).single;
    final harness = _Harness(search: _search, page: _page(), pageBytes: [0xff]);
    addTearDown(harness.close);
    await expectLater(
      harness.provider.resolve(candidate),
      throwsA(_failure('invalid_response')),
    );
    expect(
      () => ChordsAndTabsProvider.parsePage('\u00e9' * (600 * 1024), candidate),
      throwsA(_failure('invalid_response')),
    );
  });

  test('canonical evidence is validated and request fallback is identified', () {
    final candidate = ChordsAndTabsProvider.parseSearch(
      _search,
      'Artist Test Song',
    ).single;
    final noCanonical = ChordsAndTabsProvider.parsePage(
      _page(canonical: null),
      candidate,
    );
    expect(noCanonical.extra['pageIdentityEvidence'], {
      'basis': 'validated_request_url',
      'url': candidate.url,
    });

    final duplicate = _page().replaceFirst(
      '<link rel="canonical" href="https://www.chords-and-tabs.net/song/name/artist-test-song">',
      '<link rel="canonical" href="https://www.chords-and-tabs.net/song/name/artist-test-song">'
          '<link rel="canonical" href="https://www.chords-and-tabs.net/song/name/artist-test-song">',
    );
    final canonical = ChordsAndTabsProvider.parsePage(duplicate, candidate);
    expect(canonical.extra['pageIdentityEvidence'], {
      'basis': 'publisher_canonical',
      'url': candidate.url,
    });

    expect(
      () => ChordsAndTabsProvider.parsePage(
        _page(canonical: 'https://evil.example/song/name/artist-test-song'),
        candidate,
      ),
      throwsA(_failure('invalid_selection')),
    );
    expect(
      () => ChordsAndTabsProvider.parsePage(
        _page(canonical: '/song/name/artist-test-song'),
        candidate,
      ),
      throwsA(_failure('invalid_selection')),
    );
    expect(
      () => ChordsAndTabsProvider.parsePage(
        _page(canonical: 'https://www.chords-and-tabs.net/song/name/other'),
        candidate,
      ),
      throwsA(_failure('identity_mismatch')),
    );
    final conflicting = _page().replaceFirst(
      '</head>',
      '<link rel="canonical" href="https://www.chords-and-tabs.net/song/name/other"></head>',
    );
    expect(
      () => ChordsAndTabsProvider.parsePage(conflicting, candidate),
      throwsA(_failure('identity_mismatch')),
    );
    expect(
      () => ChordsAndTabsProvider.parsePage(
        _page(canonical: 'https://www.chords-and-tabs.net/song/name/bad%zz'),
        candidate,
      ),
      throwsA(_failure('invalid_selection')),
    );
    expect(
      () => ChordsAndTabsProvider.parsePage(
        _page().replaceFirst(
          ' href="https://www.chords-and-tabs.net/song/name/artist-test-song"',
          '',
        ),
        candidate,
      ),
      throwsA(_failure('invalid_selection')),
    );
  });

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
