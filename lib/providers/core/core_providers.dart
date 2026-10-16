import '../provider.dart';
import 'catalogs.dart';
import 'charts.dart';
import 'youtube_music.dart';
import '../youtube_music_session.dart';
export 'service.dart';

List<LyricsProvider> createCoreProviders({
  ProviderTransport? transport,
  YoutubeMusicSession? youtubeMusicSession,
  Future<bool> Function()? onYoutubeMusicConsentRequired,
  String geniusToken = const String.fromEnvironment('GENIUS_ACCESS_TOKEN'),
}) {
  final http = transport ?? ProviderTransport();
  return [
    GeniusProvider(http, token: geniusToken),
    SongsterrProvider(http),
    UltimateGuitarProvider(http),
    LrclibProvider(http),
    YoutubeMusicProvider(
      http,
      session: youtubeMusicSession,
      onConsentRequired: onYoutubeMusicConsentRequired,
    ),
    LyricsOvhProvider(http),
    SyncLrcProvider(http),
    BetterLyricsProvider(http),
  ];
}
