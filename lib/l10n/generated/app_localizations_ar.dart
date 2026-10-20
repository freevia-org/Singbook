// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'كلمات الأغاني وأكورداتها وقوائم الأغاني، كلها معًا، جاهزة للتدريب والعزف على المسرح وأينما تعزف.';

  @override
  String get aboutMadeForSinging => 'كل أغنية جاهزة.';

  @override
  String get aboutDetails =>
      'ابحث في المصادر المتاحة وقارن الكلمات والأكوردات والتوقيت وتفاصيل التسجيل قبل حفظ النسخة التي تريد عزفها. يختلف المحتوى المتاح حسب الأغنية والخدمة.';

  @override
  String get aboutFindTitle => 'اعثر على النسخة المناسبة';

  @override
  String get aboutKeepTitle => 'أنشئ مكتبتك الخاصة';

  @override
  String get aboutKeepDetails =>
      'حرّر الأغاني وغيّر طبقتها، واحتفظ بها في مكتبتك المحلية لاستخدامها دون اتصال، وشارك ملفات ChordPro قابلة للنقل. تستخدم المزامنة الاختيارية مع Google Drive مجلدًا خاصًا بالتطبيق في حسابك على Google. ويمكنك أيضًا الضغط على «زامِن الآن» لتحديث أجهزتك.';

  @override
  String get aboutPlayTitle => 'اصطحب قائمتك إلى المسرح';

  @override
  String get aboutPlayDetails =>
      'رتّب الأغاني في قوائم، واختر طبقة لكل أغنية، وشارك قوائم OpenSong. اضبط حجم نص القارئ والتمرير التلقائي للكلمات واطبع ملفات PDF للأغاني. لا يبث Singbook الصوت ولا يشغّله.';

  @override
  String get aboutPrivacyTitle => 'مجاني ويضع جهازك أولًا';

  @override
  String get aboutPrivacyDetails =>
      'Singbook مجاني، بلا إعلانات أو تحليلات أو مشتريات داخل التطبيق. تبقى مكتبتك المحفوظة على جهازك؛ وتستخدم المزامنة الاختيارية Google Drive الخاص بك. تأتي النتائج عبر الإنترنت مباشرةً من خدمات مستقلة تابعة لجهات خارجية، وقد لا تكون متاحة أو قد تكون محمية بحقوق النشر. لا يستضيف Singbook محتواها.';

  @override
  String get aboutWebsite => 'موقع Singbook';

  @override
  String get aboutSourceCode => 'الكود المصدري على GitHub';

  @override
  String get aboutPublisher => 'من Freevia';

  @override
  String aboutLanguages(int count) {
    return 'لغات التطبيق: $count';
  }

  @override
  String get aboutSupport => 'الدعم والملاحظات';

  @override
  String get menuTypeNewSong => 'اكتب أغنية جديدة';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navSongs => 'الأغاني';

  @override
  String get navSetlists => 'قوائم الأغاني';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navSettingsCompact => 'الإعدادات';

  @override
  String get navSearch => 'بحث';

  @override
  String get navBack => 'رجوع';

  @override
  String get appExitBackAgain => 'اضغط رجوع مرة أخرى للخروج';

  @override
  String get navClose => 'إغلاق';

  @override
  String get navMore => 'مزيد من الإجراءات';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionDone => 'تم';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionShare => 'مشاركة';

  @override
  String get actionPrint => 'طباعة';

  @override
  String get actionCopy => 'نسخ';

  @override
  String get actionClear => 'مسح';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionRefresh => 'تحديث';

  @override
  String get actionImport => 'استيراد';

  @override
  String get actionExport => 'تصدير';

  @override
  String get actionExpand => 'توسيع';

  @override
  String get actionCollapse => 'طي';

  @override
  String get actionAdd => 'إضافة';

  @override
  String get actionCreate => 'إنشاء';

  @override
  String get actionRemove => 'إزالة';

  @override
  String get actionDuplicate => 'إنشاء نسخة';

  @override
  String get actionMoveUp => 'نقل إلى الأعلى';

  @override
  String get actionMoveDown => 'نقل إلى الأسفل';

  @override
  String get actionPrevious => 'السابق';

  @override
  String get actionNext => 'التالي';

  @override
  String get searchHint => 'ابحث عن الأغاني أو الفنانين أو الكلمات';

  @override
  String get searchCatalogHint => 'ابحث عن أغنية أو فنان';

  @override
  String get searchChangeSong => 'تغيير الأغنية';

  @override
  String get searchSelectedPreview => 'معاينة محددة';

  @override
  String get searchSubmit => 'بحث';

  @override
  String get searchFilters => 'خيارات البحث';

  @override
  String get searchFiltersShow => 'إظهار خيارات البحث';

  @override
  String get searchFiltersHide => 'إخفاء خيارات البحث';

  @override
  String get searchFilterArtist => 'الفنان';

  @override
  String get searchFilterTitle => 'عنوان الأغنية';

  @override
  String get searchFilterLyrics => 'الكلمات';

  @override
  String get searchFilterChords => 'تحتوي على أكوردات';

  @override
  String get searchFilterTimed => 'كلمات متزامنة';

  @override
  String get searchFilterLanguage => 'اللغة';

  @override
  String get searchFilterAll => 'الكل';

  @override
  String get searchAutocompleteLabel => 'اقتراحات';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتيجة',
      many: '$count نتيجة',
      few: '$count نتائج',
      two: 'نتيجتان',
      one: 'نتيجة واحدة',
      zero: 'لا توجد نتائج',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery => 'أدخل أغنية أو فنانًا أو كلمات للبحث.';

  @override
  String get searchCatalogEmptyQuery => 'أدخل أغنية أو فنانًا للبحث.';

  @override
  String get searchNoResults => 'لم يتم العثور على أغانٍ. جرّب بحثًا مختلفًا.';

  @override
  String get searchLoading => 'جارٍ البحث عن الأغاني…';

  @override
  String get searchError => 'تعذّر إكمال البحث.';

  @override
  String get searchOnlineTab => 'عبر الإنترنت';

  @override
  String get searchRecentTab => 'الأخيرة';

  @override
  String get searchFavoritesTab => 'المفضلة';

  @override
  String get searchSuggested => 'تطابق مقترح';

  @override
  String get searchAlternatives => 'تطابقات أخرى';

  @override
  String get searchCompare => 'مقارنة الإصدارات';

  @override
  String get searchChooseVersion => 'اختيار هذا الإصدار';

  @override
  String get searchFullPreview => 'معاينة كاملة';

  @override
  String get searchArrangementNotes => 'ملاحظات التوزيع الموسيقي';

  @override
  String get searchOpenLyrics => 'فتح الكلمات';

  @override
  String get searchContributions => 'المصادر المستخدمة';

  @override
  String get searchVersionChecking => 'جارٍ التحقق من هذا الإصدار…';

  @override
  String get searchVersionUnavailable =>
      'يتعذر استخدام هذا الإصدار. اختر إصدارًا آخر.';

  @override
  String get searchPreviewUnavailable => 'لا تتوفر معاينة للكلمات.';

  @override
  String get searchSongMatch => 'تطابق الأغنية';

  @override
  String get searchRecordingMatch => 'تطابق التسجيل';

  @override
  String get searchMatchUnverified => 'لم يتم التحقق من التسجيل';

  @override
  String get searchMatchExact => 'تطابق التسجيل تمامًا';

  @override
  String get searchMatchPossible => 'تطابق محتمل';

  @override
  String get searchAvailability => 'التوفر';

  @override
  String get searchLyricsAvailable => 'الكلمات متوفرة';

  @override
  String get searchLyricsUnavailable => 'الكلمات غير متوفرة';

  @override
  String get searchChordsAvailable => 'الأكوردات متوفرة';

  @override
  String get searchChordsUnavailable => 'لا توجد أكوردات';

  @override
  String get searchTimingAvailable => 'التوقيت متوفر';

  @override
  String get searchTimingUnavailable => 'لا يوجد توقيت';

  @override
  String get searchDurationUnknown => 'المدة غير معروفة';

  @override
  String searchRating(String rating) {
    return 'التقييم $rating';
  }

  @override
  String get searchSourceLabel => 'المصدر';

  @override
  String get searchMetadata => 'تفاصيل الأغنية';

  @override
  String get searchAlbum => 'الألبوم';

  @override
  String get searchArtist => 'الفنان';

  @override
  String get searchYear => 'السنة';

  @override
  String get searchLanguage => 'اللغة';

  @override
  String get searchViewVersions => 'عرض النسخ';

  @override
  String get searchSaved => 'تم حفظ الأغنية في مكتبتك.';

  @override
  String get searchSaveOpenLyrics => 'حفظ وفتح الكلمات';

  @override
  String get searchOtherResults => 'نتائج أخرى';

  @override
  String get searchSaveFailed => 'تعذّر حفظ هذه الأغنية.';

  @override
  String get homeRecentSongs => 'الأغاني الأخيرة';

  @override
  String get homeRecentlyPlayed => 'تم تشغيلها مؤخرًا';

  @override
  String get homeFavorites => 'المفضلة';

  @override
  String get homeHistory => 'السجل';

  @override
  String get homeHistoryClear => 'مسح السجل';

  @override
  String get homeHistoryCleared => 'تم مسح السجل.';

  @override
  String get homeHistoryEmpty => 'ستظهر هنا الأغاني التي تفتحها.';

  @override
  String get homeFavoritesEmpty => 'ستظهر هنا أغانيك وقوائمك المفضلة.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم عرض $count عنصر',
      many: 'تم عرض $count عنصرًا',
      few: 'تم عرض $count عناصر',
      two: 'تم عرض عنصرين',
      one: 'تم عرض عنصر واحد',
      zero: 'لم يتم عرض أي عناصر',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty => 'ستظهر هنا أغانيك وقوائمك الأخيرة.';

  @override
  String get homeTimelineLabel => 'الخط الزمني للسجل';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'السجل الكامل';

  @override
  String get homeShowFavorites => 'إظهار المفضلة';

  @override
  String get homeShowRecent => 'إظهار الأخيرة';

  @override
  String get songsTitle => 'الأغاني';

  @override
  String get songsEmpty => 'ستظهر أغانيك هنا.';

  @override
  String get songsEmptySearch => 'لا تتطابق أي أغنية مع بحثك.';

  @override
  String get songsAdd => 'إضافة أغنية';

  @override
  String get songsSortAlphabetical => 'ترتيب أبجدي';

  @override
  String get songsAlphabetNavigation => 'فهرس الأغاني';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم فتحها $count مرة',
      many: 'تم فتحها $count مرة',
      few: 'تم فتحها $count مرات',
      two: 'تم فتحها مرتين',
      one: 'تم فتحها مرة واحدة',
      zero: 'لم يتم فتحها مطلقًا',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'إضافة إلى المفضلة';

  @override
  String get songFavoriteRemove => 'إزالة من المفضلة';

  @override
  String get songMenuLabel => 'إجراءات الأغنية';

  @override
  String get songInfo => 'تفاصيل الأغنية';

  @override
  String get setlistMenuLabel => 'إجراءات قائمة الأغاني';

  @override
  String get songAddToSetlist => 'إضافة إلى قائمة الأغاني';

  @override
  String get songCopyChordPro => 'نسخ ChordPro';

  @override
  String get songDeleteConfirmTitle => 'حذف الأغنية؟';

  @override
  String get songDeleteConfirmMessage => 'ستتم إزالة هذه الأغنية من مكتبتك.';

  @override
  String get songDeleted => 'تم حذف الأغنية.';

  @override
  String get setlistsTitle => 'قوائم الأغاني';

  @override
  String get setlistsEmpty => 'أنشئ قائمة أغاني للتدريب أو العرض القادم.';

  @override
  String get setlistsEmptySearch => 'لا تتطابق أي قائمة مع بحثك.';

  @override
  String get setlistCreate => 'قائمة أغاني جديدة';

  @override
  String get setlistNameHint => 'اسم قائمة الأغاني';

  @override
  String get setlistNotes => 'ملاحظات';

  @override
  String get setlistEntryOverride => 'المقام والكابو الخاصان بالأغنية';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أغنية',
      many: '$count أغنية',
      few: '$count أغانٍ',
      two: 'أغنيتان',
      one: 'أغنية واحدة',
      zero: 'لا توجد أغانٍ',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'على الأقل $duration';
  }

  @override
  String get setlistDurationUnknown => 'المدة غير معروفة';

  @override
  String setlistActivity(String date) {
    return 'آخر نشاط $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'أُنشئت في $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'عُدّلت في $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'آخر تشغيل في $date';
  }

  @override
  String get setlistSongsEmpty => 'لا تحتوي هذه القائمة على أغانٍ بعد.';

  @override
  String get setlistAddSongs => 'إضافة أغانٍ';

  @override
  String get setlistReorder => 'إعادة ترتيب الأغاني';

  @override
  String setlistMoveSongUp(String song) {
    return 'نقل $song إلى الأعلى';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'نقل $song إلى الأسفل';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'إزالة $song من قائمة الأغاني';
  }

  @override
  String get setlistDuplicate => 'إنشاء نسخة من قائمة الأغاني';

  @override
  String get setlistFavoriteAdd => 'إضافة قائمة الأغاني إلى المفضلة';

  @override
  String get setlistFavoriteRemove => 'إزالة قائمة الأغاني من المفضلة';

  @override
  String get setlistShare => 'مشاركة كملف OpenSong';

  @override
  String get setlistSharePdf => 'مشاركة كملف PDF';

  @override
  String get setlistPrint => 'طباعة';

  @override
  String get setlistDeleteConfirmTitle => 'حذف قائمة الأغاني؟';

  @override
  String get setlistDeleteConfirmMessage =>
      'ستتم إزالة قائمة الأغاني، وستبقى الأغاني في مكتبتك.';

  @override
  String get setlistDeleted => 'تم حذف قائمة الأغاني.';

  @override
  String get readerTitle => 'الكلمات';

  @override
  String get readerNoLyrics => 'لم تتم إضافة كلمات بعد.';

  @override
  String get readerShowChords => 'إظهار الأكوردات';

  @override
  String get readerHideChords => 'إخفاء الأكوردات';

  @override
  String get readerTranspose => 'نقل الأكوردات';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نصف درجة',
      many: '$count نصف درجة',
      few: '$count أنصاف درجات',
      two: 'درجتين نصفيتين',
      one: 'نصف درجة واحدة',
      zero: '0 نصف درجة',
    );
    return 'النقل بمقدار $_temp0';
  }

  @override
  String get readerSaved => 'تم الحفظ';

  @override
  String get readerEdit => 'تعديل الكلمات والتفاصيل';

  @override
  String get playerPlay => 'تشغيل';

  @override
  String get playerPause => 'إيقاف مؤقت';

  @override
  String get playerResume => 'استئناف تمرير الكلمات';

  @override
  String get playerSeek => 'موضع التشغيل';

  @override
  String playerElapsed(String time) {
    return 'الوقت المنقضي $time';
  }

  @override
  String playerRemaining(String time) {
    return 'الوقت المتبقي $time';
  }

  @override
  String get playerTimingMode => 'وضع التمرير';

  @override
  String get playerTimedLyrics => 'كلمات متزامنة';

  @override
  String get playerStartScroll => 'بدء التمرير التلقائي';

  @override
  String get playerEstimatedPace => 'سرعة تقديرية';

  @override
  String get playerScrollSpeed => 'سرعة التمرير';

  @override
  String playerEstimatedDuration(String time) {
    return 'المدة المقدرة: $time';
  }

  @override
  String get playerLyricsOnly => 'تمرير الكلمات · بدون صوت';

  @override
  String get playerManualScroll => 'تمرير يدوي';

  @override
  String get playerTimingStatusReady => 'ستتبع الكلمات التوقيت المتاح.';

  @override
  String get playerTimingStatusEstimated =>
      'تُقدّر سرعة التمرير استنادًا إلى مدة الأغنية.';

  @override
  String get playerTimingStatusManual => 'مرّر الكلمات يدويًا.';

  @override
  String get playerTimingStatusUnavailable =>
      'التمرير المتزامن غير متاح لهذه الأغنية.';

  @override
  String get playerDurationUnknown =>
      'أضف مدة الأغنية لاستخدام التمرير التقديري.';

  @override
  String get playerProgressLabel => 'تقدم الأغنية';

  @override
  String get playerCurrentSection => 'المقطع الحالي';

  @override
  String get playerPreviousSection => 'المقطع السابق';

  @override
  String get playerNextSection => 'المقطع التالي';

  @override
  String get playerPreviousSectionSong =>
      'المقطع السابق · اضغط مطولًا للانتقال إلى الأغنية السابقة في القائمة';

  @override
  String get playerNextSectionSong =>
      'المقطع التالي · اضغط مطولًا للانتقال إلى الأغنية التالية في القائمة';

  @override
  String get playerPreviousSong => 'الأغنية السابقة';

  @override
  String get playerNextSong => 'الأغنية التالية';

  @override
  String get editorTitle => 'تعديل الأغنية';

  @override
  String get editorTitleField => 'عنوان الأغنية';

  @override
  String get editorArtistField => 'الفنان';

  @override
  String get editorAlbumField => 'الألبوم';

  @override
  String get editorLyricsField => 'الكلمات';

  @override
  String get editorChordsField => 'الأكوردات';

  @override
  String get editorKeyField => 'المقام';

  @override
  String get editorCapoField => 'الكابو';

  @override
  String get editorTuningField => 'الضبط';

  @override
  String get editorTempoField => 'الإيقاع';

  @override
  String get editorDurationField => 'المدة';

  @override
  String get editorTimeSignatureField => 'الميزان';

  @override
  String get editorLanguageField => 'اللغة';

  @override
  String get editorYearField => 'السنة';

  @override
  String get editorComposerField => 'الملحن';

  @override
  String get editorLyricistField => 'كاتب الكلمات';

  @override
  String get editorCopyrightField => 'حقوق النشر';

  @override
  String get editorLicenseField => 'الترخيص';

  @override
  String get songInfoSources => 'المصادر والاعتمادات';

  @override
  String get searchMatchSameSong => 'الأغنية نفسها؛ لم يتم تأكيد التسجيل';

  @override
  String get searchMatchNeedsAgreement => 'يجب تأكيد كلمات ورقة الأكوردات';

  @override
  String get searchMatchDifferentLyrics => 'تختلف الكلمات عن الأغنية المحددة';

  @override
  String get searchMatchCombinedSources => 'تم جمع التفاصيل من مصادر متعددة';

  @override
  String get searchCombinedLabel => 'المجموعة الكاملة';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تطابق للأغاني',
      many: '$count تطابقًا للأغاني',
      few: '$count تطابقات للأغاني',
      two: 'تطابقان للأغنية',
      one: 'تطابق واحد للأغنية',
      zero: '0 تطابقات للأغاني',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إصدار للمصدر',
      many: '$count إصدارًا للمصدر',
      few: '$count إصدارات للمصدر',
      two: 'إصداران للمصدر',
      one: 'إصدار واحد للمصدر',
      zero: '0 إصدارات للمصدر',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'أفضل تطابق متاح';

  @override
  String get providerDescriptionUnknown => 'مصدر الأغنية';

  @override
  String get providerDescDownloadChordProThenImport =>
      'نزّل ملف ChordPro من المصدر، ثم استورده.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'نزّل الملف باستخدام حساب مجاني، ثم استورده.';

  @override
  String get providerDescPublicChordSheets => 'أوراق أكوردات عامة.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'كلمات تاريخية مرخصة لكل عمل.';

  @override
  String get providerDescLicensedCatalog => 'كتالوج كلمات مرخص.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'أغانٍ أصلية بترخيص Creative Commons BY.';

  @override
  String get providerDescPerSongLicense => 'كلمات مرخصة لكل أغنية.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'تفاصيل التسجيل والإصدار فقط.';

  @override
  String get providerDescCompositionMetadataOnly => 'تفاصيل التأليف فقط.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'أغلفة للتسجيلات المطابقة تمامًا فقط.';

  @override
  String get providerCapabilityLyrics => 'الكلمات';

  @override
  String get providerCapabilityChords => 'الأكوردات';

  @override
  String get providerCapabilityTiming => 'كلمات متزامنة';

  @override
  String get providerCapabilitySearch => 'البحث';

  @override
  String get providerCapabilityMetadata => 'تفاصيل الأغنية';

  @override
  String get editorArtworkField => 'رابط الغلاف';

  @override
  String get editorLyricsHint =>
      'الأوتار بين أقواس [C]؛ وعلامات المقاطع في أسطر منفصلة.';

  @override
  String get editorSave => 'حفظ التغييرات';

  @override
  String get editorSaved => 'تم حفظ التغييرات.';

  @override
  String get editorSaveFailed => 'تعذّر حفظ التغييرات.';

  @override
  String get editorSaveConflict =>
      'تم تعديل الأغنية في مكان آخر. حُفظت تعديلاتك كنسخة منفصلة.';

  @override
  String get editorUnsavedTitle => 'هل تريد تجاهل التغييرات؟';

  @override
  String get editorUnsavedMessage => 'لم يتم حفظ تغييراتك.';

  @override
  String get editorFieldRequired => 'أدخل عنوان الأغنية.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get settingsThemeSystem => 'استخدام إعداد الجهاز';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsColorPalette => 'لوحة الألوان';

  @override
  String get settingsFont => 'الخط';

  @override
  String get settingsTextSize => 'حجم النص';

  @override
  String get settingsLyricsPreview => 'معاينة الكلمات';

  @override
  String get settingsPlayer => 'مشغل الكلمات';

  @override
  String get settingsLyricHighlight => 'تمييز السطر الحالي';

  @override
  String get settingsHighlightBackgroundUnderline => 'خلفية + تسطير';

  @override
  String get settingsHighlightBackground => 'خلفية';

  @override
  String get settingsHighlightUnderline => 'تسطير';

  @override
  String get settingsHighlightContrast => 'لون نص متباين';

  @override
  String get settingsHighlightNone => 'بلا';

  @override
  String get settingsDefaultShowChords => 'إظهار الأكوردات افتراضيًا';

  @override
  String get settingsDefaultAutoscroll => 'بدء تمرير الكلمات تلقائيًا';

  @override
  String get settingsDefaultTiming => 'وضع التمرير الافتراضي';

  @override
  String get settingsLanguage => 'لغة التطبيق';

  @override
  String get settingsLanguageSystem => 'استخدام لغة الجهاز';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'مصادر الكلمات';

  @override
  String settingsSourceEnabled(String source) {
    return 'تفعيل المصدر $source';
  }

  @override
  String get settingsSourceRefresh => 'تحديث قائمة المصادر';

  @override
  String get settingsSourcesUpdated => 'تم تحديث المصادر.';

  @override
  String get settingsSourcesUpdateFailed => 'تعذّر تحديث المصادر.';

  @override
  String get settingsImport => 'استيراد الأغاني';

  @override
  String get settingsImportChordPro => 'استيراد ملف ChordPro';

  @override
  String get settingsImportSetlist => 'استيراد ملف قائمة أغاني';

  @override
  String get settingsImportSuccess => 'اكتمل الاستيراد.';

  @override
  String get settingsImportFailed => 'تعذّر استيراد هذا الملف.';

  @override
  String get settingsImportUnsupported => 'نوع الملف هذا غير مدعوم.';

  @override
  String get settingsShareSong => 'مشاركة كـ ChordPro';

  @override
  String get settingsSharePdf => 'مشاركة كـ PDF';

  @override
  String get settingsCopySong => 'نسخ إلى الحافظة';

  @override
  String get settingsPrintSong => 'طباعة الأغنية فقط';

  @override
  String get settingsPrintSetlist => 'طباعة قائمة الأغاني مع الكلمات';

  @override
  String get settingsExportFailed => 'تعذّر تجهيز الملف.';

  @override
  String get settingsCopied => 'تم النسخ إلى الحافظة.';

  @override
  String get settingsAbout => 'حول';

  @override
  String get settingsPrivacy => 'الخصوصية';

  @override
  String get settingsLegal => 'معلومات قانونية';

  @override
  String get settingsClearHistory => 'مسح السجل';

  @override
  String get settingsClearHistoryConfirm => 'هل تريد مسح سجل الأغاني وقوائمها؟';

  @override
  String get settingsHistoryCleared => 'تم مسح السجل.';

  @override
  String get accountTitle => 'الحساب والمزامنة';

  @override
  String get accountUnavailable =>
      'تتطلب المزامنة إصدارًا من Singbook تم إعداد تسجيل الدخول إلى Google فيه. يحتفظ هذا الإصدار بأغانيك على هذا الجهاز فقط.';

  @override
  String get accountSyncNow => 'مزامنة الآن';

  @override
  String get accountConnected =>
      'تم الربط. اختر «مزامنة الآن» لتحديث النسخة الاحتياطية.';

  @override
  String get accountSignIn => 'ربط حساب';

  @override
  String get accountSignOut => 'تسجيل الخروج';

  @override
  String get accountChange => 'تغيير الحساب';

  @override
  String get accountSignedOut => 'غير مرتبط';

  @override
  String get accountSyncing => 'جارٍ مزامنة مكتبتك…';

  @override
  String get accountSynced => 'تمت مزامنة المكتبة.';

  @override
  String get accountSyncFailed => 'تعذّرت مزامنة مكتبتك.';

  @override
  String get accessibilityFavorite => 'مفضل';

  @override
  String get accessibilityNotFavorite => 'ليس مفضلًا';

  @override
  String get accessibilitySearchField => 'البحث عن الأغاني';

  @override
  String get accessibilityClearSearch => 'مسح نص البحث';

  @override
  String accessibilitySongMenu(String song) {
    return 'إجراءات $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'إجراءات $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'توسيع الأغاني في $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'طي الأغاني في $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'تقدم التشغيل، $percent بالمئة';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'الخط الزمني للسجل، $date';
  }

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get loadingSongs => 'جارٍ تحميل الأغاني…';

  @override
  String get loadingSetlists => 'جارٍ تحميل القوائم…';

  @override
  String get errorGeneric => 'حدث خطأ ما.';

  @override
  String get errorOffline => 'يبدو أنك غير متصل بالإنترنت.';

  @override
  String get errorPermission => 'يلزم الحصول على إذن للمتابعة.';

  @override
  String get emptyFiltered => 'لا تتطابق أي عناصر مع هذه الفلاتر.';

  @override
  String get unknownValue => 'غير معروف';

  @override
  String get durationUnknown => 'المدة غير معروفة';

  @override
  String get metadataNotSet => 'غير محدد';

  @override
  String get dateToday => 'اليوم';

  @override
  String get dateYesterday => 'أمس';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أغنية',
      many: '$count أغنية',
      few: '$count أغانٍ',
      two: 'أغنيتان',
      one: 'أغنية واحدة',
      zero: 'لا توجد أغانٍ',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'أزرق داكن';

  @override
  String get settingsPaletteSage => 'أخضر المريمية';

  @override
  String get settingsPaletteOcean => 'المحيط';

  @override
  String get settingsPaletteClay => 'طيني';

  @override
  String get settingsPalettePlum => 'برقوقي';

  @override
  String get settingsFontSystem => 'النظام';

  @override
  String get settingsFontSerif => 'ذو زوائد';

  @override
  String get settingsFontMonospace => 'أحادي المسافة';

  @override
  String get settingsLyricsPreviewExample => 'عندما يأتي الصباح، سنغني مجددًا.';

  @override
  String get settingsPreviewSongTitle => 'ترنيمة الصباح';

  @override
  String get settingsPreviewArtist => 'ترتيب موسيقي نموذجي';

  @override
  String get settingsPreviewCurrentLine => 'عندما يأتي الصباح';

  @override
  String get settingsPreviewNextLine => 'سنغني مجددًا.';

  @override
  String get settingsPlayerSections => 'عناوين الأقسام';

  @override
  String get settingsPlayerControls => 'لوحة التشغيل';

  @override
  String get settingsPlayerAutoscroll => 'التمرير التلقائي';

  @override
  String get settingsSystemShort => 'الجهاز';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'جارٍ التحقق من مصادر الكلمات: اكتمل $checked من $total.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'لم يتم العثور على كلمات قابلة للاستخدام.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'تم التحقق من الأغنية المحددة في المصادر المفعّلة، لكن لم يُرجع أي منها نسخة كلمات قابلة للاستخدام.';

  @override
  String get searchDiscoveryError => 'تعذّر التحقق من مصادر الكلمات.';

  @override
  String get searchDiscoveryRetry => 'إعادة البحث عن الكلمات';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مصدر غير متاح',
      many: '$count مصدرًا غير متاح',
      few: '$count مصادر غير متاحة',
      two: 'مصدران غير متاحين',
      one: 'مصدر واحد غير متاح',
      zero: '0 مصادر غير متاحة',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'تحقق من اتصالك ثم حاول مرة أخرى.';

  @override
  String get searchProviderChecks => 'عمليات التحقق من المصادر';

  @override
  String get searchProviderPending => 'جارٍ التحقق';

  @override
  String get searchProviderFound => 'تم العثور على تطابق';

  @override
  String get searchProviderRejected => 'غير مطابق';

  @override
  String get searchProviderFailed => 'فشل التحقق';

  @override
  String get searchProviderUnavailable => 'لا توجد كلمات قابلة للاستخدام';

  @override
  String get searchCatalogFilterHint =>
      'اختر أغنية لتصفية نسخ الكلمات حسب الأكوردات أو التوقيت أو اللغة.';

  @override
  String get startupErrorTitle => 'تعذّر فتح مكتبتك.';

  @override
  String setlistCopyName(String name) {
    return 'نسخة من $name';
  }

  @override
  String get setlistSongMissing => 'أغنية مفقودة';

  @override
  String get settingsImportTooLarge => 'هذا الملف كبير جدًا لاستيراده.';

  @override
  String songsJumpToLetter(String letter) {
    return 'الانتقال إلى $letter';
  }

  @override
  String get actionDiscard => 'تجاهل';

  @override
  String get editorKeepEditing => 'متابعة التعديل';

  @override
  String get settingsDefaultShowChordsHint =>
      'إظهار الأكوردات فوق الكلمات عندما تحتوي الأغنية عليها.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'تتحرك الكلمات مع الأغنية. لا يُستخدم ذلك في وضع التمرير اليدوي.';

  @override
  String get accountUnavailableTitle => 'المزامنة غير مُعدّة';

  @override
  String get accountSignedOutBenefits =>
      'يؤدي ربط Google Drive إلى مزامنة مكتبتك. وستتم مزامنة تغييرات الأغاني تلقائيًا بعد ذلك.';

  @override
  String get accountManualSyncHint =>
      'يمكنك أيضًا الضغط على «مزامنة الآن» لمزامنة مكتبتك.';

  @override
  String get accountSignInWithGoogle => 'تسجيل الدخول باستخدام Google';

  @override
  String get accountWorking => 'جارٍ العمل…';

  @override
  String get accountNeverSynced => 'لم تتم المزامنة مطلقًا';

  @override
  String get accountSyncedJustNow => 'تمت المزامنة للتو';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت المزامنة قبل $count دقيقة',
      many: 'تمت المزامنة قبل $count دقيقة',
      few: 'تمت المزامنة قبل $count دقائق',
      two: 'تمت المزامنة قبل دقيقتين',
      one: 'تمت المزامنة قبل دقيقة واحدة',
      zero: 'تمت المزامنة قبل 0 دقيقة',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت المزامنة قبل $count ساعة',
      many: 'تمت المزامنة قبل $count ساعة',
      few: 'تمت المزامنة قبل $count ساعات',
      two: 'تمت المزامنة قبل ساعتين',
      one: 'تمت المزامنة قبل ساعة واحدة',
      zero: 'تمت المزامنة قبل 0 ساعة',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت المزامنة قبل $count يوم',
      many: 'تمت المزامنة قبل $count يومًا',
      few: 'تمت المزامنة قبل $count أيام',
      two: 'تمت المزامنة قبل يومين',
      one: 'تمت المزامنة قبل يوم واحد',
      zero: 'تمت المزامنة قبل 0 يوم',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم حفظ $count تعديل متعارض كنسخة',
      many: 'تم حفظ $count تعديلًا متعارضًا كنسخ',
      few: 'تم حفظ $count تعديلات متعارضة كنسخ',
      two: 'تم حفظ تعديلين متعارضين كنسختين',
      one: 'تم حفظ تعديل متعارض واحد كنسخة',
      zero: 'لا توجد تعديلات متعارضة محفوظة كنسخ',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'تم تعديل الأغنية أو قائمة الأغاني نفسها في مكانين. لم يضع شيء: تم حفظ الإصدار الآخر كنسخة منفصلة.';

  @override
  String get accountReviewConflicts => 'مراجعة النسخ';

  @override
  String get songsConflictFilterActive => 'عرض النسخ المتعارضة فقط';

  @override
  String get songsConflictFilterClear => 'إظهار جميع الأغاني';

  @override
  String get songsConflictBadge => 'نسخة متعارضة';

  @override
  String get songsConflictEmpty => 'لا توجد نسخ متعارضة.';

  @override
  String get accountAutoSync => 'مزامنة تلقائية';

  @override
  String get accountAutoSyncHint =>
      'تتم المزامنة بعد الاتصال وبعد إضافة أغنية أو تعديلها أو حذفها.';

  @override
  String get accountDriveFolder => 'مجلد مكتبة جوجل درايف';

  @override
  String get accountPrivateDriveFolder => 'مجلد Singbook الخاص';

  @override
  String get accountChooseDriveFolder => 'اختر المجلد';

  @override
  String get accountDriveFolderMoveTitle => 'نقل مكتبة Singbook الخاصة بك؟';

  @override
  String get accountDriveFolderMoveBody =>
      'اختر مجلد Google Drive مرئيًا. سيقوم Singbook بنسخ الأغاني وقوائم الأغاني الخاصة بك والتحقق منها هناك قبل التبديل إليها. تبقى الملفات الأصلية في موقعها السابق كنسخة احتياطية. يتم ترك الملفات الأخرى وحدها. يتم اعتماد ملفات ChordPro التي تستوردها في هذا المجلد للمزامنة واستقبال البيانات التعريفية لـ Singbook.';

  @override
  String get accountImportChordPro => 'استيراد ChordPro من Drive';

  @override
  String get accountImportChordProHint =>
      'اختر ملفات .cho لإضافتها إلى هذه المكتبة. تم اعتماد الملفات الموجودة بالفعل في المجلد؛ يتم نسخ الملفات في مكان آخر هنا.';

  @override
  String get syncErrorFolderPickerUnavailable => 'تحديد مجلد Drive غير متاح';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'اختر مجلد Drive مرئيًا باستخدام أداة اختيار Google Drive على جهاز مدعوم.';

  @override
  String get syncErrorDriveFolderMissing => 'مجلد Singbook Drive غير متوفر';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'اختر المجلد مرة أخرى، أو استعادته في Google Drive.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'يحتاج Singbook إلى الوصول إلى مجلد Drive هذا';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'اختر المجلد مرة أخرى لمنح الوصول، ثم قم بمزامنة مكتبتك.';

  @override
  String get syncErrorFolderMigration => 'لا يمكن نقل المكتبة بعد';

  @override
  String get syncErrorFolderMigrationHint =>
      'مكتبتك السابقة لا تزال آمنة. تحقق من الاتصال واختر المجلد مرة أخرى لإعادة المحاولة.';

  @override
  String get syncErrorVisibleFolderRequired => 'اختر مجلد Drive مرئيًا أولاً';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'يلزم وجود مجلد مكتبة مرئي قبل استيراد الملفات من Drive.';

  @override
  String get accountSignOutTitle => 'تسجيل الخروج من هذا الحساب؟';

  @override
  String get accountSignOutBody =>
      'ستبقى أغانيك وقوائمك على هذا الجهاز. لن يتم نسخها احتياطيًا أو مزامنتها حتى تسجل الدخول مجددًا.';

  @override
  String get accountUseDifferent => 'استخدام حساب آخر';

  @override
  String get accountSignInAgain => 'تسجيل الدخول مجددًا';

  @override
  String get accountChooseAction => 'اختر كيفية المتابعة';

  @override
  String get accountChangedTitle => 'حساب Google مختلف';

  @override
  String get accountChangedBody =>
      'تمت مزامنة هذا الجهاز آخر مرة مع حساب Google آخر. اختر ما يجب فعله بالأغاني والقوائم الموجودة على هذا الجهاز.';

  @override
  String get accountChangedMerge => 'الدمج مع الحساب الجديد';

  @override
  String get accountChangedMergeHint =>
      'احتفظ بكل شيء على هذا الجهاز وأضفه إلى الحساب الجديد.';

  @override
  String get accountChangedReplace => 'الاستبدال بمكتبة الحساب الجديد';

  @override
  String get accountChangedReplaceHint =>
      'ستتم إزالة الأغاني الموجودة على هذا الجهاز وغير الموجودة في الحساب الجديد.';

  @override
  String get accountChangedSignOut => 'إلغاء وتسجيل الخروج';

  @override
  String get accountStatusSignedOut => 'الحساب والمزامنة: لم يتم تسجيل الدخول';

  @override
  String get accountStatusSignedIn => 'الحساب والمزامنة: تم تسجيل الدخول';

  @override
  String get accountStatusSyncing => 'الحساب والمزامنة: جارٍ المزامنة';

  @override
  String get accountStatusSynced => 'الحساب والمزامنة: المكتبة محدّثة';

  @override
  String get accountStatusError => 'الحساب والمزامنة: مشكلة، المس للمراجعة';

  @override
  String get accountNoticeConflicts =>
      'تم تعديل بعض الأغاني في مكانين. تم الاحتفاظ بالنسخ.';

  @override
  String get accountNoticeSignedIn => 'تم تسجيل الدخول.';

  @override
  String get accountNoticeSignedOut =>
      'تم تسجيل الخروج. ستبقى أغانيك على هذا الجهاز.';

  @override
  String get syncErrorNotConfigured => 'المزامنة غير مُعدّة في هذا الإصدار.';

  @override
  String get syncErrorNotConfiguredHint =>
      'استخدم إصدارًا من Singbook مُعَدًّا لتسجيل الدخول إلى Google.';

  @override
  String get syncErrorNotSignedIn => 'لم تسجل الدخول.';

  @override
  String get syncErrorNotSignedInHint => 'سجّل الدخول لمزامنة مكتبتك.';

  @override
  String get syncErrorAuthorizationRequired =>
      'تطلب Google تسجيل الدخول مرة أخرى.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'سجّل الدخول مرة أخرى لمتابعة المزامنة. أغانيك آمنة على هذا الجهاز.';

  @override
  String get syncErrorAccessDenied =>
      'ليس لدى Singbook إذن لاستخدام Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'سجّل الدخول مجددًا واسمح بالوصول إلى Drive عند الطلب.';

  @override
  String get syncErrorRateLimited => 'تقيّد Google الطلبات حاليًا.';

  @override
  String get syncErrorRateLimitedHint => 'انتظر بضع دقائق ثم حاول مرة أخرى.';

  @override
  String get syncErrorStorageFull => 'مساحة Google Drive ممتلئة.';

  @override
  String get syncErrorStorageFullHint =>
      'أفرغ بعض المساحة في Drive ثم حاول مرة أخرى.';

  @override
  String get syncErrorNetwork => 'تعذّر الوصول إلى Google.';

  @override
  String get syncErrorNetworkHint => 'تحقق من اتصال الإنترنت ثم حاول مرة أخرى.';

  @override
  String get syncErrorAccountChanged => 'تم استخدام حساب Google مختلف.';

  @override
  String get syncErrorAccountChangedHint =>
      'اختر ما إذا كنت تريد دمج مكتبة هذا الجهاز مع الحساب أو استبدالها.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'مكتبتك المتزامنة أكبر مما يستطيع Singbook التعامل معه.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'أزل بعض الأغاني أو القوائم من المكتبة المتزامنة ثم حاول مرة أخرى.';

  @override
  String get syncErrorSignInFailed => 'لم يكتمل تسجيل الدخول.';

  @override
  String get syncErrorSignInFailedHint => 'حاول تسجيل الدخول مرة أخرى.';

  @override
  String get syncErrorGeneric => 'تعذّرت مزامنة مكتبتك.';

  @override
  String get syncErrorGenericHint =>
      'حاول مرة أخرى بعد قليل. لا تزال أغانيك آمنة على هذا الجهاز.';

  @override
  String get editorDurationInvalid => 'أدخل ثواني، أو دقائق وثواني، مثل 3:45.';

  @override
  String get editorNumberInvalid => 'أدخل رقمًا.';

  @override
  String get accountReplaceConfirmTitle => 'حذف الأغاني المحلية؟';

  @override
  String get accountReplaceConfirmBody =>
      'ستُحذف نهائيًا الأغاني وقوائم الأغاني الموجودة على هذا الجهاز وغير الموجودة في الحساب الجديد. لا يمكن التراجع عن ذلك.';

  @override
  String get accountReplaceConfirmAction => 'حذف واستبدال';

  @override
  String get accountSuspiciousTitle => 'عناصر مفقودة من Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر سبق لهذا الجهاز مزامنته مفقود من Google Drive.',
      many: '$count عنصرًا سبق لهذا الجهاز مزامنته مفقود من Google Drive.',
      few: '$count عناصر سبق لهذا الجهاز مزامنتها مفقودة من Google Drive.',
      two: 'عنصران سبق لهذا الجهاز مزامنتهما مفقودان من Google Drive.',
      one: 'عنصر واحد سبق لهذا الجهاز مزامنته مفقود من Google Drive.',
      zero: 'لا توجد عناصر سبق لهذا الجهاز مزامنتها مفقودة من Google Drive.',
    );
    return '$_temp0 قد يحدث هذا إذا مُسحت بيانات التطبيق من إعدادات Google. لم يُحذف أي شيء بعد.';
  }

  @override
  String get accountSuspiciousDelete => 'احذفها هنا أيضًا';

  @override
  String get accountSuspiciousKeep => 'احتفظ بأغنياتي وارفعها مرة أخرى';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حذف $count عنصر من هذا الجهاز؟',
      many: 'حذف $count عنصرًا من هذا الجهاز؟',
      few: 'حذف $count عناصر من هذا الجهاز؟',
      two: 'حذف عنصرين من هذا الجهاز؟',
      one: 'حذف عنصر واحد من هذا الجهاز؟',
      zero: 'حذف 0 عنصر من هذا الجهاز؟',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'ستُحذف هذه الأغاني وقوائم الأغاني نهائيًا من هذا الجهاز. لا يمكن التراجع عن ذلك.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'الحذف من هذا الجهاز';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'توجد عناصر مفقودة من Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'لم يُحذف شيء. اختر ما إذا كنت تريد حذفها هنا أيضًا أم إعادة رفعها.';

  @override
  String get syncErrorRemoteChanged => 'تغيّر Google Drive أثناء المزامنة.';

  @override
  String get syncErrorRemoteChangedHint =>
      'لم يُفقد أي شيء. أعد المزامنة لجلب أحدث التغييرات.';

  @override
  String get syncErrorInvalidLocalData =>
      'تعذّرت مزامنة بعض البيانات على هذا الجهاز.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'تعذرت قراءة أغنية أو قائمة أغاني. استوردها أو أنشئها من جديد، ثم أعد المزامنة.';

  @override
  String get syncErrorNoAccountChange =>
      'لا يوجد تغيير في الحساب يحتاج إلى معالجة.';

  @override
  String get syncErrorNoAccountChangeHint => 'أعد المزامنة للمتابعة.';

  @override
  String get accountSyncWarningTitle => 'تمت المزامنة، لكن تم تخطي بعض الملفات';

  @override
  String get accountSyncWarningBody =>
      'تعذّر استخدام بعض الملفات، فبقيت كما هي. كل ما عدا ذلك محدّث.';

  @override
  String get accountSyncWarningTooLarge =>
      'كان أحد الملفات كبيرًا جدًا للمزامنة، لذا تم تخطيه. كل ما عدا ذلك محدّث.';

  @override
  String get accountSyncWarningInvalid =>
      'تعذّرت قراءة أحد الملفات، لذا تم تخطيه. كل ما عدا ذلك محدّث.';

  @override
  String get accountNoticeSyncSkipped => 'تمت المزامنة. تم تخطي بعض الملفات.';

  @override
  String get settingsExportPdfTooLarge =>
      'سيكون ملف PDF هذا كبيرًا جدًا. جرّب عددًا أقل من الأغاني أو شاركه كنص.';

  @override
  String get settingsTimingTooLarge =>
      'بيانات التوقيت كبيرة جدًا (أكثر من 3 ميغابايت).';

  @override
  String get settingsImportDuplicateSongId =>
      'تتضمن هذه النسخة الاحتياطية الأغنية نفسها مرتين، لذا لم يتم استيراد أي شيء.';

  @override
  String get setlistSaveConflict =>
      'تم تغيير قائمة الأغاني في مكان آخر. تم حفظ تعديلاتك كنسخة منفصلة.';

  @override
  String get sectionVerse => 'مقطع';

  @override
  String get sectionChorus => 'اللازمة';

  @override
  String get sectionBridge => 'جسر';

  @override
  String get sectionIntro => 'مقدمة';

  @override
  String get sectionOutro => 'خاتمة';

  @override
  String get sectionPreChorus => 'ما قبل اللازمة';

  @override
  String get sectionPostChorus => 'ما بعد اللازمة';

  @override
  String get sectionInstrumental => 'مقطع موسيقي';

  @override
  String get sectionInterlude => 'فاصل موسيقي';

  @override
  String get sectionSolo => 'سولو';

  @override
  String get sectionRefrain => 'ترديدة';

  @override
  String get sectionHook => 'هوك';

  @override
  String get sectionBreakdown => 'بريك داون';

  @override
  String get sectionCoda => 'كودا';

  @override
  String get sectionTag => 'تاغ';

  @override
  String get sectionEnding => 'النهاية';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إصدار جاهز',
      many: '$count إصدارًا جاهزًا',
      few: '$count إصدارات جاهزة',
      two: 'إصداران جاهزان',
      one: 'إصدار جاهز واحد',
      zero: 'لا توجد إصدارات جاهزة',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إصدار غير متاح',
      many: '$count إصدارًا غير متاح',
      few: '$count إصدارات غير متاحة',
      two: 'إصداران غير متاحين',
      one: 'إصدار واحد غير متاح',
      zero: 'لا توجد إصدارات غير متاحة',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'الانتقال إلى القسم';

  @override
  String get searchVersionDetails => 'تفاصيل الإصدار';

  @override
  String get searchSelectedRecording => 'التسجيل المحدد';

  @override
  String get searchVersionDuration => 'مدة الإصدار';

  @override
  String get searchSourceOptions => 'خيارات المصدر';

  @override
  String get actionUndo => 'تراجع';

  @override
  String setlistEntryRemoved(String song) {
    return 'تمت إزالة $song من قائمة الأغاني';
  }

  @override
  String get backupTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupExport => 'تصدير نسخة احتياطية';

  @override
  String get backupRestore => 'استعادة نسخة احتياطية';

  @override
  String get backupIncludePreferences => 'تضمين تفضيلات التطبيق';

  @override
  String get backupRestorePreferences => 'استعادة تفضيلات التطبيق';

  @override
  String get backupMerge => 'إضافة إلى هذه المكتبة';

  @override
  String get backupMergeHint =>
      'احتفظ بالتعديلات المحلية وأضف الأغاني والقوائم من هذه النسخة الاحتياطية.';

  @override
  String get backupReplace => 'استبدال هذه المكتبة';

  @override
  String get backupReplaceHint =>
      'استبدل جميع الأغاني والقوائم على هذا الجهاز بمحتوى هذه النسخة الاحتياطية.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'الأغاني: $songs · القوائم: $setlists · التعارضات: $conflicts';
  }

  @override
  String get backupFailed =>
      'تعذّر إكمال عملية النسخ الاحتياطي. حاول مرة أخرى.';

  @override
  String get backupRestored => 'تمت استعادة النسخة الاحتياطية.';

  @override
  String get backupLocalHint =>
      'احفظ نسخة من مكتبتك. لا تُضمّن بيانات الحساب أو ملفات تعريف الارتباط للموافقة.';

  @override
  String get backupReplaceConfirm =>
      'هل تريد استبدال المكتبة الحالية؟ لا يمكن التراجع عن ذلك.';

  @override
  String get searchCheckOperations => 'العمليات';

  @override
  String get searchCheckCode => 'رمز النتيجة';

  @override
  String get searchCheckQueued => 'بانتظار التحقق من هذا المصدر.';

  @override
  String get searchCheckFetch => 'تحميل كلمات الأغنية';

  @override
  String get searchCheckValidate => 'التحقق من تطابق الأغنية';

  @override
  String get searchCheckCorroborate => 'التحقق من تطابق الكلمات';

  @override
  String get searchCheckCompleted => 'اكتمل';

  @override
  String get searchCheckTimeout => 'لم يستجب المصدر في الوقت المحدد.';

  @override
  String get searchCheckBlocked => 'حظر المصدر الطلب.';

  @override
  String get searchCheckRateLimited => 'يحدّ المصدر من الطلبات. حاول لاحقًا.';

  @override
  String get searchCheckNetwork => 'تعذر الوصول إلى المصدر. تحقق من اتصالك.';

  @override
  String get searchCheckInvalid => 'أعاد المصدر استجابة غير قابلة للقراءة.';

  @override
  String get searchCheckNotConfigured => 'هذا المصدر غير مُعدّ في هذا الإصدار.';

  @override
  String get searchCheckNoLyrics => 'لم تُعثر على كلمات مطابقة.';

  @override
  String get searchCheckFailed => 'تعذر إكمال هذه العملية.';

  @override
  String get searchCheckNoHistory =>
      'لم تُجرَ أي عمليات تحقق من المصادر لهذه المقارنة.';

  @override
  String get searchVersionCredits => 'الاعتمادات';

  @override
  String get searchVersionMediaLinks => 'روابط ذات صلة';

  @override
  String get searchCheckCancelled => 'أُلغيت';

  @override
  String get searchCheckAmbiguous =>
      'عُثر على عدة نتائج. يحتاج هذا المصدر إلى تسجيل أكثر تحديدًا.';

  @override
  String get searchCheckIdentity => 'يحتاج هذا المصدر إلى معرّف تسجيل أو عمل.';

  @override
  String get searchCheckExtraction =>
      'استجاب المصدر، لكن تعذّر استخراج الكلمات.';

  @override
  String get searchCheckBusy => 'المصدر مشغول. حاول لاحقًا.';

  @override
  String get searchCheckSelection => 'اختر نتيجة محددة من هذا المصدر.';

  @override
  String get playerChordsNone => 'لا شيء';

  @override
  String get editorCustomValue => 'أخرى…';

  @override
  String get editorStandardTuning => 'قياسي';

  @override
  String get editorExampleVerse =>
      '[C]يوم جديد [G]ينادينا،\n[Am]والنور يقودنا إلى [F]البيت.';

  @override
  String get editorExampleChorus =>
      '[F]لنغنِّ هذه الأغنية [C]معًا،\n[G]ولتأخذنا الألحان [C]بعيدًا.';

  @override
  String get editorExampleBridge => '[Am]سطر آخر، وخطوة [F]أقرب.';

  @override
  String get playerEstimatedKey => 'المفتاح المُقدّر';

  @override
  String get songsLibraryView => 'المكتبة';

  @override
  String get settingsStartupView => 'ابدأ في';

  @override
  String get settingsStartupViewHint =>
      'اختر عرض الأغاني الذي يظهر عند فتح التطبيق.';

  @override
  String get settingsStartupLastView => 'آخر عرض مفتوح';

  @override
  String get playerFullScreen => 'ملء الشاشة';

  @override
  String get playerExitFullScreen => 'الخروج من ملء الشاشة';

  @override
  String get playerExpandControls => 'إظهار عناصر التحكم بالتشغيل';

  @override
  String get playerCollapseControls => 'إخفاء عناصر التحكم بالتشغيل';

  @override
  String get settingsShowSections => 'إظهار عناوين الأقسام';

  @override
  String get settingsShowSectionsHint =>
      'أظهر عناوين المقاطع والكورس والأقسام الأخرى في كلمات الأغاني.';

  @override
  String get settingsShowPlayerControls => 'إظهار عناصر التحكم بالتشغيل';

  @override
  String get settingsShowPlayerControlsHint =>
      'يمكنك أيضًا النقر على لوحة المشغّل أو تمريرها لإظهارها أو إخفائها.';
}
