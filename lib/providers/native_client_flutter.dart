import 'dart:io';
import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;
import 'windows_http_client.dart';

/// Platform stacks consume HTTP 103 Early Hints correctly. Dart IOClient's
/// HTTP/1 parser can emit an unsolicited-response error for Songsterr pages.
/// Android builds set cronetHttpNoPlay=true to bundle the engine, avoiding an
/// assumption that Google Play services is installed on the device.
http.Client createNativeHttpClient() {
  if (Platform.isAndroid) return CronetClient.defaultCronetEngine();
  if (Platform.isWindows) return WindowsHttpClient();
  if (Platform.isIOS || Platform.isMacOS) {
    return CupertinoClient.defaultSessionConfiguration();
  }
  return http.Client();
}
