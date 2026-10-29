// ignore_for_file: avoid_print
// Opt-in metadata audit over the metadata accuracy corpus, outside the test
// suite:
//   flutter test tool/metadata_audit_test.dart \
//     [--dart-define=AUDIT_CORPUS=<corpus json>] [--dart-define=AUDIT_ONLY=Title]
//     [--dart-define=AUDIT_CACHE=<cache directory>]
//     [--dart-define=AUDIT_CATALOG=<source catalog json>]
//     [--dart-define=AUDIT_AS_OF=<ISO time>] [--dart-define=AUDIT_JITTER=<seed>]
//     [--dart-define=AUDIT_LIVE=true --dart-define=AUDIT_MAX_NETWORK=<n>]
// It runs under flutter test for the platform HTTP stack the app uses, with
// the providers of the app's bundled source catalog (as SourceCatalogRuntime
// applies it) and a fixed provider clock.
//
// Runs are offline by default: every response comes from the cache (by
// default build/metadata_audit/cache; the benchmark client's .json.gz
// entries are read too) and each request missing from it is journaled. Only
// AUDIT_LIVE with a positive AUDIT_MAX_NETWORK asks providers, at most that
// many times, for missing requests only. The report (build/metadata_audit/
// report.json) records the code, corpus, catalog, cache and clock it used,
// and holds identities, counts and chord symbols only, never lyrics or
// credentials.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chord_key_estimate.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/search_grouping.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/native_client.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';

const _corpusPath = String.fromEnvironment(
  'AUDIT_CORPUS',
  defaultValue: 'tool/metadata_accuracy_corpus.json',
);

/// (id, title, artist, legacy recording key hint) for each corpus song.
List<(String, String, String, String?)> _songs() {
  final corpus = jsonDecode(File(_corpusPath).readAsStringSync()) as Map;
  return [
    for (final raw in corpus['songs'] as List)
      if (raw case {
        'id': final String id,
        'title': final String title,
        'artist': final String artist,
      })
        (
          id,
          title,
          artist,
          (((raw['expected'] as Map?)?['legacyUnverifiedExpectation']
                  as Map?)?['recordingKey'])
              as String?,
        ),
  ];
}

/// Answers from the cache when it can; otherwise asks the network and keeps
/// successful and not-found answers. Keys leave out headers, so tokens are
/// never written.
class CachingClient extends http.BaseClient {
  CachingClient(
    this.directory, {
    required this.offline,
    this.jitter,
    this.networkBudget,
  });

  /// The most network requests one run may make; further misses fail as
  /// unavailable and are counted, so a run cannot exceed its allowance.
  final int? networkBudget;
  int overBudget = 0;

  final Directory directory;
  final bool offline;

  /// Random delays for cached answers, so replays can arrive in another
  /// order, as live responses do; differing results show order dependence.
  final math.Random? jitter;
  final http.Client _inner = createNativeHttpClient();
  int hits = 0, misses = 0, uncached = 0;
  final uncachedHosts = <String, int>{};

  /// Requests the cache could not answer, with the song that made them.
  final missJournal = <Map<String, Object?>>[];
  String? currentSong;
  void _journal(http.BaseRequest request, String outcome) => missJournal.add({
    'song': currentSong,
    'method': request.method,
    'host': request.url.host,
    'path': request.url.path,
    'outcome': outcome,
  });
  final storedStatuses = <int, int>{};

  final _nextAllowed = <String, DateTime>{};

  /// Hosts that answered 429 or 503, with the requests skipped since.
  final busyHosts = <String, int>{};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.body : '';
    final key = sha1
        .convert(utf8.encode('${request.method} ${request.url}\n$body'))
        .toString();
    final file = File('${directory.path}/$key.json');
    // The shared cache also holds the benchmark client's gzip entries.
    final packed = File('${directory.path}/$key.json.gz');
    if (packed.existsSync() || file.existsSync()) {
      hits++;
      if (jitter case final random?) {
        await Future<void>.delayed(Duration(milliseconds: random.nextInt(120)));
      }
      final stored =
          jsonDecode(
                packed.existsSync()
                    ? utf8.decode(gzip.decode(packed.readAsBytesSync()))
                    : file.readAsStringSync(),
              )
              as Map;
      return http.StreamedResponse(
        Stream.value(base64Decode(stored['body'] as String)),
        stored['status'] as int,
        headers: Map<String, String>.from(stored['headers'] as Map),
        request: request,
      );
    }
    if (offline) {
      uncached++;
      uncachedHosts.update(request.url.host, (n) => n + 1, ifAbsent: () => 1);
      _journal(request, 'offline');
      throw const ProviderException('unavailable', 'not in audit cache');
    }
    if (networkBudget case final budget? when misses >= budget) {
      overBudget++;
      _journal(request, 'over_budget');
      throw const ProviderException('unavailable', 'audit network budget');
    }
    // A host that answered busy is left alone for the rest of the run.
    if (busyHosts.containsKey(request.url.host)) {
      busyHosts.update(request.url.host, (n) => n + 1);
      _journal(request, 'host_backed_off');
      throw const ProviderException('provider_busy', 'audit host backed off');
    }
    misses++;
    // At most one network request per host every 1.2 s, the pace public
    // catalogs such as MusicBrainz ask of clients.
    final host = request.url.host;
    final previous = _nextAllowed[host];
    final now = DateTime.now();
    final start = previous != null && previous.isAfter(now) ? previous : now;
    _nextAllowed[host] = start.add(const Duration(milliseconds: 1200));
    if (start.isAfter(now)) await Future<void>.delayed(start.difference(now));
    final response = await _inner.send(request);
    final bytes = await response.stream.toBytes();
    storedStatuses.update(response.statusCode, (n) => n + 1, ifAbsent: () => 1);
    _journal(request, 'fetched_${response.statusCode}');
    if (const {429, 503}.contains(response.statusCode)) {
      busyHosts.putIfAbsent(request.url.host, () => 0);
    }
    // Refusals and not-found answers are kept too, so reruns do not repeat
    // them; rate limits and server errors are not.
    if (const {200, 401, 403, 404, 410}.contains(response.statusCode)) {
      directory.createSync(recursive: true);
      file.writeAsStringSync(
        jsonEncode({
          'url': request.url.replace(query: '').toString(),
          'status': response.statusCode,
          'headers': {
            if (response.headers['content-type'] case final String type)
              'content-type': type,
          },
          'body': base64Encode(bytes),
        }),
      );
    }
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

String _norm(String value) => value
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

void main() {
  test('metadata audit', _audit, timeout: const Timeout(Duration(hours: 2)));
}

/// A title without qualifiers ("(Remastered 2009)", "- Live").
String _baseTitle(String title) => _norm(
  title.replaceAll(RegExp(r'\s*[(\[][^()\[\]]*[)\]]|\s+[-–—]\s+.*$'), ''),
);

/// An artist's identifying words: every one must appear in a matching row.
Set<String> _artistWords(String artist) => {
  for (final word in _norm(artist.replaceAll('&', ' and ')).split(' '))
    if (!const {'the', 'and', ''}.contains(word)) word,
};

String _fileSha(String path) =>
    sha256.convert(File(path).readAsBytesSync()).toString();

/// Entry names and sizes: identifies a cache's contents without reading
/// every response.
Map<String, Object> _cacheFingerprint(Directory directory) {
  final entries = directory.existsSync()
      ? (directory
            .listSync()
            .whereType<File>()
            .map((f) => '${f.uri.pathSegments.last} ${f.lengthSync()}')
            .toList()
          ..sort())
      : <String>[];
  return {
    'path': directory.path,
    'entries': entries.length,
    'namesAndSizesSha256': sha256
        .convert(utf8.encode(entries.join('\n')))
        .toString(),
  };
}

Future<void> _audit() async {
  const live = bool.fromEnvironment('AUDIT_LIVE');
  const offline = !live;
  const budget = int.fromEnvironment('AUDIT_MAX_NETWORK');
  if (live && budget <= 0) {
    throw StateError('AUDIT_LIVE needs a positive AUDIT_MAX_NETWORK.');
  }
  const onlyValue = String.fromEnvironment('AUDIT_ONLY');
  // Several titles may be given, separated by "|".
  final only = onlyValue == '' ? null : onlyValue.split('|').toSet();
  const verbose = bool.fromEnvironment('AUDIT_VERBOSE');
  final out = Directory('build/metadata_audit');
  const jitterSeed = int.fromEnvironment('AUDIT_JITTER', defaultValue: -1);
  const cachePath = String.fromEnvironment('AUDIT_CACHE');
  const catalogPath = String.fromEnvironment(
    'AUDIT_CATALOG',
    defaultValue: 'config/source-catalog-v10.json',
  );
  final asOf = DateTime.parse(
    const String.fromEnvironment(
      'AUDIT_AS_OF',
      defaultValue: '2026-10-29T12:00:00Z',
    ),
  ).toUtc();
  final cacheDirectory = Directory(
    cachePath.isEmpty ? '${out.path}/cache' : cachePath,
  );
  final client = CachingClient(
    cacheDirectory,
    offline: offline,
    jitter: jitterSeed < 0 ? null : math.Random(jitterSeed),
    networkBudget: live ? budget : null,
  );
  // Offline, a placeholder enables cached Genius requests without a secret.
  var token = offline ? 'cached-audit-no-network' : '';
  for (final path in [
    'config/local.defines.json',
    '../Singbook/config/local.defines.json',
  ]) {
    final file = File(path);
    if (token.isEmpty && file.existsSync()) {
      token =
          (jsonDecode(file.readAsStringSync()) as Map)['GENIUS_ACCESS_TOKEN']
              as String? ??
          '';
    }
  }
  if (token.isEmpty) token = Platform.environment['GENIUS_ACCESS_TOKEN'] ?? '';
  final transport = ProviderTransport(
    client: client,
    hostInterval: offline ? Duration.zero : const Duration(milliseconds: 700),
    maxRetries: offline ? 0 : 3,
  );
  // The providers the app runs: compiled adapters as the bundled source
  // catalog configures, enables and adds to them.
  final catalog = SourceCatalog.parse(File(catalogPath).readAsStringSync());
  final runtime = SourceCatalogRuntime(
    builtins: [
      ...createCoreProviders(
        transport: transport,
        geniusToken: token,
        clock: () => asOf,
      ),
      ...createExtraProviders(transport: transport),
    ],
    createProvider: (entry) {
      ConfigurableProvider.validateExtraction(entry);
      return ConfigurableProvider(entry, transport);
    },
  )..apply(catalog);
  final discovery = SourceDiscoveryService(
    runtime.providers,
    recordingKeys: RecordingKeyService(transport),
  );
  final catalogs = {
    for (final p in discovery.definitions)
      if (p.capabilities.contains('catalog') &&
          p.configured &&
          p.enabledByDefault)
        p.id,
  };
  final run = {
    'head': Process.runSync('git', [
      'rev-parse',
      'HEAD',
    ]).stdout.toString().trim(),
    'dirty': Process.runSync('git', [
      'status',
      '--porcelain',
      'lib',
      'tool',
    ]).stdout.toString().trim().isNotEmpty,
    'harnessSha256': _fileSha('tool/metadata_audit_test.dart'),
    'corpus': {'path': _corpusPath, 'sha256': _fileSha(_corpusPath)},
    'catalog': {
      'path': catalogPath,
      'revision': catalog.revision,
      'sha256': _fileSha(catalogPath),
    },
    'asOf': asOf.toIso8601String(),
    'offline': offline,
    if (live) 'networkBudget': budget,
    'cacheBefore': _cacheFingerprint(cacheDirectory),
  };

  final rows = <Map<String, Object?>>[];
  final findings = <String, List<String>>{};
  for (final (id, title, artist, expectedKey) in _songs()) {
    if (only != null && !only.contains(title) && !only.contains(id)) continue;
    client.currentSong = id;
    final query = '$title $artist';
    final row = <String, Object?>{'id': id, 'title': title, 'artist': artist};
    final issues = <String>[];
    try {
      final found = await discovery.searchAcrossCatalogs(
        query,
        primaryProviderId: 'genius',
        enabledIds: catalogs,
      );
      // Rank like the app: preferred catalog first, then relevance.
      final ranked = found.indexed.toList()
        ..sort((a, b) {
          final provider = (a.$2.providerId == 'genius' ? 0 : 1).compareTo(
            b.$2.providerId == 'genius' ? 0 : 1,
          );
          if (provider != 0) return provider;
          final relevance = searchRelevance(
            b.$2,
            query,
          ).compareTo(searchRelevance(a.$2, query));
          return relevance != 0 ? relevance : a.$1.compareTo(b.$1);
        });
      final groups = groupSearchRecordings(
        ranked.map((e) => e.$2),
        preferredProviderId: 'genius',
      );
      bool isSong(SongCandidate c) =>
          _baseTitle(c.title) == _baseTitle(title) &&
          _artistWords(artist).every(_artistWords(c.artist).contains);
      final position = groups.indexWhere((g) => isSong(g.representative));
      row['searchRank'] = position < 0 ? null : position + 1;
      if (position < 0) {
        issues.add('search: not found');
        row['issues'] = issues;
        rows.add(row);
        continue;
      }
      if (position > 0) issues.add('search: original at rank ${position + 1}');
      final group = groups[position];
      if (group.artworkUrl == null) issues.add('search: no artwork');
      if (group.album == null) issues.add('search: no album');
      if (group.durationSeconds == null) issues.add('search: no duration');

      final selection = group.selection;
      if (verbose) {
        print(
          '   selected ${selection.providerId} album=${selection.album} '
          'dur=${selection.durationSeconds} group album=${group.album} '
          'dur=${group.durationSeconds} members='
          '${group.members.map((m) => '${m.providerId}:${m.album}:${m.durationSeconds}').join(', ')}',
        );
      }
      final checks = <String, ProviderCheck>{};
      final results = await discovery.discover(
        selection,
        onProgress: (check) => checks[check.providerId] = check,
      );
      if (verbose) {
        for (final check in checks.values) {
          print(
            '   check ${check.providerId}: ${check.state} ${check.code ?? ''} '
            '${check.operations.where((o) => o.state != 'completed').map((o) => '${o.phase}:${o.state}:${o.code ?? ''}').join(' ')}',
          );
        }
      }
      final doc = combineSources(selection, results);
      if (const bool.fromEnvironment('AUDIT_DUMP')) {
        final dir = Directory('build/metadata_audit/dump/$title')
          ..createSync(recursive: true);
        File('${dir.path}/combined.txt').writeAsStringSync(doc.body);
        for (final (i, r) in results.indexed) {
          File(
            '${dir.path}/$i-${r.candidate.providerId}-${r.matchKind.name}.txt',
          ).writeAsStringSync(r.body);
        }
      }
      if (verbose) {
        final reference = results
            .where((r) => r.matchKind == MatchKind.sameRecording)
            .firstOrNull;
        List<String> words(String body) => _norm(
          body
              .replaceAll(RegExp(r'\{[^}\n]*\}'), ' ')
              .replaceAll(RegExp(r'\[[^\]\n]*\]'), ''),
        ).split(' ').where((w) => w.isNotEmpty).toList();
        Set<String> bigrams(List<String> w) => {
          for (var i = 1; i < w.length; i++) '${w[i - 1]} ${w[i]}',
        };
        for (final r in results) {
          if (r.hasChords && reference != null) {
            final a = words(r.body), b = words(reference.body);
            final common = a.toSet().intersection(b.toSet());
            final ab = bigrams(a), bb = bigrams(b);
            final both = ab.intersection(bb);
            print(
              '   ~ ${r.candidate.providerId} ${r.candidate.title} / '
              '${r.candidate.artist}: common ${common.length}, '
              'of chart ${(common.length / a.toSet().length).toStringAsFixed(2)}, '
              'of ref ${(common.length / b.toSet().length).toStringAsFixed(2)}, '
              'bigrams ${(both.length / ab.length).toStringAsFixed(2)}/'
              '${(both.length / bb.length).toStringAsFixed(2)}',
            );
          }
          print(
            '   ${r.candidate.providerId} ${r.matchKind.name} '
            'chords=${r.hasChords} lines=${parseArrangement(r.body).length} '
            'album=${r.candidate.album ?? r.metadata['album']} '
            'dur=${r.candidate.durationSeconds ?? r.metadata['durationSeconds']} '
            'rec=${(r.extra['keyRecording'] as Map?)?['key']} '
            'capo=${r.metadata['capo'] ?? r.candidate.metadata['capo']} '
            'declared=${r.metadata['key'] ?? r.candidate.metadata['key']} '
            'shift=${r.extra['keyShift']} consensus=${r.extra['keyConsensus']} '
            'est=${r.hasChords ? estimateChordKey(r.body)?.key : ''} '
            'extra=${r.extra.keys.where((k) => !k.startsWith('_')).join(',')}',
          );
        }
      }
      final m = doc.metadata;
      if (verbose) {
        print(
          '   combined chordKeyEstimate=${doc.extra['chordKeyEstimate']} '
          'capo=${m['capo']} key=${m['key']} chordSources=${doc.extra['chordSourceIds']}',
        );
      }
      for (final field in ['album', 'artworkUrl', 'durationSeconds']) {
        if (m[field] == null) issues.add('combined: no $field');
      }
      if (m['year'] == null && m['releaseDate'] == null) {
        issues.add('combined: no year');
      }
      final lines = parseArrangement(
        doc.body,
      ).where((l) => !l.directive && l.text.trim().isNotEmpty).toList();
      final chorded = lines.where((l) => l.chords.isNotEmpty).length;
      row['lines'] = lines.length;
      row['chorded'] = chorded;
      if (verbose) {
        // One mark per lyric line, section breaks as spaces: # chorded, . not.
        final marks = StringBuffer();
        for (final line in parseArrangement(doc.body)) {
          if (line.directive || line.text.trim().isEmpty) {
            if (marks.isNotEmpty && !marks.toString().endsWith(' ')) {
              marks.write(' ');
            }
          } else {
            marks.write(line.chords.isEmpty ? '.' : '#');
          }
        }
        print('   coverage $marks');
      }
      if (chorded == 0) {
        issues.add('chords: none');
      } else if (chorded < lines.length * .8) {
        issues.add('chords: $chorded/${lines.length} lines');
      }
      // Chord order: every chorded line must appear, in order, in one of
      // the charts that gave chords, as moved by its key shift and any capo
      // difference from the other charts.
      final chordIds = {
        for (final id in (doc.extra['chordSourceIds'] as List? ?? const []))
          '$id',
      };
      final shifts = doc.extra['chordKeyShifts'] as Map? ?? const {};
      final charts = results.where((r) => chordIds.contains(r.id)).toList();
      int capoOf(SourceResult r) {
        final capo = r.metadata['capo'] ?? r.candidate.metadata['capo'];
        return capo is num ? capo.toInt() : int.tryParse('${capo ?? ''}') ?? 0;
      }

      final streams = <String>[
        for (final chart in charts)
          for (final other in charts)
            () {
              final shift = shifts[chart.id] is int
                  ? shifts[chart.id] as int
                  : 0;
              final move = (shift + capoOf(chart) - capoOf(other)) % 12;
              final body = move == 0
                  ? chart.body
                  : transposeBody(chart.body, move);
              return ' ${[for (final l in parseArrangement(body))
                for (final a in l.chords) a.chord].join(' ')} ';
            }(),
      ];
      var outOfOrder = 0;
      for (final line in lines.where((l) => l.chords.isNotEmpty)) {
        final sequence = ' ${line.chords.map((a) => a.chord).join(' ')} ';
        if (!streams.any((stream) => stream.contains(sequence))) outOfOrder++;
      }
      if (charts.isNotEmpty && outOfOrder > 0) {
        issues.add('chords: $outOfOrder lines out of chart order');
      }
      // The key a reader sees: the declared key, else the checked or
      // estimated one.
      final shown =
          (m['key'] as String?) ??
          checkedChordKeyEstimate(doc) ??
          estimateChordKey(doc.body)?.key;
      final capo = m['capo'];
      final frets = capo is num
          ? capo.toInt()
          : int.tryParse('${capo ?? ''}') ?? 0;
      final sounding = shown == null
          ? null
          : m['key'] != null || frets <= 0
          ? shown
          : transposeChord(shown, frets);
      row['key'] = sounding;
      // Where the key came from: a source's declaration, or inferred from
      // the chords (a checked estimate or the estimator).
      row['keyBasis'] = sounding == null
          ? null
          : m['key'] != null
          ? 'source'
          : 'inferred';
      row['capo'] = capo;
      if (chorded > 0 && sounding == null) issues.add('key: none');
      if (expectedKey != null &&
          sounding != null &&
          !keysAgree(sounding, expectedKey)) {
        issues.add('key: $sounding, expected $expectedKey');
      }
      row['sources'] = [
        for (final source in contributingProviderIds(doc)) source,
      ];
      // Presence: lyrics, chords on lyric lines and a key. Coverage is the
      // share of lyric lines with chords, reported but not a pass gate.
      row['present'] = {
        'lyrics': lines.isNotEmpty,
        'chords': chorded > 0,
        'key': sounding != null,
      };
      row['coverage'] = lines.isEmpty
          ? 0
          : double.parse((chorded / lines.length).toStringAsFixed(3));
    } on ProviderException catch (e) {
      issues.add('error: ${e.code}');
    } catch (e, stack) {
      issues.add('error: ${e.runtimeType}');
      if (verbose) print('   $e\n$stack');
    }
    row['issues'] = issues;
    rows.add(row);
    for (final issue in issues) {
      findings.putIfAbsent(issue.split(':').first, () => []).add(title);
    }
    print(
      '${issues.isEmpty ? 'OK ' : '-- '}$title — ${row['chorded']}/${row['lines']} '
      'key=${row['key']}${issues.isEmpty ? '' : ' | ${issues.join('; ')}'}',
    );
  }
  out.createSync(recursive: true);
  File('${out.path}/report.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'run': run,
      'cacheAfter': _cacheFingerprint(cacheDirectory),
      'cache': {
        'hits': client.hits,
        'misses': client.misses,
        'uncachedOffline': client.uncached,
        'overNetworkBudget': client.overBudget,
        'uncachedHosts': client.uncachedHosts,
        'busyHosts': client.busyHosts,
        'networkStatuses': {
          for (final e in client.storedStatuses.entries) '${e.key}': e.value,
        },
      },
      'missJournal': client.missJournal,
      'songs': rows,
    }),
  );
  bool present(Map<String, Object?> row) =>
      (row['present'] as Map?)?.values.every((value) => value == true) ?? false;
  print(
    '\n${rows.where(present).length}/${rows.length} songs with lyrics, chords '
    'and a key; '
    '${rows.where((r) => (r['issues'] as List).isEmpty).length}/${rows.length} '
    'songs without findings; cache hits ${client.hits}, misses ${client.misses}'
    '${client.uncached == 0 ? '' : '; ${client.uncached} requests not in the cache (rerun online)'}'
    '${client.overBudget == 0 ? '' : '; ${client.overBudget} requests refused over the network budget'}'
    '${client.busyHosts.isEmpty ? '' : '; busy hosts left alone: ${client.busyHosts}'}',
  );
  for (final entry in findings.entries) {
    print('${entry.key}: ${entry.value.length}');
  }
  transport.close();
}
