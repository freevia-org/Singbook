// Output-identity guard for the combine pipeline.
//
// The digests below were recorded from the implementation as it stood before
// the review's performance and robustness refactoring. Combined documents are
// persisted (the `x_verse` ChordPro payload), so an internal optimization must
// not change a single byte of them. A digest changes only for an intentional
// behaviour change, which needs its own review.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/evidence_ranking.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/source_result_merge.dart';

const _vocabulary = [
  'amber', 'lanterns', 'glow', 'above', 'the', 'quiet', 'water', 'silver', //
  'rain', 'returns', 'beneath', 'evening', 'sky', 'every', 'window', 'keeps',
  'a', 'little', 'golden', 'light', 'morning', 'carries', 'dream', 'back',
  'home', 'river', 'stone', 'paper', 'garden', 'winter', 'summer', 'oh',
  'yeah', 'la', "darlin'", 'don\'t', 'café', 'naïve', 'heart', 'runs',
];
const _progressions = [
  ['G', 'D', 'Em', 'C'],
  ['C', 'G', 'Am', 'F'],
  ['E', 'B', 'C#m', 'A'],
  ['Am', 'F', 'C', 'G'],
  ['D', 'A', 'Bm', 'G'],
  ['F', 'Bb', 'C', 'Dm'],
  ['A7', 'D7', 'E7', 'A7'],
];
const _keys = ['G', 'C', 'E', 'Am', 'D', 'F', 'A', 'Em', 'Bb', 'F#m'];

/// Set REVIEW_COMBINE_DUMP to a directory to write a corpus's raw output
/// there, for comparing two implementations line by line.
void _dump(String name, Object? value) {
  final directory = Platform.environment['REVIEW_COMBINE_DUMP'];
  if (directory == null || directory.isEmpty) return;
  File('$directory/$name.json').writeAsStringSync(
    const JsonEncoder.withIndent(' ').convert(value),
  );
  File('$directory/$name.digest').writeAsStringSync(_digest(value));
}

String _digest(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(value))).toString();

JsonMap _stable(SongDocument song) => song.toJson()
  ..remove('id')
  ..remove('createdAt')
  ..remove('updatedAt');

class _Scenario {
  _Scenario(int seed) : random = Random(seed);
  final Random random;

  T pick<T>(List<T> values) => values[random.nextInt(values.length)];
  bool chance(double probability) => random.nextDouble() < probability;

  List<String> line() => [
    for (var i = 0, count = 2 + random.nextInt(7); i < count; i++)
      pick(_vocabulary),
  ];

  /// Lyric lines with deliberate repeats, so repeated-line, ambiguous and
  /// leftover alignment paths are all exercised.
  List<List<String>> lyricLines() {
    final verse = [for (var i = 0; i < 3 + random.nextInt(3); i++) line()];
    final chorus = [for (var i = 0; i < 2 + random.nextInt(3); i++) line()];
    final second = [for (var i = 0; i < verse.length; i++) line()];
    return [
      ...verse,
      ...chorus,
      ...second,
      ...chorus,
      if (chance(.5)) ...[line(), line()],
      if (chance(.5)) ...chorus,
    ];
  }

  String lyrics(List<List<String>> lines, {bool sections = false}) {
    final output = <String>[];
    for (var i = 0; i < lines.length; i++) {
      if (sections && i % 4 == 0) {
        output.add(i % 8 == 0 ? 'Verse ${i ~/ 8 + 1}' : '{comment: Chorus}');
      }
      output.add(lines[i].join(' '));
      if (i % 4 == 3) output.add('');
    }
    return output.join('\n');
  }

  String chart(List<List<String>> lines, List<String> chords) {
    final output = <String>[];
    var chord = 0;
    for (var i = 0; i < lines.length; i++) {
      var words = [...lines[i]];
      if (chance(.12)) continue;
      if (chance(.15) && words.length > 3) words.removeLast();
      if (chance(.1)) words = [...words, pick(_vocabulary)];
      if (chance(.2) && i > lines.length ~/ 2) {
        output.add(words.join(' '));
        continue;
      }
      if (chance(.1) && i + 1 < lines.length) {
        words = [...words, ...lines[i + 1]];
      }
      final text = StringBuffer();
      for (var w = 0; w < words.length; w++) {
        if (w > 0) text.write(' ');
        if (w == 0 || chance(.3)) {
          text.write('[${chords[chord++ % chords.length]}]');
        }
        text.write(words[w]);
      }
      if (chance(.15)) text.write(' [${chords[chord++ % chords.length]}]');
      if (chance(.1)) output.add('{comment: Chorus}');
      output.add(text.toString());
    }
    return output.join('\n');
  }

  JsonMap facts() => {
    if (chance(.5)) 'album': pick(['Lanterns', 'Lanterns (Remastered 2009)']),
    if (chance(.5)) 'durationSeconds': pick<num>([201, 202.4, 203, 240, 0]),
    if (chance(.3)) 'year': pick([1999, 2009]),
    if (chance(.3)) 'genres': [pick(['folk', 'pop']), pick(['rock', 'folk'])],
    if (chance(.3))
      'credits': {
        'composer': pick(['A. Writer', 'B. Writer']),
        if (chance(.5)) 'lyricist': 'C. Poet',
      },
    if (chance(.2))
      'mediaLinks': [
        {'url': 'https://open.spotify.com/track/${pick(['abc', 'def'])}'},
      ],
    if (chance(.2)) 'isrc': pick(['USRC17607839', 'GBAYE0601498']),
    if (chance(.15)) 'language': pick(['en', 'fr']),
  };

  SourceResult source(
    String provider,
    String body, {
    String id = 'song',
    MatchKind? match,
    String? matchReason,
    JsonMap metadata = const {},
    JsonMap candidateMetadata = const {},
    JsonMap extra = const {},
    Map<String, String> recordingIds = const {},
  }) {
    final candidate = facts();
    return SourceResult(
      candidate: SongCandidate(
        providerId: provider,
        id: id,
        title: pick(['Lantern Song', 'Lantern Song', 'Lantern Song (Live)']),
        artist: pick(['The Singers', 'The Singers', 'Singers']),
        album: candidate.remove('album') as String?,
        durationSeconds: chance(.4) ? pick([201.0, 203.5, 250.0]) : null,
        metadata: {...candidate, ...candidateMetadata},
        recordingIds: recordingIds,
      ),
      body: body,
      metadata: {...facts(), ...metadata},
      matchKind:
          match ??
          pick([
            MatchKind.sameSong,
            MatchKind.sameSong,
            MatchKind.sameRecording,
            MatchKind.unverified,
          ]),
      matchReason: matchReason,
      extra: extra,
    );
  }

  ({SongCandidate selected, List<SourceResult> sources}) build() {
    final lines = lyricLines();
    final recordingIds = chance(.4)
        ? {'isrc': 'USRC17607839'}
        : const <String, String>{};
    final selected = SongCandidate(
      providerId: 'catalog',
      id: 'selected',
      title: 'Lantern Song',
      artist: 'The Singers',
      album: chance(.5) ? 'Lanterns' : null,
      durationSeconds: chance(.5) ? 202 : null,
      metadata: chance(.3) ? {'identityScope': 'recording'} : const {},
      recordingIds: recordingIds,
    );
    final sources = <SourceResult>[
      source(
        'lyrics-a',
        lyrics(lines, sections: chance(.5)),
        match: chance(.5) ? MatchKind.sameRecording : MatchKind.sameSong,
        recordingIds: recordingIds,
      ),
      if (chance(.6))
        source('lyrics-b', lyrics(lines, sections: chance(.5))),
      if (chance(.3))
        source('lyrics-c', lyrics(lines.take(lines.length - 2).toList())),
    ];
    final chartCount = random.nextInt(5);
    for (var i = 0; i < chartCount; i++) {
      final chords = pick(_progressions);
      final body = chart(lines, chords);
      final rejected = chance(.2);
      final earlier = source(
        'chords-$i',
        chart(lines, pick(_progressions)),
        match: MatchKind.sameSong,
      );
      sources.add(
        source(
          'chords-$i',
          body,
          match: rejected ? MatchKind.rejected : null,
          matchReason: rejected ? 'incomplete_or_different_lyrics' : null,
          metadata: {
            if (chance(.5)) 'key': pick(_keys),
            if (chance(.4)) 'capo': pick<Object>([0, 2, 3, '4', 'x']),
            if (chance(.2)) 'tuning': pick(['E A D G B E', 'D A D G B E']),
            if (chance(.15)) 'timeSignature': pick(['4/4', '3/4']),
          },
          extra: {
            if (chance(.5)) 'keyConsensus': chance(.7),
            if (chance(.2)) 'keyShift': pick([0, 2, 5, 9]),
            if (chance(.4)) 'keyEstimate': pick(_keys),
            if (chance(.3)) 'requiresLyricsAgreement': true,
            if (chance(.35))
              'keyRecording': {
                'key': pick(_keys),
                'ids': [pick(['USRC17607839', 'GBAYE0601498'])],
                if (chance(.5)) 'recordingScope': pick(['song', 'recording']),
                if (chance(.3)) 'selectedIdentity': 'catalog:selected',
                if (chance(.5))
                  'alternatives': [
                    {
                      'key': pick(_keys),
                      'ids': ['GBAYE0601498'],
                    },
                  ],
              },
            if (chance(.4))
              'discoveryEvidence': {
                if (chance(.5)) 'capabilities': ['chords'],
                if (chance(.6)) 'acceptedPayloads': [earlier.toJson()],
                if (chance(.4))
                  'rejectedPayloads': [
                    {
                      'payload': earlier.toJson(),
                      'reason': 'identity_mismatch',
                    },
                  ],
                'searchCandidates': [
                  for (var c = 0; c < random.nextInt(4); c++)
                    {
                      'candidate': SongCandidate(
                        providerId: 'chords-$i',
                        id: 'hit-$c',
                        title: 'Lantern Song',
                        artist: 'The Singers',
                        metadata: {
                          if (chance(.5)) 'key': pick(_keys),
                          ...facts(),
                        },
                      ).toJson(),
                    },
                ],
              },
          },
        ),
      );
    }
    if (chance(.3)) {
      sources.add(
        source(
          'musicbrainz',
          '',
          metadata: {
            'artistCredits': [
              {'name': 'The Singers', 'id': 'mbid-1'},
            ],
          },
          extra: {'metadataOnly': true},
        ),
      );
    }
    sources.shuffle(random);
    return (selected: selected, sources: sources);
  }
}

Object? _combined(
  SongCandidate selected,
  List<SourceResult> sources, {
  String? preferredSourceId,
  bool compact = false,
}) {
  try {
    return _stable(
      combineSources(
        selected,
        sources,
        preferredSourceId: preferredSourceId,
        compactExplicitSave: compact,
        allowRejectedPreferredSource: preferredSourceId != null,
      ),
    );
  } on FormatException catch (error) {
    return 'FormatException: ${error.message}';
  }
}

void main() {
  test('automatic combination output is unchanged', () {
    final outputs = <Object?>[];
    for (var seed = 0; seed < 120; seed++) {
      final scenario = _Scenario(seed).build();
      outputs.add(_combined(scenario.selected, scenario.sources));
    }
    expect(
      outputs.whereType<Map>().length,
      greaterThan(100),
      reason: 'the corpus must mostly produce documents',
    );
    expect(
      outputs
          .whereType<Map>()
          .where((song) => (song['body'] as String).contains('['))
          .length,
      greaterThan(50),
      reason: 'the corpus must exercise chord placement',
    );
    _dump('automatic', outputs);
    expect(_digest(outputs), _automaticDigest);
  });

  test('explicit source combination output is unchanged', () {
    final outputs = <Object?>[];
    for (var seed = 200; seed < 260; seed++) {
      final scenario = _Scenario(seed).build();
      for (final source in scenario.sources.take(3)) {
        outputs.add(
          _combined(
            scenario.selected,
            scenario.sources,
            preferredSourceId: source.id,
            compact: seed.isEven,
          ),
        );
      }
    }
    expect(outputs.whereType<Map>().length, greaterThan(60));
    _dump('explicit', outputs);
    expect(_digest(outputs), _explicitDigest);
  });

  test('key recovery and diagnostics output is unchanged', () {
    final outputs = <Object?>[];
    final diagnostics = <Object?>[];
    for (var seed = 300; seed < 380; seed++) {
      final scenario = _Scenario(seed).build();
      SongDocument song;
      try {
        song = combineSources(scenario.selected, scenario.sources);
      } on FormatException {
        continue;
      }
      // Saved imports have no ranking and no recovered key.
      final legacy = song.copyWith(
        metadata: {...song.metadata}..remove('key'),
        extra: {...song.extra}..remove('evidenceRanking'),
      );
      final sourced = sourcedArrangementKey(legacy);
      final corroborated = corroboratedArrangementKey(legacy);
      outputs.add([
        sourced == null ? null : [sourced.key, sourced.sourceIds],
        corroborated == null
            ? null
            : [corroborated.key, corroborated.sourceIds],
        checkedChordKeyEstimate(song),
        rankedChordKeyEstimate(song),
        rankedKeyNeedsReview(song),
      ]);
      diagnostics.add(arrangementKeySetupDiagnostics(legacy));
    }
    expect(outputs.length, greaterThan(60));
    _dump('key', outputs);
    _dump('diagnostics', diagnostics);
    expect(_digest(outputs), _keyDigest);
    expect(_digest(diagnostics), _diagnosticsDigest);
  });

  test('source merge and saved version history output is unchanged', () {
    final outputs = <Object?>[];
    for (var seed = 400; seed < 460; seed++) {
      final builder = _Scenario(seed);
      final scenario = builder.build();
      SourceResult? merged;
      for (var round = 0; round < 4; round++) {
        final next = _Scenario(seed * 10 + round).build().sources;
        for (final source in next) {
          if (source.id != scenario.sources.first.id) continue;
          merged = merged == null
              ? source
              : mergeSourceResult(merged, source);
        }
      }
      outputs.add(merged?.toJson());
      SongDocument? previous;
      var history = <JsonMap>[];
      for (var round = 0; round < 3; round++) {
        final next = _Scenario(seed * 10 + round).build();
        SongDocument song;
        try {
          song = combineSources(next.selected, next.sources).copyWith(
            id: 'song',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026, 1, round + 1),
          );
        } on FormatException {
          continue;
        }
        if (previous != null) {
          history = retainedSavedVersions(
            previous.copyWith(
              extra: {...previous.extra, 'previousSavedVersions': history},
            ),
            song,
          );
        }
        previous = song;
      }
      outputs.add(history);
    }
    _dump('history', outputs);
    expect(_digest(outputs), _historyDigest);
  });

  test('generic evidence ranking output is unchanged', () {
    final outputs = <Object?>[];
    for (var seed = 500; seed < 560; seed++) {
      final random = Random(seed);
      T pick<T>(List<T> values) => values[random.nextInt(values.length)];
      final claims = [
        for (var i = 0, count = 5 + random.nextInt(60); i < count; i++)
          EvidenceClaim(
            field: 'f${random.nextInt(9)}',
            value: pick<Object>([
              'Alpha',
              'alpha',
              'beta',
              3,
              3.5,
              ['x', 'y'],
              ['y', 'x'],
              {'b': 1, 'a': 2},
              {'a': 2, 'b': 1},
              DateTime.utc(2026, 1, 2),
            ]),
            sourceId: 's${random.nextInt(6)}',
            providerId: 'p${random.nextInt(4)}',
            lineageId: random.nextBool() ? 'l${random.nextInt(2)}' : null,
            matchQuality: pick(EvidenceMatchQuality.values),
            sourceScope: pick(EvidenceSourceScope.values),
            origin: pick(EvidenceOrigin.values),
            harmonyFit: pick(EvidenceHarmonyFit.values),
            contextId: random.nextBool() ? 'c${random.nextInt(3)}' : null,
            contextCompatible: random.nextInt(5) != 0,
            supportsCorroboration: random.nextInt(4) != 0,
            equivalenceKey: random.nextInt(4) == 0
                ? pick(['K1', 'k1', ' K2 ', ''])
                : null,
            qualitySignals: {
              if (random.nextBool()) 'q': random.nextInt(60) - 30,
              if (random.nextBool()) 'r': random.nextInt(60) - 30,
            },
          ),
      ];
      final ranking = rankEvidenceClaims(
        claims,
        beamBudget: pick([1, 4, 32]),
        fieldWeights: const {'f0': 4, 'f1': 2},
        compatibleWithChosen: (candidate, chosen) => chosen.every(
          (other) =>
              candidate.contextId == null ||
              other.contextId == null ||
              candidate.contextId == other.contextId,
        ),
      );
      outputs.add({
        ...ranking.toJson(),
        'chosen': {
          for (final entry in ranking.chosenByField.entries)
            entry.key: claims.indexOf(entry.value),
        },
        'alternatives': {
          for (final entry in ranking.alternativesByField.entries)
            entry.key: entry.value.map(claims.indexOf).toList(),
        },
        'order': ranking.claims
            .map((item) => claims.indexOf(item.claim))
            .toList(),
      });
    }
    final encodable = jsonDecode(
      jsonEncode(
        outputs,
        toEncodable: (value) =>
            value is DateTime ? value.toIso8601String() : '$value',
      ),
    );
    _dump('ranking', encodable);
    expect(_digest(encodable), _rankingDigest);
  });
}

const _automaticDigest = '1dcdc378b24e6263da55bc104408eaa34c6c6e8643519f1e89635599f27b547f';
const _explicitDigest = 'fb179bed4b9f8e8b260a2adc03e003f2fa975bf42640ea315fd58cca98a18c0e';
const _keyDigest = 'e9e6f7e909d2f00e0656e4d63c16cf818390e03d89068ce9180454f04a1f2415';
const _diagnosticsDigest = 'ca6876bca022a0c6def31ee1e4df66e539ebff83df8940c89075b316e3a87d8a';
const _historyDigest = 'c02b21c96b606844911f73779d1db989de7ca9e04ef93a29320fbc54af53181a';
const _rankingDigest = '24ae1efe7fc2b064277882cc012c4d2f61a24bbbbc3ae9e1eedd4ebea0e75f1e';
