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
      'Sinu laulusõnad, akordid ja lugude nimekirjad koos, valmis prooviks, lavale ja kõikjale, kus mängid.';

  @override
  String get aboutMadeForSinging => 'Iga laul on valmis.';

  @override
  String get aboutDetails =>
      'Otsi lubatud allikatest ning võrdle laulusõnu, akorde, ajastust ja salvestuse üksikasju enne, kui salvestad esitamiseks sobiva versiooni. Saadavus oleneb laulust ja teenusest.';

  @override
  String get aboutFindTitle => 'Leia sobiv versioon';

  @override
  String get aboutKeepTitle => 'Loo oma kogu';

  @override
  String get aboutKeepDetails =>
      'Töötle ja transponeeri laule, hoia neid võrguühenduseta kasutamiseks oma kohalikus kogus ning jaga kaasaskantavaid ChordPro-faile. Valikuline Google Drive’i sünkroonimine kasutab sinu Google’i kontol rakenduse privaatkausta. Seadmete uuendamiseks võid puudutada ka nuppu „Sünkrooni kohe“.';

  @override
  String get aboutPlayTitle => 'Võta oma nimekiri lavale kaasa';

  @override
  String get aboutPlayDetails =>
      'Järjesta laulud nimekirjadesse, vali igale laulule helistik ja jaga OpenSongi nimekirju. Muuda lugeja teksti, laulusõnade automaatset kerimist ja prindi laulude PDF-faile. Singbook ei voogedasta ega esita heli.';

  @override
  String get aboutPrivacyTitle => 'Tasuta ja seadmepõhine';

  @override
  String get aboutPrivacyDetails =>
      'Singbook on tasuta, ilma reklaamide, analüütika ja rakendusesiseste ostudeta. Salvestatud kogu jääb sinu seadmesse; valikuline sünkroonimine kasutab sinu enda Google Drive’i. Veebitulemused tulevad otse sõltumatutelt kolmanda poole teenustelt ning võivad olla kättesaamatud või autoriõigustega kaitstud. Singbook nende sisu ei majuta.';

  @override
  String get aboutWebsite => 'Singbooki veebisait';

  @override
  String get aboutSourceCode => 'Lähtekood GitHubis';

  @override
  String get aboutPublisher => 'Freevialt';

  @override
  String aboutLanguages(int count) {
    return 'Rakenduse keeled: $count';
  }

  @override
  String get aboutSupport => 'Tugi ja tagasiside';

  @override
  String get menuTypeNewSong => 'Sisesta uus laul';

  @override
  String get menuFile => 'Fail';

  @override
  String get menuNewSong => 'Uus laul';

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
  String get appExitBackAgain => 'Väljumiseks vajuta uuesti Tagasi';

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
  String get searchFullPreview => 'Täielik eelvaade';

  @override
  String get searchArrangementNotes => 'Seade märkused';

  @override
  String get searchOpenLyrics => 'Ava laulusõnad';

  @override
  String get searchContributions => 'Kasutatud allikad';

  @override
  String get searchVersionChecking => 'Selle versiooni kontrollimine…';

  @override
  String get searchVersionUnavailable =>
      'Seda versiooni ei saa kasutada. Vali mõni teine versioon.';

  @override
  String get searchPreviewUnavailable => 'Laulusõnade eelvaade pole saadaval.';

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
  String get searchPreferredSourceLabel => 'Eelistatud allikas';

  @override
  String get searchPreferredSourceHint =>
      'Tulemused võivad pärineda ka muudest lubatud otsinguallikatest.';

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
  String get setlistShare => 'Jaga OpenSong-vormingus';

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
  String get playerPlay => 'Esita';

  @override
  String get playerPause => 'Peata';

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
  String get searchCombinedLabel => 'Kombineeritud';

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
  String get editorLyricsHint =>
      'Akordid kirjuta [C] sulgudesse; osamärgid eraldi ridadele.';

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
  String get settingsLyricHighlight => 'Praeguse laulusõnarea esiletõst';

  @override
  String get settingsHighlightBackgroundUnderline => 'Taust + allajoon';

  @override
  String get settingsHighlightBackground => 'Taust';

  @override
  String get settingsHighlightUnderline => 'Allajoon';

  @override
  String get settingsHighlightContrast => 'Kontrastne tekstivärv';

  @override
  String get settingsHighlightNone => 'Puudub';

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
      'Kustutab laulude ja laulunimekirjade hiljutise tegevusajaloo. Säilitab salvestatud laulud, lemmikud, laulunimekirjad ja seaded.';

  @override
  String get settingsHistoryCleared => 'Ajalugu kustutati.';

  @override
  String get accountTitle => 'Konto ja sünkroonimine';

  @override
  String get accountICloudBenefits =>
      'Kasuta oma Apple’i kontot, et sünkroonida laule ja esitusloendeid iCloudiga privaatselt. Pärast ühendamist sünkroonitakse muudatused automaatselt.';

  @override
  String get accountICloudUnavailable =>
      'iCloud pole saadaval. Kontrolli süsteemiseadetes oma Apple’i kontot ja iCloudi juurdepääsu ning proovi uuesti.';

  @override
  String get accountConnectICloud => 'Ühenda iCloud';

  @override
  String get accountDisconnectICloud => 'Katkesta iCloudi ühendus';

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
  String get settingsPreviewSongTitle => 'Hommikulaul';

  @override
  String get settingsPreviewArtist => 'Näidistöötlus';

  @override
  String get settingsPreviewCurrentLine => 'Kui hommik saabub';

  @override
  String get settingsPreviewNextLine => 'Laulame jälle.';

  @override
  String get settingsPlayerSections => 'Jaotiste pealkirjad';

  @override
  String get settingsPlayerControls => 'Taasesituspaneel';

  @override
  String get settingsPlayerAutoscroll => 'Automaatne kerimine';

  @override
  String get settingsSystemShort => 'Seade';

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
      'Google Drive’i ühendamisel sünkroonitakse sinu kogu. Seejärel sünkroonitakse laulude muudatused automaatselt.';

  @override
  String get accountManualSyncHint =>
      'Võid puudutada ka nuppu Sünkrooni kohe, et oma kogu sünkroonida.';

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
      'Sünkroonimine toimub pärast ühendamist ning pärast laulu lisamist, muutmist või eemaldamist.';

  @override
  String get accountDriveFolder => 'Google Drive\'i teegi kaust';

  @override
  String get accountPrivateDriveFolder => 'Privaatne lauluraamatu kaust';

  @override
  String get accountChooseDriveFolder => 'Valige kaust';

  @override
  String get accountDriveFolderMoveTitle =>
      'Kas teisaldada oma lauluraamatuteek?';

  @override
  String get accountDriveFolderMoveBody =>
      'Valige nähtav Google Drive\'i kaust. Singbook kopeerib ja kinnitab teie laulud ja komplektiloendid seal enne sellele üleminekut. Originaalfailid jäävad varukoopiaks oma eelmisesse asukohta. Teised failid jäetakse rahule. Sellesse kausta imporditud ChordPro failid võetakse sünkroonimiseks ja Singbooki metaandmete vastuvõtmiseks vastu.';

  @override
  String get accountImportChordPro => 'Importige ChordPro Drive\'ist';

  @override
  String get accountImportChordProHint =>
      'Valige sellesse teeki lisamiseks .cho-failid. Kaustas juba olevad failid võetakse vastu; mujal olevad failid kopeeritakse siia.';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'Drive\'i kausta valik pole saadaval';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'Valige toetatud seadmes Google Drive\'i valija abil nähtav Drive\'i kaust.';

  @override
  String get syncErrorDriveFolderMissing =>
      'Singbook Drive\'i kaust pole saadaval';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Valige kaust uuesti või taastage see Google Drive\'is.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook vajab juurdepääsu sellele Drive\'i kaustale';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Juurdepääsu andmiseks valige kaust uuesti, seejärel sünkroonige oma teek.';

  @override
  String get syncErrorFolderMigration =>
      'Raamatukogu ei saanud veel teisaldada';

  @override
  String get syncErrorFolderMigrationHint =>
      'Teie eelmine kogu on endiselt turvaline. Kontrollige ühendust ja valige uuesti proovimiseks uuesti kaust.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Valige esmalt nähtav Drive\'i kaust';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'Enne failide importimist Drive\'ist on vaja nähtavat teegikausta.';

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
  String get syncErrorOAuthClientConfiguration =>
      'Google lükkas selle järgu sisselogimise konfiguratsiooni tagasi.';

  @override
  String get syncErrorOAuthClientConfigurationHint =>
      'Kontrolli, et seadistatud OAuthi ID kuulub Singbooki töölauarakenduse kliendile.';

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

  @override
  String get editorDurationInvalid =>
      'Sisesta sekundid või minutid ja sekundid, näiteks 3:45.';

  @override
  String get editorNumberInvalid => 'Sisesta arv.';

  @override
  String get accountReplaceConfirmTitle => 'Kustutada kohalikud laulud?';

  @override
  String get accountReplaceConfirmBody =>
      'Selle seadme laulud ja laulunimekirjad, mida uues kontos pole, kustutatakse jäädavalt. Seda ei saa tagasi võtta.';

  @override
  String get accountReplaceConfirmAction => 'Kustuta ja asenda';

  @override
  String get accountSuspiciousTitle => 'Google Drive’ist puuduvad üksused';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Google Drive’ist puudub $count üksust, mille see seade oli varem sünkrooninud.',
      one:
          'Google Drive’ist puudub üksus, mille see seade oli varem sünkrooninud.',
    );
    return '$_temp0 See võib juhtuda, kui rakenduse andmed kustutati Google’i seadetes. Midagi pole veel kustutatud.';
  }

  @override
  String get accountSuspiciousDelete => 'Kustuta need ka siit';

  @override
  String get accountSuspiciousKeep =>
      'Säilita mu laulud ja laadi need uuesti üles';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kas kustutada sellest seadmest $count üksust?',
      one: 'Kas kustutada sellest seadmest $count üksus?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Need laulud ja laulunimekirjad kustutatakse sellest seadmest jäädavalt. Seda ei saa tagasi võtta.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Kustuta sellest seadmest';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Google Drive’ist puuduvad üksused.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Midagi ei kustutatud. Vali, kas kustutada need ka siit või laadida uuesti üles.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive muutus sünkroonimise ajal.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Midagi ei läinud kaotsi. Viimaste muudatuste saamiseks sünkrooni uuesti.';

  @override
  String get syncErrorInvalidLocalData =>
      'Mõningaid selle seadme andmeid ei saanud sünkroonida.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Laulu või laulunimekirja ei saanud lugeda. Impordi või loo see uuesti ja sünkrooni seejärel uuesti.';

  @override
  String get syncErrorNoAccountChange =>
      'Lahendamist vajavat kontomuutust pole.';

  @override
  String get syncErrorNoAccountChangeHint => 'Jätkamiseks sünkrooni uuesti.';

  @override
  String get accountSyncWarningTitle =>
      'Sünkroonitud, kuid mõned failid jäeti vahele';

  @override
  String get accountSyncWarningBody =>
      'Mõnda faili ei saanud kasutada ja need jäeti muutmata. Kõik muu on ajakohane.';

  @override
  String get accountSyncWarningTooLarge =>
      'Fail oli sünkroonimiseks liiga suur ja jäeti vahele. Kõik muu on ajakohane.';

  @override
  String get accountSyncWarningInvalid =>
      'Faili ei saanud lugeda ja see jäeti vahele. Kõik muu on ajakohane.';

  @override
  String get accountNoticeSyncSkipped =>
      'Sünkroonitud. Mõned failid jäeti vahele.';

  @override
  String get settingsExportPdfTooLarge =>
      'See PDF oleks liiga suur. Proovi vähemate lauludega või jaga seda tekstina.';

  @override
  String get settingsTimingTooLarge =>
      'Ajastuse andmed on liiga suured (üle 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'See varukoopia sisaldab sama laulu kaks korda, seega ei imporditud midagi.';

  @override
  String get setlistSaveConflict =>
      'Laulunimekirja muudeti mujal. Sinu muudatused salvestati eraldi koopiana.';

  @override
  String get sectionVerse => 'Salm';

  @override
  String get sectionChorus => 'Refrään';

  @override
  String get sectionBridge => 'Sild';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Eelrefrään';

  @override
  String get sectionPostChorus => 'Järelrefrään';

  @override
  String get sectionInstrumental => 'Instrumentaal';

  @override
  String get sectionInterlude => 'Vahemäng';

  @override
  String get sectionSolo => 'Soolo';

  @override
  String get sectionRefrain => 'Kordus';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Lõpp';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Valmis versioonid',
      one: '1 valmis versioon',
      zero: '0 Valmis versioonid',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kättesaamatud versioonid',
      one: '1 kättesaamatu versioon',
      zero: '0 Kättesaamatud versioonid',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Hüppa jaotisse';

  @override
  String get searchVersionDetails => 'Versiooni üksikasjad';

  @override
  String get searchSelectedRecording => 'Valitud salvestis';

  @override
  String get searchVersionDuration => 'Versiooni kestus';

  @override
  String get searchSourceOptions => 'Allika valikud';

  @override
  String get actionUndo => 'Võta tagasi';

  @override
  String setlistEntryRemoved(String song) {
    return 'Lugu „$song“ eemaldati esituskavast';
  }

  @override
  String get backupTitle => 'Varundamine ja taastamine';

  @override
  String get backupExport => 'Ekspordi varukoopia';

  @override
  String get backupRestore => 'Taasta varukoopia';

  @override
  String get backupIncludePreferences => 'Kaasa rakenduse eelistused';

  @override
  String get backupRestorePreferences => 'Taasta rakenduse eelistused';

  @override
  String get backupMerge => 'Lisa sellesse teeki';

  @override
  String get backupMergeHint =>
      'Säilita kohalikud muudatused ja lisa sellest varukoopiast lood ning esituskavad.';

  @override
  String get backupReplace => 'Asenda see teek';

  @override
  String get backupReplaceHint =>
      'Asenda selle seadme kõik lood ja esituskavad selle varukoopia sisuga.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Laulud: $songs · Esituskavad: $setlists · Konfliktid: $conflicts';
  }

  @override
  String get backupFailed =>
      'Varundamistoimingut ei saanud lõpetada. Proovi uuesti.';

  @override
  String get backupRestored => 'Varukoopia taastati.';

  @override
  String get backupLocalHint =>
      'Salvesta oma teegi koopia. Kontoandmeid ega nõusolekuküpsiseid ei lisata.';

  @override
  String get backupReplaceConfirm =>
      'Kas asendada praegune teek? Seda ei saa tagasi võtta.';

  @override
  String get searchCheckOperations => 'Toimingud';

  @override
  String get searchCheckCode => 'Tulemuse kood';

  @override
  String get searchCheckQueued => 'Selle allika kontrollimine on ootel.';

  @override
  String get searchCheckFetch => 'Laadi laulusõnad';

  @override
  String get searchCheckValidate => 'Kontrolli laulu vastet';

  @override
  String get searchCheckCorroborate => 'Kontrolli sõnade vastavust';

  @override
  String get searchCheckCompleted => 'Valmis';

  @override
  String get searchCheckTimeout => 'Allikas ei vastanud õigel ajal.';

  @override
  String get searchCheckBlocked => 'Allikas blokeeris päringu.';

  @override
  String get searchCheckRateLimited =>
      'Allikas piirab päringuid. Proovi hiljem uuesti.';

  @override
  String get searchCheckNetwork =>
      'Allikaga ei saanud ühendust. Kontrolli ühendust.';

  @override
  String get searchCheckInvalid => 'Allikas tagastas loetamatu vastuse.';

  @override
  String get searchCheckNotConfigured =>
      'See allikas pole selles järgus seadistatud.';

  @override
  String get searchCheckNoLyrics => 'Sobivaid laulusõnu ei leitud.';

  @override
  String get searchCheckFailed => 'Toimingut ei saanud lõpule viia.';

  @override
  String get searchCheckNoHistory =>
      'Selle võrdluse jaoks pole allikaid kontrollitud.';

  @override
  String get searchVersionCredits => 'Autorid ja allikad';

  @override
  String get searchVersionMediaLinks => 'Seotud lingid';

  @override
  String get searchCheckCancelled => 'Tühistatud';

  @override
  String get searchCheckAmbiguous =>
      'Leiti mitu vastet. See allikas vajab täpsemat salvestist.';

  @override
  String get searchCheckIdentity =>
      'See allikas vajab salvestise või teose tunnust.';

  @override
  String get searchCheckExtraction =>
      'Allikas vastas, kuid laulusõnu ei saanud eraldada.';

  @override
  String get searchCheckBusy => 'Allikas on hõivatud. Proovi hiljem uuesti.';

  @override
  String get searchCheckSelection =>
      'Vali sellest allikast konkreetne tulemus.';

  @override
  String get playerChordsNone => 'Puudub';

  @override
  String get editorCustomValue => 'Muu…';

  @override
  String get editorStandardTuning => 'Standardhäälestus';

  @override
  String get editorExampleVerse =>
      '[C]Uus päev meid [G]kutsub,\n[Am]järgime valgust tagasi [F]koju.';

  @override
  String get editorExampleChorus =>
      '[F]Laulame seda laulu [C]koos,\n[G]las meloodia kannab meid [C]edasi.';

  @override
  String get editorExampleBridge => '[Am]Veel üks rida, veidi [F]lähemal.';

  @override
  String get playerEstimatedKey => 'Hinnanguline helistik';

  @override
  String get songsLibraryView => 'Teek';

  @override
  String get settingsStartupView => 'Ava käivitamisel';

  @override
  String get settingsStartupViewHint =>
      'Vali laulude vaade, mida rakenduse avamisel näidatakse.';

  @override
  String get settingsStartupLastView => 'Viimati avatud';

  @override
  String get playerFullScreen => 'Täisekraan';

  @override
  String get playerExitFullScreen => 'Välju täisekraanilt';

  @override
  String get playerExpandControls => 'Kuva taasesituse juhtnuppe';

  @override
  String get playerCollapseControls => 'Peida taasesituse juhtnupud';

  @override
  String get settingsShowSections => 'Kuva osade pealkirjad';

  @override
  String get settingsShowSectionsHint =>
      'Kuva laulusõnades salmide, refrääni ja muude osade pealkirju.';

  @override
  String get settingsShowPlayerControls => 'Kuva taasesituse juhtnuppe';

  @override
  String get settingsShowPlayerControlsHint =>
      'Saad pleieripaneeli kuvamiseks või peitmiseks seda ka puudutada või libistada.';

  @override
  String get sourceAnalysisHeading => 'Esitatud heli analüüs (kinnitamata)';

  @override
  String sourceAnalysisCoverage(int shown, int total) {
    return 'Kuvatakse $shown esitatud salvestist $total-st';
  }

  @override
  String sourceAnalysisSample(int number) {
    return 'Näidis $number';
  }

  @override
  String get sourceAnalysisEstimatedTempo => 'Hinnanguline tempo (BPM)';
}
