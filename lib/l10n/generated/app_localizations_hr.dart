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
      'Tekstovi, akordi i popisi pjesama zajedno, spremni za probu, pozornicu i svako mjesto na kojem sviraš.';

  @override
  String get aboutMadeForSinging => 'Svaka pjesma spremna.';

  @override
  String get aboutDetails =>
      'Pretraži omogućene izvore i usporedi tekstove, akorde, vremenske oznake i pojedinosti o snimci prije nego što spremiš verziju koju želiš svirati. Dostupnost ovisi o pjesmi i usluzi.';

  @override
  String get aboutFindTitle => 'Pronađi pravu verziju';

  @override
  String get aboutKeepTitle => 'Izgradi vlastitu zbirku';

  @override
  String get aboutKeepDetails =>
      'Uređuj pjesme i transponiraj ih, čuvaj ih u svojoj lokalnoj zbirci za korištenje izvan mreže i dijeli prenosive datoteke ChordPro. Neobavezna sinkronizacija s Google Driveom koristi privatnu mapu aplikacije na tvom Google računu. Možeš dodirnuti i „Sinkroniziraj sada” da ažuriraš svoje uređaje.';

  @override
  String get aboutPlayTitle => 'Ponesi svoj popis na pozornicu';

  @override
  String get aboutPlayDetails =>
      'Poredaj pjesme u popise, odaberi tonalitet za svaku pjesmu i dijeli popise OpenSong. Prilagodi tekst čitača i automatsko pomicanje stihova te ispisuj PDF-ove pjesama. Singbook ne prenosi ni reproducira zvuk.';

  @override
  String get aboutPrivacyTitle => 'Besplatno i usmjereno na lokalnu pohranu';

  @override
  String get aboutPrivacyDetails =>
      'Singbook je besplatan, bez oglasa, analitike i kupnji unutar aplikacije. Tvoja spremljena zbirka ostaje na uređaju; neobavezna sinkronizacija koristi tvoj Google Drive. Mrežni rezultati dolaze izravno od neovisnih usluga trećih strana i možda nisu dostupni ili su zaštićeni autorskim pravima. Singbook ne hostira njihov sadržaj.';

  @override
  String get aboutWebsite => 'Web-stranica Singbooka';

  @override
  String get aboutSourceCode => 'Izvorni kod na GitHubu';

  @override
  String get aboutPublisher => 'Od Freevije';

  @override
  String aboutLanguages(int count) {
    return 'Jezici aplikacije: $count';
  }

  @override
  String get aboutSupport => 'Podrška i povratne informacije';

  @override
  String get menuTypeNewSong => 'Unesi novu pjesmu';

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
  String get appExitBackAgain => 'Za izlaz ponovno pritisnite Natrag';

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
  String get searchChangeSong => 'Promijeni pjesmu';

  @override
  String get searchSelectedPreview => 'Odabrani pretpregled';

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
  String get searchFullPreview => 'Cijeli pregled';

  @override
  String get searchArrangementNotes => 'Napomene o aranžmanu';

  @override
  String get searchOpenLyrics => 'Otvori tekst';

  @override
  String get searchContributions => 'Korišteni izvori';

  @override
  String get searchVersionChecking => 'Provjera ove verzije…';

  @override
  String get searchVersionUnavailable =>
      'Ova se verzija ne može upotrijebiti. Odaberi drugu verziju.';

  @override
  String get searchPreviewUnavailable => 'Pregled teksta nije dostupan.';

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
  String get searchViewVersions => 'Prikaži verzije';

  @override
  String get searchSaved => 'Pjesma je spremljena u vašu zbirku.';

  @override
  String get searchSaveOpenLyrics => 'Spremi i otvori tekst';

  @override
  String get searchOtherResults => 'Ostali rezultati';

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
  String get setlistShare => 'Podijeli kao OpenSong';

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
  String get readerSaved => 'Spremljeno';

  @override
  String get readerEdit => 'Uredi tekst i pojedinosti';

  @override
  String get playerPlay => 'Pokreni';

  @override
  String get playerPause => 'Pauza';

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
  String get playerStartScroll => 'Pokreni automatsko pomicanje';

  @override
  String get playerEstimatedPace => 'Procijenjena brzina';

  @override
  String get playerScrollSpeed => 'Brzina pomicanja';

  @override
  String playerEstimatedDuration(String time) {
    return 'Procijenjeno trajanje: $time';
  }

  @override
  String get playerLyricsOnly => 'Pomicanje teksta · bez zvuka';

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
  String get searchCombinedLabel => 'Kombinirano';

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
      'Akorde pišite u uglate zagrade [C]; oznake dijelova u zasebne retke.';

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
  String get settingsLyricHighlight => 'Isticanje trenutačnog retka';

  @override
  String get settingsHighlightBackgroundUnderline => 'Pozadina + podcrtavanje';

  @override
  String get settingsHighlightBackground => 'Pozadina';

  @override
  String get settingsHighlightUnderline => 'Podcrtavanje';

  @override
  String get settingsHighlightContrast => 'Kontrastna boja teksta';

  @override
  String get settingsHighlightNone => 'Bez';

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
      'Briše nedavnu povijest aktivnosti pjesama i setlista. Zadržava spremljene pjesme, favorite, setliste i postavke.';

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
  String get settingsPreviewSongTitle => 'Jutarnja pjesma';

  @override
  String get settingsPreviewArtist => 'Primjer aranžmana';

  @override
  String get settingsPreviewCurrentLine => 'Kad jutro svane';

  @override
  String get settingsPreviewNextLine => 'Ponovno ćemo zapjevati.';

  @override
  String get settingsPlayerSections => 'Naslovi odjeljaka';

  @override
  String get settingsPlayerControls => 'Ploča za reprodukciju';

  @override
  String get settingsPlayerAutoscroll => 'Automatsko pomicanje';

  @override
  String get settingsSystemShort => 'Uređaj';

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
      'Povezivanjem s Google Driveom sinkronizira se vaša zbirka. Promjene pjesama nakon toga sinkroniziraju se automatski.';

  @override
  String get accountManualSyncHint =>
      'Zbirku možete sinkronizirati i tako da dodirnete Sinkroniziraj sada.';

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
      'Sinkronizacija se odvija nakon povezivanja te nakon dodavanja, uređivanja ili uklanjanja pjesme.';

  @override
  String get accountDriveFolder => 'Mapa biblioteke Google diska';

  @override
  String get accountPrivateDriveFolder => 'Privatna mapa Singbook';

  @override
  String get accountChooseDriveFolder => 'Odaberite mapu';

  @override
  String get accountDriveFolderMoveTitle =>
      'Premjestiti svoju biblioteku Singbook?';

  @override
  String get accountDriveFolderMoveBody =>
      'Odaberite vidljivu mapu Google diska. Singbook će tamo kopirati i potvrditi vaše pjesme i setliste prije nego se prebacite na njega. Izvorne datoteke ostaju na svojoj prethodnoj lokaciji kao sigurnosna kopija. Ostale datoteke ostaju same. ChordPro datoteke koje uvezete u ovu mapu usvajaju se za sinkronizaciju i primaju Singbook metapodatke.';

  @override
  String get accountImportChordPro => 'Uvezite ChordPro s Diska';

  @override
  String get accountImportChordProHint =>
      'Odaberite .cho datoteke za dodavanje u ovu biblioteku. Usvajaju se datoteke koje se već nalaze u mapi; datoteke na drugim mjestima kopiraju se ovdje.';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'Odabir mape pogona nije dostupan';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'Na podržanom uređaju odaberite vidljivu mapu Diska pomoću alata za odabir Google Diska.';

  @override
  String get syncErrorDriveFolderMissing => 'Mapa Singbook Drive nije dostupna';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Ponovno odaberite mapu ili je vratite na Google disk.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook treba pristup ovoj mapi Diska';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Ponovno odaberite mapu da biste odobrili pristup, a zatim sinkronizirajte svoju biblioteku.';

  @override
  String get syncErrorFolderMigration =>
      'Knjižnica još nije mogla biti premještena';

  @override
  String get syncErrorFolderMigrationHint =>
      'Vaša prethodna biblioteka još uvijek je sigurna. Provjerite vezu i ponovno odaberite mapu za ponovni pokušaj.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Prvo odaberite vidljivu mapu Diska';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'Prije uvoza datoteka s Diska potrebna je vidljiva mapa knjižnice.';

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
  String get syncErrorOAuthClientConfiguration =>
      'Google rejected this build\'s sign-in configuration.';

  @override
  String get syncErrorOAuthClientConfigurationHint =>
      'Check that the configured OAuth ID is Singbook\'s Desktop app client.';

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
  String get accountSuspiciousTitle => 'Nedostaju stavke na Google Driveu';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count stavki koje je ovaj uređaj ranije sinkronizirao nedostaje na Google Driveu.',
      few:
          '$count stavke koje je ovaj uređaj ranije sinkronizirao nedostaju na Google Driveu.',
      one:
          '$count stavka koju je ovaj uređaj ranije sinkronizirao nedostaje na Google Driveu.',
    );
    return '$_temp0 To se može dogoditi ako su podaci aplikacije izbrisani u Googleovim postavkama. Još ništa nije izbrisano.';
  }

  @override
  String get accountSuspiciousDelete => 'Izbriši ih i ovdje';

  @override
  String get accountSuspiciousKeep => 'Zadrži moje pjesme i ponovno ih prenesi';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Izbrisati $count stavki s ovog uređaja?',
      few: 'Izbrisati $count stavke s ovog uređaja?',
      one: 'Izbrisati $count stavku s ovog uređaja?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Ove pjesme i setliste bit će trajno izbrisane s ovog uređaja. To se ne može poništiti.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Izbriši s ovog uređaja';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Nedostaju stavke na Google Driveu.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Ništa nije izbrisano. Odaberite želite li ih izbrisati i ovdje ili ih ponovno prenijeti.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive promijenio se tijekom sinkronizacije.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Ništa nije izgubljeno. Ponovno sinkronizirajte da biste preuzeli najnovije promjene.';

  @override
  String get syncErrorInvalidLocalData =>
      'Neke podatke na ovom uređaju nije bilo moguće sinkronizirati.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Pjesmu ili setlistu nije bilo moguće pročitati. Uvezite je ili ponovno izradite pa sinkronizirajte.';

  @override
  String get syncErrorNoAccountChange =>
      'Nema promjene računa koju treba riješiti.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Ponovno sinkronizirajte za nastavak.';

  @override
  String get accountSyncWarningTitle =>
      'Sinkronizirano, ali neke su datoteke preskočene';

  @override
  String get accountSyncWarningBody =>
      'Neke datoteke nije bilo moguće upotrijebiti pa su ostavljene kakve jesu. Sve ostalo je ažurno.';

  @override
  String get accountSyncWarningTooLarge =>
      'Datoteka je bila prevelika za sinkronizaciju pa je preskočena. Sve ostalo je ažurno.';

  @override
  String get accountSyncWarningInvalid =>
      'Datoteku nije bilo moguće pročitati pa je preskočena. Sve ostalo je ažurno.';

  @override
  String get accountNoticeSyncSkipped =>
      'Sinkronizirano. Neke su datoteke preskočene.';

  @override
  String get settingsExportPdfTooLarge =>
      'Ovaj PDF bio bi prevelik. Odaberite manje pjesama ili ga podijelite kao tekst.';

  @override
  String get settingsTimingTooLarge =>
      'Podaci za vremensko usklađivanje preveliki su (više od 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Ova sigurnosna kopija navodi istu pjesmu dvaput pa ništa nije uvezeno.';

  @override
  String get setlistSaveConflict =>
      'Setlista je promijenjena drugdje. Vaše su izmjene spremljene kao zasebna kopija.';

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
  String get sectionPreChorus => 'Predrefren';

  @override
  String get sectionPostChorus => 'Postrefren';

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

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dostupnih verzija',
      few: '$count dostupne verzije',
      one: '$count dostupna verzija',
      zero: 'Nema dostupnih verzija',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nedostupnih verzija',
      few: '$count nedostupne verzije',
      one: '$count nedostupna verzija',
      zero: 'Nema nedostupnih verzija',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Idi na odjeljak';

  @override
  String get searchVersionDetails => 'Pojedinosti o verziji';

  @override
  String get searchSelectedRecording => 'Odabrana snimka';

  @override
  String get searchVersionDuration => 'Trajanje verzije';

  @override
  String get searchSourceOptions => 'Opcije izvora';

  @override
  String get actionUndo => 'Poništi';

  @override
  String setlistEntryRemoved(String song) {
    return 'Pjesma „$song” uklonjena je s popisa';
  }

  @override
  String get backupTitle => 'Sigurnosna kopija i vraćanje';

  @override
  String get backupExport => 'Izvezi sigurnosnu kopiju';

  @override
  String get backupRestore => 'Vrati sigurnosnu kopiju';

  @override
  String get backupIncludePreferences => 'Uključi postavke aplikacije';

  @override
  String get backupRestorePreferences => 'Vrati postavke aplikacije';

  @override
  String get backupMerge => 'Dodaj u ovu biblioteku';

  @override
  String get backupMergeHint =>
      'Zadrži lokalne izmjene i dodaj pjesme i popise iz ove sigurnosne kopije.';

  @override
  String get backupReplace => 'Zamijeni ovu biblioteku';

  @override
  String get backupReplaceHint =>
      'Zamijeni sve pjesme i popise na ovom uređaju sadržajem ove sigurnosne kopije.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Pjesme: $songs · Popisi: $setlists · Sukobi: $conflicts';
  }

  @override
  String get backupFailed =>
      'Nije moguće dovršiti ovu radnju. Pokušajte ponovno.';

  @override
  String get backupRestored => 'Sigurnosna kopija vraćena je.';

  @override
  String get backupLocalHint =>
      'Spremite kopiju svoje biblioteke. Podaci računa i kolačići privole nikad se ne uključuju.';

  @override
  String get backupReplaceConfirm =>
      'Želite li zamijeniti trenutačnu biblioteku? To se ne može poništiti.';

  @override
  String get searchCheckOperations => 'Operacije';

  @override
  String get searchCheckCode => 'Šifra rezultata';

  @override
  String get searchCheckQueued => 'Čeka se provjera ovog izvora.';

  @override
  String get searchCheckFetch => 'Učitaj tekst pjesme';

  @override
  String get searchCheckValidate => 'Provjeri podudaranje pjesme';

  @override
  String get searchCheckCorroborate => 'Provjeri podudaranje teksta';

  @override
  String get searchCheckCompleted => 'Dovršeno';

  @override
  String get searchCheckTimeout => 'Izvor nije odgovorio na vrijeme.';

  @override
  String get searchCheckBlocked => 'Izvor je blokirao zahtjev.';

  @override
  String get searchCheckRateLimited =>
      'Izvor ograničava zahtjeve. Pokušajte ponovno poslije.';

  @override
  String get searchCheckNetwork =>
      'Nije moguće pristupiti izvoru. Provjerite vezu.';

  @override
  String get searchCheckInvalid => 'Izvor je vratio nečitljiv odgovor.';

  @override
  String get searchCheckNotConfigured =>
      'Ovaj izvor nije konfiguriran u ovoj verziji.';

  @override
  String get searchCheckNoLyrics => 'Nije pronađen odgovarajući tekst pjesme.';

  @override
  String get searchCheckFailed => 'Ovu radnju nije moguće dovršiti.';

  @override
  String get searchCheckNoHistory =>
      'Za ovu usporedbu nisu provedene provjere izvora.';

  @override
  String get searchVersionCredits => 'Zasluge';

  @override
  String get searchVersionMediaLinks => 'Povezane poveznice';

  @override
  String get searchCheckCancelled => 'Otkazano';

  @override
  String get searchCheckAmbiguous =>
      'Pronađeno je više podudaranja. Ovom je izvoru potrebna određenija snimka.';

  @override
  String get searchCheckIdentity =>
      'Ovom je izvoru potreban identifikator snimke ili djela.';

  @override
  String get searchCheckExtraction =>
      'Izvor je odgovorio, ali tekst pjesme nije moguće izdvojiti.';

  @override
  String get searchCheckBusy => 'Izvor je zauzet. Pokušajte ponovno poslije.';

  @override
  String get searchCheckSelection =>
      'Odaberite određeni rezultat iz ovog izvora.';

  @override
  String get playerChordsNone => 'Ništa';

  @override
  String get editorCustomValue => 'Drugo…';

  @override
  String get editorStandardTuning => 'Standardno ugađanje';

  @override
  String get editorExampleVerse =>
      '[C]Novi dan nas [G]zove,\n[Am]pratimo svjetlo natrag [F]kući.';

  @override
  String get editorExampleChorus =>
      '[F]Pjevajmo ovu pjesmu [C]zajedno,\n[G]neka nas melodija ponese [C]dalje.';

  @override
  String get editorExampleBridge => '[Am]Još jedan redak, malo [F]bliže.';

  @override
  String get playerEstimatedKey => 'Procijenjeni tonalitet';

  @override
  String get songsLibraryView => 'Knjižnica';

  @override
  String get settingsStartupView => 'Početni prikaz';

  @override
  String get settingsStartupViewHint =>
      'Odaberite prikaz pjesama koji će se prikazati pri otvaranju aplikacije.';

  @override
  String get settingsStartupLastView => 'Posljednji otvoreni';

  @override
  String get playerFullScreen => 'Cijeli zaslon';

  @override
  String get playerExitFullScreen => 'Izađi iz cijelog zaslona';

  @override
  String get playerExpandControls => 'Prikaži kontrole reprodukcije';

  @override
  String get playerCollapseControls => 'Sakrij kontrole reprodukcije';

  @override
  String get settingsShowSections => 'Prikaži naslove odjeljaka';

  @override
  String get settingsShowSectionsHint =>
      'Prikaži naslove strofa, refrena i drugih odjeljaka u tekstu pjesme.';

  @override
  String get settingsShowPlayerControls => 'Prikaži kontrole reprodukcije';

  @override
  String get settingsShowPlayerControlsHint =>
      'Ploču reproduktora možete prikazati ili sakriti i dodirom ili prelaskom prstom.';
}
