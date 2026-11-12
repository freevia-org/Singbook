import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:path/path.dart' as path;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/extra/wikibooks_preview.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test(
    'offline preview preserves opt-outs and saved source rights across reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'singbook-wikibooks-preview-',
      );
      final databasePath = path.join(directory.path, 'library.sqlite');
      LibraryRepository? repository;
      AppController? app;
      var requests = 0;
      final transport = ProviderTransport(
        client: MockClient((_) async {
          requests++;
          throw StateError('Preview preservation must stay offline');
        }),
        maxRetries: 0,
      );
      try {
        repository = await LibraryRepository.open(
          path: databasePath,
          factory: databaseFactoryFfi,
        );
        final productionText = File(
          SourceCatalogClient.bundledAsset,
        ).readAsStringSync();
        final compiled = [
          ...createCoreProviders(transport: transport),
          ...createExtraProviders(transport: transport),
        ];
        final cached = jsonDecode(productionText) as Map<String, dynamic>;
        cached['revision'] = (cached['revision'] as int) + 1;
        final cachedSources = (cached['sources'] as List)
            .cast<Map<String, dynamic>>();
        cachedSources.removeWhere((entry) => entry['id'] == 'genius');
        final repair = cachedSources.singleWhere(
          (entry) => entry['id'] == 'lyricsovh',
        );
        repair['revision'] = (repair['revision'] as int) + 1;
        repair['status'] = 'disabled';
        final effectiveProductionText = jsonEncode(cached);
        const preferences = {
          'providers': {
            'genius': false,
            'lrclib': false,
            WikibooksLiederbuchPreview.sourceId: false,
            'future-provider': false,
          },
          'themeMode': 'dark',
        };
        await repository.setSetting('app', preferences);
        await repository.setSetting(
          SourceCatalogClient.cacheKey,
          effectiveProductionText,
        );
        await repository.setSetting(
          SourceCatalogClient.legacyCacheKey,
          'Untouched legacy cache fixture',
        );
        final initialStore = repository;
        var productionWrites = 0;
        final productionClient = SourceCatalogClient(
          runtime: SourceCatalogRuntime(
            builtins: compiled,
            createProvider: (entry) => ConfigurableProvider(entry, transport),
          ),
          transport: transport,
          loadBundled: () async => productionText,
          readCache: () async =>
              await initialStore.getSetting(SourceCatalogClient.cacheKey)
                  as String?,
          writeCache: (_) async {
            productionWrites++;
          },
        );
        await productionClient.initialize();
        final production = productionClient.runtime.catalog!;
        expect(
          production.sources.any((entry) => entry.id == 'genius'),
          isFalse,
        );
        expect(
          production.sources
              .singleWhere((entry) => entry.id == 'lyricsovh')
              .status,
          'disabled',
        );
        const source = SourceResult(
          candidate: SongCandidate(
            providerId: WikibooksLiederbuchPreview.sourceId,
            id: '7123',
            title: 'Invented saved sheet',
            artist: 'Invented source credit',
          ),
          body: '[B]An invented line.\n[Bb]Another invented line.',
          attribution:
              'Synthetic contributor; contribution terms are separate.',
          extra: {
            'rights': {
              'license': 'unknown',
              'permissions': {
                'pageContributions': 'CC-BY-SA-4.0',
                'underlyingLyricsAndMusic': 'unknown',
              },
              'revision': 98765,
            },
            'originalResponseRaw': '{"fixture":"Invented source bytes"}',
            'wikibooksPageId': 7123,
            'wikibooksRevision': 98765,
          },
        );
        await repository.saveSong(
          SongDocument(
            id: 'saved-wikibooks-fixture',
            title: source.candidate.title,
            artist: source.candidate.artist,
            body: source.body,
            sources: const [source],
          ),
        );
        final savedJson = jsonEncode(
          (await repository.listSongs()).single.toJson(),
        );

        for (var boot = 0; boot < 2; boot++) {
          final store = repository!;
          final preview = await WikibooksLiederbuchPreview.create(
            productionCatalog: production,
            compiledProviders: compiled,
            transport: transport,
            readSetting: store.getSetting,
            writeSetting: store.setSetting,
            clock: () => DateTime.utc(2026, 10, 29, 12 + boot),
          );
          expect(preview.usedCache, boot == 1);
          app = AppController(
            repository: store,
            discovery: preview.createDiscovery(),
          );
          await app.initialize();
          expect(
            app.providerEnabled(WikibooksLiederbuchPreview.sourceId),
            isFalse,
          );
          expect(app.providerEnabled('genius'), isFalse);
          expect(app.providerEnabled('lrclib'), isFalse);
          expect(app.providerEnabled('lyricsovh'), isFalse);
          expect(await app.refreshSources(), isFalse);
          expect(await store.getSetting('app'), preferences);
          expect(
            await store.getSetting(SourceCatalogClient.cacheKey),
            effectiveProductionText,
          );
          expect(
            await store.getSetting(SourceCatalogClient.legacyCacheKey),
            'Untouched legacy cache fixture',
          );
          final saved = (await store.listSongs()).single;
          expect(jsonEncode(saved.toJson()), savedJson);
          final portable = ChordProCodec().decode(app.exportSong(saved));
          expect(portable.sources.single.toJson(), source.toJson());
          expect(
            portable
                .sources
                .single
                .extra['rights']['permissions']['underlyingLyricsAndMusic'],
            'unknown',
          );
          expect(requests, 0);
          expect(productionWrites, 0);
          if (boot == 0) {
            app.dispose();
            app = null;
            repository = null;
            await store.close();
            repository = await LibraryRepository.open(
              path: databasePath,
              factory: databaseFactoryFfi,
            );
          }
        }
      } finally {
        app?.dispose();
        await repository?.close();
        await transport.close();
        final parent = await Directory.systemTemp.resolveSymbolicLinks();
        final target = await directory.resolveSymbolicLinks();
        expect(path.isWithin(parent, target), isTrue);
        await directory.delete(recursive: true);
      }
    },
  );
}
