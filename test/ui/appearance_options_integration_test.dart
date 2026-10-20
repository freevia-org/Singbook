import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  for (final family in [
    'sans-serif',
    'serif',
    'monospace',
    'Lora',
    'Nunito',
    'Source Sans 3',
  ]) {
    for (final brightness in Brightness.values) {
      test(
        'selected $family reaches body and heading styles in $brightness',
        () {
          final theme = verseTheme(
            brightness: brightness,
            palette: 'navy',
            fontFamily: family,
          );
          for (final style in [
            theme.textTheme.bodyLarge,
            theme.textTheme.bodyMedium,
            theme.textTheme.titleLarge,
            theme.textTheme.labelMedium,
            theme.textTheme.displaySmall,
          ]) {
            expect(style!.fontFamily, family);
          }
        },
      );
    }
  }

  for (final entry in [
    ('lora', 'Lora'),
    ('nunito', 'Nunito'),
    ('sourceSans', 'Source Sans 3'),
  ]) {
    testWidgets(
      'saved ${entry.$1} font reaches actual Appearance lyric preview',
      (tester) async {
        // Startup sweeps its share cache. Keep that platform request inside a
        // unique, nonexistent test path instead of the host's actual cache.
        final cachePath =
            '${Directory.systemTemp.path}${Platform.pathSeparator}'
            'singbook-font-preview-${DateTime.now().microsecondsSinceEpoch}';
        expect(
          await tester.runAsync(() => Directory(cachePath).exists()),
          isFalse,
        );
        const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathChannel, (call) async {
              if (call.method == 'getTemporaryDirectory') return cachePath;
              throw MissingPluginException();
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(pathChannel, null),
        );
        sqfliteFfiInit();
        final (repository, app) = (await tester.runAsync(() async {
          final repository = await LibraryRepository.open(
            path: inMemoryDatabasePath,
            factory: databaseFactoryFfi,
          );
          final app = AppController(repository: repository);
          await app.initialize();
          await app.setSetting('fontFamily', entry.$1);
          await app.setSetting('locale', 'bg');
          return (repository, app);
        }))!;
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox.shrink());
          app.dispose();
          await tester.runAsync(repository.close);
        });
        await tester.runAsync(() async {
          await tester.pumpWidget(VerseApp(controller: app));
          // SQLite initialization completes in the real async zone, while the
          // app's startup spinner schedules frames until that work finishes.
          for (
            var i = 0;
            i < 100 && find.byType(VerseAppShell).evaluate().isEmpty;
            i++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            await tester.pump();
          }
        });
        await tester.pumpAndSettle();
        final shell = tester.widget<VerseAppShell>(find.byType(VerseAppShell));
        final adapter = shell.controller as AppControllerAdapter;
        adapter.setTab(VerseTab.settings);
        await tester.pumpAndSettle();
        await _openAppearance(tester);
        final previews = tester.widgetList<ChordLyricsLine>(
          find.byType(ChordLyricsLine),
        );
        expect(previews, isNotEmpty);
        expect(adapter.state.fontFamily, entry.$1);
        for (final line in previews) {
          expect(line.style!.fontFamily, entry.$2);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

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
