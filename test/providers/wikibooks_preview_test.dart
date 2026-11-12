import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/extra/wikibooks_preview.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';

SourceCatalog _catalog() => SourceCatalog.parse(
  File(SourceCatalogClient.bundledAsset).readAsStringSync(),
);

ProviderTransport _transport(void Function() onRequest) => ProviderTransport(
  client: MockClient((_) async {
    onRequest();
    throw StateError('Preview profile must stay offline');
  }),
  maxRetries: 0,
  hostInterval: Duration.zero,
);

Future<WikibooksLiederbuchPreview> _preview({
  required SourceCatalog catalog,
  required List<LyricsProvider> providers,
  required ProviderTransport transport,
  required Map<String, Object?> settings,
  Future<void> Function(String, Object?)? write,
  DateTime Function()? clock,
}) => WikibooksLiederbuchPreview.create(
  productionCatalog: catalog,
  compiledProviders: providers,
  transport: transport,
  readSetting: (key) async => settings[key],
  writeSetting: (key, value) async {
    if (write != null) {
      await write(key, value);
    } else {
      settings[key] = value;
    }
  },
  clock: clock,
);

void main() {
  test(
    'production roster and current catalog stay unchanged; preview is separate',
    () async {
      var requests = 0;
      final transport = _transport(() => requests++);
      addTearDown(transport.close);
      final compiled = [
        ...createCoreProviders(transport: transport),
        ...createExtraProviders(transport: transport),
      ];
      final production = _catalog();
      final productionJson = jsonEncode(production.toJson());
      final productionIds = compiled.map((p) => p.definition.id).toSet();

      expect(
        productionIds,
        isNot(contains(WikibooksLiederbuchPreview.sourceId)),
      );
      expect(
        production.sources
            .where((entry) => entry.adapter == 'builtin')
            .map((entry) => entry.id)
            .toSet(),
        productionIds,
      );

      final preview = await _preview(
        catalog: production,
        providers: compiled,
        transport: transport,
        settings: {},
        clock: () => DateTime.utc(2026, 10, 29),
      );

      expect(jsonEncode(production.toJson()), productionJson);
      expect(
        productionIds,
        isNot(contains(WikibooksLiederbuchPreview.sourceId)),
      );
      final entry = preview.catalog.sources.singleWhere(
        (source) => source.id == WikibooksLiederbuchPreview.sourceId,
      );
      expect(entry.status, 'disabled');
      expect(entry.enabledByDefault, isFalse);
      expect(
        preview.runtime.providers.map((p) => p.definition.id),
        isNot(contains(WikibooksLiederbuchPreview.sourceId)),
      );
      expect(
        preview.compiledProviders.map((p) => p.definition.id),
        contains(WikibooksLiederbuchPreview.sourceId),
      );
      expect(preview.createDiscovery().catalogClient, isNull);
      expect(requests, 0);
    },
  );

  test('preview cache uses its own key and reuses matching snapshot', () async {
    var requests = 0;
    final transport = _transport(() => requests++);
    addTearDown(transport.close);
    final compiled = [
      ...createCoreProviders(transport: transport),
      ...createExtraProviders(transport: transport),
    ];
    final settings = <String, Object?>{
      SourceCatalogClient.cacheKey: 'untouched',
    };
    final first = await _preview(
      catalog: _catalog(),
      providers: compiled,
      transport: transport,
      settings: settings,
      clock: () => DateTime.utc(2026, 10, 29),
    );
    final serialized = settings[WikibooksLiederbuchPreview.cacheKey] as String;
    expect(first.usedCache, isFalse);
    expect(settings[SourceCatalogClient.cacheKey], 'untouched');

    final second = await _preview(
      catalog: _catalog(),
      providers: compiled,
      transport: transport,
      settings: settings,
      clock: () => DateTime.utc(2027, 1, 1),
    );
    expect(second.usedCache, isTrue);
    expect(second.cacheErrorCode, isNull);
    expect(settings[WikibooksLiederbuchPreview.cacheKey], serialized);
    expect(settings[SourceCatalogClient.cacheKey], 'untouched');
    expect(requests, 0);
  });

  test('edited cache cannot activate the preview source', () async {
    var requests = 0;
    final transport = _transport(() => requests++);
    addTearDown(transport.close);
    final compiled = [
      ...createCoreProviders(transport: transport),
      ...createExtraProviders(transport: transport),
    ];
    final original = _catalog();
    final staleSettings = <String, Object?>{};
    await _preview(
      catalog: original,
      providers: compiled,
      transport: transport,
      settings: staleSettings,
      clock: () => DateTime.utc(2026, 10, 29),
    );
    final poisoned =
        jsonDecode(staleSettings[WikibooksLiederbuchPreview.cacheKey] as String)
            as Map<String, dynamic>;
    final entries = (poisoned['sources'] as List).cast<Map<String, dynamic>>();
    final book = entries.singleWhere(
      (entry) => entry['id'] == WikibooksLiederbuchPreview.sourceId,
    );
    book['status'] = 'active';
    book['enabledByDefault'] = true;
    staleSettings[WikibooksLiederbuchPreview.cacheKey] = jsonEncode(poisoned);

    final result = await _preview(
      catalog: original,
      providers: compiled,
      transport: transport,
      settings: staleSettings,
      clock: () => DateTime.utc(2026, 10, 30),
    );

    expect(result.usedCache, isFalse);
    expect(result.cacheErrorCode, 'invalid_response');
    final safeBook = result.catalog.sources.singleWhere(
      (entry) => entry.id == WikibooksLiederbuchPreview.sourceId,
    );
    expect(safeBook.status, 'disabled');
    expect(safeBook.enabledByDefault, isFalse);
    expect(requests, 0);
  });

  test(
    'stale cache cannot override a repair or resurrect a removed source',
    () async {
      var requests = 0;
      final transport = _transport(() => requests++);
      addTearDown(transport.close);
      final compiled = [
        ...createCoreProviders(transport: transport),
        ...createExtraProviders(transport: transport),
      ];
      final original = _catalog();
      final originalJson = jsonEncode(original.toJson());
      final settings = <String, Object?>{};
      final cachedPreview = await _preview(
        catalog: original,
        providers: compiled,
        transport: transport,
        settings: settings,
        clock: () => DateTime.utc(2026, 10, 29),
      );
      expect(cachedPreview.usedCache, isFalse);

      final repairedJson = original.toJson();
      final repairedEntries = (repairedJson['sources'] as List)
          .cast<Map<String, dynamic>>();
      final repairTarget = repairedEntries.firstWhere(
        (entry) => entry['id'] == 'chordsandtabs',
      );
      final repairedRevision = (repairTarget['revision'] as int) + 1;
      repairTarget['revision'] = repairedRevision;
      repairTarget['name'] = 'Repaired synthetic catalog entry';
      repairTarget['status'] = 'disabled';
      repairTarget['enabledByDefault'] = false;
      repairedEntries.removeWhere((entry) => entry['id'] == 'lyricsovh');
      repairedJson['revision'] = (repairedJson['revision'] as int) + 1;
      final repaired = SourceCatalog.fromJson(repairedJson);
      final result = await _preview(
        catalog: repaired,
        providers: compiled,
        transport: transport,
        settings: settings,
        clock: () => DateTime.utc(2026, 10, 30),
      );

      expect(result.usedCache, isFalse);
      expect(result.cacheErrorCode, 'invalid_response');
      final retainedRepair = result.catalog.sources.singleWhere(
        (entry) => entry.id == 'chordsandtabs',
      );
      expect(retainedRepair.revision, repairedRevision);
      expect(retainedRepair.name, 'Repaired synthetic catalog entry');
      expect(retainedRepair.status, 'disabled');
      expect(retainedRepair.enabledByDefault, isFalse);
      expect(
        result.catalog.sources.any((entry) => entry.id == 'lyricsovh'),
        isFalse,
      );
      expect(jsonEncode(original.toJson()), originalJson);
      expect(requests, 0);
    },
  );

  test('source ID collision is rejected before cache access', () async {
    var requests = 0;
    var cacheReads = 0;
    final transport = _transport(() => requests++);
    addTearDown(transport.close);
    final compiled = [
      ...createCoreProviders(transport: transport),
      ...createExtraProviders(transport: transport),
    ];
    final json = _catalog().toJson();
    (json['sources'] as List).add({
      'id': WikibooksLiederbuchPreview.sourceId,
      'name': 'Conflicting source',
      'adapter': 'builtin',
      'status': 'disabled',
      'revision': 1,
      'capabilities': ['lyrics'],
      'enabledByDefault': false,
      'accessMode': 'publicApi',
      'website': 'https://de.wikibooks.org/wiki/Liederbuch',
      'hosts': <String>[],
      'changeReason': 'Synthetic collision fixture.',
    });
    await expectLater(
      WikibooksLiederbuchPreview.create(
        productionCatalog: SourceCatalog.fromJson(json),
        compiledProviders: compiled,
        transport: transport,
        readSetting: (_) async {
          cacheReads++;
          return null;
        },
        writeSetting: (_, _) async {},
      ),
      throwsStateError,
    );
    expect(cacheReads, 0);
    expect(requests, 0);
  });

  test(
    'cache write failure leaves a usable disabled offline preview',
    () async {
      var requests = 0;
      final transport = _transport(() => requests++);
      addTearDown(transport.close);
      final compiled = [
        ...createCoreProviders(transport: transport),
        ...createExtraProviders(transport: transport),
      ];
      final result = await _preview(
        catalog: _catalog(),
        providers: compiled,
        transport: transport,
        settings: {},
        write: (_, _) async => throw StateError('Synthetic cache failure'),
      );
      expect(result.cacheErrorCode, 'cache_write_failed');
      expect(result.usedCache, isFalse);
      expect(
        result.catalog.sources
            .singleWhere(
              (entry) => entry.id == WikibooksLiederbuchPreview.sourceId,
            )
            .status,
        'disabled',
      );
      expect(requests, 0);
    },
  );
}
