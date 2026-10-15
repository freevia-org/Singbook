import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

Color _paintedIconColor(WidgetTester tester, IconData data) {
  final icon = find.byIcon(data).first;
  final text = tester.widget<RichText>(
    find.descendant(of: icon, matching: find.byType(RichText)),
  );
  final style = text.text.style!;
  return style.foreground?.color ?? style.color!;
}

double _contrast(Color foreground, Color background) {
  final painted = Color.alphaBlend(foreground, background);
  final luminance = [painted.computeLuminance(), background.computeLuminance()]
    ..sort();
  return (luminance.last + .05) / (luminance.first + .05);
}

void main() {
  testWidgets('painted library actions have contrast in every palette and theme', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = FakeUiController(
      (_) => const VerseUiState(
        activeTab: VerseTab.songs,
        songs: [
          SongCardData(id: 'song', title: 'Lanterns at Dawn', artist: 'Mira Vale'),
        ],
      ),
    );
    addTearDown(controller.dispose);

    for (final palette in versePalettes) {
      for (final brightness in Brightness.values) {
        final theme = verseTheme(brightness: brightness, palette: palette.name);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: VerseAppShell(
              controller: controller,
              files: VerseFileActions(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final surface = theme.colorScheme.surface;
        for (final icon in [
          Icons.favorite_border_rounded,
          Icons.more_horiz_rounded,
        ]) {
          expect(
            _contrast(_paintedIconColor(tester, icon), surface),
            greaterThanOrEqualTo(3),
            reason: '${palette.name}/${brightness.name}: $icon',
          );
        }
        expect(
          _contrast(
            _paintedIconColor(tester, Icons.add_rounded),
            theme.colorScheme.secondaryContainer,
          ),
          greaterThanOrEqualTo(3),
          reason: '${palette.name}/${brightness.name}: tonal add button',
        );
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
