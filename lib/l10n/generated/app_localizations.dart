import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bg.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ga.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_lv.dart';
import 'app_localizations_mt.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_sl.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bg'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('et'),
    Locale('fi'),
    Locale('fr'),
    Locale('ga'),
    Locale('hi'),
    Locale('hr'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('lt'),
    Locale('lv'),
    Locale('mt'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sk'),
    Locale('sl'),
    Locale('sv'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Singbook'**
  String get appTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A calm place to find, organize, and sing from your song library.'**
  String get aboutDescription;

  /// No description provided for @aboutMadeForSinging.
  ///
  /// In en, this message translates to:
  /// **'Made for singing together'**
  String get aboutMadeForSinging;

  /// No description provided for @aboutDetails.
  ///
  /// In en, this message translates to:
  /// **'Search enabled providers, compare song versions, keep lyrics and chords together, and organize songs into setlists. Your library stays on your device; optional Google Drive sync uses your Google account. Searches go directly to enabled providers.'**
  String get aboutDetails;

  /// No description provided for @aboutSupport.
  ///
  /// In en, this message translates to:
  /// **'Support and feedback'**
  String get aboutSupport;

  /// No description provided for @menuTypeNewSong.
  ///
  /// In en, this message translates to:
  /// **'Type in a new song'**
  String get menuTypeNewSong;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get navSongs;

  /// No description provided for @navSetlists.
  ///
  /// In en, this message translates to:
  /// **'Setlists'**
  String get navSetlists;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navSettingsCompact.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettingsCompact;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get navBack;

  /// No description provided for @appExitBackAgain.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get appExitBackAgain;

  /// No description provided for @navClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get navClose;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get navMore;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get actionPrint;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get actionImport;

  /// No description provided for @actionExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get actionExport;

  /// No description provided for @actionExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get actionExpand;

  /// No description provided for @actionCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get actionCollapse;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get actionDuplicate;

  /// No description provided for @actionMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get actionMoveUp;

  /// No description provided for @actionMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get actionMoveDown;

  /// No description provided for @actionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get actionPrevious;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Song, artist or lyrics'**
  String get searchHint;

  /// No description provided for @searchCatalogHint.
  ///
  /// In en, this message translates to:
  /// **'Song or artist'**
  String get searchCatalogHint;

  /// No description provided for @searchChangeSong.
  ///
  /// In en, this message translates to:
  /// **'Change song'**
  String get searchChangeSong;

  /// No description provided for @searchSelectedPreview.
  ///
  /// In en, this message translates to:
  /// **'Selected preview'**
  String get searchSelectedPreview;

  /// No description provided for @searchSubmit.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchSubmit;

  /// No description provided for @searchFilters.
  ///
  /// In en, this message translates to:
  /// **'Search options'**
  String get searchFilters;

  /// No description provided for @searchFiltersShow.
  ///
  /// In en, this message translates to:
  /// **'Show search options'**
  String get searchFiltersShow;

  /// No description provided for @searchFiltersHide.
  ///
  /// In en, this message translates to:
  /// **'Hide search options'**
  String get searchFiltersHide;

  /// No description provided for @searchFilterArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get searchFilterArtist;

  /// No description provided for @searchFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Song title'**
  String get searchFilterTitle;

  /// No description provided for @searchFilterLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get searchFilterLyrics;

  /// No description provided for @searchFilterChords.
  ///
  /// In en, this message translates to:
  /// **'Has chords'**
  String get searchFilterChords;

  /// No description provided for @searchFilterTimed.
  ///
  /// In en, this message translates to:
  /// **'Timed lyrics'**
  String get searchFilterTimed;

  /// No description provided for @searchFilterLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get searchFilterLanguage;

  /// No description provided for @searchFilterAll.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get searchFilterAll;

  /// No description provided for @searchAutocompleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get searchAutocompleteLabel;

  /// No description provided for @searchResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{1 result} other{{count} results}}'**
  String searchResultCount(int count);

  /// No description provided for @searchEmptyQuery.
  ///
  /// In en, this message translates to:
  /// **'Enter a song, artist, or lyric to search.'**
  String get searchEmptyQuery;

  /// No description provided for @searchCatalogEmptyQuery.
  ///
  /// In en, this message translates to:
  /// **'Enter a song or artist to search.'**
  String get searchCatalogEmptyQuery;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No songs found. Try a different search.'**
  String get searchNoResults;

  /// No description provided for @searchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching songs…'**
  String get searchLoading;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search could not be completed.'**
  String get searchError;

  /// No description provided for @searchOnlineTab.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get searchOnlineTab;

  /// No description provided for @searchRecentTab.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get searchRecentTab;

  /// No description provided for @searchFavoritesTab.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get searchFavoritesTab;

  /// No description provided for @searchSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested match'**
  String get searchSuggested;

  /// No description provided for @searchAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Other matches'**
  String get searchAlternatives;

  /// No description provided for @searchCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare versions'**
  String get searchCompare;

  /// No description provided for @searchChooseVersion.
  ///
  /// In en, this message translates to:
  /// **'Choose this version'**
  String get searchChooseVersion;

  /// No description provided for @searchFullPreview.
  ///
  /// In en, this message translates to:
  /// **'Full preview'**
  String get searchFullPreview;

  /// No description provided for @searchArrangementNotes.
  ///
  /// In en, this message translates to:
  /// **'Arrangement notes'**
  String get searchArrangementNotes;

  /// No description provided for @searchOpenLyrics.
  ///
  /// In en, this message translates to:
  /// **'Open lyrics'**
  String get searchOpenLyrics;

  /// No description provided for @searchContributions.
  ///
  /// In en, this message translates to:
  /// **'Sources used'**
  String get searchContributions;

  /// No description provided for @searchVersionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking this version…'**
  String get searchVersionChecking;

  /// No description provided for @searchVersionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This version can’t be used. Choose another version.'**
  String get searchVersionUnavailable;

  /// No description provided for @searchPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No lyric preview available.'**
  String get searchPreviewUnavailable;

  /// No description provided for @searchSongMatch.
  ///
  /// In en, this message translates to:
  /// **'Song match'**
  String get searchSongMatch;

  /// No description provided for @searchRecordingMatch.
  ///
  /// In en, this message translates to:
  /// **'Recording match'**
  String get searchRecordingMatch;

  /// No description provided for @searchMatchUnverified.
  ///
  /// In en, this message translates to:
  /// **'Recording not verified'**
  String get searchMatchUnverified;

  /// No description provided for @searchMatchExact.
  ///
  /// In en, this message translates to:
  /// **'Exact recording match'**
  String get searchMatchExact;

  /// No description provided for @searchMatchPossible.
  ///
  /// In en, this message translates to:
  /// **'Possible match'**
  String get searchMatchPossible;

  /// No description provided for @searchAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get searchAvailability;

  /// No description provided for @searchLyricsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Lyrics available'**
  String get searchLyricsAvailable;

  /// No description provided for @searchLyricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Lyrics unavailable'**
  String get searchLyricsUnavailable;

  /// No description provided for @searchChordsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Chords available'**
  String get searchChordsAvailable;

  /// No description provided for @searchChordsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No chords'**
  String get searchChordsUnavailable;

  /// No description provided for @searchTimingAvailable.
  ///
  /// In en, this message translates to:
  /// **'Timing available'**
  String get searchTimingAvailable;

  /// No description provided for @searchTimingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No timing'**
  String get searchTimingUnavailable;

  /// No description provided for @searchDurationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Duration unknown'**
  String get searchDurationUnknown;

  /// No description provided for @searchRating.
  ///
  /// In en, this message translates to:
  /// **'Rating {rating}'**
  String searchRating(String rating);

  /// No description provided for @searchSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get searchSourceLabel;

  /// No description provided for @searchMetadata.
  ///
  /// In en, this message translates to:
  /// **'Song details'**
  String get searchMetadata;

  /// No description provided for @searchAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get searchAlbum;

  /// No description provided for @searchArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get searchArtist;

  /// No description provided for @searchYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get searchYear;

  /// No description provided for @searchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get searchLanguage;

  /// No description provided for @searchViewVersions.
  ///
  /// In en, this message translates to:
  /// **'View versions'**
  String get searchViewVersions;

  /// No description provided for @searchSaved.
  ///
  /// In en, this message translates to:
  /// **'Song saved to your library.'**
  String get searchSaved;

  /// No description provided for @searchSaveOpenLyrics.
  ///
  /// In en, this message translates to:
  /// **'Save & open lyrics'**
  String get searchSaveOpenLyrics;

  /// No description provided for @searchOtherResults.
  ///
  /// In en, this message translates to:
  /// **'Other results'**
  String get searchOtherResults;

  /// No description provided for @searchSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this song.'**
  String get searchSaveFailed;

  /// No description provided for @homeRecentSongs.
  ///
  /// In en, this message translates to:
  /// **'Recent songs'**
  String get homeRecentSongs;

  /// No description provided for @homeRecentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get homeRecentlyPlayed;

  /// No description provided for @homeFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get homeFavorites;

  /// No description provided for @homeHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get homeHistory;

  /// No description provided for @homeHistoryClear.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get homeHistoryClear;

  /// No description provided for @homeHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared.'**
  String get homeHistoryCleared;

  /// No description provided for @homeHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Songs you open will appear here.'**
  String get homeHistoryEmpty;

  /// No description provided for @homeFavoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your favorite songs and setlists will appear here.'**
  String get homeFavoritesEmpty;

  /// No description provided for @homeItemsShownCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 items shown} =1{1 item shown} other{{count} items shown}}'**
  String homeItemsShownCount(int count);

  /// No description provided for @homeRecentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your recent songs and setlists will appear here.'**
  String get homeRecentEmpty;

  /// No description provided for @homeTimelineLabel.
  ///
  /// In en, this message translates to:
  /// **'History timeline'**
  String get homeTimelineLabel;

  /// No description provided for @homeTimelineDate.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String homeTimelineDate(String date);

  /// No description provided for @homeAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Full history'**
  String get homeAllHistory;

  /// No description provided for @homeShowFavorites.
  ///
  /// In en, this message translates to:
  /// **'Show favorites'**
  String get homeShowFavorites;

  /// No description provided for @homeShowRecent.
  ///
  /// In en, this message translates to:
  /// **'Show recent'**
  String get homeShowRecent;

  /// No description provided for @songsTitle.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songsTitle;

  /// No description provided for @songsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your songs will appear here.'**
  String get songsEmpty;

  /// No description provided for @songsEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No songs match your search.'**
  String get songsEmptySearch;

  /// No description provided for @songsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add song'**
  String get songsAdd;

  /// No description provided for @songsSortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Sort alphabetically'**
  String get songsSortAlphabetical;

  /// No description provided for @songsAlphabetNavigation.
  ///
  /// In en, this message translates to:
  /// **'Song index'**
  String get songsAlphabetNavigation;

  /// No description provided for @songsUsageCount.
  ///
  /// In en, this message translates to:
  /// **'Opened {count, plural, =0{never} =1{once} other{{count} times}}'**
  String songsUsageCount(int count);

  /// No description provided for @songFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get songFavoriteAdd;

  /// No description provided for @songFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get songFavoriteRemove;

  /// No description provided for @songMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Song actions'**
  String get songMenuLabel;

  /// No description provided for @songInfo.
  ///
  /// In en, this message translates to:
  /// **'Song details'**
  String get songInfo;

  /// No description provided for @setlistMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Setlist actions'**
  String get setlistMenuLabel;

  /// No description provided for @songAddToSetlist.
  ///
  /// In en, this message translates to:
  /// **'Add to setlist'**
  String get songAddToSetlist;

  /// No description provided for @songCopyChordPro.
  ///
  /// In en, this message translates to:
  /// **'Copy ChordPro'**
  String get songCopyChordPro;

  /// No description provided for @songDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete song?'**
  String get songDeleteConfirmTitle;

  /// No description provided for @songDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This song will be removed from your library.'**
  String get songDeleteConfirmMessage;

  /// No description provided for @songDeleted.
  ///
  /// In en, this message translates to:
  /// **'Song deleted.'**
  String get songDeleted;

  /// No description provided for @setlistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Setlists'**
  String get setlistsTitle;

  /// No description provided for @setlistsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create a setlist for your next rehearsal or performance.'**
  String get setlistsEmpty;

  /// No description provided for @setlistsEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No setlists match your search.'**
  String get setlistsEmptySearch;

  /// No description provided for @setlistCreate.
  ///
  /// In en, this message translates to:
  /// **'New setlist'**
  String get setlistCreate;

  /// No description provided for @setlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Setlist name'**
  String get setlistNameHint;

  /// No description provided for @setlistNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get setlistNotes;

  /// No description provided for @setlistEntryOverride.
  ///
  /// In en, this message translates to:
  /// **'Song-specific key and capo'**
  String get setlistEntryOverride;

  /// No description provided for @setlistSongsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs} =1{1 song} other{{count} songs}}'**
  String setlistSongsCount(int count);

  /// No description provided for @setlistDuration.
  ///
  /// In en, this message translates to:
  /// **'{duration}'**
  String setlistDuration(String duration);

  /// No description provided for @setlistDurationPartial.
  ///
  /// In en, this message translates to:
  /// **'At least {duration}'**
  String setlistDurationPartial(String duration);

  /// No description provided for @setlistDurationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Duration unknown'**
  String get setlistDurationUnknown;

  /// No description provided for @setlistActivity.
  ///
  /// In en, this message translates to:
  /// **'Last activity {date}'**
  String setlistActivity(String date);

  /// No description provided for @setlistActivityCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String setlistActivityCreated(String date);

  /// No description provided for @setlistActivityEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited {date}'**
  String setlistActivityEdited(String date);

  /// No description provided for @setlistActivityUsed.
  ///
  /// In en, this message translates to:
  /// **'Last played {date}'**
  String setlistActivityUsed(String date);

  /// No description provided for @setlistSongsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This setlist has no songs yet.'**
  String get setlistSongsEmpty;

  /// No description provided for @setlistAddSongs.
  ///
  /// In en, this message translates to:
  /// **'Add songs'**
  String get setlistAddSongs;

  /// No description provided for @setlistReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder songs'**
  String get setlistReorder;

  /// No description provided for @setlistMoveSongUp.
  ///
  /// In en, this message translates to:
  /// **'Move {song} up'**
  String setlistMoveSongUp(String song);

  /// No description provided for @setlistMoveSongDown.
  ///
  /// In en, this message translates to:
  /// **'Move {song} down'**
  String setlistMoveSongDown(String song);

  /// No description provided for @setlistRemoveSong.
  ///
  /// In en, this message translates to:
  /// **'Remove {song} from setlist'**
  String setlistRemoveSong(String song);

  /// No description provided for @setlistDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate setlist'**
  String get setlistDuplicate;

  /// No description provided for @setlistFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Favorite setlist'**
  String get setlistFavoriteAdd;

  /// No description provided for @setlistFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove setlist from favorites'**
  String get setlistFavoriteRemove;

  /// No description provided for @setlistShare.
  ///
  /// In en, this message translates to:
  /// **'Share as setlist file'**
  String get setlistShare;

  /// No description provided for @setlistSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share as PDF'**
  String get setlistSharePdf;

  /// No description provided for @setlistPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get setlistPrint;

  /// No description provided for @setlistDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete setlist?'**
  String get setlistDeleteConfirmTitle;

  /// No description provided for @setlistDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The setlist will be removed. Songs in your library will stay.'**
  String get setlistDeleteConfirmMessage;

  /// No description provided for @setlistDeleted.
  ///
  /// In en, this message translates to:
  /// **'Setlist deleted.'**
  String get setlistDeleted;

  /// No description provided for @readerTitle.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get readerTitle;

  /// No description provided for @readerNoLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics have not been added yet.'**
  String get readerNoLyrics;

  /// No description provided for @readerShowChords.
  ///
  /// In en, this message translates to:
  /// **'Show chords'**
  String get readerShowChords;

  /// No description provided for @readerHideChords.
  ///
  /// In en, this message translates to:
  /// **'Hide chords'**
  String get readerHideChords;

  /// No description provided for @readerTranspose.
  ///
  /// In en, this message translates to:
  /// **'Transpose chords'**
  String get readerTranspose;

  /// No description provided for @readerTransposeSemitones.
  ///
  /// In en, this message translates to:
  /// **'Transpose by {count, plural, =0{0 semitones} =1{1 semitone} other{{count} semitones}}'**
  String readerTransposeSemitones(int count);

  /// No description provided for @readerSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get readerSaved;

  /// No description provided for @readerEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit lyrics and details'**
  String get readerEdit;

  /// No description provided for @playerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @playerResume.
  ///
  /// In en, this message translates to:
  /// **'Resume lyric scrolling'**
  String get playerResume;

  /// No description provided for @playerSeek.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get playerSeek;

  /// No description provided for @playerElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed time {time}'**
  String playerElapsed(String time);

  /// No description provided for @playerRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining {time}'**
  String playerRemaining(String time);

  /// No description provided for @playerTimingMode.
  ///
  /// In en, this message translates to:
  /// **'Scrolling mode'**
  String get playerTimingMode;

  /// No description provided for @playerTimedLyrics.
  ///
  /// In en, this message translates to:
  /// **'Timed lyrics'**
  String get playerTimedLyrics;

  /// No description provided for @playerStartScroll.
  ///
  /// In en, this message translates to:
  /// **'Start auto-scroll'**
  String get playerStartScroll;

  /// No description provided for @playerEstimatedPace.
  ///
  /// In en, this message translates to:
  /// **'Estimated pace'**
  String get playerEstimatedPace;

  /// No description provided for @playerScrollSpeed.
  ///
  /// In en, this message translates to:
  /// **'Scroll speed'**
  String get playerScrollSpeed;

  /// No description provided for @playerEstimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated {time}'**
  String playerEstimatedDuration(String time);

  /// No description provided for @playerLyricsOnly.
  ///
  /// In en, this message translates to:
  /// **'Lyric scrolling · no audio'**
  String get playerLyricsOnly;

  /// No description provided for @playerManualScroll.
  ///
  /// In en, this message translates to:
  /// **'Manual scroll'**
  String get playerManualScroll;

  /// No description provided for @playerTimingStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Lyrics will follow the available timing.'**
  String get playerTimingStatusReady;

  /// No description provided for @playerTimingStatusEstimated.
  ///
  /// In en, this message translates to:
  /// **'Scrolling pace is estimated from song length.'**
  String get playerTimingStatusEstimated;

  /// No description provided for @playerTimingStatusManual.
  ///
  /// In en, this message translates to:
  /// **'Scroll the lyrics yourself.'**
  String get playerTimingStatusManual;

  /// No description provided for @playerTimingStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Timed scrolling is unavailable for this song.'**
  String get playerTimingStatusUnavailable;

  /// No description provided for @playerDurationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Add a song duration to use estimated scrolling.'**
  String get playerDurationUnknown;

  /// No description provided for @playerProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Song progress'**
  String get playerProgressLabel;

  /// No description provided for @playerCurrentSection.
  ///
  /// In en, this message translates to:
  /// **'Current section'**
  String get playerCurrentSection;

  /// No description provided for @playerPreviousSection.
  ///
  /// In en, this message translates to:
  /// **'Previous section'**
  String get playerPreviousSection;

  /// No description provided for @playerNextSection.
  ///
  /// In en, this message translates to:
  /// **'Next section'**
  String get playerNextSection;

  /// No description provided for @playerPreviousSectionSong.
  ///
  /// In en, this message translates to:
  /// **'Previous section · hold for previous setlist song'**
  String get playerPreviousSectionSong;

  /// No description provided for @playerNextSectionSong.
  ///
  /// In en, this message translates to:
  /// **'Next section · hold for next setlist song'**
  String get playerNextSectionSong;

  /// No description provided for @playerPreviousSong.
  ///
  /// In en, this message translates to:
  /// **'Previous song'**
  String get playerPreviousSong;

  /// No description provided for @playerNextSong.
  ///
  /// In en, this message translates to:
  /// **'Next song'**
  String get playerNextSong;

  /// No description provided for @editorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit song'**
  String get editorTitle;

  /// No description provided for @editorTitleField.
  ///
  /// In en, this message translates to:
  /// **'Song title'**
  String get editorTitleField;

  /// No description provided for @editorArtistField.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get editorArtistField;

  /// No description provided for @editorAlbumField.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get editorAlbumField;

  /// No description provided for @editorLyricsField.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get editorLyricsField;

  /// No description provided for @editorChordsField.
  ///
  /// In en, this message translates to:
  /// **'Chords'**
  String get editorChordsField;

  /// No description provided for @editorKeyField.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get editorKeyField;

  /// No description provided for @editorCapoField.
  ///
  /// In en, this message translates to:
  /// **'Capo'**
  String get editorCapoField;

  /// No description provided for @editorTuningField.
  ///
  /// In en, this message translates to:
  /// **'Tuning'**
  String get editorTuningField;

  /// No description provided for @editorTempoField.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get editorTempoField;

  /// No description provided for @editorDurationField.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get editorDurationField;

  /// No description provided for @editorTimeSignatureField.
  ///
  /// In en, this message translates to:
  /// **'Time signature'**
  String get editorTimeSignatureField;

  /// No description provided for @editorLanguageField.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get editorLanguageField;

  /// No description provided for @editorYearField.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get editorYearField;

  /// No description provided for @editorComposerField.
  ///
  /// In en, this message translates to:
  /// **'Composer'**
  String get editorComposerField;

  /// No description provided for @editorLyricistField.
  ///
  /// In en, this message translates to:
  /// **'Lyricist'**
  String get editorLyricistField;

  /// No description provided for @editorCopyrightField.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get editorCopyrightField;

  /// No description provided for @editorLicenseField.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get editorLicenseField;

  /// No description provided for @songInfoSources.
  ///
  /// In en, this message translates to:
  /// **'Sources and credits'**
  String get songInfoSources;

  /// No description provided for @searchMatchSameSong.
  ///
  /// In en, this message translates to:
  /// **'Same song; recording not confirmed'**
  String get searchMatchSameSong;

  /// No description provided for @searchMatchNeedsAgreement.
  ///
  /// In en, this message translates to:
  /// **'Chart needs lyric confirmation'**
  String get searchMatchNeedsAgreement;

  /// No description provided for @searchMatchDifferentLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics differ from the selected song'**
  String get searchMatchDifferentLyrics;

  /// No description provided for @searchMatchCombinedSources.
  ///
  /// In en, this message translates to:
  /// **'Details combined from multiple sources'**
  String get searchMatchCombinedSources;

  /// No description provided for @searchCombinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Combined'**
  String get searchCombinedLabel;

  /// No description provided for @searchSongMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 song matches} =1{1 song match} other{{count} song matches}}'**
  String searchSongMatchCount(int count);

  /// No description provided for @searchSourceVersionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 source versions} =1{1 source version} other{{count} source versions}}'**
  String searchSourceVersionsCount(int count);

  /// No description provided for @searchMatchBestAvailable.
  ///
  /// In en, this message translates to:
  /// **'Best available match'**
  String get searchMatchBestAvailable;

  /// No description provided for @providerDescriptionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Song source'**
  String get providerDescriptionUnknown;

  /// No description provided for @providerDescDownloadChordProThenImport.
  ///
  /// In en, this message translates to:
  /// **'Download a ChordPro file from the source, then import it.'**
  String get providerDescDownloadChordProThenImport;

  /// No description provided for @providerDescFreeAccountDownloadThenImport.
  ///
  /// In en, this message translates to:
  /// **'Download with a free account, then import the file.'**
  String get providerDescFreeAccountDownloadThenImport;

  /// No description provided for @providerDescPublicChordSheets.
  ///
  /// In en, this message translates to:
  /// **'Public chord sheets.'**
  String get providerDescPublicChordSheets;

  /// No description provided for @providerDescHistoricalTextPerWorkLicense.
  ///
  /// In en, this message translates to:
  /// **'Historical lyrics licensed by work.'**
  String get providerDescHistoricalTextPerWorkLicense;

  /// No description provided for @providerDescLicensedCatalog.
  ///
  /// In en, this message translates to:
  /// **'Licensed lyric catalog.'**
  String get providerDescLicensedCatalog;

  /// No description provided for @providerDescOriginalSongsCcBy.
  ///
  /// In en, this message translates to:
  /// **'Original songs under Creative Commons BY.'**
  String get providerDescOriginalSongsCcBy;

  /// No description provided for @providerDescPerSongLicense.
  ///
  /// In en, this message translates to:
  /// **'Lyrics licensed per song.'**
  String get providerDescPerSongLicense;

  /// No description provided for @providerDescRecordingMetadataOnly.
  ///
  /// In en, this message translates to:
  /// **'Recording and release details only.'**
  String get providerDescRecordingMetadataOnly;

  /// No description provided for @providerDescCompositionMetadataOnly.
  ///
  /// In en, this message translates to:
  /// **'Composition details only.'**
  String get providerDescCompositionMetadataOnly;

  /// No description provided for @providerDescExactFileArtworkOnly.
  ///
  /// In en, this message translates to:
  /// **'Artwork for exact recording matches only.'**
  String get providerDescExactFileArtworkOnly;

  /// No description provided for @providerCapabilityLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get providerCapabilityLyrics;

  /// No description provided for @providerCapabilityChords.
  ///
  /// In en, this message translates to:
  /// **'Chords'**
  String get providerCapabilityChords;

  /// No description provided for @providerCapabilityTiming.
  ///
  /// In en, this message translates to:
  /// **'Timed lyrics'**
  String get providerCapabilityTiming;

  /// No description provided for @providerCapabilitySearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get providerCapabilitySearch;

  /// No description provided for @providerCapabilityMetadata.
  ///
  /// In en, this message translates to:
  /// **'Song details'**
  String get providerCapabilityMetadata;

  /// No description provided for @editorArtworkField.
  ///
  /// In en, this message translates to:
  /// **'Artwork link'**
  String get editorArtworkField;

  /// No description provided for @editorLyricsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a line to edit lyrics or chords.'**
  String get editorLyricsHint;

  /// No description provided for @editorSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editorSave;

  /// No description provided for @editorSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get editorSaved;

  /// No description provided for @editorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes.'**
  String get editorSaveFailed;

  /// No description provided for @editorSaveConflict.
  ///
  /// In en, this message translates to:
  /// **'The song changed elsewhere. Your edits were saved as a separate copy.'**
  String get editorSaveConflict;

  /// No description provided for @editorUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editorUnsavedTitle;

  /// No description provided for @editorUnsavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your edits have not been saved.'**
  String get editorUnsavedMessage;

  /// No description provided for @editorFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a song title.'**
  String get editorFieldRequired;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Use device setting'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsColorPalette.
  ///
  /// In en, this message translates to:
  /// **'Color palette'**
  String get settingsColorPalette;

  /// No description provided for @settingsFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settingsFont;

  /// No description provided for @settingsTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSize;

  /// No description provided for @settingsLyricsPreview.
  ///
  /// In en, this message translates to:
  /// **'Lyrics preview'**
  String get settingsLyricsPreview;

  /// No description provided for @settingsPlayer.
  ///
  /// In en, this message translates to:
  /// **'Lyrics player'**
  String get settingsPlayer;

  /// No description provided for @settingsDefaultShowChords.
  ///
  /// In en, this message translates to:
  /// **'Show chords by default'**
  String get settingsDefaultShowChords;

  /// No description provided for @settingsDefaultAutoscroll.
  ///
  /// In en, this message translates to:
  /// **'Start lyric scrolling automatically'**
  String get settingsDefaultAutoscroll;

  /// No description provided for @settingsDefaultTiming.
  ///
  /// In en, this message translates to:
  /// **'Default scrolling mode'**
  String get settingsDefaultTiming;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageBulgarian.
  ///
  /// In en, this message translates to:
  /// **'Български'**
  String get settingsLanguageBulgarian;

  /// No description provided for @settingsLanguageUkrainian.
  ///
  /// In en, this message translates to:
  /// **'Українська'**
  String get settingsLanguageUkrainian;

  /// No description provided for @settingsSources.
  ///
  /// In en, this message translates to:
  /// **'Lyrics sources'**
  String get settingsSources;

  /// No description provided for @settingsSourceEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable source {source}'**
  String settingsSourceEnabled(String source);

  /// No description provided for @settingsSourceRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh source list'**
  String get settingsSourceRefresh;

  /// No description provided for @settingsSourcesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Sources updated.'**
  String get settingsSourcesUpdated;

  /// No description provided for @settingsSourcesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh sources.'**
  String get settingsSourcesUpdateFailed;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import songs'**
  String get settingsImport;

  /// No description provided for @settingsImportChordPro.
  ///
  /// In en, this message translates to:
  /// **'Import ChordPro file'**
  String get settingsImportChordPro;

  /// No description provided for @settingsImportSetlist.
  ///
  /// In en, this message translates to:
  /// **'Import setlist file'**
  String get settingsImportSetlist;

  /// No description provided for @settingsImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import complete.'**
  String get settingsImportSuccess;

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import this file.'**
  String get settingsImportFailed;

  /// No description provided for @settingsImportUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported.'**
  String get settingsImportUnsupported;

  /// No description provided for @settingsShareSong.
  ///
  /// In en, this message translates to:
  /// **'Share as ChordPro'**
  String get settingsShareSong;

  /// No description provided for @settingsSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share as PDF'**
  String get settingsSharePdf;

  /// No description provided for @settingsCopySong.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get settingsCopySong;

  /// No description provided for @settingsPrintSong.
  ///
  /// In en, this message translates to:
  /// **'Print only'**
  String get settingsPrintSong;

  /// No description provided for @settingsPrintSetlist.
  ///
  /// In en, this message translates to:
  /// **'Print setlist with lyrics'**
  String get settingsPrintSetlist;

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare the file.'**
  String get settingsExportFailed;

  /// No description provided for @settingsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard.'**
  String get settingsCopied;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsLegal;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get settingsClearHistory;

  /// No description provided for @settingsClearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear your song and setlist history?'**
  String get settingsClearHistoryConfirm;

  /// No description provided for @settingsHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared.'**
  String get settingsHistoryCleared;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account and sync'**
  String get accountTitle;

  /// No description provided for @accountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sync needs a build of Singbook with Google sign-in configured. This build keeps your songs on this device only.'**
  String get accountUnavailable;

  /// No description provided for @accountSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get accountSyncNow;

  /// No description provided for @accountConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected. Choose Sync now to update your backup.'**
  String get accountConnected;

  /// No description provided for @accountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Connect account'**
  String get accountSignIn;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountChange.
  ///
  /// In en, this message translates to:
  /// **'Change account'**
  String get accountChange;

  /// No description provided for @accountSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get accountSignedOut;

  /// No description provided for @accountSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing your library…'**
  String get accountSyncing;

  /// No description provided for @accountSynced.
  ///
  /// In en, this message translates to:
  /// **'Library synced.'**
  String get accountSynced;

  /// No description provided for @accountSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync your library.'**
  String get accountSyncFailed;

  /// No description provided for @accessibilityFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get accessibilityFavorite;

  /// No description provided for @accessibilityNotFavorite.
  ///
  /// In en, this message translates to:
  /// **'Not a favorite'**
  String get accessibilityNotFavorite;

  /// No description provided for @accessibilitySearchField.
  ///
  /// In en, this message translates to:
  /// **'Search songs'**
  String get accessibilitySearchField;

  /// No description provided for @accessibilityClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search text'**
  String get accessibilityClearSearch;

  /// No description provided for @accessibilitySongMenu.
  ///
  /// In en, this message translates to:
  /// **'Actions for {song}'**
  String accessibilitySongMenu(String song);

  /// No description provided for @accessibilitySetlistMenu.
  ///
  /// In en, this message translates to:
  /// **'Actions for {setlist}'**
  String accessibilitySetlistMenu(String setlist);

  /// No description provided for @accessibilityExpandSetlist.
  ///
  /// In en, this message translates to:
  /// **'Expand songs in {setlist}'**
  String accessibilityExpandSetlist(String setlist);

  /// No description provided for @accessibilityCollapseSetlist.
  ///
  /// In en, this message translates to:
  /// **'Collapse songs in {setlist}'**
  String accessibilityCollapseSetlist(String setlist);

  /// No description provided for @accessibilityPlaybackProgress.
  ///
  /// In en, this message translates to:
  /// **'Playback progress, {percent} percent'**
  String accessibilityPlaybackProgress(int percent);

  /// No description provided for @accessibilityTimeline.
  ///
  /// In en, this message translates to:
  /// **'History timeline, {date}'**
  String accessibilityTimeline(String date);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @loadingSongs.
  ///
  /// In en, this message translates to:
  /// **'Loading songs…'**
  String get loadingSongs;

  /// No description provided for @loadingSetlists.
  ///
  /// In en, this message translates to:
  /// **'Loading setlists…'**
  String get loadingSetlists;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline.'**
  String get errorOffline;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission is needed to continue.'**
  String get errorPermission;

  /// No description provided for @emptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No items match these filters.'**
  String get emptyFiltered;

  /// No description provided for @unknownValue.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownValue;

  /// No description provided for @durationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Duration unknown'**
  String get durationUnknown;

  /// No description provided for @metadataNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get metadataNotSet;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @daySongCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No songs} =1{1 song} other{{count} songs}}'**
  String daySongCount(int count);

  /// No description provided for @settingsPaletteNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get settingsPaletteNavy;

  /// No description provided for @settingsPaletteSage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get settingsPaletteSage;

  /// No description provided for @settingsPaletteOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get settingsPaletteOcean;

  /// No description provided for @settingsPaletteClay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get settingsPaletteClay;

  /// No description provided for @settingsPalettePlum.
  ///
  /// In en, this message translates to:
  /// **'Plum'**
  String get settingsPalettePlum;

  /// No description provided for @settingsFontSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsFontSystem;

  /// No description provided for @settingsFontSerif.
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get settingsFontSerif;

  /// No description provided for @settingsFontMonospace.
  ///
  /// In en, this message translates to:
  /// **'Monospace'**
  String get settingsFontMonospace;

  /// No description provided for @settingsLyricsPreviewExample.
  ///
  /// In en, this message translates to:
  /// **'When the morning comes, we will sing again.'**
  String get settingsLyricsPreviewExample;

  /// No description provided for @searchDiscoveryProgress.
  ///
  /// In en, this message translates to:
  /// **'Checking lyrics sources: {checked} of {total} complete.'**
  String searchDiscoveryProgress(int checked, int total);

  /// No description provided for @searchDiscoveryNoLyrics.
  ///
  /// In en, this message translates to:
  /// **'No usable lyrics found.'**
  String get searchDiscoveryNoLyrics;

  /// No description provided for @searchDiscoveryNoLyricsDetails.
  ///
  /// In en, this message translates to:
  /// **'The selected song was checked against the enabled sources, but none returned a usable lyric version.'**
  String get searchDiscoveryNoLyricsDetails;

  /// No description provided for @searchDiscoveryError.
  ///
  /// In en, this message translates to:
  /// **'Lyrics sources could not be checked.'**
  String get searchDiscoveryError;

  /// No description provided for @searchDiscoveryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry lyrics search'**
  String get searchDiscoveryRetry;

  /// No description provided for @searchSourcesUnavailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 sources unavailable} =1{1 source unavailable} other{{count} sources unavailable}}'**
  String searchSourcesUnavailableCount(int count);

  /// No description provided for @searchErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get searchErrorDetails;

  /// No description provided for @searchProviderChecks.
  ///
  /// In en, this message translates to:
  /// **'Source checks'**
  String get searchProviderChecks;

  /// No description provided for @searchProviderPending.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get searchProviderPending;

  /// No description provided for @searchProviderFound.
  ///
  /// In en, this message translates to:
  /// **'Match found'**
  String get searchProviderFound;

  /// No description provided for @searchProviderRejected.
  ///
  /// In en, this message translates to:
  /// **'Does not match'**
  String get searchProviderRejected;

  /// No description provided for @searchProviderFailed.
  ///
  /// In en, this message translates to:
  /// **'Check failed'**
  String get searchProviderFailed;

  /// No description provided for @searchProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No usable lyrics'**
  String get searchProviderUnavailable;

  /// No description provided for @searchCatalogFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Select a song to filter lyric versions by chords, timing, or language.'**
  String get searchCatalogFilterHint;

  /// No description provided for @startupErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library could not be opened.'**
  String get startupErrorTitle;

  /// No description provided for @setlistCopyName.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String setlistCopyName(String name);

  /// No description provided for @setlistSongMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing song'**
  String get setlistSongMissing;

  /// No description provided for @settingsImportTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is too large to import.'**
  String get settingsImportTooLarge;

  /// No description provided for @songsJumpToLetter.
  ///
  /// In en, this message translates to:
  /// **'Jump to {letter}'**
  String songsJumpToLetter(String letter);

  /// No description provided for @actionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionDiscard;

  /// No description provided for @editorKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get editorKeepEditing;

  /// No description provided for @settingsDefaultShowChordsHint.
  ///
  /// In en, this message translates to:
  /// **'Show chords above the lyrics when a song has them.'**
  String get settingsDefaultShowChordsHint;

  /// No description provided for @settingsDefaultAutoscrollHint.
  ///
  /// In en, this message translates to:
  /// **'Lyrics scroll with the song. Not used in manual scroll mode.'**
  String get settingsDefaultAutoscrollHint;

  /// No description provided for @accountUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync is not set up'**
  String get accountUnavailableTitle;

  /// No description provided for @accountSignedOutBenefits.
  ///
  /// In en, this message translates to:
  /// **'Connecting Google Drive syncs your library. Song changes then sync automatically.'**
  String get accountSignedOutBenefits;

  /// No description provided for @accountManualSyncHint.
  ///
  /// In en, this message translates to:
  /// **'You can also tap Sync now to sync your library.'**
  String get accountManualSyncHint;

  /// No description provided for @accountSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get accountSignInWithGoogle;

  /// No description provided for @accountWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get accountWorking;

  /// No description provided for @accountNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get accountNeverSynced;

  /// No description provided for @accountSyncedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Synced just now'**
  String get accountSyncedJustNow;

  /// No description provided for @accountSyncedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Synced 1 minute ago} other{Synced {count} minutes ago}}'**
  String accountSyncedMinutesAgo(int count);

  /// No description provided for @accountSyncedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Synced 1 hour ago} other{Synced {count} hours ago}}'**
  String accountSyncedHoursAgo(int count);

  /// No description provided for @accountSyncedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Synced 1 day ago} other{Synced {count} days ago}}'**
  String accountSyncedDaysAgo(int count);

  /// No description provided for @accountConflictsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 conflicting edit kept as a copy} other{{count} conflicting edits kept as copies}}'**
  String accountConflictsTitle(int count);

  /// No description provided for @accountConflictsBody.
  ///
  /// In en, this message translates to:
  /// **'The same song or setlist was edited in two places. Nothing was lost: the other version was saved as a separate copy.'**
  String get accountConflictsBody;

  /// No description provided for @accountReviewConflicts.
  ///
  /// In en, this message translates to:
  /// **'Review copies'**
  String get accountReviewConflicts;

  /// No description provided for @songsConflictFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Showing conflict copies only'**
  String get songsConflictFilterActive;

  /// No description provided for @songsConflictFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Show all songs'**
  String get songsConflictFilterClear;

  /// No description provided for @songsConflictBadge.
  ///
  /// In en, this message translates to:
  /// **'Conflict copy'**
  String get songsConflictBadge;

  /// No description provided for @songsConflictEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conflict copies.'**
  String get songsConflictEmpty;

  /// No description provided for @accountAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Sync automatically'**
  String get accountAutoSync;

  /// No description provided for @accountAutoSyncHint.
  ///
  /// In en, this message translates to:
  /// **'Sync after connecting and after adding, editing or removing a song.'**
  String get accountAutoSyncHint;

  /// No description provided for @accountSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this account?'**
  String get accountSignOutTitle;

  /// No description provided for @accountSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your songs and setlists stay on this device. They won\'t be backed up or synced until you sign in again.'**
  String get accountSignOutBody;

  /// No description provided for @accountUseDifferent.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get accountUseDifferent;

  /// No description provided for @accountSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get accountSignInAgain;

  /// No description provided for @accountChooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose how to continue'**
  String get accountChooseAction;

  /// No description provided for @accountChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Different Google account'**
  String get accountChangedTitle;

  /// No description provided for @accountChangedBody.
  ///
  /// In en, this message translates to:
  /// **'This device was last synced with another Google account. Choose what should happen to the songs and setlists on this device.'**
  String get accountChangedBody;

  /// No description provided for @accountChangedMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge into the new account'**
  String get accountChangedMerge;

  /// No description provided for @accountChangedMergeHint.
  ///
  /// In en, this message translates to:
  /// **'Keep everything on this device and add it to the new account.'**
  String get accountChangedMergeHint;

  /// No description provided for @accountChangedReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace with the new account\'s library'**
  String get accountChangedReplace;

  /// No description provided for @accountChangedReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'Songs on this device that are not in the new account are removed.'**
  String get accountChangedReplaceHint;

  /// No description provided for @accountChangedSignOut.
  ///
  /// In en, this message translates to:
  /// **'Cancel and sign out'**
  String get accountChangedSignOut;

  /// No description provided for @accountStatusSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Account and sync: not signed in'**
  String get accountStatusSignedOut;

  /// No description provided for @accountStatusSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Account and sync: signed in'**
  String get accountStatusSignedIn;

  /// No description provided for @accountStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Account and sync: syncing'**
  String get accountStatusSyncing;

  /// No description provided for @accountStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Account and sync: library up to date'**
  String get accountStatusSynced;

  /// No description provided for @accountStatusError.
  ///
  /// In en, this message translates to:
  /// **'Account and sync: problem, tap to review'**
  String get accountStatusError;

  /// No description provided for @accountNoticeConflicts.
  ///
  /// In en, this message translates to:
  /// **'Some songs were edited in two places. Copies were kept.'**
  String get accountNoticeConflicts;

  /// No description provided for @accountNoticeSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in.'**
  String get accountNoticeSignedIn;

  /// No description provided for @accountNoticeSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out. Your songs stay on this device.'**
  String get accountNoticeSignedOut;

  /// No description provided for @syncErrorNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Sync isn\'t set up in this build.'**
  String get syncErrorNotConfigured;

  /// No description provided for @syncErrorNotConfiguredHint.
  ///
  /// In en, this message translates to:
  /// **'Use a Singbook build with Google sign-in configured.'**
  String get syncErrorNotConfiguredHint;

  /// No description provided for @syncErrorNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'You\'re not signed in.'**
  String get syncErrorNotSignedIn;

  /// No description provided for @syncErrorNotSignedInHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your library.'**
  String get syncErrorNotSignedInHint;

  /// No description provided for @syncErrorAuthorizationRequired.
  ///
  /// In en, this message translates to:
  /// **'Google needs you to sign in again.'**
  String get syncErrorAuthorizationRequired;

  /// No description provided for @syncErrorAuthorizationRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue syncing. Your songs are safe on this device.'**
  String get syncErrorAuthorizationRequiredHint;

  /// No description provided for @syncErrorAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Singbook doesn\'t have permission to use Google Drive.'**
  String get syncErrorAccessDenied;

  /// No description provided for @syncErrorAccessDeniedHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in again and allow access to Drive when asked.'**
  String get syncErrorAccessDeniedHint;

  /// No description provided for @syncErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Google is limiting requests for now.'**
  String get syncErrorRateLimited;

  /// No description provided for @syncErrorRateLimitedHint.
  ///
  /// In en, this message translates to:
  /// **'Wait a few minutes, then try again.'**
  String get syncErrorRateLimitedHint;

  /// No description provided for @syncErrorStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Your Google Drive is full.'**
  String get syncErrorStorageFull;

  /// No description provided for @syncErrorStorageFullHint.
  ///
  /// In en, this message translates to:
  /// **'Free up some Drive space, then try again.'**
  String get syncErrorStorageFullHint;

  /// No description provided for @syncErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach Google.'**
  String get syncErrorNetwork;

  /// No description provided for @syncErrorNetworkHint.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get syncErrorNetworkHint;

  /// No description provided for @syncErrorAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'A different Google account was used.'**
  String get syncErrorAccountChanged;

  /// No description provided for @syncErrorAccountChangedHint.
  ///
  /// In en, this message translates to:
  /// **'Choose whether to merge this device\'s library into it or replace it.'**
  String get syncErrorAccountChangedHint;

  /// No description provided for @syncErrorRemoteLibraryTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Your synced library is larger than Singbook can handle.'**
  String get syncErrorRemoteLibraryTooLarge;

  /// No description provided for @syncErrorRemoteLibraryTooLargeHint.
  ///
  /// In en, this message translates to:
  /// **'Remove some songs or setlists from the synced library, then try again.'**
  String get syncErrorRemoteLibraryTooLargeHint;

  /// No description provided for @syncErrorSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in didn\'t finish.'**
  String get syncErrorSignInFailed;

  /// No description provided for @syncErrorSignInFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Try signing in again.'**
  String get syncErrorSignInFailedHint;

  /// No description provided for @syncErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync your library.'**
  String get syncErrorGeneric;

  /// No description provided for @syncErrorGenericHint.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment. Your songs are still safe on this device.'**
  String get syncErrorGenericHint;

  /// No description provided for @editorDurationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter seconds or minutes and seconds, such as 3:45.'**
  String get editorDurationInvalid;

  /// No description provided for @editorNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number.'**
  String get editorNumberInvalid;

  /// No description provided for @accountReplaceConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete local songs?'**
  String get accountReplaceConfirmTitle;

  /// No description provided for @accountReplaceConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Songs and setlists on this device that are not in the new account will be permanently deleted. This can\'t be undone.'**
  String get accountReplaceConfirmBody;

  /// No description provided for @accountReplaceConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete and replace'**
  String get accountReplaceConfirmAction;

  /// No description provided for @accountSuspiciousTitle.
  ///
  /// In en, this message translates to:
  /// **'Items missing from Google Drive'**
  String get accountSuspiciousTitle;

  /// No description provided for @accountSuspiciousBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item that this device synced earlier is missing from Google Drive.} other{{count} items that this device synced earlier are missing from Google Drive.}} This can happen if app data was cleared in Google settings. Nothing has been deleted yet.'**
  String accountSuspiciousBody(int count);

  /// No description provided for @accountSuspiciousDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete them here too'**
  String get accountSuspiciousDelete;

  /// No description provided for @accountSuspiciousKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep my songs and upload them again'**
  String get accountSuspiciousKeep;

  /// No description provided for @accountSuspiciousDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete {count} item from this device?} other{Delete {count} items from this device?}}'**
  String accountSuspiciousDeleteConfirmTitle(int count);

  /// No description provided for @accountSuspiciousDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'These songs and setlists will be permanently deleted from this device. This can\'t be undone.'**
  String get accountSuspiciousDeleteConfirmBody;

  /// No description provided for @accountSuspiciousDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete from this device'**
  String get accountSuspiciousDeleteConfirmAction;

  /// No description provided for @syncErrorRemoteListingSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Items are missing from Google Drive.'**
  String get syncErrorRemoteListingSuspicious;

  /// No description provided for @syncErrorRemoteListingSuspiciousHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing was deleted. Choose whether to delete them here too or upload them again.'**
  String get syncErrorRemoteListingSuspiciousHint;

  /// No description provided for @syncErrorRemoteChanged.
  ///
  /// In en, this message translates to:
  /// **'Google Drive changed while syncing.'**
  String get syncErrorRemoteChanged;

  /// No description provided for @syncErrorRemoteChangedHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing was lost. Sync again to pick up the latest changes.'**
  String get syncErrorRemoteChangedHint;

  /// No description provided for @syncErrorInvalidLocalData.
  ///
  /// In en, this message translates to:
  /// **'Some data on this device couldn\'t be synced.'**
  String get syncErrorInvalidLocalData;

  /// No description provided for @syncErrorInvalidLocalDataHint.
  ///
  /// In en, this message translates to:
  /// **'A song or setlist could not be read. Import or recreate it, then sync again.'**
  String get syncErrorInvalidLocalDataHint;

  /// No description provided for @syncErrorNoAccountChange.
  ///
  /// In en, this message translates to:
  /// **'There is no account change to resolve.'**
  String get syncErrorNoAccountChange;

  /// No description provided for @syncErrorNoAccountChangeHint.
  ///
  /// In en, this message translates to:
  /// **'Sync again to continue.'**
  String get syncErrorNoAccountChangeHint;

  /// No description provided for @accountSyncWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Synced, but some files were skipped'**
  String get accountSyncWarningTitle;

  /// No description provided for @accountSyncWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Some files couldn\'t be used and were left as they are. Everything else is up to date.'**
  String get accountSyncWarningBody;

  /// No description provided for @accountSyncWarningTooLarge.
  ///
  /// In en, this message translates to:
  /// **'A file was too large to sync and was skipped. Everything else is up to date.'**
  String get accountSyncWarningTooLarge;

  /// No description provided for @accountSyncWarningInvalid.
  ///
  /// In en, this message translates to:
  /// **'A file couldn\'t be read and was skipped. Everything else is up to date.'**
  String get accountSyncWarningInvalid;

  /// No description provided for @accountNoticeSyncSkipped.
  ///
  /// In en, this message translates to:
  /// **'Synced. Some files were skipped.'**
  String get accountNoticeSyncSkipped;

  /// No description provided for @settingsExportPdfTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This PDF would be too large. Try fewer songs, or share it as text.'**
  String get settingsExportPdfTooLarge;

  /// No description provided for @settingsTimingTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The timing data is too large (over 3 MB).'**
  String get settingsTimingTooLarge;

  /// No description provided for @settingsImportDuplicateSongId.
  ///
  /// In en, this message translates to:
  /// **'This backup lists the same song twice, so nothing was imported.'**
  String get settingsImportDuplicateSongId;

  /// No description provided for @setlistSaveConflict.
  ///
  /// In en, this message translates to:
  /// **'The setlist changed elsewhere. Your edits were saved as a separate copy.'**
  String get setlistSaveConflict;

  /// No description provided for @sectionVerse.
  ///
  /// In en, this message translates to:
  /// **'Verse'**
  String get sectionVerse;

  /// No description provided for @sectionChorus.
  ///
  /// In en, this message translates to:
  /// **'Chorus'**
  String get sectionChorus;

  /// No description provided for @sectionBridge.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get sectionBridge;

  /// No description provided for @sectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Intro'**
  String get sectionIntro;

  /// No description provided for @sectionOutro.
  ///
  /// In en, this message translates to:
  /// **'Outro'**
  String get sectionOutro;

  /// No description provided for @sectionPreChorus.
  ///
  /// In en, this message translates to:
  /// **'Pre-Chorus'**
  String get sectionPreChorus;

  /// No description provided for @sectionPostChorus.
  ///
  /// In en, this message translates to:
  /// **'Post-Chorus'**
  String get sectionPostChorus;

  /// No description provided for @sectionInstrumental.
  ///
  /// In en, this message translates to:
  /// **'Instrumental'**
  String get sectionInstrumental;

  /// No description provided for @sectionInterlude.
  ///
  /// In en, this message translates to:
  /// **'Interlude'**
  String get sectionInterlude;

  /// No description provided for @sectionSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get sectionSolo;

  /// No description provided for @sectionRefrain.
  ///
  /// In en, this message translates to:
  /// **'Refrain'**
  String get sectionRefrain;

  /// No description provided for @sectionHook.
  ///
  /// In en, this message translates to:
  /// **'Hook'**
  String get sectionHook;

  /// No description provided for @sectionBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get sectionBreakdown;

  /// No description provided for @sectionCoda.
  ///
  /// In en, this message translates to:
  /// **'Coda'**
  String get sectionCoda;

  /// No description provided for @sectionTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get sectionTag;

  /// No description provided for @sectionEnding.
  ///
  /// In en, this message translates to:
  /// **'Ending'**
  String get sectionEnding;

  /// No description provided for @searchReadyVersions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No ready versions} =1{1 ready version} other{{count} ready versions}}'**
  String searchReadyVersions(int count);

  /// No description provided for @searchUnavailableVersions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unavailable version} other{{count} unavailable versions}}'**
  String searchUnavailableVersions(int count);

  /// No description provided for @searchJumpSection.
  ///
  /// In en, this message translates to:
  /// **'Jump to section'**
  String get searchJumpSection;

  /// No description provided for @searchVersionDetails.
  ///
  /// In en, this message translates to:
  /// **'Version details'**
  String get searchVersionDetails;

  /// No description provided for @searchSelectedRecording.
  ///
  /// In en, this message translates to:
  /// **'Selected recording'**
  String get searchSelectedRecording;

  /// No description provided for @searchVersionDuration.
  ///
  /// In en, this message translates to:
  /// **'Version duration'**
  String get searchVersionDuration;

  /// No description provided for @searchSourceOptions.
  ///
  /// In en, this message translates to:
  /// **'Source options'**
  String get searchSourceOptions;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @setlistEntryRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {song} from setlist'**
  String setlistEntryRemoved(String song);

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get backupTitle;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backupExport;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get backupRestore;

  /// No description provided for @backupIncludePreferences.
  ///
  /// In en, this message translates to:
  /// **'Include app preferences'**
  String get backupIncludePreferences;

  /// No description provided for @backupRestorePreferences.
  ///
  /// In en, this message translates to:
  /// **'Restore app preferences'**
  String get backupRestorePreferences;

  /// No description provided for @backupMerge.
  ///
  /// In en, this message translates to:
  /// **'Add to this library'**
  String get backupMerge;

  /// No description provided for @backupMergeHint.
  ///
  /// In en, this message translates to:
  /// **'Keep local edits and add songs and setlists from this backup.'**
  String get backupMergeHint;

  /// No description provided for @backupReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace this library'**
  String get backupReplace;

  /// No description provided for @backupReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'Replace all songs and setlists on this device with this backup.'**
  String get backupReplaceHint;

  /// No description provided for @backupSummary.
  ///
  /// In en, this message translates to:
  /// **'Songs: {songs} · Setlists: {setlists} · Conflicts: {conflicts}'**
  String backupSummary(int songs, int setlists, int conflicts);

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this backup operation. Try again.'**
  String get backupFailed;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored.'**
  String get backupRestored;

  /// No description provided for @backupLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Save a copy of your library. Account credentials and consent cookies are never included.'**
  String get backupLocalHint;

  /// No description provided for @backupReplaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace the current library? This cannot be undone.'**
  String get backupReplaceConfirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bg',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'ga',
    'hi',
    'hr',
    'hu',
    'id',
    'it',
    'ja',
    'ko',
    'lt',
    'lv',
    'mt',
    'nl',
    'pl',
    'pt',
    'ro',
    'ru',
    'sk',
    'sl',
    'sv',
    'tr',
    'uk',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bg':
      return AppLocalizationsBg();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'et':
      return AppLocalizationsEt();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'ga':
      return AppLocalizationsGa();
    case 'hi':
      return AppLocalizationsHi();
    case 'hr':
      return AppLocalizationsHr();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'lt':
      return AppLocalizationsLt();
    case 'lv':
      return AppLocalizationsLv();
    case 'mt':
      return AppLocalizationsMt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sk':
      return AppLocalizationsSk();
    case 'sl':
      return AppLocalizationsSl();
    case 'sv':
      return AppLocalizationsSv();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
