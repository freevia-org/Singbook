import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemException;
import 'package:archive/archive.dart' show ArchiveException;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart' show XmlException;
import '../data/library_repository.dart';
import '../domain/models.dart';
import '../domain/chordpro.dart';
import '../domain/combine.dart';
import '../providers/provider.dart';
import '../providers/core/core_providers.dart';
import '../providers/extra/extra_providers.dart';
import '../providers/source_catalog.dart';
import '../providers/source_catalog_client.dart';
import '../providers/configurable_provider.dart';
import 'file_actions.dart';
import '../sync/google_drive_sync.dart';
import 'youtube_music_consent.dart';
import '../providers/youtube_music_session.dart';

/// A user-visible outcome of an operation, identified by a stable [code] (never
/// free text, never containing credentials) that the UI maps to a localized
/// string. [operation] names what was attempted: `import`, `share`, `save`,
/// `delete`, `sync`, `setlist`.
class AppMessage {
  const AppMessage(this.code, {this.operation = 'operation', this.isError = true});
  final String code, operation;

  /// False for warnings that did not lose data (for example `save_conflict`).
  final bool isError;
  @override
  String toString() => 'AppMessage($operation:$code)';
}

class _AutoSyncTiming {
  const _AutoSyncTiming(
    this.delay,
    this.startDelay,
    this.staleAfter,
    this.backoff,
    this.maxBackoff,
  );
  final Duration delay, startDelay, staleAfter, backoff, maxBackoff;
}

/// Owns durable application state; navigation and player clock stay in the UI.
class AppController extends ChangeNotifier {
  /// Automatic sync timing (all adjustable for tests):
  ///  * [autoSyncDelay]: quiet period after the last local change;
  ///  * [autoSyncStartDelay]: wait after start / sign-in / resume before the
  ///    first run, so it never competes with the first frame;
  ///  * [autoSyncStaleAfter]: start and resume only sync when the last
  ///    successful sync is older than this;
  ///  * [autoSyncBackoff] / [autoSyncMaxBackoff]: after a retryable failure
  ///    the next attempt waits backoff * 2^(failures - 1), capped.
  factory AppController({
    LibraryRepository? repository,
    SourceDiscoveryService? discovery,
    GoogleDriveSyncService? sync,
    YoutubeMusicConsent? youtubeMusicConsent,
    Duration autoSyncDelay = const Duration(seconds: 25),
    Duration autoSyncStartDelay = const Duration(seconds: 3),
    Duration autoSyncStaleAfter = const Duration(minutes: 5),
    Duration autoSyncBackoff = const Duration(seconds: 30),
    Duration autoSyncMaxBackoff = const Duration(minutes: 15),
  }) {
    final timing = _AutoSyncTiming(
      autoSyncDelay,
      autoSyncStartDelay,
      autoSyncStaleAfter,
      autoSyncBackoff,
      autoSyncMaxBackoff,
    );
    final consent = youtubeMusicConsent ?? YoutubeMusicConsent();
    if (discovery != null) {
      return AppController._(repository, discovery, null, sync, timing, consent);
    }
    final transport = ProviderTransport();
    return AppController._(
      repository,
      _createDiscovery(transport, consent.session),
      transport,
      sync,
      timing,
      consent,
    );
  }

  AppController._(
    this._repository,
    this.discovery,
    this._ownedTransport,
    this._sync,
    this._timing,
    this.youtubeMusicConsent,
  );
  final _AutoSyncTiming _timing;
  final YoutubeMusicConsent youtubeMusicConsent;

  static SourceDiscoveryService _createDiscovery(
    ProviderTransport transport,
    YoutubeMusicSession youtubeMusicSession,
  ) {
    return SourceDiscoveryService([
      ...createCoreProviders(transport: transport, youtubeMusicSession: youtubeMusicSession),
      ...createExtraProviders(transport: transport),
    ]);
  }

  final ProviderTransport? _ownedTransport;
  LibraryRepository? _repository;
  bool _ownsRepository = false;
  LibraryRepository get repository => _repository!;
  final SourceDiscoveryService discovery;
  List<SongDocument> songs = [];
  List<SetlistDocument> setlists = [];
  JsonMap settings = {};
  List<ActivityEntry> recent = [];
  Future<void> _recentQueue = Future.value();
  bool hasMoreRecent = true;
  List<ProviderDefinition> get providers => discovery.definitions;
  bool sourcesRefreshing = false;
  String? sourceRefreshError;
  Future<bool>? _sourceRefreshFuture;
  String query = '';
  List<SongCandidate> suggestions = [];
  SongCandidate? selection;
  List<SourceResult> results = [];
  SongDocument? combined;
  final Map<String, ProviderCheck> checks = {};
  bool searching = false, discovering = false, initialized = false;
  String? errorCode;
  GoogleDriveSyncService? _sync;
  bool get syncConfigured => _sync?.configured ?? false;
  bool get syncConnected => _sync?.isConnected ?? false;
  String? get syncAccountEmail => _sync?.accountEmail;
  bool syncBusy = false;

  /// Code of the first unusable remote/local file the last (otherwise
  /// successful) sync skipped, or null. Mirrors what [syncError] also reports
  /// for such a sync, without meaning that the sync failed.
  String? syncWarning;

  /// While [syncError] is `remote_listing_suspicious`: how many local items the
  /// refused sync would have deleted.
  int get syncSuspiciousDeletionCount => _sync?.suspiciousDeletionCount ?? 0;

  /// Stable code of the last sync problem (see [lastSyncErrorCode]), or null.
  String? syncError;
  SyncReport? syncReport;

  /// When the signed-in account last synced successfully (persisted per
  /// account), or null if never / signed out.
  DateTime? lastSyncAt;

  /// Concurrent edits the last sync kept as separate copies.
  int lastSyncConflicts = 0;

  /// Stable code of the last sync problem, or null:
  /// `not_configured`, `not_signed_in`, `authorization_required`,
  /// `access_denied`, `rate_limited`, `storage_full`, `network`,
  /// `account_changed`, `remote_library_too_large`, `library_too_large`,
  /// `remote_file_too_large`, `invalid_remote_data`, `local_file_too_large`,
  /// `sign_in_failed`, `sync_failed`, `not_initialized`,
  /// `remote_listing_suspicious` (the cloud no longer lists many items that
  /// were synced before; nothing was deleted, see [confirmRemoteDeletions] and
  /// [keepLocalAfterRemoteDeletions]), `no_account_change`.
  /// `remote_file_too_large` / `invalid_remote_data` mean the sync completed
  /// but left some unusable remote files untouched.
  String? get lastSyncErrorCode => syncError;

  /// E-mail of the account this library was synced with before, while
  /// [lastSyncErrorCode] is `account_changed`; for the "switch account" choice
  /// (see [adoptAccount]).
  String? syncPreviousAccountEmail;

  /// True while the signed-in account differs from the one this library syncs
  /// with and the user has not chosen yet ([adoptAccount]).
  bool get syncAccountChangePending => syncError == 'account_changed';

  /// Automatic sync is on unless the user switched it off (default on).
  bool get autoSyncEnabled => settings['autoSync'] != false;
  Timer? _autoTimer;
  int _autoFailures = 0, _pendingRetries = 0;
  DateTime? _backoffUntil;
  bool _changedDuringSync = false;
  int _searchEpoch = 0, _discoveryEpoch = 0;
  CancellationToken? _searchCancel, _discoveryCancel;
  bool _disposed = false;
  Future<void>? _activeSyncAction;
  final Map<String, String> _savedSources = {};
  final Map<String, String> _savedCombined = {};
  Map<String, String> _songHashes = {};
  Map<String, String> _setlistHashes = {};
  int _writesSinceCompaction = 0;

  /// Most recent outcome worth showing to the user, or null. Listen to it to
  /// surface import/share/save/delete/sync failures; each new message is a new
  /// object, so listeners fire even when the code repeats. Codes are stable
  /// identifiers such as `file_too_large`, `invalid_archive`, `save_conflict`,
  /// `setlist_missing`, `not_initialized`, or a `SyncException.code`.
  final ValueNotifier<AppMessage?> messages = ValueNotifier<AppMessage?>(null);
  AppMessage? get lastMessage => messages.value;

  /// Stable code of the last *error* (null when the last message was a warning
  /// or there is none).
  String? get lastErrorCode {
    final message = messages.value;
    return message != null && message.isError ? message.code : null;
  }

  void clearMessage() {
    if (!_disposed && messages.value != null) messages.value = null;
  }

  /// Records a message for the UI. A no-op after dispose.
  void postMessage(
    String code, {
    String operation = 'operation',
    bool isError = true,
  }) {
    if (_disposed) return;
    messages.value = AppMessage(code, operation: operation, isError: isError);
  }

  /// Records [error] for the UI under a stable code and returns that code.
  String reportError(Object error, {String operation = 'operation'}) {
    final code = errorCodeFor(error);
    postMessage(code, operation: operation);
    return code;
  }

  /// Runs [action]; on failure posts a message and returns null instead of
  /// throwing. For UI call sites that only need "show an error and carry on",
  /// such as share and print.
  Future<T?> guarded<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      reportError(error, operation: operation);
      return null;
    }
  }

  static const _knownCodes = {
    'file_too_large',
    'empty_file',
    'invalid_timing',
    'unsupported_file',
    'too_many_songs',
    'invalid_archive',
    'invalid_archive_hash',
    'invalid_archive_identity',
    'unsupported_archive',
    'missing_song_references',
    'invalid_xml',
    'backup_too_large',
    'invalid_encoding',
    'discovery_in_progress',
    'no_result',
    'invalid_source',
    'not_initialized',
  };

  /// Maps any exception to a stable, non-sensitive code.
  static String errorCodeFor(Object error) {
    if (error is SyncException) return error.code;
    if (error is ProviderException) return error.code;
    if (error is XmlException) return 'invalid_xml';
    if (error is ArchiveException) return 'invalid_archive';
    if (error is FormatException) {
      return _knownCodes.contains(error.message) ? error.message : 'invalid_file';
    }
    if (error is StateError) {
      return _knownCodes.contains(error.message) ? error.message : 'invalid_state';
    }
    if (error is FileSystemException) return 'file_error';
    if (error.runtimeType.toString().contains('DatabaseException')) {
      return 'database_error';
    }
    return 'unknown_error';
  }

  Future<T> _tracked<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      reportError(error, operation: operation);
      rethrow;
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void>? _initializing;

  Future<void> initialize() {
    // Two overlapping calls must not open the database twice.
    final running = _initializing;
    if (running != null) return running;
    final attempt = _initialize();
    _initializing = attempt;
    return attempt.whenComplete(() {
      if (identical(_initializing, attempt)) _initializing = null;
    });
  }

  Future<void> _initialize() async {
    if (_disposed) return;
    if (_repository == null) {
      final opened = await LibraryRepository.open();
      if (_disposed) {
        await opened.close();
        return;
      }
      _repository = opened;
      _ownsRepository = true;
    }
    _sync ??= GoogleDriveSyncService(repository: repository);
    settings = jsonMap(await repository.getSetting('app'));
    if (_disposed) return;
    await youtubeMusicConsent.restore();
    if (_disposed) return;
    await _initializeSourceCatalog();
    if (_disposed) return;
    await _reload();
    if (_disposed) return;
    recent = await repository.listRecentActivity(limit: 40);
    if (_disposed) return;
    hasMoreRecent = recent.length == 40;
    _indexSaved();
    unawaited(compactOutbox().then<void>((_) {}, onError: (Object _) {}));
    initialized = true;
    _emit();
    if (discovery.catalogClient != null) {
      unawaited(refreshSources(silent: true));
    }
    if (syncConfigured) {
      await restoreSync();
    }
  }

  /// Silently restores a previous sign-in (no UI). Never throws. When it
  /// succeeds and the last sync is old, an automatic sync is scheduled.
  Future<void> restoreSync() async {
    final sync = _sync;
    if (sync == null || _disposed) return;
    try {
      if (await sync.restore()) await _afterSignIn(startup: true);
    } catch (error) {
      syncError = error is SyncException ? error.code : 'sync_failed';
    }
    _emit();
  }

  /// Common state after a sign-in or a restored session.
  Future<void> _afterSignIn({bool startup = false}) async {
    final sync = _sync!;
    lastSyncAt = await sync.lastSuccessfulSync();
    if (await sync.hasAccountMismatch()) {
      syncPreviousAccountEmail = await sync.previousAccountEmail();
      syncError = 'account_changed';
      return;
    }
    syncPreviousAccountEmail = null;
    if (syncError == 'account_changed') syncError = null;
    // Edits are recorded in the outbox until a sync acknowledges them, so a
    // change made just before the app was killed still triggers a sync.
    if (!startup || _isStale() || await repository.outboxMark() > 0) {
      _scheduleAutoSync(after: _timing.startDelay);
    }
  }

  bool _isStale() {
    final last = lastSyncAt;
    if (last == null) return true;
    final age = DateTime.now().toUtc().difference(last);
    // A last sync "in the future" means the clock moved back: sync again.
    return age.isNegative || age > _timing.staleAfter;
  }

  int _reloadEpoch = 0;
  Future<void>? _latestReload;

  /// Reloads the cached library. Overlapping reloads are sequenced: only the
  /// newest one publishes, so an older snapshot (and its hashes) can never
  /// replace a newer one; an older call waits for the newest to finish.
  Future<void> _reload() {
    final epoch = ++_reloadEpoch;
    final run = _loadSnapshot(epoch);
    _latestReload = run;
    return run.then((_) => _latestReload ?? run);
  }

  Future<void> _loadSnapshot(int epoch) async {
    final loadedSongs = await repository.listSongs();
    final loadedSetlists = await repository.listSetlists();
    final hashRows = await repository.database.query(
      'songs',
      columns: ['id', 'content_hash'],
    );
    if (_disposed || epoch != _reloadEpoch) return;
    songs = loadedSongs;
    setlists = loadedSetlists;
    _songHashes = {
      for (final row in hashRows) row['id'] as String: row['content_hash'] as String,
    };
    _setlistHashes = {
      for (final set in loadedSetlists) set.id: _setlistHash(set),
    };
  }

  static String _setlistHash(SetlistDocument set) =>
      sha256.convert(utf8.encode(jsonEncode(set.toJson()))).toString();

  /// Content hash of the stored song as of the last reload. Pass it back as
  /// `baseHash` to [saveSong] when an edit session started earlier than the
  /// latest reload, so a background change is detected.
  String? songHash(String id) => _songHashes[id];
  String? setlistHash(String id) => _setlistHashes[id];

  void _indexSaved() {
    _savedSources.clear();
    _savedCombined.clear();
    for (final song in songs) {
      final source = song.extra['savedSourceId'];
      if (source is String) _savedSources[source] = song.id;
      final key = song.extra['combinedSelection'];
      if (key is String) _savedCombined[key] = song.id;
    }
  }

  /// Cached lookup for synchronous UI code; may lag the database by one
  /// reload. Use [loadSong] when correctness matters.
  SongDocument? findSong(String id) {
    for (final song in songs) {
      if (song.id == id) return song;
    }
    return null;
  }

  /// Authoritative lookup straight from the database.
  Future<SongDocument?> loadSong(String id) => repository.getSong(id);

  bool providerEnabled(String id) => !providers.any((p) => p.id == id)
      ? false
      : (settings['providers'] is Map &&
            (settings['providers'] as Map)[id] is bool)
      ? (settings['providers'] as Map)[id] as bool
      : providers.firstWhere((p) => p.id == id).enabledByDefault;

  Future<void> _initializeSourceCatalog() async {
    final transport = _ownedTransport;
    if (discovery.catalogClient == null && transport != null) {
      final runtime = SourceCatalogRuntime(
        builtins: discovery.providers,
        createProvider: (entry) {
          ConfigurableProvider.validateExtraction(entry);
          return ConfigurableProvider(entry, transport);
        },
      );
      discovery.catalogClient = SourceCatalogClient(
        runtime: runtime,
        transport: transport,
        loadBundled: () => rootBundle.loadString('config/source-catalog.json'),
        readCache: () async {
          final value = await repository.getSetting('sourceCatalog');
          return value is String ? value : null;
        },
        writeCache: (value) => repository.setSetting('sourceCatalog', value),
      );
    }
    await discovery.catalogClient?.initialize();
  }

  /// Preferences and saved song provenance survive provider retirement.
  /// Existing searches use their original snapshot; their results are cancelled
  /// before a newly downloaded catalog is exposed to the UI.
  Future<bool> refreshSources({bool silent = false}) =>
      _sourceRefreshFuture ??= _refreshSources(
        silent: silent,
      ).whenComplete(() => _sourceRefreshFuture = null);

  Future<bool> _refreshSources({required bool silent}) async {
    if (_disposed) return false;
    final client = discovery.catalogClient;
    if (client == null) return false;
    sourcesRefreshing = true;
    sourceRefreshError = null;
    _emit();
    final previous = client.runtime.catalog?.revision;
    final success = await client.refresh();
    if (_disposed) return false;
    if (success && previous != client.runtime.catalog?.revision) {
      cancelSearch();
    }
    sourcesRefreshing = false;
    sourceRefreshError = client.lastErrorCode;
    if (!silent && !success) {
      messages.value = const AppMessage('refresh_failed', operation: 'sources');
    }
    _emit();
    return success;
  }

  Future<void> setProviderEnabled(String id, bool enabled) async {
    await setSetting('providers', {
      ...jsonMap(settings['providers']),
      id: enabled,
    });
  }

  Future<void> setSetting(String key, dynamic value) async {
    settings = {...settings, key: value};
    await repository.setSetting('app', settings);
    _emit();
  }

  Future<void> search(String value) async {
    final epoch = ++_searchEpoch;
    _searchCancel?.cancel();
    if (value != query) {
      selection = null;
      cancelDiscovery();
      suggestions = [];
    }
    query = value;
    if (value.trim().isEmpty) {
      suggestions = [];
      searching = false;
      selection = null;
      cancelDiscovery();
      _emit();
      return;
    }
    final cancellation = _searchCancel = CancellationToken();
    searching = true;
    errorCode = null;
    _emit();
    try {
      final requested = settings['catalog'] as String? ?? 'genius';
      final available = providers.where(
        (p) => p.capabilities.contains('catalog'),
      );
      final catalog = providers.any((p) => p.id == requested)
          ? requested
          : available.isNotEmpty
          ? available.first.id
          : providers.isNotEmpty
          ? providers.first.id
          : requested;
      final found = await discovery.search(
        value.trim(),
        providerId: catalog,
        cancel: cancellation,
      );
      if (epoch != _searchEpoch || _disposed) return;
      suggestions = found;
    } catch (error) {
      if (epoch != _searchEpoch || _disposed) return;
      errorCode = error is ProviderException ? error.code : 'search_failed';
    } finally {
      if (epoch == _searchEpoch) {
        searching = false;
        _emit();
      }
    }
  }

  void cancelSearch() {
    ++_searchEpoch;
    _searchCancel?.cancel();
    searching = false;
    suggestions = [];
    selection = null;
    cancelDiscovery();
    _emit();
  }

  void cancelDiscovery() {
    ++_discoveryEpoch;
    _discoveryCancel?.cancel();
    discovering = false;
    results = [];
    combined = null;
    checks.clear();
    _cachedDiscoverySourceIds = const {};
  }

  Set<String> _cachedDiscoverySourceIds = const {};

  /// Chord arrangements receive a final lyric-agreement check after providers
  /// finish. Plain lyrics and previously saved sources can be opened sooner.
  bool isSourceReady(SourceResult source) =>
      !discovering ||
      !source.hasChords ||
      _cachedDiscoverySourceIds.contains(source.id);

  Future<void> selectCandidate(
    SongCandidate candidate, {
    String? searchQuery,
    List<SourceResult> cachedResults = const [],
  }) async {
    ++_searchEpoch;
    _searchCancel?.cancel();
    searching = false;
    suggestions = [];
    cancelDiscovery();
    final epoch = _discoveryEpoch;
    final cancellation = _discoveryCancel = CancellationToken();
    selection = candidate;
    if (searchQuery != null) query = searchQuery;
    // Saved provenance remains available during refresh, including offline.
    // Fresh results replace only the matching cached source by identity.
    final cached = {
      for (final source in cachedResults) source.id: _snapshotSource(source),
    }.values.toList();
    _cachedDiscoverySourceIds = cached.map((source) => source.id).toSet();
    results = cached;
    discovering = true;
    _combine(candidate);
    errorCode = null;
    _emit();
    try {
      final found = await discovery.discover(
        candidate,
        enabledIds: providers
            .where((p) => providerEnabled(p.id))
            .map((p) => p.id)
            .toSet(),
        cancel: cancellation,
        onProgress: (check) {
          if (epoch != _discoveryEpoch || _disposed) return;
          checks[check.providerId] = check;
          final result = check.result;
          if (result != null &&
              !(result.hasChords && _cachedDiscoverySourceIds.contains(result.id))) {
            results = [
              ...results.where((item) => item.id != result.id),
              result,
            ];
            _combine(candidate);
          }
          _emit();
        },
      );
      if (epoch != _discoveryEpoch || _disposed) return;
      results = {
        for (final source in cached) source.id: source,
        for (final source in found) source.id: source,
      }.values.toList();
      _combine(candidate);
    } catch (error) {
      if (epoch != _discoveryEpoch || _disposed) return;
      errorCode = error is ProviderException ? error.code : 'discovery_failed';
    } finally {
      if (epoch == _discoveryEpoch) {
        discovering = false;
        _combine(candidate);
        _emit();
      }
    }
  }

  void _combine(SongCandidate candidate) {
    final usable = results.where(
      (r) =>
          r.matchKind != MatchKind.rejected &&
          r.body.trim().isNotEmpty &&
          isSourceReady(r),
    );
    try {
      combined = usable.isEmpty
          ? null
          : combineSources(candidate, results.where(isSourceReady).toList());
    } on FormatException {
      combined = null;
    }
  }

  String? savedResultId({SourceResult? source}) => source != null
      ? _savedSources[source.id]
      : selection == null
      ? null
      : _savedCombined[selection!.identity];
  Future<SongDocument> saveResult({SourceResult? source}) {
    // Capture the complete decision synchronously. Discovery may publish more
    // sources, or the user may select another candidate, while the tracked
    // save is waiting to write to the library.
    final selectedSnapshot = selection == null
        ? null
        : _snapshotCandidate(selection!);
    final resultSnapshots = results
        .where(isSourceReady)
        .map(_snapshotSource)
        .toList(growable: false);
    final requestedSourceId = source?.id;

    return _tracked('save', () async {
      final selected = selectedSnapshot;
      if (selected == null) throw StateError('no_result');
      SourceResult? selectedSource;
      if (requestedSourceId != null) {
        for (final result in resultSnapshots) {
          if (result.id == requestedSourceId) {
            selectedSource = result;
            break;
          }
        }
        if (selectedSource == null ||
            selectedSource.matchKind == MatchKind.rejected ||
            selectedSource.body.trim().isEmpty) {
          throw StateError('invalid_source');
        }
      }
      final existingId = selectedSource == null
          ? _savedCombined[selected.identity]
          : _savedSources[selectedSource.id];
      // combineSources also checks song identity and arrangement usability.
      // For a source save this allows a ready result even while other provider
      // checks are still running.
      final document = combineSources(
        selected,
        resultSnapshots,
        preferredSourceId: selectedSource?.id,
      );
      final song = document.copyWith(
        extra: {
          ...document.extra,
          if (selectedSource != null) 'savedSourceId': selectedSource.id,
          if (selectedSource == null) 'combinedSelection': selected.identity,
        },
        revision: 1,
      );
      final saved = await repository.saveImportedSong(
        song,
        existingId: existingId,
      );
      await _afterWrite();
      return saved;
    });
  }

  SongCandidate _snapshotCandidate(SongCandidate candidate) =>
      SongCandidate.fromJson(
        _snapshotJsonMap(candidate.toJson()),
      );

  SourceResult _snapshotSource(SourceResult source) =>
      SourceResult.fromJson(_snapshotJsonMap(source.toJson()));

  JsonMap _snapshotJsonMap(Map<String, dynamic> value) => {
    for (final entry in value.entries)
      entry.key: _snapshotJsonValue(entry.value),
  };

  Object? _snapshotJsonValue(Object? value) {
    if (value is Map<String, dynamic>) return _snapshotJsonMap(value);
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key as String: _snapshotJsonValue(entry.value),
      };
    }
    if (value is List) {
      return [for (final item in value) _snapshotJsonValue(item)];
    }
    return value;
  }

  Future<void> _afterWrite({bool songsChanged = true}) async {
    await _reload();
    if (songsChanged) _indexSaved();
    _emit();
    _noteLocalChange();
    if (++_writesSinceCompaction >= 50) {
      _writesSinceCompaction = 0;
      unawaited(compactOutbox().then<void>((_) {}, onError: (Object _) {}));
    }
  }

  /// Collapses the change queue to the newest row per object. Without an
  /// account the queue is never acknowledged and would otherwise grow with
  /// every save. Sync decides by content hash and acknowledges by object, so
  /// keeping only the latest row loses nothing. Returns the rows removed.
  Future<int> compactOutbox() async {
    if (_disposed || _repository == null) return 0;
    return repository.database.rawDelete(
      'DELETE FROM outbox WHERE rowid NOT IN '
      '(SELECT MAX(rowid) FROM outbox GROUP BY object_kind, object_id)',
    );
  }

  /// Saves [song]. If the stored song changed since this controller last loaded
  /// it (or since [baseHash], when given) - for example a background sync
  /// applied a newer version - the stored version is kept and the edit is saved
  /// as a separate conflict copy instead of overwriting it. Returns true when
  /// saved in place; false when a conflict copy was written (a `save_conflict`
  /// message is posted).
  Future<bool> saveSong(SongDocument song, {String? baseHash}) =>
      _tracked('save', () async {
        final expected = baseHash ?? _songHashes[song.id];
        // Atomic compare-and-set: a stale save never overwrites, even when a
        // sync lands between the check and the write.
        if (!await repository.saveSongIfUnchanged(
          song,
          expected,
          mustNotExist: expected == null,
        )) {
          final text = ChordProCodec().encode(song);
          final copyId = conflictDocumentId(
            song.id,
            sha256.convert(utf8.encode(text)).toString(),
          );
          await repository.saveSong(
            song.copyWith(
              id: copyId,
              extra: {
                ...song.extra,
                'syncConflict': {
                  'originalId': song.id,
                  'reason': 'stale_save',
                },
              },
              revision: song.revision,
              updatedAt: song.updatedAt,
            ),
          );
          await _afterWrite();
          postMessage('save_conflict', operation: 'save', isError: false);
          return false;
        }
        await _afterWrite();
        return true;
      });

  Future<void> deleteSong(String id) => _tracked('delete', () async {
    await repository.deleteSong(id);
    await _reload();
    _indexSaved();
    recent.removeWhere(
      (event) => event.objectKind == 'song' && event.objectId == id,
    );
    _emit();
    _noteLocalChange();
  });

  /// Toggles relative to the stored song, so a concurrent background change is
  /// not overwritten with a stale snapshot.
  Future<void> toggleFavorite(SongDocument song) => _tracked('save', () async {
    // Read-modify-write as compare-and-set; a background sync landing in
    // between makes it retry on the newer stored song instead of overwriting.
    var saved = false;
    for (var attempt = 0; attempt < 4 && !saved; attempt++) {
      final hash = await repository.getSongHash(song.id);
      final current = await repository.getSong(song.id) ?? song;
      saved = await repository.saveSongIfUnchanged(
        current.copyWith(favorite: !current.favorite),
        hash,
        mustNotExist: hash == null,
      );
    }
    await _afterWrite();
    if (!saved) postMessage('save_conflict', operation: 'save', isError: false);
  });

  /// Saves [setlist]; like [saveSong], a stale snapshot never overwrites a
  /// newer stored setlist but is kept as a conflict copy. Returns true when
  /// saved in place.
  Future<bool> saveSetlist(SetlistDocument setlist, {String? baseHash}) =>
      _tracked('save', () async {
        final expected = baseHash ?? _setlistHashes[setlist.id];
        if (!await repository.saveSetlistIfUnchanged(
          setlist,
          expected,
          mustNotExist: expected == null,
        )) {
          final copyId = conflictDocumentId(
            setlist.id,
            _setlistHash(setlist),
          );
          await repository.saveSetlist(
            SetlistDocument(
              id: copyId,
              name: '${setlist.name} [${copyId.substring(copyId.length - 6)}]',
              notes: setlist.notes,
              favorite: setlist.favorite,
              entries: [
                for (var i = 0; i < setlist.entries.length; i++)
                  SetlistEntry(
                    id: _stableId('$copyId:$i'),
                    songId: setlist.entries[i].songId,
                    overrides: setlist.entries[i].overrides,
                  ),
              ],
              createdAt: setlist.createdAt,
              updatedAt: setlist.updatedAt,
            ),
          );
          await _afterWrite(songsChanged: false);
          postMessage('save_conflict', operation: 'save', isError: false);
          return false;
        }
        await _afterWrite(songsChanged: false);
        return true;
      });

  Future<void> deleteSetlist(String id) => _tracked('delete', () async {
    await repository.deleteSetlist(id);
    await _reload();
    recent.removeWhere(
      (event) => event.objectKind == 'setlist' && event.objectId == id,
    );
    _emit();
    _noteLocalChange();
  });

  Future<void> toggleSetlistFavorite(SetlistDocument value) =>
      _tracked('save', () async {
        var saved = false;
        for (var attempt = 0; attempt < 4 && !saved; attempt++) {
          final stored = await repository.getSetlist(value.id);
          final current = stored ?? value;
          saved = await repository.saveSetlistIfUnchanged(
            SetlistDocument(
              id: current.id,
              name: current.name,
              notes: current.notes,
              entries: current.entries,
              favorite: !current.favorite,
              createdAt: current.createdAt,
            ),
            stored == null ? null : _setlistHash(stored),
            mustNotExist: stored == null,
          );
        }
        await _afterWrite(songsChanged: false);
        if (!saved) {
          postMessage('save_conflict', operation: 'save', isError: false);
        }
      });

  /// Appends [songId] to the stored setlist. Returns false (and posts
  /// `setlist_missing`) when the setlist no longer exists, e.g. because a sync
  /// or another action deleted it.
  Future<bool> addToSetlist(String songId, String setlistId) =>
      _tracked('setlist', () async {
        for (var attempt = 0; attempt < 4; attempt++) {
          final value = await repository.getSetlist(setlistId);
          if (value == null) {
            postMessage('setlist_missing', operation: 'setlist');
            return false;
          }
          if (await repository.saveSetlistIfUnchanged(
            SetlistDocument(
              id: value.id,
              name: value.name,
              notes: value.notes,
              favorite: value.favorite,
              createdAt: value.createdAt,
              entries: [
                ...value.entries,
                SetlistEntry(id: newId(), songId: songId),
              ],
            ),
            _setlistHash(value),
          )) {
            await _afterWrite(songsChanged: false);
            return true;
          }
        }
        // Kept changing underneath us; nothing was overwritten.
        postMessage('save_conflict', operation: 'setlist', isError: false);
        return false;
      });

  // A visit can move a group across a page boundary. Keep paging, refreshes
  // and clearing in call order so an old page cannot skip or restore groups.
  Future<void> _updateRecent(Future<void> Function() action) {
    final result = _recentQueue.then((_) async {
      if (!_disposed) await action();
    });
    _recentQueue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> recordUse(String kind, String id) => _updateRecent(() async {
    final entry = ActivityEntry(
      id: newId(),
      objectId: id,
      objectKind: kind,
      action: 'opened',
      occurredAt: DateTime.now().toUtc(),
    );
    await repository.addActivity(entry);
    final visibleLimit = recent.length < 40 ? 40 : recent.length;
    recent = await repository.listRecentActivity(limit: visibleLimit);
    hasMoreRecent = recent.length == visibleLimit;
    _emit();
  });

  Future<void> loadMoreRecent() => _updateRecent(() async {
    if (!hasMoreRecent) return;
    final next = await repository.listRecentActivity(
      offset: recent.length,
      limit: 40,
    );
    recent = {
      for (final entry in [...recent, ...next])
        (entry.objectKind, entry.objectId): entry,
    }.values.toList();
    hasMoreRecent = next.length == 40;
    _emit();
  });

  Future<void> clearHistory() => _updateRecent(() async {
    await repository.clearActivity();
    recent = [];
    hasMoreRecent = false;
    _emit();
  });

  // ---- Google Drive sync ------------------------------------------------

  /// Interactive sign-in (call from a button). Sign-in alone uploads nothing:
  /// with automatic sync on, the first sync starts a moment later; with it off,
  /// the user taps Sync now. Cancelling the account picker is not an error.
  /// If the account differs from the one this library syncs with, the state
  /// becomes `account_changed` until [adoptAccount] is called.
  Future<void> connectSync() => _runSyncAction(() async {
    try {
      await _sync!.connect();
    } on SyncException catch (error) {
      if (error.code == 'cancelled') return;
      rethrow;
    }
    _autoFailures = 0;
    _backoffUntil = null;
    await _afterSignIn();
  });

  /// Alias of [connectSync] under the name the account UI uses.
  Future<void> signInForSync() => connectSync();

  /// Signs out on this device. The local library and the cloud files are kept;
  /// signing in again with the same account continues where it stopped.
  Future<void> disconnectSync() => _runSyncAction(() async {
    _cancelAutoSync();
    await _sync!.disconnect();
    lastSyncAt = null;
    lastSyncConflicts = 0;
    syncPreviousAccountEmail = null;
    _autoFailures = 0;
    _backoffUntil = null;
  });

  /// Alias of [disconnectSync] under the name the account UI uses.
  Future<void> signOutFromSync() => disconnectSync();

  Future<void> syncNow() => _runSyncAction(_syncBody);

  /// The user's decision after `account_changed`: bind this library to the
  /// signed-in account and sync.
  ///  * [mergeLocal] true: merge the local library with the account (local-only
  ///    songs are uploaded; same-id differences become conflict copies).
  ///  * [mergeLocal] false: the account's library replaces the local one;
  ///    local songs and setlists the account does not have are DELETED. Ask the
  ///    user to confirm this one.
  /// To keep the local library out of the account, sign out instead.
  Future<void> adoptAccount({required bool mergeLocal}) =>
      _runSyncAction(() async {
        await _sync!.adoptAccount(mergeLocal: mergeLocal);
        syncPreviousAccountEmail = null;
        syncError = null;
        await _syncBody();
      });

  /// The user's decision after `remote_listing_suspicious`: the cloud really
  /// lost those items, so delete them locally too (runs a sync). Ask the user
  /// to confirm: it removes up to [syncSuspiciousDeletionCount] songs and
  /// setlists from this device.
  Future<void> confirmRemoteDeletions() => _runSyncAction(() async {
    _sync!.confirmRemoteDeletions();
    await _syncBody();
  });

  /// The user's other decision after `remote_listing_suspicious`: keep the
  /// local library and upload the missing items to the cloud again (runs a
  /// sync). Nothing is deleted.
  Future<void> keepLocalAfterRemoteDeletions() => _runSyncAction(() async {
    await _sync!.keepLocalAfterSuspiciousListing();
    await _syncBody();
  });

  Future<void> _syncBody() async {
    final report = await _sync!.sync();
    if (_disposed) return;
    syncReport = report;
    lastSyncConflicts = report.conflicts;
    lastSyncAt = await _sync!.lastSuccessfulSync();
    _autoFailures = 0;
    _backoffUntil = null;
    // Some remote files could not be used: the rest is synced, and the problem
    // stays visible with its code.
    syncWarning = report.skipCodes.isEmpty ? null : report.skipCodes.first;
    syncError = syncWarning;
    await _reload();
    if (_disposed) return;
    _indexSaved();
    if (report.pending > 0 && _pendingRetries++ < 3) {
      _scheduleAutoSync(after: _timing.delay);
    } else if (report.pending == 0) {
      _pendingRetries = 0;
    }
  }

  /// Call when the app returns to the foreground. Starts an automatic sync
  /// when signed in, enabled and the last successful sync is old.
  void onAppResumed() {
    if (_disposed || !initialized || !syncConnected || syncBusy) return;
    if (_isStale() || _changedDuringSync) {
      _scheduleAutoSync(after: _timing.startDelay);
    }
  }

  /// Switches automatic syncing (a persisted app setting, default on).
  Future<void> setAutoSync(bool enabled) async {
    await setSetting('autoSync', enabled);
    if (enabled) {
      if (syncConnected && _isStale()) {
        _scheduleAutoSync(after: _timing.startDelay);
      }
    } else {
      _cancelAutoSync();
    }
  }

  static const _noAutoRetry = {
    'not_configured',
    'not_signed_in',
    'authorization_required',
    'access_denied',
    'storage_full',
    'account_changed',
    'remote_library_too_large',
    'library_too_large',
    'sign_in_failed',
    'not_initialized',
    'cancelled',
    // Permanent for the data at hand: retrying changes nothing.
    'remote_listing_suspicious',
    'invalid_remote_data',
    'invalid_local_data',
    'remote_file_too_large',
    'local_file_too_large',
    'no_account_change',
  };

  /// After this many consecutive automatic failures the background retries stop
  /// until the user acts (a manual sync) or a sync succeeds.
  static const _maxAutoFailures = 8;

  bool get _autoEligible =>
      !_disposed &&
      _autoFailures < _maxAutoFailures &&
      initialized &&
      _sync != null &&
      syncConnected &&
      autoSyncEnabled &&
      !_noAutoRetry.contains(syncError);

  void _cancelAutoSync() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _changedDuringSync = false;
  }

  void _noteLocalChange() {
    if (syncBusy) {
      _changedDuringSync = true;
      return;
    }
    _scheduleAutoSync(after: _timing.delay);
  }

  /// (Re)starts the single automatic-sync timer, never earlier than the
  /// current failure back-off.
  void _scheduleAutoSync({required Duration after}) {
    if (!_autoEligible) return;
    var wait = after;
    final until = _backoffUntil;
    if (until != null) {
      var left = until.difference(DateTime.now());
      // A clock moved back must not postpone the retry beyond the cap.
      if (left > _timing.maxBackoff) left = _timing.maxBackoff;
      if (left > wait) wait = left;
    }
    _autoTimer?.cancel();
    _autoTimer = Timer(wait, () {
      _autoTimer = null;
      if (!_autoEligible) return;
      if (syncBusy) {
        _changedDuringSync = true;
        return;
      }
      unawaited(_runSyncAction(_syncBody, automatic: true));
    });
  }

  void _noteAutoFailure() {
    _autoFailures++;
    var wait = _timing.backoff * (1 << (_autoFailures - 1).clamp(0, 20));
    if (wait > _timing.maxBackoff) wait = _timing.maxBackoff;
    _backoffUntil = DateTime.now().add(wait);
    _scheduleAutoSync(after: wait);
  }

  /// Completes when any in-flight sync action has finished (for tests and
  /// orderly shutdown).
  Future<void> get syncIdle => _activeSyncAction ?? Future.value();

  Future<void> _runSyncAction(
    Future<void> Function() action, {
    bool automatic = false,
  }) {
    if (syncBusy) return Future.value();
    if (_disposed) return Future.value();
    if (_sync == null) {
      // Before initialize() there is nothing to sync with: a handled state, not
      // a crash.
      syncError = 'not_initialized';
      postMessage('not_initialized', operation: 'sync');
      _emit();
      return Future.value();
    }
    return _activeSyncAction = _execute(action, automatic: automatic);
  }

  Future<void> _execute(
    Future<void> Function() action, {
    required bool automatic,
  }) async {
    syncBusy = true;
    syncError = null;
    _emit();
    try {
      await action();
    } on SyncException catch (error) {
      _failSync(error.code, automatic);
      await _reloadAfterFailure();
    } catch (_) {
      _failSync('sync_failed', automatic);
      await _reloadAfterFailure();
    } finally {
      syncBusy = false;
      _emit();
      if (_changedDuringSync && !_disposed) {
        _changedDuringSync = false;
        _scheduleAutoSync(after: _timing.delay);
      }
    }
  }

  /// A failed or cancelled sync may still have committed some items; the cache
  /// and the content hashes must reflect the database again.
  Future<void> _reloadAfterFailure() async {
    if (_disposed || _repository == null) return;
    try {
      await _reload();
      if (!_disposed) _indexSaved();
    } catch (_) {}
  }

  void _failSync(String code, bool automatic) {
    if (_disposed) return;
    syncError = code;
    // A background run fails silently (the account screen shows the code); a
    // user action also tells the user.
    if (!automatic && code != 'cancelled') {
      postMessage(code, operation: 'sync');
    }
    if (!_noAutoRetry.contains(code)) _noteAutoFailure();
  }

  String exportSong(SongDocument song) => ChordProCodec().encode(song);
  Future<List<SongDocument>> importText(String text) => _tracked(
    'import',
    () async {
      final collection = await importCollection(
        ImportedCollection(decodeSongText(text), []),
      );
      return collection.songs;
    },
  );

  Future<ImportedCollection> importDocument(PickedDocument file) =>
      _tracked('import', () async {
        final bytes = file.bytes;
        if (looksLikeZip(bytes)) {
          return importCollection(await decodeLibraryPackageAsync(bytes));
        }
        if (bytes.length > maxImportBytes) {
          throw const FormatException('file_too_large');
        }
        final name = file.name.toLowerCase();
        if (name.endsWith('.lrc') || name.endsWith('.ttml')) {
          return importCollection(
            ImportedCollection(decodePickedSongs(file), []),
          );
        }
        final text = file.lenientText;
        if (looksLikeSetlistXml(text)) {
          return importCollection(
            ImportedCollection([], [
              decodeSetlistReferences(
                text,
                await repository.listSongs(),
                fileName: file.name,
              ),
            ]),
          );
        }
        return importCollection(
          ImportedCollection(decodeSongText(text, fileName: file.name), []),
        );
      });

  static String _stableId(String seed) =>
      'imp-${sha256.convert(utf8.encode(seed)).toString().substring(0, 32)}';

  /// Imports songs and setlists without ever overwriting local work, and
  /// idempotently: importing the same backup or file again creates nothing new.
  /// A song whose id exists with different content is stored under a stable
  /// derived id; a setlist's id is derived from its identity and content, and
  /// one that already exists is left untouched (the user may have edited it).
  Future<ImportedCollection> importCollection(ImportedCollection input) =>
      _tracked('import', () async {
        final mapping = <String, String>{};
        final incoming = <SongDocument>[];
        final toWrite = <SongDocument>[];
        for (final song in input.songs) {
          final existing = await repository.getSong(song.id);
          if (existing == null) {
            mapping[song.id] = song.id;
            incoming.add(song);
            toWrite.add(song);
          } else if (exportSong(existing) == exportSong(song)) {
            mapping[song.id] = song.id;
            incoming.add(song);
          } else {
            // An externally edited file gets its own identity; importing never
            // overwrites local work. The identity is derived from the content so
            // a repeated import finds its earlier copy instead of adding another.
            final id = _stableId('song:${song.id}:${exportSong(song)}');
            mapping[song.id] = id;
            final copy = SongDocument(
              id: id,
              title: song.title,
              artist: song.artist,
              body: song.body,
              metadata: song.metadata,
              sources: song.sources,
              timingTracks: song.timingTracks,
              selectedRecording: song.selectedRecording,
              activeTimingTrackId: song.activeTimingTrackId,
              favorite: song.favorite,
              createdAt: song.createdAt,
              updatedAt: song.updatedAt,
              revision: song.revision,
              extra: {...song.extra, 'importedFromId': song.id},
              preservedExtensions: song.preservedExtensions,
              extensionError: song.extensionError,
            );
            incoming.add(copy);
            if (await repository.getSong(id) == null) toWrite.add(copy);
          }
        }
        final importedSets = <SetlistDocument>[];
        final newSets = <SetlistDocument>[];
        for (final set in input.setlists) {
          final mapped = [
            for (final entry in set.entries)
              (
                songId: mapping[entry.songId] ?? entry.songId,
                overrides: entry.overrides,
              ),
          ];
          final id = _stableId(
            'setlist:${jsonEncode({
              'id': set.id,
              'name': set.name,
              'notes': set.notes,
              'favorite': set.favorite,
              'entries': [
                for (final e in mapped) [e.songId, e.overrides],
              ],
            })}',
          );
          final document = SetlistDocument(
            id: id,
            name: set.name,
            notes: set.notes,
            favorite: set.favorite,
            createdAt: set.createdAt,
            entries: [
              for (var i = 0; i < mapped.length; i++)
                SetlistEntry(
                  id: _stableId('entry:$id:$i'),
                  songId: mapped[i].songId,
                  overrides: mapped[i].overrides,
                ),
            ],
          );
          importedSets.add(document);
          if (await repository.getSetlist(id) == null) newSets.add(document);
        }
        if (toWrite.isNotEmpty || newSets.isNotEmpty) {
          await repository.importCollection(toWrite, newSets);
        }
        await _afterWrite();
        return ImportedCollection(incoming, importedSets);
      });

  @override
  void dispose() {
    _disposed = true;
    _cancelAutoSync();
    _sync?.cancel();
    _searchCancel?.cancel();
    _discoveryCancel?.cancel();
    // Close the HTTP client only once the cancelled sync has stopped, so its
    // workers do not spend retries on a closed client.
    final closing = _sync;
    if (closing != null) {
      unawaited(
        (_activeSyncAction ?? Future<void>.value())
            .catchError((Object _) {})
            .then<void>((_) => closing.close()),
      );
    }
    final transport = _ownedTransport;
    if (transport != null) {
      unawaited(
        transport.close().then<void>(
          (_) {},
          onError: (Object error, StackTrace stack) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stack,
                library: 'singbook',
                context: ErrorDescription(
                  'while closing the app controller provider transport',
                ),
              ),
            );
          },
        ),
      );
    }
    if (_ownsRepository && _repository != null) {
      // Only a database this controller opened is closed by it, and only after
      // an in-flight sync has finished with it.
      final owned = _repository!;
      unawaited(
        (_activeSyncAction ?? Future<void>.value())
            .catchError((Object _) {})
            .then<void>((_) => owned.close())
            .catchError((Object _) {}),
      );
    }
    messages.dispose();
    super.dispose();
  }
}
