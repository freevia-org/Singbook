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
  builtins: [
    ...createCoreProviders(transport: transport),
    ...createExtraProviders(transport: transport),
  ].where((p) => !released || p.definition.id != 'lrcred').toList(),
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
      legacyValue['revision'] = 1000;
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
        expect(runtime.catalog!.revision, 8);
        expect(await client.refresh(), true);
        expect(runtime.catalog!.revision, 9);
        expect(settings['sourceCatalog'], legacy);
        expect(settings['providers'], {'genius': false});
        expect(settings[SourceCatalogClient.cacheKey], next);
        final added = runtime.catalog!.sources.singleWhere(
          (s) => s.id == 'lrcred',
        );
        expect(added.status, 'disabled');
        expect(
          runtime.providers.any((p) => p.definition.id == 'lrcred'),
          false,
        );
        final oldIds = SourceCatalog.parse(legacy).sources.map((s) => s.id);
        expect(runtime.catalog!.sources.map((s) => s.id), containsAll(oldIds));
        for (final previous in SourceCatalog.parse(legacy).sources) {
          expect(
            runtime.catalog!.sources
                .singleWhere((s) => s.id == previous.id)
                .toJson(),
            previous.toJson(),
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
        expect(runtime.catalog!.revision, 8);
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
