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
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/adaptive_bottom_navigation.dart';

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

    for (final locale in const [
      Locale('en'),
      Locale('bg'),
      Locale('uk'),
      Locale('de'),
      Locale('fi'),
      Locale('el'),
    ]) {
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
        expect(find.byKey(const ValueKey('appbar-version')), findsOneWidget);
        final appBarRect = tester.getRect(find.byType(AppBar));
        final brandRect = tester.getRect(
          find.byKey(const ValueKey('appbar-brand-title')),
        );
        expect(brandRect.left, greaterThanOrEqualTo(appBarRect.left));
        expect(brandRect.right, lessThanOrEqualTo(appBarRect.right));
        final railHeight = 54 + 8 + 3 * (56 + 20 * 2);
        final usesRail = size.width >= 600 && size.height >= railHeight;
        if (usesRail) {
          expect(
            find.byKey(const ValueKey('tablet-navigation-rail')),
            findsOneWidget,
          );
          expect(find.byType(NavigationBar), findsNothing);
        } else {
          expect(find.byType(AdaptiveBottomNavigation), findsOneWidget);
          expect(
            find.byKey(const ValueKey('tablet-navigation-rail')),
            findsNothing,
          );
        }

        final l10n = AppLocalizations.of(tester.element(find.byType(AppBar)));
        final navigation = usesRail
            ? find.byKey(const ValueKey('tablet-navigation-rail'))
            : find.byType(AdaptiveBottomNavigation);
        final settingsDestination = find.descendant(
          of: navigation,
          matching: find.text(l10n.navSettings),
        );
        expect(settingsDestination, findsOneWidget);
        await tester.tap(settingsDestination);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('settings-menu-appearance')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.settingsAppearance), findsOneWidget);
        expect(find.text(l10n.settingsLanguage), findsNothing);
        await tester.tap(
          find.byKey(const ValueKey('settings-menu-appearance')),
        );
        await tester.pumpAndSettle();
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
        final languageButton = find.byType(DropdownButton<String>).first;
        final languageDropdown = tester.widget<DropdownButton<String>>(
          languageButton,
        );
        final languageNames = languageDropdown.items!
            .map((item) => (item.child as Text).data)
            .toList();
        expect(
          languageNames,
          containsAll([
            l10n.settingsLanguageSystem,
            'English',
            'Български',
            'Українська',
          ]),
        );
        final selectedName =
            (languageDropdown.items!
                        .singleWhere(
                          (item) => item.value == languageDropdown.value,
                        )
                        .child
                    as Text)
                .data!;
        await tester.tap(languageButton);
        await tester.pumpAndSettle();
        expect(find.text(selectedName), findsWidgets);
        // Close the language popup route before scrolling Settings.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        final menuList = find.byType(ListView);
        final currentL10n = AppLocalizations.of(
          tester.element(find.byType(AppBar)),
        );
        final aboutTile = find.widgetWithText(
          ListTile,
          currentL10n.settingsAbout,
        );
        final aboutTitle = find.descendant(
          of: aboutTile,
          matching: find.text(currentL10n.settingsAbout),
        );
        // The menu remains scrollable with enlarged text.
        final scrollable = find.byType(Scrollable);
        expect(scrollable, findsOneWidget);
        for (
          var attempt = 0;
          attempt < 4 && aboutTitle.evaluate().isEmpty;
          attempt++
        ) {
          final position = tester.state<ScrollableState>(scrollable).position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
        }
        expect(aboutTitle, findsOneWidget);
        await tester.ensureVisible(aboutTitle);
        await tester.pumpAndSettle();
        final viewportRect = tester.getRect(menuList);
        final aboutRect = tester.getRect(aboutTitle);
        expect(aboutRect.top, greaterThanOrEqualTo(viewportRect.top));
        expect(aboutRect.bottom, lessThanOrEqualTo(viewportRect.bottom));
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

  testWidgets('compact landscape navigation fits English and German at 2x', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 360);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();
    try {
      for (final locale in const [Locale('en'), Locale('de')]) {
        final app = AppController(
          repository: repository,
          discovery: SourceDiscoveryService(const []),
        )..settings = {'locale': locale.languageCode};
        final controller = AppControllerAdapter(app);
        await _pumpShell(tester, locale, controller);

        final l10n = AppLocalizations.of(tester.element(find.byType(AppBar)));
        final railHeight = 54 + 8 + 3 * (56 + 20 * 2);
        final usesRail = 360 >= railHeight;
        final navigation = usesRail
            ? find.byKey(const ValueKey('tablet-navigation-rail'))
            : find.byType(AdaptiveBottomNavigation);
        expect(navigation, findsOneWidget);
        if (usesRail) {
          expect(find.byType(AdaptiveBottomNavigation), findsNothing);
        } else {
          expect(
            find.byKey(const ValueKey('tablet-navigation-rail')),
            findsNothing,
          );
        }
        final navigationRect = tester.getRect(navigation);
        final labels = [l10n.navSongs, l10n.navSetlists, l10n.navSettings];
        const destinationTabs = [
          VerseTab.home,
          VerseTab.setlists,
          VerseTab.settings,
        ];
        for (var index = 0; index < labels.length; index++) {
          final destination = find.descendant(
            of: navigation,
            matching: find.text(labels[index]),
          );
          expect(destination, findsOneWidget);
          final labelRect = tester.getRect(destination);
          expect(labelRect.left, greaterThanOrEqualTo(navigationRect.left));
          expect(labelRect.right, lessThanOrEqualTo(navigationRect.right));
          expect(labelRect.top, greaterThanOrEqualTo(navigationRect.top));
          expect(labelRect.bottom, lessThanOrEqualTo(navigationRect.bottom));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: destination, matching: find.byType(RichText)),
          );
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '$locale label ${labels[index]} at 640×360 / 2×',
          );

          final semanticDestination = find.descendant(
            of: navigation,
            matching: find.bySemanticsLabel(
              RegExp('^${RegExp.escape(labels[index])}(\\n|\$)'),
            ),
          );
          expect(semanticDestination, findsOneWidget);
          final semanticData = tester
              .getSemantics(semanticDestination)
              .getSemanticsData();
          expect(semanticData.hasAction(SemanticsAction.tap), isTrue);
          await tester.tap(destination);
          await tester.pumpAndSettle();
          expect(controller.state.activeTab, destinationTabs[index]);
          expect(
            tester
                .getSemantics(semanticDestination)
                .getSemanticsData()
                .flagsCollection
                .isSelected
                .toBoolOrNull(),
            isTrue,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$locale destination $index at 640×360 / 2×',
          );
        }

        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        app.dispose();
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('home header shows compact version alongside the wordmark', (
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

    expect(find.byKey(const ValueKey('appbar-version')), findsOneWidget);
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
        final settingsDestination = find.descendant(
          of: find.byType(AdaptiveBottomNavigation),
          matching: find.text(l10n.navSettings),
        );
        expect(settingsDestination, findsOneWidget);
        expect(find.byType(AdaptiveBottomNavigation), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Ukrainian navigation at text scale $scale',
        );
        await tester.tap(settingsDestination);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(ListView),
            matching: find.text(l10n.settingsTitle),
          ),
          findsOneWidget,
        );
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
