import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

import 'support/fake_controller.dart';

const _captureDirectory = String.fromEnvironment('PLAYER_FONT_CAPTURE_DIR');
const _increase = ValueKey('player-increase-font-size');
const _decrease = ValueKey('player-decrease-font-size');
const _lyrics = ValueKey('player-lyrics-scroll');

class _Controller extends FakeUiController {
  _Controller() : super((controller) => (controller as _Controller)._state);

  double fontSize = 24;
  int writes = 0;
  Completer<void>? saveGate;
  bool setlist = false;
  bool arabic = false;

  VerseUiState get _state => VerseUiState(
    route: VerseRoute.reader,
    song: const SongCardData(
      id: 'song',
      title: 'Lanterns at Dawn',
      artist: 'Mira Vale',
      durationSeconds: 240,
    ),
    lyricsFontSize: fontSize,
    playerControlsExpanded: false,
    activeSetlist: setlist
        ? const SetlistCardData(id: 'setlist', title: 'Evening songs')
        : null,
    songLines: List.generate(
      40,
      (index) => LyricLineData(
        id: 'line-$index',
        text: arabic
            ? 'نغني معاً في ضوء الصباح'
            : 'When morning spills across the hills ${index + 1}',
        chords: const [LyricChord(graphemeOffset: 0, symbol: 'Em')],
      ),
    ),
  );

  @override
  Future<void> setLyricsFontSize(double size) async {
    writes++;
    await saveGate?.future;
    fontSize = size;
    refresh();
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Controller controller, {
  Size size = const Size(1000, 800),
  bool fullScreen = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  GlobalKey? captureKey,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final theme = verseTheme(
    brightness: brightness,
    palette: 'navy',
    fontFamily: 'Roboto',
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: singbookLocalizationsDelegates,
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('bg')],
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(
            fontFamilyFallback: const ['SetlistArabic'],
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => PlayerScreen(
              controller: controller,
              fullScreen: fullScreen,
              onFullScreenChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _paintedSize(WidgetTester tester) => tester
    .widget<ChordLyricsLine>(find.byType(ChordLyricsLine).first)
    .style!
    .fontSize!;

Future<void> _pinch(WidgetTester tester, double scale) async {
  final center = tester.getCenter(find.byKey(_lyrics));
  final first = await tester.startGesture(
    center - const Offset(50, 0),
    pointer: 1,
  );
  final second = await tester.startGesture(
    center + const Offset(50, 0),
    pointer: 2,
  );
  await tester.pump();
  await first.moveTo(center - Offset(50 * scale, 0));
  await second.moveTo(center + Offset(50 * scale, 0));
  await tester.pump();
  await first.up();
  await second.up();
  await tester.pumpAndSettle();
}

void _testFontWidgets(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await callback(tester);
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
}

void main() {
  _testFontWidgets(
    'pinch previews live, saves once and clamps to settings limits',
    (tester) async {
      final controller = _Controller();
      addTearDown(controller.dispose);
      await _pump(tester, controller);
      final center = tester.getCenter(find.byKey(_lyrics));
      final first = await tester.startGesture(
        center - const Offset(50, 0),
        pointer: 1,
      );
      final second = await tester.startGesture(
        center + const Offset(50, 0),
        pointer: 2,
      );
      await tester.pump();
      await first.moveBy(const Offset(-100, 0));
      await second.moveBy(const Offset(100, 0));
      await tester.pump();
      expect(_paintedSize(tester), 36);
      expect(controller.fontSize, 24);
      expect(controller.writes, 0);
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(controller.fontSize, 36);
      expect(controller.writes, 1);
      await _pinch(tester, .2);
      expect(controller.fontSize, 18);
      expect(controller.writes, 2);
    },
  );

  _testFontWidgets('second finger can start pinch after scrolling has begun', (
    tester,
  ) async {
    final controller = _Controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller, size: const Size(390, 844));
    final center = tester.getCenter(find.byKey(_lyrics));
    final first = await tester.startGesture(
      center - const Offset(50, 0),
      pointer: 1,
    );
    await first.moveBy(const Offset(0, -60));
    await tester.pump();
    final second = await tester.startGesture(
      center + const Offset(50, -60),
      pointer: 2,
    );
    await tester.pump();
    await first.moveBy(const Offset(-50, 0));
    await second.moveBy(const Offset(50, 0));
    await tester.pump();
    expect(_paintedSize(tester), 36);
    expect(controller.writes, 0);
    await first.cancel();
    await second.cancel();
    await tester.pumpAndSettle();
    expect(controller.fontSize, 36);
    expect(controller.writes, 1);
  });

  _testFontWidgets('pending button save cannot clear a newer pinch preview', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final controller = _Controller()..saveGate = Completer<void>();
    addTearDown(controller.dispose);
    await _pump(tester, controller);
    await tester.tap(find.byKey(_increase));
    await tester.pump();
    expect(_paintedSize(tester), 26);
    final center = tester.getCenter(find.byKey(_lyrics));
    final first = await tester.startGesture(
      center - const Offset(50, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(50, 0),
      pointer: 2,
    );
    await tester.pump();
    await first.moveBy(const Offset(-10, 0));
    await second.moveBy(const Offset(10, 0));
    await tester.pump();
    expect(_paintedSize(tester), closeTo(31.2, .001));
    controller.saveGate!.complete();
    await tester.pump();
    expect(controller.fontSize, 26);
    expect(_paintedSize(tester), closeTo(31.2, .001));
    expect(controller.writes, 1);
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(controller.fontSize, closeTo(31.2, .001));
    expect(controller.writes, 2);
  });

  _testFontWidgets(
    'pinch does not advance setlist; one-finger swipe still does',
    (tester) async {
      final controller = _Controller()..setlist = true;
      addTearDown(controller.dispose);
      await _pump(tester, controller);
      await _pinch(tester, 3);
      expect(controller.calls, isNot(contains('nextSong')));
      expect(controller.calls, isNot(contains('previousSong')));
      await tester.drag(find.byKey(_lyrics), const Offset(-160, 0));
      await tester.pumpAndSettle();
      expect(controller.calls, contains('nextSong'));
    },
  );

  _testFontWidgets('one-finger vertical scrolling does not resize lyrics', (
    tester,
  ) async {
    final controller = _Controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller, size: const Size(390, 844));
    final list = tester.widget<ListView>(find.byKey(_lyrics));
    await tester.drag(find.byKey(_lyrics), const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(list.controller!.offset, greaterThan(0));
    expect(controller.writes, 0);
    expect(_paintedSize(tester), 24);
    expect(find.byKey(_increase), findsNothing);
  });

  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ]) {
    _testFontWidgets(
      '${platform.name} buttons update shared size and respect limits',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final controller = _Controller()..fontSize = 34;
        addTearDown(controller.dispose);
        await _pump(tester, controller, fullScreen: true);
        expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
        final fullscreen = tester.getRect(
          find.byKey(const ValueKey('player-exit-fullscreen')),
        );
        final increase = tester.getRect(find.byKey(_increase));
        expect(increase.center.dy, fullscreen.center.dy);
        expect(increase.right, lessThanOrEqualTo(fullscreen.left));
        await tester.tap(find.byKey(_increase));
        await tester.pumpAndSettle();
        expect(controller.fontSize, 36);
        expect(_paintedSize(tester), 36);
        expect(
          tester.widget<IconButton>(find.byKey(_increase)).onPressed,
          isNull,
        );
        await tester.tap(find.byKey(_decrease));
        await tester.pumpAndSettle();
        expect(controller.fontSize, 34);
        controller.fontSize = 18;
        controller.refresh();
        await tester.pumpAndSettle();
        expect(
          tester.widget<IconButton>(find.byKey(_decrease)).onPressed,
          isNull,
        );
      },
    );
  }

  if (_captureDirectory.isNotEmpty) {
    for (final scenario in [
      (
        'desktop_normal_light',
        TargetPlatform.windows,
        const Size(1280, 900),
        false,
        Brightness.light,
        const Locale('en'),
        1.0,
      ),
      (
        'desktop_fullscreen_dark',
        TargetPlatform.macOS,
        const Size(1280, 900),
        true,
        Brightness.dark,
        const Locale('en'),
        1.0,
      ),
      (
        'compact_large_max',
        TargetPlatform.android,
        const Size(320, 640),
        false,
        Brightness.dark,
        const Locale('en'),
        2.0,
      ),
      (
        'desktop_rtl_landscape',
        TargetPlatform.windows,
        const Size(1200, 650),
        true,
        Brightness.light,
        const Locale('ar'),
        1.6,
      ),
      (
        'phone_landscape',
        TargetPlatform.android,
        const Size(700, 360),
        true,
        Brightness.light,
        const Locale('bg'),
        1.5,
      ),
    ]) {
      _testFontWidgets('fresh font controls visual ${scenario.$1}', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = scenario.$2;
        await tester.runAsync(() async {
          for (final family in ['Roboto', 'sans-serif']) {
            await (FontLoader(family)
                  ..addFont(
                    rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
                  )
                  ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf')))
                .load();
          }
          await (FontLoader('SetlistArabic')..addFont(
                rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'),
              ))
              .load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
        final controller = _Controller()
          ..fontSize = 36
          ..arabic = scenario.$6.languageCode == 'ar';
        addTearDown(controller.dispose);
        final key = GlobalKey();
        await _pump(
          tester,
          controller,
          size: scenario.$3,
          fullScreen: scenario.$4,
          brightness: scenario.$5,
          locale: scenario.$6,
          textScale: scenario.$7,
          captureKey: key,
        );
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('$_captureDirectory/${scenario.$1}.png');
            expect(
              file.existsSync(),
              isFalse,
              reason: 'preserve prior evidence',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
          } finally {
            image.dispose();
          }
        });
      });
    }
  }
}
