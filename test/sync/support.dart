import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:verse_mobile/data/library_repository.dart';
import 'package:verse_mobile/domain/models.dart';
import 'package:verse_mobile/sync/google_drive_sync.dart';

class FakeAuth implements DriveAuthorization {
  bool connected = false;
  String id = 'person-a';
  Object? restoreError;
  @override
  bool get configured => true;
  @override
  bool get isConnected => connected;
  @override
  String? get accountId => connected ? id : null;
  @override
  String? get accountEmail => connected ? '$id@example.test' : null;
  @override
  Future<void> connect() async {
    connected = true;
  }

  @override
  Future<bool> restore() async {
    if (restoreError != null) throw restoreError!;
    return connected;
  }

  @override
  Future<String> accessToken() async => 'test-token';
  @override
  Future<void> disconnect() async {
    connected = false;
  }
}

class RefreshableFakeAuth extends FakeAuth implements RefreshableAuthorization {
  int refreshes = 0;
  String token = 'stale-token';
  @override
  Future<String> accessToken() async => token;
  @override
  Future<String> refreshAccessToken() async {
    refreshes++;
    return token = 'fresh-token';
  }
}

class _Stored {
  _Stored(this.id, this.name, this.content, this.props, this.version, this.at);
  String id, name, content;
  Map<String, String> props;
  int version;
  DateTime at;
}

/// In-memory Drive appDataFolder with in-place updates, versions and
/// fault injection. Several devices share one instance.
class MemoryCloud implements SyncCloudStore {
  final _files = <String, _Stored>{};
  int _ids = 0, _versions = 0;

  /// Server clock; every write advances it by one second.
  DateTime now = DateTime.utc(2026, 1, 1);

  int lists = 0, reads = 0, gets = 0, creates = 0, updates = 0, deletes = 0;
  int get writes => creates + updates + deletes;
  int get requests => lists + reads + gets + writes;
  void resetCounters() =>
      lists = reads = gets = creates = updates = deletes = 0;

  /// Called before every operation (`list`, `read`, `get`, `create`,
  /// `update`, `delete`) with the file id (or name for create). Throw to fail.
  FutureOr<void> Function(String op, String target)? hook;

  /// Pretends a file is larger than it is (id -> reported size).
  final sizes = <String, int>{};

  @override
  Future<List<DriveFile>> listFiles() async {
    lists++;
    await hook?.call('list', '');
    return [for (final f in _files.values) _meta(f)];
  }

  DriveFile _meta(_Stored f) => DriveFile(
    id: f.id,
    name: f.name,
    properties: Map.of(f.props),
    modifiedTime: f.at,
    version: '${f.version}',
    size: sizes[f.id] ?? utf8.encode(f.content).length,
  );

  @override
  Future<String> readFile(String id) async {
    reads++;
    await hook?.call('read', id);
    final f = _files[id];
    if (f == null) throw const SyncException('remote_file_missing');
    return f.content;
  }

  @override
  Future<DriveFile?> getFile(String id) async {
    gets++;
    await hook?.call('get', id);
    final f = _files[id];
    return f == null ? null : _meta(f);
  }

  @override
  Future<DriveFile> createFile(
    String name,
    String content,
    Map<String, String> properties,
  ) async {
    creates++;
    await hook?.call('create', name);
    return _meta(_write(null, name, content, properties));
  }

  @override
  Future<DriveFile> updateFile(
    String id,
    String content,
    Map<String, String> properties,
  ) async {
    updates++;
    await hook?.call('update', id);
    final f = _files[id];
    if (f == null) throw const SyncException('remote_file_missing');
    return _meta(_write(f, f.name, content, properties));
  }

  @override
  Future<void> deleteFile(String id) async {
    deletes++;
    await hook?.call('delete', id);
    _files.remove(id);
  }

  _Stored _write(
    _Stored? existing,
    String name,
    String content,
    Map<String, String> properties,
  ) {
    now = now.add(const Duration(seconds: 1));
    final f = existing ?? _Stored('file_${_ids++}', name, content, {}, 0, now);
    f
      ..content = content
      ..props = {...properties, 'verseSchema': syncSchema}
      ..version = ++_versions
      ..at = now;
    return _files[f.id] = f;
  }

  // ---- test helpers (not counted as requests) ---------------------------

  List<DriveFile> get files => [for (final f in _files.values) _meta(f)];
  List<String> get names => [for (final f in _files.values) f.name]..sort();
  bool has(String name) => _files.values.any((f) => f.name == name);
  String? body(String name) =>
      _files.values.where((f) => f.name == name).firstOrNull?.content;
  String? idOf(String name) =>
      _files.values.where((f) => f.name == name).firstOrNull?.id;

  /// Another writer (a device we do not simulate) puts a file in place.
  String put(String name, String content, {Map<String, String>? properties}) {
    final existing = _files.values.where((f) => f.name == name).firstOrNull;
    final kind = name.startsWith('song-') ? 'song' : 'setlist';
    return _write(
      existing,
      name,
      content,
      properties ?? {'kind': kind, 'hash': syncHash(content)},
    ).id;
  }

  /// Creates a second file with an already used name (a race on create).
  String putDuplicate(String name, String content) => _write(
    null,
    name,
    content,
    {'kind': name.startsWith('song-') ? 'song' : 'setlist', 'hash': syncHash(content)},
  ).id;

  void remove(String name) =>
      _files.removeWhere((_, f) => f.name == name);
}

/// A simulated device: its own library, its own sign-in, shared cloud.
class Device {
  Device._(this.repo, this.auth, this.sync, this._dir);
  final Directory _dir;
  final LibraryRepository repo;
  final FakeAuth auth;
  final GoogleDriveSyncService sync;

  static Future<Device> create(
    MemoryCloud cloud, {
    String account = 'person-a',
    int concurrency = 1,
    int maxItems = maxSyncItems,
    DateTime Function()? clock,
  }) async {
    sqfliteFfiInit();
    // Each device needs its own database (an in-memory path is shared).
    final dir = await Directory.systemTemp.createTemp('verse-sync-');
    final repo = await LibraryRepository.open(
      path: '${dir.path}/library.sqlite',
      factory: databaseFactoryFfi,
    );
    final auth = FakeAuth()..id = account;
    final sync = GoogleDriveSyncService(
      repository: repo,
      auth: auth,
      store: cloud,
      concurrency: concurrency,
      maxItems: maxItems,
      clock: clock,
    );
    await sync.connect();
    return Device._(repo, auth, sync, dir);
  }

  Future<void> close() async {
    await repo.close();
    try {
      await _dir.delete(recursive: true);
    } catch (_) {}
  }

  Future<void> saveSong(String id, String body, {String title = 'Song'}) =>
      repo.saveSong(
        SongDocument(
          id: id,
          title: title,
          artist: 'Artist',
          body: body,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );

  Future<void> editSong(String id, String body) async {
    final song = (await repo.getSong(id))!;
    await repo.saveSong(
      song.copyWith(
        body: body,
        updatedAt: song.updatedAt.add(const Duration(seconds: 1)),
      ),
    );
  }

  Future<String?> body(String id) async => (await repo.getSong(id))?.body;

  Future<void> saveSetlist(String id, String name, List<String> songIds) =>
      repo.saveSetlist(
        SetlistDocument(
          id: id,
          name: name,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          entries: [
            for (var i = 0; i < songIds.length; i++)
              SetlistEntry(id: '$id-e$i', songId: songIds[i]),
          ],
        ),
      );

  Future<List<String>> songIds() async =>
      [for (final s in await repo.listSongs()) s.id]..sort();
  Future<Set<String>> bodies() async => {
    for (final s in await repo.listSongs()) s.body,
  };
}

Matcher syncError(String code) =>
    isA<SyncException>().having((e) => e.code, 'code', code);
