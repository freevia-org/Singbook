// Opt-in publisher-download checks. Normal offline CI does not contact sources.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/transport.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'source_maintenance.dart' show DesktopMaintenanceClient;
import 'src/maintenance_http_diagnostics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final live = Platform.environment['SINGBOOK_LIVE_IMPORT_CHECK'] == '1';
  test(
    'Ozbcoz public downloads import, save, reopen and export',
    () async {
      sqfliteFfiInit();
      final diagnostics = MaintenanceHttpDiagnosticsClient(
        Platform.isWindows ? DesktopMaintenanceClient() : http.Client(),
      );
      final transport = ProviderTransport(
        client: diagnostics,
        hostInterval: const Duration(seconds: 1),
      );
      final root = Directory('artifacts/source-maintenance')
        ..createSync(recursive: true);
      final directory = await Directory.systemTemp.createTemp(
        'singbook-import-check-',
      );
      final results = <Map<String, dynamic>>[];
      try {
        // Exact public links observed in the publisher's ChordPro index. Do not
        // guess endpoints or substitute another arrangement if one disappears.
        for (final canary in [
          (id: '2941', title: 'Wild Rover [C]', artist: 'The Dubliners'),
          (id: '1683', title: 'Banana Boat Song', artist: 'Harry Belafonte'),
        ]) {
          final url = Uri.https('ozbcoz.com', '/Songs/cp/get_pro.php', {
            'ID': canary.id,
            'instr': 'guitar',
          });
          final result = <String, dynamic>{
            'id': canary.id,
            'source': 'ozbcoz',
            'sourceUrl': url.toString(),
            'expectedTitle': canary.title,
            'expectedArtist': canary.artist,
            'measuredAt': DateTime.now().toUtc().toIso8601String(),
            'nativeFilePickerTested': false,
          };
          LibraryRepository? repository;
          AppController? controller;
          try {
            final text = await transport.getText(url, maxBytes: 512 * 1024);
            final bytes = Uint8List.fromList(utf8.encode(text));
            final picked = PickedDocument('ozbcoz-${canary.id}.pro', bytes);
            final decoded = decodePickedSongs(picked).single;
            expect(decoded.title.trim(), canary.title);
            expect(decoded.artist.trim(), canary.artist);
            final chordPattern = RegExp(r'\[[A-G][^\]]*\]');
            // A key in a title (e.g. [C]) is not a lyric chord token.
            final songLines = text
                .replaceAll('\r\n', '\n')
                .split('\n')
                .where(
                  (line) => !RegExp(
                    r'^\s*\{(?:t|title|artist|st|subtitle|key)\s*:',
                    caseSensitive: false,
                  ).hasMatch(line),
                )
                .join('\n');
            final chords = chordPattern
                .allMatches(songLines)
                .map((m) => m[0])
                .toList();
            expect(chords, isNotEmpty);
            expect(
              chordPattern.allMatches(decoded.body).map((m) => m[0]),
              chords,
            );
            expect(decoded.metadata['key'], 'C');
            // Credit/comment lines are part of the original body; retain every
            // such line, including publisher provenance. Never invent credits.
            final comments = text
                .replaceAll('\r\n', '\n')
                .split('\n')
                .where(
                  (line) =>
                      line.trimLeft().startsWith('#') ||
                      RegExp(
                        r'^\s*\{(?:c|comment|ci|comment_italic|cb|comment_box)\s*:',
                        caseSensitive: false,
                      ).hasMatch(line),
                )
                .toList();
            expect(comments, isNotEmpty);
            expect(comments.every(decoded.body.contains), isTrue);
            final path = '${directory.path}/${canary.id}.sqlite';
            repository = await LibraryRepository.open(
              path: path,
              factory: databaseFactoryFfi,
            );
            controller = AppController(
              repository: repository,
              discovery: SourceDiscoveryService([]),
            );
            await controller.initialize();
            expect(await repository.listSongs(), isEmpty);
            final imported = await controller.importDocument(
              picked,
              intent: ImportIntent.songs,
            );
            final saved = imported.songs.single;
            final savedJson = jsonEncode(saved.toJson());
            controller.dispose();
            controller = null;
            await repository.close();
            repository = null;
            repository = await LibraryRepository.open(
              path: path,
              factory: databaseFactoryFfi,
            );
            final reopened = (await repository.listSongs()).single;
            expect(jsonEncode(reopened.toJson()), savedJson);
            final exported = ChordProCodec().decode(
              ChordProCodec().encode(reopened),
            );
            expect(exported.body, reopened.body);
            expect(exported.metadata, reopened.metadata);
            expect(exported.title, reopened.title);
            expect(exported.artist, reopened.artist);
            result.addAll({
              'status': 'healthy',
              'downloadedBytes': bytes.length,
              'downloadedTextSha256': sha256.convert(bytes).toString(),
              'chordTokensRetained': chords.length,
              'metadataFields': decoded.metadata.keys.toList()..sort(),
              'commentLinesRetained': comments.length,
              'sourceRecordCount': decoded.sources.length,
              'saveReopenExact': true,
              'exportBodyMetadataIdentityExact': true,
              'verifiedCapabilities': [
                'fileImport',
                'lyrics',
                'chords',
                'metadata',
              ],
            });
          } catch (error) {
            result.addAll({
              'status': 'unverified',
              'reason': error is ProviderException
                  ? error.code
                  : 'import_check_failed',
            });
            rethrow;
          } finally {
            controller?.dispose();
            await repository?.close();
            results.add(result);
          }
        }
      } finally {
        await transport.close();
        File('${root.path}/imports-live.json').writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert({'schemaVersion': 1, 'runtime': 'host-flutter-test', 'measuredAt': DateTime.now().toUtc().toIso8601String(), 'userLibraryAccessed': false, 'documentsRetained': false, 'httpDiagnostics': diagnostics.report, 'probes': results})}\n',
        );
        // Only the newly-created disposable QA directory is removed.
        await directory.delete(recursive: true);
      }
    },
    skip: live
        ? false
        : 'Set SINGBOOK_LIVE_IMPORT_CHECK=1 for permitted live downloads',
  );
}
