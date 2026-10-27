import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';
import 'package:singbook/providers/source_maintenance.dart';
import 'package:singbook/providers/transport.dart';

void main() {
  final v5File = File('config/source-catalog-v5.json');
  final v6File = File('config/source-catalog-v6.json');

  test('channel 6 preserves channel 5 entries and selects v6 defaults', () {
    final old = jsonDecode(v5File.readAsStringSync()) as Map<String, dynamic>;
    final current =
        jsonDecode(v6File.readAsStringSync()) as Map<String, dynamic>;
    final oldSources = old['sources'] as List;
    final newSources = current['sources'] as List;
    expect(current['revision'], 18);
    expect(newSources.take(oldSources.length).toList(), oldSources);
    final entry = newSources.singleWhere(
      (source) => source['id'] == 'startjamming',
    );
    expect(entry['revision'], 1);
    expect(entry['status'], 'active');
    expect(entry['enabledByDefault'], isTrue);
    expect(entry['accessMode'], 'publicApi');
    expect(
      entry['capabilities'],
      containsAll(['catalog', 'lyrics', 'chords', 'metadata']),
    );
    expect(entry['probes'].map((probe) => probe['id']), [
      'clinch-mountain-backstep',
      'blue-moon-of-kentucky',
    ]);
    for (final probe in entry['probes']) {
      final id = probe['id'];
      final candidate = probe['candidate'];
      final identity = candidate['startjamming'];
      expect(candidate['providerId'], 'startjamming');
      expect(candidate['id'], id);
      expect(candidate['title'], probe['expectedTitle']);
      expect(candidate['artist'], '');
      expect(candidate['url'], 'https://www.startjamming.com/song/$id');
      expect(candidate['metadata']['identityScope'], 'arrangement');
      expect(identity['id'], id);
      expect(identity['canonical_id'], id);
      expect(identity['slug'], id);
      expect(identity['song_id'], id.replaceAll('-', '_'));
      expect(
        identity['apiUrl'],
        'https://www.startjamming.com/api/songs/$id/full?for=agent',
      );
      expect(probe['query'], probe['expectedTitle']);
      expect(
        probe['requiredMetadataFields'],
        containsAll(['identityScope', 'key', 'timeSignature']),
      );
    }
    expect(SourceCatalogClient.bundledAsset, 'config/source-catalog-v6.json');
    expect(SourceCatalogClient.cacheKey, 'sourceCatalog:v6');
    expect(SourceCatalogClient.channel5CacheKey, 'sourceCatalog:v5');
    expect(SourceCatalogClient.channel4CacheKey, 'sourceCatalog:v4');
    expect(
      SourceCatalogClient.defaultEndpoint,
      endsWith('/source-catalog-v6.json'),
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('config/source-catalog-v6.json'),
    );
  });

  test('older roster rejects v6 atomically and retains v5 state', () {
    final transport = ProviderTransport(
      client: MockClient((_) async => throw StateError('unexpected HTTP')),
      hostInterval: Duration.zero,
    );
    addTearDown(transport.close);
    final all = [
      ...createCoreProviders(transport: transport),
      ...createExtraProviders(transport: transport),
    ];
    final oldRoster = all
        .where((provider) => provider.definition.id != 'startjamming')
        .toList();
    final runtime = SourceCatalogRuntime(
      builtins: oldRoster,
      createProvider: (entry) => ConfigurableProvider(entry, transport),
    );
    final oldCatalog = SourceCatalog.parse(v5File.readAsStringSync());
    runtime.apply(oldCatalog);
    final providerIds = runtime.providers
        .map((provider) => provider.definition.id)
        .toList();
    expect(
      () => runtime.apply(SourceCatalog.parse(v6File.readAsStringSync())),
      throwsStateError,
    );
    expect(runtime.catalog!.revision, 17);
    expect(runtime.catalog!.sameContent(oldCatalog), isTrue);
    expect(
      runtime.providers.map((provider) => provider.definition.id).toList(),
      providerIds,
    );
  });

  test(
    'maintenance harness qualifies instrumental and vocal canonical probes',
    () async {
      const ids = ['clinch-mountain-backstep', 'blue-moon-of-kentucky'];
      const titles = ['Clinch Mountain Backstep', 'Blue Moon of Kentucky'];
      final requests = <http.Request>[];
      final transport = ProviderTransport(
        client: MockClient((request) async {
          requests.add(request);
          expect(request.url.host, 'www.startjamming.com');
          if (request.url.path == '/api/songs/search') {
            expect(request.url.queryParameters['for'], 'agent');
            expect(request.url.queryParameters['limit'], '8');
            final index = titles.indexOf(
              request.url.queryParameters['q'] ?? '',
            );
            expect(index, isNonNegative);
            final id = ids[index];
            return http.Response(
              jsonEncode({
                'results': [_searchRow(id, titles[index], index)],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          final id = request.url.pathSegments[2];
          final index = ids.indexOf(id);
          expect(index, isNonNegative);
          expect(
            request.url.toString(),
            'https://www.startjamming.com/api/songs/$id/full?for=agent',
          );
          return http.Response(
            jsonEncode(_detail(id, titles[index], index)),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        hostInterval: Duration.zero,
      );
      addTearDown(transport.close);
      final report =
          await SourceMaintenanceHarness(
            providers: [StartJammingProvider(transport)],
          ).run(
            SourceCatalog.parse(v6File.readAsStringSync()),
            sourceIds: const {'startjamming'},
          );
      final source = (report['sources'] as List).single as Map;
      final probes = (source['probes'] as List).cast<Map>();
      expect(probes.map((probe) => probe['status']), ['healthy', 'healthy']);
      expect(
        probes.first['verifiedCapabilities'],
        containsAll(['catalog', 'chords', 'metadata']),
      );
      expect(probes.first['verifiedCapabilities'], isNot(contains('lyrics')));
      expect(probes.last['verifiedCapabilities'], contains('lyrics'));
      expect(
        source['coverage']['verifiedCapabilities'],
        containsAll(['catalog', 'lyrics', 'chords', 'metadata']),
      );
      expect(source['coverage']['status'], 'complete');
      expect(requests, hasLength(4));
      expect(
        requests.where((request) => request.url.path == '/api/songs/search'),
        hasLength(2),
      );
      expect(
        requests.where((request) => request.url.path.endsWith('/full')),
        hasLength(2),
      );
      expect(
        requests
            .where((request) => request.url.path.endsWith('/full'))
            .every((request) => request.url.queryParameters['for'] == 'agent'),
        isTrue,
      );
    },
  );
}

Map<String, Object?> _identity(String id, String title) => {
  'id': id,
  'canonical_id': id,
  'slug': id,
  'song_id': id.replaceAll('-', '_'),
  'title': title,
  'url': 'https://www.startjamming.com/song/$id',
  'api_url': 'https://www.startjamming.com/api/songs/$id/full?for=agent',
};

Map<String, Object?> _searchRow(String id, String title, int index) => {
  ..._identity(id, title),
  'type': index == 0 ? 'instrumental' : 'vocal',
  'key': index == 0 ? 'G' : 'C',
  'match_type': 'title_exact',
  'score': 1.0,
};

Map<String, Object?> _detail(String id, String title, int index) {
  final chord = index == 0 ? 'G' : 'C';
  final progression = '$chord / / /';
  return {
    ..._identity(id, title),
    'type': index == 0 ? 'instrumental' : 'vocal',
    'key': chord,
    'signature': '4/4',
    if (index == 1) 'lyrics': 'Synthetic singers follow the quiet river.',
    'arrangement': {
      'song_id': id.replaceAll('-', '_'),
      'title': title,
      'original_key': chord,
      'target_key': chord,
      'signature': '4/4',
      'sections': [
        {
          'name': 'A',
          'repeats': 1,
          'measures': [
            {
              'index': 0,
              'source': progression,
              'beats': [chord, chord, chord, chord],
              'display': progression,
              'beat_count': 4,
              'has_rest': false,
            },
          ],
        },
      ],
    },
  };
}
