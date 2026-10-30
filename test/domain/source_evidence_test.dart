import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/evidence_ranking.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/source_evidence.dart';

SongCandidate _candidate({
  String provider = 'catalog',
  String id = 'song',
  Map<String, dynamic> metadata = const {},
  Map<String, dynamic> extra = const {},
  String? album,
  double? duration,
}) => SongCandidate(
  providerId: provider,
  id: id,
  title: 'Example',
  artist: 'Artist',
  metadata: metadata,
  extra: extra,
  album: album,
  durationSeconds: duration,
);

SourceResult _source({
  required SongCandidate candidate,
  String body = '',
  Map<String, dynamic> metadata = const {},
  Map<String, dynamic> extra = const {},
  MatchKind match = MatchKind.sameSong,
}) => SourceResult(
  candidate: candidate,
  body: body,
  metadata: metadata,
  extra: extra,
  matchKind: match,
);

void main() {
  test(
    'a song record P826 assertion remains composition key evidence only',
    () {
      final source = _source(
        candidate: _candidate(provider: 'wikidata'),
        metadata: {
          'identityScope': 'song',
          'key': 'A',
          'language': 'en',
          'keyAssertions': [
            {
              'normalizedKey': 'A',
              'statement': {
                'rank': 'normal',
                'mainsnak': {'property': 'P826'},
              },
            },
          ],
        },
      );
      final claims = collectSourceEvidence(_candidate(), [
        source,
      ], compatible: (_, _) => true);
      expect(
        claims
            .singleWhere((claim) => claim.field == 'metadata.key')
            .sourceScope,
        EvidenceSourceScope.composition,
      );
      expect(
        claims
            .singleWhere((claim) => claim.field == 'metadata.language')
            .sourceScope,
        EvidenceSourceScope.song,
      );
      expect(
        claims.every((claim) => claim.origin == EvidenceOrigin.provider),
        isTrue,
      );
    },
  );

  test(
    'multiple literal keys retain their composition scope and statement ranks',
    () {
      final source = _source(
        candidate: _candidate(provider: 'wikidata'),
        metadata: {
          'identityScope': 'composition',
          'keys': ['A', 'Ebm', 'F#m'],
          'keyAssertions': [
            {
              'normalizedKey': 'A',
              'statement': {'rank': 'normal'},
            },
            {
              'normalizedKey': 'Ebm',
              'statement': {'rank': 'preferred'},
            },
            {
              'normalizedKey': 'F#m',
              'statement': {'rank': 'deprecated'},
            },
            {
              'label': 'atonality',
              'statement': {'rank': 'normal'},
            },
          ],
        },
      );
      final claims = collectSourceEvidence(
        _candidate(),
        [source],
        compatible: (_, field) => field == 'metadata.key',
        keyFit: (_, _, value) => value == 'F#m'
            ? EvidenceHarmonyFit.fitting
            : EvidenceHarmonyFit.neutral,
      );
      final keys = claims
          .where((claim) => claim.field == 'metadata.key')
          .toList();
      expect(keys.map((claim) => claim.value), ['A', 'Ebm', 'F#m']);
      expect(
        keys.every(
          (claim) => claim.sourceScope == EvidenceSourceScope.composition,
        ),
        isTrue,
      );
      expect(
        keys.every((claim) => claim.origin == EvidenceOrigin.provider),
        isTrue,
      );
      expect(
        keys.every(
          (claim) => claim.matchQuality == EvidenceMatchQuality.sameSong,
        ),
        isTrue,
      );
      expect(keys.every((claim) => claim.contextCompatible), isTrue);
      expect(keys.map((claim) => claim.qualitySignals['statementRank']), [
        0,
        3,
        -20,
      ]);
      expect(keys.last.harmonyFit, EvidenceHarmonyFit.fitting);
      expect(
        claims.singleWhere((claim) => claim.field == 'metadata.keys').value,
        ['A', 'Ebm', 'F#m'],
      );
      expect(
        claims
            .singleWhere((claim) => claim.field == 'metadata.keyAssertions')
            .value,
        source.metadata['keyAssertions'],
      );
    },
  );

  test('a current assertion supersedes a deprecated copy of the same key', () {
    final source = _source(
      candidate: _candidate(provider: 'wikidata'),
      metadata: {
        'identityScope': 'composition',
        'key': 'A',
        'keyAssertions': [
          {
            'normalizedKey': 'A',
            'statement': {'rank': 'deprecated'},
          },
          {
            'normalizedKey': 'A',
            'statement': {'rank': 'normal'},
          },
        ],
      },
    );
    final key = collectSourceEvidence(
      _candidate(),
      [source],
      compatible: (_, _) => true,
    ).singleWhere((claim) => claim.field == 'metadata.key');
    expect(key.qualitySignals['statementRank'], 0);
  });

  test('blank resolved metadata does not erase candidate facts', () {
    final source = _source(
      candidate: _candidate(
        provider: 'lyrics',
        metadata: {
          'key': 'D',
          'credits': {'writer': 'A. Writer'},
        },
      ),
      metadata: {'key': ' ', 'album': null},
    );
    final claims = collectSourceEvidence(_candidate(), [
      source,
    ], compatible: (_, _) => true);

    expect(
      claims
          .where((claim) => claim.field == 'metadata.key')
          .map((c) => c.value),
      ['D'],
    );
    expect(
      claims
          .singleWhere((claim) => claim.field == 'metadata.credits.writer')
          .value,
      'A. Writer',
    );
  });

  test('candidate and resolved nested facts remain separate claims', () {
    final source = _source(
      candidate: _candidate(
        provider: 'catalog',
        metadata: {
          'credits': {'composer': 'Candidate Name'},
        },
      ),
      metadata: {
        'credits': {'composer': 'Resolved Name'},
      },
    );
    final claims = collectSourceEvidence(
      _candidate(),
      [source],
      compatible: (_, _) => true,
    ).where((claim) => claim.field == 'metadata.credits.composer').toList();

    expect(claims.map((claim) => claim.value).toSet(), {
      'Candidate Name',
      'Resolved Name',
    });
    expect(
      claims
          .singleWhere((claim) => claim.value == 'Resolved Name')
          .qualitySignals,
      {'resolvedClaim': 2},
    );
  });

  test('the selected record outweighs another resolved album', () {
    final other = _source(
      candidate: _candidate(provider: 'lyrics', id: 'other'),
      metadata: {'album': 'Compilation', 'durationSeconds': 275},
    );
    final claims = collectSourceEvidence(
      _candidate(album: 'Original Album', duration: 266),
      [other],
      compatible: (_, _) => true,
    );
    for (final field in ['metadata.album', 'metadata.durationSeconds']) {
      final signals = {
        for (final claim in claims.where((claim) => claim.field == field))
          claim.value: claim.qualitySignals,
      };
      expect(signals.values, [
        {'selectedRecord': 3},
        {'resolvedClaim': 2},
      ], reason: field);
    }
  });

  test('rejected or context-incompatible metadata stays as a claim', () {
    final source = _source(
      candidate: _candidate(provider: 'catalog', metadata: {'key': 'F#'}),
      match: MatchKind.rejected,
    );
    final claims = collectSourceEvidence(_candidate(), [
      source,
    ], compatible: (_, _) => false);
    final key = claims.singleWhere((claim) => claim.field == 'metadata.key');

    expect(key.value, 'F#');
    expect(key.contextCompatible, isFalse);
    expect(key.incompatibilityReason, 'context_incompatible');
    expect(key.matchQuality, EvidenceMatchQuality.rejected);
  });

  test(
    'content hashes are stable across source identities and normalize lyrics',
    () {
      final first = _source(
        candidate: _candidate(provider: 'one', id: 'a'),
        body: '[Verse]\n[C]Hello,  world!\n[G]Again',
      );
      final second = _source(
        candidate: _candidate(provider: 'two', id: 'b'),
        body: '[Verse]\n[C]hello world\n[G]Again',
      );
      List<EvidenceClaim> collect(SourceResult source) => collectSourceEvidence(
        _candidate(),
        [source],
        compatible: (_, _) => true,
      );
      final firstClaims = collect(first);
      final secondClaims = collect(second);

      expect(
        firstClaims.singleWhere((claim) => claim.field == 'lyrics').value,
        secondClaims.singleWhere((claim) => claim.field == 'lyrics').value,
      );
      expect(
        firstClaims.singleWhere((claim) => claim.field == 'chords').value,
        secondClaims.singleWhere((claim) => claim.field == 'chords').value,
      );
      expect(
        firstClaims.singleWhere((claim) => claim.field == 'lyrics').sourceId,
        'one:a',
      );
    },
  );

  test(
    'app-supplied lineage is retained but payload labels cannot declare it',
    () {
      final linked = _source(
        candidate: _candidate(provider: 'one', extra: {'lineageId': 'work-7'}),
        body: 'A lyric line',
      );
      final unlinked = _source(
        candidate: _candidate(provider: 'two'),
        body: 'A lyric line',
      );
      final claims = collectSourceEvidence(
        _candidate(),
        [linked, unlinked],
        compatible: (_, _) => true,
        sourceLineage: (source) => source.id == 'one:song' ? 'work-7' : null,
      ).where((claim) => claim.field == 'lyrics').toList();

      expect(claims.map((claim) => claim.lineageId), ['work-7', null]);
      expect(claims.map((claim) => claim.value).toSet().length, 1);
    },
  );

  test(
    'provider metadata cannot promote itself to user or primary authority',
    () {
      final source = _source(
        candidate: _candidate(
          provider: 'provider',
          metadata: {
            'evidenceOrigin': 'userProvided',
            'identityScope': 'recording',
            'lineageId': 'forged-copy-group',
          },
        ),
        body: '[C]A lyric line',
        metadata: {'key': 'C', 'sourceOrigin': 'primarySource'},
      );
      final claims = collectSourceEvidence(_candidate(), [
        source,
      ], compatible: (_, _) => true);
      expect(
        claims.every((claim) => claim.origin == EvidenceOrigin.provider),
        isTrue,
      );
      expect(claims.every((claim) => claim.lineageId == null), isTrue);
      expect(
        claims
            .singleWhere((claim) => claim.field == 'metadata.key')
            .sourceScope,
        EvidenceSourceScope.arrangement,
      );
    },
  );
}
