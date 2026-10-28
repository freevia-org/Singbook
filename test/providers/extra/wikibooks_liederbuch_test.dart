import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/extra/wikibooks_liederbuch.dart';
import 'package:singbook/providers/provider.dart';

const _pageId = 7123;
const _pageTitle = 'Liederbuch/ Morgenwind am Silberhang';

Map<String, Object?> _searchHit({
  Object? pageId = _pageId,
  Object? namespace = 0,
  String title = _pageTitle,
}) => {'pageid': pageId, 'ns': namespace, 'title': title};

String _pageHtml({
  String title = 'Morgenwind am Silberhang',
  String body = '''
<p class="source-credits">Text: Liora Fen (synthetic fixture)<br>Melodie: K. Tarel (synthetic fixture)<br>Bearbeitung: Miri Falk (synthetic fixture)</p>
<div class="poem"><p>
  <span style="color:white;font-size:0.1em">[</span><span style="vertical-align:50%;font-family:sans-serif;font-weight:bold">[H]</span><span style="color:white;font-size:0.1em">]</span>Am Morgen glänzt der kupferne Bach.<br>
  Unter sieben Zweigen ruht ein blauer Klang. [Wort] {wörtlich} #Stern<br>
</p><p><span style="vertical-align:50%;font-family:sans-serif;font-weight:bold">[B]</span>Sie tanzen leis am Hang.</p></div>
<div class="poem"><p>Ein kleiner Mond bewacht den Garten.</p></div>
<div class="score"><img alt="Score image must not become lyric text"></div>
<nav>Navigation must not become lyric text</nav>''',
}) => '''
<html><head><title>$title</title></head><body>
  <div id="mw-content-text">
    <div class="mw-parser-output">$body</div>
  </div>
</body></html>''';

Map<String, Object?> _parseResponse({
  int pageId = _pageId,
  String title = _pageTitle,
  int revision = 98765,
  String? html,
  List<String>? categories,
}) => {
  'parse': {
    'pageid': pageId,
    'title': title,
    'revid': revision,
    'displaytitle': title,
    'text': html ?? _pageHtml(),
    'categories': [
      for (final category in categories ?? const [
        'Liederbuch/_Lieder',
        'Liederbuch/_Lieder_auf_Deutsch',
      ])
        {'category': category, 'sortkey': ''},
    ],
    'properties': [],
  },
};

http.Response _json(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ProviderTransport _transport(
  FutureOr<http.Response> Function(http.Request request) handler,
) => ProviderTransport(
  client: MockClient((request) async => await handler(request)),
  maxRetries: 0,
  hostInterval: Duration.zero,
);

void main() {
  test('search stays in the Liederbuch mainspace boundary', () async {
    final seen = <Uri>[];
    final transport = _transport((request) {
      seen.add(request.url);
      return _json({
        'query': {
          'search': [
            _searchHit(),
            _searchHit(pageId: 0),
            _searchHit(namespace: 1),
            _searchHit(title: 'Hilfe: Liederbuch/ Example'),
            _searchHit(title: 'Liederbuch: Morgenwind am Silberhang'),
          ],
        },
      });
    });
    try {
      final provider = WikibooksLiederbuchProvider(transport);
      expect(provider.definition.id, 'wikibooksliederbuch');
      expect(provider.definition.enabledByDefault, isFalse);
      expect(provider.definition.capabilities, containsAll({
        'catalog',
        'lyrics',
        'chords',
        'metadata',
      }));

      final results = await provider.search('Morgenwind am Silberhang');
      expect(results, hasLength(1));
      expect(results.single.id, '$_pageId');
      expect(results.single.providerId, 'wikibooksliederbuch');
      expect(results.single.title, 'Morgenwind am Silberhang');
      expect(results.single.artist, isEmpty);
      expect(results.single.metadata['identityScope'], 'arrangement');
      expect(results.single.metadata['wikibooksPageId'], _pageId);
      expect(results.single.metadata['wikibooksPageTitle'], _pageTitle);
      expect(results.single.url, 'https://de.wikibooks.org/?curid=7123');

      final uri = seen.single;
      expect(uri.scheme, 'https');
      expect(uri.host, 'de.wikibooks.org');
      expect(uri.path, '/w/api.php');
      expect(uri.queryParameters['action'], 'query');
      expect(uri.queryParameters['list'], 'search');
      expect(uri.queryParameters['srnamespace'], '0');
      expect(uri.queryParameters['srlimit'], '10');
      expect(uri.queryParameters['srsearch'], contains('prefix:Liederbuch/'));
      expect(uri.queryParameters['format'], 'json');
      expect(uri.queryParameters['formatversion'], '2');
      expect(uri.queryParameters['maxlag'], '5');
    } finally {
      await transport.close();
    }
  });

  test('parse extracts every poem, inline chords, credits, and literal lyric syntax', () async {
    final seen = <Uri>[];
    final transport = _transport((request) {
      seen.add(request.url);
      if (request.url.queryParameters['action'] == 'query') {
        return _json({'query': {'search': [_searchHit()]}});
      }
      return _json(_parseResponse());
    });
    try {
      final provider = WikibooksLiederbuchProvider(transport);
      final selected = (await provider.search('Morgenwind am Silberhang')).single;
      final forged = SongCandidate(
        providerId: selected.providerId,
        id: selected.id,
        title: selected.title,
        artist: selected.artist,
        url: 'https://evil.example/forged',
        metadata: const {
          'identityScope': 'recording',
          'wikibooksPageId': 999,
          'wikibooksPageTitle': 'Liederbuch/ Forged',
        },
      );
      final result = await provider.resolve(forged);

      expect(result.body, contains('[B]Am Morgen glänzt der kupferne Bach.'));
      expect(result.body, contains(r'Unter sieben Zweigen ruht ein blauer Klang. \[Wort\] \{wörtlich\} \#Stern'));
      expect(result.body, contains('[Bb]Sie tanzen leis am Hang.'));
      expect(result.body, contains('Ein kleiner Mond bewacht den Garten.'));
      expect(result.body, isNot(contains('[unresolved chorus]')));
      expect(result.body, isNot(contains('Score image must not become lyric text')));
      expect(result.body, isNot(contains('Navigation must not become lyric text')));
      expect(plainLyrics(result.body), contains('Unter sieben Zweigen ruht ein blauer Klang. [Wort] {wörtlich} #Stern'));
      expect(result.candidate.id, '$_pageId');
      expect(result.candidate.url, selected.url);
      expect(result.metadata['identityScope'], 'arrangement');
      expect(result.metadata['wikibooksPageId'], _pageId);
      expect(result.metadata['wikibooksPageTitle'], _pageTitle);
      expect(result.metadata['wikibooksRevisionId'], 98765);
      expect(result.metadata['sourceTextCredit'], 'Liora Fen (synthetic fixture)');
      expect(result.metadata['sourceMelodyCredit'], 'K. Tarel (synthetic fixture)');
      expect(result.metadata['sourceArrangerCredits'], ['Miri Falk (synthetic fixture)']);
      expect(result.metadata['language'], 'de');
      expect(result.metadata['sourceChordNotation'], 'german');
      expect(result.attribution, contains(_pageTitle));
      expect(result.attribution, contains('98765'));
      expect(result.timingTracks, isEmpty);
      expect(result.candidate.recordingIds, isEmpty);

      final parseUri = seen.last;
      expect(parseUri.host, 'de.wikibooks.org');
      expect(parseUri.path, '/w/api.php');
      expect(parseUri.queryParameters['action'], 'parse');
      expect(parseUri.queryParameters['pageid'], '$_pageId');
      expect(parseUri.queryParameters['prop'], contains('text'));
      expect(parseUri.queryParameters['prop'], contains('revid'));
      expect(parseUri.queryParameters['prop'], contains('categories'));
      expect(parseUri.queryParameters['prop'], contains('properties'));
      expect(parseUri.queryParameters['prop'], contains('displaytitle'));
      expect(parseUri.queryParameters['page'], isNull);
      expect(parseUri.queryParameters['oldid'], isNull);
      expect(seen.every((uri) => uri.host == 'de.wikibooks.org'), isTrue);
    } finally {
      await transport.close();
    }
  });

  for (final testCase in [
    (
      language: 'Liederbuch/_Lieder_auf_Deutsch',
      source: '<span style="vertical-align:50%;font-family:sans-serif;font-weight:bold">[H]</span>H und <span style="vertical-align:50%;font-family:sans-serif;font-weight:bold">[B]</span>B',
      expected: '[B]H und [Bb]B',
    ),
    (
      language: 'Liederbuch/_Lieder_auf_Englisch',
      source: '<span style="vertical-align:50%;font-family:sans-serif;font-weight:bold">[B]</span>B and <span style="vertical-align:50%;font-family:sans-serif;font-weight:bold">[Bb]</span>B-flat',
      expected: '[B]B and [Bb]B-flat',
    ),
  ]) {
    test('chord letters follow ${testCase.language}', () async {
      final html = _pageHtml(
        body: '<div class="poem"><p>${testCase.source}</p></div>',
      );
      final transport = _transport((request) => request.url.queryParameters['action'] == 'query'
          ? _json({'query': {'search': [_searchHit()]}})
          : _json(_parseResponse(html: html, categories: [
              'Liederbuch/_Lieder',
              testCase.language,
            ])));
      try {
        final provider = WikibooksLiederbuchProvider(transport);
        final selected = (await provider.search('Morgenwind am Silberhang')).single;
        final source = await provider.resolve(selected);
        expect(source.body, contains(testCase.expected));
        expect(source.metadata['sourceChordNotation'],
            testCase.language.endsWith('_Deutsch') ? 'german' : 'international');
        expect(source.metadata['language'],
            testCase.language.endsWith('_Deutsch') ? 'de' : 'en');
      } finally {
        await transport.close();
      }
    });
  }

  test('ambiguous B/H chord notation is rejected rather than guessed', () async {
    final html = _pageHtml(
      body: '''<div class="poem"><p>
<span style="vertical-align:50%;font-family:sans-serif;font-weight:bold">[H]</span>First
<span style="vertical-align:50%;font-family:sans-serif;font-weight:bold">[B]</span>Second
</p></div>''',
    );
    final transport = _transport((request) => request.url.queryParameters['action'] == 'query'
        ? _json({'query': {'search': [_searchHit()]}})
        : _json(_parseResponse(html: html, categories: ['Liederbuch/_Lieder'])));
    try {
      final provider = WikibooksLiederbuchProvider(transport);
      final selected = (await provider.search('Morgenwind am Silberhang')).single;
      await expectLater(
        provider.resolve(selected),
        throwsA(
          isA<ProviderException>().having(
            (error) => error.code,
            'code',
            'unsupported_chord_notation',
          ),
        ),
      );
    } finally {
      await transport.close();
    }
  });

  test('unrecognized chord annotations stay literal and are recorded', () async {
    final html = _pageHtml(
      body: '''<div class="poem"><p>
<span style="vertical-align:50%;font-family:sans-serif;font-weight:bold">[G?]</span>Literal marker
</p></div>''',
    );
    final transport = _transport((request) => request.url.queryParameters['action'] == 'query'
        ? _json({'query': {'search': [_searchHit()]}})
        : _json(_parseResponse(html: html)));
    try {
      final provider = WikibooksLiederbuchProvider(transport);
      final selected = (await provider.search('Morgenwind am Silberhang')).single;
      final source = await provider.resolve(selected);
      expect(source.body, contains(r'\[G?\]Literal marker'));
      expect(jsonEncode(source.extra['unparsedChordAnnotations']), contains('G?'));
    } finally {
      await transport.close();
    }
  });

  test('pages without poem blocks are unavailable', () async {
    final transport = _transport((request) => request.url.queryParameters['action'] == 'query'
        ? _json({'query': {'search': [_searchHit()]}})
        : _json(_parseResponse(html: _pageHtml(body: '<p>Not a poem.</p>'))));
    try {
      final provider = WikibooksLiederbuchProvider(transport);
      final selected = (await provider.search('Morgenwind am Silberhang')).single;
      await expectLater(
        provider.resolve(selected),
        throwsA(
          isA<ProviderException>().having((error) => error.code, 'code', 'unavailable'),
        ),
      );
    } finally {
      await transport.close();
    }
  });

  for (final response in [
    {'parse': {'pageid': _pageId + 1, 'title': _pageTitle, 'revid': 1}},
    {'parse': {'pageid': _pageId, 'title': 'Liederbuch/ Another Song', 'revid': 1}},
    {'parse': {'pageid': _pageId, 'title': _pageTitle, 'revid': 0}},
    {'error': {'code': 'missingtitle', 'info': 'missing page'}},
  ]) {
    test('resolve rejects invalid page identity or missing page: $response', () async {
      final transport = _transport((request) => request.url.queryParameters['action'] == 'query'
          ? _json({'query': {'search': [_searchHit()]}})
          : _json(response));
      try {
        final provider = WikibooksLiederbuchProvider(transport);
        final selected = (await provider.search('Morgenwind am Silberhang')).single;
        await expectLater(provider.resolve(selected), throwsA(isA<ProviderException>()));
      } finally {
        await transport.close();
      }
    });
  }

  test('maxlag becomes provider_busy and pre-cancelled search makes no request', () async {
    var calls = 0;
    final transport = _transport((_) {
      calls++;
      return _json({'error': {'code': 'maxlag', 'info': 'retry later'}});
    });
    try {
      final provider = WikibooksLiederbuchProvider(transport);
      await expectLater(
        provider.search('Morgenwind'),
        throwsA(
          isA<ProviderException>().having((error) => error.code, 'code', 'provider_busy'),
        ),
      );
      expect(calls, 1);
      await expectLater(
        provider.search('Morgenwind'),
        throwsA(
          isA<ProviderException>().having((error) => error.code, 'code', 'provider_busy'),
        ),
      );
      expect(calls, 2);
      final cancelled = CancellationToken()..cancel();
      await expectLater(
        provider.search('Morgenwind', cancel: cancelled),
        throwsA(
          isA<ProviderException>().having((error) => error.code, 'code', 'cancelled'),
        ),
      );
      expect(calls, 2);
    } finally {
      await transport.close();
    }
  });

  test('portable ChordPro keeps source license scope and exact source evidence', () async {
    final transport = _transport((request) => request.url.queryParameters['action'] == 'query'
        ? _json({'query': {'search': [_searchHit()]}})
        : _json(_parseResponse()));
    try {
      final provider = WikibooksLiederbuchProvider(transport);
      final selected = (await provider.search('Morgenwind am Silberhang')).single;
      final source = await provider.resolve(selected);
      final document = SongDocument(
        id: 'wikibooks-portable-test',
        title: selected.title,
        artist: '',
        body: source.body,
        sources: [source],
      );
      final codec = ChordProCodec();
      final reopened = codec.decode(codec.encode(document));
      final retained = reopened.sources.single;
      final rights = retained.extra['rights'] as Map;
      final original = source.extra['originalPayload'] as Map;
      expect(rights['license'], 'unknown');
      expect(rights['licenseUrl'], isNull);
      expect(rights['permissions'], {
        'status': 'field_specific',
        'pageContributions': 'CC-BY-SA-4.0',
        'pageContributionsLicenseUrl': 'https://creativecommons.org/licenses/by-sa/4.0/',
        'underlyingLyricsAndMusic': 'unknown',
      });
      expect(rights['sourceUrl'], 'https://de.wikibooks.org/?curid=7123');
      expect(rights['sourceId'], selected.id);
      expect(rights['evidenceUrl'], contains('oldid=98765'));
      expect(rights['attribution'], source.attribution);
      expect(rights['revision'], 98765);
      expect(retained.extra['originalPayload'], original);
      expect(retained.extra['revision'], '98765');
      final historyUrl = retained.extra['wikibooks']['historyUrl'] as String;
      expect(historyUrl, source.extra['wikibooks']['historyUrl']);
      final history = Uri.parse(historyUrl);
      expect(history.scheme, 'https');
      expect(history.host, 'de.wikibooks.org');
      expect(history.path, '/w/index.php');
      expect(history.queryParameters['action'], 'history');
      expect(history.queryParameters['title'], _pageTitle);
      expect(
        retained.attribution,
        contains('https://creativecommons.org/licenses/by-sa/4.0/'),
      );
      expect(retained.attribution, contains('converted to ChordPro'));
      expect(jsonEncode(retained.extra['wikibooks']), contains('Morgenwind am Silberhang'));
      expect(
        base64Decode(original['base64'] as String),
        utf8.encode(jsonEncode(_parseResponse())),
      );
      expect(retained.metadata, source.metadata);
      expect(retained.body, source.body);
      expect(retained.attribution, source.attribution);
      expect(plainLyrics(retained.body), plainLyrics(source.body));
    } finally {
      await transport.close();
    }
  });

  test('successful search response is cached for fifteen minutes', () async {
    var now = DateTime.utc(2026, 10, 28);
    var calls = 0;
    final transport = _transport((request) {
      calls++;
      return request.url.queryParameters['action'] == 'query'
          ? _json({'query': {'search': [_searchHit()]}})
          : _json(_parseResponse());
    });
    try {
      final provider = WikibooksLiederbuchProvider(
        transport,
        clock: () => now,
      );
      final selected = (await provider.search('Morgenwind')).single;
      await provider.resolve(selected);
      expect((await provider.search('Morgenwind')).single.id, selected.id);
      await provider.resolve(selected);
      expect(calls, 2);
      now = now.add(const Duration(minutes: 16));
      expect(await provider.search('Morgenwind'), hasLength(1));
      expect(calls, 3);
    } finally {
      await transport.close();
    }
  });
}
