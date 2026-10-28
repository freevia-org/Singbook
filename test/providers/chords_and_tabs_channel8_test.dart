import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/chords_and_tabs.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';
import 'package:singbook/providers/source_maintenance.dart';
import 'package:singbook/providers/transport.dart';

void main() {
  final channel7File = File('config/source-catalog-v7.json');
  final channel8File = File('config/source-catalog-v8.json');

  test('channel8 adds a disabled Chords & Tabs entry without editing v7', () {
    final oldText = channel7File.readAsStringSync();
    expect(
      sha256.convert(utf8.encode(oldText)).toString(),
      'b192e129d56664ddc04fea41be863cbb9e4c9f92eb7b3e5b76717e2a0b171e76',
    );
    final old = jsonDecode(oldText) as Map<String, dynamic>;
    final next =
        jsonDecode(channel8File.readAsStringSync()) as Map<String, dynamic>;
    final oldSources = old['sources'] as List;
    final sources = next['sources'] as List;
    expect(oldSources, hasLength(28));
    expect(sources, hasLength(29));
    expect(sources.take(oldSources.length).toList(), oldSources);
    expect(next['revision'], 20);
    expect(DateTime.parse(next['publishedAt']).isUtc, isTrue);
    expect(
      DateTime.parse(next['publishedAt']).isAfter(
        DateTime.parse(old['publishedAt']),
      ),
      isTrue,
    );
    final entry = sources.last as Map;
    expect(entry['id'], 'chordsandtabs');
    expect(entry['adapter'], 'builtin');
    expect(entry['revision'], 1);
    expect(entry['status'], 'disabled');
    expect(entry['enabledByDefault'], false);
    expect(entry['accessMode'], 'publicPage');
    expect(entry['capabilities'], ['catalog', 'chords', 'lyrics', 'metadata']);
    expect(entry['website'], 'https://www.chords-and-tabs.net');
    expect(entry['hosts'], ['www.chords-and-tabs.net']);
    expect(entry['attribution'], 'Chords and Tabs');
    expect(entry['probes'], isEmpty);
    expect(SourceCatalogClient.bundledAsset, 'config/source-catalog-v8.json');
    expect(SourceCatalogClient.cacheKey, 'sourceCatalog:v8');
    expect(SourceCatalogClient.channel7CacheKey, 'sourceCatalog:v7');
    expect(
      SourceCatalogClient.defaultEndpoint,
      endsWith('/source-catalog-v8.json'),
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('    - config/source-catalog-v8.json'),
    );
  });

  test('new roster accepts v8 but an old v7 roster rejects it atomically', () {
    final transport = ProviderTransport(
      client: MockClient(
        (_) async => throw StateError('No HTTP in catalog checks'),
      ),
    );
    addTearDown(transport.close);
    final providers = [
      ...createCoreProviders(transport: transport),
      ...createExtraProviders(transport: transport),
    ];
    final native = providers.whereType<ChordsAndTabsProvider>().single;
    expect(native.definition.enabledByDefault, isFalse);
    final next = SourceCatalog.parse(channel8File.readAsStringSync());
    final currentRuntime = SourceCatalogRuntime(
      builtins: providers,
      createProvider: (entry) => ConfigurableProvider(entry, transport),
    );
    currentRuntime.apply(next);
    expect(
      currentRuntime.catalog!.sources.map((entry) => entry.id),
      contains('chordsandtabs'),
    );
    expect(
      currentRuntime.providers.any(
        (provider) => provider.definition.id == 'chordsandtabs',
      ),
      isFalse,
    );

    final oldProviders = providers
        .where((provider) => provider.definition.id != 'chordsandtabs')
        .toList();
    final oldRuntime = SourceCatalogRuntime(
      builtins: oldProviders,
      createProvider: (entry) => ConfigurableProvider(entry, transport),
    );
    final channel7 = SourceCatalog.parse(channel7File.readAsStringSync());
    oldRuntime.apply(channel7);
    final priorProviders = oldRuntime.providers;
    expect(() => oldRuntime.apply(next), throwsStateError);
    expect(identical(oldRuntime.catalog, channel7), isTrue);
    expect(identical(oldRuntime.providers, priorProviders), isTrue);
  });

  test('channel8 offline maintenance covers every compiled provider', () async {
    final transport = ProviderTransport(
      client: MockClient(
        (_) async => throw StateError('Offline gate must not request'),
      ),
    );
    addTearDown(transport.close);
    final providers = [
      ...createCoreProviders(transport: transport),
      ...createExtraProviders(transport: transport),
    ];
    final catalog = SourceCatalog.parse(channel8File.readAsStringSync());
    final runtime = SourceCatalogRuntime(
      builtins: providers,
      createProvider: (entry) => ConfigurableProvider(entry, transport),
    )..apply(catalog);
    final report = await SourceMaintenanceHarness(
      providers: [...providers, ...runtime.providers],
    ).run(catalog, offline: true);
    final rows = (report['sources'] as List).cast<Map>();
    expect(
      rows.map((row) => row['id']).toSet(),
      providers.map((provider) => provider.definition.id).toSet(),
    );
    expect(rows.where((row) => row['status'] == 'coverage_gap'), isEmpty);
    expect(
      rows.singleWhere((row) => row['id'] == 'chordsandtabs')['status'],
      'disabled',
    );
    expect(report['offline'], isTrue);
  });
}
