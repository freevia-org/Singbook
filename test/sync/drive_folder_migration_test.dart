import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/sync/google_drive_sync.dart';

import 'support.dart';

class _VisibleMemoryCloud extends MemoryCloud
    implements VisibleDriveFolderStore {
  _VisibleMemoryCloud(this.folderId);

  @override
  final String folderId;

  @override
  Future<DriveFolderInfo> verifyFolder() async =>
      DriveFolderInfo(id: folderId, name: 'Visible library');

  @override
  void close() {}
}

void main() {
  late MemoryCloud source;
  late _VisibleMemoryCloud destination;
  late Device device;
  late DriveFile sourceFile;
  late DriveFile destinationFile;
  late String account;
  late String folderKey;
  late String cleanupKey;
  late Map<String, Object?> cleanupJournal;
  late Map<String, Object?> destinationSetting;

  Future<void> prepareMigration() async {
    source = MemoryCloud();
    destination = _VisibleMemoryCloud('visible-library');
    device = await Device.create(source);
    await device.saveSong('move-me', '[C]A song to move');
    await device.sync.sync();

    sourceFile = source.files.single;
    destination.put(
      sourceFile.name,
      await source.readFile(sourceFile.id),
      properties: sourceFile.properties,
    );
    destinationFile = destination.files.single;

    account = syncHash('person-a');
    folderKey = 'sync.driveFolder.$account';
    cleanupKey = 'sync.driveFolderCleanup.$account';
    destinationSetting = {
      'id': destination.folderId,
      'name': 'Visible library',
    };
    cleanupJournal = {
      'version': 1,
      'sourceFolderId': null,
      'destinationFolderId': destination.folderId,
      'verifiedFileCount': 1,
    };
  }

  GoogleDriveSyncService resumedService(SyncCloudStore store) =>
      GoogleDriveSyncService(
        repository: device.repo,
        auth: device.auth,
        store: store,
      );

  Future<void> activateMigration() => device.repo.setSettingsAtomically({
    cleanupKey: cleanupJournal,
    folderKey: destinationSetting,
  });

  tearDown(() async {
    await device.close();
  });

  test(
    'atomic activation rolls back a failed second write and resumes safely',
    () async {
      await prepareMigration();
      await device.repo.database.execute('''
      CREATE TRIGGER fail_folder_activation
      BEFORE INSERT ON settings
      WHEN NEW.key = '$folderKey'
      BEGIN SELECT RAISE(ABORT, 'simulated process interruption'); END
    ''');

      await expectLater(activateMigration(), throwsA(anything));
      expect(await device.repo.getSetting(folderKey), isNull);
      expect(await device.repo.getSetting(cleanupKey), isNull);
      expect(source.body(sourceFile.name), isNotNull);

      // A legacy/partially-written journal without a committed destination must
      // be inert, even if it names old files for cleanup.
      final incompleteJournal = {
        'folderId': null,
        'fileIds': [sourceFile.id],
      };
      await device.repo.setSetting(cleanupKey, incompleteJournal);
      await resumedService(source).sync();
      expect(source.body(sourceFile.name), isNotNull);
      expect(await device.repo.getSetting(cleanupKey), incompleteJournal);
      await device.repo.setSetting(cleanupKey, null);

      await device.repo.database.execute('DROP TRIGGER fail_folder_activation');
      await activateMigration();
      await resumedService(destination).sync();

      expect(await device.repo.getSetting(folderKey), destinationSetting);
      expect(await device.repo.getSetting(cleanupKey), isNull);
      expect(source.body(sourceFile.name), isNotNull);
      expect(destination.body(sourceFile.name), isNotNull);
    },
  );

  test(
    'resumed migration retains a source edited after copy verification',
    () async {
      await prepareMigration();
      await activateMigration();
      final edited =
          '${await source.readFile(sourceFile.id)}\n# newer source edit';
      source.put(sourceFile.name, edited);

      await resumedService(destination).sync();

      expect(source.body(sourceFile.name), edited);
      expect(destination.body(sourceFile.name), isNotNull);
    },
  );

  test(
    'resumed migration retains source when destination changed after verify',
    () async {
      await prepareMigration();
      await activateMigration();
      final edited =
          '${await destination.readFile(destinationFile.id)}\n# newer destination edit';
      destination.put(destinationFile.name, edited);

      await resumedService(destination).sync();

      expect(source.body(sourceFile.name), isNotNull);
      expect(destination.body(destinationFile.name), edited);
    },
  );
}
