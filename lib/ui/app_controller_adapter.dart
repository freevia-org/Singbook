import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/app_controller.dart';
import '../domain/arrangement.dart' as arrangement;
import '../domain/chordpro.dart';
import '../domain/models.dart';
import '../domain/timing.dart' show timingOccurrenceMap;
import '../domain/source_contributions.dart';
import 'format.dart';
import 'player_section_timeline.dart';
import 'verse_ui_state.dart';

double? _validDuration(Object? value) {
  if (value is! num) return null;
  final seconds = value.toDouble();
  return seconds.isFinite && seconds > 0 && seconds <= 86400 ? seconds : null;
}

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
    this.onSignIn,
    this.onSignOut,
  }) {
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
  final Future<void> Function()? onSignIn;
  final Future<void> Function()? onSignOut;

  VerseTab _tab = VerseTab.home;
  VerseRoute _route = VerseRoute.main;
  HomeListMode _homeMode = HomeListMode.recent;
  SearchFilterData _filters = const SearchFilterData();
  bool _filtersExpanded = false;
  String _query = '';
  String? _songId, _setlistId, _setlistEntryId, _selectedVersionId;
  String? _selectedQuery;
  List<SongCandidate> _cachedAutocomplete = const [];
  SongDocument? _draftSong;
  SongEditorData? _editorData;
  bool _editing = false, _playing = false, _editingSetlist = false;
  bool _editorDirty = false, _loadingMoreRecent = false, _disposed = false;
  bool _conflictFilter = false;
  String? _editorBaseHash;
  double _progress = 0, _transpose = 0, _playbackSpeed = 1;
  Timer? _searchDebounce, _playerTimer;
  final _codec = ChordProCodec();

  // Playback clock: progress is derived from a stopwatch so a delayed timer
  // tick catches up instead of drifting.
  final Stopwatch _playWatch = Stopwatch();
  double _playBase = 0;

  // State cache. [_revision] bumps on every notification; the base state is
  // rebuilt lazily when it is stale.
  int _revision = 0, _builtRevision = -1, _builds = 0;
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
    _revision++;
    _refreshPosition();
    super.notifyListeners();
  }

  void _onAppChanged() => notifyListeners();

  SongDocument? get currentSong => _songId == null
      ? null
      : app.findSong(_songId!) ??
            (_draftSong?.id == _songId ? _draftSong : null);
  String? get displayedKey {
    final key = currentSong?.metadata['key']?.toString();
    final override = activeSetlistEntry?.overrides['key']?.toString();
    final base = override?.isNotEmpty == true ? override : key;
    if (base == null || base.isEmpty) return null;
    return arrangement.transposeChord(base, _transpose.toInt());
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
    final originalKey = song.metadata['key']?.toString();
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

  static final _keyPattern = RegExp(r'^\s*([A-G])([#b♯♭]?)');
  static int? _keyPitch(String key) {
    final match = _keyPattern.firstMatch(key);
    if (match == null) return null;
    const pitches = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
    final pitch = pitches[match.group(1)];
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

  SetlistDocument? get currentSetlist => _setlistId == null
      ? null
      : app.setlists.where((item) => item.id == _setlistId).firstOrNull;

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
    return _base = _buildState();
  }

  /// Publishes the playback position for the current progress and song.
  void _refreshPosition() {
    final song = currentSong;
    if (song == null) {
      _position.value = PlayerPosition.zero;
      return;
    }
    _position.value = PlayerPosition(
      _progress,
      _currentLineId(_baseState().songLines, song),
    );
  }

  VerseUiState _buildState() {
    _builds++;
    final opens = <String, int>{};
    for (final event in app.recent) {
      if (event.objectKind == 'song') {
        opens[event.objectId] = (opens[event.objectId] ?? 0) + 1;
      }
    }
    _opens = opens;
    final song = currentSong;
    final setlist = currentSetlist;
    final timingMode = app.settings['timingMode'] as String? ?? 'estimated';
    final data = song == null
        ? const <LyricLineData>[]
        : _lines(
            arrangement.transposeBody(song.body, _effectiveTranspose(song)),
          );
    final playerDuration = song == null
        ? 0.0
        : _validDuration(song.metadata['durationSeconds']) ??
              _estimatedDuration(data.length);
    final playerSections = song == null
        ? const <PlayerSectionMarker>[]
        : buildPlayerSectionMarkers(
            lines: data,
            durationSeconds: playerDuration,
            timedLineStarts: _timedLineStarts(data, song, timingMode),
          );
    final recent = <RecentItemData>[];
    for (final event in app.recent) {
      if (event.objectKind == 'song') {
        final item = app.findSong(event.objectId);
        if (item != null) {
          recent.add(
            RecentItemData(
              id: item.id,
              title: item.title,
              artist: item.artist,
              subtitle: _subtitle(item),
              artworkUrl: item.metadata['artworkUrl'] as String?,
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
    final comparison = _comparison();
    final autocompleteCandidates = app.suggestions.isNotEmpty
        ? app.suggestions
        : _cachedAutocomplete;
    final rankedAutocomplete =
        autocompleteCandidates
            .asMap()
            .entries
            .where((entry) => _matchesFilters(entry.value))
            .toList()
          ..sort((a, b) {
            final relevance = _candidateRelevance(
              b.value,
              _query,
            ).compareTo(_candidateRelevance(a.value, _query));
            return relevance != 0 ? relevance : a.key.compareTo(b.key);
          });
    final tuning = song?.metadata['tuning'];
    final tempo = song?.metadata['tempo'];
    final selectedSourceId = song?.extra['selectedSourceId'];
    final selectedSource = song?.sources
        .where((source) => source.id == selectedSourceId)
        .firstOrNull;
    final sourceProviderId = selectedSource?.candidate.providerId;
    final readerSource = sourceProviderId == null
        ? null
        : app.providers
                  .where((provider) => provider.id == sourceProviderId)
                  .firstOrNull
                  ?.name ??
              sourceProviderId;
    final readerHasTiming =
        timingMode == 'timed' &&
        song != null &&
        _timedLineStarts(data, song, timingMode).isNotEmpty;
    final readerCanCompareVersions =
        song != null &&
        comparison != null &&
        _songMatchesSearchReference(song, comparison.reference.id);
    return VerseUiState(
      route: _route,
      activeTab: _tab,
      homeListMode: _homeMode,
      query: _query,
      autocomplete: _query.trim() == app.query.trim()
          ? rankedAutocomplete.map((entry) => _reference(entry.value)).toList()
          : const [],
      searchState: comparison != null
          ? LoadState.loaded
          : _query.trim().length >= 2 && _query != app.query
          ? LoadState.loading
          : app.searching
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
      songs: app.songs.map(_songCard).toList()..sort(_alphabeticalSong),
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
      searchFiltersExpanded: _filtersExpanded,
      searchFilters: _filters,
      syncReady: app.syncConfigured,
      syncSignedIn: app.syncConnected,
      syncBusy: app.syncBusy,
      accountName: app.syncAccountEmail,
      accountError: app.syncError,
      lastSyncAt: _lastSyncAt,
      lastSyncConflicts: _lastSyncConflicts,
      lastSyncErrorCode: _lastSyncErrorCode,
      autoSyncEnabled: _autoSyncEnabled,
      songsConflictFilter: _conflictFilter,
      darkTheme: _themeMode(app.settings['themeMode']),
      palette: app.settings['palette'] as String? ?? 'navy',
      fontFamily: app.settings['fontFamily'] as String? ?? 'system',
      lyricsFontSize:
          (app.settings['readerFontSize'] as num?)?.toDouble() ?? 24,
      showChords: app.settings['showChords'] as bool? ?? true,
      autoscroll:
          (app.settings['autoscroll'] as bool? ?? true) &&
          timingMode != 'manual',
      timingMode: timingMode,
      languageCode: app.settings['locale'] as String?,
      song: song == null ? null : _songCard(song),
      songLines: data,
      isPlaying: _playing,
      playbackSpeed: _playbackSpeed,
      playerSections: playerSections,
      activeSetlist: setlist == null ? null : _setlistCard(setlist),
      editing: _editing,
      editingSetlist: _editingSetlist,
      editor: _editorData,
      editorDirty: _editorDirty,
      readerKey: displayedKey,
      readerCapo: displayedCapo?.toString(),
      readerTuning: tuning?.toString(),
      readerTempo: tempo?.toString(),
      readerHasTiming: readerHasTiming,
      readerDurationEstimated:
          song != null &&
          _validDuration(song.metadata['durationSeconds']) == null,
      readerSource: readerSource,
      readerCanCompareVersions: readerCanCompareVersions,
    );
  }

  static int _alphabeticalSong(SongCardData a, SongCardData b) =>
      a.title.toLowerCase().compareTo(b.title.toLowerCase());

  bool _isUsableLyricResult(SourceResult result) {
    final incompleteSourceIds =
        app.combined?.extra['excludedIncompleteSourceIds'];
    return result.matchKind != MatchKind.rejected &&
        arrangement.plainLyrics(result.body).trim().isNotEmpty &&
        (incompleteSourceIds is! List ||
            !incompleteSourceIds.contains(result.id));
  }

  bool _hasUsableTiming(Iterable<TimingTrack> tracks) => tracks.any(
    (track) => track.status == TimingStatus.usable && track.cues.isNotEmpty,
  );

  SongCardData _songCard(SongDocument song) => SongCardData(
    id: song.id,
    title: song.title,
    artist: song.artist,
    album: song.metadata['album'] as String?,
    artworkUrl: song.metadata['artworkUrl'] as String?,
    durationSeconds: _validDuration(song.metadata['durationSeconds']),
    key: song.metadata['key'] as String?,
    favorite: song.favorite,
    modifiedAt: song.updatedAt,
    authored: song.sources.isEmpty,
    playCount: _opens[song.id] ?? 0,
    hasChords: song.hasChords,
    isConflictCopy:
        song.id.startsWith('conflict-') || song.extra['syncConflict'] != null,
  );

  SetlistCardData _setlistCard(SetlistDocument value) {
    final entries = [for (final entry in value.entries) _entryData(entry)];
    return SetlistCardData(
      id: value.id,
      title: value.name,
      notes: value.notes,
      songIds: [for (final entry in entries) entry.songId],
      songTitles: [for (final entry in entries) entry.title],
      entries: entries,
      favorite: value.favorite,
      modifiedAt: value.updatedAt,
    );
  }

  SetlistEntryData _entryData(SetlistEntry entry) {
    final song = app.findSong(entry.songId);
    final key = entry.overrides['key']?.toString();
    final capo = entry.overrides['capo']?.toString();
    return SetlistEntryData(
      id: entry.id,
      songId: entry.songId,
      title: song?.title ?? '',
      artist: song?.artist ?? '',
      keyOverride: key == null || key.isEmpty ? null : key,
      capoOverride: capo == null || capo.isEmpty ? null : capo,
      missing: song == null,
    );
  }

  SearchReferenceData _reference(SongCandidate value) => SearchReferenceData(
    id: value.identity,
    title: value.title,
    artist: value.artist,
    album: value.album,
    durationSeconds:
        _validDuration(value.durationSeconds) ??
        _validDuration(value.metadata['durationSeconds']),
    artworkUrl: value.artworkUrl,
  );

  bool _matchesFilters(SongCandidate candidate) {
    if (_isEditorialCandidate(candidate)) return false;
    if (_filters.field == 'title' && !_contains(candidate.title, _query)) {
      return false;
    }
    if (_filters.field == 'artist' && !_contains(candidate.artist, _query)) {
      return false;
    }
    // Catalog candidates do not reliably carry language, chord, or timing
    // metadata. Those filters apply after discovery, when provider results can
    // be evaluated from their actual lyric bodies and timing tracks.
    return true;
  }

  bool _contains(String value, String query) =>
      value.toLowerCase().contains(query.trim().toLowerCase());

  bool _isEditorialCandidate(SongCandidate candidate) {
    final kind = candidate.metadata['kind']?.toString().toLowerCase();
    if (const {
      'article',
      'editorial',
      'news',
      'release_calendar',
    }.contains(kind)) {
      return true;
    }
    return RegExp(
      r'\brelease\s+calendar\b',
      caseSensitive: false,
    ).hasMatch(candidate.title);
  }

  int _candidateRelevance(SongCandidate candidate, String query) {
    final tokens = RegExp(
      r'[\p{L}\p{N}]+',
      unicode: true,
    ).allMatches(query.toLowerCase()).map((match) => match.group(0)!).toSet();
    if (tokens.isEmpty) return 0;
    final title = RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(candidate.title.toLowerCase())
        .map((match) => match.group(0)!)
        .toSet();
    final artist = RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(candidate.artist.toLowerCase())
        .map((match) => match.group(0)!)
        .toSet();
    return tokens.where(title.contains).length * 4 +
        tokens.where(artist.contains).length -
        title.difference(tokens).length;
  }

  SearchComparisonData? _comparison() {
    final candidate = app.selection;
    if (candidate == null || _selectedQuery != _query.trim()) return null;
    final alternatives =
        app.results.map(_version).where(_versionMatchesFilters).toList()
          ..sort((a, b) {
            int score(SourceVersionData value) =>
                (value.sameRecording ? 4 : 0) +
                (value.hasChords ? 2 : 0) +
                (value.hasTiming ? 1 : 0);
            return score(b).compareTo(score(a));
          });
    final combined = app.combined;
    final combinedMatchesFilters = _combinedMatchesFilters(combined);
    final chosenSourceId = combined?.extra['selectedSourceId'];
    final contributorCount = combined == null
        ? 0
        : contributingProviderIds(combined).length;
    final chosenSource = app.results
        .where((item) => item.id == chosenSourceId)
        .firstOrNull;
    final suggested = combined == null || !combinedMatchesFilters
        ? null
        : SourceVersionData(
            id: 'combined',
            providerId: 'combined',
            // The UI renders combined entries from [sourceCount]; there is no
            // provider name to show.
            providerName: contributorCount == 1 && chosenSource != null
                ? app.providers
                          .where(
                            (provider) =>
                                provider.id ==
                                chosenSource.candidate.providerId,
                          )
                          .firstOrNull
                          ?.name ??
                      chosenSource.candidate.providerId
                : '',
            sourceCount: contributorCount,
            title: combined.title,
            artist: combined.artist,
            album: combined.metadata['album'] as String?,
            durationSeconds: _validDuration(
              combined.metadata['durationSeconds'],
            ),
            artworkUrl: combined.metadata['artworkUrl'] as String?,
            hasLyrics: arrangement.plainLyrics(combined.body).trim().isNotEmpty,
            hasChords: combined.hasChords,
            hasTiming: _hasUsableTiming(combined.timingTracks),
            sameRecording: chosenSource?.matchKind == MatchKind.sameRecording,
            matchSummary: contributorCount > 1
                ? 'combined_sources'
                : 'best_available',
            bodyPreview: _lines(combined.body).take(3).toList(),
            canSave:
                !app.discovering &&
                combined.body.trim().isNotEmpty &&
                app.savedResultId() == null,
            savedSongId: app.savedResultId(),
            underlyingSourceId: contributorCount == 1 ? chosenSource?.id : null,
          );
    final chosenId = _effectiveSelectionId(suggested?.id, alternatives);
    final checks = app.checks.values
        .map(
          (check) => SearchProviderCheckData(
            id: check.providerId,
            name:
                app.providers
                    .where((provider) => provider.id == check.providerId)
                    .firstOrNull
                    ?.name ??
                check.providerId,
            state: check.result?.matchKind == MatchKind.rejected
                ? 'rejected'
                : check.state,
          ),
        )
        .toList();
    return SearchComparisonData(
      reference: _reference(candidate),
      suggested: suggested,
      alternatives: alternatives,
      selectedVersionId: chosenId,
      error: app.errorCode,
      discoveryError: app.errorCode,
      discovering: app.discovering,
      noUsableLyrics:
          !app.discovering && !app.results.any(_isUsableLyricResult),
      providerChecks: checks,
    );
  }

  String? _effectiveSelectionId(
    String? suggestedId,
    List<SourceVersionData> alternatives,
  ) {
    final selectedAlternative = alternatives
        .where((item) => item.id == _selectedVersionId && item.isUsableVersion)
        .firstOrNull;
    if (_selectedVersionId == 'combined' && suggestedId != null) {
      return 'combined';
    }
    return selectedAlternative?.id ??
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

  bool _combinedMatchesFilters(SongDocument? combined) {
    if (combined == null ||
        (_filters.chordsOnly && !combined.hasChords) ||
        (_filters.timedOnly && !_hasUsableTiming(combined.timingTracks))) {
      return false;
    }
    if (_filters.language.isNotEmpty &&
        (combined.metadata['language'] as String?)?.toLowerCase() !=
            _filters.language.toLowerCase()) {
      return false;
    }
    return true;
  }

  SourceVersionData _version(SourceResult result) {
    final candidate = result.candidate;
    final check = app.checks[candidate.providerId];
    final savedId = app.savedResultId(source: result);
    return SourceVersionData(
      id: result.id,
      providerId: candidate.providerId,
      providerName:
          app.providers
              .where((item) => item.id == candidate.providerId)
              .firstOrNull
              ?.name ??
          candidate.providerId,
      title: candidate.title,
      artist: candidate.artist,
      album: candidate.album ?? result.metadata['album'] as String?,
      durationSeconds:
          _validDuration(candidate.durationSeconds) ??
          _validDuration(result.metadata['durationSeconds']) ??
          _validDuration(candidate.metadata['durationSeconds']),
      artworkUrl:
          candidate.artworkUrl ?? result.metadata['artworkUrl'] as String?,
      rating: (result.metadata['rating'] as num?)?.toDouble(),
      ratingCount: result.metadata['ratingCount'] as int?,
      hasLyrics: arrangement.plainLyrics(result.body).trim().isNotEmpty,
      isUsableVersion: _isUsableLyricResult(result),
      hasChords: result.hasChords,
      hasTiming: _hasUsableTiming(result.timingTracks),
      sameRecording: result.matchKind == MatchKind.sameRecording,
      matchSummary: result.matchReason ?? '',
      status: check?.state == 'failed' || check?.state == 'unavailable'
          ? LoadState.failed
          : LoadState.loaded,
      bodyPreview: _lines(result.body).take(3).toList(),
      canSave:
          !app.discovering &&
          result.matchKind != MatchKind.rejected &&
          _isUsableLyricResult(result) &&
          app.combined != null &&
          savedId == null,
      savedSongId: savedId,
    );
  }

  static final _sectionPattern = RegExp(
    r'^\s*\[((?:pre[- ]?chorus|post[- ]?chorus|verse|chorus|bridge|intro|outro|instrumental|interlude|solo|refrain|hook|breakdown|coda|tag|ending)[^\]]*)\]\s*$',
    caseSensitive: false,
  );

  static List<LyricLineData> _lines(String body) {
    var lyricIndex = 0;
    return arrangement.parseArrangement(body).asMap().entries.map((entry) {
      final line = entry.value;
      final section =
          arrangement.sectionLabelForLine(line) ??
          _sectionPattern.firstMatch(line.text)?.group(1)?.trim();
      final chords = line.chords
          .map(
            (chord) =>
                LyricChord(graphemeOffset: chord.offset, symbol: chord.chord),
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
        isBlank:
            section != null || line.directive || (!hasLyrics && chords.isEmpty),
      );
    }).toList();
  }

  Map<String, double> _timedLineStarts(
    List<LyricLineData> lines,
    SongDocument song,
    String timingMode,
  ) {
    if (timingMode != 'timed') return const {};
    final track = song.timingTracks
        .where(
          (item) =>
              item.id == song.activeTimingTrackId &&
              item.status == TimingStatus.usable,
        )
        .firstOrNull;
    if (track == null || track.cues.isEmpty) return const {};

    final binding = jsonMap(track.extra['binding']);
    final rawOccurrences = binding['occurrences'];
    final occurrences = rawOccurrences is List
        ? rawOccurrences.whereType<Map>().toList()
        : timingOccurrenceMap(track, song.body);
    final lineIds = lines.map((line) => line.id).toSet();
    final starts = <String, double>{};
    for (final cue in track.cues) {
      final mapping = occurrences
          .where((item) => item['source'] == cue.occurrenceId)
          .firstOrNull;
      final target = mapping?['target'] is String
          ? mapping!['target'] as String
          : cue.occurrenceId;
      if (!lineIds.contains(target)) continue;
      final seconds = cue.startUs / 1000000;
      final previous = starts[target];
      if (previous == null || seconds < previous) starts[target] = seconds;
    }
    return starts;
  }

  String? _currentLineId(List<LyricLineData> lines, SongDocument? song) {
    if (song == null || lines.isEmpty) return null;
    final timingMode = app.settings['timingMode'] as String? ?? 'estimated';
    if (timingMode == 'manual') return null;
    final activeTrack = timingMode == 'timed'
        ? song.timingTracks
              .where(
                (track) =>
                    track.id == song.activeTimingTrackId &&
                    track.status == TimingStatus.usable,
              )
              .firstOrNull
        : null;
    if (activeTrack != null && activeTrack.cues.isNotEmpty) {
      final elapsedUs = (_progress * 1000000).round();
      final cue = activeTrack.cues
          .where((item) => item.startUs <= elapsedUs)
          .fold<TimingCue?>(
            null,
            (latest, item) =>
                latest == null || item.startUs > latest.startUs ? item : latest,
          );
      if (cue != null) {
        final binding = jsonMap(activeTrack.extra['binding']);
        final rawOccurrences = binding['occurrences'];
        final occurrences = rawOccurrences is List
            ? rawOccurrences.whereType<Map>().toList()
            : timingOccurrenceMap(activeTrack, song.body);
        var target = cue.occurrenceId;
        if (occurrences.isNotEmpty) {
          final mapping = occurrences
              .where((item) => item['source'] == cue.occurrenceId)
              .firstOrNull;
          if (mapping?['target'] is String) {
            target = mapping!['target'] as String;
          }
        }
        final targetLine = lines.where((line) => line.id == target).firstOrNull;
        if (targetLine != null) return targetLine.id;
      }
    }
    if (timingMode == 'timed') return null;
    final duration =
        _validDuration(song.metadata['durationSeconds']) ??
        _estimatedDuration(lines.length);
    if (duration <= 0) return null;
    final visibleLines = lines.where((line) => !line.isBlank).toList();
    if (visibleLines.isEmpty) return null;
    final index = ((_progress / duration) * visibleLines.length).floor().clamp(
      0,
      visibleLines.length - 1,
    );
    return visibleLines[index].id;
  }

  static double _estimatedDuration(int lineCount) =>
      (lineCount * 3.4).clamp(90, 600).toDouble();

  String _subtitle(SongDocument song) => [
    if (song.metadata['album'] is String) song.metadata['album'],
    if (_validDuration(song.metadata['durationSeconds']) case final duration?)
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
    final preferred = app.settings['defaultView'] as String?;
    _tab =
        VerseTab.values.where((value) => value.name == preferred).firstOrNull ??
        VerseTab.home;
    notifyListeners();
  }

  @override
  void setTab(VerseTab tab) {
    _tab = tab;
    _route = VerseRoute.main;
    _setlistId = null;
    _setlistEntryId = null;
    unawaited(app.setSetting('defaultView', tab.name));
    notifyListeners();
  }

  @override
  void setHomeListMode(HomeListMode mode) {
    _homeMode = mode;
    if (mode == HomeListMode.online) {
      _normalizeOnlineMetadataFilter();
      unawaited(submitSearch());
    }
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
    if (_query.trim() != value.trim()) _cachedAutocomplete = const [];
    _query = value;
    app.errorCode = null;
    if (_selectedQuery != value.trim()) {
      _selectedVersionId = null;
      _selectedQuery = null;
    }
    if (value.trim().isNotEmpty) {
      _homeMode = HomeListMode.online;
      _normalizeOnlineMetadataFilter();
    }
    _searchDebounce?.cancel();
    app.cancelSearch();
    if (value.trim().length >= 2) {
      _searchDebounce = Timer(
        const Duration(milliseconds: 360),
        () => unawaited(app.search(value)),
      );
    }
    notifyListeners();
  }

  @override
  void changeSearchSong() {
    _selectedQuery = null;
    _selectedVersionId = null;
    _route = VerseRoute.main;
    _tab = VerseTab.home;
    _homeMode = HomeListMode.online;
    notifyListeners();
  }

  @override
  Future<void> submitSearch() async {
    _homeMode = HomeListMode.online;
    _searchDebounce?.cancel();
    await app.search(_query);
    _cachedAutocomplete = app.suggestions;
    notifyListeners();
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
    final effectiveSelection = _comparison()?.selectedVersionId;
    if (effectiveSelection != null || _selectedVersionId != null) {
      _selectedVersionId = effectiveSelection;
    }
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
    final candidates = app.suggestions.isNotEmpty
        ? app.suggestions
        : _cachedAutocomplete;
    if (app.suggestions.isNotEmpty) _cachedAutocomplete = app.suggestions;
    final candidate = candidates
        .where((item) => item.identity == reference.id)
        .firstOrNull;
    if (candidate == null) return;
    _selectedVersionId = null;
    _selectedQuery = _query.trim();
    await app.selectCandidate(candidate);
    _chooseFallbackVersion();
    notifyListeners();
  }

  @override
  Future<void> retrySelectedSongDiscovery() async {
    final candidate = app.selection;
    if (candidate == null) return;
    _selectedVersionId = null;
    _selectedQuery = _query.trim();
    await app.selectCandidate(candidate);
    _chooseFallbackVersion();
    notifyListeners();
  }

  void _chooseFallbackVersion() {
    if (_disposed) return;
    final combined = app.combined;
    final combinedMatchesFilters = _combinedMatchesFilters(combined);
    if (_selectedVersionId == 'combined' && combinedMatchesFilters) return;
    if (_selectedVersionId != null) {
      final selectedResult = app.results
          .where((item) => item.id == _selectedVersionId)
          .firstOrNull;
      if (selectedResult != null &&
          selectedResult.matchKind != MatchKind.rejected &&
          _isUsableLyricResult(selectedResult) &&
          _versionMatchesFilters(_version(selectedResult))) {
        return;
      }
    }
    _selectedVersionId = combinedMatchesFilters
        ? null
        : app.results
              .map(_version)
              .where(_versionMatchesFilters)
              .where((item) => item.canSave)
              .firstOrNull
              ?.id;
  }

  @override
  void selectVersion(String versionId) {
    _selectedVersionId = versionId;
    notifyListeners();
  }

  @override
  Future<void> saveSelectedVersion() async {
    if (app.discovering) return;
    final comparison = _comparison();
    final availableAlternatives = comparison == null
        ? app.results.map(_version).where(_versionMatchesFilters).toList()
        : comparison.alternatives;
    final selectedId =
        comparison?.selectedVersionId ??
        _effectiveSelectionId(
          _combinedMatchesFilters(app.combined) ? 'combined' : null,
          availableAlternatives,
        );
    if (selectedId == null) {
      postNotice(UiNotice.songSaveFailed);
      return;
    }
    final version = selectedId == 'combined'
        ? null
        : app.results.where((item) => item.id == selectedId).firstOrNull;
    if (selectedId != 'combined' &&
        (version == null || !_isUsableLyricResult(version))) {
      postNotice(UiNotice.songSaveFailed);
      return;
    }
    final SongDocument song;
    try {
      song = await app.saveResult(source: version);
    } catch (_) {
      postNotice(UiNotice.songSaveFailed);
      return;
    }
    _setlistId = null;
    _setlistEntryId = null;
    _homeMode = HomeListMode.recent;
    await _openSong(song.id);
    postNotice(UiNotice.songSaved);
  }

  @override
  Future<void> compareCurrentSongVersions() async {
    final song = currentSong;
    final referenceId = app.selection?.identity;
    if (song == null ||
        referenceId == null ||
        !_songMatchesSearchReference(song, referenceId) ||
        _selectedQuery != _query.trim() ||
        _query.trim() != app.query.trim()) {
      return;
    }
    _setlistId = null;
    _setlistEntryId = null;
    _route = VerseRoute.main;
    _tab = VerseTab.home;
    _homeMode = HomeListMode.online;
    _selectedQuery = app.query.trim();
    _selectedVersionId = song.extra['selectedSourceId'] as String?;
    notifyListeners();
  }

  @override
  Future<void> openSong(String id) async {
    if (app.findSong(id) == null) return;
    _setlistId = null;
    _setlistEntryId = null;
    await _openSong(id);
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
    _setlistId = setlistId;
    _setlistEntryId = entryId;
    await _openSong(entry.songId);
  }

  Future<void> _openSong(String id) async {
    _songId = id;
    _route = VerseRoute.reader;
    _stopPlayer();
    _progress = 0;
    _transpose = 0;
    await app.recordUse('song', id);
    notifyListeners();
  }

  @override
  Future<void> openSetlist(String id) async {
    _setlistId = id;
    _setlistEntryId = null;
    _editingSetlist = false;
    _route = VerseRoute.setlistDetail;
    final value = currentSetlist;
    if (value != null) await app.recordUse('setlist', id);
    notifyListeners();
  }

  @override
  Future<void> editSong(String id) async {
    final song = app.findSong(id);
    if (song == null) return;
    _songId = id;
    _openEditor(song, isNew: false);
    notifyListeners();
  }

  void _openEditor(SongDocument song, {required bool isNew}) {
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
    _setlistId = id;
    _editingSetlist = true;
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
    final value = app.setlists.where((item) => item.id == id).firstOrNull;
    if (value == null) return;
    await _guard(() => app.toggleSetlistFavorite(value));
  }

  @override
  Future<void> createSong() {
    final song = SongDocument(id: newId(), title: '', artist: '', body: '');
    _stopPlayer();
    _progress = 0;
    _transpose = 0;
    _setlistId = null;
    _setlistEntryId = null;
    _songId = song.id;
    _draftSong = song;
    _openEditor(song, isNew: true);
    notifyListeners();
    return Future<void>.value();
  }

  @override
  Future<void> createSetlist({String? name, String? songId}) async {
    final value = SetlistDocument(
      id: newId(),
      name: name?.trim() ?? '',
      entries: songId == null
          ? const []
          : [SetlistEntry(id: newId(), songId: songId)],
    );
    if (!await _guard(() => app.saveSetlist(value))) return;
    if (songId != null) {
      // Adding a song to a brand-new setlist keeps the person where they are.
      return;
    }
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
    } catch (_) {
      postNotice(UiNotice.exportFailed);
    }
  }

  SetlistDocument? _setlistById(String id) =>
      app.setlists.where((item) => item.id == id).firstOrNull;

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
    return _validDuration(song?.metadata['durationSeconds']) ??
        _estimatedDuration(_baseState().songLines.length);
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
    if (![.5, 1, 1.5, 2].contains(speed) || speed == _playbackSpeed) return;
    if (_playing) {
      _advancePlayer(
        _playBase + _playWatch.elapsedMilliseconds / 1000 * _playbackSpeed,
      );
    }
    _playbackSpeed = speed;
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
    if (list == null || _songId == null) return;
    var index = list.entries.indexWhere((entry) => entry.id == _setlistEntryId);
    if (index < 0) {
      index = list.entries.indexWhere((entry) => entry.songId == _songId);
    }
    final next = index + direction;
    if (next < 0 || next >= list.entries.length) return;
    _songId = list.entries[next].songId;
    _setlistEntryId = list.entries[next].id;
    _progress = 0;
    _transpose = 0;
    if (_playing) _resetPlayClock();
    notifyListeners();
  }

  @override
  Future<void> transpose(int semitones) async {
    _transpose += semitones;
    notifyListeners();
  }

  // -- Editing -------------------------------------------------------------

  @override
  Future<void> saveLyricsEdit(String chordProText) async {
    final old = currentSong;
    if (old == null) return;
    final parsed = _codec.decode(chordProText);
    if (old.id == _draftSong?.id &&
        parsed.title.trim().isEmpty &&
        parsed.body.trim().isEmpty) {
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
      conflicted = !await app.saveSong(edited, baseHash: _editorBaseHash);
    }, failure: UiNotice.editorSaveFailed)) {
      return;
    }
    _draftSong = null;
    _editing = false;
    _editorData = null;
    _editorDirty = false;
    _route = VerseRoute.reader;
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
    if (_draftSong?.id == id) {
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
    if (_songId == id) {
      _songId = null;
      _route = VerseRoute.main;
    }
    notifyListeners();
    postNotice(UiNotice.songDeleted);
  }

  @override
  Future<void> deleteSetlist(String id) async {
    if (!await _guard(() => app.deleteSetlist(id))) return;
    if (_setlistId == id) {
      _setlistId = null;
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
    final orderedEntries = entryOrder == null
        ? current.entries
        : _orderEntries(current.entries, entryOrder);
    final saved = await _guard(
      () => app.saveSetlist(
        SetlistDocument(
          id: current.id,
          name: name.trim().isEmpty ? current.name : name.trim(),
          notes: notes,
          favorite: current.favorite,
          createdAt: current.createdAt,
          entries: orderedEntries,
        ),
      ),
    );
    if (saved && finishEditing) {
      _editingSetlist = false;
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
    final current = _setlistById(setlistId);
    if (current == null) return;
    await _saveSetlistWith(
      current,
      entries: current.entries.where((entry) => entry.id != entryId).toList(),
      name: name,
      notes: notes,
    );
  }

  Future<void> _saveSetlistWith(
    SetlistDocument current, {
    required List<SetlistEntry> entries,
    String? name,
    String? notes,
  }) => _guard(
    () => app.saveSetlist(
      SetlistDocument(
        id: current.id,
        name: name == null || name.trim().isEmpty ? current.name : name.trim(),
        notes: notes ?? current.notes,
        favorite: current.favorite,
        createdAt: current.createdAt,
        entries: entries,
      ),
    ),
  );

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
    await _guard(() => app.addToSetlist(songId, setlistId));
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
            providerName:
                app.providers
                    .where((item) => item.id == source.candidate.providerId)
                    .firstOrNull
                    ?.name ??
                source.candidate.providerId,
            attribution: source.attribution ?? '',
            matchReason: source.matchReason,
            url: source.candidate.url,
          ),
      ],
    );
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) =>
      app.setSetting('themeMode', mode.name);
  @override
  Future<void> setLanguage(String? languageCode) =>
      app.setSetting('locale', languageCode);
  @override
  Future<void> setPalette(String palette) => app.setSetting('palette', palette);
  @override
  Future<void> setFontFamily(String fontFamily) =>
      app.setSetting('fontFamily', fontFamily);
  @override
  Future<void> setLyricsFontSize(double size) =>
      app.setSetting('readerFontSize', size);
  @override
  Future<void> setShowChords(bool show) => app.setSetting('showChords', show);

  @override
  Future<void> setAutoscroll(bool enabled) =>
      app.setSetting('autoscroll', enabled);
  @override
  Future<void> setTimingMode(String mode) => app.setSetting('timingMode', mode);
  @override
  Future<void> setProviderEnabled(String id, bool enabled) =>
      app.setProviderEnabled(id, enabled);

  @override
  Future<bool> refreshSources() => app.refreshSources();
  // ---- Sync engine state used by the account UI --------------------------
  DateTime? get _lastSyncAt => app.lastSyncAt;
  int get _lastSyncConflicts => app.lastSyncConflicts;
  String? get _lastSyncErrorCode => app.lastSyncErrorCode;
  bool get _autoSyncEnabled => app.autoSyncEnabled;

  @override
  Future<void> setAutoSync(bool enabled) => app.setAutoSync(enabled);

  @override
  void onAppResumed() => app.onAppResumed();

  @override
  Future<void> adoptAccount({required bool mergeLocal}) =>
      app.adoptAccount(mergeLocal: mergeLocal);

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
  Future<void> syncNow() async {
    if (!app.syncConnected) return;
    final conflictsBefore = _lastSyncConflicts;
    await app.syncNow();
    if (app.syncError != null) {
      postNotice(UiNotice.syncFailed);
    } else {
      postNotice(
        _lastSyncConflicts > conflictsBefore
            ? UiNotice.syncConflictsFound
            : UiNotice.syncSucceeded,
      );
    }
  }

  @override
  Future<void> importChordPro() async {
    if (onImport == null) return;
    try {
      await onImport!();
    } on FormatException catch (error) {
      postNotice(switch (error.message) {
        'file_too_large' => UiNotice.importTooLarge,
        'unsupported_file' => UiNotice.importUnsupported,
        _ => UiNotice.importFailed,
      });
    } catch (_) {
      postNotice(UiNotice.importFailed);
    }
  }

  @override
  Future<void> back() async {
    _stopPlayer();
    if (_route == VerseRoute.editor) {
      _editing = false;
      _editorData = null;
      _editorDirty = false;
      if (_draftSong != null) {
        _draftSong = null;
        _songId = null;
        _route = VerseRoute.main;
      } else {
        _route = VerseRoute.reader;
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
      _setlistId = null;
      _editingSetlist = false;
      _route = VerseRoute.main;
    } else if (_route != VerseRoute.main) {
      _route = VerseRoute.main;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    _playerTimer?.cancel();
    app.removeListener(_onAppChanged);
    _notices.close();
    _position.dispose();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
