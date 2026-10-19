import 'google_auth.dart';

/// File selection and authorization travel together so a selected Drive ID is
/// never used with a token belonging to another platform flow or account.
abstract interface class DriveFileAccessCapability {
  DriveAuthorization get fileAuthorization;
  Future<String> pickFolder({String? accountEmail});
  Future<List<String>> pickChordProFiles({String? accountEmail});
}
