import 'dart:async';

import 'provider.dart';

/// Queries each eligible catalog once, preserving every row's original identity.
///
/// The preferred catalog ranks first; other catalogs rank by ID, independently
/// of completion order. This union does not establish equivalence between rows
/// or copy recording metadata between them. Historical text stays isolated from
/// ordinary song catalogs.
///
/// [onProgress] receives immutable partial snapshots before slow catalogs finish.
/// Statuses are pending/completed/failed for attempted queries; closing a query
/// marks active queries timeout/cancelled and queued ones not_attempted. Filtered
/// catalogs are not attempted or reported. Codes never contain upstream messages.
/// A provider cancellation retires only that provider, including transports
/// which finish after cancellation. It does not discard other catalog results.
Future<List<SongCandidate>> searchCatalogsTogether(
  String query, {
  required List<ProviderDefinition> definitions,
  required String primaryProviderId,
  required Set<String> enabledIds,
  required Future<List<SongCandidate>> Function(
    String providerId,
    CancellationToken cancel,
  )
  search,
  CancellationToken? cancel,
  Duration timeout = const Duration(seconds: 8),
  int concurrency = 4,
  Map<String, CancellationToken> providerCancellation = const {},
  void Function(List<SongCandidate>)? onProgress,
  void Function(String providerId, String state, String? code)? onStatus,
}) async {
  cancel?.throwIfCancelled();
  final eligible = <String, ProviderDefinition>{};
  for (final definition in definitions) {
    if (definition.configured &&
        definition.capabilities.contains('catalog') &&
        enabledIds.contains(definition.id)) {
      eligible.putIfAbsent(definition.id, () => definition);
    }
  }
  final primary = eligible[primaryProviderId];
  if (primary == null) {
    throw const ProviderException('not_configured');
  }
  if (query.trim().isEmpty) {
    return const [];
  }
  if (timeout <= Duration.zero) {
    throw const ProviderException('timeout');
  }

  bool historical(ProviderDefinition definition) =>
      definition.id == 'wikisource' ||
      definition.accessMode == 'publicDomainText';
  final ids = historical(primary)
      ? <String>[primaryProviderId]
      : (eligible.values
            .where((definition) => !historical(definition))
            .map((definition) => definition.id)
            .where((id) => id != primaryProviderId)
            .toList()
          ..sort());
  if (ids.isEmpty || ids.first != primaryProviderId) {
    ids.insert(0, primaryProviderId);
  }

  final completed = Completer<void>();
  final rowsById = <String, List<SongCandidate>>{};
  final active = <String, CancellationToken>{};
  Object? primaryError;
  StackTrace? primaryStack;
  var next = 0;
  var closed = false;
  var timedOut = false;
  final elapsed = Stopwatch()..start();

  List<SongCandidate> snapshot() {
    final seen = <(String, String)>{};
    return List.unmodifiable([
      for (final id in ids)
        if (providerCancellation[id]?.isCancelled != true)
          for (final row in rowsById[id] ?? const <SongCandidate>[])
            if (seen.add((row.providerId, row.id))) row,
    ]);
  }

  void status(String id, String state, [String? code]) {
    try {
      onStatus?.call(id, state, code);
    } catch (_) {
      // Observers cannot turn a usable catalog response into a source failure.
    }
  }

  void finish([String? reason]) {
    if (closed) {
      return;
    }
    closed = true;
    for (final entry in active.entries) {
      entry.value.cancel();
      if (reason != null) {
        status(entry.key, reason, reason);
      }
    }
    if (reason != null) {
      for (final id in ids.skip(next)) {
        status(id, 'not_attempted', reason);
      }
    }
    completed.complete();
  }

  bool shouldStop() {
    if (cancel?.isCancelled ?? false) {
      finish('cancelled');
    }
    if (!closed && elapsed.elapsed >= timeout) {
      timedOut = true;
      finish('timeout');
    }
    return closed;
  }

  final timer = Timer(timeout, () {
    if (cancel?.isCancelled ?? false) {
      finish('cancelled');
    } else {
      timedOut = true;
      finish('timeout');
    }
  });
  if (cancel != null) {
    unawaited(cancel.cancelled.then((_) => finish('cancelled')));
  }

  Future<void> worker() async {
    while (!shouldStop() && next < ids.length) {
      final id = ids[next++];
      final child = providerCancellation[id] ?? CancellationToken();
      if (child.isCancelled) {
        if (id == primaryProviderId) {
          primaryError = const ProviderException('cancelled');
          primaryStack = StackTrace.current;
        }
        status(id, 'cancelled', 'cancelled');
        continue;
      }
      active[id] = child;
      status(id, 'pending');
      if (shouldStop()) {
        return;
      }
      try {
        child.throwIfCancelled();
        final rows = await Future.any<List<SongCandidate>>([
          Future.sync(() => search(id, child)),
          child.cancelled.then<List<SongCandidate>>((_) {
            throw const ProviderException('cancelled');
          }),
        ]);
        child.throwIfCancelled();
        if (!shouldStop()) {
          rowsById[id] = rows
              .where((row) => row.providerId == id)
              .toList(growable: false);
          active.remove(id);
          status(id, 'completed');
          if (!shouldStop()) {
            try {
              onProgress?.call(snapshot());
            } catch (_) {
              // UI observation is independent of provider success.
            }
          }
        }
      } catch (error, stack) {
        if (!shouldStop()) {
          active.remove(id);
          if (id == primaryProviderId) {
            primaryError = child.isCancelled
                ? const ProviderException('cancelled')
                : error;
            primaryStack = stack;
          }
          status(
            id,
            child.isCancelled ? 'cancelled' : 'failed',
            child.isCancelled ? 'cancelled' : _errorCode(error),
          );
        }
      } finally {
        active.remove(id);
      }
    }
  }

  final limit = concurrency < 1 ? 1 : (concurrency > 4 ? 4 : concurrency);
  final count = limit > ids.length ? ids.length : limit;
  unawaited(
    Future.wait(List.generate(count, (_) => worker())).then((_) {
      finish();
    }),
  );
  await completed.future;
  timer.cancel();
  elapsed.stop();
  cancel?.throwIfCancelled();

  final result = snapshot();
  if (result.isNotEmpty) {
    return result;
  }
  if (primaryError != null) {
    Error.throwWithStackTrace(primaryError!, primaryStack!);
  }
  if (timedOut) {
    throw const ProviderException('timeout');
  }
  return const [];
}

String _errorCode(Object error) =>
    error is ProviderException &&
        const {
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
          'redirect',
          'rights_review_required',
          'select_specific_work',
          'title_required',
          'timeout',
          'transport_closed',
          'uncorroborated_arrangement',
          'incomplete_or_different_lyrics',
          'validation_rejected',
          'unavailable',
          'user_selection_required',
        }.contains(error.code)
    ? error.code
    : 'provider_error';
