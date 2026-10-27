import 'dart:async';
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
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/source_catalog.dart';

class _PendingCatalog implements LyricsProvider {
  final started = Completer<void>();
  final response = Completer<List<SongCandidate>>();
  @override
  final definition = const ProviderDefinition(
    id: 'pending',
    name: 'Pending source',
    capabilities: {'catalog', 'lyrics'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) {
    if (!started.isCompleted) started.complete();
    return response.future;
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw const ProviderException('unavailable');
}

Map<String, dynamic> bundle(String asset) =>
    jsonDecode(File(asset).readAsStringSync()) as Map<String, dynamic>;
Map<String, dynamic> source(Map<String, dynamic> catalog, String id) =>
    (catalog['sources'] as List).cast<Map<String, dynamic>>().singleWhere(
      (s) => s['id'] == id,
    );
Map<String, dynamic> cachedRepair() {
  final old = bundle('config/source-catalog-v2.json');
  old['revision'] = 9000;
  source(old, 'lrclib')
    ..['revision'] = 100
    ..['status'] = 'disabled';
  source(old, 'lyricsovh')
    ..['revision'] = 100
    ..['name'] = 'Cached offline repair';
  (old['sources'] as List).removeWhere((s) => s['id'] == 'genius');
  (old['sources'] as List).add({
    'id': 'cachedlyrics',
    'name': 'Cached custom source',
    'adapter': 'json',
    'status': 'active',
    'revision': 1,
    'capabilities': ['lyrics'],
    'enabledByDefault': true,
    'accessMode': 'publicApi',
    'website': 'https://lyrics.example.com/',
    'hosts': ['lyrics.example.com'],
    'attribution': 'Synthetic publisher',
    'extraction': {
      'search': {
        'url': 'https://lyrics.example.com/search?q={query}',
        'response': 'json',
        'itemsPath': 'results',
        'fields': {'id': 'id', 'title': 'title', 'artist': 'artist'},
      },
      'resolve': {
        'url': 'https://lyrics.example.com/song/{id}',
        'response': 'json',
        'fields': {'title': 'title', 'artist': 'artist', 'body': 'lyrics'},
      },
      'bodyFormat': 'plain',
    },
  });
  return old;
}

void main() {
  test(
    'authoritative refresh cancels pending search when migration changes content at the same envelope revision',
    () async {
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final provider = _PendingCatalog();
      Map<String, dynamic> entry(int revision, String name) => {
        'id': 'pending',
        'name': name,
        'revision': revision,
        'status': 'active',
        'adapter': 'builtin',
        'enabledByDefault': true,
        'capabilities': ['catalog', 'lyrics'],
        'accessMode': 'public',
        'website': 'https://example.org/',
        'hosts': <String>[],
      };
      String snapshot(int revision, Map<String, dynamic> source) => jsonEncode({
        'schemaVersion': 1,
        'extractionSchemaVersion': 1,
        'revision': revision,
        'publishedAt': '2026-10-27T00:00:00Z',
        'sources': [source],
      });
      final target = snapshot(10, entry(1, 'Current channel'));
      final pendingRefresh = Completer<http.Response>();
      final transport = ProviderTransport(
        client: MockClient((r) => pendingRefresh.future),
        maxRetries: 0,
      );
      final runtime = SourceCatalogRuntime(
        builtins: [provider],
        createProvider: (entry) => throw StateError('No declarative adapters'),
      );
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => target,
        readCache: () async => null,
        writeCache: (text) =>
            repo.setSetting(SourceCatalogClient.cacheKey, text),
        readPreviousCaches: () async => [
          (
            bundled: snapshot(2, entry(1, 'Current channel')),
            cached: snapshot(9000, entry(100, 'Old repair')),
          ),
        ],
      );
      final app = AppController(
        repository: repo,
        discovery: SourceDiscoveryService([provider], catalogClient: client),
      );
      Future<void>? search;
      try {
        await app.initialize();
        search = app.search('Saved query');
        await provider.started.future;
        expect(app.searching, true);
        expect(client.runtime.catalog!.revision, 10);
        pendingRefresh.complete(
          http.Response(
            target,
            200,
            headers: {'content-type': 'application/json'},
          ),
        );
        expect(await app.refreshSources(), true);
        expect(client.runtime.catalog!.revision, 10);
        expect(app.searching, false);
        provider.response.complete([
          const SongCandidate(
            providerId: 'pending',
            id: 'late',
            title: 'Late row',
            artist: 'Old source',
          ),
        ]);
        await search;
        expect(app.suggestions, isEmpty);
      } finally {
        if (!provider.response.isCompleted) provider.response.complete([]);
        if (!pendingRefresh.isCompleted) {
          pendingRefresh.complete(http.Response('offline', 503));
        }
        await search;
        app.dispose();
        await transport.close();
        await repo.close();
      }
    },
  );
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test(
    'offline upgrade retains compatible cached repairs, removals and additions until current-channel refresh commits',
    () async {
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final oldText = jsonEncode(cachedRepair());
      await repo.setSetting(SourceCatalogClient.channel2CacheKey, oldText);
      await repo.setSetting('app', {
        'providers': {'genius': false, 'amll': false},
        'themeMode': 'dark',
      });
      await repo.saveSong(
        SongDocument(
          id: 'old-song',
          title: 'Saved original',
          artist: 'Saved credit',
          body: '[C]Original words',
          metadata: {'album': 'Saved album'},
        ),
      );
      final saved = jsonEncode((await repo.listSongs()).single.toJson());
      var requests = 0, online = false;
      final currentText = jsonEncode(bundle(SourceCatalogClient.bundledAsset));
      ProviderTransport makeTransport() => ProviderTransport(
        client: MockClient((r) async {
          requests++;
          expect(
            r.url.path,
            endsWith('/${SourceCatalogClient.bundledAsset.split('/').last}'),
          );
          return http.Response(
            online ? currentText : 'offline',
            online ? 200 : 503,
            headers: {'content-type': 'application/json'},
          );
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      var transport = makeTransport();
      var app = AppController(repository: repo, transport: transport);
      void expectMigrated() {
        expect(app.providers.any((p) => p.id == 'lrclib'), false);
        expect(app.providers.any((p) => p.id == 'genius'), false);
        expect(
          app.providers.singleWhere((p) => p.id == 'lyricsovh').name,
          'Cached offline repair',
        );
        expect(app.providers.any((p) => p.id == 'cachedlyrics'), true);
        expect(app.providers.any((p) => p.id == 'amll'), true);
        expect(app.providerEnabled('amll'), false);
        expect(
          app.discovery.catalogClient!.runtime.catalog!.revision,
          jsonDecode(currentText)['revision'],
        );
      }

      try {
        await app.initialize();
        expectMigrated();
        expect(requests, 0);
        expect(await repo.getSetting(SourceCatalogClient.cacheKey), isNull);
        expect(await app.refreshSources(), false);
        expectMigrated();
        expect(
          await repo.getSetting(SourceCatalogClient.channel2CacheKey),
          oldText,
        );
        expect(await repo.getSetting(SourceCatalogClient.cacheKey), isNull);
        app.dispose();
        await transport.close();
        transport = makeTransport();
        app = AppController(repository: repo, transport: transport);
        await app.initialize();
        expectMigrated();
        // initialize schedules an existing background refresh. Join that
        // attempt before switching the network fixture online.
        expect(await app.refreshSources(), false);
        expect(requests, greaterThanOrEqualTo(2));
        final beforeCommit = requests;
        online = true;
        // Even an unchanged target-channel envelope is authoritative after a real,
        // successful refresh; the old envelope's 9000 cannot lock it out.
        expect(await app.refreshSources(), true);
        expect(requests, beforeCommit + 1);
        expect(app.providers.any((p) => p.id == 'lrclib'), true);
        expect(app.providers.any((p) => p.id == 'genius'), true);
        expect(app.providers.any((p) => p.id == 'cachedlyrics'), false);
        expect(
          app.providers.singleWhere((p) => p.id == 'lyricsovh').name,
          isNot('Cached offline repair'),
        );
        expect(
          await repo.getSetting(SourceCatalogClient.cacheKey),
          currentText,
        );
        expect(
          await repo.getSetting(SourceCatalogClient.channel2CacheKey),
          oldText,
        );
        app.dispose();
        await transport.close();
        transport = makeTransport();
        app = AppController(repository: repo, transport: transport);
        await app.initialize();
        expect(app.providers.any((p) => p.id == 'cachedlyrics'), false);
        expect(app.providerEnabled('genius'), false);
        expect(app.providerEnabled('amll'), false);
        expect(app.settings['themeMode'], 'dark');
        expect(jsonEncode((await repo.listSongs()).single.toJson()), saved);
        await app.refreshSources();
        expect(requests, greaterThan(beforeCommit + 1));
      } finally {
        app.dispose();
        await transport.close();
        await repo.close();
      }
    },
  );
  test(
    'unknown previous native entries cannot poison an offline upgrade',
    () async {
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final old = cachedRepair();
      (old['sources'] as List).add({
        ...source(old, 'lyricsovh'),
        'id': 'notcompiled',
      });
      final text = jsonEncode(old);
      await repo.setSetting(SourceCatalogClient.channel2CacheKey, text);
      var requests = 0;
      final transport = ProviderTransport(
        client: MockClient((r) async {
          requests++;
          throw StateError('Must stay offline');
        }),
        maxRetries: 0,
      );
      final app = AppController(repository: repo, transport: transport);
      try {
        await app.initialize();
        expect(app.providers.any((p) => p.id == 'amll'), true);
        expect(app.providers.any((p) => p.id == 'lrclib'), true);
        expect(app.providers.any((p) => p.id == 'cachedlyrics'), false);
        expect(requests, 0);
        expect(
          await repo.getSetting(SourceCatalogClient.channel2CacheKey),
          text,
        );
      } finally {
        app.dispose();
        await transport.close();
        await repo.close();
      }
    },
  );
}
