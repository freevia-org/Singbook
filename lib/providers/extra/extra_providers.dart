import '../provider.dart';
import 'import_sources.dart';
import 'metadata.dart';
import 'open_catalogs.dart';
import 'lrc_red.dart';
import 'roswell.dart';
import 'kara_moe.dart';
import 'amll.dart';
import 'vocadb.dart';

export 'import_sources.dart';
export 'metadata.dart';
export 'open_catalogs.dart';
export 'lrc_red.dart';
export 'roswell.dart';
export 'kara_moe.dart';
export 'amll.dart';
export 'vocadb.dart';

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
    VocaDbProvider(http),
    TouhouDbProvider(http),
    UtaiteDbProvider(http),
  ];
}
