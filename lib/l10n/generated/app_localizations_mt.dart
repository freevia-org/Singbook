// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Maltese (`mt`).
class AppLocalizationsMt extends AppLocalizations {
  AppLocalizationsMt([String locale = 'mt']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Post paċifiku fejn issib, torganizza u tkanta l-kanzunetti tiegħek.';

  @override
  String get aboutMadeForSinging => 'Magħmul biex inkantaw flimkien';

  @override
  String appVersion(String version) {
    return 'Verżjoni $version';
  }

  @override
  String get navHome => 'Dar';

  @override
  String get navSongs => 'Kanzunetti';

  @override
  String get navSetlists => 'Listi ta’ kanzunetti';

  @override
  String get navSettings => 'Issettjar';

  @override
  String get navSettingsCompact => 'Issettjar';

  @override
  String get navSearch => 'Fittex';

  @override
  String get navBack => 'Lura';

  @override
  String get navClose => 'Agħlaq';

  @override
  String get navMore => 'Aktar azzjonijiet';

  @override
  String get actionCancel => 'Ikkanċella';

  @override
  String get actionSave => 'Issejvja';

  @override
  String get actionDone => 'Lest';

  @override
  String get actionEdit => 'Editja';

  @override
  String get actionDelete => 'Ħassar';

  @override
  String get actionShare => 'Aqsam';

  @override
  String get actionPrint => 'Ipprintja';

  @override
  String get actionCopy => 'Ikkopja';

  @override
  String get actionClear => 'Neħħi';

  @override
  String get actionRetry => 'Erġa’ pprova';

  @override
  String get actionRefresh => 'Aġġorna';

  @override
  String get actionImport => 'Importa';

  @override
  String get actionExport => 'Esporta';

  @override
  String get actionExpand => 'Espandi';

  @override
  String get actionCollapse => 'Itwi';

  @override
  String get actionAdd => 'Żid';

  @override
  String get actionCreate => 'Oħloq';

  @override
  String get actionRemove => 'Neħħi';

  @override
  String get actionDuplicate => 'Idduplika';

  @override
  String get actionMoveUp => 'Mexxi ’il fuq';

  @override
  String get actionMoveDown => 'Mexxi ’l isfel';

  @override
  String get actionPrevious => 'Preċedenti';

  @override
  String get actionNext => 'Li jmiss';

  @override
  String get searchHint => 'Fittex kanzunetti, artisti jew lirika';

  @override
  String get searchCatalogHint => 'Fittex kanzunetta jew artist';

  @override
  String get searchChangeSong => 'Ibdel il-kanzunetta';

  @override
  String get searchSelectedPreview => 'Previżjoni magħżula';

  @override
  String get searchSubmit => 'Fittex';

  @override
  String get searchFilters => 'Għażliet tat-tiftix';

  @override
  String get searchFiltersShow => 'Uri l-għażliet tat-tiftix';

  @override
  String get searchFiltersHide => 'Aħbi l-għażliet tat-tiftix';

  @override
  String get searchFilterArtist => 'Artist';

  @override
  String get searchFilterTitle => 'Titlu tal-kanzunetta';

  @override
  String get searchFilterLyrics => 'Lirika';

  @override
  String get searchFilterChords => 'Għandha akkordi';

  @override
  String get searchFilterTimed => 'Lirika b’ħin';

  @override
  String get searchFilterLanguage => 'Lingwa';

  @override
  String get searchFilterAll => 'Kwalunkwe';

  @override
  String get searchAutocompleteLabel => 'Suġġerimenti';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count riżultati',
      one: 'Riżultat wieħed',
      zero: 'Ebda riżultat',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Daħħal kanzunetta, artist jew lirika biex tfittex.';

  @override
  String get searchCatalogEmptyQuery =>
      'Daħħal kanzunetta jew artist biex tfittex.';

  @override
  String get searchNoResults =>
      'Ma nstabet ebda kanzunetta. Ipprova tfittxija oħra.';

  @override
  String get searchLoading => 'Qed infittex kanzunetti…';

  @override
  String get searchError => 'Ma setgħetx titlesta t-tfittxija.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Riċenti';

  @override
  String get searchFavoritesTab => 'Favoriti';

  @override
  String get searchSuggested => 'Taqbil issuġġerit';

  @override
  String get searchAlternatives => 'Riżultati oħra';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verżjoni lesta',
      many: '$count verżjoni lesta',
      few: '$count verżjonijiet lesti',
      two: '$count verżjonijiet lesti',
      one: '$count verżjoni lesta',
      zero: 'Mhemmx verżjonijiet lesti',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verżjoni mhux disponibbli',
      many: '$count verżjoni mhux disponibbli',
      few: '$count verżjonijiet mhux disponibbli',
      two: '$count verżjonijiet mhux disponibbli',
      one: '$count verżjoni mhux disponibbli',
      zero: 'Mhemmx verżjonijiet mhux disponibbli',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Mur fit-taqsima';

  @override
  String get searchVersionDetails => 'Dettalji tal-verżjoni';

  @override
  String get searchSelectedRecording => 'Reġistrazzjoni magħżula';

  @override
  String get searchVersionDuration => 'Tul tal-verżjoni';

  @override
  String get searchCompare => 'Qabbel il-verżjonijiet';

  @override
  String get searchChooseVersion => 'Agħżel din il-verżjoni';

  @override
  String get searchFullPreview => 'Previżjoni sħiħa';

  @override
  String get searchArrangementNotes => 'Noti dwar l-arranġament';

  @override
  String get searchOpenLyrics => 'Iftaħ il-lirika';

  @override
  String get searchContributions => 'Sorsi użati';

  @override
  String get searchVersionChecking => 'Qed niċċekkja din il-verżjoni…';

  @override
  String get searchVersionUnavailable =>
      'Din il-verżjoni ma tistax tintuża. Agħżel verżjoni oħra.';

  @override
  String get searchPreviewUnavailable =>
      'M’hemmx previżjoni tal-lirika disponibbli.';

  @override
  String get searchSongMatch => 'Taqbil tal-kanzunetta';

  @override
  String get searchRecordingMatch => 'Taqbil tar-reġistrazzjoni';

  @override
  String get searchMatchUnverified => 'Ir-reġistrazzjoni mhix ivverifikata';

  @override
  String get searchMatchExact => 'Taqbil eżatt tar-reġistrazzjoni';

  @override
  String get searchMatchPossible => 'Taqbil possibbli';

  @override
  String get searchAvailability => 'Disponibbiltà';

  @override
  String get searchLyricsAvailable => 'Lirika disponibbli';

  @override
  String get searchLyricsUnavailable => 'Lirika mhux disponibbli';

  @override
  String get searchChordsAvailable => 'Akkordi disponibbli';

  @override
  String get searchChordsUnavailable => 'Ebda akkordi';

  @override
  String get searchTimingAvailable => 'Ħin disponibbli';

  @override
  String get searchTimingUnavailable => 'Ebda ħin';

  @override
  String get searchDurationUnknown => 'Tul mhux magħruf';

  @override
  String searchRating(String rating) {
    return 'Klassifikazzjoni $rating';
  }

  @override
  String get searchSourceLabel => 'Sors';

  @override
  String get searchMetadata => 'Dettalji tal-kanzunetta';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Artist';

  @override
  String get searchYear => 'Sena';

  @override
  String get searchLanguage => 'Lingwa';

  @override
  String get searchViewVersions => 'Ara verżjonijiet';

  @override
  String get searchSaved =>
      'Il-kanzunetta ġiet issejvjata fil-librerija tiegħek.';

  @override
  String get searchSaveOpenLyrics => 'Issejvja u iftaħ il-lirika';

  @override
  String get searchOtherResults => 'Riżultati oħra';

  @override
  String get searchSaveFailed =>
      'Ma setgħetx tiġi ssejvjata din il-kanzunetta.';

  @override
  String get homeRecentSongs => 'Kanzunetti riċenti';

  @override
  String get homeRecentlyPlayed => 'Daqqew riċentement';

  @override
  String get homeFavorites => 'Favoriti';

  @override
  String get homeHistory => 'Kronoloġija';

  @override
  String get homeHistoryClear => 'Ħassar il-kronoloġija';

  @override
  String get homeHistoryCleared => 'Il-kronoloġija tħassret.';

  @override
  String get homeHistoryEmpty => 'Il-kanzunetti li tiftaħ jidhru hawn.';

  @override
  String get homeFavoritesEmpty =>
      'Il-kanzunetti u l-listi favoriti tiegħek jidhru hawn.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi ntwerew',
      one: 'Intwera element wieħed',
      zero: 'Ma ntwera ebda element',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Il-kanzunetti u l-listi riċenti tiegħek jidhru hawn.';

  @override
  String get homeTimelineLabel => 'Kronoloġija tal-istorja';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Kronoloġija sħiħa';

  @override
  String get homeShowFavorites => 'Uri l-favoriti';

  @override
  String get homeShowRecent => 'Uri r-riċenti';

  @override
  String get songsTitle => 'Kanzunetti';

  @override
  String get songsEmpty => 'Il-kanzunetti tiegħek jidhru hawn.';

  @override
  String get songsEmptySearch =>
      'Ebda kanzunetta ma taqbel mat-tfittxija tiegħek.';

  @override
  String get songsAdd => 'Żid kanzunetta';

  @override
  String get songsSortAlphabetical => 'Ordna alfabetikament';

  @override
  String get songsAlphabetNavigation => 'Indiċi tal-kanzunetti';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Infetħet $count darbiet',
      one: 'Infetħet darba',
      zero: 'Qatt ma nfetħet',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'Żid mal-favoriti';

  @override
  String get songFavoriteRemove => 'Neħħi mill-favoriti';

  @override
  String get songMenuLabel => 'Azzjonijiet tal-kanzunetta';

  @override
  String get songInfo => 'Dettalji tal-kanzunetta';

  @override
  String get setlistMenuLabel => 'Azzjonijiet tal-lista';

  @override
  String get songAddToSetlist => 'Żid mal-lista';

  @override
  String get songCopyChordPro => 'Ikkopja ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Tħassar il-kanzunetta?';

  @override
  String get songDeleteConfirmMessage =>
      'Din il-kanzunetta se titneħħa mil-librerija tiegħek.';

  @override
  String get songDeleted => 'Il-kanzunetta tħassret.';

  @override
  String get setlistsTitle => 'Listi ta’ kanzunetti';

  @override
  String get setlistsEmpty =>
      'Oħloq lista għall-prova jew l-eżekuzzjoni li jmiss tiegħek.';

  @override
  String get setlistsEmptySearch =>
      'Ebda lista ma taqbel mat-tfittxija tiegħek.';

  @override
  String get setlistCreate => 'Lista ġdida';

  @override
  String get setlistNameHint => 'Isem il-lista';

  @override
  String get setlistNotes => 'Noti';

  @override
  String get setlistEntryOverride => 'Tonalità u capo għal din il-kanzunetta';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kanzunetti',
      one: 'Kanzunetta waħda',
      zero: 'Ebda kanzunetta',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Mill-inqas $duration';
  }

  @override
  String get setlistDurationUnknown => 'Tul mhux magħruf';

  @override
  String setlistActivity(String date) {
    return 'L-aħħar attività $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Inħolqot $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Ġiet editjata $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'L-aħħar daqq $date';
  }

  @override
  String get setlistSongsEmpty => 'Din il-lista għadha bla kanzunetti.';

  @override
  String get setlistAddSongs => 'Żid kanzunetti';

  @override
  String get setlistReorder => 'Ibdel l-ordni tal-kanzunetti';

  @override
  String setlistMoveSongUp(String song) {
    return 'Mexxi $song ’il fuq';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Mexxi $song ’l isfel';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Neħħi $song mil-lista';
  }

  @override
  String get setlistDuplicate => 'Idduplika l-lista';

  @override
  String get setlistFavoriteAdd => 'Żid il-lista mal-favoriti';

  @override
  String get setlistFavoriteRemove => 'Neħħi l-lista mill-favoriti';

  @override
  String get setlistShare => 'Aqsam bħala fajl tal-lista';

  @override
  String get setlistSharePdf => 'Aqsam bħala PDF';

  @override
  String get setlistPrint => 'Ipprintja';

  @override
  String get setlistDeleteConfirmTitle => 'Tħassar il-lista?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Il-lista se titneħħa. Il-kanzunetti fil-librerija tiegħek jibqgħu.';

  @override
  String get setlistDeleted => 'Il-lista tħassret.';

  @override
  String get readerTitle => 'Lirika';

  @override
  String get readerNoLyrics => 'Għadha ma żdiedetx il-lirika.';

  @override
  String get readerShowChords => 'Uri l-akkordi';

  @override
  String get readerHideChords => 'Aħbi l-akkordi';

  @override
  String get readerTranspose => 'Ibdel it-tonalità tal-akkordi';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semitoni',
      one: 'semitonu wieħed',
      zero: '0 semitoni',
    );
    return 'Ibdel b’$_temp0';
  }

  @override
  String get readerSaved => 'Issejvjat';

  @override
  String get readerEdit => 'Editja l-lirika u d-dettalji';

  @override
  String get playerPlay => 'Ibda l-iskrolljar tal-lirika';

  @override
  String get playerPause => 'Waqqaf l-iskrolljar tal-lirika';

  @override
  String get playerResume => 'Kompli l-iskrolljar tal-lirika';

  @override
  String get playerSeek => 'Pożizzjoni tad-daqq';

  @override
  String playerElapsed(String time) {
    return 'Ħin li għadda $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Ħin li fadal $time';
  }

  @override
  String get playerTimingMode => 'Mod tal-iskrolljar';

  @override
  String get playerTimedLyrics => 'Lirika b’ħin';

  @override
  String get playerStartScroll => 'Ibda skrolljar awtomatiku';

  @override
  String get playerEstimatedPace => 'Ritmu stmat';

  @override
  String get playerScrollSpeed => 'Veloċità tal-iskrolljar';

  @override
  String playerEstimatedDuration(String time) {
    return 'Tul stmat: $time';
  }

  @override
  String get playerLyricsOnly => 'Skrolljar tal-lirika · mingħajr awdjo';

  @override
  String get playerManualScroll => 'Skrolljar manwali';

  @override
  String get playerTimingStatusReady =>
      'Il-lirika se ssegwi l-ħin disponibbli.';

  @override
  String get playerTimingStatusEstimated =>
      'Ir-ritmu tal-iskrolljar huwa stmat mit-tul tal-kanzunetta.';

  @override
  String get playerTimingStatusManual => 'Skrollja l-lirika int.';

  @override
  String get playerTimingStatusUnavailable =>
      'L-iskrolljar bil-ħin mhuwiex disponibbli għal din il-kanzunetta.';

  @override
  String get playerDurationUnknown =>
      'Żid it-tul tal-kanzunetta biex tuża skrolljar stmat.';

  @override
  String get playerProgressLabel => 'Progress tal-kanzunetta';

  @override
  String get playerCurrentSection => 'Parti attwali';

  @override
  String get playerPreviousSection => 'Parti ta’ qabel';

  @override
  String get playerNextSection => 'Parti li jmiss';

  @override
  String get playerPreviousSectionSong =>
      'Parti ta’ qabel · żomm għal kanzunetta ta’ qabel fil-lista';

  @override
  String get playerNextSectionSong =>
      'Parti li jmiss · żomm għal kanzunetta li jmiss fil-lista';

  @override
  String get playerPreviousSong => 'Kanzunetta ta’ qabel';

  @override
  String get playerNextSong => 'Il-kanzunetta li jmiss';

  @override
  String get editorTitle => 'Editja l-kanzunetta';

  @override
  String get editorTitleField => 'Titlu tal-kanzunetta';

  @override
  String get editorArtistField => 'Artist';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Lirika';

  @override
  String get editorChordsField => 'Akkordi';

  @override
  String get editorKeyField => 'Tonalità';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Intunatura';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Tul';

  @override
  String get editorTimeSignatureField => 'Metru';

  @override
  String get editorLanguageField => 'Lingwa';

  @override
  String get editorYearField => 'Sena';

  @override
  String get editorComposerField => 'Kompożitur';

  @override
  String get editorLyricistField => 'Kittieb tal-lirika';

  @override
  String get editorCopyrightField => 'Drittijiet tal-awtur';

  @override
  String get editorLicenseField => 'Liċenzja';

  @override
  String get songInfoSources => 'Sorsi u krediti';

  @override
  String get searchMatchSameSong =>
      'L-istess kanzunetta; ir-reġistrazzjoni mhix ikkonfermata';

  @override
  String get searchMatchNeedsAgreement =>
      'Il-lirika tal-partitura trid tiġi kkonfermata';

  @override
  String get searchMatchDifferentLyrics =>
      'Il-lirika hija differenti minn dik tal-kanzunetta magħżula';

  @override
  String get searchMatchCombinedSources =>
      'Dettalji magħquda minn diversi sorsi';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Magħquda minn $count sorsi',
      one: 'Magħquda minn sors wieħed',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count taqbiliet ta’ kanzunetti',
      one: 'Taqbil wieħed ta’ kanzunetta',
      zero: 'Ebda taqbil ta’ kanzunetta',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verżjonijiet minn sorsi',
      one: 'Verżjoni waħda minn sors',
      zero: 'Ebda verżjoni minn sors',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'L-aħjar taqbil disponibbli';

  @override
  String get providerDescriptionUnknown => 'Sors tal-kanzunetta';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Niżżel fajl ChordPro mis-sors, imbagħad importah.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Niżżel fajl b’kont bla ħlas, imbagħad importah.';

  @override
  String get providerDescPublicChordSheets => 'Partituri pubbliċi bl-akkordi.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Lirika storika liċenzjata għal kull xogħol.';

  @override
  String get providerDescLicensedCatalog => 'Katalgu tal-lirika liċenzjat.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Kanzunetti oriġinali taħt Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Lirika liċenzjata għal kull kanzunetta.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Dettalji tar-reġistrazzjoni u tar-rilaxx biss.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Dettalji tal-kompożizzjoni biss.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Kopertina biss għal reġistrazzjonijiet li jaqblu eżatt.';

  @override
  String get providerCapabilityLyrics => 'Lirika';

  @override
  String get providerCapabilityChords => 'Akkordi';

  @override
  String get providerCapabilityTiming => 'Lirika b’ħin';

  @override
  String get providerCapabilitySearch => 'Tiftix';

  @override
  String get providerCapabilityMetadata => 'Dettalji tal-kanzunetta';

  @override
  String get editorArtworkField => 'Link tal-kopertina';

  @override
  String get editorLyricsHint =>
      'Tektek linja biex teditja l-lirika jew l-akkordi.';

  @override
  String get editorSave => 'Issejvja l-bidliet';

  @override
  String get editorSaved => 'Il-bidliet ġew issejvjati.';

  @override
  String get editorSaveFailed => 'Ma setgħux jiġu ssejvjati l-bidliet.';

  @override
  String get editorSaveConflict =>
      'Il-kanzunetta nbidlet f’post ieħor. L-editji tiegħek ġew issejvjati bħala kopja separata.';

  @override
  String get editorUnsavedTitle => 'Tarmi l-bidliet?';

  @override
  String get editorUnsavedMessage =>
      'L-editji tiegħek għadhom ma ġewx issejvjati.';

  @override
  String get editorFieldRequired => 'Daħħal titlu tal-kanzunetta.';

  @override
  String get settingsTitle => 'Issettjar';

  @override
  String get settingsAppearance => 'Dehra';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Uża l-issettjar tal-apparat';

  @override
  String get settingsThemeLight => 'Ċara';

  @override
  String get settingsThemeDark => 'Skura';

  @override
  String get settingsColorPalette => 'Paletta tal-kuluri';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsTextSize => 'Daqs tat-test';

  @override
  String get settingsLyricsPreview => 'Previżjoni tal-lirika';

  @override
  String get settingsPlayer => 'Plejer tal-lirika';

  @override
  String get settingsDefaultShowChords => 'Uri l-akkordi b’mod predefinit';

  @override
  String get settingsDefaultAutoscroll =>
      'Ibda l-iskrolljar tal-lirika awtomatikament';

  @override
  String get settingsDefaultTiming => 'Mod tal-iskrolljar predefinit';

  @override
  String get settingsLanguage => 'Lingwa tal-app';

  @override
  String get settingsLanguageSystem => 'Uża l-lingwa tal-apparat';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Sorsi tal-lirika';

  @override
  String settingsSourceEnabled(String source) {
    return 'Attiva s-sors $source';
  }

  @override
  String get settingsSourceRefresh => 'Aġġorna l-lista tas-sorsi';

  @override
  String get settingsSourcesUpdated => 'Is-sorsi ġew aġġornati.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Ma setgħetx tiġġedded il-lista tas-sorsi.';

  @override
  String get settingsImport => 'Importa kanzunetti';

  @override
  String get settingsImportChordPro => 'Importa fajl ChordPro';

  @override
  String get settingsImportSetlist => 'Importa fajl tal-lista';

  @override
  String get settingsImportSuccess => 'L-importazzjoni tlestiet.';

  @override
  String get settingsImportFailed => 'Ma setax jiġi importat dan il-fajl.';

  @override
  String get settingsImportUnsupported =>
      'Dan it-tip ta’ fajl mhuwiex appoġġjat.';

  @override
  String get settingsShareSong => 'Aqsam bħala ChordPro';

  @override
  String get settingsSharePdf => 'Aqsam bħala PDF';

  @override
  String get settingsCopySong => 'Ikkopja fil-clipboard';

  @override
  String get settingsPrintSong => 'Ipprintja biss';

  @override
  String get settingsPrintSetlist => 'Ipprintja l-lista bil-lirika';

  @override
  String get settingsExportFailed => 'Ma setax jitħejja l-fajl.';

  @override
  String get settingsCopied => 'Ġie kkupjat fil-clipboard.';

  @override
  String get settingsAbout => 'Dwar';

  @override
  String get settingsPrivacy => 'Privatezza';

  @override
  String get settingsLegal => 'Legali';

  @override
  String get settingsClearHistory => 'Ħassar il-kronoloġija';

  @override
  String get settingsClearHistoryConfirm =>
      'Tħassar il-kronoloġija tal-kanzunetti u l-listi?';

  @override
  String get settingsHistoryCleared => 'Il-kronoloġija tħassret.';

  @override
  String get accountTitle => 'Kont u sinkronizzazzjoni';

  @override
  String get accountUnavailable =>
      'Is-sinkronizzazzjoni teħtieġ verżjoni ta’ Singbook b’aċċess għal Google kkonfigurat. Din il-verżjoni żżomm il-kanzunetti tiegħek fuq dan l-apparat biss.';

  @override
  String get accountSyncNow => 'Issinkronizza issa';

  @override
  String get accountConnected =>
      'Imqabbad. Agħżel “Issinkronizza issa” biex taġġorna l-backup tiegħek.';

  @override
  String get accountSignIn => 'Qabbad kont';

  @override
  String get accountSignOut => 'Oħroġ mill-kont';

  @override
  String get accountChange => 'Ibdel il-kont';

  @override
  String get accountSignedOut => 'Mhux imqabbad';

  @override
  String get accountSyncing => 'Qed nissinkronizza l-librerija tiegħek…';

  @override
  String get accountSynced => 'Il-librerija ġiet issinkronizzata.';

  @override
  String get accountSyncFailed =>
      'Ma setgħetx tiġi sinkronizzata l-librerija tiegħek.';

  @override
  String get accessibilityFavorite => 'Favorit';

  @override
  String get accessibilityNotFavorite => 'Mhux favorit';

  @override
  String get accessibilitySearchField => 'Fittex kanzunetti';

  @override
  String get accessibilityClearSearch => 'Neħħi t-test tat-tfittxija';

  @override
  String accessibilitySongMenu(String song) {
    return 'Azzjonijiet għal $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Azzjonijiet għal $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Espandi l-kanzunetti f’$setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Itwi l-kanzunetti f’$setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Progress tad-daqq, $percent fil-mija';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Kronoloġija tal-istorja, $date';
  }

  @override
  String get loading => 'Qed jitgħabba…';

  @override
  String get loadingSongs => 'Qed jitgħabbew il-kanzunetti…';

  @override
  String get loadingSetlists => 'Qed jitgħabbew il-listi…';

  @override
  String get errorGeneric => 'Xi ħaġa marret ħażin.';

  @override
  String get errorOffline => 'Jidher li m’intix online.';

  @override
  String get errorPermission => 'Hemm bżonn permess biex tkompli.';

  @override
  String get emptyFiltered => 'Ebda element ma jaqbel ma’ dawn il-filtri.';

  @override
  String get unknownValue => 'Mhux magħruf';

  @override
  String get durationUnknown => 'Tul mhux magħruf';

  @override
  String get metadataNotSet => 'Mhux issettjat';

  @override
  String get dateToday => 'Illum';

  @override
  String get dateYesterday => 'Ilbieraħ';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kanzunetti',
      one: 'Kanzunetta waħda',
      zero: 'Ebda kanzunetta',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Blu navy';

  @override
  String get settingsPaletteSage => 'Aħdar salvja';

  @override
  String get settingsPaletteOcean => 'Oċean';

  @override
  String get settingsPaletteClay => 'Tafal';

  @override
  String get settingsPalettePlum => 'Għanbaqar';

  @override
  String get settingsFontSystem => 'Sistema';

  @override
  String get settingsFontSerif => 'Serif';

  @override
  String get settingsFontMonospace => 'Monospazju';

  @override
  String get settingsLyricsPreviewExample =>
      'Meta jasal filgħodu, nerġgħu nkantaw.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Qed niċċekkja s-sorsi tal-lirika: $checked minn $total lesti.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Ma nstabet ebda lirika li tista’ tintuża.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Il-kanzunetta magħżula ġiet iċċekkjata mas-sorsi attivati, iżda ħadd minnhom ma rritorna verżjoni tal-lirika li tista’ tintuża.';

  @override
  String get searchDiscoveryError =>
      'Ma setgħux jiġu ċċekkjati s-sorsi tal-lirika.';

  @override
  String get searchDiscoveryRetry => 'Erġa’ fittex il-lirika';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sorsi mhux disponibbli',
      one: 'sors wieħed mhux disponibbli',
      zero: '0 sors mhux disponibbli',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails =>
      'Iċċekkja l-konnessjoni tiegħek u erġa’ pprova.';

  @override
  String get searchProviderChecks => 'Iċċekkjar tas-sorsi';

  @override
  String get searchProviderPending => 'Qed jiċċekkja';

  @override
  String get searchProviderFound => 'Instab taqbil';

  @override
  String get searchProviderRejected => 'Ma jaqbilx';

  @override
  String get searchProviderFailed => 'L-iċċekkjar falla';

  @override
  String get searchProviderUnavailable => 'Ebda lirika li tista’ tintuża';

  @override
  String get searchCatalogFilterHint =>
      'Agħżel kanzunetta biex tiffiltra l-verżjonijiet tal-lirika skont l-akkordi, il-ħin jew il-lingwa.';

  @override
  String get startupErrorTitle => 'Ma setgħetx tinfetaħ il-librerija tiegħek.';

  @override
  String setlistCopyName(String name) {
    return 'Kopja ta’ $name';
  }

  @override
  String get setlistSongMissing => 'Kanzunetta nieqsa';

  @override
  String get settingsImportTooLarge =>
      'Dan il-fajl huwa kbir wisq biex jiġi importat.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Mur għal $letter';
  }

  @override
  String get actionDiscard => 'Armi';

  @override
  String get editorKeepEditing => 'Kompli editja';

  @override
  String get settingsDefaultShowChordsHint =>
      'Uri l-akkordi fuq il-lirika meta jkun hemm.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Il-lirika tiskrollja mal-kanzunetta. Ma jintużax fil-mod ta’ skrolljar manwali.';

  @override
  String get accountUnavailableTitle =>
      'Is-sinkronizzazzjoni mhix ikkonfigurata';

  @override
  String get accountSignedOutBenefits =>
      'Idħol b’Google biex tagħmel backup tal-kanzunetti u l-listi tiegħek fuq Google Drive u żżomm l-apparati kollha tiegħek sinkronizzati. Il-kanzunetti tiegħek jibqgħu fuq dan l-apparat fi kwalunkwe każ.';

  @override
  String get accountSignInWithGoogle => 'Idħol b’Google';

  @override
  String get accountWorking => 'Qed jaħdem…';

  @override
  String get accountNeverSynced => 'Qatt ma ġiet sinkronizzata';

  @override
  String get accountSyncedJustNow => 'Sinkronizzata issa stess';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinkronizzata $count minuti ilu',
      one: 'Sinkronizzata minuta ilu',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinkronizzata $count sigħat ilu',
      one: 'Sinkronizzata siegħa ilu',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinkronizzata $count ijiem ilu',
      one: 'Sinkronizzata ġurnata ilu',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count editji konfliġġenti nżammu bħala kopji',
      one: 'Editja konfliġġenti waħda nżammet bħala kopja',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'L-istess kanzunetta jew lista ġiet editjata f’żewġ postijiet. Ma ntilef xejn: il-verżjoni l-oħra ġiet issejvjata bħala kopja separata.';

  @override
  String get accountReviewConflicts => 'Irrevedi l-kopji';

  @override
  String get songsConflictFilterActive =>
      'Qed jintwerew biss kopji konfliġġenti';

  @override
  String get songsConflictFilterClear => 'Uri l-kanzunetti kollha';

  @override
  String get songsConflictBadge => 'Kopja konfliġġenti';

  @override
  String get songsConflictEmpty => 'Ebda kopja konfliġġenti.';

  @override
  String get accountAutoSync => 'Issinkronizza awtomatikament';

  @override
  String get accountAutoSyncHint =>
      'Żomm il-librerija tiegħek aġġornata meta tiftaħ l-app u wara l-bidliet.';

  @override
  String get accountSignOutTitle => 'Toħroġ minn dan il-kont?';

  @override
  String get accountSignOutBody =>
      'Il-kanzunetti u l-listi tiegħek jibqgħu fuq dan l-apparat. Mhux se jsir backup jew sinkronizzazzjoni sakemm terġa’ tidħol.';

  @override
  String get accountUseDifferent => 'Uża kont ieħor';

  @override
  String get accountSignInAgain => 'Idħol mill-ġdid';

  @override
  String get accountChooseAction => 'Agħżel kif tkompli';

  @override
  String get accountChangedTitle => 'Kont Google differenti';

  @override
  String get accountChangedBody =>
      'Dan l-apparat issinkronizza l-aħħar ma’ kont Google ieħor. Agħżel x’għandu jiġri lill-kanzunetti u l-listi fuq dan l-apparat.';

  @override
  String get accountChangedMerge => 'Għaqqad mal-kont il-ġdid';

  @override
  String get accountChangedMergeHint =>
      'Żomm kollox fuq dan l-apparat u żidu mal-kont il-ġdid.';

  @override
  String get accountChangedReplace => 'Ibdel bil-librerija tal-kont il-ġdid';

  @override
  String get accountChangedReplaceHint =>
      'Jitneħħew il-kanzunetti fuq dan l-apparat li mhumiex fil-kont il-ġdid.';

  @override
  String get accountChangedSignOut => 'Ikkanċella u oħroġ';

  @override
  String get accountStatusSignedOut =>
      'Kont u sinkronizzazzjoni: mhux illoggjat';

  @override
  String get accountStatusSignedIn => 'Kont u sinkronizzazzjoni: illoggjat';

  @override
  String get accountStatusSyncing =>
      'Kont u sinkronizzazzjoni: qed tissinkronizza';

  @override
  String get accountStatusSynced =>
      'Kont u sinkronizzazzjoni: il-librerija hija aġġornata';

  @override
  String get accountStatusError =>
      'Kont u sinkronizzazzjoni: problema, tektek biex tirrevedi';

  @override
  String get accountNoticeConflicts =>
      'Xi kanzunetti ġew editjati f’żewġ postijiet. Inżammu kopji.';

  @override
  String get accountNoticeSignedIn => 'Dħalt fil-kont.';

  @override
  String get accountNoticeSignedOut =>
      'Ħriġt mill-kont. Il-kanzunetti tiegħek jibqgħu fuq dan l-apparat.';

  @override
  String get syncErrorNotConfigured =>
      'Is-sinkronizzazzjoni mhix ikkonfigurata f’din il-verżjoni.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Uża verżjoni ta’ Singbook b’aċċess għal Google kkonfigurat.';

  @override
  String get syncErrorNotSignedIn => 'M’intix illoggjat.';

  @override
  String get syncErrorNotSignedInHint =>
      'Idħol biex tissinkronizza l-librerija tiegħek.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google teħtieġ li terġa’ tidħol.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Idħol mill-ġdid biex tkompli tissinkronizza. Il-kanzunetti tiegħek huma siguri fuq dan l-apparat.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook m’għandhiex permess tuża Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Idħol mill-ġdid u agħti aċċess għal Drive meta tintalab.';

  @override
  String get syncErrorRateLimited => 'Google qed tillimita t-talbiet għalissa.';

  @override
  String get syncErrorRateLimitedHint =>
      'Stenna ftit minuti, imbagħad erġa’ pprova.';

  @override
  String get syncErrorStorageFull => 'Google Drive tiegħek mimli.';

  @override
  String get syncErrorStorageFullHint =>
      'Ħeles ftit spazju f’Drive, imbagħad erġa’ pprova.';

  @override
  String get syncErrorNetwork => 'Ma rnexxilniex nilħqu lil Google.';

  @override
  String get syncErrorNetworkHint =>
      'Iċċekkja l-konnessjoni tal-internet u erġa’ pprova.';

  @override
  String get syncErrorAccountChanged => 'Intuża kont Google differenti.';

  @override
  String get syncErrorAccountChangedHint =>
      'Agħżel jekk tgħaqqadx il-librerija ta’ dan l-apparat miegħu jew tissostitwixxihiex.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Il-librerija sinkronizzata tiegħek hija akbar milli tista’ timmaniġġa Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Neħħi xi kanzunetti jew listi mil-librerija sinkronizzata, imbagħad erġa’ pprova.';

  @override
  String get syncErrorSignInFailed => 'Id-dħul fil-kont ma tlestiex.';

  @override
  String get syncErrorSignInFailedHint => 'Erġa’ pprova tidħol.';

  @override
  String get syncErrorGeneric =>
      'Ma setgħetx tiġi sinkronizzata l-librerija tiegħek.';

  @override
  String get syncErrorGenericHint =>
      'Erġa’ pprova dalwaqt. Il-kanzunetti tiegħek għadhom siguri fuq dan l-apparat.';

  @override
  String get editorDurationInvalid =>
      'Daħħal is-sekondi jew il-minuti u s-sekondi, pereżempju 3:45.';

  @override
  String get editorNumberInvalid => 'Daħħal numru.';

  @override
  String get accountReplaceConfirmTitle => 'Tħassar il-kanzunetti lokali?';

  @override
  String get accountReplaceConfirmBody =>
      'Il-kanzunetti u l-listi fuq dan it-tagħmir li mhumiex fil-kont il-ġdid se jitħassru għal dejjem. Ma tistax treġġa’ lura din l-azzjoni.';

  @override
  String get accountReplaceConfirmAction => 'Ħassar u ibdel';

  @override
  String get accountSuspiciousTitle => 'Oġġetti neqsin minn Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count oġġetti li dan l-apparat issinkronizza qabel huma neqsin minn Google Drive.',
      one:
          '$count oġġett li dan l-apparat issinkronizza qabel huwa nieqes minn Google Drive.',
    );
    return '$_temp0 Dan jista’ jiġri jekk id-data tal-app tħassret fis-settings ta’ Google. Għadu ma tħassar xejn.';
  }

  @override
  String get accountSuspiciousDelete => 'Ħassarhom minn dan l-apparat ukoll';

  @override
  String get accountSuspiciousKeep =>
      'Żomm il-kanzunetti tiegħi u tella’hom mill-ġdid';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tħassar $count oġġetti minn dan l-apparat?',
      one: 'Tħassar $count oġġett minn dan l-apparat?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Dawn il-kanzunetti u l-listi se jitħassru għal dejjem minn dan l-apparat. Ma tistax treġġa’ lura din l-azzjoni.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Ħassar minn dan l-apparat';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Oġġetti neqsin minn Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Ma tħassar xejn. Agħżel jekk tridx tħassarhom minn dan l-apparat ukoll jew ittellagħhom mill-ġdid.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive nbidel waqt is-sinkronizzazzjoni.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Ma ntilef xejn. Issinkronizza mill-ġdid biex tikseb l-aħħar bidliet.';

  @override
  String get syncErrorInvalidLocalData =>
      'Xi data fuq dan l-apparat ma setgħetx tiġi ssinkronizzata.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Kanzunetta jew lista ma setgħetx tinqara. Importaha jew oħloqha mill-ġdid, imbagħad issinkronizza.';

  @override
  String get syncErrorNoAccountChange => 'M’hemmx bidla fil-kont x’issolvi.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Issinkronizza mill-ġdid biex tkompli.';

  @override
  String get accountSyncWarningTitle => 'Issinkronizzat, iżda nqabeż xi fajls';

  @override
  String get accountSyncWarningBody =>
      'Xi fajls ma setgħux jintużaw u tħallew kif kienu. Kull ħaġa oħra hija aġġornata.';

  @override
  String get accountSyncWarningTooLarge =>
      'Fajl kien kbir wisq biex jiġi ssinkronizzat u nqabeż. Kull ħaġa oħra hija aġġornata.';

  @override
  String get accountSyncWarningInvalid =>
      'Fajl ma setax jinqara u nqabeż. Kull ħaġa oħra hija aġġornata.';

  @override
  String get accountNoticeSyncSkipped => 'Issinkronizzat. Inqabżu xi fajls.';

  @override
  String get settingsExportPdfTooLarge =>
      'Dan il-PDF ikun kbir wisq. Agħżel inqas kanzunetti jew aqsam bħala test.';

  @override
  String get settingsTimingTooLarge =>
      'Id-data tat-timing hija kbira wisq (aktar minn 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Din il-backup telenka l-istess kanzunetta darbtejn, għalhekk ma ġie importat xejn.';

  @override
  String get setlistSaveConflict =>
      'Il-lista nbidlet x’imkien ieħor. Il-bidliet tiegħek ġew salvati bħala kopja separata.';

  @override
  String get sectionVerse => 'Vers';

  @override
  String get sectionChorus => 'Ritornell';

  @override
  String get sectionBridge => 'Pont';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Qabel ir-ritornell';

  @override
  String get sectionPostChorus => 'Wara r-ritornell';

  @override
  String get sectionInstrumental => 'Parti strumentali';

  @override
  String get sectionInterlude => 'Interludju';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Ritornell';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Koda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Tmiem';

  @override
  String get youtubeConsentHint =>
      'Sperimentali. Agħżel il-cookies fil-paġna ta\' Google biex tipprova tfittex il-lirika. M\'hemmx għalfejn tidħol f\'kont ta\' Google. L-għażla tiegħek tibqa\' fuq dan it-tagħmir.';

  @override
  String get youtubeConsentOpen => 'Irrevedi l-kunsens ta\' Google';

  @override
  String get youtubeConsentSaved => 'Il-kunsens ġie ssejvjat';

  @override
  String get youtubeConsentClear => 'Neħħi l-kunsens';

  @override
  String get youtubeConsentInstructions =>
      'Temm l-għażla tal-cookies u stenna sakemm jerġa\' jidher YouTube Music. Imbagħad issejvja din is-sessjoni u erġa\' fittex il-kanzunetta.';

  @override
  String get youtubeConsentError =>
      'Ma setgħetx tiġi aġġornata l-għażla tal-kunsens ta\' Google. Erġa\' pprova.';

  @override
  String get youtubeConsentBlocked =>
      'Hawnhekk jistgħu jinfetħu biss YouTube Music u l-paġna tal-kunsens ta\' Google. Id-dħul f\'kont mhuwiex disponibbli.';
}
