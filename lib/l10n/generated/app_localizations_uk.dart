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
      'Тексти, акорди й сетлисти разом — готові до репетиції, сцени та будь-якого місця, де ви граєте.';

  @override
  String get aboutMadeForSinging => 'Кожна пісня готова.';

  @override
  String get aboutDetails =>
      'Шукайте в доступних джерелах і порівнюйте тексти, акорди, таймінг та відомості про запис, перш ніж зберегти потрібну версію. Доступність залежить від пісні та сервісу.';

  @override
  String get aboutFindTitle => 'Знайдіть потрібну версію';

  @override
  String get aboutKeepTitle => 'Створіть власну бібліотеку';

  @override
  String get aboutKeepDetails =>
      'Редагуйте й транспонуйте пісні, зберігайте їх у локальній бібліотеці для використання офлайн і діліться переносними файлами ChordPro. Необов’язкова синхронізація з Google Drive використовує приватну папку додатка у вашому обліковому записі Google. Також можна натиснути «Синхронізувати зараз», щоб оновити пристрої.';

  @override
  String get aboutPlayTitle => 'Візьміть сетлист на сцену';

  @override
  String get aboutPlayDetails =>
      'Упорядковуйте пісні в сетлисти, вибирайте тональність для кожної та діліться сетлистами OpenSong. Налаштовуйте розмір тексту в читачі, вмикайте автоматичне прокручування тексту й друкуйте PDF-файли пісень. Singbook не транслює та не відтворює аудіо.';

  @override
  String get aboutPrivacyTitle =>
      'Безкоштовно, бібліотека зберігається локально';

  @override
  String get aboutPrivacyDetails =>
      'Singbook безкоштовний: без реклами, аналітики та покупок у додатку. Збережена бібліотека лишається на вашому пристрої; для необов’язкової синхронізації використовується ваш Google Drive. Результати онлайн-пошуку надходять безпосередньо від незалежних сторонніх сервісів і можуть бути недоступними або захищеними авторським правом. Singbook не розміщує цей вміст.';

  @override
  String get aboutWebsite => 'Вебсайт Singbook';

  @override
  String get aboutSourceCode => 'Вихідний код на GitHub';

  @override
  String get aboutPublisher => 'Від Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Мови додатка: $count';
  }

  @override
  String get aboutSupport => 'Підтримка та відгуки';

  @override
  String get menuTypeNewSong => 'Ввести нову пісню';

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
  String get appExitBackAgain => 'Натисніть «Назад» ще раз, щоб вийти';

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
  String get searchFullPreview => 'Повний перегляд';

  @override
  String get searchArrangementNotes => 'Примітки щодо аранжування';

  @override
  String get searchOpenLyrics => 'Відкрити текст';

  @override
  String get searchContributions => 'Використані джерела';

  @override
  String get searchVersionChecking => 'Перевірка цієї версії…';

  @override
  String get searchVersionUnavailable =>
      'Цю версію не можна використати. Виберіть іншу.';

  @override
  String get searchPreviewUnavailable =>
      'Попередній перегляд тексту недоступний.';

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
  String get playerPlay => 'Відтворити';

  @override
  String get playerPause => 'Пауза';

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
  String get searchCombinedLabel => 'Об’єднані';

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
      'Акорди в дужках [C]; маркери частин на окремих рядках.';

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
  String get settingsLyricHighlight => 'Підсвічування поточного рядка';

  @override
  String get settingsHighlightBackgroundUnderline => 'Тло + підкреслення';

  @override
  String get settingsHighlightBackground => 'Тло';

  @override
  String get settingsHighlightUnderline => 'Підкреслення';

  @override
  String get settingsHighlightContrast => 'Контрастний колір тексту';

  @override
  String get settingsHighlightNone => 'Немає';

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
      'Після підключення Google Drive бібліотека синхронізується. Надалі зміни пісень синхронізуються автоматично.';

  @override
  String get accountManualSyncHint =>
      'Також можна натиснути «Синхронізувати зараз», щоб синхронізувати бібліотеку.';

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
      'Синхронізація відбувається після підключення, а також після додавання, редагування чи видалення пісні.';

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

  @override
  String get editorDurationInvalid =>
      'Введіть секунди або хвилини й секунди, наприклад 3:45.';

  @override
  String get editorNumberInvalid => 'Введіть число.';

  @override
  String get accountReplaceConfirmTitle => 'Видалити локальні пісні?';

  @override
  String get accountReplaceConfirmBody =>
      'Пісні та сетлисти на цьому пристрої, яких немає в новому обліковому записі, буде остаточно видалено. Цю дію неможливо скасувати.';

  @override
  String get accountReplaceConfirmAction => 'Видалити й замінити';

  @override
  String get accountSuspiciousTitle => 'У Google Drive бракує елементів';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count елемента, які цей пристрій синхронізував раніше, відсутні у Google Drive.',
      many:
          '$count елементів, які цей пристрій синхронізував раніше, відсутні у Google Drive.',
      few:
          '$count елементи, які цей пристрій синхронізував раніше, відсутні у Google Drive.',
      one:
          '$count елемент, який цей пристрій синхронізував раніше, відсутній у Google Drive.',
    );
    return '$_temp0 Таке може статися, якщо дані програми очистили в налаштуваннях Google. Поки що нічого не видалено.';
  }

  @override
  String get accountSuspiciousDelete => 'Видалити їх і тут';

  @override
  String get accountSuspiciousKeep =>
      'Залишити мої пісні та завантажити їх знову';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Видалити $count елемента із цього пристрою?',
      many: 'Видалити $count елементів із цього пристрою?',
      few: 'Видалити $count елементи із цього пристрою?',
      one: 'Видалити $count елемент із цього пристрою?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Ці пісні та сетлисти буде остаточно видалено з цього пристрою. Цю дію неможливо скасувати.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Видалити з цього пристрою';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'У Google Drive бракує елементів.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Нічого не видалено. Оберіть: видалити їх і тут чи завантажити знову.';

  @override
  String get syncErrorRemoteChanged =>
      'Вміст Google Drive змінився під час синхронізації.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Нічого не втрачено. Синхронізуйте ще раз, щоб отримати останні зміни.';

  @override
  String get syncErrorInvalidLocalData =>
      'Деякі дані на цьому пристрої не вдалося синхронізувати.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Пісню або сетлист не вдалося прочитати. Імпортуйте або створіть його знову й повторіть синхронізацію.';

  @override
  String get syncErrorNoAccountChange =>
      'Немає зміни облікового запису, яку потрібно вирішити.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Синхронізуйте ще раз, щоб продовжити.';

  @override
  String get accountSyncWarningTitle =>
      'Синхронізовано, але деякі файли пропущено';

  @override
  String get accountSyncWarningBody =>
      'Деякі файли не вдалося використати, тому їх залишено без змін. Решту оновлено.';

  @override
  String get accountSyncWarningTooLarge =>
      'Один файл завеликий для синхронізації, тому його пропущено. Решту оновлено.';

  @override
  String get accountSyncWarningInvalid =>
      'Один файл не вдалося прочитати, тому його пропущено. Решту оновлено.';

  @override
  String get accountNoticeSyncSkipped =>
      'Синхронізовано. Деякі файли пропущено.';

  @override
  String get settingsExportPdfTooLarge =>
      'Цей PDF був би завеликим. Спробуйте менше пісень або поділіться текстом.';

  @override
  String get settingsTimingTooLarge => 'Дані таймінгу завеликі (понад 3 МБ).';

  @override
  String get settingsImportDuplicateSongId =>
      'У цій резервній копії одна пісня вказана двічі, тому нічого не імпортовано.';

  @override
  String get setlistSaveConflict =>
      'Сетлист змінено деінде. Ваші зміни збережено як окрему копію.';

  @override
  String get sectionVerse => 'Куплет';

  @override
  String get sectionChorus => 'Приспів';

  @override
  String get sectionBridge => 'Брідж';

  @override
  String get sectionIntro => 'Інтро';

  @override
  String get sectionOutro => 'Аутро';

  @override
  String get sectionPreChorus => 'Передприспів';

  @override
  String get sectionPostChorus => 'Післяприспів';

  @override
  String get sectionInstrumental => 'Інструментал';

  @override
  String get sectionInterlude => 'Інтерлюдія';

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
  String get sectionEnding => 'Закінчення';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count доступної версії',
      many: '$count доступних версій',
      few: '$count доступні версії',
      one: '$count доступна версія',
      zero: 'Немає доступних версій',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недоступної версії',
      many: '$count недоступних версій',
      few: '$count недоступні версії',
      one: '$count недоступна версія',
      zero: 'Немає недоступних версій',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Перейти до розділу';

  @override
  String get searchVersionDetails => 'Відомості про версію';

  @override
  String get searchSelectedRecording => 'Вибраний запис';

  @override
  String get searchVersionDuration => 'Тривалість версії';

  @override
  String get searchSourceOptions => 'Параметри джерела';

  @override
  String get actionUndo => 'Скасувати';

  @override
  String setlistEntryRemoved(String song) {
    return 'Пісню «$song» вилучено зі списку';
  }

  @override
  String get backupTitle => 'Резервна копія та відновлення';

  @override
  String get backupExport => 'Експортувати резервну копію';

  @override
  String get backupRestore => 'Відновити резервну копію';

  @override
  String get backupIncludePreferences => 'Додати налаштування застосунку';

  @override
  String get backupRestorePreferences => 'Відновити налаштування застосунку';

  @override
  String get backupMerge => 'Додати до цієї бібліотеки';

  @override
  String get backupMergeHint =>
      'Зберегти локальні зміни й додати пісні та списки з цієї резервної копії.';

  @override
  String get backupReplace => 'Замінити цю бібліотеку';

  @override
  String get backupReplaceHint =>
      'Замінити всі пісні та списки на цьому пристрої вмістом цієї резервної копії.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Пісні: $songs · Списки: $setlists · Конфлікти: $conflicts';
  }

  @override
  String get backupFailed => 'Не вдалося завершити операцію. Спробуйте ще раз.';

  @override
  String get backupRestored => 'Резервну копію відновлено.';

  @override
  String get backupLocalHint =>
      'Збережіть копію бібліотеки. Дані облікового запису та файли cookie згоди не додаються.';

  @override
  String get backupReplaceConfirm =>
      'Замінити поточну бібліотеку? Цю дію неможливо скасувати.';

  @override
  String get searchCheckOperations => 'Операції';

  @override
  String get searchCheckCode => 'Код результату';

  @override
  String get searchCheckQueued => 'Очікування перевірки цього джерела.';

  @override
  String get searchCheckFetch => 'Завантажити текст пісні';

  @override
  String get searchCheckValidate => 'Перевірити збіг пісні';

  @override
  String get searchCheckCorroborate => 'Перевірити збіг тексту';

  @override
  String get searchCheckCompleted => 'Завершено';

  @override
  String get searchCheckTimeout => 'Джерело не відповіло вчасно.';

  @override
  String get searchCheckBlocked => 'Джерело заблокувало запит.';

  @override
  String get searchCheckRateLimited =>
      'Джерело обмежує запити. Спробуйте пізніше.';

  @override
  String get searchCheckNetwork =>
      'Не вдалося зв’язатися з джерелом. Перевірте підключення.';

  @override
  String get searchCheckInvalid => 'Джерело повернуло нечитабельну відповідь.';

  @override
  String get searchCheckNotConfigured =>
      'Це джерело не налаштоване в цій збірці.';

  @override
  String get searchCheckNoLyrics => 'Відповідних текстів пісень не знайдено.';

  @override
  String get searchCheckFailed => 'Не вдалося завершити цю операцію.';

  @override
  String get searchCheckNoHistory =>
      'Для цього порівняння перевірки джерел не запускалися.';

  @override
  String get searchVersionCredits => 'Автори та джерела';

  @override
  String get searchVersionMediaLinks => 'Пов’язані посилання';

  @override
  String get searchCheckCancelled => 'Скасовано';

  @override
  String get searchCheckAmbiguous =>
      'Знайдено кілька збігів. Для цього джерела потрібен точніший запис.';

  @override
  String get searchCheckIdentity =>
      'Для цього джерела потрібен ідентифікатор запису або твору.';

  @override
  String get searchCheckExtraction =>
      'Джерело відповіло, але не вдалося отримати текст пісні.';

  @override
  String get searchCheckBusy => 'Джерело зайняте. Спробуйте пізніше.';

  @override
  String get searchCheckSelection =>
      'Виберіть конкретний результат із цього джерела.';

  @override
  String get playerChordsNone => 'Немає';

  @override
  String get editorCustomValue => 'Інше…';

  @override
  String get editorStandardTuning => 'Стандартний';

  @override
  String get editorExampleVerse =>
      '[C]Новий день нас [G]кличе,\n[Am]світло веде нас [F]додому.';

  @override
  String get editorExampleChorus =>
      '[F]Заспіваймо цю пісню [C]разом,\n[G]хай мелодія веде нас [C]далі.';

  @override
  String get editorExampleBridge => '[Am]Ще один рядок, на крок [F]ближче.';
}
