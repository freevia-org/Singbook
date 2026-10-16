// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'A calm place to find, organize, and sing from your song library.';

  @override
  String get aboutMadeForSinging => 'Made for singing together';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navSongs => 'Songs';

  @override
  String get navSetlists => 'Setlists';

  @override
  String get navSettings => 'Settings';

  @override
  String get navSettingsCompact => 'Settings';

  @override
  String get navSearch => 'Search';

  @override
  String get navBack => 'Back';

  @override
  String get appExitBackAgain => 'Press back again to exit';

  @override
  String get navClose => 'Close';

  @override
  String get navMore => 'More actions';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDone => 'Done';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionShare => 'Share';

  @override
  String get actionPrint => 'Print';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionImport => 'Import';

  @override
  String get actionExport => 'Export';

  @override
  String get actionExpand => 'Expand';

  @override
  String get actionCollapse => 'Collapse';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get actionMoveUp => 'Move up';

  @override
  String get actionMoveDown => 'Move down';

  @override
  String get actionPrevious => 'Previous';

  @override
  String get actionNext => 'Next';

  @override
  String get searchHint => 'Song, artist or lyrics';

  @override
  String get searchCatalogHint => 'Song or artist';

  @override
  String get searchChangeSong => 'Change song';

  @override
  String get searchSelectedPreview => 'Selected preview';

  @override
  String get searchSubmit => 'Search';

  @override
  String get searchFilters => 'Search options';

  @override
  String get searchFiltersShow => 'Show search options';

  @override
  String get searchFiltersHide => 'Hide search options';

  @override
  String get searchFilterArtist => 'Artist';

  @override
  String get searchFilterTitle => 'Song title';

  @override
  String get searchFilterLyrics => 'Lyrics';

  @override
  String get searchFilterChords => 'Has chords';

  @override
  String get searchFilterTimed => 'Timed lyrics';

  @override
  String get searchFilterLanguage => 'Language';

  @override
  String get searchFilterAll => 'Any';

  @override
  String get searchAutocompleteLabel => 'Suggestions';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery => 'Enter a song, artist, or lyric to search.';

  @override
  String get searchCatalogEmptyQuery => 'Enter a song or artist to search.';

  @override
  String get searchNoResults => 'No songs found. Try a different search.';

  @override
  String get searchLoading => 'Searching songs…';

  @override
  String get searchError => 'Search could not be completed.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Recent';

  @override
  String get searchFavoritesTab => 'Favorites';

  @override
  String get searchSuggested => 'Suggested match';

  @override
  String get searchAlternatives => 'Other matches';

  @override
  String get searchCompare => 'Compare versions';

  @override
  String get searchChooseVersion => 'Choose this version';

  @override
  String get searchFullPreview => 'Full preview';

  @override
  String get searchArrangementNotes => 'Arrangement notes';

  @override
  String get searchOpenLyrics => 'Open lyrics';

  @override
  String get searchContributions => 'Sources used';

  @override
  String get searchVersionChecking => 'Checking this version…';

  @override
  String get searchVersionUnavailable =>
      'This version can’t be used. Choose another version.';

  @override
  String get searchPreviewUnavailable => 'No lyric preview available.';

  @override
  String get searchSongMatch => 'Song match';

  @override
  String get searchRecordingMatch => 'Recording match';

  @override
  String get searchMatchUnverified => 'Recording not verified';

  @override
  String get searchMatchExact => 'Exact recording match';

  @override
  String get searchMatchPossible => 'Possible match';

  @override
  String get searchAvailability => 'Availability';

  @override
  String get searchLyricsAvailable => 'Lyrics available';

  @override
  String get searchLyricsUnavailable => 'Lyrics unavailable';

  @override
  String get searchChordsAvailable => 'Chords available';

  @override
  String get searchChordsUnavailable => 'No chords';

  @override
  String get searchTimingAvailable => 'Timing available';

  @override
  String get searchTimingUnavailable => 'No timing';

  @override
  String get searchDurationUnknown => 'Duration unknown';

  @override
  String searchRating(String rating) {
    return 'Rating $rating';
  }

  @override
  String get searchSourceLabel => 'Source';

  @override
  String get searchMetadata => 'Song details';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Artist';

  @override
  String get searchYear => 'Year';

  @override
  String get searchLanguage => 'Language';

  @override
  String get searchViewVersions => 'View versions';

  @override
  String get searchSaved => 'Song saved to your library.';

  @override
  String get searchSaveOpenLyrics => 'Save & open lyrics';

  @override
  String get searchOtherResults => 'Other results';

  @override
  String get searchSaveFailed => 'Could not save this song.';

  @override
  String get homeRecentSongs => 'Recent songs';

  @override
  String get homeRecentlyPlayed => 'Recently played';

  @override
  String get homeFavorites => 'Favorites';

  @override
  String get homeHistory => 'History';

  @override
  String get homeHistoryClear => 'Clear history';

  @override
  String get homeHistoryCleared => 'History cleared.';

  @override
  String get homeHistoryEmpty => 'Songs you open will appear here.';

  @override
  String get homeFavoritesEmpty =>
      'Your favorite songs and setlists will appear here.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items shown',
      one: '1 item shown',
      zero: '0 items shown',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Your recent songs and setlists will appear here.';

  @override
  String get homeTimelineLabel => 'History timeline';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Full history';

  @override
  String get homeShowFavorites => 'Show favorites';

  @override
  String get homeShowRecent => 'Show recent';

  @override
  String get songsTitle => 'Songs';

  @override
  String get songsEmpty => 'Your songs will appear here.';

  @override
  String get songsEmptySearch => 'No songs match your search.';

  @override
  String get songsAdd => 'Add song';

  @override
  String get songsSortAlphabetical => 'Sort alphabetically';

  @override
  String get songsAlphabetNavigation => 'Song index';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
      zero: 'never',
    );
    return 'Opened $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Add to favorites';

  @override
  String get songFavoriteRemove => 'Remove from favorites';

  @override
  String get songMenuLabel => 'Song actions';

  @override
  String get songInfo => 'Song details';

  @override
  String get setlistMenuLabel => 'Setlist actions';

  @override
  String get songAddToSetlist => 'Add to setlist';

  @override
  String get songCopyChordPro => 'Copy ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Delete song?';

  @override
  String get songDeleteConfirmMessage =>
      'This song will be removed from your library.';

  @override
  String get songDeleted => 'Song deleted.';

  @override
  String get setlistsTitle => 'Setlists';

  @override
  String get setlistsEmpty =>
      'Create a setlist for your next rehearsal or performance.';

  @override
  String get setlistsEmptySearch => 'No setlists match your search.';

  @override
  String get setlistCreate => 'New setlist';

  @override
  String get setlistNameHint => 'Setlist name';

  @override
  String get setlistNotes => 'Notes';

  @override
  String get setlistEntryOverride => 'Song-specific key and capo';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: 'No songs',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'At least $duration';
  }

  @override
  String get setlistDurationUnknown => 'Duration unknown';

  @override
  String setlistActivity(String date) {
    return 'Last activity $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Created $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Edited $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Last played $date';
  }

  @override
  String get setlistSongsEmpty => 'This setlist has no songs yet.';

  @override
  String get setlistAddSongs => 'Add songs';

  @override
  String get setlistReorder => 'Reorder songs';

  @override
  String setlistMoveSongUp(String song) {
    return 'Move $song up';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Move $song down';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Remove $song from setlist';
  }

  @override
  String get setlistDuplicate => 'Duplicate setlist';

  @override
  String get setlistFavoriteAdd => 'Favorite setlist';

  @override
  String get setlistFavoriteRemove => 'Remove setlist from favorites';

  @override
  String get setlistShare => 'Share as setlist file';

  @override
  String get setlistSharePdf => 'Share as PDF';

  @override
  String get setlistPrint => 'Print';

  @override
  String get setlistDeleteConfirmTitle => 'Delete setlist?';

  @override
  String get setlistDeleteConfirmMessage =>
      'The setlist will be removed. Songs in your library will stay.';

  @override
  String get setlistDeleted => 'Setlist deleted.';

  @override
  String get readerTitle => 'Lyrics';

  @override
  String get readerNoLyrics => 'Lyrics have not been added yet.';

  @override
  String get readerShowChords => 'Show chords';

  @override
  String get readerHideChords => 'Hide chords';

  @override
  String get readerTranspose => 'Transpose chords';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semitones',
      one: '1 semitone',
      zero: '0 semitones',
    );
    return 'Transpose by $_temp0';
  }

  @override
  String get readerSaved => 'Saved';

  @override
  String get readerEdit => 'Edit lyrics and details';

  @override
  String get playerPlay => 'Play lyric scrolling';

  @override
  String get playerPause => 'Pause lyric scrolling';

  @override
  String get playerResume => 'Resume lyric scrolling';

  @override
  String get playerSeek => 'Playback position';

  @override
  String playerElapsed(String time) {
    return 'Elapsed time $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Time remaining $time';
  }

  @override
  String get playerTimingMode => 'Scrolling mode';

  @override
  String get playerTimedLyrics => 'Timed lyrics';

  @override
  String get playerStartScroll => 'Start auto-scroll';

  @override
  String get playerEstimatedPace => 'Estimated pace';

  @override
  String get playerScrollSpeed => 'Scroll speed';

  @override
  String playerEstimatedDuration(String time) {
    return 'Estimated $time';
  }

  @override
  String get playerLyricsOnly => 'Lyric scrolling · no audio';

  @override
  String get playerManualScroll => 'Manual scroll';

  @override
  String get playerTimingStatusReady =>
      'Lyrics will follow the available timing.';

  @override
  String get playerTimingStatusEstimated =>
      'Scrolling pace is estimated from song length.';

  @override
  String get playerTimingStatusManual => 'Scroll the lyrics yourself.';

  @override
  String get playerTimingStatusUnavailable =>
      'Timed scrolling is unavailable for this song.';

  @override
  String get playerDurationUnknown =>
      'Add a song duration to use estimated scrolling.';

  @override
  String get playerProgressLabel => 'Song progress';

  @override
  String get playerCurrentSection => 'Current section';

  @override
  String get playerPreviousSection => 'Previous section';

  @override
  String get playerNextSection => 'Next section';

  @override
  String get playerPreviousSectionSong =>
      'Previous section · hold for previous setlist song';

  @override
  String get playerNextSectionSong =>
      'Next section · hold for next setlist song';

  @override
  String get playerPreviousSong => 'Previous song';

  @override
  String get playerNextSong => 'Next song';

  @override
  String get editorTitle => 'Edit song';

  @override
  String get editorTitleField => 'Song title';

  @override
  String get editorArtistField => 'Artist';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Lyrics';

  @override
  String get editorChordsField => 'Chords';

  @override
  String get editorKeyField => 'Key';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Tuning';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Duration';

  @override
  String get editorTimeSignatureField => 'Time signature';

  @override
  String get editorLanguageField => 'Language';

  @override
  String get editorYearField => 'Year';

  @override
  String get editorComposerField => 'Composer';

  @override
  String get editorLyricistField => 'Lyricist';

  @override
  String get editorCopyrightField => 'Copyright';

  @override
  String get editorLicenseField => 'License';

  @override
  String get songInfoSources => 'Sources and credits';

  @override
  String get searchMatchSameSong => 'Same song; recording not confirmed';

  @override
  String get searchMatchNeedsAgreement => 'Chart needs lyric confirmation';

  @override
  String get searchMatchDifferentLyrics =>
      'Lyrics differ from the selected song';

  @override
  String get searchMatchCombinedSources =>
      'Details combined from multiple sources';

  @override
  String get searchCombinedLabel => 'All';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count song matches',
      one: '1 song match',
      zero: '0 song matches',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count source versions',
      one: '1 source version',
      zero: '0 source versions',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Best available match';

  @override
  String get providerDescriptionUnknown => 'Song source';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Download a ChordPro file from the source, then import it.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Download with a free account, then import the file.';

  @override
  String get providerDescPublicChordSheets => 'Public chord sheets.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Historical lyrics licensed by work.';

  @override
  String get providerDescLicensedCatalog => 'Licensed lyric catalog.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Original songs under Creative Commons BY.';

  @override
  String get providerDescPerSongLicense => 'Lyrics licensed per song.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Recording and release details only.';

  @override
  String get providerDescCompositionMetadataOnly => 'Composition details only.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Artwork for exact recording matches only.';

  @override
  String get providerCapabilityLyrics => 'Lyrics';

  @override
  String get providerCapabilityChords => 'Chords';

  @override
  String get providerCapabilityTiming => 'Timed lyrics';

  @override
  String get providerCapabilitySearch => 'Search';

  @override
  String get providerCapabilityMetadata => 'Song details';

  @override
  String get editorArtworkField => 'Artwork link';

  @override
  String get editorLyricsHint => 'Tap a line to edit lyrics or chords.';

  @override
  String get editorSave => 'Save changes';

  @override
  String get editorSaved => 'Changes saved.';

  @override
  String get editorSaveFailed => 'Could not save changes.';

  @override
  String get editorSaveConflict =>
      'The song changed elsewhere. Your edits were saved as a separate copy.';

  @override
  String get editorUnsavedTitle => 'Discard changes?';

  @override
  String get editorUnsavedMessage => 'Your edits have not been saved.';

  @override
  String get editorFieldRequired => 'Enter a song title.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'Use device setting';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsColorPalette => 'Color palette';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get settingsLyricsPreview => 'Lyrics preview';

  @override
  String get settingsPlayer => 'Lyrics player';

  @override
  String get settingsDefaultShowChords => 'Show chords by default';

  @override
  String get settingsDefaultAutoscroll => 'Start lyric scrolling automatically';

  @override
  String get settingsDefaultTiming => 'Default scrolling mode';

  @override
  String get settingsLanguage => 'App language';

  @override
  String get settingsLanguageSystem => 'Use device language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Lyrics sources';

  @override
  String settingsSourceEnabled(String source) {
    return 'Enable source $source';
  }

  @override
  String get settingsSourceRefresh => 'Refresh source list';

  @override
  String get settingsSourcesUpdated => 'Sources updated.';

  @override
  String get settingsSourcesUpdateFailed => 'Could not refresh sources.';

  @override
  String get settingsImport => 'Import songs';

  @override
  String get settingsImportChordPro => 'Import ChordPro file';

  @override
  String get settingsImportSetlist => 'Import setlist file';

  @override
  String get settingsImportSuccess => 'Import complete.';

  @override
  String get settingsImportFailed => 'Could not import this file.';

  @override
  String get settingsImportUnsupported => 'This file type is not supported.';

  @override
  String get settingsShareSong => 'Share as ChordPro';

  @override
  String get settingsSharePdf => 'Share as PDF';

  @override
  String get settingsCopySong => 'Copy to clipboard';

  @override
  String get settingsPrintSong => 'Print only';

  @override
  String get settingsPrintSetlist => 'Print setlist with lyrics';

  @override
  String get settingsExportFailed => 'Could not prepare the file.';

  @override
  String get settingsCopied => 'Copied to clipboard.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsLegal => 'Legal';

  @override
  String get settingsClearHistory => 'Clear history';

  @override
  String get settingsClearHistoryConfirm =>
      'Clear your song and setlist history?';

  @override
  String get settingsHistoryCleared => 'History cleared.';

  @override
  String get accountTitle => 'Account and sync';

  @override
  String get accountUnavailable =>
      'Sync needs a build of Singbook with Google sign-in configured. This build keeps your songs on this device only.';

  @override
  String get accountSyncNow => 'Sync now';

  @override
  String get accountConnected =>
      'Connected. Choose Sync now to update your backup.';

  @override
  String get accountSignIn => 'Connect account';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountChange => 'Change account';

  @override
  String get accountSignedOut => 'Not connected';

  @override
  String get accountSyncing => 'Syncing your library…';

  @override
  String get accountSynced => 'Library synced.';

  @override
  String get accountSyncFailed => 'Could not sync your library.';

  @override
  String get accessibilityFavorite => 'Favorite';

  @override
  String get accessibilityNotFavorite => 'Not a favorite';

  @override
  String get accessibilitySearchField => 'Search songs';

  @override
  String get accessibilityClearSearch => 'Clear search text';

  @override
  String accessibilitySongMenu(String song) {
    return 'Actions for $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Actions for $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Expand songs in $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Collapse songs in $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Playback progress, $percent percent';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'History timeline, $date';
  }

  @override
  String get loading => 'Loading…';

  @override
  String get loadingSongs => 'Loading songs…';

  @override
  String get loadingSetlists => 'Loading setlists…';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorOffline => 'You appear to be offline.';

  @override
  String get errorPermission => 'Permission is needed to continue.';

  @override
  String get emptyFiltered => 'No items match these filters.';

  @override
  String get unknownValue => 'Unknown';

  @override
  String get durationUnknown => 'Duration unknown';

  @override
  String get metadataNotSet => 'Not set';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
      zero: 'No songs',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Navy';

  @override
  String get settingsPaletteSage => 'Sage';

  @override
  String get settingsPaletteOcean => 'Ocean';

  @override
  String get settingsPaletteClay => 'Clay';

  @override
  String get settingsPalettePlum => 'Plum';

  @override
  String get settingsFontSystem => 'System';

  @override
  String get settingsFontSerif => 'Serif';

  @override
  String get settingsFontMonospace => 'Monospace';

  @override
  String get settingsLyricsPreviewExample =>
      'When the morning comes, we will sing again.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Checking lyrics sources: $checked of $total complete.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'No usable lyrics found.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'The selected song was checked against the enabled sources, but none returned a usable lyric version.';

  @override
  String get searchDiscoveryError => 'Lyrics sources could not be checked.';

  @override
  String get searchDiscoveryRetry => 'Retry lyrics search';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources unavailable',
      one: '1 source unavailable',
      zero: '0 sources unavailable',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Check your connection and try again.';

  @override
  String get searchProviderChecks => 'Source checks';

  @override
  String get searchProviderPending => 'Checking';

  @override
  String get searchProviderFound => 'Match found';

  @override
  String get searchProviderRejected => 'Does not match';

  @override
  String get searchProviderFailed => 'Check failed';

  @override
  String get searchProviderUnavailable => 'No usable lyrics';

  @override
  String get searchCatalogFilterHint =>
      'Select a song to filter lyric versions by chords, timing, or language.';

  @override
  String get startupErrorTitle => 'Your library could not be opened.';

  @override
  String setlistCopyName(String name) {
    return '$name copy';
  }

  @override
  String get setlistSongMissing => 'Missing song';

  @override
  String get settingsImportTooLarge => 'This file is too large to import.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Jump to $letter';
  }

  @override
  String get actionDiscard => 'Discard';

  @override
  String get editorKeepEditing => 'Keep editing';

  @override
  String get settingsDefaultShowChordsHint =>
      'Show chords above the lyrics when a song has them.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Lyrics scroll with the song. Not used in manual scroll mode.';

  @override
  String get accountUnavailableTitle => 'Sync is not set up';

  @override
  String get accountSignedOutBenefits =>
      'Connecting Google Drive syncs your library. Song changes then sync automatically.';

  @override
  String get accountManualSyncHint =>
      'You can also tap Sync now to sync your library.';

  @override
  String get accountSignInWithGoogle => 'Sign in with Google';

  @override
  String get accountWorking => 'Working…';

  @override
  String get accountNeverSynced => 'Never synced';

  @override
  String get accountSyncedJustNow => 'Synced just now';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synced $count minutes ago',
      one: 'Synced 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synced $count hours ago',
      one: 'Synced 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synced $count days ago',
      one: 'Synced 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflicting edits kept as copies',
      one: '1 conflicting edit kept as a copy',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'The same song or setlist was edited in two places. Nothing was lost: the other version was saved as a separate copy.';

  @override
  String get accountReviewConflicts => 'Review copies';

  @override
  String get songsConflictFilterActive => 'Showing conflict copies only';

  @override
  String get songsConflictFilterClear => 'Show all songs';

  @override
  String get songsConflictBadge => 'Conflict copy';

  @override
  String get songsConflictEmpty => 'No conflict copies.';

  @override
  String get accountAutoSync => 'Sync automatically';

  @override
  String get accountAutoSyncHint =>
      'Sync after connecting and after adding, editing or removing a song.';

  @override
  String get accountSignOutTitle => 'Sign out of this account?';

  @override
  String get accountSignOutBody =>
      'Your songs and setlists stay on this device. They won\'t be backed up or synced until you sign in again.';

  @override
  String get accountUseDifferent => 'Use a different account';

  @override
  String get accountSignInAgain => 'Sign in again';

  @override
  String get accountChooseAction => 'Choose how to continue';

  @override
  String get accountChangedTitle => 'Different Google account';

  @override
  String get accountChangedBody =>
      'This device was last synced with another Google account. Choose what should happen to the songs and setlists on this device.';

  @override
  String get accountChangedMerge => 'Merge into the new account';

  @override
  String get accountChangedMergeHint =>
      'Keep everything on this device and add it to the new account.';

  @override
  String get accountChangedReplace => 'Replace with the new account\'s library';

  @override
  String get accountChangedReplaceHint =>
      'Songs on this device that are not in the new account are removed.';

  @override
  String get accountChangedSignOut => 'Cancel and sign out';

  @override
  String get accountStatusSignedOut => 'Account and sync: not signed in';

  @override
  String get accountStatusSignedIn => 'Account and sync: signed in';

  @override
  String get accountStatusSyncing => 'Account and sync: syncing';

  @override
  String get accountStatusSynced => 'Account and sync: library up to date';

  @override
  String get accountStatusError => 'Account and sync: problem, tap to review';

  @override
  String get accountNoticeConflicts =>
      'Some songs were edited in two places. Copies were kept.';

  @override
  String get accountNoticeSignedIn => 'Signed in.';

  @override
  String get accountNoticeSignedOut =>
      'Signed out. Your songs stay on this device.';

  @override
  String get syncErrorNotConfigured => 'Sync isn\'t set up in this build.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Use a Singbook build with Google sign-in configured.';

  @override
  String get syncErrorNotSignedIn => 'You\'re not signed in.';

  @override
  String get syncErrorNotSignedInHint => 'Sign in to sync your library.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google needs you to sign in again.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Sign in again to continue syncing. Your songs are safe on this device.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook doesn\'t have permission to use Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Sign in again and allow access to Drive when asked.';

  @override
  String get syncErrorRateLimited => 'Google is limiting requests for now.';

  @override
  String get syncErrorRateLimitedHint => 'Wait a few minutes, then try again.';

  @override
  String get syncErrorStorageFull => 'Your Google Drive is full.';

  @override
  String get syncErrorStorageFullHint =>
      'Free up some Drive space, then try again.';

  @override
  String get syncErrorNetwork => 'Couldn\'t reach Google.';

  @override
  String get syncErrorNetworkHint =>
      'Check your internet connection and try again.';

  @override
  String get syncErrorAccountChanged => 'A different Google account was used.';

  @override
  String get syncErrorAccountChangedHint =>
      'Choose whether to merge this device\'s library into it or replace it.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Your synced library is larger than Singbook can handle.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Remove some songs or setlists from the synced library, then try again.';

  @override
  String get syncErrorSignInFailed => 'Sign-in didn\'t finish.';

  @override
  String get syncErrorSignInFailedHint => 'Try signing in again.';

  @override
  String get syncErrorGeneric => 'Couldn\'t sync your library.';

  @override
  String get syncErrorGenericHint =>
      'Try again in a moment. Your songs are still safe on this device.';

  @override
  String get editorDurationInvalid =>
      'Enter seconds or minutes and seconds, such as 3:45.';

  @override
  String get editorNumberInvalid => 'Enter a number.';

  @override
  String get accountReplaceConfirmTitle => 'Delete local songs?';

  @override
  String get accountReplaceConfirmBody =>
      'Songs and setlists on this device that are not in the new account will be permanently deleted. This can\'t be undone.';

  @override
  String get accountReplaceConfirmAction => 'Delete and replace';

  @override
  String get accountSuspiciousTitle => 'Items missing from Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items that this device synced earlier are missing from Google Drive.',
      one:
          '$count item that this device synced earlier is missing from Google Drive.',
    );
    return '$_temp0 This can happen if app data was cleared in Google settings. Nothing has been deleted yet.';
  }

  @override
  String get accountSuspiciousDelete => 'Delete them here too';

  @override
  String get accountSuspiciousKeep => 'Keep my songs and upload them again';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items from this device?',
      one: 'Delete $count item from this device?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'These songs and setlists will be permanently deleted from this device. This can\'t be undone.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Delete from this device';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Items are missing from Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Nothing was deleted. Choose whether to delete them here too or upload them again.';

  @override
  String get syncErrorRemoteChanged => 'Google Drive changed while syncing.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Nothing was lost. Sync again to pick up the latest changes.';

  @override
  String get syncErrorInvalidLocalData =>
      'Some data on this device couldn\'t be synced.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'A song or setlist could not be read. Import or recreate it, then sync again.';

  @override
  String get syncErrorNoAccountChange =>
      'There is no account change to resolve.';

  @override
  String get syncErrorNoAccountChangeHint => 'Sync again to continue.';

  @override
  String get accountSyncWarningTitle => 'Synced, but some files were skipped';

  @override
  String get accountSyncWarningBody =>
      'Some files couldn\'t be used and were left as they are. Everything else is up to date.';

  @override
  String get accountSyncWarningTooLarge =>
      'A file was too large to sync and was skipped. Everything else is up to date.';

  @override
  String get accountSyncWarningInvalid =>
      'A file couldn\'t be read and was skipped. Everything else is up to date.';

  @override
  String get accountNoticeSyncSkipped => 'Synced. Some files were skipped.';

  @override
  String get settingsExportPdfTooLarge =>
      'This PDF would be too large. Try fewer songs, or share it as text.';

  @override
  String get settingsTimingTooLarge =>
      'The timing data is too large (over 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'This backup lists the same song twice, so nothing was imported.';

  @override
  String get setlistSaveConflict =>
      'The setlist changed elsewhere. Your edits were saved as a separate copy.';

  @override
  String get sectionVerse => 'Verse';

  @override
  String get sectionChorus => 'Chorus';

  @override
  String get sectionBridge => 'Bridge';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pre-Chorus';

  @override
  String get sectionPostChorus => 'Post-Chorus';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Interlude';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Refrain';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Ending';

  @override
  String get youtubeConsentHint =>
      'Experimental. Make your cookie choice on Google\'s page to try lyrics lookup. No Google account sign-in. Your choice stays on this device.';

  @override
  String get youtubeConsentOpen => 'Review Google consent';

  @override
  String get youtubeConsentSaved => 'Consent saved';

  @override
  String get youtubeConsentClear => 'Clear consent';

  @override
  String get youtubeConsentInstructions =>
      'Complete Google\'s cookie choice and wait for YouTube Music to return. Then save this session and retry the song.';

  @override
  String get youtubeConsentError =>
      'Couldn\'t update Google\'s consent choice. Try again.';

  @override
  String get youtubeConsentBlocked =>
      'Only YouTube Music and Google\'s consent page can open here. Account sign-in is unavailable.';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ready versions',
      one: '1 ready version',
      zero: 'No ready versions',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unavailable versions',
      one: '1 unavailable version',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Jump to section';

  @override
  String get searchVersionDetails => 'Version details';

  @override
  String get searchSelectedRecording => 'Selected recording';

  @override
  String get searchVersionDuration => 'Version duration';

  @override
  String get searchSourceOptions => 'Source options';
}
