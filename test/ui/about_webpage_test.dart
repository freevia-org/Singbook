import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _capture = bool.fromEnvironment('ABOUT_CAPTURES');

void main() {
  for (final (name, size, locale, scale, brightness) in [
    (
      'phone-en',
      const Size(393, 873),
      const Locale('en'),
      1.0,
      Brightness.light,
    ),
    (
      'phone-bg-large',
      const Size(360, 640),
      const Locale('bg'),
      2.0,
      Brightness.light,
    ),
    (
      'landscape-en-large',
      const Size(640, 360),
      const Locale('en'),
      2.0,
      Brightness.light,
    ),
    (
      'landscape-uk-large-dark',
      const Size(640, 360),
      const Locale('uk'),
      2.0,
      Brightness.dark,
    ),
    (
      'tablet-ar-large-dark',
      const Size(800, 1280),
      const Locale('ar'),
      2.0,
      Brightness.dark,
    ),
  ]) {
    testWidgets('About webpage content scrolls and closes: $name', (
      tester,
    ) async {
      final controller = FakeUiController(
        (_) => const VerseUiState(activeTab: VerseTab.settings),
      );
      addTearDown(controller.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      if (_capture) await _loadFonts();
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: singbookLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: _theme(
            brightness: brightness,
            palette: 'navy',
            fontFamily: _capture ? 'AboutFixture' : 'system',
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: RepaintBoundary(key: boundaryKey, child: child!),
          ),
          home: VerseAppShell(
            controller: controller,
            files: VerseFileActions(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      final about = find.byKey(const ValueKey('settings-menu-about'));
      await tester.ensureVisible(about);
      await tester.pumpAndSettle();
      await tester.tap(about);
      await tester.pumpAndSettle();

      expect(find.text(l10n.aboutDescription), findsOneWidget);
      expect(find.text(l10n.aboutDetails), findsOneWidget);
      expect(find.text(l10n.aboutKeepDetails), findsOneWidget);
      expect(find.text(l10n.aboutPlayDetails), findsOneWidget);
      expect(find.text(l10n.aboutPrivacyDetails), findsOneWidget);
      expect(
        find.text(
          l10n.aboutLanguages(AppLocalizations.supportedLocales.length),
        ),
        findsOneWidget,
      );
      if (_capture) {
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/branding/singbook-mark-foreground.png'),
            boundaryKey.currentContext!,
          ),
        );
        await tester.pump();
      }
      await _snapshot(tester, boundaryKey, '$name-top');
      for (final heading in [
        l10n.aboutFindTitle,
        l10n.aboutKeepTitle,
        l10n.aboutPlayTitle,
        l10n.aboutPrivacyTitle,
      ]) {
        await tester.ensureVisible(find.text(heading));
        await tester.pumpAndSettle();
        expect(
          tester
              .getSemantics(find.text(heading))
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
        );
        expect(tester.takeException(), isNull);
        if (heading == l10n.aboutKeepTitle) {
          await _snapshot(tester, boundaryKey, '$name-middle');
        }
      }
      await tester.ensureVisible(find.text(l10n.aboutPublisher));
      await tester.pumpAndSettle();
      await _snapshot(tester, boundaryKey, '$name-bottom');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text(l10n.settingsAbout), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings-menu-about')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _snapshot(WidgetTester tester, GlobalKey key, String name) async {
  if (!_capture) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = Directory('artifacts/about-webpage/captures-v4')
      ..createSync(recursive: true);
    File(
      '${output.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _loadFonts() async {
  final body = FontLoader('AboutFixture')
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  final arabic = FontLoader('AboutArabic')
    ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  final brand = FontLoader('SingbookBrand')
    ..addFont(rootBundle.load('assets/fonts/SingbookBrand-Bold.ttf'));
  final serif = FontLoader('SingbookSerif')
    ..addFont(rootBundle.load('assets/fonts/SingbookSerif-Bold.ttf'));
  await Future.wait([
    body.load(),
    arabic.load(),
    icons.load(),
    brand.load(),
    serif.load(),
  ]);
}

ThemeData _theme({
  required Brightness brightness,
  required String palette,
  required String fontFamily,
}) {
  final theme = verseTheme(
    brightness: brightness,
    palette: palette,
    fontFamily: fontFamily,
  );
  return _capture
      ? theme.copyWith(
          textTheme: theme.textTheme.apply(
            fontFamily: fontFamily,
            fontFamilyFallback: const ['AboutArabic'],
          ),
        )
      : theme;
}
