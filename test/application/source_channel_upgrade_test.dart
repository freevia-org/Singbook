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
    'fresh offline bootstrap exposes AMLL enabled without a consent step',
    () async {
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      var requests = 0;
      final transport = ProviderTransport(
        client: MockClient((_) async {
          requests++;
          return http.Response('offline', 503);
        }),
        maxRetries: 0,
      );
      final app = AppController(repository: repo, transport: transport);
      try {
        await app.initialize();
        expect(app.providerEnabled('amll'), true);
        expect(
          app.providers.singleWhere((p) => p.id == 'amll').configured,
          true,
        );
        expect(
          app.discovery.catalogClient!.runtime.catalog!.sources,
          hasLength(23),
        );
        expect(requests, 0);
        await app.setProviderEnabled('amll', false);
        expect(app.providerEnabled('amll'), false);
        expect(
          ((await repo.getSetting('app') as Map)['providers'] as Map)['amll'],
          false,
        );
      } finally {
        app.dispose();
        await transport.close();
        await repo.close();
      }
    },
  );
  test(
    'real bootstrap migrates to channel3 without changing legacy data or choices',
    () async {
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final old1 =
          jsonDecode(File('config/source-catalog.json').readAsStringSync())
              as Map<String, dynamic>;
      old1['revision'] = 2000;
      final old1Text = jsonEncode(old1);
      final old2 =
          jsonDecode(File('config/source-catalog-v2.json').readAsStringSync())
              as Map<String, dynamic>;
      old2['revision'] = 3000;
      final old2Text = jsonEncode(old2);
      await repo.setSetting('sourceCatalog', old1Text);
      await repo.setSetting(SourceCatalogClient.channel2CacheKey, old2Text);
      await repo.setSetting('app', {
        'providers': {
          'lrclib': false,
          'karamoe': false,
          'amll': false,
          'worshiptogether': true,
        },
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
      final nextRevision = (next['revision'] as int) + 1;
      next['revision'] = nextRevision;
      final nextText = jsonEncode(next);
      final seen = <Uri>[];
      final transport = ProviderTransport(
        client: MockClient((r) async {
          seen.add(r.url);
          return http.Response(
            nextText,
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
        await app.refreshSources();
        expect(app.discovery.catalogClient!.lastErrorCode, isNull);
        expect(seen.single.path, endsWith('/source-catalog-v3.json'));
        expect(
          app.discovery.catalogClient!.runtime.catalog!.revision,
          nextRevision,
        );
        expect(await repo.getSetting('sourceCatalog'), old1Text);
        expect(
          await repo.getSetting(SourceCatalogClient.channel2CacheKey),
          old2Text,
        );
        expect(await repo.getSetting(SourceCatalogClient.cacheKey), nextText);
        expect(app.providerEnabled('lrclib'), false);
        expect(app.providerEnabled('karamoe'), false);
        expect(app.providerEnabled('amll'), false);
        expect(
          app.discovery.catalogClient!.runtime.providers
              .singleWhere((p) => p.definition.id == 'amll')
              .definition
              .enabledByDefault,
          true,
        );
        expect(app.settings['themeMode'], 'dark');
        expect(
          ((await repo.getSetting('app') as Map)['providers']
              as Map)['worshiptogether'],
          true,
        );
        for (final id in ['lrcred', 'roswellmusicjam', 'karamoe', 'amll']) {
          expect(app.providers.any((p) => p.id == id), true);
        }
        expect(app.providerEnabled('lrcred'), true);
        expect(app.providerEnabled('roswellmusicjam'), true);
        expect(jsonEncode((await repo.listSongs()).single.toJson()), before);
        expect(app.songs.single.id, 'preserved-user-song');

        app.dispose();
        app = AppController(repository: repo, transport: transport);
        await app.initialize();
        expect(app.providerEnabled('amll'), false);
        expect(app.providerEnabled('lrclib'), false);
        expect(app.providerEnabled('karamoe'), false);
        expect(jsonEncode((await repo.listSongs()).single.toJson()), before);
      } finally {
        app.dispose();
        await transport.close();
        await repo.close();
      }
    },
  );
}
