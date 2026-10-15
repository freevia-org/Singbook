import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/transport.dart';

ProviderTransport mockTransport(
  Future<http.Response> Function(http.Request) handle,
) => ProviderTransport(client: MockClient(handle), hostInterval: Duration.zero);
http.Response jsonResponse(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'extra roster distinguishes imports, catalogs, and identity-bound artwork',
    () {
      final providers = createExtraProviders();
      expect(providers.length, 10);
      expect(providers.map((p) => p.definition.id).toSet().length, 10);
      expect(
        providers.whereType<FileImportProvider>().map((p) => p.definition.id),
        ['ozbcoz', 'worshiptogether'],
      );
      expect(
        providers
            .singleWhere((p) => p.definition.id == 'wikimediacommons')
            .definition
            .capabilities
            .contains('catalog'),
        false,
      );
    },
  );
  test(
    'user-selected file import preserves attribution, raw document and unknown rights',
    () {
      const text =
          '{title: Example}\n{artist: Writer}\n{capo: 0}\n[C]Synthetic line';
      final result = OzbcozProvider().importDocument(
        text,
        fileName: 'example.cho',
      );
      expect(result.body, text);
      expect(result.candidate.title, 'Example');
      expect(result.metadata['capo'], 0);
      expect(result.extra['userSelectedImport'], true);
      expect(result.extra['rights']['permissions']['status'], 'unknown');
      expect(
        utf8.decode(base64Decode(result.extra['originalPayload']['base64'])),
        text,
      );
    },
  );
  test(
    'import-only adapter never presents empty success as online lookup',
    () async {
      await expectLater(
        WorshipTogetherProvider().search('Example'),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'file_import_required',
          ),
        ),
      );
    },
  );
  test(
    'WorshipCommons excludes custom restricted licenses and uses actual sheet metadata',
    () async {
      final provider = WorshipCommonsProvider(
        mockTransport(
          (r) async => jsonResponse({
            'rows': [
              {
                'id': 'open',
                'title': 'Example Song',
                'writer': 'Author',
                'license': 'PD',
                'status': 'approved',
                'songKey': 'C',
                'bpm': 80,
                'chordPro': '[C]A synthetic line',
              },
              {
                'id': 'restricted',
                'title': 'Example Other',
                'writer': 'Author',
                'license': 'WC',
                'status': 'approved',
                'chordPro': 'Other',
              },
              {
                'id': 'pending',
                'title': 'Example Pending',
                'writer': 'Author',
                'license': 'CC-BY',
                'status': 'pending',
                'chordPro': 'Other',
              },
            ],
          }),
        ),
      );
      final rows = await provider.search('example');
      expect(rows.map((r) => r.id), ['open']);
      final result = await provider.resolve(rows.single);
      expect(result.metadata['key'], 'C');
      expect(result.metadata['tempo'], 80);
      expect(result.hasChords, true);
      expect(result.extra['rights']['license'], 'PD');
    },
  );
  test(
    'WorshipCommons does not attribute composer sheet to an unrelated performer',
    () async {
      final provider = WorshipCommonsProvider(
        mockTransport(
          (r) async => jsonResponse({
            'rows': [
              {
                'id': 'one',
                'title': 'Example',
                'writer': 'Original Author',
                'license': 'PD',
                'status': 'approved',
                'chordPro': 'text',
              },
            ],
          }),
        ),
      );
      await expectLater(
        provider.resolve(
          const SongCandidate(
            providerId: 'genius',
            id: '9',
            title: 'Example',
            artist: 'Different Singer',
          ),
        ),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'unavailable'),
        ),
      );
    },
  );
  test(
    'Worship timing retains word ends, original JSON and unverified recording',
    () {
      final raw = jsonEncode({
        'duration': 10,
        'stanzas': [
          {
            'label': 'Verse',
            'lines': [
              [
                {'t': 1.125, 'd': 0.5, 'text': 'Hello'},
                {'t': 2, 'd': 1, 'text': 'world'},
              ],
              [
                {'t': 5, 'd': 0.7, 'text': 'Again'},
              ],
            ],
          },
        ],
      });
      final track = parseWorshipTiming(raw, 'wc:one');
      expect(track.raw, raw);
      expect(track.cues.length, 3);
      expect(track.cues.first.startUs, 1125000);
      expect(track.cues.first.endUs, 1625000);
      expect(track.cues[1].graphemeStart, 6);
      expect(track.sourceLyrics, 'Hello world\nAgain');
      expect(track.recordingId, isNull);
      expect(track.status, TimingStatus.unverified);
    },
  );
  test('invalid timing stays retained without partially activating cues', () {
    const raw =
        '{"stanzas":[{"lines":[[{"t":2,"text":"ok"},{"t":-1,"text":"bad"}]]}]}';
    final track = parseWorshipTiming(raw, 'wc:one');
    expect(track.raw, raw);
    expect(track.status, TimingStatus.invalid);
    expect(track.cues, isEmpty);
  });
  test(
    'Sean catalog includes only original song paths and resolves explicit ChordPro',
    () async {
      final provider = SeanMcGrathProvider(
        mockTransport((r) async {
          if (r.url.path == '/songs/') {
            return http.Response(
              '<a href="/songs/example/">Example</a><a href="/covers/cover/">Cover</a>',
              200,
            );
          }
          if (r.url.path == '/songs/example/') {
            return http.Response(
              '<a href="/assets/chordpro/example.pro">ChordPro</a><iframe src="https://www.youtube.com/embed/abcdefghijk"></iframe>',
              200,
            );
          }
          if (r.url.path == '/assets/chordpro/example.pro') {
            return http.Response('{title:Example}\n[C]Synthetic words', 200);
          }
          throw StateError('Unexpected request');
        }),
      );
      final rows = await provider.search('Sean');
      expect(rows.length, 1);
      final result = await provider.resolve(rows.single);
      expect(result.hasChords, true);
      expect(result.extra['rights']['license'], 'CC BY 4.0');
      expect(
        result.metadata['mediaLinks'][0]['url'],
        'https://www.youtube.com/watch?v=abcdefghijk',
      );
    },
  );
  test(
    'Sean never resolves covers through an injected same-host URL',
    () async {
      final provider = SeanMcGrathProvider(
        mockTransport((_) async => throw StateError('Must not fetch')),
      );
      await expectLater(
        provider.resolve(
          const SongCandidate(
            providerId: 'seanmcgrathmusic',
            id: 'cover',
            title: 'Cover',
            artist: 'Sean McGrath',
            url: 'https://seanmcgrathmusic.com/covers/cover/',
          ),
        ),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'invalid_url'),
        ),
      );
    },
  );
  test('Open Filk retains exact license line and source recording link', () async {
    final provider = OpenFilkProvider(
      mockTransport((r) async {
        if (r.url.path.contains('_index')) {
          return http.Response(
            '<ul><li><a href="/songs/pages/author__Example.html">Example</a> (Author)<a href="/songs/Chordpro/author__Example.pro">file</a><a href="https://example.org/recording">recording</a></li></ul>',
            200,
          );
        }
        return http.Response(
          '{title:Example}\n{c:License (Lyrics): Filksongbook Minimal License V1.0}\n[G]Example text',
          200,
        );
      }),
    );
    final rows = await provider.search('Author');
    expect(rows.single.artist, 'Author');
    final result = await provider.resolve(rows.single);
    expect(result.extra['rights']['license'], contains('Minimal License'));
    expect(
      result.extra['rights']['permissions']['redistribute'],
      'see_original_license',
    );
    expect(
      result.metadata['mediaLinks'][0]['url'],
      'https://example.org/recording',
    );
  });
  test(
    'Chordie extracts selected chart and preserves original host attribution',
    () async {
      final provider = ChordieProvider(
        mockTransport(
          (r) async => http.Response(
            r.url.path == '/result.php'
                ? '<a href="/chord.pere/original.test/example.pro"><span>Example</span><span>Writer</span></a>'
                : '<textarea id="chordproContent">{t:Example}\n{key:Am}\n[Am]Synthetic words</textarea><a href="https://original.test/example.pro">original song</a>',
            200,
          ),
        ),
      );
      final rows = await provider.search('Example Writer');
      final result = await provider.resolve(rows.single);
      expect(result.metadata['key'], 'Am');
      expect(
        result.extra['originalSourceUrl'],
        'https://original.test/example.pro',
      );
      expect(result.hasChords, true);
    },
  );
  test('Chordie rejects wrong title in returned chart', () async {
    final provider = ChordieProvider(
      mockTransport(
        (_) async => http.Response(
          '<textarea id="chordproContent">{t:Wrong}\n[C]Other lyrics</textarea>',
          200,
        ),
      ),
    );
    await expectLater(
      provider.resolve(
        const SongCandidate(
          providerId: 'chordie',
          id: 'x',
          title: 'Expected',
          artist: 'Writer',
          url: 'https://www.chordie.com/chord.pere/example.test/a.pro',
        ),
      ),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.code,
          'code',
          'identity_mismatch',
        ),
      ),
    );
  });
  test(
    'MusicBrainz retains releases separately instead of choosing arbitrary album',
    () async {
      final provider = MusicBrainzProvider(
        mockTransport(
          (_) async => jsonResponse({
            'id': '12345678-1234-1234-1234-123456789abc',
            'title': 'Example',
            'length': 181000,
            'artist-credit': [
              {
                'name': 'Artist',
                'artist': {'id': 'artist-id'},
              },
            ],
            'releases': [
              {'id': 'a', 'title': 'First'},
              {'id': 'b', 'title': 'Second'},
            ],
            'isrcs': ['XX1234567890'],
          }),
        ),
      );
      final result = await provider.resolve(
        const SongCandidate(
          providerId: 'musicbrainz',
          id: '12345678-1234-1234-1234-123456789abc',
          title: 'Example',
          artist: 'Artist',
        ),
      );
      expect(result.candidate.album, isNull);
      expect(result.metadata['durationSeconds'], 181);
      expect(result.metadata['releases'], hasLength(2));
      expect(result.body, isEmpty);
      expect(result.extra['metadataOnly'], true);
    },
  );
  test(
    'Wikidata keeps composition dates distinct from recording dates',
    () async {
      JsonMap claim(dynamic v) => {
        'mainsnak': {
          'datavalue': {'value': v},
        },
      };
      final provider = WikidataProvider(
        mockTransport((r) async {
          if (r.url.queryParameters['ids'] == 'Q1') {
            return jsonResponse({
              'entities': {
                'Q1': {
                  'labels': {
                    'en': {'value': 'Example'},
                  },
                  'claims': {
                    'P175': [
                      claim({'id': 'Q2'}),
                    ],
                    'P577': [
                      claim({'time': '+1900-01-01T00:00:00Z', 'precision': 9}),
                    ],
                    'P18': [claim('Exact image.jpg')],
                  },
                },
              },
            });
          }
          return jsonResponse({
            'entities': {
              'Q2': {
                'labels': {
                  'en': {'value': 'Artist'},
                },
              },
            },
          });
        }),
      );
      final result = await provider.resolve(
        const SongCandidate(
          providerId: 'wikidata',
          id: 'Q1',
          title: 'Example',
          artist: '',
        ),
      );
      expect(result.candidate.artist, 'Artist');
      expect(result.metadata['identityScope'], 'composition');
      expect(result.metadata.containsKey('releaseDate'), false);
      expect(result.metadata['wikimediaCommonsFile'], 'Exact image.jpg');
    },
  );
  test('Commons never searches arbitrary song text for an image', () async {
    final provider = WikimediaCommonsProvider(
      mockTransport((_) async => throw StateError('Must not fetch')),
    );
    expect(await provider.search('Example Song'), isEmpty);
    await expectLater(
      provider.resolve(
        const SongCandidate(
          providerId: 'genius',
          id: '1',
          title: 'Example',
          artist: 'Artist',
        ),
      ),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.code,
          'code',
          'identity_required',
        ),
      ),
    );
  });
  test(
    'Commons retains author and license only for approved exact-file assets',
    () async {
      final provider = WikimediaCommonsProvider(
        mockTransport(
          (_) async => jsonResponse({
            'query': {
              'pages': [
                {
                  'imageinfo': [
                    {
                      'url': 'https://upload.wikimedia.org/example.jpg',
                      'descriptionurl':
                          'https://commons.wikimedia.org/wiki/File:Example.jpg',
                      'mime': 'image/jpeg',
                      'extmetadata': {
                        'LicenseShortName': {'value': 'CC BY-SA 4.0'},
                        'LicenseUrl': {
                          'value':
                              'https://creativecommons.org/licenses/by-sa/4.0/',
                        },
                        'Artist': {'value': '<a>Photographer</a>'},
                      },
                    },
                  ],
                },
              ],
            },
          }),
        ),
      );
      final result = await provider.resolve(
        const SongCandidate(
          providerId: 'wikidata',
          id: 'Q1',
          title: 'Example',
          artist: 'Artist',
          metadata: {'wikimediaCommonsFile': 'Example.jpg'},
        ),
      );
      expect(result.metadata['licensedImages'][0]['author'], 'Photographer');
      expect(result.metadata.containsKey('artworkUrl'), false);
      expect(result.extra['rights']['permissions']['shareAlike'], true);
    },
  );
  test(
    'Wikisource requires selected work and never substitutes a text by title alone',
    () async {
      final provider = WikisourceProvider(
        mockTransport((_) async => throw StateError('Must not fetch')),
      );
      await expectLater(
        provider.resolve(
          const SongCandidate(
            providerId: 'genius',
            id: '1',
            title: 'Old song',
            artist: 'Singer',
          ),
        ),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'user_selection_required',
          ),
        ),
      );
    },
  );
  test(
    'Wikisource excludes prose chrome and retains selected text revision/license',
    () async {
      final provider = WikisourceProvider(
        mockTransport(
          (_) async => jsonResponse({
            'parse': {
              'title': 'Old Song',
              'revid': 7,
              'templates': [
                {'title': 'Template:PD-old'},
              ],
              'text':
                  '<h1>Navigation</h1><a href="/wiki/Author:Writer">Writer</a><div class="poem">First line<br>Second line</div>',
            },
          }),
        ),
      );
      final result = await provider.resolve(
        const SongCandidate(
          providerId: 'wikisource',
          id: '12',
          title: 'Old Song',
          artist: '',
        ),
      );
      expect(result.body, 'First line\nSecond line');
      expect(result.candidate.artist, 'Writer');
      expect(result.extra['revision'], '7');
      expect(result.extra['rights']['license'], 'Template:PD-old');
    },
  );
}
