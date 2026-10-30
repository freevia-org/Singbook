// Native iOS provider qualification with synthetic HTTP responses and a
// temporary SQLite library. This does not claim live-provider availability.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart' show deleteDatabase, getDatabasesPath;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/arrangement.dart' show plainLyrics;
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';
import 'package:singbook/providers/transport.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'LyricsPlus native provider parses synthetic search, lyrics and word timing',
    (tester) async {
      final requests = <http.Request>[];
      final transport = ProviderTransport(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.host == 'lyricsplus.prjktla.my.id' &&
              request.url.path == '/v1/songlist/search') {
            return _jsonResponse({
              'results': [
                {
                  'id': {'deezer': '42'},
                  'sourceId': '42',
                  'title': 'Fixture Song',
                  'artist': 'Fixture Artist',
                  'album': 'Catalog Album',
                  'durationMs': 238000,
                  'isrc': 'GBXXX1200001',
                  'availability': ['Deezer'],
                  'externalUrls': {'deezer': 'https://www.deezer.com/track/42'},
                },
              ],
            });
          }
          if (request.url.host == 'lyricsplus.prjktla.my.id' &&
              request.url.path == '/v2/lyrics/get') {
            return _jsonResponse(_lyricsPlusPayload());
          }
          if (request.url.host == 'itunes.apple.com' &&
              request.url.path == '/lookup') {
            return _jsonResponse({
              'resultCount': 1,
              'results': [
                {
                  'wrapperType': 'track',
                  'kind': 'song',
                  'trackId': 12345,
                  'trackName': 'Fixture Song',
                  'artistName': 'Fixture Artist',
                  'collectionName': 'Apple Fixture Album',
                  'trackTimeMillis': 238640,
                  'trackViewUrl': 'https://music.apple.com/fixture/12345',
                  'artworkUrl100':
                      'https://is1-ssl.mzstatic.com/image/thumb/fixture/100.jpg',
                },
              ],
            });
          }
          return http.Response('unexpected route', 404);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      addTearDown(transport.close);

      final provider = LyricsPlusProvider(transport);
      final candidate = (await provider.search(
        'Fixture Song Fixture Artist',
      )).single;
      final result = await provider.resolve(candidate);

      expect(result.candidate.identity, candidate.identity);
      expect(result.body, 'Copper lanterns shimmer across quiet water');
      expect(result.candidate.album, 'Apple Fixture Album');
      expect(result.metadata['identityScope'], 'arrangement');
      expect(result.timingTracks, hasLength(1));
      final track = result.timingTracks.single;
      expect(track.granularity, 'word');
      expect(track.raw, isNotEmpty);
      expect(
        track.cues
            .where((cue) => cue.graphemeStart != null)
            .map((cue) => cue.text)
            .join(),
        'Copper lanterns shimmer across quiet water',
      );
      expect(track.cues.every((cue) => cue.startUs >= 0), isTrue);
      expect(requests.map((request) => request.url.host).toSet(), {
        'lyricsplus.prjktla.my.id',
        'itunes.apple.com',
      });
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'channel 7 cache fallback activates LyricsPlus and preserves library data',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_ios_channel7_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await repository.close();
          await deleteDatabase(databasePath);
        });
      });
      final original = SongDocument(
        id: 'before-channel-upgrade',
        title: 'Original Saved Song',
        artist: 'Original Artist',
        body: '[C]Original library text',
        extra: {'origin': 'existing-library'},
      );
      await repository.saveSong(original);

      final channel6 =
          jsonDecode(
                await rootBundle.loadString('config/source-catalog-v6.json'),
              )
              as Map<String, dynamic>;
      final cached = jsonDecode(jsonEncode(channel6)) as Map<String, dynamic>;
      cached['revision'] = (cached['revision'] as int) + 1;
      final cachedLyricsOvh = (cached['sources'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((source) => source['id'] == 'lyricsovh');
      cachedLyricsOvh['revision'] = (cachedLyricsOvh['revision'] as int) + 1;
      cachedLyricsOvh['name'] = 'Retained cached Lyrics.ovh';

      final transport = ProviderTransport(
        client: MockClient((_) async => http.Response('offline', 503)),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      addTearDown(transport.close);
      final builtins = [
        ...createCoreProviders(transport: transport),
        ...createExtraProviders(transport: transport),
      ];
      final runtime = SourceCatalogRuntime(
        builtins: builtins,
        createProvider: (entry) => ConfigurableProvider(entry, transport),
      );
      final bundled = await rootBundle.loadString(
        'config/source-catalog-v7.json',
      );
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => bundled,
        readCache: () async => null,
        writeCache: (_) async {},
        readPreviousCaches: () async => [
          (bundled: jsonEncode(channel6), cached: jsonEncode(cached)),
        ],
        endpoint: Uri.https('catalog.invalid', '/offline.json'),
      );

      await client.initialize();

      expect(
        runtime.catalog!.sources.any((source) => source.id == 'lyricsplus'),
        isTrue,
      );
      expect(
        runtime.providers.any(
          (provider) => provider.definition.id == 'lyricsplus',
        ),
        isTrue,
      );
      expect(
        runtime.catalog!.sources
            .singleWhere((source) => source.id == 'lyricsovh')
            .name,
        'Retained cached Lyrics.ovh',
      );
      final reopened = await repository.getSong(original.id);
      expect(reopened?.title, original.title);
      expect(reopened?.body, original.body);
      expect(reopened?.extra['origin'], 'existing-library');
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'Start Jamming chord-only result compares, saves and reopens with provenance',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_ios_chord_only_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
      final transport = ProviderTransport(
        client: MockClient((request) async {
          if (request.url.path == '/api/songs/search') {
            return _jsonResponse({
              'results': [_startJammingSearchRow],
            });
          }
          if (request.url.path == '/api/songs/fixture-chart/full') {
            return _jsonResponse(_startJammingDetail);
          }
          return http.Response('unexpected route', 404);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      AppController? app;
      AppControllerAdapter? adapter;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        adapter?.dispose();
        app?.dispose();
        await tester.runAsync(() async {
          await transport.close();
          await repository.close();
          await deleteDatabase(databasePath);
        });
      });
      final provider = StartJammingProvider(transport);
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([provider]),
      );
      await app.initialize();
      app.settings['catalog'] = 'startjamming';
      adapter = AppControllerAdapter(app);
      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();

      adapter.setQuery('Instrumental Fixture');
      await adapter.submitSearch();
      expect(app.suggestions, hasLength(1));
      final candidate = app.suggestions.single;
      await adapter.selectReference(
        SearchReferenceData(
          id: candidate.identity,
          title: candidate.title,
          artist: candidate.artist,
        ),
      );
      final result = app.results.singleWhere(
        (item) => item.id == candidate.identity,
      );
      expect(result.hasChords, isTrue);
      expect(plainLyrics(result.body).trim(), isEmpty);
      expect(
        result.attribution,
        contains('www.startjamming.com/song/fixture-chart'),
      );

      final comparison = adapter.state.comparison!;
      final rawVersion = comparison.alternatives.singleWhere(
        (version) => version.id == result.id,
      );
      expect(rawVersion.hasLyrics, isFalse);
      expect(rawVersion.hasChords, isTrue);
      expect(rawVersion.isUsableVersion, isTrue);
      expect(rawVersion.canSave, isTrue);
      adapter.selectVersion(rawVersion.id);
      await adapter.saveSelectedVersion();

      expect(adapter.state.song, isNotNull);
      final saved = (await repository.getSong(app.songs.single.id))!;
      expect(saved.body, result.body);
      expect(saved.extra['selectedSourceId'], result.id);
      expect(saved.sources.single.id, result.id);
      expect(saved.sources.single.body, result.body);
      expect(saved.sources.single.attribution, result.attribution);
      await adapter.openSong(saved.id);
      expect(adapter.state.song?.id, saved.id);
      expect(app.findSong(saved.id)?.body, result.body);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

http.Response _jsonResponse(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _lyricsPlusPayload() => {
  'type': 'Word',
  'KpoeTools': 'synthetic-fixture',
  'metadata': {
    'source': 'Apple',
    'language': 'en',
    'totalDuration': '3:58.640',
    'songWriters': ['Fixture Writer'],
    'agents': {
      'v1': {'type': 'person', 'name': 'Fixture Artist', 'alias': 'v1'},
    },
    'songParts': [
      {'name': 'Verse', 'time': 1000, 'duration': 3000},
    ],
  },
  'lyrics': [
    {
      'text': 'Copper lanterns shimmer across quiet water',
      'time': 1000,
      'duration': 3000,
      'syllabus': [
        {'text': 'Copper ', 'time': 1000, 'duration': 500},
        {'text': 'lanterns ', 'time': 1500, 'duration': 500},
        {'text': 'shimmer ', 'time': 2000, 'duration': 500},
        {'text': 'across ', 'time': 2500, 'duration': 500},
        {'text': 'quiet ', 'time': 3000, 'duration': 500},
        {'text': 'water', 'time': 3500, 'duration': 500},
      ],
      'element': {'key': 'L1', 'singer': 'v1', 'songPartIndex': 0},
    },
  ],
  'processingTime': {
    'winnerSource': 'apple',
    'selectedSongMetadata': {
      'source': 'Apple',
      'title': 'Fixture Song',
      'artist': 'Fixture Artist',
      'album': 'Catalog Album',
      'duration': 238.64,
      'songISRC': 'GBXXX1200001',
      'songPlatformId': '12345',
    },
  },
};

const _startJammingSearchRow = <String, Object?>{
  'id': 'fixture-chart',
  'canonical_id': 'fixture-chart',
  'song_id': 'fixture_chart',
  'slug': 'fixture-chart',
  'title': 'Instrumental Fixture',
  'url': 'https://www.startjamming.com/song/fixture-chart',
  'api_url':
      'https://www.startjamming.com/api/songs/fixture-chart/full?for=agent',
  'type': 'vocal',
  'key': 'G',
  'match_type': 'title_exact',
  'score': 1.0,
};

const _startJammingDetail = <String, Object?>{
  'id': 'fixture-chart',
  'canonical_id': 'fixture-chart',
  'song_id': 'fixture_chart',
  'slug': 'fixture-chart',
  'title': 'Instrumental Fixture',
  'url': 'https://www.startjamming.com/song/fixture-chart',
  'api_url':
      'https://www.startjamming.com/api/songs/fixture-chart/full?for=agent',
  'type': 'vocal',
  'key': 'G',
  'signature': '4/4',
  'tempo': 92,
  'lyrics': '',
  'arrangement': {
    'song_id': 'fixture_chart',
    'title': 'Instrumental Fixture',
    'original_key': 'G',
    'target_key': 'G',
    'signature': '4/4',
    'default_beats_per_measure': 4,
    'sections': [
      {
        'name': 'A',
        'repeats': 1,
        'measures': [
          {
            'index': 0,
            'source': 'G / / /',
            'beats': ['G', 'G', 'G', 'G'],
            'display': 'G / / /',
            'beat_count': 4,
            'has_rest': false,
          },
          {
            'index': 1,
            'source': 'C / / /',
            'beats': ['C', 'C', 'C', 'C'],
            'display': 'C / / /',
            'beat_count': 4,
            'has_rest': false,
          },
        ],
      },
    ],
    'backing_track_progression': ['G / / /', 'C / / /'],
    'unique_chords': ['G', 'C'],
  },
};
