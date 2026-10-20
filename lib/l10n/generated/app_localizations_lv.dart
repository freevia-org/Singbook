// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latvian (`lv`).
class AppLocalizationsLv extends AppLocalizations {
  AppLocalizationsLv([String locale = 'lv']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Dziesmu vārdi, akordi un dziesmu saraksti vienuviet — gatavi mēģinājumiem, skatuvei un jebkurai vietai, kur spēlējat.';

  @override
  String get aboutMadeForSinging => 'Katra dziesma gatava.';

  @override
  String get aboutDetails =>
      'Meklējiet pieejamajos avotos un salīdziniet dziesmu vārdus, akordus, laika atzīmes un ieraksta informāciju, pirms saglabājat vēlamo versiju. Pieejamība ir atkarīga no dziesmas un pakalpojuma.';

  @override
  String get aboutFindTitle => 'Atrodiet īsto versiju';

  @override
  String get aboutKeepTitle => 'Veidojiet savu bibliotēku';

  @override
  String get aboutKeepDetails =>
      'Rediģējiet un transponējiet dziesmas, glabājiet tās vietējā bibliotēkā lietošanai bezsaistē un kopīgojiet pārnēsājamus ChordPro failus. Izvēles sinhronizācija ar Google Drive izmanto privātu lietotnes mapi jūsu Google kontā. Varat arī pieskarties “Sinhronizēt tagad”, lai atjauninātu ierīces.';

  @override
  String get aboutPlayTitle => 'Ņemiet dziesmu sarakstu līdzi uz skatuvi';

  @override
  String get aboutPlayDetails =>
      'Sakārtojiet dziesmas sarakstos, izvēlieties katrai dziesmai tonalitāti un kopīgojiet OpenSong sarakstus. Pielāgojiet lasītāja teksta lielumu, ieslēdziet dziesmu vārdu automātisko ritināšanu un drukājiet dziesmu PDF failus. Singbook netranslē un neatskaņo audio.';

  @override
  String get aboutPrivacyTitle => 'Bezmaksas un ar uzsvaru uz lokālu lietošanu';

  @override
  String get aboutPrivacyDetails =>
      'Singbook ir bezmaksas, bez reklāmām, analītikas un pirkumiem lietotnē. Saglabātā bibliotēka paliek jūsu ierīcē; izvēles sinhronizācijai tiek izmantots jūsu Google Drive. Tiešsaistes rezultātus nodrošina neatkarīgi trešo pušu pakalpojumi; tie var nebūt pieejami vai būt aizsargāti ar autortiesībām. Singbook šo saturu neizvieto.';

  @override
  String get aboutWebsite => 'Singbook vietne';

  @override
  String get aboutSourceCode => 'Avota kods vietnē GitHub';

  @override
  String get aboutPublisher => 'Freevia veidots';

  @override
  String aboutLanguages(int count) {
    return 'Lietotnes valodas: $count';
  }

  @override
  String get aboutSupport => 'Atbalsts un atsauksmes';

  @override
  String get menuTypeNewSong => 'Ievadīt jaunu dziesmu';

  @override
  String appVersion(String version) {
    return 'Versija $version';
  }

  @override
  String get navHome => 'Sākums';

  @override
  String get navSongs => 'Dziesmas';

  @override
  String get navSetlists => 'Koncertprogrammas';

  @override
  String get navSettings => 'Iestatījumi';

  @override
  String get navSettingsCompact => 'Iestatījumi';

  @override
  String get navSearch => 'Meklēt';

  @override
  String get navBack => 'Atpakaļ';

  @override
  String get appExitBackAgain => 'Lai izietu, vēlreiz nospiediet Atpakaļ';

  @override
  String get navClose => 'Aizvērt';

  @override
  String get navMore => 'Citas darbības';

  @override
  String get actionCancel => 'Atcelt';

  @override
  String get actionSave => 'Saglabāt';

  @override
  String get actionDone => 'Gatavs';

  @override
  String get actionEdit => 'Rediģēt';

  @override
  String get actionDelete => 'Dzēst';

  @override
  String get actionShare => 'Kopīgot';

  @override
  String get actionPrint => 'Drukāt';

  @override
  String get actionCopy => 'Kopēt';

  @override
  String get actionClear => 'Notīrīt';

  @override
  String get actionRetry => 'Mēģināt vēlreiz';

  @override
  String get actionRefresh => 'Atsvaidzināt';

  @override
  String get actionImport => 'Importēt';

  @override
  String get actionExport => 'Eksportēt';

  @override
  String get actionExpand => 'Izvērst';

  @override
  String get actionCollapse => 'Sakļaut';

  @override
  String get actionAdd => 'Pievienot';

  @override
  String get actionCreate => 'Izveidot';

  @override
  String get actionRemove => 'Noņemt';

  @override
  String get actionDuplicate => 'Dublēt';

  @override
  String get actionMoveUp => 'Pārvietot augšup';

  @override
  String get actionMoveDown => 'Pārvietot lejup';

  @override
  String get actionPrevious => 'Iepriekšējais';

  @override
  String get actionNext => 'Nākamais';

  @override
  String get searchHint => 'Meklēt dziesmas, izpildītājus vai dziesmu vārdus';

  @override
  String get searchCatalogHint => 'Meklēt dziesmu vai izpildītāju';

  @override
  String get searchChangeSong => 'Mainīt dziesmu';

  @override
  String get searchSelectedPreview => 'Atlasītais priekšskatījums';

  @override
  String get searchSubmit => 'Meklēt';

  @override
  String get searchFilters => 'Meklēšanas opcijas';

  @override
  String get searchFiltersShow => 'Rādīt meklēšanas opcijas';

  @override
  String get searchFiltersHide => 'Paslēpt meklēšanas opcijas';

  @override
  String get searchFilterArtist => 'Izpildītājs';

  @override
  String get searchFilterTitle => 'Dziesmas nosaukums';

  @override
  String get searchFilterLyrics => 'Dziesmu vārdi';

  @override
  String get searchFilterChords => 'Ir akordi';

  @override
  String get searchFilterTimed => 'Dziesmu vārdi ar laika atzīmēm';

  @override
  String get searchFilterLanguage => 'Valoda';

  @override
  String get searchFilterAll => 'Jebkura';

  @override
  String get searchAutocompleteLabel => 'Ieteikumi';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rezultāti',
      one: '$count rezultāts',
      zero: '$count rezultātu',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Ievadiet dziesmu, izpildītāju vai dziesmas rindu, ko meklēt.';

  @override
  String get searchCatalogEmptyQuery =>
      'Ievadiet dziesmu vai izpildītāju, ko meklēt.';

  @override
  String get searchNoResults =>
      'Dziesmas nav atrastas. Pamēģiniet citu meklējumu.';

  @override
  String get searchLoading => 'Meklē dziesmas…';

  @override
  String get searchError => 'Meklēšanu neizdevās pabeigt.';

  @override
  String get searchOnlineTab => 'Tiešsaistē';

  @override
  String get searchRecentTab => 'Nesenās';

  @override
  String get searchFavoritesTab => 'Izlase';

  @override
  String get searchSuggested => 'Ieteikta atbilstība';

  @override
  String get searchAlternatives => 'Citas atbilstības';

  @override
  String get searchCompare => 'Salīdzināt versijas';

  @override
  String get searchChooseVersion => 'Izvēlēties šo versiju';

  @override
  String get searchFullPreview => 'Pilns priekšskatījums';

  @override
  String get searchArrangementNotes => 'Piezīmes par aranžējumu';

  @override
  String get searchOpenLyrics => 'Atvērt dziesmas vārdus';

  @override
  String get searchContributions => 'Izmantotie avoti';

  @override
  String get searchVersionChecking => 'Notiek šīs versijas pārbaude…';

  @override
  String get searchVersionUnavailable =>
      'Šo versiju nevar izmantot. Izvēlieties citu versiju.';

  @override
  String get searchPreviewUnavailable =>
      'Dziesmas vārdu priekšskatījums nav pieejams.';

  @override
  String get searchSongMatch => 'Dziesmas atbilstība';

  @override
  String get searchRecordingMatch => 'Ieraksta atbilstība';

  @override
  String get searchMatchUnverified => 'Ieraksts nav pārbaudīts';

  @override
  String get searchMatchExact => 'Precīza ieraksta atbilstība';

  @override
  String get searchMatchPossible => 'Iespējama atbilstība';

  @override
  String get searchAvailability => 'Pieejamība';

  @override
  String get searchLyricsAvailable => 'Dziesmu vārdi ir pieejami';

  @override
  String get searchLyricsUnavailable => 'Dziesmu vārdi nav pieejami';

  @override
  String get searchChordsAvailable => 'Akordi ir pieejami';

  @override
  String get searchChordsUnavailable => 'Akordu nav';

  @override
  String get searchTimingAvailable => 'Laika atzīmes ir pieejamas';

  @override
  String get searchTimingUnavailable => 'Laika atzīmju nav';

  @override
  String get searchDurationUnknown => 'Ilgums nav zināms';

  @override
  String searchRating(String rating) {
    return 'Vērtējums $rating';
  }

  @override
  String get searchSourceLabel => 'Avots';

  @override
  String get searchMetadata => 'Dziesmas informācija';

  @override
  String get searchAlbum => 'Albums';

  @override
  String get searchArtist => 'Izpildītājs';

  @override
  String get searchYear => 'Gads';

  @override
  String get searchLanguage => 'Valoda';

  @override
  String get searchViewVersions => 'Skatīt versijas';

  @override
  String get searchSaved => 'Dziesma ir saglabāta jūsu bibliotēkā.';

  @override
  String get searchSaveOpenLyrics => 'Saglabāt un atvērt vārdus';

  @override
  String get searchOtherResults => 'Citi rezultāti';

  @override
  String get searchSaveFailed => 'Dziesmu neizdevās saglabāt.';

  @override
  String get homeRecentSongs => 'Nesenās dziesmas';

  @override
  String get homeRecentlyPlayed => 'Nesen atskaņotās';

  @override
  String get homeFavorites => 'Izlase';

  @override
  String get homeHistory => 'Vēsture';

  @override
  String get homeHistoryClear => 'Notīrīt vēsturi';

  @override
  String get homeHistoryCleared => 'Vēsture ir notīrīta.';

  @override
  String get homeHistoryEmpty => 'Šeit būs redzamas jūsu atvērtās dziesmas.';

  @override
  String get homeFavoritesEmpty =>
      'Šeit būs redzamas jūsu iecienītās dziesmas un koncertprogrammas.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rādīti $count vienumi',
      one: 'Rādīts $count vienums',
      zero: 'Rādīts $count vienumu',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Šeit būs redzamas jūsu nesenās dziesmas un koncertprogrammas.';

  @override
  String get homeTimelineLabel => 'Vēstures laika skala';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Visa vēsture';

  @override
  String get homeShowFavorites => 'Rādīt izlasi';

  @override
  String get homeShowRecent => 'Rādīt nesenās';

  @override
  String get songsTitle => 'Dziesmas';

  @override
  String get songsEmpty => 'Šeit būs redzamas jūsu dziesmas.';

  @override
  String get songsEmptySearch => 'Neviena dziesma neatbilst meklējumam.';

  @override
  String get songsAdd => 'Pievienot dziesmu';

  @override
  String get songsSortAlphabetical => 'Kārtot alfabētiski';

  @override
  String get songsAlphabetNavigation => 'Dziesmu rādītājs';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reizes',
      one: '$count reizi',
      zero: '$count reižu',
    );
    return 'Atvērta $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Pievienot izlasei';

  @override
  String get songFavoriteRemove => 'Noņemt no izlases';

  @override
  String get songMenuLabel => 'Dziesmas darbības';

  @override
  String get songInfo => 'Dziesmas informācija';

  @override
  String get setlistMenuLabel => 'Koncertprogrammas darbības';

  @override
  String get songAddToSetlist => 'Pievienot koncertprogrammai';

  @override
  String get songCopyChordPro => 'Kopēt ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Dzēst dziesmu?';

  @override
  String get songDeleteConfirmMessage =>
      'Dziesma tiks noņemta no jūsu bibliotēkas.';

  @override
  String get songDeleted => 'Dziesma ir izdzēsta.';

  @override
  String get setlistsTitle => 'Koncertprogrammas';

  @override
  String get setlistsEmpty =>
      'Izveidojiet koncertprogrammu nākamajam mēģinājumam vai uzstāšanās reizei.';

  @override
  String get setlistsEmptySearch =>
      'Neviena koncertprogramma neatbilst meklējumam.';

  @override
  String get setlistCreate => 'Jauna koncertprogramma';

  @override
  String get setlistNameHint => 'Koncertprogrammas nosaukums';

  @override
  String get setlistNotes => 'Piezīmes';

  @override
  String get setlistEntryOverride =>
      'Atsevišķa dziesmas tonalitāte un kapodastrs';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dziesmas',
      one: '$count dziesma',
      zero: '$count dziesmu',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Vismaz $duration';
  }

  @override
  String get setlistDurationUnknown => 'Ilgums nav zināms';

  @override
  String setlistActivity(String date) {
    return 'Pēdējā darbība $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Izveidota $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Rediģēta $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Pēdējo reizi atskaņota $date';
  }

  @override
  String get setlistSongsEmpty => 'Šajā koncertprogrammā vēl nav dziesmu.';

  @override
  String get setlistAddSongs => 'Pievienot dziesmas';

  @override
  String get setlistReorder => 'Mainīt dziesmu secību';

  @override
  String setlistMoveSongUp(String song) {
    return 'Pārvietot dziesmu “$song” augšup';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Pārvietot dziesmu “$song” lejup';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Noņemt dziesmu “$song” no koncertprogrammas';
  }

  @override
  String get setlistDuplicate => 'Dublēt koncertprogrammu';

  @override
  String get setlistFavoriteAdd => 'Pievienot koncertprogrammu izlasei';

  @override
  String get setlistFavoriteRemove => 'Noņemt koncertprogrammu no izlases';

  @override
  String get setlistShare => 'Kopīgot kā OpenSong';

  @override
  String get setlistSharePdf => 'Kopīgot kā PDF';

  @override
  String get setlistPrint => 'Drukāt';

  @override
  String get setlistDeleteConfirmTitle => 'Dzēst koncertprogrammu?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Koncertprogramma tiks noņemta. Jūsu bibliotēkas dziesmas paliks.';

  @override
  String get setlistDeleted => 'Koncertprogramma ir izdzēsta.';

  @override
  String get readerTitle => 'Dziesmu vārdi';

  @override
  String get readerNoLyrics => 'Dziesmas vārdi vēl nav pievienoti.';

  @override
  String get readerShowChords => 'Rādīt akordus';

  @override
  String get readerHideChords => 'Paslēpt akordus';

  @override
  String get readerTranspose => 'Transponēt akordus';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pustoņiem',
      one: '$count pustoni',
      zero: '$count pustoņiem',
    );
    return 'Transponēt par $_temp0';
  }

  @override
  String get readerSaved => 'Saglabāts';

  @override
  String get readerEdit => 'Rediģēt dziesmas vārdus un informāciju';

  @override
  String get playerPlay => 'Atskaņot';

  @override
  String get playerPause => 'Pauze';

  @override
  String get playerResume => 'Atsākt dziesmas vārdu ritināšanu';

  @override
  String get playerSeek => 'Atskaņošanas pozīcija';

  @override
  String playerElapsed(String time) {
    return 'Pagājušais laiks $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Atlikušais laiks $time';
  }

  @override
  String get playerTimingMode => 'Ritināšanas režīms';

  @override
  String get playerTimedLyrics => 'Dziesmu vārdi ar laika atzīmēm';

  @override
  String get playerStartScroll => 'Sākt automātisko ritināšanu';

  @override
  String get playerEstimatedPace => 'Aprēķinātais ritināšanas ātrums';

  @override
  String get playerScrollSpeed => 'Ritināšanas ātrums';

  @override
  String playerEstimatedDuration(String time) {
    return 'Paredzamais ilgums: $time';
  }

  @override
  String get playerLyricsOnly => 'Dziesmas vārdu ritināšana · bez audio';

  @override
  String get playerManualScroll => 'Manuāla ritināšana';

  @override
  String get playerTimingStatusReady =>
      'Dziesmas vārdi ritinās atbilstoši pieejamajām laika atzīmēm.';

  @override
  String get playerTimingStatusEstimated =>
      'Ritināšanas ātrums aprēķināts pēc dziesmas ilguma.';

  @override
  String get playerTimingStatusManual => 'Ritiniet dziesmas vārdus paši.';

  @override
  String get playerTimingStatusUnavailable =>
      'Šai dziesmai laika atzīmju ritināšana nav pieejama.';

  @override
  String get playerDurationUnknown =>
      'Pievienojiet dziesmas ilgumu, lai izmantotu aprēķināto ritināšanu.';

  @override
  String get playerProgressLabel => 'Dziesmas progress';

  @override
  String get playerCurrentSection => 'Pašreizējā daļa';

  @override
  String get playerPreviousSection => 'Iepriekšējā daļa';

  @override
  String get playerNextSection => 'Nākamā daļa';

  @override
  String get playerPreviousSectionSong =>
      'Iepriekšējā daļa · turiet nospiestu, lai pārietu uz iepriekšējo koncertprogrammas dziesmu';

  @override
  String get playerNextSectionSong =>
      'Nākamā daļa · turiet nospiestu, lai pārietu uz nākamo koncertprogrammas dziesmu';

  @override
  String get playerPreviousSong => 'Iepriekšējā dziesma';

  @override
  String get playerNextSong => 'Nākamā dziesma';

  @override
  String get editorTitle => 'Rediģēt dziesmu';

  @override
  String get editorTitleField => 'Dziesmas nosaukums';

  @override
  String get editorArtistField => 'Izpildītājs';

  @override
  String get editorAlbumField => 'Albums';

  @override
  String get editorLyricsField => 'Dziesmas vārdi';

  @override
  String get editorChordsField => 'Akordi';

  @override
  String get editorKeyField => 'Tonalitāte';

  @override
  String get editorCapoField => 'Kapodastrs';

  @override
  String get editorTuningField => 'Skaņojums';

  @override
  String get editorTempoField => 'Temps';

  @override
  String get editorDurationField => 'Ilgums';

  @override
  String get editorTimeSignatureField => 'Taktsmērs';

  @override
  String get editorLanguageField => 'Valoda';

  @override
  String get editorYearField => 'Gads';

  @override
  String get editorComposerField => 'Komponists';

  @override
  String get editorLyricistField => 'Dziesmas vārdu autors';

  @override
  String get editorCopyrightField => 'Autortiesības';

  @override
  String get editorLicenseField => 'Licence';

  @override
  String get songInfoSources => 'Avoti un norādes';

  @override
  String get searchMatchSameSong =>
      'Tā pati dziesma; ieraksts nav apstiprināts';

  @override
  String get searchMatchNeedsAgreement =>
      'Akordu ieraksts jāsalīdzina ar dziesmas vārdiem';

  @override
  String get searchMatchDifferentLyrics =>
      'Dziesmas vārdi atšķiras no atlasītās dziesmas';

  @override
  String get searchMatchCombinedSources =>
      'Informācija apkopota no vairākiem avotiem';

  @override
  String get searchCombinedLabel => 'Apvienots';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dziesmu atbilstības',
      one: '$count dziesmas atbilstība',
      zero: '$count dziesmu atbilstību',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avota versijas',
      one: '$count avota versija',
      zero: '$count avota versiju',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Labākā pieejamā atbilstība';

  @override
  String get providerDescriptionUnknown => 'Dziesmas avots';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Lejupielādējiet ChordPro failu no avota un pēc tam importējiet to.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Lejupielādējiet failu ar bezmaksas kontu un pēc tam importējiet to.';

  @override
  String get providerDescPublicChordSheets => 'Publiski akordu pieraksti.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Vēsturiskie dziesmu vārdi licencēti katram darbam atsevišķi.';

  @override
  String get providerDescLicensedCatalog => 'Licencēts dziesmu vārdu katalogs.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Oriģināldziesmas ar Creative Commons BY licenci.';

  @override
  String get providerDescPerSongLicense =>
      'Dziesmu vārdi licencēti katrai dziesmai atsevišķi.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Tikai ieraksta un izdevuma informācija.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Tikai skaņdarba informācija.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Vāka attēls pieejams tikai precīzām ieraksta atbilstībām.';

  @override
  String get providerCapabilityLyrics => 'Dziesmu vārdi';

  @override
  String get providerCapabilityChords => 'Akordi';

  @override
  String get providerCapabilityTiming => 'Dziesmu vārdi ar laika atzīmēm';

  @override
  String get providerCapabilitySearch => 'Meklēšana';

  @override
  String get providerCapabilityMetadata => 'Dziesmas informācija';

  @override
  String get editorArtworkField => 'Vāka saite';

  @override
  String get editorLyricsHint =>
      'Akordus rakstiet kvadrātiekavās [C]; sadaļu marķierus ievietojiet atsevišķās rindās.';

  @override
  String get editorSave => 'Saglabāt izmaiņas';

  @override
  String get editorSaved => 'Izmaiņas saglabātas.';

  @override
  String get editorSaveFailed => 'Neizdevās saglabāt izmaiņas.';

  @override
  String get editorSaveConflict =>
      'Dziesma ir mainīta citur. Jūsu labojumi saglabāti kā atsevišķa kopija.';

  @override
  String get editorUnsavedTitle => 'Atmest izmaiņas?';

  @override
  String get editorUnsavedMessage => 'Jūsu labojumi nav saglabāti.';

  @override
  String get editorFieldRequired => 'Ievadiet dziesmas nosaukumu.';

  @override
  String get settingsTitle => 'Iestatījumi';

  @override
  String get settingsAppearance => 'Izskats';

  @override
  String get settingsTheme => 'Tēma';

  @override
  String get settingsThemeSystem => 'Izmantot ierīces iestatījumu';

  @override
  String get settingsThemeLight => 'Gaiša';

  @override
  String get settingsThemeDark => 'Tumša';

  @override
  String get settingsColorPalette => 'Krāsu palete';

  @override
  String get settingsFont => 'Fonts';

  @override
  String get settingsTextSize => 'Teksta lielums';

  @override
  String get settingsLyricsPreview => 'Dziesmas vārdu priekšskatījums';

  @override
  String get settingsPlayer => 'Dziesmu vārdu atskaņotājs';

  @override
  String get settingsLyricHighlight => 'Pašreizējās teksta rindas izcelšana';

  @override
  String get settingsHighlightBackgroundUnderline => 'Fons + pasvītrojums';

  @override
  String get settingsHighlightBackground => 'Fons';

  @override
  String get settingsHighlightUnderline => 'Pasvītrojums';

  @override
  String get settingsHighlightContrast => 'Kontrastējoša teksta krāsa';

  @override
  String get settingsHighlightNone => 'Nav';

  @override
  String get settingsDefaultShowChords => 'Pēc noklusējuma rādīt akordus';

  @override
  String get settingsDefaultAutoscroll =>
      'Automātiski sākt dziesmas vārdu ritināšanu';

  @override
  String get settingsDefaultTiming => 'Noklusējuma ritināšanas režīms';

  @override
  String get settingsLanguage => 'Lietotnes valoda';

  @override
  String get settingsLanguageSystem => 'Izmantot ierīces valodu';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Dziesmu vārdu avoti';

  @override
  String settingsSourceEnabled(String source) {
    return 'Iespējot avotu $source';
  }

  @override
  String get settingsSourceRefresh => 'Atsvaidzināt avotu sarakstu';

  @override
  String get settingsSourcesUpdated => 'Avoti ir atjaunināti.';

  @override
  String get settingsSourcesUpdateFailed => 'Neizdevās atjaunināt avotus.';

  @override
  String get settingsImport => 'Importēt dziesmas';

  @override
  String get settingsImportChordPro => 'Importēt ChordPro failu';

  @override
  String get settingsImportSetlist => 'Importēt koncertprogrammas failu';

  @override
  String get settingsImportSuccess => 'Importēšana pabeigta.';

  @override
  String get settingsImportFailed => 'Neizdevās importēt šo failu.';

  @override
  String get settingsImportUnsupported => 'Šis faila veids netiek atbalstīts.';

  @override
  String get settingsShareSong => 'Kopīgot kā ChordPro';

  @override
  String get settingsSharePdf => 'Kopīgot kā PDF';

  @override
  String get settingsCopySong => 'Kopēt starpliktuvē';

  @override
  String get settingsPrintSong => 'Drukāt tikai dziesmu';

  @override
  String get settingsPrintSetlist =>
      'Drukāt koncertprogrammu ar dziesmu vārdiem';

  @override
  String get settingsExportFailed => 'Neizdevās sagatavot failu.';

  @override
  String get settingsCopied => 'Nokopēts starpliktuvē.';

  @override
  String get settingsAbout => 'Par lietotni';

  @override
  String get settingsPrivacy => 'Konfidencialitāte';

  @override
  String get settingsLegal => 'Juridiskā informācija';

  @override
  String get settingsClearHistory => 'Notīrīt vēsturi';

  @override
  String get settingsClearHistoryConfirm =>
      'Notīra dziesmu un koncertprogrammu neseno darbību vēsturi. Saglabā saglabātās dziesmas, izlasi, koncertprogrammas un iestatījumus.';

  @override
  String get settingsHistoryCleared => 'Vēsture ir notīrīta.';

  @override
  String get accountTitle => 'Konts un sinhronizācija';

  @override
  String get accountUnavailable =>
      'Sinhronizēšanai vajadzīga Singbook versija ar konfigurētu pierakstīšanos Google kontā. Šajā versijā dziesmas tiek glabātas tikai šajā ierīcē.';

  @override
  String get accountSyncNow => 'Sinhronizēt tūlīt';

  @override
  String get accountConnected =>
      'Savienots. Izvēlieties “Sinhronizēt tūlīt”, lai atjauninātu dublējumu.';

  @override
  String get accountSignIn => 'Pievienot kontu';

  @override
  String get accountSignOut => 'Izrakstīties';

  @override
  String get accountChange => 'Mainīt kontu';

  @override
  String get accountSignedOut => 'Nav savienots';

  @override
  String get accountSyncing => 'Sinhronizē jūsu bibliotēku…';

  @override
  String get accountSynced => 'Bibliotēka sinhronizēta.';

  @override
  String get accountSyncFailed => 'Neizdevās sinhronizēt bibliotēku.';

  @override
  String get accessibilityFavorite => 'Izlasē';

  @override
  String get accessibilityNotFavorite => 'Nav izlasē';

  @override
  String get accessibilitySearchField => 'Meklēt dziesmas';

  @override
  String get accessibilityClearSearch => 'Notīrīt meklēšanas tekstu';

  @override
  String accessibilitySongMenu(String song) {
    return 'Dziesmas “$song” darbības';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Koncertprogrammas “$setlist” darbības';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Izvērst koncertprogrammas “$setlist” dziesmas';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Sakļaut koncertprogrammas “$setlist” dziesmas';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      percent,
      locale: localeName,
      other: '$percent procenti',
      one: '$percent procents',
      zero: '$percent procentu',
    );
    return 'Atskaņošanas progress, $_temp0';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Vēstures laika skala, $date';
  }

  @override
  String get loading => 'Notiek ielāde…';

  @override
  String get loadingSongs => 'Notiek dziesmu ielāde…';

  @override
  String get loadingSetlists => 'Notiek koncertprogrammu ielāde…';

  @override
  String get errorGeneric => 'Radās kļūda.';

  @override
  String get errorOffline => 'Šķiet, ka neesat tiešsaistē.';

  @override
  String get errorPermission => 'Lai turpinātu, nepieciešama atļauja.';

  @override
  String get emptyFiltered => 'Neviens vienums neatbilst šiem filtriem.';

  @override
  String get unknownValue => 'Nezināms';

  @override
  String get durationUnknown => 'Ilgums nav zināms';

  @override
  String get metadataNotSet => 'Nav iestatīts';

  @override
  String get dateToday => 'Šodien';

  @override
  String get dateYesterday => 'Vakar';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dziesmas',
      one: '$count dziesma',
      zero: '$count dziesmu',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Tumši zila';

  @override
  String get settingsPaletteSage => 'Salvijas zaļa';

  @override
  String get settingsPaletteOcean => 'Okeāna zila';

  @override
  String get settingsPaletteClay => 'Māla krāsa';

  @override
  String get settingsPalettePlum => 'Plūmju violeta';

  @override
  String get settingsFontSystem => 'Sistēmas';

  @override
  String get settingsFontSerif => 'Serifa';

  @override
  String get settingsFontMonospace => 'Vienāda platuma';

  @override
  String get settingsLyricsPreviewExample =>
      'Kad pienāks rīts, mēs atkal dziedāsim.';

  @override
  String get settingsPreviewSongTitle => 'Rīta dziesma';

  @override
  String get settingsPreviewArtist => 'Parauga aranžējums';

  @override
  String get settingsPreviewCurrentLine => 'Kad pienāks rīts';

  @override
  String get settingsPreviewNextLine => 'Mēs atkal dziedāsim.';

  @override
  String get settingsPlayerSections => 'Sadaļu virsraksti';

  @override
  String get settingsPlayerControls => 'Atskaņošanas panelis';

  @override
  String get settingsPlayerAutoscroll => 'Automātiska ritināšana';

  @override
  String get settingsSystemShort => 'Ierīce';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Pārbauda dziesmu vārdu avotus: pabeigti $checked no $total.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Nav atrasti izmantojami dziesmu vārdi.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Atlasītā dziesma tika pārbaudīta iespējotajos avotos, taču neviens no tiem neatgrieza izmantojamu dziesmu vārdu versiju.';

  @override
  String get searchDiscoveryError =>
      'Neizdevās pārbaudīt dziesmu vārdu avotus.';

  @override
  String get searchDiscoveryRetry => 'Meklēt dziesmu vārdus vēlreiz';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avoti nav pieejami',
      one: '$count avots nav pieejams',
      zero: '$count avotu nav pieejami',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails =>
      'Pārbaudiet savienojumu un mēģiniet vēlreiz.';

  @override
  String get searchProviderChecks => 'Avotu pārbaudes';

  @override
  String get searchProviderPending => 'Pārbauda';

  @override
  String get searchProviderFound => 'Atbilstība atrasta';

  @override
  String get searchProviderRejected => 'Neatbilst';

  @override
  String get searchProviderFailed => 'Pārbaude neizdevās';

  @override
  String get searchProviderUnavailable => 'Nav izmantojamu dziesmu vārdu';

  @override
  String get searchCatalogFilterHint =>
      'Atlasiet dziesmu, lai filtrētu dziesmu vārdu versijas pēc akordiem, laika atzīmēm vai valodas.';

  @override
  String get startupErrorTitle => 'Neizdevās atvērt jūsu bibliotēku.';

  @override
  String setlistCopyName(String name) {
    return '$name kopija';
  }

  @override
  String get setlistSongMissing => 'Dziesma nav atrasta';

  @override
  String get settingsImportTooLarge =>
      'Šis fails ir pārāk liels, lai to importētu.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Pāriet uz burtu $letter';
  }

  @override
  String get actionDiscard => 'Atmest';

  @override
  String get editorKeepEditing => 'Turpināt rediģēt';

  @override
  String get settingsDefaultShowChordsHint =>
      'Rādīt akordus virs dziesmas vārdiem, ja tie ir pieejami.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Dziesmas vārdi ritinās līdzi dziesmai. Manuālās ritināšanas režīmā tas netiek izmantots.';

  @override
  String get accountUnavailableTitle => 'Sinhronizācija nav iestatīta';

  @override
  String get accountSignedOutBenefits =>
      'Pievienojot Google Drive, tiek sinhronizēta bibliotēka. Pēc tam dziesmu izmaiņas tiek sinhronizētas automātiski.';

  @override
  String get accountManualSyncHint =>
      'Varat arī pieskarties Sinhronizēt tūlīt, lai sinhronizētu bibliotēku.';

  @override
  String get accountSignInWithGoogle => 'Pierakstīties Google kontā';

  @override
  String get accountWorking => 'Notiek darbība…';

  @override
  String get accountNeverSynced => 'Nekad nav sinhronizēts';

  @override
  String get accountSyncedJustNow => 'Sinhronizēts tikko';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinhronizēts pirms $count minūtēm',
      one: 'Sinhronizēts pirms $count minūtes',
      zero: 'Sinhronizēts pirms $count minūtēm',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinhronizēts pirms $count stundām',
      one: 'Sinhronizēts pirms $count stundas',
      zero: 'Sinhronizēts pirms $count stundām',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinhronizēts pirms $count dienām',
      one: 'Sinhronizēts pirms $count dienas',
      zero: 'Sinhronizēts pirms $count dienām',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kā kopijas saglabāti $count konfliktējošie labojumi',
      one: 'Kā kopija saglabāts $count konfliktējošais labojums',
      zero: 'Kā kopijas saglabāts $count konfliktējošu labojumu',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Viena un tā pati dziesma vai koncertprogramma tika rediģēta divās vietās. Nekas nav pazaudēts: otra versija saglabāta kā atsevišķa kopija.';

  @override
  String get accountReviewConflicts => 'Pārskatīt kopijas';

  @override
  String get songsConflictFilterActive => 'Rāda tikai konflikta kopijas';

  @override
  String get songsConflictFilterClear => 'Rādīt visas dziesmas';

  @override
  String get songsConflictBadge => 'Konflikta kopija';

  @override
  String get songsConflictEmpty => 'Konflikta kopiju nav.';

  @override
  String get accountAutoSync => 'Sinhronizēt automātiski';

  @override
  String get accountAutoSyncHint =>
      'Bibliotēka tiek sinhronizēta pēc savienojuma izveides un pēc dziesmas pievienošanas, rediģēšanas vai noņemšanas.';

  @override
  String get accountDriveFolder => 'Google diska bibliotēkas mape';

  @override
  String get accountPrivateDriveFolder => 'Privātā Singbook mape';

  @override
  String get accountChooseDriveFolder => 'Izvēlieties mapi';

  @override
  String get accountDriveFolderMoveTitle =>
      'Vai pārvietot savu dziesmu grāmatu bibliotēku?';

  @override
  String get accountDriveFolderMoveBody =>
      'Izvēlieties redzamu Google diska mapi. Singbook pirms pārslēgšanās uz to nokopēs un pārbaudīs jūsu dziesmas un setu sarakstus. Oriģinālie faili tiek saglabāti to iepriekšējā atrašanās vietā kā rezerves kopija. Citi faili tiek atstāti atsevišķi. ChordPro faili, ko importējat šajā mapē, tiek pieņemti sinhronizēšanai un saņem Singbook metadatus.';

  @override
  String get accountImportChordPro => 'Importējiet ChordPro no diska';

  @override
  String get accountImportChordProHint =>
      'Izvēlieties .cho failus, ko pievienot šai bibliotēkai. Mapē jau esošie faili tiek pieņemti; šeit tiek kopēti faili citur.';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'Diska mapes atlase nav pieejama';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'Atbalstītā ierīcē izvēlieties redzamu Diska mapi, izmantojot Google diska atlasītāju.';

  @override
  String get syncErrorDriveFolderMissing => 'Singbook Drive mape nav pieejama';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Vēlreiz izvēlieties mapi vai atjaunojiet to Google diskā.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook ir nepieciešama piekļuve šai Diska mapei';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Vēlreiz izvēlieties mapi, lai piešķirtu piekļuvi, un pēc tam sinhronizējiet savu bibliotēku.';

  @override
  String get syncErrorFolderMigration => 'Bibliotēku vēl nevarēja pārvietot';

  @override
  String get syncErrorFolderMigrationHint =>
      'Jūsu iepriekšējā bibliotēka joprojām ir drošībā. Pārbaudiet savienojumu un vēlreiz izvēlieties mapi, lai mēģinātu vēlreiz.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Vispirms izvēlieties redzamu Diska mapi';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'Pirms failu importēšanas no Diska ir nepieciešama redzama bibliotēkas mape.';

  @override
  String get accountSignOutTitle => 'Izrakstīties no šī konta?';

  @override
  String get accountSignOutBody =>
      'Dziesmas un koncertprogrammas paliks šajā ierīcē. To dublēšana un sinhronizēšana nenotiks, līdz pierakstīsieties vēlreiz.';

  @override
  String get accountUseDifferent => 'Izmantot citu kontu';

  @override
  String get accountSignInAgain => 'Pierakstīties vēlreiz';

  @override
  String get accountChooseAction => 'Izvēlieties, kā turpināt';

  @override
  String get accountChangedTitle => 'Cits Google konts';

  @override
  String get accountChangedBody =>
      'Šī ierīce pēdējo reizi tika sinhronizēta ar citu Google kontu. Izvēlieties, kas notiks ar šajā ierīcē esošajām dziesmām un koncertprogrammām.';

  @override
  String get accountChangedMerge => 'Apvienot ar jauno kontu';

  @override
  String get accountChangedMergeHint =>
      'Paturēt visu šajā ierīcē un pievienot jaunajam kontam.';

  @override
  String get accountChangedReplace => 'Aizstāt ar jaunā konta bibliotēku';

  @override
  String get accountChangedReplaceHint =>
      'Dziesmas šajā ierīcē, kuru nav jaunajā kontā, tiks noņemtas.';

  @override
  String get accountChangedSignOut => 'Atcelt un izrakstīties';

  @override
  String get accountStatusSignedOut =>
      'Konts un sinhronizācija: nav pierakstīts';

  @override
  String get accountStatusSignedIn => 'Konts un sinhronizācija: pierakstīts';

  @override
  String get accountStatusSyncing =>
      'Konts un sinhronizācija: notiek sinhronizācija';

  @override
  String get accountStatusSynced =>
      'Konts un sinhronizācija: bibliotēka ir atjaunināta';

  @override
  String get accountStatusError =>
      'Konts un sinhronizācija: radusies problēma, pieskarieties, lai pārskatītu';

  @override
  String get accountNoticeConflicts =>
      'Dažas dziesmas tika rediģētas divās vietās. Kopijas ir saglabātas.';

  @override
  String get accountNoticeSignedIn => 'Pierakstījāties.';

  @override
  String get accountNoticeSignedOut =>
      'Izrakstījāties. Dziesmas paliek šajā ierīcē.';

  @override
  String get syncErrorNotConfigured =>
      'Šajā versijā sinhronizācija nav iestatīta.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Izmantojiet Singbook versiju ar konfigurētu pierakstīšanos Google kontā.';

  @override
  String get syncErrorNotSignedIn => 'Pierakstīšanās nav veikta.';

  @override
  String get syncErrorNotSignedInHint =>
      'Pierakstieties, lai sinhronizētu bibliotēku.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google pieprasa pierakstīties vēlreiz.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Pierakstieties vēlreiz, lai turpinātu sinhronizēšanu. Dziesmas šajā ierīcē ir drošībā.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook nav atļaujas izmantot Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Pierakstieties vēlreiz un, kad tiek prasīts, atļaujiet piekļuvi Drive.';

  @override
  String get syncErrorRateLimited => 'Google pašlaik ierobežo pieprasījumus.';

  @override
  String get syncErrorRateLimitedHint =>
      'Uzgaidiet dažas minūtes un mēģiniet vēlreiz.';

  @override
  String get syncErrorStorageFull => 'Jūsu Google Drive ir pilns.';

  @override
  String get syncErrorStorageFullHint =>
      'Atbrīvojiet vietu Drive un mēģiniet vēlreiz.';

  @override
  String get syncErrorNetwork => 'Neizdevās sasniegt Google.';

  @override
  String get syncErrorNetworkHint =>
      'Pārbaudiet interneta savienojumu un mēģiniet vēlreiz.';

  @override
  String get syncErrorAccountChanged => 'Tika izmantots cits Google konts.';

  @override
  String get syncErrorAccountChangedHint =>
      'Izvēlieties, vai apvienot šīs ierīces bibliotēku ar šo kontu vai to aizstāt.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Sinhronizētā bibliotēka ir pārāk liela, lai Singbook to apstrādātu.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Noņemiet dziesmas vai koncertprogrammas no sinhronizētās bibliotēkas un mēģiniet vēlreiz.';

  @override
  String get syncErrorSignInFailed => 'Pierakstīšanās neizdevās.';

  @override
  String get syncErrorSignInFailedHint => 'Mēģiniet pierakstīties vēlreiz.';

  @override
  String get syncErrorGeneric => 'Neizdevās sinhronizēt bibliotēku.';

  @override
  String get syncErrorGenericHint =>
      'Pēc brīža mēģiniet vēlreiz. Dziesmas šajā ierīcē joprojām ir drošībā.';

  @override
  String get editorDurationInvalid =>
      'Ievadiet sekundes vai minūtes un sekundes, piemēram, 3:45.';

  @override
  String get editorNumberInvalid => 'Ievadiet skaitli.';

  @override
  String get accountReplaceConfirmTitle => 'Dzēst vietējās dziesmas?';

  @override
  String get accountReplaceConfirmBody =>
      'Šīs ierīces dziesmas un koncertprogrammas, kuru nav jaunajā kontā, tiks neatgriezeniski izdzēstas. To nevar atsaukt.';

  @override
  String get accountReplaceConfirmAction => 'Dzēst un aizstāt';

  @override
  String get accountSuspiciousTitle => 'Google Drive trūkst vienumu';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count vienumi, ko šī ierīce iepriekš sinhronizēja, nav atrodami Google Drive.',
      one:
          '$count vienums, ko šī ierīce iepriekš sinhronizēja, nav atrodams Google Drive.',
      zero:
          '$count vienumu, ko šī ierīce iepriekš sinhronizēja, nav atrodami Google Drive.',
    );
    return '$_temp0 Tā var notikt, ja Google iestatījumos tika dzēsti lietotnes dati. Pagaidām nekas nav dzēsts.';
  }

  @override
  String get accountSuspiciousDelete => 'Dzēst arī šeit';

  @override
  String get accountSuspiciousKeep =>
      'Saglabāt dziesmas un augšupielādēt vēlreiz';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dzēst $count vienumus no šīs ierīces?',
      one: 'Dzēst $count vienumu no šīs ierīces?',
      zero: 'Dzēst $count vienumu no šīs ierīces?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Šīs dziesmas un koncertprogrammas tiks neatgriezeniski izdzēstas no šīs ierīces. To nevar atsaukt.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Dzēst no šīs ierīces';

  @override
  String get syncErrorRemoteListingSuspicious => 'Google Drive trūkst vienumu.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Nekas nav dzēsts. Izvēlieties, vai dzēst tos arī šeit vai augšupielādēt vēlreiz.';

  @override
  String get syncErrorRemoteChanged =>
      'Sinhronizācijas laikā Google Drive tika mainīts.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Nekas nav zudis. Sinhronizējiet vēlreiz, lai saņemtu jaunākās izmaiņas.';

  @override
  String get syncErrorInvalidLocalData =>
      'Daļu šīs ierīces datu neizdevās sinhronizēt.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Neizdevās nolasīt dziesmu vai koncertprogrammu. Importējiet vai izveidojiet to no jauna un sinhronizējiet vēlreiz.';

  @override
  String get syncErrorNoAccountChange =>
      'Nav konta izmaiņu, kas būtu jāatrisina.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Lai turpinātu, sinhronizējiet vēlreiz.';

  @override
  String get accountSyncWarningTitle =>
      'Sinhronizēts, bet daži faili tika izlaisti';

  @override
  String get accountSyncWarningBody =>
      'Dažus failus nevarēja izmantot, un tie palika nemainīti. Pārējais ir atjaunināts.';

  @override
  String get accountSyncWarningTooLarge =>
      'Fails bija pārāk liels sinhronizācijai, tāpēc tika izlaists. Pārējais ir atjaunināts.';

  @override
  String get accountSyncWarningInvalid =>
      'Failu nevarēja nolasīt, tāpēc tas tika izlaists. Pārējais ir atjaunināts.';

  @override
  String get accountNoticeSyncSkipped =>
      'Sinhronizēts. Daži faili tika izlaisti.';

  @override
  String get settingsExportPdfTooLarge =>
      'Šis PDF būtu pārāk liels. Izvēlieties mazāk dziesmu vai kopīgojiet to kā tekstu.';

  @override
  String get settingsTimingTooLarge =>
      'Laika dati ir pārāk lieli (vairāk nekā 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Dublējumkopijā viena dziesma ir norādīta divreiz, tāpēc nekas netika importēts.';

  @override
  String get setlistSaveConflict =>
      'Koncertprogramma tika mainīta citur. Jūsu labojumi saglabāti atsevišķā kopijā.';

  @override
  String get sectionVerse => 'Pants';

  @override
  String get sectionChorus => 'Piedziedājums';

  @override
  String get sectionBridge => 'Tilts';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pirms piedziedājuma';

  @override
  String get sectionPostChorus => 'Pēc piedziedājuma';

  @override
  String get sectionInstrumental => 'Instrumentāls';

  @override
  String get sectionInterlude => 'Starpspēle';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Refrēns';

  @override
  String get sectionHook => 'Āķis';

  @override
  String get sectionBreakdown => 'Instrumentālais pārtraukums';

  @override
  String get sectionCoda => 'Koda';

  @override
  String get sectionTag => 'Atzīme';

  @override
  String get sectionEnding => 'Nobeigums';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieejamas versijas',
      one: '$count pieejama versija',
      zero: 'Nav pieejamu versiju',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nepieejamas versijas',
      one: '$count nepieejama versija',
      zero: 'Nav nepieejamu versiju',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Pāriet uz sadaļu';

  @override
  String get searchVersionDetails => 'Versijas informācija';

  @override
  String get searchSelectedRecording => 'Atlasītais ieraksts';

  @override
  String get searchVersionDuration => 'Versijas ilgums';

  @override
  String get searchSourceOptions => 'Avota opcijas';

  @override
  String get actionUndo => 'Atsaukt';

  @override
  String setlistEntryRemoved(String song) {
    return 'Dziesma „$song” noņemta no dziesmu saraksta';
  }

  @override
  String get backupTitle => 'Dublēšana un atjaunošana';

  @override
  String get backupExport => 'Eksportēt dublējumu';

  @override
  String get backupRestore => 'Atjaunot dublējumu';

  @override
  String get backupIncludePreferences => 'Iekļaut lietotnes preferences';

  @override
  String get backupRestorePreferences => 'Atjaunot lietotnes preferences';

  @override
  String get backupMerge => 'Pievienot šai bibliotēkai';

  @override
  String get backupMergeHint =>
      'Saglabājiet vietējos labojumus un pievienojiet dziesmas un sarakstus no šī dublējuma.';

  @override
  String get backupReplace => 'Aizstāt šo bibliotēku';

  @override
  String get backupReplaceHint =>
      'Aizstājiet visas šīs ierīces dziesmas un sarakstus ar šī dublējuma saturu.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Dziesmas: $songs · Saraksti: $setlists · Konflikti: $conflicts';
  }

  @override
  String get backupFailed =>
      'Dublēšanas darbību neizdevās pabeigt. Mēģiniet vēlreiz.';

  @override
  String get backupRestored => 'Dublējums atjaunots.';

  @override
  String get backupLocalHint =>
      'Saglabājiet savas bibliotēkas kopiju. Konta dati un piekrišanas sīkfaili netiek iekļauti.';

  @override
  String get backupReplaceConfirm =>
      'Aizstāt pašreizējo bibliotēku? Šo darbību nevar atsaukt.';

  @override
  String get searchCheckOperations => 'Darbības';

  @override
  String get searchCheckCode => 'Rezultāta kods';

  @override
  String get searchCheckQueued => 'Gaida šī avota pārbaudi.';

  @override
  String get searchCheckFetch => 'Ielādēt dziesmas vārdus';

  @override
  String get searchCheckValidate => 'Pārbaudīt dziesmas atbilstību';

  @override
  String get searchCheckCorroborate => 'Pārbaudīt vārdu atbilstību';

  @override
  String get searchCheckCompleted => 'Pabeigts';

  @override
  String get searchCheckTimeout => 'Avots neatbildēja laikus.';

  @override
  String get searchCheckBlocked => 'Avots bloķēja pieprasījumu.';

  @override
  String get searchCheckRateLimited =>
      'Avots ierobežo pieprasījumus. Mēģiniet vēlāk vēlreiz.';

  @override
  String get searchCheckNetwork =>
      'Neizdevās sasniegt avotu. Pārbaudiet savienojumu.';

  @override
  String get searchCheckInvalid => 'Avots atgrieza nelasāmu atbildi.';

  @override
  String get searchCheckNotConfigured =>
      'Šis avots šajā versijā nav konfigurēts.';

  @override
  String get searchCheckNoLyrics => 'Atbilstoši dziesmas vārdi netika atrasti.';

  @override
  String get searchCheckFailed => 'Šo darbību neizdevās pabeigt.';

  @override
  String get searchCheckNoHistory => 'Šim salīdzinājumam avoti nav pārbaudīti.';

  @override
  String get searchVersionCredits => 'Autori un avoti';

  @override
  String get searchVersionMediaLinks => 'Saistītās saites';

  @override
  String get searchCheckCancelled => 'Atcelts';

  @override
  String get searchCheckAmbiguous =>
      'Atrastas vairāk nekā viens atbilstības rezultāts. Šim avotam vajadzīgs konkrētāks ieraksts.';

  @override
  String get searchCheckIdentity =>
      'Šim avotam vajadzīgs ieraksta vai darba identifikators.';

  @override
  String get searchCheckExtraction =>
      'Avots atbildēja, taču dziesmas vārdus neizdevās iegūt.';

  @override
  String get searchCheckBusy => 'Avots ir aizņemts. Mēģiniet vēlāk vēlreiz.';

  @override
  String get searchCheckSelection => 'Izvēlieties konkrētu šī avota rezultātu.';

  @override
  String get playerChordsNone => 'Nav';

  @override
  String get editorCustomValue => 'Cits…';

  @override
  String get editorStandardTuning => 'Standarta skaņojums';

  @override
  String get editorExampleVerse =>
      '[C]Jauna diena mūs [G]sauc,\n[Am]mēs sekojam gaismai atpakaļ [F]mājās.';

  @override
  String get editorExampleChorus =>
      '[F]Dziedāsim šo dziesmu [C]kopā,\n[G]lai melodija mūs nes [C]tālāk.';

  @override
  String get editorExampleBridge => '[Am]Vēl viena rinda, mazliet [F]tuvāk.';

  @override
  String get playerEstimatedKey => 'Aptuvenā tonalitāte';

  @override
  String get songsLibraryView => 'Bibliotēka';

  @override
  String get settingsStartupView => 'Sākuma skats';

  @override
  String get settingsStartupViewHint =>
      'Izvēlieties dziesmu skatu, kas tiks rādīts, atverot lietotni.';

  @override
  String get settingsStartupLastView => 'Pēdējoreiz atvērtais';

  @override
  String get playerFullScreen => 'Pilnekrāna režīms';

  @override
  String get playerExitFullScreen => 'Iziet no pilnekrāna režīma';

  @override
  String get playerExpandControls => 'Rādīt atskaņošanas vadīklas';

  @override
  String get playerCollapseControls => 'Paslēpt atskaņošanas vadīklas';

  @override
  String get settingsShowSections => 'Rādīt sadaļu virsrakstus';

  @override
  String get settingsShowSectionsHint =>
      'Dziesmas tekstā rādīt pantu, piedziedājuma un citu sadaļu virsrakstus.';

  @override
  String get settingsShowPlayerControls => 'Rādīt atskaņošanas vadīklas';

  @override
  String get settingsShowPlayerControlsHint =>
      'Atskaņotāja paneli var parādīt vai paslēpt arī, pieskaroties tam vai pārvelkot.';
}
