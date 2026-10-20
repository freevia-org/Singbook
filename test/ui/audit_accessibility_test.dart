import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/localized_labels.dart';
import 'package:singbook/ui/widgets/adaptive_bottom_navigation.dart';

void main() {
  testWidgets('large German navigation keeps full labels within touch tiles', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 804);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            bottomNavigationBar: AdaptiveBottomNavigation(
              labels: const [
                'Startseite',
                'Lieder',
                'Setlisten',
                'Einstellungen',
              ],
              icons: const [
                Icons.home,
                Icons.music_note,
                Icons.list,
                Icons.settings,
              ],
              selectedIndex: 1,
              onSelected: (index) => selected = index,
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('two-row-navigation')), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      final tile = tester.getRect(find.byKey(ValueKey('navigation-tile-$i')));
      final labelFinder = find.byKey(ValueKey('navigation-label-$i'));
      final label = tester.getRect(labelFinder);
      expect(tile.width, greaterThanOrEqualTo(48));
      expect(tile.height, greaterThanOrEqualTo(48));
      expect(label.left, greaterThanOrEqualTo(tile.left));
      expect(label.right, lessThanOrEqualTo(tile.right));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: labelFinder, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
    }
    final firstTile = find.byKey(const ValueKey('navigation-tile-1'));
    final firstInkWell = tester.widget<InkWell>(
      find.descendant(of: firstTile, matching: find.byType(InkWell)),
    );
    expect(firstInkWell.splashFactory, NoSplash.splashFactory);
    expect(
      firstInkWell.overlayColor?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(firstInkWell.overlayColor?.resolve({WidgetState.focused}), isNull);
    expect(firstInkWell.canRequestFocus, isTrue);
    await tester.tap(find.text('Einstellungen'));
    expect(selected, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact navigation keeps a short steady selection animation', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AdaptiveBottomNavigation(
            labels: const ['Home', 'Songs', 'Sets'],
            icons: const [Icons.home, Icons.music_note, Icons.queue_music],
            selectedIndex: selected,
            onSelected: (index) => selected = index,
          ),
        ),
      ),
    );

    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigation.animationDuration, const Duration(milliseconds: 180));
    expect(
      navigation.overlayColor?.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    expect(navigation.overlayColor?.resolve({WidgetState.focused}), isNull);
    final navigationTheme = Theme.of(
      tester.element(find.byType(NavigationBar)),
    );
    expect(navigationTheme.splashFactory, NoSplash.splashFactory);
    await tester.tap(find.text('Songs'));
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });

  test('provider descriptions translate each capability without leaking IDs', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final result = localizedProviderDescription(
      l10n,
      'catalog · lyrics · lineTiming · wordTiming · fileImport · unknownCapability',
    );
    expect(result, 'Search · Lyrics · Timed lyrics · Import');
    expect(
      localizedProviderDescription(l10n, 'unknownCapability'),
      l10n.providerDescriptionUnknown,
    );
    expect(
      localizedProviderDescription(l10n, 'otherKey · unknownCapability'),
      l10n.providerDescriptionUnknown,
    );
  });
}
