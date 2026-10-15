import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/sync/google_drive_sync.dart';
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

  group('setlists and songs', () {
    test('a deleted song leaves the setlist on every device without it',
        () async {
      await a.saveSong('s1', 'one');
      await a.saveSong('s2', 'two');
      await a.saveSetlist('l', 'Gig', ['s1', 's2']);
      await a.sync.sync();
      await b.sync.sync();
      await a.repo.deleteSong('s2');
      final r = await a.sync.sync();
      expect(r.deletedRemote, 1);
      expect(r.uploaded, 1, reason: 'the shortened setlist');
      await b.sync.sync();
      expect(await b.songIds(), ['s1']);
      expect((await b.repo.getSetlist('l'))!.entries.map((e) => e.songId), [
        's1',
      ]);
      for (final d in [a, b]) {
        expect((await d.sync.sync()).isNoop, isTrue);
      }
    });

    test('a remote song deletion that B has not seen does not shrink a '
        'setlist B changed meanwhile without a conflict copy of the song',
        () async {
      await a.saveSong('s1', 'one');
      await a.saveSong('s2', 'two');
      await a.saveSetlist('l', 'Gig', ['s1', 's2']);
      await a.sync.sync();
      await b.sync.sync();
      await a.repo.deleteSong('s2');
      await a.sync.sync();
      await b.saveSetlist('l', 'Gig B', ['s1', 's2']);
      final r = await b.sync.sync();
      expect(r.conflicts, 1);
      expect(await b.songIds(), ['s1']);
      // Both versions of the setlist exist; none references a missing song.
      for (final set in await b.repo.listSetlists()) {
        for (final e in set.entries) {
          expect(await b.repo.getSong(e.songId), isNotNull);
        }
      }
    });

    test('a setlist whose songs are not local yet is pulled after them',
        () async {
      for (var i = 0; i < 4; i++) {
        await a.saveSong('s$i', 'song $i');
      }
      await a.saveSetlist('l', 'All', ['s3', 's2', 's1', 's0']);
      await a.sync.sync();
      final r = await b.sync.sync();
      expect(r.pending, 0);
      expect((await b.repo.getSetlist('l'))!.entries, hasLength(4));
    });

    test('a setlist pointing at a song that does not exist stays pending',
        () async {
      cloud.put(
        'setlist-ghost.json',
        jsonEncode({
          'id': 'ghost',
          'name': 'Ghost',
          'notes': '',
          'favorite': false,
          'entries': [
            {'id': 'e1', 'songId': 'nowhere', 'overrides': {}},
          ],
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
      );
      final r = await b.sync.sync();
      expect(r.pending, 1);
      expect(await b.repo.listSetlists(), isEmpty);
      expect(cloud.has('setlist-ghost.json'), isTrue, reason: 'never deleted');
    });
  });

  group('accounts', () {
    test('signing in with another account stops with account_changed',
        () async {
      await a.saveSong('s', 'mine');
      await a.sync.sync();
      a.auth.id = 'person-b';
      expect(await a.sync.hasAccountMismatch(), isTrue);
      expect(await a.sync.previousAccountEmail(), 'person-a@example.test');
      cloud.resetCounters();
      await expectLater(a.sync.sync(), throwsA(syncError('account_changed')));
      expect(cloud.requests, 0, reason: 'nothing is read or written');
      expect(await a.songIds(), ['s']);
    });

    test('adopting with merge uploads the local library to the new account',
        () async {
      await a.saveSong('s', 'mine');
      await a.sync.sync();
      final other = MemoryCloud()..put('song-t.cho', 'x'); // unused foreign
      expect(other.names, isNotEmpty);
      a.auth.id = 'person-b';
      await a.sync.adoptAccount(mergeLocal: true);
      expect(await a.sync.hasAccountMismatch(), isFalse);
      // The fake cloud is shared, so person-b "has" the same files: the
      // library is linked, not duplicated.
      final r = await a.sync.sync();
      expect(r.conflicts, 0);
      expect(await a.songIds(), ['s']);
      expect(cloud.names, ['song-s.cho']);
    });

    test('adopting without merge makes the account library replace the local one',
        () async {
      await b.saveSong('theirs', 'cloud song');
      await b.sync.sync();
      await a.saveSong('mine', 'local only');
      await a.saveSong('theirs', 'edited locally');
      await a.sync.sync(); // links up: 'mine' uploaded, 'theirs' conflicts
      cloud.remove('song-mine.cho');
      a.auth.id = 'person-c';
      await a.sync.adoptAccount(mergeLocal: false);
      final r = await a.sync.sync();
      expect(r.deletedLocal, greaterThan(0));
      expect(await a.body('theirs'), 'cloud song');
      expect(await a.body('mine'), isNull);
      expect((await a.sync.sync()).isNoop, isTrue);
    });

    test('signing out keeps the local library and the baseline', () async {
      await a.saveSong('s', 'mine');
      await a.sync.sync();
      await a.sync.disconnect();
      expect(await a.songIds(), ['s']);
      await expectLater(a.sync.sync(), throwsA(syncError('not_signed_in')));
      await a.sync.connect();
      expect((await a.sync.sync()).isNoop, isTrue);
    });

    test('the account changing in the middle of a sync aborts it', () async {
      await a.saveSong('s1', 'one');
      await a.saveSong('s2', 'two');
      cloud.hook = (op, target) {
        if (op == 'create') a.auth.id = 'person-z';
      };
      await expectLater(a.sync.sync(), throwsA(syncError('account_changed')));
      cloud.hook = null;
      expect(cloud.creates, 1);
    });
  });

  group('devices that were away', () {
    test('B returns after many changes on A and converges', () async {
      for (var i = 0; i < 30; i++) {
        await a.saveSong('s$i', 'v1 $i');
      }
      await a.saveSetlist('l', 'L', ['s0', 's1']);
      await a.sync.sync();
      await b.sync.sync();
      // B stays offline while A edits, deletes and adds.
      for (var i = 0; i < 10; i++) {
        await a.editSong('s$i', 'v2 $i');
      }
      for (var i = 10; i < 15; i++) {
        await a.repo.deleteSong('s$i');
      }
      for (var i = 30; i < 40; i++) {
        await a.saveSong('s$i', 'new $i');
      }
      await a.sync.sync();
      // ...and B made its own changes meanwhile.
      await b.editSong('s20', 'b edit');
      await b.editSong('s3', 'b edit of an item A also changed');
      await b.repo.deleteSong('s25');
      await b.saveSong('b-new', 'only on b');
      await b.sync.sync();
      await a.sync.sync();
      await b.sync.sync();
      expect(await a.songIds(), await b.songIds());
      expect(await b.body('s5'), 'v2 5');
      expect(await b.body('s10'), isNull);
      expect(await b.body('s20'), 'b edit');
      expect(await b.body('s25'), isNull);
      expect(await b.body('s3'), 'v2 3', reason: 'cloud wins at the id');
      expect(await b.bodies(), contains('b edit of an item A also changed'));
      expect(await a.bodies(), await b.bodies());
      for (final d in [a, b]) {
        expect((await d.sync.sync()).isNoop, isTrue);
      }
    });
  });

  group('duplicate names (a race on create)', () {
    test('the newest file wins; an old copy of known content is removed',
        () async {
      await a.saveSong('s', 'one');
      await a.sync.sync();
      final loser = cloud.idOf('song-s.cho')!;
      cloud.putDuplicate('song-s.cho', cloud.body('song-s.cho')!);
      final r = await b.sync.sync();
      expect(await b.songIds(), ['s']);
      expect(r.conflicts, 0);
      expect(cloud.files.where((f) => f.name == 'song-s.cho'), hasLength(1));
      expect(cloud.files.any((f) => f.id == loser), isFalse,
          reason: 'the older of two identical files is dropped');
    });

    test('an older duplicate with unknown content is kept as a conflict copy',
        () async {
      await a.saveSong('s', 'v1');
      await a.sync.sync();
      // Two other devices created the file at the same moment (same name).
      await b.saveSong('s', 'from b');
      final bodyB = (await b.repo.getSongRaw('s'))!.document;
      await b.editSong('s', 'from c');
      final bodyC = (await b.repo.getSongRaw('s'))!.document;
      cloud.put('song-s.cho', bodyB);
      cloud.putDuplicate('song-s.cho', bodyC); // the newer one
      final r = await a.sync.sync();
      expect(r.conflicts, 1);
      expect(await a.body('s'), 'from c');
      expect(await a.bodies(), containsAll(['from b', 'from c']));
      expect(await a.songIds(), hasLength(2));
      expect(cloud.files.where((f) => f.name == 'song-s.cho'), hasLength(1));
      await a.sync.sync();
      expect((await a.sync.sync()).isNoop, isTrue);
      expect(await a.songIds(), hasLength(2));
    });
  });

  group('hostile or broken cloud data', () {
    test('an oversize remote file is skipped, the rest still syncs', () async {
      await a.saveSong('big', 'x');
      await a.saveSong('ok', 'fine');
      await a.sync.sync();
      cloud.sizes[cloud.idOf('song-big.cho')!] = maxSyncFileBytes + 1;
      final r = await b.sync.sync();
      expect(r.skipped, 1);
      expect(r.skipCodes, ['remote_file_too_large']);
      expect(await b.songIds(), ['ok']);
      expect(cloud.reads, lessThanOrEqualTo(2));
      // Not deleted anywhere and retried next time.
      expect(cloud.has('song-big.cho'), isTrue);
      cloud.sizes.clear();
      final again = await b.sync.sync();
      expect(again.skipped, 0);
      expect(await b.songIds(), ['big', 'ok']);
    });

    test('a tampered body never reaches the library', () async {
      await a.saveSong('s', 'real');
      await a.sync.sync();
      final file = cloud.files.single;
      cloud.put(
        'song-s.cho',
        'tampered',
        properties: {...file.properties}, // hash property no longer matches
      );
      final r = await b.sync.sync();
      expect(r.skipCodes, ['invalid_remote_data']);
      expect(await b.songIds(), isEmpty);
    });

    test('a body for the wrong id is rejected', () async {
      await a.saveSong('s', 'real');
      await a.sync.sync();
      final body = cloud.body('song-s.cho')!;
      cloud.put('song-other.cho', body);
      final r = await b.sync.sync();
      expect(r.skipCodes, ['invalid_remote_data']);
      expect(await b.songIds(), ['s']);
    });

    test('files that are not ours, or have unsafe names, are ignored', () async {
      cloud.put('notes.txt', 'hello', properties: {'hash': syncHash('hello')});
      cloud.put('song-../evil.cho', 'x');
      cloud.put('song-a b.cho', 'x');
      cloud.put('setlist-x.cho', 'x');
      cloud.put('song-~!!!.cho', 'x');
      final r = await b.sync.sync();
      expect(r.isNoop, isTrue);
      expect(r.skipped, 0);
      expect(cloud.deletes, 0);
    });

    test('a cloud file with a broken hash property is skipped, not trusted',
        () async {
      cloud.put('song-s.cho', 'x', properties: {'kind': 'song', 'hash': 'nope'});
      final r = await b.sync.sync();
      expect(r.skipCodes, ['invalid_remote_data']);
      expect(await b.songIds(), isEmpty);
    });

    test('item limits stop the sync with a clear error before any change',
        () async {
      for (var i = 0; i < 5; i++) {
        await a.saveSong('s$i', 'x');
      }
      await a.sync.sync();
      final small = await Device.create(cloud, maxItems: 3);
      addTearDown(small.close);
      await expectLater(
        small.sync.sync(),
        throwsA(syncError('remote_library_too_large')),
      );
      expect(await small.songIds(), isEmpty);
      final tiny = await Device.create(MemoryCloud(), maxItems: 2);
      addTearDown(tiny.close);
      for (var i = 0; i < 3; i++) {
        await tiny.saveSong('t$i', 'x');
      }
      await expectLater(
        tiny.sync.sync(),
        throwsA(syncError('library_too_large')),
      );
    });

    test('ids that need encoding survive the round trip', () async {
      await a.saveSong('weird id/ü?', 'odd');
      await a.sync.sync();
      expect(cloud.names.single, startsWith('song-~'));
      await b.sync.sync();
      expect(await b.body('weird id/ü?'), 'odd');
      expect((await b.sync.sync()).isNoop, isTrue);
    });
  });

  group('failures', () {
    test('an interrupted sync keeps what it did and the next one converges',
        () async {
      for (var i = 0; i < 6; i++) {
        await a.saveSong('s$i', 'body $i');
      }
      var creates = 0;
      cloud.hook = (op, target) {
        if (op == 'create' && ++creates == 4) {
          throw const SyncException('network');
        }
      };
      await expectLater(a.sync.sync(), throwsA(syncError('network')));
      cloud.hook = null;
      final done = cloud.creates - 1; // the failed attempt created nothing
      expect(cloud.names, hasLength(done));
      cloud.resetCounters();
      final r = await a.sync.sync();
      expect(cloud.creates, 6 - done, reason: 'only what is still missing');
      expect(r.uploaded, 6 - done);
      expect(cloud.names, hasLength(6));
      await b.sync.sync();
      expect(await b.songIds(), await a.songIds());
      expect((await a.sync.sync()).isNoop, isTrue);
    });

    test('a crash after uploading but before remembering it is harmless',
        () async {
      await a.saveSong('s', 'one');
      await a.sync.sync();
      // Simulate losing the baseline row (as if the process died before it
      // was written): the cloud and local content are equal, so it re-links.
      await a.repo.clearSyncBaselines();
      cloud.resetCounters();
      final r = await a.sync.sync();
      expect(r.isNoop, isTrue);
      expect(cloud.writes + cloud.reads, 0);
    });

    test('a pull failing in the middle leaves the library consistent',
        () async {
      for (var i = 0; i < 5; i++) {
        await a.saveSong('s$i', 'body $i');
      }
      await a.saveSetlist('l', 'L', ['s0', 's4']);
      await a.sync.sync();
      var reads = 0;
      cloud.hook = (op, target) {
        if (op == 'read' && ++reads == 3) throw const SyncException('network');
      };
      await expectLater(b.sync.sync(), throwsA(syncError('network')));
      cloud.hook = null;
      for (final set in await b.repo.listSetlists()) {
        for (final e in set.entries) {
          expect(await b.repo.getSong(e.songId), isNotNull);
        }
      }
      await b.sync.sync();
      expect(await b.songIds(), await a.songIds());
      expect(await b.repo.listSetlists(), hasLength(1));
      expect((await b.sync.sync()).isNoop, isTrue);
    });

    test('a file replaced between listing and download is decided again',
        () async {
      await a.saveSong('s', 'v1');
      await a.sync.sync();
      var swapped = false;
      cloud.hook = (op, target) {
        if (op == 'read' && !swapped) {
          swapped = true;
          final text = cloud.body('song-s.cho')!.replaceAll('v1', 'v2');
          cloud.put('song-s.cho', text);
        }
      };
      final r = await b.sync.sync();
      cloud.hook = null;
      expect(r.skipped, 0);
      expect(await b.body('s'), 'v2');
    });

    test('a file deleted between listing and download is skipped quietly',
        () async {
      await a.saveSong('s', 'v1');
      await a.sync.sync();
      cloud.hook = (op, target) {
        if (op == 'read') cloud.remove('song-s.cho');
      };
      final r = await b.sync.sync();
      cloud.hook = null;
      expect(r.skipped, 0);
      expect(await b.songIds(), isEmpty);
    });

    test('cancelling stops at an item boundary and loses nothing', () async {
      for (var i = 0; i < 6; i++) {
        await a.saveSong('s$i', 'body $i');
      }
      cloud.hook = (op, target) {
        if (op == 'create') a.sync.cancel();
      };
      await expectLater(a.sync.sync(), throwsA(syncError('cancelled')));
      cloud.hook = null;
      await a.sync.sync();
      expect(cloud.names, hasLength(6));
    });

    test('only one sync runs at a time', () async {
      await a.saveSong('s', 'x');
      final first = a.sync.sync();
      await expectLater(a.sync.sync(), throwsA(syncError('sync_in_progress')));
      await first;
    });

    test('errors from the store reach the caller with their code', () async {
      for (final code in [
        'authorization_required',
        'access_denied',
        'rate_limited',
        'storage_full',
        'network',
      ]) {
        cloud.hook = (op, target) => throw SyncException(code);
        await expectLater(a.sync.sync(), throwsA(syncError(code)));
      }
      cloud.hook = null;
      expect(a.sync.isBusy, isFalse);
    });
  });

  group('scale', () {
    test('3000 songs: one listing per sync, one write per changed item',
        () async {
      final big = await Device.create(cloud, concurrency: 4);
      addTearDown(big.close);
      await big.repo.importCollection([
        for (var i = 0; i < 3000; i++)
          SongDocument(
            id: 'song-$i',
            title: 'Song $i',
            artist: 'Artist',
            body: 'lyrics $i',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
      ], const []);
      final watch = Stopwatch()..start();
      cloud.resetCounters();
      final up = await big.sync.sync();
      // ignore: avoid_print
      print('push 3000: ${watch.elapsedMilliseconds} ms');
      watch.reset();
      expect(up.uploaded, 3000);
      expect(cloud.lists, 1);
      expect(cloud.creates, 3000);
      expect(cloud.reads, 0);

      cloud.resetCounters();
      expect((await big.sync.sync()).isNoop, isTrue);
      expect(cloud.requests, 1, reason: 'an unchanged library costs a listing');

      await big.editSong('song-7', 'changed');
      cloud.resetCounters();
      await big.sync.sync();
      expect(cloud.lists, 1);
      expect(cloud.gets, 1);
      expect(cloud.updates, 1);
      expect(cloud.requests, 3);

      final other = await Device.create(cloud, concurrency: 4);
      addTearDown(other.close);
      cloud.resetCounters();
      watch.reset();
      final down = await other.sync.sync();
      // ignore: avoid_print
      print('pull 3000: ${watch.elapsedMilliseconds} ms');
      expect(down.downloaded, 3000);
      expect(cloud.reads, 3000);
      expect(cloud.lists, 1);
      cloud.resetCounters();
      expect((await other.sync.sync()).isNoop, isTrue);
      expect(cloud.requests, 1);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
