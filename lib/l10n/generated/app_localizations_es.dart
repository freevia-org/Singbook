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
      'Tus letras, acordes y listas de canciones, juntos y listos para ensayar, subir al escenario y tocar donde quieras.';

  @override
  String get aboutMadeForSinging => 'Cada canción, lista.';

  @override
  String get aboutDetails =>
      'Busca en las fuentes habilitadas y compara letras, acordes, tiempos y detalles de grabación antes de guardar la versión que quieres tocar. La disponibilidad depende de la canción y del servicio.';

  @override
  String get aboutFindTitle => 'Encuentra la versión adecuada';

  @override
  String get aboutKeepTitle => 'Crea tu propia biblioteca';

  @override
  String get aboutKeepDetails =>
      'Edita y transpón canciones, consérvalas en tu biblioteca local para usarlas sin conexión y comparte archivos ChordPro portátiles. La sincronización opcional con Google Drive utiliza una carpeta privada de la aplicación en tu cuenta de Google. También puedes tocar Sincronizar ahora para actualizar tus dispositivos.';

  @override
  String get aboutPlayTitle => 'Lleva tu lista al escenario';

  @override
  String get aboutPlayDetails =>
      'Ordena canciones en listas, elige una tonalidad para cada canción y comparte listas de OpenSong. Ajusta el texto del lector, el desplazamiento automático de las letras e imprime PDF de canciones. Singbook no transmite ni reproduce audio.';

  @override
  String get aboutPrivacyTitle => 'Gratis y centrada en el uso local';

  @override
  String get aboutPrivacyDetails =>
      'Singbook es gratis, sin anuncios, analíticas ni compras dentro de la aplicación. Tu biblioteca guardada permanece en el dispositivo; la sincronización opcional usa tu propio Google Drive. Los resultados en línea proceden directamente de servicios independientes de terceros y pueden no estar disponibles o estar protegidos por derechos de autor. Singbook no aloja su contenido.';

  @override
  String get aboutWebsite => 'Web de Singbook';

  @override
  String get aboutSourceCode => 'Código fuente en GitHub';

  @override
  String get aboutPublisher => 'De Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Idiomas de la aplicación: $count';
  }

  @override
  String get aboutSupport => 'Ayuda y comentarios';

  @override
  String get menuTypeNewSong => 'Escribir una canción nueva';

  @override
  String get menuFile => 'Archivo';

  @override
  String get menuNewSong => 'Nueva canción';

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
  String get appExitBackAgain => 'Pulsa Atrás de nuevo para salir';

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
  String get searchPreferredSourceLabel => 'Fuente preferida';

  @override
  String get searchPreferredSourceHint =>
      'Los resultados también pueden proceder de otras fuentes de búsqueda activadas.';

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
  String get setlistShare => 'Compartir como OpenSong';

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
  String get playerPlay => 'Reproducir';

  @override
  String get playerPause => 'Pausar';

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
  String get searchCombinedLabel => 'Combinado';

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
      'Acordes entre corchetes [C]; los marcadores de sección van en líneas separadas.';

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
  String get settingsLyricHighlight => 'Resaltado de la línea actual';

  @override
  String get settingsHighlightBackgroundUnderline => 'Fondo + subrayado';

  @override
  String get settingsHighlightBackground => 'Fondo';

  @override
  String get settingsHighlightUnderline => 'Subrayado';

  @override
  String get settingsHighlightContrast => 'Color de texto con contraste';

  @override
  String get settingsHighlightNone => 'Ninguno';

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
      'Borra la actividad reciente de canciones y listas. Conserva las canciones guardadas, los favoritos, las listas y los ajustes.';

  @override
  String get settingsHistoryCleared => 'Historial borrado.';

  @override
  String get accountTitle => 'Cuenta y sincronización';

  @override
  String get accountICloudBenefits =>
      'Usa tu cuenta de Apple para sincronizar canciones y listas de canciones de forma privada con iCloud. Los cambios se sincronizan automáticamente al conectarte.';

  @override
  String get accountICloudUnavailable =>
      'iCloud no está disponible. Comprueba tu cuenta de Apple y el acceso a iCloud en los ajustes del sistema e inténtalo de nuevo.';

  @override
  String get accountConnectICloud => 'Conectar iCloud';

  @override
  String get accountDisconnectICloud => 'Desconectar iCloud';

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
  String get settingsPreviewSongTitle => 'Canción de la mañana';

  @override
  String get settingsPreviewArtist => 'Arreglo de ejemplo';

  @override
  String get settingsPreviewCurrentLine => 'Cuando llegue la mañana';

  @override
  String get settingsPreviewNextLine => 'Volveremos a cantar.';

  @override
  String get settingsPlayerSections => 'Títulos de sección';

  @override
  String get settingsPlayerControls => 'Panel de reproducción';

  @override
  String get settingsPlayerAutoscroll => 'Desplazamiento automático';

  @override
  String get settingsSystemShort => 'Dispositivo';

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
      'Al conectar Google Drive, se sincroniza tu biblioteca. Después, los cambios en las canciones se sincronizan automáticamente.';

  @override
  String get accountManualSyncHint =>
      'También puedes tocar Sincronizar ahora para sincronizar tu biblioteca.';

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
      'Sincroniza después de conectar y después de añadir, editar o eliminar una canción.';

  @override
  String get accountDriveFolder => 'Carpeta de biblioteca de Google Drive';

  @override
  String get accountPrivateDriveFolder => 'Carpeta privada de Singbook';

  @override
  String get accountChooseDriveFolder => 'Elige carpeta';

  @override
  String get accountDriveFolderMoveTitle => '¿Mover tu biblioteca Singbook?';

  @override
  String get accountDriveFolderMoveBody =>
      'Elija una carpeta visible de Google Drive. Singbook copiará y verificará sus canciones y setlists allí antes de cambiar a él. Los archivos originales permanecen en su ubicación anterior como copia de seguridad. Otros archivos se dejan en paz. Los archivos ChordPro que importe a esta carpeta se adoptan para sincronizarse y recibir metadatos de Singbook.';

  @override
  String get accountImportChordPro => 'Importar ChordPro desde Drive';

  @override
  String get accountImportChordProHint =>
      'Elija archivos .cho para agregarlos a esta biblioteca. Se adoptan los archivos que ya están en la carpeta; Los archivos de otros lugares se copian aquí.';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'La selección de carpeta de Drive no está disponible';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'Elija una carpeta visible de Drive con el selector de Google Drive en un dispositivo compatible.';

  @override
  String get syncErrorDriveFolderMissing =>
      'La carpeta Singbook Drive no está disponible';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Elija la carpeta nuevamente o restáurela en Google Drive.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook necesita acceso a esta carpeta de Drive';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Elija la carpeta nuevamente para otorgar acceso y luego sincronice su biblioteca.';

  @override
  String get syncErrorFolderMigration =>
      'La biblioteca aún no se ha podido mover.';

  @override
  String get syncErrorFolderMigrationHint =>
      'Su biblioteca anterior todavía está segura. Verifique la conexión y elija la carpeta nuevamente para volver a intentarlo.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Elija primero una carpeta de Drive visible';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'Se necesita una carpeta de biblioteca visible antes de importar archivos desde Drive.';

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
  String get syncErrorOAuthClientConfiguration =>
      'Google rechazó la configuración de inicio de sesión de esta versión.';

  @override
  String get syncErrorOAuthClientConfigurationHint =>
      'Comprueba que el ID de OAuth configurado sea el cliente de escritorio de Singbook.';

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

  @override
  String get actionUndo => 'Deshacer';

  @override
  String setlistEntryRemoved(String song) {
    return 'Se ha quitado $song de la lista';
  }

  @override
  String get backupTitle => 'Copia de seguridad y restauración';

  @override
  String get backupExport => 'Exportar copia de seguridad';

  @override
  String get backupRestore => 'Restaurar copia de seguridad';

  @override
  String get backupIncludePreferences =>
      'Incluir preferencias de la aplicación';

  @override
  String get backupRestorePreferences =>
      'Restaurar preferencias de la aplicación';

  @override
  String get backupMerge => 'Añadir a esta biblioteca';

  @override
  String get backupMergeHint =>
      'Conserva los cambios locales y añade canciones y listas de esta copia de seguridad.';

  @override
  String get backupReplace => 'Reemplazar esta biblioteca';

  @override
  String get backupReplaceHint =>
      'Reemplaza todas las canciones y listas de este dispositivo con las de esta copia.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Canciones: $songs · Listas: $setlists · Conflictos: $conflicts';
  }

  @override
  String get backupFailed =>
      'No se pudo completar la operación. Inténtalo de nuevo.';

  @override
  String get backupRestored => 'Copia de seguridad restaurada.';

  @override
  String get backupLocalHint =>
      'Guarda una copia de tu biblioteca. Nunca se incluyen las credenciales de la cuenta ni las cookies de consentimiento.';

  @override
  String get backupReplaceConfirm =>
      '¿Reemplazar la biblioteca actual? Esta acción no se puede deshacer.';

  @override
  String get searchCheckOperations => 'Operaciones';

  @override
  String get searchCheckCode => 'Código del resultado';

  @override
  String get searchCheckQueued => 'Esperando para comprobar esta fuente.';

  @override
  String get searchCheckFetch => 'Cargar letra';

  @override
  String get searchCheckValidate => 'Comprobar coincidencia de la canción';

  @override
  String get searchCheckCorroborate => 'Comprobar coincidencia de la letra';

  @override
  String get searchCheckCompleted => 'Completado';

  @override
  String get searchCheckTimeout => 'La fuente no respondió a tiempo.';

  @override
  String get searchCheckBlocked => 'La fuente bloqueó la solicitud.';

  @override
  String get searchCheckRateLimited =>
      'La fuente está limitando las solicitudes. Inténtalo más tarde.';

  @override
  String get searchCheckNetwork =>
      'No se pudo acceder a la fuente. Comprueba tu conexión.';

  @override
  String get searchCheckInvalid => 'La fuente devolvió una respuesta ilegible.';

  @override
  String get searchCheckNotConfigured =>
      'Esta fuente no está configurada en esta versión.';

  @override
  String get searchCheckNoLyrics => 'No se encontraron letras coincidentes.';

  @override
  String get searchCheckFailed => 'No se pudo completar esta operación.';

  @override
  String get searchCheckNoHistory =>
      'No se han realizado comprobaciones de fuentes para esta comparación.';

  @override
  String get searchVersionCredits => 'Créditos';

  @override
  String get searchVersionMediaLinks => 'Enlaces relacionados';

  @override
  String get searchCheckCancelled => 'Cancelado';

  @override
  String get searchCheckAmbiguous =>
      'Se encontraron varias coincidencias. Esta fuente necesita una grabación más específica.';

  @override
  String get searchCheckIdentity =>
      'Esta fuente necesita un identificador de grabación u obra.';

  @override
  String get searchCheckExtraction =>
      'La fuente respondió, pero no se pudieron extraer las letras.';

  @override
  String get searchCheckBusy =>
      'Esta fuente está ocupada. Inténtalo más tarde.';

  @override
  String get searchCheckSelection =>
      'Elige un resultado específico de esta fuente.';

  @override
  String get playerChordsNone => 'Ninguno';

  @override
  String get editorCustomValue => 'Otro…';

  @override
  String get editorStandardTuning => 'Afinación estándar';

  @override
  String get editorExampleVerse =>
      '[C]Un nuevo día nos [G]llama,\n[Am]seguimos la luz de vuelta a [F]casa.';

  @override
  String get editorExampleChorus =>
      '[F]Cantemos esta canción [C]juntos,\n[G]que la melodía nos lleve [C]más allá.';

  @override
  String get editorExampleBridge => '[Am]Una línea más, un poco [F]más cerca.';

  @override
  String get playerEstimatedKey => 'Tonalidad estimada';

  @override
  String get songsLibraryView => 'Biblioteca';

  @override
  String get settingsStartupView => 'Iniciar en';

  @override
  String get settingsStartupViewHint =>
      'Elige la vista de canciones que se mostrará al abrir la aplicación.';

  @override
  String get settingsStartupLastView => 'Última vista abierta';

  @override
  String get playerFullScreen => 'Pantalla completa';

  @override
  String get playerExitFullScreen => 'Salir de pantalla completa';

  @override
  String get playerExpandControls => 'Mostrar controles de reproducción';

  @override
  String get playerCollapseControls => 'Ocultar controles de reproducción';

  @override
  String get settingsShowSections => 'Mostrar encabezados de las secciones';

  @override
  String get settingsShowSectionsHint =>
      'Muestra en la letra los encabezados de estrofas, estribillos y otras secciones.';

  @override
  String get settingsShowPlayerControls => 'Mostrar controles de reproducción';

  @override
  String get settingsShowPlayerControlsHint =>
      'También puedes tocar o deslizar el panel del reproductor para mostrarlo u ocultarlo.';

  @override
  String get sourceAnalysisHeading =>
      'Análisis del audio enviado (sin verificar)';

  @override
  String sourceAnalysisCoverage(int shown, int total) {
    return 'Se muestran $shown de $total envíos';
  }

  @override
  String sourceAnalysisSample(int number) {
    return 'Muestra $number';
  }

  @override
  String get sourceAnalysisEstimatedTempo => 'Tempo estimado (BPM)';
}
