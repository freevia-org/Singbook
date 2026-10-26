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
    'real bootstrap uses channel2 asset/cache and preserves legacy library/settings',
    () async {
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final legacy =
          jsonDecode(File('config/source-catalog.json').readAsStringSync())
              as Map<String, dynamic>;
      legacy['revision'] = 1000;
      final legacyText = jsonEncode(legacy);
      await repo.setSetting('sourceCatalog', legacyText);
      await repo.setSetting('app', {
        'providers': {'lrclib': false, 'worshiptogether': true},
        'themeMode': 'dark',
      });
      final song = SongDocument(
        id: 'preserved-user-song',
        title: 'Saved title',
        artist: 'Saved artist',
        body: '[C]My original words',
      );
      await repo.saveSong(song);
      final before = jsonEncode((await repo.listSongs()).single.toJson());
      final next =
          jsonDecode(File(SourceCatalogClient.bundledAsset).readAsStringSync())
              as Map<String, dynamic>;
      next['revision'] = 9;
      final nextText = jsonEncode(next);
      final seen = <Uri>[];
      final transport = ProviderTransport(
        client: MockClient((r) async {
          seen.add(r.url);
          return http.Response(nextText, 200);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final app = AppController(repository: repo, transport: transport);
      try {
        await app.initialize();
        await app.refreshSources();
        expect(seen.single.path, endsWith('/source-catalog-v2.json'));
        expect(app.discovery.catalogClient!.runtime.catalog!.revision, 9);
        expect(await repo.getSetting('sourceCatalog'), legacyText);
        expect(await repo.getSetting(SourceCatalogClient.cacheKey), nextText);
        expect(app.providerEnabled('lrclib'), false);
        expect(app.settings['themeMode'], 'dark');
        expect(
          ((await repo.getSetting('app') as Map)['providers']
              as Map)['worshiptogether'],
          true,
        );
        expect(
          app.providers.any((p) => p.id == 'lrcred'),
          false,
          reason: 'rollout remains disabled',
        );
        expect(jsonEncode((await repo.listSongs()).single.toJson()), before);
        expect(app.songs.single.id, 'preserved-user-song');
      } finally {
        app.dispose();
        await transport.close();
        await repo.close();
      }
    },
  );
}
