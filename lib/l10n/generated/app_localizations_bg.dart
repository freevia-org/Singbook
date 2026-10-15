// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Спокойно място за намиране, подреждане и пеене от вашата песенна библиотека.';

  @override
  String get aboutMadeForSinging => 'Създадено за пеене заедно';

  @override
  String appVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get navHome => 'Начало';

  @override
  String get navSongs => 'Песни';

  @override
  String get navSetlists => 'Списъци с песни';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navSettingsCompact => 'Настройки';

  @override
  String get navSearch => 'Търсене';

  @override
  String get navBack => 'Назад';

  @override
  String get navClose => 'Затваряне';

  @override
  String get navMore => 'Още действия';

  @override
  String get actionCancel => 'Отказ';

  @override
  String get actionSave => 'Запазване';

  @override
  String get actionDone => 'Готово';

  @override
  String get actionEdit => 'Редактиране';

  @override
  String get actionDelete => 'Изтриване';

  @override
  String get actionShare => 'Споделяне';

  @override
  String get actionPrint => 'Печат';

  @override
  String get actionCopy => 'Копиране';

  @override
  String get actionClear => 'Изчистване';

  @override
  String get actionRetry => 'Опитай отново';

  @override
  String get actionRefresh => 'Опресняване';

  @override
  String get actionImport => 'Импортиране';

  @override
  String get actionExport => 'Експортиране';

  @override
  String get actionExpand => 'Разгъване';

  @override
  String get actionCollapse => 'Свиване';

  @override
  String get actionAdd => 'Добавяне';

  @override
  String get actionCreate => 'Създаване';

  @override
  String get actionRemove => 'Премахване';

  @override
  String get actionDuplicate => 'Дублиране';

  @override
  String get actionMoveUp => 'Преместване нагоре';

  @override
  String get actionMoveDown => 'Преместване надолу';

  @override
  String get actionPrevious => 'Предишен';

  @override
  String get actionNext => 'Следващ';

  @override
  String get searchHint => 'Търсене на песни, изпълнители или текст';

  @override
  String get searchCatalogHint => 'Търсене на песен или изпълнител';

  @override
  String get searchChangeSong => 'Смени песента';

  @override
  String get searchSelectedPreview => 'Избран преглед';

  @override
  String get searchSubmit => 'Търсене';

  @override
  String get searchFilters => 'Опции за търсене';

  @override
  String get searchFiltersShow => 'Показване на опциите за търсене';

  @override
  String get searchFiltersHide => 'Скриване на опциите за търсене';

  @override
  String get searchFilterArtist => 'Изпълнител';

  @override
  String get searchFilterTitle => 'Заглавие на песента';

  @override
  String get searchFilterLyrics => 'Текст';

  @override
  String get searchFilterChords => 'С акорди';

  @override
  String get searchFilterTimed => 'Текст с време';

  @override
  String get searchFilterLanguage => 'Език';

  @override
  String get searchFilterAll => 'Всички';

  @override
  String get searchAutocompleteLabel => 'Предложения';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count резултата',
      one: '1 резултат',
      zero: 'Няма резултати',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Въведете песен, изпълнител или текст за търсене.';

  @override
  String get searchCatalogEmptyQuery =>
      'Въведете песен или изпълнител за търсене.';

  @override
  String get searchNoResults =>
      'Няма намерени песни. Опитайте с друго търсене.';

  @override
  String get searchLoading => 'Търсене на песни…';

  @override
  String get searchError => 'Търсенето не бе изпълнено.';

  @override
  String get searchOnlineTab => 'Онлайн';

  @override
  String get searchRecentTab => 'Последни';

  @override
  String get searchFavoritesTab => 'Любими';

  @override
  String get searchSuggested => 'Предложено съвпадение';

  @override
  String get searchAlternatives => 'Други съвпадения';

  @override
  String get searchCompare => 'Сравняване на версии';

  @override
  String get searchChooseVersion => 'Избор на тази версия';

  @override
  String get searchFullPreview => 'Пълен преглед';

  @override
  String get searchArrangementNotes => 'Бележки за аранжимента';

  @override
  String get searchOpenLyrics => 'Отвори текста';

  @override
  String get searchContributions => 'Използвани източници';

  @override
  String get searchVersionChecking => 'Проверка на тази версия…';

  @override
  String get searchVersionUnavailable =>
      'Тази версия не може да се използва. Изберете друга версия.';

  @override
  String get searchPreviewUnavailable => 'Няма наличен преглед на текста.';

  @override
  String get searchSongMatch => 'Съвпадение на песента';

  @override
  String get searchRecordingMatch => 'Съвпадение на записа';

  @override
  String get searchMatchUnverified => 'Записът не е потвърден';

  @override
  String get searchMatchExact => 'Точно съвпадение на записа';

  @override
  String get searchMatchPossible => 'Възможно съвпадение';

  @override
  String get searchAvailability => 'Наличност';

  @override
  String get searchLyricsAvailable => 'Има текст';

  @override
  String get searchLyricsUnavailable => 'Няма наличен текст';

  @override
  String get searchChordsAvailable => 'Има акорди';

  @override
  String get searchChordsUnavailable => 'Без акорди';

  @override
  String get searchTimingAvailable => 'Има времеви маркери';

  @override
  String get searchTimingUnavailable => 'Няма времеви маркери';

  @override
  String get searchDurationUnknown => 'Неизвестна продължителност';

  @override
  String searchRating(String rating) {
    return 'Оценка $rating';
  }

  @override
  String get searchSourceLabel => 'Източник';

  @override
  String get searchMetadata => 'Подробности за песента';

  @override
  String get searchAlbum => 'Албум';

  @override
  String get searchArtist => 'Изпълнител';

  @override
  String get searchYear => 'Година';

  @override
  String get searchLanguage => 'Език';

  @override
  String get searchViewVersions => 'Виж версиите';

  @override
  String get searchSaved => 'Песента е запазена в библиотеката.';

  @override
  String get searchSaveOpenLyrics => 'Запази и отвори текста';

  @override
  String get searchOtherResults => 'Други резултати';

  @override
  String get searchSaveFailed => 'Песента не бе запазена.';

  @override
  String get homeRecentSongs => 'Последни песни';

  @override
  String get homeRecentlyPlayed => 'Последно слушани';

  @override
  String get homeFavorites => 'Любими';

  @override
  String get homeHistory => 'История';

  @override
  String get homeHistoryClear => 'Изчистване на историята';

  @override
  String get homeHistoryCleared => 'Историята е изчистена.';

  @override
  String get homeHistoryEmpty => 'Отворените песни ще се показват тук.';

  @override
  String get homeFavoritesEmpty =>
      'Любимите песни и списъци ще се показват тук.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Показани са $count елемента',
      one: 'Показан е 1 елемент',
      zero: 'Показани са 0 елемента',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Последните песни и списъци ще се показват тук.';

  @override
  String get homeTimelineLabel => 'Времева линия на историята';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Цялата история';

  @override
  String get homeShowFavorites => 'Показване на любимите';

  @override
  String get homeShowRecent => 'Показване на последните';

  @override
  String get songsTitle => 'Песни';

  @override
  String get songsEmpty => 'Песните ви ще се показват тук.';

  @override
  String get songsEmptySearch => 'Няма песни, отговарящи на търсенето.';

  @override
  String get songsAdd => 'Добавяне на песен';

  @override
  String get songsSortAlphabetical => 'Азбучно подреждане';

  @override
  String get songsAlphabetNavigation => 'Индекс на песните';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пъти',
      one: 'веднъж',
      zero: 'никога',
    );
    return 'Отваряна $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Добавяне към любимите';

  @override
  String get songFavoriteRemove => 'Премахване от любимите';

  @override
  String get songMenuLabel => 'Действия за песента';

  @override
  String get songInfo => 'Подробности за песента';

  @override
  String get setlistMenuLabel => 'Действия със списъка';

  @override
  String get songAddToSetlist => 'Добавяне към списък';

  @override
  String get songCopyChordPro => 'Копиране на ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Изтриване на песента?';

  @override
  String get songDeleteConfirmMessage =>
      'Песента ще бъде премахната от библиотеката.';

  @override
  String get songDeleted => 'Песента е изтрита.';

  @override
  String get setlistsTitle => 'Списъци с песни';

  @override
  String get setlistsEmpty =>
      'Създайте списък за следващата репетиция или изява.';

  @override
  String get setlistsEmptySearch => 'Няма списъци, отговарящи на търсенето.';

  @override
  String get setlistCreate => 'Нов списък';

  @override
  String get setlistNameHint => 'Име на списъка';

  @override
  String get setlistNotes => 'Бележки';

  @override
  String get setlistEntryOverride => 'Тоналност и каподастър за тази песен';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни',
      one: '1 песен',
      zero: 'Няма песни',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Поне $duration';
  }

  @override
  String get setlistDurationUnknown => 'Неизвестна продължителност';

  @override
  String setlistActivity(String date) {
    return 'Последна промяна $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Създаден на $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Редактиран на $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Последно изпълнен на $date';
  }

  @override
  String get setlistSongsEmpty => 'Списъкът все още няма песни.';

  @override
  String get setlistAddSongs => 'Добавяне на песни';

  @override
  String get setlistReorder => 'Пренареждане на песните';

  @override
  String setlistMoveSongUp(String song) {
    return 'Преместване на $song нагоре';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Преместване на $song надолу';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Премахване на $song от списъка';
  }

  @override
  String get setlistDuplicate => 'Дублиране на списъка';

  @override
  String get setlistFavoriteAdd => 'Добавяне на списъка в любимите';

  @override
  String get setlistFavoriteRemove => 'Премахване на списъка от любимите';

  @override
  String get setlistShare => 'Споделяне като файл на списъка';

  @override
  String get setlistSharePdf => 'Споделяне като PDF';

  @override
  String get setlistPrint => 'Печат';

  @override
  String get setlistDeleteConfirmTitle => 'Изтриване на списъка?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Списъкът ще бъде премахнат. Песните в библиотеката ще останат.';

  @override
  String get setlistDeleted => 'Списъкът е изтрит.';

  @override
  String get readerTitle => 'Текст';

  @override
  String get readerNoLyrics => 'Все още няма добавен текст.';

  @override
  String get readerShowChords => 'Показване на акорди';

  @override
  String get readerHideChords => 'Скриване на акордите';

  @override
  String get readerTranspose => 'Транспониране на акордите';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count полутона',
      one: '1 полутон',
      zero: '0 полутона',
    );
    return 'Транспониране с $_temp0';
  }

  @override
  String get readerSaved => 'Запазено';

  @override
  String get readerEdit => 'Редактиране на текста и данните';

  @override
  String get playerPlay => 'Пускане на превъртането';

  @override
  String get playerPause => 'Пауза на превъртането';

  @override
  String get playerResume => 'Продължаване на превъртането';

  @override
  String get playerSeek => 'Позиция';

  @override
  String playerElapsed(String time) {
    return 'Изминало време $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Оставащо време $time';
  }

  @override
  String get playerTimingMode => 'Режим на превъртане';

  @override
  String get playerTimedLyrics => 'Текст с времеви маркери';

  @override
  String get playerStartScroll => 'Започни автоматично превъртане';

  @override
  String get playerEstimatedPace => 'Приблизително темпо';

  @override
  String get playerScrollSpeed => 'Скорост на превъртане';

  @override
  String playerEstimatedDuration(String time) {
    return 'Очаквана продължителност: $time';
  }

  @override
  String get playerLyricsOnly => 'Превъртане на текста · без звук';

  @override
  String get playerManualScroll => 'Ръчно превъртане';

  @override
  String get playerTimingStatusReady =>
      'Текстът ще следва наличните времеви маркери.';

  @override
  String get playerTimingStatusEstimated =>
      'Темпото е изчислено според дължината на песента.';

  @override
  String get playerTimingStatusManual => 'Превъртайте текста ръчно.';

  @override
  String get playerTimingStatusUnavailable =>
      'Времевото превъртане не е налично за тази песен.';

  @override
  String get playerDurationUnknown =>
      'Добавете продължителност, за да използвате приблизително превъртане.';

  @override
  String get playerProgressLabel => 'Напредък на песента';

  @override
  String get playerCurrentSection => 'Текуща част';

  @override
  String get playerPreviousSection => 'Предишна част';

  @override
  String get playerNextSection => 'Следваща част';

  @override
  String get playerPreviousSectionSong =>
      'Предишна част · задръжте за предишната песен от списъка';

  @override
  String get playerNextSectionSong =>
      'Следваща част · задръжте за следващата песен от списъка';

  @override
  String get playerPreviousSong => 'Предишна песен';

  @override
  String get playerNextSong => 'Следваща песен';

  @override
  String get editorTitle => 'Редактиране на песен';

  @override
  String get editorTitleField => 'Заглавие на песента';

  @override
  String get editorArtistField => 'Изпълнител';

  @override
  String get editorAlbumField => 'Албум';

  @override
  String get editorLyricsField => 'Текст';

  @override
  String get editorChordsField => 'Акорди';

  @override
  String get editorKeyField => 'Тоналност';

  @override
  String get editorCapoField => 'Каподастър';

  @override
  String get editorTuningField => 'Настройка';

  @override
  String get editorTempoField => 'Темпо';

  @override
  String get editorDurationField => 'Продължителност';

  @override
  String get editorTimeSignatureField => 'Такт';

  @override
  String get editorLanguageField => 'Език';

  @override
  String get editorYearField => 'Година';

  @override
  String get editorComposerField => 'Композитор';

  @override
  String get editorLyricistField => 'Автор на текста';

  @override
  String get editorCopyrightField => 'Авторски права';

  @override
  String get editorLicenseField => 'Лиценз';

  @override
  String get songInfoSources => 'Източници и права';

  @override
  String get searchMatchSameSong => 'Същата песен; записът не е потвърден';

  @override
  String get searchMatchNeedsAgreement => 'Нужно е потвърждение по текста';

  @override
  String get searchMatchDifferentLyrics =>
      'Текстът се различава от избраната песен';

  @override
  String get searchMatchCombinedSources =>
      'Подробностите са събрани от няколко източника';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Обединено от $count източника',
      one: 'Обединено от 1 източник',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count съвпадения на песни',
      one: '1 съвпадение на песен',
      zero: '0 съвпадения на песни',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count версии от източници',
      one: '1 версия от източник',
      zero: '0 версии от източници',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Най-добро налично съвпадение';

  @override
  String get providerDescriptionUnknown => 'Източник на песни';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Изтеглете ChordPro файл от източника и го импортирайте.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Изтеглете файла с безплатен профил и го импортирайте.';

  @override
  String get providerDescPublicChordSheets => 'Публични акордовни текстове.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Исторически текстове с лиценз за всяко произведение.';

  @override
  String get providerDescLicensedCatalog => 'Лицензиран каталог с текстове.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Авторски песни с лиценз Creative Commons BY.';

  @override
  String get providerDescPerSongLicense => 'Текстове с лиценз за всяка песен.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Само данни за записи и издания.';

  @override
  String get providerDescCompositionMetadataOnly => 'Само данни за композиции.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Обложки само за точно съвпадение на запис.';

  @override
  String get providerCapabilityLyrics => 'Текстове';

  @override
  String get providerCapabilityChords => 'Акорди';

  @override
  String get providerCapabilityTiming => 'Тайминг на текста';

  @override
  String get providerCapabilitySearch => 'Търсене';

  @override
  String get providerCapabilityMetadata => 'Данни за песента';

  @override
  String get editorArtworkField => 'Връзка към изображение';

  @override
  String get editorLyricsHint =>
      'Докоснете ред, за да редактирате текста или акордите.';

  @override
  String get editorSave => 'Запазване на промените';

  @override
  String get editorSaved => 'Промените са запазени.';

  @override
  String get editorSaveFailed => 'Промените не бяха запазени.';

  @override
  String get editorSaveConflict =>
      'Песента е променена другаде. Вашите промени са запазени като отделно копие.';

  @override
  String get editorUnsavedTitle => 'Отхвърляне на промените?';

  @override
  String get editorUnsavedMessage => 'Промените не са запазени.';

  @override
  String get editorFieldRequired => 'Въведете заглавие на песента.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAppearance => 'Изглед';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeSystem => 'Според устройството';

  @override
  String get settingsThemeLight => 'Светла';

  @override
  String get settingsThemeDark => 'Тъмна';

  @override
  String get settingsColorPalette => 'Цветова палитра';

  @override
  String get settingsFont => 'Шрифт';

  @override
  String get settingsTextSize => 'Размер на текста';

  @override
  String get settingsLyricsPreview => 'Преглед на текста';

  @override
  String get settingsPlayer => 'Плейър за текстове';

  @override
  String get settingsDefaultShowChords => 'Показване на акорди по подразбиране';

  @override
  String get settingsDefaultAutoscroll =>
      'Автоматично превъртане при стартиране';

  @override
  String get settingsDefaultTiming => 'Режим на превъртане по подразбиране';

  @override
  String get settingsLanguage => 'Език на приложението';

  @override
  String get settingsLanguageSystem => 'Според езика на устройството';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Източници на текстове';

  @override
  String settingsSourceEnabled(String source) {
    return 'Включване на източника $source';
  }

  @override
  String get settingsSourceRefresh => 'Опресняване на списъка с източници';

  @override
  String get settingsSourcesUpdated => 'Източниците са обновени.';

  @override
  String get settingsSourcesUpdateFailed => 'Източниците не бяха опреснени.';

  @override
  String get settingsImport => 'Импортиране на песни';

  @override
  String get settingsImportChordPro => 'Импортиране на ChordPro файл';

  @override
  String get settingsImportSetlist => 'Импортиране на списък с песни';

  @override
  String get settingsImportSuccess => 'Импортирането завърши.';

  @override
  String get settingsImportFailed => 'Файлът не бе импортиран.';

  @override
  String get settingsImportUnsupported => 'Този формат не се поддържа.';

  @override
  String get settingsShareSong => 'Споделяне като ChordPro';

  @override
  String get settingsSharePdf => 'Споделяне като PDF';

  @override
  String get settingsCopySong => 'Копиране в клипборда';

  @override
  String get settingsPrintSong => 'Само печат';

  @override
  String get settingsPrintSetlist => 'Печат на списъка с текстовете';

  @override
  String get settingsExportFailed => 'Файлът не бе подготвен.';

  @override
  String get settingsCopied => 'Копирано в клипборда.';

  @override
  String get settingsAbout => 'За приложението';

  @override
  String get settingsPrivacy => 'Поверителност';

  @override
  String get settingsLegal => 'Правна информация';

  @override
  String get settingsClearHistory => 'Изчистване на историята';

  @override
  String get settingsClearHistoryConfirm =>
      'Да се изчисти ли историята на песните и списъците?';

  @override
  String get settingsHistoryCleared => 'Историята е изчистена.';

  @override
  String get accountTitle => 'Профил и синхронизиране';

  @override
  String get accountUnavailable =>
      'За синхронизиране е нужна версия на Singbook с настроен вход през Google. Тази версия пази песните само на това устройство.';

  @override
  String get accountSyncNow => 'Синхронизирай сега';

  @override
  String get accountConnected =>
      'Свързано. Изберете „Синхронизирай сега“, за да обновите архива.';

  @override
  String get accountSignIn => 'Свързване на профил';

  @override
  String get accountSignOut => 'Изход от профила';

  @override
  String get accountChange => 'Смяна на профил';

  @override
  String get accountSignedOut => 'Няма свързан профил';

  @override
  String get accountSyncing => 'Синхронизиране на библиотеката…';

  @override
  String get accountSynced => 'Библиотеката е синхронизирана.';

  @override
  String get accountSyncFailed => 'Библиотеката не бе синхронизирана.';

  @override
  String get accessibilityFavorite => 'Любима';

  @override
  String get accessibilityNotFavorite => 'Не е любима';

  @override
  String get accessibilitySearchField => 'Търсене на песни';

  @override
  String get accessibilityClearSearch => 'Изчистване на текста за търсене';

  @override
  String accessibilitySongMenu(String song) {
    return 'Действия за $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Действия за $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Разгъване на песните в $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Свиване на песните в $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Напредък на възпроизвеждането: $percent%';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Времева линия на историята, $date';
  }

  @override
  String get loading => 'Зареждане…';

  @override
  String get loadingSongs => 'Зареждане на песните…';

  @override
  String get loadingSetlists => 'Зареждане на списъците…';

  @override
  String get errorGeneric => 'Възникна грешка.';

  @override
  String get errorOffline => 'Изглежда, че няма връзка с интернет.';

  @override
  String get errorPermission => 'За да продължите, е нужно разрешение.';

  @override
  String get emptyFiltered => 'Няма елементи, отговарящи на филтрите.';

  @override
  String get unknownValue => 'Неизвестно';

  @override
  String get durationUnknown => 'Неизвестна продължителност';

  @override
  String get metadataNotSet => 'Не е зададено';

  @override
  String get dateToday => 'Днес';

  @override
  String get dateYesterday => 'Вчера';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count песни',
      one: '1 песен',
      zero: 'Няма песни',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Тъмносиня';

  @override
  String get settingsPaletteSage => 'Градински чай';

  @override
  String get settingsPaletteOcean => 'Океан';

  @override
  String get settingsPaletteClay => 'Глина';

  @override
  String get settingsPalettePlum => 'Слива';

  @override
  String get settingsFontSystem => 'Системен';

  @override
  String get settingsFontSerif => 'Серифен';

  @override
  String get settingsFontMonospace => 'Моноширинен';

  @override
  String get settingsLyricsPreviewExample =>
      'Когато настъпи утрото, отново ще запеем.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Проверени са $checked от общо $total източника за текстове.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Не са намерени използваеми текстове.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Избраната песен е проверена в активните източници, но няма използваема версия на текста.';

  @override
  String get searchDiscoveryError =>
      'Източниците за текстове не можаха да бъдат проверени.';

  @override
  String get searchDiscoveryRetry => 'Повторно търсене на текстове';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недостъпни източника',
      one: '1 недостъпен източник',
      zero: 'Няма недостъпни източници',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Проверете връзката си и опитайте отново.';

  @override
  String get searchProviderChecks => 'Проверки на източниците';

  @override
  String get searchProviderPending => 'Проверява се';

  @override
  String get searchProviderFound => 'Намерено съвпадение';

  @override
  String get searchProviderRejected => 'Няма съвпадение';

  @override
  String get searchProviderFailed => 'Проверката не бе успешна';

  @override
  String get searchProviderUnavailable => 'Няма използваем текст';

  @override
  String get searchCatalogFilterHint =>
      'Изберете песен, за да филтрирате версиите на текста по акорди, тайминг или език.';

  @override
  String get startupErrorTitle => 'Библиотеката не можа да бъде отворена.';

  @override
  String setlistCopyName(String name) {
    return '$name (копие)';
  }

  @override
  String get setlistSongMissing => 'Липсваща песен';

  @override
  String get settingsImportTooLarge => 'Файлът е твърде голям за импортиране.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Към буква $letter';
  }

  @override
  String get actionDiscard => 'Отхвърляне';

  @override
  String get editorKeepEditing => 'Продължаване на редакцията';

  @override
  String get settingsDefaultShowChordsHint =>
      'Акордите се показват над текста, когато песента има такива.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Текстът се превърта заедно с песента. Не се използва при ръчно превъртане.';

  @override
  String get accountUnavailableTitle => 'Синхронизирането не е настроено';

  @override
  String get accountSignedOutBenefits =>
      'Влезте с Google, за да архивирате песните и списъците си в Google Drive и да държите всичките си устройства синхронизирани. Песните остават на това устройство и без вход.';

  @override
  String get accountSignInWithGoogle => 'Вход с Google';

  @override
  String get accountWorking => 'Изчакайте…';

  @override
  String get accountNeverSynced => 'Още не е синхронизирано';

  @override
  String get accountSyncedJustNow => 'Синхронизирано току-що';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Синхронизирано преди $count минути',
      one: 'Синхронизирано преди 1 минута',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Синхронизирано преди $count часа',
      one: 'Синхронизирано преди 1 час',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Синхронизирано преди $count дни',
      one: 'Синхронизирано преди 1 ден',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count конфликтни промени са запазени като копия',
      one: '1 конфликтна промяна е запазена като копие',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Една и съща песен или един и същ списък е редактиран на две места. Нищо не е загубено: другата версия е запазена като отделно копие.';

  @override
  String get accountReviewConflicts => 'Преглед на копията';

  @override
  String get songsConflictFilterActive =>
      'Показани са само копията при конфликт';

  @override
  String get songsConflictFilterClear => 'Покажи всички песни';

  @override
  String get songsConflictBadge => 'Копие при конфликт';

  @override
  String get songsConflictEmpty => 'Няма копия при конфликт.';

  @override
  String get accountAutoSync => 'Синхронизирай автоматично';

  @override
  String get accountAutoSyncHint =>
      'Поддържай библиотеката актуална при отваряне на приложението и след промени.';

  @override
  String get accountSignOutTitle => 'Изход от профила?';

  @override
  String get accountSignOutBody =>
      'Песните и списъците ви остават на това устройство. Няма да се архивират и синхронизират, докато не влезете отново.';

  @override
  String get accountUseDifferent => 'Използване на друг профил';

  @override
  String get accountSignInAgain => 'Влезте отново';

  @override
  String get accountChooseAction => 'Изберете как да продължите';

  @override
  String get accountChangedTitle => 'Друг профил в Google';

  @override
  String get accountChangedBody =>
      'Това устройство последно е синхронизирано с друг профил в Google. Изберете какво да стане с песните и списъците на устройството.';

  @override
  String get accountChangedMerge => 'Обединяване с новия профил';

  @override
  String get accountChangedMergeHint =>
      'Запазва всичко на устройството и го добавя към новия профил.';

  @override
  String get accountChangedReplace => 'Замяна с библиотеката на новия профил';

  @override
  String get accountChangedReplaceHint =>
      'Песните на устройството, които ги няма в новия профил, се премахват.';

  @override
  String get accountChangedSignOut => 'Отказ и изход';

  @override
  String get accountStatusSignedOut => 'Профил и синхронизиране: няма вход';

  @override
  String get accountStatusSignedIn => 'Профил и синхронизиране: влезли сте';

  @override
  String get accountStatusSyncing => 'Профил и синхронизиране: синхронизира се';

  @override
  String get accountStatusSynced =>
      'Профил и синхронизиране: библиотеката е актуална';

  @override
  String get accountStatusError =>
      'Профил и синхронизиране: проблем, докоснете за преглед';

  @override
  String get accountNoticeConflicts =>
      'Някои песни са редактирани на две места. Запазени са копия.';

  @override
  String get accountNoticeSignedIn => 'Влязохте.';

  @override
  String get accountNoticeSignedOut =>
      'Излязохте. Песните остават на това устройство.';

  @override
  String get syncErrorNotConfigured =>
      'Синхронизирането не е настроено в тази версия.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Използвайте версия на Singbook с настроен вход през Google.';

  @override
  String get syncErrorNotSignedIn => 'Не сте влезли в профил.';

  @override
  String get syncErrorNotSignedInHint =>
      'Влезте, за да синхронизирате библиотеката.';

  @override
  String get syncErrorAuthorizationRequired => 'Google изисква нов вход.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Влезте отново, за да продължите синхронизирането. Песните са в безопасност на устройството.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook няма разрешение да ползва Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Влезте отново и разрешете достъпа до Drive, когато бъдете попитани.';

  @override
  String get syncErrorRateLimited => 'Google временно ограничава заявките.';

  @override
  String get syncErrorRateLimitedHint =>
      'Изчакайте няколко минути и опитайте отново.';

  @override
  String get syncErrorStorageFull => 'Google Drive е пълен.';

  @override
  String get syncErrorStorageFullHint =>
      'Освободете място в Drive и опитайте отново.';

  @override
  String get syncErrorNetwork => 'Връзката с Google не се получи.';

  @override
  String get syncErrorNetworkHint =>
      'Проверете интернет връзката и опитайте отново.';

  @override
  String get syncErrorAccountChanged => 'Използван е друг профил в Google.';

  @override
  String get syncErrorAccountChangedHint =>
      'Изберете дали да обедините библиотеката на устройството с него, или да я замените.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Синхронизираната библиотека е по-голяма, отколкото Singbook може да обработи.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Премахнете част от песните или списъците от синхронизираната библиотека и опитайте отново.';

  @override
  String get syncErrorSignInFailed => 'Входът не завърши.';

  @override
  String get syncErrorSignInFailedHint => 'Опитайте да влезете отново.';

  @override
  String get syncErrorGeneric => 'Библиотеката не бе синхронизирана.';

  @override
  String get syncErrorGenericHint =>
      'Опитайте отново след малко. Песните са в безопасност на устройството.';

  @override
  String get editorDurationInvalid =>
      'Въведете секунди или минути и секунди, например 3:45.';

  @override
  String get editorNumberInvalid => 'Въведете число.';

  @override
  String get accountReplaceConfirmTitle => 'Да се изтрият ли локалните песни?';

  @override
  String get accountReplaceConfirmBody =>
      'Песните и списъците на това устройство, които не са в новия акаунт, ще бъдат изтрити завинаги. Действието не може да бъде отменено.';

  @override
  String get accountReplaceConfirmAction => 'Изтрий и замени';

  @override
  String get accountSuspiciousTitle => 'Липсват елементи в Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count елемента, които това устройство е синхронизирало преди, липсват в Google Drive.',
      one:
          '$count елемент, който това устройство е синхронизирало преди, липсва в Google Drive.',
    );
    return '$_temp0 Това може да се случи, ако данните на приложението са изчистени от настройките на Google. Нищо още не е изтрито.';
  }

  @override
  String get accountSuspiciousDelete => 'Изтрий ги и тук';

  @override
  String get accountSuspiciousKeep => 'Запази песните ми и ги качи отново';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Да се изтрият ли $count елемента от това устройство?',
      one: 'Да се изтрие ли $count елемент от това устройство?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Тези песни и списъци ще бъдат изтрити завинаги от това устройство. Действието не може да бъде отменено.';

  @override
  String get accountSuspiciousDeleteConfirmAction =>
      'Изтрий от това устройство';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'В Google Drive липсват елементи.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Нищо не е изтрито. Изберете дали да ги изтриете и тук, или да ги качите отново.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive се промени по време на синхронизирането.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Нищо не е загубено. Синхронизирайте отново, за да получите последните промени.';

  @override
  String get syncErrorInvalidLocalData =>
      'Някои данни на това устройство не можаха да се синхронизират.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Песен или списък не можа да бъде прочетен. Импортирайте или създайте го отново и синхронизирайте пак.';

  @override
  String get syncErrorNoAccountChange =>
      'Няма промяна на акаунта за разрешаване.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Синхронизирайте отново, за да продължите.';

  @override
  String get accountSyncWarningTitle =>
      'Синхронизирано, но някои файлове са пропуснати';

  @override
  String get accountSyncWarningBody =>
      'Някои файлове не можаха да се използват и са оставени непроменени. Всичко останало е актуално.';

  @override
  String get accountSyncWarningTooLarge =>
      'Един файл е твърде голям за синхронизиране и е пропуснат. Всичко останало е актуално.';

  @override
  String get accountSyncWarningInvalid =>
      'Един файл не можа да бъде прочетен и е пропуснат. Всичко останало е актуално.';

  @override
  String get accountNoticeSyncSkipped =>
      'Синхронизирано. Някои файлове са пропуснати.';

  @override
  String get settingsExportPdfTooLarge =>
      'Този PDF би бил твърде голям. Опитайте с по-малко песни или го споделете като текст.';

  @override
  String get settingsTimingTooLarge =>
      'Данните за тайминга са твърде големи (над 3 МБ).';

  @override
  String get settingsImportDuplicateSongId =>
      'Този архив съдържа една и съща песен два пъти, затова нищо не е импортирано.';

  @override
  String get setlistSaveConflict =>
      'Списъкът е променен другаде. Вашите промени са запазени като отделно копие.';

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
  String get sectionPreChorus => 'Предприпев';

  @override
  String get sectionPostChorus => 'Следприпев';

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
  String get sectionTag => 'Таг';

  @override
  String get sectionEnding => 'Край';
}
