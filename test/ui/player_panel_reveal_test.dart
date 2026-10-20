import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/player/player_controls_panel.dart';
import 'package:singbook/ui/player/player_fullscreen_header.dart';

void main() {
  for (final side in [false, true]) {
    testWidgets('drag reveal is continuous and preserves lyrics ($side)', (
      tester,
    ) async {
      final expanded = ValueNotifier(false);
      final scroll = ScrollController();
      addTearDown(expanded.dispose);
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: expanded,
              builder: (context, value, _) => PlayerControlsPanel(
                expanded: value,
                onChanged: (value) => expanded.value = value,
                expandLabel: 'Expand',
                collapseLabel: 'Collapse',
                side: side,
                lyrics: ListView.builder(
                  key: const ValueKey('lyrics'),
                  controller: scroll,
                  itemCount: 100,
                  itemBuilder: (_, i) =>
                      SizedBox(height: 50, child: Text('Line $i')),
                ),
                controls: SizedBox(
                  width: side ? 240 : null,
                  height: side ? null : 160,
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      );
      final lyrics = find.byKey(const ValueKey('lyrics'));
      final before = tester.getRect(lyrics);
      final element = tester.element(lyrics);
      scroll.jumpTo(100);
      await tester.pump();
      final grip = find.byKey(const ValueKey('player-controls-grip'));
      final handle = find.byKey(const ValueKey('player-controls-handle'));
      expect(tester.getSize(grip).height, 12);
      expect(tester.getSize(handle).height, 48);
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(0, -30));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      final during = tester.getRect(lyrics);
      expect(
        side ? during.width : during.height,
        lessThan(side ? before.width : before.height),
      );
      expect(
        expanded.value,
        isFalse,
        reason: 'persist only after the drag is released',
      );
      expect(tester.element(lyrics), same(element));
      expect(scroll.offset, 100);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(expanded.value, isTrue);
      final opened = tester.getRect(lyrics);
      await tester.tap(handle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final closing = tester.getRect(lyrics);
      expect(
        side ? closing.width : closing.height,
        greaterThan(side ? opened.width : opened.height),
      );
      expect(
        side ? closing.width : closing.height,
        lessThan(side ? before.width : before.height),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(lyrics), before);
      expect(scroll.offset, 100);
      final canceled = await tester.startGesture(tester.getCenter(handle));
      await canceled.moveBy(const Offset(0, -30));
      await canceled.moveBy(const Offset(0, -20));
      await tester.pump();
      await canceled.cancel();
      await tester.pumpAndSettle();
      expect(expanded.value, isFalse);
      expect(tester.getRect(lyrics), before);
      expect(scroll.offset, 100);
      expect(tester.takeException(), isNull);
    });
  }

  for (final rtl in [false, true]) {
    testWidgets('fullscreen title and actions fit beside the cutout ($rtl)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const cutout = Rect.fromLTWH(174, 0, 42, 52);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              viewPadding: EdgeInsets.only(top: 52),
              displayFeatures: [
                DisplayFeature(
                  bounds: cutout,
                  type: DisplayFeatureType.cutout,
                  state: DisplayFeatureState.unknown,
                ),
              ],
            ),
            child: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                body: Column(
                  children: [
                    PlayerFullscreenHeader(
                      title: 'Lanterns at Dawn',
                      artist: 'Mira Vale',
                      actions: [
                        IconButton(
                          key: const ValueKey('exit'),
                          onPressed: () {},
                          icon: const Icon(Icons.fullscreen_exit),
                        ),
                        IconButton(
                          key: const ValueKey('settings'),
                          onPressed: () {},
                          icon: const Icon(Icons.settings),
                        ),
                      ],
                    ),
                    const Expanded(child: Text('Lyrics')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      for (final finder in [
        find.text('Lanterns at Dawn'),
        find.text('Mira Vale'),
        find.byKey(const ValueKey('exit')),
        find.byKey(const ValueKey('settings')),
      ]) {
        expect(tester.getRect(finder).overlaps(cutout), isFalse);
        expect(tester.getRect(finder).top, greaterThanOrEqualTo(0));
        expect(tester.getRect(finder).bottom, lessThanOrEqualTo(52));
      }
      expect(
        tester
            .getSize(find.byKey(const ValueKey('player-fullscreen-header')))
            .height,
        52,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final scenario in [
    (
      'large text',
      const Size(320, 640),
      2.0,
      52.0,
      [const Rect.fromLTWH(140, 0, 40, 52)],
    ),
    (
      'multiple cameras',
      const Size(390, 844),
      1.0,
      52.0,
      [const Rect.fromLTWH(40, 0, 30, 52), const Rect.fromLTWH(180, 0, 70, 52)],
    ),
    (
      'wide notch',
      const Size(320, 640),
      1.0,
      52.0,
      [const Rect.fromLTWH(30, 0, 260, 52)],
    ),
    ('unknown inset geometry', const Size(390, 844), 1.0, 52.0, <Rect>[]),
    (
      'landscape camera',
      const Size(844, 390),
      1.6,
      0.0,
      [const Rect.fromLTWH(0, 170, 52, 50)],
    ),
    ('no camera', const Size(800, 1280), 1.0, 0.0, <Rect>[]),
  ]) {
    testWidgets('fullscreen header remains readable: ${scenario.$1}', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: scenario.$2,
              textScaler: TextScaler.linear(scenario.$3),
              viewPadding: EdgeInsets.only(top: scenario.$4),
              displayFeatures: [
                for (final bounds in scenario.$5)
                  DisplayFeature(
                    bounds: bounds,
                    type: DisplayFeatureType.cutout,
                    state: DisplayFeatureState.unknown,
                  ),
              ],
            ),
            child: Scaffold(
              body: Column(
                children: [
                  PlayerFullscreenHeader(
                    title: 'A longer original song title',
                    artist: 'Original fixture artist',
                    actions: [
                      IconButton(
                        key: const ValueKey('exit'),
                        onPressed: () {},
                        icon: const Icon(Icons.fullscreen_exit),
                      ),
                      IconButton(
                        key: const ValueKey('settings'),
                        onPressed: () {},
                        icon: const Icon(Icons.settings),
                      ),
                    ],
                  ),
                  const Expanded(child: Text('Lyrics')),
                ],
              ),
            ),
          ),
        ),
      );
      final header = tester.getRect(
        find.byKey(const ValueKey('player-fullscreen-header')),
      );
      for (final finder in [
        find.text('A longer original song title'),
        find.text('Original fixture artist'),
        find.byKey(const ValueKey('exit')),
        find.byKey(const ValueKey('settings')),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(scenario.$2.width));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(header.bottom));
        for (final cutout in scenario.$5) {
          expect(rect.overlaps(cutout), isFalse);
        }
      }
      if (scenario.$1 == 'unknown inset geometry') {
        expect(
          tester.getRect(find.byKey(const ValueKey('exit'))).top,
          greaterThanOrEqualTo(52),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
