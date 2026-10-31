import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/drive_file_access.dart';
import 'package:singbook/sync/google_auth.dart';
import 'package:singbook/sync/ios_drive_file_access.dart';
import 'package:singbook/sync/mobile_drive_file_access.dart';
import 'package:singbook/sync/platform_drive_auth.dart';
import 'package:singbook/sync/sync_protocol.dart';
import 'package:singbook/sync/windows_google_auth.dart';

class _Auth
    implements
        DriveAuthorization,
        RefreshableAuthorization,
        ProfilePhotoAuthorization,
        DriveFileAccessCapability {
  @override
  bool get configured => true;
  @override
  bool get isConnected => true;
  @override
  String get accountId => 'account';
  @override
  String get accountEmail => 'singer@example.com';
  @override
  String get accountPhotoUrl => 'https://example.com/photo';
  @override
  Future<void> connect() async {}
  @override
  Future<bool> restore() async => true;
  @override
  Future<void> disconnect() async {}
  @override
  Future<String> accessToken() async => 'token';
  @override
  Future<String> refreshAccessToken() async => 'renewed';
  @override
  DriveAuthorization get fileAuthorization => this;
  @override
  Future<String> pickFolder({String? accountEmail}) async => 'folder';
  @override
  Future<List<String>> pickChordProFiles({String? accountEmail}) async => [
    'file',
  ];
}

class _PlainAuth implements DriveAuthorization {
  @override
  bool get configured => true;
  @override
  bool get isConnected => true;
  @override
  String get accountId => 'account';
  @override
  String get accountEmail => 'singer@example.com';
  @override
  Future<void> connect() async {}
  @override
  Future<bool> restore() async => true;
  @override
  Future<void> disconnect() async {}
  @override
  Future<String> accessToken() async => 'primary-token';
}

Matcher _error(String code) =>
    isA<SyncException>().having((error) => error.code, 'code', code);

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test(
      '$platform forwards exact saved identity callbacks and optional capabilities',
      () async {
        final primary = _Auth();
        final savedIdentity = <String, String>{
          'id': 'old',
          'email': 'old@example.com',
        };
        Map<String, String>? saved;
        Future<Map<String, String>?> load() async => savedIdentity;
        Future<void> save(Map<String, String>? identity) async {
          saved = identity;
        }

        SavedDriveIdentityLoader? receivedLoad;
        SavedDriveIdentitySaver? receivedSave;
        final auth = createPlatformDriveAuthorization(
          platformOverride: platform,
          isWebOverride: false,
          loadSavedIdentity: load,
          saveSavedIdentity: save,
          mobileBuilder: ({loadSavedIdentity, saveSavedIdentity}) {
            receivedLoad = loadSavedIdentity;
            receivedSave = saveSavedIdentity;
            return primary;
          },
          windowsBuilder: () => throw StateError('wrong platform'),
        );
        expect(auth, same(primary));
        expect(auth, isA<RefreshableAuthorization>());
        expect(auth, isA<ProfilePhotoAuthorization>());
        expect(auth, isA<DriveFileAccessCapability>());
        expect(receivedLoad, same(load));
        expect(receivedSave, same(save));
        expect(await receivedLoad!(), same(savedIdentity));
        await receivedSave!(savedIdentity);
        expect(saved, same(savedIdentity));
        await receivedSave!(null);
        expect(saved, isNull);
      },
    );
  }

  test(
    'Windows uses the desktop builder without touching mobile persistence',
    () {
      final primary = _Auth();
      var desktopCalls = 0;
      final auth = createPlatformDriveAuthorization(
        platformOverride: TargetPlatform.windows,
        isWebOverride: false,
        loadSavedIdentity: () => throw StateError('mobile load'),
        saveSavedIdentity: (_) => throw StateError('mobile save'),
        mobileBuilder: ({loadSavedIdentity, saveSavedIdentity}) =>
            throw StateError('mobile builder'),
        windowsBuilder: () {
          desktopCalls++;
          return primary;
        },
      );
      expect(auth, same(primary));
      expect(auth, isA<RefreshableAuthorization>());
      expect(auth, isA<ProfilePhotoAuthorization>());
      expect(auth, isA<DriveFileAccessCapability>());
      expect(desktopCalls, 1);
    },
  );

  test('Linux reuses the desktop OAuth authorization', () {
    final auth = createPlatformDriveAuthorization(
      platformOverride: TargetPlatform.linux,
      isWebOverride: false,
    );
    expect(auth, isA<WindowsGoogleDriveAuth>());
    expect(auth, isA<DriveFileAccessCapability>());
  });

  test(
    'default constructors retain mobile callbacks and Windows type without native calls',
    () {
      Future<Map<String, String>?> load() async => null;
      Future<void> save(Map<String, String>? identity) async {}
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        final auth = createPlatformDriveAuthorization(
          platformOverride: platform,
          isWebOverride: false,
          loadSavedIdentity: load,
          saveSavedIdentity: save,
        );
        expect(auth, isA<GoogleDriveAuth>());
        final mobile = auth as GoogleDriveAuth;
        expect(mobile.loadSavedIdentity, same(load));
        expect(mobile.saveSavedIdentity, same(save));
      }
      final desktop = createPlatformDriveAuthorization(
        platformOverride: TargetPlatform.windows,
        isWebOverride: false,
      );
      expect(desktop, isA<WindowsGoogleDriveAuth>());
      expect(desktop, isA<DriveFileAccessCapability>());
    },
  );

  for (final platform in [
    TargetPlatform.fuchsia,
  ]) {
    test(
      '$platform is unavailable without constructing platform authorization or showing UI',
      () async {
        final auth = createPlatformDriveAuthorization(
          platformOverride: platform,
          isWebOverride: false,
          mobileBuilder: ({loadSavedIdentity, saveSavedIdentity}) =>
              throw StateError('must not construct'),
          windowsBuilder: () => throw StateError('must not construct'),
        );
        expect(auth.configured, isFalse);
        expect(auth.isConnected, isFalse);
        expect(auth.accountId, isNull);
        expect(await auth.restore(), isFalse);
        await expectLater(auth.connect(), throwsA(_error('not_configured')));
        await expectLater(auth.accessToken(), throwsA(_error('not_signed_in')));
        await auth.disconnect();
        expect(
          createPlatformDriveFileAccess(
            _Auth(),
            platformOverride: platform,
            isWebOverride: false,
          ),
          isNull,
        );
      },
    );
  }

  test('web fails closed even when platform says Windows', () async {
    final auth = createPlatformDriveAuthorization(
      platformOverride: TargetPlatform.windows,
      isWebOverride: true,
      windowsBuilder: () => throw StateError('must not construct'),
    );
    expect(auth.configured, isFalse);
    expect(await auth.restore(), isFalse);
    await expectLater(auth.connect(), throwsA(_error('not_configured')));
    expect(
      createPlatformDriveFileAccess(
        _Auth(),
        platformOverride: TargetPlatform.windows,
        isWebOverride: true,
      ),
      isNull,
    );
  });

  test(
    'file access dispatch keeps native capability and adapts plain mobile auth',
    () {
      final capable = _Auth(), plain = _PlainAuth();
      for (final platform in [
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.android,
        TargetPlatform.iOS,
      ]) {
        expect(
          createPlatformDriveFileAccess(
            capable,
            platformOverride: platform,
            isWebOverride: false,
          ),
          same(capable),
        );
      }
      expect(
        createPlatformDriveFileAccess(
          plain,
          platformOverride: TargetPlatform.windows,
          isWebOverride: false,
        ),
        isNull,
      );
      expect(
        createPlatformDriveFileAccess(
          capable,
          platformOverride: TargetPlatform.iOS,
          isWebOverride: false,
        ),
        same(capable),
      );
      expect(
        createPlatformDriveFileAccess(
          plain,
          platformOverride: TargetPlatform.iOS,
          isWebOverride: false,
        ),
        isA<IOSDriveFileAccess>(),
      );
      final android = createPlatformDriveFileAccess(
        plain,
        platformOverride: TargetPlatform.android,
        isWebOverride: false,
      );
      expect(android, isA<MobileDriveFileAccess>());
      expect((android as MobileDriveFileAccess).identity, same(plain));
      expect(android.fileAuthorization, isA<RefreshableAuthorization>());
      invalidatePlatformDriveFileAccess(capable);
      invalidatePlatformDriveFileAccess(null);
      expect(capable.isConnected, isTrue);
    },
  );
}
