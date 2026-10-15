import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verse_mobile/l10n/generated/app_localizations.dart';
import 'package:verse_mobile/ui/home/home_screen.dart';
import 'package:verse_mobile/ui/verse_ui_state.dart';

void main() {
  testWidgets('recent timeline only overlays the list while scrolling', (
    tester,
  ) async {
    final controller = _HomeController(
      VerseUiState(
        recent: [
          for (var day = 0; day < 30; day++)
            RecentItemData(
              id: 'song-$day',
              title: 'Song $day',
              artist: 'Artist',
              occurredAt: DateTime.now().subtract(Duration(days: day)),
              isSetlist: false,
            ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VerseHomeScreen(
            controller: controller,
            state: controller.state,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final timeline = tester.widget<AnimatedOpacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('recent-history-timeline')),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(timeline.opacity, 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -340));
    await _frames(tester);
    final visible = tester.widget<AnimatedOpacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('recent-history-timeline')),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(visible.opacity, 1);

    await tester.pump(const Duration(milliseconds: 850));
    await tester.pump(const Duration(milliseconds: 200));
    final hidden = tester.widget<AnimatedOpacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('recent-history-timeline')),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(hidden.opacity, 0);
    controller.dispose();
  });
  testWidgets('the highlighted timeline day follows the scroll position', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _HomeController(
      VerseUiState(
        recent: [
          for (var day = 0; day < 40; day++)
            RecentItemData(
              id: 'song-$day',
              title: 'Song $day',
              artist: 'Artist',
              occurredAt: DateTime.now().subtract(Duration(days: day)),
              isSetlist: false,
            ),
        ],
      ),
    );
    addTearDown(controller.dispose);
    await _pumpHome(tester, controller);
    expect(_activeChips(tester), [0]);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await _frames(tester);
    final afterFirst = _activeChips(tester);
    expect(afterFirst, hasLength(1));
    expect(afterFirst.single, greaterThan(0));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await _frames(tester);
    final afterSecond = _activeChips(tester);
    expect(afterSecond, hasLength(1));
    expect(afterSecond.single, greaterThan(afterFirst.single));

    // The strip scrolled so that the active chip is on screen.
    final chip = tester.getRect(
      find.byKey(ValueKey('timeline-day-${afterSecond.single}')),
    );
    expect(chip.top, greaterThanOrEqualTo(0));
    expect(chip.bottom, lessThanOrEqualTo(800));
    expect(chip.height, greaterThanOrEqualTo(48));

    // Scrolling back up moves the highlight back.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1500));
    await _frames(tester);
    expect(_activeChips(tester).single, lessThan(afterSecond.single));
  });

  testWidgets('timeline chips are readable and large enough to touch', (
    tester,
  ) async {
    final controller = _HomeController(
      VerseUiState(
        recent: [
          for (var day = 0; day < 5; day++)
            RecentItemData(
              id: 'song-$day',
              title: 'Song $day',
              occurredAt: DateTime.now().subtract(Duration(days: day)),
              isSetlist: false,
            ),
        ],
      ),
    );
    addTearDown(controller.dispose);
    await _pumpHome(tester, controller);

    final chip = find.byKey(const ValueKey('timeline-day-1'));
    expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
    final text = tester.widget<Text>(
      find.descendant(of: chip, matching: find.byType(Text)),
    );
    expect(text.style!.fontSize, greaterThanOrEqualTo(12));
  });

}

Future<void> _pumpHome(WidgetTester tester, _HomeController controller) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: VerseHomeScreen(controller: controller, state: controller.state),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The active day is measured after the scroll frame, then the strip follows
/// it on a later frame.
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Indexes of timeline chips drawn as the active day.
List<int> _activeChips(WidgetTester tester) => [
  for (final container in tester.widgetList<Container>(
    find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('timeline-day-'),
    ),
  ))
    if (container.decoration != null)
      int.parse((container.key! as ValueKey<String>).value.split('-').last),
];

class _HomeController extends VerseUiController {
  _HomeController(this._state);
  final VerseUiState _state;
  @override
  VerseUiState get state => _state;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #loadMoreRecent ||
        invocation.memberName == #submitSearch ||
        invocation.memberName == #saveSelectedVersion) {
      return Future<void>.value();
    }
    return null;
  }
}
