import 'dart:async';
import 'diagnostics.dart';
import 'dart:math' as math;
import '../../domain/models.dart';
import '../provider.dart';
import '../source_catalog_client.dart';

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
    this.operations = const [],
  });
  final String providerId, state;
  final String? code;
  final SourceResult? result;
  final List<ProviderOperation> operations;
}

String normalizedIdentity(String text) => text
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();
String _titleKey(String title) => normalizedIdentity(
  title.replaceFirst(
    RegExp(
      r'\s*(?:\((?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?\)|\[(?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?\]|\s[-–—]\s(?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?)\s*$',
      caseSensitive: false,
    ),
    '',
  ),
);
String arrangementTitle(String title) => title
    .replaceFirst(
      RegExp(
        r'\s*(?:\((?:(?:acoustic|live|unplugged|version)\s*)+\)|\[(?:(?:acoustic|live|unplugged|version)\s*)+\]|\s[-–—]\s(?:(?:acoustic|live|unplugged|version)\s*)+)\s*$',
        caseSensitive: false,
      ),
      '',
    )
    .trim();
Set<String> _versions(String value, {bool album = false}) {
  final labels = album
      ? [value]
      : RegExp(
          r'\(([^()]*)\)|\[([^\[\]]*)\]|\s[-–—]\s(.+)$',
        ).allMatches(value).map((m) => m[1] ?? m[2] ?? m[3]!).toList();
  final result = <String>{};
  for (final label in labels) {
    final text = normalizedIdentity(label);
    var remaining = text;
    final found = <String>{};
    for (final marker in [
      'live',
      'acoustic',
      'unplugged',
      'karaoke',
      'instrumental',
      'sped up',
      'slowed',
      'nightcore',
    ]) {
      final matches = RegExp('(?:^|\\s)$marker(?:\\s|\$)').hasMatch(text);
      if (!matches) continue;
      if (album) {
        final explicit =
            RegExp(
              '(?:[\\[(]\\s*|\\s[-–—]\\s+)$marker\\b',
              caseSensitive: false,
            ).hasMatch(value) ||
            (marker == 'live'
                ? RegExp(
                    r'^live(?:\s+\d{4})?\s*$|\blive\s+(?:at|in|from|on)\b|^live\s+\d{4}',
                    caseSensitive: false,
                  ).hasMatch(value)
                : RegExp('^$marker\\b', caseSensitive: false).hasMatch(value));
        if (!explicit) continue;
      }
      final version = marker == 'unplugged' ? 'acoustic' : marker;
      if (album) {
        result.add(version);
      } else {
        found.add(version);
        remaining = remaining.replaceAll(RegExp('\\b$marker\\b'), ' ');
      }
    }
    if (!album &&
        remaining
            .replaceAll(
              RegExp(r'\b(?:version|recording|performance|session)\b'),
              ' ',
            )
            .trim()
            .isEmpty) {
      result.addAll(found);
    }
  }
  return result;
}

bool sameSong(SongCandidate selected, SongCandidate result) {
  for (final id in selected.recordingIds.entries) {
    if (result.recordingIds.containsKey(id.key) &&
        result.recordingIds[id.key] != id.value) {
      return false;
    }
  }
  if (_titleKey(selected.title) != _titleKey(result.title) ||
      normalizedIdentity(selected.artist) !=
          normalizedIdentity(result.artist)) {
    return false;
  }
  final a = _versions(selected.album ?? '', album: true),
      b = _versions(result.album ?? '', album: true);
  if (a.difference(b).isNotEmpty || b.difference(a).isNotEmpty) {
    if (selected.album != null && result.album != null) return false;
    if (selected.identity != result.identity &&
        !_versions(selected.title).containsAll({...a, ...b})) {
      return false;
    }
  }
  final sa = selected.durationSeconds, sb = result.durationSeconds;
  if (sa != null &&
      sb != null &&
      (sa - sb).abs() > math.min(15, math.max(8, sa * 0.02))) {
    return false;
  }
  return true;
}

bool sameArrangement(
  SongCandidate selected,
  SongCandidate result,
  LyricsProvider provider,
) {
  if (!provider.definition.capabilities.contains('chords') ||
      normalizedIdentity(selected.artist) !=
          normalizedIdentity(result.artist)) {
    return false;
  }
  final a = arrangementTitle(selected.title);
  var b = arrangementTitle(result.title);
  if (a != selected.title) {
    b = b.replaceFirst(RegExp(r'\s+acoustic$', caseSensitive: false), '');
  }
  return _titleKey(a) == _titleKey(b);
}

bool _sameAlbum(SongCandidate a, SongCandidate b) =>
    a.album != null &&
    b.album != null &&
    normalizedIdentity(a.album!) == normalizedIdentity(b.album!);
bool _selectedHistoricalText(
  SongCandidate selected,
  SongCandidate result,
  String providerId,
) =>
    providerId == 'wikisource' &&
    selected.providerId == providerId &&
    result.providerId == providerId &&
    selected.id == result.id &&
    RegExp(r'^\d+$').hasMatch(selected.id) &&
    result.metadata['identityScope'] == 'historicalText' &&
    normalizedIdentity(selected.title) == normalizedIdentity(result.title) &&
    (selected.artist.trim().isEmpty ||
        normalizedIdentity(selected.artist) ==
            normalizedIdentity(result.artist));
double _rank(SongCandidate selection, SongCandidate song) =>
    (_sameAlbum(selection, song) ? 100 : 0) +
    (normalizedIdentity(selection.title) == normalizedIdentity(song.title)
        ? 20
        : 0) +
    (selection.durationSeconds != null && song.durationSeconds != null
        ? 40 - (selection.durationSeconds! - song.durationSeconds!).abs()
        : 0);
SourceResult _matched(
  SourceResult result,
  MatchKind kind,
  String reason, {
  JsonMap extra = const {},
}) => SourceResult(
  candidate: result.candidate,
  body: result.body,
  metadata: result.metadata,
  timingTracks: result.timingTracks,
  matchKind: kind,
  matchReason: reason,
  attribution: result.attribution,
  retrievedAt: result.retrievedAt,
  extra: {...result.extra, ...extra},
);

Future<SourceResult> findMatchingSource(
  LyricsProvider provider,
  SongCandidate selection, {
  CancellationToken? cancel,
  // Candidate ids already tried by an earlier pass.
  Set<String> exclude = const {},
  // Extra acceptance test (for example lyrics corroboration). A result that
  // fails it is skipped so the next candidate can be tried.
  bool Function(SourceResult result)? accept,
  void Function(ProviderOperation operation)? onOperation,
  String operationPrefix = 'lookup',
}) async {
  final phaseSequences = <String, int>{};
  final activeOperationIds = <String, String>{};
  void report(
    String phase,
    String state, {
    String? code,
    String? query,
    SongCandidate? candidate,
    int? resultCount,
    int? elapsedMilliseconds,
  }) {
    if (cancel?.isCancelled == true) return;
    final id = state == 'pending'
        ? '${provider.definition.id}:$operationPrefix:$phase:${phaseSequences.update(phase, (n) => n + 1, ifAbsent: () => 0)}'
        : activeOperationIds[phase] ??
              '${provider.definition.id}:$operationPrefix:$phase:${phaseSequences.update(phase, (n) => n + 1, ifAbsent: () => 0)}';
    activeOperationIds[phase] = id;
    onOperation?.call(
      ProviderOperation(
        id: id,
        phase: phase,
        state: state,
        code: code == null ? null : _safeDiagnosticCode(code),
        query: query,
        title: candidate?.title,
        artist: candidate?.artist,
        sourceUrl: candidate?.providerId == provider.definition.id
            ? safeDiagnosticUrl(candidate?.url)
            : null,
        resultCount: resultCount,
        elapsedMilliseconds: elapsedMilliseconds,
      ),
    );
  }

  final metadataOnly =
      provider.definition.capabilities.contains('metadata') &&
      !provider.definition.capabilities.contains('lyrics') &&
      !provider.definition.capabilities.contains('chords');
  if (metadataOnly) {
    // Enrichment adapters have source-specific ambiguity checks and identity
    // lookup (for example MusicBrainz IDs or an exact Commons filename). Do not
    // bypass those checks by selecting the first generic search hit here.
    final fetchWatch = Stopwatch()..start();
    report('metadata', 'pending', candidate: selection);
    late final SourceResult result;
    try {
      result = await provider.resolve(selection, cancel: cancel);
      report(
        'metadata',
        'completed',
        candidate: result.candidate,
        elapsedMilliseconds: fetchWatch.elapsedMilliseconds,
      );
    } on ProviderException catch (error) {
      report(
        'metadata',
        'failed',
        code: error.code,
        candidate: selection,
        elapsedMilliseconds: fetchWatch.elapsedMilliseconds,
      );
      rethrow;
    } catch (_) {
      report(
        'metadata',
        'failed',
        code: 'invalid_response',
        candidate: selection,
        elapsedMilliseconds: fetchWatch.elapsedMilliseconds,
      );
      rethrow;
    }
    report('validate', 'pending', candidate: result.candidate);
    final song = result.candidate;
    if (song.providerId != provider.definition.id ||
        !sameSong(selection, song)) {
      report(
        'validate',
        'rejected',
        code: 'identity_mismatch',
        candidate: song,
      );
      return _matched(result, MatchKind.rejected, 'identity_mismatch');
    }
    if (result.metadata.isEmpty) {
      report('validate', 'failed', code: 'unavailable', candidate: song);
      throw const ProviderException('unavailable');
    }
    report('validate', 'completed', candidate: song);
    final sharedId = selection.recordingIds.entries.any(
      (e) => song.recordingIds[e.key] == e.value,
    );
    final recordingScope = song.metadata['identityScope'] == 'recording';
    final exact =
        recordingScope &&
        (selection.identity == song.identity ||
            sharedId ||
            _sameAlbum(selection, song) &&
                selection.durationSeconds != null &&
                song.durationSeconds != null &&
                (selection.durationSeconds! - song.durationSeconds!).abs() <=
                    3);
    return _matched(
      result,
      exact ? MatchKind.sameRecording : MatchKind.sameSong,
      exact ? 'same_recording' : 'same_song',
    );
  }
  var attempts = 0;
  final seen = <String>{...exclude};
  // The first identity rejection is kept, but only returned once every
  // candidate has been tried.
  SourceResult? rejected;
  // Every soft failure is kept (candidate id and code), not just the first.
  final unresolved = <ProviderException>[];
  Future<SourceResult?> attempt(SongCandidate candidate) async {
    cancel?.throwIfCancelled();
    if (!seen.add(candidate.id) ||
        candidate.metadata['instrumental'] == true ||
        candidate.metadata['hasLyrics'] == false ||
        attempts >= 3) {
      return null;
    }
    attempts++;
    SourceResult result;
    final fetchWatch = Stopwatch()..start();
    report('fetch', 'pending', candidate: candidate);
    try {
      result = await provider.resolve(candidate, cancel: cancel);
    } on ProviderException catch (e) {
      report(
        'fetch',
        'failed',
        code: e.code,
        candidate: candidate,
        elapsedMilliseconds: fetchWatch.elapsedMilliseconds,
      );
      if (e.code == 'unavailable') return null;
      if (e.code == 'extraction_failed') {
        unresolved.add(
          ProviderException(
            e.code,
            '${candidate.id}${e.message.isEmpty ? '' : ' (${e.message})'}',
          ),
        );
        return null;
      }
      rethrow;
    } catch (_) {
      report(
        'fetch',
        'failed',
        code: 'invalid_response',
        candidate: candidate,
        elapsedMilliseconds: fetchWatch.elapsedMilliseconds,
      );
      rethrow;
    }
    report(
      'fetch',
      'completed',
      candidate: result.candidate,
      elapsedMilliseconds: fetchWatch.elapsedMilliseconds,
    );
    report('validate', 'pending', candidate: result.candidate);
    final song = result.candidate,
        historicalText =
            candidate.identity == selection.identity &&
            _selectedHistoricalText(selection, song, provider.definition.id) &&
            song.metadata['resolvedPageId'] == candidate.id &&
            song.metadata['resolvedTitle'] == song.title &&
            song.metadata['copyrightTags'] is List &&
            (song.metadata['copyrightTags'] as List).isNotEmpty,
        strict = sameSong(selection, result.candidate);
    if (song.providerId != provider.definition.id ||
        song.id != candidate.id ||
        (!sameSong(candidate, song) && !historicalText) ||
        (!strict &&
            !sameArrangement(selection, song, provider) &&
            !historicalText)) {
      report(
        'validate',
        'rejected',
        code: 'identity_mismatch',
        candidate: song,
      );
      rejected ??= _matched(result, MatchKind.rejected, 'identity_mismatch');
      return null;
    }
    if (result.body.trim().isEmpty &&
        !result.timingTracks.any((track) => track.raw?.isNotEmpty == true)) {
      report('validate', 'failed', code: 'unavailable', candidate: song);
      return null;
    }
    final scope = song.metadata['identityScope'];
    final exact =
        selection.identity == song.identity &&
        !{
          'composition',
          'arrangement',
          'image',
          'work',
          'historicalText',
        }.contains(scope) &&
        !provider.definition.capabilities.contains('chords');
    final verifiedRecording =
        _sameAlbum(selection, song) &&
        selection.durationSeconds != null &&
        song.durationSeconds != null &&
        (selection.durationSeconds! - song.durationSeconds!).abs() <= 3 &&
        normalizedIdentity(selection.title) == normalizedIdentity(song.title);
    // Artist/title-only APIs cannot establish which recording supplied lyrics.
    final recording =
        provider.definition.id != 'lyricsovh' &&
        !{
          'composition',
          'arrangement',
          'image',
          'work',
          'historicalText',
        }.contains(scope) &&
        (exact || verifiedRecording);
    final matched = _matched(
      result,
      recording ? MatchKind.sameRecording : MatchKind.sameSong,
      recording
          ? 'same_recording'
          : historicalText
          ? 'explicit_historical_work'
          : strict
          ? 'same_song'
          : 'arrangement_requires_agreement',
      extra: !strict && !historicalText
          ? {'requiresLyricsAgreement': true}
          : {},
    );
    if (accept != null && !accept(matched)) {
      report(
        'validate',
        'rejected',
        code: operationPrefix == 'corroboration'
            ? 'incomplete_or_different_lyrics'
            : 'validation_rejected',
        candidate: song,
      );
      return null;
    }
    report('validate', 'completed', candidate: song);
    return matched;
  }

  if (selection.providerId == provider.definition.id) {
    final result = await attempt(selection);
    if (result != null) return result;
    if (provider.definition.id == 'wikisource') {
      if (rejected != null) return rejected!;
      if (unresolved.isNotEmpty) {
        throw ProviderException(
          unresolved.first.code,
          unresolved.map((e) => '${e.code}: ${e.message}').join('; '),
        );
      }
      throw const ProviderException('unavailable');
    }
  }
  final artist = selection.artist.length <= 100
      ? selection.artist
      : selection.artist.substring(0, 100);
  var title = provider.definition.capabilities.contains('chords')
      ? arrangementTitle(selection.title)
      : selection.title;
  if (title.length > 199 - artist.length) {
    title = title.substring(0, 199 - artist.length);
  }
  final searchQuery = '$title $artist';
  final searchWatch = Stopwatch()..start();
  report('search', 'pending', query: searchQuery);
  late final List<SongCandidate> results;
  try {
    results = await provider.search(searchQuery, cancel: cancel);
  } on ProviderException catch (error) {
    report(
      'search',
      'failed',
      code: error.code,
      query: searchQuery,
      elapsedMilliseconds: searchWatch.elapsedMilliseconds,
    );
    rethrow;
  } catch (_) {
    report(
      'search',
      'failed',
      code: 'invalid_response',
      query: searchQuery,
      elapsedMilliseconds: searchWatch.elapsedMilliseconds,
    );
    rethrow;
  }
  final candidates =
      results
          .take(100)
          .where(
            (s) =>
                s.providerId == provider.definition.id &&
                (sameSong(selection, s) ||
                    sameArrangement(selection, s, provider)),
          )
          .toList()
        ..sort((a, b) => _rank(selection, b).compareTo(_rank(selection, a)));
  report(
    'search',
    'completed',
    query: searchQuery,
    resultCount: results.length,
    elapsedMilliseconds: searchWatch.elapsedMilliseconds,
  );
  for (final candidate in candidates) {
    if (attempts >= 3) break;
    final result = await attempt(candidate);
    if (result != null) return result;
  }
  if (rejected != null) return rejected!;
  if (unresolved.isEmpty) throw const ProviderException('unavailable');
  // 'blocked' is rethrown at once (hammering a bot wall helps nobody); layout
  // failures from every attempted candidate are reported together.
  throw ProviderException(
    unresolved.first.code,
    unresolved.map((e) => '${e.code}: ${e.message}').join('; '),
  );
}

/// Shared by the UI and headless device tests; no result is fabricated on failure.
class SourceDiscoveryService {
  SourceDiscoveryService(this._providers, {this.catalogClient});
  final List<LyricsProvider> _providers;
  SourceCatalogClient? catalogClient;
  List<LyricsProvider> get providers =>
      catalogClient?.runtime.providers ?? _providers;
  List<ProviderDefinition> get definitions =>
      providers.map((p) => p.definition).toList();
  Future<List<SongCandidate>> search(
    String query, {
    String providerId = 'genius',
    CancellationToken? cancel,
  }) async {
    final matches = providers.where((p) => p.definition.id == providerId);
    if (matches.isEmpty) throw const ProviderException('not_configured');
    return matches.single.search(query, cancel: cancel);
  }

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
              enabledIds?.contains(p.definition.id) ??
              p.definition.enabledByDefault,
        )
        .toList();
    final results = <SourceResult>[];
    final operationsByProvider = <String, List<ProviderOperation>>{};
    final traceOpen = <String, bool>{};
    final correlationSequence = <String, int>{};
    final providerChecksState = <String, String>{};
    final providerResults = <String, SourceResult>{};
    final providerCodes = <String, String?>{};
    final operationWatches = <String, Stopwatch>{};
    final corroborationOperationIds = <String, String>{};
    var index = 0;
    void publish(
      String providerId,
      String state, {
      String? code,
      SourceResult? result,
      bool preserveCode = false,
    }) {
      // A closed comparison must not receive delayed provider callbacks.
      if (cancel?.isCancelled == true) return;
      if (!preserveCode) providerCodes[providerId] = code;
      onProgress?.call(
        ProviderCheck(
          providerId: providerId,
          state: state,
          code: providerCodes[providerId] == null
              ? null
              : _safeDiagnosticCode(providerCodes[providerId]),
          result: result,
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
        final local =
            providerCancellation[provider.definition.id] ?? CancellationToken();
        cancel?.cancelled.then((_) => local.cancel());
        try {
          final result =
              await findMatchingSource(
                provider,
                selection,
                cancel: local,
                onOperation: (operation) {
                  if (!local.isCancelled) {
                    recordOperation(provider.definition.id, operation);
                  }
                },
              ).timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  local.cancel();
                  throw const ProviderException('timeout');
                },
              );
          local.throwIfCancelled();
          cancel?.throwIfCancelled();
          results.add(result);
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
      List.generate(math.min(3, active.length), (_) => worker()),
    );
    // Chord sources describe arrangements: corroborate their words against the
    // strongest full lyric reference before making them eligible for combining.
    final references =
        results
            .where(
              (r) =>
                  r.matchKind != MatchKind.rejected &&
                  !r.hasChords &&
                  r.body.trim().isNotEmpty &&
                  _words(r.body).toSet().length >= 12,
            )
            .toList()
          ..sort(
            (a, b) => _words(
              b.body,
            ).toSet().length.compareTo(_words(a.body).toSet().length),
          );
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      if (!result.hasChords || result.matchKind == MatchKind.rejected) continue;
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
        if (!_agreement(result.body, references.first.body)) {
          // The first chart may be a truncated or different-lyrics version: try
          // the provider's other candidates against the same reference.
          SourceResult? alternative;
          final owners = active.where(
            (p) => p.definition.id == result.candidate.providerId,
          );
          if (owners.isNotEmpty) {
            final referenceBody = references.first.body;
            // Linked local token: a timeout (or the caller cancelling) must stop
            // the underlying lookup, not just stop waiting for it, so a slow
            // retry cannot keep issuing requests after discover has returned.
            final alternativeCancel = CancellationToken();
            cancel?.cancelled.then((_) => alternativeCancel.cancel());
            try {
              cancel?.throwIfCancelled();
              alternative =
                  await findMatchingSource(
                    owners.first,
                    selection,
                    cancel: alternativeCancel,
                    exclude: {result.candidate.id},
                    operationPrefix: 'corroboration',
                    onOperation: (operation) {
                      if (!alternativeCancel.isCancelled) {
                        recordOperation(owners.first.definition.id, operation);
                      }
                    },
                    accept: (r) =>
                        r.hasChords && _agreement(r.body, referenceBody),
                  ).timeout(
                    alternativeTimeout,
                    onTimeout: () {
                      alternativeCancel.cancel();
                      throw const ProviderException('timeout');
                    },
                  );
              if (alternative.matchKind == MatchKind.rejected ||
                  !alternative.hasChords) {
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
            results[i] = alternative;
            providerResults[alternative.candidate.providerId] = alternative;
            publish(
              alternative.candidate.providerId,
              providerChecksState[alternative.candidate.providerId] ?? 'found',
              result: alternative,
            );
            recordCorroboration(alternative.candidate.providerId, 'completed');
          } else if (_partialAgreement(result.body, references.first.body)) {
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
    for (final provider in active) {
      finalizePending(provider.definition.id, 'failed', 'provider_error');
      traceOpen[provider.definition.id] = false;
    }
    return results;
  }
}

List<String> _words(String body) => normalizedIdentity(
  body
      .replaceAll(RegExp(r'\{[^}\n]*\}'), ' ')
      .replaceAll(RegExp(r'(?<!\\)\[[^\]\n]*\]'), ''),
).split(' ').where((w) => w.isNotEmpty).toList();
bool _agreement(String chart, String reference) {
  final a = _words(chart),
      b = _words(reference),
      aa = a.toSet(),
      bb = b.toSet(),
      common = a.toSet().intersection(b.toSet());
  if (common.length < 12 ||
      common.length / aa.length < .8 ||
      common.length / bb.length < .85) {
    return false;
  }
  Set<String> bigrams(List<String> words) => {
    for (var i = 1; i < words.length; i++) '${words[i - 1]} ${words[i]}',
  };
  final ab = bigrams(a),
      ba = bigrams(b),
      both = bigrams(a).intersection(bigrams(b));
  return ab.isNotEmpty &&
      ba.isNotEmpty &&
      both.length / ab.length >= .65 &&
      both.length / ba.length >= .65;
}

bool _partialAgreement(String chart, String reference) {
  final words = _words(chart), referenceWords = _words(reference);
  final unique = words.toSet(), referenceUnique = referenceWords.toSet();
  final common = unique.intersection(referenceUnique);
  if (common.length < 12 || common.length / unique.length < .90) return false;
  Set<String> bigrams(List<String> values) => {
    for (var i = 1; i < values.length; i++) '${values[i - 1]} ${values[i]}',
  };
  final pairs = bigrams(words);
  return pairs.isNotEmpty &&
      pairs.intersection(bigrams(referenceWords)).length / pairs.length >= .75;
}
