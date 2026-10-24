import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/sync/google_drive_sync.dart';
import 'support.dart';

void main() {
  late MemoryCloud googleCloud;
  late MemoryCloud icloudCloud;
  late Device device;
  late FakeAuth icloudAuth;
  late GoogleDriveSyncService icloudSync;

  setUp(() async {
    googleCloud = MemoryCloud();
    icloudCloud = MemoryCloud();
    device = await Device.create(googleCloud, account: 'google-a');
    icloudAuth = FakeAuth()..id = 'icloud-a';
    await icloudAuth.connect();
    icloudSync = GoogleDriveSyncService(
      repository: device.repo,
      auth: icloudAuth,
      store: icloudCloud,
      settingsNamespace: 'sync.icloud',
      clock: () => DateTime.utc(2026, 3, 1),
    );
  });

  tearDown(() async => device.close());

  test(
    'Google and iCloud keep independent account bindings and last syncs',
    () async {
      await device.saveSong('song', 'body');
      await device.sync.sync();
      await icloudSync.sync();

      final googleLastSuccess = await device.sync.lastSuccessfulSync();
      final icloudLastSuccess = await icloudSync.lastSuccessfulSync();
      expect(googleLastSuccess, isNotNull);
      expect(icloudLastSuccess, DateTime.utc(2026, 3, 1));
      expect(await device.repo.getSetting('sync.account'), {
        'id': syncHash('google-a'),
        'email': 'google-a@example.test',
      });
      expect(await device.repo.getSetting('sync.icloud.account'), {
        'id': syncHash('icloud-a'),
        'email': 'icloud-a@example.test',
      });

      device.auth.id = 'google-b';
      expect(await device.sync.hasAccountMismatch(), isTrue);
      expect(await icloudSync.hasAccountMismatch(), isFalse);
      icloudAuth.id = 'icloud-b';
      expect(await icloudSync.hasAccountMismatch(), isTrue);
      expect(await device.sync.hasAccountMismatch(), isTrue);
    },
  );

  test(
    'adopting an iCloud account clears only its old and new baselines',
    () async {
      await device.saveSong('song', 'body');
      await device.sync.sync();
      await icloudSync.sync();

      final googleOld = syncHash('google-a'), googleNew = syncHash('google-b');
      final icloudOld = syncHash('icloud-a'), icloudNew = syncHash('icloud-b');
      Future<void> seed(String account, String id) =>
          device.repo.writeSyncBaselines(
            account,
            puts: [
              SyncBaseline(
                kind: 'song',
                id: id,
                cloudHash: 'cloud-$id',
                localHash: 'local-$id',
              ),
            ],
          );

      await seed(googleOld, 'google-old');
      await seed(googleNew, 'google-new');
      await seed(icloudNew, 'icloud-new');
      icloudAuth.id = 'icloud-b';
      expect(await icloudSync.hasAccountMismatch(), isTrue);

      await icloudSync.adoptAccount(mergeLocal: true);

      expect(await device.repo.loadSyncBaselines(icloudOld), isEmpty);
      expect(await device.repo.loadSyncBaselines(icloudNew), isEmpty);
      expect(
        (await device.repo.loadSyncBaselines(googleOld)).keys,
        contains('song:google-old'),
      );
      expect(
        (await device.repo.loadSyncBaselines(googleNew)).keys,
        contains('song:google-new'),
      );
      expect(await icloudSync.hasAccountMismatch(), isFalse);
      expect(await device.sync.hasAccountMismatch(), isFalse);
    },
  );
}
