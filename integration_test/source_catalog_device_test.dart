import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('declarative TTML extraction uses the real Android HTTP client', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final catalog = SourceCatalog.parse(
        await rootBundle.loadString('config/source-catalog.json'),
      );
      final entry = catalog.sources.singleWhere(
        (source) => source.id == 'unison',
      );
      final candidate = SongCandidate.fromJson(
        Map<String, dynamic>.from(
          entry.probes.firstWhere(
                (probe) => probe['candidate'] is Map,
              )['candidate']
              as Map,
        ),
      );
      final transport = ProviderTransport();
      try {
        final result = await ConfigurableProvider(
          entry,
          transport,
        ).resolve(candidate);
        expect(result.candidate.title, candidate.title);
        expect(result.candidate.artist, candidate.artist);
        expect(result.body.trim().isNotEmpty, isTrue);
        expect(result.timingTracks.isNotEmpty, isTrue);
        expect(
          result.timingTracks.any(
            (track) =>
                track.granularity == 'word' &&
                track.extra['timingProfile'] == 'unison-ttml' &&
                track.cues.any(
                  (cue) =>
                      cue.graphemeStart != null &&
                      cue.graphemeEnd != null &&
                      cue.graphemeEnd! > cue.graphemeStart!,
                ),
          ),
          isTrue,
        );
        expect(
          result.timingTracks.every((track) => track.raw?.isNotEmpty == true),
          isTrue,
        );
        expect(result.attribution, entry.attribution);
        expect(result.candidate.metadata['identityScope'], 'composition');
      } finally {
        await transport.close();
      }
    });
  });
  testWidgets(
    'bundled catalog refresh is atomic on Android and preserves offline cache',
    (tester) async {
      await tester.runAsync(() async {
        final bundled = await rootBundle.loadString(
          'config/source-catalog.json',
        );
        final catalog = SourceCatalog.parse(bundled);
        final transport = ProviderTransport(
          client: MockClient((_) async => http.Response('{broken', 200)),
        );
        final builtins = [
          ...createCoreProviders(transport: transport),
          ...createExtraProviders(transport: transport),
        ];
        final runtime = SourceCatalogRuntime(
          builtins: builtins,
          createProvider: (entry) => ConfigurableProvider(entry, transport),
        );
        String? cached;
        final client = SourceCatalogClient(
          runtime: runtime,
          transport: transport,
          loadBundled: () async => bundled,
          readCache: () async => cached,
          writeCache: (text) async => cached = text,
        );
        try {
          await client.initialize();
          expect(runtime.catalog!.revision, catalog.revision);
          final ids = runtime.providers.map((p) => p.definition.id).toList();
          expect(ids, containsAll(['genius', 'lrclib', 'songsterr']));
          expect(await client.refresh(), isFalse);
          expect(runtime.providers.map((p) => p.definition.id), ids);
          expect(cached, isNull);
          final next = catalog.toJson();
          next['revision'] = catalog.revision + 1;
          final sourceEntries = (next['sources'] as List)
              .cast<Map<String, dynamic>>();
          final entry = sourceEntries.singleWhere(
            (source) => source['id'] == 'lrclib',
          );
          entry['status'] = 'retired';
          entry['revision'] = (entry['revision'] as int) + 1;
          final updateTransport = ProviderTransport(
            client: MockClient(
              (_) async => http.Response(jsonEncode(next), 200),
            ),
          );
          try {
            final refresh = SourceCatalogClient(
              runtime: runtime,
              transport: updateTransport,
              loadBundled: () async => bundled,
              readCache: () async => cached,
              writeCache: (text) async => cached = text,
            );
            expect(await refresh.refresh(), isTrue);
            expect(
              runtime.providers.any((p) => p.definition.id == 'lrclib'),
              isFalse,
            );
            expect(SourceCatalog.parse(cached!).revision, catalog.revision + 1);
          } finally {
            await updateTransport.close();
          }
        } finally {
          await transport.close();
        }
      });
    },
  );
}
