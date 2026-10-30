import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/settings/backup_section.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';

class _RestoreCall {
  const _RestoreCall({
    required this.file,
    required this.mode,
    required this.previewToken,
    required this.restorePreferences,
  });

  final PickedDocument file;
  final BackupRestoreMode mode;
  final String previewToken;
  final bool restorePreferences;
}

class _BackupController implements AppController {
  _BackupController({required this.preview});

  final BackupPreview preview;
  final exports = <bool>[];
  final inspections = <PickedDocument>[];
  final restores = <_RestoreCall>[];
  Uint8List exportBytes = Uint8List.fromList([1, 2, 3]);
  Object? inspectError;

  @override
  Future<Uint8List> exportBackup({bool includePreferences = true}) async {
    exports.add(includePreferences);
    return exportBytes;
  }

  @override
  Future<BackupPreview> inspectBackup(PickedDocument file) async {
    inspections.add(file);
    if (inspectError case final error?) throw error;
    return preview;
  }

  @override
  Future<BackupRestoreResult> restoreBackup(
    PickedDocument file, {
    required BackupRestoreMode mode,
    required String expectedPreviewToken,
    bool restorePreferences = false,
  }) async {
    restores.add(
      _RestoreCall(
        file: file,
        mode: mode,
        previewToken: expectedPreviewToken,
        restorePreferences: restorePreferences,
      ),
    );
    return BackupRestoreResult(
      mode: mode,
      importedSongCount: preview.songCount,
      importedSetlistCount: preview.setlistCount,
      preferencesRestored: restorePreferences,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BackupFiles extends VerseFileActions {
  _BackupFiles(this.document);

  final PickedDocument? document;
  int pickCount = 0;
  Uint8List? sharedBytes;
  Uint8List? savedBytes;

  @override
  Future<PickedDocument?> pickDocument() async {
    pickCount++;
    return document;
  }

  @override
  Future<Uri?> saveBackupBytes(Uint8List bytes) async {
    savedBytes = bytes;
    return Uri.parse('content://saved');
  }

  @override
  Future<ShareResult> shareBackupBytes(Uint8List bytes, {Rect? origin}) async {
    sharedBytes = bytes;
    return const ShareResult('shared', ShareResultStatus.success);
  }
}

BackupPreview _preview({List<String> preferenceKeys = const ['themeMode']}) =>
    BackupPreview(
      schemaVersion: 3,
      songCount: 12,
      setlistCount: 3,
      includedPreferenceKeys: preferenceKeys,
      identicalSongCount: 0,
      conflictingSongCount: 1,
      identicalSetlistCount: 0,
      conflictingSetlistCount: 0,
      token: 'preview-token-123',
    );

Future<void> _pumpSection(
  WidgetTester tester,
  _BackupController controller,
  _BackupFiles files, {
  double textScale = 1,
  Size size = const Size(420, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: singbookLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: BackupSection(controller: controller, files: files),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Restore keeps the section busy while a modal is open, so its progress
// indicator continues animating. Advance the dialog animation without waiting
// for the background spinner to settle.
Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('picker cancellation does not inspect or restore', (
    tester,
  ) async {
    final controller = _BackupController(preview: _preview());
    final files = _BackupFiles(null);
    await _pumpSection(tester, controller, files);

    await tester.tap(find.byKey(const ValueKey('backup-restore')));
    await tester.pumpAndSettle();

    expect(files.pickCount, 1);
    expect(controller.inspections, isEmpty);
    expect(controller.restores, isEmpty);
  });

  testWidgets('Merge is the default and preferences stay unchecked', (
    tester,
  ) async {
    final controller = _BackupController(preview: _preview());
    final file = PickedDocument('backup.zip', Uint8List.fromList([1]));
    final files = _BackupFiles(file);
    await _pumpSection(tester, controller, files);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

    await tester.tap(find.byKey(const ValueKey('backup-restore')));
    await _pumpDialog(tester);
    expect(find.text(l10n.backupSummary(12, 3, 1)), findsOneWidget);
    expect(
      tester
          .widget<RadioGroup<BackupRestoreMode>>(
            find.byType(RadioGroup<BackupRestoreMode>),
          )
          .groupValue,
      BackupRestoreMode.merge,
    );
    await tester.tap(find.text(l10n.backupRestore).last);
    await tester.pumpAndSettle();

    expect(controller.inspections, [file]);
    expect(controller.restores, hasLength(1));
    expect(controller.restores.single.mode, BackupRestoreMode.merge);
    expect(controller.restores.single.previewToken, 'preview-token-123');
    expect(controller.restores.single.restorePreferences, isFalse);
  });

  testWidgets('Replace requires a second confirmation before writing', (
    tester,
  ) async {
    final controller = _BackupController(preview: _preview());
    final files = _BackupFiles(
      PickedDocument('backup.zip', Uint8List.fromList([1])),
    );
    await _pumpSection(tester, controller, files);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

    await tester.tap(find.byKey(const ValueKey('backup-restore')));
    await _pumpDialog(tester);
    await tester.tap(find.byType(RadioListTile<BackupRestoreMode>).at(1));
    await _pumpDialog(tester);
    await tester.tap(find.text(l10n.backupRestore).last);
    await _pumpDialog(tester);
    expect(find.text(l10n.backupReplaceConfirm), findsOneWidget);
    await tester.tap(find.text(l10n.actionCancel).last);
    await tester.pumpAndSettle();

    expect(controller.restores, isEmpty);
  });

  testWidgets(
    'confirmed Replace passes the inspected token and preference choice',
    (tester) async {
      final controller = _BackupController(preview: _preview());
      final file = PickedDocument('backup.zip', Uint8List.fromList([1]));
      final files = _BackupFiles(file);
      await _pumpSection(tester, controller, files);
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

      await tester.tap(find.byKey(const ValueKey('backup-restore')));
      await _pumpDialog(tester);
      await tester.tap(find.byType(RadioListTile<BackupRestoreMode>).at(1));
      await _pumpDialog(tester);
      await tester.tap(find.text(l10n.backupRestorePreferences));
      await _pumpDialog(tester);
      await tester.tap(find.text(l10n.backupRestore).last);
      await _pumpDialog(tester);
      await tester.tap(find.text(l10n.backupReplace).last);
      await tester.pumpAndSettle();

      expect(controller.restores, hasLength(1));
      expect(controller.restores.single.file, same(file));
      expect(controller.restores.single.mode, BackupRestoreMode.replace);
      expect(controller.restores.single.previewToken, 'preview-token-123');
      expect(controller.restores.single.restorePreferences, isTrue);
    },
  );

  testWidgets(
    'export passes the preference toggle and exact bytes to sharing',
    (tester) async {
      final controller = _BackupController(preview: _preview());
      controller.exportBytes = Uint8List.fromList([4, 5, 6, 7]);
      final files = _BackupFiles(null);
      await _pumpSection(tester, controller, files);
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

      await tester.tap(find.byKey(const ValueKey('backup-export')));
      await tester.pumpAndSettle();
      expect(controller.exports, [true]);

      await tester.tap(find.text(l10n.backupIncludePreferences));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('backup-export')));
      await tester.pumpAndSettle();

      expect(controller.exports, [true, false]);
      expect(files.sharedBytes, orderedEquals([4, 5, 6, 7]));
    },
  );

  testWidgets('save to device exports with the preference choice and saves', (
    tester,
  ) async {
    final controller = _BackupController(preview: _preview());
    controller.exportBytes = Uint8List.fromList([8, 9]);
    final files = _BackupFiles(null);
    await _pumpSection(tester, controller, files);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

    await tester.tap(find.text(l10n.backupIncludePreferences));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('backup-save-device')));
    await tester.pumpAndSettle();

    expect(controller.exports, [false]);
    expect(files.savedBytes, orderedEquals([8, 9]));
    expect(files.sharedBytes, isNull);
  });

  testWidgets('invalid preview shows failure and never restores', (
    tester,
  ) async {
    final controller = _BackupController(preview: _preview())
      ..inspectError = const FormatException('invalid_archive');
    final files = _BackupFiles(
      PickedDocument('broken.lyrics-setlist', Uint8List.fromList([1])),
    );
    await _pumpSection(tester, controller, files);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

    await tester.tap(find.byKey(const ValueKey('backup-restore')));
    await tester.pumpAndSettle();

    expect(controller.inspections, hasLength(1));
    expect(controller.restores, isEmpty);
    expect(find.text(l10n.backupFailed), findsOneWidget);
  });

  testWidgets('large text preview remains scrollable and can be canceled', (
    tester,
  ) async {
    final controller = _BackupController(preview: _preview());
    final files = _BackupFiles(
      PickedDocument('backup.zip', Uint8List.fromList([1])),
    );
    await _pumpSection(
      tester,
      controller,
      files,
      textScale: 1.8,
      size: const Size(360, 640),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

    await tester.ensureVisible(find.byKey(const ValueKey('backup-restore')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('backup-restore')));
    await _pumpDialog(tester);
    expect(find.text(l10n.backupSummary(12, 3, 1)), findsOneWidget);
    await tester.ensureVisible(find.text(l10n.actionCancel).last);
    await tester.pump();
    await tester.tap(find.text(l10n.actionCancel).last);
    await tester.pumpAndSettle();

    expect(controller.restores, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
