// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Rahulik koht oma laulude leidmiseks, korrastamiseks ja laulmiseks.';

  @override
  String get aboutMadeForSinging => 'Loodud koos laulmiseks';

  @override
  String appVersion(String version) {
    return 'Versioon $version';
  }

  @override
  String get navHome => 'Avaleht';

  @override
  String get navSongs => 'Laulud';

  @override
  String get navSetlists => 'Laulunimekirjad';

  @override
  String get navSettings => 'Seaded';

  @override
  String get navSettingsCompact => 'Seaded';

  @override
  String get navSearch => 'Otsi';

  @override
  String get navBack => 'Tagasi';

  @override
  String get navClose => 'Sulge';

  @override
  String get navMore => 'Veel toiminguid';

  @override
  String get actionCancel => 'Tühista';

  @override
  String get actionSave => 'Salvesta';

  @override
  String get actionDone => 'Valmis';

  @override
  String get actionEdit => 'Muuda';

  @override
  String get actionDelete => 'Kustuta';

  @override
  String get actionShare => 'Jaga';

  @override
  String get actionPrint => 'Prindi';

  @override
  String get actionCopy => 'Kopeeri';

  @override
  String get actionClear => 'Tühjenda';

  @override
  String get actionRetry => 'Proovi uuesti';

  @override
  String get actionRefresh => 'Värskenda';

  @override
  String get actionImport => 'Impordi';

  @override
  String get actionExport => 'Ekspordi';

  @override
  String get actionExpand => 'Laienda';

  @override
  String get actionCollapse => 'Ahenda';

  @override
  String get actionAdd => 'Lisa';

  @override
  String get actionCreate => 'Loo';

  @override
  String get actionRemove => 'Eemalda';

  @override
  String get actionDuplicate => 'Tee koopia';

  @override
  String get actionMoveUp => 'Liiguta üles';

  @override
  String get actionMoveDown => 'Liiguta alla';

  @override
  String get actionPrevious => 'Eelmine';

  @override
  String get actionNext => 'Järgmine';

  @override
  String get searchHint => 'Otsi laule, esitajaid või sõnu';

  @override
  String get searchCatalogHint => 'Otsi laulu või esitajat';

  @override
  String get searchChangeSong => 'Vaheta laulu';

  @override
  String get searchSelectedPreview => 'Valitud eelvaade';

  @override
  String get searchSubmit => 'Otsi';

  @override
  String get searchFilters => 'Otsinguvalikud';

  @override
  String get searchFiltersShow => 'Näita otsinguvalikuid';

  @override
  String get searchFiltersHide => 'Peida otsinguvalikud';

  @override
  String get searchFilterArtist => 'Esitaja';

  @override
  String get searchFilterTitle => 'Laulu pealkiri';

  @override
  String get searchFilterLyrics => 'Laulusõnad';

  @override
  String get searchFilterChords => 'Akordidega';

  @override
  String get searchFilterTimed => 'Ajastatud laulusõnad';

  @override
  String get searchFilterLanguage => 'Keel';

  @override
  String get searchFilterAll => 'Kõik';

  @override
  String get searchAutocompleteLabel => 'Soovitused';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tulemust',
      one: '1 tulemus',
      zero: 'Tulemusi pole',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Sisesta otsimiseks laulu pealkiri, esitaja või sõnad.';

  @override
  String get searchCatalogEmptyQuery =>
      'Sisesta otsimiseks laulu pealkiri või esitaja.';

  @override
  String get searchNoResults => 'Laule ei leitud. Proovi teist otsingut.';

  @override
  String get searchLoading => 'Laulude otsimine…';

  @override
  String get searchError => 'Otsingut ei õnnestunud teha.';

  @override
  String get searchOnlineTab => 'Veebist';

  @override
  String get searchRecentTab => 'Hiljutised';

  @override
  String get searchFavoritesTab => 'Lemmikud';

  @override
  String get searchSuggested => 'Soovitatud vaste';

  @override
  String get searchAlternatives => 'Muud vasted';

  @override
  String get searchCompare => 'Võrdle versioone';

  @override
  String get searchChooseVersion => 'Vali see versioon';

  @override
  String get searchSongMatch => 'Laulu vaste';

  @override
  String get searchRecordingMatch => 'Salvestise vaste';

  @override
  String get searchMatchUnverified => 'Salvestis pole kinnitatud';

  @override
  String get searchMatchExact => 'Salvestis vastab täpselt';

  @override
  String get searchMatchPossible => 'Võimalik vaste';

  @override
  String get searchAvailability => 'Saadavus';

  @override
  String get searchLyricsAvailable => 'Laulusõnad on saadaval';

  @override
  String get searchLyricsUnavailable => 'Laulusõnad pole saadaval';

  @override
  String get searchChordsAvailable => 'Akordid on saadaval';

  @override
  String get searchChordsUnavailable => 'Akorde pole';

  @override
  String get searchTimingAvailable => 'Ajastus on saadaval';

  @override
  String get searchTimingUnavailable => 'Ajastus puudub';

  @override
  String get searchDurationUnknown => 'Kestus teadmata';

  @override
  String searchRating(String rating) {
    return 'Hinnang $rating';
  }

  @override
  String get searchSourceLabel => 'Allikas';

  @override
  String get searchMetadata => 'Laulu andmed';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Esitaja';

  @override
  String get searchYear => 'Aasta';

  @override
  String get searchLanguage => 'Keel';

  @override
  String get searchViewVersions => 'Vaata versioone';

  @override
  String get searchSaved => 'Laul salvestati sinu kogusse.';

  @override
  String get searchSaveOpenLyrics => 'Salvesta ja ava sõnad';

  @override
  String get searchOtherResults => 'Muud tulemused';

  @override
  String get searchSaveFailed => 'Laulu salvestamine ebaõnnestus.';

  @override
  String get homeRecentSongs => 'Hiljutised laulud';

  @override
  String get homeRecentlyPlayed => 'Hiljuti esitatud';

  @override
  String get homeFavorites => 'Lemmikud';

  @override
  String get homeHistory => 'Ajalugu';

  @override
  String get homeHistoryClear => 'Kustuta ajalugu';

  @override
  String get homeHistoryCleared => 'Ajalugu kustutati.';

  @override
  String get homeHistoryEmpty => 'Siin kuvatakse avatud laulud.';

  @override
  String get homeFavoritesEmpty =>
      'Siin kuvatakse sinu lemmiklaulud ja laulunimekirjad.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kuvatud $count üksust',
      one: 'Kuvatud 1 üksus',
      zero: 'Kuvatud 0 üksust',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Siin kuvatakse sinu hiljutised laulud ja laulunimekirjad.';

  @override
  String get homeTimelineLabel => 'Ajaloo ajajoon';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Kogu ajalugu';

  @override
  String get homeShowFavorites => 'Näita lemmikuid';

  @override
  String get homeShowRecent => 'Näita hiljutisi';

  @override
  String get songsTitle => 'Laulud';

  @override
  String get songsEmpty => 'Siin kuvatakse sinu laulud.';

  @override
  String get songsEmptySearch => 'Ükski laul ei vasta otsingule.';

  @override
  String get songsAdd => 'Lisa laul';

  @override
  String get songsSortAlphabetical => 'Sorteeri tähestiku järgi';

  @override
  String get songsAlphabetNavigation => 'Laulude register';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count korda',
      one: 'üks kord',
      zero: 'mitte kordagi',
    );
    return 'Avatud $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Lisa lemmikutesse';

  @override
  String get songFavoriteRemove => 'Eemalda lemmikutest';

  @override
  String get songMenuLabel => 'Laulu toimingud';

  @override
  String get songInfo => 'Laulu andmed';

  @override
  String get setlistMenuLabel => 'Laulunimekirja toimingud';

  @override
  String get songAddToSetlist => 'Lisa laulunimekirja';

  @override
  String get songCopyChordPro => 'Kopeeri ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Kas kustutada laul?';

  @override
  String get songDeleteConfirmMessage => 'See laul eemaldatakse sinu kogust.';

  @override
  String get songDeleted => 'Laul kustutati.';

  @override
  String get setlistsTitle => 'Laulunimekirjad';

  @override
  String get setlistsEmpty =>
      'Loo laulunimekiri järgmiseks prooviks või esinemiseks.';

  @override
  String get setlistsEmptySearch => 'Ükski laulunimekiri ei vasta otsingule.';

  @override
  String get setlistCreate => 'Uus laulunimekiri';

  @override
  String get setlistNameHint => 'Laulunimekirja nimi';

  @override
  String get setlistNotes => 'Märkmed';

  @override
  String get setlistEntryOverride => 'Laulupõhine helistik ja capo';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count laulu',
      one: '1 laul',
      zero: 'Laule pole',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Vähemalt $duration';
  }

  @override
  String get setlistDurationUnknown => 'Kestus teadmata';

  @override
  String setlistActivity(String date) {
    return 'Viimane tegevus $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Loodud $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Muudetud $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Viimati esitatud $date';
  }

  @override
  String get setlistSongsEmpty => 'Selles laulunimekirjas pole veel laule.';

  @override
  String get setlistAddSongs => 'Lisa laule';

  @override
  String get setlistReorder => 'Muuda laulude järjekorda';

  @override
  String setlistMoveSongUp(String song) {
    return 'Liiguta $song üles';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Liiguta $song alla';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Eemalda $song laulunimekirjast';
  }

  @override
  String get setlistDuplicate => 'Tee laulunimekirjast koopia';

  @override
  String get setlistFavoriteAdd => 'Lisa laulunimekiri lemmikutesse';

  @override
  String get setlistFavoriteRemove => 'Eemalda laulunimekiri lemmikutest';

  @override
  String get setlistShare => 'Jaga laulunimekirja failina';

  @override
  String get setlistSharePdf => 'Jaga PDF-ina';

  @override
  String get setlistPrint => 'Prindi';

  @override
  String get setlistDeleteConfirmTitle => 'Kas kustutada laulunimekiri?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Laulunimekiri eemaldatakse. Sinu kogus olevad laulud jäävad alles.';

  @override
  String get setlistDeleted => 'Laulunimekiri kustutati.';

  @override
  String get readerTitle => 'Laulusõnad';

  @override
  String get readerNoLyrics => 'Laulusõnu pole veel lisatud.';

  @override
  String get readerShowChords => 'Näita akorde';

  @override
  String get readerHideChords => 'Peida akordid';

  @override
  String get readerTranspose => 'Transponeeri akorde';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pooltooni',
      one: '1 pooltoon',
      zero: '0 pooltooni',
    );
    return 'Transponeeri $_temp0';
  }

  @override
  String get readerSaved => 'Salvestatud';

  @override
  String get readerEdit => 'Muuda sõnu ja andmeid';

  @override
  String get playerPlay => 'Alusta laulusõnade kerimist';

  @override
  String get playerPause => 'Peata laulusõnade kerimine';

  @override
  String get playerResume => 'Jätka laulusõnade kerimist';

  @override
  String get playerSeek => 'Taasesituse asukoht';

  @override
  String playerElapsed(String time) {
    return 'Möödunud aeg $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Aega jäänud $time';
  }

  @override
  String get playerTimingMode => 'Kerimise režiim';

  @override
  String get playerTimedLyrics => 'Ajastatud laulusõnad';

  @override
  String get playerStartScroll => 'Alusta automaatset kerimist';

  @override
  String get playerEstimatedPace => 'Hinnanguline kerimiskiirus';

  @override
  String get playerScrollSpeed => 'Kerimise kiirus';

  @override
  String playerEstimatedDuration(String time) {
    return 'Hinnanguline kestus: $time';
  }

  @override
  String get playerLyricsOnly => 'Laulusõnade kerimine · helita';

  @override
  String get playerManualScroll => 'Käsitsi kerimine';

  @override
  String get playerTimingStatusReady =>
      'Laulusõnad liiguvad olemasoleva ajastuse järgi.';

  @override
  String get playerTimingStatusEstimated =>
      'Kerimiskiirus on hinnatud laulu kestuse järgi.';

  @override
  String get playerTimingStatusManual => 'Keri laulusõnu ise.';

  @override
  String get playerTimingStatusUnavailable =>
      'Selle laulu ajastatud kerimine pole saadaval.';

  @override
  String get playerDurationUnknown =>
      'Lisa laulu kestus, et kasutada hinnangulist kerimist.';

  @override
  String get playerProgressLabel => 'Laulu edenemine';

  @override
  String get playerCurrentSection => 'Praegune osa';

  @override
  String get playerPreviousSection => 'Eelmine osa';

  @override
  String get playerNextSection => 'Järgmine osa';

  @override
  String get playerPreviousSectionSong =>
      'Eelmine osa · hoia all eelmise laulunimekirja laulu jaoks';

  @override
  String get playerNextSectionSong =>
      'Järgmine osa · hoia all järgmise laulunimekirja laulu jaoks';

  @override
  String get playerPreviousSong => 'Eelmine laul';

  @override
  String get playerNextSong => 'Järgmine laul';

  @override
  String get editorTitle => 'Muuda laulu';

  @override
  String get editorTitleField => 'Laulu pealkiri';

  @override
  String get editorArtistField => 'Esitaja';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Laulusõnad';

  @override
  String get editorChordsField => 'Akordid';

  @override
  String get editorKeyField => 'Helistik';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Häälestus';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Kestus';

  @override
  String get editorTimeSignatureField => 'Mõõt';

  @override
  String get editorLanguageField => 'Keel';

  @override
  String get editorYearField => 'Aasta';

  @override
  String get editorComposerField => 'Helilooja';

  @override
  String get editorLyricistField => 'Sõnade autor';

  @override
  String get editorCopyrightField => 'Autoriõigus';

  @override
  String get editorLicenseField => 'Litsents';

  @override
  String get songInfoSources => 'Allikad ja autoriteave';

  @override
  String get searchMatchSameSong => 'Sama laul; salvestis pole kinnitatud';

  @override
  String get searchMatchNeedsAgreement =>
      'Laulu noodistus vajab sõnade kinnitust';

  @override
  String get searchMatchDifferentLyrics =>
      'Laulusõnad erinevad valitud laulust';

  @override
  String get searchMatchCombinedSources =>
      'Andmed on ühendatud mitmest allikast';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ühendatud $count allikast',
      one: 'Ühendatud 1 allikast',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count laulu vastet',
      one: '1 laulu vaste',
      zero: '0 laulu vastet',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allikaversiooni',
      one: '1 allikaversioon',
      zero: '0 allikaversiooni',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Parim saadaolev vaste';

  @override
  String get providerDescriptionUnknown => 'Laulu allikas';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Laadi allikast alla ChordPro-fail ja impordi see.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Laadi fail tasuta kontoga alla ja impordi see.';

  @override
  String get providerDescPublicChordSheets => 'Avalikud akordilehed.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Ajalooliste laulusõnade litsents määratakse teose kaupa.';

  @override
  String get providerDescLicensedCatalog =>
      'Litsentsitud laulusõnade kataloog.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Originaallaulud Creative Commons BY litsentsi alusel.';

  @override
  String get providerDescPerSongLicense =>
      'Laulusõnade litsents määratakse laulu kaupa.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Ainult salvestise ja väljaande andmed.';

  @override
  String get providerDescCompositionMetadataOnly => 'Ainult heliteose andmed.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Kaanepilt ainult täpselt vastavate salvestiste puhul.';

  @override
  String get providerCapabilityLyrics => 'Laulusõnad';

  @override
  String get providerCapabilityChords => 'Akordid';

  @override
  String get providerCapabilityTiming => 'Ajastatud laulusõnad';

  @override
  String get providerCapabilitySearch => 'Otsing';

  @override
  String get providerCapabilityMetadata => 'Laulu andmed';

  @override
  String get editorArtworkField => 'Kaanepildi link';

  @override
  String get editorLyricsHint => 'Puuduta rida, et muuta laulusõnu või akorde.';

  @override
  String get editorSave => 'Salvesta muudatused';

  @override
  String get editorSaved => 'Muudatused salvestati.';

  @override
  String get editorSaveFailed => 'Muudatuste salvestamine ebaõnnestus.';

  @override
  String get editorSaveConflict =>
      'Laulu muudeti mujal. Sinu muudatused salvestati eraldi koopiana.';

  @override
  String get editorUnsavedTitle => 'Kas loobuda muudatustest?';

  @override
  String get editorUnsavedMessage => 'Sinu muudatusi pole salvestatud.';

  @override
  String get editorFieldRequired => 'Sisesta laulu pealkiri.';

  @override
  String get settingsTitle => 'Seaded';

  @override
  String get settingsAppearance => 'Välimus';

  @override
  String get settingsTheme => 'Teema';

  @override
  String get settingsThemeSystem => 'Kasuta seadme seadet';

  @override
  String get settingsThemeLight => 'Hele';

  @override
  String get settingsThemeDark => 'Tume';

  @override
  String get settingsColorPalette => 'Värvipalett';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsTextSize => 'Teksti suurus';

  @override
  String get settingsLyricsPreview => 'Laulusõnade eelvaade';

  @override
  String get settingsPlayer => 'Laulusõnade mängija';

  @override
  String get settingsDefaultShowChords => 'Näita vaikimisi akorde';

  @override
  String get settingsDefaultAutoscroll =>
      'Alusta laulusõnade automaatset kerimist';

  @override
  String get settingsDefaultTiming => 'Vaikimisi kerimisrežiim';

  @override
  String get settingsLanguage => 'Rakenduse keel';

  @override
  String get settingsLanguageSystem => 'Kasuta seadme keelt';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Laulusõnade allikad';

  @override
  String settingsSourceEnabled(String source) {
    return 'Luba allikas $source';
  }

  @override
  String get settingsSourceRefresh => 'Värskenda allikate loendit';

  @override
  String get settingsSourcesUpdated => 'Allikad värskendati.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Allikaid ei õnnestunud värskendada.';

  @override
  String get settingsImport => 'Impordi laulud';

  @override
  String get settingsImportChordPro => 'Impordi ChordPro-fail';

  @override
  String get settingsImportSetlist => 'Impordi laulunimekirja fail';

  @override
  String get settingsImportSuccess => 'Importimine lõpetatud.';

  @override
  String get settingsImportFailed => 'Faili importimine ebaõnnestus.';

  @override
  String get settingsImportUnsupported => 'Seda failitüüpi ei toetata.';

  @override
  String get settingsShareSong => 'Jaga ChordPro-failina';

  @override
  String get settingsSharePdf => 'Jaga PDF-ina';

  @override
  String get settingsCopySong => 'Kopeeri lõikelauale';

  @override
  String get settingsPrintSong => 'Prindi ainult laul';

  @override
  String get settingsPrintSetlist => 'Prindi laulunimekiri koos laulusõnadega';

  @override
  String get settingsExportFailed => 'Faili ettevalmistamine ebaõnnestus.';

  @override
  String get settingsCopied => 'Lõikelauale kopeeritud.';

  @override
  String get settingsAbout => 'Teave';

  @override
  String get settingsPrivacy => 'Privaatsus';

  @override
  String get settingsLegal => 'Õigusteave';

  @override
  String get settingsClearHistory => 'Kustuta ajalugu';

  @override
  String get settingsClearHistoryConfirm =>
      'Kas kustutada laulude ja laulunimekirjade ajalugu?';

  @override
  String get settingsHistoryCleared => 'Ajalugu kustutati.';

  @override
  String get accountTitle => 'Konto ja sünkroonimine';

  @override
  String get accountUnavailable =>
      'Sünkroonimiseks on vaja Singbooki versiooni, kus Google\'i sisselogimine on seadistatud. Selles versioonis hoitakse laule ainult selles seadmes.';

  @override
  String get accountSyncNow => 'Sünkrooni kohe';

  @override
  String get accountConnected =>
      'Ühendatud. Vali varukoopia uuendamiseks „Sünkrooni kohe”.';

  @override
  String get accountSignIn => 'Ühenda konto';

  @override
  String get accountSignOut => 'Logi välja';

  @override
  String get accountChange => 'Vaheta kontot';

  @override
  String get accountSignedOut => 'Ühendamata';

  @override
  String get accountSyncing => 'Sinu kogu sünkroonimine…';

  @override
  String get accountSynced => 'Kogu sünkrooniti.';

  @override
  String get accountSyncFailed => 'Kogu sünkroonimine ebaõnnestus.';

  @override
  String get accessibilityFavorite => 'Lemmik';

  @override
  String get accessibilityNotFavorite => 'Pole lemmik';

  @override
  String get accessibilitySearchField => 'Otsi laule';

  @override
  String get accessibilityClearSearch => 'Kustuta otsingutekst';

  @override
  String accessibilitySongMenu(String song) {
    return 'Laulu $song toimingud';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Laulunimekirja $setlist toimingud';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Laienda laulunimekirja $setlist laule';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Ahenda laulunimekirja $setlist laulud';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Taasesituse edenemine, $percent protsenti';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Ajaloo ajajoon, $date';
  }

  @override
  String get loading => 'Laadimine…';

  @override
  String get loadingSongs => 'Laulude laadimine…';

  @override
  String get loadingSetlists => 'Laulunimekirjade laadimine…';

  @override
  String get errorGeneric => 'Midagi läks valesti.';

  @override
  String get errorOffline => 'Paistab, et internetiühendus puudub.';

  @override
  String get errorPermission => 'Jätkamiseks on vaja luba.';

  @override
  String get emptyFiltered => 'Ükski üksus ei vasta nendele filtritele.';

  @override
  String get unknownValue => 'Teadmata';

  @override
  String get durationUnknown => 'Kestus teadmata';

  @override
  String get metadataNotSet => 'Määramata';

  @override
  String get dateToday => 'Täna';

  @override
  String get dateYesterday => 'Eile';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count laulu',
      one: '1 laul',
      zero: 'Laule pole',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Meresinine';

  @override
  String get settingsPaletteSage => 'Salveiroheline';

  @override
  String get settingsPaletteOcean => 'Ookean';

  @override
  String get settingsPaletteClay => 'Savi';

  @override
  String get settingsPalettePlum => 'Ploom';

  @override
  String get settingsFontSystem => 'Süsteem';

  @override
  String get settingsFontSerif => 'Seriif';

  @override
  String get settingsFontMonospace => 'Monolaiusega';

  @override
  String get settingsLyricsPreviewExample =>
      'Kui hommik saabub, laulame jälle.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Laulusõnade allikate kontrollimine: $checked / $total tehtud.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Kasutatavaid laulusõnu ei leitud.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Valitud laulu kontrolliti lubatud allikatest, kuid ükski neist ei tagastanud kasutatavat laulusõnade versiooni.';

  @override
  String get searchDiscoveryError =>
      'Laulusõnade allikaid ei õnnestunud kontrollida.';

  @override
  String get searchDiscoveryRetry => 'Otsi laulusõnu uuesti';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allikat pole saadaval',
      one: '1 allikas pole saadaval',
      zero: '0 allikat pole saadaval',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails =>
      'Kontrolli internetiühendust ja proovi uuesti.';

  @override
  String get searchProviderChecks => 'Allikate kontrollid';

  @override
  String get searchProviderPending => 'Kontrollimine';

  @override
  String get searchProviderFound => 'Leiti vaste';

  @override
  String get searchProviderRejected => 'Ei sobi';

  @override
  String get searchProviderFailed => 'Kontroll ebaõnnestus';

  @override
  String get searchProviderUnavailable => 'Kasutatavaid laulusõnu pole';

  @override
  String get searchCatalogFilterHint =>
      'Vali laul, et filtreerida laulusõnade versioone akordide, ajastuse või keele järgi.';

  @override
  String get startupErrorTitle => 'Sinu kogu avamine ebaõnnestus.';

  @override
  String setlistCopyName(String name) {
    return '$name koopia';
  }

  @override
  String get setlistSongMissing => 'Puuduv laul';

  @override
  String get settingsImportTooLarge => 'See fail on importimiseks liiga suur.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Hüppa tähe $letter juurde';
  }

  @override
  String get actionDiscard => 'Loobu';

  @override
  String get editorKeepEditing => 'Jätka muutmist';

  @override
  String get settingsDefaultShowChordsHint =>
      'Näita akordidega laulu puhul akorde laulusõnade kohal.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Laulusõnad kerivad koos lauluga. Käsitsi kerimise režiimis seda ei kasutata.';

  @override
  String get accountUnavailableTitle => 'Sünkroonimine pole seadistatud';

  @override
  String get accountSignedOutBenefits =>
      'Logi Google\'iga sisse, et varundada laulud ja laulunimekirjad Google Drive\'i ning hoida kõik seadmed sünkroonis. Laulud jäävad igal juhul sellesse seadmesse.';

  @override
  String get accountSignInWithGoogle => 'Logi sisse Google\'iga';

  @override
  String get accountWorking => 'Töötamine…';

  @override
  String get accountNeverSynced => 'Pole kunagi sünkroonitud';

  @override
  String get accountSyncedJustNow => 'Äsja sünkroonitud';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sünkroonitud $count minuti eest',
      one: 'Sünkroonitud 1 minuti eest',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sünkroonitud $count tunni eest',
      one: 'Sünkroonitud 1 tunni eest',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sünkroonitud $count päeva eest',
      one: 'Sünkroonitud 1 päeva eest',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vastuolulist muudatust salvestati koopiatena',
      one: '1 vastuoluline muudatus salvestati koopiana',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Sama laulu või laulunimekirja muudeti kahes kohas. Midagi ei läinud kaduma: teine versioon salvestati eraldi koopiana.';

  @override
  String get accountReviewConflicts => 'Vaata koopiad üle';

  @override
  String get songsConflictFilterActive => 'Kuvatakse ainult konflikti koopiaid';

  @override
  String get songsConflictFilterClear => 'Näita kõiki laule';

  @override
  String get songsConflictBadge => 'Konflikti koopia';

  @override
  String get songsConflictEmpty => 'Konflikti koopiaid pole.';

  @override
  String get accountAutoSync => 'Sünkrooni automaatselt';

  @override
  String get accountAutoSyncHint =>
      'Hoia kogu ajakohasena rakenduse avamisel ja pärast muudatusi.';

  @override
  String get accountSignOutTitle => 'Kas logida sellelt kontolt välja?';

  @override
  String get accountSignOutBody =>
      'Sinu laulud ja laulunimekirjad jäävad sellesse seadmesse. Neid ei varundata ega sünkroonita enne, kui uuesti sisse logid.';

  @override
  String get accountUseDifferent => 'Kasuta teist kontot';

  @override
  String get accountSignInAgain => 'Logi uuesti sisse';

  @override
  String get accountChooseAction => 'Vali, kuidas jätkata';

  @override
  String get accountChangedTitle => 'Teine Google\'i konto';

  @override
  String get accountChangedBody =>
      'See seade sünkrooniti viimati teise Google\'i kontoga. Vali, mis saab selles seadmes olevatest lauludest ja laulunimekirjadest.';

  @override
  String get accountChangedMerge => 'Ühenda uue kontoga';

  @override
  String get accountChangedMergeHint =>
      'Hoia kõik selles seadmes alles ja lisa see uuele kontole.';

  @override
  String get accountChangedReplace => 'Asenda uue konto koguga';

  @override
  String get accountChangedReplaceHint =>
      'Laulud sellest seadmest, mida uuel kontol pole, eemaldatakse.';

  @override
  String get accountChangedSignOut => 'Tühista ja logi välja';

  @override
  String get accountStatusSignedOut =>
      'Konto ja sünkroonimine: pole sisse logitud';

  @override
  String get accountStatusSignedIn => 'Konto ja sünkroonimine: sisse logitud';

  @override
  String get accountStatusSyncing => 'Konto ja sünkroonimine: sünkroonimine';

  @override
  String get accountStatusSynced => 'Konto ja sünkroonimine: kogu on ajakohane';

  @override
  String get accountStatusError =>
      'Konto ja sünkroonimine: probleem, puuduta ülevaatamiseks';

  @override
  String get accountNoticeConflicts =>
      'Mõnda laulu muudeti kahes kohas. Koopiad jäeti alles.';

  @override
  String get accountNoticeSignedIn => 'Sisse logitud.';

  @override
  String get accountNoticeSignedOut =>
      'Välja logitud. Sinu laulud jäävad sellesse seadmesse.';

  @override
  String get syncErrorNotConfigured =>
      'Selles versioonis pole sünkroonimine seadistatud.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Kasuta Singbooki versiooni, kus Google\'i sisselogimine on seadistatud.';

  @override
  String get syncErrorNotSignedIn => 'Sa pole sisse logitud.';

  @override
  String get syncErrorNotSignedInHint => 'Kogu sünkroonimiseks logi sisse.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google nõuab uuesti sisselogimist.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Sünkroonimise jätkamiseks logi uuesti sisse. Sinu laulud on selles seadmes alles.';

  @override
  String get syncErrorAccessDenied =>
      'Singbookil pole luba Google Drive\'i kasutada.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Logi uuesti sisse ja luba küsimisel Drive\'i kasutamine.';

  @override
  String get syncErrorRateLimited => 'Google piirab praegu päringuid.';

  @override
  String get syncErrorRateLimitedHint => 'Oota mõni minut ja proovi uuesti.';

  @override
  String get syncErrorStorageFull => 'Sinu Google Drive on täis.';

  @override
  String get syncErrorStorageFullHint =>
      'Vabasta Drive\'is ruumi ja proovi uuesti.';

  @override
  String get syncErrorNetwork => 'Google\'iga ei õnnestunud ühendust luua.';

  @override
  String get syncErrorNetworkHint =>
      'Kontrolli internetiühendust ja proovi uuesti.';

  @override
  String get syncErrorAccountChanged => 'Kasutati teist Google\'i kontot.';

  @override
  String get syncErrorAccountChangedHint =>
      'Vali, kas ühendada selle seadme kogu kontoga või see asendada.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Sünkroonitud kogu on Singbooki jaoks liiga suur.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Eemalda sünkroonitud kogust mõned laulud või laulunimekirjad ja proovi uuesti.';

  @override
  String get syncErrorSignInFailed => 'Sisselogimine jäi pooleli.';

  @override
  String get syncErrorSignInFailedHint => 'Proovi uuesti sisse logida.';

  @override
  String get syncErrorGeneric => 'Kogu sünkroonimine ebaõnnestus.';

  @override
  String get syncErrorGenericHint =>
      'Proovi veidi aja pärast uuesti. Sinu laulud on selles seadmes alles.';
}
