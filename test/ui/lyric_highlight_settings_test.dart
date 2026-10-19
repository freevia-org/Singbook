import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  sqfliteFfiInit();
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('highlight choices persist through Settings at 2x ($locale)', (
      tester,
    ) async {
      late LibraryRepository repository;
      late AppController app;
      late AppControllerAdapter controller;
      await tester.runAsync(() async {
        repository = await LibraryRepository.open(
          path: inMemoryDatabasePath,
          factory: databaseFactoryFfi,
        );
        app = AppController(repository: repository);
        await app.initialize();
        controller = AppControllerAdapter(app)..setTab(VerseTab.settings);
      });
      await pumpShell(
        tester,
        controller,
        locale: locale,
        textScale: 2,
        size: const Size(320, 640),
      );
      final l10n = l10nOf(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-menu-player')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-player')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(l10n.settingsLyricHighlight),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final dropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButton<String> &&
            widget.items!.any((item) => item.value == 'contrast'),
      );
      expect(tester.widget<DropdownButton<String>>(dropdown).value, 'contrast');
      for (final choice in [
        ('backgroundUnderline', l10n.settingsHighlightBackgroundUnderline),
        ('background', l10n.settingsHighlightBackground),
        ('underline', l10n.settingsHighlightUnderline),
        ('contrast', l10n.settingsHighlightContrast),
        ('none', l10n.settingsHighlightNone),
      ]) {
        await Scrollable.ensureVisible(
          tester.element(dropdown),
          alignment: .15,
        );
        await tester.pumpAndSettle();
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice.$2).last);
        await tester.runAsync(() async {
          // Wait for the asynchronous SQLite setting write to drain.
          expect(
            (await repository.getSetting('app') as Map)['lyricHighlightStyle'],
            choice.$1,
          );
        });
        await tester.pumpAndSettle();
        expect(controller.state.lyricHighlightStyle, choice.$1);
        expect(
          tester.widget<DropdownButton<String>>(dropdown).value,
          choice.$1,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        controller.dispose();
        app.dispose();
        await repository.close();
      });
    });
  }
}
