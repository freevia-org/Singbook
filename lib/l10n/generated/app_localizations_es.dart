// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Un lugar tranquilo para encontrar, organizar y cantar con tu biblioteca de canciones.';

  @override
  String get aboutMadeForSinging => 'Creada para cantar juntos';

  @override
  String appVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get navHome => 'Inicio';

  @override
  String get navSongs => 'Canciones';

  @override
  String get navSetlists => 'Listas de canciones';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navSettingsCompact => 'Ajustes';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navBack => 'Atrás';

  @override
  String get navClose => 'Cerrar';

  @override
  String get navMore => 'Más acciones';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionDone => 'Listo';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionShare => 'Compartir';

  @override
  String get actionPrint => 'Imprimir';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionClear => 'Borrar';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionRefresh => 'Actualizar';

  @override
  String get actionImport => 'Importar';

  @override
  String get actionExport => 'Exportar';

  @override
  String get actionExpand => 'Expandir';

  @override
  String get actionCollapse => 'Contraer';

  @override
  String get actionAdd => 'Añadir';

  @override
  String get actionCreate => 'Crear';

  @override
  String get actionRemove => 'Quitar';

  @override
  String get actionDuplicate => 'Duplicar';

  @override
  String get actionMoveUp => 'Subir';

  @override
  String get actionMoveDown => 'Bajar';

  @override
  String get actionPrevious => 'Anterior';

  @override
  String get actionNext => 'Siguiente';

  @override
  String get searchHint => 'Busca canciones, artistas o letras';

  @override
  String get searchCatalogHint => 'Busca una canción o un artista';

  @override
  String get searchChangeSong => 'Cambiar canción';

  @override
  String get searchSelectedPreview => 'Vista previa seleccionada';

  @override
  String get searchSubmit => 'Buscar';

  @override
  String get searchFilters => 'Opciones de búsqueda';

  @override
  String get searchFiltersShow => 'Mostrar opciones de búsqueda';

  @override
  String get searchFiltersHide => 'Ocultar opciones de búsqueda';

  @override
  String get searchFilterArtist => 'Artista';

  @override
  String get searchFilterTitle => 'Título de la canción';

  @override
  String get searchFilterLyrics => 'Letras';

  @override
  String get searchFilterChords => 'Con acordes';

  @override
  String get searchFilterTimed => 'Letras sincronizadas';

  @override
  String get searchFilterLanguage => 'Idioma';

  @override
  String get searchFilterAll => 'Cualquiera';

  @override
  String get searchAutocompleteLabel => 'Sugerencias';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: 'No hay resultados',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Introduce una canción, un artista o una letra para buscar.';

  @override
  String get searchCatalogEmptyQuery =>
      'Introduce una canción o un artista para buscar.';

  @override
  String get searchNoResults =>
      'No se han encontrado canciones. Prueba otra búsqueda.';

  @override
  String get searchLoading => 'Buscando canciones…';

  @override
  String get searchError => 'No se ha podido completar la búsqueda.';

  @override
  String get searchOnlineTab => 'En línea';

  @override
  String get searchRecentTab => 'Recientes';

  @override
  String get searchFavoritesTab => 'Favoritos';

  @override
  String get searchSuggested => 'Coincidencia sugerida';

  @override
  String get searchAlternatives => 'Otras coincidencias';

  @override
  String get searchCompare => 'Comparar versiones';

  @override
  String get searchChooseVersion => 'Elegir esta versión';

  @override
  String get searchFullPreview => 'Vista previa completa';

  @override
  String get searchArrangementNotes => 'Notas del arreglo';

  @override
  String get searchOpenLyrics => 'Abrir letra';

  @override
  String get searchContributions => 'Fuentes utilizadas';

  @override
  String get searchVersionChecking => 'Comprobando esta versión…';

  @override
  String get searchVersionUnavailable =>
      'No se puede usar esta versión. Elige otra versión.';

  @override
  String get searchPreviewUnavailable => 'No hay vista previa de la letra.';

  @override
  String get searchSongMatch => 'Coincidencia de canción';

  @override
  String get searchRecordingMatch => 'Coincidencia de grabación';

  @override
  String get searchMatchUnverified => 'Grabación sin verificar';

  @override
  String get searchMatchExact => 'Coincidencia exacta de grabación';

  @override
  String get searchMatchPossible => 'Posible coincidencia';

  @override
  String get searchAvailability => 'Disponibilidad';

  @override
  String get searchLyricsAvailable => 'Letra disponible';

  @override
  String get searchLyricsUnavailable => 'Letra no disponible';

  @override
  String get searchChordsAvailable => 'Acordes disponibles';

  @override
  String get searchChordsUnavailable => 'Sin acordes';

  @override
  String get searchTimingAvailable => 'Sincronización disponible';

  @override
  String get searchTimingUnavailable => 'Sin sincronización';

  @override
  String get searchDurationUnknown => 'Duración desconocida';

  @override
  String searchRating(String rating) {
    return 'Valoración $rating';
  }

  @override
  String get searchSourceLabel => 'Fuente';

  @override
  String get searchMetadata => 'Detalles de la canción';

  @override
  String get searchAlbum => 'Álbum';

  @override
  String get searchArtist => 'Artista';

  @override
  String get searchYear => 'Año';

  @override
  String get searchLanguage => 'Idioma';

  @override
  String get searchViewVersions => 'Ver versiones';

  @override
  String get searchSaved => 'Canción guardada en tu biblioteca.';

  @override
  String get searchSaveOpenLyrics => 'Guardar y abrir la letra';

  @override
  String get searchOtherResults => 'Otros resultados';

  @override
  String get searchSaveFailed => 'No se ha podido guardar la canción.';

  @override
  String get homeRecentSongs => 'Canciones recientes';

  @override
  String get homeRecentlyPlayed => 'Reproducidas recientemente';

  @override
  String get homeFavorites => 'Favoritos';

  @override
  String get homeHistory => 'Historial';

  @override
  String get homeHistoryClear => 'Borrar historial';

  @override
  String get homeHistoryCleared => 'Historial borrado.';

  @override
  String get homeHistoryEmpty => 'Aquí aparecerán las canciones que abras.';

  @override
  String get homeFavoritesEmpty =>
      'Aquí aparecerán tus canciones y listas favoritas.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos mostrados',
      one: '1 elemento mostrado',
      zero: '0 elementos mostrados',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Aquí aparecerán tus canciones y listas recientes.';

  @override
  String get homeTimelineLabel => 'Cronología del historial';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Todo el historial';

  @override
  String get homeShowFavorites => 'Mostrar favoritos';

  @override
  String get homeShowRecent => 'Mostrar recientes';

  @override
  String get songsTitle => 'Canciones';

  @override
  String get songsEmpty => 'Aquí aparecerán tus canciones.';

  @override
  String get songsEmptySearch => 'Ninguna canción coincide con tu búsqueda.';

  @override
  String get songsAdd => 'Añadir canción';

  @override
  String get songsSortAlphabetical => 'Ordenar alfabéticamente';

  @override
  String get songsAlphabetNavigation => 'Índice de canciones';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veces',
      one: 'una vez',
      zero: 'nunca',
    );
    return 'Abierta $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Añadir a favoritos';

  @override
  String get songFavoriteRemove => 'Quitar de favoritos';

  @override
  String get songMenuLabel => 'Acciones de la canción';

  @override
  String get songInfo => 'Detalles de la canción';

  @override
  String get setlistMenuLabel => 'Acciones de la lista';

  @override
  String get songAddToSetlist => 'Añadir a la lista';

  @override
  String get songCopyChordPro => 'Copiar ChordPro';

  @override
  String get songDeleteConfirmTitle => '¿Eliminar canción?';

  @override
  String get songDeleteConfirmMessage =>
      'Esta canción se quitará de tu biblioteca.';

  @override
  String get songDeleted => 'Canción eliminada.';

  @override
  String get setlistsTitle => 'Listas de canciones';

  @override
  String get setlistsEmpty =>
      'Crea una lista para tu próximo ensayo o actuación.';

  @override
  String get setlistsEmptySearch => 'Ninguna lista coincide con tu búsqueda.';

  @override
  String get setlistCreate => 'Nueva lista de canciones';

  @override
  String get setlistNameHint => 'Nombre de la lista';

  @override
  String get setlistNotes => 'Notas';

  @override
  String get setlistEntryOverride =>
      'Tonalidad y cejilla específicas de la canción';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
      zero: 'No hay canciones',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Al menos $duration';
  }

  @override
  String get setlistDurationUnknown => 'Duración desconocida';

  @override
  String setlistActivity(String date) {
    return 'Última actividad: $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Creada el $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Editada el $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Reproducida por última vez el $date';
  }

  @override
  String get setlistSongsEmpty => 'Esta lista aún no tiene canciones.';

  @override
  String get setlistAddSongs => 'Añadir canciones';

  @override
  String get setlistReorder => 'Reordenar canciones';

  @override
  String setlistMoveSongUp(String song) {
    return 'Subir $song';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Bajar $song';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Quitar $song de la lista';
  }

  @override
  String get setlistDuplicate => 'Duplicar lista';

  @override
  String get setlistFavoriteAdd => 'Añadir lista a favoritos';

  @override
  String get setlistFavoriteRemove => 'Quitar lista de favoritos';

  @override
  String get setlistShare => 'Compartir como archivo de lista';

  @override
  String get setlistSharePdf => 'Compartir como PDF';

  @override
  String get setlistPrint => 'Imprimir';

  @override
  String get setlistDeleteConfirmTitle => '¿Eliminar lista?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Se quitará la lista. Las canciones de tu biblioteca se conservarán.';

  @override
  String get setlistDeleted => 'Lista eliminada.';

  @override
  String get readerTitle => 'Letras';

  @override
  String get readerNoLyrics => 'Todavía no se han añadido letras.';

  @override
  String get readerShowChords => 'Mostrar acordes';

  @override
  String get readerHideChords => 'Ocultar acordes';

  @override
  String get readerTranspose => 'Transportar acordes';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semitonos',
      one: '1 semitono',
      zero: '0 semitonos',
    );
    return 'Transportar $_temp0';
  }

  @override
  String get readerSaved => 'Guardado';

  @override
  String get readerEdit => 'Editar letras y detalles';

  @override
  String get playerPlay => 'Iniciar desplazamiento de letras';

  @override
  String get playerPause => 'Pausar desplazamiento de letras';

  @override
  String get playerResume => 'Reanudar desplazamiento de letras';

  @override
  String get playerSeek => 'Posición de reproducción';

  @override
  String playerElapsed(String time) {
    return 'Tiempo transcurrido: $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Tiempo restante: $time';
  }

  @override
  String get playerTimingMode => 'Modo de desplazamiento';

  @override
  String get playerTimedLyrics => 'Letras sincronizadas';

  @override
  String get playerStartScroll => 'Iniciar desplazamiento automático';

  @override
  String get playerEstimatedPace => 'Ritmo estimado';

  @override
  String get playerScrollSpeed => 'Velocidad de desplazamiento';

  @override
  String playerEstimatedDuration(String time) {
    return 'Duración estimada: $time';
  }

  @override
  String get playerLyricsOnly => 'Desplazamiento de letra · sin audio';

  @override
  String get playerManualScroll => 'Desplazamiento manual';

  @override
  String get playerTimingStatusReady =>
      'Las letras seguirán la sincronización disponible.';

  @override
  String get playerTimingStatusEstimated =>
      'La velocidad de desplazamiento se estima según la duración de la canción.';

  @override
  String get playerTimingStatusManual => 'Desplaza las letras manualmente.';

  @override
  String get playerTimingStatusUnavailable =>
      'El desplazamiento sincronizado no está disponible para esta canción.';

  @override
  String get playerDurationUnknown =>
      'Añade la duración de la canción para usar el desplazamiento estimado.';

  @override
  String get playerProgressLabel => 'Progreso de la canción';

  @override
  String get playerCurrentSection => 'Sección actual';

  @override
  String get playerPreviousSection => 'Sección anterior';

  @override
  String get playerNextSection => 'Sección siguiente';

  @override
  String get playerPreviousSectionSong =>
      'Sección anterior · mantén pulsado para ir a la canción anterior de la lista';

  @override
  String get playerNextSectionSong =>
      'Sección siguiente · mantén pulsado para ir a la canción siguiente de la lista';

  @override
  String get playerPreviousSong => 'Canción anterior';

  @override
  String get playerNextSong => 'Canción siguiente';

  @override
  String get editorTitle => 'Editar canción';

  @override
  String get editorTitleField => 'Título de la canción';

  @override
  String get editorArtistField => 'Artista';

  @override
  String get editorAlbumField => 'Álbum';

  @override
  String get editorLyricsField => 'Letra';

  @override
  String get editorChordsField => 'Acordes';

  @override
  String get editorKeyField => 'Tonalidad';

  @override
  String get editorCapoField => 'Cejilla';

  @override
  String get editorTuningField => 'Afinación';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Duración';

  @override
  String get editorTimeSignatureField => 'Compás';

  @override
  String get editorLanguageField => 'Idioma';

  @override
  String get editorYearField => 'Año';

  @override
  String get editorComposerField => 'Compositor';

  @override
  String get editorLyricistField => 'Autor de la letra';

  @override
  String get editorCopyrightField => 'Derechos de autor';

  @override
  String get editorLicenseField => 'Licencia';

  @override
  String get songInfoSources => 'Fuentes y créditos';

  @override
  String get searchMatchSameSong => 'La misma canción; grabación sin confirmar';

  @override
  String get searchMatchNeedsAgreement =>
      'La letra de la hoja de acordes debe confirmarse';

  @override
  String get searchMatchDifferentLyrics =>
      'La letra no coincide con la canción seleccionada';

  @override
  String get searchMatchCombinedSources =>
      'Detalles combinados de varias fuentes';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Combinado de $count fuentes',
      one: 'Combinado de 1 fuente',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coincidencias de canciones',
      one: '1 coincidencia de canción',
      zero: '0 coincidencias de canciones',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versiones de fuentes',
      one: '1 versión de fuente',
      zero: '0 versiones de fuentes',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Mejor coincidencia disponible';

  @override
  String get providerDescriptionUnknown => 'Fuente de canciones';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Descarga un archivo ChordPro de la fuente y luego impórtalo.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Descarga el archivo con una cuenta gratuita y luego impórtalo.';

  @override
  String get providerDescPublicChordSheets => 'Hojas de acordes públicas.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Letras históricas con licencia por obra.';

  @override
  String get providerDescLicensedCatalog => 'Catálogo de letras con licencia.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Canciones originales con licencia Creative Commons BY.';

  @override
  String get providerDescPerSongLicense => 'Letras con licencia por canción.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Solo detalles de grabaciones y lanzamientos.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Solo detalles de composiciones.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Portadas solo para coincidencias exactas de grabación.';

  @override
  String get providerCapabilityLyrics => 'Letras';

  @override
  String get providerCapabilityChords => 'Acordes';

  @override
  String get providerCapabilityTiming => 'Letras sincronizadas';

  @override
  String get providerCapabilitySearch => 'Búsqueda';

  @override
  String get providerCapabilityMetadata => 'Detalles de la canción';

  @override
  String get editorArtworkField => 'Enlace a la portada';

  @override
  String get editorLyricsHint =>
      'Toca una línea para editar la letra o los acordes.';

  @override
  String get editorSave => 'Guardar cambios';

  @override
  String get editorSaved => 'Cambios guardados.';

  @override
  String get editorSaveFailed => 'No se han podido guardar los cambios.';

  @override
  String get editorSaveConflict =>
      'La canción se modificó en otro lugar. Tus cambios se guardaron como una copia independiente.';

  @override
  String get editorUnsavedTitle => '¿Descartar cambios?';

  @override
  String get editorUnsavedMessage => 'No se han guardado tus cambios.';

  @override
  String get editorFieldRequired => 'Introduce el título de la canción.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Usar ajuste del dispositivo';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsColorPalette => 'Paleta de colores';

  @override
  String get settingsFont => 'Fuente';

  @override
  String get settingsTextSize => 'Tamaño del texto';

  @override
  String get settingsLyricsPreview => 'Vista previa de la letra';

  @override
  String get settingsPlayer => 'Reproductor de letras';

  @override
  String get settingsDefaultShowChords =>
      'Mostrar acordes de forma predeterminada';

  @override
  String get settingsDefaultAutoscroll =>
      'Desplazar las letras automáticamente';

  @override
  String get settingsDefaultTiming => 'Modo de desplazamiento predeterminado';

  @override
  String get settingsLanguage => 'Idioma de la aplicación';

  @override
  String get settingsLanguageSystem => 'Usar idioma del dispositivo';

  @override
  String get settingsLanguageEnglish => 'Inglés';

  @override
  String get settingsLanguageBulgarian => 'Búlgaro';

  @override
  String get settingsLanguageUkrainian => 'Ucraniano';

  @override
  String get settingsSources => 'Fuentes de letras';

  @override
  String settingsSourceEnabled(String source) {
    return 'Activar fuente $source';
  }

  @override
  String get settingsSourceRefresh => 'Actualizar lista de fuentes';

  @override
  String get settingsSourcesUpdated => 'Fuentes actualizadas.';

  @override
  String get settingsSourcesUpdateFailed =>
      'No se han podido actualizar las fuentes.';

  @override
  String get settingsImport => 'Importar canciones';

  @override
  String get settingsImportChordPro => 'Importar archivo ChordPro';

  @override
  String get settingsImportSetlist => 'Importar archivo de lista';

  @override
  String get settingsImportSuccess => 'Importación completada.';

  @override
  String get settingsImportFailed => 'No se ha podido importar este archivo.';

  @override
  String get settingsImportUnsupported =>
      'Este tipo de archivo no es compatible.';

  @override
  String get settingsShareSong => 'Compartir como ChordPro';

  @override
  String get settingsSharePdf => 'Compartir como PDF';

  @override
  String get settingsCopySong => 'Copiar al portapapeles';

  @override
  String get settingsPrintSong => 'Imprimir solo la canción';

  @override
  String get settingsPrintSetlist => 'Imprimir lista con letras';

  @override
  String get settingsExportFailed => 'No se ha podido preparar el archivo.';

  @override
  String get settingsCopied => 'Copiado al portapapeles.';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsPrivacy => 'Privacidad';

  @override
  String get settingsLegal => 'Legal';

  @override
  String get settingsClearHistory => 'Borrar historial';

  @override
  String get settingsClearHistoryConfirm =>
      '¿Borrar el historial de canciones y listas?';

  @override
  String get settingsHistoryCleared => 'Historial borrado.';

  @override
  String get accountTitle => 'Cuenta y sincronización';

  @override
  String get accountUnavailable =>
      'La sincronización requiere una versión de Singbook configurada para iniciar sesión con Google. Esta versión solo guarda tus canciones en este dispositivo.';

  @override
  String get accountSyncNow => 'Sincronizar ahora';

  @override
  String get accountConnected =>
      'Conectado. Elige «Sincronizar ahora» para actualizar la copia de seguridad.';

  @override
  String get accountSignIn => 'Conectar cuenta';

  @override
  String get accountSignOut => 'Cerrar sesión';

  @override
  String get accountChange => 'Cambiar cuenta';

  @override
  String get accountSignedOut => 'Desconectado';

  @override
  String get accountSyncing => 'Sincronizando tu biblioteca…';

  @override
  String get accountSynced => 'Biblioteca sincronizada.';

  @override
  String get accountSyncFailed => 'No se ha podido sincronizar tu biblioteca.';

  @override
  String get accessibilityFavorite => 'Favorito';

  @override
  String get accessibilityNotFavorite => 'No es favorito';

  @override
  String get accessibilitySearchField => 'Buscar canciones';

  @override
  String get accessibilityClearSearch => 'Borrar texto de búsqueda';

  @override
  String accessibilitySongMenu(String song) {
    return 'Acciones para $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Acciones para $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Expandir canciones de $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Contraer canciones de $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Progreso de reproducción, $percent por ciento';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Cronología del historial, $date';
  }

  @override
  String get loading => 'Cargando…';

  @override
  String get loadingSongs => 'Cargando canciones…';

  @override
  String get loadingSetlists => 'Cargando listas…';

  @override
  String get errorGeneric => 'Se ha producido un error.';

  @override
  String get errorOffline => 'Parece que no tienes conexión.';

  @override
  String get errorPermission => 'Se necesita permiso para continuar.';

  @override
  String get emptyFiltered => 'Ningún elemento coincide con estos filtros.';

  @override
  String get unknownValue => 'Desconocido';

  @override
  String get durationUnknown => 'Duración desconocida';

  @override
  String get metadataNotSet => 'Sin establecer';

  @override
  String get dateToday => 'Hoy';

  @override
  String get dateYesterday => 'Ayer';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canciones',
      one: '1 canción',
      zero: 'No hay canciones',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Azul marino';

  @override
  String get settingsPaletteSage => 'Verde salvia';

  @override
  String get settingsPaletteOcean => 'Océano';

  @override
  String get settingsPaletteClay => 'Arcilla';

  @override
  String get settingsPalettePlum => 'Ciruela';

  @override
  String get settingsFontSystem => 'Sistema';

  @override
  String get settingsFontSerif => 'Con remates';

  @override
  String get settingsFontMonospace => 'Monoespaciada';

  @override
  String get settingsLyricsPreviewExample =>
      'Cuando llegue la mañana, volveremos a cantar.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Comprobando fuentes de letras: $checked de $total completadas.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'No se han encontrado letras utilizables.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Se ha comprobado la canción seleccionada en las fuentes activadas, pero ninguna proporcionó una versión de la letra utilizable.';

  @override
  String get searchDiscoveryError =>
      'No se han podido comprobar las fuentes de letras.';

  @override
  String get searchDiscoveryRetry => 'Volver a buscar letras';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fuentes no disponibles',
      one: '1 fuente no disponible',
      zero: '0 fuentes no disponibles',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails =>
      'Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get searchProviderChecks => 'Comprobaciones de fuentes';

  @override
  String get searchProviderPending => 'Comprobando';

  @override
  String get searchProviderFound => 'Coincidencia encontrada';

  @override
  String get searchProviderRejected => 'No coincide';

  @override
  String get searchProviderFailed => 'Error en la comprobación';

  @override
  String get searchProviderUnavailable => 'No hay letras utilizables';

  @override
  String get searchCatalogFilterHint =>
      'Selecciona una canción para filtrar las versiones de letras por acordes, sincronización o idioma.';

  @override
  String get startupErrorTitle => 'No se ha podido abrir tu biblioteca.';

  @override
  String setlistCopyName(String name) {
    return 'Copia de $name';
  }

  @override
  String get setlistSongMissing => 'Canción no encontrada';

  @override
  String get settingsImportTooLarge =>
      'Este archivo es demasiado grande para importarlo.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Ir a $letter';
  }

  @override
  String get actionDiscard => 'Descartar';

  @override
  String get editorKeepEditing => 'Seguir editando';

  @override
  String get settingsDefaultShowChordsHint =>
      'Mostrar los acordes encima de la letra cuando una canción los tenga.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Las letras se desplazan con la canción. No se usa en el modo de desplazamiento manual.';

  @override
  String get accountUnavailableTitle => 'Sincronización no configurada';

  @override
  String get accountSignedOutBenefits =>
      'Conecta Google Drive para guardar una copia de seguridad opcional de tus canciones y listas. No se subirá nada hasta que toques Sincronizar ahora.';

  @override
  String get accountManualSyncHint =>
      'La sincronización solo se realiza cuando tocas Sincronizar ahora.';

  @override
  String get accountSignInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get accountWorking => 'Procesando…';

  @override
  String get accountNeverSynced => 'Nunca sincronizada';

  @override
  String get accountSyncedJustNow => 'Sincronizada ahora mismo';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizada hace $count minutos',
      one: 'Sincronizada hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizada hace $count horas',
      one: 'Sincronizada hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizada hace $count días',
      one: 'Sincronizada hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambios en conflicto guardados como copias',
      one: '1 cambio en conflicto guardado como copia',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'La misma canción o lista se modificó en dos lugares. No se perdió nada: la otra versión se guardó como una copia independiente.';

  @override
  String get accountReviewConflicts => 'Revisar copias';

  @override
  String get songsConflictFilterActive => 'Mostrando solo copias en conflicto';

  @override
  String get songsConflictFilterClear => 'Mostrar todas las canciones';

  @override
  String get songsConflictBadge => 'Copia en conflicto';

  @override
  String get songsConflictEmpty => 'No hay copias en conflicto.';

  @override
  String get accountAutoSync => 'Sincronizar automáticamente';

  @override
  String get accountAutoSyncHint =>
      'Mantén tu biblioteca actualizada al abrir la aplicación y después de hacer cambios.';

  @override
  String get accountSignOutTitle => '¿Cerrar sesión en esta cuenta?';

  @override
  String get accountSignOutBody =>
      'Tus canciones y listas permanecen en este dispositivo. No se guardarán ni sincronizarán hasta que vuelvas a iniciar sesión.';

  @override
  String get accountUseDifferent => 'Usar otra cuenta';

  @override
  String get accountSignInAgain => 'Volver a iniciar sesión';

  @override
  String get accountChooseAction => 'Elige cómo continuar';

  @override
  String get accountChangedTitle => 'Otra cuenta de Google';

  @override
  String get accountChangedBody =>
      'La última sincronización de este dispositivo se hizo con otra cuenta de Google. Elige qué hacer con las canciones y listas de este dispositivo.';

  @override
  String get accountChangedMerge => 'Combinar con la cuenta nueva';

  @override
  String get accountChangedMergeHint =>
      'Conserva todo en este dispositivo y añádelo a la cuenta nueva.';

  @override
  String get accountChangedReplace =>
      'Sustituir por la biblioteca de la cuenta nueva';

  @override
  String get accountChangedReplaceHint =>
      'Se quitarán las canciones de este dispositivo que no estén en la cuenta nueva.';

  @override
  String get accountChangedSignOut => 'Cancelar y cerrar sesión';

  @override
  String get accountStatusSignedOut =>
      'Cuenta y sincronización: sesión cerrada';

  @override
  String get accountStatusSignedIn =>
      'Cuenta y sincronización: sesión iniciada';

  @override
  String get accountStatusSyncing => 'Cuenta y sincronización: sincronizando';

  @override
  String get accountStatusSynced =>
      'Cuenta y sincronización: biblioteca actualizada';

  @override
  String get accountStatusError =>
      'Cuenta y sincronización: problema, toca para revisar';

  @override
  String get accountNoticeConflicts =>
      'Algunas canciones se modificaron en dos lugares. Se conservaron copias.';

  @override
  String get accountNoticeSignedIn => 'Sesión iniciada.';

  @override
  String get accountNoticeSignedOut =>
      'Sesión cerrada. Tus canciones permanecen en este dispositivo.';

  @override
  String get syncErrorNotConfigured =>
      'La sincronización no está configurada en esta versión.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Usa una versión de Singbook configurada para iniciar sesión con Google.';

  @override
  String get syncErrorNotSignedIn => 'No has iniciado sesión.';

  @override
  String get syncErrorNotSignedInHint =>
      'Inicia sesión para sincronizar tu biblioteca.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google necesita que vuelvas a iniciar sesión.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Vuelve a iniciar sesión para continuar la sincronización. Tus canciones están a salvo en este dispositivo.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook no tiene permiso para usar Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Vuelve a iniciar sesión y permite el acceso a Drive cuando se te solicite.';

  @override
  String get syncErrorRateLimited =>
      'Google está limitando las solicitudes por ahora.';

  @override
  String get syncErrorRateLimitedHint =>
      'Espera unos minutos e inténtalo de nuevo.';

  @override
  String get syncErrorStorageFull => 'Tu Google Drive está lleno.';

  @override
  String get syncErrorStorageFullHint =>
      'Libera espacio en Drive e inténtalo de nuevo.';

  @override
  String get syncErrorNetwork => 'No se ha podido conectar con Google.';

  @override
  String get syncErrorNetworkHint =>
      'Comprueba tu conexión a Internet e inténtalo de nuevo.';

  @override
  String get syncErrorAccountChanged => 'Se ha usado otra cuenta de Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Elige si quieres combinar con ella la biblioteca de este dispositivo o sustituirla.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Tu biblioteca sincronizada es demasiado grande para Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Quita algunas canciones o listas de la biblioteca sincronizada e inténtalo de nuevo.';

  @override
  String get syncErrorSignInFailed =>
      'No se ha completado el inicio de sesión.';

  @override
  String get syncErrorSignInFailedHint => 'Intenta iniciar sesión de nuevo.';

  @override
  String get syncErrorGeneric => 'No se ha podido sincronizar tu biblioteca.';

  @override
  String get syncErrorGenericHint =>
      'Vuelve a intentarlo dentro de un momento. Tus canciones siguen a salvo en este dispositivo.';

  @override
  String get editorDurationInvalid =>
      'Introduce segundos o minutos y segundos, por ejemplo 3:45.';

  @override
  String get editorNumberInvalid => 'Introduce un número.';

  @override
  String get accountReplaceConfirmTitle => '¿Eliminar las canciones locales?';

  @override
  String get accountReplaceConfirmBody =>
      'Las canciones y listas de este dispositivo que no estén en la cuenta nueva se eliminarán de forma permanente. No se puede deshacer.';

  @override
  String get accountReplaceConfirmAction => 'Eliminar y reemplazar';

  @override
  String get accountSuspiciousTitle => 'Faltan elementos en Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Faltan $count elementos que este dispositivo había sincronizado anteriormente en Google Drive.',
      one:
          'Falta 1 elemento que este dispositivo había sincronizado anteriormente en Google Drive.',
    );
    return '$_temp0 Esto puede ocurrir si se borraron los datos de la aplicación en los ajustes de Google. Todavía no se ha eliminado nada.';
  }

  @override
  String get accountSuspiciousDelete => 'Eliminarlos también aquí';

  @override
  String get accountSuspiciousKeep =>
      'Conservar mis canciones y volver a subirlas';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count elementos de este dispositivo?',
      one: '¿Eliminar $count elemento de este dispositivo?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Estas canciones y listas se eliminarán permanentemente de este dispositivo. Esta acción no se puede deshacer.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Eliminar de este dispositivo';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Faltan elementos en Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'No se ha eliminado nada. Elige si quieres eliminarlos también aquí o volver a subirlos.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive ha cambiado durante la sincronización.';

  @override
  String get syncErrorRemoteChangedHint =>
      'No se ha perdido nada. Vuelve a sincronizar para obtener los cambios más recientes.';

  @override
  String get syncErrorInvalidLocalData =>
      'No se han podido sincronizar algunos datos de este dispositivo.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'No se ha podido leer una canción o una lista. Impórtala o créala de nuevo y vuelve a sincronizar.';

  @override
  String get syncErrorNoAccountChange =>
      'No hay ningún cambio de cuenta que resolver.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Vuelve a sincronizar para continuar.';

  @override
  String get accountSyncWarningTitle =>
      'Sincronizado, pero se omitieron algunos archivos';

  @override
  String get accountSyncWarningBody =>
      'No se pudieron usar algunos archivos y se dejaron tal como estaban. Todo lo demás está actualizado.';

  @override
  String get accountSyncWarningTooLarge =>
      'Un archivo era demasiado grande para sincronizarlo y se omitió. Todo lo demás está actualizado.';

  @override
  String get accountSyncWarningInvalid =>
      'No se pudo leer un archivo y se omitió. Todo lo demás está actualizado.';

  @override
  String get accountNoticeSyncSkipped =>
      'Sincronizado. Se omitieron algunos archivos.';

  @override
  String get settingsExportPdfTooLarge =>
      'Este PDF sería demasiado grande. Prueba con menos canciones o compártelo como texto.';

  @override
  String get settingsTimingTooLarge =>
      'Los datos de tiempos son demasiado grandes (más de 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Esta copia de seguridad incluye la misma canción dos veces, así que no se ha importado nada.';

  @override
  String get setlistSaveConflict =>
      'La lista cambió en otro lugar. Tus cambios se guardaron como una copia aparte.';

  @override
  String get sectionVerse => 'Estrofa';

  @override
  String get sectionChorus => 'Estribillo';

  @override
  String get sectionBridge => 'Puente';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pre-estribillo';

  @override
  String get sectionPostChorus => 'Post-estribillo';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Interludio';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Refrán';

  @override
  String get sectionHook => 'Gancho';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Coletilla';

  @override
  String get sectionEnding => 'Final';

  @override
  String get youtubeConsentHint =>
      'Experimental. Elige tus cookies en la página de Google para probar la búsqueda de letras. No necesitas iniciar sesión en una cuenta de Google. Tu elección se guarda en este dispositivo.';

  @override
  String get youtubeConsentOpen => 'Revisar el consentimiento de Google';

  @override
  String get youtubeConsentSaved => 'Consentimiento guardado';

  @override
  String get youtubeConsentClear => 'Borrar consentimiento';

  @override
  String get youtubeConsentInstructions =>
      'Completa tu elección de cookies y espera a que vuelva YouTube Music. Después, guarda esta sesión y vuelve a buscar la canción.';

  @override
  String get youtubeConsentError =>
      'No se pudo actualizar tu elección de consentimiento de Google. Inténtalo de nuevo.';

  @override
  String get youtubeConsentBlocked =>
      'Aquí solo se pueden abrir YouTube Music y la página de consentimiento de Google. No se puede iniciar sesión en una cuenta.';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versiones disponibles',
      one: '1 versión disponible',
      zero: '0 Versiones disponibles',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versiones no disponibles',
      one: '1 versión no disponible',
      zero: '0 Versiones no disponibles',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Ir a la sección';

  @override
  String get searchVersionDetails => 'Detalles de la versión';

  @override
  String get searchSelectedRecording => 'Grabación seleccionada';

  @override
  String get searchVersionDuration => 'Duración de la versión';

  @override
  String get searchSourceOptions => 'Opciones de la fuente';
}
