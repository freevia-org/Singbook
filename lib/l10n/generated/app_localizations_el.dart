// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Ένας ήρεμος χώρος για να βρίσκεις, να οργανώνεις και να τραγουδάς από τη συλλογή τραγουδιών σου.';

  @override
  String get aboutMadeForSinging => 'Φτιαγμένο για να τραγουδάμε μαζί';

  @override
  String get aboutDetails =>
      'Αναζητήστε σε ενεργοποιημένες πηγές, συγκρίνετε εκδόσεις, κρατήστε μαζί στίχους και συγχορδίες και οργανώστε τραγούδια σε λίστες. Η βιβλιοθήκη σας αποθηκεύεται σε αυτήν τη συσκευή· ο προαιρετικός συγχρονισμός μέσω Google Drive χρησιμοποιεί τον λογαριασμό σας Google. Οι αναζητήσεις αποστέλλονται απευθείας στις ενεργοποιημένες πηγές.';

  @override
  String get aboutSupport => 'Υποστήριξη και σχόλια';

  @override
  String get menuTypeNewSong => 'Πληκτρολογήστε ένα νέο τραγούδι';

  @override
  String appVersion(String version) {
    return 'Έκδοση $version';
  }

  @override
  String get navHome => 'Αρχική';

  @override
  String get navSongs => 'Τραγούδια';

  @override
  String get navSetlists => 'Λίστες';

  @override
  String get navSettings => 'Ρυθμίσεις';

  @override
  String get navSettingsCompact => 'Ρυθμίσεις';

  @override
  String get navSearch => 'Αναζήτηση';

  @override
  String get navBack => 'Πίσω';

  @override
  String get appExitBackAgain => 'Πατήστε ξανά Πίσω για έξοδο';

  @override
  String get navClose => 'Κλείσιμο';

  @override
  String get navMore => 'Περισσότερες ενέργειες';

  @override
  String get actionCancel => 'Ακύρωση';

  @override
  String get actionSave => 'Αποθήκευση';

  @override
  String get actionDone => 'Τέλος';

  @override
  String get actionEdit => 'Επεξεργασία';

  @override
  String get actionDelete => 'Διαγραφή';

  @override
  String get actionShare => 'Κοινοποίηση';

  @override
  String get actionPrint => 'Εκτύπωση';

  @override
  String get actionCopy => 'Αντιγραφή';

  @override
  String get actionClear => 'Εκκαθάριση';

  @override
  String get actionRetry => 'Δοκιμή ξανά';

  @override
  String get actionRefresh => 'Ανανέωση';

  @override
  String get actionImport => 'Εισαγωγή';

  @override
  String get actionExport => 'Εξαγωγή';

  @override
  String get actionExpand => 'Ανάπτυξη';

  @override
  String get actionCollapse => 'Σύμπτυξη';

  @override
  String get actionAdd => 'Προσθήκη';

  @override
  String get actionCreate => 'Δημιουργία';

  @override
  String get actionRemove => 'Αφαίρεση';

  @override
  String get actionDuplicate => 'Δημιουργία αντιγράφου';

  @override
  String get actionMoveUp => 'Μετακίνηση προς τα πάνω';

  @override
  String get actionMoveDown => 'Μετακίνηση προς τα κάτω';

  @override
  String get actionPrevious => 'Προηγούμενο';

  @override
  String get actionNext => 'Επόμενο';

  @override
  String get searchHint => 'Αναζήτησε τραγούδια, καλλιτέχνες ή στίχους';

  @override
  String get searchCatalogHint => 'Αναζήτησε τραγούδι ή καλλιτέχνη';

  @override
  String get searchChangeSong => 'Αλλαγή τραγουδιού';

  @override
  String get searchSelectedPreview => 'Επιλεγμένη προεπισκόπηση';

  @override
  String get searchSubmit => 'Αναζήτηση';

  @override
  String get searchFilters => 'Επιλογές αναζήτησης';

  @override
  String get searchFiltersShow => 'Εμφάνιση επιλογών αναζήτησης';

  @override
  String get searchFiltersHide => 'Απόκρυψη επιλογών αναζήτησης';

  @override
  String get searchFilterArtist => 'Καλλιτέχνης';

  @override
  String get searchFilterTitle => 'Τίτλος τραγουδιού';

  @override
  String get searchFilterLyrics => 'Στίχοι';

  @override
  String get searchFilterChords => 'Με συγχορδίες';

  @override
  String get searchFilterTimed => 'Συγχρονισμένοι στίχοι';

  @override
  String get searchFilterLanguage => 'Γλώσσα';

  @override
  String get searchFilterAll => 'Οποιοδήποτε';

  @override
  String get searchAutocompleteLabel => 'Προτάσεις';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αποτελέσματα',
      one: '1 αποτέλεσμα',
      zero: 'Δεν υπάρχουν αποτελέσματα',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Πληκτρολόγησε τραγούδι, καλλιτέχνη ή στίχο για αναζήτηση.';

  @override
  String get searchCatalogEmptyQuery =>
      'Πληκτρολόγησε τραγούδι ή καλλιτέχνη για αναζήτηση.';

  @override
  String get searchNoResults =>
      'Δεν βρέθηκαν τραγούδια. Δοκίμασε διαφορετική αναζήτηση.';

  @override
  String get searchLoading => 'Αναζήτηση τραγουδιών…';

  @override
  String get searchError => 'Δεν ήταν δυνατή η ολοκλήρωση της αναζήτησης.';

  @override
  String get searchOnlineTab => 'Διαδικτυακά';

  @override
  String get searchRecentTab => 'Πρόσφατα';

  @override
  String get searchFavoritesTab => 'Αγαπημένα';

  @override
  String get searchSuggested => 'Προτεινόμενη αντιστοιχία';

  @override
  String get searchAlternatives => 'Άλλες αντιστοιχίες';

  @override
  String get searchCompare => 'Σύγκριση εκδόσεων';

  @override
  String get searchChooseVersion => 'Επιλογή αυτής της έκδοσης';

  @override
  String get searchFullPreview => 'Πλήρης προεπισκόπηση';

  @override
  String get searchArrangementNotes => 'Σημειώσεις ενορχήστρωσης';

  @override
  String get searchOpenLyrics => 'Άνοιγμα στίχων';

  @override
  String get searchContributions => 'Πηγές που χρησιμοποιήθηκαν';

  @override
  String get searchVersionChecking => 'Έλεγχος αυτής της έκδοσης…';

  @override
  String get searchVersionUnavailable =>
      'Δεν είναι δυνατή η χρήση αυτής της έκδοσης. Επιλέξτε άλλη έκδοση.';

  @override
  String get searchPreviewUnavailable =>
      'Δεν υπάρχει διαθέσιμη προεπισκόπηση στίχων.';

  @override
  String get searchSongMatch => 'Αντιστοιχία τραγουδιού';

  @override
  String get searchRecordingMatch => 'Αντιστοιχία ηχογράφησης';

  @override
  String get searchMatchUnverified => 'Η ηχογράφηση δεν έχει επαληθευτεί';

  @override
  String get searchMatchExact => 'Ακριβής αντιστοιχία ηχογράφησης';

  @override
  String get searchMatchPossible => 'Πιθανή αντιστοιχία';

  @override
  String get searchAvailability => 'Διαθεσιμότητα';

  @override
  String get searchLyricsAvailable => 'Οι στίχοι είναι διαθέσιμοι';

  @override
  String get searchLyricsUnavailable => 'Οι στίχοι δεν είναι διαθέσιμοι';

  @override
  String get searchChordsAvailable => 'Οι συγχορδίες είναι διαθέσιμες';

  @override
  String get searchChordsUnavailable => 'Χωρίς συγχορδίες';

  @override
  String get searchTimingAvailable => 'Ο χρονισμός είναι διαθέσιμος';

  @override
  String get searchTimingUnavailable => 'Χωρίς χρονισμό';

  @override
  String get searchDurationUnknown => 'Άγνωστη διάρκεια';

  @override
  String searchRating(String rating) {
    return 'Βαθμολογία $rating';
  }

  @override
  String get searchSourceLabel => 'Πηγή';

  @override
  String get searchMetadata => 'Στοιχεία τραγουδιού';

  @override
  String get searchAlbum => 'Άλμπουμ';

  @override
  String get searchArtist => 'Καλλιτέχνης';

  @override
  String get searchYear => 'Έτος';

  @override
  String get searchLanguage => 'Γλώσσα';

  @override
  String get searchViewVersions => 'Προβολή εκδόσεων';

  @override
  String get searchSaved => 'Το τραγούδι αποθηκεύτηκε στη συλλογή σου.';

  @override
  String get searchSaveOpenLyrics => 'Αποθήκευση και άνοιγμα στίχων';

  @override
  String get searchOtherResults => 'Άλλα αποτελέσματα';

  @override
  String get searchSaveFailed =>
      'Δεν ήταν δυνατή η αποθήκευση αυτού του τραγουδιού.';

  @override
  String get homeRecentSongs => 'Πρόσφατα τραγούδια';

  @override
  String get homeRecentlyPlayed => 'Πρόσφατες αναπαραγωγές';

  @override
  String get homeFavorites => 'Αγαπημένα';

  @override
  String get homeHistory => 'Ιστορικό';

  @override
  String get homeHistoryClear => 'Εκκαθάριση ιστορικού';

  @override
  String get homeHistoryCleared => 'Το ιστορικό διαγράφηκε.';

  @override
  String get homeHistoryEmpty =>
      'Τα τραγούδια που ανοίγεις θα εμφανίζονται εδώ.';

  @override
  String get homeFavoritesEmpty =>
      'Τα αγαπημένα τραγούδια και οι λίστες σου θα εμφανίζονται εδώ.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Εμφανίζονται $count στοιχεία',
      one: 'Εμφανίζεται 1 στοιχείο',
      zero: 'Εμφανίζονται 0 στοιχεία',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Τα πρόσφατα τραγούδια και οι λίστες σου θα εμφανίζονται εδώ.';

  @override
  String get homeTimelineLabel => 'Χρονολόγιο ιστορικού';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Πλήρες ιστορικό';

  @override
  String get homeShowFavorites => 'Εμφάνιση αγαπημένων';

  @override
  String get homeShowRecent => 'Εμφάνιση πρόσφατων';

  @override
  String get songsTitle => 'Τραγούδια';

  @override
  String get songsEmpty => 'Τα τραγούδια σου θα εμφανίζονται εδώ.';

  @override
  String get songsEmptySearch =>
      'Κανένα τραγούδι δεν ταιριάζει με την αναζήτησή σου.';

  @override
  String get songsAdd => 'Προσθήκη τραγουδιού';

  @override
  String get songsSortAlphabetical => 'Ταξινόμηση αλφαβητικά';

  @override
  String get songsAlphabetNavigation => 'Ευρετήριο τραγουδιών';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ανοίχτηκε $count φορές',
      one: 'Ανοίχτηκε μία φορά',
      zero: 'Δεν έχει ανοιχτεί ποτέ',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'Προσθήκη στα αγαπημένα';

  @override
  String get songFavoriteRemove => 'Αφαίρεση από τα αγαπημένα';

  @override
  String get songMenuLabel => 'Ενέργειες τραγουδιού';

  @override
  String get songInfo => 'Στοιχεία τραγουδιού';

  @override
  String get setlistMenuLabel => 'Ενέργειες λίστας τραγουδιών';

  @override
  String get songAddToSetlist => 'Προσθήκη στη λίστα τραγουδιών';

  @override
  String get songCopyChordPro => 'Αντιγραφή ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Διαγραφή τραγουδιού;';

  @override
  String get songDeleteConfirmMessage =>
      'Αυτό το τραγούδι θα αφαιρεθεί από τη συλλογή σου.';

  @override
  String get songDeleted => 'Το τραγούδι διαγράφηκε.';

  @override
  String get setlistsTitle => 'Λίστες τραγουδιών';

  @override
  String get setlistsEmpty =>
      'Δημιούργησε μια λίστα για την επόμενη πρόβα ή εμφάνισή σου.';

  @override
  String get setlistsEmptySearch =>
      'Καμία λίστα δεν ταιριάζει με την αναζήτησή σου.';

  @override
  String get setlistCreate => 'Νέα λίστα τραγουδιών';

  @override
  String get setlistNameHint => 'Όνομα λίστας';

  @override
  String get setlistNotes => 'Σημειώσεις';

  @override
  String get setlistEntryOverride =>
      'Τονικότητα και capo για το συγκεκριμένο τραγούδι';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count τραγούδια',
      one: '1 τραγούδι',
      zero: 'Κανένα τραγούδι',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Τουλάχιστον $duration';
  }

  @override
  String get setlistDurationUnknown => 'Άγνωστη διάρκεια';

  @override
  String setlistActivity(String date) {
    return 'Τελευταία δραστηριότητα $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Δημιουργήθηκε $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Τροποποιήθηκε $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Αναπαράχθηκε τελευταία φορά $date';
  }

  @override
  String get setlistSongsEmpty => 'Αυτή η λίστα δεν έχει ακόμη τραγούδια.';

  @override
  String get setlistAddSongs => 'Προσθήκη τραγουδιών';

  @override
  String get setlistReorder => 'Αλλαγή σειράς τραγουδιών';

  @override
  String setlistMoveSongUp(String song) {
    return 'Μετακίνηση του $song προς τα πάνω';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Μετακίνηση του $song προς τα κάτω';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Αφαίρεση του $song από τη λίστα';
  }

  @override
  String get setlistDuplicate => 'Δημιουργία αντιγράφου λίστας';

  @override
  String get setlistFavoriteAdd => 'Προσθήκη λίστας στα αγαπημένα';

  @override
  String get setlistFavoriteRemove => 'Αφαίρεση λίστας από τα αγαπημένα';

  @override
  String get setlistShare => 'Κοινοποίηση ως αρχείο λίστας τραγουδιών';

  @override
  String get setlistSharePdf => 'Κοινοποίηση ως PDF';

  @override
  String get setlistPrint => 'Εκτύπωση';

  @override
  String get setlistDeleteConfirmTitle => 'Διαγραφή λίστας;';

  @override
  String get setlistDeleteConfirmMessage =>
      'Η λίστα θα αφαιρεθεί. Τα τραγούδια στη συλλογή σου θα παραμείνουν.';

  @override
  String get setlistDeleted => 'Η λίστα διαγράφηκε.';

  @override
  String get readerTitle => 'Στίχοι';

  @override
  String get readerNoLyrics => 'Δεν έχουν προστεθεί ακόμη στίχοι.';

  @override
  String get readerShowChords => 'Εμφάνιση συγχορδιών';

  @override
  String get readerHideChords => 'Απόκρυψη συγχορδιών';

  @override
  String get readerTranspose => 'Μεταφορά συγχορδιών';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ημιτόνια',
      one: '1 ημιτόνιο',
      zero: '0 ημιτόνια',
    );
    return 'Μεταφορά κατά $_temp0';
  }

  @override
  String get readerSaved => 'Αποθηκεύτηκε';

  @override
  String get readerEdit => 'Επεξεργασία στίχων και στοιχείων';

  @override
  String get playerPlay => 'Αναπαραγωγή';

  @override
  String get playerPause => 'Παύση';

  @override
  String get playerResume => 'Συνέχιση κύλισης στίχων';

  @override
  String get playerSeek => 'Θέση αναπαραγωγής';

  @override
  String playerElapsed(String time) {
    return 'Χρόνος που πέρασε $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Χρόνος που απομένει $time';
  }

  @override
  String get playerTimingMode => 'Λειτουργία κύλισης';

  @override
  String get playerTimedLyrics => 'Συγχρονισμένοι στίχοι';

  @override
  String get playerStartScroll => 'Έναρξη αυτόματης κύλισης';

  @override
  String get playerEstimatedPace => 'Εκτιμώμενος ρυθμός';

  @override
  String get playerScrollSpeed => 'Ταχύτητα κύλισης';

  @override
  String playerEstimatedDuration(String time) {
    return 'Εκτιμώμενη διάρκεια: $time';
  }

  @override
  String get playerLyricsOnly => 'Κύλιση στίχων · χωρίς ήχο';

  @override
  String get playerManualScroll => 'Χειροκίνητη κύλιση';

  @override
  String get playerTimingStatusReady =>
      'Οι στίχοι θα ακολουθούν τον διαθέσιμο χρονισμό.';

  @override
  String get playerTimingStatusEstimated =>
      'Ο ρυθμός κύλισης εκτιμάται από τη διάρκεια του τραγουδιού.';

  @override
  String get playerTimingStatusManual => 'Κύλησε τους στίχους χειροκίνητα.';

  @override
  String get playerTimingStatusUnavailable =>
      'Η συγχρονισμένη κύλιση δεν είναι διαθέσιμη για αυτό το τραγούδι.';

  @override
  String get playerDurationUnknown =>
      'Πρόσθεσε διάρκεια τραγουδιού για να χρησιμοποιήσεις την εκτιμώμενη κύλιση.';

  @override
  String get playerProgressLabel => 'Πρόοδος τραγουδιού';

  @override
  String get playerCurrentSection => 'Τρέχον μέρος';

  @override
  String get playerPreviousSection => 'Προηγούμενο μέρος';

  @override
  String get playerNextSection => 'Επόμενο μέρος';

  @override
  String get playerPreviousSectionSong =>
      'Προηγούμενο μέρος · κράτησε πατημένο για το προηγούμενο τραγούδι της λίστας';

  @override
  String get playerNextSectionSong =>
      'Επόμενο μέρος · κράτησε πατημένο για το επόμενο τραγούδι της λίστας';

  @override
  String get playerPreviousSong => 'Προηγούμενο τραγούδι';

  @override
  String get playerNextSong => 'Επόμενο τραγούδι';

  @override
  String get editorTitle => 'Επεξεργασία τραγουδιού';

  @override
  String get editorTitleField => 'Τίτλος τραγουδιού';

  @override
  String get editorArtistField => 'Καλλιτέχνης';

  @override
  String get editorAlbumField => 'Άλμπουμ';

  @override
  String get editorLyricsField => 'Στίχοι';

  @override
  String get editorChordsField => 'Συγχορδίες';

  @override
  String get editorKeyField => 'Τονικότητα';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Κούρδισμα';

  @override
  String get editorTempoField => 'Τέμπο';

  @override
  String get editorDurationField => 'Διάρκεια';

  @override
  String get editorTimeSignatureField => 'Μέτρο';

  @override
  String get editorLanguageField => 'Γλώσσα';

  @override
  String get editorYearField => 'Έτος';

  @override
  String get editorComposerField => 'Συνθέτης';

  @override
  String get editorLyricistField => 'Στιχουργός';

  @override
  String get editorCopyrightField => 'Πνευματικά δικαιώματα';

  @override
  String get editorLicenseField => 'Άδεια';

  @override
  String get songInfoSources => 'Πηγές και συντελεστές';

  @override
  String get searchMatchSameSong =>
      'Ίδιο τραγούδι· η ηχογράφηση δεν επιβεβαιώθηκε';

  @override
  String get searchMatchNeedsAgreement =>
      'Το φύλλο συγχορδιών χρειάζεται επιβεβαίωση στίχων';

  @override
  String get searchMatchDifferentLyrics =>
      'Οι στίχοι διαφέρουν από το επιλεγμένο τραγούδι';

  @override
  String get searchMatchCombinedSources =>
      'Στοιχεία από πολλές πηγές συνδυάστηκαν';

  @override
  String get searchCombinedLabel => 'Συνδυασμένα';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αντιστοιχίες τραγουδιών',
      one: '1 αντιστοιχία τραγουδιού',
      zero: '0 αντιστοιχίες τραγουδιών',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count εκδόσεις πηγής',
      one: '1 έκδοση πηγής',
      zero: '0 εκδόσεις πηγής',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Καλύτερη διαθέσιμη αντιστοιχία';

  @override
  String get providerDescriptionUnknown => 'Πηγή τραγουδιού';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Κατέβασε ένα αρχείο ChordPro από την πηγή και έπειτα εισήγαγέ το.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Κατέβασε το αρχείο με δωρεάν λογαριασμό και έπειτα εισήγαγέ το.';

  @override
  String get providerDescPublicChordSheets => 'Δημόσια φύλλα συγχορδιών.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Ιστορικοί στίχοι με άδεια ανά έργο.';

  @override
  String get providerDescLicensedCatalog => 'Κατάλογος αδειοδοτημένων στίχων.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Πρωτότυπα τραγούδια με άδεια Creative Commons BY.';

  @override
  String get providerDescPerSongLicense => 'Στίχοι με άδεια ανά τραγούδι.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Μόνο στοιχεία ηχογράφησης και κυκλοφορίας.';

  @override
  String get providerDescCompositionMetadataOnly => 'Μόνο στοιχεία σύνθεσης.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Εξώφυλλα μόνο για ακριβείς αντιστοιχίες ηχογραφήσεων.';

  @override
  String get providerCapabilityLyrics => 'Στίχοι';

  @override
  String get providerCapabilityChords => 'Συγχορδίες';

  @override
  String get providerCapabilityTiming => 'Συγχρονισμένοι στίχοι';

  @override
  String get providerCapabilitySearch => 'Αναζήτηση';

  @override
  String get providerCapabilityMetadata => 'Στοιχεία τραγουδιού';

  @override
  String get editorArtworkField => 'Σύνδεσμος εξωφύλλου';

  @override
  String get editorLyricsHint =>
      'Οι συγχορδίες μπαίνουν σε αγκύλες [C]· οι δείκτες ενοτήτων σε ξεχωριστές γραμμές.';

  @override
  String get editorSave => 'Αποθήκευση αλλαγών';

  @override
  String get editorSaved => 'Οι αλλαγές αποθηκεύτηκαν.';

  @override
  String get editorSaveFailed => 'Δεν ήταν δυνατή η αποθήκευση των αλλαγών.';

  @override
  String get editorSaveConflict =>
      'Το τραγούδι άλλαξε αλλού. Οι αλλαγές σου αποθηκεύτηκαν ως ξεχωριστό αντίγραφο.';

  @override
  String get editorUnsavedTitle => 'Απόρριψη αλλαγών;';

  @override
  String get editorUnsavedMessage => 'Οι αλλαγές σου δεν έχουν αποθηκευτεί.';

  @override
  String get editorFieldRequired => 'Πληκτρολόγησε τίτλο τραγουδιού.';

  @override
  String get settingsTitle => 'Ρυθμίσεις';

  @override
  String get settingsAppearance => 'Εμφάνιση';

  @override
  String get settingsTheme => 'Θέμα';

  @override
  String get settingsThemeSystem => 'Χρήση ρύθμισης συσκευής';

  @override
  String get settingsThemeLight => 'Φωτεινό';

  @override
  String get settingsThemeDark => 'Σκούρο';

  @override
  String get settingsColorPalette => 'Παλέτα χρωμάτων';

  @override
  String get settingsFont => 'Γραμματοσειρά';

  @override
  String get settingsTextSize => 'Μέγεθος κειμένου';

  @override
  String get settingsLyricsPreview => 'Προεπισκόπηση στίχων';

  @override
  String get settingsPlayer => 'Αναπαραγωγή στίχων';

  @override
  String get settingsLyricHighlight => 'Current lyric highlight';

  @override
  String get settingsHighlightBackgroundUnderline => 'Background + underline';

  @override
  String get settingsHighlightBackground => 'Background';

  @override
  String get settingsHighlightUnderline => 'Underline';

  @override
  String get settingsHighlightContrast => 'Contrasting text color';

  @override
  String get settingsHighlightNone => 'None';

  @override
  String get settingsDefaultShowChords => 'Εμφάνιση συγχορδιών από προεπιλογή';

  @override
  String get settingsDefaultAutoscroll => 'Αυτόματη κύλιση στίχων';

  @override
  String get settingsDefaultTiming => 'Προεπιλεγμένη λειτουργία κύλισης';

  @override
  String get settingsLanguage => 'Γλώσσα εφαρμογής';

  @override
  String get settingsLanguageSystem => 'Χρήση γλώσσας συσκευής';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Πηγές στίχων';

  @override
  String settingsSourceEnabled(String source) {
    return 'Ενεργοποίηση πηγής $source';
  }

  @override
  String get settingsSourceRefresh => 'Ανανέωση λίστας πηγών';

  @override
  String get settingsSourcesUpdated => 'Οι πηγές ενημερώθηκαν.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Δεν ήταν δυνατή η ανανέωση των πηγών.';

  @override
  String get settingsImport => 'Εισαγωγή τραγουδιών';

  @override
  String get settingsImportChordPro => 'Εισαγωγή αρχείου ChordPro';

  @override
  String get settingsImportSetlist => 'Εισαγωγή αρχείου λίστας τραγουδιών';

  @override
  String get settingsImportSuccess => 'Η εισαγωγή ολοκληρώθηκε.';

  @override
  String get settingsImportFailed =>
      'Δεν ήταν δυνατή η εισαγωγή αυτού του αρχείου.';

  @override
  String get settingsImportUnsupported =>
      'Αυτός ο τύπος αρχείου δεν υποστηρίζεται.';

  @override
  String get settingsShareSong => 'Κοινοποίηση ως ChordPro';

  @override
  String get settingsSharePdf => 'Κοινοποίηση ως PDF';

  @override
  String get settingsCopySong => 'Αντιγραφή στο πρόχειρο';

  @override
  String get settingsPrintSong => 'Εκτύπωση μόνο τραγουδιού';

  @override
  String get settingsPrintSetlist => 'Εκτύπωση λίστας με στίχους';

  @override
  String get settingsExportFailed =>
      'Δεν ήταν δυνατή η προετοιμασία του αρχείου.';

  @override
  String get settingsCopied => 'Αντιγράφηκε στο πρόχειρο.';

  @override
  String get settingsAbout => 'Σχετικά';

  @override
  String get settingsPrivacy => 'Απόρρητο';

  @override
  String get settingsLegal => 'Νομικά';

  @override
  String get settingsClearHistory => 'Εκκαθάριση ιστορικού';

  @override
  String get settingsClearHistoryConfirm =>
      'Να διαγραφεί το ιστορικό τραγουδιών και λιστών;';

  @override
  String get settingsHistoryCleared => 'Το ιστορικό διαγράφηκε.';

  @override
  String get accountTitle => 'Λογαριασμός και συγχρονισμός';

  @override
  String get accountUnavailable =>
      'Ο συγχρονισμός απαιτεί έκδοση του Singbook με ρυθμισμένη σύνδεση Google. Αυτή η έκδοση διατηρεί τα τραγούδια σου μόνο σε αυτήν τη συσκευή.';

  @override
  String get accountSyncNow => 'Συγχρονισμός τώρα';

  @override
  String get accountConnected =>
      'Συνδέθηκες. Επίλεξε «Συγχρονισμός τώρα» για να ενημερώσεις το αντίγραφο ασφαλείας.';

  @override
  String get accountSignIn => 'Σύνδεση λογαριασμού';

  @override
  String get accountSignOut => 'Αποσύνδεση';

  @override
  String get accountChange => 'Αλλαγή λογαριασμού';

  @override
  String get accountSignedOut => 'Δεν έχει συνδεθεί';

  @override
  String get accountSyncing => 'Γίνεται συγχρονισμός της συλλογής…';

  @override
  String get accountSynced => 'Η συλλογή συγχρονίστηκε.';

  @override
  String get accountSyncFailed =>
      'Δεν ήταν δυνατός ο συγχρονισμός της συλλογής.';

  @override
  String get accessibilityFavorite => 'Αγαπημένο';

  @override
  String get accessibilityNotFavorite => 'Δεν είναι αγαπημένο';

  @override
  String get accessibilitySearchField => 'Αναζήτηση τραγουδιών';

  @override
  String get accessibilityClearSearch => 'Εκκαθάριση κειμένου αναζήτησης';

  @override
  String accessibilitySongMenu(String song) {
    return 'Ενέργειες για το $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Ενέργειες για τη λίστα $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Ανάπτυξη τραγουδιών στη λίστα $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Σύμπτυξη τραγουδιών στη λίστα $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Πρόοδος αναπαραγωγής, $percent τοις εκατό';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Χρονολόγιο ιστορικού, $date';
  }

  @override
  String get loading => 'Φόρτωση…';

  @override
  String get loadingSongs => 'Φόρτωση τραγουδιών…';

  @override
  String get loadingSetlists => 'Φόρτωση λιστών…';

  @override
  String get errorGeneric => 'Κάτι πήγε στραβά.';

  @override
  String get errorOffline => 'Φαίνεται ότι είσαι εκτός σύνδεσης.';

  @override
  String get errorPermission => 'Απαιτείται άδεια για να συνεχίσεις.';

  @override
  String get emptyFiltered =>
      'Κανένα στοιχείο δεν ταιριάζει με αυτά τα φίλτρα.';

  @override
  String get unknownValue => 'Άγνωστο';

  @override
  String get durationUnknown => 'Άγνωστη διάρκεια';

  @override
  String get metadataNotSet => 'Δεν έχει οριστεί';

  @override
  String get dateToday => 'Σήμερα';

  @override
  String get dateYesterday => 'Χθες';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count τραγούδια',
      one: '1 τραγούδι',
      zero: 'Κανένα τραγούδι',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Μπλε σκούρο';

  @override
  String get settingsPaletteSage => 'Πράσινο φασκόμηλου';

  @override
  String get settingsPaletteOcean => 'Ωκεανός';

  @override
  String get settingsPaletteClay => 'Πηλός';

  @override
  String get settingsPalettePlum => 'Δαμασκηνί';

  @override
  String get settingsFontSystem => 'Σύστημα';

  @override
  String get settingsFontSerif => 'Με πατούρες';

  @override
  String get settingsFontMonospace => 'Σταθερού πλάτους';

  @override
  String get settingsLyricsPreviewExample =>
      'Όταν έρθει το πρωί, θα τραγουδήσουμε ξανά.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Έλεγχος πηγών στίχων: ολοκληρώθηκαν $checked από $total.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Δεν βρέθηκαν αξιοποιήσιμοι στίχοι.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Το επιλεγμένο τραγούδι ελέγχθηκε στις ενεργοποιημένες πηγές, αλλά καμία δεν επέστρεψε αξιοποιήσιμη έκδοση στίχων.';

  @override
  String get searchDiscoveryError =>
      'Δεν ήταν δυνατός ο έλεγχος των πηγών στίχων.';

  @override
  String get searchDiscoveryRetry => 'Επανάληψη αναζήτησης στίχων';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count πηγές μη διαθέσιμες',
      one: '1 πηγή μη διαθέσιμη',
      zero: '0 πηγές μη διαθέσιμες',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Έλεγξε τη σύνδεσή σου και δοκίμασε ξανά.';

  @override
  String get searchProviderChecks => 'Έλεγχοι πηγών';

  @override
  String get searchProviderPending => 'Γίνεται έλεγχος';

  @override
  String get searchProviderFound => 'Βρέθηκε αντιστοιχία';

  @override
  String get searchProviderRejected => 'Δεν ταιριάζει';

  @override
  String get searchProviderFailed => 'Ο έλεγχος απέτυχε';

  @override
  String get searchProviderUnavailable => 'Δεν υπάρχουν αξιοποιήσιμοι στίχοι';

  @override
  String get searchCatalogFilterHint =>
      'Επίλεξε τραγούδι για να φιλτράρεις εκδόσεις στίχων με βάση τις συγχορδίες, τον χρονισμό ή τη γλώσσα.';

  @override
  String get startupErrorTitle =>
      'Δεν ήταν δυνατό το άνοιγμα της συλλογής σου.';

  @override
  String setlistCopyName(String name) {
    return 'Αντίγραφο του $name';
  }

  @override
  String get setlistSongMissing => 'Τραγούδι που λείπει';

  @override
  String get settingsImportTooLarge =>
      'Αυτό το αρχείο είναι πολύ μεγάλο για εισαγωγή.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Μετάβαση στο $letter';
  }

  @override
  String get actionDiscard => 'Απόρριψη';

  @override
  String get editorKeepEditing => 'Συνέχιση επεξεργασίας';

  @override
  String get settingsDefaultShowChordsHint =>
      'Εμφάνιση συγχορδιών πάνω από τους στίχους όταν το τραγούδι έχει συγχορδίες.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Οι στίχοι κυλούν μαζί με το τραγούδι. Δεν χρησιμοποιείται στη χειροκίνητη κύλιση.';

  @override
  String get accountUnavailableTitle => 'Ο συγχρονισμός δεν έχει ρυθμιστεί';

  @override
  String get accountSignedOutBenefits =>
      'Με τη σύνδεση του Google Drive συγχρονίζεται η συλλογή σας. Οι αλλαγές στα τραγούδια συγχρονίζονται αυτόματα στη συνέχεια.';

  @override
  String get accountManualSyncHint =>
      'Μπορείτε επίσης να πατήσετε Συγχρονισμός τώρα για να συγχρονίσετε τη συλλογή σας.';

  @override
  String get accountSignInWithGoogle => 'Σύνδεση με Google';

  @override
  String get accountWorking => 'Γίνεται επεξεργασία…';

  @override
  String get accountNeverSynced => 'Δεν συγχρονίστηκε ποτέ';

  @override
  String get accountSyncedJustNow => 'Μόλις συγχρονίστηκε';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Συγχρονίστηκε πριν από $count λεπτά',
      one: 'Συγχρονίστηκε πριν από 1 λεπτό',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Συγχρονίστηκε πριν από $count ώρες',
      one: 'Συγχρονίστηκε πριν από 1 ώρα',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Συγχρονίστηκε πριν από $count ημέρες',
      one: 'Συγχρονίστηκε πριν από 1 ημέρα',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αντικρουόμενες αλλαγές αποθηκεύτηκαν ως αντίγραφα',
      one: '1 αντικρουόμενη αλλαγή αποθηκεύτηκε ως αντίγραφο',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Το ίδιο τραγούδι ή η ίδια λίστα τροποποιήθηκε σε δύο σημεία. Δεν χάθηκε τίποτα: η άλλη έκδοση αποθηκεύτηκε ως ξεχωριστό αντίγραφο.';

  @override
  String get accountReviewConflicts => 'Έλεγχος αντιγράφων';

  @override
  String get songsConflictFilterActive =>
      'Εμφανίζονται μόνο αντίγραφα με διένεξη';

  @override
  String get songsConflictFilterClear => 'Εμφάνιση όλων των τραγουδιών';

  @override
  String get songsConflictBadge => 'Αντίγραφο με διένεξη';

  @override
  String get songsConflictEmpty => 'Δεν υπάρχουν αντίγραφα με διένεξη.';

  @override
  String get accountAutoSync => 'Αυτόματος συγχρονισμός';

  @override
  String get accountAutoSyncHint =>
      'Ο συγχρονισμός γίνεται μετά τη σύνδεση και μετά την προσθήκη, επεξεργασία ή αφαίρεση ενός τραγουδιού.';

  @override
  String get accountSignOutTitle => 'Αποσύνδεση από αυτόν τον λογαριασμό;';

  @override
  String get accountSignOutBody =>
      'Τα τραγούδια και οι λίστες σου παραμένουν σε αυτήν τη συσκευή. Δεν θα δημιουργούνται αντίγραφα ασφαλείας ούτε θα συγχρονίζονται μέχρι να συνδεθείς ξανά.';

  @override
  String get accountUseDifferent => 'Χρήση άλλου λογαριασμού';

  @override
  String get accountSignInAgain => 'Σύνδεση ξανά';

  @override
  String get accountChooseAction => 'Επίλεξε πώς θέλεις να συνεχίσεις';

  @override
  String get accountChangedTitle => 'Διαφορετικός λογαριασμός Google';

  @override
  String get accountChangedBody =>
      'Αυτή η συσκευή συγχρονίστηκε τελευταία φορά με διαφορετικό λογαριασμό Google. Επίλεξε τι θα γίνει με τα τραγούδια και τις λίστες σε αυτήν τη συσκευή.';

  @override
  String get accountChangedMerge => 'Συγχώνευση με τον νέο λογαριασμό';

  @override
  String get accountChangedMergeHint =>
      'Διατήρησε τα πάντα σε αυτήν τη συσκευή και πρόσθεσέ τα στον νέο λογαριασμό.';

  @override
  String get accountChangedReplace =>
      'Αντικατάσταση με τη συλλογή του νέου λογαριασμού';

  @override
  String get accountChangedReplaceHint =>
      'Τα τραγούδια αυτής της συσκευής που δεν υπάρχουν στον νέο λογαριασμό θα αφαιρεθούν.';

  @override
  String get accountChangedSignOut => 'Ακύρωση και αποσύνδεση';

  @override
  String get accountStatusSignedOut =>
      'Λογαριασμός και συγχρονισμός: αποσυνδεδεμένος';

  @override
  String get accountStatusSignedIn =>
      'Λογαριασμός και συγχρονισμός: συνδεδεμένος';

  @override
  String get accountStatusSyncing =>
      'Λογαριασμός και συγχρονισμός: γίνεται συγχρονισμός';

  @override
  String get accountStatusSynced =>
      'Λογαριασμός και συγχρονισμός: η συλλογή είναι ενημερωμένη';

  @override
  String get accountStatusError =>
      'Λογαριασμός και συγχρονισμός: πρόβλημα, πάτησε για έλεγχο';

  @override
  String get accountNoticeConflicts =>
      'Ορισμένα τραγούδια τροποποιήθηκαν σε δύο σημεία. Τα αντίγραφα διατηρήθηκαν.';

  @override
  String get accountNoticeSignedIn => 'Συνδέθηκες.';

  @override
  String get accountNoticeSignedOut =>
      'Αποσυνδέθηκες. Τα τραγούδια σου παραμένουν σε αυτήν τη συσκευή.';

  @override
  String get syncErrorNotConfigured =>
      'Ο συγχρονισμός δεν έχει ρυθμιστεί σε αυτήν την έκδοση.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Χρησιμοποίησε έκδοση του Singbook με ρυθμισμένη σύνδεση Google.';

  @override
  String get syncErrorNotSignedIn => 'Δεν έχεις συνδεθεί.';

  @override
  String get syncErrorNotSignedInHint =>
      'Συνδέσου για να συγχρονίσεις τη συλλογή σου.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Η Google χρειάζεται να συνδεθείς ξανά.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Συνδέσου ξανά για να συνεχιστεί ο συγχρονισμός. Τα τραγούδια σου είναι ασφαλή σε αυτήν τη συσκευή.';

  @override
  String get syncErrorAccessDenied =>
      'Το Singbook δεν έχει άδεια χρήσης του Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Συνδέσου ξανά και επίτρεψε την πρόσβαση στο Drive όταν σου ζητηθεί.';

  @override
  String get syncErrorRateLimited =>
      'Η Google περιορίζει προσωρινά τα αιτήματα.';

  @override
  String get syncErrorRateLimitedHint =>
      'Περίμενε λίγα λεπτά και δοκίμασε ξανά.';

  @override
  String get syncErrorStorageFull => 'Ο χώρος στο Google Drive έχει γεμίσει.';

  @override
  String get syncErrorStorageFullHint =>
      'Ελευθέρωσε χώρο στο Drive και δοκίμασε ξανά.';

  @override
  String get syncErrorNetwork => 'Δεν ήταν δυνατή η σύνδεση με την Google.';

  @override
  String get syncErrorNetworkHint =>
      'Έλεγξε τη σύνδεσή σου στο διαδίκτυο και δοκίμασε ξανά.';

  @override
  String get syncErrorAccountChanged =>
      'Χρησιμοποιήθηκε διαφορετικός λογαριασμός Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Επίλεξε αν θα συγχωνευτεί η συλλογή αυτής της συσκευής με τον λογαριασμό ή αν θα αντικατασταθεί.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Η συγχρονισμένη συλλογή σου είναι μεγαλύτερη από όσο μπορεί να διαχειριστεί το Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Αφαίρεσε μερικά τραγούδια ή λίστες από τη συγχρονισμένη συλλογή και δοκίμασε ξανά.';

  @override
  String get syncErrorSignInFailed => 'Η σύνδεση δεν ολοκληρώθηκε.';

  @override
  String get syncErrorSignInFailedHint => 'Δοκίμασε να συνδεθείς ξανά.';

  @override
  String get syncErrorGeneric =>
      'Δεν ήταν δυνατός ο συγχρονισμός της συλλογής σου.';

  @override
  String get syncErrorGenericHint =>
      'Δοκίμασε ξανά σε λίγο. Τα τραγούδια σου παραμένουν ασφαλή σε αυτήν τη συσκευή.';

  @override
  String get editorDurationInvalid =>
      'Εισαγάγετε δευτερόλεπτα ή λεπτά και δευτερόλεπτα, π.χ. 3:45.';

  @override
  String get editorNumberInvalid => 'Εισαγάγετε έναν αριθμό.';

  @override
  String get accountReplaceConfirmTitle => 'Διαγραφή τοπικών τραγουδιών;';

  @override
  String get accountReplaceConfirmBody =>
      'Τα τραγούδια και οι λίστες σε αυτήν τη συσκευή που δεν υπάρχουν στον νέο λογαριασμό θα διαγραφούν οριστικά. Αυτή η ενέργεια δεν αναιρείται.';

  @override
  String get accountReplaceConfirmAction => 'Διαγραφή και αντικατάσταση';

  @override
  String get accountSuspiciousTitle => 'Λείπουν στοιχεία από το Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Λείπουν από το Google Drive $count στοιχεία που είχε συγχρονίσει παλαιότερα αυτή η συσκευή.',
      one:
          'Λείπει από το Google Drive $count στοιχείο που είχε συγχρονίσει παλαιότερα αυτή η συσκευή.',
    );
    return '$_temp0 Αυτό μπορεί να συμβεί αν διαγράφηκαν δεδομένα της εφαρμογής από τις ρυθμίσεις Google. Δεν έχει διαγραφεί τίποτα ακόμη.';
  }

  @override
  String get accountSuspiciousDelete => 'Να διαγραφούν και από εδώ';

  @override
  String get accountSuspiciousKeep =>
      'Κράτησε τα τραγούδια μου και ανέβασέ τα ξανά';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Να διαγραφούν $count στοιχεία από αυτήν τη συσκευή;',
      one: 'Να διαγραφεί $count στοιχείο από αυτήν τη συσκευή;',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Αυτά τα τραγούδια και οι λίστες τραγουδιών θα διαγραφούν οριστικά από αυτήν τη συσκευή. Δεν είναι δυνατή η αναίρεση.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Διαγραφή από αυτήν τη συσκευή';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Λείπουν στοιχεία από το Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Δεν διαγράφηκε τίποτα. Επίλεξε αν θέλεις να διαγραφούν και από εδώ ή να μεταφορτωθούν ξανά.';

  @override
  String get syncErrorRemoteChanged =>
      'Το Google Drive άλλαξε κατά τον συγχρονισμό.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Δεν χάθηκε τίποτα. Συγχρόνισε ξανά για να ληφθούν οι πιο πρόσφατες αλλαγές.';

  @override
  String get syncErrorInvalidLocalData =>
      'Δεν ήταν δυνατός ο συγχρονισμός ορισμένων δεδομένων σε αυτήν τη συσκευή.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Δεν ήταν δυνατή η ανάγνωση ενός τραγουδιού ή μιας λίστας τραγουδιών. Κάνε εισαγωγή ή δημιούργησέ τα ξανά και μετά συγχρόνισε ξανά.';

  @override
  String get syncErrorNoAccountChange =>
      'Δεν υπάρχει αλλαγή λογαριασμού προς επίλυση.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Συγχρόνισε ξανά για να συνεχίσεις.';

  @override
  String get accountSyncWarningTitle =>
      'Ο συγχρονισμός έγινε, αλλά παραλείφθηκαν ορισμένα αρχεία';

  @override
  String get accountSyncWarningBody =>
      'Δεν ήταν δυνατή η χρήση ορισμένων αρχείων και παρέμειναν ως είχαν. Όλα τα υπόλοιπα είναι ενημερωμένα.';

  @override
  String get accountSyncWarningTooLarge =>
      'Ένα αρχείο ήταν πολύ μεγάλο για συγχρονισμό και παραλείφθηκε. Όλα τα υπόλοιπα είναι ενημερωμένα.';

  @override
  String get accountSyncWarningInvalid =>
      'Δεν ήταν δυνατή η ανάγνωση ενός αρχείου και παραλείφθηκε. Όλα τα υπόλοιπα είναι ενημερωμένα.';

  @override
  String get accountNoticeSyncSkipped =>
      'Ο συγχρονισμός έγινε. Παραλείφθηκαν ορισμένα αρχεία.';

  @override
  String get settingsExportPdfTooLarge =>
      'Αυτό το PDF θα ήταν πολύ μεγάλο. Δοκίμασε λιγότερα τραγούδια ή κοινοποίησέ το ως κείμενο.';

  @override
  String get settingsTimingTooLarge =>
      'Τα δεδομένα χρονισμού είναι πολύ μεγάλα (πάνω από 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Αυτό το αντίγραφο ασφαλείας περιέχει το ίδιο τραγούδι δύο φορές, οπότε δεν έγινε εισαγωγή.';

  @override
  String get setlistSaveConflict =>
      'Η λίστα τραγουδιών άλλαξε αλλού. Οι αλλαγές σου αποθηκεύτηκαν ως ξεχωριστό αντίγραφο.';

  @override
  String get sectionVerse => 'Στροφή';

  @override
  String get sectionChorus => 'Ρεφρέν';

  @override
  String get sectionBridge => 'Γέφυρα';

  @override
  String get sectionIntro => 'Εισαγωγή';

  @override
  String get sectionOutro => 'Έξοδος';

  @override
  String get sectionPreChorus => 'Προ-ρεφρέν';

  @override
  String get sectionPostChorus => 'Μετά-ρεφρέν';

  @override
  String get sectionInstrumental => 'Οργανικό';

  @override
  String get sectionInterlude => 'Ιντερλούδιο';

  @override
  String get sectionSolo => 'Σόλο';

  @override
  String get sectionRefrain => 'Επωδός';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Κόδα';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Τέλος';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Διαθέσιμες εκδόσεις',
      one: '1 διαθέσιμη έκδοση',
      zero: '0 Διαθέσιμες εκδόσεις',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Μη διαθέσιμες εκδόσεις',
      one: '1 μη διαθέσιμη έκδοση',
      zero: '0 Μη διαθέσιμες εκδόσεις',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Μετάβαση στην ενότητα';

  @override
  String get searchVersionDetails => 'Λεπτομέρειες έκδοσης';

  @override
  String get searchSelectedRecording => 'Επιλεγμένη ηχογράφηση';

  @override
  String get searchVersionDuration => 'Διάρκεια έκδοσης';

  @override
  String get searchSourceOptions => 'Επιλογές πηγής';

  @override
  String get actionUndo => 'Αναίρεση';

  @override
  String setlistEntryRemoved(String song) {
    return 'Το τραγούδι «$song» αφαιρέθηκε από τη λίστα';
  }

  @override
  String get backupTitle => 'Δημιουργία αντιγράφου και επαναφορά';

  @override
  String get backupExport => 'Εξαγωγή αντιγράφου ασφαλείας';

  @override
  String get backupRestore => 'Επαναφορά αντιγράφου ασφαλείας';

  @override
  String get backupIncludePreferences => 'Συμπερίληψη προτιμήσεων εφαρμογής';

  @override
  String get backupRestorePreferences => 'Επαναφορά προτιμήσεων εφαρμογής';

  @override
  String get backupMerge => 'Προσθήκη σε αυτήν τη βιβλιοθήκη';

  @override
  String get backupMergeHint =>
      'Διατηρήστε τις τοπικές αλλαγές και προσθέστε τραγούδια και λίστες από αυτό το αντίγραφο.';

  @override
  String get backupReplace => 'Αντικατάσταση αυτής της βιβλιοθήκης';

  @override
  String get backupReplaceHint =>
      'Αντικαταστήστε όλα τα τραγούδια και τις λίστες σε αυτήν τη συσκευή με αυτό το αντίγραφο.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Τραγούδια: $songs · Λίστες: $setlists · Διενέξεις: $conflicts';
  }

  @override
  String get backupFailed =>
      'Δεν ήταν δυνατή η ολοκλήρωση της ενέργειας. Δοκιμάστε ξανά.';

  @override
  String get backupRestored => 'Το αντίγραφο ασφαλείας επαναφέρθηκε.';

  @override
  String get backupLocalHint =>
      'Αποθηκεύστε ένα αντίγραφο της βιβλιοθήκης σας. Δεν περιλαμβάνονται στοιχεία λογαριασμού ή cookies συγκατάθεσης.';

  @override
  String get backupReplaceConfirm =>
      'Να αντικατασταθεί η τρέχουσα βιβλιοθήκη; Αυτή η ενέργεια δεν αναιρείται.';

  @override
  String get searchCheckOperations => 'Λειτουργίες';

  @override
  String get searchCheckCode => 'Κωδικός αποτελέσματος';

  @override
  String get searchCheckQueued => 'Αναμονή για έλεγχο αυτής της πηγής.';

  @override
  String get searchCheckFetch => 'Φόρτωση στίχων';

  @override
  String get searchCheckValidate => 'Έλεγχος αντιστοιχίας τραγουδιού';

  @override
  String get searchCheckCorroborate => 'Έλεγχος συμφωνίας στίχων';

  @override
  String get searchCheckCompleted => 'Ολοκληρώθηκε';

  @override
  String get searchCheckTimeout => 'Η πηγή δεν αποκρίθηκε εγκαίρως.';

  @override
  String get searchCheckBlocked => 'Η πηγή απέκλεισε το αίτημα.';

  @override
  String get searchCheckRateLimited =>
      'Η πηγή περιορίζει τα αιτήματα. Δοκιμάστε ξανά αργότερα.';

  @override
  String get searchCheckNetwork =>
      'Δεν ήταν δυνατή η πρόσβαση στην πηγή. Ελέγξτε τη σύνδεσή σας.';

  @override
  String get searchCheckInvalid => 'Η πηγή επέστρεψε μη αναγνώσιμη απάντηση.';

  @override
  String get searchCheckNotConfigured =>
      'Αυτή η πηγή δεν έχει ρυθμιστεί σε αυτήν την έκδοση.';

  @override
  String get searchCheckNoLyrics => 'Δεν βρέθηκαν αντίστοιχοι στίχοι.';

  @override
  String get searchCheckFailed =>
      'Δεν ήταν δυνατή η ολοκλήρωση αυτής της λειτουργίας.';

  @override
  String get searchCheckNoHistory =>
      'Δεν έχουν εκτελεστεί έλεγχοι πηγών για αυτήν τη σύγκριση.';

  @override
  String get searchVersionCredits => 'Συντελεστές';

  @override
  String get searchVersionMediaLinks => 'Σχετικοί σύνδεσμοι';

  @override
  String get searchCheckCancelled => 'Ακυρώθηκε';

  @override
  String get searchCheckAmbiguous =>
      'Βρέθηκαν πολλά αποτελέσματα. Αυτή η πηγή χρειάζεται πιο συγκεκριμένη ηχογράφηση.';

  @override
  String get searchCheckIdentity =>
      'Αυτή η πηγή χρειάζεται αναγνωριστικό ηχογράφησης ή έργου.';

  @override
  String get searchCheckExtraction =>
      'Η πηγή αποκρίθηκε, αλλά δεν ήταν δυνατή η εξαγωγή των στίχων.';

  @override
  String get searchCheckBusy =>
      'Η πηγή είναι απασχολημένη. Δοκιμάστε ξανά αργότερα.';

  @override
  String get searchCheckSelection =>
      'Επιλέξτε ένα συγκεκριμένο αποτέλεσμα από αυτήν την πηγή.';

  @override
  String get playerChordsNone => 'Κανένα';

  @override
  String get editorCustomValue => 'Άλλο…';

  @override
  String get editorStandardTuning => 'Τυπικό κούρδισμα';

  @override
  String get editorExampleVerse =>
      '[C]Μια νέα μέρα μας [G]καλεί,\n[Am]ακολουθούμε το φως πίσω στο [F]σπίτι.';

  @override
  String get editorExampleChorus =>
      '[F]Ας τραγουδήσουμε αυτό το τραγούδι [C]μαζί,\n[G]κι ας μας ταξιδέψει η μελωδία [C]παραπέρα.';

  @override
  String get editorExampleBridge => '[Am]Άλλος ένας στίχος, λίγο πιο [F]κοντά.';
}
