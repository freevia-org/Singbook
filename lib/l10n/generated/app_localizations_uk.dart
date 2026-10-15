// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Затишне місце, щоб знаходити, упорядковувати й співати зі своєї бібліотеки пісень.';

  @override
  String get aboutMadeForSinging => 'Створено для спільного співу';

  @override
  String appVersion(String version) {
    return 'Версія $version';
  }

  @override
  String get navHome => 'Головна';

  @override
  String get navSongs => 'Пісні';

  @override
  String get navSetlists => 'Сетлисти';

  @override
  String get navSettings => 'Налаштування';

  @override
  String get navSettingsCompact => 'Параметри';

  @override
  String get navSearch => 'Пошук';

  @override
  String get navBack => 'Назад';

  @override
  String get navClose => 'Закрити';

  @override
  String get navMore => 'Інші дії';

  @override
  String get actionCancel => 'Скасувати';

  @override
  String get actionSave => 'Зберегти';

  @override
  String get actionDone => 'Готово';

  @override
  String get actionEdit => 'Редагувати';

  @override
  String get actionDelete => 'Видалити';

  @override
  String get actionShare => 'Поділитися';

  @override
  String get actionPrint => 'Друк';

  @override
  String get actionCopy => 'Копіювати';

  @override
  String get actionClear => 'Очистити';

  @override
  String get actionRetry => 'Повторити';

  @override
  String get actionRefresh => 'Оновити';

  @override
  String get actionImport => 'Імпортувати';

  @override
  String get actionExport => 'Експортувати';

  @override
  String get actionExpand => 'Розгорнути';

  @override
  String get actionCollapse => 'Згорнути';

  @override
  String get actionAdd => 'Додати';

  @override
  String get actionCreate => 'Створити';

  @override
  String get actionRemove => 'Прибрати';

  @override
  String get actionDuplicate => 'Дублювати';

  @override
  String get actionMoveUp => 'Перемістити вгору';

  @override
  String get actionMoveDown => 'Перемістити вниз';

  @override
  String get actionPrevious => 'Попередній';

  @override
  String get actionNext => 'Наступний';

  @override
  String get searchHint => 'Шукайте пісні, виконавців або слова';

  @override
  String get searchCatalogHint => 'Шукайте пісню або виконавця';

  @override
  String get searchChangeSong => 'Змінити пісню';

  @override
  String get searchSelectedPreview => 'Вибраний перегляд';

  @override
  String get searchSubmit => 'Шукати';

  @override
  String get searchFilters => 'Параметри пошуку';

  @override
  String get searchFiltersShow => 'Показати параметри пошуку';

  @override
  String get searchFiltersHide => 'Сховати параметри пошуку';

  @override
  String get searchFilterArtist => 'Виконавець';

  @override
  String get searchFilterTitle => 'Назва пісні';

  @override
  String get searchFilterLyrics => 'Текст';

  @override
  String get searchFilterChords => 'З акордами';

  @override
  String get searchFilterTimed => 'Текст із таймінгом';

  @override
  String get searchFilterLanguage => 'Мова';

  @override
  String get searchFilterAll => 'Усі';

  @override
  String get searchAutocompleteLabel => 'Підказки';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результату',
      many: '$count результатів',
      few: '$count результати',
      one: '$count результат',
      zero: 'Немає результатів',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Введіть назву пісні, виконавця або слова для пошуку.';

  @override
  String get searchCatalogEmptyQuery =>
      'Введіть назву пісні або виконавця для пошуку.';

  @override
  String get searchNoResults => 'Пісень не знайдено. Спробуйте інший запит.';

  @override
  String get searchLoading => 'Пошук пісень…';

  @override
  String get searchError => 'Не вдалося завершити пошук.';

  @override
  String get searchOnlineTab => 'Онлайн';

  @override
  String get searchRecentTab => 'Останні';

  @override
  String get searchFavoritesTab => 'Обране';

  @override
  String get searchSuggested => 'Рекомендований збіг';

  @override
  String get searchAlternatives => 'Інші збіги';

  @override
  String get searchCompare => 'Порівняти версії';

  @override
  String get searchChooseVersion => 'Вибрати цю версію';

  @override
  String get searchSongMatch => 'Збіг пісні';

  @override
  String get searchRecordingMatch => 'Збіг запису';

  @override
  String get searchMatchUnverified => 'Запис не підтверджено';

  @override
  String get searchMatchExact => 'Точний збіг запису';

  @override
  String get searchMatchPossible => 'Можливий збіг';

  @override
  String get searchAvailability => 'Доступність';

  @override
  String get searchLyricsAvailable => 'Текст доступний';

  @override
  String get searchLyricsUnavailable => 'Текст недоступний';

  @override
  String get searchChordsAvailable => 'Акорди доступні';

  @override
  String get searchChordsUnavailable => 'Без акордів';

  @override
  String get searchTimingAvailable => 'Таймінг доступний';

  @override
  String get searchTimingUnavailable => 'Таймінгу немає';

  @override
  String get searchDurationUnknown => 'Тривалість невідома';

  @override
  String searchRating(String rating) {
    return 'Оцінка $rating';
  }

  @override
  String get searchSourceLabel => 'Джерело';

  @override
  String get searchMetadata => 'Відомості про пісню';

  @override
  String get searchAlbum => 'Альбом';

  @override
  String get searchArtist => 'Виконавець';

  @override
  String get searchYear => 'Рік';

  @override
  String get searchLanguage => 'Мова';

  @override
  String get searchViewVersions => 'Переглянути версії';

  @override
  String get searchSaved => 'Пісню збережено у вашій бібліотеці.';

  @override
  String get searchSaveOpenLyrics => 'Зберегти й відкрити текст';

  @override
  String get searchOtherResults => 'Інші результати';

  @override
  String get searchSaveFailed => 'Не вдалося зберегти пісню.';

  @override
  String get homeRecentSongs => 'Останні пісні';

  @override
  String get homeRecentlyPlayed => 'Нещодавно відтворені';

  @override
  String get homeFavorites => 'Обране';

  @override
  String get homeHistory => 'Історія';

  @override
  String get homeHistoryClear => 'Очистити історію';

  @override
  String get homeHistoryCleared => 'Історію очищено.';

  @override
  String get homeHistoryEmpty => 'Відкриті пісні з’являтимуться тут.';

  @override
  String get homeFavoritesEmpty =>
      'Обрані пісні й сетлисти з’являтимуться тут.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Показано $count елемента',
      many: 'Показано $count елементів',
      few: 'Показано $count елементи',
      one: 'Показано $count елемент',
      zero: 'Показано 0 елементів',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty => 'Останні пісні й сетлисти з’являтимуться тут.';

  @override
  String get homeTimelineLabel => 'Шкала історії';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Уся історія';

  @override
  String get homeShowFavorites => 'Показати обране';

  @override
  String get homeShowRecent => 'Показати останні';

  @override
  String get songsTitle => 'Пісні';

  @override
  String get songsEmpty => 'Ваші пісні з’являтимуться тут.';

  @override
  String get songsEmptySearch => 'Пісень за цим запитом не знайдено.';

  @override
  String get songsAdd => 'Додати пісню';

  @override
  String get songsSortAlphabetical => 'Сортувати за абеткою';

  @override
  String get songsAlphabetNavigation => 'Індекс пісень';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count разу',
      many: '$count разів',
      few: '$count рази',
      one: '$count раз',
      zero: 'жодного разу',
    );
    return 'Відкрито $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Додати до обраного';

  @override
  String get songFavoriteRemove => 'Прибрати з обраного';

  @override
  String get songMenuLabel => 'Дії з піснею';

  @override
  String get songInfo => 'Відомості про пісню';

  @override
  String get setlistMenuLabel => 'Дії із сетлистом';

  @override
  String get songAddToSetlist => 'Додати до сетлисту';

  @override
  String get songCopyChordPro => 'Копіювати ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Видалити пісню?';

  @override
  String get songDeleteConfirmMessage => 'Пісню буде прибрано з бібліотеки.';

  @override
  String get songDeleted => 'Пісню видалено.';

  @override
  String get setlistsTitle => 'Сетлисти';

  @override
  String get setlistsEmpty =>
      'Створіть сетлист для наступної репетиції чи виступу.';

  @override
  String get setlistsEmptySearch => 'Сетлистів за цим запитом не знайдено.';

  @override
  String get setlistCreate => 'Новий сетлист';

  @override
  String get setlistNameHint => 'Назва сетлисту';

  @override
  String get setlistNotes => 'Нотатки';

  @override
  String get setlistEntryOverride => 'Тональність і каподастр для цієї пісні';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пісні',
      many: '$count пісень',
      few: '$count пісні',
      one: '$count пісня',
      zero: 'Немає пісень',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Щонайменше $duration';
  }

  @override
  String get setlistDurationUnknown => 'Тривалість невідома';

  @override
  String setlistActivity(String date) {
    return 'Остання дія $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Створено $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Змінено $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Востаннє відтворено $date';
  }

  @override
  String get setlistSongsEmpty => 'У цьому сетлисті ще немає пісень.';

  @override
  String get setlistAddSongs => 'Додати пісні';

  @override
  String get setlistReorder => 'Змінити порядок пісень';

  @override
  String setlistMoveSongUp(String song) {
    return 'Перемістити $song вгору';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Перемістити $song вниз';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Прибрати $song із сетлисту';
  }

  @override
  String get setlistDuplicate => 'Дублювати сетлист';

  @override
  String get setlistFavoriteAdd => 'Додати сетлист до обраного';

  @override
  String get setlistFavoriteRemove => 'Прибрати сетлист з обраного';

  @override
  String get setlistShare => 'Поділитися файлом сетлисту';

  @override
  String get setlistSharePdf => 'Поділитися як PDF';

  @override
  String get setlistPrint => 'Друк';

  @override
  String get setlistDeleteConfirmTitle => 'Видалити сетлист?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Сетлист буде видалено. Пісні у бібліотеці залишаться.';

  @override
  String get setlistDeleted => 'Сетлист видалено.';

  @override
  String get readerTitle => 'Текст пісні';

  @override
  String get readerNoLyrics => 'Текст ще не додано.';

  @override
  String get readerShowChords => 'Показати акорди';

  @override
  String get readerHideChords => 'Сховати акорди';

  @override
  String get readerTranspose => 'Транспонувати акорди';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count півтона',
      many: '$count півтонів',
      few: '$count півтони',
      one: '$count півтон',
      zero: '0 півтонів',
    );
    return 'Транспонувати на $_temp0';
  }

  @override
  String get readerSaved => 'Збережено';

  @override
  String get readerEdit => 'Редагувати текст і відомості';

  @override
  String get playerPlay => 'Почати прокручування тексту';

  @override
  String get playerPause => 'Призупинити прокручування';

  @override
  String get playerResume => 'Продовжити прокручування';

  @override
  String get playerSeek => 'Позиція відтворення';

  @override
  String playerElapsed(String time) {
    return 'Минуло $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Залишилося $time';
  }

  @override
  String get playerTimingMode => 'Режим прокручування';

  @override
  String get playerTimedLyrics => 'Текст із таймінгом';

  @override
  String get playerStartScroll => 'Почати автопрокручування';

  @override
  String get playerEstimatedPace => 'Приблизний темп';

  @override
  String get playerScrollSpeed => 'Швидкість прокручування';

  @override
  String playerEstimatedDuration(String time) {
    return 'Орієнтовна тривалість: $time';
  }

  @override
  String get playerLyricsOnly => 'Прокручування тексту · без аудіо';

  @override
  String get playerManualScroll => 'Ручне прокручування';

  @override
  String get playerTimingStatusReady =>
      'Текст прокручуватиметься за наявним таймінгом.';

  @override
  String get playerTimingStatusEstimated =>
      'Темп прокручування оцінено за тривалістю пісні.';

  @override
  String get playerTimingStatusManual => 'Прокручуйте текст самостійно.';

  @override
  String get playerTimingStatusUnavailable =>
      'Таймінг для цієї пісні недоступний.';

  @override
  String get playerDurationUnknown =>
      'Додайте тривалість пісні для приблизного прокручування.';

  @override
  String get playerProgressLabel => 'Перебіг пісні';

  @override
  String get playerCurrentSection => 'Поточний розділ';

  @override
  String get playerPreviousSection => 'Попередній розділ';

  @override
  String get playerNextSection => 'Наступний розділ';

  @override
  String get playerPreviousSectionSong =>
      'Попередній розділ · утримуйте для попередньої пісні сетлисту';

  @override
  String get playerNextSectionSong =>
      'Наступний розділ · утримуйте для наступної пісні сетлисту';

  @override
  String get playerPreviousSong => 'Попередня пісня';

  @override
  String get playerNextSong => 'Наступна пісня';

  @override
  String get editorTitle => 'Редагувати пісню';

  @override
  String get editorTitleField => 'Назва пісні';

  @override
  String get editorArtistField => 'Виконавець';

  @override
  String get editorAlbumField => 'Альбом';

  @override
  String get editorLyricsField => 'Текст';

  @override
  String get editorChordsField => 'Акорди';

  @override
  String get editorKeyField => 'Тональність';

  @override
  String get editorCapoField => 'Каподастр';

  @override
  String get editorTuningField => 'Стрій';

  @override
  String get editorTempoField => 'Темп';

  @override
  String get editorDurationField => 'Тривалість';

  @override
  String get editorTimeSignatureField => 'Розмір такту';

  @override
  String get editorLanguageField => 'Мова';

  @override
  String get editorYearField => 'Рік';

  @override
  String get editorComposerField => 'Композитор';

  @override
  String get editorLyricistField => 'Автор тексту';

  @override
  String get editorCopyrightField => 'Авторське право';

  @override
  String get editorLicenseField => 'Ліцензія';

  @override
  String get songInfoSources => 'Джерела й атрибуція';

  @override
  String get searchMatchSameSong => 'Та сама пісня; запис не підтверджено';

  @override
  String get searchMatchNeedsAgreement => 'Потрібне підтвердження за текстом';

  @override
  String get searchMatchDifferentLyrics =>
      'Текст відрізняється від вибраної пісні';

  @override
  String get searchMatchCombinedSources => 'Дані зведено з кількох джерел';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Об’єднано з $count джерела',
      many: 'Об’єднано з $count джерел',
      few: 'Об’єднано з $count джерел',
      one: 'Об’єднано з $count джерела',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count збігу пісень',
      many: '$count збігів пісень',
      few: '$count збіги пісень',
      one: '$count збіг пісні',
      zero: '0 збігів пісень',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count версії джерел',
      many: '$count версій джерел',
      few: '$count версії джерел',
      one: '$count версія джерела',
      zero: '0 версій джерел',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Найкращий доступний збіг';

  @override
  String get providerDescriptionUnknown => 'Джерело пісень';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Завантажте файл ChordPro з джерела та імпортуйте його.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Завантажте файл із безкоштовним обліковим записом та імпортуйте його.';

  @override
  String get providerDescPublicChordSheets => 'Відкриті тексти з акордами.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Архівні тексти з ліцензією на кожен твір.';

  @override
  String get providerDescLicensedCatalog => 'Ліцензований каталог текстів.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Авторські пісні за ліцензією Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Тексти з окремою ліцензією для кожної пісні.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Лише дані про записи та релізи.';

  @override
  String get providerDescCompositionMetadataOnly => 'Лише дані про композиції.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Обкладинки лише для точного збігу запису.';

  @override
  String get providerCapabilityLyrics => 'Тексти';

  @override
  String get providerCapabilityChords => 'Акорди';

  @override
  String get providerCapabilityTiming => 'Таймінг тексту';

  @override
  String get providerCapabilitySearch => 'Пошук';

  @override
  String get providerCapabilityMetadata => 'Дані про пісню';

  @override
  String get editorArtworkField => 'Посилання на зображення';

  @override
  String get editorLyricsHint =>
      'Торкніться рядка, щоб редагувати текст або акорди.';

  @override
  String get editorSave => 'Зберегти зміни';

  @override
  String get editorSaved => 'Зміни збережено.';

  @override
  String get editorSaveFailed => 'Не вдалося зберегти зміни.';

  @override
  String get editorSaveConflict =>
      'Пісню змінено деінде. Ваші зміни збережено як окрему копію.';

  @override
  String get editorUnsavedTitle => 'Відхилити зміни?';

  @override
  String get editorUnsavedMessage => 'Ваші зміни не збережено.';

  @override
  String get editorFieldRequired => 'Введіть назву пісні.';

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get settingsAppearance => 'Вигляд';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeSystem => 'Як на пристрої';

  @override
  String get settingsThemeLight => 'Світла';

  @override
  String get settingsThemeDark => 'Темна';

  @override
  String get settingsColorPalette => 'Палітра кольорів';

  @override
  String get settingsFont => 'Шрифт';

  @override
  String get settingsTextSize => 'Розмір тексту';

  @override
  String get settingsLyricsPreview => 'Попередній перегляд тексту';

  @override
  String get settingsPlayer => 'Прокручування тексту';

  @override
  String get settingsDefaultShowChords => 'Показувати акорди за замовчуванням';

  @override
  String get settingsDefaultAutoscroll =>
      'Автоматично прокручувати після запуску';

  @override
  String get settingsDefaultTiming => 'Режим прокручування за замовчуванням';

  @override
  String get settingsLanguage => 'Мова програми';

  @override
  String get settingsLanguageSystem => 'Мова пристрою';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Джерела текстів';

  @override
  String settingsSourceEnabled(String source) {
    return 'Увімкнути джерело $source';
  }

  @override
  String get settingsSourceRefresh => 'Оновити список джерел';

  @override
  String get settingsSourcesUpdated => 'Список джерел оновлено.';

  @override
  String get settingsSourcesUpdateFailed => 'Не вдалося оновити джерела.';

  @override
  String get settingsImport => 'Імпорт пісень';

  @override
  String get settingsImportChordPro => 'Імпортувати файл ChordPro';

  @override
  String get settingsImportSetlist => 'Імпортувати файл сетлисту';

  @override
  String get settingsImportSuccess => 'Імпорт завершено.';

  @override
  String get settingsImportFailed => 'Не вдалося імпортувати файл.';

  @override
  String get settingsImportUnsupported => 'Цей тип файлу не підтримується.';

  @override
  String get settingsShareSong => 'Поділитися як ChordPro';

  @override
  String get settingsSharePdf => 'Поділитися як PDF';

  @override
  String get settingsCopySong => 'Копіювати до буфера обміну';

  @override
  String get settingsPrintSong => 'Лише друк';

  @override
  String get settingsPrintSetlist => 'Друкувати сетлист із текстами';

  @override
  String get settingsExportFailed => 'Не вдалося підготувати файл.';

  @override
  String get settingsCopied => 'Скопійовано до буфера обміну.';

  @override
  String get settingsAbout => 'Про програму';

  @override
  String get settingsPrivacy => 'Конфіденційність';

  @override
  String get settingsLegal => 'Правова інформація';

  @override
  String get settingsClearHistory => 'Очистити історію';

  @override
  String get settingsClearHistoryConfirm =>
      'Очистити історію пісень і сетлистів?';

  @override
  String get settingsHistoryCleared => 'Історію очищено.';

  @override
  String get accountTitle => 'Обліковий запис і синхронізація';

  @override
  String get accountUnavailable =>
      'Для синхронізації потрібна збірка Singbook із налаштованим входом через Google. Ця збірка зберігає пісні лише на цьому пристрої.';

  @override
  String get accountSyncNow => 'Синхронізувати зараз';

  @override
  String get accountConnected =>
      'Підключено. Натисніть «Синхронізувати зараз», щоб оновити резервну копію.';

  @override
  String get accountSignIn => 'Підключити обліковий запис';

  @override
  String get accountSignOut => 'Вийти';

  @override
  String get accountChange => 'Змінити обліковий запис';

  @override
  String get accountSignedOut => 'Не підключено';

  @override
  String get accountSyncing => 'Синхронізація бібліотеки…';

  @override
  String get accountSynced => 'Бібліотеку синхронізовано.';

  @override
  String get accountSyncFailed => 'Не вдалося синхронізувати бібліотеку.';

  @override
  String get accessibilityFavorite => 'В обраному';

  @override
  String get accessibilityNotFavorite => 'Не в обраному';

  @override
  String get accessibilitySearchField => 'Пошук пісень';

  @override
  String get accessibilityClearSearch => 'Очистити пошуковий текст';

  @override
  String accessibilitySongMenu(String song) {
    return 'Дії для пісні $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Дії для сетлисту $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Розгорнути пісні в сетлисті $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Згорнути пісні в сетлисті $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Перебіг відтворення: $percent%';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Шкала історії, $date';
  }

  @override
  String get loading => 'Завантаження…';

  @override
  String get loadingSongs => 'Завантаження пісень…';

  @override
  String get loadingSetlists => 'Завантаження сетлистів…';

  @override
  String get errorGeneric => 'Сталася помилка.';

  @override
  String get errorOffline => 'Схоже, немає підключення до мережі.';

  @override
  String get errorPermission => 'Для продовження потрібен дозвіл.';

  @override
  String get emptyFiltered => 'Немає елементів, що відповідають фільтрам.';

  @override
  String get unknownValue => 'Невідомо';

  @override
  String get durationUnknown => 'Тривалість невідома';

  @override
  String get metadataNotSet => 'Не вказано';

  @override
  String get dateToday => 'Сьогодні';

  @override
  String get dateYesterday => 'Учора';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пісні',
      many: '$count пісень',
      few: '$count пісні',
      one: '$count пісня',
      zero: 'Немає пісень',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Темно-синя';

  @override
  String get settingsPaletteSage => 'Шавлія';

  @override
  String get settingsPaletteOcean => 'Океан';

  @override
  String get settingsPaletteClay => 'Глина';

  @override
  String get settingsPalettePlum => 'Слива';

  @override
  String get settingsFontSystem => 'Системний';

  @override
  String get settingsFontSerif => 'Засічковий';

  @override
  String get settingsFontMonospace => 'Моноширинний';

  @override
  String get settingsLyricsPreviewExample =>
      'Коли настане ранок, ми знову заспіваємо.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Перевірено $checked із $total джерел текстів.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Не знайдено придатних текстів.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Вибрану пісню перевірено в увімкнених джерелах, але придатної версії тексту немає.';

  @override
  String get searchDiscoveryError => 'Не вдалося перевірити джерела текстів.';

  @override
  String get searchDiscoveryRetry => 'Повторити пошук текстів';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Недоступного джерела: $count',
      many: 'Недоступних джерел: $count',
      few: 'Недоступні джерела: $count',
      one: 'Недоступне джерело: $count',
      zero: 'Недоступних джерел: 0',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Перевірте підключення та спробуйте ще раз.';

  @override
  String get searchProviderChecks => 'Перевірка джерел';

  @override
  String get searchProviderPending => 'Перевіряється';

  @override
  String get searchProviderFound => 'Знайдено збіг';

  @override
  String get searchProviderRejected => 'Не збігається';

  @override
  String get searchProviderFailed => 'Помилка перевірки';

  @override
  String get searchProviderUnavailable => 'Немає придатного тексту';

  @override
  String get searchCatalogFilterHint =>
      'Виберіть пісню, щоб фільтрувати версії тексту за акордами, таймінгом або мовою.';

  @override
  String get startupErrorTitle => 'Не вдалося відкрити бібліотеку.';

  @override
  String setlistCopyName(String name) {
    return '$name (копія)';
  }

  @override
  String get setlistSongMissing => 'Пісню не знайдено';

  @override
  String get settingsImportTooLarge => 'Файл завеликий для імпорту.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Перейти до літери $letter';
  }

  @override
  String get actionDiscard => 'Відхилити';

  @override
  String get editorKeepEditing => 'Продовжити редагування';

  @override
  String get settingsDefaultShowChordsHint =>
      'Акорди показуються над текстом, якщо пісня їх має.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Текст прокручується разом із піснею. Не діє в ручному режимі прокручування.';

  @override
  String get accountUnavailableTitle => 'Синхронізацію не налаштовано';

  @override
  String get accountSignedOutBenefits =>
      'Увійдіть через Google, щоб зберігати резервну копію пісень і сетлистів на Google Drive та синхронізувати всі свої пристрої. Пісні в будь-якому разі залишаються на цьому пристрої.';

  @override
  String get accountSignInWithGoogle => 'Увійти через Google';

  @override
  String get accountWorking => 'Зачекайте…';

  @override
  String get accountNeverSynced => 'Ще не синхронізовано';

  @override
  String get accountSyncedJustNow => 'Синхронізовано щойно';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Синхронізовано $count хвилини тому',
      many: 'Синхронізовано $count хвилин тому',
      few: 'Синхронізовано $count хвилини тому',
      one: 'Синхронізовано $count хвилину тому',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Синхронізовано $count години тому',
      many: 'Синхронізовано $count годин тому',
      few: 'Синхронізовано $count години тому',
      one: 'Синхронізовано $count годину тому',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Синхронізовано $count дня тому',
      many: 'Синхронізовано $count днів тому',
      few: 'Синхронізовано $count дні тому',
      one: 'Синхронізовано $count день тому',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Збережено $count конфліктної зміни як копії',
      many: 'Збережено $count конфліктних змін як копії',
      few: 'Збережено $count конфліктні зміни як копії',
      one: 'Збережено $count конфліктну зміну як копію',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Ту саму пісню або той самий сетлист змінили в двох місцях. Нічого не втрачено: іншу версію збережено як окрему копію.';

  @override
  String get accountReviewConflicts => 'Переглянути копії';

  @override
  String get songsConflictFilterActive => 'Показано лише копії через конфлікт';

  @override
  String get songsConflictFilterClear => 'Показати всі пісні';

  @override
  String get songsConflictBadge => 'Копія через конфлікт';

  @override
  String get songsConflictEmpty => 'Немає копій через конфлікт.';

  @override
  String get accountAutoSync => 'Синхронізувати автоматично';

  @override
  String get accountAutoSyncHint =>
      'Підтримувати бібліотеку актуальною під час відкриття застосунку та після змін.';

  @override
  String get accountSignOutTitle => 'Вийти з облікового запису?';

  @override
  String get accountSignOutBody =>
      'Ваші пісні та сетлисти залишаться на цьому пристрої. Їх не буде збережено в резервній копії та синхронізовано, доки ви не ввійдете знову.';

  @override
  String get accountUseDifferent => 'Використати інший обліковий запис';

  @override
  String get accountSignInAgain => 'Увійти знову';

  @override
  String get accountChooseAction => 'Обрати подальші дії';

  @override
  String get accountChangedTitle => 'Інший обліковий запис Google';

  @override
  String get accountChangedBody =>
      'Цей пристрій востаннє синхронізувався з іншим обліковим записом Google. Оберіть, що робити з піснями та сетлистами на пристрої.';

  @override
  String get accountChangedMerge => 'Об’єднати з новим обліковим записом';

  @override
  String get accountChangedMergeHint =>
      'Залишає все на пристрої та додає до нового облікового запису.';

  @override
  String get accountChangedReplace =>
      'Замінити бібліотекою нового облікового запису';

  @override
  String get accountChangedReplaceHint =>
      'Пісні на пристрої, яких немає в новому обліковому записі, буде видалено.';

  @override
  String get accountChangedSignOut => 'Скасувати й вийти';

  @override
  String get accountStatusSignedOut =>
      'Обліковий запис і синхронізація: вхід не виконано';

  @override
  String get accountStatusSignedIn =>
      'Обліковий запис і синхронізація: вхід виконано';

  @override
  String get accountStatusSyncing =>
      'Обліковий запис і синхронізація: триває синхронізація';

  @override
  String get accountStatusSynced =>
      'Обліковий запис і синхронізація: бібліотека актуальна';

  @override
  String get accountStatusError =>
      'Обліковий запис і синхронізація: проблема, торкніться, щоб переглянути';

  @override
  String get accountNoticeConflicts =>
      'Деякі пісні змінили в двох місцях. Копії збережено.';

  @override
  String get accountNoticeSignedIn => 'Вхід виконано.';

  @override
  String get accountNoticeSignedOut =>
      'Ви вийшли. Пісні залишаються на цьому пристрої.';

  @override
  String get syncErrorNotConfigured =>
      'Синхронізацію не налаштовано в цій збірці.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Скористайтеся збіркою Singbook із налаштованим входом через Google.';

  @override
  String get syncErrorNotSignedIn => 'Вхід не виконано.';

  @override
  String get syncErrorNotSignedInHint =>
      'Увійдіть, щоб синхронізувати бібліотеку.';

  @override
  String get syncErrorAuthorizationRequired => 'Google просить увійти знову.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Увійдіть знову, щоб продовжити синхронізацію. Ваші пісні в безпеці на пристрої.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook не має дозволу на використання Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Увійдіть знову й надайте доступ до Drive, коли з’явиться запит.';

  @override
  String get syncErrorRateLimited => 'Google тимчасово обмежує запити.';

  @override
  String get syncErrorRateLimitedHint =>
      'Зачекайте кілька хвилин і спробуйте ще раз.';

  @override
  String get syncErrorStorageFull => 'Google Drive заповнений.';

  @override
  String get syncErrorStorageFullHint =>
      'Звільніть місце на Drive і спробуйте ще раз.';

  @override
  String get syncErrorNetwork => 'Не вдалося зв’язатися з Google.';

  @override
  String get syncErrorNetworkHint =>
      'Перевірте підключення до інтернету й спробуйте ще раз.';

  @override
  String get syncErrorAccountChanged =>
      'Використано інший обліковий запис Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Оберіть: об’єднати бібліотеку пристрою з ним чи замінити її.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Синхронізована бібліотека більша, ніж може обробити Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Видаліть частину пісень або сетлистів із синхронізованої бібліотеки й спробуйте ще раз.';

  @override
  String get syncErrorSignInFailed => 'Вхід не завершено.';

  @override
  String get syncErrorSignInFailedHint => 'Спробуйте увійти знову.';

  @override
  String get syncErrorGeneric => 'Не вдалося синхронізувати бібліотеку.';

  @override
  String get syncErrorGenericHint =>
      'Спробуйте ще раз трохи згодом. Ваші пісні в безпеці на пристрої.';
}
