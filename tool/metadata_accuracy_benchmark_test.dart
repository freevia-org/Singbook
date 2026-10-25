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

void main() {
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
      final data =
          jsonDecode(
                File('tool/metadata_accuracy_corpus.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
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
  final data =
      jsonDecode(File('tool/metadata_accuracy_corpus.json').readAsStringSync())
          as Map<String, dynamic>;
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
      final recordingReference =
          expected['recordingReference'] as Map<String, dynamic>;
      final recordingReferenceAnchored =
          recordingReference['status'] == 'verified' &&
          (recordingReference['evidence'] as List).isNotEmpty &&
          ((recordingReference['providerId'] == selected.providerId &&
                  recordingReference['candidateId'] == selected.id) ||
              (recordingReference['isrc'] != null &&
                  recordingReference['isrc'] == selected.recordingIds['isrc']));
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
        row['recordingEditionAnchored'] = evidence.any(
          (v) => v.contains(editionNorm),
        );
      } else {
        row['recordingEditionAnchored'] = null;
      }
      // Check every alternate member against the selected candidate's explicit
      // edition signals; conflicts make recording-specific fields unavailable.
      final compatibleMembers = group.members
          .where((candidate) => explicitEditionsCompatible(selected, candidate))
          .toList();
      row['editionCompatibleMemberCount'] = compatibleMembers.length;
      final results = await discovery.discover(selected);
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
      final identityReady = recordingReferenceAnchored;
      row.addAll({
        'selectedProvider': selected.providerId,
        'selectedTitle': selected.title,
        'selectedArtist': selected.artist,
        'selectedAlbum': selected.album,
        'selectedDurationSeconds': selected.durationSeconds,
        'sourceIds': (contributingProviderIds(doc).toList()..sort()),
        'normalizedLyricsSha256': lyricsHash,
        'key': key,
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
      'percent': 100 * correct / songs.length,
      'referenceCoverage': refs,
      'evaluatedReferences': evaluated,
      'referenceCoveragePercent': 100 * refs / songs.length,
    };
  }
  final report = {
    'mode': 'offline-cache-first',
    'jitterSeed': _jitterSeed,
    'maxNetworkRequests': 0,
    'corpusSize': songs.length,
    'coverage': rows.where((r) => r.containsKey('selectedProvider')).length,
    'unavailableCount': rows.where((r) => r['availability'] != null).length,
    'accuracy': accuracy,
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
    'METADATA_ACCURACY ${jsonEncode({'coverage': report['coverage'], 'corpusSize': songs.length, 'unavailableCount': report['unavailableCount'], 'accuracy': accuracy, 'cacheHits': client.hits, 'uncachedOffline': client.uncached})}',
  );
  await transport.close();
}
