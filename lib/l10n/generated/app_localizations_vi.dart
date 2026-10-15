// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Không gian yên bình để tìm, sắp xếp và hát các bài hát trong thư viện của bạn.';

  @override
  String get aboutMadeForSinging => 'Được tạo để cùng nhau ca hát';

  @override
  String appVersion(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navSongs => 'Bài hát';

  @override
  String get navSetlists => 'Danh sách';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get navSettingsCompact => 'Cài đặt';

  @override
  String get navSearch => 'Tìm kiếm';

  @override
  String get navBack => 'Quay lại';

  @override
  String get navClose => 'Đóng';

  @override
  String get navMore => 'Thao tác khác';

  @override
  String get actionCancel => 'Hủy';

  @override
  String get actionSave => 'Lưu';

  @override
  String get actionDone => 'Xong';

  @override
  String get actionEdit => 'Chỉnh sửa';

  @override
  String get actionDelete => 'Xóa';

  @override
  String get actionShare => 'Chia sẻ';

  @override
  String get actionPrint => 'In';

  @override
  String get actionCopy => 'Sao chép';

  @override
  String get actionClear => 'Xóa';

  @override
  String get actionRetry => 'Thử lại';

  @override
  String get actionRefresh => 'Làm mới';

  @override
  String get actionImport => 'Nhập';

  @override
  String get actionExport => 'Xuất';

  @override
  String get actionExpand => 'Mở rộng';

  @override
  String get actionCollapse => 'Thu gọn';

  @override
  String get actionAdd => 'Thêm';

  @override
  String get actionCreate => 'Tạo';

  @override
  String get actionRemove => 'Gỡ';

  @override
  String get actionDuplicate => 'Nhân bản';

  @override
  String get actionMoveUp => 'Di chuyển lên';

  @override
  String get actionMoveDown => 'Di chuyển xuống';

  @override
  String get actionPrevious => 'Trước';

  @override
  String get actionNext => 'Tiếp theo';

  @override
  String get searchHint => 'Tìm bài hát, nghệ sĩ hoặc lời bài hát';

  @override
  String get searchCatalogHint => 'Tìm bài hát hoặc nghệ sĩ';

  @override
  String get searchChangeSong => 'Đổi bài hát';

  @override
  String get searchSelectedPreview => 'Bản xem trước đã chọn';

  @override
  String get searchSubmit => 'Tìm kiếm';

  @override
  String get searchFilters => 'Tùy chọn tìm kiếm';

  @override
  String get searchFiltersShow => 'Hiện tùy chọn tìm kiếm';

  @override
  String get searchFiltersHide => 'Ẩn tùy chọn tìm kiếm';

  @override
  String get searchFilterArtist => 'Nghệ sĩ';

  @override
  String get searchFilterTitle => 'Tên bài hát';

  @override
  String get searchFilterLyrics => 'Lời bài hát';

  @override
  String get searchFilterChords => 'Có hợp âm';

  @override
  String get searchFilterTimed => 'Lời bài hát có thời gian';

  @override
  String get searchFilterLanguage => 'Ngôn ngữ';

  @override
  String get searchFilterAll => 'Bất kỳ';

  @override
  String get searchAutocompleteLabel => 'Gợi ý';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kết quả',
      one: '1 kết quả',
      zero: 'Không có kết quả',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Nhập bài hát, nghệ sĩ hoặc lời bài hát để tìm kiếm.';

  @override
  String get searchCatalogEmptyQuery =>
      'Nhập bài hát hoặc nghệ sĩ để tìm kiếm.';

  @override
  String get searchNoResults =>
      'Không tìm thấy bài hát. Hãy thử tìm kiếm khác.';

  @override
  String get searchLoading => 'Đang tìm bài hát…';

  @override
  String get searchError => 'Không thể hoàn tất tìm kiếm.';

  @override
  String get searchOnlineTab => 'Trực tuyến';

  @override
  String get searchRecentTab => 'Gần đây';

  @override
  String get searchFavoritesTab => 'Yêu thích';

  @override
  String get searchSuggested => 'Kết quả phù hợp được đề xuất';

  @override
  String get searchAlternatives => 'Kết quả phù hợp khác';

  @override
  String get searchCompare => 'So sánh các phiên bản';

  @override
  String get searchChooseVersion => 'Chọn phiên bản này';

  @override
  String get searchSongMatch => 'Bài hát phù hợp';

  @override
  String get searchRecordingMatch => 'Bản ghi âm phù hợp';

  @override
  String get searchMatchUnverified => 'Bản ghi âm chưa được xác minh';

  @override
  String get searchMatchExact => 'Bản ghi âm khớp chính xác';

  @override
  String get searchMatchPossible => 'Có thể phù hợp';

  @override
  String get searchAvailability => 'Tình trạng';

  @override
  String get searchLyricsAvailable => 'Có lời bài hát';

  @override
  String get searchLyricsUnavailable => 'Không có lời bài hát';

  @override
  String get searchChordsAvailable => 'Có hợp âm';

  @override
  String get searchChordsUnavailable => 'Không có hợp âm';

  @override
  String get searchTimingAvailable => 'Có dữ liệu thời gian';

  @override
  String get searchTimingUnavailable => 'Không có dữ liệu thời gian';

  @override
  String get searchDurationUnknown => 'Thời lượng không xác định';

  @override
  String searchRating(String rating) {
    return 'Đánh giá $rating';
  }

  @override
  String get searchSourceLabel => 'Nguồn';

  @override
  String get searchMetadata => 'Thông tin bài hát';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Nghệ sĩ';

  @override
  String get searchYear => 'Năm';

  @override
  String get searchLanguage => 'Ngôn ngữ';

  @override
  String get searchViewVersions => 'Xem các phiên bản';

  @override
  String get searchSaved => 'Đã lưu bài hát vào thư viện của bạn.';

  @override
  String get searchSaveOpenLyrics => 'Lưu và mở lời bài hát';

  @override
  String get searchOtherResults => 'Kết quả khác';

  @override
  String get searchSaveFailed => 'Không thể lưu bài hát này.';

  @override
  String get homeRecentSongs => 'Bài hát gần đây';

  @override
  String get homeRecentlyPlayed => 'Đã phát gần đây';

  @override
  String get homeFavorites => 'Yêu thích';

  @override
  String get homeHistory => 'Lịch sử';

  @override
  String get homeHistoryClear => 'Xóa lịch sử';

  @override
  String get homeHistoryCleared => 'Đã xóa lịch sử.';

  @override
  String get homeHistoryEmpty => 'Các bài hát bạn mở sẽ xuất hiện ở đây.';

  @override
  String get homeFavoritesEmpty =>
      'Bài hát và danh sách yêu thích sẽ xuất hiện ở đây.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã hiển thị $count mục',
      one: 'Đã hiển thị 1 mục',
      zero: 'Đã hiển thị 0 mục',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Bài hát và danh sách gần đây sẽ xuất hiện ở đây.';

  @override
  String get homeTimelineLabel => 'Dòng thời gian lịch sử';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Toàn bộ lịch sử';

  @override
  String get homeShowFavorites => 'Hiện mục yêu thích';

  @override
  String get homeShowRecent => 'Hiện mục gần đây';

  @override
  String get songsTitle => 'Bài hát';

  @override
  String get songsEmpty => 'Bài hát của bạn sẽ xuất hiện ở đây.';

  @override
  String get songsEmptySearch => 'Không có bài hát nào khớp với tìm kiếm.';

  @override
  String get songsAdd => 'Thêm bài hát';

  @override
  String get songsSortAlphabetical => 'Sắp xếp theo bảng chữ cái';

  @override
  String get songsAlphabetNavigation => 'Mục lục bài hát';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã mở $count lần',
      one: 'Đã mở một lần',
      zero: 'Chưa từng mở',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'Thêm vào mục yêu thích';

  @override
  String get songFavoriteRemove => 'Xóa khỏi mục yêu thích';

  @override
  String get songMenuLabel => 'Thao tác với bài hát';

  @override
  String get songInfo => 'Thông tin bài hát';

  @override
  String get setlistMenuLabel => 'Thao tác với danh sách';

  @override
  String get songAddToSetlist => 'Thêm vào danh sách';

  @override
  String get songCopyChordPro => 'Sao chép ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Xóa bài hát?';

  @override
  String get songDeleteConfirmMessage =>
      'Bài hát này sẽ bị xóa khỏi thư viện của bạn.';

  @override
  String get songDeleted => 'Đã xóa bài hát.';

  @override
  String get setlistsTitle => 'Danh sách bài hát';

  @override
  String get setlistsEmpty =>
      'Tạo danh sách cho buổi tập hoặc buổi biểu diễn tiếp theo.';

  @override
  String get setlistsEmptySearch => 'Không có danh sách nào khớp với tìm kiếm.';

  @override
  String get setlistCreate => 'Danh sách mới';

  @override
  String get setlistNameHint => 'Tên danh sách';

  @override
  String get setlistNotes => 'Ghi chú';

  @override
  String get setlistEntryOverride => 'Tông và capo riêng cho bài hát';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài hát',
      one: '1 bài hát',
      zero: 'Không có bài hát',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Ít nhất $duration';
  }

  @override
  String get setlistDurationUnknown => 'Thời lượng không xác định';

  @override
  String setlistActivity(String date) {
    return 'Hoạt động gần nhất $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Đã tạo $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Đã chỉnh sửa $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Phát lần cuối $date';
  }

  @override
  String get setlistSongsEmpty => 'Danh sách này chưa có bài hát.';

  @override
  String get setlistAddSongs => 'Thêm bài hát';

  @override
  String get setlistReorder => 'Sắp xếp lại bài hát';

  @override
  String setlistMoveSongUp(String song) {
    return 'Di chuyển $song lên trên';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Di chuyển $song xuống dưới';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Xóa $song khỏi danh sách';
  }

  @override
  String get setlistDuplicate => 'Nhân bản danh sách';

  @override
  String get setlistFavoriteAdd => 'Thêm danh sách vào mục yêu thích';

  @override
  String get setlistFavoriteRemove => 'Xóa danh sách khỏi mục yêu thích';

  @override
  String get setlistShare => 'Chia sẻ dưới dạng tệp danh sách';

  @override
  String get setlistSharePdf => 'Chia sẻ dưới dạng PDF';

  @override
  String get setlistPrint => 'In';

  @override
  String get setlistDeleteConfirmTitle => 'Xóa danh sách?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Danh sách sẽ bị xóa. Các bài hát trong thư viện vẫn được giữ lại.';

  @override
  String get setlistDeleted => 'Đã xóa danh sách.';

  @override
  String get readerTitle => 'Lời bài hát';

  @override
  String get readerNoLyrics => 'Chưa thêm lời bài hát.';

  @override
  String get readerShowChords => 'Hiện hợp âm';

  @override
  String get readerHideChords => 'Ẩn hợp âm';

  @override
  String get readerTranspose => 'Dịch tông hợp âm';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nửa cung',
      one: '1 nửa cung',
      zero: '0 nửa cung',
    );
    return 'Dịch tông $_temp0';
  }

  @override
  String get readerSaved => 'Đã lưu';

  @override
  String get readerEdit => 'Chỉnh sửa lời bài hát và thông tin';

  @override
  String get playerPlay => 'Bắt đầu cuộn lời bài hát';

  @override
  String get playerPause => 'Tạm dừng cuộn lời bài hát';

  @override
  String get playerResume => 'Tiếp tục cuộn lời bài hát';

  @override
  String get playerSeek => 'Vị trí phát';

  @override
  String playerElapsed(String time) {
    return 'Thời gian đã phát $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Thời gian còn lại $time';
  }

  @override
  String get playerTimingMode => 'Chế độ cuộn';

  @override
  String get playerTimedLyrics => 'Lời bài hát có thời gian';

  @override
  String get playerStartScroll => 'Bắt đầu tự cuộn';

  @override
  String get playerEstimatedPace => 'Tốc độ ước tính';

  @override
  String get playerScrollSpeed => 'Tốc độ cuộn';

  @override
  String playerEstimatedDuration(String time) {
    return 'Thời lượng ước tính: $time';
  }

  @override
  String get playerLyricsOnly => 'Cuộn lời bài hát · không có âm thanh';

  @override
  String get playerManualScroll => 'Cuộn thủ công';

  @override
  String get playerTimingStatusReady =>
      'Lời bài hát sẽ chạy theo dữ liệu thời gian hiện có.';

  @override
  String get playerTimingStatusEstimated =>
      'Tốc độ cuộn được ước tính dựa trên thời lượng bài hát.';

  @override
  String get playerTimingStatusManual => 'Tự cuộn lời bài hát.';

  @override
  String get playerTimingStatusUnavailable =>
      'Không thể cuộn theo thời gian cho bài hát này.';

  @override
  String get playerDurationUnknown =>
      'Thêm thời lượng bài hát để dùng chế độ cuộn ước tính.';

  @override
  String get playerProgressLabel => 'Tiến độ bài hát';

  @override
  String get playerCurrentSection => 'Đoạn hiện tại';

  @override
  String get playerPreviousSection => 'Đoạn trước';

  @override
  String get playerNextSection => 'Đoạn tiếp theo';

  @override
  String get playerPreviousSectionSong =>
      'Đoạn trước · nhấn giữ để chuyển đến bài trước trong danh sách';

  @override
  String get playerNextSectionSong =>
      'Đoạn tiếp theo · nhấn giữ để chuyển đến bài tiếp theo trong danh sách';

  @override
  String get playerPreviousSong => 'Bài hát trước';

  @override
  String get playerNextSong => 'Bài hát tiếp theo';

  @override
  String get editorTitle => 'Chỉnh sửa bài hát';

  @override
  String get editorTitleField => 'Tên bài hát';

  @override
  String get editorArtistField => 'Nghệ sĩ';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Lời bài hát';

  @override
  String get editorChordsField => 'Hợp âm';

  @override
  String get editorKeyField => 'Tông';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Cách lên dây';

  @override
  String get editorTempoField => 'Nhịp độ';

  @override
  String get editorDurationField => 'Thời lượng';

  @override
  String get editorTimeSignatureField => 'Nhịp';

  @override
  String get editorLanguageField => 'Ngôn ngữ';

  @override
  String get editorYearField => 'Năm';

  @override
  String get editorComposerField => 'Nhạc sĩ';

  @override
  String get editorLyricistField => 'Tác giả lời';

  @override
  String get editorCopyrightField => 'Bản quyền';

  @override
  String get editorLicenseField => 'Giấy phép';

  @override
  String get songInfoSources => 'Nguồn và ghi công';

  @override
  String get searchMatchSameSong => 'Cùng bài hát; chưa xác nhận bản ghi âm';

  @override
  String get searchMatchNeedsAgreement => 'Cần xác nhận lời trong bản nhạc';

  @override
  String get searchMatchDifferentLyrics => 'Lời bài hát khác với bài đã chọn';

  @override
  String get searchMatchCombinedSources =>
      'Thông tin được tổng hợp từ nhiều nguồn';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tổng hợp từ $count nguồn',
      one: 'Tổng hợp từ 1 nguồn',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài hát phù hợp',
      one: '1 bài hát phù hợp',
      zero: '0 bài hát phù hợp',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phiên bản nguồn',
      one: '1 phiên bản nguồn',
      zero: '0 phiên bản nguồn',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Kết quả phù hợp nhất hiện có';

  @override
  String get providerDescriptionUnknown => 'Nguồn bài hát';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Tải tệp ChordPro từ nguồn, sau đó nhập tệp.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Tải tệp bằng tài khoản miễn phí, sau đó nhập tệp.';

  @override
  String get providerDescPublicChordSheets => 'Bản nhạc hợp âm công khai.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Lời bài hát lịch sử được cấp phép theo từng tác phẩm.';

  @override
  String get providerDescLicensedCatalog =>
      'Danh mục lời bài hát được cấp phép.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Bài hát gốc theo giấy phép Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Lời bài hát được cấp phép theo từng bài.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Chỉ có thông tin về bản ghi âm và bản phát hành.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Chỉ có thông tin về tác phẩm.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Ảnh bìa chỉ dành cho bản ghi âm khớp chính xác.';

  @override
  String get providerCapabilityLyrics => 'Lời bài hát';

  @override
  String get providerCapabilityChords => 'Hợp âm';

  @override
  String get providerCapabilityTiming => 'Lời bài hát có thời gian';

  @override
  String get providerCapabilitySearch => 'Tìm kiếm';

  @override
  String get providerCapabilityMetadata => 'Thông tin bài hát';

  @override
  String get editorArtworkField => 'Liên kết ảnh bìa';

  @override
  String get editorLyricsHint =>
      'Chạm vào một dòng để chỉnh sửa lời bài hát hoặc hợp âm.';

  @override
  String get editorSave => 'Lưu thay đổi';

  @override
  String get editorSaved => 'Đã lưu thay đổi.';

  @override
  String get editorSaveFailed => 'Không thể lưu thay đổi.';

  @override
  String get editorSaveConflict =>
      'Bài hát đã được thay đổi ở nơi khác. Các chỉnh sửa của bạn đã được lưu thành bản sao riêng.';

  @override
  String get editorUnsavedTitle => 'Bỏ thay đổi?';

  @override
  String get editorUnsavedMessage => 'Các chỉnh sửa của bạn chưa được lưu.';

  @override
  String get editorFieldRequired => 'Nhập tên bài hát.';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get settingsTheme => 'Chủ đề';

  @override
  String get settingsThemeSystem => 'Dùng cài đặt thiết bị';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsColorPalette => 'Bảng màu';

  @override
  String get settingsFont => 'Phông chữ';

  @override
  String get settingsTextSize => 'Cỡ chữ';

  @override
  String get settingsLyricsPreview => 'Xem trước lời bài hát';

  @override
  String get settingsPlayer => 'Trình phát lời bài hát';

  @override
  String get settingsDefaultShowChords => 'Mặc định hiện hợp âm';

  @override
  String get settingsDefaultAutoscroll => 'Tự động bắt đầu cuộn lời bài hát';

  @override
  String get settingsDefaultTiming => 'Chế độ cuộn mặc định';

  @override
  String get settingsLanguage => 'Ngôn ngữ ứng dụng';

  @override
  String get settingsLanguageSystem => 'Dùng ngôn ngữ thiết bị';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Nguồn lời bài hát';

  @override
  String settingsSourceEnabled(String source) {
    return 'Bật nguồn $source';
  }

  @override
  String get settingsSourceRefresh => 'Làm mới danh sách nguồn';

  @override
  String get settingsSourcesUpdated => 'Đã cập nhật nguồn.';

  @override
  String get settingsSourcesUpdateFailed => 'Không thể làm mới nguồn.';

  @override
  String get settingsImport => 'Nhập bài hát';

  @override
  String get settingsImportChordPro => 'Nhập tệp ChordPro';

  @override
  String get settingsImportSetlist => 'Nhập tệp danh sách bài hát';

  @override
  String get settingsImportSuccess => 'Đã nhập xong.';

  @override
  String get settingsImportFailed => 'Không thể nhập tệp này.';

  @override
  String get settingsImportUnsupported => 'Không hỗ trợ loại tệp này.';

  @override
  String get settingsShareSong => 'Chia sẻ dưới dạng ChordPro';

  @override
  String get settingsSharePdf => 'Chia sẻ dưới dạng PDF';

  @override
  String get settingsCopySong => 'Sao chép vào bảng nhớ tạm';

  @override
  String get settingsPrintSong => 'Chỉ in bài hát';

  @override
  String get settingsPrintSetlist => 'In danh sách kèm lời bài hát';

  @override
  String get settingsExportFailed => 'Không thể chuẩn bị tệp.';

  @override
  String get settingsCopied => 'Đã sao chép vào bảng nhớ tạm.';

  @override
  String get settingsAbout => 'Giới thiệu';

  @override
  String get settingsPrivacy => 'Quyền riêng tư';

  @override
  String get settingsLegal => 'Pháp lý';

  @override
  String get settingsClearHistory => 'Xóa lịch sử';

  @override
  String get settingsClearHistoryConfirm => 'Xóa lịch sử bài hát và danh sách?';

  @override
  String get settingsHistoryCleared => 'Đã xóa lịch sử.';

  @override
  String get accountTitle => 'Tài khoản và đồng bộ hóa';

  @override
  String get accountUnavailable =>
      'Đồng bộ hóa yêu cầu bản dựng Singbook đã cấu hình đăng nhập Google. Bản dựng này chỉ lưu bài hát trên thiết bị này.';

  @override
  String get accountSyncNow => 'Đồng bộ hóa ngay';

  @override
  String get accountConnected =>
      'Đã kết nối. Chọn “Đồng bộ hóa ngay” để cập nhật bản sao lưu.';

  @override
  String get accountSignIn => 'Kết nối tài khoản';

  @override
  String get accountSignOut => 'Đăng xuất';

  @override
  String get accountChange => 'Đổi tài khoản';

  @override
  String get accountSignedOut => 'Chưa kết nối';

  @override
  String get accountSyncing => 'Đang đồng bộ hóa thư viện…';

  @override
  String get accountSynced => 'Đã đồng bộ hóa thư viện.';

  @override
  String get accountSyncFailed => 'Không thể đồng bộ hóa thư viện.';

  @override
  String get accessibilityFavorite => 'Yêu thích';

  @override
  String get accessibilityNotFavorite => 'Không yêu thích';

  @override
  String get accessibilitySearchField => 'Tìm bài hát';

  @override
  String get accessibilityClearSearch => 'Xóa nội dung tìm kiếm';

  @override
  String accessibilitySongMenu(String song) {
    return 'Thao tác cho $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Thao tác cho $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Mở rộng các bài hát trong $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Thu gọn các bài hát trong $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Tiến độ phát, $percent phần trăm';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Dòng thời gian lịch sử, $date';
  }

  @override
  String get loading => 'Đang tải…';

  @override
  String get loadingSongs => 'Đang tải bài hát…';

  @override
  String get loadingSetlists => 'Đang tải danh sách…';

  @override
  String get errorGeneric => 'Đã xảy ra lỗi.';

  @override
  String get errorOffline => 'Có vẻ như bạn đang ngoại tuyến.';

  @override
  String get errorPermission => 'Cần có quyền để tiếp tục.';

  @override
  String get emptyFiltered => 'Không có mục nào khớp với các bộ lọc này.';

  @override
  String get unknownValue => 'Không xác định';

  @override
  String get durationUnknown => 'Thời lượng không xác định';

  @override
  String get metadataNotSet => 'Chưa đặt';

  @override
  String get dateToday => 'Hôm nay';

  @override
  String get dateYesterday => 'Hôm qua';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài hát',
      one: '1 bài hát',
      zero: 'Không có bài hát',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Xanh navy';

  @override
  String get settingsPaletteSage => 'Xanh xô thơm';

  @override
  String get settingsPaletteOcean => 'Đại dương';

  @override
  String get settingsPaletteClay => 'Đất sét';

  @override
  String get settingsPalettePlum => 'Mận';

  @override
  String get settingsFontSystem => 'Hệ thống';

  @override
  String get settingsFontSerif => 'Có chân';

  @override
  String get settingsFontMonospace => 'Đơn cách';

  @override
  String get settingsLyricsPreviewExample =>
      'Khi bình minh lên, chúng ta sẽ lại hát.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Đang kiểm tra nguồn lời bài hát: hoàn tất $checked/$total.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Không tìm thấy lời bài hát có thể sử dụng.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Bài hát đã chọn được kiểm tra với các nguồn đang bật, nhưng không nguồn nào trả về phiên bản lời bài hát có thể sử dụng.';

  @override
  String get searchDiscoveryError =>
      'Không thể kiểm tra các nguồn lời bài hát.';

  @override
  String get searchDiscoveryRetry => 'Tìm lời bài hát lại';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nguồn không khả dụng',
      one: '1 nguồn không khả dụng',
      zero: '0 nguồn không khả dụng',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Kiểm tra kết nối rồi thử lại.';

  @override
  String get searchProviderChecks => 'Kiểm tra nguồn';

  @override
  String get searchProviderPending => 'Đang kiểm tra';

  @override
  String get searchProviderFound => 'Đã tìm thấy kết quả phù hợp';

  @override
  String get searchProviderRejected => 'Không khớp';

  @override
  String get searchProviderFailed => 'Kiểm tra thất bại';

  @override
  String get searchProviderUnavailable => 'Không có lời bài hát khả dụng';

  @override
  String get searchCatalogFilterHint =>
      'Chọn bài hát để lọc phiên bản lời theo hợp âm, thời gian hoặc ngôn ngữ.';

  @override
  String get startupErrorTitle => 'Không thể mở thư viện của bạn.';

  @override
  String setlistCopyName(String name) {
    return 'Bản sao của $name';
  }

  @override
  String get setlistSongMissing => 'Thiếu bài hát';

  @override
  String get settingsImportTooLarge => 'Tệp này quá lớn để nhập.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Chuyển đến $letter';
  }

  @override
  String get actionDiscard => 'Bỏ';

  @override
  String get editorKeepEditing => 'Tiếp tục chỉnh sửa';

  @override
  String get settingsDefaultShowChordsHint =>
      'Hiện hợp âm phía trên lời bài hát nếu có.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Lời bài hát cuộn theo bài hát. Không dùng trong chế độ cuộn thủ công.';

  @override
  String get accountUnavailableTitle => 'Chưa thiết lập đồng bộ hóa';

  @override
  String get accountSignedOutBenefits =>
      'Đăng nhập bằng Google để sao lưu bài hát và danh sách lên Google Drive, đồng thời đồng bộ hóa tất cả thiết bị. Dù thế nào, bài hát vẫn được lưu trên thiết bị này.';

  @override
  String get accountSignInWithGoogle => 'Đăng nhập bằng Google';

  @override
  String get accountWorking => 'Đang xử lý…';

  @override
  String get accountNeverSynced => 'Chưa từng đồng bộ hóa';

  @override
  String get accountSyncedJustNow => 'Vừa đồng bộ hóa';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã đồng bộ hóa $count phút trước',
      one: 'Đã đồng bộ hóa 1 phút trước',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã đồng bộ hóa $count giờ trước',
      one: 'Đã đồng bộ hóa 1 giờ trước',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã đồng bộ hóa $count ngày trước',
      one: 'Đã đồng bộ hóa 1 ngày trước',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã giữ $count chỉnh sửa xung đột dưới dạng bản sao',
      one: 'Đã giữ 1 chỉnh sửa xung đột dưới dạng bản sao',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Cùng một bài hát hoặc danh sách đã được chỉnh sửa ở hai nơi. Không có gì bị mất: phiên bản còn lại đã được lưu thành bản sao riêng.';

  @override
  String get accountReviewConflicts => 'Xem lại các bản sao';

  @override
  String get songsConflictFilterActive => 'Chỉ hiển thị các bản sao xung đột';

  @override
  String get songsConflictFilterClear => 'Hiện tất cả bài hát';

  @override
  String get songsConflictBadge => 'Bản sao xung đột';

  @override
  String get songsConflictEmpty => 'Không có bản sao xung đột.';

  @override
  String get accountAutoSync => 'Tự động đồng bộ hóa';

  @override
  String get accountAutoSyncHint =>
      'Luôn cập nhật thư viện khi bạn mở ứng dụng và sau khi có thay đổi.';

  @override
  String get accountSignOutTitle => 'Đăng xuất khỏi tài khoản này?';

  @override
  String get accountSignOutBody =>
      'Bài hát và danh sách vẫn trên thiết bị này. Chúng sẽ không được sao lưu hoặc đồng bộ hóa cho đến khi bạn đăng nhập lại.';

  @override
  String get accountUseDifferent => 'Dùng tài khoản khác';

  @override
  String get accountSignInAgain => 'Đăng nhập lại';

  @override
  String get accountChooseAction => 'Chọn cách tiếp tục';

  @override
  String get accountChangedTitle => 'Tài khoản Google khác';

  @override
  String get accountChangedBody =>
      'Lần đồng bộ gần nhất của thiết bị này dùng một tài khoản Google khác. Chọn cách xử lý bài hát và danh sách trên thiết bị.';

  @override
  String get accountChangedMerge => 'Hợp nhất vào tài khoản mới';

  @override
  String get accountChangedMergeHint =>
      'Giữ mọi thứ trên thiết bị này và thêm vào tài khoản mới.';

  @override
  String get accountChangedReplace => 'Thay bằng thư viện của tài khoản mới';

  @override
  String get accountChangedReplaceHint =>
      'Các bài hát trên thiết bị này không có trong tài khoản mới sẽ bị xóa.';

  @override
  String get accountChangedSignOut => 'Hủy và đăng xuất';

  @override
  String get accountStatusSignedOut =>
      'Tài khoản và đồng bộ hóa: chưa đăng nhập';

  @override
  String get accountStatusSignedIn => 'Tài khoản và đồng bộ hóa: đã đăng nhập';

  @override
  String get accountStatusSyncing => 'Tài khoản và đồng bộ hóa: đang đồng bộ';

  @override
  String get accountStatusSynced =>
      'Tài khoản và đồng bộ hóa: thư viện đã cập nhật';

  @override
  String get accountStatusError =>
      'Tài khoản và đồng bộ hóa: có sự cố, chạm để xem';

  @override
  String get accountNoticeConflicts =>
      'Một số bài hát được chỉnh sửa ở hai nơi. Đã giữ lại các bản sao.';

  @override
  String get accountNoticeSignedIn => 'Đã đăng nhập.';

  @override
  String get accountNoticeSignedOut =>
      'Đã đăng xuất. Bài hát vẫn trên thiết bị này.';

  @override
  String get syncErrorNotConfigured =>
      'Bản dựng này chưa thiết lập đồng bộ hóa.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Dùng bản dựng Singbook đã cấu hình đăng nhập Google.';

  @override
  String get syncErrorNotSignedIn => 'Bạn chưa đăng nhập.';

  @override
  String get syncErrorNotSignedInHint => 'Đăng nhập để đồng bộ hóa thư viện.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google yêu cầu bạn đăng nhập lại.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Đăng nhập lại để tiếp tục đồng bộ hóa. Bài hát vẫn an toàn trên thiết bị này.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook không có quyền sử dụng Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Đăng nhập lại và cho phép truy cập Drive khi được hỏi.';

  @override
  String get syncErrorRateLimited =>
      'Google đang giới hạn yêu cầu trong lúc này.';

  @override
  String get syncErrorRateLimitedHint => 'Đợi vài phút rồi thử lại.';

  @override
  String get syncErrorStorageFull => 'Google Drive của bạn đã đầy.';

  @override
  String get syncErrorStorageFullHint =>
      'Giải phóng dung lượng Drive rồi thử lại.';

  @override
  String get syncErrorNetwork => 'Không thể kết nối với Google.';

  @override
  String get syncErrorNetworkHint => 'Kiểm tra kết nối Internet rồi thử lại.';

  @override
  String get syncErrorAccountChanged => 'Đã sử dụng một tài khoản Google khác.';

  @override
  String get syncErrorAccountChangedHint =>
      'Chọn hợp nhất thư viện trên thiết bị này vào tài khoản đó hay thay thế thư viện.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Thư viện đã đồng bộ quá lớn để Singbook xử lý.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Xóa một số bài hát hoặc danh sách khỏi thư viện đã đồng bộ rồi thử lại.';

  @override
  String get syncErrorSignInFailed => 'Chưa hoàn tất đăng nhập.';

  @override
  String get syncErrorSignInFailedHint => 'Thử đăng nhập lại.';

  @override
  String get syncErrorGeneric => 'Không thể đồng bộ hóa thư viện.';

  @override
  String get syncErrorGenericHint =>
      'Hãy thử lại sau. Bài hát vẫn an toàn trên thiết bị này.';

  @override
  String get editorDurationInvalid =>
      'Nhập số giây, hoặc phút và giây, ví dụ 3:45.';

  @override
  String get editorNumberInvalid => 'Nhập một số.';

  @override
  String get accountReplaceConfirmTitle => 'Xóa các bài hát trên thiết bị?';

  @override
  String get accountReplaceConfirmBody =>
      'Các bài hát và danh sách trên thiết bị này không có trong tài khoản mới sẽ bị xóa vĩnh viễn. Không thể hoàn tác.';

  @override
  String get accountReplaceConfirmAction => 'Xóa và thay thế';

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
  String get sectionVerse => 'Đoạn';

  @override
  String get sectionChorus => 'Điệp khúc';

  @override
  String get sectionBridge => 'Đoạn chuyển';

  @override
  String get sectionIntro => 'Dạo đầu';

  @override
  String get sectionOutro => 'Kết';

  @override
  String get sectionPreChorus => 'Tiền điệp khúc';

  @override
  String get sectionPostChorus => 'Hậu điệp khúc';

  @override
  String get sectionInstrumental => 'Đoạn nhạc';

  @override
  String get sectionInterlude => 'Dạo giữa';

  @override
  String get sectionSolo => 'Độc tấu';

  @override
  String get sectionRefrain => 'Điệp khúc lặp';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Kết thúc';
}
