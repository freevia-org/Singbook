// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Spokojne miejsce do wyszukiwania, porządkowania i śpiewania utworów z Twojej biblioteki.';

  @override
  String get aboutMadeForSinging => 'Stworzone do wspólnego śpiewania';

  @override
  String appVersion(String version) {
    return 'Wersja $version';
  }

  @override
  String get navHome => 'Strona główna';

  @override
  String get navSongs => 'Utwory';

  @override
  String get navSetlists => 'Listy utworów';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String get navSettingsCompact => 'Ustawienia';

  @override
  String get navSearch => 'Szukaj';

  @override
  String get navBack => 'Wstecz';

  @override
  String get navClose => 'Zamknij';

  @override
  String get navMore => 'Więcej działań';

  @override
  String get actionCancel => 'Anuluj';

  @override
  String get actionSave => 'Zapisz';

  @override
  String get actionDone => 'Gotowe';

  @override
  String get actionEdit => 'Edytuj';

  @override
  String get actionDelete => 'Usuń';

  @override
  String get actionShare => 'Udostępnij';

  @override
  String get actionPrint => 'Drukuj';

  @override
  String get actionCopy => 'Kopiuj';

  @override
  String get actionClear => 'Wyczyść';

  @override
  String get actionRetry => 'Spróbuj ponownie';

  @override
  String get actionRefresh => 'Odśwież';

  @override
  String get actionImport => 'Importuj';

  @override
  String get actionExport => 'Eksportuj';

  @override
  String get actionExpand => 'Rozwiń';

  @override
  String get actionCollapse => 'Zwiń';

  @override
  String get actionAdd => 'Dodaj';

  @override
  String get actionCreate => 'Utwórz';

  @override
  String get actionRemove => 'Usuń';

  @override
  String get actionDuplicate => 'Duplikuj';

  @override
  String get actionMoveUp => 'Przenieś wyżej';

  @override
  String get actionMoveDown => 'Przenieś niżej';

  @override
  String get actionPrevious => 'Poprzedni';

  @override
  String get actionNext => 'Następny';

  @override
  String get searchHint => 'Szukaj utworów, wykonawców lub tekstów';

  @override
  String get searchCatalogHint => 'Szukaj utworu lub wykonawcy';

  @override
  String get searchSubmit => 'Szukaj';

  @override
  String get searchFilters => 'Opcje wyszukiwania';

  @override
  String get searchFiltersShow => 'Pokaż opcje wyszukiwania';

  @override
  String get searchFiltersHide => 'Ukryj opcje wyszukiwania';

  @override
  String get searchFilterArtist => 'Wykonawca';

  @override
  String get searchFilterTitle => 'Tytuł utworu';

  @override
  String get searchFilterLyrics => 'Tekst';

  @override
  String get searchFilterChords => 'Zawiera akordy';

  @override
  String get searchFilterTimed => 'Tekst zsynchronizowany';

  @override
  String get searchFilterLanguage => 'Język';

  @override
  String get searchFilterAll => 'Dowolny';

  @override
  String get searchAutocompleteLabel => 'Sugestie';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyniku',
      many: '$count wyników',
      few: '$count wyniki',
      one: '$count wynik',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Wpisz utwór, wykonawcę lub fragment tekstu, aby wyszukać.';

  @override
  String get searchCatalogEmptyQuery =>
      'Wpisz utwór lub wykonawcę, aby wyszukać.';

  @override
  String get searchNoResults =>
      'Nie znaleziono utworów. Spróbuj wyszukać coś innego.';

  @override
  String get searchLoading => 'Wyszukiwanie utworów…';

  @override
  String get searchError => 'Nie udało się ukończyć wyszukiwania.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Ostatnie';

  @override
  String get searchFavoritesTab => 'Ulubione';

  @override
  String get searchSuggested => 'Sugerowane dopasowanie';

  @override
  String get searchAlternatives => 'Inne dopasowania';

  @override
  String get searchCompare => 'Porównaj wersje';

  @override
  String get searchChooseVersion => 'Wybierz tę wersję';

  @override
  String get searchSongMatch => 'Dopasowanie utworu';

  @override
  String get searchRecordingMatch => 'Dopasowanie nagrania';

  @override
  String get searchMatchUnverified => 'Nagranie niezweryfikowane';

  @override
  String get searchMatchExact => 'Dokładne dopasowanie nagrania';

  @override
  String get searchMatchPossible => 'Możliwe dopasowanie';

  @override
  String get searchAvailability => 'Dostępność';

  @override
  String get searchLyricsAvailable => 'Tekst dostępny';

  @override
  String get searchLyricsUnavailable => 'Tekst niedostępny';

  @override
  String get searchChordsAvailable => 'Akordy dostępne';

  @override
  String get searchChordsUnavailable => 'Brak akordów';

  @override
  String get searchTimingAvailable => 'Synchronizacja dostępna';

  @override
  String get searchTimingUnavailable => 'Brak synchronizacji';

  @override
  String get searchDurationUnknown => 'Nieznany czas trwania';

  @override
  String searchRating(String rating) {
    return 'Ocena $rating';
  }

  @override
  String get searchSourceLabel => 'Źródło';

  @override
  String get searchMetadata => 'Szczegóły utworu';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Wykonawca';

  @override
  String get searchYear => 'Rok';

  @override
  String get searchLanguage => 'Język';

  @override
  String get searchSaved => 'Utwór został zapisany w bibliotece.';

  @override
  String get searchSaveFailed => 'Nie udało się zapisać tego utworu.';

  @override
  String get homeRecentSongs => 'Ostatnie utwory';

  @override
  String get homeRecentlyPlayed => 'Ostatnio odtwarzane';

  @override
  String get homeFavorites => 'Ulubione';

  @override
  String get homeHistory => 'Historia';

  @override
  String get homeHistoryClear => 'Wyczyść historię';

  @override
  String get homeHistoryCleared => 'Historia została wyczyszczona.';

  @override
  String get homeHistoryEmpty => 'Otwarte utwory pojawią się tutaj.';

  @override
  String get homeFavoritesEmpty => 'Ulubione utwory i listy pojawią się tutaj.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wyświetlono $count elementu',
      many: 'Wyświetlono $count elementów',
      few: 'Wyświetlono $count elementy',
      one: 'Wyświetlono $count element',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty => 'Ostatnie utwory i listy pojawią się tutaj.';

  @override
  String get homeTimelineLabel => 'Oś czasu historii';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Pełna historia';

  @override
  String get homeShowFavorites => 'Pokaż ulubione';

  @override
  String get homeShowRecent => 'Pokaż ostatnie';

  @override
  String get songsTitle => 'Utwory';

  @override
  String get songsEmpty => 'Twoje utwory pojawią się tutaj.';

  @override
  String get songsEmptySearch => 'Żaden utwór nie pasuje do wyszukiwania.';

  @override
  String get songsAdd => 'Dodaj utwór';

  @override
  String get songsSortAlphabetical => 'Sortuj alfabetycznie';

  @override
  String get songsAlphabetNavigation => 'Indeks utworów';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count raza',
      many: '$count razy',
      few: '$count razy',
      one: 'raz',
    );
    return 'Otwarto $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Dodaj do ulubionych';

  @override
  String get songFavoriteRemove => 'Usuń z ulubionych';

  @override
  String get songMenuLabel => 'Działania dotyczące utworu';

  @override
  String get songInfo => 'Szczegóły utworu';

  @override
  String get setlistMenuLabel => 'Działania dotyczące listy';

  @override
  String get songAddToSetlist => 'Dodaj do listy';

  @override
  String get songCopyChordPro => 'Kopiuj ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Usunąć utwór?';

  @override
  String get songDeleteConfirmMessage =>
      'Utwór zostanie usunięty z biblioteki.';

  @override
  String get songDeleted => 'Utwór został usunięty.';

  @override
  String get setlistsTitle => 'Listy utworów';

  @override
  String get setlistsEmpty => 'Utwórz listę na następną próbę lub występ.';

  @override
  String get setlistsEmptySearch => 'Żadna lista nie pasuje do wyszukiwania.';

  @override
  String get setlistCreate => 'Nowa lista';

  @override
  String get setlistNameHint => 'Nazwa listy';

  @override
  String get setlistNotes => 'Notatki';

  @override
  String get setlistEntryOverride => 'Tonacja i capo dla tego utworu';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utworu',
      many: '$count utworów',
      few: '$count utwory',
      one: '$count utwór',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Co najmniej $duration';
  }

  @override
  String get setlistDurationUnknown => 'Nieznany czas trwania';

  @override
  String setlistActivity(String date) {
    return 'Ostatnia aktywność $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Utworzono $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Edytowano $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Ostatnio odtwarzano $date';
  }

  @override
  String get setlistSongsEmpty => 'Ta lista nie zawiera jeszcze utworów.';

  @override
  String get setlistAddSongs => 'Dodaj utwory';

  @override
  String get setlistReorder => 'Zmień kolejność utworów';

  @override
  String setlistMoveSongUp(String song) {
    return 'Przenieś utwór $song wyżej';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Przenieś utwór $song niżej';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Usuń utwór $song z listy';
  }

  @override
  String get setlistDuplicate => 'Duplikuj listę';

  @override
  String get setlistFavoriteAdd => 'Dodaj listę do ulubionych';

  @override
  String get setlistFavoriteRemove => 'Usuń listę z ulubionych';

  @override
  String get setlistShare => 'Udostępnij jako plik listy';

  @override
  String get setlistSharePdf => 'Udostępnij jako PDF';

  @override
  String get setlistPrint => 'Drukuj';

  @override
  String get setlistDeleteConfirmTitle => 'Usunąć listę?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Lista zostanie usunięta. Utwory w bibliotece pozostaną.';

  @override
  String get setlistDeleted => 'Lista została usunięta.';

  @override
  String get readerTitle => 'Tekst';

  @override
  String get readerNoLyrics => 'Tekst nie został jeszcze dodany.';

  @override
  String get readerShowChords => 'Pokaż akordy';

  @override
  String get readerHideChords => 'Ukryj akordy';

  @override
  String get readerTranspose => 'Transponuj akordy';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count półtonu',
      many: '$count półtonów',
      few: '$count półtony',
      one: '$count półton',
    );
    return 'Transponuj o $_temp0';
  }

  @override
  String get readerEdit => 'Edytuj tekst i szczegóły';

  @override
  String get playerPlay => 'Włącz przewijanie tekstu';

  @override
  String get playerPause => 'Wstrzymaj przewijanie tekstu';

  @override
  String get playerResume => 'Wznów przewijanie tekstu';

  @override
  String get playerSeek => 'Pozycja odtwarzania';

  @override
  String playerElapsed(String time) {
    return 'Czas, który upłynął: $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Pozostały czas: $time';
  }

  @override
  String get playerTimingMode => 'Tryb przewijania';

  @override
  String get playerTimedLyrics => 'Tekst zsynchronizowany';

  @override
  String get playerEstimatedPace => 'Szacowane tempo';

  @override
  String get playerManualScroll => 'Przewijanie ręczne';

  @override
  String get playerTimingStatusReady =>
      'Tekst będzie przewijany zgodnie z dostępną synchronizacją.';

  @override
  String get playerTimingStatusEstimated =>
      'Tempo przewijania jest szacowane na podstawie długości utworu.';

  @override
  String get playerTimingStatusManual => 'Przewijaj tekst samodzielnie.';

  @override
  String get playerTimingStatusUnavailable =>
      'Synchronizowane przewijanie jest niedostępne dla tego utworu.';

  @override
  String get playerDurationUnknown =>
      'Dodaj czas trwania utworu, aby użyć szacowanego przewijania.';

  @override
  String get playerProgressLabel => 'Postęp utworu';

  @override
  String get playerCurrentSection => 'Bieżąca część';

  @override
  String get playerPreviousSection => 'Poprzednia część';

  @override
  String get playerNextSection => 'Następna część';

  @override
  String get playerPreviousSectionSong =>
      'Poprzednia część · przytrzymaj, aby przejść do poprzedniego utworu na liście';

  @override
  String get playerNextSectionSong =>
      'Następna część · przytrzymaj, aby przejść do następnego utworu na liście';

  @override
  String get playerPreviousSong => 'Poprzedni utwór';

  @override
  String get playerNextSong => 'Następny utwór';

  @override
  String get editorTitle => 'Edytuj utwór';

  @override
  String get editorTitleField => 'Tytuł utworu';

  @override
  String get editorArtistField => 'Wykonawca';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Tekst';

  @override
  String get editorChordsField => 'Akordy';

  @override
  String get editorKeyField => 'Tonacja';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Strojenie';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Czas trwania';

  @override
  String get editorTimeSignatureField => 'Metrum';

  @override
  String get editorLanguageField => 'Język';

  @override
  String get editorYearField => 'Rok';

  @override
  String get editorComposerField => 'Kompozytor';

  @override
  String get editorLyricistField => 'Autor tekstu';

  @override
  String get editorCopyrightField => 'Prawa autorskie';

  @override
  String get editorLicenseField => 'Licencja';

  @override
  String get songInfoSources => 'Źródła i informacje o autorach';

  @override
  String get searchMatchSameSong =>
      'Ten sam utwór; nagranie nie zostało potwierdzone';

  @override
  String get searchMatchNeedsAgreement =>
      'Akordy wymagają potwierdzenia tekstu';

  @override
  String get searchMatchDifferentLyrics =>
      'Tekst różni się od tekstu wybranego utworu';

  @override
  String get searchMatchCombinedSources => 'Szczegóły połączono z wielu źródeł';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Połączono z $count źródła',
      many: 'Połączono z $count źródeł',
      few: 'Połączono z $count źródeł',
      one: 'Połączono z $count źródła',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dopasowania utworu',
      many: '$count dopasowań utworu',
      few: '$count dopasowania utworu',
      one: '$count dopasowanie utworu',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wersji ze źródła',
      many: '$count wersji ze źródła',
      few: '$count wersje ze źródła',
      one: '$count wersja ze źródła',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Najlepsze dostępne dopasowanie';

  @override
  String get providerDescriptionUnknown => 'Źródło utworu';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Pobierz plik ChordPro ze źródła, a następnie go zaimportuj.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Pobierz plik przy użyciu bezpłatnego konta, a następnie go zaimportuj.';

  @override
  String get providerDescPublicChordSheets => 'Publiczne śpiewniki z akordami.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Historyczne teksty licencjonowane dla każdego utworu.';

  @override
  String get providerDescLicensedCatalog => 'Licencjonowany katalog tekstów.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Oryginalne utwory na licencji Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Teksty licencjonowane dla każdego utworu.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Tylko informacje o nagraniu i wydaniu.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Tylko informacje o kompozycji.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Okładka tylko dla dokładnie dopasowanych nagrań.';

  @override
  String get providerCapabilityLyrics => 'Tekst';

  @override
  String get providerCapabilityChords => 'Akordy';

  @override
  String get providerCapabilityTiming => 'Tekst zsynchronizowany';

  @override
  String get providerCapabilitySearch => 'Wyszukiwanie';

  @override
  String get providerCapabilityMetadata => 'Szczegóły utworu';

  @override
  String get editorArtworkField => 'Link do okładki';

  @override
  String get editorLyricsHint =>
      'Dotknij wersu, aby edytować tekst lub akordy.';

  @override
  String get editorSave => 'Zapisz zmiany';

  @override
  String get editorSaved => 'Zmiany zostały zapisane.';

  @override
  String get editorSaveFailed => 'Nie udało się zapisać zmian.';

  @override
  String get editorSaveConflict =>
      'Utwór został zmieniony w innym miejscu. Twoje zmiany zapisano jako osobną kopię.';

  @override
  String get editorUnsavedTitle => 'Odrzucić zmiany?';

  @override
  String get editorUnsavedMessage => 'Twoje zmiany nie zostały zapisane.';

  @override
  String get editorFieldRequired => 'Wpisz tytuł utworu.';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsAppearance => 'Wygląd';

  @override
  String get settingsTheme => 'Motyw';

  @override
  String get settingsThemeSystem => 'Użyj ustawień urządzenia';

  @override
  String get settingsThemeLight => 'Jasny';

  @override
  String get settingsThemeDark => 'Ciemny';

  @override
  String get settingsColorPalette => 'Paleta kolorów';

  @override
  String get settingsFont => 'Czcionka';

  @override
  String get settingsTextSize => 'Rozmiar tekstu';

  @override
  String get settingsLyricsPreview => 'Podgląd tekstu';

  @override
  String get settingsPlayer => 'Odtwarzacz tekstu';

  @override
  String get settingsDefaultShowChords => 'Domyślnie pokazuj akordy';

  @override
  String get settingsDefaultAutoscroll =>
      'Automatycznie rozpocznij przewijanie tekstu';

  @override
  String get settingsDefaultTiming => 'Domyślny tryb przewijania';

  @override
  String get settingsLanguage => 'Język aplikacji';

  @override
  String get settingsLanguageSystem => 'Użyj języka urządzenia';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Źródła tekstów';

  @override
  String settingsSourceEnabled(String source) {
    return 'Włącz źródło $source';
  }

  @override
  String get settingsSourceRefresh => 'Odśwież listę źródeł';

  @override
  String get settingsSourcesUpdated => 'Źródła zostały zaktualizowane.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Nie udało się odświeżyć listy źródeł.';

  @override
  String get settingsImport => 'Importuj utwory';

  @override
  String get settingsImportChordPro => 'Importuj plik ChordPro';

  @override
  String get settingsImportSetlist => 'Importuj plik listy utworów';

  @override
  String get settingsImportSuccess => 'Import zakończony.';

  @override
  String get settingsImportFailed => 'Nie udało się zaimportować tego pliku.';

  @override
  String get settingsImportUnsupported => 'Ten typ pliku nie jest obsługiwany.';

  @override
  String get settingsShareSong => 'Udostępnij jako ChordPro';

  @override
  String get settingsSharePdf => 'Udostępnij jako PDF';

  @override
  String get settingsCopySong => 'Kopiuj do schowka';

  @override
  String get settingsPrintSong => 'Drukuj tylko utwór';

  @override
  String get settingsPrintSetlist => 'Drukuj listę z tekstami';

  @override
  String get settingsExportFailed => 'Nie udało się przygotować pliku.';

  @override
  String get settingsCopied => 'Skopiowano do schowka.';

  @override
  String get settingsAbout => 'Informacje';

  @override
  String get settingsPrivacy => 'Prywatność';

  @override
  String get settingsLegal => 'Informacje prawne';

  @override
  String get settingsClearHistory => 'Wyczyść historię';

  @override
  String get settingsClearHistoryConfirm =>
      'Wyczyścić historię utworów i list?';

  @override
  String get settingsHistoryCleared => 'Historia została wyczyszczona.';

  @override
  String get accountTitle => 'Konto i synchronizacja';

  @override
  String get accountUnavailable =>
      'Synchronizacja wymaga wersji Singbook skonfigurowanej do logowania przez Google. Ta wersja przechowuje utwory tylko na tym urządzeniu.';

  @override
  String get accountSyncNow => 'Synchronizuj teraz';

  @override
  String get accountConnected =>
      'Połączono. Wybierz „Synchronizuj teraz”, aby zaktualizować kopię zapasową.';

  @override
  String get accountSignIn => 'Połącz konto';

  @override
  String get accountSignOut => 'Wyloguj się';

  @override
  String get accountChange => 'Zmień konto';

  @override
  String get accountSignedOut => 'Nie połączono';

  @override
  String get accountSyncing => 'Synchronizowanie biblioteki…';

  @override
  String get accountSynced => 'Biblioteka została zsynchronizowana.';

  @override
  String get accountSyncFailed => 'Nie udało się zsynchronizować biblioteki.';

  @override
  String get accessibilityFavorite => 'Ulubiony';

  @override
  String get accessibilityNotFavorite => 'Nie jest ulubiony';

  @override
  String get accessibilitySearchField => 'Szukaj utworów';

  @override
  String get accessibilityClearSearch => 'Wyczyść tekst wyszukiwania';

  @override
  String accessibilitySongMenu(String song) {
    return 'Działania dotyczące utworu $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Działania dotyczące listy $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Rozwiń utwory na liście $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Zwiń utwory na liście $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Postęp odtwarzania, $percent procent';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Oś czasu historii, $date';
  }

  @override
  String get loading => 'Ładowanie…';

  @override
  String get loadingSongs => 'Ładowanie utworów…';

  @override
  String get loadingSetlists => 'Ładowanie list…';

  @override
  String get errorGeneric => 'Coś poszło nie tak.';

  @override
  String get errorOffline =>
      'Wygląda na to, że nie masz połączenia z internetem.';

  @override
  String get errorPermission => 'Do kontynuowania potrzebne są uprawnienia.';

  @override
  String get emptyFiltered => 'Żaden element nie pasuje do tych filtrów.';

  @override
  String get unknownValue => 'Nieznane';

  @override
  String get durationUnknown => 'Nieznany czas trwania';

  @override
  String get metadataNotSet => 'Nie ustawiono';

  @override
  String get dateToday => 'Dzisiaj';

  @override
  String get dateYesterday => 'Wczoraj';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utworu',
      many: '$count utworów',
      few: '$count utwory',
      one: '$count utwór',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Granatowy';

  @override
  String get settingsPaletteSage => 'Szałwiowy';

  @override
  String get settingsPaletteOcean => 'Oceaniczny';

  @override
  String get settingsPaletteClay => 'Gliniany';

  @override
  String get settingsPalettePlum => 'Śliwkowy';

  @override
  String get settingsFontSystem => 'Systemowa';

  @override
  String get settingsFontSerif => 'Szeryfowa';

  @override
  String get settingsFontMonospace => 'Monospace';

  @override
  String get settingsLyricsPreviewExample =>
      'Gdy nadejdzie poranek, znów zaśpiewamy.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Sprawdzanie źródeł tekstów: ukończono $checked z $total.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Nie znaleziono tekstu, którego można użyć.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Wybrany utwór sprawdzono we włączonych źródłach, ale żadne z nich nie zwróciło użytecznej wersji tekstu.';

  @override
  String get searchDiscoveryError => 'Nie udało się sprawdzić źródeł tekstów.';

  @override
  String get searchDiscoveryRetry => 'Ponów wyszukiwanie tekstu';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niedostępnego źródła',
      many: '$count niedostępnych źródeł',
      few: '$count niedostępne źródła',
      one: '$count niedostępne źródło',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get searchProviderChecks => 'Sprawdzanie źródeł';

  @override
  String get searchProviderPending => 'Sprawdzanie';

  @override
  String get searchProviderFound => 'Znaleziono dopasowanie';

  @override
  String get searchProviderRejected => 'Nie pasuje';

  @override
  String get searchProviderFailed => 'Sprawdzanie nie powiodło się';

  @override
  String get searchProviderUnavailable => 'Brak tekstu, którego można użyć';

  @override
  String get searchCatalogFilterHint =>
      'Wybierz utwór, aby filtrować wersje tekstu według akordów, synchronizacji lub języka.';

  @override
  String get startupErrorTitle => 'Nie udało się otworzyć biblioteki.';

  @override
  String setlistCopyName(String name) {
    return 'Kopia: $name';
  }

  @override
  String get setlistSongMissing => 'Brak utworu';

  @override
  String get settingsImportTooLarge =>
      'Ten plik jest za duży, aby go zaimportować.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Przejdź do litery $letter';
  }

  @override
  String get actionDiscard => 'Odrzuć';

  @override
  String get editorKeepEditing => 'Kontynuuj edycję';

  @override
  String get settingsDefaultShowChordsHint =>
      'Pokazuj akordy nad tekstem, jeśli są dostępne dla utworu.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Tekst przewija się razem z utworem. Nie dotyczy trybu przewijania ręcznego.';

  @override
  String get accountUnavailableTitle =>
      'Synchronizacja nie jest skonfigurowana';

  @override
  String get accountSignedOutBenefits =>
      'Zaloguj się przez Google, aby tworzyć kopie zapasowe utworów i list na Dysku Google oraz synchronizować wszystkie urządzenia. Utwory pozostaną na tym urządzeniu niezależnie od tego.';

  @override
  String get accountSignInWithGoogle => 'Zaloguj się przez Google';

  @override
  String get accountWorking => 'Przetwarzanie…';

  @override
  String get accountNeverSynced => 'Nigdy nie synchronizowano';

  @override
  String get accountSyncedJustNow => 'Zsynchronizowano przed chwilą';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zsynchronizowano $count minuty temu',
      many: 'Zsynchronizowano $count minut temu',
      few: 'Zsynchronizowano $count minuty temu',
      one: 'Zsynchronizowano minutę temu',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zsynchronizowano $count godziny temu',
      many: 'Zsynchronizowano $count godzin temu',
      few: 'Zsynchronizowano $count godziny temu',
      one: 'Zsynchronizowano godzinę temu',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zsynchronizowano $count dnia temu',
      many: 'Zsynchronizowano $count dni temu',
      few: 'Zsynchronizowano $count dni temu',
      one: 'Zsynchronizowano dzień temu',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count konfliktowej edycji zachowano jako kopii',
      many: '$count konfliktowych edycji zachowano jako kopie',
      few: '$count konfliktowe edycje zachowano jako kopie',
      one: '1 konfliktowa edycja została zachowana jako kopia',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Ten sam utwór lub lista zostały edytowane w dwóch miejscach. Nic nie utracono: druga wersja została zapisana jako osobna kopia.';

  @override
  String get accountReviewConflicts => 'Przejrzyj kopie';

  @override
  String get songsConflictFilterActive =>
      'Wyświetlane są tylko kopie konfliktowe';

  @override
  String get songsConflictFilterClear => 'Pokaż wszystkie utwory';

  @override
  String get songsConflictBadge => 'Kopia konfliktowa';

  @override
  String get songsConflictEmpty => 'Brak kopii konfliktowych.';

  @override
  String get accountAutoSync => 'Synchronizuj automatycznie';

  @override
  String get accountAutoSyncHint =>
      'Aktualizuj bibliotekę po otwarciu aplikacji i po wprowadzeniu zmian.';

  @override
  String get accountSignOutTitle => 'Wylogować się z tego konta?';

  @override
  String get accountSignOutBody =>
      'Utwory i listy pozostaną na tym urządzeniu. Nie będą tworzone ich kopie zapasowe ani synchronizowane, dopóki nie zalogujesz się ponownie.';

  @override
  String get accountUseDifferent => 'Użyj innego konta';

  @override
  String get accountSignInAgain => 'Zaloguj się ponownie';

  @override
  String get accountChooseAction => 'Wybierz, jak kontynuować';

  @override
  String get accountChangedTitle => 'Inne konto Google';

  @override
  String get accountChangedBody =>
      'To urządzenie było ostatnio synchronizowane z innym kontem Google. Wybierz, co zrobić z utworami i listami na tym urządzeniu.';

  @override
  String get accountChangedMerge => 'Scal z nowym kontem';

  @override
  String get accountChangedMergeHint =>
      'Zachowaj wszystko na tym urządzeniu i dodaj do nowego konta.';

  @override
  String get accountChangedReplace => 'Zastąp biblioteką z nowego konta';

  @override
  String get accountChangedReplaceHint =>
      'Utwory z tego urządzenia, których nie ma na nowym koncie, zostaną usunięte.';

  @override
  String get accountChangedSignOut => 'Anuluj i wyloguj się';

  @override
  String get accountStatusSignedOut => 'Konto i synchronizacja: wylogowano';

  @override
  String get accountStatusSignedIn => 'Konto i synchronizacja: zalogowano';

  @override
  String get accountStatusSyncing =>
      'Konto i synchronizacja: trwa synchronizacja';

  @override
  String get accountStatusSynced =>
      'Konto i synchronizacja: biblioteka aktualna';

  @override
  String get accountStatusError =>
      'Konto i synchronizacja: problem, dotknij, aby sprawdzić';

  @override
  String get accountNoticeConflicts =>
      'Niektóre utwory edytowano w dwóch miejscach. Zachowano kopie.';

  @override
  String get accountNoticeSignedIn => 'Zalogowano.';

  @override
  String get accountNoticeSignedOut =>
      'Wylogowano. Utwory pozostają na tym urządzeniu.';

  @override
  String get syncErrorNotConfigured =>
      'Synchronizacja nie jest skonfigurowana w tej wersji.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Użyj wersji Singbook skonfigurowanej do logowania przez Google.';

  @override
  String get syncErrorNotSignedIn => 'Nie jesteś zalogowany.';

  @override
  String get syncErrorNotSignedInHint =>
      'Zaloguj się, aby zsynchronizować bibliotekę.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google wymaga ponownego zalogowania.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Zaloguj się ponownie, aby kontynuować synchronizację. Utwory są bezpieczne na tym urządzeniu.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook nie ma uprawnień do korzystania z Dysku Google.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Zaloguj się ponownie i zezwól na dostęp do Dysku, gdy pojawi się prośba.';

  @override
  String get syncErrorRateLimited =>
      'Google tymczasowo ogranicza liczbę żądań.';

  @override
  String get syncErrorRateLimitedHint =>
      'Odczekaj kilka minut i spróbuj ponownie.';

  @override
  String get syncErrorStorageFull => 'Dysk Google jest pełny.';

  @override
  String get syncErrorStorageFullHint =>
      'Zwolnij miejsce na Dysku i spróbuj ponownie.';

  @override
  String get syncErrorNetwork => 'Nie udało się połączyć z Google.';

  @override
  String get syncErrorNetworkHint =>
      'Sprawdź połączenie z internetem i spróbuj ponownie.';

  @override
  String get syncErrorAccountChanged => 'Użyto innego konta Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Wybierz, czy scalić bibliotekę z tego urządzenia z biblioteką konta, czy ją zastąpić.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Zsynchronizowana biblioteka jest zbyt duża dla Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Usuń kilka utworów lub list ze zsynchronizowanej biblioteki i spróbuj ponownie.';

  @override
  String get syncErrorSignInFailed => 'Logowanie nie zostało ukończone.';

  @override
  String get syncErrorSignInFailedHint => 'Spróbuj zalogować się ponownie.';

  @override
  String get syncErrorGeneric => 'Nie udało się zsynchronizować biblioteki.';

  @override
  String get syncErrorGenericHint =>
      'Spróbuj ponownie za chwilę. Utwory są bezpieczne na tym urządzeniu.';

  @override
  String get editorDurationInvalid =>
      'Wpisz sekundy albo minuty i sekundy, na przykład 3:45.';

  @override
  String get editorNumberInvalid => 'Wpisz liczbę.';

  @override
  String get accountReplaceConfirmTitle => 'Usunąć lokalne utwory?';

  @override
  String get accountReplaceConfirmBody =>
      'Utwory i listy na tym urządzeniu, których nie ma na nowym koncie, zostaną trwale usunięte. Tej operacji nie można cofnąć.';

  @override
  String get accountReplaceConfirmAction => 'Usuń i zastąp';

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
  String get sectionVerse => 'Zwrotka';

  @override
  String get sectionChorus => 'Refren';

  @override
  String get sectionBridge => 'Bridge';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Przedrefren';

  @override
  String get sectionPostChorus => 'Zarefren';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Przejście';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Przyśpiew';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Koda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Zakończenie';
}
