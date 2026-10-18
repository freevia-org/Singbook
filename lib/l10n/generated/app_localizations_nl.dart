// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Een rustige plek om de nummers in je bibliotheek te vinden, te ordenen en te zingen.';

  @override
  String get aboutMadeForSinging => 'Gemaakt om samen te zingen';

  @override
  String get aboutDetails =>
      'Zoek in ingeschakelde bronnen, vergelijk versies, bewaar songteksten en akkoorden samen en orden nummers in setlijsten. Je bibliotheek wordt op dit apparaat opgeslagen; optionele synchronisatie met Google Drive gebruikt je Google-account. Zoekopdrachten gaan rechtstreeks naar ingeschakelde bronnen.';

  @override
  String get aboutSupport => 'Ondersteuning en feedback';

  @override
  String get menuTypeNewSong => 'Nieuw lied invoeren';

  @override
  String appVersion(String version) {
    return 'Versie $version';
  }

  @override
  String get navHome => 'Start';

  @override
  String get navSongs => 'Nummers';

  @override
  String get navSetlists => 'Setlijsten';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get navSettingsCompact => 'Instellingen';

  @override
  String get navSearch => 'Zoeken';

  @override
  String get navBack => 'Terug';

  @override
  String get appExitBackAgain => 'Druk nogmaals op Terug om af te sluiten';

  @override
  String get navClose => 'Sluiten';

  @override
  String get navMore => 'Meer acties';

  @override
  String get actionCancel => 'Annuleren';

  @override
  String get actionSave => 'Opslaan';

  @override
  String get actionDone => 'Klaar';

  @override
  String get actionEdit => 'Bewerken';

  @override
  String get actionDelete => 'Verwijderen';

  @override
  String get actionShare => 'Delen';

  @override
  String get actionPrint => 'Afdrukken';

  @override
  String get actionCopy => 'Kopiëren';

  @override
  String get actionClear => 'Wissen';

  @override
  String get actionRetry => 'Opnieuw proberen';

  @override
  String get actionRefresh => 'Vernieuwen';

  @override
  String get actionImport => 'Importeren';

  @override
  String get actionExport => 'Exporteren';

  @override
  String get actionExpand => 'Uitvouwen';

  @override
  String get actionCollapse => 'Invouwen';

  @override
  String get actionAdd => 'Toevoegen';

  @override
  String get actionCreate => 'Maken';

  @override
  String get actionRemove => 'Verwijderen';

  @override
  String get actionDuplicate => 'Dupliceren';

  @override
  String get actionMoveUp => 'Omhoog verplaatsen';

  @override
  String get actionMoveDown => 'Omlaag verplaatsen';

  @override
  String get actionPrevious => 'Vorige';

  @override
  String get actionNext => 'Volgende';

  @override
  String get searchHint => 'Zoek nummers, artiesten of songteksten';

  @override
  String get searchCatalogHint => 'Zoek een nummer of artiest';

  @override
  String get searchChangeSong => 'Nummer wijzigen';

  @override
  String get searchSelectedPreview => 'Geselecteerd voorbeeld';

  @override
  String get searchSubmit => 'Zoeken';

  @override
  String get searchFilters => 'Zoekopties';

  @override
  String get searchFiltersShow => 'Zoekopties tonen';

  @override
  String get searchFiltersHide => 'Zoekopties verbergen';

  @override
  String get searchFilterArtist => 'Artiest';

  @override
  String get searchFilterTitle => 'Nummertitel';

  @override
  String get searchFilterLyrics => 'Songteksten';

  @override
  String get searchFilterChords => 'Met akkoorden';

  @override
  String get searchFilterTimed => 'Gesynchroniseerde songteksten';

  @override
  String get searchFilterLanguage => 'Taal';

  @override
  String get searchFilterAll => 'Alle';

  @override
  String get searchAutocompleteLabel => 'Suggesties';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultaten',
      one: '1 resultaat',
      zero: 'Geen resultaten',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Voer een nummer, artiest of songtekst in om te zoeken.';

  @override
  String get searchCatalogEmptyQuery =>
      'Voer een nummer of artiest in om te zoeken.';

  @override
  String get searchNoResults =>
      'Geen nummers gevonden. Probeer een andere zoekopdracht.';

  @override
  String get searchLoading => 'Nummers zoeken…';

  @override
  String get searchError => 'Zoeken is niet gelukt.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Recent';

  @override
  String get searchFavoritesTab => 'Favorieten';

  @override
  String get searchSuggested => 'Voorgestelde overeenkomst';

  @override
  String get searchAlternatives => 'Andere overeenkomsten';

  @override
  String get searchCompare => 'Versies vergelijken';

  @override
  String get searchChooseVersion => 'Deze versie kiezen';

  @override
  String get searchFullPreview => 'Volledige preview';

  @override
  String get searchArrangementNotes => 'Opmerkingen over het arrangement';

  @override
  String get searchOpenLyrics => 'Songtekst openen';

  @override
  String get searchContributions => 'Gebruikte bronnen';

  @override
  String get searchVersionChecking => 'Deze versie controleren…';

  @override
  String get searchVersionUnavailable =>
      'Deze versie kan niet worden gebruikt. Kies een andere versie.';

  @override
  String get searchPreviewUnavailable =>
      'Geen preview van de songtekst beschikbaar.';

  @override
  String get searchSongMatch => 'Nummerovereenkomst';

  @override
  String get searchRecordingMatch => 'Opnameovereenkomst';

  @override
  String get searchMatchUnverified => 'Opname niet geverifieerd';

  @override
  String get searchMatchExact => 'Exacte opnameovereenkomst';

  @override
  String get searchMatchPossible => 'Mogelijke overeenkomst';

  @override
  String get searchAvailability => 'Beschikbaarheid';

  @override
  String get searchLyricsAvailable => 'Songtekst beschikbaar';

  @override
  String get searchLyricsUnavailable => 'Songtekst niet beschikbaar';

  @override
  String get searchChordsAvailable => 'Akkoorden beschikbaar';

  @override
  String get searchChordsUnavailable => 'Geen akkoorden';

  @override
  String get searchTimingAvailable => 'Timing beschikbaar';

  @override
  String get searchTimingUnavailable => 'Geen timing';

  @override
  String get searchDurationUnknown => 'Duur onbekend';

  @override
  String searchRating(String rating) {
    return 'Beoordeling $rating';
  }

  @override
  String get searchSourceLabel => 'Bron';

  @override
  String get searchMetadata => 'Nummergegevens';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Artiest';

  @override
  String get searchYear => 'Jaar';

  @override
  String get searchLanguage => 'Taal';

  @override
  String get searchViewVersions => 'Versies bekijken';

  @override
  String get searchSaved => 'Nummer opgeslagen in je bibliotheek.';

  @override
  String get searchSaveOpenLyrics => 'Tekst opslaan en openen';

  @override
  String get searchOtherResults => 'Andere resultaten';

  @override
  String get searchSaveFailed => 'Nummer opslaan is niet gelukt.';

  @override
  String get homeRecentSongs => 'Recente nummers';

  @override
  String get homeRecentlyPlayed => 'Onlangs afgespeeld';

  @override
  String get homeFavorites => 'Favorieten';

  @override
  String get homeHistory => 'Geschiedenis';

  @override
  String get homeHistoryClear => 'Geschiedenis wissen';

  @override
  String get homeHistoryCleared => 'Geschiedenis gewist.';

  @override
  String get homeHistoryEmpty => 'Nummers die je opent, verschijnen hier.';

  @override
  String get homeFavoritesEmpty =>
      'Je favoriete nummers en setlijsten verschijnen hier.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items getoond',
      one: '1 item getoond',
      zero: '0 items getoond',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Je recente nummers en setlijsten verschijnen hier.';

  @override
  String get homeTimelineLabel => 'Tijdlijn van de geschiedenis';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Volledige geschiedenis';

  @override
  String get homeShowFavorites => 'Favorieten tonen';

  @override
  String get homeShowRecent => 'Recente tonen';

  @override
  String get songsTitle => 'Nummers';

  @override
  String get songsEmpty => 'Je nummers verschijnen hier.';

  @override
  String get songsEmptySearch =>
      'Geen nummers komen overeen met je zoekopdracht.';

  @override
  String get songsAdd => 'Nummer toevoegen';

  @override
  String get songsSortAlphabetical => 'Alfabetisch sorteren';

  @override
  String get songsAlphabetNavigation => 'Nummerindex';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count keer geopend',
      one: 'Eén keer geopend',
      zero: 'Nooit geopend',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'Aan favorieten toevoegen';

  @override
  String get songFavoriteRemove => 'Uit favorieten verwijderen';

  @override
  String get songMenuLabel => 'Nummeracties';

  @override
  String get songInfo => 'Nummergegevens';

  @override
  String get setlistMenuLabel => 'Setlijstacties';

  @override
  String get songAddToSetlist => 'Aan setlijst toevoegen';

  @override
  String get songCopyChordPro => 'ChordPro kopiëren';

  @override
  String get songDeleteConfirmTitle => 'Nummer verwijderen?';

  @override
  String get songDeleteConfirmMessage =>
      'Dit nummer wordt uit je bibliotheek verwijderd.';

  @override
  String get songDeleted => 'Nummer verwijderd.';

  @override
  String get setlistsTitle => 'Setlijsten';

  @override
  String get setlistsEmpty =>
      'Maak een setlijst voor je volgende repetitie of optreden.';

  @override
  String get setlistsEmptySearch =>
      'Geen setlijsten komen overeen met je zoekopdracht.';

  @override
  String get setlistCreate => 'Nieuwe setlijst';

  @override
  String get setlistNameHint => 'Naam van setlijst';

  @override
  String get setlistNotes => 'Notities';

  @override
  String get setlistEntryOverride => 'Toonsoort en capo voor dit nummer';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nummers',
      one: '1 nummer',
      zero: 'Geen nummers',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Ten minste $duration';
  }

  @override
  String get setlistDurationUnknown => 'Duur onbekend';

  @override
  String setlistActivity(String date) {
    return 'Laatste activiteit $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Gemaakt op $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Bewerkt op $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Laatst afgespeeld op $date';
  }

  @override
  String get setlistSongsEmpty => 'Deze setlijst bevat nog geen nummers.';

  @override
  String get setlistAddSongs => 'Nummers toevoegen';

  @override
  String get setlistReorder => 'Nummers opnieuw ordenen';

  @override
  String setlistMoveSongUp(String song) {
    return '$song omhoog verplaatsen';
  }

  @override
  String setlistMoveSongDown(String song) {
    return '$song omlaag verplaatsen';
  }

  @override
  String setlistRemoveSong(String song) {
    return '$song uit de setlijst verwijderen';
  }

  @override
  String get setlistDuplicate => 'Setlijst dupliceren';

  @override
  String get setlistFavoriteAdd => 'Setlijst aan favorieten toevoegen';

  @override
  String get setlistFavoriteRemove => 'Setlijst uit favorieten verwijderen';

  @override
  String get setlistShare => 'Delen als setlijstbestand';

  @override
  String get setlistSharePdf => 'Delen als PDF';

  @override
  String get setlistPrint => 'Afdrukken';

  @override
  String get setlistDeleteConfirmTitle => 'Setlijst verwijderen?';

  @override
  String get setlistDeleteConfirmMessage =>
      'De setlijst wordt verwijderd. Nummers in je bibliotheek blijven behouden.';

  @override
  String get setlistDeleted => 'Setlijst verwijderd.';

  @override
  String get readerTitle => 'Songteksten';

  @override
  String get readerNoLyrics => 'Er zijn nog geen songteksten toegevoegd.';

  @override
  String get readerShowChords => 'Akkoorden tonen';

  @override
  String get readerHideChords => 'Akkoorden verbergen';

  @override
  String get readerTranspose => 'Akkoorden transponeren';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count halve tonen',
      one: '1 halve toon',
      zero: '0 halve tonen',
    );
    return 'Transponeren met $_temp0';
  }

  @override
  String get readerSaved => 'Opgeslagen';

  @override
  String get readerEdit => 'Songteksten en gegevens bewerken';

  @override
  String get playerPlay => 'Afspelen';

  @override
  String get playerPause => 'Pauzeren';

  @override
  String get playerResume => 'Automatisch scrollen hervatten';

  @override
  String get playerSeek => 'Afspeelpositie';

  @override
  String playerElapsed(String time) {
    return 'Verstreken tijd $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Resterende tijd $time';
  }

  @override
  String get playerTimingMode => 'Scrollmodus';

  @override
  String get playerTimedLyrics => 'Gesynchroniseerde songteksten';

  @override
  String get playerStartScroll => 'Automatisch scrollen starten';

  @override
  String get playerEstimatedPace => 'Geschatte snelheid';

  @override
  String get playerScrollSpeed => 'Scrollsnelheid';

  @override
  String playerEstimatedDuration(String time) {
    return 'Geschatte duur: $time';
  }

  @override
  String get playerLyricsOnly => 'Songtekst scrollen · geen audio';

  @override
  String get playerManualScroll => 'Handmatig scrollen';

  @override
  String get playerTimingStatusReady =>
      'De songteksten volgen de beschikbare timing.';

  @override
  String get playerTimingStatusEstimated =>
      'De scrollsnelheid wordt geschat op basis van de duur van het nummer.';

  @override
  String get playerTimingStatusManual => 'Scroll zelf door de songteksten.';

  @override
  String get playerTimingStatusUnavailable =>
      'Gesynchroniseerd scrollen is niet beschikbaar voor dit nummer.';

  @override
  String get playerDurationUnknown =>
      'Voeg de duur van het nummer toe om scrollen op basis van een schatting te gebruiken.';

  @override
  String get playerProgressLabel => 'Voortgang van nummer';

  @override
  String get playerCurrentSection => 'Huidig deel';

  @override
  String get playerPreviousSection => 'Vorig deel';

  @override
  String get playerNextSection => 'Volgend deel';

  @override
  String get playerPreviousSectionSong =>
      'Vorig deel · houd ingedrukt voor het vorige nummer in de setlijst';

  @override
  String get playerNextSectionSong =>
      'Volgend deel · houd ingedrukt voor het volgende nummer in de setlijst';

  @override
  String get playerPreviousSong => 'Vorig nummer';

  @override
  String get playerNextSong => 'Volgend nummer';

  @override
  String get editorTitle => 'Nummer bewerken';

  @override
  String get editorTitleField => 'Nummertitel';

  @override
  String get editorArtistField => 'Artiest';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Songtekst';

  @override
  String get editorChordsField => 'Akkoorden';

  @override
  String get editorKeyField => 'Toonsoort';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Stemming';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Duur';

  @override
  String get editorTimeSignatureField => 'Maatsoort';

  @override
  String get editorLanguageField => 'Taal';

  @override
  String get editorYearField => 'Jaar';

  @override
  String get editorComposerField => 'Componist';

  @override
  String get editorLyricistField => 'Tekstschrijver';

  @override
  String get editorCopyrightField => 'Auteursrecht';

  @override
  String get editorLicenseField => 'Licentie';

  @override
  String get songInfoSources => 'Bronnen en credits';

  @override
  String get searchMatchSameSong => 'Hetzelfde nummer; opname niet bevestigd';

  @override
  String get searchMatchNeedsAgreement =>
      'De songtekst moet met het akkoordenschema worden bevestigd';

  @override
  String get searchMatchDifferentLyrics =>
      'De songtekst verschilt van die van het geselecteerde nummer';

  @override
  String get searchMatchCombinedSources =>
      'Gegevens gecombineerd uit meerdere bronnen';

  @override
  String get searchCombinedLabel => 'Gecombineerd';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nummerovereenkomsten',
      one: '1 nummerovereenkomst',
      zero: '0 nummerovereenkomsten',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bronversies',
      one: '1 bronversie',
      zero: '0 bronversies',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Beste beschikbare overeenkomst';

  @override
  String get providerDescriptionUnknown => 'Muziekbron';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Download een ChordPro-bestand van de bron en importeer het daarna.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Download het bestand met een gratis account en importeer het daarna.';

  @override
  String get providerDescPublicChordSheets => 'Openbare akkoordenschema\'s.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Historische songteksten met een licentie per werk.';

  @override
  String get providerDescLicensedCatalog =>
      'Catalogus met gelicentieerde songteksten.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Originele nummers onder Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Songteksten met een licentie per nummer.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Alleen opname- en releasegegevens.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Alleen compositiegegevens.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Albumhoezen alleen voor exacte opnameovereenkomsten.';

  @override
  String get providerCapabilityLyrics => 'Songteksten';

  @override
  String get providerCapabilityChords => 'Akkoorden';

  @override
  String get providerCapabilityTiming => 'Gesynchroniseerde songteksten';

  @override
  String get providerCapabilitySearch => 'Zoeken';

  @override
  String get providerCapabilityMetadata => 'Nummergegevens';

  @override
  String get editorArtworkField => 'Link naar albumhoes';

  @override
  String get editorLyricsHint =>
      'Akkoorden tussen [C]-haken; sectiemarkeringen op aparte regels.';

  @override
  String get editorSave => 'Wijzigingen opslaan';

  @override
  String get editorSaved => 'Wijzigingen opgeslagen.';

  @override
  String get editorSaveFailed => 'Wijzigingen opslaan is niet gelukt.';

  @override
  String get editorSaveConflict =>
      'Het nummer is ergens anders gewijzigd. Je wijzigingen zijn als aparte kopie opgeslagen.';

  @override
  String get editorUnsavedTitle => 'Wijzigingen verwerpen?';

  @override
  String get editorUnsavedMessage => 'Je wijzigingen zijn niet opgeslagen.';

  @override
  String get editorFieldRequired => 'Voer een nummertitel in.';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsAppearance => 'Weergave';

  @override
  String get settingsTheme => 'Thema';

  @override
  String get settingsThemeSystem => 'Apparaatinstelling gebruiken';

  @override
  String get settingsThemeLight => 'Licht';

  @override
  String get settingsThemeDark => 'Donker';

  @override
  String get settingsColorPalette => 'Kleurenpalet';

  @override
  String get settingsFont => 'Lettertype';

  @override
  String get settingsTextSize => 'Tekstgrootte';

  @override
  String get settingsLyricsPreview => 'Voorbeeld van songteksten';

  @override
  String get settingsPlayer => 'Songtekstspeler';

  @override
  String get settingsDefaultShowChords => 'Akkoorden standaard tonen';

  @override
  String get settingsDefaultAutoscroll =>
      'Songteksten automatisch laten scrollen';

  @override
  String get settingsDefaultTiming => 'Standaard scrollmodus';

  @override
  String get settingsLanguage => 'App-taal';

  @override
  String get settingsLanguageSystem => 'Apparaattaal gebruiken';

  @override
  String get settingsLanguageEnglish => 'Engels';

  @override
  String get settingsLanguageBulgarian => 'Bulgaars';

  @override
  String get settingsLanguageUkrainian => 'Oekraïens';

  @override
  String get settingsSources => 'Songtekstbronnen';

  @override
  String settingsSourceEnabled(String source) {
    return 'Bron $source inschakelen';
  }

  @override
  String get settingsSourceRefresh => 'Bronnenlijst vernieuwen';

  @override
  String get settingsSourcesUpdated => 'Bronnen bijgewerkt.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Bronnen vernieuwen is niet gelukt.';

  @override
  String get settingsImport => 'Nummers importeren';

  @override
  String get settingsImportChordPro => 'ChordPro-bestand importeren';

  @override
  String get settingsImportSetlist => 'Setlijstbestand importeren';

  @override
  String get settingsImportSuccess => 'Importeren voltooid.';

  @override
  String get settingsImportFailed =>
      'Dit bestand kon niet worden geïmporteerd.';

  @override
  String get settingsImportUnsupported =>
      'Dit bestandstype wordt niet ondersteund.';

  @override
  String get settingsShareSong => 'Delen als ChordPro';

  @override
  String get settingsSharePdf => 'Delen als PDF';

  @override
  String get settingsCopySong => 'Naar klembord kopiëren';

  @override
  String get settingsPrintSong => 'Alleen nummer afdrukken';

  @override
  String get settingsPrintSetlist => 'Setlijst met songteksten afdrukken';

  @override
  String get settingsExportFailed => 'Bestand voorbereiden is niet gelukt.';

  @override
  String get settingsCopied => 'Gekopieerd naar klembord.';

  @override
  String get settingsAbout => 'Over';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsLegal => 'Juridisch';

  @override
  String get settingsClearHistory => 'Geschiedenis wissen';

  @override
  String get settingsClearHistoryConfirm =>
      'De geschiedenis van je nummers en setlijsten wissen?';

  @override
  String get settingsHistoryCleared => 'Geschiedenis gewist.';

  @override
  String get accountTitle => 'Account en synchronisatie';

  @override
  String get accountUnavailable =>
      'Voor synchronisatie is een versie van Singbook nodig waarin Google-aanmelding is ingesteld. In deze versie blijven je nummers alleen op dit apparaat.';

  @override
  String get accountSyncNow => 'Nu synchroniseren';

  @override
  String get accountConnected =>
      'Verbonden. Kies ‘Nu synchroniseren’ om je back-up bij te werken.';

  @override
  String get accountSignIn => 'Account koppelen';

  @override
  String get accountSignOut => 'Afmelden';

  @override
  String get accountChange => 'Account wijzigen';

  @override
  String get accountSignedOut => 'Niet verbonden';

  @override
  String get accountSyncing => 'Je bibliotheek synchroniseren…';

  @override
  String get accountSynced => 'Bibliotheek gesynchroniseerd.';

  @override
  String get accountSyncFailed =>
      'Je bibliotheek synchroniseren is niet gelukt.';

  @override
  String get accessibilityFavorite => 'Favoriet';

  @override
  String get accessibilityNotFavorite => 'Geen favoriet';

  @override
  String get accessibilitySearchField => 'Nummers zoeken';

  @override
  String get accessibilityClearSearch => 'Zoektekst wissen';

  @override
  String accessibilitySongMenu(String song) {
    return 'Acties voor $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Acties voor $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Nummers in $setlist uitvouwen';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Nummers in $setlist invouwen';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Afspeelvoortgang, $percent procent';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Tijdlijn van de geschiedenis, $date';
  }

  @override
  String get loading => 'Laden…';

  @override
  String get loadingSongs => 'Nummers laden…';

  @override
  String get loadingSetlists => 'Setlijsten laden…';

  @override
  String get errorGeneric => 'Er is iets misgegaan.';

  @override
  String get errorOffline => 'Je lijkt offline te zijn.';

  @override
  String get errorPermission => 'Er is toestemming nodig om door te gaan.';

  @override
  String get emptyFiltered => 'Geen items komen overeen met deze filters.';

  @override
  String get unknownValue => 'Onbekend';

  @override
  String get durationUnknown => 'Duur onbekend';

  @override
  String get metadataNotSet => 'Niet ingesteld';

  @override
  String get dateToday => 'Vandaag';

  @override
  String get dateYesterday => 'Gisteren';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nummers',
      one: '1 nummer',
      zero: 'Geen nummers',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Marineblauw';

  @override
  String get settingsPaletteSage => 'Saliegroen';

  @override
  String get settingsPaletteOcean => 'Oceaan';

  @override
  String get settingsPaletteClay => 'Klei';

  @override
  String get settingsPalettePlum => 'Pruim';

  @override
  String get settingsFontSystem => 'Systeem';

  @override
  String get settingsFontSerif => 'Met schreef';

  @override
  String get settingsFontMonospace => 'Monospace';

  @override
  String get settingsLyricsPreviewExample =>
      'Wanneer de ochtend komt, zingen we opnieuw.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Songtekstbronnen controleren: $checked van $total voltooid.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Geen bruikbare songteksten gevonden.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Het geselecteerde nummer is gecontroleerd bij de ingeschakelde bronnen, maar geen daarvan leverde een bruikbare versie van de songtekst.';

  @override
  String get searchDiscoveryError =>
      'Songtekstbronnen konden niet worden gecontroleerd.';

  @override
  String get searchDiscoveryRetry => 'Songteksten opnieuw zoeken';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bronnen niet beschikbaar',
      one: '1 bron niet beschikbaar',
      zero: '0 bronnen niet beschikbaar',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails =>
      'Controleer je verbinding en probeer het opnieuw.';

  @override
  String get searchProviderChecks => 'Broncontroles';

  @override
  String get searchProviderPending => 'Controleren';

  @override
  String get searchProviderFound => 'Overeenkomst gevonden';

  @override
  String get searchProviderRejected => 'Komt niet overeen';

  @override
  String get searchProviderFailed => 'Controle mislukt';

  @override
  String get searchProviderUnavailable => 'Geen bruikbare songteksten';

  @override
  String get searchCatalogFilterHint =>
      'Selecteer een nummer om songtekstversies te filteren op akkoorden, timing of taal.';

  @override
  String get startupErrorTitle => 'Je bibliotheek kon niet worden geopend.';

  @override
  String setlistCopyName(String name) {
    return 'Kopie van $name';
  }

  @override
  String get setlistSongMissing => 'Nummer ontbreekt';

  @override
  String get settingsImportTooLarge =>
      'Dit bestand is te groot om te importeren.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Ga naar $letter';
  }

  @override
  String get actionDiscard => 'Verwerpen';

  @override
  String get editorKeepEditing => 'Doorgaan met bewerken';

  @override
  String get settingsDefaultShowChordsHint =>
      'Akkoorden boven de songtekst tonen als een nummer akkoorden heeft.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'De songteksten scrollen mee met het nummer. Dit wordt niet gebruikt in de modus voor handmatig scrollen.';

  @override
  String get accountUnavailableTitle => 'Synchronisatie niet ingesteld';

  @override
  String get accountSignedOutBenefits =>
      'Als je Google Drive koppelt, wordt je bibliotheek gesynchroniseerd. Wijzigingen in nummers worden daarna automatisch gesynchroniseerd.';

  @override
  String get accountManualSyncHint =>
      'Je kunt ook op Nu synchroniseren tikken om je bibliotheek te synchroniseren.';

  @override
  String get accountSignInWithGoogle => 'Aanmelden met Google';

  @override
  String get accountWorking => 'Bezig…';

  @override
  String get accountNeverSynced => 'Nog nooit gesynchroniseerd';

  @override
  String get accountSyncedJustNow => 'Zojuist gesynchroniseerd';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuten geleden gesynchroniseerd',
      one: '1 minuut geleden gesynchroniseerd',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur geleden gesynchroniseerd',
      one: '1 uur geleden gesynchroniseerd',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden gesynchroniseerd',
      one: '1 dag geleden gesynchroniseerd',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflicterende wijzigingen als kopieën bewaard',
      one: '1 conflicterende wijziging als kopie bewaard',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Hetzelfde nummer of dezelfde setlijst is op twee plekken bewerkt. Er is niets verloren gegaan: de andere versie is als aparte kopie opgeslagen.';

  @override
  String get accountReviewConflicts => 'Kopieën controleren';

  @override
  String get songsConflictFilterActive =>
      'Alleen conflictkopieën worden getoond';

  @override
  String get songsConflictFilterClear => 'Alle nummers tonen';

  @override
  String get songsConflictBadge => 'Conflictkopie';

  @override
  String get songsConflictEmpty => 'Geen conflictkopieën.';

  @override
  String get accountAutoSync => 'Automatisch synchroniseren';

  @override
  String get accountAutoSyncHint =>
      'Synchroniseer na het koppelen en na het toevoegen, bewerken of verwijderen van een nummer.';

  @override
  String get accountSignOutTitle => 'Afmelden bij dit account?';

  @override
  String get accountSignOutBody =>
      'Je nummers en setlijsten blijven op dit apparaat. Ze worden pas weer geback-upt of gesynchroniseerd nadat je je opnieuw hebt aangemeld.';

  @override
  String get accountUseDifferent => 'Ander account gebruiken';

  @override
  String get accountSignInAgain => 'Opnieuw aanmelden';

  @override
  String get accountChooseAction => 'Kies hoe je verder wilt gaan';

  @override
  String get accountChangedTitle => 'Ander Google-account';

  @override
  String get accountChangedBody =>
      'Dit apparaat is voor het laatst gesynchroniseerd met een ander Google-account. Kies wat er met de nummers en setlijsten op dit apparaat moet gebeuren.';

  @override
  String get accountChangedMerge => 'Samenvoegen met het nieuwe account';

  @override
  String get accountChangedMergeHint =>
      'Bewaar alles op dit apparaat en voeg het toe aan het nieuwe account.';

  @override
  String get accountChangedReplace =>
      'Vervangen door de bibliotheek van het nieuwe account';

  @override
  String get accountChangedReplaceHint =>
      'Nummers op dit apparaat die niet in het nieuwe account staan, worden verwijderd.';

  @override
  String get accountChangedSignOut => 'Annuleren en afmelden';

  @override
  String get accountStatusSignedOut =>
      'Account en synchronisatie: niet aangemeld';

  @override
  String get accountStatusSignedIn => 'Account en synchronisatie: aangemeld';

  @override
  String get accountStatusSyncing =>
      'Account en synchronisatie: synchroniseren';

  @override
  String get accountStatusSynced =>
      'Account en synchronisatie: bibliotheek bijgewerkt';

  @override
  String get accountStatusError =>
      'Account en synchronisatie: probleem, tik om te bekijken';

  @override
  String get accountNoticeConflicts =>
      'Sommige nummers zijn op twee plekken bewerkt. Kopieën zijn bewaard.';

  @override
  String get accountNoticeSignedIn => 'Aangemeld.';

  @override
  String get accountNoticeSignedOut =>
      'Afgemeld. Je nummers blijven op dit apparaat.';

  @override
  String get syncErrorNotConfigured =>
      'Synchronisatie is in deze versie niet ingesteld.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Gebruik een versie van Singbook waarin Google-aanmelding is ingesteld.';

  @override
  String get syncErrorNotSignedIn => 'Je bent niet aangemeld.';

  @override
  String get syncErrorNotSignedInHint =>
      'Meld je aan om je bibliotheek te synchroniseren.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google vraagt je om je opnieuw aan te melden.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Meld je opnieuw aan om verder te synchroniseren. Je nummers zijn veilig op dit apparaat.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook heeft geen toestemming om Google Drive te gebruiken.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Meld je opnieuw aan en geef toegang tot Drive wanneer daarom wordt gevraagd.';

  @override
  String get syncErrorRateLimited =>
      'Google beperkt momenteel het aantal verzoeken.';

  @override
  String get syncErrorRateLimitedHint =>
      'Wacht een paar minuten en probeer het opnieuw.';

  @override
  String get syncErrorStorageFull => 'Je Google Drive is vol.';

  @override
  String get syncErrorStorageFullHint =>
      'Maak ruimte vrij in Drive en probeer het opnieuw.';

  @override
  String get syncErrorNetwork => 'Google kon niet worden bereikt.';

  @override
  String get syncErrorNetworkHint =>
      'Controleer je internetverbinding en probeer het opnieuw.';

  @override
  String get syncErrorAccountChanged =>
      'Er is een ander Google-account gebruikt.';

  @override
  String get syncErrorAccountChangedHint =>
      'Kies of je de bibliotheek op dit apparaat wilt samenvoegen met die van dit account of wilt vervangen.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Je gesynchroniseerde bibliotheek is groter dan Singbook aankan.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Verwijder nummers of setlijsten uit de gesynchroniseerde bibliotheek en probeer het opnieuw.';

  @override
  String get syncErrorSignInFailed => 'Aanmelden is niet voltooid.';

  @override
  String get syncErrorSignInFailedHint => 'Probeer je opnieuw aan te melden.';

  @override
  String get syncErrorGeneric =>
      'Je bibliotheek synchroniseren is niet gelukt.';

  @override
  String get syncErrorGenericHint =>
      'Probeer het zo nog eens. Je nummers zijn nog steeds veilig op dit apparaat.';

  @override
  String get editorDurationInvalid =>
      'Voer seconden in, of minuten en seconden, bijvoorbeeld 3:45.';

  @override
  String get editorNumberInvalid => 'Voer een getal in.';

  @override
  String get accountReplaceConfirmTitle => 'Lokale nummers verwijderen?';

  @override
  String get accountReplaceConfirmBody =>
      'Nummers en setlijsten op dit apparaat die niet in het nieuwe account staan, worden definitief verwijderd. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get accountReplaceConfirmAction => 'Verwijderen en vervangen';

  @override
  String get accountSuspiciousTitle => 'Items ontbreken op Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items die dit apparaat eerder heeft gesynchroniseerd, ontbreken op Google Drive.',
      one:
          '$count item dat dit apparaat eerder heeft gesynchroniseerd, ontbreekt op Google Drive.',
    );
    return '$_temp0 Dit kan gebeuren als appgegevens zijn gewist in de Google-instellingen. Er is nog niets verwijderd.';
  }

  @override
  String get accountSuspiciousDelete => 'Verwijder ze hier ook';

  @override
  String get accountSuspiciousKeep =>
      'Bewaar mijn nummers en upload ze opnieuw';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items van dit apparaat verwijderen?',
      one: '$count item van dit apparaat verwijderen?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Deze nummers en setlijsten worden definitief van dit apparaat verwijderd. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Verwijderen van dit apparaat';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Items ontbreken op Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Er is niets verwijderd. Kies of je ze hier ook wilt verwijderen of opnieuw wilt uploaden.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive is gewijzigd tijdens het synchroniseren.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Er is niets verloren gegaan. Synchroniseer opnieuw om de nieuwste wijzigingen op te halen.';

  @override
  String get syncErrorInvalidLocalData =>
      'Sommige gegevens op dit apparaat konden niet worden gesynchroniseerd.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Een nummer of setlijst kon niet worden gelezen. Importeer of maak het opnieuw en synchroniseer daarna opnieuw.';

  @override
  String get syncErrorNoAccountChange =>
      'Er is geen accountwijziging om op te lossen.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Synchroniseer opnieuw om door te gaan.';

  @override
  String get accountSyncWarningTitle =>
      'Gesynchroniseerd, maar sommige bestanden zijn overgeslagen';

  @override
  String get accountSyncWarningBody =>
      'Sommige bestanden konden niet worden gebruikt en zijn ongewijzigd gelaten. De rest is bijgewerkt.';

  @override
  String get accountSyncWarningTooLarge =>
      'Een bestand was te groot om te synchroniseren en is overgeslagen. De rest is bijgewerkt.';

  @override
  String get accountSyncWarningInvalid =>
      'Een bestand kon niet worden gelezen en is overgeslagen. De rest is bijgewerkt.';

  @override
  String get accountNoticeSyncSkipped =>
      'Gesynchroniseerd. Sommige bestanden zijn overgeslagen.';

  @override
  String get settingsExportPdfTooLarge =>
      'Deze PDF zou te groot worden. Probeer minder nummers of deel het als tekst.';

  @override
  String get settingsTimingTooLarge =>
      'De timinggegevens zijn te groot (meer dan 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Deze back-up bevat hetzelfde nummer twee keer. Er is niets geïmporteerd.';

  @override
  String get setlistSaveConflict =>
      'De setlijst is elders gewijzigd. Je bewerkingen zijn opgeslagen als een aparte kopie.';

  @override
  String get sectionVerse => 'Couplet';

  @override
  String get sectionChorus => 'Refrein';

  @override
  String get sectionBridge => 'Brug';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pre-refrein';

  @override
  String get sectionPostChorus => 'Post-refrein';

  @override
  String get sectionInstrumental => 'Instrumentaal';

  @override
  String get sectionInterlude => 'Interlude';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Herhaling';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Slot';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Beschikbare versies',
      one: '1 beschikbare versie',
      zero: '0 Beschikbare versies',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Niet-beschikbare versies',
      one: '1 niet-beschikbare versie',
      zero: '0 Niet-beschikbare versies',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Ga naar sectie';

  @override
  String get searchVersionDetails => 'Versiedetails';

  @override
  String get searchSelectedRecording => 'Geselecteerde opname';

  @override
  String get searchVersionDuration => 'Versieduur';

  @override
  String get searchSourceOptions => 'Bronopties';

  @override
  String get actionUndo => 'Ongedaan maken';

  @override
  String setlistEntryRemoved(String song) {
    return '$song is uit de setlist verwijderd';
  }

  @override
  String get backupTitle => 'Back-up en herstel';

  @override
  String get backupExport => 'Back-up exporteren';

  @override
  String get backupRestore => 'Back-up herstellen';

  @override
  String get backupIncludePreferences => 'App-voorkeuren opnemen';

  @override
  String get backupRestorePreferences => 'App-voorkeuren herstellen';

  @override
  String get backupMerge => 'Toevoegen aan deze bibliotheek';

  @override
  String get backupMergeHint =>
      'Behoud lokale wijzigingen en voeg nummers en setlists uit deze back-up toe.';

  @override
  String get backupReplace => 'Deze bibliotheek vervangen';

  @override
  String get backupReplaceHint =>
      'Vervang alle nummers en setlists op dit apparaat door deze back-up.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Nummers: $songs · Setlists: $setlists · Conflicten: $conflicts';
  }

  @override
  String get backupFailed =>
      'Deze back-upbewerking is niet voltooid. Probeer het opnieuw.';

  @override
  String get backupRestored => 'Back-up hersteld.';

  @override
  String get backupLocalHint =>
      'Sla een kopie van je bibliotheek op. Accountgegevens en toestemmingscookies worden nooit opgenomen.';

  @override
  String get backupReplaceConfirm =>
      'De huidige bibliotheek vervangen? Dit kan niet ongedaan worden gemaakt.';

  @override
  String get searchCheckOperations => 'Bewerkingen';

  @override
  String get searchCheckCode => 'Resultaatcode';

  @override
  String get searchCheckQueued => 'Wachten op controle van deze bron.';

  @override
  String get searchCheckFetch => 'Songtekst laden';

  @override
  String get searchCheckValidate => 'Nummerovereenkomst controleren';

  @override
  String get searchCheckCorroborate => 'Tekstovereenkomst controleren';

  @override
  String get searchCheckCompleted => 'Voltooid';

  @override
  String get searchCheckTimeout => 'De bron reageerde niet op tijd.';

  @override
  String get searchCheckBlocked => 'De bron heeft het verzoek geblokkeerd.';

  @override
  String get searchCheckRateLimited =>
      'De bron beperkt verzoeken. Probeer het later opnieuw.';

  @override
  String get searchCheckNetwork =>
      'Kan de bron niet bereiken. Controleer je verbinding.';

  @override
  String get searchCheckInvalid => 'De bron gaf een onleesbaar antwoord terug.';

  @override
  String get searchCheckNotConfigured =>
      'Deze bron is niet ingesteld in deze build.';

  @override
  String get searchCheckNoLyrics =>
      'Er is geen overeenkomende songtekst gevonden.';

  @override
  String get searchCheckFailed => 'Deze bewerking kon niet worden voltooid.';

  @override
  String get searchCheckNoHistory =>
      'Er zijn geen broncontroles uitgevoerd voor deze vergelijking.';

  @override
  String get searchVersionCredits => 'Credits';

  @override
  String get searchVersionMediaLinks => 'Gerelateerde links';

  @override
  String get searchCheckCancelled => 'Geannuleerd';

  @override
  String get searchCheckAmbiguous =>
      'Er zijn meerdere overeenkomsten gevonden. Deze bron heeft een specifiekere opname nodig.';

  @override
  String get searchCheckIdentity =>
      'Deze bron heeft een opname- of werkidentificatie nodig.';

  @override
  String get searchCheckExtraction =>
      'De bron reageerde, maar de songtekst kon niet worden opgehaald.';

  @override
  String get searchCheckBusy =>
      'Deze bron is bezig. Probeer het later opnieuw.';

  @override
  String get searchCheckSelection =>
      'Kies een specifiek resultaat van deze bron.';

  @override
  String get playerChordsNone => 'Geen';

  @override
  String get editorCustomValue => 'Anders…';

  @override
  String get editorStandardTuning => 'Standaardstemming';

  @override
  String get editorExampleVerse =>
      '[C]Een nieuwe dag [G]roept,\n[Am]we volgen het licht terug naar [F]huis.';

  @override
  String get editorExampleChorus =>
      '[F]Zing dit lied [C]samen,\n[G]laat de melodie ons [C]verder dragen.';

  @override
  String get editorExampleBridge =>
      '[Am]Nog een regel, een beetje [F]dichterbij.';
}
