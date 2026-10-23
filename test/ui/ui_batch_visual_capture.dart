import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'support/fake_controller.dart';

// HOST widget screenshots only: this does not verify native OS fullscreen.
const _output = String.fromEnvironment('UI_BATCH_CAPTURE_DIR');
const _song = SongCardData(
  id: 'visual-song', title: 'Lanterns at Dawn', artist: 'Mira Vale',
  album: 'Quiet Rooms', key: 'Em', durationSeconds: 240, hasChords: true,
);

VerseUiState _state(String screen) => VerseUiState(
  route: screen == 'library' || screen == 'setlists'
      ? VerseRoute.main : VerseRoute.reader,
  activeTab: screen == 'setlists' ? VerseTab.setlists : VerseTab.home,
  homeListMode: HomeListMode.library,
  songs: const [_song],
  setlists: const [SetlistCardData(
    id: 'visual-setlist', title: 'Evening songs', durationSeconds: 240,
    songTitles: ['Lanterns at Dawn'], songIds: ['visual-song'],
  )],
  song: _song,
  readerKey: 'Em',
  readerSource: 'Original visual fixture',
  readerDurationEstimated: true,
  playbackSpeed: 1,
  playerControlsExpanded: screen != 'fullscreen',
  songLines: List.generate(40, (i) => LyricLineData(
    id: 'line-$i', text: 'Original fixture lyric line ${i + 1}',
    chords: const [LyricChord(graphemeOffset: 0, symbol: 'Em')],
  )),
);

Future<void> _fonts() async {
  for (final family in ['NotoSansFixture', 'Roboto', 'sans-serif']) {
    await (FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'))).load();
  }
  await (FontLoader('SetlistArabic')
    ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'))).load();
  await (FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  await (FontLoader('monospace')
    ..addFont(rootBundle.load('assets/fonts/NotoSansMono-Regular.ttf'))).load();
  for (final family in ['SingbookBrand', 'SingbookSerif']) {
    await (FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/$family-Bold.ttf'))).load();
  }
}

Future<void> _capture(
  WidgetTester tester, GlobalKey boundaryKey, String name,
) async {
  expect(_output, isNotEmpty);
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final boundary = boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(data, isNotNull);
      final file = File('$_output/$name.png');
      final sidecar = File('$_output/$name.json');
      expect(file.existsSync(), isFalse, reason: 'never overwrite evidence');
      expect(sidecar.existsSync(), isFalse, reason: 'never overwrite sidecars');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
      await sidecar.writeAsString(jsonEncode({
        'screen': name, 'width': image.width, 'height': image.height,
        'evidenceKind': 'host_widget_screenshot',
        'nativeFullscreenVerified': false,
        'targetPlatform': defaultTargetPlatform.name,
      }), flush: true);
    } finally {
      image.dispose();
    }
  });
}

Future<void> _captureScrolling(
  WidgetTester tester, GlobalKey key, String name,
) async {
  final list = find.byKey(const ValueKey('player-lyrics-scroll'));
  final gesture = await tester.startGesture(tester.getCenter(list));
  try {
    await gesture.moveBy(const Offset(0, -100));
    // Hold the scroll gesture while the scrollbar fades in; a settled idle
    // view could hide the mobile thumb and would not demonstrate placement.
    await tester.pump(const Duration(milliseconds: 200));
    await _capture(tester, key, name);
  } finally {
    await gesture.cancel();
  }
  await tester.pump();
}

void main() {
  for (final scenario in [
    ('phone', const Size(360, 780), const Locale('en'), 1.0, Brightness.light, TargetPlatform.android),
    ('compact_large', const Size(320, 640), const Locale('en'), 2.0, Brightness.dark, TargetPlatform.android),
    ('landscape', const Size(700, 360), const Locale('bg'), 1.5, Brightness.light, TargetPlatform.android),
    ('wide_rtl', const Size(1600, 900), const Locale('ar'), 1.6, Brightness.dark, TargetPlatform.windows),
    ('tablet', const Size(800, 1280), const Locale('uk'), 1.3, Brightness.light, TargetPlatform.android),
  ]) {
    testWidgets('fresh UI batch visuals ${scenario.$1}', (tester) async {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = scenario.$6;
      addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatform);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(_fonts);
      const fullscreen = MethodChannel('org.freevia.singbook/fullscreen');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        fullscreen, (_) async => null,
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(fullscreen, null));
      var screen = 'library';
      final controller = FakeUiController((_) => _state(screen));
      addTearDown(controller.dispose);
      final boundaryKey = GlobalKey();
      final theme = verseTheme(
        brightness: scenario.$5, palette: 'navy', fontFamily: 'NotoSansFixture',
      );
      await tester.pumpWidget(RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          locale: scenario.$3,
          localizationsDelegates: singbookLocalizationsDelegates,
          supportedLocales: const [Locale('en'), Locale('bg'), Locale('ar'), Locale('uk')],
          theme: theme.copyWith(textTheme: theme.textTheme.apply(
            fontFamily: 'NotoSansFixture', fontFamilyFallback: const ['SetlistArabic'],
          )),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scenario.$4)),
            child: child!,
          ),
          home: VerseAppShell(controller: controller, files: VerseFileActions()),
        ),
      ));
      await tester.pumpAndSettle(const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
      await tester.runAsync(() => precacheImage(
        const AssetImage('assets/branding/singbook-mark-foreground.png'),
        boundaryKey.currentContext!,
      ));
      await tester.pump();
      for (final stage in ['library', 'setlists', 'reader']) {
        screen = stage;
        controller.refresh();
        await tester.pumpAndSettle(const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
        if (stage != 'reader') {
          final shortcut = find.byKey(ValueKey(
            stage == 'library' ? 'songs-create-shortcut' : 'setlists-create-shortcut',
          ));
          await tester.ensureVisible(shortcut);
          await tester.pumpAndSettle();
          expect(shortcut.hitTestable(), findsOneWidget);
        } else {
          final bar = find.byKey(const ValueKey('player-lyrics-scrollbar'));
          final pane = find.byKey(const ValueKey('tablet-reader-content'));
          expect(tester.getRect(bar), tester.getRect(pane));
        }
        if (stage == 'reader') {
          await _captureScrolling(tester, boundaryKey, '${scenario.$1}-$stage');
        } else {
          await _capture(tester, boundaryKey, '${scenario.$1}-$stage');
        }
      }
      await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
      await tester.pumpAndSettle();
      final slider = find.byKey(const ValueKey('scroll-speed-slider'));
      final gesture = await tester.startGesture(tester.getCenter(slider));
      try {
        await gesture.moveBy(const Offset(0, -24));
        await tester.pump();
        final expected = tester.widget<Slider>(slider).label;
        expect(expected, isNot('1×'));
        expect(tester.widget<Text>(find.byKey(
          const ValueKey('scroll-speed-value'),
        )).data, expected);
        expect(controller.calls.where((call) => call.startsWith('setPlaybackSpeed')), isEmpty);
        await _capture(tester, boundaryKey, '${scenario.$1}-speed-held');
      } finally {
        await gesture.cancel();
      }
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      screen = 'fullscreen';
      controller.refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('player-enter-fullscreen')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('player-exit-fullscreen')), findsOneWidget);
      await _captureScrolling(tester, boundaryKey, '${scenario.$1}-fullscreen');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
