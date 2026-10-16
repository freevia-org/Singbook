// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'अपनी गीत लाइब्रेरी में गीत खोजने, व्यवस्थित करने और गाने के लिए एक शांत जगह।';

  @override
  String get aboutMadeForSinging => 'साथ मिलकर गाने के लिए बनाया गया';

  @override
  String appVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get navHome => 'होम';

  @override
  String get navSongs => 'गीत';

  @override
  String get navSetlists => 'गीत-सूचियाँ';

  @override
  String get navSettings => 'सेटिंग';

  @override
  String get navSettingsCompact => 'सेटिंग';

  @override
  String get navSearch => 'खोजें';

  @override
  String get navBack => 'वापस';

  @override
  String get navClose => 'बंद करें';

  @override
  String get navMore => 'और कार्रवाइयाँ';

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get actionSave => 'सहेजें';

  @override
  String get actionDone => 'हो गया';

  @override
  String get actionEdit => 'संपादित करें';

  @override
  String get actionDelete => 'हटाएँ';

  @override
  String get actionShare => 'साझा करें';

  @override
  String get actionPrint => 'प्रिंट करें';

  @override
  String get actionCopy => 'कॉपी करें';

  @override
  String get actionClear => 'साफ़ करें';

  @override
  String get actionRetry => 'फिर से कोशिश करें';

  @override
  String get actionRefresh => 'रिफ़्रेश करें';

  @override
  String get actionImport => 'आयात करें';

  @override
  String get actionExport => 'निर्यात करें';

  @override
  String get actionExpand => 'बड़ा करें';

  @override
  String get actionCollapse => 'समेटें';

  @override
  String get actionAdd => 'जोड़ें';

  @override
  String get actionCreate => 'बनाएँ';

  @override
  String get actionRemove => 'हटाएँ';

  @override
  String get actionDuplicate => 'डुप्लिकेट करें';

  @override
  String get actionMoveUp => 'ऊपर ले जाएँ';

  @override
  String get actionMoveDown => 'नीचे ले जाएँ';

  @override
  String get actionPrevious => 'पिछला';

  @override
  String get actionNext => 'अगला';

  @override
  String get searchHint => 'गीत, कलाकार या बोल खोजें';

  @override
  String get searchCatalogHint => 'कोई गीत या कलाकार खोजें';

  @override
  String get searchChangeSong => 'गाना बदलें';

  @override
  String get searchSelectedPreview => 'चुना हुआ पूर्वावलोकन';

  @override
  String get searchSubmit => 'खोजें';

  @override
  String get searchFilters => 'खोज विकल्प';

  @override
  String get searchFiltersShow => 'खोज विकल्प दिखाएँ';

  @override
  String get searchFiltersHide => 'खोज विकल्प छिपाएँ';

  @override
  String get searchFilterArtist => 'कलाकार';

  @override
  String get searchFilterTitle => 'गीत का शीर्षक';

  @override
  String get searchFilterLyrics => 'बोल';

  @override
  String get searchFilterChords => 'कॉर्ड उपलब्ध हैं';

  @override
  String get searchFilterTimed => 'समयबद्ध बोल';

  @override
  String get searchFilterLanguage => 'भाषा';

  @override
  String get searchFilterAll => 'कोई भी';

  @override
  String get searchAutocompleteLabel => 'सुझाव';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count परिणाम',
      one: '1 परिणाम',
      zero: 'कोई परिणाम नहीं',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery => 'खोजने के लिए गीत, कलाकार या बोल दर्ज करें।';

  @override
  String get searchCatalogEmptyQuery => 'खोजने के लिए गीत या कलाकार दर्ज करें।';

  @override
  String get searchNoResults => 'कोई गीत नहीं मिला। कोई दूसरा शब्द खोजें।';

  @override
  String get searchLoading => 'गीत खोजे जा रहे हैं…';

  @override
  String get searchError => 'खोज पूरी नहीं हो सकी।';

  @override
  String get searchOnlineTab => 'ऑनलाइन';

  @override
  String get searchRecentTab => 'हाल के';

  @override
  String get searchFavoritesTab => 'पसंदीदा';

  @override
  String get searchSuggested => 'सुझाया गया मेल';

  @override
  String get searchAlternatives => 'अन्य मेल';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count तैयार संस्करण',
      one: '1 तैयार संस्करण',
      zero: '0 तैयार संस्करण',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count अनुपलब्ध संस्करण',
      one: '1 अनुपलब्ध संस्करण',
      zero: '0 अनुपलब्ध संस्करण',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'अनुभाग पर जाएँ';

  @override
  String get searchVersionDetails => 'संस्करण का विवरण';

  @override
  String get searchSelectedRecording => 'चयनित रिकॉर्डिंग';

  @override
  String get searchVersionDuration => 'संस्करण की अवधि';

  @override
  String get searchCompare => 'संस्करणों की तुलना करें';

  @override
  String get searchChooseVersion => 'यह संस्करण चुनें';

  @override
  String get searchFullPreview => 'पूरा पूर्वावलोकन';

  @override
  String get searchArrangementNotes => 'संगीत संयोजन के नोट';

  @override
  String get searchOpenLyrics => 'बोल खोलें';

  @override
  String get searchContributions => 'इस्तेमाल किए गए स्रोत';

  @override
  String get searchVersionChecking => 'इस संस्करण की जाँच हो रही है…';

  @override
  String get searchVersionUnavailable =>
      'यह संस्करण इस्तेमाल नहीं किया जा सकता। कोई दूसरा संस्करण चुनें।';

  @override
  String get searchPreviewUnavailable =>
      'गीत के बोल का पूर्वावलोकन उपलब्ध नहीं है।';

  @override
  String get searchSongMatch => 'गीत का मेल';

  @override
  String get searchRecordingMatch => 'रिकॉर्डिंग का मेल';

  @override
  String get searchMatchUnverified => 'रिकॉर्डिंग की पुष्टि नहीं हुई';

  @override
  String get searchMatchExact => 'रिकॉर्डिंग का सटीक मेल';

  @override
  String get searchMatchPossible => 'संभावित मेल';

  @override
  String get searchAvailability => 'उपलब्धता';

  @override
  String get searchLyricsAvailable => 'बोल उपलब्ध हैं';

  @override
  String get searchLyricsUnavailable => 'बोल उपलब्ध नहीं हैं';

  @override
  String get searchChordsAvailable => 'कॉर्ड उपलब्ध हैं';

  @override
  String get searchChordsUnavailable => 'कॉर्ड नहीं हैं';

  @override
  String get searchTimingAvailable => 'टाइमिंग उपलब्ध है';

  @override
  String get searchTimingUnavailable => 'टाइमिंग उपलब्ध नहीं है';

  @override
  String get searchDurationUnknown => 'अवधि अज्ञात';

  @override
  String searchRating(String rating) {
    return 'रेटिंग $rating';
  }

  @override
  String get searchSourceLabel => 'स्रोत';

  @override
  String get searchMetadata => 'गीत का विवरण';

  @override
  String get searchAlbum => 'एल्बम';

  @override
  String get searchArtist => 'कलाकार';

  @override
  String get searchYear => 'वर्ष';

  @override
  String get searchLanguage => 'भाषा';

  @override
  String get searchViewVersions => 'संस्करण देखें';

  @override
  String get searchSaved => 'गीत आपकी लाइब्रेरी में सहेजा गया।';

  @override
  String get searchSaveOpenLyrics => 'गीत सहेजें और खोलें';

  @override
  String get searchOtherResults => 'अन्य परिणाम';

  @override
  String get searchSaveFailed => 'यह गीत सहेजा नहीं जा सका।';

  @override
  String get homeRecentSongs => 'हाल के गीत';

  @override
  String get homeRecentlyPlayed => 'हाल में चलाए गए';

  @override
  String get homeFavorites => 'पसंदीदा';

  @override
  String get homeHistory => 'इतिहास';

  @override
  String get homeHistoryClear => 'इतिहास मिटाएँ';

  @override
  String get homeHistoryCleared => 'इतिहास मिटा दिया गया।';

  @override
  String get homeHistoryEmpty => 'आपके खोले हुए गीत यहाँ दिखाई देंगे।';

  @override
  String get homeFavoritesEmpty =>
      'आपके पसंदीदा गीत और गीत-सूचियाँ यहाँ दिखाई देंगी।';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आइटम दिखाए गए',
      one: '1 आइटम दिखाया गया',
      zero: '0 आइटम दिखाए गए',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'आपके हाल के गीत और गीत-सूचियाँ यहाँ दिखाई देंगी।';

  @override
  String get homeTimelineLabel => 'इतिहास की समयरेखा';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'पूरा इतिहास';

  @override
  String get homeShowFavorites => 'पसंदीदा दिखाएँ';

  @override
  String get homeShowRecent => 'हाल के दिखाएँ';

  @override
  String get songsTitle => 'गीत';

  @override
  String get songsEmpty => 'आपके गीत यहाँ दिखाई देंगे।';

  @override
  String get songsEmptySearch => 'आपकी खोज से कोई गीत मेल नहीं खाता।';

  @override
  String get songsAdd => 'गीत जोड़ें';

  @override
  String get songsSortAlphabetical => 'वर्णानुक्रम में क्रमबद्ध करें';

  @override
  String get songsAlphabetNavigation => 'गीत अनुक्रमणिका';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बार खोला गया',
      one: 'एक बार खोला गया',
      zero: 'कभी नहीं खोला गया',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'पसंदीदा में जोड़ें';

  @override
  String get songFavoriteRemove => 'पसंदीदा से हटाएँ';

  @override
  String get songMenuLabel => 'गीत की कार्रवाइयाँ';

  @override
  String get songInfo => 'गीत का विवरण';

  @override
  String get setlistMenuLabel => 'गीत-सूची की कार्रवाइयाँ';

  @override
  String get songAddToSetlist => 'गीत-सूची में जोड़ें';

  @override
  String get songCopyChordPro => 'ChordPro कॉपी करें';

  @override
  String get songDeleteConfirmTitle => 'गीत हटाएँ?';

  @override
  String get songDeleteConfirmMessage =>
      'यह गीत आपकी लाइब्रेरी से हटा दिया जाएगा।';

  @override
  String get songDeleted => 'गीत हटा दिया गया।';

  @override
  String get setlistsTitle => 'गीत-सूचियाँ';

  @override
  String get setlistsEmpty =>
      'अपनी अगली रिहर्सल या प्रस्तुति के लिए गीत-सूची बनाएँ।';

  @override
  String get setlistsEmptySearch => 'आपकी खोज से कोई गीत-सूची मेल नहीं खाती।';

  @override
  String get setlistCreate => 'नई गीत-सूची';

  @override
  String get setlistNameHint => 'गीत-सूची का नाम';

  @override
  String get setlistNotes => 'नोट';

  @override
  String get setlistEntryOverride => 'इस गीत का अलग स्वर और capo';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count गीत',
      one: '1 गीत',
      zero: 'कोई गीत नहीं',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'कम से कम $duration';
  }

  @override
  String get setlistDurationUnknown => 'अवधि अज्ञात';

  @override
  String setlistActivity(String date) {
    return 'आख़िरी गतिविधि $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'बनाई गई $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'संपादित की गई $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'आख़िरी बार चलाई गई $date';
  }

  @override
  String get setlistSongsEmpty => 'इस गीत-सूची में अभी कोई गीत नहीं है।';

  @override
  String get setlistAddSongs => 'गीत जोड़ें';

  @override
  String get setlistReorder => 'गीतों का क्रम बदलें';

  @override
  String setlistMoveSongUp(String song) {
    return '$song को ऊपर ले जाएँ';
  }

  @override
  String setlistMoveSongDown(String song) {
    return '$song को नीचे ले जाएँ';
  }

  @override
  String setlistRemoveSong(String song) {
    return '$song को गीत-सूची से हटाएँ';
  }

  @override
  String get setlistDuplicate => 'गीत-सूची की कॉपी बनाएँ';

  @override
  String get setlistFavoriteAdd => 'गीत-सूची को पसंदीदा बनाएँ';

  @override
  String get setlistFavoriteRemove => 'गीत-सूची को पसंदीदा से हटाएँ';

  @override
  String get setlistShare => 'गीत-सूची फ़ाइल के रूप में साझा करें';

  @override
  String get setlistSharePdf => 'PDF के रूप में साझा करें';

  @override
  String get setlistPrint => 'प्रिंट करें';

  @override
  String get setlistDeleteConfirmTitle => 'गीत-सूची हटाएँ?';

  @override
  String get setlistDeleteConfirmMessage =>
      'गीत-सूची हटा दी जाएगी। आपकी लाइब्रेरी के गीत बने रहेंगे।';

  @override
  String get setlistDeleted => 'गीत-सूची हटा दी गई।';

  @override
  String get readerTitle => 'बोल';

  @override
  String get readerNoLyrics => 'अभी तक बोल नहीं जोड़े गए हैं।';

  @override
  String get readerShowChords => 'कॉर्ड दिखाएँ';

  @override
  String get readerHideChords => 'कॉर्ड छिपाएँ';

  @override
  String get readerTranspose => 'कॉर्ड का स्वर बदलें';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सेमीटोन',
      one: '1 सेमीटोन',
      zero: '0 सेमीटोन',
    );
    return '$_temp0 से स्वर बदलें';
  }

  @override
  String get readerSaved => 'सहेजा गया';

  @override
  String get readerEdit => 'बोल और विवरण संपादित करें';

  @override
  String get playerPlay => 'बोलों की स्क्रॉलिंग चलाएँ';

  @override
  String get playerPause => 'बोलों की स्क्रॉलिंग रोकें';

  @override
  String get playerResume => 'बोलों की स्क्रॉलिंग फिर शुरू करें';

  @override
  String get playerSeek => 'प्लेबैक की स्थिति';

  @override
  String playerElapsed(String time) {
    return 'बिता हुआ समय $time';
  }

  @override
  String playerRemaining(String time) {
    return 'बाकी समय $time';
  }

  @override
  String get playerTimingMode => 'स्क्रॉलिंग मोड';

  @override
  String get playerTimedLyrics => 'समयबद्ध बोल';

  @override
  String get playerStartScroll => 'ऑटो-स्क्रॉल शुरू करें';

  @override
  String get playerEstimatedPace => 'अनुमानित गति';

  @override
  String get playerScrollSpeed => 'स्क्रॉल गति';

  @override
  String playerEstimatedDuration(String time) {
    return 'अनुमानित अवधि: $time';
  }

  @override
  String get playerLyricsOnly => 'गीत स्क्रॉल · ऑडियो नहीं';

  @override
  String get playerManualScroll => 'मैन्युअल स्क्रॉल';

  @override
  String get playerTimingStatusReady => 'बोल उपलब्ध टाइमिंग के अनुसार चलेंगे।';

  @override
  String get playerTimingStatusEstimated =>
      'स्क्रॉलिंग की गति गीत की अवधि से अनुमानित है।';

  @override
  String get playerTimingStatusManual => 'बोलों को स्वयं स्क्रॉल करें।';

  @override
  String get playerTimingStatusUnavailable =>
      'इस गीत के लिए समयबद्ध स्क्रॉलिंग उपलब्ध नहीं है।';

  @override
  String get playerDurationUnknown =>
      'अनुमानित स्क्रॉलिंग इस्तेमाल करने के लिए गीत की अवधि जोड़ें।';

  @override
  String get playerProgressLabel => 'गीत की प्रगति';

  @override
  String get playerCurrentSection => 'वर्तमान भाग';

  @override
  String get playerPreviousSection => 'पिछला भाग';

  @override
  String get playerNextSection => 'अगला भाग';

  @override
  String get playerPreviousSectionSong =>
      'पिछला भाग · सूची का पिछला गीत खोलने के लिए दबाकर रखें';

  @override
  String get playerNextSectionSong =>
      'अगला भाग · सूची का अगला गीत खोलने के लिए दबाकर रखें';

  @override
  String get playerPreviousSong => 'पिछला गीत';

  @override
  String get playerNextSong => 'अगला गीत';

  @override
  String get editorTitle => 'गीत संपादित करें';

  @override
  String get editorTitleField => 'गीत का शीर्षक';

  @override
  String get editorArtistField => 'कलाकार';

  @override
  String get editorAlbumField => 'एल्बम';

  @override
  String get editorLyricsField => 'बोल';

  @override
  String get editorChordsField => 'कॉर्ड';

  @override
  String get editorKeyField => 'स्वर';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'ट्यूनिंग';

  @override
  String get editorTempoField => 'गति';

  @override
  String get editorDurationField => 'अवधि';

  @override
  String get editorTimeSignatureField => 'ताल संकेत';

  @override
  String get editorLanguageField => 'भाषा';

  @override
  String get editorYearField => 'वर्ष';

  @override
  String get editorComposerField => 'संगीतकार';

  @override
  String get editorLyricistField => 'गीतकार';

  @override
  String get editorCopyrightField => 'कॉपीराइट';

  @override
  String get editorLicenseField => 'लाइसेंस';

  @override
  String get songInfoSources => 'स्रोत और श्रेय';

  @override
  String get searchMatchSameSong => 'वही गीत; रिकॉर्डिंग की पुष्टि नहीं हुई';

  @override
  String get searchMatchNeedsAgreement => 'चार्ट के बोलों की पुष्टि ज़रूरी है';

  @override
  String get searchMatchDifferentLyrics => 'बोल चुने गए गीत से अलग हैं';

  @override
  String get searchMatchCombinedSources => 'कई स्रोतों से विवरण जोड़ा गया';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्रोतों से जोड़ा गया',
      one: '1 स्रोत से जोड़ा गया',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count गीत मेल खाते हैं',
      one: '1 गीत मेल खाता है',
      zero: '0 गीत मेल खाते हैं',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्रोत संस्करण',
      one: '1 स्रोत संस्करण',
      zero: '0 स्रोत संस्करण',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'सबसे अच्छा उपलब्ध मेल';

  @override
  String get providerDescriptionUnknown => 'गीत का स्रोत';

  @override
  String get providerDescDownloadChordProThenImport =>
      'स्रोत से ChordPro फ़ाइल डाउनलोड करें, फिर उसे आयात करें।';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'मुफ़्त खाते से फ़ाइल डाउनलोड करें, फिर उसे आयात करें।';

  @override
  String get providerDescPublicChordSheets => 'सार्वजनिक कॉर्ड शीट।';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'प्रत्येक रचना के लिए लाइसेंस प्राप्त ऐतिहासिक बोल।';

  @override
  String get providerDescLicensedCatalog => 'लाइसेंस प्राप्त गीत-संग्रह।';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Creative Commons BY के अंतर्गत मौलिक गीत।';

  @override
  String get providerDescPerSongLicense => 'हर गीत के लिए लाइसेंस प्राप्त बोल।';

  @override
  String get providerDescRecordingMetadataOnly =>
      'केवल रिकॉर्डिंग और रिलीज़ का विवरण।';

  @override
  String get providerDescCompositionMetadataOnly => 'केवल रचना का विवरण।';

  @override
  String get providerDescExactFileArtworkOnly =>
      'केवल सटीक रिकॉर्डिंग मेल के लिए कवर आर्ट।';

  @override
  String get providerCapabilityLyrics => 'बोल';

  @override
  String get providerCapabilityChords => 'कॉर्ड';

  @override
  String get providerCapabilityTiming => 'समयबद्ध बोल';

  @override
  String get providerCapabilitySearch => 'खोज';

  @override
  String get providerCapabilityMetadata => 'गीत का विवरण';

  @override
  String get editorArtworkField => 'कवर आर्ट लिंक';

  @override
  String get editorLyricsHint =>
      'बोल या कॉर्ड संपादित करने के लिए किसी पंक्ति पर टैप करें।';

  @override
  String get editorSave => 'बदलाव सहेजें';

  @override
  String get editorSaved => 'बदलाव सहेज दिए गए।';

  @override
  String get editorSaveFailed => 'बदलाव सहेजे नहीं जा सके।';

  @override
  String get editorSaveConflict =>
      'गीत कहीं और बदला गया था। आपके संपादन अलग कॉपी के रूप में सहेजे गए।';

  @override
  String get editorUnsavedTitle => 'बदलाव छोड़ें?';

  @override
  String get editorUnsavedMessage => 'आपके संपादन सहेजे नहीं गए हैं।';

  @override
  String get editorFieldRequired => 'गीत का शीर्षक दर्ज करें।';

  @override
  String get settingsTitle => 'सेटिंग';

  @override
  String get settingsAppearance => 'दिखावट';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get settingsThemeSystem => 'डिवाइस सेटिंग इस्तेमाल करें';

  @override
  String get settingsThemeLight => 'हल्की';

  @override
  String get settingsThemeDark => 'गहरी';

  @override
  String get settingsColorPalette => 'रंग पैलेट';

  @override
  String get settingsFont => 'फ़ॉन्ट';

  @override
  String get settingsTextSize => 'टेक्स्ट का आकार';

  @override
  String get settingsLyricsPreview => 'बोलों का पूर्वावलोकन';

  @override
  String get settingsPlayer => 'बोल प्लेयर';

  @override
  String get settingsDefaultShowChords => 'डिफ़ॉल्ट रूप से कॉर्ड दिखाएँ';

  @override
  String get settingsDefaultAutoscroll =>
      'बोलों की स्क्रॉलिंग अपने-आप शुरू करें';

  @override
  String get settingsDefaultTiming => 'डिफ़ॉल्ट स्क्रॉलिंग मोड';

  @override
  String get settingsLanguage => 'ऐप की भाषा';

  @override
  String get settingsLanguageSystem => 'डिवाइस की भाषा इस्तेमाल करें';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'बोलों के स्रोत';

  @override
  String settingsSourceEnabled(String source) {
    return '$source स्रोत चालू करें';
  }

  @override
  String get settingsSourceRefresh => 'स्रोत सूची रिफ़्रेश करें';

  @override
  String get settingsSourcesUpdated => 'स्रोत अपडेट किए गए।';

  @override
  String get settingsSourcesUpdateFailed => 'स्रोत रिफ़्रेश नहीं किए जा सके।';

  @override
  String get settingsImport => 'गीत आयात करें';

  @override
  String get settingsImportChordPro => 'ChordPro फ़ाइल आयात करें';

  @override
  String get settingsImportSetlist => 'गीत-सूची फ़ाइल आयात करें';

  @override
  String get settingsImportSuccess => 'आयात पूरा हुआ।';

  @override
  String get settingsImportFailed => 'यह फ़ाइल आयात नहीं की जा सकी।';

  @override
  String get settingsImportUnsupported => 'यह फ़ाइल प्रकार समर्थित नहीं है।';

  @override
  String get settingsShareSong => 'ChordPro के रूप में साझा करें';

  @override
  String get settingsSharePdf => 'PDF के रूप में साझा करें';

  @override
  String get settingsCopySong => 'क्लिपबोर्ड पर कॉपी करें';

  @override
  String get settingsPrintSong => 'केवल प्रिंट करें';

  @override
  String get settingsPrintSetlist => 'बोलों सहित गीत-सूची प्रिंट करें';

  @override
  String get settingsExportFailed => 'फ़ाइल तैयार नहीं की जा सकी।';

  @override
  String get settingsCopied => 'क्लिपबोर्ड पर कॉपी किया गया।';

  @override
  String get settingsAbout => 'ऐप के बारे में';

  @override
  String get settingsPrivacy => 'गोपनीयता';

  @override
  String get settingsLegal => 'कानूनी जानकारी';

  @override
  String get settingsClearHistory => 'इतिहास मिटाएँ';

  @override
  String get settingsClearHistoryConfirm =>
      'गीतों और गीत-सूचियों का इतिहास मिटाएँ?';

  @override
  String get settingsHistoryCleared => 'इतिहास मिटा दिया गया।';

  @override
  String get accountTitle => 'खाता और सिंक';

  @override
  String get accountUnavailable =>
      'सिंक के लिए Google साइन-इन कॉन्फ़िगर किया हुआ Singbook बिल्ड चाहिए। यह बिल्ड आपके गीत केवल इसी डिवाइस पर रखता है।';

  @override
  String get accountSyncNow => 'अभी सिंक करें';

  @override
  String get accountConnected =>
      'कनेक्ट किया गया। बैकअप अपडेट करने के लिए “अभी सिंक करें” चुनें।';

  @override
  String get accountSignIn => 'खाता कनेक्ट करें';

  @override
  String get accountSignOut => 'साइन आउट करें';

  @override
  String get accountChange => 'खाता बदलें';

  @override
  String get accountSignedOut => 'कनेक्ट नहीं है';

  @override
  String get accountSyncing => 'आपकी लाइब्रेरी सिंक हो रही है…';

  @override
  String get accountSynced => 'लाइब्रेरी सिंक हो गई।';

  @override
  String get accountSyncFailed => 'आपकी लाइब्रेरी सिंक नहीं हो सकी।';

  @override
  String get accessibilityFavorite => 'पसंदीदा';

  @override
  String get accessibilityNotFavorite => 'पसंदीदा नहीं';

  @override
  String get accessibilitySearchField => 'गीत खोजें';

  @override
  String get accessibilityClearSearch => 'खोज टेक्स्ट साफ़ करें';

  @override
  String accessibilitySongMenu(String song) {
    return '$song के लिए कार्रवाइयाँ';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return '$setlist के लिए कार्रवाइयाँ';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return '$setlist के गीत दिखाएँ';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return '$setlist के गीत छिपाएँ';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'प्लेबैक प्रगति, $percent प्रतिशत';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'इतिहास की समयरेखा, $date';
  }

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String get loadingSongs => 'गीत लोड हो रहे हैं…';

  @override
  String get loadingSetlists => 'गीत-सूचियाँ लोड हो रही हैं…';

  @override
  String get errorGeneric => 'कुछ गड़बड़ हुई।';

  @override
  String get errorOffline => 'लगता है आप ऑफ़लाइन हैं।';

  @override
  String get errorPermission => 'जारी रखने के लिए अनुमति ज़रूरी है।';

  @override
  String get emptyFiltered => 'इन फ़िल्टर से कोई आइटम मेल नहीं खाता।';

  @override
  String get unknownValue => 'अज्ञात';

  @override
  String get durationUnknown => 'अवधि अज्ञात';

  @override
  String get metadataNotSet => 'सेट नहीं है';

  @override
  String get dateToday => 'आज';

  @override
  String get dateYesterday => 'कल';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count गीत',
      one: '1 गीत',
      zero: 'कोई गीत नहीं',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'गहरा नीला';

  @override
  String get settingsPaletteSage => 'सेज';

  @override
  String get settingsPaletteOcean => 'समुद्री नीला';

  @override
  String get settingsPaletteClay => 'मिट्टी जैसा';

  @override
  String get settingsPalettePlum => 'बेर';

  @override
  String get settingsFontSystem => 'सिस्टम';

  @override
  String get settingsFontSerif => 'सेरिफ़';

  @override
  String get settingsFontMonospace => 'मोनोस्पेस';

  @override
  String get settingsLyricsPreviewExample => 'सुबह होते ही, हम फिर गाएँगे।';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'बोलों के स्रोत जाँचे जा रहे हैं: $total में से $checked पूरे।';
  }

  @override
  String get searchDiscoveryNoLyrics => 'इस्तेमाल करने योग्य बोल नहीं मिले।';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'चुने गए गीत को चालू स्रोतों में खोजा गया, लेकिन किसी ने भी इस्तेमाल करने योग्य बोलों का संस्करण नहीं दिया।';

  @override
  String get searchDiscoveryError => 'बोलों के स्रोत नहीं जाँचे जा सके।';

  @override
  String get searchDiscoveryRetry => 'बोलों की खोज फिर से करें';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्रोत उपलब्ध नहीं',
      one: '1 स्रोत उपलब्ध नहीं',
      zero: '0 स्रोत उपलब्ध नहीं',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'अपना कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get searchProviderChecks => 'स्रोत जाँच';

  @override
  String get searchProviderPending => 'जाँच हो रही है';

  @override
  String get searchProviderFound => 'मेल मिला';

  @override
  String get searchProviderRejected => 'मेल नहीं खाता';

  @override
  String get searchProviderFailed => 'जाँच विफल';

  @override
  String get searchProviderUnavailable => 'इस्तेमाल करने योग्य बोल नहीं';

  @override
  String get searchCatalogFilterHint =>
      'कॉर्ड, टाइमिंग या भाषा के आधार पर बोलों के संस्करण फ़िल्टर करने के लिए कोई गीत चुनें।';

  @override
  String get startupErrorTitle => 'आपकी लाइब्रेरी नहीं खुल सकी।';

  @override
  String setlistCopyName(String name) {
    return '$name की कॉपी';
  }

  @override
  String get setlistSongMissing => 'गीत मौजूद नहीं है';

  @override
  String get settingsImportTooLarge =>
      'यह फ़ाइल आयात करने के लिए बहुत बड़ी है।';

  @override
  String songsJumpToLetter(String letter) {
    return '$letter पर जाएँ';
  }

  @override
  String get actionDiscard => 'छोड़ें';

  @override
  String get editorKeepEditing => 'संपादन जारी रखें';

  @override
  String get settingsDefaultShowChordsHint =>
      'गीत में कॉर्ड हों, तो उन्हें बोलों के ऊपर दिखाएँ।';

  @override
  String get settingsDefaultAutoscrollHint =>
      'बोल गीत के साथ स्क्रॉल होते हैं। मैन्युअल स्क्रॉल मोड में इस्तेमाल नहीं होता।';

  @override
  String get accountUnavailableTitle => 'सिंक सेट अप नहीं है';

  @override
  String get accountSignedOutBenefits =>
      'अपने गीतों और गीत-सूचियों का Google Drive पर बैकअप लेने और सभी डिवाइस सिंक रखने के लिए Google से साइन इन करें। आपके गीत किसी भी स्थिति में इस डिवाइस पर रहेंगे।';

  @override
  String get accountSignInWithGoogle => 'Google से साइन इन करें';

  @override
  String get accountWorking => 'काम हो रहा है…';

  @override
  String get accountNeverSynced => 'कभी सिंक नहीं हुआ';

  @override
  String get accountSyncedJustNow => 'अभी-अभी सिंक हुआ';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मिनट पहले सिंक हुआ',
      one: '$count मिनट पहले सिंक हुआ',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे पहले सिंक हुआ',
      one: '$count घंटे पहले सिंक हुआ',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन पहले सिंक हुआ',
      one: '$count दिन पहले सिंक हुआ',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'टकराव वाले $count संपादन कॉपी के रूप में रखे गए',
      one: 'टकराव वाला $count संपादन कॉपी के रूप में रखा गया',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'एक ही गीत या गीत-सूची को दो जगहों पर संपादित किया गया। कुछ भी खोया नहीं: दूसरा संस्करण अलग कॉपी के रूप में सहेजा गया।';

  @override
  String get accountReviewConflicts => 'कॉपियों की समीक्षा करें';

  @override
  String get songsConflictFilterActive =>
      'केवल टकराव वाली कॉपियाँ दिखाई जा रही हैं';

  @override
  String get songsConflictFilterClear => 'सभी गीत दिखाएँ';

  @override
  String get songsConflictBadge => 'टकराव वाली कॉपी';

  @override
  String get songsConflictEmpty => 'टकराव वाली कोई कॉपी नहीं।';

  @override
  String get accountAutoSync => 'अपने-आप सिंक करें';

  @override
  String get accountAutoSyncHint =>
      'ऐप खोलने और बदलावों के बाद अपनी लाइब्रेरी अपडेट रखें।';

  @override
  String get accountSignOutTitle => 'इस खाते से साइन आउट करें?';

  @override
  String get accountSignOutBody =>
      'आपके गीत और गीत-सूचियाँ इस डिवाइस पर रहेंगे। दोबारा साइन इन करने तक उनका बैकअप या सिंक नहीं होगा।';

  @override
  String get accountUseDifferent => 'दूसरा खाता इस्तेमाल करें';

  @override
  String get accountSignInAgain => 'फिर से साइन इन करें';

  @override
  String get accountChooseAction => 'आगे बढ़ने का तरीका चुनें';

  @override
  String get accountChangedTitle => 'दूसरा Google खाता';

  @override
  String get accountChangedBody =>
      'यह डिवाइस आख़िरी बार किसी दूसरे Google खाते से सिंक हुआ था। चुनें कि इस डिवाइस के गीतों और गीत-सूचियों के साथ क्या करना है।';

  @override
  String get accountChangedMerge => 'नए खाते में मिलाएँ';

  @override
  String get accountChangedMergeHint =>
      'इस डिवाइस पर सब कुछ रखें और उसे नए खाते में जोड़ें।';

  @override
  String get accountChangedReplace => 'नए खाते की लाइब्रेरी से बदलें';

  @override
  String get accountChangedReplaceHint =>
      'इस डिवाइस के वे गीत जो नए खाते में नहीं हैं, हटा दिए जाएँगे।';

  @override
  String get accountChangedSignOut => 'रद्द करें और साइन आउट करें';

  @override
  String get accountStatusSignedOut => 'खाता और सिंक: साइन इन नहीं है';

  @override
  String get accountStatusSignedIn => 'खाता और सिंक: साइन इन है';

  @override
  String get accountStatusSyncing => 'खाता और सिंक: सिंक हो रहा है';

  @override
  String get accountStatusSynced => 'खाता और सिंक: लाइब्रेरी अपडेट है';

  @override
  String get accountStatusError =>
      'खाता और सिंक: समस्या, समीक्षा के लिए टैप करें';

  @override
  String get accountNoticeConflicts =>
      'कुछ गीत दो जगहों पर संपादित किए गए। उनकी कॉपी रखी गई।';

  @override
  String get accountNoticeSignedIn => 'साइन इन हो गया।';

  @override
  String get accountNoticeSignedOut =>
      'साइन आउट हो गया। आपके गीत इस डिवाइस पर रहेंगे।';

  @override
  String get syncErrorNotConfigured => 'इस बिल्ड में सिंक सेट अप नहीं है।';

  @override
  String get syncErrorNotConfiguredHint =>
      'Google साइन-इन कॉन्फ़िगर किया हुआ Singbook बिल्ड इस्तेमाल करें।';

  @override
  String get syncErrorNotSignedIn => 'आप साइन इन नहीं हैं।';

  @override
  String get syncErrorNotSignedInHint =>
      'अपनी लाइब्रेरी सिंक करने के लिए साइन इन करें।';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google को आपसे फिर से साइन इन करने की ज़रूरत है।';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'सिंक जारी रखने के लिए फिर से साइन इन करें। आपके गीत इस डिवाइस पर सुरक्षित हैं।';

  @override
  String get syncErrorAccessDenied =>
      'Singbook को Google Drive इस्तेमाल करने की अनुमति नहीं है।';

  @override
  String get syncErrorAccessDeniedHint =>
      'फिर से साइन इन करें और पूछे जाने पर Drive का ऐक्सेस दें।';

  @override
  String get syncErrorRateLimited => 'Google अभी अनुरोध सीमित कर रहा है।';

  @override
  String get syncErrorRateLimitedHint => 'कुछ मिनट रुकें, फिर कोशिश करें।';

  @override
  String get syncErrorStorageFull => 'आपका Google Drive भर गया है।';

  @override
  String get syncErrorStorageFullHint =>
      'Drive में जगह खाली करें, फिर कोशिश करें।';

  @override
  String get syncErrorNetwork => 'Google से संपर्क नहीं हो सका।';

  @override
  String get syncErrorNetworkHint =>
      'अपना इंटरनेट कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get syncErrorAccountChanged => 'दूसरा Google खाता इस्तेमाल किया गया।';

  @override
  String get syncErrorAccountChangedHint =>
      'चुनें कि इस डिवाइस की लाइब्रेरी को उसमें मिलाना है या उससे बदलना है।';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'आपकी सिंक की गई लाइब्रेरी Singbook की क्षमता से बड़ी है।';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'सिंक की गई लाइब्रेरी से कुछ गीत या गीत-सूचियाँ हटाएँ, फिर कोशिश करें।';

  @override
  String get syncErrorSignInFailed => 'साइन-इन पूरा नहीं हुआ।';

  @override
  String get syncErrorSignInFailedHint => 'फिर से साइन इन करने की कोशिश करें।';

  @override
  String get syncErrorGeneric => 'आपकी लाइब्रेरी सिंक नहीं हो सकी।';

  @override
  String get syncErrorGenericHint =>
      'थोड़ी देर बाद फिर कोशिश करें। आपके गीत इस डिवाइस पर सुरक्षित हैं।';

  @override
  String get editorDurationInvalid =>
      'सेकंड या मिनट और सेकंड दर्ज करें, जैसे 3:45।';

  @override
  String get editorNumberInvalid => 'एक संख्या दर्ज करें।';

  @override
  String get accountReplaceConfirmTitle => 'स्थानीय गीत हटाएँ?';

  @override
  String get accountReplaceConfirmBody =>
      'इस डिवाइस के वे गीत और गीत-सूचियाँ, जो नए खाते में नहीं हैं, हमेशा के लिए हटा दी जाएँगी। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get accountReplaceConfirmAction => 'हटाएँ और बदलें';

  @override
  String get accountSuspiciousTitle => 'Google Drive में आइटम नहीं मिल रहे';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count आइटम, जिन्हें इस डिवाइस ने पहले सिंक किया था, Google Drive में नहीं हैं।',
      one:
          '$count आइटम, जिसे इस डिवाइस ने पहले सिंक किया था, Google Drive में नहीं है।',
    );
    return '$_temp0 ऐसा Google सेटिंग में ऐप का डेटा मिटाने पर हो सकता है। अभी कुछ भी नहीं हटाया गया है।';
  }

  @override
  String get accountSuspiciousDelete => 'उन्हें यहाँ से भी हटाएँ';

  @override
  String get accountSuspiciousKeep =>
      'मेरे गीत रखें और उन्हें फिर से अपलोड करें';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'इस डिवाइस से $count आइटम हटाएँ?',
      one: 'इस डिवाइस से $count आइटम हटाएँ?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'ये गीत और गीत-सूचियाँ इस डिवाइस से हमेशा के लिए हटा दी जाएँगी। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'इस डिवाइस से हटाएँ';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Google Drive में आइटम नहीं मिल रहे।';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'कुछ भी नहीं हटाया गया। चुनें कि उन्हें यहाँ से भी हटाना है या फिर से अपलोड करना है।';

  @override
  String get syncErrorRemoteChanged =>
      'सिंक के दौरान Google Drive में बदलाव हुआ।';

  @override
  String get syncErrorRemoteChangedHint =>
      'कुछ भी खोया नहीं है। नवीनतम बदलाव पाने के लिए फिर से सिंक करें।';

  @override
  String get syncErrorInvalidLocalData =>
      'इस डिवाइस का कुछ डेटा सिंक नहीं हो सका।';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'गीत या गीत-सूची पढ़ी नहीं जा सकी। उसे इंपोर्ट करें या फिर से बनाएँ, फिर सिंक करें।';

  @override
  String get syncErrorNoAccountChange =>
      'हल करने के लिए खाते में कोई बदलाव नहीं है।';

  @override
  String get syncErrorNoAccountChangeHint =>
      'जारी रखने के लिए फिर से सिंक करें।';

  @override
  String get accountSyncWarningTitle =>
      'सिंक हो गया, लेकिन कुछ फ़ाइलें छोड़ दी गईं';

  @override
  String get accountSyncWarningBody =>
      'कुछ फ़ाइलों का उपयोग नहीं हो सका और उन्हें वैसा ही रखा गया। बाकी सब अपडेट है।';

  @override
  String get accountSyncWarningTooLarge =>
      'एक फ़ाइल सिंक के लिए बहुत बड़ी थी, इसलिए छोड़ दी गई। बाकी सब अपडेट है।';

  @override
  String get accountSyncWarningInvalid =>
      'एक फ़ाइल पढ़ी नहीं जा सकी, इसलिए छोड़ दी गई। बाकी सब अपडेट है।';

  @override
  String get accountNoticeSyncSkipped =>
      'सिंक हो गया। कुछ फ़ाइलें छोड़ दी गईं।';

  @override
  String get settingsExportPdfTooLarge =>
      'यह PDF बहुत बड़ी होगी। कम गीत चुनें या इसे टेक्स्ट के रूप में साझा करें।';

  @override
  String get settingsTimingTooLarge =>
      'टाइमिंग डेटा बहुत बड़ा है (3 MB से अधिक)।';

  @override
  String get settingsImportDuplicateSongId =>
      'इस बैकअप में एक ही गीत दो बार है, इसलिए कुछ भी इंपोर्ट नहीं किया गया।';

  @override
  String get setlistSaveConflict =>
      'गीत-सूची कहीं और बदली गई। आपके संपादन अलग कॉपी के रूप में सहेजे गए।';

  @override
  String get sectionVerse => 'अंतरा';

  @override
  String get sectionChorus => 'कोरस';

  @override
  String get sectionBridge => 'ब्रिज';

  @override
  String get sectionIntro => 'इंट्रो';

  @override
  String get sectionOutro => 'आउट्रो';

  @override
  String get sectionPreChorus => 'प्री-कोरस';

  @override
  String get sectionPostChorus => 'पोस्ट-कोरस';

  @override
  String get sectionInstrumental => 'वाद्य भाग';

  @override
  String get sectionInterlude => 'इंटरल्यूड';

  @override
  String get sectionSolo => 'सोलो';

  @override
  String get sectionRefrain => 'मुखड़ा';

  @override
  String get sectionHook => 'हुक';

  @override
  String get sectionBreakdown => 'ब्रेकडाउन';

  @override
  String get sectionCoda => 'कोडा';

  @override
  String get sectionTag => 'टैग';

  @override
  String get sectionEnding => 'समापन';

  @override
  String get youtubeConsentHint =>
      'प्रयोगात्मक। गीत के बोल खोजने के लिए Google के पेज पर कुकी विकल्प चुनें। Google खाते में साइन इन करने की ज़रूरत नहीं है। आपकी पसंद इसी डिवाइस पर रहेगी।';

  @override
  String get youtubeConsentOpen => 'Google की सहमति देखें';

  @override
  String get youtubeConsentSaved => 'सहमति सहेजी गई';

  @override
  String get youtubeConsentClear => 'सहमति मिटाएँ';

  @override
  String get youtubeConsentInstructions =>
      'कुकी विकल्प पूरा करें और YouTube Music के लौटने तक प्रतीक्षा करें। फिर यह सत्र सहेजें और गाना दोबारा खोजें।';

  @override
  String get youtubeConsentError =>
      'Google की सहमति का विकल्प अपडेट नहीं हो सका। फिर से कोशिश करें।';

  @override
  String get youtubeConsentBlocked =>
      'यहाँ केवल YouTube Music और Google का सहमति पेज खुल सकता है। खाते में साइन इन करना उपलब्ध नहीं है।';
}
