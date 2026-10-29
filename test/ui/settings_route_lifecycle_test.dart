import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  for (final section in [
    'sources',
    'account',
    'appearance',
    'player',
    'about',
  ]) {
    testWidgets(
      'manual $section Back followed by shell navigation cannot pop the root',
      (tester) async {
        var state = const VerseUiState(activeTab: VerseTab.settings);
        final controller = FakeUiController((_) => state);
        addTearDown(controller.dispose);
        await pumpShell(tester, controller);
        final menu = find.byKey(ValueKey('settings-menu-$section'));
        await tester.scrollUntilVisible(
          menu,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(menu);
        await tester.pumpAndSettle();
        expect(find.byType(BackButton), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        // The detail remains mounted during its reverse transition. A quick
        // Songs-tab choice must not let its listener pop the root a second time.
        await tester.pump(const Duration(milliseconds: 30));
        state = const VerseUiState(activeTab: VerseTab.home);
        controller.refresh();
        await tester.pumpAndSettle();
        expect(find.byType(VerseAppShell), findsOneWidget);
        expect(find.byType(BackButton), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
