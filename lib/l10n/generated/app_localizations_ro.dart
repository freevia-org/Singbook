// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Versuri, acorduri și liste de melodii împreună, pregătite pentru repetiții, scenă și oriunde cânți.';

  @override
  String get aboutMadeForSinging => 'Fiecare cântec, gata de cântat.';

  @override
  String get aboutDetails =>
      'Caută în sursele disponibile și compară versurile, acordurile, marcajele temporale și detaliile înregistrării înainte să salvezi versiunea dorită. Disponibilitatea diferă în funcție de melodie și serviciu.';

  @override
  String get aboutFindTitle => 'Găsește versiunea potrivită';

  @override
  String get aboutKeepTitle => 'Construiește-ți propria bibliotecă';

  @override
  String get aboutKeepDetails =>
      'Editează și transpune melodiile, păstrează-le în biblioteca locală pentru a le folosi offline și distribuie fișiere ChordPro portabile. Sincronizarea opțională cu Google Drive folosește un dosar privat al aplicației din contul tău Google. Poți atinge și „Sincronizează acum” pentru a actualiza dispozitivele.';

  @override
  String get aboutPlayTitle => 'Ia lista de melodii pe scenă';

  @override
  String get aboutPlayDetails =>
      'Grupează melodiile în setlisturi, alege tonalitatea fiecăreia și distribuie setlisturi OpenSong. Ajustează textul cititorului, derulează automat versurile și imprimă PDF-uri cu melodii. Singbook nu transmite și nu redă conținut audio.';

  @override
  String get aboutPrivacyTitle => 'Gratuită și cu biblioteca păstrată local';

  @override
  String get aboutPrivacyDetails =>
      'Singbook este gratuită, fără reclame, analiză sau achiziții în aplicație. Biblioteca salvată rămâne pe dispozitivul tău; sincronizarea opțională folosește propriul Google Drive. Rezultatele online vin direct de la servicii independente terțe și pot fi indisponibile sau protejate prin drepturi de autor. Singbook nu găzduiește conținutul acestora.';

  @override
  String get aboutWebsite => 'Site-ul Singbook';

  @override
  String get aboutSourceCode => 'Cod sursă pe GitHub';

  @override
  String get aboutPublisher => 'De la Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Limbi ale aplicației: $count';
  }

  @override
  String get aboutSupport => 'Asistență și feedback';

  @override
  String get menuTypeNewSong => 'Introdu o melodie nouă';

  @override
  String appVersion(String version) {
    return 'Versiunea $version';
  }

  @override
  String get navHome => 'Acasă';

  @override
  String get navSongs => 'Melodii';

  @override
  String get navSetlists => 'Liste de piese';

  @override
  String get navSettings => 'Setări';

  @override
  String get navSettingsCompact => 'Setări';

  @override
  String get navSearch => 'Caută';

  @override
  String get navBack => 'Înapoi';

  @override
  String get appExitBackAgain => 'Apăsați din nou Înapoi pentru a ieși';

  @override
  String get navClose => 'Închide';

  @override
  String get navMore => 'Mai multe acțiuni';

  @override
  String get actionCancel => 'Anulează';

  @override
  String get actionSave => 'Salvează';

  @override
  String get actionDone => 'Gata';

  @override
  String get actionEdit => 'Editează';

  @override
  String get actionDelete => 'Șterge';

  @override
  String get actionShare => 'Partajează';

  @override
  String get actionPrint => 'Imprimă';

  @override
  String get actionCopy => 'Copiază';

  @override
  String get actionClear => 'Șterge';

  @override
  String get actionRetry => 'Încearcă din nou';

  @override
  String get actionRefresh => 'Reîmprospătează';

  @override
  String get actionImport => 'Importă';

  @override
  String get actionExport => 'Exportă';

  @override
  String get actionExpand => 'Extinde';

  @override
  String get actionCollapse => 'Restrânge';

  @override
  String get actionAdd => 'Adaugă';

  @override
  String get actionCreate => 'Creează';

  @override
  String get actionRemove => 'Elimină';

  @override
  String get actionDuplicate => 'Duplică';

  @override
  String get actionMoveUp => 'Mută în sus';

  @override
  String get actionMoveDown => 'Mută în jos';

  @override
  String get actionPrevious => 'Anterior';

  @override
  String get actionNext => 'Următorul';

  @override
  String get searchHint => 'Caută melodii, artiști sau versuri';

  @override
  String get searchCatalogHint => 'Caută o melodie sau un artist';

  @override
  String get searchChangeSong => 'Schimbă melodia';

  @override
  String get searchSelectedPreview => 'Previzualizare selectată';

  @override
  String get searchSubmit => 'Caută';

  @override
  String get searchFilters => 'Opțiuni de căutare';

  @override
  String get searchFiltersShow => 'Afișează opțiunile de căutare';

  @override
  String get searchFiltersHide => 'Ascunde opțiunile de căutare';

  @override
  String get searchFilterArtist => 'Artist';

  @override
  String get searchFilterTitle => 'Titlul melodiei';

  @override
  String get searchFilterLyrics => 'Versuri';

  @override
  String get searchFilterChords => 'Are acorduri';

  @override
  String get searchFilterTimed => 'Versuri sincronizate';

  @override
  String get searchFilterLanguage => 'Limba';

  @override
  String get searchFilterAll => 'Oricare';

  @override
  String get searchAutocompleteLabel => 'Sugestii';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de rezultate',
      few: '$count rezultate',
      one: '1 rezultat',
      zero: 'Niciun rezultat',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Introdu o melodie, un artist sau versuri pentru a căuta.';

  @override
  String get searchCatalogEmptyQuery =>
      'Introdu o melodie sau un artist pentru a căuta.';

  @override
  String get searchNoResults =>
      'Nu s-au găsit melodii. Încearcă o altă căutare.';

  @override
  String get searchLoading => 'Se caută melodii…';

  @override
  String get searchError => 'Căutarea nu a putut fi finalizată.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Recente';

  @override
  String get searchFavoritesTab => 'Favorite';

  @override
  String get searchSuggested => 'Potrivire sugerată';

  @override
  String get searchAlternatives => 'Alte potriviri';

  @override
  String get searchCompare => 'Compară versiunile';

  @override
  String get searchChooseVersion => 'Alege această versiune';

  @override
  String get searchFullPreview => 'Previzualizare completă';

  @override
  String get searchArrangementNotes => 'Note despre aranjament';

  @override
  String get searchOpenLyrics => 'Deschide versurile';

  @override
  String get searchContributions => 'Surse folosite';

  @override
  String get searchVersionChecking => 'Se verifică această versiune…';

  @override
  String get searchVersionUnavailable =>
      'Această versiune nu poate fi folosită. Alege altă versiune.';

  @override
  String get searchPreviewUnavailable =>
      'Previzualizarea versurilor nu este disponibilă.';

  @override
  String get searchSongMatch => 'Potrivire pentru melodie';

  @override
  String get searchRecordingMatch => 'Potrivire pentru înregistrare';

  @override
  String get searchMatchUnverified => 'Înregistrare neverificată';

  @override
  String get searchMatchExact => 'Potrivire exactă a înregistrării';

  @override
  String get searchMatchPossible => 'Potrivire posibilă';

  @override
  String get searchAvailability => 'Disponibilitate';

  @override
  String get searchLyricsAvailable => 'Versuri disponibile';

  @override
  String get searchLyricsUnavailable => 'Versuri indisponibile';

  @override
  String get searchChordsAvailable => 'Acorduri disponibile';

  @override
  String get searchChordsUnavailable => 'Fără acorduri';

  @override
  String get searchTimingAvailable => 'Sincronizare disponibilă';

  @override
  String get searchTimingUnavailable => 'Fără sincronizare';

  @override
  String get searchDurationUnknown => 'Durată necunoscută';

  @override
  String searchRating(String rating) {
    return 'Evaluare $rating';
  }

  @override
  String get searchSourceLabel => 'Sursă';

  @override
  String get searchMetadata => 'Detalii despre melodie';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Artist';

  @override
  String get searchYear => 'An';

  @override
  String get searchLanguage => 'Limba';

  @override
  String get searchViewVersions => 'Vezi versiunile';

  @override
  String get searchSaved => 'Melodia a fost salvată în bibliotecă.';

  @override
  String get searchSaveOpenLyrics => 'Salvează și deschide versurile';

  @override
  String get searchOtherResults => 'Alte rezultate';

  @override
  String get searchSaveFailed => 'Melodia nu a putut fi salvată.';

  @override
  String get homeRecentSongs => 'Melodii recente';

  @override
  String get homeRecentlyPlayed => 'Ascultate recent';

  @override
  String get homeFavorites => 'Favorite';

  @override
  String get homeHistory => 'Istoric';

  @override
  String get homeHistoryClear => 'Șterge istoricul';

  @override
  String get homeHistoryCleared => 'Istoricul a fost șters.';

  @override
  String get homeHistoryEmpty =>
      'Melodiile pe care le deschizi vor apărea aici.';

  @override
  String get homeFavoritesEmpty =>
      'Melodiile și listele tale favorite vor apărea aici.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de elemente afișate',
      few: '$count elemente afișate',
      one: '1 element afișat',
      zero: '0 elemente afișate',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty => 'Melodiile și listele recente vor apărea aici.';

  @override
  String get homeTimelineLabel => 'Cronologia istoricului';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Tot istoricul';

  @override
  String get homeShowFavorites => 'Afișează favoritele';

  @override
  String get homeShowRecent => 'Afișează elementele recente';

  @override
  String get songsTitle => 'Melodii';

  @override
  String get songsEmpty => 'Melodiile tale vor apărea aici.';

  @override
  String get songsEmptySearch => 'Nicio melodie nu corespunde căutării.';

  @override
  String get songsAdd => 'Adaugă o melodie';

  @override
  String get songsSortAlphabetical => 'Sortează alfabetic';

  @override
  String get songsAlphabetNavigation => 'Indexul melodiilor';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'de $count de ori',
      few: 'de $count ori',
      one: 'o dată',
      zero: 'niciodată',
    );
    return 'Deschisă $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Adaugă la favorite';

  @override
  String get songFavoriteRemove => 'Elimină de la favorite';

  @override
  String get songMenuLabel => 'Acțiuni pentru melodie';

  @override
  String get songInfo => 'Detalii despre melodie';

  @override
  String get setlistMenuLabel => 'Acțiuni pentru listă';

  @override
  String get songAddToSetlist => 'Adaugă în listă';

  @override
  String get songCopyChordPro => 'Copiază ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Ștergi melodia?';

  @override
  String get songDeleteConfirmMessage =>
      'Melodia va fi eliminată din bibliotecă.';

  @override
  String get songDeleted => 'Melodia a fost ștearsă.';

  @override
  String get setlistsTitle => 'Liste de piese';

  @override
  String get setlistsEmpty =>
      'Creează o listă pentru următoarea repetiție sau interpretare.';

  @override
  String get setlistsEmptySearch => 'Nicio listă nu corespunde căutării.';

  @override
  String get setlistCreate => 'Listă nouă';

  @override
  String get setlistNameHint => 'Numele listei';

  @override
  String get setlistNotes => 'Note';

  @override
  String get setlistEntryOverride =>
      'Tonalitate și capo pentru această melodie';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de melodii',
      few: '$count melodii',
      one: '1 melodie',
      zero: 'Nicio melodie',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Cel puțin $duration';
  }

  @override
  String get setlistDurationUnknown => 'Durată necunoscută';

  @override
  String setlistActivity(String date) {
    return 'Ultima activitate $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Creată $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Editată $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Redată ultima dată $date';
  }

  @override
  String get setlistSongsEmpty => 'Lista nu conține încă melodii.';

  @override
  String get setlistAddSongs => 'Adaugă melodii';

  @override
  String get setlistReorder => 'Reordonează melodiile';

  @override
  String setlistMoveSongUp(String song) {
    return 'Mută $song în sus';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Mută $song în jos';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Elimină $song din listă';
  }

  @override
  String get setlistDuplicate => 'Duplică lista';

  @override
  String get setlistFavoriteAdd => 'Adaugă lista la favorite';

  @override
  String get setlistFavoriteRemove => 'Elimină lista de la favorite';

  @override
  String get setlistShare => 'Partajează ca fișier de listă';

  @override
  String get setlistSharePdf => 'Partajează ca PDF';

  @override
  String get setlistPrint => 'Imprimă';

  @override
  String get setlistDeleteConfirmTitle => 'Ștergi lista?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Lista va fi eliminată. Melodiile din bibliotecă vor rămâne.';

  @override
  String get setlistDeleted => 'Lista a fost ștearsă.';

  @override
  String get readerTitle => 'Versuri';

  @override
  String get readerNoLyrics => 'Versurile nu au fost adăugate încă.';

  @override
  String get readerShowChords => 'Afișează acordurile';

  @override
  String get readerHideChords => 'Ascunde acordurile';

  @override
  String get readerTranspose => 'Transpune acordurile';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de semitonuri',
      few: '$count semitonuri',
      one: '1 semiton',
      zero: '0 semitonuri',
    );
    return 'Transpune cu $_temp0';
  }

  @override
  String get readerSaved => 'Salvat';

  @override
  String get readerEdit => 'Editează versurile și detaliile';

  @override
  String get playerPlay => 'Redă';

  @override
  String get playerPause => 'Pauză';

  @override
  String get playerResume => 'Reia derularea versurilor';

  @override
  String get playerSeek => 'Poziția redării';

  @override
  String playerElapsed(String time) {
    return 'Timp scurs $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Timp rămas $time';
  }

  @override
  String get playerTimingMode => 'Mod de derulare';

  @override
  String get playerTimedLyrics => 'Versuri sincronizate';

  @override
  String get playerStartScroll => 'Pornește derularea automată';

  @override
  String get playerEstimatedPace => 'Ritm estimat';

  @override
  String get playerScrollSpeed => 'Viteza de derulare';

  @override
  String playerEstimatedDuration(String time) {
    return 'Durată estimată: $time';
  }

  @override
  String get playerLyricsOnly => 'Derularea versurilor · fără sunet';

  @override
  String get playerManualScroll => 'Derulare manuală';

  @override
  String get playerTimingStatusReady =>
      'Versurile vor urma sincronizarea disponibilă.';

  @override
  String get playerTimingStatusEstimated =>
      'Ritmul de derulare este estimat pe baza duratei melodiei.';

  @override
  String get playerTimingStatusManual => 'Derulează manual versurile.';

  @override
  String get playerTimingStatusUnavailable =>
      'Derularea sincronizată nu este disponibilă pentru această melodie.';

  @override
  String get playerDurationUnknown =>
      'Adaugă durata melodiei pentru a folosi derularea estimată.';

  @override
  String get playerProgressLabel => 'Progresul melodiei';

  @override
  String get playerCurrentSection => 'Secțiunea curentă';

  @override
  String get playerPreviousSection => 'Secțiunea anterioară';

  @override
  String get playerNextSection => 'Secțiunea următoare';

  @override
  String get playerPreviousSectionSong =>
      'Secțiunea anterioară · ține apăsat pentru melodia anterioară din listă';

  @override
  String get playerNextSectionSong =>
      'Secțiunea următoare · ține apăsat pentru melodia următoare din listă';

  @override
  String get playerPreviousSong => 'Melodia anterioară';

  @override
  String get playerNextSong => 'Melodia următoare';

  @override
  String get editorTitle => 'Editează melodia';

  @override
  String get editorTitleField => 'Titlul melodiei';

  @override
  String get editorArtistField => 'Artist';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Versuri';

  @override
  String get editorChordsField => 'Acorduri';

  @override
  String get editorKeyField => 'Tonalitate';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Acordaj';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Durată';

  @override
  String get editorTimeSignatureField => 'Măsura';

  @override
  String get editorLanguageField => 'Limba';

  @override
  String get editorYearField => 'An';

  @override
  String get editorComposerField => 'Compozitor';

  @override
  String get editorLyricistField => 'Textier';

  @override
  String get editorCopyrightField => 'Drepturi de autor';

  @override
  String get editorLicenseField => 'Licență';

  @override
  String get songInfoSources => 'Surse și credite';

  @override
  String get searchMatchSameSong =>
      'Aceeași melodie; înregistrarea nu este confirmată';

  @override
  String get searchMatchNeedsAgreement =>
      'Partitura necesită confirmarea versurilor';

  @override
  String get searchMatchDifferentLyrics =>
      'Versurile diferă de cele ale melodiei selectate';

  @override
  String get searchMatchCombinedSources =>
      'Detalii combinate din mai multe surse';

  @override
  String get searchCombinedLabel => 'Combinate';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de potriviri pentru melodii',
      few: '$count potriviri pentru melodii',
      one: '1 potrivire pentru melodie',
      zero: '0 potriviri pentru melodii',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de versiuni din surse',
      few: '$count versiuni din surse',
      one: '1 versiune dintr-o sursă',
      zero: '0 versiuni din surse',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Cea mai bună potrivire disponibilă';

  @override
  String get providerDescriptionUnknown => 'Sursă pentru melodie';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Descarcă un fișier ChordPro de la sursă, apoi importă-l.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Descarcă fișierul cu un cont gratuit, apoi importă-l.';

  @override
  String get providerDescPublicChordSheets => 'Partituri publice cu acorduri.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Versuri istorice licențiate pentru fiecare operă.';

  @override
  String get providerDescLicensedCatalog => 'Catalog de versuri licențiat.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Melodii originale sub licența Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Versuri licențiate pentru fiecare melodie.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Doar detalii despre înregistrare și lansare.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Doar detalii despre compoziție.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Copertă doar pentru potriviri exacte ale înregistrării.';

  @override
  String get providerCapabilityLyrics => 'Versuri';

  @override
  String get providerCapabilityChords => 'Acorduri';

  @override
  String get providerCapabilityTiming => 'Versuri sincronizate';

  @override
  String get providerCapabilitySearch => 'Căutare';

  @override
  String get providerCapabilityMetadata => 'Detalii despre melodie';

  @override
  String get editorArtworkField => 'Link către copertă';

  @override
  String get editorLyricsHint =>
      'Acordurile se scriu între paranteze [C]; marcajele secțiunilor pe rânduri separate.';

  @override
  String get editorSave => 'Salvează modificările';

  @override
  String get editorSaved => 'Modificările au fost salvate.';

  @override
  String get editorSaveFailed => 'Modificările nu au putut fi salvate.';

  @override
  String get editorSaveConflict =>
      'Melodia a fost modificată în altă parte. Modificările tale au fost salvate ca o copie separată.';

  @override
  String get editorUnsavedTitle => 'Renunți la modificări?';

  @override
  String get editorUnsavedMessage => 'Modificările tale nu au fost salvate.';

  @override
  String get editorFieldRequired => 'Introdu titlul melodiei.';

  @override
  String get settingsTitle => 'Setări';

  @override
  String get settingsAppearance => 'Aspect';

  @override
  String get settingsTheme => 'Temă';

  @override
  String get settingsThemeSystem => 'Folosește setarea dispozitivului';

  @override
  String get settingsThemeLight => 'Luminoasă';

  @override
  String get settingsThemeDark => 'Întunecată';

  @override
  String get settingsColorPalette => 'Paletă de culori';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsTextSize => 'Dimensiunea textului';

  @override
  String get settingsLyricsPreview => 'Previzualizarea versurilor';

  @override
  String get settingsPlayer => 'Player de versuri';

  @override
  String get settingsLyricHighlight => 'Evidențierea versului curent';

  @override
  String get settingsHighlightBackgroundUnderline => 'Fundal + subliniere';

  @override
  String get settingsHighlightBackground => 'Fundal';

  @override
  String get settingsHighlightUnderline => 'Subliniere';

  @override
  String get settingsHighlightContrast => 'Culoare de text contrastantă';

  @override
  String get settingsHighlightNone => 'Niciuna';

  @override
  String get settingsDefaultShowChords => 'Afișează acordurile implicit';

  @override
  String get settingsDefaultAutoscroll =>
      'Pornește automat derularea versurilor';

  @override
  String get settingsDefaultTiming => 'Mod implicit de derulare';

  @override
  String get settingsLanguage => 'Limba aplicației';

  @override
  String get settingsLanguageSystem => 'Folosește limba dispozitivului';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Surse pentru versuri';

  @override
  String settingsSourceEnabled(String source) {
    return 'Activează sursa $source';
  }

  @override
  String get settingsSourceRefresh => 'Reîmprospătează lista surselor';

  @override
  String get settingsSourcesUpdated => 'Sursele au fost actualizate.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Lista surselor nu a putut fi reîmprospătată.';

  @override
  String get settingsImport => 'Importă melodii';

  @override
  String get settingsImportChordPro => 'Importă un fișier ChordPro';

  @override
  String get settingsImportSetlist => 'Importă un fișier cu lista de piese';

  @override
  String get settingsImportSuccess => 'Import finalizat.';

  @override
  String get settingsImportFailed => 'Fișierul nu a putut fi importat.';

  @override
  String get settingsImportUnsupported =>
      'Acest tip de fișier nu este acceptat.';

  @override
  String get settingsShareSong => 'Partajează ca ChordPro';

  @override
  String get settingsSharePdf => 'Partajează ca PDF';

  @override
  String get settingsCopySong => 'Copiază în clipboard';

  @override
  String get settingsPrintSong => 'Imprimă doar melodia';

  @override
  String get settingsPrintSetlist => 'Imprimă lista cu versuri';

  @override
  String get settingsExportFailed => 'Fișierul nu a putut fi pregătit.';

  @override
  String get settingsCopied => 'Copiat în clipboard.';

  @override
  String get settingsAbout => 'Despre';

  @override
  String get settingsPrivacy => 'Confidențialitate';

  @override
  String get settingsLegal => 'Informații legale';

  @override
  String get settingsClearHistory => 'Șterge istoricul';

  @override
  String get settingsClearHistoryConfirm =>
      'Ștergi istoricul melodiilor și listelor?';

  @override
  String get settingsHistoryCleared => 'Istoricul a fost șters.';

  @override
  String get accountTitle => 'Cont și sincronizare';

  @override
  String get accountUnavailable =>
      'Sincronizarea necesită o versiune Singbook configurată pentru autentificarea Google. Această versiune păstrează melodiile doar pe acest dispozitiv.';

  @override
  String get accountSyncNow => 'Sincronizează acum';

  @override
  String get accountConnected =>
      'Conectat. Alege „Sincronizează acum” pentru a actualiza copia de siguranță.';

  @override
  String get accountSignIn => 'Conectează contul';

  @override
  String get accountSignOut => 'Deconectează-te';

  @override
  String get accountChange => 'Schimbă contul';

  @override
  String get accountSignedOut => 'Neconectat';

  @override
  String get accountSyncing => 'Se sincronizează biblioteca…';

  @override
  String get accountSynced => 'Biblioteca a fost sincronizată.';

  @override
  String get accountSyncFailed => 'Biblioteca nu a putut fi sincronizată.';

  @override
  String get accessibilityFavorite => 'Favorită';

  @override
  String get accessibilityNotFavorite => 'Nu este favorită';

  @override
  String get accessibilitySearchField => 'Caută melodii';

  @override
  String get accessibilityClearSearch => 'Șterge textul căutării';

  @override
  String accessibilitySongMenu(String song) {
    return 'Acțiuni pentru $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Acțiuni pentru $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Extinde melodiile din $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Restrânge melodiile din $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Progresul redării, $percent la sută';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Cronologia istoricului, $date';
  }

  @override
  String get loading => 'Se încarcă…';

  @override
  String get loadingSongs => 'Se încarcă melodiile…';

  @override
  String get loadingSetlists => 'Se încarcă listele…';

  @override
  String get errorGeneric => 'A apărut o eroare.';

  @override
  String get errorOffline => 'Se pare că nu ai conexiune la internet.';

  @override
  String get errorPermission => 'Este necesară o permisiune pentru a continua.';

  @override
  String get emptyFiltered => 'Niciun element nu corespunde acestor filtre.';

  @override
  String get unknownValue => 'Necunoscut';

  @override
  String get durationUnknown => 'Durată necunoscută';

  @override
  String get metadataNotSet => 'Nesetat';

  @override
  String get dateToday => 'Astăzi';

  @override
  String get dateYesterday => 'Ieri';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de melodii',
      few: '$count melodii',
      one: '1 melodie',
      zero: 'Nicio melodie',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Bleumarin';

  @override
  String get settingsPaletteSage => 'Salvie';

  @override
  String get settingsPaletteOcean => 'Ocean';

  @override
  String get settingsPaletteClay => 'Argilă';

  @override
  String get settingsPalettePlum => 'Prună';

  @override
  String get settingsFontSystem => 'Sistem';

  @override
  String get settingsFontSerif => 'Serif';

  @override
  String get settingsFontMonospace => 'Monospațiat';

  @override
  String get settingsLyricsPreviewExample =>
      'Când vine dimineața, vom cânta din nou.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Se verifică sursele de versuri: $checked din $total finalizate.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Nu s-au găsit versuri utilizabile.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Melodia selectată a fost verificată în sursele activate, dar niciuna nu a returnat o versiune utilizabilă a versurilor.';

  @override
  String get searchDiscoveryError =>
      'Sursele de versuri nu au putut fi verificate.';

  @override
  String get searchDiscoveryRetry => 'Reîncearcă căutarea versurilor';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de surse indisponibile',
      few: '$count surse indisponibile',
      one: '1 sursă indisponibilă',
      zero: '0 surse indisponibile',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails =>
      'Verifică-ți conexiunea și încearcă din nou.';

  @override
  String get searchProviderChecks => 'Verificarea surselor';

  @override
  String get searchProviderPending => 'Se verifică';

  @override
  String get searchProviderFound => 'Potrivire găsită';

  @override
  String get searchProviderRejected => 'Nu se potrivește';

  @override
  String get searchProviderFailed => 'Verificarea a eșuat';

  @override
  String get searchProviderUnavailable => 'Nu există versuri utilizabile';

  @override
  String get searchCatalogFilterHint =>
      'Selectează o melodie pentru a filtra versiunile versurilor după acorduri, sincronizare sau limbă.';

  @override
  String get startupErrorTitle => 'Biblioteca nu a putut fi deschisă.';

  @override
  String setlistCopyName(String name) {
    return 'Copia $name';
  }

  @override
  String get setlistSongMissing => 'Melodie lipsă';

  @override
  String get settingsImportTooLarge =>
      'Fișierul este prea mare pentru a fi importat.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Sari la $letter';
  }

  @override
  String get actionDiscard => 'Renunță';

  @override
  String get editorKeepEditing => 'Continuă editarea';

  @override
  String get settingsDefaultShowChordsHint =>
      'Afișează acordurile deasupra versurilor când melodia le are.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Versurile se derulează odată cu melodia. Nu se folosește în modul de derulare manuală.';

  @override
  String get accountUnavailableTitle => 'Sincronizarea nu este configurată';

  @override
  String get accountSignedOutBenefits =>
      'Conectarea Google Drive sincronizează biblioteca. Ulterior, modificările melodiilor se sincronizează automat.';

  @override
  String get accountManualSyncHint =>
      'Poți atinge și Sincronizează acum pentru a sincroniza biblioteca.';

  @override
  String get accountSignInWithGoogle => 'Conectează-te cu Google';

  @override
  String get accountWorking => 'Se procesează…';

  @override
  String get accountNeverSynced => 'Niciodată sincronizată';

  @override
  String get accountSyncedJustNow => 'Sincronizată chiar acum';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizată acum $count de minute',
      few: 'Sincronizată acum $count minute',
      one: 'Sincronizată acum un minut',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizată acum $count de ore',
      few: 'Sincronizată acum $count ore',
      one: 'Sincronizată acum o oră',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizată acum $count de zile',
      few: 'Sincronizată acum $count zile',
      one: 'Sincronizată acum o zi',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de modificări în conflict au fost păstrate ca copii',
      few: '$count modificări în conflict au fost păstrate ca copii',
      one: 'O modificare în conflict a fost păstrată ca o copie',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Aceeași melodie sau listă a fost editată în două locuri. Nimic nu s-a pierdut: cealaltă versiune a fost salvată ca o copie separată.';

  @override
  String get accountReviewConflicts => 'Examinează copiile';

  @override
  String get songsConflictFilterActive =>
      'Se afișează doar copiile aflate în conflict';

  @override
  String get songsConflictFilterClear => 'Afișează toate melodiile';

  @override
  String get songsConflictBadge => 'Copie în conflict';

  @override
  String get songsConflictEmpty => 'Nu există copii în conflict.';

  @override
  String get accountAutoSync => 'Sincronizează automat';

  @override
  String get accountAutoSyncHint =>
      'Sincronizarea are loc după conectare și după adăugarea, editarea sau eliminarea unei melodii.';

  @override
  String get accountSignOutTitle => 'Te deconectezi de la acest cont?';

  @override
  String get accountSignOutBody =>
      'Melodiile și listele rămân pe acest dispozitiv. Nu vor fi salvate sau sincronizate până când te conectezi din nou.';

  @override
  String get accountUseDifferent => 'Folosește alt cont';

  @override
  String get accountSignInAgain => 'Conectează-te din nou';

  @override
  String get accountChooseAction => 'Alege cum vrei să continui';

  @override
  String get accountChangedTitle => 'Alt cont Google';

  @override
  String get accountChangedBody =>
      'Acest dispozitiv a fost sincronizat ultima dată cu un alt cont Google. Alege ce se întâmplă cu melodiile și listele de pe acest dispozitiv.';

  @override
  String get accountChangedMerge => 'Unește cu noul cont';

  @override
  String get accountChangedMergeHint =>
      'Păstrează totul pe acest dispozitiv și adaugă la noul cont.';

  @override
  String get accountChangedReplace => 'Înlocuiește cu biblioteca noului cont';

  @override
  String get accountChangedReplaceHint =>
      'Melodiile de pe acest dispozitiv care nu există în noul cont vor fi eliminate.';

  @override
  String get accountChangedSignOut => 'Anulează și deconectează-te';

  @override
  String get accountStatusSignedOut => 'Cont și sincronizare: deconectat';

  @override
  String get accountStatusSignedIn => 'Cont și sincronizare: conectat';

  @override
  String get accountStatusSyncing => 'Cont și sincronizare: se sincronizează';

  @override
  String get accountStatusSynced =>
      'Cont și sincronizare: biblioteca este actualizată';

  @override
  String get accountStatusError =>
      'Cont și sincronizare: problemă, atinge pentru detalii';

  @override
  String get accountNoticeConflicts =>
      'Unele melodii au fost editate în două locuri. Au fost păstrate copii.';

  @override
  String get accountNoticeSignedIn => 'Conectat.';

  @override
  String get accountNoticeSignedOut =>
      'Deconectat. Melodiile rămân pe acest dispozitiv.';

  @override
  String get syncErrorNotConfigured =>
      'Sincronizarea nu este configurată în această versiune.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Folosește o versiune Singbook configurată pentru autentificarea Google.';

  @override
  String get syncErrorNotSignedIn => 'Nu ești conectat.';

  @override
  String get syncErrorNotSignedInHint =>
      'Conectează-te pentru a sincroniza biblioteca.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google îți cere să te conectezi din nou.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Conectează-te din nou pentru a continua sincronizarea. Melodiile sunt în siguranță pe acest dispozitiv.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook nu are permisiunea de a folosi Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Conectează-te din nou și permite accesul la Drive când ți se solicită.';

  @override
  String get syncErrorRateLimited => 'Google limitează momentan solicitările.';

  @override
  String get syncErrorRateLimitedHint =>
      'Așteaptă câteva minute, apoi încearcă din nou.';

  @override
  String get syncErrorStorageFull => 'Google Drive este plin.';

  @override
  String get syncErrorStorageFullHint =>
      'Eliberează spațiu în Drive, apoi încearcă din nou.';

  @override
  String get syncErrorNetwork => 'Nu s-a putut contacta Google.';

  @override
  String get syncErrorNetworkHint =>
      'Verifică conexiunea la internet și încearcă din nou.';

  @override
  String get syncErrorAccountChanged => 'A fost folosit un alt cont Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Alege dacă unești biblioteca acestui dispozitiv cu cea a contului sau o înlocuiești.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Biblioteca sincronizată este prea mare pentru Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Elimină câteva melodii sau liste din biblioteca sincronizată, apoi încearcă din nou.';

  @override
  String get syncErrorSignInFailed => 'Conectarea nu s-a finalizat.';

  @override
  String get syncErrorSignInFailedHint => 'Încearcă să te conectezi din nou.';

  @override
  String get syncErrorGeneric => 'Biblioteca nu a putut fi sincronizată.';

  @override
  String get syncErrorGenericHint =>
      'Încearcă din nou peste puțin timp. Melodiile sunt în siguranță pe acest dispozitiv.';

  @override
  String get editorDurationInvalid =>
      'Introdu secunde sau minute și secunde, de exemplu 3:45.';

  @override
  String get editorNumberInvalid => 'Introdu un număr.';

  @override
  String get accountReplaceConfirmTitle => 'Ștergi melodiile locale?';

  @override
  String get accountReplaceConfirmBody =>
      'Melodiile și listele de pe acest dispozitiv care nu se află în contul nou vor fi șterse definitiv. Acțiunea nu poate fi anulată.';

  @override
  String get accountReplaceConfirmAction => 'Șterge și înlocuiește';

  @override
  String get accountSuspiciousTitle => 'Lipsesc elemente din Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count de elemente sincronizate anterior de acest dispozitiv lipsesc din Google Drive.',
      few:
          '$count elemente sincronizate anterior de acest dispozitiv lipsesc din Google Drive.',
      one:
          '$count element sincronizat anterior de acest dispozitiv lipsește din Google Drive.',
    );
    return '$_temp0 Se poate întâmpla dacă datele aplicației au fost șterse din setările Google. Nu s-a șters nimic încă.';
  }

  @override
  String get accountSuspiciousDelete => 'Șterge-le și de aici';

  @override
  String get accountSuspiciousKeep =>
      'Păstrează melodiile și încarcă-le din nou';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ștergi $count de elemente de pe acest dispozitiv?',
      few: 'Ștergi $count elemente de pe acest dispozitiv?',
      one: 'Ștergi $count element de pe acest dispozitiv?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Aceste melodii și liste de piese vor fi șterse definitiv de pe acest dispozitiv. Acțiunea nu poate fi anulată.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Șterge de pe acest dispozitiv';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Lipsesc elemente din Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Nu s-a șters nimic. Alege dacă le ștergi și de aici sau le încarci din nou.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive s-a modificat în timpul sincronizării.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Nu s-a pierdut nimic. Sincronizează din nou pentru a prelua cele mai recente modificări.';

  @override
  String get syncErrorInvalidLocalData =>
      'Unele date de pe acest dispozitiv nu au putut fi sincronizate.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'O melodie sau o listă de piese nu a putut fi citită. Importă-o sau creeaz-o din nou, apoi sincronizează.';

  @override
  String get syncErrorNoAccountChange =>
      'Nu există nicio schimbare de cont de rezolvat.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Sincronizează din nou pentru a continua.';

  @override
  String get accountSyncWarningTitle =>
      'Sincronizare reușită, dar unele fișiere au fost omise';

  @override
  String get accountSyncWarningBody =>
      'Unele fișiere nu au putut fi folosite și au rămas neschimbate. Restul este actualizat.';

  @override
  String get accountSyncWarningTooLarge =>
      'Un fișier era prea mare pentru sincronizare și a fost omis. Restul este actualizat.';

  @override
  String get accountSyncWarningInvalid =>
      'Un fișier nu a putut fi citit și a fost omis. Restul este actualizat.';

  @override
  String get accountNoticeSyncSkipped =>
      'Sincronizat. Unele fișiere au fost omise.';

  @override
  String get settingsExportPdfTooLarge =>
      'Acest PDF ar fi prea mare. Încearcă mai puține melodii sau distribuie-l ca text.';

  @override
  String get settingsTimingTooLarge =>
      'Datele de temporizare sunt prea mari (peste 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Această copie de rezervă conține aceeași melodie de două ori, așa că nu s-a importat nimic.';

  @override
  String get setlistSaveConflict =>
      'Lista de piese s-a modificat în altă parte. Modificările tale au fost salvate într-o copie separată.';

  @override
  String get sectionVerse => 'Strofă';

  @override
  String get sectionChorus => 'Refren';

  @override
  String get sectionBridge => 'Pod';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pre-refren';

  @override
  String get sectionPostChorus => 'Post-refren';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Interludiu';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Reluare';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Codă';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Final';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de versiuni disponibile',
      few: '$count de versiuni disponibile',
      one: '$count versiune disponibilă',
      zero: 'Nu există versiuni disponibile',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de versiuni indisponibile',
      few: '$count de versiuni indisponibile',
      one: '$count versiune indisponibilă',
      zero: 'Nu există versiuni indisponibile',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Salt la secțiune';

  @override
  String get searchVersionDetails => 'Detalii despre versiune';

  @override
  String get searchSelectedRecording => 'Înregistrarea selectată';

  @override
  String get searchVersionDuration => 'Durata versiunii';

  @override
  String get searchSourceOptions => 'Opțiuni sursă';

  @override
  String get actionUndo => 'Anulează';

  @override
  String setlistEntryRemoved(String song) {
    return 'Piesa „$song” a fost eliminată din listă';
  }

  @override
  String get backupTitle => 'Copie de rezervă și restaurare';

  @override
  String get backupExport => 'Exportă copia de rezervă';

  @override
  String get backupRestore => 'Restaurează copia de rezervă';

  @override
  String get backupIncludePreferences => 'Include preferințele aplicației';

  @override
  String get backupRestorePreferences => 'Restaurează preferințele aplicației';

  @override
  String get backupMerge => 'Adaugă în această bibliotecă';

  @override
  String get backupMergeHint =>
      'Păstrează modificările locale și adaugă piesele și listele din această copie.';

  @override
  String get backupReplace => 'Înlocuiește această bibliotecă';

  @override
  String get backupReplaceHint =>
      'Înlocuiește toate piesele și listele de pe acest dispozitiv cu conținutul copiei.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Piese: $songs · Liste: $setlists · Conflicte: $conflicts';
  }

  @override
  String get backupFailed =>
      'Operația nu a putut fi finalizată. Încearcă din nou.';

  @override
  String get backupRestored => 'Copia de rezervă a fost restaurată.';

  @override
  String get backupLocalHint =>
      'Salvează o copie a bibliotecii. Datele contului și cookie-urile de consimțământ nu sunt incluse.';

  @override
  String get backupReplaceConfirm =>
      'Înlocuiești biblioteca actuală? Acțiunea nu poate fi anulată.';

  @override
  String get searchCheckOperations => 'Operațiuni';

  @override
  String get searchCheckCode => 'Codul rezultatului';

  @override
  String get searchCheckQueued => 'Se așteaptă verificarea acestei surse.';

  @override
  String get searchCheckFetch => 'Încarcă versurile';

  @override
  String get searchCheckValidate => 'Verifică potrivirea melodiei';

  @override
  String get searchCheckCorroborate => 'Verifică potrivirea versurilor';

  @override
  String get searchCheckCompleted => 'Finalizat';

  @override
  String get searchCheckTimeout => 'Sursa nu a răspuns la timp.';

  @override
  String get searchCheckBlocked => 'Sursa a blocat solicitarea.';

  @override
  String get searchCheckRateLimited =>
      'Sursa limitează solicitările. Încearcă din nou mai târziu.';

  @override
  String get searchCheckNetwork =>
      'Sursa nu poate fi accesată. Verifică conexiunea.';

  @override
  String get searchCheckInvalid => 'Sursa a returnat un răspuns ilizibil.';

  @override
  String get searchCheckNotConfigured =>
      'Această sursă nu este configurată în această versiune.';

  @override
  String get searchCheckNoLyrics => 'Nu au fost găsite versuri potrivite.';

  @override
  String get searchCheckFailed => 'Operațiunea nu a putut fi finalizată.';

  @override
  String get searchCheckNoHistory =>
      'Nu s-au efectuat verificări ale surselor pentru această comparație.';

  @override
  String get searchVersionCredits => 'Credite';

  @override
  String get searchVersionMediaLinks => 'Linkuri asociate';

  @override
  String get searchCheckCancelled => 'Anulat';

  @override
  String get searchCheckAmbiguous =>
      'Au fost găsite mai multe potriviri. Această sursă are nevoie de o înregistrare mai exactă.';

  @override
  String get searchCheckIdentity =>
      'Această sursă are nevoie de identificatorul unei înregistrări sau al unei opere.';

  @override
  String get searchCheckExtraction =>
      'Sursa a răspuns, dar versurile nu au putut fi extrase.';

  @override
  String get searchCheckBusy =>
      'Sursa este ocupată. Încearcă din nou mai târziu.';

  @override
  String get searchCheckSelection =>
      'Alege un rezultat specific din această sursă.';

  @override
  String get playerChordsNone => 'Niciunul';

  @override
  String get editorCustomValue => 'Altul…';

  @override
  String get editorStandardTuning => 'Acordaj standard';

  @override
  String get editorExampleVerse =>
      '[C]O nouă zi ne [G]cheamă,\n[Am]urmăm lumina înapoi spre [F]casă.';

  @override
  String get editorExampleChorus =>
      '[F]Să cântăm acest cântec [C]împreună,\n[G]să ne poarte melodia [C]mai departe.';

  @override
  String get editorExampleBridge => '[Am]Încă un vers, puțin mai [F]aproape.';
}
