import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';

SourceCatalogEntry entry({
  required String searchResponse,
  required JsonMap searchFields,
  required String resolveResponse,
  required JsonMap resolveFields,
  String? itemsPath,
  String? itemSelector,
  String? rootPath,
  String bodyFormat = 'plain',
  List<String> capabilities = const ['lyrics'],
  String searchUrl = 'https://lyrics.example.com/search?q={query}',
  String resolveUrl = 'https://lyrics.example.com/song/{id}',
}) => SourceCatalogEntry.fromJson({
  'id': 'catalog_test',
  'name': 'Catalog test',
  'adapter': 'json',
  'status': 'active',
  'revision': 7,
  'capabilities': capabilities,
  'enabledByDefault': true,
  'accessMode': 'public',
  'attribution': 'Catalog test source',
  'website': 'https://lyrics.example.com',
  'hosts': ['lyrics.example.com'],
  'extraction': {
    'search': {
      'url': searchUrl,
      'response': searchResponse,
      ...?_optionalEntry('itemsPath', itemsPath),
      ...?_optionalEntry('itemSelector', itemSelector),
      'fields': searchFields,
    },
    'resolve': {
      'url': resolveUrl,
      'response': resolveResponse,
      ...?_optionalEntry('rootPath', rootPath),
      'fields': resolveFields,
    },
    'bodyFormat': bodyFormat,
  },
});

ProviderTransport transport(
  Future<http.Response> Function(http.Request) respond,
) => ProviderTransport(
  client: MockClient(respond),
  hostInterval: Duration.zero,
  maxRetries: 0,
);

Matcher code(String value) =>
    isA<ProviderException>().having((e) => e.code, 'code', value);

Map<String, Object?>? _optionalEntry(String key, Object? value) =>
    value == null ? null : {key: value};

void main() {
  test(
    'extracts JSON search and resolve fields and preserves source metadata',
    () async {
      final source = entry(
        searchResponse: 'json',
        itemsPath: 'results',
        searchFields: {
          'id': 'id',
          'title': 'song.title',
          'artist': 'song.artist',
          'url': 'page',
          'album': 'song.album',
          'durationSeconds': 'length',
        },
        resolveResponse: 'json',
        rootPath: 'song',
        resolveFields: {
          'body': 'lyrics',
          'title': 'title',
          'artist': 'artist',
          'album': 'album',
        },
      );
      final seen = <String>[];
      final provider = ConfigurableProvider(
        source,
        transport((request) async {
          seen.add(request.url.toString());
          if (request.url.path == '/search') {
            return http.Response(
              jsonEncode({
                'results': [
                  {
                    'id': 'song/42',
                    'song': {
                      'title': 'A Song',
                      'artist': 'The Band',
                      'album': 'First',
                    },
                    'page': 'https://lyrics.example.com/song/42',
                    'length': 201,
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'song': {
                'title': 'A Song',
                'artist': 'The Band',
                'album': 'First',
                'lyrics': 'First line\nSecond line',
              },
            }),
            200,
          );
        }),
      );

      final songs = await provider.search('A Song/The Band');
      expect(songs, hasLength(1));
      expect(songs.single.id, 'song/42');
      expect(songs.single.durationSeconds, 201);
      expect(Uri.parse(seen.first).queryParameters['q'], 'A Song/The Band');
      final result = await provider.resolve(songs.single);
      expect(result.body, contains('First line'));
      expect(result.candidate.title, songs.single.title);
      expect(result.matchKind, MatchKind.unverified);
      expect(result.extra['extractionRevision'], 7);
      expect(result.extra['rights']['status'], 'unknown');
      expect(result.attribution, 'Catalog test source');
      expect(result.extra['sourceUrl'], songs.single.url);
    },
  );

  test('extracts HTML with CSS selectors and ordered selector fallback', () async {
    final source = entry(
      searchResponse: 'html',
      itemSelector: '.song',
      searchFields: {
        'id': [
          {'selector': '.missing', 'attribute': 'data-id'},
          {'selector': '.title', 'attribute': 'data-id'},
        ],
        'title': {'selector': '.title'},
        'artist': {'selector': '.artist'},
        'url': {'selector': 'a', 'attribute': 'href'},
      },
      resolveResponse: 'html',
      resolveFields: {
        'body': {'selector': '.lyrics'},
        'title': {'selector': 'h1'},
        'artist': {'selector': '.artist'},
      },
    );
    final provider = ConfigurableProvider(
      source,
      transport((request) async {
        if (request.url.path == '/search') {
          return http.Response(
            '<div class="song"><a class="title" data-id="s1" href="/song/s1">A Song</a><span class="artist">The Band</span></div>',
            200,
          );
        }
        return http.Response(
          '<h1>A Song</h1><span class="artist">The Band</span><div class="lyrics">Line one<br>Line two</div>',
          200,
        );
      }),
    );

    final candidate = (await provider.search('A Song')).single;
    expect(candidate.url, 'https://lyrics.example.com/song/s1');
    final result = await provider.resolve(candidate);
    expect(result.body, contains('Line one'));
    expect(result.body, contains('Line two'));
    expect(result.body, contains('\n'));
  });

  test(
    'uses the validated resolve URL as provenance when search has no URL',
    () async {
      const resolvedUrl = 'https://lyrics.example.com/song/s1';
      final source = entry(
        searchResponse: 'json',
        itemsPath: 'data',
        searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
        resolveResponse: 'json',
        resolveFields: {'body': 'lyrics', 'title': 'title', 'artist': 'artist'},
      );
      final provider = ConfigurableProvider(
        source,
        transport((request) async {
          if (request.url.path == '/search') {
            return http.Response(
              jsonEncode({
                'data': [
                  {'id': 's1', 'title': 'A Song', 'artist': 'The Band'},
                ],
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'title': 'A Song',
              'artist': 'The Band',
              'lyrics': 'Line one',
            }),
            200,
          );
        }),
      );

      final candidate = (await provider.search('A Song')).single;
      expect(candidate.url, isNull);
      final result = await provider.resolve(candidate);
      expect(result.candidate.url, resolvedUrl);
      expect(result.extra['sourceUrl'], resolvedUrl);
    },
  );

  test(
    'rejects unsafe templates, encoded host traversal, and mismatched identity',
    () async {
      final unsafe = entry(
        searchResponse: 'json',
        itemsPath: 'rows',
        searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
        resolveResponse: 'json',
        resolveFields: {'body': 'lyrics', 'title': 'title', 'artist': 'artist'},
        searchUrl: 'https://attacker.example/search?q={query}',
      );
      expect(
        () => ConfigurableProvider.validateExtraction(unsafe),
        throwsA(code('invalid_config')),
      );

      final hostPlaceholder = entry(
        searchResponse: 'json',
        itemsPath: 'rows',
        searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
        resolveResponse: 'json',
        resolveFields: {'body': 'lyrics', 'title': 'title', 'artist': 'artist'},
        searchUrl: 'https://{id}.lyrics.example.com/search?q={query}',
      );
      expect(
        () => ConfigurableProvider.validateExtraction(hostPlaceholder),
        throwsA(code('invalid_config')),
      );

      final invalidSelector = entry(
        searchResponse: 'html',
        itemSelector: '[',
        searchFields: {
          'id': {'selector': '.id'},
          'title': {'selector': '.title'},
          'artist': {'selector': '.artist'},
        },
        resolveResponse: 'html',
        resolveFields: {
          'body': {'selector': '.lyrics'},
          'title': {'selector': 'h1'},
          'artist': {'selector': '.artist'},
        },
      );
      expect(
        () => ConfigurableProvider.validateExtraction(invalidSelector),
        throwsA(code('invalid_config')),
      );

      final source = entry(
        searchResponse: 'json',
        itemsPath: 'rows',
        searchFields: {
          'id': 'id',
          'title': 'title',
          'artist': 'artist',
          'url': 'url',
        },
        resolveResponse: 'json',
        resolveFields: {'body': 'lyrics', 'title': 'title', 'artist': 'artist'},
        resolveUrl: '{url}',
      );
      final provider = ConfigurableProvider(
        source,
        transport(
          (request) async => http.Response(
            jsonEncode({
              'rows': [
                {
                  'id': '1',
                  'title': 'A Song',
                  'artist': 'The Band',
                  'url': 'https://attacker.example/steal',
                },
              ],
            }),
            200,
          ),
        ),
      );
      final candidate = (await provider.search('A Song')).single;
      expect(candidate.url, isNull);
      await expectLater(
        provider.resolve(candidate),
        throwsA(anyOf(code('invalid_url'), code('identity_mismatch'))),
      );

      final exactSource = entry(
        searchResponse: 'json',
        itemsPath: 'rows',
        searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
        resolveResponse: 'json',
        resolveFields: {'body': 'lyrics', 'title': 'title', 'artist': 'artist'},
      );
      final mismatchProvider = ConfigurableProvider(
        exactSource,
        transport(
          (request) async => http.Response(
            request.url.path == '/search'
                ? jsonEncode({
                    'rows': [
                      {'id': '1', 'title': 'A Song', 'artist': 'The Band'},
                    ],
                  })
                : jsonEncode({
                    'title': 'Different Song',
                    'artist': 'The Band',
                    'lyrics': 'Line',
                  }),
            200,
          ),
        ),
      );
      final exactCandidate = (await mismatchProvider.search('A Song')).single;
      await expectLater(
        mismatchProvider.resolve(exactCandidate),
        throwsA(code('identity_mismatch')),
      );
    },
  );

  test(
    'reports malformed nonempty search rows as extraction failures',
    () async {
      final source = entry(
        searchResponse: 'json',
        itemsPath: 'rows',
        searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
        resolveResponse: 'json',
        resolveFields: {'body': 'lyrics', 'title': 'title', 'artist': 'artist'},
      );
      final provider = ConfigurableProvider(
        source,
        transport(
          (_) async => http.Response(
            jsonEncode({
              'rows': [
                {'unexpected': true},
              ],
            }),
            200,
          ),
        ),
      );
      await expectLater(
        provider.search('A Song'),
        throwsA(code('extraction_failed')),
      );
    },
  );

  test('supports sanitized mapped metadata-only resolves', () async {
    final source = entry(
      searchResponse: 'json',
      itemsPath: 'rows',
      searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
      resolveResponse: 'json',
      resolveFields: {
        'title': 'title',
        'artist': 'artist',
        'metadata': {'key': 'key', 'tempo': 'tempo', 'unknown': 'raw'},
      },
      capabilities: const ['metadata'],
    );
    // Unknown metadata mappings are rejected during prevalidation.
    expect(
      () => ConfigurableProvider.validateExtraction(source),
      throwsA(code('invalid_config')),
    );

    final valid = entry(
      searchResponse: 'json',
      itemsPath: 'rows',
      searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
      resolveResponse: 'json',
      resolveFields: {
        'title': 'title',
        'artist': 'artist',
        'metadata': {'key': 'key', 'tempo': 'tempo'},
      },
      capabilities: const ['metadata'],
    );
    final provider = ConfigurableProvider(
      valid,
      transport(
        (request) async => http.Response(
          request.url.path == '/search'
              ? jsonEncode({
                  'rows': [
                    {'id': '1', 'title': 'A Song', 'artist': 'The Band'},
                  ],
                })
              : jsonEncode({
                  'title': 'A Song',
                  'artist': 'The Band',
                  'key': 'C',
                  'tempo': 120,
                  'raw': 'drop',
                }),
          200,
        ),
      ),
    );
    final candidate = (await provider.search('A Song')).single;
    final result = await provider.resolve(candidate);
    expect(result.body, isEmpty);
    expect(result.metadata, {'key': 'C', 'tempo': 120});
    expect(result.extra['rights']['status'], 'unknown');

    final emptyMetadataProvider = ConfigurableProvider(
      valid,
      transport(
        (request) async => http.Response(
          request.url.path == '/search'
              ? jsonEncode({
                  'rows': [
                    {'id': '1', 'title': 'A Song', 'artist': 'The Band'},
                  ],
                })
              : jsonEncode({
                  'title': 'A Song',
                  'artist': 'The Band',
                  'key': '',
                  'tempo': 900,
                }),
          200,
        ),
      ),
    );
    final emptyMetadataCandidate = (await emptyMetadataProvider.search(
      'A Song',
    )).single;
    await expectLater(
      emptyMetadataProvider.resolve(emptyMetadataCandidate),
      throwsA(code('extraction_failed')),
    );
  });

  test(
    'metadata-only resolves foreign selections uniquely and never claims a recording',
    () async {
      final source = entry(
        searchResponse: 'json',
        itemsPath: 'rows',
        searchFields: {
          'id': 'id',
          'title': 'title',
          'artist': 'artist',
          'album': 'album',
          'durationSeconds': 'duration',
        },
        resolveResponse: 'json',
        resolveFields: {
          'title': 'title',
          'artist': 'artist',
          'metadata': {'key': 'key'},
        },
        capabilities: const ['metadata'],
      );
      final provider = ConfigurableProvider(
        source,
        transport(
          (request) async => http.Response(
            request.url.path == '/search'
                ? jsonEncode({
                    'rows': [
                      {
                        'id': 'song-1',
                        'title': 'A Song',
                        'artist': 'The Band',
                        'album': 'First',
                        'duration': 201,
                      },
                    ],
                  })
                : jsonEncode({
                    'title': 'A Song',
                    'artist': 'The Band',
                    'key': 'C',
                  }),
            200,
          ),
        ),
      );
      const foreign = SongCandidate(
        providerId: 'genius',
        id: 'remote-id',
        title: 'A Song',
        artist: 'The Band',
        album: 'First',
        durationSeconds: 201,
        metadata: {'identityScope': 'recording'},
      );
      final enriched = await findMatchingSource(provider, foreign);
      expect(enriched.candidate.providerId, 'catalog_test');
      expect(enriched.candidate.metadata['identityScope'], 'composition');
      expect(enriched.matchKind, MatchKind.sameSong);

      final local = (await provider.search('A Song The Band')).single;
      final localMatch = await findMatchingSource(provider, local);
      expect(localMatch.matchKind, MatchKind.sameSong);
    },
  );

  test(
    'metadata-only resolve refuses ambiguous title and artist search hits',
    () async {
      final source = entry(
        searchResponse: 'json',
        itemsPath: 'rows',
        searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
        resolveResponse: 'json',
        resolveFields: {
          'title': 'title',
          'artist': 'artist',
          'metadata': {'key': 'key'},
        },
        capabilities: const ['metadata'],
      );
      final provider = ConfigurableProvider(
        source,
        transport(
          (_) async => http.Response(
            jsonEncode({
              'rows': [
                {'id': 'one', 'title': 'A Song', 'artist': 'The Band'},
                {'id': 'two', 'title': 'A Song', 'artist': 'The Band'},
              ],
            }),
            200,
          ),
        ),
      );
      await expectLater(
        provider.resolve(
          const SongCandidate(
            providerId: 'other',
            id: 'external',
            title: 'A Song',
            artist: 'The Band',
          ),
        ),
        throwsA(code('unavailable')),
      );
    },
  );

  test(
    'redirects to an unlisted www twin are blocked for configured sources',
    () async {
      final source = entry(
        searchResponse: 'json',
        itemsPath: 'rows',
        searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
        resolveResponse: 'json',
        resolveFields: {'body': 'lyrics', 'title': 'title', 'artist': 'artist'},
      );
      final provider = ConfigurableProvider(
        source,
        transport(
          (_) async => http.Response(
            '',
            302,
            headers: {'location': 'https://www.lyrics.example.com/search'},
          ),
        ),
      );
      await expectLater(provider.search('A Song'), throwsA(code('redirect')));
    },
  );

  test(
    'classifies a 200 bot wall as blocked and keeps raw LRC timing unverified',
    () async {
      final blocked = entry(
        searchResponse: 'json',
        itemsPath: 'rows',
        searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
        resolveResponse: 'json',
        resolveFields: {'body': 'lyrics', 'title': 'title', 'artist': 'artist'},
      );
      final blockedProvider = ConfigurableProvider(
        blocked,
        transport(
          (_) async => http.Response(
            '<title>Just a moment...</title><div id="challenge-platform">',
            200,
          ),
        ),
      );
      await expectLater(
        blockedProvider.search('A Song'),
        throwsA(code('blocked')),
      );

      final lrc = entry(
        searchResponse: 'json',
        itemsPath: 'rows',
        searchFields: {'id': 'id', 'title': 'title', 'artist': 'artist'},
        resolveResponse: 'json',
        resolveFields: {'body': 'lyrics', 'title': 'title', 'artist': 'artist'},
        rootPath: 'song',
        bodyFormat: 'lrc',
      );
      final provider = ConfigurableProvider(
        lrc,
        transport(
          (request) async => http.Response(
            request.url.path == '/search'
                ? jsonEncode({
                    'rows': [
                      {'id': '1', 'title': 'A Song', 'artist': 'The Band'},
                    ],
                  })
                : jsonEncode({
                    'song': {
                      'title': 'A Song',
                      'artist': 'The Band',
                      'lyrics': '[00:01.00]First line\n[00:02.00]Second line',
                    },
                  }),
            200,
          ),
        ),
      );
      final candidate = (await provider.search('A Song')).single;
      final result = await provider.resolve(candidate);
      expect(
        result.timingTracks.single.raw,
        '[00:01.00]First line\n[00:02.00]Second line',
      );
      expect(result.timingTracks.single.status.name, 'unverified');
      expect(result.matchKind, MatchKind.unverified);
    },
  );

  test(
    'auto format preserves and parses source TTML with fixed attribution',
    () async {
      const ttml =
          '<tt xmlns="http://www.w3.org/ns/ttml"><body><div><p begin="00:00:01.000" end="00:00:02.000">First line</p><p begin="00:00:03.000" end="00:00:04.000">Second line</p></div></body></tt>';
      final source = entry(
        searchResponse: 'json',
        itemsPath: 'data',
        searchFields: {'id': 'id', 'title': 'song', 'artist': 'artist'},
        resolveResponse: 'json',
        rootPath: 'data',
        resolveFields: {
          'body': 'lyrics',
          'title': 'song',
          'artist': 'artist',
          'format': 'format',
        },
        bodyFormat: 'auto',
        resolveUrl: 'https://lyrics.example.com/lyrics/{id}',
        searchUrl: 'https://lyrics.example.com/lyrics/search?q={query}',
      );
      final provider = ConfigurableProvider(
        source,
        transport(
          (request) async => http.Response(
            request.url.path.endsWith('/search')
                ? jsonEncode({
                    'data': [
                      {'id': '31', 'song': 'A Song', 'artist': 'The Band'},
                    ],
                  })
                : jsonEncode({
                    'data': {
                      'song': 'A Song',
                      'artist': 'The Band',
                      'lyrics': ttml,
                      'format': 'ttml',
                    },
                  }),
            200,
          ),
        ),
      );
      final candidate = (await provider.search('A Song')).single;
      final result = await provider.resolve(candidate);
      expect(result.timingTracks.single.format, 'ttml');
      expect(result.timingTracks.single.raw, ttml);
      expect(result.timingTracks.single.cues, isNotEmpty);
      expect(result.body, contains('First line'));
      expect(result.attribution, 'Catalog test source');
    },
  );
}
