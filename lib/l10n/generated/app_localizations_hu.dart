// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Nyugodt hely, ahol megtalálhatod, rendszerezheted és énekelheted a dalaidat.';

  @override
  String get aboutMadeForSinging => 'Közös énekléshez készült';

  @override
  String get aboutDetails =>
      'Keress az engedélyezett forrásokban, hasonlítsd össze a változatokat, tartsd együtt a dalszöveget és az akkordokat, és rendezd a dalokat listákba. A könyvtár ezen az eszközön tárolódik; a választható Google Drive-szinkronizálás a Google-fiókodat használja. A keresések közvetlenül az engedélyezett forrásokhoz kerülnek.';

  @override
  String get aboutSupport => 'Támogatás és visszajelzés';

  @override
  String get menuTypeNewSong => 'Új dal beírása';

  @override
  String appVersion(String version) {
    return 'Verzió: $version';
  }

  @override
  String get navHome => 'Kezdőlap';

  @override
  String get navSongs => 'Dalok';

  @override
  String get navSetlists => 'Setlisták';

  @override
  String get navSettings => 'Beállítások';

  @override
  String get navSettingsCompact => 'Beállítások';

  @override
  String get navSearch => 'Keresés';

  @override
  String get navBack => 'Vissza';

  @override
  String get appExitBackAgain => 'A kilépéshez nyomja meg újra a Vissza gombot';

  @override
  String get navClose => 'Bezárás';

  @override
  String get navMore => 'További műveletek';

  @override
  String get actionCancel => 'Mégse';

  @override
  String get actionSave => 'Mentés';

  @override
  String get actionDone => 'Kész';

  @override
  String get actionEdit => 'Szerkesztés';

  @override
  String get actionDelete => 'Törlés';

  @override
  String get actionShare => 'Megosztás';

  @override
  String get actionPrint => 'Nyomtatás';

  @override
  String get actionCopy => 'Másolás';

  @override
  String get actionClear => 'Törlés';

  @override
  String get actionRetry => 'Újra';

  @override
  String get actionRefresh => 'Frissítés';

  @override
  String get actionImport => 'Importálás';

  @override
  String get actionExport => 'Exportálás';

  @override
  String get actionExpand => 'Kibontás';

  @override
  String get actionCollapse => 'Összecsukás';

  @override
  String get actionAdd => 'Hozzáadás';

  @override
  String get actionCreate => 'Létrehozás';

  @override
  String get actionRemove => 'Eltávolítás';

  @override
  String get actionDuplicate => 'Másolat készítése';

  @override
  String get actionMoveUp => 'Mozgatás felfelé';

  @override
  String get actionMoveDown => 'Mozgatás lefelé';

  @override
  String get actionPrevious => 'Előző';

  @override
  String get actionNext => 'Következő';

  @override
  String get searchHint => 'Dalok, előadók vagy dalszövegek keresése';

  @override
  String get searchCatalogHint => 'Dal vagy előadó keresése';

  @override
  String get searchChangeSong => 'Dal módosítása';

  @override
  String get searchSelectedPreview => 'Kiválasztott előnézet';

  @override
  String get searchSubmit => 'Keresés';

  @override
  String get searchFilters => 'Keresési beállítások';

  @override
  String get searchFiltersShow => 'Keresési beállítások megjelenítése';

  @override
  String get searchFiltersHide => 'Keresési beállítások elrejtése';

  @override
  String get searchFilterArtist => 'Előadó';

  @override
  String get searchFilterTitle => 'Dal címe';

  @override
  String get searchFilterLyrics => 'Dalszöveg';

  @override
  String get searchFilterChords => 'Akkordokkal';

  @override
  String get searchFilterTimed => 'Időzített dalszöveg';

  @override
  String get searchFilterLanguage => 'Nyelv';

  @override
  String get searchFilterAll => 'Bármelyik';

  @override
  String get searchAutocompleteLabel => 'Javaslatok';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count találat',
      one: '1 találat',
      zero: 'Nincs találat',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Adj meg egy dalt, előadót vagy dalszövegrészletet a kereséshez.';

  @override
  String get searchCatalogEmptyQuery =>
      'Adj meg egy dalt vagy előadót a kereséshez.';

  @override
  String get searchNoResults => 'Nem található dal. Próbálj másképp keresni.';

  @override
  String get searchLoading => 'Dalok keresése…';

  @override
  String get searchError => 'A keresés nem fejeződött be.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Legutóbbi';

  @override
  String get searchFavoritesTab => 'Kedvencek';

  @override
  String get searchSuggested => 'Javasolt egyezés';

  @override
  String get searchAlternatives => 'További egyezések';

  @override
  String get searchCompare => 'Verziók összehasonlítása';

  @override
  String get searchChooseVersion => 'Verzió kiválasztása';

  @override
  String get searchFullPreview => 'Teljes előnézet';

  @override
  String get searchArrangementNotes => 'Hangszerelési megjegyzések';

  @override
  String get searchOpenLyrics => 'Dalszöveg megnyitása';

  @override
  String get searchContributions => 'Felhasznált források';

  @override
  String get searchVersionChecking => 'Verzió ellenőrzése…';

  @override
  String get searchVersionUnavailable =>
      'Ez a verzió nem használható. Válassz másik verziót.';

  @override
  String get searchPreviewUnavailable => 'Nem érhető el dalszöveg-előnézet.';

  @override
  String get searchSongMatch => 'Dal egyezése';

  @override
  String get searchRecordingMatch => 'Felvétel egyezése';

  @override
  String get searchMatchUnverified => 'A felvétel nincs ellenőrizve';

  @override
  String get searchMatchExact => 'Pontos felvételegyezés';

  @override
  String get searchMatchPossible => 'Lehetséges egyezés';

  @override
  String get searchAvailability => 'Elérhetőség';

  @override
  String get searchLyricsAvailable => 'Dalszöveg elérhető';

  @override
  String get searchLyricsUnavailable => 'Dalszöveg nem érhető el';

  @override
  String get searchChordsAvailable => 'Akkordok elérhetők';

  @override
  String get searchChordsUnavailable => 'Nincsenek akkordok';

  @override
  String get searchTimingAvailable => 'Időzítés elérhető';

  @override
  String get searchTimingUnavailable => 'Nincs időzítés';

  @override
  String get searchDurationUnknown => 'Ismeretlen időtartam';

  @override
  String searchRating(String rating) {
    return 'Értékelés: $rating';
  }

  @override
  String get searchSourceLabel => 'Forrás';

  @override
  String get searchMetadata => 'Dal adatai';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Előadó';

  @override
  String get searchYear => 'Év';

  @override
  String get searchLanguage => 'Nyelv';

  @override
  String get searchViewVersions => 'Verziók megtekintése';

  @override
  String get searchSaved => 'A dal mentve a könyvtáradba.';

  @override
  String get searchSaveOpenLyrics => 'Dalszöveg mentése és megnyitása';

  @override
  String get searchOtherResults => 'További találatok';

  @override
  String get searchSaveFailed => 'A dal mentése nem sikerült.';

  @override
  String get homeRecentSongs => 'Legutóbbi dalok';

  @override
  String get homeRecentlyPlayed => 'Nemrég lejátszott';

  @override
  String get homeFavorites => 'Kedvencek';

  @override
  String get homeHistory => 'Előzmények';

  @override
  String get homeHistoryClear => 'Előzmények törlése';

  @override
  String get homeHistoryCleared => 'Előzmények törölve.';

  @override
  String get homeHistoryEmpty => 'Itt jelennek meg a megnyitott dalok.';

  @override
  String get homeFavoritesEmpty =>
      'Itt jelennek meg a kedvenc dalaid és setlistáid.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elem megjelenítve',
      one: '1 elem megjelenítve',
      zero: '0 elem megjelenítve',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Itt jelennek meg a legutóbbi dalaid és setlistáid.';

  @override
  String get homeTimelineLabel => 'Előzmények idővonala';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Teljes előzmények';

  @override
  String get homeShowFavorites => 'Kedvencek megjelenítése';

  @override
  String get homeShowRecent => 'Legutóbbiak megjelenítése';

  @override
  String get songsTitle => 'Dalok';

  @override
  String get songsEmpty => 'Itt jelennek meg a dalaid.';

  @override
  String get songsEmptySearch => 'Egyik dal sem felel meg a keresésednek.';

  @override
  String get songsAdd => 'Dal hozzáadása';

  @override
  String get songsSortAlphabetical => 'Rendezés ábécésorrendben';

  @override
  String get songsAlphabetNavigation => 'Dalok indexe';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alkalommal',
      one: 'egyszer',
      zero: 'soha',
    );
    return 'Megnyitva $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Hozzáadás a kedvencekhez';

  @override
  String get songFavoriteRemove => 'Eltávolítás a kedvencekből';

  @override
  String get songMenuLabel => 'Dal műveletei';

  @override
  String get songInfo => 'Dal adatai';

  @override
  String get setlistMenuLabel => 'Setlista műveletei';

  @override
  String get songAddToSetlist => 'Hozzáadás a setlistához';

  @override
  String get songCopyChordPro => 'ChordPro másolása';

  @override
  String get songDeleteConfirmTitle => 'Törlöd a dalt?';

  @override
  String get songDeleteConfirmMessage =>
      'A dal eltávolításra kerül a könyvtáradból.';

  @override
  String get songDeleted => 'Dal törölve.';

  @override
  String get setlistsTitle => 'Setlisták';

  @override
  String get setlistsEmpty =>
      'Készíts setlistát a következő próbádhoz vagy fellépésedhez.';

  @override
  String get setlistsEmptySearch =>
      'Egyik setlista sem felel meg a keresésednek.';

  @override
  String get setlistCreate => 'Új setlista';

  @override
  String get setlistNameHint => 'Setlista neve';

  @override
  String get setlistNotes => 'Jegyzetek';

  @override
  String get setlistEntryOverride => 'A dalhoz tartozó hangnem és capo';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dal',
      one: '1 dal',
      zero: 'Nincs dal',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Legalább $duration';
  }

  @override
  String get setlistDurationUnknown => 'Ismeretlen időtartam';

  @override
  String setlistActivity(String date) {
    return 'Utolsó tevékenység: $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Létrehozva: $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Szerkesztve: $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Utoljára lejátszva: $date';
  }

  @override
  String get setlistSongsEmpty => 'Ez a setlista még nem tartalmaz dalokat.';

  @override
  String get setlistAddSongs => 'Dalok hozzáadása';

  @override
  String get setlistReorder => 'Dalok átrendezése';

  @override
  String setlistMoveSongUp(String song) {
    return '$song mozgatása felfelé';
  }

  @override
  String setlistMoveSongDown(String song) {
    return '$song mozgatása lefelé';
  }

  @override
  String setlistRemoveSong(String song) {
    return '$song eltávolítása a setlistáról';
  }

  @override
  String get setlistDuplicate => 'Setlista másolása';

  @override
  String get setlistFavoriteAdd => 'Setlista hozzáadása a kedvencekhez';

  @override
  String get setlistFavoriteRemove => 'Setlista eltávolítása a kedvencekből';

  @override
  String get setlistShare => 'Megosztás setlistafájlként';

  @override
  String get setlistSharePdf => 'Megosztás PDF-ként';

  @override
  String get setlistPrint => 'Nyomtatás';

  @override
  String get setlistDeleteConfirmTitle => 'Törlöd a setlistát?';

  @override
  String get setlistDeleteConfirmMessage =>
      'A setlista eltávolításra kerül. A könyvtáradban lévő dalok megmaradnak.';

  @override
  String get setlistDeleted => 'Setlista törölve.';

  @override
  String get readerTitle => 'Dalszövegek';

  @override
  String get readerNoLyrics => 'Még nincs dalszöveg hozzáadva.';

  @override
  String get readerShowChords => 'Akkordok megjelenítése';

  @override
  String get readerHideChords => 'Akkordok elrejtése';

  @override
  String get readerTranspose => 'Akkordok transzponálása';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count félhanggal',
      one: '1 félhanggal',
      zero: '0 félhanggal',
    );
    return 'Transzponálás $_temp0';
  }

  @override
  String get readerSaved => 'Mentve';

  @override
  String get readerEdit => 'Dalszöveg és adatok szerkesztése';

  @override
  String get playerPlay => 'Lejátszás';

  @override
  String get playerPause => 'Szünet';

  @override
  String get playerResume => 'Dalszöveg görgetésének folytatása';

  @override
  String get playerSeek => 'Lejátszási pozíció';

  @override
  String playerElapsed(String time) {
    return 'Eltelt idő: $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Hátralévő idő: $time';
  }

  @override
  String get playerTimingMode => 'Görgetési mód';

  @override
  String get playerTimedLyrics => 'Időzített dalszöveg';

  @override
  String get playerStartScroll => 'Automatikus görgetés indítása';

  @override
  String get playerEstimatedPace => 'Becsült tempó';

  @override
  String get playerScrollSpeed => 'Görgetési sebesség';

  @override
  String playerEstimatedDuration(String time) {
    return 'Becsült időtartam: $time';
  }

  @override
  String get playerLyricsOnly => 'Dalszöveg görgetése · hang nélkül';

  @override
  String get playerManualScroll => 'Kézi görgetés';

  @override
  String get playerTimingStatusReady =>
      'A dalszöveg a rendelkezésre álló időzítést követi.';

  @override
  String get playerTimingStatusEstimated =>
      'A görgetési sebesség a dal időtartama alapján becsült.';

  @override
  String get playerTimingStatusManual => 'Görgesd a dalszöveget kézzel.';

  @override
  String get playerTimingStatusUnavailable =>
      'Ehhez a dalhoz nem érhető el időzített görgetés.';

  @override
  String get playerDurationUnknown =>
      'Add meg a dal időtartamát a becsült görgetés használatához.';

  @override
  String get playerProgressLabel => 'Dal előrehaladása';

  @override
  String get playerCurrentSection => 'Jelenlegi rész';

  @override
  String get playerPreviousSection => 'Előző rész';

  @override
  String get playerNextSection => 'Következő rész';

  @override
  String get playerPreviousSectionSong =>
      'Előző rész · tartsd lenyomva az előző setlistadalhoz';

  @override
  String get playerNextSectionSong =>
      'Következő rész · tartsd lenyomva a következő setlistadalhoz';

  @override
  String get playerPreviousSong => 'Előző dal';

  @override
  String get playerNextSong => 'Következő dal';

  @override
  String get editorTitle => 'Dal szerkesztése';

  @override
  String get editorTitleField => 'Dal címe';

  @override
  String get editorArtistField => 'Előadó';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Dalszöveg';

  @override
  String get editorChordsField => 'Akkordok';

  @override
  String get editorKeyField => 'Hangnem';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Hangolás';

  @override
  String get editorTempoField => 'Tempó';

  @override
  String get editorDurationField => 'Időtartam';

  @override
  String get editorTimeSignatureField => 'Ütemmutató';

  @override
  String get editorLanguageField => 'Nyelv';

  @override
  String get editorYearField => 'Év';

  @override
  String get editorComposerField => 'Zeneszerző';

  @override
  String get editorLyricistField => 'Dalszövegíró';

  @override
  String get editorCopyrightField => 'Szerzői jog';

  @override
  String get editorLicenseField => 'Licenc';

  @override
  String get songInfoSources => 'Források és közreműködők';

  @override
  String get searchMatchSameSong =>
      'Ugyanaz a dal; a felvétel nincs megerősítve';

  @override
  String get searchMatchNeedsAgreement =>
      'A dalszöveget össze kell vetni a kottával';

  @override
  String get searchMatchDifferentLyrics =>
      'A dalszöveg eltér a kiválasztott dalétól';

  @override
  String get searchMatchCombinedSources =>
      'Több forrásból összeállított adatok';

  @override
  String get searchCombinedLabel => 'Összes';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dalegyezés',
      one: '1 dalegyezés',
      zero: '0 dalegyezés',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count forrásverzió',
      one: '1 forrásverzió',
      zero: '0 forrásverzió',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Legjobb elérhető egyezés';

  @override
  String get providerDescriptionUnknown => 'Dal forrása';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Tölts le egy ChordPro-fájlt a forrásból, majd importáld.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Töltsd le a fájlt ingyenes fiókkal, majd importáld.';

  @override
  String get providerDescPublicChordSheets => 'Nyilvános akkordlapok.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Történelmi dalszövegek művenkénti licenccel.';

  @override
  String get providerDescLicensedCatalog => 'Licencelt dalszövegkatalógus.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Eredeti dalok Creative Commons BY licenccel.';

  @override
  String get providerDescPerSongLicense => 'Dalszövegek dalonkénti licenccel.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Csak a felvétel és a kiadás adatai.';

  @override
  String get providerDescCompositionMetadataOnly => 'Csak a zenemű adatai.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Borítók csak pontos felvételegyezés esetén.';

  @override
  String get providerCapabilityLyrics => 'Dalszöveg';

  @override
  String get providerCapabilityChords => 'Akkordok';

  @override
  String get providerCapabilityTiming => 'Időzített dalszöveg';

  @override
  String get providerCapabilitySearch => 'Keresés';

  @override
  String get providerCapabilityMetadata => 'Dal adatai';

  @override
  String get editorArtworkField => 'Borító hivatkozása';

  @override
  String get editorLyricsHint =>
      'Koppints egy sorra a dalszöveg vagy az akkordok szerkesztéséhez.';

  @override
  String get editorSave => 'Módosítások mentése';

  @override
  String get editorSaved => 'Módosítások mentve.';

  @override
  String get editorSaveFailed => 'A módosításokat nem sikerült menteni.';

  @override
  String get editorSaveConflict =>
      'A dalt máshol módosították. A módosításaid külön másolatként lettek mentve.';

  @override
  String get editorUnsavedTitle => 'Elveted a módosításokat?';

  @override
  String get editorUnsavedMessage => 'A módosításaid nincsenek mentve.';

  @override
  String get editorFieldRequired => 'Add meg a dal címét.';

  @override
  String get settingsTitle => 'Beállítások';

  @override
  String get settingsAppearance => 'Megjelenés';

  @override
  String get settingsTheme => 'Téma';

  @override
  String get settingsThemeSystem => 'Eszközbeállítás használata';

  @override
  String get settingsThemeLight => 'Világos';

  @override
  String get settingsThemeDark => 'Sötét';

  @override
  String get settingsColorPalette => 'Színpaletta';

  @override
  String get settingsFont => 'Betűtípus';

  @override
  String get settingsTextSize => 'Szövegméret';

  @override
  String get settingsLyricsPreview => 'Dalszöveg előnézete';

  @override
  String get settingsPlayer => 'Dalszöveg-lejátszó';

  @override
  String get settingsDefaultShowChords =>
      'Akkordok megjelenítése alapértelmezés szerint';

  @override
  String get settingsDefaultAutoscroll => 'Dalszöveg automatikus görgetése';

  @override
  String get settingsDefaultTiming => 'Alapértelmezett görgetési mód';

  @override
  String get settingsLanguage => 'Alkalmazás nyelve';

  @override
  String get settingsLanguageSystem => 'Eszköz nyelvének használata';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Dalszövegforrások';

  @override
  String settingsSourceEnabled(String source) {
    return 'A(z) $source forrás engedélyezése';
  }

  @override
  String get settingsSourceRefresh => 'Forráslista frissítése';

  @override
  String get settingsSourcesUpdated => 'Források frissítve.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Nem sikerült frissíteni a forrásokat.';

  @override
  String get settingsImport => 'Dalok importálása';

  @override
  String get settingsImportChordPro => 'ChordPro-fájl importálása';

  @override
  String get settingsImportSetlist => 'Setlistafájl importálása';

  @override
  String get settingsImportSuccess => 'Importálás kész.';

  @override
  String get settingsImportFailed => 'A fájl importálása nem sikerült.';

  @override
  String get settingsImportUnsupported => 'Ez a fájltípus nem támogatott.';

  @override
  String get settingsShareSong => 'Megosztás ChordPro-ként';

  @override
  String get settingsSharePdf => 'Megosztás PDF-ként';

  @override
  String get settingsCopySong => 'Másolás a vágólapra';

  @override
  String get settingsPrintSong => 'Csak a dal nyomtatása';

  @override
  String get settingsPrintSetlist => 'Setlista nyomtatása dalszövegekkel';

  @override
  String get settingsExportFailed => 'Nem sikerült előkészíteni a fájlt.';

  @override
  String get settingsCopied => 'Vágólapra másolva.';

  @override
  String get settingsAbout => 'Névjegy';

  @override
  String get settingsPrivacy => 'Adatvédelem';

  @override
  String get settingsLegal => 'Jogi információk';

  @override
  String get settingsClearHistory => 'Előzmények törlése';

  @override
  String get settingsClearHistoryConfirm =>
      'Törlöd a dalok és setlisták előzményeit?';

  @override
  String get settingsHistoryCleared => 'Előzmények törölve.';

  @override
  String get accountTitle => 'Fiók és szinkronizálás';

  @override
  String get accountUnavailable =>
      'A szinkronizáláshoz olyan Singbook-verzió szükséges, amelyben be van állítva a Google-bejelentkezés. Ez a verzió csak ezen az eszközön tárolja a dalokat.';

  @override
  String get accountSyncNow => 'Szinkronizálás most';

  @override
  String get accountConnected =>
      'Csatlakoztatva. A biztonsági mentés frissítéséhez válaszd a Szinkronizálás most lehetőséget.';

  @override
  String get accountSignIn => 'Fiók csatlakoztatása';

  @override
  String get accountSignOut => 'Kijelentkezés';

  @override
  String get accountChange => 'Fiókváltás';

  @override
  String get accountSignedOut => 'Nincs csatlakoztatva';

  @override
  String get accountSyncing => 'A könyvtár szinkronizálása…';

  @override
  String get accountSynced => 'Könyvtár szinkronizálva.';

  @override
  String get accountSyncFailed => 'Nem sikerült szinkronizálni a könyvtárat.';

  @override
  String get accessibilityFavorite => 'Kedvenc';

  @override
  String get accessibilityNotFavorite => 'Nem kedvenc';

  @override
  String get accessibilitySearchField => 'Dalok keresése';

  @override
  String get accessibilityClearSearch => 'Keresési szöveg törlése';

  @override
  String accessibilitySongMenu(String song) {
    return 'Műveletek ehhez: $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Műveletek ehhez: $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'A(z) $setlist dalainak kibontása';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'A(z) $setlist dalainak összecsukása';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Lejátszás előrehaladása, $percent százalék';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Előzmények idővonala, $date';
  }

  @override
  String get loading => 'Betöltés…';

  @override
  String get loadingSongs => 'Dalok betöltése…';

  @override
  String get loadingSetlists => 'Setlisták betöltése…';

  @override
  String get errorGeneric => 'Hiba történt.';

  @override
  String get errorOffline => 'Úgy tűnik, nincs internetkapcsolat.';

  @override
  String get errorPermission => 'A folytatáshoz engedély szükséges.';

  @override
  String get emptyFiltered =>
      'Egyetlen elem sem felel meg ezeknek a szűrőknek.';

  @override
  String get unknownValue => 'Ismeretlen';

  @override
  String get durationUnknown => 'Ismeretlen időtartam';

  @override
  String get metadataNotSet => 'Nincs megadva';

  @override
  String get dateToday => 'Ma';

  @override
  String get dateYesterday => 'Tegnap';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dal',
      one: '1 dal',
      zero: 'Nincs dal',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Sötétkék';

  @override
  String get settingsPaletteSage => 'Zsályazöld';

  @override
  String get settingsPaletteOcean => 'Óceán';

  @override
  String get settingsPaletteClay => 'Agyag';

  @override
  String get settingsPalettePlum => 'Szilva';

  @override
  String get settingsFontSystem => 'Rendszer';

  @override
  String get settingsFontSerif => 'Talpas';

  @override
  String get settingsFontMonospace => 'Rögzített szélességű';

  @override
  String get settingsLyricsPreviewExample =>
      'Amikor eljön a reggel, újra énekelni fogunk.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Dalszövegforrások ellenőrzése: $checked/$total kész.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Nem található használható dalszöveg.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'A kiválasztott dalt ellenőriztük az engedélyezett forrásokban, de egyik sem adott vissza használható dalszövegverziót.';

  @override
  String get searchDiscoveryError =>
      'Nem sikerült ellenőrizni a dalszövegforrásokat.';

  @override
  String get searchDiscoveryRetry => 'Dalszövegkeresés újra';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count forrás nem érhető el',
      one: '1 forrás nem érhető el',
      zero: '0 forrás nem érhető el',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails =>
      'Ellenőrizd a kapcsolatot, majd próbáld újra.';

  @override
  String get searchProviderChecks => 'Forrásellenőrzések';

  @override
  String get searchProviderPending => 'Ellenőrzés';

  @override
  String get searchProviderFound => 'Egyezés található';

  @override
  String get searchProviderRejected => 'Nem egyezik';

  @override
  String get searchProviderFailed => 'Az ellenőrzés nem sikerült';

  @override
  String get searchProviderUnavailable => 'Nincs használható dalszöveg';

  @override
  String get searchCatalogFilterHint =>
      'Válassz dalt a dalszövegverziók akkord, időzítés vagy nyelv szerinti szűréséhez.';

  @override
  String get startupErrorTitle => 'Nem sikerült megnyitni a könyvtáradat.';

  @override
  String setlistCopyName(String name) {
    return '$name másolata';
  }

  @override
  String get setlistSongMissing => 'Hiányzó dal';

  @override
  String get settingsImportTooLarge => 'Ez a fájl túl nagy az importáláshoz.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Ugrás ide: $letter';
  }

  @override
  String get actionDiscard => 'Elvetés';

  @override
  String get editorKeepEditing => 'Szerkesztés folytatása';

  @override
  String get settingsDefaultShowChordsHint =>
      'Akkordok megjelenítése a dalszöveg felett, ha a dalhoz tartoznak akkordok.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'A dalszöveg a dallal együtt görget. Kézi görgetési módban nincs használatban.';

  @override
  String get accountUnavailableTitle => 'A szinkronizálás nincs beállítva';

  @override
  String get accountSignedOutBenefits =>
      'A Google Drive csatlakoztatásakor szinkronizálódik a könyvtárad. Ezután a dalok módosításai automatikusan szinkronizálódnak.';

  @override
  String get accountManualSyncHint =>
      'A könyvtár szinkronizálásához a Szinkronizálás most gombra is koppinthatsz.';

  @override
  String get accountSignInWithGoogle => 'Bejelentkezés Google-fiókkal';

  @override
  String get accountWorking => 'Folyamatban…';

  @override
  String get accountNeverSynced => 'Még soha nem szinkronizált';

  @override
  String get accountSyncedJustNow => 'Épp most szinkronizálva';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perce szinkronizálva',
      one: '1 perce szinkronizálva',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count órája szinkronizálva',
      one: '1 órája szinkronizálva',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count napja szinkronizálva',
      one: '1 napja szinkronizálva',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ütköző módosítás másolatként megőrizve',
      one: '1 ütköző módosítás másolatként megőrizve',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Ugyanazt a dalt vagy setlistát két helyen módosították. Semmi sem veszett el: a másik verzió külön másolatként lett mentve.';

  @override
  String get accountReviewConflicts => 'Másolatok áttekintése';

  @override
  String get songsConflictFilterActive => 'Csak az ütköző másolatok láthatók';

  @override
  String get songsConflictFilterClear => 'Összes dal megjelenítése';

  @override
  String get songsConflictBadge => 'Ütköző másolat';

  @override
  String get songsConflictEmpty => 'Nincsenek ütköző másolatok.';

  @override
  String get accountAutoSync => 'Automatikus szinkronizálás';

  @override
  String get accountAutoSyncHint =>
      'A szinkronizálás csatlakozás után, valamint dal hozzáadása, szerkesztése vagy törlése után történik.';

  @override
  String get accountSignOutTitle => 'Kijelentkezel ebből a fiókból?';

  @override
  String get accountSignOutBody =>
      'A dalaid és setlistáid ezen az eszközön maradnak. Nem készül róluk biztonsági mentés, és nem szinkronizálódnak, amíg újra be nem jelentkezel.';

  @override
  String get accountUseDifferent => 'Másik fiók használata';

  @override
  String get accountSignInAgain => 'Bejelentkezés újra';

  @override
  String get accountChooseAction => 'Válaszd ki, hogyan folytatod';

  @override
  String get accountChangedTitle => 'Másik Google-fiók';

  @override
  String get accountChangedBody =>
      'Ezt az eszközt legutóbb egy másik Google-fiókkal szinkronizálták. Válaszd ki, mi történjen az eszközön lévő dalokkal és setlistákkal.';

  @override
  String get accountChangedMerge => 'Egyesítés az új fiókkal';

  @override
  String get accountChangedMergeHint =>
      'Tarts meg mindent ezen az eszközön, és add hozzá az új fiókhoz.';

  @override
  String get accountChangedReplace => 'Csere az új fiók könyvtárára';

  @override
  String get accountChangedReplaceHint =>
      'Az eszközről törlődnek azok a dalok, amelyek nincsenek meg az új fiókban.';

  @override
  String get accountChangedSignOut => 'Mégse és kijelentkezés';

  @override
  String get accountStatusSignedOut =>
      'Fiók és szinkronizálás: nincs bejelentkezve';

  @override
  String get accountStatusSignedIn => 'Fiók és szinkronizálás: bejelentkezve';

  @override
  String get accountStatusSyncing =>
      'Fiók és szinkronizálás: szinkronizálás folyamatban';

  @override
  String get accountStatusSynced =>
      'Fiók és szinkronizálás: a könyvtár naprakész';

  @override
  String get accountStatusError =>
      'Fiók és szinkronizálás: probléma, koppints az áttekintéshez';

  @override
  String get accountNoticeConflicts =>
      'Néhány dalt két helyen módosítottak. A másolatok megmaradtak.';

  @override
  String get accountNoticeSignedIn => 'Bejelentkezve.';

  @override
  String get accountNoticeSignedOut =>
      'Kijelentkezve. A dalaid ezen az eszközön maradnak.';

  @override
  String get syncErrorNotConfigured =>
      'Ebben a verzióban nincs beállítva a szinkronizálás.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Használj olyan Singbook-verziót, amelyben be van állítva a Google-bejelentkezés.';

  @override
  String get syncErrorNotSignedIn => 'Nincs bejelentkezve.';

  @override
  String get syncErrorNotSignedInHint =>
      'Jelentkezz be a könyvtár szinkronizálásához.';

  @override
  String get syncErrorAuthorizationRequired =>
      'A Google kéri, hogy jelentkezz be újra.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'A szinkronizálás folytatásához jelentkezz be újra. A dalaid biztonságban vannak ezen az eszközön.';

  @override
  String get syncErrorAccessDenied =>
      'A Singbook nem kapott engedélyt a Google Drive használatához.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Jelentkezz be újra, és engedélyezd a Drive-hozzáférést, amikor a rendszer kéri.';

  @override
  String get syncErrorRateLimited =>
      'A Google jelenleg korlátozza a kéréseket.';

  @override
  String get syncErrorRateLimitedHint =>
      'Várj néhány percet, majd próbáld újra.';

  @override
  String get syncErrorStorageFull => 'Megtelt a Google Drive.';

  @override
  String get syncErrorStorageFullHint =>
      'Szabadíts fel helyet a Drive-on, majd próbáld újra.';

  @override
  String get syncErrorNetwork => 'Nem sikerült elérni a Google-t.';

  @override
  String get syncErrorNetworkHint =>
      'Ellenőrizd az internetkapcsolatot, majd próbáld újra.';

  @override
  String get syncErrorAccountChanged => 'Másik Google-fiókot használtak.';

  @override
  String get syncErrorAccountChangedHint =>
      'Válaszd ki, hogy egyesíted-e az eszköz könyvtárát a fiókéval, vagy lecseréled.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'A szinkronizált könyvtárad nagyobb annál, mint amit a Singbook kezelni tud.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Távolíts el néhány dalt vagy setlistát a szinkronizált könyvtárból, majd próbáld újra.';

  @override
  String get syncErrorSignInFailed => 'A bejelentkezés nem fejeződött be.';

  @override
  String get syncErrorSignInFailedHint => 'Próbálj meg újra bejelentkezni.';

  @override
  String get syncErrorGeneric => 'Nem sikerült szinkronizálni a könyvtáradat.';

  @override
  String get syncErrorGenericHint =>
      'Próbáld újra egy kicsit később. A dalaid továbbra is biztonságban vannak ezen az eszközön.';

  @override
  String get editorDurationInvalid =>
      'Adj meg másodperceket, vagy perceket és másodperceket, például 3:45.';

  @override
  String get editorNumberInvalid => 'Adj meg egy számot.';

  @override
  String get accountReplaceConfirmTitle => 'Törlöd a helyi dalokat?';

  @override
  String get accountReplaceConfirmBody =>
      'Az ezen az eszközön lévő, az új fiókban nem szereplő dalok és setlisták véglegesen törlődnek. Ez nem vonható vissza.';

  @override
  String get accountReplaceConfirmAction => 'Törlés és csere';

  @override
  String get accountSuspiciousTitle => 'Hiányzó elemek a Google Drive-ban';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elem, amelyet ez az eszköz korábban szinkronizált, hiányzik a Google Drive-ból.',
      one:
          '$count elem, amelyet ez az eszköz korábban szinkronizált, hiányzik a Google Drive-ból.',
    );
    return '$_temp0 Ez akkor fordulhat elő, ha a Google beállításaiban törölték az alkalmazás adatait. Még semmi sem lett törölve.';
  }

  @override
  String get accountSuspiciousDelete => 'Töröld őket itt is';

  @override
  String get accountSuspiciousKeep =>
      'Tartsd meg a dalaimat, és töltsd fel őket újra';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Törlöd erről az eszközről: $count elem?',
      one: 'Törlöd erről az eszközről: $count elem?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Ezek a dalok és setlisták véglegesen törlődnek erről az eszközről. Ez nem vonható vissza.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Törlés erről az eszközről';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Hiányzó elemek a Google Drive-ban.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Semmi sem lett törölve. Válaszd ki, hogy itt is törlöd őket, vagy újra feltöltöd.';

  @override
  String get syncErrorRemoteChanged =>
      'Szinkronizálás közben megváltozott a Google Drive.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Semmi sem veszett el. Szinkronizálj újra a legújabb változásokért.';

  @override
  String get syncErrorInvalidLocalData =>
      'Az eszközön lévő adatok egy része nem szinkronizálható.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Egy dal vagy setlista nem olvasható. Importáld vagy hozd létre újra, majd szinkronizálj.';

  @override
  String get syncErrorNoAccountChange => 'Nincs megoldandó fiókváltás.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'A folytatáshoz szinkronizálj újra.';

  @override
  String get accountSyncWarningTitle =>
      'Szinkronizálva, de néhány fájl kimaradt';

  @override
  String get accountSyncWarningBody =>
      'Néhány fájlt nem lehetett használni, ezért változatlanul maradtak. Minden más naprakész.';

  @override
  String get accountSyncWarningTooLarge =>
      'Egy fájl túl nagy volt a szinkronizáláshoz, ezért kimaradt. Minden más naprakész.';

  @override
  String get accountSyncWarningInvalid =>
      'Egy fájlt nem lehetett beolvasni, ezért kimaradt. Minden más naprakész.';

  @override
  String get accountNoticeSyncSkipped =>
      'Szinkronizálva. Néhány fájl kimaradt.';

  @override
  String get settingsExportPdfTooLarge =>
      'Ez a PDF túl nagy lenne. Próbálj kevesebb dalt választani, vagy oszd meg szövegként.';

  @override
  String get settingsTimingTooLarge =>
      'Az időzítési adatok túl nagyok (több mint 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'A biztonsági mentés kétszer tartalmazza ugyanazt a dalt, ezért nem történt importálás.';

  @override
  String get setlistSaveConflict =>
      'A setlista máshol megváltozott. A módosításaid külön másolatként lettek mentve.';

  @override
  String get sectionVerse => 'Verszak';

  @override
  String get sectionChorus => 'Refrén';

  @override
  String get sectionBridge => 'Híd';

  @override
  String get sectionIntro => 'Intró';

  @override
  String get sectionOutro => 'Outró';

  @override
  String get sectionPreChorus => 'Előrefrén';

  @override
  String get sectionPostChorus => 'Utórefrén';

  @override
  String get sectionInstrumental => 'Instrumentális';

  @override
  String get sectionInterlude => 'Közjáték';

  @override
  String get sectionSolo => 'Szóló';

  @override
  String get sectionRefrain => 'Refrén';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Kóda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Befejezés';

  @override
  String get youtubeConsentHint =>
      'Kísérleti funkció. A dalszövegkeresés kipróbálásához válaszd ki a cookie-beállításokat a Google oldalán. Nem kell bejelentkezned Google-fiókba. A választásod ezen az eszközön marad.';

  @override
  String get youtubeConsentOpen => 'Google-hozzájárulás áttekintése';

  @override
  String get youtubeConsentSaved => 'Hozzájárulás mentve';

  @override
  String get youtubeConsentClear => 'Hozzájárulás törlése';

  @override
  String get youtubeConsentInstructions =>
      'Fejezd be a cookie-választást, és várd meg, amíg visszatér a YouTube Music. Ezután mentsd ezt a munkamenetet, és keresd meg újra a dalt.';

  @override
  String get youtubeConsentError =>
      'Nem sikerült frissíteni a Google-hozzájárulási választást. Próbáld újra.';

  @override
  String get youtubeConsentBlocked =>
      'Itt csak a YouTube Music és a Google hozzájárulási oldala nyitható meg. A fiókba való bejelentkezés nem érhető el.';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elérhető verziók',
      one: '1 elérhető verzió',
      zero: '0 Elérhető verziók',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nem elérhető verziók',
      one: '1 nem elérhető verzió',
      zero: '0 Nem elérhető verziók',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Ugrás a szakaszhoz';

  @override
  String get searchVersionDetails => 'Verzió részletei';

  @override
  String get searchSelectedRecording => 'Kiválasztott felvétel';

  @override
  String get searchVersionDuration => 'Verzió hossza';

  @override
  String get searchSourceOptions => 'Forrásbeállítások';
}
