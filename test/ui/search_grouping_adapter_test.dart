import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _art = 'https://images.example/cover.jpg';

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late AppController app;
  late AppControllerAdapter ui;

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([
        _CatalogProvider('genius', 'Genius', const [
          SongCandidate(
            providerId: 'genius',
            id: '1',
            title: 'Sample Song',
            artist: 'Test Artist',
            metadata: {'artworkUrl': _art},
          ),
        ]),
        _CatalogProvider('lrclib', 'LRCLIB', const [
          SongCandidate(
            providerId: 'lrclib',
            id: '7',
            title: 'Sample Song',
            artist: 'Test Artist',
            album: 'Demo Album',
            durationSeconds: 201,
          ),
          SongCandidate(
            providerId: 'lrclib',
            id: '8',
            title: 'Sample Song',
            artist: 'Test Artist',
            album: 'Greatest Hits',
            durationSeconds: 199,
          ),
        ]),
        _CatalogProvider('betterlyrics', 'Better Lyrics', const [
          SongCandidate(
            providerId: 'betterlyrics',
            id: '7',
            title: 'Sample Song',
            artist: 'Test Artist',
            album: 'Demo Album',
            durationSeconds: 201,
          ),
        ]),
      ]),
    );
    await app.initialize();
    ui = AppControllerAdapter(app);
  });

  tearDown(() async {
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  test('search shows one row per recording with every source', () async {
    ui.setHomeListMode(HomeListMode.online);
    ui.setQuery('Sample Song');
    await ui.submitSearch();
    await pumpEventQueue();

    expect(app.suggestions, hasLength(4));
    final rows = ui.state.autocomplete;
    expect(rows, hasLength(2));
    final demo = rows.firstWhere((row) => row.album == 'Demo Album');
    // The preferred catalog's row is opened and listed first.
    expect(demo.id, 'genius:1');
    expect(demo.sourceNames, ['Genius', 'Better Lyrics', 'LRCLIB']);
    expect(demo.durationSeconds, 201);
    expect(demo.artworkUrl, _art);
    final hits = rows.firstWhere((row) => row.album == 'Greatest Hits');
    expect(hits.id, 'lrclib:8');
    expect(hits.sourceNames, ['LRCLIB']);
    expect(hits.artworkUrl, isNull);

    await ui.selectReference(demo);
    expect(app.selection?.identity, 'genius:1');
  });
}

class _CatalogProvider implements LyricsProvider {
  _CatalogProvider(this.id, this.name, this.rows);

  final String id, name;
  final List<SongCandidate> rows;

  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: id,
    name: name,
    capabilities: const {'catalog', 'lyrics', 'metadata'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => rows;

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(candidate: candidate, body: 'A line\nAnother');
}
