// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Dina låttexter, ackord och setlistor samlade, redo för repetition, scenen och överallt där du spelar.';

  @override
  String get aboutMadeForSinging => 'Varje låt, redo att sjungas.';

  @override
  String get aboutDetails =>
      'Sök bland tillgängliga källor och jämför låttexter, ackord, timing och inspelningsinformation innan du sparar den version du vill spela. Tillgängligheten varierar mellan låtar och tjänster.';

  @override
  String get aboutFindTitle => 'Hitta rätt version';

  @override
  String get aboutKeepTitle => 'Bygg ditt eget bibliotek';

  @override
  String get aboutKeepDetails =>
      'Redigera och transponera låtar, behåll dem i det lokala biblioteket för offlineanvändning och dela portabla ChordPro-filer. Valfri synkronisering med Google Drive använder en privat appmapp i ditt Google-konto. Du kan också trycka på ”Synkronisera nu” för att uppdatera dina enheter.';

  @override
  String get aboutPlayTitle => 'Ta med setlistan upp på scenen';

  @override
  String get aboutPlayDetails =>
      'Ordna låtar i setlistor, välj tonart för varje låt och dela OpenSong-setlistor. Anpassa textstorleken i läsaren, aktivera automatisk rullning av låttexten och skriv ut låt-PDF:er. Singbook strömmar eller spelar inte upp ljud.';

  @override
  String get aboutPrivacyTitle => 'Gratis med lokal lagring i första hand';

  @override
  String get aboutPrivacyDetails =>
      'Singbook är gratis och saknar annonser, analys och köp inuti appen. Ditt sparade bibliotek finns kvar på enheten; valfri synkronisering använder ditt eget Google Drive. Onlineresultat kommer direkt från oberoende tredjepartstjänster och kan vara otillgängliga eller skyddade av upphovsrätt. Singbook är inte värd för deras innehåll.';

  @override
  String get aboutWebsite => 'Singbooks webbplats';

  @override
  String get aboutSourceCode => 'Källkod på GitHub';

  @override
  String get aboutPublisher => 'Av Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Appens språk: $count';
  }

  @override
  String get aboutSupport => 'Support och feedback';

  @override
  String get menuTypeNewSong => 'Skriv in en ny låt';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get navHome => 'Hem';

  @override
  String get navSongs => 'Låtar';

  @override
  String get navSetlists => 'Setlistor';

  @override
  String get navSettings => 'Inställningar';

  @override
  String get navSettingsCompact => 'Inställningar';

  @override
  String get navSearch => 'Sök';

  @override
  String get navBack => 'Tillbaka';

  @override
  String get appExitBackAgain => 'Tryck på Tillbaka igen för att avsluta';

  @override
  String get navClose => 'Stäng';

  @override
  String get navMore => 'Fler åtgärder';

  @override
  String get actionCancel => 'Avbryt';

  @override
  String get actionSave => 'Spara';

  @override
  String get actionDone => 'Klart';

  @override
  String get actionEdit => 'Redigera';

  @override
  String get actionDelete => 'Ta bort';

  @override
  String get actionShare => 'Dela';

  @override
  String get actionPrint => 'Skriv ut';

  @override
  String get actionCopy => 'Kopiera';

  @override
  String get actionClear => 'Rensa';

  @override
  String get actionRetry => 'Försök igen';

  @override
  String get actionRefresh => 'Uppdatera';

  @override
  String get actionImport => 'Importera';

  @override
  String get actionExport => 'Exportera';

  @override
  String get actionExpand => 'Expandera';

  @override
  String get actionCollapse => 'Fäll ihop';

  @override
  String get actionAdd => 'Lägg till';

  @override
  String get actionCreate => 'Skapa';

  @override
  String get actionRemove => 'Ta bort';

  @override
  String get actionDuplicate => 'Duplicera';

  @override
  String get actionMoveUp => 'Flytta upp';

  @override
  String get actionMoveDown => 'Flytta ned';

  @override
  String get actionPrevious => 'Föregående';

  @override
  String get actionNext => 'Nästa';

  @override
  String get searchHint => 'Sök efter låtar, artister eller låttexter';

  @override
  String get searchCatalogHint => 'Sök efter en låt eller artist';

  @override
  String get searchChangeSong => 'Byt låt';

  @override
  String get searchSelectedPreview => 'Vald förhandsvisning';

  @override
  String get searchSubmit => 'Sök';

  @override
  String get searchFilters => 'Sökalternativ';

  @override
  String get searchFiltersShow => 'Visa sökalternativ';

  @override
  String get searchFiltersHide => 'Dölj sökalternativ';

  @override
  String get searchFilterArtist => 'Artist';

  @override
  String get searchFilterTitle => 'Låttitel';

  @override
  String get searchFilterLyrics => 'Låttexter';

  @override
  String get searchFilterChords => 'Har ackord';

  @override
  String get searchFilterTimed => 'Tidsinställda låttexter';

  @override
  String get searchFilterLanguage => 'Språk';

  @override
  String get searchFilterAll => 'Alla';

  @override
  String get searchAutocompleteLabel => 'Förslag';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultat',
      one: '1 resultat',
      zero: 'Inga resultat',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Skriv in en låt, artist eller textrad att söka efter.';

  @override
  String get searchCatalogEmptyQuery =>
      'Skriv in en låt eller artist att söka efter.';

  @override
  String get searchNoResults => 'Inga låtar hittades. Prova en annan sökning.';

  @override
  String get searchLoading => 'Söker efter låtar…';

  @override
  String get searchError => 'Det gick inte att slutföra sökningen.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Senaste';

  @override
  String get searchFavoritesTab => 'Favoriter';

  @override
  String get searchSuggested => 'Föreslagen träff';

  @override
  String get searchAlternatives => 'Andra träffar';

  @override
  String get searchCompare => 'Jämför versioner';

  @override
  String get searchChooseVersion => 'Välj den här versionen';

  @override
  String get searchFullPreview => 'Fullständig förhandsvisning';

  @override
  String get searchArrangementNotes => 'Arrangemangsanteckningar';

  @override
  String get searchOpenLyrics => 'Öppna låttexten';

  @override
  String get searchContributions => 'Använda källor';

  @override
  String get searchVersionChecking => 'Kontrollerar den här versionen…';

  @override
  String get searchVersionUnavailable =>
      'Den här versionen kan inte användas. Välj en annan version.';

  @override
  String get searchPreviewUnavailable =>
      'Förhandsvisning av låttexten är inte tillgänglig.';

  @override
  String get searchSongMatch => 'Låtträff';

  @override
  String get searchRecordingMatch => 'Inspelningsträff';

  @override
  String get searchMatchUnverified => 'Inspelningen är inte verifierad';

  @override
  String get searchMatchExact => 'Exakt inspelningsträff';

  @override
  String get searchMatchPossible => 'Möjlig träff';

  @override
  String get searchAvailability => 'Tillgänglighet';

  @override
  String get searchLyricsAvailable => 'Låttext finns';

  @override
  String get searchLyricsUnavailable => 'Låttext saknas';

  @override
  String get searchChordsAvailable => 'Ackord finns';

  @override
  String get searchChordsUnavailable => 'Inga ackord';

  @override
  String get searchTimingAvailable => 'Tidsinställning finns';

  @override
  String get searchTimingUnavailable => 'Ingen tidsinställning';

  @override
  String get searchDurationUnknown => 'Okänd längd';

  @override
  String searchRating(String rating) {
    return 'Betyg $rating';
  }

  @override
  String get searchSourceLabel => 'Källa';

  @override
  String get searchPreferredSourceLabel => 'Föredragen källa';

  @override
  String get searchPreferredSourceHint =>
      'Resultat kan även komma från andra aktiverade sökkällor.';

  @override
  String get searchMetadata => 'Låtinformation';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Artist';

  @override
  String get searchYear => 'År';

  @override
  String get searchLanguage => 'Språk';

  @override
  String get searchViewVersions => 'Visa versioner';

  @override
  String get searchSaved => 'Låten har sparats i ditt bibliotek.';

  @override
  String get searchSaveOpenLyrics => 'Spara och öppna texten';

  @override
  String get searchOtherResults => 'Andra resultat';

  @override
  String get searchSaveFailed => 'Det gick inte att spara låten.';

  @override
  String get homeRecentSongs => 'Senaste låtar';

  @override
  String get homeRecentlyPlayed => 'Nyligen spelade';

  @override
  String get homeFavorites => 'Favoriter';

  @override
  String get homeHistory => 'Historik';

  @override
  String get homeHistoryClear => 'Rensa historik';

  @override
  String get homeHistoryCleared => 'Historiken har rensats.';

  @override
  String get homeHistoryEmpty => 'Låtar som du öppnar visas här.';

  @override
  String get homeFavoritesEmpty => 'Dina favoritlåtar och setlistor visas här.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objekt visas',
      one: '1 objekt visas',
      zero: '0 objekt visas',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty => 'Dina senaste låtar och setlistor visas här.';

  @override
  String get homeTimelineLabel => 'Historikens tidslinje';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Fullständig historik';

  @override
  String get homeShowFavorites => 'Visa favoriter';

  @override
  String get homeShowRecent => 'Visa senaste';

  @override
  String get songsTitle => 'Låtar';

  @override
  String get songsEmpty => 'Dina låtar visas här.';

  @override
  String get songsEmptySearch => 'Inga låtar matchar sökningen.';

  @override
  String get songsAdd => 'Lägg till låt';

  @override
  String get songsSortAlphabetical => 'Sortera alfabetiskt';

  @override
  String get songsAlphabetNavigation => 'Låtregister';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Öppnad $count gånger',
      one: 'Öppnad 1 gång',
      zero: 'Aldrig öppnad',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'Lägg till i favoriter';

  @override
  String get songFavoriteRemove => 'Ta bort från favoriter';

  @override
  String get songMenuLabel => 'Låtåtgärder';

  @override
  String get songInfo => 'Låtinformation';

  @override
  String get setlistMenuLabel => 'Setliståtgärder';

  @override
  String get songAddToSetlist => 'Lägg till i setlista';

  @override
  String get songCopyChordPro => 'Kopiera ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Ta bort låten?';

  @override
  String get songDeleteConfirmMessage => 'Låten tas bort från ditt bibliotek.';

  @override
  String get songDeleted => 'Låten har tagits bort.';

  @override
  String get setlistsTitle => 'Setlistor';

  @override
  String get setlistsEmpty =>
      'Skapa en setlista inför nästa repetition eller spelning.';

  @override
  String get setlistsEmptySearch => 'Inga setlistor matchar sökningen.';

  @override
  String get setlistCreate => 'Ny setlista';

  @override
  String get setlistNameHint => 'Setlistans namn';

  @override
  String get setlistNotes => 'Anteckningar';

  @override
  String get setlistEntryOverride => 'Separat tonart och capo för låten';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count låtar',
      one: '1 låt',
      zero: 'Inga låtar',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Minst $duration';
  }

  @override
  String get setlistDurationUnknown => 'Okänd längd';

  @override
  String setlistActivity(String date) {
    return 'Senaste aktivitet $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Skapad $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Redigerad $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Senast spelad $date';
  }

  @override
  String get setlistSongsEmpty => 'Setlistan innehåller inga låtar ännu.';

  @override
  String get setlistAddSongs => 'Lägg till låtar';

  @override
  String get setlistReorder => 'Ändra låtordning';

  @override
  String setlistMoveSongUp(String song) {
    return 'Flytta ”$song” uppåt';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Flytta ”$song” nedåt';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Ta bort ”$song” från setlistan';
  }

  @override
  String get setlistDuplicate => 'Duplicera setlista';

  @override
  String get setlistFavoriteAdd => 'Lägg till setlista i favoriter';

  @override
  String get setlistFavoriteRemove => 'Ta bort setlista från favoriter';

  @override
  String get setlistShare => 'Dela som OpenSong';

  @override
  String get setlistSharePdf => 'Dela som PDF';

  @override
  String get setlistPrint => 'Skriv ut';

  @override
  String get setlistDeleteConfirmTitle => 'Ta bort setlistan?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Setlistan tas bort. Låtarna i ditt bibliotek finns kvar.';

  @override
  String get setlistDeleted => 'Setlistan har tagits bort.';

  @override
  String get readerTitle => 'Låttexter';

  @override
  String get readerNoLyrics => 'Låttexten har inte lagts till ännu.';

  @override
  String get readerShowChords => 'Visa ackord';

  @override
  String get readerHideChords => 'Dölj ackord';

  @override
  String get readerTranspose => 'Transponera ackord';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count halvtoner',
      one: '1 halvton',
      zero: '0 halvtoner',
    );
    return 'Transponera $_temp0';
  }

  @override
  String get readerSaved => 'Sparad';

  @override
  String get readerEdit => 'Redigera låttext och information';

  @override
  String get playerPlay => 'Spela';

  @override
  String get playerPause => 'Pausa';

  @override
  String get playerResume => 'Återuppta rullningen av låttexten';

  @override
  String get playerSeek => 'Uppspelningsposition';

  @override
  String playerElapsed(String time) {
    return 'Förfluten tid $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Återstående tid $time';
  }

  @override
  String get playerTimingMode => 'Rullningsläge';

  @override
  String get playerTimedLyrics => 'Tidsinställd låttext';

  @override
  String get playerStartScroll => 'Starta automatisk rullning';

  @override
  String get playerEstimatedPace => 'Uppskattat tempo';

  @override
  String get playerScrollSpeed => 'Rullningshastighet';

  @override
  String playerEstimatedDuration(String time) {
    return 'Beräknad längd: $time';
  }

  @override
  String get playerLyricsOnly => 'Rulla låttext · inget ljud';

  @override
  String get playerManualScroll => 'Manuell rullning';

  @override
  String get playerTimingStatusReady =>
      'Låttexten rullar i takt med de tillgängliga tidsmarkeringarna.';

  @override
  String get playerTimingStatusEstimated =>
      'Rullningstempot uppskattas utifrån låtens längd.';

  @override
  String get playerTimingStatusManual => 'Rulla låttexten själv.';

  @override
  String get playerTimingStatusUnavailable =>
      'Tidsinställd rullning är inte tillgänglig för den här låten.';

  @override
  String get playerDurationUnknown =>
      'Lägg till låtens längd för att använda uppskattad rullning.';

  @override
  String get playerProgressLabel => 'Låtens förlopp';

  @override
  String get playerCurrentSection => 'Aktuell del';

  @override
  String get playerPreviousSection => 'Föregående del';

  @override
  String get playerNextSection => 'Nästa del';

  @override
  String get playerPreviousSectionSong =>
      'Föregående del · håll för att gå till föregående låt i setlistan';

  @override
  String get playerNextSectionSong =>
      'Nästa del · håll för att gå till nästa låt i setlistan';

  @override
  String get playerPreviousSong => 'Föregående låt';

  @override
  String get playerNextSong => 'Nästa låt';

  @override
  String get editorTitle => 'Redigera låt';

  @override
  String get editorTitleField => 'Låttitel';

  @override
  String get editorArtistField => 'Artist';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Låttext';

  @override
  String get editorChordsField => 'Ackord';

  @override
  String get editorKeyField => 'Tonart';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Stämning';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Längd';

  @override
  String get editorTimeSignatureField => 'Taktart';

  @override
  String get editorLanguageField => 'Språk';

  @override
  String get editorYearField => 'År';

  @override
  String get editorComposerField => 'Kompositör';

  @override
  String get editorLyricistField => 'Textförfattare';

  @override
  String get editorCopyrightField => 'Upphovsrätt';

  @override
  String get editorLicenseField => 'Licens';

  @override
  String get songInfoSources => 'Källor och medverkande';

  @override
  String get searchMatchSameSong => 'Samma låt, inspelningen är inte bekräftad';

  @override
  String get searchMatchNeedsAgreement =>
      'Ackordbladet behöver bekräftas mot låttexten';

  @override
  String get searchMatchDifferentLyrics =>
      'Låttexten skiljer sig från den valda låten';

  @override
  String get searchMatchCombinedSources =>
      'Informationen har sammanställts från flera källor';

  @override
  String get searchCombinedLabel => 'Kombinerat';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count låtträffar',
      one: '1 låtträff',
      zero: '0 låtträffar',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count källversioner',
      one: '1 källversion',
      zero: '0 källversioner',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Bästa tillgängliga träff';

  @override
  String get providerDescriptionUnknown => 'Låtkälla';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Ladda ned en ChordPro-fil från källan och importera den sedan.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Ladda ned filen med ett kostnadsfritt konto och importera den sedan.';

  @override
  String get providerDescPublicChordSheets => 'Offentliga ackordblad.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Historiska låttexter licensieras per verk.';

  @override
  String get providerDescLicensedCatalog =>
      'Licensierad katalog med låttexter.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Originallåtar under licensen Creative Commons BY.';

  @override
  String get providerDescPerSongLicense => 'Låttexter licensieras per låt.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Endast information om inspelning och utgivning.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Endast information om kompositionen.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Omslagsbild finns endast för exakta inspelningsträffar.';

  @override
  String get providerCapabilityLyrics => 'Låttexter';

  @override
  String get providerCapabilityChords => 'Ackord';

  @override
  String get providerCapabilityTiming => 'Tidsinställda låttexter';

  @override
  String get providerCapabilitySearch => 'Sökning';

  @override
  String get providerCapabilityMetadata => 'Låtinformation';

  @override
  String get editorArtworkField => 'Omslagslänk';

  @override
  String get editorLyricsHint =>
      'Ackord inom [C]-hakparenteser; avsnittsmarkörer på egna rader.';

  @override
  String get editorSave => 'Spara ändringar';

  @override
  String get editorSaved => 'Ändringarna har sparats.';

  @override
  String get editorSaveFailed => 'Det gick inte att spara ändringarna.';

  @override
  String get editorSaveConflict =>
      'Låten ändrades på ett annat ställe. Dina ändringar sparades som en separat kopia.';

  @override
  String get editorUnsavedTitle => 'Förkasta ändringarna?';

  @override
  String get editorUnsavedMessage => 'Dina ändringar har inte sparats.';

  @override
  String get editorFieldRequired => 'Ange en låttitel.';

  @override
  String get settingsTitle => 'Inställningar';

  @override
  String get settingsAppearance => 'Utseende';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Använd enhetens inställning';

  @override
  String get settingsThemeLight => 'Ljust';

  @override
  String get settingsThemeDark => 'Mörkt';

  @override
  String get settingsColorPalette => 'Färgpalett';

  @override
  String get settingsFont => 'Typsnitt';

  @override
  String get settingsTextSize => 'Textstorlek';

  @override
  String get settingsLyricsPreview => 'Förhandsvisning av låttext';

  @override
  String get settingsPlayer => 'Låttextspelare';

  @override
  String get settingsLyricHighlight => 'Markering av aktuell textrad';

  @override
  String get settingsHighlightBackgroundUnderline =>
      'Bakgrund + understrykning';

  @override
  String get settingsHighlightBackground => 'Bakgrund';

  @override
  String get settingsHighlightUnderline => 'Understrykning';

  @override
  String get settingsHighlightContrast => 'Kontrasterande textfärg';

  @override
  String get settingsHighlightNone => 'Ingen';

  @override
  String get settingsDefaultShowChords => 'Visa ackord som standard';

  @override
  String get settingsDefaultAutoscroll =>
      'Starta rullning av låttext automatiskt';

  @override
  String get settingsDefaultTiming => 'Standardläge för rullning';

  @override
  String get settingsLanguage => 'Appspråk';

  @override
  String get settingsLanguageSystem => 'Använd enhetens språk';

  @override
  String get settingsLanguageEnglish => 'Engelska';

  @override
  String get settingsLanguageBulgarian => 'Bulgariska';

  @override
  String get settingsLanguageUkrainian => 'Ukrainska';

  @override
  String get settingsSources => 'Källor för låttexter';

  @override
  String settingsSourceEnabled(String source) {
    return 'Aktivera källan $source';
  }

  @override
  String get settingsSourceRefresh => 'Uppdatera listan över källor';

  @override
  String get settingsSourcesUpdated => 'Källorna har uppdaterats.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Det gick inte att uppdatera källorna.';

  @override
  String get settingsImport => 'Importera låtar';

  @override
  String get settingsImportChordPro => 'Importera ChordPro-fil';

  @override
  String get settingsImportSetlist => 'Importera setlistfil';

  @override
  String get settingsImportSuccess => 'Importen är klar.';

  @override
  String get settingsImportFailed => 'Det gick inte att importera filen.';

  @override
  String get settingsImportUnsupported => 'Den här filtypen stöds inte.';

  @override
  String get settingsShareSong => 'Dela som ChordPro';

  @override
  String get settingsSharePdf => 'Dela som PDF';

  @override
  String get settingsCopySong => 'Kopiera till urklipp';

  @override
  String get settingsPrintSong => 'Skriv bara ut låten';

  @override
  String get settingsPrintSetlist => 'Skriv ut setlista med låttexter';

  @override
  String get settingsExportFailed => 'Det gick inte att förbereda filen.';

  @override
  String get settingsCopied => 'Kopierat till urklipp.';

  @override
  String get settingsAbout => 'Om';

  @override
  String get settingsPrivacy => 'Integritet';

  @override
  String get settingsLegal => 'Juridiskt';

  @override
  String get settingsClearHistory => 'Rensa historik';

  @override
  String get settingsClearHistoryConfirm =>
      'Rensar den senaste aktiviteten för låtar och setlistor. Behåller sparade låtar, favoriter, setlistor och inställningar.';

  @override
  String get settingsHistoryCleared => 'Historiken har rensats.';

  @override
  String get accountTitle => 'Konto och synkronisering';

  @override
  String get accountICloudBenefits =>
      'Använd ditt Apple-konto för att synkronisera låtar och låtlistor privat med iCloud. Ändringar synkroniseras automatiskt när du har anslutit.';

  @override
  String get accountICloudUnavailable =>
      'iCloud är inte tillgängligt. Kontrollera ditt Apple-konto och åtkomsten till iCloud i systeminställningarna och försök igen.';

  @override
  String get accountConnectICloud => 'Anslut iCloud';

  @override
  String get accountDisconnectICloud => 'Koppla från iCloud';

  @override
  String get accountUnavailable =>
      'Synkronisering kräver en version av Singbook där inloggning med Google har konfigurerats. I den här versionen sparas låtarna endast på den här enheten.';

  @override
  String get accountSyncNow => 'Synkronisera nu';

  @override
  String get accountConnected =>
      'Ansluten. Välj Synkronisera nu för att uppdatera säkerhetskopian.';

  @override
  String get accountSignIn => 'Anslut konto';

  @override
  String get accountSignOut => 'Logga ut';

  @override
  String get accountChange => 'Byt konto';

  @override
  String get accountSignedOut => 'Inte ansluten';

  @override
  String get accountSyncing => 'Synkroniserar ditt bibliotek…';

  @override
  String get accountSynced => 'Biblioteket har synkroniserats.';

  @override
  String get accountSyncFailed => 'Det gick inte att synkronisera biblioteket.';

  @override
  String get accessibilityFavorite => 'Favorit';

  @override
  String get accessibilityNotFavorite => 'Inte en favorit';

  @override
  String get accessibilitySearchField => 'Sök låtar';

  @override
  String get accessibilityClearSearch => 'Rensa söktexten';

  @override
  String accessibilitySongMenu(String song) {
    return 'Åtgärder för $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Åtgärder för $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Visa låtar i $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Dölj låtar i $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Uppspelningsförlopp, $percent procent';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Historikens tidslinje, $date';
  }

  @override
  String get loading => 'Läser in…';

  @override
  String get loadingSongs => 'Läser in låtar…';

  @override
  String get loadingSetlists => 'Läser in setlistor…';

  @override
  String get errorGeneric => 'Något gick fel.';

  @override
  String get errorOffline => 'Det verkar som att du är offline.';

  @override
  String get errorPermission => 'Du måste ge behörighet för att fortsätta.';

  @override
  String get emptyFiltered => 'Inga objekt matchar de här filtren.';

  @override
  String get unknownValue => 'Okänt';

  @override
  String get durationUnknown => 'Okänd längd';

  @override
  String get metadataNotSet => 'Inte angivet';

  @override
  String get dateToday => 'I dag';

  @override
  String get dateYesterday => 'I går';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count låtar',
      one: '1 låt',
      zero: 'Inga låtar',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Marinblå';

  @override
  String get settingsPaletteSage => 'Salviagrön';

  @override
  String get settingsPaletteOcean => 'Havsblå';

  @override
  String get settingsPaletteClay => 'Lerfärgad';

  @override
  String get settingsPalettePlum => 'Plommonlila';

  @override
  String get settingsFontSystem => 'System';

  @override
  String get settingsFontSerif => 'Serif';

  @override
  String get settingsFontMonospace => 'Fast bredd';

  @override
  String get settingsLyricsPreviewExample =>
      'När morgonen kommer sjunger vi igen.';

  @override
  String get settingsPreviewSongTitle => 'Morgonsång';

  @override
  String get settingsPreviewArtist => 'Exempelarrangemang';

  @override
  String get settingsPreviewCurrentLine => 'När morgonen kommer';

  @override
  String get settingsPreviewNextLine => 'Vi sjunger igen.';

  @override
  String get settingsPlayerSections => 'Avsnittsrubriker';

  @override
  String get settingsPlayerControls => 'Uppspelningspanel';

  @override
  String get settingsPlayerAutoscroll => 'Automatisk rullning';

  @override
  String get settingsSystemShort => 'Enhet';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Kontrollerar källor för låttexter: $checked av $total klara.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Inga användbara låttexter hittades.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Den valda låten kontrollerades mot de aktiverade källorna, men ingen av dem hittade en användbar version av låttexten.';

  @override
  String get searchDiscoveryError =>
      'Det gick inte att kontrollera källorna för låttexter.';

  @override
  String get searchDiscoveryRetry => 'Sök efter låttexter igen';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count källor otillgängliga',
      one: '1 källa otillgänglig',
      zero: '0 källor otillgängliga',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Kontrollera anslutningen och försök igen.';

  @override
  String get searchProviderChecks => 'Källkontroller';

  @override
  String get searchProviderPending => 'Kontrollerar';

  @override
  String get searchProviderFound => 'Träff hittad';

  @override
  String get searchProviderRejected => 'Matchar inte';

  @override
  String get searchProviderFailed => 'Kontrollen misslyckades';

  @override
  String get searchProviderUnavailable => 'Inga användbara låttexter';

  @override
  String get searchCatalogFilterHint =>
      'Välj en låt för att filtrera textversioner efter ackord, tidsinställning eller språk.';

  @override
  String get startupErrorTitle => 'Det gick inte att öppna biblioteket.';

  @override
  String setlistCopyName(String name) {
    return 'Kopia av $name';
  }

  @override
  String get setlistSongMissing => 'Låten saknas';

  @override
  String get settingsImportTooLarge => 'Filen är för stor för att importera.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Hoppa till $letter';
  }

  @override
  String get actionDiscard => 'Förkasta';

  @override
  String get editorKeepEditing => 'Fortsätt redigera';

  @override
  String get settingsDefaultShowChordsHint =>
      'Visa ackord ovanför låttexten när det finns ackord.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Låttexten rullas med låten. Används inte i manuellt rullningsläge.';

  @override
  String get accountUnavailableTitle => 'Synkronisering är inte konfigurerad';

  @override
  String get accountSignedOutBenefits =>
      'När du ansluter Google Drive synkroniseras biblioteket. Ändringar av låtar synkroniseras sedan automatiskt.';

  @override
  String get accountManualSyncHint =>
      'Du kan också trycka på Synkronisera nu för att synkronisera biblioteket.';

  @override
  String get accountSignInWithGoogle => 'Logga in med Google';

  @override
  String get accountWorking => 'Arbetar…';

  @override
  String get accountNeverSynced => 'Aldrig synkroniserat';

  @override
  String get accountSyncedJustNow => 'Synkroniserat nyss';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synkroniserat för $count minuter sedan',
      one: 'Synkroniserat för 1 minut sedan',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synkroniserat för $count timmar sedan',
      one: 'Synkroniserat för 1 timme sedan',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synkroniserat för $count dagar sedan',
      one: 'Synkroniserat för 1 dag sedan',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ändringar i konflikt sparades som kopior',
      one: '1 ändring i konflikt sparades som en kopia',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Samma låt eller setlista redigerades på två ställen. Inget gick förlorat: den andra versionen sparades som en separat kopia.';

  @override
  String get accountReviewConflicts => 'Granska kopior';

  @override
  String get songsConflictFilterActive => 'Visar endast konfliktkopior';

  @override
  String get songsConflictFilterClear => 'Visa alla låtar';

  @override
  String get songsConflictBadge => 'Konfliktkopia';

  @override
  String get songsConflictEmpty => 'Inga konfliktkopior.';

  @override
  String get accountAutoSync => 'Synkronisera automatiskt';

  @override
  String get accountAutoSyncHint =>
      'Synkronisering sker efter anslutning och efter att en låt har lagts till, redigerats eller tagits bort.';

  @override
  String get accountDriveFolder => 'Google Drive biblioteksmapp';

  @override
  String get accountPrivateDriveFolder => 'Privat Singbook-mapp';

  @override
  String get accountChooseDriveFolder => 'Välj mapp';

  @override
  String get accountDriveFolderMoveTitle => 'Flytta ditt Singbook-bibliotek?';

  @override
  String get accountDriveFolderMoveBody =>
      'Välj en synlig Google Drive-mapp. Singbook kommer att kopiera och verifiera dina låtar och setlistor där innan du byter till den. Originalfilerna stannar på sin tidigare plats som en säkerhetskopia. Andra filer lämnas ifred. ChordPro-filer som du importerar till den här mappen används för synkronisering och tar emot Singbook-metadata.';

  @override
  String get accountImportChordPro => 'Importera ChordPro från Drive';

  @override
  String get accountImportChordProHint =>
      'Välj .cho-filer att lägga till i det här biblioteket. Filer som redan finns i mappen antas; filer på andra ställen kopieras hit.';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'Val av Drive-mapp är inte tillgängligt';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'Välj en synlig Drive-mapp med Google Drives väljare på en enhet som stöds.';

  @override
  String get syncErrorDriveFolderMissing =>
      'Mappen Singbook Drive är inte tillgänglig';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Välj mappen igen eller återställ den i Google Drive.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook behöver åtkomst till den här Drive-mappen';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Välj mappen igen för att ge åtkomst och synkronisera sedan ditt bibliotek.';

  @override
  String get syncErrorFolderMigration => 'Biblioteket kunde inte flyttas ännu';

  @override
  String get syncErrorFolderMigrationHint =>
      'Ditt tidigare bibliotek är fortfarande säkert. Kontrollera anslutningen och välj mappen igen för att försöka igen.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Välj först en synlig Drive-mapp';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'En synlig biblioteksmapp behövs innan du importerar filer från Drive.';

  @override
  String get accountSignOutTitle => 'Logga ut från det här kontot?';

  @override
  String get accountSignOutBody =>
      'Dina låtar och setlistor finns kvar på den här enheten. De säkerhetskopieras eller synkroniseras inte förrän du loggar in igen.';

  @override
  String get accountUseDifferent => 'Använd ett annat konto';

  @override
  String get accountSignInAgain => 'Logga in igen';

  @override
  String get accountChooseAction => 'Välj hur du vill fortsätta';

  @override
  String get accountChangedTitle => 'Ett annat Google-konto';

  @override
  String get accountChangedBody =>
      'Den här enheten synkroniserades senast med ett annat Google-konto. Välj vad som ska hända med låtarna och setlistorna på den här enheten.';

  @override
  String get accountChangedMerge => 'Slå ihop med det nya kontot';

  @override
  String get accountChangedMergeHint =>
      'Behåll allt på den här enheten och lägg till det i det nya kontot.';

  @override
  String get accountChangedReplace => 'Ersätt med det nya kontots bibliotek';

  @override
  String get accountChangedReplaceHint =>
      'Låtar på den här enheten som inte finns i det nya kontot tas bort.';

  @override
  String get accountChangedSignOut => 'Avbryt och logga ut';

  @override
  String get accountStatusSignedOut =>
      'Konto och synkronisering: inte inloggad';

  @override
  String get accountStatusSignedIn => 'Konto och synkronisering: inloggad';

  @override
  String get accountStatusSyncing => 'Konto och synkronisering: synkroniserar';

  @override
  String get accountStatusSynced =>
      'Konto och synkronisering: biblioteket är uppdaterat';

  @override
  String get accountStatusError =>
      'Konto och synkronisering: problem, tryck för att granska';

  @override
  String get accountNoticeConflicts =>
      'Vissa låtar redigerades på två ställen. Kopior sparades.';

  @override
  String get accountNoticeSignedIn => 'Inloggad.';

  @override
  String get accountNoticeSignedOut =>
      'Utloggad. Dina låtar finns kvar på den här enheten.';

  @override
  String get syncErrorNotConfigured =>
      'Synkronisering är inte konfigurerad i den här versionen.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Använd en version av Singbook med inloggning via Google konfigurerad.';

  @override
  String get syncErrorOAuthClientConfiguration =>
      'Google avvisade inloggningskonfigurationen för den här versionen.';

  @override
  String get syncErrorOAuthClientConfigurationHint =>
      'Kontrollera att det konfigurerade OAuth-ID:t tillhör Singbooks skrivbordsklient.';

  @override
  String get syncErrorNotSignedIn => 'Du är inte inloggad.';

  @override
  String get syncErrorNotSignedInHint =>
      'Logga in för att synkronisera biblioteket.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google kräver att du loggar in igen.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Logga in igen för att fortsätta synkronisera. Dina låtar är säkra på den här enheten.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook har inte behörighet att använda Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Logga in igen och tillåt åtkomst till Drive när du blir tillfrågad.';

  @override
  String get syncErrorRateLimited =>
      'Google begränsar antalet förfrågningar just nu.';

  @override
  String get syncErrorRateLimitedHint => 'Vänta några minuter och försök igen.';

  @override
  String get syncErrorStorageFull => 'Ditt Google Drive är fullt.';

  @override
  String get syncErrorStorageFullHint =>
      'Frigör utrymme på Drive och försök igen.';

  @override
  String get syncErrorNetwork => 'Det gick inte att nå Google.';

  @override
  String get syncErrorNetworkHint =>
      'Kontrollera internetanslutningen och försök igen.';

  @override
  String get syncErrorAccountChanged => 'Ett annat Google-konto användes.';

  @override
  String get syncErrorAccountChangedHint =>
      'Välj om du vill slå ihop biblioteket på den här enheten med det eller ersätta det.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Det synkroniserade biblioteket är för stort för att Singbook ska kunna hantera det.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Ta bort några låtar eller setlistor från det synkroniserade biblioteket och försök igen.';

  @override
  String get syncErrorSignInFailed => 'Inloggningen slutfördes inte.';

  @override
  String get syncErrorSignInFailedHint => 'Försök logga in igen.';

  @override
  String get syncErrorGeneric => 'Det gick inte att synkronisera biblioteket.';

  @override
  String get syncErrorGenericHint =>
      'Försök igen om en stund. Dina låtar är fortfarande säkra på den här enheten.';

  @override
  String get editorDurationInvalid =>
      'Ange sekunder, eller minuter och sekunder, till exempel 3:45.';

  @override
  String get editorNumberInvalid => 'Ange ett tal.';

  @override
  String get accountReplaceConfirmTitle => 'Ta bort lokala låtar?';

  @override
  String get accountReplaceConfirmBody =>
      'Låtar och setlistor på den här enheten som inte finns i det nya kontot tas bort permanent. Det går inte att ångra.';

  @override
  String get accountReplaceConfirmAction => 'Ta bort och ersätt';

  @override
  String get accountSuspiciousTitle => 'Objekt saknas på Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count objekt som den här enheten har synkroniserat tidigare saknas på Google Drive.',
      one:
          '$count objekt som den här enheten har synkroniserat tidigare saknas på Google Drive.',
    );
    return '$_temp0 Det kan hända om appdata har rensats i Googles inställningar. Inget har tagits bort ännu.';
  }

  @override
  String get accountSuspiciousDelete => 'Ta bort dem här också';

  @override
  String get accountSuspiciousKeep =>
      'Behåll mina låtar och ladda upp dem igen';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ta bort $count objekt från den här enheten?',
      one: 'Ta bort $count objekt från den här enheten?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Dessa låtar och setlistor tas bort permanent från den här enheten. Det går inte att ångra.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Ta bort från den här enheten';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Objekt saknas på Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Inget har tagits bort. Välj om du vill ta bort dem här också eller ladda upp dem igen.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive ändrades under synkroniseringen.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Inget har gått förlorat. Synkronisera igen för att hämta de senaste ändringarna.';

  @override
  String get syncErrorInvalidLocalData =>
      'Vissa data på den här enheten kunde inte synkroniseras.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'En låt eller setlista kunde inte läsas. Importera eller skapa den igen och synkronisera sedan.';

  @override
  String get syncErrorNoAccountChange =>
      'Det finns ingen kontoändring att lösa.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Synkronisera igen för att fortsätta.';

  @override
  String get accountSyncWarningTitle =>
      'Synkroniserat, men vissa filer hoppades över';

  @override
  String get accountSyncWarningBody =>
      'Vissa filer kunde inte användas och lämnades som de var. Allt annat är uppdaterat.';

  @override
  String get accountSyncWarningTooLarge =>
      'En fil var för stor för att synkroniseras och hoppades över. Allt annat är uppdaterat.';

  @override
  String get accountSyncWarningInvalid =>
      'En fil kunde inte läsas och hoppades över. Allt annat är uppdaterat.';

  @override
  String get accountNoticeSyncSkipped =>
      'Synkroniserat. Vissa filer hoppades över.';

  @override
  String get settingsExportPdfTooLarge =>
      'Den här PDF-filen skulle bli för stor. Prova med färre låtar eller dela som text.';

  @override
  String get settingsTimingTooLarge => 'Tidsdata är för stora (över 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Den här säkerhetskopian innehåller samma låt två gånger, så inget importerades.';

  @override
  String get setlistSaveConflict =>
      'Setlistan ändrades någon annanstans. Dina ändringar sparades som en separat kopia.';

  @override
  String get sectionVerse => 'Vers';

  @override
  String get sectionChorus => 'Refräng';

  @override
  String get sectionBridge => 'Brygga';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pre-refräng';

  @override
  String get sectionPostChorus => 'Post-refräng';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Mellanspel';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Omkväde';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Avslutning';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tillgängliga versioner',
      one: '1 tillgänglig version',
      zero: '0 Tillgängliga versioner',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Otillgängliga versioner',
      one: '1 otillgänglig version',
      zero: '0 Otillgängliga versioner',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Hoppa till avsnitt';

  @override
  String get searchVersionDetails => 'Versionsinformation';

  @override
  String get searchSelectedRecording => 'Vald inspelning';

  @override
  String get searchVersionDuration => 'Versionens längd';

  @override
  String get searchSourceOptions => 'Källalternativ';

  @override
  String get actionUndo => 'Ångra';

  @override
  String setlistEntryRemoved(String song) {
    return '$song har tagits bort från spellistan';
  }

  @override
  String get backupTitle => 'Säkerhetskopiering och återställning';

  @override
  String get backupExport => 'Exportera säkerhetskopia';

  @override
  String get backupSaveToDevice => 'Spara säkerhetskopia på enheten';

  @override
  String get backupRestore => 'Återställ säkerhetskopia';

  @override
  String get backupIncludePreferences => 'Inkludera appinställningar';

  @override
  String get backupRestorePreferences => 'Återställ appinställningar';

  @override
  String get backupMerge => 'Lägg till i det här biblioteket';

  @override
  String get backupMergeHint =>
      'Behåll lokala ändringar och lägg till låtar och spellistor från säkerhetskopian.';

  @override
  String get backupReplace => 'Ersätt det här biblioteket';

  @override
  String get backupReplaceHint =>
      'Ersätt alla låtar och spellistor på den här enheten med innehållet i säkerhetskopian.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Låtar: $songs · Spellistor: $setlists · Konflikter: $conflicts';
  }

  @override
  String get backupFailed =>
      'Det gick inte att slutföra åtgärden. Försök igen.';

  @override
  String get backupRestored => 'Säkerhetskopian har återställts.';

  @override
  String get backupLocalHint =>
      'Spara en kopia av biblioteket. Kontouppgifter och samtyckescookies tas aldrig med.';

  @override
  String get backupReplaceConfirm =>
      'Ersätta det nuvarande biblioteket? Det här kan inte ångras.';

  @override
  String get searchCheckOperations => 'Åtgärder';

  @override
  String get searchCheckCode => 'Resultatkod';

  @override
  String get searchCheckQueued => 'Väntar på att kontrollera den här källan.';

  @override
  String get searchCheckFetch => 'Läs in låttext';

  @override
  String get searchCheckValidate => 'Kontrollera låtmatchning';

  @override
  String get searchCheckCorroborate => 'Kontrollera textöverensstämmelse';

  @override
  String get searchCheckCompleted => 'Slutfört';

  @override
  String get searchCheckTimeout => 'Källan svarade inte i tid.';

  @override
  String get searchCheckBlocked => 'Källan blockerade begäran.';

  @override
  String get searchCheckRateLimited =>
      'Källan begränsar förfrågningar. Försök igen senare.';

  @override
  String get searchCheckNetwork =>
      'Det gick inte att nå källan. Kontrollera anslutningen.';

  @override
  String get searchCheckInvalid => 'Källan returnerade ett oläsbart svar.';

  @override
  String get searchCheckNotConfigured =>
      'Den här källan är inte konfigurerad i den här versionen.';

  @override
  String get searchCheckNoLyrics => 'Ingen matchande låttext hittades.';

  @override
  String get searchCheckFailed => 'Åtgärden kunde inte slutföras.';

  @override
  String get searchCheckNoHistory =>
      'Inga källkontroller har körts för den här jämförelsen.';

  @override
  String get searchVersionCredits => 'Medverkande';

  @override
  String get searchVersionMediaLinks => 'Relaterade länkar';

  @override
  String get searchCheckCancelled => 'Avbruten';

  @override
  String get searchCheckAmbiguous =>
      'Flera matchningar hittades. Den här källan behöver en mer specifik inspelning.';

  @override
  String get searchCheckIdentity =>
      'Den här källan behöver en identifierare för en inspelning eller ett verk.';

  @override
  String get searchCheckExtraction =>
      'Källan svarade, men låttexten kunde inte hämtas.';

  @override
  String get searchCheckBusy =>
      'Den här källan är upptagen. Försök igen senare.';

  @override
  String get searchCheckSelection =>
      'Välj ett specifikt resultat från den här källan.';

  @override
  String get playerChordsNone => 'Ingen';

  @override
  String get editorCustomValue => 'Annat…';

  @override
  String get editorStandardTuning => 'Standardstämning';

  @override
  String get editorExampleVerse =>
      '[C]En ny dag [G]kallar,\n[Am]vi följer ljuset hem till [F]oss.';

  @override
  String get editorExampleChorus =>
      '[F]Sjung den här sången [C]tillsammans,\n[G]låt melodin bära oss [C]vidare.';

  @override
  String get editorExampleBridge => '[Am]En rad till, lite [F]närmare.';

  @override
  String get playerEstimatedKey => 'Uppskattad tonart';

  @override
  String get songsLibraryView => 'Bibliotek';

  @override
  String get settingsStartupView => 'Starta i';

  @override
  String get settingsStartupViewHint =>
      'Välj låtvyn som visas när appen öppnas.';

  @override
  String get settingsStartupLastView => 'Senast öppnad';

  @override
  String get playerFullScreen => 'Helskärm';

  @override
  String get playerExitFullScreen => 'Avsluta helskärm';

  @override
  String get playerExpandControls => 'Visa uppspelningskontroller';

  @override
  String get playerCollapseControls => 'Dölj uppspelningskontroller';

  @override
  String get settingsShowSections => 'Visa avsnittsrubriker';

  @override
  String get settingsShowSectionsHint =>
      'Visa rubriker för verser, refräng och andra avsnitt i låttexten.';

  @override
  String get settingsShowPlayerControls => 'Visa uppspelningskontroller';

  @override
  String get settingsShowPlayerControlsHint =>
      'Du kan också trycka på eller svepa över spelarpanelen för att visa eller dölja den.';

  @override
  String get sourceAnalysisHeading => 'Analys av inskickat ljud (overifierad)';

  @override
  String sourceAnalysisCoverage(int shown, int total) {
    return 'Visar $shown av $total inskickade bidrag';
  }

  @override
  String sourceAnalysisSample(int number) {
    return 'Prov $number';
  }

  @override
  String get sourceAnalysisEstimatedTempo => 'Uppskattat tempo (BPM)';
}
