// Opt-in, operator-assisted app UI checks for iOS native share and Files flows.
// The app is backed by a temporary database containing only original fixtures.
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart' show deleteDatabase, getDatabasesPath;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'support/ios_screenshots.dart';

const _enabled = bool.fromEnvironment('SINGBOOK_NATIVE_DIALOG_QA');
const _hostRotation = bool.fromEnvironment('SINGBOOK_HOST_ROTATION');
const _songId = 'ios-app-workflow-song';
const _setlistId = 'ios-app-workflow-setlist';
const _extraSongId = 'ios-app-workflow-extra';
final _qaSession = DateTime.now().microsecondsSinceEpoch.toString();

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'iOS app menus, account availability, and backup restore workflows',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_ios_workflows_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
      AppController? controller;
      addTearDown(() async {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          controller?.dispose();
          await SystemChrome.setPreferredOrientations([]);
          await tester.runAsync(() async {
            await repository.close();
            await deleteDatabase(databasePath);
          });
        }
      });
      final song = SongDocument(
        id: _songId,
        title: 'Lanterns Before Sunrise',
        artist: 'Freevia Original QA',
        body: '[C]Lanterns mark the road\n[G]We carry songs at dawn',
      );
      final setlist = SetlistDocument(
        id: _setlistId,
        name: 'Original QA Set',
        entries: [SetlistEntry(id: 'ios-app-workflow-entry', songId: _songId)],
      );
      await repository.saveSong(song);
      await repository.saveSetlist(setlist);
      final app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(const []),
      );
      controller = app;
      await app.initialize();
      await app.setSetting('startupSongsView', 'library');
      await app.setSetting('themeMode', 'dark');
      await tester.pumpWidget(VerseApp(controller: app));
      await _pumpUi(tester);
      await _rotate(tester, false);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );

      // Open the account settings from the real app header and verify the
      // platform's unavailable state without attempting authentication.
      await tester.tap(find.byKey(const ValueKey('cloud-button')));
      await _pumpUi(tester);
      await _scrollTo(
        tester,
        find.byKey(const ValueKey('account-unavailable')),
      );
      expect(find.byKey(const ValueKey('account-unavailable')), findsOneWidget);
      await _capture('app_account_unavailable');
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.navSongs).first);
      await _pumpUi(tester);
      await tester.tap(find.byKey(const ValueKey('home-mode-library')));
      await _pumpUi(tester);
      expect(find.text(song.title), findsOneWidget);
      final songMenu = find.byTooltip(l10n.songMenuLabel);
      await _scrollTo(tester, songMenu);
      expect(songMenu.hitTestable(), findsOneWidget);
      await tester.tap(songMenu);
      await _pumpUi(tester);
      final songShareAck = await _OperatorAcknowledgement.start(
        'song_share_sheet_cancel',
      );
      await tester.tap(find.text(l10n.settingsShareSong).last);
      await songShareAck.wait(tester);

      await _rotate(tester, true);
      await tester.tap(find.text(l10n.navSetlists).first);
      await _pumpUi(tester);
      expect(find.text(setlist.name), findsOneWidget);
      final setlistMenu = find.byTooltip(
        l10n.accessibilitySetlistMenu(setlist.name),
      );
      await _scrollTo(tester, setlistMenu);
      expect(setlistMenu.hitTestable(), findsOneWidget);
      await tester.tap(setlistMenu);
      await _pumpUi(tester);
      final setlistShareAck = await _OperatorAcknowledgement.start(
        'setlist_share_sheet_cancel',
      );
      await tester.tap(find.text(l10n.setlistShare).last);
      await setlistShareAck.wait(tester);

      await tester.tap(find.text(l10n.navSettings).first);
      await _pumpUi(tester);
      await tester.tap(find.byKey(const ValueKey('settings-menu-account')));
      await _pumpUi(tester);
      final export = find.byKey(const ValueKey('backup-export'));
      await _scrollTo(tester, export);
      expect(
        export,
        findsOneWidget,
        reason: 'Backup section is app-integrated',
      );
      await _capture('app_backup_settings');
      final exportAck = await _OperatorAcknowledgement.start('backup_export');
      await tester.tap(export);
      await exportAck.wait(tester);
      await _waitForEnabled(tester, export);
      await app.setSetting('themeMode', 'light');

      // Add an original temporary-library record after exporting. A successful
      // merge keeps it; replacement removes it, proving the selected mode.
      await app.saveSong(
        SongDocument(
          id: _extraSongId,
          title: 'Temporary Merge Marker',
          artist: 'Freevia Original QA',
          body: 'Only present before replacement',
        ),
      );

      final mergePreviewAck = await _OperatorAcknowledgement.start(
        'restore_picker_merge_preview',
      );
      await _openRestorePicker(tester);
      await mergePreviewAck.wait(tester);
      await _pumpUi(tester);
      expect(find.text(l10n.backupSummary(1, 1, 0)), findsOneWidget);
      await _capture('app_backup_merge_preview');
      await _tapDialogAction(tester, l10n.actionCancel);
      await _pumpUi(tester);
      expect(find.byKey(const ValueKey('backup-restore')), findsOneWidget);
      expect(app.findSong(_extraSongId), isNotNull);

      final mergeRestoreAck = await _OperatorAcknowledgement.start(
        'restore_picker_merge_confirm',
      );
      await _openRestorePicker(tester);
      await mergeRestoreAck.wait(tester);
      await _pumpUi(tester);
      expect(find.text(l10n.backupSummary(1, 1, 0)), findsOneWidget);
      final restorePreferences = find.text(l10n.backupRestorePreferences);
      expect(restorePreferences, findsOneWidget);
      await _scrollTo(tester, restorePreferences);
      expect(restorePreferences.hitTestable(), findsOneWidget);
      await tester.tap(restorePreferences);
      await _pumpUi(tester);
      await _tapDialogAction(tester, l10n.backupRestore);
      await _waitForEnabled(
        tester,
        find.byKey(const ValueKey('backup-restore')),
      );
      expect(app.findSong(_songId)?.body, song.body);
      expect(app.findSong(_extraSongId), isNotNull);
      expect(app.setlists.any((item) => item.id == _setlistId), isTrue);
      expect(app.settings['themeMode'], 'dark');
      await _capture('app_backup_merge_restored');

      await _rotate(tester, false);
      final replaceCancelAck = await _OperatorAcknowledgement.start(
        'restore_picker_replace_cancel',
      );
      await _openRestorePicker(tester);
      await replaceCancelAck.wait(tester);
      await _pumpUi(tester);
      await tester.tap(find.text(l10n.backupReplace).first);
      await _pumpUi(tester);
      await _tapDialogAction(tester, l10n.backupRestore);
      await _pumpUi(tester);
      expect(find.text(l10n.backupReplaceConfirm), findsOneWidget);
      await _capture('app_backup_replace_confirmation');
      await _tapDialogAction(tester, l10n.actionCancel);
      await _pumpUi(tester);
      expect(app.findSong(_extraSongId), isNotNull);

      final replaceConfirmAck = await _OperatorAcknowledgement.start(
        'restore_picker_replace_confirm',
      );
      await _openRestorePicker(tester);
      await replaceConfirmAck.wait(tester);
      await _pumpUi(tester);
      await tester.tap(find.text(l10n.backupReplace).first);
      await _pumpUi(tester);
      await _tapDialogAction(tester, l10n.backupRestore);
      await _pumpUi(tester);
      expect(find.text(l10n.backupReplaceConfirm), findsOneWidget);
      await _tapDialogAction(tester, l10n.backupReplace);
      await _waitForEnabled(
        tester,
        find.byKey(const ValueKey('backup-restore')),
      );
      expect(app.findSong(_songId)?.body, song.body);
      expect(app.findSong(_extraSongId), isNull);
      expect(app.setlists.map((item) => item.id), contains(_setlistId));
      await _capture('app_backup_replace_restored');
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isIOS || !_enabled,
    timeout: const Timeout(Duration(minutes: 30)),
  );
  importTests();
}

void importTests() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'iOS app imports ChordPro songs and setlists from Files',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_ios_imports_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
      AppController? controller;
      Directory? fixtureDirectory;
      addTearDown(() async {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          controller?.dispose();
          await SystemChrome.setPreferredOrientations([]);
          await tester.runAsync(() async {
            if (fixtureDirectory?.existsSync() ?? false) {
              await fixtureDirectory!.delete(recursive: true);
            }
            await repository.close();
            await deleteDatabase(databasePath);
          });
        }
      });

      final originalSong = SongDocument(
        id: _songId,
        title: 'Lanterns Before Sunrise',
        artist: 'Freevia Original QA',
        body: '[C]Lanterns mark the road\n[G]We carry songs at dawn',
      );
      final originalSetlist = SetlistDocument(
        id: _setlistId,
        name: 'Original QA Set',
        entries: [
          SetlistEntry(id: 'ios-import-baseline-entry', songId: _songId),
        ],
      );
      await repository.saveSong(originalSong);
      await repository.saveSetlist(originalSetlist);
      final app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(const []),
      );
      controller = app;
      await app.initialize();
      await app.setSetting('startupSongsView', 'library');
      await tester.pumpWidget(VerseApp(controller: app));
      await _pumpUi(tester);
      await _rotate(tester, false);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );

      // Keep original-only files in this app's Documents sandbox. The operator
      // saves them through iOS share UI, then selects them in the real picker.
      final documents = await getApplicationDocumentsDirectory();
      final importFixtures = Directory(
        paths.join(documents.path, 'singbook-app-qa', _qaSession),
      );
      fixtureDirectory = importFixtures;
      await importFixtures.create(recursive: true);
      final importedSong = SongDocument(
        id: 'ios-app-import-song',
        title: 'Files Picker Original Song',
        artist: 'Freevia Original QA',
        body:
            '[D]A paper lantern keeps the way\n[A]We bring a song to greet the day',
      );
      final chordPro = ChordProCodec().encode(importedSong);
      final songFile = File(
        paths.join(importFixtures.path, 'QA Song $_qaSession.cho'),
      );
      await songFile.writeAsString(chordPro, encoding: utf8, flush: true);
      final fixtureSetlist = SetlistDocument(
        id: 'fixture-only-setlist-id',
        name: 'Files Picker Original Setlist',
        notes: 'Original local Files import fixture',
        entries: [
          SetlistEntry(
            id: 'fixture-only-entry-id',
            songId: importedSong.id,
            overrides: const {'key': 'E'},
          ),
        ],
      );
      final setlistXml = encodeSetlistReferences(fixtureSetlist, [
        importedSong,
      ]);
      final setlistFile = File(
        paths.join(importFixtures.path, 'QA Setlist $_qaSession.osts'),
      );
      await setlistFile.writeAsString(setlistXml, encoding: utf8, flush: true);

      await _shareFixtureFile(tester, songFile, 'song_fixture_save_to_files');
      await _shareFixtureFile(
        tester,
        setlistFile,
        'setlist_fixture_save_to_files',
      );

      final importNotices = <UiNotice>[];
      final ui = tester
          .widget<VerseAppShell>(find.byType(VerseAppShell))
          .controller;
      final notices = ui.notices.listen(importNotices.add);
      addTearDown(notices.cancel);
      int completedImports() => importNotices
          .where((notice) => notice == UiNotice.importSuccess)
          .length;

      await tester.tap(find.text(l10n.navSongs).first);
      await _pumpUi(tester);
      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await _pumpUi(tester);
      final songImportAck = await _OperatorAcknowledgement.start(
        'song_import_picker',
      );
      await tester.tap(find.text(l10n.settingsImportChordPro));
      await songImportAck.wait(tester);
      await _pumpUi(tester);
      await _waitForRealAsync(
        tester,
        () => completedImports() >= 1,
        'ChordPro import completion event',
      );
      expect(app.findSong(importedSong.id)?.body, importedSong.body);
      expect(app.findSong(importedSong.id)?.title, importedSong.title);
      expect(app.songs, hasLength(2));
      expect(app.findSong(_songId)?.body, originalSong.body);
      await _capture('app_song_imported_from_files');

      await tester.tap(find.text(l10n.navSetlists).first);
      await _pumpUi(tester);
      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await _pumpUi(tester);
      final setlistImportAck = await _OperatorAcknowledgement.start(
        'setlist_import_picker',
      );
      await tester.tap(find.text('${l10n.settingsImportSetlist} (.osts)'));
      await setlistImportAck.wait(tester);
      await _pumpUi(tester);
      await _waitForRealAsync(
        tester,
        () => completedImports() >= 2,
        'setlist import completion event',
      );
      final imported = app.setlists.singleWhere(
        (value) => value.name == fixtureSetlist.name,
      );
      expect(imported.id, isNotEmpty);
      expect(imported.id, isNot(fixtureSetlist.id));
      expect(imported.name, fixtureSetlist.name);
      expect(imported.notes, fixtureSetlist.notes);
      expect(imported.entries, hasLength(1));
      expect(imported.entries.single.songId, importedSong.id);
      expect(imported.entries.single.overrides['key'], 'E');
      expect(app.setlists, hasLength(2));
      await _capture('app_setlist_imported_from_files');

      // Completion events are retained even if their transient snackbar has
      // disappeared while the operator acknowledges the native picker.
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).first),
      ).hideCurrentSnackBar();
      await _pumpUi(tester);
      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await _pumpUi(tester);
      final repeatImportAck = await _OperatorAcknowledgement.start(
        'setlist_import_picker_repeat',
      );
      await tester.tap(find.text('${l10n.settingsImportSetlist} (.osts)'));
      await repeatImportAck.wait(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      debugPrint('SINGBOOK_IMPORT_REPEAT:picker_returned');
      await _pumpUi(tester);
      await _waitForRealAsync(
        tester,
        () => completedImports() >= 3,
        'repeat setlist import completion event',
      );
      final repeated = app.setlists.singleWhere(
        (value) => value.name == fixtureSetlist.name,
      );
      expect(repeated.id, imported.id);
      expect(app.setlists, hasLength(2));
      expect(repeated.notes, fixtureSetlist.notes);
      expect(repeated.entries, hasLength(1));
      expect(repeated.entries.single.songId, importedSong.id);
      expect(repeated.entries.single.overrides['key'], 'E');
      await _capture('app_setlist_repeat_import_verified');
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isIOS || !_enabled,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

Future<void> _openRestorePicker(WidgetTester tester) async {
  final restore = find.byKey(const ValueKey('backup-restore'));
  await _scrollTo(tester, restore);
  expect(restore, findsOneWidget);
  await tester.tap(restore);
}

class _OperatorAcknowledgement {
  _OperatorAcknowledgement(this._acknowledgement, this._stage);

  final File _acknowledgement;
  final String _stage;

  static Future<_OperatorAcknowledgement> start(String stage) async {
    final directory = Directory(
      paths.join(
        (await getApplicationSupportDirectory()).path,
        'singbook-app-qa',
        _qaSession,
      ),
    );
    await directory.create(recursive: true);
    final safeStage = stage.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final acknowledgement = File(paths.join(directory.path, '$safeStage.ack'));
    if (await acknowledgement.exists()) await acknowledgement.delete();
    debugPrint(
      'SINGBOOK_APP_UI_WAIT:$_qaSession:$safeStage:${acknowledgement.path}',
    );
    return _OperatorAcknowledgement(acknowledgement, safeStage);
  }

  Future<void> wait(WidgetTester tester) async {
    // Keep Flutter frames advancing while native Files returns its result.
    // One long runAsync wait can leave the restore modal unrendered on a
    // phone after an orientation transition.
    final deadline = DateTime.now().add(const Duration(seconds: 600));
    var acknowledged = false;
    while (DateTime.now().isBefore(deadline)) {
      final ready = await tester.runAsync(() async {
        if (!await _acknowledgement.exists()) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          return false;
        }
        await _acknowledgement.delete();
        return true;
      });
      await tester.pump(const Duration(milliseconds: 100));
      if (ready == true) {
        debugPrint('SINGBOOK_APP_UI_ACK:$_qaSession:$_stage');
        acknowledged = true;
        break;
      }
    }
    expect(
      acknowledged,
      isTrue,
      reason: 'Operator acknowledgement failed for stage $_stage',
    );
  }

  Future<bool> waitReal() async {
    final deadline = DateTime.now().add(const Duration(seconds: 600));
    while (DateTime.now().isBefore(deadline)) {
      if (await _acknowledgement.exists()) {
        await _acknowledgement.delete();
        debugPrint('SINGBOOK_APP_UI_ACK:$_qaSession:$_stage');
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }
}

Future<void> _shareFixtureFile(
  WidgetTester tester,
  File file,
  String stage,
) async {
  final acknowledgement = await _OperatorAcknowledgement.start(stage);
  final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
  final origin = Offset.zero & logicalSize;
  final result = await tester.runAsync(() async {
    final shared = SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        title: paths.basename(file.path),
        sharePositionOrigin: origin,
      ),
    );
    final value = await shared;
    if (!await acknowledgement.waitReal()) return null;
    return value;
  });
  expect(
    result,
    isNotNull,
    reason: 'Native file-sharing flow did not complete for ${file.path}',
  );
  expect(result!.status, ShareResultStatus.success);
}

Future<void> _tapDialogAction(WidgetTester tester, String label) async {
  final dialog = find.byType(AlertDialog).last;
  final filled = find.descendant(
    of: dialog,
    matching: find.widgetWithText(FilledButton, label),
  );
  final text = find.descendant(
    of: dialog,
    matching: find.widgetWithText(TextButton, label),
  );
  final action = filled.evaluate().isNotEmpty ? filled : text;
  expect(
    action,
    findsOneWidget,
    reason: 'Expected $label in the current dialog',
  );
  await tester.tap(action);
  await _pumpUi(tester);
}

Future<void> _waitForEnabled(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (tester.widget<ListTile>(finder).enabled) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
  }
  fail('Timed out waiting for the app action to finish: $finder');
}

Future<void> _waitForRealAsync(
  WidgetTester tester,
  bool Function() condition,
  String description,
) async {
  for (var attempt = 0; attempt < 240; attempt++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 250));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
  }
  expect(condition(), isTrue, reason: 'Timed out waiting for $description');
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
    await _pumpUi(tester);
    if (target.hitTestable().evaluate().isNotEmpty) return;
  }
  for (var attempt = 0; attempt < 20; attempt++) {
    if (target.evaluate().isNotEmpty &&
        target.hitTestable().evaluate().isNotEmpty) {
      return;
    }
    final ancestors = find.ancestor(
      of: target,
      matching: find.byType(Scrollable),
    );
    final scrollable = ancestors.evaluate().isNotEmpty
        ? ancestors.first
        : find.byType(Scrollable).hitTestable().last;
    await tester.drag(scrollable, const Offset(0, -260));
    await tester.pump(const Duration(milliseconds: 120));
  }
  await tester.ensureVisible(target);
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _capture(String name) async {
  await captureIosCheckpoint(name);
}

Future<void> _rotate(WidgetTester tester, bool landscape) async {
  if (_hostRotation) {
    await SystemChrome.setPreferredOrientations([]);
    debugPrint(
      'SINGBOOK_NATIVE_ROTATE:${landscape ? 'landscape' : 'portrait'}',
    );
  } else {
    await SystemChrome.setPreferredOrientations([
      landscape
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.portraitUp,
    ]);
  }
  for (var attempt = 0; attempt < (_hostRotation ? 480 : 40); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await _pumpUi(tester);
    final size = tester.view.physicalSize;
    if (landscape ? size.width > size.height : size.height > size.width) return;
  }
  fail('App workflow native rotation did not complete');
}

// Restore keeps its progress indicator animating behind the modal until the
// user finishes the dialog. Wait for transitions without requiring idle frames.
Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
