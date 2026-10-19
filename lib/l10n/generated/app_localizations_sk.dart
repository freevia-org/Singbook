// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Texty piesní, akordy a zoznamy skladieb spolu, pripravené na skúšku, na pódium aj kamkoľvek, kde hráte.';

  @override
  String get aboutMadeForSinging => 'Každá pieseň pripravená.';

  @override
  String get aboutDetails =>
      'Vyhľadávajte v dostupných zdrojoch a porovnávajte texty, akordy, načasovanie a informácie o nahrávke, kým si neuložíte verziu, ktorú chcete hrať. Dostupnosť sa líši podľa piesne a služby.';

  @override
  String get aboutFindTitle => 'Nájdite správnu verziu';

  @override
  String get aboutKeepTitle => 'Vytvorte si vlastnú knižnicu';

  @override
  String get aboutKeepDetails =>
      'Upravujte a transponujte piesne, uchovávajte ich v miestnej knižnici na používanie offline a zdieľajte prenosné súbory ChordPro. Voliteľná synchronizácia s Google Drive používa súkromný priečinok aplikácie vo vašom účte Google. Zariadenia môžete aktualizovať aj klepnutím na „Synchronizovať teraz“.';

  @override
  String get aboutPlayTitle => 'Vezmite si zoznam skladieb na pódium';

  @override
  String get aboutPlayDetails =>
      'Zoraďte piesne do zoznamov, vyberte tóninu každej piesne a zdieľajte zoznamy OpenSong. Upravte veľkosť textu v čítačke, zapnite automatické posúvanie textu a tlačte PDF súbory piesní. Singbook neprenáša ani neprehráva zvuk.';

  @override
  String get aboutPrivacyTitle => 'Bezplatná a s knižnicou uloženou lokálne';

  @override
  String get aboutPrivacyDetails =>
      'Singbook je bezplatný, bez reklám, analytiky a nákupov v aplikácii. Uložená knižnica zostáva vo vašom zariadení; voliteľná synchronizácia využíva váš Google Drive. Online výsledky pochádzajú priamo od nezávislých služieb tretích strán a nemusia byť dostupné alebo môžu byť chránené autorskými právami. Singbook ich obsah nehostuje.';

  @override
  String get aboutWebsite => 'Webová stránka Singbook';

  @override
  String get aboutSourceCode => 'Zdrojový kód na GitHube';

  @override
  String get aboutPublisher => 'Od Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Jazyky aplikácie: $count';
  }

  @override
  String get aboutSupport => 'Podpora a spätná väzba';

  @override
  String get menuTypeNewSong => 'Zadať novú pieseň';

  @override
  String appVersion(String version) {
    return 'Verzia $version';
  }

  @override
  String get navHome => 'Domov';

  @override
  String get navSongs => 'Piesne';

  @override
  String get navSetlists => 'Koncertné programy';

  @override
  String get navSettings => 'Nastavenia';

  @override
  String get navSettingsCompact => 'Nastavenia';

  @override
  String get navSearch => 'Hľadať';

  @override
  String get navBack => 'Späť';

  @override
  String get appExitBackAgain => 'Opätovným stlačením Späť aplikáciu ukončíte';

  @override
  String get navClose => 'Zavrieť';

  @override
  String get navMore => 'Ďalšie akcie';

  @override
  String get actionCancel => 'Zrušiť';

  @override
  String get actionSave => 'Uložiť';

  @override
  String get actionDone => 'Hotovo';

  @override
  String get actionEdit => 'Upraviť';

  @override
  String get actionDelete => 'Odstrániť';

  @override
  String get actionShare => 'Zdieľať';

  @override
  String get actionPrint => 'Tlačiť';

  @override
  String get actionCopy => 'Kopírovať';

  @override
  String get actionClear => 'Vymazať';

  @override
  String get actionRetry => 'Skúsiť znova';

  @override
  String get actionRefresh => 'Obnoviť';

  @override
  String get actionImport => 'Importovať';

  @override
  String get actionExport => 'Exportovať';

  @override
  String get actionExpand => 'Rozbaliť';

  @override
  String get actionCollapse => 'Zbaliť';

  @override
  String get actionAdd => 'Pridať';

  @override
  String get actionCreate => 'Vytvoriť';

  @override
  String get actionRemove => 'Odobrať';

  @override
  String get actionDuplicate => 'Duplikovať';

  @override
  String get actionMoveUp => 'Posunúť nahor';

  @override
  String get actionMoveDown => 'Posunúť nadol';

  @override
  String get actionPrevious => 'Predchádzajúce';

  @override
  String get actionNext => 'Nasledujúce';

  @override
  String get searchHint => 'Hľadať piesne, interpretov alebo texty piesní';

  @override
  String get searchCatalogHint => 'Hľadať pieseň alebo interpreta';

  @override
  String get searchChangeSong => 'Zmeniť skladbu';

  @override
  String get searchSelectedPreview => 'Vybratá ukážka';

  @override
  String get searchSubmit => 'Hľadať';

  @override
  String get searchFilters => 'Možnosti vyhľadávania';

  @override
  String get searchFiltersShow => 'Zobraziť možnosti vyhľadávania';

  @override
  String get searchFiltersHide => 'Skryť možnosti vyhľadávania';

  @override
  String get searchFilterArtist => 'Interpret';

  @override
  String get searchFilterTitle => 'Názov piesne';

  @override
  String get searchFilterLyrics => 'Texty piesní';

  @override
  String get searchFilterChords => 'Obsahuje akordy';

  @override
  String get searchFilterTimed => 'Časované texty piesní';

  @override
  String get searchFilterLanguage => 'Jazyk';

  @override
  String get searchFilterAll => 'Ľubovoľný';

  @override
  String get searchAutocompleteLabel => 'Návrhy';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count výsledkov',
      few: '$count výsledky',
      one: '1 výsledok',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Zadajte pieseň, interpreta alebo verš, ktorý chcete vyhľadať.';

  @override
  String get searchCatalogEmptyQuery =>
      'Zadajte pieseň alebo interpreta, ktorého chcete vyhľadať.';

  @override
  String get searchNoResults =>
      'Nenašli sa žiadne piesne. Skúste iné vyhľadávanie.';

  @override
  String get searchLoading => 'Vyhľadávajú sa piesne…';

  @override
  String get searchError => 'Vyhľadávanie sa nepodarilo dokončiť.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Nedávne';

  @override
  String get searchFavoritesTab => 'Obľúbené';

  @override
  String get searchSuggested => 'Navrhovaná zhoda';

  @override
  String get searchAlternatives => 'Ďalšie zhody';

  @override
  String get searchCompare => 'Porovnať verzie';

  @override
  String get searchChooseVersion => 'Vybrať túto verziu';

  @override
  String get searchFullPreview => 'Úplný náhľad';

  @override
  String get searchArrangementNotes => 'Poznámky k aranžmánu';

  @override
  String get searchOpenLyrics => 'Otvoriť text';

  @override
  String get searchContributions => 'Použité zdroje';

  @override
  String get searchVersionChecking => 'Kontroluje sa táto verzia…';

  @override
  String get searchVersionUnavailable =>
      'Túto verziu nemožno použiť. Vyberte inú verziu.';

  @override
  String get searchPreviewUnavailable => 'Náhľad textu nie je k dispozícii.';

  @override
  String get searchSongMatch => 'Zhoda piesne';

  @override
  String get searchRecordingMatch => 'Zhoda nahrávky';

  @override
  String get searchMatchUnverified => 'Nahrávka nie je overená';

  @override
  String get searchMatchExact => 'Presná zhoda nahrávky';

  @override
  String get searchMatchPossible => 'Možná zhoda';

  @override
  String get searchAvailability => 'Dostupnosť';

  @override
  String get searchLyricsAvailable => 'Text piesne je dostupný';

  @override
  String get searchLyricsUnavailable => 'Text piesne nie je dostupný';

  @override
  String get searchChordsAvailable => 'Akordy sú dostupné';

  @override
  String get searchChordsUnavailable => 'Bez akordov';

  @override
  String get searchTimingAvailable => 'Časovanie je dostupné';

  @override
  String get searchTimingUnavailable => 'Časovanie nie je dostupné';

  @override
  String get searchDurationUnknown => 'Trvanie nie je známe';

  @override
  String searchRating(String rating) {
    return 'Hodnotenie $rating';
  }

  @override
  String get searchSourceLabel => 'Zdroj';

  @override
  String get searchMetadata => 'Informácie o piesni';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Interpret';

  @override
  String get searchYear => 'Rok';

  @override
  String get searchLanguage => 'Jazyk';

  @override
  String get searchViewVersions => 'Zobraziť verzie';

  @override
  String get searchSaved => 'Pieseň bola uložená do vašej knižnice.';

  @override
  String get searchSaveOpenLyrics => 'Uložiť a otvoriť text';

  @override
  String get searchOtherResults => 'Ďalšie výsledky';

  @override
  String get searchSaveFailed => 'Pieseň sa nepodarilo uložiť.';

  @override
  String get homeRecentSongs => 'Nedávne piesne';

  @override
  String get homeRecentlyPlayed => 'Nedávno prehrávané';

  @override
  String get homeFavorites => 'Obľúbené';

  @override
  String get homeHistory => 'História';

  @override
  String get homeHistoryClear => 'Vymazať históriu';

  @override
  String get homeHistoryCleared => 'História bola vymazaná.';

  @override
  String get homeHistoryEmpty => 'Tu sa zobrazia piesne, ktoré otvoríte.';

  @override
  String get homeFavoritesEmpty =>
      'Tu sa zobrazia vaše obľúbené piesne a koncertné programy.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zobrazených $count položiek',
      few: 'Zobrazené $count položky',
      one: 'Zobrazená 1 položka',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Tu sa zobrazia vaše nedávne piesne a koncertné programy.';

  @override
  String get homeTimelineLabel => 'Časová os histórie';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Celá história';

  @override
  String get homeShowFavorites => 'Zobraziť obľúbené';

  @override
  String get homeShowRecent => 'Zobraziť nedávne';

  @override
  String get songsTitle => 'Piesne';

  @override
  String get songsEmpty => 'Tu sa zobrazia vaše piesne.';

  @override
  String get songsEmptySearch => 'Žiadna pieseň nezodpovedá vyhľadávaniu.';

  @override
  String get songsAdd => 'Pridať pieseň';

  @override
  String get songsSortAlphabetical => 'Zoradiť podľa abecedy';

  @override
  String get songsAlphabetNavigation => 'Register piesní';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-krát',
      few: '$count-krát',
      one: 'raz',
    );
    return 'Otvorené $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Pridať medzi obľúbené';

  @override
  String get songFavoriteRemove => 'Odstrániť z obľúbených';

  @override
  String get songMenuLabel => 'Akcie s piesňou';

  @override
  String get songInfo => 'Informácie o piesni';

  @override
  String get setlistMenuLabel => 'Akcie s koncertným programom';

  @override
  String get songAddToSetlist => 'Pridať do koncertného programu';

  @override
  String get songCopyChordPro => 'Kopírovať ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Odstrániť pieseň?';

  @override
  String get songDeleteConfirmMessage =>
      'Táto pieseň sa odstráni z vašej knižnice.';

  @override
  String get songDeleted => 'Pieseň bola odstránená.';

  @override
  String get setlistsTitle => 'Koncertné programy';

  @override
  String get setlistsEmpty =>
      'Vytvorte koncertný program na najbližšiu skúšku alebo vystúpenie.';

  @override
  String get setlistsEmptySearch =>
      'Žiadny koncertný program nezodpovedá vyhľadávaniu.';

  @override
  String get setlistCreate => 'Nový koncertný program';

  @override
  String get setlistNameHint => 'Názov koncertného programu';

  @override
  String get setlistNotes => 'Poznámky';

  @override
  String get setlistEntryOverride => 'Tónina a kapodaster pre konkrétnu pieseň';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count piesní',
      few: '$count piesne',
      one: '1 pieseň',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Aspoň $duration';
  }

  @override
  String get setlistDurationUnknown => 'Trvanie nie je známe';

  @override
  String setlistActivity(String date) {
    return 'Posledná aktivita $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Vytvorené $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Upravené $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Naposledy hrané $date';
  }

  @override
  String get setlistSongsEmpty =>
      'V tomto koncertnom programe zatiaľ nie sú žiadne piesne.';

  @override
  String get setlistAddSongs => 'Pridať piesne';

  @override
  String get setlistReorder => 'Zmeniť poradie piesní';

  @override
  String setlistMoveSongUp(String song) {
    return 'Posunúť pieseň „$song“ nahor';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Posunúť pieseň „$song“ nadol';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Odstrániť pieseň „$song“ z koncertného programu';
  }

  @override
  String get setlistDuplicate => 'Duplikovať koncertný program';

  @override
  String get setlistFavoriteAdd => 'Pridať koncertný program medzi obľúbené';

  @override
  String get setlistFavoriteRemove =>
      'Odstrániť koncertný program z obľúbených';

  @override
  String get setlistShare => 'Zdieľať ako súbor koncertného programu';

  @override
  String get setlistSharePdf => 'Zdieľať ako PDF';

  @override
  String get setlistPrint => 'Tlačiť';

  @override
  String get setlistDeleteConfirmTitle => 'Odstrániť koncertný program?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Koncertný program sa odstráni. Piesne vo vašej knižnici zostanú.';

  @override
  String get setlistDeleted => 'Koncertný program bol odstránený.';

  @override
  String get readerTitle => 'Texty piesní';

  @override
  String get readerNoLyrics => 'Text piesne zatiaľ nebol pridaný.';

  @override
  String get readerShowChords => 'Zobraziť akordy';

  @override
  String get readerHideChords => 'Skryť akordy';

  @override
  String get readerTranspose => 'Transponovať akordy';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count poltónov',
      few: '$count poltóny',
      one: '1 poltón',
    );
    return 'Transponovať o $_temp0';
  }

  @override
  String get readerSaved => 'Uložené';

  @override
  String get readerEdit => 'Upraviť text piesne a informácie';

  @override
  String get playerPlay => 'Prehrať';

  @override
  String get playerPause => 'Pozastaviť';

  @override
  String get playerResume => 'Pokračovať v posúvaní textu piesne';

  @override
  String get playerSeek => 'Pozícia prehrávania';

  @override
  String playerElapsed(String time) {
    return 'Uplynutý čas $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Zostávajúci čas $time';
  }

  @override
  String get playerTimingMode => 'Režim posúvania';

  @override
  String get playerTimedLyrics => 'Časované texty piesní';

  @override
  String get playerStartScroll => 'Spustiť automatické posúvanie';

  @override
  String get playerEstimatedPace => 'Odhadované tempo';

  @override
  String get playerScrollSpeed => 'Rýchlosť posúvania';

  @override
  String playerEstimatedDuration(String time) {
    return 'Odhadované trvanie: $time';
  }

  @override
  String get playerLyricsOnly => 'Posúvanie textu · bez zvuku';

  @override
  String get playerManualScroll => 'Manuálne posúvanie';

  @override
  String get playerTimingStatusReady =>
      'Text piesne sa bude posúvať podľa dostupného časovania.';

  @override
  String get playerTimingStatusEstimated =>
      'Tempo posúvania sa odhaduje podľa dĺžky piesne.';

  @override
  String get playerTimingStatusManual => 'Posúvajte text piesne sami.';

  @override
  String get playerTimingStatusUnavailable =>
      'Časované posúvanie nie je pre túto pieseň dostupné.';

  @override
  String get playerDurationUnknown =>
      'Ak chcete použiť odhadované posúvanie, zadajte trvanie piesne.';

  @override
  String get playerProgressLabel => 'Priebeh piesne';

  @override
  String get playerCurrentSection => 'Aktuálna časť';

  @override
  String get playerPreviousSection => 'Predchádzajúca časť';

  @override
  String get playerNextSection => 'Nasledujúca časť';

  @override
  String get playerPreviousSectionSong =>
      'Predchádzajúca časť · podržaním prejdete na predchádzajúcu pieseň v programe';

  @override
  String get playerNextSectionSong =>
      'Nasledujúca časť · podržaním prejdete na ďalšiu pieseň v programe';

  @override
  String get playerPreviousSong => 'Predchádzajúca pieseň';

  @override
  String get playerNextSong => 'Nasledujúca pieseň';

  @override
  String get editorTitle => 'Upraviť pieseň';

  @override
  String get editorTitleField => 'Názov piesne';

  @override
  String get editorArtistField => 'Interpret';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Text piesne';

  @override
  String get editorChordsField => 'Akordy';

  @override
  String get editorKeyField => 'Tónina';

  @override
  String get editorCapoField => 'Kapodaster';

  @override
  String get editorTuningField => 'Ladenie';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Trvanie';

  @override
  String get editorTimeSignatureField => 'Takt';

  @override
  String get editorLanguageField => 'Jazyk';

  @override
  String get editorYearField => 'Rok';

  @override
  String get editorComposerField => 'Skladateľ';

  @override
  String get editorLyricistField => 'Autor textu';

  @override
  String get editorCopyrightField => 'Autorské práva';

  @override
  String get editorLicenseField => 'Licencia';

  @override
  String get songInfoSources => 'Zdroje a zásluhy';

  @override
  String get searchMatchSameSong => 'Rovnaká pieseň; nahrávka nie je potvrdená';

  @override
  String get searchMatchNeedsAgreement =>
      'Zápis akordov treba potvrdiť podľa textu piesne';

  @override
  String get searchMatchDifferentLyrics => 'Text sa líši od vybranej piesne';

  @override
  String get searchMatchCombinedSources =>
      'Informácie spojené z viacerých zdrojov';

  @override
  String get searchCombinedLabel => 'Kombinované';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zhôd piesní',
      few: '$count zhody piesní',
      one: '1 zhoda piesne',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verzií zdroja',
      few: '$count verzie zdroja',
      one: '1 verzia zdroja',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Najlepšia dostupná zhoda';

  @override
  String get providerDescriptionUnknown => 'Zdroj piesne';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Stiahnite súbor ChordPro zo zdroja a potom ho importujte.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Stiahnite súbor pomocou bezplatného účtu a potom ho importujte.';

  @override
  String get providerDescPublicChordSheets => 'Verejné zápisy akordov.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Historické texty piesní licencované pre každé dielo osobitne.';

  @override
  String get providerDescLicensedCatalog =>
      'Licencovaný katalóg textov piesní.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Pôvodné piesne pod licenciou Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Texty piesní licencované osobitne pre každú pieseň.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Len informácie o nahrávke a vydaní.';

  @override
  String get providerDescCompositionMetadataOnly => 'Len informácie o skladbe.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Obal je dostupný len pri presnej zhode nahrávky.';

  @override
  String get providerCapabilityLyrics => 'Texty piesní';

  @override
  String get providerCapabilityChords => 'Akordy';

  @override
  String get providerCapabilityTiming => 'Časované texty piesní';

  @override
  String get providerCapabilitySearch => 'Vyhľadávanie';

  @override
  String get providerCapabilityMetadata => 'Informácie o piesni';

  @override
  String get editorArtworkField => 'Odkaz na obal';

  @override
  String get editorLyricsHint =>
      'Akordy píšte do hranatých zátvoriek [C]; označenia častí na samostatné riadky.';

  @override
  String get editorSave => 'Uložiť zmeny';

  @override
  String get editorSaved => 'Zmeny boli uložené.';

  @override
  String get editorSaveFailed => 'Zmeny sa nepodarilo uložiť.';

  @override
  String get editorSaveConflict =>
      'Pieseň bola zmenená inde. Vaše úpravy sa uložili ako samostatná kópia.';

  @override
  String get editorUnsavedTitle => 'Zahodiť zmeny?';

  @override
  String get editorUnsavedMessage => 'Vaše úpravy neboli uložené.';

  @override
  String get editorFieldRequired => 'Zadajte názov piesne.';

  @override
  String get settingsTitle => 'Nastavenia';

  @override
  String get settingsAppearance => 'Vzhľad';

  @override
  String get settingsTheme => 'Motív';

  @override
  String get settingsThemeSystem => 'Použiť nastavenie zariadenia';

  @override
  String get settingsThemeLight => 'Svetlý';

  @override
  String get settingsThemeDark => 'Tmavý';

  @override
  String get settingsColorPalette => 'Paleta farieb';

  @override
  String get settingsFont => 'Písmo';

  @override
  String get settingsTextSize => 'Veľkosť textu';

  @override
  String get settingsLyricsPreview => 'Ukážka textu piesne';

  @override
  String get settingsPlayer => 'Prehrávač textov piesní';

  @override
  String get settingsLyricHighlight => 'Zvýraznenie aktuálneho riadka';

  @override
  String get settingsHighlightBackgroundUnderline => 'Pozadie + podčiarknutie';

  @override
  String get settingsHighlightBackground => 'Pozadie';

  @override
  String get settingsHighlightUnderline => 'Podčiarknutie';

  @override
  String get settingsHighlightContrast => 'Kontrastná farba textu';

  @override
  String get settingsHighlightNone => 'Žiadne';

  @override
  String get settingsDefaultShowChords => 'Predvolene zobrazovať akordy';

  @override
  String get settingsDefaultAutoscroll =>
      'Automaticky spustiť posúvanie textu piesne';

  @override
  String get settingsDefaultTiming => 'Predvolený režim posúvania';

  @override
  String get settingsLanguage => 'Jazyk aplikácie';

  @override
  String get settingsLanguageSystem => 'Použiť jazyk zariadenia';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Zdroje textov piesní';

  @override
  String settingsSourceEnabled(String source) {
    return 'Povoliť zdroj $source';
  }

  @override
  String get settingsSourceRefresh => 'Obnoviť zoznam zdrojov';

  @override
  String get settingsSourcesUpdated => 'Zdroje boli aktualizované.';

  @override
  String get settingsSourcesUpdateFailed => 'Zdroje sa nepodarilo obnoviť.';

  @override
  String get settingsImport => 'Importovať piesne';

  @override
  String get settingsImportChordPro => 'Importovať súbor ChordPro';

  @override
  String get settingsImportSetlist => 'Importovať súbor koncertného programu';

  @override
  String get settingsImportSuccess => 'Importovanie dokončené.';

  @override
  String get settingsImportFailed => 'Tento súbor sa nepodarilo importovať.';

  @override
  String get settingsImportUnsupported =>
      'Tento typ súboru nie je podporovaný.';

  @override
  String get settingsShareSong => 'Zdieľať ako ChordPro';

  @override
  String get settingsSharePdf => 'Zdieľať ako PDF';

  @override
  String get settingsCopySong => 'Kopírovať do schránky';

  @override
  String get settingsPrintSong => 'Tlačiť iba pieseň';

  @override
  String get settingsPrintSetlist =>
      'Vytlačiť koncertný program s textami piesní';

  @override
  String get settingsExportFailed => 'Súbor sa nepodarilo pripraviť.';

  @override
  String get settingsCopied => 'Skopírované do schránky.';

  @override
  String get settingsAbout => 'O aplikácii';

  @override
  String get settingsPrivacy => 'Súkromie';

  @override
  String get settingsLegal => 'Právne informácie';

  @override
  String get settingsClearHistory => 'Vymazať históriu';

  @override
  String get settingsClearHistoryConfirm =>
      'Vymazať históriu piesní a koncertných programov?';

  @override
  String get settingsHistoryCleared => 'História bola vymazaná.';

  @override
  String get accountTitle => 'Účet a synchronizácia';

  @override
  String get accountUnavailable =>
      'Synchronizácia vyžaduje verziu aplikácie Singbook s nakonfigurovaným prihlasovaním cez Google. Táto verzia ukladá vaše piesne iba v tomto zariadení.';

  @override
  String get accountSyncNow => 'Synchronizovať teraz';

  @override
  String get accountConnected =>
      'Pripojené. Výberom možnosti Synchronizovať teraz aktualizujete zálohu.';

  @override
  String get accountSignIn => 'Pripojiť účet';

  @override
  String get accountSignOut => 'Odhlásiť sa';

  @override
  String get accountChange => 'Zmeniť účet';

  @override
  String get accountSignedOut => 'Nepripojené';

  @override
  String get accountSyncing => 'Synchronizuje sa vaša knižnica…';

  @override
  String get accountSynced => 'Knižnica je synchronizovaná.';

  @override
  String get accountSyncFailed => 'Knižnicu sa nepodarilo synchronizovať.';

  @override
  String get accessibilityFavorite => 'Obľúbené';

  @override
  String get accessibilityNotFavorite => 'Nie je obľúbené';

  @override
  String get accessibilitySearchField => 'Hľadať piesne';

  @override
  String get accessibilityClearSearch => 'Vymazať text vyhľadávania';

  @override
  String accessibilitySongMenu(String song) {
    return 'Akcie s piesňou $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Akcie s koncertným programom $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Rozbaliť piesne v programe $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Zbaliť piesne v programe $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Priebeh prehrávania, $percent percent';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Časová os histórie, $date';
  }

  @override
  String get loading => 'Načítava sa…';

  @override
  String get loadingSongs => 'Načítavajú sa piesne…';

  @override
  String get loadingSetlists => 'Načítavajú sa koncertné programy…';

  @override
  String get errorGeneric => 'Niečo sa pokazilo.';

  @override
  String get errorOffline => 'Zdá sa, že ste offline.';

  @override
  String get errorPermission => 'Na pokračovanie je potrebné povolenie.';

  @override
  String get emptyFiltered => 'Žiadna položka nezodpovedá týmto filtrom.';

  @override
  String get unknownValue => 'Neznáme';

  @override
  String get durationUnknown => 'Trvanie nie je známe';

  @override
  String get metadataNotSet => 'Nenastavené';

  @override
  String get dateToday => 'Dnes';

  @override
  String get dateYesterday => 'Včera';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count piesní',
      few: '$count piesne',
      one: '1 pieseň',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Tmavomodrá';

  @override
  String get settingsPaletteSage => 'Šalviová';

  @override
  String get settingsPaletteOcean => 'Oceánska';

  @override
  String get settingsPaletteClay => 'Hlinená';

  @override
  String get settingsPalettePlum => 'Slivková';

  @override
  String get settingsFontSystem => 'Systémové';

  @override
  String get settingsFontSerif => 'Pätkové';

  @override
  String get settingsFontMonospace => 'Neproporcionálne';

  @override
  String get settingsLyricsPreviewExample =>
      'Keď príde ráno, budeme znova spievať.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Kontrolujú sa zdroje textov piesní: dokončené $checked z $total.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Nenašli sa použiteľné texty piesní.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Vybraná pieseň sa skontrolovala v povolených zdrojoch, ale žiadny z nich neposkytol použiteľnú verziu textu.';

  @override
  String get searchDiscoveryError =>
      'Zdroje textov piesní sa nepodarilo skontrolovať.';

  @override
  String get searchDiscoveryRetry => 'Znova vyhľadať texty piesní';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nedostupných zdrojov',
      few: '$count nedostupné zdroje',
      one: '1 nedostupný zdroj',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Skontrolujte pripojenie a skúste to znova.';

  @override
  String get searchProviderChecks => 'Kontroly zdrojov';

  @override
  String get searchProviderPending => 'Kontroluje sa';

  @override
  String get searchProviderFound => 'Zhoda sa našla';

  @override
  String get searchProviderRejected => 'Nezodpovedá';

  @override
  String get searchProviderFailed => 'Kontrola zlyhala';

  @override
  String get searchProviderUnavailable => 'Žiadne použiteľné texty piesní';

  @override
  String get searchCatalogFilterHint =>
      'Vyberte pieseň a filtrujte verzie textu podľa akordov, časovania alebo jazyka.';

  @override
  String get startupErrorTitle => 'Knižnicu sa nepodarilo otvoriť.';

  @override
  String setlistCopyName(String name) {
    return 'Kópia: $name';
  }

  @override
  String get setlistSongMissing => 'Chýbajúca pieseň';

  @override
  String get settingsImportTooLarge =>
      'Tento súbor je príliš veľký na importovanie.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Prejsť na písmeno $letter';
  }

  @override
  String get actionDiscard => 'Zahodiť';

  @override
  String get editorKeepEditing => 'Pokračovať v úpravách';

  @override
  String get settingsDefaultShowChordsHint =>
      'Ak pieseň obsahuje akordy, zobrazovať ich nad textom.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Text sa posúva spolu s piesňou. V režime manuálneho posúvania sa táto možnosť nepoužíva.';

  @override
  String get accountUnavailableTitle => 'Synchronizácia nie je nastavená';

  @override
  String get accountSignedOutBenefits =>
      'Pripojením Google Drive sa synchronizuje vaša knižnica. Zmeny piesní sa potom synchronizujú automaticky.';

  @override
  String get accountManualSyncHint =>
      'Knižnicu môžete synchronizovať aj ťuknutím na Synchronizovať teraz.';

  @override
  String get accountSignInWithGoogle => 'Prihlásiť sa cez Google';

  @override
  String get accountWorking => 'Pracuje sa…';

  @override
  String get accountNeverSynced => 'Ešte nesynchronizované';

  @override
  String get accountSyncedJustNow => 'Práve synchronizované';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronizované pred $count minútami',
      few: 'Synchronizované pred $count minútami',
      one: 'Synchronizované pred 1 minútou',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronizované pred $count hodinami',
      few: 'Synchronizované pred $count hodinami',
      one: 'Synchronizované pred 1 hodinou',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronizované pred $count dňami',
      few: 'Synchronizované pred $count dňami',
      one: 'Synchronizované pred 1 dňom',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count konfliktných úprav sa uložilo ako kópie',
      few: '$count konfliktné úpravy sa uložili ako kópie',
      one: '1 konfliktná úprava sa uložila ako kópia',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Tá istá pieseň alebo ten istý koncertný program boli upravené na dvoch miestach. Nič sa nestratilo: druhá verzia sa uložila ako samostatná kópia.';

  @override
  String get accountReviewConflicts => 'Skontrolovať kópie';

  @override
  String get songsConflictFilterActive => 'Zobrazujú sa iba konfliktné kópie';

  @override
  String get songsConflictFilterClear => 'Zobraziť všetky piesne';

  @override
  String get songsConflictBadge => 'Konfliktná kópia';

  @override
  String get songsConflictEmpty => 'Žiadne konfliktné kópie.';

  @override
  String get accountAutoSync => 'Synchronizovať automaticky';

  @override
  String get accountAutoSyncHint =>
      'Synchronizácia prebehne po pripojení a po pridaní, úprave alebo odstránení piesne.';

  @override
  String get accountSignOutTitle => 'Odhlásiť sa z tohto účtu?';

  @override
  String get accountSignOutBody =>
      'Vaše piesne a koncertné programy zostanú v tomto zariadení. Nebudú sa zálohovať ani synchronizovať, kým sa znova neprihlásite.';

  @override
  String get accountUseDifferent => 'Použiť iný účet';

  @override
  String get accountSignInAgain => 'Znova sa prihlásiť';

  @override
  String get accountChooseAction => 'Vyberte, ako chcete pokračovať';

  @override
  String get accountChangedTitle => 'Iný účet Google';

  @override
  String get accountChangedBody =>
      'Toto zariadenie sa naposledy synchronizovalo s iným účtom Google. Vyberte, čo sa má stať s piesňami a koncertnými programami v tomto zariadení.';

  @override
  String get accountChangedMerge => 'Zlúčiť s novým účtom';

  @override
  String get accountChangedMergeHint =>
      'Ponechať všetko v tomto zariadení a pridať to do nového účtu.';

  @override
  String get accountChangedReplace => 'Nahradiť knižnicou nového účtu';

  @override
  String get accountChangedReplaceHint =>
      'Piesne v tomto zariadení, ktoré nie sú v novom účte, sa odstránia.';

  @override
  String get accountChangedSignOut => 'Zrušiť a odhlásiť sa';

  @override
  String get accountStatusSignedOut => 'Účet a synchronizácia: odhlásené';

  @override
  String get accountStatusSignedIn => 'Účet a synchronizácia: prihlásené';

  @override
  String get accountStatusSyncing => 'Účet a synchronizácia: synchronizuje sa';

  @override
  String get accountStatusSynced =>
      'Účet a synchronizácia: knižnica je aktuálna';

  @override
  String get accountStatusError =>
      'Účet a synchronizácia: problém, ťuknutím zobrazíte podrobnosti';

  @override
  String get accountNoticeConflicts =>
      'Niektoré piesne boli upravené na dvoch miestach. Kópie sa zachovali.';

  @override
  String get accountNoticeSignedIn => 'Prihlásili ste sa.';

  @override
  String get accountNoticeSignedOut =>
      'Odhlásili ste sa. Vaše piesne zostávajú v tomto zariadení.';

  @override
  String get syncErrorNotConfigured =>
      'V tomto zostavení nie je synchronizácia nastavená.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Použite verziu aplikácie Singbook s nakonfigurovaným prihlasovaním cez Google.';

  @override
  String get syncErrorNotSignedIn => 'Nie ste prihlásení.';

  @override
  String get syncErrorNotSignedInHint =>
      'Prihláste sa a synchronizujte svoju knižnicu.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google vyžaduje, aby ste sa znova prihlásili.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Znova sa prihláste a pokračujte v synchronizácii. Vaše piesne sú v tomto zariadení v bezpečí.';

  @override
  String get syncErrorAccessDenied =>
      'Aplikácia Singbook nemá povolenie používať Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Znova sa prihláste a po výzve povoľte prístup k Drive.';

  @override
  String get syncErrorRateLimited =>
      'Google momentálne obmedzuje počet požiadaviek.';

  @override
  String get syncErrorRateLimitedHint =>
      'Počkajte niekoľko minút a skúste to znova.';

  @override
  String get syncErrorStorageFull => 'Váš Google Drive je plný.';

  @override
  String get syncErrorStorageFullHint =>
      'Uvoľnite miesto na Drive a skúste to znova.';

  @override
  String get syncErrorNetwork => 'Nepodarilo sa spojiť so službou Google.';

  @override
  String get syncErrorNetworkHint =>
      'Skontrolujte internetové pripojenie a skúste to znova.';

  @override
  String get syncErrorAccountChanged => 'Použil sa iný účet Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Vyberte, či chcete knižnicu z tohto zariadenia zlúčiť s novým účtom alebo ju nahradiť.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Synchronizovaná knižnica je príliš veľká na spracovanie aplikáciou Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Odstráňte niektoré piesne alebo koncertné programy zo synchronizovanej knižnice a skúste to znova.';

  @override
  String get syncErrorSignInFailed => 'Prihlásenie sa nedokončilo.';

  @override
  String get syncErrorSignInFailedHint => 'Skúste sa znova prihlásiť.';

  @override
  String get syncErrorGeneric => 'Knižnicu sa nepodarilo synchronizovať.';

  @override
  String get syncErrorGenericHint =>
      'O chvíľu to skúste znova. Vaše piesne sú v tomto zariadení stále v bezpečí.';

  @override
  String get editorDurationInvalid =>
      'Zadajte sekundy alebo minúty a sekundy, napríklad 3:45.';

  @override
  String get editorNumberInvalid => 'Zadajte číslo.';

  @override
  String get accountReplaceConfirmTitle => 'Odstrániť miestne piesne?';

  @override
  String get accountReplaceConfirmBody =>
      'Piesne a koncertné programy v tomto zariadení, ktoré nie sú v novom účte, sa natrvalo odstránia. Túto akciu nie je možné vrátiť späť.';

  @override
  String get accountReplaceConfirmAction => 'Odstrániť a nahradiť';

  @override
  String get accountSuspiciousTitle => 'Na Google Drive chýbajú položky';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count položiek, ktoré toto zariadenie predtým synchronizovalo, chýba na Google Drive.',
      few:
          '$count položky, ktoré toto zariadenie predtým synchronizovalo, chýbajú na Google Drive.',
      one:
          '$count položka, ktorú toto zariadenie predtým synchronizovalo, chýba na Google Drive.',
    );
    return '$_temp0 Môže sa to stať, ak boli údaje aplikácie vymazané v nastaveniach Google. Zatiaľ sa nič neodstránilo.';
  }

  @override
  String get accountSuspiciousDelete => 'Odstrániť ich aj tu';

  @override
  String get accountSuspiciousKeep => 'Ponechať piesne a znova ich nahrať';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Odstrániť $count položiek z tohto zariadenia?',
      few: 'Odstrániť $count položky z tohto zariadenia?',
      one: 'Odstrániť $count položku z tohto zariadenia?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Tieto piesne a koncertné programy sa z tohto zariadenia natrvalo odstránia. Túto akciu nemožno vrátiť späť.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Odstrániť z tohto zariadenia';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Na Google Drive chýbajú položky.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Nič sa neodstránilo. Vyberte, či ich chcete odstrániť aj tu alebo znova nahrať.';

  @override
  String get syncErrorRemoteChanged =>
      'Počas synchronizácie sa Google Drive zmenil.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Nič sa nestratilo. Znova synchronizujte a získajte najnovšie zmeny.';

  @override
  String get syncErrorInvalidLocalData =>
      'Niektoré údaje v tomto zariadení sa nepodarilo synchronizovať.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Pieseň alebo koncertný program sa nepodarilo načítať. Importujte ho alebo vytvorte znova a potom synchronizujte.';

  @override
  String get syncErrorNoAccountChange =>
      'Nie je tu žiadna zmena účtu na vyriešenie.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Pokračujte opätovnou synchronizáciou.';

  @override
  String get accountSyncWarningTitle =>
      'Synchronizácia dokončená, niektoré súbory sa preskočili';

  @override
  String get accountSyncWarningBody =>
      'Niektoré súbory sa nedali použiť a zostali nezmenené. Ostatné údaje sú aktuálne.';

  @override
  String get accountSyncWarningTooLarge =>
      'Súbor bol príliš veľký na synchronizáciu a preskočil sa. Ostatné údaje sú aktuálne.';

  @override
  String get accountSyncWarningInvalid =>
      'Súbor sa nepodarilo načítať a preskočil sa. Ostatné údaje sú aktuálne.';

  @override
  String get accountNoticeSyncSkipped =>
      'Synchronizované. Niektoré súbory sa preskočili.';

  @override
  String get settingsExportPdfTooLarge =>
      'Tento súbor PDF by bol príliš veľký. Skúste menej piesní alebo ho zdieľajte ako text.';

  @override
  String get settingsTimingTooLarge =>
      'Údaje o časovaní sú príliš veľké (viac ako 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Táto záloha uvádza tú istú pieseň dvakrát, preto sa nič neimportovalo.';

  @override
  String get setlistSaveConflict =>
      'Koncertný program sa zmenil inde. Vaše úpravy sa uložili ako samostatná kópia.';

  @override
  String get sectionVerse => 'Sloha';

  @override
  String get sectionChorus => 'Refrén';

  @override
  String get sectionBridge => 'Bridge';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Predrefrén';

  @override
  String get sectionPostChorus => 'Porefrén';

  @override
  String get sectionInstrumental => 'Inštrumentál';

  @override
  String get sectionInterlude => 'Medzihra';

  @override
  String get sectionSolo => 'Sólo';

  @override
  String get sectionRefrain => 'Prípev';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Kóda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Záver';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dostupných verzí',
      few: '$count dostupné verze',
      one: '$count pripravená verzia',
      zero: 'Žádné dostupné verze',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nedostupných verzí',
      few: '$count nedostupné verze',
      one: '$count nedostupná verzia',
      zero: 'Žádné nedostupné verze',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Prejsť na sekciu';

  @override
  String get searchVersionDetails => 'Podrobnosti o verzii';

  @override
  String get searchSelectedRecording => 'Vybratá nahrávka';

  @override
  String get searchVersionDuration => 'Dĺžka verzie';

  @override
  String get searchSourceOptions => 'Možnosti zdroja';

  @override
  String get actionUndo => 'Vrátiť späť';

  @override
  String setlistEntryRemoved(String song) {
    return 'Skladba „$song“ bola odstránená zo setlistu';
  }

  @override
  String get backupTitle => 'Zálohovanie a obnovenie';

  @override
  String get backupExport => 'Exportovať zálohu';

  @override
  String get backupRestore => 'Obnoviť zálohu';

  @override
  String get backupIncludePreferences => 'Zahrnúť nastavenia aplikácie';

  @override
  String get backupRestorePreferences => 'Obnoviť nastavenia aplikácie';

  @override
  String get backupMerge => 'Pridať do tejto knižnice';

  @override
  String get backupMergeHint =>
      'Zachovať miestne úpravy a pridať skladby a setlisty z tejto zálohy.';

  @override
  String get backupReplace => 'Nahradiť túto knižnicu';

  @override
  String get backupReplaceHint =>
      'Nahradiť všetky skladby a setlisty v tomto zariadení obsahom tejto zálohy.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Skladby: $songs · Setlisty: $setlists · Konflikty: $conflicts';
  }

  @override
  String get backupFailed =>
      'Operáciu sa nepodarilo dokončiť. Skúste to znova.';

  @override
  String get backupRestored => 'Záloha bola obnovená.';

  @override
  String get backupLocalHint =>
      'Uložte si kópiu knižnice. Údaje účtu ani súbory cookie súhlasu sa nezahŕňajú.';

  @override
  String get backupReplaceConfirm =>
      'Nahradiť aktuálnu knižnicu? Túto akciu nemožno vrátiť späť.';

  @override
  String get searchCheckOperations => 'Operácie';

  @override
  String get searchCheckCode => 'Kód výsledku';

  @override
  String get searchCheckQueued => 'Čaká sa na kontrolu tohto zdroja.';

  @override
  String get searchCheckFetch => 'Načítať text piesne';

  @override
  String get searchCheckValidate => 'Overiť zhodu skladby';

  @override
  String get searchCheckCorroborate => 'Overiť zhodu textu';

  @override
  String get searchCheckCompleted => 'Dokončené';

  @override
  String get searchCheckTimeout => 'Zdroj neodpovedal včas.';

  @override
  String get searchCheckBlocked => 'Zdroj zablokoval požiadavku.';

  @override
  String get searchCheckRateLimited =>
      'Zdroj obmedzuje požiadavky. Skúste to znova neskôr.';

  @override
  String get searchCheckNetwork =>
      'Zdroj sa nepodarilo kontaktovať. Skontrolujte pripojenie.';

  @override
  String get searchCheckInvalid => 'Zdroj vrátil nečitateľnú odpoveď.';

  @override
  String get searchCheckNotConfigured =>
      'Tento zdroj nie je v tejto zostave nakonfigurovaný.';

  @override
  String get searchCheckNoLyrics => 'Nenašli sa zodpovedajúce texty piesní.';

  @override
  String get searchCheckFailed => 'Túto operáciu sa nepodarilo dokončiť.';

  @override
  String get searchCheckNoHistory =>
      'Pre toto porovnanie sa nespustili žiadne kontroly zdrojov.';

  @override
  String get searchVersionCredits => 'Autori a zdroje';

  @override
  String get searchVersionMediaLinks => 'Súvisiace odkazy';

  @override
  String get searchCheckCancelled => 'Zrušené';

  @override
  String get searchCheckAmbiguous =>
      'Našlo sa niekoľko zhôd. Tento zdroj vyžaduje konkrétnejšiu nahrávku.';

  @override
  String get searchCheckIdentity =>
      'Tento zdroj vyžaduje identifikátor nahrávky alebo diela.';

  @override
  String get searchCheckExtraction =>
      'Zdroj odpovedal, ale text sa nepodarilo extrahovať.';

  @override
  String get searchCheckBusy =>
      'Zdroj je zaneprázdnený. Skúste to znova neskôr.';

  @override
  String get searchCheckSelection =>
      'Vyberte konkrétny výsledok z tohto zdroja.';

  @override
  String get playerChordsNone => 'Žiadne';

  @override
  String get editorCustomValue => 'Iné…';

  @override
  String get editorStandardTuning => 'Štandardné ladenie';

  @override
  String get editorExampleVerse =>
      '[C]Nový deň nás [G]volá,\n[Am]za svetlom sa vraciame [F]domov.';

  @override
  String get editorExampleChorus =>
      '[F]Spievajme túto pieseň [C]spolu,\n[G]nech nás melódia nesie [C]ďalej.';

  @override
  String get editorExampleBridge => '[Am]Ešte jeden riadok, o čosi [F]bližšie.';

  @override
  String get playerEstimatedKey => 'Odhadovaná tónina';
}
