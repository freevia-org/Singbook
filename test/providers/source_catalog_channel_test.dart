import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';
import 'package:singbook/providers/transport.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/provider.dart' show ContextualLyricsSearch;
import 'package:singbook/domain/models.dart' show SongCandidate, MatchKind;

const _releasedEndpoint =
    'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog.json';
const _channel2Endpoint =
    'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog-v2.json';
const _channel3Endpoint =
    'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog-v3.json';
http.Response _catalogResponse(String text) => http.Response(
  text,
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
String _bundle(String channel) =>
    File('config/source-catalog$channel.json').readAsStringSync();
SourceCatalogRuntime _runtime(
  ProviderTransport transport, {
  bool released = false,
  bool channel2 = false,
  bool channel3 = false,
  bool channel4 = false,
}) => SourceCatalogRuntime(
  builtins:
      [
            ...createCoreProviders(transport: transport),
            ...createExtraProviders(transport: transport),
          ]
          .where(
            (p) =>
                p.definition.id != 'chordsandtabs' &&
                p.definition.id != 'pisni' &&
                !(released
                        ? {
                            'lrcred',
                            'roswellmusicjam',
                            'karamoe',
                            'amll',
                            'vocadb',
                            'touhoudb',
                            'utaitedb',
                          }
                        : channel2
                        ? {'amll', 'vocadb', 'touhoudb', 'utaitedb'}
                        : channel3
                        ? {'vocadb', 'touhoudb', 'utaitedb'}
                        : channel4
                        ? {'touhoudb', 'utaitedb'}
                        : <String>{})
                    .contains(p.definition.id),
          )
          .toList(),
  createProvider: (entry) => ConfigurableProvider(entry, transport),
);
String _next(String text, {bool unknown = false}) {
  final value = jsonDecode(text) as Map<String, dynamic>;
  value['revision'] = (value['revision'] as int) + 1;
  if (unknown) {
    (value['sources'] as List).add({
      'id': 'notcompiled',
      'name': 'Unknown native source',
      'adapter': 'builtin',
      'status': 'disabled',
      'revision': 1,
      'capabilities': ['metadata'],
      'enabledByDefault': false,
      'accessMode': 'publicApi',
      'website': 'https://example.org/',
      'hosts': [],
    });
  }
  return jsonEncode(value);
}

void main() {
  for (final (sourceId, sourceHost) in const [
    ('vocadb', 'vocadb.net'),
    ('touhoudb', 'touhoudb.com'),
    ('utaitedb', 'utaitedb.net'),
  ]) {
    test(
      'channel5 preserves channel4 entries and routes normal $sourceId context',
      () async {
        final bundle = _bundle('-v5');
        final seen = <Uri>[];
        final row = {
          'id': 123,
          'name': 'Invented Song',
          'artistString': 'Invented Producer feat. Invented Voice',
          'songType': 'Original',
          'names': [
            {'value': 'Invented Song', 'language': 'English'},
          ],
          'artists': [
            {'name': 'Invented Producer', 'roles': 'Composer, Lyricist'},
          ],
          'cultureCodes': ['en'],
          'minMilliBpm': 100000,
          'maxMilliBpm': 100000,
          'lyrics': [
            {
              'id': 45,
              'translationType': 'Original',
              'value': 'Invented lyric line\nA second invented lyric line',
            },
          ],
        };
        final transport = ProviderTransport(
          client: MockClient((r) async {
            seen.add(r.url);
            expect(r.url.host, sourceHost);
            if (r.url.path == '/api/songs') {
              expect(r.url.queryParameters['query'], 'Invented Song');
              if (sourceId == 'utaitedb' &&
                  r.url.queryParameters['nameMatchMode'] == 'Auto') {
                return _catalogResponse(
                  jsonEncode({
                    'items': [
                      {...row, 'id': 999, 'artistString': 'Different vocalist'},
                    ],
                  }),
                );
              }
              return _catalogResponse(
                jsonEncode({
                  'items': [row],
                }),
              );
            }
            expect(r.url.path, '/api/songs/123');
            return _catalogResponse(jsonEncode(row));
          }),
          hostInterval: Duration.zero,
          maxRetries: 0,
        );
        try {
          final runtime = _runtime(transport);
          final client = SourceCatalogClient(
            runtime: runtime,
            transport: transport,
            loadBundled: () async => bundle,
            readCache: () async => null,
            writeCache: (_) async {},
          );
          await client.initialize();
          expect(
            SourceCatalogClient.bundledAsset,
            'config/source-catalog-v10.json',
          );
          expect(SourceCatalogClient.cacheKey, 'sourceCatalog:v10');
          expect(client.endpoint.path, endsWith('/source-catalog-v10.json'));
          expect(runtime.catalog!.sources, hasLength(26));
          for (final previous in SourceCatalog.parse(_bundle('-v4')).sources) {
            final current = runtime.catalog!.sources.singleWhere(
              (s) => s.id == previous.id,
            );
            if (previous.id == 'musicbrainz') {
              // Optional exact-release artwork is the one deliberately
              // revised existing provider; its earlier canary/contract stays.
              expect(current.revision, 3);
              expect(current.capabilities, {
                ...previous.capabilities,
                'artwork',
              });
              expect(
                current.probes.take(previous.probes.length).toList(),
                previous.probes,
              );
              expect(current.probes.length, previous.probes.length + 2);
              expect({
                ...current.toJson(),
                'revision': previous.revision,
                'capabilities': previous.toJson()['capabilities'],
                'probes': previous.probes,
                'changeReason': previous.toJson()['changeReason'],
              }, previous.toJson());
              continue;
            }
            expect(current.toJson(), previous.toJson());
          }
          final source = runtime.catalog!.sources.singleWhere(
            (s) => s.id == sourceId,
          );
          expect(source.status, 'active');
          expect(source.enabledByDefault, true);
          final provider = runtime.providers.singleWhere(
            (p) => p.definition.id == sourceId,
          );
          expect(provider, isA<ContextualLyricsSearch>());
          const reference = SongCandidate(
            providerId: 'reference',
            id: 'canonical',
            title: 'Invented Song',
            artist: 'Invented Producer feat. Invented Voice',
          );
          final result = await findMatchingSource(
            provider,
            reference,
            maxAttempts: 1,
          );
          expect(result.matchKind, MatchKind.sameSong);
          expect(result.candidate.recordingIds, isEmpty);
          expect(result.body, contains('Invented lyric line'));
          expect(result.metadata['tempo'], 100);
          expect(result.extra[sourceId]['lyrics'], row['lyrics']);
          expect(seen, hasLength(sourceId == 'utaitedb' ? 3 : 2));
          expect(
            seen
                .where((url) => url.path == '/api/songs')
                .map((url) => url.queryParameters['nameMatchMode']),
            sourceId == 'utaitedb' ? ['Auto', 'Exact'] : ['Auto'],
          );
        } finally {
          await transport.close();
        }
      },
    );
  }

  test(
    'channel1/2/3 runtimes reject even disabled VocaDB before changing a snapshot',
    () async {
      final entry =
          (jsonDecode(_bundle('-v4'))['sources'] as List)
              .cast<Map<String, dynamic>>()
              .singleWhere((s) => s['id'] == 'vocadb')
            ..['status'] = 'disabled';
      for (final channel in ['', '-v2', '-v3']) {
        final bundle = _bundle(channel);
        final next = jsonDecode(bundle) as Map<String, dynamic>;
        next['revision'] = (next['revision'] as int) + 1;
        (next['sources'] as List).add(entry);
        var cache = bundle;
        final transport = ProviderTransport(
          client: MockClient((_) async => _catalogResponse(jsonEncode(next))),
          maxRetries: 0,
          hostInterval: Duration.zero,
        );
        try {
          final runtime = _runtime(
            transport,
            released: channel.isEmpty,
            channel2: channel == '-v2',
            channel3: channel == '-v3',
          );
          final client = SourceCatalogClient(
            runtime: runtime,
            transport: transport,
            loadBundled: () async => bundle,
            readCache: () async => cache,
            writeCache: (text) async {
              cache = text;
            },
            endpoint: Uri.parse(
              channel.isEmpty
                  ? _releasedEndpoint
                  : channel == '-v2'
                  ? _channel2Endpoint
                  : _channel3Endpoint,
            ),
          );
          await client.initialize();
          final ids = runtime.providers.map((p) => p.definition.id).toList();
          expect(await client.refresh(), false);
          expect(cache, bundle);
          expect(runtime.catalog!.revision, jsonDecode(bundle)['revision']);
          expect(runtime.providers.map((p) => p.definition.id), ids);
          expect(
            runtime.providers.any((p) => p.definition.id == 'vocadb'),
            false,
          );
        } finally {
          await transport.close();
        }
      }
    },
  );

  for (final sourceId in const ['touhoudb', 'utaitedb']) {
    test(
      'older runtimes reject even disabled $sourceId before changing a snapshot',
      () async {
        final entry =
            (jsonDecode(_bundle('-v5'))['sources'] as List)
                .cast<Map<String, dynamic>>()
                .singleWhere((s) => s['id'] == sourceId)
              ..['status'] = 'disabled';
        for (final channel in ['', '-v2', '-v3', '-v4']) {
          final bundle = _bundle(channel);
          final next = jsonDecode(bundle) as Map<String, dynamic>;
          next['revision'] = (next['revision'] as int) + 1;
          (next['sources'] as List).add(entry);
          var cache = bundle;
          final transport = ProviderTransport(
            client: MockClient((_) async => _catalogResponse(jsonEncode(next))),
            maxRetries: 0,
            hostInterval: Duration.zero,
          );
          try {
            final runtime = _runtime(
              transport,
              released: channel.isEmpty,
              channel2: channel == '-v2',
              channel3: channel == '-v3',
              channel4: channel == '-v4',
            );
            final client = SourceCatalogClient(
              runtime: runtime,
              transport: transport,
              loadBundled: () async => bundle,
              readCache: () async => cache,
              writeCache: (text) async {
                cache = text;
              },
              endpoint: Uri.parse(
                channel.isEmpty
                    ? _releasedEndpoint
                    : channel == '-v2'
                    ? _channel2Endpoint
                    : channel == '-v3'
                    ? _channel3Endpoint
                    : 'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog-v4.json',
              ),
            );
            await client.initialize();
            final ids = runtime.providers.map((p) => p.definition.id).toList();
            expect(await client.refresh(), false);
            expect(cache, bundle);
            expect(runtime.catalog!.revision, jsonDecode(bundle)['revision']);
            expect(runtime.providers.map((p) => p.definition.id), ids);
            expect(
              runtime.providers.any((p) => p.definition.id == sourceId),
              false,
            );
          } finally {
            await transport.close();
          }
        }
      },
    );
  }

  test(
    'released roster keeps v1 and rejects channel2 without poisoning last good',
    () async {
      final legacy = _bundle('');
      var cached = legacy;
      final seen = <Uri>[];
      final transport = ProviderTransport(
        client: MockClient((r) async {
          seen.add(r.url);
          return _catalogResponse(_bundle('-v2'));
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final runtime = _runtime(transport, released: true);
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => legacy,
        readCache: () async => cached,
        writeCache: (text) async {
          cached = text;
        },
        endpoint: Uri.parse(_releasedEndpoint),
      );
      try {
        await client.initialize();
        final ids = runtime.providers.map((p) => p.definition.id).toList();
        expect(await client.refresh(), false);
        expect(seen.single.toString(), _releasedEndpoint);
        expect(runtime.providers.map((p) => p.definition.id), ids);
        expect(cached, legacy);
        expect(runtime.catalog!.revision, jsonDecode(legacy)['revision']);
      } finally {
        await transport.close();
      }
    },
  );

  test(
    'channel2 bundle/cache ignore legacy revision stream and preserve old data',
    () async {
      final legacyValue = jsonDecode(_bundle('')) as Map<String, dynamic>;
      // Channel 1 may advance independently before a user upgrades the app.
      legacyValue['revision'] =
          (jsonDecode(_bundle('-v2'))['revision'] as int) + 1000;
      final legacy = jsonEncode(legacyValue);
      final next = _next(_bundle('-v2'));
      final settings = <String, Object?>{
        'sourceCatalog': legacy,
        'providers': {'genius': false},
      };
      final transport = ProviderTransport(
        client: MockClient((r) async {
          expect(r.url.path, endsWith('/source-catalog-v2.json'));
          return _catalogResponse(next);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final runtime = _runtime(transport);
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => _bundle('-v2'),
        readCache: () async =>
            settings[SourceCatalogClient.channel2CacheKey] as String?,
        writeCache: (text) async {
          settings[SourceCatalogClient.channel2CacheKey] = text;
        },
        endpoint: Uri.parse(_channel2Endpoint),
      );
      try {
        await client.initialize();
        expect(
          runtime.catalog!.revision,
          jsonDecode(_bundle('-v2'))['revision'],
        );
        expect(await client.refresh(), true, reason: client.lastErrorCode);
        expect(runtime.catalog!.revision, jsonDecode(next)['revision']);
        expect(settings['sourceCatalog'], legacy);
        expect(settings['providers'], {'genius': false});
        expect(settings[SourceCatalogClient.channel2CacheKey], next);
        for (final id in ['lrcred', 'roswellmusicjam', 'karamoe']) {
          final added = runtime.catalog!.sources.singleWhere((s) => s.id == id);
          expect(added.status, 'active');
          expect(added.enabledByDefault, true);
          final provider = runtime.providers.singleWhere(
            (p) => p.definition.id == id,
          );
          expect(provider.definition.enabledByDefault, true);
        }
        final oldIds = SourceCatalog.parse(legacy).sources.map((s) => s.id);
        expect(runtime.catalog!.sources.map((s) => s.id), containsAll(oldIds));
        for (final previous in SourceCatalog.parse(legacy).sources) {
          final current = runtime.catalog!.sources
              .singleWhere((s) => s.id == previous.id)
              .toJson();
          final expected = previous.toJson();
          if (previous.id == 'seanmcgrathmusic') {
            // Channel 2 ships the publisher path migration and another canary;
            // channel 1 remains byte-compatible with the released app.
            expect(
              current['revision'],
              greaterThan(expected['revision'] as int),
            );
            expect(current['probes'], containsAll(expected['probes'] as List));
            expect((current['probes'] as List).length, 2);
            expect(current['changeReason'], contains('songs_and_poems'));
            for (final key in ['revision', 'probes', 'changeReason']) {
              current.remove(key);
              expected.remove(key);
            }
          } else if (previous.id == 'synclrc') {
            // Channel 2 qualifies the documented lookup contract separately
            // from the unchanged legacy probes. Runtime identity, capability,
            // access, attribution and preference fields still compare below.
            expect(current['revision'], greaterThan(previous.revision));
            final probes = (current['probes'] as List)
                .cast<Map<String, dynamic>>();
            final direct = probes.where((probe) => probe['candidate'] is Map);
            expect(direct, hasLength(2));
            expect(
              probes.where((probe) => probe['query'] is String),
              hasLength(1),
            );
            expect(
              probes.map((probe) => probe['id']),
              containsAll([
                'never-gonna-give-you-up-studio',
                'wonderwall-oasis-timed-version',
                'never-gonna-give-you-up-catalog-search',
              ]),
            );
            for (final probe in probes) {
              expect(
                probe['requiredFields'],
                containsAll(['body', 'metadata', 'lineTiming', 'wordTiming']),
              );
            }
            for (final probe in direct) {
              final candidate = probe['candidate'] as Map;
              expect(candidate['providerId'], previous.id);
              expect(candidate['id'], matches(RegExp(r'^[a-f0-9]{32}$')));
              expect(candidate['title'], probe['expectedTitle']);
              expect(candidate['artist'], probe['expectedArtist']);
              expect(candidate['album'], probe['expectedAlbum']);
              expect(
                candidate['durationSeconds'],
                probe['expectedDurationSeconds'],
              );
            }
            for (final key in ['revision', 'probes', 'changeReason']) {
              current.remove(key);
              expected.remove(key);
            }
          }
          expect(
            current,
            expected,
            reason: 'Existing source ${previous.id} keeps its full definition',
          );
        }
      } finally {
        await transport.close();
      }
    },
  );

  test(
    'unknown native in a newer snapshot leaves channel2 live/cache unchanged',
    () async {
      final bundle = _bundle('-v2');
      var cached = bundle;
      final transport = ProviderTransport(
        client: MockClient(
          (_) async => _catalogResponse(_next(bundle, unknown: true)),
        ),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final runtime = _runtime(transport);
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => bundle,
        readCache: () async => cached,
        writeCache: (text) async {
          cached = text;
        },
        endpoint: Uri.parse(_channel2Endpoint),
      );
      try {
        expect(await client.refresh(), false);
        expect(cached, bundle);
        expect(runtime.catalog!.revision, jsonDecode(bundle)['revision']);
        expect(
          runtime.providers.any((p) => p.definition.id == 'notcompiled'),
          false,
        );
      } finally {
        await transport.close();
      }
    },
  );

  test(
    'channel3 bundle has the AMLL native source enabled by default',
    () async {
      final bundle = _bundle('-v3');
      final transport = ProviderTransport(
        client: MockClient((_) async => _catalogResponse(bundle)),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final runtime = _runtime(transport);
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => bundle,
        readCache: () async => null,
        writeCache: (_) async {},
      );
      try {
        await client.initialize();
        final previousEntries = SourceCatalog.parse(_bundle('-v2')).sources;
        expect(SourceCatalogClient.channel3CacheKey, 'sourceCatalog:v3');
        expect(runtime.catalog!.sources, hasLength(23));
        for (final previous in previousEntries) {
          expect(
            runtime.catalog!.sources
                .singleWhere((entry) => entry.id == previous.id)
                .toJson(),
            previous.toJson(),
            reason: 'Channel 3 preserves ${previous.id} configuration',
          );
        }
        final amll = runtime.catalog!.sources.singleWhere(
          (s) => s.id == 'amll',
        );
        expect(amll.status, 'active');
        expect(amll.enabledByDefault, true);
        expect(
          runtime.providers
              .singleWhere((p) => p.definition.id == 'amll')
              .definition
              .enabledByDefault,
          true,
        );
      } finally {
        await transport.close();
      }
    },
  );

  test(
    'old channel1 and channel2 reject AMLL before live/cache mutation',
    () async {
      final amll =
          (jsonDecode(_bundle('-v3')) as Map<String, dynamic>)['sources']
              as List;
      final amllEntry = (amll.cast<Map<String, dynamic>>().singleWhere(
        (source) => source['id'] == 'amll',
      ))..['status'] = 'disabled';

      for (final channel in ['', '-v2']) {
        final bundle = _bundle(channel);
        final incomingCatalog = jsonDecode(bundle) as Map<String, dynamic>;
        incomingCatalog['revision'] = (incomingCatalog['revision'] as int) + 1;
        (incomingCatalog['sources'] as List).add(amllEntry);
        final incoming = jsonEncode(incomingCatalog);
        var cached = bundle;
        final transport = ProviderTransport(
          client: MockClient((_) async => _catalogResponse(incoming)),
          hostInterval: Duration.zero,
          maxRetries: 0,
        );
        final runtime = _runtime(
          transport,
          released: channel.isEmpty,
          channel2: channel == '-v2',
        );
        final client = SourceCatalogClient(
          runtime: runtime,
          transport: transport,
          loadBundled: () async => bundle,
          readCache: () async => cached,
          writeCache: (text) async {
            cached = text;
          },
          endpoint: Uri.parse(
            channel.isEmpty ? _releasedEndpoint : _channel2Endpoint,
          ),
        );
        try {
          await client.initialize();
          final beforeIds = runtime.providers
              .map((p) => p.definition.id)
              .toList();
          expect(await client.refresh(), false);
          expect(cached, bundle);
          expect(runtime.catalog!.revision, jsonDecode(bundle)['revision']);
          expect(runtime.providers.map((p) => p.definition.id), beforeIds);
          expect(
            runtime.providers.any((p) => p.definition.id == 'amll'),
            false,
          );
        } finally {
          await transport.close();
        }
      }
    },
  );

  test('explicit publisher override remains in effect on channel3', () async {
    final endpoint = Uri.parse('https://publisher.example/catalog.json');
    final bundle = _bundle('-v3');
    final transport = ProviderTransport(
      client: MockClient((r) async {
        expect(r.url, endpoint);
        return _catalogResponse(_next(bundle));
      }),
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    final runtime = _runtime(transport);
    final client = SourceCatalogClient(
      runtime: runtime,
      transport: transport,
      loadBundled: () async => bundle,
      readCache: () async => null,
      writeCache: (_) async {},
      endpoint: endpoint,
    );
    try {
      expect(await client.refresh(), true, reason: client.lastErrorCode);
    } finally {
      await transport.close();
    }
  });
}
