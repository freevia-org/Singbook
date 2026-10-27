import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'arrangement.dart' show lyricLines, parseArrangement;
import 'evidence_ranking.dart';
import 'models.dart';

typedef EvidenceQualitySignals =
    Map<String, int> Function(SourceResult source, String field);
typedef EvidenceKeyFit =
    EvidenceHarmonyFit Function(
      SourceResult source,
      String field,
      Object value,
    );

/// Collects source claims without deciding which source is suitable for a
/// particular merge. Incompatible claims stay in the returned ledger so the
/// caller can explain why they were not selected.
List<EvidenceClaim> collectSourceEvidence(
  SongCandidate selected,
  List<SourceResult> sources, {
  required bool Function(SourceResult source, String field) compatible,
  bool Function(SourceResult source)? sameRecording,
  EvidenceQualitySignals? qualitySignals,
  EvidenceKeyFit? keyFit,
  EvidenceOrigin Function(SourceResult source, String field)? sourceOrigin,
  EvidenceSourceScope Function(SourceResult source, String field)? sourceScope,
  String? Function(SourceResult source)? sourceLineage,
  String? preferredSourceId,
}) {
  final claims = <EvidenceClaim>[];

  EvidenceMatchQuality matchQuality(MatchKind kind) => switch (kind) {
    MatchKind.rejected => EvidenceMatchQuality.rejected,
    MatchKind.unverified => EvidenceMatchQuality.unverified,
    MatchKind.sameSong => EvidenceMatchQuality.sameSong,
    MatchKind.sameRecording => EvidenceMatchQuality.sameRecording,
  };

  bool compositionScoped(SourceResult source, String field) =>
      [source.candidate.metadata, source.metadata, source.extra].any(
        (metadata) =>
            metadata['identityScope'] == 'composition' ||
            field == 'metadata.key' &&
                source.candidate.providerId == 'wikidata' &&
                metadata['keyAssertions'] is List &&
                (metadata['keyAssertions'] as List).whereType<Map>().any(
                  (assertion) =>
                      jsonMap(
                        jsonMap(assertion['statement'])['mainsnak'],
                      )['property'] ==
                      'P826',
                ),
      );

  EvidenceSourceScope scopeOf(SourceResult source, String field) =>
      sourceScope?.call(source, field) ??
      (compositionScoped(source, field)
          ? EvidenceSourceScope.composition
          : (field == 'chords' ||
                    const {
                      'metadata.key',
                      'metadata.capo',
                      'metadata.tuning',
                      'metadata.timeSignature',
                    }.contains(field)
                ? EvidenceSourceScope.arrangement
                : (sameRecording?.call(source) ??
                      source.matchKind == MatchKind.sameRecording)
                ? EvidenceSourceScope.recording
                : EvidenceSourceScope.song));
  EvidenceOrigin originOf(SourceResult source, String field) =>
      source.id == preferredSourceId
      ? EvidenceOrigin.userProvided
      : sourceOrigin?.call(source, field) ?? EvidenceOrigin.provider;

  bool present(Object? value) =>
      value != null &&
      (value is! String || value.trim().isNotEmpty) &&
      (value is! Iterable || value.isNotEmpty) &&
      (value is! Map || value.isNotEmpty);

  void emit({
    required String field,
    required Object? value,
    required String sourceId,
    required String providerId,
    required EvidenceMatchQuality match,
    required EvidenceSourceScope scope,
    required EvidenceOrigin origin,
    required String? lineage,
    required bool contextCompatible,
    required EvidenceHarmonyFit harmony,
    Map<String, int> signals = const {},
    String? contextId,
    String? incompatibilityReason,
  }) {
    if (!present(value)) return;
    claims.add(
      EvidenceClaim(
        field: field,
        value: value!,
        sourceId: sourceId,
        providerId: providerId,
        lineageId: lineage,
        matchQuality: match,
        sourceScope: scope,
        origin: origin,
        harmonyFit: harmony,
        contextId: contextId,
        contextCompatible: contextCompatible,
        incompatibilityReason: incompatibilityReason,
        qualitySignals: Map.unmodifiable(signals),
      ),
    );
  }

  void metadataClaims({
    required SourceResult source,
    required JsonMap values,
    required String prefix,
    required bool resolved,
    required Iterable<JsonMap> contextMaps,
  }) {
    final lineage = sourceLineage?.call(source);
    void visit(String path, Object? value) {
      if (!present(value)) return;
      if (path == '$prefix.keys' && value is List) {
        for (final key in value.whereType<String>().toSet()) {
          visit('$prefix.key', key);
        }
      }
      if (value is Map) {
        final keys = value.keys.whereType<String>().toList()..sort();
        for (final key in keys) {
          visit('$path.$key', value[key]);
        }
        return;
      }
      final isCompatible = compatible(source, path);
      final signals = <String, int>{
        if (qualitySignals != null) ...qualitySignals(source, path),
        if (resolved) 'resolvedClaim': 2,
      };
      if (path == '$prefix.key') {
        final statementRanks = <int>[];
        final assertions = values['keyAssertions'];
        if (assertions is List) {
          for (final raw in assertions) {
            final assertion = jsonMap(raw);
            if (assertion['normalizedKey'] != value) continue;
            statementRanks.add(switch (jsonMap(
              assertion['statement'],
            )['rank']) {
              'deprecated' => -20,
              'preferred' => 3,
              _ => 0,
            });
          }
        }
        if (statementRanks.isNotEmpty) {
          signals['statementRank'] = statementRanks.reduce(
            (a, b) => a > b ? a : b,
          );
        }
      }
      emit(
        field: path,
        value: value,
        sourceId: source.id,
        providerId: source.candidate.providerId,
        match: matchQuality(source.matchKind),
        scope: scopeOf(source, path),
        origin: originOf(source, path),
        lineage: lineage,
        contextCompatible: isCompatible,
        harmony: path == 'metadata.key' || path.endsWith('.key')
            ? (keyFit?.call(source, path, value!) ?? EvidenceHarmonyFit.neutral)
            : EvidenceHarmonyFit.neutral,
        signals: signals,
        contextId: source.extra['contextId'] is String
            ? source.extra['contextId'] as String
            : null,
        incompatibilityReason: isCompatible ? null : 'context_incompatible',
      );
    }

    for (final entry in values.entries) {
      visit('$prefix.${entry.key}', entry.value);
    }
  }

  // The selected catalog candidate is evidence too, even when no provider
  // returned a corresponding SourceResult.
  final selectedResult = SourceResult(
    candidate: selected,
    body: '',
    matchKind: MatchKind.sameRecording,
  );
  final selectedMaps = [selected.metadata, selected.extra];
  final selectedMetadata = <String, dynamic>{
    ...selected.metadata,
    if (selected.album != null) 'album': selected.album,
    if (selected.durationSeconds != null)
      'durationSeconds': selected.durationSeconds,
  };
  metadataClaims(
    source: selectedResult,
    values: selectedMetadata,
    prefix: 'metadata',
    resolved: false,
    contextMaps: selectedMaps,
  );

  for (final source in sources) {
    final maps = [
      source.candidate.metadata,
      source.candidate.extra,
      source.metadata,
      source.extra,
    ];
    final lineage = sourceLineage?.call(source);
    final recordingMatch =
        sameRecording?.call(source) ??
        source.matchKind == MatchKind.sameRecording;
    final match = recordingMatch
        ? EvidenceMatchQuality.sameRecording
        : matchQuality(source.matchKind);
    final lyricText = lyricLines(source.body)
        .map(
          (line) => line
              .toLowerCase()
              .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
              .trim(),
        )
        .where((line) => line.isNotEmpty)
        .toList();
    if (lyricText.isNotEmpty) {
      final value = sha256.convert(utf8.encode(lyricText.join(' '))).toString();
      final isCompatible = compatible(source, 'lyrics');
      emit(
        field: 'lyrics',
        value: value,
        sourceId: source.id,
        providerId: source.candidate.providerId,
        match: match,
        scope: scopeOf(source, 'lyrics'),
        origin: originOf(source, 'lyrics'),
        lineage: lineage,
        contextCompatible: isCompatible,
        harmony: EvidenceHarmonyFit.neutral,
        contextId: source.extra['contextId'] is String
            ? source.extra['contextId'] as String
            : null,
        incompatibilityReason: isCompatible ? null : 'context_incompatible',
        signals: qualitySignals?.call(source, 'lyrics') ?? const {},
      );
    }
    final arrangement = parseArrangement(source.body);
    final anchors = [
      for (final line in arrangement)
        if (line.chords.isNotEmpty)
          {
            'lyrics': line.text
                .toLowerCase()
                .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
                .trim(),
            'chords': [
              for (final chord in line.chords) [chord.offset, chord.chord],
            ],
          },
    ];
    if (anchors.isNotEmpty) {
      final value = sha256.convert(utf8.encode(jsonEncode(anchors))).toString();
      final isCompatible = compatible(source, 'chords');
      emit(
        field: 'chords',
        value: value,
        sourceId: source.id,
        providerId: source.candidate.providerId,
        match: match,
        scope: scopeOf(source, 'chords'),
        origin: originOf(source, 'chords'),
        lineage: lineage,
        contextCompatible: isCompatible,
        harmony: EvidenceHarmonyFit.neutral,
        contextId: source.extra['contextId'] is String
            ? source.extra['contextId'] as String
            : null,
        incompatibilityReason: isCompatible ? null : 'context_incompatible',
        signals: qualitySignals?.call(source, 'chords') ?? const {},
      );
    }

    final candidateFacts = <String, dynamic>{
      ...source.candidate.metadata,
      if (source.candidate.album != null) 'album': source.candidate.album,
      if (source.candidate.durationSeconds != null)
        'durationSeconds': source.candidate.durationSeconds,
    };
    metadataClaims(
      source: source,
      values: candidateFacts,
      prefix: 'metadata',
      resolved: false,
      contextMaps: maps,
    );
    metadataClaims(
      source: source,
      values: source.metadata,
      prefix: 'metadata',
      resolved: true,
      contextMaps: maps,
    );
  }
  return List.unmodifiable(claims);
}
