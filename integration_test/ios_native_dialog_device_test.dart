// Opt-in interactive checks. The operator cancels the first three sheets,
// then saves an original fixture to local Files and selects it again.
// No file is sent to another person, uploaded, or sent to a printer.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';

const _enabled = bool.fromEnvironment('SINGBOOK_NATIVE_DIALOG_QA');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'iOS native document, sharing, and print dialogs cancel cleanly',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('Native dialog QA'))),
        ),
      );
      await tester.pumpAndSettle();
      final files = VerseFileActions();
      final song = SongDocument(
        id: 'ios-dialog-original',
        title: 'Original native dialog fixture',
        artist: 'Freevia QA',
        body: '[C]A lantern lights the road\n[G]We sing a new refrain',
      );
      await tester.runAsync(() async {
        debugPrint('SINGBOOK_NATIVE_DIALOG:document_picker_cancel');
        expect(
          await files.pickDocument().timeout(const Duration(minutes: 2)),
          isNull,
        );
        debugPrint('SINGBOOK_NATIVE_DIALOG:share_sheet_cancel');
        final result = await files
            .shareSong(song, origin: const Rect.fromLTWH(20, 100, 20, 20))
            .timeout(const Duration(minutes: 2));
        expect(result.status, ShareResultStatus.dismissed);
        final pdf = await createSongPdf([song]);
        debugPrint('SINGBOOK_NATIVE_DIALOG:print_dialog_cancel');
        final printed = await Printing.layoutPdf(
          name: 'Original native dialog fixture',
          onLayout: (_) async => pdf,
        ).timeout(const Duration(minutes: 2));
        expect(printed, isFalse);
        debugPrint('SINGBOOK_NATIVE_DIALOG:all_cancelled');
      });
    },
    skip: !Platform.isIOS || !_enabled,
    timeout: const Timeout(Duration(minutes: 8)),
  );
  testWidgets(
    'iOS Files export and document selection preserve the song',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Local Files round-trip QA')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final song = SongDocument(
        id: 'ios-files-original',
        title: 'Singbook Files QA 20261019',
        artist: 'Freevia QA',
        body: '[C]A lantern lights the road\n[G]We sing a new refrain',
      );
      final files = VerseFileActions();
      await tester.runAsync(() async {
        debugPrint('SINGBOOK_NATIVE_DIALOG:save_fixture_to_local_files');
        final result = await files
            .shareSong(song, origin: const Rect.fromLTWH(20, 100, 20, 20))
            .timeout(const Duration(minutes: 3));
        expect(result.status, ShareResultStatus.success);
        debugPrint('SINGBOOK_NATIVE_DIALOG:select_saved_fixture');
        final picked = await files.pickDocument().timeout(
          const Duration(minutes: 3),
        );
        expect(picked, isNotNull);
        expect(picked!.text, ChordProCodec().encode(song));
        final restored = decodePickedSongs(picked).single;
        expect(restored.id, song.id);
        expect(restored.title, song.title);
        expect(restored.body, song.body);
        debugPrint('SINGBOOK_NATIVE_DIALOG:local_files_roundtrip_verified');
      });
    },
    skip: !Platform.isIOS || !_enabled,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
