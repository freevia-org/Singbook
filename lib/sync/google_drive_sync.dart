import 'dart:convert';
import 'dart:math' as math;
import '../data/library_repository.dart';
import '../domain/chordpro.dart';
import '../domain/models.dart';
import 'drive_store.dart';
import 'google_auth.dart';
import 'sync_protocol.dart';

export 'drive_store.dart';
export 'google_auth.dart';
export 'sync_protocol.dart';

/// Thrown inside one item's processing when the cloud file changed (or
/// vanished) since it was listed. The item is re-read and decided again.
class _Stale implements Exception {
  const _Stale();
}

/// Problems with one remote/local file that must not stop the other items.
const _skippable = {
  'remote_file_too_large',
  'invalid_remote_data',
  'local_file_too_large',
  'invalid_local_data',
};

enum _Act { none, adopt, forget, pull, push, resolve, deleteLocal, deleteCloud }

class _Item {
  _Item(this.kind, this.id);
  final String kind, id;
  String get key => '$kind:$id';

  /// Hash of the local document, or null when the item does not exist locally.
  String? local;

  /// The (newest) cloud file of this item, or null when there is none.
  DriveFile? cloud;

  /// The cloud file exists but cannot be trusted (no valid hash property).
  bool cloudInvalid = false;
  SyncBaseline? base;

  /// Older files with the same name (a race on create).
  List<DriveFile> duplicates = [];
}

class _Local {
  const _Local(this.content, this.hash);
  final String content, hash;
}

class _Pulled {
  const _Pulled(this.item, this.document, this.cloudHash);
  final _Item item;
  final Object document;
  final String cloudHash;
}

class _Run {
  _Run(
    this.account,
    this.replace, {
    this.replaceKeys,
    this.confirmDeletions = false,
  });
  final String account;

  /// The account was just adopted with "replace the local library".
  final bool replace;

  /// Items that existed locally when "replace" was chosen; only those are
  /// removed by it. Null (an old persisted flag) means every unknown item.
  final Set<String>? replaceKeys;

  /// The user approved a mass deletion that would otherwise be refused.
  final bool confirmDeletions;
  final puts = <String, SyncBaseline>{};
  final removes = <String>{};
  int uploaded = 0,
      downloaded = 0,
      conflicts = 0,
      deletedLocal = 0,
      deletedRemote = 0,
      pending = 0,
      cascadeDeletes = 0;
  final skipCodes = <String>[];

  /// Downloaded documents waiting to be written in one transaction.
  var pulls = <_Pulled>[];

  void put(SyncBaseline b) {
    removes.remove(b.key);
    puts[b.key] = b;
  }

  void remove(String key) {
    puts.remove(key);
    removes.add(key);
  }
}

/// Google Drive sync with one cloud file per item, updated in place.
///
/// Cloud layout (Drive appDataFolder, scope `drive.appdata` only):
///  * `song-<id>.cho`      the complete x_verse ChordPro payload of a song;
///  * `setlist-<id>.json`  a setlist as JSON.
/// Each file carries `appProperties` `{verseSchema: 2, kind, hash}` where
/// `hash` is the sha-256 of the body, so one metadata listing (no downloads)
/// is enough to see what changed.
///
/// Per item and per account the device remembers a baseline (`SyncBaseline`):
/// the cloud hash and local hash at the last point both sides agreed. Every
/// sync compares the current local hash and cloud hash with that baseline
/// (three-way, no history needed, no tombstones): only one side changed -> copy
/// it to the other; both changed -> the cloud version stays, the local edit
/// becomes a stable conflict copy; one side vanished -> that is a deletion
/// unless the other side changed since the baseline, in which case the change
/// wins and is restored. See lib/sync/SETUP.md.
class GoogleDriveSyncService {
  GoogleDriveSyncService({
    required this.repository,
    DriveAuthorization? auth,
    SyncCloudStore? store,
    this.maxItems = maxSyncItems,
    this.concurrency = 4,
    DateTime Function()? clock,
  }) : auth = auth ?? GoogleDriveAuth(
         loadSavedIdentity: () async {
           final raw = await repository.getSetting(_googleSessionKey);
           if (raw is Map && raw['id'] is String && raw['email'] is String) {
             return {
               'id': raw['id'] as String,
               'email': raw['email'] as String,
               if (raw['photoUrl'] is String)
                 'photoUrl': raw['photoUrl'] as String,
             };
           }
           return null;
         },
         saveSavedIdentity: (identity) =>
             repository.setSetting(_googleSessionKey, identity),
       ),
       _providedStore = store,
       _clock = clock; // ignore: prefer_initializing_formals

  final LibraryRepository repository;
  final DriveAuthorization auth;
  final SyncCloudStore? _providedStore;
  final DateTime Function()? _clock;

  /// Songs plus setlists. Beyond it sync fails with `remote_library_too_large`
  /// (cloud) / `library_too_large` (local) and changes nothing.
  final int maxItems;

  /// Parallel requests while processing items of one phase.
  final int concurrency;

  SyncCloudStore? _activeStore;
  SyncCloudStore get _store =>
      _activeStore ??= _providedStore ?? DriveAppDataStore(authorization: auth);
  final _codec = ChordProCodec();
  bool _busy = false, _cancelled = false;
  bool _confirmDeletions = false;

  /// Number of local items the last refused sync would have deleted (see
  /// `remote_listing_suspicious`), else 0.
  int suspiciousDeletionCount = 0;
  Set<String> _suspiciousKeys = {};

  /// A sync deleting at least [_minMassDeletes] items that were agreed with the
  /// cloud before, and more than half of them (or at least [_minEmptyListing]
  /// when the cloud lists no item at all), is refused as a suspicious listing.
  static const _minMassDeletes = 5, _minEmptyListing = 3;

  bool get configured => auth.configured;
  bool get isConnected => auth.isConnected;
  String? get accountEmail => auth.accountEmail;
  String? get accountPhotoUrl => auth is ProfilePhotoAuthorization
      ? (auth as ProfilePhotoAuthorization).accountPhotoUrl
      : null;
  bool get isBusy => _busy;
  DateTime _now() => (_clock?.call() ?? DateTime.now()).toUtc();

  Future<void> connect() async {
    if (_busy) throw const SyncException('sync_in_progress');
    await auth.connect();
  }

  Future<bool> restore() => auth.restore();

  /// Signs out of this device only. The local library, the baselines and the
  /// cloud files are untouched, so signing in again with the same account
  /// continues where it stopped.
  Future<void> disconnect() async {
    if (_busy) throw const SyncException('sync_in_progress');
    await auth.disconnect();
  }

  /// Asks a running [sync] to stop at the next item boundary (it then fails
  /// with `cancelled`). Everything done so far stays consistent.
  void cancel() => _cancelled = true;

  // ---- account binding -------------------------------------------------

  static const _bindingKey = 'sync.account';
  static const _googleSessionKey = 'sync.googleSession';
  static const _replaceKey = 'sync.replacePending';

  String _accountHash(String id) => syncHash(id);

  Future<JsonMap> _binding() async => jsonMap(await repository.getSetting(_bindingKey));

  /// True when this library is bound to a different Google account than the
  /// one currently signed in. Sync refuses with `account_changed` until
  /// [adoptAccount] is called.
  Future<bool> hasAccountMismatch() async {
    final id = auth.accountId;
    if (id == null) return false;
    final bound = await _binding();
    return bound['id'] is String && bound['id'] != _accountHash(id);
  }

  /// E-mail of the account this library was last synced with, when it is not
  /// the signed-in one (for the "switch account?" dialog); else null.
  Future<String?> previousAccountEmail() async {
    if (!await hasAccountMismatch()) return null;
    return (await _binding())['email'] as String?;
  }

  /// Explicit user decision after `account_changed`. Binds this library to the
  /// signed-in account and forgets the sync state of every other account.
  ///  * [mergeLocal] true: the next sync merges the local library with the
  ///    account (local-only items are uploaded, same-id differences become
  ///    conflict copies).
  ///  * [mergeLocal] false: the account's library replaces the local one:
  ///    local-only songs and setlists are removed and differing items are
  ///    overwritten by the cloud version. Destructive; the UI must confirm.
  ///    The decision is persisted and survives an interrupted sync.
  /// Nothing is read or written in the cloud by this call.
  Future<void> adoptAccount({required bool mergeLocal}) async {
    if (_busy) throw const SyncException('sync_in_progress');
    final id = auth.accountId;
    if (!auth.isConnected || id == null) {
      throw const SyncException('not_signed_in');
    }
    // Only a real account change may be adopted: a stray or repeated call must
    // not wipe the baselines and arm a destructive replace.
    if (!await hasAccountMismatch()) {
      throw const SyncException('no_account_change');
    }
    final account = _accountHash(id);
    // Remember what exists now: "replace" only removes these items, never
    // songs created while the replace sync was still waiting to run.
    final existing = mergeLocal ? null : (await _localSnapshot()).keys.toList();
    await repository.clearSyncBaselines();
    await repository.setSetting(_bindingKey, {
      'id': account,
      'email': auth.accountEmail,
    });
    if (mergeLocal) {
      await repository.setSetting(_replaceKey, null);
    } else {
      await repository.setSetting(_replaceKey, {
        'account': account,
        'keys': existing,
      });
    }
  }

  /// The user approved the deletions that a sync refused with
  /// `remote_listing_suspicious`; the next [sync] applies them.
  void confirmRemoteDeletions() => _confirmDeletions = true;

  /// The user rejected those deletions: the items the cloud lacks are treated
  /// as new local items and uploaded again by the next [sync].
  Future<void> keepLocalAfterSuspiciousListing() async {
    if (_busy) throw const SyncException('sync_in_progress');
    final id = auth.accountId;
    if (id == null) throw const SyncException('not_signed_in');
    if (_suspiciousKeys.isEmpty) return;
    await repository.writeSyncBaselines(
      _accountHash(id),
      puts: const [],
      removeKeys: _suspiciousKeys.toList(),
    );
    _suspiciousKeys = {};
    suspiciousDeletionCount = 0;
  }

  Future<DateTime?> lastSuccessfulSync() async {
    final id = auth.accountId;
    if (id == null) return null;
    return DateTime.tryParse(
      await repository.getSetting('sync.google.${_accountHash(id)}.lastSuccess')
              as String? ??
          '',
    );
  }

  // ---- sync ------------------------------------------------------------

  Future<SyncReport> sync() async {
    if (_busy) throw const SyncException('sync_in_progress');
    if (!auth.configured) throw const SyncException('not_configured');
    final id = auth.accountId;
    if (!auth.isConnected || id == null) {
      throw const SyncException('not_signed_in');
    }
    _busy = true;
    _cancelled = false;
    try {
      final account = _accountHash(id);
      final bound = await _binding();
      if (bound['id'] == null) {
        await repository.setSetting(_bindingKey, {
          'id': account,
          'email': auth.accountEmail,
        });
      } else if (bound['id'] != account) {
        throw const SyncException('account_changed');
      }
      final pending = await repository.getSetting(_replaceKey);
      final replace =
          pending == account ||
          (pending is Map && pending['account'] == account);
      final replaceKeys = pending is Map && pending['keys'] is List
          ? {for (final k in pending['keys'] as List) k.toString()}
          : null;
      final run = _Run(
        account,
        replace,
        replaceKeys: replaceKeys,
        confirmDeletions: _confirmDeletions,
      );
      _confirmDeletions = false;
      final outboxMark = await repository.outboxMark();
      Object? failed;
      try {
        for (var round = 0; round < 3; round++) {
          run.cascadeDeletes = 0;
          await _round(run);
          // Deleting a song removes it from local setlists; those changed
          // setlists are uploaded by one more round.
          if (run.cascadeDeletes == 0) break;
        }
      } catch (error) {
        failed = error;
        rethrow;
      } finally {
        // Whatever was uploaded or agreed is remembered even when a later item
        // failed: the next sync converges from there. A failing flush must not
        // hide the error that started the unwinding.
        try {
          await _flush(run);
        } catch (_) {
          if (failed == null) rethrow;
        }
      }
      if (replace) await repository.setSetting(_replaceKey, null);
      await repository.clearOutboxThrough(outboxMark);
      await repository.setSetting(
        'sync.google.$account.lastSuccess',
        _now().toIso8601String(),
      );
      return SyncReport(
        uploaded: run.uploaded,
        downloaded: run.downloaded,
        conflicts: run.conflicts,
        deletedLocal: run.deletedLocal,
        deletedRemote: run.deletedRemote,
        skipped: run.skipCodes.length,
        pending: run.pending,
        skipCodes: run.skipCodes.toSet().toList()..sort(),
      );
    } on FormatException {
      throw const SyncException('invalid_remote_data');
    } finally {
      _busy = false;
    }
  }

  void _check(_Run run) {
    if (_cancelled) throw const SyncException('cancelled');
    // The authenticated identity must stay fixed for the whole operation.
    if (auth.accountId == null || _accountHash(auth.accountId!) != run.account) {
      throw const SyncException('account_changed');
    }
  }

  Future<void> _flush(_Run run) async {
    if (run.puts.isEmpty && run.removes.isEmpty) return;
    final puts = run.puts.values.toList(), removes = run.removes.toList();
    run.puts.clear();
    run.removes.clear();
    await repository.writeSyncBaselines(
      run.account,
      puts: puts,
      removeKeys: removes,
    );
  }

  Future<Map<String, String>> _localSnapshot() async {
    final result = <String, String>{};
    final rows = await repository.database.query(
      'songs',
      columns: ['id', 'content_hash'],
    );
    for (final row in rows) {
      result['song:${row['id']}'] = row['content_hash'] as String;
    }
    for (final setlist in await repository.listSetlists()) {
      result['setlist:${setlist.id}'] = syncHash(jsonEncode(setlist.toJson()));
    }
    return result;
  }

  Future<_Local?> _readLocal(String kind, String id) async {
    if (kind == 'song') {
      final raw = await repository.getSongRaw(id);
      return raw == null ? null : _Local(raw.document, raw.hash);
    }
    final setlist = await repository.getSetlist(id);
    if (setlist == null) return null;
    final text = jsonEncode(setlist.toJson());
    return _Local(text, syncHash(text));
  }

  /// One pass over the whole library: list, decide per item, act.
  Future<void> _round(_Run run) async {
    _check(run);
    final files = await _store.listFiles();
    _check(run);
    final local = await _localSnapshot();
    final baselines = await repository.loadSyncBaselines(run.account);

    // Group cloud files by item. Foreign names are not ours and are ignored.
    final groups = <String, List<DriveFile>>{};
    for (final file in files) {
      final parsed = parseSyncFileName(file.name);
      if (parsed == null) continue;
      (groups['${parsed.kind}:${parsed.id}'] ??= []).add(file);
    }
    if (groups.length > maxItems) {
      throw const SyncException('remote_library_too_large');
    }
    final keys = {...local.keys, ...groups.keys, ...baselines.keys};
    if (keys.length > maxItems) {
      throw const SyncException('library_too_large');
    }

    final items = <_Item>[];
    for (final key in keys) {
      final split = key.indexOf(':');
      final it = _Item(key.substring(0, split), key.substring(split + 1))
        ..local = local[key]
        ..base = baselines[key];
      final group = groups[key];
      if (group != null) {
        // Two files of one name are a race on create. The newest wins, ties
        // broken by id, so every device picks the same one.
        group.sort((a, b) {
          final byTime = (a.modifiedTime ?? DateTime.utc(1970)).compareTo(
            b.modifiedTime ?? DateTime.utc(1970),
          );
          return byTime != 0 ? byTime : a.id.compareTo(b.id);
        });
        it.cloud = group.last;
        it.duplicates = group.sublist(0, group.length - 1);
        it.cloudInvalid = !_validCloud(it);
      }
      items.add(it);
    }
    items.sort((a, b) => a.key.compareTo(b.key));

    final main = {'song': <_Item>[], 'setlist': <_Item>[]};
    final deleteLocal = {'song': <_Item>[], 'setlist': <_Item>[]};
    final deleteCloud = <_Item>[];
    for (final it in items) {
      if (it.cloudInvalid) {
        run.skipCodes.add('invalid_remote_data');
        continue;
      }
      switch (_decide(run, it)) {
        case _Act.none:
          if (it.duplicates.isNotEmpty) main[it.kind]!.add(it);
        case _Act.adopt:
          run.put(
            SyncBaseline(
              kind: it.kind,
              id: it.id,
              cloudHash: it.cloud!.hash!,
              localHash: it.local!,
            ),
          );
        case _Act.forget:
          run.remove(it.key);
        case _Act.pull || _Act.push || _Act.resolve:
          main[it.kind]!.add(it);
        case _Act.deleteLocal:
          deleteLocal[it.kind]!.add(it);
        case _Act.deleteCloud:
          deleteCloud.add(it);
      }
    }
    await _guardDeletions(
      run,
      items,
      deleteLocal['song']!.length + deleteLocal['setlist']!.length,
      groups.isEmpty,
    );
    for (final kind in const ['song', 'setlist']) {
      deleteLocal[kind] = await _confirmAbsent(run, deleteLocal[kind]!);
    }
    await _flush(run);

    // Songs first, so a setlist pulled in this round finds its songs; setlists
    // are removed before the songs they point to.
    await _phase(run, main['song']!);
    await _phase(run, main['setlist']!);
    await _phase(run, deleteLocal['setlist']!);
    await _phase(run, deleteLocal['song']!);
    await _phase(run, deleteCloud);
    await _flush(run);
  }

  /// Refuses to apply a sync that would delete a large part of the library
  /// only because the cloud no longer lists it (a wiped appDataFolder, a
  /// partial listing). Nothing has been changed yet when this throws; the user
  /// decides with [confirmRemoteDeletions] or [keepLocalAfterSuspiciousListing].
  Future<void> _guardDeletions(
    _Run run,
    List<_Item> items,
    int deletes,
    bool emptyListing,
  ) async {
    if (run.replace || run.confirmDeletions || deletes == 0) return;
    final known = items.where((i) => i.base != null && i.local != null).length;
    final suspicious =
        (deletes >= _minMassDeletes && deletes * 2 > known) ||
        (emptyListing && deletes >= _minEmptyListing);
    if (!suspicious) return;
    _suspiciousKeys = {
      for (final i in items)
        if (i.base != null &&
            i.local != null &&
            i.cloud == null &&
            !i.cloudInvalid &&
            i.local == i.base!.localHash)
          i.key,
    };
    suspiciousDeletionCount = deletes;
    throw const SyncException('remote_listing_suspicious');
  }

  /// A file missing from the listing is only a deletion when a second listing
  /// agrees (Drive search can lag). Others are left for the next sync.
  Future<List<_Item>> _confirmAbsent(_Run run, List<_Item> candidates) async {
    if (candidates.isEmpty || run.replace) return candidates;
    if (!candidates.any((i) => i.cloud == null)) return candidates;
    _check(run);
    final present = <String>{};
    for (final file in await _store.listFiles()) {
      final parsed = parseSyncFileName(file.name);
      if (parsed != null) present.add('${parsed.kind}:${parsed.id}');
    }
    final result = <_Item>[];
    for (final it in candidates) {
      if (it.cloud == null && present.contains(it.key)) {
        run.pending++;
      } else {
        result.add(it);
      }
    }
    return result;
  }

  bool _validCloud(_Item it) {
    final file = it.cloud!;
    if (!isSyncHash(file.hash)) return false;
    final kind = file.properties['kind'];
    return kind == null || kind == it.kind;
  }

  _Act _decide(_Run run, _Item it) {
    final l = it.local, c = it.cloud, b = it.base;
    if (l == null && c == null) return b == null ? _Act.none : _Act.forget;
    final inReplaceScope =
        run.replaceKeys == null || run.replaceKeys!.contains(it.key);
    if (run.replace && b == null && inReplaceScope) {
      // A freshly adopted account whose library replaces the local one.
      if (c == null) return _Act.deleteLocal;
      if (l == null) return _Act.pull;
      return c.hash == l ? _Act.adopt : _Act.pull;
    }
    if (b == null) {
      // Never synced with this account.
      if (c == null) return _Act.push;
      if (l == null) return _Act.pull;
      return c.hash == l ? _Act.adopt : _Act.resolve;
    }
    if (l != null && c != null) {
      if (c.hash == l) {
        return b.cloudHash == l && b.localHash == l ? _Act.none : _Act.adopt;
      }
      final localChanged = l != b.localHash, cloudChanged = c.hash != b.cloudHash;
      if (!localChanged && !cloudChanged) return _Act.none;
      if (localChanged && !cloudChanged) return _Act.push;
      if (!localChanged && cloudChanged) return _Act.pull;
      return _Act.resolve;
    }
    if (l != null) {
      // Gone from the cloud: deleted elsewhere, unless edited here since.
      return l == b.localHash ? _Act.deleteLocal : _Act.push;
    }
    // Deleted here: delete the cloud file, unless it changed since.
    return c!.hash == b.cloudHash ? _Act.deleteCloud : _Act.pull;
  }

  static const _baselineBatch = 10;

  Future<void> _phase(_Run run, List<_Item> items) async {
    if (items.isEmpty) return;
    var next = 0;
    Object? failure;
    StackTrace? trace;
    Future<void> worker() async {
      while (failure == null) {
        final index = next++;
        if (index >= items.length) return;
        try {
          _check(run);
          await _process(run, items[index]);
          // Remember agreed uploads in small batches: a kill must not turn the
          // next edit of an uploaded item into a spurious conflict.
          if (run.puts.length >= _baselineBatch) await _flush(run);
        } catch (error, stack) {
          failure ??= error;
          trace ??= stack;
        }
      }
    }

    await Future.wait([
      for (var i = 0; i < math.min(math.max(concurrency, 1), items.length); i++)
        worker(),
    ]);
    // Downloaded items are kept even when another item failed.
    try {
      await _flushPulls(run);
    } catch (_) {
      if (failure == null) rethrow;
    }
    if (failure != null) Error.throwWithStackTrace(failure!, trace!);
  }

  Future<void> _process(_Run run, _Item it) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      if (it.cloudInvalid) {
        run.skipCodes.add('invalid_remote_data');
        return;
      }
      try {
        await _execute(run, it, _decide(run, it));
        await _dropDuplicates(run, it);
        return;
      } on _Stale {
        // Someone else changed this file after the listing: look again.
        final cloud = it.cloud;
        it.cloud = cloud == null ? null : await _store.getFile(cloud.id);
        it.cloudInvalid = it.cloud != null && !_validCloud(it);
      } on SyncException catch (e) {
        if (!_skippable.contains(e.code)) rethrow;
        run.skipCodes.add(e.code);
        return;
      }
    }
    run.skipCodes.add('remote_changed');
  }

  Future<void> _execute(_Run run, _Item it, _Act act) async {
    switch (act) {
      case _Act.none:
        return;
      case _Act.adopt:
        run.put(
          SyncBaseline(
            kind: it.kind,
            id: it.id,
            cloudHash: it.cloud!.hash!,
            localHash: it.local!,
          ),
        );
      case _Act.forget:
        run.remove(it.key);
      case _Act.push:
        await _push(run, it);
      case _Act.pull:
        await _pull(run, it);
      case _Act.resolve:
        await _resolve(run, it);
      case _Act.deleteLocal:
        await _deleteLocal(run, it);
      case _Act.deleteCloud:
        await _deleteCloud(run, it);
    }
  }

  // ---- actions ---------------------------------------------------------

  Future<void> _push(_Run run, _Item it) async {
    final local = await _readLocal(it.kind, it.id);
    if (local == null) return; // deleted meanwhile; the next sync decides
    if (utf8.encode(local.content).length > maxSyncFileBytes - 8192) {
      throw const SyncException('local_file_too_large');
    }
    final hash = syncHash(local.content);
    final properties = {'kind': it.kind, 'hash': hash};
    final cloud = it.cloud;
    if (cloud == null) {
      await _store.createFile(
        syncFileName(it.kind, it.id),
        local.content,
        properties,
      );
    } else {
      // Drive has no If-Match: re-read the metadata right before the write
      // and start over if another device got there first.
      final meta = await _store.getFile(cloud.id);
      if (meta == null || meta.version != cloud.version || meta.hash != cloud.hash) {
        throw const _Stale();
      }
      try {
        await _store.updateFile(cloud.id, local.content, properties);
      } on SyncException catch (e) {
        if (e.code == 'remote_file_missing') throw const _Stale();
        rethrow;
      }
    }
    run.uploaded++;
    run.put(
      SyncBaseline(
        kind: it.kind,
        id: it.id,
        cloudHash: hash,
        localHash: local.hash,
      ),
    );
  }

  Future<String> _download(_Item it, DriveFile file) async {
    if (file.size != null && file.size! > maxSyncFileBytes) {
      throw const SyncException('remote_file_too_large');
    }
    final String text;
    try {
      text = await _store.readFile(file.id);
    } on SyncException catch (e) {
      if (e.code == 'remote_file_missing') throw const _Stale();
      rethrow;
    }
    if (syncHash(text) != file.hash) {
      final fresh = await _store.getFile(file.id);
      if (fresh == null || fresh.version != file.version || fresh.hash != file.hash) {
        throw const _Stale(); // replaced between listing and download
      }
      throw const SyncException('invalid_remote_data');
    }
    return text;
  }

  /// A song or setlist document, validated against the item it was found for.
  Object _parse(_Item it, String text) {
    try {
      if (it.kind == 'song') {
        final song = _codec.decode(text);
        if (song.id != it.id) throw const SyncException('invalid_remote_data');
        return song;
      }
      final set = SetlistDocument.fromJson(jsonMap(jsonDecode(text)));
      if (set.id != it.id) throw const SyncException('invalid_remote_data');
      return set;
    } on SyncException {
      rethrow;
    } catch (_) {
      throw const SyncException('invalid_remote_data');
    }
  }

  Future<JsonMap> _apply(
    _Run run,
    _Item it, {
    List<Object> documents = const [],
    required Map<String, String?> expected,
    bool delete = false,
    String? cloudHash,
  }) {
    final songs = [for (final d in documents) if (d is SongDocument) d];
    final sets = [for (final d in documents) if (d is SetlistDocument) d];
    final songExpected = {
      for (final e in expected.entries)
        if (e.key.startsWith('song:')) e.key.substring(5): e.value,
    };
    final setExpected = {
      for (final e in expected.entries)
        if (e.key.startsWith('setlist:')) e.key.substring(8): e.value,
    };
    return repository.applySyncChanges(
      songs,
      sets,
      expectedSongHashes: songExpected,
      expectedSetlistHashes: setExpected,
      deletedSongIds: delete && it.kind == 'song' ? [it.id] : const [],
      deletedSetlistIds: delete && it.kind == 'setlist' ? [it.id] : const [],
      syncAccount: run.account,
      baselineCloudHashes: {it.key: cloudHash},
    );
  }

  bool _saved(JsonMap result, String kind, String id) =>
      (result[kind == 'song' ? 'savedSongIds' : 'savedSetlistIds'] as List)
          .contains(id);

  /// Downloads the cloud version; it is written to the library in batches (one
  /// transaction per [_pullBatch] items) by [_flushPulls].
  Future<void> _pull(_Run run, _Item it) async {
    final cloud = it.cloud!;
    final document = _parse(it, await _download(it, cloud));
    run.pulls.add(_Pulled(it, document, cloud.hash!));
    if (run.pulls.length >= _pullBatch) await _flushPulls(run);
  }

  static const _pullBatch = 100;

  Future<void> _flushPulls(_Run run) async {
    if (run.pulls.isEmpty) return;
    final batch = run.pulls;
    run.pulls = [];
    final result = await repository.applySyncChanges(
      [
        for (final p in batch)
          if (p.document is SongDocument) p.document as SongDocument,
      ],
      [
        for (final p in batch)
          if (p.document is SetlistDocument) p.document as SetlistDocument,
      ],
      expectedSongHashes: {
        for (final p in batch)
          if (p.item.kind == 'song') p.item.id: p.item.local,
      },
      expectedSetlistHashes: {
        for (final p in batch)
          if (p.item.kind == 'setlist') p.item.id: p.item.local,
      },
      syncAccount: run.account,
      baselineCloudHashes: {for (final p in batch) p.item.key: p.cloudHash},
    );
    for (final p in batch) {
      if (_saved(result, p.item.kind, p.item.id)) {
        run.downloaded++;
      } else {
        // Edited locally while downloading (or a setlist whose songs have not
        // arrived): nothing was overwritten; the next sync decides again.
        run.pending++;
      }
    }
  }

  Future<void> _deleteLocal(_Run run, _Item it) async {
    final result = await _apply(
      run,
      it,
      expected: {it.key: it.local},
      delete: true,
    );
    if (_saved(result, it.kind, it.id)) {
      run.deletedLocal++;
      if (it.kind == 'song') run.cascadeDeletes++;
    } else {
      run.pending++;
    }
  }

  Future<void> _deleteCloud(_Run run, _Item it) async {
    final cloud = it.cloud!;
    final meta = await _store.getFile(cloud.id);
    if (meta != null) {
      if (meta.version != cloud.version || meta.hash != cloud.hash) {
        throw const _Stale();
      }
      await _store.deleteFile(cloud.id);
    }
    run.deletedRemote++;
    run.remove(it.key);
  }

  /// Both sides changed. The cloud version stays at the original id; the local
  /// edit is kept as a copy under a derived id, so repeating the sync finds the
  /// same copy instead of making another.
  Future<void> _resolve(_Run run, _Item it) async {
    final cloud = it.cloud!;
    final document = _parse(it, await _download(it, cloud));
    final normalized = syncHash(
      document is SongDocument
          ? _codec.encode(document)
          : jsonEncode((document as SetlistDocument).toJson()),
    );
    if (normalized == it.local) {
      // Same content, only spelled differently: nothing to merge.
      run.put(
        SyncBaseline(
          kind: it.kind,
          id: it.id,
          cloudHash: cloud.hash!,
          localHash: it.local!,
        ),
      );
      return;
    }
    final local = await _readLocal(it.kind, it.id);
    if (local == null || local.hash != it.local) {
      run.pending++; // edited again while we were looking
      return;
    }
    final copyId = conflictDocumentId(it.id, local.hash);
    final Object copy;
    try {
      copy = it.kind == 'song'
          ? _songCopy(
              _codec.decode(local.content),
              copyId,
              cloud.hash!,
              'concurrent_edit',
            )
          : _setlistCopy(
              SetlistDocument.fromJson(jsonMap(jsonDecode(local.content))),
              copyId,
            );
    } on FormatException {
      // A damaged local document is a local problem, not remote data.
      throw const SyncException('invalid_local_data');
    }
    final result = await _apply(
      run,
      it,
      documents: [copy, document],
      expected: {'${it.kind}:$copyId': null, it.key: it.local},
      cloudHash: cloud.hash,
    );
    if (!_saved(result, it.kind, it.id)) {
      run.pending++;
      return;
    }
    run.downloaded++;
    run.conflicts++;
    if (_saved(result, it.kind, copyId)) {
      await _pushNew(run, it.kind, copyId);
    }
  }

  SongDocument _songCopy(
    SongDocument song,
    String copyId,
    String remoteHash,
    String reason,
  ) => song.copyWith(
    id: copyId,
    extra: {
      ...song.extra,
      'syncConflict': {
        'originalId': song.id,
        'remoteHash': remoteHash,
        'reason': reason,
      },
    },
    revision: song.revision,
    updatedAt: song.updatedAt,
  );

  SetlistDocument _setlistCopy(SetlistDocument set, String copyId) =>
      SetlistDocument(
        id: copyId,
        name: '${set.name} [${copyId.substring(copyId.length - 6)}]',
        notes: set.notes,
        favorite: set.favorite,
        entries: [
          for (var i = 0; i < set.entries.length; i++)
            SetlistEntry(
              id: syncHash('$copyId:$i').substring(0, 32),
              songId: set.entries[i].songId,
              overrides: set.entries[i].overrides,
            ),
        ],
        createdAt: set.createdAt,
        updatedAt: set.updatedAt,
      );

  /// Uploads a local item that has no cloud file yet (a fresh conflict copy).
  /// A failure is not an error: the item simply uploads on the next sync.
  Future<void> _pushNew(_Run run, String kind, String id) async {
    final local = await _readLocal(kind, id);
    if (local == null) return;
    final it = _Item(kind, id)..local = local.hash;
    try {
      await _push(run, it);
    } on SyncException catch (e) {
      if (!_skippable.contains(e.code) &&
          e.code != 'network' &&
          e.code != 'rate_limited') {
        rethrow;
      }
    }
  }

  /// Two files of one name: the newest was chosen. An older one with content
  /// we already know is deleted; one with unknown content is first kept as a
  /// conflict copy, so a race on create never loses an edit.
  Future<void> _dropDuplicates(_Run run, _Item it) async {
    if (it.duplicates.isEmpty) return;
    final known = <String?>{
      it.cloud?.hash,
      it.local,
      it.base?.cloudHash,
      it.base?.localHash,
    }.whereType<String>().toSet();
    for (final extra in List.of(it.duplicates)) {
      if (!isSyncHash(extra.hash)) continue; // untrusted: leave it alone
      if (!known.contains(extra.hash)) {
        try {
          final document = _parse(it, await _download(it, extra));
          final copyId = conflictDocumentId(it.id, extra.hash!);
          final copy = document is SongDocument
              ? _songCopy(document, copyId, extra.hash!, 'duplicate_create')
              : _setlistCopy(document as SetlistDocument, copyId);
          final result = await _apply(
            run,
            _Item(it.kind, copyId),
            documents: [copy],
            expected: {'${it.kind}:$copyId': null},
            cloudHash: null,
          );
          if (_saved(result, it.kind, copyId)) {
            run.conflicts++;
            await _pushNew(run, it.kind, copyId);
          }
        } on SyncException catch (e) {
          if (e.code == 'remote_file_missing') continue;
          continue; // unreadable: keep the file, retry next sync
        } on _Stale {
          continue;
        }
      }
      await _store.deleteFile(extra.id);
    }
    it.duplicates = [];
  }

  void close() {
    final store = _activeStore;
    if (_providedStore == null && store is DriveAppDataStore) {
      store.close();
    }
  }
}
