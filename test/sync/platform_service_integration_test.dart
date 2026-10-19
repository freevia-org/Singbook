import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/drive_file_access.dart';
import 'package:singbook/sync/google_drive_sync.dart';

import 'support.dart';

class _Access implements DriveFileAccessCapability {
  _Access(this.fileAuthorization);
  @override
  final DriveAuthorization fileAuthorization;
  Future<String> Function()? folder;
  Future<List<String>> Function()? files;
  String? pickerEmail;
  @override
  Future<String> pickFolder({String? accountEmail}) {
    pickerEmail = accountEmail;
    return folder?.call() ?? Future.value('chosen-folder');
  }

  @override
  Future<List<String>> pickChordProFiles({String? accountEmail}) =>
      files?.call() ?? Future.value(const []);
}

class _Store implements VisibleDriveFolderStore {
  _Store(this.cloud, this.folderId, {this.verificationError});
  final MemoryCloud cloud;
  final Object? verificationError;
  @override
  final String? folderId;
  bool closed = false;
  void _open() {
    if (closed) throw StateError('closed store reused');
  }

  @override
  Future<DriveFolderInfo> verifyFolder() async {
    _open();
    if (verificationError != null) throw verificationError!;
    return DriveFolderInfo(id: folderId!, name: 'Chosen library');
  }

  @override
  void close() => closed = true;
  @override
  Future<List<DriveFile>> listFiles() {
    _open();
    return cloud.listFiles();
  }

  @override
  Future<String> readFile(String id) {
    _open();
    return cloud.readFile(id);
  }

  @override
  Future<DriveFile?> getFile(String id) {
    _open();
    return cloud.getFile(id);
  }

  @override
  Future<DriveFile> createFile(
    String name,
    String content,
    Map<String, String> properties,
  ) {
    _open();
    return cloud.createFile(name, content, properties);
  }

  @override
  Future<DriveFile> updateFile(
    String id,
    String content,
    Map<String, String> properties,
  ) {
    _open();
    return cloud.updateFile(id, content, properties);
  }

  @override
  Future<void> deleteFile(String id) {
    _open();
    return cloud.deleteFile(id);
  }
}

void main() {
  late Device device;
  late MemoryCloud privateCloud, visibleCloud;
  late FakeAuth fileAuth;
  late _Access access;
  late List<({DriveAuthorization auth, _Store store})> stores;
  Object? verificationError;

  GoogleDriveSyncService service() => GoogleDriveSyncService(
    repository: device.repo,
    auth: device.auth,
    fileAccess: access,
    storeFactory: (auth, folder) {
      final store = _Store(
        folder == null ? privateCloud : visibleCloud,
        folder,
        verificationError: folder == null ? null : verificationError,
      );
      stores.add((auth: auth, store: store));
      return store;
    },
  );

  setUp(() async {
    privateCloud = MemoryCloud();
    visibleCloud = MemoryCloud();
    device = await Device.create(privateCloud);
    fileAuth = FakeAuth()..connected = true;
    access = _Access(fileAuth);
    stores = [];
    verificationError = null;
  });
  tearDown(() => device.close());

  test(
    'folder migration pairs picker authorization and retains private backup',
    () async {
      await device.saveSong('kept', '[C]Original library');
      await device.sync.sync();
      final originalBody = privateCloud.body('song-kept.cho');
      final sync = service();

      final folder = await sync.chooseVisibleDriveFolder();

      expect(folder.id, 'chosen-folder');
      expect(access.pickerEmail, device.auth.accountEmail);
      expect(privateCloud.body('song-kept.cho'), originalBody);
      expect(visibleCloud.body('song-kept.cho'), originalBody);
      expect(privateCloud.deletes, 0);
      expect(stores.where((s) => s.store.folderId == null), isNotEmpty);
      expect(
        stores
            .where((s) => s.store.folderId == null)
            .every((s) => identical(s.auth, device.auth)),
        isTrue,
      );
      expect(
        stores
            .where((s) => s.store.folderId != null)
            .every((s) => identical(s.auth, fileAuth)),
        isTrue,
      );
      await sync
          .sync(); // The temporary migration store must not close this one.
      expect(await device.repo.getSong('kept'), isNotNull);
    },
  );

  test('picker cancellation leaves location and files untouched', () async {
    await device.saveSong('kept', '[C]Kept');
    await device.sync.sync();
    final original = privateCloud.body('song-kept.cho');
    access.folder = () async => throw const SyncException('cancelled');
    await expectLater(
      service().chooseVisibleDriveFolder(),
      throwsA(isA<SyncException>().having((e) => e.code, 'code', 'cancelled')),
    );
    expect(stores, isEmpty);
    expect(visibleCloud.writes, 0);
    expect(privateCloud.body('song-kept.cho'), original);
    expect(
      await device.repo.getSetting('sync.driveFolder.${syncHash('person-a')}'),
      isNull,
    );
  });

  test(
    'account change during picker cannot activate a folder for the old account',
    () async {
      access.folder = () async {
        device.auth.id = 'person-b';
        return 'chosen-folder';
      };
      await expectLater(
        service().chooseVisibleDriveFolder(),
        throwsA(
          isA<SyncException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      expect(stores, isEmpty);
      expect(visibleCloud.writes, 0);
      expect(
        await device.repo.getSetting(
          'sync.driveFolder.${syncHash('person-a')}',
        ),
        isNull,
      );
      expect(
        await device.repo.getSetting(
          'sync.driveFolder.${syncHash('person-b')}',
        ),
        isNull,
      );
    },
  );

  test(
    'failed target verification closes the owned store before any migration',
    () async {
      verificationError = const SyncException('drive_folder_missing');
      await expectLater(
        service().chooseVisibleDriveFolder(),
        throwsA(isA<SyncException>()),
      );
      expect(stores, hasLength(1));
      expect(stores.single.store.closed, isTrue);
      expect(privateCloud.requests, 0);
      expect(visibleCloud.writes, 0);
    },
  );

  test(
    'file import serializes sign-out and releases its busy state on cancel',
    () async {
      final sync = service();
      await sync.chooseVisibleDriveFolder();
      final started = Completer<void>();
      final selected = Completer<List<String>>();
      access.files = () {
        started.complete();
        return selected.future;
      };
      final importing = sync.importChordProFilesFromDrive();
      await started.future;
      expect(sync.isBusy, isTrue);
      await expectLater(
        sync.disconnect(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.code,
            'code',
            'sync_in_progress',
          ),
        ),
      );
      selected.completeError(const SyncException('cancelled'));
      await expectLater(importing, throwsA(isA<SyncException>()));
      expect(sync.isBusy, isFalse);
      expect(device.auth.isConnected, isTrue);
    },
  );

  test(
    'an explicitly injected cloud keeps the original appData-only contract',
    () async {
      await device.saveSong('original', '[G]Unchanged injected cloud');
      await device.sync.sync();
      expect(privateCloud.files, hasLength(1));
      await expectLater(
        device.sync.chooseVisibleDriveFolder(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.code,
            'code',
            'folder_picker_unavailable',
          ),
        ),
      );
      expect(privateCloud.deletes, 0);
    },
  );
}
