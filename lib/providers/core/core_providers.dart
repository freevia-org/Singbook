import '../provider.dart';
import 'catalogs.dart';
import 'charts.dart';
import 'youtube_music.dart';
export 'recording_key.dart' show RecordingKeyService;
export 'service.dart';

List<LyricsProvider> createCoreProviders({
  ProviderTransport? transport,
  String geniusToken = const String.fromEnvironment('GENIUS_ACCESS_TOKEN'),
}) {
  final http = transport ?? ProviderTransport();
  return [
    GeniusProvider(http, token: geniusToken),
    SongsterrProvider(http),
    UltimateGuitarProvider(http),
    LrclibProvider(http),
    YoutubeMusicProvider(http),
    LyricsOvhProvider(http),
    SyncLrcProvider(http),
    BetterLyricsProvider(http),
  ];
}
