import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/combine.dart' show recordingCompatible;
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _query = 'Amber Lantern';
const _short =
    'Paper lanterns float across the sleeping garden\n'
    'Silver rivers carry every quiet song';
const _full = '$_short\nMorning opens all the windows to the sky';
const _selected = SongCandidate(
  providerId: 'genius',
  id: 'song',
  title: _query,
  artist: 'Synthetic Ensemble',
  metadata: {'identityScope': 'recording'},
  recordingIds: {'syntheticRecording': 'take-one'},
);

void main() {
  sqfliteFfiInit();

  Future<_Harness> open({
    List<ProviderDefinition>? definitions,
    JsonMap settings = const {},
  }) async {
    final harness = await _Harness.open(
      definitions: definitions ?? _definitions(),
      settings: settings,
    );
    addTearDown(harness.close);
    return harness;
  }

  for (final scenario in [
    (
      name: 'configured Genius is the default',
      configured: true,
      present: true,
      settings: <String, dynamic>{},
      expected: 'genius',
    ),
    (
      name: 'unconfigured Genius falls back to LRCLIB',
      configured: false,
      present: true,
      settings: <String, dynamic>{},
      expected: 'lrclib',
    ),
    (
      name: 'disabled Genius falls back to LRCLIB',
      configured: true,
      present: true,
      settings: <String, dynamic>{
        'providers': {'genius': false},
      },
      expected: 'lrclib',
    ),
    (
      name: 'unregistered Genius falls back to LRCLIB',
      configured: true,
      present: false,
      settings: <String, dynamic>{},
      expected: 'lrclib',
    ),
    (
      name: 'explicit LRCLIB preference wins over configured Genius',
      configured: true,
      present: true,
      settings: <String, dynamic>{'catalog': 'lrclib'},
      expected: 'lrclib',
    ),
    (
      name: 'a missing remembered primary falls back to registered Genius',
      configured: true,
      present: true,
      settings: <String, dynamic>{'catalog': 'not-registered'},
      expected: 'genius',
    ),
  ]) {
    test(scenario.name, () async {
      final h = await open(
        definitions: _definitions(
          geniusConfigured: scenario.configured,
          includeGenius: scenario.present,
        ),
        settings: scenario.settings,
      );
      expect(h.app.searchCatalogId, scenario.expected);
      expect(h.ui.state.searchCatalogId, scenario.expected);
      final search = h.app.search(_query);
      final eligible = h.app.searchCatalogs
          .where((definition) => definition.accessMode != 'publicDomainText')
          .map((definition) => definition.id)
          .toSet();
      for (final id in eligible) {
        (await h.discovery.searchAt(id, _query)).complete([_candidate(id)]);
      }
      await search;
      expect(
        h.discovery.searches.map((request) => request.providerId).toSet(),
        eligible,
      );
      expect(h.app.suggestions.first.providerId, scenario.expected);
      expect(h.app.catalogChecks.keys.toSet(), eligible);
      expect(
        h.app.catalogChecks.values.map((check) => check.state),
        everyElement('completed'),
      );
      expect(
        h.discovery.searches.any(
          (request) => {
            'wikisource',
            'metadata-only',
            'not-registered',
          }.contains(request.providerId),
        ),
        isFalse,
      );
      expect(h.app.searching, isFalse);
      expect(await h.repository.listSongs(), isEmpty);
    });
  }

  test(
    'fast primary rows are visible while a secondary catalog remains pending',
    () async {
      final h = await open();
      h.ui.setHomeListMode(HomeListMode.online);
      h.ui.setQuery(_query);
      final search = h.ui.submitSearch();
      final primary = await h.discovery.searchAt('genius', _query);
      final secondary = await h.discovery.searchAt('lrclib', _query);
      primary.complete([_selected]);
      await _settle();
      expect(h.app.searching, isTrue);
      expect(h.app.catalogChecks['genius']?.state, 'completed');
      expect(h.app.catalogChecks['lrclib']?.state, 'pending');
      expect(h.ui.state.searchState, LoadState.loaded);
      expect(h.ui.state.autocomplete.single.id, _selected.identity);
      expect(secondary.response.isCompleted, isFalse);
      secondary.complete([]);
      await search;
      expect(h.app.searching, isFalse);
      expect(h.ui.state.autocomplete.single.id, _selected.identity);
    },
  );

  test(
    'disabling a pending secondary cancels only that catalog and ignores its late rows',
    () async {
      final h = await open();
      h.ui.setHomeListMode(HomeListMode.online);
      h.ui.setQuery(_query);
      final search = h.ui.submitSearch();
      final primary = await h.discovery.searchAt('genius', _query);
      final secondary = await h.discovery.searchAt('lrclib', _query);
      await h.app.setProviderEnabled('lrclib', false);
      expect(secondary.cancel?.isCancelled, isTrue);
      expect(primary.cancel?.isCancelled, isFalse);
      expect(
        h.app.searching,
        isTrue,
        reason: 'the primary lookup is still in flight',
      );
      expect(h.app.searchCatalogId, 'genius');
      primary.complete([_selected]);
      await search;
      expect(h.app.suggestions.single.identity, _selected.identity);
      expect(h.ui.state.autocomplete.single.id, _selected.identity);
      expect(h.ui.state.searchState, LoadState.loaded);
      expect(h.app.catalogChecks['genius']?.state, 'completed');
      expect(h.app.catalogChecks['lrclib']?.state, 'cancelled');
      secondary.complete([_candidate('lrclib', id: 'disabled-late-result')]);
      await _settle();
      expect(h.app.suggestions.single.identity, _selected.identity);
      expect(h.ui.state.autocomplete.single.id, _selected.identity);
      expect(h.app.catalogChecks['lrclib']?.state, 'cancelled');
      expect(h.app.errorCode, isNull);
      expect(h.app.searching, isFalse);
      expect(primary.cancel?.isCancelled, isFalse);
      expect(await h.repository.listSongs(), isEmpty);
    },
  );

  test(
    'a secondary result selected before a late primary keeps its comparison',
    () async {
      final h = await open();
      h.ui.setHomeListMode(HomeListMode.online);
      h.ui.setQuery(_query);
      final search = h.ui.submitSearch();
      final primary = await h.discovery.searchAt('genius', _query);
      final secondary = await h.discovery.searchAt('lrclib', _query);
      final secondaryCandidate = _candidate('lrclib');
      secondary.complete([secondaryCandidate]);
      await _settle();
      final choice = h.ui.selectReference(h.ui.state.autocomplete.single);
      final discovery = await h.discovery.discoveryAt(0);
      final lyrics = _source('lrclib');
      discovery.publish(lyrics);
      expect(primary.cancel?.isCancelled, isTrue);
      primary.complete([_selected]);
      await search;
      expect(h.app.selection?.identity, secondaryCandidate.identity);
      expect(h.app.suggestions, isEmpty);
      expect(h.ui.state.comparison?.reference.id, secondaryCandidate.identity);
      await h.app.flushCombine();
      expect(h.app.combined?.body, _short);
      discovery.response.complete([]);
      await choice;
      expect(h.ui.state.comparison?.reference.id, secondaryCandidate.identity);
      expect(h.app.results.single.id, lyrics.id);
      expect(await h.repository.listSongs(), isEmpty);
    },
  );

  test(
    'results arriving within one interval are merged as a single batch',
    () async {
      final h = await open();
      h.app.discoveryCombineInterval = const Duration(milliseconds: 80);
      final flow = await h.beginSelection();
      final before = h.app.combineRunner.startedRuns;
      flow.request.publish(_source('genius'));
      flow.request.publish(_source('genius', metadata: {'album': 'A'}));
      flow.request.publish(_source('lrclib', body: _full));
      flow.request.publish(_source('genius', metadata: {'album': 'B'}));
      await Future<void>.delayed(Duration.zero);
      expect(h.app.combineRunner.startedRuns, before);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(h.app.combineRunner.startedRuns, before + 1);
      expect(h.app.combined?.body, _full);
      flow.request.response.complete([]);
      await flow.completion;
      expect(h.app.combineRunner.startedRuns, before + 2);
      expect(h.app.combined?.body, _full);
    },
  );

  test(
    'disabling an in-flight discovery provider preserves other work and excludes its late results',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      final secondaryToken = flow.request.providerCancellation['lrclib']!;
      final primaryToken = flow.request.providerCancellation['genius']!;
      flow.request.publish(
        _source('genius', metadata: {'album': 'Primary Album'}),
      );
      flow.request.publish(
        _source(
          'lrclib',
          body: '',
          metadata: {'label': 'Live secondary label'},
        ),
      );
      await h.app.flushCombine();
      expect(h.app.combined?.metadata['label'], 'Live secondary label');
      await h.app.setProviderEnabled('lrclib', false);
      expect(secondaryToken.isCancelled, isTrue);
      expect(primaryToken.isCancelled, isFalse);
      expect(flow.request.cancel?.isCancelled, isFalse);
      expect(h.app.discovering, isTrue);
      expect(h.app.selection?.identity, _selected.identity);
      expect(h.app.results.map((source) => source.candidate.providerId), [
        'genius',
      ]);
      await h.app.flushCombine();
      expect(h.app.combined?.metadata['label'], isNull);
      expect(h.app.checks.containsKey('lrclib'), isFalse);

      final forbidden = _source(
        'lrclib',
        body: _full,
        metadata: {'album': 'Forbidden late album'},
      );
      flow.request.publish(forbidden);
      expect(h.app.results.map((source) => source.candidate.providerId), [
        'genius',
      ]);
      expect(h.app.checks.containsKey('lrclib'), isFalse);
      final improvedPrimary = _source(
        'genius',
        body: _full,
        metadata: {
          'composers': ['Active Primary Writer'],
        },
      );
      flow.request.publish(improvedPrimary);
      await h.app.flushCombine();
      expect(h.app.combined?.body, _full);
      expect(h.app.combined?.metadata['composers'], ['Active Primary Writer']);
      flow.request.response.complete([forbidden, improvedPrimary]);
      await flow.completion;
      expect(h.app.results.map((source) => source.candidate.providerId), [
        'genius',
      ]);
      expect(h.app.combined?.metadata['album'], 'Primary Album');
      expect(h.app.combined?.metadata['label'], isNull);
      expect(h.app.selection?.identity, _selected.identity);
      expect(h.ui.state.comparison, isNotNull);
      expect(h.app.discovering, isFalse);
      expect(h.app.providerEnabled('lrclib'), isFalse);
      expect(
        h.ui.state.providers
            .singleWhere((provider) => provider.id == 'lrclib')
            .enabled,
        isFalse,
      );
      expect(
        jsonMap(
          jsonMap(await h.repository.getSetting('app'))['providers'],
        )['lrclib'],
        isFalse,
        reason: 'late callbacks cannot silently re-enable a provider',
      );
      expect(await h.repository.listSongs(), isEmpty);
    },
  );

  test(
    'disabling discovery retains a repository-backed saved source and ignores live replacement',
    () async {
      final h = await open();
      final cached = _source(
        'lrclib',
        body: _full,
        metadata: {'album': 'Saved Album'},
      );
      await h.app.saveSong(
        SongDocument(
          id: 'cached-library-song',
          title: _query,
          artist: 'Synthetic Ensemble',
          body: _full,
          selectedRecording: _selected,
          sources: [cached],
          extra: {
            'selectedSourceId': cached.id,
            'fieldOrigins': {'lyrics': cached.id, 'album': cached.id},
          },
        ),
      );
      final before = await _libraryRows(h.repository);
      final comparison = h.app.compareSavedSong(
        'cached-library-song',
        expectedReference: _selected,
        searchQuery: _query,
      );
      final request = await h.discovery.discoveryAt(0);
      final secondaryToken = request.providerCancellation['lrclib']!;
      expect(h.app.results.single.toJson(), cached.toJson());
      await h.app.setProviderEnabled('lrclib', false);
      expect(secondaryToken.isCancelled, isTrue);
      expect(request.providerCancellation['genius']?.isCancelled, isFalse);
      expect(h.app.results.single.toJson(), cached.toJson());
      await h.app.flushCombine();
      expect(h.app.combined?.body, _full);
      expect(h.app.combined?.metadata['album'], 'Saved Album');
      final forbidden = _source(
        'lrclib',
        body: 'A live callback may not replace saved words',
        metadata: {'album': 'Forbidden live album'},
      );
      request.publish(forbidden);
      expect(h.app.results.single.toJson(), cached.toJson());
      final primary = _source('genius');
      request.publish(primary);
      request.response.complete([forbidden, primary]);
      await comparison;
      expect(
        h.app.results.singleWhere((source) => source.id == cached.id).toJson(),
        cached.toJson(),
      );
      expect(h.app.results.any((source) => source.id == primary.id), isTrue);
      expect(h.app.combined?.body, _full);
      expect(h.app.combined?.metadata['album'], 'Saved Album');
      expect(h.app.selection?.identity, _selected.identity);
      expect(h.app.providerEnabled('lrclib'), isFalse);
      expect(await _libraryRows(h.repository), before);
    },
  );

  test(
    'disable and re-enable cannot resurrect an old discovery child',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      final oldToken = flow.request.providerCancellation['lrclib']!;
      final primary = _source('genius');
      flow.request.publish(primary);
      await h.app.setProviderEnabled('lrclib', false);
      await h.app.setProviderEnabled('lrclib', true);
      expect(h.app.providerEnabled('lrclib'), isTrue);
      expect(oldToken.isCancelled, isTrue);
      expect(flow.request.providerCancellation['genius']?.isCancelled, isFalse);
      final obsolete = _source(
        'lrclib',
        body: _full,
        metadata: {'album': 'Obsolete child album'},
      );
      flow.request.publish(obsolete);
      expect(h.app.results.single.id, primary.id);
      expect(h.app.combined?.metadata['album'], isNull);
      flow.request.response.complete([obsolete, primary]);
      await flow.completion;
      expect(h.app.results.single.id, primary.id);
      expect(h.app.combined?.body, _short);
      expect(h.app.combined?.metadata['album'], isNull);
      expect(h.app.providerEnabled('lrclib'), isTrue);

      final restarted = h.app.selectCandidate(
        _selected,
        cachedResults: List<SourceResult>.of(h.app.results),
      );
      final current = await h.discovery.discoveryAt(1);
      final newToken = current.providerCancellation['lrclib']!;
      expect(newToken, isNot(same(oldToken)));
      expect(newToken.isCancelled, isFalse);
      final fresh = _source(
        'lrclib',
        body: _full,
        metadata: {'album': 'Fresh enabled source album'},
      );
      current.publish(fresh);
      current.response.complete([fresh]);
      await restarted;
      expect(h.app.results.any((source) => source.id == fresh.id), isTrue);
      expect(h.app.combined?.body, _full);
      expect(h.app.combined?.metadata['album'], 'Fresh enabled source album');
      expect(h.app.selection?.identity, _selected.identity);
      expect(await h.repository.listSongs(), isEmpty);
    },
  );

  test('a new query rejects late old rows and per-provider statuses', () async {
    final h = await open();
    h.ui.setHomeListMode(HomeListMode.online);
    h.ui.setQuery('First lantern');
    final oldSearch = h.ui.submitSearch();
    final oldPrimary = await h.discovery.searchAt('genius', 'First lantern');
    final oldSecondary = await h.discovery.searchAt('lrclib', 'First lantern');
    h.ui.setQuery('Second lantern');
    final currentSearch = h.ui.submitSearch();
    final currentPrimary = await h.discovery.searchAt(
      'genius',
      'Second lantern',
    );
    final currentSecondary = await h.discovery.searchAt(
      'lrclib',
      'Second lantern',
    );
    currentPrimary.complete([_candidate('genius', id: 'current')]);
    currentSecondary.response.completeError(const ProviderException('network'));
    await currentSearch;
    final states = {
      for (final entry in h.app.catalogChecks.entries)
        entry.key: (entry.value.state, entry.value.code),
    };
    expect(oldPrimary.cancel?.isCancelled, isTrue);
    expect(oldSecondary.cancel?.isCancelled, isTrue);
    oldPrimary.complete([_candidate('genius', id: 'obsolete')]);
    oldSecondary.response.completeError(const ProviderException('blocked'));
    await oldSearch;
    await _settle();
    expect(h.app.suggestions.single.id, 'current');
    expect(h.ui.state.query, 'Second lantern');
    expect(h.ui.state.searchState, LoadState.loaded);
    expect(h.app.errorCode, isNull);
    expect({
      for (final entry in h.app.catalogChecks.entries)
        entry.key: (entry.value.state, entry.value.code),
    }, states);
    expect(h.app.catalogChecks['lrclib']?.code, 'network');
  });

  test(
    'progressive facts and fuller lyrics survive late blank partial and failure updates',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      final initial = _source(
        'genius',
        metadata: {
          'album': 'Dawn Collection',
          'composers': ['Synthetic Composer'],
        },
      );
      flow.request.publish(initial);
      flow.request.publish(
        _source(
          'genius',
          body: '',
          metadata: {
            'artworkUrl': 'https://example.org/synthetic-cover.jpg',
            'label': 'Synthetic Label',
          },
        ),
      );
      flow.request.publish(
        _source(
          'genius',
          body: _full,
          metadata: {
            'composers': ['Synthetic Composer', 'Second Composer'],
          },
        ),
      );
      flow.request.publish(
        _source(
          'genius',
          body: _full,
          metadata: {
            'releaseDate': '2026-01-01',
            'producers': ['Synthetic Producer'],
          },
        ),
      );
      final accepted = h.app.results.single;
      expect(accepted.body, _full);
      expect(accepted.metadata['album'], 'Dawn Collection');
      expect(
        accepted.metadata['composers'],
        containsAll(['Synthetic Composer', 'Second Composer']),
      );
      final blank = _source(
        'genius',
        body: '',
        metadata: {'album': '', 'composers': <String>[]},
      );
      final partial = _source('genius', body: _short.split('\n').first);
      flow.request.publish(blank);
      flow.request.publish(partial);
      flow.request.failure('genius', 'network');
      // The final return must merge against progress, rather than the empty
      // pre-discovery cache or the last raw (partial) provider response.
      flow.request.response.complete([partial]);
      await flow.completion;
      final current = h.app.results.single;
      expect(current.body, _full);
      expect(current.metadata, accepted.metadata);
      expect(h.app.combined?.body, _full);
      expect(h.app.combined?.metadata['album'], 'Dawn Collection');
      expect(
        h.app.combined?.metadata['artworkUrl'],
        'https://example.org/synthetic-cover.jpg',
      );
      expect(h.app.checks['genius']?.code, 'network');
      expect(
        _history(current).map((version) => version.body),
        containsAll([_short, '', _short.split('\n').first]),
      );
      expect(await h.repository.listSongs(), isEmpty);
    },
  );

  test(
    'a transport failure after accepted progress preserves its usable payload',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      final accepted = _source(
        'genius',
        metadata: {'album': 'Dawn Collection'},
      );
      flow.request.publish(accepted);
      flow.request.response.completeError(const ProviderException('network'));
      await flow.completion;
      expect(h.app.errorCode, 'network');
      expect(h.app.discovering, isFalse);
      expect(h.app.results.single.toJson(), accepted.toJson());
      expect(h.app.combined?.body, _short);
      expect(h.ui.state.comparison?.discoveryError, 'network');
      expect(await h.repository.listSongs(), isEmpty);
    },
  );

  test(
    'final identity rejection withdraws active facts while retaining raw history',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      final accepted = _source(
        'genius',
        metadata: {'album': 'Withdrawn Album'},
      );
      final independent = _source('lrclib', body: _full);
      flow.request.publish(accepted);
      flow.request.publish(independent);
      final rejected = _source(
        'genius',
        title: 'Different historical title',
        kind: MatchKind.rejected,
        reason: 'identity_mismatch',
        metadata: {},
      );
      flow.request.response.complete([rejected, independent]);
      await flow.completion;
      final current = h.app.results.singleWhere(
        (source) => source.id == accepted.id,
      );
      expect(current.matchKind, MatchKind.rejected);
      expect(current.candidate.title, rejected.candidate.title);
      expect(recordingCompatible(_selected, current), isFalse);
      expect(
        _history(current).map((version) => version.toJson()),
        anyElement(equals(accepted.toJson())),
      );
      expect(h.app.combined?.body, _full);
      expect(h.app.combined?.metadata['album'], isNull);
      expect(h.app.combined?.extra['selectedSourceId'], independent.id);
      expect(await h.repository.listSongs(), isEmpty);
    },
  );

  test(
    'a sole final-rejected source cannot regain automatic combined authority',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      const priorTiming = TimingTrack(
        id: 'synthetic-timing',
        sourceDocumentId: 'genius:song',
        sourceLyrics: _full,
        format: 'lrc',
        status: TimingStatus.usable,
        cues: [
          TimingCue(
            id: 'cue',
            occurrenceId: 'line-0',
            startUs: 0,
            text: 'Paper lanterns float across the sleeping garden',
          ),
        ],
      );
      final accepted = _source(
        'genius',
        body: _full,
        metadata: {'album': 'Withdrawn Album', 'durationSeconds': 123},
        tracks: [priorTiming],
      );
      flow.request.publish(accepted);
      await h.app.flushCombine();
      expect(h.app.combined?.body, _full);
      final rejected = _source(
        'genius',
        body: _full,
        kind: MatchKind.rejected,
        reason: 'identity_mismatch',
      );
      flow.request.response.complete([rejected]);
      await flow.completion;
      expect(h.app.results.single.matchKind, MatchKind.rejected);
      expect(h.app.combined, isNull);
      expect(h.ui.state.comparison?.suggested, isNull);
      expect(recordingCompatible(_selected, h.app.results.single), isFalse);
      expect(
        _history(h.app.results.single).map((version) => version.toJson()),
        anyElement(equals(accepted.toJson())),
      );
      expect(
        _history(h.app.results.single).single.timingTracks.single.toJson(),
        priorTiming.toJson(),
      );
      expect(await h.repository.listSongs(), isEmpty);
      // An explicit source choice remains a separate action by the owner.
      final explicit = await h.app.saveResult(
        source: h.app.results.single,
        allowRejectedSource: true,
      );
      expect(explicit.body, _full);
      expect(h.app.combined, isNull);
      expect(explicit.sources.single.matchKind, MatchKind.rejected);
      expect(explicit.timingTracks, isEmpty);
    },
  );

  test(
    'real chart corroboration withdraws tentative A and retains accepted B under its own ID',
    () async {
      const reference = SongCandidate(
        providerId: 'lrclib',
        id: 'reference',
        title: _query,
        artist: 'Synthetic Ensemble',
      );
      const a = SongCandidate(
        providerId: 'chart',
        id: 'a',
        title: _query,
        artist: 'Synthetic Ensemble',
      );
      const b = SongCandidate(
        providerId: 'chart',
        id: 'b',
        title: _query,
        artist: 'Synthetic Ensemble',
      );
      final charts = _ScriptedProvider(
        'chart',
        capabilities: const {'lyrics', 'chords'},
        searches: const [
          [a],
          [b],
        ],
      );
      final lyrics = _ScriptedProvider(
        'lrclib',
        capabilities: const {'catalog', 'lyrics'},
      );
      final repository = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([charts, lyrics]),
      );
      addTearDown(() async {
        app.dispose();
        for (final provider in [charts, lyrics]) {
          for (final request in provider.resolved) {
            if (!request.response.isCompleted) {
              request.response.completeError(
                const ProviderException('cancelled'),
              );
            }
          }
        }
        await repository.close();
      });
      await app.initialize();
      final transitions = <({MatchKind kind, bool hasB, bool pending})>[];
      void observe() {
        final current = app.results
            .where((source) => source.id == a.identity)
            .firstOrNull;
        if (current != null) {
          transitions.add((
            kind: current.matchKind,
            hasB: app.results.any((source) => source.id == b.identity),
            pending: app.discovering,
          ));
        }
      }

      app.addListener(observe);
      final comparison = app.selectCandidate(reference);
      const badChart =
          '[F#]Copper mountains call the restless thunder\n'
          '[B]Seven crimson valleys hide a broken clock\n'
          '[C#]Distant engines wake beneath the autumn harbor';
      (await charts.resolveAt(0)).response.complete(
        const SourceResult(
          candidate: a,
          body: badChart,
          metadata: {'key': 'F#'},
          extra: {'rawMarker': 'original-chart-a'},
        ),
      );
      final referenceRequest = await lyrics.resolveAt(0);
      expect(
        app.results.singleWhere((source) => source.id == a.identity).matchKind,
        MatchKind.sameSong,
      );
      expect(app.discovering, isTrue);
      referenceRequest.response.complete(
        const SourceResult(candidate: reference, body: _full),
      );
      final replacementRequest = await charts.resolveAt(1);
      expect(
        charts.searchCalls,
        2,
        reason: 'B is resolved by final corroboration',
      );
      expect(replacementRequest.candidate.id, b.id);
      final goodChart = '[C]${_full.replaceAll('\n', '\n[G]')}';
      replacementRequest.response.complete(
        SourceResult(
          candidate: b,
          body: goodChart,
          metadata: const {'key': 'C'},
          extra: const {'rawMarker': 'validated-chart-b'},
        ),
      );
      await comparison;
      app.removeListener(observe);
      expect(
        transitions,
        contains((kind: MatchKind.sameSong, hasB: false, pending: true)),
      );
      expect(
        transitions,
        contains((kind: MatchKind.rejected, hasB: false, pending: true)),
        reason: 'progress consumers see A withdrawn before B is published',
      );
      expect(
        transitions,
        contains((kind: MatchKind.rejected, hasB: true, pending: true)),
      );
      expect(app.results.map((source) => source.id).toSet(), {
        a.identity,
        b.identity,
        reference.identity,
      });
      final withdrawn = app.results.singleWhere(
        (source) => source.id == a.identity,
      );
      final accepted = app.results.singleWhere(
        (source) => source.id == b.identity,
      );
      expect(withdrawn.matchKind, MatchKind.rejected);
      expect(withdrawn.matchReason, 'incomplete_or_different_lyrics');
      expect(withdrawn.body, badChart);
      expect(withdrawn.extra['rawMarker'], 'original-chart-a');
      expect(
        _history(withdrawn).map((source) => source.body),
        contains(badChart),
      );
      expect(accepted.matchKind, isNot(MatchKind.rejected));
      expect(accepted.body, goodChart);
      expect(app.combined?.body, contains('Paper lanterns'));
      expect(app.combined?.body, isNot(contains('Copper mountains')));
      expect(app.combined?.extra['fieldOrigins']['chords'], b.identity);
      expect(app.combined?.metadata['key'], 'C');
      expect(
        jsonMap(app.combined?.extra['fieldOrigins']).values,
        isNot(contains(a.identity)),
      );
      expect(await repository.listSongs(), isEmpty);
      final saved = await app.saveResult();
      expect(saved.body, isNot(contains('Copper mountains')));
      expect(saved.extra['fieldOrigins']['chords'], b.identity);
      expect(
        saved.sources
            .singleWhere((source) => source.id == a.identity)
            .matchKind,
        MatchKind.rejected,
      );
    },
  );

  test(
    'closed or replaced discovery callbacks cannot revive withdrawn A after completion',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      final a = _source('genius', metadata: {'album': 'Withdrawn Album'});
      final rejected = _source(
        'genius',
        kind: MatchKind.rejected,
        reason: 'identity_mismatch',
      );
      final b = _source('lrclib', body: _full);
      flow.request.publish(a);
      flow.request.publish(rejected);
      flow.request.publish(b);
      flow.request.response.complete([rejected, b]);
      await flow.completion;
      expect(
        h.app.results.singleWhere((source) => source.id == a.id).matchKind,
        MatchKind.rejected,
      );
      final settled = h.app.results.map((source) => source.toJson()).toList();
      // Deliberately misbehaving source: it invokes its captured observer after
      // its Future completed, without a new comparison epoch to hide the bug.
      flow.request.publish(a);
      expect(h.app.results.map((source) => source.toJson()).toList(), settled);
      expect(h.app.combined?.body, _full);
      expect(h.app.combined?.metadata['album'], isNull);
      expect(h.app.checks['genius']?.result?.matchKind, MatchKind.rejected);

      final restarted = h.app.selectCandidate(
        _selected,
        cachedResults: List<SourceResult>.of(h.app.results),
      );
      final current = await h.discovery.discoveryAt(1);
      flow.request.publish(a);
      expect(
        h.app.results.singleWhere((source) => source.id == a.id).matchKind,
        MatchKind.rejected,
      );
      expect(h.app.combined?.metadata['album'], isNull);
      current.response.complete([]);
      await restarted;
      expect(
        h.app.results.singleWhere((source) => source.id == a.id).matchKind,
        MatchKind.rejected,
      );
      expect(h.app.combined?.body, _full);
      expect(await h.repository.listSongs(), isEmpty);
    },
  );

  test(
    'a late independent provider upgrades the combined choice and alternatives',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      flow.request.publish(_source('genius'));
      await h.app.flushCombine();
      expect(h.app.combined?.body, _short);
      final fuller = _source(
        'lrclib',
        body: _full,
        metadata: {
          'album': 'Dawn Collection',
          'durationSeconds': 123,
          'artworkUrl': 'https://example.org/late-cover.jpg',
          'writers': ['Synthetic Writer'],
        },
      );
      flow.request.publish(fuller);
      await h.app.flushCombine();
      expect(h.app.combined?.body, _full);
      expect(h.app.combined?.metadata['album'], 'Dawn Collection');
      expect(h.app.combined?.metadata['durationSeconds'], 123);
      expect(h.app.combined?.extra['selectedSourceId'], fuller.id);
      expect(h.app.combined?.extra['fieldOrigins']['album'], fuller.id);
      expect(
        h.ui.state.comparison?.alternatives.map((version) => version.id),
        containsAll(['genius:song', 'lrclib:song']),
      );
      expect(h.ui.state.comparison?.suggested?.hasLyrics, isTrue);
      expect(
        _selected.album,
        isNull,
        reason: 'display enrichment is not new evidence',
      );
      expect(_selected.durationSeconds, isNull);
      flow.request.response.complete([]);
      await flow.completion;
      expect(h.app.combined?.body, _full);
    },
  );

  test(
    'explicit save and controller reopen retain lyrics metadata origins and history',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      flow.request.publish(_source('genius'));
      flow.request.publish(
        _source(
          'genius',
          body: _full,
          metadata: {
            'album': 'Dawn Collection',
            'durationSeconds': 123,
            'artworkUrl': 'https://example.org/cover.jpg',
            'composers': ['Synthetic Composer'],
          },
        ),
      );
      flow.request.publish(_source('genius', body: ''));
      flow.request.response.complete([]);
      await flow.completion;
      final saved = await h.app.saveResult();
      expect(saved.body, _full);
      expect(saved.metadata['album'], 'Dawn Collection');
      expect(saved.metadata['durationSeconds'], 123);
      expect(saved.extra['selectedSourceId'], 'genius:song');
      expect(
        saved.extra['fieldContributors']['composers'],
        contains('genius:song'),
      );
      expect(
        _history(saved.sources.single).map((version) => version.body),
        containsAll([_short, '']),
      );
      final before = (await h.repository.getSong(saved.id))!.toJson();
      await h.reopenController();
      expect(h.app.songs.single.toJson(), before);
      expect(
        h.app.songs.single.selectedRecording?.toJson(),
        _selected.toJson(),
      );
      expect(
        h.app.songs.single.sources.single.extra['previousSourceVersions'],
        saved.sources.single.extra['previousSourceVersions'],
      );
      expect(
        h.app.songs.single.metadata['artworkUrl'],
        'https://example.org/cover.jpg',
      );
      expect(await h.repository.listSongs(), hasLength(1));
    },
  );

  test(
    'provider callbacks cannot overwrite manually edited stored songs or setlists',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      flow.request.publish(_source('genius'));
      final original = await h.app.saveResult();
      final manual = original.copyWith(
        body: '[C]An owner wrote this different arrangement',
        metadata: {'album': 'Manual Album', 'composer': 'Owner'},
        extra: {
          ...original.extra,
          'fieldOrigins': {
            'lyrics': 'user',
            'album': 'user',
            'composer': 'user',
          },
        },
        favorite: true,
      );
      expect(await h.app.saveSong(manual), isTrue);
      await h.app.saveSetlist(
        SetlistDocument(
          id: 'manual-list',
          name: 'Owner rehearsal',
          entries: [SetlistEntry(id: 'entry', songId: original.id)],
        ),
      );
      final before = await _libraryRows(h.repository);
      flow.request.publish(
        _source(
          'genius',
          body: _full,
          metadata: {
            'album': 'Provider Album',
            'composers': ['New Provider Credit'],
          },
        ),
      );
      flow.request.publish(_source('lrclib', body: _full));
      flow.request.response.complete([]);
      await flow.completion;
      expect(h.app.combined?.body, _full);
      expect(await _libraryRows(h.repository), before);
      final stored = (await h.repository.getSong(original.id))!;
      expect(stored.body, manual.body);
      expect(stored.metadata['album'], 'Manual Album');
      expect(stored.extra['fieldOrigins']['lyrics'], 'user');
      expect(stored.favorite, isTrue);
      expect(
        (await h.repository.getSetlist('manual-list'))!.entries.single.songId,
        original.id,
      );
    },
  );

  test(
    'an explicit version replacement keeps library identity favorite and setlist links',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      flow.request.publish(_source('genius'));
      final original = await h.app.saveResult();
      expect(
        await h.app.saveSong(
          original.copyWith(
            favorite: true,
            metadata: {'composer': 'Owner Composition Credit'},
            extra: {
              ...original.extra,
              'fieldOrigins': {'composer': 'user'},
            },
          ),
        ),
        isTrue,
      );
      await h.app.saveSetlist(
        SetlistDocument(
          id: 'replacement-list',
          name: 'Synthetic rehearsal',
          entries: [SetlistEntry(id: 'kept-entry', songId: original.id)],
        ),
      );
      final fuller = _source(
        'lrclib',
        body: _full,
        metadata: {'album': 'Dawn Collection'},
      );
      flow.request.publish(fuller);
      flow.request.response.complete([]);
      await flow.completion;
      expect((await h.repository.getSong(original.id))!.body, _short);
      final replacement = await h.app.saveResult(source: fuller);
      expect(replacement.id, original.id);
      expect(replacement.body, _full);
      expect(replacement.favorite, isTrue);
      expect(replacement.createdAt, original.createdAt);
      expect(replacement.revision, greaterThan(original.revision));
      expect(replacement.metadata['composer'], 'Owner Composition Credit');
      expect(replacement.extra['fieldOrigins']['composer'], 'user');
      expect(
        replacement.sources.map((source) => source.body),
        contains(_short),
      );
      expect(await h.repository.listSongs(), hasLength(1));
      expect(
        (await h.repository.getSetlist(
          'replacement-list',
        ))!.entries.single.songId,
        original.id,
      );
    },
  );

  test(
    'an editor CAS conflict preserves a newer stored edit during provider enrichment',
    () async {
      final h = await open();
      final flow = await h.beginSelection();
      flow.request.publish(_source('genius'));
      final original = await h.app.saveResult();
      final baseHash = h.app.songHash(original.id)!;
      final editorSnapshot = h.app.findSong(original.id)!;
      await h.repository.saveSong(
        editorSnapshot.copyWith(
          body: 'A newer owner edit already reached storage',
          metadata: {'composer': 'New Owner Credit'},
        ),
      );
      flow.request.publish(
        _source(
          'genius',
          body: _full,
          metadata: {
            'composers': ['Late Provider Credit'],
          },
        ),
      );
      flow.request.response.complete([]);
      await flow.completion;
      expect(
        await h.app.saveSong(
          editorSnapshot.copyWith(
            body: 'An editor finished from an older snapshot',
          ),
          baseHash: baseHash,
        ),
        isFalse,
      );
      expect(h.app.lastMessage?.code, 'save_conflict');
      expect(
        (await h.repository.getSong(original.id))!.body,
        'A newer owner edit already reached storage',
      );
      expect(
        (await h.repository.getSong(original.id))!.metadata['composer'],
        'New Owner Credit',
      );
      expect(
        (await h.repository.listSongs()).map((song) => song.body).toSet(),
        {
          'A newer owner edit already reached storage',
          'An editor finished from an older snapshot',
        },
      );
    },
  );
}

List<ProviderDefinition> _definitions({
  bool geniusConfigured = true,
  bool includeGenius = true,
}) => [
  if (includeGenius)
    ProviderDefinition(
      id: 'genius',
      name: 'Synthetic Genius',
      configured: geniusConfigured,
      capabilities: const {'catalog', 'lyrics', 'metadata'},
    ),
  const ProviderDefinition(
    id: 'lrclib',
    name: 'Synthetic LRCLIB',
    capabilities: {'catalog', 'lyrics', 'metadata'},
  ),
  const ProviderDefinition(
    id: 'wikisource',
    name: 'Synthetic historical text',
    accessMode: 'publicDomainText',
    capabilities: {'catalog', 'lyrics'},
  ),
  const ProviderDefinition(
    id: 'metadata-only',
    name: 'Synthetic metadata',
    capabilities: {'metadata'},
  ),
];

SongCandidate _candidate(
  String provider, {
  String id = 'song',
  String title = _query,
}) => SongCandidate(
  providerId: provider,
  id: id,
  title: title,
  artist: 'Synthetic Ensemble',
  metadata: const {'identityScope': 'recording'},
  recordingIds: const {'syntheticRecording': 'take-one'},
);

SourceResult _source(
  String provider, {
  String body = _short,
  String title = _query,
  JsonMap metadata = const {},
  MatchKind kind = MatchKind.sameRecording,
  String? reason,
  List<TimingTrack> tracks = const [],
}) => SourceResult(
  candidate: _candidate(provider, title: title),
  body: body,
  metadata: metadata,
  matchKind: kind,
  timingTracks: tracks,
  matchReason:
      reason ??
      (kind == MatchKind.rejected ? 'identity_mismatch' : 'same_recording'),
  attribution: 'Synthetic provider attribution',
);

List<SourceResult> _history(SourceResult source) => [
  for (final payload
      in source.extra['previousSourceVersions'] as List? ?? const [])
    SourceResult.fromJson(jsonMap(payload)),
];

Future<void> _settle() => Future<void>.delayed(Duration.zero);

Future<Map<String, Object?>> _libraryRows(LibraryRepository repository) async =>
    {
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
  final _ControlledDiscovery discovery;
  AppController app;
  AppControllerAdapter ui;

  static Future<_Harness> open({
    required List<ProviderDefinition> definitions,
    required JsonMap settings,
  }) async {
    final repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    await repository.setSetting('app', settings);
    final discovery = _ControlledDiscovery(definitions);
    final app = AppController(repository: repository, discovery: discovery);
    await app.initialize();
    return _Harness(repository, discovery, app, AppControllerAdapter(app));
  }

  Future<({Future<void> completion, _DiscoveryRequest request})>
  beginSelection() async {
    ui.setHomeListMode(HomeListMode.online);
    ui.setQuery(_query);
    final search = ui.submitSearch();
    (await discovery.searchAt('genius', _query)).complete([_selected]);
    (await discovery.searchAt('lrclib', _query)).complete([]);
    await search;
    final completion = ui.selectReference(ui.state.autocomplete.single);
    final request = await discovery.discoveryAt(0);
    return (completion: completion, request: request);
  }

  Future<void> reopenController() async {
    ui.dispose();
    app.dispose();
    app = AppController(repository: repository, discovery: discovery);
    await app.initialize();
    ui = AppControllerAdapter(app);
  }

  Future<void> close() async {
    ui.dispose();
    app.dispose();
    for (final request in discovery.searches) {
      if (!request.response.isCompleted) request.complete([]);
    }
    for (final request in discovery.discoveries) {
      if (!request.response.isCompleted) request.response.complete([]);
    }
    await repository.close();
  }
}

class _ControlledDiscovery extends SourceDiscoveryService {
  _ControlledDiscovery(List<ProviderDefinition> definitions)
    : super(definitions.map(_NeverProvider.new).toList());
  final searches = <_CatalogRequest>[];
  final discoveries = <_DiscoveryRequest>[];
  final _searchWaiters = <(String, String), Completer<_CatalogRequest>>{};
  final _discoveryWaiters = <int, Completer<_DiscoveryRequest>>{};

  Future<_CatalogRequest> searchAt(String provider, String query) {
    final existing = searches
        .where(
          (request) => request.providerId == provider && request.query == query,
        )
        .firstOrNull;
    return existing == null
        ? (_searchWaiters[(provider, query)] ??= Completer<_CatalogRequest>())
              .future
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
    final request = _CatalogRequest(providerId, query, cancel);
    searches.add(request);
    _searchWaiters.remove((providerId, query))?.complete(request);
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
    final request = _DiscoveryRequest(
      selection,
      cancel,
      onProgress,
      Map<String, CancellationToken>.unmodifiable(providerCancellation),
    );
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
  }) => throw StateError(
    'Exact-provider overrides must participate in catalog search',
  );
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) => throw StateError('Pipeline discovery is controlled explicitly');
}

class _CatalogRequest {
  _CatalogRequest(this.providerId, this.query, this.cancel);
  final String providerId, query;
  final CancellationToken? cancel;
  final response = Completer<List<SongCandidate>>();
  void complete(List<SongCandidate> rows) => response.complete(rows);
}

class _DiscoveryRequest {
  _DiscoveryRequest(
    this.selection,
    this.cancel,
    this.onProgress,
    this.providerCancellation,
  );
  final SongCandidate selection;
  final CancellationToken? cancel;
  final void Function(ProviderCheck)? onProgress;
  final Map<String, CancellationToken> providerCancellation;
  final response = Completer<List<SourceResult>>();
  void publish(SourceResult source) => onProgress?.call(
    ProviderCheck(
      providerId: source.candidate.providerId,
      state: 'found',
      result: source,
    ),
  );
  void failure(String provider, String code) => onProgress?.call(
    ProviderCheck(providerId: provider, state: 'failed', code: code),
  );
}

class _ScriptedProvider implements LyricsProvider {
  _ScriptedProvider(
    String id, {
    required Set<String> capabilities,
    this.searches = const [],
  }) : definition = ProviderDefinition(
         id: id,
         name: 'Synthetic $id',
         capabilities: capabilities,
       );
  @override
  final ProviderDefinition definition;
  final List<List<SongCandidate>> searches;
  final resolved = <_ProviderResolve>[];
  final _waiters = <int, Completer<_ProviderResolve>>{};
  int searchCalls = 0;

  Future<_ProviderResolve> resolveAt(int index) => index < resolved.length
      ? Future.value(resolved[index])
      : (_waiters[index] ??= Completer<_ProviderResolve>()).future;

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final index = searchCalls++;
    return index < searches.length ? searches[index] : const [];
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) {
    final request = _ProviderResolve(candidate, cancel);
    resolved.add(request);
    _waiters.remove(resolved.length - 1)?.complete(request);
    return request.response.future;
  }
}

class _ProviderResolve {
  _ProviderResolve(this.candidate, this.cancel);
  final SongCandidate candidate;
  final CancellationToken? cancel;
  final response = Completer<SourceResult>();
}
