// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Dine sangtekster, akkorder og sætlister samlet, klar til øvning, scenen og alle steder, du spiller.';

  @override
  String get aboutMadeForSinging => 'Hver sang er klar.';

  @override
  String get aboutDetails =>
      'Søg i aktiverede kilder, og sammenlign sangtekster, akkorder, timing og optagelsesoplysninger, før du gemmer den version, du vil spille. Tilgængeligheden varierer efter sang og tjeneste.';

  @override
  String get aboutFindTitle => 'Find den rigtige version';

  @override
  String get aboutKeepTitle => 'Byg dit eget bibliotek';

  @override
  String get aboutKeepDetails =>
      'Rediger og transponer sange, behold dem i dit lokale bibliotek til offlinebrug, og del bærbare ChordPro-filer. Valgfri synkronisering med Google Drive bruger en privat appmappe på din Google-konto. Du kan også trykke på Synkronisér nu for at opdatere dine enheder.';

  @override
  String get aboutPlayTitle => 'Tag din sætliste med på scenen';

  @override
  String get aboutPlayDetails =>
      'Organiser sange i sætlister, vælg toneart for hver sang, og del OpenSong-sætlister. Tilpas læserens tekst, automatisk rulning af sangtekster, og udskriv sang-PDF’er. Singbook streamer eller afspiller ikke lyd.';

  @override
  String get aboutPrivacyTitle => 'Gratis, med biblioteket på din enhed';

  @override
  String get aboutPrivacyDetails =>
      'Singbook er gratis uden annoncer, analyse eller køb i appen. Dit gemte bibliotek bliver på din enhed; valgfri synkronisering bruger dit eget Google Drive. Onlineresultater kommer direkte fra uafhængige tredjepartstjenester og kan være utilgængelige eller ophavsretligt beskyttede. Singbook er ikke vært for deres indhold.';

  @override
  String get aboutWebsite => 'Singbooks website';

  @override
  String get aboutSourceCode => 'Kildekode på GitHub';

  @override
  String get aboutPublisher => 'Fra Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Appens sprog: $count';
  }

  @override
  String get aboutSupport => 'Support og feedback';

  @override
  String get menuTypeNewSong => 'Skriv en ny sang';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get navHome => 'Hjem';

  @override
  String get navSongs => 'Sange';

  @override
  String get navSetlists => 'Sanglister';

  @override
  String get navSettings => 'Indstillinger';

  @override
  String get navSettingsCompact => 'Indstillinger';

  @override
  String get navSearch => 'Søg';

  @override
  String get navBack => 'Tilbage';

  @override
  String get appExitBackAgain => 'Tryk på Tilbage igen for at afslutte';

  @override
  String get navClose => 'Luk';

  @override
  String get navMore => 'Flere handlinger';

  @override
  String get actionCancel => 'Annuller';

  @override
  String get actionSave => 'Gem';

  @override
  String get actionDone => 'Færdig';

  @override
  String get actionEdit => 'Rediger';

  @override
  String get actionDelete => 'Slet';

  @override
  String get actionShare => 'Del';

  @override
  String get actionPrint => 'Udskriv';

  @override
  String get actionCopy => 'Kopiér';

  @override
  String get actionClear => 'Ryd';

  @override
  String get actionRetry => 'Prøv igen';

  @override
  String get actionRefresh => 'Opdatér';

  @override
  String get actionImport => 'Importér';

  @override
  String get actionExport => 'Eksportér';

  @override
  String get actionExpand => 'Udvid';

  @override
  String get actionCollapse => 'Fold sammen';

  @override
  String get actionAdd => 'Tilføj';

  @override
  String get actionCreate => 'Opret';

  @override
  String get actionRemove => 'Fjern';

  @override
  String get actionDuplicate => 'Duplikér';

  @override
  String get actionMoveUp => 'Flyt op';

  @override
  String get actionMoveDown => 'Flyt ned';

  @override
  String get actionPrevious => 'Forrige';

  @override
  String get actionNext => 'Næste';

  @override
  String get searchHint => 'Søg efter sange, kunstnere eller sangtekster';

  @override
  String get searchCatalogHint => 'Søg efter en sang eller kunstner';

  @override
  String get searchChangeSong => 'Skift sang';

  @override
  String get searchSelectedPreview => 'Valgt forhåndsvisning';

  @override
  String get searchSubmit => 'Søg';

  @override
  String get searchFilters => 'Søgemuligheder';

  @override
  String get searchFiltersShow => 'Vis søgemuligheder';

  @override
  String get searchFiltersHide => 'Skjul søgemuligheder';

  @override
  String get searchFilterArtist => 'Kunstner';

  @override
  String get searchFilterTitle => 'Sangtitel';

  @override
  String get searchFilterLyrics => 'Sangtekster';

  @override
  String get searchFilterChords => 'Har akkorder';

  @override
  String get searchFilterTimed => 'Tidsinddelte sangtekster';

  @override
  String get searchFilterLanguage => 'Sprog';

  @override
  String get searchFilterAll => 'Alle';

  @override
  String get searchAutocompleteLabel => 'Forslag';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultater',
      one: '1 resultat',
      zero: 'Ingen resultater',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Indtast en sang, kunstner eller sangtekst, du vil søge efter.';

  @override
  String get searchCatalogEmptyQuery =>
      'Indtast en sang eller kunstner, du vil søge efter.';

  @override
  String get searchNoResults => 'Ingen sange fundet. Prøv en anden søgning.';

  @override
  String get searchLoading => 'Søger efter sange…';

  @override
  String get searchError => 'Søgningen kunne ikke gennemføres.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Seneste';

  @override
  String get searchFavoritesTab => 'Favoritter';

  @override
  String get searchSuggested => 'Foreslået match';

  @override
  String get searchAlternatives => 'Andre match';

  @override
  String get searchCompare => 'Sammenlign versioner';

  @override
  String get searchChooseVersion => 'Vælg denne version';

  @override
  String get searchFullPreview => 'Fuld forhåndsvisning';

  @override
  String get searchArrangementNotes => 'Bemærkninger om arrangementet';

  @override
  String get searchOpenLyrics => 'Åbn sangteksten';

  @override
  String get searchContributions => 'Anvendte kilder';

  @override
  String get searchVersionChecking => 'Kontrollerer denne version…';

  @override
  String get searchVersionUnavailable =>
      'Denne version kan ikke bruges. Vælg en anden version.';

  @override
  String get searchPreviewUnavailable =>
      'Ingen forhåndsvisning af sangteksten tilgængelig.';

  @override
  String get searchSongMatch => 'Sangmatch';

  @override
  String get searchRecordingMatch => 'Indspilningsmatch';

  @override
  String get searchMatchUnverified => 'Indspilningen er ikke bekræftet';

  @override
  String get searchMatchExact => 'Nøjagtigt indspilningsmatch';

  @override
  String get searchMatchPossible => 'Muligt match';

  @override
  String get searchAvailability => 'Tilgængelighed';

  @override
  String get searchLyricsAvailable => 'Sangtekst tilgængelig';

  @override
  String get searchLyricsUnavailable => 'Sangtekst ikke tilgængelig';

  @override
  String get searchChordsAvailable => 'Akkorder tilgængelige';

  @override
  String get searchChordsUnavailable => 'Ingen akkorder';

  @override
  String get searchTimingAvailable => 'Tidsinddeling tilgængelig';

  @override
  String get searchTimingUnavailable => 'Ingen tidsinddeling';

  @override
  String get searchDurationUnknown => 'Varighed ukendt';

  @override
  String searchRating(String rating) {
    return 'Bedømmelse $rating';
  }

  @override
  String get searchSourceLabel => 'Kilde';

  @override
  String get searchMetadata => 'Sangdetaljer';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Kunstner';

  @override
  String get searchYear => 'År';

  @override
  String get searchLanguage => 'Sprog';

  @override
  String get searchViewVersions => 'Se versioner';

  @override
  String get searchSaved => 'Sangen er gemt i dit bibliotek.';

  @override
  String get searchSaveOpenLyrics => 'Gem og åbn teksten';

  @override
  String get searchOtherResults => 'Andre resultater';

  @override
  String get searchSaveFailed => 'Sangen kunne ikke gemmes.';

  @override
  String get homeRecentSongs => 'Seneste sange';

  @override
  String get homeRecentlyPlayed => 'Afspillet for nylig';

  @override
  String get homeFavorites => 'Favoritter';

  @override
  String get homeHistory => 'Historik';

  @override
  String get homeHistoryClear => 'Ryd historik';

  @override
  String get homeHistoryCleared => 'Historikken er ryddet.';

  @override
  String get homeHistoryEmpty => 'Sange, du åbner, vises her.';

  @override
  String get homeFavoritesEmpty => 'Dine favoritsange og sanglister vises her.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementer vist',
      one: '1 element vist',
      zero: '0 elementer vist',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty => 'Dine seneste sange og sanglister vises her.';

  @override
  String get homeTimelineLabel => 'Historikforløb';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Hele historikken';

  @override
  String get homeShowFavorites => 'Vis favoritter';

  @override
  String get homeShowRecent => 'Vis seneste';

  @override
  String get songsTitle => 'Sange';

  @override
  String get songsEmpty => 'Dine sange vises her.';

  @override
  String get songsEmptySearch => 'Ingen sange matcher din søgning.';

  @override
  String get songsAdd => 'Tilføj sang';

  @override
  String get songsSortAlphabetical => 'Sortér alfabetisk';

  @override
  String get songsAlphabetNavigation => 'Sangindeks';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Åbnet $count gange',
      one: 'Åbnet én gang',
      zero: 'Aldrig åbnet',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'Føj til favoritter';

  @override
  String get songFavoriteRemove => 'Fjern fra favoritter';

  @override
  String get songMenuLabel => 'Sanghandlinger';

  @override
  String get songInfo => 'Sangdetaljer';

  @override
  String get setlistMenuLabel => 'Sanglistehandlinger';

  @override
  String get songAddToSetlist => 'Føj til sangliste';

  @override
  String get songCopyChordPro => 'Kopiér ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Slet sang?';

  @override
  String get songDeleteConfirmMessage => 'Sangen fjernes fra dit bibliotek.';

  @override
  String get songDeleted => 'Sangen er slettet.';

  @override
  String get setlistsTitle => 'Sanglister';

  @override
  String get setlistsEmpty =>
      'Opret en sangliste til din næste øvegang eller optræden.';

  @override
  String get setlistsEmptySearch => 'Ingen sanglister matcher din søgning.';

  @override
  String get setlistCreate => 'Ny sangliste';

  @override
  String get setlistNameHint => 'Sanglistens navn';

  @override
  String get setlistNotes => 'Notater';

  @override
  String get setlistEntryOverride => 'Sangspecifik toneart og capo';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sange',
      one: '1 sang',
      zero: 'Ingen sange',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Mindst $duration';
  }

  @override
  String get setlistDurationUnknown => 'Varighed ukendt';

  @override
  String setlistActivity(String date) {
    return 'Seneste aktivitet $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Oprettet $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Redigeret $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Sidst spillet $date';
  }

  @override
  String get setlistSongsEmpty =>
      'Denne sangliste indeholder ingen sange endnu.';

  @override
  String get setlistAddSongs => 'Tilføj sange';

  @override
  String get setlistReorder => 'Ændr rækkefølge på sange';

  @override
  String setlistMoveSongUp(String song) {
    return 'Flyt $song op';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Flyt $song ned';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Fjern $song fra sanglisten';
  }

  @override
  String get setlistDuplicate => 'Duplikér sangliste';

  @override
  String get setlistFavoriteAdd => 'Føj sangliste til favoritter';

  @override
  String get setlistFavoriteRemove => 'Fjern sangliste fra favoritter';

  @override
  String get setlistShare => 'Del som OpenSong';

  @override
  String get setlistSharePdf => 'Del som PDF';

  @override
  String get setlistPrint => 'Udskriv';

  @override
  String get setlistDeleteConfirmTitle => 'Slet sangliste?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Sanglisten fjernes. Sangene i dit bibliotek bevares.';

  @override
  String get setlistDeleted => 'Sanglisten er slettet.';

  @override
  String get readerTitle => 'Sangtekster';

  @override
  String get readerNoLyrics => 'Der er ikke tilføjet sangtekst endnu.';

  @override
  String get readerShowChords => 'Vis akkorder';

  @override
  String get readerHideChords => 'Skjul akkorder';

  @override
  String get readerTranspose => 'Transponér akkorder';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count halvtoner',
      one: '1 halvtone',
      zero: '0 halvtoner',
    );
    return 'Transponér $_temp0';
  }

  @override
  String get readerSaved => 'Gemt';

  @override
  String get readerEdit => 'Rediger sangtekst og detaljer';

  @override
  String get playerPlay => 'Afspil';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerResume => 'Fortsæt rulning af sangteksten';

  @override
  String get playerSeek => 'Afspilningsposition';

  @override
  String playerElapsed(String time) {
    return 'Forløbet tid $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Resterende tid $time';
  }

  @override
  String get playerTimingMode => 'Rulletilstand';

  @override
  String get playerTimedLyrics => 'Tidsinddelte sangtekster';

  @override
  String get playerStartScroll => 'Start automatisk rulning';

  @override
  String get playerEstimatedPace => 'Anslået tempo';

  @override
  String get playerScrollSpeed => 'Rullehastighed';

  @override
  String playerEstimatedDuration(String time) {
    return 'Anslået varighed: $time';
  }

  @override
  String get playerLyricsOnly => 'Rulning af sangtekst · ingen lyd';

  @override
  String get playerManualScroll => 'Manuel rulning';

  @override
  String get playerTimingStatusReady =>
      'Sangteksten følger den tilgængelige tidsinddeling.';

  @override
  String get playerTimingStatusEstimated =>
      'Rulletempoet er anslået ud fra sangens varighed.';

  @override
  String get playerTimingStatusManual => 'Rul selv gennem sangteksten.';

  @override
  String get playerTimingStatusUnavailable =>
      'Tidsinddelt rulning er ikke tilgængelig for denne sang.';

  @override
  String get playerDurationUnknown =>
      'Tilføj sangens varighed for at bruge anslået rulning.';

  @override
  String get playerProgressLabel => 'Sangens forløb';

  @override
  String get playerCurrentSection => 'Aktuelt afsnit';

  @override
  String get playerPreviousSection => 'Forrige afsnit';

  @override
  String get playerNextSection => 'Næste afsnit';

  @override
  String get playerPreviousSectionSong =>
      'Forrige afsnit · hold for forrige sang på sanglisten';

  @override
  String get playerNextSectionSong =>
      'Næste afsnit · hold for næste sang på sanglisten';

  @override
  String get playerPreviousSong => 'Forrige sang';

  @override
  String get playerNextSong => 'Næste sang';

  @override
  String get editorTitle => 'Rediger sang';

  @override
  String get editorTitleField => 'Sangtitel';

  @override
  String get editorArtistField => 'Kunstner';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Sangtekst';

  @override
  String get editorChordsField => 'Akkorder';

  @override
  String get editorKeyField => 'Toneart';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Stemning';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Varighed';

  @override
  String get editorTimeSignatureField => 'Taktart';

  @override
  String get editorLanguageField => 'Sprog';

  @override
  String get editorYearField => 'År';

  @override
  String get editorComposerField => 'Komponist';

  @override
  String get editorLyricistField => 'Tekstforfatter';

  @override
  String get editorCopyrightField => 'Ophavsret';

  @override
  String get editorLicenseField => 'Licens';

  @override
  String get songInfoSources => 'Kilder og kreditering';

  @override
  String get searchMatchSameSong => 'Samme sang; indspilning ikke bekræftet';

  @override
  String get searchMatchNeedsAgreement =>
      'Akkordarket skal bekræftes mod sangteksten';

  @override
  String get searchMatchDifferentLyrics =>
      'Sangteksten adskiller sig fra den valgte sang';

  @override
  String get searchMatchCombinedSources => 'Detaljer samlet fra flere kilder';

  @override
  String get searchCombinedLabel => 'Kombineret';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sangmatch',
      one: '1 sangmatch',
      zero: '0 sangmatch',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kildeversioner',
      one: '1 kildeversion',
      zero: '0 kildeversioner',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Bedste tilgængelige match';

  @override
  String get providerDescriptionUnknown => 'Sangkilde';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Download en ChordPro-fil fra kilden, og importér den derefter.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Download filen med en gratis konto, og importér den derefter.';

  @override
  String get providerDescPublicChordSheets => 'Offentlige akkordark.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Historiske sangtekster licenseret for hvert værk.';

  @override
  String get providerDescLicensedCatalog => 'Licenseret sangtekstkatalog.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Originalsange under Creative Commons BY.';

  @override
  String get providerDescPerSongLicense => 'Sangtekster licenseret pr. sang.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Kun oplysninger om indspilning og udgivelse.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Kun oplysninger om kompositionen.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Omslag kun for nøjagtige indspilningsmatch.';

  @override
  String get providerCapabilityLyrics => 'Sangtekster';

  @override
  String get providerCapabilityChords => 'Akkorder';

  @override
  String get providerCapabilityTiming => 'Tidsinddelte sangtekster';

  @override
  String get providerCapabilitySearch => 'Søgning';

  @override
  String get providerCapabilityMetadata => 'Sangdetaljer';

  @override
  String get editorArtworkField => 'Link til omslag';

  @override
  String get editorLyricsHint =>
      'Akkorder skrives i [C]-klammer; afsnitsmarkører står på egne linjer.';

  @override
  String get editorSave => 'Gem ændringer';

  @override
  String get editorSaved => 'Ændringer gemt.';

  @override
  String get editorSaveFailed => 'Ændringerne kunne ikke gemmes.';

  @override
  String get editorSaveConflict =>
      'Sangen er blevet ændret et andet sted. Dine ændringer blev gemt som en separat kopi.';

  @override
  String get editorUnsavedTitle => 'Kassér ændringer?';

  @override
  String get editorUnsavedMessage => 'Dine ændringer er ikke gemt.';

  @override
  String get editorFieldRequired => 'Indtast en sangtitel.';

  @override
  String get settingsTitle => 'Indstillinger';

  @override
  String get settingsAppearance => 'Udseende';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Brug enhedens indstilling';

  @override
  String get settingsThemeLight => 'Lys';

  @override
  String get settingsThemeDark => 'Mørk';

  @override
  String get settingsColorPalette => 'Farvepalet';

  @override
  String get settingsFont => 'Skrifttype';

  @override
  String get settingsTextSize => 'Tekststørrelse';

  @override
  String get settingsLyricsPreview => 'Forhåndsvisning af sangtekst';

  @override
  String get settingsPlayer => 'Sangtekstafspiller';

  @override
  String get settingsLyricHighlight => 'Fremhævning af den aktuelle linje';

  @override
  String get settingsHighlightBackgroundUnderline =>
      'Baggrund + understregning';

  @override
  String get settingsHighlightBackground => 'Baggrund';

  @override
  String get settingsHighlightUnderline => 'Understregning';

  @override
  String get settingsHighlightContrast => 'Kontrastfarve på tekst';

  @override
  String get settingsHighlightNone => 'Ingen';

  @override
  String get settingsDefaultShowChords => 'Vis akkorder som standard';

  @override
  String get settingsDefaultAutoscroll =>
      'Start automatisk rulning af sangteksten';

  @override
  String get settingsDefaultTiming => 'Standardindstilling for rulning';

  @override
  String get settingsLanguage => 'Appens sprog';

  @override
  String get settingsLanguageSystem => 'Brug enhedens sprog';

  @override
  String get settingsLanguageEnglish => 'Engelsk';

  @override
  String get settingsLanguageBulgarian => 'Bulgarsk';

  @override
  String get settingsLanguageUkrainian => 'Ukrainsk';

  @override
  String get settingsSources => 'Sangtekstkilder';

  @override
  String settingsSourceEnabled(String source) {
    return 'Aktivér kilden $source';
  }

  @override
  String get settingsSourceRefresh => 'Opdatér kildelisten';

  @override
  String get settingsSourcesUpdated => 'Kilder opdateret.';

  @override
  String get settingsSourcesUpdateFailed => 'Kilderne kunne ikke opdateres.';

  @override
  String get settingsImport => 'Importér sange';

  @override
  String get settingsImportChordPro => 'Importér ChordPro-fil';

  @override
  String get settingsImportSetlist => 'Importér sanglistefil';

  @override
  String get settingsImportSuccess => 'Import fuldført.';

  @override
  String get settingsImportFailed => 'Filen kunne ikke importeres.';

  @override
  String get settingsImportUnsupported => 'Denne filtype understøttes ikke.';

  @override
  String get settingsShareSong => 'Del som ChordPro';

  @override
  String get settingsSharePdf => 'Del som PDF';

  @override
  String get settingsCopySong => 'Kopiér til udklipsholder';

  @override
  String get settingsPrintSong => 'Udskriv kun sangen';

  @override
  String get settingsPrintSetlist => 'Udskriv sangliste med sangtekster';

  @override
  String get settingsExportFailed => 'Filen kunne ikke klargøres.';

  @override
  String get settingsCopied => 'Kopieret til udklipsholder.';

  @override
  String get settingsAbout => 'Om';

  @override
  String get settingsPrivacy => 'Privatliv';

  @override
  String get settingsLegal => 'Juridisk';

  @override
  String get settingsClearHistory => 'Ryd historik';

  @override
  String get settingsClearHistoryConfirm =>
      'Rydder den seneste aktivitet for sange og sætlister. Beholder gemte sange, favoritter, sætlister og indstillinger.';

  @override
  String get settingsHistoryCleared => 'Historikken er ryddet.';

  @override
  String get accountTitle => 'Konto og synkronisering';

  @override
  String get accountUnavailable =>
      'Synkronisering kræver en version af Singbook med Google-login konfigureret. I denne version gemmes dine sange kun på denne enhed.';

  @override
  String get accountSyncNow => 'Synkronisér nu';

  @override
  String get accountConnected =>
      'Forbundet. Vælg Synkronisér nu for at opdatere din sikkerhedskopi.';

  @override
  String get accountSignIn => 'Forbind konto';

  @override
  String get accountSignOut => 'Log ud';

  @override
  String get accountChange => 'Skift konto';

  @override
  String get accountSignedOut => 'Ikke forbundet';

  @override
  String get accountSyncing => 'Synkroniserer dit bibliotek…';

  @override
  String get accountSynced => 'Bibliotek synkroniseret.';

  @override
  String get accountSyncFailed => 'Biblioteket kunne ikke synkroniseres.';

  @override
  String get accessibilityFavorite => 'Favorit';

  @override
  String get accessibilityNotFavorite => 'Ikke en favorit';

  @override
  String get accessibilitySearchField => 'Søg efter sange';

  @override
  String get accessibilityClearSearch => 'Ryd søgetekst';

  @override
  String accessibilitySongMenu(String song) {
    return 'Handlinger for $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Handlinger for $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Udvid sangene i $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Fold sangene i $setlist sammen';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Afspilningsforløb, $percent procent';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Historikforløb, $date';
  }

  @override
  String get loading => 'Indlæser…';

  @override
  String get loadingSongs => 'Indlæser sange…';

  @override
  String get loadingSetlists => 'Indlæser sanglister…';

  @override
  String get errorGeneric => 'Der opstod en fejl.';

  @override
  String get errorOffline => 'Du ser ud til at være offline.';

  @override
  String get errorPermission => 'Der kræves tilladelse for at fortsætte.';

  @override
  String get emptyFiltered => 'Ingen elementer matcher disse filtre.';

  @override
  String get unknownValue => 'Ukendt';

  @override
  String get durationUnknown => 'Varighed ukendt';

  @override
  String get metadataNotSet => 'Ikke angivet';

  @override
  String get dateToday => 'I dag';

  @override
  String get dateYesterday => 'I går';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sange',
      one: '1 sang',
      zero: 'Ingen sange',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Marineblå';

  @override
  String get settingsPaletteSage => 'Salviegrøn';

  @override
  String get settingsPaletteOcean => 'Hav';

  @override
  String get settingsPaletteClay => 'Ler';

  @override
  String get settingsPalettePlum => 'Blomme';

  @override
  String get settingsFontSystem => 'System';

  @override
  String get settingsFontSerif => 'Serif';

  @override
  String get settingsFontMonospace => 'Monospatieret';

  @override
  String get settingsLyricsPreviewExample =>
      'Når morgenen kommer, synger vi igen.';

  @override
  String get settingsPreviewSongTitle => 'Morgensang';

  @override
  String get settingsPreviewArtist => 'Eksempelarrangement';

  @override
  String get settingsPreviewCurrentLine => 'Når morgenen kommer';

  @override
  String get settingsPreviewNextLine => 'Vi synger igen.';

  @override
  String get settingsPlayerSections => 'Sektionsoverskrifter';

  @override
  String get settingsPlayerControls => 'Afspilningspanel';

  @override
  String get settingsPlayerAutoscroll => 'Automatisk rulning';

  @override
  String get settingsSystemShort => 'Enhed';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Kontrollerer sangtekstkilder: $checked af $total fuldført.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Ingen brugbare sangtekster fundet.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Den valgte sang blev kontrolleret mod de aktiverede kilder, men ingen af dem fandt en brugbar version af sangteksten.';

  @override
  String get searchDiscoveryError =>
      'Sangtekstkilderne kunne ikke kontrolleres.';

  @override
  String get searchDiscoveryRetry => 'Prøv at søge efter sangtekster igen';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kilder utilgængelige',
      one: '1 kilde utilgængelig',
      zero: '0 kilder utilgængelige',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Kontrollér din forbindelse, og prøv igen.';

  @override
  String get searchProviderChecks => 'Kildekontroller';

  @override
  String get searchProviderPending => 'Kontrollerer';

  @override
  String get searchProviderFound => 'Match fundet';

  @override
  String get searchProviderRejected => 'Matcher ikke';

  @override
  String get searchProviderFailed => 'Kontrollen mislykkedes';

  @override
  String get searchProviderUnavailable => 'Ingen brugbare sangtekster';

  @override
  String get searchCatalogFilterHint =>
      'Vælg en sang for at filtrere sangtekstversioner efter akkorder, tidsinddeling eller sprog.';

  @override
  String get startupErrorTitle => 'Dit bibliotek kunne ikke åbnes.';

  @override
  String setlistCopyName(String name) {
    return '$name kopi';
  }

  @override
  String get setlistSongMissing => 'Manglende sang';

  @override
  String get settingsImportTooLarge =>
      'Denne fil er for stor til at importere.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Gå til $letter';
  }

  @override
  String get actionDiscard => 'Kassér';

  @override
  String get editorKeepEditing => 'Fortsæt redigering';

  @override
  String get settingsDefaultShowChordsHint =>
      'Vis akkorder over sangteksten, når sangen indeholder akkorder.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Sangteksten ruller med sangen. Bruges ikke ved manuel rulning.';

  @override
  String get accountUnavailableTitle => 'Synkronisering er ikke konfigureret';

  @override
  String get accountSignedOutBenefits =>
      'Når du tilslutter Google Drev, synkroniseres dit bibliotek. Ændringer af sange synkroniseres derefter automatisk.';

  @override
  String get accountManualSyncHint =>
      'Du kan også trykke på Synkronisér nu for at synkronisere dit bibliotek.';

  @override
  String get accountSignInWithGoogle => 'Log ind med Google';

  @override
  String get accountWorking => 'Arbejder…';

  @override
  String get accountNeverSynced => 'Aldrig synkroniseret';

  @override
  String get accountSyncedJustNow => 'Synkroniseret lige nu';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synkroniseret for $count minutter siden',
      one: 'Synkroniseret for 1 minut siden',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synkroniseret for $count timer siden',
      one: 'Synkroniseret for 1 time siden',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synkroniseret for $count dage siden',
      one: 'Synkroniseret for 1 dag siden',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modstridende redigeringer gemt som kopier',
      one: '1 modstridende redigering gemt som kopi',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Den samme sang eller sangliste blev redigeret to steder. Intet gik tabt: den anden version blev gemt som en separat kopi.';

  @override
  String get accountReviewConflicts => 'Gennemgå kopier';

  @override
  String get songsConflictFilterActive => 'Viser kun konfliktkopier';

  @override
  String get songsConflictFilterClear => 'Vis alle sange';

  @override
  String get songsConflictBadge => 'Konfliktkopi';

  @override
  String get songsConflictEmpty => 'Ingen konfliktkopier.';

  @override
  String get accountAutoSync => 'Synkronisér automatisk';

  @override
  String get accountAutoSyncHint =>
      'Synkronisering sker efter tilslutning og efter tilføjelse, redigering eller fjernelse af en sang.';

  @override
  String get accountDriveFolder => 'Google Drev biblioteksmappe';

  @override
  String get accountPrivateDriveFolder => 'Privat Singbook-mappe';

  @override
  String get accountChooseDriveFolder => 'Vælg mappe';

  @override
  String get accountDriveFolderMoveTitle => 'Flytte dit Singbook-bibliotek?';

  @override
  String get accountDriveFolderMoveBody =>
      'Vælg en synlig Google Drev-mappe. Singbook vil kopiere og bekræfte dine sange og sætlister der, før du skifter til den. Originalfiler forbliver på deres tidligere placering som en sikkerhedskopi. Andre filer efterlades alene. ChordPro-filer, du importerer til denne mappe, bruges til synkronisering og modtager Singbook-metadata.';

  @override
  String get accountImportChordPro => 'Importer ChordPro fra Drive';

  @override
  String get accountImportChordProHint =>
      'Vælg .cho-filer, der skal føjes til dette bibliotek. Filer, der allerede er i mappen, overtages; filer andre steder kopieres her.';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'Valg af Drev-mappe er ikke tilgængeligt';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'Vælg en synlig Drev-mappe med Google Drevs mappevælger på en understøttet enhed.';

  @override
  String get syncErrorDriveFolderMissing =>
      'Singbook Drive-mappen er ikke tilgængelig';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Vælg mappen igen, eller gendan den i Google Drev.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook skal have adgang til denne Drev-mappe';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Vælg mappen igen for at give adgang, og synkroniser derefter dit bibliotek.';

  @override
  String get syncErrorFolderMigration => 'Biblioteket kunne ikke flyttes endnu';

  @override
  String get syncErrorFolderMigrationHint =>
      'Dit tidligere bibliotek er stadig sikkert. Kontroller forbindelsen, og vælg mappen igen for at prøve igen.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Vælg først en synlig Drev-mappe';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'Der kræves en synlig biblioteksmappe, før du importerer filer fra Drev.';

  @override
  String get accountSignOutTitle => 'Log ud af denne konto?';

  @override
  String get accountSignOutBody =>
      'Dine sange og sanglister forbliver på denne enhed. De bliver ikke sikkerhedskopieret eller synkroniseret, før du logger ind igen.';

  @override
  String get accountUseDifferent => 'Brug en anden konto';

  @override
  String get accountSignInAgain => 'Log ind igen';

  @override
  String get accountChooseAction => 'Vælg, hvordan du vil fortsætte';

  @override
  String get accountChangedTitle => 'En anden Google-konto';

  @override
  String get accountChangedBody =>
      'Denne enhed blev sidst synkroniseret med en anden Google-konto. Vælg, hvad der skal ske med sangene og sanglisterne på denne enhed.';

  @override
  String get accountChangedMerge => 'Flet ind i den nye konto';

  @override
  String get accountChangedMergeHint =>
      'Behold alt på denne enhed, og føj det til den nye konto.';

  @override
  String get accountChangedReplace => 'Erstat med det nye kontos bibliotek';

  @override
  String get accountChangedReplaceHint =>
      'Sange på denne enhed, som ikke findes på den nye konto, fjernes.';

  @override
  String get accountChangedSignOut => 'Annuller, og log ud';

  @override
  String get accountStatusSignedOut =>
      'Konto og synkronisering: ikke logget ind';

  @override
  String get accountStatusSignedIn => 'Konto og synkronisering: logget ind';

  @override
  String get accountStatusSyncing => 'Konto og synkronisering: synkroniserer';

  @override
  String get accountStatusSynced =>
      'Konto og synkronisering: biblioteket er opdateret';

  @override
  String get accountStatusError =>
      'Konto og synkronisering: problem, tryk for at gennemgå';

  @override
  String get accountNoticeConflicts =>
      'Nogle sange blev redigeret to steder. Kopier blev gemt.';

  @override
  String get accountNoticeSignedIn => 'Logget ind.';

  @override
  String get accountNoticeSignedOut =>
      'Logget ud. Dine sange forbliver på denne enhed.';

  @override
  String get syncErrorNotConfigured =>
      'Synkronisering er ikke konfigureret i denne version.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Brug en Singbook-version med Google-login konfigureret.';

  @override
  String get syncErrorOAuthClientConfiguration =>
      'Google rejected this build\'s sign-in configuration.';

  @override
  String get syncErrorOAuthClientConfigurationHint =>
      'Check that the configured OAuth ID is Singbook\'s Desktop app client.';

  @override
  String get syncErrorNotSignedIn => 'Du er ikke logget ind.';

  @override
  String get syncErrorNotSignedInHint =>
      'Log ind for at synkronisere dit bibliotek.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google kræver, at du logger ind igen.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Log ind igen for at fortsætte synkroniseringen. Dine sange er sikre på denne enhed.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook har ikke tilladelse til at bruge Google Drev.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Log ind igen, og giv adgang til Drev, når du bliver spurgt.';

  @override
  String get syncErrorRateLimited => 'Google begrænser forespørgsler lige nu.';

  @override
  String get syncErrorRateLimitedHint => 'Vent et par minutter, og prøv igen.';

  @override
  String get syncErrorStorageFull => 'Dit Google Drev er fuldt.';

  @override
  String get syncErrorStorageFullHint => 'Frigør plads i Drev, og prøv igen.';

  @override
  String get syncErrorNetwork =>
      'Der kunne ikke oprettes forbindelse til Google.';

  @override
  String get syncErrorNetworkHint =>
      'Kontrollér din internetforbindelse, og prøv igen.';

  @override
  String get syncErrorAccountChanged => 'Der blev brugt en anden Google-konto.';

  @override
  String get syncErrorAccountChangedHint =>
      'Vælg, om du vil flette denne enheds bibliotek ind i kontoen eller erstatte det.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Dit synkroniserede bibliotek er større, end Singbook kan håndtere.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Fjern nogle sange eller sanglister fra det synkroniserede bibliotek, og prøv igen.';

  @override
  String get syncErrorSignInFailed => 'Login blev ikke fuldført.';

  @override
  String get syncErrorSignInFailedHint => 'Prøv at logge ind igen.';

  @override
  String get syncErrorGeneric => 'Biblioteket kunne ikke synkroniseres.';

  @override
  String get syncErrorGenericHint =>
      'Prøv igen om lidt. Dine sange er stadig sikre på denne enhed.';

  @override
  String get editorDurationInvalid =>
      'Angiv sekunder eller minutter og sekunder, f.eks. 3:45.';

  @override
  String get editorNumberInvalid => 'Angiv et tal.';

  @override
  String get accountReplaceConfirmTitle => 'Slet lokale sange?';

  @override
  String get accountReplaceConfirmBody =>
      'Sange og sanglister på denne enhed, som ikke findes i den nye konto, slettes permanent. Det kan ikke fortrydes.';

  @override
  String get accountReplaceConfirmAction => 'Slet og erstat';

  @override
  String get accountSuspiciousTitle => 'Elementer mangler i Google Drev';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elementer, som denne enhed tidligere har synkroniseret, mangler i Google Drev.',
      one:
          '$count element, som denne enhed tidligere har synkroniseret, mangler i Google Drev.',
    );
    return '$_temp0 Det kan ske, hvis appdata er blevet slettet i Googles indstillinger. Intet er slettet endnu.';
  }

  @override
  String get accountSuspiciousDelete => 'Slet dem også her';

  @override
  String get accountSuspiciousKeep => 'Behold mine sange, og upload dem igen';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Slet $count elementer fra denne enhed?',
      one: 'Slet $count element fra denne enhed?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Disse sange og sanglister slettes permanent fra denne enhed. Det kan ikke fortrydes.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Slet fra denne enhed';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Der mangler elementer i Google Drev.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Intet blev slettet. Vælg, om du også vil slette dem her eller uploade dem igen.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drev blev ændret under synkroniseringen.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Intet er gået tabt. Synkroniser igen for at hente de seneste ændringer.';

  @override
  String get syncErrorInvalidLocalData =>
      'Nogle data på denne enhed kunne ikke synkroniseres.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'En sang eller sangliste kunne ikke læses. Importér eller genskab den, og synkroniser derefter igen.';

  @override
  String get syncErrorNoAccountChange => 'Der er ingen kontoændring at løse.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Synkroniser igen for at fortsætte.';

  @override
  String get accountSyncWarningTitle =>
      'Synkroniseret, men nogle filer blev sprunget over';

  @override
  String get accountSyncWarningBody =>
      'Nogle filer kunne ikke bruges og blev efterladt, som de var. Alt andet er opdateret.';

  @override
  String get accountSyncWarningTooLarge =>
      'En fil var for stor til at synkronisere og blev sprunget over. Alt andet er opdateret.';

  @override
  String get accountSyncWarningInvalid =>
      'En fil kunne ikke læses og blev sprunget over. Alt andet er opdateret.';

  @override
  String get accountNoticeSyncSkipped =>
      'Synkroniseret. Nogle filer blev sprunget over.';

  @override
  String get settingsExportPdfTooLarge =>
      'Denne PDF ville blive for stor. Prøv med færre sange, eller del den som tekst.';

  @override
  String get settingsTimingTooLarge => 'Tidsdataene er for store (over 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Denne sikkerhedskopi indeholder den samme sang to gange, så intet blev importeret.';

  @override
  String get setlistSaveConflict =>
      'Sanglisten blev ændret et andet sted. Dine ændringer blev gemt som en separat kopi.';

  @override
  String get sectionVerse => 'Vers';

  @override
  String get sectionChorus => 'Omkvæd';

  @override
  String get sectionBridge => 'Bro';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Præ-omkvæd';

  @override
  String get sectionPostChorus => 'Post-omkvæd';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Mellemspil';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Refræn';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Afslutning';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tilgængelige versioner',
      one: '1 klar version',
      zero: '0 Tilgængelige versioner',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Utilgængelige versioner',
      one: '1 utilgængelig version',
      zero: '0 Utilgængelige versioner',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Gå til afsnit';

  @override
  String get searchVersionDetails => 'Versionsoplysninger';

  @override
  String get searchSelectedRecording => 'Valgt indspilning';

  @override
  String get searchVersionDuration => 'Versionens varighed';

  @override
  String get searchSourceOptions => 'Kildeindstillinger';

  @override
  String get actionUndo => 'Fortryd';

  @override
  String setlistEntryRemoved(String song) {
    return '$song er fjernet fra sætliste';
  }

  @override
  String get backupTitle => 'Sikkerhedskopiering og gendannelse';

  @override
  String get backupExport => 'Eksportér sikkerhedskopi';

  @override
  String get backupRestore => 'Gendan sikkerhedskopi';

  @override
  String get backupIncludePreferences => 'Medtag appindstillinger';

  @override
  String get backupRestorePreferences => 'Gendan appindstillinger';

  @override
  String get backupMerge => 'Føj til dette bibliotek';

  @override
  String get backupMergeHint =>
      'Behold lokale ændringer, og føj sange og sætlister fra denne sikkerhedskopi til.';

  @override
  String get backupReplace => 'Erstat dette bibliotek';

  @override
  String get backupReplaceHint =>
      'Erstat alle sange og sætlister på denne enhed med indholdet fra sikkerhedskopien.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Sange: $songs · Sætlister: $setlists · Konflikter: $conflicts';
  }

  @override
  String get backupFailed => 'Handlingen kunne ikke fuldføres. Prøv igen.';

  @override
  String get backupRestored => 'Sikkerhedskopien er gendannet.';

  @override
  String get backupLocalHint =>
      'Gem en kopi af dit bibliotek. Kontooplysninger og samtykkecookies medtages aldrig.';

  @override
  String get backupReplaceConfirm =>
      'Vil du erstatte det aktuelle bibliotek? Dette kan ikke fortrydes.';

  @override
  String get searchCheckOperations => 'Handlinger';

  @override
  String get searchCheckCode => 'Resultatkode';

  @override
  String get searchCheckQueued => 'Venter på at kontrollere denne kilde.';

  @override
  String get searchCheckFetch => 'Hent sangtekst';

  @override
  String get searchCheckValidate => 'Kontrollér sangmatch';

  @override
  String get searchCheckCorroborate => 'Kontrollér tekstmatch';

  @override
  String get searchCheckCompleted => 'Fuldført';

  @override
  String get searchCheckTimeout => 'Kilden svarede ikke i tide.';

  @override
  String get searchCheckBlocked => 'Kilden blokerede forespørgslen.';

  @override
  String get searchCheckRateLimited =>
      'Kilden begrænser forespørgsler. Prøv igen senere.';

  @override
  String get searchCheckNetwork =>
      'Kunne ikke nå kilden. Kontrollér din forbindelse.';

  @override
  String get searchCheckInvalid => 'Kilden returnerede et ulæseligt svar.';

  @override
  String get searchCheckNotConfigured =>
      'Denne kilde er ikke konfigureret i denne build.';

  @override
  String get searchCheckNoLyrics =>
      'Der blev ikke fundet matchende sangtekster.';

  @override
  String get searchCheckFailed => 'Handlingen kunne ikke fuldføres.';

  @override
  String get searchCheckNoHistory =>
      'Der er ikke kørt kildekontroller for denne sammenligning.';

  @override
  String get searchVersionCredits => 'Kreditering';

  @override
  String get searchVersionMediaLinks => 'Relaterede links';

  @override
  String get searchCheckCancelled => 'Annulleret';

  @override
  String get searchCheckAmbiguous =>
      'Der blev fundet flere match. Denne kilde kræver en mere specifik indspilning.';

  @override
  String get searchCheckIdentity =>
      'Denne kilde kræver et id for en indspilning eller et værk.';

  @override
  String get searchCheckExtraction =>
      'Kilden svarede, men sangteksten kunne ikke hentes.';

  @override
  String get searchCheckBusy => 'Kilden er optaget. Prøv igen senere.';

  @override
  String get searchCheckSelection =>
      'Vælg et bestemt resultat fra denne kilde.';

  @override
  String get playerChordsNone => 'Ingen';

  @override
  String get editorCustomValue => 'Andet…';

  @override
  String get editorStandardTuning => 'Standardstemning';

  @override
  String get editorExampleVerse =>
      '[C]En ny dag [G]kalder,\n[Am]vi følger lyset hjem til [F]os.';

  @override
  String get editorExampleChorus =>
      '[F]Syng denne sang [C]sammen,\n[G]lad melodien føre os [C]videre.';

  @override
  String get editorExampleBridge => '[Am]En linje mere, lidt [F]tættere på.';

  @override
  String get playerEstimatedKey => 'Anslået toneart';

  @override
  String get songsLibraryView => 'Bibliotek';

  @override
  String get settingsStartupView => 'Start i';

  @override
  String get settingsStartupViewHint =>
      'Vælg den sangvisning, der vises, når appen åbnes.';

  @override
  String get settingsStartupLastView => 'Senest åbne';

  @override
  String get playerFullScreen => 'Fuld skærm';

  @override
  String get playerExitFullScreen => 'Afslut fuld skærm';

  @override
  String get playerExpandControls => 'Vis afspilningsknapper';

  @override
  String get playerCollapseControls => 'Skjul afspilningsknapper';

  @override
  String get settingsShowSections => 'Vis sektionsoverskrifter';

  @override
  String get settingsShowSectionsHint =>
      'Vis overskrifter for vers, omkvæd og andre afsnit i sangteksten.';

  @override
  String get settingsShowPlayerControls => 'Vis afspilningsknapper';

  @override
  String get settingsShowPlayerControlsHint =>
      'Du kan også trykke på eller stryge på afspillerpanelet for at vise eller skjule det.';
}
