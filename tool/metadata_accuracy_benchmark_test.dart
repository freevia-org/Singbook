// ignore_for_file: avoid_print
// Offline-only, cache-first metadata benchmark. No network requests are made.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/chord_key_estimate.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/domain/edition_identity.dart';
import 'package:singbook/domain/search_grouping.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';

import 'src/metadata_response_cache.dart';
import 'src/metadata_corpus_identity.dart';
import 'src/metadata_reference_validation.dart';

const _jitterSeed = int.fromEnvironment(
  'METADATA_BENCHMARK_JITTER',
  defaultValue: -1,
);
const _maxNetwork = int.fromEnvironment('METADATA_BENCHMARK_MAX_NETWORK');
const _runAudit = bool.fromEnvironment('METADATA_BENCHMARK_RUN');
const _cachePath = String.fromEnvironment(
  'METADATA_BENCHMARK_CACHE',
  defaultValue: 'artifacts/metadata-accuracy/cache',
);
const _fields = ['lyrics', 'key', 'chords'];

String _normalize(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r"['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

String _normalizedLyrics(String body) => _normalize(
  body
      .replaceAll(RegExp(r'\{[^}\n]*\}'), ' ')
      .replaceAll(RegExp(r'\[[^\]\n]*\]'), ''),
);

String _sha(String value) => sha256.convert(utf8.encode(value)).toString();

double? _strictCorpusAccuracyPercent({
  required int correct,
  required int evaluated,
  required int corpusSize,
}) => evaluated == corpusSize ? 100 * correct / corpusSize : null;

String _accuracyEvaluationStatus({
  required int evaluated,
  required int corpusSize,
}) => switch (evaluated) {
  0 => 'no_adjudicated_correctness_comparisons',
  _ when evaluated == corpusSize => 'all_songs_compared',
  _ => 'partial_adjudicated_comparisons',
};

Map<String, Object?> _selectedLyricsSupport({
  required String? selectedHash,
  required Iterable<Map> sources,
}) {
  if (selectedHash == null) {
    return {
      'level': 'no_selected_lyrics',
      'providerLabels': <String>[],
      'matchingCandidateCount': 0,
      'matchingCandidateIdCount': 0,
      'independentLineageConfirmed': false,
    };
  }
  final matches = sources
      .where((source) => source['normalizedLyricsSha256'] == selectedHash)
      .toList();
  final providers =
      matches
          .map((source) => source['provider'])
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
  final candidateIds = matches
      .map((source) => source['candidateIdSha256'])
      .whereType<String>()
      .toSet();
  return {
    'level': providers.length > 1
        ? 'multi_provider_exact_text_support'
        : providers.length == 1
        ? 'single_provider_exact_text_support'
        : 'no_exact_candidate_text_support',
    'providerLabels': providers,
    'matchingCandidateCount': matches.length,
    'matchingCandidateIdCount': candidateIds.length,
    // Different adapter labels or catalog IDs do not prove independent
    // upstream lineage; retain that distinction in the audit output.
    'independentLineageConfirmed': false,
  };
}

int _capoOf(Object? raw) =>
    raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;

String? _soundingKey(SongDocument doc) {
  final m = doc.metadata;
  final declared = m['key'] as String?;
  // Declared metadata is already a sounding key, matching player display.
  if (declared != null) return declared;
  final shapeKey =
      checkedChordKeyEstimate(doc) ?? estimateChordKey(doc.body)?.key;
  if (shapeKey == null) return null;
  final capo = _capoOf(m['capo']);
  return capo == 0 ? shapeKey : transposeChord(shapeKey, capo);
}

/// Identifies the scope of the combined key value for reference comparison.
/// A chart can name the transposed arrangement key without establishing the
/// selected recording's home key. Keep that useful chart claim, but do not
/// compare a different-scope claim as a recording-key error.
String _keyClaimScope(SongDocument doc) {
  final estimate = jsonMap(doc.extra['chordKeyEstimate']);
  if (estimate['hint'] == 'recording') return 'recording';
  if (_hasMeaningfulMetadata(doc.metadata['key'])) {
    final origin = jsonMap(doc.extra['fieldOrigins'])['key'];
    if (origin is String) {
      for (final source in doc.sources) {
        if (source.id != origin) continue;
        final selected =
            doc.selectedRecording ??
            SongCandidate(
              providerId: 'library',
              id: doc.id,
              title: doc.title,
              artist: doc.artist,
            );
        return recordingCompatible(selected, source)
            ? 'recording'
            : 'arrangement';
      }
    }
    return 'unknown';
  }
  if (estimate['key'] is String || estimateChordKey(doc.body) != null) {
    return 'arrangement';
  }
  return 'unknown';
}

bool _hasMeaningfulMetadata(Object? value) =>
    value != null && (value is! String || value.trim().isNotEmpty);

String _keyComparisonStatus({
  required bool matchesReference,
  required String claimScope,
}) {
  if (matchesReference) return 'verifiedCorrect';
  return switch (claimScope) {
    'arrangement' => 'scopeMismatch',
    'recording' => 'verifiedIncorrect',
    _ => 'unverified',
  };
}

// Accuracy requires the same tonic AND mode. Relative major/minor agreement
// used by chart voting is useful evidence, but is not an exact key answer.
String? _exactKeyIdentity(String value) {
  final match = RegExp(
    r'^([A-Ga-g])([#b♯♭]{0,2})\s*(m|min|minor|maj|major|M|ionian|aeolian|dorian|phrygian|lydian|mixolydian|locrian)?$',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return null;
  const pitches = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  var pitch = pitches[match[1]!.toUpperCase()]!;
  for (final accidental in match[2]!.split('')) {
    pitch += accidental == '#' || accidental == '♯' ? 1 : -1;
  }
  final raw = match[3] ?? 'major';
  final mode = raw == 'M'
      ? 'major'
      : switch (raw.toLowerCase()) {
          'm' || 'min' || 'minor' || 'aeolian' => 'minor',
          'maj' || 'major' || 'ionian' => 'major',
          _ => raw.toLowerCase(),
        };
  return '${pitch % 12}:$mode';
}

String _canonicalChord(String chord, int capo) {
  final moved = transposeChord(
    chord,
    capo,
  ).replaceAll('♯', '#').replaceAll('♭', 'b');
  return moved.replaceAllMapped(RegExp(r'(^|/)([A-G])([#b]{0,2})'), (m) {
    final key = _exactKeyIdentity('${m[2]}${m[3]}')!;
    return '${m[1]}p${key.split(':').first}';
  });
}

String? _chordAlignmentHash(SongDocument doc) {
  final anchors = <String>[];
  var wordBase = 0;
  final capo = _capoOf(doc.metadata['capo']);
  for (final line in parseArrangement(doc.body)) {
    if (line.directive) continue;
    final words = RegExp(
      r"[\p{L}\p{N}]+(?:['‘’][\p{L}\p{N}]+)*",
      unicode: true,
    ).allMatches(line.text).toList();
    for (final anchor in line.chords) {
      var word = words.indexWhere((w) => anchor.offset < w.end);
      if (word < 0) word = words.length;
      anchors.add('${wordBase + word}:${_canonicalChord(anchor.chord, capo)}');
    }
    wordBase += words.length;
  }
  if (anchors.isEmpty) return null;
  return _sha('${_sha(_normalizedLyrics(doc.body))}\n${anchors.join('\n')}');
}

String? _sourceChordAlignmentHash(SourceResult source) => _chordAlignmentHash(
  SongDocument(
    id: source.id,
    title: source.candidate.title,
    artist: source.candidate.artist,
    body: source.body,
    metadata: {...source.candidate.metadata, ...source.metadata},
  ),
);

Map<String, dynamic> _readCorpus() {
  final data =
      jsonDecode(File('tool/metadata_accuracy_corpus.json').readAsStringSync())
          as Map<String, dynamic>;
  for (final song in (data['songs'] as List).cast<Map<String, dynamic>>()) {
    final expected = song['expected'] as Map<String, dynamic>;
    for (final field in _fields) {
      final claim = (expected['fields'] as Map)[field] as Map;
      if (claim['status'] != 'verified') continue;
      final value = claim['value'];
      if (value is! String ||
          (field == 'key'
              ? _exactKeyIdentity(value) == null
              : !RegExp(r'^[0-9a-f]{64}$').hasMatch(value))) {
        throw StateError('${song['id']} $field has an invalid reference value');
      }
      final path = claim['reviewRecord'];
      if (path is! String ||
          !RegExp(
            r'^tool/metadata_reference_evidence/[a-z0-9_]+\.json$',
          ).hasMatch(path)) {
        throw StateError('${song['id']} $field has no canonical review record');
      }
      final review =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final errors = reviewedReferenceErrors(song, field, review);
      if (errors.isNotEmpty) {
        throw StateError('${song['id']} $field: ${errors.join('; ')}');
      }
    }
  }
  return data;
}

void main() {
  test(
    'reviewed references reject stale value, recording, field and scope',
    () {
      Map<String, dynamic> song() => {
        'id': 'invented',
        'recordingEdition': 'Original studio performance',
        'recordingEditionStatus': 'verified',
        'expected': {
          'recordingReference': {
            'status': 'verified',
            'providerId': 'catalog',
            'candidateId': 'original',
            'isrc': null,
            'recordingEdition': 'Original studio performance',
            'evidence': ['https://example.test/original'],
          },
          'fields': {
            'key': {
              'status': 'verified',
              'value': 'C',
              'evidence': ['https://example.test/analysis'],
            },
          },
        },
      };
      Map<String, dynamic> review() => {
        'songId': 'invented',
        'field': 'key',
        'status': 'verified',
        'value': 'C',
        'scope': 'Original studio performance',
        'recordingBinding': {
          'status': 'verified',
          'providerId': 'catalog',
          'candidateId': 'original',
          'isrc': null,
          'recordingEdition': 'Original studio performance',
          'evidence': ['https://example.test/original'],
        },
        'independentSources': [
          {
            'url': 'https://example.test/analysis',
            'role': 'Invented educator',
            'finding': 'Invented evidence',
          },
        ],
        'notDerivedFromActualBenchmarkKey': true,
      };
      expect(reviewedReferenceErrors(song(), 'key', review()), isEmpty);
      for (final entry in {
        'value': 'D',
        'songId': 'another-song',
        'field': 'lyrics',
        'scope': 'Live performance',
        'status': 'unverified',
        'notDerivedFromActualBenchmarkKey': false,
      }.entries) {
        expect(
          reviewedReferenceErrors(
            song(),
            'key',
            review()..[entry.key] = entry.value,
          ),
          isNotEmpty,
          reason: entry.key,
        );
      }
      final stale = review();
      (stale['recordingBinding'] as Map)['candidateId'] = 'another-recording';
      expect(reviewedReferenceErrors(song(), 'key', stale), isNotEmpty);
      final missing = review()..['independentSources'] = [];
      expect(reviewedReferenceErrors(song(), 'key', missing), isNotEmpty);
      final noRecordingEvidence = review();
      (noRecordingEvidence['recordingBinding'] as Map)['evidence'] = [];
      expect(
        reviewedReferenceErrors(song(), 'key', noRecordingEvidence),
        isNotEmpty,
      );
      final staleEvidence = song();
      (((staleEvidence['expected'] as Map)['fields'] as Map)['key']
          as Map)['evidence'] = [
        'https://example.test/unreviewed',
      ];
      expect(
        reviewedReferenceErrors(staleEvidence, 'key', review()),
        isNotEmpty,
      );
      final catalogOnly = song();
      (((catalogOnly['expected'] as Map)['fields'] as Map)['key']
          as Map)['evidence'] = [
        'https://example.test/original',
      ];
      expect(reviewedReferenceErrors(catalogOnly, 'key', review()), isNotEmpty);
      final unbound = song();
      ((unbound['expected'] as Map)['recordingReference']
              as Map)['candidateId'] =
          null;
      expect(reviewedReferenceErrors(unbound, 'key', review()), isNotEmpty);
      final unknown = song();
      (((unknown['expected'] as Map)['fields'] as Map)['key']
              as Map)['status'] =
          'unverified';
      expect(reviewedReferenceErrors(unknown, 'key', {}), isEmpty);
    },
  );

  test('partial reference coverage has no strict corpus accuracy score', () {
    expect(
      _strictCorpusAccuracyPercent(correct: 0, evaluated: 0, corpusSize: 100),
      isNull,
    );
    expect(
      _strictCorpusAccuracyPercent(correct: 7, evaluated: 8, corpusSize: 100),
      isNull,
    );
    expect(
      _strictCorpusAccuracyPercent(
        correct: 97,
        evaluated: 100,
        corpusSize: 100,
      ),
      97,
    );
  });
  test('accuracy status describes adjudication, not source discovery', () {
    expect(
      _accuracyEvaluationStatus(evaluated: 0, corpusSize: 100),
      'no_adjudicated_correctness_comparisons',
    );
    expect(
      _accuracyEvaluationStatus(evaluated: 8, corpusSize: 100),
      'partial_adjudicated_comparisons',
    );
    expect(
      _accuracyEvaluationStatus(evaluated: 100, corpusSize: 100),
      'all_songs_compared',
    );
  });
  test('selected lyric support is visible without claiming correctness', () {
    final converged = _selectedLyricsSupport(
      selectedHash: 'selected',
      sources: [
        {
          'normalizedLyricsSha256': 'selected',
          'provider': 'genius',
          'candidateIdSha256': 'upstream-1',
        },
        {
          'normalizedLyricsSha256': 'selected',
          'provider': 'betterlyrics',
          'candidateIdSha256': 'upstream-1',
        },
      ],
    );
    expect(converged['level'], 'multi_provider_exact_text_support');
    expect(converged['providerLabels'], ['betterlyrics', 'genius']);
    expect(converged['matchingCandidateIdCount'], 1);
    expect(converged['independentLineageConfirmed'], isFalse);

    final singleLabel = _selectedLyricsSupport(
      selectedHash: 'selected',
      sources: [
        {
          'normalizedLyricsSha256': 'selected',
          'provider': 'genius',
          'candidateIdSha256': 'one',
        },
        {
          'normalizedLyricsSha256': 'alternative',
          'provider': 'lrclib',
          'candidateIdSha256': 'two',
        },
      ],
    );
    expect(singleLabel['level'], 'single_provider_exact_text_support');
    expect(singleLabel['independentLineageConfirmed'], isFalse);

    expect(
      _selectedLyricsSupport(selectedHash: null, sources: const [])['level'],
      'no_selected_lyrics',
    );
  });
  test('recording key comparisons distinguish chart-scoped key claims', () {
    const selected = SongCandidate(
      providerId: 'genius',
      id: '821238',
      title: 'The Girl from Ipanema',
      artist: 'Stan Getz & João Gilberto',
    );
    final alternateArrangement = SourceResult(
      candidate: const SongCandidate(
        providerId: 'ultimateguitar',
        id: 'chart-1',
        title: 'The Girl from Ipanema',
        artist: 'Stan Getz & João Gilberto',
      ),
      body: '[F]Example lyric line',
      matchKind: MatchKind.sameSong,
    );
    final chartKey = SongDocument(
      id: 'ipanema',
      title: selected.title,
      artist: selected.artist,
      body: '[F]Example lyric line',
      metadata: const {'key': 'F'},
      sources: [alternateArrangement],
      selectedRecording: selected,
      extra: {
        'fieldOrigins': {'key': alternateArrangement.id},
      },
    );
    expect(_keyClaimScope(chartKey), 'arrangement');
    expect(
      _keyComparisonStatus(
        matchesReference: false,
        claimScope: _keyClaimScope(chartKey),
      ),
      'scopeMismatch',
    );
    expect(
      _keyComparisonStatus(matchesReference: false, claimScope: 'recording'),
      'verifiedIncorrect',
    );
    expect(
      _keyComparisonStatus(matchesReference: false, claimScope: 'unknown'),
      'unverified',
    );
    expect(
      _keyComparisonStatus(
        matchesReference: true,
        claimScope: _keyClaimScope(chartKey),
      ),
      'verifiedCorrect',
    );

    final recordingSource = SourceResult(
      candidate: selected,
      body: '[Db]Example lyric line',
      matchKind: MatchKind.sameRecording,
    );
    final recordingKey = chartKey.copyWith(
      metadata: const {'key': 'Db'},
      sources: [recordingSource],
      extra: {
        'fieldOrigins': {'key': recordingSource.id},
      },
    );
    expect(_keyClaimScope(recordingKey), 'recording');
  });
  test(
    'reviewed edition proof requires the bound recording and target scope',
    () {
      const candidate = SongCandidate(
        providerId: 'catalog',
        id: 'original',
        title: 'Harbor Song',
        artist: 'Lantern Coast',
      );
      Map<String, dynamic> fixture() => {
        'title': 'Harbor Song',
        'artist': 'Lantern Coast',
        'recordingEdition': 'Original studio performance',
        'recordingEditionStatus': 'verified',
        'expected': {
          'recordingReference': {
            'status': 'verified',
            'providerId': 'catalog',
            'candidateId': 'original',
            'recordingEdition': 'Original studio performance',
            'evidence': ['https://catalog.example.test/original'],
          },
        },
      };
      final song = fixture();
      expect(corpusRecordingReferenceMatches(song, candidate), isTrue);
      expect(corpusReviewedEditionMatches(song, candidate), isTrue);
      expect(
        corpusReviewedEditionMatches(
          song,
          const SongCandidate(
            providerId: 'catalog',
            id: 'live',
            title: 'Harbor Song',
            artist: 'Lantern Coast',
          ),
        ),
        isFalse,
      );
      expect(
        corpusRecordingReferenceMatches(
          song,
          const SongCandidate(
            providerId: 'catalog',
            id: 'original',
            title: 'Harbor Song (Live)',
            artist: 'Lantern Coast',
          ),
        ),
        isFalse,
      );
      final changedEdition = fixture()
        ..['recordingEdition'] = 'Live performance';
      expect(corpusReviewedEditionMatches(changedEdition, candidate), isFalse);
      final unreviewed = fixture()..['recordingEditionStatus'] = 'unverified';
      expect(corpusReviewedEditionMatches(unreviewed, candidate), isFalse);
      final noProof = fixture();
      ((noProof['expected'] as Map)['recordingReference'] as Map)['evidence'] =
          [];
      expect(corpusRecordingReferenceMatches(noProof, candidate), isFalse);
      expect(corpusReviewedEditionMatches(noProof, candidate), isFalse);
    },
  );
  test('reviewed catalog aliases select only the bound record and credits', () {
    const original = SongCandidate(
      providerId: 'catalog',
      id: 'original',
      title: '星の道 (Star Road)',
      artist: '夜の歌 (Night Songs)',
    );
    final song = <String, dynamic>{
      'title': 'Star Road',
      'artist': 'Night Songs',
      'catalogSelection': {
        'providerId': original.providerId,
        'candidateId': original.id,
        'title': original.title,
        'artist': original.artist,
        'evidence': ['https://example.org/official-release'],
      },
    };
    expect(matchesCorpusCandidate(song, original), isTrue);
    for (final candidate in [
      const SongCandidate(
        providerId: 'catalog',
        id: 'cover',
        title: 'Star Road',
        artist: 'Night Songs',
      ),
      const SongCandidate(
        providerId: 'another',
        id: 'original',
        title: '星の道 (Star Road)',
        artist: '夜の歌 (Night Songs)',
      ),
      const SongCandidate(
        providerId: 'catalog',
        id: 'original',
        title: '星の道 (Star Road)',
        artist: 'Different Performer',
      ),
    ]) {
      expect(matchesCorpusCandidate(song, candidate), isFalse);
    }
    (song['catalogSelection'] as Map)['evidence'] = <String>[];
    expect(matchesCorpusCandidate(song, original), isFalse);
    song.remove('catalogSelection');
    expect(matchesCorpusCandidate(song, original), isFalse);
    expect(
      matchesCorpusCandidate(
        song,
        const SongCandidate(
          providerId: 'catalog',
          id: 'exact',
          title: 'Star Road',
          artist: 'The Night Songs',
        ),
      ),
      isTrue,
    );
  });
  test(
    'accuracy distinguishes tonic and mode, retaining enharmonic equivalence',
    () {
      expect(_exactKeyIdentity('Am'), isNot(_exactKeyIdentity('C')));
      expect(_exactKeyIdentity('F#m'), _exactKeyIdentity('Gbm'));
      expect(_exactKeyIdentity('D mixolydian'), isNot(_exactKeyIdentity('G')));
      expect(_exactKeyIdentity('Eb major'), _exactKeyIdentity('D#'));
      expect(_exactKeyIdentity('B Minor'), _exactKeyIdentity('Bm'));
      expect(_exactKeyIdentity('C MAJOR'), _exactKeyIdentity('C'));
    },
  );
  test('chord accuracy includes word placement and sounding capo pitch', () {
    SongDocument song(String body, [int capo = 0]) => SongDocument(
      id: 'fixture',
      title: 'Original fixture',
      artist: 'Test',
      body: body,
      metadata: {'capo': capo},
    );
    expect(
      _chordAlignmentHash(song('[C]Amber windows')),
      isNot(_chordAlignmentHash(song('Amber [C]windows'))),
    );
    expect(
      _chordAlignmentHash(song('[C#]Amber windows')),
      _chordAlignmentHash(song('[Db]Amber windows')),
    );
    expect(
      _chordAlignmentHash(song('[C]Amber windows', 1)),
      _chordAlignmentHash(song('[Db]Amber windows')),
    );
  });
  test('source chord evidence uses the selected chart alignment hash', () {
    const candidate = SongCandidate(
      providerId: 'fixture',
      id: 'same-recording',
      title: 'Original fixture',
      artist: 'Test',
      metadata: {'capo': 1},
    );
    const source = SourceResult(
      candidate: candidate,
      body: '[C]Amber windows',
      metadata: {'capo': 1},
    );
    final selected = SongDocument(
      id: 'selected',
      title: 'Original fixture',
      artist: 'Test',
      body: '[Db]Amber windows',
    );
    expect(_sourceChordAlignmentHash(source), _chordAlignmentHash(selected));
  });
  test(
    'metadata accuracy corpus has 100 entries and valid reference states',
    () {
      final data = _readCorpus();
      final songs = (data['songs'] as List).cast<Map<String, dynamic>>();
      expect(songs, hasLength(100));
      expect(songs.map((s) => s['id']).toSet(), hasLength(100));
      expect(
        songs.take(88).map((s) => '${s['title']}|${s['artist']}').toSet(),
        hasLength(88),
      );
      for (final song in songs) {
        if (song['catalogSelection'] case final Map binding) {
          for (final key in ['providerId', 'candidateId', 'title', 'artist']) {
            expect(binding[key], isA<String>());
            expect((binding[key] as String).trim(), isNotEmpty);
          }
          expect(binding['evidence'], isNotEmpty);
        }
        final expected = song['expected'] as Map<String, dynamic>;
        expect(expected['status'], anyOf('unverified', 'verified'));
        final recordingReference =
            expected['recordingReference'] as Map<String, dynamic>;
        expect(recordingReference['status'], anyOf('unverified', 'verified'));
        if (recordingReference['status'] == 'verified') {
          expect(recordingReference['evidence'], isNotEmpty);
          expect(
            (recordingReference['providerId'] is String &&
                    recordingReference['candidateId'] is String) ||
                recordingReference['isrc'] is String,
            isTrue,
          );
        }
        final fields = expected['fields'] as Map<String, dynamic>;
        for (final field in _fields) {
          final reference = fields[field] as Map<String, dynamic>;
          expect(reference['status'], anyOf('unverified', 'verified'));
          if (reference['status'] == 'verified') {
            expect(
              reference['evidence'],
              isNotEmpty,
              reason: '${song['id']} $field',
            );
            expect(
              reference['value'],
              isA<String>(),
              reason: '${song['id']} $field',
            );
            final value = reference['value'] as String;
            expect(
              field == 'key'
                  ? _exactKeyIdentity(value) != null
                  : RegExp(r'^[0-9a-f]{64}$').hasMatch(value),
              isTrue,
              reason: '${song['id']} $field reference format',
            );
          }
        }
      }
    },
  );

  if (_runAudit) {
    test(
      '100-song cache-first benchmark',
      _benchmark,
      timeout: const Timeout(Duration(hours: 2)),
    );
  }
}

Future<void> _benchmark() async {
  final data = _readCorpus();
  final songs = (data['songs'] as List).cast<Map<String, dynamic>>();
  if (_maxNetwork != 0) {
    throw StateError(
      'This harness is offline-only; METADATA_BENCHMARK_MAX_NETWORK must be 0.',
    );
  }
  final client = MetadataResponseCacheClient(
    Directory(_cachePath),
    offline: true,
    jitter: _jitterSeed < 0 ? null : math.Random(_jitterSeed),
  );
  final transport = ProviderTransport(
    client: client,
    hostInterval: Duration.zero,
    maxRetries: 0,
  );
  // A nonempty placeholder enables cached Genius requests without loading a secret.
  final discovery = SourceDiscoveryService([
    ...createCoreProviders(
      transport: transport,
      geniusToken: 'cached-benchmark-no-network',
    ),
    ...createExtraProviders(transport: transport),
  ], recordingKeys: RecordingKeyService(transport));
  final catalogIds = {
    for (final p in discovery.definitions)
      if (p.capabilities.contains('catalog') &&
          p.configured &&
          p.enabledByDefault)
        p.id,
  };
  final fieldCounts = {
    for (final field in _fields)
      field: {
        'verifiedCorrect': 0,
        'verifiedIncorrect': 0,
        'scopeMismatch': 0,
        'unverified': 0,
        'unavailable': 0,
      },
  };
  final rows = <Map<String, Object?>>[];

  for (final song in songs) {
    final title = song['title'] as String;
    final artist = song['artist'] as String;
    final edition = song['recordingEdition'] as String?;
    final expected = song['expected'] as Map<String, dynamic>;
    final expectedFields = expected['fields'] as Map<String, dynamic>;
    final row = <String, Object?>{
      'id': song['id'],
      'title': title,
      'artist': artist,
      'recordingEdition': edition,
      'recordingEditionStatus':
          song['recordingEditionStatus'] ??
          (edition == null ? 'unspecified' : 'unverified'),
      'expectedStatus': expected['status'],
      'evidence': expected['evidence'],
    };
    var unavailable = false;
    try {
      // Use the collector's bounded query fallbacks. Edition verification is
      // separate: appending a prose edition label here invents a cache miss.
      final query = '$title $artist';
      final found = <SongCandidate>[];
      for (final searchQuery in [query, '$artist $title', title]) {
        found.addAll(
          await discovery.searchAcrossCatalogs(
            searchQuery,
            primaryProviderId: 'genius',
            enabledIds: catalogIds,
          ),
        );
        if (found.any((c) => matchesCorpusCandidate(song, c))) {
          break;
        }
      }
      final ranked = found.indexed.toList()
        ..sort((a, b) {
          final ap = a.$2.providerId == 'genius' ? 0 : 1;
          final bp = b.$2.providerId == 'genius' ? 0 : 1;
          if (ap != bp) return ap.compareTo(bp);
          final relevance = searchRelevance(
            b.$2,
            query,
          ).compareTo(searchRelevance(a.$2, query));
          if (relevance != 0) return relevance;
          final titleOrder = _normalize(
            a.$2.title,
          ).compareTo(_normalize(b.$2.title));
          if (titleOrder != 0) return titleOrder;
          final artistOrder = _normalize(
            a.$2.artist,
          ).compareTo(_normalize(b.$2.artist));
          return artistOrder != 0
              ? artistOrder
              : a.$2.providerId.compareTo(b.$2.providerId);
        });
      final groups = groupSearchRecordings(
        ranked.map((e) => e.$2),
        preferredProviderId: 'genius',
      );
      bool matches(SongCandidate c) => matchesCorpusCandidate(song, c);
      final group = groups.where((g) => matches(g.representative)).firstOrNull;
      if (group == null) {
        throw const ProviderException(
          'unavailable',
          'no exact title/artist match',
        );
      }
      final selected = group.representative;
      final recordingReferenceAnchored = corpusRecordingReferenceMatches(
        song,
        selected,
      );
      row['recordingReferenceAnchored'] = recordingReferenceAnchored;

      if (edition != null) {
        final editionNorm = _normalize(edition);
        final evidence = <String?>[
          selected.title,
          for (final key in [
            'version',
            'edition',
            'disambiguation',
            'recording',
          ])
            selected.metadata[key] is String
                ? selected.metadata[key] as String
                : null,
          selected.extra['version'] is String
              ? selected.extra['version'] as String
              : null,
          selected.extra['edition'] is String
              ? selected.extra['edition'] as String
              : null,
        ].whereType<String>().map(_normalize);
        final catalogEditionTextMatched = evidence.any(
          (v) => v.contains(editionNorm),
        );
        final reviewedEdition = corpusReviewedEditionMatches(song, selected);
        row['catalogEditionTextMatched'] = catalogEditionTextMatched;
        row['recordingEditionAnchored'] =
            reviewedEdition || catalogEditionTextMatched;
        row['recordingEditionEvidence'] = reviewedEdition
            ? 'reviewed_recording_reference'
            : catalogEditionTextMatched
            ? 'catalog_text'
            : null;
      } else {
        row['recordingEditionAnchored'] = null;
        row['catalogEditionTextMatched'] = null;
        row['recordingEditionEvidence'] = null;
      }
      // Check every alternate member against the selected candidate's explicit
      // edition signals; conflicts make recording-specific fields unavailable.
      final compatibleMembers = group.members
          .where((candidate) => explicitEditionsCompatible(selected, candidate))
          .toList();
      row['editionCompatibleMemberCount'] = compatibleMembers.length;
      final results = await discovery.discover(selected);
      final sourceSummaries = <Map<String, Object?>>[];
      for (final source in results) {
        final sourceLyrics = _normalizedLyrics(source.body);
        final sourceArrangement = parseArrangement(source.body);
        final sourceChordSequence = sourceArrangement
            .expand((line) => line.chords.map((annotation) => annotation.chord))
            .join(' ');
        sourceSummaries.add({
          'provider': source.candidate.providerId,
          // Stable join key for tying a discovered candidate to the source
          // contribution recorded by combineSources, without retaining its
          // catalog ID in the report.
          'sourceIdentitySha256': _sha(source.id),
          'candidateIdSha256': _sha(source.candidate.id),
          'match': source.matchKind.name,
          'reason': source.matchReason,
          'recordingCompatible': recordingCompatible(selected, source),
          'lyricWordCount': sourceLyrics.isEmpty
              ? 0
              : sourceLyrics.split(' ').length,
          // Hashes support private exact-text and arrangement comparisons
          // without copying copyrighted source bodies into the audit report.
          'normalizedLyricsSha256': sourceLyrics.isEmpty
              ? null
              : _sha(sourceLyrics),
          'chordCount': sourceArrangement.fold<int>(
            0,
            (count, line) => count + line.chords.length,
          ),
          'chordSequenceSha256': sourceChordSequence.isEmpty
              ? null
              : _sha(sourceChordSequence),
          // Keep the raw chord spelling hash above for transcription diffs;
          // agreement with the selected chart must use the same lyric-anchor,
          // capo-normalized representation as the selected output.
          'chordAlignmentSha256': _sourceChordAlignmentHash(source),
          'declaredKey':
              source.metadata['key'] ?? source.candidate.metadata['key'],
          'capo': source.metadata['capo'] ?? source.candidate.metadata['capo'],
          'keyConsensus': source.extra['keyConsensus'],
          'keyShift': source.extra['keyShift'],
          'requiresLyricsAgreement': source.extra['requiresLyricsAgreement'],
        });
      }
      row['sourceSummary'] = sourceSummaries;
      final compatibleResults = results
          .where(
            (r) => explicitEditionsCompatible(
              selected,
              r.candidate,
              metadata: r.metadata,
              extra: r.extra,
            ),
          )
          .toList();
      final doc = combineSources(selected, compatibleResults);
      final selectedSourceId = doc.extra['selectedSourceId'];
      final chordSourceIds = (doc.extra['chordSourceIds'] as List? ?? const [])
          .whereType<String>()
          .toSet();
      final sectionSourceIds =
          (doc.extra['sectionSourceIds'] as List? ?? const [])
              .whereType<String>()
              .toSet();
      final fieldContributors = doc.extra['fieldContributors'] is Map
          ? (doc.extra['fieldContributors'] as Map).map(
              (field, ids) => MapEntry(
                field.toString(),
                (ids is List ? ids : const []).whereType<String>().toSet(),
              ),
            )
          : <String, Set<String>>{};
      final arrangement = parseArrangement(doc.body);
      final combinedHasChords = arrangement.any(
        (line) => line.chords.isNotEmpty,
      );
      final combinedHasSections = arrangement.any(
        (line) => sectionLabelForLine(line) != null,
      );
      for (final summary in sourceSummaries) {
        final identityHash = summary['sourceIdentitySha256'];
        final source = results
            .where((candidate) => _sha(candidate.id) == identityHash)
            .firstOrNull;
        if (source == null) continue;
        summary['combinedContribution'] = {
          'selectedBaseLyrics': selectedSourceId == source.id,
          'chords': combinedHasChords && chordSourceIds.contains(source.id),
          'sections':
              combinedHasSections && sectionSourceIds.contains(source.id),
          'metadataFields':
              fieldContributors.entries
                  .where((entry) => entry.value.contains(source.id))
                  .map((entry) => entry.key)
                  .toList()
                ..sort(),
        };
      }
      final normalizedLyrics = _normalizedLyrics(doc.body);
      final lyricsHash = normalizedLyrics.isEmpty
          ? null
          : _sha(normalizedLyrics);
      final chordSequence = arrangement
          .expand((l) => l.chords.map((a) => a.chord))
          .join(' ');
      final key = _soundingKey(doc);
      final keyClaimScope = _keyClaimScope(doc);
      final identityReady =
          recordingReferenceAnchored &&
          (edition == null || row['recordingEditionAnchored'] == true);
      row.addAll({
        'selectedProvider': selected.providerId,
        'selectedTitle': selected.title,
        'selectedArtist': selected.artist,
        'selectedAlbum': selected.album,
        'selectedDurationSeconds': selected.durationSeconds,
        'sourceIds': (contributingProviderIds(doc).toList()..sort()),
        'normalizedLyricsSha256': lyricsHash,
        'key': key,
        'keyEvidence': doc.metadata['key'] != null
            ? 'source'
            : checkedChordKeyEstimate(doc) != null
            ? 'checkedChartEstimate'
            : key != null
            ? 'chartEstimate'
            : null,
        'keyClaimScope': key == null ? null : keyClaimScope,
        'capo': doc.metadata['capo'],
        'chordAlignmentSha256': _chordAlignmentHash(doc),
        'baseLyricsSourceId': doc.extra['selectedSourceId'],
        'chordSequenceSha256': chordSequence.isEmpty
            ? null
            : _sha(chordSequence),
        'lineCount': arrangement
            .where((l) => !l.directive && l.text.trim().isNotEmpty)
            .length,
        'chordedLineCount': arrangement
            .where((l) => l.chords.isNotEmpty)
            .length,
      });
      final fieldResults = <String, String>{};
      for (final field in _fields) {
        final reference = expectedFields[field] as Map<String, dynamic>;
        final verified =
            reference['status'] == 'verified' &&
            reference['value'] != null &&
            (reference['evidence'] as List? ?? []).isNotEmpty;
        if (!compatibleMembers.contains(selected)) {
          fieldResults[field] = 'unavailable';
          continue;
        }
        final actual = switch (field) {
          'lyrics' => lyricsHash,
          'key' => key,
          'chords' => _chordAlignmentHash(doc),
          _ => null,
        };
        if (actual == null) {
          fieldResults[field] = 'unavailable';
          continue;
        }
        if (!identityReady || !verified) {
          fieldResults[field] = 'unverified';
          continue;
        }
        final matchesReference = switch (field) {
          'key' =>
            _exactKeyIdentity(actual) != null &&
                _exactKeyIdentity(actual) ==
                    _exactKeyIdentity(reference['value'] as String),
          _ => actual == reference['value'],
        };
        final status = field == 'key'
            ? _keyComparisonStatus(
                matchesReference: matchesReference,
                claimScope: keyClaimScope,
              )
            : matchesReference
            ? 'verifiedCorrect'
            : 'verifiedIncorrect';
        fieldResults[field] = status;
      }
      row['fieldResults'] = fieldResults;
    } on ProviderException catch (e) {
      unavailable = true;
      row['availability'] = 'unavailable';
      row['errorCode'] = e.code;
    } on FormatException catch (e) {
      unavailable = true;
      const reasons = {
        'No matching lyrics are available to save.': 'no_matching_lyrics',
        'No complete matching lyrics are available.': 'no_complete_lyrics',
      };
      final reason = reasons[e.message];
      row['availability'] = reason == null ? 'error' : 'unavailable';
      row['errorType'] = e.runtimeType.toString();
      if (reason != null) row['errorCode'] = reason;
    } catch (e) {
      unavailable = true;
      row['availability'] = 'error';
      row['errorType'] = e.runtimeType.toString();
    }
    if (unavailable) {
      row['fieldResults'] = {for (final field in _fields) field: 'unavailable'};
    }
    for (final field in _fields) {
      final status = (row['fieldResults'] as Map)[field] as String;
      final counts = fieldCounts[field]!;
      counts[status] = counts[status]! + 1;
    }
    rows.add(row);
    print(
      'BENCHMARK_SONG ${rows.length}/${songs.length} ${song['id']} ${jsonEncode(row['fieldResults'])}',
    );
  }
  final accuracy = <String, Object?>{};
  // Keep source availability distinct from evidence-backed accuracy. The
  // collector can return useful candidate data even when the corpus has no
  // reviewed gold reference yet; that is a coverage gap, not a failed
  // comparison.
  final sourceCoverage = <String, Object?>{};
  for (final field in _fields) {
    final counts = fieldCounts[field]!;
    final correct = counts['verifiedCorrect']!;
    final evaluated = correct + counts['verifiedIncorrect']!;
    final refs = songs.where((song) {
      final expected = song['expected'] as Map;
      return (expected['recordingReference'] as Map)['status'] == 'verified' &&
          ((expected['fields'] as Map)[field] as Map)['status'] == 'verified';
    }).length;
    if (counts.values.fold<int>(0, (a, b) => a + b) != songs.length) {
      throw StateError(
        'Accuracy categories must account for every corpus song once',
      );
    }
    accuracy[field] = {
      ...counts,
      'denominator': songs.length,
      // An unevaluated song is not a failed comparison. Do not print a
      // misleading 0% corpus score until every row has a reviewed reference.
      'percent': _strictCorpusAccuracyPercent(
        correct: correct,
        evaluated: evaluated,
        corpusSize: songs.length,
      ),
      'strictCorpusAccuracyPercent': _strictCorpusAccuracyPercent(
        correct: correct,
        evaluated: evaluated,
        corpusSize: songs.length,
      ),
      'evaluationStatus': _accuracyEvaluationStatus(
        evaluated: evaluated,
        corpusSize: songs.length,
      ),
      'accuracyAmongEvaluatedPercent': evaluated == 0
          ? null
          : 100 * correct / evaluated,
      'referenceCoverage': refs,
      'evaluatedReferences': evaluated,
      'referenceCoveragePercent': 100 * refs / songs.length,
      'adjudicatedGoldReferenceCoverage': refs,
      'adjudicatedGoldReferenceCoveragePercent': 100 * refs / songs.length,
      'correctnessBasis':
          'Only reviewed field-level gold references with comparable output scope count here. A mismatching arrangement-scoped key is reported separately as scopeMismatch, not as a wrong recording key. Observed source pages and provider candidates are evidence coverage, not correctness comparisons.',
      'scopeMismatchMeaning': field == 'key'
          ? 'The selected key is supported as a chart/arrangement key, while the reviewed reference is the recording home key; the values are retained but not compared as like-scoped claims.'
          : null,
      'scopeMismatchesExcludedFromEvaluatedDenominator':
          counts['scopeMismatch'],
      'referenceCoverageMeaning':
          'Adjudicated field-level gold rows only; source-page observations are reported separately.',
    };

    bool hasFieldData(Map source) => switch (field) {
      'lyrics' => (source['lyricWordCount'] as num? ?? 0) > 0,
      'key' => source['declaredKey'] is String,
      'chords' => (source['chordCount'] as num? ?? 0) > 0,
      _ => false,
    };
    final candidateRows = <Map<String, Object?>>[];
    final compatibleCandidateRows = <Map<String, Object?>>[];
    final candidateProviders = <String>{};
    final compatibleCandidateProviders = <String>{};
    var baseLyricsContributionRows = 0;
    var chordContributionRows = 0;
    var sectionContributionRows = 0;
    final contributingProviders = <String>{};
    for (final row in rows) {
      final summaries = (row['sourceSummary'] as List? ?? const [])
          .whereType<Map>()
          .where(hasFieldData)
          .toList();
      if (summaries.isEmpty) continue;
      candidateRows.add(row);
      candidateProviders.addAll(
        summaries.map((source) => source['provider'] as String),
      );
      final compatible = summaries
          .where((source) => source['recordingCompatible'] == true)
          .toList();
      if (compatible.isNotEmpty) {
        compatibleCandidateRows.add(row);
        compatibleCandidateProviders.addAll(
          compatible.map((source) => source['provider'] as String),
        );
      }
      final contributors = (row['sourceSummary'] as List? ?? const [])
          .whereType<Map>()
          .whereType<Map<String, Object?>>();
      var rowHasBaseLyricsContribution = false;
      var rowHasChordContribution = false;
      var rowHasSectionContribution = false;
      for (final source in contributors) {
        final contribution = source['combinedContribution'];
        if (contribution is! Map) continue;
        final metadataFields =
            (contribution['metadataFields'] as List? ?? const [])
                .whereType<String>()
                .toSet();
        final used = switch (field) {
          'lyrics' =>
            contribution['selectedBaseLyrics'] == true ||
                contribution['sections'] == true,
          'chords' => contribution['chords'] == true,
          'key' =>
            metadataFields.contains('key') ||
                contribution['chords'] == true && row['key'] != null,
          _ => false,
        };
        if (used) contributingProviders.add(source['provider'] as String);
        if (field == 'lyrics' && contribution['selectedBaseLyrics'] == true) {
          rowHasBaseLyricsContribution = true;
        }
        if (field == 'chords' && contribution['chords'] == true) {
          rowHasChordContribution = true;
        }
        if (field == 'lyrics' && contribution['sections'] == true) {
          rowHasSectionContribution = true;
        }
      }
      if (rowHasBaseLyricsContribution) baseLyricsContributionRows++;
      if (rowHasChordContribution) chordContributionRows++;
      if (rowHasSectionContribution) sectionContributionRows++;
    }
    final selectedValueRows = rows.where((row) {
      final value = switch (field) {
        'lyrics' => row['normalizedLyricsSha256'],
        'key' => row['key'],
        'chords' => row['chordSequenceSha256'],
        _ => null,
      };
      return value != null;
    }).length;
    sourceCoverage[field] = {
      'songsWithCandidateData': candidateRows.length,
      'candidateProviderCount': candidateProviders.length,
      'songsWithRecordingCompatibleCandidateData':
          compatibleCandidateRows.length,
      'recordingCompatibleProviderCount': compatibleCandidateProviders.length,
      'songsWithSelectedValue': selectedValueRows,
      'songsWithSelectedBaseLyricsContribution': field == 'lyrics'
          ? baseLyricsContributionRows
          : null,
      'songsWithChordChartContribution': field == 'chords'
          ? chordContributionRows
          : null,
      'songsWithSectionContribution': field == 'lyrics'
          ? sectionContributionRows
          : null,
      'contributingProviderCount': contributingProviders.length,
      'corpusRowsWithVerifiedClaim': refs,
      'rowsWithAdjudicatedCorrectnessReference': refs,
      'comparisonsEvaluated': evaluated,
      'compatibilityBasis':
          'Programmatic recordingCompatible(selected, source) result; this is not independent proof of exact master identity or field correctness.',
      'referenceCoverageMeaning':
          'Count of corpus rows with reviewed field-level correctness gold; this is not a count of source pages discovered or checked.',
    };
  }
  Map<String, Object?> sourceAgreement(
    String hashField, {
    String? selectedHashField,
  }) {
    var songsWithSources = 0;
    var songsWithOneTextVariant = 0;
    var songsWithConflictingVariants = 0;
    var songsWithAnyCrossProviderAgreement = 0;
    var songsWithSingleProviderOnly = 0;
    var selectedOutputsWithCrossProviderSupport = 0;
    var selectedOutputsWithMaxSupport = 0;
    var selectedOutputsWithOnlySingleProvider = 0;
    var selectedOutputsWithSharedAlternativeButSingleSupport = 0;
    var selectedOutputRows = 0;
    final selectedSupportCounts = <String, int>{};
    final selectedOutputReviewCandidates = <Map<String, Object?>>[];
    final variantCounts = <String, int>{};
    for (final row in rows) {
      final sources = (row['sourceSummary'] as List? ?? const [])
          .whereType<Map>()
          .where((source) => source[hashField] is String)
          .toList();
      if (hashField == 'normalizedLyricsSha256') {
        row['practicalLyricsSupport'] = _selectedLyricsSupport(
          selectedHash: row['normalizedLyricsSha256'] as String?,
          sources: (row['sourceSummary'] as List? ?? const []).whereType<Map>(),
        );
      }
      if (sources.isEmpty) continue;
      songsWithSources++;
      final hashes = <String, List<Map>>{};
      for (final source in sources) {
        (hashes[source[hashField] as String] ??= []).add(source);
      }
      final variantCount = hashes.length;
      variantCounts['$variantCount'] =
          (variantCounts['$variantCount'] ?? 0) + 1;
      final hasSharedVariant = hashes.values.any((group) {
        final providers = group
            .map((source) => source['provider'] as String)
            .toSet();
        return providers.length > 1;
      });
      if (hasSharedVariant) songsWithAnyCrossProviderAgreement++;
      if (selectedHashField != null && row[selectedHashField] is String) {
        selectedOutputRows++;
        final selectedHash = row[selectedHashField] as String;
        final selectedSupport = (hashes[selectedHash] ?? const <Map>[])
            .map((source) => source['provider'] as String)
            .toSet()
            .length;
        selectedSupportCounts['$selectedSupport'] =
            (selectedSupportCounts['$selectedSupport'] ?? 0) + 1;
        if (selectedSupport > 1) {
          selectedOutputsWithCrossProviderSupport++;
        } else if (selectedSupport == 1) {
          selectedOutputsWithOnlySingleProvider++;
          if (hasSharedVariant) {
            selectedOutputsWithSharedAlternativeButSingleSupport++;
            final alternatives =
                hashes.entries
                    .where((entry) => entry.key != selectedHash)
                    .map((entry) {
                      final providers =
                          entry.value
                              .map((source) => source['provider'] as String)
                              .toSet()
                              .toList()
                            ..sort();
                      return (hash: entry.key, providers: providers);
                    })
                    .where((entry) => entry.providers.length > 1)
                    .toList()
                  ..sort((a, b) {
                    final support = b.providers.length.compareTo(
                      a.providers.length,
                    );
                    return support != 0 ? support : a.hash.compareTo(b.hash);
                  });
            selectedOutputReviewCandidates.add({
              'songId': row['id'],
              'title': row['selectedTitle'] ?? row['title'],
              'artist': row['selectedArtist'] ?? row['artist'],
              'recordingEditionStatus': row['recordingEditionStatus'],
              'selectedProviderLabels':
                  hashes[selectedHash]!
                      .map((source) => source['provider'] as String)
                      .toSet()
                      .toList()
                    ..sort(),
              'alternativeSharedHashGroups': alternatives
                  .map(
                    (entry) => {
                      'normalizedHashSha256': entry.hash,
                      'providerLabels': entry.providers,
                      'providerLabelCount': entry.providers.length,
                    },
                  )
                  .toList(),
            });
          }
        }
        final maxSupport = hashes.values
            .map(
              (group) => group
                  .map((source) => source['provider'] as String)
                  .toSet()
                  .length,
            )
            .fold<int>(0, (max, count) => count > max ? count : max);
        if (selectedSupport == maxSupport) selectedOutputsWithMaxSupport++;
      }
      if (variantCount == 1) {
        songsWithOneTextVariant++;
        final providers = hashes.values.single
            .map((source) => source['provider'] as String)
            .toSet();
        if (providers.length == 1) {
          songsWithSingleProviderOnly++;
        }
      } else {
        songsWithConflictingVariants++;
      }
    }
    return {
      'songsWithSourceData': songsWithSources,
      'songsWithOneHashVariant': songsWithOneTextVariant,
      'songsWithMultipleHashVariants': songsWithConflictingVariants,
      'songsWithAtLeastOneHashSharedAcrossProviderLabels':
          songsWithAnyCrossProviderAgreement,
      'songsWithOneProviderLabelOnly': songsWithSingleProviderOnly,
      'hashVariantCountDistribution': variantCounts,
      if (selectedHashField != null) ...{
        'selectedOutputRows': selectedOutputRows,
        'selectedOutputHashProviderSupportCounts': selectedSupportCounts,
        'selectedOutputHashHasCrossProviderSupport':
            selectedOutputsWithCrossProviderSupport,
        'selectedOutputHashHasOnlyOneProviderLabel':
            selectedOutputsWithOnlySingleProvider,
        'selectedOutputHasSharedAlternativeButChosenHashHasOneProvider':
            selectedOutputsWithSharedAlternativeButSingleSupport,
        'selectedOutputReviewCandidates': selectedOutputReviewCandidates,
        'selectedOutputHashHasMaximumProviderLabelSupport':
            selectedOutputsWithMaxSupport,
      },
      'interpretation':
          'Exact normalized lyric or chord-sequence hash agreement, including a shared hash within a conflicting group, is a consolidation signal, not proof of independent provenance or correctness.',
    };
  }

  final sourceAgreementSummary = {
    'lyrics': sourceAgreement(
      'normalizedLyricsSha256',
      selectedHashField: 'normalizedLyricsSha256',
    ),
    'chords': sourceAgreement(
      'chordSequenceSha256',
      selectedHashField: 'chordSequenceSha256',
    ),
    'chordAlignment': sourceAgreement(
      'chordAlignmentSha256',
      selectedHashField: 'chordAlignmentSha256',
    ),
  };
  final reusedCatalogIds = <String, Object?>{};
  var songsWithCrossProviderIdReuse = 0;
  var crossProviderIdGroups = 0;
  var groupsWithDifferentLyrics = 0;
  var groupsWithSameLyrics = 0;
  final providerPairs = <String, int>{};
  for (final row in rows) {
    final sources = (row['sourceSummary'] as List? ?? const [])
        .whereType<Map>()
        .where((source) => source['candidateIdSha256'] is String)
        .toList();
    final groups = <String, List<Map>>{};
    for (final source in sources) {
      (groups[source['candidateIdSha256'] as String] ??= []).add(source);
    }
    final reused = groups.entries.where((entry) {
      return entry.value
              .map((source) => source['provider'] as String)
              .toSet()
              .length >
          1;
    }).toList();
    if (reused.isEmpty) continue;
    songsWithCrossProviderIdReuse++;
    for (final entry in reused) {
      crossProviderIdGroups++;
      final providers =
          entry.value
              .map((source) => source['provider'] as String)
              .toSet()
              .toList()
            ..sort();
      final pair = providers.join('+');
      providerPairs[pair] = (providerPairs[pair] ?? 0) + 1;
      final lyricHashes = entry.value
          .map((source) => source['normalizedLyricsSha256'])
          .whereType<String>()
          .toSet();
      if (lyricHashes.length > 1) {
        groupsWithDifferentLyrics++;
      } else if (lyricHashes.length == 1) {
        groupsWithSameLyrics++;
      }
    }
  }
  reusedCatalogIds.addAll({
    'songsWithCrossProviderIdReuse': songsWithCrossProviderIdReuse,
    'crossProviderIdGroups': crossProviderIdGroups,
    'groupsWithDifferentLyricsHashes': groupsWithDifferentLyrics,
    'groupsWithSameLyricsHash': groupsWithSameLyrics,
    'providerPairGroupCounts': providerPairs,
    'betterLyricsAdapterNote':
        'BetterLyrics uses LRCLIB as its catalog and then resolves lyric content through the Better Lyrics API; a shared catalog ID does not guarantee identical lyric payloads.',
    'interpretation':
        'Candidate-ID reuse across provider adapters is not enough to merge or count evidence as independent; compare field payload hashes and provider provenance.',
  });
  final report = {
    'mode': 'offline-cache-first',
    'jitterSeed': _jitterSeed,
    'maxNetworkRequests': 0,
    'corpusSize': songs.length,
    'coverage': rows.where((r) => r.containsKey('selectedProvider')).length,
    'unavailableCount': rows.where((r) => r['availability'] != null).length,
    'accuracy': accuracy,
    'keyScopePolicy':
        'A chart-sourced key that is not recordingCompatible with the selected recording remains available as an arrangement key. If it differs from a recording-home-key reference, report scopeMismatch separately instead of calling it a verified incorrect recording key.',
    'sourceCoverage': sourceCoverage,
    'sourceAgreement': sourceAgreementSummary,
    'crossProviderCandidateIdReuse': reusedCatalogIds,
    'cache': {
      'hits': client.hits,
      'networkAttempts': client.networkAttempts,
      'uncachedOffline': client.uncached,
    },
    'songs': rows,
  };
  final out = Directory('build/metadata_accuracy');
  out.createSync(recursive: true);
  File(
    '${out.path}/report.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  print(
    'METADATA_ACCURACY ${jsonEncode({'coverage': report['coverage'], 'corpusSize': songs.length, 'unavailableCount': report['unavailableCount'], 'sourceCoverage': sourceCoverage, 'sourceAgreement': sourceAgreementSummary, 'crossProviderCandidateIdReuse': reusedCatalogIds, 'accuracy': accuracy, 'cacheHits': client.hits, 'uncachedOffline': client.uncached})}',
  );
  await transport.close();
}
