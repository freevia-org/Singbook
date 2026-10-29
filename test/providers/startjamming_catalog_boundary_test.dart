import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/transport.dart';

void main() {
  test(
    'existing catalog channels keep their roster after native registration',
    () async {
      var requests = 0;
      final transport = ProviderTransport(
        client: MockClient((_) async {
          requests++;
          throw StateError('Offline catalog validation must not use HTTP');
        }),
      );
      addTearDown(transport.close);
      final providers = [
        ...createCoreProviders(transport: transport),
        ...createExtraProviders(transport: transport),
      ];
      expect(providers.whereType<StartJammingProvider>(), hasLength(1));
      for (final file in Directory('config').listSync().whereType<File>().where(
        (f) => RegExp(r'source-catalog(?:-v[2-5])?\.json$').hasMatch(f.path),
      )) {
        final catalog = SourceCatalog.parse(file.readAsStringSync());
        final runtime = SourceCatalogRuntime(
          builtins: providers,
          createProvider: (entry) => ConfigurableProvider(entry, transport),
        )..apply(catalog);
        expect(catalog.sources.any((s) => s.id == 'startjamming'), isFalse);
        expect(
          runtime.providers.any((p) => p.definition.id == 'startjamming'),
          isFalse,
        );
        expect(
          runtime.providers.map((p) => p.definition.id).toSet(),
          catalog.sources.where((s) => s.isActive).map((s) => s.id).toSet(),
        );
      }
      expect(requests, 0);
    },
  );
}
