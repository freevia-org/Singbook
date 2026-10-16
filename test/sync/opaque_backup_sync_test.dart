import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';
import 'package:singbook/sync/google_drive_sync.dart';

import 'support.dart';

void main() {
  late MemoryCloud cloud;
  late Device device;

  setUp(() async {
    cloud = MemoryCloud();
    device = await Device.create(cloud);
  });

  tearDown(() async {
    await device.close();
  });

  SongDocument opaqueSong(String id) {
    final track = parseLrc(
      '[00:01]Timed lyric',
      sourceDocumentId: 'lrc-source',
    );
    return SongDocument(
      id: id,
      title: 'Future song',
      artist: 'Band',
      body: 'Timed lyric',
      metadata: {'album': 'Album', 'tempo': 94},
      timingTracks: [track],
      extra: {
        'custom': {'kept': true},
      },
      selectedRecording: const SongCandidate(
        providerId: 'catalog',
        id: 'recording-1',
        title: 'Future song',
        artist: 'Band',
      ),
      activeTimingTrackId: track.id,
      favorite: true,
      preservedExtensions: ['{x_verse: future unsupported data}'],
      extensionError: 'Unsupported x_verse extension',
    );
  }

  Future<List<Map<String, Object?>>> outboxRows() =>
      device.repo.database.query('outbox', orderBy: 'rowid');

  Future<void> corruptSidecar(String id, {bool changeLocalHash = true}) async {
    await device.repo.database.update(
      'songs',
      {
        'full_document': '{"id":"forged"}',
        'full_document_hash': List.filled(64, '0').join(),
        if (changeLocalHash)
          // Ensure an unsafe planner would regard this as a local edit.
          'content_hash': List.filled(64, 'f').join(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  test(
    'backup preserves opaque song state and repeated setlist references',
    () async {
      final opaque = opaqueSong('opaque-song');
      final setlist = SetlistDocument(
        id: 'opaque-setlist',
        name: 'Repeat',
        entries: const [
          SetlistEntry(
            id: 'first',
            songId: 'opaque-song',
            overrides: {'capo': 2, 'key': 'D'},
          ),
          SetlistEntry(
            id: 'again',
            songId: 'opaque-song',
            overrides: {'capo': 0},
          ),
        ],
      );

      await device.repo.saveSong(opaque);
      await device.repo.saveSetlist(setlist);
      final snapshot = await device.repo.backupSnapshot();
      final package = encodeLibraryPackage(
        snapshot.songs,
        snapshot.setlists,
        preferences: {'themeMode': 'dark'},
      );
      final decoded = decodeLibraryPackage(package);
      expect(decoded.schemaVersion, 3);
      expect(decoded.songs.single.toJson(), opaque.toJson());
      expect(decoded.setlists.single.toJson(), setlist.toJson());

      await device.repo.replaceLibrary(decoded.songs, decoded.setlists);
      expect((await device.repo.getSong(opaque.id))!.toJson(), opaque.toJson());
      final restoredSetlist = (await device.repo.getSetlist(setlist.id))!;
      expect(restoredSetlist.entries.map((entry) => entry.id), [
        'first',
        'again',
      ]);
      expect(restoredSetlist.entries.map((entry) => entry.songId), [
        'opaque-song',
        'opaque-song',
      ]);
      expect(restoredSetlist.entries.first.overrides, {'capo': 2, 'key': 'D'});
    },
  );

  test(
    'opaque sidecar blocks upload and reconciliation without acknowledging',
    () async {
      final opaque = opaqueSong('opaque-sync');
      await device.repo.saveSong(opaque);
      final outboxBefore = await outboxRows();
      final remote = ChordProCodec().encode(
        SongDocument(
          id: opaque.id,
          title: 'Older cloud copy',
          artist: 'Band',
          body: 'Cloud lyric',
        ),
      );
      cloud.put('song-${opaque.id}.cho', remote);
      cloud.resetCounters();

      await expectLater(
        device.sync.sync(),
        throwsA(
          isA<SyncException>().having(
            (error) => error.code,
            'code',
            'invalid_local_data',
          ),
        ),
      );
      expect(cloud.body('song-${opaque.id}.cho'), remote);
      expect(cloud.writes, 0);
      expect((await device.repo.getSong(opaque.id))!.toJson(), opaque.toJson());
      expect(await outboxRows(), outboxBefore);
    },
  );

  test('invalid sidecar blocks pulling a changed cloud song', () async {
    final local = SongDocument(
      id: 'remote-updated',
      title: 'Song',
      artist: 'Band',
      body: 'Local lyric',
    );
    await device.repo.saveSong(local);
    await device.sync.sync();
    final remote = ChordProCodec().encode(local.copyWith(body: 'Cloud lyric'));
    cloud.put('song-${local.id}.cho', remote);
    await corruptSidecar(local.id);
    final before = await outboxRows();
    cloud.resetCounters();

    await expectLater(
      device.sync.sync(),
      throwsA(
        isA<SyncException>().having(
          (error) => error.code,
          'code',
          'invalid_local_data',
        ),
      ),
    );
    expect(cloud.body('song-${local.id}.cho'), remote);
    expect(cloud.writes, 0);
    expect(
      (await device.repo.database.query(
        'songs',
        columns: ['document'],
        where: 'id = ?',
        whereArgs: [local.id],
      )).single['document'],
      isNot(remote),
    );
    expect(await outboxRows(), before);
  });

  test(
    'pull CAS rechecks sidecar damage that occurs after preflight',
    () async {
      final local = SongDocument(
        id: 'pull-race',
        title: 'Song',
        artist: 'Band',
        body: 'Local lyric',
      );
      await device.repo.saveSong(local);
      await device.sync.sync();
      final remote = ChordProCodec().encode(
        local.copyWith(body: 'Cloud lyric'),
      );
      cloud.put('song-${local.id}.cho', remote);
      var corruptedAfterSnapshot = false;
      cloud.hook = (op, _) async {
        if (op == 'read' && !corruptedAfterSnapshot) {
          await corruptSidecar(local.id, changeLocalHash: false);
          corruptedAfterSnapshot = true;
        }
      };
      final before = await outboxRows();
      cloud.resetCounters();

      await expectLater(
        device.sync.sync(),
        throwsA(
          isA<SyncException>().having(
            (error) => error.code,
            'code',
            'invalid_local_data',
          ),
        ),
      );
      cloud.hook = null;
      expect(corruptedAfterSnapshot, isTrue);
      expect(cloud.body('song-${local.id}.cho'), remote);
      expect(cloud.writes, 0);
      expect(
        (await device.repo.database.query(
          'songs',
          columns: ['document'],
          where: 'id = ?',
          whereArgs: [local.id],
        )).single['document'],
        isNot(remote),
      );
      expect(await outboxRows(), before);
    },
  );

  test(
    'invalid sidecar blocks local deletion after confirmed cloud absence',
    () async {
      final local = SongDocument(
        id: 'remote-missing',
        title: 'Song',
        artist: 'Band',
        body: 'Local lyric',
      );
      await device.repo.saveSong(local);
      await device.sync.sync();
      cloud.remove('song-${local.id}.cho');
      var listCalls = 0;
      var corruptedAfterSnapshot = false;
      cloud.hook = (op, _) async {
        if (op == 'list' && ++listCalls == 2) {
          // The library hash stays unchanged; only the opaque sidecar is
          // damaged after preflight and before the transactional delete guard.
          await corruptSidecar(local.id, changeLocalHash: false);
          corruptedAfterSnapshot = true;
        }
      };
      final before = await outboxRows();

      await expectLater(
        device.sync.sync(),
        throwsA(
          isA<SyncException>().having(
            (error) => error.code,
            'code',
            'invalid_local_data',
          ),
        ),
      );
      cloud.hook = null;
      expect(corruptedAfterSnapshot, isTrue);
      expect(
        await device.repo.database.query(
          'songs',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [local.id],
        ),
        hasLength(1),
      );
      expect(cloud.deletes, 0);
      expect(await outboxRows(), before);
    },
  );

  test(
    'normal raw ChordPro hash mismatch fails before sync mutation',
    () async {
      final local = SongDocument(
        id: 'raw-hash',
        title: 'Song',
        artist: 'Band',
        body: 'Local lyric',
      );
      await device.repo.saveSong(local);
      await device.sync.sync();
      await device.repo.database.update(
        'songs',
        {'content_hash': List.filled(64, '0').join()},
        where: 'id = ?',
        whereArgs: [local.id],
      );
      final remote = cloud.body('song-${local.id}.cho');
      cloud.resetCounters();

      await expectLater(
        device.sync.sync(),
        throwsA(
          isA<SyncException>().having(
            (error) => error.code,
            'code',
            'invalid_local_data',
          ),
        ),
      );
      expect(cloud.body('song-${local.id}.cho'), remote);
      expect(cloud.writes, 0);
    },
  );
}
