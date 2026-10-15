import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';

Matcher errorCode(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);
ProviderTransport mock(Future<http.Response> Function(http.Request) handle) =>
    ProviderTransport(
      client: MockClient(handle),
      hostInterval: Duration.zero,
      retryBaseDelay: const Duration(milliseconds: 1),
    );
http.Response jsonResponse(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const maxlag = {
  'error': {'code': 'maxlag', 'info': 'Waiting for a database server'},
};

const wikisourceCandidate = SongCandidate(
  providerId: 'wikisource',
  id: '12',
  title: 'Old Song',
  artist: '',
);

Map<String, dynamic> wikisourceParse(String poem) => {
  'parse': {
    'title': 'Old Song',
    'revid': 7,
    'templates': [
      {'title': 'Template:PD-old'},
    ],
    'text': '<a href="/wiki/Author:Writer">Writer</a><div class="poem">$poem</div>',
  },
};

Map<String, dynamic> commonsFile({
  String? licenseUrl = 'https://creativecommons.org/licenses/by-sa/4.0/',
  String url = 'https://upload.wikimedia.org/example.jpg',
}) => {
  'query': {
    'pages': [
      {
        'imageinfo': [
          {
            'url': url,
            'descriptionurl':
                'https://commons.wikimedia.org/wiki/File:Example.jpg',
            'mime': 'image/jpeg',
            'extmetadata': {
              'LicenseShortName': {'value': 'CC BY-SA 4.0'},
              'LicenseUrl': {'value': ?licenseUrl},
              'Artist': {'value': 'Photographer'},
            },
          },
        ],
      },
    ],
  },
};

const commonsCandidate = SongCandidate(
  providerId: 'wikidata',
  id: 'Q1',
  title: 'Example',
  artist: 'Artist',
  metadata: {'wikimediaCommonsFile': 'Example.jpg'},
);

void main() {
  group('Wikisource', () {
    test('poem text cannot inject directives, forged titles or chords', () async {
      final provider = WikisourceProvider(
        mock(
          (_) async => jsonResponse(
            wikisourceParse(
              '{x_verse: 1 json-base64url 1}<br>{x_verse_data: 1/1 e30}<br>'
              '{title: Forged}<br>[Chorus]<br>Roses [C] are red<br>Back\\slash',
            ),
          ),
        ),
      );
      final result = await provider.resolve(wikisourceCandidate);
      expect(result.body, isNot(contains('x_verse')));
      expect(RegExp(r'(?<!\\)\{title').hasMatch(result.body), false);
      expect(result.body, contains(r'\{title: Forged\}'));
      expect(result.body, contains('{comment: Chorus}'));
      expect(result.body, contains(r'Roses \[C\] are red'));
      expect(result.body, contains(r'Back\\slash'));
      expect(result.hasChords, false);
    });

    test('a poem made only of directives is rejected', () async {
      final provider = WikisourceProvider(
        mock(
          (_) async => jsonResponse(
            wikisourceParse('{x_verse: 1 json-base64url 1}'),
          ),
        ),
      );
      await expectLater(
        provider.resolve(wikisourceCandidate),
        throwsA(errorCode('invalid_response')),
      );
    });

    test('deeply nested markup is a typed extraction failure', () async {
      final provider = WikisourceProvider(
        mock(
          (_) async => jsonResponse(
            wikisourceParse('${'<span>' * 20000}deep text'),
          ),
        ),
      );
      await expectLater(
        provider.resolve(wikisourceCandidate),
        throwsA(errorCode('extraction_failed')),
      );
    });

    test('maxlag is a retryable busy failure for search and resolve', () async {
      final provider = WikisourceProvider(mock((_) async => jsonResponse(maxlag)));
      await expectLater(
        provider.search('rose'),
        throwsA(errorCode('provider_busy')),
      );
      await expectLater(
        provider.resolve(wikisourceCandidate),
        throwsA(errorCode('provider_busy')),
      );
    });

    test('other API errors stay "unavailable"', () async {
      final provider = WikisourceProvider(
        mock(
          (_) async => jsonResponse({
            'error': {'code': 'missingtitle'},
          }),
        ),
      );
      await expectLater(
        provider.search('rose'),
        throwsA(errorCode('unavailable')),
      );
    });
  });

  group('Wikimedia Commons', () {
    test('maxlag is provider_busy, not "no artwork"', () async {
      final provider = WikimediaCommonsProvider(
        mock((_) async => jsonResponse(maxlag)),
      );
      await expectLater(
        provider.resolve(commonsCandidate),
        throwsA(errorCode('provider_busy')),
      );
    });

    test('licenseUrl must be a known https host; image host is restricted', () async {
      final bad = await WikimediaCommonsProvider(
        mock(
          (_) async => jsonResponse(
            commonsFile(licenseUrl: 'javascript:alert(1)'),
          ),
        ),
      ).resolve(commonsCandidate);
      expect(bad.extra['rights'].containsKey('licenseUrl'), false);
      expect(bad.metadata['licensedImages'][0].containsKey('licenseUrl'), false);
      final tracker = await WikimediaCommonsProvider(
        mock(
          (_) async => jsonResponse(
            commonsFile(licenseUrl: 'http://tracker.example/l'),
          ),
        ),
      ).resolve(commonsCandidate);
      expect(tracker.extra['rights'].containsKey('licenseUrl'), false);
      final good = await WikimediaCommonsProvider(
        mock((_) async => jsonResponse(commonsFile())),
      ).resolve(commonsCandidate);
      expect(
        good.extra['rights']['licenseUrl'],
        'https://creativecommons.org/licenses/by-sa/4.0/',
      );
      await expectLater(
        WikimediaCommonsProvider(
          mock(
            (_) async => jsonResponse(
              commonsFile(url: 'https://images.example.org/x.jpg'),
            ),
          ),
        ).resolve(commonsCandidate),
        throwsA(errorCode('invalid_response')),
      );
    });
  });

  group('metadata from extra providers is bounded', () {
    test('WorshipCommons rows: wrong types and huge values are normalised', () async {
      final rlo = String.fromCharCode(0x202e);
      final provider = WorshipCommonsProvider(
        mock(
          (_) async => jsonResponse({
            'rows': [
              {
                'id': 42,
                'title': 'Example${rlo}Song',
                'writer': 'Author',
                'license': 'PD',
                'status': 'approved',
                'bpm': 'fast',
                'songKey': 'C' * 5000,
                'themes': {
                  'a': {
                    'b': {
                      'c': {
                        'd': {
                          'e': {
                            'f': {'g': 'deep'},
                          },
                        },
                      },
                    },
                  },
                },
                'scripture': List.generate(500, (i) => 'Psalm $i'),
                'videoUrl': 'https://www.youtube.com/watch?v=abcdefghijk',
                'chordPro': '{capo: 999999}\n{year: 3}\n[C]A synthetic line',
              },
              {
                'id': '',
                'title': 'No Id',
                'license': 'PD',
                'status': 'approved',
                'chordPro': 'x',
              },
              {
                'id': 'notitle',
                'title': '  ',
                'license': 'PD',
                'status': 'approved',
                'chordPro': 'x',
              },
            ],
          }),
        ),
      );
      final rows = await provider.search('example');
      expect(rows.single.id, '42');
      expect(rows.single.title, 'Example${rlo}Song'.replaceAll(rlo, ''));
      final result = await provider.resolve(rows.single);
      final meta = result.metadata;
      expect(meta.containsKey('tempo'), false);
      expect(meta.containsKey('capo'), false);
      expect(meta.containsKey('year'), false);
      expect((meta['key'] as String).length, lessThanOrEqualTo(500));
      expect((meta['scripture'] as List).length, 30);
      expect(jsonEncode(meta['themes']), isNot(contains('deep')));
      final link = (meta['mediaLinks'] as List).single as Map;
      expect(link['kind'], 'videoUrl');
      expect(link.containsKey('type'), false);
    });

    test('MusicBrainz releases and relations are capped', () async {
      const id = '11111111-2222-3333-4444-555555555555';
      final provider = MusicBrainzProvider(
        mock(
          (_) async => jsonResponse({
            'id': id,
            'title': 'Example',
            'length': 180000,
            'artist-credit': [
              {'name': 'Artist'},
            ],
            'releases': List.generate(
              300,
              (i) => {'id': 'r$i', 'title': 'Album $i'},
            ),
            'isrcs': List.generate(300, (i) => 'ISRC$i'),
            'relations': List.generate(300, (i) => {'type': 'url', 'id': '$i'}),
          }),
        ),
      );
      final result = await provider.resolve(
        const SongCandidate(
          providerId: 'musicbrainz',
          id: id,
          title: 'Example',
          artist: 'Artist',
        ),
      );
      expect((result.metadata['releases'] as List).length, 30);
      expect((result.metadata['relationships'] as List).length, 30);
      expect((result.metadata['isrcs'] as List).length, 30);
    });

    test('Sean McGrath keeps the first title and refuses http links', () async {
      final provider = SeanMcGrathProvider(
        mock(
          (_) async => http.Response(
            '<a href="/songs/example/">Example</a>'
            '<a href="/songs/example/">Read more</a>'
            '<a href="http://seanmcgrathmusic.com/songs/plain/">Plain</a>',
            200,
          ),
        ),
      );
      final rows = await provider.search('example');
      expect(rows.single.title, 'Example');
      expect(await provider.search('plain'), isEmpty);
    });

    test('Open Filk does not invent a license for a file without one', () async {
      final provider = OpenFilkProvider(
        mock((r) async {
          if (r.url.path.contains('_index')) {
            return http.Response(
              '<ul><li><a href="/songs/pages/a__Example.html">Example</a> (Author)<a href="/songs/Chordpro/a__Example.pro">file</a></li></ul>',
              200,
            );
          }
          return http.Response('{title:Example}\n[G]Example text', 200);
        }),
      );
      final rows = await provider.search('Author');
      final result = await provider.resolve(rows.single);
      expect(result.extra['rights'].containsKey('license'), false);
      expect(result.extra['rights']['permissions']['status'], 'unknown');
      expect(result.extra['rights']['provenanceNote'], contains('default'));
    });
  });
}
