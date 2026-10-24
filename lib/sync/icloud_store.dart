import 'dart:convert';

import 'package:flutter/services.dart';

import 'drive_store.dart';
import 'sync_protocol.dart';
import 'icloud_auth.dart';

/// CloudKit private database adapter implementing the existing sync protocol.
class ICloudSyncStore implements SyncCloudStore {
  ICloudSyncStore({required this.authorization, MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('org.freevia.singbook/icloud_sync');
  final ICloudAuthorization authorization;
  final MethodChannel _channel;
  final Map<String, DriveFile> _observed = {};
  final Set<String> _knownMissing = {};
  String? _observedAccount;
  static const int maxListedFiles = 40000;

  Map<String, Object?> _scope([Map<String, Object?> extra = const {}]) {
    final account = authorization.accountId;
    if (!authorization.isConnected ||
        account == null ||
        !account.startsWith('icloud:')) {
      throw const SyncException('account_unavailable');
    }
    if (_observedAccount != account) {
      _observed.clear();
      _knownMissing.clear();
      _observedAccount = account;
    }
    return {'accountID': account, ...extra};
  }

  Future<T> _call<T>(String method, Map<String, Object?> args) async {
    try {
      return (await _channel.invokeMethod<T>(method, args)) as T;
    } on PlatformException catch (error) {
      throw SyncException(error.code);
    } on MissingPluginException {
      throw const SyncException('icloud_unavailable');
    }
  }

  DriveFile _parse(Object? raw) {
    if (raw is! Map) throw const SyncException('invalid_remote_data');
    final name = raw['name'];
    final id = raw['id'];
    final tag = raw['changeTag'];
    final props = raw['properties'];
    final size = raw['size'];
    final modifiedTime = raw['modifiedTime'];
    if (name is! String ||
        id is! String ||
        !_cloudRecordId.hasMatch(id) ||
        tag is! String ||
        tag.isEmpty ||
        tag.length > 4096 ||
        props is! Map ||
        (size != null && (size is! int || size < 0)) ||
        (modifiedTime != null && modifiedTime is! String) ||
        name.length > 255 ||
        parseSyncFileName(name) == null) {
      throw const SyncException('invalid_remote_data');
    }
    final properties = <String, String>{};
    var propertiesBytes = 0;
    for (final entry in props.entries) {
      if (entry.key is! String ||
          entry.value is! String ||
          (entry.key as String).length > 128 ||
          (entry.value as String).length > 4096) {
        throw const SyncException('invalid_remote_data');
      }
      final key = entry.key as String;
      final value = entry.value as String;
      propertiesBytes += utf8.encode(key).length + utf8.encode(value).length;
      if (propertiesBytes > 65536) {
        throw const SyncException('invalid_remote_data');
      }
      properties[key] = value;
    }
    return DriveFile(
      id: id,
      name: name,
      properties: properties,
      version: tag,
      size: size as int?,
      modifiedTime: DateTime.tryParse(modifiedTime as String? ?? ''),
    );
  }

  @override
  Future<List<DriveFile>> listFiles() async {
    final raw = await _call<List<Object?>>('list', _scope());
    if (raw.length > maxListedFiles) {
      throw const SyncException('remote_library_too_large');
    }
    final files = raw.map(_parse).toList(growable: false);
    _observed
      ..clear()
      ..addEntries(files.map((file) => MapEntry(file.id, file)));
    _knownMissing.clear();
    return files;
  }

  @override
  Future<DriveFile?> getFile(String id) async {
    try {
      final raw = await _call<Object?>('get', _scope({'id': id}));
      if (raw == null) {
        _observed.remove(id);
        _knownMissing.add(id);
        return null;
      }
      final file = _parse(raw);
      _observed[id] = file;
      _knownMissing.remove(id);
      return file;
    } on SyncException catch (error) {
      if (error.code == 'remote_file_missing') {
        _observed.remove(id);
        _knownMissing.add(id);
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<String> readFile(String id) async {
    final raw = await _call<Object?>('read', _scope({'id': id}));
    if (raw is! Map || raw['content'] is! String) {
      throw const SyncException('invalid_remote_data');
    }
    final content = raw['content'] as String;
    if (utf8.encode(content).length > maxSyncFileBytes) {
      throw const SyncException('remote_file_too_large');
    }
    return content;
  }

  @override
  Future<DriveFile> createFile(
    String name,
    String content,
    Map<String, String> properties,
  ) async {
    _validate(name, content);
    _validateProperties(properties);
    final file = _parse(
      await _call<Object?>(
        'create',
        _scope({'name': name, 'content': content, 'properties': properties}),
      ),
    );
    _observed[file.id] = file;
    _knownMissing.remove(file.id);
    return file;
  }

  @override
  Future<DriveFile> updateFile(
    String id,
    String content,
    Map<String, String> properties,
  ) async {
    _validate(null, content);
    _validateProperties(properties);
    final scope =
        _scope(); // Clear observations if authorization changed account.
    final current = _observed[id];
    if (current == null) throw const SyncException('sync_conflict');
    final file = _parse(
      await _call<Object?>('update', {
        ...scope,
        'id': id,
        'changeTag': current.version!,
        'content': content,
        'properties': properties,
      }),
    );
    _observed[id] = file;
    _knownMissing.remove(id);
    return file;
  }

  @override
  Future<void> deleteFile(String id) async {
    final scope =
        _scope(); // Clear observations if authorization changed account.
    final current = _observed[id];
    if (current == null) {
      if (_knownMissing.contains(id)) return;
      throw const SyncException('sync_conflict');
    }
    await _call<Object?>('delete', {
      ...scope,
      'id': id,
      'changeTag': current.version!,
    });
    _observed.remove(id);
    _knownMissing.add(id);
  }

  void _validate(String? name, String content) {
    if (name != null && parseSyncFileName(name) == null) {
      throw const SyncException('invalid_local_data');
    }
    if (utf8.encode(content).length > maxSyncFileBytes) {
      throw const SyncException('local_file_too_large');
    }
  }

  void _validateProperties(Map<String, String> properties) {
    if (properties.length > 256 ||
        properties.entries.any(
          (entry) =>
              entry.key.isEmpty ||
              utf8.encode(entry.key).length > 128 ||
              utf8.encode(entry.value).length > 4096,
        ) ||
        utf8.encode(jsonEncode(properties)).length > 65536) {
      throw const SyncException('invalid_local_data');
    }
  }
}

final _cloudRecordId = RegExp(r'^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$');
