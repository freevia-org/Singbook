// ignore_for_file: avoid_print
// Opt-in metadata audit over a fixed song set, outside the test suite:
//   flutter test tool/metadata_audit_test.dart \
//     [--dart-define=AUDIT_OFFLINE=true] [--dart-define=AUDIT_ONLY=Title]
// It runs under flutter test for the platform HTTP stack the app uses.
//
// Every provider response is cached under build/metadata_audit/cache, keyed
// by request, so repeated runs work from stored results instead of asking
// the providers again; --offline never touches the network. The report
// (build/metadata_audit/report.json) and printed summary hold identities,
// counts and chord symbols only, never lyrics or credentials.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chord_key_estimate.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/search_grouping.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/native_client.dart';
import 'package:singbook/providers/provider.dart';

/// (title, artist, recording key when well documented).
const songs = <(String, String, String?)>[
  ('Tears in Heaven', 'Eric Clapton', 'A'),
  ('Lonely Stranger', 'Eric Clapton', 'E'),
  ('Wonderful Tonight', 'Eric Clapton', 'G'),
  ('Wonderwall', 'Oasis', 'F#m'),
  ('Hotel California', 'Eagles', 'Bm'),
  ('Let It Be', 'The Beatles', 'C'),
  ('Hey Jude', 'The Beatles', 'F'),
  ('Yesterday', 'The Beatles', 'F'),
  ('Here Comes the Sun', 'The Beatles', 'A'),
  ('Imagine', 'John Lennon', 'C'),
  ('Wish You Were Here', 'Pink Floyd', 'G'),
  ('Fast Car', 'Tracy Chapman', null),
  ('Hallelujah', 'Leonard Cohen', 'C'),
  ('Free Fallin\'', 'Tom Petty', 'F'),
  ('Stand By Me', 'Ben E. King', 'A'),
  ('Brown Eyed Girl', 'Van Morrison', 'G'),
  ('Sweet Home Alabama', 'Lynyrd Skynyrd', 'D'),
  ('Perfect', 'Ed Sheeran', 'Ab'),
  ('Thinking Out Loud', 'Ed Sheeran', 'D'),
  ('Shape of You', 'Ed Sheeran', 'C#m'),
  ('Zombie', 'The Cranberries', 'Em'),
  ('Creep', 'Radiohead', 'G'),
  ('Riptide', 'Vance Joy', null),
  ('Knockin\' on Heaven\'s Door', 'Bob Dylan', 'G'),
  ('Blowin\' in the Wind', 'Bob Dylan', 'D'),
  ('The House of the Rising Sun', 'The Animals', 'Am'),
  ('Losing My Religion', 'R.E.M.', 'Am'),
  ('Every Breath You Take', 'The Police', 'Ab'),
  ('Hey There Delilah', 'Plain White T\'s', 'D'),
  ('Have You Ever Seen the Rain', 'Creedence Clearwater Revival', 'C'),
  ('Take Me Home, Country Roads', 'John Denver', 'A'),
  ('Redemption Song', 'Bob Marley & The Wailers', 'G'),
  ('Three Little Birds', 'Bob Marley & The Wailers', 'A'),
  ('No Woman, No Cry', 'Bob Marley & The Wailers', 'C'),
  ('Jolene', 'Dolly Parton', 'C#m'),
  ('Ring of Fire', 'Johnny Cash', 'G'),
  ('Hurt', 'Johnny Cash', 'Am'),
  ('Shallow', 'Lady Gaga & Bradley Cooper', 'G'),
  ('Someone Like You', 'Adele', 'A'),
  ('Yellow', 'Coldplay', 'B'),
  ('Fix You', 'Coldplay', 'Eb'),
  ('Chasing Cars', 'Snow Patrol', 'A'),
  ('Boulevard of Broken Dreams', 'Green Day', 'Fm'),
  ('Good Riddance (Time of Your Life)', 'Green Day', 'G'),
  ('Black', 'Pearl Jam', 'E'),
  ('Nothing Else Matters', 'Metallica', 'Em'),
  ('Smells Like Teen Spirit', 'Nirvana', 'Fm'),
  ('Take Me to Church', 'Hozier', 'Em'),
  ('Ho Hey', 'The Lumineers', 'C'),
  ('Bohemian Rhapsody', 'Queen', 'Bb'),
  ('Despacito', 'Luis Fonsi', 'Bm'),
];

/// Answers from the cache when it can; otherwise asks the network and keeps
/// successful and not-found answers. Keys leave out headers, so tokens are
/// never written.
class CachingClient extends http.BaseClient {
  CachingClient(this.directory, {required this.offline});

  final Directory directory;
  final bool offline;
  final http.Client _inner = createNativeHttpClient();
  int hits = 0, misses = 0, uncached = 0;
  final uncachedHosts = <String, int>{};
  final storedStatuses = <int, int>{};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.body : '';
    final key = sha1
        .convert(utf8.encode('${request.method} ${request.url}\n$body'))
        .toString();
    final file = File('${directory.path}/$key.json');
    if (file.existsSync()) {
      hits++;
      final stored = jsonDecode(file.readAsStringSync()) as Map;
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
      throw const ProviderException('unavailable', 'not in audit cache');
    }
    misses++;
    final response = await _inner.send(request);
    final bytes = await response.stream.toBytes();
    storedStatuses.update(response.statusCode, (n) => n + 1, ifAbsent: () => 1);
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

Future<void> _audit() async {
  const offline = bool.fromEnvironment('AUDIT_OFFLINE');
  const onlyValue = String.fromEnvironment('AUDIT_ONLY');
  // Several titles may be given, separated by "|".
  final only = onlyValue == '' ? null : onlyValue.split('|').toSet();
  const verbose = bool.fromEnvironment('AUDIT_VERBOSE');
  final out = Directory('build/metadata_audit');
  final client = CachingClient(
    Directory('${out.path}/cache'),
    offline: offline,
  );
  var token = Platform.environment['GENIUS_ACCESS_TOKEN'] ?? '';
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
  final transport = ProviderTransport(
    client: client,
    hostInterval: offline ? Duration.zero : const Duration(milliseconds: 700),
  );
  final discovery = SourceDiscoveryService([
    ...createCoreProviders(transport: transport, geniusToken: token),
    ...createExtraProviders(transport: transport),
  ], recordingKeys: RecordingKeyService(transport));
  final catalogs = {
    for (final p in discovery.definitions)
      if (p.capabilities.contains('catalog') &&
          p.configured &&
          p.enabledByDefault)
        p.id,
  };

  final rows = <Map<String, Object?>>[];
  final findings = <String, List<String>>{};
  for (final (title, artist, expectedKey) in songs) {
    if (only != null && !only.contains(title)) continue;
    final query = '$title $artist';
    final row = <String, Object?>{'title': title, 'artist': artist};
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

      final selection = group.representative;
      final results = await discovery.discover(selection);
      final doc = combineSources(selection, results);
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
            'extra=${r.extra.keys.where((k) => !k.startsWith('_')).join(',')}',
          );
        }
      }
      final m = doc.metadata;
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
      if (chorded == 0) {
        issues.add('chords: none');
      } else if (chorded < lines.length * .8) {
        issues.add('chords: $chorded/${lines.length} lines');
      }
      // Chord order against the chart that gave the chords.
      final chordIds = {
        for (final id in (doc.extra['chordSourceIds'] as List? ?? const []))
          '$id',
      };
      final shifts = doc.extra['chordKeyShifts'] as Map? ?? const {};
      var outOfOrder = 0;
      for (final chart in results.where((r) => chordIds.contains(r.id))) {
        final shift = shifts[chart.id];
        final body = shift is int && shift % 12 != 0
            ? transposeBody(chart.body, shift)
            : chart.body;
        final stream =
            ' ${[for (final l in parseArrangement(body))
              for (final a in l.chords) a.chord].join(' ')} ';
        for (final line in lines.where((l) => l.chords.isNotEmpty)) {
          final sequence = line.chords.map((a) => a.chord).join(' ');
          if (!stream.contains(' $sequence ')) outOfOrder++;
        }
        break;
      }
      if (chordIds.length == 1 && outOfOrder > 0) {
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
      row['capo'] = capo;
      if (chorded > 0 && sounding == null) issues.add('key: none');
      if (expectedKey != null &&
          sounding != null &&
          !keysAgree(sounding, expectedKey)) {
        issues.add('key: $sounding, expected $expectedKey');
      }
      row['sources'] = [for (final id in contributingProviderIds(doc)) id];
    } on ProviderException catch (e) {
      issues.add('error: ${e.code}');
    } catch (e) {
      issues.add('error: ${e.runtimeType}');
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
      'offline': offline,
      'cache': {
        'hits': client.hits,
        'misses': client.misses,
        'uncachedOffline': client.uncached,
        'uncachedHosts': client.uncachedHosts,
        'networkStatuses': {
          for (final e in client.storedStatuses.entries) '${e.key}': e.value,
        },
      },
      'songs': rows,
    }),
  );
  print(
    '\n${rows.where((r) => (r['issues'] as List).isEmpty).length}/${rows.length} '
    'songs without findings; cache hits ${client.hits}, misses ${client.misses}'
    '${client.uncached == 0 ? '' : '; ${client.uncached} requests not in the cache (rerun online)'}',
  );
  for (final entry in findings.entries) {
    print('${entry.key}: ${entry.value.length}');
  }
  transport.close();
}
