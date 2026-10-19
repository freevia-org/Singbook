// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      '歌詞、コード、セットリストをひとつにまとめ、リハーサルやステージ、いつもの演奏場所ですぐに使えます。';

  @override
  String get aboutMadeForSinging => 'すべての曲を、すぐに。';

  @override
  String get aboutDetails =>
      '利用可能なソースを検索し、歌詞、コード、タイミング、録音情報を比較して、演奏したいバージョンを保存できます。利用状況は曲やサービスによって異なります。';

  @override
  String get aboutFindTitle => 'ぴったりのバージョンを見つける';

  @override
  String get aboutKeepTitle => '自分のライブラリを作る';

  @override
  String get aboutKeepDetails =>
      '曲を編集・移調し、オフラインでも使えるようローカルライブラリに保存して、持ち運べるChordProファイルを共有できます。Google Driveとの同期は任意で、Googleアカウント内のアプリ専用フォルダを使います。「今すぐ同期」をタップして、端末間で更新することもできます。';

  @override
  String get aboutPlayTitle => 'セットリストをステージへ';

  @override
  String get aboutPlayDetails =>
      '曲をセットリストに並べ、曲ごとにキーを選び、OpenSongのセットリストを共有できます。リーダーの文字サイズを調整し、歌詞を自動スクロールしたり、曲のPDFを印刷したりできます。Singbookは音声のストリーミングや再生を行いません。';

  @override
  String get aboutPrivacyTitle => '無料で、端末を中心に使える';

  @override
  String get aboutPrivacyDetails =>
      'Singbookは無料で、広告、分析機能、アプリ内購入はありません。保存したライブラリは端末に保管され、任意の同期にはご自身のGoogle Driveを使います。オンライン検索結果は独立した第三者サービスから直接提供され、利用できない場合や著作権で保護されている場合があります。Singbookはそれらのコンテンツをホストしません。';

  @override
  String get aboutWebsite => 'Singbookのウェブサイト';

  @override
  String get aboutSourceCode => 'GitHubのソースコード';

  @override
  String get aboutPublisher => 'Freeviaより';

  @override
  String aboutLanguages(int count) {
    return 'アプリの言語: $count';
  }

  @override
  String get aboutSupport => 'サポートとフィードバック';

  @override
  String get menuTypeNewSong => '新しい曲を入力';

  @override
  String appVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get navHome => 'ホーム';

  @override
  String get navSongs => '曲';

  @override
  String get navSetlists => 'セットリスト';

  @override
  String get navSettings => '設定';

  @override
  String get navSettingsCompact => '設定';

  @override
  String get navSearch => '検索';

  @override
  String get navBack => '戻る';

  @override
  String get appExitBackAgain => '終了するには、もう一度戻るを押してください';

  @override
  String get navClose => '閉じる';

  @override
  String get navMore => 'その他の操作';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionSave => '保存';

  @override
  String get actionDone => '完了';

  @override
  String get actionEdit => '編集';

  @override
  String get actionDelete => '削除';

  @override
  String get actionShare => '共有';

  @override
  String get actionPrint => '印刷';

  @override
  String get actionCopy => 'コピー';

  @override
  String get actionClear => 'クリア';

  @override
  String get actionRetry => '再試行';

  @override
  String get actionRefresh => '更新';

  @override
  String get actionImport => 'インポート';

  @override
  String get actionExport => 'エクスポート';

  @override
  String get actionExpand => '展開';

  @override
  String get actionCollapse => '折りたたむ';

  @override
  String get actionAdd => '追加';

  @override
  String get actionCreate => '作成';

  @override
  String get actionRemove => '削除';

  @override
  String get actionDuplicate => '複製';

  @override
  String get actionMoveUp => '上へ移動';

  @override
  String get actionMoveDown => '下へ移動';

  @override
  String get actionPrevious => '前へ';

  @override
  String get actionNext => '次へ';

  @override
  String get searchHint => '曲名、アーティスト、歌詞を検索';

  @override
  String get searchCatalogHint => '曲名またはアーティストを検索';

  @override
  String get searchChangeSong => '曲を変更';

  @override
  String get searchSelectedPreview => '選択したプレビュー';

  @override
  String get searchSubmit => '検索';

  @override
  String get searchFilters => '検索オプション';

  @override
  String get searchFiltersShow => '検索オプションを表示';

  @override
  String get searchFiltersHide => '検索オプションを非表示';

  @override
  String get searchFilterArtist => 'アーティスト';

  @override
  String get searchFilterTitle => '曲名';

  @override
  String get searchFilterLyrics => '歌詞';

  @override
  String get searchFilterChords => 'コードあり';

  @override
  String get searchFilterTimed => 'タイミング付き歌詞';

  @override
  String get searchFilterLanguage => '言語';

  @override
  String get searchFilterAll => 'すべて';

  @override
  String get searchAutocompleteLabel => '候補';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の結果',
      one: '1件の結果',
      zero: '結果はありません',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery => '検索する曲名、アーティスト名、または歌詞を入力してください。';

  @override
  String get searchCatalogEmptyQuery => '検索する曲名またはアーティスト名を入力してください。';

  @override
  String get searchNoResults => '曲が見つかりませんでした。別のキーワードでお試しください。';

  @override
  String get searchLoading => '曲を検索しています…';

  @override
  String get searchError => '検索を完了できませんでした。';

  @override
  String get searchOnlineTab => 'オンライン';

  @override
  String get searchRecentTab => '最近';

  @override
  String get searchFavoritesTab => 'お気に入り';

  @override
  String get searchSuggested => 'おすすめの一致';

  @override
  String get searchAlternatives => 'その他の一致';

  @override
  String get searchCompare => 'バージョンを比較';

  @override
  String get searchChooseVersion => 'このバージョンを選択';

  @override
  String get searchFullPreview => '全体をプレビュー';

  @override
  String get searchArrangementNotes => '編曲メモ';

  @override
  String get searchOpenLyrics => '歌詞を開く';

  @override
  String get searchContributions => '使用したソース';

  @override
  String get searchVersionChecking => 'このバージョンを確認中…';

  @override
  String get searchVersionUnavailable => 'このバージョンは使用できません。別のバージョンを選んでください。';

  @override
  String get searchPreviewUnavailable => '歌詞のプレビューはありません。';

  @override
  String get searchSongMatch => '曲の一致';

  @override
  String get searchRecordingMatch => '録音の一致';

  @override
  String get searchMatchUnverified => '録音は未確認です';

  @override
  String get searchMatchExact => '録音が完全に一致';

  @override
  String get searchMatchPossible => '一致する可能性があります';

  @override
  String get searchAvailability => '利用状況';

  @override
  String get searchLyricsAvailable => '歌詞あり';

  @override
  String get searchLyricsUnavailable => '歌詞なし';

  @override
  String get searchChordsAvailable => 'コードあり';

  @override
  String get searchChordsUnavailable => 'コードなし';

  @override
  String get searchTimingAvailable => 'タイミング情報あり';

  @override
  String get searchTimingUnavailable => 'タイミング情報なし';

  @override
  String get searchDurationUnknown => '長さ不明';

  @override
  String searchRating(String rating) {
    return '評価 $rating';
  }

  @override
  String get searchSourceLabel => 'ソース';

  @override
  String get searchMetadata => '曲の詳細';

  @override
  String get searchAlbum => 'アルバム';

  @override
  String get searchArtist => 'アーティスト';

  @override
  String get searchYear => '年';

  @override
  String get searchLanguage => '言語';

  @override
  String get searchViewVersions => 'バージョンを見る';

  @override
  String get searchSaved => '曲をライブラリに保存しました。';

  @override
  String get searchSaveOpenLyrics => '歌詞を保存して開く';

  @override
  String get searchOtherResults => 'その他の結果';

  @override
  String get searchSaveFailed => '曲を保存できませんでした。';

  @override
  String get homeRecentSongs => '最近の曲';

  @override
  String get homeRecentlyPlayed => '最近再生した曲';

  @override
  String get homeFavorites => 'お気に入り';

  @override
  String get homeHistory => '履歴';

  @override
  String get homeHistoryClear => '履歴を消去';

  @override
  String get homeHistoryCleared => '履歴を消去しました。';

  @override
  String get homeHistoryEmpty => '開いた曲がここに表示されます。';

  @override
  String get homeFavoritesEmpty => 'お気に入りの曲とセットリストがここに表示されます。';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件を表示中',
      one: '1件を表示中',
      zero: '0件を表示中',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty => '最近の曲とセットリストがここに表示されます。';

  @override
  String get homeTimelineLabel => '履歴のタイムライン';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'すべての履歴';

  @override
  String get homeShowFavorites => 'お気に入りを表示';

  @override
  String get homeShowRecent => '最近の項目を表示';

  @override
  String get songsTitle => '曲';

  @override
  String get songsEmpty => '曲がここに表示されます。';

  @override
  String get songsEmptySearch => '検索に一致する曲はありません。';

  @override
  String get songsAdd => '曲を追加';

  @override
  String get songsSortAlphabetical => 'アルファベット順に並べ替え';

  @override
  String get songsAlphabetNavigation => '曲の索引';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count回',
      one: '1回',
      zero: '0回',
    );
    return '開いた回数: $_temp0';
  }

  @override
  String get songFavoriteAdd => 'お気に入りに追加';

  @override
  String get songFavoriteRemove => 'お気に入りから削除';

  @override
  String get songMenuLabel => '曲の操作';

  @override
  String get songInfo => '曲の詳細';

  @override
  String get setlistMenuLabel => 'セットリストの操作';

  @override
  String get songAddToSetlist => 'セットリストに追加';

  @override
  String get songCopyChordPro => 'ChordProをコピー';

  @override
  String get songDeleteConfirmTitle => '曲を削除しますか？';

  @override
  String get songDeleteConfirmMessage => 'この曲はライブラリから削除されます。';

  @override
  String get songDeleted => '曲を削除しました。';

  @override
  String get setlistsTitle => 'セットリスト';

  @override
  String get setlistsEmpty => '次のリハーサルや演奏に向けてセットリストを作成しましょう。';

  @override
  String get setlistsEmptySearch => '検索に一致するセットリストはありません。';

  @override
  String get setlistCreate => '新しいセットリスト';

  @override
  String get setlistNameHint => 'セットリスト名';

  @override
  String get setlistNotes => 'メモ';

  @override
  String get setlistEntryOverride => '曲ごとのキーとカポ';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count曲',
      one: '1曲',
      zero: '曲はありません',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return '少なくとも $duration';
  }

  @override
  String get setlistDurationUnknown => '長さ不明';

  @override
  String setlistActivity(String date) {
    return '最終操作 $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return '作成日 $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return '編集日 $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return '最終再生日 $date';
  }

  @override
  String get setlistSongsEmpty => 'このセットリストにはまだ曲がありません。';

  @override
  String get setlistAddSongs => '曲を追加';

  @override
  String get setlistReorder => '曲の順序を変更';

  @override
  String setlistMoveSongUp(String song) {
    return '「$song」を上へ移動';
  }

  @override
  String setlistMoveSongDown(String song) {
    return '「$song」を下へ移動';
  }

  @override
  String setlistRemoveSong(String song) {
    return '「$song」をセットリストから削除';
  }

  @override
  String get setlistDuplicate => 'セットリストを複製';

  @override
  String get setlistFavoriteAdd => 'セットリストをお気に入りに追加';

  @override
  String get setlistFavoriteRemove => 'セットリストをお気に入りから削除';

  @override
  String get setlistShare => 'OpenSongとして共有';

  @override
  String get setlistSharePdf => 'PDFとして共有';

  @override
  String get setlistPrint => '印刷';

  @override
  String get setlistDeleteConfirmTitle => 'セットリストを削除しますか？';

  @override
  String get setlistDeleteConfirmMessage => 'セットリストは削除されます。ライブラリ内の曲はそのまま残ります。';

  @override
  String get setlistDeleted => 'セットリストを削除しました。';

  @override
  String get readerTitle => '歌詞';

  @override
  String get readerNoLyrics => '歌詞はまだ追加されていません。';

  @override
  String get readerShowChords => 'コードを表示';

  @override
  String get readerHideChords => 'コードを非表示';

  @override
  String get readerTranspose => 'コードを移調';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count半音',
      one: '1半音',
      zero: '0半音',
    );
    return '$_temp0だけ移調';
  }

  @override
  String get readerSaved => '保存済み';

  @override
  String get readerEdit => '歌詞と詳細を編集';

  @override
  String get playerPlay => '再生';

  @override
  String get playerPause => '一時停止';

  @override
  String get playerResume => '歌詞のスクロールを再開';

  @override
  String get playerSeek => '再生位置';

  @override
  String playerElapsed(String time) {
    return '経過時間 $time';
  }

  @override
  String playerRemaining(String time) {
    return '残り時間 $time';
  }

  @override
  String get playerTimingMode => 'スクロールモード';

  @override
  String get playerTimedLyrics => 'タイミング付き歌詞';

  @override
  String get playerStartScroll => '自動スクロールを開始';

  @override
  String get playerEstimatedPace => '推定速度';

  @override
  String get playerScrollSpeed => 'スクロール速度';

  @override
  String playerEstimatedDuration(String time) {
    return '推定時間：$time';
  }

  @override
  String get playerLyricsOnly => '歌詞スクロール・音声なし';

  @override
  String get playerManualScroll => '手動スクロール';

  @override
  String get playerTimingStatusReady => '利用可能なタイミングに合わせて歌詞がスクロールします。';

  @override
  String get playerTimingStatusEstimated => '曲の長さからスクロール速度を推定します。';

  @override
  String get playerTimingStatusManual => '歌詞を手動でスクロールしてください。';

  @override
  String get playerTimingStatusUnavailable => 'この曲ではタイミング付きスクロールを利用できません。';

  @override
  String get playerDurationUnknown => '推定スクロールを使うには曲の長さを追加してください。';

  @override
  String get playerProgressLabel => '曲の進行状況';

  @override
  String get playerCurrentSection => '現在のセクション';

  @override
  String get playerPreviousSection => '前のセクション';

  @override
  String get playerNextSection => '次のセクション';

  @override
  String get playerPreviousSectionSong => '前のセクション · 長押しで前のセットリストの曲へ';

  @override
  String get playerNextSectionSong => '次のセクション · 長押しで次のセットリストの曲へ';

  @override
  String get playerPreviousSong => '前の曲';

  @override
  String get playerNextSong => '次の曲';

  @override
  String get editorTitle => '曲を編集';

  @override
  String get editorTitleField => '曲名';

  @override
  String get editorArtistField => 'アーティスト';

  @override
  String get editorAlbumField => 'アルバム';

  @override
  String get editorLyricsField => '歌詞';

  @override
  String get editorChordsField => 'コード';

  @override
  String get editorKeyField => 'キー';

  @override
  String get editorCapoField => 'カポ';

  @override
  String get editorTuningField => 'チューニング';

  @override
  String get editorTempoField => 'テンポ';

  @override
  String get editorDurationField => '長さ';

  @override
  String get editorTimeSignatureField => '拍子';

  @override
  String get editorLanguageField => '言語';

  @override
  String get editorYearField => '年';

  @override
  String get editorComposerField => '作曲者';

  @override
  String get editorLyricistField => '作詞者';

  @override
  String get editorCopyrightField => '著作権';

  @override
  String get editorLicenseField => 'ライセンス';

  @override
  String get songInfoSources => 'ソースとクレジット';

  @override
  String get searchMatchSameSong => '同じ曲ですが、録音は確認されていません';

  @override
  String get searchMatchNeedsAgreement => 'コード譜を歌詞と照合する必要があります';

  @override
  String get searchMatchDifferentLyrics => '選択した曲と歌詞が異なります';

  @override
  String get searchMatchCombinedSources => '複数のソースから詳細を統合しました';

  @override
  String get searchCombinedLabel => '統合';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count曲の一致',
      one: '1曲の一致',
      zero: '0曲の一致',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のソースバージョン',
      one: '1個のソースバージョン',
      zero: '0個のソースバージョン',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => '最適な一致';

  @override
  String get providerDescriptionUnknown => '曲のソース';

  @override
  String get providerDescDownloadChordProThenImport =>
      'ソースからChordProファイルをダウンロードしてインポートしてください。';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      '無料アカウントでファイルをダウンロードしてからインポートしてください。';

  @override
  String get providerDescPublicChordSheets => '公開されているコード譜。';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      '歴史的な歌詞は作品ごとにライセンスされています。';

  @override
  String get providerDescLicensedCatalog => 'ライセンス済みの歌詞カタログ。';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Creative Commons BYライセンスのオリジナル曲。';

  @override
  String get providerDescPerSongLicense => '歌詞は曲ごとにライセンスされています。';

  @override
  String get providerDescRecordingMetadataOnly => '録音とリリースの詳細のみ。';

  @override
  String get providerDescCompositionMetadataOnly => '楽曲の詳細のみ。';

  @override
  String get providerDescExactFileArtworkOnly => 'アートワークは録音が完全に一致する場合のみ利用できます。';

  @override
  String get providerCapabilityLyrics => '歌詞';

  @override
  String get providerCapabilityChords => 'コード';

  @override
  String get providerCapabilityTiming => 'タイミング付き歌詞';

  @override
  String get providerCapabilitySearch => '検索';

  @override
  String get providerCapabilityMetadata => '曲の詳細';

  @override
  String get editorArtworkField => 'アートワークのリンク';

  @override
  String get editorLyricsHint => 'コードは [C] の角括弧に入れ、セクション名は別の行に入力します。';

  @override
  String get editorSave => '変更を保存';

  @override
  String get editorSaved => '変更を保存しました。';

  @override
  String get editorSaveFailed => '変更を保存できませんでした。';

  @override
  String get editorSaveConflict => '別の場所で曲が変更されました。編集内容は別のコピーとして保存されました。';

  @override
  String get editorUnsavedTitle => '変更を破棄しますか？';

  @override
  String get editorUnsavedMessage => '編集内容は保存されていません。';

  @override
  String get editorFieldRequired => '曲名を入力してください。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeSystem => '端末の設定を使用';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsColorPalette => 'カラーパレット';

  @override
  String get settingsFont => 'フォント';

  @override
  String get settingsTextSize => '文字サイズ';

  @override
  String get settingsLyricsPreview => '歌詞のプレビュー';

  @override
  String get settingsPlayer => '歌詞プレーヤー';

  @override
  String get settingsLyricHighlight => '現在の歌詞行の強調';

  @override
  String get settingsHighlightBackgroundUnderline => '背景＋下線';

  @override
  String get settingsHighlightBackground => '背景';

  @override
  String get settingsHighlightUnderline => '下線';

  @override
  String get settingsHighlightContrast => 'コントラストのある文字色';

  @override
  String get settingsHighlightNone => 'なし';

  @override
  String get settingsDefaultShowChords => 'デフォルトでコードを表示';

  @override
  String get settingsDefaultAutoscroll => '歌詞の自動スクロールを開始';

  @override
  String get settingsDefaultTiming => 'デフォルトのスクロールモード';

  @override
  String get settingsLanguage => 'アプリの言語';

  @override
  String get settingsLanguageSystem => '端末の言語を使用';

  @override
  String get settingsLanguageEnglish => '英語';

  @override
  String get settingsLanguageBulgarian => 'ブルガリア語';

  @override
  String get settingsLanguageUkrainian => 'ウクライナ語';

  @override
  String get settingsSources => '歌詞のソース';

  @override
  String settingsSourceEnabled(String source) {
    return 'ソース $source を有効にする';
  }

  @override
  String get settingsSourceRefresh => 'ソース一覧を更新';

  @override
  String get settingsSourcesUpdated => 'ソースを更新しました。';

  @override
  String get settingsSourcesUpdateFailed => 'ソースを更新できませんでした。';

  @override
  String get settingsImport => '曲をインポート';

  @override
  String get settingsImportChordPro => 'ChordProファイルをインポート';

  @override
  String get settingsImportSetlist => 'セットリストファイルをインポート';

  @override
  String get settingsImportSuccess => 'インポートが完了しました。';

  @override
  String get settingsImportFailed => 'このファイルをインポートできませんでした。';

  @override
  String get settingsImportUnsupported => 'このファイル形式はサポートされていません。';

  @override
  String get settingsShareSong => 'ChordProとして共有';

  @override
  String get settingsSharePdf => 'PDFとして共有';

  @override
  String get settingsCopySong => 'クリップボードにコピー';

  @override
  String get settingsPrintSong => '曲のみ印刷';

  @override
  String get settingsPrintSetlist => '歌詞付きセットリストを印刷';

  @override
  String get settingsExportFailed => 'ファイルを準備できませんでした。';

  @override
  String get settingsCopied => 'クリップボードにコピーしました。';

  @override
  String get settingsAbout => 'アプリについて';

  @override
  String get settingsPrivacy => 'プライバシー';

  @override
  String get settingsLegal => '法的情報';

  @override
  String get settingsClearHistory => '履歴を消去';

  @override
  String get settingsClearHistoryConfirm => '曲とセットリストの履歴を消去しますか？';

  @override
  String get settingsHistoryCleared => '履歴を消去しました。';

  @override
  String get accountTitle => 'アカウントと同期';

  @override
  String get accountUnavailable =>
      '同期にはGoogleログインを設定したSingbookのビルドが必要です。このビルドでは曲はこの端末にのみ保存されます。';

  @override
  String get accountSyncNow => '今すぐ同期';

  @override
  String get accountConnected => '接続しました。「今すぐ同期」を選択してバックアップを更新してください。';

  @override
  String get accountSignIn => 'アカウントを接続';

  @override
  String get accountSignOut => 'ログアウト';

  @override
  String get accountChange => 'アカウントを変更';

  @override
  String get accountSignedOut => '未接続';

  @override
  String get accountSyncing => 'ライブラリを同期しています…';

  @override
  String get accountSynced => 'ライブラリを同期しました。';

  @override
  String get accountSyncFailed => 'ライブラリを同期できませんでした。';

  @override
  String get accessibilityFavorite => 'お気に入り';

  @override
  String get accessibilityNotFavorite => 'お気に入りではありません';

  @override
  String get accessibilitySearchField => '曲を検索';

  @override
  String get accessibilityClearSearch => '検索文字列を消去';

  @override
  String accessibilitySongMenu(String song) {
    return '「$song」の操作';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return '「$setlist」の操作';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return '「$setlist」の曲を展開';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return '「$setlist」の曲を折りたたむ';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return '再生の進行状況、$percentパーセント';
  }

  @override
  String accessibilityTimeline(String date) {
    return '履歴のタイムライン、$date';
  }

  @override
  String get loading => '読み込み中…';

  @override
  String get loadingSongs => '曲を読み込み中…';

  @override
  String get loadingSetlists => 'セットリストを読み込み中…';

  @override
  String get errorGeneric => '問題が発生しました。';

  @override
  String get errorOffline => 'オフラインのようです。';

  @override
  String get errorPermission => '続行するには権限が必要です。';

  @override
  String get emptyFiltered => 'これらのフィルターに一致する項目はありません。';

  @override
  String get unknownValue => '不明';

  @override
  String get durationUnknown => '長さ不明';

  @override
  String get metadataNotSet => '未設定';

  @override
  String get dateToday => '今日';

  @override
  String get dateYesterday => '昨日';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count曲',
      one: '1曲',
      zero: '曲はありません',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'ネイビー';

  @override
  String get settingsPaletteSage => 'セージ';

  @override
  String get settingsPaletteOcean => 'オーシャン';

  @override
  String get settingsPaletteClay => 'クレイ';

  @override
  String get settingsPalettePlum => 'プラム';

  @override
  String get settingsFontSystem => 'システム';

  @override
  String get settingsFontSerif => 'セリフ';

  @override
  String get settingsFontMonospace => '等幅';

  @override
  String get settingsLyricsPreviewExample => '朝が来たら、また一緒に歌いましょう。';

  @override
  String get settingsPreviewSongTitle => '朝の歌';

  @override
  String get settingsPreviewArtist => 'アレンジ例';

  @override
  String get settingsPreviewCurrentLine => '朝が来たら';

  @override
  String get settingsPreviewNextLine => 'また一緒に歌いましょう。';

  @override
  String get settingsPlayerSections => 'セクション見出し';

  @override
  String get settingsPlayerControls => '再生パネル';

  @override
  String get settingsPlayerAutoscroll => '自動スクロール';

  @override
  String get settingsSystemShort => 'デバイス';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return '歌詞ソースを確認中: $total件中$checked件完了。';
  }

  @override
  String get searchDiscoveryNoLyrics => '使用できる歌詞が見つかりませんでした。';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      '選択した曲を有効なソースで確認しましたが、使用できる歌詞のバージョンは見つかりませんでした。';

  @override
  String get searchDiscoveryError => '歌詞ソースを確認できませんでした。';

  @override
  String get searchDiscoveryRetry => '歌詞を再検索';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '利用できないソースは$count件',
      one: '利用できないソースは1件',
      zero: '利用できないソースは0件',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => '接続を確認して、もう一度お試しください。';

  @override
  String get searchProviderChecks => 'ソースの確認';

  @override
  String get searchProviderPending => '確認中';

  @override
  String get searchProviderFound => '一致が見つかりました';

  @override
  String get searchProviderRejected => '一致しません';

  @override
  String get searchProviderFailed => '確認に失敗しました';

  @override
  String get searchProviderUnavailable => '使用できる歌詞がありません';

  @override
  String get searchCatalogFilterHint => '曲を選択すると、コード、タイミング、言語で歌詞のバージョンを絞り込めます。';

  @override
  String get startupErrorTitle => 'ライブラリを開けませんでした。';

  @override
  String setlistCopyName(String name) {
    return '$nameのコピー';
  }

  @override
  String get setlistSongMissing => '曲が見つかりません';

  @override
  String get settingsImportTooLarge => 'このファイルは大きすぎてインポートできません。';

  @override
  String songsJumpToLetter(String letter) {
    return '$letterに移動';
  }

  @override
  String get actionDiscard => '破棄';

  @override
  String get editorKeepEditing => '編集を続ける';

  @override
  String get settingsDefaultShowChordsHint => '曲にコードがある場合、歌詞の上に表示します。';

  @override
  String get settingsDefaultAutoscrollHint =>
      '曲に合わせて歌詞がスクロールします。手動スクロールモードでは使用されません。';

  @override
  String get accountUnavailableTitle => '同期が設定されていません';

  @override
  String get accountSignedOutBenefits =>
      'Google Driveに接続すると、ライブラリが同期されます。その後、曲の変更は自動的に同期されます。';

  @override
  String get accountManualSyncHint => '今すぐ同期をタップしてライブラリを同期することもできます。';

  @override
  String get accountSignInWithGoogle => 'Googleでログイン';

  @override
  String get accountWorking => '処理中…';

  @override
  String get accountNeverSynced => '未同期';

  @override
  String get accountSyncedJustNow => 'たった今同期';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count分前に同期',
      one: '1分前に同期',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count時間前に同期',
      one: '1時間前に同期',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日前に同期',
      one: '1日前に同期',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '競合した編集$count件をコピーとして保存しました',
      one: '競合した編集1件をコピーとして保存しました',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      '同じ曲またはセットリストが2か所で編集されました。データは失われていません。もう一方のバージョンは別のコピーとして保存されました。';

  @override
  String get accountReviewConflicts => 'コピーを確認';

  @override
  String get songsConflictFilterActive => '競合コピーのみを表示中';

  @override
  String get songsConflictFilterClear => 'すべての曲を表示';

  @override
  String get songsConflictBadge => '競合コピー';

  @override
  String get songsConflictEmpty => '競合コピーはありません。';

  @override
  String get accountAutoSync => '自動同期';

  @override
  String get accountAutoSyncHint => '接続後、および曲の追加、編集、削除後に同期します。';

  @override
  String get accountDriveFolder => 'Googleドライブのライブラリフォルダ';

  @override
  String get accountPrivateDriveFolder => 'プライベート Singbook フォルダー';

  @override
  String get accountChooseDriveFolder => 'フォルダーを選択してください';

  @override
  String get accountDriveFolderMoveTitle => 'Singbook ライブラリを移動しますか?';

  @override
  String get accountDriveFolderMoveBody =>
      '表示されている Google ドライブ フォルダーを選択します。 Singbook は、そこに切り替える前に、そこに曲とセットリストをコピーして検証します。元のファイルはバックアップとして以前の場所に残ります。他のファイルはそのまま残されます。このフォルダーにインポートした ChordPro ファイルは、同期に採用され、Singbook メタデータを受信します。';

  @override
  String get accountImportChordPro => 'ChordPro をドライブからインポート';

  @override
  String get accountImportChordProHint =>
      'このライブラリに追加する .cho ファイルを選択します。フォルダー内に既にあるファイルが採用されます。他の場所にあるファイルはここにコピーされます。';

  @override
  String get syncErrorFolderPickerUnavailable => 'ドライブフォルダーの選択は使用できません';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      '対応デバイスで Google ドライブ ピッカーを使い、表示されるドライブ フォルダを選択してください。';

  @override
  String get syncErrorDriveFolderMissing => 'Singbook Drive フォルダーが使用できません';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'フォルダーを再度選択するか、Google ドライブに復元します。';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook はこのドライブ フォルダーにアクセスする必要があります';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'フォルダーを再度選択してアクセスを許可し、ライブラリを同期します。';

  @override
  String get syncErrorFolderMigration => 'ライブラリはまだ移動できませんでした';

  @override
  String get syncErrorFolderMigrationHint =>
      '以前のライブラリはまだ安全です。接続を確認し、フォルダーを再度選択して再試行してください。';

  @override
  String get syncErrorVisibleFolderRequired => '最初に表示されるドライブ フォルダーを選択してください';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'ドライブからファイルをインポートする前に、表示可能なライブラリ フォルダーが必要です。';

  @override
  String get accountSignOutTitle => 'このアカウントからログアウトしますか？';

  @override
  String get accountSignOutBody =>
      '曲とセットリストはこの端末に残ります。再度ログインするまでバックアップと同期は行われません。';

  @override
  String get accountUseDifferent => '別のアカウントを使用';

  @override
  String get accountSignInAgain => '再度ログイン';

  @override
  String get accountChooseAction => '続行方法を選択';

  @override
  String get accountChangedTitle => '別のGoogleアカウント';

  @override
  String get accountChangedBody =>
      'この端末は最後に別のGoogleアカウントと同期しました。この端末の曲とセットリストをどうするか選択してください。';

  @override
  String get accountChangedMerge => '新しいアカウントに統合';

  @override
  String get accountChangedMergeHint => 'この端末のすべてを保持し、新しいアカウントに追加します。';

  @override
  String get accountChangedReplace => '新しいアカウントのライブラリに置き換え';

  @override
  String get accountChangedReplaceHint => '新しいアカウントにないこの端末の曲は削除されます。';

  @override
  String get accountChangedSignOut => 'キャンセルしてログアウト';

  @override
  String get accountStatusSignedOut => 'アカウントと同期: 未ログイン';

  @override
  String get accountStatusSignedIn => 'アカウントと同期: ログイン済み';

  @override
  String get accountStatusSyncing => 'アカウントと同期: 同期中';

  @override
  String get accountStatusSynced => 'アカウントと同期: ライブラリは最新です';

  @override
  String get accountStatusError => 'アカウントと同期: 問題があります。タップして確認してください';

  @override
  String get accountNoticeConflicts => '一部の曲が2か所で編集されました。コピーを保存しました。';

  @override
  String get accountNoticeSignedIn => 'ログインしました。';

  @override
  String get accountNoticeSignedOut => 'ログアウトしました。曲はこの端末に残ります。';

  @override
  String get syncErrorNotConfigured => 'このビルドでは同期が設定されていません。';

  @override
  String get syncErrorNotConfiguredHint =>
      'Googleログインが設定されたSingbookのビルドを使用してください。';

  @override
  String get syncErrorNotSignedIn => 'ログインしていません。';

  @override
  String get syncErrorNotSignedInHint => 'ライブラリを同期するにはログインしてください。';

  @override
  String get syncErrorAuthorizationRequired => 'Googleへの再ログインが必要です。';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      '同期を続けるには再度ログインしてください。曲はこの端末に安全に保存されています。';

  @override
  String get syncErrorAccessDenied => 'SingbookにはGoogle Driveを使用する権限がありません。';

  @override
  String get syncErrorAccessDeniedHint => '再度ログインし、表示されたらDriveへのアクセスを許可してください。';

  @override
  String get syncErrorRateLimited => 'Googleは現在リクエストを制限しています。';

  @override
  String get syncErrorRateLimitedHint => '数分待ってから、もう一度お試しください。';

  @override
  String get syncErrorStorageFull => 'Google Driveの空き容量がありません。';

  @override
  String get syncErrorStorageFullHint => 'Driveの空き容量を増やしてから、もう一度お試しください。';

  @override
  String get syncErrorNetwork => 'Googleに接続できませんでした。';

  @override
  String get syncErrorNetworkHint => 'インターネット接続を確認して、もう一度お試しください。';

  @override
  String get syncErrorAccountChanged => '別のGoogleアカウントが使用されました。';

  @override
  String get syncErrorAccountChangedHint =>
      'この端末のライブラリをそのアカウントに統合するか、置き換えるか選択してください。';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      '同期されたライブラリが大きすぎてSingbookで処理できません。';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      '同期されたライブラリから曲またはセットリストを削除して、もう一度お試しください。';

  @override
  String get syncErrorSignInFailed => 'ログインを完了できませんでした。';

  @override
  String get syncErrorSignInFailedHint => 'もう一度ログインしてください。';

  @override
  String get syncErrorGeneric => 'ライブラリを同期できませんでした。';

  @override
  String get syncErrorGenericHint => 'しばらくしてからもう一度お試しください。曲はこの端末に安全に保存されています。';

  @override
  String get editorDurationInvalid => '秒、または「分:秒」の形式で入力してください(例: 3:45)。';

  @override
  String get editorNumberInvalid => '数字を入力してください。';

  @override
  String get accountReplaceConfirmTitle => 'ローカルの曲を削除しますか?';

  @override
  String get accountReplaceConfirmBody =>
      'このデバイスにある曲とセットリストのうち、新しいアカウントにないものは完全に削除されます。この操作は元に戻せません。';

  @override
  String get accountReplaceConfirmAction => '削除して置き換え';

  @override
  String get accountSuspiciousTitle => 'Google Drive にない項目';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の項目が Google Drive にありません。このデバイスでは以前同期されていました。',
      one: '$count 件の項目が Google Drive にありません。このデバイスでは以前同期されていました。',
    );
    return '$_temp0 Google の設定でアプリのデータを消去すると、この状態になることがあります。まだ何も削除されていません。';
  }

  @override
  String get accountSuspiciousDelete => 'このデバイスからも削除';

  @override
  String get accountSuspiciousKeep => '曲を残して再アップロード';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このデバイスから $count 件の項目を削除しますか?',
      one: 'このデバイスから $count 件の項目を削除しますか?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'これらの曲とセットリストはこのデバイスから完全に削除されます。この操作は元に戻せません。';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'このデバイスから削除';

  @override
  String get syncErrorRemoteListingSuspicious => 'Google Drive にない項目があります。';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      '何も削除されていません。このデバイスからも削除するか、再アップロードするかを選んでください。';

  @override
  String get syncErrorRemoteChanged => '同期中に Google Drive が変更されました。';

  @override
  String get syncErrorRemoteChangedHint =>
      'データは失われていません。最新の変更を取り込むため、もう一度同期してください。';

  @override
  String get syncErrorInvalidLocalData => 'このデバイスの一部のデータを同期できませんでした。';

  @override
  String get syncErrorInvalidLocalDataHint =>
      '曲またはセットリストを読み込めませんでした。インポートするか作り直してから、もう一度同期してください。';

  @override
  String get syncErrorNoAccountChange => '解決するアカウント変更はありません。';

  @override
  String get syncErrorNoAccountChangeHint => '続けるにはもう一度同期してください。';

  @override
  String get accountSyncWarningTitle => '同期しましたが、一部のファイルをスキップしました';

  @override
  String get accountSyncWarningBody =>
      '一部のファイルを使用できなかったため、そのまま残しました。それ以外は最新です。';

  @override
  String get accountSyncWarningTooLarge =>
      '同期するにはファイルが大きすぎたため、スキップしました。それ以外は最新です。';

  @override
  String get accountSyncWarningInvalid => 'ファイルを読み込めなかったため、スキップしました。それ以外は最新です。';

  @override
  String get accountNoticeSyncSkipped => '同期しました。一部のファイルをスキップしました。';

  @override
  String get settingsExportPdfTooLarge =>
      'この PDF は大きくなりすぎます。曲数を減らすか、テキストとして共有してください。';

  @override
  String get settingsTimingTooLarge => 'タイミングデータが大きすぎます（3 MB 超）。';

  @override
  String get settingsImportDuplicateSongId =>
      'このバックアップには同じ曲が重複しているため、何もインポートされませんでした。';

  @override
  String get setlistSaveConflict => 'セットリストが別の場所で変更されました。編集内容は別のコピーとして保存されました。';

  @override
  String get sectionVerse => 'ヴァース';

  @override
  String get sectionChorus => 'コーラス';

  @override
  String get sectionBridge => 'ブリッジ';

  @override
  String get sectionIntro => 'イントロ';

  @override
  String get sectionOutro => 'アウトロ';

  @override
  String get sectionPreChorus => 'プレコーラス';

  @override
  String get sectionPostChorus => 'ポストコーラス';

  @override
  String get sectionInstrumental => 'インスト';

  @override
  String get sectionInterlude => '間奏';

  @override
  String get sectionSolo => 'ソロ';

  @override
  String get sectionRefrain => 'リフレイン';

  @override
  String get sectionHook => 'フック';

  @override
  String get sectionBreakdown => 'ブレイクダウン';

  @override
  String get sectionCoda => 'コーダ';

  @override
  String get sectionTag => 'タグ';

  @override
  String get sectionEnding => 'エンディング';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 利用可能なバージョン',
      one: '1 利用可能なバージョン',
      zero: '0 利用可能なバージョン',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 利用できないバージョン',
      one: '1 利用できないバージョン',
      zero: '0 利用できないバージョン',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'セクションへ移動';

  @override
  String get searchVersionDetails => 'バージョンの詳細';

  @override
  String get searchSelectedRecording => '選択した録音';

  @override
  String get searchVersionDuration => 'バージョンの長さ';

  @override
  String get searchSourceOptions => 'ソースのオプション';

  @override
  String get actionUndo => '元に戻す';

  @override
  String setlistEntryRemoved(String song) {
    return '「$song」をセットリストから削除しました';
  }

  @override
  String get backupTitle => 'バックアップと復元';

  @override
  String get backupExport => 'バックアップをエクスポート';

  @override
  String get backupRestore => 'バックアップを復元';

  @override
  String get backupIncludePreferences => 'アプリの設定を含める';

  @override
  String get backupRestorePreferences => 'アプリの設定を復元';

  @override
  String get backupMerge => 'このライブラリに追加';

  @override
  String get backupMergeHint => 'ローカルの編集内容を保ったまま、このバックアップの曲とセットリストを追加します。';

  @override
  String get backupReplace => 'このライブラリを置き換える';

  @override
  String get backupReplaceHint => 'この端末のすべての曲とセットリストを、このバックアップの内容に置き換えます。';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return '曲: $songs · セットリスト: $setlists · 競合: $conflicts';
  }

  @override
  String get backupFailed => 'バックアップ操作を完了できませんでした。もう一度お試しください。';

  @override
  String get backupRestored => 'バックアップを復元しました。';

  @override
  String get backupLocalHint => 'ライブラリのコピーを保存します。アカウント認証情報や同意 Cookie は含まれません。';

  @override
  String get backupReplaceConfirm => '現在のライブラリを置き換えますか？この操作は元に戻せません。';

  @override
  String get searchCheckOperations => '操作';

  @override
  String get searchCheckCode => '結果コード';

  @override
  String get searchCheckQueued => 'このソースの確認を待っています。';

  @override
  String get searchCheckFetch => '歌詞を読み込む';

  @override
  String get searchCheckValidate => '曲の一致を確認';

  @override
  String get searchCheckCorroborate => '歌詞の一致を確認';

  @override
  String get searchCheckCompleted => '完了';

  @override
  String get searchCheckTimeout => 'ソースが時間内に応答しませんでした。';

  @override
  String get searchCheckBlocked => 'ソースがリクエストをブロックしました。';

  @override
  String get searchCheckRateLimited => 'ソースがリクエストを制限しています。後でもう一度お試しください。';

  @override
  String get searchCheckNetwork => 'ソースに接続できません。接続を確認してください。';

  @override
  String get searchCheckInvalid => 'ソースから読み取れない応答が返されました。';

  @override
  String get searchCheckNotConfigured => 'このビルドではこのソースが設定されていません。';

  @override
  String get searchCheckNoLyrics => '一致する歌詞が見つかりませんでした。';

  @override
  String get searchCheckFailed => 'この操作を完了できませんでした。';

  @override
  String get searchCheckNoHistory => 'この比較ではソース確認がまだ実行されていません。';

  @override
  String get searchVersionCredits => 'クレジット';

  @override
  String get searchVersionMediaLinks => '関連リンク';

  @override
  String get searchCheckCancelled => 'キャンセル済み';

  @override
  String get searchCheckAmbiguous => '複数の一致が見つかりました。このソースには、より具体的な録音情報が必要です。';

  @override
  String get searchCheckIdentity => 'このソースには録音または作品の識別子が必要です。';

  @override
  String get searchCheckExtraction => 'ソースから応答がありましたが、歌詞を抽出できませんでした。';

  @override
  String get searchCheckBusy => 'このソースは混み合っています。後でもう一度お試しください。';

  @override
  String get searchCheckSelection => 'このソースから特定の結果を選択してください。';

  @override
  String get playerChordsNone => 'なし';

  @override
  String get editorCustomValue => 'その他…';

  @override
  String get editorStandardTuning => '標準チューニング';

  @override
  String get editorExampleVerse => '[C]新しい日が [G]呼んでいる、\n[Am]光をたどって [F]家へ帰ろう。';

  @override
  String get editorExampleChorus => '[F]この歌を[C]一緒に歌おう、\n[G]メロディーに乗って [C]進もう。';

  @override
  String get editorExampleBridge => '[Am]もう一行、少しだけ [F]近くへ。';

  @override
  String get playerEstimatedKey => '推定キー';

  @override
  String get songsLibraryView => 'ライブラリ';

  @override
  String get settingsStartupView => '起動時の画面';

  @override
  String get settingsStartupViewHint => 'アプリを開いたときに表示する曲の画面を選択します。';

  @override
  String get settingsStartupLastView => '前回開いた画面';

  @override
  String get playerFullScreen => '全画面表示';

  @override
  String get playerExitFullScreen => '全画面表示を終了';

  @override
  String get playerExpandControls => '再生コントロールを表示';

  @override
  String get playerCollapseControls => '再生コントロールを非表示';

  @override
  String get settingsShowSections => 'セクション見出しを表示';

  @override
  String get settingsShowSectionsHint => '歌詞に、ヴァース、コーラスなど各セクションの見出しを表示します。';

  @override
  String get settingsShowPlayerControls => '再生コントロールを表示';

  @override
  String get settingsShowPlayerControlsHint =>
      'プレーヤーパネルをタップまたはスワイプして表示・非表示を切り替えることもできます。';
}
