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

const _releasedEndpoint =
    'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog.json';
String _bundle(String channel) =>
    File('config/source-catalog$channel.json').readAsStringSync();
SourceCatalogRuntime _runtime(
  ProviderTransport transport, {
  bool released = false,
}) => SourceCatalogRuntime(
  builtins:
      [
            ...createCoreProviders(transport: transport),
            ...createExtraProviders(transport: transport),
          ]
          .where(
            (p) =>
                !released ||
                !{
                  'lrcred',
                  'roswellmusicjam',
                  'karamoe',
                }.contains(p.definition.id),
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
  test(
    'released roster keeps v1 and rejects channel2 without poisoning last good',
    () async {
      final legacy = _bundle('');
      var cached = legacy;
      final seen = <Uri>[];
      final transport = ProviderTransport(
        client: MockClient((r) async {
          seen.add(r.url);
          return http.Response(_bundle('-v2'), 200);
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
          return http.Response(next, 200);
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
            settings[SourceCatalogClient.cacheKey] as String?,
        writeCache: (text) async {
          settings[SourceCatalogClient.cacheKey] = text;
        },
      );
      try {
        await client.initialize();
        expect(
          runtime.catalog!.revision,
          jsonDecode(_bundle('-v2'))['revision'],
        );
        expect(await client.refresh(), true);
        expect(runtime.catalog!.revision, jsonDecode(next)['revision']);
        expect(settings['sourceCatalog'], legacy);
        expect(settings['providers'], {'genius': false});
        expect(settings[SourceCatalogClient.cacheKey], next);
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
          (_) async => http.Response(_next(bundle, unknown: true), 200),
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

  test('explicit publisher override remains in effect on channel2', () async {
    final endpoint = Uri.parse('https://publisher.example/catalog.json');
    final transport = ProviderTransport(
      client: MockClient((r) async {
        expect(r.url, endpoint);
        return http.Response(_next(_bundle('-v2')), 200);
      }),
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    final runtime = _runtime(transport);
    final client = SourceCatalogClient(
      runtime: runtime,
      transport: transport,
      loadBundled: () async => _bundle('-v2'),
      readCache: () async => null,
      writeCache: (_) async {},
      endpoint: endpoint,
    );
    try {
      expect(await client.refresh(), true);
    } finally {
      await transport.close();
    }
  });
}
