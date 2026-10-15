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
  String get aboutDescription => '一个宁静的空间，让你查找、整理并跟着自己的歌曲库一起歌唱。';

  @override
  String get aboutMadeForSinging => '为一起歌唱而打造';

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
  String get searchSaved => '歌曲已保存到你的曲库。';

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
  String get setlistShare => '分享为歌单文件';

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
  String get readerEdit => '编辑歌词和详情';

  @override
  String get playerPlay => '开始滚动歌词';

  @override
  String get playerPause => '暂停滚动歌词';

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
  String get playerEstimatedPace => '估算速度';

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
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '合并自 $count 个来源',
      one: '合并自 1 个来源',
    );
    return '$_temp0';
  }

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
  String get editorLyricsHint => '点按一行即可编辑歌词或和弦。';

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
  String get settingsClearHistoryConfirm => '清除歌曲和歌单历史记录？';

  @override
  String get settingsHistoryCleared => '历史记录已清除。';

  @override
  String get accountTitle => '账户与同步';

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
      '使用 Google 登录，将歌曲和歌单备份到 Google Drive，并让所有设备保持同步。无论如何，你的歌曲都会保留在此设备上。';

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
  String get accountAutoSyncHint => '打开应用和进行更改后，保持曲库为最新状态。';

  @override
  String get accountSignOutTitle => '退出此账户？';

  @override
  String get accountSignOutBody => '你的歌曲和歌单会保留在此设备上。重新登录之前，它们不会备份或同步。';

  @override
  String get accountUseDifferent => '使用其他账户';

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
  String get accountSuspiciousTitle => 'Items missing from Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items that this device synced earlier are missing from Google Drive.',
      one:
          '$count item that this device synced earlier is missing from Google Drive.',
    );
    return '$_temp0 This can happen if app data was cleared in Google settings. Nothing has been deleted yet.';
  }

  @override
  String get accountSuspiciousDelete => 'Delete them here too';

  @override
  String get accountSuspiciousKeep => 'Keep my songs and upload them again';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items from this device?',
      one: 'Delete $count item from this device?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'These songs and setlists will be permanently deleted from this device. This can\'t be undone.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Delete from this device';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Items are missing from Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Nothing was deleted. Choose whether to delete them here too or upload them again.';

  @override
  String get syncErrorRemoteChanged => 'Google Drive changed while syncing.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Nothing was lost. Sync again to pick up the latest changes.';

  @override
  String get syncErrorInvalidLocalData =>
      'Some data on this device couldn\'t be synced.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'A song or setlist could not be read. Import or recreate it, then sync again.';

  @override
  String get syncErrorNoAccountChange =>
      'There is no account change to resolve.';

  @override
  String get syncErrorNoAccountChangeHint => 'Sync again to continue.';

  @override
  String get accountSyncWarningTitle => 'Synced, but some files were skipped';

  @override
  String get accountSyncWarningBody =>
      'Some files couldn\'t be used and were left as they are. Everything else is up to date.';

  @override
  String get accountSyncWarningTooLarge =>
      'A file was too large to sync and was skipped. Everything else is up to date.';

  @override
  String get accountSyncWarningInvalid =>
      'A file couldn\'t be read and was skipped. Everything else is up to date.';

  @override
  String get accountNoticeSyncSkipped => 'Synced. Some files were skipped.';

  @override
  String get settingsExportPdfTooLarge =>
      'This PDF would be too large. Try fewer songs, or share it as text.';

  @override
  String get settingsTimingTooLarge =>
      'The timing data is too large (over 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'This backup lists the same song twice, so nothing was imported.';

  @override
  String get setlistSaveConflict =>
      'The setlist changed elsewhere. Your edits were saved as a separate copy.';

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
}
