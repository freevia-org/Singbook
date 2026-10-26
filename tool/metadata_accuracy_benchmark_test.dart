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
      final arrangement = parseArrangement(doc.body);
      final normalizedLyrics = _normalizedLyrics(doc.body);
      final lyricsHash = normalizedLyrics.isEmpty
          ? null
          : _sha(normalizedLyrics);
      final chordSequence = arrangement
          .expand((l) => l.chords.map((a) => a.chord))
          .join(' ');
      final key = _soundingKey(doc);
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
        final status = matchesReference
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
      // Keep the strict corpus score for the 100-song goal, but make a lack
      // of reviewed references distinguishable from actual failed checks.
      'percent': 100 * correct / songs.length,
      'evaluationStatus': evaluated == 0
          ? 'no_reference_comparisons'
          : evaluated == songs.length
          ? 'all_songs_compared'
          : 'partial_reference_coverage',
      'accuracyAmongEvaluatedPercent': evaluated == 0
          ? null
          : 100 * correct / evaluated,
      'referenceCoverage': refs,
      'evaluatedReferences': evaluated,
      'referenceCoveragePercent': 100 * refs / songs.length,
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
      'corpusRowsWithVerifiedClaim': refs,
      'comparisonsEvaluated': evaluated,
      'compatibilityBasis':
          'Programmatic recordingCompatible(selected, source) result; this is not independent proof of exact master identity or field correctness.',
    };
  }
  Map<String, Object?> sourceAgreement(String hashField) {
    var songsWithSources = 0;
    var songsWithOneTextVariant = 0;
    var songsWithConflictingVariants = 0;
    var songsWithAnyCrossProviderAgreement = 0;
    var songsWithSingleProviderOnly = 0;
    final variantCounts = <String, int>{};
    for (final row in rows) {
      final sources = (row['sourceSummary'] as List? ?? const [])
          .whereType<Map>()
          .where((source) => source[hashField] is String)
          .toList();
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
      'interpretation':
          'Exact normalized lyric or chord-sequence hash agreement, including a shared hash within a conflicting group, is a consolidation signal, not proof of independent provenance or correctness.',
    };
  }

  final sourceAgreementSummary = {
    'lyrics': sourceAgreement('normalizedLyricsSha256'),
    'chords': sourceAgreement('chordSequenceSha256'),
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
