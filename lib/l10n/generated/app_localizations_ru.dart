// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Тексты, аккорды и сет-листы вместе — всё готово к репетиции, выступлению и игре где угодно.';

  @override
  String get aboutMadeForSinging => 'Каждая песня готова.';

  @override
  String get aboutDetails =>
      'Ищите в доступных источниках и сравнивайте тексты, аккорды, тайминг и сведения о записи, прежде чем сохранить нужную версию. Доступность зависит от песни и сервиса.';

  @override
  String get aboutFindTitle => 'Найдите подходящую версию';

  @override
  String get aboutKeepTitle => 'Создайте свою библиотеку';

  @override
  String get aboutKeepDetails =>
      'Редактируйте и транспонируйте песни, храните их в локальной библиотеке для использования офлайн и делитесь переносимыми файлами ChordPro. Необязательная синхронизация с Google Drive использует закрытую папку приложения в вашем аккаунте Google. Можно также нажать «Синхронизировать сейчас», чтобы обновить устройства.';

  @override
  String get aboutPlayTitle => 'Возьмите сет-лист на сцену';

  @override
  String get aboutPlayDetails =>
      'Собирайте песни в сет-листы, выбирайте тональность для каждой и делитесь сет-листами OpenSong. Настраивайте размер текста в ридере, включайте автопрокрутку текста и печатайте PDF-файлы песен. Singbook не транслирует и не воспроизводит аудио.';

  @override
  String get aboutPrivacyTitle => 'Бесплатно, библиотека хранится локально';

  @override
  String get aboutPrivacyDetails =>
      'Singbook бесплатен: без рекламы, аналитики и встроенных покупок. Ваша библиотека хранится на устройстве; для необязательной синхронизации используется ваш Google Drive. Результаты онлайн-поиска поступают напрямую от независимых сторонних сервисов и могут быть недоступны или защищены авторским правом. Singbook не размещает этот контент.';

  @override
  String get aboutWebsite => 'Сайт Singbook';

  @override
  String get aboutSourceCode => 'Исходный код на GitHub';

  @override
  String get aboutPublisher => 'От Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Языки приложения: $count';
  }

  @override
  String get aboutSupport => 'Поддержка и отзывы';

  @override
  String get menuTypeNewSong => 'Ввести новую песню';

  @override
  String appVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get navHome => 'Главная';

  @override
  String get navSongs => 'Песни';

  @override
  String get navSetlists => 'Сет-листы';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navSettingsCompact => 'Настройки';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navBack => 'Назад';

  @override
  String get appExitBackAgain => 'Нажмите «Назад» ещё раз, чтобы выйти';

  @override
  String get navClose => 'Закрыть';

  @override
  String get navMore => 'Другие действия';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionDone => 'Готово';

  @override
  String get actionEdit => 'Изменить';

  @override
  String get actionDelete => 'Удалить';

  @override
  String get actionShare => 'Поделиться';

  @override
  String get actionPrint => 'Печать';

  @override
  String get actionCopy => 'Копировать';

  @override
  String get actionClear => 'Очистить';

  @override
  String get actionRetry => 'Повторить';

  @override
  String get actionRefresh => 'Обновить';

  @override
  String get actionImport => 'Импортировать';

  @override
  String get actionExport => 'Экспортировать';

  @override
  String get actionExpand => 'Развернуть';

  @override
  String get actionCollapse => 'Свернуть';

  @override
  String get actionAdd => 'Добавить';

  @override
  String get actionCreate => 'Создать';

  @override
  String get actionRemove => 'Убрать';

  @override
  String get actionDuplicate => 'Создать копию';

  @override
  String get actionMoveUp => 'Переместить вверх';

  @override
  String get actionMoveDown => 'Переместить вниз';

  @override
  String get actionPrevious => 'Предыдущая';

  @override
  String get actionNext => 'Следующая';

  @override
  String get searchHint => 'Поиск песен, исполнителей или текстов';

  @override
  String get searchCatalogHint => 'Поиск песни или исполнителя';

  @override
  String get searchChangeSong => 'Сменить песню';

  @override
  String get searchSelectedPreview => 'Выбранный предпросмотр';

  @override
  String get searchSubmit => 'Найти';

  @override
  String get searchFilters => 'Параметры поиска';

  @override
  String get searchFiltersShow => 'Показать параметры поиска';

  @override
  String get searchFiltersHide => 'Скрыть параметры поиска';

  @override
  String get searchFilterArtist => 'Исполнитель';

  @override
  String get searchFilterTitle => 'Название песни';

  @override
  String get searchFilterLyrics => 'Текст песни';

  @override
  String get searchFilterChords => 'Есть аккорды';

  @override
  String get searchFilterTimed => 'Синхронизированный текст';

  @override
  String get searchFilterLanguage => 'Язык';

  @override
  String get searchFilterAll => 'Любой';

  @override
  String get searchAutocompleteLabel => 'Подсказки';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результата',
      many: '$count результатов',
      few: '$count результата',
      one: '$count результат',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Введите название песни, исполнителя или текст для поиска.';

  @override
  String get searchCatalogEmptyQuery =>
      'Введите название песни или исполнителя для поиска.';

  @override
  String get searchNoResults => 'Песни не найдены. Попробуйте изменить запрос.';

  @override
  String get searchLoading => 'Поиск песен…';

  @override
  String get searchError => 'Не удалось выполнить поиск.';

  @override
  String get searchOnlineTab => 'Онлайн';

  @override
  String get searchRecentTab => 'Недавние';

  @override
  String get searchFavoritesTab => 'Избранное';

  @override
  String get searchSuggested => 'Предлагаемое совпадение';

  @override
  String get searchAlternatives => 'Другие совпадения';

  @override
  String get searchCompare => 'Сравнить версии';

  @override
  String get searchChooseVersion => 'Выбрать эту версию';

  @override
  String get searchFullPreview => 'Полный предпросмотр';

  @override
  String get searchArrangementNotes => 'Примечания к аранжировке';

  @override
  String get searchOpenLyrics => 'Открыть текст';

  @override
  String get searchContributions => 'Использованные источники';

  @override
  String get searchVersionChecking => 'Проверка этой версии…';

  @override
  String get searchVersionUnavailable =>
      'Эту версию нельзя использовать. Выберите другую.';

  @override
  String get searchPreviewUnavailable => 'Предпросмотр текста недоступен.';

  @override
  String get searchSongMatch => 'Совпадение песни';

  @override
  String get searchRecordingMatch => 'Совпадение записи';

  @override
  String get searchMatchUnverified => 'Запись не проверена';

  @override
  String get searchMatchExact => 'Точное совпадение записи';

  @override
  String get searchMatchPossible => 'Возможное совпадение';

  @override
  String get searchAvailability => 'Доступность';

  @override
  String get searchLyricsAvailable => 'Текст доступен';

  @override
  String get searchLyricsUnavailable => 'Текст недоступен';

  @override
  String get searchChordsAvailable => 'Аккорды доступны';

  @override
  String get searchChordsUnavailable => 'Аккордов нет';

  @override
  String get searchTimingAvailable => 'Доступна синхронизация';

  @override
  String get searchTimingUnavailable => 'Синхронизация недоступна';

  @override
  String get searchDurationUnknown => 'Длительность неизвестна';

  @override
  String searchRating(String rating) {
    return 'Оценка: $rating';
  }

  @override
  String get searchSourceLabel => 'Источник';

  @override
  String get searchPreferredSourceLabel => 'Предпочитаемый источник';

  @override
  String get searchPreferredSourceHint =>
      'Результаты могут поступать и из других включённых источников поиска.';

  @override
  String get searchMetadata => 'Сведения о песне';

  @override
  String get searchAlbum => 'Альбом';

  @override
  String get searchArtist => 'Исполнитель';

  @override
  String get searchYear => 'Год';

  @override
  String get searchLanguage => 'Язык';

  @override
  String get searchViewVersions => 'Посмотреть версии';

  @override
  String get searchSaved => 'Песня сохранена в библиотеке.';

  @override
  String get searchSaveOpenLyrics => 'Сохранить и открыть текст';

  @override
  String get searchOtherResults => 'Другие результаты';

  @override
  String get searchSaveFailed => 'Не удалось сохранить песню.';

  @override
  String get homeRecentSongs => 'Недавние песни';

  @override
  String get homeRecentlyPlayed => 'Недавно проигранные';

  @override
  String get homeFavorites => 'Избранное';

  @override
  String get homeHistory => 'История';

  @override
  String get homeHistoryClear => 'Очистить историю';

  @override
  String get homeHistoryCleared => 'История очищена.';

  @override
  String get homeHistoryEmpty => 'Здесь появятся песни, которые ты откроешь.';

  @override
  String get homeFavoritesEmpty =>
      'Здесь появятся избранные песни и сет-листы.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Показано: $count элемента',
      many: 'Показано: $count элементов',
      few: 'Показано: $count элемента',
      one: 'Показан: $count элемент',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty => 'Здесь появятся недавние песни и сет-листы.';

  @override
  String get homeTimelineLabel => 'Временная шкала истории';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Вся история';

  @override
  String get homeShowFavorites => 'Показать избранное';

  @override
  String get homeShowRecent => 'Показать недавние';

  @override
  String get songsTitle => 'Песни';

  @override
  String get songsEmpty => 'Здесь появятся твои песни.';

  @override
  String get songsEmptySearch => 'Нет песен, соответствующих запросу.';

  @override
  String get songsAdd => 'Добавить песню';

  @override
  String get songsSortAlphabetical => 'Сортировать по алфавиту';

  @override
  String get songsAlphabetNavigation => 'Указатель песен';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раза',
      many: '$count раз',
      few: '$count раза',
      one: '$count раз',
    );
    return 'Открыта $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Добавить в избранное';

  @override
  String get songFavoriteRemove => 'Убрать из избранного';

  @override
  String get songMenuLabel => 'Действия с песней';

  @override
  String get songInfo => 'Сведения о песне';

  @override
  String get setlistMenuLabel => 'Действия с сет-листом';

  @override
  String get songAddToSetlist => 'Добавить в сет-лист';

  @override
  String get songCopyChordPro => 'Копировать ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Удалить песню?';

  @override
  String get songDeleteConfirmMessage => 'Песня будет удалена из библиотеки.';

  @override
  String get songDeleted => 'Песня удалена.';

  @override
  String get setlistsTitle => 'Сет-листы';

  @override
  String get setlistsEmpty =>
      'Создай сет-лист для следующей репетиции или выступления.';

  @override
  String get setlistsEmptySearch => 'Нет сет-листов, соответствующих запросу.';

  @override
  String get setlistCreate => 'Новый сет-лист';

  @override
  String get setlistNameHint => 'Название сет-листа';

  @override
  String get setlistNotes => 'Заметки';

  @override
  String get setlistEntryOverride => 'Тональность и каподастр для этой песни';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни',
      many: '$count песен',
      few: '$count песни',
      one: '$count песня',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Не менее $duration';
  }

  @override
  String get setlistDurationUnknown => 'Длительность неизвестна';

  @override
  String setlistActivity(String date) {
    return 'Последнее действие: $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Создан $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Изменён $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Последний раз исполнялся $date';
  }

  @override
  String get setlistSongsEmpty => 'В этом сет-листе пока нет песен.';

  @override
  String get setlistAddSongs => 'Добавить песни';

  @override
  String get setlistReorder => 'Изменить порядок песен';

  @override
  String setlistMoveSongUp(String song) {
    return 'Переместить $song вверх';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Переместить $song вниз';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Убрать $song из сет-листа';
  }

  @override
  String get setlistDuplicate => 'Создать копию сет-листа';

  @override
  String get setlistFavoriteAdd => 'Добавить сет-лист в избранное';

  @override
  String get setlistFavoriteRemove => 'Убрать сет-лист из избранного';

  @override
  String get setlistShare => 'Поделиться как OpenSong';

  @override
  String get setlistSharePdf => 'Поделиться как PDF';

  @override
  String get setlistPrint => 'Печать';

  @override
  String get setlistDeleteConfirmTitle => 'Удалить сет-лист?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Сет-лист будет удалён. Песни в библиотеке останутся.';

  @override
  String get setlistDeleted => 'Сет-лист удалён.';

  @override
  String get readerTitle => 'Тексты песен';

  @override
  String get readerNoLyrics => 'Текст песни ещё не добавлен.';

  @override
  String get readerShowChords => 'Показать аккорды';

  @override
  String get readerHideChords => 'Скрыть аккорды';

  @override
  String get readerTranspose => 'Транспонировать аккорды';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count полутона',
      many: '$count полутонов',
      few: '$count полутона',
      one: '$count полутон',
    );
    return 'Транспонировать на $_temp0';
  }

  @override
  String get readerSaved => 'Сохранено';

  @override
  String get readerEdit => 'Изменить текст и сведения';

  @override
  String get playerPlay => 'Воспроизвести';

  @override
  String get playerPause => 'Пауза';

  @override
  String get playerResume => 'Продолжить прокрутку текста';

  @override
  String get playerSeek => 'Позиция воспроизведения';

  @override
  String playerElapsed(String time) {
    return 'Прошло времени: $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Осталось времени: $time';
  }

  @override
  String get playerTimingMode => 'Режим прокрутки';

  @override
  String get playerTimedLyrics => 'Синхронизированный текст';

  @override
  String get playerStartScroll => 'Начать автопрокрутку';

  @override
  String get playerEstimatedPace => 'Примерная скорость';

  @override
  String get playerScrollSpeed => 'Скорость прокрутки';

  @override
  String playerEstimatedDuration(String time) {
    return 'Примерная длительность: $time';
  }

  @override
  String get playerLyricsOnly => 'Прокрутка текста · без аудио';

  @override
  String get playerManualScroll => 'Ручная прокрутка';

  @override
  String get playerTimingStatusReady =>
      'Текст будет прокручиваться по доступным временным меткам.';

  @override
  String get playerTimingStatusEstimated =>
      'Скорость прокрутки рассчитана по длительности песни.';

  @override
  String get playerTimingStatusManual => 'Прокручивай текст вручную.';

  @override
  String get playerTimingStatusUnavailable =>
      'Для этой песни синхронизированная прокрутка недоступна.';

  @override
  String get playerDurationUnknown =>
      'Укажи длительность песни, чтобы использовать примерную прокрутку.';

  @override
  String get playerProgressLabel => 'Ход песни';

  @override
  String get playerCurrentSection => 'Текущий раздел';

  @override
  String get playerPreviousSection => 'Предыдущий раздел';

  @override
  String get playerNextSection => 'Следующий раздел';

  @override
  String get playerPreviousSectionSong =>
      'Предыдущий раздел · удерживай, чтобы перейти к предыдущей песне в сет-листе';

  @override
  String get playerNextSectionSong =>
      'Следующий раздел · удерживай, чтобы перейти к следующей песне в сет-листе';

  @override
  String get playerPreviousSong => 'Предыдущая песня';

  @override
  String get playerNextSong => 'Следующая песня';

  @override
  String get editorTitle => 'Изменить песню';

  @override
  String get editorTitleField => 'Название песни';

  @override
  String get editorArtistField => 'Исполнитель';

  @override
  String get editorAlbumField => 'Альбом';

  @override
  String get editorLyricsField => 'Текст песни';

  @override
  String get editorChordsField => 'Аккорды';

  @override
  String get editorKeyField => 'Тональность';

  @override
  String get editorCapoField => 'Каподастр';

  @override
  String get editorTuningField => 'Строй';

  @override
  String get editorTempoField => 'Темп';

  @override
  String get editorDurationField => 'Длительность';

  @override
  String get editorTimeSignatureField => 'Размер';

  @override
  String get editorLanguageField => 'Язык';

  @override
  String get editorYearField => 'Год';

  @override
  String get editorComposerField => 'Композитор';

  @override
  String get editorLyricistField => 'Автор текста';

  @override
  String get editorCopyrightField => 'Авторские права';

  @override
  String get editorLicenseField => 'Лицензия';

  @override
  String get songInfoSources => 'Источники и авторство';

  @override
  String get searchMatchSameSong => 'Та же песня; запись не подтверждена';

  @override
  String get searchMatchNeedsAgreement =>
      'Аккорды нужно сверить с текстом песни';

  @override
  String get searchMatchDifferentLyrics =>
      'Текст отличается от выбранной песни';

  @override
  String get searchMatchCombinedSources =>
      'Сведения объединены из нескольких источников';

  @override
  String get searchCombinedLabel => 'Объединённые';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count совпадения песни',
      many: '$count совпадений песен',
      few: '$count совпадения песен',
      one: '$count совпадение песни',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count версии источника',
      many: '$count версий источника',
      few: '$count версии источника',
      one: '$count версия источника',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Лучшее доступное совпадение';

  @override
  String get providerDescriptionUnknown => 'Источник песни';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Скачай файл ChordPro из источника, затем импортируй его.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Скачай файл, войдя в бесплатный аккаунт, затем импортируй его.';

  @override
  String get providerDescPublicChordSheets =>
      'Общедоступные листы с аккордами.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Исторические тексты с лицензией на каждое произведение.';

  @override
  String get providerDescLicensedCatalog => 'Каталог текстов по лицензии.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Оригинальные песни по лицензии Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Лицензия на текст оформляется для каждой песни.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Только сведения о записи и выпуске.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Только сведения о композиции.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Обложки только для точных совпадений записей.';

  @override
  String get providerCapabilityLyrics => 'Тексты песен';

  @override
  String get providerCapabilityChords => 'Аккорды';

  @override
  String get providerCapabilityTiming => 'Синхронизированный текст';

  @override
  String get providerCapabilitySearch => 'Поиск';

  @override
  String get providerCapabilityMetadata => 'Сведения о песне';

  @override
  String get editorArtworkField => 'Ссылка на обложку';

  @override
  String get editorLyricsHint =>
      'Аккорды указывайте в скобках [C], а названия разделов — отдельными строками.';

  @override
  String get editorSave => 'Сохранить изменения';

  @override
  String get editorSaved => 'Изменения сохранены.';

  @override
  String get editorSaveFailed => 'Не удалось сохранить изменения.';

  @override
  String get editorSaveConflict =>
      'Песня была изменена в другом месте. Твои изменения сохранены отдельной копией.';

  @override
  String get editorUnsavedTitle => 'Отменить изменения?';

  @override
  String get editorUnsavedMessage => 'Изменения не сохранены.';

  @override
  String get editorFieldRequired => 'Введи название песни.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeSystem => 'Как на устройстве';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsColorPalette => 'Цветовая палитра';

  @override
  String get settingsFont => 'Шрифт';

  @override
  String get settingsTextSize => 'Размер текста';

  @override
  String get settingsLyricsPreview => 'Предпросмотр текста';

  @override
  String get settingsPlayer => 'Прокрутка текста';

  @override
  String get settingsLyricHighlight => 'Подсветка текущей строки текста';

  @override
  String get settingsHighlightBackgroundUnderline => 'Фон + подчёркивание';

  @override
  String get settingsHighlightBackground => 'Фон';

  @override
  String get settingsHighlightUnderline => 'Подчёркивание';

  @override
  String get settingsHighlightContrast => 'Контрастный цвет текста';

  @override
  String get settingsHighlightNone => 'Нет';

  @override
  String get settingsDefaultShowChords => 'Показывать аккорды по умолчанию';

  @override
  String get settingsDefaultAutoscroll => 'Автоматически прокручивать текст';

  @override
  String get settingsDefaultTiming => 'Режим прокрутки по умолчанию';

  @override
  String get settingsLanguage => 'Язык приложения';

  @override
  String get settingsLanguageSystem => 'Использовать язык устройства';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Источники текстов';

  @override
  String settingsSourceEnabled(String source) {
    return 'Включить источник $source';
  }

  @override
  String get settingsSourceRefresh => 'Обновить список источников';

  @override
  String get settingsSourcesUpdated => 'Источники обновлены.';

  @override
  String get settingsSourcesUpdateFailed => 'Не удалось обновить источники.';

  @override
  String get settingsImport => 'Импортировать песни';

  @override
  String get settingsImportChordPro => 'Импортировать файл ChordPro';

  @override
  String get settingsImportSetlist => 'Импортировать файл сет-листа';

  @override
  String get settingsImportSuccess => 'Импорт завершён.';

  @override
  String get settingsImportFailed => 'Не удалось импортировать этот файл.';

  @override
  String get settingsImportUnsupported => 'Этот тип файла не поддерживается.';

  @override
  String get settingsShareSong => 'Поделиться как ChordPro';

  @override
  String get settingsSharePdf => 'Поделиться как PDF';

  @override
  String get settingsCopySong => 'Копировать в буфер обмена';

  @override
  String get settingsPrintSong => 'Печатать только песню';

  @override
  String get settingsPrintSetlist => 'Печатать сет-лист с текстами песен';

  @override
  String get settingsExportFailed => 'Не удалось подготовить файл.';

  @override
  String get settingsCopied => 'Скопировано в буфер обмена.';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsPrivacy => 'Конфиденциальность';

  @override
  String get settingsLegal => 'Правовая информация';

  @override
  String get settingsClearHistory => 'Очистить историю';

  @override
  String get settingsClearHistoryConfirm =>
      'Очищает историю недавних действий с песнями и сет-листами. Сохраняет сохранённые песни, избранное, сет-листы и настройки.';

  @override
  String get settingsHistoryCleared => 'История очищена.';

  @override
  String get accountTitle => 'Аккаунт и синхронизация';

  @override
  String get accountICloudBenefits =>
      'Используйте учётную запись Apple для конфиденциальной синхронизации песен и сет-листов с iCloud. После подключения изменения синхронизируются автоматически.';

  @override
  String get accountICloudUnavailable =>
      'iCloud недоступен. Проверьте учётную запись Apple и доступ к iCloud в системных настройках, затем попробуйте снова.';

  @override
  String get accountConnectICloud => 'Подключить iCloud';

  @override
  String get accountDisconnectICloud => 'Отключить iCloud';

  @override
  String get accountUnavailable =>
      'Для синхронизации нужна версия Singbook с настроенным входом через Google. В этой версии песни хранятся только на этом устройстве.';

  @override
  String get accountSyncNow => 'Синхронизировать';

  @override
  String get accountConnected =>
      'Подключено. Нажми «Синхронизировать», чтобы обновить резервную копию.';

  @override
  String get accountSignIn => 'Подключить аккаунт';

  @override
  String get accountSignOut => 'Выйти';

  @override
  String get accountChange => 'Сменить аккаунт';

  @override
  String get accountSignedOut => 'Не подключено';

  @override
  String get accountSyncing => 'Синхронизация библиотеки…';

  @override
  String get accountSynced => 'Библиотека синхронизирована.';

  @override
  String get accountSyncFailed => 'Не удалось синхронизировать библиотеку.';

  @override
  String get accessibilityFavorite => 'Избранное';

  @override
  String get accessibilityNotFavorite => 'Не в избранном';

  @override
  String get accessibilitySearchField => 'Поиск песен';

  @override
  String get accessibilityClearSearch => 'Очистить поисковый запрос';

  @override
  String accessibilitySongMenu(String song) {
    return 'Действия для песни «$song»';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Действия для сет-листа «$setlist»';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Развернуть песни в сет-листе «$setlist»';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Свернуть песни в сет-листе «$setlist»';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      percent,
      locale: localeName,
      other: '$percent процента',
      many: '$percent процентов',
      few: '$percent процента',
      one: '$percent процент',
    );
    return 'Ход воспроизведения: $_temp0';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Временная шкала истории, $date';
  }

  @override
  String get loading => 'Загрузка…';

  @override
  String get loadingSongs => 'Загрузка песен…';

  @override
  String get loadingSetlists => 'Загрузка сет-листов…';

  @override
  String get errorGeneric => 'Что-то пошло не так.';

  @override
  String get errorOffline => 'Похоже, ты не в сети.';

  @override
  String get errorPermission => 'Для продолжения требуется разрешение.';

  @override
  String get emptyFiltered => 'Нет элементов, соответствующих этим фильтрам.';

  @override
  String get unknownValue => 'Неизвестно';

  @override
  String get durationUnknown => 'Длительность неизвестна';

  @override
  String get metadataNotSet => 'Не задано';

  @override
  String get dateToday => 'Сегодня';

  @override
  String get dateYesterday => 'Вчера';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни',
      many: '$count песен',
      few: '$count песни',
      one: '$count песня',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Тёмно-синий';

  @override
  String get settingsPaletteSage => 'Шалфейный';

  @override
  String get settingsPaletteOcean => 'Океан';

  @override
  String get settingsPaletteClay => 'Глиняный';

  @override
  String get settingsPalettePlum => 'Сливовый';

  @override
  String get settingsFontSystem => 'Системный';

  @override
  String get settingsFontSerif => 'С засечками';

  @override
  String get settingsFontMonospace => 'Моноширинный';

  @override
  String get settingsLyricsPreviewExample =>
      'Когда наступит утро, мы снова запоём.';

  @override
  String get settingsPreviewSongTitle => 'Утренняя песня';

  @override
  String get settingsPreviewArtist => 'Пример аранжировки';

  @override
  String get settingsPreviewCurrentLine => 'Когда наступит утро';

  @override
  String get settingsPreviewNextLine => 'Мы снова запоём.';

  @override
  String get settingsPlayerSections => 'Заголовки разделов';

  @override
  String get settingsPlayerControls => 'Панель воспроизведения';

  @override
  String get settingsPlayerAutoscroll => 'Автопрокрутка';

  @override
  String get settingsSystemShort => 'Устройство';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Проверка источников текстов: готово $checked из $total.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Не найдено подходящих текстов.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Выбранная песня проверена в подключённых источниках, но ни один из них не предоставил подходящую версию текста.';

  @override
  String get searchDiscoveryError => 'Не удалось проверить источники текстов.';

  @override
  String get searchDiscoveryRetry => 'Повторить поиск текста';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count источника недоступно',
      many: '$count источников недоступно',
      few: '$count источника недоступно',
      one: '$count источник недоступен',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Проверь подключение и попробуй ещё раз.';

  @override
  String get searchProviderChecks => 'Проверки источников';

  @override
  String get searchProviderPending => 'Проверка';

  @override
  String get searchProviderFound => 'Совпадение найдено';

  @override
  String get searchProviderRejected => 'Не совпадает';

  @override
  String get searchProviderFailed => 'Ошибка проверки';

  @override
  String get searchProviderUnavailable => 'Нет подходящих текстов';

  @override
  String get searchCatalogFilterHint =>
      'Выбери песню, чтобы фильтровать версии текста по аккордам, синхронизации или языку.';

  @override
  String get startupErrorTitle => 'Не удалось открыть библиотеку.';

  @override
  String setlistCopyName(String name) {
    return 'Копия: $name';
  }

  @override
  String get setlistSongMissing => 'Песня отсутствует';

  @override
  String get settingsImportTooLarge => 'Этот файл слишком велик для импорта.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Перейти к букве $letter';
  }

  @override
  String get actionDiscard => 'Не сохранять';

  @override
  String get editorKeepEditing => 'Продолжить редактирование';

  @override
  String get settingsDefaultShowChordsHint =>
      'Показывать аккорды над текстом, если они есть у песни.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Текст прокручивается вместе с песней. Не используется в ручном режиме прокрутки.';

  @override
  String get accountUnavailableTitle => 'Синхронизация не настроена';

  @override
  String get accountSignedOutBenefits =>
      'При подключении Google Drive библиотека синхронизируется. После этого изменения песен синхронизируются автоматически.';

  @override
  String get accountManualSyncHint =>
      'Также можно нажать «Синхронизировать», чтобы синхронизировать библиотеку.';

  @override
  String get accountSignInWithGoogle => 'Войти через Google';

  @override
  String get accountWorking => 'Выполняется…';

  @override
  String get accountNeverSynced => 'Ещё не синхронизировалось';

  @override
  String get accountSyncedJustNow => 'Синхронизировано только что';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Синхронизировано $count минуты назад',
      many: 'Синхронизировано $count минут назад',
      few: 'Синхронизировано $count минуты назад',
      one: 'Синхронизировано $count минуту назад',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Синхронизировано $count часа назад',
      many: 'Синхронизировано $count часов назад',
      few: 'Синхронизировано $count часа назад',
      one: 'Синхронизировано $count час назад',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Синхронизировано $count дня назад',
      many: 'Синхронизировано $count дней назад',
      few: 'Синхронизировано $count дня назад',
      one: 'Синхронизировано $count день назад',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count конфликтного изменения сохранено копиями',
      many: '$count конфликтных изменений сохранено копиями',
      few: '$count конфликтных изменения сохранены копиями',
      one: '$count конфликтное изменение сохранено копией',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Одна и та же песня или сет-лист были изменены в двух местах. Ничего не потеряно: другая версия сохранена отдельной копией.';

  @override
  String get accountReviewConflicts => 'Проверить копии';

  @override
  String get songsConflictFilterActive => 'Показаны только конфликтующие копии';

  @override
  String get songsConflictFilterClear => 'Показать все песни';

  @override
  String get songsConflictBadge => 'Конфликтующая копия';

  @override
  String get songsConflictEmpty => 'Конфликтующих копий нет.';

  @override
  String get accountAutoSync => 'Автоматическая синхронизация';

  @override
  String get accountAutoSyncHint =>
      'Синхронизация выполняется после подключения, а также после добавления, изменения или удаления песни.';

  @override
  String get accountDriveFolder => 'Папка библиотеки Google Диска';

  @override
  String get accountPrivateDriveFolder => 'Личная папка Singbook';

  @override
  String get accountChooseDriveFolder => 'Выбрать папку';

  @override
  String get accountDriveFolderMoveTitle => 'Переместить библиотеку Singbook?';

  @override
  String get accountDriveFolderMoveBody =>
      'Выберите видимую папку Google Диска. Singbook скопирует и проверит ваши песни и сетлисты перед переключением на него. Исходные файлы остаются в прежнем месте в качестве резервной копии. Остальные файлы остаются в покое. Файлы ChordPro, которые вы импортируете в эту папку, принимаются для синхронизации и получают метаданные Singbook.';

  @override
  String get accountImportChordPro => 'Импортировать ChordPro с Диска';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'Выбор папки на Диске недоступен';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'Выберите видимую папку на Диске с помощью средства выбора Google Диска на поддерживаемом устройстве.';

  @override
  String get syncErrorDriveFolderMissing => 'Папка Singbook Drive недоступна';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Выберите папку еще раз или восстановите ее на Google Диске.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook требуется доступ к этой папке на Диске';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Снова выберите папку, чтобы предоставить доступ, а затем синхронизируйте свою библиотеку.';

  @override
  String get syncErrorFolderMigration => 'Библиотеку пока нельзя переместить.';

  @override
  String get syncErrorFolderMigrationHint =>
      'Ваша предыдущая библиотека по-прежнему в безопасности. Проверьте соединение и еще раз выберите папку, чтобы повторить попытку.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Сначала выберите видимую папку на Диске';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'Перед импортом файлов с Диска необходима видимая папка библиотеки.';

  @override
  String get accountSignOutTitle => 'Выйти из этого аккаунта?';

  @override
  String get accountSignOutBody =>
      'Песни и сет-листы останутся на этом устройстве. Они не будут сохраняться в резервную копию или синхронизироваться, пока ты не войдёшь снова.';

  @override
  String get accountSignInAgain => 'Войти снова';

  @override
  String get accountChooseAction => 'Выбери, как продолжить';

  @override
  String get accountChangedTitle => 'Другой аккаунт Google';

  @override
  String get accountChangedBody =>
      'В последний раз это устройство синхронизировалось с другим аккаунтом Google. Выбери, что делать с песнями и сет-листами на этом устройстве.';

  @override
  String get accountChangedMerge => 'Объединить с новым аккаунтом';

  @override
  String get accountChangedMergeHint =>
      'Сохрани всё на этом устройстве и добавь данные в новый аккаунт.';

  @override
  String get accountChangedReplace => 'Заменить библиотекой нового аккаунта';

  @override
  String get accountChangedReplaceHint =>
      'Песни с этого устройства, которых нет в новом аккаунте, будут удалены.';

  @override
  String get accountChangedSignOut => 'Отмена и выход';

  @override
  String get accountStatusSignedOut =>
      'Аккаунт и синхронизация: вход не выполнен';

  @override
  String get accountStatusSignedIn => 'Аккаунт и синхронизация: выполнен вход';

  @override
  String get accountStatusSyncing =>
      'Аккаунт и синхронизация: выполняется синхронизация';

  @override
  String get accountStatusSynced =>
      'Аккаунт и синхронизация: библиотека обновлена';

  @override
  String get accountStatusError =>
      'Аккаунт и синхронизация: проблема, нажми для проверки';

  @override
  String get accountNoticeConflicts =>
      'Некоторые песни изменялись в двух местах. Копии сохранены.';

  @override
  String get accountNoticeSignedIn => 'Вход выполнен.';

  @override
  String get accountNoticeSignedOut =>
      'Выполнен выход. Песни останутся на этом устройстве.';

  @override
  String get syncErrorNotConfigured =>
      'В этой версии синхронизация не настроена.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Используй версию Singbook с настроенным входом через Google.';

  @override
  String get syncErrorOAuthClientConfiguration =>
      'Google отклонил настройки входа в эту сборку.';

  @override
  String get syncErrorOAuthClientConfigurationHint =>
      'Проверьте, что указанный OAuth ID принадлежит клиенту Singbook для настольных компьютеров.';

  @override
  String get syncErrorNotSignedIn => 'Вход в аккаунт не выполнен.';

  @override
  String get syncErrorNotSignedInHint =>
      'Войди, чтобы синхронизировать библиотеку.';

  @override
  String get syncErrorAuthorizationRequired => 'Google просит войти снова.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Войди снова, чтобы продолжить синхронизацию. Песни в безопасности на этом устройстве.';

  @override
  String get syncErrorAccessDenied =>
      'У Singbook нет разрешения на использование Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Войди снова и разреши доступ к Drive, когда появится запрос.';

  @override
  String get syncErrorRateLimited => 'Google временно ограничивает запросы.';

  @override
  String get syncErrorRateLimitedHint =>
      'Подожди несколько минут и повтори попытку.';

  @override
  String get syncErrorStorageFull => 'В Google Drive закончилось место.';

  @override
  String get syncErrorStorageFullHint =>
      'Освободи место на Drive и повтори попытку.';

  @override
  String get syncErrorNetwork => 'Не удалось связаться с Google.';

  @override
  String get syncErrorNetworkHint =>
      'Проверь подключение к интернету и повтори попытку.';

  @override
  String get syncErrorAccountChanged => 'Использовался другой аккаунт Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Выбери, объединить библиотеку этого устройства с аккаунтом или заменить её.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Синхронизированная библиотека слишком велика для Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Удали несколько песен или сет-листов из синхронизированной библиотеки и повтори попытку.';

  @override
  String get syncErrorSignInFailed => 'Не удалось завершить вход.';

  @override
  String get syncErrorSignInFailedHint => 'Попробуй войти ещё раз.';

  @override
  String get syncErrorGeneric => 'Не удалось синхронизировать библиотеку.';

  @override
  String get syncErrorGenericHint =>
      'Попробуй ещё раз чуть позже. Песни по-прежнему в безопасности на этом устройстве.';

  @override
  String get editorDurationInvalid =>
      'Введите секунды или минуты и секунды, например 3:45.';

  @override
  String get editorNumberInvalid => 'Введите число.';

  @override
  String get accountReplaceConfirmTitle => 'Удалить локальные песни?';

  @override
  String get accountReplaceConfirmBody =>
      'Песни и сет-листы на этом устройстве, которых нет в новой учётной записи, будут удалены навсегда. Это действие нельзя отменить.';

  @override
  String get accountReplaceConfirmAction => 'Удалить и заменить';

  @override
  String get accountSuspiciousTitle => 'В Google Drive не хватает элементов';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count элемента, ранее синхронизированных с этого устройства, отсутствуют на Google Drive.',
      many:
          '$count элементов, ранее синхронизированных с этого устройства, отсутствуют на Google Drive.',
      few:
          '$count элемента, ранее синхронизированных с этого устройства, отсутствуют на Google Drive.',
      one:
          '$count элемент, ранее синхронизированный с этого устройства, отсутствует на Google Drive.',
    );
    return '$_temp0 Такое может произойти, если данные приложения были очищены в настройках Google. Ничего ещё не удалено.';
  }

  @override
  String get accountSuspiciousDelete => 'Удалить их и здесь';

  @override
  String get accountSuspiciousKeep => 'Оставить песни и загрузить их снова';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count элемента с этого устройства?',
      many: 'Удалить $count элементов с этого устройства?',
      few: 'Удалить $count элемента с этого устройства?',
      one: 'Удалить $count элемент с этого устройства?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Эти песни и сет-листы будут навсегда удалены с этого устройства. Это действие нельзя отменить.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Удалить с этого устройства';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'В Google Drive не хватает элементов.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Ничего не удалено. Выбери, удалить ли их здесь или загрузить снова.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive изменился во время синхронизации.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Ничего не потеряно. Синхронизируй снова, чтобы получить последние изменения.';

  @override
  String get syncErrorInvalidLocalData =>
      'Не удалось синхронизировать некоторые данные на устройстве.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Не удалось прочитать песню или сет-лист. Импортируй или создай их заново, затем синхронизируй.';

  @override
  String get syncErrorNoAccountChange =>
      'Нет изменений аккаунта для разрешения.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Синхронизируй снова, чтобы продолжить.';

  @override
  String get accountSyncWarningTitle =>
      'Синхронизация завершена, но некоторые файлы пропущены';

  @override
  String get accountSyncWarningBody =>
      'Некоторые файлы не удалось использовать, поэтому они оставлены без изменений. Остальные данные обновлены.';

  @override
  String get accountSyncWarningTooLarge =>
      'Файл слишком велик для синхронизации и пропущен. Остальные данные обновлены.';

  @override
  String get accountSyncWarningInvalid =>
      'Не удалось прочитать файл, поэтому он пропущен. Остальные данные обновлены.';

  @override
  String get accountNoticeSyncSkipped =>
      'Синхронизация завершена. Некоторые файлы пропущены.';

  @override
  String get settingsExportPdfTooLarge =>
      'Этот PDF будет слишком большим. Выбери меньше песен или отправь текст.';

  @override
  String get settingsTimingTooLarge =>
      'Данные о времени слишком велики (более 3 МБ).';

  @override
  String get settingsImportDuplicateSongId =>
      'В резервной копии одна и та же песня указана дважды, поэтому ничего не импортировано.';

  @override
  String get setlistSaveConflict =>
      'Сет-лист изменился в другом месте. Твои изменения сохранены отдельной копией.';

  @override
  String get sectionVerse => 'Куплет';

  @override
  String get sectionChorus => 'Припев';

  @override
  String get sectionBridge => 'Бридж';

  @override
  String get sectionIntro => 'Интро';

  @override
  String get sectionOutro => 'Аутро';

  @override
  String get sectionPreChorus => 'Пред-припев';

  @override
  String get sectionPostChorus => 'Пост-припев';

  @override
  String get sectionInstrumental => 'Инструментал';

  @override
  String get sectionInterlude => 'Интерлюдия';

  @override
  String get sectionSolo => 'Соло';

  @override
  String get sectionRefrain => 'Рефрен';

  @override
  String get sectionHook => 'Хук';

  @override
  String get sectionBreakdown => 'Брейкдаун';

  @override
  String get sectionCoda => 'Кода';

  @override
  String get sectionTag => 'Тег';

  @override
  String get sectionEnding => 'Окончание';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count доступной версии',
      many: '$count доступных версий',
      few: '$count доступные версии',
      one: '$count доступная версия',
      zero: 'Нет доступных версий',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недоступной версии',
      many: '$count недоступных версий',
      few: '$count недоступные версии',
      one: '$count недоступная версия',
      zero: 'Нет недоступных версий',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Перейти к разделу';

  @override
  String get searchVersionDetails => 'Сведения о версии';

  @override
  String get searchSelectedRecording => 'Выбранная запись';

  @override
  String get searchVersionDuration => 'Длительность версии';

  @override
  String get searchSourceOptions => 'Параметры источника';

  @override
  String get actionUndo => 'Отменить';

  @override
  String setlistEntryRemoved(String song) {
    return 'Композиция «$song» удалена из сет-листа';
  }

  @override
  String get backupTitle => 'Резервное копирование и восстановление';

  @override
  String get backupExport => 'Экспортировать резервную копию';

  @override
  String get backupSaveToDevice => 'Сохранить резервную копию на устройстве';

  @override
  String get backupRestore => 'Восстановить резервную копию';

  @override
  String get backupIncludePreferences => 'Включить настройки приложения';

  @override
  String get backupRestorePreferences => 'Восстановить настройки приложения';

  @override
  String get backupMerge => 'Добавить в эту библиотеку';

  @override
  String get backupMergeHint =>
      'Сохранить локальные изменения и добавить песни и списки из этой резервной копии.';

  @override
  String get backupReplace => 'Заменить эту библиотеку';

  @override
  String get backupReplaceHint =>
      'Заменить все песни и сет-листы на этом устройстве содержимым этой резервной копии.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Песни: $songs · Сет-листы: $setlists · Конфликты: $conflicts';
  }

  @override
  String get backupFailed =>
      'Не удалось завершить операцию. Попробуйте ещё раз.';

  @override
  String get backupRestored => 'Резервная копия восстановлена.';

  @override
  String get backupLocalHint =>
      'Сохраните копию библиотеки. Данные учётной записи и файлы cookie согласия не включаются.';

  @override
  String get backupReplaceConfirm =>
      'Заменить текущую библиотеку? Это действие нельзя отменить.';

  @override
  String get searchCheckOperations => 'Операции';

  @override
  String get searchCheckCode => 'Код результата';

  @override
  String get searchCheckQueued => 'Ожидание проверки этого источника.';

  @override
  String get searchCheckFetch => 'Загрузить текст песни';

  @override
  String get searchCheckValidate => 'Проверить совпадение песни';

  @override
  String get searchCheckCorroborate => 'Проверить совпадение текста';

  @override
  String get searchCheckCompleted => 'Завершено';

  @override
  String get searchCheckTimeout => 'Источник не ответил вовремя.';

  @override
  String get searchCheckBlocked => 'Источник заблокировал запрос.';

  @override
  String get searchCheckRateLimited =>
      'Источник ограничивает запросы. Повторите попытку позже.';

  @override
  String get searchCheckNetwork =>
      'Не удалось связаться с источником. Проверьте подключение.';

  @override
  String get searchCheckInvalid => 'Источник вернул нечитаемый ответ.';

  @override
  String get searchCheckNotConfigured =>
      'Этот источник не настроен в данной сборке.';

  @override
  String get searchCheckNoLyrics => 'Подходящие тексты песен не найдены.';

  @override
  String get searchCheckFailed => 'Не удалось выполнить эту операцию.';

  @override
  String get searchCheckNoHistory =>
      'Для этого сравнения проверки источников не запускались.';

  @override
  String get searchVersionCredits => 'Авторы и источники';

  @override
  String get searchVersionMediaLinks => 'Связанные ссылки';

  @override
  String get searchCheckCancelled => 'Отменено';

  @override
  String get searchCheckAmbiguous =>
      'Найдено несколько совпадений. Для этого источника нужна более точная запись.';

  @override
  String get searchCheckIdentity =>
      'Для этого источника нужен идентификатор записи или произведения.';

  @override
  String get searchCheckExtraction =>
      'Источник ответил, но не удалось извлечь текст песни.';

  @override
  String get searchCheckBusy => 'Источник занят. Повторите попытку позже.';

  @override
  String get searchCheckSelection =>
      'Выберите конкретный результат из этого источника.';

  @override
  String get playerChordsNone => 'Нет';

  @override
  String get editorCustomValue => 'Другое…';

  @override
  String get editorStandardTuning => 'Стандартный строй';

  @override
  String get editorExampleVerse =>
      '[C]Новый день нас [G]зовёт,\n[Am]мы следуем за светом домой, к [F]порогу.';

  @override
  String get editorExampleChorus =>
      '[F]Споём эту песню [C]вместе,\n[G]пусть мелодия уносит нас [C]вперёд.';

  @override
  String get editorExampleBridge => '[Am]Ещё одна строка, немного [F]ближе.';

  @override
  String get playerEstimatedKey => 'Предполагаемая тональность';

  @override
  String get songsLibraryView => 'Библиотека';

  @override
  String get settingsStartupView => 'Начальный экран';

  @override
  String get settingsStartupViewHint =>
      'Выберите раздел «Песни», который будет открываться при запуске приложения.';

  @override
  String get settingsStartupLastView => 'Последний открытый';

  @override
  String get playerFullScreen => 'Полный экран';

  @override
  String get playerExitFullScreen => 'Выйти из полноэкранного режима';

  @override
  String get playerExpandControls =>
      'Показать элементы управления воспроизведением';

  @override
  String get playerCollapseControls =>
      'Скрыть элементы управления воспроизведением';

  @override
  String get settingsShowSections => 'Показывать заголовки разделов';

  @override
  String get settingsShowSectionsHint =>
      'Показывать в тексте заголовки куплетов, припева и других разделов.';

  @override
  String get settingsShowPlayerControls =>
      'Показать элементы управления воспроизведением';

  @override
  String get settingsShowPlayerControlsHint =>
      'Панель плеера также можно показать или скрыть касанием или свайпом.';

  @override
  String get sourceAnalysisHeading =>
      'Анализ отправленного аудио (не проверен)';

  @override
  String sourceAnalysisCoverage(int shown, int total) {
    return 'Показано $shown из $total отправленных записей';
  }

  @override
  String sourceAnalysisSample(int number) {
    return 'Образец $number';
  }

  @override
  String get sourceAnalysisEstimatedTempo => 'Предполагаемый темп (BPM)';
}
