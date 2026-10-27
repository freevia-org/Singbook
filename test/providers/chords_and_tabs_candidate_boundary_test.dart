import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/chords_and_tabs.dart';
import 'package:singbook/providers/extra/extra_providers.dart'
    show createExtraProviders;
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';

Map<String, dynamic> _candidateEntry({bool enabledByDefault = false}) => {
  'id': 'chordsandtabs',
  'name': 'Chords and Tabs',
  'adapter': 'builtin',
  'status': 'active',
  'revision': 1,
  'capabilities': ['catalog', 'lyrics', 'chords', 'metadata'],
  'enabledByDefault': enabledByDefault,
  'accessMode': 'publicPage',
  'website': 'https://www.chords-and-tabs.net/',
  'attribution': 'Chords and Tabs',
  'description': 'Candidate native chart adapter; rights remain unverified.',
  'hosts': <String>[],
  'changeReason': 'Isolated candidate qualification; opt-in only.',
};

SourceCatalog _candidateSnapshot(
  SourceCatalog previous, {
  bool enabledByDefault = false,
}) {
  final json = previous.toJson();
  final sources = List<Map<String, dynamic>>.from(
    (json['sources'] as List).map(
      (entry) => Map<String, dynamic>.from(entry as Map),
    ),
  )..add(_candidateEntry(enabledByDefault: enabledByDefault));
  return SourceCatalog.fromJson({
    ...json,
    'revision': previous.revision + 1,
    'publishedAt': '2026-10-28T12:00:00.000Z',
    'sources': sources,
  });
}

List<LyricsProvider> _builtins(ProviderTransport transport) => [
  ...createCoreProviders(transport: transport),
  ...createExtraProviders(transport: transport),
];

void main() {
  test(
    'published v7 roster remains 28 sources and omits the candidate',
    () async {
      final transport = ProviderTransport(
        client: MockClient(
          (_) async => throw StateError('Must remain offline'),
        ),
        hostInterval: Duration.zero,
      );
      addTearDown(transport.close);
      final v7 = SourceCatalog.parse(
        File('config/source-catalog-v7.json').readAsStringSync(),
      );
      expect(v7.sources, hasLength(28));
      expect(
        v7.sources.map((source) => source.id),
        isNot(contains('chordsandtabs')),
      );

      final runtime = SourceCatalogRuntime(
        builtins: _builtins(transport),
        createProvider: (entry) => ConfigurableProvider(entry, transport),
      )..apply(v7);
      expect(
        runtime.providers.map((provider) => provider.definition.id).toSet(),
        v7.sources
            .where((source) => source.isActive)
            .map((source) => source.id)
            .toSet(),
      );
      expect(runtime.providers.whereType<ChordsAndTabsProvider>(), isEmpty);
    },
  );

  test(
    'candidate native adapter is catalogued but disabled by default',
    () async {
      final transport = ProviderTransport(
        client: MockClient(
          (_) async => throw StateError('Must remain offline'),
        ),
        hostInterval: Duration.zero,
      );
      addTearDown(transport.close);
      final v7 = SourceCatalog.parse(
        File('config/source-catalog-v7.json').readAsStringSync(),
      );
      final candidate = _candidateSnapshot(v7);
      expect(candidate.sources, hasLength(29));

      final runtime = SourceCatalogRuntime(
        builtins: _builtins(transport),
        createProvider: (entry) => ConfigurableProvider(entry, transport),
      )..apply(candidate);
      final provider = runtime.providers.singleWhere(
        (item) => item.definition.id == 'chordsandtabs',
      );
      expect(provider, isA<ConfiguredBuiltinProvider>());
      expect(provider.definition.enabledByDefault, isFalse);
      expect(
        provider.definition.capabilities,
        containsAll(['lyrics', 'chords']),
      );
      expect(
        (provider as ConfiguredBuiltinProvider).delegate,
        isA<ChordsAndTabsProvider>(),
      );
      // Only the explicitly supplied candidate configuration enables it;
      // the compiled factory and the published v7 roster stay unchanged.
      final optedIn = _candidateSnapshot(v7, enabledByDefault: true).toJson()
        ..['revision'] = candidate.revision + 1;
      ((optedIn['sources'] as List).singleWhere(
                (entry) => entry['id'] == 'chordsandtabs',
              )
              as Map)['revision'] =
          2;
      runtime.apply(SourceCatalog.fromJson(optedIn));
      expect(
        runtime.providers
            .singleWhere((item) => item.definition.id == 'chordsandtabs')
            .definition
            .enabledByDefault,
        isTrue,
      );
      expect(
        _builtins(transport)
            .singleWhere((item) => item.definition.id == 'chordsandtabs')
            .definition
            .enabledByDefault,
        isFalse,
      );
    },
  );

  test(
    'runtime without the native ID rejects the candidate atomically',
    () async {
      final transport = ProviderTransport(
        client: MockClient(
          (_) async => throw StateError('Must remain offline'),
        ),
        hostInterval: Duration.zero,
      );
      addTearDown(transport.close);
      final v7 = SourceCatalog.parse(
        File('config/source-catalog-v7.json').readAsStringSync(),
      );
      final oldBuiltins = _builtins(
        transport,
      ).where((provider) => provider.definition.id != 'chordsandtabs').toList();
      final runtime = SourceCatalogRuntime(
        builtins: oldBuiltins,
        createProvider: (entry) => ConfigurableProvider(entry, transport),
      )..apply(v7);
      final oldProviders = runtime.providers;
      final candidate = _candidateSnapshot(v7);

      expect(() => runtime.apply(candidate), throwsA(isA<StateError>()));
      expect(identical(runtime.catalog, v7), isTrue);
      expect(identical(runtime.providers, oldProviders), isTrue);
      expect(
        runtime.providers.map((provider) => provider.definition.id).toSet(),
        v7.sources
            .where((source) => source.isActive)
            .map((source) => source.id)
            .toSet(),
      );
    },
  );
}
