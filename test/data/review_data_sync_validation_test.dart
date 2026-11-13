import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  late LibraryRepository repo;
  setUp(() async {
    sqfliteFfiInit();
    directory = await Directory.systemTemp.createTemp('singbook-review-data-');
    repo = await LibraryRepository.open(
      path: '${directory.path}${Platform.pathSeparator}library.db',
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() async {
    await repo.close();
    try {
      await directory.delete(recursive: true);
    } catch (_) {}
  });

  SongDocument song(String id, String body) => SongDocument(
    id: id,
    title: 'Title $id',
    artist: 'Artist',
    body: body,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  Future<void> saveLinked(String id) async {
    final candidate = SongCandidate(
      providerId: 'catalog',
      id: id,
      title: 'Linked',
      artist: 'Artist',
    );
    await repo.beginDiscoverySession(
      candidateIdentity: candidate.identity,
      generation: 1,
    );
    await repo.stageDiscoverySources(
      candidateIdentity: candidate.identity,
      generation: 1,
      sources: [SourceResult(candidate: candidate, body: '[C]A source')],
    );
    await repo.saveChosenSongFast(
      SongDocument(
        id: id,
        title: 'Linked',
        artist: 'Artist',
        body: '[C]Playable chart',
        selectedRecording: candidate,
      ),
      candidateIdentity: candidate.identity,
      discoveryGeneration: 1,
      existingSongId: null,
      expectedExistingHash: null,
    );
  }

  Future<void> damage(String id) => repo.database.update(
    'songs',
    {'document': '{title: Replaced behind the hash}'},
    where: 'id = ?',
    whereArgs: [id],
  );

  group('validating songs for sync', () {
    test(
      'accepts plain and evidence-linked songs and fills the memo',
      () async {
        await repo.saveSong(song('plain', 'one'));
        await saveLinked('linked');
        final memo = <String, String>{};

        await repo.validateSyncSongData();
        await repo.validateSyncSongData(validated: memo);

        expect(memo, {
          'plain': await repo.getSongHash('plain'),
          'linked': await repo.getSongHash('linked'),
        });
        // Validation alone never changes what sync would upload.
        final wire = await repo.getSyncSongRaw('linked');
        expect(wire!.hash, memo['linked']);
        expect(ChordProCodec().decode(wire.document).sources, hasLength(1));
      },
    );

    test('still refuses a document that no longer matches its hash', () async {
      await repo.saveSong(song('plain', 'one'));
      await damage('plain');
      await expectLater(repo.validateSyncSongData(), throwsFormatException);
      await expectLater(
        repo.validateSyncSongData(validated: {}),
        throwsFormatException,
      );
    });

    test('still refuses an evidence index that no longer matches', () async {
      await saveLinked('linked');
      await repo.database.delete('discovery_evidence');
      await expectLater(repo.validateSyncSongData(), throwsFormatException);
    });

    test('reads a memoised song again once its content hash changed', () async {
      await repo.saveSong(song('plain', 'one'));
      await repo.saveSong(song('other', 'two'));
      final memo = <String, String>{};
      await repo.validateSyncSongData(validated: memo);
      final first = memo['plain'];

      await repo.saveSong(song('plain', 'changed'));
      await repo.deleteSong('other');
      await repo.validateSyncSongData(validated: memo);

      expect(memo.keys, ['plain']);
      expect(memo['plain'], isNot(first));
      expect(memo['plain'], await repo.getSongHash('plain'));

      // A stale entry never hides a song: the hash differs, so it is read.
      memo['plain'] = first!;
      await damage('plain');
      await expectLater(
        repo.validateSyncSongData(validated: memo),
        throwsFormatException,
      );
    });
  });

  group('applying sync changes', () {
    test('writes songs encoded off the UI isolate unchanged', () async {
      final incoming = song('s', '[C]From the cloud');
      final result = await repo.applySyncChanges(
        [incoming],
        const [],
        expectedSongHashes: const {'s': null},
        expectedSetlistHashes: const {},
        syncAccount: 'account',
        baselineCloudHashes: const {'song:s': 'cloud-hash'},
      );

      expect(result['savedSongIds'], ['s']);
      final raw = await repo.getSongRaw('s');
      expect(raw!.document, ChordProCodec().encode(incoming));
      expect(raw.hash, sha256.convert(utf8.encode(raw.document)).toString());
      final baseline = (await repo.loadSyncBaselines('account'))['song:s']!;
      expect(baseline.cloudHash, 'cloud-hash');
      expect(baseline.localHash, raw.hash);
    });

    test(
      'refuses a song with an unreadable extension before any write',
      () async {
        final opaque = SongDocument(
          id: 'opaque',
          title: 'Opaque',
          artist: 'Artist',
          body: 'body',
          extensionError: 'unsupported',
        );
        await expectLater(
          repo.applySyncChanges(
            [song('fine', 'ok'), opaque],
            const [],
            expectedSongHashes: const {'fine': null, 'opaque': null},
            expectedSetlistHashes: const {},
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'invalid_local_data',
            ),
          ),
        );
        expect(await repo.getSongHash('fine'), isNull);
      },
    );
  });

  test('setlistContentHash is the hash conditional writes compare', () async {
    await repo.saveSong(song('s', 'one'));
    final setlist = SetlistDocument(
      id: 'list',
      name: 'List',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      entries: [SetlistEntry(id: 'e0', songId: 's')],
    );
    await repo.saveSetlist(setlist);
    final stored = (await repo.getSetlist('list'))!;

    expect(
      setlistContentHash(stored),
      sha256.convert(utf8.encode(jsonEncode(stored.toJson()))).toString(),
    );
    expect(await repo.getSetlistHash('list'), setlistContentHash(stored));
    expect(
      await repo.saveSetlistIfUnchangedWithHash(
        stored,
        setlistContentHash(stored),
      ),
      setlistContentHash(stored),
    );
  });
}
