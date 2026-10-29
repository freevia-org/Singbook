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

/// Optional native lookup for APIs that accept separate selected-song fields.
/// The caller still validates every returned identity and recording context.
abstract interface class ContextualLyricsSearch {
  /// Cached rows must still satisfy context added by recording enrichment.
  bool canReuseSearchForSelection(
    SongCandidate selection,
    List<SongCandidate> candidates,
  );

  Future<List<SongCandidate>> searchForSelection(
    SongCandidate selection, {
    required String fallbackQuery,
    CancellationToken? cancel,
  });
}

/// Optional evidence that a publisher's own alternate title names a selection.
/// Implementations revalidate the source title/artist and supplied album/duration
/// context. Callers retain all recording-ID and edition checks; returning an
/// alias does not authorize recording identity or rewrite canonical source facts.
abstract interface class PublishedTitleAliasEvidence {
  String? publishedTitleAliasForSelection(
    SongCandidate selection,
    SongCandidate candidate,
  );
}
