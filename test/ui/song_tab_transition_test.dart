import 'dart:ui' show PointerDeviceKind, SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

Finder _tab(HomeListMode mode) =>
    find.byKey(ValueKey('home-mode-${mode.name}'));
Finder _segment(HomeListMode mode) =>
    find.byKey(ValueKey('home-mode-${mode.name}-segment'));

Color _paintedColor(WidgetTester tester, HomeListMode mode) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: _segment(mode),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color!;

class _TabsController extends FakeUiController {
  _TabsController()
    : super(
        (c) => VerseUiState(
          homeListMode: (c as _TabsController).mode,
          query: 'Retained query',
        ),
      );

  HomeListMode mode = HomeListMode.recent;

  @override
  void setHomeListMode(HomeListMode value) {
    calls.add('mode:${value.name}');
    mode = value;
    refresh();
  }
}

Future<void> _pump(
  WidgetTester tester,
  _TabsController controller, {
  Brightness brightness = Brightness.light,
  bool reducedMotion = false,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: verseTheme(brightness: brightness, palette: 'navy'),
      locale: locale,
      localizationsDelegates: singbookLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reducedMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: controller,
          builder: (_, child) =>
              VerseHomeScreen(controller: controller, state: controller.state),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('song tabs remain opaque through rapid $brightness changes', (
      tester,
    ) async {
      final controller = _TabsController();
      addTearDown(controller.dispose);
      final semantics = tester.ensureSemantics();
      try {
        await _pump(tester, controller, brightness: brightness);
        final colors = Theme.of(
          tester.element(_tab(HomeListMode.recent)),
        ).colorScheme;
        expect(
          _paintedColor(tester, HomeListMode.recent),
          colors.primaryContainer,
        );
        expect(_paintedColor(tester, HomeListMode.library), colors.surface);
        await tester.tap(_tab(HomeListMode.library));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        final intermediate = _paintedColor(tester, HomeListMode.library);
        expect(intermediate.a, 1);
        expect(intermediate, isNot(colors.surface));
        expect(intermediate, isNot(colors.primaryContainer));
        expect(_paintedColor(tester, HomeListMode.recent).a, 1);
        // Reverse direction before the first animation has completed.
        await tester.tap(_tab(HomeListMode.online));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 45));
        for (final mode in [
          HomeListMode.recent,
          HomeListMode.library,
          HomeListMode.online,
        ]) {
          expect(_paintedColor(tester, mode).a, 1);
          expect(tester.getSize(_tab(mode)).height, greaterThanOrEqualTo(48));
        }
        await tester.pumpAndSettle();
        expect(controller.mode, HomeListMode.online);
        expect(
          _paintedColor(tester, HomeListMode.online),
          colors.primaryContainer,
        );
        expect(_paintedColor(tester, HomeListMode.library), colors.surface);
        final online = tester.getSemantics(_tab(HomeListMode.online));
        expect(online.hasFlag(SemanticsFlag.isButton), isTrue);
        expect(online.hasFlag(SemanticsFlag.isSelected), isTrue);
        expect(controller.state.query, 'Retained query');
        expect(controller.calls, ['mode:library', 'mode:online']);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
    'large RTL reduced-motion tabs settle immediately and hover preserves selection',
    (tester) async {
      final controller = _TabsController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller,
        locale: const Locale('ar'),
        textScale: 1.6,
        reducedMotion: true,
      );
      expect(
        tester.getCenter(_tab(HomeListMode.online)).dx,
        lessThan(tester.getCenter(_tab(HomeListMode.recent)).dx),
      );
      final colors = Theme.of(
        tester.element(_tab(HomeListMode.recent)),
      ).colorScheme;
      await tester.tap(_tab(HomeListMode.library));
      await tester.pump();
      expect(
        _paintedColor(tester, HomeListMode.library),
        colors.primaryContainer,
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(_tab(HomeListMode.online)));
      await tester.pump(const Duration(milliseconds: 75));
      expect(_paintedColor(tester, HomeListMode.online), colors.surface);
      expect(controller.mode, HomeListMode.library);
      await mouse.removePointer();
      expect(controller.calls, ['mode:library']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keyboard focus remains visible and activates a song tab', (
    tester,
  ) async {
    final oldStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = oldStrategy);
    final controller = _TabsController();
    addTearDown(controller.dispose);
    await _pump(tester, controller);
    var found = false;
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final box = tester.widget<AnimatedContainer>(
        _segment(HomeListMode.library),
      );
      if (box.foregroundDecoration != null) {
        found = true;
        break;
      }
    }
    expect(
      found,
      isTrue,
      reason:
          'Library must receive a visible focus outline through real Tab traversal',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(controller.mode, HomeListMode.library);
    expect(controller.calls, ['mode:library']);
    // Disposing the selector must also remove its highlight-mode listener.
    await tester.pumpWidget(const SizedBox());
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
