import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/evidence_ranking.dart';

EvidenceClaim claim(
  String field,
  Object value,
  String source,
  String provider, {
  String? lineage,
  EvidenceMatchQuality match = EvidenceMatchQuality.sameRecording,
  EvidenceSourceScope scope = EvidenceSourceScope.recording,
  EvidenceOrigin origin = EvidenceOrigin.provider,
  EvidenceHarmonyFit harmony = EvidenceHarmonyFit.neutral,
  bool compatible = true,
  Map<String, int> qualitySignals = const {},
  String? equivalenceKey,
}) => EvidenceClaim(
  field: field,
  value: value,
  sourceId: source,
  providerId: provider,
  lineageId: lineage,
  matchQuality: match,
  sourceScope: scope,
  origin: origin,
  harmonyFit: harmony,
  contextCompatible: compatible,
  qualitySignals: qualitySignals,
  equivalenceKey: equivalenceKey,
);

void main() {
  test('alternative hypotheses cannot manufacture independent votes', () {
    final declaration = claim('key', 'A', 'explicit', 'provider');
    final alternatives = [
      for (var i = 0; i < 8; i++)
        EvidenceClaim(
          field: 'key',
          value: 'E',
          sourceId: 'hypothesis-$i',
          providerId: 'analysis-$i',
          origin: EvidenceOrigin.inferred,
          matchQuality: EvidenceMatchQuality.sameRecording,
          sourceScope: EvidenceSourceScope.recording,
          supportsCorroboration: false,
        ),
    ];
    final result = rankEvidenceClaims([declaration, ...alternatives]);
    expect(result.chosenByField['key']!.value, 'A');
    expect(
      result.claims
          .where((item) => item.claim.value == 'E')
          .every((item) => item.components['corroboration'] == 0),
      isTrue,
    );
  });

  test(
    'same valued sources stay distinct when compatibility uses identity',
    () {
      final a = claim('lyrics', 'same text', 'a', 'pa');
      final b = claim('lyrics', 'same text', 'b', 'pb');
      final chart = claim('chart', 'chart', 'b', 'pb');
      final result = rankEvidenceClaims(
        [a, b, chart],
        compatibleWithChosen: (candidate, chosen) => chosen.every(
          (other) =>
              candidate.field == other.field ||
              candidate.sourceId == other.sourceId,
        ),
      );
      expect(result.chosenByField['lyrics']!.sourceId, 'b');
      expect(result.chosenByField['chart']!.sourceId, 'b');
    },
  );

  test('ranking and winner are stable under input permutation', () {
    final a = claim('lyrics', 'Verse A', 'source-a', 'provider-a');
    final b = claim('lyrics', 'Verse B', 'source-b', 'provider-b');
    final forward = rankEvidenceClaims([a, b]);
    final reverse = rankEvidenceClaims([b, a]);
    expect(
      forward.chosenByField['lyrics']!.value,
      reverse.chosenByField['lyrics']!.value,
    );
    expect(
      forward.claims.map((c) => c.claim.sourceId),
      reverse.claims.map((c) => c.claim.sourceId),
    );
  });

  test(
    'distinct providers corroborate while provider and copied lineage count once',
    () {
      final claims = [
        claim('key', 'G', 'a', 'provider-a', lineage: 'copy-x'),
        claim('key', 'G', 'a2', 'provider-a', lineage: 'copy-y'),
        claim('key', 'G', 'b', 'provider-b', lineage: 'copy-x'),
        claim('key', 'G', 'c', 'provider-c', lineage: 'independent'),
      ];
      final result = rankEvidenceClaims(claims);
      expect(result.claims.first.components['corroboration'], 6);
    },
  );

  test(
    'canonical JSON and explicit equivalence keys normalize claim values',
    () {
      final first = claim(
        'metadata',
        {'artist': 'Ada', 'title': 'Song'},
        'a',
        'p1',
      );
      final reordered = claim(
        'metadata',
        {'title': 'Song', 'artist': 'Ada'},
        'b',
        'p2',
      );
      final enharmonic = claim(
        'key',
        'C#',
        'sharp',
        'p1',
        equivalenceKey: 'Db',
      );
      final flat = claim('key', 'Db', 'flat', 'p2', equivalenceKey: 'Db');
      expect(first.normalizedValue, reordered.normalizedValue);
      final result = rankEvidenceClaims([first, reordered, enharmonic, flat]);
      expect(result.ambiguousFields, isEmpty);
      expect(
        result.claims
            .firstWhere((c) => c.claim.field == 'key')
            .components['corroboration'],
        6,
      );
    },
  );

  test('rejected and context-incompatible claims do not corroborate', () {
    final result = rankEvidenceClaims([
      claim('key', 'G', 'valid', 'p1'),
      claim('key', 'G', 'rejected', 'p2', match: EvidenceMatchQuality.rejected),
      claim('key', 'G', 'other-context', 'p3', compatible: false),
    ]);
    expect(
      result.claims
          .firstWhere((c) => c.claim.sourceId == 'valid')
          .components['corroboration'],
      0,
    );
  });

  test('corroborating same-value ties are not ambiguous', () {
    final result = rankEvidenceClaims([
      claim('artist', 'Ada', 'a', 'p1'),
      claim('artist', 'Ada', 'b', 'p2'),
    ]);
    expect(result.ambiguousFields, isEmpty);
  });

  test(
    'incompatible equal-score values do not make the chosen field ambiguous',
    () {
      final result = rankEvidenceClaims([
        claim('key', 'D', 'd', 'p1'),
        claim('key', 'E', 'e', 'p2'),
      ], compatibleWithChosen: (candidate, _) => candidate.value == 'D');
      expect(result.chosenByField['key']!.value, 'D');
      expect(result.ambiguousFields, isEmpty);
    },
  );

  test('harmonic fit can resolve conflicting key evidence', () {
    final result = rankEvidenceClaims([
      claim('key', 'C', 'c', 'p1', harmony: EvidenceHarmonyFit.conflicting),
      claim('key', 'G', 'g', 'p2', harmony: EvidenceHarmonyFit.fitting),
    ]);
    expect(result.chosenByField['key']!.value, 'G');
    expect(result.alternativesByField['key'], hasLength(1));
  });

  test(
    'uncontested source-supported claim wins without a certification gate',
    () {
      final source = claim(
        'artist',
        'Ada',
        'primary',
        'catalog',
        origin: EvidenceOrigin.primarySource,
      );
      final result = rankEvidenceClaims([source]);
      expect(result.chosenByField['artist']!.value, 'Ada');
      expect(result.claims.single.score, greaterThan(0));
    },
  );

  test(
    'bounded quality signals distinguish completeness without dominating identity',
    () {
      final result = rankEvidenceClaims([
        claim(
          'lyrics',
          'short',
          'short',
          'p1',
          qualitySignals: {'completeness': 2},
        ),
        claim(
          'lyrics',
          'complete',
          'complete',
          'p2',
          qualitySignals: {'completeness': 12},
        ),
      ]);
      expect(result.chosenByField['lyrics']!.value, 'complete');
      expect(result.claims.first.components['qualitySignals'], 12);
    },
  );

  test('exact ties retain a deterministic winner and report ambiguity', () {
    final result = rankEvidenceClaims([
      claim('key', 'E', 'z', 'z-provider'),
      claim('key', 'D', 'a', 'a-provider'),
    ]);
    expect(result.chosenByField['key']!.sourceId, 'a');
    expect(result.ambiguousFields, contains('key'));
    expect(result.alternativesByField['key'], hasLength(1));
    expect(result.claims, hasLength(2));
  });

  test(
    'blank claims are omitted and incompatible claims remain alternatives',
    () {
      final result = rankEvidenceClaims([
        claim('key', ' ', 'blank', 'p0'),
        claim('key', 'E', 'wrong-context', 'p1', compatible: false),
        claim('key', 'A', 'current-context', 'p2'),
      ]);
      expect(result.claims, hasLength(2));
      expect(result.chosenByField['key']!.value, 'A');
      expect(
        result.alternativesByField['key']!.map((c) => c.value),
        contains('E'),
      );
    },
  );

  test(
    'compatible combination filters selection without discarding claims',
    () {
      final root = claim('recording', 'album', 'album', 'p1');
      final lyricsAlbum = claim('lyrics', 'album text', 'la', 'p2');
      final lyricsSingle = claim('lyrics', 'single text', 'ls', 'p3');
      final result = rankEvidenceClaims(
        [root, lyricsAlbum, lyricsSingle],
        compatibleWithChosen: (candidate, chosen) =>
            candidate.field != 'lyrics' ||
            !chosen.any((c) => c.field == 'recording') ||
            candidate.value == 'album text',
      );
      expect(result.chosenByField['lyrics']!.value, 'album text');
      expect(result.claims, hasLength(3));
    },
  );

  test('beam search picks the best total compatible combination', () {
    final strongIncompatibleLyrics = claim(
      'lyrics',
      'lyrics A',
      'la',
      'pa',
      origin: EvidenceOrigin.primarySource,
    );
    final weakerCompatibleLyrics = claim(
      'lyrics',
      'lyrics B',
      'lb',
      'pb',
      match: EvidenceMatchQuality.sameSong,
      scope: EvidenceSourceScope.song,
    );
    final chart = claim(
      'chart',
      'chart B',
      'cb',
      'pc',
      origin: EvidenceOrigin.primarySource,
    );
    bool compatible(EvidenceClaim candidate, List<EvidenceClaim> selected) {
      if (candidate.field == 'chart') {
        return !selected.any((c) => c.field == 'lyrics') ||
            selected.any((c) => c.field == 'lyrics' && c.value == 'lyrics B');
      }
      return !selected.any((c) => c.field == 'chart') ||
          candidate.value == 'lyrics B';
    }

    final forward = rankEvidenceClaims([
      strongIncompatibleLyrics,
      weakerCompatibleLyrics,
      chart,
    ], compatibleWithChosen: compatible);
    final reverse = rankEvidenceClaims([
      chart,
      weakerCompatibleLyrics,
      strongIncompatibleLyrics,
    ], compatibleWithChosen: compatible);
    expect(forward.selectedPerField['lyrics']!.value, 'lyrics B');
    expect(forward.selectedPerField['chart']!.value, 'chart B');
    expect(forward.totalScore, reverse.totalScore);
    expect(
      forward.claims.map((c) => c.claim.sourceId),
      reverse.claims.map((c) => c.claim.sourceId),
    );
    expect(forward.claims, hasLength(3));
  });
}
