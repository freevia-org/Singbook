import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _query = 'Lonely Stranger';
const _definitions = [
  ProviderDefinition(id: 'genius', name: 'Genius', capabilities: {'catalog'}),
  ProviderDefinition(id: 'lrclib', name: 'LRCLIB', capabilities: {'catalog'}),
];

void main() {
  sqfliteFfiInit();

  test(
    'streamed catalog batches keep the preferred artwork row first',
    () async {
      final h = await _Harness.open();
      addTearDown(h.close);
      h.ui.setHomeListMode(HomeListMode.online);
      h.ui.setQuery(_query);
      final search = h.ui.submitSearch();
      final genius = await h.discovery.searchAt('genius');
      final lrclib = await h.discovery.searchAt('lrclib');
      final artwork = _candidate(
        'genius',
        '333411',
        'Lonely Stranger (Acoustic Live)',
        metadata: const {
          'artworkUrl': 'https://images.genius.com/synthetic.png',
        },
      );

      genius.complete([artwork]);
      await _settle();
      expect(h.app.searching, isTrue);
      expect(h.ui.state.searchState, LoadState.loaded);
      expect(h.ui.state.autocomplete.single.id, 'genius:333411');
      expect(
        h.ui.state.autocomplete.single.artworkUrl,
        'https://images.genius.com/synthetic.png',
      );

      lrclib.complete([
        for (var i = 0; i < 80; i++)
          _candidate(
            'lrclib',
            'late-$i',
            _query,
            album: i == 0 ? 'Eric Clapton Unplugged' : 'Compilation $i',
            durationSeconds: i == 0 ? 351 : (200 + i).toDouble(),
          ),
        _candidate(
          'lrclib',
          'edition-327',
          _query,
          album: 'Eric Clapton - MTV Unplugged',
          durationSeconds: 327,
        ),
      ]);
      await search;

      final references = h.ui.state.autocomplete;
      expect(references.first.id, 'genius:333411');
      expect(references.first.providerId, 'genius');
      expect(
        references.first.artworkUrl,
        'https://images.genius.com/synthetic.png',
      );
      expect(references[1].providerId, 'lrclib');
      expect(references, hasLength(82));
      final editions = {
        for (final reference in references.where(
          (reference) => reference.providerId == 'lrclib',
        ))
          reference.id: reference,
      };
      expect(editions['lrclib:late-0']!.album, 'Eric Clapton Unplugged');
      expect(editions['lrclib:late-0']!.durationSeconds, 351);
      expect(
        editions['lrclib:edition-327']!.album,
        'Eric Clapton - MTV Unplugged',
      );
      expect(editions['lrclib:edition-327']!.durationSeconds, 327);

      final selection = h.ui.selectReference(references.first);
      await _settle();
      expect(h.app.selection?.identity, 'genius:333411');
      expect(h.app.selection?.artworkUrl, artwork.artworkUrl);
      final discovery = await h.discovery.discoveryAt(0);
      discovery.complete();
      await selection;
    },
  );

  test(
    'provider grouping is stable when the secondary completes first',
    () async {
      final h = await _Harness.open();
      addTearDown(h.close);
      h.ui.setHomeListMode(HomeListMode.online);
      h.ui.setQuery(_query);
      final search = h.ui.submitSearch();
      final genius = await h.discovery.searchAt('genius');
      final lrclib = await h.discovery.searchAt('lrclib');

      lrclib.complete([_candidate('lrclib', 'secondary', _query)]);
      await _settle();
      expect(h.ui.state.autocomplete.single.providerId, 'lrclib');
      genius.complete([
        _candidate(
          'genius',
          'primary',
          '$_query (Live)',
          metadata: const {'artworkUrl': 'https://images.genius.com/live.png'},
        ),
      ]);
      await search;

      expect(h.ui.state.autocomplete.map((reference) => reference.id), [
        'genius:primary',
        'lrclib:secondary',
      ]);
      expect(
        h.ui.state.autocomplete.first.artworkUrl,
        'https://images.genius.com/live.png',
      );
    },
  );
}

SongCandidate _candidate(
  String provider,
  String id,
  String title, {
  String? album,
  double? durationSeconds,
  JsonMap metadata = const {},
}) => SongCandidate(
  providerId: provider,
  id: id,
  title: title,
  artist: 'Eric Clapton',
  album: album,
  durationSeconds: durationSeconds,
  metadata: metadata,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

class _Harness {
  _Harness(this.repository, this.discovery, this.app, this.ui);

  final LibraryRepository repository;
  final _ControlledDiscovery discovery;
  final AppController app;
  final AppControllerAdapter ui;

  static Future<_Harness> open() async {
    final repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    final discovery = _ControlledDiscovery();
    final app = AppController(repository: repository, discovery: discovery);
    await app.initialize();
    return _Harness(repository, discovery, app, AppControllerAdapter(app));
  }

  Future<void> close() async {
    ui.dispose();
    app.dispose();
    for (final request in discovery.searches) {
      if (!request.response.isCompleted) request.complete([]);
    }
    for (final request in discovery.discoveries) {
      if (!request.response.isCompleted) request.complete();
    }
    await repository.close();
  }
}

class _ControlledDiscovery extends SourceDiscoveryService {
  _ControlledDiscovery() : super(_definitions.map(_NeverProvider.new).toList());

  final searches = <_CatalogRequest>[];
  final discoveries = <_DiscoveryRequest>[];
  final _searchWaiters = <String, Completer<_CatalogRequest>>{};
  final _discoveryWaiters = <int, Completer<_DiscoveryRequest>>{};

  Future<_CatalogRequest> searchAt(String provider) {
    final existing = searches
        .where((request) => request.providerId == provider)
        .firstOrNull;
    return existing == null
        ? (_searchWaiters[provider] ??= Completer<_CatalogRequest>()).future
        : Future.value(existing);
  }

  Future<_DiscoveryRequest> discoveryAt(int index) => index < discoveries.length
      ? Future.value(discoveries[index])
      : (_discoveryWaiters[index] ??= Completer<_DiscoveryRequest>()).future;

  @override
  Future<List<SongCandidate>> search(
    String query, {
    String providerId = 'genius',
    CancellationToken? cancel,
  }) {
    final request = _CatalogRequest(providerId, cancel);
    searches.add(request);
    _searchWaiters.remove(providerId)?.complete(request);
    return request.response.future;
  }

  @override
  Future<List<SourceResult>> discover(
    SongCandidate selection, {
    Set<String>? enabledIds,
    void Function(ProviderCheck)? onProgress,
    CancellationToken? cancel,
    Map<String, CancellationToken> providerCancellation = const {},
    Duration alternativeTimeout = const Duration(seconds: 30),
  }) {
    final request = _DiscoveryRequest();
    discoveries.add(request);
    _discoveryWaiters.remove(discoveries.length - 1)?.complete(request);
    return request.response.future;
  }
}

class _NeverProvider implements LyricsProvider {
  _NeverProvider(this.definition);

  @override
  final ProviderDefinition definition;

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) => throw StateError('Search calls are controlled by the test.');

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) => throw StateError('Discovery calls are controlled by the test.');
}

class _CatalogRequest {
  _CatalogRequest(this.providerId, this.cancel);

  final String providerId;
  final CancellationToken? cancel;
  final response = Completer<List<SongCandidate>>();

  void complete(List<SongCandidate> rows) => response.complete(rows);
}

class _DiscoveryRequest {
  final response = Completer<List<SourceResult>>();

  void complete() => response.complete([]);
}
