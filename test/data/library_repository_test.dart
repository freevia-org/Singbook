import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/timing.dart';

void main() {
  late LibraryRepository repo;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() => repo.close());
  SongDocument song(
    String id, {
    String body = '[C]A lyric',
    List<TimingTrack> tracks = const [],
  }) => SongDocument(
    id: id,
    title: 'A title',
    artist: 'Artist',
    body: body,
    timingTracks: tracks,
    extra: {'selectedSourceId': 'source:1'},
  );
  test('the final playable chart is available before Save commits', () async {
    const selection = SongCandidate(
      providerId: 'provider',
      id: 'song',
      title: 'Title',
      artist: 'Artist',
    );
    final ready = Completer<SongDocument>();
    final evidenceReady = Completer<void>();
    final saving = repo.saveChosenSongFast(
      SongDocument(
        id: 'song',
        title: selection.title,
        artist: selection.artist,
        body: '[G]A lyric',
        selectedRecording: selection,
        sources: [SourceResult(candidate: selection, body: 'Source history')],
      ),
      candidateIdentity: selection.identity,
      discoveryGeneration: 1,
      existingSongId: null,
      expectedExistingHash: null,
      evidenceReady: evidenceReady.future,
      onChartPrepared: ready.complete,
    );
    final SongDocument prepared;
    try {
      prepared = await ready.future.timeout(const Duration(seconds: 5));
      expect(prepared.body, '[G]A lyric');
      expect(prepared.sources, isEmpty);
      expect(await repo.getPlayableSong(prepared.id), isNull);
    } finally {
      evidenceReady.complete();
    }
    final committed = await saving;
    expect(committed.song, same(prepared));
    expect((await repo.getPlayableSong(prepared.id))?.body, prepared.body);
  });

  test(
    'merge diagnostics stay in history and travel through sync and backup',
    () async {
      const selection = SongCandidate(
        providerId: 'source',
        id: 'diagnostics',
        title: 'A title',
        artist: 'Artist',
      );
      final conflicts = {
        'durationSeconds': [
          {'sourceId': 'provider:other', 'value': 245},
        ],
      };
      final contributors = {
        'durationSeconds': ['source:diagnostics', 'provider:other'],
      };
      final chart = SongDocument(
        id: 'diagnostics',
        title: selection.title,
        artist: selection.artist,
        body: '[G]One playable chart',
        selectedRecording: selection,
        extra: {'conflicts': conflicts, 'fieldContributors': contributors},
      );
      await repo.beginDiscoverySession(
        candidateIdentity: selection.identity,
        generation: 1,
      );
      Future<SongDocument> save(
        SongDocument song, [
        SongDocument? prior,
      ]) async {
        final saved = await repo.saveChosenSongFast(
          song,
          candidateIdentity: selection.identity,
          discoveryGeneration: 1,
          existingSongId: prior?.id,
          existingSnapshot: prior,
          expectedExistingHash: prior == null
              ? null
              : await repo.getSongEditHash(prior.id),
        );
        return saved.song;
      }

      final first = await save(chart);
      expect(first.extra, isNot(contains('conflicts')));
      expect(first.extra, isNot(contains('fieldContributors')));
      final raw = ChordProCodec().decode(
        (await repo.getSongRaw(first.id))!.document,
      );
      expect(raw.body, chart.body);
      expect(raw.extra, isNot(contains('conflicts')));
      final repeated = await save(chart, first);
      expect(repeated.revision, first.revision);
      final wire = ChordProCodec().decode(
        (await repo.getSyncSongRaw(first.id))!.document,
      );
      expect(wire.extra['conflicts'], conflicts);
      expect(wire.extra['fieldContributors'], contributors);
      expect(wire.extra, isNot(contains('libraryMergeDiagnosticsHash')));

      await repo.replaceLibrary([raw], []);
      final portableChart = (await repo.getSongWithEvidence(first.id))!;
      expect(portableChart.body, chart.body);
      expect(
        portableChart.extra,
        isNot(contains('libraryMergeDiagnosticsHash')),
      );

      await repo.replaceLibrary([wire], []);
      final restored = (await repo.getPlayableSong(first.id))!;
      expect(restored.extra, isNot(contains('conflicts')));
      expect(
        (await repo.getSongWithEvidence(first.id))!.extra['conflicts'],
        conflicts,
      );

      final second = await save(
        chart.copyWith(
          body: '[D]A different chart',
          extra: {
            'conflicts': {
              'tempo': [
                {'value': 99},
              ],
            },
          },
        ),
        restored,
      );
      final complete = (await repo.backupSnapshot()).songs.single;
      expect(complete.id, second.id);
      expect(complete.extra['conflicts'], {
        'tempo': [
          {'value': 99},
        ],
      });
      final archived = SongDocument.fromJson(
        jsonMap((complete.extra['previousSavedVersions'] as List).single),
      );
      expect(archived.extra['conflicts'], conflicts);
      expect(archived.extra['fieldContributors'], contributors);
    },
  );

  test(
    'linked evidence stays out of the playable file and travels with sync',
    () async {
      const selection = SongCandidate(
        providerId: 'source',
        id: '1',
        title: 'A title',
        artist: 'Artist',
      );
      const discovery = SourceResult(
        candidate: selection,
        body: '[G]One selected lyric',
        matchKind: MatchKind.sameRecording,
      );
      await repo.beginDiscoverySession(
        candidateIdentity: selection.identity,
        generation: 1,
      );
      await repo.stageDiscoverySources(
        candidateIdentity: selection.identity,
        generation: 1,
        sources: [discovery],
      );
      expect(await repo.listSongs(), isEmpty);

      final saved = await repo.saveChosenSongFast(
        SongDocument(
          id: 'chosen',
          title: selection.title,
          artist: selection.artist,
          body: discovery.body,
          selectedRecording: selection,
          sources: [discovery],
          extra: const {'selectedSourceId': 'source:1'},
        ),
        candidateIdentity: selection.identity,
        discoveryGeneration: 1,
        existingSongId: null,
        expectedExistingHash: null,
      );
      final active = (await repo.getSongRaw(saved.song.id))!;
      expect(ChordProCodec().decode(active.document).sources, isEmpty);
      final sync = (await repo.getSyncSongRaw(saved.song.id))!;
      final synced = ChordProCodec().decode(sync.document);
      expect(synced.body, discovery.body);
      expect(synced.sources.single.toJson(), discovery.toJson());
      expect(sync.hash, active.hash);
      expect(sync.hash, await repo.getSongHash(saved.song.id));
      expect(saved.contentHash, await repo.getSongEditHash(saved.song.id));
      expect(saved.contentHash, isNot(sync.hash));
      expect(
        (await repo.backupSnapshot()).songs.single.sources.single.id,
        discovery.id,
      );

      await repo.beginDiscoverySession(
        candidateIdentity: selection.identity,
        generation: 2,
      );
      await repo.stageDiscoverySources(
        candidateIdentity: selection.identity,
        generation: 2,
        sources: [
          const SourceResult(
            candidate: selection,
            body: 'A newer discovery awaiting Save',
            matchKind: MatchKind.sameRecording,
          ),
        ],
      );
      expect(await repo.getSongHash(saved.song.id), sync.hash);
      expect(
        (await repo.getSong(saved.song.id))!.sources.single.body,
        discovery.body,
      );
      await repo.saveChosenSongFast(
        saved.song,
        candidateIdentity: selection.identity,
        discoveryGeneration: 1,
        existingSongId: saved.song.id,
        existingSnapshot: saved.song,
        expectedExistingHash: saved.contentHash,
      );
      expect(
        (await repo.getSong(saved.song.id))!.sources.single.body,
        discovery.body,
      );
    },
  );

  test(
    'upgrading duplicate diagnostic storage preserves saved and staged history',
    () async {
      final directory = await Directory.systemTemp.createTemp('singbook-v10-');
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}${Platform.pathSeparator}library.db';
      Future<LibraryRepository> open() =>
          LibraryRepository.open(path: path, factory: databaseFactoryFfi);
      const selected = SongCandidate(
        providerId: 'source',
        id: 'old-diagnostics',
        title: 'A title',
        artist: 'Artist',
      );
      final document = SongDocument(
        id: 'chart',
        title: selected.title,
        artist: selected.artist,
        body: '[G]A playable chart',
        selectedRecording: selected,
        extra: {
          'fieldContributors': {
            'key': [selected.identity],
          },
        },
      );
      final old = await open();
      final ({String document, String hash}) wire;
      final String? stagedHash;
      try {
        await old.beginDiscoverySession(
          candidateIdentity: selected.identity,
          generation: 1,
        );
        stagedHash = await old.stageMergeDiagnostics(
          document,
          candidateIdentity: selected.identity,
          generation: 1,
        );
        await old.saveChosenSongFast(
          document,
          candidateIdentity: selected.identity,
          discoveryGeneration: 1,
          existingSongId: null,
          expectedExistingHash: null,
          stagedDiagnosticsHash: stagedHash,
        );
        wire = (await old.getSyncSongRaw(document.id))!;

        // Recreate the layout used in v10, when each reference held its own
        // payload text. Keep the saved document and its hashes byte-identical.
        await old.database.transaction((txn) async {
          await txn.execute(
            'DROP TRIGGER song_merge_diagnostics_collect_payload',
          );
          await txn.execute(
            'DROP TRIGGER discovery_merge_diagnostics_collect_payload',
          );
          for (final table in [
            'song_merge_diagnostics',
            'discovery_merge_diagnostics',
          ]) {
            await txn.execute(
              'CREATE TABLE ${table}_v10 AS SELECT ref.*, blob.payload '
              'FROM $table AS ref JOIN merge_diagnostic_payloads AS blob '
              'ON ref.payload_hash = blob.payload_hash',
            );
            await txn.execute('DROP TABLE $table');
            await txn.execute('ALTER TABLE ${table}_v10 RENAME TO $table');
          }
          await txn.execute('DROP TABLE merge_diagnostic_payloads');
          await txn.execute('PRAGMA user_version = 10');
        });
      } finally {
        await old.close();
      }

      final upgraded = await open();
      addTearDown(upgraded.close);
      expect(
        await upgraded.database.query('merge_diagnostic_payloads'),
        hasLength(1),
      );
      expect(
        (await upgraded.database.query(
          'discovery_merge_diagnostics',
        )).single['payload_hash'],
        stagedHash,
      );
      expect(await upgraded.getSyncSongRaw(document.id), wire);
      await upgraded.database.delete('discovery_merge_diagnostics');
      expect(await upgraded.getSyncSongRaw(document.id), wire);
      await upgraded.deleteSong(document.id);
      expect(
        await upgraded.database.query('merge_diagnostic_payloads'),
        isEmpty,
      );
    },
  );

  test(
    'upgrading the source index preserves chart and observation order',
    () async {
      final directory = await Directory.systemTemp.createTemp('singbook-v7-');
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}${Platform.pathSeparator}library.db';
      Future<LibraryRepository> open() =>
          LibraryRepository.open(path: path, factory: databaseFactoryFfi);
      const selected = SongCandidate(
        providerId: 'catalog',
        id: 'old',
        title: 'Title',
        artist: 'Artist',
      );
      const earlier = SourceResult(candidate: selected, body: 'Earlier source');
      const latest = SourceResult(candidate: selected, body: 'Latest source');
      final old = await open();
      final String? hash;
      final List<Map<String, Object?>> rows;
      try {
        await old.beginDiscoverySession(
          candidateIdentity: selected.identity,
          generation: 1,
        );
        await old.stageDiscoverySources(
          candidateIdentity: selected.identity,
          generation: 1,
          sources: const [earlier, latest],
        );
        await old.saveChosenSongFast(
          SongDocument(
            id: 'chart',
            title: selected.title,
            artist: selected.artist,
            body: '[C]Playable chart',
            selectedRecording: selected,
          ),
          candidateIdentity: selected.identity,
          discoveryGeneration: 1,
          existingSongId: null,
          expectedExistingHash: null,
        );
        hash = await old.getSongHash('chart');
        rows = await old.database.query('discovery_evidence', orderBy: 'rowid');
        await old.database.execute('DROP INDEX discovery_evidence_song');
        await old.database.execute(
          'CREATE INDEX discovery_evidence_song ON discovery_evidence(song_id)',
        );
        await old.database.setVersion(7);
      } finally {
        await old.close();
      }

      final upgraded = await open();
      addTearDown(upgraded.close);
      expect(await upgraded.database.getVersion(), 11);
      expect(
        (await upgraded.database.rawQuery(
          'PRAGMA index_info(discovery_evidence_song)',
        )).map((row) => row['name']),
        ['song_id', 'source_id'],
      );
      expect(await upgraded.getSongHash('chart'), hash);
      expect(
        await upgraded.database.query('discovery_evidence', orderBy: 'rowid'),
        rows,
      );
      expect(
        (await upgraded.getSongForComparison('chart'))!.sources.single.body,
        latest.body,
      );
    },
  );

  test('saving an unchanged chart does not create another revision', () async {
    const candidate = SongCandidate(
      providerId: 'catalog',
      id: 'song',
      title: 'Title',
      artist: 'Artist',
    );
    await repo.beginDiscoverySession(
      candidateIdentity: candidate.identity,
      generation: 1,
    );
    final fresh = SongDocument(
      id: 'song',
      title: candidate.title,
      artist: candidate.artist,
      body: '[C]A playable chart',
      selectedRecording: candidate,
      metadata: const {'tempo': '88'},
    );
    final first = await repo.saveChosenSongFast(
      fresh,
      candidateIdentity: candidate.identity,
      discoveryGeneration: 1,
      existingSongId: null,
      expectedExistingHash: null,
    );
    final outbox = await repo.outboxMark();
    final before = (await repo.getPlayableSong('song'))!;
    expect(before.metadata['tempo'], 88);
    final second = await repo.saveChosenSongFast(
      fresh,
      candidateIdentity: candidate.identity,
      discoveryGeneration: 1,
      existingSongId: before.id,
      existingSnapshot: before,
      expectedExistingHash: first.contentHash,
    );

    expect(second.contentHash, first.contentHash);
    expect(second.song.revision, before.revision);
    expect(await repo.outboxMark(), outbox);
    expect(await repo.database.query('song_versions'), isEmpty);
    expect(second.changed, isFalse);

    await repo.beginDiscoverySession(
      candidateIdentity: candidate.identity,
      generation: 2,
    );
    const evidence = SourceResult(candidate: candidate, body: 'New history');
    await repo.stageDiscoverySources(
      candidateIdentity: candidate.identity,
      generation: 2,
      sources: [evidence],
    );
    final third = await repo.saveChosenSongFast(
      before,
      candidateIdentity: candidate.identity,
      discoveryGeneration: 2,
      existingSongId: before.id,
      existingSnapshot: before,
      expectedExistingHash: first.contentHash,
    );
    expect(third.changed, isTrue);
    expect(third.contentHash, first.contentHash);
    expect(third.song.revision, before.revision);
    expect(await repo.outboxMark(), outbox + 1);
    expect(await repo.database.query('song_versions'), isEmpty);
    expect(
      (await repo.getSongWithEvidence('song'))!.sources.single.body,
      evidence.body,
    );
  });

  test(
    'sync and backup restore keep archived evidence off the chart',
    () async {
      const candidate = SongCandidate(
        providerId: 'catalog',
        id: 'recording',
        title: 'Title',
        artist: 'Artist',
      );
      const source = SourceResult(candidate: candidate, body: 'Provider words');
      final prior = SongDocument(
        id: 'song',
        title: candidate.title,
        artist: candidate.artist,
        body: 'Earlier playable chart',
        selectedRecording: candidate,
      );
      final transferred = prior.copyWith(
        body: 'Current playable chart',
        sources: [source],
        extra: {
          'libraryEvidenceIdentity': candidate.identity,
          'previousSavedVersions': [prior.toJson()],
        },
      );

      Future<void> verify({bool hasLocalHistory = false}) async {
        final playable = (await repo.getPlayableSong('song'))!;
        expect(playable.body, transferred.body);
        expect(playable.sources, isEmpty);
        expect(playable.extra, isNot(contains('previousSavedVersions')));
        final complete = (await repo.getSongWithEvidence('song'))!;
        expect(complete.sources.single.toJson(), source.toJson());
        final comparison = (await repo.getSongForComparison('song'))!;
        expect(comparison.sources.single.toJson(), source.toJson());
        expect(comparison.extra, isNot(contains('previousSavedVersions')));
        final versions = complete.extra['previousSavedVersions'] as List;
        expect(versions, hasLength(hasLocalHistory ? 2 : 1));
        expect(versions, contains(equals(prior.toJson())));
        final wire = ChordProCodec().decode(
          (await repo.getSyncSongRaw('song'))!.document,
        );
        expect(wire.sources.single.toJson(), source.toJson());
        expect(wire.extra['previousSavedVersions'], versions);
      }

      await repo.applySyncChanges(
        [transferred],
        [],
        expectedSongHashes: {'song': null},
        expectedSetlistHashes: {},
      );
      await verify();
      expect(await repo.outboxMark(), 0);

      final raw = (await repo.getSongRaw('song'))!;
      final imported = await repo.saveImportedSong(
        ChordProCodec().decode(raw.document),
      );
      expect(imported.id, 'song');
      expect(await repo.listSongs(), hasLength(1));
      expect(await repo.outboxMark(), 0);

      await repo.beginDiscoverySession(
        candidateIdentity: candidate.identity,
        generation: 1,
      );
      final playable = (await repo.getPlayableSong('song'))!;
      await repo.saveChosenSongFast(
        playable.copyWith(body: 'Locally changed chart'),
        candidateIdentity: candidate.identity,
        discoveryGeneration: 1,
        existingSongId: 'song',
        existingSnapshot: playable,
        expectedExistingHash: await repo.getSongEditHash('song'),
      );
      await repo.applySyncChanges(
        [transferred],
        [],
        expectedSongHashes: {'song': await repo.getSongHash('song')},
        expectedSetlistHashes: {},
      );
      await verify(hasLocalHistory: true);

      final backup = await repo.backupSnapshot();
      await repo.replaceLibrary(backup.songs, backup.setlists);
      await verify(hasLocalHistory: true);
    },
  );

  test('staging a repeated payload keeps the original song history', () async {
    const candidate = SongCandidate(
      providerId: 'catalog',
      id: 'recording',
      title: 'Title',
      artist: 'Artist',
    );
    const source = SourceResult(candidate: candidate, body: 'Provider words');

    Future<void> begin(int generation) => repo.beginDiscoverySession(
      candidateIdentity: candidate.identity,
      generation: generation,
    );
    Future<String?> stage(int generation) => repo.stageDiscoverySources(
      candidateIdentity: candidate.identity,
      generation: generation,
      sources: [source],
    );
    Future<void> save(String id, int generation) async {
      await repo.saveChosenSongFast(
        SongDocument(
          id: id,
          title: candidate.title,
          artist: candidate.artist,
          body: 'Saved chart',
          selectedRecording: candidate,
        ),
        candidateIdentity: candidate.identity,
        discoveryGeneration: generation,
        existingSongId: null,
        expectedExistingHash: null,
      );
    }

    await begin(1);
    await stage(1);
    await save('first', 1);
    final before = await repo.getSyncSongRaw('first');
    await begin(2);
    await save('second', 2);
    await stage(2);

    expect(await repo.getSyncSongRaw('first'), before);
    expect(
      (await repo.getSongWithEvidence('first'))!.sources.single.id,
      source.id,
    );
    expect((await repo.getSongWithEvidence('second'))!.sources, isEmpty);
  });

  test(
    'a provider can return to an archived version without duplicating it',
    () async {
      const candidate = SongCandidate(
        providerId: 'catalog',
        id: 'recording',
        title: 'Title',
        artist: 'Artist',
      );
      const a = SourceResult(candidate: candidate, body: 'First chart');
      const b = SourceResult(candidate: candidate, body: 'Second chart');
      Future<void> stage(int generation, List<SourceResult> sources) async {
        await repo.stageDiscoverySources(
          candidateIdentity: candidate.identity,
          generation: generation,
          sources: sources,
        );
      }

      await repo.beginDiscoverySession(
        candidateIdentity: candidate.identity,
        generation: 1,
      );
      await stage(1, [a]);
      await repo.saveChosenSongFast(
        SongDocument(
          id: 'song',
          title: candidate.title,
          artist: candidate.artist,
          body: '[C]Playable chart',
          selectedRecording: candidate,
        ),
        candidateIdentity: candidate.identity,
        discoveryGeneration: 1,
        existingSongId: null,
        expectedExistingHash: null,
      );
      await stage(1, [b]);
      final wire = await repo.getSyncSongRaw('song');
      final outbox = await repo.outboxMark();
      expect(
        (await repo.getSongForComparison('song'))!.sources.single.body,
        b.body,
      );

      await repo.database.execute(
        'CREATE TABLE observed_updates (payload_hash TEXT PRIMARY KEY)',
      );
      await repo.database.execute('''
        CREATE TRIGGER record_observed_update
        AFTER UPDATE OF observed_order ON discovery_evidence
        BEGIN INSERT INTO observed_updates VALUES (NEW.payload_hash); END
      ''');
      try {
        await stage(1, [b, a, b, a, a]);
        expect(await repo.database.query('observed_updates'), hasLength(2));
        final order = await repo.database.query(
          'discovery_evidence',
          columns: ['observed_order'],
          orderBy: 'observed_order',
        );
        expect(order.map((row) => row['observed_order']), [5, 7]);
      } finally {
        await repo.database.execute('DROP TRIGGER record_observed_update');
      }
      expect(
        (await repo.getSongForComparison('song'))!.sources.single.body,
        a.body,
      );
      expect((await repo.database.query('discovery_evidence')), hasLength(2));
      expect(await repo.getSyncSongRaw('song'), wire);
      expect(await repo.outboxMark(), outbox);

      await repo.beginDiscoverySession(
        candidateIdentity: candidate.identity,
        generation: 2,
      );
      await stage(2, [b]);
      expect(
        (await repo.getSongForComparison('song'))!.sources.single.body,
        b.body,
      );
      expect(await repo.getSyncSongRaw('song'), wire);
    },
  );

  test(
    'repeat discovery deduplicates retrieval timestamps in nested evidence',
    () async {
      const selection = SongCandidate(
        providerId: 'provider',
        id: 'song',
        title: 'Title',
        artist: 'Artist',
      );
      SourceResult fetched(int day) {
        final result = SourceResult(
          candidate: selection,
          body: 'Lyrics',
          retrievedAt: DateTime.utc(2026, 1, day),
        );
        return result.copyWith(
          extra: {
            'discoveryEvidence': {
              'acceptedPayloads': [result.toJson()],
            },
          },
        );
      }

      for (final generation in [1, 2]) {
        await repo.beginDiscoverySession(
          candidateIdentity: selection.identity,
          generation: generation,
        );
        await repo.stageDiscoverySources(
          candidateIdentity: selection.identity,
          generation: generation,
          sources: [fetched(generation), fetched(3)],
        );
      }
      expect((await repo.database.query('discovery_evidence')).length, 1);
      final saved = await repo.saveChosenSongFast(
        SongDocument(
          id: 'song',
          title: selection.title,
          artist: selection.artist,
          body: 'Lyrics',
          selectedRecording: selection,
        ),
        candidateIdentity: selection.identity,
        discoveryGeneration: 2,
        existingSongId: null,
        expectedExistingHash: null,
      );
      final comparison = (await repo.getSongForComparison(saved.song.id))!;
      expect(comparison.sources.single.body, 'Lyrics');
      expect(
        comparison.sources.single.extra,
        isNot(contains('discoveryEvidence')),
      );
      final archive = (await repo.getSongWithEvidence(saved.song.id))!;
      expect(archive.sources.single.toJson(), fetched(1).toJson());

      final beforeDuplicate = await repo.outboxMark();
      await repo.database.execute('''
        CREATE TRIGGER reject_repeated_insert BEFORE INSERT ON discovery_evidence
        BEGIN SELECT RAISE(ABORT, 'a replay must not try to insert'); END
      ''');
      final String? unchangedHash;
      try {
        unchangedHash = await repo.stageDiscoverySources(
          candidateIdentity: selection.identity,
          generation: 2,
          sources: [fetched(3)],
        );
      } finally {
        await repo.database.execute('DROP TRIGGER reject_repeated_insert');
      }
      expect(unchangedHash, await repo.getSongHash(saved.song.id));
      expect(await repo.outboxMark(), beforeDuplicate);
      expect((await repo.database.query('discovery_evidence')).length, 1);

      const newEvidence = SourceResult(
        candidate: selection,
        body: 'An alternative arrangement',
      );
      final changedHash = await repo.stageDiscoverySources(
        candidateIdentity: selection.identity,
        generation: 2,
        sources: [newEvidence],
      );
      expect(changedHash, isNot(unchangedHash));
      expect(changedHash, await repo.getSongHash(saved.song.id));
      expect(await repo.outboxMark(), beforeDuplicate + 1);
      expect((await repo.getPlayableSong(saved.song.id))?.body, 'Lyrics');
    },
  );

  test(
    'starts empty and stores complete documents and safe settings',
    () async {
      expect(await repo.listSongs(), isEmpty);
      final original = song(
        '1',
        tracks: [parseLrc('[00:01]A lyric', sourceDocumentId: 'source:1')],
      );
      await repo.saveSong(original);
      expect(
        (await repo.getSong('1'))!.timingTracks.single.raw,
        '[00:01]A lyric',
      );
      await repo.setSetting('preferences', {
        'theme': 'dark',
        'locale': 'uk',
        'enabled': ['genius'],
      });
      expect((await repo.getSetting('preferences'))['locale'], 'uk');
      expect(await repo.getSetting('missing'), isNull);
    },
  );
  test(
    'editing song preserves setlist entries and repeated occurrences',
    () async {
      await repo.saveSong(song('1'));
      await repo.saveSetlist(
        SetlistDocument(
          id: 'list',
          name: 'Practice',
          entries: [
            const SetlistEntry(id: 'first', songId: '1'),
            const SetlistEntry(
              id: 'repeat',
              songId: '1',
              overrides: {'capo': 2},
            ),
          ],
        ),
      );
      await repo.saveSong(song('1', body: '[D]New lyric'));
      final list = (await repo.getSetlist('list'))!;
      expect(list.entries.map((e) => e.id), ['first', 'repeat']);
      expect(list.entries.last.overrides['capo'], 2);
    },
  );
  test(
    'invalid setlist replacement rolls back old entries and metadata',
    () async {
      await repo.saveSong(song('1'));
      await repo.saveSetlist(
        SetlistDocument(
          id: 'list',
          name: 'Old',
          entries: [const SetlistEntry(id: 'entry', songId: '1')],
        ),
      );
      await expectLater(
        repo.saveSetlist(
          SetlistDocument(
            id: 'list',
            name: 'Broken',
            entries: [const SetlistEntry(id: 'invalid', songId: 'missing')],
          ),
        ),
        throwsA(anything),
      );
      final list = (await repo.getSetlist('list'))!;
      expect(list.name, 'Old');
      expect(list.entries.single.id, 'entry');
    },
  );
  test(
    'backup snapshot includes library and app preferences together',
    () async {
      await repo.saveSong(song('1'));
      await repo.saveSetlist(
        SetlistDocument(
          id: 'list',
          name: 'Practice',
          entries: [
            const SetlistEntry(id: 'first', songId: '1'),
            const SetlistEntry(
              id: 'repeat',
              songId: '1',
              overrides: {'capo': 2},
            ),
          ],
        ),
      );
      await repo.setSetting('app', {'themeMode': 'dark'});
      final snapshot = await repo.backupSnapshot();
      expect(snapshot.songs.map((value) => value.id), ['1']);
      expect(snapshot.setlists.single.entries.map((entry) => entry.id), [
        'first',
        'repeat',
      ]);
      expect(snapshot.setlists.single.entries.last.overrides['capo'], 2);
      expect(snapshot.appSettings['themeMode'], 'dark');
      expect(snapshot.libraryFingerprint, isNotEmpty);
    },
  );

  test(
    'backup replace is atomic and preserves repeated entries and overrides',
    () async {
      await repo.saveSong(song('old'));
      await repo.saveSong(song('incoming'));
      await repo.saveSetlist(
        SetlistDocument(
          id: 'old-list',
          name: 'Old',
          entries: [const SetlistEntry(id: 'old-entry', songId: 'old')],
        ),
      );
      final expected = (await repo.backupSnapshot()).libraryFingerprint;
      final replacement = SetlistDocument(
        id: 'new-list',
        name: 'New',
        notes: 'Keep these notes',
        entries: [
          const SetlistEntry(id: 'first', songId: 'incoming'),
          const SetlistEntry(
            id: 'repeat',
            songId: 'incoming',
            overrides: {'capo': 3},
          ),
        ],
      );
      await repo.replaceLibrary(
        [song('incoming', body: '[D]New lyric')],
        [replacement],
        appSettings: {'themeMode': 'light'},
        expectedLibraryFingerprint: expected,
      );
      expect((await repo.listSongs()).map((value) => value.id), ['incoming']);
      final stored = (await repo.listSetlists()).single;
      expect(stored.id, 'new-list');
      expect(stored.notes, 'Keep these notes');
      expect(stored.entries.map((entry) => entry.id), ['first', 'repeat']);
      expect(stored.entries.last.overrides['capo'], 3);
      expect((await repo.getSetting('app'))['themeMode'], 'light');
    },
  );

  test(
    'backup replace rejects a stale preview before changing local data',
    () async {
      await repo.saveSong(song('1'));
      final expected = (await repo.backupSnapshot()).libraryFingerprint;
      await repo.saveSong(song('1', body: '[G]Changed after preview'));
      await expectLater(
        repo.replaceLibrary(
          [song('replacement')],
          [],
          expectedLibraryFingerprint: expected,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'stale_backup_preview',
          ),
        ),
      );
      expect((await repo.listSongs()).map((value) => value.id), ['1']);
      expect((await repo.getSong('1'))!.body, '[G]Changed after preview');
    },
  );
  test(
    'backup restore guard includes preferences written after preview',
    () async {
      await repo.saveSong(song('1'));
      final expected = (await repo.backupSnapshot()).libraryFingerprint;
      await repo.setSetting('app', {
        'themeMode': 'dark',
        'accountHint': 'local',
      });
      await expectLater(
        repo.importCollection(
          [song('replacement')],
          const [],
          appSettings: {'themeMode': 'light'},
          expectedLibraryFingerprint: expected,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'stale_backup_preview',
          ),
        ),
      );
      expect((await repo.listSongs()).map((value) => value.id), ['1']);
      expect((await repo.getSetting('app'))['themeMode'], 'dark');
      expect((await repo.getSetting('app'))['accountHint'], 'local');
    },
  );
  test('repeated import merges newly found timing into original ID', () async {
    final first = await repo.saveImportedSong(song('1'));
    final second = await repo.saveImportedSong(
      song(
        '2',
        tracks: [parseLrc('[00:01]A lyric', sourceDocumentId: 'lrclib:1')],
      ),
    );
    expect(second.id, first.id);
    expect(await repo.listSongs(), hasLength(1));
    expect((await repo.getSong('1'))!.timingTracks, hasLength(1));
    final alternative = await repo.saveImportedSong(
      song('3', body: '[G]A lyric'),
    );
    expect(alternative.id, '3');
    expect(await repo.listSongs(), hasLength(2));
  });
  test('history clear preserves songs setlists and favorite flags', () async {
    await repo.saveSong(song('1').copyWith(favorite: true));
    await repo.saveSetlist(
      SetlistDocument(id: 'list', name: 'Practice', favorite: true),
    );
    for (var i = 0; i < 4; i++) {
      await repo.addActivity(
        ActivityEntry(
          id: 'event-$i',
          objectId: '1',
          objectKind: 'song',
          action: 'open',
          occurredAt: DateTime.utc(2026, 1, i + 1),
        ),
      );
    }
    expect((await repo.listActivity(limit: 2)).map((a) => a.id), [
      'event-3',
      'event-2',
    ]);
    expect((await repo.listActivity(limit: 2, offset: 2)).map((a) => a.id), [
      'event-1',
      'event-0',
    ]);
    await repo.clearActivity();
    expect(await repo.listActivity(), isEmpty);
    expect(await repo.listSongs(favoritesOnly: true), hasLength(1));
    expect(await repo.listSetlists(favoritesOnly: true), hasLength(1));
  });
  test('song deletion cascades entries but does not delete setlists', () async {
    await repo.saveSong(song('1'));
    await repo.saveSetlist(
      SetlistDocument(
        id: 'list',
        name: 'Practice',
        entries: [const SetlistEntry(id: 'entry', songId: '1')],
      ),
    );
    await repo.deleteSong('1');
    expect((await repo.getSetlist('list'))!.entries, isEmpty);
    final outbox = await repo.database.query(
      'outbox',
      where: 'action = ?',
      whereArgs: ['delete'],
    );
    expect(outbox.single['object_id'], '1');
  });
  test('library filters do not interpret SQL wildcard input', () async {
    await repo.saveSong(song('1'));
    expect(await repo.listSongs(query: 'A lyric'), hasLength(1));
    expect(await repo.listSongs(query: '%'), isEmpty);
  });
  test(
    're-discovery preserves edited arrangement and stores new timing as stale',
    () async {
      await repo.saveSong(
        song('1', body: '[D]My changed lyric').copyWith(favorite: true),
      );
      final track = parseLrc(
        '[00:01]A lyric',
        sourceDocumentId: 'lrclib:1',
      ).copyWith(status: TimingStatus.usable);
      final merged = await repo.saveImportedSong(
        song('2', tracks: [track]),
        existingId: '1',
      );
      expect(merged.id, '1');
      expect(merged.body, '[D]My changed lyric');
      expect(merged.favorite, isTrue);
      expect(merged.timingTracks.single.status, TimingStatus.stale);
    },
  );
  test(
    'collection import commits songs and setlists together or neither',
    () async {
      await expectLater(
        repo.importCollection(
          [song('1')],
          [
            SetlistDocument(
              id: 'list',
              name: 'Broken',
              // Not JSON-encodable: the write fails after the song was stored.
              entries: [
                SetlistEntry(
                  id: 'entry',
                  songId: '1',
                  overrides: {'bad': Object()},
                ),
              ],
            ),
          ],
        ),
        throwsA(anything),
      );
      expect(await repo.listSongs(), isEmpty);
      expect(await repo.database.query('outbox'), isEmpty);
      await repo.importCollection(
        [song('1')],
        [
          SetlistDocument(
            id: 'list',
            name: 'Good',
            entries: [const SetlistEntry(id: 'entry', songId: '1')],
          ),
        ],
      );
      expect((await repo.getSetlist('list'))!.entries.single.songId, '1');
    },
  );
  test(
    'conditional sync cannot overwrite edits made during network request',
    () async {
      await repo.saveSong(song('1'));
      final before = await repo.getSongHash('1');
      await repo.saveSong(song('1', body: 'Locally edited'));
      final report = await repo.applySyncChanges(
        [song('1', body: 'Remote edited'), song('2')],
        [],
        expectedSongHashes: {'1': before, '2': null},
        expectedSetlistHashes: {},
      );
      expect(report['conflictingSongIds'], ['1']);
      expect(report['savedSongIds'], ['2']);
      expect((await repo.getSong('1'))!.body, 'Locally edited');
      final current = await repo.getSongHash('1');
      await repo.applySyncChanges(
        [],
        [],
        expectedSongHashes: {'1': before},
        expectedSetlistHashes: {},
        deletedSongIds: ['1'],
      );
      expect(await repo.getSong('1'), isNotNull);
      await repo.applySyncChanges(
        [],
        [],
        expectedSongHashes: {'1': current},
        expectedSetlistHashes: {},
        deletedSongIds: ['1'],
      );
      expect(await repo.getSong('1'), isNull);
    },
  );
  test(
    'conditional setlist sync rejects stale hashes and absent expectations',
    () async {
      await repo.saveSetlist(SetlistDocument(id: 'list', name: 'Old'));
      final before = await repo.getSetlistHash('list');
      await repo.saveSetlist(SetlistDocument(id: 'list', name: 'Local edit'));
      final result = await repo.applySyncChanges(
        [],
        [
          SetlistDocument(id: 'list', name: 'Remote edit'),
          SetlistDocument(id: 'new', name: 'No expectation'),
        ],
        expectedSongHashes: {},
        expectedSetlistHashes: {'list': before},
      );
      expect(result['conflictingSetlistIds'], ['list', 'new']);
      expect((await repo.getSetlist('list'))!.name, 'Local edit');
    },
  );
  test(
    'opaque future extension keeps its full model on repository reads',
    () async {
      final opaque = SongDocument(
        id: 'opaque',
        title: 'Future',
        artist: 'Artist',
        body: 'A lyric',
        metadata: {'album': 'Album', 'tempo': 94},
        timingTracks: [
          parseLrc('[00:01]A lyric', sourceDocumentId: 'opaque-source'),
        ],
        extra: {
          'custom': {'kept': true},
        },
        preservedExtensions: [
          '{x_verse: 2 future 1}',
          '{x_verse_data: 1/1 e30}',
        ],
        extensionError: 'Unsupported',
      );
      await repo.saveSong(opaque);
      final restored = (await repo.getSong('opaque'))!;
      expect(restored.id, 'opaque');
      expect(restored.metadata['album'], 'Album');
      expect(restored.timingTracks.single.raw, '[00:01]A lyric');
      expect(restored.preservedExtensions, opaque.preservedExtensions);
      expect((await repo.listSongs()).single.toJson(), restored.toJson());

      final rawBefore = (await repo.getSongRaw('opaque'))!;
      final editedMetadata = SongDocument(
        id: restored.id,
        title: restored.title,
        artist: restored.artist,
        body: restored.body,
        metadata: {...restored.metadata, 'localOnlyMetadata': 'Changed'},
        sources: restored.sources,
        timingTracks: restored.timingTracks,
        favorite: restored.favorite,
        createdAt: restored.createdAt,
        updatedAt: restored.updatedAt,
        selectedRecording: restored.selectedRecording,
        activeTimingTrackId: restored.activeTimingTrackId,
        revision: restored.revision + 1,
        extra: restored.extra,
        preservedExtensions: restored.preservedExtensions,
        extensionError: restored.extensionError,
      );
      await repo.saveSong(editedMetadata);
      final rawAfter = (await repo.getSongRaw('opaque'))!;
      expect(rawAfter.document, rawBefore.document);
      expect(rawAfter.hash, isNot(rawBefore.hash));
      expect(await repo.saveSongIfUnchanged(restored, rawBefore.hash), isFalse);

      await repo.saveSong(
        SongDocument(
          id: restored.id,
          title: restored.title,
          artist: restored.artist,
          body: restored.body,
          metadata: restored.metadata,
          createdAt: restored.createdAt,
          updatedAt: restored.updatedAt,
        ),
      );
      final columns = await repo.database.query(
        'songs',
        columns: const ['full_document', 'full_document_hash'],
        where: 'id = ?',
        whereArgs: const ['opaque'],
      );
      expect(columns.single['full_document'], isNull);
      expect(columns.single['full_document_hash'], isNull);
    },
  );

  test(
    'large opaque sidecar is chunk-read by get, list, and backup snapshot',
    () async {
      final large = SongDocument(
        id: 'large-opaque',
        title: 'Large future song',
        artist: 'Band',
        body: 'Words',
        extra: {'largeField': 'x' * (140 * 1024)},
        preservedExtensions: ['{x_verse: unsupported}'],
        extensionError: 'Unsupported x_verse extension',
      );
      await repo.saveSong(large);
      final setlist = SetlistDocument(
        id: 'large-sidecar-setlist',
        name: 'Large sidecar setlist',
        entries: const [
          SetlistEntry(id: 'large-entry', songId: 'large-opaque'),
        ],
      );
      await repo.saveSetlist(setlist);

      expect(
        (await repo.getSong(large.id))!.extra['largeField'],
        large.extra['largeField'],
      );
      expect(
        (await repo.listSongs()).single.extra['largeField'],
        large.extra['largeField'],
      );
      final snapshot = await repo.backupSnapshot();
      expect(
        snapshot.songs.single.extra['largeField'],
        large.extra['largeField'],
      );
      final library = await repo.librarySnapshot();
      expect(
        library.songs.single.extra['largeField'],
        large.extra['largeField'],
      );
      expect(library.songHashes[large.id], await repo.getSongHash(large.id));
      expect(library.setlists.single.entries.single.songId, large.id);
    },
  );

  test('version 3 database upgrades without changing stored song identity', () async {
    final directory = await Directory.systemTemp.createTemp('singbook-v3-');
    final path = '${directory.path}${Platform.pathSeparator}library.db';
    const legacyOpaqueDocument =
        '{title:Legacy opaque}\n{artist:Band}\n{x_verse: 2 future 1}\n{x_verse_data: 1/1 e30}\n\nWords';
    final legacyCreatedAt = DateTime.utc(2020, 1, 1);
    final legacyUpdatedAt = DateTime.utc(2020, 1, 2);
    final legacyOpaqueCreatedAt = DateTime.utc(2017, 4, 3, 2, 1);
    final legacyDocument = ChordProCodec().encode(
      SongDocument(
        id: 'legacy-id',
        title: 'Legacy',
        artist: 'Band',
        body: '[C]Old words',
        createdAt: legacyCreatedAt,
        updatedAt: legacyUpdatedAt,
        revision: 7,
      ),
    );
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE songs (id TEXT PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL, album TEXT, favorite INTEGER NOT NULL DEFAULT 0, document TEXT NOT NULL, content_hash TEXT NOT NULL, lyric_hash TEXT NOT NULL, source_identity TEXT, revision INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, search_text TEXT)',
          );
          await db.execute(
            'CREATE INDEX songs_title_artist ON songs(title COLLATE NOCASE,artist COLLATE NOCASE)',
          );
          await db.execute(
            'CREATE INDEX songs_source ON songs(source_identity,lyric_hash)',
          );
          await db.execute(
            'CREATE TABLE setlists (id TEXT PRIMARY KEY, name TEXT NOT NULL, notes TEXT NOT NULL, favorite INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE setlist_entries (id TEXT PRIMARY KEY, setlist_id TEXT NOT NULL REFERENCES setlists(id) ON DELETE CASCADE, song_id TEXT NOT NULL REFERENCES songs(id) ON DELETE CASCADE, position INTEGER NOT NULL, overrides TEXT NOT NULL, UNIQUE(setlist_id,position))',
          );
          await db.execute(
            'CREATE INDEX setlist_entries_song ON setlist_entries(song_id)',
          );
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE activity (id TEXT PRIMARY KEY, object_id TEXT NOT NULL, object_kind TEXT NOT NULL, action TEXT NOT NULL, occurred_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE INDEX activity_order ON activity(occurred_at DESC,id DESC)',
          );
          await db.execute(
            'CREATE TABLE outbox (id TEXT PRIMARY KEY, object_id TEXT NOT NULL, object_kind TEXT NOT NULL, action TEXT NOT NULL, revision INTEGER, created_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE sync_items (account TEXT NOT NULL, kind TEXT NOT NULL, item_id TEXT NOT NULL, cloud_hash TEXT NOT NULL, local_hash TEXT NOT NULL, PRIMARY KEY(account,kind,item_id))',
          );
          await db.insert('songs', {
            'id': 'legacy-id',
            'title': 'Legacy',
            'artist': 'Band',
            'favorite': 0,
            'document': legacyDocument,
            'content_hash': sha256
                .convert(utf8.encode(legacyDocument))
                .toString(),
            'lyric_hash': 'legacy-lyrics',
            'revision': 7,
            'created_at': legacyCreatedAt.toIso8601String(),
            'updated_at': legacyUpdatedAt.toIso8601String(),
            'search_text': 'legacy\nband\nold words',
          });
          await db.insert('songs', {
            'id': 'legacy-opaque-id',
            'title': 'Legacy opaque',
            'artist': 'Band',
            'favorite': 0,
            'document': legacyOpaqueDocument,
            'content_hash': 'legacy-opaque-hash',
            'lyric_hash': 'legacy-opaque-lyrics',
            'revision': 4,
            'created_at': legacyOpaqueCreatedAt.toIso8601String(),
            'updated_at': '2020-01-02T00:00:00.000Z',
            'search_text': 'legacy opaque\nband\nwords',
          });
        },
      ),
    );
    await old.close();

    final upgraded = await LibraryRepository.open(
      path: path,
      factory: databaseFactoryFfi,
    );
    final restored = (await upgraded.getSong('legacy-id'))!;
    expect(restored.title, 'Legacy');
    expect(restored.revision, 7);
    final raw = (await upgraded.getSongRaw('legacy-id'))!;
    expect(raw.document, legacyDocument);
    expect(raw.hash, sha256.convert(utf8.encode(legacyDocument)).toString());
    final expectedOpaqueCreatedAt = legacyOpaqueCreatedAt;
    expect(
      (await upgraded.getSong('legacy-opaque-id'))!.createdAt,
      expectedOpaqueCreatedAt,
    );
    final listedOpaque = (await upgraded.listSongs()).singleWhere(
      (song) => song.id == 'legacy-opaque-id',
    );
    expect(listedOpaque.createdAt, expectedOpaqueCreatedAt);
    final snapshot = await upgraded.backupSnapshot();
    final snapshotOpaque = snapshot.songs.singleWhere(
      (song) => song.id == 'legacy-opaque-id',
    );
    expect(snapshotOpaque.createdAt, expectedOpaqueCreatedAt);
    final backupRestore = decodeLibraryPackage(
      encodeLibraryPackage(snapshot.songs, snapshot.setlists),
    );
    expect(
      backupRestore.songs
          .singleWhere((song) => song.id == 'legacy-opaque-id')
          .createdAt,
      expectedOpaqueCreatedAt,
    );
    final opaqueRow = await upgraded.database.query(
      'songs',
      columns: const ['document'],
      where: 'id = ?',
      whereArgs: const ['legacy-opaque-id'],
    );
    expect(opaqueRow.single['document'], legacyOpaqueDocument);
    expect(
      (await upgraded.database.rawQuery(
        'PRAGMA user_version',
      )).single.values.single,
      11,
    );
    await upgraded.close();
    await directory.delete(recursive: true);
  });
}
