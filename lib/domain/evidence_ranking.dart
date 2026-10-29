import 'dart:convert';

/// Generic, deterministic ranking for claims gathered from independent sources.
///
/// Claims are never removed from [EvidenceRanking.claims].  The score is an
/// ordering aid, not a probability or an authenticity guarantee.
enum EvidenceMatchQuality { rejected, unverified, sameSong, sameRecording }

enum EvidenceSourceScope { unknown, composition, song, recording, arrangement }

enum EvidenceOrigin { inferred, provider, userProvided, primarySource }

enum EvidenceHarmonyFit { conflicting, neutral, fitting }

class EvidenceClaim {
  final String field;
  final Object value;
  final String sourceId;
  final String providerId;
  final String? lineageId;
  final EvidenceMatchQuality matchQuality;
  final EvidenceSourceScope sourceScope;
  final EvidenceOrigin origin;
  final EvidenceHarmonyFit harmonyFit;
  final String? contextId;
  final bool contextCompatible;

  /// A hypothesis is an option, not an independent assertion by its provider.
  final bool supportsCorroboration;
  final String? incompatibilityReason;

  /// Optional caller-supplied equivalence key, e.g. a normalized lyric hash or
  /// enharmonic key class. When present it controls value grouping and ties.
  final String? equivalenceKey;

  /// Optional task-specific signals, such as bounded completeness or coverage.
  /// Each is clamped and their combined contribution is capped at +/-32.
  final Map<String, int> qualitySignals;

  const EvidenceClaim({
    required this.field,
    required this.value,
    required this.sourceId,
    required this.providerId,
    this.lineageId,
    this.matchQuality = EvidenceMatchQuality.unverified,
    this.sourceScope = EvidenceSourceScope.unknown,
    this.origin = EvidenceOrigin.provider,
    this.harmonyFit = EvidenceHarmonyFit.neutral,
    this.contextId,
    this.contextCompatible = true,
    this.supportsCorroboration = true,
    this.incompatibilityReason,
    this.equivalenceKey,
    this.qualitySignals = const {},
  });

  String get normalizedValue => equivalenceKey?.trim().isNotEmpty == true
      ? equivalenceKey!.trim()
      : _canonicalValue(value);
}

String _canonicalValue(Object value) {
  Object? canonical(Object? item) {
    if (item is Map) {
      final entries = item.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return {
        for (final entry in entries)
          entry.key.toString(): canonical(entry.value),
      };
    }
    if (item is Iterable) return item.map(canonical).toList();
    if (item is DateTime) return item.toUtc().toIso8601String();
    if (item is String || item is num || item is bool || item == null) {
      return item;
    }
    return item.toString();
  }

  try {
    return jsonEncode(canonical(value)).trim();
  } on Object {
    return value.toString().trim();
  }
}

class RankedEvidenceClaim {
  final EvidenceClaim claim;
  final int score;
  final Map<String, int> components;
  final int rank;

  const RankedEvidenceClaim(this.claim, this.score, this.components, this.rank);

  Map<String, Object?> toJson() => {
    'field': claim.field,
    'value': evidenceDiagnosticValue(claim.value),
    'normalizedValue': claim.normalizedValue,
    if (claim.equivalenceKey != null) 'equivalenceKey': claim.equivalenceKey,
    'sourceId': claim.sourceId,
    'providerId': claim.providerId,
    if (claim.lineageId != null) 'lineageId': claim.lineageId,
    'matchQuality': claim.matchQuality.name,
    'sourceScope': claim.sourceScope.name,
    'origin': claim.origin.name,
    'harmonyFit': claim.harmonyFit.name,
    if (claim.contextId != null) 'contextId': claim.contextId,
    'contextCompatible': claim.contextCompatible,
    'supportsCorroboration': claim.supportsCorroboration,
    if (claim.qualitySignals.isNotEmpty) 'qualitySignals': claim.qualitySignals,
    if (claim.incompatibilityReason != null)
      'incompatibilityReason': claim.incompatibilityReason,
    'score': score,
    'components': components,
    'rank': rank,
  };
}

typedef EvidenceCombinationCompatibility =
    bool Function(EvidenceClaim candidate, List<EvidenceClaim> chosen);

class EvidenceRanking {
  /// All nonblank claims in deterministic ranked order, including losers.
  final List<RankedEvidenceClaim> claims;
  final Map<String, EvidenceClaim> chosenByField;

  /// Alias for the winner's claims as one context-compatible combination.
  final Map<String, EvidenceClaim> selectedPerField;
  final Map<String, List<EvidenceClaim>> alternativesByField;
  final Set<String> ambiguousFields;
  final int totalScore;
  final int beamBudget;

  const EvidenceRanking({
    required this.claims,
    required this.chosenByField,
    required this.alternativesByField,
    required this.ambiguousFields,
    required this.totalScore,
    required this.beamBudget,
  }) : selectedPerField = chosenByField;

  Map<String, Object?> toJson() => {
    'claims': claims.map((item) => item.toJson()).toList(),
    'chosenByField': chosenByField.map(
      (key, value) => MapEntry(key, {
        'value': value.value,
        'sourceId': value.sourceId,
        'providerId': value.providerId,
      }),
    ),
    'totalScore': totalScore,
    'beamBudget': beamBudget,
    'ambiguousFields': ambiguousFields.toList()..sort(),
  };
}

/// Rank each field's alternatives and choose the strongest compatible set.
///
/// Stable lexical tie breaks ensure the same input permutation gives the same
/// winner. A tie remains explicitly marked ambiguous and retains alternatives.
/// The beam includes an unset-field branch, so a rejected or sufficiently
/// negative claim can be omitted; callers should map approved partial roots to
/// [EvidenceMatchQuality.sameSong] when those claims should remain selectable.
EvidenceRanking rankEvidenceClaims(
  Iterable<EvidenceClaim> input, {
  EvidenceCombinationCompatibility? compatibleWithChosen,
  int beamBudget = 32,
  Map<String, int> fieldWeights = const {},
  String Function(EvidenceClaim claim)? combinationStateKey,
}) {
  final claims = input
      .where(
        (c) =>
            c.field.trim().isNotEmpty &&
            (c.value is! String || (c.value as String).trim().isNotEmpty) &&
            (c.value is! Iterable || (c.value as Iterable).isNotEmpty) &&
            (c.value is! Map || (c.value as Map).isNotEmpty),
      )
      .toList();
  claims.sort(_claimOrder);
  final byField = <String, List<EvidenceClaim>>{};
  for (final claim in claims) {
    byField.putIfAbsent(claim.field, () => []).add(claim);
  }
  final scores = <EvidenceClaim, int>{};
  final componentsByClaim = <EvidenceClaim, Map<String, int>>{};
  for (final field in byField.keys) {
    for (final claim in byField[field]!) {
      final components = _components(claim, byField[field]!);
      final rawScore = components.values.fold<int>(0, (a, b) => a + b);
      final weight = (fieldWeights[field] ?? 1).clamp(1, 8).toInt();
      if (weight > 1) components['fieldImportance'] = rawScore * (weight - 1);
      componentsByClaim[claim] = components;
      scores[claim] = components.values.fold<int>(0, (a, b) => a + b);
    }
  }

  // Search field combinations globally: a locally weaker claim may make a
  // much stronger combination possible in another field.
  final fields = byField.keys.toList()
    ..sort((a, b) {
      final aTop = byField[a]!
          .map((c) => scores[c]!)
          .fold<int>(-10000, (x, y) => x > y ? x : y);
      final bTop = byField[b]!
          .map((c) => scores[c]!)
          .fold<int>(-10000, (x, y) => x > y ? x : y);
      final byScore = bTop.compareTo(aTop);
      return byScore != 0 ? byScore : a.compareTo(b);
    });
  final budget = beamBudget < 1 ? 1 : beamBudget;
  final stateKeys = <EvidenceClaim, String>{};
  String stateKey(EvidenceClaim claim) => stateKeys.putIfAbsent(
    claim,
    () =>
        combinationStateKey?.call(claim) ??
        jsonEncode([
          claim.normalizedValue,
          _canonicalValue(claim.value),
          claim.sourceId,
          claim.providerId,
          claim.contextId,
          claim.origin.name,
          claim.sourceScope.name,
          claim.matchQuality.name,
          claim.harmonyFit.name,
          claim.lineageId,
          _canonicalValue(claim.qualitySignals),
          claim.supportsCorroboration,
        ]),
  );
  var beam = <_Combination>[_Combination(const {}, 0, stateKey)];
  for (final field in fields) {
    final expanded = <_Combination>[];
    for (final partial in beam) {
      // A field may remain unset if all its evidence belongs to another
      // identity/setup. This preserves a usable partial result.
      expanded.add(partial);
      for (final option in byField[field]!) {
        if (!option.contextCompatible) continue;
        final chosenSoFar = partial.selected.values.toList();
        if (compatibleWithChosen != null &&
            !compatibleWithChosen(option, chosenSoFar)) {
          continue;
        }
        expanded.add(partial.withClaim(field, option, scores[option]!));
      }
    }
    expanded.sort((a, b) => _combinationOrder(a, b));
    final unique = <String, _Combination>{};
    for (final candidate in expanded) {
      unique.putIfAbsent(candidate.signature, () => candidate);
      if (unique.length >= budget) break;
    }
    beam = unique.values.toList();
  }
  beam.sort(_combinationOrder);
  final best = beam.first;
  final chosen = Map<String, EvidenceClaim>.of(best.selected);
  final alternatives = <String, List<EvidenceClaim>>{};
  final ambiguous = <String>{};
  for (final field in fields) {
    final options = byField[field]!;
    final winner = chosen[field];
    if (winner == null) {
      alternatives[field] = List.of(options);
      continue;
    }
    alternatives[field] = options.where((c) => !identical(c, winner)).toList();
    final others = chosen.entries
        .where((entry) => entry.key != field)
        .map((entry) => entry.value)
        .toList();
    final tied = options.any(
      (candidate) =>
          candidate.contextCompatible &&
          candidate.normalizedValue != winner.normalizedValue &&
          scores[candidate] == scores[winner] &&
          (compatibleWithChosen?.call(candidate, others) ?? true),
    );
    if (tied) {
      ambiguous.add(field);
    }
  }

  final ranked = <RankedEvidenceClaim>[];
  for (final field in byField.keys.toList()..sort()) {
    final options = byField[field]!;
    options.sort((a, b) {
      final s = scores[b]!.compareTo(scores[a]!);
      return s != 0 ? s : _claimOrder(a, b);
    });
    for (var i = 0; i < options.length; i++) {
      final c = options[i];
      final components = componentsByClaim[c]!;
      ranked.add(RankedEvidenceClaim(c, scores[c]!, components, i + 1));
    }
  }
  ranked.sort((a, b) {
    final fieldOrder = a.claim.field.compareTo(b.claim.field);
    if (fieldOrder != 0) return fieldOrder;
    return a.rank.compareTo(b.rank);
  });
  return EvidenceRanking(
    claims: List<RankedEvidenceClaim>.unmodifiable(ranked),
    chosenByField: Map<String, EvidenceClaim>.unmodifiable(chosen),
    alternativesByField: Map<String, List<EvidenceClaim>>.unmodifiable({
      for (final entry in alternatives.entries)
        entry.key: List<EvidenceClaim>.unmodifiable(entry.value),
    }),
    ambiguousFields: Set<String>.unmodifiable(ambiguous),
    totalScore: best.score,
    beamBudget: budget,
  );
}

class _Combination {
  final Map<String, EvidenceClaim> selected;
  final int score;
  final String Function(EvidenceClaim claim) stateKey;
  const _Combination(this.selected, this.score, this.stateKey);

  _Combination withClaim(String field, EvidenceClaim claim, int claimScore) =>
      _Combination({...selected, field: claim}, score + claimScore, stateKey);

  String get signature {
    final fields = selected.keys.toList()..sort();
    return jsonEncode([
      for (final field in fields) [field, stateKey(selected[field]!)],
    ]);
  }
}

int _combinationOrder(_Combination a, _Combination b) {
  final score = b.score.compareTo(a.score);
  return score != 0 ? score : a.signature.compareTo(b.signature);
}

Map<String, int> _components(EvidenceClaim c, List<EvidenceClaim> fieldClaims) {
  final equivalent = fieldClaims
      .where(
        (other) =>
            other.normalizedValue == c.normalizedValue &&
            other.contextCompatible &&
            other.supportsCorroboration &&
            other.matchQuality != EvidenceMatchQuality.rejected,
      )
      .toList();
  final seenProviders = <String>{};
  final seenLineages = <String>{};
  var corroboration = 0;
  for (final source in equivalent) {
    final provider = source.providerId.trim();
    final lineage = source.lineageId?.trim();
    if (provider.isEmpty ||
        seenProviders.contains(provider) ||
        (lineage != null &&
            lineage.isNotEmpty &&
            seenLineages.contains(lineage))) {
      continue;
    }
    seenProviders.add(provider);
    if (lineage != null && lineage.isNotEmpty) seenLineages.add(lineage);
    corroboration++;
  }
  return {
    'match': switch (c.matchQuality) {
      EvidenceMatchQuality.rejected => -100,
      EvidenceMatchQuality.unverified => 0,
      EvidenceMatchQuality.sameSong => 20,
      EvidenceMatchQuality.sameRecording => 40,
    },
    'scope': switch (c.sourceScope) {
      EvidenceSourceScope.unknown => 0,
      EvidenceSourceScope.composition => 2,
      EvidenceSourceScope.song => 5,
      EvidenceSourceScope.recording => 10,
      EvidenceSourceScope.arrangement => 5,
    },
    'origin': switch (c.origin) {
      EvidenceOrigin.inferred => -8,
      EvidenceOrigin.provider => 8,
      EvidenceOrigin.userProvided => 32,
      EvidenceOrigin.primarySource => 16,
    },
    'corroboration': corroboration > 1 ? (corroboration - 1) * 6 : 0,
    'harmony': switch (c.harmonyFit) {
      EvidenceHarmonyFit.conflicting => -24,
      EvidenceHarmonyFit.neutral => 0,
      EvidenceHarmonyFit.fitting => 12,
    },
    'context': c.contextCompatible ? 5 : -100,
    'qualitySignals': _qualitySignalScore(c.qualitySignals),
  };
}

int _qualitySignalScore(Map<String, int> signals) {
  var positiveTotal = 0;
  var negativeTotal = 0;
  final keys = signals.keys.toList()..sort();
  for (final key in keys) {
    if (key.trim().isEmpty) continue;
    final value = signals[key]!.clamp(-20, 20).toInt();
    if (value > 0) {
      positiveTotal += value;
    } else {
      negativeTotal += value;
    }
  }
  final total =
      positiveTotal.clamp(0, 32).toInt() + negativeTotal.clamp(-32, 0).toInt();
  return total.clamp(-32, 32).toInt();
}

/// Keeps malformed numeric evidence inspectable in a JSON diagnostic ledger.
Object? evidenceDiagnosticValue(Object? value) {
  if (value is num && !value.isFinite) return value.toString();
  if (value is List) return value.map(evidenceDiagnosticValue).toList();
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): evidenceDiagnosticValue(entry.value),
    };
  }
  return value;
}

int _claimOrder(EvidenceClaim a, EvidenceClaim b) {
  var order = b.contextCompatible.toString().compareTo(
    a.contextCompatible.toString(),
  );
  if (order != 0) return order;
  order = a.normalizedValue.toLowerCase().compareTo(
    b.normalizedValue.toLowerCase(),
  );
  if (order != 0) return order;
  order = a.providerId.compareTo(b.providerId);
  if (order != 0) return order;
  order = a.sourceId.compareTo(b.sourceId);
  if (order != 0) return order;
  return (a.lineageId ?? '').compareTo(b.lineageId ?? '');
}
