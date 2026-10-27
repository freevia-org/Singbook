import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/source_catalog_client.dart';
import 'source_catalog_client_test.dart' as fixture;

void main() {
  final old = fixture.catalog(2);
  final target = fixture.catalog(10);
  final repaired = fixture.catalog(
    9000,
    sources: [
      fixture.source(id: 'builtin-one', name: 'Cached repair', revision: 100),
    ],
  );
  test(
    'valid current cache recovers when bundled adapters cannot be validated',
    () async {
      final invalidBundle = fixture.catalog(
        10,
        sources: [fixture.source(id: 'notcompiled')],
      );
      final transport = fixture.makeTransport(
        (r) async => throw StateError('No requests'),
      );
      final client = SourceCatalogClient(
        runtime: fixture.makeRuntime(),
        transport: transport,
        loadBundled: () async => invalidBundle,
        readCache: () async => target,
        writeCache: (text) async => fail('No write'),
        readPreviousCaches: () async =>
            throw StateError('Valid current cache bypasses older state'),
      );
      try {
        await client.initialize();
        expect(client.runtime.catalog!.revision, 10);
        expect(client.runtime.providers.single.definition.id, 'builtin-one');
      } finally {
        await transport.close();
      }
    },
  );
  test(
    'initial compatibility loading does no HTTP or writes; failed durable target write retains fallback',
    () async {
      var calls = 0, writes = 0;
      var rejectWrite = true;
      final transport = fixture.makeTransport((r) async {
        calls++;
        return http.Response(
          target,
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = SourceCatalogClient(
        runtime: fixture.makeRuntime(),
        transport: transport,
        loadBundled: () async => target,
        readCache: () async => null,
        writeCache: (text) async {
          writes++;
          if (rejectWrite) throw StateError('full disk');
        },
        readPreviousCaches: () async => [(bundled: old, cached: repaired)],
      );
      try {
        await client.initialize();
        expect(calls, 0);
        expect(writes, 0);
        expect(
          client.runtime.providers.single.definition.name,
          'Cached repair',
        );
        expect(client.runtime.catalog!.revision, 10);
        final fallback = client.runtime;
        expect(await client.refresh(), false);
        expect(identical(client.runtime, fallback), true);
        expect(
          client.runtime.providers.single.definition.name,
          'Cached repair',
        );
        expect(client.lastErrorCode, 'invalid_response');
        rejectWrite = false;
        expect(await client.refresh(), true);
        expect(
          client.runtime.providers.single.definition.name,
          isNot('Cached repair'),
        );
        expect(calls, 2);
        expect(writes, 2);
      } finally {
        await transport.close();
      }
    },
  );
  test(
    'valid current cache is authoritative and previous callback is never read',
    () async {
      var oldReads = 0;
      final cached = fixture.catalog(11);
      final transport = fixture.makeTransport(
        (r) async => throw StateError('no requests'),
      );
      final client = SourceCatalogClient(
        runtime: fixture.makeRuntime(),
        transport: transport,
        loadBundled: () async => target,
        readCache: () async => cached,
        writeCache: (text) async => fail('no writes'),
        readPreviousCaches: () async {
          oldReads++;
          return [(bundled: old, cached: repaired)];
        },
      );
      try {
        await client.initialize();
        expect(oldReads, 0);
        expect(client.runtime.catalog!.revision, 11);
        expect(
          client.runtime.providers.single.definition.name,
          isNot('Cached repair'),
        );
      } finally {
        await transport.close();
      }
    },
  );
  test(
    'invalid current and closest previous cache fall back to next compatible channel',
    () async {
      final transport = fixture.makeTransport(
        (r) async => throw StateError('no requests'),
      );
      final client = SourceCatalogClient(
        runtime: fixture.makeRuntime(),
        transport: transport,
        loadBundled: () async => target,
        readCache: () async => 'broken',
        writeCache: (text) async => fail('no writes'),
        readPreviousCaches: () async => [
          (bundled: old, cached: 'broken'),
          (bundled: old, cached: repaired),
        ],
      );
      try {
        await client.initialize();
        expect(
          client.runtime.providers.single.definition.name,
          'Cached repair',
        );
        expect(client.runtime.catalog!.revision, 10);
      } finally {
        await transport.close();
      }
    },
  );
  test(
    'newer bundled source revisions override previous edits and omissions',
    () async {
      final current = fixture.catalog(
        10,
        sources: [
          fixture.source(
            id: 'builtin-one',
            name: 'New compiled correction',
            revision: 101,
          ),
        ],
      );
      for (final previous in [repaired, fixture.catalog(9000, sources: [])]) {
        final transport = fixture.makeTransport(
          (r) async => throw StateError('no requests'),
        );
        final client = SourceCatalogClient(
          runtime: fixture.makeRuntime(),
          transport: transport,
          loadBundled: () async => current,
          readCache: () async => null,
          writeCache: (text) async => fail('no writes'),
          readPreviousCaches: () async => [(bundled: old, cached: previous)],
        );
        try {
          await client.initialize();
          expect(
            client.runtime.providers.single.definition.name,
            'New compiled correction',
          );
        } finally {
          await transport.close();
        }
      }
    },
  );
  test(
    'new bundle retirement cannot be resurrected by an older channel',
    () async {
      final current = fixture.catalog(
        10,
        sources: [
          fixture.source(id: 'builtin-one', status: 'retired', revision: 5),
        ],
      );
      final transport = fixture.makeTransport(
        (r) async => throw StateError('no requests'),
      );
      final client = SourceCatalogClient(
        runtime: fixture.makeRuntime(),
        transport: transport,
        loadBundled: () async => current,
        readCache: () async => null,
        writeCache: (text) async => fail('no writes'),
        readPreviousCaches: () async => [(bundled: old, cached: repaired)],
      );
      try {
        await client.initialize();
        expect(client.runtime.providers, isEmpty);
        expect(client.runtime.catalog!.sources.single.status, 'retired');
      } finally {
        await transport.close();
      }
    },
  );
  test(
    'target rollback or unknown native response preserves offline compatibility view',
    () async {
      var response = fixture.catalog(9);
      var writes = 0;
      final transport = fixture.makeTransport(
        (r) async => http.Response(
          response,
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final client = SourceCatalogClient(
        runtime: fixture.makeRuntime(),
        transport: transport,
        loadBundled: () async => target,
        readCache: () async => null,
        writeCache: (text) async {
          writes++;
        },
        readPreviousCaches: () async => [(bundled: old, cached: repaired)],
      );
      try {
        await client.initialize();
        expect(await client.refresh(), false);
        expect(writes, 0);
        expect(
          client.runtime.providers.single.definition.name,
          'Cached repair',
        );
        final value = jsonDecode(fixture.catalog(11)) as Map<String, dynamic>;
        (value['sources'] as List).add(
          fixture.source(id: 'unknown-native', status: 'disabled'),
        );
        response = jsonEncode(value);
        expect(await client.refresh(), false);
        expect(writes, 0);
        expect(
          client.runtime.providers.single.definition.name,
          'Cached repair',
        );
      } finally {
        await transport.close();
      }
    },
  );
}
