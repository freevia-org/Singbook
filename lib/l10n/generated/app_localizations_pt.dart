// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Um espaço tranquilo para encontrar, organizar e cantar com sua biblioteca de músicas.';

  @override
  String get aboutMadeForSinging => 'Feito para cantar em conjunto';

  @override
  String appVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get navHome => 'Início';

  @override
  String get navSongs => 'Músicas';

  @override
  String get navSetlists => 'Listas de músicas';

  @override
  String get navSettings => 'Configurações';

  @override
  String get navSettingsCompact => 'Configurações';

  @override
  String get navSearch => 'Pesquisar';

  @override
  String get navBack => 'Voltar';

  @override
  String get navClose => 'Fechar';

  @override
  String get navMore => 'Mais ações';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionDone => 'Concluído';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionShare => 'Compartilhar';

  @override
  String get actionPrint => 'Imprimir';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionClear => 'Limpar';

  @override
  String get actionRetry => 'Tentar novamente';

  @override
  String get actionRefresh => 'Atualizar';

  @override
  String get actionImport => 'Importar';

  @override
  String get actionExport => 'Exportar';

  @override
  String get actionExpand => 'Expandir';

  @override
  String get actionCollapse => 'Recolher';

  @override
  String get actionAdd => 'Adicionar';

  @override
  String get actionCreate => 'Criar';

  @override
  String get actionRemove => 'Remover';

  @override
  String get actionDuplicate => 'Duplicar';

  @override
  String get actionMoveUp => 'Mover para cima';

  @override
  String get actionMoveDown => 'Mover para baixo';

  @override
  String get actionPrevious => 'Anterior';

  @override
  String get actionNext => 'Próxima';

  @override
  String get searchHint => 'Pesquise músicas, artistas ou letras';

  @override
  String get searchCatalogHint => 'Pesquise uma música ou um artista';

  @override
  String get searchChangeSong => 'Alterar música';

  @override
  String get searchSelectedPreview => 'Pré-visualização selecionada';

  @override
  String get searchSubmit => 'Pesquisar';

  @override
  String get searchFilters => 'Opções de pesquisa';

  @override
  String get searchFiltersShow => 'Mostrar opções de pesquisa';

  @override
  String get searchFiltersHide => 'Ocultar opções de pesquisa';

  @override
  String get searchFilterArtist => 'Artista';

  @override
  String get searchFilterTitle => 'Título da música';

  @override
  String get searchFilterLyrics => 'Letras';

  @override
  String get searchFilterChords => 'Com acordes';

  @override
  String get searchFilterTimed => 'Letras sincronizadas';

  @override
  String get searchFilterLanguage => 'Idioma';

  @override
  String get searchFilterAll => 'Qualquer';

  @override
  String get searchAutocompleteLabel => 'Sugestões';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: 'Nenhum resultado',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Digite uma música, um artista ou um trecho da letra para pesquisar.';

  @override
  String get searchCatalogEmptyQuery =>
      'Digite uma música ou um artista para pesquisar.';

  @override
  String get searchNoResults =>
      'Nenhuma música encontrada. Tente outra pesquisa.';

  @override
  String get searchLoading => 'Pesquisando músicas…';

  @override
  String get searchError => 'Não foi possível concluir a pesquisa.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Recentes';

  @override
  String get searchFavoritesTab => 'Favoritas';

  @override
  String get searchSuggested => 'Correspondência sugerida';

  @override
  String get searchAlternatives => 'Outras correspondências';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versões disponíveis',
      one: '1 versão disponível',
      zero: '0 Versões disponíveis',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Versões indisponíveis',
      one: '1 versão indisponível',
      zero: '0 Versões indisponíveis',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Ir para a seção';

  @override
  String get searchVersionDetails => 'Detalhes da versão';

  @override
  String get searchSelectedRecording => 'Gravação selecionada';

  @override
  String get searchVersionDuration => 'Duração da versão';

  @override
  String get searchCompare => 'Comparar versões';

  @override
  String get searchChooseVersion => 'Escolher esta versão';

  @override
  String get searchFullPreview => 'Pré-visualização completa';

  @override
  String get searchArrangementNotes => 'Notas sobre o arranjo';

  @override
  String get searchOpenLyrics => 'Abrir letra';

  @override
  String get searchContributions => 'Fontes utilizadas';

  @override
  String get searchVersionChecking => 'A verificar esta versão…';

  @override
  String get searchVersionUnavailable =>
      'Não é possível usar esta versão. Escolha outra.';

  @override
  String get searchPreviewUnavailable =>
      'Pré-visualização da letra indisponível.';

  @override
  String get searchSongMatch => 'Correspondência de música';

  @override
  String get searchRecordingMatch => 'Correspondência de gravação';

  @override
  String get searchMatchUnverified => 'Gravação não verificada';

  @override
  String get searchMatchExact => 'Correspondência exata da gravação';

  @override
  String get searchMatchPossible => 'Possível correspondência';

  @override
  String get searchAvailability => 'Disponibilidade';

  @override
  String get searchLyricsAvailable => 'Letra disponível';

  @override
  String get searchLyricsUnavailable => 'Letra indisponível';

  @override
  String get searchChordsAvailable => 'Acordes disponíveis';

  @override
  String get searchChordsUnavailable => 'Sem acordes';

  @override
  String get searchTimingAvailable => 'Sincronização disponível';

  @override
  String get searchTimingUnavailable => 'Sem sincronização';

  @override
  String get searchDurationUnknown => 'Duração desconhecida';

  @override
  String searchRating(String rating) {
    return 'Avaliação $rating';
  }

  @override
  String get searchSourceLabel => 'Fonte';

  @override
  String get searchMetadata => 'Detalhes da música';

  @override
  String get searchAlbum => 'Álbum';

  @override
  String get searchArtist => 'Artista';

  @override
  String get searchYear => 'Ano';

  @override
  String get searchLanguage => 'Idioma';

  @override
  String get searchViewVersions => 'Ver versões';

  @override
  String get searchSaved => 'Música salva na sua biblioteca.';

  @override
  String get searchSaveOpenLyrics => 'Guardar e abrir a letra';

  @override
  String get searchOtherResults => 'Outros resultados';

  @override
  String get searchSaveFailed => 'Não foi possível salvar esta música.';

  @override
  String get homeRecentSongs => 'Músicas recentes';

  @override
  String get homeRecentlyPlayed => 'Reproduzidas recentemente';

  @override
  String get homeFavorites => 'Favoritas';

  @override
  String get homeHistory => 'Histórico';

  @override
  String get homeHistoryClear => 'Limpar histórico';

  @override
  String get homeHistoryCleared => 'Histórico limpo.';

  @override
  String get homeHistoryEmpty => 'As músicas que você abrir aparecerão aqui.';

  @override
  String get homeFavoritesEmpty =>
      'Suas músicas e listas favoritas aparecerão aqui.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens exibidos',
      one: '1 item exibido',
      zero: '0 itens exibidos',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Suas músicas e listas recentes aparecerão aqui.';

  @override
  String get homeTimelineLabel => 'Linha do tempo do histórico';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Todo o histórico';

  @override
  String get homeShowFavorites => 'Mostrar favoritas';

  @override
  String get homeShowRecent => 'Mostrar recentes';

  @override
  String get songsTitle => 'Músicas';

  @override
  String get songsEmpty => 'Suas músicas aparecerão aqui.';

  @override
  String get songsEmptySearch => 'Nenhuma música corresponde à sua pesquisa.';

  @override
  String get songsAdd => 'Adicionar música';

  @override
  String get songsSortAlphabetical => 'Ordenar em ordem alfabética';

  @override
  String get songsAlphabetNavigation => 'Índice de músicas';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vezes',
      one: 'uma vez',
      zero: 'nunca',
    );
    return 'Aberta $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Adicionar às favoritas';

  @override
  String get songFavoriteRemove => 'Remover das favoritas';

  @override
  String get songMenuLabel => 'Ações da música';

  @override
  String get songInfo => 'Detalhes da música';

  @override
  String get setlistMenuLabel => 'Ações da lista';

  @override
  String get songAddToSetlist => 'Adicionar à lista';

  @override
  String get songCopyChordPro => 'Copiar ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Excluir música?';

  @override
  String get songDeleteConfirmMessage =>
      'Esta música será removida da sua biblioteca.';

  @override
  String get songDeleted => 'Música excluída.';

  @override
  String get setlistsTitle => 'Listas de músicas';

  @override
  String get setlistsEmpty =>
      'Crie uma lista para seu próximo ensaio ou apresentação.';

  @override
  String get setlistsEmptySearch => 'Nenhuma lista corresponde à sua pesquisa.';

  @override
  String get setlistCreate => 'Nova lista de músicas';

  @override
  String get setlistNameHint => 'Nome da lista';

  @override
  String get setlistNotes => 'Anotações';

  @override
  String get setlistEntryOverride => 'Tom e capotraste específicos da música';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count músicas',
      one: '1 música',
      zero: 'Nenhuma música',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Pelo menos $duration';
  }

  @override
  String get setlistDurationUnknown => 'Duração desconhecida';

  @override
  String setlistActivity(String date) {
    return 'Última atividade: $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Criada em $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Editada em $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Reproduzida pela última vez em $date';
  }

  @override
  String get setlistSongsEmpty => 'Esta lista ainda não tem músicas.';

  @override
  String get setlistAddSongs => 'Adicionar músicas';

  @override
  String get setlistReorder => 'Reordenar músicas';

  @override
  String setlistMoveSongUp(String song) {
    return 'Mover $song para cima';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Mover $song para baixo';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Remover $song da lista';
  }

  @override
  String get setlistDuplicate => 'Duplicar lista';

  @override
  String get setlistFavoriteAdd => 'Adicionar lista às favoritas';

  @override
  String get setlistFavoriteRemove => 'Remover lista das favoritas';

  @override
  String get setlistShare => 'Compartilhar como arquivo de lista';

  @override
  String get setlistSharePdf => 'Compartilhar como PDF';

  @override
  String get setlistPrint => 'Imprimir';

  @override
  String get setlistDeleteConfirmTitle => 'Excluir lista?';

  @override
  String get setlistDeleteConfirmMessage =>
      'A lista será removida. As músicas da sua biblioteca serão mantidas.';

  @override
  String get setlistDeleted => 'Lista excluída.';

  @override
  String get readerTitle => 'Letras';

  @override
  String get readerNoLyrics => 'Nenhuma letra foi adicionada ainda.';

  @override
  String get readerShowChords => 'Mostrar acordes';

  @override
  String get readerHideChords => 'Ocultar acordes';

  @override
  String get readerTranspose => 'Transpor acordes';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semitons',
      one: '1 semitom',
      zero: '0 semitons',
    );
    return 'Transpor $_temp0';
  }

  @override
  String get readerSaved => 'Guardado';

  @override
  String get readerEdit => 'Editar letras e detalhes';

  @override
  String get playerPlay => 'Iniciar rolagem das letras';

  @override
  String get playerPause => 'Pausar rolagem das letras';

  @override
  String get playerResume => 'Retomar rolagem das letras';

  @override
  String get playerSeek => 'Posição da reprodução';

  @override
  String playerElapsed(String time) {
    return 'Tempo decorrido: $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Tempo restante: $time';
  }

  @override
  String get playerTimingMode => 'Modo de rolagem';

  @override
  String get playerTimedLyrics => 'Letras sincronizadas';

  @override
  String get playerStartScroll => 'Iniciar deslocamento automático';

  @override
  String get playerEstimatedPace => 'Ritmo estimado';

  @override
  String get playerScrollSpeed => 'Velocidade de deslocamento';

  @override
  String playerEstimatedDuration(String time) {
    return 'Duração estimada: $time';
  }

  @override
  String get playerLyricsOnly => 'Deslocamento da letra · sem áudio';

  @override
  String get playerManualScroll => 'Rolagem manual';

  @override
  String get playerTimingStatusReady =>
      'As letras acompanharão a sincronização disponível.';

  @override
  String get playerTimingStatusEstimated =>
      'A velocidade da rolagem é estimada com base na duração da música.';

  @override
  String get playerTimingStatusManual => 'Role as letras manualmente.';

  @override
  String get playerTimingStatusUnavailable =>
      'A rolagem sincronizada não está disponível para esta música.';

  @override
  String get playerDurationUnknown =>
      'Adicione a duração da música para usar a rolagem estimada.';

  @override
  String get playerProgressLabel => 'Progresso da música';

  @override
  String get playerCurrentSection => 'Seção atual';

  @override
  String get playerPreviousSection => 'Seção anterior';

  @override
  String get playerNextSection => 'Próxima seção';

  @override
  String get playerPreviousSectionSong =>
      'Seção anterior · mantenha pressionado para ir à música anterior da lista';

  @override
  String get playerNextSectionSong =>
      'Próxima seção · mantenha pressionado para ir à próxima música da lista';

  @override
  String get playerPreviousSong => 'Música anterior';

  @override
  String get playerNextSong => 'Próxima música';

  @override
  String get editorTitle => 'Editar música';

  @override
  String get editorTitleField => 'Título da música';

  @override
  String get editorArtistField => 'Artista';

  @override
  String get editorAlbumField => 'Álbum';

  @override
  String get editorLyricsField => 'Letra';

  @override
  String get editorChordsField => 'Acordes';

  @override
  String get editorKeyField => 'Tom';

  @override
  String get editorCapoField => 'Capotraste';

  @override
  String get editorTuningField => 'Afinação';

  @override
  String get editorTempoField => 'Andamento';

  @override
  String get editorDurationField => 'Duração';

  @override
  String get editorTimeSignatureField => 'Fórmula de compasso';

  @override
  String get editorLanguageField => 'Idioma';

  @override
  String get editorYearField => 'Ano';

  @override
  String get editorComposerField => 'Compositor';

  @override
  String get editorLyricistField => 'Autor da letra';

  @override
  String get editorCopyrightField => 'Direitos autorais';

  @override
  String get editorLicenseField => 'Licença';

  @override
  String get songInfoSources => 'Fontes e créditos';

  @override
  String get searchMatchSameSong => 'Mesma música; gravação não confirmada';

  @override
  String get searchMatchNeedsAgreement =>
      'A letra da cifra precisa ser confirmada';

  @override
  String get searchMatchDifferentLyrics =>
      'A letra é diferente da música selecionada';

  @override
  String get searchMatchCombinedSources =>
      'Detalhes combinados de várias fontes';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Combinado de $count fontes',
      one: 'Combinado de 1 fonte',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count correspondências de músicas',
      one: '1 correspondência de música',
      zero: '0 correspondências de músicas',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versões de fonte',
      one: '1 versão de fonte',
      zero: '0 versões de fonte',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Melhor correspondência disponível';

  @override
  String get providerDescriptionUnknown => 'Fonte da música';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Baixe um arquivo ChordPro da fonte e depois importe-o.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Baixe o arquivo com uma conta gratuita e depois importe-o.';

  @override
  String get providerDescPublicChordSheets => 'Cifras públicas.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Letras históricas licenciadas por obra.';

  @override
  String get providerDescLicensedCatalog => 'Catálogo de letras licenciadas.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Músicas originais sob licença Creative Commons BY.';

  @override
  String get providerDescPerSongLicense => 'Letras licenciadas por música.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Somente detalhes da gravação e do lançamento.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Somente detalhes da composição.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Capas apenas para correspondências exatas de gravação.';

  @override
  String get providerCapabilityLyrics => 'Letras';

  @override
  String get providerCapabilityChords => 'Acordes';

  @override
  String get providerCapabilityTiming => 'Letras sincronizadas';

  @override
  String get providerCapabilitySearch => 'Pesquisa';

  @override
  String get providerCapabilityMetadata => 'Detalhes da música';

  @override
  String get editorArtworkField => 'Link da capa';

  @override
  String get editorLyricsHint =>
      'Toque em uma linha para editar a letra ou os acordes.';

  @override
  String get editorSave => 'Salvar alterações';

  @override
  String get editorSaved => 'Alterações salvas.';

  @override
  String get editorSaveFailed => 'Não foi possível salvar as alterações.';

  @override
  String get editorSaveConflict =>
      'A música foi alterada em outro lugar. Suas alterações foram salvas como uma cópia separada.';

  @override
  String get editorUnsavedTitle => 'Descartar alterações?';

  @override
  String get editorUnsavedMessage => 'Suas alterações não foram salvas.';

  @override
  String get editorFieldRequired => 'Digite o título da música.';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Usar configuração do dispositivo';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsColorPalette => 'Paleta de cores';

  @override
  String get settingsFont => 'Fonte';

  @override
  String get settingsTextSize => 'Tamanho do texto';

  @override
  String get settingsLyricsPreview => 'Prévia das letras';

  @override
  String get settingsPlayer => 'Reprodutor de letras';

  @override
  String get settingsDefaultShowChords => 'Mostrar acordes por padrão';

  @override
  String get settingsDefaultAutoscroll =>
      'Iniciar rolagem automática das letras';

  @override
  String get settingsDefaultTiming => 'Modo de rolagem padrão';

  @override
  String get settingsLanguage => 'Idioma do app';

  @override
  String get settingsLanguageSystem => 'Usar idioma do dispositivo';

  @override
  String get settingsLanguageEnglish => 'Inglês';

  @override
  String get settingsLanguageBulgarian => 'Búlgaro';

  @override
  String get settingsLanguageUkrainian => 'Ucraniano';

  @override
  String get settingsSources => 'Fontes de letras';

  @override
  String settingsSourceEnabled(String source) {
    return 'Ativar fonte $source';
  }

  @override
  String get settingsSourceRefresh => 'Atualizar lista de fontes';

  @override
  String get settingsSourcesUpdated => 'Fontes atualizadas.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Não foi possível atualizar as fontes.';

  @override
  String get settingsImport => 'Importar músicas';

  @override
  String get settingsImportChordPro => 'Importar arquivo ChordPro';

  @override
  String get settingsImportSetlist => 'Importar arquivo de lista';

  @override
  String get settingsImportSuccess => 'Importação concluída.';

  @override
  String get settingsImportFailed => 'Não foi possível importar este arquivo.';

  @override
  String get settingsImportUnsupported =>
      'Este tipo de arquivo não é compatível.';

  @override
  String get settingsShareSong => 'Compartilhar como ChordPro';

  @override
  String get settingsSharePdf => 'Compartilhar como PDF';

  @override
  String get settingsCopySong => 'Copiar para a área de transferência';

  @override
  String get settingsPrintSong => 'Imprimir apenas a música';

  @override
  String get settingsPrintSetlist => 'Imprimir lista com letras';

  @override
  String get settingsExportFailed => 'Não foi possível preparar o arquivo.';

  @override
  String get settingsCopied => 'Copiado para a área de transferência.';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsPrivacy => 'Privacidade';

  @override
  String get settingsLegal => 'Informações legais';

  @override
  String get settingsClearHistory => 'Limpar histórico';

  @override
  String get settingsClearHistoryConfirm =>
      'Limpar o histórico de músicas e listas?';

  @override
  String get settingsHistoryCleared => 'Histórico limpo.';

  @override
  String get accountTitle => 'Conta e sincronização';

  @override
  String get accountUnavailable =>
      'A sincronização requer uma versão do Singbook configurada para login com o Google. Esta versão mantém suas músicas apenas neste dispositivo.';

  @override
  String get accountSyncNow => 'Sincronizar agora';

  @override
  String get accountConnected =>
      'Conectado. Escolha “Sincronizar agora” para atualizar seu backup.';

  @override
  String get accountSignIn => 'Conectar conta';

  @override
  String get accountSignOut => 'Sair';

  @override
  String get accountChange => 'Trocar conta';

  @override
  String get accountSignedOut => 'Desconectado';

  @override
  String get accountSyncing => 'Sincronizando sua biblioteca…';

  @override
  String get accountSynced => 'Biblioteca sincronizada.';

  @override
  String get accountSyncFailed =>
      'Não foi possível sincronizar sua biblioteca.';

  @override
  String get accessibilityFavorite => 'Favorita';

  @override
  String get accessibilityNotFavorite => 'Não é favorita';

  @override
  String get accessibilitySearchField => 'Pesquisar músicas';

  @override
  String get accessibilityClearSearch => 'Limpar texto de pesquisa';

  @override
  String accessibilitySongMenu(String song) {
    return 'Ações para $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Ações para $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Expandir músicas em $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Recolher músicas em $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Progresso da reprodução, $percent por cento';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Linha do tempo do histórico, $date';
  }

  @override
  String get loading => 'Carregando…';

  @override
  String get loadingSongs => 'Carregando músicas…';

  @override
  String get loadingSetlists => 'Carregando listas…';

  @override
  String get errorGeneric => 'Algo deu errado.';

  @override
  String get errorOffline => 'Parece que você está sem conexão.';

  @override
  String get errorPermission => 'É necessária uma permissão para continuar.';

  @override
  String get emptyFiltered => 'Nenhum item corresponde a estes filtros.';

  @override
  String get unknownValue => 'Desconhecido';

  @override
  String get durationUnknown => 'Duração desconhecida';

  @override
  String get metadataNotSet => 'Não definido';

  @override
  String get dateToday => 'Hoje';

  @override
  String get dateYesterday => 'Ontem';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count músicas',
      one: '1 música',
      zero: 'Nenhuma música',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Azul-marinho';

  @override
  String get settingsPaletteSage => 'Verde-sálvia';

  @override
  String get settingsPaletteOcean => 'Oceano';

  @override
  String get settingsPaletteClay => 'Argila';

  @override
  String get settingsPalettePlum => 'Ameixa';

  @override
  String get settingsFontSystem => 'Sistema';

  @override
  String get settingsFontSerif => 'Serifada';

  @override
  String get settingsFontMonospace => 'Monoespaçada';

  @override
  String get settingsLyricsPreviewExample =>
      'Quando a manhã chegar, cantaremos novamente.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Verificando fontes de letras: $checked de $total concluídas.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Nenhuma letra utilizável encontrada.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'A música selecionada foi verificada nas fontes ativadas, mas nenhuma delas forneceu uma versão de letra utilizável.';

  @override
  String get searchDiscoveryError =>
      'Não foi possível verificar as fontes de letras.';

  @override
  String get searchDiscoveryRetry => 'Pesquisar letras novamente';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fontes indisponíveis',
      one: '1 fonte indisponível',
      zero: '0 fontes indisponíveis',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Verifique sua conexão e tente novamente.';

  @override
  String get searchProviderChecks => 'Verificações das fontes';

  @override
  String get searchProviderPending => 'Verificando';

  @override
  String get searchProviderFound => 'Correspondência encontrada';

  @override
  String get searchProviderRejected => 'Não corresponde';

  @override
  String get searchProviderFailed => 'Falha na verificação';

  @override
  String get searchProviderUnavailable => 'Nenhuma letra utilizável';

  @override
  String get searchCatalogFilterHint =>
      'Selecione uma música para filtrar versões da letra por acordes, sincronização ou idioma.';

  @override
  String get startupErrorTitle => 'Não foi possível abrir sua biblioteca.';

  @override
  String setlistCopyName(String name) {
    return 'Cópia de $name';
  }

  @override
  String get setlistSongMissing => 'Música ausente';

  @override
  String get settingsImportTooLarge =>
      'Este arquivo é grande demais para importar.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Ir para $letter';
  }

  @override
  String get actionDiscard => 'Descartar';

  @override
  String get editorKeepEditing => 'Continuar editando';

  @override
  String get settingsDefaultShowChordsHint =>
      'Mostrar os acordes acima da letra quando a música tiver acordes.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'As letras rolam junto com a música. Não é usado no modo de rolagem manual.';

  @override
  String get accountUnavailableTitle => 'Sincronização não configurada';

  @override
  String get accountSignedOutBenefits =>
      'Entre com o Google para fazer backup das suas músicas e listas no Google Drive e manter todos os seus dispositivos sincronizados. Suas músicas continuam neste dispositivo de qualquer forma.';

  @override
  String get accountSignInWithGoogle => 'Entrar com o Google';

  @override
  String get accountWorking => 'Processando…';

  @override
  String get accountNeverSynced => 'Nunca sincronizada';

  @override
  String get accountSyncedJustNow => 'Sincronizada agora mesmo';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizada há $count minutos',
      one: 'Sincronizada há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizada há $count horas',
      one: 'Sincronizada há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizada há $count dias',
      one: 'Sincronizada há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterações conflitantes salvas como cópias',
      one: '1 alteração conflitante salva como cópia',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'A mesma música ou lista foi editada em dois lugares. Nada foi perdido: a outra versão foi salva como uma cópia separada.';

  @override
  String get accountReviewConflicts => 'Revisar cópias';

  @override
  String get songsConflictFilterActive => 'Exibindo apenas cópias em conflito';

  @override
  String get songsConflictFilterClear => 'Mostrar todas as músicas';

  @override
  String get songsConflictBadge => 'Cópia em conflito';

  @override
  String get songsConflictEmpty => 'Nenhuma cópia em conflito.';

  @override
  String get accountAutoSync => 'Sincronizar automaticamente';

  @override
  String get accountAutoSyncHint =>
      'Mantenha sua biblioteca atualizada ao abrir o app e depois de fazer alterações.';

  @override
  String get accountSignOutTitle => 'Sair desta conta?';

  @override
  String get accountSignOutBody =>
      'Suas músicas e listas continuam neste dispositivo. Elas não terão backup nem serão sincronizadas até você entrar novamente.';

  @override
  String get accountUseDifferent => 'Usar outra conta';

  @override
  String get accountSignInAgain => 'Entrar novamente';

  @override
  String get accountChooseAction => 'Escolha como continuar';

  @override
  String get accountChangedTitle => 'Outra conta do Google';

  @override
  String get accountChangedBody =>
      'Este dispositivo foi sincronizado pela última vez com outra conta do Google. Escolha o que fazer com as músicas e listas deste dispositivo.';

  @override
  String get accountChangedMerge => 'Mesclar com a nova conta';

  @override
  String get accountChangedMergeHint =>
      'Mantenha tudo neste dispositivo e adicione à nova conta.';

  @override
  String get accountChangedReplace =>
      'Substituir pela biblioteca da nova conta';

  @override
  String get accountChangedReplaceHint =>
      'As músicas deste dispositivo que não estiverem na nova conta serão removidas.';

  @override
  String get accountChangedSignOut => 'Cancelar e sair';

  @override
  String get accountStatusSignedOut => 'Conta e sincronização: desconectado';

  @override
  String get accountStatusSignedIn => 'Conta e sincronização: conectado';

  @override
  String get accountStatusSyncing => 'Conta e sincronização: sincronizando';

  @override
  String get accountStatusSynced =>
      'Conta e sincronização: biblioteca atualizada';

  @override
  String get accountStatusError =>
      'Conta e sincronização: problema, toque para revisar';

  @override
  String get accountNoticeConflicts =>
      'Algumas músicas foram editadas em dois lugares. As cópias foram mantidas.';

  @override
  String get accountNoticeSignedIn => 'Conectado.';

  @override
  String get accountNoticeSignedOut =>
      'Desconectado. Suas músicas continuam neste dispositivo.';

  @override
  String get syncErrorNotConfigured =>
      'A sincronização não está configurada nesta versão.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Use uma versão do Singbook configurada para login com o Google.';

  @override
  String get syncErrorNotSignedIn => 'Você não está conectado.';

  @override
  String get syncErrorNotSignedInHint =>
      'Entre para sincronizar sua biblioteca.';

  @override
  String get syncErrorAuthorizationRequired =>
      'O Google precisa que você entre novamente.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Entre novamente para continuar a sincronização. Suas músicas estão seguras neste dispositivo.';

  @override
  String get syncErrorAccessDenied =>
      'O Singbook não tem permissão para usar o Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Entre novamente e permita o acesso ao Drive quando solicitado.';

  @override
  String get syncErrorRateLimited =>
      'O Google está limitando as solicitações no momento.';

  @override
  String get syncErrorRateLimitedHint =>
      'Aguarde alguns minutos e tente novamente.';

  @override
  String get syncErrorStorageFull => 'Seu Google Drive está cheio.';

  @override
  String get syncErrorStorageFullHint =>
      'Libere espaço no Drive e tente novamente.';

  @override
  String get syncErrorNetwork => 'Não foi possível acessar o Google.';

  @override
  String get syncErrorNetworkHint =>
      'Verifique sua conexão com a internet e tente novamente.';

  @override
  String get syncErrorAccountChanged => 'Outra conta do Google foi usada.';

  @override
  String get syncErrorAccountChangedHint =>
      'Escolha se deseja mesclar a biblioteca deste dispositivo com a conta ou substituí-la.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Sua biblioteca sincronizada é grande demais para o Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Remova algumas músicas ou listas da biblioteca sincronizada e tente novamente.';

  @override
  String get syncErrorSignInFailed => 'O login não foi concluído.';

  @override
  String get syncErrorSignInFailedHint => 'Tente entrar novamente.';

  @override
  String get syncErrorGeneric => 'Não foi possível sincronizar sua biblioteca.';

  @override
  String get syncErrorGenericHint =>
      'Tente novamente daqui a pouco. Suas músicas continuam seguras neste dispositivo.';

  @override
  String get editorDurationInvalid =>
      'Digite segundos ou minutos e segundos, por exemplo 3:45.';

  @override
  String get editorNumberInvalid => 'Digite um número.';

  @override
  String get accountReplaceConfirmTitle => 'Excluir as músicas locais?';

  @override
  String get accountReplaceConfirmBody =>
      'As músicas e listas deste dispositivo que não estão na nova conta serão excluídas permanentemente. Não é possível desfazer.';

  @override
  String get accountReplaceConfirmAction => 'Excluir e substituir';

  @override
  String get accountSuspiciousTitle => 'Faltam itens no Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count itens sincronizados anteriormente por este dispositivo estão ausentes do Google Drive.',
      one:
          '$count item sincronizado anteriormente por este dispositivo está ausente do Google Drive.',
    );
    return '$_temp0 Isso pode acontecer se os dados do app tiverem sido apagados nas configurações do Google. Nada foi excluído ainda.';
  }

  @override
  String get accountSuspiciousDelete => 'Excluir também aqui';

  @override
  String get accountSuspiciousKeep =>
      'Manter minhas músicas e enviá-las novamente';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count itens deste dispositivo?',
      one: 'Excluir $count item deste dispositivo?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Estas músicas e listas serão excluídas permanentemente deste dispositivo. Não é possível desfazer.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Excluir deste dispositivo';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Faltam itens no Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Nada foi excluído. Escolha se quer excluí-los também aqui ou enviá-los novamente.';

  @override
  String get syncErrorRemoteChanged =>
      'O Google Drive mudou durante a sincronização.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Nada foi perdido. Sincronize novamente para obter as alterações mais recentes.';

  @override
  String get syncErrorInvalidLocalData =>
      'Não foi possível sincronizar alguns dados deste dispositivo.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Não foi possível ler uma música ou lista. Importe-a ou crie-a novamente e sincronize.';

  @override
  String get syncErrorNoAccountChange =>
      'Não há nenhuma alteração de conta para resolver.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Sincronize novamente para continuar.';

  @override
  String get accountSyncWarningTitle =>
      'Sincronizado, mas alguns arquivos foram ignorados';

  @override
  String get accountSyncWarningBody =>
      'Alguns arquivos não puderam ser usados e foram deixados como estavam. O restante está atualizado.';

  @override
  String get accountSyncWarningTooLarge =>
      'Um arquivo era grande demais para ser sincronizado e foi ignorado. O restante está atualizado.';

  @override
  String get accountSyncWarningInvalid =>
      'Um arquivo não pôde ser lido e foi ignorado. O restante está atualizado.';

  @override
  String get accountNoticeSyncSkipped =>
      'Sincronizado. Alguns arquivos foram ignorados.';

  @override
  String get settingsExportPdfTooLarge =>
      'Este PDF ficaria grande demais. Tente com menos músicas ou compartilhe como texto.';

  @override
  String get settingsTimingTooLarge =>
      'Os dados de temporização são grandes demais (mais de 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Este backup inclui a mesma música duas vezes, então nada foi importado.';

  @override
  String get setlistSaveConflict =>
      'A lista de músicas foi alterada em outro lugar. Suas alterações foram salvas como uma cópia separada.';

  @override
  String get sectionVerse => 'Estrofe';

  @override
  String get sectionChorus => 'Refrão';

  @override
  String get sectionBridge => 'Ponte';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pré-refrão';

  @override
  String get sectionPostChorus => 'Pós-refrão';

  @override
  String get sectionInstrumental => 'Instrumental';

  @override
  String get sectionInterlude => 'Interlúdio';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Estribilho';

  @override
  String get sectionHook => 'Gancho';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Final';

  @override
  String get youtubeConsentHint =>
      'Experimental. Escolha os cookies na página da Google para experimentar a pesquisa de letras. Não precisa iniciar sessão numa conta Google. A sua escolha fica neste dispositivo.';

  @override
  String get youtubeConsentOpen => 'Rever consentimento da Google';

  @override
  String get youtubeConsentSaved => 'Consentimento guardado';

  @override
  String get youtubeConsentClear => 'Limpar consentimento';

  @override
  String get youtubeConsentInstructions =>
      'Conclua a escolha dos cookies e aguarde o regresso do YouTube Music. Depois, guarde esta sessão e volte a pesquisar a música.';

  @override
  String get youtubeConsentError =>
      'Não foi possível atualizar a escolha de consentimento da Google. Tente novamente.';

  @override
  String get youtubeConsentBlocked =>
      'Aqui só é possível abrir o YouTube Music e a página de consentimento da Google. Não é possível iniciar sessão numa conta.';
}
