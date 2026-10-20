// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Texty, akordy a seznamy písní pohromadě, připravené na zkoušku, na pódium i kamkoli, kde hrajete.';

  @override
  String get aboutMadeForSinging => 'Každá píseň připravená.';

  @override
  String get aboutDetails =>
      'Prohledávejte povolené zdroje a porovnávejte texty, akordy, časování a podrobnosti o nahrávkách, než uložíte verzi, kterou chcete hrát. Dostupnost se liší podle písně a služby.';

  @override
  String get aboutFindTitle => 'Najděte správnou verzi';

  @override
  String get aboutKeepTitle => 'Vytvořte si vlastní knihovnu';

  @override
  String get aboutKeepDetails =>
      'Upravujte a transponujte písně, uchovávejte je ve své místní knihovně pro offline použití a sdílejte přenosné soubory ChordPro. Volitelná synchronizace s Google Drive využívá soukromou složku aplikace ve vašem účtu Google. Klepnutím na „Synchronizovat nyní“ můžete také aktualizovat svá zařízení.';

  @override
  String get aboutPlayTitle => 'Vezměte si svůj seznam na pódium';

  @override
  String get aboutPlayDetails =>
      'Řaďte písně do seznamů, vyberte tóninu pro každou píseň a sdílejte seznamy OpenSong. Upravte velikost textu čtečky, automatické posouvání textu a tiskněte PDF s písněmi. Singbook nepřenáší ani nepřehrává zvuk.';

  @override
  String get aboutPrivacyTitle => 'Zdarma, s knihovnou v zařízení';

  @override
  String get aboutPrivacyDetails =>
      'Singbook je zdarma, bez reklam, analytiky a nákupů v aplikaci. Vaše uložená knihovna zůstává ve vašem zařízení; volitelná synchronizace používá váš Google Drive. Online výsledky pocházejí přímo od nezávislých služeb třetích stran a mohou být nedostupné nebo chráněné autorským právem. Singbook jejich obsah nehostuje.';

  @override
  String get aboutWebsite => 'Web Singbook';

  @override
  String get aboutSourceCode => 'Zdrojový kód na GitHubu';

  @override
  String get aboutPublisher => 'Od Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Jazyky aplikace: $count';
  }

  @override
  String get aboutSupport => 'Podpora a zpětná vazba';

  @override
  String get menuTypeNewSong => 'Zadat novou píseň';

  @override
  String appVersion(String version) {
    return 'Verze $version';
  }

  @override
  String get navHome => 'Domů';

  @override
  String get navSongs => 'Písně';

  @override
  String get navSetlists => 'Koncertní programy';

  @override
  String get navSettings => 'Nastavení';

  @override
  String get navSettingsCompact => 'Nastavení';

  @override
  String get navSearch => 'Hledat';

  @override
  String get navBack => 'Zpět';

  @override
  String get appExitBackAgain =>
      'Dalším stisknutím tlačítka Zpět aplikaci ukončíte';

  @override
  String get navClose => 'Zavřít';

  @override
  String get navMore => 'Další akce';

  @override
  String get actionCancel => 'Zrušit';

  @override
  String get actionSave => 'Uložit';

  @override
  String get actionDone => 'Hotovo';

  @override
  String get actionEdit => 'Upravit';

  @override
  String get actionDelete => 'Smazat';

  @override
  String get actionShare => 'Sdílet';

  @override
  String get actionPrint => 'Tisk';

  @override
  String get actionCopy => 'Kopírovat';

  @override
  String get actionClear => 'Vymazat';

  @override
  String get actionRetry => 'Zkusit znovu';

  @override
  String get actionRefresh => 'Obnovit';

  @override
  String get actionImport => 'Importovat';

  @override
  String get actionExport => 'Exportovat';

  @override
  String get actionExpand => 'Rozbalit';

  @override
  String get actionCollapse => 'Sbalit';

  @override
  String get actionAdd => 'Přidat';

  @override
  String get actionCreate => 'Vytvořit';

  @override
  String get actionRemove => 'Odebrat';

  @override
  String get actionDuplicate => 'Duplikovat';

  @override
  String get actionMoveUp => 'Posunout nahoru';

  @override
  String get actionMoveDown => 'Posunout dolů';

  @override
  String get actionPrevious => 'Předchozí';

  @override
  String get actionNext => 'Další';

  @override
  String get searchHint => 'Hledat písně, interprety nebo texty písní';

  @override
  String get searchCatalogHint => 'Hledat píseň nebo interpreta';

  @override
  String get searchChangeSong => 'Změnit píseň';

  @override
  String get searchSelectedPreview => 'Vybraný náhled';

  @override
  String get searchSubmit => 'Hledat';

  @override
  String get searchFilters => 'Možnosti vyhledávání';

  @override
  String get searchFiltersShow => 'Zobrazit možnosti vyhledávání';

  @override
  String get searchFiltersHide => 'Skrýt možnosti vyhledávání';

  @override
  String get searchFilterArtist => 'Interpret';

  @override
  String get searchFilterTitle => 'Název písně';

  @override
  String get searchFilterLyrics => 'Texty písní';

  @override
  String get searchFilterChords => 'Obsahuje akordy';

  @override
  String get searchFilterTimed => 'Texty s časováním';

  @override
  String get searchFilterLanguage => 'Jazyk';

  @override
  String get searchFilterAll => 'Libovolný';

  @override
  String get searchAutocompleteLabel => 'Návrhy';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count výsledků',
      few: '$count výsledky',
      one: '1 výsledek',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Zadejte píseň, interpreta nebo verš, který chcete vyhledat.';

  @override
  String get searchCatalogEmptyQuery =>
      'Zadejte píseň nebo interpreta, kterého chcete vyhledat.';

  @override
  String get searchNoResults =>
      'Nebyly nalezeny žádné písně. Zkuste jiné hledání.';

  @override
  String get searchLoading => 'Vyhledávání písní…';

  @override
  String get searchError => 'Vyhledávání se nepodařilo dokončit.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Nedávné';

  @override
  String get searchFavoritesTab => 'Oblíbené';

  @override
  String get searchSuggested => 'Navrhovaná shoda';

  @override
  String get searchAlternatives => 'Další shody';

  @override
  String get searchCompare => 'Porovnat verze';

  @override
  String get searchChooseVersion => 'Vybrat tuto verzi';

  @override
  String get searchFullPreview => 'Úplný náhled';

  @override
  String get searchArrangementNotes => 'Poznámky k aranžmá';

  @override
  String get searchOpenLyrics => 'Otevřít text';

  @override
  String get searchContributions => 'Použité zdroje';

  @override
  String get searchVersionChecking => 'Ověřování této verze…';

  @override
  String get searchVersionUnavailable =>
      'Tuto verzi nelze použít. Vyberte jinou verzi.';

  @override
  String get searchPreviewUnavailable => 'Náhled textu není k dispozici.';

  @override
  String get searchSongMatch => 'Shoda písně';

  @override
  String get searchRecordingMatch => 'Shoda nahrávky';

  @override
  String get searchMatchUnverified => 'Nahrávka není ověřena';

  @override
  String get searchMatchExact => 'Přesná shoda nahrávky';

  @override
  String get searchMatchPossible => 'Možná shoda';

  @override
  String get searchAvailability => 'Dostupnost';

  @override
  String get searchLyricsAvailable => 'Text písně je k dispozici';

  @override
  String get searchLyricsUnavailable => 'Text písně není k dispozici';

  @override
  String get searchChordsAvailable => 'Akordy jsou k dispozici';

  @override
  String get searchChordsUnavailable => 'Bez akordů';

  @override
  String get searchTimingAvailable => 'Časování je k dispozici';

  @override
  String get searchTimingUnavailable => 'Časování není k dispozici';

  @override
  String get searchDurationUnknown => 'Délka není známa';

  @override
  String searchRating(String rating) {
    return 'Hodnocení $rating';
  }

  @override
  String get searchSourceLabel => 'Zdroj';

  @override
  String get searchMetadata => 'Informace o písni';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Interpret';

  @override
  String get searchYear => 'Rok';

  @override
  String get searchLanguage => 'Jazyk';

  @override
  String get searchViewVersions => 'Zobrazit verze';

  @override
  String get searchSaved => 'Píseň byla uložena do vaší knihovny.';

  @override
  String get searchSaveOpenLyrics => 'Uložit a otevřít text';

  @override
  String get searchOtherResults => 'Další výsledky';

  @override
  String get searchSaveFailed => 'Píseň se nepodařilo uložit.';

  @override
  String get homeRecentSongs => 'Nedávné písně';

  @override
  String get homeRecentlyPlayed => 'Nedávno přehrávané';

  @override
  String get homeFavorites => 'Oblíbené';

  @override
  String get homeHistory => 'Historie';

  @override
  String get homeHistoryClear => 'Vymazat historii';

  @override
  String get homeHistoryCleared => 'Historie byla vymazána.';

  @override
  String get homeHistoryEmpty => 'Zde se zobrazí písně, které otevřete.';

  @override
  String get homeFavoritesEmpty =>
      'Zde se zobrazí vaše oblíbené písně a koncertní programy.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zobrazeno $count položek',
      few: 'Zobrazeny $count položky',
      one: 'Zobrazena 1 položka',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Zde se zobrazí vaše nedávné písně a koncertní programy.';

  @override
  String get homeTimelineLabel => 'Časová osa historie';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Celá historie';

  @override
  String get homeShowFavorites => 'Zobrazit oblíbené';

  @override
  String get homeShowRecent => 'Zobrazit nedávné';

  @override
  String get songsTitle => 'Písně';

  @override
  String get songsEmpty => 'Zde se zobrazí vaše písně.';

  @override
  String get songsEmptySearch => 'Žádná píseň neodpovídá hledání.';

  @override
  String get songsAdd => 'Přidat píseň';

  @override
  String get songsSortAlphabetical => 'Seřadit abecedně';

  @override
  String get songsAlphabetNavigation => 'Rejstřík písní';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}krát',
      few: '${count}krát',
      one: 'jednou',
    );
    return 'Otevřeno $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Přidat k oblíbeným';

  @override
  String get songFavoriteRemove => 'Odebrat z oblíbených';

  @override
  String get songMenuLabel => 'Akce s písní';

  @override
  String get songInfo => 'Informace o písni';

  @override
  String get setlistMenuLabel => 'Akce s koncertním programem';

  @override
  String get songAddToSetlist => 'Přidat do koncertního programu';

  @override
  String get songCopyChordPro => 'Kopírovat ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Smazat píseň?';

  @override
  String get songDeleteConfirmMessage =>
      'Tato píseň bude odebrána z vaší knihovny.';

  @override
  String get songDeleted => 'Píseň byla smazána.';

  @override
  String get setlistsTitle => 'Koncertní programy';

  @override
  String get setlistsEmpty =>
      'Vytvořte koncertní program pro příští zkoušku nebo vystoupení.';

  @override
  String get setlistsEmptySearch =>
      'Žádný koncertní program neodpovídá hledání.';

  @override
  String get setlistCreate => 'Nový koncertní program';

  @override
  String get setlistNameHint => 'Název koncertního programu';

  @override
  String get setlistNotes => 'Poznámky';

  @override
  String get setlistEntryOverride => 'Tónina a kapodastr pro tuto píseň';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count písní',
      few: '$count písně',
      one: '1 píseň',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Alespoň $duration';
  }

  @override
  String get setlistDurationUnknown => 'Délka není známa';

  @override
  String setlistActivity(String date) {
    return 'Poslední aktivita $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Vytvořeno $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Upraveno $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Naposledy přehráno $date';
  }

  @override
  String get setlistSongsEmpty =>
      'V tomto koncertním programu zatím nejsou žádné písně.';

  @override
  String get setlistAddSongs => 'Přidat písně';

  @override
  String get setlistReorder => 'Změnit pořadí písní';

  @override
  String setlistMoveSongUp(String song) {
    return 'Posunout píseň „$song“ nahoru';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Posunout píseň „$song“ dolů';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Odebrat píseň „$song“ z koncertního programu';
  }

  @override
  String get setlistDuplicate => 'Duplikovat koncertní program';

  @override
  String get setlistFavoriteAdd => 'Přidat koncertní program k oblíbeným';

  @override
  String get setlistFavoriteRemove => 'Odebrat koncertní program z oblíbených';

  @override
  String get setlistShare => 'Sdílet jako OpenSong';

  @override
  String get setlistSharePdf => 'Sdílet jako PDF';

  @override
  String get setlistPrint => 'Tisk';

  @override
  String get setlistDeleteConfirmTitle => 'Smazat koncertní program?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Koncertní program bude odebrán. Písně ve vaší knihovně zůstanou.';

  @override
  String get setlistDeleted => 'Koncertní program byl smazán.';

  @override
  String get readerTitle => 'Texty písní';

  @override
  String get readerNoLyrics => 'Text písně zatím nebyl přidán.';

  @override
  String get readerShowChords => 'Zobrazit akordy';

  @override
  String get readerHideChords => 'Skrýt akordy';

  @override
  String get readerTranspose => 'Transponovat akordy';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count půltónů',
      few: '$count půltóny',
      one: '1 půltón',
    );
    return 'Transponovat o $_temp0';
  }

  @override
  String get readerSaved => 'Uloženo';

  @override
  String get readerEdit => 'Upravit text písně a informace';

  @override
  String get playerPlay => 'Přehrát';

  @override
  String get playerPause => 'Pozastavit';

  @override
  String get playerResume => 'Pokračovat v posouvání textu písně';

  @override
  String get playerSeek => 'Pozice přehrávání';

  @override
  String playerElapsed(String time) {
    return 'Uplynulý čas $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Zbývající čas $time';
  }

  @override
  String get playerTimingMode => 'Režim posouvání';

  @override
  String get playerTimedLyrics => 'Texty s časováním';

  @override
  String get playerStartScroll => 'Spustit automatické posouvání';

  @override
  String get playerEstimatedPace => 'Odhadované tempo';

  @override
  String get playerScrollSpeed => 'Rychlost posouvání';

  @override
  String playerEstimatedDuration(String time) {
    return 'Odhadovaná délka: $time';
  }

  @override
  String get playerLyricsOnly => 'Posouvání textu · bez zvuku';

  @override
  String get playerManualScroll => 'Ruční posouvání';

  @override
  String get playerTimingStatusReady =>
      'Text písně se bude posouvat podle dostupného časování.';

  @override
  String get playerTimingStatusEstimated =>
      'Tempo posouvání se odhaduje podle délky písně.';

  @override
  String get playerTimingStatusManual => 'Posouvejte text písně sami.';

  @override
  String get playerTimingStatusUnavailable =>
      'Synchronizované posouvání není pro tuto píseň k dispozici.';

  @override
  String get playerDurationUnknown =>
      'Zadejte délku písně, aby bylo možné použít odhadované posouvání.';

  @override
  String get playerProgressLabel => 'Průběh písně';

  @override
  String get playerCurrentSection => 'Aktuální část';

  @override
  String get playerPreviousSection => 'Předchozí část';

  @override
  String get playerNextSection => 'Další část';

  @override
  String get playerPreviousSectionSong =>
      'Předchozí část · podržením přejdete na předchozí píseň v programu';

  @override
  String get playerNextSectionSong =>
      'Další část · podržením přejdete na další píseň v programu';

  @override
  String get playerPreviousSong => 'Předchozí píseň';

  @override
  String get playerNextSong => 'Následující píseň';

  @override
  String get editorTitle => 'Upravit píseň';

  @override
  String get editorTitleField => 'Název písně';

  @override
  String get editorArtistField => 'Interpret';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Text písně';

  @override
  String get editorChordsField => 'Akordy';

  @override
  String get editorKeyField => 'Tónina';

  @override
  String get editorCapoField => 'Kapodastr';

  @override
  String get editorTuningField => 'Ladění';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Délka';

  @override
  String get editorTimeSignatureField => 'Takt';

  @override
  String get editorLanguageField => 'Jazyk';

  @override
  String get editorYearField => 'Rok';

  @override
  String get editorComposerField => 'Skladatel';

  @override
  String get editorLyricistField => 'Autor textu';

  @override
  String get editorCopyrightField => 'Autorská práva';

  @override
  String get editorLicenseField => 'Licence';

  @override
  String get songInfoSources => 'Zdroje a poděkování';

  @override
  String get searchMatchSameSong => 'Stejná píseň; nahrávka není potvrzena';

  @override
  String get searchMatchNeedsAgreement =>
      'Zápis akordů je třeba ověřit podle textu písně';

  @override
  String get searchMatchDifferentLyrics => 'Text se liší od vybrané písně';

  @override
  String get searchMatchCombinedSources => 'Informace sloučené z více zdrojů';

  @override
  String get searchCombinedLabel => 'Kombinované';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shod písní',
      few: '$count shody písní',
      one: '1 shoda písně',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verzí zdroje',
      few: '$count verze zdroje',
      one: '1 verze zdroje',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Nejlepší dostupná shoda';

  @override
  String get providerDescriptionUnknown => 'Zdroj písně';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Stáhněte soubor ChordPro ze zdroje a poté jej importujte.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Stáhněte soubor pomocí bezplatného účtu a poté jej importujte.';

  @override
  String get providerDescPublicChordSheets => 'Veřejné zápisy akordů.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Historické texty písní licencované pro každé dílo zvlášť.';

  @override
  String get providerDescLicensedCatalog => 'Licencovaný katalog textů písní.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Původní písně pod licencí Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Texty písní licencované pro každou píseň zvlášť.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Pouze informace o nahrávce a vydání.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Pouze informace o skladbě.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Obal je k dispozici pouze pro přesné shody nahrávek.';

  @override
  String get providerCapabilityLyrics => 'Texty písní';

  @override
  String get providerCapabilityChords => 'Akordy';

  @override
  String get providerCapabilityTiming => 'Texty s časováním';

  @override
  String get providerCapabilitySearch => 'Vyhledávání';

  @override
  String get providerCapabilityMetadata => 'Informace o písni';

  @override
  String get editorArtworkField => 'Odkaz na obal';

  @override
  String get editorLyricsHint =>
      'Akordy pište do závorek [C]; označení částí na samostatné řádky.';

  @override
  String get editorSave => 'Uložit změny';

  @override
  String get editorSaved => 'Změny byly uloženy.';

  @override
  String get editorSaveFailed => 'Změny se nepodařilo uložit.';

  @override
  String get editorSaveConflict =>
      'Píseň byla změněna jinde. Vaše úpravy byly uloženy jako samostatná kopie.';

  @override
  String get editorUnsavedTitle => 'Zahodit změny?';

  @override
  String get editorUnsavedMessage => 'Vaše úpravy nebyly uloženy.';

  @override
  String get editorFieldRequired => 'Zadejte název písně.';

  @override
  String get settingsTitle => 'Nastavení';

  @override
  String get settingsAppearance => 'Vzhled';

  @override
  String get settingsTheme => 'Motiv';

  @override
  String get settingsThemeSystem => 'Použít nastavení zařízení';

  @override
  String get settingsThemeLight => 'Světlý';

  @override
  String get settingsThemeDark => 'Tmavý';

  @override
  String get settingsColorPalette => 'Paleta barev';

  @override
  String get settingsFont => 'Písmo';

  @override
  String get settingsTextSize => 'Velikost textu';

  @override
  String get settingsLyricsPreview => 'Náhled textu písně';

  @override
  String get settingsPlayer => 'Přehrávač textů písní';

  @override
  String get settingsLyricHighlight => 'Zvýraznění aktuálního řádku';

  @override
  String get settingsHighlightBackgroundUnderline => 'Pozadí + podtržení';

  @override
  String get settingsHighlightBackground => 'Pozadí';

  @override
  String get settingsHighlightUnderline => 'Podtržení';

  @override
  String get settingsHighlightContrast => 'Kontrastní barva textu';

  @override
  String get settingsHighlightNone => 'Žádné';

  @override
  String get settingsDefaultShowChords =>
      'Ve výchozím nastavení zobrazovat akordy';

  @override
  String get settingsDefaultAutoscroll => 'Automaticky spustit posouvání textu';

  @override
  String get settingsDefaultTiming => 'Výchozí režim posouvání';

  @override
  String get settingsLanguage => 'Jazyk aplikace';

  @override
  String get settingsLanguageSystem => 'Použít jazyk zařízení';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Zdroje textů písní';

  @override
  String settingsSourceEnabled(String source) {
    return 'Povolit zdroj $source';
  }

  @override
  String get settingsSourceRefresh => 'Obnovit seznam zdrojů';

  @override
  String get settingsSourcesUpdated => 'Zdroje byly aktualizovány.';

  @override
  String get settingsSourcesUpdateFailed => 'Zdroje se nepodařilo obnovit.';

  @override
  String get settingsImport => 'Importovat písně';

  @override
  String get settingsImportChordPro => 'Importovat soubor ChordPro';

  @override
  String get settingsImportSetlist => 'Importovat soubor koncertního programu';

  @override
  String get settingsImportSuccess => 'Import dokončen.';

  @override
  String get settingsImportFailed => 'Tento soubor se nepodařilo importovat.';

  @override
  String get settingsImportUnsupported => 'Tento typ souboru není podporován.';

  @override
  String get settingsShareSong => 'Sdílet jako ChordPro';

  @override
  String get settingsSharePdf => 'Sdílet jako PDF';

  @override
  String get settingsCopySong => 'Kopírovat do schránky';

  @override
  String get settingsPrintSong => 'Tisknout pouze píseň';

  @override
  String get settingsPrintSetlist => 'Tisknout koncertní program s texty písní';

  @override
  String get settingsExportFailed => 'Soubor se nepodařilo připravit.';

  @override
  String get settingsCopied => 'Zkopírováno do schránky.';

  @override
  String get settingsAbout => 'O aplikaci';

  @override
  String get settingsPrivacy => 'Soukromí';

  @override
  String get settingsLegal => 'Právní informace';

  @override
  String get settingsClearHistory => 'Vymazat historii';

  @override
  String get settingsClearHistoryConfirm =>
      'Vymaže nedávnou historii aktivit u písní a setlistů. Zachová uložené písně, oblíbené položky, setlisty a nastavení.';

  @override
  String get settingsHistoryCleared => 'Historie byla vymazána.';

  @override
  String get accountTitle => 'Účet a synchronizace';

  @override
  String get accountUnavailable =>
      'Synchronizace vyžaduje sestavení Singbook s nastaveným přihlášením přes Google. Tato verze uchovává vaše písně pouze v tomto zařízení.';

  @override
  String get accountSyncNow => 'Synchronizovat nyní';

  @override
  String get accountConnected =>
      'Připojeno. Výběrem možnosti Synchronizovat nyní aktualizujete zálohu.';

  @override
  String get accountSignIn => 'Připojit účet';

  @override
  String get accountSignOut => 'Odhlásit se';

  @override
  String get accountChange => 'Změnit účet';

  @override
  String get accountSignedOut => 'Nepřipojeno';

  @override
  String get accountSyncing => 'Synchronizuje se vaše knihovna…';

  @override
  String get accountSynced => 'Knihovna je synchronizována.';

  @override
  String get accountSyncFailed => 'Knihovnu se nepodařilo synchronizovat.';

  @override
  String get accessibilityFavorite => 'Oblíbená';

  @override
  String get accessibilityNotFavorite => 'Není oblíbená';

  @override
  String get accessibilitySearchField => 'Hledat písně';

  @override
  String get accessibilityClearSearch => 'Vymazat hledaný text';

  @override
  String accessibilitySongMenu(String song) {
    return 'Akce pro píseň $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Akce pro koncertní program $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Rozbalit písně v programu $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Sbalit písně v programu $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Průběh přehrávání, $percent procent';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Časová osa historie, $date';
  }

  @override
  String get loading => 'Načítání…';

  @override
  String get loadingSongs => 'Načítání písní…';

  @override
  String get loadingSetlists => 'Načítání koncertních programů…';

  @override
  String get errorGeneric => 'Něco se pokazilo.';

  @override
  String get errorOffline => 'Zdá se, že jste offline.';

  @override
  String get errorPermission => 'K pokračování je potřeba oprávnění.';

  @override
  String get emptyFiltered => 'Žádná položka neodpovídá těmto filtrům.';

  @override
  String get unknownValue => 'Neznámé';

  @override
  String get durationUnknown => 'Délka není známa';

  @override
  String get metadataNotSet => 'Nenastaveno';

  @override
  String get dateToday => 'Dnes';

  @override
  String get dateYesterday => 'Včera';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count písní',
      few: '$count písně',
      one: '1 píseň',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Námořnická modrá';

  @override
  String get settingsPaletteSage => 'Šalvějová';

  @override
  String get settingsPaletteOcean => 'Oceánská';

  @override
  String get settingsPaletteClay => 'Hliněná';

  @override
  String get settingsPalettePlum => 'Švestková';

  @override
  String get settingsFontSystem => 'Systémové';

  @override
  String get settingsFontSerif => 'Patkové';

  @override
  String get settingsFontMonospace => 'Neproporcionální';

  @override
  String get settingsLyricsPreviewExample =>
      'Až přijde ráno, zazpíváme si znovu.';

  @override
  String get settingsPreviewSongTitle => 'Ranní píseň';

  @override
  String get settingsPreviewArtist => 'Ukázkové aranžmá';

  @override
  String get settingsPreviewCurrentLine => 'Až přijde ráno';

  @override
  String get settingsPreviewNextLine => 'Znovu si zazpíváme.';

  @override
  String get settingsPlayerSections => 'Nadpisy oddílů';

  @override
  String get settingsPlayerControls => 'Panel přehrávání';

  @override
  String get settingsPlayerAutoscroll => 'Automatické posouvání';

  @override
  String get settingsSystemShort => 'Zařízení';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Kontrola zdrojů textů písní: dokončeno $checked z $total.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Nebyly nalezeny použitelné texty písní.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Vybraná píseň byla porovnána s povolenými zdroji, ale žádný z nich nevrátil použitelnou verzi textu.';

  @override
  String get searchDiscoveryError =>
      'Zdroje textů písní se nepodařilo zkontrolovat.';

  @override
  String get searchDiscoveryRetry => 'Znovu vyhledat texty písní';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nedostupných zdrojů',
      few: '$count nedostupné zdroje',
      one: '1 nedostupný zdroj',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Zkontrolujte připojení a zkuste to znovu.';

  @override
  String get searchProviderChecks => 'Kontrola zdrojů';

  @override
  String get searchProviderPending => 'Kontroluje se';

  @override
  String get searchProviderFound => 'Nalezena shoda';

  @override
  String get searchProviderRejected => 'Neshoduje se';

  @override
  String get searchProviderFailed => 'Kontrola selhala';

  @override
  String get searchProviderUnavailable => 'Žádné použitelné texty písní';

  @override
  String get searchCatalogFilterHint =>
      'Vyberte píseň a filtrujte verze textu podle akordů, časování nebo jazyka.';

  @override
  String get startupErrorTitle => 'Knihovnu se nepodařilo otevřít.';

  @override
  String setlistCopyName(String name) {
    return 'Kopie: $name';
  }

  @override
  String get setlistSongMissing => 'Chybějící píseň';

  @override
  String get settingsImportTooLarge =>
      'Tento soubor je příliš velký na import.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Přejít na písmeno $letter';
  }

  @override
  String get actionDiscard => 'Zahodit';

  @override
  String get editorKeepEditing => 'Pokračovat v úpravách';

  @override
  String get settingsDefaultShowChordsHint =>
      'Pokud píseň obsahuje akordy, zobrazovat je nad textem.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Text se posouvá spolu s písní. V režimu ručního posouvání se nepoužívá.';

  @override
  String get accountUnavailableTitle => 'Synchronizace není nastavena';

  @override
  String get accountSignedOutBenefits =>
      'Připojením Google Drive se synchronizuje vaše knihovna. Změny písní se pak synchronizují automaticky.';

  @override
  String get accountManualSyncHint =>
      'Knihovnu můžete synchronizovat také klepnutím na Synchronizovat nyní.';

  @override
  String get accountSignInWithGoogle => 'Přihlásit se přes Google';

  @override
  String get accountWorking => 'Práce probíhá…';

  @override
  String get accountNeverSynced => 'Zatím nesynchronizováno';

  @override
  String get accountSyncedJustNow => 'Právě synchronizováno';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronizováno před $count minutami',
      few: 'Synchronizováno před $count minutami',
      one: 'Synchronizováno před 1 minutou',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronizováno před $count hodinami',
      few: 'Synchronizováno před $count hodinami',
      one: 'Synchronizováno před 1 hodinou',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronizováno před $count dny',
      few: 'Synchronizováno před $count dny',
      one: 'Synchronizováno před 1 dnem',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count konfliktních úprav bylo uloženo jako kopie',
      few: '$count konfliktní úpravy byly uloženy jako kopie',
      one: '1 konfliktní úprava byla uložena jako kopie',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Stejná píseň nebo koncertní program byly upraveny na dvou místech. Nic se neztratilo: druhá verze byla uložena jako samostatná kopie.';

  @override
  String get accountReviewConflicts => 'Zkontrolovat kopie';

  @override
  String get songsConflictFilterActive => 'Zobrazují se pouze konfliktní kopie';

  @override
  String get songsConflictFilterClear => 'Zobrazit všechny písně';

  @override
  String get songsConflictBadge => 'Konfliktní kopie';

  @override
  String get songsConflictEmpty => 'Žádné konfliktní kopie.';

  @override
  String get accountAutoSync => 'Automatická synchronizace';

  @override
  String get accountAutoSyncHint =>
      'Synchronizace proběhne po připojení a po přidání, úpravě nebo odebrání písně.';

  @override
  String get accountDriveFolder => 'Složka knihovny Disku Google';

  @override
  String get accountPrivateDriveFolder => 'Soukromá složka Zpěvník';

  @override
  String get accountChooseDriveFolder => 'Vyberte složku';

  @override
  String get accountDriveFolderMoveTitle => 'Přesunout knihovnu Singbooku?';

  @override
  String get accountDriveFolderMoveBody =>
      'Vyberte viditelnou složku Disku Google. Singbook tam zkopíruje a ověří vaše skladby a setlisty, než na něj přepnete. Původní soubory zůstanou ve svém předchozím umístění jako záloha. Ostatní soubory jsou ponechány na pokoji. Soubory ChordPro, které importujete do této složky, jsou přijaty pro synchronizaci a přijímání metadat Singbooku.';

  @override
  String get accountImportChordPro => 'Importujte ChordPro z Disku';

  @override
  String get accountImportChordProHint =>
      'Vyberte soubory .cho, které chcete přidat do této knihovny. Soubory již ve složce jsou převzaty; soubory jinde jsou zkopírovány sem.';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'Výběr složky na Disku není k dispozici';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'Na podporovaném zařízení vyberte viditelnou složku na Disku Google pomocí jeho výběru.';

  @override
  String get syncErrorDriveFolderMissing =>
      'Složka Singbook Drive není dostupná';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Vyberte složku znovu nebo ji obnovte na Disku Google.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Zpěvník potřebuje přístup k této složce na Disku';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Znovu vyberte složku, ke které chcete udělit přístup, a poté knihovnu synchronizujte.';

  @override
  String get syncErrorFolderMigration =>
      'Knihovnu se zatím nepodařilo přesunout';

  @override
  String get syncErrorFolderMigrationHint =>
      'Vaše předchozí knihovna je stále v bezpečí. Zkontrolujte připojení a znovu vyberte složku a zkuste to znovu.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Nejprve vyberte viditelnou složku na Disku';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'Před importem souborů z Disku je potřeba viditelná složka knihovny.';

  @override
  String get accountSignOutTitle => 'Odhlásit se z tohoto účtu?';

  @override
  String get accountSignOutBody =>
      'Vaše písně a koncertní programy zůstanou v tomto zařízení. Nebudou se zálohovat ani synchronizovat, dokud se znovu nepřihlásíte.';

  @override
  String get accountUseDifferent => 'Použít jiný účet';

  @override
  String get accountSignInAgain => 'Znovu se přihlásit';

  @override
  String get accountChooseAction => 'Zvolte, jak chcete pokračovat';

  @override
  String get accountChangedTitle => 'Jiný účet Google';

  @override
  String get accountChangedBody =>
      'Toto zařízení bylo naposledy synchronizováno s jiným účtem Google. Zvolte, co se má stát s písněmi a koncertními programy v tomto zařízení.';

  @override
  String get accountChangedMerge => 'Sloučit s novým účtem';

  @override
  String get accountChangedMergeHint =>
      'Ponechat vše v tomto zařízení a přidat to do nového účtu.';

  @override
  String get accountChangedReplace => 'Nahradit knihovnou nového účtu';

  @override
  String get accountChangedReplaceHint =>
      'Písně v tomto zařízení, které nejsou v novém účtu, budou odstraněny.';

  @override
  String get accountChangedSignOut => 'Zrušit a odhlásit se';

  @override
  String get accountStatusSignedOut =>
      'Účet a synchronizace: nejste přihlášeni';

  @override
  String get accountStatusSignedIn => 'Účet a synchronizace: jste přihlášeni';

  @override
  String get accountStatusSyncing =>
      'Účet a synchronizace: synchronizace probíhá';

  @override
  String get accountStatusSynced =>
      'Účet a synchronizace: knihovna je aktuální';

  @override
  String get accountStatusError =>
      'Účet a synchronizace: problém, klepnutím zobrazíte podrobnosti';

  @override
  String get accountNoticeConflicts =>
      'Některé písně byly upraveny na dvou místech. Kopie byly zachovány.';

  @override
  String get accountNoticeSignedIn => 'Jste přihlášeni.';

  @override
  String get accountNoticeSignedOut =>
      'Byli jste odhlášeni. Vaše písně zůstávají v tomto zařízení.';

  @override
  String get syncErrorNotConfigured =>
      'Synchronizace není v tomto sestavení nastavena.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Použijte sestavení Singbook s nastaveným přihlášením přes Google.';

  @override
  String get syncErrorNotSignedIn => 'Nejste přihlášeni.';

  @override
  String get syncErrorNotSignedInHint =>
      'Přihlaste se a synchronizujte svou knihovnu.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google vás žádá o opětovné přihlášení.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Znovu se přihlaste a pokračujte v synchronizaci. Vaše písně jsou v tomto zařízení v bezpečí.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook nemá oprávnění používat Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Znovu se přihlaste a po zobrazení výzvy povolte přístup k Drive.';

  @override
  String get syncErrorRateLimited => 'Google nyní omezuje počet požadavků.';

  @override
  String get syncErrorRateLimitedHint =>
      'Počkejte několik minut a zkuste to znovu.';

  @override
  String get syncErrorStorageFull => 'Váš Google Drive je plný.';

  @override
  String get syncErrorStorageFullHint =>
      'Uvolněte místo na Drive a zkuste to znovu.';

  @override
  String get syncErrorNetwork => 'Nepodařilo se spojit se službou Google.';

  @override
  String get syncErrorNetworkHint =>
      'Zkontrolujte připojení k internetu a zkuste to znovu.';

  @override
  String get syncErrorAccountChanged => 'Byl použit jiný účet Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Zvolte, zda chcete knihovnu z tohoto zařízení sloučit s novým účtem, nebo ji nahradit.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Synchronizovaná knihovna je příliš velká na to, aby ji Singbook zpracoval.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Odeberte ze synchronizované knihovny některé písně nebo koncertní programy a zkuste to znovu.';

  @override
  String get syncErrorSignInFailed => 'Přihlášení nebylo dokončeno.';

  @override
  String get syncErrorSignInFailedHint => 'Zkuste se znovu přihlásit.';

  @override
  String get syncErrorGeneric => 'Knihovnu se nepodařilo synchronizovat.';

  @override
  String get syncErrorGenericHint =>
      'Zkuste to znovu za chvíli. Vaše písně jsou v tomto zařízení stále v bezpečí.';

  @override
  String get editorDurationInvalid =>
      'Zadejte sekundy nebo minuty a sekundy, například 3:45.';

  @override
  String get editorNumberInvalid => 'Zadejte číslo.';

  @override
  String get accountReplaceConfirmTitle => 'Smazat místní písně?';

  @override
  String get accountReplaceConfirmBody =>
      'Písně a koncertní programy v tomto zařízení, které nejsou v novém účtu, budou trvale smazány. Tuto akci nelze vrátit zpět.';

  @override
  String get accountReplaceConfirmAction => 'Smazat a nahradit';

  @override
  String get accountSuspiciousTitle => 'Na Google Drive chybí položky';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count položek, které toto zařízení dříve synchronizovalo, na Google Drive chybí.',
      few:
          '$count položky, které toto zařízení dříve synchronizovalo, na Google Drive chybí.',
      one:
          '$count položka, kterou toto zařízení dříve synchronizovalo, na Google Drive chybí.',
    );
    return '$_temp0 Může se to stát, pokud byla data aplikace vymazána v nastavení Google. Zatím nebylo nic smazáno.';
  }

  @override
  String get accountSuspiciousDelete => 'Smazat je i zde';

  @override
  String get accountSuspiciousKeep => 'Ponechat moje písně a znovu je nahrát';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Smazat $count položek z tohoto zařízení?',
      few: 'Smazat $count položky z tohoto zařízení?',
      one: 'Smazat $count položku z tohoto zařízení?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Tyto písně a koncertní programy budou z tohoto zařízení trvale smazány. Tuto akci nelze vrátit zpět.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Smazat z tohoto zařízení';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Na Google Drive chybí položky.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Nic nebylo smazáno. Zvolte, zda je chcete smazat i zde, nebo je znovu nahrát.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive se během synchronizace změnil.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Nic se neztratilo. Opětovnou synchronizací načtete nejnovější změny.';

  @override
  String get syncErrorInvalidLocalData =>
      'Některá data v tomto zařízení se nepodařilo synchronizovat.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Píseň nebo koncertní program se nepodařilo přečíst. Importujte je nebo znovu vytvořte a potom synchronizujte znovu.';

  @override
  String get syncErrorNoAccountChange =>
      'Není zde žádná změna účtu k vyřešení.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Pokračujte opětovnou synchronizací.';

  @override
  String get accountSyncWarningTitle =>
      'Synchronizace proběhla, některé soubory se ale přeskočily';

  @override
  String get accountSyncWarningBody =>
      'Některé soubory se nepodařilo použít a zůstaly beze změny. Vše ostatní je aktuální.';

  @override
  String get accountSyncWarningTooLarge =>
      'Soubor byl pro synchronizaci příliš velký, proto se přeskočil. Vše ostatní je aktuální.';

  @override
  String get accountSyncWarningInvalid =>
      'Soubor se nepodařilo přečíst, proto se přeskočil. Vše ostatní je aktuální.';

  @override
  String get accountNoticeSyncSkipped =>
      'Synchronizace dokončena. Některé soubory byly přeskočeny.';

  @override
  String get settingsExportPdfTooLarge =>
      'Tento soubor PDF by byl příliš velký. Zkuste méně písní nebo ho sdílejte jako text.';

  @override
  String get settingsTimingTooLarge =>
      'Data časování jsou příliš velká (více než 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Tato záloha obsahuje stejnou píseň dvakrát, proto se nic neimportovalo.';

  @override
  String get setlistSaveConflict =>
      'Koncertní program byl změněn jinde. Vaše úpravy byly uloženy jako samostatná kopie.';

  @override
  String get sectionVerse => 'Sloka';

  @override
  String get sectionChorus => 'Refrén';

  @override
  String get sectionBridge => 'Bridge';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Předrefrén';

  @override
  String get sectionPostChorus => 'Pořefrén';

  @override
  String get sectionInstrumental => 'Instrumentální';

  @override
  String get sectionInterlude => 'Mezihra';

  @override
  String get sectionSolo => 'Sólo';

  @override
  String get sectionRefrain => 'Přípěv';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Kóda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Závěr';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dostupných verzí',
      few: '$count dostupné verze',
      one: '$count připravená verze',
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
      one: '$count nedostupná verze',
      zero: 'Žádné nedostupné verze',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Přejít na sekci';

  @override
  String get searchVersionDetails => 'Podrobnosti o verzi';

  @override
  String get searchSelectedRecording => 'Vybraná nahrávka';

  @override
  String get searchVersionDuration => 'Délka verze';

  @override
  String get searchSourceOptions => 'Možnosti zdroje';

  @override
  String get actionUndo => 'Zpět';

  @override
  String setlistEntryRemoved(String song) {
    return 'Skladba „$song“ byla odebrána ze seznamu';
  }

  @override
  String get backupTitle => 'Zálohování a obnovení';

  @override
  String get backupExport => 'Exportovat zálohu';

  @override
  String get backupRestore => 'Obnovit zálohu';

  @override
  String get backupIncludePreferences => 'Zahrnout předvolby aplikace';

  @override
  String get backupRestorePreferences => 'Obnovit předvolby aplikace';

  @override
  String get backupMerge => 'Přidat do této knihovny';

  @override
  String get backupMergeHint =>
      'Zachovat místní úpravy a přidat skladby a seznamy z této zálohy.';

  @override
  String get backupReplace => 'Nahradit tuto knihovnu';

  @override
  String get backupReplaceHint =>
      'Nahradit všechny skladby a seznamy v tomto zařízení obsahem této zálohy.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Skladby: $songs · Seznamy: $setlists · Konflikty: $conflicts';
  }

  @override
  String get backupFailed =>
      'Tuto operaci zálohy se nepodařilo dokončit. Zkuste to znovu.';

  @override
  String get backupRestored => 'Záloha byla obnovena.';

  @override
  String get backupLocalHint =>
      'Uložte si kopii knihovny. Přihlašovací údaje ani soubory cookie souhlasu se nezahrnují.';

  @override
  String get backupReplaceConfirm =>
      'Nahradit současnou knihovnu? Tuto akci nelze vrátit.';

  @override
  String get searchCheckOperations => 'Operace';

  @override
  String get searchCheckCode => 'Kód výsledku';

  @override
  String get searchCheckQueued => 'Čeká se na kontrolu tohoto zdroje.';

  @override
  String get searchCheckFetch => 'Načíst text písně';

  @override
  String get searchCheckValidate => 'Ověřit shodu skladby';

  @override
  String get searchCheckCorroborate => 'Ověřit shodu textu';

  @override
  String get searchCheckCompleted => 'Dokončeno';

  @override
  String get searchCheckTimeout => 'Zdroj neodpověděl včas.';

  @override
  String get searchCheckBlocked => 'Zdroj zablokoval požadavek.';

  @override
  String get searchCheckRateLimited =>
      'Zdroj omezuje počet požadavků. Zkuste to později.';

  @override
  String get searchCheckNetwork =>
      'Zdroj se nepodařilo kontaktovat. Zkontrolujte připojení.';

  @override
  String get searchCheckInvalid => 'Zdroj vrátil nečitelnou odpověď.';

  @override
  String get searchCheckNotConfigured =>
      'Tento zdroj není v tomto sestavení nakonfigurován.';

  @override
  String get searchCheckNoLyrics => 'Nebyl nalezen odpovídající text.';

  @override
  String get searchCheckFailed => 'Tuto operaci se nepodařilo dokončit.';

  @override
  String get searchCheckNoHistory =>
      'Pro toto porovnání neproběhla žádná kontrola zdroje.';

  @override
  String get searchVersionCredits => 'Autoři a licence';

  @override
  String get searchVersionMediaLinks => 'Související odkazy';

  @override
  String get searchCheckCancelled => 'Zrušeno';

  @override
  String get searchCheckAmbiguous =>
      'Bylo nalezeno několik shod. Tento zdroj vyžaduje konkrétnější nahrávku.';

  @override
  String get searchCheckIdentity =>
      'Tento zdroj vyžaduje identifikátor nahrávky nebo díla.';

  @override
  String get searchCheckExtraction =>
      'Zdroj odpověděl, ale text se nepodařilo získat.';

  @override
  String get searchCheckBusy => 'Zdroj je zaneprázdněn. Zkuste to později.';

  @override
  String get searchCheckSelection =>
      'Vyberte konkrétní výsledek z tohoto zdroje.';

  @override
  String get playerChordsNone => 'Žádné';

  @override
  String get editorCustomValue => 'Jiné…';

  @override
  String get editorStandardTuning => 'Standardní ladění';

  @override
  String get editorExampleVerse =>
      '[C]Nový den nás [G]volá,\n[Am]za světlem se vracíme [F]domů.';

  @override
  String get editorExampleChorus =>
      '[F]Zpívejme tuto píseň [C]společně,\n[G]ať nás melodie nese [C]dál.';

  @override
  String get editorExampleBridge => '[Am]Ještě jeden řádek, o něco [F]blíž.';

  @override
  String get playerEstimatedKey => 'Odhadovaná tónina';

  @override
  String get songsLibraryView => 'Knihovna';

  @override
  String get settingsStartupView => 'Otevřít při spuštění';

  @override
  String get settingsStartupViewHint =>
      'Vyberte zobrazení Písně, které se ukáže po otevření aplikace.';

  @override
  String get settingsStartupLastView => 'Naposledy otevřené';

  @override
  String get playerFullScreen => 'Celá obrazovka';

  @override
  String get playerExitFullScreen => 'Ukončit celou obrazovku';

  @override
  String get playerExpandControls => 'Zobrazit ovládání přehrávání';

  @override
  String get playerCollapseControls => 'Skrýt ovládání přehrávání';

  @override
  String get settingsShowSections => 'Zobrazovat nadpisy částí';

  @override
  String get settingsShowSectionsHint =>
      'Zobrazovat v textu nadpisy slok, refrénu a dalších částí.';

  @override
  String get settingsShowPlayerControls => 'Zobrazit ovládání přehrávání';

  @override
  String get settingsShowPlayerControlsHint =>
      'Panel přehrávače můžete také zobrazit nebo skrýt klepnutím či přejetím.';
}
