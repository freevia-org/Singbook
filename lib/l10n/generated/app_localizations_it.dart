// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Uno spazio tranquillo per trovare, organizzare e cantare con la tua raccolta di brani.';

  @override
  String get aboutMadeForSinging => 'Pensata per cantare insieme';

  @override
  String appVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navSongs => 'Brani';

  @override
  String get navSetlists => 'Scalette';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get navSettingsCompact => 'Impostazioni';

  @override
  String get navSearch => 'Cerca';

  @override
  String get navBack => 'Indietro';

  @override
  String get navClose => 'Chiudi';

  @override
  String get navMore => 'Altre azioni';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionSave => 'Salva';

  @override
  String get actionDone => 'Fatto';

  @override
  String get actionEdit => 'Modifica';

  @override
  String get actionDelete => 'Elimina';

  @override
  String get actionShare => 'Condividi';

  @override
  String get actionPrint => 'Stampa';

  @override
  String get actionCopy => 'Copia';

  @override
  String get actionClear => 'Cancella';

  @override
  String get actionRetry => 'Riprova';

  @override
  String get actionRefresh => 'Aggiorna';

  @override
  String get actionImport => 'Importa';

  @override
  String get actionExport => 'Esporta';

  @override
  String get actionExpand => 'Espandi';

  @override
  String get actionCollapse => 'Comprimi';

  @override
  String get actionAdd => 'Aggiungi';

  @override
  String get actionCreate => 'Crea';

  @override
  String get actionRemove => 'Rimuovi';

  @override
  String get actionDuplicate => 'Duplica';

  @override
  String get actionMoveUp => 'Sposta in alto';

  @override
  String get actionMoveDown => 'Sposta in basso';

  @override
  String get actionPrevious => 'Precedente';

  @override
  String get actionNext => 'Successivo';

  @override
  String get searchHint => 'Cerca brani, artisti o testi';

  @override
  String get searchCatalogHint => 'Cerca un brano o un artista';

  @override
  String get searchChangeSong => 'Cambia canzone';

  @override
  String get searchSelectedPreview => 'Anteprima selezionata';

  @override
  String get searchSubmit => 'Cerca';

  @override
  String get searchFilters => 'Opzioni di ricerca';

  @override
  String get searchFiltersShow => 'Mostra le opzioni di ricerca';

  @override
  String get searchFiltersHide => 'Nascondi le opzioni di ricerca';

  @override
  String get searchFilterArtist => 'Artista';

  @override
  String get searchFilterTitle => 'Titolo del brano';

  @override
  String get searchFilterLyrics => 'Testi';

  @override
  String get searchFilterChords => 'Con accordi';

  @override
  String get searchFilterTimed => 'Testi sincronizzati';

  @override
  String get searchFilterLanguage => 'Lingua';

  @override
  String get searchFilterAll => 'Qualsiasi';

  @override
  String get searchAutocompleteLabel => 'Suggerimenti';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '1 risultato',
      zero: 'Nessun risultato',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Inserisci un brano, un artista o un testo da cercare.';

  @override
  String get searchCatalogEmptyQuery =>
      'Inserisci un brano o un artista da cercare.';

  @override
  String get searchNoResults =>
      'Nessun brano trovato. Prova un\'altra ricerca.';

  @override
  String get searchLoading => 'Ricerca dei brani…';

  @override
  String get searchError => 'Impossibile completare la ricerca.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Recenti';

  @override
  String get searchFavoritesTab => 'Preferiti';

  @override
  String get searchSuggested => 'Corrispondenza suggerita';

  @override
  String get searchAlternatives => 'Altre corrispondenze';

  @override
  String get searchCompare => 'Confronta versioni';

  @override
  String get searchChooseVersion => 'Scegli questa versione';

  @override
  String get searchSongMatch => 'Corrispondenza del brano';

  @override
  String get searchRecordingMatch => 'Corrispondenza della registrazione';

  @override
  String get searchMatchUnverified => 'Registrazione non verificata';

  @override
  String get searchMatchExact => 'Corrispondenza esatta della registrazione';

  @override
  String get searchMatchPossible => 'Possibile corrispondenza';

  @override
  String get searchAvailability => 'Disponibilità';

  @override
  String get searchLyricsAvailable => 'Testo disponibile';

  @override
  String get searchLyricsUnavailable => 'Testo non disponibile';

  @override
  String get searchChordsAvailable => 'Accordi disponibili';

  @override
  String get searchChordsUnavailable => 'Nessun accordo';

  @override
  String get searchTimingAvailable => 'Sincronizzazione disponibile';

  @override
  String get searchTimingUnavailable => 'Nessuna sincronizzazione';

  @override
  String get searchDurationUnknown => 'Durata sconosciuta';

  @override
  String searchRating(String rating) {
    return 'Valutazione $rating';
  }

  @override
  String get searchSourceLabel => 'Fonte';

  @override
  String get searchMetadata => 'Dettagli del brano';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Artista';

  @override
  String get searchYear => 'Anno';

  @override
  String get searchLanguage => 'Lingua';

  @override
  String get searchViewVersions => 'Vedi versioni';

  @override
  String get searchSaved => 'Brano salvato nella tua raccolta.';

  @override
  String get searchSaveOpenLyrics => 'Salva e apri il testo';

  @override
  String get searchOtherResults => 'Altri risultati';

  @override
  String get searchSaveFailed => 'Impossibile salvare il brano.';

  @override
  String get homeRecentSongs => 'Brani recenti';

  @override
  String get homeRecentlyPlayed => 'Riprodotti di recente';

  @override
  String get homeFavorites => 'Preferiti';

  @override
  String get homeHistory => 'Cronologia';

  @override
  String get homeHistoryClear => 'Cancella cronologia';

  @override
  String get homeHistoryCleared => 'Cronologia cancellata.';

  @override
  String get homeHistoryEmpty => 'Qui compariranno i brani che apri.';

  @override
  String get homeFavoritesEmpty =>
      'Qui compariranno i tuoi brani e le tue scalette preferite.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi mostrati',
      one: '1 elemento mostrato',
      zero: '0 elementi mostrati',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Qui compariranno i tuoi brani e le tue scalette recenti.';

  @override
  String get homeTimelineLabel => 'Cronologia delle attività';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Tutta la cronologia';

  @override
  String get homeShowFavorites => 'Mostra i preferiti';

  @override
  String get homeShowRecent => 'Mostra i recenti';

  @override
  String get songsTitle => 'Brani';

  @override
  String get songsEmpty => 'Qui compariranno i tuoi brani.';

  @override
  String get songsEmptySearch => 'Nessun brano corrisponde alla ricerca.';

  @override
  String get songsAdd => 'Aggiungi brano';

  @override
  String get songsSortAlphabetical => 'Ordina alfabeticamente';

  @override
  String get songsAlphabetNavigation => 'Indice dei brani';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volte',
      one: 'una volta',
      zero: 'mai',
    );
    return 'Aperto $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Aggiungi ai preferiti';

  @override
  String get songFavoriteRemove => 'Rimuovi dai preferiti';

  @override
  String get songMenuLabel => 'Azioni del brano';

  @override
  String get songInfo => 'Dettagli del brano';

  @override
  String get setlistMenuLabel => 'Azioni della scaletta';

  @override
  String get songAddToSetlist => 'Aggiungi alla scaletta';

  @override
  String get songCopyChordPro => 'Copia ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Eliminare il brano?';

  @override
  String get songDeleteConfirmMessage =>
      'Il brano verrà rimosso dalla tua raccolta.';

  @override
  String get songDeleted => 'Brano eliminato.';

  @override
  String get setlistsTitle => 'Scalette';

  @override
  String get setlistsEmpty =>
      'Crea una scaletta per la prossima prova o esibizione.';

  @override
  String get setlistsEmptySearch =>
      'Nessuna scaletta corrisponde alla ricerca.';

  @override
  String get setlistCreate => 'Nuova scaletta';

  @override
  String get setlistNameHint => 'Nome della scaletta';

  @override
  String get setlistNotes => 'Note';

  @override
  String get setlistEntryOverride => 'Tonalità e capotasto specifici del brano';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
      zero: 'Nessun brano',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Almeno $duration';
  }

  @override
  String get setlistDurationUnknown => 'Durata sconosciuta';

  @override
  String setlistActivity(String date) {
    return 'Ultima attività: $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Creata il $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Modificata il $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Riprodotta l\'ultima volta il $date';
  }

  @override
  String get setlistSongsEmpty => 'Questa scaletta non contiene ancora brani.';

  @override
  String get setlistAddSongs => 'Aggiungi brani';

  @override
  String get setlistReorder => 'Riordina i brani';

  @override
  String setlistMoveSongUp(String song) {
    return 'Sposta $song in alto';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Sposta $song in basso';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Rimuovi $song dalla scaletta';
  }

  @override
  String get setlistDuplicate => 'Duplica scaletta';

  @override
  String get setlistFavoriteAdd => 'Aggiungi scaletta ai preferiti';

  @override
  String get setlistFavoriteRemove => 'Rimuovi scaletta dai preferiti';

  @override
  String get setlistShare => 'Condividi come file di scaletta';

  @override
  String get setlistSharePdf => 'Condividi come PDF';

  @override
  String get setlistPrint => 'Stampa';

  @override
  String get setlistDeleteConfirmTitle => 'Eliminare la scaletta?';

  @override
  String get setlistDeleteConfirmMessage =>
      'La scaletta verrà rimossa. I brani della tua raccolta resteranno.';

  @override
  String get setlistDeleted => 'Scaletta eliminata.';

  @override
  String get readerTitle => 'Testi';

  @override
  String get readerNoLyrics => 'Non è stato ancora aggiunto alcun testo.';

  @override
  String get readerShowChords => 'Mostra accordi';

  @override
  String get readerHideChords => 'Nascondi accordi';

  @override
  String get readerTranspose => 'Trasponi accordi';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semitoni',
      one: '1 semitono',
      zero: '0 semitoni',
    );
    return 'Trasponi di $_temp0';
  }

  @override
  String get readerSaved => 'Salvato';

  @override
  String get readerEdit => 'Modifica testo e dettagli';

  @override
  String get playerPlay => 'Avvia lo scorrimento del testo';

  @override
  String get playerPause => 'Metti in pausa lo scorrimento del testo';

  @override
  String get playerResume => 'Riprendi lo scorrimento del testo';

  @override
  String get playerSeek => 'Posizione di riproduzione';

  @override
  String playerElapsed(String time) {
    return 'Tempo trascorso: $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Tempo rimanente: $time';
  }

  @override
  String get playerTimingMode => 'Modalità di scorrimento';

  @override
  String get playerTimedLyrics => 'Testi sincronizzati';

  @override
  String get playerStartScroll => 'Avvia scorrimento automatico';

  @override
  String get playerEstimatedPace => 'Velocità stimata';

  @override
  String get playerScrollSpeed => 'Velocità di scorrimento';

  @override
  String playerEstimatedDuration(String time) {
    return 'Durata stimata: $time';
  }

  @override
  String get playerLyricsOnly => 'Scorrimento testo · senza audio';

  @override
  String get playerManualScroll => 'Scorrimento manuale';

  @override
  String get playerTimingStatusReady =>
      'Il testo seguirà la sincronizzazione disponibile.';

  @override
  String get playerTimingStatusEstimated =>
      'La velocità di scorrimento è stimata in base alla durata del brano.';

  @override
  String get playerTimingStatusManual => 'Scorri il testo manualmente.';

  @override
  String get playerTimingStatusUnavailable =>
      'Lo scorrimento sincronizzato non è disponibile per questo brano.';

  @override
  String get playerDurationUnknown =>
      'Aggiungi la durata del brano per usare lo scorrimento stimato.';

  @override
  String get playerProgressLabel => 'Avanzamento del brano';

  @override
  String get playerCurrentSection => 'Sezione corrente';

  @override
  String get playerPreviousSection => 'Sezione precedente';

  @override
  String get playerNextSection => 'Sezione successiva';

  @override
  String get playerPreviousSectionSong =>
      'Sezione precedente · tieni premuto per il brano precedente della scaletta';

  @override
  String get playerNextSectionSong =>
      'Sezione successiva · tieni premuto per il brano successivo della scaletta';

  @override
  String get playerPreviousSong => 'Brano precedente';

  @override
  String get playerNextSong => 'Brano successivo';

  @override
  String get editorTitle => 'Modifica brano';

  @override
  String get editorTitleField => 'Titolo del brano';

  @override
  String get editorArtistField => 'Artista';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Testo';

  @override
  String get editorChordsField => 'Accordi';

  @override
  String get editorKeyField => 'Tonalità';

  @override
  String get editorCapoField => 'Capotasto';

  @override
  String get editorTuningField => 'Accordatura';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Durata';

  @override
  String get editorTimeSignatureField => 'Indicazione di tempo';

  @override
  String get editorLanguageField => 'Lingua';

  @override
  String get editorYearField => 'Anno';

  @override
  String get editorComposerField => 'Compositore';

  @override
  String get editorLyricistField => 'Autore del testo';

  @override
  String get editorCopyrightField => 'Copyright';

  @override
  String get editorLicenseField => 'Licenza';

  @override
  String get songInfoSources => 'Fonti e crediti';

  @override
  String get searchMatchSameSong =>
      'Stesso brano; registrazione non confermata';

  @override
  String get searchMatchNeedsAgreement =>
      'Il testo deve essere confermato rispetto allo spartito';

  @override
  String get searchMatchDifferentLyrics =>
      'Il testo differisce da quello del brano selezionato';

  @override
  String get searchMatchCombinedSources => 'Dettagli combinati da più fonti';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Combinato da $count fonti',
      one: 'Combinato da 1 fonte',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count corrispondenze di brani',
      one: '1 corrispondenza di brano',
      zero: '0 corrispondenze di brani',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versioni della fonte',
      one: '1 versione della fonte',
      zero: '0 versioni della fonte',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Migliore corrispondenza disponibile';

  @override
  String get providerDescriptionUnknown => 'Fonte del brano';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Scarica un file ChordPro dalla fonte, poi importalo.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Scarica il file con un account gratuito, poi importalo.';

  @override
  String get providerDescPublicChordSheets => 'Schede di accordi pubbliche.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Testi storici con licenza per ciascuna opera.';

  @override
  String get providerDescLicensedCatalog => 'Catalogo di testi con licenza.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Brani originali con licenza Creative Commons BY.';

  @override
  String get providerDescPerSongLicense => 'Testi con licenza per ogni brano.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Solo dettagli della registrazione e della pubblicazione.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Solo dettagli della composizione.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Copertine solo per corrispondenze esatte della registrazione.';

  @override
  String get providerCapabilityLyrics => 'Testi';

  @override
  String get providerCapabilityChords => 'Accordi';

  @override
  String get providerCapabilityTiming => 'Testi sincronizzati';

  @override
  String get providerCapabilitySearch => 'Ricerca';

  @override
  String get providerCapabilityMetadata => 'Dettagli del brano';

  @override
  String get editorArtworkField => 'Link alla copertina';

  @override
  String get editorLyricsHint =>
      'Tocca una riga per modificare il testo o gli accordi.';

  @override
  String get editorSave => 'Salva modifiche';

  @override
  String get editorSaved => 'Modifiche salvate.';

  @override
  String get editorSaveFailed => 'Impossibile salvare le modifiche.';

  @override
  String get editorSaveConflict =>
      'Il brano è stato modificato altrove. Le tue modifiche sono state salvate come copia separata.';

  @override
  String get editorUnsavedTitle => 'Scartare le modifiche?';

  @override
  String get editorUnsavedMessage => 'Le modifiche non sono state salvate.';

  @override
  String get editorFieldRequired => 'Inserisci il titolo del brano.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Usa l\'impostazione del dispositivo';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsColorPalette => 'Palette colori';

  @override
  String get settingsFont => 'Carattere';

  @override
  String get settingsTextSize => 'Dimensione del testo';

  @override
  String get settingsLyricsPreview => 'Anteprima del testo';

  @override
  String get settingsPlayer => 'Lettore di testi';

  @override
  String get settingsDefaultShowChords =>
      'Mostra accordi per impostazione predefinita';

  @override
  String get settingsDefaultAutoscroll =>
      'Avvia automaticamente lo scorrimento del testo';

  @override
  String get settingsDefaultTiming => 'Modalità di scorrimento predefinita';

  @override
  String get settingsLanguage => 'Lingua dell\'app';

  @override
  String get settingsLanguageSystem => 'Usa la lingua del dispositivo';

  @override
  String get settingsLanguageEnglish => 'Inglese';

  @override
  String get settingsLanguageBulgarian => 'Bulgaro';

  @override
  String get settingsLanguageUkrainian => 'Ucraino';

  @override
  String get settingsSources => 'Fonti dei testi';

  @override
  String settingsSourceEnabled(String source) {
    return 'Abilita la fonte $source';
  }

  @override
  String get settingsSourceRefresh => 'Aggiorna l\'elenco delle fonti';

  @override
  String get settingsSourcesUpdated => 'Fonti aggiornate.';

  @override
  String get settingsSourcesUpdateFailed => 'Impossibile aggiornare le fonti.';

  @override
  String get settingsImport => 'Importa brani';

  @override
  String get settingsImportChordPro => 'Importa file ChordPro';

  @override
  String get settingsImportSetlist => 'Importa file di scaletta';

  @override
  String get settingsImportSuccess => 'Importazione completata.';

  @override
  String get settingsImportFailed => 'Impossibile importare questo file.';

  @override
  String get settingsImportUnsupported =>
      'Questo tipo di file non è supportato.';

  @override
  String get settingsShareSong => 'Condividi come ChordPro';

  @override
  String get settingsSharePdf => 'Condividi come PDF';

  @override
  String get settingsCopySong => 'Copia negli appunti';

  @override
  String get settingsPrintSong => 'Stampa solo il brano';

  @override
  String get settingsPrintSetlist => 'Stampa la scaletta con i testi';

  @override
  String get settingsExportFailed => 'Impossibile preparare il file.';

  @override
  String get settingsCopied => 'Copiato negli appunti.';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsLegal => 'Note legali';

  @override
  String get settingsClearHistory => 'Cancella cronologia';

  @override
  String get settingsClearHistoryConfirm =>
      'Cancellare la cronologia di brani e scalette?';

  @override
  String get settingsHistoryCleared => 'Cronologia cancellata.';

  @override
  String get accountTitle => 'Account e sincronizzazione';

  @override
  String get accountUnavailable =>
      'La sincronizzazione richiede una versione di Singbook configurata per l\'accesso con Google. Questa versione conserva i brani solo su questo dispositivo.';

  @override
  String get accountSyncNow => 'Sincronizza ora';

  @override
  String get accountConnected =>
      'Connesso. Scegli «Sincronizza ora» per aggiornare il backup.';

  @override
  String get accountSignIn => 'Collega account';

  @override
  String get accountSignOut => 'Esci';

  @override
  String get accountChange => 'Cambia account';

  @override
  String get accountSignedOut => 'Non connesso';

  @override
  String get accountSyncing => 'Sincronizzazione della raccolta…';

  @override
  String get accountSynced => 'Raccolta sincronizzata.';

  @override
  String get accountSyncFailed => 'Impossibile sincronizzare la raccolta.';

  @override
  String get accessibilityFavorite => 'Preferito';

  @override
  String get accessibilityNotFavorite => 'Non preferito';

  @override
  String get accessibilitySearchField => 'Cerca brani';

  @override
  String get accessibilityClearSearch => 'Cancella testo di ricerca';

  @override
  String accessibilitySongMenu(String song) {
    return 'Azioni per $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Azioni per $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Espandi i brani in $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Comprimi i brani in $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Avanzamento della riproduzione, $percent per cento';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Cronologia delle attività, $date';
  }

  @override
  String get loading => 'Caricamento…';

  @override
  String get loadingSongs => 'Caricamento dei brani…';

  @override
  String get loadingSetlists => 'Caricamento delle scalette…';

  @override
  String get errorGeneric => 'Si è verificato un errore.';

  @override
  String get errorOffline => 'Sembra che tu sia offline.';

  @override
  String get errorPermission =>
      'È necessaria un\'autorizzazione per continuare.';

  @override
  String get emptyFiltered => 'Nessun elemento corrisponde a questi filtri.';

  @override
  String get unknownValue => 'Sconosciuto';

  @override
  String get durationUnknown => 'Durata sconosciuta';

  @override
  String get metadataNotSet => 'Non impostato';

  @override
  String get dateToday => 'Oggi';

  @override
  String get dateYesterday => 'Ieri';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
      zero: 'Nessun brano',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Blu navy';

  @override
  String get settingsPaletteSage => 'Verde salvia';

  @override
  String get settingsPaletteOcean => 'Oceano';

  @override
  String get settingsPaletteClay => 'Argilla';

  @override
  String get settingsPalettePlum => 'Prugna';

  @override
  String get settingsFontSystem => 'Sistema';

  @override
  String get settingsFontSerif => 'Con grazie';

  @override
  String get settingsFontMonospace => 'Monospaziato';

  @override
  String get settingsLyricsPreviewExample =>
      'Quando arriverà il mattino, canteremo ancora.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Controllo delle fonti dei testi: completate $checked di $total.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Non sono stati trovati testi utilizzabili.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Il brano selezionato è stato controllato nelle fonti abilitate, ma nessuna ha fornito una versione del testo utilizzabile.';

  @override
  String get searchDiscoveryError =>
      'Impossibile controllare le fonti dei testi.';

  @override
  String get searchDiscoveryRetry => 'Ripeti la ricerca dei testi';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fonti non disponibili',
      one: '1 fonte non disponibile',
      zero: '0 fonti non disponibili',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Controlla la connessione e riprova.';

  @override
  String get searchProviderChecks => 'Verifiche delle fonti';

  @override
  String get searchProviderPending => 'Verifica in corso';

  @override
  String get searchProviderFound => 'Corrispondenza trovata';

  @override
  String get searchProviderRejected => 'Non corrisponde';

  @override
  String get searchProviderFailed => 'Verifica non riuscita';

  @override
  String get searchProviderUnavailable => 'Nessun testo utilizzabile';

  @override
  String get searchCatalogFilterHint =>
      'Seleziona un brano per filtrare le versioni del testo per accordi, sincronizzazione o lingua.';

  @override
  String get startupErrorTitle => 'Impossibile aprire la raccolta.';

  @override
  String setlistCopyName(String name) {
    return 'Copia di $name';
  }

  @override
  String get setlistSongMissing => 'Brano mancante';

  @override
  String get settingsImportTooLarge =>
      'Questo file è troppo grande per essere importato.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Vai alla lettera $letter';
  }

  @override
  String get actionDiscard => 'Scarta';

  @override
  String get editorKeepEditing => 'Continua a modificare';

  @override
  String get settingsDefaultShowChordsHint =>
      'Mostra gli accordi sopra il testo quando il brano li contiene.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Il testo scorre insieme al brano. Non viene usato in modalità di scorrimento manuale.';

  @override
  String get accountUnavailableTitle => 'Sincronizzazione non configurata';

  @override
  String get accountSignedOutBenefits =>
      'Accedi con Google per eseguire il backup dei brani e delle scalette su Google Drive e mantenere sincronizzati tutti i tuoi dispositivi. In ogni caso, i brani restano su questo dispositivo.';

  @override
  String get accountSignInWithGoogle => 'Accedi con Google';

  @override
  String get accountWorking => 'Operazione in corso…';

  @override
  String get accountNeverSynced => 'Mai sincronizzato';

  @override
  String get accountSyncedJustNow => 'Sincronizzato proprio ora';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizzato $count minuti fa',
      one: 'Sincronizzato 1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizzato $count ore fa',
      one: 'Sincronizzato 1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizzato $count giorni fa',
      one: 'Sincronizzato 1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche in conflitto salvate come copie',
      one: '1 modifica in conflitto salvata come copia',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Lo stesso brano o la stessa scaletta è stata modificata in due punti. Non è andato perso nulla: l\'altra versione è stata salvata come copia separata.';

  @override
  String get accountReviewConflicts => 'Esamina le copie';

  @override
  String get songsConflictFilterActive =>
      'Visualizzazione delle sole copie in conflitto';

  @override
  String get songsConflictFilterClear => 'Mostra tutti i brani';

  @override
  String get songsConflictBadge => 'Copia in conflitto';

  @override
  String get songsConflictEmpty => 'Nessuna copia in conflitto.';

  @override
  String get accountAutoSync => 'Sincronizza automaticamente';

  @override
  String get accountAutoSyncHint =>
      'Mantieni aggiornata la raccolta quando apri l\'app e dopo le modifiche.';

  @override
  String get accountSignOutTitle => 'Uscire da questo account?';

  @override
  String get accountSignOutBody =>
      'I brani e le scalette restano su questo dispositivo. Non verranno sottoposti a backup o sincronizzati finché non accederai di nuovo.';

  @override
  String get accountUseDifferent => 'Usa un altro account';

  @override
  String get accountSignInAgain => 'Accedi di nuovo';

  @override
  String get accountChooseAction => 'Scegli come continuare';

  @override
  String get accountChangedTitle => 'Account Google diverso';

  @override
  String get accountChangedBody =>
      'Questo dispositivo è stato sincronizzato l\'ultima volta con un altro account Google. Scegli cosa fare con i brani e le scalette presenti su questo dispositivo.';

  @override
  String get accountChangedMerge => 'Unisci al nuovo account';

  @override
  String get accountChangedMergeHint =>
      'Conserva tutto su questo dispositivo e aggiungilo al nuovo account.';

  @override
  String get accountChangedReplace =>
      'Sostituisci con la raccolta del nuovo account';

  @override
  String get accountChangedReplaceHint =>
      'I brani su questo dispositivo che non sono nel nuovo account verranno rimossi.';

  @override
  String get accountChangedSignOut => 'Annulla ed esci';

  @override
  String get accountStatusSignedOut =>
      'Account e sincronizzazione: non connesso';

  @override
  String get accountStatusSignedIn => 'Account e sincronizzazione: connesso';

  @override
  String get accountStatusSyncing =>
      'Account e sincronizzazione: sincronizzazione in corso';

  @override
  String get accountStatusSynced =>
      'Account e sincronizzazione: raccolta aggiornata';

  @override
  String get accountStatusError =>
      'Account e sincronizzazione: problema, tocca per esaminare';

  @override
  String get accountNoticeConflicts =>
      'Alcuni brani sono stati modificati in due punti. Le copie sono state conservate.';

  @override
  String get accountNoticeSignedIn => 'Accesso effettuato.';

  @override
  String get accountNoticeSignedOut =>
      'Disconnessione effettuata. I brani restano su questo dispositivo.';

  @override
  String get syncErrorNotConfigured =>
      'La sincronizzazione non è configurata in questa versione.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Usa una versione di Singbook configurata per l\'accesso con Google.';

  @override
  String get syncErrorNotSignedIn => 'Non hai effettuato l\'accesso.';

  @override
  String get syncErrorNotSignedInHint =>
      'Accedi per sincronizzare la raccolta.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google richiede un nuovo accesso.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Accedi di nuovo per continuare la sincronizzazione. I brani sono al sicuro su questo dispositivo.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook non dispone dell\'autorizzazione per usare Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Accedi di nuovo e consenti l\'accesso a Drive quando richiesto.';

  @override
  String get syncErrorRateLimited =>
      'Google sta limitando le richieste per il momento.';

  @override
  String get syncErrorRateLimitedHint => 'Attendi alcuni minuti, poi riprova.';

  @override
  String get syncErrorStorageFull => 'Google Drive è pieno.';

  @override
  String get syncErrorStorageFullHint => 'Libera spazio su Drive, poi riprova.';

  @override
  String get syncErrorNetwork => 'Impossibile raggiungere Google.';

  @override
  String get syncErrorNetworkHint =>
      'Controlla la connessione a Internet e riprova.';

  @override
  String get syncErrorAccountChanged =>
      'È stato usato un altro account Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Scegli se unire la raccolta di questo dispositivo a quella dell\'account o sostituirla.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'La raccolta sincronizzata è troppo grande per Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Rimuovi alcuni brani o scalette dalla raccolta sincronizzata, poi riprova.';

  @override
  String get syncErrorSignInFailed => 'L\'accesso non è stato completato.';

  @override
  String get syncErrorSignInFailedHint => 'Prova ad accedere di nuovo.';

  @override
  String get syncErrorGeneric => 'Impossibile sincronizzare la raccolta.';

  @override
  String get syncErrorGenericHint =>
      'Riprova tra poco. I brani sono ancora al sicuro su questo dispositivo.';

  @override
  String get editorDurationInvalid =>
      'Inserisci i secondi oppure minuti e secondi, ad esempio 3:45.';

  @override
  String get editorNumberInvalid => 'Inserisci un numero.';

  @override
  String get accountReplaceConfirmTitle => 'Eliminare i brani locali?';

  @override
  String get accountReplaceConfirmBody =>
      'I brani e le scalette su questo dispositivo che non sono nel nuovo account verranno eliminati definitivamente. L’operazione non può essere annullata.';

  @override
  String get accountReplaceConfirmAction => 'Elimina e sostituisci';

  @override
  String get accountSuspiciousTitle => 'Elementi mancanti su Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elementi sincronizzati in precedenza da questo dispositivo sono mancanti su Google Drive.',
      one:
          '$count elemento sincronizzato in precedenza da questo dispositivo è mancante su Google Drive.',
    );
    return '$_temp0 Può succedere se i dati dell’app sono stati cancellati nelle impostazioni Google. Non è stato eliminato nulla.';
  }

  @override
  String get accountSuspiciousDelete => 'Eliminali anche qui';

  @override
  String get accountSuspiciousKeep =>
      'Conserva i miei brani e caricali di nuovo';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminare $count elementi da questo dispositivo?',
      one: 'Eliminare $count elemento da questo dispositivo?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Questi brani e scalette verranno eliminati definitivamente da questo dispositivo. L’operazione non può essere annullata.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Elimina da questo dispositivo';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Elementi mancanti su Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Non è stato eliminato nulla. Scegli se eliminarli anche qui o caricarli di nuovo.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive è cambiato durante la sincronizzazione.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Non è andato perso nulla. Sincronizza di nuovo per recuperare le modifiche più recenti.';

  @override
  String get syncErrorInvalidLocalData =>
      'Non è stato possibile sincronizzare alcuni dati su questo dispositivo.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Non è stato possibile leggere un brano o una scaletta. Importalo o ricrealo, poi sincronizza di nuovo.';

  @override
  String get syncErrorNoAccountChange =>
      'Non c’è alcun cambio di account da risolvere.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Sincronizza di nuovo per continuare.';

  @override
  String get accountSyncWarningTitle =>
      'Sincronizzazione completata, ma alcuni file sono stati ignorati';

  @override
  String get accountSyncWarningBody =>
      'Alcuni file non erano utilizzabili e sono stati lasciati invariati. Tutto il resto è aggiornato.';

  @override
  String get accountSyncWarningTooLarge =>
      'Un file era troppo grande per la sincronizzazione ed è stato ignorato. Tutto il resto è aggiornato.';

  @override
  String get accountSyncWarningInvalid =>
      'Non è stato possibile leggere un file, che è stato ignorato. Tutto il resto è aggiornato.';

  @override
  String get accountNoticeSyncSkipped =>
      'Sincronizzazione completata. Alcuni file sono stati ignorati.';

  @override
  String get settingsExportPdfTooLarge =>
      'Questo PDF sarebbe troppo grande. Prova con meno brani o condividilo come testo.';

  @override
  String get settingsTimingTooLarge =>
      'I dati di timing sono troppo grandi (oltre 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Questo backup contiene due volte lo stesso brano, quindi non è stato importato nulla.';

  @override
  String get setlistSaveConflict =>
      'La scaletta è stata modificata altrove. Le tue modifiche sono state salvate in una copia separata.';

  @override
  String get sectionVerse => 'Strofa';

  @override
  String get sectionChorus => 'Ritornello';

  @override
  String get sectionBridge => 'Bridge';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pre-ritornello';

  @override
  String get sectionPostChorus => 'Post-ritornello';

  @override
  String get sectionInstrumental => 'Strumentale';

  @override
  String get sectionInterlude => 'Interludio';

  @override
  String get sectionSolo => 'Assolo';

  @override
  String get sectionRefrain => 'Refrain';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Finale';
}
