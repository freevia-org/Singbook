// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Şarkı sözleriniz, akorlarınız ve set listeleriniz bir arada; prova, sahne ve çaldığınız her yer için hazır.';

  @override
  String get aboutMadeForSinging => 'Her şarkı, söylemeye hazır.';

  @override
  String get aboutDetails =>
      'Kullanılabilir kaynaklarda arama yapın; çalmak istediğiniz sürümü kaydetmeden önce şarkı sözlerini, akorları, zamanlamayı ve kayıt bilgilerini karşılaştırın. Kullanılabilirlik şarkıya ve hizmete göre değişir.';

  @override
  String get aboutFindTitle => 'Doğru sürümü bulun';

  @override
  String get aboutKeepTitle => 'Kendi kitaplığınızı oluşturun';

  @override
  String get aboutKeepDetails =>
      'Şarkıları düzenleyip transpoze edin, çevrimdışı kullanmak için yerel kitaplığınızda tutun ve taşınabilir ChordPro dosyalarını paylaşın. İsteğe bağlı Google Drive eşitlemesi, Google hesabınızdaki özel bir uygulama klasörünü kullanır. Cihazlarınızı güncellemek için “Şimdi eşitle”ye de dokunabilirsiniz.';

  @override
  String get aboutPlayTitle => 'Set listenizi sahneye taşıyın';

  @override
  String get aboutPlayDetails =>
      'Şarkıları set listelerinde sıralayın, her şarkı için bir ton seçin ve OpenSong set listelerini paylaşın. Okuyucu metninin boyutunu ayarlayın, şarkı sözlerini otomatik kaydırın ve şarkı PDF’lerini yazdırın. Singbook ses akışı sağlamaz veya ses çalmaz.';

  @override
  String get aboutPrivacyTitle => 'Ücretsiz ve öncelikle yerel';

  @override
  String get aboutPrivacyDetails =>
      'Singbook ücretsizdir; reklam, analiz veya uygulama içi satın alma içermez. Kaydedilen kitaplığınız cihazınızda kalır; isteğe bağlı eşitleme kendi Google Drive hesabınızı kullanır. Çevrimiçi sonuçlar bağımsız üçüncü taraf hizmetlerden doğrudan gelir ve kullanılamayabilir ya da telif hakkıyla korunuyor olabilir. Singbook bu içerikleri barındırmaz.';

  @override
  String get aboutWebsite => 'Singbook web sitesi';

  @override
  String get aboutSourceCode => 'GitHub’da kaynak kodu';

  @override
  String get aboutPublisher => 'Freevia tarafından';

  @override
  String aboutLanguages(int count) {
    return 'Uygulama dilleri: $count';
  }

  @override
  String get aboutSupport => 'Destek ve geri bildirim';

  @override
  String get menuTypeNewSong => 'Yeni bir şarkı yazın';

  @override
  String appVersion(String version) {
    return 'Sürüm $version';
  }

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navSongs => 'Şarkılar';

  @override
  String get navSetlists => 'Şarkı listeleri';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get navSettingsCompact => 'Ayarlar';

  @override
  String get navSearch => 'Ara';

  @override
  String get navBack => 'Geri';

  @override
  String get appExitBackAgain => 'Çıkmak için Geri düğmesine tekrar basın';

  @override
  String get navClose => 'Kapat';

  @override
  String get navMore => 'Diğer işlemler';

  @override
  String get actionCancel => 'İptal';

  @override
  String get actionSave => 'Kaydet';

  @override
  String get actionDone => 'Tamam';

  @override
  String get actionEdit => 'Düzenle';

  @override
  String get actionDelete => 'Sil';

  @override
  String get actionShare => 'Paylaş';

  @override
  String get actionPrint => 'Yazdır';

  @override
  String get actionCopy => 'Kopyala';

  @override
  String get actionClear => 'Temizle';

  @override
  String get actionRetry => 'Tekrar dene';

  @override
  String get actionRefresh => 'Yenile';

  @override
  String get actionImport => 'İçe aktar';

  @override
  String get actionExport => 'Dışa aktar';

  @override
  String get actionExpand => 'Genişlet';

  @override
  String get actionCollapse => 'Daralt';

  @override
  String get actionAdd => 'Ekle';

  @override
  String get actionCreate => 'Oluştur';

  @override
  String get actionRemove => 'Kaldır';

  @override
  String get actionDuplicate => 'Çoğalt';

  @override
  String get actionMoveUp => 'Yukarı taşı';

  @override
  String get actionMoveDown => 'Aşağı taşı';

  @override
  String get actionPrevious => 'Önceki';

  @override
  String get actionNext => 'Sonraki';

  @override
  String get searchHint => 'Şarkı, sanatçı veya şarkı sözü ara';

  @override
  String get searchCatalogHint => 'Bir şarkı veya sanatçı ara';

  @override
  String get searchChangeSong => 'Şarkıyı değiştir';

  @override
  String get searchSelectedPreview => 'Seçili önizleme';

  @override
  String get searchSubmit => 'Ara';

  @override
  String get searchFilters => 'Arama seçenekleri';

  @override
  String get searchFiltersShow => 'Arama seçeneklerini göster';

  @override
  String get searchFiltersHide => 'Arama seçeneklerini gizle';

  @override
  String get searchFilterArtist => 'Sanatçı';

  @override
  String get searchFilterTitle => 'Şarkı adı';

  @override
  String get searchFilterLyrics => 'Şarkı sözleri';

  @override
  String get searchFilterChords => 'Akor içeriyor';

  @override
  String get searchFilterTimed => 'Zamanlanmış şarkı sözleri';

  @override
  String get searchFilterLanguage => 'Dil';

  @override
  String get searchFilterAll => 'Tümü';

  @override
  String get searchAutocompleteLabel => 'Öneriler';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sonuç',
      one: '1 sonuç',
      zero: 'Sonuç yok',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Aramak için bir şarkı, sanatçı veya şarkı sözü girin.';

  @override
  String get searchCatalogEmptyQuery =>
      'Aramak için bir şarkı veya sanatçı girin.';

  @override
  String get searchNoResults => 'Şarkı bulunamadı. Farklı bir arama deneyin.';

  @override
  String get searchLoading => 'Şarkılar aranıyor…';

  @override
  String get searchError => 'Arama tamamlanamadı.';

  @override
  String get searchOnlineTab => 'Çevrimiçi';

  @override
  String get searchRecentTab => 'Son aramalar';

  @override
  String get searchFavoritesTab => 'Favoriler';

  @override
  String get searchSuggested => 'Önerilen eşleşme';

  @override
  String get searchAlternatives => 'Diğer eşleşmeler';

  @override
  String get searchCompare => 'Sürümleri karşılaştır';

  @override
  String get searchChooseVersion => 'Bu sürümü seç';

  @override
  String get searchFullPreview => 'Tam önizleme';

  @override
  String get searchArrangementNotes => 'Aranjman notları';

  @override
  String get searchOpenLyrics => 'Şarkı sözlerini aç';

  @override
  String get searchContributions => 'Kullanılan kaynaklar';

  @override
  String get searchVersionChecking => 'Bu sürüm kontrol ediliyor…';

  @override
  String get searchVersionUnavailable =>
      'Bu sürüm kullanılamıyor. Başka bir sürüm seçin.';

  @override
  String get searchPreviewUnavailable =>
      'Şarkı sözü önizlemesi kullanılamıyor.';

  @override
  String get searchSongMatch => 'Şarkı eşleşmesi';

  @override
  String get searchRecordingMatch => 'Kayıt eşleşmesi';

  @override
  String get searchMatchUnverified => 'Kayıt doğrulanmadı';

  @override
  String get searchMatchExact => 'Tam kayıt eşleşmesi';

  @override
  String get searchMatchPossible => 'Olası eşleşme';

  @override
  String get searchAvailability => 'Kullanılabilirlik';

  @override
  String get searchLyricsAvailable => 'Şarkı sözleri mevcut';

  @override
  String get searchLyricsUnavailable => 'Şarkı sözleri mevcut değil';

  @override
  String get searchChordsAvailable => 'Akorlar mevcut';

  @override
  String get searchChordsUnavailable => 'Akor yok';

  @override
  String get searchTimingAvailable => 'Zamanlama mevcut';

  @override
  String get searchTimingUnavailable => 'Zamanlama yok';

  @override
  String get searchDurationUnknown => 'Süre bilinmiyor';

  @override
  String searchRating(String rating) {
    return 'Puan $rating';
  }

  @override
  String get searchSourceLabel => 'Kaynak';

  @override
  String get searchMetadata => 'Şarkı ayrıntıları';

  @override
  String get searchAlbum => 'Albüm';

  @override
  String get searchArtist => 'Sanatçı';

  @override
  String get searchYear => 'Yıl';

  @override
  String get searchLanguage => 'Dil';

  @override
  String get searchViewVersions => 'Sürümleri gör';

  @override
  String get searchSaved => 'Şarkı kitaplığınıza kaydedildi.';

  @override
  String get searchSaveOpenLyrics => 'Şarkı sözlerini kaydet ve aç';

  @override
  String get searchOtherResults => 'Diğer sonuçlar';

  @override
  String get searchSaveFailed => 'Bu şarkı kaydedilemedi.';

  @override
  String get homeRecentSongs => 'Son şarkılar';

  @override
  String get homeRecentlyPlayed => 'Son çalınanlar';

  @override
  String get homeFavorites => 'Favoriler';

  @override
  String get homeHistory => 'Geçmiş';

  @override
  String get homeHistoryClear => 'Geçmişi temizle';

  @override
  String get homeHistoryCleared => 'Geçmiş temizlendi.';

  @override
  String get homeHistoryEmpty => 'Açtığınız şarkılar burada görünür.';

  @override
  String get homeFavoritesEmpty =>
      'Favori şarkılarınız ve listeleriniz burada görünür.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öğe gösterildi',
      one: '1 öğe gösterildi',
      zero: '0 öğe gösterildi',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Son şarkılarınız ve listeleriniz burada görünür.';

  @override
  String get homeTimelineLabel => 'Geçmiş zaman çizelgesi';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Tüm geçmiş';

  @override
  String get homeShowFavorites => 'Favorileri göster';

  @override
  String get homeShowRecent => 'Son öğeleri göster';

  @override
  String get songsTitle => 'Şarkılar';

  @override
  String get songsEmpty => 'Şarkılarınız burada görünür.';

  @override
  String get songsEmptySearch => 'Aramanızla eşleşen şarkı yok.';

  @override
  String get songsAdd => 'Şarkı ekle';

  @override
  String get songsSortAlphabetical => 'Alfabetik sırala';

  @override
  String get songsAlphabetNavigation => 'Şarkı dizini';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kez açıldı',
      one: 'Bir kez açıldı',
      zero: 'Hiç açılmadı',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'Favorilere ekle';

  @override
  String get songFavoriteRemove => 'Favorilerden kaldır';

  @override
  String get songMenuLabel => 'Şarkı işlemleri';

  @override
  String get songInfo => 'Şarkı ayrıntıları';

  @override
  String get setlistMenuLabel => 'Liste işlemleri';

  @override
  String get songAddToSetlist => 'Listeye ekle';

  @override
  String get songCopyChordPro => 'ChordPro\'yu kopyala';

  @override
  String get songDeleteConfirmTitle => 'Şarkı silinsin mi?';

  @override
  String get songDeleteConfirmMessage =>
      'Bu şarkı kitaplığınızdan kaldırılacak.';

  @override
  String get songDeleted => 'Şarkı silindi.';

  @override
  String get setlistsTitle => 'Şarkı listeleri';

  @override
  String get setlistsEmpty =>
      'Bir sonraki provanız veya performansınız için bir liste oluşturun.';

  @override
  String get setlistsEmptySearch => 'Aramanızla eşleşen liste yok.';

  @override
  String get setlistCreate => 'Yeni liste';

  @override
  String get setlistNameHint => 'Liste adı';

  @override
  String get setlistNotes => 'Notlar';

  @override
  String get setlistEntryOverride => 'Şarkıya özel ton ve capo';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şarkı',
      one: '1 şarkı',
      zero: 'Şarkı yok',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'En az $duration';
  }

  @override
  String get setlistDurationUnknown => 'Süre bilinmiyor';

  @override
  String setlistActivity(String date) {
    return 'Son etkinlik $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Oluşturulma $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Düzenlenme $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Son çalınma $date';
  }

  @override
  String get setlistSongsEmpty => 'Bu listede henüz şarkı yok.';

  @override
  String get setlistAddSongs => 'Şarkı ekle';

  @override
  String get setlistReorder => 'Şarkıların sırasını değiştir';

  @override
  String setlistMoveSongUp(String song) {
    return '$song şarkısını yukarı taşı';
  }

  @override
  String setlistMoveSongDown(String song) {
    return '$song şarkısını aşağı taşı';
  }

  @override
  String setlistRemoveSong(String song) {
    return '$song şarkısını listeden kaldır';
  }

  @override
  String get setlistDuplicate => 'Listeyi çoğalt';

  @override
  String get setlistFavoriteAdd => 'Listeyi favorilere ekle';

  @override
  String get setlistFavoriteRemove => 'Listeyi favorilerden kaldır';

  @override
  String get setlistShare => 'Liste dosyası olarak paylaş';

  @override
  String get setlistSharePdf => 'PDF olarak paylaş';

  @override
  String get setlistPrint => 'Yazdır';

  @override
  String get setlistDeleteConfirmTitle => 'Liste silinsin mi?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Liste kaldırılacak. Kitaplığınızdaki şarkılar kalacak.';

  @override
  String get setlistDeleted => 'Liste silindi.';

  @override
  String get readerTitle => 'Şarkı sözleri';

  @override
  String get readerNoLyrics => 'Henüz şarkı sözü eklenmedi.';

  @override
  String get readerShowChords => 'Akorları göster';

  @override
  String get readerHideChords => 'Akorları gizle';

  @override
  String get readerTranspose => 'Akorları transpoze et';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yarım ton',
      one: '1 yarım ton',
      zero: '0 yarım ton',
    );
    return '$_temp0 transpoze et';
  }

  @override
  String get readerSaved => 'Kaydedildi';

  @override
  String get readerEdit => 'Şarkı sözlerini ve ayrıntıları düzenle';

  @override
  String get playerPlay => 'Oynat';

  @override
  String get playerPause => 'Duraklat';

  @override
  String get playerResume => 'Şarkı sözü kaydırmayı sürdür';

  @override
  String get playerSeek => 'Çalma konumu';

  @override
  String playerElapsed(String time) {
    return 'Geçen süre $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Kalan süre $time';
  }

  @override
  String get playerTimingMode => 'Kaydırma modu';

  @override
  String get playerTimedLyrics => 'Zamanlanmış şarkı sözleri';

  @override
  String get playerStartScroll => 'Otomatik kaydırmayı başlat';

  @override
  String get playerEstimatedPace => 'Tahmini hız';

  @override
  String get playerScrollSpeed => 'Kaydırma hızı';

  @override
  String playerEstimatedDuration(String time) {
    return 'Tahmini süre: $time';
  }

  @override
  String get playerLyricsOnly => 'Şarkı sözü kaydırma · ses yok';

  @override
  String get playerManualScroll => 'Elle kaydırma';

  @override
  String get playerTimingStatusReady =>
      'Şarkı sözleri mevcut zamanlamaya göre ilerler.';

  @override
  String get playerTimingStatusEstimated =>
      'Kaydırma hızı şarkı süresine göre tahmin edilir.';

  @override
  String get playerTimingStatusManual => 'Şarkı sözlerini kendiniz kaydırın.';

  @override
  String get playerTimingStatusUnavailable =>
      'Bu şarkı için zamanlanmış kaydırma kullanılamıyor.';

  @override
  String get playerDurationUnknown =>
      'Tahmini kaydırmayı kullanmak için şarkı süresi ekleyin.';

  @override
  String get playerProgressLabel => 'Şarkı ilerlemesi';

  @override
  String get playerCurrentSection => 'Geçerli bölüm';

  @override
  String get playerPreviousSection => 'Önceki bölüm';

  @override
  String get playerNextSection => 'Sonraki bölüm';

  @override
  String get playerPreviousSectionSong =>
      'Önceki bölüm · listedeki önceki şarkı için basılı tutun';

  @override
  String get playerNextSectionSong =>
      'Sonraki bölüm · listedeki sonraki şarkı için basılı tutun';

  @override
  String get playerPreviousSong => 'Önceki şarkı';

  @override
  String get playerNextSong => 'Sonraki şarkı';

  @override
  String get editorTitle => 'Şarkıyı düzenle';

  @override
  String get editorTitleField => 'Şarkı adı';

  @override
  String get editorArtistField => 'Sanatçı';

  @override
  String get editorAlbumField => 'Albüm';

  @override
  String get editorLyricsField => 'Şarkı sözleri';

  @override
  String get editorChordsField => 'Akorlar';

  @override
  String get editorKeyField => 'Ton';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Akort';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Süre';

  @override
  String get editorTimeSignatureField => 'Ölçü';

  @override
  String get editorLanguageField => 'Dil';

  @override
  String get editorYearField => 'Yıl';

  @override
  String get editorComposerField => 'Besteci';

  @override
  String get editorLyricistField => 'Söz yazarı';

  @override
  String get editorCopyrightField => 'Telif hakkı';

  @override
  String get editorLicenseField => 'Lisans';

  @override
  String get songInfoSources => 'Kaynaklar ve katkıda bulunanlar';

  @override
  String get searchMatchSameSong => 'Aynı şarkı; kayıt doğrulanmadı';

  @override
  String get searchMatchNeedsAgreement => 'Şarkı sözleri onaylanmalı';

  @override
  String get searchMatchDifferentLyrics =>
      'Şarkı sözleri seçilen şarkıdan farklı';

  @override
  String get searchMatchCombinedSources =>
      'Ayrıntılar birden çok kaynaktan birleştirildi';

  @override
  String get searchCombinedLabel => 'Birleşik';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şarkı eşleşmesi',
      one: '1 şarkı eşleşmesi',
      zero: '0 şarkı eşleşmesi',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaynak sürümü',
      one: '1 kaynak sürümü',
      zero: '0 kaynak sürümü',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Mevcut en iyi eşleşme';

  @override
  String get providerDescriptionUnknown => 'Şarkı kaynağı';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Kaynak sitesinden bir ChordPro dosyası indirin, ardından içe aktarın.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Ücretsiz bir hesapla dosyayı indirin, ardından içe aktarın.';

  @override
  String get providerDescPublicChordSheets => 'Herkese açık akor sayfaları.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Eser başına lisanslanmış tarihî şarkı sözleri.';

  @override
  String get providerDescLicensedCatalog => 'Lisanslı şarkı sözü kataloğu.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Creative Commons BY kapsamında özgün şarkılar.';

  @override
  String get providerDescPerSongLicense =>
      'Şarkı başına lisanslanmış şarkı sözleri.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Yalnızca kayıt ve yayın ayrıntıları.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Yalnızca beste ayrıntıları.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Yalnızca tam kayıt eşleşmeleri için kapak görseli.';

  @override
  String get providerCapabilityLyrics => 'Şarkı sözleri';

  @override
  String get providerCapabilityChords => 'Akorlar';

  @override
  String get providerCapabilityTiming => 'Zamanlanmış şarkı sözleri';

  @override
  String get providerCapabilitySearch => 'Arama';

  @override
  String get providerCapabilityMetadata => 'Şarkı ayrıntıları';

  @override
  String get editorArtworkField => 'Kapak görseli bağlantısı';

  @override
  String get editorLyricsHint =>
      'Akorları [C] köşeli parantez içinde yazın; bölüm işaretlerini ayrı satırlara koyun.';

  @override
  String get editorSave => 'Değişiklikleri kaydet';

  @override
  String get editorSaved => 'Değişiklikler kaydedildi.';

  @override
  String get editorSaveFailed => 'Değişiklikler kaydedilemedi.';

  @override
  String get editorSaveConflict =>
      'Şarkı başka bir yerde değiştirildi. Düzenlemeleriniz ayrı bir kopya olarak kaydedildi.';

  @override
  String get editorUnsavedTitle => 'Değişiklikler silinsin mi?';

  @override
  String get editorUnsavedMessage => 'Düzenlemeleriniz kaydedilmedi.';

  @override
  String get editorFieldRequired => 'Bir şarkı adı girin.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Cihaz ayarını kullan';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsColorPalette => 'Renk paleti';

  @override
  String get settingsFont => 'Yazı tipi';

  @override
  String get settingsTextSize => 'Metin boyutu';

  @override
  String get settingsLyricsPreview => 'Şarkı sözü önizlemesi';

  @override
  String get settingsPlayer => 'Şarkı sözü oynatıcı';

  @override
  String get settingsLyricHighlight => 'Geçerli söz satırını vurgula';

  @override
  String get settingsHighlightBackgroundUnderline => 'Arka plan + alt çizgi';

  @override
  String get settingsHighlightBackground => 'Arka plan';

  @override
  String get settingsHighlightUnderline => 'Alt çizgi';

  @override
  String get settingsHighlightContrast => 'Kontrastlı metin rengi';

  @override
  String get settingsHighlightNone => 'Yok';

  @override
  String get settingsDefaultShowChords => 'Akorları varsayılan olarak göster';

  @override
  String get settingsDefaultAutoscroll =>
      'Şarkı sözü kaydırmayı otomatik başlat';

  @override
  String get settingsDefaultTiming => 'Varsayılan kaydırma modu';

  @override
  String get settingsLanguage => 'Uygulama dili';

  @override
  String get settingsLanguageSystem => 'Cihaz dilini kullan';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Şarkı sözü kaynakları';

  @override
  String settingsSourceEnabled(String source) {
    return '$source kaynağını etkinleştir';
  }

  @override
  String get settingsSourceRefresh => 'Kaynak listesini yenile';

  @override
  String get settingsSourcesUpdated => 'Kaynaklar güncellendi.';

  @override
  String get settingsSourcesUpdateFailed => 'Kaynak listesi yenilenemedi.';

  @override
  String get settingsImport => 'Şarkıları içe aktar';

  @override
  String get settingsImportChordPro => 'ChordPro dosyasını içe aktar';

  @override
  String get settingsImportSetlist => 'Şarkı listesi dosyasını içe aktar';

  @override
  String get settingsImportSuccess => 'İçe aktarma tamamlandı.';

  @override
  String get settingsImportFailed => 'Bu dosya içe aktarılamadı.';

  @override
  String get settingsImportUnsupported => 'Bu dosya türü desteklenmiyor.';

  @override
  String get settingsShareSong => 'ChordPro olarak paylaş';

  @override
  String get settingsSharePdf => 'PDF olarak paylaş';

  @override
  String get settingsCopySong => 'Panoya kopyala';

  @override
  String get settingsPrintSong => 'Yalnızca yazdır';

  @override
  String get settingsPrintSetlist => 'Şarkı listesini sözlerle birlikte yazdır';

  @override
  String get settingsExportFailed => 'Dosya hazırlanamadı.';

  @override
  String get settingsCopied => 'Panoya kopyalandı.';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String get settingsPrivacy => 'Gizlilik';

  @override
  String get settingsLegal => 'Yasal bilgiler';

  @override
  String get settingsClearHistory => 'Geçmişi temizle';

  @override
  String get settingsClearHistoryConfirm =>
      'Şarkı ve liste geçmişi temizlensin mi?';

  @override
  String get settingsHistoryCleared => 'Geçmiş temizlendi.';

  @override
  String get accountTitle => 'Hesap ve senkronizasyon';

  @override
  String get accountUnavailable =>
      'Senkronizasyon için Google oturum açma özelliği yapılandırılmış bir Singbook derlemesi gerekir. Bu derleme şarkılarınızı yalnızca bu cihazda tutar.';

  @override
  String get accountSyncNow => 'Şimdi senkronize et';

  @override
  String get accountConnected =>
      'Bağlandı. Yedeklemenizi güncellemek için Şimdi senkronize et\'i seçin.';

  @override
  String get accountSignIn => 'Hesabı bağla';

  @override
  String get accountSignOut => 'Oturumu kapat';

  @override
  String get accountChange => 'Hesabı değiştir';

  @override
  String get accountSignedOut => 'Bağlı değil';

  @override
  String get accountSyncing => 'Kitaplığınız senkronize ediliyor…';

  @override
  String get accountSynced => 'Kitaplık senkronize edildi.';

  @override
  String get accountSyncFailed => 'Kitaplığınız senkronize edilemedi.';

  @override
  String get accessibilityFavorite => 'Favori';

  @override
  String get accessibilityNotFavorite => 'Favori değil';

  @override
  String get accessibilitySearchField => 'Şarkı ara';

  @override
  String get accessibilityClearSearch => 'Arama metnini temizle';

  @override
  String accessibilitySongMenu(String song) {
    return '$song için işlemler';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return '$setlist için işlemler';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return '$setlist listesindeki şarkıları genişlet';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return '$setlist listesindeki şarkıları daralt';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Çalma ilerlemesi, yüzde $percent';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Geçmiş zaman çizelgesi, $date';
  }

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get loadingSongs => 'Şarkılar yükleniyor…';

  @override
  String get loadingSetlists => 'Listeler yükleniyor…';

  @override
  String get errorGeneric => 'Bir sorun oluştu.';

  @override
  String get errorOffline => 'Çevrimdışı görünüyorsunuz.';

  @override
  String get errorPermission => 'Devam etmek için izin gerekiyor.';

  @override
  String get emptyFiltered => 'Bu filtrelerle eşleşen öğe yok.';

  @override
  String get unknownValue => 'Bilinmiyor';

  @override
  String get durationUnknown => 'Süre bilinmiyor';

  @override
  String get metadataNotSet => 'Ayarlanmadı';

  @override
  String get dateToday => 'Bugün';

  @override
  String get dateYesterday => 'Dün';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şarkı',
      one: '1 şarkı',
      zero: 'Şarkı yok',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Lacivert';

  @override
  String get settingsPaletteSage => 'Adaçayı';

  @override
  String get settingsPaletteOcean => 'Okyanus';

  @override
  String get settingsPaletteClay => 'Kil';

  @override
  String get settingsPalettePlum => 'Erik';

  @override
  String get settingsFontSystem => 'Sistem';

  @override
  String get settingsFontSerif => 'Tırnaklı';

  @override
  String get settingsFontMonospace => 'Eş aralıklı';

  @override
  String get settingsLyricsPreviewExample =>
      'Sabah olduğunda yine şarkı söyleyeceğiz.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Şarkı sözü kaynakları kontrol ediliyor: $total kaynaktan $checked tanesi tamamlandı.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Kullanılabilir şarkı sözü bulunamadı.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Seçilen şarkı etkin kaynaklarda arandı ancak hiçbiri kullanılabilir bir söz sürümü döndürmedi.';

  @override
  String get searchDiscoveryError => 'Şarkı sözü kaynakları kontrol edilemedi.';

  @override
  String get searchDiscoveryRetry => 'Şarkı sözlerini yeniden ara';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaynak kullanılamıyor',
      one: '1 kaynak kullanılamıyor',
      zero: '0 kaynak kullanılamıyor',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get searchProviderChecks => 'Kaynak kontrolleri';

  @override
  String get searchProviderPending => 'Kontrol ediliyor';

  @override
  String get searchProviderFound => 'Eşleşme bulundu';

  @override
  String get searchProviderRejected => 'Eşleşmiyor';

  @override
  String get searchProviderFailed => 'Kontrol başarısız';

  @override
  String get searchProviderUnavailable => 'Kullanılabilir şarkı sözü yok';

  @override
  String get searchCatalogFilterHint =>
      'Şarkı sözü sürümlerini akor, zamanlama veya dile göre filtrelemek için bir şarkı seçin.';

  @override
  String get startupErrorTitle => 'Kitaplığınız açılamadı.';

  @override
  String setlistCopyName(String name) {
    return '$name kopyası';
  }

  @override
  String get setlistSongMissing => 'Şarkı eksik';

  @override
  String get settingsImportTooLarge =>
      'Bu dosya içe aktarılamayacak kadar büyük.';

  @override
  String songsJumpToLetter(String letter) {
    return '$letter harfine git';
  }

  @override
  String get actionDiscard => 'At';

  @override
  String get editorKeepEditing => 'Düzenlemeye devam et';

  @override
  String get settingsDefaultShowChordsHint =>
      'Şarkıda akor varsa şarkı sözlerinin üzerinde göster.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Şarkı sözleri şarkıyla birlikte kayar. Elle kaydırma modunda kullanılmaz.';

  @override
  String get accountUnavailableTitle => 'Senkronizasyon ayarlanmamış';

  @override
  String get accountSignedOutBenefits =>
      'Google Drive’ı bağlamak kitaplığınızı eşitler. Şarkı değişiklikleri bundan sonra otomatik olarak eşitlenir.';

  @override
  String get accountManualSyncHint =>
      'Kitaplığınızı eşitlemek için Şimdi senkronize et düğmesine de dokunabilirsiniz.';

  @override
  String get accountSignInWithGoogle => 'Google ile oturum aç';

  @override
  String get accountWorking => 'İşleniyor…';

  @override
  String get accountNeverSynced => 'Hiç senkronize edilmedi';

  @override
  String get accountSyncedJustNow => 'Az önce senkronize edildi';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika önce senkronize edildi',
      one: '1 dakika önce senkronize edildi',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat önce senkronize edildi',
      one: '1 saat önce senkronize edildi',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün önce senkronize edildi',
      one: '1 gün önce senkronize edildi',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çakışan $count düzenleme kopya olarak saklandı',
      one: 'Çakışan 1 düzenleme kopya olarak saklandı',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Aynı şarkı veya liste iki yerde düzenlendi. Hiçbir şey kaybolmadı: diğer sürüm ayrı bir kopya olarak kaydedildi.';

  @override
  String get accountReviewConflicts => 'Kopyaları gözden geçir';

  @override
  String get songsConflictFilterActive =>
      'Yalnızca çakışan kopyalar gösteriliyor';

  @override
  String get songsConflictFilterClear => 'Tüm şarkıları göster';

  @override
  String get songsConflictBadge => 'Çakışan kopya';

  @override
  String get songsConflictEmpty => 'Çakışan kopya yok.';

  @override
  String get accountAutoSync => 'Otomatik senkronize et';

  @override
  String get accountAutoSyncHint =>
      'Bağlandıktan ve bir şarkı eklendikten, düzenlendikten veya kaldırıldıktan sonra eşitlenir.';

  @override
  String get accountDriveFolder => 'Google Drive kitaplık klasörü';

  @override
  String get accountPrivateDriveFolder => 'Özel Singbook klasörü';

  @override
  String get accountChooseDriveFolder => 'Klasör seç';

  @override
  String get accountDriveFolderMoveTitle =>
      'Singbook kütüphaneniz taşınsın mı?';

  @override
  String get accountDriveFolderMoveBody =>
      'Görünür bir Google Drive klasörü seçin. Singbook, geçiş yapmadan önce şarkılarınızı ve set listelerinizi oraya kopyalayacak ve doğrulayacaktır. Orijinal dosyalar yedek olarak önceki konumlarında kalır. Diğer dosyalar yalnız bırakılır. Bu klasöre aktardığınız ChordPro dosyaları senkronizasyon için benimsenir ve Singbook meta verilerini alır.';

  @override
  String get accountImportChordPro => 'ChordPro\'yu Drive\'dan içe aktar';

  @override
  String get accountImportChordProHint =>
      'Bu kitaplığa eklenecek .cho dosyalarını seçin. Zaten klasörde bulunan dosyalar benimsenir; başka yerlerdeki dosyalar buraya kopyalanır.';

  @override
  String get syncErrorFolderPickerUnavailable =>
      'Drive klasörü seçimi kullanılamıyor';

  @override
  String get syncErrorFolderPickerUnavailableHint =>
      'Desteklenen bir cihazda Google Drive seçiciyi kullanarak görünür bir Drive klasörü seçin.';

  @override
  String get syncErrorDriveFolderMissing =>
      'Singbook Drive klasörü kullanılamıyor';

  @override
  String get syncErrorDriveFolderMissingHint =>
      'Klasörü tekrar seçin veya Google Drive\'a geri yükleyin.';

  @override
  String get syncErrorDriveFileAuthorization =>
      'Singbook\'un bu Drive klasörüne erişmesi gerekiyor';

  @override
  String get syncErrorDriveFileAuthorizationHint =>
      'Erişim izni vermek için klasörü tekrar seçin ve ardından kitaplığınızı senkronize edin.';

  @override
  String get syncErrorFolderMigration => 'Kütüphane henüz taşınamadı';

  @override
  String get syncErrorFolderMigrationHint =>
      'Önceki kitaplığınız hâlâ güvende. Bağlantıyı kontrol edin ve yeniden denemek için klasörü tekrar seçin.';

  @override
  String get syncErrorVisibleFolderRequired =>
      'Önce görünür bir Drive klasörü seçin';

  @override
  String get syncErrorVisibleFolderRequiredHint =>
      'Dosyaları Drive\'dan içe aktarmadan önce görünür bir kitaplık klasörüne ihtiyaç vardır.';

  @override
  String get accountSignOutTitle => 'Bu hesaptan çıkış yapılsın mı?';

  @override
  String get accountSignOutBody =>
      'Şarkılarınız ve listeleriniz bu cihazda kalır. Yeniden oturum açana kadar yedeklenmez veya senkronize edilmez.';

  @override
  String get accountUseDifferent => 'Farklı bir hesap kullan';

  @override
  String get accountSignInAgain => 'Tekrar oturum aç';

  @override
  String get accountChooseAction => 'Nasıl devam edeceğinizi seçin';

  @override
  String get accountChangedTitle => 'Farklı Google hesabı';

  @override
  String get accountChangedBody =>
      'Bu cihaz en son başka bir Google hesabıyla senkronize edildi. Bu cihazdaki şarkı ve listelere ne olacağını seçin.';

  @override
  String get accountChangedMerge => 'Yeni hesapla birleştir';

  @override
  String get accountChangedMergeHint =>
      'Bu cihazdaki her şeyi koruyup yeni hesaba ekleyin.';

  @override
  String get accountChangedReplace => 'Yeni hesabın kitaplığıyla değiştir';

  @override
  String get accountChangedReplaceHint =>
      'Bu cihazda olup yeni hesapta bulunmayan şarkılar kaldırılır.';

  @override
  String get accountChangedSignOut => 'İptal et ve oturumu kapat';

  @override
  String get accountStatusSignedOut =>
      'Hesap ve senkronizasyon: oturum açılmadı';

  @override
  String get accountStatusSignedIn => 'Hesap ve senkronizasyon: oturum açıldı';

  @override
  String get accountStatusSyncing =>
      'Hesap ve senkronizasyon: senkronize ediliyor';

  @override
  String get accountStatusSynced => 'Hesap ve senkronizasyon: kitaplık güncel';

  @override
  String get accountStatusError =>
      'Hesap ve senkronizasyon: sorun var, incelemek için dokunun';

  @override
  String get accountNoticeConflicts =>
      'Bazı şarkılar iki yerde düzenlendi. Kopyaları saklandı.';

  @override
  String get accountNoticeSignedIn => 'Oturum açıldı.';

  @override
  String get accountNoticeSignedOut =>
      'Oturum kapatıldı. Şarkılarınız bu cihazda kalır.';

  @override
  String get syncErrorNotConfigured =>
      'Bu derlemede senkronizasyon ayarlanmamış.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Google oturum açma özelliği yapılandırılmış bir Singbook derlemesi kullanın.';

  @override
  String get syncErrorNotSignedIn => 'Oturum açmadınız.';

  @override
  String get syncErrorNotSignedInHint =>
      'Kitaplığınızı senkronize etmek için oturum açın.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google yeniden oturum açmanızı istiyor.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Senkronizasyona devam etmek için tekrar oturum açın. Şarkılarınız bu cihazda güvende.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook\'un Google Drive\'ı kullanma izni yok.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Tekrar oturum açın ve sorulduğunda Drive erişimine izin verin.';

  @override
  String get syncErrorRateLimited => 'Google şu anda istekleri sınırlıyor.';

  @override
  String get syncErrorRateLimitedHint =>
      'Birkaç dakika bekleyip tekrar deneyin.';

  @override
  String get syncErrorStorageFull => 'Google Drive\'ınız dolu.';

  @override
  String get syncErrorStorageFullHint => 'Drive\'da yer açıp tekrar deneyin.';

  @override
  String get syncErrorNetwork => 'Google\'a ulaşılamadı.';

  @override
  String get syncErrorNetworkHint =>
      'İnternet bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get syncErrorAccountChanged => 'Farklı bir Google hesabı kullanıldı.';

  @override
  String get syncErrorAccountChangedHint =>
      'Bu cihazın kitaplığını hesaba eklemek veya hesabın kitaplığıyla değiştirmek arasında seçim yapın.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Senkronize edilen kitaplığınız Singbook\'un işleyebileceğinden büyük.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Senkronize edilen kitaplıktan birkaç şarkı veya liste kaldırıp tekrar deneyin.';

  @override
  String get syncErrorSignInFailed => 'Oturum açma tamamlanmadı.';

  @override
  String get syncErrorSignInFailedHint => 'Tekrar oturum açmayı deneyin.';

  @override
  String get syncErrorGeneric => 'Kitaplığınız senkronize edilemedi.';

  @override
  String get syncErrorGenericHint =>
      'Birazdan tekrar deneyin. Şarkılarınız bu cihazda güvende.';

  @override
  String get editorDurationInvalid =>
      'Saniye veya dakika ve saniye girin, örneğin 3:45.';

  @override
  String get editorNumberInvalid => 'Bir sayı girin.';

  @override
  String get accountReplaceConfirmTitle => 'Yerel şarkılar silinsin mi?';

  @override
  String get accountReplaceConfirmBody =>
      'Bu cihazdaki ve yeni hesapta bulunmayan şarkılar ile şarkı listeleri kalıcı olarak silinecek. Bu işlem geri alınamaz.';

  @override
  String get accountReplaceConfirmAction => 'Sil ve değiştir';

  @override
  String get accountSuspiciousTitle => 'Google Drive\'da bazı öğeler eksik';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bu cihaz tarafından daha önce senkronize edilen $count öğe Google Drive\'da bulunamıyor.',
      one:
          'Bu cihaz tarafından daha önce senkronize edilen $count öğe Google Drive\'da bulunamıyor.',
    );
    return '$_temp0 Bu durum, uygulama verileri Google ayarlarından temizlendiğinde oluşabilir. Henüz hiçbir şey silinmedi.';
  }

  @override
  String get accountSuspiciousDelete => 'Onları burada da sil';

  @override
  String get accountSuspiciousKeep => 'Şarkılarımı koru ve yeniden yükle';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öğe bu cihazdan silinsin mi?',
      one: '$count öğe bu cihazdan silinsin mi?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Bu şarkılar ve şarkı listeleri bu cihazdan kalıcı olarak silinecek. Bu işlem geri alınamaz.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Bu cihazdan sil';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Google Drive\'da bazı öğeler eksik.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Hiçbir şey silinmedi. Bunları burada da silmeyi veya yeniden yüklemeyi seçin.';

  @override
  String get syncErrorRemoteChanged =>
      'Senkronizasyon sırasında Google Drive değişti.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Hiçbir şey kaybolmadı. En son değişiklikleri almak için yeniden senkronize edin.';

  @override
  String get syncErrorInvalidLocalData =>
      'Bu cihazdaki bazı veriler senkronize edilemedi.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Bir şarkı veya şarkı listesi okunamadı. İçe aktarın ya da yeniden oluşturun, ardından tekrar senkronize edin.';

  @override
  String get syncErrorNoAccountChange => 'Çözülecek bir hesap değişikliği yok.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Devam etmek için yeniden senkronize edin.';

  @override
  String get accountSyncWarningTitle =>
      'Senkronize edildi, ancak bazı dosyalar atlandı';

  @override
  String get accountSyncWarningBody =>
      'Bazı dosyalar kullanılamadı ve olduğu gibi bırakıldı. Diğer her şey güncel.';

  @override
  String get accountSyncWarningTooLarge =>
      'Bir dosya senkronize edilemeyecek kadar büyüktü ve atlandı. Diğer her şey güncel.';

  @override
  String get accountSyncWarningInvalid =>
      'Bir dosya okunamadı ve atlandı. Diğer her şey güncel.';

  @override
  String get accountNoticeSyncSkipped =>
      'Senkronize edildi. Bazı dosyalar atlandı.';

  @override
  String get settingsExportPdfTooLarge =>
      'Bu PDF çok büyük olur. Daha az şarkı seçin veya metin olarak paylaşın.';

  @override
  String get settingsTimingTooLarge =>
      'Zamanlama verileri çok büyük (3 MB üzerinde).';

  @override
  String get settingsImportDuplicateSongId =>
      'Bu yedek aynı şarkıyı iki kez içeriyor; hiçbir şey içe aktarılmadı.';

  @override
  String get setlistSaveConflict =>
      'Şarkı listesi başka bir yerde değiştirildi. Düzenlemeleriniz ayrı bir kopya olarak kaydedildi.';

  @override
  String get sectionVerse => 'Kıta';

  @override
  String get sectionChorus => 'Nakarat';

  @override
  String get sectionBridge => 'Köprü';

  @override
  String get sectionIntro => 'Giriş';

  @override
  String get sectionOutro => 'Çıkış';

  @override
  String get sectionPreChorus => 'Nakarat öncesi';

  @override
  String get sectionPostChorus => 'Nakarat sonrası';

  @override
  String get sectionInstrumental => 'Enstrümantal';

  @override
  String get sectionInterlude => 'Ara bölüm';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Tekrar';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Koda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Bitiş';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Hazır sürümler',
      one: '1 hazır sürüm',
      zero: '0 Hazır sürümler',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kullanılamayan sürümler',
      one: '1 kullanılamayan sürüm',
      zero: '0 Kullanılamayan sürümler',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Bölüme git';

  @override
  String get searchVersionDetails => 'Sürüm ayrıntıları';

  @override
  String get searchSelectedRecording => 'Seçilen kayıt';

  @override
  String get searchVersionDuration => 'Sürüm süresi';

  @override
  String get searchSourceOptions => 'Kaynak seçenekleri';

  @override
  String get actionUndo => 'Geri al';

  @override
  String setlistEntryRemoved(String song) {
    return '$song şarkısı set listesinden kaldırıldı';
  }

  @override
  String get backupTitle => 'Yedekleme ve geri yükleme';

  @override
  String get backupExport => 'Yedeği dışa aktar';

  @override
  String get backupRestore => 'Yedeği geri yükle';

  @override
  String get backupIncludePreferences => 'Uygulama tercihlerini dahil et';

  @override
  String get backupRestorePreferences => 'Uygulama tercihlerini geri yükle';

  @override
  String get backupMerge => 'Bu kitaplığa ekle';

  @override
  String get backupMergeHint =>
      'Yerel düzenlemeleri koruyun ve bu yedekteki şarkıları ve listeleri ekleyin.';

  @override
  String get backupReplace => 'Bu kitaplığı değiştir';

  @override
  String get backupReplaceHint =>
      'Bu cihazdaki tüm şarkıları ve listeleri bu yedekle değiştirin.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Şarkılar: $songs · Listeler: $setlists · Çakışmalar: $conflicts';
  }

  @override
  String get backupFailed => 'Yedekleme işlemi tamamlanamadı. Yeniden deneyin.';

  @override
  String get backupRestored => 'Yedek geri yüklendi.';

  @override
  String get backupLocalHint =>
      'Kitaplığınızın bir kopyasını kaydedin. Hesap kimlik bilgileri ve izin çerezleri hiçbir zaman dahil edilmez.';

  @override
  String get backupReplaceConfirm =>
      'Mevcut kitaplık değiştirilsin mi? Bu işlem geri alınamaz.';

  @override
  String get searchCheckOperations => 'İşlemler';

  @override
  String get searchCheckCode => 'Sonuç kodu';

  @override
  String get searchCheckQueued => 'Bu kaynağın kontrol edilmesi bekleniyor.';

  @override
  String get searchCheckFetch => 'Şarkı sözlerini yükle';

  @override
  String get searchCheckValidate => 'Şarkı eşleşmesini kontrol et';

  @override
  String get searchCheckCorroborate => 'Şarkı sözü uyumunu kontrol et';

  @override
  String get searchCheckCompleted => 'Tamamlandı';

  @override
  String get searchCheckTimeout => 'Kaynak zamanında yanıt vermedi.';

  @override
  String get searchCheckBlocked => 'Kaynak isteği engelledi.';

  @override
  String get searchCheckRateLimited =>
      'Kaynak istekleri sınırlandırıyor. Daha sonra tekrar deneyin.';

  @override
  String get searchCheckNetwork =>
      'Kaynağa ulaşılamadı. Bağlantınızı kontrol edin.';

  @override
  String get searchCheckInvalid => 'Kaynak okunamayan bir yanıt döndürdü.';

  @override
  String get searchCheckNotConfigured =>
      'Bu derlemede bu kaynak yapılandırılmamış.';

  @override
  String get searchCheckNoLyrics => 'Eşleşen şarkı sözü bulunamadı.';

  @override
  String get searchCheckFailed => 'Bu işlem tamamlanamadı.';

  @override
  String get searchCheckNoHistory =>
      'Bu karşılaştırma için kaynak kontrolü yapılmadı.';

  @override
  String get searchVersionCredits => 'Katkıda bulunanlar';

  @override
  String get searchVersionMediaLinks => 'İlgili bağlantılar';

  @override
  String get searchCheckCancelled => 'İptal edildi';

  @override
  String get searchCheckAmbiguous =>
      'Birden fazla eşleşme bulundu. Bu kaynak için daha belirgin bir kayıt gerekiyor.';

  @override
  String get searchCheckIdentity =>
      'Bu kaynak için bir kayıt veya eser tanımlayıcısı gerekiyor.';

  @override
  String get searchCheckExtraction =>
      'Kaynak yanıt verdi ancak şarkı sözleri çıkarılamadı.';

  @override
  String get searchCheckBusy => 'Bu kaynak meşgul. Daha sonra tekrar deneyin.';

  @override
  String get searchCheckSelection => 'Bu kaynaktan belirli bir sonuç seçin.';

  @override
  String get playerChordsNone => 'Yok';

  @override
  String get editorCustomValue => 'Diğer…';

  @override
  String get editorStandardTuning => 'Standart akort';

  @override
  String get editorExampleVerse =>
      '[C]Yeni bir gün bizi [G]çağırıyor,\n[Am]ışığı izleyip [F]eve dönüyoruz.';

  @override
  String get editorExampleChorus =>
      '[F]Bu şarkıyı [C]birlikte söyleyelim,\n[G]melodi bizi [C]ileriye taşısın.';

  @override
  String get editorExampleBridge => '[Am]Bir satır daha, biraz daha [F]yakın.';

  @override
  String get playerEstimatedKey => 'Tahmini tonalite';

  @override
  String get songsLibraryView => 'Kitaplık';

  @override
  String get settingsStartupView => 'Başlangıç görünümü';

  @override
  String get settingsStartupViewHint =>
      'Uygulama açıldığında gösterilecek Şarkılar görünümünü seçin.';

  @override
  String get settingsStartupLastView => 'Son açılan';

  @override
  String get playerExpandControls => 'Oynatma kontrollerini göster';

  @override
  String get playerCollapseControls => 'Oynatma kontrollerini gizle';

  @override
  String get settingsShowSections => 'Bölüm başlıklarını göster';

  @override
  String get settingsShowSectionsHint =>
      'Şarkı sözlerinde kıta, nakarat ve diğer bölümlerin başlıklarını göster.';

  @override
  String get settingsShowPlayerControls => 'Oynatma kontrollerini göster';

  @override
  String get settingsShowPlayerControlsHint =>
      'Oynatıcı panelini göstermek veya gizlemek için panele dokunabilir ya da kaydırabilirsiniz.';
}
