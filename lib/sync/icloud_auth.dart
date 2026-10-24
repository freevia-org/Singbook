import 'dart:io';

import 'package:flutter/services.dart';

import 'google_auth.dart';
import 'sync_protocol.dart';

/// Device's current iCloud identity. This performs no sign-in and stores no
/// credentials; CloudKit uses the signed-in system account.
class ICloudAuthorization implements DriveAuthorization {
  ICloudAuthorization({MethodChannel? channel, bool? supportedOverride})
    : _channel =
          channel ?? const MethodChannel('org.freevia.singbook/icloud_sync'),
      // Keep the test override public while the stored field stays private.
      // ignore: prefer_initializing_formals
      _supportedOverride = supportedOverride;
  final MethodChannel _channel;
  final bool? _supportedOverride;
  String? _recordName;
  String? _email;
  bool _available = false;
  bool _loaded = false;

  @override
  bool get configured =>
      _supportedOverride ?? (Platform.isIOS || Platform.isMacOS);
  @override
  bool get isConnected => _available && _recordName != null;
  @override
  String? get accountId => _recordName == null ? null : 'icloud:$_recordName';
  @override
  String? get accountEmail => _email;

  Future<void> refresh() async {
    _loaded = true;
    try {
      final value = await _channel.invokeMapMethod<String, Object?>('status');
      _available = value?['available'] == true;
      _recordName = value?['recordName'] as String?;
      _email = null;
      if (!_available || _recordName == null || _recordName!.isEmpty) {
        _available = false;
        _recordName = null;
        throw const SyncException('icloud_unavailable');
      }
    } on PlatformException catch (error) {
      _available = false;
      _recordName = null;
      throw SyncException(error.code);
    } on MissingPluginException {
      _available = false;
      _recordName = null;
      throw const SyncException('icloud_unavailable');
    }
  }

  @override
  Future<void> connect() async => refresh();
  @override
  Future<bool> restore() async {
    try {
      await refresh();
      return isConnected;
    } on SyncException catch (error) {
      if (error.code == 'icloud_unavailable') return false;
      rethrow;
    }
  }

  @override
  Future<String> accessToken() async =>
      throw const SyncException('not_supported');
  @override
  Future<void> disconnect() async {
    _available = false;
    _recordName = null;
  }

  bool get hasLoadedIdentity => _loaded;
}
