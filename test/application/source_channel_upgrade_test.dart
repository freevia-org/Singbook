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
    'fresh offline bootstrap exposes new channel5 sources enabled by default',
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
        expect(app.providerEnabled('vocadb'), true);
        expect(app.providerEnabled('touhoudb'), true);
        expect(app.providerEnabled('utaitedb'), true);
        for (final id in ['touhoudb', 'utaitedb']) {
          expect(app.providers.singleWhere((p) => p.id == id).configured, true);
        }
        expect(
          app.providers.singleWhere((p) => p.id == 'vocadb').configured,
          true,
        );
        expect(
          app.providers.singleWhere((p) => p.id == 'amll').configured,
          true,
        );
        expect(
          app.discovery.catalogClient!.runtime.catalog!.sources,
          hasLength(26),
        );
        expect(app.discovery.catalogClient!.runtime.catalog!.revision, 17);
        expect(requests, 0);
        await app.setProviderEnabled('amll', false);
        await app.setProviderEnabled('vocadb', false);
        await app.setProviderEnabled('touhoudb', false);
        await app.setProviderEnabled('utaitedb', false);
        expect(app.providerEnabled('amll'), false);
        expect(app.providerEnabled('vocadb'), false);
        expect(app.providerEnabled('touhoudb'), false);
        expect(app.providerEnabled('utaitedb'), false);
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
    'real bootstrap upgrades populated libraries into channel5 without changing older streams or choices',
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
      final old3 =
          jsonDecode(File('config/source-catalog-v3.json').readAsStringSync())
              as Map<String, dynamic>;
      old3['revision'] = 4000;
      final old3Text = jsonEncode(old3);
      await repo.setSetting(SourceCatalogClient.channel3CacheKey, old3Text);
      final old4 =
          jsonDecode(File('config/source-catalog-v4.json').readAsStringSync())
              as Map<String, dynamic>;
      old4['revision'] = 5000;
      final old4Text = jsonEncode(old4);
      await repo.setSetting(SourceCatalogClient.channel4CacheKey, old4Text);
      await repo.setSetting('app', {
        'providers': {
          'lrclib': false,
          'karamoe': false,
          'amll': false,
          'vocadb': false,
          'touhoudb': false,
          'utaitedb': false,
          'worshiptogether': true,
        },
        'themeMode': 'dark',
      });
      final song = SongDocument(
        id: 'preserved-user-song',
        title: 'Saved title',
        artist: 'Saved artist',
        body: '[C]My original words',
        metadata: {'album': 'Saved album', 'tempo': 90},
        sources: [
          SourceResult(
            candidate: const SongCandidate(
              providerId: 'lrclib',
              id: 'saved-source',
              title: 'Saved title',
              artist: 'Saved artist',
            ),
            body: '[C]My original words',
            attribution: 'Synthetic prior-source attribution',
            extra: {
              'originalPayload': {
                'contentType': 'text/plain',
                'encoding': 'utf-8',
                'base64': base64Encode(
                  utf8.encode('Synthetic original source payload'),
                ),
              },
              'rights': {'license': 'unknown'},
            },
          ),
        ],
        timingTracks: const [
          TimingTrack(
            id: 'saved-timing',
            sourceDocumentId: 'lrclib:saved-source',
            sourceLyrics: 'My original words',
            format: 'lrc',
            raw: '[00:01.00]My original words',
            cues: [
              TimingCue(
                id: 'saved-cue',
                occurrenceId: 'line-0',
                text: 'My original words',
                startUs: 1000000,
                endUs: 2000000,
              ),
            ],
          ),
        ],
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
        expect(await repo.getSetting(SourceCatalogClient.cacheKey), isNull);
        expect(app.discovery.catalogClient!.runtime.catalog!.revision, 17);
        expect(
          app.discovery.catalogClient!.runtime.catalog!.sources,
          hasLength(26),
        );
        await app.refreshSources();
        expect(app.discovery.catalogClient!.lastErrorCode, isNull);
        expect(seen.single.path, endsWith('/source-catalog-v5.json'));
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
        expect(
          await repo.getSetting(SourceCatalogClient.channel3CacheKey),
          old3Text,
        );
        expect(
          await repo.getSetting(SourceCatalogClient.channel4CacheKey),
          old4Text,
        );
        expect(app.providerEnabled('lrclib'), false);
        expect(app.providerEnabled('karamoe'), false);
        expect(app.providerEnabled('amll'), false);
        expect(app.providerEnabled('vocadb'), false);
        expect(app.providerEnabled('touhoudb'), false);
        expect(app.providerEnabled('utaitedb'), false);
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
        for (final id in [
          'lrcred',
          'roswellmusicjam',
          'karamoe',
          'amll',
          'vocadb',
        ]) {
          expect(app.providers.any((p) => p.id == id), true);
        }
        expect(app.providerEnabled('lrcred'), true);
        expect(app.providerEnabled('roswellmusicjam'), true);
        expect(jsonEncode((await repo.listSongs()).single.toJson()), before);
        expect(await repo.getSetting(SourceCatalogClient.cacheKey), nextText);
        expect(await repo.getSetting('sourceCatalog'), old1Text);
        expect(
          await repo.getSetting(SourceCatalogClient.channel2CacheKey),
          old2Text,
        );
        expect(
          await repo.getSetting(SourceCatalogClient.channel3CacheKey),
          old3Text,
        );
        expect(
          await repo.getSetting(SourceCatalogClient.channel4CacheKey),
          old4Text,
        );
        expect(app.songs.single.id, 'preserved-user-song');

        app.dispose();
        app = AppController(repository: repo, transport: transport);
        await app.initialize();
        expect(
          app.discovery.catalogClient!.runtime.catalog!.revision,
          nextRevision,
        );
        expect(
          app.discovery.catalogClient!.runtime.catalog!.sources,
          hasLength(26),
        );
        expect(app.providerEnabled('amll'), false);
        expect(app.providerEnabled('vocadb'), false);
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
