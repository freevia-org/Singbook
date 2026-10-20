import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/player/player_lyric_line.dart';
import 'package:singbook/ui/settings/lyrics_settings_preview.dart';
import 'package:singbook/ui/settings/settings_screen.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

import 'settings_navigation_test.dart' show open;
import 'support/fake_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);
  for (final brightness in Brightness.values) {
    for (final palette in versePalettes) {
      test('${palette.name} ${brightness.name} active lyric is readable', () {
        final theme = verseTheme(brightness: brightness, palette: palette.name);
        for (final surface in [
          theme.colorScheme.surface,
          verseCardColor(brightness),
        ]) {
          final a = theme.colorScheme.tertiary.computeLuminance();
          final b = surface.computeLuminance();
          final ratio =
              (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
          expect(ratio, greaterThanOrEqualTo(4.5));
        }
        expect(
          theme.colorScheme.tertiary,
          brightness == Brightness.dark
              ? palette.activeLyricDark
              : palette.seed,
        );
      });
    }
  }

  for (final mode in [
    'contrast',
    'background',
    'underline',
    'backgroundUnderline',
    'none',
  ]) {
    testWidgets('preview uses player typography and $mode paint', (
      tester,
    ) async {
      const size = 30.0;
      final state = VerseUiState(
        lyricHighlightStyle: mode,
        lyricsFontSize: size,
      );
      final theme = verseTheme(brightness: Brightness.dark, palette: 'navy');
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: LyricsSettingsPreview(state: state),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final renderers = tester
          .widgetList<PlayerLyricLine>(find.byType(PlayerLyricLine))
          .toList();
      expect(renderers.map((line) => line.current), [true, false]);
      final line = tester.widget<ChordLyricsLine>(
        find.byType(ChordLyricsLine).first,
      );
      expect(line.style!.fontSize, size);
      expect(line.showChords, isTrue);
      expect(
        line.style!.color,
        mode == 'contrast'
            ? theme.colorScheme.tertiary
            : theme.textTheme.bodyLarge!.color,
      );
      expect(
        line.style!.decoration,
        mode.contains('nderline')
            ? TextDecoration.underline
            : theme.textTheme.bodyLarge!.decoration,
      );
      final decoration = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(PlayerLyricLine).first,
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (decoration.decoration as BoxDecoration).color,
        mode.startsWith('background')
            ? theme.colorScheme.primaryContainer.withValues(alpha: .48)
            : Colors.transparent,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'preview hides headings and chords but retains transport labels',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: LyricsSettingsPreview(
              state: VerseUiState(showSections: false, showChords: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('settings-preview-section-heading')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('settings-preview-expanded-controls')),
        findsOneWidget,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LyricsSettingsPreview)),
      );
      expect(find.text(l10n.sectionVerse), findsOneWidget);
      expect(find.text(l10n.sectionChorus), findsOneWidget);
      expect(
        tester
            .widgetList<ChordLyricsLine>(find.byType(ChordLyricsLine))
            .every((line) => !line.showChords),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final section in ['appearance', 'player']) {
    for (final scenario in [
      (const Size(360, 780), const Locale('en'), 1.0),
      (const Size(320, 640), const Locale('uk'), 2.0),
      (const Size(740, 360), const Locale('ar'), 2.0),
    ]) {
      testWidgets('$section preview is reachable at $scenario', (tester) async {
        final controller = FakeUiController(
          (_) => const VerseUiState(activeTab: VerseTab.settings),
        );
        addTearDown(controller.dispose);
        await pumpShell(
          tester,
          controller,
          size: scenario.$1,
          locale: scenario.$2,
          textScale: scenario.$3,
        );
        await open(tester, section);
        final preview = find.byType(LyricsSettingsPreview);
        await tester.scrollUntilVisible(
          preview,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(preview, findsOneWidget);
        expect(tester.takeException(), isNull);
        if (scenario.$3 == 1) {
          final rect = tester.getRect(preview);
          expect(rect.bottom, lessThanOrEqualTo(scenario.$1.height));
        }
      });
    }
  }

  testWidgets('capture compact settings and palette previews', (tester) async {
    if (!const bool.fromEnvironment('SINGBOOK_SETTINGS_CAPTURE')) return;
    final output = Directory('artifacts/settings-preview-captures')
      ..createSync(recursive: true);
    for (final section in ['appearance', 'player']) {
      final boundary = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 780);
      final controller = FakeUiController(
        (_) => const VerseUiState(activeTab: VerseTab.settings),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              RepaintBoundary(key: boundary, child: child!),
          home: Scaffold(body: SettingsScreen(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      await open(tester, section);
      await _capture(tester, boundary, '${output.path}/$section-phone.png');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }
    for (final brightness in Brightness.values) {
      for (final palette in versePalettes) {
        final boundary = GlobalKey();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 780);
        final state = VerseUiState(
          activeTab: VerseTab.settings,
          palette: palette.name,
        );
        final controller = FakeUiController((_) => state);
        await tester.pumpWidget(
          MaterialApp(
            theme: verseTheme(brightness: brightness, palette: palette.name),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                RepaintBoundary(key: boundary, child: child!),
            home: Scaffold(body: LyricsSettingsPreview(state: state)),
          ),
        );
        await tester.pumpAndSettle();
        await _capture(
          tester,
          boundary,
          '${output.path}/${palette.name}-${brightness.name}.png',
        );
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      }
    }
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _loadFonts() async {
  for (final entry in [
    ('sans-serif', 'assets/fonts/NotoSans-Regular.ttf'),
    ('Roboto', 'assets/fonts/NotoSans-Regular.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ('SingbookBrand', 'assets/fonts/SingbookBrand-Bold.ttf'),
    ('SingbookSerif', 'assets/fonts/SingbookSerif-Bold.ttf'),
  ]) {
    await (FontLoader(entry.$1)..addFont(rootBundle.load(entry.$2))).load();
  }
}
