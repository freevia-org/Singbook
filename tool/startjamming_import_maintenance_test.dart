// Opt-in live source qualification. Ordinary offline CI makes no source requests.
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'source_maintenance.dart' show DesktopMaintenanceClient;
import 'src/maintenance_http_diagnostics.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/common.dart' show plainToChordPro;
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/startjamming.dart';
import 'package:singbook/providers/transport.dart';

Object? canonical(Object? v) => v is Map
    ? {
        for (final k in v.keys.cast<String>().toList()..sort())
          k: canonical(v[k]),
      }
    : v is List
    ? v.map(canonical).toList()
    : v;
String digest(Object? v) =>
    sha256.convert(utf8.encode(jsonEncode(canonical(v)))).toString();
void require(bool value, String code) {
  if (!value) throw StateError(code);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  final enabled =
      Platform.environment['SINGBOOK_LIVE_STARTJAMMING_CHECK'] == '1';
  test(
    'live native source import preserves lyrics, independent chord measures, source bytes and SQLite/ChordPro facts',
    () async {
      const canaries = [
        {
          'query': 'Clinch Mountain Backstep',
          'id': 'clinch-mountain-backstep',
          'hasLyrics': false,
        },
        {
          'query': 'Blue Moon of Kentucky',
          'id': 'blue-moon-of-kentucky',
          'hasLyrics': true,
        },
      ];
      final run = Directory(
        'artifacts/startjamming-live-private/${DateTime.now().toUtc().microsecondsSinceEpoch}',
      )..createSync(recursive: true);
      final checks = <Map<String, dynamic>>[];
      final diagnostics = MaintenanceHttpDiagnosticsClient(
        DesktopMaintenanceClient(),
      );
      final transport = ProviderTransport(
        client: diagnostics,
        hostInterval: const Duration(seconds: 1),
        maxRetries: 0,
      );
      final provider = StartJammingProvider(transport);
      final path = '${run.path}/library.sqlite';
      final repo = await LibraryRepository.open(
        path: path,
        factory: databaseFactoryFfi,
      );
      final app = AppController(
        repository: repo,
        discovery: SourceDiscoveryService([provider]),
      );
      final codec = ChordProCodec();
      final saved = <SongDocument>[];
      try {
        await app.initialize();
        for (final row in canaries) {
          await app.search(row['query'] as String);
          final selected = app.suggestions.singleWhere(
            (s) => s.id == row['id'],
          );
          require(
            selected.artist.isEmpty && selected.recordingIds.isEmpty,
            'Invented artist/recording',
          );
          await app.selectCandidate(selected);
          final result = app.results.singleWhere(
            (s) => s.candidate.providerId == 'startjamming',
          );
          require(
            result.matchKind == MatchKind.sameSong &&
                result.candidate.recordingIds.isEmpty &&
                result.timingTracks.isEmpty,
            'Arrangement wrongly promoted to recording/timing',
          );
          final bytes = base64Decode(
            result.extra['originalPayload']['base64'] as String,
          );
          final original = jsonDecode(utf8.decode(bytes));
          require(
            digest(result.extra['startjamming']['rawFullJson']) ==
                digest(original),
            'Original live source facts lost',
          );
          require(
            original['id'] == row['id'] && original['title'] == selected.title,
            'Live canonical identity changed',
          );
          final sourceLyrics = (original['lyrics'] as String? ?? '').replaceAll(
            RegExp(r'</?chorus\s*>', caseSensitive: false),
            '',
          );
          require(
            lyricOrderHash(result.body) ==
                lyricOrderHash(plainToChordPro(sourceLyrics)),
            'Lyrics changed or chord chart polluted lyrics',
          );
          require(
            lyricLines(result.body).isNotEmpty == row['hasLyrics'],
            'Canary lyric capability changed',
          );
          final sections = original['arrangement']['sections'] as List;
          final beats = sections.fold<int>(
            0,
            (n, s) =>
                n +
                (s['measures'] as List).fold<int>(
                  0,
                  (m, v) => m + (v['beats'] as List).length,
                ),
          );
          require(
            chordPattern.allMatches(result.body).length == beats,
            'Chord beat count changed',
          );
          require(
            result.hasChords &&
                result.attribution!.contains(
                  'https://www.startjamming.com/song/${row['id']}',
                ),
            'Chord chart/attribution missing',
          );
          final song = await app.saveResult(source: result);
          saved.add(song);
          final retained = song.sources.singleWhere(
            (s) => s.candidate.providerId == 'startjamming',
          );
          require(
            digest(retained.toJson()) == digest(result.toJson()),
            'Save changed full source',
          );
          final roundtrip = codec.decode(codec.encode(song));
          require(
            roundtrip.extensionError == null &&
                digest(roundtrip.sources.map((s) => s.toJson()).toList()) ==
                    digest(song.sources.map((s) => s.toJson()).toList()),
            'ChordPro lost source facts',
          );
          File(
            '${run.path}/${selected.id}-result.json',
          ).writeAsStringSync(jsonEncode(result.toJson()));
          checks.add({
            'id': selected.id,
            'status': 'healthy_local_live_native',
            'canonicalUrl': result.candidate.url,
            'lyricLines': lyricLines(result.body).length,
            'unknownArtistAndUnconfirmedRecordingPreserved': true,
            'normalizedChordMeasures': sections.fold<int>(
              0,
              (n, s) => n + (s['measures'] as List).length,
            ),
            'httpBodyBytes': bytes.length,
            'httpBodySha256': sha256.convert(bytes).toString(),
            'expandedBeatsRendered': beats,
            'lyricOrderExact': true,
            'allSourceFactsAndHttpBodyBytesExact': true,
            'normalControllerSearchSelectSavePassed': true,
            'chordProSourceFactsExact': true,
            'metadataFields': result.metadata.keys.toList()..sort(),
          });
        }
      } finally {
        app.dispose();
        await transport.close();
        await repo.close();
      }
      final reopened = await LibraryRepository.open(
        path: path,
        factory: databaseFactoryFfi,
      );
      try {
        for (final song in saved) {
          final next = await reopened.getSong(song.id);
          require(
            next != null && digest(next.toJson()) == digest(song.toJson()),
            'SQLite reopen changed saved song',
          );
        }
      } finally {
        await reopened.close();
      }
      require(
        diagnostics.report['networkFailures'] == 0,
        'Live network failure',
      );
      final host = diagnostics.report['hosts']['www.startjamming.com'];
      require(
        host != null && host['requests'] == 4 && host['statuses']['200'] == 4,
        'Live requests did not return exactly four HTTP200 responses',
      );
      final report = {
        'atUtc': DateTime.now().toUtc().toIso8601String(),
        'scope':
            'Four local live native HTTP requests through normal AppController, real SQLite save/reopen and production ChordPro codec; no Android UI or cloud claim',
        'baseCommit': Platform.environment['SINGBOOK_SOURCE_COMMIT'],
        'workingTreeQualification': true,
        'sourceSha256': sha256
            .convert(
              File('lib/providers/extra/startjamming.dart').readAsBytesSync(),
            )
            .toString(),
        'transportSha256': sha256
            .convert(File('lib/providers/transport.dart').readAsBytesSync())
            .toString(),
        'httpDiagnostics': diagnostics.report,
        'maxRetries': 0,
        'minimumHostIntervalMs': 1000,
        'credentialsOrCookiesUsed': false,
        'checks': checks,
        'savedSongCount': saved.length,
        'completeSavedSongJsonExactAfterSQLiteReopen': true,
        'newSourceRegisteredOrActivated': false,
      };
      File('artifacts/startjamming-native-live-report.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(report)}\n',
      );
      stdout.writeln(jsonEncode(report));
    },
    skip: !enabled,
  );
}
