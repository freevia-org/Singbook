import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/library/editor_screen.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/verse_app.dart';

void main() {
  testWidgets('untouched new-song template returns without saving', (
    tester,
  ) async {
    final controller = _TestController(title: '');
    addTearDown(controller.dispose);
    var backCalls = 0;
    await _pumpEditor(
      tester,
      controller,
      edit: false,
      onBack: () => backCalls++,
    );
    final body = tester.widget<TextField>(
      find.byKey(const ValueKey('editor-lyrics-input')),
    );
    expect(body.controller!.text, contains('{start_of_verse: 1}'));
    final l10n = AppLocalizations.of(tester.element(find.byType(EditorScreen)));
    await tester.tap(find.byTooltip(l10n.actionSave));
    await tester.pump();
    expect(backCalls, 1);
    expect(controller.savedBodies, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated Save taps during keyboard hide save only once', (
    tester,
  ) async {
    final controller = _TestController();
    addTearDown(controller.dispose);
    final hideGate = Completer<void>();
    final hideCalled = Completer<void>();
    var hideCalls = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput,
      (call) async {
        if (call.method == 'TextInput.hide') {
          hideCalls++;
          if (!hideCalled.isCompleted) hideCalled.complete();
          await hideGate.future;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        null,
      ),
    );

    await _pumpEditor(tester, controller);
    final save = find.byTooltip(
      AppLocalizations.of(tester.element(find.byType(EditorScreen))).actionSave,
    );
    await tester.tap(save);
    await tester.pump();
    await hideCalled.future;

    expect(hideCalls, 1);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(of: save, matching: find.byType(IconButton)),
          )
          .onPressed,
      isNull,
    );
    expect(controller.savedBodies, isEmpty);

    hideGate.complete();
    await tester.pump(const Duration(milliseconds: 221));
    await tester.pump();

    expect(controller.savedBodies, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing before keyboard hide completes skips the save', (
    tester,
  ) async {
    final controller = _TestController();
    addTearDown(controller.dispose);
    final hideGate = Completer<void>();
    final hideCalled = Completer<void>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput,
      (call) async {
        if (call.method == 'TextInput.hide') {
          if (!hideCalled.isCompleted) hideCalled.complete();
          await hideGate.future;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        null,
      ),
    );

    await _pumpEditor(tester, controller);
    final l10n = AppLocalizations.of(tester.element(find.byType(EditorScreen)));
    await tester.tap(find.byTooltip(l10n.actionSave));
    await tester.pump();
    await hideCalled.future;

    await tester.pumpWidget(const SizedBox());
    hideGate.complete();
    await tester.pump(const Duration(milliseconds: 221));
    await tester.pump();

    expect(controller.savedBodies, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpEditor(
  WidgetTester tester,
  _TestController controller, {
  bool edit = true,
  VoidCallback? onBack,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: singbookLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EditorScreen(controller: controller, onBack: onBack ?? () {}),
      ),
    ),
  );
  if (edit) {
    // These transition tests need an actual edit before Save becomes useful.
    tester
            .widget<TextField>(
              find.byKey(const ValueKey('editor-lyrics-input')),
            )
            .controller!
            .text =
        '[C]New lyrics';
    await tester.pump();
  }
}

class _TestController extends VerseUiController {
  _TestController({this.title = 'Song'});
  final String title;
  final savedBodies = <String>[];
  final _position = ValueNotifier(PlayerPosition.zero);
  final _notices = StreamController<UiNotice>.broadcast();

  @override
  VerseUiState get state => VerseUiState(
    route: VerseRoute.editor,
    editing: true,
    editor: SongEditorData(songId: 'draft', isNew: true, title: title),
  );

  @override
  ValueListenable<PlayerPosition> get playerPosition => _position;

  @override
  Stream<UiNotice> get notices => _notices.stream;

  @override
  void setEditorDirty(bool value) {}

  @override
  Future<void> saveLyricsEdit(String chordProText) async {
    savedBodies.add(chordProText);
  }

  @override
  void dispose() {
    _notices.close();
    _position.dispose();
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
