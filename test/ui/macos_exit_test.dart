import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  testWidgets(
    'native macOS close asks before discarding edits and permits clean exit',
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
            body: 'Original',
          ),
        ),
      );
      addTearDown(controller.dispose);
      controller.dirty = true;
      await pumpShell(tester, controller, size: const Size(1100, 720));
      final l10n = l10nOf(tester);

      final cancel = _nativeClose(tester);
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsOneWidget);
      await tester.tap(find.text(l10n.editorKeepEditing));
      await tester.pumpAndSettle();
      expect(await cancel, isFalse);
      expect(controller.state.editorDirty, isTrue);
      expect(controller.calls, isNot(contains('back')));

      final discard = _nativeClose(tester);
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsOneWidget);
      await tester.tap(find.text(l10n.actionDiscard));
      await tester.pumpAndSettle();
      expect(await discard, isTrue);

      controller.dirty = false;
      controller.refresh();
      await tester.pumpAndSettle();
      expect(await _nativeClose(tester), isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(await _nativeClose(tester), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}

Future<Object?> _nativeClose(WidgetTester tester) async {
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
