// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Mirno mjesto za pronalaženje, organiziranje i zajedničko pjevanje uz vašu zbirku pjesama.';

  @override
  String get aboutMadeForSinging => 'Stvoreno za zajedničko pjevanje';

  @override
  String appVersion(String version) {
    return 'Verzija $version';
  }

  @override
  String get navHome => 'Početna';

  @override
  String get navSongs => 'Pjesme';

  @override
  String get navSetlists => 'Setliste';

  @override
  String get navSettings => 'Postavke';

  @override
  String get navSettingsCompact => 'Postavke';

  @override
  String get navSearch => 'Pretraživanje';

  @override
  String get navBack => 'Natrag';

  @override
  String get navClose => 'Zatvori';

  @override
  String get navMore => 'Više radnji';

  @override
  String get actionCancel => 'Odustani';

  @override
  String get actionSave => 'Spremi';

  @override
  String get actionDone => 'Gotovo';

  @override
  String get actionEdit => 'Uredi';

  @override
  String get actionDelete => 'Izbriši';

  @override
  String get actionShare => 'Podijeli';

  @override
  String get actionPrint => 'Ispis';

  @override
  String get actionCopy => 'Kopiraj';

  @override
  String get actionClear => 'Očisti';

  @override
  String get actionRetry => 'Pokušaj ponovno';

  @override
  String get actionRefresh => 'Osvježi';

  @override
  String get actionImport => 'Uvezi';

  @override
  String get actionExport => 'Izvezi';

  @override
  String get actionExpand => 'Proširi';

  @override
  String get actionCollapse => 'Sažmi';

  @override
  String get actionAdd => 'Dodaj';

  @override
  String get actionCreate => 'Stvori';

  @override
  String get actionRemove => 'Ukloni';

  @override
  String get actionDuplicate => 'Dupliciraj';

  @override
  String get actionMoveUp => 'Pomakni gore';

  @override
  String get actionMoveDown => 'Pomakni dolje';

  @override
  String get actionPrevious => 'Prethodno';

  @override
  String get actionNext => 'Sljedeće';

  @override
  String get searchHint => 'Pretražite pjesme, izvođače ili tekstove pjesama';

  @override
  String get searchCatalogHint => 'Pretražite pjesmu ili izvođača';

  @override
  String get searchSubmit => 'Pretraži';

  @override
  String get searchFilters => 'Mogućnosti pretraživanja';

  @override
  String get searchFiltersShow => 'Prikaži mogućnosti pretraživanja';

  @override
  String get searchFiltersHide => 'Sakrij mogućnosti pretraživanja';

  @override
  String get searchFilterArtist => 'Izvođač';

  @override
  String get searchFilterTitle => 'Naslov pjesme';

  @override
  String get searchFilterLyrics => 'Tekstovi pjesama';

  @override
  String get searchFilterChords => 'Ima akorde';

  @override
  String get searchFilterTimed => 'Vremenski usklađeni tekstovi';

  @override
  String get searchFilterLanguage => 'Jezik';

  @override
  String get searchFilterAll => 'Bilo koji';

  @override
  String get searchAutocompleteLabel => 'Prijedlozi';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rezultata',
      few: '$count rezultata',
      one: '$count rezultat',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Unesite pjesmu, izvođača ili stih za pretraživanje.';

  @override
  String get searchCatalogEmptyQuery =>
      'Unesite pjesmu ili izvođača za pretraživanje.';

  @override
  String get searchNoResults =>
      'Nisu pronađene pjesme. Pokušajte drukčije pretraživati.';

  @override
  String get searchLoading => 'Pretraživanje pjesama…';

  @override
  String get searchError => 'Pretraživanje nije uspjelo.';

  @override
  String get searchOnlineTab => 'Na internetu';

  @override
  String get searchRecentTab => 'Nedavno';

  @override
  String get searchFavoritesTab => 'Favoriti';

  @override
  String get searchSuggested => 'Predloženo podudaranje';

  @override
  String get searchAlternatives => 'Ostala podudaranja';

  @override
  String get searchCompare => 'Usporedi verzije';

  @override
  String get searchChooseVersion => 'Odaberi ovu verziju';

  @override
  String get searchSongMatch => 'Podudaranje pjesme';

  @override
  String get searchRecordingMatch => 'Podudaranje snimke';

  @override
  String get searchMatchUnverified => 'Snimka nije provjerena';

  @override
  String get searchMatchExact => 'Točno podudaranje snimke';

  @override
  String get searchMatchPossible => 'Moguće podudaranje';

  @override
  String get searchAvailability => 'Dostupnost';

  @override
  String get searchLyricsAvailable => 'Tekst je dostupan';

  @override
  String get searchLyricsUnavailable => 'Tekst nije dostupan';

  @override
  String get searchChordsAvailable => 'Akordi su dostupni';

  @override
  String get searchChordsUnavailable => 'Nema akorda';

  @override
  String get searchTimingAvailable => 'Vremensko usklađivanje dostupno';

  @override
  String get searchTimingUnavailable => 'Nema vremenskog usklađivanja';

  @override
  String get searchDurationUnknown => 'Trajanje nije poznato';

  @override
  String searchRating(String rating) {
    return 'Ocjena $rating';
  }

  @override
  String get searchSourceLabel => 'Izvor';

  @override
  String get searchMetadata => 'Pojedinosti o pjesmi';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Izvođač';

  @override
  String get searchYear => 'Godina';

  @override
  String get searchLanguage => 'Jezik';

  @override
  String get searchSaved => 'Pjesma je spremljena u vašu zbirku.';

  @override
  String get searchSaveFailed => 'Pjesmu nije bilo moguće spremiti.';

  @override
  String get homeRecentSongs => 'Nedavne pjesme';

  @override
  String get homeRecentlyPlayed => 'Nedavno reproducirano';

  @override
  String get homeFavorites => 'Favoriti';

  @override
  String get homeHistory => 'Povijest';

  @override
  String get homeHistoryClear => 'Izbriši povijest';

  @override
  String get homeHistoryCleared => 'Povijest je izbrisana.';

  @override
  String get homeHistoryEmpty => 'Ovdje će se prikazati pjesme koje otvorite.';

  @override
  String get homeFavoritesEmpty =>
      'Ovdje će se prikazati vaše omiljene pjesme i setliste.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prikazano $count stavki',
      few: 'Prikazane $count stavke',
      one: 'Prikazana $count stavka',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Ovdje će se prikazati vaše nedavne pjesme i setliste.';

  @override
  String get homeTimelineLabel => 'Vremenska crta povijesti';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Cijela povijest';

  @override
  String get homeShowFavorites => 'Prikaži favorite';

  @override
  String get homeShowRecent => 'Prikaži nedavne';

  @override
  String get songsTitle => 'Pjesme';

  @override
  String get songsEmpty => 'Ovdje će se prikazati vaše pjesme.';

  @override
  String get songsEmptySearch => 'Nijedna pjesma ne odgovara pretraživanju.';

  @override
  String get songsAdd => 'Dodaj pjesmu';

  @override
  String get songsSortAlphabetical => 'Poredaj abecedno';

  @override
  String get songsAlphabetNavigation => 'Kazalo pjesama';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puta',
      few: '$count puta',
      one: '$count put',
    );
    return 'Otvoreno $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Dodaj u favorite';

  @override
  String get songFavoriteRemove => 'Ukloni iz favorita';

  @override
  String get songMenuLabel => 'Radnje za pjesmu';

  @override
  String get songInfo => 'Pojedinosti o pjesmi';

  @override
  String get setlistMenuLabel => 'Radnje za setlistu';

  @override
  String get songAddToSetlist => 'Dodaj u setlistu';

  @override
  String get songCopyChordPro => 'Kopiraj ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Izbrisati pjesmu?';

  @override
  String get songDeleteConfirmMessage =>
      'Pjesma će biti uklonjena iz vaše zbirke.';

  @override
  String get songDeleted => 'Pjesma je izbrisana.';

  @override
  String get setlistsTitle => 'Setliste';

  @override
  String get setlistsEmpty => 'Stvorite setlistu za sljedeću probu ili nastup.';

  @override
  String get setlistsEmptySearch =>
      'Nijedna setlista ne odgovara pretraživanju.';

  @override
  String get setlistCreate => 'Nova setlista';

  @override
  String get setlistNameHint => 'Naziv setliste';

  @override
  String get setlistNotes => 'Bilješke';

  @override
  String get setlistEntryOverride => 'Tonalitet i kapodaster za ovu pjesmu';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pjesama',
      few: '$count pjesme',
      one: '$count pjesma',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Najmanje $duration';
  }

  @override
  String get setlistDurationUnknown => 'Trajanje nije poznato';

  @override
  String setlistActivity(String date) {
    return 'Posljednja aktivnost $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Stvoreno $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Uređeno $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Posljednji put svirano $date';
  }

  @override
  String get setlistSongsEmpty => 'Ova setlista još nema pjesama.';

  @override
  String get setlistAddSongs => 'Dodaj pjesme';

  @override
  String get setlistReorder => 'Promijeni redoslijed pjesama';

  @override
  String setlistMoveSongUp(String song) {
    return 'Pomakni pjesmu $song gore';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Pomakni pjesmu $song dolje';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Ukloni pjesmu $song iz setliste';
  }

  @override
  String get setlistDuplicate => 'Dupliciraj setlistu';

  @override
  String get setlistFavoriteAdd => 'Dodaj setlistu u favorite';

  @override
  String get setlistFavoriteRemove => 'Ukloni setlistu iz favorita';

  @override
  String get setlistShare => 'Podijeli kao datoteku setliste';

  @override
  String get setlistSharePdf => 'Podijeli kao PDF';

  @override
  String get setlistPrint => 'Ispis';

  @override
  String get setlistDeleteConfirmTitle => 'Izbrisati setlistu?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Setlista će biti uklonjena. Pjesme u vašoj zbirci ostat će sačuvane.';

  @override
  String get setlistDeleted => 'Setlista je izbrisana.';

  @override
  String get readerTitle => 'Tekstovi pjesama';

  @override
  String get readerNoLyrics => 'Tekst još nije dodan.';

  @override
  String get readerShowChords => 'Prikaži akorde';

  @override
  String get readerHideChords => 'Sakrij akorde';

  @override
  String get readerTranspose => 'Transponiraj akorde';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count polutonova',
      few: '$count polutona',
      one: '$count poluton',
    );
    return 'Transponiraj za $_temp0';
  }

  @override
  String get readerEdit => 'Uredi tekst i pojedinosti';

  @override
  String get playerPlay => 'Pokreni pomicanje teksta';

  @override
  String get playerPause => 'Pauziraj pomicanje teksta';

  @override
  String get playerResume => 'Nastavi pomicanje teksta';

  @override
  String get playerSeek => 'Položaj reprodukcije';

  @override
  String playerElapsed(String time) {
    return 'Proteklo vrijeme $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Preostalo vrijeme $time';
  }

  @override
  String get playerTimingMode => 'Način pomicanja';

  @override
  String get playerTimedLyrics => 'Vremenski usklađeni tekst';

  @override
  String get playerEstimatedPace => 'Procijenjena brzina';

  @override
  String get playerManualScroll => 'Ručno pomicanje';

  @override
  String get playerTimingStatusReady =>
      'Tekst će pratiti dostupno vremensko usklađivanje.';

  @override
  String get playerTimingStatusEstimated =>
      'Brzina pomicanja procijenjena je prema trajanju pjesme.';

  @override
  String get playerTimingStatusManual => 'Pomaknite tekst ručno.';

  @override
  String get playerTimingStatusUnavailable =>
      'Vremenski usklađeno pomicanje nije dostupno za ovu pjesmu.';

  @override
  String get playerDurationUnknown =>
      'Dodajte trajanje pjesme da biste koristili procijenjeno pomicanje.';

  @override
  String get playerProgressLabel => 'Napredak pjesme';

  @override
  String get playerCurrentSection => 'Trenutačni dio';

  @override
  String get playerPreviousSection => 'Prethodni dio';

  @override
  String get playerNextSection => 'Sljedeći dio';

  @override
  String get playerPreviousSectionSong =>
      'Prethodni dio · držite za prethodnu pjesmu sa setliste';

  @override
  String get playerNextSectionSong =>
      'Sljedeći dio · držite za sljedeću pjesmu sa setliste';

  @override
  String get playerPreviousSong => 'Prethodna pjesma';

  @override
  String get playerNextSong => 'Sljedeća pjesma';

  @override
  String get editorTitle => 'Uredi pjesmu';

  @override
  String get editorTitleField => 'Naslov pjesme';

  @override
  String get editorArtistField => 'Izvođač';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Tekst pjesme';

  @override
  String get editorChordsField => 'Akordi';

  @override
  String get editorKeyField => 'Tonalitet';

  @override
  String get editorCapoField => 'Kapodaster';

  @override
  String get editorTuningField => 'Ugađanje';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Trajanje';

  @override
  String get editorTimeSignatureField => 'Metrum';

  @override
  String get editorLanguageField => 'Jezik';

  @override
  String get editorYearField => 'Godina';

  @override
  String get editorComposerField => 'Skladatelj';

  @override
  String get editorLyricistField => 'Tekstopisac';

  @override
  String get editorCopyrightField => 'Autorska prava';

  @override
  String get editorLicenseField => 'Licenca';

  @override
  String get songInfoSources => 'Izvori i zasluge';

  @override
  String get searchMatchSameSong => 'Ista pjesma; snimka nije potvrđena';

  @override
  String get searchMatchNeedsAgreement =>
      'Za potvrdu akorda potreban je tekst pjesme';

  @override
  String get searchMatchDifferentLyrics =>
      'Tekst se razlikuje od odabrane pjesme';

  @override
  String get searchMatchCombinedSources =>
      'Pojedinosti su objedinjene iz više izvora';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Objedinjeno iz $count izvora',
      few: 'Objedinjeno iz $count izvora',
      one: 'Objedinjeno iz $count izvora',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count podudaranja pjesama',
      few: '$count podudaranja pjesama',
      one: '$count podudaranje pjesme',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verzija izvora',
      few: '$count verzije izvora',
      one: '$count verzija izvora',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Najbolje dostupno podudaranje';

  @override
  String get providerDescriptionUnknown => 'Izvor pjesme';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Preuzmite datoteku ChordPro iz izvora, a zatim je uvezite.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Preuzmite datoteku besplatnim računom, a zatim je uvezite.';

  @override
  String get providerDescPublicChordSheets => 'Javno dostupni zapisi akorda.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Povijesni tekstovi licencirani su za svako djelo zasebno.';

  @override
  String get providerDescLicensedCatalog =>
      'Licencirani katalog tekstova pjesama.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Izvorne pjesme objavljene pod licencom Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Tekstovi pjesama licencirani su zasebno za svaku pjesmu.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Samo pojedinosti o snimci i izdanju.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Samo pojedinosti o skladbi.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Omot je dostupan samo za točno podudaranje snimke.';

  @override
  String get providerCapabilityLyrics => 'Tekstovi pjesama';

  @override
  String get providerCapabilityChords => 'Akordi';

  @override
  String get providerCapabilityTiming => 'Vremenski usklađeni tekstovi';

  @override
  String get providerCapabilitySearch => 'Pretraživanje';

  @override
  String get providerCapabilityMetadata => 'Pojedinosti o pjesmi';

  @override
  String get editorArtworkField => 'Poveznica na omot';

  @override
  String get editorLyricsHint =>
      'Dodirnite stih da biste uredili tekst ili akorde.';

  @override
  String get editorSave => 'Spremi promjene';

  @override
  String get editorSaved => 'Promjene su spremljene.';

  @override
  String get editorSaveFailed => 'Promjene nije bilo moguće spremiti.';

  @override
  String get editorSaveConflict =>
      'Pjesma je promijenjena na drugom mjestu. Vaše su izmjene spremljene kao zasebna kopija.';

  @override
  String get editorUnsavedTitle => 'Odbaciti promjene?';

  @override
  String get editorUnsavedMessage => 'Vaše izmjene nisu spremljene.';

  @override
  String get editorFieldRequired => 'Unesite naslov pjesme.';

  @override
  String get settingsTitle => 'Postavke';

  @override
  String get settingsAppearance => 'Izgled';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Koristi postavku uređaja';

  @override
  String get settingsThemeLight => 'Svijetla';

  @override
  String get settingsThemeDark => 'Tamna';

  @override
  String get settingsColorPalette => 'Paleta boja';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsTextSize => 'Veličina teksta';

  @override
  String get settingsLyricsPreview => 'Pretpregled teksta';

  @override
  String get settingsPlayer => 'Reprodukcija teksta';

  @override
  String get settingsDefaultShowChords =>
      'Prema zadanim postavkama prikaži akorde';

  @override
  String get settingsDefaultAutoscroll => 'Automatski pokreni pomicanje teksta';

  @override
  String get settingsDefaultTiming => 'Zadani način pomicanja';

  @override
  String get settingsLanguage => 'Jezik aplikacije';

  @override
  String get settingsLanguageSystem => 'Koristi jezik uređaja';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Izvori tekstova pjesama';

  @override
  String settingsSourceEnabled(String source) {
    return 'Omogući izvor $source';
  }

  @override
  String get settingsSourceRefresh => 'Osvježi popis izvora';

  @override
  String get settingsSourcesUpdated => 'Izvori su ažurirani.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Nije bilo moguće osvježiti izvore.';

  @override
  String get settingsImport => 'Uvezi pjesme';

  @override
  String get settingsImportChordPro => 'Uvezi datoteku ChordPro';

  @override
  String get settingsImportSetlist => 'Uvezi datoteku setliste';

  @override
  String get settingsImportSuccess => 'Uvoz je dovršen.';

  @override
  String get settingsImportFailed => 'Datoteku nije bilo moguće uvesti.';

  @override
  String get settingsImportUnsupported => 'Ova vrsta datoteke nije podržana.';

  @override
  String get settingsShareSong => 'Podijeli kao ChordPro';

  @override
  String get settingsSharePdf => 'Podijeli kao PDF';

  @override
  String get settingsCopySong => 'Kopiraj u međuspremnik';

  @override
  String get settingsPrintSong => 'Samo ispiši';

  @override
  String get settingsPrintSetlist => 'Ispiši setlistu s tekstovima pjesama';

  @override
  String get settingsExportFailed => 'Datoteku nije bilo moguće pripremiti.';

  @override
  String get settingsCopied => 'Kopirano u međuspremnik.';

  @override
  String get settingsAbout => 'O aplikaciji';

  @override
  String get settingsPrivacy => 'Privatnost';

  @override
  String get settingsLegal => 'Pravne informacije';

  @override
  String get settingsClearHistory => 'Izbriši povijest';

  @override
  String get settingsClearHistoryConfirm =>
      'Izbrisati povijest pjesama i setlista?';

  @override
  String get settingsHistoryCleared => 'Povijest je izbrisana.';

  @override
  String get accountTitle => 'Račun i sinkronizacija';

  @override
  String get accountUnavailable =>
      'Za sinkronizaciju je potrebna verzija Singbooka s konfiguriranom prijavom putem Googlea. Ova verzija čuva pjesme samo na ovom uređaju.';

  @override
  String get accountSyncNow => 'Sinkroniziraj sada';

  @override
  String get accountConnected =>
      'Povezano. Odaberite Sinkroniziraj sada da biste ažurirali sigurnosnu kopiju.';

  @override
  String get accountSignIn => 'Poveži račun';

  @override
  String get accountSignOut => 'Odjavi se';

  @override
  String get accountChange => 'Promijeni račun';

  @override
  String get accountSignedOut => 'Nije povezano';

  @override
  String get accountSyncing => 'Sinkronizacija vaše zbirke…';

  @override
  String get accountSynced => 'Zbirka je sinkronizirana.';

  @override
  String get accountSyncFailed => 'Zbirku nije bilo moguće sinkronizirati.';

  @override
  String get accessibilityFavorite => 'Favorit';

  @override
  String get accessibilityNotFavorite => 'Nije favorit';

  @override
  String get accessibilitySearchField => 'Pretraživanje pjesama';

  @override
  String get accessibilityClearSearch => 'Očisti tekst pretraživanja';

  @override
  String accessibilitySongMenu(String song) {
    return 'Radnje za pjesmu $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Radnje za setlistu $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Proširi pjesme u setlisti $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Sažmi pjesme u setlisti $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Napredak reprodukcije, $percent posto';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Vremenska crta povijesti, $date';
  }

  @override
  String get loading => 'Učitavanje…';

  @override
  String get loadingSongs => 'Učitavanje pjesama…';

  @override
  String get loadingSetlists => 'Učitavanje setlista…';

  @override
  String get errorGeneric => 'Došlo je do pogreške.';

  @override
  String get errorOffline => 'Čini se da niste povezani s internetom.';

  @override
  String get errorPermission => 'Za nastavak je potrebno dopuštenje.';

  @override
  String get emptyFiltered => 'Nijedna stavka ne odgovara ovim filtrima.';

  @override
  String get unknownValue => 'Nepoznato';

  @override
  String get durationUnknown => 'Trajanje nije poznato';

  @override
  String get metadataNotSet => 'Nije postavljeno';

  @override
  String get dateToday => 'Danas';

  @override
  String get dateYesterday => 'Jučer';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pjesama',
      few: '$count pjesme',
      one: '$count pjesma',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Tamnoplava';

  @override
  String get settingsPaletteSage => 'Kaduljasto zelena';

  @override
  String get settingsPaletteOcean => 'Oceanska';

  @override
  String get settingsPaletteClay => 'Glinena';

  @override
  String get settingsPalettePlum => 'Šljivasta';

  @override
  String get settingsFontSystem => 'Sistemski';

  @override
  String get settingsFontSerif => 'Serifni';

  @override
  String get settingsFontMonospace => 'Monospace';

  @override
  String get settingsLyricsPreviewExample =>
      'Kad jutro svane, ponovno ćemo zapjevati.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Provjera izvora tekstova pjesama: dovršeno $checked od $total.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Nije pronađen nijedan upotrebljiv tekst pjesme.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Odabrana pjesma provjerena je u svim omogućenim izvorima, ali nijedan nije vratio upotrebljivu verziju teksta.';

  @override
  String get searchDiscoveryError =>
      'Nije bilo moguće provjeriti izvore tekstova pjesama.';

  @override
  String get searchDiscoveryRetry => 'Ponovno pretraži tekstove pjesama';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nedostupnih izvora',
      few: '$count nedostupna izvora',
      one: '$count nedostupan izvor',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Provjerite vezu i pokušajte ponovno.';

  @override
  String get searchProviderChecks => 'Provjere izvora';

  @override
  String get searchProviderPending => 'Provjera u tijeku';

  @override
  String get searchProviderFound => 'Pronađeno podudaranje';

  @override
  String get searchProviderRejected => 'Ne podudara se';

  @override
  String get searchProviderFailed => 'Provjera nije uspjela';

  @override
  String get searchProviderUnavailable => 'Nema upotrebljivog teksta pjesme';

  @override
  String get searchCatalogFilterHint =>
      'Odaberite pjesmu da biste filtrirali verzije teksta prema akordima, vremenskom usklađivanju ili jeziku.';

  @override
  String get startupErrorTitle => 'Nije bilo moguće otvoriti vašu zbirku.';

  @override
  String setlistCopyName(String name) {
    return 'Kopija: $name';
  }

  @override
  String get setlistSongMissing => 'Pjesma nedostaje';

  @override
  String get settingsImportTooLarge => 'Ova je datoteka prevelika za uvoz.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Skoči na slovo $letter';
  }

  @override
  String get actionDiscard => 'Odbaci';

  @override
  String get editorKeepEditing => 'Nastavi uređivati';

  @override
  String get settingsDefaultShowChordsHint =>
      'Prikaži akorde iznad teksta pjesme ako postoje.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Tekst se pomiče uz pjesmu. Ne koristi se u načinu ručnog pomicanja.';

  @override
  String get accountUnavailableTitle => 'Sinkronizacija nije postavljena';

  @override
  String get accountSignedOutBenefits =>
      'Prijavite se putem Googlea da biste spremili sigurnosnu kopiju pjesama i setlista na svoj Google Drive i uskladili sve uređaje. Pjesme će u svakom slučaju ostati na ovom uređaju.';

  @override
  String get accountSignInWithGoogle => 'Prijavite se putem Googlea';

  @override
  String get accountWorking => 'Obrada…';

  @override
  String get accountNeverSynced => 'Još nije sinkronizirano';

  @override
  String get accountSyncedJustNow => 'Upravo sinkronizirano';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinkronizirano prije $count minuta',
      few: 'Sinkronizirano prije $count minute',
      one: 'Sinkronizirano prije $count minutu',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinkronizirano prije $count sati',
      few: 'Sinkronizirano prije $count sata',
      one: 'Sinkronizirano prije $count sat',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinkronizirano prije $count dana',
      few: 'Sinkronizirano prije $count dana',
      one: 'Sinkronizirano prije $count dan',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Spremljene su kopije za $count spornih izmjena',
      few: '$count sporne izmjene spremljene su kao kopije',
      one: '$count sporna izmjena spremljena je kao kopija',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Ista pjesma ili setlista uređena je na dva mjesta. Ništa nije izgubljeno: druga je verzija spremljena kao zasebna kopija.';

  @override
  String get accountReviewConflicts => 'Pregledaj kopije';

  @override
  String get songsConflictFilterActive =>
      'Prikazuju se samo kopije nastale zbog sukoba';

  @override
  String get songsConflictFilterClear => 'Prikaži sve pjesme';

  @override
  String get songsConflictBadge => 'Kopija zbog sukoba';

  @override
  String get songsConflictEmpty => 'Nema kopija nastalih zbog sukoba.';

  @override
  String get accountAutoSync => 'Automatska sinkronizacija';

  @override
  String get accountAutoSyncHint =>
      'Ažurirajte zbirku pri otvaranju aplikacije i nakon promjena.';

  @override
  String get accountSignOutTitle => 'Odjaviti se s ovog računa?';

  @override
  String get accountSignOutBody =>
      'Pjesme i setliste ostat će na ovom uređaju. Sigurnosno kopiranje i sinkronizacija obustavit će se dok se ponovno ne prijavite.';

  @override
  String get accountUseDifferent => 'Koristi drugi račun';

  @override
  String get accountSignInAgain => 'Prijavi se ponovno';

  @override
  String get accountChooseAction => 'Odaberite kako želite nastaviti';

  @override
  String get accountChangedTitle => 'Drugi Google račun';

  @override
  String get accountChangedBody =>
      'Ovaj je uređaj zadnji put sinkroniziran s drugim Google računom. Odaberite što će se dogoditi s pjesmama i setlistama na ovom uređaju.';

  @override
  String get accountChangedMerge => 'Spoji sa zbirkom novog računa';

  @override
  String get accountChangedMergeHint =>
      'Zadržite sve na ovom uređaju i dodajte to na novi račun.';

  @override
  String get accountChangedReplace => 'Zamijeni zbirkom novog računa';

  @override
  String get accountChangedReplaceHint =>
      'Pjesme s ovog uređaja kojih nema na novom računu bit će uklonjene.';

  @override
  String get accountChangedSignOut => 'Odustani i odjavi se';

  @override
  String get accountStatusSignedOut =>
      'Račun i sinkronizacija: niste prijavljeni';

  @override
  String get accountStatusSignedIn => 'Račun i sinkronizacija: prijavljeni ste';

  @override
  String get accountStatusSyncing =>
      'Račun i sinkronizacija: sinkronizacija u tijeku';

  @override
  String get accountStatusSynced =>
      'Račun i sinkronizacija: zbirka je ažurirana';

  @override
  String get accountStatusError =>
      'Račun i sinkronizacija: problem, dodirnite za pregled';

  @override
  String get accountNoticeConflicts =>
      'Neke su pjesme uređene na dva mjesta. Kopije su sačuvane.';

  @override
  String get accountNoticeSignedIn => 'Prijavljeni ste.';

  @override
  String get accountNoticeSignedOut =>
      'Odjavljeni ste. Pjesme ostaju na ovom uređaju.';

  @override
  String get syncErrorNotConfigured =>
      'Sinkronizacija nije postavljena u ovoj verziji.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Upotrijebite verziju Singbooka s konfiguriranom prijavom putem Googlea.';

  @override
  String get syncErrorNotSignedIn => 'Niste prijavljeni.';

  @override
  String get syncErrorNotSignedInHint =>
      'Prijavite se da biste sinkronizirali zbirku.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google traži da se ponovno prijavite.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Ponovno se prijavite da biste nastavili sinkronizaciju. Pjesme su sigurne na ovom uređaju.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook nema dopuštenje za upotrebu Google Drivea.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Ponovno se prijavite i dopustite pristup Driveu kada se to zatraži.';

  @override
  String get syncErrorRateLimited =>
      'Google trenutačno ograničava broj zahtjeva.';

  @override
  String get syncErrorRateLimitedHint =>
      'Pričekajte nekoliko minuta pa pokušajte ponovno.';

  @override
  String get syncErrorStorageFull => 'Vaš Google Drive je pun.';

  @override
  String get syncErrorStorageFullHint =>
      'Oslobodite prostor na Driveu pa pokušajte ponovno.';

  @override
  String get syncErrorNetwork => 'Nije moguće povezati se s Googleom.';

  @override
  String get syncErrorNetworkHint =>
      'Provjerite internetsku vezu i pokušajte ponovno.';

  @override
  String get syncErrorAccountChanged => 'Upotrijebljen je drugi Google račun.';

  @override
  String get syncErrorAccountChangedHint =>
      'Odaberite želite li zbirku s ovog uređaja spojiti s njim ili je zamijeniti.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Sinkronizirana zbirka veća je nego što Singbook može obraditi.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Uklonite pjesme ili setliste iz sinkronizirane zbirke pa pokušajte ponovno.';

  @override
  String get syncErrorSignInFailed => 'Prijava nije dovršena.';

  @override
  String get syncErrorSignInFailedHint => 'Pokušajte se ponovno prijaviti.';

  @override
  String get syncErrorGeneric => 'Zbirku nije bilo moguće sinkronizirati.';

  @override
  String get syncErrorGenericHint =>
      'Pokušajte ponovno za koji trenutak. Pjesme su i dalje sigurne na ovom uređaju.';

  @override
  String get editorDurationInvalid =>
      'Unesite sekunde ili minute i sekunde, npr. 3:45.';

  @override
  String get editorNumberInvalid => 'Unesite broj.';

  @override
  String get accountReplaceConfirmTitle => 'Izbrisati lokalne pjesme?';

  @override
  String get accountReplaceConfirmBody =>
      'Pjesme i setliste na ovom uređaju kojih nema na novom računu bit će trajno izbrisane. Ovo se ne može poništiti.';

  @override
  String get accountReplaceConfirmAction => 'Izbriši i zamijeni';

  @override
  String get accountSuspiciousTitle => 'Items missing from Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items that this device synced earlier are missing from Google Drive.',
      one:
          '$count item that this device synced earlier is missing from Google Drive.',
    );
    return '$_temp0 This can happen if app data was cleared in Google settings. Nothing has been deleted yet.';
  }

  @override
  String get accountSuspiciousDelete => 'Delete them here too';

  @override
  String get accountSuspiciousKeep => 'Keep my songs and upload them again';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items from this device?',
      one: 'Delete $count item from this device?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'These songs and setlists will be permanently deleted from this device. This can\'t be undone.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Delete from this device';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Items are missing from Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Nothing was deleted. Choose whether to delete them here too or upload them again.';

  @override
  String get syncErrorRemoteChanged => 'Google Drive changed while syncing.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Nothing was lost. Sync again to pick up the latest changes.';

  @override
  String get syncErrorInvalidLocalData =>
      'Some data on this device couldn\'t be synced.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'A song or setlist could not be read. Import or recreate it, then sync again.';

  @override
  String get syncErrorNoAccountChange =>
      'There is no account change to resolve.';

  @override
  String get syncErrorNoAccountChangeHint => 'Sync again to continue.';

  @override
  String get accountSyncWarningTitle => 'Synced, but some files were skipped';

  @override
  String get accountSyncWarningBody =>
      'Some files couldn\'t be used and were left as they are. Everything else is up to date.';

  @override
  String get accountSyncWarningTooLarge =>
      'A file was too large to sync and was skipped. Everything else is up to date.';

  @override
  String get accountSyncWarningInvalid =>
      'A file couldn\'t be read and was skipped. Everything else is up to date.';

  @override
  String get accountNoticeSyncSkipped => 'Synced. Some files were skipped.';

  @override
  String get settingsExportPdfTooLarge =>
      'This PDF would be too large. Try fewer songs, or share it as text.';

  @override
  String get settingsTimingTooLarge =>
      'The timing data is too large (over 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'This backup lists the same song twice, so nothing was imported.';

  @override
  String get setlistSaveConflict =>
      'The setlist changed elsewhere. Your edits were saved as a separate copy.';

  @override
  String get sectionVerse => 'Strofa';

  @override
  String get sectionChorus => 'Refren';

  @override
  String get sectionBridge => 'Most';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Prije refrena';

  @override
  String get sectionPostChorus => 'Poslije refrena';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Međuigra';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Pripjev';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Koda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Završetak';
}
