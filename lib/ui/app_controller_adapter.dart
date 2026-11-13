import 'dart:async';
import '../domain/acousticbrainz_analysis.dart';
import '../providers/core/recording_context.dart';
import '../providers/core/diagnostics.dart';
import '../providers/core/service.dart' show ProviderCheck;

import 'package:flutter/foundation.dart';

import '../application/app_controller.dart';
import '../sync/sync_provider.dart';
import '../domain/arrangement.dart' as arrangement;
import '../domain/chordpro.dart';
import '../domain/combine.dart' show rankedKeyNeedsReview, recordingCompatible;
import '../domain/metadata_enrichment.dart'
    show DisplayMetadata, comparisonDisplayMetadata, displayMetadataFor;
import '../domain/models.dart';
import '../domain/search_grouping.dart';
import '../domain/timing.dart' show timingOccurrenceMapForLyrics;
import '../domain/source_contributions.dart';
import 'format.dart';
import 'library/collation.dart' show foldForSearch;
import 'player_section_timeline.dart';
import 'player_duration.dart';
import 'song_search.dart';
import 'verse_ui_state.dart';

typedef AppAppearance = ({
  String palette,
  String fontFamily,
  AppThemeMode themeMode,
  String? languageCode,
});

typedef _ReaderTimingInput = ({
  String sourceLyrics,
  Object? occurrences,
  List<TimingCue> cues,
});

typedef _ReaderChartInput = ({String body, int transpose});

typedef _ReaderProjection = ({
  List<LyricLineData> lines,
  _ReaderTiming? timing,
  double? estimate,
  Map<String, double>? estimatedStarts,
});

typedef _SavedReaderWork = ({
  SongDocument song,
  _ReaderChartInput chart,
  TimingTrack? track,
  PlayerDuration duration,
  List<LyricLineData>? cachedLines,
  Future<_ReaderProjection> projection,
});

class _ReaderTiming {
  _ReaderTiming({required this.lineStarts, required this.cueTargets})
    : cueTimes = (cueTargets.keys.toList()..sort());

  final Map<String, double> lineStarts;
  final Map<int, String?> cueTargets;
  final List<int> cueTimes;

  String? lineAt(int elapsedUs) {
    var start = 0;
    var end = cueTimes.length;
    while (start < end) {
      final middle = (start + end) ~/ 2;
      if (cueTimes[middle] <= elapsedUs) {
        start = middle + 1;
      } else {
        end = middle;
      }
    }
    return start == 0 ? null : cueTargets[cueTimes[start - 1]];
  }
}

typedef _ComparisonTarget = ({SongCandidate record, bool rejected});

typedef _ComparisonMetadataInput = ({
  SongCandidate selection,
  List<_ComparisonTarget> targets,
  List<SongCandidate> suggestions,
});

List<DisplayMetadata> _enrichComparison(_ComparisonMetadataInput input) =>
    comparisonDisplayMetadata(
      targets: [(record: input.selection, rejected: false), ...input.targets],
      donors: [
        input.selection,
        for (final target in input.targets)
          if (!target.rejected) target.record,
        ...input.suggestions,
      ],
    );

typedef _RecordingProofInput = ({
  SongCandidate selection,
  List<SourceResult> sources,
  Set<String> enabled,
  Set<String> confirmed,
});

typedef _ComparisonProjection = ({
  List<DisplayMetadata> display,
  Set<int> verified,
  Set<String> confirmedAnalysis,
});

_ComparisonProjection _projectComparison(
  ({_ComparisonMetadataInput metadata, _RecordingProofInput? proof}) input,
) {
  final verified = <int>{};
  final confirmedAnalysis = <String>{};
  if (input.proof case final proof?) {
    final allConfirmed = setEquals(proof.enabled, proof.confirmed);
    for (final (index, source) in proof.sources.indexed) {
      if (source.extra['recordingContext'] is! Map) continue;
      final compatible = recordingContextCompatible(
        proof.selection,
        source,
        proof.sources,
        eligible: proof.enabled.contains,
      );
      if (compatible) verified.add(index);
      if (source.candidate.providerId == 'acousticbrainz' &&
          (allConfirmed
              ? compatible
              : recordingContextCompatible(
                  proof.selection,
                  source,
                  proof.sources,
                  eligible: proof.confirmed.contains,
                ))) {
        confirmedAnalysis.add(source.id);
      }
    }
  }
  return (
    display: _enrichComparison(input.metadata),
    verified: verified,
    confirmedAnalysis: confirmedAnalysis,
  );
}

class _ComparisonMetadata {
  _ComparisonMetadata(
    this.selection,
    this.sources,
    this.suggestions,
    this.input,
    this.proof,
  );

  final SongCandidate selection;
  final List<SourceResult> sources;
  final List<SongCandidate> suggestions;
  final _ComparisonMetadataInput input;
  final _RecordingProofInput? proof;
  _ComparisonProjection? projection;
  bool attempted = false;

  late final _localReference = displayMetadataFor(input.selection);
  late final _localVersions = [
    for (final target in input.targets) displayMetadataFor(target.record),
  ];

  DisplayMetadata get reference => projection?.display.first ?? _localReference;
  DisplayMetadata versionAt(int index) =>
      projection?.display[index + 1] ?? _localVersions[index];
}

String _lyricHighlightStyle(Object? value) =>
    const {
      'backgroundUnderline',
      'background',
      'underline',
      'contrast',
      'none',
    }.contains(value)
    ? value! as String
    : 'background';

/// Adapts the durable domain controller to the deliberately small UI contract.
/// Account and file actions are injected by the app shell when those integrations
/// are configured; absent integrations remain visibly unavailable.
///
/// [state] is cached and rebuilt only after the controller or the adapter
/// itself notifies, so reading it repeatedly while building is cheap. Playback
/// position changes (one-second ticks, scrubbing) are published through
/// [playerPosition] and do not notify listeners or invalidate the cache.
class AppControllerAdapter extends VerseUiController {
  AppControllerAdapter(
    this.app, {
    this.onShareSong,
    this.onShareSongPdf,
    this.onCopySong,
    this.onPrintSong,
    this.onShareSetlist,
    this.onShareSetlistPdf,
    this.onCopySetlist,
    this.onPrintSetlist,
    this.onImport,
    this.onImportSetlist,
    this.onSignIn,
    this.onSignOut,
    this.onSavePlayerPreferences,
    this.catalogProjector,
  }) {
    _observedSearchCatalogId = app.searchCatalogId;
    _observedSourceCatalogRevision =
        app.discovery.catalogClient?.runtime.catalog?.revision;
    app.addListener(_onAppChanged);
  }

  final AppController app;
  final Future<void> Function(SongDocument song)? onShareSong;
  final Future<void> Function(SongDocument song)? onShareSongPdf;
  final Future<void> Function(SongDocument song)? onCopySong;
  final Future<void> Function(SongDocument song)? onPrintSong;
  final Future<void> Function(SetlistDocument setlist)? onShareSetlist;
  final Future<void> Function(SetlistDocument setlist)? onShareSetlistPdf;
  final Future<void> Function(SetlistDocument setlist)? onCopySetlist;
  final Future<void> Function(SetlistDocument setlist)? onPrintSetlist;
  final Future<void> Function()? onImport;
  final Future<void> Function()? onImportSetlist;
  final Future<void> Function()? onSignIn;
  final Future<void> Function()? onSignOut;

  /// Optional persistence boundary for hosts and deterministic failure tests.
  final Future<void> Function(String id, int transpose, double playbackSpeed)?
  onSavePlayerPreferences;

  @visibleForTesting
  final Future<List<SearchRecordingGroup>> Function(CatalogProjection)?
  catalogProjector;

  VerseTab _tab = VerseTab.home;
  VerseRoute _route = VerseRoute.main;
  HomeListMode _homeMode = HomeListMode.recent;
  bool _favoritesOnly = false;
  SearchFilterData _filters = const SearchFilterData();
  bool _filtersExpanded = false;
  String _query = '';
  String? _songId, _setlistId, _setlistEntryId, _selectedVersionId;
  String? _selectedQuery;
  String? _lastCatalogQuery;
  String? _observedSearchCatalogId;
  int? _observedSourceCatalogRevision;
  int _catalogRequestRevision = 0, _catalogChangeRevision = 0;
  String? _versionOrderReferenceId;
  final Map<String, int> _versionArrivalOrder = {};
  int _nextVersionArrivalOrder = 0;
  List<SongCandidate> _cachedAutocomplete = const [];
  SongDocument? _draftSong;
  SetlistDocument? _draftSetlist;
  String? _draftSetlistInitialName;
  SongEditorData? _editorData;
  bool _editing = false, _playing = false, _editingSetlist = false;
  int _playerPreferenceRevision = 0;
  final _pendingPlayerPreferences =
      <String, ({int revision, int transpose, double speed})>{};
  Future<void>? _playerPreferenceSave;
  bool _editorDirty = false, _loadingMoreRecent = false, _disposed = false;
  bool _conflictFilter = false;
  String? _editorBaseHash;
  int _editorSessionRevision = 0;

  /// Stored hash of the setlist when editing began, so a save after a
  /// background sync changed it becomes a conflict copy, not an overwrite.
  String? _setlistBaseHash;
  int _setlistEditSessionRevision = 0;
  double _progress = 0, _transpose = 0, _playbackSpeed = 1;
  Timer? _searchDebounce, _playerTimer;
  Timer? _playerPreferenceDebounce;
  final _codec = ChordProCodec();

  // Playback clock: progress is derived from a stopwatch so a delayed timer
  // tick catches up instead of drifting.
  final Stopwatch _playWatch = Stopwatch();
  double _playBase = 0;

  // State cache. [_revision] bumps on every notification; the base state is
  // rebuilt lazily when it is stale.
  int _revision = 0, _builtRevision = -1, _builds = 0;
  int _navigationIntentRevision = 0;
  VerseUiState? _base, _composed;
  PlayerPosition _composedPosition = PlayerPosition.zero;
  Map<String, int> _opens = const {};
  final ValueNotifier<PlayerPosition> _position = ValueNotifier(
    PlayerPosition.zero,
  );
  final StreamController<UiNotice> _notices = StreamController.broadcast();

  /// How many times the full state has been rebuilt (for tests).
  @visibleForTesting
  int get stateBuildCount => _builds;

  @override
  ValueListenable<PlayerPosition> get playerPosition => _position;

  @override
  Stream<UiNotice> get notices => _notices.stream;

  /// Reports an outcome to whoever is listening (the app shell).
  void postNotice(UiNotice notice) {
    if (!_disposed) _notices.add(notice);
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    _queueCatalogProjection();
    _revision++;
    _refreshPosition();
    super.notifyListeners();
  }

  void _onAppChanged() {
    if (!identical(_comparisonMetadata?.selection, app.selection)) {
      _comparisonMetadata = null;
    }
    final catalogId = app.searchCatalogId;
    final revision = app.discovery.catalogClient?.runtime.catalog?.revision;
    if (_observedSearchCatalogId != catalogId ||
        _observedSourceCatalogRevision != revision) {
      _observedSearchCatalogId = catalogId;
      _observedSourceCatalogRevision = revision;
      ++_catalogRequestRevision;
      _searchDebounce?.cancel();
      _cachedAutocomplete = const [];
      _lastCatalogQuery = null;
      if (app.selection == null) {
        _selectedQuery = null;
        _selectedVersionId = null;
      }
    }
    notifyListeners();
  }

  int _beginNavigationIntent() => ++_navigationIntentRevision;

  bool _isCurrentNavigationIntent(int revision) =>
      !_disposed && revision == _navigationIntentRevision;

  String _keyWithCanonicalRoot(String key) => key.replaceFirstMapped(
    RegExp(r'^(\s*)([a-g])'),
    (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
  );

  SongDocument? get currentSong => _songId == null
      ? null
      : app.findSong(_songId!) ??
            (_draftSong?.id == _songId ? _draftSong : null);
  String? get displayedKey {
    final key = currentSong == null ? null : _songKey(currentSong!);
    final override = activeSetlistEntry?.overrides['key']?.toString();
    final base = override?.isNotEmpty == true ? override : key;
    if (base == null || base.isEmpty) return null;
    return arrangement.transposeChord(
      _keyWithCanonicalRoot(base),
      _transpose.toInt(),
    );
  }

  Object? get displayedCapo =>
      activeSetlistEntry?.overrides['capo'] ?? currentSong?.metadata['capo'];

  SetlistEntry? get activeSetlistEntry {
    final entryId = _setlistEntryId;
    if (entryId == null) return null;
    return currentSetlist?.entries
        .where((entry) => entry.id == entryId)
        .firstOrNull;
  }

  int _effectiveTranspose(SongDocument? song) {
    if (song == null) return _transpose.toInt();
    final originalKey = _songKey(song);
    final overrideKey = activeSetlistEntry?.overrides['key']?.toString();
    if (originalKey == null ||
        originalKey.isEmpty ||
        overrideKey == null ||
        overrideKey.isEmpty) {
      return _transpose.toInt();
    }
    final originalPitch = _keyPitch(originalKey);
    final overridePitch = _keyPitch(overrideKey);
    if (originalPitch == null || overridePitch == null) {
      return _transpose.toInt();
    }
    return (overridePitch - originalPitch + 12) % 12 + _transpose.toInt();
  }

  static final _keyPattern = RegExp(
    r'^\s*([A-G])([#b♯♭]?)',
    caseSensitive: false,
  );
  static int? _keyPitch(String key) {
    final match = _keyPattern.firstMatch(key);
    if (match == null) return null;
    const pitches = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
    final pitch = pitches[match.group(1)!.toUpperCase()];
    if (pitch == null) return null;
    final accidental = match.group(2);
    return (pitch +
            (accidental == '#' || accidental == '♯'
                ? 1
                : accidental == 'b' || accidental == '♭'
                ? -1
                : 0) +
            12) %
        12;
  }

  SetlistDocument? get currentSetlist =>
      _setlistId == null ? null : _setlistById(_setlistId!);

  @override
  VerseRoute get route => _route;

  AppAppearance get appearance => (
    palette: app.settings['palette'] as String? ?? 'navy',
    fontFamily: app.settings['fontFamily'] as String? ?? 'system',
    themeMode: _themeMode(app.settings['themeMode']),
    languageCode: app.settings['locale'] as String?,
  );

  @override
  VerseUiState get state {
    final base = _baseState();
    final position = _position.value;
    final composed = _composed;
    if (composed != null &&
        identical(_composedBase, base) &&
        _composedPosition == position) {
      return composed;
    }
    _composedBase = base;
    _composedPosition = position;
    return _composed = VerseUiState.withPosition(
      base,
      position.seconds,
      position.currentLineId,
    );
  }

  VerseUiState? _composedBase;

  VerseUiState _baseState() {
    final cached = _base;
    if (cached != null && _builtRevision == _revision) return cached;
    _builtRevision = _revision;
    if (!_songIndexIsCurrent) {
      // Search, player and navigation changes usually share the same library.
      final index = <String, SongDocument>{};
      for (final song in app.songs) {
        index.putIfAbsent(song.id, () => song);
      }
      _indexedSongs = app.songs;
      _indexedSongCount = app.songs.length;
      _songIndex = index;
      _chartEstimates.removeWhere((id, _) => !index.containsKey(id));
      _orderedSongs = null;
      _libraryCards = null;
      _setlistCards = Expando<SetlistCardData>();
    }
    return _base = _buildState();
  }

  List<SongDocument>? _indexedSongs;
  int _indexedSongCount = 0;
  Map<String, SongDocument> _songIndex = const {};
  bool get _songIndexIsCurrent =>
      identical(_indexedSongs, app.songs) &&
      _indexedSongCount == app.songs.length;

  SongDocument? _lookupSong(String id) =>
      _songIndexIsCurrent ? _songIndex[id] : app.findSong(id);

  ({String body, int transpose, List<LyricLineData> lines})? _readerChart;

  List<LyricLineData> _readerLines(SongDocument song) {
    final transpose = _effectiveTranspose(song);
    final cached = _readerChart;
    if (cached != null &&
        cached.body == song.body &&
        cached.transpose == transpose) {
      return cached.lines;
    }
    final lines = _renderReaderChart((body: song.body, transpose: transpose));
    _readerChart = (body: song.body, transpose: transpose, lines: lines);
    return lines;
  }

  static List<LyricLineData> _renderReaderChart(
    ({String body, int transpose}) input,
  ) => _renderLines(
    arrangement.parseArrangement(input.body),
    transpose: input.transpose,
  );

  static _ReaderProjection _prepareReaderProjection(
    ({
      _ReaderChartInput chart,
      List<LyricLineData>? cachedLines,
      _ReaderTimingInput? timing,
      double durationSeconds,
      bool estimateDuration,
      bool prepareEstimatedStarts,
    })
    input,
  ) {
    final lines = input.cachedLines ?? _renderReaderChart(input.chart);
    final timeline = input.estimateDuration || input.prepareEstimatedStarts
        ? EstimatedChartTimeline(lines)
        : null;
    final estimate = input.estimateDuration ? timeline!.durationEstimate : null;
    final seconds = estimate != null && estimate > input.durationSeconds
        ? estimate
        : input.durationSeconds;
    final timing = input.timing;
    return (
      lines: lines,
      estimate: estimate,
      estimatedStarts: input.prepareEstimatedStarts
          ? timeline!.lineStarts(seconds)
          : null,
      timing: timing == null
          ? null
          : _buildReaderTiming(timing, lines.map((line) => line.id)),
    );
  }

  int _savedChartTranspose(SongDocument song) =>
      _pendingPlayerPreferences[song.id]?.transpose ??
      _storedTranspose(song).toInt();

  /// Publishes the position without rebuilding unrelated screen projections.
  void _refreshPosition() {
    if (_savingSelectedVersion && _route == VerseRoute.main) return;
    final song = currentSong;
    if (song == null) {
      _position.value = PlayerPosition.zero;
      return;
    }
    _position.value = PlayerPosition(
      _progress,
      _currentLineId(_readerLines(song), song),
    );
  }

  VerseUiState _buildState() {
    _builds++;
    final opens = <String, int>{};
    for (final event in app.recent) {
      if (event.objectKind == 'song') {
        opens[event.objectId] = (opens[event.objectId] ?? 0) + event.openCount;
      }
    }
    _opens = opens;
    final song = currentSong;
    final setlist = currentSetlist;
    final trustedReaderKey = displayedKey;
    final estimatedReaderKey = trustedReaderKey == null && song != null
        ? app.displayKeysFor(song)?.estimate
        : null;
    final readerKey =
        trustedReaderKey ??
        (estimatedReaderKey == null
            ? null
            : arrangement.transposeChord(
                _keyWithCanonicalRoot(estimatedReaderKey),
                _transpose.toInt(),
              ));
    final timingMode = app.settings['timingMode'] as String? ?? 'estimated';
    final readerDeferred = _savingSelectedVersion && _route == VerseRoute.main;
    final data = song == null || readerDeferred
        ? const <LyricLineData>[]
        : _readerLines(song);
    final duration = song == null
        ? null
        : readerDeferred
        ? _libraryDurationForSong(song)
        : _durationForSong(song, lines: data);
    final playerDuration = duration?.seconds ?? 0.0;
    final timedLineStarts = song == null || readerDeferred
        ? const <String, double>{}
        : _timedLineStarts(data, song, timingMode);
    final activeTimingTrackId = song?.activeTimingTrackId;
    final hasActiveTimedCues =
        timingMode == 'timed' &&
        song?.timingTracks.any(
              (track) =>
                  track.id == activeTimingTrackId &&
                  track.status == TimingStatus.usable &&
                  track.cues.isNotEmpty,
            ) ==
            true;
    final estimatedStarts =
        data.isNotEmpty && (timingMode == 'estimated' || !hasActiveTimedCues)
        ? _estimatedStartsFor(data, playerDuration)
        : null;
    final playerSections = _playerSectionsFor(
      lines: data,
      duration: playerDuration,
      timedStarts: timedLineStarts,
      estimatedStarts: hasActiveTimedCues ? null : estimatedStarts,
    );
    final recent = _recentItems(opens);
    final comparison = _route == VerseRoute.main ? _comparison() : null;
    final catalog = _catalogProjection();
    final groups = _catalogGroups(catalog);
    final catalogPreparing =
        catalog != null &&
        app.isFetchedCatalogSnapshot(catalog.candidates) &&
        _preparedCatalog?.input != catalog &&
        groups.isEmpty;
    final tuning = song?.metadata['tuning'];
    final tempo = song?.metadata['tempo'];
    final selectedSourceId = song?.extra['selectedSourceId'];
    final selectedSource = song?.sources
        .where((source) => source.id == selectedSourceId)
        .firstOrNull;
    final sourceSeparator = selectedSourceId is String
        ? selectedSourceId.indexOf(':')
        : -1;
    final sourceProviderId =
        selectedSource?.candidate.providerId ??
        (sourceSeparator > 0
            ? (selectedSourceId as String).substring(0, sourceSeparator)
            : null);
    final readerSource = sourceProviderId == null
        ? null
        : _providerName(sourceProviderId);
    final readerTimingAvailable =
        song != null &&
        !readerDeferred &&
        _timedLineStarts(data, song, 'timed').isNotEmpty;
    final readerHasTiming = timingMode == 'timed' && readerTimingAvailable;
    final readerCanCompareVersions =
        song != null && _comparisonReference(song) != null;
    final currentAppearance = appearance;
    return VerseUiState(
      route: _route,
      activeTab: _tab,
      homeListMode: _homeMode,
      favoritesOnly: _favoritesOnly,
      startupSongsView: _startupSongsView(app.settings['startupSongsView']),
      query: _query,
      autocomplete: _searchRows(groups),
      searchState: comparison != null
          ? LoadState.loaded
          : _query.trim().length >= 2 && _query != app.query
          ? LoadState.loading
          : catalogPreparing || app.searching && app.suggestions.isEmpty
          ? LoadState.loading
          : app.errorCode != null
          ? LoadState.failed
          : app.suggestions.isNotEmpty
          ? LoadState.loaded
          : LoadState.idle,
      searchError: comparison == null ? app.errorCode : null,
      comparison: comparison,
      recent: recent,
      recentHasMore: app.hasMoreRecent,
      loadingMoreRecent: _loadingMoreRecent,
      songs: _sortedSongCards(),
      setlists: app.setlists.map(_setlistCard).toList(),
      providers: app.providers
          .map(
            (value) => ProviderSettingData(
              id: value.id,
              name: value.name,
              description: value.description ?? value.capabilities.join(' · '),
              enabled: app.providerEnabled(value.id),
            ),
          )
          .toList(),
      searchCatalogs: app.searchCatalogs
          .map(
            (provider) => ProviderSettingData(
              id: provider.id,
              name: provider.name,
              enabled: true,
            ),
          )
          .toList(),
      searchCatalogId: app.searchCatalogId,
      searchIncludesOtherSources: _searchIncludesOtherSources,
      searchFiltersExpanded: _filtersExpanded,
      searchFilters: _filters,
      syncProvider: app.syncProvider,
      appleSyncSupported: app.appleSyncSupported,
      syncReady: app.syncConfigured,
      syncSignedIn: app.syncConnected,
      syncBusy: app.syncBusy,
      accountName: app.syncAccountEmail,
      syncDriveFolderName: app.syncDriveFolderName,
      accountPhotoUrl: app.syncAccountPhotoUrl,
      accountError: _syncWarningOnly || _syncCancelled ? null : app.syncError,
      lastSyncAt: _lastSyncAt,
      lastSyncConflicts: _lastSyncConflicts,
      lastSyncErrorCode: _syncWarningOnly || _syncCancelled
          ? null
          : _lastSyncErrorCode,
      syncWarningCode: _syncWarningOnly ? app.syncWarning : null,
      syncSuspiciousDeletionCount: app.syncSuspiciousDeletionCount,
      autoSyncEnabled: _autoSyncEnabled,
      songsConflictFilter: _conflictFilter,
      darkTheme: currentAppearance.themeMode,
      palette: currentAppearance.palette,
      fontFamily: currentAppearance.fontFamily,
      lyricsFontSize:
          (app.settings['readerFontSize'] as num?)?.toDouble() ?? 24,
      lyricHighlightStyle: _lyricHighlightStyle(
        app.settings['lyricHighlightStyle'],
      ),
      showChords: app.settings['showChords'] as bool? ?? true,
      showSections: app.settings['showSections'] as bool? ?? true,
      playerControlsExpanded:
          app.settings['playerControlsExpanded'] as bool? ?? true,
      autoscroll:
          (app.settings['autoscroll'] as bool? ?? true) &&
          timingMode != 'manual',
      autoscrollPreference: app.settings['autoscroll'] as bool? ?? true,
      timingMode: timingMode,
      languageCode: currentAppearance.languageCode,
      song: song == null ? null : _songCard(song),
      songLines: data,
      isPlaying: _playing,
      playbackSpeed: _playbackSpeed,
      playerSections: playerSections,
      estimatedLineStarts: timingMode == 'estimated' ? estimatedStarts : null,
      activeSetlist: setlist == null ? null : _setlistCard(setlist),
      editing: _editing,
      editingSetlist: _editingSetlist,
      editor: _editorData,
      editorDirty: _editorDirty,
      readerKey: readerKey,
      readerKeyEstimated:
          estimatedReaderKey != null ||
          song != null &&
              activeSetlistEntry?.overrides['key']
                      ?.toString()
                      .trim()
                      .isNotEmpty !=
                  true &&
              rankedKeyNeedsReview(song),
      readerTranspose: _transpose.round(),
      readerCapo: displayedCapo?.toString(),
      readerTuning: tuning?.toString(),
      readerTempo: tempo?.toString(),
      readerHasTiming: readerHasTiming,
      readerDurationEstimated: duration?.estimated ?? false,
      readerSource: readerSource,
      readerTimingAvailable: readerTimingAvailable,
      readerCanCompareVersions: readerCanCompareVersions,
    );
  }

  ({
    Object events,
    int eventCount,
    Object songs,
    int songCount,
    Object setlists,
    int setlistCount,
    List<RecentItemData> items,
  })?
  _recentCache;

  /// The Recent rows. The same list instance is returned until the history,
  /// the library or the setlists are replaced, so the home screen can keep its
  /// grouping and counts across notifications that concern none of them.
  List<RecentItemData> _recentItems(Map<String, int> opens) {
    final cached = _recentCache;
    if (cached != null &&
        identical(cached.events, app.recent) &&
        cached.eventCount == app.recent.length &&
        identical(cached.songs, app.songs) &&
        cached.songCount == app.songs.length &&
        identical(cached.setlists, app.setlists) &&
        cached.setlistCount == app.setlists.length) {
      return cached.items;
    }
    final recent = <RecentItemData>[];
    for (final event in app.recent) {
      if (event.objectKind == 'song') {
        final item = _lookupSong(event.objectId);
        if (item != null) {
          recent.add(
            RecentItemData(
              id: item.id,
              title: item.title,
              artist: item.artist,
              subtitle: _subtitle(item),
              artworkUrl: _metaString(item.metadata['artworkUrl']),
              occurredAt: event.occurredAt,
              isSetlist: false,
              favorite: item.favorite,
              playCount: opens[item.id] ?? 0,
            ),
          );
        }
      } else if (event.objectKind == 'setlist') {
        final item = app.setlists
            .where((value) => value.id == event.objectId)
            .firstOrNull;
        if (item != null) {
          recent.add(
            RecentItemData(
              id: item.id,
              title: item.name,
              subtitle: '',
              occurredAt: event.occurredAt,
              isSetlist: true,
              favorite: item.favorite,
              playCount: item.entries.length,
            ),
          );
        }
      }
    }
    final items = List<RecentItemData>.unmodifiable(recent);
    _recentCache = (
      events: app.recent,
      eventCount: app.recent.length,
      songs: app.songs,
      songCount: app.songs.length,
      setlists: app.setlists,
      setlistCount: app.setlists.length,
      items: items,
    );
    return items;
  }

  List<SongDocument>? _orderedSongs;
  ({List<SongCardData> cards, Map<String, int> opens, int keysRevision})?
  _libraryCards;

  List<SongCardData> _sortedSongCards() {
    final keysRevision = app.songDisplayKeysRevision;
    final cached = _libraryCards;
    if (cached != null &&
        cached.keysRevision == keysRevision &&
        mapEquals(cached.opens, _opens)) {
      return cached.cards;
    }
    final ordered = _orderedSongs ??= _songsInTitleOrder();
    final cards = List<SongCardData>.unmodifiable(ordered.map(_songCard));
    _libraryCards = (cards: cards, opens: _opens, keysRevision: keysRevision);
    return cards;
  }

  List<SongDocument> _songsInTitleOrder() {
    final keyed = [
      for (final song in app.songs) (key: song.title.toLowerCase(), song: song),
    ]..sort((a, b) => a.key.compareTo(b.key));
    return [for (final entry in keyed) entry.song];
  }

  bool _isUsableResult(SourceResult result, {bool allowRejected = false}) {
    return (allowRejected || result.matchKind != MatchKind.rejected) &&
        _hasUsableBody(result);
  }

  AcousticBrainzAnalysis? _checkRecordingAnalysis(
    String providerId,
    String state,
    SourceResult? checked,
    List<SourceVersionData> versions,
    Set<String> confirmedAnalysis,
  ) {
    if (providerId != 'acousticbrainz' ||
        state != 'found' ||
        !app.providerEnabled(providerId) ||
        checked == null ||
        checked.candidate.providerId != providerId ||
        checked.matchKind != MatchKind.sameRecording ||
        checked.hasPendingMatchCheck) {
      return null;
    }
    final sources = app.results
        .where(
          (source) =>
              source.id == checked.id &&
              source.candidate.providerId == providerId,
        )
        .toList();
    final current = versions
        .where(
          (version) =>
              version.id == checked.id &&
              version.providerId == providerId &&
              version.sameRecording &&
              !version.isChecking,
        )
        .toList();
    if (sources.length != 1 || current.length != 1) return null;
    final source = sources.single;
    if (source.matchKind != MatchKind.sameRecording ||
        source.hasPendingMatchCheck) {
      return null;
    }
    // _version revalidates the selected recording and any live, enabled
    // MusicBrainz witnesses; do not treat an archived payload as that proof.
    final analysis = AcousticBrainzAnalysis.fromMetadata(
      providerId,
      current.single.metadata,
    );
    if (analysis == null) return null;
    final candidate = source.candidate;
    final id = analysis.recordingId.toLowerCase();
    if (candidate.id.toLowerCase() != id ||
        candidate.recordingIds['musicbrainz']?.toLowerCase() != id) {
      return null;
    }
    final selection = app.selection;
    if (selection == null) return null;
    final selectedId =
        selection.recordingIds['musicbrainz'] ??
        (selection.providerId == 'musicbrainz' ? selection.id : null);
    if (selectedId != null) {
      if (selectedId.toLowerCase() != id) return null;
    } else if (!confirmedAnalysis.contains(source.id)) {
      return null;
    }
    return analysis;
  }

  final _sourceLyrics = Expando<bool>();
  final _sourceLines = Expando<List<LyricLineData>>();
  final _sourceChartChords = Expando<bool>();
  final _sourceLineJobs =
      <String, ({Set<Object> owners, Completer<void> completion})>{};
  bool _renderingSourceLines = false;
  String? _sourceSavePriority;
  static const _inlinePreviewLimit = 16 * 1024;

  bool? _knownSourceLyrics(Object owner) =>
      app.preparedHasLyrics(owner) ?? _sourceLyrics[owner];

  bool _sourceHasLyrics(Object owner, String body) {
    final known = _knownSourceLyrics(owner);
    if (known != null) return known;
    if (body.length > _inlinePreviewLimit) {
      _queueSourceLines(owner, body);
      return false;
    }
    return _sourceLyrics[owner] = arrangement
        .plainLyrics(body)
        .trim()
        .isNotEmpty;
  }

  List<LyricLineData> _sourceBodyLines(Object owner, String body) {
    final cached = _sourceLines[owner];
    if (cached != null) return cached;
    if (body.length <= _inlinePreviewLimit) {
      return _sourceLines[owner] = _lines(body);
    }
    _queueSourceLines(owner, body);
    return const [];
  }

  Future<void> _queueSourceLines(Object owner, String body) {
    final job = _sourceLineJobs[body] ??= (
      owners: Set<Object>.identity(),
      completion: Completer<void>(),
    );
    job.owners.add(owner);
    if (!_renderingSourceLines) {
      _renderingSourceLines = true;
      scheduleMicrotask(_renderSourceLines);
    }
    return job.completion.future;
  }

  Future<void> _waitForSourceLyrics(SourceResult source) async {
    final workerFact = Completer<void>();
    void checkWorkerFact() {
      if (!workerFact.isCompleted &&
          (_knownSourceLyrics(source) != null ||
              !app.results.any((current) => identical(current, source)))) {
        workerFact.complete();
      }
    }

    _sourceSavePriority = source.body;
    app.addListener(checkWorkerFact);
    try {
      checkWorkerFact();
      await Future.any([
        _queueSourceLines(source, source.body),
        workerFact.future,
      ]);
    } finally {
      app.removeListener(checkWorkerFact);
      _sourceSavePriority = null;
    }
  }

  static List<
    ({List<LyricLineData> lines, bool hasLyrics, bool hasChartChords})
  >
  _renderSourceLineBatch(List<({String body, bool? hasLyrics})> inputs) {
    return inputs.map((input) {
      final parsed = arrangement.parseArrangement(input.body);
      return (
        lines: _renderLines(parsed),
        hasLyrics:
            input.hasLyrics ??
            arrangement.plainLyrics(input.body).trim().isNotEmpty,
        hasChartChords: parsed.any(
          (line) => !line.directive && line.chords.isNotEmpty,
        ),
      );
    }).toList();
  }

  Future<void> _renderSourceLines() async {
    bool isCurrent(Object owner) =>
        identical(owner, app.combined) ||
        app.results.any((source) => identical(owner, source)) ||
        (_route == VerseRoute.reader &&
            (currentSong?.sources.any((source) => identical(owner, source)) ??
                false));
    try {
      while (!_disposed && _sourceLineJobs.isNotEmpty) {
        _sourceLineJobs.removeWhere((_, job) {
          if (job.owners.any(isCurrent)) return false;
          job.completion.complete();
          return true;
        });
        if (_sourceLineJobs.isEmpty) break;
        final priority = _sourceSavePriority;
        final bodies = priority != null && _sourceLineJobs.containsKey(priority)
            ? [priority]
            : _sourceLineJobs.keys.take(4).toList();
        final rendered =
            await compute(_renderSourceLineBatch, [
              for (final body in bodies)
                (
                  body: body,
                  hasLyrics: _sourceLineJobs[body]!.owners
                      .map(_knownSourceLyrics)
                      .whereType<bool>()
                      .firstOrNull,
                ),
            ], debugLabel: 'singbook-source-lines').onError(
              (_, _) => [
                for (final _ in bodies)
                  (
                    lines: const <LyricLineData>[],
                    hasLyrics: false,
                    hasChartChords: false,
                  ),
              ],
            );
        if (_disposed) break;
        var changed = false;
        for (final (index, body) in bodies.indexed) {
          final job = _sourceLineJobs.remove(body)!;
          for (final owner in job.owners) {
            if (!isCurrent(owner)) continue;
            _sourceLines[owner] = rendered[index].lines;
            _sourceLyrics[owner] = rendered[index].hasLyrics;
            _sourceChartChords[owner] = rendered[index].hasChartChords;
            changed = true;
          }
          job.completion.complete();
        }
        if (changed) notifyListeners();
      }
    } finally {
      _renderingSourceLines = false;
      for (final job in _sourceLineJobs.values) {
        job.completion.complete();
      }
      _sourceLineJobs.clear();
    }
  }

  bool _hasUsableBody(SourceResult result) =>
      _sourceHasLyrics(result, result.body) ||
      app.isUsableChordOnlySource(result);

  bool _hasUsableDocument(SongDocument document) =>
      app.preparedDocumentUsable(document) ??
      (_sourceHasLyrics(document, document.body) ||
          (document.body.length > _inlinePreviewLimit
              ? _sourceChartChords[document] == true
              : arrangement
                    .parseArrangement(document.body)
                    .any((line) => !line.directive && line.chords.isNotEmpty)));

  bool _hasUsableTiming(Iterable<TimingTrack> tracks) => tracks.any(
    (track) => track.status == TimingStatus.usable && track.cues.isNotEmpty,
  );

  final _playbackDurations = Expando<PlayerDuration>();
  var _pendingLibraryEstimates = Expando<PlayerDuration>();
  bool _libraryEstimateDeferred = false;

  PlayerDuration _durationWithoutChartEstimate(SongDocument song) =>
      _playbackDurations[song] ??
      (_pendingLibraryEstimates[song] ??= resolvePlayerDuration(
        song,
        estimate: () => 90,
      ));

  PlayerDuration? _libraryDurationForSong(SongDocument song) {
    if (!_savingSelectedVersion) return _durationForSong(song);
    final cached = _playbackDurations[song];
    if (cached != null) return cached;
    final duration = _durationWithoutChartEstimate(song);
    if (duration.kind != PlayerDurationKind.chartEstimate) {
      return _playbackDurations[song] = duration;
    }
    _libraryEstimateDeferred = true;
    return null;
  }

  bool _invalidateDeferredLibraryEstimates() {
    if (!_libraryEstimateDeferred) return false;
    _libraryEstimateDeferred = false;
    _libraryCards = null;
    _setlistCards = Expando<SetlistCardData>();
    return true;
  }

  PlayerDuration _durationForSong(
    SongDocument song, {
    List<LyricLineData>? lines,
  }) => _playbackDurations[song] ??= resolvePlayerDuration(
    song,
    estimate: () => _chartEstimate(song, lines),
  );

  /// Chart estimates by song id, valid for the stored content hash they were
  /// computed from. A library reload replaces every [SongDocument] instance,
  /// which empties the identity-keyed duration cache; the estimate depends
  /// only on the body, so an unchanged song must not be parsed again.
  final _chartEstimates = <String, ({String hash, double seconds})>{};
  int _chartEstimateRuns = 0;

  /// How many charts have been estimated from their lines (for tests).
  @visibleForTesting
  int get chartEstimateCount => _chartEstimateRuns;

  double _chartEstimate(SongDocument song, List<LyricLineData>? lines) {
    // Only the library's own instance is described by the stored hash; a
    // draft or a superseded copy is estimated without touching the cache.
    final hash = identical(_lookupSong(song.id), song)
        ? app.songHash(song.id)
        : null;
    if (hash != null) {
      final cached = _chartEstimates[song.id];
      if (cached != null && cached.hash == hash) return cached.seconds;
    }
    _chartEstimateRuns++;
    final prepared = _readerChart;
    final seconds = estimateChartDuration(
      lines ??
          (prepared != null && prepared.body == song.body
              ? prepared.lines
              : _lines(song.body)),
    );
    if (hash != null) _chartEstimates[song.id] = (hash: hash, seconds: seconds);
    return seconds;
  }

  String? _songKey(SongDocument song) =>
      _metaString(song.metadata['key']) ?? app.displayKeysFor(song)?.sourceKey;

  SongCardData _songCard(SongDocument song) => SongCardData(
    id: song.id,
    title: song.title,
    artist: song.artist,
    album: _metaString(song.metadata['album']),
    artworkUrl: _metaString(song.metadata['artworkUrl']),
    durationSeconds: _libraryDurationForSong(song)?.seconds,
    key: _songKey(song),
    favorite: song.favorite,
    modifiedAt: song.updatedAt,
    authored: song.sources.isEmpty,
    playCount: _opens[song.id] ?? 0,
    hasChords: song.hasChords,
    isConflictCopy:
        song.id.startsWith('conflict-') || song.extra['syncConflict'] != null,
  );

  var _setlistCards = Expando<SetlistCardData>();

  SetlistCardData _setlistCard(SetlistDocument value) =>
      _setlistCards[value] ??= _buildSetlistCard(value);

  SetlistCardData _buildSetlistCard(SetlistDocument value) {
    final entries = [for (final entry in value.entries) _entryData(entry)];
    var durationSeconds = 0.0;
    var durationEstimated = false;
    var durationPartial = false;
    for (final entry in value.entries) {
      final song = _lookupSong(entry.songId);
      if (song == null) {
        durationPartial = true;
        continue;
      }
      final duration = _libraryDurationForSong(song);
      if (duration == null) {
        durationPartial = true;
        continue;
      }
      durationSeconds += duration.seconds;
      durationEstimated |= duration.estimated;
    }
    return SetlistCardData(
      id: value.id,
      title: value.name,
      notes: value.notes,
      songIds: [for (final entry in entries) entry.songId],
      songTitles: [for (final entry in entries) entry.title],
      entries: entries,
      favorite: value.favorite,
      modifiedAt: value.updatedAt,
      durationSeconds: durationSeconds,
      durationEstimated: durationEstimated,
      durationPartial: durationPartial,
    );
  }

  SetlistEntryData _entryData(SetlistEntry entry) {
    final song = _lookupSong(entry.songId);
    final key = entry.overrides['key']?.toString();
    final capo = entry.overrides['capo']?.toString();
    return SetlistEntryData(
      id: entry.id,
      songId: entry.songId,
      title: song?.title ?? '',
      artist: song?.artist ?? '',
      durationSeconds: song == null
          ? null
          : validDurationSeconds(song.metadata['durationSeconds']),
      keyOverride: key == null || key.isEmpty ? null : key,
      capoOverride: capo == null || capo.isEmpty ? null : capo,
      missing: song == null,
    );
  }

  /// Every row of the current search. Enabled catalogs are searched
  /// together, so one catalog's hit can fill another's missing display facts.
  List<SongCandidate> get _suggestionDonors =>
      app.suggestions.isNotEmpty ? app.suggestions : _cachedAutocomplete;

  static const _inlineComparisonDonorLimit = 32;
  _ComparisonMetadata? _comparisonMetadata;
  Future<void>? _comparisonMetadataTask;

  bool _confirmedRecordingProvider(String id) =>
      const {'found', 'completed'}.contains(app.checks[id]?.state);

  bool _comparisonMetadataIsCurrent(_ComparisonMetadata snapshot) =>
      identical(snapshot.selection, app.selection) &&
      listEquals(snapshot.sources, app.results) &&
      listEquals(snapshot.suggestions, _suggestionDonors) &&
      (snapshot.proof == null ||
          snapshot.sources.every((source) {
            final id = source.candidate.providerId;
            final enabled = app.providerEnabled(id);
            return snapshot.proof!.enabled.contains(id) == enabled &&
                snapshot.proof!.confirmed.contains(id) ==
                    (enabled && _confirmedRecordingProvider(id));
          }));

  void _prepareComparisonMetadata(SongCandidate selection) {
    final previous = _comparisonMetadata;
    if (previous != null && _comparisonMetadataIsCurrent(previous)) return;

    final sources = List.of(app.results);
    final suggestions = List.of(_suggestionDonors);
    final hasContext = sources.any(
      (source) => source.extra['recordingContext'] is Map,
    );
    final providerIds = {
      if (hasContext)
        for (final source in sources)
          if (app.providerEnabled(source.candidate.providerId))
            source.candidate.providerId,
    };
    final proof = !hasContext
        ? null
        : (
            selection: selection,
            sources: sources,
            enabled: providerIds,
            confirmed: providerIds.where(_confirmedRecordingProvider).toSet(),
          );
    final snapshot = _ComparisonMetadata(selection, sources, suggestions, (
      selection: _displayRecord(selection),
      targets: [
        for (final source in sources)
          (
            record: _displayRecord(source.candidate, source: source),
            rejected: source.matchKind == MatchKind.rejected,
          ),
      ],
      suggestions: suggestions.map(_displayRecord).toList(),
    ), proof);
    _comparisonMetadata = snapshot;
    if (proof == null &&
        sources.length + suggestions.length + 1 <=
            _inlineComparisonDonorLimit) {
      snapshot.projection = _projectComparison((
        metadata: snapshot.input,
        proof: null,
      ));
      snapshot.attempted = true;
      return;
    }
    _comparisonMetadataTask ??= Future<void>.microtask(
      _projectComparisons,
    ).whenComplete(() => _comparisonMetadataTask = null);
  }

  Future<void> _projectComparisons() async {
    while (!_disposed && _selectedQuery == _query.trim()) {
      final snapshot = _comparisonMetadata;
      if (snapshot == null ||
          snapshot.attempted ||
          !_comparisonMetadataIsCurrent(snapshot)) {
        return;
      }
      snapshot.attempted = true;
      try {
        final output = await compute(_projectComparison, (
          metadata: snapshot.input,
          proof: snapshot.proof,
        ), debugLabel: 'singbook-comparison-projection');
        if (_disposed ||
            _selectedQuery != _query.trim() ||
            !identical(snapshot, _comparisonMetadata) ||
            !_comparisonMetadataIsCurrent(snapshot)) {
          if (identical(snapshot, _comparisonMetadata)) {
            _comparisonMetadata = null;
          }
          continue;
        }
        snapshot.projection = output;
        notifyListeners();
      } catch (error) {
        if (identical(snapshot, _comparisonMetadata) && !_disposed) {
          snapshot.projection = (
            display: [snapshot.reference, ...snapshot._localVersions],
            verified: const {},
            confirmedAnalysis: const {},
          );
          notifyListeners();
        }
        debugPrint('Comparison projection failed: ${error.runtimeType}');
      }
    }
  }

  @visibleForTesting
  Future<void> settleComparisonMetadata() async {
    await _comparisonMetadataTask;
  }

  /// Copies only the facts and identity evidence used by display enrichment.
  /// Source bodies and the rest of the provider payload stay out of the worker.
  SongCandidate _displayRecord(
    SongCandidate candidate, {
    SourceResult? source,
  }) {
    const identityKeys = [
      'identityScope',
      'pendingMatchCheck',
      'version',
      'edition',
      'disambiguation',
      'recording',
    ];
    final metadata = candidate.metadata;
    final extra = candidate.extra;
    final sourceMetadata = source?.metadata ?? const {};
    final sourceExtra = source?.extra ?? const {};
    final artwork =
        _metaString(metadata['artworkUrl']) ??
        _metaString(sourceMetadata['artworkUrl']);
    return SongCandidate(
      providerId: candidate.providerId,
      id: candidate.id,
      title: candidate.title,
      artist: candidate.artist,
      album: candidate.album ?? _metaString(sourceMetadata['album']),
      durationSeconds:
          validDurationSeconds(candidate.durationSeconds) ??
          validDurationSeconds(sourceMetadata['durationSeconds']) ??
          validDurationSeconds(metadata['durationSeconds']),
      metadata: {
        for (final key in [
          ...identityKeys,
          'album',
          'durationSeconds',
          'duration',
        ])
          key: metadata.containsKey(key) ? metadata[key] : sourceMetadata[key],
        'artworkUrl': ?artwork,
      },
      recordingIds: candidate.recordingIds,
      extra: {
        for (final key in identityKeys)
          key: extra.containsKey(key) ? extra[key] : sourceExtra[key],
      },
    );
  }

  SearchReferenceData _reference(SongCandidate value, DisplayMetadata display) {
    return SearchReferenceData(
      id: value.identity,
      providerId: value.providerId,
      providerName: _providerName(value.providerId),
      title: value.title,
      artist: value.artist,
      album: display.album,
      durationSeconds: display.durationSeconds,
      artworkUrl: display.artworkUrl,
      isHistoricalText: value.providerId == 'wikisource',
    );
  }

  CatalogProjection? _wantedCatalog;
  ({CatalogProjection input, List<SearchRecordingGroup> groups})?
  _preparedCatalog;
  Future<void>? _catalogProjectionTask;
  String? _catalogScoreQuery;
  var _catalogScores = Expando<int>();

  CatalogProjection? _catalogProjection() {
    final query = _query.trim();
    if (query != app.query.trim()) return null;
    final candidates = app.suggestions.isEmpty
        ? _cachedAutocomplete
        : app.suggestions;
    if (candidates.isEmpty) return null;
    return (
      candidates: candidates,
      query: query,
      field: _filters.field,
      preferred: app.searchCatalogId,
      catalogIds: app.searchCatalogs
          .map((provider) => provider.id)
          .join('\u0000'),
    );
  }

  void _queueCatalogProjection() {
    final input = _catalogProjection();
    _wantedCatalog =
        input != null && app.isFetchedCatalogSnapshot(input.candidates)
        ? input
        : null;
    if (_wantedCatalog == null || _preparedCatalog?.input == _wantedCatalog) {
      return;
    }
    _catalogProjectionTask ??= Future<void>.microtask(_projectCatalogs)
        .whenComplete(() {
          _catalogProjectionTask = null;
          if (!_disposed) _queueCatalogProjection();
        });
  }

  @visibleForTesting
  Future<void> settleCatalogProjection() async {
    await _catalogProjectionTask;
  }

  Future<void> _projectCatalogs() async {
    while (!_disposed) {
      final input = _wantedCatalog;
      if (input == null || _preparedCatalog?.input == input) return;
      List<SearchRecordingGroup> groups;
      try {
        final projector = catalogProjector;
        if (projector != null) {
          groups = await projector(input);
        } else {
          final query = input.query.toLowerCase();
          if (_catalogScoreQuery != query) {
            _catalogScoreQuery = query;
            _catalogScores = Expando<int>();
          }
          final scores = _catalogScores;
          final projected = await compute(projectCatalogWithScores, (
            input: input,
            scores: {
              for (final entry in input.candidates.asMap().entries)
                entry.key: ?scores[entry.value],
            },
          ), debugLabel: 'singbook-catalog-projection');
          for (final entry in projected.newScores.entries) {
            scores[input.candidates[entry.key]] = entry.value;
          }
          groups = projected.groups;
        }
      } catch (error) {
        debugPrint('Catalog projection failed: ${error.runtimeType}');
        groups = const [];
      }
      if (_disposed || _wantedCatalog != input) continue;
      _preparedCatalog = (input: input, groups: groups);
      notifyListeners();
    }
  }

  List<SearchRecordingGroup> _catalogGroups(CatalogProjection? input) {
    if (input == null) return const [];
    final prepared = _preparedCatalog;
    if (prepared?.input == input) return prepared!.groups;
    if (!app.isFetchedCatalogSnapshot(input.candidates)) {
      // A locally constructed reference can be shown immediately.
      return projectCatalog(input);
    }
    if (prepared != null &&
        prepared.input.query == input.query &&
        prepared.input.field == input.field &&
        prepared.input.preferred == input.preferred &&
        prepared.input.catalogIds == input.catalogIds) {
      final available = input.candidates.map((row) => row.identity).toSet();
      return prepared.groups
          .where(
            (group) =>
                group.members.every((row) => available.contains(row.identity)),
          )
          .toList();
    }
    return const [];
  }

  /// Requests artwork for the leading groups after their worker result arrives.
  List<SearchReferenceData> _searchRows(List<SearchRecordingGroup> groups) {
    final missing = [
      for (final group in groups)
        if (group.artworkUrl == null &&
            group.representative.providerId != 'wikisource')
          group.representative,
    ].take(20).toList();
    if (missing.isNotEmpty) {
      scheduleMicrotask(() => app.requestArtwork(missing));
    }
    return groups.map(_groupReference).toList();
  }

  /// One search row per recording. The representative's identity is what a
  /// tap selects, so discovery and saving work as for a single row. Display
  /// facts come from the group's own members only: a row without an album was
  /// placed in one group and must not lend its art to another.
  SearchReferenceData _groupReference(SearchRecordingGroup group) {
    final value = group.representative;
    final names = <String>{
      for (final member in [value, ...group.members])
        _providerName(member.providerId),
    }.toList();
    return SearchReferenceData(
      id: value.identity,
      providerId: value.providerId,
      providerName: _providerName(value.providerId),
      title: value.title,
      artist: value.artist,
      album: group.album,
      durationSeconds: group.durationSeconds,
      artworkUrl: group.artworkUrl ?? app.artworkLookups[value.identity],
      isHistoricalText: value.providerId == 'wikisource',
      sourceNames: names,
    );
  }

  bool get _searchIncludesOtherSources {
    final catalogs = app.searchCatalogs;
    final primary = catalogs
        .where((provider) => provider.id == app.searchCatalogId)
        .firstOrNull;
    // Match searchCatalogsTogether's historical isolation policy for both
    // the built-in catalog and definitions that declare public-domain text.
    bool isolated(ProviderDefinition provider) =>
        provider.id == 'wikisource' ||
        provider.accessMode == 'publicDomainText';
    return primary != null &&
        !isolated(primary) &&
        catalogs.where((provider) => !isolated(provider)).length > 1;
  }

  final _providerOperationCards = Expando<List<SearchProviderOperationData>>();

  List<SearchProviderOperationData> _operationsFor(ProviderCheck check) =>
      _providerOperationCards[check] ??= List.unmodifiable([
        for (final operation in check.operations)
          SearchProviderOperationData(
            id: operation.id,
            phase: operation.phase,
            state: operation.state,
            code: operation.code,
            query: operation.query,
            title: operation.title,
            artist: operation.artist,
            sourceUrl: safeDiagnosticUrl(operation.sourceUrl),
            resultCount: operation.resultCount,
            elapsedMilliseconds: operation.elapsedMilliseconds,
          ),
      ]);

  SearchComparisonData? _comparison() {
    final candidate = app.selection;
    if (candidate == null || _selectedQuery != _query.trim()) return null;
    _rememberVersionArrivalOrder(candidate.identity, app.results);
    _prepareComparisonMetadata(candidate);
    final metadata = _comparisonMetadata!;
    final knownResults =
        [
          for (var index = 0; index < metadata.sources.length; index++)
            _version(
              metadata.sources[index],
              metadata.versionAt(index),
              contextualMatch:
                  metadata.projection?.verified.contains(index) ?? false,
              proofPending:
                  metadata.proof != null && metadata.projection == null,
            ),
        ]..sort(
          (a, b) => _versionArrivalOrder[a.id]!.compareTo(
            _versionArrivalOrder[b.id]!,
          ),
        );
    final alternatives = knownResults
        .where(_versionMatchesFilters)
        .toList(growable: true);
    final combined = app.combined;
    final combinedMatchesFilters = _combinedMatchesFilters(combined);
    final combinedReady = app.canSavePreparedCombined;
    final chosenSourceId = combined?.extra['selectedSourceId'];
    final contributorCount = combined == null
        ? 0
        : contributingProviderIds(combined).length;
    final chosenSource = app.results
        .where((item) => item.id == chosenSourceId)
        .firstOrNull;
    final contributingSourceIds = <String>{
      if (chosenSourceId is String) chosenSourceId,
      if (combined?.extra['chordSourceIds'] is List)
        ...(combined!.extra['chordSourceIds'] as List).whereType<String>(),
    };
    final pendingChordSourceIds = {
      if (combined?.extra['pendingChordSourceIds'] is List)
        ...(combined!.extra['pendingChordSourceIds'] as List)
            .whereType<String>(),
    };
    final activePendingProviderIds = app.checks.values
        .where((check) => check.state == 'pending')
        .map((check) => check.providerId)
        .toSet();
    final pendingContributor = combined?.sources
        .where(
          (source) =>
              contributingSourceIds.contains(source.id) &&
              (activePendingProviderIds.contains(source.candidate.providerId) ||
                  app.discovering &&
                      (pendingChordSourceIds.contains(source.id) ||
                          !app.isSourceReady(source))),
        )
        .firstOrNull;
    final unverifiedContributor = combined?.sources
        .where(
          (source) =>
              contributingSourceIds.contains(source.id) &&
              (source.matchKind != MatchKind.sameRecording ||
                  !recordingCompatible(candidate, source)),
        )
        .firstOrNull;
    final suggested =
        combined == null ||
            (!combinedMatchesFilters && _selectedVersionId != 'combined')
        ? null
        : SourceVersionData(
            id: 'combined',
            providerId: 'combined',
            // The UI renders combined entries from [sourceCount]; there is no
            // provider name to show.
            providerName: contributorCount == 1 && chosenSource != null
                ? _providerName(chosenSource.candidate.providerId)
                : '',
            sourceCount: contributorCount,
            title: combined.title,
            artist: combined.artist,
            album: _metaString(combined.metadata['album']),
            sourceUrl: safeDiagnosticUrl(chosenSource?.candidate.url),
            metadata: _diagnosticMetadata(combined.metadata),
            durationSeconds: validDurationSeconds(
              combined.metadata['durationSeconds'],
            ),
            artworkUrl: _metaString(combined.metadata['artworkUrl']),
            hasLyrics: _sourceHasLyrics(combined, combined.body),
            isUsableVersion: _hasUsableDocument(combined),
            hasChords: app.documentHasChords(combined),
            hasTiming: _hasUsableTiming(combined.timingTracks),
            sameRecording:
                chosenSource?.matchKind == MatchKind.sameRecording &&
                pendingContributor == null &&
                unverifiedContributor == null,
            matchSummary: pendingContributor != null
                ? 'pending'
                : unverifiedContributor != null
                ? unverifiedContributor.matchKind == MatchKind.sameSong
                      ? 'same_song'
                      : 'identity_mismatch'
                : contributorCount > 1
                ? 'combined_sources'
                : 'best_available',
            bodyPreview: _previewLines(
              _sourceBodyLines(combined, combined.body),
            ),
            bodyLines: _sourceBodyLines(combined, combined.body),
            contributions: _combinedContributions(combined),
            isChecking: !combinedReady,
            canSave:
                combinedReady &&
                combinedMatchesFilters &&
                combined.body.trim().isNotEmpty &&
                app.savedResultId() == null,
            savedSongId: app.savedResultId(),
            underlyingSourceId: contributorCount == 1 ? chosenSource?.id : null,
          );
    // Keep the explicit card in the list even when a final check rejected it
    // or a filter would otherwise hide it. The UI can then show why it cannot
    // be saved without silently changing the person's choice.
    final explicitlySelected = _selectedVersionId;
    if (explicitlySelected != null && explicitlySelected != 'combined') {
      final selected = knownResults
          .where((item) => item.id == explicitlySelected)
          .firstOrNull;
      if (selected != null &&
          !alternatives.any((item) => item.id == selected.id)) {
        alternatives.add(selected);
        alternatives.sort(
          (a, b) => _versionArrivalOrder[a.id]!.compareTo(
            _versionArrivalOrder[b.id]!,
          ),
        );
      }
    }
    final chosenId = _effectiveSelectionId(suggested?.id, alternatives);
    final checks = app.checks.values
        .map(
          (check) => SearchProviderCheckData(
            id: check.providerId,
            name: _providerName(check.providerId),
            code: check.code,
            state: check.result?.matchKind == MatchKind.rejected
                ? 'rejected'
                : check.state,
            recordingAnalysis: _checkRecordingAnalysis(
              check.providerId,
              check.state,
              check.result,
              knownResults,
              metadata.projection?.confirmedAnalysis ?? const {},
            ),
            operations: _operationsFor(check),
          ),
        )
        .toList();
    return SearchComparisonData(
      reference: _reference(candidate, metadata.reference),
      suggested: suggested,
      alternatives: alternatives,
      selectedVersionId: chosenId,
      error: app.errorCode,
      discoveryError: app.errorCode,
      discovering: app.discovering,
      noUsableLyrics:
          !app.discovering &&
          !app.results.any(
            (source) =>
                (source.body.length > _inlinePreviewLimit &&
                    _knownSourceLyrics(source) == null) ||
                _hasUsableBody(source),
          ),
      providerChecks: checks,
    );
  }

  List<SourceContributionData> _combinedContributions(SongDocument song) {
    final sourceById = {for (final source in song.sources) source.id: source};
    final rolesByProvider = <String, Set<String>>{};
    final providerNames = <String, String>{};
    final sourceUrls = <String, String?>{};

    void add(String? sourceId, String role) {
      if (sourceId == null) return;
      final source = sourceById[sourceId];
      final recording = song.selectedRecording;
      final providerId =
          source?.candidate.providerId ??
          (recording?.identity == sourceId ? recording!.providerId : null);
      if (providerId == null ||
          (source?.matchKind == MatchKind.rejected &&
              sourceId != song.extra['selectedSourceId'] &&
              !(role == 'metadata' &&
                  source?.matchReason == 'incomplete_or_different_lyrics' &&
                  (song.extra['corroboratedKeySourceIds'] as List? ?? const [])
                      .contains(sourceId)))) {
        return;
      }
      providerNames[providerId] = _providerName(providerId);
      sourceUrls.putIfAbsent(
        providerId,
        () => safeDiagnosticUrl(source?.candidate.url),
      );
      rolesByProvider.putIfAbsent(providerId, () => <String>{}).add(role);
    }

    final selectedSourceId = song.extra['selectedSourceId'];
    final origins = jsonMap(song.extra['fieldOrigins']);
    if (selectedSourceId is String) {
      add(selectedSourceId, 'lyrics');
      if (app.documentHasChords(song)) {
        final chordSources = song.extra['chordSourceIds'];
        if (chordSources is List) {
          for (final sourceId in chordSources.whereType<String>()) {
            add(sourceId, 'chords');
          }
        } else {
          add(origins['chords'] as String? ?? selectedSourceId, 'chords');
        }
      }
    }
    for (final entry in origins.entries) {
      if (entry.key == 'lyrics' || entry.key == 'chords') continue;
      final value = song.metadata[entry.key];
      if (value != null && value != '' && entry.value is String) {
        add(entry.value as String, 'metadata');
      }
    }
    final fieldContributors = jsonMap(song.extra['fieldContributors']);
    for (final entry in fieldContributors.entries) {
      if (entry.key == 'lyrics' || entry.key == 'chords') continue;
      final value = song.metadata[entry.key];
      final sourceIds = entry.value;
      if (value != null && value != '' && sourceIds is List) {
        for (final sourceId in sourceIds.whereType<String>()) {
          add(sourceId, 'metadata');
        }
      }
    }
    for (final track in song.timingTracks) {
      if (track.status != TimingStatus.usable || track.cues.isEmpty) continue;
      final sourceId = jsonMap(track.extra['binding'])['sourceId'];
      if (sourceId is String) add(sourceId, 'timing');
    }
    final recording = song.selectedRecording;
    if (recording != null &&
        song.title == recording.title &&
        song.artist == recording.artist) {
      add(recording.identity, 'metadata');
    }
    const roleOrder = ['lyrics', 'chords', 'timing', 'metadata'];
    return [
      for (final entry in rolesByProvider.entries)
        SourceContributionData(
          providerName: providerNames[entry.key] ?? entry.key,
          roles: [
            for (final role in roleOrder)
              if (entry.value.contains(role)) role,
          ],
          sourceUrl: sourceUrls[entry.key],
        ),
    ];
  }

  void _rememberVersionArrivalOrder(
    String referenceId,
    List<SourceResult> results,
  ) {
    if (_versionOrderReferenceId != referenceId) {
      _versionOrderReferenceId = referenceId;
      _versionArrivalOrder.clear();
      _nextVersionArrivalOrder = 0;
    }
    for (final result in results) {
      _versionArrivalOrder.putIfAbsent(
        result.id,
        () => _nextVersionArrivalOrder++,
      );
    }
  }

  String? _effectiveSelectionId(
    String? suggestedId,
    List<SourceVersionData> alternatives,
  ) {
    return _selectedVersionId ??
        suggestedId ??
        alternatives
            .where(
              (item) =>
                  item.isUsableVersion &&
                  (item.canSave || item.savedSongId != null),
            )
            .firstOrNull
            ?.id;
  }

  bool _songMatchesSearchReference(SongDocument song, String referenceId) =>
      song.selectedRecording?.identity == referenceId ||
      song.extra['combinedSelection'] == referenceId;

  SongCandidate? _comparisonReference(SongDocument song) =>
      song.selectedRecording ??
      song.sources
          .where((source) => source.id == song.extra['selectedSourceId'])
          .firstOrNull
          ?.candidate ??
      song.sources.where(_isUsableResult).firstOrNull?.candidate;

  bool _versionMatchesFilters(SourceVersionData item) =>
      (!_filters.chordsOnly || item.hasChords) &&
      (!_filters.timedOnly || item.hasTiming) &&
      (_filters.language.isEmpty ||
          app.results
                  .where((result) => result.id == item.id)
                  .firstOrNull
                  ?.metadata['language']
                  ?.toString()
                  .toLowerCase() ==
              _filters.language.toLowerCase());

  bool _sourceMatchesFilters(SourceResult source) =>
      (!_filters.chordsOnly || app.sourceHasChords(source)) &&
      (!_filters.timedOnly || _hasUsableTiming(source.timingTracks)) &&
      (_filters.language.isEmpty ||
          source.metadata['language']?.toString().toLowerCase() ==
              _filters.language.toLowerCase());

  bool _combinedMatchesFilters(SongDocument? combined) {
    if (combined == null ||
        (_filters.chordsOnly && !app.documentHasChords(combined)) ||
        (_filters.timedOnly && !_hasUsableTiming(combined.timingTracks))) {
      return false;
    }
    if (_filters.language.isNotEmpty &&
        _metaString(combined.metadata['language'])?.toLowerCase() !=
            _filters.language.toLowerCase()) {
      return false;
    }
    return true;
  }

  SourceVersionData _version(
    SourceResult result,
    DisplayMetadata display, {
    required bool contextualMatch,
    required bool proofPending,
  }) {
    final candidate = result.candidate;
    final check = app.checks[candidate.providerId];
    final savedId = app.savedResultId(source: result);
    final hasLyrics = _sourceHasLyrics(result, result.body);
    final lines = _sourceBodyLines(result, result.body);
    final usable = hasLyrics || app.isUsableChordOnlySource(result);
    final isChecking =
        (result.body.length > _inlinePreviewLimit &&
            _knownSourceLyrics(result) == null) ||
        check?.state == 'pending' ||
        app.discovering && !app.isSourceReady(result);
    final sameRecording =
        !isChecking &&
        result.matchKind == MatchKind.sameRecording &&
        app.selection != null &&
        (contextualMatch || recordingCompatible(app.selection!, result));
    final pendingVerification =
        result.matchKind == MatchKind.sameRecording &&
        (isChecking ||
            (!sameRecording &&
                proofPending &&
                result.extra['recordingContext'] is Map));
    return SourceVersionData(
      id: result.id,
      providerId: candidate.providerId,
      providerName: _providerName(candidate.providerId),
      title: candidate.title,
      artist: candidate.artist,
      sourceUrl: safeDiagnosticUrl(candidate.url),
      metadata: _diagnosticMetadata({
        ...candidate.metadata,
        ...result.metadata,
      }, providerId: candidate.providerId),
      album: display.album,
      durationSeconds: display.durationSeconds,
      artworkUrl: display.artworkUrl,
      rating: _metaDouble(result.metadata['rating']),
      ratingCount: _metaInt(result.metadata['ratingCount']),
      hasLyrics: hasLyrics,
      isUsableVersion: usable,
      hasChords: app.sourceHasChords(result),
      hasTiming: _hasUsableTiming(result.timingTracks),
      sameRecording: sameRecording,
      matchSummary: pendingVerification
          ? 'pending'
          : result.matchKind == MatchKind.sameRecording && !sameRecording
          ? 'identity_mismatch'
          : result.matchReason ?? '',
      status: isChecking
          ? LoadState.loading
          : check?.state == 'failed' || check?.state == 'unavailable'
          ? LoadState.failed
          : LoadState.loaded,
      bodyPreview: _previewLines(lines),
      bodyLines: lines,
      contributions: _sourceContributions(result),
      isChecking: isChecking,
      canSave: usable && savedId == null,
      savedSongId: savedId,
    );
  }

  List<SourceContributionData> _sourceContributions(SourceResult result) {
    final roles = <String>[
      if (_sourceHasLyrics(result, result.body)) 'lyrics',
      if (app.sourceHasChords(result)) 'chords',
      if (_hasUsableTiming(result.timingTracks)) 'timing',
      if (result.candidate.album?.isNotEmpty == true ||
          result.candidate.metadata.values.any(
            (value) => value != null && value != '',
          ) ||
          result.metadata.values.any((value) => value != null && value != ''))
        'metadata',
    ];
    return [
      SourceContributionData(
        providerName: _providerName(result.candidate.providerId),
        roles: roles,
        sourceUrl: safeDiagnosticUrl(result.candidate.url),
      ),
    ];
  }

  String _providerName(String providerId) =>
      app.providers
          .where((provider) => provider.id == providerId)
          .firstOrNull
          ?.name ??
      providerId;

  static final _setupRowPattern = RegExp(
    r'^(?:capo(?: position)?|tuning|key|tempo|time signature)\s*[:=-]',
    caseSensitive: false,
  );

  static bool _isArrangementNote(String text, {bool hasChords = false}) {
    final value = text.trim();
    // Setup rows are short. Long or malformed provider text stays visible as
    // content; never feed an unbounded chord token into a repeated regex.
    if (value.isEmpty || value.length > 256) return false;
    if (_setupRowPattern.hasMatch(value)) return true;
    if ('eEBGDA'.contains(value[0]) && value.length > 1) {
      final tail = value.substring(1).trimLeft();
      if ((tail.startsWith('|') || tail.startsWith(':')) &&
          tail.length > 1 &&
          tail
              .substring(1)
              .split('')
              .every(
                (character) => '-0123456789xX|:/\\ \t'.contains(character),
              )) {
        return true;
      }
    }
    bool shape(String token) =>
        token.length >= 5 &&
        token.length <= 64 &&
        token
            .split('')
            .every((character) => '0123456789xX-'.contains(character));
    final tokens = value.split(RegExp(r'\s+'));
    if (tokens.length == 1) {
      // A bare number may be a lyric, rather than a guitar diagram.
      return shape(tokens.first) &&
          (hasChords || tokens.first.contains(RegExp(r'[xX-]')));
    }
    if (tokens.length != 2 && tokens.length != 4) return false;
    if (!shape(tokens[1]) ||
        (tokens.length == 4 &&
            (tokens[2].toLowerCase() != 'or' || !shape(tokens[3])))) {
      return false;
    }
    final chord = tokens.first;
    if (chord.length > 32) return false;
    final wrapped = '[$chord]';
    final match = arrangement.chordPattern.firstMatch(wrapped);
    return match != null && match.start == 0 && match.end == wrapped.length;
  }

  static List<LyricLineData> _previewLines(List<LyricLineData> lines) => lines
      .where(
        (line) =>
            line.text.trim().isNotEmpty &&
            line.section == null &&
            !line.isArrangementNote,
      )
      .take(3)
      .toList();

  static final _sectionPattern = RegExp(
    r'^\s*\[((?:pre[- ]?chorus|post[- ]?chorus|verse|chorus|bridge|intro|outro|instrumental|interlude|solo|refrain|hook|breakdown|coda|tag|ending)[^\]]*)\]\s*$',
    caseSensitive: false,
  );

  static List<LyricLineData> _lines(String body) =>
      _renderLines(arrangement.parseArrangement(body));

  static List<LyricLineData> _renderLines(
    List<arrangement.ArrangementLine> parsed, {
    int? transpose,
  }) {
    final transposed = <String, String>{};
    var lyricIndex = 0;
    return parsed.asMap().entries.map((entry) {
      final line = entry.value;
      final section =
          arrangement.sectionLabelForLine(line) ??
          _sectionPattern.firstMatch(line.text)?.group(1)?.trim();
      final chords = line.chords
          .map(
            (chord) => LyricChord(
              graphemeOffset: chord.offset,
              symbol: transpose == null
                  ? chord.chord
                  : transposed.putIfAbsent(
                      chord.chord,
                      () => arrangement.transposeChord(chord.chord, transpose),
                    ),
            ),
          )
          .toList();
      final hasLyrics = line.text.trim().isNotEmpty;
      final id = section != null
          ? 'section-${entry.key}'
          : line.directive
          ? 'directive-${entry.key}'
          : hasLyrics
          ? 'line-${lyricIndex++}'
          : chords.isNotEmpty
          ? 'chordline-${entry.key}'
          : 'blank-${entry.key}';
      return LyricLineData(
        id: id,
        text: section != null || line.directive ? '' : line.text,
        section: section,
        chords: chords,
        isArrangementNote: _isArrangementNote(
          line.text,
          hasChords: chords.isNotEmpty,
        ),
        isBlank:
            section != null || line.directive || (!hasLyrics && chords.isEmpty),
      );
    }).toList();
  }

  Map<String, double> _timedLineStarts(
    List<LyricLineData> lines,
    SongDocument song,
    String timingMode,
  ) => timingMode == 'timed'
      ? _readerTiming(lines, song)?.lineStarts ?? const {}
      : const {};

  ({
    String body,
    List<LyricLineData> lines,
    TimingTrack track,
    _ReaderTiming data,
  })?
  _cachedReaderTiming;

  static TimingTrack? _activeReaderTimingTrack(SongDocument song) {
    final track = song.timingTracks
        .where(
          (item) =>
              item.id == song.activeTimingTrackId &&
              item.status == TimingStatus.usable,
        )
        .firstOrNull;
    return track == null || track.cues.isEmpty ? null : track;
  }

  static _ReaderTimingInput _readerTimingInput(TimingTrack track) => (
    sourceLyrics: track.sourceLyrics,
    occurrences: jsonMap(track.extra['binding'])['occurrences'],
    cues: track.cues,
  );

  _ReaderTiming? _cachedTimingFor(
    String body,
    List<LyricLineData> lines,
    TimingTrack track,
  ) {
    final cached = _cachedReaderTiming;
    if (cached != null &&
        identical(cached.lines, lines) &&
        identical(cached.track, track) &&
        cached.body == body) {
      return cached.data;
    }
    return null;
  }

  _ReaderTiming? _readerTiming(List<LyricLineData> lines, SongDocument song) {
    final track = _activeReaderTimingTrack(song);
    if (track == null) return null;
    final cached = _cachedTimingFor(song.body, lines, track);
    if (cached != null) return cached;
    final data = _buildReaderTiming(
      _readerTimingInput(track),
      lines.map((line) => line.id),
    );
    _cachedReaderTiming = (
      body: song.body,
      lines: lines,
      track: track,
      data: data,
    );
    return data;
  }

  static _ReaderTiming _buildReaderTiming(
    _ReaderTimingInput input,
    Iterable<String> readerLineIds,
  ) {
    final rawOccurrences = input.occurrences;
    final occurrences = rawOccurrences is List
        ? rawOccurrences.whereType<Map>()
        : timingOccurrenceMapForLyrics(input.sourceLyrics);
    final targets = <String, String?>{};
    for (final mapping in occurrences) {
      final source = mapping['source'];
      final target = mapping['target'];
      if (source is String) {
        targets.putIfAbsent(source, () => target is String ? target : null);
      }
    }
    final lineIds = readerLineIds.toSet();
    final starts = <String, double>{};
    final cueTargets = <int, String?>{};
    for (final cue in input.cues) {
      final target = targets[cue.occurrenceId] ?? cue.occurrenceId;
      final valid = lineIds.contains(target);
      // Equal start times previously used the first cue, even if its target
      // is absent. Keep that tie rule for the playback lookup.
      cueTargets.putIfAbsent(cue.startUs, () => valid ? target : null);
      if (!valid) continue;
      final seconds = cue.startUs / 1000000;
      final previous = starts[target];
      if (previous == null || seconds < previous) starts[target] = seconds;
    }
    return _ReaderTiming(lineStarts: starts, cueTargets: cueTargets);
  }

  ({
    ({
      List<LyricLineData> lines,
      double duration,
      Map<String, double> timedStarts,
      Map<String, double>? estimatedStarts,
    })
    input,
    List<PlayerSectionMarker> markers,
  })?
  _sectionMarkers;

  List<PlayerSectionMarker> _playerSectionsFor({
    required List<LyricLineData> lines,
    required double duration,
    required Map<String, double> timedStarts,
    required Map<String, double>? estimatedStarts,
  }) {
    if (lines.isEmpty) return const [];
    final input = (
      lines: lines,
      duration: duration,
      timedStarts: timedStarts,
      estimatedStarts: estimatedStarts,
    );
    final cached = _sectionMarkers;
    if (cached?.input == input) return cached!.markers;
    final markers = buildPlayerSectionMarkers(
      lines: lines,
      durationSeconds: duration,
      timedLineStarts: timedStarts,
      useEstimatedFallback: estimatedStarts != null,
      estimatedLineStarts: estimatedStarts,
    );
    _sectionMarkers = (input: input, markers: markers);
    return markers;
  }

  List<LyricLineData>? _estimatedPositionLines;
  double? _estimatedPositionDuration;
  Map<String, double> _estimatedPositionStarts = const {};

  Map<String, double> _estimatedStartsFor(
    List<LyricLineData> lines,
    double duration,
  ) {
    if (!identical(_estimatedPositionLines, lines) ||
        _estimatedPositionDuration != duration) {
      _estimatedPositionLines = lines;
      _estimatedPositionDuration = duration;
      _estimatedPositionStarts = estimatedLineStartTimes(lines, duration);
    }
    return _estimatedPositionStarts;
  }

  String? _currentLineId(List<LyricLineData> lines, SongDocument? song) {
    if (song == null || lines.isEmpty) return null;
    final timingMode = app.settings['timingMode'] as String? ?? 'estimated';
    if (timingMode == 'manual') return null;
    if (timingMode == 'timed') {
      return _readerTiming(lines, song)?.lineAt((_progress * 1000000).round());
    }
    final duration = _durationForSong(song, lines: lines).seconds;
    return estimatedLineIdAtPosition(
      lines,
      progressSeconds: _progress,
      durationSeconds: duration,
      lineStartTimes: _estimatedStartsFor(lines, duration),
    );
  }

  String _subtitle(SongDocument song) => [
    if (song.metadata['album'] is String) song.metadata['album'],
    if (validDurationSeconds(song.metadata['durationSeconds'])
        case final duration?)
      formatDuration(duration),
  ].join(' · ');

  static AppThemeMode _themeMode(Object? value) => switch (value) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    _ => AppThemeMode.system,
  };

  @override
  Future<void> initialize() async {
    await app.initialize();
    // Startup is a Songs view, independent of the last bottom destination.
    // Legacy defaultView values were written on every navigation tap and are
    // not an explicit startup preference.
    _tab = VerseTab.home;
    final preferred = _startupSongsView(app.settings['startupSongsView']);
    final view = preferred == 'last'
        ? app.settings['lastSongsView']
        : preferred;
    final legacyFavorites = view == 'favorites';
    _homeMode = legacyFavorites
        ? HomeListMode.library
        : HomeListMode.values.where((mode) => mode.name == view).firstOrNull ??
              HomeListMode.recent;
    _favoritesOnly =
        preferred == 'favorites' ||
        (preferred == 'last' &&
            (legacyFavorites ||
                app.settings['lastSongsFavoritesOnly'] == true));
    _rememberSongsView();
    notifyListeners();
  }

  static String _startupSongsView(Object? value) =>
      const {'recent', 'library', 'favorites', 'online', 'last'}.contains(value)
      ? value! as String
      : 'recent';

  void _rememberSongsView() {
    final view = _homeMode.name;
    if (app.settings['lastSongsView'] != view) {
      unawaited(_guard(() => app.setSetting('lastSongsView', view)));
    }
    if (app.settings['lastSongsFavoritesOnly'] != _favoritesOnly) {
      unawaited(
        _guard(() => app.setSetting('lastSongsFavoritesOnly', _favoritesOnly)),
      );
    }
  }

  @override
  Future<void> setStartupSongsView(String view) =>
      _setSetting('startupSongsView', _startupSongsView(view));

  /// Stores a preference. A failed write is reported instead of escaping from
  /// an unawaited UI callback, and the screen is brought back in step with the
  /// value the controller now holds.
  Future<void> _setSetting(String key, Object? value) =>
      _guardSetting(() => app.setSetting(key, value));

  Future<void> _guardSetting(Future<void> Function() write) async {
    if (!await _guard(write)) notifyListeners();
  }

  @override
  void setTab(VerseTab tab) {
    _beginNavigationIntent();
    // Keep the former Songs route as a Library alias for conflict review and
    // older callers. The visible navigation has one Songs destination.
    _tab = tab == VerseTab.songs ? VerseTab.home : tab;
    if (tab == VerseTab.songs) {
      _homeMode = HomeListMode.library;
      // Conflict review should reveal every conflict copy without local
      // search or favorites filters hiding some of them.
      if (_conflictFilter) {
        _query = '';
        _favoritesOnly = false;
      }
    }
    _route = VerseRoute.main;
    _draftSetlist = null;
    _draftSetlistInitialName = null;
    _setlistId = null;
    _setlistEntryId = null;
    if (_tab == VerseTab.home) _rememberSongsView();
    notifyListeners();
  }

  @override
  void setHomeListMode(HomeListMode mode) {
    _searchDebounce?.cancel();
    if (mode == HomeListMode.favorites) {
      // Compatibility for persisted and older callers: Favorites is the
      // Library view with its local favorites filter enabled.
      _homeMode = HomeListMode.library;
      _favoritesOnly = true;
    } else {
      _homeMode = mode;
    }
    _rememberSongsView();
    if (mode == HomeListMode.online) {
      _normalizeOnlineMetadataFilter();
      if (_query.trim().isNotEmpty &&
          _selectedQuery != _query.trim() &&
          _lastCatalogQuery != _query.trim()) {
        unawaited(_guard(submitSearch));
      }
    }
    notifyListeners();
  }

  @override
  void setFavoritesOnly(bool value) {
    if (_favoritesOnly == value) return;
    _favoritesOnly = value;
    _rememberSongsView();
    notifyListeners();
  }

  void _normalizeOnlineMetadataFilter() {
    if (_filters.field != 'lyrics') return;
    _filters = SearchFilterData(
      field: 'all',
      language: _filters.language,
      chordsOnly: _filters.chordsOnly,
      timedOnly: _filters.timedOnly,
      durationBucket: _filters.durationBucket,
    );
  }

  @override
  void setQuery(String value) {
    final online = _homeMode == HomeListMode.online;
    if (online && _query.trim() != value.trim()) {
      _cachedAutocomplete = const [];
      _versionOrderReferenceId = null;
      _versionArrivalOrder.clear();
      _nextVersionArrivalOrder = 0;
    }
    _query = value;
    if (online) app.errorCode = null;
    if (online && _selectedQuery != value.trim()) {
      _selectedVersionId = null;
      _selectedQuery = null;
    }
    if (_homeMode == HomeListMode.online) {
      _normalizeOnlineMetadataFilter();
    }
    _searchDebounce?.cancel();
    // Typing in a local view filters that view without contacting providers.
    if (online) {
      _lastCatalogQuery = null;
      app.cancelSearch();
    }
    if (_homeMode == HomeListMode.online && value.trim().length >= 2) {
      _searchDebounce = Timer(
        const Duration(milliseconds: 360),
        () => unawaited(_guard(() => _searchCatalog(value))),
      );
    }
    notifyListeners();
  }

  @override
  void changeSearchSong() {
    _beginNavigationIntent();
    _selectedQuery = null;
    _selectedVersionId = null;
    _route = VerseRoute.main;
    _tab = VerseTab.home;
    _homeMode = HomeListMode.online;
    _rememberSongsView();
    notifyListeners();
  }

  @override
  Future<void> submitSearch() async {
    if (_query.trim().length < 2) return;
    if (_homeMode != HomeListMode.online && _hasLocalSearchMatches()) return;
    _homeMode = HomeListMode.online;
    _normalizeOnlineMetadataFilter();
    _rememberSongsView();
    _searchDebounce?.cancel();
    notifyListeners();
    await _searchCatalog(_query);
  }

  // Use the same fields and filters as the visible local lists. Typing stays
  // local; only an explicit Search with no visible matches opens Online.
  bool _hasLocalSearchMatches() {
    final current = state;
    final needle = foldForSearch(_query);
    if (_homeMode == HomeListMode.recent) {
      return current.recent.any(
        (item) =>
            !item.isSetlist &&
            (!_favoritesOnly || item.favorite) &&
            foldForSearch(
              '${item.title} ${item.artist} ${item.subtitle}',
            ).contains(needle),
      );
    }
    return current.songs.any(
      (song) =>
          (!_conflictFilter || song.isConflictCopy) &&
          (_conflictFilter || !_favoritesOnly || song.favorite) &&
          songMatchesQuery(song, needle),
    );
  }

  @override
  Future<void> setSearchCatalog(String id) => _guard(() async {
    final inSettings = _route == VerseRoute.main && _tab == VerseTab.settings;
    final inOnlineSearch =
        _route == VerseRoute.main &&
        _tab == VerseTab.home &&
        _homeMode == HomeListMode.online &&
        app.selection == null;
    if (_disposed || (!inSettings && !inOnlineSearch)) {
      return;
    }
    if (!app.searchCatalogs.any((provider) => provider.id == id)) return;
    final intent = _beginNavigationIntent();
    final change = ++_catalogChangeRevision;
    ++_catalogRequestRevision;
    _searchDebounce?.cancel();
    _cachedAutocomplete = const [];
    _lastCatalogQuery = null;
    _selectedQuery = null;
    _selectedVersionId = null;
    _versionOrderReferenceId = null;
    _versionArrivalOrder.clear();
    _nextVersionArrivalOrder = 0;
    final query = _query;
    final changed = await app.setSearchCatalog(id);
    if (!changed ||
        change != _catalogChangeRevision ||
        !_isCurrentNavigationIntent(intent) ||
        app.searchCatalogId != id) {
      return;
    }
    if (inSettings) {
      notifyListeners();
      return;
    }
    if (_tab != VerseTab.home ||
        _homeMode != HomeListMode.online ||
        _query != query) {
      return;
    }
    _searchDebounce?.cancel();
    if (query.trim().length >= 2) await _searchCatalog(query);
    notifyListeners();
  });

  Future<void> _searchCatalog(String query) async {
    final request = ++_catalogRequestRevision;
    final catalog = app.searchCatalogId;
    _lastCatalogQuery = query.trim();
    await app.search(query);
    if (_disposed ||
        request != _catalogRequestRevision ||
        catalog != app.searchCatalogId ||
        _query != query) {
      return;
    }
    _cachedAutocomplete = app.suggestions;
    notifyListeners();
    await _catalogProjectionTask;
  }

  @override
  void toggleSearchFilters() {
    _filtersExpanded = !_filtersExpanded;
    notifyListeners();
  }

  @override
  void setSearchFilter(String key, Object? value) {
    _filters = SearchFilterData(
      field: key == 'field' ? value as String : _filters.field,
      language: key == 'language' ? value as String : _filters.language,
      chordsOnly: key == 'chordsOnly' ? value as bool : _filters.chordsOnly,
      timedOnly: key == 'timedOnly' ? value as bool : _filters.timedOnly,
      durationBucket: key == 'durationBucket'
          ? value as String
          : _filters.durationBucket,
    );
    // A deliberate filter change can choose a matching fallback. Background
    // provider updates cannot clear the explicit choice in this way.
    final selectedId = _selectedVersionId;
    if (selectedId == 'combined' && !_combinedMatchesFilters(app.combined)) {
      _selectedVersionId = null;
    } else if (selectedId != null && selectedId != 'combined') {
      final source = app.results
          .where((item) => item.id == selectedId)
          .firstOrNull;
      if (source != null && !_sourceMatchesFilters(source)) {
        _selectedVersionId = null;
      }
    }
    final effectiveSelection = _comparison()?.selectedVersionId;
    if (effectiveSelection != null || _selectedVersionId != null) {
      _selectedVersionId = effectiveSelection;
    }
    app.prepareVersionForSave(
      _selectedVersionId ?? 'combined',
      allowRejectedSource: true,
    );
    notifyListeners();
  }

  /// Loads the next page of history. Re-entrant calls while a page is loading
  /// are ignored so scrolling and the "Full history" button cannot double-load.
  @override
  Future<void> loadMoreRecent() async {
    if (_loadingMoreRecent || !app.hasMoreRecent) return;
    _loadingMoreRecent = true;
    notifyListeners();
    try {
      await app.loadMoreRecent();
    } catch (_) {
      postNotice(UiNotice.genericError);
    } finally {
      _loadingMoreRecent = false;
      notifyListeners();
    }
  }

  @override
  void clearHistory() => unawaited(_clearHistory());

  Future<void> _clearHistory() async {
    try {
      await app.clearHistory();
      postNotice(UiNotice.historyCleared);
    } catch (_) {
      postNotice(UiNotice.genericError);
    }
  }

  @override
  Future<void> selectReference(SearchReferenceData reference) async {
    final request = _catalogRequestRevision;
    final candidates = app.suggestions.isNotEmpty
        ? app.suggestions
        : _cachedAutocomplete;
    if (app.suggestions.isNotEmpty) _cachedAutocomplete = app.suggestions;
    final row = candidates
        .where((item) => item.identity == reference.id)
        .firstOrNull;
    if (row == null) return;
    final candidate = withRowFacts(
      row,
      album: reference.album,
      durationSeconds: reference.durationSeconds,
    );
    _selectedVersionId = null;
    _selectedQuery = _query.trim();
    await app.selectCandidate(candidate);
    if (_disposed ||
        request != _catalogRequestRevision ||
        app.selection?.identity != candidate.identity) {
      return;
    }
    _chooseFallbackVersion();
    notifyListeners();
  }

  @override
  Future<void> retrySelectedSongDiscovery() async {
    final candidate = app.selection;
    if (candidate == null) return;
    _selectedVersionId = null;
    _selectedQuery = _query.trim();
    await _guard(() => app.selectCandidate(candidate));
    // Another song may have been opened while this discovery was cancelled;
    // its default version is not this request's to choose.
    if (_disposed || app.selection?.identity != candidate.identity) return;
    _chooseFallbackVersion();
    notifyListeners();
  }

  void _chooseFallbackVersion() {
    if (_disposed) return;
    // Discovery completion must never replace an explicit choice, including a
    // version whose final validation failed. Keep it selected and explain why
    // it cannot be saved, until the person chooses another version.
    if (_selectedVersionId case final selectedId?) {
      app.prepareVersionForSave(selectedId, allowRejectedSource: true);
      return;
    }
    final combined = app.combined;
    final combinedMatchesFilters = _combinedMatchesFilters(combined);
    _selectedVersionId = combinedMatchesFilters
        ? null
        : app.results
              .where(_sourceMatchesFilters)
              .where(
                (source) =>
                    app.savedResultId(source: source) == null &&
                    _isUsableResult(source, allowRejected: true),
              )
              .firstOrNull
              ?.id;
    app.prepareVersionForSave(
      _selectedVersionId ?? 'combined',
      allowRejectedSource: true,
    );
  }

  @override
  void selectVersion(String versionId) {
    _selectedVersionId = versionId;
    app.prepareVersionForSave(versionId, allowRejectedSource: true);
    notifyListeners();
  }

  bool _savingSelectedVersion = false;

  @override
  Future<void> saveVersion(String versionId) {
    if (_savingSelectedVersion) return Future<void>.value();
    if (_selectedVersionId != versionId) selectVersion(versionId);
    return saveSelectedVersion();
  }

  @override
  Future<void> saveSelectedVersion() async {
    if (_savingSelectedVersion) return;
    _savingSelectedVersion = true;
    try {
      await _saveSelectedVersion();
    } finally {
      _savingSelectedVersion = false;
      _pendingLibraryEstimates = Expando<PlayerDuration>();
      if (_invalidateDeferredLibraryEstimates()) notifyListeners();
    }
  }

  /// Resolves the same default as the comparison without building the library,
  /// diagnostic metadata or previews in response to a Save tap.
  String? _versionIdForSave() {
    if (_selectedVersionId case final selectedId?) return selectedId;
    if (_combinedMatchesFilters(app.combined)) return 'combined';
    final candidate = app.selection;
    final hasComparison = candidate != null && _selectedQuery == _query.trim();
    if (hasComparison) {
      _rememberVersionArrivalOrder(candidate.identity, app.results);
    }
    SourceResult? earliest;
    for (final result in app.results) {
      if (!_sourceMatchesFilters(result) ||
          !_isUsableResult(result, allowRejected: true)) {
        continue;
      }
      if (!hasComparison) return result.id;
      if (earliest == null ||
          _versionArrivalOrder[result.id]! <
              _versionArrivalOrder[earliest.id]!) {
        earliest = result;
      }
    }
    return earliest?.id;
  }

  Future<void> _saveSelectedVersion() async {
    final selectedId = _versionIdForSave();
    if (selectedId == null) {
      postNotice(UiNotice.songSaveFailed);
      return;
    }
    var version = selectedId == 'combined'
        ? null
        : app.results.where((item) => item.id == selectedId).firstOrNull;
    if (version != null && !app.isSourceReady(version)) {
      final savedSongId = app.savedResultId(source: version);
      if (savedSongId != null) {
        final navigationIntent = _beginNavigationIntent();
        await _openSong(
          savedSongId,
          navigationIntent: navigationIntent,
          returnToRecent: true,
        );
        return;
      }
    }
    final navigationIntent = _beginNavigationIntent();
    while (version != null &&
        version.body.length > _inlinePreviewLimit &&
        _knownSourceLyrics(version) == null &&
        !app.isUsableChordOnlySource(version)) {
      await _waitForSourceLyrics(version);
      if (!_isCurrentNavigationIntent(navigationIntent) ||
          (_selectedVersionId != null && _selectedVersionId != selectedId)) {
        return;
      }
      version = app.results.where((item) => item.id == selectedId).firstOrNull;
    }
    if (selectedId == 'combined' && !app.canSavePreparedCombined) {
      final prepared = await app.waitForPreparedCombined();
      if (!_isCurrentNavigationIntent(navigationIntent) ||
          (_selectedVersionId != null && _selectedVersionId != selectedId)) {
        return;
      }
      if (!prepared) {
        postNotice(UiNotice.songSaveFailed);
        return;
      }
    }
    if (selectedId == 'combined' &&
        (!_combinedMatchesFilters(app.combined) ||
            app.combined == null ||
            !_hasUsableDocument(app.combined!))) {
      postNotice(UiNotice.songSaveFailed);
      return;
    }
    if (selectedId != 'combined' &&
        (version == null || !_isUsableResult(version, allowRejected: true))) {
      postNotice(UiNotice.songSaveFailed);
      return;
    }
    final SongDocument song;
    _SavedReaderWork? preparedReader;
    try {
      song = await app.saveResult(
        source: version,
        allowRejectedSource: version != null,
        includeEvidence: false,
        onChartPrepared: (chart) {
          if (_isCurrentNavigationIntent(navigationIntent)) {
            preparedReader = _startSavedReaderWork(chart);
          }
        },
      );
    } catch (_) {
      postNotice(UiNotice.songSaveFailed);
      return;
    }
    if (_isCurrentNavigationIntent(navigationIntent)) {
      await _openSong(
        song.id,
        navigationIntent: navigationIntent,
        returnToRecent: true,
        savedChart: true,
        preparedReader: preparedReader,
      );
    }
    postNotice(UiNotice.songSaved);
  }

  @override
  Future<void> compareCurrentSongVersions() async {
    final song = currentSong;
    if (song == null) return;
    final reference = _comparisonReference(song);
    if (reference == null) return;
    final navigationIntent = _beginNavigationIntent();
    final reuseComparison =
        app.selection?.identity == reference.identity &&
        _songMatchesSearchReference(song, reference.identity) &&
        _selectedQuery == _query.trim() &&
        _query.trim() == app.query.trim();
    _searchDebounce?.cancel();
    _stopPlayer();
    _setlistId = null;
    _setlistEntryId = null;
    _route = VerseRoute.main;
    _tab = VerseTab.home;
    _homeMode = HomeListMode.online;
    _rememberSongsView();
    _selectedVersionId = song.extra['combinedSelection'] == reference.identity
        ? 'combined'
        : song.extra['selectedSourceId'] as String?;
    // A saved recording reference survives restart and avoids a new catalog
    // search choosing a different artist or recording with the same title.
    if (!reuseComparison) {
      _filters = const SearchFilterData();
      _filtersExpanded = false;
      _query = [
        reference.title,
        reference.artist,
      ].where((part) => part.trim().isNotEmpty).join(' ');
      _selectedQuery = _query.trim();
      _cachedAutocomplete = [reference];
      final query = _query;
      final refresh = _guard(
        () =>
            reference.providerId == 'wikisource' ||
                song.extra.containsKey('libraryEvidenceIdentity')
            ? app.compareSavedSong(
                song.id,
                expectedReference: reference,
                searchQuery: query,
              )
            : app.selectCandidate(
                reference,
                searchQuery: query,
                cachedResults: song.sources,
              ),
      );
      notifyListeners();
      await refresh;
      // Leaving this comparison (back, another song, a tab) ends the request;
      // it must not choose a version for whatever is on screen now.
      if (!_isCurrentNavigationIntent(navigationIntent)) return;
      _chooseFallbackVersion();
      notifyListeners();
      return;
    }
    _selectedQuery = app.query.trim();
    app.prepareVersionForSave(
      _selectedVersionId ?? 'combined',
      allowRejectedSource: true,
    );
    notifyListeners();
  }

  @override
  Future<void> openSong(String id) async {
    if (app.findSong(id) == null) return;
    final navigationIntent = _beginNavigationIntent();
    await _openSong(id, navigationIntent: navigationIntent);
  }

  @override
  Future<void> openSetlistEntry(String setlistId, String entryId) async {
    final setlist = app.setlists
        .where((item) => item.id == setlistId)
        .firstOrNull;
    final entry = setlist?.entries
        .where((item) => item.id == entryId)
        .firstOrNull;
    if (entry == null || app.findSong(entry.songId) == null) return;
    final navigationIntent = _beginNavigationIntent();
    await _openSong(
      entry.songId,
      navigationIntent: navigationIntent,
      setlistId: setlistId,
      setlistEntryId: entryId,
    );
  }

  _SavedReaderWork? _startSavedReaderWork(SongDocument song) {
    final chart = (body: song.body, transpose: _savedChartTranspose(song));
    final cached = _readerChart;
    final cachedLines =
        cached != null &&
            cached.body == chart.body &&
            cached.transpose == chart.transpose
        ? cached.lines
        : null;
    final track = _activeReaderTimingTrack(song);
    final needsTiming =
        track != null &&
        (cachedLines == null ||
            _cachedTimingFor(chart.body, cachedLines, track) == null);
    final duration = _durationWithoutChartEstimate(song);
    final needsEstimate =
        _playbackDurations[song] == null &&
        duration.kind == PlayerDurationKind.chartEstimate;
    final needsEstimatedStarts =
        needsEstimate ||
        cachedLines == null ||
        !identical(_estimatedPositionLines, cachedLines) ||
        _estimatedPositionDuration != duration.seconds;
    if (!needsTiming && !needsEstimatedStarts) return null;

    final projection = compute(_prepareReaderProjection, (
      chart: chart,
      cachedLines: cachedLines,
      timing: needsTiming ? _readerTimingInput(track) : null,
      durationSeconds: duration.seconds,
      estimateDuration: needsEstimate,
      prepareEstimatedStarts: needsEstimatedStarts,
    ), debugLabel: 'singbook-reader-chart');
    // Save can fail or the user can leave before claiming the projection.
    unawaited(projection.then<void>((_) {}, onError: (Object _) {}));
    return (
      song: song,
      chart: chart,
      track: track,
      duration: duration,
      cachedLines: cachedLines,
      projection: projection,
    );
  }

  Future<void> _openSong(
    String id, {
    int? navigationIntent,
    String? setlistId,
    String? setlistEntryId,
    bool returnToRecent = false,
    bool savedChart = false,
    _SavedReaderWork? preparedReader,
  }) async {
    final intent = navigationIntent ?? _beginNavigationIntent();
    _playerPreferenceDebounce?.cancel();
    final preferences = _savePlayerPreferences();
    if (savedChart) {
      unawaited(preferences);
    } else {
      await preferences;
    }
    if (!_isCurrentNavigationIntent(intent)) return;
    final initialSong = app.findSong(id);
    if (initialSong == null) return;
    var song = initialSong;
    while (savedChart) {
      final prepared = preparedReader;
      preparedReader = null;
      final work =
          prepared != null &&
              identical(song, prepared.song) &&
              _savedChartTranspose(song) == prepared.chart.transpose
          ? prepared
          : _startSavedReaderWork(song);
      if (work == null) {
        _playbackDurations[song] ??= _durationWithoutChartEstimate(song);
        break;
      }
      final (
        chart: input,
        :duration,
        :track,
        :cachedLines,
        song: projectedSong,
        projection: pendingProjection,
      ) = work;
      final _ReaderProjection projection;
      try {
        projection = await pendingProjection;
      } catch (_) {
        // The chart is already saved. Open the reader and let it prepare the
        // lines itself rather than losing the navigation and the notice.
        if (!_isCurrentNavigationIntent(intent)) return;
        break;
      }
      if (!_isCurrentNavigationIntent(intent)) return;
      final current = app.findSong(id);
      if (current == null) return;
      song = current;
      if (song.body == input.body &&
          _savedChartTranspose(song) == input.transpose) {
        final lines = cachedLines ?? projection.lines;
        if (identical(song, projectedSong)) {
          _playbackDurations[song] ??= duration;
        }
        var projectedSeconds = duration.seconds;
        if (projection.estimate case final estimate?) {
          if (estimate > projectedSeconds) projectedSeconds = estimate;
          _playbackDurations[song] = identical(song, projectedSong)
              ? PlayerDuration(projectedSeconds, duration.kind)
              : resolvePlayerDuration(song, estimate: () => estimate);
          _invalidateDeferredLibraryEstimates();
        }
        _readerChart = (
          body: input.body,
          transpose: input.transpose,
          lines: lines,
        );
        if (projection.estimatedStarts case final starts?) {
          _estimatedPositionLines = lines;
          _estimatedPositionDuration = projectedSeconds;
          _estimatedPositionStarts = starts;
        }
        if (identical(_activeReaderTimingTrack(song), track)) {
          if (projection.timing case final timing? when track != null) {
            _cachedReaderTiming = (
              body: input.body,
              lines: lines,
              track: track,
              data: timing,
            );
          }
          if (_playbackDurations[song]?.seconds == _estimatedPositionDuration) {
            break;
          }
        }
      }
    }
    _setlistId = setlistId;
    _setlistEntryId = setlistEntryId;
    if (returnToRecent) _homeMode = HomeListMode.recent;
    _songId = id;
    _route = VerseRoute.reader;
    _stopPlayer();
    _progress = 0;
    // A reopened chart can use the current values while their write finishes.
    final pending = savedChart ? _pendingPlayerPreferences[id] : null;
    _transpose = pending?.transpose.toDouble() ?? _storedTranspose(song);
    _playbackSpeed = pending?.speed ?? _storedPlaybackSpeed(song);
    notifyListeners();
    final record = _recordRecentSong(id);
    if (!savedChart) await record;
  }

  @override
  Future<void> openSetlist(String id) async {
    _beginNavigationIntent();
    _setlistEditSessionRevision++;
    _setlistId = id;
    _setlistEntryId = null;
    _editingSetlist = false;
    _route = VerseRoute.setlistDetail;
    final value = currentSetlist;
    // Navigate first: the visit is recorded behind any history page that is
    // still loading, and a failed write must not leave the route unannounced.
    notifyListeners();
    if (value != null) await _guard(() => app.recordUse('setlist', id));
  }

  @override
  Future<void> editSong(String id) async {
    final navigationIntent = _beginNavigationIntent();
    _playerPreferenceDebounce?.cancel();
    await _savePlayerPreferences();
    if (!_isCurrentNavigationIntent(navigationIntent)) return;
    final song = app.findSong(id);
    if (song == null) return;
    // Editing from the song's own reader keeps its transpose and position;
    // editing another song starts from a clean reader state.
    _editorReturnsToReader = _route == VerseRoute.reader && _songId == id;
    // The playback clock must not keep running behind the editor; the song's
    // own reader keeps its position and resumes from there.
    _stopPlayer();
    if (_songId != id) {
      _progress = 0;
      _transpose = _storedTranspose(song);
      _playbackSpeed = _storedPlaybackSpeed(song);
      _setlistEntryId = null;
    }
    _songId = id;
    _openEditor(song, isNew: false);
    notifyListeners();
  }

  /// Whether leaving the open editor returns to the song's reader (it was
  /// entered from there) rather than to the list it was opened from.
  bool _editorReturnsToReader = true;

  void _openEditor(SongDocument song, {required bool isNew}) {
    _editorSessionRevision++;
    final metadata = song.metadata;
    String text(String key) => metadata[key]?.toString() ?? '';
    _editorBaseHash = isNew ? null : app.songHash(song.id);
    _editorData = SongEditorData(
      songId: song.id,
      isNew: isNew,
      title: song.title,
      artist: song.artist,
      album: text('album'),
      key: text('key'),
      capo: text('capo'),
      tuning: text('tuning'),
      tempo: text('tempo'),
      duration: text('durationSeconds'),
      body: song.body,
    );
    _editorDirty = false;
    _editing = true;
    _route = VerseRoute.editor;
  }

  @override
  void setEditorDirty(bool dirty) {
    if (_editorDirty == dirty) return;
    _editorDirty = dirty;
    notifyListeners();
  }

  @override
  Future<void> editSetlist(String id) async {
    _beginNavigationIntent();
    _setlistEditSessionRevision++;
    _setlistId = id;
    _editingSetlist = true;
    _setlistBaseHash = app.setlistHash(id);
    _route = VerseRoute.setlistDetail;
    notifyListeners();
  }

  @override
  Future<void> toggleSongFavorite(String id) async {
    final song = app.findSong(id);
    if (song == null) return;
    await _guard(() => app.toggleFavorite(song));
  }

  @override
  Future<void> toggleSetlistFavorite(String id) async {
    final draft = _draftSetlist;
    if (draft != null && draft.id == id) {
      _draftSetlist = draft.copyWith(favorite: !draft.favorite);
      notifyListeners();
      return;
    }
    final value = app.setlists.where((item) => item.id == id).firstOrNull;
    if (value == null) return;
    await _guard(() => app.toggleSetlistFavorite(value));
  }

  @override
  Future<void> createSong() {
    _beginNavigationIntent();
    final song = SongDocument(id: newId(), title: '', artist: '', body: '');
    _stopPlayer();
    _progress = 0;
    _transpose = 0;
    _playbackSpeed = 1;
    _setlistId = null;
    _setlistEntryId = null;
    _songId = song.id;
    _draftSong = song;
    _editorReturnsToReader = false;
    _openEditor(song, isNew: true);
    notifyListeners();
    return Future<void>.value();
  }

  @override
  Future<void> createSetlist({String? name, String? songId}) async {
    final navigationIntent = songId == null ? _beginNavigationIntent() : null;
    final value = SetlistDocument(
      id: newId(),
      name: name?.trim() ?? '',
      entries: songId == null
          ? const []
          : [SetlistEntry(id: newId(), songId: songId)],
    );
    if (songId != null) {
      // Adding a song to a brand-new setlist keeps the person where they are.
      await _guard(() => app.saveSetlist(value));
      return;
    }
    if (!_isCurrentNavigationIntent(navigationIntent!)) return;
    // Opening the form is not a library write. Keep its placeholder private
    // until the person supplies a name, notes or at least one song.
    _draftSetlist = value;
    _draftSetlistInitialName = value.name;
    _setlistEditSessionRevision++;
    _setlistBaseHash = null;
    _editingSetlist = true;
    _setlistId = value.id;
    _route = VerseRoute.setlistDetail;
    notifyListeners();
  }

  @override
  Future<void> duplicateSetlist(String id, {String? copyName}) async {
    final original = app.setlists.where((item) => item.id == id).firstOrNull;
    if (original == null) return;
    final copy = SetlistDocument(
      id: newId(),
      name: copyName ?? original.name,
      notes: original.notes,
      entries: original.entries
          .map(
            (entry) => SetlistEntry(
              id: newId(),
              songId: entry.songId,
              overrides: entry.overrides,
            ),
          )
          .toList(),
    );
    await _guard(() => app.saveSetlist(copy));
  }

  /// Runs a library write, reporting failure; returns whether it succeeded.
  Future<bool> _guard(
    Future<void> Function() action, {
    UiNotice failure = UiNotice.genericError,
  }) async {
    try {
      await action();
      return true;
    } catch (_) {
      postNotice(failure);
      return false;
    }
  }

  Future<void> _export<T>(
    T? value,
    Future<void> Function(T value)? action, {
    bool copy = false,
  }) async {
    if (value == null || action == null) return;
    try {
      await action(value);
      if (copy) postNotice(UiNotice.copied);
    } on FormatException catch (error) {
      postNotice(_failureNotice(error, UiNotice.exportFailed));
    } catch (_) {
      postNotice(UiNotice.exportFailed);
    }
  }

  /// Maps a file action's stable [FormatException] code (or the timing
  /// payload size message) to the notice that explains it.
  static UiNotice _failureNotice(FormatException error, UiNotice fallback) {
    final message = error.message;
    return switch (message) {
      'file_too_large' || 'backup_too_large' => UiNotice.importTooLarge,
      'unsupported_file' => UiNotice.importUnsupported,
      'pdf_too_large' => UiNotice.exportPdfTooLarge,
      'duplicate_song_id' => UiNotice.importDuplicateSongId,
      _ when message.startsWith('Timing payload exceeds') =>
        UiNotice.timingTooLarge,
      _ => fallback,
    };
  }

  SetlistDocument? _setlistById(String id) =>
      app.setlists.where((item) => item.id == id).firstOrNull ??
      (_draftSetlist?.id == id ? _draftSetlist : null);

  SongDocument? _readerPdfSong(String id) {
    final song = app.findSong(id);
    if (song == null || _route != VerseRoute.reader || _songId != id) {
      return song;
    }

    final metadata = Map<String, Object?>.from(song.metadata);
    final key = displayedKey;
    final capo = displayedCapo;
    if (key != null) metadata['key'] = key;
    if (capo != null) metadata['capo'] = capo;
    return song.copyWith(
      body: arrangement.transposeBody(song.body, _effectiveTranspose(song)),
      metadata: metadata,
    );
  }

  @override
  Future<void> shareSong(String id) => _export(app.findSong(id), onShareSong);

  @override
  Future<void> shareSongPdf(String id) =>
      _export(_readerPdfSong(id), onShareSongPdf);

  @override
  Future<void> copySongChordPro(String id) =>
      _export(app.findSong(id), onCopySong, copy: true);

  @override
  Future<void> printSong(String id) => _export(_readerPdfSong(id), onPrintSong);

  @override
  Future<void> shareSetlist(String id) =>
      _export(_setlistById(id), onShareSetlist);

  @override
  Future<void> shareSetlistPdf(String id) =>
      _export(_setlistById(id), onShareSetlistPdf);

  @override
  Future<void> copySetlist(String id) =>
      _export(_setlistById(id), onCopySetlist, copy: true);

  @override
  Future<void> printSetlist(String id) =>
      _export(_setlistById(id), onPrintSetlist);

  // -- Playback ------------------------------------------------------------

  double _playerDuration() {
    final song = currentSong;
    return song == null ? 0 : _durationForSong(song).seconds;
  }

  void _stopPlayer() {
    _playing = false;
    _playerTimer?.cancel();
    _playerTimer = null;
    _playWatch.stop();
  }

  void _resetPlayClock() {
    _playBase = _progress;
    _playWatch
      ..reset()
      ..start();
  }

  @override
  Future<void> playPause() async {
    if (currentSong == null) return;
    _playing = !_playing;
    _playerTimer?.cancel();
    _playerTimer = null;
    if (_playing) {
      // Playing again after the song ended starts over from the beginning.
      final duration = _playerDuration();
      if (duration > 0 && _progress >= duration) _progress = 0;
      _resetPlayClock();
      _playerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _advancePlayer(
          _playBase + _playWatch.elapsedMilliseconds / 1000 * _playbackSpeed,
        );
      });
    } else {
      _playWatch.stop();
    }
    notifyListeners();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    if (!speed.isFinite || speed < .5 || speed > 2 || speed == _playbackSpeed) {
      return;
    }
    if (_playing) {
      _advancePlayer(
        _playBase + _playWatch.elapsedMilliseconds / 1000 * _playbackSpeed,
      );
    }
    _playbackSpeed = speed;
    _schedulePlayerPreferenceSave();
    if (_playing) _resetPlayClock();
    notifyListeners();
  }

  /// Moves playback forward by [seconds] as if the clock had run (for tests).
  @visibleForTesting
  void advancePlayerBy(double seconds) {
    _playBase += seconds;
    _advancePlayer(_progress + seconds);
  }

  void _advancePlayer(double seconds) {
    if (_disposed) return;
    final duration = _playerDuration();
    _progress = seconds.clamp(0, duration).toDouble();
    if (_progress >= duration) {
      _stopPlayer();
      notifyListeners();
    } else {
      _refreshPosition();
    }
  }

  @override
  Future<void> seek(double seconds) async {
    _progress = seconds;
    if (_playing) _resetPlayClock();
    _refreshPosition();
  }

  @override
  Future<void> nextSong() async => _advance(1);
  @override
  Future<void> previousSong() async => _advance(-1);
  Future<void> _advance(int direction) async {
    final list = currentSetlist;
    final songId = _songId;
    if (list == null || songId == null || _route != VerseRoute.reader) return;
    final listId = list.id;
    final entryId = _setlistEntryId;
    var index = list.entries.indexWhere((entry) => entry.id == entryId);
    if (entryId == null || index < 0) {
      index = list.entries.indexWhere((entry) => entry.songId == songId);
    }
    if (index < 0) return;
    final navigationIntent = _beginNavigationIntent();
    _playerPreferenceDebounce?.cancel();
    await _savePlayerPreferences();
    if (!_isCurrentNavigationIntent(navigationIntent) ||
        _route != VerseRoute.reader ||
        _setlistId != listId ||
        _setlistEntryId != entryId ||
        _songId != songId) {
      return;
    }
    final currentList = _setlistById(listId);
    if (currentList == null) return;
    final currentIndex = entryId == null
        ? currentList.entries.indexWhere((entry) => entry.songId == songId)
        : currentList.entries.indexWhere((entry) => entry.id == entryId);
    if (currentIndex < 0) return;
    var next = currentIndex + direction;
    // Entries whose song was deleted cannot be opened; step over them.
    while (next >= 0 &&
        next < currentList.entries.length &&
        app.findSong(currentList.entries[next].songId) == null) {
      next += direction;
    }
    if (next < 0 || next >= currentList.entries.length) return;
    final target = currentList.entries[next];
    _songId = target.songId;
    _setlistEntryId = target.id;
    _progress = 0;
    final song = app.findSong(_songId!);
    _transpose = _storedTranspose(song);
    _playbackSpeed = _storedPlaybackSpeed(song);
    if (_playing) _resetPlayClock();
    notifyListeners();
    // The song was opened from the setlist: it belongs in Recent too. Recorded
    // after navigating so the player never waits for the database.
    final opened = _songId;
    if (opened != null) unawaited(_recordRecentSong(opened));
  }

  final Set<Future<bool>> _pendingRecentRecords = {};

  Future<bool> _recordRecentSong(String id) {
    final record = _guard(() => app.recordUse('song', id));
    _pendingRecentRecords.add(record);
    unawaited(record.whenComplete(() => _pendingRecentRecords.remove(record)));
    return record;
  }

  /// Completes when outstanding reader visits are stored in Recent
  /// (for tests, which must await real database work in `runAsync`).
  @visibleForTesting
  Future<void> settleRecentRecords() async {
    while (_pendingRecentRecords.isNotEmpty) {
      await Future.wait(_pendingRecentRecords.toList());
    }
  }

  @override
  Future<void> transpose(int semitones) async {
    _transpose += semitones;
    _schedulePlayerPreferenceSave();
    notifyListeners();
  }

  static const _playerTransposeMetadataKey = 'x_verse_player_transpose';
  static const _playerSpeedMetadataKey = 'x_verse_player_speed';

  double _storedTranspose(SongDocument? song) {
    final value = song?.metadata[_playerTransposeMetadataKey];
    return value is num && value.isFinite ? value.roundToDouble() : 0;
  }

  double _storedPlaybackSpeed(SongDocument? song) {
    final value = song?.metadata[_playerSpeedMetadataKey];
    return value is num && value.isFinite && value >= .5 && value <= 2
        ? value.toDouble()
        : 1;
  }

  void _schedulePlayerPreferenceSave() {
    final id = _songId;
    if (id == null || app.findSong(id) == null) return;
    // Capture both the song and values now; navigation can change the reader
    // before the debounce or an in-flight write finishes.
    _pendingPlayerPreferences[id] = (
      revision: ++_playerPreferenceRevision,
      transpose: _transpose.round(),
      speed: _playbackSpeed,
    );
    _playerPreferenceDebounce?.cancel();
    _playerPreferenceDebounce = Timer(const Duration(milliseconds: 400), () {
      _playerPreferenceDebounce = null;
      unawaited(_savePlayerPreferences());
    });
  }

  Future<void> _savePlayerPreferences() {
    final running = _playerPreferenceSave;
    if (running != null) return running;
    final completion = _drainPlayerPreferences().whenComplete(() {
      _playerPreferenceSave = null;
    });
    _playerPreferenceSave = completion;
    return completion;
  }

  Future<void> _drainPlayerPreferences() async {
    final failed = <String, int>{};
    while (true) {
      final id = _pendingPlayerPreferences.keys
          .where((id) => _pendingPlayerPreferences[id]!.revision != failed[id])
          .firstOrNull;
      if (id == null) return;
      final pending = _pendingPlayerPreferences[id]!;
      final saved = await _guard(() async {
        final writer = onSavePlayerPreferences;
        if (writer != null) {
          await writer(id, pending.transpose, pending.speed);
        } else {
          await app.savePlayerPreferences(
            id,
            transpose: pending.transpose,
            playbackSpeed: pending.speed,
          );
        }
      });
      if (!saved) {
        // Keep this song's values for a later attempt without starving other
        // songs or retrying a persistent error in a tight loop.
        failed[id] = pending.revision;
      } else if (_pendingPlayerPreferences[id]?.revision == pending.revision) {
        _pendingPlayerPreferences.remove(id);
      }
      // A newer revision stays queued and is written after the current save.
    }
  }

  @visibleForTesting
  Future<void> settlePlayerPreferences() {
    _playerPreferenceDebounce?.cancel();
    _playerPreferenceDebounce = null;
    return _savePlayerPreferences();
  }

  // -- Editing -------------------------------------------------------------

  @override
  Future<void> saveLyricsEdit(String chordProText) async {
    final old = currentSong;
    if (old == null) return;
    final editorSessionRevision = _editorSessionRevision;
    final editorBaseHash = _editorBaseHash;
    final parsed = _codec.decode(chordProText);
    // A new song always needs a real title, even when its body contains the
    // editor's example template or this method is called outside the form.
    if (old.id == _draftSong?.id && parsed.title.trim().isEmpty) {
      return;
    }
    final metadata = {...old.metadata, ...parsed.metadata}
      ..removeWhere((key, value) => value == '');
    final edited = arrangement.editSong(
      old,
      body: parsed.body,
      title: parsed.title.isEmpty ? old.title : parsed.title,
      artist: parsed.artist,
      metadata: metadata,
    );
    var conflicted = false;
    if (!await _guard(() async {
      conflicted = !await app.saveSong(edited, baseHash: editorBaseHash);
    }, failure: UiNotice.editorSaveFailed)) {
      return;
    }
    if (_disposed ||
        _editorSessionRevision != editorSessionRevision ||
        _route != VerseRoute.editor ||
        _songId != old.id) {
      postNotice(
        conflicted ? UiNotice.editorSaveConflict : UiNotice.editorSaved,
      );
      return;
    }
    final wasDraft = old.id == _draftSong?.id;
    _draftSong = null;
    _editing = false;
    _editorData = null;
    _editorDirty = false;
    _leaveEditor(savedNewSong: wasDraft);
    notifyListeners();
    postNotice(conflicted ? UiNotice.editorSaveConflict : UiNotice.editorSaved);
  }

  String get editableChordPro {
    final song = currentSong;
    if (song == null) return '';
    const headers = <String, String>{
      'album': 'album',
      'key': 'key',
      'capo': 'capo',
      'tempo': 'tempo',
      'timeSignature': 'time',
      'durationSeconds': 'duration',
      'year': 'year',
      'tuning': 'tuning',
      'composer': 'composer',
      'lyricist': 'lyricist',
      'copyright': 'copyright',
    };
    String safe(Object? value) =>
        value?.toString().replaceAll(RegExp(r'[\r\n{}]'), ' ') ?? '';
    return [
      '{title: ${safe(song.title)}}',
      '{artist: ${safe(song.artist)}}',
      for (final entry in headers.entries)
        '{${entry.value}: ${safe(song.metadata[entry.key])}}',
      '',
      song.body,
    ].join('\n');
  }

  @override
  Future<void> deleteSong(String id) async {
    _beginNavigationIntent();
    if (_draftSong?.id == id) {
      _editorSessionRevision++;
      _draftSong = null;
      _songId = null;
      _editorData = null;
      _editorDirty = false;
      _editing = false;
      _route = VerseRoute.main;
      notifyListeners();
      return;
    }
    if (!await _guard(() => app.deleteSong(id))) return;
    _pendingPlayerPreferences.remove(id);
    if (_songId == id) {
      _editorSessionRevision++;
      _stopPlayer();
      _progress = 0;
      _songId = null;
      _setlistEntryId = null;
      _editorData = null;
      _editorBaseHash = null;
      _editorDirty = false;
      _editorReturnsToReader = false;
      _editing = false;
      _route = VerseRoute.main;
    }
    notifyListeners();
    postNotice(UiNotice.songDeleted);
  }

  @override
  Future<void> deleteSetlist(String id) async {
    _beginNavigationIntent();
    if (_draftSetlist?.id == id) {
      _draftSetlist = null;
      _draftSetlistInitialName = null;
    } else if (!await _guard(() => app.deleteSetlist(id))) {
      return;
    }
    if (_setlistId == id) {
      _setlistEditSessionRevision++;
      _setlistId = null;
      _setlistEntryId = null;
      _setlistBaseHash = null;
      _editingSetlist = false;
      _route = VerseRoute.main;
    }
    notifyListeners();
    postNotice(UiNotice.setlistDeleted);
  }

  /// Saves the open setlist. The editing mode is left alone unless
  /// [finishEditing] is set, so reordering or removing while editing keeps the
  /// name and notes fields on screen.
  @override
  Future<void> saveSetlistDetails({
    required String name,
    required String notes,
    List<String>? entryOrder,
    bool finishEditing = false,
  }) async {
    final current = currentSetlist;
    if (current == null) return;
    final editSessionRevision = _setlistEditSessionRevision;
    final orderedEntries = entryOrder == null
        ? current.entries
        : _orderEntries(current.entries, entryOrder);
    final saved = await _saveSetlistDocument(
      SetlistDocument(
        id: current.id,
        name: name.trim().isEmpty ? current.name : name.trim(),
        notes: notes,
        favorite: current.favorite,
        createdAt: current.createdAt,
        entries: orderedEntries,
      ),
    );
    if (saved &&
        finishEditing &&
        _route == VerseRoute.setlistDetail &&
        _setlistId == current.id &&
        _setlistEditSessionRevision == editSessionRevision) {
      _editingSetlist = false;
      _setlistEditSessionRevision++;
      notifyListeners();
    }
  }

  List<SetlistEntry> _orderEntries(
    List<SetlistEntry> existing,
    List<String> order,
  ) {
    final byId = {for (final entry in existing) entry.id: entry};
    return [
      for (final id in order)
        if (byId[id] != null) byId[id]!,
    ];
  }

  @override
  Future<void> removeSetlistEntry(
    String setlistId,
    String entryId, {
    String? name,
    String? notes,
  }) async {
    await _removeSetlistEntry(setlistId, entryId, name: name, notes: notes);
  }

  @override
  Future<SetlistEntryRemovalData?> removeSetlistEntryWithUndo(
    String setlistId,
    String entryId, {
    String? name,
    String? notes,
  }) async {
    final current = _setlistById(setlistId);
    if (current == null) return null;
    final index = current.entries.indexWhere((entry) => entry.id == entryId);
    if (index < 0) return null;
    final removed = current.entries[index];
    final saved = await _saveSetlistWith(
      current,
      entries: [...current.entries]..removeAt(index),
      name: name,
      notes: notes,
    );
    if (!saved) return null;
    return SetlistEntryRemovalData(
      setlistId: setlistId,
      entryId: removed.id,
      songId: removed.songId,
      overrides: Map<String, Object?>.unmodifiable(removed.overrides),
      index: index,
    );
  }

  Future<bool> _removeSetlistEntry(
    String setlistId,
    String entryId, {
    String? name,
    String? notes,
  }) async {
    final current = _setlistById(setlistId);
    if (current == null) return false;
    final entries = current.entries
        .where((entry) => entry.id != entryId)
        .toList();
    if (entries.length == current.entries.length) return false;
    return _saveSetlistWith(
      current,
      entries: entries,
      name: name,
      notes: notes,
    );
  }

  @override
  Future<void> restoreSetlistEntry(SetlistEntryRemovalData removed) async {
    final current = _setlistById(removed.setlistId);
    if (current == null ||
        current.entries.any((entry) => entry.id == removed.entryId)) {
      return;
    }
    final entries = [...current.entries];
    final index = removed.index.clamp(0, entries.length).toInt();
    entries.insert(
      index,
      SetlistEntry(
        id: removed.entryId,
        songId: removed.songId,
        overrides: Map<String, Object?>.from(removed.overrides),
      ),
    );
    await _saveSetlistWith(current, entries: entries);
  }

  Future<bool> _saveSetlistWith(
    SetlistDocument current, {
    required List<SetlistEntry> entries,
    String? name,
    String? notes,
  }) => _saveSetlistDocument(
    SetlistDocument(
      id: current.id,
      name: name == null || name.trim().isEmpty ? current.name : name.trim(),
      notes: notes ?? current.notes,
      favorite: current.favorite,
      createdAt: current.createdAt,
      entries: entries,
    ),
  );

  /// Saves [setlist]; while it is being edited the save is checked against the
  /// hash captured when editing began. A stale save is kept as a conflict copy
  /// and announced, but is not reported as an in-place change to its caller.
  Future<bool> _saveSetlistDocument(SetlistDocument setlist) async {
    final isDraft = _draftSetlist?.id == setlist.id;
    if (isDraft &&
        setlist.entries.isEmpty &&
        setlist.name.trim() == _draftSetlistInitialName &&
        setlist.notes.trim().isEmpty &&
        !setlist.favorite) {
      // Save on an untouched placeholder may leave edit mode, but must not
      // create an empty item (or schedule any cloud write).
      _draftSetlist = setlist;
      return true;
    }
    final editing = _editingSetlist && _setlistId == setlist.id;
    final editSessionRevision = _setlistEditSessionRevision;
    final editBaseHash = editing ? _setlistBaseHash : null;
    SetlistWriteHashes? writeHashes;
    var inPlace = true;
    final ok = await _guard(() async {
      writeHashes = await app.saveSetlistWithHashes(
        setlist,
        baseHash: editBaseHash,
      );
      inPlace = writeHashes != null;
    });
    if (ok && inPlace && editing) {
      _adoptSetlistWriteHash(
        setlist.id,
        writeHashes,
        editSessionRevision: editSessionRevision,
        editBaseHash: editBaseHash,
      );
    }
    if (ok && !inPlace) postNotice(UiNotice.setlistSaveConflict);
    if (ok && inPlace && isDraft && _draftSetlist?.id == setlist.id) {
      _draftSetlist = null;
      _draftSetlistInitialName = null;
    }
    return ok && inPlace;
  }

  @override
  Future<void> saveSetlistEntryOverrides(
    String setlistId,
    String entryId, {
    String? key,
    String? capo,
    String? name,
    String? notes,
  }) async {
    final current = _setlistById(setlistId);
    if (current == null) return;
    final trimmedKey = key?.trim() ?? '';
    final trimmedCapo = capo?.trim() ?? '';
    await _saveSetlistWith(
      current,
      name: name,
      notes: notes,
      entries: current.entries.map((entry) {
        if (entry.id != entryId) return entry;
        final overrides = {...entry.overrides}
          ..remove('key')
          ..remove('capo');
        if (trimmedKey.isNotEmpty) overrides['key'] = trimmedKey;
        if (trimmedCapo.isNotEmpty) {
          overrides['capo'] = num.tryParse(trimmedCapo) ?? trimmedCapo;
        }
        return SetlistEntry(
          id: entry.id,
          songId: entry.songId,
          overrides: overrides,
        );
      }).toList(),
    );
  }

  bool get editingSetlist => _editingSetlist;

  @override
  Future<void> addSongToSetlist(String songId, String setlistId) async {
    final draft = _draftSetlist;
    if (draft != null && draft.id == setlistId) {
      if (app.findSong(songId) == null) return;
      await _saveSetlistWith(
        draft,
        entries: [
          ...draft.entries,
          SetlistEntry(id: newId(), songId: songId),
        ],
      );
      return;
    }
    final editing = _editingSetlist && _setlistId == setlistId;
    final editSessionRevision = _setlistEditSessionRevision;
    final editBaseHash = editing ? _setlistBaseHash : null;
    SetlistWriteHashes? writeHashes;
    final saved = await _guard(() async {
      writeHashes = await app.addToSetlistWithHashes(songId, setlistId);
    });
    if (saved && editing) {
      _adoptSetlistWriteHash(
        setlistId,
        writeHashes,
        editSessionRevision: editSessionRevision,
        editBaseHash: editBaseHash,
      );
    }
    // The setlist was deleted meanwhile, or kept changing underneath the
    // write: nothing was added, and the person must be told.
    if (saved && writeHashes == null) postNotice(UiNotice.genericError);
  }

  /// Moves the open edit session's baseline to [hashes] after its own write.
  /// Adopt only the exact hash returned by that write, and only while the CAS
  /// began from the baseline and the session remains the one that initiated
  /// it.
  void _adoptSetlistWriteHash(
    String setlistId,
    SetlistWriteHashes? hashes, {
    required int editSessionRevision,
    required String? editBaseHash,
  }) {
    if (hashes != null &&
        _editingSetlist &&
        _setlistId == setlistId &&
        _route == VerseRoute.setlistDetail &&
        _setlistEditSessionRevision == editSessionRevision &&
        _setlistBaseHash == editBaseHash &&
        hashes.expectedHash == editBaseHash &&
        app.setlistHash(setlistId) == hashes.persistedHash) {
      _setlistBaseHash = hashes.persistedHash;
    }
  }

  @override
  SongInfoData? songInfo(String id) {
    final song = app.findSong(id);
    if (song == null) return null;
    const names = [
      'album',
      'capo',
      'tuning',
      'tempo',
      'timeSignature',
      'durationSeconds',
      'language',
      'year',
      'composer',
      'lyricist',
      'copyright',
      'license',
    ];
    return SongInfoData(
      title: song.title,
      artist: song.artist,
      fields: {
        'key': id == _songId ? displayedKey : song.metadata['key'],
        for (final name in names) name: song.metadata[name],
      },
      sources: [
        for (final source in song.sources)
          SongInfoSourceData(
            providerName: _providerName(source.candidate.providerId),
            attribution: source.attribution ?? '',
            matchReason: source.matchReason,
            url: source.candidate.url,
          ),
      ],
    );
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) =>
      _setSetting('themeMode', mode.name);
  @override
  Future<void> setLanguage(String? languageCode) =>
      _setSetting('locale', languageCode);
  @override
  Future<void> setPalette(String palette) => _setSetting('palette', palette);
  @override
  Future<void> setFontFamily(String fontFamily) =>
      _setSetting('fontFamily', fontFamily);
  @override
  Future<void> setLyricsFontSize(double size) =>
      _setSetting('readerFontSize', size);
  @override
  Future<void> setLyricHighlightStyle(String style) =>
      _setSetting('lyricHighlightStyle', style);
  @override
  Future<void> setShowChords(bool show) => _setSetting('showChords', show);

  @override
  Future<void> setShowSections(bool show) => _setSetting('showSections', show);

  @override
  Future<void> setPlayerControlsExpanded(bool expanded) =>
      _setSetting('playerControlsExpanded', expanded);

  @override
  Future<void> setAutoscroll(bool enabled) =>
      _setSetting('autoscroll', enabled);
  @override
  Future<void> setTimingMode(String mode) => _setSetting('timingMode', mode);
  @override
  Future<void> setProviderEnabled(String id, bool enabled) =>
      _guardSetting(() => app.setProviderEnabled(id, enabled));

  @override
  Future<bool> refreshSources() => app.refreshSources();

  // ---- Sync engine state used by the account UI --------------------------
  DateTime? get _lastSyncAt => app.lastSyncAt;
  int get _lastSyncConflicts => app.lastSyncConflicts;
  String? get _lastSyncErrorCode => app.lastSyncErrorCode;

  /// The sync completed and only skipped unusable files: the code is a notice,
  /// not a failure.
  bool get _syncWarningOnly =>
      app.syncWarning != null && app.syncError == app.syncWarning;

  /// The person dismissed a system or Google dialog; nothing went wrong, so it
  /// is neither an error banner nor a failed-sync notice.
  bool get _syncCancelled => app.syncError == 'cancelled';
  bool get _autoSyncEnabled => app.autoSyncEnabled;

  @override
  Future<void> setAutoSync(bool enabled) => app.setAutoSync(enabled);

  @override
  void onAppResumed() => app.onAppResumed();

  @override
  Future<void> adoptAccount({required bool mergeLocal}) =>
      app.adoptAccount(mergeLocal: mergeLocal);

  @override
  Future<void> confirmRemoteDeletions() async {
    final conflictsBefore = _lastSyncConflicts;
    await app.confirmRemoteDeletions();
    _postSyncOutcome(conflictsBefore);
  }

  @override
  Future<void> keepLocalAfterRemoteDeletions() async {
    final conflictsBefore = _lastSyncConflicts;
    await app.keepLocalAfterRemoteDeletions();
    _postSyncOutcome(conflictsBefore);
  }

  @override
  void reviewSyncConflicts() {
    _conflictFilter = true;
    setTab(VerseTab.songs);
  }

  @override
  void clearConflictFilter() {
    _conflictFilter = false;
    notifyListeners();
  }

  @override
  Future<void> signInForSync() async {
    if (app.syncConfigured) {
      await app.connectSync();
    } else if (onSignIn != null) {
      await onSignIn!();
    }
    if (app.syncConnected && app.syncError == null) {
      postNotice(UiNotice.signedIn);
    }
  }

  @override
  Future<void> signOutFromSync() async {
    final wasConnected = app.syncConnected;
    if (wasConnected) {
      await app.disconnectSync();
    } else if (onSignOut != null) {
      await onSignOut!();
    }
    if (wasConnected && !app.syncConnected) postNotice(UiNotice.signedOut);
  }

  @override
  Future<void> selectSyncProvider(SyncProvider provider) =>
      app.selectSyncProvider(provider);

  @override
  Future<void> syncNow() async {
    if (!app.syncConnected) return;
    final conflictsBefore = _lastSyncConflicts;
    await app.syncNow();
    _postSyncOutcome(conflictsBefore);
  }

  @override
  Future<void> chooseSyncDriveFolder() async {
    if (!app.syncConnected) return;
    await _runDriveAction(app.chooseSyncDriveFolder);
  }

  @override
  Future<void> importChordProFromDrive() async {
    if (!app.syncConnected || app.syncDriveFolderName == null) return;
    await _runDriveAction(app.importChordProFromDrive);
  }

  Future<void> _runDriveAction(Future<void> Function() action) async {
    try {
      await action();
      if (_syncCancelled) return;
      if (app.syncError != null) {
        postNotice(UiNotice.syncFailed);
      } else {
        postNotice(UiNotice.syncSucceeded);
      }
    } catch (_) {
      postNotice(UiNotice.syncFailed);
    }
  }

  void _postSyncOutcome(int conflictsBefore) {
    if (_syncWarningOnly) {
      postNotice(UiNotice.syncSkipped);
    } else if (_syncCancelled) {
      return;
    } else if (app.syncError != null) {
      // A refused deletion waits for the person's decision (the dialog); it is
      // not announced as a failed sync as well.
      if (app.syncError != 'remote_listing_suspicious') {
        postNotice(UiNotice.syncFailed);
      }
    } else {
      postNotice(
        _lastSyncConflicts > conflictsBefore
            ? UiNotice.syncConflictsFound
            : UiNotice.syncSucceeded,
      );
    }
  }

  @override
  Future<void> importChordPro() => _runImport(onImport);

  @override
  Future<void> importSetlist() => _runImport(onImportSetlist);

  Future<void> _runImport(Future<void> Function()? import) async {
    if (import == null) return;
    try {
      await import();
    } on FormatException catch (error) {
      postNotice(_failureNotice(error, UiNotice.importFailed));
    } catch (_) {
      postNotice(UiNotice.importFailed);
    }
  }

  void _leaveEditor({bool savedNewSong = false}) {
    if (_editorReturnsToReader || savedNewSong) {
      _route = VerseRoute.reader;
    } else {
      _songId = null;
      _route = VerseRoute.main;
    }
  }

  @override
  Future<void> back() async {
    _beginNavigationIntent();
    _stopPlayer();
    if (_route == VerseRoute.editor) {
      _editorSessionRevision++;
      _editing = false;
      _editorData = null;
      _editorDirty = false;
      if (_draftSong != null) {
        _draftSong = null;
        _songId = null;
        _route = VerseRoute.main;
      } else {
        _leaveEditor();
      }
    } else if (_route == VerseRoute.reader) {
      if (_setlistId != null) {
        _setlistEntryId = null;
        _route = VerseRoute.setlistDetail;
      } else {
        _songId = null;
        _route = VerseRoute.main;
      }
    } else if (_route == VerseRoute.setlistDetail) {
      _setlistEditSessionRevision++;
      _draftSetlist = null;
      _draftSetlistInitialName = null;
      _setlistId = null;
      _setlistBaseHash = null;
      _editingSetlist = false;
      _route = VerseRoute.main;
    } else if (_route != VerseRoute.main) {
      _route = VerseRoute.main;
    }
    if (_route == VerseRoute.main && _tab == VerseTab.home) {
      _rememberSongsView();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _beginNavigationIntent();
    _searchDebounce?.cancel();
    _playerTimer?.cancel();
    _playerPreferenceDebounce?.cancel();
    unawaited(_savePlayerPreferences());
    app.removeListener(_onAppChanged);
    _notices.close();
    _position.dispose();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Metadata comes from imported files and synced documents, so values may have
/// an unexpected type. These read them without throwing.
double? _metaDouble(Object? value) {
  final number = switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value.trim()),
    _ => null,
  };
  return number != null && number.isFinite ? number : null;
}

int? _metaInt(Object? value) => switch (value) {
  int() => value,
  num() when value.isFinite => value.toInt(),
  String() => int.tryParse(value.trim()),
  _ => null,
};

String? _metaString(Object? value) => switch (value) {
  String() => value,
  num() || bool() => value.toString(),
  _ => null,
};

Map<String, Object?> _diagnosticMetadata(
  Map<String, Object?> values, {
  String? providerId,
}) {
  const aliases = <String, List<String>>{
    'timeSignature': ['timeSignature', 'time_signature', 'time'],
    'tuning': ['tuning', 'tuningStrings', 'tuning_strings'],
  };
  const allowed = {
    'key',
    'capo',
    'tuning',
    'tempo',
    'timeSignature',
    'year',
    'album',
    'language',
    'composer',
    'composers',
    'lyricist',
    'lyricists',
    'author',
    'writers',
    'genre',
    'credits',
    'mediaLinks',
  };
  final output = <String, Object?>{};
  final analysis = AcousticBrainzAnalysis.fromMetadata(
    providerId ?? '',
    values,
  );
  if (analysis != null) output['acousticbrainz'] = analysis.toMetadata();
  for (final key in allowed) {
    Object? value = values[key];
    if (value == null) {
      for (final alias in aliases[key] ?? const <String>[]) {
        if (values.containsKey(alias)) {
          value = values[alias];
          break;
        }
      }
    }
    if (key == 'mediaLinks' && value is List) {
      final links = <String>[];
      for (final entry in value.take(30)) {
        final rawUrl = entry is String
            ? entry
            : entry is Map
            ? _metaString(entry['url'])
            : null;
        final url = safeDiagnosticUrl(rawUrl);
        if (url == null) continue;
        final rawTitle = entry is Map ? _metaString(entry['title']) : null;
        final title = rawTitle?.trim().replaceAll(RegExp(r'\s+'), ' ');
        final label = title == null || title.isEmpty || title == rawUrl
            ? url
            : '${title.length > 256 ? title.substring(0, 256) : title}\n$url';
        if (!links.contains(label)) links.add(label);
      }
      if (links.isNotEmpty) output[key] = List<String>.unmodifiable(links);
    } else if (value is List) {
      final entries = value
          .map((item) => _diagnosticCredit(item))
          .whereType<String>()
          .toList(growable: false);
      if (entries.isNotEmpty) output[key] = List<String>.unmodifiable(entries);
    } else if (_metaString(value) case final text?
        when text.trim().isNotEmpty) {
      output[key] = text.trim();
    }
  }
  return Map<String, Object?>.unmodifiable(output);
}

String? _diagnosticCredit(Object? value) {
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  if (value is! Map) return null;
  final name = _metaString(value['name'] ?? value['artist'] ?? value['value']);
  final role = _metaString(value['role'] ?? value['type']);
  final parts = [
    if (name?.trim().isNotEmpty == true) name!.trim(),
    if (role?.trim().isNotEmpty == true) role!.trim(),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
