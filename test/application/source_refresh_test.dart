import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';

class _Catalog implements LyricsProvider {
  _Catalog(this.id);
  final String id;
  Completer<List<SongCandidate>>? pending;
  @override
  ProviderDefinition get definition =>
      ProviderDefinition(id: id, name: id, capabilities: {'catalog', 'lyrics'});
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) => pending?.future ?? Future.value([]);
  @override
  Future<SourceResult> resolve(
    SongCandidate song, {
    CancellationToken? cancel,
  }) async => SourceResult(candidate: song, body: 'Original words');
}

String _catalog(int revision, {bool retired = false}) => jsonEncode({
  'schemaVersion': 1,
  'extractionSchemaVersion': 1,
  'revision': revision,
  'publishedAt': '2026-10-15T00:00:00Z',
  'sources': [
    for (final id in ['genius', 'other'])
      {
        'id': id,
        'name': id,
        'adapter': 'builtin',
        'status': retired && id == 'genius' ? 'retired' : 'active',
        'revision': revision,
        'capabilities': ['catalog', 'lyrics'],
        'enabledByDefault': true,
        'accessMode': 'public',
        'website': 'https://music.example.org/',
        'hosts': <String>[],
      },
  ],
});

void main() {
  sqfliteFfiInit();
  test(
    'refresh retires lookup without deleting preferences or saved provenance; stale results lose',
    () async {
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      addTearDown(repo.close);
      final genius = _Catalog('genius'), other = _Catalog('other');
      var response = _catalog(1);
      final transport = ProviderTransport(
        client: MockClient((_) async => http.Response(response, 200)),
      );
      addTearDown(transport.close);
      final runtime = SourceCatalogRuntime(
        builtins: [genius, other],
        createProvider: (_) => throw StateError('unused'),
      );
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => _catalog(1),
        readCache: () async => null,
        writeCache: (text) => repo.setSetting('sourceCatalog', text),
      );
      final app = AppController(
        repository: repo,
        discovery: SourceDiscoveryService([
          genius,
          other,
        ], catalogClient: client),
      );
      addTearDown(app.dispose);
      await app.initialize();
      await app.refreshSources(); // Joins the startup download.
      await app.setProviderEnabled('genius', false);
      await app.saveSong(
        SongDocument(
          id: 'saved',
          title: 'Saved',
          artist: 'Artist',
          body: 'User words',
          sources: [
            SourceResult(
              candidate: SongCandidate(
                providerId: 'genius',
                id: '1',
                title: 'Saved',
                artist: 'Artist',
              ),
              body: 'Original words',
            ),
          ],
        ),
      );
      genius.pending = Completer<List<SongCandidate>>();
      final oldSearch = app.search('old search');
      response = _catalog(2, retired: true);
      expect(await app.refreshSources(), isTrue);
      expect(app.providers.map((p) => p.id), ['other']);
      expect(app.providerEnabled('genius'), isFalse);
      expect((app.settings['providers'] as Map)['genius'], isFalse);
      genius.pending!.complete([
        const SongCandidate(
          providerId: 'genius',
          id: 'stale',
          title: 'Wrong',
          artist: 'Old',
        ),
      ]);
      await oldSearch;
      expect(app.suggestions, isEmpty);
      final saved = (await repo.getSong('saved'))!;
      expect(saved.body, 'User words');
      expect(saved.sources.single.candidate.providerId, 'genius');
      response = _catalog(3);
      expect(await app.refreshSources(), isTrue);
      expect(
        app.providerEnabled('genius'),
        isFalse,
        reason: 'User preference survives retirement/reactivation',
      );
      response = '{broken';
      expect(await app.refreshSources(), isFalse);
      expect(client.runtime.catalog!.revision, 3);
      expect(
        SourceCatalog.parse(
          await repo.getSetting('sourceCatalog') as String,
        ).revision,
        3,
      );
    },
  );

  test(
    'search chooses another catalog after the preferred source retires',
    () async {
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      addTearDown(repo.close);
      final genius = _Catalog('genius'), other = _Catalog('other');
      final runtime = SourceCatalogRuntime(
        builtins: [genius, other],
        createProvider: (_) => throw StateError('unused'),
      );
      final transport = ProviderTransport(
        client: MockClient(
          (_) async => http.Response(_catalog(2, retired: true), 200),
        ),
      );
      addTearDown(transport.close);
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => _catalog(1),
        readCache: () async => null,
        writeCache: (_) async {},
      );
      final app = AppController(
        repository: repo,
        discovery: SourceDiscoveryService([
          genius,
          other,
        ], catalogClient: client),
      );
      addTearDown(app.dispose);
      await app.initialize();
      await app.refreshSources();
      other.pending = Completer<List<SongCandidate>>();
      final search = app.search('new search');
      other.pending!.complete([
        const SongCandidate(
          providerId: 'other',
          id: 'new',
          title: 'Found',
          artist: 'Us',
        ),
      ]);
      await search;
      expect(app.suggestions.single.providerId, 'other');
      expect(app.errorCode, isNull);
    },
  );
}
