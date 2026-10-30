import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';
import 'package:singbook/providers/source_maintenance.dart';

String _bundle(int channel) =>
    File('config/source-catalog-v$channel.json').readAsStringSync();

List<LyricsProvider> _compiled(ProviderTransport transport) => [
  ...createCoreProviders(transport: transport),
  ...createExtraProviders(transport: transport),
];

SourceCatalogRuntime _runtime(
  ProviderTransport transport, {
  bool legacy = false,
}) => SourceCatalogRuntime(
  builtins: _compiled(
    transport,
  ).where((p) => !legacy || p.definition.id != 'wikibooksliederbuch').toList(),
  createProvider: (entry) => ConfigurableProvider(entry, transport),
);

void main() {
  test(
    'channel11 preserves channel10 and gates the new compiled source offline',
    () async {
      var requests = 0;
      final transport = ProviderTransport(
        client: MockClient((_) async {
          requests++;
          throw StateError('Offline structural check');
        }),
      );
      addTearDown(transport.close);
      final previous = jsonDecode(_bundle(10)) as Map;
      final next = jsonDecode(_bundle(11)) as Map;
      final rows = next['sources'] as List;
      expect(
        rows.take((previous['sources'] as List).length).toList(),
        previous['sources'],
      );
      expect(rows.length, (previous['sources'] as List).length + 1);
      expect(next['revision'], greaterThan(previous['revision'] as int));
      expect(
        SourceCatalogClient.bundledAsset,
        'config/source-catalog-v11.json',
      );
      expect(SourceCatalogClient.cacheKey, 'sourceCatalog:v11');
      expect(SourceCatalogClient.channel10CacheKey, 'sourceCatalog:v10');
      final row = rows.last as Map;
      expect(row['id'], 'wikibooksliederbuch');
      expect(row['status'], 'disabled');
      expect(row['enabledByDefault'], false);
      expect(row['license'], isNull);
      expect((row['probes'] as List).map((p) => (p as Map)['id']), [
        '118857',
        '115615',
      ]);
      final compiled = _compiled(transport);
      final book = compiled.whereType<WikibooksLiederbuchProvider>().single;
      expect(book.definition.enabledByDefault, false);
      expect(
        (row['capabilities'] as List).toSet(),
        book.definition.capabilities,
      );
      final catalog = SourceCatalog.parse(_bundle(11));
      expect(
        catalog.sources
            .where((s) => s.adapter == 'builtin')
            .map((s) => s.id)
            .toSet(),
        compiled.map((p) => p.definition.id).toSet(),
      );
      final runtime = _runtime(transport)..apply(catalog);
      expect(runtime.providers.any((p) => p.definition.id == row['id']), false);
      final report = await SourceMaintenanceHarness(
        providers: [...compiled, ...runtime.providers],
      ).run(catalog, offline: true);
      final reports = (report['sources'] as List).cast<Map>();
      expect(reports, hasLength(catalog.sources.length));
      expect(reports.where((r) => r['status'] == 'coverage_gap'), isEmpty);
      expect(
        reports.singleWhere((r) => r['id'] == row['id'])['status'],
        'disabled',
      );
      expect(requests, 0);
    },
  );

  test(
    'channel10 binary rejects the new disabled ID before cache mutation',
    () async {
      var requests = 0, writes = 0;
      final previous = _bundle(10);
      var cached = previous;
      final transport = ProviderTransport(
        client: MockClient((_) async {
          requests++;
          return http.Response(
            _bundle(11),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      addTearDown(transport.close);
      final runtime = _runtime(transport, legacy: true);
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => previous,
        readCache: () async => cached,
        writeCache: (text) async {
          writes++;
          cached = text;
        },
        endpoint: Uri.parse(
          'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog-v10.json',
        ),
      );
      await client.initialize();
      final before = runtime.catalog!.toJson();
      expect(await client.refresh(), false);
      expect(runtime.catalog!.toJson(), before);
      expect(cached, previous);
      expect(writes, 0);
      expect(requests, 1);
    },
  );

  test(
    'channel11 inherits cached channel10 repairs and removals while staying gated',
    () async {
      var requests = 0, writes = 0;
      final previous = _bundle(10);
      final cached = jsonDecode(previous) as Map<String, dynamic>;
      cached['revision'] = 9000;
      final rows = (cached['sources'] as List).cast<Map<String, dynamic>>();
      rows.singleWhere((r) => r['id'] == 'lyricsovh')
        ..['name'] = 'Cached offline repair'
        ..['revision'] = 1000;
      rows.removeWhere((r) => r['id'] == 'genius');
      final transport = ProviderTransport(
        client: MockClient((_) async {
          requests++;
          throw StateError('No network during upgrade');
        }),
      );
      addTearDown(transport.close);
      final client = SourceCatalogClient(
        runtime: _runtime(transport),
        transport: transport,
        loadBundled: () async => _bundle(11),
        readCache: () async => null,
        writeCache: (_) async {
          writes++;
        },
        readPreviousCaches: () async => [
          (bundled: previous, cached: jsonEncode(cached)),
        ],
      );
      await client.initialize();
      final migrated = client.runtime.catalog!;
      expect(migrated.revision, SourceCatalog.parse(_bundle(11)).revision);
      expect(migrated.sources.any((s) => s.id == 'genius'), false);
      expect(
        migrated.sources.singleWhere((s) => s.id == 'lyricsovh').name,
        'Cached offline repair',
      );
      final book = migrated.sources.singleWhere(
        (s) => s.id == 'wikibooksliederbuch',
      );
      expect(book.status, 'disabled');
      expect(book.enabledByDefault, false);
      expect(requests, 0);
      expect(writes, 0);
    },
  );
}
