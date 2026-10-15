import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

class _LyricsProvider implements LyricsProvider {
  _LyricsProvider(this.id, this.resolveResult);

  final String id;
  final Future<SourceResult> Function(SongCandidate) resolveResult;

  @override
  ProviderDefinition get definition =>
      ProviderDefinition(id: id, name: id, capabilities: const {'lyrics'});

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [
    SongCandidate(
      providerId: id,
      id: 'ready',
      title: 'A Song',
      artist: 'An Artist',
    ),
  ];

  @override
  Future<SourceResult> resolve(
    SongCandidate song, {
    CancellationToken? cancel,
  }) => resolveResult(song);
}

void main() {
  sqfliteFfiInit();

  late LibraryRepository repository;
  late AppController app;
  late SongCandidate selected;

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    selected = const SongCandidate(
      providerId: 'catalog',
      id: 'song',
      title: 'A Song',
      artist: 'An Artist',
      durationSeconds: 200,
    );
  });

  tearDown(() async {
    app.dispose();
    await repository.close();
  });

  test(
    'saves a ready source during discovery as an immutable snapshot',
    () async {
      final pendingSecond = Completer<SourceResult>();
      final first = _LyricsProvider(
        'first',
        (candidate) async => SourceResult(
          candidate: SongCandidate(
            providerId: 'first',
            id: 'ready',
            title: candidate.title,
            artist: candidate.artist,
            durationSeconds: 204,
          ),
          body: 'First source lyrics',
          matchKind: MatchKind.sameSong,
          attribution: 'First source attribution',
          retrievedAt: DateTime.utc(2026, 10, 15),
          timingTracks: const [
            TimingTrack(
              id: 'first-track',
              sourceDocumentId: 'first:ready',
              sourceLyrics: 'First source lyrics',
              format: 'lrc',
              raw: '[00:01.00]First source lyrics',
            ),
          ],
        ),
      );
      final second = _LyricsProvider('second', (candidate) {
        if (candidate.title == 'A Song') return pendingSecond.future;
        return Future.value(
          SourceResult(
            candidate: SongCandidate(
              providerId: 'second',
              id: 'replacement',
              title: candidate.title,
              artist: candidate.artist,
            ),
            body: 'Replacement lyrics',
            matchKind: MatchKind.sameSong,
          ),
        );
      });
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([first, second]),
      );
      await app.initialize();

      final firstReady = Completer<void>();
      app.addListener(() {
        if (app.discovering && app.results.any((r) => r.id == 'first:ready')) {
          if (!firstReady.isCompleted) firstReady.complete();
        }
      });
      final discovery = app.selectCandidate(selected);
      await firstReady.future;

      final readyResult = app.results.singleWhere((r) => r.id == 'first:ready');
      final save = app.saveResult(source: readyResult);
      // A new selection starts while the save is queued on the library write.
      // Its mutable controller state must not replace the captured save input.
      const replacement = SongCandidate(
        providerId: 'catalog',
        id: 'replacement',
        title: 'Another Song',
        artist: 'Another Artist',
      );
      final replacementDiscovery = app.selectCandidate(replacement);

      // The old provider then finishes late. Its stale completion must not
      // change the saved source snapshot.
      pendingSecond.complete(
        SourceResult(
          candidate: const SongCandidate(
            providerId: 'second',
            id: 'ready',
            title: 'A Song',
            artist: 'An Artist',
            durationSeconds: 198,
          ),
          body: 'Late source lyrics that must not replace the saved snapshot',
          matchKind: MatchKind.sameSong,
        ),
      );
      final saved = await save;
      await discovery;
      await replacementDiscovery;
      expect(saved.body, 'First source lyrics');
      expect(saved.extra['savedSourceId'], 'first:ready');
      expect(saved.metadata['durationSeconds'], 204);
      expect(saved.extra['fieldOrigins']['durationSeconds'], 'first:ready');
      expect(saved.sources.single.attribution, 'First source attribution');
      expect(saved.sources.single.timingTracks.single.id, 'first-track');

      // Completion of later providers cannot revise the saved document.
      final persisted = (await repository.getSong(saved.id))!;
      expect(persisted.body, 'First source lyrics');
      expect(persisted.sources.map((r) => r.id), ['first:ready']);
      expect(app.selection?.identity, replacement.identity);
    },
  );

  test('rejects a source that was not in the captured results', () async {
    final provider = _LyricsProvider(
      'first',
      (candidate) async => SourceResult(
        candidate: SongCandidate(
          providerId: 'first',
          id: 'ready',
          title: candidate.title,
          artist: candidate.artist,
        ),
        body: 'Available lyrics',
        matchKind: MatchKind.sameSong,
      ),
    );
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([provider]),
    );
    await app.initialize();
    await app.selectCandidate(selected);

    expect(
      app.saveResult(
        source: SourceResult(
          candidate: const SongCandidate(
            providerId: 'missing',
            id: 'not-found',
            title: 'A Song',
            artist: 'An Artist',
          ),
          body: 'Injected lyrics',
          matchKind: MatchKind.sameSong,
        ),
      ),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'invalid_source'),
      ),
    );
  });
}
