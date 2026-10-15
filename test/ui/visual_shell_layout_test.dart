import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';

void main() {
  final repository = _VisualSettingsRepository();

  testWidgets('shell header, navigation and settings fit at 2x text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final locale in const [Locale('en'), Locale('bg'), Locale('uk')]) {
      for (final size in const [
        Size(360, 804),
        Size(393, 873),
        Size(400, 873),
        Size(600, 900),
      ]) {
        tester.view.physicalSize = size;
        final app = AppController(
          repository: repository,
          discovery: SourceDiscoveryService(const []),
        )..settings = {'locale': locale.languageCode};
        final controller = AppControllerAdapter(app);
        await _pumpShell(tester, locale, controller);

        expect(tester.takeException(), isNull, reason: '$locale/$size');
        expect(
          find.byKey(const ValueKey('appbar-brand-title')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('appbar-version')), findsNothing);
        final appBarRect = tester.getRect(find.byType(AppBar));
        final brandRect = tester.getRect(
          find.byKey(const ValueKey('appbar-brand-title')),
        );
        expect(brandRect.left, greaterThanOrEqualTo(appBarRect.left));
        expect(brandRect.right, lessThanOrEqualTo(appBarRect.right));
        if (size.width >= 600) {
          expect(
            find.byKey(const ValueKey('tablet-navigation-rail')),
            findsOneWidget,
          );
          expect(find.byType(NavigationBar), findsNothing);
        } else {
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(
            find.byKey(const ValueKey('tablet-navigation-rail')),
            findsNothing,
          );
        }

        final l10n = AppLocalizations.of(tester.element(find.byType(AppBar)));
        await tester.tap(
          find
              .text(
                size.width >= 600 ? l10n.navSettings : l10n.navSettingsCompact,
              )
              .last,
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.settingsAppearance), findsOneWidget);
        expect(find.text(l10n.settingsLanguage), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Settings at $locale/$size',
        );
        final settingsList = find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(ListView),
        );
        expect(settingsList, findsOneWidget);
        await tester.tap(find.byType(DropdownButton<String>).first);
        await tester.pumpAndSettle();
        expect(find.text(l10n.settingsLanguageSystem), findsWidgets);
        expect(find.text(l10n.settingsLanguageEnglish), findsWidgets);
        expect(find.text(l10n.settingsLanguageBulgarian), findsWidgets);
        expect(find.text('Українська'), findsWidgets);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        await tester.drag(settingsList, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Scrolled settings at $locale/$size',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        app.dispose();
      }
    }
  });

  testWidgets('home header keeps version details out of the main flow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 873);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService(const []),
    )..settings = {'locale': 'bg'};
    final controller = AppControllerAdapter(app);
    await _pumpShell(tester, const Locale('bg'), controller);

    expect(find.byKey(const ValueKey('appbar-version')), findsNothing);
    final brand = tester.widget<Text>(
      find.byKey(const ValueKey('appbar-brand-title')),
    );
    final wordmarkSpans = (brand.textSpan! as TextSpan).children!
        .cast<TextSpan>();
    final colors = Theme.of(tester.element(find.byType(AppBar))).colorScheme;
    expect(wordmarkSpans[0].style!.color, colors.primary);
    expect(wordmarkSpans[1].style!.color, colors.onSurface);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    app.dispose();
  });

  testWidgets(
    'Ukrainian navigation stays readable at phone width and large text',
    (tester) async {
      final font = FontLoader('NotoSansShell')
        ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
      await font.load();

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 804);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final scale in const [1.0, 1.3, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final app = AppController(
          repository: repository,
          discovery: SourceDiscoveryService(const []),
        )..settings = {'locale': 'uk', 'themeMode': 'dark'};
        final controller = AppControllerAdapter(app);
        await _pumpShell(
          tester,
          const Locale('uk'),
          controller,
          themeMode: ThemeMode.dark,
          fontFamily: 'NotoSansShell',
        );

        final l10n = AppLocalizations.of(tester.element(find.byType(AppBar)));
        expect(find.text(l10n.navSettingsCompact), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Ukrainian navigation at text scale $scale',
        );
        await tester.tap(find.text(l10n.navSettingsCompact));
        await tester.pumpAndSettle();
        expect(find.text(l10n.settingsTitle), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Ukrainian settings screen at text scale $scale',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        app.dispose();
      }
    },
  );

  testWidgets('tablet navigation rail uses the selected app font', (
    tester,
  ) async {
    final font = FontLoader('NotoSansShell')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    await font.load();

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService(const []),
    )..settings = {'locale': 'uk', 'themeMode': 'dark'};
    final controller = AppControllerAdapter(app);
    await _pumpShell(
      tester,
      const Locale('uk'),
      controller,
      themeMode: ThemeMode.dark,
      fontFamily: 'NotoSansShell',
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(AppBar)));
    expect(
      find.byKey(const ValueKey('tablet-navigation-rail')),
      findsOneWidget,
    );
    final railLabel = tester.renderObject<RenderParagraph>(
      find.text(l10n.navSettings),
    );
    expect(railLabel.text.style?.fontFamily, 'NotoSansShell');
    expect(railLabel.size.width, greaterThan(0));
    expect(railLabel.size.height, greaterThan(0));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    app.dispose();
  });
}

// This suite measures shell layout. Durable writes are covered by repository,
// adapter and native journey tests; avoid real I/O in Flutter's fake clock.
class _VisualSettingsRepository implements LibraryRepository {
  @override
  Future<void> setSetting(String key, dynamic value) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected visual test repository operation');
}

Future<void> _pumpShell(
  WidgetTester tester,
  Locale locale,
  AppControllerAdapter controller, {
  ThemeMode themeMode = ThemeMode.light,
  String fontFamily = 'sans-serif',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: singbookLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: verseTheme(
        brightness: Brightness.light,
        palette: 'navy',
        fontFamily: fontFamily,
      ),
      darkTheme: verseTheme(
        brightness: Brightness.dark,
        palette: 'navy',
        fontFamily: fontFamily,
      ),
      themeMode: themeMode,
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) =>
            VerseAppShell(controller: controller, files: VerseFileActions()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
