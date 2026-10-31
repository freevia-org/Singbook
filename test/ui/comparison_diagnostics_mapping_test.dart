import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _lyrics =
    'A paper satellite sails above the desk tonight\n'
    'Our quiet room remembers all the stories from the rain';

const _candidate = SongCandidate(
  providerId: 'fixture',
  id: 'paper-satellites',
  title: 'Paper Satellites',
  artist: 'Fixture Ensemble',
  url: 'https://fixture.example/private/path?token=private#fragment',
);

class _MetadataProvider implements LyricsProvider {
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'fixture',
    name: 'Metadata fixture',
    capabilities: {'catalog', 'lyrics'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_candidate];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: _candidate,
    body: _lyrics,
    matchKind: MatchKind.sameRecording,
    metadata: const {
      'key': 'C',
      'capo': 2,
      'time_signature': '3/4',
      'composer': [
        {'name': 'Ada Lovelace', 'role': 'composer'},
      ],
      'mediaLinks': [
        {
          'url':
              'https://genius.com/ada-lovelace-paper-satellites-lyrics?utm_source=private#private',
          'title': 'Genius lyrics',
          'type': 'lyrics',
        },
        {
          'url':
              'https://www.youtube.com/watch?v=Abc_123-xY0&list=private#private',
          'title': 'Studio recording',
          'type': 'video',
        },
        {
          'url': 'https://scores.example/private/path?secret=private#private',
          'title': 'Studio score',
          'type': 'score',
        },
      ],
      'privateToken': 'do not expose',
    },
  );
}

class _IdentityDiscovery extends SourceDiscoveryService {
  _IdentityDiscovery(this.result) : super(const []);

  final SourceResult result;
  late AppController app;
  bool preservedCombinedForNoOp = false;
  bool replacedCombinedForNewResult = false;
  bool updatedCombinedMetadata = false;

  @override
  List<ProviderDefinition> get definitions => const [
    ProviderDefinition(
      id: 'fixture',
      name: 'Identity fixture',
      capabilities: {'lyrics'},
    ),
  ];

  @override
  Future<List<SourceResult>> discover(
    SongCandidate selection, {
    Set<String>? enabledIds,
    void Function(ProviderCheck)? onProgress,
    CancellationToken? cancel,
    Map<String, CancellationToken> providerCancellation = const {},
    Duration alternativeTimeout = const Duration(seconds: 30),
  }) async {
    await app.flushCombine();
    final before = app.combined;
    final cached = app.results.single;
    onProgress?.call(
      ProviderCheck(providerId: 'fixture', state: 'found', result: cached),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    preservedCombinedForNoOp = identical(app.combined, before);
    onProgress?.call(
      ProviderCheck(providerId: 'fixture', state: 'found', result: result),
    );
    for (var i = 0; i < 100 && identical(app.combined, before); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    replacedCombinedForNewResult = !identical(app.combined, before);
    updatedCombinedMetadata = app.combined?.metadata['key'] == 'D';
    return [result];
  }
}

void main() {
  sqfliteFfiInit();

  test(
    'comparison diagnostics map useful metadata immutably and safely',
    () async {
      final repository = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([_MetadataProvider()]),
      );
      await app.initialize();
      app.settings['catalog'] = 'fixture';
      final ui = AppControllerAdapter(app);
      try {
        ui.setHomeListMode(HomeListMode.online);
        ui.setQuery('Paper Satellites');
        await ui.submitSearch();
        await ui.selectReference(
          const SearchReferenceData(
            id: 'fixture:paper-satellites',
            title: 'Paper Satellites',
            artist: 'Fixture Ensemble',
          ),
        );

        final comparison = ui.state.comparison!;
        final version = comparison.alternatives.single;
        expect(version.metadata['key'], 'C');
        expect(version.metadata['capo'], '2');
        expect(version.metadata['timeSignature'], '3/4');
        expect(version.metadata['composer'], ['Ada Lovelace · composer']);
        expect(version.metadata['mediaLinks'], [
          'Genius lyrics\nhttps://genius.com/ada-lovelace-paper-satellites-lyrics',
          'Studio recording\nhttps://www.youtube.com/watch?v=Abc_123-xY0',
          'Studio score\nhttps://scores.example',
        ]);
        expect(version.metadata.containsKey('privateToken'), isFalse);
        expect(version.sourceUrl, 'https://fixture.example');
        expect(() => version.metadata['key'] = 'D', throwsUnsupportedError);
        expect(
          () => (version.metadata['composer'] as List).add('changed'),
          throwsUnsupportedError,
        );
        expect(
          () => (version.metadata['mediaLinks'] as List).add('https://bad'),
          throwsUnsupportedError,
        );

        final fetch = comparison.providerChecks.single.operations.singleWhere(
          (operation) => operation.phase == 'fetch',
        );
        expect(fetch.id, 'fixture:lookup:fetch:0');
        expect(fetch.sourceUrl, 'https://fixture.example');
        expect(
          () => comparison.providerChecks.single.operations.clear(),
          throwsUnsupportedError,
        );
      } finally {
        ui.dispose();
        app.dispose();
        await repository.close();
      }
    },
  );

  test(
    'no-op discovery updates preserve combine until a new result arrives',
    () async {
      const selected = SongCandidate(
        providerId: 'fixture',
        id: 'selected',
        title: 'Paper Satellites',
        artist: 'Fixture Ensemble',
      );
      const cached = SourceResult(
        candidate: SongCandidate(
          providerId: 'fixture',
          id: 'selected',
          title: 'Paper Satellites',
          artist: 'Fixture Ensemble',
        ),
        body: _lyrics,
        matchKind: MatchKind.sameSong,
      );
      const fresh = SourceResult(
        candidate: SongCandidate(
          providerId: 'fixture',
          id: 'selected',
          title: 'Paper Satellites',
          artist: 'Fixture Ensemble',
        ),
        body: _lyrics,
        matchKind: MatchKind.sameRecording,
        metadata: {'key': 'D'},
      );
      final discovery = _IdentityDiscovery(fresh);
      final repository = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final app = AppController(repository: repository, discovery: discovery);
      discovery.app = app;
      try {
        await app.initialize();
        await app.selectCandidate(selected, cachedResults: [cached]);
        expect(discovery.preservedCombinedForNoOp, isTrue);
        expect(discovery.replacedCombinedForNewResult, isTrue);
        expect(discovery.updatedCombinedMetadata, isTrue);
      } finally {
        app.dispose();
        await repository.close();
      }
    },
  );
}
