part of 'service.dart';

Future<int> _preferredProviderAlternative(
  List<({String body, MatchKind kind})> alternatives,
) => Isolate.run(() {
  var bestIndex = 0;
  for (var index = 1; index < alternatives.length; index++) {
    final best = alternatives[bestIndex];
    final next = alternatives[index];
    if ((next.kind == MatchKind.sameRecording &&
            best.kind != MatchKind.sameRecording) ||
        (next.kind == best.kind &&
            next.body != best.body &&
            preferCompatibleLyrics(best.body, [next.body]) == next.body)) {
      bestIndex = index;
    }
  }
  return bestIndex;
}, debugName: 'singbook-provider-alternatives');

Future<SourceResult> findMatchingSource(
  LyricsProvider provider,
  SongCandidate selection, {
  CancellationToken? cancel,
  // Candidate ids already tried by an earlier pass.
  Set<String> exclude = const {},
  // Extra acceptance test (for example lyrics corroboration). A result that
  // fails it is skipped so the next candidate can be tried.
  FutureOr<bool> Function(SourceResult result)? accept,
  void Function(ProviderOperation operation)? onOperation,
  void Function(SourceResult result)? onAlternative,
  FutureOr<void> Function(SourceResult result)? onCandidate,
  // Only deliberate internal corroboration may explore alternatives to the
  // selected provider's exact row. Ordinary selection never substitutes one.
  bool allowSelectedProviderAlternatives = false,
  // During initial chord discovery, defer later matching rows until the
  // selected chart has been checked against a full lyric reference. That
  // retry path has its own timeout and cancellation scope.
  bool stopAfterFirstChordCandidate = false,
  // Only the deferred, recording-lyric-backed retry may inspect an exact-title
  // chart credited to another performer.
  bool allowAlternatePerformers = false,
  // Reuse bounded search rows when resolved recording metadata adds context.
  List<SongCandidate>? searchedCandidates,
  void Function(List<SongCandidate>)? onSearchCandidates,
  // Only a full resolved recording reference authorizes this discovery pass.
  bool allowContextualArrangements = false,
  String operationPrefix = 'lookup',
  // Candidates resolved from the provider's search before giving up.
  int maxAttempts = 3,
}) async {
  cancel?.throwIfCancelled();
  bool arrangementMatches(SongCandidate candidate) =>
      sameArrangement(selection, candidate, provider) ||
      (allowContextualArrangements &&
          (contextualArrangementCandidate(selection, candidate) ||
              allowAlternatePerformers &&
                  provider.definition.capabilities.contains('chords') &&
                  contextualArrangementCandidate(
                    selection,
                    candidate,
                    allowAlternatePerformers: true,
                  )));
  String? publishedTitleAliasFor(
    SongCandidate selected,
    SongCandidate candidate, {
    JsonMap metadata = const {},
    JsonMap extra = const {},
  }) {
    if (candidate.providerId != provider.definition.id ||
        provider is! PublishedTitleAliasEvidence ||
        !explicitEditionsCompatible(
          selected,
          candidate,
          metadata: metadata,
          extra: extra,
        )) {
      return null;
    }
    final evidence = (provider as PublishedTitleAliasEvidence)
        .publishedTitleAliasForSelection(selected, candidate);
    if (evidence == null || evidence.trim().isEmpty) return null;
    // Compare the publisher's alias temporarily. Keep its canonical candidate
    // unchanged and retain every existing non-title identity constraint.
    final aliasCandidate = SongCandidate(
      providerId: candidate.providerId,
      id: candidate.id,
      title: evidence,
      artist: candidate.artist,
      album: candidate.album,
      durationSeconds: candidate.durationSeconds,
      url: candidate.url,
      metadata: candidate.metadata,
      recordingIds: candidate.recordingIds,
      extra: candidate.extra,
    );
    return sameSong(selected, aliasCandidate) ? evidence : null;
  }

  bool matchesSelectedSong(
    SongCandidate selected,
    SongCandidate candidate, {
    JsonMap metadata = const {},
    JsonMap extra = const {},
  }) =>
      sameSong(selected, candidate) ||
      publishedTitleAliasFor(
            selected,
            candidate,
            metadata: metadata,
            extra: extra,
          ) !=
          null;
  Future<void> observeCandidate(SourceResult result) async {
    if (cancel?.isCancelled == true || onCandidate == null) return;
    try {
      await onCandidate(result);
    } catch (_) {
      // Observation cannot invalidate an already validated provider payload.
    }
  }

  final searchEvidence = <JsonMap>[];
  final rejectedEvidence = <JsonMap>[];
  final unresolvedEvidence = <JsonMap>[];
  final acceptedEvidence = <JsonMap>[];
  JsonMap evidenceSnapshot(SourceResult source) =>
      {...source.toJson()}..remove('discoveryEvidence');
  JsonMap evidenceEnvelope() => {
    'providerId': provider.definition.id,
    'capabilities': provider.definition.capabilities.toList()..sort(),
    'searchCandidates': searchEvidence,
    'rejectedPayloads': rejectedEvidence,
    'unresolvedCandidates': unresolvedEvidence,
    'acceptedPayloads': acceptedEvidence,
  };
  SourceResult withEvidence(SourceResult source) => source.copyWith(
    extra: {...source.extra, 'discoveryEvidence': evidenceEnvelope()},
  );

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
      unresolvedEvidence.add({
        'candidate': selection.toJson(),
        'state': 'failed',
        'code': _safeDiagnosticCode(error.code),
      });
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
      unresolvedEvidence.add({
        'candidate': selection.toJson(),
        'state': 'failed',
        'code': 'invalid_response',
      });
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
      final rejected = _matched(
        result,
        MatchKind.rejected,
        'identity_mismatch',
      );
      rejectedEvidence.add({
        'reason': 'identity_mismatch',
        'payload': evidenceSnapshot(rejected),
      });
      return withEvidence(rejected);
    }
    if (result.metadata.isEmpty) {
      report('validate', 'failed', code: 'unavailable', candidate: song);
      unresolvedEvidence.add({
        'candidate': selection.toJson(),
        'state': 'failed',
        'code': 'unavailable',
      });
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
    acceptedEvidence.add(evidenceSnapshot(matched));
    if (onCandidate != null) await observeCandidate(matched);
    return withEvidence(matched);
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
    final explicitlySelectedChart =
        candidate.identity == selection.identity &&
        selection.providerId == provider.definition.id &&
        provider.definition.capabilities.contains('chords');
    if (!seen.add(candidate.id) ||
        (!explicitlySelectedChart &&
            (candidate.metadata['instrumental'] == true ||
                candidate.metadata['hasLyrics'] == false)) ||
        attempts >= maxAttempts) {
      final reason = exclude.contains(candidate.id)
          ? 'excluded'
          : candidate.metadata['instrumental'] == true
          ? 'instrumental'
          : candidate.metadata['hasLyrics'] == false
          ? 'lyrics_unavailable'
          : attempts >= maxAttempts
          ? 'attempt_limit'
          : 'duplicate';
      unresolvedEvidence.add({
        'candidate': candidate.toJson(),
        'state': 'skipped',
        'reason': reason,
      });
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
      unresolvedEvidence.add({
        'candidate': candidate.toJson(),
        'state': 'failed',
        'code': _safeDiagnosticCode(e.code),
      });
      if (e.code == 'unavailable') {
        return null;
      }
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
      unresolvedEvidence.add({
        'candidate': candidate.toJson(),
        'state': 'failed',
        'code': 'invalid_response',
      });
      // A page that breaks its parser is one unreadable candidate, like an
      // `invalid_response`: the provider's other candidates are still tried.
      unresolved.add(ProviderException('invalid_response', candidate.id));
      return null;
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
        strict = matchesSelectedSong(
          selection,
          result.candidate,
          metadata: result.metadata,
          extra: result.extra,
        ),
        publishedAlias = publishedTitleAliasFor(
          selection,
          result.candidate,
          metadata: result.metadata,
          extra: result.extra,
        );
    if (song.providerId != provider.definition.id ||
        song.id != candidate.id ||
        (!matchesSelectedSong(
              candidate,
              song,
              metadata: result.metadata,
              extra: result.extra,
            ) &&
            !historicalText) ||
        (!strict && !arrangementMatches(song) && !historicalText)) {
      report(
        'validate',
        'rejected',
        code: 'identity_mismatch',
        candidate: song,
      );
      rejected ??= _matched(result, MatchKind.rejected, 'identity_mismatch');
      rejectedEvidence.add({
        'reason': 'identity_mismatch',
        'payload': evidenceSnapshot(
          _matched(result, MatchKind.rejected, 'identity_mismatch'),
        ),
      });
      return null;
    }
    if (result.body.trim().isEmpty &&
        !result.timingTracks.any((track) => track.raw?.isNotEmpty == true)) {
      report('validate', 'failed', code: 'unavailable', candidate: song);
      rejectedEvidence.add({
        'reason': 'unavailable',
        'payload': evidenceSnapshot(result),
      });
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
    final contextualCandidate =
        allowContextualArrangements &&
        (contextualArrangementCandidate(selection, song) ||
            allowAlternatePerformers &&
                provider.definition.capabilities.contains('chords') &&
                contextualArrangementCandidate(
                  selection,
                  song,
                  allowAlternatePerformers: true,
                ));
    final alternatePerformerChart =
        allowAlternatePerformers &&
        provider.definition.capabilities.contains('chords') &&
        !contextualArrangementCandidate(selection, song) &&
        contextualArrangementCandidate(
          selection,
          song,
          allowAlternatePerformers: true,
        );
    // Artist/title-only APIs cannot establish which recording supplied lyrics.
    final recording =
        provider.definition.id != 'lyricsovh' &&
        !alternatePerformerChart &&
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
      extra: {
        if (publishedAlias != null)
          'sourceTitleAliasEvidence': {
            'sourceId': song.id,
            'canonicalTitle': song.title,
            'selectedTitle': selection.title,
            'publishedAlias': publishedAlias,
          },
        if (!strict && !historicalText) ...{
          'requiresLyricsAgreement': true,
          if (reviewedChartArtistCredit(song) case final credit?)
            'artistIdentityEvidence': credit.toJson(),
          if (contextualCandidate) 'requiresRecordingLyricsAgreement': true,
          if (alternatePerformerChart) 'alternatePerformerChart': true,
        },
      },
    );
    final acceptance = accept?.call(matched);
    final accepted = acceptance is Future<bool> ? await acceptance : acceptance;
    cancel?.throwIfCancelled();
    if (accepted == false) {
      rejectedEvidence.add({
        'reason': operationPrefix == 'corroboration'
            ? 'incomplete_or_different_lyrics'
            : 'validation_rejected',
        'payload': evidenceSnapshot(matched),
      });
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
    acceptedEvidence.add(evidenceSnapshot(matched));
    if (onCandidate != null) await observeCandidate(matched);
    return matched;
  }

  if (selection.providerId == provider.definition.id) {
    final result = await attempt(selection);
    if (result != null) return withEvidence(result);
    if (!allowSelectedProviderAlternatives ||
        provider.definition.id == 'wikisource') {
      if (rejected != null) return withEvidence(rejected!);
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
  late List<SongCandidate> results;
  final canReuse =
      searchedCandidates != null &&
      (provider is! ContextualLyricsSearch ||
          (provider as ContextualLyricsSearch).canReuseSearchForSelection(
            selection,
            searchedCandidates,
          ));
  try {
    results = !canReuse
        ? provider is ContextualLyricsSearch
              ? await (provider as ContextualLyricsSearch).searchForSelection(
                  selection,
                  fallbackQuery: searchQuery,
                  cancel: cancel,
                )
              : await provider.search(searchQuery, cancel: cancel)
        : List.unmodifiable(searchedCandidates.take(100));
    cancel?.throwIfCancelled();
    onSearchCandidates?.call(List.unmodifiable(results.take(100)));
    for (final candidate in results) {
      var reason = 'identity_mismatch';
      if (candidate.providerId == provider.definition.id) {
        if (!sameSong(selection, candidate) && !arrangementMatches(candidate)) {
          reason = 'identity_mismatch';
        } else if (candidate.metadata['instrumental'] == true) {
          reason = 'instrumental';
        } else if (candidate.metadata['hasLyrics'] == false) {
          reason = 'lyrics_unavailable';
        } else {
          reason = 'eligible';
        }
      } else {
        reason = 'provider_mismatch';
      }
      searchEvidence.add({
        'candidate': candidate.toJson(),
        'state': 'returned',
        'reason': reason,
      });
    }
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
  // Some providers index only the Latin alias that is explicitly printed
  // beside a non-Latin name. Try that full title-and-artist query once when
  // the primary query found no identity-compatible result. This bounded
  // fallback runs before candidate resolution and keeps the provider's
  // returned candidate unchanged.
  final latinTitleAliases = publishedNameVariants(selection.title);
  final latinArtistAliases = publishedNameVariants(selection.artist);
  final latinTitle = latinTitleAliases.length > 1
      ? latinTitleAliases.last
      : null;
  final latinArtist = latinArtistAliases.length > 1
      ? latinArtistAliases.last
      : null;
  final hasIdentityMatch = results.any(
    (candidate) =>
        candidate.providerId == provider.definition.id &&
        (matchesSelectedSong(selection, candidate) ||
            arrangementMatches(candidate)),
  );
  var usedAliasFallback = false;
  if (provider is! ContextualLyricsSearch &&
      !hasIdentityMatch &&
      latinTitle != null &&
      latinArtist != null) {
    var fallbackTitle = provider.definition.capabilities.contains('chords')
        ? arrangementTitle(latinTitle)
        : latinTitle;
    var fallbackArtist = latinArtist;
    if (fallbackArtist.length > 100) {
      fallbackArtist = fallbackArtist.substring(0, 100);
    }
    if (fallbackTitle.length > 199 - fallbackArtist.length) {
      fallbackTitle = fallbackTitle.substring(0, 199 - fallbackArtist.length);
    }
    final fallbackQuery = '$fallbackTitle $fallbackArtist';
    if (normalizedIdentity(fallbackQuery) != normalizedIdentity(searchQuery)) {
      report(
        'search',
        'completed',
        query: searchQuery,
        resultCount: results.length,
        elapsedMilliseconds: searchWatch.elapsedMilliseconds,
      );
      usedAliasFallback = true;
      final fallbackWatch = Stopwatch()..start();
      report('search', 'pending', query: fallbackQuery);
      try {
        final fallbackResults = await provider.search(
          fallbackQuery,
          cancel: cancel,
        );
        cancel?.throwIfCancelled();
        results = {
          for (final candidate in results) candidate.identity: candidate,
          for (final candidate in fallbackResults)
            candidate.identity: candidate,
        }.values.take(100).toList();
        for (final candidate in fallbackResults.take(100)) {
          final reason = candidate.providerId != provider.definition.id
              ? 'provider_mismatch'
              : !matchesSelectedSong(selection, candidate) &&
                    !arrangementMatches(candidate)
              ? 'identity_mismatch'
              : candidate.metadata['instrumental'] == true
              ? 'instrumental'
              : candidate.metadata['hasLyrics'] == false
              ? 'lyrics_unavailable'
              : 'eligible';
          searchEvidence.add({
            'candidate': candidate.toJson(),
            'state': 'returned',
            'reason': reason,
          });
        }
        onSearchCandidates?.call(List.unmodifiable(results.take(100)));
        report(
          'search',
          'completed',
          query: fallbackQuery,
          resultCount: fallbackResults.length,
          elapsedMilliseconds: fallbackWatch.elapsedMilliseconds,
        );
      } on ProviderException catch (error) {
        cancel?.throwIfCancelled();
        unresolvedEvidence.add({
          'candidate': selection.toJson(),
          'state': 'failed',
          'code': _safeDiagnosticCode(error.code),
        });
        report(
          'search',
          'failed',
          code: error.code,
          query: fallbackQuery,
          elapsedMilliseconds: fallbackWatch.elapsedMilliseconds,
        );
      } catch (_) {
        cancel?.throwIfCancelled();
        unresolvedEvidence.add({
          'candidate': selection.toJson(),
          'state': 'failed',
          'code': 'invalid_response',
        });
        report(
          'search',
          'failed',
          code: 'invalid_response',
          query: fallbackQuery,
          elapsedMilliseconds: fallbackWatch.elapsedMilliseconds,
        );
      }
    }
  }
  final rankedCandidates =
      <({SongCandidate candidate, bool performer, double rank})>[];
  for (final candidate in results.take(100)) {
    if (candidate.providerId != provider.definition.id) continue;
    final selectedSong = matchesSelectedSong(selection, candidate);
    if (!selectedSong && !arrangementMatches(candidate)) continue;
    rankedCandidates.add((
      candidate: candidate,
      performer:
          selectedSong || sameArrangement(selection, candidate, provider),
      rank: _rank(selection, candidate),
    ));
  }
  // Preserve the selected performer's charts within the provider attempt cap.
  rankedCandidates.sort((a, b) {
    if (a.performer != b.performer) return a.performer ? -1 : 1;
    final rank = b.rank.compareTo(a.rank);
    return rank != 0 ? rank : a.candidate.id.compareTo(b.candidate.id);
  });
  final candidates = rankedCandidates.map((entry) => entry.candidate).toList();
  for (final evidence in searchEvidence) {
    final raw = evidence['candidate'];
    if (raw is Map &&
        raw['providerId'] == provider.definition.id &&
        candidates.any((candidate) => candidate.id == raw['id']) &&
        evidence['reason'] == 'eligible') {
      evidence['state'] = 'eligible';
    }
  }
  for (final evidence in searchEvidence) {
    final raw = evidence['candidate'];
    if (evidence['reason'] == 'eligible' &&
        raw is Map &&
        !candidates.any(
          (candidate) =>
              candidate.providerId == raw['providerId'] &&
              candidate.id == raw['id'],
        )) {
      evidence['state'] = 'not_considered';
      evidence['reason'] = 'candidate_window';
    }
  }
  if (!usedAliasFallback) {
    report(
      'search',
      'completed',
      query: searchQuery,
      resultCount: results.length,
      elapsedMilliseconds: searchWatch.elapsedMilliseconds,
    );
  }
  final alternatives = <SourceResult>[];
  String? alternativeFailure;
  for (final candidate in candidates) {
    if (attempts >= maxAttempts) break;
    final evidence = searchEvidence.where((item) {
      final raw = item['candidate'];
      return raw is Map &&
          raw['providerId'] == candidate.providerId &&
          raw['id'] == candidate.id;
    }).firstOrNull;
    if (evidence != null) evidence['state'] = 'attempted';
    SourceResult? result;
    final rejectedBefore = rejectedEvidence.length;
    try {
      result = await attempt(candidate);
    } on ProviderException catch (error) {
      cancel?.throwIfCancelled();
      if (alternatives.isEmpty) rethrow;
      alternativeFailure = _safeDiagnosticCode(error.code);
      break;
    } catch (_) {
      cancel?.throwIfCancelled();
      if (alternatives.isEmpty) rethrow;
      alternativeFailure = 'invalid_response';
      break;
    }
    if (result == null) {
      if (evidence != null && evidence['state'] == 'attempted') {
        evidence['state'] = rejectedEvidence.length > rejectedBefore
            ? 'rejected'
            : 'unavailable';
      }
      continue;
    }
    if (evidence != null) evidence['state'] = 'accepted';
    alternatives.add(result);
    if (stopAfterFirstChordCandidate && !allowSelectedProviderAlternatives) {
      cancel?.throwIfCancelled();
      return withEvidence(result);
    }
  }
  if (attempts >= maxAttempts) {
    for (final evidence in searchEvidence) {
      if (evidence['state'] == 'eligible') evidence['reason'] = 'attempt_limit';
    }
  }
  final best = alternatives.isEmpty
      ? null
      : alternatives.length == 1
      ? alternatives.single
      : alternatives[await _preferredProviderAlternative([
          for (final result in alternatives)
            (body: result.body, kind: result.matchKind),
        ])];
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
    acceptedEvidence
      ..clear()
      ..addAll(alternatives.map(evidenceSnapshot));
    return best.copyWith(
      extra: {
        ...best.extra,
        'discoveryEvidence': evidenceEnvelope(),
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
  if (rejected != null) return withEvidence(rejected!);
  if (unresolved.isEmpty) throw const ProviderException('unavailable');
  // 'blocked' is rethrown at once (hammering a bot wall helps nobody); layout
  // failures from every attempted candidate are reported together.
  throw ProviderException(
    unresolved.first.code,
    unresolved.map((e) => '${e.code}: ${e.message}').join('; '),
  );
}
