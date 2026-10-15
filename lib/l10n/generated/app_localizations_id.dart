// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Tempat yang nyaman untuk menemukan, mengatur, dan bernyanyi bersama koleksi lagu Anda.';

  @override
  String get aboutMadeForSinging => 'Dibuat untuk bernyanyi bersama';

  @override
  String appVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get navHome => 'Beranda';

  @override
  String get navSongs => 'Lagu';

  @override
  String get navSetlists => 'Daftar lagu';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get navSettingsCompact => 'Pengaturan';

  @override
  String get navSearch => 'Cari';

  @override
  String get navBack => 'Kembali';

  @override
  String get navClose => 'Tutup';

  @override
  String get navMore => 'Tindakan lainnya';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionSave => 'Simpan';

  @override
  String get actionDone => 'Selesai';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Hapus';

  @override
  String get actionShare => 'Bagikan';

  @override
  String get actionPrint => 'Cetak';

  @override
  String get actionCopy => 'Salin';

  @override
  String get actionClear => 'Bersihkan';

  @override
  String get actionRetry => 'Coba lagi';

  @override
  String get actionRefresh => 'Muat ulang';

  @override
  String get actionImport => 'Impor';

  @override
  String get actionExport => 'Ekspor';

  @override
  String get actionExpand => 'Perluas';

  @override
  String get actionCollapse => 'Ciutkan';

  @override
  String get actionAdd => 'Tambahkan';

  @override
  String get actionCreate => 'Buat';

  @override
  String get actionRemove => 'Hapus';

  @override
  String get actionDuplicate => 'Duplikasi';

  @override
  String get actionMoveUp => 'Pindahkan ke atas';

  @override
  String get actionMoveDown => 'Pindahkan ke bawah';

  @override
  String get actionPrevious => 'Sebelumnya';

  @override
  String get actionNext => 'Berikutnya';

  @override
  String get searchHint => 'Cari lagu, artis, atau lirik';

  @override
  String get searchCatalogHint => 'Cari lagu atau artis';

  @override
  String get searchChangeSong => 'Ganti lagu';

  @override
  String get searchSelectedPreview => 'Pratinjau terpilih';

  @override
  String get searchSubmit => 'Cari';

  @override
  String get searchFilters => 'Opsi pencarian';

  @override
  String get searchFiltersShow => 'Tampilkan opsi pencarian';

  @override
  String get searchFiltersHide => 'Sembunyikan opsi pencarian';

  @override
  String get searchFilterArtist => 'Artis';

  @override
  String get searchFilterTitle => 'Judul lagu';

  @override
  String get searchFilterLyrics => 'Lirik';

  @override
  String get searchFilterChords => 'Memiliki akor';

  @override
  String get searchFilterTimed => 'Lirik bertanda waktu';

  @override
  String get searchFilterLanguage => 'Bahasa';

  @override
  String get searchFilterAll => 'Apa saja';

  @override
  String get searchAutocompleteLabel => 'Saran';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hasil',
      one: '1 hasil',
      zero: 'Tidak ada hasil',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Masukkan lagu, artis, atau lirik untuk mencari.';

  @override
  String get searchCatalogEmptyQuery =>
      'Masukkan lagu atau artis untuk mencari.';

  @override
  String get searchNoResults => 'Lagu tidak ditemukan. Coba pencarian lain.';

  @override
  String get searchLoading => 'Mencari lagu…';

  @override
  String get searchError => 'Pencarian tidak dapat diselesaikan.';

  @override
  String get searchOnlineTab => 'Online';

  @override
  String get searchRecentTab => 'Terbaru';

  @override
  String get searchFavoritesTab => 'Favorit';

  @override
  String get searchSuggested => 'Kecocokan yang disarankan';

  @override
  String get searchAlternatives => 'Kecocokan lainnya';

  @override
  String get searchCompare => 'Bandingkan versi';

  @override
  String get searchChooseVersion => 'Pilih versi ini';

  @override
  String get searchSongMatch => 'Kecocokan lagu';

  @override
  String get searchRecordingMatch => 'Kecocokan rekaman';

  @override
  String get searchMatchUnverified => 'Rekaman belum diverifikasi';

  @override
  String get searchMatchExact => 'Rekaman cocok persis';

  @override
  String get searchMatchPossible => 'Kemungkinan cocok';

  @override
  String get searchAvailability => 'Ketersediaan';

  @override
  String get searchLyricsAvailable => 'Lirik tersedia';

  @override
  String get searchLyricsUnavailable => 'Lirik tidak tersedia';

  @override
  String get searchChordsAvailable => 'Akor tersedia';

  @override
  String get searchChordsUnavailable => 'Tidak ada akor';

  @override
  String get searchTimingAvailable => 'Penanda waktu tersedia';

  @override
  String get searchTimingUnavailable => 'Tidak ada penanda waktu';

  @override
  String get searchDurationUnknown => 'Durasi tidak diketahui';

  @override
  String searchRating(String rating) {
    return 'Penilaian $rating';
  }

  @override
  String get searchSourceLabel => 'Sumber';

  @override
  String get searchMetadata => 'Detail lagu';

  @override
  String get searchAlbum => 'Album';

  @override
  String get searchArtist => 'Artis';

  @override
  String get searchYear => 'Tahun';

  @override
  String get searchLanguage => 'Bahasa';

  @override
  String get searchViewVersions => 'Lihat versi';

  @override
  String get searchSaved => 'Lagu disimpan ke pustaka Anda.';

  @override
  String get searchSaveOpenLyrics => 'Simpan & buka lirik';

  @override
  String get searchOtherResults => 'Hasil lainnya';

  @override
  String get searchSaveFailed => 'Lagu ini tidak dapat disimpan.';

  @override
  String get homeRecentSongs => 'Lagu terbaru';

  @override
  String get homeRecentlyPlayed => 'Baru diputar';

  @override
  String get homeFavorites => 'Favorit';

  @override
  String get homeHistory => 'Riwayat';

  @override
  String get homeHistoryClear => 'Hapus riwayat';

  @override
  String get homeHistoryCleared => 'Riwayat dihapus.';

  @override
  String get homeHistoryEmpty => 'Lagu yang Anda buka akan muncul di sini.';

  @override
  String get homeFavoritesEmpty =>
      'Lagu dan daftar lagu favorit Anda akan muncul di sini.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item ditampilkan',
      one: '1 item ditampilkan',
      zero: '0 item ditampilkan',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Lagu dan daftar lagu terbaru Anda akan muncul di sini.';

  @override
  String get homeTimelineLabel => 'Linimasa riwayat';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Semua riwayat';

  @override
  String get homeShowFavorites => 'Tampilkan favorit';

  @override
  String get homeShowRecent => 'Tampilkan terbaru';

  @override
  String get songsTitle => 'Lagu';

  @override
  String get songsEmpty => 'Lagu Anda akan muncul di sini.';

  @override
  String get songsEmptySearch =>
      'Tidak ada lagu yang cocok dengan pencarian Anda.';

  @override
  String get songsAdd => 'Tambahkan lagu';

  @override
  String get songsSortAlphabetical => 'Urutkan menurut abjad';

  @override
  String get songsAlphabetNavigation => 'Indeks lagu';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dibuka $count kali',
      one: 'Dibuka sekali',
      zero: 'Tidak pernah dibuka',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'Tambahkan ke favorit';

  @override
  String get songFavoriteRemove => 'Hapus dari favorit';

  @override
  String get songMenuLabel => 'Tindakan lagu';

  @override
  String get songInfo => 'Detail lagu';

  @override
  String get setlistMenuLabel => 'Tindakan daftar lagu';

  @override
  String get songAddToSetlist => 'Tambahkan ke daftar lagu';

  @override
  String get songCopyChordPro => 'Salin ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Hapus lagu?';

  @override
  String get songDeleteConfirmMessage =>
      'Lagu ini akan dihapus dari pustaka Anda.';

  @override
  String get songDeleted => 'Lagu dihapus.';

  @override
  String get setlistsTitle => 'Daftar lagu';

  @override
  String get setlistsEmpty =>
      'Buat daftar lagu untuk latihan atau pertunjukan berikutnya.';

  @override
  String get setlistsEmptySearch =>
      'Tidak ada daftar lagu yang cocok dengan pencarian Anda.';

  @override
  String get setlistCreate => 'Daftar lagu baru';

  @override
  String get setlistNameHint => 'Nama daftar lagu';

  @override
  String get setlistNotes => 'Catatan';

  @override
  String get setlistEntryOverride =>
      'Nada dasar dan capo khusus untuk lagu ini';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu',
      one: '1 lagu',
      zero: 'Tidak ada lagu',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Setidaknya $duration';
  }

  @override
  String get setlistDurationUnknown => 'Durasi tidak diketahui';

  @override
  String setlistActivity(String date) {
    return 'Aktivitas terakhir $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Dibuat $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Diedit $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Terakhir diputar $date';
  }

  @override
  String get setlistSongsEmpty => 'Belum ada lagu dalam daftar ini.';

  @override
  String get setlistAddSongs => 'Tambahkan lagu';

  @override
  String get setlistReorder => 'Atur ulang lagu';

  @override
  String setlistMoveSongUp(String song) {
    return 'Pindahkan $song ke atas';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Pindahkan $song ke bawah';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Hapus $song dari daftar lagu';
  }

  @override
  String get setlistDuplicate => 'Duplikasi daftar lagu';

  @override
  String get setlistFavoriteAdd => 'Tambahkan daftar lagu ke favorit';

  @override
  String get setlistFavoriteRemove => 'Hapus daftar lagu dari favorit';

  @override
  String get setlistShare => 'Bagikan sebagai file daftar lagu';

  @override
  String get setlistSharePdf => 'Bagikan sebagai PDF';

  @override
  String get setlistPrint => 'Cetak';

  @override
  String get setlistDeleteConfirmTitle => 'Hapus daftar lagu?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Daftar lagu akan dihapus. Lagu di pustaka Anda akan tetap ada.';

  @override
  String get setlistDeleted => 'Daftar lagu dihapus.';

  @override
  String get readerTitle => 'Lirik';

  @override
  String get readerNoLyrics => 'Lirik belum ditambahkan.';

  @override
  String get readerShowChords => 'Tampilkan akor';

  @override
  String get readerHideChords => 'Sembunyikan akor';

  @override
  String get readerTranspose => 'Transposisikan akor';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semiton',
      one: '1 semiton',
      zero: '0 semiton',
    );
    return 'Transposisikan $_temp0';
  }

  @override
  String get readerSaved => 'Tersimpan';

  @override
  String get readerEdit => 'Edit lirik dan detail';

  @override
  String get playerPlay => 'Mulai gulir lirik';

  @override
  String get playerPause => 'Jeda gulir lirik';

  @override
  String get playerResume => 'Lanjutkan gulir lirik';

  @override
  String get playerSeek => 'Posisi pemutaran';

  @override
  String playerElapsed(String time) {
    return 'Waktu berlalu $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Sisa waktu $time';
  }

  @override
  String get playerTimingMode => 'Mode gulir';

  @override
  String get playerTimedLyrics => 'Lirik bertanda waktu';

  @override
  String get playerStartScroll => 'Mulai gulir otomatis';

  @override
  String get playerEstimatedPace => 'Kecepatan perkiraan';

  @override
  String get playerScrollSpeed => 'Kecepatan gulir';

  @override
  String playerEstimatedDuration(String time) {
    return 'Perkiraan durasi: $time';
  }

  @override
  String get playerLyricsOnly => 'Gulir lirik · tanpa audio';

  @override
  String get playerManualScroll => 'Gulir manual';

  @override
  String get playerTimingStatusReady =>
      'Lirik akan mengikuti penanda waktu yang tersedia.';

  @override
  String get playerTimingStatusEstimated =>
      'Kecepatan gulir diperkirakan dari durasi lagu.';

  @override
  String get playerTimingStatusManual => 'Gulir lirik secara manual.';

  @override
  String get playerTimingStatusUnavailable =>
      'Gulir tersinkronisasi tidak tersedia untuk lagu ini.';

  @override
  String get playerDurationUnknown =>
      'Tambahkan durasi lagu untuk menggunakan gulir perkiraan.';

  @override
  String get playerProgressLabel => 'Progres lagu';

  @override
  String get playerCurrentSection => 'Bagian saat ini';

  @override
  String get playerPreviousSection => 'Bagian sebelumnya';

  @override
  String get playerNextSection => 'Bagian berikutnya';

  @override
  String get playerPreviousSectionSong =>
      'Bagian sebelumnya · tahan untuk lagu sebelumnya dalam daftar';

  @override
  String get playerNextSectionSong =>
      'Bagian berikutnya · tahan untuk lagu berikutnya dalam daftar';

  @override
  String get playerPreviousSong => 'Lagu sebelumnya';

  @override
  String get playerNextSong => 'Lagu berikutnya';

  @override
  String get editorTitle => 'Edit lagu';

  @override
  String get editorTitleField => 'Judul lagu';

  @override
  String get editorArtistField => 'Artis';

  @override
  String get editorAlbumField => 'Album';

  @override
  String get editorLyricsField => 'Lirik';

  @override
  String get editorChordsField => 'Akor';

  @override
  String get editorKeyField => 'Nada dasar';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Penyetelan';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Durasi';

  @override
  String get editorTimeSignatureField => 'Tanda birama';

  @override
  String get editorLanguageField => 'Bahasa';

  @override
  String get editorYearField => 'Tahun';

  @override
  String get editorComposerField => 'Komposer';

  @override
  String get editorLyricistField => 'Penulis lirik';

  @override
  String get editorCopyrightField => 'Hak cipta';

  @override
  String get editorLicenseField => 'Lisensi';

  @override
  String get songInfoSources => 'Sumber dan kredit';

  @override
  String get searchMatchSameSong =>
      'Lagu yang sama; rekaman belum dikonfirmasi';

  @override
  String get searchMatchNeedsAgreement =>
      'Lirik pada lembar akor perlu dikonfirmasi';

  @override
  String get searchMatchDifferentLyrics =>
      'Lirik berbeda dari lagu yang dipilih';

  @override
  String get searchMatchCombinedSources =>
      'Detail digabungkan dari beberapa sumber';

  @override
  String searchCombinedFromSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Digabungkan dari $count sumber',
      one: 'Digabungkan dari 1 sumber',
    );
    return '$_temp0';
  }

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kecocokan lagu',
      one: '1 kecocokan lagu',
      zero: '0 kecocokan lagu',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versi sumber',
      one: '1 versi sumber',
      zero: '0 versi sumber',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Kecocokan terbaik yang tersedia';

  @override
  String get providerDescriptionUnknown => 'Sumber lagu';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Unduh file ChordPro dari sumber, lalu impor.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Unduh file dengan akun gratis, lalu impor.';

  @override
  String get providerDescPublicChordSheets => 'Lembar akor publik.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Lirik historis berlisensi per karya.';

  @override
  String get providerDescLicensedCatalog => 'Katalog lirik berlisensi.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Lagu orisinal berlisensi Creative Commons BY.';

  @override
  String get providerDescPerSongLicense => 'Lirik berlisensi per lagu.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Hanya detail rekaman dan rilis.';

  @override
  String get providerDescCompositionMetadataOnly => 'Hanya detail komposisi.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Sampul hanya untuk rekaman yang cocok persis.';

  @override
  String get providerCapabilityLyrics => 'Lirik';

  @override
  String get providerCapabilityChords => 'Akor';

  @override
  String get providerCapabilityTiming => 'Lirik bertanda waktu';

  @override
  String get providerCapabilitySearch => 'Pencarian';

  @override
  String get providerCapabilityMetadata => 'Detail lagu';

  @override
  String get editorArtworkField => 'Tautan sampul';

  @override
  String get editorLyricsHint => 'Ketuk baris untuk mengedit lirik atau akor.';

  @override
  String get editorSave => 'Simpan perubahan';

  @override
  String get editorSaved => 'Perubahan disimpan.';

  @override
  String get editorSaveFailed => 'Perubahan tidak dapat disimpan.';

  @override
  String get editorSaveConflict =>
      'Lagu diubah di tempat lain. Perubahan Anda disimpan sebagai salinan terpisah.';

  @override
  String get editorUnsavedTitle => 'Buang perubahan?';

  @override
  String get editorUnsavedMessage => 'Perubahan Anda belum disimpan.';

  @override
  String get editorFieldRequired => 'Masukkan judul lagu.';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsAppearance => 'Tampilan';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Gunakan pengaturan perangkat';

  @override
  String get settingsThemeLight => 'Terang';

  @override
  String get settingsThemeDark => 'Gelap';

  @override
  String get settingsColorPalette => 'Palet warna';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsTextSize => 'Ukuran teks';

  @override
  String get settingsLyricsPreview => 'Pratinjau lirik';

  @override
  String get settingsPlayer => 'Pemutar lirik';

  @override
  String get settingsDefaultShowChords => 'Tampilkan akor secara default';

  @override
  String get settingsDefaultAutoscroll => 'Mulai gulir lirik secara otomatis';

  @override
  String get settingsDefaultTiming => 'Mode gulir default';

  @override
  String get settingsLanguage => 'Bahasa aplikasi';

  @override
  String get settingsLanguageSystem => 'Gunakan bahasa perangkat';

  @override
  String get settingsLanguageEnglish => 'Inggris';

  @override
  String get settingsLanguageBulgarian => 'Bulgaria';

  @override
  String get settingsLanguageUkrainian => 'Ukraina';

  @override
  String get settingsSources => 'Sumber lirik';

  @override
  String settingsSourceEnabled(String source) {
    return 'Aktifkan sumber $source';
  }

  @override
  String get settingsSourceRefresh => 'Muat ulang daftar sumber';

  @override
  String get settingsSourcesUpdated => 'Sumber diperbarui.';

  @override
  String get settingsSourcesUpdateFailed => 'Sumber tidak dapat dimuat ulang.';

  @override
  String get settingsImport => 'Impor lagu';

  @override
  String get settingsImportChordPro => 'Impor file ChordPro';

  @override
  String get settingsImportSetlist => 'Impor file daftar lagu';

  @override
  String get settingsImportSuccess => 'Impor selesai.';

  @override
  String get settingsImportFailed => 'File ini tidak dapat diimpor.';

  @override
  String get settingsImportUnsupported => 'Jenis file ini tidak didukung.';

  @override
  String get settingsShareSong => 'Bagikan sebagai ChordPro';

  @override
  String get settingsSharePdf => 'Bagikan sebagai PDF';

  @override
  String get settingsCopySong => 'Salin ke papan klip';

  @override
  String get settingsPrintSong => 'Cetak lagu saja';

  @override
  String get settingsPrintSetlist => 'Cetak daftar lagu beserta lirik';

  @override
  String get settingsExportFailed => 'File tidak dapat disiapkan.';

  @override
  String get settingsCopied => 'Disalin ke papan klip.';

  @override
  String get settingsAbout => 'Tentang';

  @override
  String get settingsPrivacy => 'Privasi';

  @override
  String get settingsLegal => 'Informasi hukum';

  @override
  String get settingsClearHistory => 'Hapus riwayat';

  @override
  String get settingsClearHistoryConfirm =>
      'Hapus riwayat lagu dan daftar lagu?';

  @override
  String get settingsHistoryCleared => 'Riwayat dihapus.';

  @override
  String get accountTitle => 'Akun dan sinkronisasi';

  @override
  String get accountUnavailable =>
      'Sinkronisasi memerlukan versi Singbook yang dikonfigurasi untuk login Google. Versi ini hanya menyimpan lagu di perangkat ini.';

  @override
  String get accountSyncNow => 'Sinkronkan sekarang';

  @override
  String get accountConnected =>
      'Terhubung. Pilih Sinkronkan sekarang untuk memperbarui cadangan Anda.';

  @override
  String get accountSignIn => 'Hubungkan akun';

  @override
  String get accountSignOut => 'Keluar';

  @override
  String get accountChange => 'Ganti akun';

  @override
  String get accountSignedOut => 'Tidak terhubung';

  @override
  String get accountSyncing => 'Menyinkronkan pustaka Anda…';

  @override
  String get accountSynced => 'Pustaka disinkronkan.';

  @override
  String get accountSyncFailed => 'Pustaka Anda tidak dapat disinkronkan.';

  @override
  String get accessibilityFavorite => 'Favorit';

  @override
  String get accessibilityNotFavorite => 'Bukan favorit';

  @override
  String get accessibilitySearchField => 'Cari lagu';

  @override
  String get accessibilityClearSearch => 'Hapus teks pencarian';

  @override
  String accessibilitySongMenu(String song) {
    return 'Tindakan untuk $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Tindakan untuk $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Perluas lagu dalam $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Ciutkan lagu dalam $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Progres pemutaran, $percent persen';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Linimasa riwayat, $date';
  }

  @override
  String get loading => 'Memuat…';

  @override
  String get loadingSongs => 'Memuat lagu…';

  @override
  String get loadingSetlists => 'Memuat daftar lagu…';

  @override
  String get errorGeneric => 'Terjadi kesalahan.';

  @override
  String get errorOffline => 'Sepertinya Anda sedang offline.';

  @override
  String get errorPermission => 'Izin diperlukan untuk melanjutkan.';

  @override
  String get emptyFiltered => 'Tidak ada item yang cocok dengan filter ini.';

  @override
  String get unknownValue => 'Tidak diketahui';

  @override
  String get durationUnknown => 'Durasi tidak diketahui';

  @override
  String get metadataNotSet => 'Belum diatur';

  @override
  String get dateToday => 'Hari ini';

  @override
  String get dateYesterday => 'Kemarin';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lagu',
      one: '1 lagu',
      zero: 'Tidak ada lagu',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Biru tua';

  @override
  String get settingsPaletteSage => 'Hijau sage';

  @override
  String get settingsPaletteOcean => 'Samudra';

  @override
  String get settingsPaletteClay => 'Tanah liat';

  @override
  String get settingsPalettePlum => 'Prem';

  @override
  String get settingsFontSystem => 'Sistem';

  @override
  String get settingsFontSerif => 'Serif';

  @override
  String get settingsFontMonospace => 'Monospace';

  @override
  String get settingsLyricsPreviewExample =>
      'Saat pagi tiba, kita akan bernyanyi lagi.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Memeriksa sumber lirik: $checked dari $total selesai.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Tidak ditemukan lirik yang dapat digunakan.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Lagu yang dipilih telah diperiksa pada sumber yang diaktifkan, tetapi tidak ada yang memberikan versi lirik yang dapat digunakan.';

  @override
  String get searchDiscoveryError => 'Sumber lirik tidak dapat diperiksa.';

  @override
  String get searchDiscoveryRetry => 'Cari lirik lagi';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sumber tidak tersedia',
      one: '1 sumber tidak tersedia',
      zero: '0 sumber tidak tersedia',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Periksa koneksi Anda lalu coba lagi.';

  @override
  String get searchProviderChecks => 'Pemeriksaan sumber';

  @override
  String get searchProviderPending => 'Memeriksa';

  @override
  String get searchProviderFound => 'Kecocokan ditemukan';

  @override
  String get searchProviderRejected => 'Tidak cocok';

  @override
  String get searchProviderFailed => 'Pemeriksaan gagal';

  @override
  String get searchProviderUnavailable =>
      'Tidak ada lirik yang dapat digunakan';

  @override
  String get searchCatalogFilterHint =>
      'Pilih lagu untuk memfilter versi lirik berdasarkan akor, penanda waktu, atau bahasa.';

  @override
  String get startupErrorTitle => 'Pustaka Anda tidak dapat dibuka.';

  @override
  String setlistCopyName(String name) {
    return 'Salinan $name';
  }

  @override
  String get setlistSongMissing => 'Lagu tidak ditemukan';

  @override
  String get settingsImportTooLarge => 'File ini terlalu besar untuk diimpor.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Lompat ke $letter';
  }

  @override
  String get actionDiscard => 'Buang';

  @override
  String get editorKeepEditing => 'Lanjutkan mengedit';

  @override
  String get settingsDefaultShowChordsHint =>
      'Tampilkan akor di atas lirik jika lagu memilikinya.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Lirik bergulir mengikuti lagu. Tidak digunakan dalam mode gulir manual.';

  @override
  String get accountUnavailableTitle => 'Sinkronisasi belum disiapkan';

  @override
  String get accountSignedOutBenefits =>
      'Login dengan Google untuk mencadangkan lagu dan daftar lagu ke Google Drive serta menyinkronkan semua perangkat Anda. Lagu tetap tersimpan di perangkat ini.';

  @override
  String get accountSignInWithGoogle => 'Login dengan Google';

  @override
  String get accountWorking => 'Memproses…';

  @override
  String get accountNeverSynced => 'Belum pernah disinkronkan';

  @override
  String get accountSyncedJustNow => 'Baru saja disinkronkan';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Disinkronkan $count menit yang lalu',
      one: 'Disinkronkan 1 menit yang lalu',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Disinkronkan $count jam yang lalu',
      one: 'Disinkronkan 1 jam yang lalu',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Disinkronkan $count hari yang lalu',
      one: 'Disinkronkan 1 hari yang lalu',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perubahan yang bertentangan disimpan sebagai salinan',
      one: '1 perubahan yang bertentangan disimpan sebagai salinan',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Lagu atau daftar lagu yang sama diedit di dua tempat. Tidak ada yang hilang: versi lainnya disimpan sebagai salinan terpisah.';

  @override
  String get accountReviewConflicts => 'Tinjau salinan';

  @override
  String get songsConflictFilterActive =>
      'Hanya menampilkan salinan yang bertentangan';

  @override
  String get songsConflictFilterClear => 'Tampilkan semua lagu';

  @override
  String get songsConflictBadge => 'Salinan yang bertentangan';

  @override
  String get songsConflictEmpty => 'Tidak ada salinan yang bertentangan.';

  @override
  String get accountAutoSync => 'Sinkronkan otomatis';

  @override
  String get accountAutoSyncHint =>
      'Jaga agar pustaka tetap terbaru saat Anda membuka aplikasi dan setelah perubahan.';

  @override
  String get accountSignOutTitle => 'Keluar dari akun ini?';

  @override
  String get accountSignOutBody =>
      'Lagu dan daftar lagu Anda tetap ada di perangkat ini. Lagu tidak akan dicadangkan atau disinkronkan sampai Anda login kembali.';

  @override
  String get accountUseDifferent => 'Gunakan akun lain';

  @override
  String get accountSignInAgain => 'Login kembali';

  @override
  String get accountChooseAction => 'Pilih cara untuk melanjutkan';

  @override
  String get accountChangedTitle => 'Akun Google berbeda';

  @override
  String get accountChangedBody =>
      'Perangkat ini terakhir disinkronkan dengan akun Google lain. Pilih tindakan untuk lagu dan daftar lagu di perangkat ini.';

  @override
  String get accountChangedMerge => 'Gabungkan ke akun baru';

  @override
  String get accountChangedMergeHint =>
      'Simpan semua yang ada di perangkat ini dan tambahkan ke akun baru.';

  @override
  String get accountChangedReplace => 'Ganti dengan pustaka akun baru';

  @override
  String get accountChangedReplaceHint =>
      'Lagu di perangkat ini yang tidak ada di akun baru akan dihapus.';

  @override
  String get accountChangedSignOut => 'Batal dan keluar';

  @override
  String get accountStatusSignedOut => 'Akun dan sinkronisasi: belum login';

  @override
  String get accountStatusSignedIn => 'Akun dan sinkronisasi: sudah login';

  @override
  String get accountStatusSyncing =>
      'Akun dan sinkronisasi: sedang menyinkronkan';

  @override
  String get accountStatusSynced => 'Akun dan sinkronisasi: pustaka terbaru';

  @override
  String get accountStatusError =>
      'Akun dan sinkronisasi: ada masalah, ketuk untuk meninjau';

  @override
  String get accountNoticeConflicts =>
      'Beberapa lagu diedit di dua tempat. Salinannya dipertahankan.';

  @override
  String get accountNoticeSignedIn => 'Login berhasil.';

  @override
  String get accountNoticeSignedOut =>
      'Anda telah keluar. Lagu Anda tetap ada di perangkat ini.';

  @override
  String get syncErrorNotConfigured =>
      'Sinkronisasi belum disiapkan di versi ini.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Gunakan versi Singbook yang dikonfigurasi untuk login Google.';

  @override
  String get syncErrorNotSignedIn => 'Anda belum login.';

  @override
  String get syncErrorNotSignedInHint =>
      'Login untuk menyinkronkan pustaka Anda.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google meminta Anda untuk login kembali.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Login kembali untuk melanjutkan sinkronisasi. Lagu Anda aman di perangkat ini.';

  @override
  String get syncErrorAccessDenied =>
      'Singbook tidak memiliki izin untuk menggunakan Google Drive.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Login kembali dan izinkan akses ke Drive saat diminta.';

  @override
  String get syncErrorRateLimited => 'Google sedang membatasi permintaan.';

  @override
  String get syncErrorRateLimitedHint =>
      'Tunggu beberapa menit, lalu coba lagi.';

  @override
  String get syncErrorStorageFull => 'Google Drive Anda penuh.';

  @override
  String get syncErrorStorageFullHint =>
      'Kosongkan ruang di Drive, lalu coba lagi.';

  @override
  String get syncErrorNetwork => 'Google tidak dapat dijangkau.';

  @override
  String get syncErrorNetworkHint =>
      'Periksa koneksi internet Anda, lalu coba lagi.';

  @override
  String get syncErrorAccountChanged =>
      'Akun Google yang berbeda telah digunakan.';

  @override
  String get syncErrorAccountChangedHint =>
      'Pilih apakah pustaka perangkat ini akan digabungkan dengan akun atau diganti.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Pustaka yang disinkronkan lebih besar daripada yang dapat ditangani Singbook.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Hapus beberapa lagu atau daftar dari pustaka yang disinkronkan, lalu coba lagi.';

  @override
  String get syncErrorSignInFailed => 'Login tidak selesai.';

  @override
  String get syncErrorSignInFailedHint => 'Coba login lagi.';

  @override
  String get syncErrorGeneric => 'Pustaka Anda tidak dapat disinkronkan.';

  @override
  String get syncErrorGenericHint =>
      'Coba lagi sebentar lagi. Lagu Anda tetap aman di perangkat ini.';

  @override
  String get editorDurationInvalid =>
      'Masukkan detik, atau menit dan detik, misalnya 3:45.';

  @override
  String get editorNumberInvalid => 'Masukkan angka.';

  @override
  String get accountReplaceConfirmTitle => 'Hapus lagu lokal?';

  @override
  String get accountReplaceConfirmBody =>
      'Lagu dan daftar lagu di perangkat ini yang tidak ada di akun baru akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get accountReplaceConfirmAction => 'Hapus dan ganti';

  @override
  String get accountSuspiciousTitle => 'Item tidak ditemukan di Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count item yang pernah disinkronkan perangkat ini tidak ditemukan di Google Drive.',
      one:
          '$count item yang pernah disinkronkan perangkat ini tidak ditemukan di Google Drive.',
    );
    return '$_temp0 Ini bisa terjadi jika data aplikasi dihapus melalui setelan Google. Belum ada yang dihapus.';
  }

  @override
  String get accountSuspiciousDelete => 'Hapus juga di sini';

  @override
  String get accountSuspiciousKeep => 'Simpan lagu saya dan unggah lagi';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hapus $count item dari perangkat ini?',
      one: 'Hapus $count item dari perangkat ini?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Lagu dan daftar lagu ini akan dihapus permanen dari perangkat ini. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Hapus dari perangkat ini';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Item tidak ditemukan di Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Tidak ada yang dihapus. Pilih untuk menghapusnya juga di sini atau mengunggahnya lagi.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive berubah saat sinkronisasi berlangsung.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Tidak ada yang hilang. Sinkronkan lagi untuk mengambil perubahan terbaru.';

  @override
  String get syncErrorInvalidLocalData =>
      'Sebagian data di perangkat ini tidak dapat disinkronkan.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Lagu atau daftar lagu tidak dapat dibaca. Impor atau buat ulang, lalu sinkronkan lagi.';

  @override
  String get syncErrorNoAccountChange =>
      'Tidak ada perubahan akun yang perlu diselesaikan.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Sinkronkan lagi untuk melanjutkan.';

  @override
  String get accountSyncWarningTitle =>
      'Tersinkron, tetapi beberapa file dilewati';

  @override
  String get accountSyncWarningBody =>
      'Beberapa file tidak dapat digunakan dan dibiarkan apa adanya. Sisanya sudah diperbarui.';

  @override
  String get accountSyncWarningTooLarge =>
      'Sebuah file terlalu besar untuk disinkronkan dan dilewati. Sisanya sudah diperbarui.';

  @override
  String get accountSyncWarningInvalid =>
      'Sebuah file tidak dapat dibaca dan dilewati. Sisanya sudah diperbarui.';

  @override
  String get accountNoticeSyncSkipped => 'Tersinkron. Beberapa file dilewati.';

  @override
  String get settingsExportPdfTooLarge =>
      'PDF ini akan terlalu besar. Coba pilih lebih sedikit lagu atau bagikan sebagai teks.';

  @override
  String get settingsTimingTooLarge =>
      'Data timing terlalu besar (lebih dari 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Cadangan ini mencantumkan lagu yang sama dua kali, jadi tidak ada yang diimpor.';

  @override
  String get setlistSaveConflict =>
      'Daftar lagu berubah di tempat lain. Perubahan Anda disimpan sebagai salinan terpisah.';

  @override
  String get sectionVerse => 'Bait';

  @override
  String get sectionChorus => 'Reff';

  @override
  String get sectionBridge => 'Bridge';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Pra-reff';

  @override
  String get sectionPostChorus => 'Pasca-reff';

  @override
  String get sectionInstrumental => 'Bagian instrumental';

  @override
  String get sectionInterlude => 'Interlude';

  @override
  String get sectionSolo => 'Solo';

  @override
  String get sectionRefrain => 'Refren';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Koda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Penutup';
}
