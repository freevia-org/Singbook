import 'dart:async';
import 'dart:isolate';
import 'diagnostics.dart';
import 'dart:math' as math;
import '../../domain/arrangement.dart'
    show containsChords, plainLyrics, transposeBody, transposeChord;
import '../../domain/chord_key_estimate.dart' show estimateChordKey;
import '../../domain/combine.dart'
    show
        chordKeyVerdict,
        declaredKeyFitsChords,
        keysAgree,
        recordingCompatible,
        soundingChartKey,
        soundingTransposition;
import '../../domain/artist_credit.dart';
import '../../domain/reviewed_chart_artist.dart';
import '../../domain/metadata_artist_credit.dart';
import '../../domain/published_name_alias.dart';
import '../../domain/arrangement_context.dart';
import '../../domain/contextual_chart_lyrics.dart';
import '../../domain/lyric_word_identity.dart';
import '../../domain/short_lyric_reference.dart';
import '../../domain/models.dart';
import '../../domain/lyrics_variants.dart';
import '../../domain/edition_identity.dart';
import '../provider.dart';
import '../source_catalog_client.dart';
import '../catalog_search.dart';
import 'recording_key.dart';
import 'recording_context.dart';

part 'identity_match.dart';
part 'match_source.dart';
part 'lyric_agreement.dart';

const _diagnosticCodes = <String>{
  'blocked',
  'access_denied',
  'ambiguous_match',
  'cancelled',
  'extraction_failed',
  'file_import_required',
  'identity_mismatch',
  'identity_required',
  'invalid_config',
  'invalid_query',
  'invalid_response',
  'invalid_selection',
  'invalid_url',
  'network',
  'not_configured',
  'provider_busy',
  'rate_limited',
  'rights_review_required',
  'redirect',
  'select_specific_work',
  'title_required',
  'timeout',
  'transport_closed',
  'uncorroborated_arrangement',
  'incomplete_or_different_lyrics',
  'validation_rejected',
  'unavailable',
  'user_selection_required',
};

String? _safeDiagnosticCode(String? code) =>
    code != null && _diagnosticCodes.contains(code) ? code : 'provider_error';

class ProviderOperation {
  const ProviderOperation({
    required this.id,
    required this.phase,
    required this.state,
    this.code,
    this.query,
    this.title,
    this.artist,
    this.sourceUrl,
    this.resultCount,
    this.elapsedMilliseconds,
  });

  final String id, phase, state;
  final String? code, query, title, artist, sourceUrl;
  final int? resultCount, elapsedMilliseconds;
}

class ProviderCheck {
  const ProviderCheck({
    required this.providerId,
    required this.state,
    this.code,
    this.result,
    this.hasLyrics,
    this.hasChords,
    this.operations = const [],
  });
  final String providerId, state;
  final String? code;
  final SourceResult? result;
  final bool? hasLyrics, hasChords;
  final List<ProviderOperation> operations;
}

/// Shared by the UI and headless device tests; no result is fabricated on failure.
class SourceDiscoveryService {
  SourceDiscoveryService(
    this._providers, {
    this.catalogClient,
    this.recordingKeys,
    this.discoveryConcurrency = 6,
    this.providerTimeout = const Duration(seconds: 30),
  }) : assert(discoveryConcurrency > 0);

  /// Bounds each provider's first lookup. Expiry fails that lookup only; it
  /// never cancels the caller's token, which means "source withdrawn".
  final Duration providerTimeout;

  /// Providers looked up at once in discovery's first pass. Each talks to its
  /// own host and the transport already paces every host separately.
  final int discoveryConcurrency;
  final List<LyricsProvider> _providers;
  SourceCatalogClient? catalogClient;

  /// Measures a recording's key from its audio (ReccoBeats), as one piece of
  /// evidence in the chord key check. Null disables the lookup.
  final RecordingKeyService? recordingKeys;
  List<LyricsProvider> get providers =>
      catalogClient?.runtime.providers ?? _providers;
  List<ProviderDefinition> get definitions =>
      providers.map((p) => p.definition).toList();
  Future<List<SongCandidate>> search(
    String query, {
    String providerId = 'genius',
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final matches = providers.where((p) => p.definition.id == providerId);
    if (matches.isEmpty) throw const ProviderException('not_configured');
    final rows = await matches.single.search(query, cancel: cancel);
    cancel?.throwIfCancelled();
    return rows;
  }

  /// Queries each eligible catalog once while retaining the preferred catalog's
  /// identities and rank. Exact provider search remains available to adapters
  /// and maintenance probes, and test overrides participate through [search].
  Future<List<SongCandidate>> searchAcrossCatalogs(
    String query, {
    required String primaryProviderId,
    required Set<String> enabledIds,
    CancellationToken? cancel,
    Map<String, CancellationToken> providerCancellation = const {},
    void Function(List<SongCandidate>)? onProgress,
    void Function(String providerId, String state, String? code)? onStatus,
  }) => searchCatalogsTogether(
    query,
    definitions: definitions,
    primaryProviderId: primaryProviderId,
    enabledIds: enabledIds,
    search: (id, token) => search(query, providerId: id, cancel: token),
    cancel: cancel,
    providerCancellation: providerCancellation,
    onProgress: onProgress,
    onStatus: onStatus,
  );

  Future<List<SourceResult>> discover(
    SongCandidate selection, {
    Set<String>? enabledIds,
    void Function(ProviderCheck)? onProgress,
    CancellationToken? cancel,
    Map<String, CancellationToken> providerCancellation = const {},
    Duration alternativeTimeout = const Duration(seconds: 30),
  }) async {
    final active = providers
        .where(
          (p) =>
              p.definition.configured &&
              (enabledIds?.contains(p.definition.id) ??
                  p.definition.enabledByDefault),
        )
        .toList();
    final results = <SourceResult>[];
    final operationsByProvider = <String, List<ProviderOperation>>{};
    final traceOpen = <String, bool>{};
    final correlationSequence = <String, int>{};
    final providerChecksState = <String, String>{};
    final providerResults = <String, SourceResult>{};
    final preferredResultIds = <String, String>{};
    final providerCodes = <String, String?>{};
    final operationWatches = <String, Stopwatch>{};
    final corroborationOperationIds = <String, String>{};
    final searchedByProvider = <String, List<SongCandidate>>{};
    final lookupCancellation = <String, CancellationToken>{};
    const inlineChordScanLimit = 16 * 1024;
    final referenceFacts = <String, _LyricReferenceFacts>{};
    final preparingReferences = <String, Future<void>>{};
    final lyricScores = <_LyricPair, _LyricScore>{};
    final scoring = <_LyricPair, Future<void>>{};
    final deferredRecordingReceivers = <String, String>{};
    final recordingContextPlans = <String, RecordingContextPlan>{};
    final recordingMatches = Expando<bool>();
    bool matchesSelectedRecording(SourceResult result) =>
        recordingMatches[result] ??= recordingCompatible(selection, result);

    bool contextProviderEligible(String id) =>
        (enabledIds?.contains(id) ?? true) &&
        providerCancellation[id]?.isCancelled != true &&
        lookupCancellation[id]?.isCancelled != true;
    bool liveRecordingContext(SourceResult result) =>
        recordingContextPlans[result.id]?.isCurrent(
          results,
          original: selection,
          eligible: contextProviderEligible,
        ) ??
        true;
    _LyricPair lyricPair(SourceResult chart, SourceResult reference) => (
      chart: chart.candidate,
      reference: reference.candidate,
      chartBody: chart.body,
      referenceBody: reference.body,
      alternatePerformer: chart.extra['alternatePerformerChart'] == true,
      shortRecording:
          reference.matchKind == MatchKind.sameRecording &&
          matchesSelectedRecording(reference),
    );

    Future<void> warmLyricScores(Iterable<_LyricPair> pairs) async {
      final pending = pairs.toSet().where(
        (pair) => !lyricScores.containsKey(pair),
      );
      final needed = <_LyricPair>[];
      final waiting = <Future<void>>{};
      for (final pair in pending) {
        final running = scoring[pair];
        if (running == null) {
          needed.add(pair);
        } else {
          waiting.add(running);
        }
      }
      if (needed.isNotEmpty) {
        final batch = _scoreLyricPairs(needed)
            .then((scores) {
              for (var i = 0; i < needed.length; i++) {
                lyricScores[needed[i]] = scores[i];
              }
            })
            .whenComplete(() {
              for (final pair in needed) {
                scoring.remove(pair);
              }
            });
        for (final pair in needed) {
          scoring[pair] = batch;
        }
        waiting.add(batch);
      }
      if (waiting.isNotEmpty) await Future.wait(waiting);
    }

    Future<_LyricScore> scoreLyrics(
      SourceResult chart,
      SourceResult reference,
    ) async {
      final pair = lyricPair(chart, reference);
      if (!lyricScores.containsKey(pair)) await warmLyricScores([pair]);
      return lyricScores[pair]!;
    }

    bool needsLyricProof(SourceResult source) =>
        source.matchKind != MatchKind.rejected &&
        (source.extra['requiresLyricsAgreement'] == true ||
            source.extra['requiresRecordingLyricsAgreement'] == true);

    Future<SourceResult> markPartialLyricSupport(
      SourceResult chart,
      SourceResult reference,
    ) async {
      if (chart.extra['alternatePerformerChart'] != true ||
          !(await scoreLyrics(chart, reference)).contextualPartial) {
        return chart;
      }
      return chart.copyWith(
        extra: {...chart.extra, 'partialLyricSupport': true},
      );
    }

    bool hasChords(SourceResult source) =>
        referenceFacts[source.body]?.hasChords ?? source.hasChords;

    bool referenceCandidate(SourceResult reference) =>
        const {
          MatchKind.sameSong,
          MatchKind.sameRecording,
        }.contains(reference.matchKind) &&
        reference.extra['requiresLyricsAgreement'] != true &&
        reference.extra['requiresRecordingLyricsAgreement'] != true &&
        providerCancellation[reference.candidate.providerId]?.isCancelled !=
            true &&
        !hasChords(reference);

    Future<void> prepareBody(SourceResult source) async {
      final body = source.body;
      if (referenceFacts.containsKey(body)) return;
      // Bounded small charts use the ordinary chord cache. Large charts and
      // lyric references share a worker pass for the facts used by discovery.
      if (body.length <= inlineChordScanLimit && !referenceCandidate(source)) {
        return;
      }
      await preparingReferences.putIfAbsent(
        body,
        () => _scoreLyricReference(body)
            .then((facts) {
              referenceFacts[body] = facts;
            })
            .whenComplete(() {
              preparingReferences.remove(body);
            }),
      );
    }

    Future<bool> preparedHasChords(SourceResult source) async {
      if (source.body.length > inlineChordScanLimit) await prepareBody(source);
      return hasChords(source);
    }

    bool shortRecordingReference(SourceResult reference) =>
        referenceFacts[reference.body]?.short == true &&
        reference.matchKind == MatchKind.sameRecording &&
        matchesSelectedRecording(reference);

    bool liveReference(SourceResult reference) =>
        referenceCandidate(reference) &&
        ((referenceFacts[reference.body]?.words ?? 0) >= 12 ||
            shortRecordingReference(reference));
    bool liveDependencyFor(SourceResult chart) {
      if (providerCancellation[chart.candidate.providerId]?.isCancelled ==
          true) {
        return false;
      }
      final contextual =
          chart.extra['requiresRecordingLyricsAgreement'] == true;
      var hasShortAnchor = false;
      var longAgreement = false;
      for (final reference in results) {
        if (!referenceCandidate(reference)) continue;
        final shortAnchor = shortRecordingReference(reference);
        if (shortAnchor) {
          hasShortAnchor = true;
        } else if (hasShortAnchor ||
            longAgreement ||
            (referenceFacts[reference.body]?.words ?? 0) < 12) {
          continue;
        }
        final score = lyricScores[lyricPair(chart, reference)];
        if (score == null || !(score.agrees || !contextual && score.loose)) {
          continue;
        }
        if (contextual &&
            (lookupCancellation[reference.candidate.providerId]?.isCancelled ==
                    true ||
                !matchesSelectedRecording(reference) ||
                !contextualArrangementCandidate(
                  reference.candidate,
                  chart.candidate,
                  allowAlternatePerformers:
                      chart.extra['alternatePerformerChart'] == true,
                ))) {
          continue;
        }
        if (shortAnchor) return true;
        longAgreement = true;
      }
      // A longer unanchored performance cannot bypass a short recording's
      // ordered-sequence evidence during progressive publication.
      return !hasShortAnchor && longAgreement;
    }

    Future<void> warmDependencyScores(Iterable<SourceResult> charts) async {
      await Future.wait(results.map(prepareBody));
      final references = results.where(liveReference).toList();
      await warmLyricScores([
        for (final chart in charts.where(needsLyricProof))
          for (final reference in references) lyricPair(chart, reference),
      ]);
    }

    var index = 0;
    void publish(
      String providerId,
      String state, {
      String? code,
      SourceResult? result,
      bool preserveCode = false,
    }) {
      // A closed comparison must not receive delayed provider callbacks.
      if (cancel?.isCancelled == true ||
          providerCancellation[providerId]?.isCancelled == true &&
              !(state == 'cancelled' && result == null)) {
        return;
      }
      if (result != null &&
          result.matchKind != MatchKind.rejected &&
          !liveRecordingContext(result)) {
        return;
      }
      if (result != null &&
          result.matchKind != MatchKind.rejected &&
          (result.extra['requiresLyricsAgreement'] == true ||
              result.extra['requiresRecordingLyricsAgreement'] == true) &&
          !liveDependencyFor(result)) {
        return;
      }
      if (!preserveCode) providerCodes[providerId] = code;
      onProgress?.call(
        ProviderCheck(
          providerId: providerId,
          state: state,
          code: providerCodes[providerId] == null
              ? null
              : _safeDiagnosticCode(providerCodes[providerId]),
          result: result,
          hasLyrics: result == null
              ? null
              : referenceFacts[result.body]?.hasLyrics,
          hasChords: result == null
              ? null
              : referenceFacts[result.body]?.hasChords,
          operations: List.unmodifiable(
            operationsByProvider[providerId] ?? const [],
          ),
        ),
      );
    }

    void recordOperation(String providerId, ProviderOperation operation) {
      if (traceOpen[providerId] != true ||
          cancel?.isCancelled == true ||
          providerCancellation[providerId]?.isCancelled == true) {
        return;
      }
      final operations = operationsByProvider.putIfAbsent(providerId, () => []);
      final oldIndex = operations.indexWhere((item) => item.id == operation.id);
      var update = operation;
      if (operation.state == 'pending') {
        operationWatches[operation.id] = Stopwatch()..start();
      } else {
        final watch = operationWatches.remove(operation.id);
        if (operation.elapsedMilliseconds == null && watch != null) {
          update = ProviderOperation(
            id: operation.id,
            phase: operation.phase,
            state: operation.state,
            code: operation.code,
            query: operation.query,
            title: operation.title,
            artist: operation.artist,
            sourceUrl: operation.sourceUrl,
            resultCount: operation.resultCount,
            elapsedMilliseconds: watch.elapsedMilliseconds,
          );
        }
      }
      if (oldIndex >= 0) {
        operations[oldIndex] = update;
      } else {
        if (operations.length >= 24) operations.removeAt(0);
        operations.add(update);
      }
      final currentState = providerChecksState[providerId] ?? 'pending';
      publish(
        providerId,
        currentState,
        result: providerResults[providerId],
        preserveCode: true,
      );
    }

    void recordCorroboration(String providerId, String state, {String? code}) {
      String id;
      if (state == 'pending') {
        if (corroborationOperationIds.containsKey(providerId)) return;
        final sequence = correlationSequence.update(
          providerId,
          (value) => value + 1,
          ifAbsent: () => 0,
        );
        id = '$providerId:corroborate:$sequence';
        corroborationOperationIds[providerId] = id;
      } else {
        id =
            corroborationOperationIds.remove(providerId) ??
            '$providerId:corroborate:${correlationSequence.update(providerId, (value) => value + 1, ifAbsent: () => 0)}';
      }
      recordOperation(
        providerId,
        ProviderOperation(
          id: id,
          phase: 'corroborate',
          state: state,
          code: code == null ? null : _safeDiagnosticCode(code),
        ),
      );
    }

    void finalizePending(
      String providerId,
      String state,
      String code, {
      String? operationIdPrefix,
    }) {
      final operations = operationsByProvider[providerId];
      if (operations == null) return;
      var changed = false;
      for (var i = 0; i < operations.length; i++) {
        final operation = operations[i];
        if (operation.state != 'pending' ||
            (operationIdPrefix != null &&
                !operation.id.startsWith(operationIdPrefix))) {
          continue;
        }
        final watch = operationWatches.remove(operation.id);
        operations[i] = ProviderOperation(
          id: operation.id,
          phase: operation.phase,
          state: state,
          code: _safeDiagnosticCode(code),
          query: operation.query,
          title: operation.title,
          artist: operation.artist,
          sourceUrl: operation.sourceUrl,
          resultCount: operation.resultCount,
          elapsedMilliseconds: watch?.elapsedMilliseconds,
        );
        changed = true;
      }
      if (changed) {
        publish(
          providerId,
          providerChecksState[providerId] ?? 'pending',
          code: code,
          result: providerResults[providerId],
        );
      }
    }

    void finalizeCancelledChecks() {
      for (final provider in active) {
        final providerId = provider.definition.id;
        if (traceOpen[providerId] != true) continue;
        providerChecksState[providerId] = 'failed';
        finalizePending(providerId, 'cancelled', 'cancelled');
        traceOpen[providerId] = false;
        publish(providerId, 'failed', code: 'cancelled');
      }
    }

    void invalidateLyricDependentResults() {
      // Progress consumers can disable another provider synchronously. Repeat
      // until every dependent chart has been withdrawn; each row changes once.
      var changed = true;
      while (changed) {
        cancel?.throwIfCancelled();
        changed = false;
        for (var i = 0; i < results.length; i++) {
          final result = results[i];
          if (result.matchKind == MatchKind.rejected ||
              (result.extra['requiresLyricsAgreement'] != true &&
                  result.extra['requiresRecordingLyricsAgreement'] != true) ||
              liveDependencyFor(result)) {
            continue;
          }
          final rejected = _matched(
            result,
            MatchKind.rejected,
            'uncorroborated_arrangement',
          );
          results[i] = rejected;
          final id = result.candidate.providerId;
          if (providerResults[id]?.id == result.id) {
            providerResults[id] = rejected;
          }
          providerChecksState[id] = 'unavailable';
          publish(
            id,
            'unavailable',
            code: rejected.matchReason,
            result: rejected,
          );
          changed = true;
        }
      }
    }

    void invalidateRecordingContextResults() {
      var changed = true;
      while (changed) {
        cancel?.throwIfCancelled();
        changed = false;
        for (var i = 0; i < results.length; i++) {
          final result = results[i];
          if (result.matchKind == MatchKind.rejected ||
              liveRecordingContext(result)) {
            continue;
          }
          final rejected = _matched(
            result,
            MatchKind.rejected,
            'identity_required',
          );
          results[i] = rejected;
          final id = result.candidate.providerId;
          providerResults[id] = rejected;
          providerChecksState[id] = 'unavailable';
          publish(
            id,
            'unavailable',
            code: 'identity_required',
            result: rejected,
          );
          changed = true;
        }
      }
    }

    for (final provider in active) {
      final id = provider.definition.id;
      traceOpen[id] = true;
      operationsByProvider[id] = [];
      providerChecksState[id] = 'pending';
      publish(id, 'pending');
    }
    Future<void> worker() async {
      while (index < active.length) {
        if (cancel?.isCancelled == true) {
          finalizeCancelledChecks();
          cancel!.throwIfCancelled();
        }
        final provider = active[index++];
        // A linked token of its own: a timeout retires this lookup without
        // marking the caller's provider token as withdrawn.
        final local = CancellationToken();
        final provided = providerCancellation[provider.definition.id];
        if (provided?.isCancelled == true) local.cancel();
        // The link above fires a microtask late; consult the caller's token too.
        bool retired() => local.isCancelled || provided?.isCancelled == true;
        provided?.cancelled.then((_) => local.cancel());
        lookupCancellation[provider.definition.id] = local;
        cancel?.cancelled.then((_) => local.cancel());
        final namespace = provider is RecordingContextReceiver
            ? (provider as RecordingContextReceiver)
                  .requiredRecordingIdNamespace
            : null;
        if (namespace != null &&
            !selection.recordingIds.containsKey(namespace)) {
          deferredRecordingReceivers[provider.definition.id] = namespace;
          continue;
        }
        Future<void> retainCandidate(SourceResult result) async {
          if (retired() || cancel?.isCancelled == true) return;
          if (result.body.length > inlineChordScanLimit) {
            await prepareBody(result);
            if (retired() || cancel?.isCancelled == true) return;
          }
          final previous = results.indexWhere((item) => item.id == result.id);
          if (previous < 0) {
            results.add(result);
          } else {
            results[previous] = result;
          }
          if (needsLyricProof(result)) {
            await warmDependencyScores([result]);
          } else if (referenceCandidate(result)) {
            await prepareBody(result);
            await warmLyricScores([
              if (liveReference(result))
                for (final chart in results.where(needsLyricProof))
                  lyricPair(chart, result),
            ]);
          }
          if (retired() || cancel?.isCancelled == true) return;
          final state = result.matchKind == MatchKind.rejected
              ? 'unavailable'
              : 'found';
          providerChecksState[provider.definition.id] = state;
          providerResults[provider.definition.id] = result;
          publish(
            provider.definition.id,
            state,
            code: result.matchKind == MatchKind.rejected
                ? 'identity_mismatch'
                : null,
            result: result,
          );
        }

        try {
          final alternatives = <SourceResult>[];
          final result =
              await findMatchingSource(
                provider,
                selection,
                cancel: local,
                onAlternative: alternatives.add,
                onCandidate: retainCandidate,
                stopAfterFirstChordCandidate: provider.definition.capabilities
                    .contains('chords'),
                onSearchCandidates:
                    provider.definition.capabilities.contains('chords')
                    ? (candidates) {
                        if (!retired() && cancel?.isCancelled != true) {
                          searchedByProvider[provider.definition.id] =
                              candidates;
                        }
                      }
                    : null,
                onOperation: (operation) {
                  if (!retired()) {
                    recordOperation(provider.definition.id, operation);
                  }
                },
              ).timeout(
                providerTimeout,
                onTimeout: () {
                  local.cancel();
                  throw const ProviderException('timeout');
                },
              );
          local.throwIfCancelled();
          provided?.throwIfCancelled();
          cancel?.throwIfCancelled();
          preferredResultIds[provider.definition.id] = result.id;
          for (final alternative in alternatives) {
            await retainCandidate(alternative);
          }
          await retainCandidate(result);
          final state = result.matchKind == MatchKind.rejected
              ? 'unavailable'
              : 'found';
          providerChecksState[provider.definition.id] = state;
          providerResults[provider.definition.id] = result;
          publish(
            provider.definition.id,
            state,
            code: result.matchKind == MatchKind.rejected
                ? 'identity_mismatch'
                : null,
            result: result,
          );
        } on ProviderException catch (e) {
          final state = e.code == 'unavailable' ? 'unavailable' : 'failed';
          providerChecksState[provider.definition.id] = state;
          finalizePending(
            provider.definition.id,
            e.code == 'cancelled' ? 'cancelled' : 'failed',
            e.code,
          );
          traceOpen[provider.definition.id] = false;
          publish(provider.definition.id, state, code: e.code);
          if (cancel?.isCancelled == true) finalizeCancelledChecks();
          cancel?.throwIfCancelled();
        } catch (_) {
          providerChecksState[provider.definition.id] = 'failed';
          finalizePending(provider.definition.id, 'failed', 'invalid_response');
          traceOpen[provider.definition.id] = false;
          publish(provider.definition.id, 'failed', code: 'invalid_response');
          if (cancel?.isCancelled == true) finalizeCancelledChecks();
          cancel?.throwIfCancelled();
        }
      }
    }

    await Future.wait(
      List.generate(
        math.min(discoveryConcurrency, active.length),
        (_) => worker(),
      ),
    );
    // Chord sources describe arrangements: corroborate their words against the
    // strongest full lyric reference before making them eligible for combining.
    final references = results.where(liveReference).toList()
      ..sort((a, b) {
        // A longer same-song transcription may be a remix or another
        // performance. Corroborate charts against the selected recording
        // before falling back to unanchored same-song references.
        final recording = (matchesSelectedRecording(b) ? 1 : 0).compareTo(
          matchesSelectedRecording(a) ? 1 : 0,
        );
        if (recording != 0) return recording;
        final words = referenceFacts[b.body]!.words.compareTo(
          referenceFacts[a.body]!.words,
        );
        return words != 0 ? words : a.id.compareTo(b.id);
      });
    final recordingReference = references
        .where((reference) => matchesSelectedRecording(reference))
        .firstOrNull;
    if (recordingReference != null) {
      // A catalog hit may omit the album/featured credits subsequently supplied
      // by its resolved lyrics. Give MusicBrainz one narrower, album-scoped
      // lookup after a semantic miss, without retrying rate limits or failures.
      final resolvedAlbum = recordingReference.candidate.album?.trim();
      if (selection.providerId == 'genius' &&
          recordingReference.candidate.identity == selection.identity &&
          (selection.album?.trim().isEmpty ?? true) &&
          resolvedAlbum != null &&
          resolvedAlbum.isNotEmpty) {
        for (final provider in active.where(
          (p) => p.definition.id == 'musicbrainz',
        )) {
          final id = provider.definition.id;
          final dependencies = <CancellationToken?>[
            cancel,
            lookupCancellation[id],
            providerCancellation[id],
            lookupCancellation[recordingReference.candidate.providerId],
            providerCancellation[recordingReference.candidate.providerId],
          ];
          if (dependencies.any((token) => token?.isCancelled == true) ||
              !const {
                'unavailable',
                'ambiguous_match',
              }.contains(providerCodes[id]) ||
              results.any(
                (result) =>
                    result.candidate.providerId == id &&
                    result.matchKind != MatchKind.rejected,
              )) {
            continue;
          }
          final contextCancel = CancellationToken();
          for (final token in dependencies) {
            token?.cancelled.then((_) => contextCancel.cancel());
          }
          void checkContext() {
            for (final token in dependencies) {
              token?.throwIfCancelled();
            }
            contextCancel.throwIfCancelled();
          }

          final context = SongCandidate.fromJson({
            ...recordingReference.candidate.toJson(),
            'durationSeconds':
                recordingReference.candidate.durationSeconds ??
                selection.durationSeconds,
            'recordingIds': {
              ...selection.recordingIds,
              ...recordingReference.candidate.recordingIds,
            },
          });
          traceOpen[id] = true;
          providerChecksState[id] = 'pending';
          publish(id, 'pending');
          try {
            checkContext();
            final result =
                await findMatchingSource(
                  provider,
                  context,
                  cancel: contextCancel,
                  operationPrefix: 'metadata-context',
                  onOperation: (operation) {
                    if (!contextCancel.isCancelled) {
                      recordOperation(id, operation);
                    }
                  },
                ).timeout(
                  alternativeTimeout,
                  onTimeout: () {
                    contextCancel.cancel();
                    throw const ProviderException('timeout');
                  },
                );
            checkContext();
            if (result.matchKind == MatchKind.rejected) {
              throw const ProviderException('identity_mismatch');
            }
            final enriched = result.copyWith(
              extra: {
                ...result.extra,
                'resolvedRecordingContext': {
                  'providerId': context.providerId,
                  'candidateId': context.id,
                  'album': resolvedAlbum,
                },
              },
            );
            if (enriched.body.length > inlineChordScanLimit) {
              await prepareBody(enriched);
              checkContext();
            }
            final existing = results.indexWhere((old) => old.id == enriched.id);
            if (existing < 0) {
              results.add(enriched);
            } else {
              results[existing] = enriched;
            }
            preferredResultIds[id] = enriched.id;
            providerResults[id] = enriched;
            providerChecksState[id] = 'found';
            publish(id, 'found', result: enriched);
          } on ProviderException catch (error) {
            finalizePending(
              id,
              error.code == 'cancelled' ? 'cancelled' : 'failed',
              error.code,
              operationIdPrefix: '$id:metadata-context:',
            );
            if (cancel?.isCancelled == true) {
              finalizeCancelledChecks();
              cancel!.throwIfCancelled();
            }
            providerChecksState[id] = error.code == 'unavailable'
                ? 'unavailable'
                : 'failed';
            publish(id, providerChecksState[id]!, code: error.code);
          } catch (_) {
            cancel?.throwIfCancelled();
            finalizePending(
              id,
              'failed',
              'invalid_response',
              operationIdPrefix: '$id:metadata-context:',
            );
            providerChecksState[id] = 'failed';
            publish(id, 'failed', code: 'invalid_response');
          } finally {
            contextCancel.cancel();
            traceOpen[id] = false;
          }
        }
      }
      // Only resolved recording metadata supplies composer/work context. Reuse
      // the original search rows; do not issue another broad catalog search.
      for (final provider in active) {
        final id = provider.definition.id;
        final lookupCancel = lookupCancellation[id];
        final providerCancel = providerCancellation[id];
        final referenceCancel =
            providerCancellation[recordingReference.candidate.providerId];
        final referenceLookupCancel =
            lookupCancellation[recordingReference.candidate.providerId];
        cancel?.throwIfCancelled();
        if (referenceCancel?.isCancelled == true ||
            referenceLookupCancel?.isCancelled == true) {
          break;
        }
        if (!provider.definition.capabilities.contains('chords') ||
            lookupCancel?.isCancelled == true ||
            providerCancel?.isCancelled == true ||
            !const {'found', 'unavailable'}.contains(providerChecksState[id]) ||
            results.any(
              (r) =>
                  r.candidate.providerId == id &&
                  hasChords(r) &&
                  r.matchKind != MatchKind.rejected,
            )) {
          continue;
        }
        final candidates = (searchedByProvider[id] ?? const <SongCandidate>[])
            .where(
              (candidate) => contextualArrangementCandidate(
                recordingReference.candidate,
                candidate,
                allowAlternatePerformers: true,
              ),
            )
            .toList();
        if (candidates.isEmpty) continue;
        final contextualCancel = CancellationToken();
        cancel?.cancelled.then((_) => contextualCancel.cancel());
        lookupCancel?.cancelled.then((_) => contextualCancel.cancel());
        providerCancel?.cancelled.then((_) => contextualCancel.cancel());
        referenceCancel?.cancelled.then((_) => contextualCancel.cancel());
        referenceLookupCancel?.cancelled.then((_) => contextualCancel.cancel());
        final alternatives = <SourceResult>[];
        var succeeded = false;
        traceOpen[id] = true;
        providerChecksState[id] = 'pending';
        publish(id, 'pending');
        recordCorroboration(id, 'pending');
        try {
          cancel?.throwIfCancelled();
          providerCancel?.throwIfCancelled();
          lookupCancel?.throwIfCancelled();
          referenceCancel?.throwIfCancelled();
          referenceLookupCancel?.throwIfCancelled();
          final result =
              await findMatchingSource(
                provider,
                recordingReference.candidate,
                searchedCandidates: candidates,
                allowContextualArrangements: true,
                allowAlternatePerformers: true,
                operationPrefix: 'contextual',
                cancel: contextualCancel,
                onAlternative: alternatives.add,
                onOperation: (operation) {
                  if (!contextualCancel.isCancelled) {
                    recordOperation(id, operation);
                  }
                },
                accept: (result) async =>
                    await preparedHasChords(result) &&
                    (await scoreLyrics(result, recordingReference)).agrees,
              ).timeout(
                alternativeTimeout,
                onTimeout: () {
                  contextualCancel.cancel();
                  throw const ProviderException('timeout');
                },
              );
          cancel?.throwIfCancelled();
          lookupCancel?.throwIfCancelled();
          providerCancel?.throwIfCancelled();
          referenceCancel?.throwIfCancelled();
          referenceLookupCancel?.throwIfCancelled();
          contextualCancel.throwIfCancelled();
          if (result.matchKind == MatchKind.rejected || !hasChords(result)) {
            throw const ProviderException('unavailable');
          }
          final acceptedResult = await markPartialLyricSupport(
            result,
            recordingReference,
          );
          for (final rawAccepted in [...alternatives, acceptedResult]) {
            final accepted = await markPartialLyricSupport(
              rawAccepted,
              recordingReference,
            );
            final existing = results.indexWhere((r) => r.id == accepted.id);
            if (existing < 0) {
              results.add(accepted);
            } else {
              results[existing] = accepted;
            }
          }
          await warmDependencyScores([acceptedResult, ...alternatives]);
          contextualCancel.throwIfCancelled();
          preferredResultIds[id] = acceptedResult.id;
          providerResults[id] = acceptedResult;
          providerChecksState[id] = 'found';
          succeeded = true;
          recordCorroboration(id, 'completed');
          publish(id, 'found', result: acceptedResult);
        } on ProviderException catch (error) {
          finalizePending(
            id,
            error.code == 'cancelled' ? 'cancelled' : 'failed',
            error.code,
            operationIdPrefix: '$id:contextual:',
          );
          if (cancel?.isCancelled == true) {
            finalizeCancelledChecks();
            cancel!.throwIfCancelled();
          }
          providerChecksState[id] = error.code == 'unavailable'
              ? 'unavailable'
              : 'failed';
          recordCorroboration(id, 'failed', code: error.code);
          publish(id, providerChecksState[id]!, code: error.code);
        } catch (_) {
          finalizePending(
            id,
            'failed',
            'invalid_response',
            operationIdPrefix: '$id:contextual:',
          );
          cancel?.throwIfCancelled();
          providerChecksState[id] = 'failed';
          recordCorroboration(id, 'failed', code: 'invalid_response');
          publish(id, 'failed', code: 'invalid_response');
        } finally {
          contextualCancel.cancel();
          if (!succeeded) traceOpen[id] = false;
        }
      }
    }
    if (references.isNotEmpty) {
      await warmLyricScores([
        for (final chart in results)
          if (hasChords(chart) && chart.matchKind != MatchKind.rejected)
            lyricPair(chart, references.first),
      ]);
    }
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      final providerCancel = providerCancellation[result.candidate.providerId];
      if (providerCancel?.isCancelled == true) continue;
      if (!hasChords(result) || result.matchKind == MatchKind.rejected) {
        continue;
      }
      if (cancel?.isCancelled == true) {
        finalizeCancelledChecks();
        cancel!.throwIfCancelled();
      }
      if (references.isEmpty) {
        if (result.extra['requiresLyricsAgreement'] == true) {
          recordCorroboration(result.candidate.providerId, 'pending');
          results[i] = _matched(
            result,
            MatchKind.rejected,
            'uncorroborated_arrangement',
          );
          recordCorroboration(
            result.candidate.providerId,
            'rejected',
            code: 'uncorroborated_arrangement',
          );
        }
      } else {
        recordCorroboration(result.candidate.providerId, 'pending');
        final score = await scoreLyrics(result, references.first);
        if (!score.agrees) {
          // The first chart may be a truncated or different-lyrics version: try
          // the provider's other candidates against the same reference.
          SourceResult? alternative;
          final owners = active.where(
            (p) => p.definition.id == result.candidate.providerId,
          );
          if (owners.isNotEmpty) {
            final contextReferenceCancel = recordingReference == null
                ? null
                : providerCancellation[recordingReference.candidate.providerId];
            final contextReferenceLookupCancel = recordingReference == null
                ? null
                : lookupCancellation[recordingReference.candidate.providerId];
            final contextRows =
                recordingReference == null ||
                    lookupCancellation[result.candidate.providerId]
                            ?.isCancelled ==
                        true
                ? null
                : searchedByProvider[result.candidate.providerId];
            final canUseContext =
                contextReferenceCancel?.isCancelled != true &&
                contextReferenceLookupCancel?.isCancelled != true &&
                contextRows?.any(
                      (candidate) => contextualArrangementCandidate(
                        recordingReference!.candidate,
                        candidate,
                        allowAlternatePerformers: true,
                      ),
                    ) ==
                    true;
            // Linked local token: a timeout (or the caller cancelling) must stop
            // the underlying lookup, not just stop waiting for it, so a slow
            // retry cannot keep issuing requests after discover has returned.
            final alternativeCancel = CancellationToken();
            cancel?.cancelled.then((_) => alternativeCancel.cancel());
            providerCancel?.cancelled.then((_) => alternativeCancel.cancel());
            if (canUseContext) {
              contextReferenceCancel?.cancelled.then(
                (_) => alternativeCancel.cancel(),
              );
              contextReferenceLookupCancel?.cancelled.then(
                (_) => alternativeCancel.cancel(),
              );
            }
            try {
              cancel?.throwIfCancelled();
              providerCancel?.throwIfCancelled();
              if (canUseContext) {
                contextReferenceCancel?.throwIfCancelled();
                contextReferenceLookupCancel?.throwIfCancelled();
              }
              alternative =
                  await findMatchingSource(
                    owners.first,
                    canUseContext ? recordingReference!.candidate : selection,
                    searchedCandidates: canUseContext ? contextRows : null,
                    allowContextualArrangements: canUseContext,
                    allowAlternatePerformers:
                        canUseContext &&
                        owners.first.definition.capabilities.contains('chords'),
                    cancel: alternativeCancel,
                    exclude: {result.candidate.id},
                    allowSelectedProviderAlternatives: true,
                    operationPrefix: 'corroboration',
                    onOperation: (operation) {
                      if (!alternativeCancel.isCancelled) {
                        recordOperation(owners.first.definition.id, operation);
                      }
                    },
                    accept: (r) async =>
                        await preparedHasChords(r) &&
                        (await scoreLyrics(r, references.first)).agrees,
                  ).timeout(
                    alternativeTimeout,
                    onTimeout: () {
                      alternativeCancel.cancel();
                      throw const ProviderException('timeout');
                    },
                  );
              cancel?.throwIfCancelled();
              providerCancel?.throwIfCancelled();
              alternativeCancel.throwIfCancelled();
              if (canUseContext) {
                contextReferenceCancel?.throwIfCancelled();
                contextReferenceLookupCancel?.throwIfCancelled();
              }
              if (alternative.matchKind == MatchKind.rejected ||
                  !hasChords(alternative)) {
                alternative = null;
              }
            } on ProviderException catch (e) {
              finalizePending(
                result.candidate.providerId,
                e.code == 'cancelled' ? 'cancelled' : 'failed',
                e.code,
                operationIdPrefix:
                    '${result.candidate.providerId}:corroboration:',
              );
              if (e.code == 'cancelled' && (cancel?.isCancelled ?? false)) {
                recordCorroboration(
                  result.candidate.providerId,
                  'failed',
                  code: 'cancelled',
                );
                finalizeCancelledChecks();
                rethrow;
              }
              recordCorroboration(
                result.candidate.providerId,
                'failed',
                code: e.code,
              );
              alternative = null;
            } catch (_) {
              finalizePending(
                result.candidate.providerId,
                'failed',
                'invalid_response',
                operationIdPrefix:
                    '${result.candidate.providerId}:corroboration:',
              );
              recordCorroboration(
                result.candidate.providerId,
                'failed',
                code: 'invalid_response',
              );
              alternative = null;
            } finally {
              alternativeCancel.cancel();
            }
          }
          if (alternative != null) {
            alternative = await markPartialLyricSupport(
              alternative,
              references.first,
            );
            await warmDependencyScores([alternative]);
            cancel?.throwIfCancelled();
            if (providerCancel?.isCancelled == true) continue;
            // Withdraw the chart already emitted as a tentative result before
            // publishing its corroborated alternative under that source's ID.
            // Replacing the list slot alone leaves progressive consumers with
            // the old chart still accepted.
            results[i] = _matched(
              result,
              MatchKind.rejected,
              'incomplete_or_different_lyrics',
            );
            publish(
              result.candidate.providerId,
              'unavailable',
              code: results[i].matchReason,
              result: results[i],
            );
            final alternativeIndex = results.indexWhere(
              (item) => item.id == alternative!.id,
            );
            if (alternativeIndex < 0) {
              results.add(alternative);
            } else {
              results[alternativeIndex] = alternative;
            }
            preferredResultIds[alternative.candidate.providerId] =
                alternative.id;
            providerResults[alternative.candidate.providerId] = alternative;
            publish(
              alternative.candidate.providerId,
              providerChecksState[alternative.candidate.providerId] ?? 'found',
              result: alternative,
            );
            recordCorroboration(alternative.candidate.providerId, 'completed');
            continue;
          } else if (score.loose) {
            recordCorroboration(result.candidate.providerId, 'pending');
            // A chart can omit repeated choruses or ad-libs yet supply accurate
            // chords. Keep it as a donor; combineSources retains the full lyrics.
            results[i] = _matched(
              result,
              result.matchKind,
              'same_song',
              extra: {'partialLyrics': true},
            );
            providerResults[result.candidate.providerId] = results[i];
            publish(
              result.candidate.providerId,
              providerChecksState[result.candidate.providerId] ?? 'found',
              result: results[i],
            );
            recordCorroboration(result.candidate.providerId, 'completed');
          } else {
            recordCorroboration(result.candidate.providerId, 'pending');
            results[i] = _matched(
              result,
              MatchKind.rejected,
              'incomplete_or_different_lyrics',
            );
            recordCorroboration(
              result.candidate.providerId,
              'rejected',
              code: 'incomplete_or_different_lyrics',
            );
          }
        } else {
          if (score.scriptAlternative) {
            results[i] = result.copyWith(
              extra: {
                ...result.extra,
                'lyricRepresentation': 'latin_script_alternative',
                'lyricRepresentationEvidence': {
                  'referenceSourceId': references.first.id,
                  'basis': 'publisher_name_alias_and_different_writing_system',
                  'wordAgreementEstablished': false,
                },
              },
            );
          }
          recordCorroboration(result.candidate.providerId, 'completed');
        }
      }
      if (results[i].matchKind == MatchKind.rejected) {
        providerChecksState[result.candidate.providerId] = 'unavailable';
        providerResults[result.candidate.providerId] = results[i];
        publish(
          result.candidate.providerId,
          'unavailable',
          code: results[i].matchReason,
          result: results[i],
        );
      }
    }
    await warmDependencyScores(results);
    invalidateLyricDependentResults();
    await _checkChordKeys(
      results,
      active,
      selection,
      reference: references.firstOrNull,
      hasChords: hasChords,
      preparedHasChords: preparedHasChords,
      cancel: cancel,
      providerCancellation: providerCancellation,
      onOperation: recordOperation,
      timeout: alternativeTimeout,
    );
    await warmDependencyScores(results);
    invalidateLyricDependentResults();
    // One late pass only, after existing recording metadata retries and chart
    // checks settle. Missing context never triggers another donor search.
    for (final provider in active) {
      final id = provider.definition.id;
      final namespace = deferredRecordingReceivers[id];
      if (namespace == null) continue;
      cancel?.throwIfCancelled();
      if (!contextProviderEligible(id)) {
        providerChecksState[id] = 'cancelled';
        traceOpen[id] = false;
        publish(id, 'cancelled', code: 'cancelled');
        continue;
      }
      final eligibleProviders = {
        for (final source in results)
          if (contextProviderEligible(source.candidate.providerId))
            source.candidate.providerId,
      };
      final plan = await prepareRecordingContext(
        selection,
        results,
        namespace: namespace,
        eligible: eligibleProviders,
      );
      cancel?.throwIfCancelled();
      if (!contextProviderEligible(id)) {
        providerChecksState[id] = 'cancelled';
        traceOpen[id] = false;
        publish(id, 'cancelled', code: 'cancelled');
        continue;
      }
      if (plan == null) {
        providerChecksState[id] = 'unavailable';
        publish(id, 'unavailable', code: 'identity_required');
        continue;
      }
      final contextCancel = CancellationToken();
      final dependencies = <CancellationToken?>[
        cancel,
        lookupCancellation[id],
        providerCancellation[id],
        for (final witness in plan.witnesses) ...[
          lookupCancellation[witness.candidate.providerId],
          providerCancellation[witness.candidate.providerId],
        ],
      ];
      for (final dependency in dependencies) {
        dependency?.cancelled.then((_) => contextCancel.cancel());
      }
      void checkContext() {
        for (final dependency in dependencies) {
          dependency?.throwIfCancelled();
        }
        contextCancel.throwIfCancelled();
        if (!contextProviderEligible(id) ||
            !plan.isCurrent(
              results,
              original: selection,
              eligible: contextProviderEligible,
            )) {
          throw const ProviderException('identity_required');
        }
      }

      traceOpen[id] = true;
      providerChecksState[id] = 'pending';
      publish(id, 'pending');
      try {
        checkContext();
        final result =
            await Future.any<SourceResult>([
              findMatchingSource(
                provider,
                plan.selection,
                cancel: contextCancel,
                operationPrefix: 'recording-context',
                onOperation: (operation) {
                  if (!contextCancel.isCancelled) {
                    try {
                      checkContext();
                      recordOperation(id, operation);
                      // A synchronous operation callback can withdraw a donor
                      // before the adapter starts its HTTP request.
                      checkContext();
                    } on ProviderException {
                      contextCancel.cancel();
                      rethrow;
                    }
                  }
                },
              ),
              contextCancel.cancelled.then<SourceResult>(
                (_) => throw const ProviderException('cancelled'),
              ),
            ]).timeout(
              alternativeTimeout,
              onTimeout: () {
                contextCancel.cancel();
                throw const ProviderException('timeout');
              },
            );
        checkContext();
        if (result.matchKind != MatchKind.sameRecording ||
            result.candidate.recordingIds[plan.namespace] !=
                plan.selection.recordingIds[plan.namespace] ||
            !recordingCompatible(plan.selection, result)) {
          throw const ProviderException('identity_mismatch');
        }
        final enriched = result.copyWith(
          extra: {...result.extra, 'recordingContext': plan.provenance},
        );
        if (enriched.body.length > inlineChordScanLimit) {
          await prepareBody(enriched);
          checkContext();
        }
        recordingContextPlans[enriched.id] = plan;
        results.add(enriched);
        preferredResultIds[id] = enriched.id;
        providerResults[id] = enriched;
        providerChecksState[id] = 'found';
        publish(id, 'found', result: enriched);
        invalidateRecordingContextResults();
      } on ProviderException catch (error) {
        providerChecksState[id] =
            error.code == 'identity_required' || error.code == 'unavailable'
            ? 'unavailable'
            : 'failed';
        finalizePending(
          id,
          'failed',
          error.code,
          operationIdPrefix: '$id:recording-context:',
        );
        publish(id, providerChecksState[id]!, code: error.code);
        cancel?.throwIfCancelled();
      } catch (_) {
        providerChecksState[id] = 'failed';
        finalizePending(
          id,
          'failed',
          'invalid_response',
          operationIdPrefix: '$id:recording-context:',
        );
        publish(id, 'failed', code: 'invalid_response');
        cancel?.throwIfCancelled();
      } finally {
        contextCancel.cancel();
        traceOpen[id] = false;
      }
    }
    invalidateRecordingContextResults();
    for (final provider in active) {
      final id = provider.definition.id;
      final accepted = results
          .where(
            (source) =>
                source.candidate.providerId == id &&
                source.matchKind != MatchKind.rejected,
          )
          .toList();
      if (accepted.isNotEmpty) {
        final current =
            accepted
                .where((source) => source.id == preferredResultIds[id])
                .firstOrNull ??
            accepted.first;
        providerResults[id] = current;
        if (providerChecksState[id] != 'failed') {
          providerChecksState[id] = 'found';
          publish(id, 'found', result: current);
        } else {
          publish(
            id,
            'failed',
            code: providerCodes[id],
            result: current,
            preserveCode: true,
          );
        }
      }
      finalizePending(provider.definition.id, 'failed', 'provider_error');
      traceOpen[provider.definition.id] = false;
    }
    await warmDependencyScores(results);
    invalidateLyricDependentResults();
    invalidateRecordingContextResults();
    return results
        .where(
          (result) =>
              providerCancellation[result.candidate.providerId]?.isCancelled !=
              true,
        )
        .toList();
  }

  /// Prefer identifiers bound to the selection. A clean empty analysis can
  /// fall back to compatible same-song recordings without asserting that they
  /// identify the selected recording. Failed requests never trigger retries.
  Future<
    ({
      RecordingKey key,
      Set<String> providers,
      List<String> sourceIds,
      List<String> carrierIds,
      bool recordingBound,
    })?
  >
  _recordingKey(
    SongCandidate selection,
    List<SourceResult> results,
    bool Function(String providerId) eligible, {
    CancellationToken? cancel,
  }) async {
    final service = recordingKeys;
    if (service == null) return null;
    final pool = [...results];
    final carriers = {for (final source in results) source.id: source.id};
    for (final source in results.where(
      (source) => source.extra['metadataOnly'] == true,
    )) {
      for (final raw
          in source.extra['providerAlternatives'] is List
              ? source.extra['providerAlternatives'] as List
              : const []) {
        if (raw is! Map) continue;
        try {
          final alternative = SourceResult.fromJson(jsonMap(raw));
          if (alternative.extra['metadataOnly'] == true &&
              alternative.body.trim().isEmpty &&
              alternative.candidate.providerId == source.candidate.providerId &&
              alternative.matchKind == MatchKind.sameSong &&
              sameSong(selection, alternative.candidate)) {
            pool.add(alternative);
            carriers[alternative.id] = source.id;
          }
        } on Object {
          // The raw alternative remains archived even when it is not a safe identifier donor.
        }
      }
    }
    final exact = pool
        .where(
          (result) =>
              result.matchKind == MatchKind.sameRecording &&
              !result.hasPendingMatchCheck &&
              eligible(result.candidate.providerId),
        )
        .toList();
    double? duration(SourceResult source) {
      final value =
          source.candidate.durationSeconds ??
          source.metadata['durationSeconds'] ??
          source.metadata['duration'] ??
          source.candidate.metadata['durationSeconds'] ??
          source.candidate.metadata['duration'];
      return value is num && value.isFinite && value > 0
          ? value.toDouble()
          : null;
    }

    String? album(SourceResult source) {
      final value =
          source.candidate.album ??
          source.metadata['album'] ??
          source.candidate.metadata['album'];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    final selectedSource = SourceResult(candidate: selection, body: '');
    final knownAlbums = <String>{
      if (album(selectedSource) case final String value)
        normalizedIdentity(value),
      for (final source in exact)
        if (album(source) case final String value) normalizedIdentity(value),
    };
    final selectedDuration = duration(selectedSource);
    final knownDurations = selectedDuration != null
        ? [selectedDuration]
        : exact.map(duration).whereType<double>().toList();
    bool fallbackMatches(SourceResult source) {
      if (source.matchKind != MatchKind.sameSong ||
          source.hasPendingMatchCheck ||
          !eligible(source.candidate.providerId) ||
          !sameSong(selection, source.candidate) ||
          !explicitEditionsCompatible(
            selection,
            source.candidate,
            metadata: source.metadata,
            extra: source.extra,
          )) {
        return false;
      }
      for (final anchor in exact) {
        if (!explicitEditionsCompatible(
          anchor.candidate,
          source.candidate,
          selectedMetadata: anchor.metadata,
          selectedExtra: anchor.extra,
          metadata: source.metadata,
          extra: source.extra,
        )) {
          return false;
        }
      }
      final length = duration(source);
      if (length != null &&
          knownDurations.isNotEmpty &&
          !knownDurations.any((known) => (known - length).abs() <= 3)) {
        return false;
      }
      final albums = <String>{
        if (album(source) case final String value) normalizedIdentity(value),
        for (final map in [source.candidate.metadata, source.metadata])
          for (final raw
              in map['releases'] is List ? map['releases'] as List : const [])
            if (raw is Map && raw['title'] is String)
              normalizedIdentity(raw['title'] as String),
      };
      return knownAlbums.isEmpty ||
          albums.isEmpty ||
          albums.any(knownAlbums.contains);
    }

    final lookupCancel = CancellationToken();
    cancel?.cancelled.then((_) => lookupCancel.cancel());
    final tried = <String>{};
    Future<
      ({
        RecordingKey key,
        Set<String> providers,
        List<String> sourceIds,
        List<String> carrierIds,
        bool recordingBound,
      })?
    >
    lookup(List<SourceResult> sources, bool recordingBound) async {
      final spotify = <String>{}, isrcs = <String>{}, providers = <String>{};
      final sourceIds = <String>{};
      for (final source in sources) {
        if (!eligible(source.candidate.providerId)) continue;
        final ids = recordingIdentifiers(source);
        final freshSpotify = ids.spotify
            .where((id) => !tried.contains(id))
            .toList();
        final freshIsrcs = ids.isrcs
            .where((id) => !tried.contains(id))
            .toList();
        if (freshSpotify.isEmpty && freshIsrcs.isEmpty) continue;
        spotify.addAll(freshSpotify);
        isrcs.addAll(freshIsrcs);
        providers.add(source.candidate.providerId);
        sourceIds.add(source.id);
      }
      if (spotify.isEmpty && isrcs.isEmpty) return null;
      tried.addAll({...spotify, ...isrcs});
      cancel?.throwIfCancelled();
      final key = await service.lookup(
        spotifyIds: spotify.toList(),
        isrcs: isrcs.toList(),
        cancel: lookupCancel,
        retainAlternatives: true,
      );
      cancel?.throwIfCancelled();
      return key == null || !providers.every(eligible)
          ? null
          : (
              key: key,
              providers: providers,
              sourceIds: sourceIds.toList()..sort(),
              carrierIds:
                  sourceIds.map((id) => carriers[id] ?? id).toSet().toList()
                    ..sort(),
              recordingBound: recordingBound,
            );
    }

    try {
      final bound = await lookup(exact, true);
      if (bound != null) return bound;
      // Cancellation of an identity witness invalidates this lookup batch.
      if (!exact.every((source) => eligible(source.candidate.providerId))) {
        return null;
      }
      final fallback = pool.where(fallbackMatches).where((source) {
        final ids = recordingIdentifiers(source);
        return [...ids.spotify, ...ids.isrcs].any((id) => !tried.contains(id));
      }).toList();
      int preference(SourceResult source) {
        var score = 0;
        final length = duration(source);
        if (length != null &&
            knownDurations.any((known) => (known - length).abs() <= 3)) {
          score += 4;
        }
        if (album(source) case final String value) {
          if (knownAlbums.contains(normalizedIdentity(value))) score += 4;
        }
        final edition = [
          source.candidate.title,
          for (final map in [
            source.candidate.metadata,
            source.metadata,
            source.extra,
          ])
            for (final field in const [
              'version',
              'edition',
              'disambiguation',
              'recording',
            ])
              if (map[field] is String) map[field] as String,
        ].join(' ').toLowerCase();
        if (RegExp(r'\b(?:album version|studio)\b').hasMatch(edition)) {
          score += 1;
        }
        return score;
      }

      fallback.sort((a, b) {
        final ranked = preference(b).compareTo(preference(a));
        return ranked != 0 ? ranked : a.id.compareTo(b.id);
      });
      // Keep each fallback recording's identifiers together. Different edits
      // must not vote as if they were one recording merely sharing a song.
      return fallback.isEmpty ? null : await lookup([fallback.first], false);
    } on ProviderException {
      cancel?.throwIfCancelled();
      return null;
    } catch (_) {
      cancel?.throwIfCancelled();
      return null;
    } finally {
      lookupCancel.cancel();
    }
  }

  /// Chord charts of one song are sometimes written in another key, such as a
  /// capo chart in G of a song recorded in E. When accepted charts disagree,
  /// or a chart's declared key contradicts its own chords, this double checks with up to six more charts from each chord source
  /// and marks each accepted chart with `keyConsensus`: true in the key most
  /// charts share, false when transposed from it, with `keyShift` semitones
  /// that move it into that key, and `keyEstimate`, the estimated sounding
  /// majority key, when the charts' estimates agree. Nothing is marked when the
  /// charts agree, no key has more than half of the distinct charts, or the
  /// extra lookups fail; the extra charts are only votes and never become
  /// results.
  ///
  /// A vote must have a compatible edition and words that agree with the
  /// lyric [reference] (or, without one, with an accepted chart), so a
  /// different song or arrangement under the same title cannot vote. Like
  /// lyric corroboration, cancellation is checked before each lookup, and a
  /// provider cancelled or disabled meanwhile contributes no chart or vote.
  Future<void> _checkChordKeys(
    List<SourceResult> results,
    List<LyricsProvider> active,
    SongCandidate selection, {
    required bool Function(SourceResult) hasChords,
    required Future<bool> Function(SourceResult) preparedHasChords,
    SourceResult? reference,
    CancellationToken? cancel,
    Map<String, CancellationToken> providerCancellation = const {},
    void Function(String providerId, ProviderOperation operation)? onOperation,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    bool eligible(String providerId) =>
        providerCancellation[providerId]?.isCancelled != true;
    JsonMap recordingEvidence(
      RecordingKey key,
      bool bound, {
      List<String> sourceIds = const [],
      Set<String> providers = const {},
    }) => {
      ...key.toJson(),
      if (key.alternatives.isNotEmpty)
        'alternatives': [
          for (final alternative in key.alternatives)
            recordingEvidence(
              alternative,
              bound,
              sourceIds: sourceIds,
              providers: providers,
            ),
        ],
      'recordingScope': bound ? 'recording' : 'song',
      'identifierSourceIds': sourceIds,
      'identifierProviders': providers.toList()..sort(),
      if (bound) 'selectedIdentity': selection.identity,
    };
    List<int> acceptedIndexes() => [
      for (var i = 0; i < results.length; i++)
        if (hasChords(results[i]) &&
            results[i].matchKind != MatchKind.rejected &&
            eligible(results[i].candidate.providerId))
          i,
    ];
    final heard = await _recordingKey(
      selection,
      results,
      eligible,
      cancel: cancel,
    );
    // Recording metadata is useful even when no chart has been found. Keep
    // the analysis on its identifier witnesses, independently of chord checks.
    if (heard != null && heard.providers.every(eligible)) {
      for (var i = 0; i < results.length; i++) {
        if (heard.carrierIds.contains(results[i].id) &&
            eligible(results[i].candidate.providerId)) {
          results[i] = results[i].copyWith(
            extra: {
              ...results[i].extra,
              'keyRecording': recordingEvidence(
                heard.key,
                heard.recordingBound,
                sourceIds: heard.sourceIds,
                providers: heard.providers,
              ),
            },
          );
        }
      }
    }
    final indexes = acceptedIndexes();
    if (indexes.isEmpty) return;
    final initialCharts = [for (final i in indexes) results[i]];
    final charts = [for (final chart in initialCharts) chart.body];
    // Conflicting analyses belong in the combination ranker. A scalar tie
    // break must never authorize an earlier in-place chart correction.
    var recording =
        heard?.recordingBound == true && heard!.key.alternatives.isEmpty
        ? heard.key
        : null;
    final doubt = await _needsChordKeyCheck(initialCharts, recording?.key);
    cancel?.throwIfCancelled();
    if (!doubt) {
      // No doubt to settle; the measured key still helps name a key the
      // chords leave open (a relative major or minor).
      if (heard != null && heard.providers.every(eligible)) {
        for (final i in indexes) {
          if (!eligible(results[i].candidate.providerId)) continue;
          results[i] = results[i].copyWith(
            extra: {
              ...results[i].extra,
              'keyRecording': recordingEvidence(
                heard.key,
                heard.recordingBound,
                sourceIds: heard.sourceIds,
                providers: heard.providers,
              ),
            },
          );
        }
      }
      return;
    }
    bool referenceEligible() =>
        reference == null || eligible(reference.candidate.providerId);
    final shortReference =
        reference != null &&
        reference.matchKind == MatchKind.sameRecording &&
        recordingCompatible(selection, reference);
    final lyricVotes = <String, Future<bool>>{};
    Future<bool> canVote(SourceResult result) async {
      if (!referenceEligible() ||
          !await preparedHasChords(result) ||
          result.matchKind == MatchKind.rejected ||
          !explicitEditionsCompatible(
            selection,
            result.candidate,
            metadata: result.metadata,
            extra: result.extra,
          )) {
        return false;
      }
      final agrees = await lyricVotes.putIfAbsent(
        result.body,
        () => _scoreKeyVoteLyrics(
          result.body,
          charts,
          reference?.body,
          shortReference,
        ),
      );
      return agrees && referenceEligible();
    }

    // Each chord source has its own host and token, so the double checks run
    // together. Ballots are joined in `active` order below: the verdict must
    // not depend on which source happened to answer first.
    Future<List<({String providerId, SourceResult chart})>> ballot(
      LyricsProvider provider,
    ) async {
      final ballots = <({String providerId, SourceResult chart})>[];
      final id = provider.definition.id;
      cancel?.throwIfCancelled();
      if (!eligible(id) || !referenceEligible()) return ballots;
      final checkCancel = CancellationToken();
      cancel?.cancelled.then((_) => checkCancel.cancel());
      providerCancellation[id]?.cancelled.then((_) => checkCancel.cancel());
      if (reference != null) {
        providerCancellation[reference.candidate.providerId]?.cancelled.then(
          (_) => checkCancel.cancel(),
        );
      }
      try {
        final found = <SourceResult>[];
        final best =
            await findMatchingSource(
              provider,
              selection,
              cancel: checkCancel,
              exclude: {
                for (final i in indexes)
                  if (results[i].candidate.providerId == id)
                    results[i].candidate.id,
              },
              allowSelectedProviderAlternatives: true,
              operationPrefix: 'keycheck',
              // A key in doubt needs enough charts to show a majority.
              maxAttempts: 6,
              accept: canVote,
              onAlternative: found.add,
              onOperation: (operation) {
                if (!checkCancel.isCancelled) onOperation?.call(id, operation);
              },
            ).timeout(
              timeout,
              onTimeout: () {
                checkCancel.cancel();
                throw const ProviderException('timeout');
              },
            );
        cancel?.throwIfCancelled();
        if (!eligible(id) || !referenceEligible()) return ballots;
        for (final chart in [best, ...found]) {
          if (await canVote(chart)) ballots.add((providerId: id, chart: chart));
        }
      } on ProviderException {
        // The caller's cancellation wins over whatever the linked token made
        // the lookup report first.
        cancel?.throwIfCancelled();
      } catch (_) {
        cancel?.throwIfCancelled();
        // A failed double check leaves the charts as they were.
      } finally {
        checkCancel.cancel();
      }
      return ballots;
    }

    final votes = [
      for (final ballots in await Future.wait([
        for (final provider in active.where(
          (p) => p.definition.capabilities.contains('chords'),
        ))
          ballot(provider),
      ]))
        ...ballots,
    ];
    cancel?.throwIfCancelled();
    // Reference cancellation invalidates the lyric proof for this vote batch.
    if (!referenceEligible()) return;
    // Providers disabled during a scoring batch cannot contribute a vote.
    late List<int> current;
    late List<SourceResult> sources;
    ({List<int?> shifts, String? keyEstimate})? outcome;
    while (true) {
      current = [
        for (final i in acceptedIndexes())
          if (indexes.contains(i)) i,
      ];
      if (current.isEmpty) return;
      sources = [
        for (final i in current) results[i],
        for (final vote in votes)
          if (eligible(vote.providerId)) vote.chart,
      ];
      if (heard != null && !heard.providers.every(eligible)) recording = null;
      outcome = await _scoreChordKeys(sources, current.length, recording?.key);
      cancel?.throwIfCancelled();
      if (!referenceEligible()) return;
      if (sources.every((source) => eligible(source.candidate.providerId)) &&
          (recording == null || heard!.providers.every(eligible))) {
        break;
      }
    }
    // Same-song analyses inform ranking, but cannot authorize a correction
    // of the selected recording's published chart setup.
    if (heard != null &&
        !heard.recordingBound &&
        heard.providers.every(eligible)) {
      for (final i in current) {
        results[i] = results[i].copyWith(
          extra: {
            ...results[i].extra,
            'keyRecording': recordingEvidence(
              heard.key,
              false,
              sourceIds: heard.sourceIds,
              providers: heard.providers,
            ),
          },
        );
      }
    }
    if (outcome == null) return;
    final verdict = outcome.shifts;
    final keyEstimate = outcome.keyEstimate;
    for (var n = 0; n < current.length; n++) {
      final shift = verdict[n];
      if (shift == null) continue;
      final i = current[n];
      results[i] = results[i].copyWith(
        extra: {
          ...results[i].extra,
          'keyConsensus': shift == 0,
          'keyShift': ?(shift == 0 ? null : shift),
          'keyCheckCharts': sources.length,
          'keyEstimate': ?keyEstimate,
          'keyRecording': ?(recording == null
              ? null
              : recordingEvidence(
                  recording,
                  true,
                  sourceIds: heard!.sourceIds,
                  providers: heard.providers,
                )),
        },
      );
    }
  }
}

