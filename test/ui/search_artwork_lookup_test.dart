import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _art = 'https://images.example/pentatonix.jpg';

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late AppController app;
  late AppControllerAdapter ui;
  late List<String> queries;
  late List<String> youtubeQueries;
  late Completer<List<SongCandidate>> delayedLyricsLookup;
  late Completer<void> lyricsLookupStarted;
  late bool delayLyricsLookup;

  setUp(() async {
    queries = [];
    youtubeQueries = [];
    delayedLyricsLookup = Completer<List<SongCandidate>>();
    lyricsLookupStarted = Completer<void>();
    delayLyricsLookup = false;
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([
        _Catalog('chordie', (query) {
          // The typed search returns rows without artwork.
          if (query != 'Hallelujah') return const [];
          return const [
            SongCandidate(
              providerId: 'chordie',
              id: 'p',
              title: 'Hallelujah',
              artist: 'Pentatonix',
              // Chord sheets are arrangements of the song they illustrate.
              metadata: {'identityScope': 'arrangement'},
            ),
            SongCandidate(
              providerId: 'chordie',
              id: 'k',
              title: 'Hallelujah',
              artist: 'Kate Voegele',
            ),
          ];
        }),
        _Catalog('lyricsovh', (query) {
          queries.add(query);
          if (query == 'Pentatonix Hallelujah' && delayLyricsLookup) {
            if (!lyricsLookupStarted.isCompleted) {
              lyricsLookupStarted.complete();
            }
            return delayedLyricsLookup.future;
          }
          return switch (query) {
            'Pentatonix Hallelujah' => const [
              SongCandidate(
                providerId: 'lyricsovh',
                id: 'x',
                title: 'Hallelujah',
                artist: 'Pentatonix',
                album: 'A Pentatonix Christmas',
                metadata: {'artworkUrl': _art},
              ),
            ],
            // A hit for another song never supplies artwork.
            'Kate Voegele Hallelujah' => const [
              SongCandidate(
                providerId: 'lyricsovh',
                id: 'y',
                title: 'Hallelujah',
                artist: 'Jeff Buckley',
                metadata: {'artworkUrl': 'https://images.example/jeff.jpg'},
              ),
            ],
            _ => const [],
          };
        }),
        _Catalog('youtubemusic', (query) {
          youtubeQueries.add(query);
          return query == 'Pentatonix Hallelujah'
              ? const [
                  SongCandidate(
                    providerId: 'youtubemusic',
                    id: 'yt-p',
                    title: 'Hallelujah',
                    artist: 'Pentatonix',
                    metadata: {
                      'artworkUrl': 'https://images.example/youtube.jpg',
                    },
                  ),
                ]
              : const [];
        }),
      ]),
    );
    await app.initialize();
    await app.setSearchCatalog('chordie');
    ui = AppControllerAdapter(app);
  });

  tearDown(() async {
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  test(
    'rows without artwork are looked up in enabled artwork catalogs',
    () async {
      ui.setHomeListMode(HomeListMode.online);
      ui.setQuery('Hallelujah');
      await ui.submitSearch();
      for (var i = 0; i < 5; i++) {
        await pumpEventQueue();
        ui.state;
      }

      SearchReferenceData row(String id) =>
          ui.state.autocomplete.firstWhere((item) => item.id == id);
      expect(row('chordie:p').artworkUrl, _art);
      expect(row('chordie:k').artworkUrl, isNull);
      // The typed query plus one lookup per artless row, each made once.
      expect(
        queries.where((query) => query != 'Hallelujah'),
        unorderedEquals(['Pentatonix Hallelujah', 'Kate Voegele Hallelujah']),
      );
      expect(app.artworkLookups, {'chordie:p': _art, 'chordie:k': null});
      await app.setProviderEnabled('lyricsovh', false);
      expect(app.artworkLookups, isEmpty);
    },
  );

  test('no lookup runs when artwork catalogs are disabled', () async {
    await app.setProviderEnabled('lyricsovh', false);
    await app.setProviderEnabled('youtubemusic', false);
    ui.setHomeListMode(HomeListMode.online);
    ui.setQuery('Hallelujah');
    await ui.submitSearch();
    for (var i = 0; i < 5; i++) {
      await pumpEventQueue();
      ui.state;
    }
    expect(queries, isEmpty);
    expect(youtubeQueries, isEmpty);
    expect(app.artworkLookups, isEmpty);
  });

  test('late artwork from a disabled provider is discarded', () async {
    delayLyricsLookup = true;
    await app.setProviderEnabled('youtubemusic', false);
    ui.setHomeListMode(HomeListMode.online);
    ui.setQuery('Hallelujah');
    await ui.submitSearch();
    ui.state;
    await lyricsLookupStarted.future;

    await app.setProviderEnabled('lyricsovh', false);
    expect(app.artworkLookups, isEmpty);
    await app.setProviderEnabled('youtubemusic', true);
    ui.state;
    for (var i = 0; i < 5; i++) {
      await pumpEventQueue();
      ui.state;
    }

    delayedLyricsLookup.complete(const [
      SongCandidate(
        providerId: 'lyricsovh',
        id: 'late',
        title: 'Hallelujah',
        artist: 'Pentatonix',
        metadata: {'artworkUrl': 'https://images.example/disabled.jpg'},
      ),
    ]);
    for (var i = 0; i < 5; i++) {
      await pumpEventQueue();
      ui.state;
    }

    expect(youtubeQueries, contains('Pentatonix Hallelujah'));
    expect(
      app.artworkLookups['chordie:p'],
      'https://images.example/youtube.jpg',
    );
    expect(
      ui.state.autocomplete
          .firstWhere((item) => item.id == 'chordie:p')
          .artworkUrl,
      'https://images.example/youtube.jpg',
    );
    expect(
      app.artworkLookups.values,
      isNot(contains('https://images.example/disabled.jpg')),
    );
  });
}

class _Catalog implements LyricsProvider {
  _Catalog(this.id, this.rows);

  final String id;
  final FutureOr<List<SongCandidate>> Function(String query) rows;

  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: id,
    name: id,
    capabilities: const {'catalog', 'lyrics', 'metadata'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => await rows(query);

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw const ProviderException('unavailable');
}
