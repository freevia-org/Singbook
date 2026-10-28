import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_maintenance.dart';
import 'package:singbook/providers/transport.dart';

void main() {
  final oldFile = File('config/source-catalog-v6.json');
  final newFile = File('config/source-catalog-v7.json');

  test('channel7 adds LyricsPlus without changing any channel6 source', () {
    final old = jsonDecode(oldFile.readAsStringSync()) as Map<String, dynamic>;
    final next = jsonDecode(newFile.readAsStringSync()) as Map<String, dynamic>;
    final previous = old['sources'] as List;
    final sources = next['sources'] as List;
    expect(previous, hasLength(27));
    expect(sources, hasLength(28));
    expect(sources.take(previous.length).toList(), previous);
    expect(next['revision'], 19);
    expect(DateTime.parse(next['publishedAt']).isUtc, isTrue);
    expect(
      DateTime.parse(
        next['publishedAt'],
      ).isAfter(DateTime.parse(old['publishedAt'])),
      isTrue,
    );
    final entry = sources.last as Map;
    expect(entry['id'], 'lyricsplus');
    expect(entry['adapter'], 'builtin');
    expect(entry['revision'], 1);
    expect(entry['status'], 'active');
    expect(entry['enabledByDefault'], isTrue);
    expect(entry['accessMode'], 'publicApi');
    expect(entry['capabilities'], [
      'catalog',
      'lyrics',
      'metadata',
      'lineTiming',
      'wordTiming',
    ]);
    expect(entry['hosts'], ['lyricsplus.prjktla.my.id', 'itunes.apple.com']);
    final probes = (entry['probes'] as List).cast<Map>();
    expect(probes.map((probe) => probe['id']), [
      'billie-jean-michael-jackson',
      'creep-radiohead',
    ]);
    for (final probe in probes) {
      expect(probe['query'], isNotEmpty);
      expect(probe['expectedTitle'], isNotEmpty);
      expect(probe['expectedArtist'], isNotEmpty);
      expect(probe.containsKey('candidate'), isFalse);
      expect(probe['requiredFields'], [
        'body',
        'metadata',
        'lineTiming',
        'wordTiming',
      ]);
      expect(
        probe['requiredMetadataFields'],
        containsAll([
          'identityScope',
          'documentKind',
          'album',
          'durationSeconds',
          'appleMusicIds',
        ]),
      );
    }
    final assets = File('pubspec.yaml').readAsStringSync();
    for (final asset in [
      'config/source-catalog.json',
      for (var channel = 2; channel <= 8; channel++)
        'config/source-catalog-v$channel.json',
    ]) {
      expect(assets, contains('    - $asset'));
    }
  });

  test('LyricsPlus becomes active only in its compatible channel', () {
    final transport = ProviderTransport(
      client: MockClient(
        (_) async => throw StateError('No HTTP in catalog checks'),
      ),
    );
    addTearDown(transport.close);
    final builtins = [
      ...createCoreProviders(transport: transport),
      ...createExtraProviders(transport: transport),
    ].where(
      (provider) =>
          provider.definition.id != 'chordsandtabs' &&
          provider.definition.id != 'pisni',
    ).toList();
    final native = builtins.whereType<LyricsPlusProvider>().single;
    expect(native.definition.enabledByDefault, isFalse);
    final runtime = SourceCatalogRuntime(
      builtins: builtins,
      createProvider: (entry) => ConfigurableProvider(entry, transport),
    );
    runtime.apply(SourceCatalog.parse(oldFile.readAsStringSync()));
    expect(
      runtime.providers.any(
        (provider) => provider.definition.id == 'lyricsplus',
      ),
      isFalse,
    );
    runtime.apply(SourceCatalog.parse(newFile.readAsStringSync()));
    final activated = runtime.providers.singleWhere(
      (provider) => provider.definition.id == 'lyricsplus',
    );
    expect(activated.definition.enabledByDefault, isTrue);
    expect(activated.definition.configured, isTrue);
    expect(native.definition.enabledByDefault, isFalse);
    expect(
      runtime.providers.map((provider) => provider.definition.id).toSet(),
      runtime.catalog!.sources
          .where((entry) => entry.isActive)
          .map((entry) => entry.id)
          .toSet(),
    );
  });

  test(
    'older native roster rejects channel7 atomically and retains channel6',
    () {
      final transport = ProviderTransport(
        client: MockClient(
          (_) async => throw StateError('No HTTP in catalog checks'),
        ),
      );
      addTearDown(transport.close);
      final builtins = [
        ...createCoreProviders(transport: transport),
        ...createExtraProviders(transport: transport),
      ].where(
        (provider) =>
            provider.definition.id != 'lyricsplus' &&
            provider.definition.id != 'chordsandtabs' &&
            provider.definition.id != 'pisni',
      ).toList();
      final runtime = SourceCatalogRuntime(
        builtins: builtins,
        createProvider: (entry) => ConfigurableProvider(entry, transport),
      );
      final previous = SourceCatalog.parse(oldFile.readAsStringSync());
      runtime.apply(previous);
      final providers = runtime.providers;
      expect(
        () => runtime.apply(SourceCatalog.parse(newFile.readAsStringSync())),
        throwsStateError,
      );
      expect(identical(runtime.catalog, previous), isTrue);
      expect(identical(runtime.providers, providers), isTrue);
    },
  );

  test(
    'both channel7 probes use search, actual lyrics and independent metadata',
    () async {
      final catalog = SourceCatalog.parse(newFile.readAsStringSync());
      final entry = catalog.sources.singleWhere(
        (source) => source.id == 'lyricsplus',
      );
      final probes = entry.probes;
      final requests = <http.Request>[];
      final transport = ProviderTransport(
        client: MockClient((request) async {
          requests.add(request);
          final Object data;
          if (request.url.host == 'lyricsplus.prjktla.my.id' &&
              request.url.path == '/v1/songlist/search') {
            final index = probes.indexWhere(
              (probe) => probe['query'] == request.url.queryParameters['q'],
            );
            expect(index, isNonNegative);
            data = {
              'results': [_catalogRow(probes[index])],
            };
          } else if (request.url.host == 'lyricsplus.prjktla.my.id' &&
              request.url.path == '/v2/lyrics/get') {
            expect(request.url.queryParameters.keys.toSet(), {
              'title',
              'artist',
            });
            final index = probes.indexWhere(
              (probe) =>
                  probe['expectedTitle'] ==
                      request.url.queryParameters['title'] &&
                  probe['expectedArtist'] ==
                      request.url.queryParameters['artist'],
            );
            expect(index, isNonNegative);
            data = _payload(probes[index], 1001 + index);
          } else {
            expect(request.url.host, 'itunes.apple.com');
            expect(request.url.path, '/lookup');
            final id = int.parse(request.url.queryParameters['id']!);
            final index = id - 1001;
            expect(index, inInclusiveRange(0, 1));
            data = {
              'resultCount': 1,
              'results': [_apple(probes[index], id)],
            };
          }
          expect(request.headers.containsKey('authorization'), isFalse);
          expect(request.headers.containsKey('cookie'), isFalse);
          expect(
            request.url.queryParameters.containsKey('forceReload'),
            isFalse,
          );
          return http.Response.bytes(
            utf8.encode(jsonEncode(data)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      addTearDown(transport.close);
      final report = await SourceMaintenanceHarness(
        providers: [LyricsPlusProvider(transport)],
      ).run(catalog, sourceIds: const {'lyricsplus'});
      final source = (report['sources'] as List).single as Map;
      final results = (source['probes'] as List).cast<Map>();
      expect(results.map((probe) => probe['status']), ['healthy', 'healthy']);
      expect(source['coverage']['status'], 'complete');
      expect(
        source['coverage']['verifiedCapabilities'],
        containsAll([
          'catalog',
          'lyrics',
          'metadata',
          'lineTiming',
          'wordTiming',
        ]),
      );
      expect(requests, hasLength(6));
      for (final path in ['/v1/songlist/search', '/v2/lyrics/get', '/lookup']) {
        expect(
          requests.where((request) => request.url.path == path),
          hasLength(2),
        );
      }
    },
  );
}

Map<String, Object?> _catalogRow(Map probe) => {
  'id': {'deezer': '42'},
  'sourceId': '42',
  'title': probe['expectedTitle'],
  'artist': probe['expectedArtist'],
  'album': 'Catalog hint album',
  'durationMs': 238000,
  'availability': ['Deezer'],
};

Map<String, Object?> _payload(Map probe, int id) => {
  'type': 'Word',
  'metadata': {
    'source': 'Apple',
    'language': 'en',
    'totalDuration': '3:58.640',
  },
  'lyrics': [
    {
      'text': 'Synthetic words',
      'time': 1000,
      'duration': 2000,
      'syllabus': [
        {'text': 'Synthetic ', 'time': 1000, 'duration': 800},
        {'text': 'words', 'time': 1800, 'duration': 1200},
      ],
    },
  ],
  'processingTime': {
    'winnerSource': 'apple',
    'selectedSongMetadata': {
      'source': 'Apple',
      'title': probe['expectedTitle'],
      'artist': probe['expectedArtist'],
      'songPlatformId': id.toString(),
    },
  },
};

Map<String, Object?> _apple(Map probe, int id) => {
  'wrapperType': 'track',
  'kind': 'song',
  'trackId': id,
  'trackName': probe['expectedTitle'],
  'artistName': probe['expectedArtist'],
  'collectionName': 'Independently returned fixture album',
  'trackTimeMillis': 238640,
  'trackViewUrl': 'https://music.apple.com/us/album/fixture/100?i=$id',
};
