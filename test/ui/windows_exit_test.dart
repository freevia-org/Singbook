import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  testWidgets('window exit can cancel without losing the editor draft', (
    tester,
  ) async {
    final controller = FakeUiController(
      (c) => VerseUiState(
        route: VerseRoute.editor,
        editing: true,
        editorDirty: c.dirty,
        editor: const SongEditorData(
          songId: 's',
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
    final exit = tester.binding.handleRequestAppExit();
    await tester.pumpAndSettle();
    expect(find.text(l10n.editorUnsavedTitle), findsOneWidget);
    await tester.tap(find.text(l10n.editorKeepEditing));
    await tester.pumpAndSettle();
    expect(await exit, AppExitResponse.cancel);
    expect(controller.state.editorDirty, isTrue);
    expect(controller.calls, isNot(contains('back')));

    final discardExit = tester.binding.handleRequestAppExit();
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.actionDiscard));
    await tester.pumpAndSettle();
    expect(await discardExit, AppExitResponse.exit);
  });

  testWidgets(
    'repeated close requests share a single prompt; saved state can exit',
    (tester) async {
      final controller = FakeUiController(
        (c) => VerseUiState(
          route: VerseRoute.editor,
          editing: true,
          editorDirty: c.dirty,
          editor: const SongEditorData(
            songId: 's',
            isNew: false,
            title: 'Draft',
          ),
        ),
      );
      addTearDown(controller.dispose);
      controller.dirty = true;
      await pumpShell(tester, controller, size: const Size(1100, 720));
      final l10n = l10nOf(tester);
      final first = tester.binding.handleRequestAppExit();
      final second = tester.binding.handleRequestAppExit();
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsOneWidget);
      await tester.tap(find.text(l10n.editorKeepEditing));
      await tester.pumpAndSettle();
      expect(await first, AppExitResponse.cancel);
      expect(await second, AppExitResponse.cancel);
      controller.dirty = false;
      controller.refresh();
      await tester.pumpAndSettle();
      expect(await tester.binding.handleRequestAppExit(), AppExitResponse.exit);
    },
  );
}
