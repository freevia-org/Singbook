import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';

void main() {
  sqfliteFfiInit();
  test('pending network refresh does not gate local library startup', () async {
    final repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    final pending = Completer<http.Response>();
    final requested = Completer<void>();
    final transport = ProviderTransport(
      client: MockClient((_) {
        if (!requested.isCompleted) requested.complete();
        return pending.future;
      }),
    );
    final catalog = jsonEncode({
      'schemaVersion': 1,
      'extractionSchemaVersion': 1,
      'revision': 1,
      'providers': <Object>[],
    });
    final runtime = SourceCatalogRuntime(
      builtins: [],
      createProvider: (_) => throw StateError('unused'),
    );
    final client = SourceCatalogClient(
      runtime: runtime,
      transport: transport,
      loadBundled: () async => catalog,
      readCache: () async => null,
      writeCache: (_) async {},
    );
    final app = AppController(
      repository: repo,
      discovery: SourceDiscoveryService([], catalogClient: client),
    );
    try {
      await app.initialize().timeout(const Duration(seconds: 2));
      await requested.future.timeout(const Duration(seconds: 2));
      expect(app.initialized, isTrue);
      expect(app.songs, isEmpty);
      expect(pending.isCompleted, isFalse);
    } finally {
      if (!pending.isCompleted) pending.complete(http.Response(catalog, 200));
      await app.refreshSources();
      app.dispose();
      await transport.close();
      await repo.close();
    }
  });
}
