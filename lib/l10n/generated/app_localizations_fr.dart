// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Un espace paisible pour trouver, organiser et chanter à partir de votre bibliothèque de chansons.';

  @override
  String get aboutMadeForSinging => 'Conçu pour chanter ensemble';

  @override
  String get aboutDetails =>
      'Recherchez dans les sources activées, comparez les versions, regroupez paroles et accords et organisez les chansons en listes. Votre bibliothèque est enregistrée sur cet appareil ; la synchronisation Google Drive facultative utilise votre compte Google. Les recherches sont envoyées directement aux sources activées.';

  @override
  String get aboutSupport => 'Aide et commentaires';

  @override
  String get menuTypeNewSong => 'Saisir une nouvelle chanson';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get navHome => 'Accueil';

  @override
  String get navSongs => 'Chansons';

  @override
  String get navSetlists => 'Listes de chansons';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navSettingsCompact => 'Paramètres';

  @override
  String get navSearch => 'Rechercher';

  @override
  String get navBack => 'Retour';

  @override
  String get appExitBackAgain => 'Appuyez de nouveau sur Retour pour quitter';

  @override
  String get navClose => 'Fermer';

  @override
  String get navMore => 'Autres actions';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionDone => 'Terminé';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionShare => 'Partager';

  @override
  String get actionPrint => 'Imprimer';

  @override
  String get actionCopy => 'Copier';

  @override
  String get actionClear => 'Effacer';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionRefresh => 'Actualiser';

  @override
  String get actionImport => 'Importer';

  @override
  String get actionExport => 'Exporter';

  @override
  String get actionExpand => 'Développer';

  @override
  String get actionCollapse => 'Réduire';

  @override
  String get actionAdd => 'Ajouter';

  @override
  String get actionCreate => 'Créer';

  @override
  String get actionRemove => 'Retirer';

  @override
  String get actionDuplicate => 'Dupliquer';

  @override
  String get actionMoveUp => 'Déplacer vers le haut';

  @override
  String get actionMoveDown => 'Déplacer vers le bas';

  @override
  String get actionPrevious => 'Précédent';

  @override
  String get actionNext => 'Suivant';

  @override
  String get searchHint =>
      'Rechercher des chansons, des artistes ou des paroles';

  @override
  String get searchCatalogHint => 'Rechercher une chanson ou un artiste';

  @override
  String get searchChangeSong => 'Changer de chanson';

  @override
  String get searchSelectedPreview => 'Aperçu sélectionné';

  @override
  String get searchSubmit => 'Rechercher';

  @override
  String get searchFilters => 'Options de recherche';

  @override
  String get searchFiltersShow => 'Afficher les options de recherche';

  @override
  String get searchFiltersHide => 'Masquer les options de recherche';

  @override
  String get searchFilterArtist => 'Artiste';

  @override
  String get searchFilterTitle => 'Titre de la chanson';

  @override
  String get searchFilterLyrics => 'Paroles';

  @override
  String get searchFilterChords => 'Avec accords';

  @override
  String get searchFilterTimed => 'Paroles synchronisées';

  @override
  String get searchFilterLanguage => 'Langue';

  @override
  String get searchFilterAll => 'Tous';

  @override
  String get searchAutocompleteLabel => 'Suggestions';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: 'Aucun résultat',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Saisissez une chanson, un artiste ou des paroles à rechercher.';

  @override
  String get searchCatalogEmptyQuery =>
      'Saisissez une chanson ou un artiste à rechercher.';

  @override
  String get searchNoResults =>
      'Aucune chanson trouvée. Essayez une autre recherche.';

  @override
  String get searchLoading => 'Recherche de chansons…';

  @override
  String get searchError => 'La recherche n’a pas pu aboutir.';

  @override
  String get searchOnlineTab => 'En ligne';

  @override
  String get searchRecentTab => 'Récents';

  @override
  String get searchFavoritesTab => 'Favoris';

  @override
  String get searchSuggested => 'Correspondance suggérée';

  @override
  String get searchAlternatives => 'Autres correspondances';

  @override
  String get searchCompare => 'Comparer les versions';

  @override
  String get searchChooseVersion => 'Choisir cette version';

  @override
  String get searchFullPreview => 'Aperçu complet';

  @override
  String get searchArrangementNotes => 'Notes sur l’arrangement';

  @override
  String get searchOpenLyrics => 'Ouvrir les paroles';

  @override
  String get searchContributions => 'Sources utilisées';

  @override
  String get searchVersionChecking => 'Vérification de cette version…';

  @override
  String get searchVersionUnavailable =>
      'Cette version ne peut pas être utilisée. Choisissez-en une autre.';

  @override
  String get searchPreviewUnavailable => 'Aucun aperçu des paroles disponible.';

  @override
  String get searchSongMatch => 'Correspondance de chanson';

  @override
  String get searchRecordingMatch => 'Correspondance d’enregistrement';

  @override
  String get searchMatchUnverified => 'Enregistrement non vérifié';

  @override
  String get searchMatchExact => 'Correspondance exacte de l’enregistrement';

  @override
  String get searchMatchPossible => 'Correspondance possible';

  @override
  String get searchAvailability => 'Disponibilité';

  @override
  String get searchLyricsAvailable => 'Paroles disponibles';

  @override
  String get searchLyricsUnavailable => 'Paroles indisponibles';

  @override
  String get searchChordsAvailable => 'Accords disponibles';

  @override
  String get searchChordsUnavailable => 'Aucun accord';

  @override
  String get searchTimingAvailable => 'Synchronisation disponible';

  @override
  String get searchTimingUnavailable => 'Aucune synchronisation';

  @override
  String get searchDurationUnknown => 'Durée inconnue';

  @override
  String searchRating(String rating) {
    return 'Note : $rating';
  }

  @override
  String get searchSourceLabel => 'Source';

  @override
  String get searchMetadata => 'Détails de la chanson';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Artiste';

  @override
  String get searchYear => 'Année';

  @override
  String get searchLanguage => 'Langue';

  @override
  String get searchViewVersions => 'Voir les versions';

  @override
  String get searchSaved => 'Chanson enregistrée dans votre bibliothèque.';

  @override
  String get searchSaveOpenLyrics => 'Enregistrer et ouvrir les paroles';

  @override
  String get searchOtherResults => 'Autres résultats';

  @override
  String get searchSaveFailed => 'Impossible d’enregistrer cette chanson.';

  @override
  String get homeRecentSongs => 'Chansons récentes';

  @override
  String get homeRecentlyPlayed => 'Écoutées récemment';

  @override
  String get homeFavorites => 'Favoris';

  @override
  String get homeHistory => 'Historique';

  @override
  String get homeHistoryClear => 'Effacer l’historique';

  @override
  String get homeHistoryCleared => 'Historique effacé.';

  @override
  String get homeHistoryEmpty =>
      'Les chansons que vous ouvrez apparaîtront ici.';

  @override
  String get homeFavoritesEmpty =>
      'Vos chansons et listes favorites apparaîtront ici.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments affichés',
      one: '1 élément affiché',
      zero: '0 élément affiché',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Vos chansons et listes récentes apparaîtront ici.';

  @override
  String get homeTimelineLabel => 'Chronologie de l’historique';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Tout l’historique';

  @override
  String get homeShowFavorites => 'Afficher les favoris';

  @override
  String get homeShowRecent => 'Afficher les récents';

  @override
  String get songsTitle => 'Chansons';

  @override
  String get songsEmpty => 'Vos chansons apparaîtront ici.';

  @override
  String get songsEmptySearch =>
      'Aucune chanson ne correspond à votre recherche.';

  @override
  String get songsAdd => 'Ajouter une chanson';

  @override
  String get songsSortAlphabetical => 'Trier par ordre alphabétique';

  @override
  String get songsAlphabetNavigation => 'Index des chansons';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fois',
      one: 'une fois',
      zero: 'jamais',
    );
    return 'Ouverte $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Ajouter aux favoris';

  @override
  String get songFavoriteRemove => 'Retirer des favoris';

  @override
  String get songMenuLabel => 'Actions de la chanson';

  @override
  String get songInfo => 'Détails de la chanson';

  @override
  String get setlistMenuLabel => 'Actions de la liste de chansons';

  @override
  String get songAddToSetlist => 'Ajouter à la liste de chansons';

  @override
  String get songCopyChordPro => 'Copier ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Supprimer la chanson ?';

  @override
  String get songDeleteConfirmMessage =>
      'Cette chanson sera retirée de votre bibliothèque.';

  @override
  String get songDeleted => 'Chanson supprimée.';

  @override
  String get setlistsTitle => 'Listes de chansons';

  @override
  String get setlistsEmpty =>
      'Créez une liste pour votre prochaine répétition ou représentation.';

  @override
  String get setlistsEmptySearch =>
      'Aucune liste ne correspond à votre recherche.';

  @override
  String get setlistCreate => 'Nouvelle liste de chansons';

  @override
  String get setlistNameHint => 'Nom de la liste';

  @override
  String get setlistNotes => 'Notes';

  @override
  String get setlistEntryOverride =>
      'Tonalité et capodastre propres à la chanson';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chansons',
      one: '1 chanson',
      zero: 'Aucune chanson',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Au moins $duration';
  }

  @override
  String get setlistDurationUnknown => 'Durée inconnue';

  @override
  String setlistActivity(String date) {
    return 'Dernière activité : $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Créée le $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Modifiée le $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Jouée pour la dernière fois le $date';
  }

  @override
  String get setlistSongsEmpty =>
      'Cette liste ne contient pas encore de chansons.';

  @override
  String get setlistAddSongs => 'Ajouter des chansons';

  @override
  String get setlistReorder => 'Réorganiser les chansons';

  @override
  String setlistMoveSongUp(String song) {
    return 'Déplacer $song vers le haut';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Déplacer $song vers le bas';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Retirer $song de la liste';
  }

  @override
  String get setlistDuplicate => 'Dupliquer la liste de chansons';

  @override
  String get setlistFavoriteAdd => 'Ajouter la liste aux favoris';

  @override
  String get setlistFavoriteRemove => 'Retirer la liste des favoris';

  @override
  String get setlistShare => 'Partager comme fichier de liste';

  @override
  String get setlistSharePdf => 'Partager en PDF';

  @override
  String get setlistPrint => 'Imprimer';

  @override
  String get setlistDeleteConfirmTitle => 'Supprimer la liste ?';

  @override
  String get setlistDeleteConfirmMessage =>
      'La liste sera supprimée. Les chansons de votre bibliothèque seront conservées.';

  @override
  String get setlistDeleted => 'Liste de chansons supprimée.';

  @override
  String get readerTitle => 'Paroles';

  @override
  String get readerNoLyrics => 'Aucune parole n’a encore été ajoutée.';

  @override
  String get readerShowChords => 'Afficher les accords';

  @override
  String get readerHideChords => 'Masquer les accords';

  @override
  String get readerTranspose => 'Transposer les accords';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count demi-tons',
      one: '1 demi-ton',
      zero: '0 demi-ton',
    );
    return 'Transposer de $_temp0';
  }

  @override
  String get readerSaved => 'Enregistré';

  @override
  String get readerEdit => 'Modifier les paroles et les détails';

  @override
  String get playerPlay => 'Lancer le défilement des paroles';

  @override
  String get playerPause => 'Mettre le défilement des paroles en pause';

  @override
  String get playerResume => 'Reprendre le défilement des paroles';

  @override
  String get playerSeek => 'Position de lecture';

  @override
  String playerElapsed(String time) {
    return 'Temps écoulé : $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Temps restant : $time';
  }

  @override
  String get playerTimingMode => 'Mode de défilement';

  @override
  String get playerTimedLyrics => 'Paroles synchronisées';

  @override
  String get playerStartScroll => 'Démarrer le défilement automatique';

  @override
  String get playerEstimatedPace => 'Vitesse estimée';

  @override
  String get playerScrollSpeed => 'Vitesse de défilement';

  @override
  String playerEstimatedDuration(String time) {
    return 'Durée estimée : $time';
  }

  @override
  String get playerLyricsOnly => 'Défilement des paroles · sans audio';

  @override
  String get playerManualScroll => 'Défilement manuel';

  @override
  String get playerTimingStatusReady =>
      'Les paroles suivront la synchronisation disponible.';

  @override
  String get playerTimingStatusEstimated =>
      'La vitesse de défilement est estimée à partir de la durée de la chanson.';

  @override
  String get playerTimingStatusManual =>
      'Faites défiler les paroles vous-même.';

  @override
  String get playerTimingStatusUnavailable =>
      'Le défilement synchronisé n’est pas disponible pour cette chanson.';

  @override
  String get playerDurationUnknown =>
      'Ajoutez la durée de la chanson pour utiliser le défilement estimé.';

  @override
  String get playerProgressLabel => 'Progression de la chanson';

  @override
  String get playerCurrentSection => 'Section actuelle';

  @override
  String get playerPreviousSection => 'Section précédente';

  @override
  String get playerNextSection => 'Section suivante';

  @override
  String get playerPreviousSectionSong =>
      'Section précédente · maintenir pour passer à la chanson précédente de la liste';

  @override
  String get playerNextSectionSong =>
      'Section suivante · maintenir pour passer à la chanson suivante de la liste';

  @override
  String get playerPreviousSong => 'Chanson précédente';

  @override
  String get playerNextSong => 'Chanson suivante';

  @override
  String get editorTitle => 'Modifier la chanson';

  @override
  String get editorTitleField => 'Titre de la chanson';

  @override
  String get editorArtistField => 'Artiste';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Paroles';

  @override
  String get editorChordsField => 'Accords';

  @override
  String get editorKeyField => 'Tonalité';

  @override
  String get editorCapoField => 'Capodastre';

  @override
  String get editorTuningField => 'Accordage';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Durée';

  @override
  String get editorTimeSignatureField => 'Chiffrage de mesure';

  @override
  String get editorLanguageField => 'Langue';

  @override
  String get editorYearField => 'Année';

  @override
  String get editorComposerField => 'Compositeur';

  @override
  String get editorLyricistField => 'Auteur des paroles';

  @override
  String get editorCopyrightField => 'Droits d’auteur';

  @override
  String get editorLicenseField => 'Licence';

  @override
  String get songInfoSources => 'Sources et crédits';

  @override
  String get searchMatchSameSong =>
      'Même chanson ; enregistrement non confirmé';

  @override
  String get searchMatchNeedsAgreement =>
      'Les paroles doivent être confirmées pour cette partition';

  @override
  String get searchMatchDifferentLyrics =>
      'Les paroles diffèrent de celles de la chanson sélectionnée';

  @override
  String get searchMatchCombinedSources =>
      'Détails réunis à partir de plusieurs sources';

  @override
  String get searchCombinedLabel => 'Tout';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count correspondances de chansons',
      one: '1 correspondance de chanson',
      zero: '0 correspondance de chanson',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versions sources',
      one: '1 version source',
      zero: '0 version source',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Meilleure correspondance disponible';

  @override
  String get providerDescriptionUnknown => 'Source de chansons';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Téléchargez un fichier ChordPro depuis la source, puis importez-le.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Téléchargez le fichier avec un compte gratuit, puis importez-le.';

  @override
  String get providerDescPublicChordSheets => 'Grilles d’accords publiques.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Paroles historiques sous licence pour chaque œuvre.';

  @override
  String get providerDescLicensedCatalog =>
      'Catalogue de paroles sous licence.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Chansons originales sous licence Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Paroles sous licence pour chaque chanson.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Informations sur l’enregistrement et la sortie uniquement.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Informations sur la composition uniquement.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Pochettes uniquement pour les correspondances exactes d’enregistrement.';

  @override
  String get providerCapabilityLyrics => 'Paroles';

  @override
  String get providerCapabilityChords => 'Accords';

  @override
  String get providerCapabilityTiming => 'Paroles synchronisées';

  @override
  String get providerCapabilitySearch => 'Recherche';

  @override
  String get providerCapabilityMetadata => 'Détails de la chanson';

  @override
  String get editorArtworkField => 'Lien vers la pochette';

  @override
  String get editorLyricsHint =>
      'Touchez une ligne pour modifier les paroles ou les accords.';

  @override
  String get editorSave => 'Enregistrer les modifications';

  @override
  String get editorSaved => 'Modifications enregistrées.';

  @override
  String get editorSaveFailed => 'Impossible d’enregistrer les modifications.';

  @override
  String get editorSaveConflict =>
      'La chanson a été modifiée ailleurs. Vos modifications ont été enregistrées dans une copie séparée.';

  @override
  String get editorUnsavedTitle => 'Abandonner les modifications ?';

  @override
  String get editorUnsavedMessage =>
      'Vos modifications n’ont pas été enregistrées.';

  @override
  String get editorFieldRequired => 'Saisissez un titre de chanson.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeSystem => 'Utiliser le réglage de l’appareil';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsColorPalette => 'Palette de couleurs';

  @override
  String get settingsFont => 'Police';

  @override
  String get settingsTextSize => 'Taille du texte';

  @override
  String get settingsLyricsPreview => 'Aperçu des paroles';

  @override
  String get settingsPlayer => 'Lecteur de paroles';

  @override
  String get settingsDefaultShowChords => 'Afficher les accords par défaut';

  @override
  String get settingsDefaultAutoscroll =>
      'Faire défiler les paroles automatiquement';

  @override
  String get settingsDefaultTiming => 'Mode de défilement par défaut';

  @override
  String get settingsLanguage => 'Langue de l’application';

  @override
  String get settingsLanguageSystem => 'Utiliser la langue de l’appareil';

  @override
  String get settingsLanguageEnglish => 'Anglais';

  @override
  String get settingsLanguageBulgarian => 'Bulgare';

  @override
  String get settingsLanguageUkrainian => 'Ukrainien';

  @override
  String get settingsSources => 'Sources de paroles';

  @override
  String settingsSourceEnabled(String source) {
    return 'Activer la source $source';
  }

  @override
  String get settingsSourceRefresh => 'Actualiser la liste des sources';

  @override
  String get settingsSourcesUpdated => 'Sources actualisées.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Impossible d’actualiser les sources.';

  @override
  String get settingsImport => 'Importer des chansons';

  @override
  String get settingsImportChordPro => 'Importer un fichier ChordPro';

  @override
  String get settingsImportSetlist => 'Importer un fichier de liste';

  @override
  String get settingsImportSuccess => 'Importation terminée.';

  @override
  String get settingsImportFailed => 'Impossible d’importer ce fichier.';

  @override
  String get settingsImportUnsupported =>
      'Ce type de fichier n’est pas pris en charge.';

  @override
  String get settingsShareSong => 'Partager en ChordPro';

  @override
  String get settingsSharePdf => 'Partager en PDF';

  @override
  String get settingsCopySong => 'Copier dans le presse-papiers';

  @override
  String get settingsPrintSong => 'Imprimer uniquement la chanson';

  @override
  String get settingsPrintSetlist => 'Imprimer la liste avec les paroles';

  @override
  String get settingsExportFailed => 'Impossible de préparer le fichier.';

  @override
  String get settingsCopied => 'Copié dans le presse-papiers.';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsPrivacy => 'Confidentialité';

  @override
  String get settingsLegal => 'Mentions légales';

  @override
  String get settingsClearHistory => 'Effacer l’historique';

  @override
  String get settingsClearHistoryConfirm =>
      'Effacer l’historique de vos chansons et listes ?';

  @override
  String get settingsHistoryCleared => 'Historique effacé.';

  @override
  String get accountTitle => 'Compte et synchronisation';

  @override
  String get accountUnavailable =>
      'La synchronisation nécessite une version de Singbook configurée pour la connexion Google. Cette version conserve vos chansons uniquement sur cet appareil.';

  @override
  String get accountSyncNow => 'Synchroniser maintenant';

  @override
  String get accountConnected =>
      'Connecté. Choisissez « Synchroniser maintenant » pour mettre à jour votre sauvegarde.';

  @override
  String get accountSignIn => 'Connecter un compte';

  @override
  String get accountSignOut => 'Se déconnecter';

  @override
  String get accountChange => 'Changer de compte';

  @override
  String get accountSignedOut => 'Non connecté';

  @override
  String get accountSyncing => 'Synchronisation de votre bibliothèque…';

  @override
  String get accountSynced => 'Bibliothèque synchronisée.';

  @override
  String get accountSyncFailed =>
      'Impossible de synchroniser votre bibliothèque.';

  @override
  String get accessibilityFavorite => 'Favori';

  @override
  String get accessibilityNotFavorite => 'Pas un favori';

  @override
  String get accessibilitySearchField => 'Rechercher des chansons';

  @override
  String get accessibilityClearSearch => 'Effacer le texte de recherche';

  @override
  String accessibilitySongMenu(String song) {
    return 'Actions pour $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Actions pour $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Développer les chansons de $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Réduire les chansons de $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Progression de lecture, $percent pour cent';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Chronologie de l’historique, $date';
  }

  @override
  String get loading => 'Chargement…';

  @override
  String get loadingSongs => 'Chargement des chansons…';

  @override
  String get loadingSetlists => 'Chargement des listes…';

  @override
  String get errorGeneric => 'Une erreur s’est produite.';

  @override
  String get errorOffline => 'Vous semblez être hors ligne.';

  @override
  String get errorPermission =>
      'Une autorisation est nécessaire pour continuer.';

  @override
  String get emptyFiltered => 'Aucun élément ne correspond à ces filtres.';

  @override
  String get unknownValue => 'Inconnu';

  @override
  String get durationUnknown => 'Durée inconnue';

  @override
  String get metadataNotSet => 'Non défini';

  @override
  String get dateToday => 'Aujourd’hui';

  @override
  String get dateYesterday => 'Hier';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chansons',
      one: '1 chanson',
      zero: 'Aucune chanson',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Bleu marine';

  @override
  String get settingsPaletteSage => 'Vert sauge';

  @override
  String get settingsPaletteOcean => 'Océan';

  @override
  String get settingsPaletteClay => 'Argile';

  @override
  String get settingsPalettePlum => 'Prune';

  @override
  String get settingsFontSystem => 'Système';

  @override
  String get settingsFontSerif => 'À empattement';

  @override
  String get settingsFontMonospace => 'À chasse fixe';

  @override
  String get settingsLyricsPreviewExample =>
      'Quand le matin viendra, nous chanterons à nouveau.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Vérification des sources de paroles : $checked sur $total terminées.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Aucune parole utilisable trouvée.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'La chanson sélectionnée a été vérifiée auprès des sources activées, mais aucune n’a fourni de version de paroles utilisable.';

  @override
  String get searchDiscoveryError =>
      'Impossible de vérifier les sources de paroles.';

  @override
  String get searchDiscoveryRetry => 'Relancer la recherche de paroles';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources indisponibles',
      one: '1 source indisponible',
      zero: '0 source indisponible',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Vérifiez votre connexion et réessayez.';

  @override
  String get searchProviderChecks => 'Vérifications des sources';

  @override
  String get searchProviderPending => 'Vérification';

  @override
  String get searchProviderFound => 'Correspondance trouvée';

  @override
  String get searchProviderRejected => 'Ne correspond pas';

  @override
  String get searchProviderFailed => 'Échec de la vérification';

  @override
  String get searchProviderUnavailable => 'Aucune parole utilisable';

  @override
  String get searchCatalogFilterHint =>
      'Sélectionnez une chanson pour filtrer les versions de paroles par accords, synchronisation ou langue.';

  @override
  String get startupErrorTitle => 'Impossible d’ouvrir votre bibliothèque.';

  @override
  String setlistCopyName(String name) {
    return 'Copie de $name';
  }

  @override
  String get setlistSongMissing => 'Chanson manquante';

  @override
  String get settingsImportTooLarge =>
      'Ce fichier est trop volumineux pour être importé.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Aller à $letter';
  }

  @override
  String get actionDiscard => 'Abandonner';

  @override
  String get editorKeepEditing => 'Continuer la modification';

  @override
  String get settingsDefaultShowChordsHint =>
      'Afficher les accords au-dessus des paroles lorsque la chanson en comporte.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Les paroles défilent avec la chanson. Cette option n’est pas utilisée en mode de défilement manuel.';

  @override
  String get accountUnavailableTitle => 'Synchronisation non configurée';

  @override
  String get accountSignedOutBenefits =>
      'La connexion à Google Drive synchronise votre bibliothèque. Les modifications des chansons sont ensuite synchronisées automatiquement.';

  @override
  String get accountManualSyncHint =>
      'Vous pouvez aussi toucher Synchroniser maintenant pour synchroniser votre bibliothèque.';

  @override
  String get accountSignInWithGoogle => 'Se connecter avec Google';

  @override
  String get accountWorking => 'En cours…';

  @override
  String get accountNeverSynced => 'Jamais synchronisé';

  @override
  String get accountSyncedJustNow => 'Synchronisé à l’instant';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronisé il y a $count minutes',
      one: 'Synchronisé il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronisé il y a $count heures',
      one: 'Synchronisé il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronisé il y a $count jours',
      one: 'Synchronisé il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications conflictuelles conservées comme copies',
      one: '1 modification conflictuelle conservée comme copie',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'La même chanson ou liste a été modifiée à deux endroits. Rien n’a été perdu : l’autre version a été enregistrée dans une copie séparée.';

  @override
  String get accountReviewConflicts => 'Examiner les copies';

  @override
  String get songsConflictFilterActive =>
      'Affichage des copies en conflit uniquement';

  @override
  String get songsConflictFilterClear => 'Afficher toutes les chansons';

  @override
  String get songsConflictBadge => 'Copie en conflit';

  @override
  String get songsConflictEmpty => 'Aucune copie en conflit.';

  @override
  String get accountAutoSync => 'Synchroniser automatiquement';

  @override
  String get accountAutoSyncHint =>
      'La synchronisation a lieu après la connexion, puis après l’ajout, la modification ou la suppression d’une chanson.';

  @override
  String get accountSignOutTitle => 'Se déconnecter de ce compte ?';

  @override
  String get accountSignOutBody =>
      'Vos chansons et listes restent sur cet appareil. Elles ne seront ni sauvegardées ni synchronisées avant votre prochaine connexion.';

  @override
  String get accountUseDifferent => 'Utiliser un autre compte';

  @override
  String get accountSignInAgain => 'Se reconnecter';

  @override
  String get accountChooseAction => 'Choisissez comment continuer';

  @override
  String get accountChangedTitle => 'Autre compte Google';

  @override
  String get accountChangedBody =>
      'Cet appareil a été synchronisé pour la dernière fois avec un autre compte Google. Choisissez ce qu’il adviendra des chansons et listes présentes sur cet appareil.';

  @override
  String get accountChangedMerge => 'Fusionner avec le nouveau compte';

  @override
  String get accountChangedMergeHint =>
      'Conservez tout sur cet appareil et ajoutez-le au nouveau compte.';

  @override
  String get accountChangedReplace =>
      'Remplacer par la bibliothèque du nouveau compte';

  @override
  String get accountChangedReplaceHint =>
      'Les chansons de cet appareil absentes du nouveau compte seront supprimées.';

  @override
  String get accountChangedSignOut => 'Annuler et se déconnecter';

  @override
  String get accountStatusSignedOut =>
      'Compte et synchronisation : non connecté';

  @override
  String get accountStatusSignedIn => 'Compte et synchronisation : connecté';

  @override
  String get accountStatusSyncing =>
      'Compte et synchronisation : synchronisation en cours';

  @override
  String get accountStatusSynced =>
      'Compte et synchronisation : bibliothèque à jour';

  @override
  String get accountStatusError =>
      'Compte et synchronisation : problème, touchez pour examiner';

  @override
  String get accountNoticeConflicts =>
      'Certaines chansons ont été modifiées à deux endroits. Des copies ont été conservées.';

  @override
  String get accountNoticeSignedIn => 'Connecté.';

  @override
  String get accountNoticeSignedOut =>
      'Déconnecté. Vos chansons restent sur cet appareil.';

  @override
  String get syncErrorNotConfigured =>
      'La synchronisation n’est pas configurée dans cette version.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Utilisez une version de Singbook configurée pour la connexion Google.';

  @override
  String get syncErrorNotSignedIn => 'Vous n’êtes pas connecté.';

  @override
  String get syncErrorNotSignedInHint =>
      'Connectez-vous pour synchroniser votre bibliothèque.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google vous demande de vous reconnecter.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Reconnectez-vous pour reprendre la synchronisation. Vos chansons sont en sécurité sur cet appareil.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook n’a pas l’autorisation d’utiliser Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Reconnectez-vous et autorisez l’accès à Drive lorsque cela vous est demandé.';

  @override
  String get syncErrorRateLimited => 'Google limite actuellement les requêtes.';

  @override
  String get syncErrorRateLimitedHint =>
      'Attendez quelques minutes, puis réessayez.';

  @override
  String get syncErrorStorageFull => 'Votre Google Drive est plein.';

  @override
  String get syncErrorStorageFullHint =>
      'Libérez de l’espace dans Drive, puis réessayez.';

  @override
  String get syncErrorNetwork => 'Impossible de joindre Google.';

  @override
  String get syncErrorNetworkHint =>
      'Vérifiez votre connexion Internet et réessayez.';

  @override
  String get syncErrorAccountChanged => 'Un autre compte Google a été utilisé.';

  @override
  String get syncErrorAccountChangedHint =>
      'Choisissez de fusionner la bibliothèque de cet appareil avec ce compte ou de la remplacer.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Votre bibliothèque synchronisée dépasse la capacité de Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Retirez des chansons ou des listes de la bibliothèque synchronisée, puis réessayez.';

  @override
  String get syncErrorSignInFailed => 'La connexion n’a pas abouti.';

  @override
  String get syncErrorSignInFailedHint => 'Essayez de vous reconnecter.';

  @override
  String get syncErrorGeneric =>
      'Impossible de synchroniser votre bibliothèque.';

  @override
  String get syncErrorGenericHint =>
      'Réessayez dans un instant. Vos chansons restent en sécurité sur cet appareil.';

  @override
  String get editorDurationInvalid =>
      'Saisissez des secondes, ou des minutes et secondes, par exemple 3:45.';

  @override
  String get editorNumberInvalid => 'Saisissez un nombre.';

  @override
  String get accountReplaceConfirmTitle => 'Supprimer les chansons locales ?';

  @override
  String get accountReplaceConfirmBody =>
      'Les chansons et listes de cet appareil qui ne figurent pas dans le nouveau compte seront supprimées définitivement. Cette action est irréversible.';

  @override
  String get accountReplaceConfirmAction => 'Supprimer et remplacer';

  @override
  String get accountSuspiciousTitle => 'Éléments manquants dans Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count éléments précédemment synchronisés depuis cet appareil sont absents de Google Drive.',
      one:
          'Un élément précédemment synchronisé depuis cet appareil est absent de Google Drive.',
    );
    return '$_temp0 Cela peut se produire si les données de l’application ont été effacées dans les paramètres Google. Rien n’a encore été supprimé.';
  }

  @override
  String get accountSuspiciousDelete => 'Les supprimer aussi ici';

  @override
  String get accountSuspiciousKeep =>
      'Garder mes chansons et les envoyer à nouveau';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $count éléments de cet appareil ?',
      one: 'Supprimer $count élément de cet appareil ?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Ces chansons et listes seront définitivement supprimées de cet appareil. Cette action est irréversible.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Supprimer de cet appareil';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Des éléments sont manquants dans Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Rien n’a été supprimé. Choisissez de les supprimer aussi ici ou de les envoyer à nouveau.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive a changé pendant la synchronisation.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Aucune donnée n’a été perdue. Synchronisez à nouveau pour récupérer les dernières modifications.';

  @override
  String get syncErrorInvalidLocalData =>
      'Certaines données de cet appareil n’ont pas pu être synchronisées.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Une chanson ou une liste n’a pas pu être lue. Importez-la ou recréez-la, puis relancez la synchronisation.';

  @override
  String get syncErrorNoAccountChange =>
      'Aucun changement de compte n’est à résoudre.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Synchronisez à nouveau pour continuer.';

  @override
  String get accountSyncWarningTitle =>
      'Synchronisation effectuée, mais certains fichiers ont été ignorés';

  @override
  String get accountSyncWarningBody =>
      'Certains fichiers n’ont pas pu être utilisés et ont été laissés tels quels. Tout le reste est à jour.';

  @override
  String get accountSyncWarningTooLarge =>
      'Un fichier était trop volumineux pour être synchronisé et a été ignoré. Tout le reste est à jour.';

  @override
  String get accountSyncWarningInvalid =>
      'Un fichier n’a pas pu être lu et a été ignoré. Tout le reste est à jour.';

  @override
  String get accountNoticeSyncSkipped =>
      'Synchronisation effectuée. Certains fichiers ont été ignorés.';

  @override
  String get settingsExportPdfTooLarge =>
      'Ce PDF serait trop volumineux. Essayez avec moins de chansons ou partagez-le au format texte.';

  @override
  String get settingsTimingTooLarge =>
      'Les données de minutage sont trop volumineuses (plus de 3 Mo).';

  @override
  String get settingsImportDuplicateSongId =>
      'Cette sauvegarde contient deux fois la même chanson ; rien n’a donc été importé.';

  @override
  String get setlistSaveConflict =>
      'La liste a été modifiée ailleurs. Vos changements ont été enregistrés dans une copie séparée.';

  @override
  String get sectionVerse => 'Couplet';

  @override
  String get sectionChorus => 'Refrain';

  @override
  String get sectionBridge => 'Pont';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pré-refrain';

  @override
  String get sectionPostChorus => 'Post-refrain';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Interlude';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Reprise';

  @override
  String get sectionHook => 'Accroche';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Fin';

  @override
  String get youtubeConsentHint =>
      'Fonction expérimentale. Choisissez vos cookies sur la page de Google pour essayer la recherche de paroles. Vous n\'avez pas besoin de vous connecter à un compte Google. Votre choix reste sur cet appareil.';

  @override
  String get youtubeConsentOpen => 'Examiner le consentement Google';

  @override
  String get youtubeConsentSaved => 'Consentement enregistré';

  @override
  String get youtubeConsentClear => 'Effacer le consentement';

  @override
  String get youtubeConsentInstructions =>
      'Terminez votre choix de cookies et attendez le retour de YouTube Music. Enregistrez ensuite cette session et relancez la recherche du morceau.';

  @override
  String get youtubeConsentError =>
      'Impossible de mettre à jour votre choix de consentement Google. Réessayez.';

  @override
  String get youtubeConsentBlocked =>
      'Seuls YouTube Music et la page de consentement de Google peuvent s\'ouvrir ici. La connexion à un compte n\'est pas disponible.';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versions disponibles',
      one: '1 version disponible',
      zero: '0 Versions disponibles',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versions indisponibles',
      one: '1 version indisponible',
      zero: '0 Versions indisponibles',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Aller à la section';

  @override
  String get searchVersionDetails => 'Détails de la version';

  @override
  String get searchSelectedRecording => 'Enregistrement sélectionné';

  @override
  String get searchVersionDuration => 'Durée de la version';

  @override
  String get searchSourceOptions => 'Options de la source';
}
