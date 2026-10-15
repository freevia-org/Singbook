// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lithuanian (`lt`).
class AppLocalizationsLt extends AppLocalizations {
  AppLocalizationsLt([String locale = 'lt']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Rami vieta, kurioje galite rasti dainas, tvarkyti jų rinkinį ir dainuoti kartu.';

  @override
  String get aboutMadeForSinging => 'Sukurta dainuoti kartu';

  @override
  String appVersion(String version) {
    return 'Versija $version';
  }

  @override
  String get navHome => 'Pradžia';

  @override
  String get navSongs => 'Dainos';

  @override
  String get navSetlists => 'Sąrašai';

  @override
  String get navSettings => 'Nustatymai';

  @override
  String get navSettingsCompact => 'Nustatymai';

  @override
  String get navSearch => 'Paieška';

  @override
  String get navBack => 'Atgal';

  @override
  String get navClose => 'Uždaryti';

  @override
  String get navMore => 'Daugiau veiksmų';

  @override
  String get actionCancel => 'Atšaukti';

  @override
  String get actionSave => 'Išsaugoti';

  @override
  String get actionDone => 'Atlikta';

  @override
  String get actionEdit => 'Redaguoti';

  @override
  String get actionDelete => 'Ištrinti';

  @override
  String get actionShare => 'Bendrinti';

  @override
  String get actionPrint => 'Spausdinti';

  @override
  String get actionCopy => 'Kopijuoti';

  @override
  String get actionClear => 'Išvalyti';

  @override
  String get actionRetry => 'Bandyti dar kartą';

  @override
  String get actionRefresh => 'Atnaujinti';

  @override
  String get actionImport => 'Importuoti';

  @override
  String get actionExport => 'Eksportuoti';

  @override
  String get actionExpand => 'Išskleisti';

  @override
  String get actionCollapse => 'Suskleisti';

  @override
  String get actionAdd => 'Pridėti';

  @override
  String get actionCreate => 'Sukurti';

  @override
  String get actionRemove => 'Pašalinti';

  @override
  String get actionDuplicate => 'Dubliuoti';

  @override
  String get actionMoveUp => 'Perkelti aukštyn';

  @override
  String get actionMoveDown => 'Perkelti žemyn';

  @override
  String get actionPrevious => 'Ankstesnis';

  @override
  String get actionNext => 'Kitas';

  @override
  String get searchHint => 'Ieškoti dainų, atlikėjų arba dainų tekstų';

  @override
  String get searchCatalogHint => 'Ieškoti dainos arba atlikėjo';

  @override
  String get searchChangeSong => 'Keisti dainą';

  @override
  String get searchSelectedPreview => 'Pasirinkta peržiūra';

  @override
  String get searchSubmit => 'Ieškoti';

  @override
  String get searchFilters => 'Paieškos parinktys';

  @override
  String get searchFiltersShow => 'Rodyti paieškos parinktis';

  @override
  String get searchFiltersHide => 'Slėpti paieškos parinktis';

  @override
  String get searchFilterArtist => 'Atlikėjas';

  @override
  String get searchFilterTitle => 'Dainos pavadinimas';

  @override
  String get searchFilterLyrics => 'Dainų tekstai';

  @override
  String get searchFilterChords => 'Yra akordai';

  @override
  String get searchFilterTimed => 'Dainų tekstai su laiko žymomis';

  @override
  String get searchFilterLanguage => 'Kalba';

  @override
  String get searchFilterAll => 'Bet kuri';

  @override
  String get searchAutocompleteLabel => 'Pasiūlymai';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rezultatų',
      many: '$count rezultatų',
      few: '$count rezultatai',
      one: '$count rezultatas',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Įveskite dainą, atlikėją ar dainos eilutę paieškai.';

  @override
  String get searchCatalogEmptyQuery =>
      'Įveskite dainą arba atlikėją paieškai.';

  @override
  String get searchNoResults => 'Dainų nerasta. Pabandykite pakeisti paiešką.';

  @override
  String get searchLoading => 'Ieškoma dainų…';

  @override
  String get searchError => 'Nepavyko atlikti paieškos.';

  @override
  String get searchOnlineTab => 'Internetu';

  @override
  String get searchRecentTab => 'Naujausios';

  @override
  String get searchFavoritesTab => 'Mėgstamos';

  @override
  String get searchSuggested => 'Siūlomas atitikmuo';

  @override
  String get searchAlternatives => 'Kiti atitikmenys';

  @override
  String get searchCompare => 'Palyginti versijas';

  @override
  String get searchChooseVersion => 'Pasirinkti šią versiją';

  @override
  String get searchSongMatch => 'Dainos atitikmuo';

  @override
  String get searchRecordingMatch => 'Įrašo atitikmuo';

  @override
  String get searchMatchUnverified => 'Įrašas nepatvirtintas';

  @override
  String get searchMatchExact => 'Tikslus įrašo atitikmuo';

  @override
  String get searchMatchPossible => 'Galimas atitikmuo';

  @override
  String get searchAvailability => 'Prieinamumas';

  @override
  String get searchLyricsAvailable => 'Dainų tekstai prieinami';

  @override
  String get searchLyricsUnavailable => 'Dainų tekstai neprieinami';

  @override
  String get searchChordsAvailable => 'Akordai prieinami';

  @override
  String get searchChordsUnavailable => 'Akordų nėra';

  @override
  String get searchTimingAvailable => 'Laiko žymos yra';

  @override
  String get searchTimingUnavailable => 'Laiko žymų nėra';

  @override
  String get searchDurationUnknown => 'Trukmė nežinoma';

  @override
  String searchRating(String rating) {
    return 'Įvertinimas $rating';
  }

  @override
  String get searchSourceLabel => 'Šaltinis';

  @override
  String get searchMetadata => 'Dainos informacija';

  @override
  String get searchAlbum => 'Albumas';

  @override
  String get searchArtist => 'Atlikėjas';

  @override
  String get searchYear => 'Metai';

  @override
  String get searchLanguage => 'Kalba';

  @override
  String get searchViewVersions => 'Peržiūrėti versijas';

  @override
  String get searchSaved => 'Daina išsaugota jūsų bibliotekoje.';

  @override
  String get searchSaveOpenLyrics => 'Išsaugoti ir atverti žodžius';

  @override
  String get searchOtherResults => 'Kiti rezultatai';

  @override
  String get searchSaveFailed => 'Nepavyko išsaugoti dainos.';

  @override
  String get homeRecentSongs => 'Naujausios dainos';

  @override
  String get homeRecentlyPlayed => 'Neseniai grotos';

  @override
  String get homeFavorites => 'Mėgstamos';

  @override
  String get homeHistory => 'Istorija';

  @override
  String get homeHistoryClear => 'Išvalyti istoriją';

  @override
  String get homeHistoryCleared => 'Istorija išvalyta.';

  @override
  String get homeHistoryEmpty => 'Čia bus rodomos jūsų atvertos dainos.';

  @override
  String get homeFavoritesEmpty =>
      'Čia bus rodomos mėgstamos dainos ir koncertinės programos.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rodoma $count elementų',
      many: 'Rodoma $count elementų',
      few: 'Rodomi $count elementai',
      one: 'Rodomas $count elementas',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Čia bus rodomos naujausios dainos ir koncertinės programos.';

  @override
  String get homeTimelineLabel => 'Istorijos laiko juosta';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Visa istorija';

  @override
  String get homeShowFavorites => 'Rodyti mėgstamas';

  @override
  String get homeShowRecent => 'Rodyti naujausias';

  @override
  String get songsTitle => 'Dainos';

  @override
  String get songsEmpty => 'Čia bus rodomos jūsų dainos.';

  @override
  String get songsEmptySearch => 'Nė viena daina neatitinka paieškos.';

  @override
  String get songsAdd => 'Pridėti dainą';

  @override
  String get songsSortAlphabetical => 'Rikiuoti pagal abėcėlę';

  @override
  String get songsAlphabetNavigation => 'Dainų rodyklė';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kartų',
      many: '$count kartų',
      few: '$count kartus',
      one: '$count kartą',
    );
    return 'Atverta $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Pridėti prie mėgstamų';

  @override
  String get songFavoriteRemove => 'Pašalinti iš mėgstamų';

  @override
  String get songMenuLabel => 'Dainos veiksmai';

  @override
  String get songInfo => 'Dainos informacija';

  @override
  String get setlistMenuLabel => 'Koncertinės programos veiksmai';

  @override
  String get songAddToSetlist => 'Pridėti prie koncertinės programos';

  @override
  String get songCopyChordPro => 'Kopijuoti ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Ištrinti dainą?';

  @override
  String get songDeleteConfirmMessage =>
      'Ši daina bus pašalinta iš jūsų bibliotekos.';

  @override
  String get songDeleted => 'Daina ištrinta.';

  @override
  String get setlistsTitle => 'Koncertinės programos';

  @override
  String get setlistsEmpty =>
      'Sukurkite koncertinę programą kitai repeticijai ar pasirodymui.';

  @override
  String get setlistsEmptySearch =>
      'Nė viena koncertinė programa neatitinka paieškos.';

  @override
  String get setlistCreate => 'Nauja koncertinė programa';

  @override
  String get setlistNameHint => 'Koncertinės programos pavadinimas';

  @override
  String get setlistNotes => 'Pastabos';

  @override
  String get setlistEntryOverride =>
      'Atskiras dainos tonacijos ir kapodastro nustatymas';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dainų',
      many: '$count dainų',
      few: '$count dainos',
      one: '$count daina',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Bent $duration';
  }

  @override
  String get setlistDurationUnknown => 'Trukmė nežinoma';

  @override
  String setlistActivity(String date) {
    return 'Paskutinė veikla $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Sukurta $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Redaguota $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Paskutinį kartą grota $date';
  }

  @override
  String get setlistSongsEmpty =>
      'Šioje koncertinėje programoje dar nėra dainų.';

  @override
  String get setlistAddSongs => 'Pridėti dainų';

  @override
  String get setlistReorder => 'Keisti dainų tvarką';

  @override
  String setlistMoveSongUp(String song) {
    return 'Perkelti dainą „$song“ aukštyn';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Perkelti dainą „$song“ žemyn';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Pašalinti dainą „$song“ iš koncertinės programos';
  }

  @override
  String get setlistDuplicate => 'Dubliuoti koncertinę programą';

  @override
  String get setlistFavoriteAdd => 'Pridėti koncertinę programą prie mėgstamų';

  @override
  String get setlistFavoriteRemove =>
      'Pašalinti koncertinę programą iš mėgstamų';

  @override
  String get setlistShare => 'Bendrinti kaip koncertinės programos failą';

  @override
  String get setlistSharePdf => 'Bendrinti kaip PDF';

  @override
  String get setlistPrint => 'Spausdinti';

  @override
  String get setlistDeleteConfirmTitle => 'Ištrinti koncertinę programą?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Koncertinė programa bus pašalinta. Bibliotekoje esančios dainos liks.';

  @override
  String get setlistDeleted => 'Koncertinė programa ištrinta.';

  @override
  String get readerTitle => 'Dainų tekstai';

  @override
  String get readerNoLyrics => 'Dainos tekstas dar nepridėtas.';

  @override
  String get readerShowChords => 'Rodyti akordus';

  @override
  String get readerHideChords => 'Slėpti akordus';

  @override
  String get readerTranspose => 'Transponuoti akordus';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pustonių',
      many: '$count pustonių',
      few: '$count pustonius',
      one: '$count pustonį',
    );
    return 'Transponuoti per $_temp0';
  }

  @override
  String get readerSaved => 'Išsaugota';

  @override
  String get readerEdit => 'Redaguoti dainos tekstą ir informaciją';

  @override
  String get playerPlay => 'Pradėti slinkti dainos tekstą';

  @override
  String get playerPause => 'Pristabdyti dainos teksto slinkimą';

  @override
  String get playerResume => 'Tęsti dainos teksto slinkimą';

  @override
  String get playerSeek => 'Atkūrimo vieta';

  @override
  String playerElapsed(String time) {
    return 'Praėjęs laikas $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Liko laiko $time';
  }

  @override
  String get playerTimingMode => 'Slinkimo režimas';

  @override
  String get playerTimedLyrics => 'Dainų tekstai su laiko žymomis';

  @override
  String get playerStartScroll => 'Pradėti automatinį slinkimą';

  @override
  String get playerEstimatedPace => 'Numatomas tempas';

  @override
  String get playerScrollSpeed => 'Slinkimo greitis';

  @override
  String playerEstimatedDuration(String time) {
    return 'Numatoma trukmė: $time';
  }

  @override
  String get playerLyricsOnly => 'Dainos žodžių slinkimas · be garso';

  @override
  String get playerManualScroll => 'Rankinis slinkimas';

  @override
  String get playerTimingStatusReady =>
      'Dainos tekstas slinks pagal turimas laiko žymas.';

  @override
  String get playerTimingStatusEstimated =>
      'Slinkimo tempas apskaičiuotas pagal dainos trukmę.';

  @override
  String get playerTimingStatusManual => 'Slinkite dainos tekstą patys.';

  @override
  String get playerTimingStatusUnavailable =>
      'Šiai dainai slinkimas pagal laiko žymas negalimas.';

  @override
  String get playerDurationUnknown =>
      'Įveskite dainos trukmę, kad būtų galima naudoti numatomą slinkimą.';

  @override
  String get playerProgressLabel => 'Dainos eiga';

  @override
  String get playerCurrentSection => 'Dabartinė dalis';

  @override
  String get playerPreviousSection => 'Ankstesnė dalis';

  @override
  String get playerNextSection => 'Kita dalis';

  @override
  String get playerPreviousSectionSong =>
      'Ankstesnė dalis · palaikykite, kad pereitumėte prie ankstesnės programos dainos';

  @override
  String get playerNextSectionSong =>
      'Kita dalis · palaikykite, kad pereitumėte prie kitos programos dainos';

  @override
  String get playerPreviousSong => 'Ankstesnė daina';

  @override
  String get playerNextSong => 'Kita daina';

  @override
  String get editorTitle => 'Redaguoti dainą';

  @override
  String get editorTitleField => 'Dainos pavadinimas';

  @override
  String get editorArtistField => 'Atlikėjas';

  @override
  String get editorAlbumField => 'Albumas';

  @override
  String get editorLyricsField => 'Dainos tekstas';

  @override
  String get editorChordsField => 'Akordai';

  @override
  String get editorKeyField => 'Tonacija';

  @override
  String get editorCapoField => 'Kapodastro padėtis';

  @override
  String get editorTuningField => 'Derinimas';

  @override
  String get editorTempoField => 'Tempas';

  @override
  String get editorDurationField => 'Trukmė';

  @override
  String get editorTimeSignatureField => 'Metras';

  @override
  String get editorLanguageField => 'Kalba';

  @override
  String get editorYearField => 'Metai';

  @override
  String get editorComposerField => 'Kompozitorius';

  @override
  String get editorLyricistField => 'Dainos teksto autorius';

  @override
  String get editorCopyrightField => 'Autorių teisės';

  @override
  String get editorLicenseField => 'Licencija';

  @override
  String get songInfoSources => 'Šaltiniai ir autorių informacija';

  @override
  String get searchMatchSameSong => 'Ta pati daina; įrašas nepatvirtintas';

  @override
  String get searchMatchNeedsAgreement =>
      'Akordų įrašą reikia patvirtinti pagal dainos tekstą';

  @override
  String get searchMatchDifferentLyrics =>
      'Dainos tekstas skiriasi nuo pasirinktos dainos';

  @override
  String get searchMatchCombinedSources =>
      'Informacija sujungta iš kelių šaltinių';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sujungta iš $count šaltinių',
      many: 'Sujungta iš $count šaltinių',
      few: 'Sujungta iš $count šaltinių',
      one: 'Sujungta iš $count šaltinio',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dainų atitikmenų',
      many: '$count dainų atitikmenų',
      few: '$count dainų atitikmenys',
      one: '$count dainos atitikmuo',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šaltinio versijų',
      many: '$count šaltinio versijų',
      few: '$count šaltinio versijos',
      one: '$count šaltinio versija',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Geriausias galimas atitikmuo';

  @override
  String get providerDescriptionUnknown => 'Dainos šaltinis';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Atsisiųskite ChordPro failą iš šaltinio, tada jį importuokite.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Atsisiųskite failą naudodami nemokamą paskyrą, tada jį importuokite.';

  @override
  String get providerDescPublicChordSheets => 'Viešai prieinami akordų įrašai.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Istoriniai dainų tekstai licencijuojami kiekvienam kūriniui.';

  @override
  String get providerDescLicensedCatalog =>
      'Licencijuotas dainų tekstų katalogas.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Originalios dainos pagal Creative Commons BY licenciją.';

  @override
  String get providerDescPerSongLicense =>
      'Dainų tekstai licencijuojami kiekvienai dainai atskirai.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Tik įrašo ir leidimo informacija.';

  @override
  String get providerDescCompositionMetadataOnly => 'Tik kūrinio informacija.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Viršelio vaizdas pateikiamas tik tiksliai sutapus įrašui.';

  @override
  String get providerCapabilityLyrics => 'Dainų tekstai';

  @override
  String get providerCapabilityChords => 'Akordai';

  @override
  String get providerCapabilityTiming => 'Laiko žymos';

  @override
  String get providerCapabilitySearch => 'Paieška';

  @override
  String get providerCapabilityMetadata => 'Dainos informacija';

  @override
  String get editorArtworkField => 'Viršelio nuoroda';

  @override
  String get editorLyricsHint =>
      'Palieskite eilutę, kad redaguotumėte tekstą arba akordus.';

  @override
  String get editorSave => 'Išsaugoti pakeitimus';

  @override
  String get editorSaved => 'Pakeitimai išsaugoti.';

  @override
  String get editorSaveFailed => 'Nepavyko išsaugoti pakeitimų.';

  @override
  String get editorSaveConflict =>
      'Daina buvo pakeista kitoje vietoje. Jūsų pakeitimai išsaugoti kaip atskira kopija.';

  @override
  String get editorUnsavedTitle => 'Atmesti pakeitimus?';

  @override
  String get editorUnsavedMessage => 'Jūsų pakeitimai neišsaugoti.';

  @override
  String get editorFieldRequired => 'Įveskite dainos pavadinimą.';

  @override
  String get settingsTitle => 'Nustatymai';

  @override
  String get settingsAppearance => 'Išvaizda';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Naudoti įrenginio nustatymą';

  @override
  String get settingsThemeLight => 'Šviesi';

  @override
  String get settingsThemeDark => 'Tamsi';

  @override
  String get settingsColorPalette => 'Spalvų paletė';

  @override
  String get settingsFont => 'Šriftas';

  @override
  String get settingsTextSize => 'Teksto dydis';

  @override
  String get settingsLyricsPreview => 'Dainos teksto peržiūra';

  @override
  String get settingsPlayer => 'Dainų tekstų grotuvas';

  @override
  String get settingsDefaultShowChords =>
      'Pagal numatytuosius nustatymus rodyti akordus';

  @override
  String get settingsDefaultAutoscroll =>
      'Automatiškai pradėti slinkti dainos tekstą';

  @override
  String get settingsDefaultTiming => 'Numatytasis slinkimo režimas';

  @override
  String get settingsLanguage => 'Programos kalba';

  @override
  String get settingsLanguageSystem => 'Naudoti įrenginio kalbą';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Dainų tekstų šaltiniai';

  @override
  String settingsSourceEnabled(String source) {
    return 'Įjungti šaltinį $source';
  }

  @override
  String get settingsSourceRefresh => 'Atnaujinti šaltinių sąrašą';

  @override
  String get settingsSourcesUpdated => 'Šaltiniai atnaujinti.';

  @override
  String get settingsSourcesUpdateFailed => 'Nepavyko atnaujinti šaltinių.';

  @override
  String get settingsImport => 'Importuoti dainas';

  @override
  String get settingsImportChordPro => 'Importuoti ChordPro failą';

  @override
  String get settingsImportSetlist => 'Importuoti koncertinės programos failą';

  @override
  String get settingsImportSuccess => 'Importavimas baigtas.';

  @override
  String get settingsImportFailed => 'Nepavyko importuoti šio failo.';

  @override
  String get settingsImportUnsupported => 'Šio tipo failas nepalaikomas.';

  @override
  String get settingsShareSong => 'Bendrinti kaip ChordPro';

  @override
  String get settingsSharePdf => 'Bendrinti kaip PDF';

  @override
  String get settingsCopySong => 'Kopijuoti į iškarpinę';

  @override
  String get settingsPrintSong => 'Spausdinti tik dainą';

  @override
  String get settingsPrintSetlist =>
      'Spausdinti koncertinę programą su dainų tekstais';

  @override
  String get settingsExportFailed => 'Nepavyko paruošti failo.';

  @override
  String get settingsCopied => 'Nukopijuota į iškarpinę.';

  @override
  String get settingsAbout => 'Apie programą';

  @override
  String get settingsPrivacy => 'Privatumas';

  @override
  String get settingsLegal => 'Teisinė informacija';

  @override
  String get settingsClearHistory => 'Išvalyti istoriją';

  @override
  String get settingsClearHistoryConfirm =>
      'Išvalyti dainų ir koncertinių programų istoriją?';

  @override
  String get settingsHistoryCleared => 'Istorija išvalyta.';

  @override
  String get accountTitle => 'Paskyra ir sinchronizavimas';

  @override
  String get accountUnavailable =>
      'Sinchronizavimui reikalinga Singbook versija, kurioje sukonfigūruotas prisijungimas per Google. Šioje versijoje dainos saugomos tik šiame įrenginyje.';

  @override
  String get accountSyncNow => 'Sinchronizuoti dabar';

  @override
  String get accountConnected =>
      'Prisijungta. Pasirinkite „Sinchronizuoti dabar“, kad atnaujintumėte atsarginę kopiją.';

  @override
  String get accountSignIn => 'Prijungti paskyrą';

  @override
  String get accountSignOut => 'Atsijungti';

  @override
  String get accountChange => 'Pakeisti paskyrą';

  @override
  String get accountSignedOut => 'Neprisijungta';

  @override
  String get accountSyncing => 'Sinchronizuojama jūsų biblioteka…';

  @override
  String get accountSynced => 'Biblioteka sinchronizuota.';

  @override
  String get accountSyncFailed => 'Nepavyko sinchronizuoti bibliotekos.';

  @override
  String get accessibilityFavorite => 'Mėgstama';

  @override
  String get accessibilityNotFavorite => 'Nėra mėgstama';

  @override
  String get accessibilitySearchField => 'Ieškoti dainų';

  @override
  String get accessibilityClearSearch => 'Išvalyti paieškos tekstą';

  @override
  String accessibilitySongMenu(String song) {
    return 'Dainos „$song“ veiksmai';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Koncertinės programos „$setlist“ veiksmai';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Išskleisti koncertinės programos „$setlist“ dainas';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Suskleisti koncertinės programos „$setlist“ dainas';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Atkūrimo eiga, $percent proc.';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Istorijos laiko juosta, $date';
  }

  @override
  String get loading => 'Įkeliama…';

  @override
  String get loadingSongs => 'Įkeliamos dainos…';

  @override
  String get loadingSetlists => 'Įkeliamos koncertinės programos…';

  @override
  String get errorGeneric => 'Įvyko klaida.';

  @override
  String get errorOffline => 'Panašu, kad nesate prisijungę prie interneto.';

  @override
  String get errorPermission => 'Norint tęsti, reikia leidimo.';

  @override
  String get emptyFiltered => 'Nė vienas elementas neatitinka šių filtrų.';

  @override
  String get unknownValue => 'Nežinoma';

  @override
  String get durationUnknown => 'Trukmė nežinoma';

  @override
  String get metadataNotSet => 'Nenustatyta';

  @override
  String get dateToday => 'Šiandien';

  @override
  String get dateYesterday => 'Vakar';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dainų',
      many: '$count dainų',
      few: '$count dainos',
      one: '$count daina',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Tamsiai mėlyna';

  @override
  String get settingsPaletteSage => 'Šalavijo žalia';

  @override
  String get settingsPaletteOcean => 'Vandenyno mėlyna';

  @override
  String get settingsPaletteClay => 'Molio';

  @override
  String get settingsPalettePlum => 'Slyvų';

  @override
  String get settingsFontSystem => 'Sistemos';

  @override
  String get settingsFontSerif => 'Su užraitais';

  @override
  String get settingsFontMonospace => 'Vienodo pločio';

  @override
  String get settingsLyricsPreviewExample => 'Kai išauš rytas, vėl dainuosime.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Tikrinami dainų tekstų šaltiniai: baigta $checked iš $total.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Nerasta tinkamų dainų tekstų.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Pasirinkta daina patikrinta visuose įjungtuose šaltiniuose, tačiau nė viename nerasta tinkamos teksto versijos.';

  @override
  String get searchDiscoveryError =>
      'Nepavyko patikrinti dainų tekstų šaltinių.';

  @override
  String get searchDiscoveryRetry => 'Pakartoti dainų tekstų paiešką';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nepasiekiamų šaltinių',
      many: '$count nepasiekiamų šaltinių',
      few: '$count nepasiekiami šaltiniai',
      one: '$count nepasiekiamas šaltinis',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Patikrinkite ryšį ir bandykite dar kartą.';

  @override
  String get searchProviderChecks => 'Šaltinių patikros';

  @override
  String get searchProviderPending => 'Tikrinama';

  @override
  String get searchProviderFound => 'Rastas atitikmuo';

  @override
  String get searchProviderRejected => 'Neatitinka';

  @override
  String get searchProviderFailed => 'Patikra nepavyko';

  @override
  String get searchProviderUnavailable => 'Tinkamų dainų tekstų nėra';

  @override
  String get searchCatalogFilterHint =>
      'Pasirinkite dainą, kad filtruotumėte teksto versijas pagal akordus, laiko žymas arba kalbą.';

  @override
  String get startupErrorTitle => 'Nepavyko atverti jūsų bibliotekos.';

  @override
  String setlistCopyName(String name) {
    return '$name kopija';
  }

  @override
  String get setlistSongMissing => 'Daina nerasta';

  @override
  String get settingsImportTooLarge =>
      'Šis failas per didelis, kad jį būtų galima importuoti.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Pereiti prie raidės $letter';
  }

  @override
  String get actionDiscard => 'Atmesti';

  @override
  String get editorKeepEditing => 'Tęsti redagavimą';

  @override
  String get settingsDefaultShowChordsHint =>
      'Jei dainoje yra akordų, rodyti juos virš teksto.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Dainos tekstas slenka kartu su daina. Šis nustatymas netaikomas rankinio slinkimo režimui.';

  @override
  String get accountUnavailableTitle => 'Sinchronizavimas nesukonfigūruotas';

  @override
  String get accountSignedOutBenefits =>
      'Prisijunkite per Google, kad sukurtumėte dainų ir koncertinių programų atsarginę kopiją Google Drive ir sinchronizuotumėte visus įrenginius. Dainos bet kuriuo atveju liks šiame įrenginyje.';

  @override
  String get accountSignInWithGoogle => 'Prisijungti per Google';

  @override
  String get accountWorking => 'Vykdoma…';

  @override
  String get accountNeverSynced => 'Dar nesinchronizuota';

  @override
  String get accountSyncedJustNow => 'Sinchronizuota ką tik';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinchronizuota prieš $count minučių',
      many: 'Sinchronizuota prieš $count minučių',
      few: 'Sinchronizuota prieš $count minutes',
      one: 'Sinchronizuota prieš $count minutę',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinchronizuota prieš $count valandų',
      many: 'Sinchronizuota prieš $count valandų',
      few: 'Sinchronizuota prieš $count valandas',
      one: 'Sinchronizuota prieš $count valandą',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sinchronizuota prieš $count dienų',
      many: 'Sinchronizuota prieš $count dienų',
      few: 'Sinchronizuota prieš $count dienas',
      one: 'Sinchronizuota prieš $count dieną',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dėl konflikto kilusių pakeitimų išsaugota kaip kopijos',
      many: '$count dėl konflikto kilusių pakeitimų išsaugota kaip kopijos',
      few: '$count dėl konflikto kilę pakeitimai išsaugoti kaip kopijos',
      one: '$count dėl konflikto kilęs pakeitimas išsaugotas kaip kopija',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Ta pati daina arba koncertinė programa buvo redaguota dviejose vietose. Nieko nepraradote: kita versija išsaugota kaip atskira kopija.';

  @override
  String get accountReviewConflicts => 'Peržiūrėti kopijas';

  @override
  String get songsConflictFilterActive => 'Rodomos tik konfliktinės kopijos';

  @override
  String get songsConflictFilterClear => 'Rodyti visas dainas';

  @override
  String get songsConflictBadge => 'Konfliktinė kopija';

  @override
  String get songsConflictEmpty => 'Konfliktinių kopijų nėra.';

  @override
  String get accountAutoSync => 'Sinchronizuoti automatiškai';

  @override
  String get accountAutoSyncHint =>
      'Biblioteka atnaujinama, kai atveriate programą ir atliekate pakeitimų.';

  @override
  String get accountSignOutTitle => 'Atsijungti nuo šios paskyros?';

  @override
  String get accountSignOutBody =>
      'Dainos ir koncertinės programos liks šiame įrenginyje. Jų atsarginės kopijos nebus kuriamos ir jos nebus sinchronizuojamos, kol vėl neprisijungsite.';

  @override
  String get accountUseDifferent => 'Naudoti kitą paskyrą';

  @override
  String get accountSignInAgain => 'Prisijungti dar kartą';

  @override
  String get accountChooseAction => 'Pasirinkite, kaip tęsti';

  @override
  String get accountChangedTitle => 'Kita Google paskyra';

  @override
  String get accountChangedBody =>
      'Šis įrenginys paskutinį kartą buvo sinchronizuotas su kita Google paskyra. Pasirinkite, kas nutiks šiame įrenginyje esančioms dainoms ir koncertinėms programoms.';

  @override
  String get accountChangedMerge => 'Sujungti su nauja paskyra';

  @override
  String get accountChangedMergeHint =>
      'Palikti viską šiame įrenginyje ir pridėti prie naujos paskyros.';

  @override
  String get accountChangedReplace => 'Pakeisti naujos paskyros biblioteka';

  @override
  String get accountChangedReplaceHint =>
      'Šiame įrenginyje esančios dainos, kurių nėra naujoje paskyroje, bus pašalintos.';

  @override
  String get accountChangedSignOut => 'Atšaukti ir atsijungti';

  @override
  String get accountStatusSignedOut =>
      'Paskyra ir sinchronizavimas: neprisijungta';

  @override
  String get accountStatusSignedIn =>
      'Paskyra ir sinchronizavimas: prisijungta';

  @override
  String get accountStatusSyncing =>
      'Paskyra ir sinchronizavimas: sinchronizuojama';

  @override
  String get accountStatusSynced =>
      'Paskyra ir sinchronizavimas: biblioteka atnaujinta';

  @override
  String get accountStatusError =>
      'Paskyra ir sinchronizavimas: iškilo problema, palieskite, kad peržiūrėtumėte';

  @override
  String get accountNoticeConflicts =>
      'Kai kurios dainos buvo redaguotos dviejose vietose. Kopijos išsaugotos.';

  @override
  String get accountNoticeSignedIn => 'Prisijungėte.';

  @override
  String get accountNoticeSignedOut =>
      'Atsijungėte. Dainos liks šiame įrenginyje.';

  @override
  String get syncErrorNotConfigured =>
      'Šioje versijoje sinchronizavimas nesukonfigūruotas.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Naudokite Singbook versiją su sukonfigūruotu prisijungimu per Google.';

  @override
  String get syncErrorNotSignedIn => 'Esate neprisijungę.';

  @override
  String get syncErrorNotSignedInHint =>
      'Prisijunkite, kad sinchronizuotumėte biblioteką.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google prašo prisijungti iš naujo.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Prisijunkite dar kartą, kad tęstumėte sinchronizavimą. Dainos šiame įrenginyje saugios.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook neturi leidimo naudoti Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Prisijunkite iš naujo ir, kai būsite paprašyti, leiskite prieigą prie Drive.';

  @override
  String get syncErrorRateLimited => 'Google laikinai riboja užklausas.';

  @override
  String get syncErrorRateLimitedHint =>
      'Palaukite kelias minutes ir bandykite dar kartą.';

  @override
  String get syncErrorStorageFull => 'Google Drive pilnas.';

  @override
  String get syncErrorStorageFullHint =>
      'Atlaisvinkite vietos Drive ir bandykite dar kartą.';

  @override
  String get syncErrorNetwork => 'Nepavyko pasiekti Google.';

  @override
  String get syncErrorNetworkHint =>
      'Patikrinkite interneto ryšį ir bandykite dar kartą.';

  @override
  String get syncErrorAccountChanged => 'Naudota kita Google paskyra.';

  @override
  String get syncErrorAccountChangedHint =>
      'Pasirinkite, ar sujungti šio įrenginio biblioteką su ja, ar ją pakeisti.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Sinchronizuota biblioteka per didelė, kad Singbook galėtų ją apdoroti.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Pašalinkite dainų ar koncertinių programų iš sinchronizuotos bibliotekos ir bandykite dar kartą.';

  @override
  String get syncErrorSignInFailed => 'Prisijungti nepavyko.';

  @override
  String get syncErrorSignInFailedHint => 'Bandykite prisijungti dar kartą.';

  @override
  String get syncErrorGeneric => 'Nepavyko sinchronizuoti bibliotekos.';

  @override
  String get syncErrorGenericHint =>
      'Netrukus bandykite dar kartą. Dainos šiame įrenginyje vis dar saugios.';
}
