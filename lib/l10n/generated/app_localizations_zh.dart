// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription => '歌词、和弦与演出歌单汇集一处，为排练、舞台和每一次演奏做好准备。';

  @override
  String get aboutMadeForSinging => '每首歌，都已准备就绪。';

  @override
  String get aboutDetails =>
      '搜索可用来源，比较歌词、和弦、时间信息和录音详情，再保存想演奏的版本。内容是否可用取决于歌曲和服务。';

  @override
  String get aboutFindTitle => '找到合适的版本';

  @override
  String get aboutKeepTitle => '建立自己的曲库';

  @override
  String get aboutKeepDetails =>
      '编辑和移调歌曲，将其保存在本地曲库中以便离线使用，并分享便携的 ChordPro 文件。可选的 Google Drive 同步会使用你 Google 帐号中的应用专用私密文件夹。你也可以点按“立即同步”来更新设备。';

  @override
  String get aboutPlayTitle => '带着歌单登上舞台';

  @override
  String get aboutPlayDetails =>
      '将歌曲编入演出歌单，为每首歌选择调性，并分享 OpenSong 歌单。调整阅读器文字大小、自动滚动歌词，也可打印歌曲 PDF。Singbook 不会串流或播放音频。';

  @override
  String get aboutPrivacyTitle => '免费使用，优先本地存储';

  @override
  String get aboutPrivacyDetails =>
      'Singbook 免费使用，不含广告、分析或应用内购买。已保存的曲库保留在你的设备上；可选同步使用你自己的 Google Drive。在线结果直接来自独立的第三方服务，可能无法使用或受版权保护。Singbook 不托管这些内容。';

  @override
  String get aboutWebsite => 'Singbook 网站';

  @override
  String get aboutSourceCode => 'GitHub 上的源代码';

  @override
  String get aboutPublisher => 'Freevia 出品';

  @override
  String aboutLanguages(int count) {
    return '应用语言：$count';
  }

  @override
  String get aboutSupport => '支持与反馈';

  @override
  String get menuTypeNewSong => '输入新歌曲';

  @override
  String appVersion(String version) {
    return '版本 $version';
  }

  @override
  String get navHome => '首页';

  @override
  String get navSongs => '歌曲';

  @override
  String get navSetlists => '歌单';

  @override
  String get navSettings => '设置';

  @override
  String get navSettingsCompact => '设置';

  @override
  String get navSearch => '搜索';

  @override
  String get navBack => '返回';

  @override
  String get appExitBackAgain => '再次按返回键退出';

  @override
  String get navClose => '关闭';

  @override
  String get navMore => '更多操作';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSave => '保存';

  @override
  String get actionDone => '完成';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionDelete => '删除';

  @override
  String get actionShare => '分享';

  @override
  String get actionPrint => '打印';

  @override
  String get actionCopy => '复制';

  @override
  String get actionClear => '清除';

  @override
  String get actionRetry => '重试';

  @override
  String get actionRefresh => '刷新';

  @override
  String get actionImport => '导入';

  @override
  String get actionExport => '导出';

  @override
  String get actionExpand => '展开';

  @override
  String get actionCollapse => '收起';

  @override
  String get actionAdd => '添加';

  @override
  String get actionCreate => '创建';

  @override
  String get actionRemove => '移除';

  @override
  String get actionDuplicate => '创建副本';

  @override
  String get actionMoveUp => '上移';

  @override
  String get actionMoveDown => '下移';

  @override
  String get actionPrevious => '上一个';

  @override
  String get actionNext => '下一个';

  @override
  String get searchHint => '搜索歌曲、艺人或歌词';

  @override
  String get searchCatalogHint => '搜索歌曲或艺人';

  @override
  String get searchChangeSong => '更换歌曲';

  @override
  String get searchSelectedPreview => '已选预览';

  @override
  String get searchSubmit => '搜索';

  @override
  String get searchFilters => '搜索选项';

  @override
  String get searchFiltersShow => '显示搜索选项';

  @override
  String get searchFiltersHide => '隐藏搜索选项';

  @override
  String get searchFilterArtist => '艺人';

  @override
  String get searchFilterTitle => '歌曲名称';

  @override
  String get searchFilterLyrics => '歌词';

  @override
  String get searchFilterChords => '包含和弦';

  @override
  String get searchFilterTimed => '带时间同步的歌词';

  @override
  String get searchFilterLanguage => '语言';

  @override
  String get searchFilterAll => '不限';

  @override
  String get searchAutocompleteLabel => '建议';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个结果',
      one: '1 个结果',
      zero: '没有结果',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery => '输入歌曲、艺人或歌词进行搜索。';

  @override
  String get searchCatalogEmptyQuery => '输入歌曲或艺人进行搜索。';

  @override
  String get searchNoResults => '未找到歌曲。请尝试其他搜索。';

  @override
  String get searchLoading => '正在搜索歌曲…';

  @override
  String get searchError => '无法完成搜索。';

  @override
  String get searchOnlineTab => '在线';

  @override
  String get searchRecentTab => '最近';

  @override
  String get searchFavoritesTab => '收藏';

  @override
  String get searchSuggested => '建议匹配';

  @override
  String get searchAlternatives => '其他匹配';

  @override
  String get searchCompare => '比较版本';

  @override
  String get searchChooseVersion => '选择此版本';

  @override
  String get searchFullPreview => '完整预览';

  @override
  String get searchArrangementNotes => '编曲备注';

  @override
  String get searchOpenLyrics => '打开歌词';

  @override
  String get searchContributions => '使用的来源';

  @override
  String get searchVersionChecking => '正在检查此版本…';

  @override
  String get searchVersionUnavailable => '此版本无法使用。请选择其他版本。';

  @override
  String get searchPreviewUnavailable => '没有可用的歌词预览。';

  @override
  String get searchSongMatch => '歌曲匹配';

  @override
  String get searchRecordingMatch => '录音匹配';

  @override
  String get searchMatchUnverified => '录音未经验证';

  @override
  String get searchMatchExact => '录音完全匹配';

  @override
  String get searchMatchPossible => '可能匹配';

  @override
  String get searchAvailability => '可用性';

  @override
  String get searchLyricsAvailable => '歌词可用';

  @override
  String get searchLyricsUnavailable => '歌词不可用';

  @override
  String get searchChordsAvailable => '和弦可用';

  @override
  String get searchChordsUnavailable => '没有和弦';

  @override
  String get searchTimingAvailable => '时间信息可用';

  @override
  String get searchTimingUnavailable => '没有时间信息';

  @override
  String get searchDurationUnknown => '时长未知';

  @override
  String searchRating(String rating) {
    return '评分 $rating';
  }

  @override
  String get searchSourceLabel => '来源';

  @override
  String get searchPreferredSourceLabel => '首选来源';

  @override
  String get searchPreferredSourceHint => '结果也可能来自其他已启用的搜索来源。';

  @override
  String get searchMetadata => '歌曲详情';

  @override
  String get searchAlbum => '专辑';

  @override
  String get searchArtist => '艺人';

  @override
  String get searchYear => '年份';

  @override
  String get searchLanguage => '语言';

  @override
  String get searchViewVersions => '查看版本';

  @override
  String get searchSaved => '歌曲已保存到你的曲库。';

  @override
  String get searchSaveOpenLyrics => '保存并打开歌词';

  @override
  String get searchOtherResults => '其他结果';

  @override
  String get searchSaveFailed => '无法保存此歌曲。';

  @override
  String get homeRecentSongs => '最近的歌曲';

  @override
  String get homeRecentlyPlayed => '最近播放';

  @override
  String get homeFavorites => '收藏';

  @override
  String get homeHistory => '历史记录';

  @override
  String get homeHistoryClear => '清除历史记录';

  @override
  String get homeHistoryCleared => '历史记录已清除。';

  @override
  String get homeHistoryEmpty => '你打开的歌曲会显示在这里。';

  @override
  String get homeFavoritesEmpty => '你收藏的歌曲和歌单会显示在这里。';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '显示 $count 项',
      one: '显示 1 项',
      zero: '显示 0 项',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty => '你最近的歌曲和歌单会显示在这里。';

  @override
  String get homeTimelineLabel => '历史时间线';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => '全部历史记录';

  @override
  String get homeShowFavorites => '显示收藏';

  @override
  String get homeShowRecent => '显示最近项目';

  @override
  String get songsTitle => '歌曲';

  @override
  String get songsEmpty => '你的歌曲会显示在这里。';

  @override
  String get songsEmptySearch => '没有歌曲符合你的搜索条件。';

  @override
  String get songsAdd => '添加歌曲';

  @override
  String get songsSortAlphabetical => '按字母顺序排序';

  @override
  String get songsAlphabetNavigation => '歌曲索引';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '打开过 $count 次',
      one: '打开过一次',
      zero: '从未打开',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => '添加到收藏';

  @override
  String get songFavoriteRemove => '从收藏中移除';

  @override
  String get songMenuLabel => '歌曲操作';

  @override
  String get songInfo => '歌曲详情';

  @override
  String get setlistMenuLabel => '歌单操作';

  @override
  String get songAddToSetlist => '添加到歌单';

  @override
  String get songCopyChordPro => '复制 ChordPro';

  @override
  String get songDeleteConfirmTitle => '删除歌曲？';

  @override
  String get songDeleteConfirmMessage => '此歌曲将从你的曲库中移除。';

  @override
  String get songDeleted => '歌曲已删除。';

  @override
  String get setlistsTitle => '歌单';

  @override
  String get setlistsEmpty => '为下次排练或演出创建一个歌单。';

  @override
  String get setlistsEmptySearch => '没有歌单符合你的搜索条件。';

  @override
  String get setlistCreate => '新建歌单';

  @override
  String get setlistNameHint => '歌单名称';

  @override
  String get setlistNotes => '备注';

  @override
  String get setlistEntryOverride => '此歌曲专属的调性和变调夹';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 首歌曲',
      one: '1 首歌曲',
      zero: '没有歌曲',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return '至少 $duration';
  }

  @override
  String get setlistDurationUnknown => '时长未知';

  @override
  String setlistActivity(String date) {
    return '最近活动：$date';
  }

  @override
  String setlistActivityCreated(String date) {
    return '创建于 $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return '编辑于 $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return '最近播放于 $date';
  }

  @override
  String get setlistSongsEmpty => '此歌单中还没有歌曲。';

  @override
  String get setlistAddSongs => '添加歌曲';

  @override
  String get setlistReorder => '重新排列歌曲';

  @override
  String setlistMoveSongUp(String song) {
    return '将 $song 上移';
  }

  @override
  String setlistMoveSongDown(String song) {
    return '将 $song 下移';
  }

  @override
  String setlistRemoveSong(String song) {
    return '从歌单中移除 $song';
  }

  @override
  String get setlistDuplicate => '复制歌单';

  @override
  String get setlistFavoriteAdd => '将歌单添加到收藏';

  @override
  String get setlistFavoriteRemove => '从收藏中移除歌单';

  @override
  String get setlistShare => '分享为 OpenSong';

  @override
  String get setlistSharePdf => '分享为 PDF';

  @override
  String get setlistPrint => '打印';

  @override
  String get setlistDeleteConfirmTitle => '删除歌单？';

  @override
  String get setlistDeleteConfirmMessage => '歌单将被移除。曲库中的歌曲会保留。';

  @override
  String get setlistDeleted => '歌单已删除。';

  @override
  String get readerTitle => '歌词';

  @override
  String get readerNoLyrics => '尚未添加歌词。';

  @override
  String get readerShowChords => '显示和弦';

  @override
  String get readerHideChords => '隐藏和弦';

  @override
  String get readerTranspose => '移调和弦';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个半音',
      one: '1 个半音',
      zero: '0 个半音',
    );
    return '移调 $_temp0';
  }

  @override
  String get readerSaved => '已保存';

  @override
  String get readerEdit => '编辑歌词和详情';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暂停';

  @override
  String get playerResume => '继续滚动歌词';

  @override
  String get playerSeek => '播放位置';

  @override
  String playerElapsed(String time) {
    return '已用时间 $time';
  }

  @override
  String playerRemaining(String time) {
    return '剩余时间 $time';
  }

  @override
  String get playerTimingMode => '滚动模式';

  @override
  String get playerTimedLyrics => '带时间同步的歌词';

  @override
  String get playerStartScroll => '开始自动滚动';

  @override
  String get playerEstimatedPace => '估算速度';

  @override
  String get playerScrollSpeed => '滚动速度';

  @override
  String playerEstimatedDuration(String time) {
    return '预计时长：$time';
  }

  @override
  String get playerLyricsOnly => '歌词滚动 · 无音频';

  @override
  String get playerManualScroll => '手动滚动';

  @override
  String get playerTimingStatusReady => '歌词将按照可用的时间信息滚动。';

  @override
  String get playerTimingStatusEstimated => '滚动速度根据歌曲时长估算。';

  @override
  String get playerTimingStatusManual => '手动滚动歌词。';

  @override
  String get playerTimingStatusUnavailable => '此歌曲不支持时间同步滚动。';

  @override
  String get playerDurationUnknown => '添加歌曲时长后即可使用估算滚动。';

  @override
  String get playerProgressLabel => '歌曲进度';

  @override
  String get playerCurrentSection => '当前段落';

  @override
  String get playerPreviousSection => '上一段';

  @override
  String get playerNextSection => '下一段';

  @override
  String get playerPreviousSectionSong => '上一段 · 按住可切换到歌单中的上一首';

  @override
  String get playerNextSectionSong => '下一段 · 按住可切换到歌单中的下一首';

  @override
  String get playerPreviousSong => '上一首歌曲';

  @override
  String get playerNextSong => '下一首歌曲';

  @override
  String get editorTitle => '编辑歌曲';

  @override
  String get editorTitleField => '歌曲名称';

  @override
  String get editorArtistField => '艺人';

  @override
  String get editorAlbumField => '专辑';

  @override
  String get editorLyricsField => '歌词';

  @override
  String get editorChordsField => '和弦';

  @override
  String get editorKeyField => '调性';

  @override
  String get editorCapoField => '变调夹';

  @override
  String get editorTuningField => '调弦';

  @override
  String get editorTempoField => '速度';

  @override
  String get editorDurationField => '时长';

  @override
  String get editorTimeSignatureField => '拍号';

  @override
  String get editorLanguageField => '语言';

  @override
  String get editorYearField => '年份';

  @override
  String get editorComposerField => '作曲';

  @override
  String get editorLyricistField => '作词';

  @override
  String get editorCopyrightField => '版权';

  @override
  String get editorLicenseField => '许可';

  @override
  String get songInfoSources => '来源和署名';

  @override
  String get searchMatchSameSong => '同一首歌曲；录音尚未确认';

  @override
  String get searchMatchNeedsAgreement => '需要确认谱面中的歌词';

  @override
  String get searchMatchDifferentLyrics => '歌词与所选歌曲不同';

  @override
  String get searchMatchCombinedSources => '详情由多个来源合并而成';

  @override
  String get searchCombinedLabel => '合并结果';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 首歌曲匹配',
      one: '1 首歌曲匹配',
      zero: '0 首歌曲匹配',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个来源版本',
      one: '1 个来源版本',
      zero: '0 个来源版本',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => '最佳可用匹配';

  @override
  String get providerDescriptionUnknown => '歌曲来源';

  @override
  String get providerDescDownloadChordProThenImport =>
      '从来源下载 ChordPro 文件，然后导入。';

  @override
  String get providerDescFreeAccountDownloadThenImport => '使用免费账户下载文件，然后导入。';

  @override
  String get providerDescPublicChordSheets => '公开的和弦谱。';

  @override
  String get providerDescHistoricalTextPerWorkLicense => '历史歌词按作品获得许可。';

  @override
  String get providerDescLicensedCatalog => '获得许可的歌词目录。';

  @override
  String get providerDescOriginalSongsCcBy => '采用 Creative Commons BY 许可的原创歌曲。';

  @override
  String get providerDescPerSongLicense => '歌词按歌曲获得许可。';

  @override
  String get providerDescRecordingMetadataOnly => '仅提供录音和发行信息。';

  @override
  String get providerDescCompositionMetadataOnly => '仅提供作品信息。';

  @override
  String get providerDescExactFileArtworkOnly => '仅为录音完全匹配的歌曲提供封面图。';

  @override
  String get providerCapabilityLyrics => '歌词';

  @override
  String get providerCapabilityChords => '和弦';

  @override
  String get providerCapabilityTiming => '带时间同步的歌词';

  @override
  String get providerCapabilitySearch => '搜索';

  @override
  String get providerCapabilityMetadata => '歌曲详情';

  @override
  String get editorArtworkField => '封面链接';

  @override
  String get editorLyricsHint => '和弦写在 [C] 方括号中；段落标记单独占一行。';

  @override
  String get editorSave => '保存更改';

  @override
  String get editorSaved => '更改已保存。';

  @override
  String get editorSaveFailed => '无法保存更改。';

  @override
  String get editorSaveConflict => '歌曲已在其他位置更改。你的更改已另存为一个副本。';

  @override
  String get editorUnsavedTitle => '放弃更改？';

  @override
  String get editorUnsavedMessage => '你的更改尚未保存。';

  @override
  String get editorFieldRequired => '请输入歌曲名称。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '使用设备设置';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsColorPalette => '调色板';

  @override
  String get settingsFont => '字体';

  @override
  String get settingsTextSize => '文字大小';

  @override
  String get settingsLyricsPreview => '歌词预览';

  @override
  String get settingsPlayer => '歌词播放器';

  @override
  String get settingsLyricHighlight => '高亮当前歌词行';

  @override
  String get settingsHighlightBackgroundUnderline => '背景 + 下划线';

  @override
  String get settingsHighlightBackground => '背景';

  @override
  String get settingsHighlightUnderline => '下划线';

  @override
  String get settingsHighlightContrast => '对比色文字';

  @override
  String get settingsHighlightNone => '无';

  @override
  String get settingsDefaultShowChords => '默认显示和弦';

  @override
  String get settingsDefaultAutoscroll => '自动滚动歌词';

  @override
  String get settingsDefaultTiming => '默认滚动模式';

  @override
  String get settingsLanguage => '应用语言';

  @override
  String get settingsLanguageSystem => '使用设备语言';

  @override
  String get settingsLanguageEnglish => '英语';

  @override
  String get settingsLanguageBulgarian => '保加利亚语';

  @override
  String get settingsLanguageUkrainian => '乌克兰语';

  @override
  String get settingsSources => '歌词来源';

  @override
  String settingsSourceEnabled(String source) {
    return '启用来源 $source';
  }

  @override
  String get settingsSourceRefresh => '刷新来源列表';

  @override
  String get settingsSourcesUpdated => '来源已更新。';

  @override
  String get settingsSourcesUpdateFailed => '无法刷新来源。';

  @override
  String get settingsImport => '导入歌曲';

  @override
  String get settingsImportChordPro => '导入 ChordPro 文件';

  @override
  String get settingsImportSetlist => '导入歌单文件';

  @override
  String get settingsImportSuccess => '导入完成。';

  @override
  String get settingsImportFailed => '无法导入此文件。';

  @override
  String get settingsImportUnsupported => '不支持此文件类型。';

  @override
  String get settingsShareSong => '分享为 ChordPro';

  @override
  String get settingsSharePdf => '分享为 PDF';

  @override
  String get settingsCopySong => '复制到剪贴板';

  @override
  String get settingsPrintSong => '仅打印歌曲';

  @override
  String get settingsPrintSetlist => '打印包含歌词的歌单';

  @override
  String get settingsExportFailed => '无法准备文件。';

  @override
  String get settingsCopied => '已复制到剪贴板。';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsPrivacy => '隐私';

  @override
  String get settingsLegal => '法律信息';

  @override
  String get settingsClearHistory => '清除历史记录';

  @override
  String get settingsClearHistoryConfirm => '清除歌曲和歌单的最近活动记录。保留已保存的歌曲、收藏、歌单和设置。';

  @override
  String get settingsHistoryCleared => '历史记录已清除。';

  @override
  String get accountTitle => '账户与同步';

  @override
  String get accountICloudBenefits =>
      '使用 Apple 账户通过 iCloud 私密同步歌曲和歌单。连接后，所有更改都会自动同步。';

  @override
  String get accountICloudUnavailable =>
      'iCloud 不可用。请在系统设置中检查 Apple 账户和 iCloud 访问权限，然后重试。';

  @override
  String get accountConnectICloud => '连接 iCloud';

  @override
  String get accountDisconnectICloud => '断开 iCloud';

  @override
  String get accountUnavailable =>
      '同步需要配置了 Google 登录功能的 Singbook 版本。此版本只会将歌曲保存在此设备上。';

  @override
  String get accountSyncNow => '立即同步';

  @override
  String get accountConnected => '已连接。选择“立即同步”以更新备份。';

  @override
  String get accountSignIn => '连接账户';

  @override
  String get accountSignOut => '退出登录';

  @override
  String get accountChange => '更换账户';

  @override
  String get accountSignedOut => '未连接';

  @override
  String get accountSyncing => '正在同步曲库…';

  @override
  String get accountSynced => '曲库已同步。';

  @override
  String get accountSyncFailed => '无法同步曲库。';

  @override
  String get accessibilityFavorite => '收藏';

  @override
  String get accessibilityNotFavorite => '未收藏';

  @override
  String get accessibilitySearchField => '搜索歌曲';

  @override
  String get accessibilityClearSearch => '清除搜索文本';

  @override
  String accessibilitySongMenu(String song) {
    return '$song的操作';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return '$setlist的操作';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return '展开$setlist中的歌曲';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return '收起$setlist中的歌曲';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return '播放进度，$percent%';
  }

  @override
  String accessibilityTimeline(String date) {
    return '历史时间线，$date';
  }

  @override
  String get loading => '正在加载…';

  @override
  String get loadingSongs => '正在加载歌曲…';

  @override
  String get loadingSetlists => '正在加载歌单…';

  @override
  String get errorGeneric => '发生了错误。';

  @override
  String get errorOffline => '你似乎处于离线状态。';

  @override
  String get errorPermission => '需要获得权限才能继续。';

  @override
  String get emptyFiltered => '没有项目符合这些筛选条件。';

  @override
  String get unknownValue => '未知';

  @override
  String get durationUnknown => '时长未知';

  @override
  String get metadataNotSet => '未设置';

  @override
  String get dateToday => '今天';

  @override
  String get dateYesterday => '昨天';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 首歌曲',
      one: '1 首歌曲',
      zero: '没有歌曲',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => '海军蓝';

  @override
  String get settingsPaletteSage => '鼠尾草绿';

  @override
  String get settingsPaletteOcean => '海洋';

  @override
  String get settingsPaletteClay => '陶土色';

  @override
  String get settingsPalettePlum => '梅子色';

  @override
  String get settingsFontSystem => '系统';

  @override
  String get settingsFontSerif => '衬线体';

  @override
  String get settingsFontMonospace => '等宽字体';

  @override
  String get settingsLyricsPreviewExample => '清晨来临时，我们将再次歌唱。';

  @override
  String get settingsPreviewSongTitle => '晨间歌曲';

  @override
  String get settingsPreviewArtist => '示例编曲';

  @override
  String get settingsPreviewCurrentLine => '清晨来临时';

  @override
  String get settingsPreviewNextLine => '我们将再次歌唱。';

  @override
  String get settingsPlayerSections => '章节标题';

  @override
  String get settingsPlayerControls => '播放面板';

  @override
  String get settingsPlayerAutoscroll => '自动滚动';

  @override
  String get settingsSystemShort => '设备';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return '正在检查歌词来源：已完成 $checked/$total。';
  }

  @override
  String get searchDiscoveryNoLyrics => '未找到可用的歌词。';

  @override
  String get searchDiscoveryNoLyricsDetails => '已在启用的来源中检查所选歌曲，但没有来源提供可用的歌词版本。';

  @override
  String get searchDiscoveryError => '无法检查歌词来源。';

  @override
  String get searchDiscoveryRetry => '重新搜索歌词';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个来源不可用',
      one: '1 个来源不可用',
      zero: '0 个来源不可用',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => '检查网络连接后重试。';

  @override
  String get searchProviderChecks => '来源检查';

  @override
  String get searchProviderPending => '正在检查';

  @override
  String get searchProviderFound => '找到匹配项';

  @override
  String get searchProviderRejected => '不匹配';

  @override
  String get searchProviderFailed => '检查失败';

  @override
  String get searchProviderUnavailable => '没有可用的歌词';

  @override
  String get searchCatalogFilterHint => '选择一首歌曲，按和弦、时间同步或语言筛选歌词版本。';

  @override
  String get startupErrorTitle => '无法打开你的曲库。';

  @override
  String setlistCopyName(String name) {
    return '$name 的副本';
  }

  @override
  String get setlistSongMissing => '歌曲缺失';

  @override
  String get settingsImportTooLarge => '此文件过大，无法导入。';

  @override
  String songsJumpToLetter(String letter) {
    return '跳转到 $letter';
  }

  @override
  String get actionDiscard => '放弃';

  @override
  String get editorKeepEditing => '继续编辑';

  @override
  String get settingsDefaultShowChordsHint => '歌曲包含和弦时，在歌词上方显示和弦。';

  @override
  String get settingsDefaultAutoscrollHint => '歌词会跟随歌曲滚动。手动滚动模式下不会使用此功能。';

  @override
  String get accountUnavailableTitle => '尚未设置同步';

  @override
  String get accountSignedOutBenefits =>
      '连接 Google Drive 后，曲库会同步。之后，歌曲更改会自动同步。';

  @override
  String get accountManualSyncHint => '你也可以点按立即同步来同步曲库。';

  @override
  String get accountSignInWithGoogle => '使用 Google 登录';

  @override
  String get accountWorking => '正在处理…';

  @override
  String get accountNeverSynced => '从未同步';

  @override
  String get accountSyncedJustNow => '刚刚同步';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前同步',
      one: '1 分钟前同步',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前同步',
      one: '1 小时前同步',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前同步',
      one: '1 天前同步',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项冲突更改已另存为副本',
      one: '1 项冲突更改已另存为副本',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      '同一首歌曲或同一个歌单在两个位置都进行了编辑。没有内容丢失：另一个版本已另存为独立副本。';

  @override
  String get accountReviewConflicts => '查看副本';

  @override
  String get songsConflictFilterActive => '仅显示冲突副本';

  @override
  String get songsConflictFilterClear => '显示所有歌曲';

  @override
  String get songsConflictBadge => '冲突副本';

  @override
  String get songsConflictEmpty => '没有冲突副本。';

  @override
  String get accountAutoSync => '自动同步';

  @override
  String get accountAutoSyncHint => '连接后，以及添加、编辑或删除歌曲后进行同步。';

  @override
  String get accountDriveFolder => 'Google 云端硬盘库文件夹';

  @override
  String get accountPrivateDriveFolder => '私人Singbook文件夹';

  @override
  String get accountChooseDriveFolder => '选择文件夹';

  @override
  String get accountDriveFolderMoveTitle => '移动您的 Singbook 图书馆吗？';

  @override
  String get accountDriveFolderMoveBody =>
      '请选择一个 Google Drive 中可见的文件夹。Singbook 会先将歌曲和歌单复制到所选文件夹并验证副本，然后再将其设为当前同步文件夹。原始文件会保留在原位置作为备份。其他文件不会受到影响。导入此文件夹的 ChordPro 文件会纳入同步并添加 Singbook 元数据。';

  @override
  String get accountImportChordPro => '从云端硬盘导入 ChordPro';

  @override
  String get syncErrorFolderPickerUnavailable => '驱动器文件夹选择不可用';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      '请在受支持的设备上使用 Google 云端硬盘选择器选择一个可见的云端硬盘文件夹。';

  @override
  String get syncErrorDriveFolderMissing => 'Singbook Drive 文件夹不可用';

  @override
  String get syncErrorDriveFolderMissingHint => '再次选择该文件夹，或在 Google 云端硬盘中将其恢复。';

  @override
  String get syncErrorDriveFileAuthorization => 'Singbook 需要访问此云端硬盘文件夹';

  @override
  String get syncErrorDriveFileAuthorizationHint => '再次选择该文件夹以授予访问权限，然后同步您的库。';

  @override
  String get syncErrorFolderMigration => '图书馆还无法移动';

  @override
  String get syncErrorFolderMigrationHint => '您以前的图书馆仍然安全。检查连接并再次选择文件夹以重试。';

  @override
  String get syncErrorVisibleFolderRequired => '首先选择一个可见的云端硬盘文件夹';

  @override
  String get syncErrorVisibleFolderRequiredHint => '从云端硬盘导入文件之前，需要一个可见的库文件夹。';

  @override
  String get accountSignOutTitle => '退出此账户？';

  @override
  String get accountSignOutBody => '你的歌曲和歌单会保留在此设备上。重新登录之前，它们不会备份或同步。';

  @override
  String get accountSignInAgain => '重新登录';

  @override
  String get accountChooseAction => '选择如何继续';

  @override
  String get accountChangedTitle => '其他 Google 账户';

  @override
  String get accountChangedBody =>
      '此设备上次使用另一个 Google 账户进行同步。请选择如何处理此设备上的歌曲和歌单。';

  @override
  String get accountChangedMerge => '合并到新账户';

  @override
  String get accountChangedMergeHint => '保留此设备上的所有内容，并将其添加到新账户。';

  @override
  String get accountChangedReplace => '替换为新账户的曲库';

  @override
  String get accountChangedReplaceHint => '此设备上不在新账户中的歌曲将被移除。';

  @override
  String get accountChangedSignOut => '取消并退出登录';

  @override
  String get accountStatusSignedOut => '账户与同步：未登录';

  @override
  String get accountStatusSignedIn => '账户与同步：已登录';

  @override
  String get accountStatusSyncing => '账户与同步：正在同步';

  @override
  String get accountStatusSynced => '账户与同步：曲库已是最新';

  @override
  String get accountStatusError => '账户与同步：出现问题，点按查看';

  @override
  String get accountNoticeConflicts => '部分歌曲在两个位置都进行了编辑。已保留副本。';

  @override
  String get accountNoticeSignedIn => '已登录。';

  @override
  String get accountNoticeSignedOut => '已退出登录。你的歌曲会保留在此设备上。';

  @override
  String get syncErrorNotConfigured => '此版本尚未设置同步。';

  @override
  String get syncErrorNotConfiguredHint => '请使用配置了 Google 登录功能的 Singbook 版本。';

  @override
  String get syncErrorOAuthClientConfiguration => 'Google 拒绝了此版本的登录配置。';

  @override
  String get syncErrorOAuthClientConfigurationHint =>
      '请确认配置的 OAuth ID 属于 Singbook 桌面应用客户端。';

  @override
  String get syncErrorNotSignedIn => '你尚未登录。';

  @override
  String get syncErrorNotSignedInHint => '登录以同步曲库。';

  @override
  String get syncErrorAuthorizationRequired => 'Google 要求你重新登录。';

  @override
  String get syncErrorAuthorizationRequiredHint => '重新登录以继续同步。你的歌曲安全地保存在此设备上。';

  @override
  String get syncErrorAccessDenied => 'Singbook 无权使用 Google Drive。';

  @override
  String get syncErrorAccessDeniedHint => '请重新登录，并在出现提示时允许访问 Drive。';

  @override
  String get syncErrorRateLimited => 'Google 暂时限制了请求。';

  @override
  String get syncErrorRateLimitedHint => '等待几分钟后重试。';

  @override
  String get syncErrorStorageFull => 'Google Drive 已满。';

  @override
  String get syncErrorStorageFullHint => '请清理 Drive 空间后重试。';

  @override
  String get syncErrorNetwork => '无法连接到 Google。';

  @override
  String get syncErrorNetworkHint => '检查网络连接后重试。';

  @override
  String get syncErrorAccountChanged => '使用了另一个 Google 账户。';

  @override
  String get syncErrorAccountChangedHint => '选择将此设备的曲库与该账户合并，或替换此设备的曲库。';

  @override
  String get syncErrorRemoteLibraryTooLarge => '同步曲库的内容超出 Singbook 的处理能力。';

  @override
  String get syncErrorRemoteLibraryTooLargeHint => '从同步曲库中移除一些歌曲或歌单，然后重试。';

  @override
  String get syncErrorSignInFailed => '登录未完成。';

  @override
  String get syncErrorSignInFailedHint => '请尝试重新登录。';

  @override
  String get syncErrorGeneric => '无法同步曲库。';

  @override
  String get syncErrorGenericHint => '请稍后重试。你的歌曲仍安全地保存在此设备上。';

  @override
  String get editorDurationInvalid => '请输入秒数，或“分:秒”，例如 3:45。';

  @override
  String get editorNumberInvalid => '请输入数字。';

  @override
  String get accountReplaceConfirmTitle => '删除本地歌曲？';

  @override
  String get accountReplaceConfirmBody => '此设备上不在新账号中的歌曲和歌单将被永久删除。此操作无法撤销。';

  @override
  String get accountReplaceConfirmAction => '删除并替换';

  @override
  String get accountSuspiciousTitle => 'Google 云端硬盘中缺少项目';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此设备之前同步的 $count 个项目在 Google 云端硬盘中缺失。',
      one: '此设备之前同步的 $count 个项目在 Google 云端硬盘中缺失。',
    );
    return '$_temp0 如果在 Google 设置中清除了应用数据，就可能发生这种情况。目前尚未删除任何内容。';
  }

  @override
  String get accountSuspiciousDelete => '也从此设备删除';

  @override
  String get accountSuspiciousKeep => '保留我的歌曲并重新上传';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '要从此设备删除 $count 个项目吗？',
      one: '要从此设备删除 $count 个项目吗？',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody => '这些歌曲和歌单将从此设备永久删除，且无法撤销。';

  @override
  String get accountSuspiciousDeleteConfirmAction => '从此设备删除';

  @override
  String get syncErrorRemoteListingSuspicious => 'Google 云端硬盘中缺少项目。';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      '尚未删除任何内容。请选择也从此设备删除，或重新上传。';

  @override
  String get syncErrorRemoteChanged => '同步期间 Google 云端硬盘发生了更改。';

  @override
  String get syncErrorRemoteChangedHint => '没有内容丢失。请重新同步以获取最新更改。';

  @override
  String get syncErrorInvalidLocalData => '此设备上的部分数据无法同步。';

  @override
  String get syncErrorInvalidLocalDataHint => '无法读取某首歌曲或歌单。请重新导入或创建，然后再次同步。';

  @override
  String get syncErrorNoAccountChange => '没有需要处理的账号更改。';

  @override
  String get syncErrorNoAccountChangeHint => '请重新同步以继续。';

  @override
  String get accountSyncWarningTitle => '已同步，但跳过了部分文件';

  @override
  String get accountSyncWarningBody => '部分文件无法使用，因此保持原样。其他内容均已更新。';

  @override
  String get accountSyncWarningTooLarge => '某个文件过大，无法同步，因此已跳过。其他内容均已更新。';

  @override
  String get accountSyncWarningInvalid => '某个文件无法读取，因此已跳过。其他内容均已更新。';

  @override
  String get accountNoticeSyncSkipped => '已同步。跳过了部分文件。';

  @override
  String get settingsExportPdfTooLarge => '此 PDF 会过大。请减少歌曲数量，或以文本形式分享。';

  @override
  String get settingsTimingTooLarge => '计时数据过大（超过 3 MB）。';

  @override
  String get settingsImportDuplicateSongId => '此备份中同一首歌曲重复出现，因此未导入任何内容。';

  @override
  String get setlistSaveConflict => '歌单已在其他位置更改。你的修改已另存为一个副本。';

  @override
  String get sectionVerse => '主歌';

  @override
  String get sectionChorus => '副歌';

  @override
  String get sectionBridge => '桥段';

  @override
  String get sectionIntro => '前奏';

  @override
  String get sectionOutro => '尾奏';

  @override
  String get sectionPreChorus => '预副歌';

  @override
  String get sectionPostChorus => '后副歌';

  @override
  String get sectionInstrumental => '器乐段';

  @override
  String get sectionInterlude => '间奏';

  @override
  String get sectionSolo => '独奏';

  @override
  String get sectionRefrain => '叠句';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => '尾声';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => '结尾';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 可用版本',
      one: '1 可用版本',
      zero: '0 可用版本',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 不可用版本',
      one: '1 不可用版本',
      zero: '0 不可用版本',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => '跳转到章节';

  @override
  String get searchVersionDetails => '版本详情';

  @override
  String get searchSelectedRecording => '已选录音';

  @override
  String get searchVersionDuration => '版本时长';

  @override
  String get searchSourceOptions => '来源选项';

  @override
  String get actionUndo => '撤销';

  @override
  String setlistEntryRemoved(String song) {
    return '已从演出列表中移除 $song';
  }

  @override
  String get backupTitle => '备份与恢复';

  @override
  String get backupExport => '导出备份';

  @override
  String get backupSaveToDevice => '将备份保存到设备';

  @override
  String get backupRestore => '恢复备份';

  @override
  String get backupIncludePreferences => '包含应用偏好设置';

  @override
  String get backupRestorePreferences => '恢复应用偏好设置';

  @override
  String get backupMerge => '添加到此曲库';

  @override
  String get backupMergeHint => '保留本地编辑，并从此备份添加歌曲和演出列表。';

  @override
  String get backupReplace => '替换此曲库';

  @override
  String get backupReplaceHint => '用此备份替换此设备上的所有歌曲和演出列表。';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return '歌曲：$songs · 演出列表：$setlists · 冲突：$conflicts';
  }

  @override
  String get backupFailed => '无法完成此备份操作，请重试。';

  @override
  String get backupRestored => '备份已恢复。';

  @override
  String get backupLocalHint => '保存曲库副本。不会包含账户凭据或同意 Cookie。';

  @override
  String get backupReplaceConfirm => '要替换当前曲库吗？此操作无法撤销。';

  @override
  String get searchCheckOperations => '操作';

  @override
  String get searchCheckCode => '结果代码';

  @override
  String get searchCheckQueued => '正在等待检查此来源。';

  @override
  String get searchCheckFetch => '加载歌词';

  @override
  String get searchCheckValidate => '检查歌曲匹配情况';

  @override
  String get searchCheckCorroborate => '检查歌词一致性';

  @override
  String get searchCheckCompleted => '已完成';

  @override
  String get searchCheckTimeout => '来源未能及时响应。';

  @override
  String get searchCheckBlocked => '来源屏蔽了此请求。';

  @override
  String get searchCheckRateLimited => '来源正在限制请求。请稍后重试。';

  @override
  String get searchCheckNetwork => '无法连接到来源。请检查网络连接。';

  @override
  String get searchCheckInvalid => '来源返回了无法读取的响应。';

  @override
  String get searchCheckNotConfigured => '此构建版本未配置此来源。';

  @override
  String get searchCheckNoLyrics => '未找到匹配的歌词。';

  @override
  String get searchCheckFailed => '无法完成此操作。';

  @override
  String get searchCheckNoHistory => '此比较尚未运行任何来源检查。';

  @override
  String get searchVersionCredits => '鸣谢';

  @override
  String get searchVersionMediaLinks => '相关链接';

  @override
  String get searchCheckCancelled => '已取消';

  @override
  String get searchCheckAmbiguous => '找到多个匹配项。此来源需要更具体的录音信息。';

  @override
  String get searchCheckIdentity => '此来源需要录音或作品标识符。';

  @override
  String get searchCheckExtraction => '来源已响应，但无法提取歌词。';

  @override
  String get searchCheckBusy => '此来源正忙，请稍后重试。';

  @override
  String get searchCheckSelection => '请从此来源选择一个具体结果。';

  @override
  String get playerChordsNone => '无';

  @override
  String get editorCustomValue => '其他…';

  @override
  String get editorStandardTuning => '标准调弦';

  @override
  String get editorExampleVerse => '[C]新的一天在 [G]召唤，\n[Am]我们追随光芒回到 [F]家。';

  @override
  String get editorExampleChorus => '[F]一起唱这首 [C]歌，\n[G]让旋律带我们 [C]向前。';

  @override
  String get editorExampleBridge => '[Am]再写一行，靠近 [F]一点。';

  @override
  String get playerEstimatedKey => '估计调性';

  @override
  String get songsLibraryView => '曲库';

  @override
  String get settingsStartupView => '启动时打开';

  @override
  String get settingsStartupViewHint => '选择应用打开时显示的歌曲视图。';

  @override
  String get settingsStartupLastView => '上次打开';

  @override
  String get playerFullScreen => '全屏';

  @override
  String get playerExitFullScreen => '退出全屏';

  @override
  String get playerExpandControls => '显示播放控件';

  @override
  String get playerCollapseControls => '隐藏播放控件';

  @override
  String get settingsShowSections => '显示段落标题';

  @override
  String get settingsShowSectionsHint => '在歌词中显示主歌、副歌和其他段落的标题。';

  @override
  String get settingsShowPlayerControls => '显示播放控件';

  @override
  String get settingsShowPlayerControlsHint => '也可以轻触或滑动播放器面板来显示或隐藏它。';

  @override
  String get sourceAnalysisHeading => '已提交音频分析（未验证）';

  @override
  String sourceAnalysisCoverage(int shown, int total) {
    return '显示 $total 项提交中的 $shown 项';
  }

  @override
  String sourceAnalysisSample(int number) {
    return '样本 $number';
  }

  @override
  String get sourceAnalysisEstimatedTempo => '估算节奏（BPM）';
}
