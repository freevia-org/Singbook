import 'ios_drive_file_access.dart';
import 'windows_drive_file_access.dart';
import 'windows_google_auth.dart';

/// Uses Google's custom-scheme PKCE Picker flow with the same iOS-type OAuth
/// client as macOS sign-in (or an explicit macOS override) and the shared
/// secure credential/grant implementation.
class MacOSDriveFileAccess extends WindowsDriveFileAccess {
  MacOSDriveFileAccess({
    required super.identity,
    super.clientId = const String.fromEnvironment(
      'VERSE_GOOGLE_MACOS_CLIENT_ID',
      defaultValue: String.fromEnvironment('VERSE_GOOGLE_IOS_CLIENT_ID'),
    ),
    DesktopCredentialStore? credentials,
    IOSPickerOAuthFlow? flow,
  }) : super(
         credentials: credentials ?? WindowsCredentialStore(),
         flow: flow ?? IOSPickerOAuthFlow(),
       );
}
