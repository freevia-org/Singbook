import '../provider.dart';
import 'import_sources.dart';
import 'metadata.dart';
import 'open_catalogs.dart';
import 'lrc_red.dart';
import 'roswell.dart';
import 'kara_moe.dart';
import 'amll.dart';
import 'startjamming.dart';
import 'lyricsplus.dart';
import 'vocadb.dart';
import 'chords_and_tabs.dart';
import 'pisni.dart';
import 'openscore_lieder.dart';
import 'acousticbrainz.dart';
import 'wikibooks_liederbuch.dart';

export 'import_sources.dart';
export 'metadata.dart';
export 'open_catalogs.dart';
export 'lrc_red.dart';
export 'roswell.dart';
export 'kara_moe.dart';
export 'amll.dart';
export 'startjamming.dart';
export 'lyricsplus.dart';
export 'vocadb.dart';
export 'chords_and_tabs.dart';
export 'pisni.dart';
export 'openscore_lieder.dart';
export 'acousticbrainz.dart';
export 'wikibooks_liederbuch.dart';

/// All sources in the architecture, including truthful file-import-only routes.
List<LyricsProvider> createExtraProviders({ProviderTransport? transport}) {
  final http = transport ?? ProviderTransport();
  return [
    OzbcozProvider(),
    ChordieProvider(http),
    WorshipCommonsProvider(http),
    OpenFilkProvider(http),
    SeanMcGrathProvider(http),
    WorshipTogetherProvider(),
    MusicBrainzProvider(http),
    WikidataProvider(http),
    WikimediaCommonsProvider(http),
    WikisourceProvider(http),
    LrcRedProvider(http),
    RoswellMusicJamProvider(http),
    KaraMoeProvider(http),
    AmllProvider(http),
    StartJammingProvider(http),
    LyricsPlusProvider(http),
    VocaDbProvider(http),
    TouhouDbProvider(http),
    UtaiteDbProvider(http),
    ChordsAndTabsProvider(http),
    PisniProvider(http),
    OpenScoreLiederProvider(http),
    AcousticBrainzProvider(http),
    WikibooksLiederbuchProvider(http),
  ];
}
