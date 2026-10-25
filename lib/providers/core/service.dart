import 'dart:async';
import 'diagnostics.dart';
import 'dart:math' as math;
import '../../domain/arrangement.dart' show transposeBody, transposeChord;
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
import '../../domain/lyric_word_identity.dart';
import '../../domain/models.dart';
import '../../domain/lyrics_variants.dart';
import '../../domain/edition_identity.dart';
import '../provider.dart';
import '../source_catalog_client.dart';
import '../catalog_search.dart';
import 'recording_key.dart';

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

/// Whether a chord site's arrangement may be [selected]'s song. Chord sites
/// may credit only the main artist ("Bob Marley" for "Bob Marley & The
/// Wailers") and drop a leading article ("House of the Rising Sun"); such
/// matches still need their lyrics to agree before they are used.
bool sameArrangement(
  SongCandidate selected,
  SongCandidate result,
  LyricsProvider provider,
) {
  if (!provider.definition.capabilities.contains('chords') ||
      !artistCreditsMatch(selected.artist, result.artist, normalizedIdentity)) {
    return false;
  }
  final a = arrangementTitle(selected.title);
  var b = arrangementTitle(result.title);
  if (a != selected.title) {
    b = b.replaceFirst(RegExp(r'\s+acoustic$', caseSensitive: false), '');
  }
  String key(String title) =>
      _titleKey(title).replaceFirst(RegExp(r'^(?:the|a|an) '), '');
  return key(a) == key(b);
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
  void Function(SourceResult result)? onAlternative,
  void Function(SourceResult result)? onCandidate,
  // Only deliberate internal corroboration may explore alternatives to the
  // selected provider's exact row. Ordinary selection never substitutes one.
  bool allowSelectedProviderAlternatives = false,
  // During initial chord discovery, defer later matching rows until the
  // selected chart has been checked against a full lyric reference. That
  // retry path has its own timeout and cancellation scope.
  bool stopAfterFirstChordCandidate = false,
  String operationPrefix = 'lookup',
  // Candidates resolved from the provider's search before giving up.
  int maxAttempts = 3,
}) async {
  cancel?.throwIfCancelled();
  void observeCandidate(SourceResult result) {
    if (cancel?.isCancelled == true) return;
    try {
      onCandidate?.call(result);
    } catch (_) {
      // Observation cannot invalidate an already validated provider payload.
    }
  }

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
      cancel?.throwIfCancelled();
      report(
        'metadata',
        'completed',
        candidate: result.candidate,
        elapsedMilliseconds: fetchWatch.elapsedMilliseconds,
      );
    } on ProviderException catch (error) {
      cancel?.throwIfCancelled();
      report(
        'metadata',
        'failed',
        code: error.code,
        candidate: selection,
        elapsedMilliseconds: fetchWatch.elapsedMilliseconds,
      );
      rethrow;
    } catch (_) {
      cancel?.throwIfCancelled();
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
        explicitEditionsCompatible(
          selection,
          song,
          metadata: result.metadata,
          extra: result.extra,
        ) &&
        (selection.identity == song.identity ||
            sharedId ||
            _sameAlbum(selection, song) &&
                selection.durationSeconds != null &&
                song.durationSeconds != null &&
                (selection.durationSeconds! - song.durationSeconds!).abs() <=
                    3);
    final matched = _matched(
      result,
      exact ? MatchKind.sameRecording : MatchKind.sameSong,
      exact ? 'same_recording' : 'same_song',
    );
    observeCandidate(matched);
    return matched;
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
        attempts >= maxAttempts) {
      return null;
    }
    attempts++;
    SourceResult result;
    final fetchWatch = Stopwatch()..start();
    report('fetch', 'pending', candidate: candidate);
    try {
      result = await provider.resolve(candidate, cancel: cancel);
      cancel?.throwIfCancelled();
    } on ProviderException catch (e) {
      cancel?.throwIfCancelled();
      report(
        'fetch',
        'failed',
        code: e.code,
        candidate: candidate,
        elapsedMilliseconds: fetchWatch.elapsedMilliseconds,
      );
      if (e.code == 'unavailable') return null;
      // One chart that cannot be read leaves the provider's other candidates
      // to try; all failing still reports why.
      if (e.code == 'extraction_failed' || e.code == 'invalid_response') {
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
      cancel?.throwIfCancelled();
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
        explicitEditionsCompatible(
          selection,
          song,
          metadata: result.metadata,
          extra: result.extra,
        ) &&
        !{
          'composition',
          'arrangement',
          'image',
          'work',
          'historicalText',
        }.contains(scope) &&
        !provider.definition.capabilities.contains('chords');
    final verifiedRecording =
        explicitEditionsCompatible(
          selection,
          song,
          metadata: result.metadata,
          extra: result.extra,
        ) &&
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
    observeCandidate(matched);
    return matched;
  }

  if (selection.providerId == provider.definition.id) {
    final result = await attempt(selection);
    if (result != null) return result;
    if (!allowSelectedProviderAlternatives ||
        provider.definition.id == 'wikisource') {
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
    cancel?.throwIfCancelled();
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
        ..sort((a, b) {
          final rank = _rank(selection, b).compareTo(_rank(selection, a));
          return rank != 0 ? rank : a.id.compareTo(b.id);
        });
  report(
    'search',
    'completed',
    query: searchQuery,
    resultCount: results.length,
    elapsedMilliseconds: searchWatch.elapsedMilliseconds,
  );
  SourceResult? best;
  final alternatives = <SourceResult>[];
  String? alternativeFailure;
  for (final candidate in candidates) {
    if (attempts >= maxAttempts) break;
    SourceResult? result;
    try {
      result = await attempt(candidate);
    } on ProviderException catch (error) {
      cancel?.throwIfCancelled();
      if (best == null) rethrow;
      alternativeFailure = _safeDiagnosticCode(error.code);
      break;
    } catch (_) {
      cancel?.throwIfCancelled();
      if (best == null) rethrow;
      alternativeFailure = 'invalid_response';
      break;
    }
    if (result == null) continue;
    alternatives.add(result);
    if (stopAfterFirstChordCandidate && !allowSelectedProviderAlternatives) {
      cancel?.throwIfCancelled();
      return result;
    }
    if (best == null ||
        (result.matchKind == MatchKind.sameRecording &&
            best.matchKind != MatchKind.sameRecording) ||
        (result.matchKind == best.matchKind &&
            preferCompatibleLyrics(best.body, [result.body]) == result.body &&
            best.body != result.body)) {
      best = result;
    }
  }
  if (best != null) {
    cancel?.throwIfCancelled();
    for (final alternative in alternatives) {
      if (!identical(alternative, best)) {
        try {
          onAlternative?.call(alternative);
        } catch (_) {
          // A consumer may ignore alternatives; it cannot erase the best one.
        }
      }
    }
    return best.copyWith(
      extra: {
        ...best.extra,
        if (alternatives.length > 1)
          'providerAlternatives': [
            for (final alternative in alternatives)
              if (!identical(alternative, best))
                {...alternative.toJson()}..remove('providerAlternatives'),
          ],
        'alternativeLookupFailure': ?alternativeFailure,
      },
    );
  }
  cancel?.throwIfCancelled();
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
  SourceDiscoveryService(
    this._providers, {
    this.catalogClient,
    this.recordingKeys,
  });
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
        void retainCandidate(SourceResult result) {
          if (local.isCancelled || cancel?.isCancelled == true) return;
          final previous = results.indexWhere((item) => item.id == result.id);
          if (previous < 0) {
            results.add(result);
          } else {
            results[previous] = result;
          }
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
          preferredResultIds[provider.definition.id] = result.id;
          for (final alternative in alternatives) {
            retainCandidate(alternative);
          }
          retainCandidate(result);
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
                  providerCancellation[r.candidate.providerId]?.isCancelled !=
                      true &&
                  r.matchKind != MatchKind.rejected &&
                  !r.hasChords &&
                  r.body.trim().isNotEmpty &&
                  _words(r.body).toSet().length >= 12,
            )
            .toList()
          ..sort((a, b) {
            // A longer same-song transcription may be a remix or another
            // performance. Corroborate charts against the selected recording
            // before falling back to unanchored same-song references.
            final recording = (recordingCompatible(selection, b) ? 1 : 0)
                .compareTo(recordingCompatible(selection, a) ? 1 : 0);
            if (recording != 0) return recording;
            final words = _words(
              b.body,
            ).toSet().length.compareTo(_words(a.body).toSet().length);
            return words != 0 ? words : a.id.compareTo(b.id);
          });
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      final providerCancel = providerCancellation[result.candidate.providerId];
      if (providerCancel?.isCancelled == true) continue;
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
            providerCancel?.cancelled.then((_) => alternativeCancel.cancel());
            try {
              cancel?.throwIfCancelled();
              providerCancel?.throwIfCancelled();
              alternative =
                  await findMatchingSource(
                    owners.first,
                    selection,
                    cancel: alternativeCancel,
                    exclude: {result.candidate.id},
                    allowSelectedProviderAlternatives: true,
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
          } else if (_partialAgreement(result.body, references.first.body) ||
              _noisyAgreement(result.body, references.first.body)) {
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
    await _checkChordKeys(
      results,
      active,
      selection,
      reference: references.firstOrNull?.body,
      cancel: cancel,
      providerCancellation: providerCancellation,
      onOperation: recordOperation,
      timeout: alternativeTimeout,
    );
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
    return results;
  }

  /// The key measured from the selected recording's audio, when results
  /// already identified as that recording carry a Spotify link or ISRC.
  /// Failures and missing identifiers give null; cancellation still throws.
  /// [providers] names the providers whose results gave the identifiers.
  Future<({RecordingKey key, Set<String> providers})?> _recordingKey(
    List<SourceResult> results,
    bool Function(String providerId) eligible, {
    CancellationToken? cancel,
  }) async {
    final service = recordingKeys;
    if (service == null) return null;
    final spotify = <String>{}, isrcs = <String>{}, providers = <String>{};
    for (final result in results) {
      if (result.matchKind != MatchKind.sameRecording ||
          !eligible(result.candidate.providerId)) {
        continue;
      }
      final ids = recordingIdentifiers(result);
      if (ids.spotify.isEmpty && ids.isrcs.isEmpty) continue;
      spotify.addAll(ids.spotify);
      isrcs.addAll(ids.isrcs);
      providers.add(result.candidate.providerId);
    }
    if (spotify.isEmpty && isrcs.isEmpty) return null;
    cancel?.throwIfCancelled();
    final lookupCancel = CancellationToken();
    cancel?.cancelled.then((_) => lookupCancel.cancel());
    try {
      final key = await service.lookup(
        spotifyIds: spotify.toList(),
        isrcs: isrcs.toList(),
        cancel: lookupCancel,
      );
      return key == null || !providers.every(eligible)
          ? null
          : (key: key, providers: providers);
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
    String? reference,
    CancellationToken? cancel,
    Map<String, CancellationToken> providerCancellation = const {},
    void Function(String providerId, ProviderOperation operation)? onOperation,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    bool eligible(String providerId) =>
        providerCancellation[providerId]?.isCancelled != true;
    List<int> acceptedIndexes() => [
      for (var i = 0; i < results.length; i++)
        if (results[i].hasChords &&
            results[i].matchKind != MatchKind.rejected &&
            eligible(results[i].candidate.providerId))
          i,
    ];
    final indexes = acceptedIndexes();
    if (indexes.isEmpty) return;
    final charts = [for (final i in indexes) results[i].body];
    Object? setup(SourceResult source, String field) =>
        source.metadata[field] ?? source.candidate.metadata[field];
    final heard = await _recordingKey(results, eligible, cancel: cancel);
    var recording = heard?.key;
    // Doubt: charts in different keys, or a chart whose declared key
    // contradicts its own chords (a transposed chart or a missing capo).
    // Charts are compared by sounding key: the same shapes with a different
    // capo are in different keys.
    final disagree = indexes
        .skip(1)
        .any(
          (i) =>
              (soundingTransposition(
                    results[indexes.first].body,
                    setup(results[indexes.first], 'capo'),
                    results[i].body,
                    setup(results[i], 'capo'),
                  ) ??
                  0) !=
              0,
        );
    final contradicted = indexes.any((i) {
      final source = results[i];
      final declared =
          source.metadata['key'] ?? source.candidate.metadata['key'];
      return declared is String &&
          declared.trim().isNotEmpty &&
          !declaredKeyFitsChords(
            source.body,
            declared.trim(),
            source.metadata['capo'] ?? source.candidate.metadata['capo'],
          );
    });
    // The recording's measured key disagreeing with a chart's chords (beyond
    // a relative major/minor) is doubt as well.
    final measured = heard?.key.key;
    final unheard =
        measured != null &&
        indexes.any((i) {
          final key = soundingChartKey(
            results[i].body,
            setup(results[i], 'capo'),
          );
          return key != null && !keysAgree(key, measured);
        });
    if (!disagree && !contradicted && !unheard) {
      // No doubt to settle; the measured key still helps name a key the
      // chords leave open (a relative major or minor).
      if (heard != null && heard.providers.every(eligible)) {
        for (final i in indexes) {
          results[i] = results[i].copyWith(
            extra: {...results[i].extra, 'keyRecording': heard.key.toJson()},
          );
        }
      }
      return;
    }
    bool lyricsAgree(String body) => reference != null
        ? _agreement(body, reference) ||
              _partialAgreement(body, reference) ||
              _noisyAgreement(body, reference)
        : charts.any(
            (chart) =>
                _agreement(body, chart) || _partialAgreement(body, chart),
          );
    bool canVote(SourceResult result) =>
        result.hasChords &&
        result.matchKind != MatchKind.rejected &&
        explicitEditionsCompatible(
          selection,
          result.candidate,
          metadata: result.metadata,
          extra: result.extra,
        ) &&
        lyricsAgree(result.body);
    final votes = <({String providerId, SourceResult chart})>[];
    for (final provider in active.where(
      (p) => p.definition.capabilities.contains('chords'),
    )) {
      final id = provider.definition.id;
      cancel?.throwIfCancelled();
      if (!eligible(id)) continue;
      final checkCancel = CancellationToken();
      cancel?.cancelled.then((_) => checkCancel.cancel());
      providerCancellation[id]?.cancelled.then((_) => checkCancel.cancel());
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
        if (!eligible(id)) continue;
        for (final chart in [best, ...found]) {
          if (canVote(chart)) votes.add((providerId: id, chart: chart));
        }
      } on ProviderException {
        if (cancel?.isCancelled == true) rethrow;
      } catch (_) {
        cancel?.throwIfCancelled();
        // A failed double check leaves the charts as they were.
      } finally {
        checkCancel.cancel();
      }
    }
    cancel?.throwIfCancelled();
    // Providers cancelled or disabled during the lookups drop out entirely.
    final current = [
      for (final i in acceptedIndexes())
        if (indexes.contains(i)) i,
    ];
    if (current.isEmpty) return;
    final sources = [
      for (final i in current) results[i],
      for (final vote in votes)
        if (eligible(vote.providerId)) vote.chart,
    ];
    // A recording identified only by providers disabled since is no evidence.
    if (heard != null && !heard.providers.every(eligible)) recording = null;
    final all = [for (final source in sources) source.body];
    final outcome = chordKeyVerdict(
      all,
      recordingKey: recording?.key,
      capos: [for (final source in sources) setup(source, 'capo')],
      declaredKeys: [
        for (final source in sources)
          if (setup(source, 'key') case final String key) key else null,
      ],
      // Accepted charts transcribed against the recording settle a key when
      // the other charts show no majority.
      anchors: [
        for (var n = 0; n < sources.length; n++)
          n < current.length &&
              _recordingTranscriptions.contains(
                sources[n].candidate.providerId,
              ),
      ],
    );
    if (outcome == null) return;
    final verdict = outcome.shifts;
    // Estimate the majority key from every chart moved into it; a key is
    // named only when the estimates that do not abstain all agree.
    final estimates = <String>{};
    String? estimate;
    for (var n = 0; n < all.length; n++) {
      final shift = verdict[n];
      if (shift == null) continue;
      final shapes = estimateChordKey(
        shift == 0 ? all[n] : transposeBody(all[n], shift),
      )?.key;
      if (shapes == null) continue;
      // Compare sounding keys: chord shapes plus the chart's capo.
      final capo = setup(sources[n], 'capo');
      final frets = capo is num ? capo.toInt() : int.tryParse('${capo ?? ''}');
      final key = frets == null || frets <= 0
          ? shapes
          : transposeChord(shapes, frets);
      estimate ??= key;
      estimates.add(key);
    }
    // Chord estimates name the mode best; the recording's key fills in when
    // the chords give none and it voted for the winning key.
    final keyEstimate = estimates.length == 1
        ? estimate
        : estimates.isEmpty && outcome.recordingAgrees
        ? recording?.key
        : null;
    for (var n = 0; n < current.length; n++) {
      final shift = verdict[n];
      if (shift == null) continue;
      final i = current[n];
      results[i] = results[i].copyWith(
        extra: {
          ...results[i].extra,
          'keyConsensus': shift == 0,
          'keyShift': ?(shift == 0 ? null : shift),
          'keyCheckCharts': all.length,
          'keyEstimate': ?keyEstimate,
          'keyRecording': ?recording?.toJson(),
        },
      );
    }
  }
}

/// Chord providers whose charts are transcribed against the recording itself
/// (Songsterr's tabs play in sync with the original audio), unlike user
/// arrangements that are often written in a singer's key.
const _recordingTranscriptions = {'songsterr'};

List<String> _words(String body) => normalizedIdentity(
  foldLyricVowelAccents(body)
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

/// A chord chart can carry the whole song among notes that are not lyrics:
/// chords typed as text, tab and strumming notation, links, capo or tuning
/// instructions and commentary. Judge only its lyric-like lines (three or
/// more words, at least 70% of them in the reference): they must cover most
/// of the reference's words in the same order. A different song with the
/// same title has no such lines.
bool _noisyAgreement(String chart, String reference) {
  final referenceWords = _words(reference);
  final vocabulary = referenceWords.toSet();
  if (vocabulary.length < 12) return false;
  final lyricWords = <String>[];
  var lyricLines = 0;
  for (final line in chart.split('\n')) {
    final words = _words(line);
    if (words.length < 3) continue;
    final known = words.where(vocabulary.contains).length;
    if (known / words.length < .7) continue;
    lyricLines++;
    lyricWords.addAll(words);
  }
  if (lyricLines < 4) return false;
  final covered = lyricWords.toSet().intersection(vocabulary);
  if (covered.length / vocabulary.length < .6) return false;
  Set<String> bigrams(List<String> values) => {
    for (var i = 1; i < values.length; i++) '${values[i - 1]} ${values[i]}',
  };
  final pairs = bigrams(lyricWords);
  return pairs.isNotEmpty &&
      pairs.intersection(bigrams(referenceWords)).length / pairs.length >= .75;
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
