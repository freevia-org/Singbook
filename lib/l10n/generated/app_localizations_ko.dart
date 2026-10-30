// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      '가사, 코드, 세트리스트를 한곳에 모아 리허설과 무대, 어디서든 바로 사용할 수 있습니다.';

  @override
  String get aboutMadeForSinging => '모든 곡을 바로 노래하세요.';

  @override
  String get aboutDetails =>
      '검색 가능한 소스를 찾아 가사, 코드, 타이밍, 녹음 정보를 비교한 뒤 연주할 버전을 저장하세요. 이용 가능 여부는 곡과 서비스에 따라 다릅니다.';

  @override
  String get aboutFindTitle => '원하는 버전 찾기';

  @override
  String get aboutKeepTitle => '나만의 라이브러리 만들기';

  @override
  String get aboutKeepDetails =>
      '곡을 편집하고 조옮김해 로컬 라이브러리에 보관하면 오프라인에서도 사용할 수 있고, 휴대용 ChordPro 파일로 공유할 수도 있습니다. Google Drive 동기화는 선택 사항이며 Google 계정의 비공개 앱 폴더를 사용합니다. ‘지금 동기화’를 눌러 기기를 업데이트할 수도 있습니다.';

  @override
  String get aboutPlayTitle => '세트리스트를 무대로 가져가기';

  @override
  String get aboutPlayDetails =>
      '곡을 세트리스트로 정렬하고 곡마다 조를 선택하며 OpenSong 세트리스트를 공유하세요. 리더 글자 크기를 조정하고 가사를 자동 스크롤하거나 곡 PDF를 인쇄할 수 있습니다. Singbook은 오디오를 스트리밍하거나 재생하지 않습니다.';

  @override
  String get aboutPrivacyTitle => '무료이며 로컬을 우선합니다';

  @override
  String get aboutPrivacyDetails =>
      'Singbook은 광고, 분석, 인앱 구매 없이 무료입니다. 저장한 라이브러리는 기기에 보관되며 선택적 동기화에는 본인의 Google Drive를 사용합니다. 온라인 결과는 독립적인 제3자 서비스에서 직접 제공되며 곡과 서비스에 따라 이용할 수 없거나 저작권으로 보호될 수 있습니다. Singbook은 해당 콘텐츠를 호스팅하지 않습니다.';

  @override
  String get aboutWebsite => 'Singbook 웹사이트';

  @override
  String get aboutSourceCode => 'GitHub의 소스 코드';

  @override
  String get aboutPublisher => 'Freevia 제공';

  @override
  String aboutLanguages(int count) {
    return '앱 언어: $count';
  }

  @override
  String get aboutSupport => '지원 및 의견 보내기';

  @override
  String get menuTypeNewSong => '새 노래 입력';

  @override
  String appVersion(String version) {
    return '버전 $version';
  }

  @override
  String get navHome => '홈';

  @override
  String get navSongs => '노래';

  @override
  String get navSetlists => '세트리스트';

  @override
  String get navSettings => '설정';

  @override
  String get navSettingsCompact => '설정';

  @override
  String get navSearch => '검색';

  @override
  String get navBack => '뒤로';

  @override
  String get appExitBackAgain => '종료하려면 뒤로를 한 번 더 누르세요';

  @override
  String get navClose => '닫기';

  @override
  String get navMore => '추가 작업';

  @override
  String get actionCancel => '취소';

  @override
  String get actionSave => '저장';

  @override
  String get actionDone => '완료';

  @override
  String get actionEdit => '수정';

  @override
  String get actionDelete => '삭제';

  @override
  String get actionShare => '공유';

  @override
  String get actionPrint => '인쇄';

  @override
  String get actionCopy => '복사';

  @override
  String get actionClear => '지우기';

  @override
  String get actionRetry => '다시 시도';

  @override
  String get actionRefresh => '새로고침';

  @override
  String get actionImport => '가져오기';

  @override
  String get actionExport => '내보내기';

  @override
  String get actionExpand => '펼치기';

  @override
  String get actionCollapse => '접기';

  @override
  String get actionAdd => '추가';

  @override
  String get actionCreate => '만들기';

  @override
  String get actionRemove => '제거';

  @override
  String get actionDuplicate => '복제';

  @override
  String get actionMoveUp => '위로 이동';

  @override
  String get actionMoveDown => '아래로 이동';

  @override
  String get actionPrevious => '이전';

  @override
  String get actionNext => '다음';

  @override
  String get searchHint => '노래, 아티스트 또는 가사 검색';

  @override
  String get searchCatalogHint => '노래 또는 아티스트 검색';

  @override
  String get searchChangeSong => '곡 변경';

  @override
  String get searchSelectedPreview => '선택한 미리보기';

  @override
  String get searchSubmit => '검색';

  @override
  String get searchFilters => '검색 옵션';

  @override
  String get searchFiltersShow => '검색 옵션 표시';

  @override
  String get searchFiltersHide => '검색 옵션 숨기기';

  @override
  String get searchFilterArtist => '아티스트';

  @override
  String get searchFilterTitle => '노래 제목';

  @override
  String get searchFilterLyrics => '가사';

  @override
  String get searchFilterChords => '코드 있음';

  @override
  String get searchFilterTimed => '타이밍이 적용된 가사';

  @override
  String get searchFilterLanguage => '언어';

  @override
  String get searchFilterAll => '모두';

  @override
  String get searchAutocompleteLabel => '추천';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '결과 $count개',
      one: '결과 1개',
      zero: '결과 없음',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery => '검색할 노래, 아티스트 또는 가사를 입력하세요.';

  @override
  String get searchCatalogEmptyQuery => '검색할 노래 또는 아티스트를 입력하세요.';

  @override
  String get searchNoResults => '노래를 찾을 수 없습니다. 다른 검색어를 입력해 보세요.';

  @override
  String get searchLoading => '노래 검색 중…';

  @override
  String get searchError => '검색을 완료할 수 없습니다.';

  @override
  String get searchOnlineTab => '온라인';

  @override
  String get searchRecentTab => '최근';

  @override
  String get searchFavoritesTab => '즐겨찾기';

  @override
  String get searchSuggested => '추천 일치 항목';

  @override
  String get searchAlternatives => '다른 일치 항목';

  @override
  String get searchCompare => '버전 비교';

  @override
  String get searchChooseVersion => '이 버전 선택';

  @override
  String get searchFullPreview => '전체 미리보기';

  @override
  String get searchArrangementNotes => '편곡 메모';

  @override
  String get searchOpenLyrics => '가사 열기';

  @override
  String get searchContributions => '사용된 출처';

  @override
  String get searchVersionChecking => '이 버전 확인 중…';

  @override
  String get searchVersionUnavailable => '이 버전은 사용할 수 없습니다. 다른 버전을 선택하세요.';

  @override
  String get searchPreviewUnavailable => '가사 미리보기를 사용할 수 없습니다.';

  @override
  String get searchSongMatch => '노래 일치';

  @override
  String get searchRecordingMatch => '녹음 일치';

  @override
  String get searchMatchUnverified => '녹음이 확인되지 않음';

  @override
  String get searchMatchExact => '녹음이 정확히 일치';

  @override
  String get searchMatchPossible => '일치 가능성 있음';

  @override
  String get searchAvailability => '사용 가능 여부';

  @override
  String get searchLyricsAvailable => '가사 사용 가능';

  @override
  String get searchLyricsUnavailable => '가사 사용 불가';

  @override
  String get searchChordsAvailable => '코드 사용 가능';

  @override
  String get searchChordsUnavailable => '코드 없음';

  @override
  String get searchTimingAvailable => '타이밍 사용 가능';

  @override
  String get searchTimingUnavailable => '타이밍 없음';

  @override
  String get searchDurationUnknown => '길이 알 수 없음';

  @override
  String searchRating(String rating) {
    return '평점 $rating';
  }

  @override
  String get searchSourceLabel => '출처';

  @override
  String get searchPreferredSourceLabel => '우선 출처';

  @override
  String get searchPreferredSourceHint => '결과는 사용 설정된 다른 검색 소스에서도 제공될 수 있습니다.';

  @override
  String get searchMetadata => '노래 세부정보';

  @override
  String get searchAlbum => '앨범';

  @override
  String get searchArtist => '아티스트';

  @override
  String get searchYear => '연도';

  @override
  String get searchLanguage => '언어';

  @override
  String get searchViewVersions => '버전 보기';

  @override
  String get searchSaved => '노래를 라이브러리에 저장했습니다.';

  @override
  String get searchSaveOpenLyrics => '가사 저장 후 열기';

  @override
  String get searchOtherResults => '기타 결과';

  @override
  String get searchSaveFailed => '노래를 저장할 수 없습니다.';

  @override
  String get homeRecentSongs => '최근 노래';

  @override
  String get homeRecentlyPlayed => '최근 재생';

  @override
  String get homeFavorites => '즐겨찾기';

  @override
  String get homeHistory => '기록';

  @override
  String get homeHistoryClear => '기록 지우기';

  @override
  String get homeHistoryCleared => '기록을 지웠습니다.';

  @override
  String get homeHistoryEmpty => '열어 본 노래가 여기에 표시됩니다.';

  @override
  String get homeFavoritesEmpty => '즐겨찾는 노래와 세트리스트가 여기에 표시됩니다.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '항목 $count개 표시',
      one: '항목 1개 표시',
      zero: '항목 0개 표시',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty => '최근 노래와 세트리스트가 여기에 표시됩니다.';

  @override
  String get homeTimelineLabel => '기록 타임라인';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => '전체 기록';

  @override
  String get homeShowFavorites => '즐겨찾기 표시';

  @override
  String get homeShowRecent => '최근 항목 표시';

  @override
  String get songsTitle => '노래';

  @override
  String get songsEmpty => '노래가 여기에 표시됩니다.';

  @override
  String get songsEmptySearch => '검색과 일치하는 노래가 없습니다.';

  @override
  String get songsAdd => '노래 추가';

  @override
  String get songsSortAlphabetical => '가나다순 정렬';

  @override
  String get songsAlphabetNavigation => '노래 색인';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count회',
      one: '1회',
      zero: '0회',
    );
    return '열린 횟수: $_temp0';
  }

  @override
  String get songFavoriteAdd => '즐겨찾기에 추가';

  @override
  String get songFavoriteRemove => '즐겨찾기에서 제거';

  @override
  String get songMenuLabel => '노래 작업';

  @override
  String get songInfo => '노래 세부정보';

  @override
  String get setlistMenuLabel => '세트리스트 작업';

  @override
  String get songAddToSetlist => '세트리스트에 추가';

  @override
  String get songCopyChordPro => 'ChordPro 복사';

  @override
  String get songDeleteConfirmTitle => '노래를 삭제할까요?';

  @override
  String get songDeleteConfirmMessage => '이 노래가 라이브러리에서 제거됩니다.';

  @override
  String get songDeleted => '노래를 삭제했습니다.';

  @override
  String get setlistsTitle => '세트리스트';

  @override
  String get setlistsEmpty => '다음 리허설이나 공연을 위한 세트리스트를 만들어 보세요.';

  @override
  String get setlistsEmptySearch => '검색과 일치하는 세트리스트가 없습니다.';

  @override
  String get setlistCreate => '새 세트리스트';

  @override
  String get setlistNameHint => '세트리스트 이름';

  @override
  String get setlistNotes => '메모';

  @override
  String get setlistEntryOverride => '노래별 키와 카포';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '노래 $count곡',
      one: '노래 1곡',
      zero: '노래 없음',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return '최소 $duration';
  }

  @override
  String get setlistDurationUnknown => '길이 알 수 없음';

  @override
  String setlistActivity(String date) {
    return '마지막 활동 $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return '만든 날짜 $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return '수정한 날짜 $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return '마지막 재생 $date';
  }

  @override
  String get setlistSongsEmpty => '이 세트리스트에는 아직 노래가 없습니다.';

  @override
  String get setlistAddSongs => '노래 추가';

  @override
  String get setlistReorder => '노래 순서 변경';

  @override
  String setlistMoveSongUp(String song) {
    return '“$song” 위로 이동';
  }

  @override
  String setlistMoveSongDown(String song) {
    return '“$song” 아래로 이동';
  }

  @override
  String setlistRemoveSong(String song) {
    return '세트리스트에서 “$song” 제거';
  }

  @override
  String get setlistDuplicate => '세트리스트 복제';

  @override
  String get setlistFavoriteAdd => '세트리스트를 즐겨찾기에 추가';

  @override
  String get setlistFavoriteRemove => '세트리스트를 즐겨찾기에서 제거';

  @override
  String get setlistShare => 'OpenSong으로 공유';

  @override
  String get setlistSharePdf => 'PDF로 공유';

  @override
  String get setlistPrint => '인쇄';

  @override
  String get setlistDeleteConfirmTitle => '세트리스트를 삭제할까요?';

  @override
  String get setlistDeleteConfirmMessage =>
      '세트리스트가 제거됩니다. 라이브러리의 노래는 그대로 유지됩니다.';

  @override
  String get setlistDeleted => '세트리스트를 삭제했습니다.';

  @override
  String get readerTitle => '가사';

  @override
  String get readerNoLyrics => '아직 가사가 추가되지 않았습니다.';

  @override
  String get readerShowChords => '코드 표시';

  @override
  String get readerHideChords => '코드 숨기기';

  @override
  String get readerTranspose => '코드 조옮김';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 반음',
      one: '1 반음',
      zero: '0 반음',
    );
    return '$_temp0 단위로 조옮김';
  }

  @override
  String get readerSaved => '저장됨';

  @override
  String get readerEdit => '가사 및 세부정보 수정';

  @override
  String get playerPlay => '재생';

  @override
  String get playerPause => '일시정지';

  @override
  String get playerResume => '가사 스크롤 재개';

  @override
  String get playerSeek => '재생 위치';

  @override
  String playerElapsed(String time) {
    return '경과 시간 $time';
  }

  @override
  String playerRemaining(String time) {
    return '남은 시간 $time';
  }

  @override
  String get playerTimingMode => '스크롤 모드';

  @override
  String get playerTimedLyrics => '타이밍이 적용된 가사';

  @override
  String get playerStartScroll => '자동 스크롤 시작';

  @override
  String get playerEstimatedPace => '예상 속도';

  @override
  String get playerScrollSpeed => '스크롤 속도';

  @override
  String playerEstimatedDuration(String time) {
    return '예상 시간: $time';
  }

  @override
  String get playerLyricsOnly => '가사 스크롤 · 오디오 없음';

  @override
  String get playerManualScroll => '수동 스크롤';

  @override
  String get playerTimingStatusReady => '사용 가능한 타이밍에 맞춰 가사가 스크롤됩니다.';

  @override
  String get playerTimingStatusEstimated => '노래 길이를 기준으로 스크롤 속도를 예상합니다.';

  @override
  String get playerTimingStatusManual => '가사를 직접 스크롤하세요.';

  @override
  String get playerTimingStatusUnavailable => '이 노래는 타이밍 기반 스크롤을 사용할 수 없습니다.';

  @override
  String get playerDurationUnknown => '예상 스크롤을 사용하려면 노래 길이를 추가하세요.';

  @override
  String get playerProgressLabel => '노래 진행률';

  @override
  String get playerCurrentSection => '현재 구간';

  @override
  String get playerPreviousSection => '이전 구간';

  @override
  String get playerNextSection => '다음 구간';

  @override
  String get playerPreviousSectionSong => '이전 구간 · 길게 눌러 세트리스트의 이전 노래로 이동';

  @override
  String get playerNextSectionSong => '다음 구간 · 길게 눌러 세트리스트의 다음 노래로 이동';

  @override
  String get playerPreviousSong => '이전 곡';

  @override
  String get playerNextSong => '다음 곡';

  @override
  String get editorTitle => '노래 수정';

  @override
  String get editorTitleField => '노래 제목';

  @override
  String get editorArtistField => '아티스트';

  @override
  String get editorAlbumField => '앨범';

  @override
  String get editorLyricsField => '가사';

  @override
  String get editorChordsField => '코드';

  @override
  String get editorKeyField => '키';

  @override
  String get editorCapoField => '카포';

  @override
  String get editorTuningField => '튜닝';

  @override
  String get editorTempoField => '템포';

  @override
  String get editorDurationField => '길이';

  @override
  String get editorTimeSignatureField => '박자표';

  @override
  String get editorLanguageField => '언어';

  @override
  String get editorYearField => '연도';

  @override
  String get editorComposerField => '작곡가';

  @override
  String get editorLyricistField => '작사가';

  @override
  String get editorCopyrightField => '저작권';

  @override
  String get editorLicenseField => '라이선스';

  @override
  String get songInfoSources => '출처 및 크레딧';

  @override
  String get searchMatchSameSong => '같은 노래지만 녹음은 확인되지 않음';

  @override
  String get searchMatchNeedsAgreement => '코드 차트를 가사와 대조해 확인해야 합니다';

  @override
  String get searchMatchDifferentLyrics => '선택한 노래와 가사가 다릅니다';

  @override
  String get searchMatchCombinedSources => '여러 출처의 세부정보를 결합했습니다';

  @override
  String get searchCombinedLabel => '통합';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '노래 일치 $count개',
      one: '노래 일치 1개',
      zero: '노래 일치 0개',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '출처 버전 $count개',
      one: '출처 버전 1개',
      zero: '출처 버전 0개',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => '사용 가능한 최선의 일치 항목';

  @override
  String get providerDescriptionUnknown => '노래 출처';

  @override
  String get providerDescDownloadChordProThenImport =>
      '출처에서 ChordPro 파일을 다운로드한 다음 가져오세요.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      '무료 계정으로 파일을 다운로드한 다음 가져오세요.';

  @override
  String get providerDescPublicChordSheets => '공개 코드 차트.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      '역사적 가사는 작품별로 라이선스가 부여됩니다.';

  @override
  String get providerDescLicensedCatalog => '라이선스가 있는 가사 카탈로그.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Creative Commons BY 라이선스가 적용된 오리지널 노래.';

  @override
  String get providerDescPerSongLicense => '가사는 노래별로 라이선스가 부여됩니다.';

  @override
  String get providerDescRecordingMetadataOnly => '녹음 및 발매 정보만 제공됩니다.';

  @override
  String get providerDescCompositionMetadataOnly => '작곡 정보만 제공됩니다.';

  @override
  String get providerDescExactFileArtworkOnly =>
      '녹음이 정확히 일치하는 경우에만 아트워크를 사용할 수 있습니다.';

  @override
  String get providerCapabilityLyrics => '가사';

  @override
  String get providerCapabilityChords => '코드';

  @override
  String get providerCapabilityTiming => '타이밍이 적용된 가사';

  @override
  String get providerCapabilitySearch => '검색';

  @override
  String get providerCapabilityMetadata => '노래 세부정보';

  @override
  String get editorArtworkField => '아트워크 링크';

  @override
  String get editorLyricsHint => '코드는 [C] 대괄호 안에, 섹션 표시는 별도 줄에 입력하세요.';

  @override
  String get editorSave => '변경사항 저장';

  @override
  String get editorSaved => '변경사항을 저장했습니다.';

  @override
  String get editorSaveFailed => '변경사항을 저장할 수 없습니다.';

  @override
  String get editorSaveConflict => '다른 곳에서 노래가 변경되었습니다. 수정사항은 별도 복사본으로 저장했습니다.';

  @override
  String get editorUnsavedTitle => '변경사항을 버릴까요?';

  @override
  String get editorUnsavedMessage => '수정사항이 저장되지 않았습니다.';

  @override
  String get editorFieldRequired => '노래 제목을 입력하세요.';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsAppearance => '모양';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeSystem => '기기 설정 사용';

  @override
  String get settingsThemeLight => '밝게';

  @override
  String get settingsThemeDark => '어둡게';

  @override
  String get settingsColorPalette => '색상 팔레트';

  @override
  String get settingsFont => '글꼴';

  @override
  String get settingsTextSize => '텍스트 크기';

  @override
  String get settingsLyricsPreview => '가사 미리보기';

  @override
  String get settingsPlayer => '가사 플레이어';

  @override
  String get settingsLyricHighlight => '현재 가사 줄 강조';

  @override
  String get settingsHighlightBackgroundUnderline => '배경 + 밑줄';

  @override
  String get settingsHighlightBackground => '배경';

  @override
  String get settingsHighlightUnderline => '밑줄';

  @override
  String get settingsHighlightContrast => '대비되는 글자 색';

  @override
  String get settingsHighlightNone => '없음';

  @override
  String get settingsDefaultShowChords => '기본으로 코드 표시';

  @override
  String get settingsDefaultAutoscroll => '가사 자동 스크롤 시작';

  @override
  String get settingsDefaultTiming => '기본 스크롤 모드';

  @override
  String get settingsLanguage => '앱 언어';

  @override
  String get settingsLanguageSystem => '기기 언어 사용';

  @override
  String get settingsLanguageEnglish => '영어';

  @override
  String get settingsLanguageBulgarian => '불가리아어';

  @override
  String get settingsLanguageUkrainian => '우크라이나어';

  @override
  String get settingsSources => '가사 출처';

  @override
  String settingsSourceEnabled(String source) {
    return '출처 $source 사용';
  }

  @override
  String get settingsSourceRefresh => '출처 목록 새로고침';

  @override
  String get settingsSourcesUpdated => '출처를 업데이트했습니다.';

  @override
  String get settingsSourcesUpdateFailed => '출처를 새로고침할 수 없습니다.';

  @override
  String get settingsImport => '노래 가져오기';

  @override
  String get settingsImportChordPro => 'ChordPro 파일 가져오기';

  @override
  String get settingsImportSetlist => '세트리스트 파일 가져오기';

  @override
  String get settingsImportSuccess => '가져오기가 완료되었습니다.';

  @override
  String get settingsImportFailed => '이 파일을 가져올 수 없습니다.';

  @override
  String get settingsImportUnsupported => '지원되지 않는 파일 형식입니다.';

  @override
  String get settingsShareSong => 'ChordPro로 공유';

  @override
  String get settingsSharePdf => 'PDF로 공유';

  @override
  String get settingsCopySong => '클립보드에 복사';

  @override
  String get settingsPrintSong => '노래만 인쇄';

  @override
  String get settingsPrintSetlist => '가사가 포함된 세트리스트 인쇄';

  @override
  String get settingsExportFailed => '파일을 준비할 수 없습니다.';

  @override
  String get settingsCopied => '클립보드에 복사했습니다.';

  @override
  String get settingsAbout => '정보';

  @override
  String get settingsPrivacy => '개인정보 보호';

  @override
  String get settingsLegal => '법률 정보';

  @override
  String get settingsClearHistory => '기록 지우기';

  @override
  String get settingsClearHistoryConfirm =>
      '노래와 세트리스트의 최근 활동 기록을 지웁니다. 저장된 노래, 즐겨찾기, 세트리스트 및 설정은 유지됩니다.';

  @override
  String get settingsHistoryCleared => '기록을 지웠습니다.';

  @override
  String get accountTitle => '계정 및 동기화';

  @override
  String get accountICloudBenefits =>
      'Apple 계정으로 노래와 세트리스트를 iCloud에 비공개로 동기화하세요. 연결하면 변경 사항이 자동으로 동기화됩니다.';

  @override
  String get accountICloudUnavailable =>
      'iCloud를 사용할 수 없습니다. 시스템 설정에서 Apple 계정과 iCloud 접근 권한을 확인한 다음 다시 시도하세요.';

  @override
  String get accountConnectICloud => 'iCloud 연결';

  @override
  String get accountDisconnectICloud => 'iCloud 연결 해제';

  @override
  String get accountUnavailable =>
      '동기화하려면 Google 로그인이 설정된 Singbook 빌드가 필요합니다. 이 빌드에서는 노래가 이 기기에만 저장됩니다.';

  @override
  String get accountSyncNow => '지금 동기화';

  @override
  String get accountConnected => '연결되었습니다. 백업을 업데이트하려면 지금 동기화를 선택하세요.';

  @override
  String get accountSignIn => '계정 연결';

  @override
  String get accountSignOut => '로그아웃';

  @override
  String get accountChange => '계정 변경';

  @override
  String get accountSignedOut => '연결되지 않음';

  @override
  String get accountSyncing => '라이브러리 동기화 중…';

  @override
  String get accountSynced => '라이브러리를 동기화했습니다.';

  @override
  String get accountSyncFailed => '라이브러리를 동기화할 수 없습니다.';

  @override
  String get accessibilityFavorite => '즐겨찾기';

  @override
  String get accessibilityNotFavorite => '즐겨찾기가 아님';

  @override
  String get accessibilitySearchField => '노래 검색';

  @override
  String get accessibilityClearSearch => '검색어 지우기';

  @override
  String accessibilitySongMenu(String song) {
    return '$song 작업';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return '$setlist 작업';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return '$setlist의 노래 펼치기';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return '$setlist의 노래 접기';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return '재생 진행률, $percent퍼센트';
  }

  @override
  String accessibilityTimeline(String date) {
    return '기록 타임라인, $date';
  }

  @override
  String get loading => '불러오는 중…';

  @override
  String get loadingSongs => '노래 불러오는 중…';

  @override
  String get loadingSetlists => '세트리스트 불러오는 중…';

  @override
  String get errorGeneric => '문제가 발생했습니다.';

  @override
  String get errorOffline => '오프라인 상태인 것 같습니다.';

  @override
  String get errorPermission => '계속하려면 권한이 필요합니다.';

  @override
  String get emptyFiltered => '필터와 일치하는 항목이 없습니다.';

  @override
  String get unknownValue => '알 수 없음';

  @override
  String get durationUnknown => '길이 알 수 없음';

  @override
  String get metadataNotSet => '설정되지 않음';

  @override
  String get dateToday => '오늘';

  @override
  String get dateYesterday => '어제';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '노래 $count곡',
      one: '노래 1곡',
      zero: '노래 없음',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => '네이비';

  @override
  String get settingsPaletteSage => '세이지';

  @override
  String get settingsPaletteOcean => '오션';

  @override
  String get settingsPaletteClay => '클레이';

  @override
  String get settingsPalettePlum => '플럼';

  @override
  String get settingsFontSystem => '시스템';

  @override
  String get settingsFontSerif => '세리프';

  @override
  String get settingsFontMonospace => '고정폭';

  @override
  String get settingsLyricsPreviewExample => '아침이 오면 우리는 다시 노래할 거예요.';

  @override
  String get settingsPreviewSongTitle => '아침 노래';

  @override
  String get settingsPreviewArtist => '샘플 편곡';

  @override
  String get settingsPreviewCurrentLine => '아침이 오면';

  @override
  String get settingsPreviewNextLine => '우리는 다시 노래할 거예요.';

  @override
  String get settingsPlayerSections => '섹션 제목';

  @override
  String get settingsPlayerControls => '재생 패널';

  @override
  String get settingsPlayerAutoscroll => '자동 스크롤';

  @override
  String get settingsSystemShort => '기기';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return '가사 출처 확인 중: $total개 중 $checked개 완료.';
  }

  @override
  String get searchDiscoveryNoLyrics => '사용할 수 있는 가사를 찾지 못했습니다.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      '선택한 노래를 사용 설정된 출처에서 확인했지만 사용할 수 있는 가사 버전을 찾지 못했습니다.';

  @override
  String get searchDiscoveryError => '가사 출처를 확인할 수 없습니다.';

  @override
  String get searchDiscoveryRetry => '가사 다시 검색';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사용할 수 없는 출처 $count개',
      one: '사용할 수 없는 출처 1개',
      zero: '사용할 수 없는 출처 0개',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => '연결을 확인하고 다시 시도하세요.';

  @override
  String get searchProviderChecks => '출처 확인';

  @override
  String get searchProviderPending => '확인 중';

  @override
  String get searchProviderFound => '일치 항목을 찾았습니다';

  @override
  String get searchProviderRejected => '일치하지 않음';

  @override
  String get searchProviderFailed => '확인 실패';

  @override
  String get searchProviderUnavailable => '사용할 수 있는 가사 없음';

  @override
  String get searchCatalogFilterHint =>
      '노래를 선택하면 코드, 타이밍 또는 언어로 가사 버전을 필터링할 수 있습니다.';

  @override
  String get startupErrorTitle => '라이브러리를 열 수 없습니다.';

  @override
  String setlistCopyName(String name) {
    return '$name 복사본';
  }

  @override
  String get setlistSongMissing => '누락된 노래';

  @override
  String get settingsImportTooLarge => '이 파일은 가져오기에는 너무 큽니다.';

  @override
  String songsJumpToLetter(String letter) {
    return '$letter(으)로 이동';
  }

  @override
  String get actionDiscard => '버리기';

  @override
  String get editorKeepEditing => '계속 수정';

  @override
  String get settingsDefaultShowChordsHint => '노래에 코드가 있으면 가사 위에 표시합니다.';

  @override
  String get settingsDefaultAutoscrollHint =>
      '노래에 맞춰 가사가 스크롤됩니다. 수동 스크롤 모드에서는 사용되지 않습니다.';

  @override
  String get accountUnavailableTitle => '동기화가 설정되지 않음';

  @override
  String get accountSignedOutBenefits =>
      'Google Drive를 연결하면 라이브러리가 동기화됩니다. 이후 노래 변경 사항은 자동으로 동기화됩니다.';

  @override
  String get accountManualSyncHint => '라이브러리를 동기화하려면 지금 동기화를 탭할 수도 있습니다.';

  @override
  String get accountSignInWithGoogle => 'Google로 로그인';

  @override
  String get accountWorking => '작업 중…';

  @override
  String get accountNeverSynced => '동기화한 적 없음';

  @override
  String get accountSyncedJustNow => '방금 동기화됨';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분 전에 동기화됨',
      one: '1분 전에 동기화됨',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count시간 전에 동기화됨',
      one: '1시간 전에 동기화됨',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 전에 동기화됨',
      one: '1일 전에 동기화됨',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '충돌한 수정사항 $count개를 복사본으로 저장함',
      one: '충돌한 수정사항 1개를 복사본으로 저장함',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      '같은 노래나 세트리스트가 두 곳에서 수정되었습니다. 데이터는 손실되지 않았습니다. 다른 버전은 별도 복사본으로 저장되었습니다.';

  @override
  String get accountReviewConflicts => '복사본 검토';

  @override
  String get songsConflictFilterActive => '충돌 복사본만 표시 중';

  @override
  String get songsConflictFilterClear => '모든 노래 표시';

  @override
  String get songsConflictBadge => '충돌 복사본';

  @override
  String get songsConflictEmpty => '충돌 복사본이 없습니다.';

  @override
  String get accountAutoSync => '자동 동기화';

  @override
  String get accountAutoSyncHint => '연결한 후와 노래를 추가, 수정 또는 삭제한 후에 동기화합니다.';

  @override
  String get accountDriveFolder => 'Google 드라이브 라이브러리 폴더';

  @override
  String get accountPrivateDriveFolder => '개인 Singbook 폴더';

  @override
  String get accountChooseDriveFolder => '폴더 선택';

  @override
  String get accountDriveFolderMoveTitle => 'Singbook 라이브러리를 이동하시겠습니까?';

  @override
  String get accountDriveFolderMoveBody =>
      '표시되는 Google 드라이브 폴더를 선택하세요. Singbook은 전환하기 전에 노래와 세트리스트를 복사하고 확인합니다. 원본 파일은 백업으로 이전 위치에 유지됩니다. 다른 파일은 그대로 둡니다. 이 폴더로 가져온 ChordPro 파일은 Singbook 메타데이터를 동기화하고 수신하기 위해 채택됩니다.';

  @override
  String get accountImportChordPro => '드라이브에서 ChordPro 가져오기';

  @override
  String get accountImportChordProHint =>
      '이 라이브러리에 추가할 .cho 파일을 선택하세요. 폴더에 이미 있는 파일이 채택됩니다. 다른 곳에 있는 파일은 여기에 복사됩니다.';

  @override
  String get syncErrorFolderPickerUnavailable => '드라이브 폴더를 선택할 수 없습니다.';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      '지원되는 기기에서 Google 드라이브 선택기로 표시되는 Drive 폴더를 선택하세요.';

  @override
  String get syncErrorDriveFolderMissing => 'Singbook Drive 폴더를 사용할 수 없습니다.';

  @override
  String get syncErrorDriveFolderMissingHint =>
      '폴더를 다시 선택하거나 Google Drive에서 복원하세요.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook은 이 드라이브 폴더에 액세스해야 합니다.';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      '폴더를 다시 선택하여 액세스 권한을 부여한 다음 라이브러리를 동기화하세요.';

  @override
  String get syncErrorFolderMigration => '아직 라이브러리를 이동할 수 없습니다.';

  @override
  String get syncErrorFolderMigrationHint =>
      '이전 라이브러리는 여전히 안전합니다. 연결을 확인하고 폴더를 다시 선택하여 다시 시도하세요.';

  @override
  String get syncErrorVisibleFolderRequired => '먼저 표시되는 드라이브 폴더를 선택하세요.';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      '드라이브에서 파일을 가져오기 전에 표시되는 라이브러리 폴더가 필요합니다.';

  @override
  String get accountSignOutTitle => '이 계정에서 로그아웃할까요?';

  @override
  String get accountSignOutBody =>
      '노래와 세트리스트는 이 기기에 남습니다. 다시 로그인할 때까지 백업되거나 동기화되지 않습니다.';

  @override
  String get accountUseDifferent => '다른 계정 사용';

  @override
  String get accountSignInAgain => '다시 로그인';

  @override
  String get accountChooseAction => '계속할 방법 선택';

  @override
  String get accountChangedTitle => '다른 Google 계정';

  @override
  String get accountChangedBody =>
      '이 기기는 마지막으로 다른 Google 계정과 동기화되었습니다. 이 기기의 노래와 세트리스트를 어떻게 처리할지 선택하세요.';

  @override
  String get accountChangedMerge => '새 계정에 병합';

  @override
  String get accountChangedMergeHint => '이 기기의 모든 항목을 유지하고 새 계정에 추가합니다.';

  @override
  String get accountChangedReplace => '새 계정의 라이브러리로 교체';

  @override
  String get accountChangedReplaceHint => '새 계정에 없는 이 기기의 노래는 제거됩니다.';

  @override
  String get accountChangedSignOut => '취소하고 로그아웃';

  @override
  String get accountStatusSignedOut => '계정 및 동기화: 로그인되지 않음';

  @override
  String get accountStatusSignedIn => '계정 및 동기화: 로그인됨';

  @override
  String get accountStatusSyncing => '계정 및 동기화: 동기화 중';

  @override
  String get accountStatusSynced => '계정 및 동기화: 라이브러리가 최신 상태임';

  @override
  String get accountStatusError => '계정 및 동기화: 문제 발생, 탭하여 확인';

  @override
  String get accountNoticeConflicts => '일부 노래가 두 곳에서 수정되었습니다. 복사본을 보관했습니다.';

  @override
  String get accountNoticeSignedIn => '로그인했습니다.';

  @override
  String get accountNoticeSignedOut => '로그아웃했습니다. 노래는 이 기기에 남습니다.';

  @override
  String get syncErrorNotConfigured => '이 빌드에서는 동기화가 설정되지 않았습니다.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Google 로그인이 설정된 Singbook 빌드를 사용하세요.';

  @override
  String get syncErrorOAuthClientConfiguration =>
      'Google에서 이 빌드의 로그인 구성을 거부했습니다.';

  @override
  String get syncErrorOAuthClientConfigurationHint =>
      '설정된 OAuth ID가 Singbook 데스크톱 앱 클라이언트인지 확인하세요.';

  @override
  String get syncErrorNotSignedIn => '로그인되어 있지 않습니다.';

  @override
  String get syncErrorNotSignedInHint => '라이브러리를 동기화하려면 로그인하세요.';

  @override
  String get syncErrorAuthorizationRequired => 'Google에 다시 로그인해야 합니다.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      '동기화를 계속하려면 다시 로그인하세요. 노래는 이 기기에 안전하게 보관되어 있습니다.';

  @override
  String get syncErrorAccessDenied => 'Singbook에 Google Drive 사용 권한이 없습니다.';

  @override
  String get syncErrorAccessDeniedHint =>
      '다시 로그인하고 메시지가 표시되면 Drive 액세스를 허용하세요.';

  @override
  String get syncErrorRateLimited => 'Google이 현재 요청을 제한하고 있습니다.';

  @override
  String get syncErrorRateLimitedHint => '몇 분 기다린 후 다시 시도하세요.';

  @override
  String get syncErrorStorageFull => 'Google Drive 저장공간이 가득 찼습니다.';

  @override
  String get syncErrorStorageFullHint => 'Drive 공간을 확보한 다음 다시 시도하세요.';

  @override
  String get syncErrorNetwork => 'Google에 연결할 수 없습니다.';

  @override
  String get syncErrorNetworkHint => '인터넷 연결을 확인하고 다시 시도하세요.';

  @override
  String get syncErrorAccountChanged => '다른 Google 계정이 사용되었습니다.';

  @override
  String get syncErrorAccountChangedHint =>
      '이 기기의 라이브러리를 해당 계정에 병합할지 교체할지 선택하세요.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      '동기화된 라이브러리가 Singbook에서 처리하기에 너무 큽니다.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      '동기화된 라이브러리에서 노래나 세트리스트를 일부 제거한 다음 다시 시도하세요.';

  @override
  String get syncErrorSignInFailed => '로그인을 완료하지 못했습니다.';

  @override
  String get syncErrorSignInFailedHint => '다시 로그인해 보세요.';

  @override
  String get syncErrorGeneric => '라이브러리를 동기화할 수 없습니다.';

  @override
  String get syncErrorGenericHint => '잠시 후 다시 시도하세요. 노래는 이 기기에 안전하게 보관되어 있습니다.';

  @override
  String get editorDurationInvalid => '초 또는 분:초 형식으로 입력하세요(예: 3:45).';

  @override
  String get editorNumberInvalid => '숫자를 입력하세요.';

  @override
  String get accountReplaceConfirmTitle => '로컬 노래를 삭제할까요?';

  @override
  String get accountReplaceConfirmBody =>
      '이 기기에 있는 노래와 세트리스트 중 새 계정에 없는 항목은 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get accountReplaceConfirmAction => '삭제 후 교체';

  @override
  String get accountSuspiciousTitle => 'Google Drive에서 항목을 찾을 수 없음';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 항목이 Google Drive에서 사라졌습니다. 이 기기에서 이전에 동기화한 항목입니다.',
      one: '$count개 항목이 Google Drive에서 사라졌습니다. 이 기기에서 이전에 동기화한 항목입니다.',
    );
    return '$_temp0 Google 설정에서 앱 데이터를 삭제하면 이런 일이 발생할 수 있습니다. 아직 삭제된 항목은 없습니다.';
  }

  @override
  String get accountSuspiciousDelete => '이 기기에서도 삭제';

  @override
  String get accountSuspiciousKeep => '노래를 유지하고 다시 업로드';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이 기기에서 항목 $count개를 삭제할까요?',
      one: '이 기기에서 항목 $count개를 삭제할까요?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      '이 노래와 세트리스트는 이 기기에서 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get accountSuspiciousDeleteConfirmAction => '이 기기에서 삭제';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Google Drive에서 항목을 찾을 수 없습니다.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      '삭제된 항목은 없습니다. 이 기기에서도 삭제할지 다시 업로드할지 선택하세요.';

  @override
  String get syncErrorRemoteChanged => '동기화 중 Google Drive가 변경되었습니다.';

  @override
  String get syncErrorRemoteChangedHint =>
      '손실된 항목은 없습니다. 최신 변경사항을 가져오려면 다시 동기화하세요.';

  @override
  String get syncErrorInvalidLocalData => '이 기기의 일부 데이터를 동기화할 수 없습니다.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      '노래나 세트리스트를 읽을 수 없습니다. 가져오거나 다시 만든 다음 동기화하세요.';

  @override
  String get syncErrorNoAccountChange => '해결할 계정 변경이 없습니다.';

  @override
  String get syncErrorNoAccountChangeHint => '계속하려면 다시 동기화하세요.';

  @override
  String get accountSyncWarningTitle => '동기화 완료, 일부 파일 건너뜀';

  @override
  String get accountSyncWarningBody =>
      '일부 파일을 사용할 수 없어 그대로 두었습니다. 나머지는 최신 상태입니다.';

  @override
  String get accountSyncWarningTooLarge =>
      '파일이 너무 커서 동기화하지 않고 건너뛰었습니다. 나머지는 최신 상태입니다.';

  @override
  String get accountSyncWarningInvalid => '파일을 읽을 수 없어 건너뛰었습니다. 나머지는 최신 상태입니다.';

  @override
  String get accountNoticeSyncSkipped => '동기화 완료. 일부 파일을 건너뛰었습니다.';

  @override
  String get settingsExportPdfTooLarge =>
      '이 PDF는 너무 커집니다. 노래 수를 줄이거나 텍스트로 공유하세요.';

  @override
  String get settingsTimingTooLarge => '타이밍 데이터가 너무 큽니다(3MB 초과).';

  @override
  String get settingsImportDuplicateSongId =>
      '백업에 같은 노래가 두 번 있어 아무것도 가져오지 않았습니다.';

  @override
  String get setlistSaveConflict =>
      '세트리스트가 다른 곳에서 변경되었습니다. 수정사항은 별도 사본으로 저장되었습니다.';

  @override
  String get sectionVerse => '벌스';

  @override
  String get sectionChorus => '후렴';

  @override
  String get sectionBridge => '브리지';

  @override
  String get sectionIntro => '인트로';

  @override
  String get sectionOutro => '아웃트로';

  @override
  String get sectionPreChorus => '프리코러스';

  @override
  String get sectionPostChorus => '포스트코러스';

  @override
  String get sectionInstrumental => '연주';

  @override
  String get sectionInterlude => '간주';

  @override
  String get sectionSolo => '솔로';

  @override
  String get sectionRefrain => '리프레인';

  @override
  String get sectionHook => '훅';

  @override
  String get sectionBreakdown => '브레이크다운';

  @override
  String get sectionCoda => '코다';

  @override
  String get sectionTag => '태그';

  @override
  String get sectionEnding => '엔딩';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 사용 가능한 버전',
      one: '1 사용 가능한 버전',
      zero: '0 사용 가능한 버전',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 사용할 수 없는 버전',
      one: '1 사용할 수 없는 버전',
      zero: '0 사용할 수 없는 버전',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => '섹션으로 이동';

  @override
  String get searchVersionDetails => '버전 세부정보';

  @override
  String get searchSelectedRecording => '선택한 녹음';

  @override
  String get searchVersionDuration => '버전 길이';

  @override
  String get searchSourceOptions => '소스 옵션';

  @override
  String get actionUndo => '실행 취소';

  @override
  String setlistEntryRemoved(String song) {
    return '세트리스트에서 $song을(를) 삭제했습니다';
  }

  @override
  String get backupTitle => '백업 및 복원';

  @override
  String get backupExport => '백업 내보내기';

  @override
  String get backupSaveToDevice => '백업을 기기에 저장';

  @override
  String get backupRestore => '백업 복원';

  @override
  String get backupIncludePreferences => '앱 환경설정 포함';

  @override
  String get backupRestorePreferences => '앱 환경설정 복원';

  @override
  String get backupMerge => '이 라이브러리에 추가';

  @override
  String get backupMergeHint => '로컬 편집 내용을 유지하고 이 백업의 노래와 세트리스트를 추가합니다.';

  @override
  String get backupReplace => '이 라이브러리 교체';

  @override
  String get backupReplaceHint => '이 기기의 모든 노래와 세트리스트를 이 백업 내용으로 교체합니다.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return '노래: $songs · 세트리스트: $setlists · 충돌: $conflicts';
  }

  @override
  String get backupFailed => '백업 작업을 완료하지 못했습니다. 다시 시도하세요.';

  @override
  String get backupRestored => '백업을 복원했습니다.';

  @override
  String get backupLocalHint => '라이브러리 사본을 저장합니다. 계정 자격 증명과 동의 쿠키는 포함되지 않습니다.';

  @override
  String get backupReplaceConfirm => '현재 라이브러리를 교체할까요? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get searchCheckOperations => '작업';

  @override
  String get searchCheckCode => '결과 코드';

  @override
  String get searchCheckQueued => '이 소스를 확인하는 중입니다.';

  @override
  String get searchCheckFetch => '가사 불러오기';

  @override
  String get searchCheckValidate => '곡 일치 확인';

  @override
  String get searchCheckCorroborate => '가사 일치 확인';

  @override
  String get searchCheckCompleted => '완료';

  @override
  String get searchCheckTimeout => '소스가 제시간에 응답하지 않았습니다.';

  @override
  String get searchCheckBlocked => '소스가 요청을 차단했습니다.';

  @override
  String get searchCheckRateLimited => '소스에서 요청을 제한하고 있습니다. 나중에 다시 시도하세요.';

  @override
  String get searchCheckNetwork => '소스에 연결할 수 없습니다. 연결을 확인하세요.';

  @override
  String get searchCheckInvalid => '소스에서 읽을 수 없는 응답을 반환했습니다.';

  @override
  String get searchCheckNotConfigured => '이 빌드에서는 이 소스가 설정되어 있지 않습니다.';

  @override
  String get searchCheckNoLyrics => '일치하는 가사가 없습니다.';

  @override
  String get searchCheckFailed => '이 작업을 완료할 수 없습니다.';

  @override
  String get searchCheckNoHistory => '이 비교에서는 소스 확인이 실행되지 않았습니다.';

  @override
  String get searchVersionCredits => '크레딧';

  @override
  String get searchVersionMediaLinks => '관련 링크';

  @override
  String get searchCheckCancelled => '취소됨';

  @override
  String get searchCheckAmbiguous =>
      '일치하는 항목이 여러 개 있습니다. 이 소스에는 더 구체적인 녹음 정보가 필요합니다.';

  @override
  String get searchCheckIdentity => '이 소스에는 녹음 또는 작품 식별자가 필요합니다.';

  @override
  String get searchCheckExtraction => '소스가 응답했지만 가사를 추출할 수 없습니다.';

  @override
  String get searchCheckBusy => '이 소스가 사용 중입니다. 나중에 다시 시도하세요.';

  @override
  String get searchCheckSelection => '이 소스에서 특정 결과를 선택하세요.';

  @override
  String get playerChordsNone => '없음';

  @override
  String get editorCustomValue => '기타…';

  @override
  String get editorStandardTuning => '표준 튜닝';

  @override
  String get editorExampleVerse =>
      '[C]새로운 하루가 [G]우릴 부르고,\n[Am]빛을 따라 [F]집으로 돌아가요.';

  @override
  String get editorExampleChorus => '[F]이 노래를 [C]함께 불러요,\n[G]멜로디를 따라 [C]나아가요.';

  @override
  String get editorExampleBridge => '[Am]한 줄 더, 조금 더 [F]가까이.';

  @override
  String get playerEstimatedKey => '추정 조성';

  @override
  String get songsLibraryView => '라이브러리';

  @override
  String get settingsStartupView => '시작 화면';

  @override
  String get settingsStartupViewHint => '앱을 열 때 표시할 노래 화면을 선택하세요.';

  @override
  String get settingsStartupLastView => '마지막으로 연 화면';

  @override
  String get playerFullScreen => '전체 화면';

  @override
  String get playerExitFullScreen => '전체 화면 종료';

  @override
  String get playerExpandControls => '재생 컨트롤 표시';

  @override
  String get playerCollapseControls => '재생 컨트롤 숨기기';

  @override
  String get settingsShowSections => '섹션 제목 표시';

  @override
  String get settingsShowSectionsHint => '가사에 절, 후렴 및 기타 섹션 제목을 표시합니다.';

  @override
  String get settingsShowPlayerControls => '재생 컨트롤 표시';

  @override
  String get settingsShowPlayerControlsHint =>
      '플레이어 패널을 탭하거나 스와이프해 표시하거나 숨길 수도 있습니다.';

  @override
  String get sourceAnalysisHeading => '제출된 오디오 분석(미검증)';

  @override
  String sourceAnalysisCoverage(int shown, int total) {
    return '$total개 제출 중 $shown개 표시';
  }

  @override
  String sourceAnalysisSample(int number) {
    return '샘플 $number';
  }

  @override
  String get sourceAnalysisEstimatedTempo => '추정 템포 (BPM)';
}
