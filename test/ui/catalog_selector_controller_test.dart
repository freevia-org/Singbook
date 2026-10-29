import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/catalogs.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_catalog_client.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  sqfliteFfiInit();

  Future<_Harness> open({
    List<LyricsProvider>? providers,
    JsonMap settings = const {},
  }) async {
    final harness = await _Harness.open(
      providers: providers,
      settings: settings,
    );
    addTearDown(harness.close);
    return harness;
  }

  Future<void> waitForCombined(
    _Harness harness,
    bool Function() condition,
  ) async {
    if (condition()) return;
    final changed = Completer<void>();
    late void Function() listener;
    listener = () {
      if (condition() && !changed.isCompleted) changed.complete();
    };
    harness.app.addListener(listener);
    try {
      await changed.future.timeout(const Duration(seconds: 2));
    } finally {
      harness.app.removeListener(listener);
    }
  }

  test('catalogs come from capability, enablement and configuration', () async {
    final h = await open();
    // Wikisource deliberately precedes LRCLIB in the registry.
    expect(h.app.searchCatalogs.map((provider) => provider.id), [
      'wikisource',
      'lrclib',
    ]);
    expect(h.app.searchCatalogId, 'lrclib');
    expect(h.ui.state.searchCatalogs.map((provider) => provider.id), [
      'wikisource',
      'lrclib',
    ]);
    expect(h.ui.state.searchCatalogId, 'lrclib');
    expect(
      const ProviderDefinition(id: 'public', name: 'Public').configured,
      isTrue,
      reason: 'existing providers remain configured when the flag is omitted',
    );

    final localCatalog = _PendingProvider('local-archive');
    h.discovery.active = [localCatalog];
    await h.app.setSetting('syntheticRegistryRevision', 2);
    expect(h.app.searchCatalogs.single.id, 'local-archive');
    expect(h.ui.state.searchCatalogs.single.id, 'local-archive');
    expect(h.ui.state.searchCatalogId, 'local-archive');
    expect(await h.app.setSearchCatalog('lrclib'), isFalse);
    expect(await h.app.setSearchCatalog('local-archive'), isTrue);
    expect(localCatalog.requests, isEmpty);
  });

  test('Genius configuration and wrappers follow the compiled token', () async {
    final transport = ProviderTransport(
      client: MockClient((_) async => throw StateError('Unexpected HTTP call')),
    );
    addTearDown(transport.close);
    final entry = SourceCatalogEntry.fromJson({
      'id': 'genius',
      'name': 'Synthetic Genius catalog',
      'adapter': 'builtin',
      'status': 'active',
      'revision': 1,
      'capabilities': ['catalog', 'lyrics', 'metadata'],
      'enabledByDefault': true,
      'accessMode': 'public',
      'website': 'https://example.org/',
      'hosts': <String>[],
    });
    for (final token in ['', '   ', 'synthetic-test-token']) {
      final builtin = GeniusProvider(transport, token: token);
      final wrapped = ConfiguredBuiltinProvider(entry, builtin);
      final configured = token.trim().isNotEmpty;
      expect(builtin.definition.configured, configured);
      expect(wrapped.definition.configured, configured);
      final h = await open(
        providers: [wrapped],
        // A remembered enablement must not invent a missing token.
        settings: const {
          'providers': {'genius': true},
        },
      );
      expect(
        h.app.searchCatalogs.map((provider) => provider.id),
        configured ? ['genius'] : isEmpty,
      );
      expect(h.ui.state.searchCatalogId, configured ? 'genius' : isNull);
      expect(await h.app.setSearchCatalog('genius'), configured);
    }
  });

  test(
    'invalid choices preserve provider preferences and do not search',
    () async {
      final h = await open();
      h.online('');
      await h.app.setSetting('syntheticBarrier', true);
      final before = await h.repository.getSetting('app');
      final state = h.ui.state;
      for (final id in [
        'unconfigured',
        'disabled',
        'metadata-only',
        'missing',
      ]) {
        expect(await h.app.setSearchCatalog(id), isFalse, reason: id);
        await h.ui.setSearchCatalog(id);
        expect(h.app.searchCatalogId, 'lrclib');
        expect(h.ui.state.searchCatalogId, 'lrclib');
      }
      expect(await h.repository.getSetting('app'), before);
      expect(h.app.providerEnabled('disabled'), isFalse);
      expect(h.app.providerEnabled('unconfigured'), isTrue);
      expect(
        h.ui.state.providers.map((provider) => provider.enabled),
        state.providers.map((provider) => provider.enabled),
      );
      expect(h.allRequests, isEmpty);
    },
  );

  test(
    'no available catalog fails locally and can recover after enablement',
    () async {
      final h = await open();
      await h.app.setProviderEnabled('lrclib', false);
      await h.app.setProviderEnabled('wikisource', false);
      expect(h.app.searchCatalogs, isEmpty);
      expect(h.ui.state.searchCatalogId, isNull);
      expect(await h.app.setSearchCatalog('unconfigured'), isFalse);
      h.online('Lantern path');
      await h.ui.submitSearch();
      expect(h.allRequests, isEmpty);
      expect(h.app.searching, isFalse);
      expect(h.ui.state.searchState, LoadState.failed);
      expect(h.ui.state.searchError, 'not_configured');

      await h.app.setProviderEnabled('wikisource', true);
      final search = h.ui.submitSearch();
      final request = await h.wiki.requestAt(0);
      request.complete('available');
      await search;
      expect(h.ui.state.searchCatalogId, 'wikisource');
      expect(h.ui.state.searchError, isNull);
      expect(h.ui.state.searchState, LoadState.loaded);
    },
  );

  test(
    'same-query catalog switch cancels and ignores the old response',
    () async {
      final h = await open();
      h.online('Lantern path');
      final firstSearch = h.ui.submitSearch();
      final old = await h.lrclib.requestAt(0);
      final change = h.ui.setSearchCatalog('wikisource');
      final current = await h.wiki.requestAt(0);
      expect(old.cancel?.isCancelled, isTrue);
      expect(current.query, old.query);
      expect(h.ui.state.autocomplete, isEmpty);
      expect(h.ui.state.comparison, isNull);
      current.complete('new-catalog');
      await change;
      old.complete('stale-catalog');
      await firstSearch;
      expect(h.app.suggestions.single.id, 'new-catalog');
      expect(h.ui.state.autocomplete.single.id, 'wikisource:new-catalog');
      expect(h.ui.state.searchCatalogId, 'wikisource');
      expect(h.app.searching, isFalse);
    },
  );

  test(
    'only the trusted historical catalog adds a historical text disclosure',
    () async {
      final h = await open();
      h.online('Lantern path');
      final search = h.ui.submitSearch();
      final request = await h.lrclib.requestAt(0);
      request.response.complete(const [
        SongCandidate(
          providerId: 'lrclib',
          id: 'recording',
          title: 'Lantern path',
          artist: 'Synthetic ensemble',
          metadata: {'identityScope': 'historicalText'},
        ),
      ]);
      await search;
      expect(h.ui.state.autocomplete.single.isHistoricalText, isFalse);
      final change = h.ui.setSearchCatalog('wikisource');
      (await h.wiki.requestAt(0)).complete('historical-work');
      await change;
      expect(h.ui.state.autocomplete.single.isHistoricalText, isTrue);
    },
  );

  test(
    'rapid LRCLIB to Wikisource to LRCLIB cannot revive either old callback',
    () async {
      final h = await open();
      h.online('Lantern path');
      final firstSearch = h.ui.submitSearch();
      final first = await h.lrclib.requestAt(0);
      final middleChange = h.ui.setSearchCatalog('wikisource');
      final middle = await h.wiki.requestAt(0);
      final lastChange = h.ui.setSearchCatalog('lrclib');
      final last = await h.lrclib.requestAt(1);
      expect(first.cancel?.isCancelled, isTrue);
      expect(middle.cancel?.isCancelled, isTrue);
      last.complete('latest');
      await lastChange;
      middle.complete('obsolete-middle');
      await middleChange;
      first.complete('obsolete-first');
      await firstSearch;
      expect(h.app.suggestions.single.id, 'latest');
      expect(h.ui.state.autocomplete.single.id, 'lrclib:latest');
      expect(h.ui.state.searchCatalogId, 'lrclib');
      expect(h.ui.state.searchState, LoadState.loaded);
    },
  );

  test(
    'disabling the selected catalog drops cached results and preserves preference',
    () async {
      final h = await open();
      await h.app.setSearchCatalog('wikisource');
      h.online('Lantern path');
      final search = h.ui.submitSearch();
      (await h.wiki.requestAt(0)).complete('cached-wiki');
      await search;
      expect(h.ui.state.autocomplete, isNotEmpty);
      await h.app.setProviderEnabled('wikisource', false);
      expect(h.app.settings['catalog'], 'wikisource');
      expect(h.ui.state.searchCatalogId, 'lrclib');
      expect(h.ui.state.autocomplete, isEmpty);
      expect(h.app.suggestions, isEmpty);
      expect(
        h.allRequests,
        hasLength(1),
        reason: 'disable does not launch a lookup',
      );
      await h.app.setProviderEnabled('wikisource', true);
      expect(h.ui.state.searchCatalogId, 'wikisource');
      expect(h.ui.state.autocomplete, isEmpty);
      expect(
        jsonMap(await h.repository.getSetting('app'))['catalog'],
        'wikisource',
      );
    },
  );

  test(
    'disabling a fallback cancels its pending search without rewriting preference',
    () async {
      final h = await open(settings: const {'catalog': 'retired-catalog'});
      h.online('Lantern path');
      final oldSearch = h.ui.submitSearch();
      final pending = await h.lrclib.requestAt(0);
      await h.app.setProviderEnabled('lrclib', false);
      expect(pending.cancel?.isCancelled, isTrue);
      expect(h.ui.state.searchCatalogId, 'wikisource');
      expect(h.app.settings['catalog'], 'retired-catalog');
      pending.complete('disabled-fallback');
      await oldSearch;
      expect(h.ui.state.autocomplete, isEmpty);
      expect(h.app.suggestions, isEmpty);
      expect(h.app.searching, isFalse);
      await h.app.setProviderEnabled('lrclib', true);
      expect(h.ui.state.searchCatalogId, 'lrclib');
      expect(h.app.settings['catalog'], 'retired-catalog');
    },
  );

  test(
    'catalog preference survives controller reopen without changing saved works',
    () async {
      final h = await open();
      await h.app.saveSong(
        SongDocument(
          id: 'owned-song',
          title: 'Lantern path',
          artist: 'Synthetic ensemble',
          body:
              '[C]Paper lanterns cross the hill\n[G]Morning finds the garden still',
          metadata: {'key': 'C', 'language': 'en'},
        ),
      );
      await h.app.saveSetlist(
        SetlistDocument(
          id: 'owned-setlist',
          name: 'Synthetic evening',
          entries: const [
            SetlistEntry(id: 'owned-entry', songId: 'owned-song'),
          ],
        ),
      );
      final before = await _savedRows(h.repository);
      h.online('');
      await h.ui.setSearchCatalog('wikisource');
      final persisted = jsonMap(await h.repository.getSetting('app'));
      expect(persisted['catalog'], 'wikisource');
      expect(persisted.containsKey('providers'), isFalse);
      expect(await _savedRows(h.repository), before);

      // Reopen application state over the same real in-memory SQLite database.
      h.ui.dispose();
      h.app.dispose();
      h.app = AppController(repository: h.repository, discovery: h.discovery);
      await h.app.initialize();
      h.ui = AppControllerAdapter(h.app);
      expect(h.ui.state.searchCatalogId, 'wikisource');
      expect(await _savedRows(h.repository), before);
      expect(h.app.songs.single.body, contains('Paper lanterns'));
      expect(h.app.setlists.single.entries.single.songId, 'owned-song');
      expect(h.allRequests, isEmpty);
    },
  );

  test('queued preference writes retain the latest rapid choice', () async {
    final h = await open();
    final gate = await _holdWrites(h.repository);
    addTearDown(gate.release);
    final first = h.app.setSearchCatalog('wikisource');
    final second = h.app.setSearchCatalog('lrclib');
    final third = h.app.setSearchCatalog('wikisource');
    expect(h.app.searchCatalogId, 'lrclib');
    expect(h.ui.state.searchCatalogId, 'lrclib');
    await gate.release();
    await Future.wait([first, second, third]);
    expect(
      jsonMap(await h.repository.getSetting('app'))['catalog'],
      'wikisource',
    );
    expect(h.ui.state.searchCatalogId, 'wikisource');
    expect(h.app.searching, isFalse);
    expect(h.allRequests, isEmpty);
  });

  test(
    'idle navigation writes reach an immediate read and fresh controller',
    () async {
      final h = await open();
      await h.ui.setStartupSongsView('last');
      h.ui.setHomeListMode(HomeListMode.library);
      h.ui.setFavoritesOnly(true);
      h.ui.setHomeListMode(HomeListMode.online);
      h.ui.setFavoritesOnly(false);
      h.ui.setHomeListMode(HomeListMode.favorites);
      final persisted = jsonMap(await h.repository.getSetting('app'));
      expect(persisted['lastSongsView'], 'library');
      expect(persisted['lastSongsFavoritesOnly'], isTrue);
      h.ui.dispose();
      h.app.dispose();
      h.app = AppController(repository: h.repository, discovery: h.discovery);
      h.ui = AppControllerAdapter(h.app);
      await h.ui.initialize();
      expect(h.ui.state.homeListMode, HomeListMode.library);
      expect(h.ui.state.favoritesOnly, isTrue);
      expect(h.allRequests, isEmpty);
    },
  );

  test('ordinary writes cannot overtake a failing catalog-lane tail', () async {
    final h = await open(settings: const {'catalog': 'lrclib'});
    await _observeCatalogWrites(h.repository, failures: {}, failedAttempt: 2);
    final gate = await _holdWrites(h.repository);
    addTearDown(gate.release);
    final catalog = h.app.setSearchCatalog('wikisource');
    final tail = _captureWriteError(h.app.setSetting('palette', 'plum'));
    await gate.release();
    expect(await catalog, isTrue);
    // The catalog has completed, but its earlier ordinary write still belongs
    // to this lane. The second database attempt must fail the tail, not this
    // later ordinary write, even when both documents contain the latest keys.
    final later = _captureWriteError(h.app.setSetting('notation', 'letters'));
    expect(await tail, isA<DatabaseException>());
    expect(await later, isNull);
    expect(await _catalogWriteAttempts(h.repository), hasLength(3));
    await _expectCatalogAgreement(h, 'wikisource');
    final saved = jsonMap(await h.repository.getSetting('app'));
    expect(saved['palette'], 'plum');
    expect(saved['notation'], 'letters');
    h.ui.setHomeListMode(HomeListMode.favorites);
    final immediate = jsonMap(await h.repository.getSetting('app'));
    expect(immediate['lastSongsView'], 'library');
    expect(immediate['lastSongsFavoritesOnly'], isTrue);
  });

  test(
    'overlapping persisted choices launch only the latest catalog lookup',
    () async {
      final h = await open();
      h.online('Lantern path');
      final oldSearch = h.ui.submitSearch();
      final old = await h.lrclib.requestAt(0);
      await h.app.setSetting('syntheticBarrier', true);
      final gate = await _holdWrites(h.repository);
      addTearDown(gate.release);
      final middle = h.ui.setSearchCatalog('wikisource');
      final latest = h.ui.setSearchCatalog('lrclib');
      expect(old.cancel?.isCancelled, isTrue);
      await gate.release();
      final current = await h.lrclib.requestAt(1);
      expect(h.wiki.requests, isEmpty);
      current.complete('last-persisted-choice');
      await Future.wait([middle, latest]);
      old.complete('obsolete-before-persistence');
      await oldSearch;
      expect(h.ui.state.autocomplete.single.id, 'lrclib:last-persisted-choice');
      expect(h.ui.state.searchCatalogId, 'lrclib');
      expect(
        jsonMap(await h.repository.getSetting('app'))['catalog'],
        'lrclib',
      );
      expect(h.app.searching, isFalse);
    },
  );

  test(
    'Settings navigation during preference persistence does not start a search',
    () async {
      final h = await open();
      h.online('Lantern path');
      final oldSearch = h.ui.submitSearch();
      final old = await h.lrclib.requestAt(0);
      // Drain the view-preference writes before holding the catalog write.
      await h.app.setSetting('syntheticBarrier', true);
      final gate = await _holdWrites(h.repository);
      addTearDown(gate.release);
      final change = h.ui.setSearchCatalog('wikisource');
      h.ui.setTab(VerseTab.settings);
      expect(old.cancel?.isCancelled, isTrue);
      await gate.release();
      await change;
      old.complete('late-after-settings');
      await oldSearch;
      expect(h.ui.state.activeTab, VerseTab.settings);
      expect(h.ui.state.route, VerseRoute.main);
      expect(h.wiki.requests, isEmpty);
      expect(h.ui.state.autocomplete, isEmpty);
      expect(h.app.searching, isFalse);
      expect(
        jsonMap(await h.repository.getSetting('app'))['catalog'],
        'wikisource',
      );
    },
  );

  test(
    'a newer Online selection and discovery survive an earlier catalog commit',
    () async {
      final h = await open();
      h.discovery.holdDiscoveries = true;
      h.online('');
      await h.app.setSetting('syntheticBarrier', true);
      final gate = await _holdWrites(h.repository);
      addTearDown(gate.release);
      h.ui.setQuery('Original query');
      final change = h.ui.setSearchCatalog('wikisource');
      expect(h.ui.state.searchCatalogId, 'lrclib');

      // These are the normal Online query, result and selection entry points.
      h.ui.setQuery('Newer lantern query');
      final interimSearch = h.ui.submitSearch();
      (await h.lrclib.requestAt(0)).complete('newer-selection');
      await interimSearch;
      final candidate = h.app.suggestions.single;
      final selection = h.ui.selectReference(h.ui.state.autocomplete.single);
      final discovery = await h.discovery.discoveryAt(0);
      expect(discovery.selection.identity, candidate.identity);
      final source = SourceResult(
        candidate: candidate,
        body: 'Synthetic lanterns greet the day\nSynthetic clouds drift away',
        matchKind: MatchKind.sameSong,
        matchReason: 'same_song',
      );
      discovery.publish(source);
      expect(h.app.selection?.identity, candidate.identity);
      expect(h.app.discovering, isTrue);
      expect(h.app.combined?.body, source.body);

      await gate.release();
      await change;
      await _expectCatalogAgreement(h, 'wikisource');
      expect(h.app.selection?.identity, candidate.identity);
      expect(h.app.results.single.toJson(), source.toJson());
      expect(h.app.combined?.body, source.body);
      expect(h.app.discovering, isTrue);
      expect(discovery.cancel?.isCancelled, isFalse);
      expect(h.ui.state.comparison, isNotNull);
      expect(h.ui.state.query, 'Newer lantern query');
      expect(h.ui.state.homeListMode, HomeListMode.online);
      expect(
        h.wiki.requests,
        isEmpty,
        reason: 'the old catalog setter cannot search its obsolete query',
      );
      expect(h.lrclib.requests, hasLength(1));

      discovery.response.complete([source]);
      await selection;
      expect(h.app.discovering, isFalse);
      expect(h.app.selection?.identity, candidate.identity);
      expect(h.app.combined?.body, source.body);
      expect(h.ui.state.comparison, isNotNull);
    },
  );

  test(
    'clustered discovery recomputes settle on the latest source set',
    () async {
      final h = await open(
        providers: [
          _PendingProvider('alpha'),
          _PendingProvider('beta'),
          _PendingProvider('gamma'),
        ],
      );
      h.discovery.holdDiscoveries = true;
      final candidate = SongCandidate(
        providerId: 'catalog',
        id: 'lantern-song',
        title: 'Lantern Song',
        artist: 'Lanterns',
      );
      SourceResult result(
        String provider,
        String body, {
        JsonMap metadata = const {},
      }) => SourceResult(
        candidate: SongCandidate(
          providerId: provider,
          id: 'lantern-song',
          title: candidate.title,
          artist: candidate.artist,
        ),
        body: body,
        metadata: metadata,
        matchKind: MatchKind.sameSong,
        matchReason: 'same_song',
      );
      final alpha = result('alpha', 'Lanterns glow');
      final beta = result('beta', 'Lanterns glow');
      final gamma = result(
        'gamma',
        'Lanterns glow across the quiet harbor at night',
        metadata: {'mood': 'reflective'},
      );

      final selection = h.app.selectCandidate(candidate);
      final request = await h.discovery.discoveryAt(0);
      request.publish(alpha);
      request.publish(beta);
      request.publish(gamma);

      expect(h.app.results.map((source) => source.id), [
        alpha.id,
        beta.id,
        gamma.id,
      ]);
      expect(h.app.combined?.body, alpha.body);
      await waitForCombined(h, () => h.app.combined?.body == gamma.body);
      expect(h.app.combined?.body, gamma.body);
      expect(h.app.combined?.extra['fieldOrigins']['mood'], gamma.id);

      request.response.complete([alpha, beta, gamma]);
      await selection;
      expect(h.app.combined?.body, gamma.body);
      expect(h.app.combined?.extra['fieldOrigins']['mood'], gamma.id);
    },
  );

  test(
    'same-source progress bursts coalesce after two immediate recomputes',
    () async {
      final h = await open(providers: [_PendingProvider('alpha')]);
      h.discovery.holdDiscoveries = true;
      final candidate = SongCandidate(
        providerId: 'catalog',
        id: 'lantern-song',
        title: 'Lantern Song',
        artist: 'Lanterns',
      );
      SourceResult result(String body, {JsonMap metadata = const {}}) =>
          SourceResult(
            candidate: SongCandidate(
              providerId: 'alpha',
              id: 'lantern-song',
              title: candidate.title,
              artist: candidate.artist,
            ),
            body: body,
            metadata: metadata,
            matchKind: MatchKind.sameSong,
            matchReason: 'same_song',
          );
      final first = result('Lanterns glow');
      final second = result('Lanterns glow', metadata: {'mood': 'reflective'});
      final third = result(
        'Lanterns glow',
        metadata: {
          'mood': 'reflective',
          'genres': ['folk'],
        },
      );
      final latest = result(
        'Lanterns glow',
        metadata: {
          'mood': 'reflective',
          'genres': ['folk'],
          'year': 1970,
        },
      );

      final selection = h.app.selectCandidate(candidate);
      final request = await h.discovery.discoveryAt(0);
      request.publish(first);
      expect(h.app.combined?.body, first.body);
      request.publish(second);
      expect(h.app.combined?.body, second.body);
      expect(h.app.combined?.extra['fieldOrigins']['mood'], second.id);
      request.publish(third);
      request.publish(latest);

      expect(h.app.results, hasLength(1));
      expect(h.app.results.single.body, latest.body);
      expect(h.app.results.single.metadata['year'], 1970);
      expect(
        h.app.combined?.sources.single.metadata.containsKey('year'),
        isFalse,
        reason: 'updates after the two immediate recomputes are coalesced',
      );
      await waitForCombined(
        h,
        () =>
            h.app.combined?.sources.single.metadata.containsKey('year') == true,
      );
      expect(h.app.combined?.body, latest.body);
      expect(h.app.combined?.extra['fieldOrigins']['mood'], latest.id);
      expect(h.app.combined?.sources.single.metadata['year'], 1970);

      request.response.complete([latest]);
      await selection;
      expect(h.app.combined?.body, latest.body);
      expect(h.app.combined?.extra['fieldOrigins']['mood'], latest.id);
    },
  );

  test('cancelled discovery cannot run its queued recombination', () async {
    final h = await open(
      providers: [
        _PendingProvider('alpha'),
        _PendingProvider('beta'),
        _PendingProvider('gamma'),
      ],
    );
    h.discovery.holdDiscoveries = true;
    final candidate = SongCandidate(
      providerId: 'catalog',
      id: 'lantern-song',
      title: 'Lantern Song',
      artist: 'Lanterns',
    );
    SourceResult result(String provider, String body) => SourceResult(
      candidate: SongCandidate(
        providerId: provider,
        id: 'lantern-song',
        title: candidate.title,
        artist: candidate.artist,
      ),
      body: body,
      matchKind: MatchKind.sameSong,
      matchReason: 'same_song',
    );
    final first = result('alpha', 'Lanterns glow');
    final second = result('beta', 'Lanterns glow');
    final queued = result(
      'gamma',
      'Lanterns glow across the quiet harbor at night',
    );

    final selection = h.app.selectCandidate(candidate);
    final request = await h.discovery.discoveryAt(0);
    request.publish(first);
    request.publish(second);
    request.publish(queued);
    expect(h.app.results, hasLength(3));

    h.app.cancelSearch();
    expect(h.app.selection, isNull);
    expect(h.app.results, isEmpty);
    expect(h.app.combined, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(h.app.combined, isNull);

    request.response.complete([first, second, queued]);
    await selection;
    expect(h.app.results, isEmpty);
    expect(h.app.combined, isNull);
  });

  test(
    'disabling a provider cancels queued recombination of its result',
    () async {
      final h = await open(
        providers: [
          _PendingProvider('alpha'),
          _PendingProvider('beta'),
          _PendingProvider('gamma'),
        ],
      );
      h.discovery.holdDiscoveries = true;
      final candidate = SongCandidate(
        providerId: 'catalog',
        id: 'lantern-song',
        title: 'Lantern Song',
        artist: 'Lanterns',
      );
      SourceResult result(String provider, String body) => SourceResult(
        candidate: SongCandidate(
          providerId: provider,
          id: 'lantern-song',
          title: candidate.title,
          artist: candidate.artist,
        ),
        body: body,
        matchKind: MatchKind.sameSong,
        matchReason: 'same_song',
      );
      final first = result('alpha', 'Lanterns glow');
      final second = result('beta', 'Lanterns glow');
      final disabled = result(
        'gamma',
        'Lanterns glow across the quiet harbor at night',
      );

      final selection = h.app.selectCandidate(candidate);
      final request = await h.discovery.discoveryAt(0);
      request.publish(first);
      request.publish(second);
      request.publish(disabled);
      expect(h.app.results, hasLength(3));

      await h.app.setProviderEnabled('gamma', false);
      expect(h.app.results.map((source) => source.id), [first.id, second.id]);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(h.app.results.map((source) => source.id), [first.id, second.id]);
      expect(h.app.combined?.body, first.body);

      request.response.complete([first, second, disabled]);
      await selection;
      expect(h.app.results.map((source) => source.id), [first.id, second.id]);
      expect(h.app.combined?.body, first.body);
    },
  );

  test(
    'a saved comparison queued after catalog persistence retains repository cache authority',
    () async {
      final h = await open();
      final saved = SongDocument.fromJson(
        jsonDecode(
              File(
                'test/fixtures/wikisource_legacy_saved_song.json',
              ).readAsStringSync(),
            )
            as JsonMap,
      );
      await h.repository.saveSong(saved);
      h.discovery.holdDiscoveries = true;
      final reference = saved.selectedRecording!;

      // Identical raw source data cannot grant the repository-only capability.
      final forged = h.app.selectCandidate(
        reference,
        cachedResults: saved.sources,
      );
      (await h.discovery.discoveryAt(0)).response.complete([]);
      await forged;
      expect(h.app.combined, isNull);
      await expectLater(
        h.app.saveResult(
          source: h.app.results.single,
          allowRejectedSource: true,
        ),
        throwsA(isA<FormatException>()),
      );
      h.app.cancelSearch();
      h.online('');
      await h.app.setSetting('syntheticBarrier', true);
      final gate = await _holdWrites(h.repository);
      addTearDown(gate.release);
      final change = h.app.setSearchCatalog('wikisource');
      // Dispatch the catalog INSERT into SQLite's queue before the saved read.
      await Future<void>.delayed(Duration.zero);
      final oldSearch = h.app.search('Interim catalog query');
      final old = await h.lrclib.requestAt(0);
      final comparison = h.app.compareSavedSong(
        saved.id,
        expectedReference: reference,
        searchQuery: 'Saved historical comparison',
      );
      // compareSavedSong cancels the HTTP token and marks searching false,
      // while its repository read is still queued behind the catalog write.
      expect(old.cancel?.isCancelled, isTrue);
      expect(h.app.searching, isFalse);
      expect(h.app.selection, isNull);

      await gate.release();
      expect(await change, isTrue);
      final discovery = await Future.any<_DiscoveryRequest?>([
        h.discovery.discoveryAt(1),
        comparison.then<_DiscoveryRequest?>((_) => null),
      ]);
      expect(
        discovery,
        isNotNull,
        reason: 'the committed preference must not invalidate the queued read',
      );
      final active = discovery!;
      expect(active.selection.toJson(), reference.toJson());
      expect(active.cancel?.isCancelled, isFalse);
      expect(h.app.selection?.toJson(), reference.toJson());
      expect(h.app.results.single.toJson(), saved.sources.single.toJson());
      expect(h.app.combined?.body, saved.body);
      expect(h.app.discovering, isTrue);
      await h.app.setProviderEnabled('lrclib', false);
      expect(h.app.providerEnabled('lrclib'), isFalse);
      expect(active.cancel?.isCancelled, isFalse);
      expect(h.app.discovering, isTrue);
      expect(h.app.selection?.toJson(), reference.toJson());
      expect(h.app.results.single.toJson(), saved.sources.single.toJson());
      expect(h.app.combined?.body, saved.body);
      old.complete('obsolete-interim-catalog');
      await oldSearch;
      active.response.complete([]);
      await comparison;
      expect(h.app.selection?.toJson(), reference.toJson());
      expect(h.app.combined?.body, saved.body);
      expect(h.app.query, 'Saved historical comparison');
      expect(h.app.discovering, isFalse);
      expect((await h.repository.getSong(saved.id))!.toJson(), saved.toJson());
      final resaved = await h.app.saveResult(
        source: h.app.results.single,
        allowRejectedSource: true,
      );
      expect(resaved.body, saved.body);
      expect(resaved.sources.single.matchReason, 'identity_mismatch');
      await _expectCatalogAgreement(h, 'wikisource');
    },
  );

  test(
    'a catalog commit cancels an interim active lookup without changing navigation',
    () async {
      final h = await open();
      h.online('');
      await h.app.setSetting('syntheticBarrier', true);
      final gate = await _holdWrites(h.repository);
      addTearDown(gate.release);
      h.ui.setQuery('Original query');
      final change = h.ui.setSearchCatalog('wikisource');
      h.ui.setQuery('Interim lantern query');
      final search = h.ui.submitSearch();
      final old = await h.lrclib.requestAt(0);
      expect(h.app.searching, isTrue);
      h.ui.setTab(VerseTab.settings);

      await gate.release();
      await change;
      expect(old.cancel?.isCancelled, isTrue);
      expect(h.app.searching, isFalse);
      old.complete('late-interim-result');
      await search;
      await _expectCatalogAgreement(h, 'wikisource');
      expect(h.app.suggestions, isEmpty);
      expect(h.ui.state.autocomplete, isEmpty);
      expect(h.app.selection, isNull);
      expect(h.ui.state.query, 'Interim lantern query');
      expect(h.app.query, 'Interim lantern query');
      expect(h.ui.state.activeTab, VerseTab.settings);
      expect(h.ui.state.route, VerseRoute.main);
      expect(h.wiki.requests, isEmpty);
      expect(h.lrclib.requests, hasLength(1));
    },
  );

  test(
    'a failed preference write allows the same choice to be retried',
    () async {
      final h = await open();
      await h.app.setSearchCatalog('lrclib');
      h.online('');
      await h.app.setSetting('syntheticBarrier', true);
      await h.repository.database.execute('''
      CREATE TEMP TRIGGER reject_synthetic_catalog
      BEFORE INSERT ON settings
      WHEN NEW.key = 'app' AND NEW.value LIKE '%"catalog":"wikisource"%'
      BEGIN
        SELECT RAISE(ABORT, 'synthetic catalog write failure');
      END
    ''');
      final notices = <UiNotice>[];
      final subscription = h.ui.notices.listen(notices.add);
      addTearDown(subscription.cancel);
      h.app.errorCode = 'network';
      await h.ui.setSearchCatalog('wikisource');
      // A stream turn ensures the guarded failure notice has been delivered.
      await Future<void>.delayed(Duration.zero);
      expect(notices, contains(UiNotice.genericError));
      await _expectCatalogAgreement(h, 'lrclib');
      expect(
        h.app.errorCode,
        'network',
        reason: 'failure preserves the old error',
      );
      expect(h.app.searching, isFalse);
      h.ui.setFavoritesOnly(true);
      expect(
        jsonMap(await h.repository.getSetting('app'))['lastSongsFavoritesOnly'],
        isTrue,
        reason: 'a failed catalog write releases normal immediate dispatch',
      );
      await h.repository.database.execute(
        'DROP TRIGGER reject_synthetic_catalog',
      );
      await h.ui.setSearchCatalog('wikisource');
      await _expectCatalogAgreement(h, 'wikisource');
      expect(
        h.app.errorCode,
        isNull,
        reason: 'successful retry clears the error',
      );
      h.online('Lantern path');
      final search = h.ui.submitSearch();
      (await h.wiki.requestAt(0)).complete('recovered');
      await search;
      expect(h.ui.state.searchState, LoadState.loaded);
      expect(h.app.searching, isFalse);
    },
  );

  for (final scenario in [
    (
      name: 'both queued writes fail and restore the last durable catalog',
      failures: {'wikisource', 'lrclib'},
      firstFails: true,
      secondFails: true,
      expected: 'archive',
    ),
    (
      name: 'a successful first write survives a failed latest choice',
      failures: {'lrclib'},
      firstFails: false,
      secondFails: true,
      expected: 'wikisource',
    ),
    (
      name:
          'an obsolete failed write cannot roll back a successful latest choice',
      failures: {'wikisource'},
      firstFails: true,
      secondFails: false,
      expected: 'lrclib',
    ),
  ]) {
    test(scenario.name, () async {
      final h = await open(
        providers: [
          _PendingProvider('archive'),
          _PendingProvider('wikisource'),
          _PendingProvider('lrclib'),
        ],
        settings: const {'catalog': 'archive'},
      );
      h.online('');
      await h.app.setSetting('syntheticBarrier', true);
      await _observeCatalogWrites(h.repository, failures: scenario.failures);
      final gate = await _holdWrites(h.repository);
      addTearDown(gate.release);
      // Attach error handlers before either queued write can be dispatched.
      final first = _captureWriteError(h.app.setSearchCatalog('wikisource'));
      final second = _captureWriteError(h.app.setSearchCatalog('lrclib'));
      expect(h.app.settings['catalog'], 'archive');
      expect(h.app.searchCatalogId, 'archive');
      expect(h.ui.state.searchCatalogId, 'archive');
      await gate.release();
      final errors = await Future.wait([first, second]);
      expect(
        errors[0],
        scenario.firstFails ? isA<DatabaseException>() : isNull,
      );
      expect(
        errors[1],
        scenario.secondFails ? isA<DatabaseException>() : isNull,
      );
      final attempts = await _catalogWriteAttempts(h.repository);
      expect(
        attempts.map((document) => document['catalog']),
        ['wikisource', 'lrclib'],
        reason:
            'each operation writes its own choice, even when already obsolete',
      );
      await _expectCatalogAgreement(h, scenario.expected);
      expect(h.app.searching, isFalse);
      expect(h.ui.state.autocomplete, isEmpty);
      expect(h.allRequests, isEmpty);
      // A failed choice does not silently search another catalog. The ordinary
      // submit action recovers using the choice that really committed.
      h.online('Lantern path');
      final retry = h.ui.submitSearch();
      (await h._provider(scenario.expected).requestAt(0)).complete(
        'retry-current',
      );
      await retry;
      expect(
        h.ui.state.autocomplete.single.id,
        '${scenario.expected}:retry-current',
      );
      await _expectCatalogAgreement(h, scenario.expected);
    });
  }

  test(
    'catalog rollback preserves a setting changed during pending persistence',
    () async {
      final h = await open(
        settings: const {'catalog': 'lrclib', 'palette': 'mint'},
      );
      h.online('');
      await h.app.setSetting('syntheticBarrier', true);
      await _observeCatalogWrites(h.repository, failures: {'wikisource'});
      final gate = await _holdWrites(h.repository);
      addTearDown(gate.release);
      final failedChoice = _captureWriteError(
        h.app.setSearchCatalog('wikisource'),
      );
      final unrelated = h.app.setSetting('palette', 'plum');
      expect(h.app.settings['palette'], 'plum');
      await gate.release();
      expect(await failedChoice, isA<DatabaseException>());
      await unrelated;
      await _expectCatalogAgreement(h, 'lrclib');
      expect(h.app.settings['palette'], 'plum');
      expect(h.ui.state.palette, 'plum');
      final persisted = jsonMap(await h.repository.getSetting('app'));
      expect(persisted['palette'], 'plum');
      final attempts = await _catalogWriteAttempts(h.repository);
      expect(attempts.map((document) => document['catalog']), [
        'wikisource',
        'lrclib',
      ]);
      expect(attempts.map((document) => document['palette']), ['plum', 'plum']);
      expect(h.app.searching, isFalse);
    },
  );

  test(
    'dispose during a failed catalog write rejects late old search publication',
    () async {
      final h = await open(settings: const {'catalog': 'lrclib'});
      h.online('Lantern path');
      final oldSearch = h.ui.submitSearch();
      final old = await h.lrclib.requestAt(0);
      await h.app.setSetting('syntheticBarrier', true);
      await _observeCatalogWrites(h.repository, failures: {'wikisource'});
      final gate = await _holdWrites(h.repository);
      addTearDown(gate.release);
      final failure = _captureWriteError(h.app.setSearchCatalog('wikisource'));
      expect(old.cancel?.isCancelled, isTrue);
      var appPublications = 0;
      var uiPublications = 0;
      h.app.addListener(() => appPublications++);
      h.ui.addListener(() => uiPublications++);
      h.disposeControllers();
      await gate.release();
      expect(await failure, isA<DatabaseException>());
      old.complete('obsolete-after-dispose-and-failure');
      await oldSearch;
      expect(appPublications, 0);
      expect(uiPublications, 0);
      expect(h.app.suggestions, isEmpty);
      expect(h.app.selection, isNull);
      expect(h.app.searching, isFalse);
      expect(h.wiki.requests, isEmpty);
      expect(
        jsonMap(await h.repository.getSetting('app'))['catalog'],
        'lrclib',
      );
      expect(
        (await _catalogWriteAttempts(h.repository)).single['catalog'],
        'wikisource',
      );
    },
  );

  test(
    'a cached catalog snapshot retires an old lookup and rejects its callback',
    () async {
      final h = await open(settings: const {'catalog': 'lrclib'});
      h.online('Lantern path');
      final oldSearch = h.ui.submitSearch();
      final old = await h.lrclib.requestAt(0);
      final transport = ProviderTransport(
        client: MockClient(
          (_) async => throw StateError('Unexpected HTTP call'),
        ),
      );
      addTearDown(transport.close);
      final runtime = SourceCatalogRuntime(
        builtins: h.discovery.active,
        createProvider: (_) =>
            throw StateError('Synthetic snapshots use builtins'),
      );
      final client = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => _catalogSnapshot(1, [
          _catalogEntry('lrclib'),
          _catalogEntry('wikisource'),
        ]),
        readCache: () async => _catalogSnapshot(2, [
          _catalogEntry('lrclib', status: 'retired'),
          _catalogEntry('wikisource'),
        ]),
        writeCache: (_) async {},
      );
      // Restore only local bundled/cache snapshots. No remote refresh is needed.
      h.discovery.catalogClient = client;
      await client.initialize();
      await h.app.setSetting('syntheticCatalogRevision', 2);
      expect(runtime.catalog?.revision, 2);
      expect(h.app.searchCatalogs.map((provider) => provider.id), [
        'wikisource',
      ]);
      expect(h.ui.state.searchCatalogId, 'wikisource');
      expect(await h.app.setSearchCatalog('lrclib'), isFalse);
      old.complete('retired-catalog-result');
      await oldSearch;
      expect(h.app.suggestions, isEmpty);
      expect(h.ui.state.autocomplete, isEmpty);
      expect(h.ui.state.comparison, isNull);
      expect(h.app.settings['catalog'], 'lrclib');
      expect(h.app.searching, isFalse);
    },
  );

  test(
    'same-ID catalog revision changes reject old-generation results',
    () async {
      final h = await open();
      final transport = ProviderTransport(
        client: MockClient(
          (_) async => throw StateError('Unexpected HTTP call'),
        ),
      );
      addTearDown(transport.close);
      final runtime = SourceCatalogRuntime(
        builtins: h.discovery.active,
        createProvider: (_) =>
            throw StateError('Synthetic snapshots use builtins'),
      );
      final sources = [_catalogEntry('lrclib'), _catalogEntry('wikisource')];
      runtime.apply(SourceCatalog.parse(_catalogSnapshot(1, sources)));
      h.discovery.catalogClient = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () async => _catalogSnapshot(1, sources),
        readCache: () async => null,
        writeCache: (_) async {},
      );
      h.online('Lantern path');
      final oldSearch = h.ui.submitSearch();
      final old = await h.lrclib.requestAt(0);
      runtime.apply(SourceCatalog.parse(_catalogSnapshot(2, sources)));
      await h.app.setSetting('syntheticCatalogRevision', 2);
      expect(h.app.searchCatalogId, 'lrclib');
      old.complete('old-generation');
      await oldSearch;
      expect(h.app.suggestions, isEmpty);
      expect(h.ui.state.autocomplete, isEmpty);
      expect(h.app.searching, isFalse);
    },
  );
}

Future<void> _expectCatalogAgreement(_Harness harness, String id) async {
  expect(harness.app.settings['catalog'], id, reason: 'runtime preference');
  expect(harness.app.searchCatalogId, id, reason: 'effective catalog');
  expect(harness.ui.state.searchCatalogId, id, reason: 'displayed catalog');
  expect(
    jsonMap(await harness.repository.getSetting('app'))['catalog'],
    id,
    reason: 'durable preference',
  );
}

Future<Object?> _captureWriteError<T>(Future<T> write) async {
  try {
    await write;
    return null;
  } catch (error) {
    return error;
  }
}

Future<void> _observeCatalogWrites(
  LibraryRepository repository, {
  required Set<String> failures,
  int? failedAttempt,
}) async {
  await repository.database.execute('''
    CREATE TEMP TABLE synthetic_catalog_writes (
      sequence INTEGER PRIMARY KEY AUTOINCREMENT,
      document TEXT NOT NULL
    )
  ''');
  final rejection = [
    ...failures.map((id) => 'NEW.value LIKE \'%"catalog":"$id"%\''),
    if (failedAttempt != null)
      '(SELECT MAX(sequence) FROM synthetic_catalog_writes) = $failedAttempt',
  ].join(' OR ');
  // RAISE(FAIL) retains preceding trigger statements. Unlike ABORT, it lets
  // the test audit the document of a rejected write in this real database.
  await repository.database.execute('''
    CREATE TEMP TRIGGER observe_synthetic_catalog
    BEFORE INSERT ON settings
    WHEN NEW.key = 'app'
    BEGIN
      INSERT INTO synthetic_catalog_writes (document) VALUES (NEW.value);
      SELECT CASE WHEN ${rejection.isEmpty ? '0' : rejection}
        THEN RAISE(FAIL, 'synthetic catalog write failure') END;
    END
  ''');
}

Future<List<JsonMap>> _catalogWriteAttempts(
  LibraryRepository repository,
) async {
  final rows = await repository.database.query(
    'synthetic_catalog_writes',
    orderBy: 'sequence',
  );
  return rows
      .map((row) => jsonMap(jsonDecode(row['document'] as String)))
      .toList();
}

Map<String, Object?> _catalogEntry(String id, {String status = 'active'}) => {
  'id': id,
  'name': 'Synthetic $id',
  'adapter': 'builtin',
  'status': status,
  'revision': status == 'active' ? 1 : 2,
  'capabilities': ['catalog', 'lyrics', 'metadata'],
  'enabledByDefault': true,
  'accessMode': 'public',
  'website': 'https://example.org/',
  'hosts': <String>[],
};

String _catalogSnapshot(int revision, List<Map<String, Object?>> sources) =>
    jsonEncode({
      'schemaVersion': 1,
      'extractionSchemaVersion': 1,
      'revision': revision,
      'publishedAt': '2026-10-15T12:00:00.000Z',
      'sources': sources,
    });

Future<Map<String, Object?>> _savedRows(LibraryRepository repository) async => {
  for (final table in [
    'songs',
    'setlists',
    'setlist_entries',
    'activity',
    'outbox',
  ])
    table: await repository.database.query(table, orderBy: 'id'),
};

class _Harness {
  _Harness(this.repository, this.discovery, this.app, this.ui);

  final LibraryRepository repository;
  final _RegistryDiscovery discovery;
  AppController app;
  AppControllerAdapter ui;
  bool _controllersDisposed = false;

  static Future<_Harness> open({
    List<LyricsProvider>? providers,
    required JsonMap settings,
  }) async {
    final repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    await repository.setSetting('app', settings);
    final discovery = _RegistryDiscovery(
      providers ??
          [
            _PendingProvider('wikisource'),
            _PendingProvider('lrclib'),
            _PendingProvider('unconfigured', configured: false),
            _PendingProvider('disabled', enabled: false),
            _PendingProvider('metadata-only', capabilities: const {'metadata'}),
          ],
    );
    final app = AppController(repository: repository, discovery: discovery);
    await app.initialize();
    return _Harness(repository, discovery, app, AppControllerAdapter(app));
  }

  _PendingProvider get lrclib => _provider('lrclib');
  _PendingProvider get wiki => _provider('wikisource');
  _PendingProvider _provider(String id) => discovery.active
      .whereType<_PendingProvider>()
      .singleWhere((provider) => provider.definition.id == id);
  List<_Request> get allRequests => discovery.active
      .whereType<_PendingProvider>()
      .expand((provider) => provider.requests)
      .toList();

  void online(String query) {
    ui.setHomeListMode(HomeListMode.online);
    ui.setQuery(query);
  }

  void disposeControllers() {
    if (_controllersDisposed) return;
    _controllersDisposed = true;
    ui.dispose();
    app.dispose();
  }

  Future<void> close() async {
    disposeControllers();
    for (final request in allRequests) {
      if (!request.response.isCompleted) request.response.complete([]);
    }
    for (final request in discovery.discoveries) {
      if (!request.response.isCompleted) request.response.complete([]);
    }
    await repository.close();
  }
}

class _RegistryDiscovery extends SourceDiscoveryService {
  _RegistryDiscovery(this.active) : super([]);
  List<LyricsProvider> active;
  bool holdDiscoveries = false;
  final discoveries = <_DiscoveryRequest>[];
  final _discoveryWaiters = <int, Completer<_DiscoveryRequest>>{};

  Future<_DiscoveryRequest> discoveryAt(int index) => index < discoveries.length
      ? Future.value(discoveries[index])
      : (_discoveryWaiters[index] ??= Completer<_DiscoveryRequest>()).future;

  @override
  List<LyricsProvider> get providers =>
      catalogClient?.runtime.providers ?? active;

  @override
  Future<List<SourceResult>> discover(
    SongCandidate selection, {
    Set<String>? enabledIds,
    void Function(ProviderCheck)? onProgress,
    CancellationToken? cancel,
    Map<String, CancellationToken> providerCancellation = const {},
    Duration alternativeTimeout = const Duration(seconds: 30),
  }) {
    if (!holdDiscoveries) {
      return super.discover(
        selection,
        enabledIds: enabledIds,
        onProgress: onProgress,
        cancel: cancel,
        providerCancellation: providerCancellation,
        alternativeTimeout: alternativeTimeout,
      );
    }
    final request = _DiscoveryRequest(selection, cancel, onProgress);
    discoveries.add(request);
    _discoveryWaiters.remove(discoveries.length - 1)?.complete(request);
    return request.response.future;
  }
}

class _DiscoveryRequest {
  _DiscoveryRequest(this.selection, this.cancel, this.onProgress);
  final SongCandidate selection;
  final CancellationToken? cancel;
  final void Function(ProviderCheck)? onProgress;
  final response = Completer<List<SourceResult>>();

  void publish(SourceResult source) => onProgress?.call(
    ProviderCheck(
      providerId: source.candidate.providerId,
      state: 'found',
      result: source,
    ),
  );
}

class _PendingProvider implements LyricsProvider {
  _PendingProvider(
    String id, {
    bool enabled = true,
    bool configured = true,
    Set<String> capabilities = const {'catalog', 'lyrics', 'metadata'},
  }) : definition = ProviderDefinition(
         id: id,
         name: 'Synthetic $id',
         capabilities: capabilities,
         enabledByDefault: enabled,
         configured: configured,
       );

  @override
  final ProviderDefinition definition;
  final requests = <_Request>[];
  final _requestWaiters = <int, Completer<_Request>>{};

  Future<_Request> requestAt(int index) => index < requests.length
      ? Future.value(requests[index])
      : (_requestWaiters[index] ??= Completer<_Request>()).future;

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) {
    final request = _Request(definition.id, query, cancel);
    requests.add(request);
    _requestWaiters.remove(requests.length - 1)?.complete(request);
    // Intentionally ignore cancellation: real providers may finish an already
    // dispatched request, so the controller must also reject stale callbacks.
    return request.response.future;
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw const ProviderException('unavailable');
}

class _Request {
  _Request(this.providerId, this.query, this.cancel);
  final String providerId, query;
  final CancellationToken? cancel;
  final response = Completer<List<SongCandidate>>();

  void complete(String id) => response.complete([
    SongCandidate(
      providerId: providerId,
      id: id,
      title: 'Lantern path',
      artist: 'Synthetic ensemble',
    ),
  ]);
}

class _WriteGate {
  _WriteGate(this.released, this.transaction);
  final Completer<void> released;
  final Future<void> transaction;

  Future<void> release() async {
    if (!released.isCompleted) released.complete();
    await transaction;
  }
}

Future<_WriteGate> _holdWrites(LibraryRepository repository) async {
  final entered = Completer<void>();
  final released = Completer<void>();
  final transaction = repository.database.transaction<void>((_) async {
    entered.complete();
    await released.future;
  });
  await entered.future;
  return _WriteGate(released, transaction);
}
