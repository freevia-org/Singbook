import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _fullscreen = MethodChannel('org.freevia.singbook/fullscreen');

VerseUiState _reader(bool controls) => VerseUiState(
  route: VerseRoute.reader,
  song: const SongCardData(
    id: 'shortcuts',
    title: 'Keyboard song',
    durationSeconds: 120,
  ),
  playerControlsExpanded: controls,
  autoscroll: true,
  timingMode: 'estimated',
  songLines: const [LyricLineData(id: 'intro', text: 'Original demo lyrics')],
  playerSections: const [
    PlayerSectionMarker(name: 'Intro', startSeconds: 0, lineId: 'intro'),
    PlayerSectionMarker(name: 'Verse', startSeconds: 30, lineId: 'verse'),
    PlayerSectionMarker(name: 'Chorus', startSeconds: 60, lineId: 'chorus'),
  ],
);

void main() {
  final desktop = TargetPlatformVariant({
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_fullscreen, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_fullscreen, null);
  });

  testWidgets('desktop playback, seeking and section shortcuts', (
    tester,
  ) async {
    final controller = FakeUiController((_) => _reader(true));
    addTearDown(controller.dispose);
    await pumpShell(tester, controller, size: const Size(1100, 800));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(controller.calls, contains('playPause'));
    controller.calls.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.calls.last, 'seek(5.0)');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(controller.calls.last, 'seek(0.0)');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(controller.calls.last, 'seek(0.0)');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(controller.calls.last, 'seek(120.0)');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.calls.last, 'seek(120.0)');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(controller.calls.last, 'seek(0.0)');
    final sectionModifier = defaultTargetPlatform == TargetPlatform.macOS
        ? LogicalKeyboardKey.altLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(sectionModifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(sectionModifier);
    await tester.pump();
    expect(controller.calls.last, 'seek(30.0)');
    expect(tester.takeException(), isNull);
  }, variant: desktop);

  testWidgets('desktop shortcuts do not control playback behind settings', (
    tester,
  ) async {
    final controller = FakeUiController((_) => _reader(true));
    addTearDown(controller.dispose);
    await pumpShell(tester, controller, size: const Size(1100, 800));
    await tester.tap(find.byKey(const ValueKey('player-settings-button')));
    await tester.pumpAndSettle();
    controller.calls.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(
      controller.calls.where(
        (call) => call == 'playPause' || call.startsWith('seek('),
      ),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  }, variant: desktop);

  testWidgets(
    'native Mac fullscreen command toggles reader chrome',
    (tester) async {
      final controller = FakeUiController((_) => _reader(true));
      addTearDown(controller.dispose);
      await pumpShell(tester, controller, size: const Size(1100, 800));
      Future<void> nativeToggle() async {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'org.freevia.singbook/fullscreen',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('toggleRequested'),
          ),
          (_) {},
        );
        await tester.pumpAndSettle();
      }

      await nativeToggle();
      expect(find.byKey(const ValueKey('player-header-panel')), findsNothing);
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'org.freevia.singbook/fullscreen',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('exited'),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('player-header-panel')), findsOneWidget);
      await nativeToggle();
      expect(find.byKey(const ValueKey('player-header-panel')), findsNothing);
      await nativeToggle();
      expect(find.byKey(const ValueKey('player-header-panel')), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  for (final preference in [true, false]) {
    testWidgets(
      'fullscreen temporarily hides chrome and respects controls preference $preference',
      (tester) async {
        final controller = FakeUiController((_) => _reader(preference));
        addTearDown(controller.dispose);
        await pumpShell(tester, controller, size: const Size(1100, 800));
        final header = find.byKey(const ValueKey('player-header-panel'));
        final slider = find.byKey(const ValueKey('player-seek-slider'));
        expect(header, findsOneWidget);
        expect(
          slider.hitTestable(),
          preference ? findsOneWidget : findsNothing,
        );
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.f11);
        }
        await tester.pumpAndSettle();
        expect(header, findsNothing);
        expect(slider.hitTestable(), findsNothing);
        expect(controller.state.playerControlsExpanded, preference);
        final lyrics = find.byKey(const ValueKey('player-lyrics-scroll'));
        expect(tester.getRect(lyrics).top, 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(header, findsOneWidget);
        expect(
          slider.hitTestable(),
          preference ? findsOneWidget : findsNothing,
        );
        expect(controller.state.playerControlsExpanded, preference);
        expect(tester.takeException(), isNull);
      },
      variant: desktop,
    );
  }
}
