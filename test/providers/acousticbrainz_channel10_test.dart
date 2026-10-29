import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/core/recording_context.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';
import 'package:singbook/providers/source_maintenance.dart';

String _bundle(int channel) =>
    File('config/source-catalog-v$channel.json').readAsStringSync();

void main() {
  test(
    'channel10 inherits every channel9 row without reactivating gated sources',
    () {
      final old = jsonDecode(_bundle(9)) as Map;
      final next = jsonDecode(_bundle(10)) as Map;
      final previous = old['sources'] as List,
          current = next['sources'] as List;
      expect(current.take(previous.length).toList(), previous);
      expect(current.length, previous.length + 1);
      expect(next['revision'], (old['revision'] as int) + 1);
      final row = current.last as Map;
      expect(row['id'], 'acousticbrainz');
      expect(row['status'], 'active');
      expect(row['enabledByDefault'], true);
      expect(row['capabilities'], ['metadata']);
      expect(row['probes'], hasLength(2));
      expect(
        SourceCatalogClient.bundledAsset,
        'config/source-catalog-v10.json',
      );
      expect(SourceCatalogClient.cacheKey, 'sourceCatalog:v10');
      expect(SourceCatalogClient.channel9CacheKey, 'sourceCatalog:v9');
    },
  );

  test(
    'full current compiled roster and default catalog match offline without HTTP',
    () async {
      var calls = 0;
      final transport = ProviderTransport(
        client: MockClient((_) async {
          calls++;
          throw StateError('Offline structural qualification');
        }),
      );
      addTearDown(transport.close);
      final builtins = [
        ...createCoreProviders(transport: transport),
        ...createExtraProviders(transport: transport),
      ];
      final catalog = SourceCatalog.parse(
        File(SourceCatalogClient.bundledAsset).readAsStringSync(),
      );
      final runtime = SourceCatalogRuntime(
        builtins: builtins,
        createProvider: (e) => ConfigurableProvider(e, transport),
      )..apply(catalog);
      expect(
        catalog.sources
            .where((s) => s.adapter == 'builtin')
            .map((s) => s.id)
            .toSet(),
        builtins.map((p) => p.definition.id).toSet(),
      );
      final source = runtime.providers.singleWhere(
        (p) => p.definition.id == 'acousticbrainz',
      );
      expect(source.definition.enabledByDefault, true);
      expect(
        (source as RecordingContextReceiver).requiredRecordingIdNamespace,
        'musicbrainz',
      );
      final report = await SourceMaintenanceHarness(
        providers: [...builtins, ...runtime.providers],
      ).run(catalog, offline: true);
      final rows = (report['sources'] as List).cast<Map>();
      expect(rows, hasLength(catalog.sources.length));
      expect(rows.where((r) => r['status'] == 'coverage_gap'), isEmpty);
      expect(calls, 0);
    },
  );

  test('channel9 binary rejects the new native ID atomically', () {
    final transport = ProviderTransport(
      client: MockClient((_) async => throw StateError('No HTTP')),
    );
    addTearDown(transport.close);
    final runtime = SourceCatalogRuntime(
      builtins: [
        ...createCoreProviders(transport: transport),
        ...createExtraProviders(transport: transport),
      ].where((p) => p.definition.id != 'acousticbrainz').toList(),
      createProvider: (e) => ConfigurableProvider(e, transport),
    )..apply(SourceCatalog.parse(_bundle(9)));
    final prior = runtime.catalog, providers = runtime.providers;
    expect(
      () => runtime.apply(SourceCatalog.parse(_bundle(10))),
      throwsStateError,
    );
    expect(identical(runtime.catalog, prior), true);
    expect(identical(runtime.providers, providers), true);
  });

  test(
    'closest channel9 cached repairs survive upgrade without mutating old cache',
    () async {
      final old = jsonDecode(_bundle(9)) as Map<String, dynamic>;
      old['revision'] = 900;
      final row =
          (old['sources'] as List).firstWhere((r) => r['id'] == 'chordsandtabs')
              as Map;
      row['revision'] = 90;
      row['enabledByDefault'] = false;
      final cached9 = jsonEncode(old);
      final transport = ProviderTransport(
        client: MockClient((_) async => throw StateError('No HTTP')),
      );
      addTearDown(transport.close);
      final runtime = SourceCatalogRuntime(
        builtins: [
          ...createCoreProviders(transport: transport),
          ...createExtraProviders(transport: transport),
        ],
        createProvider: (e) => ConfigurableProvider(e, transport),
      );
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => _bundle(10),
        readCache: () async => null,
        writeCache: (_) async =>
            throw StateError('Initialization must not overwrite cache'),
        readPreviousCaches: () async => [
          (bundled: _bundle(9), cached: cached9),
        ],
      );
      await client.initialize();
      expect(client.lastErrorCode, isNull);
      expect(
        runtime.providers
            .singleWhere((p) => p.definition.id == 'chordsandtabs')
            .definition
            .enabledByDefault,
        false,
      );
      expect(
        runtime.providers
            .singleWhere((p) => p.definition.id == 'acousticbrainz')
            .definition
            .enabledByDefault,
        true,
      );
      expect(jsonEncode(old), cached9);
    },
  );
}
