import '../domain/models.dart';
import 'transport.dart';
export '../domain/models.dart'
    show ProviderDefinition, SongCandidate, SourceResult, MatchKind;
export 'transport.dart'
    show ProviderException, CancellationToken, ProviderTransport;

abstract interface class LyricsProvider {
  ProviderDefinition get definition;
  Future<List<SongCandidate>> search(String query, {CancellationToken? cancel});
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  });
}
