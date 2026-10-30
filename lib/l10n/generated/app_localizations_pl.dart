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
      'Teksty, akordy i setlisty w jednym miejscu — gotowe na próby, scenę i każde miejsce, w którym grasz.';

  @override
  String get aboutMadeForSinging => 'Każda piosenka gotowa.';

  @override
  String get aboutDetails =>
      'Przeszukuj dostępne źródła i porównuj teksty, akordy, znaczniki czasowe oraz informacje o nagraniu, zanim zapiszesz wybraną wersję. Dostępność zależy od utworu i usługi.';

  @override
  String get aboutFindTitle => 'Znajdź właściwą wersję';

  @override
  String get aboutKeepTitle => 'Zbuduj własną bibliotekę';

  @override
  String get aboutKeepDetails =>
      'Edytuj i transponuj utwory, przechowuj je w lokalnej bibliotece do użytku offline i udostępniaj przenośne pliki ChordPro. Opcjonalna synchronizacja z Google Drive używa prywatnego folderu aplikacji na Twoim koncie Google. Możesz też stuknąć „Synchronizuj teraz”, aby zaktualizować urządzenia.';

  @override
  String get aboutPlayTitle => 'Zabierz setlistę na scenę';

  @override
  String get aboutPlayDetails =>
      'Układaj utwory w setlisty, wybieraj tonację dla każdego i udostępniaj setlisty OpenSong. Dostosuj rozmiar tekstu w czytniku, włącz automatyczne przewijanie tekstu i drukuj PDF-y z utworami. Singbook nie przesyła strumieniowo ani nie odtwarza dźwięku.';

  @override
  String get aboutPrivacyTitle =>
      'Bezpłatna aplikacja, biblioteka na urządzeniu';

  @override
  String get aboutPrivacyDetails =>
      'Singbook jest bezpłatny i nie zawiera reklam, analityki ani zakupów w aplikacji. Zapisana biblioteka pozostaje na Twoim urządzeniu; opcjonalna synchronizacja korzysta z Twojego Google Drive. Wyniki online pochodzą bezpośrednio od niezależnych usług zewnętrznych i mogą być niedostępne lub chronione prawem autorskim. Singbook nie hostuje tych treści.';

  @override
  String get aboutWebsite => 'Strona Singbook';

  @override
  String get aboutSourceCode => 'Kod źródłowy w GitHub';

  @override
  String get aboutPublisher => 'Od Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Języki aplikacji: $count';
  }

  @override
  String get aboutSupport => 'Pomoc i opinie';

  @override
  String get menuTypeNewSong => 'Wpisz nową piosenkę';

  @override
  String get menuFile => 'Plik';

  @override
  String get menuNewSong => 'Nowa piosenka';

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
  String get appExitBackAgain => 'Naciśnij ponownie Wstecz, aby wyjść';

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
  String get searchChangeSong => 'Zmień utwór';

  @override
  String get searchSelectedPreview => 'Wybrany podgląd';

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
  String get searchFullPreview => 'Pełny podgląd';

  @override
  String get searchArrangementNotes => 'Uwagi dotyczące aranżacji';

  @override
  String get searchOpenLyrics => 'Otwórz tekst';

  @override
  String get searchContributions => 'Użyte źródła';

  @override
  String get searchVersionChecking => 'Sprawdzanie tej wersji…';

  @override
  String get searchVersionUnavailable =>
      'Nie można użyć tej wersji. Wybierz inną.';

  @override
  String get searchPreviewUnavailable => 'Podgląd tekstu jest niedostępny.';

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
  String get searchPreferredSourceLabel => 'Preferowane źródło';

  @override
  String get searchPreferredSourceHint =>
      'Wyniki mogą pochodzić także z innych włączonych źródeł wyszukiwania.';

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
  String get searchViewVersions => 'Zobacz wersje';

  @override
  String get searchSaved => 'Utwór został zapisany w bibliotece.';

  @override
  String get searchSaveOpenLyrics => 'Zapisz i otwórz tekst';

  @override
  String get searchOtherResults => 'Pozostałe wyniki';

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
  String get setlistShare => 'Udostępnij jako OpenSong';

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
  String get readerSaved => 'Zapisano';

  @override
  String get readerEdit => 'Edytuj tekst i szczegóły';

  @override
  String get playerPlay => 'Odtwórz';

  @override
  String get playerPause => 'Wstrzymaj';

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
  String get playerStartScroll => 'Rozpocznij automatyczne przewijanie';

  @override
  String get playerEstimatedPace => 'Szacowane tempo';

  @override
  String get playerScrollSpeed => 'Szybkość przewijania';

  @override
  String playerEstimatedDuration(String time) {
    return 'Szacowany czas: $time';
  }

  @override
  String get playerLyricsOnly => 'Przewijanie tekstu · bez dźwięku';

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
  String get searchCombinedLabel => 'Połączone';

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
      'Akordy zapisuj w nawiasach [C], a oznaczenia części w osobnych wierszach.';

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
  String get settingsLyricHighlight => 'Podświetlenie bieżącego wersu';

  @override
  String get settingsHighlightBackgroundUnderline => 'Tło + podkreślenie';

  @override
  String get settingsHighlightBackground => 'Tło';

  @override
  String get settingsHighlightUnderline => 'Podkreślenie';

  @override
  String get settingsHighlightContrast => 'Kontrastowy kolor tekstu';

  @override
  String get settingsHighlightNone => 'Brak';

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
      'Czyści ostatnią historię aktywności utworów i setlist. Zachowuje zapisane utwory, ulubione, setlisty i ustawienia.';

  @override
  String get settingsHistoryCleared => 'Historia została wyczyszczona.';

  @override
  String get accountTitle => 'Konto i synchronizacja';

  @override
  String get accountICloudBenefits =>
      'Użyj swojego konta Apple, aby prywatnie synchronizować utwory i setlisty z iCloud. Po połączeniu zmiany synchronizują się automatycznie.';

  @override
  String get accountICloudUnavailable =>
      'iCloud jest niedostępny. Sprawdź konto Apple i dostęp do iCloud w ustawieniach systemowych, a następnie spróbuj ponownie.';

  @override
  String get accountConnectICloud => 'Połącz iCloud';

  @override
  String get accountDisconnectICloud => 'Odłącz iCloud';

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
  String get settingsPreviewSongTitle => 'Poranna pieśń';

  @override
  String get settingsPreviewArtist => 'Przykładowa aranżacja';

  @override
  String get settingsPreviewCurrentLine => 'Gdy nadejdzie poranek';

  @override
  String get settingsPreviewNextLine => 'Znów zaśpiewamy.';

  @override
  String get settingsPlayerSections => 'Nagłówki sekcji';

  @override
  String get settingsPlayerControls => 'Panel odtwarzania';

  @override
  String get settingsPlayerAutoscroll => 'Automatyczne przewijanie';

  @override
  String get settingsSystemShort => 'Urządzenie';

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
      'Połączenie Dysku Google synchronizuje bibliotekę. Późniejsze zmiany utworów są synchronizowane automatycznie.';

  @override
  String get accountManualSyncHint =>
      'Możesz też dotknąć Synchronizuj teraz, aby zsynchronizować bibliotekę.';

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
      'Synchronizacja odbywa się po połączeniu oraz po dodaniu, edycji lub usunięciu utworu.';

  @override
  String get accountDriveFolder => 'Folder biblioteki Dysku Google';

  @override
  String get accountPrivateDriveFolder => 'Prywatny folder Śpiewaka';

  @override
  String get accountChooseDriveFolder => 'Wybierz folder';

  @override
  String get accountDriveFolderMoveTitle => 'Przenieść bibliotekę Singbook?';

  @override
  String get accountDriveFolderMoveBody =>
      'Wybierz widoczny folder na Dysku Google. Singbook skopiuje i zweryfikuje tam Twoje utwory i setlisty przed przełączeniem na niego. Oryginalne pliki pozostają w poprzedniej lokalizacji jako kopia zapasowa. Pozostałe pliki pozostawiamy w spokoju. Pliki ChordPro, które zaimportujesz do tego folderu, zostaną przystosowane do synchronizacji i otrzymają metadane Singbooka.';

  @override
  String get accountImportChordPro => 'Importuj ChordPro z Dysku';

  @override
  String get accountImportChordProHint =>
      'Wybierz pliki .cho, które chcesz dodać do tej biblioteki. Pliki znajdujące się już w folderze zostaną przejęte; pliki gdzie indziej są kopiowane tutaj.';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'Wybór folderu na Dysku jest niedostępny';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'Na obsługiwanym urządzeniu wybierz widoczny folder Dysku za pomocą selektora Dysku Google.';

  @override
  String get syncErrorDriveFolderMissing =>
      'Folder na dysku Singbook jest niedostępny';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Wybierz folder ponownie lub przywróć go na Dysku Google.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook potrzebuje dostępu do tego folderu na Dysku';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Wybierz folder ponownie, aby przyznać dostęp, a następnie zsynchronizuj swoją bibliotekę.';

  @override
  String get syncErrorFolderMigration =>
      'Biblioteki nie udało się jeszcze przenieść';

  @override
  String get syncErrorFolderMigrationHint =>
      'Twoja poprzednia biblioteka jest nadal bezpieczna. Sprawdź połączenie i ponownie wybierz folder, aby spróbować ponownie.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Najpierw wybierz widoczny folder na Dysku';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'Przed importowaniem plików z Dysku potrzebny jest widoczny folder biblioteki.';

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
  String get syncErrorOAuthClientConfiguration =>
      'Google odrzuciło konfigurację logowania w tej kompilacji.';

  @override
  String get syncErrorOAuthClientConfigurationHint =>
      'Sprawdź, czy skonfigurowany identyfikator OAuth należy do klienta Singbook dla komputerów.';

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
  String get accountSuspiciousTitle => 'Brakuje elementów na Dysku Google';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elementu zsynchronizowanego wcześniej przez to urządzenie nie jest dostępnego na Dysku Google.',
      many:
          '$count elementów zsynchronizowanych wcześniej przez to urządzenie nie jest dostępnych na Dysku Google.',
      few:
          '$count elementy zsynchronizowane wcześniej przez to urządzenie nie są dostępne na Dysku Google.',
      one:
          '$count element zsynchronizowany wcześniej przez to urządzenie nie jest dostępny na Dysku Google.',
    );
    return '$_temp0 Może się tak zdarzyć po wyczyszczeniu danych aplikacji w ustawieniach Google. Niczego jeszcze nie usunięto.';
  }

  @override
  String get accountSuspiciousDelete => 'Usuń je również tutaj';

  @override
  String get accountSuspiciousKeep => 'Zachowaj utwory i prześlij je ponownie';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usunąć $count elementu z tego urządzenia?',
      many: 'Usunąć $count elementów z tego urządzenia?',
      few: 'Usunąć $count elementy z tego urządzenia?',
      one: 'Usunąć $count element z tego urządzenia?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Utwory i listy zostaną trwale usunięte z tego urządzenia. Tej operacji nie można cofnąć.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Usuń z tego urządzenia';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Brakuje elementów na Dysku Google.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Nic nie usunięto. Wybierz, czy usunąć je również tutaj, czy przesłać ponownie.';

  @override
  String get syncErrorRemoteChanged =>
      'Dysk Google zmienił się podczas synchronizacji.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Nic nie utracono. Zsynchronizuj ponownie, aby pobrać najnowsze zmiany.';

  @override
  String get syncErrorInvalidLocalData =>
      'Nie udało się zsynchronizować części danych z tego urządzenia.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Nie udało się odczytać utworu lub listy. Zaimportuj je albo utwórz ponownie, a następnie zsynchronizuj.';

  @override
  String get syncErrorNoAccountChange => 'Nie ma zmiany konta do rozwiązania.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Zsynchronizuj ponownie, aby kontynuować.';

  @override
  String get accountSyncWarningTitle =>
      'Zsynchronizowano, ale pominięto część plików';

  @override
  String get accountSyncWarningBody =>
      'Niektórych plików nie udało się użyć, więc pozostawiono je bez zmian. Pozostałe dane są aktualne.';

  @override
  String get accountSyncWarningTooLarge =>
      'Plik był zbyt duży do synchronizacji i został pominięty. Pozostałe dane są aktualne.';

  @override
  String get accountSyncWarningInvalid =>
      'Nie udało się odczytać pliku, więc został pominięty. Pozostałe dane są aktualne.';

  @override
  String get accountNoticeSyncSkipped =>
      'Zsynchronizowano. Pominięto część plików.';

  @override
  String get settingsExportPdfTooLarge =>
      'Ten plik PDF byłby zbyt duży. Wybierz mniej utworów lub udostępnij je jako tekst.';

  @override
  String get settingsTimingTooLarge =>
      'Dane o znacznikach czasu są zbyt duże (ponad 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Ta kopia zapasowa zawiera ten sam utwór dwa razy, więc niczego nie zaimportowano.';

  @override
  String get setlistSaveConflict =>
      'Lista utworów zmieniła się w innym miejscu. Twoje zmiany zapisano jako osobną kopię.';

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

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gotowej wersji',
      many: '$count gotowych wersji',
      few: '$count gotowe wersje',
      one: '$count gotowa wersja',
      zero: 'Brak gotowych wersji',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count niedostępnej wersji',
      many: '$count niedostępnych wersji',
      few: '$count niedostępne wersje',
      one: '$count niedostępna wersja',
      zero: 'Brak niedostępnych wersji',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Przejdź do sekcji';

  @override
  String get searchVersionDetails => 'Szczegóły wersji';

  @override
  String get searchSelectedRecording => 'Wybrane nagranie';

  @override
  String get searchVersionDuration => 'Czas trwania wersji';

  @override
  String get searchSourceOptions => 'Opcje źródła';

  @override
  String get actionUndo => 'Cofnij';

  @override
  String setlistEntryRemoved(String song) {
    return 'Utwór „$song” usunięto z setlisty';
  }

  @override
  String get backupTitle => 'Kopia zapasowa i przywracanie';

  @override
  String get backupExport => 'Eksportuj kopię zapasową';

  @override
  String get backupRestore => 'Przywróć kopię zapasową';

  @override
  String get backupIncludePreferences => 'Uwzględnij ustawienia aplikacji';

  @override
  String get backupRestorePreferences => 'Przywróć ustawienia aplikacji';

  @override
  String get backupMerge => 'Dodaj do tej biblioteki';

  @override
  String get backupMergeHint =>
      'Zachowaj lokalne zmiany i dodaj utwory oraz setlisty z tej kopii.';

  @override
  String get backupReplace => 'Zastąp tę bibliotekę';

  @override
  String get backupReplaceHint =>
      'Zastąp wszystkie utwory i setlisty na tym urządzeniu zawartością tej kopii.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Utwory: $songs · Setlisty: $setlists · Konflikty: $conflicts';
  }

  @override
  String get backupFailed =>
      'Nie udało się ukończyć tej operacji. Spróbuj ponownie.';

  @override
  String get backupRestored => 'Przywrócono kopię zapasową.';

  @override
  String get backupLocalHint =>
      'Zapisz kopię swojej biblioteki. Dane logowania i pliki cookie zgody nigdy nie są dołączane.';

  @override
  String get backupReplaceConfirm =>
      'Zastąpić bieżącą bibliotekę? Tej operacji nie można cofnąć.';

  @override
  String get searchCheckOperations => 'Operacje';

  @override
  String get searchCheckCode => 'Kod wyniku';

  @override
  String get searchCheckQueued => 'Oczekiwanie na sprawdzenie tego źródła.';

  @override
  String get searchCheckFetch => 'Wczytaj tekst piosenki';

  @override
  String get searchCheckValidate => 'Sprawdź zgodność utworu';

  @override
  String get searchCheckCorroborate => 'Sprawdź zgodność tekstu';

  @override
  String get searchCheckCompleted => 'Ukończono';

  @override
  String get searchCheckTimeout => 'Źródło nie odpowiedziało na czas.';

  @override
  String get searchCheckBlocked => 'Źródło zablokowało żądanie.';

  @override
  String get searchCheckRateLimited =>
      'Źródło ogranicza liczbę żądań. Spróbuj ponownie później.';

  @override
  String get searchCheckNetwork =>
      'Nie można połączyć się ze źródłem. Sprawdź połączenie.';

  @override
  String get searchCheckInvalid => 'Źródło zwróciło nieczytelną odpowiedź.';

  @override
  String get searchCheckNotConfigured =>
      'To źródło nie jest skonfigurowane w tej kompilacji.';

  @override
  String get searchCheckNoLyrics =>
      'Nie znaleziono pasującego tekstu piosenki.';

  @override
  String get searchCheckFailed => 'Nie udało się ukończyć tej operacji.';

  @override
  String get searchCheckNoHistory =>
      'Dla tego porównania nie uruchomiono żadnych kontroli źródeł.';

  @override
  String get searchVersionCredits => 'Autorzy i źródła';

  @override
  String get searchVersionMediaLinks => 'Powiązane linki';

  @override
  String get searchCheckCancelled => 'Anulowano';

  @override
  String get searchCheckAmbiguous =>
      'Znaleziono kilka pasujących wyników. To źródło wymaga dokładniejszego nagrania.';

  @override
  String get searchCheckIdentity =>
      'To źródło wymaga identyfikatora nagrania lub utworu.';

  @override
  String get searchCheckExtraction =>
      'Źródło odpowiedziało, ale nie udało się wyodrębnić tekstu piosenki.';

  @override
  String get searchCheckBusy =>
      'To źródło jest zajęte. Spróbuj ponownie później.';

  @override
  String get searchCheckSelection => 'Wybierz konkretny wynik z tego źródła.';

  @override
  String get playerChordsNone => 'Brak';

  @override
  String get editorCustomValue => 'Inne…';

  @override
  String get editorStandardTuning => 'Strój standardowy';

  @override
  String get editorExampleVerse =>
      '[C]Nowy dzień nas [G]woła,\n[Am]wracamy za światłem do [F]domu.';

  @override
  String get editorExampleChorus =>
      '[F]Zaśpiewajmy tę piosenkę [C]razem,\n[G]niech melodia poniesie nas [C]dalej.';

  @override
  String get editorExampleBridge => '[Am]Jeszcze jeden wers, trochę [F]bliżej.';

  @override
  String get playerEstimatedKey => 'Szacowana tonacja';

  @override
  String get songsLibraryView => 'Biblioteka';

  @override
  String get settingsStartupView => 'Widok początkowy';

  @override
  String get settingsStartupViewHint =>
      'Wybierz widok utworów wyświetlany po otwarciu aplikacji.';

  @override
  String get settingsStartupLastView => 'Ostatnio otwarty';

  @override
  String get playerFullScreen => 'Pełny ekran';

  @override
  String get playerExitFullScreen => 'Opuść pełny ekran';

  @override
  String get playerExpandControls => 'Pokaż elementy sterujące odtwarzaniem';

  @override
  String get playerCollapseControls => 'Ukryj elementy sterujące odtwarzaniem';

  @override
  String get settingsShowSections => 'Pokazuj nagłówki sekcji';

  @override
  String get settingsShowSectionsHint =>
      'Pokazuj w tekście nagłówki zwrotek, refrenu i innych sekcji.';

  @override
  String get settingsShowPlayerControls =>
      'Pokaż elementy sterujące odtwarzaniem';

  @override
  String get settingsShowPlayerControlsHint =>
      'Możesz też stuknąć panel odtwarzacza lub przesunąć po nim palcem, aby go pokazać lub ukryć.';

  @override
  String get sourceAnalysisHeading =>
      'Analiza przesłanego dźwięku (niezweryfikowana)';

  @override
  String sourceAnalysisCoverage(int shown, int total) {
    return 'Wyświetlono $shown z $total zgłoszeń';
  }

  @override
  String sourceAnalysisSample(int number) {
    return 'Próbka $number';
  }

  @override
  String get sourceAnalysisEstimatedTempo => 'Szacowane tempo (BPM)';
}
