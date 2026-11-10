import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/combine_runner.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
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

  for (final expired in [false, true]) {
    test(
      expired
          ? 'Save recovers an expired diagnostic record without a partial write'
          : 'the completed merge stages diagnostics before Save links them',
      () async {
        app = AppController(
          repository: repository,
          discovery: SourceDiscoveryService([]),
        );
        await app.initialize();
        final source = SourceResult(
          candidate: selected,
          body: '[G]A playable chart',
          matchKind: MatchKind.sameRecording,
        );
        await app.selectCandidate(selected, cachedResults: [source]);

        final staged = (await repository.database.rawQuery(
          'SELECT blob.payload_hash,blob.payload FROM discovery_merge_diagnostics AS staged '
          'JOIN merge_diagnostic_payloads AS blob ON blob.payload_hash = staged.payload_hash '
          'WHERE staged.candidate_identity = ?',
          [selected.identity],
        )).single;
        expect(staged['payload'], contains('fieldContributors'));
        expect(
          await repository.database.query('song_merge_diagnostics'),
          isEmpty,
        );
        expect(await repository.listSongs(), isEmpty);

        if (expired) {
          await repository.database.delete('discovery_merge_diagnostics');
          expect(
            await repository.database.query('merge_diagnostic_payloads'),
            isEmpty,
          );
        } else {
          await repository.database.execute('''
            CREATE TRIGGER no_payload_copy BEFORE INSERT ON merge_diagnostic_payloads
            BEGIN SELECT RAISE(ABORT, 'Save must link the stored payload'); END
          ''');
        }
        // Save must use either the original staging or its captured merge.
        // It cannot require discovery to run again.
        await repository.database.execute('''
      CREATE TRIGGER no_late_staging BEFORE INSERT ON discovery_merge_diagnostics
      BEGIN SELECT RAISE(ABORT, 'diagnostics must be staged before Save'); END
    ''');
        final saved = await app.saveResult(includeEvidence: false);
        final attached = (await repository.database.rawQuery(
          'SELECT blob.payload_hash,blob.payload FROM song_merge_diagnostics AS stored '
          'JOIN merge_diagnostic_payloads AS blob ON blob.payload_hash = stored.payload_hash '
          'WHERE stored.song_id = ?',
          [saved.id],
        )).single;
        expect(attached, staged);
        expect(
          await repository.database.query('merge_diagnostic_payloads'),
          hasLength(1),
        );
        expect(saved.revision, 1);
        expect(await repository.outboxMark(), 1);
        expect(await repository.database.query('song_versions'), isEmpty);
        expect(saved.extra, isNot(contains('fieldContributors')));
        expect(
          (await repository.getSongWithEvidence(saved.id))!.extra,
          contains('fieldContributors'),
        );
      },
    );
  }

  test(
    'lightweight Save cannot succeed if accepted history failed to stage',
    () async {
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([]),
      );
      await app.initialize();
      await repository.database.execute('''
      CREATE TRIGGER fail_evidence_stage BEFORE INSERT ON discovery_evidence
      BEGIN SELECT RAISE(ABORT, 'fixture failed to stage evidence'); END
    ''');
      final accepted = SourceResult(
        candidate: selected,
        body: '[G]A playable chart',
        matchKind: MatchKind.sameRecording,
      );
      await app.selectCandidate(selected, cachedResults: [accepted]);
      expect(app.canSavePreparedCombined, isTrue);

      await expectLater(
        app.saveResult(includeEvidence: false),
        throwsA(isA<DatabaseException>()),
      );
      expect(await repository.database.query('songs'), isEmpty);
      expect(
        await repository.database.query('song_merge_diagnostics'),
        isEmpty,
      );
    },
  );

  test(
    'restarting the same discovery keeps accepted evidence from both sessions',
    () async {
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([]),
      );
      await app.initialize();
      final first = SourceResult(
        candidate: selected,
        body: 'The first accepted arrangement',
        matchKind: MatchKind.sameSong,
      );
      final second = SourceResult(
        candidate: selected,
        body: 'The second accepted arrangement',
        matchKind: MatchKind.sameSong,
      );

      final oldDiscovery = app.selectCandidate(
        selected,
        cachedResults: [first],
      );
      final newDiscovery = app.selectCandidate(
        selected,
        cachedResults: [second],
      );
      await Future.wait([oldDiscovery, newDiscovery]);

      final saved = await app.saveResult(
        source: second,
        includeEvidence: false,
      );
      expect(saved.body, second.body);
      final evidence = await repository.database.query(
        'discovery_evidence',
        columns: ['song_id', 'payload'],
        where: 'song_id = ?',
        whereArgs: [saved.id],
      );
      expect(evidence, hasLength(2));
      expect(
        evidence.map((row) => row['payload']),
        contains(contains(first.body)),
      );
      expect(
        evidence.map((row) => row['payload']),
        contains(contains(second.body)),
      );
      expect((await repository.getPlayableSong(saved.id))?.sources, isEmpty);
    },
  );

  test(
    'immediate Save claims the arrangement already started by selection',
    () async {
      final source = SourceResult(
        candidate: SongCandidate(
          providerId: 'first',
          id: 'ready',
          title: selected.title,
          artist: selected.artist,
        ),
        body: '[C]The selected chart',
        matchKind: MatchKind.sameSong,
      );
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([
          _LyricsProvider('first', (_) async => source),
        ]),
      );
      await app.initialize();
      await app.selectCandidate(selected);
      final liveSource = app.results.singleWhere(
        (result) => result.id == source.id,
      );
      // The comparison's Save action can also replace a chart from a source
      // that is already in the library.
      final firstSave = await app.saveResult(
        source: liveSource,
        includeEvidence: false,
      );
      expect(app.savedResultId(source: liveSource), firstSave.id);
      final workerStarted = Completer<void>();
      final workerProduct = Completer<SongDocument>();
      var preparations = 0;
      app.preferredArrangementPreparer = PreferredArrangementPreparer(
        compute:
            (
              request, {
              required sourceId,
              required compact,
              required allowRejectedPreferredSource,
            }) {
              preparations++;
              expect(sourceId, source.id);
              expect(compact, isTrue);
              workerStarted.complete();
              return workerProduct.future;
            },
      );

      app.prepareVersionForSave(liveSource.id);
      await workerStarted.future.timeout(const Duration(seconds: 3));
      final saving = app.saveResult(source: liveSource, includeEvidence: false);
      expect(
        (await repository.getPlayableSong(firstSave.id))?.revision,
        firstSave.revision,
      );
      workerProduct.complete(
        SongDocument(
          id: 'prepared-chart',
          title: selected.title,
          artist: selected.artist,
          body: source.body,
          selectedRecording: selected,
          extra: {
            'selectedSourceId': source.id,
            'preparedProof': true,
            'fieldContributors': {
              'tempo': [source.id],
            },
          },
        ),
      );
      final saved = await saving;

      expect(preparations, 1);
      expect(saved.id, firstSave.id);
      expect(saved.revision, firstSave.revision + 1);
      expect(saved.extra['preparedProof'], isTrue);
      expect(saved.body, source.body);
      final attached = await repository.database.rawQuery(
        'SELECT blob.payload FROM song_merge_diagnostics AS stored '
        'JOIN merge_diagnostic_payloads AS blob ON blob.payload_hash = stored.payload_hash '
        'JOIN discovery_merge_diagnostics AS staged '
        'ON staged.payload_hash = stored.payload_hash '
        'WHERE stored.song_id = ? AND staged.candidate_identity = ? '
        "AND blob.payload LIKE '%tempo%'",
        [saved.id, selected.identity],
      );
      expect(attached.single['payload'], contains(source.id));
      expect((await repository.getPlayableSong(saved.id))?.sources, isEmpty);
      expect(
        (await repository.getSongWithEvidence(saved.id))?.sources.single.id,
        source.id,
      );
    },
  );

  test(
    'Save preserves duplicate lookup priority and removes replaced keys',
    () async {
      const formerReference = SongCandidate(
        providerId: 'former',
        id: 'chart',
        title: 'Former chart',
        artist: 'An Artist',
      );
      final source = SourceResult(
        candidate: selected,
        body: '[G]A new chart',
        matchKind: MatchKind.sameRecording,
      );
      final formerSource = SourceResult(candidate: formerReference, body: '');
      await repository.saveSong(
        SongDocument(
          id: 'replace',
          title: selected.title,
          artist: selected.artist,
          body: 'Earlier chart',
          selectedRecording: selected,
          updatedAt: DateTime.utc(2025),
          extra: {
            'savedSourceId': formerSource.id,
            'combinedSelection': selected.identity,
          },
        ),
      );
      for (final (id, key) in [
        ('former-copy', formerSource.id),
        ('new-copy', source.id),
      ]) {
        await repository.saveSong(
          SongDocument(
            id: id,
            title: id,
            artist: 'An Artist',
            body: 'Other library chart',
            updatedAt: DateTime.utc(2026),
            extra: {'savedSourceId': key},
          ),
        );
      }
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([]),
      );
      await app.initialize();
      await app.selectCandidate(selected, cachedResults: [source]);
      expect(app.savedResultId(), 'replace');
      expect(app.savedResultId(source: formerSource), 'replace');

      final saved = await app.saveResult(
        source: source,
        includeEvidence: false,
      );

      expect(saved.id, 'replace');
      expect(app.songs.map((song) => song.id), [
        'replace',
        'former-copy',
        'new-copy',
      ]);
      expect(app.savedResultId(), isNull);
      expect(app.savedResultId(source: formerSource), 'former-copy');
      expect(app.savedResultId(source: source), 'new-copy');
    },
  );

  test(
    'Save prefers the oldest exact reference over a matching name',
    () async {
      final earlier = DateTime.utc(2025);
      final later = DateTime.utc(2026);
      await repository.saveSong(
        SongDocument(
          id: 'name-match',
          title: selected.title,
          artist: selected.artist,
          body: 'Display-name match',
          createdAt: earlier,
        ),
      );
      for (final id in ['exact-b', 'exact-a', 'conflict']) {
        await repository.saveSong(
          SongDocument(
            id: id,
            title: 'Locally renamed',
            artist: 'Local credit',
            body: 'Previously saved chart',
            selectedRecording: selected,
            createdAt: id == 'conflict' ? earlier : later,
            extra: {if (id == 'conflict') 'syncConflict': true},
          ),
        );
      }

      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([]),
      );
      await app.initialize();
      final source = SourceResult(
        candidate: selected,
        body: '[G]New chart',
        matchKind: MatchKind.sameRecording,
      );
      await app.selectCandidate(selected, cachedResults: [source]);
      final saved = await app.saveResult(
        source: source,
        includeEvidence: false,
      );

      expect(saved.id, 'exact-a');
      expect(saved.body, source.body);
      expect(
        (await repository.getPlayableSong('name-match'))?.body,
        'Display-name match',
      );
      expect(
        (await repository.getPlayableSong('conflict'))?.body,
        'Previously saved chart',
      );

      // Replacing exact-a changed its display name. The old name still
      // resolves to exact-b, without rebuilding the library snapshot.
      const alias = SongCandidate(
        providerId: 'different-provider',
        id: 'alias',
        title: 'Locally renamed',
        artist: 'Local credit',
      );
      const aliasSource = SourceResult(
        candidate: alias,
        body: '[D]Other chart',
        matchKind: MatchKind.sameRecording,
      );
      await app.selectCandidate(alias, cachedResults: [aliasSource]);
      final other = await app.saveResult(
        source: aliasSource,
        includeEvidence: false,
      );
      expect(other.id, 'exact-b');
      expect((await repository.getPlayableSong('exact-a'))?.body, source.body);
    },
  );

  test(
    'a new selection can prepare while an old preview is still running',
    () async {
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([]),
      );
      await app.initialize();
      const second = SongCandidate(
        providerId: 'catalog',
        id: 'second',
        title: 'Another song',
        artist: 'Another artist',
      );
      final started = Completer<void>();
      final obsolete = Completer<CombineOutcome>();
      app.combineRunner = CombineRunner(
        compute: (request) async {
          if (request.candidate == selected) {
            if (!started.isCompleted) started.complete();
            return obsolete.future;
          }
          return computeCombine(request);
        },
      );
      final first = app.selectCandidate(
        selected,
        cachedResults: [
          SourceResult(candidate: selected, body: 'Earlier lyrics'),
        ],
      );
      await started.future;
      try {
        await app
            .selectCandidate(
              second,
              cachedResults: const [
                SourceResult(candidate: second, body: 'New lyrics'),
              ],
            )
            .timeout(const Duration(seconds: 5));
        expect(app.canSavePreparedCombined, isTrue);
        expect(app.combined?.body, 'New lyrics');
      } finally {
        obsolete.completeError(StateError('obsolete preview failed'));
        await first;
      }
      expect(app.combined?.body, 'New lyrics');
      expect(app.errorCode, isNull);
    },
  );

  test(
    'switching versions frees Save from the abandoned preparation',
    () async {
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([]),
      );
      await app.initialize();
      final first = SourceResult(candidate: selected, body: 'Earlier words');
      final second = SourceResult(
        candidate: selected,
        arrangementId: 'alternate',
        body: '[G]Chosen words',
      );
      await app.selectCandidate(selected, cachedResults: [first, second]);
      final blocked = Completer<SongDocument>();
      final started = <String>[];
      app.preferredArrangementPreparer = PreferredArrangementPreparer(
        compute:
            (
              request, {
              required sourceId,
              required compact,
              required allowRejectedPreferredSource,
            }) {
              started.add(sourceId);
              if (sourceId == first.id) return blocked.future;
              return Future.value(
                SongDocument(
                  id: 'chosen',
                  title: selected.title,
                  artist: selected.artist,
                  body: second.body,
                  selectedRecording: selected,
                ),
              );
            },
      );
      try {
        app.prepareVersionForSave(first.id);
        app.prepareVersionForSave(second.id);
        final saved = await app
            .saveResult(source: second, includeEvidence: false)
            .timeout(const Duration(seconds: 5));
        expect(started, [first.id, second.id]);
        expect(saved.body, second.body);
        expect(saved.sources, isEmpty);
        app.prepareVersionForSave(second.id);
        final repeated = await app.saveResult(
          source: second,
          includeEvidence: false,
        );
        expect(started, [first.id, second.id]);
        expect(repeated.revision, saved.revision);
      } finally {
        blocked.completeError(StateError('obsolete speculative worker'));
      }
    },
  );

  test('explicit Save claims preparation with the same chart policy', () async {
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([]),
    );
    await app.initialize();
    SongCandidate candidate(String providerId) => SongCandidate(
      providerId: providerId,
      id: selected.id,
      title: selected.title,
      artist: selected.artist,
      durationSeconds: selected.durationSeconds,
    );
    final chart = SourceResult(
      candidate: candidate('chart'),
      body: '[C]one two three four five six seven eight nine ten eleven twelve',
      matchKind: MatchKind.sameSong,
    );
    final lyrics = SourceResult(
      candidate: candidate('lyrics'),
      body:
          'one two three four five six seven eight nine ten eleven twelve\n'
          'thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty '
          'twentyone twentytwo twentythree twentyfour',
      matchKind: MatchKind.sameRecording,
    );
    await app.selectCandidate(selected, cachedResults: [chart, lyrics]);
    final request = CombineRequest(
      candidate: selected,
      results: app.results,
      historicalCacheUses: const [],
    );
    await expectLater(
      combineForSave(
        request,
        preferredSourceId: chart.id,
        allowRejectedPreferredSource: false,
        pendingSources: const {},
        compactExplicitSave: true,
      ),
      throwsFormatException,
    );

    final preparations = <bool>[];
    app.preferredArrangementPreparer = PreferredArrangementPreparer(
      compute:
          (
            request, {
            required sourceId,
            required compact,
            required allowRejectedPreferredSource,
          }) async {
            preparations.add(allowRejectedPreferredSource);
            final prepared = await combineForSave(
              request,
              preferredSourceId: sourceId,
              allowRejectedPreferredSource: allowRejectedPreferredSource,
              pendingSources: const {},
              compactExplicitSave: compact,
            );
            return prepared.copyWith(
              extra: {...prepared.extra, 'preparedProof': true},
            );
          },
    );
    app.prepareVersionForSave(chart.id, allowRejectedSource: true);
    final saved = await app.saveResult(
      source: chart,
      allowRejectedSource: true,
      includeEvidence: false,
    );

    expect(preparations, [true]);
    expect(saved.body, chart.body);
    expect(saved.extra['preparedProof'], isTrue);
    expect(saved.extra['savedSourceId'], chart.id);
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
      final save = app.saveResult(source: readyResult, includeEvidence: false);
      // A new selection starts while the save is queued on the library write.
      // Its mutable controller state must not replace the captured save input.
      const replacement = SongCandidate(
        providerId: 'catalog',
        id: 'replacement',
        title: 'Another Song',
        artist: 'Another Artist',
      );
      final replacementDiscovery = app.selectCandidate(replacement);

      // Save can commit while the old provider's response is still pending.
      final saved = await save;
      // Its later completion must not change the captured save snapshot.
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
      await discovery;
      await replacementDiscovery;
      expect(saved.body, 'First source lyrics');
      expect(saved.extra['savedSourceId'], 'first:ready');
      expect(saved.metadata['durationSeconds'], 204);
      expect(saved.extra['fieldOrigins']['durationSeconds'], 'first:ready');
      expect(saved.sources, isEmpty);
      final archive = (await repository.getSongWithEvidence(saved.id))!;
      expect(archive.sources.single.attribution, 'First source attribution');
      expect(archive.sources.single.timingTracks.single.id, 'first-track');
      final capturedDiagnostics = await repository.database.rawQuery(
        'SELECT staged.payload_hash FROM discovery_merge_diagnostics AS staged '
        'JOIN song_merge_diagnostics AS stored '
        'ON stored.payload_hash = staged.payload_hash '
        'WHERE staged.candidate_identity = ? AND stored.song_id = ?',
        [selected.identity, saved.id],
      );
      expect(capturedDiagnostics, hasLength(1));

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

  test('overlapping saves apply in selection order', () async {
    SourceResult source(String provider, String body) => SourceResult(
      candidate: SongCandidate(
        providerId: provider,
        id: 'ready',
        title: selected.title,
        artist: selected.artist,
      ),
      body: body,
      matchKind: MatchKind.sameSong,
    );
    final first = source('first', 'First source lyrics');
    final second = source('second', 'Second source lyrics');
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([
        _LyricsProvider('first', (_) async => first),
        _LyricsProvider('second', (_) async => second),
      ]),
    );
    await app.initialize();
    await app.selectCandidate(selected);

    final beforeSave = await repository.database.query(
      'discovery_evidence',
      columns: ['source_id', 'song_id'],
      orderBy: 'source_id',
    );
    expect(beforeSave, [
      {'source_id': first.id, 'song_id': null},
      {'source_id': second.id, 'song_id': null},
    ]);

    final earlier = app.saveResult(source: first);
    final later = app.saveResult(source: second);
    final saved = await Future.wait([earlier, later]);

    expect(saved.first.id, saved.last.id);
    final persisted = (await repository.getSong(saved.last.id))!;
    expect(persisted.extra['savedSourceId'], second.id);
    expect(persisted.body, second.body);
    expect(
      persisted.sources.map((source) => source.id),
      containsAll([first.id, second.id]),
    );
    final active = (await repository.database.query(
      'songs',
      columns: ['document'],
      where: 'id = ?',
      whereArgs: [persisted.id],
    )).single;
    final playable = ChordProCodec().decode(active['document'] as String);
    expect(playable.body, second.body);
    expect(playable.sources, isEmpty);
    expect(playable.extra['previousSavedVersions'], isNull);
  });
}
