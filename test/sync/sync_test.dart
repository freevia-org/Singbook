import 'package:flutter_test/flutter_test.dart';
import 'package:verse_mobile/sync/google_drive_sync.dart';
import 'support.dart';

void main() {
  late MemoryCloud cloud;
  late Device a, b;

  setUp(() async {
    cloud = MemoryCloud();
    a = await Device.create(cloud);
    b = await Device.create(cloud);
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  group('first sync', () {
    test('everything on A reaches an empty B, songs before setlists', () async {
      await a.saveSong('s1', 'one');
      await a.saveSong('s2', 'two');
      await a.saveSetlist('l1', 'Gig', ['s1', 's2', 's1']);
      final sent = await a.sync.sync();
      expect(sent.uploaded, 3);
      expect(cloud.names, ['setlist-l1.json', 'song-s1.cho', 'song-s2.cho']);
      final file = cloud.files.firstWhere((f) => f.name == 'song-s1.cho');
      expect(file.properties['kind'], 'song');
      expect(file.properties['verseSchema'], syncSchema);
      expect(file.properties['hash'], syncHash(cloud.body('song-s1.cho')!));

      final got = await b.sync.sync();
      expect(got.downloaded, 3);
      expect(await b.body('s1'), 'one');
      expect((await b.repo.getSetlist('l1'))!.entries.map((e) => e.songId), [
        's1',
        's2',
        's1',
      ]);
      expect(await b.repo.database.query('outbox'), isEmpty);
    });

    test('both libraries differ: after one round trip both have everything',
        () async {
      await a.saveSong('x', 'from a');
      await b.saveSong('y', 'from b');
      await a.sync.sync();
      await b.sync.sync();
      await a.sync.sync();
      expect(await a.songIds(), ['x', 'y']);
      expect(await b.songIds(), ['x', 'y']);
    });

    test('same song on both sides with the same content just links up',
        () async {
      await a.saveSong('s', 'same');
      await a.sync.sync();
      await b.saveSong('s', 'same');
      final r = await b.sync.sync();
      expect(r.isNoop, isTrue);
      expect(await b.songIds(), ['s']);
      expect(cloud.writes, 1);
    });

    test('a second sync is a no-op: one listing, no reads, no writes', () async {
      for (var i = 0; i < 5; i++) {
        await a.saveSong('s$i', 'body $i');
      }
      await a.saveSetlist('l', 'L', ['s0']);
      await a.sync.sync();
      await b.sync.sync();
      for (final d in [a, b]) {
        cloud.resetCounters();
        final r = await d.sync.sync();
        expect(r.isNoop, isTrue);
        expect(cloud.lists, 1);
        expect(cloud.reads + cloud.gets + cloud.writes, 0);
      }
    });
  });

  group('edits and deletes', () {
    setUp(() async {
      await a.saveSong('s', 'v1');
      await a.sync.sync();
      await b.sync.sync();
    });

    test('an edit on A is pulled by B and updates the file in place', () async {
      final id = cloud.idOf('song-s.cho');
      await a.editSong('s', 'v2');
      final sent = await a.sync.sync();
      expect(sent.uploaded, 1);
      expect(cloud.idOf('song-s.cho'), id, reason: 'same file, no new one');
      expect(cloud.creates, 1);
      final got = await b.sync.sync();
      expect(got.downloaded, 1);
      expect(await b.body('s'), 'v2');
      expect((await b.sync.sync()).isNoop, isTrue);
    });

    test('a delete on A deletes on B and removes the cloud file', () async {
      await a.repo.deleteSong('s');
      final sent = await a.sync.sync();
      expect(sent.deletedRemote, 1);
      expect(cloud.names, isEmpty);
      final got = await b.sync.sync();
      expect(got.deletedLocal, 1);
      expect(await b.songIds(), isEmpty);
      for (final d in [a, b]) {
        expect((await d.sync.sync()).isNoop, isTrue);
      }
      expect(await a.songIds(), isEmpty);
    });

    test('deleting on A then editing on B: the edit survives everywhere',
        () async {
      await a.repo.deleteSong('s');
      await a.sync.sync();
      await b.editSong('s', 'still wanted');
      final r = await b.sync.sync();
      expect(r.uploaded, 1, reason: 'the edited song is uploaded again');
      await a.sync.sync();
      expect(await a.body('s'), 'still wanted');
      expect(await b.body('s'), 'still wanted');
      expect(cloud.names, ['song-s.cho']);
    });

    test('editing on B and syncing, then deleting on A: A keeps the edit',
        () async {
      await b.editSong('s', 'edited on b');
      await b.sync.sync();
      await a.repo.deleteSong('s');
      final r = await a.sync.sync();
      expect(r.deletedRemote, 0, reason: 'the newer cloud version is kept');
      expect(await a.body('s'), 'edited on b');
      expect(cloud.has('song-s.cho'), isTrue);
      expect((await b.sync.sync()).isNoop, isTrue);
    });

    test('deleted on both sides ends quietly', () async {
      await a.repo.deleteSong('s');
      await b.repo.deleteSong('s');
      await a.sync.sync();
      final r = await b.sync.sync();
      expect(r.isNoop, isTrue);
      expect(cloud.names, isEmpty);
      expect((await b.sync.sync()).isNoop, isTrue);
    });

    test('both sides edit to identical content without a conflict', () async {
      await a.editSong('s', 'same edit');
      await b.editSong('s', 'same edit');
      await a.sync.sync();
      final r = await b.sync.sync();
      expect(r.conflicts, 0);
      expect(await b.songIds(), ['s']);
    });
  });

  group('conflicts', () {
    setUp(() async {
      await a.saveSong('s', 'base');
      await a.sync.sync();
      await b.sync.sync();
      await a.editSong('s', 'edit A');
      await b.editSong('s', 'edit B');
      await a.sync.sync();
    });

    test('cloud wins at the original id, the local edit becomes a copy',
        () async {
      final r = await b.sync.sync();
      expect(r.conflicts, 1);
      expect(await b.body('s'), 'edit A');
      expect(await b.bodies(), {'edit A', 'edit B'});
      expect(await b.songIds(), hasLength(2));
      // The copy was uploaded, so A receives it too.
      await a.sync.sync();
      expect(await a.bodies(), {'edit A', 'edit B'});
    });

    test('repeated syncs never make another copy', () async {
      await b.sync.sync();
      await a.sync.sync();
      for (var i = 0; i < 3; i++) {
        expect((await b.sync.sync()).isNoop, isTrue);
        expect((await a.sync.sync()).isNoop, isTrue);
      }
      expect(await a.songIds(), hasLength(2));
      expect(await b.songIds(), hasLength(2));
      expect(cloud.names, hasLength(2));
    });

    test('a dismissed copy stays dismissed on every device', () async {
      await b.sync.sync();
      await a.sync.sync();
      final copyId = (await b.songIds()).firstWhere((id) => id != 's');
      await b.repo.deleteSong(copyId);
      await b.sync.sync();
      await a.sync.sync();
      await b.sync.sync();
      expect(await a.songIds(), ['s']);
      expect(await b.songIds(), ['s']);
      expect(cloud.names, ['song-s.cho']);
    });

    test('concurrent setlist edits keep both versions', () async {
      await a.saveSong('t', 't');
      await a.saveSetlist('l', 'Set', ['s']);
      await a.sync.sync();
      await b.sync.sync();
      await a.saveSetlist('l', 'Set A', ['s', 't']);
      await b.saveSetlist('l', 'Set B', ['s']);
      await a.sync.sync();
      final r = await b.sync.sync();
      expect(r.conflicts, 1);
      final names = [for (final s in await b.repo.listSetlists()) s.name];
      expect(names, hasLength(2));
      expect(names, contains('Set A'));
      expect(names.where((n) => n.startsWith('Set B [')), hasLength(1));
      await a.sync.sync();
      expect(await a.repo.listSetlists(), hasLength(2));
      expect((await a.sync.sync()).isNoop, isTrue);
    });

    test('a push racing another device is decided again, nothing is lost',
        () async {
      // B edits again after the conflict was settled; while B uploads, A
      // changes the same file. Drive has no If-Match, so B re-reads the
      // metadata right before writing and sees the change.
      await b.sync.sync();
      await a.sync.sync();
      await b.editSong('s', 'B again');
      var raced = false;
      cloud.hook = (op, target) {
        if (op == 'get' && !raced) {
          raced = true;
          cloud.put('song-s.cho', cloud.body('song-s.cho')!.replaceAll('edit A', 'A again'));
        }
      };
      final r = await b.sync.sync();
      cloud.hook = null;
      expect(r.conflicts, 1);
      expect(await b.body('s'), 'A again');
      expect(await b.bodies(), containsAll(['A again', 'B again']));
      expect(cloud.body('song-s.cho'), contains('A again'));
    });
  });
}
