import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/library/editor_screen.dart';
import 'package:singbook/ui/library_actions.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import '../ui/support/fake_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'desktop content fills a wide window without tablet side gutters',
    (tester) async {
      final controller = FakeUiController((_) => const VerseUiState());
      addTearDown(controller.dispose);
      await pumpShell(tester, controller, size: const Size(1920, 1080));
      final frame = tester.getRect(
        find.byKey(const ValueKey('tablet-content-frame')),
      );
      expect(frame.right, closeTo(1920, 1));
      expect(frame.width, greaterThan(1700));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    }),
  );

  testWidgets(
    'macOS player uses Space and Command arrows, preserving text input',
    (tester) async {
      final controller = FakeUiController(
        (_) => const VerseUiState(
          song: SongCardData(id: 'song', title: 'Keyboard fixture'),
          playerSections: [
            PlayerSectionMarker(name: 'Verse', startSeconds: 0, lineId: 'v'),
            PlayerSectionMarker(name: 'Chorus', startSeconds: 20, lineId: 'c'),
          ],
        ),
      );
      addTearDown(controller.dispose);
      await _pump(tester, PlayerScreen(controller: controller));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _commandKey(tester, LogicalKeyboardKey.arrowRight);
      expect(controller.calls, ['playPause', 'seek(20.0)']);
      expect(find.byTooltip('Play (Space)'), findsOneWidget);

      final text = TextEditingController();
      addTearDown(text.dispose);
      showDialog<void>(
        context: tester.element(find.byType(PlayerScreen)),
        builder: (_) =>
            AlertDialog(content: TextField(autofocus: true, controller: text)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'typing lyrics');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _commandKey(tester, LogicalKeyboardKey.arrowLeft);
      expect(text.text, 'typing lyrics');
      expect(controller.calls, ['playPause', 'seek(20.0)']);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'macOS editor Command S saves, while typing stays intact',
    (tester) async {
      final controller = FakeUiController(
        (_) => const VerseUiState(
          editor: SongEditorData(songId: 'song', isNew: false, body: 'Initial'),
        ),
      );
      addTearDown(controller.dispose);
      await _pump(tester, EditorScreen(controller: controller, onBack: () {}));

      final title = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText ==
                AppLocalizations.of(
                  tester.element(find.byType(EditorScreen)),
                ).editorTitleField,
      );
      final body = find.byKey(const ValueKey('editor-lyrics-input'));
      await tester.enterText(title, 'Saved title');
      await tester.enterText(body, 'New lyrics');
      await _commandKey(tester, LogicalKeyboardKey.keyS);
      await tester.pump(const Duration(milliseconds: 230));
      await tester.pumpAndSettle();
      final saves = controller.calls.where(
        (call) => call.startsWith('saveLyricsEdit('),
      );
      expect(saves, hasLength(1));
      expect(saves.single, contains('{title: Saved title}'));
      expect(saves.single, contains('New lyrics'));
      expect(find.byTooltip('Save (⌘S)'), findsOneWidget);
      await tester.enterText(title, 'Native saved title');
      final nativeSave = _nativeMacEditorSave(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 230));
      await tester.pumpAndSettle();
      expect(await nativeSave, isTrue);
      expect(
        controller.calls.where((call) => call.startsWith('saveLyricsEdit(')),
        hasLength(2),
      );
      expect(controller.calls.last, contains('Native saved title'));
      showDialog<void>(
        context: tester.element(find.byType(EditorScreen)),
        builder: (_) => const AlertDialog(content: Text('Modal owns focus')),
      );
      await tester.pumpAndSettle();
      expect(await _nativeMacEditorSave(tester), isFalse);
      expect(
        controller.calls.where((call) => call.startsWith('saveLyricsEdit(')),
        hasLength(2),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'macOS native window close can cancel or discard a dirty editor',
    (tester) async {
      final controller = FakeUiController(
        (c) => VerseUiState(
          route: VerseRoute.editor,
          editing: true,
          editorDirty: c.dirty,
          editor: const SongEditorData(
            songId: 'song',
            isNew: false,
            title: 'Draft',
            body: 'Original',
          ),
        ),
      );
      addTearDown(controller.dispose);
      controller.dirty = true;
      await pumpShell(tester, controller, size: const Size(1100, 720));
      final l10n = l10nOf(tester);

      final cancel = _nativeMacClose(tester);
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsOneWidget);
      await tester.tap(find.text(l10n.editorKeepEditing));
      await tester.pumpAndSettle();
      expect(await cancel, isFalse);
      expect(controller.state.editorDirty, isTrue);
      expect(controller.calls, isNot(contains('back')));

      final discard = _nativeMacClose(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.actionDiscard));
      await tester.pumpAndSettle();
      expect(await discard, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'macOS library actions use desktop export wording',
    (tester) async {
      late AppLocalizations l10n;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return Material(
              child: Column(
                children:
                    buildLibraryActionMenu(
                          l10n,
                          actions: const {'share', 'share_pdf'},
                        )
                        .whereType<PopupMenuItem<String>>()
                        .map((entry) => entry.child ?? const SizedBox.shrink())
                        .toList(),
              ),
            );
          },
        ),
      );
      expect(find.text('${l10n.actionExport} · ChordPro'), findsOneWidget);
      expect(find.text('${l10n.actionExport} · PDF'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  test(
    'macOS song export uses Save As and preserves the ChordPro bytes',
    () async {
      final song = SongDocument(
        id: 'mac-song',
        title: 'Світло 夜',
        artist: 'Fixture',
        body: '[Em]Lyrics',
      );
      Uint8List? savedBytes;
      String? suggestedName;
      String? capturedMimeType;
      var shareCalled = false;
      final files = VerseFileActions(
        platform: TargetPlatform.macOS,
        saveFile:
            ({
              required String fileName,
              required Uint8List bytes,
              required String mimeType,
            }) async {
              suggestedName = fileName;
              savedBytes = Uint8List.fromList(bytes);
              capturedMimeType = mimeType;
              return Uri.file('/tmp/$fileName');
            },
        shareFiles: (_) async {
          shareCalled = true;
          return const ShareResult('unexpected', ShareResultStatus.success);
        },
      );
      final result = await files.shareSong(song);
      expect(result.status, ShareResultStatus.success);
      expect(suggestedName, '${song.title}.cho');
      expect(capturedMimeType, 'text/plain');
      expect(
        savedBytes,
        orderedEquals(utf8.encode(ChordProCodec().encode(song))),
      );
      expect(shareCalled, isFalse);
    },
  );

  test('cancelled macOS Save As reports dismissal', () async {
    final files = VerseFileActions(
      platform: TargetPlatform.macOS,
      saveFile:
          ({required fileName, required bytes, required mimeType}) async =>
              null,
      shareFiles: (_) async => throw StateError('cancel must not share'),
    );
    final result = await files.shareBackupBytes(Uint8List.fromList([1, 2, 3]));
    expect(result.status, ShareResultStatus.dismissed);
    expect(result.raw, isEmpty);
  });
}

Future<void> _commandKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pump();
}

Future<Object?> _nativeMacEditorSave(WidgetTester tester) async {
  const codec = StandardMethodCodec();
  final reply = Completer<ByteData?>();
  tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'org.freevia.singbook/editor_shortcuts',
    codec.encodeMethodCall(const MethodCall('save')),
    reply.complete,
  );
  final bytes = await reply.future;
  return bytes == null ? null : codec.decodeEnvelope(bytes);
}

Future<Object?> _nativeMacClose(WidgetTester tester) async {
  const codec = StandardMethodCodec();
  final reply = Completer<ByteData?>();
  tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'org.freevia.singbook/window_close',
    codec.encodeMethodCall(const MethodCall('requestClose')),
    reply.complete,
  );
  final bytes = await reply.future;
  return bytes == null ? null : codec.decodeEnvelope(bytes);
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: singbookLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: screen),
    ),
  );
  await tester.pumpAndSettle();
}
