import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';
import 'package:singbook/providers/source_maintenance.dart';
import 'package:singbook/providers/transport.dart';

void main() {
  final channel7File = File('config/source-catalog-v7.json');
  final channel8File = File('config/source-catalog-v8.json');

  test('channel8 activates qualified Chords and Tabs without editing v7', () {
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
    expect(sources, hasLength(30));
    expect(sources.take(oldSources.length).toList(), oldSources);
    expect(next['revision'], 21);
    expect(DateTime.parse(next['publishedAt']).isUtc, isTrue);
    expect(
      DateTime.parse(
        next['publishedAt'],
      ).isAfter(DateTime.parse(old['publishedAt'])),
      isTrue,
    );
    final chordsAndTabs = sources[oldSources.length] as Map;
    expect(chordsAndTabs['id'], 'chordsandtabs');
    expect(chordsAndTabs['adapter'], 'builtin');
    expect(chordsAndTabs['revision'], 2);
    expect(chordsAndTabs['status'], 'active');
    expect(chordsAndTabs['enabledByDefault'], true);
    expect(chordsAndTabs['accessMode'], 'publicPage');
    expect(chordsAndTabs['capabilities'], [
      'catalog',
      'chords',
      'lyrics',
      'metadata',
    ]);
    expect(chordsAndTabs['website'], 'https://www.chords-and-tabs.net');
    expect(chordsAndTabs['hosts'], ['www.chords-and-tabs.net']);
    expect(chordsAndTabs['attribution'], 'Chords and Tabs');
    expect(chordsAndTabs['probes'], hasLength(2));
    expect((chordsAndTabs['probes'] as List).map((probe) => probe['id']), [
      'hey-jude-beatles-chart-v4',
      'bohemian-rhapsody-queen-chart-v8',
    ]);
    final legacyChartProbe =
        (chordsAndTabs['probes'] as List).first as Map<String, dynamic>;
    final queenProbe =
        (chordsAndTabs['probes'] as List).last as Map<String, dynamic>;
    expect(legacyChartProbe['query'], 'Hey Jude');
    expect(legacyChartProbe['expectedArtist'], 'The Beatles');
    expect(queenProbe['query'], 'Bohemian Rhapsody');
    expect(queenProbe['expectedArtist'], 'Queen');
    expect(
      (legacyChartProbe['candidate'] as Map)['metadata'],
      containsPair('searchChartVersionHint', 4),
    );
    expect(
      (legacyChartProbe['candidate'] as Map)['metadata'],
      containsPair('searchChartTypeHint', 'chords'),
    );
    expect(
      (legacyChartProbe['candidate'] as Map)['metadata'],
      isNot(contains('sourceChartType')),
    );
    expect(
      legacyChartProbe['requiredFields'],
      containsAll(['body', 'chords', 'metadata']),
    );
    expect(
      legacyChartProbe['requiredMetadataFields'],
      containsAll(['identityScope', 'sourceChartType']),
    );
    final pisni = sources.last as Map;
    expect(pisni['id'], 'pisni');
    expect(pisni['adapter'], 'builtin');
    expect(pisni['revision'], 1);
    expect(pisni['status'], 'disabled');
    expect(pisni['enabledByDefault'], false);
    expect(pisni['accessMode'], 'publicPage');
    expect(pisni['capabilities'], ['catalog', 'chords', 'lyrics', 'metadata']);
    expect(pisni['website'], 'https://www.pisni.org.ua/');
    expect(pisni['hosts'], ['www.pisni.org.ua']);
    expect(pisni['probes'], isEmpty);
    expect(SourceCatalogClient.bundledAsset, 'config/source-catalog-v11.json');
    expect(SourceCatalogClient.cacheKey, 'sourceCatalog:v11');
    expect(SourceCatalogClient.channel8CacheKey, 'sourceCatalog:v8');
    expect(SourceCatalogClient.channel7CacheKey, 'sourceCatalog:v7');
    expect(
      SourceCatalogClient.defaultEndpoint,
      endsWith('/source-catalog-v11.json'),
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
      ...createExtraProviders(transport: transport).where(
        (provider) =>
            provider.definition.id != 'openscorelieder' &&
            provider.definition.id != 'acousticbrainz' &&
            provider.definition.id != 'wikibooksliederbuch',
      ),
    ];
    final native = providers.whereType<ChordsAndTabsProvider>().single;
    final pisniNative = providers.whereType<PisniProvider>().single;
    expect(native.definition.enabledByDefault, isFalse);
    expect(pisniNative.definition.enabledByDefault, isFalse);
    final next = SourceCatalog.parse(channel8File.readAsStringSync());
    final currentRuntime = SourceCatalogRuntime(
      builtins: providers,
      createProvider: (entry) => ConfigurableProvider(entry, transport),
    );
    currentRuntime.apply(next);
    expect(
      currentRuntime.catalog!.sources.map((entry) => entry.id),
      containsAll(['chordsandtabs', 'pisni']),
    );
    final configuredChordsAndTabs = currentRuntime.providers.singleWhere(
      (provider) => provider.definition.id == 'chordsandtabs',
    );
    expect(configuredChordsAndTabs, isA<ConfiguredBuiltinProvider>());
    expect(configuredChordsAndTabs.definition.enabledByDefault, isTrue);
    expect(
      currentRuntime.providers.any(
        (provider) => provider.definition.id == 'pisni',
      ),
      isFalse,
    );

    final oldProviders = providers
        .where(
          (provider) =>
              provider.definition.id != 'chordsandtabs' &&
              provider.definition.id != 'pisni',
        )
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
      ...createExtraProviders(transport: transport).where(
        (provider) =>
            provider.definition.id != 'openscorelieder' &&
            provider.definition.id != 'acousticbrainz' &&
            provider.definition.id != 'wikibooksliederbuch',
      ),
    ];
    final catalog = SourceCatalog.parse(channel8File.readAsStringSync());
    final runtime = SourceCatalogRuntime(
      builtins: providers,
      createProvider: (entry) => ConfigurableProvider(entry, transport),
    )..apply(catalog);
    final allProviders = [...providers, ...runtime.providers];
    final report = await SourceMaintenanceHarness(
      providers: allProviders,
    ).run(catalog, offline: true);
    final rows = (report['sources'] as List).cast<Map>();
    expect(
      rows.map((row) => row['id']).toSet(),
      allProviders.map((provider) => provider.definition.id).toSet(),
    );
    expect(rows.where((row) => row['status'] == 'coverage_gap'), isEmpty);
    expect(
      rows.singleWhere((row) => row['id'] == 'chordsandtabs')['status'],
      'offline_unverified',
    );
    expect(
      rows.singleWhere((row) => row['id'] == 'pisni')['status'],
      'disabled',
    );
    expect(report['offline'], isTrue);
  });
}
