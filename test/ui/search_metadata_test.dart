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

  Future<void> start(List<_CatalogProvider> providers) async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService(providers),
    );
    await app.initialize();
    ui = AppControllerAdapter(app);
  }

  tearDown(() async {
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  Future<void> search() async {
    ui.setHomeListMode(HomeListMode.online);
    ui.setQuery('Sample Song');
    await ui.submitSearch();
    await pumpEventQueue();
  }

  test(
    'search rows combine album, duration and artwork across catalogs',
    () async {
      await start([
        _CatalogProvider('genius', const [
          SongCandidate(
            providerId: 'genius',
            id: '1',
            title: 'Sample Song',
            artist: 'Test Artist',
            metadata: {'artworkUrl': _art},
          ),
          SongCandidate(
            providerId: 'genius',
            id: '2',
            title: 'Unrelated',
            artist: 'Other Artist',
          ),
        ]),
        _CatalogProvider('lrclib', const [
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
            title: 'Sample Song (Live)',
            artist: 'Test Artist',
            album: 'Live Album',
            durationSeconds: 260,
          ),
        ]),
      ]);
      await search();

      SearchReferenceData row(String id) =>
          ui.state.autocomplete.firstWhere((item) => item.id == id);
      expect(row('genius:1').album, 'Demo Album');
      expect(row('genius:1').durationSeconds, 201);
      expect(row('genius:1').artworkUrl, _art);
      expect(row('lrclib:7').artworkUrl, _art);
      expect(row('lrclib:7').album, 'Demo Album');
      // Another song or edition keeps only its own facts.
      expect(row('genius:2').album, isNull);
      expect(row('genius:2').artworkUrl, isNull);
      expect(row('lrclib:8').artworkUrl, isNull);
      expect(row('lrclib:8').album, 'Live Album');
      // Rows keep their identities; nothing is merged away or added.
      expect(ui.state.autocomplete, hasLength(4));
    },
  );

  test('lyrics versions show the selected song metadata and artwork', () async {
    await start([
      _CatalogProvider('genius', const [
        SongCandidate(
          providerId: 'genius',
          id: '1',
          title: 'Sample Song',
          artist: 'Test Artist',
          metadata: {'artworkUrl': _art},
        ),
      ], body: 'Genius line one\nTwo'),
      _CatalogProvider('lrclib', const [
        SongCandidate(
          providerId: 'lrclib',
          id: '7',
          title: 'Sample Song',
          artist: 'Test Artist',
          album: 'Demo Album',
          durationSeconds: 200,
        ),
      ], body: 'Lrclib line one\nTwo'),
      _CatalogProvider(
        'other',
        const [
          SongCandidate(
            providerId: 'other',
            id: '9',
            title: 'Different Song',
            artist: 'Test Artist',
          ),
        ],
        body: 'Other line one\nTwo',
        catalog: false,
      ),
    ]);
    await search();
    await ui.selectReference(
      ui.state.autocomplete.firstWhere((item) => item.id == 'genius:1'),
    );
    await pumpEventQueue();

    final comparison = ui.state.comparison!;
    expect(comparison.reference.artworkUrl, _art);
    expect(comparison.reference.album, 'Demo Album');
    final lrclib = comparison.alternatives.firstWhere(
      (item) => item.providerId == 'lrclib',
    );
    expect(lrclib.artworkUrl, _art);
    expect(lrclib.album, 'Demo Album');
    expect(lrclib.durationSeconds, 200);
    final genius = comparison.alternatives.firstWhere(
      (item) => item.providerId == 'genius',
    );
    expect(genius.album, 'Demo Album');
    expect(genius.durationSeconds, 200);
    for (final version in comparison.alternatives.where(
      (item) => item.providerId == 'other',
    )) {
      expect(version.artworkUrl, isNull);
    }
  });
}

class _CatalogProvider implements LyricsProvider {
  _CatalogProvider(this.id, this.rows, {this.body = '', this.catalog = true});

  final String id, body;
  final List<SongCandidate> rows;
  final bool catalog;

  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: id,
    name: id,
    capabilities: {if (catalog) 'catalog', 'lyrics', 'metadata'},
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
  }) async {
    if (body.isEmpty) throw const ProviderException('unavailable');
    return SourceResult(candidate: candidate, body: body);
  }
}
