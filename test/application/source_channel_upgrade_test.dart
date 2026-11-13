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
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/transport.dart';

SourceCatalog _currentCatalog() => SourceCatalog.parse(
  File(SourceCatalogClient.bundledAsset).readAsStringSync(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test(
    'offline current channel enables qualified Chords and Tabs and keeps OpenScore off',
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
        expect(app.providerEnabled('startjamming'), true);
        expect(app.providerEnabled('lyricsplus'), true);
        expect(app.providerEnabled('chordsandtabs'), true);
        expect(app.providerEnabled('pisni'), false);
        expect(app.providerEnabled('openscorelieder'), false);
        expect(app.providerEnabled('acousticbrainz'), true);
        for (final id in [
          'touhoudb',
          'utaitedb',
          'startjamming',
          'lyricsplus',
        ]) {
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
          app.providers.singleWhere((p) => p.id == 'chordsandtabs').configured,
          true,
        );
        expect(
          app.discovery.catalogClient!.runtime.catalog!.sources,
          hasLength(_currentCatalog().sources.length),
        );
        expect(
          app.discovery.catalogClient!.runtime.catalog!.revision,
          _currentCatalog().revision,
        );
        expect(requests, 0);
        await app.setProviderEnabled('amll', false);
        await app.setProviderEnabled('vocadb', false);
        await app.setProviderEnabled('touhoudb', false);
        await app.setProviderEnabled('utaitedb', false);
        await app.setProviderEnabled('startjamming', false);
        await app.setProviderEnabled('lyricsplus', false);
        await app.setProviderEnabled('chordsandtabs', false);
        await app.setProviderEnabled('pisni', false);
        await app.setProviderEnabled('openscorelieder', false);
        await app.setProviderEnabled('acousticbrainz', false);
        expect(app.providerEnabled('amll'), false);
        expect(app.providerEnabled('vocadb'), false);
        expect(app.providerEnabled('touhoudb'), false);
        expect(app.providerEnabled('utaitedb'), false);
        expect(app.providerEnabled('startjamming'), false);
        expect(app.providerEnabled('lyricsplus'), false);
        expect(app.providerEnabled('chordsandtabs'), false);
        expect(app.providerEnabled('pisni'), false);
        expect(app.providerEnabled('openscorelieder'), false);
        expect(app.providerEnabled('acousticbrainz'), false);
        expect(
          ((await repo.getSetting('app') as Map)['providers']
              as Map)['acousticbrainz'],
          false,
        );
        expect(
          ((await repo.getSetting('app') as Map)['providers'] as Map)['amll'],
          false,
        );
        expect(
          ((await repo.getSetting('app') as Map)['providers']
              as Map)['lyricsplus'],
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
    'bootstrap upgrades saved libraries to channel10 without changing old data',
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
      final old5 =
          jsonDecode(File('config/source-catalog-v5.json').readAsStringSync())
              as Map<String, dynamic>;
      old5['revision'] = 6000;
      final olderCachedSource = (old5['sources'] as List)
          .cast<Map>()
          .singleWhere((source) => source['id'] == 'lyricsovh');
      olderCachedSource['revision'] = 200;
      olderCachedSource['name'] = 'Older channel5 cached repair';
      final old5Text = jsonEncode(old5);
      await repo.setSetting(SourceCatalogClient.channel5CacheKey, old5Text);
      final old6 =
          jsonDecode(File('config/source-catalog-v6.json').readAsStringSync())
              as Map<String, dynamic>;
      old6['revision'] = 7000;
      final cachedSource = (old6['sources'] as List).cast<Map>().singleWhere(
        (source) => source['id'] == 'lyricsovh',
      );
      cachedSource['revision'] = 100;
      cachedSource['name'] = 'Closest channel6 cached repair';
      final old6Text = jsonEncode(old6);
      await repo.setSetting(SourceCatalogClient.channel6CacheKey, old6Text);
      final old7 =
          jsonDecode(File('config/source-catalog-v7.json').readAsStringSync())
              as Map<String, dynamic>;
      old7['revision'] = 8000;
      final old7Source = (old7['sources'] as List).cast<Map>().singleWhere(
        (source) => source['id'] == 'lyricsovh',
      );
      old7Source['revision'] = 300;
      old7Source['name'] = 'Closest channel7 cached repair';
      final old7Text = jsonEncode(old7);
      await repo.setSetting(SourceCatalogClient.channel7CacheKey, old7Text);
      final old8 =
          jsonDecode(File('config/source-catalog-v8.json').readAsStringSync())
              as Map<String, dynamic>;
      old8['revision'] = 9000;
      final old8Source = (old8['sources'] as List).cast<Map>().singleWhere(
        (source) => source['id'] == 'lyricsovh',
      );
      old8Source['revision'] = 400;
      old8Source['name'] = 'Closest channel8 cached repair';
      final old8Text = jsonEncode(old8);
      await repo.setSetting(SourceCatalogClient.channel8CacheKey, old8Text);
      await repo.setSetting('app', {
        'providers': {
          'lrclib': false,
          'karamoe': false,
          'amll': false,
          'vocadb': false,
          'touhoudb': false,
          'utaitedb': false,
          'startjamming': false,
          'lyricsplus': false,
          'chordsandtabs': false,
          'worshiptogether': true,
          'openscorelieder': false,
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
        expect(
          app.discovery.catalogClient!.runtime.catalog!.revision,
          _currentCatalog().revision,
        );
        expect(
          app.discovery.catalogClient!.runtime.catalog!.sources,
          hasLength(_currentCatalog().sources.length),
        );
        expect(
          app.providers
              .singleWhere((provider) => provider.id == 'lyricsovh')
              .name,
          'Closest channel8 cached repair',
        );
        expect(app.providerEnabled('lyricsplus'), false);
        expect(app.providerEnabled('chordsandtabs'), false);
        expect(
          app.providers
              .singleWhere((provider) => provider.id == 'chordsandtabs')
              .configured,
          true,
        );
        expect(app.providerEnabled('pisni'), false);
        expect(app.providerEnabled('openscorelieder'), false);
        expect(
          app.providers
              .singleWhere((provider) => provider.id == 'lyricsplus')
              .configured,
          true,
        );
        await app.refreshSources();
        expect(app.discovery.catalogClient!.lastErrorCode, isNull);
        expect(seen.single.path, endsWith('/source-catalog-v11.json'));
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
          await repo.getSetting(SourceCatalogClient.channel8CacheKey),
          old8Text,
        );
        expect(
          await repo.getSetting(SourceCatalogClient.channel6CacheKey),
          old6Text,
        );
        expect(
          await repo.getSetting(SourceCatalogClient.channel7CacheKey),
          old7Text,
        );
        expect(
          await repo.getSetting(SourceCatalogClient.channel3CacheKey),
          old3Text,
        );
        expect(
          await repo.getSetting(SourceCatalogClient.channel4CacheKey),
          old4Text,
        );
        expect(
          await repo.getSetting(SourceCatalogClient.channel5CacheKey),
          old5Text,
        );
        expect(app.providerEnabled('lrclib'), false);
        expect(app.providerEnabled('karamoe'), false);
        expect(app.providerEnabled('amll'), false);
        expect(app.providerEnabled('vocadb'), false);
        expect(app.providerEnabled('touhoudb'), false);
        expect(app.providerEnabled('utaitedb'), false);
        expect(app.providerEnabled('startjamming'), false);
        expect(app.providerEnabled('lyricsplus'), false);
        expect(app.providerEnabled('chordsandtabs'), false);
        expect(
          app.providers
              .singleWhere((provider) => provider.id == 'lyricsovh')
              .name,
          isNot('Closest channel8 cached repair'),
        );
        expect(
          app.discovery.catalogClient!.runtime.providers
              .singleWhere((p) => p.definition.id == 'startjamming')
              .definition
              .enabledByDefault,
          true,
        );
        expect(
          app.providers.singleWhere((p) => p.id == 'startjamming').configured,
          true,
        );
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
        expect(
          await repo.getSetting(SourceCatalogClient.channel8CacheKey),
          old8Text,
        );
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
        expect(
          await repo.getSetting(SourceCatalogClient.channel5CacheKey),
          old5Text,
        );
        expect(app.songs.single.id, 'preserved-user-song');
        expect(
          await repo.getSetting(SourceCatalogClient.channel6CacheKey),
          old6Text,
        );

        app.dispose();
        app = AppController(repository: repo, transport: transport);
        await app.initialize();
        expect(
          app.discovery.catalogClient!.runtime.catalog!.revision,
          nextRevision,
        );
        expect(
          app.discovery.catalogClient!.runtime.catalog!.sources,
          hasLength(_currentCatalog().sources.length),
        );
        expect(app.providerEnabled('amll'), false);
        expect(app.providerEnabled('vocadb'), false);
        expect(app.providerEnabled('lrclib'), false);
        expect(app.providerEnabled('karamoe'), false);
        expect(app.providerEnabled('startjamming'), false);
        expect(app.providerEnabled('lyricsplus'), false);
        expect(app.providerEnabled('chordsandtabs'), false);
        expect(app.providerEnabled('pisni'), false);
        expect(app.providerEnabled('openscorelieder'), false);
        expect(
          await repo.getSetting(SourceCatalogClient.channel6CacheKey),
          old6Text,
        );
        expect(
          await repo.getSetting(SourceCatalogClient.channel7CacheKey),
          old7Text,
        );
        expect(jsonEncode((await repo.listSongs()).single.toJson()), before);
      } finally {
        app.dispose();
        await transport.close();
        await repo.close();
      }
    },
  );
  test('saved OpenScore opt-out survives a later catalog activation', () async {
    final repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    await repo.setSetting('app', {
      'providers': {'openscorelieder': false},
      'themeMode': 'dark',
    });
    await repo.saveSong(
      SongDocument(
        id: 'saved-before-openscore',
        title: 'Saved user title',
        artist: 'Saved user artist',
        body: '[C]Original saved words',
        metadata: {'album': 'Saved user album'},
      ),
    );
    final before = jsonEncode((await repo.listSongs()).single.toJson());
    final next =
        jsonDecode(File(SourceCatalogClient.bundledAsset).readAsStringSync())
            as Map<String, dynamic>;
    next['revision'] = (next['revision'] as int) + 1;
    final source = (next['sources'] as List).cast<Map>().singleWhere(
      (s) => s['id'] == 'openscorelieder',
    );
    source['revision'] = 2;
    source['status'] = 'active';
    source['enabledByDefault'] = true;
    var calls = 0;
    final transport = ProviderTransport(
      client: MockClient((request) async {
        calls++;
        expect(request.url.path, endsWith('/source-catalog-v11.json'));
        return http.Response(
          jsonEncode(next),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      maxRetries: 0,
      hostInterval: Duration.zero,
    );
    var app = AppController(repository: repo, transport: transport);
    try {
      await app.initialize();
      expect(calls, 0);
      expect(app.providerEnabled('openscorelieder'), false);
      expect(await app.refreshSources(), isTrue);
      expect(
        app.providers.singleWhere((p) => p.id == 'openscorelieder').configured,
        true,
      );
      expect(
        app.discovery.catalogClient!.runtime.providers
            .singleWhere((p) => p.definition.id == 'openscorelieder')
            .definition
            .enabledByDefault,
        true,
      );
      expect(app.providerEnabled('openscorelieder'), false);
      expect(jsonEncode((await repo.listSongs()).single.toJson()), before);
      app.dispose();
      app = AppController(repository: repo, transport: transport);
      await app.initialize();
      expect(calls, 1);
      expect(
        app.providers.singleWhere((p) => p.id == 'openscorelieder').configured,
        true,
      );
      expect(app.providerEnabled('openscorelieder'), false);
      expect(jsonEncode((await repo.listSongs()).single.toJson()), before);
      expect(app.settings['themeMode'], 'dark');
      expect(
        ((await repo.getSetting('app') as Map)['providers']
            as Map)['openscorelieder'],
        false,
      );
    } finally {
      app.dispose();
      await transport.close();
      await repo.close();
    }
  });
}
