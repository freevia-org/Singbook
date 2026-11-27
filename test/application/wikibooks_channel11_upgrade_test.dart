import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/source_catalog_client.dart';
import 'package:singbook/providers/transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test(
    'oldest cache, saved data and opt-outs survive a gated channel11 upgrade',
    () async {
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final currentText = File(
        SourceCatalogClient.bundledAsset,
      ).readAsStringSync();
      final current = jsonDecode(currentText) as Map<String, dynamic>;
      final oldest =
          jsonDecode(File('config/source-catalog.json').readAsStringSync())
              as Map<String, dynamic>;
      oldest['revision'] = 9000;
      final repaired = (oldest['sources'] as List).first as Map;
      final repairedId = repaired['id'];
      repaired['revision'] = 1000;
      repaired['name'] = 'Cached oldest-channel repair';
      final oldestText = jsonEncode(oldest);
      await repo.setSetting(SourceCatalogClient.legacyCacheKey, oldestText);
      final channel = int.parse(SourceCatalogClient.cacheKey.split(':v').last);
      for (var previous = 2; previous < channel; previous++) {
        await repo.setSetting(
          'sourceCatalog:v$previous',
          'invalid cached envelope',
        );
      }
      await repo.setSetting('app', {
        'providers': {'wikibooksliederbuch': false, 'future-source': false},
        'themeMode': 'dark',
      });
      await repo.saveSong(
        SongDocument(
          id: 'saved-before-channel11',
          title: 'Saved title',
          artist: 'Saved artist',
          body: '[C]Synthetic saved words',
          metadata: {'album': 'Preserved album'},
          extra: {
            'preservedUnknownField': {
              'nested': ['keep', 42],
            },
          },
        ),
      );
      final before = jsonEncode((await repo.listSongs()).single.toJson());
      final published = jsonDecode(currentText) as Map<String, dynamic>;
      published['revision'] = (published['revision'] as int) + 1;
      final book = (published['sources'] as List).cast<Map>().singleWhere(
        (row) => row['id'] == 'wikibooksliederbuch',
      );
      book['revision'] = (book['revision'] as int) + 1;
      book['status'] = 'active';
      book['enabledByDefault'] = true;
      var requests = 0;
      final transport = ProviderTransport(
        client: MockClient((request) async {
          requests++;
          expect(request.url.host, 'raw.githubusercontent.com');
          expect(request.url.path, endsWith('/source-catalog-v11.json'));
          return http.Response(
            jsonEncode(published),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      var app = AppController(repository: repo, transport: transport);
      try {
        await app.initialize();
        final migrated = app.discovery.catalogClient!.runtime.catalog!;
        expect(migrated.revision, current['revision']);
        expect(
          migrated.sources.singleWhere((s) => s.id == repairedId).name,
          'Cached oldest-channel repair',
        );
        expect(
          migrated.sources
              .singleWhere((s) => s.id == 'wikibooksliederbuch')
              .status,
          'disabled',
        );
        expect(requests, 0);
        expect(app.providerEnabled('wikibooksliederbuch'), false);
        expect(await app.refreshSources(), true);
        expect(app.providers.any((p) => p.id == 'wikibooksliederbuch'), true);
        expect(app.providerEnabled('wikibooksliederbuch'), false);
        expect((app.settings['providers'] as Map)['future-source'], false);
        expect(
          await repo.getSetting(SourceCatalogClient.legacyCacheKey),
          oldestText,
        );
        expect(jsonEncode((await repo.listSongs()).single.toJson()), before);
        app.dispose();
        app = AppController(repository: repo, transport: transport);
        await app.initialize();
        expect(app.providerEnabled('wikibooksliederbuch'), false);
        expect((app.settings['providers'] as Map)['future-source'], false);
        expect(
          await repo.getSetting(SourceCatalogClient.legacyCacheKey),
          oldestText,
        );
        expect(jsonEncode((await repo.listSongs()).single.toJson()), before);
        expect(requests, 1);
      } finally {
        app.dispose();
        await transport.close();
        await repo.close();
      }
    },
  );
}
