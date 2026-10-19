// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Irish (`ga`).
class AppLocalizationsGa extends AppLocalizations {
  AppLocalizationsGa([String locale = 'ga']) : super(locale);

  @override
  String get appTitle => 'Singbook';

  @override
  String get aboutDescription =>
      'Do chuid liricí, cordaí agus liostaí amhrán le chéile, réidh don chleachtadh, don stáitse agus do cibé áit a seinneann tú.';

  @override
  String get aboutMadeForSinging => 'Gach amhrán réidh.';

  @override
  String get aboutDetails =>
      'Déan cuardach ar na foinsí atá cumasaithe agus cuir liricí, cordaí, amanna agus sonraí taifeadta i gcomparáid sula sábhálann tú an leagan is mian leat a sheinm. Braitheann infhaighteacht ar an amhrán agus ar an tseirbhís.';

  @override
  String get aboutFindTitle => 'Faigh an leagan ceart';

  @override
  String get aboutKeepTitle => 'Tóg do leabharlann féin';

  @override
  String get aboutKeepDetails =>
      'Cuir amhráin in eagar agus athraigh a dtonúlacht, sábháil go háitiúil iad mar chomhaid iniompartha ChordPro, agus úsáid amhráin shábháilte as líne. Úsáideann sioncronú roghnach le Google Drive fillteán príobháideach na haipe i do chuntas Google. Is féidir leat Sioncronaigh anois a thapáil freisin chun do ghléasanna a nuashonrú.';

  @override
  String get aboutPlayTitle => 'Tabhair do liosta chuig an stáitse leat';

  @override
  String get aboutPlayDetails =>
      'Cuir amhráin in ord i liostaí, roghnaigh eochair do gach amhrán, agus roinn liostaí OpenSong. Coigeartaigh téacs an léitheora agus scrollú uathoibríoch na liricí, agus priontáil PDFanna amhrán. Ní shruthaíonn ná ní sheinneann Singbook fuaim.';

  @override
  String get aboutPrivacyTitle => 'Saor in aisce agus dírithe ar an ngléas';

  @override
  String get aboutPrivacyDetails =>
      'Tá Singbook saor in aisce, gan fógraí, anailísíocht ná ceannacháin in-aipe. Fanann do leabharlann shábháilte ar do ghléas; úsáideann sioncronú roghnach do Google Drive féin. Tagann torthaí ar líne go díreach ó sheirbhísí neamhspleácha tríú páirtí agus d’fhéadfadh nach mbeadh siad ar fáil nó d’fhéadfadh cóipcheart iad a chosaint. Ní óstálann Singbook a n-ábhar.';

  @override
  String get aboutWebsite => 'Láithreán gréasáin Singbook';

  @override
  String get aboutSourceCode => 'Cód foinse ar GitHub';

  @override
  String get aboutPublisher => 'Le Freevia';

  @override
  String aboutLanguages(int count) {
    return 'Teangacha na haipe: $count';
  }

  @override
  String get aboutSupport => 'Tacaíocht agus aiseolas';

  @override
  String get menuTypeNewSong => 'Clóscríobh amhrán nua';

  @override
  String appVersion(String version) {
    return 'Leagan $version';
  }

  @override
  String get navHome => 'Baile';

  @override
  String get navSongs => 'Amhráin';

  @override
  String get navSetlists => 'Liostaí amhrán';

  @override
  String get navSettings => 'Socruithe';

  @override
  String get navSettingsCompact => 'Socruithe';

  @override
  String get navSearch => 'Cuardach';

  @override
  String get navBack => 'Ar ais';

  @override
  String get appExitBackAgain => 'Brúigh Ar ais arís chun imeacht';

  @override
  String get navClose => 'Dún';

  @override
  String get navMore => 'Tuilleadh gníomhartha';

  @override
  String get actionCancel => 'Cealaigh';

  @override
  String get actionSave => 'Sábháil';

  @override
  String get actionDone => 'Déanta';

  @override
  String get actionEdit => 'Cuir in eagar';

  @override
  String get actionDelete => 'Scrios';

  @override
  String get actionShare => 'Comhroinn';

  @override
  String get actionPrint => 'Priontáil';

  @override
  String get actionCopy => 'Cóipeáil';

  @override
  String get actionClear => 'Glan';

  @override
  String get actionRetry => 'Bain triail eile as';

  @override
  String get actionRefresh => 'Athnuaigh';

  @override
  String get actionImport => 'Iompórtáil';

  @override
  String get actionExport => 'Easpórtáil';

  @override
  String get actionExpand => 'Leathnaigh';

  @override
  String get actionCollapse => 'Laghdaigh';

  @override
  String get actionAdd => 'Cuir leis';

  @override
  String get actionCreate => 'Cruthaigh';

  @override
  String get actionRemove => 'Bain';

  @override
  String get actionDuplicate => 'Dúblaigh';

  @override
  String get actionMoveUp => 'Bog suas';

  @override
  String get actionMoveDown => 'Bog síos';

  @override
  String get actionPrevious => 'Roimhe seo';

  @override
  String get actionNext => 'Ar aghaidh';

  @override
  String get searchHint => 'Cuardaigh amhráin, ealaíontóirí nó liricí';

  @override
  String get searchCatalogHint => 'Cuardaigh amhrán nó ealaíontóir';

  @override
  String get searchChangeSong => 'Athraigh amhrán';

  @override
  String get searchSelectedPreview => 'Réamhamharc roghnaithe';

  @override
  String get searchSubmit => 'Cuardaigh';

  @override
  String get searchFilters => 'Roghanna cuardaigh';

  @override
  String get searchFiltersShow => 'Taispeáin roghanna cuardaigh';

  @override
  String get searchFiltersHide => 'Folaigh roghanna cuardaigh';

  @override
  String get searchFilterArtist => 'Ealaíontóir';

  @override
  String get searchFilterTitle => 'Teideal an amhráin';

  @override
  String get searchFilterLyrics => 'Liricí';

  @override
  String get searchFilterChords => 'Le cordaí';

  @override
  String get searchFilterTimed => 'Liricí uainithe';

  @override
  String get searchFilterLanguage => 'Teanga';

  @override
  String get searchFilterAll => 'Aon cheann';

  @override
  String get searchAutocompleteLabel => 'Moltaí';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count toradh',
      one: '1 toradh',
      zero: 'Gan toradh',
    );
    return '$_temp0';
  }

  @override
  String get searchEmptyQuery =>
      'Cuir isteach amhrán, ealaíontóir nó liric le cuardach.';

  @override
  String get searchCatalogEmptyQuery =>
      'Cuir isteach amhrán nó ealaíontóir le cuardach.';

  @override
  String get searchNoResults =>
      'Níor aimsíodh amhrán ar bith. Bain triail as cuardach eile.';

  @override
  String get searchLoading => 'Amhráin á gcuardach…';

  @override
  String get searchError => 'Níorbh fhéidir an cuardach a chríochnú.';

  @override
  String get searchOnlineTab => 'Ar líne';

  @override
  String get searchRecentTab => 'Le déanaí';

  @override
  String get searchFavoritesTab => 'Ceanáin';

  @override
  String get searchSuggested => 'Meaitseáil molta';

  @override
  String get searchAlternatives => 'Meaitseálacha eile';

  @override
  String get searchCompare => 'Cuir leaganacha i gcomparáid';

  @override
  String get searchChooseVersion => 'Roghnaigh an leagan seo';

  @override
  String get searchFullPreview => 'Réamhamharc iomlán';

  @override
  String get searchArrangementNotes => 'Nótaí faoin socrú ceoil';

  @override
  String get searchOpenLyrics => 'Oscail na liricí';

  @override
  String get searchContributions => 'Foinsí a úsáideadh';

  @override
  String get searchVersionChecking => 'An leagan seo á sheiceáil…';

  @override
  String get searchVersionUnavailable =>
      'Ní féidir an leagan seo a úsáid. Roghnaigh leagan eile.';

  @override
  String get searchPreviewUnavailable => 'Níl réamhamharc liricí ar fáil.';

  @override
  String get searchSongMatch => 'Meaitseáil amhráin';

  @override
  String get searchRecordingMatch => 'Meaitseáil taifeadta';

  @override
  String get searchMatchUnverified => 'Níl an taifeadadh fíoraithe';

  @override
  String get searchMatchExact => 'Meaitseáil chruinn taifeadta';

  @override
  String get searchMatchPossible => 'Meaitseáil fhéideartha';

  @override
  String get searchAvailability => 'Infhaighteacht';

  @override
  String get searchLyricsAvailable => 'Liricí ar fáil';

  @override
  String get searchLyricsUnavailable => 'Níl liricí ar fáil';

  @override
  String get searchChordsAvailable => 'Cordaí ar fáil';

  @override
  String get searchChordsUnavailable => 'Gan cordaí';

  @override
  String get searchTimingAvailable => 'Uainiú ar fáil';

  @override
  String get searchTimingUnavailable => 'Gan uainiú';

  @override
  String get searchDurationUnknown => 'Fad anaithnid';

  @override
  String searchRating(String rating) {
    return 'Rátáil $rating';
  }

  @override
  String get searchSourceLabel => 'Foinse';

  @override
  String get searchMetadata => 'Sonraí an amhráin';

  @override
  String get searchAlbum => 'Albam';

  @override
  String get searchArtist => 'Ealaíontóir';

  @override
  String get searchYear => 'Bliain';

  @override
  String get searchLanguage => 'Teanga';

  @override
  String get searchViewVersions => 'Féach ar leaganacha';

  @override
  String get searchSaved => 'Sábháladh an t-amhrán i do leabharlann.';

  @override
  String get searchSaveOpenLyrics => 'Sábháil agus oscail na liricí';

  @override
  String get searchOtherResults => 'Torthaí eile';

  @override
  String get searchSaveFailed => 'Níorbh fhéidir an t-amhrán seo a shábháil.';

  @override
  String get homeRecentSongs => 'Amhráin le déanaí';

  @override
  String get homeRecentlyPlayed => 'Seinnte le déanaí';

  @override
  String get homeFavorites => 'Ceanáin';

  @override
  String get homeHistory => 'Stair';

  @override
  String get homeHistoryClear => 'Glan an stair';

  @override
  String get homeHistoryCleared => 'Glanadh an stair.';

  @override
  String get homeHistoryEmpty =>
      'Beidh na hamhráin a osclaíonn tú le feiceáil anseo.';

  @override
  String get homeFavoritesEmpty =>
      'Beidh na hamhráin agus na liostaí amhrán is ansa leat le feiceáil anseo.';

  @override
  String homeItemsShownCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Taispeántar $count mír',
      one: 'Taispeántar 1 mhír',
      zero: 'Taispeántar 0 mír',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentEmpty =>
      'Beidh na hamhráin agus na liostaí amhrán is déanaí agat le feiceáil anseo.';

  @override
  String get homeTimelineLabel => 'Amlíne na staire';

  @override
  String homeTimelineDate(String date) {
    return '$date';
  }

  @override
  String get homeAllHistory => 'An stair ar fad';

  @override
  String get homeShowFavorites => 'Taispeáin ceanáin';

  @override
  String get homeShowRecent => 'Taispeáin na cinn is déanaí';

  @override
  String get songsTitle => 'Amhráin';

  @override
  String get songsEmpty => 'Beidh d’amhráin le feiceáil anseo.';

  @override
  String get songsEmptySearch => 'Ní mheaitseálann aon amhrán do chuardach.';

  @override
  String get songsAdd => 'Cuir amhrán leis';

  @override
  String get songsSortAlphabetical => 'Sórtáil in ord aibítre';

  @override
  String get songsAlphabetNavigation => 'Innéacs amhrán';

  @override
  String songsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Osclaíodh $count uair',
      one: 'Osclaíodh uair amháin',
      zero: 'Níor osclaíodh riamh',
    );
    return '$_temp0';
  }

  @override
  String get songFavoriteAdd => 'Cuir le ceanáin';

  @override
  String get songFavoriteRemove => 'Bain de cheanáin';

  @override
  String get songMenuLabel => 'Gníomhartha amhráin';

  @override
  String get songInfo => 'Sonraí an amhráin';

  @override
  String get setlistMenuLabel => 'Gníomhartha liosta amhrán';

  @override
  String get songAddToSetlist => 'Cuir leis an liosta amhrán';

  @override
  String get songCopyChordPro => 'Cóipeáil ChordPro';

  @override
  String get songDeleteConfirmTitle => 'Scrios an t-amhrán?';

  @override
  String get songDeleteConfirmMessage =>
      'Bainfear an t-amhrán seo de do leabharlann.';

  @override
  String get songDeleted => 'Scriosadh an t-amhrán.';

  @override
  String get setlistsTitle => 'Liostaí amhrán';

  @override
  String get setlistsEmpty =>
      'Cruthaigh liosta amhrán don chéad chleachtadh nó léiriú eile.';

  @override
  String get setlistsEmptySearch =>
      'Ní mheaitseálann aon liosta amhrán do chuardach.';

  @override
  String get setlistCreate => 'Liosta amhrán nua';

  @override
  String get setlistNameHint => 'Ainm an liosta amhrán';

  @override
  String get setlistNotes => 'Nótaí';

  @override
  String get setlistEntryOverride => 'Eochair agus capo don amhrán seo';

  @override
  String setlistSongsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amhrán',
      one: '1 amhrán',
      zero: 'Gan amhrán',
    );
    return '$_temp0';
  }

  @override
  String setlistDuration(String duration) {
    return '$duration';
  }

  @override
  String setlistDurationPartial(String duration) {
    return 'Ar a laghad $duration';
  }

  @override
  String get setlistDurationUnknown => 'Fad anaithnid';

  @override
  String setlistActivity(String date) {
    return 'Gníomhaíocht dheireanach $date';
  }

  @override
  String setlistActivityCreated(String date) {
    return 'Cruthaithe $date';
  }

  @override
  String setlistActivityEdited(String date) {
    return 'Curtha in eagar $date';
  }

  @override
  String setlistActivityUsed(String date) {
    return 'Seinnte an uair dheireanach $date';
  }

  @override
  String get setlistSongsEmpty => 'Níl aon amhrán sa liosta seo fós.';

  @override
  String get setlistAddSongs => 'Cuir amhráin leis';

  @override
  String get setlistReorder => 'Athordaigh na hamhráin';

  @override
  String setlistMoveSongUp(String song) {
    return 'Bog $song suas';
  }

  @override
  String setlistMoveSongDown(String song) {
    return 'Bog $song síos';
  }

  @override
  String setlistRemoveSong(String song) {
    return 'Bain $song den liosta amhrán';
  }

  @override
  String get setlistDuplicate => 'Dúblaigh an liosta amhrán';

  @override
  String get setlistFavoriteAdd => 'Cuir an liosta amhrán le ceanáin';

  @override
  String get setlistFavoriteRemove => 'Bain an liosta amhrán de cheanáin';

  @override
  String get setlistShare => 'Comhroinn mar chomhad liosta amhrán';

  @override
  String get setlistSharePdf => 'Comhroinn mar PDF';

  @override
  String get setlistPrint => 'Priontáil';

  @override
  String get setlistDeleteConfirmTitle => 'Scrios an liosta amhrán?';

  @override
  String get setlistDeleteConfirmMessage =>
      'Bainfear an liosta amhrán. Fanfaidh na hamhráin i do leabharlann.';

  @override
  String get setlistDeleted => 'Scriosadh an liosta amhrán.';

  @override
  String get readerTitle => 'Liricí';

  @override
  String get readerNoLyrics => 'Níor cuireadh liricí leis fós.';

  @override
  String get readerShowChords => 'Taispeáin cordaí';

  @override
  String get readerHideChords => 'Folaigh cordaí';

  @override
  String get readerTranspose => 'Trasuigh cordaí';

  @override
  String readerTransposeSemitones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leath-thón',
      one: '1 leath-thón',
      zero: '0 leath-thón',
    );
    return 'Trasuigh $_temp0';
  }

  @override
  String get readerSaved => 'Sábháilte';

  @override
  String get readerEdit => 'Cuir liricí agus sonraí in eagar';

  @override
  String get playerPlay => 'Seinn';

  @override
  String get playerPause => 'Sos';

  @override
  String get playerResume => 'Lean ar aghaidh ag scrollú na liricí';

  @override
  String get playerSeek => 'Suíomh athsheinnte';

  @override
  String playerElapsed(String time) {
    return 'Am caite $time';
  }

  @override
  String playerRemaining(String time) {
    return 'Am fágtha $time';
  }

  @override
  String get playerTimingMode => 'Mód scrollaithe';

  @override
  String get playerTimedLyrics => 'Liricí uainithe';

  @override
  String get playerStartScroll => 'Tosaigh scrollú uathoibríoch';

  @override
  String get playerEstimatedPace => 'Luas measta';

  @override
  String get playerScrollSpeed => 'Luas scrollaithe';

  @override
  String playerEstimatedDuration(String time) {
    return 'Fad measta: $time';
  }

  @override
  String get playerLyricsOnly => 'Scrollú liricí · gan fuaim';

  @override
  String get playerManualScroll => 'Scrollú láimhe';

  @override
  String get playerTimingStatusReady =>
      'Leanfaidh na liricí an t-uainiú atá ar fáil.';

  @override
  String get playerTimingStatusEstimated =>
      'Meastar luas an scrollaithe ó fhad an amhráin.';

  @override
  String get playerTimingStatusManual => 'Scrollaigh na liricí tú féin.';

  @override
  String get playerTimingStatusUnavailable =>
      'Níl scrollú uainithe ar fáil don amhrán seo.';

  @override
  String get playerDurationUnknown =>
      'Cuir fad an amhráin leis chun scrollú measta a úsáid.';

  @override
  String get playerProgressLabel => 'Dul chun cinn an amhráin';

  @override
  String get playerCurrentSection => 'Rannóg reatha';

  @override
  String get playerPreviousSection => 'Rannóg roimhe seo';

  @override
  String get playerNextSection => 'An chéad rannóg eile';

  @override
  String get playerPreviousSectionSong =>
      'Rannóg roimhe seo · coinnigh síos don amhrán roimhe seo sa liosta';

  @override
  String get playerNextSectionSong =>
      'An chéad rannóg eile · coinnigh síos don chéad amhrán eile sa liosta';

  @override
  String get playerPreviousSong => 'Amhrán roimhe seo';

  @override
  String get playerNextSong => 'An chéad amhrán eile';

  @override
  String get editorTitle => 'Cuir amhrán in eagar';

  @override
  String get editorTitleField => 'Teideal an amhráin';

  @override
  String get editorArtistField => 'Ealaíontóir';

  @override
  String get editorAlbumField => 'Albam';

  @override
  String get editorLyricsField => 'Liricí';

  @override
  String get editorChordsField => 'Cordaí';

  @override
  String get editorKeyField => 'Eochair';

  @override
  String get editorCapoField => 'Capo';

  @override
  String get editorTuningField => 'Tiúnadh';

  @override
  String get editorTempoField => 'Luas';

  @override
  String get editorDurationField => 'Fad';

  @override
  String get editorTimeSignatureField => 'Méadar';

  @override
  String get editorLanguageField => 'Teanga';

  @override
  String get editorYearField => 'Bliain';

  @override
  String get editorComposerField => 'Cumadóir';

  @override
  String get editorLyricistField => 'Údar liricí';

  @override
  String get editorCopyrightField => 'Cóipcheart';

  @override
  String get editorLicenseField => 'Ceadúnas';

  @override
  String get songInfoSources => 'Foinsí agus creidiúintí';

  @override
  String get searchMatchSameSong =>
      'An t-amhrán céanna; níl an taifeadadh deimhnithe';

  @override
  String get searchMatchNeedsAgreement =>
      'Ní mór liricí an chairte a dheimhniú';

  @override
  String get searchMatchDifferentLyrics =>
      'Tá na liricí difriúil ón amhrán roghnaithe';

  @override
  String get searchMatchCombinedSources =>
      'Cuireadh sonraí ó fhoinsí éagsúla le chéile';

  @override
  String get searchCombinedLabel => 'Comhcheangailte';

  @override
  String searchSongMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meaitseáil amhráin',
      one: '1 mheaitseáil amhráin',
      zero: '0 meaitseáil amhráin',
    );
    return '$_temp0';
  }

  @override
  String searchSourceVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leagan foinse',
      one: '1 leagan foinse',
      zero: '0 leagan foinse',
    );
    return '$_temp0';
  }

  @override
  String get searchMatchBestAvailable => 'An mheaitseáil is fearr atá ar fáil';

  @override
  String get providerDescriptionUnknown => 'Foinse amhráin';

  @override
  String get providerDescDownloadChordProThenImport =>
      'Íoslódáil comhad ChordPro ón bhfoinse, ansin iompórtáil é.';

  @override
  String get providerDescFreeAccountDownloadThenImport =>
      'Íoslódáil an comhad le cuntas saor in aisce, ansin iompórtáil é.';

  @override
  String get providerDescPublicChordSheets => 'Bileoga cordaí poiblí.';

  @override
  String get providerDescHistoricalTextPerWorkLicense =>
      'Liricí stairiúla ceadúnaithe de réir saothair.';

  @override
  String get providerDescLicensedCatalog => 'Catalóg liricí cheadúnaithe.';

  @override
  String get providerDescOriginalSongsCcBy =>
      'Amhráin bhunaidh faoi Creative Commons BY.';

  @override
  String get providerDescPerSongLicense =>
      'Liricí ceadúnaithe de réir amhráin.';

  @override
  String get providerDescRecordingMetadataOnly =>
      'Sonraí taifeadta agus eisithe amháin.';

  @override
  String get providerDescCompositionMetadataOnly =>
      'Sonraí cumadóireachta amháin.';

  @override
  String get providerDescExactFileArtworkOnly =>
      'Saothar ealaíne do mheaitseálacha cruinne taifeadta amháin.';

  @override
  String get providerCapabilityLyrics => 'Liricí';

  @override
  String get providerCapabilityChords => 'Cordaí';

  @override
  String get providerCapabilityTiming => 'Liricí uainithe';

  @override
  String get providerCapabilitySearch => 'Cuardach';

  @override
  String get providerCapabilityMetadata => 'Sonraí amhráin';

  @override
  String get editorArtworkField => 'Nasc chuig saothar ealaíne';

  @override
  String get editorLyricsHint =>
      'Corda i lúibíní [C]; marcóirí rannóige ar línte ar leith.';

  @override
  String get editorSave => 'Sábháil athruithe';

  @override
  String get editorSaved => 'Sábháladh na hathruithe.';

  @override
  String get editorSaveFailed => 'Níorbh fhéidir na hathruithe a shábháil.';

  @override
  String get editorSaveConflict =>
      'Athraíodh an t-amhrán in áit eile. Sábháladh do chuid athruithe mar chóip ar leith.';

  @override
  String get editorUnsavedTitle => 'Caith uait na hathruithe?';

  @override
  String get editorUnsavedMessage => 'Níor sábháladh do chuid athruithe.';

  @override
  String get editorFieldRequired => 'Cuir isteach teideal amhráin.';

  @override
  String get settingsTitle => 'Socruithe';

  @override
  String get settingsAppearance => 'Cuma';

  @override
  String get settingsTheme => 'Téama';

  @override
  String get settingsThemeSystem => 'Úsáid socrú an ghléis';

  @override
  String get settingsThemeLight => 'Geal';

  @override
  String get settingsThemeDark => 'Dorcha';

  @override
  String get settingsColorPalette => 'Pailéad dathanna';

  @override
  String get settingsFont => 'Cló';

  @override
  String get settingsTextSize => 'Méid an téacs';

  @override
  String get settingsLyricsPreview => 'Réamhamharc liricí';

  @override
  String get settingsPlayer => 'Seinnteoir liricí';

  @override
  String get settingsLyricHighlight => 'Aibhsiú líne reatha na liricí';

  @override
  String get settingsHighlightBackgroundUnderline => 'Cúlra + líne faoi';

  @override
  String get settingsHighlightBackground => 'Cúlra';

  @override
  String get settingsHighlightUnderline => 'Líne faoi';

  @override
  String get settingsHighlightContrast => 'Dath téacs codarsnachta';

  @override
  String get settingsHighlightNone => 'Dada';

  @override
  String get settingsDefaultShowChords =>
      'Taispeáin cordaí de réir réamhshocraithe';

  @override
  String get settingsDefaultAutoscroll => 'Scrollaigh liricí go huathoibríoch';

  @override
  String get settingsDefaultTiming => 'Mód scrollaithe réamhshocraithe';

  @override
  String get settingsLanguage => 'Teanga na haipe';

  @override
  String get settingsLanguageSystem => 'Úsáid teanga an ghléis';

  @override
  String get settingsLanguageEnglish => 'Béarla';

  @override
  String get settingsLanguageBulgarian => 'Bulgáiris';

  @override
  String get settingsLanguageUkrainian => 'Úcráinis';

  @override
  String get settingsSources => 'Foinsí liricí';

  @override
  String settingsSourceEnabled(String source) {
    return 'Cumasaigh foinse $source';
  }

  @override
  String get settingsSourceRefresh => 'Athnuaigh liosta na bhfoinsí';

  @override
  String get settingsSourcesUpdated => 'Nuashonraíodh na foinsí.';

  @override
  String get settingsSourcesUpdateFailed =>
      'Níorbh fhéidir na foinsí a athnuachan.';

  @override
  String get settingsImport => 'Iompórtáil amhráin';

  @override
  String get settingsImportChordPro => 'Iompórtáil comhad ChordPro';

  @override
  String get settingsImportSetlist => 'Iompórtáil comhad liosta amhrán';

  @override
  String get settingsImportSuccess => 'Iompórtáil críochnaithe.';

  @override
  String get settingsImportFailed =>
      'Níorbh fhéidir an comhad seo a iompórtáil.';

  @override
  String get settingsImportUnsupported =>
      'Ní thacaítear leis an gcineál comhaid seo.';

  @override
  String get settingsShareSong => 'Comhroinn mar ChordPro';

  @override
  String get settingsSharePdf => 'Comhroinn mar PDF';

  @override
  String get settingsCopySong => 'Cóipeáil chuig an ngearrthaisce';

  @override
  String get settingsPrintSong => 'Priontáil an t-amhrán amháin';

  @override
  String get settingsPrintSetlist => 'Priontáil liosta amhrán leis na liricí';

  @override
  String get settingsExportFailed => 'Níorbh fhéidir an comhad a ullmhú.';

  @override
  String get settingsCopied => 'Cóipeáladh chuig an ngearrthaisce.';

  @override
  String get settingsAbout => 'Faoi';

  @override
  String get settingsPrivacy => 'Príobháideachas';

  @override
  String get settingsLegal => 'Cúrsaí dlí';

  @override
  String get settingsClearHistory => 'Glan an stair';

  @override
  String get settingsClearHistoryConfirm =>
      'Glan stair na n-amhrán agus na liostaí amhrán?';

  @override
  String get settingsHistoryCleared => 'Glanadh an stair.';

  @override
  String get accountTitle => 'Cuntas agus sioncronú';

  @override
  String get accountUnavailable =>
      'Teastaíonn leagan de Singbook atá cumraithe le síniú isteach le Google chun sioncronú a dhéanamh. Ní choinníonn an leagan seo d’amhráin ach ar an ngléas seo.';

  @override
  String get accountSyncNow => 'Sioncrónaigh anois';

  @override
  String get accountConnected =>
      'Nasctha. Roghnaigh Sioncrónaigh anois chun do chúltaca a nuashonrú.';

  @override
  String get accountSignIn => 'Ceangail cuntas';

  @override
  String get accountSignOut => 'Sínigh amach';

  @override
  String get accountChange => 'Athraigh cuntas';

  @override
  String get accountSignedOut => 'Gan nasc';

  @override
  String get accountSyncing => 'Do leabharlann á sioncronú…';

  @override
  String get accountSynced => 'Sioncrónaíodh an leabharlann.';

  @override
  String get accountSyncFailed => 'Níorbh fhéidir do leabharlann a shioncronú.';

  @override
  String get accessibilityFavorite => 'Ceanán';

  @override
  String get accessibilityNotFavorite => 'Ní ceanán é';

  @override
  String get accessibilitySearchField => 'Cuardaigh amhráin';

  @override
  String get accessibilityClearSearch => 'Glan téacs cuardaigh';

  @override
  String accessibilitySongMenu(String song) {
    return 'Gníomhartha do $song';
  }

  @override
  String accessibilitySetlistMenu(String setlist) {
    return 'Gníomhartha do $setlist';
  }

  @override
  String accessibilityExpandSetlist(String setlist) {
    return 'Leathnaigh amhráin in $setlist';
  }

  @override
  String accessibilityCollapseSetlist(String setlist) {
    return 'Laghdaigh amhráin in $setlist';
  }

  @override
  String accessibilityPlaybackProgress(int percent) {
    return 'Dul chun cinn athsheinnte, $percent faoin gcéad';
  }

  @override
  String accessibilityTimeline(String date) {
    return 'Amlíne na staire, $date';
  }

  @override
  String get loading => 'Ag lódáil…';

  @override
  String get loadingSongs => 'Amhráin á lódáil…';

  @override
  String get loadingSetlists => 'Liostaí á lódáil…';

  @override
  String get errorGeneric => 'Tharla earráid.';

  @override
  String get errorOffline => 'Is cosúil nach bhfuil tú ar líne.';

  @override
  String get errorPermission => 'Tá cead ag teastáil chun leanúint ar aghaidh.';

  @override
  String get emptyFiltered => 'Ní mheaitseálann aon mhír na scagairí seo.';

  @override
  String get unknownValue => 'Anaithnid';

  @override
  String get durationUnknown => 'Fad anaithnid';

  @override
  String get metadataNotSet => 'Gan socrú';

  @override
  String get dateToday => 'Inniu';

  @override
  String get dateYesterday => 'Inné';

  @override
  String daySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amhrán',
      one: '1 amhrán',
      zero: 'Gan amhrán',
    );
    return '$_temp0';
  }

  @override
  String get settingsPaletteNavy => 'Dúghorm';

  @override
  String get settingsPaletteSage => 'Glas sáiste';

  @override
  String get settingsPaletteOcean => 'Aigéan';

  @override
  String get settingsPaletteClay => 'Cré';

  @override
  String get settingsPalettePlum => 'Pluma';

  @override
  String get settingsFontSystem => 'Córas';

  @override
  String get settingsFontSerif => 'Serif';

  @override
  String get settingsFontMonospace => 'Aonleithead';

  @override
  String get settingsLyricsPreviewExample =>
      'Nuair a thiocfaidh an mhaidin, canfaimid arís.';

  @override
  String searchDiscoveryProgress(int checked, int total) {
    return 'Foinsí liricí á seiceáil: $checked as $total críochnaithe.';
  }

  @override
  String get searchDiscoveryNoLyrics => 'Níor aimsíodh liricí inúsáidte.';

  @override
  String get searchDiscoveryNoLyricsDetails =>
      'Seiceáladh an t-amhrán roghnaithe sna foinsí cumasaithe, ach níor thug aon cheann acu leagan liricí inúsáidte ar ais.';

  @override
  String get searchDiscoveryError =>
      'Níorbh fhéidir foinsí liricí a sheiceáil.';

  @override
  String get searchDiscoveryRetry => 'Déan cuardach liricí arís';

  @override
  String searchSourcesUnavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foinse nach bhfuil ar fáil',
      one: '1 fhoinse nach bhfuil ar fáil',
      zero: '0 foinse nach bhfuil ar fáil',
    );
    return '$_temp0';
  }

  @override
  String get searchErrorDetails => 'Seiceáil do nasc agus bain triail eile as.';

  @override
  String get searchProviderChecks => 'Seiceálacha foinsí';

  @override
  String get searchProviderPending => 'Á sheiceáil';

  @override
  String get searchProviderFound => 'Aimsíodh meaitseáil';

  @override
  String get searchProviderRejected => 'Ní mheaitseálann';

  @override
  String get searchProviderFailed => 'Theip ar an tseiceáil';

  @override
  String get searchProviderUnavailable => 'Níl liricí inúsáidte ar fáil';

  @override
  String get searchCatalogFilterHint =>
      'Roghnaigh amhrán chun leaganacha liricí a scagadh de réir cordaí, uainiúcháin nó teanga.';

  @override
  String get startupErrorTitle => 'Níorbh fhéidir do leabharlann a oscailt.';

  @override
  String setlistCopyName(String name) {
    return 'Cóip de $name';
  }

  @override
  String get setlistSongMissing => 'Amhrán ar iarraidh';

  @override
  String get settingsImportTooLarge =>
      'Tá an comhad seo rómhór le hiompórtáil.';

  @override
  String songsJumpToLetter(String letter) {
    return 'Léim chuig $letter';
  }

  @override
  String get actionDiscard => 'Caith uait';

  @override
  String get editorKeepEditing => 'Lean leis an eagarthóireacht';

  @override
  String get settingsDefaultShowChordsHint =>
      'Taispeáin cordaí os cionn na liricí nuair atá cordaí ag amhrán.';

  @override
  String get settingsDefaultAutoscrollHint =>
      'Scrollaíonn na liricí leis an amhrán. Ní úsáidtear é sa mhód scrollaithe láimhe.';

  @override
  String get accountUnavailableTitle => 'Níl sioncronú socraithe';

  @override
  String get accountSignedOutBenefits =>
      'Nuair a cheanglaíonn tú Google Drive, sioncrónaítear do leabharlann. Sioncrónaítear athruithe ar amhráin go huathoibríoch ina dhiaidh sin.';

  @override
  String get accountManualSyncHint =>
      'Is féidir leat Sioncrónaigh anois a thapáil chun do leabharlann a shioncronú.';

  @override
  String get accountSignInWithGoogle => 'Sínigh isteach le Google';

  @override
  String get accountWorking => 'Ag obair…';

  @override
  String get accountNeverSynced => 'Níor sioncrónaíodh riamh';

  @override
  String get accountSyncedJustNow => 'Sioncrónaíodh díreach anois';

  @override
  String accountSyncedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sioncrónaíodh $count nóiméad ó shin',
      one: 'Sioncrónaíodh 1 nóiméad ó shin',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sioncrónaíodh $count uair ó shin',
      one: 'Sioncrónaíodh 1 uair ó shin',
    );
    return '$_temp0';
  }

  @override
  String accountSyncedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sioncrónaíodh $count lá ó shin',
      one: 'Sioncrónaíodh 1 lá ó shin',
    );
    return '$_temp0';
  }

  @override
  String accountConflictsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sábháladh $count athrú contrártha mar chóipeanna',
      one: 'Sábháladh 1 athrú contrártha mar chóip',
    );
    return '$_temp0';
  }

  @override
  String get accountConflictsBody =>
      'Cuireadh an t-amhrán nó an liosta céanna in eagar in dhá áit. Níor cailleadh tada: sábháladh an leagan eile mar chóip ar leith.';

  @override
  String get accountReviewConflicts => 'Athbhreithnigh cóipeanna';

  @override
  String get songsConflictFilterActive =>
      'Cóipeanna contrártha amháin á dtaispeáint';

  @override
  String get songsConflictFilterClear => 'Taispeáin gach amhrán';

  @override
  String get songsConflictBadge => 'Cóip chontrártha';

  @override
  String get songsConflictEmpty => 'Níl cóipeanna contrártha ann.';

  @override
  String get accountAutoSync => 'Sioncrónaigh go huathoibríoch';

  @override
  String get accountAutoSyncHint =>
      'Déantar sioncrónú tar éis nascadh agus tar éis amhrán a chur leis, a chur in eagar nó a bhaint.';

  @override
  String get accountSignOutTitle => 'Sínigh amach as an gcuntas seo?';

  @override
  String get accountSignOutBody =>
      'Fanann d’amhráin agus do liostaí amhrán ar an ngléas seo. Ní dhéanfar cúltaca ná sioncronú díobh go dtí go síneoidh tú isteach arís.';

  @override
  String get accountUseDifferent => 'Úsáid cuntas eile';

  @override
  String get accountSignInAgain => 'Sínigh isteach arís';

  @override
  String get accountChooseAction => 'Roghnaigh conas leanúint ar aghaidh';

  @override
  String get accountChangedTitle => 'Cuntas Google eile';

  @override
  String get accountChangedBody =>
      'Sioncrónaíodh an gléas seo le cuntas Google eile an uair dheireanach. Roghnaigh cad ba cheart a dhéanamh leis na hamhráin agus na liostaí ar an ngléas seo.';

  @override
  String get accountChangedMerge => 'Cumaisc leis an gcuntas nua';

  @override
  String get accountChangedMergeHint =>
      'Coinnigh gach rud ar an ngléas seo agus cuir leis an gcuntas nua é.';

  @override
  String get accountChangedReplace =>
      'Cuir leabharlann an chuntais nua ina hionad';

  @override
  String get accountChangedReplaceHint =>
      'Bainfear na hamhráin ar an ngléas seo nach bhfuil sa chuntas nua.';

  @override
  String get accountChangedSignOut => 'Cealaigh agus sínigh amach';

  @override
  String get accountStatusSignedOut =>
      'Cuntas agus sioncronú: níl síniú isteach déanta';

  @override
  String get accountStatusSignedIn => 'Cuntas agus sioncronú: síníodh isteach';

  @override
  String get accountStatusSyncing => 'Cuntas agus sioncronú: á sioncronú';

  @override
  String get accountStatusSynced =>
      'Cuntas agus sioncronú: tá an leabharlann cothrom le dáta';

  @override
  String get accountStatusError =>
      'Cuntas agus sioncronú: fadhb, tapáil chun athbhreithniú a dhéanamh';

  @override
  String get accountNoticeConflicts =>
      'Cuireadh roinnt amhrán in eagar in dhá áit. Coinníodh cóipeanna.';

  @override
  String get accountNoticeSignedIn => 'Síníodh isteach.';

  @override
  String get accountNoticeSignedOut =>
      'Síníodh amach. Fanann d’amhráin ar an ngléas seo.';

  @override
  String get syncErrorNotConfigured => 'Níl sioncronú socraithe sa leagan seo.';

  @override
  String get syncErrorNotConfiguredHint =>
      'Úsáid leagan de Singbook atá cumraithe le síniú isteach le Google.';

  @override
  String get syncErrorNotSignedIn => 'Níl síniú isteach déanta agat.';

  @override
  String get syncErrorNotSignedInHint =>
      'Sínigh isteach chun do leabharlann a shioncronú.';

  @override
  String get syncErrorAuthorizationRequired =>
      'Iarrann Google ort síniú isteach arís.';

  @override
  String get syncErrorAuthorizationRequiredHint =>
      'Sínigh isteach arís chun leanúint leis an sioncronú. Tá d’amhráin slán ar an ngléas seo.';

  @override
  String get syncErrorAccessDenied =>
      'Níl cead ag Singbook Google Drive a úsáid.';

  @override
  String get syncErrorAccessDeniedHint =>
      'Sínigh isteach arís agus ceadaigh rochtain ar Drive nuair a iarrtar ort é.';

  @override
  String get syncErrorRateLimited =>
      'Tá Google ag teorannú iarratais faoi láthair.';

  @override
  String get syncErrorRateLimitedHint =>
      'Fan cúpla nóiméad agus bain triail eile as.';

  @override
  String get syncErrorStorageFull => 'Tá do Google Drive lán.';

  @override
  String get syncErrorStorageFullHint =>
      'Saor spás in Drive agus bain triail eile as.';

  @override
  String get syncErrorNetwork => 'Níorbh fhéidir Google a bhaint amach.';

  @override
  String get syncErrorNetworkHint =>
      'Seiceáil do nasc idirlín agus bain triail eile as.';

  @override
  String get syncErrorAccountChanged => 'Úsáideadh cuntas Google eile.';

  @override
  String get syncErrorAccountChangedHint =>
      'Roghnaigh ar cheart leabharlann an ghléis seo a chumasc leis an gcuntas nó í a ionadú.';

  @override
  String get syncErrorRemoteLibraryTooLarge =>
      'Tá do leabharlann shioncronaithe níos mó ná mar is féidir le Singbook a láimhseáil.';

  @override
  String get syncErrorRemoteLibraryTooLargeHint =>
      'Bain roinnt amhrán nó liostaí den leabharlann shioncronaithe agus bain triail eile as.';

  @override
  String get syncErrorSignInFailed => 'Níor críochnaíodh an síniú isteach.';

  @override
  String get syncErrorSignInFailedHint => 'Bain triail eile as síniú isteach.';

  @override
  String get syncErrorGeneric => 'Níorbh fhéidir do leabharlann a shioncronú.';

  @override
  String get syncErrorGenericHint =>
      'Bain triail eile as ar ball. Tá d’amhráin fós slán ar an ngléas seo.';

  @override
  String get editorDurationInvalid =>
      'Cuir isteach soicind nó nóiméid agus soicind, mar shampla 3:45.';

  @override
  String get editorNumberInvalid => 'Cuir isteach uimhir.';

  @override
  String get accountReplaceConfirmTitle => 'Scrios amhráin áitiúla?';

  @override
  String get accountReplaceConfirmBody =>
      'Scriosfar go buan na hamhráin agus na liostaí amhrán ar an ngléas seo nach bhfuil sa chuntas nua. Ní féidir é seo a chealú.';

  @override
  String get accountReplaceConfirmAction => 'Scrios agus cuir ina n-ionad';

  @override
  String get accountSuspiciousTitle => 'Míreanna ar iarraidh ó Google Drive';

  @override
  String accountSuspiciousBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tá $count mhír a shioncronaigh an gléas seo roimhe seo ar iarraidh ó Google Drive.',
      one:
          'Tá mír amháin a shioncronaigh an gléas seo roimhe seo ar iarraidh ó Google Drive.',
    );
    return '$_temp0 D’fhéadfadh sé seo tarlú má glanadh sonraí na haipe i socruithe Google. Níl aon rud scriosta fós.';
  }

  @override
  String get accountSuspiciousDelete => 'Scrios ón ngléas seo iad freisin';

  @override
  String get accountSuspiciousKeep =>
      'Coinnigh mo chuid amhrán agus uaslódáil arís iad';

  @override
  String accountSuspiciousDeleteConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Scrios $count mhír ón ngléas seo?',
      one: 'Scrios $count mhír ón ngléas seo?',
    );
    return '$_temp0';
  }

  @override
  String get accountSuspiciousDeleteConfirmBody =>
      'Scriosfar na hamhráin agus na seinmliostaí seo go buan ón ngléas seo. Ní féidir é sin a chur ar ceal.';

  @override
  String get accountSuspiciousDeleteConfirmAction => 'Scrios ón ngléas seo';

  @override
  String get syncErrorRemoteListingSuspicious =>
      'Tá míreanna ar iarraidh ó Google Drive.';

  @override
  String get syncErrorRemoteListingSuspiciousHint =>
      'Níor scriosadh aon rud. Roghnaigh ar cheart iad a scriosadh ón ngléas seo freisin nó iad a uaslódáil arís.';

  @override
  String get syncErrorRemoteChanged =>
      'Athraíodh Google Drive le linn an tsioncronaithe.';

  @override
  String get syncErrorRemoteChangedHint =>
      'Níor cailleadh aon rud. Sioncronaigh arís chun na hathruithe is déanaí a fháil.';

  @override
  String get syncErrorInvalidLocalData =>
      'Níorbh fhéidir roinnt sonraí ar an ngléas seo a shioncronú.';

  @override
  String get syncErrorInvalidLocalDataHint =>
      'Níorbh fhéidir amhrán nó seinmliosta a léamh. Iompórtáil nó cruthaigh arís é, ansin sioncronaigh arís.';

  @override
  String get syncErrorNoAccountChange => 'Níl aon athrú cuntais le réiteach.';

  @override
  String get syncErrorNoAccountChangeHint =>
      'Sioncronaigh arís chun leanúint ar aghaidh.';

  @override
  String get accountSyncWarningTitle =>
      'Sioncrónaíodh é, ach scipeáladh roinnt comhad';

  @override
  String get accountSyncWarningBody =>
      'Níorbh fhéidir roinnt comhad a úsáid agus fágadh mar a bhí siad. Tá gach rud eile cothrom le dáta.';

  @override
  String get accountSyncWarningTooLarge =>
      'Bhí comhad rómhór le sioncrónú agus scipeáladh é. Tá gach rud eile cothrom le dáta.';

  @override
  String get accountSyncWarningInvalid =>
      'Níorbh fhéidir comhad a léamh agus scipeáladh é. Tá gach rud eile cothrom le dáta.';

  @override
  String get accountNoticeSyncSkipped =>
      'Sioncrónaíodh é. Scipeáladh roinnt comhad.';

  @override
  String get settingsExportPdfTooLarge =>
      'Bheadh an PDF seo rómhór. Bain triail as níos lú amhrán, nó roinn mar théacs é.';

  @override
  String get settingsTimingTooLarge =>
      'Tá na sonraí uainiúcháin rómhór (os cionn 3 MB).';

  @override
  String get settingsImportDuplicateSongId =>
      'Tá an t-amhrán céanna faoi dhó sa chúltaca seo, mar sin níor iompórtáladh aon rud.';

  @override
  String get setlistSaveConflict =>
      'Athraíodh an seinmliosta in áit eile. Sábháladh do chuid athruithe mar chóip ar leith.';

  @override
  String get sectionVerse => 'Véarsa';

  @override
  String get sectionChorus => 'Curfá';

  @override
  String get sectionBridge => 'Droichead';

  @override
  String get sectionIntro => 'Réamhrá';

  @override
  String get sectionOutro => 'Críoch';

  @override
  String get sectionPreChorus => 'Roimh an gcurfá';

  @override
  String get sectionPostChorus => 'Tar éis an churfá';

  @override
  String get sectionInstrumental => 'Uirlise';

  @override
  String get sectionInterlude => 'Eadráin';

  @override
  String get sectionSolo => 'Aonair';

  @override
  String get sectionRefrain => 'Athrá';

  @override
  String get sectionHook => 'Hook';

  @override
  String get sectionBreakdown => 'Breakdown';

  @override
  String get sectionCoda => 'Coda';

  @override
  String get sectionTag => 'Tag';

  @override
  String get sectionEnding => 'Deireadh';

  @override
  String searchReadyVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leagan réidh',
      many: '$count leagan réidh',
      few: '$count leaganacha réidh',
      two: '$count leagan réidh',
      one: '$count leagan réidh',
      zero: 'Níl leaganacha réidh ar fáil',
    );
    return '$_temp0';
  }

  @override
  String searchUnavailableVersions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leagan nach bhfuil ar fáil',
      many: '$count leagan nach bhfuil ar fáil',
      few: '$count leaganacha nach bhfuil ar fáil',
      two: '$count leagan nach bhfuil ar fáil',
      one: '$count leagan nach bhfuil ar fáil',
      zero: 'Níl leaganacha ar fáil',
    );
    return '$_temp0';
  }

  @override
  String get searchJumpSection => 'Léim chuig rannán';

  @override
  String get searchVersionDetails => 'Sonraí an leagain';

  @override
  String get searchSelectedRecording => 'Taifeadadh roghnaithe';

  @override
  String get searchVersionDuration => 'Fad an leagain';

  @override
  String get searchSourceOptions => 'Roghanna foinse';

  @override
  String get actionUndo => 'Cealaigh';

  @override
  String setlistEntryRemoved(String song) {
    return 'Baineadh $song den liosta seinm';
  }

  @override
  String get backupTitle => 'Cúltaca agus athchóiriú';

  @override
  String get backupExport => 'Easpórtáil cúltaca';

  @override
  String get backupRestore => 'Athchóirigh cúltaca';

  @override
  String get backupIncludePreferences =>
      'Cuir sainroghanna na haipe san áireamh';

  @override
  String get backupRestorePreferences => 'Athchóirigh sainroghanna na haipe';

  @override
  String get backupMerge => 'Cuir leis an leabharlann seo';

  @override
  String get backupMergeHint =>
      'Coinnigh na hathruithe áitiúla agus cuir amhráin agus liostaí ón gcúltaca seo leis.';

  @override
  String get backupReplace => 'Ionadaigh an leabharlann seo';

  @override
  String get backupReplaceHint =>
      'Ionadaigh gach amhrán agus liosta ar an ngléas seo le hábhar an chúltaca seo.';

  @override
  String backupSummary(int songs, int setlists, int conflicts) {
    return 'Amhráin: $songs · Liostaí: $setlists · Coinbhleachtaí: $conflicts';
  }

  @override
  String get backupFailed =>
      'Níorbh fhéidir an cúltaca a chríochnú. Bain triail eile as.';

  @override
  String get backupRestored => 'Athchóiríodh an cúltaca.';

  @override
  String get backupLocalHint =>
      'Sábháil cóip de do leabharlann. Ní chuirtear dintiúir chuntais ná fianáin toilithe san áireamh riamh.';

  @override
  String get backupReplaceConfirm =>
      'Ionadaigh an leabharlann reatha? Ní féidir é seo a chealú.';

  @override
  String get searchCheckOperations => 'Oibríochtaí';

  @override
  String get searchCheckCode => 'Cód toraidh';

  @override
  String get searchCheckQueued =>
      'Ag fanacht leis an bhfoinse seo a sheiceáil.';

  @override
  String get searchCheckFetch => 'Luchtaigh liricí';

  @override
  String get searchCheckValidate => 'Seiceáil meaitseáil an amhráin';

  @override
  String get searchCheckCorroborate => 'Seiceáil comhaontú na liricí';

  @override
  String get searchCheckCompleted => 'Críochnaithe';

  @override
  String get searchCheckTimeout => 'Níor fhreagair an fhoinse in am.';

  @override
  String get searchCheckBlocked => 'Chuir an fhoinse bac ar an iarratas.';

  @override
  String get searchCheckRateLimited =>
      'Tá an fhoinse ag teorannú iarratas. Bain triail eile as ar ball.';

  @override
  String get searchCheckNetwork =>
      'Níorbh fhéidir an fhoinse a bhaint amach. Seiceáil do cheangal.';

  @override
  String get searchCheckInvalid =>
      'D’fhill an fhoinse freagra nach féidir a léamh.';

  @override
  String get searchCheckNotConfigured =>
      'Níl an fhoinse seo cumraithe sa leagan seo.';

  @override
  String get searchCheckNoLyrics => 'Níor aimsíodh liricí meaitseála.';

  @override
  String get searchCheckFailed =>
      'Níorbh fhéidir an oibríocht seo a chríochnú.';

  @override
  String get searchCheckNoHistory =>
      'Níor reáchtáladh seiceálacha foinse don chomparáid seo.';

  @override
  String get searchVersionCredits => 'Buíochas';

  @override
  String get searchVersionMediaLinks => 'Naisc ghaolmhara';

  @override
  String get searchCheckCancelled => 'Cealaithe';

  @override
  String get searchCheckAmbiguous =>
      'Fuarthas roinnt meaitseálacha. Tá taifeadadh níos sainiúla ag teastáil ón bhfoinse seo.';

  @override
  String get searchCheckIdentity =>
      'Tá aitheantóir taifeadta nó saothair ag teastáil ón bhfoinse seo.';

  @override
  String get searchCheckExtraction =>
      'D’fhreagair an fhoinse, ach níorbh fhéidir na liricí a bhaint amach.';

  @override
  String get searchCheckBusy =>
      'Tá an fhoinse seo gnóthach. Bain triail eile as ar ball.';

  @override
  String get searchCheckSelection =>
      'Roghnaigh toradh sonrach ón bhfoinse seo.';

  @override
  String get playerChordsNone => 'Dada';

  @override
  String get editorCustomValue => 'Eile…';

  @override
  String get editorStandardTuning => 'Tiúnadh caighdeánach';

  @override
  String get editorExampleVerse =>
      '[C]Tá lá nua ag [G]glaoch,\n[Am]leanaimid an solas ar ais [F]abhaile.';

  @override
  String get editorExampleChorus =>
      '[F]Can an t-amhrán seo [C]le chéile,\n[G]go n-iompraíonn an tséis sinn [C]ar aghaidh.';

  @override
  String get editorExampleBridge =>
      '[Am]Líne amháin eile, beagán níos [F]gaire.';
}
