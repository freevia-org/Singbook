// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Besedila, akordi in seznami skladb na enem mestu, pripravljeni za vaje, oder in kjer koli igrate.';

  @override
  String get aboutMadeForSinging => 'Vsaka pesem, pripravljena.';

  @override
  String get aboutDetails =>
      'Iščite po dostopnih virih ter primerjajte besedila, akorde, časovne oznake in podatke o posnetkih, preden shranite želeno različico. Dostopnost je odvisna od pesmi in storitve.';

  @override
  String get aboutFindTitle => 'Poiščite pravo različico';

  @override
  String get aboutKeepTitle => 'Ustvarite svojo knjižnico';

  @override
  String get aboutKeepDetails =>
      'Urejajte in transponirajte pesmi, hranite jih v lokalni knjižnici za uporabo brez povezave ter delite prenosne datoteke ChordPro. Izbirna sinhronizacija z Google Drive uporablja zasebno mapo aplikacije v vašem Google računu. Naprave lahko posodobite tudi tako, da tapnete »Sinhroniziraj zdaj«.';

  @override
  String get aboutPlayTitle => 'Odnesite seznam skladb na oder';

  @override
  String get aboutPlayDetails =>
      'Razvrstite pesmi v sezname, izberite tonaliteto za vsako in delite sezname OpenSong. Prilagodite velikost besedila v bralniku, vklopite samodejno pomikanje besedila in natisnite PDF-je pesmi. Singbook ne pretaka in ne predvaja zvoka.';

  @override
  String get aboutPrivacyTitle => 'Brezplačno in z lokalno knjižnico';

  @override
  String get aboutPrivacyDetails =>
      'Singbook je brezplačen, brez oglasov, analitike in nakupov v aplikaciji. Shranjena knjižnica ostane v vaši napravi; izbirna sinhronizacija uporablja vaš Google Drive. Spletni rezultati prihajajo neposredno od neodvisnih storitev tretjih oseb ter morda niso na voljo ali so zaščiteni z avtorskimi pravicami. Singbook njihove vsebine ne gosti.';

  @override
  String get aboutWebsite => 'Spletno mesto Singbook';

  @override
  String get aboutSourceCode => 'Izvorna koda na GitHubu';

  @override
  String get aboutPublisher => 'Avtor Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Jeziki aplikacije: $count';
  }

  @override
  String get aboutSupport => 'Podpora in povratne informacije';

  @override
  String get menuTypeNewSong => 'Vnesi novo pesem';

  @override
  String appVersion(String version) {
    return 'Različica $version';
  }

  @override
  String get navHome => 'Domov';

  @override
  String get navSongs => 'Pesmi';

  @override
  String get navSetlists => 'Koncertni seznami';

  @override
  String get navSettings => 'Nastavitve';

  @override
  String get navSettingsCompact => 'Nastavitve';

  @override
  String get navSearch => 'Iskanje';

  @override
  String get navBack => 'Nazaj';

  @override
  String get appExitBackAgain => 'Za izhod znova pritisnite Nazaj';

  @override
  String get navClose => 'Zapri';

  @override
  String get navMore => 'Več dejanj';

  @override
  String get actionCancel => 'Prekliči';

  @override
  String get actionSave => 'Shrani';

  @override
  String get actionDone => 'Končano';

  @override
  String get actionEdit => 'Uredi';

  @override
  String get actionDelete => 'Izbriši';

  @override
  String get actionShare => 'Deli';

  @override
  String get actionPrint => 'Natisni';

  @override
  String get actionCopy => 'Kopiraj';

  @override
  String get actionClear => 'Počisti';

  @override
  String get actionRetry => 'Poskusi znova';

  @override
  String get actionRefresh => 'Osveži';

  @override
  String get actionImport => 'Uvozi';

  @override
  String get actionExport => 'Izvozi';

  @override
  String get actionExpand => 'Razširi';

  @override
  String get actionCollapse => 'Strni';

  @override
  String get actionAdd => 'Dodaj';

  @override
  String get actionCreate => 'Ustvari';

  @override
  String get actionRemove => 'Odstrani';

  @override
  String get actionDuplicate => 'Podvoji';

  @override
  String get actionMoveUp => 'Premakni navzgor';

  @override
  String get actionMoveDown => 'Premakni navzdol';

  @override
  String get actionPrevious => 'Prejšnje';

  @override
  String get actionNext => 'Naslednje';

  @override
  String get searchHint => 'Iščite pesmi, izvajalce ali besedila pesmi';

  @override
  String get searchCatalogHint => 'Iščite pesem ali izvajalca';

  @override
  String get searchChangeSong => 'Spremeni pesem';

  @override
  String get searchSelectedPreview => 'Izbrani predogled';

  @override
  String get searchSubmit => 'Išči';

  @override
  String get searchFilters => 'Možnosti iskanja';

  @override
  String get searchFiltersShow => 'Pokaži možnosti iskanja';

  @override
  String get searchFiltersHide => 'Skrij možnosti iskanja';

  @override
  String get searchFilterArtist => 'Izvajalec';

  @override
  String get searchFilterTitle => 'Naslov pesmi';

  @override
  String get searchFilterLyrics => 'Besedila pesmi';

  @override
  String get searchFilterChords => 'Vsebuje akorde';

  @override
  String get searchFilterTimed => 'Časovno usklajena besedila';

  @override
  String get searchFilterLanguage => 'Jezik';

  @override
  String get searchFilterAll => 'Kateri koli';

  @override
  String get searchAutocompleteLabel => 'Predlogi';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rezultatov',
      few: '$count rezultati',
      two: '$count rezultata',
      one: '$count rezultat',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Vnesite pesem, izvajalca ali del besedila za iskanje.';

  @override
  String get searchCatalogEmptyQuery =>
      'Vnesite pesem ali izvajalca za iskanje.';

  @override
  String get searchNoResults =>
      'Ni najdenih pesmi. Poskusite z drugačnim iskanjem.';

  @override
  String get searchLoading => 'Iskanje pesmi…';

  @override
  String get searchError => 'Iskanja ni bilo mogoče dokončati.';

  @override
  String get searchOnlineTab => 'Na spletu';

  @override
  String get searchRecentTab => 'Nedavno';

  @override
  String get searchFavoritesTab => 'Priljubljeno';

  @override
  String get searchSuggested => 'Predlagano ujemanje';

  @override
  String get searchAlternatives => 'Druga ujemanja';

  @override
  String get searchCompare => 'Primerjaj različice';

  @override
  String get searchChooseVersion => 'Izberi to različico';

  @override
  String get searchFullPreview => 'Celoten predogled';

  @override
  String get searchArrangementNotes => 'Opombe o aranžmaju';

  @override
  String get searchOpenLyrics => 'Odpri besedilo';

  @override
  String get searchContributions => 'Uporabljeni viri';

  @override
  String get searchVersionChecking => 'Preverjanje te različice…';

  @override
  String get searchVersionUnavailable =>
      'Te različice ni mogoče uporabiti. Izberi drugo različico.';

  @override
  String get searchPreviewUnavailable => 'Predogled besedila ni na voljo.';

  @override
  String get searchSongMatch => 'Ujemanje pesmi';

  @override
  String get searchRecordingMatch => 'Ujemanje posnetka';

  @override
  String get searchMatchUnverified => 'Posnetek ni preverjen';

  @override
  String get searchMatchExact => 'Natančno ujemanje posnetka';

  @override
  String get searchMatchPossible => 'Možno ujemanje';

  @override
  String get searchAvailability => 'Razpoložljivost';

  @override
  String get searchLyricsAvailable => 'Besedilo pesmi je na voljo';

  @override
  String get searchLyricsUnavailable => 'Besedilo pesmi ni na voljo';

  @override
  String get searchChordsAvailable => 'Akordi so na voljo';

  @override
  String get searchChordsUnavailable => 'Ni akordov';

  @override
  String get searchTimingAvailable => 'Časovno usklajevanje je na voljo';

  @override
  String get searchTimingUnavailable => 'Časovno usklajevanje ni na voljo';

  @override
  String get searchDurationUnknown => 'Trajanje ni znano';

  @override
  String searchRating(String rating) {
    return 'Ocena $rating';
  }

  @override
  String get searchSourceLabel => 'Vir';

  @override
  String get searchPreferredSourceLabel => 'Prednostni vir';

  @override
  String get searchPreferredSourceHint =>
      'Rezultati so lahko tudi iz drugih omogočenih virov iskanja.';

  @override
  String get searchMetadata => 'Podatki o pesmi';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Izvajalec';

  @override
  String get searchYear => 'Leto';

  @override
  String get searchLanguage => 'Jezik';

  @override
  String get searchViewVersions => 'Prikaži različice';

  @override
  String get searchSaved => 'Pesem je shranjena v vaši knjižnici.';

  @override
  String get searchSaveOpenLyrics => 'Shrani in odpri besedilo';

  @override
  String get searchOtherResults => 'Drugi rezultati';

  @override
  String get searchSaveFailed => 'Pesmi ni bilo mogoče shraniti.';

  @override
  String get homeRecentSongs => 'Nedavne pesmi';

  @override
  String get homeRecentlyPlayed => 'Nedavno predvajano';

  @override
  String get homeFavorites => 'Priljubljeno';

  @override
  String get homeHistory => 'Zgodovina';

  @override
  String get homeHistoryClear => 'Počisti zgodovino';

  @override
  String get homeHistoryCleared => 'Zgodovina je počiščena.';

  @override
  String get homeHistoryEmpty => 'Tukaj bodo prikazane pesmi, ki jih odprete.';

  @override
  String get homeFavoritesEmpty =>
      'Tukaj bodo prikazane vaše priljubljene pesmi in koncertni seznami.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prikazanih je $count elementov',
      few: 'Prikazani so $count elementi',
      two: 'Prikazana sta $count elementa',
      one: 'Prikazan je $count element',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Tukaj bodo prikazane vaše nedavne pesmi in koncertni seznami.';

  @override
  String get homeTimelineLabel => 'Časovnica zgodovine';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Celotna zgodovina';

  @override
  String get homeShowFavorites => 'Pokaži priljubljeno';

  @override
  String get homeShowRecent => 'Pokaži nedavne';

  @override
  String get songsTitle => 'Pesmi';

  @override
  String get songsEmpty => 'Tukaj bodo prikazane vaše pesmi.';

  @override
  String get songsEmptySearch => 'Nobena pesem se ne ujema z iskanjem.';

  @override
  String get songsAdd => 'Dodaj pesem';

  @override
  String get songsSortAlphabetical => 'Razvrsti po abecedi';

  @override
  String get songsAlphabetNavigation => 'Kazalo pesmi';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-krat',
      few: '$count-krat',
      two: '$count-krat',
      one: '$count-krat',
    );
    return 'Odprto $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Dodaj med priljubljene';

  @override
  String get songFavoriteRemove => 'Odstrani iz priljubljenih';

  @override
  String get songMenuLabel => 'Dejanja za pesem';

  @override
  String get songInfo => 'Podatki o pesmi';

  @override
  String get setlistMenuLabel => 'Dejanja za koncertni seznam';

  @override
  String get songAddToSetlist => 'Dodaj na koncertni seznam';

  @override
  String get songCopyChordPro => 'Kopiraj ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Izbrišem pesem?';

  @override
  String get songDeleteConfirmMessage =>
      'Ta pesem bo odstranjena iz vaše knjižnice.';

  @override
  String get songDeleted => 'Pesem je izbrisana.';

  @override
  String get setlistsTitle => 'Koncertni seznami';

  @override
  String get setlistsEmpty =>
      'Ustvarite koncertni seznam za naslednjo vajo ali nastop.';

  @override
  String get setlistsEmptySearch =>
      'Noben koncertni seznam se ne ujema z iskanjem.';

  @override
  String get setlistCreate => 'Nov koncertni seznam';

  @override
  String get setlistNameHint => 'Ime koncertnega seznama';

  @override
  String get setlistNotes => 'Opombe';

  @override
  String get setlistEntryOverride =>
      'Tonacija in kapodaster za posamezno pesem';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pesmi',
      few: '$count pesmi',
      two: '$count pesmi',
      one: '$count pesem',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Vsaj $duration';
  }

  @override
  String get setlistDurationUnknown => 'Trajanje ni znano';

  @override
  String setlistActivity(String date) {
    return 'Zadnja dejavnost $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Ustvarjeno $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Urejeno $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Nazadnje predvajano $date';
  }

  @override
  String get setlistSongsEmpty => 'Na tem koncertnem seznamu še ni pesmi.';

  @override
  String get setlistAddSongs => 'Dodaj pesmi';

  @override
  String get setlistReorder => 'Spremeni vrstni red pesmi';

  @override
  String setlistMoveSongUp(String song) {
    return 'Premakni pesem »$song« navzgor';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Premakni pesem »$song« navzdol';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Odstrani pesem »$song« s koncertnega seznama';
  }

  @override
  String get setlistDuplicate => 'Podvoji koncertni seznam';

  @override
  String get setlistFavoriteAdd => 'Dodaj koncertni seznam med priljubljene';

  @override
  String get setlistFavoriteRemove =>
      'Odstrani koncertni seznam iz priljubljenih';

  @override
  String get setlistShare => 'Deli kot OpenSong';

  @override
  String get setlistSharePdf => 'Deli kot PDF';

  @override
  String get setlistPrint => 'Natisni';

  @override
  String get setlistDeleteConfirmTitle => 'Izbrišem koncertni seznam?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Koncertni seznam bo odstranjen. Pesmi v vaši knjižnici bodo ostale.';

  @override
  String get setlistDeleted => 'Koncertni seznam je izbrisan.';

  @override
  String get readerTitle => 'Besedila pesmi';

  @override
  String get readerNoLyrics => 'Besedilo pesmi še ni dodano.';

  @override
  String get readerShowChords => 'Pokaži akorde';

  @override
  String get readerHideChords => 'Skrij akorde';

  @override
  String get readerTranspose => 'Transponiraj akorde';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count poltonov',
      few: '$count poltone',
      two: '$count poltona',
      one: '$count polton',
    );
    return 'Transponiraj za $_temp0';
  }

  @override
  String get readerSaved => 'Shranjeno';

  @override
  String get readerEdit => 'Uredi besedilo pesmi in podatke';

  @override
  String get playerPlay => 'Predvajaj';

  @override
  String get playerPause => 'Ustavi';

  @override
  String get playerResume => 'Nadaljuj drsenje besedila pesmi';

  @override
  String get playerSeek => 'Položaj predvajanja';

  @override
  String playerElapsed(String time) {
    return 'Pretečeni čas $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Preostali čas $time';
  }

  @override
  String get playerTimingMode => 'Način drsenja';

  @override
  String get playerTimedLyrics => 'Časovno usklajena besedila';

  @override
  String get playerStartScroll => 'Začni samodejno drsenje';

  @override
  String get playerEstimatedPace => 'Ocenjena hitrost';

  @override
  String get playerScrollSpeed => 'Hitrost drsenja';

  @override
  String playerEstimatedDuration(String time) {
    return 'Predvideno trajanje: $time';
  }

  @override
  String get playerLyricsOnly => 'Drsenje besedila · brez zvoka';

  @override
  String get playerManualScroll => 'Ročno drsenje';

  @override
  String get playerTimingStatusReady =>
      'Besedilo pesmi se bo pomikalo glede na razpoložljive časovne oznake.';

  @override
  String get playerTimingStatusEstimated =>
      'Hitrost drsenja je ocenjena glede na trajanje pesmi.';

  @override
  String get playerTimingStatusManual => 'Besedilo pesmi pomikajte sami.';

  @override
  String get playerTimingStatusUnavailable =>
      'Časovno usklajeno drsenje za to pesem ni na voljo.';

  @override
  String get playerDurationUnknown =>
      'Dodajte trajanje pesmi, da uporabite ocenjeno drsenje.';

  @override
  String get playerProgressLabel => 'Potek pesmi';

  @override
  String get playerCurrentSection => 'Trenutni del';

  @override
  String get playerPreviousSection => 'Prejšnji del';

  @override
  String get playerNextSection => 'Naslednji del';

  @override
  String get playerPreviousSectionSong =>
      'Prejšnji del · pridržite za prejšnjo pesem na koncertnem seznamu';

  @override
  String get playerNextSectionSong =>
      'Naslednji del · pridržite za naslednjo pesem na koncertnem seznamu';

  @override
  String get playerPreviousSong => 'Prejšnja pesem';

  @override
  String get playerNextSong => 'Naslednja pesem';

  @override
  String get editorTitle => 'Uredi pesem';

  @override
  String get editorTitleField => 'Naslov pesmi';

  @override
  String get editorArtistField => 'Izvajalec';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Besedilo pesmi';

  @override
  String get editorChordsField => 'Akordi';

  @override
  String get editorKeyField => 'Tonacija';

  @override
  String get editorCapoField => 'Kapodaster';

  @override
  String get editorTuningField => 'Uglasitev';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Trajanje';

  @override
  String get editorTimeSignatureField => 'Taktovski način';

  @override
  String get editorLanguageField => 'Jezik';

  @override
  String get editorYearField => 'Leto';

  @override
  String get editorComposerField => 'Skladatelj';

  @override
  String get editorLyricistField => 'Avtor besedila';

  @override
  String get editorCopyrightField => 'Avtorske pravice';

  @override
  String get editorLicenseField => 'Licenca';

  @override
  String get songInfoSources => 'Viri in zasluge';

  @override
  String get searchMatchSameSong => 'Ista pesem; posnetek ni potrjen';

  @override
  String get searchMatchNeedsAgreement =>
      'Zapis akordov je treba potrditi z besedilom pesmi';

  @override
  String get searchMatchDifferentLyrics =>
      'Besedilo se razlikuje od izbrane pesmi';

  @override
  String get searchMatchCombinedSources => 'Podatki so združeni iz več virov';

  @override
  String get searchCombinedLabel => 'Združeno';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ujemanj pesmi',
      few: '$count ujemanja pesmi',
      two: '$count ujemanji pesmi',
      one: '$count ujemanje pesmi',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count različic vira',
      few: '$count različice vira',
      two: '$count različici vira',
      one: '$count različica vira',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Najboljše razpoložljivo ujemanje';

  @override
  String get providerDescriptionUnknown => 'Vir pesmi';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Prenesite datoteko ChordPro iz vira in jo nato uvozite.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Prenesite datoteko z brezplačnim računom in jo nato uvozite.';

  @override
  String get providerDescPublicChordSheets => 'Javno dostopni zapisi akordov.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Zgodovinska besedila so licencirana za vsako delo posebej.';

  @override
  String get providerDescLicensedCatalog => 'Licenciran katalog besedil pesmi.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Izvirne pesmi pod licenco Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Besedila pesmi so licencirana za vsako pesem posebej.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Samo podatki o posnetku in izdaji.';

  @override
  String get providerDescCompositionMetadataOnly => 'Samo podatki o skladbi.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Naslovnica je na voljo samo za natančna ujemanja posnetkov.';

  @override
  String get providerCapabilityLyrics => 'Besedila pesmi';

  @override
  String get providerCapabilityChords => 'Akordi';

  @override
  String get providerCapabilityTiming => 'Časovno usklajena besedila';

  @override
  String get providerCapabilitySearch => 'Iskanje';

  @override
  String get providerCapabilityMetadata => 'Podatki o pesmi';

  @override
  String get editorArtworkField => 'Povezava do naslovnice';

  @override
  String get editorLyricsHint =>
      'Akorde zapišite v oglatih oklepajih [C]; oznake delov naj bodo v ločenih vrsticah.';

  @override
  String get editorSave => 'Shrani spremembe';

  @override
  String get editorSaved => 'Spremembe so shranjene.';

  @override
  String get editorSaveFailed => 'Sprememb ni bilo mogoče shraniti.';

  @override
  String get editorSaveConflict =>
      'Pesem je bila spremenjena drugje. Vaši popravki so shranjeni kot ločena kopija.';

  @override
  String get editorUnsavedTitle => 'Zavržem spremembe?';

  @override
  String get editorUnsavedMessage => 'Vaši popravki niso shranjeni.';

  @override
  String get editorFieldRequired => 'Vnesite naslov pesmi.';

  @override
  String get settingsTitle => 'Nastavitve';

  @override
  String get settingsAppearance => 'Videz';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Uporabi nastavitev naprave';

  @override
  String get settingsThemeLight => 'Svetla';

  @override
  String get settingsThemeDark => 'Temna';

  @override
  String get settingsColorPalette => 'Barvna paleta';

  @override
  String get settingsFont => 'Pisava';

  @override
  String get settingsTextSize => 'Velikost besedila';

  @override
  String get settingsLyricsPreview => 'Predogled besedila pesmi';

  @override
  String get settingsPlayer => 'Predvajalnik besedil pesmi';

  @override
  String get settingsLyricHighlight => 'Poudarek trenutne vrstice';

  @override
  String get settingsHighlightBackgroundUnderline => 'Ozadje + podčrtaj';

  @override
  String get settingsHighlightBackground => 'Ozadje';

  @override
  String get settingsHighlightUnderline => 'Podčrtaj';

  @override
  String get settingsHighlightContrast => 'Kontrastna barva besedila';

  @override
  String get settingsHighlightNone => 'Brez';

  @override
  String get settingsDefaultShowChords => 'Privzeto pokaži akorde';

  @override
  String get settingsDefaultAutoscroll => 'Samodejno začni drsenje besedila';

  @override
  String get settingsDefaultTiming => 'Privzeti način drsenja';

  @override
  String get settingsLanguage => 'Jezik aplikacije';

  @override
  String get settingsLanguageSystem => 'Uporabi jezik naprave';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Viri besedil pesmi';

  @override
  String settingsSourceEnabled(String source) {
    return 'Omogoči vir $source';
  }

  @override
  String get settingsSourceRefresh => 'Osveži seznam virov';

  @override
  String get settingsSourcesUpdated => 'Viri so posodobljeni.';

  @override
  String get settingsSourcesUpdateFailed => 'Virov ni bilo mogoče osvežiti.';

  @override
  String get settingsImport => 'Uvozi pesmi';

  @override
  String get settingsImportChordPro => 'Uvozi datoteko ChordPro';

  @override
  String get settingsImportSetlist => 'Uvozi datoteko koncertnega seznama';

  @override
  String get settingsImportSuccess => 'Uvoz je končan.';

  @override
  String get settingsImportFailed => 'Te datoteke ni bilo mogoče uvoziti.';

  @override
  String get settingsImportUnsupported => 'Ta vrsta datoteke ni podprta.';

  @override
  String get settingsShareSong => 'Deli kot ChordPro';

  @override
  String get settingsSharePdf => 'Deli kot PDF';

  @override
  String get settingsCopySong => 'Kopiraj v odložišče';

  @override
  String get settingsPrintSong => 'Natisni samo pesem';

  @override
  String get settingsPrintSetlist => 'Natisni koncertni seznam z besedili';

  @override
  String get settingsExportFailed => 'Datoteke ni bilo mogoče pripraviti.';

  @override
  String get settingsCopied => 'Kopirano v odložišče.';

  @override
  String get settingsAbout => 'O aplikaciji';

  @override
  String get settingsPrivacy => 'Zasebnost';

  @override
  String get settingsLegal => 'Pravne informacije';

  @override
  String get settingsClearHistory => 'Počisti zgodovino';

  @override
  String get settingsClearHistoryConfirm =>
      'Počisti zgodovino nedavnih dejavnosti pesmi in koncertnih seznamov. Ohrani shranjene pesmi, priljubljene, koncertne sezname in nastavitve.';

  @override
  String get settingsHistoryCleared => 'Zgodovina je počiščena.';

  @override
  String get accountTitle => 'Račun in sinhronizacija';

  @override
  String get accountICloudBenefits =>
      'Z računom Apple lahko zasebno sinhronizirate pesmi in sezname skladb prek iClouda. Po vzpostavitvi povezave se spremembe sinhronizirajo samodejno.';

  @override
  String get accountICloudUnavailable =>
      'iCloud ni na voljo. V sistemskih nastavitvah preverite svoj račun Apple in dostop do iClouda ter poskusite znova.';

  @override
  String get accountConnectICloud => 'Poveži iCloud';

  @override
  String get accountDisconnectICloud => 'Prekini povezavo z iCloudom';

  @override
  String get accountUnavailable =>
      'Za sinhronizacijo je potrebna različica Singbook s konfigurirano prijavo prek storitve Google. Ta različica hrani pesmi samo v tej napravi.';

  @override
  String get accountSyncNow => 'Sinhroniziraj zdaj';

  @override
  String get accountConnected =>
      'Povezano. Izberite »Sinhroniziraj zdaj«, da posodobite varnostno kopijo.';

  @override
  String get accountSignIn => 'Poveži račun';

  @override
  String get accountSignOut => 'Odjavi se';

  @override
  String get accountChange => 'Zamenjaj račun';

  @override
  String get accountSignedOut => 'Ni povezano';

  @override
  String get accountSyncing => 'Sinhronizacija knjižnice…';

  @override
  String get accountSynced => 'Knjižnica je sinhronizirana.';

  @override
  String get accountSyncFailed => 'Knjižnice ni bilo mogoče sinhronizirati.';

  @override
  String get accessibilityFavorite => 'Priljubljeno';

  @override
  String get accessibilityNotFavorite => 'Ni priljubljeno';

  @override
  String get accessibilitySearchField => 'Iskanje pesmi';

  @override
  String get accessibilityClearSearch => 'Počisti besedilo iskanja';

  @override
  String accessibilitySongMenu(String song) {
    return 'Dejanja za pesem $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Dejanja za koncertni seznam $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Razširi pesmi na koncertnem seznamu $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Strni pesmi na koncertnem seznamu $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      percent,
      locale: localeName,
      other: '$percent odstotkov',
      few: '$percent odstotki',
      two: '$percent odstotka',
      one: '$percent odstotek',
    );
    return 'Potek predvajanja, $_temp0';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Časovnica zgodovine, $date';
  }

  @override
  String get loading => 'Nalaganje…';

  @override
  String get loadingSongs => 'Nalaganje pesmi…';

  @override
  String get loadingSetlists => 'Nalaganje koncertnih seznamov…';

  @override
  String get errorGeneric => 'Prišlo je do napake.';

  @override
  String get errorOffline => 'Videti je, da niste povezani.';

  @override
  String get errorPermission => 'Za nadaljevanje je potrebno dovoljenje.';

  @override
  String get emptyFiltered => 'Noben element se ne ujema s temi filtri.';

  @override
  String get unknownValue => 'Neznano';

  @override
  String get durationUnknown => 'Trajanje ni znano';

  @override
  String get metadataNotSet => 'Ni nastavljeno';

  @override
  String get dateToday => 'Danes';

  @override
  String get dateYesterday => 'Včeraj';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pesmi',
      few: '$count pesmi',
      two: '$count pesmi',
      one: '$count pesem',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Mornarsko modra';

  @override
  String get settingsPaletteSage => 'Žajbljevo zelena';

  @override
  String get settingsPaletteOcean => 'Oceanska';

  @override
  String get settingsPaletteClay => 'Glinena';

  @override
  String get settingsPalettePlum => 'Slivova';

  @override
  String get settingsFontSystem => 'Sistemska';

  @override
  String get settingsFontSerif => 'Serifna';

  @override
  String get settingsFontMonospace => 'Enakomerno široka';

  @override
  String get settingsLyricsPreviewExample => 'Ko pride jutro, bomo spet peli.';

  @override
  String get settingsPreviewSongTitle => 'Jutranja pesem';

  @override
  String get settingsPreviewArtist => 'Primer aranžmaja';

  @override
  String get settingsPreviewCurrentLine => 'Ko pride jutro';

  @override
  String get settingsPreviewNextLine => 'Spet bomo peli.';

  @override
  String get settingsPlayerSections => 'Naslovi razdelkov';

  @override
  String get settingsPlayerControls => 'Plošča za predvajanje';

  @override
  String get settingsPlayerAutoscroll => 'Samodejno pomikanje';

  @override
  String get settingsSystemShort => 'Naprava';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Preverjanje virov besedil pesmi: dokončano $checked od $total.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Ni najdenega uporabnega besedila pesmi.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Izbrana pesem je bila preverjena v omogočenih virih, vendar noben ni vrnil uporabne različice besedila.';

  @override
  String get searchDiscoveryError =>
      'Virov besedil pesmi ni bilo mogoče preveriti.';

  @override
  String get searchDiscoveryRetry => 'Znova poišči besedilo pesmi';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count virov ni na voljo',
      few: '$count viri niso na voljo',
      two: '$count vira nista na voljo',
      one: '$count vir ni na voljo',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Preverite povezavo in poskusite znova.';

  @override
  String get searchProviderChecks => 'Preverjanja virov';

  @override
  String get searchProviderPending => 'Preverjanje';

  @override
  String get searchProviderFound => 'Ujemanje je najdeno';

  @override
  String get searchProviderRejected => 'Se ne ujema';

  @override
  String get searchProviderFailed => 'Preverjanje ni uspelo';

  @override
  String get searchProviderUnavailable => 'Ni uporabnega besedila pesmi';

  @override
  String get searchCatalogFilterHint =>
      'Izberite pesem, da filtrirate različice besedila po akordih, časovnih oznakah ali jeziku.';

  @override
  String get startupErrorTitle => 'Knjižnice ni bilo mogoče odpreti.';

  @override
  String setlistCopyName(String name) {
    return 'Kopija: $name';
  }

  @override
  String get setlistSongMissing => 'Manjkajoča pesem';

  @override
  String get settingsImportTooLarge => 'Ta datoteka je prevelika za uvoz.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Pojdi na črko $letter';
  }

  @override
  String get actionDiscard => 'Zavrzi';

  @override
  String get editorKeepEditing => 'Nadaljuj urejanje';

  @override
  String get settingsDefaultShowChordsHint =>
      'Če pesem vsebuje akorde, so prikazani nad besedilom.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Besedilo se pomika skupaj s pesmijo. V načinu ročnega drsenja se ne uporablja.';

  @override
  String get accountUnavailableTitle => 'Sinhronizacija ni nastavljena';

  @override
  String get accountSignedOutBenefits =>
      'Ob povezavi z Google Drive se knjižnica sinhronizira. Spremembe pesmi se nato sinhronizirajo samodejno.';

  @override
  String get accountManualSyncHint =>
      'Knjižnico lahko sinhronizirate tudi tako, da tapnete Sinhroniziraj zdaj.';

  @override
  String get accountSignInWithGoogle => 'Prijava prek storitve Google';

  @override
  String get accountWorking => 'Obdelava…';

  @override
  String get accountNeverSynced => 'Še ni sinhronizirano';

  @override
  String get accountSyncedJustNow => 'Pravkar sinhronizirano';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinhronizirano pred $count minutami',
      few: 'Sinhronizirano pred $count minutami',
      two: 'Sinhronizirano pred $count minutama',
      one: 'Sinhronizirano pred $count minuto',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinhronizirano pred $count urami',
      few: 'Sinhronizirano pred $count urami',
      two: 'Sinhronizirano pred $count urama',
      one: 'Sinhronizirano pred $count uro',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinhronizirano pred $count dnevi',
      few: 'Sinhronizirano pred $count dnevi',
      two: 'Sinhronizirano pred $count dnevoma',
      one: 'Sinhronizirano pred $count dnevom',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spornih sprememb je shranjenih kot kopije',
      few: '$count sporne spremembe so shranjene kot kopije',
      two: '$count sporni spremembi sta shranjeni kot kopiji',
      one: '$count sporna sprememba je shranjena kot kopija',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Ista pesem ali koncertni seznam je bil urejen na dveh mestih. Nič ni izgubljeno: druga različica je shranjena kot ločena kopija.';

  @override
  String get accountReviewConflicts => 'Preglej kopije';

  @override
  String get songsConflictFilterActive => 'Prikazane so samo konfliktne kopije';

  @override
  String get songsConflictFilterClear => 'Prikaži vse pesmi';

  @override
  String get songsConflictBadge => 'Konfliktna kopija';

  @override
  String get songsConflictEmpty => 'Ni konfliktnih kopij.';

  @override
  String get accountAutoSync => 'Samodejna sinhronizacija';

  @override
  String get accountAutoSyncHint =>
      'Sinhronizacija se izvede po povezavi ter po dodajanju, urejanju ali odstranitvi pesmi.';

  @override
  String get accountDriveFolder => 'Mapa knjižnice Google Drive';

  @override
  String get accountPrivateDriveFolder => 'Zasebna mapa Singbook';

  @override
  String get accountChooseDriveFolder => 'Izberite mapo';

  @override
  String get accountDriveFolderMoveTitle =>
      'Želite premakniti svojo knjižnico Singbook?';

  @override
  String get accountDriveFolderMoveBody =>
      'Izberite vidno mapo Google Drive. Singbook bo tam kopiral in preveril vaše pesmi in sezname, preden preklopite nanj. Izvirne datoteke ostanejo na prejšnjem mestu kot varnostna kopija. Druge datoteke ostanejo same. Datoteke ChordPro, ki jih uvozite v to mapo, so sprejete za sinhronizacijo in prejmejo metapodatke Singbook.';

  @override
  String get accountImportChordPro => 'Uvozi ChordPro iz Drive';

  @override
  String get accountImportChordProHint =>
      'Izberite datoteke .cho, ki jih želite dodati v to knjižnico. Datoteke, ki so že v mapi, so sprejete; datoteke drugje se kopirajo sem.';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'Izbira mape Drive ni na voljo';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'V podprti napravi z izbirnikom Google Drive izberite vidno mapo Drive.';

  @override
  String get syncErrorDriveFolderMissing => 'Mapa Singbook Drive ni na voljo';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Ponovno izberite mapo ali jo obnovite v storitvi Google Drive.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook potrebuje dostop do te mape Drive';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Znova izberite mapo, da omogočite dostop, nato sinhronizirajte knjižnico.';

  @override
  String get syncErrorFolderMigration =>
      'Knjižnice še ni bilo mogoče preseliti';

  @override
  String get syncErrorFolderMigrationHint =>
      'Vaša prejšnja knjižnica je še vedno varna. Preverite povezavo in znova izberite mapo za ponovni poskus.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Najprej izberite vidno mapo Drive';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'Pred uvozom datotek iz storitve Drive je potrebna vidna mapa knjižnice.';

  @override
  String get accountSignOutTitle => 'Se želite odjaviti iz tega računa?';

  @override
  String get accountSignOutBody =>
      'Pesmi in koncertni seznami bodo ostali v tej napravi. Ne bodo varnostno kopirani ali sinhronizirani, dokler se znova ne prijavite.';

  @override
  String get accountUseDifferent => 'Uporabi drug račun';

  @override
  String get accountSignInAgain => 'Znova se prijavi';

  @override
  String get accountChooseAction => 'Izberite, kako želite nadaljevati';

  @override
  String get accountChangedTitle => 'Drug račun Google';

  @override
  String get accountChangedBody =>
      'Ta naprava je bila nazadnje sinhronizirana z drugim računom Google. Izberite, kaj naj se zgodi s pesmimi in koncertnimi seznami v tej napravi.';

  @override
  String get accountChangedMerge => 'Združi z novim računom';

  @override
  String get accountChangedMergeHint =>
      'Vse v tej napravi bo ohranjeno in dodano v novi račun.';

  @override
  String get accountChangedReplace => 'Zamenjaj s knjižnico novega računa';

  @override
  String get accountChangedReplaceHint =>
      'Pesmi v tej napravi, ki jih ni v novem računu, bodo odstranjene.';

  @override
  String get accountChangedSignOut => 'Prekliči in se odjavi';

  @override
  String get accountStatusSignedOut =>
      'Račun in sinhronizacija: niste prijavljeni';

  @override
  String get accountStatusSignedIn =>
      'Račun in sinhronizacija: prijavljeni ste';

  @override
  String get accountStatusSyncing =>
      'Račun in sinhronizacija: sinhronizacija poteka';

  @override
  String get accountStatusSynced =>
      'Račun in sinhronizacija: knjižnica je posodobljena';

  @override
  String get accountStatusError =>
      'Račun in sinhronizacija: težava, tapnite za pregled';

  @override
  String get accountNoticeConflicts =>
      'Nekatere pesmi so bile urejene na dveh mestih. Kopije so ohranjene.';

  @override
  String get accountNoticeSignedIn => 'Prijavljeni ste.';

  @override
  String get accountNoticeSignedOut =>
      'Odjavljeni ste. Pesmi ostanejo v tej napravi.';

  @override
  String get syncErrorNotConfigured =>
      'Sinhronizacija v tej različici ni nastavljena.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Uporabite različico Singbook s konfigurirano prijavo prek storitve Google.';

  @override
  String get syncErrorOAuthClientConfiguration =>
      'Google je zavrnil konfiguracijo prijave v tej različici.';

  @override
  String get syncErrorOAuthClientConfigurationHint =>
      'Preverite, ali nastavljeni ID OAuth pripada namiznemu odjemalcu Singbook.';

  @override
  String get syncErrorNotSignedIn => 'Niste prijavljeni.';

  @override
  String get syncErrorNotSignedInHint =>
      'Prijavite se za sinhronizacijo knjižnice.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google zahteva, da se znova prijavite.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Znova se prijavite za nadaljevanje sinhronizacije. Vaše pesmi so v tej napravi varne.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook nima dovoljenja za uporabo Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Znova se prijavite in ob pozivu dovolite dostop do Drive.';

  @override
  String get syncErrorRateLimited => 'Google trenutno omejuje število zahtev.';

  @override
  String get syncErrorRateLimitedHint =>
      'Počakajte nekaj minut in poskusite znova.';

  @override
  String get syncErrorStorageFull => 'Vaš Google Drive je poln.';

  @override
  String get syncErrorStorageFullHint =>
      'Sprostite prostor v Drive in poskusite znova.';

  @override
  String get syncErrorNetwork => 'Povezava s storitvijo Google ni uspela.';

  @override
  String get syncErrorNetworkHint =>
      'Preverite internetno povezavo in poskusite znova.';

  @override
  String get syncErrorAccountChanged => 'Uporabljen je bil drug račun Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Izberite, ali želite knjižnico te naprave združiti z njim ali jo zamenjati.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Sinhronizirana knjižnica je prevelika, da bi jo Singbook lahko obdelal.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Odstranite nekaj pesmi ali koncertnih seznamov iz sinhronizirane knjižnice in poskusite znova.';

  @override
  String get syncErrorSignInFailed => 'Prijava ni bila dokončana.';

  @override
  String get syncErrorSignInFailedHint => 'Poskusite se znova prijaviti.';

  @override
  String get syncErrorGeneric => 'Knjižnice ni bilo mogoče sinhronizirati.';

  @override
  String get syncErrorGenericHint =>
      'Poskusite znova čez nekaj trenutkov. Vaše pesmi so v tej napravi še vedno varne.';

  @override
  String get editorDurationInvalid =>
      'Vnesite sekunde ali minute in sekunde, na primer 3:45.';

  @override
  String get editorNumberInvalid => 'Vnesite število.';

  @override
  String get accountReplaceConfirmTitle => 'Izbrišem lokalne pesmi?';

  @override
  String get accountReplaceConfirmBody =>
      'Pesmi in koncertni seznami v tej napravi, ki jih ni v novem računu, bodo trajno izbrisani. Tega ni mogoče razveljaviti.';

  @override
  String get accountReplaceConfirmAction => 'Izbriši in zamenjaj';

  @override
  String get accountSuspiciousTitle =>
      'V storitvi Google Drive manjkajo elementi';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elementov, ki jih je ta naprava že sinhronizirala, manjka v storitvi Google Drive.',
      few:
          '$count elementi, ki jih je ta naprava že sinhronizirala, manjkajo v storitvi Google Drive.',
      two:
          '$count elementa, ki ju je ta naprava že sinhronizirala, manjkata v storitvi Google Drive.',
      one:
          '$count element, ki ga je ta naprava že sinhronizirala, manjka v storitvi Google Drive.',
    );
    return '$_temp0 To se lahko zgodi, če so bili podatki aplikacije izbrisani v nastavitvah Google. Nič še ni bilo izbrisano.';
  }

  @override
  String get accountSuspiciousDelete => 'Izbriši jih tudi tukaj';

  @override
  String get accountSuspiciousKeep => 'Obdrži pesmi in jih znova naloži';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Želite izbrisati $count elementov iz te naprave?',
      few: 'Želite izbrisati $count elemente iz te naprave?',
      two: 'Želite izbrisati $count elementa iz te naprave?',
      one: 'Želite izbrisati $count element iz te naprave?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Te pesmi in koncertni seznami bodo trajno izbrisani iz te naprave. Tega ni mogoče razveljaviti.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Izbriši iz te naprave';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'V storitvi Google Drive manjkajo elementi.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Nič ni bilo izbrisano. Izberite, ali jih želite izbrisati tudi tukaj ali znova naložiti.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive se je med sinhronizacijo spremenil.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Nič se ni izgubilo. Znova sinhronizirajte, da pridobite najnovejše spremembe.';

  @override
  String get syncErrorInvalidLocalData =>
      'Nekaterih podatkov v tej napravi ni bilo mogoče sinhronizirati.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Pesmi ali koncertnega seznama ni bilo mogoče prebrati. Uvozite ga ali znova ustvarite in nato sinhronizirajte.';

  @override
  String get syncErrorNoAccountChange =>
      'Ni spremembe računa, ki bi jo bilo treba razrešiti.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Znova sinhronizirajte za nadaljevanje.';

  @override
  String get accountSyncWarningTitle =>
      'Sinhronizacija je končana, nekatere datoteke so izpuščene';

  @override
  String get accountSyncWarningBody =>
      'Nekaterih datotek ni bilo mogoče uporabiti, zato so ostale nespremenjene. Vse drugo je posodobljeno.';

  @override
  String get accountSyncWarningTooLarge =>
      'Datoteka je bila prevelika za sinhronizacijo in je izpuščena. Vse drugo je posodobljeno.';

  @override
  String get accountSyncWarningInvalid =>
      'Datoteke ni bilo mogoče prebrati, zato je izpuščena. Vse drugo je posodobljeno.';

  @override
  String get accountNoticeSyncSkipped =>
      'Sinhronizirano. Nekatere datoteke so izpuščene.';

  @override
  String get settingsExportPdfTooLarge =>
      'Ta PDF bi bil prevelik. Poskusite z manj pesmimi ali ga delite kot besedilo.';

  @override
  String get settingsTimingTooLarge =>
      'Podatki o časovnih oznakah so preveliki (več kot 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Ta varnostna kopija navaja isto pesem dvakrat, zato ni bilo uvoženo nič.';

  @override
  String get setlistSaveConflict =>
      'Koncertni seznam je bil spremenjen drugje. Vaše spremembe so shranjene v ločeni kopiji.';

  @override
  String get sectionVerse => 'Kitica';

  @override
  String get sectionChorus => 'Refren';

  @override
  String get sectionBridge => 'Most';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pred refrenom';

  @override
  String get sectionPostChorus => 'Po refrenu';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Medigra';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Pripev';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Koda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Zaključek';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dostupnih verzija',
      few: '$count dostupne verzije',
      one: '$count različica je na voljo',
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
      one: '$count različica ni na voljo',
      zero: 'Nema nedostupnih verzija',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Pojdi na razdelek';

  @override
  String get searchVersionDetails => 'Podrobnosti različice';

  @override
  String get searchSelectedRecording => 'Izbrani posnetek';

  @override
  String get searchVersionDuration => 'Trajanje različice';

  @override
  String get searchSourceOptions => 'Možnosti vira';

  @override
  String get actionUndo => 'Razveljavi';

  @override
  String setlistEntryRemoved(String song) {
    return 'Pesem »$song« je odstranjena s seznama';
  }

  @override
  String get backupTitle => 'Varnostno kopiranje in obnovitev';

  @override
  String get backupExport => 'Izvozi varnostno kopijo';

  @override
  String get backupRestore => 'Obnovi varnostno kopijo';

  @override
  String get backupIncludePreferences => 'Vključi nastavitve aplikacije';

  @override
  String get backupRestorePreferences => 'Obnovi nastavitve aplikacije';

  @override
  String get backupMerge => 'Dodaj v to knjižnico';

  @override
  String get backupMergeHint =>
      'Ohrani lokalne spremembe in dodaj pesmi ter sezname iz te varnostne kopije.';

  @override
  String get backupReplace => 'Zamenjaj to knjižnico';

  @override
  String get backupReplaceHint =>
      'Zamenjaj vse pesmi in sezname v tej napravi z vsebino varnostne kopije.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Pesmi: $songs · Seznami: $setlists · Spori: $conflicts';
  }

  @override
  String get backupFailed =>
      'Operacije ni bilo mogoče dokončati. Poskusi znova.';

  @override
  String get backupRestored => 'Varnostna kopija je obnovljena.';

  @override
  String get backupLocalHint =>
      'Shrani kopijo knjižnice. Podatki računa in piškotki soglasja niso nikoli vključeni.';

  @override
  String get backupReplaceConfirm =>
      'Zamenjam trenutno knjižnico? Tega ni mogoče razveljaviti.';

  @override
  String get searchCheckOperations => 'Operacije';

  @override
  String get searchCheckCode => 'Koda rezultata';

  @override
  String get searchCheckQueued => 'Čakanje na preverjanje tega vira.';

  @override
  String get searchCheckFetch => 'Naloži besedilo pesmi';

  @override
  String get searchCheckValidate => 'Preveri ujemanje pesmi';

  @override
  String get searchCheckCorroborate => 'Preveri ujemanje besedila';

  @override
  String get searchCheckCompleted => 'Dokončano';

  @override
  String get searchCheckTimeout => 'Vir se ni odzval pravočasno.';

  @override
  String get searchCheckBlocked => 'Vir je blokiral zahtevo.';

  @override
  String get searchCheckRateLimited =>
      'Vir omejuje zahteve. Poskusite znova pozneje.';

  @override
  String get searchCheckNetwork => 'Vira ni mogoče doseči. Preverite povezavo.';

  @override
  String get searchCheckInvalid => 'Vir je vrnil neberljiv odgovor.';

  @override
  String get searchCheckNotConfigured =>
      'Ta vir v tej različici ni konfiguriran.';

  @override
  String get searchCheckNoLyrics => 'Ustrezno besedilo pesmi ni bilo najdeno.';

  @override
  String get searchCheckFailed => 'Tega postopka ni bilo mogoče dokončati.';

  @override
  String get searchCheckNoHistory =>
      'Za to primerjavo niso bila izvedena preverjanja virov.';

  @override
  String get searchVersionCredits => 'Zasluge';

  @override
  String get searchVersionMediaLinks => 'Sorodne povezave';

  @override
  String get searchCheckCancelled => 'Preklicano';

  @override
  String get searchCheckAmbiguous =>
      'Najdenih je bilo več ujemanj. Ta vir potrebuje natančnejši posnetek.';

  @override
  String get searchCheckIdentity =>
      'Ta vir potrebuje identifikator posnetka ali dela.';

  @override
  String get searchCheckExtraction =>
      'Vir se je odzval, vendar besedila pesmi ni bilo mogoče pridobiti.';

  @override
  String get searchCheckBusy => 'Vir je zaseden. Poskusite znova pozneje.';

  @override
  String get searchCheckSelection => 'Izberite določen rezultat iz tega vira.';

  @override
  String get playerChordsNone => 'Brez';

  @override
  String get editorCustomValue => 'Drugo…';

  @override
  String get editorStandardTuning => 'Standardna uglasitev';

  @override
  String get editorExampleVerse =>
      '[C]Nov dan nas [G]kliče,\n[Am]sledimo svetlobi nazaj [F]domov.';

  @override
  String get editorExampleChorus =>
      '[F]Zapojmo to pesem [C]skupaj,\n[G]naj nas melodija ponese [C]naprej.';

  @override
  String get editorExampleBridge => '[Am]Še ena vrstica, malo [F]bliže.';

  @override
  String get playerEstimatedKey => 'Ocenjena tonaliteta';

  @override
  String get songsLibraryView => 'Knjižnica';

  @override
  String get settingsStartupView => 'Začni v';

  @override
  String get settingsStartupViewHint =>
      'Izberite pogled Pesmi, ki se prikaže ob odprtju aplikacije.';

  @override
  String get settingsStartupLastView => 'Nazadnje odprto';

  @override
  String get playerFullScreen => 'Celoten zaslon';

  @override
  String get playerExitFullScreen => 'Izhod iz celotnega zaslona';

  @override
  String get playerExpandControls => 'Prikaži kontrolnike predvajanja';

  @override
  String get playerCollapseControls => 'Skrij kontrolnike predvajanja';

  @override
  String get settingsShowSections => 'Prikaži naslove razdelkov';

  @override
  String get settingsShowSectionsHint =>
      'V besedilu prikaži naslove kitic, refrena in drugih razdelkov.';

  @override
  String get settingsShowPlayerControls => 'Prikaži kontrolnike predvajanja';

  @override
  String get settingsShowPlayerControlsHint =>
      'Ploščo predvajalnika lahko prikažete ali skrijete tudi z dotikom ali podrsanjem.';

  @override
  String get sourceAnalysisHeading => 'Analiza poslanega zvoka (nepreverjena)';

  @override
  String sourceAnalysisCoverage(int shown, int total) {
    return 'Prikazanih je $shown od $total poslanih prispevkov';
  }

  @override
  String sourceAnalysisSample(int number) {
    return 'Vzorec $number';
  }

  @override
  String get sourceAnalysisEstimatedTempo => 'Ocenjeni tempo (BPM)';
}
