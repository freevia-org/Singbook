import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/library/editor_screen.dart';
import 'package:singbook/ui/library/setlists_screen.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _playerState = VerseUiState(
  song: SongCardData(
    id: 'song',
    title: 'Keyboard fixture',
    durationSeconds: 60,
  ),
  playerSections: [
    PlayerSectionMarker(name: 'Verse', startSeconds: 0, lineId: 'verse'),
    PlayerSectionMarker(name: 'Chorus', startSeconds: 20, lineId: 'chorus'),
  ],
);

void main() {
  _windowsTestWidgets(
    'player Space and Ctrl arrows use transport section actions',
    (tester) async {
      final controller = FakeUiController((_) => _playerState);
      addTearDown(controller.dispose);
      await _pump(tester, PlayerScreen(controller: controller));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _controlKey(tester, LogicalKeyboardKey.arrowRight);
      await _controlKey(tester, LogicalKeyboardKey.arrowLeft);
      expect(controller.calls, ['playPause', 'seek(20.0)', 'seek(0.0)']);
      expect(find.byTooltip('Play (Space)'), findsOneWidget);
    },
  );

  _windowsTestWidgets(
    'focused player buttons activate without toggling playback',
    (tester) async {
      final controller = FakeUiController((_) => _playerState);
      addTearDown(controller.dispose);
      await _pump(tester, PlayerScreen(controller: controller));

      final favoriteFocus = Focus.of(
        tester.element(find.byIcon(Icons.favorite_border_rounded)),
      );
      favoriteFocus.requestFocus();
      await tester.pump();
      expect(favoriteFocus.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(controller.calls, ['toggleFavorite(song)']);

      final menuFocus = Focus.of(
        tester.element(find.byKey(const ValueKey('scroll-speed-toggle-label'))),
      );
      menuFocus.requestFocus();
      await tester.pump();
      expect(menuFocus.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scroll-speed-panel')), findsOneWidget);
      expect(controller.calls, ['toggleFavorite(song)']);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    },
  );

  _windowsTestWidgets('player popup and text entry retain keyboard focus', (
    tester,
  ) async {
    final controller = FakeUiController((_) => _playerState);
    addTearDown(controller.dispose);
    await _pump(tester, PlayerScreen(controller: controller));

    await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _controlKey(tester, LogicalKeyboardKey.arrowRight);
    expect(controller.calls, isNot(contains('playPause')));
    expect(controller.calls.where((call) => call.startsWith('seek(')), isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PlayerScreen));
    final text = TextEditingController();
    addTearDown(text.dispose);
    showDialog<void>(
      context: context,
      builder: (_) =>
          AlertDialog(content: TextField(autofocus: true, controller: text)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'typing lyrics');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _controlKey(tester, LogicalKeyboardKey.arrowLeft);
    expect(text.text, 'typing lyrics');
    expect(controller.calls, isNot(contains('playPause')));
    expect(controller.calls.where((call) => call.startsWith('seek(')), isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  });

  _windowsTestWidgets(
    'focused player seek slider keeps ordinary arrow handling',
    (tester) async {
      final controller = FakeUiController((_) => _playerState);
      addTearDown(controller.dispose);
      await _pump(tester, PlayerScreen(controller: controller));
      final slider = find.byKey(const ValueKey('player-seek-slider'));
      final detector = tester.widget<FocusableActionDetector>(
        find.descendant(
          of: slider,
          matching: find.byType(FocusableActionDetector),
        ),
      );
      detector.focusNode!.requestFocus();
      await tester.pump();
      expect(detector.focusNode!.hasFocus, isTrue);
      controller.calls.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        controller.calls.where((call) => call.startsWith('seek(')),
        isNotEmpty,
      );
      expect(controller.calls, isNot(contains('playPause')));
      expect(tester.takeException(), isNull);
    },
  );

  _windowsTestWidgets(
    'editor Ctrl S validates and saves while typing stays intact',
    (tester) async {
      final controller = FakeUiController(
        (_) => const VerseUiState(
          editor: SongEditorData(songId: 'song', isNew: false, body: 'Initial'),
        ),
      );
      addTearDown(controller.dispose);
      await _pump(tester, EditorScreen(controller: controller, onBack: () {}));

      final body = find.byKey(const ValueKey('editor-lyrics-input'));
      await tester.enterText(body, 'New lyrics');
      await _controlKey(tester, LogicalKeyboardKey.keyS);
      await tester.pumpAndSettle();
      expect(
        controller.calls.where((call) => call.startsWith('saveLyricsEdit(')),
        isEmpty,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(EditorScreen)),
      );
      expect(find.text(l10n.editorFieldRequired), findsOneWidget);
      final title = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == l10n.editorTitleField,
      );
      await tester.enterText(title, 'Saved title');
      await tester.enterText(body, 'New lyrics');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(tester.widget<TextField>(body).controller!.text, 'New lyrics');
      await _controlKey(tester, LogicalKeyboardKey.keyS);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 230));
      await tester.pumpAndSettle();
      final saves = controller.calls.where(
        (call) => call.startsWith('saveLyricsEdit('),
      );
      expect(saves, hasLength(1));
      expect(saves.single, contains('{title: Saved title}'));
      expect(saves.single, contains('New lyrics'));
    },
  );

  _windowsTestWidgets(
    'setlist mouse clicks open menus and whole rows drag without delay',
    (tester) async {
      final controller = _setlistController();
      addTearDown(controller.dispose);
      await _pump(tester, SetlistDetailScreen(controller: controller));
      final row = find.byKey(const ValueKey('one'));
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byType(PopupMenuButton<String>),
        ),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is PopupMenuItem<String> && widget.value == 'edit',
        ),
        findsOneWidget,
      );
      expect(
        controller.calls.where((call) => call.startsWith('saveSetlistDetails')),
        isEmpty,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final start = tester.getCenter(find.text('First song'));
      final secondRow = tester.getRect(find.byKey(const ValueKey('two')));
      final end = Offset(start.dx, secondRow.bottom - 4);
      final gesture = await tester.startGesture(
        start,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 24));
      await tester.pump();
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      await gesture.moveTo(end);
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        tester
            .getRect(find.byKey(const ValueKey('setlist-delete-basket')))
            .contains(end),
        isFalse,
        reason: 'A reorder drop must remain above the delete basket.',
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        controller.calls,
        contains('saveSetlistDetails(Set, , [two, one], false)'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  _windowsTestWidgets(
    'setlist no-op downward drop clears the basket without saving an order',
    (tester) async {
      final controller = _setlistController();
      addTearDown(controller.dispose);
      await _pump(tester, SetlistDetailScreen(controller: controller));
      var list = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      list.onReorderStart!(0);
      await tester.pump();
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      list = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      // Flutter reports the raw insertion slot to onReorderEnd. Slot old+1
      // normalizes back to old, so it deliberately omits onReorderItem.
      list.onReorderEnd!(1);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(
        controller.calls.where((call) => call.startsWith('saveSetlistDetails')),
        isEmpty,
      );
      expect(
        controller.calls.where((call) => call.startsWith('remove')),
        isEmpty,
      );
    },
  );

  _windowsTestWidgets(
    'Windows touch rows still require a long press to reorder',
    (tester) async {
      final controller = _setlistController();
      addTearDown(controller.dispose);
      await _pump(tester, SetlistDetailScreen(controller: controller));
      final row = find.byKey(const ValueKey('one'));
      final gesture = await tester.startGesture(tester.getCenter(row));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 24));
      await tester.pump();
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        controller.calls.where((call) => call.startsWith('saveSetlistDetails')),
        isEmpty,
      );

      final held = await tester.startGesture(tester.getCenter(row));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 20));
      await held.moveBy(const Offset(0, 24));
      await tester.pump();
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      await held.up();
      await tester.pumpAndSettle();
    },
  );
}

void _windowsTestWidgets(
  String description,
  Future<void> Function(WidgetTester) callback,
) => testWidgets(
  description,
  callback,
  variant: TargetPlatformVariant.only(TargetPlatform.windows),
);

Future<void> _controlKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
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

FakeUiController _setlistController() => FakeUiController(
  (_) => const VerseUiState(
    activeSetlist: SetlistCardData(
      id: 'set',
      title: 'Set',
      entries: [
        SetlistEntryData(id: 'one', songId: 'first', title: 'First song'),
        SetlistEntryData(id: 'two', songId: 'second', title: 'Second song'),
      ],
    ),
  ),
);
