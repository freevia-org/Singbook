import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/transport.dart';

void main() {
  test('native LyricsPlus registration cannot alter older channel rosters', () {
    var requests = 0;
    final transport = ProviderTransport(
      client: MockClient((_) async {
        requests++;
        throw StateError('Catalog boundaries are entirely offline');
      }),
    );
    addTearDown(transport.close);
    final builtins = [
      ...createCoreProviders(transport: transport),
      ...createExtraProviders(transport: transport),
    ];
    final native = builtins.whereType<LyricsPlusProvider>().single;
    expect(native.definition.enabledByDefault, isFalse);
    final frozen = Directory('config')
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              RegExp(r'source-catalog(?:-v[2-6])?\.json$').hasMatch(file.path),
        )
        .toList();
    expect(frozen.length, greaterThanOrEqualTo(5));
    for (final file in frozen) {
      final catalog = SourceCatalog.parse(file.readAsStringSync());
      final runtime = SourceCatalogRuntime(
        builtins: builtins,
        createProvider: (entry) => ConfigurableProvider(entry, transport),
      )..apply(catalog);
      expect(
        catalog.sources.any((source) => source.id == 'lyricsplus'),
        isFalse,
      );
      expect(
        runtime.providers.any(
          (provider) => provider.definition.id == 'lyricsplus',
        ),
        isFalse,
      );
      expect(
        runtime.providers.map((provider) => provider.definition.id).toSet(),
        catalog.sources
            .where((source) => source.isActive)
            .map((source) => source.id)
            .toSet(),
      );
    }
    expect(requests, 0);
  });
}
