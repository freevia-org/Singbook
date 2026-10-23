import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

class _PendingProvider implements LyricsProvider {
  _PendingProvider(this.id, {this.configured = true});
  final String id;
  final bool configured;
  final started = Completer<CancellationToken?>();
  final response = Completer<SourceResult>();
  Completer<List<SongCandidate>>? searchResponse;
  final searchStarted = Completer<CancellationToken?>();
  SongCandidate get song => SongCandidate(
    providerId: id,
    id: 'fresh',
    title: 'Fixture',
    artist: 'Original Artist',
  );
  SourceResult get result => SourceResult(
    candidate: song,
    body: 'Original fixture words preserved for this particular recording.',
  );
  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: id,
    name: id,
    capabilities: {'catalog', 'lyrics'},
    configured: configured,
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) {
    if (!searchStarted.isCompleted) searchStarted.complete(cancel);
    return searchResponse?.future ?? Future.value([song]);
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) {
    started.complete(cancel);
    // Deliberately uncooperative: the controller/service must reject late data.
    return response.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'first-run catalog search uses token-free LRCLIB when available',
    () async {
      sqfliteFfiInit();
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      addTearDown(repo.close);
      final genius = _PendingProvider('genius', configured: false);
      final lrclib = _PendingProvider('lrclib')
        ..searchResponse = Completer<List<SongCandidate>>();
      final app = AppController(
        repository: repo,
        discovery: SourceDiscoveryService([genius, lrclib]),
      );
      addTearDown(app.dispose);

      final search = app.search('Fixture');
      await lrclib.searchStarted.future;
      expect(genius.searchStarted.isCompleted, isFalse);
      lrclib.searchResponse!.complete([lrclib.song]);
      await search;

      expect(app.suggestions.single.providerId, 'lrclib');
    },
  );

  for (final reenable in [false, true]) {
    test(
      'disable excludes late YouTube discovery and preserves other providers: $reenable',
      () async {
        sqfliteFfiInit();
        final repo = await LibraryRepository.open(
          path: inMemoryDatabasePath,
          factory: databaseFactoryFfi,
        );
        addTearDown(repo.close);
        final youtube = _PendingProvider('youtubemusic');
        final other = _PendingProvider('genius');
        final app = AppController(
          repository: repo,
          discovery: SourceDiscoveryService([youtube, other]),
        );
        addTearDown(app.dispose);
        final saved = SourceResult(
          candidate: const SongCandidate(
            providerId: 'youtubemusic',
            id: 'saved',
            title: 'Fixture',
            artist: 'Original Artist',
          ),
          body: 'Previously saved original words.',
        );
        final lookup = app.selectCandidate(
          youtube.song,
          cachedResults: [saved],
        );
        final ytCancel = await youtube.started.future;
        final otherCancel = await other.started.future;
        await app.setProviderEnabled('youtubemusic', false);
        expect(ytCancel!.isCancelled, isTrue);
        expect(otherCancel!.isCancelled, isFalse);
        expect(app.discovering, isTrue);
        if (reenable) await app.setProviderEnabled('youtubemusic', true);
        youtube.response.complete(youtube.result);
        other.response.complete(other.result);
        await lookup;
        expect(
          app.results.map((r) => r.id),
          containsAll([saved.id, other.result.id]),
        );
        expect(
          app.results.map((r) => r.id),
          isNot(contains(youtube.result.id)),
        );
        expect(app.checks.containsKey('youtubemusic'), isFalse);
        expect(app.checks['genius']?.state, 'found');
      },
    );
  }

  test(
    'disabling YouTube does not cancel an unrelated catalog search',
    () async {
      sqfliteFfiInit();
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      addTearDown(repo.close);
      final other = _PendingProvider('genius')
        ..searchResponse = Completer<List<SongCandidate>>();
      final app = AppController(
        repository: repo,
        discovery: SourceDiscoveryService([
          other,
          _PendingProvider('youtubemusic'),
        ]),
      );
      addTearDown(app.dispose);
      final search = app.search('Fixture');
      final cancel = await other.searchStarted.future;
      await app.setProviderEnabled('youtubemusic', false);
      expect(cancel!.isCancelled, isFalse);
      other.searchResponse!.complete([other.song]);
      await search;
      expect(app.suggestions.map((song) => song.identity), [
        other.song.identity,
      ]);
    },
  );

  test('off/on rejects a late YouTube catalog response', () async {
    sqfliteFfiInit();
    final repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    addTearDown(repo.close);
    final youtube = _PendingProvider('youtubemusic')
      ..searchResponse = Completer<List<SongCandidate>>();
    final app = AppController(
      repository: repo,
      discovery: SourceDiscoveryService([youtube]),
    );
    addTearDown(app.dispose);
    final lookup = app.search('Fixture');
    final cancellation = await youtube.searchStarted.future;
    await app.setProviderEnabled('youtubemusic', false);
    expect(cancellation!.isCancelled, isTrue);
    await app.setProviderEnabled('youtubemusic', true);
    youtube.searchResponse!.complete([youtube.song]);
    await lookup;
    expect(app.suggestions, isEmpty);
    expect(app.searching, isFalse);
    await app.search('Fixture');
    expect(app.suggestions.single.identity, youtube.song.identity);
  });

  test('disabled YouTube cannot issue a new catalog lookup', () async {
    sqfliteFfiInit();
    final repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    addTearDown(repo.close);
    final youtube = _PendingProvider('youtubemusic');
    final app = AppController(
      repository: repo,
      discovery: SourceDiscoveryService([youtube]),
    );
    addTearDown(app.dispose);
    await app.setProviderEnabled('youtubemusic', false);
    await app.search('Fixture');
    expect(youtube.searchStarted.isCompleted, isFalse);
    expect(app.suggestions, isEmpty);
    expect(app.errorCode, 'not_configured');
  });
}
