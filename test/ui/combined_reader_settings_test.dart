import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/library_actions.dart';
import 'package:singbook/ui/player/player_full_screen.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _bars = MethodChannel('org.freevia.singbook/fullscreen');

VerseUiState _reader({
  VerseRoute route = VerseRoute.reader,
  bool controlsExpanded = false,
}) => VerseUiState(
  route: route,
  song: const SongCardData(
    id: 'reader',
    title: 'Reader fixture',
    durationSeconds: 180,
  ),
  playerControlsExpanded: controlsExpanded,
  songLines: [
    for (var i = 0; i < 60; i++)
      LyricLineData(id: 'line-$i', text: 'The original lyric line $i'),
  ],
);

class _DetailsController extends FakeUiController {
  _DetailsController() : super((_) => const VerseUiState());

  @override
  SongInfoData songInfo(String id) => SongInfoData(
    title: 'A long song title that must remain inside the details sheet',
    artist: 'Fixture artist',
    fields: const {'key': 'G', 'album': 'Original album'},
    sources: [
      for (var i = 0; i < 12; i++)
        SongInfoSourceData(
          providerName: 'Source $i',
          attribution: 'Original attribution $i',
        ),
    ],
  );
}

void main() {
  testWidgets(
    'native desktop width and all-platform reader width remain combined',
    (tester) async {
      const size = Size(1600, 900);
      var route = VerseRoute.main;
      final controller = FakeUiController((_) => _reader(route: route));
      addTearDown(controller.dispose);
      await pumpShell(tester, controller, size: size);
      final frame = find.byKey(const ValueKey('tablet-content-frame'));
      final rail = find.byType(NavigationRail);
      final availableWidth = size.width - tester.getSize(rail).width;
      final desktop =
          !kIsWeb &&
          {
            TargetPlatform.windows,
            TargetPlatform.macOS,
            TargetPlatform.linux,
          }.contains(defaultTargetPlatform);
      expect(
        tester.getSize(frame).width,
        closeTo(desktop ? availableWidth : 1200, 1),
      );
      route = VerseRoute.reader;
      controller.refresh();
      await tester.pumpAndSettle();
      expect(rail, findsNothing);
      expect(tester.getSize(frame).width, closeTo(size.width, 1));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    }),
  );

  testWidgets('shell reader preserves full-height landscape lyrics', (
    tester,
  ) async {
    const capture = bool.fromEnvironment('CAPTURE_PLAYER_VISUALS');
    if (capture) {
      await tester.runAsync(() async {
        for (final family in ['Roboto', 'sans-serif']) {
          await (FontLoader(family)
                ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf')))
              .load();
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
    }
    final controller = FakeUiController((_) => _reader());
    addTearDown(controller.dispose);
    for (final scenario in [
      ('portrait', const Size(360, 780)),
      ('landscape', const Size(700, 360)),
      ('wide_desktop', const Size(1600, 900)),
    ]) {
      await pumpShell(tester, controller, size: scenario.$2);
      final lyrics = find.byKey(const ValueKey('tablet-reader-content'));
      final frame = find.byKey(const ValueKey('tablet-content-frame'));
      expect(lyrics, findsOneWidget);
      expect(tester.getRect(frame).width, closeTo(scenario.$2.width, 1));
      if (scenario.$1 == 'landscape') {
        _expectLandscapeHeaderAndLyrics(tester, scenario.$2, lyrics);
      }
      if (capture) {
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../artifacts/player-speed-landscape-qualification/captures-v2/shell-collapsed-${scenario.$1}.png',
          ),
        );
      }
      await tester.tap(find.byKey(const ValueKey('player-enter-fullscreen')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('player-exit-fullscreen')),
        findsOneWidget,
      );
      expect(tester.getRect(frame).width, closeTo(scenario.$2.width, 1));
      expect(
        find.byKey(const ValueKey('player-landscape-header')),
        findsNothing,
      );
      expect(tester.getRect(lyrics).top, closeTo(0, 1));
      expect(tester.getRect(lyrics).height, closeTo(scenario.$2.height, 1));
      if (capture) {
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../artifacts/player-speed-landscape-qualification/captures-v2/shell-fullscreen-${scenario.$1}.png',
          ),
        );
      }
      await tester.tap(find.byKey(const ValueKey('player-exit-fullscreen')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('player-enter-fullscreen')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shell landscape puts expanded controls beside full-height lyrics',
    (tester) async {
      const capture = bool.fromEnvironment('CAPTURE_PLAYER_VISUALS');
      if (capture) {
        await tester.runAsync(() async {
          for (final family in ['Roboto', 'sans-serif']) {
            await (FontLoader(family)..addFont(
                  rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
                ))
                .load();
          }
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
      }
      final controller = FakeUiController(
        (_) => _reader(controlsExpanded: true),
      );
      addTearDown(controller.dispose);
      await pumpShell(tester, controller, size: const Size(700, 360));
      final lyrics = _expectLandscapeHeaderAndLyrics(
        tester,
        const Size(700, 360),
        find.byKey(const ValueKey('tablet-reader-content')),
      );
      final header = tester.getRect(
        find.byKey(const ValueKey('player-landscape-header')),
      );
      final controls = tester.getRect(
        find.byKey(const ValueKey('player-controls-panel')),
      );
      expect(lyrics.width, greaterThanOrEqualTo(350));
      expect(controls.top, greaterThanOrEqualTo(header.bottom));
      expect(controls.bottom, lessThanOrEqualTo(360));
      expect(controls.left, greaterThanOrEqualTo(lyrics.right));
      expect(find.byKey(const ValueKey('start-lyric-scroll')), findsOneWidget);
      expect(find.byKey(const ValueKey('scroll-speed-toggle')), findsOneWidget);
      if (capture) {
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../artifacts/player-speed-landscape-qualification/captures-v2/shell-expanded-landscape.png',
          ),
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late platform enter is followed by exit and disposal',
    (tester) async {
      final calls = <bool>[];
      final enter = Completer<void>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_bars, (
        call,
      ) async {
        final enabled = call.arguments as bool;
        calls.add(enabled);
        if (enabled) await enter.future;
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _bars,
          null,
        ),
      );
      final bars = PlayerFullScreen();
      bars.setEnabled(true);
      await tester.pump();
      expect(calls, [true]);
      bars.setEnabled(false);
      bars.dispose();
      bars.setEnabled(true);
      await tester.pump();
      expect(calls, [true]);
      enter.complete();
      await tester.pump();
      await tester.pump();
      expect(calls, [true, false, false]);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.macOS,
    }),
  );

  testWidgets(
    'platform failure does not block a later restore request',
    (tester) async {
      final calls = <bool>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_bars, (
        call,
      ) async {
        final enabled = call.arguments as bool;
        calls.add(enabled);
        if (enabled) throw PlatformException(code: 'fixture_unavailable');
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _bars,
          null,
        ),
      );
      final bars = PlayerFullScreen();
      bars.setEnabled(true);
      bars.dispose();
      await tester.pump();
      await tester.pump();
      expect(calls, [true, false]);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.macOS,
    }),
  );

  testWidgets(
    'fullscreen preserves reader scroll and Back exits before reader',
    (tester) async {
      final controller = FakeUiController((_) => _reader());
      addTearDown(controller.dispose);
      await pumpShell(tester, controller);
      final scroll = find.byKey(const ValueKey('player-lyrics-scroll'));
      await tester.drag(scroll, const Offset(0, -450));
      await tester.pumpAndSettle();
      ScrollPosition position() => tester
          .state<ScrollableState>(
            find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      final before = position().pixels;
      expect(before, greaterThan(0));
      // Dragging lyrics intentionally updates playback position; only the
      // following mode transition must leave it alone.
      controller.calls.clear();
      final player = tester.state(find.byType(PlayerScreen));
      await tester.tap(find.byKey(const ValueKey('player-enter-fullscreen')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('player-header-panel')), findsNothing);
      expect(
        find.byKey(const ValueKey('player-exit-fullscreen')),
        findsOneWidget,
      );
      expect(tester.state(find.byType(PlayerScreen)), same(player));
      expect(position().pixels, closeTo(before, 1));
      expect(
        find.byKey(const ValueKey('player-controls-handle')),
        findsNothing,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('player-exit-fullscreen')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('player-header-panel')), findsOneWidget);
      expect(position().pixels, closeTo(before, 1));
      expect(controller.calls, isNot(contains('back')));
      expect(controller.calls.where((c) => c.startsWith('seek(')), isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(controller.calls.where((c) => c == 'back'), hasLength(1));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Escape exits fullscreen without playback or reader navigation',
    (tester) async {
      final controller = FakeUiController((_) => _reader());
      addTearDown(controller.dispose);
      await pumpShell(tester, controller);
      await tester.tap(find.byKey(const ValueKey('player-enter-fullscreen')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('player-exit-fullscreen')),
        findsNothing,
      );
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(controller.calls, isNot(contains('back')));
      expect(controller.calls, isNot(contains('playPause')));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'Mac fullscreen survives focus changes without replaying requests',
    (tester) async {
      final calls = <bool>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _bars,
        (call) async => calls.add(call.arguments as bool),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _bars,
          null,
        ),
      );
      final controller = FakeUiController((_) => _reader());
      addTearDown(controller.dispose);
      await pumpShell(tester, controller);
      await tester.tap(find.byKey(const ValueKey('player-enter-fullscreen')));
      await tester.pumpAndSettle();
      expect(calls, [true]);
      for (var i = 0; i < 3; i++) {
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
          await tester.pumpAndSettle();
        }
      }
      expect(calls, [true]);
      await tester.tap(find.byKey(const ValueKey('player-exit-fullscreen')));
      await tester.pumpAndSettle();
      expect(calls, [true, false]);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('reader Edit remains reachable through the overflow menu', (
    tester,
  ) async {
    final controller = FakeUiController((_) => _reader());
    addTearDown(controller.dispose);
    await pumpShell(tester, controller);
    expect(
      find.byKey(const ValueKey('player-enter-fullscreen')),
      findsOneWidget,
    );
    final l10n = l10nOf(tester);
    await tester.tap(find.byTooltip(l10n.songMenuLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.actionEdit));
    await tester.pumpAndSettle();
    expect(controller.calls, contains('editSong'));
  });

  testWidgets(
    'route changes and disposal restore Android system bars',
    (tester) async {
      final calls = <bool>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _bars,
        (call) async => calls.add(call.arguments as bool),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _bars,
          null,
        ),
      );
      var route = VerseRoute.reader;
      final controller = FakeUiController((_) => _reader(route: route));
      addTearDown(controller.dispose);
      await pumpShell(tester, controller);
      await tester.tap(find.byKey(const ValueKey('player-enter-fullscreen')));
      await tester.pumpAndSettle();
      expect(calls.last, isTrue);
      route = VerseRoute.main;
      controller.refresh();
      await tester.pumpAndSettle();
      expect(calls.last, isFalse);
      route = VerseRoute.reader;
      controller.refresh();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('player-enter-fullscreen')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('player-enter-fullscreen')));
      await tester.pumpAndSettle();
      expect(calls.last, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(calls.last, isFalse);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.macOS,
    }),
  );

  for (final scenario in [
    (const Size(320, 640), const Locale('en'), 1.0),
    (const Size(740, 360), const Locale('ar'), 2.0),
    (const Size(800, 1000), const Locale('uk'), 2.0),
  ]) {
    testWidgets('long Song details respect safe areas and close at $scenario', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.$1;
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      final controller = _DetailsController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: scenario.$2,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scenario.$3)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSongInfo(context, controller, 'fixture'),
                child: const Text('Open details'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open details'));
      await tester.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      // BottomSheet's route wrapper spans the viewport. Its Material is the
      // visible constrained surface the user actually reads and touches.
      final bounds = tester.getRect(
        find.descendant(of: sheet, matching: find.byType(Material)).first,
      );
      expect(bounds.top, greaterThanOrEqualTo(32));
      expect(bounds.width, lessThanOrEqualTo(640));
      final list = find.descendant(of: sheet, matching: find.byType(ListView));
      final scrollable = find.descendant(
        of: list,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Source 11'),
        160,
        scrollable: scrollable,
      );
      expect(
        tester.getRect(find.text('Source 11')).bottom,
        lessThanOrEqualTo(scenario.$1.height - 24),
      );
      tester.state<ScrollableState>(scrollable).position.jumpTo(0);
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(list));
      await tester.tap(find.byTooltip(l10n.navClose));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(controller.calls, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  for (final isSetlist in [false, true]) {
    testWidgets('short menu labels preserve action values ($isSetlist)', (
      tester,
    ) async {
      final controller = FakeUiController((_) => const VerseUiState());
      addTearDown(controller.dispose);
      await pumpShell(tester, controller);
      final l10n = l10nOf(tester);
      final actions = buildLibraryActionMenu(
        l10n,
        isSetlist: isSetlist,
        actions: {'copy', 'print', 'share'},
      ).whereType<PopupMenuItem<String>>().toList();
      final labels = {
        for (final item in actions) item.value: (item.child! as Text).data,
      };
      expect(labels['copy'], 'Copy');
      expect(labels['print'], 'Print');
      if (isSetlist) expect(labels['share'], 'Share as OpenSong');
      expect(labels.keys, containsAll(['copy', 'print', 'share']));
    });
  }
}

Rect _expectLandscapeHeaderAndLyrics(
  WidgetTester tester,
  Size viewport,
  Finder lyricsFinder,
) {
  final headerFinder = find.byKey(const ValueKey('player-landscape-header'));
  expect(headerFinder, findsOneWidget);
  final header = tester.getRect(headerFinder);
  final lyrics = tester.getRect(lyricsFinder);
  expect(header.top, closeTo(0, 1));
  expect(header.height, greaterThanOrEqualTo(48));
  expect(header.bottom, lessThan(viewport.height));
  expect(lyrics.top, closeTo(header.bottom, 1));
  expect(lyrics.bottom, closeTo(viewport.height, 1));
  expect(lyrics.height, closeTo(viewport.height - header.bottom, 1));
  return lyrics;
}
