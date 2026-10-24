import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/google_auth.dart';
import 'package:singbook/sync/macos_drive_file_access.dart';
import 'package:singbook/sync/platform_drive_auth.dart';

void main() {
  test('macOS uses its own OAuth client and separate Drive Picker access', () {
    final configured = GoogleDriveAuth(
      serverClientId: '',
      iosClientId: '',
      macosClientId: 'mac.apps.googleusercontent.com',
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
    expect(missingClient.configured, isFalse);

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
