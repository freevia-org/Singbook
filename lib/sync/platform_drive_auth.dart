import 'package:flutter/foundation.dart';

import 'drive_file_access.dart';
import 'google_auth.dart';
import 'ios_drive_file_access.dart';
import 'macos_drive_file_access.dart';
import 'windows_drive_file_access.dart';
import 'mobile_drive_file_access.dart';
import 'sync_protocol.dart';
import 'windows_google_auth.dart';

typedef SavedDriveIdentityLoader = Future<Map<String, String>?> Function();
typedef SavedDriveIdentitySaver =
    Future<void> Function(Map<String, String>? identity);
typedef MobileDriveAuthBuilder =
    DriveAuthorization Function({
      SavedDriveIdentityLoader? loadSavedIdentity,
      SavedDriveIdentitySaver? saveSavedIdentity,
    });

/// Returns the primary authorization itself, retaining its optional refresh,
/// profile and platform file-access interfaces. Mobile identity persistence
/// callbacks continue to belong to the existing mobile authorization.
DriveAuthorization createPlatformDriveAuthorization({
  SavedDriveIdentityLoader? loadSavedIdentity,
  SavedDriveIdentitySaver? saveSavedIdentity,
  @visibleForTesting TargetPlatform? platformOverride,
  @visibleForTesting bool? isWebOverride,
  @visibleForTesting MobileDriveAuthBuilder? mobileBuilder,
  @visibleForTesting DriveAuthorization Function()? windowsBuilder,
}) {
  if (isWebOverride ?? kIsWeb) return const _UnavailableDriveAuthorization();
  switch (platformOverride ?? defaultTargetPlatform) {
    case TargetPlatform.windows:
      return windowsBuilder?.call() ?? WindowsGoogleDriveAuth();
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return (mobileBuilder ?? _mobileAuthorization)(
        loadSavedIdentity: loadSavedIdentity,
        saveSavedIdentity: saveSavedIdentity,
      );
    default:
      return const _UnavailableDriveAuthorization();
  }
}

DriveAuthorization _mobileAuthorization({
  SavedDriveIdentityLoader? loadSavedIdentity,
  SavedDriveIdentitySaver? saveSavedIdentity,
}) => GoogleDriveAuth(
  loadSavedIdentity: loadSavedIdentity,
  saveSavedIdentity: saveSavedIdentity,
);

/// Create once per sync service, paired with that service's primary identity.
/// iOS uses a system-browser Picker and device-only Keychain grant.
DriveFileAccessCapability? createPlatformDriveFileAccess(
  DriveAuthorization authorization, {
  @visibleForTesting TargetPlatform? platformOverride,
  @visibleForTesting bool? isWebOverride,
}) {
  if (isWebOverride ?? kIsWeb) return null;
  final platform = platformOverride ?? defaultTargetPlatform;
  if (platform != TargetPlatform.windows &&
      platform != TargetPlatform.android &&
      platform != TargetPlatform.iOS &&
      platform != TargetPlatform.macOS) {
    return null;
  }
  if (authorization is DriveFileAccessCapability) {
    return authorization as DriveFileAccessCapability;
  }
  if (platform == TargetPlatform.iOS) {
    return IOSDriveFileAccess(identity: authorization);
  }
  if (platform == TargetPlatform.macOS) {
    return MacOSDriveFileAccess(identity: authorization);
  }
  if (platform != TargetPlatform.android) return null;
  return MobileDriveFileAccess(
    identity: authorization,
    platformOverride: platformOverride,
    isWebOverride: isWebOverride,
  );
}

/// Call before changing the primary identity directly (connect/disconnect).
/// Windows owns its lifecycle internally; mobile needs an epoch because the
/// primary interface does not publish account-change notifications.
void invalidatePlatformDriveFileAccess(DriveFileAccessCapability? access) {
  if (access is MobileDriveFileAccess) access.invalidate();
  if (access is WindowsDriveFileAccess) access.cancel();
}

class _UnavailableDriveAuthorization implements DriveAuthorization {
  const _UnavailableDriveAuthorization();
  @override
  bool get configured => false;
  @override
  bool get isConnected => false;
  @override
  String? get accountId => null;
  @override
  String? get accountEmail => null;
  @override
  Future<void> connect() async => throw const SyncException('not_configured');
  @override
  Future<bool> restore() async => false;
  @override
  Future<String> accessToken() async =>
      throw const SyncException('not_signed_in');
  @override
  Future<void> disconnect() async {}
}

/// Remove the separate iOS file grant before signing out the primary account.
Future<void> clearPlatformDriveFileAccess(
  DriveFileAccessCapability? access,
) async {
  if (access is IOSDriveFileAccess) await access.clearAccount();
  if (access is MacOSDriveFileAccess) await access.clearAccount();
}
