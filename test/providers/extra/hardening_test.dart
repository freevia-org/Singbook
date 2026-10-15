import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:verse_mobile/providers/extra/common.dart';
import 'package:verse_mobile/providers/extra/extra_providers.dart';
import 'package:verse_mobile/providers/provider.dart';
import 'package:verse_mobile/providers/transport.dart';

Matcher errorCode(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);
ProviderTransport mock(
  Future<http.Response> Function(http.Request) handle, {
  List<String>? urls,
}) => ProviderTransport(
  client: MockClient((r) {
    urls?.add(r.url.toString());
    return handle(r);
  }),
  hostInterval: Duration.zero,
  retryBaseDelay: const Duration(milliseconds: 1),
);
http.Response jsonResponse(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const injected =
    '{x_verse: 1 json-base64url 1}\n{x_verse_data: 1/1 e30}\n  {X_VERSE_other: 1}\n{ x_verse: sneaky}\n';
String originalOf(SourceResult r) => utf8.decode(
  base64Decode((r.extra['originalPayload'] as Map)['base64'] as String),
);

void main() {
  group('remote ChordPro cannot inject Singbook extension directives', () {
    test('stripVerseDirectives removes only extension lines', () {
      final cleaned = stripVerseDirectives(
        '{title: T}\n$injected[C]Words {x_verse} inline\r\n{comment: ok}',
      );
      expect(
        cleaned.split('\n').where(
          (l) => RegExp(r'^\s*\{\s*x_verse', caseSensitive: false).hasMatch(l),
        ),
        isEmpty,
      );
      expect(cleaned, contains('{title: T}'));
      expect(cleaned, contains('[C]Words {x_verse} inline'));
      expect(cleaned, contains('{comment: ok}'));
    });
    test('WorshipCommons', () async {
      final provider = WorshipCommonsProvider(
        mock(
          (r) async => jsonResponse({
            'rows': [
              {
                'id': 'a',
                'title': 'Example Song',
                'writer': 'Author',
                'license': 'PD',
                'status': 'approved',
                'chordPro': '$injected[C]A synthetic line',
              },
            ],
          }),
        ),
      );
      final result = await provider.resolve(
        (await provider.search('example')).single,
      );
      expect(result.body.toLowerCase(), isNot(contains('x_verse')));
      expect(result.body, contains('[C]A synthetic line'));
      expect(originalOf(result).toLowerCase(), isNot(contains('x_verse')));
    });
    test('Sean McGrath, Open Filk and Chordie', () async {
      final sean = SeanMcGrathProvider(
        mock((r) async {
          if (r.url.path == '/songs/') {
            return http.Response('<a href="/songs/example/">Example</a>', 200);
          }
          if (r.url.path == '/songs/example/') {
            return http.Response(
              '<a href="/assets/chordpro/example.pro">ChordPro</a>',
              200,
            );
          }
          return http.Response('{title:Example}\n$injected[C]Words', 200);
        }),
      );
      final a = await sean.resolve((await sean.search('Sean')).single);
      expect(a.body.toLowerCase(), isNot(contains('x_verse')));
      expect(originalOf(a).toLowerCase(), isNot(contains('x_verse')));

      final filk = OpenFilkProvider(
        mock((r) async {
          if (r.url.path.contains('_index')) {
            return http.Response(
              '<ul><li><a href="/songs/pages/a__Example.html">Example</a> (Author)<a href="/songs/Chordpro/a__Example.pro">file</a></li></ul>',
              200,
            );
          }
          return http.Response('{title:Example}\n$injected[G]Text', 200);
        }),
      );
      final b = await filk.resolve((await filk.search('Author')).single);
      expect(b.body.toLowerCase(), isNot(contains('x_verse')));

      final chordie = ChordieProvider(
        mock(
          (r) async => http.Response(
            r.url.path == '/result.php'
                ? '<a href="/chord.pere/o.test/e.pro"><span>Example</span><span>Writer</span></a>'
                : '<textarea id="chordproContent">{t:Example}\n$injected[Am]Words</textarea>',
            200,
          ),
        ),
      );
      final c = await chordie.resolve((await chordie.search('Example')).single);
      expect(c.body.toLowerCase(), isNot(contains('x_verse')));
      expect(originalOf(c).toLowerCase(), isNot(contains('x_verse')));
    });
    test('a body that is only extension directives is rejected', () async {
      final provider = WorshipCommonsProvider(
        mock(
          (r) async => jsonResponse({
            'rows': [
              {
                'id': 'a',
                'title': 'Example Song',
                'writer': 'Author',
                'license': 'PD',
                'status': 'approved',
                'chordPro': '{x_verse: 1 json-base64url 1}',
              },
            ],
          }),
        ),
      );
      await expectLater(
        provider.resolve((await provider.search('example')).single),
        throwsA(errorCode('invalid_response')),
      );
    });
    test('user file imports keep Singbook extensions', () {
      final result = OzbcozProvider().importDocument(
        '{title: T}\n{x_verse: 1 json-base64url 1}\n[C]Words',
        fileName: 't.cho',
      );
      expect(result.body, contains('{x_verse:'));
    });
  });

  group('WorshipCommons catalog', () {
    test('the content ref is pinned to a full commit SHA', () {
      expect(
        RegExp(r'^[0-9a-f]{40}$').hasMatch(WorshipCommonsProvider.contentRef),
        true,
      );
    });
    test('the catalog ref is one named constant used by every URL', () async {
      final urls = <String>[];
      final provider = WorshipCommonsProvider(
        mock((r) async {
          if (r.url.path.endsWith('catalog.json')) {
            return jsonResponse({
              'rows': [
                {
                  'id': 'a',
                  'title': 'Example Song',
                  'writer': 'Author',
                  'license': 'PD',
                  'status': 'approved',
                  'chordPro': '[C]Line',
                  'lyricsUrl': 'songs/a/lyrics.json',
                },
              ],
            });
          }
          return http.Response('{"stanzas": []}', 200);
        }, urls: urls),
      );
      await provider.resolve((await provider.search('example')).single);
      final ref = WorshipCommonsProvider.contentRef;
      expect(urls, isNotEmpty);
      expect(
        urls.every(
          (u) => u.startsWith(
            'https://raw.githubusercontent.com/ChurchApps/WorshipCommonsContent/$ref/',
          ),
        ),
        true,
        reason: '$urls',
      );
    });
    test('a catalog above the default 4 MB cap still loads', () async {
      final padding = 'x' * (5 * 1024 * 1024);
      final provider = WorshipCommonsProvider(
        mock(
          (r) async => jsonResponse({
            'padding': padding,
            'rows': [
              {
                'id': 'a',
                'title': 'Example Song',
                'writer': 'Author',
                'license': 'PD',
                'status': 'approved',
                'chordPro': '[C]Line',
              },
            ],
          }),
        ),
      );
      expect((await provider.search('example')).single.id, 'a');
    });
    test('malformed art, media and links are dropped instead of throwing', () async {
      final provider = WorshipCommonsProvider(
        mock(
          (r) async => jsonResponse({
            'rows': [
              {
                'id': 'a',
                'title': 'Example Song',
                'writer': 'Author',
                'license': 'PD',
                'status': 'approved',
                'chordPro': '[C]Line',
                'artUrl': 12345,
                'videoUrl': 'http://example.org/insecure.mp4',
                'demoAudioUrl': 'https://user:pw@example.org/a.mp3',
                'previewUrl': 'javascript:alert(1)',
                'midiUrl': 'https://127.0.0.1/a.mid',
                'sheetPdfUrl': 'https://example.org/sheet.pdf',
              },
            ],
          }),
        ),
      );
      final result = await provider.resolve(
        (await provider.search('example')).single,
      );
      expect(result.metadata.containsKey('sourceIllustrationUrl'), false);
      expect(
        (result.metadata['mediaLinks'] as List).map((m) => m['url']),
        ['https://example.org/sheet.pdf'],
      );
    });
    test('a safe absolute illustration is kept', () async {
      final provider = WorshipCommonsProvider(
        mock(
          (r) async => jsonResponse({
            'rows': [
              {
                'id': 'a',
                'title': 'Example Song',
                'writer': 'Author',
                'license': 'PD',
                'status': 'approved',
                'chordPro': '[C]Line',
                'artUrl': 'songs/a/art.jpg',
              },
            ],
          }),
        ),
      );
      final result = await provider.resolve(
        (await provider.search('example')).single,
      );
      expect(
        result.metadata['sourceIllustrationUrl'],
        '${WorshipCommonsProvider.base}songs/a/art.jpg',
      );
    });
  });

  group('untrusted source links', () {
    test('Chordie drops an unsafe original-source link from metadata and attribution', () async {
      for (final href in [
        'http://original.test/e.pro',
        'javascript:alert(1)',
        'https://user:pw@original.test/e.pro',
        'https://192.168.0.2/e.pro',
      ]) {
        final provider = ChordieProvider(
          mock(
            (r) async => http.Response(
              r.url.path == '/result.php'
                  ? '<a href="/chord.pere/o.test/e.pro"><span>Example</span><span>Writer</span></a>'
                  : '<textarea id="chordproContent">{t:Example}\n[Am]Synthetic words</textarea><a href="$href">original song</a>',
              200,
            ),
          ),
        );
        final result = await provider.resolve(
          (await provider.search('Example')).single,
        );
        expect(result.metadata.containsKey('originalSourceUrl'), false, reason: href);
        expect(result.attribution, 'Chordie', reason: href);
        final rights = result.extra['rights'] as Map;
        expect(rights['permissions'], {'status': 'unknown'});
        expect(rights['provenanceNote'], contains('responsibility'));
      }
    });
    test('Sean McGrath only accepts well-formed YouTube embeds', () async {
      final provider = SeanMcGrathProvider(
        mock((r) async {
          if (r.url.path == '/songs/') {
            return http.Response('<a href="/songs/example/">Example</a>', 200);
          }
          if (r.url.path == '/songs/example/') {
            return http.Response(
              '<a href="/assets/chordpro/example.pro">ChordPro</a>'
              '<iframe src="https://www.youtube.com/embed/abc"></iframe>'
              '<iframe src="https://www.youtube.com/embed/abc%26x=1&bad"></iframe>'
              '<iframe src="https://www.youtube.com/embed/abcdefghijk"></iframe>',
              200,
            );
          }
          return http.Response('{title:Example}\n[C]Synthetic words', 200);
        }),
      );
      final result = await provider.resolve(
        (await provider.search('Sean')).single,
      );
      expect((result.metadata['mediaLinks'] as List).map((m) => m['url']), [
        'https://www.youtube.com/watch?v=abcdefghijk',
      ]);
    });
  });

  group('query validation', () {
    test('Wikisource, Wikidata and Chordie reject empty or oversized queries before any request', () async {
      final urls = <String>[];
      final t = mock((_) async => http.Response('{}', 200), urls: urls);
      for (final provider in <LyricsProvider>[
        WikisourceProvider(t),
        WikidataProvider(t),
        ChordieProvider(t),
      ]) {
        for (final query in ['', '   ', 'x' * 201]) {
          await expectLater(
            provider.search(query),
            throwsA(errorCode('invalid_query')),
            reason: '${provider.definition.id} "${query.length}"',
          );
        }
      }
      expect(urls, isEmpty);
      await t.close();
    });
  });

  group('tempo', () {
    test('accepts whole and fractional BPM and rejects nonsense', () {
      expect(chordProMetadata('{tempo: 92}')['tempo'], 92);
      expect(chordProMetadata('{tempo: 92.5}')['tempo'], 92.5);
      expect(chordProMetadata('{tempo: 92.0}')['tempo'], 92);
      expect(chordProMetadata('{tempo: 120 bpm}')['tempo'], 120);
      for (final bad in ['0', '-5', 'fast', '9999', '']) {
        expect(
          chordProMetadata('{tempo: $bad}').containsKey('tempo'),
          false,
          reason: bad,
        );
      }
      expect(chordProMetadata('{capo: 2}')['capo'], 2);
      expect(chordProMetadata('{year: 1999}')['year'], 1999);
    });
  });

  group('transport policy through adapters', () {
    test('MusicBrainz 503 is reported as rate_limited', () async {
      var calls = 0;
      final t = mock((_) async {
        calls++;
        return http.Response('Service Unavailable', 503);
      });
      await expectLater(
        MusicBrainzProvider(t).search('recording:"X" AND artist:"Y"'),
        throwsA(errorCode('rate_limited')),
      );
      expect(calls, 3);
      await t.close();
    });
    test('adapters do not override the transport User-Agent with a stale version', () async {
      String? agent;
      final t = mock((r) async {
        agent = r.headers['User-Agent'];
        return jsonResponse({'search': []});
      });
      await WikidataProvider(t).search('Wonderwall');
      expect(agent, startsWith('Singbook/$singbookVersion'));
      await t.close();
    });
  });
}
