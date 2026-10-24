import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/google_auth.dart';
import 'package:singbook/sync/macos_drive_file_access.dart';
import 'package:singbook/sync/platform_drive_auth.dart';

void main() {
  test('macOS reuses the iOS OAuth client when no override is supplied', () {
    final configured = GoogleDriveAuth(
      serverClientId: '',
      iosClientId: 'ios.apps.googleusercontent.com',
      macosClientId: '',
      isAndroidOverride: false,
      isMacOSOverride: true,
    );
    expect(configured.configured, isTrue);

    final missingClient = GoogleDriveAuth(
      serverClientId: '',
      iosClientId: 'ios.apps.googleusercontent.com',
      macosClientId: '',
      isAndroidOverride: false,
      isMacOSOverride: true,
    );
    expect(missingClient.configured, isTrue);
  });

  test(
    'an explicit macOS OAuth client takes precedence over the iOS client',
    () {
      final auth = GoogleDriveAuth(
        serverClientId: '',
        iosClientId: 'ios.apps.googleusercontent.com',
        macosClientId: 'mac.apps.googleusercontent.com',
        isAndroidOverride: false,
        isMacOSOverride: true,
      );
      expect(auth.configured, isTrue);
    },
  );

  test('macOS routes through Google auth and separate Drive Picker access', () {
    final auth = createPlatformDriveAuthorization(
      platformOverride: TargetPlatform.macOS,
      isWebOverride: false,
    );
    expect(auth, isA<GoogleDriveAuth>());
    final access = createPlatformDriveFileAccess(
      auth,
      platformOverride: TargetPlatform.macOS,
      isWebOverride: false,
    );
    expect(access, isA<MacOSDriveFileAccess>());
    expect((access as MacOSDriveFileAccess).identity, same(auth));
  });
}
