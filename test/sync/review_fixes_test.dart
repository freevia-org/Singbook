import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:singbook/sync/google_drive_sync.dart';
import 'support.dart';

/// A cloud whose first listing omits some files (a stale search index).
class _LaggyCloud extends MemoryCloud {
  _LaggyCloud(this.hidden);
  final Set<String> hidden;
  bool armed = false;

  @override
  Future<List<DriveFile>> listFiles() async {
    final all = await super.listFiles();
    if (!armed) return all;
    armed = false;
    return [
      for (final f in all)
        if (!hidden.contains(f.name)) f,
    ];
  }
}

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

  Future<void> sixSongs() async {
    for (var i = 0; i < 6; i++) {
      await a.saveSong('s$i', 'body $i');
    }
    await a.saveSetlist('l', 'Gig', ['s0', 's1', 's2']);
    await a.sync.sync();
  }

  void wipeCloud() {
    for (final name in List.of(cloud.names)) {
      cloud.remove(name);
    }
  }

  group('suspicious cloud listing', () {
    test('an emptied cloud does not delete the local library', () async {
      await sixSongs();
      wipeCloud();
      await expectLater(
        a.sync.sync(),
        throwsA(syncError('remote_listing_suspicious')),
      );
      expect(a.sync.suspiciousDeletionCount, 7);
      expect(await a.songIds(), hasLength(6));
      expect((await a.repo.getSetlist('l'))!.entries, hasLength(3));
      // Still refused until the user decides.
      await expectLater(
        a.sync.sync(),
        throwsA(syncError('remote_listing_suspicious')),
      );
    });

    test('confirming applies the deletions', () async {
      await sixSongs();
      wipeCloud();
      await expectLater(
        a.sync.sync(),
        throwsA(syncError('remote_listing_suspicious')),
      );
      a.sync.confirmRemoteDeletions();
      final r = await a.sync.sync();
      expect(r.deletedLocal, 7);
      expect(await a.songIds(), isEmpty);
    });

    test('keeping local uploads the library again', () async {
      await sixSongs();
      wipeCloud();
      await expectLater(
        a.sync.sync(),
        throwsA(syncError('remote_listing_suspicious')),
      );
      await a.sync.keepLocalAfterSuspiciousListing();
      final r = await a.sync.sync();
      expect(r.uploaded, 7);
      expect(r.deletedLocal, 0);
      expect(await a.songIds(), hasLength(6));
      expect(cloud.names, hasLength(7));
    });

    test('a few real deletions elsewhere still apply without a prompt',
        () async {
      await sixSongs();
      await b.sync.sync();
      await b.repo.deleteSong('s5');
      await b.sync.sync();
      final r = await a.sync.sync();
      expect(r.deletedLocal, 1);
    });

    test('an item missing only from a stale first listing is kept', () async {
      final laggy = _LaggyCloud({'song-s0.cho'});
      final d = await Device.create(laggy);
      addTearDown(d.close);
      await d.saveSong('s0', 'x');
      await d.saveSong('s1', 'y');
      await d.sync.sync();
      laggy.armed = true;
      final r = await d.sync.sync();
      expect(r.deletedLocal, 0);
      expect(r.pending, 1);
      expect(await d.songIds(), ['s0', 's1']);
    });
  });

  group('baselines and replace', () {
    test('uploads are remembered in small batches, not only at the end',
        () async {
      String id(int i) => 's${i.toString().padLeft(2, '0')}';
      for (var i = 0; i < 12; i++) {
        await a.saveSong(id(i), 'one $i');
      }
      await a.sync.sync();
      for (var i = 0; i < 12; i++) {
        await a.editSong(id(i), 'two $i');
      }
      final account = syncHash('person-a');
      String? seen;
      var updates = 0;
      cloud.hook = (op, target) async {
        if (op != 'update' || ++updates != 11) return;
        final baselines = await a.repo.loadSyncBaselines(account);
        seen = baselines['song:s00']?.cloudHash;
        throw const SyncException('network'); // like a kill after 10 uploads
      };
      await expectLater(a.sync.sync(), throwsA(syncError('network')));
      cloud.hook = null;
      expect(seen, isNotNull);
      expect(seen, syncHash(cloud.body('song-s00.cho')!));
    });

    test('a replace that waits does not delete songs created afterwards',
        () async {
      await b.saveSong('theirs', 'cloud song');
      await b.sync.sync();
      await a.saveSong('old', 'local only');
      await a.sync.sync();
      cloud.remove('song-old.cho');
      a.auth.id = 'person-c';
      await a.sync.adoptAccount(mergeLocal: false);
      await a.saveSong('fresh', 'created after the decision');
      final r = await a.sync.sync();
      expect(await a.body('old'), isNull, reason: 'part of the replace');
      expect(await a.body('fresh'), 'created after the decision');
      expect(await a.body('theirs'), 'cloud song');
      expect(cloud.has('song-fresh.cho'), isTrue);
      expect(r.deletedLocal, 1);
    });

    test('adopting without an account change is refused', () async {
      await a.saveSong('s', 'x');
      await a.sync.sync();
      await expectLater(
        a.sync.adoptAccount(mergeLocal: false),
        throwsA(syncError('no_account_change')),
      );
      expect((await a.sync.sync()).isNoop, isTrue);
      expect(await a.songIds(), ['s']);
    });
  });

  group('duplicates', () {
    test('a duplicate without a hash is left alone, not deleted', () async {
      await b.saveSong('d', 'real');
      final raw = (await b.repo.getSongRaw('d'))!;
      cloud.putDuplicate('song-d.cho', 'junk', properties: {'kind': 'song'});
      cloud.putDuplicate('song-d.cho', raw.document); // newest: the real one
      final r = await a.sync.sync();
      expect(r.downloaded, 1);
      expect(await a.body('d'), 'real');
      expect(cloud.files.where((f) => f.name == 'song-d.cho'), hasLength(2));
    });
  });

  group('authorization failures', () {
    test('only a lapsed grant needs the user, everything else retries', () {
      String code(Object e) => GoogleDriveAuth.mapAuthorizationFailure(e).code;
      expect(code(Exception('offline')), 'network');
      expect(
        code(const GoogleSignInException(code: GoogleSignInExceptionCode.interrupted)),
        'network',
      );
      expect(
        code(const GoogleSignInException(code: GoogleSignInExceptionCode.unknownError)),
        'network',
      );
      expect(
        code(const GoogleSignInException(code: GoogleSignInExceptionCode.userMismatch)),
        'authorization_required',
      );
      expect(
        code(const GoogleSignInException(code: GoogleSignInExceptionCode.uiUnavailable)),
        'authorization_required',
      );
    });
  });
}
