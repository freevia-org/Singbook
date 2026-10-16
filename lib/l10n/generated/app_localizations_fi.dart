// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Rauhallinen paikka, jossa löydät ja järjestät kappaleesi ja laulat niiden mukana.';

  @override
  String get aboutMadeForSinging => 'Tehty yhdessä laulamiseen';

  @override
  String get aboutDetails =>
      'Hae käytössä olevista lähteistä, vertaile versioita, pidä sanat ja soinnut yhdessä ja järjestä kappaleet listoiksi. Kirjastosi tallennetaan tälle laitteelle; valinnainen Google Drive -synkronointi käyttää Google-tiliäsi. Haut lähetetään suoraan käytössä oleville lähteille.';

  @override
  String get aboutSupport => 'Tuki ja palaute';

  @override
  String get menuTypeNewSong => 'Kirjoita uusi kappale';

  @override
  String appVersion(String version) {
    return 'Versio $version';
  }

  @override
  String get navHome => 'Etusivu';

  @override
  String get navSongs => 'Kappaleet';

  @override
  String get navSetlists => 'Settilistat';

  @override
  String get navSettings => 'Asetukset';

  @override
  String get navSettingsCompact => 'Asetukset';

  @override
  String get navSearch => 'Haku';

  @override
  String get navBack => 'Takaisin';

  @override
  String get appExitBackAgain => 'Poistu painamalla Takaisin uudelleen';

  @override
  String get navClose => 'Sulje';

  @override
  String get navMore => 'Lisää toimintoja';

  @override
  String get actionCancel => 'Peruuta';

  @override
  String get actionSave => 'Tallenna';

  @override
  String get actionDone => 'Valmis';

  @override
  String get actionEdit => 'Muokkaa';

  @override
  String get actionDelete => 'Poista';

  @override
  String get actionShare => 'Jaa';

  @override
  String get actionPrint => 'Tulosta';

  @override
  String get actionCopy => 'Kopioi';

  @override
  String get actionClear => 'Tyhjennä';

  @override
  String get actionRetry => 'Yritä uudelleen';

  @override
  String get actionRefresh => 'Päivitä';

  @override
  String get actionImport => 'Tuo';

  @override
  String get actionExport => 'Vie';

  @override
  String get actionExpand => 'Laajenna';

  @override
  String get actionCollapse => 'Kutista';

  @override
  String get actionAdd => 'Lisää';

  @override
  String get actionCreate => 'Luo';

  @override
  String get actionRemove => 'Poista';

  @override
  String get actionDuplicate => 'Monista';

  @override
  String get actionMoveUp => 'Siirrä ylös';

  @override
  String get actionMoveDown => 'Siirrä alas';

  @override
  String get actionPrevious => 'Edellinen';

  @override
  String get actionNext => 'Seuraava';

  @override
  String get searchHint => 'Hae kappaleita, artisteja tai sanoituksia';

  @override
  String get searchCatalogHint => 'Hae kappaletta tai artistia';

  @override
  String get searchChangeSong => 'Vaihda kappaletta';

  @override
  String get searchSelectedPreview => 'Valittu esikatselu';

  @override
  String get searchSubmit => 'Hae';

  @override
  String get searchFilters => 'Hakuasetukset';

  @override
  String get searchFiltersShow => 'Näytä hakuasetukset';

  @override
  String get searchFiltersHide => 'Piilota hakuasetukset';

  @override
  String get searchFilterArtist => 'Artisti';

  @override
  String get searchFilterTitle => 'Kappaleen nimi';

  @override
  String get searchFilterLyrics => 'Sanoitukset';

  @override
  String get searchFilterChords => 'Sisältää soinnut';

  @override
  String get searchFilterTimed => 'Ajastetut sanoitukset';

  @override
  String get searchFilterLanguage => 'Kieli';

  @override
  String get searchFilterAll => 'Mikä tahansa';

  @override
  String get searchAutocompleteLabel => 'Ehdotukset';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tulosta',
      one: '1 tulos',
      zero: 'Ei tuloksia',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Anna haettava kappale, artisti tai sanoituksen kohta.';

  @override
  String get searchCatalogEmptyQuery => 'Anna haettava kappale tai artisti.';

  @override
  String get searchNoResults => 'Kappaleita ei löytynyt. Kokeile toista hakua.';

  @override
  String get searchLoading => 'Haetaan kappaleita…';

  @override
  String get searchError => 'Hakua ei voitu suorittaa.';

  @override
  String get searchOnlineTab => 'Verkossa';

  @override
  String get searchRecentTab => 'Viimeisimmät';

  @override
  String get searchFavoritesTab => 'Suosikit';

  @override
  String get searchSuggested => 'Ehdotettu osuma';

  @override
  String get searchAlternatives => 'Muut osumat';

  @override
  String get searchCompare => 'Vertaa versioita';

  @override
  String get searchChooseVersion => 'Valitse tämä versio';

  @override
  String get searchFullPreview => 'Koko esikatselu';

  @override
  String get searchArrangementNotes => 'Sovitusmuistiinpanot';

  @override
  String get searchOpenLyrics => 'Avaa sanat';

  @override
  String get searchContributions => 'Käytetyt lähteet';

  @override
  String get searchVersionChecking => 'Tarkistetaan tätä versiota…';

  @override
  String get searchVersionUnavailable =>
      'Tätä versiota ei voi käyttää. Valitse toinen versio.';

  @override
  String get searchPreviewUnavailable =>
      'Sanojen esikatselua ei ole saatavilla.';

  @override
  String get searchSongMatch => 'Kappaleosuma';

  @override
  String get searchRecordingMatch => 'Ääniteosuma';

  @override
  String get searchMatchUnverified => 'Äänitettä ei ole vahvistettu';

  @override
  String get searchMatchExact => 'Täsmällinen ääniteosuma';

  @override
  String get searchMatchPossible => 'Mahdollinen osuma';

  @override
  String get searchAvailability => 'Saatavuus';

  @override
  String get searchLyricsAvailable => 'Sanoitukset saatavilla';

  @override
  String get searchLyricsUnavailable => 'Sanoituksia ei saatavilla';

  @override
  String get searchChordsAvailable => 'Soinnut saatavilla';

  @override
  String get searchChordsUnavailable => 'Ei sointuja';

  @override
  String get searchTimingAvailable => 'Ajastus saatavilla';

  @override
  String get searchTimingUnavailable => 'Ei ajastusta';

  @override
  String get searchDurationUnknown => 'Kesto tuntematon';

  @override
  String searchRating(String rating) {
    return 'Arvio $rating';
  }

  @override
  String get searchSourceLabel => 'Lähde';

  @override
  String get searchMetadata => 'Kappaleen tiedot';

  @override
  String get searchAlbum => 'Albumi';

  @override
  String get searchArtist => 'Artisti';

  @override
  String get searchYear => 'Vuosi';

  @override
  String get searchLanguage => 'Kieli';

  @override
  String get searchViewVersions => 'Näytä versiot';

  @override
  String get searchSaved => 'Kappale tallennettiin kirjastoosi.';

  @override
  String get searchSaveOpenLyrics => 'Tallenna ja avaa sanat';

  @override
  String get searchOtherResults => 'Muut tulokset';

  @override
  String get searchSaveFailed => 'Kappaletta ei voitu tallentaa.';

  @override
  String get homeRecentSongs => 'Viimeisimmät kappaleet';

  @override
  String get homeRecentlyPlayed => 'Viimeksi soitettu';

  @override
  String get homeFavorites => 'Suosikit';

  @override
  String get homeHistory => 'Historia';

  @override
  String get homeHistoryClear => 'Tyhjennä historia';

  @override
  String get homeHistoryCleared => 'Historia tyhjennetty.';

  @override
  String get homeHistoryEmpty => 'Avaamasi kappaleet näkyvät täällä.';

  @override
  String get homeFavoritesEmpty =>
      'Suosikkikappaleesi ja settilistasi näkyvät täällä.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kohdetta näkyvissä',
      one: '1 kohde näkyvissä',
      zero: '0 kohdetta näkyvissä',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Viimeisimmät kappaleesi ja settilistasi näkyvät täällä.';

  @override
  String get homeTimelineLabel => 'Historian aikajana';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'Koko historia';

  @override
  String get homeShowFavorites => 'Näytä suosikit';

  @override
  String get homeShowRecent => 'Näytä viimeisimmät';

  @override
  String get songsTitle => 'Kappaleet';

  @override
  String get songsEmpty => 'Kappaleesi näkyvät täällä.';

  @override
  String get songsEmptySearch => 'Yksikään kappale ei vastaa hakuasi.';

  @override
  String get songsAdd => 'Lisää kappale';

  @override
  String get songsSortAlphabetical => 'Lajittele aakkosjärjestykseen';

  @override
  String get songsAlphabetNavigation => 'Kappalehakemisto';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kertaa',
      one: 'kerran',
      zero: 'ei koskaan',
    );
    return 'Avattu $_temp0';
  }

  @override
  String get songFavoriteAdd => 'Lisää suosikkeihin';

  @override
  String get songFavoriteRemove => 'Poista suosikeista';

  @override
  String get songMenuLabel => 'Kappaleen toiminnot';

  @override
  String get songInfo => 'Kappaleen tiedot';

  @override
  String get setlistMenuLabel => 'Settilistan toiminnot';

  @override
  String get songAddToSetlist => 'Lisää settilistaan';

  @override
  String get songCopyChordPro => 'Kopioi ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Poistetaanko kappale?';

  @override
  String get songDeleteConfirmMessage => 'Kappale poistetaan kirjastostasi.';

  @override
  String get songDeleted => 'Kappale poistettu.';

  @override
  String get setlistsTitle => 'Settilistat';

  @override
  String get setlistsEmpty =>
      'Luo settilista seuraavaa harjoitusta tai esiintymistä varten.';

  @override
  String get setlistsEmptySearch => 'Yksikään settilista ei vastaa hakuasi.';

  @override
  String get setlistCreate => 'Uusi settilista';

  @override
  String get setlistNameHint => 'Settilistan nimi';

  @override
  String get setlistNotes => 'Muistiinpanot';

  @override
  String get setlistEntryOverride => 'Kappalekohtainen sävellaji ja capo';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kappaletta',
      one: '1 kappale',
      zero: 'Ei kappaleita',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Vähintään $duration';
  }

  @override
  String get setlistDurationUnknown => 'Kesto tuntematon';

  @override
  String setlistActivity(String date) {
    return 'Viimeisin toiminta $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Luotu $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Muokattu $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Soitettu viimeksi $date';
  }

  @override
  String get setlistSongsEmpty =>
      'Tässä settilistassa ei ole vielä kappaleita.';

  @override
  String get setlistAddSongs => 'Lisää kappaleita';

  @override
  String get setlistReorder => 'Järjestä kappaleet uudelleen';

  @override
  String setlistMoveSongUp(String song) {
    return 'Siirrä $song ylös';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Siirrä $song alas';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Poista $song settilistasta';
  }

  @override
  String get setlistDuplicate => 'Monista settilista';

  @override
  String get setlistFavoriteAdd => 'Lisää settilista suosikkeihin';

  @override
  String get setlistFavoriteRemove => 'Poista settilista suosikeista';

  @override
  String get setlistShare => 'Jaa settilistatiedostona';

  @override
  String get setlistSharePdf => 'Jaa PDF-tiedostona';

  @override
  String get setlistPrint => 'Tulosta';

  @override
  String get setlistDeleteConfirmTitle => 'Poistetaanko settilista?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Settilista poistetaan. Kirjastosi kappaleet säilyvät.';

  @override
  String get setlistDeleted => 'Settilista poistettu.';

  @override
  String get readerTitle => 'Sanoitukset';

  @override
  String get readerNoLyrics => 'Sanoituksia ei ole vielä lisätty.';

  @override
  String get readerShowChords => 'Näytä soinnut';

  @override
  String get readerHideChords => 'Piilota soinnut';

  @override
  String get readerTranspose => 'Transponoi soinnut';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puolisävelaskelta',
      one: '1 puolisävelaskel',
      zero: '0 puolisävelaskelta',
    );
    return 'Transponoi $_temp0';
  }

  @override
  String get readerSaved => 'Tallennettu';

  @override
  String get readerEdit => 'Muokkaa sanoituksia ja tietoja';

  @override
  String get playerPlay => 'Toista';

  @override
  String get playerPause => 'Tauko';

  @override
  String get playerResume => 'Jatka sanoitusten vieritystä';

  @override
  String get playerSeek => 'Toistokohta';

  @override
  String playerElapsed(String time) {
    return 'Kulunut aika $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Aikaa jäljellä $time';
  }

  @override
  String get playerTimingMode => 'Vieritystila';

  @override
  String get playerTimedLyrics => 'Ajastetut sanoitukset';

  @override
  String get playerStartScroll => 'Aloita automaattinen vieritys';

  @override
  String get playerEstimatedPace => 'Arvioitu nopeus';

  @override
  String get playerScrollSpeed => 'Vieritysnopeus';

  @override
  String playerEstimatedDuration(String time) {
    return 'Arvioitu kesto: $time';
  }

  @override
  String get playerLyricsOnly => 'Sanojen vieritys · ei ääntä';

  @override
  String get playerManualScroll => 'Manuaalinen vieritys';

  @override
  String get playerTimingStatusReady =>
      'Sanoitukset seuraavat käytettävissä olevaa ajastusta.';

  @override
  String get playerTimingStatusEstimated =>
      'Vieritysnopeus arvioidaan kappaleen keston perusteella.';

  @override
  String get playerTimingStatusManual => 'Vieritä sanoituksia itse.';

  @override
  String get playerTimingStatusUnavailable =>
      'Ajastettu vieritys ei ole käytettävissä tälle kappaleelle.';

  @override
  String get playerDurationUnknown =>
      'Lisää kappaleen kesto, jotta voit käyttää arvioitua vieritystä.';

  @override
  String get playerProgressLabel => 'Kappaleen eteneminen';

  @override
  String get playerCurrentSection => 'Nykyinen osio';

  @override
  String get playerPreviousSection => 'Edellinen osio';

  @override
  String get playerNextSection => 'Seuraava osio';

  @override
  String get playerPreviousSectionSong =>
      'Edellinen osio · pidä painettuna siirtyäksesi settilistan edelliseen kappaleeseen';

  @override
  String get playerNextSectionSong =>
      'Seuraava osio · pidä painettuna siirtyäksesi settilistan seuraavaan kappaleeseen';

  @override
  String get playerPreviousSong => 'Edellinen kappale';

  @override
  String get playerNextSong => 'Seuraava kappale';

  @override
  String get editorTitle => 'Muokkaa kappaletta';

  @override
  String get editorTitleField => 'Kappaleen nimi';

  @override
  String get editorArtistField => 'Artisti';

  @override
  String get editorAlbumField => 'Albumi';

  @override
  String get editorLyricsField => 'Sanoitukset';

  @override
  String get editorChordsField => 'Soinnut';

  @override
  String get editorKeyField => 'Sävellaji';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Vire';

  @override
  String get editorTempoField => 'Tempo';

  @override
  String get editorDurationField => 'Kesto';

  @override
  String get editorTimeSignatureField => 'Tahtilaji';

  @override
  String get editorLanguageField => 'Kieli';

  @override
  String get editorYearField => 'Vuosi';

  @override
  String get editorComposerField => 'Säveltäjä';

  @override
  String get editorLyricistField => 'Sanoittaja';

  @override
  String get editorCopyrightField => 'Tekijänoikeus';

  @override
  String get editorLicenseField => 'Lisenssi';

  @override
  String get songInfoSources => 'Lähteet ja tekijätiedot';

  @override
  String get searchMatchSameSong =>
      'Sama kappale; äänitettä ei ole vahvistettu';

  @override
  String get searchMatchNeedsAgreement =>
      'Kappaleen sanat on vahvistettava nuottien perusteella';

  @override
  String get searchMatchDifferentLyrics =>
      'Sanoitukset eroavat valitusta kappaleesta';

  @override
  String get searchMatchCombinedSources => 'Tiedot koottu useista lähteistä';

  @override
  String get searchCombinedLabel => 'Kaikki';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kappaleosumaa',
      one: '1 kappaleosuma',
      zero: '0 kappaleosumaa',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lähdeversiota',
      one: '1 lähdeversio',
      zero: '0 lähdeversiota',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'Paras saatavilla oleva osuma';

  @override
  String get providerDescriptionUnknown => 'Kappaleen lähde';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Lataa lähteestä ChordPro-tiedosto ja tuo se sitten.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Lataa tiedosto maksuttomalla tilillä ja tuo se sitten.';

  @override
  String get providerDescPublicChordSheets => 'Julkisia sointulehtiä.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Historiallisilla sanoituksilla on teoskohtainen lisenssi.';

  @override
  String get providerDescLicensedCatalog => 'Lisensoitu sanoituskatalogi.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Alkuperäiskappaleita Creative Commons BY -lisenssillä.';

  @override
  String get providerDescPerSongLicense =>
      'Sanoitukset lisensoidaan kappalekohtaisesti.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Vain äänitteen ja julkaisun tiedot.';

  @override
  String get providerDescCompositionMetadataOnly => 'Vain sävellyksen tiedot.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Kansikuvat vain täsmääville äänitteille.';

  @override
  String get providerCapabilityLyrics => 'Sanoitukset';

  @override
  String get providerCapabilityChords => 'Soinnut';

  @override
  String get providerCapabilityTiming => 'Ajastetut sanoitukset';

  @override
  String get providerCapabilitySearch => 'Haku';

  @override
  String get providerCapabilityMetadata => 'Kappaleen tiedot';

  @override
  String get editorArtworkField => 'Kansikuvan linkki';

  @override
  String get editorLyricsHint =>
      'Muokkaa sanoituksia tai sointuja napauttamalla riviä.';

  @override
  String get editorSave => 'Tallenna muutokset';

  @override
  String get editorSaved => 'Muutokset tallennettu.';

  @override
  String get editorSaveFailed => 'Muutoksia ei voitu tallentaa.';

  @override
  String get editorSaveConflict =>
      'Kappaletta muokattiin muualla. Muutoksesi tallennettiin erillisenä kopiona.';

  @override
  String get editorUnsavedTitle => 'Hylätäänkö muutokset?';

  @override
  String get editorUnsavedMessage => 'Muutoksia ei ole tallennettu.';

  @override
  String get editorFieldRequired => 'Anna kappaleen nimi.';

  @override
  String get settingsTitle => 'Asetukset';

  @override
  String get settingsAppearance => 'Ulkoasu';

  @override
  String get settingsTheme => 'Teema';

  @override
  String get settingsThemeSystem => 'Käytä laitteen asetusta';

  @override
  String get settingsThemeLight => 'Vaalea';

  @override
  String get settingsThemeDark => 'Tumma';

  @override
  String get settingsColorPalette => 'Väripaletti';

  @override
  String get settingsFont => 'Fontti';

  @override
  String get settingsTextSize => 'Tekstin koko';

  @override
  String get settingsLyricsPreview => 'Sanoitusten esikatselu';

  @override
  String get settingsPlayer => 'Sanoitusten soitin';

  @override
  String get settingsDefaultShowChords => 'Näytä soinnut oletuksena';

  @override
  String get settingsDefaultAutoscroll => 'Vieritä sanoituksia automaattisesti';

  @override
  String get settingsDefaultTiming => 'Oletusvieritystila';

  @override
  String get settingsLanguage => 'Sovelluksen kieli';

  @override
  String get settingsLanguageSystem => 'Käytä laitteen kieltä';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageBulgarian => 'Български';

  @override
  String get settingsLanguageUkrainian => 'Українська';

  @override
  String get settingsSources => 'Sanoituslähteet';

  @override
  String settingsSourceEnabled(String source) {
    return 'Ota lähde $source käyttöön';
  }

  @override
  String get settingsSourceRefresh => 'Päivitä lähdeluettelo';

  @override
  String get settingsSourcesUpdated => 'Lähteet päivitetty.';

  @override
  String get settingsSourcesUpdateFailed => 'Lähteitä ei voitu päivittää.';

  @override
  String get settingsImport => 'Tuo kappaleita';

  @override
  String get settingsImportChordPro => 'Tuo ChordPro-tiedosto';

  @override
  String get settingsImportSetlist => 'Tuo settilistatiedosto';

  @override
  String get settingsImportSuccess => 'Tuonti valmis.';

  @override
  String get settingsImportFailed => 'Tätä tiedostoa ei voitu tuoda.';

  @override
  String get settingsImportUnsupported => 'Tätä tiedostotyyppiä ei tueta.';

  @override
  String get settingsShareSong => 'Jaa ChordPro-muodossa';

  @override
  String get settingsSharePdf => 'Jaa PDF-tiedostona';

  @override
  String get settingsCopySong => 'Kopioi leikepöydälle';

  @override
  String get settingsPrintSong => 'Tulosta vain kappale';

  @override
  String get settingsPrintSetlist => 'Tulosta settilista sanoituksineen';

  @override
  String get settingsExportFailed => 'Tiedostoa ei voitu valmistella.';

  @override
  String get settingsCopied => 'Kopioitu leikepöydälle.';

  @override
  String get settingsAbout => 'Tietoja';

  @override
  String get settingsPrivacy => 'Tietosuoja';

  @override
  String get settingsLegal => 'Lakiasiat';

  @override
  String get settingsClearHistory => 'Tyhjennä historia';

  @override
  String get settingsClearHistoryConfirm =>
      'Tyhjennetäänkö kappaleiden ja settilistojen historia?';

  @override
  String get settingsHistoryCleared => 'Historia tyhjennetty.';

  @override
  String get accountTitle => 'Tili ja synkronointi';

  @override
  String get accountUnavailable =>
      'Synkronointi edellyttää Singbook-versiota, jossa Google-kirjautuminen on määritetty. Tässä versiossa kappaleet säilyvät vain tällä laitteella.';

  @override
  String get accountSyncNow => 'Synkronoi nyt';

  @override
  String get accountConnected =>
      'Yhdistetty. Päivitä varmuuskopio valitsemalla Synkronoi nyt.';

  @override
  String get accountSignIn => 'Yhdistä tili';

  @override
  String get accountSignOut => 'Kirjaudu ulos';

  @override
  String get accountChange => 'Vaihda tiliä';

  @override
  String get accountSignedOut => 'Ei yhdistetty';

  @override
  String get accountSyncing => 'Kirjastoa synkronoidaan…';

  @override
  String get accountSynced => 'Kirjasto synkronoitu.';

  @override
  String get accountSyncFailed => 'Kirjastoa ei voitu synkronoida.';

  @override
  String get accessibilityFavorite => 'Suosikki';

  @override
  String get accessibilityNotFavorite => 'Ei suosikki';

  @override
  String get accessibilitySearchField => 'Hae kappaleita';

  @override
  String get accessibilityClearSearch => 'Tyhjennä hakuteksti';

  @override
  String accessibilitySongMenu(String song) {
    return 'Kappaleen $song toiminnot';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Settilistan $setlist toiminnot';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Laajenna settilistan $setlist kappaleet';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Kutista settilistan $setlist kappaleet';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Toiston eteneminen, $percent prosenttia';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Historian aikajana, $date';
  }

  @override
  String get loading => 'Ladataan…';

  @override
  String get loadingSongs => 'Ladataan kappaleita…';

  @override
  String get loadingSetlists => 'Ladataan settilistoja…';

  @override
  String get errorGeneric => 'Jokin meni pieleen.';

  @override
  String get errorOffline => 'Vaikuttaa siltä, että et ole verkossa.';

  @override
  String get errorPermission => 'Jatkamiseen tarvitaan käyttöoikeus.';

  @override
  String get emptyFiltered => 'Yksikään kohde ei vastaa näitä suodattimia.';

  @override
  String get unknownValue => 'Tuntematon';

  @override
  String get durationUnknown => 'Kesto tuntematon';

  @override
  String get metadataNotSet => 'Ei asetettu';

  @override
  String get dateToday => 'Tänään';

  @override
  String get dateYesterday => 'Eilen';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kappaletta',
      one: '1 kappale',
      zero: 'Ei kappaleita',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Laivastonsininen';

  @override
  String get settingsPaletteSage => 'Salvianvihreä';

  @override
  String get settingsPaletteOcean => 'Meri';

  @override
  String get settingsPaletteClay => 'Savi';

  @override
  String get settingsPalettePlum => 'Luumu';

  @override
  String get settingsFontSystem => 'Järjestelmä';

  @override
  String get settingsFontSerif => 'Serif';

  @override
  String get settingsFontMonospace => 'Tasalevyinen';

  @override
  String get settingsLyricsPreviewExample => 'Kun aamu koittaa, laulamme taas.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Tarkistetaan sanoituslähteitä: $checked/$total valmiina.';
  }

  @override
  String get searchDiscoveryNoLyrics =>
      'Käyttökelpoisia sanoituksia ei löytynyt.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Valittu kappale tarkistettiin käytössä olevista lähteistä, mutta mikään niistä ei palauttanut käyttökelpoista sanoitusversiota.';

  @override
  String get searchDiscoveryError => 'Sanoituslähteitä ei voitu tarkistaa.';

  @override
  String get searchDiscoveryRetry => 'Hae sanoituksia uudelleen';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lähdettä ei ole käytettävissä',
      one: '1 lähde ei ole käytettävissä',
      zero: '0 lähdettä ei ole käytettävissä',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Tarkista yhteys ja yritä uudelleen.';

  @override
  String get searchProviderChecks => 'Lähteiden tarkistukset';

  @override
  String get searchProviderPending => 'Tarkistetaan';

  @override
  String get searchProviderFound => 'Osuma löytyi';

  @override
  String get searchProviderRejected => 'Ei vastaa';

  @override
  String get searchProviderFailed => 'Tarkistus epäonnistui';

  @override
  String get searchProviderUnavailable => 'Käyttökelpoisia sanoituksia ei ole';

  @override
  String get searchCatalogFilterHint =>
      'Suodata sanoitusversioita sointujen, ajastuksen tai kielen mukaan valitsemalla kappale.';

  @override
  String get startupErrorTitle => 'Kirjastoa ei voitu avata.';

  @override
  String setlistCopyName(String name) {
    return '$name – kopio';
  }

  @override
  String get setlistSongMissing => 'Puuttuva kappale';

  @override
  String get settingsImportTooLarge =>
      'Tämä tiedosto on liian suuri tuotavaksi.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Siirry kohtaan $letter';
  }

  @override
  String get actionDiscard => 'Hylkää';

  @override
  String get editorKeepEditing => 'Jatka muokkausta';

  @override
  String get settingsDefaultShowChordsHint =>
      'Näytä soinnut sanoitusten yläpuolella, kun kappaleessa on soinnut.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Sanoitukset vierivät kappaleen tahdissa. Ei käytössä manuaalisessa vieritystilassa.';

  @override
  String get accountUnavailableTitle => 'Synkronointia ei ole määritetty';

  @override
  String get accountSignedOutBenefits =>
      'Google Driveen yhdistäminen synkronoi kirjastosi. Sen jälkeen kappaleiden muutokset synkronoidaan automaattisesti.';

  @override
  String get accountManualSyncHint =>
      'Voit myös synkronoida kirjastosi napauttamalla Synkronoi nyt.';

  @override
  String get accountSignInWithGoogle => 'Kirjaudu Google-tilillä';

  @override
  String get accountWorking => 'Käsitellään…';

  @override
  String get accountNeverSynced => 'Ei koskaan synkronoitu';

  @override
  String get accountSyncedJustNow => 'Synkronoitu juuri nyt';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synkronoitu $count minuuttia sitten',
      one: 'Synkronoitu 1 minuutti sitten',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synkronoitu $count tuntia sitten',
      one: 'Synkronoitu 1 tunti sitten',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synkronoitu $count päivää sitten',
      one: 'Synkronoitu 1 päivä sitten',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ristiriitaista muokkausta säilytetty kopioina',
      one: '1 ristiriitainen muokkaus säilytetty kopiona',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Samaa kappaletta tai settilistaa muokattiin kahdessa paikassa. Mitään ei kadonnut: toinen versio tallennettiin erillisenä kopiona.';

  @override
  String get accountReviewConflicts => 'Tarkista kopiot';

  @override
  String get songsConflictFilterActive =>
      'Näytetään vain ristiriitaiset kopiot';

  @override
  String get songsConflictFilterClear => 'Näytä kaikki kappaleet';

  @override
  String get songsConflictBadge => 'Ristiriitainen kopio';

  @override
  String get songsConflictEmpty => 'Ei ristiriitaisia kopioita.';

  @override
  String get accountAutoSync => 'Synkronoi automaattisesti';

  @override
  String get accountAutoSyncHint =>
      'Synkronointi tapahtuu yhdistämisen jälkeen sekä kappaleen lisäämisen, muokkaamisen tai poistamisen jälkeen.';

  @override
  String get accountSignOutTitle => 'Kirjaudutaanko tältä tililtä ulos?';

  @override
  String get accountSignOutBody =>
      'Kappaleet ja settilistat säilyvät tällä laitteella. Niitä ei varmuuskopioida tai synkronoida ennen kuin kirjaudut uudelleen sisään.';

  @override
  String get accountUseDifferent => 'Käytä toista tiliä';

  @override
  String get accountSignInAgain => 'Kirjaudu uudelleen sisään';

  @override
  String get accountChooseAction => 'Valitse, miten jatkat';

  @override
  String get accountChangedTitle => 'Toinen Google-tili';

  @override
  String get accountChangedBody =>
      'Tämä laite synkronoitiin viimeksi toisella Google-tilillä. Valitse, mitä tällä laitteella oleville kappaleille ja settilistoille tehdään.';

  @override
  String get accountChangedMerge => 'Yhdistä uuteen tiliin';

  @override
  String get accountChangedMergeHint =>
      'Säilytä kaikki tällä laitteella ja lisää ne uuteen tiliin.';

  @override
  String get accountChangedReplace => 'Korvaa uuden tilin kirjastolla';

  @override
  String get accountChangedReplaceHint =>
      'Tältä laitteelta poistetaan kappaleet, joita ei ole uudella tilillä.';

  @override
  String get accountChangedSignOut => 'Peruuta ja kirjaudu ulos';

  @override
  String get accountStatusSignedOut => 'Tili ja synkronointi: ei kirjautunut';

  @override
  String get accountStatusSignedIn => 'Tili ja synkronointi: kirjautunut';

  @override
  String get accountStatusSyncing => 'Tili ja synkronointi: synkronoidaan';

  @override
  String get accountStatusSynced =>
      'Tili ja synkronointi: kirjasto ajan tasalla';

  @override
  String get accountStatusError =>
      'Tili ja synkronointi: ongelma, tarkista napauttamalla';

  @override
  String get accountNoticeConflicts =>
      'Joitakin kappaleita muokattiin kahdessa paikassa. Kopiot säilytettiin.';

  @override
  String get accountNoticeSignedIn => 'Kirjautunut sisään.';

  @override
  String get accountNoticeSignedOut =>
      'Kirjautunut ulos. Kappaleet säilyvät tällä laitteella.';

  @override
  String get syncErrorNotConfigured =>
      'Synkronointia ei ole määritetty tässä versiossa.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Käytä Singbook-versiota, jossa Google-kirjautuminen on määritetty.';

  @override
  String get syncErrorNotSignedIn => 'Et ole kirjautunut sisään.';

  @override
  String get syncErrorNotSignedInHint =>
      'Synkronoi kirjasto kirjautumalla sisään.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Google edellyttää, että kirjaudut uudelleen sisään.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Jatka synkronointia kirjautumalla uudelleen sisään. Kappaleet ovat turvassa tällä laitteella.';

  @override
  String get syncErrorAccessDenied =>
      'Singbookilla ei ole oikeutta käyttää Google Drivea.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Kirjaudu uudelleen sisään ja salli Drive-käyttö pyydettäessä.';

  @override
  String get syncErrorRateLimited =>
      'Google rajoittaa pyyntöjä tällä hetkellä.';

  @override
  String get syncErrorRateLimitedHint =>
      'Odota muutama minuutti ja yritä uudelleen.';

  @override
  String get syncErrorStorageFull => 'Google Drive on täynnä.';

  @override
  String get syncErrorStorageFullHint =>
      'Vapauta tilaa Drivesta ja yritä uudelleen.';

  @override
  String get syncErrorNetwork => 'Googleen ei saatu yhteyttä.';

  @override
  String get syncErrorNetworkHint =>
      'Tarkista internetyhteys ja yritä uudelleen.';

  @override
  String get syncErrorAccountChanged => 'Käytössä oli toinen Google-tili.';

  @override
  String get syncErrorAccountChangedHint =>
      'Valitse, yhdistetäänkö tämän laitteen kirjasto tiliin vai korvataanko se.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Synkronoitu kirjasto on liian suuri Singbookin käsiteltäväksi.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Poista synkronoidusta kirjastosta kappaleita tai settilistoja ja yritä uudelleen.';

  @override
  String get syncErrorSignInFailed => 'Sisäänkirjautuminen ei valmistunut.';

  @override
  String get syncErrorSignInFailedHint => 'Yritä kirjautua uudelleen sisään.';

  @override
  String get syncErrorGeneric => 'Kirjastoa ei voitu synkronoida.';

  @override
  String get syncErrorGenericHint =>
      'Yritä hetken kuluttua uudelleen. Kappaleet ovat yhä turvassa tällä laitteella.';

  @override
  String get editorDurationInvalid =>
      'Anna sekunnit tai minuutit ja sekunnit, esimerkiksi 3:45.';

  @override
  String get editorNumberInvalid => 'Anna luku.';

  @override
  String get accountReplaceConfirmTitle =>
      'Poistetaanko paikalliset kappaleet?';

  @override
  String get accountReplaceConfirmBody =>
      'Tämän laitteen kappaleet ja settilistat, joita ei ole uudella tilillä, poistetaan pysyvästi. Tätä ei voi kumota.';

  @override
  String get accountReplaceConfirmAction => 'Poista ja korvaa';

  @override
  String get accountSuspiciousTitle => 'Kappaleita puuttuu Google Drivesta';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count aiemmin tältä laitteelta synkronoitua kappaletta puuttuu Google Drivesta.',
      one:
          'Yksi aiemmin tältä laitteelta synkronoitu kappale puuttuu Google Drivesta.',
    );
    return '$_temp0 Näin voi käydä, jos sovelluksen tiedot on tyhjennetty Googlen asetuksista. Mitään ei ole vielä poistettu.';
  }

  @override
  String get accountSuspiciousDelete => 'Poista ne myös tästä laitteesta';

  @override
  String get accountSuspiciousKeep =>
      'Säilytä kappaleeni ja lataa ne uudelleen';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Poistetaanko $count kappaletta tältä laitteelta?',
      one: 'Poistetaanko $count kappale tältä laitteelta?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Nämä kappaleet ja settilistat poistetaan pysyvästi tältä laitteelta. Tätä ei voi perua.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Poista tältä laitteelta';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Google Drivesta puuttuu kohteita.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Mitään ei poistettu. Valitse, poistetaanko ne myös tästä laitteesta vai ladataanko ne uudelleen.';

  @override
  String get syncErrorRemoteChanged =>
      'Google Drive muuttui synkronoinnin aikana.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Mitään ei kadonnut. Synkronoi uudelleen saadaksesi viimeisimmät muutokset.';

  @override
  String get syncErrorInvalidLocalData =>
      'Joitakin tämän laitteen tietoja ei voitu synkronoida.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Kappaletta tai settilistaa ei voitu lukea. Tuo se tai luo se uudelleen ja synkronoi sitten uudelleen.';

  @override
  String get syncErrorNoAccountChange => 'Ratkaistavaa tilimuutosta ei ole.';

  @override
  String get syncErrorNoAccountChangeHint => 'Jatka synkronoimalla uudelleen.';

  @override
  String get accountSyncWarningTitle =>
      'Synkronoitu, mutta joitakin tiedostoja ohitettiin';

  @override
  String get accountSyncWarningBody =>
      'Joitakin tiedostoja ei voitu käyttää, joten ne jätettiin ennalleen. Kaikki muu on ajan tasalla.';

  @override
  String get accountSyncWarningTooLarge =>
      'Tiedosto oli liian suuri synkronoitavaksi, joten se ohitettiin. Kaikki muu on ajan tasalla.';

  @override
  String get accountSyncWarningInvalid =>
      'Tiedostoa ei voitu lukea, joten se ohitettiin. Kaikki muu on ajan tasalla.';

  @override
  String get accountNoticeSyncSkipped =>
      'Synkronoitu. Joitakin tiedostoja ohitettiin.';

  @override
  String get settingsExportPdfTooLarge =>
      'PDF-tiedostosta tulisi liian suuri. Kokeile pienempää kappalemäärää tai jaa se tekstinä.';

  @override
  String get settingsTimingTooLarge =>
      'Ajoitustiedot ovat liian suuret (yli 3 Mt).';

  @override
  String get settingsImportDuplicateSongId =>
      'Varmuuskopio sisältää saman kappaleen kahdesti, joten mitään ei tuotu.';

  @override
  String get setlistSaveConflict =>
      'Settilista muuttui muualla. Muokkauksesi tallennettiin erillisenä kopiona.';

  @override
  String get sectionVerse => 'Säe';

  @override
  String get sectionChorus => 'Kertosäe';

  @override
  String get sectionBridge => 'Silta';

  @override
  String get sectionIntro => 'Intro';

  @override
  String get sectionOutro => 'Outro';

  @override
  String get sectionPreChorus => 'Esikertosäe';

  @override
  String get sectionPostChorus => 'Jälkikertosäe';

  @override
  String get sectionInstrumental => 'Instrumentaali';

  @override
  String get sectionInterlude => 'Välisoitto';

  @override
  String get sectionSolo => 'Soolo';

  @override
  String get sectionRefrain => 'Refrain';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Lopetus';

  @override
  String get youtubeConsentHint =>
      'Kokeellinen. Kokeile sanoitushakua valitsemalla evästeasetukset Googlen sivulla. Google-tilille ei tarvitse kirjautua. Valintasi säilyy tällä laitteella.';

  @override
  String get youtubeConsentOpen => 'Tarkista Googlen suostumus';

  @override
  String get youtubeConsentSaved => 'Suostumus tallennettu';

  @override
  String get youtubeConsentClear => 'Tyhjennä suostumus';

  @override
  String get youtubeConsentInstructions =>
      'Tee evästevalintasi loppuun ja odota, että YouTube Music palaa. Tallenna sitten tämä istunto ja yritä hakea kappaletta uudelleen.';

  @override
  String get youtubeConsentError =>
      'Googlen suostumusvalintaa ei voitu päivittää. Yritä uudelleen.';

  @override
  String get youtubeConsentBlocked =>
      'Täällä voi avata vain YouTube Musicin ja Googlen suostumussivun. Tilille kirjautuminen ei ole käytettävissä.';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Valmiit versiot',
      one: '1 valmis versio',
      zero: '0 Valmiit versiot',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ei saatavilla olevat versiota',
      one: '1 ei saatavilla oleva versio',
      zero: '0 Ei saatavilla olevat versiota',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Siirry osiooniiin';

  @override
  String get searchVersionDetails => 'Version tiedot';

  @override
  String get searchSelectedRecording => 'Valittu äänite';

  @override
  String get searchVersionDuration => 'Version kesto';

  @override
  String get searchSourceOptions => 'Lähdeasetukset';
}
