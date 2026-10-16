// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Ein ruhiger Ort, um deine Songbibliothek zu durchsuchen, zu ordnen und daraus zu singen.';

  @override
  String get aboutMadeForSinging => 'Zum gemeinsamen Singen gemacht';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get navHome => 'Startseite';

  @override
  String get navSongs => 'Songs';

  @override
  String get navSetlists => 'Setlists';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navSettingsCompact => 'Einstellungen';

  @override
  String get navSearch => 'Suche';

  @override
  String get navBack => 'Zurück';

  @override
  String get appExitBackAgain => 'Zum Beenden erneut Zurück drücken';

  @override
  String get navClose => 'Schließen';

  @override
  String get navMore => 'Weitere Aktionen';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionDone => 'Fertig';

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionShare => 'Teilen';

  @override
  String get actionPrint => 'Drucken';

  @override
  String get actionCopy => 'Kopieren';

  @override
  String get actionClear => 'Leeren';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String get actionRefresh => 'Aktualisieren';

  @override
  String get actionImport => 'Importieren';

  @override
  String get actionExport => 'Exportieren';

  @override
  String get actionExpand => 'Ausklappen';

  @override
  String get actionCollapse => 'Einklappen';

  @override
  String get actionAdd => 'Hinzufügen';

  @override
  String get actionCreate => 'Erstellen';

  @override
  String get actionRemove => 'Entfernen';

  @override
  String get actionDuplicate => 'Duplizieren';

  @override
  String get actionMoveUp => 'Nach oben verschieben';

  @override
  String get actionMoveDown => 'Nach unten verschieben';

  @override
  String get actionPrevious => 'Zurück';

  @override
  String get actionNext => 'Weiter';

  @override
  String get searchHint => 'Nach Songs, Künstlern oder Liedtexten suchen';

  @override
  String get searchCatalogHint => 'Nach einem Song oder Künstler suchen';

  @override
  String get searchChangeSong => 'Song ändern';

  @override
  String get searchSelectedPreview => 'Ausgewählte Vorschau';

  @override
  String get searchSubmit => 'Suchen';

  @override
  String get searchFilters => 'Suchoptionen';

  @override
  String get searchFiltersShow => 'Suchoptionen anzeigen';

  @override
  String get searchFiltersHide => 'Suchoptionen ausblenden';

  @override
  String get searchFilterArtist => 'Künstler';

  @override
  String get searchFilterTitle => 'Songtitel';

  @override
  String get searchFilterLyrics => 'Liedtexte';

  @override
  String get searchFilterChords => 'Mit Akkorden';

  @override
  String get searchFilterTimed => 'Synchronisierte Liedtexte';

  @override
  String get searchFilterLanguage => 'Sprache';

  @override
  String get searchFilterAll => 'Beliebig';

  @override
  String get searchAutocompleteLabel => 'Vorschläge';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ergebnisse',
      one: '1 Ergebnis',
      zero: 'Keine Ergebnisse',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Gib einen Song, Künstler oder Liedtext für die Suche ein.';

  @override
  String get searchCatalogEmptyQuery =>
      'Gib einen Song oder Künstler für die Suche ein.';

  @override
  String get searchNoResults =>
      'Keine Songs gefunden. Versuche eine andere Suche.';

  @override
  String get searchLoading => 'Songs werden gesucht…';

  @override
  String get searchError => 'Die Suche konnte nicht abgeschlossen werden.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Zuletzt verwendet';

  @override
  String get searchFavoritesTab => 'Favoriten';

  @override
  String get searchSuggested => 'Vorgeschlagener Treffer';

  @override
  String get searchAlternatives => 'Weitere Treffer';

  @override
  String get searchCompare => 'Versionen vergleichen';

  @override
  String get searchChooseVersion => 'Diese Version auswählen';

  @override
  String get searchFullPreview => 'Vollständige Vorschau';

  @override
  String get searchArrangementNotes => 'Arrangierhinweise';

  @override
  String get searchOpenLyrics => 'Liedtext öffnen';

  @override
  String get searchContributions => 'Verwendete Quellen';

  @override
  String get searchVersionChecking => 'Diese Version wird geprüft…';

  @override
  String get searchVersionUnavailable =>
      'Diese Version kann nicht verwendet werden. Wähle eine andere Version.';

  @override
  String get searchPreviewUnavailable => 'Keine Liedtextvorschau verfügbar.';

  @override
  String get searchSongMatch => 'Songtreffer';

  @override
  String get searchRecordingMatch => 'Aufnahmetreffer';

  @override
  String get searchMatchUnverified => 'Aufnahme nicht verifiziert';

  @override
  String get searchMatchExact => 'Exakte Übereinstimmung der Aufnahme';

  @override
  String get searchMatchPossible => 'Mögliche Übereinstimmung';

  @override
  String get searchAvailability => 'Verfügbarkeit';

  @override
  String get searchLyricsAvailable => 'Liedtext verfügbar';

  @override
  String get searchLyricsUnavailable => 'Liedtext nicht verfügbar';

  @override
  String get searchChordsAvailable => 'Akkorde verfügbar';

  @override
  String get searchChordsUnavailable => 'Keine Akkorde';

  @override
  String get searchTimingAvailable => 'Timing verfügbar';

  @override
  String get searchTimingUnavailable => 'Kein Timing';

  @override
  String get searchDurationUnknown => 'Dauer unbekannt';

  @override
  String searchRating(String rating) {
    return 'Bewertung $rating';
  }

  @override
  String get searchSourceLabel => 'Quelle';

  @override
  String get searchMetadata => 'Songdetails';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Künstler';

  @override
  String get searchYear => 'Jahr';

  @override
  String get searchLanguage => 'Sprache';

  @override
  String get searchViewVersions => 'Versionen ansehen';

  @override
  String get searchSaved => 'Song wurde in deiner Bibliothek gespeichert.';

  @override
  String get searchSaveOpenLyrics => 'Text speichern & öffnen';

  @override
  String get searchOtherResults => 'Weitere Ergebnisse';

  @override
  String get searchSaveFailed => 'Song konnte nicht gespeichert werden.';

  @override
  String get homeRecentSongs => 'Zuletzt verwendete Songs';

  @override
  String get homeRecentlyPlayed => 'Zuletzt abgespielt';

  @override
  String get homeFavorites => 'Favoriten';

  @override
  String get homeHistory => 'Verlauf';

  @override
  String get homeHistoryClear => 'Verlauf löschen';

  @override
  String get homeHistoryCleared => 'Verlauf gelöscht.';

  @override
  String get homeHistoryEmpty => 'Hier erscheinen Songs, die du öffnest.';

  @override
  String get homeFavoritesEmpty =>
      'Hier erscheinen deine Lieblingssongs und Setlists.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente angezeigt',
      one: '1 Element angezeigt',
      zero: '0 Elemente angezeigt',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Hier erscheinen deine zuletzt verwendeten Songs und Setlists.';

  @override
  String get homeTimelineLabel => 'Verlaufszeitleiste';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Gesamter Verlauf';

  @override
  String get homeShowFavorites => 'Favoriten anzeigen';

  @override
  String get homeShowRecent => 'Zuletzt verwendete anzeigen';

  @override
  String get songsTitle => 'Songs';

  @override
  String get songsEmpty => 'Hier erscheinen deine Songs.';

  @override
  String get songsEmptySearch => 'Keine Songs entsprechen deiner Suche.';

  @override
  String get songsAdd => 'Song hinzufügen';

  @override
  String get songsSortAlphabetical => 'Alphabetisch sortieren';

  @override
  String get songsAlphabetNavigation => 'Songindex';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal geöffnet',
      one: 'Einmal geöffnet',
      zero: 'Nie geöffnet',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'Zu Favoriten hinzufügen';

  @override
  String get songFavoriteRemove => 'Aus Favoriten entfernen';

  @override
  String get songMenuLabel => 'Songaktionen';

  @override
  String get songInfo => 'Songdetails';

  @override
  String get setlistMenuLabel => 'Setlist-Aktionen';

  @override
  String get songAddToSetlist => 'Zur Setlist hinzufügen';

  @override
  String get songCopyChordPro => 'ChordPro kopieren';

  @override
  String get songDeleteConfirmTitle => 'Song löschen?';

  @override
  String get songDeleteConfirmMessage =>
      'Dieser Song wird aus deiner Bibliothek entfernt.';

  @override
  String get songDeleted => 'Song gelöscht.';

  @override
  String get setlistsTitle => 'Setlists';

  @override
  String get setlistsEmpty =>
      'Erstelle eine Setlist für deine nächste Probe oder deinen nächsten Auftritt.';

  @override
  String get setlistsEmptySearch => 'Keine Setlists entsprechen deiner Suche.';

  @override
  String get setlistCreate => 'Neue Setlist';

  @override
  String get setlistNameHint => 'Name der Setlist';

  @override
  String get setlistNotes => 'Notizen';

  @override
  String get setlistEntryOverride => 'Songbezogene Tonart und Capo';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs',
      one: '1 Song',
      zero: 'Keine Songs',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Mindestens $duration';
  }

  @override
  String get setlistDurationUnknown => 'Dauer unbekannt';

  @override
  String setlistActivity(String date) {
    return 'Letzte Aktivität $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Erstellt $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Bearbeitet $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Zuletzt gespielt $date';
  }

  @override
  String get setlistSongsEmpty => 'Diese Setlist enthält noch keine Songs.';

  @override
  String get setlistAddSongs => 'Songs hinzufügen';

  @override
  String get setlistReorder => 'Songreihenfolge ändern';

  @override
  String setlistMoveSongUp(String song) {
    return '$song nach oben verschieben';
  }

  @override
  String setlistMoveSongDown(String song) {
    return '$song nach unten verschieben';
  }

  @override
  String setlistRemoveSong(String song) {
    return '$song aus der Setlist entfernen';
  }

  @override
  String get setlistDuplicate => 'Setlist duplizieren';

  @override
  String get setlistFavoriteAdd => 'Setlist zu Favoriten hinzufügen';

  @override
  String get setlistFavoriteRemove => 'Setlist aus Favoriten entfernen';

  @override
  String get setlistShare => 'Als Setlist-Datei teilen';

  @override
  String get setlistSharePdf => 'Als PDF teilen';

  @override
  String get setlistPrint => 'Drucken';

  @override
  String get setlistDeleteConfirmTitle => 'Setlist löschen?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Die Setlist wird entfernt. Songs in deiner Bibliothek bleiben erhalten.';

  @override
  String get setlistDeleted => 'Setlist gelöscht.';

  @override
  String get readerTitle => 'Liedtexte';

  @override
  String get readerNoLyrics => 'Es wurden noch keine Liedtexte hinzugefügt.';

  @override
  String get readerShowChords => 'Akkorde anzeigen';

  @override
  String get readerHideChords => 'Akkorde ausblenden';

  @override
  String get readerTranspose => 'Akkorde transponieren';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Halbtöne',
      one: '1 Halbton',
      zero: '0 Halbtöne',
    );
    return 'Um $_temp0 transponieren';
  }

  @override
  String get readerSaved => 'Gespeichert';

  @override
  String get readerEdit => 'Liedtexte und Details bearbeiten';

  @override
  String get playerPlay => 'Liedtext-Scrollen starten';

  @override
  String get playerPause => 'Liedtext-Scrollen pausieren';

  @override
  String get playerResume => 'Liedtext-Scrollen fortsetzen';

  @override
  String get playerSeek => 'Wiedergabeposition';

  @override
  String playerElapsed(String time) {
    return 'Vergangene Zeit $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Verbleibende Zeit $time';
  }

  @override
  String get playerTimingMode => 'Scrollmodus';

  @override
  String get playerTimedLyrics => 'Synchronisierte Liedtexte';

  @override
  String get playerStartScroll => 'Auto-Scroll starten';

  @override
  String get playerEstimatedPace => 'Geschätztes Tempo';

  @override
  String get playerScrollSpeed => 'Scroll-Geschwindigkeit';

  @override
  String playerEstimatedDuration(String time) {
    return 'Geschätzte Dauer: $time';
  }

  @override
  String get playerLyricsOnly => 'Liedtext-Scrollen · kein Audio';

  @override
  String get playerManualScroll => 'Manuelles Scrollen';

  @override
  String get playerTimingStatusReady =>
      'Der Liedtext folgt dem verfügbaren Timing.';

  @override
  String get playerTimingStatusEstimated =>
      'Das Scrolltempo wird anhand der Songdauer geschätzt.';

  @override
  String get playerTimingStatusManual => 'Scrolle selbst durch den Liedtext.';

  @override
  String get playerTimingStatusUnavailable =>
      'Für diesen Song ist kein synchronisiertes Scrollen verfügbar.';

  @override
  String get playerDurationUnknown =>
      'Füge eine Songdauer hinzu, um das geschätzte Scrollen zu nutzen.';

  @override
  String get playerProgressLabel => 'Songfortschritt';

  @override
  String get playerCurrentSection => 'Aktueller Abschnitt';

  @override
  String get playerPreviousSection => 'Vorheriger Abschnitt';

  @override
  String get playerNextSection => 'Nächster Abschnitt';

  @override
  String get playerPreviousSectionSong =>
      'Vorheriger Abschnitt · halten für vorherigen Song der Setlist';

  @override
  String get playerNextSectionSong =>
      'Nächster Abschnitt · halten für nächsten Song der Setlist';

  @override
  String get playerPreviousSong => 'Vorheriger Song';

  @override
  String get playerNextSong => 'Nächster Song';

  @override
  String get editorTitle => 'Song bearbeiten';

  @override
  String get editorTitleField => 'Songtitel';

  @override
  String get editorArtistField => 'Künstler';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Liedtext';

  @override
  String get editorChordsField => 'Akkorde';

  @override
  String get editorKeyField => 'Tonart';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Stimmung';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Dauer';

  @override
  String get editorTimeSignatureField => 'Taktart';

  @override
  String get editorLanguageField => 'Sprache';

  @override
  String get editorYearField => 'Jahr';

  @override
  String get editorComposerField => 'Komponist';

  @override
  String get editorLyricistField => 'Textdichter';

  @override
  String get editorCopyrightField => 'Urheberrecht';

  @override
  String get editorLicenseField => 'Lizenz';

  @override
  String get songInfoSources => 'Quellen und Credits';

  @override
  String get searchMatchSameSong => 'Gleicher Song; Aufnahme nicht bestätigt';

  @override
  String get searchMatchNeedsAgreement =>
      'Liedtext muss anhand des Akkordblatts überprüft werden';

  @override
  String get searchMatchDifferentLyrics =>
      'Der Liedtext unterscheidet sich vom ausgewählten Song';

  @override
  String get searchMatchCombinedSources =>
      'Details aus mehreren Quellen zusammengeführt';

  @override
  String get searchCombinedLabel => 'Alle';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passende Songs',
      one: '1 passender Song',
      zero: '0 passende Songs',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Quellversionen',
      one: '1 Quellversion',
      zero: '0 Quellversionen',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Bester verfügbarer Treffer';

  @override
  String get providerDescriptionUnknown => 'Songquelle';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Lade eine ChordPro-Datei von der Quelle herunter und importiere sie anschließend.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Lade die Datei mit einem kostenlosen Konto herunter und importiere sie anschließend.';

  @override
  String get providerDescPublicChordSheets => 'Öffentliche Akkordblätter.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Historische Liedtexte, deren Lizenz je Werk gilt.';

  @override
  String get providerDescLicensedCatalog => 'Lizenzierter Liedtextkatalog.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Originalsongs unter Creative-Commons-BY-Lizenz.';

  @override
  String get providerDescPerSongLicense =>
      'Liedtexte werden je Song lizenziert.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Nur Angaben zu Aufnahme und Veröffentlichung.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Nur Angaben zur Komposition.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Coverbilder nur für exakte Aufnahmetreffer.';

  @override
  String get providerCapabilityLyrics => 'Liedtexte';

  @override
  String get providerCapabilityChords => 'Akkorde';

  @override
  String get providerCapabilityTiming => 'Synchronisierte Liedtexte';

  @override
  String get providerCapabilitySearch => 'Suche';

  @override
  String get providerCapabilityMetadata => 'Songdetails';

  @override
  String get editorArtworkField => 'Cover-Link';

  @override
  String get editorLyricsHint =>
      'Tippe auf eine Zeile, um Liedtext oder Akkorde zu bearbeiten.';

  @override
  String get editorSave => 'Änderungen speichern';

  @override
  String get editorSaved => 'Änderungen gespeichert.';

  @override
  String get editorSaveFailed => 'Änderungen konnten nicht gespeichert werden.';

  @override
  String get editorSaveConflict =>
      'Der Song wurde an anderer Stelle geändert. Deine Änderungen wurden als separate Kopie gespeichert.';

  @override
  String get editorUnsavedTitle => 'Änderungen verwerfen?';

  @override
  String get editorUnsavedMessage =>
      'Deine Änderungen wurden nicht gespeichert.';

  @override
  String get editorFieldRequired => 'Gib einen Songtitel ein.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeSystem => 'Geräteeinstellung verwenden';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsColorPalette => 'Farbpalette';

  @override
  String get settingsFont => 'Schriftart';

  @override
  String get settingsTextSize => 'Textgröße';

  @override
  String get settingsLyricsPreview => 'Liedtextvorschau';

  @override
  String get settingsPlayer => 'Liedtext-Player';

  @override
  String get settingsDefaultShowChords => 'Akkorde standardmäßig anzeigen';

  @override
  String get settingsDefaultAutoscroll =>
      'Liedtext automatisch scrollen lassen';

  @override
  String get settingsDefaultTiming => 'Standard-Scrollmodus';

  @override
  String get settingsLanguage => 'App-Sprache';

  @override
  String get settingsLanguageSystem => 'Gerätesprache verwenden';

  @override
  String get settingsLanguageEnglish => 'Englisch';

  @override
  String get settingsLanguageBulgarian => 'Bulgarisch';

  @override
  String get settingsLanguageUkrainian => 'Ukrainisch';

  @override
  String get settingsSources => 'Liedtextquellen';

  @override
  String settingsSourceEnabled(String source) {
    return 'Quelle $source aktivieren';
  }

  @override
  String get settingsSourceRefresh => 'Quellenliste aktualisieren';

  @override
  String get settingsSourcesUpdated => 'Quellen aktualisiert.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Quellen konnten nicht aktualisiert werden.';

  @override
  String get settingsImport => 'Songs importieren';

  @override
  String get settingsImportChordPro => 'ChordPro-Datei importieren';

  @override
  String get settingsImportSetlist => 'Setlist-Datei importieren';

  @override
  String get settingsImportSuccess => 'Import abgeschlossen.';

  @override
  String get settingsImportFailed =>
      'Diese Datei konnte nicht importiert werden.';

  @override
  String get settingsImportUnsupported =>
      'Dieser Dateityp wird nicht unterstützt.';

  @override
  String get settingsShareSong => 'Als ChordPro teilen';

  @override
  String get settingsSharePdf => 'Als PDF teilen';

  @override
  String get settingsCopySong => 'In die Zwischenablage kopieren';

  @override
  String get settingsPrintSong => 'Nur Song drucken';

  @override
  String get settingsPrintSetlist => 'Setlist mit Liedtexten drucken';

  @override
  String get settingsExportFailed => 'Datei konnte nicht vorbereitet werden.';

  @override
  String get settingsCopied => 'In die Zwischenablage kopiert.';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsLegal => 'Rechtliches';

  @override
  String get settingsClearHistory => 'Verlauf löschen';

  @override
  String get settingsClearHistoryConfirm =>
      'Verlauf deiner Songs und Setlists löschen?';

  @override
  String get settingsHistoryCleared => 'Verlauf gelöscht.';

  @override
  String get accountTitle => 'Konto und Synchronisierung';

  @override
  String get accountUnavailable =>
      'Für die Synchronisierung wird eine Singbook-Version mit eingerichtetem Google-Login benötigt. In dieser Version bleiben deine Songs nur auf diesem Gerät.';

  @override
  String get accountSyncNow => 'Jetzt synchronisieren';

  @override
  String get accountConnected =>
      'Verbunden. Wähle „Jetzt synchronisieren“, um dein Backup zu aktualisieren.';

  @override
  String get accountSignIn => 'Konto verbinden';

  @override
  String get accountSignOut => 'Abmelden';

  @override
  String get accountChange => 'Konto wechseln';

  @override
  String get accountSignedOut => 'Nicht verbunden';

  @override
  String get accountSyncing => 'Deine Bibliothek wird synchronisiert…';

  @override
  String get accountSynced => 'Bibliothek synchronisiert.';

  @override
  String get accountSyncFailed =>
      'Deine Bibliothek konnte nicht synchronisiert werden.';

  @override
  String get accessibilityFavorite => 'Favorit';

  @override
  String get accessibilityNotFavorite => 'Kein Favorit';

  @override
  String get accessibilitySearchField => 'Songs suchen';

  @override
  String get accessibilityClearSearch => 'Suchtext löschen';

  @override
  String accessibilitySongMenu(String song) {
    return 'Aktionen für $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Aktionen für $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Songs in $setlist ausklappen';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Songs in $setlist einklappen';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Wiedergabefortschritt, $percent Prozent';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Verlaufszeitleiste, $date';
  }

  @override
  String get loading => 'Wird geladen…';

  @override
  String get loadingSongs => 'Songs werden geladen…';

  @override
  String get loadingSetlists => 'Setlists werden geladen…';

  @override
  String get errorGeneric => 'Etwas ist schiefgelaufen.';

  @override
  String get errorOffline => 'Du scheinst offline zu sein.';

  @override
  String get errorPermission =>
      'Zum Fortfahren ist eine Berechtigung erforderlich.';

  @override
  String get emptyFiltered => 'Keine Elemente entsprechen diesen Filtern.';

  @override
  String get unknownValue => 'Unbekannt';

  @override
  String get durationUnknown => 'Dauer unbekannt';

  @override
  String get metadataNotSet => 'Nicht festgelegt';

  @override
  String get dateToday => 'Heute';

  @override
  String get dateYesterday => 'Gestern';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs',
      one: '1 Song',
      zero: 'Keine Songs',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Marineblau';

  @override
  String get settingsPaletteSage => 'Salbeigrün';

  @override
  String get settingsPaletteOcean => 'Ozean';

  @override
  String get settingsPaletteClay => 'Terrakotta';

  @override
  String get settingsPalettePlum => 'Pflaume';

  @override
  String get settingsFontSystem => 'System';

  @override
  String get settingsFontSerif => 'Serifenschrift';

  @override
  String get settingsFontMonospace => 'Festbreitenschrift';

  @override
  String get settingsLyricsPreviewExample =>
      'Wenn der Morgen kommt, singen wir wieder.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Liedtextquellen werden geprüft: $checked von $total abgeschlossen.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Keine verwendbaren Liedtexte gefunden.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Der ausgewählte Song wurde mit den aktivierten Quellen abgeglichen, aber keine lieferte eine verwendbare Liedtextversion.';

  @override
  String get searchDiscoveryError =>
      'Liedtextquellen konnten nicht geprüft werden.';

  @override
  String get searchDiscoveryRetry => 'Liedtextsuche wiederholen';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Quellen nicht verfügbar',
      one: '1 Quelle nicht verfügbar',
      zero: '0 Quellen nicht verfügbar',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails =>
      'Überprüfe deine Verbindung und versuche es erneut.';

  @override
  String get searchProviderChecks => 'Quellenprüfungen';

  @override
  String get searchProviderPending => 'Wird geprüft';

  @override
  String get searchProviderFound => 'Treffer gefunden';

  @override
  String get searchProviderRejected => 'Keine Übereinstimmung';

  @override
  String get searchProviderFailed => 'Prüfung fehlgeschlagen';

  @override
  String get searchProviderUnavailable => 'Keine verwendbaren Liedtexte';

  @override
  String get searchCatalogFilterHint =>
      'Wähle einen Song aus, um Liedtextversionen nach Akkorden, Timing oder Sprache zu filtern.';

  @override
  String get startupErrorTitle =>
      'Deine Bibliothek konnte nicht geöffnet werden.';

  @override
  String setlistCopyName(String name) {
    return '$name Kopie';
  }

  @override
  String get setlistSongMissing => 'Fehlender Song';

  @override
  String get settingsImportTooLarge =>
      'Diese Datei ist zu groß für den Import.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Zu $letter springen';
  }

  @override
  String get actionDiscard => 'Verwerfen';

  @override
  String get editorKeepEditing => 'Weiter bearbeiten';

  @override
  String get settingsDefaultShowChordsHint =>
      'Akkorde über dem Liedtext anzeigen, wenn ein Song welche hat.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Der Liedtext scrollt passend zum Song. Im manuellen Scrollmodus wird dies nicht verwendet.';

  @override
  String get accountUnavailableTitle => 'Synchronisierung nicht eingerichtet';

  @override
  String get accountSignedOutBenefits =>
      'Beim Verbinden mit Google Drive wird deine Bibliothek synchronisiert. Änderungen an Songs werden danach automatisch synchronisiert.';

  @override
  String get accountManualSyncHint =>
      'Du kannst auch auf Jetzt synchronisieren tippen, um deine Bibliothek zu synchronisieren.';

  @override
  String get accountSignInWithGoogle => 'Mit Google anmelden';

  @override
  String get accountWorking => 'Wird ausgeführt…';

  @override
  String get accountNeverSynced => 'Noch nie synchronisiert';

  @override
  String get accountSyncedJustNow => 'Gerade synchronisiert';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Minuten synchronisiert',
      one: 'Vor 1 Minute synchronisiert',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Stunden synchronisiert',
      one: 'Vor 1 Stunde synchronisiert',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Tagen synchronisiert',
      one: 'Vor 1 Tag synchronisiert',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count widersprüchliche Änderungen als Kopien gespeichert',
      one: '1 widersprüchliche Änderung als Kopie gespeichert',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Derselbe Song oder dieselbe Setlist wurde an zwei Orten bearbeitet. Es ging nichts verloren: Die andere Version wurde als separate Kopie gespeichert.';

  @override
  String get accountReviewConflicts => 'Kopien prüfen';

  @override
  String get songsConflictFilterActive => 'Nur Konfliktkopien werden angezeigt';

  @override
  String get songsConflictFilterClear => 'Alle Songs anzeigen';

  @override
  String get songsConflictBadge => 'Konfliktkopie';

  @override
  String get songsConflictEmpty => 'Keine Konfliktkopien.';

  @override
  String get accountAutoSync => 'Automatisch synchronisieren';

  @override
  String get accountAutoSyncHint =>
      'Synchronisiert wird nach dem Verbinden sowie nach dem Hinzufügen, Bearbeiten oder Entfernen eines Songs.';

  @override
  String get accountSignOutTitle => 'Von diesem Konto abmelden?';

  @override
  String get accountSignOutBody =>
      'Deine Songs und Setlists bleiben auf diesem Gerät. Sie werden erst wieder gesichert und synchronisiert, wenn du dich erneut anmeldest.';

  @override
  String get accountUseDifferent => 'Anderes Konto verwenden';

  @override
  String get accountSignInAgain => 'Erneut anmelden';

  @override
  String get accountChooseAction => 'Wähle, wie du fortfahren möchtest';

  @override
  String get accountChangedTitle => 'Anderes Google-Konto';

  @override
  String get accountChangedBody =>
      'Dieses Gerät wurde zuletzt mit einem anderen Google-Konto synchronisiert. Wähle, was mit den Songs und Setlists auf diesem Gerät geschehen soll.';

  @override
  String get accountChangedMerge => 'Mit dem neuen Konto zusammenführen';

  @override
  String get accountChangedMergeHint =>
      'Behalte alles auf diesem Gerät und füge es dem neuen Konto hinzu.';

  @override
  String get accountChangedReplace =>
      'Durch die Bibliothek des neuen Kontos ersetzen';

  @override
  String get accountChangedReplaceHint =>
      'Songs auf diesem Gerät, die nicht im neuen Konto vorhanden sind, werden entfernt.';

  @override
  String get accountChangedSignOut => 'Abbrechen und abmelden';

  @override
  String get accountStatusSignedOut =>
      'Konto und Synchronisierung: nicht angemeldet';

  @override
  String get accountStatusSignedIn => 'Konto und Synchronisierung: angemeldet';

  @override
  String get accountStatusSyncing =>
      'Konto und Synchronisierung: wird synchronisiert';

  @override
  String get accountStatusSynced =>
      'Konto und Synchronisierung: Bibliothek ist aktuell';

  @override
  String get accountStatusError =>
      'Konto und Synchronisierung: Problem, zum Prüfen tippen';

  @override
  String get accountNoticeConflicts =>
      'Einige Songs wurden an zwei Orten bearbeitet. Kopien wurden beibehalten.';

  @override
  String get accountNoticeSignedIn => 'Angemeldet.';

  @override
  String get accountNoticeSignedOut =>
      'Abgemeldet. Deine Songs bleiben auf diesem Gerät.';

  @override
  String get syncErrorNotConfigured =>
      'Die Synchronisierung ist in dieser Version nicht eingerichtet.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Verwende eine Singbook-Version mit eingerichtetem Google-Login.';

  @override
  String get syncErrorNotSignedIn => 'Du bist nicht angemeldet.';

  @override
  String get syncErrorNotSignedInHint =>
      'Melde dich an, um deine Bibliothek zu synchronisieren.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google verlangt, dass du dich erneut anmeldest.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Melde dich erneut an, um die Synchronisierung fortzusetzen. Deine Songs sind auf diesem Gerät sicher.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook hat keine Berechtigung, Google Drive zu verwenden.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Melde dich erneut an und erlaube den Zugriff auf Drive, wenn du dazu aufgefordert wirst.';

  @override
  String get syncErrorRateLimited => 'Google begrenzt Anfragen derzeit.';

  @override
  String get syncErrorRateLimitedHint =>
      'Warte einige Minuten und versuche es dann erneut.';

  @override
  String get syncErrorStorageFull => 'Dein Google Drive ist voll.';

  @override
  String get syncErrorStorageFullHint =>
      'Gib Speicherplatz in Drive frei und versuche es erneut.';

  @override
  String get syncErrorNetwork => 'Google konnte nicht erreicht werden.';

  @override
  String get syncErrorNetworkHint =>
      'Überprüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get syncErrorAccountChanged =>
      'Es wurde ein anderes Google-Konto verwendet.';

  @override
  String get syncErrorAccountChangedHint =>
      'Wähle, ob die Bibliothek dieses Geräts damit zusammengeführt oder ersetzt werden soll.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Deine synchronisierte Bibliothek ist größer, als Singbook verarbeiten kann.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Entferne einige Songs oder Setlists aus der synchronisierten Bibliothek und versuche es erneut.';

  @override
  String get syncErrorSignInFailed =>
      'Die Anmeldung wurde nicht abgeschlossen.';

  @override
  String get syncErrorSignInFailedHint => 'Versuche, dich erneut anzumelden.';

  @override
  String get syncErrorGeneric =>
      'Deine Bibliothek konnte nicht synchronisiert werden.';

  @override
  String get syncErrorGenericHint =>
      'Versuche es gleich noch einmal. Deine Songs sind auf diesem Gerät weiterhin sicher.';

  @override
  String get editorDurationInvalid =>
      'Gib Sekunden oder Minuten und Sekunden ein, z. B. 3:45.';

  @override
  String get editorNumberInvalid => 'Gib eine Zahl ein.';

  @override
  String get accountReplaceConfirmTitle => 'Lokale Songs löschen?';

  @override
  String get accountReplaceConfirmBody =>
      'Songs und Setlists auf diesem Gerät, die nicht im neuen Konto vorhanden sind, werden endgültig gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get accountReplaceConfirmAction => 'Löschen und ersetzen';

  @override
  String get accountSuspiciousTitle => 'Elemente fehlen in Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Elemente, die dieses Gerät zuvor synchronisiert hat, fehlen in Google Drive.',
      one:
          '$count Element, das dieses Gerät zuvor synchronisiert hat, fehlt in Google Drive.',
    );
    return '$_temp0 Das kann passieren, wenn App-Daten in den Google-Einstellungen gelöscht wurden. Bisher wurde nichts gelöscht.';
  }

  @override
  String get accountSuspiciousDelete => 'Auch hier löschen';

  @override
  String get accountSuspiciousKeep =>
      'Meine Songs behalten und erneut hochladen';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente von diesem Gerät löschen?',
      one: '$count Element von diesem Gerät löschen?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Diese Songs und Setlists werden dauerhaft von diesem Gerät gelöscht. Das kann nicht rückgängig gemacht werden.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Von diesem Gerät löschen';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Elemente fehlen in Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Es wurde nichts gelöscht. Wähle, ob du sie auch hier löschen oder erneut hochladen möchtest.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive wurde während der Synchronisierung geändert.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Es ist nichts verloren gegangen. Synchronisiere erneut, um die neuesten Änderungen abzurufen.';

  @override
  String get syncErrorInvalidLocalData =>
      'Einige Daten auf diesem Gerät konnten nicht synchronisiert werden.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Ein Song oder eine Setlist konnte nicht gelesen werden. Importiere oder erstelle sie neu und synchronisiere anschließend erneut.';

  @override
  String get syncErrorNoAccountChange =>
      'Es gibt keine Kontoänderung, die behoben werden muss.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Synchronisiere erneut, um fortzufahren.';

  @override
  String get accountSyncWarningTitle =>
      'Synchronisiert, aber einige Dateien wurden übersprungen';

  @override
  String get accountSyncWarningBody =>
      'Einige Dateien konnten nicht verwendet werden und blieben unverändert. Alles andere ist auf dem neuesten Stand.';

  @override
  String get accountSyncWarningTooLarge =>
      'Eine Datei war für die Synchronisierung zu groß und wurde übersprungen. Alles andere ist auf dem neuesten Stand.';

  @override
  String get accountSyncWarningInvalid =>
      'Eine Datei konnte nicht gelesen werden und wurde übersprungen. Alles andere ist auf dem neuesten Stand.';

  @override
  String get accountNoticeSyncSkipped =>
      'Synchronisiert. Einige Dateien wurden übersprungen.';

  @override
  String get settingsExportPdfTooLarge =>
      'Diese PDF-Datei wäre zu groß. Versuche es mit weniger Songs oder teile sie als Text.';

  @override
  String get settingsTimingTooLarge =>
      'Die Timing-Daten sind zu groß (über 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'In diesem Backup ist derselbe Song zweimal enthalten. Deshalb wurde nichts importiert.';

  @override
  String get setlistSaveConflict =>
      'Die Setlist wurde an anderer Stelle geändert. Deine Änderungen wurden als separate Kopie gespeichert.';

  @override
  String get sectionVerse => 'Strophe';

  @override
  String get sectionChorus => 'Refrain';

  @override
  String get sectionBridge => 'Bridge';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pre-Chorus';

  @override
  String get sectionPostChorus => 'Post-Chorus';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Zwischenspiel';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Kehrvers';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Schluss';

  @override
  String get youtubeConsentHint =>
      'Experimentell. Wähle auf der Google-Seite deine Cookie-Einstellungen, um die Lyricsuche auszuprobieren. Eine Anmeldung bei einem Google-Konto ist nicht nötig. Deine Auswahl bleibt auf diesem Gerät.';

  @override
  String get youtubeConsentOpen => 'Google-Einwilligung prüfen';

  @override
  String get youtubeConsentSaved => 'Einwilligung gespeichert';

  @override
  String get youtubeConsentClear => 'Einwilligung löschen';

  @override
  String get youtubeConsentInstructions =>
      'Schließe deine Cookie-Auswahl ab und warte, bis YouTube Music zurückkehrt. Speichere dann diese Sitzung und suche noch einmal nach dem Song.';

  @override
  String get youtubeConsentError =>
      'Die Google-Einwilligung konnte nicht aktualisiert werden. Versuche es noch einmal.';

  @override
  String get youtubeConsentBlocked =>
      'Hier können nur YouTube Music und die Google-Seite zur Einwilligung geöffnet werden. Eine Kontoanmeldung ist nicht verfügbar.';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Verfügbare Versionen',
      one: '1 verfügbare Version',
      zero: '0 Verfügbare Versionen',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nicht verfügbare Versionen',
      one: '1 nicht verfügbare Version',
      zero: '0 Nicht verfügbare Versionen',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Zum Abschnitt springen';

  @override
  String get searchVersionDetails => 'Versionsdetails';

  @override
  String get searchSelectedRecording => 'Ausgewählte Aufnahme';

  @override
  String get searchVersionDuration => 'Dauer der Version';

  @override
  String get searchSourceOptions => 'Quelloptionen';
}
