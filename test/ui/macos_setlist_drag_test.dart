import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/library/setlists_screen.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  testWidgets(
    'macOS setlist row preserves menu clicks and starts mouse reorder immediately',
    (tester) async {
      final controller = FakeUiController(
        (_) => const VerseUiState(
          activeSetlist: SetlistCardData(
            id: 'set',
            title: 'Set',
            entries: [
              SetlistEntryData(id: 'one', songId: 'first', title: 'First song'),
              SetlistEntryData(
                id: 'two',
                songId: 'second',
                title: 'Second song',
              ),
            ],
          ),
        ),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: singbookLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SetlistDetailScreen(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

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
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        controller.calls,
        contains('saveSetlistDetails(Set, , [two, one], false)'),
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
