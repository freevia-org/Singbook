part of 'combine.dart';

EvidenceClaim _rebuildClaim(
  EvidenceClaim claim, {
  Object? value,
  EvidenceMatchQuality? matchQuality,
  EvidenceHarmonyFit? harmonyFit,
  EvidenceSourceScope? sourceScope,
  String? contextId,
  String? equivalenceKey,
  bool? contextCompatible,
  String? incompatibilityReason,
  Map<String, int>? qualitySignals,
}) => EvidenceClaim(
  field: claim.field,
  value: value ?? claim.value,
  sourceId: claim.sourceId,
  providerId: claim.providerId,
  lineageId: claim.lineageId,
  matchQuality: matchQuality ?? claim.matchQuality,
  sourceScope: sourceScope ?? claim.sourceScope,
  origin: claim.origin,
  harmonyFit: harmonyFit ?? claim.harmonyFit,
  contextId: contextId ?? claim.contextId,
  contextCompatible: contextCompatible ?? claim.contextCompatible,
  supportsCorroboration: claim.supportsCorroboration,
  incompatibilityReason: incompatibilityReason ?? claim.incompatibilityReason,
  equivalenceKey: equivalenceKey ?? claim.equivalenceKey,
  qualitySignals: qualitySignals ?? claim.qualitySignals,
);

class _MergeScoreCache {
  _MergeScoreCache(this.selected);

  /// The selection every cached identity check is made against.
  final SongCandidate selected;
  final _sameRecording = Map<SourceResult, bool>.identity();

  /// [recordingCompatible] with the selection, once per source object.
  bool sameRecording(SourceResult source) => _sameRecording.putIfAbsent(
    source,
    () => recordingCompatible(selected, source),
  );
  final _knownRecordingIds = Map<List<SourceResult>, Set<String>>.identity();

  /// [_collectKnownRecordingIds] for one unmodified list of sources.
  Set<String> knownRecordingIds(List<SourceResult> sources) =>
      _knownRecordingIds.putIfAbsent(
        sources,
        () => _collectKnownRecordingIds(selected, sources, this),
      );
  final _plainLyricLengths = <String, int>{};
  int plainLyricLength(String body) =>
      _plainLyricLengths.putIfAbsent(body, () => plainLyrics(body).length);
  final _lyricLineCounts = <String, int>{};
  int lyricLineCount(String body) =>
      _lyricLineCounts.putIfAbsent(body, () => lyricLines(body).length);
  final _paddedLyrics = <String, String>{};

  /// Normalized lyrics between spaces, for whole-line containment checks.
  String paddedLyrics(String body) =>
      _paddedLyrics.putIfAbsent(body, () => ' ${normalizedLyrics(body)} ');

  /// [declaredKeyFitsChords] using the cached estimate of [chart].
  bool declaredKeyFits(String chart, String declared, Object? capo) {
    final estimate = estimateFor(chart)?.key;
    return estimate == null || _keyDistance(estimate, declared) == _capoOf(capo);
  }

  final _bodyHashes = <String, String>{};
  String bodyHash(String body) =>
      _bodyHashes.putIfAbsent(body, () => _bodyHash(body));
  final _correctedBodies = <SourceResult, String>{};
  String correctedBody(SourceResult source) =>
      _correctedBodies.putIfAbsent(source, () => _keyCorrectedBody(source));
  final _chordHypotheses = <(String, String?), List<ChordKeyEstimate>>{};
  List<ChordKeyEstimate> hypothesesFor(String body, {String? hint}) =>
      _chordHypotheses.putIfAbsent((
        body,
        hint,
      ), () => rankChordKeyCandidates(body, hint: hint));
  final _chartEstimates = <String, ChordKeyEstimate?>{};
  ChordKeyEstimate? estimateFor(String body) =>
      _chartEstimates.putIfAbsent(body, () => estimateChordKey(body));
  final _tonicSupport = <(String, String), bool>{};
  bool supportsTonic(String body, String key) => _tonicSupport.putIfAbsent((
    body,
    key,
  ), () => chartSupportsDeclaredTonic(body, key));
  final _normalizedLyrics = <String, String>{};
  String normalizedLyrics(String body) =>
      _normalizedLyrics.putIfAbsent(body, () => _norm(plainLyrics(body)));
  final _lyricWordCounts = <String, int>{};
  int lyricWordCount(String body) => _lyricWordCounts.putIfAbsent(body, () {
    final text = normalizedLyrics(body);
    var count = 1;
    for (final unit in text.codeUnits) {
      if (unit == 0x20) count++;
    }
    return count;
  });
  final _vocabularies = <String, Set<String>>{};
  Set<String> _vocabulary(String body) => _vocabularies.putIfAbsent(
    body,
    () => normalizedLyrics(
      body,
    ).split(' ').where((word) => word.isNotEmpty).toSet(),
  );
  final _coverageByBodies = <(String, String), double>{};
  double coverage(String reference, String candidate) =>
      _coverageByBodies.putIfAbsent((reference, candidate), () {
        final words = _vocabulary(reference);
        if (words.isEmpty) return 0;
        final available = _vocabulary(candidate);
        return words.where(available.contains).length / words.length;
      });
}

EvidenceRanking _rankSourceCombination(
  SongCandidate selected,
  List<SourceResult> sources, {
  required _MergeScoreCache scores,
  required Set<String> lyricSourceIds,
  required Set<String> chartSourceIds,
  required Set<String> factSourceIds,
  required bool Function(SourceResult) metadataContextMatches,
  String? preferredSourceId,
}) {
  final byId = <String, SourceResult>{};
  final ordered = [...sources]
    ..sort((a, b) {
      final match = a.matchKind.index.compareTo(b.matchKind.index);
      return match != 0
          ? match
          : scores.bodyHash(a.body).compareTo(scores.bodyHash(b.body));
    });
  for (final source in sources) {
    byId.putIfAbsent(source.id, () => source);
  }
  final lyrics = ordered
      .where(
        (s) => lyricSourceIds.contains(s.id) && plainLyrics(s.body).isNotEmpty,
      )
      .toList();
  final charts = ordered
      .where((s) => chartSourceIds.contains(s.id) && s.hasChords)
      .toList();
  final recordingEvidence =
      <({SourceResult source, JsonMap data, String key, bool bound})>[
        for (final source in sources)
          for (final analysis in _recordingAnalyses(source))
            if (analysis['key'] case final String key)
              if (_keyIdentity(key) != null)
                (
                  source: source,
                  data: analysis,
                  key: key,
                  bound: _recordingKeyBound(
                    selected,
                    sources,
                    analysis,
                    scores,
                  ),
                ),
      ];
  // All matching charts remain witnesses even when only one contributes
  // anchors to the saved body. Provider identity deduplicates copied versions.
  final chartKeyLeads = <({String key, String provider})>[
    for (final source in ordered)
      if (factSourceIds.contains(source.id) &&
          source.hasChords &&
          source.extra['hasArrangementViews'] != true &&
          source.extra['recordingArrangement'] is! Map &&
          !source.hasPendingMatchCheck)
        if (scores.hypothesesFor(source.body).firstOrNull case final lead?)
          (
            key: transposeChord(
              lead.key,
              _capoOf(_setupValue(source, selected, 'capo')),
            ),
            provider: source.candidate.providerId,
          ),
  ];
  final references = [...lyrics]
    ..sort((a, b) {
      final recording = (scores.sameRecording(b) ? 1 : 0).compareTo(
        scores.sameRecording(a) ? 1 : 0,
      );
      return recording != 0
          ? recording
          : scores
                .lyricLineCount(b.body)
                .compareTo(scores.lyricLineCount(a.body));
    });
  final reference = references.firstOrNull;
  final displayAlbum =
      selected.album ??
      selected.metadata['album'] ??
      references
          .where((source) => scores.sameRecording(source))
          .map((source) => source.metadata['album'] ?? source.candidate.album)
          .whereType<String>()
          .firstOrNull;
  final maximumWords = lyrics.fold<int>(
    1,
    (n, s) => math.max(n, scores.lyricWordCount(s.body)),
  );
  late final referenceLines = reference == null
      ? const <String>[]
      : lyricLines(
          reference.body,
        ).map(_norm).where((line) => line.isNotEmpty).toList();
  // Which reference lines each chart body contains, whole and in order.
  final referenceLineCoverageByBody = <String, List<bool>>{};
  List<bool> referenceLineCoverage(String body) =>
      referenceLineCoverageByBody.putIfAbsent(body, () {
        final text = scores.paddedLyrics(body);
        return [for (final line in referenceLines) text.contains(' $line ')];
      });
  bool compatible(SourceResult source, String field) {
    if (field == 'lyrics') {
      return lyricSourceIds.contains(source.id) &&
          (preferredSourceId == null || source.id == preferredSourceId);
    }
    if (field == 'chords') {
      return chartSourceIds.contains(source.id) &&
          (preferredSourceId == null || source.id == preferredSourceId);
    }
    if (!field.startsWith('metadata.')) return false;
    final top = field.substring(9).split('.').first;
    if (_rankedControlFields.contains(top)) return false;
    if (_rankedArrangementFields.contains(top) &&
        top != 'key' &&
        !chartSourceIds.contains(source.id) &&
        !lyricSourceIds.contains(source.id)) {
      return false;
    }
    if (source.id == selected.identity) return true;
    if (!factSourceIds.contains(source.id)) return false;
    if (!scores.sameRecording(source) &&
        metadataContextMatches(source)) {
      return top == 'artistCredits';
    }
    if (top == 'artistCredits' &&
        source.candidate.providerId == 'musicbrainz' &&
        !scores.sameRecording(source) &&
        !metadataContextMatches(source)) {
      return false;
    }
    final scope =
        source.metadata['identityScope'] ??
        source.candidate.metadata['identityScope'];
    if (scope == 'image') return false;
    final leaf = field.split('.').last.toLowerCase();
    if ((_rankedRecordingFields.contains(top) ||
            const {
              'isrc',
              'isrcs',
              'recordingid',
              'recordingids',
            }.contains(leaf)) &&
        !scores.sameRecording(source)) {
      return const {'duration', 'durationSeconds'}.contains(top) &&
          selected.recordingIds.isEmpty &&
          displayAlbum is String &&
          _lendsAlbumDisplay(selected, source, displayAlbum);
    }
    return true;
  }

  Map<String, int> quality(SourceResult source, String field) {
    if (field == 'metadata.key' && source.extra['searchEvidenceOnly'] == true) {
      final declared = _setupValue(source, selected, 'key');
      if (declared is String && _keyIdentity(declared) != null) {
        final supporting = chartKeyLeads
            .where((lead) => _keyDistance(lead.key, declared) == 0)
            .map((lead) => lead.provider)
            .toSet()
            .length;
        final contraryConsensus = chartKeyLeads.any(
          (lead) =>
              _keyDistance(lead.key, declared) != 0 &&
              chartKeyLeads
                      .where((other) => _keyDistance(other.key, lead.key) == 0)
                      .map((other) => other.provider)
                      .toSet()
                      .length >=
                  math.max(2, supporting + 1),
        );
        if (contraryConsensus) {
          return const {'unresolvedSearchVsChartConsensus': -8};
        }
      }
    }
    if (const {
      'metadata.duration',
      'metadata.durationSeconds',
    }.contains(field)) {
      final duration = _sourceDuration(source);
      if (duration == null) return const {};
      final peers = ordered
          .where(
            (other) =>
                compatible(other, field) &&
                _sourceDuration(other) != null &&
                (_sourceDuration(other)! - duration).abs() <= 3,
          )
          .map((other) => other.candidate.providerId)
          .toSet()
          .length;
      return {'durationAgreement': (peers - 1) * 6};
    }
    if (field == 'lyrics') {
      final count = scores.lyricWordCount(source.body);
      return {
        'completeness': (12 * count / maximumWords).round(),
        if (reference != null)
          'referenceAgreement':
              (12 * scores.coverage(reference.body, source.body)).round(),
      };
    }
    if (field == 'chords') {
      final peers = charts.where(
        (other) => _compatibleArrangementSetup(source, other, selected),
      );
      final peerCoverage = [
        for (final other in peers) referenceLineCoverage(other.body),
      ];
      var covered = 0;
      for (var line = 0; line < referenceLines.length; line++) {
        if (peerCoverage.any((coverage) => coverage[line])) covered++;
      }
      return {
        if (reference != null)
          'phraseCoverage': (16 * scores.coverage(reference.body, source.body))
              .round(),
        'chartedLines': parseArrangement(
          source.body,
        ).where((line) => line.chords.isNotEmpty).length.clamp(0, 12),
        if (referenceLines.isNotEmpty)
          'compatibleChartCoverage': (16 * covered / referenceLines.length)
              .round(),
        if (source.extra['keyConsensus'] == true) 'sourceKeyAgreement': 6,
        if (source.extra['keyConsensus'] == false)
          'sourceKeyAgreement': source.extra['keyShift'] is int ? -6 : -12,
        if (source.extra['alternatePerformerChart'] == true)
          'alternatePerformerChart': -8,
        if (source.extra['alternatePerformerChart'] == true &&
            reference != null &&
            !contextualChartLyricsMatch(source.body, reference.body))
          'partialLyricSupport': -6,
        if (source.extra['recordingArrangement'] is Map)
          'derivedRecordingSetup':
              jsonMap(source.extra['recordingArrangement'])['recordingScope'] ==
                  'song'
              ? -10
              : -6,
        if (recordingEvidence.any((evidence) => evidence.bound))
          'recordingKeyAgreement':
              recordingEvidence
                  .where((evidence) => evidence.bound)
                  .any(
                    (evidence) => _chartSupportsSoundingKey(
                      source,
                      selected,
                      evidence.key,
                      scores,
                    ),
                  )
              ? 6
              : -8,
        if (!recordingEvidence.any((evidence) => evidence.bound) &&
            recordingEvidence.isNotEmpty)
          'songKeyAgreement':
              recordingEvidence.any(
                (evidence) => _chartSupportsSoundingKey(
                  source,
                  selected,
                  evidence.key,
                  scores,
                ),
              )
              ? 4
              : -4,
      };
    }
    return const {};
  }

  EvidenceHarmonyFit chartFit(SourceResult chart, Object value) {
    if (value is! String || _keyIdentity(value) == null) {
      return EvidenceHarmonyFit.neutral;
    }
    final capo = _capoOf(_setupValue(chart, selected, 'capo'));
    final shapeKey = transposeChord(value, (12 - capo) % 12);
    if (scores.supportsTonic(scores.correctedBody(chart), shapeKey)) {
      return EvidenceHarmonyFit.fitting;
    }
    if (scores.estimateFor(scores.correctedBody(chart)) == null) {
      final hypotheses = scores.hypothesesFor(scores.correctedBody(chart));
      final capo = _capoOf(_setupValue(chart, selected, 'capo'));
      return hypotheses
              .take(3)
              .any(
                (hypothesis) =>
                    _keyDistance(transposeChord(hypothesis.key, capo), value) ==
                    0,
              )
          ? EvidenceHarmonyFit.fitting
          : EvidenceHarmonyFit.neutral;
    }
    return scores.declaredKeyFits(
          scores.correctedBody(chart),
          value,
          _setupValue(chart, selected, 'capo'),
        )
        ? EvidenceHarmonyFit.fitting
        : EvidenceHarmonyFit.conflicting;
  }

  final fitsByKey = <String, EvidenceHarmonyFit>{};
  EvidenceHarmonyFit fit(SourceResult source, String field, Object value) {
    if (charts.isEmpty || value is! String) return EvidenceHarmonyFit.neutral;
    // A declaration may fit one of several available arrangements. Judge it
    // against all of them; pair compatibility binds it to the chosen chart.
    return fitsByKey.putIfAbsent(value, () {
      var allConflict = true;
      for (final chart in charts) {
        final fit = chartFit(chart, value);
        if (fit == EvidenceHarmonyFit.fitting) return fit;
        allConflict &= fit == EvidenceHarmonyFit.conflicting;
      }
      return allConflict
          ? EvidenceHarmonyFit.conflicting
          : EvidenceHarmonyFit.neutral;
    });
  }

  final raw = collectSourceEvidence(
    selected,
    sources,
    compatible: compatible,
    sameRecording: scores.sameRecording,
    sourceOrigin: (source, field) =>
        field == 'metadata.capo' && source.extra['recordingArrangement'] is Map
        ? EvidenceOrigin.inferred
        : EvidenceOrigin.provider,
    qualitySignals: quality,
    keyFit: fit,
    preferredSourceId: preferredSourceId,
  );
  final claims = <EvidenceClaim>[
    for (final claim in raw)
      _rebuildClaim(
        claim,
        matchQuality: byId[claim.sourceId]?.hasPendingMatchCheck == true
            ? EvidenceMatchQuality.unverified
            : claim.field.startsWith('metadata.') &&
                  byId[claim.sourceId]?.extra['searchEvidenceOnly'] == true &&
                  factSourceIds.contains(claim.sourceId) &&
                  (_sameSong(selected, byId[claim.sourceId]!.candidate) ||
                      byId[claim.sourceId]?.extra['searchArrangementMatch'] ==
                          true)
            ? EvidenceMatchQuality.sameSong
            : byId[claim.sourceId]?.matchReason ==
                      'incomplete_or_different_lyrics' &&
                  claim.contextCompatible
            ? EvidenceMatchQuality.sameSong
            : null,
        contextId: const {'lyrics', 'chords'}.contains(claim.field)
            ? claim.sourceId
            : null,
        sourceScope:
            claim.field == 'metadata.key' &&
                claim.sourceScope == EvidenceSourceScope.unknown
            ? EvidenceSourceScope.arrangement
            : null,
        equivalenceKey: claim.field == 'metadata.key'
            ? _keyIdentity(claim.value)
            : null,
        contextCompatible:
            claim.value is num && !(claim.value as num).isFinite ||
                const {
                      'metadata.duration',
                      'metadata.durationSeconds',
                    }.contains(claim.field) &&
                    _validDuration(claim.value) == null
            ? false
            : null,
        incompatibilityReason:
            claim.value is num && !(claim.value as num).isFinite
            ? 'non_finite_numeric_claim'
            : const {
                    'metadata.duration',
                    'metadata.durationSeconds',
                  }.contains(claim.field) &&
                  _validDuration(claim.value) == null
            ? 'invalid_duration_claim'
            : null,
      ),
  ];
  // Keep the published declaration alongside its equivalent in the corrected
  // chart's context. Moving a chart must not leave its old key label active.
  for (var i = 0, count = claims.length; i < count; i++) {
    final claim = claims[i];
    if (claim.field != 'metadata.key' || claim.value is! String) continue;
    final source = byId[claim.sourceId];
    final shift = source?.extra['keyShift'];
    if (source == null || shift is! int || shift % 12 == 0) continue;
    final corrected = declaredKeyAfterShift(
      source.body,
      claim.value as String,
      _setupValue(source, selected, 'capo'),
      shift,
    );
    if (corrected == null || _keyIdentity(corrected) == claim.normalizedValue) {
      continue;
    }
    claims[i] = _rebuildClaim(
      claim,
      contextCompatible: false,
      incompatibilityReason: 'published_key_before_chart_transposition',
    );
    claims.add(
      _rebuildClaim(
        claim,
        value: corrected,
        equivalenceKey: _keyIdentity(corrected),
        harmonyFit: fit(source, claim.field, corrected),
      ),
    );
  }
  // Publishers use both shape-key and sounding-key labels on capo charts.
  // Retain the literal declaration and rank its arithmetic sounding reading
  // as another interpretation of that same source, never as another vote.
  for (var i = 0, count = claims.length; i < count; i++) {
    final claim = claims[i];
    if (claim.field != 'metadata.key' ||
        claim.value is! String ||
        !claim.contextCompatible) {
      continue;
    }
    final source = byId[claim.sourceId];
    if (source == null || !source.hasChords) continue;
    final capo = _capoOf(_setupValue(source, selected, 'capo'));
    if (capo == 0 || _keyIdentity(claim.value) == null) continue;
    final sounding = transposeChord(claim.value as String, capo);
    final lead = scores.hypothesesFor(scores.correctedBody(source)).firstOrNull;
    final shapeSupport =
        lead != null && _keyIdentity(lead.key) == _keyIdentity(claim.value);
    claims.add(
      _rebuildClaim(
        claim,
        value: sounding,
        equivalenceKey: _keyIdentity(sounding),
        contextId: source.id,
        harmonyFit: fit(source, claim.field, sounding),
        qualitySignals: {
          ...claim.qualitySignals,
          'capoShapeInterpretation': shapeSupport ? 4 : -4,
        },
      ),
    );
  }
  // Inferred alternatives are kept separately from every provider declaration.
  // Ambiguity and section changes affect their rank, not their availability.
  for (final source in charts) {
    final measuredHint = jsonMap(source.extra['keyRecording'])['key'];
    final shapeHint =
        measuredHint is String && _keyIdentity(measuredHint) != null
        ? transposeChord(
            measuredHint,
            (12 - _capoOf(_setupValue(source, selected, 'capo'))) % 12,
          )
        : null;
    final hypotheses = scores.hypothesesFor(
      scores.correctedBody(source),
      hint: shapeHint,
    );
    for (final hypothesis in hypotheses) {
      final key = transposeChord(
        hypothesis.key,
        _capoOf(_setupValue(source, selected, 'capo')),
      );
      claims.add(
        EvidenceClaim(
          field: 'metadata.key',
          value: key,
          sourceId: source.id,
          providerId: source.candidate.providerId,
          contextId: source.id,
          equivalenceKey: _keyIdentity(key),
          matchQuality: source.hasPendingMatchCheck
              ? EvidenceMatchQuality.unverified
              : switch (source.matchKind) {
                  MatchKind.sameRecording => EvidenceMatchQuality.sameRecording,
                  MatchKind.sameSong => EvidenceMatchQuality.sameSong,
                  MatchKind.rejected
                      when source.matchReason ==
                          'incomplete_or_different_lyrics' =>
                    EvidenceMatchQuality.sameSong,
                  _ => EvidenceMatchQuality.unverified,
                },
          sourceScope: EvidenceSourceScope.arrangement,
          origin: EvidenceOrigin.inferred,
          supportsCorroboration: hypothesis.rank == 1,
          harmonyFit: fit(source, 'metadata.key', key),
          contextCompatible:
              preferredSourceId == null || source.id == preferredSourceId,
          qualitySignals: {
            'harmonicRank': (12 - hypothesis.rank * 3).clamp(-20, 9),
          },
        ),
      );
    }
    final consensus = source.extra['keyEstimate'];
    if (consensus is String && _keyIdentity(consensus) != null) {
      claims.add(
        EvidenceClaim(
          field: 'metadata.key',
          value: consensus,
          sourceId: source.id,
          providerId: 'chord-consensus',
          lineageId: 'discovery-key-consensus',
          contextId: source.id,
          equivalenceKey: _keyIdentity(consensus),
          matchQuality: EvidenceMatchQuality.sameSong,
          sourceScope: EvidenceSourceScope.arrangement,
          origin: EvidenceOrigin.inferred,
          supportsCorroboration: false,
          qualitySignals: const {'chartCrossCheck': 8},
          contextCompatible:
              preferredSourceId == null || source.id == preferredSourceId,
          harmonyFit: fit(source, 'metadata.key', consensus),
        ),
      );
    }
  }
  final analysed = <String>{};
  for (final observation in recordingEvidence) {
    final source = observation.source;
    final measured = observation.key;
    final ids =
        _listOrEmpty(observation.data['ids']).whereType<String>().toList()
          ..sort();
    final identifierWitness =
        (observation.data['identifierSourceIds'] is List
                ? observation.data['identifierSourceIds'] as List
                : const [])
            .whereType<String>()
            .map((id) => byId[id])
            .whereType<SourceResult>()
            .where((witness) => witness.extra['searchEvidenceOnly'] != true)
            .firstOrNull ??
        source;
    final witnessId = byId.containsKey(identifierWitness.candidate.identity)
        ? identifierWitness.candidate.identity
        : identifierWitness.id;
    if (!analysed.add('$witnessId:$measured:${ids.join(',')}')) continue;
    final supportingMode = <String>{}, opposingMode = <String>{};
    for (final declaration in claims.where(
      (claim) =>
          claim.field == 'metadata.key' &&
          claim.origin != EvidenceOrigin.inferred &&
          claim.providerId != 'recording-key-analysis' &&
          claim.contextCompatible &&
          claim.matchQuality.index >= EvidenceMatchQuality.sameSong.index &&
          claim.value is String &&
          _keyDistance(claim.value as String, measured) == 0 &&
          claim.harmonyFit == EvidenceHarmonyFit.fitting,
    )) {
      final identity =
          byId[declaration.sourceId]?.candidate.identity ??
          declaration.sourceId;
      (_keyIdentity(declaration.value) == _keyIdentity(measured)
              ? supportingMode
              : opposingMode)
          .add(identity);
    }
    final measuredFit = fit(source, 'metadata.key', measured);
    final estimatedCharts = [
      for (final chart in charts)
        if (scores.estimateFor(scores.correctedBody(chart))
            case final estimate?)
          (
            source: chart,
            key: transposeChord(
              estimate.key,
              _capoOf(_setupValue(chart, selected, 'capo')),
            ),
          ),
    ];
    final localTonicOnly =
        measuredFit == EvidenceHarmonyFit.fitting &&
        estimatedCharts.isNotEmpty &&
        estimatedCharts.every((chart) {
          final capo = _capoOf(_setupValue(chart.source, selected, 'capo'));
          return _keyIdentity(chart.key) != _keyIdentity(measured) &&
              !chartSupportsBoundaryTonic(
                scores.correctedBody(chart.source),
                transposeChord(measured, (12 - capo) % 12),
              );
        });
    claims.add(
      EvidenceClaim(
        field: 'metadata.key',
        value: measured,
        sourceId: witnessId,
        providerId: 'recording-key-analysis',
        lineageId: 'recording-analysis:${ids.join(',')}',
        equivalenceKey: _keyIdentity(measured),
        matchQuality: observation.bound
            ? EvidenceMatchQuality.sameRecording
            : EvidenceMatchQuality.sameSong,
        sourceScope: observation.bound
            ? EvidenceSourceScope.recording
            : EvidenceSourceScope.song,
        origin: EvidenceOrigin.provider,
        qualitySignals: {
          'algorithmicModeUncertainty': -12,
          if (localTonicOnly) 'algorithmicLocalTonicOnly': -12,
          'recordingAgreement':
              ((_listOrEmpty(observation.data['ids'])
                              .whereType<String>()
                              .map((id) => id.toUpperCase())
                              .toSet()
                              .length -
                          1) *
                      2)
                  .clamp(0, 6),
          if (opposingMode.length > supportingMode.length)
            'relativeModeConflict': -20,
        },
        contextCompatible:
            (observation.bound || factSourceIds.contains(source.id)) &&
            (preferredSourceId == null || source.id == preferredSourceId),
        harmonyFit: localTonicOnly ? EvidenceHarmonyFit.neutral : measuredFit,
      ),
    );
  }
  // A subdominant chord can support a local tonic without establishing the
  // song's home key. When published assertions actually conflict, use the
  // chosen charts' clear home-key estimates to separate those assertions.
  // Inference alone never creates a counterclaim to an uncontested source.
  final clearChartKeys = <String>[
    for (final chart in charts)
      if (scores.estimateFor(scores.correctedBody(chart)) case final estimate?)
        transposeChord(
          estimate.key,
          _capoOf(_setupValue(chart, selected, 'capo')),
        ),
  ];
  final declarations = claims
      .where(
        (claim) =>
            claim.field == 'metadata.key' &&
            claim.origin != EvidenceOrigin.inferred &&
            claim.contextCompatible &&
            claim.value is String &&
            _keyIdentity(claim.value) != null,
      )
      .toList();
  if (clearChartKeys.isNotEmpty) {
    for (var i = 0; i < claims.length; i++) {
      final claim = claims[i];
      if (!declarations.contains(claim) ||
          !declarations.any(
            (other) =>
                other.sourceId != claim.sourceId &&
                _keyIdentity(other.value) != _keyIdentity(claim.value),
          )) {
        continue;
      }
      // A relative major/minor dispute (C against Am) is a real contest, but
      // a chart estimate of the relative key cannot settle its mode.
      final value = claim.value as String;
      final fit =
          clearChartKeys.any((key) => _keyIdentity(key) == _keyIdentity(value))
          ? 8
          : clearChartKeys.any((key) => _keyDistance(key, value) == 0)
          ? 0
          : -8;
      claims[i] = _rebuildClaim(
        claim,
        qualitySignals: {...claim.qualitySignals, 'contestedHomeKeyFit': fit},
      );
    }
  }
  // The search asks about the same chart many times; its declared key in
  // the corrected chart's context depends only on the chart.
  final declaredKeyBySource = <String, Object?>{};
  bool pairCompatible(EvidenceClaim a, EvidenceClaim b) {
    if (a.field.startsWith('${b.field}.') ||
        b.field.startsWith('${a.field}.')) {
      return false;
    }
    EvidenceClaim? chart;
    EvidenceClaim? lyric;
    if (a.field == 'chords') chart = a;
    if (b.field == 'chords') chart = b;
    if (a.field == 'lyrics') lyric = a;
    if (b.field == 'lyrics') lyric = b;
    if (chart != null && lyric != null) {
      final c = byId[chart.sourceId], l = byId[lyric.sourceId];
      return c != null && l != null && scores.coverage(l.body, c.body) > 0;
    }
    if (chart == null) return true;
    final other = identical(chart, a) ? b : a;
    final source = byId[chart.sourceId];
    if (source == null) return false;
    if (other.field == 'metadata.key') {
      if (other.origin == EvidenceOrigin.inferred && other.contextId != null) {
        return other.contextId == chart.sourceId;
      }
      final declared = declaredKeyBySource.putIfAbsent(chart.sourceId, () {
        final published = _setupValue(source, selected, 'key');
        final shift = source.extra['keyShift'];
        return published is String && shift is int && shift % 12 != 0
            ? declaredKeyAfterShift(
                source.body,
                published,
                _setupValue(source, selected, 'capo'),
                shift,
              )
            : published;
      });
      if (other.value is String) {
        final body = scores.correctedBody(source);
        final hypotheses = scores.hypothesesFor(body);
        if (hypotheses.isEmpty) return true;
        final capo = _capoOf(_setupValue(source, selected, 'capo'));
        final shapeKey = transposeChord(
          other.value as String,
          (12 - capo) % 12,
        );
        final harmonicallyCompatible =
            scores.supportsTonic(body, shapeKey) ||
            hypotheses
                .take(3)
                .any(
                  (hypothesis) => _keyDistance(hypothesis.key, shapeKey) == 0,
                );
        if (!harmonicallyCompatible) return false;
      }
      if (declared is String &&
          !scores.declaredKeyFits(
            scores.correctedBody(source),
            declared,
            _setupValue(source, selected, 'capo'),
          )) {
        return true;
      }
      return declared is! String ||
          other.value is! String ||
          _keyDistance(declared, other.value as String) == 0 ||
          _keyDistance(
                transposeChord(
                  declared,
                  _capoOf(_setupValue(source, selected, 'capo')),
                ),
                other.value as String,
              ) ==
              0;
    }
    if (other.field == 'metadata.capo') {
      return _capoOf(other.value) ==
          _capoOf(_setupValue(source, selected, 'capo'));
    }
    if (other.field == 'metadata.tuning') {
      return _compatibleChartTuning(
        other.value,
        _setupValue(source, selected, 'tuning'),
      );
    }
    if (other.field == 'metadata.timeSignature') {
      final known = _setupValue(source, selected, 'timeSignature');
      return !_hasMetadata(known) ||
          known.toString().trim() == other.value.toString().trim();
    }
    return true;
  }

  return rankEvidenceClaims(
    claims,
    compatibleWithChosen: (candidate, chosen) =>
        chosen.every((other) => pairCompatible(candidate, other)),
    fieldWeights: const {'lyrics': 4, 'chords': 4, 'metadata.key': 2},
    // This compatibility model depends on a claim's value, arrangement context
    // and whether a key is inferred. Equivalent metadata provenance can share
    // one search state without pruning a distinct arrangement option.
    combinationStateKey: (claim) => jsonEncode([
      claim.normalizedValue,
      claim.contextId,
      claim.field == 'metadata.key' && claim.origin == EvidenceOrigin.inferred,
    ]),
  );
}

void _applyRankedMetadata(SongDocument song, EvidenceRanking ranking) {
  final origins = jsonMap(song.extra['fieldOrigins']);
  final contributors = jsonMap(song.extra['fieldContributors']);
  final decisions = <String, dynamic>{};
  final writtenFields = <String>{};
  final conflicts = jsonMap(song.extra['conflicts']);
  final fieldOptions = <String, List<RankedEvidenceClaim>>{};
  for (final option in ranking.claims) {
    if (option.claim.field.startsWith('metadata.') &&
        option.claim.matchQuality != EvidenceMatchQuality.rejected &&
        option.claim.origin != EvidenceOrigin.inferred) {
      fieldOptions.putIfAbsent(option.claim.field, () => []).add(option);
    }
  }
  for (final field in fieldOptions.entries) {
    if (field.value
            .map((option) => option.claim.normalizedValue)
            .toSet()
            .length <
        2) {
      continue;
    }
    final seen = <String>{};
    conflicts[field.key.substring(9)] = [
      for (final option in field.value)
        if (seen.add(
          '${option.claim.sourceId}:${option.claim.normalizedValue}',
        ))
          {
            'sourceId': option.claim.sourceId,
            'value': evidenceDiagnosticValue(option.claim.value),
          },
    ];
  }
  final entries = ranking.chosenByField.entries.toList()
    ..sort((a, b) {
      final keyLast = (a.key == 'metadata.key' ? 1 : 0).compareTo(
        b.key == 'metadata.key' ? 1 : 0,
      );
      return keyLast != 0 ? keyLast : a.key.compareTo(b.key);
    });
  for (final entry in entries) {
    if (!entry.key.startsWith('metadata.')) continue;
    final path = entry.key.substring(9).split('.');
    var claim = entry.value;
    if (entry.key == 'metadata.key' &&
        claim.origin == EvidenceOrigin.inferred) {
      final declaration = ranking.claims
          .where(
            (option) =>
                option.claim.field == entry.key &&
                option.claim.contextCompatible &&
                option.claim.origin != EvidenceOrigin.inferred &&
                option.claim.matchQuality.index >=
                    EvidenceMatchQuality.sameSong.index &&
                option.claim.normalizedValue == claim.normalizedValue,
          )
          .firstOrNull;
      if (declaration != null) claim = declaration.claim;
    }
    if (writtenFields.add(path.first)) contributors.remove(path.first);
    if (path.first == 'key' && claim.origin == EvidenceOrigin.inferred) {
      final shapeKey = transposeChord(
        claim.value.toString(),
        (12 - _capoOf(song.metadata['capo'])) % 12,
      );
      song.extra['chordKeyEstimate'] = {
        'key': shapeKey,
        'bodyHash': _bodyHash(song.body),
        'ranked': true,
      };
      song.metadata.remove('key');
      origins.remove('key');
      contributors.remove('key');
      decisions[entry.key] = {
        'value': claim.value,
        'sourceId': claim.sourceId,
        'inferred': true,
      };
      continue;
    }
    Object value = claim.value;
    final sameValueSources = ranking.claims
        .where(
          (other) =>
              other.claim.field == entry.key &&
              other.claim.contextCompatible &&
              (entry.key != 'metadata.key' ||
                  other.claim.origin != EvidenceOrigin.inferred) &&
              other.claim.normalizedValue == claim.normalizedValue,
        )
        .map((other) => other.claim.sourceId)
        .toSet();
    if (value is List && !_rankedArrangementFields.contains(path.first)) {
      final seen = <String>{};
      value = [
        for (final option in ranking.claims.where(
          (other) =>
              other.claim.field == entry.key && other.claim.contextCompatible,
        ))
          if (option.claim.value is List)
            for (final item in option.claim.value as List)
              if (seen.add(_valueKey(item))) item,
      ];
      sameValueSources.addAll(
        ranking.claims
            .where(
              (other) =>
                  other.claim.field == entry.key &&
                  other.claim.contextCompatible &&
                  other.claim.value is List,
            )
            .map((other) => other.claim.sourceId),
      );
    }
    Map<String, dynamic> target = song.metadata;
    for (final part in path.take(path.length - 1)) {
      final child = jsonMap(target[part]);
      target[part] = child;
      target = child;
    }
    target[path.last] = value;
    origins[path.first] = claim.sourceId;
    contributors[path.first] = {
      ...?((contributors[path.first] as List?)?.whereType<String>()),
      ...sameValueSources,
    }.toList()..sort();
    if (path.first == 'key') {
      song.extra['keySourceIds'] = sameValueSources.toList()..sort();
    }
    decisions[entry.key] = {
      'value': value,
      'sourceId': claim.sourceId,
      'providerId': claim.providerId,
      'origin': claim.origin.name,
      'matchQuality': claim.matchQuality.name,
      'provisional':
          claim.matchQuality == EvidenceMatchQuality.unverified ||
          ranking.ambiguousFields.contains(entry.key),
    };
  }
  song.extra['fieldOrigins'] = origins;
  song.extra['fieldContributors'] = contributors;
  if (conflicts.isNotEmpty) song.extra['conflicts'] = conflicts;
  song.extra['evidenceRanking'] = {
    'version': 1,
    ...ranking.toJson(),
    'appliedFields': decisions,
    'retainedSourceCount': song.sources.length,
  };
}
