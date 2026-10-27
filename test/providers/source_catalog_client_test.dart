import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';

Map<String, dynamic> source({
  required String id,
  String? name,
  String adapter = 'builtin',
  String status = 'active',
  int revision = 1,
  List<String> capabilities = const ['lyrics'],
  List<String> hosts = const [],
  Map<String, dynamic>? extraction,
}) => {
  'id': id,
  'name': name ?? 'Source $id',
  'adapter': adapter,
  'status': status,
  'revision': revision,
  'capabilities': capabilities,
  'enabledByDefault': true,
  'accessMode': 'public',
  'website': 'https://music.example.org/',
  'hosts': hosts,
  'extraction': ?extraction,
};

String catalog(int revision, {List<Map<String, dynamic>>? sources}) =>
    jsonEncode({
      'schemaVersion': 1,
      'extractionSchemaVersion': 1,
      'revision': revision,
      'publishedAt': '2026-10-15T12:00:00.000Z',
      'sources': sources ?? [source(id: 'builtin-one')],
    });

class FakeProvider implements LyricsProvider {
  FakeProvider(this.definition);

  @override
  final ProviderDefinition definition;

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw const ProviderException('unavailable');
}

ProviderTransport makeTransport(
  Future<http.Response> Function(http.Request) respond,
) => ProviderTransport(
  client: MockClient(respond),
  hostInterval: Duration.zero,
  maxRetries: 0,
);

SourceCatalogRuntime makeRuntime({
  bool Function(SourceCatalogEntry entry)? rejectAdapter,
}) => SourceCatalogRuntime(
  builtins: [
    FakeProvider(
      const ProviderDefinition(
        id: 'builtin-one',
        name: 'Builtin one',
        capabilities: {'lyrics'},
      ),
    ),
  ],
  createProvider: (entry) {
    if (rejectAdapter?.call(entry) ?? false) {
      throw StateError('adapter rejected');
    }
    return FakeProvider(entry.definition);
  },
);

SourceCatalogClient makeClient({
  required SourceCatalogRuntime runtime,
  required ProviderTransport transport,
  required String bundled,
  String? Function()? cacheRead,
  Future<void> Function(String text)? cacheWrite,
  Uri? endpoint,
}) => SourceCatalogClient(
  runtime: runtime,
  transport: transport,
  loadBundled: () async => bundled,
  readCache: () async => cacheRead?.call(),
  writeCache: (text) async => cacheWrite?.call(text),
  endpoint: endpoint ?? Uri.parse('https://catalog.example.org/catalog.json'),
);

void main() {
  const remote = 'https://catalog.example.org/catalog.json';
  final updatedCatalog = catalog(
    2,
    sources: [
      source(
        id: 'builtin-one',
        revision: 2,
        capabilities: ['lyrics', 'chords'],
      ),
      source(
        id: 'remote-two',
        adapter: 'json',
        revision: 2,
        hosts: ['api.music.example.org'],
        extraction: {'path': 'lyrics'},
      ),
    ],
  );

  test('downloads, validates, persists, then applies the catalog', () async {
    final runtime = makeRuntime();
    var cache = <String?>[null];
    var persisted = false;
    final client = makeClient(
      runtime: runtime,
      bundled: catalog(1),
      cacheRead: () => cache.single,
      cacheWrite: (text) async {
        expect(runtime.catalog?.revision, 1);
        cache[0] = text;
        persisted = true;
      },
      transport: makeTransport((request) async {
        expect(request.url, Uri.parse(remote));
        return http.Response(updatedCatalog, 200);
      }),
    );

    expect(await client.refresh(), isTrue);
    expect(persisted, isTrue);
    expect(cache.single, updatedCatalog);
    expect(runtime.catalog?.revision, 2);
    expect(runtime.providers.map((provider) => provider.definition.id), [
      'builtin-one',
      'remote-two',
    ]);
    expect(client.lastErrorCode, isNull);
    expect(client.lastCheckedAt, isNotNull);
  });

  test('uses a separate channel6 cache while retaining prior cache names', () {
    expect(SourceCatalogClient.bundledAsset, 'config/source-catalog-v6.json');
    expect(SourceCatalogClient.cacheKey, 'sourceCatalog:v6');
    expect(SourceCatalogClient.channel5CacheKey, 'sourceCatalog:v5');
    expect(SourceCatalogClient.channel4CacheKey, 'sourceCatalog:v4');
    expect(SourceCatalogClient.channel3CacheKey, 'sourceCatalog:v3');
    expect(SourceCatalogClient.channel2CacheKey, 'sourceCatalog:v2');
    expect(SourceCatalogClient.legacyCacheKey, 'sourceCatalog');
    expect(
      SourceCatalogClient.defaultEndpoint,
      'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog-v6.json',
    );
  });

  test(
    'malformed and unsupported schema downloads keep the last good catalog',
    () async {
      for (final responseBody in [
        '{not json',
        catalog(2).replaceFirst('"schemaVersion":1', '"schemaVersion":99'),
      ]) {
        final runtime = makeRuntime();
        var writes = 0;
        final client = makeClient(
          runtime: runtime,
          bundled: catalog(1),
          cacheWrite: (_) async {
            writes++;
          },
          transport: makeTransport(
            (_) async => http.Response(responseBody, 200),
          ),
        );

        expect(await client.refresh(), isFalse);
        expect(runtime.catalog?.revision, 1);
        expect(runtime.providers.map((provider) => provider.definition.id), [
          'builtin-one',
        ]);
        expect(writes, 0);
        expect(client.lastErrorCode, 'invalid_response');
      }
    },
  );

  test(
    'same-revision mutation and revision rollback are rejected before persistence',
    () async {
      final changedAtSameRevision = catalog(
        1,
        sources: [source(id: 'builtin-one', name: 'Changed at same revision')],
      );
      final cases = [
        (
          initial: catalog(1),
          response: changedAtSameRevision,
          expectedRevision: 1,
        ),
        (initial: catalog(2), response: catalog(1), expectedRevision: 2),
      ];
      for (final testCase in cases) {
        final runtime = makeRuntime();
        var writes = 0;
        final client = makeClient(
          runtime: runtime,
          bundled: testCase.initial,
          cacheWrite: (_) async {
            writes++;
          },
          transport: makeTransport(
            (_) async => http.Response(testCase.response, 200),
          ),
        );

        expect(await client.refresh(), isFalse);
        expect(runtime.catalog?.revision, testCase.expectedRevision);
        expect(runtime.providers.single.definition.name, 'Source builtin-one');
        expect(writes, 0);
        expect(client.lastErrorCode, 'invalid_response');
      }
    },
  );

  test(
    'adapter validation failure preserves durable and live last-good state',
    () async {
      final runtime = makeRuntime(
        rejectAdapter: (entry) => entry.id == 'remote-two',
      );
      var cache = 'previous cache';
      final client = makeClient(
        runtime: runtime,
        bundled: catalog(1),
        cacheRead: () => null,
        cacheWrite: (text) async {
          cache = text;
        },
        transport: makeTransport(
          (_) async => http.Response(updatedCatalog, 200),
        ),
      );

      expect(await client.refresh(), isFalse);
      expect(runtime.catalog?.revision, 1);
      expect(runtime.providers.map((provider) => provider.definition.id), [
        'builtin-one',
      ]);
      expect(cache, 'previous cache');
      expect(client.lastErrorCode, 'invalid_response');
    },
  );

  test('corrupt cache cannot displace a valid bundled snapshot', () async {
    final runtime = makeRuntime();
    final client = makeClient(
      runtime: runtime,
      bundled: catalog(4),
      cacheRead: () => '{corrupt cache',
      transport: makeTransport(
        (_) async => throw StateError('request should not run'),
      ),
    );

    await client.initialize();
    expect(runtime.catalog?.revision, 4);
    expect(runtime.providers.single.definition.id, 'builtin-one');
    expect(client.lastErrorCode, 'invalid_response');
  });

  test('cache write failure leaves the runtime unchanged', () async {
    final runtime = makeRuntime();
    final client = makeClient(
      runtime: runtime,
      bundled: catalog(1),
      cacheWrite: (_) async => throw StateError('disk full'),
      transport: makeTransport((_) async => http.Response(updatedCatalog, 200)),
    );

    expect(await client.refresh(), isFalse);
    expect(runtime.catalog?.revision, 1);
    expect(runtime.providers.map((provider) => provider.definition.id), [
      'builtin-one',
    ]);
    expect(client.lastCheckedAt, isNull);
  });

  test('concurrent refresh calls share one network request', () async {
    final requestStarted = Completer<void>();
    final releaseResponse = Completer<void>();
    var requestCount = 0;
    final runtime = makeRuntime();
    final client = makeClient(
      runtime: runtime,
      bundled: catalog(1),
      transport: makeTransport((_) async {
        requestCount++;
        requestStarted.complete();
        await releaseResponse.future;
        return http.Response(updatedCatalog, 200);
      }),
    );

    final first = client.refresh();
    final second = client.refresh();
    expect(identical(first, second), isTrue);
    await requestStarted.future;
    expect(requestCount, 1);
    releaseResponse.complete();
    expect(await Future.wait([first, second]), [true, true]);
    expect(requestCount, 1);
    expect(runtime.catalog?.revision, 2);
  });

  test(
    'offline refresh retains cached configuration and omission removes providers',
    () async {
      final cached = catalog(
        2,
        sources: [
          source(id: 'builtin-one', revision: 2),
          source(
            id: 'remote-two',
            adapter: 'json',
            revision: 2,
            hosts: ['api.music.example.org'],
            extraction: {'path': 'lyrics'},
          ),
        ],
      );
      final noRemote = catalog(
        3,
        sources: [source(id: 'builtin-one', revision: 3)],
      );
      final runtime = makeRuntime();
      var persisted = cached;
      final client = makeClient(
        runtime: runtime,
        bundled: catalog(1),
        cacheRead: () => persisted,
        cacheWrite: (text) async {
          persisted = text;
        },
        transport: makeTransport((_) async => http.Response('offline', 503)),
      );

      expect(await client.refresh(), isFalse);
      expect(runtime.catalog?.revision, 2);
      expect(runtime.providers.map((provider) => provider.definition.id), [
        'builtin-one',
        'remote-two',
      ]);
      expect(persisted, cached);

      final omissionClient = makeClient(
        runtime: runtime,
        bundled: catalog(1),
        cacheRead: () => persisted,
        cacheWrite: (text) async {
          persisted = text;
        },
        transport: makeTransport((_) async => http.Response(noRemote, 200)),
      );
      expect(await omissionClient.refresh(), isTrue);
      expect(runtime.providers.map((provider) => provider.definition.id), [
        'builtin-one',
      ]);
      expect(jsonDecode(persisted)['revision'], 3);
    },
  );
}
