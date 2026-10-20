import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  for (final font in [
    'system',
    'serif',
    'mono',
    'lora',
    'nunito',
    'sourceSans',
  ]) {
    test('font preference $font survives a portable backup round trip', () {
      final bytes = encodeLibraryPackage(
        [],
        [],
        preferences: {'fontFamily': font},
      );
      expect(decodeLibraryPackage(bytes).preferences?['fontFamily'], font);
    });
  }

  testWidgets('font options preview their own family', (tester) async {
    final controller = FakeUiController(
      (_) => const VerseUiState(activeTab: VerseTab.settings),
    );
    addTearDown(controller.dispose);
    await pumpShell(tester, controller);
    await _openAppearance(tester);
    final dropdown = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButton<String> &&
          widget.items!.any((item) => item.value == 'lora'),
    );
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    for (final entry in [
      ('Lora', 'Lora'),
      ('Nunito', 'Nunito'),
      ('Source Sans 3', 'Source Sans 3'),
    ]) {
      final item = find.widgetWithText(DropdownMenuItem<String>, entry.$1);
      final label = find.descendant(of: item, matching: find.text(entry.$1));
      expect(tester.widget<Text>(label).style?.fontFamily, entry.$2);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'System theme preview follows platform brightness in a light shell',
    (tester) async {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.dark;
      addTearDown(
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
      );
      final controller = FakeUiController(
        (_) => const VerseUiState(activeTab: VerseTab.settings),
      );
      addTearDown(controller.dispose);
      await pumpShell(tester, controller);
      await _openAppearance(tester);
      final dropdown = find.byType(DropdownButton<AppThemeMode>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      for (final entry in [
        (AppThemeMode.system, Brightness.dark),
        (AppThemeMode.light, Brightness.light),
        (AppThemeMode.dark, Brightness.dark),
      ]) {
        final item = find.byWidgetPredicate(
          (widget) =>
              widget is DropdownMenuItem<AppThemeMode> &&
              widget.value == entry.$1,
        );
        final coloredContainers = tester
            .widgetList<Container>(
              find.descendant(of: item, matching: find.byType(Container)),
            )
            .where(
              (widget) =>
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).color != null,
            );
        expect(coloredContainers, hasLength(1));
        expect(
          (coloredContainers.single.decoration! as BoxDecoration).color,
          verseTheme(brightness: entry.$2, palette: 'navy').colorScheme.surface,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('palette options use their own app accents', (tester) async {
    final controller = FakeUiController(
      (_) => const VerseUiState(activeTab: VerseTab.settings),
    );
    addTearDown(controller.dispose);
    await pumpShell(tester, controller);
    await _openAppearance(tester);
    final dropdown = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButton<String> &&
          widget.items!.any((item) => item.value == 'sage'),
    );
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    for (final palette in ['navy', 'sage', 'ocean', 'clay', 'plum']) {
      final item = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownMenuItem<String> && widget.value == palette,
      );
      final dots = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: item, matching: find.byType(DecoratedBox)),
          )
          .where(
            (widget) =>
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          )
          .map((widget) => (widget.decoration as BoxDecoration).color);
      final colors = verseTheme(
        brightness: Brightness.light,
        palette: palette,
      ).colorScheme;
      expect(dots, [colors.primary, colors.tertiary]);
    }
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openAppearance(WidgetTester tester) async {
  final item = find.byKey(const ValueKey('settings-menu-appearance'));
  await tester.ensureVisible(item);
  await tester.tap(item);
  await tester.pumpAndSettle();
}
