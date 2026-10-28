import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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

String _catalogPath(int channel) => channel == 1
    ? 'config/source-catalog.json'
    : 'config/source-catalog-v$channel.json';

String _bundle(int channel) => File(_catalogPath(channel)).readAsStringSync();

List<LyricsProvider> _providers(ProviderTransport transport) => [
  ...createCoreProviders(transport: transport),
  ...createExtraProviders(transport: transport),
];

SourceCatalogRuntime _runtime(
  ProviderTransport transport, {
  bool oldRuntime = false,
}) => SourceCatalogRuntime(
  builtins: _providers(transport)
      .where((p) => !oldRuntime || p.definition.id != 'openscorelieder')
      .toList(),
  createProvider: (entry) => ConfigurableProvider(entry, transport),
);

void main() {
  test('all eight historical catalog files retain their original LF bytes', () {
    const hashes = [
      'eb23bd9999d2e70a04912bb5150d0874fc2bd5490e6f6f60fb426d2fe9838c59',
      'fb761d3e89e97faafcd20ba7dd3457e42e957f76a82e5a7acebd8f40c879b5e2',
      'b27df30346ba9fd0b0e2db530c42cb621cc2fe9371f50b40c685bc58703ff069',
      '987dee720305c7857532f619c8b8bb6c1574bc542538688051a1974d86e4fdfa',
      '17b80d9ad891e2447b9dfbade1ba7d9b3e048f2f2ea53751672258a4dc7da90b',
      'bc698ebbbe0bdec8583a44d1dd05422a9e0d423228d61ccd7be20ea80c5f932d',
      'b192e129d56664ddc04fea41be863cbb9e4c9f92eb7b3e5b76717e2a0b171e76',
      '92aca68ba9395c89b6f78d29ae5a154f78996d3ab9c417b9b1fafa7ed850137c',
    ];
    for (var channel = 1; channel <= hashes.length; channel++) {
      final bytes = File(_catalogPath(channel)).readAsBytesSync();
      expect(sha256.convert(bytes).toString(), hashes[channel - 1]);
    }
  });

  test('v9 preserves v8 rows and adds one disabled, off-default source', () {
    final old = jsonDecode(_bundle(8)) as Map;
    final next = jsonDecode(_bundle(9)) as Map;
    final oldRows = old['sources'] as List;
    final rows = next['sources'] as List;
    expect(rows.take(oldRows.length).toList(), oldRows);
    expect(rows.length, oldRows.length + 1);
    expect(next['revision'], 22);
    expect(
      DateTime.parse(next['publishedAt'] as String).isAfter(
        DateTime.parse(old['publishedAt'] as String),
      ),
      isTrue,
    );
    final candidate = rows.last as Map;
    expect(candidate['id'], 'openscorelieder');
    expect(candidate['adapter'], 'builtin');
    expect(candidate['revision'], 1);
    expect(candidate['status'], 'disabled');
    expect(candidate['enabledByDefault'], false);
    expect(candidate['capabilities'], ['catalog', 'lyrics', 'metadata']);
    expect(candidate['hosts'], ['raw.githubusercontent.com']);
    final probes = (candidate['probes'] as List).cast<Map>();
    expect(probes.map((p) => p['id']), ['6573780', '6217099']);
    for (final probe in probes) {
      expect(probe['query'], isNotEmpty);
      expect(probe['expectedTitle'], isNotEmpty);
      expect(probe['expectedArtist'], isNotEmpty);
      expect(probe.containsKey('candidate'), isFalse);
      expect(probe['requiredFields'], ['body', 'metadata']);
      expect(
        probe['requiredMetadataFields'],
        containsAll(['identityScope', 'artistCreditRole', 'composer']),
      );
    }
    expect(SourceCatalogClient.bundledAsset, 'config/source-catalog-v9.json');
    expect(SourceCatalogClient.cacheKey, 'sourceCatalog:v9');
    expect(SourceCatalogClient.channel8CacheKey, 'sourceCatalog:v8');
    expect(
      SourceCatalogClient.defaultEndpoint,
      endsWith('/source-catalog-v9.json'),
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('    - config/source-catalog-v9.json'),
    );
  });

  test('known disabled source loads without becoming an active provider', () {
    final transport = ProviderTransport(
      client: MockClient((_) async => throw StateError('No HTTP permitted')),
    );
    addTearDown(transport.close);
    final providers = _providers(transport);
    final native = providers.whereType<OpenScoreLiederProvider>().single;
    expect(native.definition.enabledByDefault, isFalse);
    final runtime = _runtime(transport)
      ..apply(SourceCatalog.parse(_bundle(9)));
    expect(
      runtime.catalog!.sources
          .where((s) => s.adapter == 'builtin')
          .map((s) => s.id)
          .toSet(),
      providers.map((p) => p.definition.id).toSet(),
    );
    expect(
      runtime.providers.any((p) => p.definition.id == 'openscorelieder'),
      isFalse,
    );
  });

  for (final status in ['disabled', 'active']) {
    test('v8 runtime rejects $status OpenScore without cache mutation', () async {
      final downloaded = jsonDecode(_bundle(9)) as Map<String, dynamic>;
      (downloaded['sources'] as List).last['status'] = status;
      var cached = _bundle(8);
      var writes = 0;
      final transport = ProviderTransport(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(downloaded),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
        maxRetries: 0,
        hostInterval: Duration.zero,
      );
      addTearDown(transport.close);
      final runtime = _runtime(transport, oldRuntime: true);
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => _bundle(8),
        readCache: () async => cached,
        writeCache: (text) async {
          writes++;
          cached = text;
        },
        endpoint: Uri.parse(
          'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog-v8.json',
        ),
      );
      await client.initialize();
      final prior = runtime.catalog;
      final priorProviders = runtime.providers;
      expect(await client.refresh(), isFalse);
      expect(identical(runtime.catalog, prior), isTrue);
      expect(identical(runtime.providers, priorProviders), isTrue);
      expect(cached, _bundle(8));
      expect(writes, 0);
    });
  }

  test('unknown disabled builtin still rejects atomically in v9', () {
    final transport = ProviderTransport(
      client: MockClient((_) async => throw StateError('No HTTP permitted')),
    );
    addTearDown(transport.close);
    final runtime = _runtime(transport)
      ..apply(SourceCatalog.parse(_bundle(9)));
    final prior = runtime.catalog;
    final providers = runtime.providers;
    final next = jsonDecode(_bundle(9)) as Map<String, dynamic>;
    next['revision'] = 23;
    (next['sources'] as List).add({
      ...((next['sources'] as List).last as Map),
      'id': 'uncompiledcandidate',
    });
    expect(() => runtime.apply(SourceCatalog.fromJson(next)), throwsStateError);
    expect(identical(runtime.catalog, prior), isTrue);
    expect(identical(runtime.providers, providers), isTrue);
  });

  test('offline maintenance derives the complete v9 registry without HTTP', () async {
    var calls = 0;
    final transport = ProviderTransport(
      client: MockClient((_) async {
        calls++;
        throw StateError('Offline gate must not issue HTTP');
      }),
    );
    addTearDown(transport.close);
    final providers = _providers(transport);
    final runtime = _runtime(transport)
      ..apply(SourceCatalog.parse(_bundle(9)));
    final allProviders = [...providers, ...runtime.providers];
    final report = await SourceMaintenanceHarness(
      providers: allProviders,
    ).run(runtime.catalog!, offline: true);
    final rows = (report['sources'] as List).cast<Map>();
    expect(
      rows.map((r) => r['id']).toSet(),
      allProviders.map((p) => p.definition.id).toSet(),
    );
    expect(rows.where((r) => r['status'] == 'coverage_gap'), isEmpty);
    expect(
      rows.singleWhere((r) => r['id'] == 'openscorelieder')['status'],
      'disabled',
    );
    expect(calls, 0);
  });
}
