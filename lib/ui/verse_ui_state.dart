import 'package:flutter/foundation.dart';

enum VerseTab { home, songs, setlists, settings }

enum VerseRoute { main, reader, editor, setlistDetail }

enum HomeListMode { recent, favorites, online }

enum LoadState { idle, loading, loaded, failed }

enum AppThemeMode { system, light, dark }

/// Short-lived outcomes the shell reports to the person using the app.
///
/// The adapter posts these after file, share, save and delete actions so the
/// shell can show one localized snackbar per outcome. They carry no text.
enum UiNotice {
  songSaved,
  songSaveFailed,
  songDeleted,
  setlistDeleted,
  copied,
  historyCleared,
  importSuccess,
  importFailed,
  importUnsupported,
  importTooLarge,
  exportFailed,
  exportPdfTooLarge,
  timingTooLarge,
  importDuplicateSongId,
  editorSaved,
  editorSaveFailed,
  editorSaveConflict,
  setlistSaveConflict,
  syncSucceeded,
  syncFailed,
  syncConflictsFound,
  syncSkipped,
  signedIn,
  signedOut,
  genericError,
}

/// Playback position, published separately from [VerseUiState] so one-second
/// ticks and scrubbing do not rebuild the whole application.
@immutable
class PlayerPosition {
  const PlayerPosition(this.seconds, this.currentLineId);
  static const zero = PlayerPosition(0, null);
  final double seconds;
  final String? currentLineId;

  @override
  bool operator ==(Object other) =>
      other is PlayerPosition &&
      other.seconds == seconds &&
      other.currentLineId == currentLineId;

  @override
  int get hashCode => Object.hash(seconds, currentLineId);
}

@immutable
class LyricChord {
  const LyricChord({required this.graphemeOffset, required this.symbol});
  final int graphemeOffset;
  final String symbol;
}

@immutable
class LyricLineData {
  const LyricLineData({
    required this.id,
    this.text = '',
    this.section,
    this.chords = const [],
    this.isBlank = false,
    this.isArrangementNote = false,
  });
  final String id;
  final String text;
  final String? section;
  final List<LyricChord> chords;
  final bool isBlank;
  final bool isArrangementNote;
}

@immutable
class PlayerSectionMarker {
  const PlayerSectionMarker({
    required this.name,
    required this.startSeconds,
    required this.lineId,
  });

  final String name;
  final double startSeconds;
  final String lineId;
}

@immutable
class SongCardData {
  const SongCardData({
    required this.id,
    required this.title,
    this.artist = '',
    this.album,
    this.artworkUrl,
    this.durationSeconds,
    this.key,
    this.favorite = false,
    this.playCount = 0,
    this.hasChords = false,
    this.modifiedAt,
    this.authored = false,
    this.isConflictCopy = false,
  });
  final String id, title;
  final String artist;
  final String? album, artworkUrl, key;
  final double? durationSeconds;
  final bool favorite, authored, hasChords;

  /// A copy kept by sync (or a stale save) because two edits collided.
  final bool isConflictCopy;
  final int playCount;
  final DateTime? modifiedAt;
}

@immutable
class RecentItemData {
  const RecentItemData({
    required this.id,
    required this.title,
    required this.occurredAt,
    required this.isSetlist,
    this.artist = '',
    this.subtitle = '',
    this.artworkUrl,
    this.favorite = false,
    this.playCount = 1,
  });
  final String id, title;
  final DateTime occurredAt;
  final bool isSetlist, favorite;
  final String artist, subtitle;
  final String? artworkUrl;
  final int playCount;
}

@immutable
class SetlistEntryData {
  const SetlistEntryData({
    required this.id,
    required this.songId,
    this.title = '',
    this.artist = '',
    this.keyOverride,
    this.capoOverride,
    this.missing = false,
  });
  final String id, songId, title, artist;
  final String? keyOverride, capoOverride;

  /// The referenced song is no longer in the library. [title] is empty and the
  /// UI supplies a localized placeholder so the entry can still be removed.
  final bool missing;
}

/// Complete data needed to put a removed entry back in its original position.
/// Overrides are kept opaque to the UI so keys, capo, repeats, and future
/// entry metadata survive an Undo action unchanged.
@immutable
class SetlistEntryRemovalData {
  const SetlistEntryRemovalData({
    required this.setlistId,
    required this.entryId,
    required this.songId,
    required this.overrides,
    required this.index,
  });

  final String setlistId, entryId, songId;
  final Map<String, Object?> overrides;
  final int index;
}

@immutable
class SetlistCardData {
  const SetlistCardData({
    required this.id,
    required this.title,
    this.notes = '',
    this.songTitles = const [],
    this.songIds = const [],
    this.entries = const [],
    this.favorite = false,
    this.modifiedAt,
    this.durationSeconds = 0,
    this.durationEstimated = false,
    this.durationPartial = false,
  });
  final String id, title, notes;

  /// Song titles in order; an empty string marks a song missing from the
  /// library (the UI shows a localized placeholder).
  final List<String> songTitles, songIds;
  final List<SetlistEntryData> entries;
  final bool favorite;
  final DateTime? modifiedAt;

  /// Sum of the entry durations, including player estimates when needed.
  /// Missing library references are omitted and marked by [durationPartial].
  final double durationSeconds;
  final bool durationEstimated, durationPartial;
}

/// Editable fields of the song being edited, captured when the editor opens.
@immutable
class SongEditorData {
  const SongEditorData({
    required this.songId,
    required this.isNew,
    this.title = '',
    this.artist = '',
    this.album = '',
    this.key = '',
    this.capo = '',
    this.tuning = '',
    this.tempo = '',
    this.duration = '',
    this.body = '',
  });
  final String songId;
  final bool isNew;
  final String title, artist, album, key, capo, tuning, tempo, duration, body;
}

@immutable
class SongInfoSourceData {
  const SongInfoSourceData({
    required this.providerName,
    this.attribution = '',
    this.matchReason,
    this.url,
  });
  final String providerName, attribution;
  final String? matchReason, url;
}

/// Read-only song details for the information sheet.
@immutable
class SongInfoData {
  const SongInfoData({
    required this.title,
    required this.artist,
    this.fields = const {},
    this.sources = const [],
  });
  final String title, artist;

  /// Raw metadata keyed by `SongDocument.metadata` names, with `key` already
  /// resolved for the active setlist entry.
  final Map<String, Object?> fields;
  final List<SongInfoSourceData> sources;
}

@immutable
class SearchReferenceData {
  const SearchReferenceData({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.durationSeconds,
    this.artworkUrl,
    this.matchReason,
  });
  final String id, title, artist;
  final String? album, artworkUrl, matchReason;
  final double? durationSeconds;
}

@immutable
class SourceVersionData {
  const SourceVersionData({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.title,
    required this.artist,
    this.album,
    this.durationSeconds,
    this.artworkUrl,
    this.rating,
    this.ratingCount,
    this.hasLyrics = false,
    this.hasChords = false,
    this.hasTiming = false,
    this.sameRecording = false,
    this.matchSummary = '',
    this.sourceCount,
    this.isUsableVersion = false,
    this.status = LoadState.loaded,
    this.bodyPreview = const [],
    this.bodyLines = const [],
    this.contributions = const [],
    this.isChecking = false,
    this.canSave = false,
    this.savedSongId,
    this.underlyingSourceId,
    this.sourceUrl,
    this.metadata = const <String, Object?>{},
  });
  final String id, providerId, providerName, title, artist;
  final String? album, artworkUrl;
  final double? durationSeconds, rating;
  final int? ratingCount;
  final bool hasLyrics, hasChords, hasTiming, sameRecording, canSave;
  final String matchSummary;
  final int? sourceCount;
  final bool isUsableVersion;
  final LoadState status;
  final List<LyricLineData> bodyPreview;

  /// Complete parsed arrangement for the full source preview.
  final List<LyricLineData> bodyLines;
  final List<SourceContributionData> contributions;

  /// True while final validation can still change this source's usability.
  final bool isChecking;
  final String? savedSongId;
  final String? underlyingSourceId;

  /// Sanitized public URL for the source, when available.
  final String? sourceUrl;

  /// Useful, display-safe metadata values from this version.
  final Map<String, Object?> metadata;
}

@immutable
class SourceContributionData {
  const SourceContributionData({
    required this.providerName,
    required this.roles,
    this.sourceUrl,
  });

  final String providerName;
  final List<String> roles;
  final String? sourceUrl;
}

@immutable
class SearchComparisonData {
  const SearchComparisonData({
    required this.reference,
    required this.suggested,
    this.alternatives = const [],
    this.selectedVersionId,
    this.error,
    this.discovering = false,
    this.discoveryError,
    this.noUsableLyrics = false,
    this.providerChecks = const [],
  });
  final SearchReferenceData reference;
  final SourceVersionData? suggested;
  final List<SourceVersionData> alternatives;
  final String? selectedVersionId, error, discoveryError;
  final bool discovering, noUsableLyrics;
  final List<SearchProviderCheckData> providerChecks;
  SourceVersionData? get selected {
    final id = selectedVersionId;
    if (id == null) return suggested;
    for (final item in [?suggested, ...alternatives]) {
      if (item.id == id) return item;
    }
    return null;
  }
}

@immutable
class SearchProviderCheckData {
  const SearchProviderCheckData({
    required this.id,
    required this.name,
    required this.state,
    this.code,
    this.operations = const [],
  });
  final String id, name, state;
  final String? code;
  final List<SearchProviderOperationData> operations;
}

/// A bounded, safe-to-display step in a provider's discovery/check flow.
@immutable
class SearchProviderOperationData {
  const SearchProviderOperationData({
    required this.id,
    required this.phase,
    required this.state,
    this.code,
    this.query,
    this.title,
    this.artist,
    this.sourceUrl,
    this.resultCount,
    this.elapsedMilliseconds,
  });

  final String id, phase, state;
  final String? code, query, title, artist, sourceUrl;
  final int? resultCount, elapsedMilliseconds;
}

@immutable
class ProviderSettingData {
  const ProviderSettingData({
    required this.id,
    required this.name,
    required this.enabled,
    this.description = '',
    this.lastChecked,
  });
  final String id, name, description;
  final bool enabled;
  final DateTime? lastChecked;
}

@immutable
class SearchFilterData {
  const SearchFilterData({
    this.field = 'all',
    this.language = '',
    this.chordsOnly = false,
    this.timedOnly = false,
    this.durationBucket = '',
  });
  final String field, language, durationBucket;
  final bool chordsOnly, timedOnly;
}

@immutable
class VerseUiState {
  const VerseUiState({
    this.route = VerseRoute.main,
    this.activeTab = VerseTab.home,
    this.homeListMode = HomeListMode.recent,
    this.query = '',
    this.autocomplete = const [],
    this.searchState = LoadState.idle,
    this.searchError,
    this.comparison,
    this.recent = const [],
    this.recentHasMore = false,
    this.loadingMoreRecent = false,
    this.songs = const [],
    this.setlists = const [],
    this.providers = const [],
    this.searchFiltersExpanded = false,
    this.searchFilters = const SearchFilterData(),
    this.syncReady = false,
    this.syncSignedIn = false,
    this.syncBusy = false,
    this.accountName,
    this.accountPhotoUrl,
    this.accountError,
    this.lastSyncAt,
    this.lastSyncConflicts = 0,
    this.lastSyncErrorCode,
    this.syncWarningCode,
    this.syncSuspiciousDeletionCount = 0,
    this.autoSyncEnabled = true,
    this.songsConflictFilter = false,
    this.darkTheme = AppThemeMode.system,
    this.palette = 'navy',
    this.fontFamily = 'system',
    this.lyricsFontSize = 24,
    this.lyricHighlightStyle = 'contrast',
    this.showChords = true,
    this.autoscroll = true,
    bool? autoscrollPreference,
    this.timingMode = 'estimated',
    this.readerHasTiming = false,
    this.readerTimingAvailable = false,
    this.readerDurationEstimated = false,
    this.readerSource,
    this.readerCanCompareVersions = false,
    this.playbackSpeed = 1,
    this.languageCode,
    this.song,
    this.songLines = const [],
    this.isPlaying = false,
    this.progressSeconds = 0,
    this.playerSections = const [],
    this.currentLineId,
    this.activeSetlist,
    this.editing = false,
    this.editingSetlist = false,
    this.editor,
    this.editorDirty = false,
    this.readerKey,
    this.readerTranspose = 0,
    this.readerCapo,
    this.readerTuning,
    this.readerTempo,
  }) : autoscrollPreference = autoscrollPreference ?? autoscroll;

  /// The same state with a new playback position; every other field, including
  /// the large lists, is shared with [o].
  VerseUiState.withPosition(
    VerseUiState o,
    this.progressSeconds,
    this.currentLineId,
  ) : route = o.route,
      activeTab = o.activeTab,
      homeListMode = o.homeListMode,
      query = o.query,
      autocomplete = o.autocomplete,
      searchState = o.searchState,
      searchError = o.searchError,
      comparison = o.comparison,
      recent = o.recent,
      recentHasMore = o.recentHasMore,
      loadingMoreRecent = o.loadingMoreRecent,
      songs = o.songs,
      setlists = o.setlists,
      providers = o.providers,
      searchFilters = o.searchFilters,
      searchFiltersExpanded = o.searchFiltersExpanded,
      syncReady = o.syncReady,
      syncSignedIn = o.syncSignedIn,
      syncBusy = o.syncBusy,
      accountName = o.accountName,
      accountPhotoUrl = o.accountPhotoUrl,
      accountError = o.accountError,
      lastSyncAt = o.lastSyncAt,
      lastSyncConflicts = o.lastSyncConflicts,
      lastSyncErrorCode = o.lastSyncErrorCode,
      syncWarningCode = o.syncWarningCode,
      syncSuspiciousDeletionCount = o.syncSuspiciousDeletionCount,
      autoSyncEnabled = o.autoSyncEnabled,
      songsConflictFilter = o.songsConflictFilter,
      darkTheme = o.darkTheme,
      palette = o.palette,
      fontFamily = o.fontFamily,
      lyricsFontSize = o.lyricsFontSize,
      lyricHighlightStyle = o.lyricHighlightStyle,
      showChords = o.showChords,
      autoscroll = o.autoscroll,
      autoscrollPreference = o.autoscrollPreference,
      timingMode = o.timingMode,
      readerHasTiming = o.readerHasTiming,
      readerTimingAvailable = o.readerTimingAvailable,
      readerDurationEstimated = o.readerDurationEstimated,
      readerSource = o.readerSource,
      readerCanCompareVersions = o.readerCanCompareVersions,
      playbackSpeed = o.playbackSpeed,
      languageCode = o.languageCode,
      song = o.song,
      songLines = o.songLines,
      isPlaying = o.isPlaying,
      playerSections = o.playerSections,
      activeSetlist = o.activeSetlist,
      editing = o.editing,
      editingSetlist = o.editingSetlist,
      editor = o.editor,
      editorDirty = o.editorDirty,
      readerKey = o.readerKey,
      readerTranspose = o.readerTranspose,
      readerCapo = o.readerCapo,
      readerTuning = o.readerTuning,
      readerTempo = o.readerTempo;

  final VerseRoute route;
  final VerseTab activeTab;
  final HomeListMode homeListMode;
  final String query;
  final List<SearchReferenceData> autocomplete;
  final LoadState searchState;
  final String? searchError;
  final SearchComparisonData? comparison;
  final List<RecentItemData> recent;
  final bool recentHasMore, loadingMoreRecent;
  final List<SongCardData> songs;
  final List<SetlistCardData> setlists;
  final List<ProviderSettingData> providers;
  final SearchFilterData searchFilters;
  final bool searchFiltersExpanded, syncReady, syncSignedIn, syncBusy;
  final String? accountName, accountPhotoUrl, accountError;

  /// When the last sync finished successfully, if ever.
  final DateTime? lastSyncAt;

  /// Conflicting edits the last sync kept as separate copies.
  final int lastSyncConflicts;

  /// Machine code of the last sync failure (`authorization_required`,
  /// `storage_full`, ...), or null. Falls back to [accountError].
  final String? lastSyncErrorCode;

  /// Code of an unusable file the last (otherwise successful) sync skipped.
  /// A neutral notice, not a failure; never also reported as an error.
  final String? syncWarningCode;

  /// While [syncErrorCode] is `remote_listing_suspicious`: how many items on
  /// this device the refused sync would have deleted.
  final int syncSuspiciousDeletionCount;
  final bool autoSyncEnabled;

  /// The Songs list shows only conflict copies.
  final bool songsConflictFilter;

  /// The error code to explain to the person, if the last sync failed.
  String? get syncErrorCode => lastSyncErrorCode ?? accountError;
  final AppThemeMode darkTheme;
  final String palette, fontFamily;
  final double lyricsFontSize;
  final String lyricHighlightStyle;
  final bool showChords, autoscroll;

  /// The stored "autoscroll by default" preference, which stays on while the
  /// effective [autoscroll] is off (manual timing).
  final bool autoscrollPreference;
  final String timingMode;
  final bool readerHasTiming, readerDurationEstimated;
  final bool readerTimingAvailable;
  final String? readerSource;
  final bool readerCanCompareVersions;
  final double playbackSpeed;
  final String? languageCode;
  final SongCardData? song;
  final List<LyricLineData> songLines;
  final bool isPlaying, editing, editingSetlist, editorDirty;
  final double progressSeconds;
  final List<PlayerSectionMarker> playerSections;
  final String? currentLineId;
  final SetlistCardData? activeSetlist;
  final SongEditorData? editor;

  /// Key (after any setlist override and transposition), capo, tuning and tempo
  /// of the open song, for the reader subtitle.
  final String? readerKey, readerCapo, readerTuning, readerTempo;

  /// Semitone adjustment from the saved arrangement, also available without
  /// key metadata. A chord root alone does not establish the song's key.
  final int readerTranspose;
}

/// UI boundary deliberately keeps widgets independent of SQLite and provider types.
abstract class VerseUiController extends ChangeNotifier {
  VerseUiState get state;

  /// Playback position; ticks here do not notify the controller's listeners.
  ValueListenable<PlayerPosition> get playerPosition => _fallbackPosition ??=
      ValueNotifier(PlayerPosition(state.progressSeconds, state.currentLineId));
  ValueNotifier<PlayerPosition>? _fallbackPosition;

  /// Outcomes to report to the person (see [UiNotice]).
  Stream<UiNotice> get notices => const Stream.empty();

  Future<void> initialize();
  void setTab(VerseTab tab);
  void setHomeListMode(HomeListMode mode);
  void setQuery(String value);
  void changeSearchSong() => setQuery('');
  Future<void> submitSearch();
  void toggleSearchFilters();
  void setSearchFilter(String key, Object? value);
  Future<void> loadMoreRecent();
  void clearHistory();
  Future<void> selectReference(SearchReferenceData reference);
  Future<void> retrySelectedSongDiscovery() async {}
  void selectVersion(String versionId);
  Future<void> saveSelectedVersion();
  Future<void> compareCurrentSongVersions() async {}
  Future<void> openSong(String id);
  Future<void> openSetlist(String id);
  Future<void> editSong(String id);
  Future<void> editSetlist(String id);
  Future<void> toggleSongFavorite(String id);
  Future<void> toggleSetlistFavorite(String id);
  Future<void> createSong();

  /// Creates a setlist named [name] (a localized default supplied by the UI)
  /// and optionally adds [songId] to it.
  Future<void> createSetlist({String? name, String? songId});
  Future<void> duplicateSetlist(String id, {String? copyName});
  Future<void> shareSong(String id);
  Future<void> shareSongPdf(String id);
  Future<void> copySongChordPro(String id);
  Future<void> printSong(String id);
  Future<void> shareSetlist(String id);
  Future<void> shareSetlistPdf(String id);
  Future<void> copySetlist(String id);
  Future<void> printSetlist(String id);
  Future<void> playPause();
  Future<void> setPlaybackSpeed(double speed) async {}
  Future<void> seek(double seconds);
  Future<void> nextSong();
  Future<void> previousSong();
  Future<void> transpose(int semitones);
  Future<void> saveLyricsEdit(String chordProText);
  Future<void> setThemeMode(AppThemeMode mode);
  Future<void> setLanguage(String? languageCode) async {}
  Future<void> setPalette(String palette);
  Future<void> setFontFamily(String fontFamily);
  Future<void> setLyricsFontSize(double size);
  Future<void> setLyricHighlightStyle(String style) async {}
  Future<void> setShowChords(bool show);
  Future<void> setAutoscroll(bool enabled);
  Future<void> setTimingMode(String mode);
  Future<void> setProviderEnabled(String id, bool enabled);
  Future<bool> refreshSources() async => false;
  Future<void> signInForSync();
  Future<void> signOutFromSync();

  /// Turns background sync on or off.
  Future<void> setAutoSync(bool enabled) async {}

  /// Resolves an `account_changed` sync stop: merge this device's library into
  /// the newly signed-in account, or replace local content with the account's.
  Future<void> adoptAccount({required bool mergeLocal}) async {}

  /// After `remote_listing_suspicious`: the cloud really lost those items, so
  /// delete them on this device too. Ask for a second confirmation first.
  Future<void> confirmRemoteDeletions() async {}

  /// After `remote_listing_suspicious`: keep this device's library and upload
  /// the missing items to the cloud again.
  Future<void> keepLocalAfterRemoteDeletions() async {}

  /// The app returned to the foreground; sync may refresh.
  void onAppResumed() {}

  /// Opens the Songs list filtered to conflict copies.
  void reviewSyncConflicts() {}

  /// Leaves the conflict-copy filter of the Songs list.
  void clearConflictFilter() {}
  Future<void> importChordPro();
  Future<void> importSetlist() async => importChordPro();
  Future<void> back();

  // Library editing used by the screens. Defaults keep lightweight test
  // doubles working; the adapter overrides all of them.
  Future<void> deleteSong(String id) async {}
  Future<void> deleteSetlist(String id) async {}
  Future<void> openSetlistEntry(String setlistId, String entryId) async {}
  Future<void> addSongToSetlist(String songId, String setlistId) async {}

  /// Saves the open setlist's [name] and [notes] (blank names keep the stored
  /// one); [entryOrder], when given, is the full ordered list of entry ids to
  /// keep. Edit mode is left as is unless [finishEditing] is set.
  Future<void> saveSetlistDetails({
    required String name,
    required String notes,
    List<String>? entryOrder,
    bool finishEditing = false,
  }) async {}

  /// [name] and [notes] carry text typed in an open editing form so it is saved
  /// with the change instead of being replaced by the stored values.
  Future<void> removeSetlistEntry(
    String setlistId,
    String entryId, {
    String? name,
    String? notes,
  }) async {}
  Future<SetlistEntryRemovalData?> removeSetlistEntryWithUndo(
    String setlistId,
    String entryId, {
    String? name,
    String? notes,
  }) async {
    await removeSetlistEntry(setlistId, entryId, name: name, notes: notes);
    return null;
  }

  Future<void> restoreSetlistEntry(SetlistEntryRemovalData removed) async {}
  Future<void> saveSetlistEntryOverrides(
    String setlistId,
    String entryId, {
    String? key,
    String? capo,
    String? name,
    String? notes,
  }) async {}
  Future<void> syncNow() async {}
  SongInfoData? songInfo(String id) => null;

  /// Records whether the open editor has unsaved changes.
  void setEditorDirty(bool dirty) {}
}
