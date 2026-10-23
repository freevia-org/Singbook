import 'dart:io';
import 'dart:ui' as ui show SemanticsAction;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/format.dart' show formatDuration;
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

class _Controller extends VerseUiController {
  final calls = <String>[];
  final positionNotifier = ValueNotifier<PlayerPosition>(PlayerPosition.zero);
  String tuning = '[E, A, D, G, B, E]';
  String? songKey = 'Em';
  double speed = 1;
  bool showChords = true;
  bool playerControlsExpanded = true;
  String highlightStyle = 'contrast';
  String songId = 'song';
  double duration = 240;
  int speedWrites = 0;
  List<LyricLineData>? lines;
  @override
  VerseUiState get state => VerseUiState(
    route: VerseRoute.reader,
    song: SongCardData(
      id: songId,
      title: 'Lanterns at Dawn',
      artist: 'Mira Vale',
      album: 'Quiet Rooms',
      key: songKey,
      hasChords: true,
      durationSeconds: duration,
    ),
    readerKey: songKey,
    readerTuning: tuning,
    readerSource: 'Original fixture source',
    readerCanCompareVersions: true,
    playbackSpeed: speed,
    showChords: showChords,
    playerControlsExpanded: playerControlsExpanded,
    lyricHighlightStyle: highlightStyle,
    songLines:
        lines ??
        const [
          LyricLineData(id: 'v', section: 'Verse 1', isBlank: true),
          LyricLineData(
            id: 'a',
            text: 'When morning spills across the hills',
            chords: [LyricChord(graphemeOffset: 0, symbol: 'Em')],
          ),
          LyricLineData(id: 'b', text: 'We raise a song in time'),
          LyricLineData(id: 'c', text: 'The quiet road remembers us'),
        ],
    playerSections: const [
      PlayerSectionMarker(name: 'Verse 1', startSeconds: 0, lineId: 'a'),
    ],
  );

  @override
  ValueListenable<PlayerPosition> get playerPosition => positionNotifier;

  void refresh() => notifyListeners();

  @override
  Future<void> seek(double seconds) async {
    calls.add('seek:$seconds');
  }

  @override
  Future<void> setPlaybackSpeed(double value) async {
    speedWrites++;
    speed = value;
    notifyListeners();
  }

  @override
  Future<void> compareCurrentSongVersions() async {
    calls.add('compare');
  }

  @override
  Future<void> editSong(String id) async {
    calls.add('edit:$id');
  }

  @override
  Future<void> setShowChords(bool value) async {
    showChords = value;
    notifyListeners();
  }

  @override
  Future<void> setPlayerControlsExpanded(bool expanded) async {
    playerControlsExpanded = expanded;
    notifyListeners();
  }

  @override
  void dispose() {
    positionNotifier.dispose();
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  _Controller controller, {
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
  double scale = 1,
  Brightness brightness = Brightness.light,
  bool fullScreen = false,
  ValueChanged<bool>? onFullScreenChanged,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: verseTheme(brightness: brightness, palette: 'navy'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => PlayerScreen(
            controller: controller,
            fullScreen: fullScreen,
            onFullScreenChanged: onFullScreenChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Slider _speedSlider(WidgetTester tester) =>
    tester.widget<Slider>(find.byKey(const ValueKey('scroll-speed-slider')));

Listener _speedSliderListener(WidgetTester tester) => tester.widget<Listener>(
  find
      .ancestor(
        of: find.byKey(const ValueKey('scroll-speed-slider')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Listener &&
              widget.onPointerDown != null &&
              widget.onPointerCancel != null,
        ),
      )
      .first,
);

void main() {
  const capturePlayerVisuals = bool.fromEnvironment('CAPTURE_PLAYER_VISUALS');
  for (final missingKey in <String?>[null, 'H']) {
    for (final scenario in [
      ('phone', const Size(360, 800), 1.0, const Locale('en')),
      ('small_large_text', const Size(320, 640), 2.0, const Locale('en')),
      ('landscape', const Size(900, 400), 1.0, const Locale('en')),
      ('landscape_large', const Size(700, 360), 1.5, const Locale('bg')),
      ('rtl', const Size(360, 780), 1.6, const Locale('ar')),
      ('tablet', const Size(800, 1280), 1.0, const Locale('en')),
    ]) {
      testWidgets(
        'keyless chord dropdown beside Play ($missingKey ${scenario.$1})',
        (tester) async {
          final controller = _Controller()..songKey = missingKey;
          addTearDown(controller.dispose);
          await _pump(
            tester,
            controller,
            size: scenario.$2,
            scale: scenario.$3,
            locale: scenario.$4,
          );
          final dropdown = find.byKey(const ValueKey('pitch-key-dropdown'));
          final key = tester.getRect(dropdown);
          final play = tester.getRect(
            find.byKey(const ValueKey('start-lyric-scroll')),
          );
          final stacked = key.bottom <= play.top;
          expect(key.overlaps(play), isFalse);
          if (!stacked && scenario.$4.languageCode == 'ar') {
            expect(key.left, greaterThanOrEqualTo(play.right));
          } else if (!stacked) {
            expect(key.right, lessThanOrEqualTo(play.left));
          }
          if (!stacked) {
            expect(key.center.dy, closeTo(play.center.dy, 1));
          }
          expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
          expect(find.byIcon(Icons.add_circle_outline), findsNothing);
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          final edit = find.byWidgetPredicate(
            (widget) =>
                widget is PopupMenuItem<String> && widget.value == 'edit-key',
          );
          expect(edit, findsOneWidget);
          expect(find.byKey(const ValueKey('transpose-pitch-0')), findsNothing);
          final popup = tester.getRect(edit);
          expect(popup.left, lessThan(key.right));
          expect(popup.right, greaterThan(key.left));
          expect(popup.top, greaterThanOrEqualTo(0));
          expect(
            tester.getRect(edit).bottom,
            lessThanOrEqualTo(scenario.$2.height),
          );
          await tester.tap(edit);
          expect(controller.calls, contains('edit:song'));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('compact sidebar keeps key play and speed on one ordered row', (
    tester,
  ) async {
    // Match native font metrics used by the player's measured fit guards.
    await tester.runAsync(() async {
      for (final family in ['Roboto', 'sans-serif']) {
        await (FontLoader(family)
              ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf')))
            .load();
      }
    });
    final controller = _Controller()
      ..songKey = 'D#'
      ..speed = 1.25;
    addTearDown(controller.dispose);
    await _pump(tester, controller, size: const Size(900, 400));
    final key = tester.getRect(
      find.byKey(const ValueKey('pitch-key-dropdown')),
    );
    final play = tester.getRect(
      find.byKey(const ValueKey('start-lyric-scroll')),
    );
    final speed = tester.getRect(
      find.byKey(const ValueKey('scroll-speed-toggle')),
    );
    expect(key.right, lessThanOrEqualTo(play.left));
    expect(play.right, lessThanOrEqualTo(speed.left));
    expect(key.center.dy, closeTo(play.center.dy, 1));
    expect(speed.center.dy, closeTo(play.center.dy, 1));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pitch-key-dropdown')),
        matching: find.text('D#'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await _pump(
      tester,
      controller,
      size: const Size(700, 360),
      scale: 1.5,
      locale: const Locale('bg'),
    );
    final localizedPlay = AppLocalizations.of(
      tester.element(find.byType(PlayerScreen)),
    ).playerPlay;
    final compactPlay = find.byKey(const ValueKey('start-lyric-scroll'));
    expect(tester.getRect(compactPlay).width, greaterThanOrEqualTo(104));
    final playLabel = find
        .descendant(of: compactPlay, matching: find.byType(RichText))
        .last;
    expect(
      tester.renderObject<RenderParagraph>(playLabel).didExceedMaxLines,
      isFalse,
    );
    expect(
      find.descendant(of: compactPlay, matching: find.text(localizedPlay)),
      findsOneWidget,
    );
    final layoutError = tester.takeException();
    if (layoutError != null) debugDumpRenderTree();
    expect(layoutError, isNull);
  });

  for (final scenario in [
    (500.0, const Locale('en'), 1.0),
    (600.0, const Locale('bg'), 1.5),
    (640.0, const Locale('ar'), 1.5),
    (700.0, const Locale('bg'), 1.5),
  ]) {
    testWidgets(
      'landscape transport stays readable and reachable at ${scenario.$1}',
      (tester) async {
        await tester.runAsync(() async {
          final font = rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
          for (final family in ['Roboto', 'sans-serif']) {
            await (FontLoader(family)..addFont(font)).load();
          }
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
        final controller = _Controller();
        if (scenario.$2.languageCode == 'ar') controller.songKey = 'D#min';
        addTearDown(controller.dispose);
        await _pump(
          tester,
          controller,
          size: Size(scenario.$1, 360),
          locale: scenario.$2,
          scale: scenario.$3,
          onFullScreenChanged: (_) {},
        );

        final lyrics = find.byKey(const ValueKey('tablet-reader-content'));
        final lyricsRect = tester.getRect(lyrics);
        expect(lyricsRect.width, greaterThanOrEqualTo(scenario.$1 * .5));
        final header = find.byKey(const ValueKey('player-landscape-header'));
        expect(header, findsOneWidget);
        final headerRect = tester.getRect(header);
        expect(lyricsRect.top, greaterThanOrEqualTo(headerRect.bottom));
        expect(lyricsRect.bottom, lessThanOrEqualTo(360));
        expect(lyricsRect.height, greaterThan(250));
        final play = find.byKey(const ValueKey('start-lyric-scroll'));
        expect(tester.getRect(play).width, greaterThanOrEqualTo(104));
        final visibleKey = find.descendant(
          of: find.byKey(const ValueKey('pitch-key-dropdown')),
          matching: find.text(controller.songKey!),
        );
        expect(visibleKey, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(visibleKey).didExceedMaxLines,
          isFalse,
        );
        // A narrow pane keeps one row and reveals its larger controls by
        // horizontal scrolling instead of clipping the key or play label.
        await Scrollable.ensureVisible(tester.element(play), alignment: .5);
        await tester.pumpAndSettle();
        final playRect = tester.getRect(play);
        final controlsRect = tester.getRect(
          find.byKey(const ValueKey('player-controls-panel')),
        );
        expect(playRect.left, greaterThanOrEqualTo(controlsRect.left - .01));
        expect(playRect.top, greaterThanOrEqualTo(controlsRect.top - .01));
        expect(playRect.right, lessThanOrEqualTo(controlsRect.right + .01));
        expect(playRect.bottom, lessThanOrEqualTo(controlsRect.bottom + .01));
        expect(playRect.width, lessThan(controlsRect.width));
        expect(play.hitTestable(), findsOneWidget);
        final key = find.byKey(const ValueKey('pitch-key-dropdown'));
        await Scrollable.ensureVisible(tester.element(key), alignment: .5);
        await tester.pumpAndSettle();
        expect(key.hitTestable(), findsOneWidget);
        expect(tester.getSize(key).height, greaterThanOrEqualTo(48));
        final speed = find.byKey(const ValueKey('scroll-speed-toggle'));
        await Scrollable.ensureVisible(tester.element(speed), alignment: .5);
        await tester.pumpAndSettle();
        expect(controlsRect.contains(tester.getCenter(speed)), isTrue);
        expect(speed.hitTestable(), findsOneWidget);
        expect(tester.getSize(speed).height, greaterThanOrEqualTo(48));
        await Scrollable.ensureVisible(tester.element(play), alignment: .5);
        await tester.pumpAndSettle();
        final playLabel = find
            .descendant(of: play, matching: find.byType(RichText))
            .last;
        expect(
          tester.renderObject<RenderParagraph>(playLabel).didExceedMaxLines,
          isFalse,
        );
        expect(
          find.byKey(const ValueKey('player-enter-fullscreen')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
        expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'landscape fullscreen keeps a persistent header and lyrics exit action',
    (tester) async {
      final controller = _Controller();
      addTearDown(controller.dispose);
      bool? fullscreen;
      await _pump(
        tester,
        controller,
        size: const Size(700, 360),
        fullScreen: true,
        onFullScreenChanged: (value) => fullscreen = value,
      );
      final lyrics = find.byKey(const ValueKey('tablet-reader-content'));
      final header = find.byKey(const ValueKey('player-landscape-header'));
      expect(header, findsOneWidget);
      final headerRect = tester.getRect(header);
      final lyricsRect = tester.getRect(lyrics);
      expect(lyricsRect.top, greaterThanOrEqualTo(headerRect.bottom));
      expect(lyricsRect.height, greaterThan(250));
      expect(
        find.byKey(const ValueKey('player-fullscreen-header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('player-landscape-header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('player-exit-fullscreen')),
        findsOneWidget,
      );

      await tester.tap(
        find.byTooltip(
          AppLocalizations.of(
            tester.element(find.byType(PlayerScreen)),
          ).playerCollapseControls,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('player-exit-fullscreen')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('player-exit-fullscreen')));
      expect(fullscreen, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'landscape song header stays visible through collapse and lyric scrolling within safe insets',
    (tester) async {
      tester.view.viewPadding = const FakeViewPadding(
        top: 24,
        left: 24,
        right: 32,
      );
      tester.view.padding = const FakeViewPadding(top: 24, left: 24, right: 32);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final controller = _Controller()
        ..lines = List.generate(
          24,
          (index) => LyricLineData(
            id: 'scroll-$index',
            text: 'Lyric line $index keeps the reader content scrollable',
          ),
        );
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller,
        size: const Size(700, 360),
        onFullScreenChanged: (_) {},
      );

      final collapse = find.byTooltip(
        AppLocalizations.of(
          tester.element(find.byType(PlayerScreen)),
        ).playerCollapseControls,
      );
      expect(collapse, findsOneWidget);
      await tester.tap(collapse);
      await tester.pumpAndSettle();
      expect(controller.playerControlsExpanded, isFalse);

      final header = find.byKey(const ValueKey('player-landscape-header'));
      final lyrics = find.byKey(const ValueKey('tablet-reader-content'));
      final headerRect = tester.getRect(header);
      final lyricsRect = tester.getRect(lyrics);
      expect(find.text('Lanterns at Dawn'), findsOneWidget);
      expect(find.text('Mira Vale'), findsOneWidget);
      expect(headerRect.left, greaterThanOrEqualTo(24));
      expect(
        tester.getRect(find.text('Lanterns at Dawn')).top,
        greaterThanOrEqualTo(24),
      );
      expect(headerRect.right, lessThanOrEqualTo(668));
      expect(lyricsRect.top, greaterThanOrEqualTo(headerRect.bottom));

      await tester.drag(
        find.byKey(const ValueKey('player-lyrics-scroll')),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('player-landscape-header')),
        findsOneWidget,
      );
      expect(find.text('Lanterns at Dawn'), findsOneWidget);
      expect(find.text('Mira Vale'), findsOneWidget);
      expect(
        tester.getRect(lyrics).top,
        greaterThanOrEqualTo(tester.getRect(header).bottom),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final scenario in [
    ('narrow_rtl', const Size(700, 360)),
    ('wide_rtl', const Size(1600, 900)),
  ]) {
    testWidgets(
      'lyrics scrollbar reaches pane edge in ${scenario.$1}',
      (tester) async {
        final controller = _Controller()
          ..lines = List.generate(
            30,
            (index) => LyricLineData(
              id: 'edge-$index',
              text: 'Reachable lyric row $index',
            ),
          );
        addTearDown(controller.dispose);
        await _pump(
          tester,
          controller,
          size: scenario.$2,
          locale: const Locale('ar'),
          onFullScreenChanged: (_) {},
        );

        final pane = find.byKey(const ValueKey('tablet-reader-content'));
        final scrollbar = find.byKey(
          const ValueKey('player-lyrics-scrollbar'),
        );
        final list = find.byKey(const ValueKey('player-lyrics-scroll'));
        expect(
          find.descendant(of: pane, matching: find.byType(Scrollbar)),
          findsOneWidget,
        );
        expect(scrollbar, findsOneWidget);
        expect(
          tester.getRect(scrollbar).left,
          closeTo(tester.getRect(pane).left, 1),
        );
        expect(
          tester.getRect(scrollbar).right,
          closeTo(tester.getRect(pane).right, 1),
        );
        final listView = tester.widget<ListView>(list);
        expect(listView.controller, isNotNull);
        expect(
          tester.widget<Scrollbar>(scrollbar).controller,
          same(listView.controller),
        );

        final lastLine = find.text('Reachable lyric row 29');
        await tester.scrollUntilVisible(
          lastLine,
          240,
          scrollable: find.descendant(
            of: list,
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        expect(lastLine.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(lastLine).bottom,
          lessThanOrEqualTo(tester.getRect(pane).bottom),
        );
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.windows,
      }),
    );
  }

  testWidgets(
    'collapsed portrait and landscape panels keep fullscreen toggle reachable',
    (tester) async {
      if (capturePlayerVisuals) {
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
      for (final size in [const Size(360, 780), const Size(700, 360)]) {
        final controller = _Controller()..playerControlsExpanded = false;
        addTearDown(controller.dispose);
        bool? fullscreen;
        await _pump(
          tester,
          controller,
          size: size,
          onFullScreenChanged: (value) => fullscreen = value,
        );

        final enter = find.byKey(const ValueKey('player-enter-fullscreen'));
        expect(enter, findsOneWidget);
        expect(tester.getSize(enter).width, greaterThanOrEqualTo(48));
        final orientation = size.width > size.height ? 'landscape' : 'portrait';
        if (capturePlayerVisuals) {
          await expectLater(
            find.byType(Scaffold).first,
            matchesGoldenFile(
              '../../artifacts/player-speed-landscape-qualification/captures-v2/collapsed-$orientation.png',
            ),
          );
        }
        await tester.tap(enter);
        expect(fullscreen, isTrue);

        await _pump(
          tester,
          controller,
          size: size,
          fullScreen: true,
          onFullScreenChanged: (value) => fullscreen = value,
        );
        final exit = find.byKey(const ValueKey('player-exit-fullscreen'));
        expect(exit, findsOneWidget);
        if (capturePlayerVisuals) {
          await expectLater(
            find.byType(Scaffold).first,
            matchesGoldenFile(
              '../../artifacts/player-speed-landscape-qualification/captures-v2/collapsed-$orientation-fullscreen.png',
            ),
          );
        }
        await tester.tap(exit);
        expect(fullscreen, isFalse);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('collapsed fullscreen action clears the long first lyric line', (
    tester,
  ) async {
    const text =
        'A long first lyric line stretches across the whole page so its actual letters would run underneath the fullscreen button';
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

    for (final locale in [const Locale('en'), const Locale('ar')]) {
      final controller = _Controller()
        ..playerControlsExpanded = false
        ..lines = const [LyricLineData(id: 'long-first', text: text)];
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller,
        size: const Size(700, 360),
        locale: locale,
        onFullScreenChanged: (_) {},
      );

      final actionFinder = find.byKey(
        const ValueKey('player-enter-fullscreen'),
      );
      final action = tester.getRect(actionFinder);
      expect(action.width, 48);
      expect(action.height, 48);
      final lyricsRect = tester.getRect(
        find.byKey(const ValueKey('tablet-reader-content')),
      );
      // The reserved 48 dp trailing gutter follows text direction.
      if (locale.languageCode == 'ar') {
        expect(action.right, closeTo(lyricsRect.left, 1));
      } else {
        expect(action.left, closeTo(lyricsRect.right, 1));
      }
      final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
      final glyphBoxes = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          )
          .map((box) {
            final bounds = box.toRect();
            return Rect.fromPoints(
              paragraph.localToGlobal(bounds.topLeft),
              paragraph.localToGlobal(bounds.bottomRight),
            );
          });
      expect(glyphBoxes, isNotEmpty);
      expect(glyphBoxes.any((box) => box.overlaps(action)), isFalse);
      expect(paragraph.didExceedMaxLines, isFalse);
      if (capturePlayerVisuals) {
        final orientation = locale.languageCode == 'ar' ? 'rtl' : 'ltr';
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile(
            '../../artifacts/player-speed-landscape-qualification/captures-v2/collapsed-long-first-line-$orientation.png',
          ),
        );
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'missing key stays neutral and large-text controls can collapse',
    (tester) async {
      final controller = _Controller()..songKey = null;
      addTearDown(controller.dispose);
      await _pump(tester, controller, size: const Size(320, 640), scale: 2);
      final keyMenu = find.byKey(const ValueKey('pitch-key-dropdown'));
      expect(
        find.descendant(of: keyMenu, matching: find.text('C')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(keyMenu);
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(keyMenu));
      expect(find.text(l10n.playerChordsNone), findsNothing);
      final editKey = find.byWidgetPredicate(
        (widget) =>
            widget is PopupMenuItem<String> && widget.value == 'edit-key',
      );
      expect(editKey, findsOneWidget);
      expect(find.byKey(const ValueKey('transpose-pitch-0')), findsNothing);
      expect(find.byType(CheckedPopupMenuItem<String>), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      await tester.tap(editKey);
      await tester.pumpAndSettle();
      expect(controller.calls, contains('edit:song'));

      expect(find.byKey(const ValueKey('start-lyric-scroll')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-seek-slider')), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.playerCollapseControls));
      await tester.pumpAndSettle();
      expect(controller.playerControlsExpanded, isFalse);
      expect(find.byKey(const ValueKey('start-lyric-scroll')), findsNothing);
      expect(find.byKey(const ValueKey('player-seek-slider')), findsNothing);
      expect(find.byTooltip(l10n.playerExpandControls), findsOneWidget);
      expect(find.text('When morning spills across the hills'), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.playerExpandControls));
      await tester.pumpAndSettle();
      expect(controller.playerControlsExpanded, isTrue);
      expect(find.byKey(const ValueKey('start-lyric-scroll')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-seek-slider')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final style in [
    'contrast',
    'backgroundUnderline',
    'background',
    'underline',
    'none',
  ]) {
    testWidgets('active lyric highlight $style does not change line geometry', (
      tester,
    ) async {
      final controller = _Controller()..highlightStyle = style;
      addTearDown(controller.dispose);
      await _pump(tester, controller, size: const Size(320, 640));

      final line = find.byType(ChordLyricsLine).first;
      final inactiveRect = tester.getRect(line);
      final inactiveStyle = tester.widget<ChordLyricsLine>(line).style!;

      controller.positionNotifier.value = const PlayerPosition(0, 'a');
      await tester.pump();

      final active = tester.widget<ChordLyricsLine>(line);
      expect(tester.getRect(line), inactiveRect);
      expect(active.style!.fontWeight, inactiveStyle.fontWeight);
      expect(
        active.style!.color,
        style == 'contrast'
            ? verseTheme(
                brightness: Brightness.light,
                palette: 'navy',
              ).colorScheme.tertiary
            : inactiveStyle.color,
      );
      expect(
        active.style!.decoration,
        style == 'underline' || style == 'backgroundUnderline'
            ? TextDecoration.underline
            : inactiveStyle.decoration,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'standard tuning aliases disappear while alternate tuning remains',
    (tester) async {
      final controller = _Controller();
      addTearDown(controller.dispose);
      await _pump(tester, controller);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PlayerScreen)),
      );
      for (final tuning in [
        '[E, A, D, G, B, E]',
        'E2 A2 D3 G3 B3 E4',
        'Standard',
        'Standard tuning',
        'Standard: E A D G B E',
        'E standard',
        'E standard tuning',
        'E standard tuning: E A D G B E',
      ]) {
        controller.tuning = tuning;
        controller.refresh();
        await tester.pump();
        expect(
          find.textContaining('${l10n.editorTuningField}:'),
          findsNothing,
          reason: tuning,
        );
      }
      controller.tuning = 'D A D G B E';
      controller.refresh();
      await tester.pump();
      expect(
        find.textContaining('${l10n.editorTuningField}: D A D G B E'),
        findsOneWidget,
      );
      expect(find.textContaining('${l10n.editorKeyField}: Em'), findsOneWidget);
    },
  );

  testWidgets(
    'comparison stays in overflow and speed opens a vertical popover',
    (tester) async {
      final controller = _Controller();
      addTearDown(controller.dispose);
      await _pump(tester, controller);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PlayerScreen)),
      );
      expect(find.text(l10n.searchCompare), findsNothing);
      expect(find.text(l10n.playerLyricsOnly), findsNothing);
      await tester.tap(find.byTooltip(l10n.songMenuLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.searchCompare));
      await tester.pumpAndSettle();
      expect(controller.calls, contains('compare'));
      expect(find.byKey(const ValueKey('scroll-speed-slider')), findsNothing);
      final playBefore = tester.getRect(
        find.byKey(const ValueKey('start-lyric-scroll')),
      );
      await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
      await tester.pumpAndSettle();
      final panel = tester.getRect(
        find.byKey(const ValueKey('scroll-speed-panel')),
      );
      expect(panel.height, greaterThan(panel.width));
      expect(
        find.byKey(const ValueKey('scroll-speed-duration')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('scroll-speed-panel')),
          matching: find.text('4:00'),
        ),
        findsOneWidget,
      );
      final speedMenuWidth = tester
          .getSize(
            find
                .byWidgetPredicate((widget) => widget is PopupMenuItem<double>)
                .first,
          )
          .width;
      expect(
        tester.getRect(find.byKey(const ValueKey('start-lyric-scroll'))),
        playBefore,
      );
      final speedSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('scroll-speed-slider')),
      );
      speedSlider.onChanged!(1.25);
      await tester.pump();
      expect(controller.speed, 1.25);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('scroll-speed-panel')),
          matching: find.text('3:12'),
        ),
        findsOneWidget,
      );
      expect(controller.speedWrites, 1);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pitch-key-dropdown')));
      await tester.pumpAndSettle();
      final keyMenuWidth = tester
          .getSize(find.byType(PopupMenuItem<String>).first)
          .width;
      expect(keyMenuWidth, speedMenuWidth);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.windows,
    }),
  );

  testWidgets('speed duration draft commits only valid slider interactions', (
    tester,
  ) async {
    final controller = _Controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);
    await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
    await tester.pumpAndSettle();

    var slider = _speedSlider(tester);
    var listener = _speedSliderListener(tester);
    final canceledGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('scroll-speed-slider'))),
      pointer: 10,
    );
    await canceledGesture.moveBy(const Offset(0, -32));
    await tester.pump();
    await canceledGesture.cancel();
    await tester.pumpAndSettle();
    expect(controller.speedWrites, 0);
    expect(controller.speed, 1);

    // Cancellation invalidates the callbacks captured by the old Slider.
    // A new interaction must use the freshly built slider callbacks.
    slider = _speedSlider(tester);
    listener = _speedSliderListener(tester);

    listener.onPointerDown!(
      PointerDownEvent(pointer: 11, position: Offset.zero),
    );
    slider.onChangeStart!(1);
    slider.onChanged!(1.25);
    await tester.pump();
    expect(controller.speedWrites, 0);
    expect(controller.speed, 1);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scroll-speed-panel')),
        matching: find.text('3:12'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scroll-speed-toggle')),
        matching: find.text('1.25×'),
      ),
      findsOneWidget,
    );

    // Slider reports onChangeEnd for a cancelled pointer on Flutter versions
    // where recognizer cancellation reaches _endInteraction first.
    slider.onChangeEnd!(1.25);
    listener.onPointerCancel!(
      PointerCancelEvent(pointer: 11, position: Offset.zero),
    );
    await tester.pump();
    expect(controller.speedWrites, 0);
    expect(controller.speed, 1);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scroll-speed-toggle')),
        matching: find.text('1×'),
      ),
      findsOneWidget,
    );

    listener.onPointerDown!(
      PointerDownEvent(pointer: 12, position: Offset.zero),
    );
    slider.onChangeStart!(1);
    slider.onChanged!(1.4);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    slider.onChangeEnd!(1.4);
    await tester.pump();
    expect(controller.speedWrites, 0);
    expect(controller.speed, 1);

    await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
    await tester.pumpAndSettle();
    slider = _speedSlider(tester);
    listener = _speedSliderListener(tester);
    listener.onPointerDown!(
      PointerDownEvent(pointer: 13, position: Offset.zero),
    );
    slider.onChangeStart!(1);
    slider.onChanged!(1.5);
    listener.onPointerUp!(PointerUpEvent(pointer: 13, position: Offset.zero));
    slider.onChangeEnd!(1.5);
    await tester.pumpAndSettle();
    expect(controller.speedWrites, 1);
    expect(controller.speed, 1.5);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scroll-speed-toggle')),
        matching: find.text('1.5×'),
      ),
      findsOneWidget,
    );
    slider.onChangeEnd!(1.5);
    expect(controller.speedWrites, 1);

    listener.onPointerDown!(
      PointerDownEvent(pointer: 14, position: Offset.zero),
    );
    slider.onChangeStart!(1.5);
    slider.onChanged!(1.25);
    controller.duration = 180;
    controller.refresh();
    await tester.pump();
    listener.onPointerUp!(PointerUpEvent(pointer: 14, position: Offset.zero));
    slider.onChangeEnd!(1.25);
    await tester.pump();
    expect(controller.speedWrites, 1);
    expect(controller.speed, 1.5);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scroll-speed-toggle')),
        matching: find.text('1.5×'),
      ),
      findsOneWidget,
    );

    listener.onPointerDown!(
      PointerDownEvent(pointer: 15, position: Offset.zero),
    );
    slider.onChangeStart!(1.5);
    slider.onChanged!(1.25);
    controller.songId = 'replacement-song';
    controller.refresh();
    await tester.pump();
    listener.onPointerUp!(PointerUpEvent(pointer: 15, position: Offset.zero));
    slider.onChangeEnd!(1.25);
    await tester.pump();
    expect(controller.speedWrites, 1);
    expect(controller.speed, 1.5);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scroll-speed-toggle')),
        matching: find.text('1.5×'),
      ),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
    await tester.pumpAndSettle();
    slider = _speedSlider(tester);
    final replacementController = _Controller()..speed = 1.5;
    addTearDown(replacementController.dispose);
    listener = _speedSliderListener(tester);
    listener.onPointerDown!(
      PointerDownEvent(pointer: 16, position: Offset.zero),
    );
    slider.onChangeStart!(1.5);
    slider.onChanged!(1.25);
    Listener? replacementListener;
    tester.binding.addPostFrameCallback((_) {
      replacementListener = _speedSliderListener(tester);
      replacementListener!.onPointerDown!(
        PointerDownEvent(pointer: 17, position: Offset.zero),
      );
      final replacementSlider = _speedSlider(tester);
      replacementSlider.onChangeStart!(1.5);
      replacementSlider.onChanged!(1.35);
    });
    await _pump(tester, replacementController);
    // The old slider's delayed end must not commit or clear the new draft.
    slider.onChangeEnd!(1.25);
    await tester.pump();
    expect(controller.speedWrites, 1);
    expect(replacementController.speedWrites, 0);
    expect(_speedSlider(tester).value, closeTo(1.35, 0.001));

    replacementListener!.onPointerCancel!(
      PointerCancelEvent(pointer: 17, position: Offset.zero),
    );
    await tester.pumpAndSettle();
    expect(replacementController.speedWrites, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
    await tester.pumpAndSettle();
    _speedSlider(tester).onChanged!(1.25); // keyboard/semantics adjustment
    await tester.pump();
    expect(replacementController.speedWrites, 1);
    expect(replacementController.speed, 1.25);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'speed popup accepts semantic increase after a real pointer cancel',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final controller = _Controller();
        addTearDown(controller.dispose);
        await _pump(tester, controller);
        await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
        await tester.pumpAndSettle();

        final slider = find.byKey(const ValueKey('scroll-speed-slider'));
        final canceledSlider = tester.widget<Slider>(slider);
        final canceledDrag = await tester.startGesture(
          tester.getCenter(slider),
          pointer: 33,
        );
        await canceledDrag.moveBy(const Offset(0, -24));
        await tester.pump();
        await canceledDrag.cancel();
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('scroll-speed-panel')),
          findsOneWidget,
        );
        expect(controller.speedWrites, 0);
        expect(controller.speed, 1);
        final sliderNode = tester.getSemantics(slider);
        expect(
          sliderNode.getSemanticsData().hasAction(ui.SemanticsAction.increase),
          isTrue,
        );
        sliderNode.owner!.performAction(
          sliderNode.id,
          ui.SemanticsAction.increase,
        );
        await tester.pumpAndSettle();
        final expectedSpeed = 1 + (2 - .5) * .05;

        expect(
          find.byKey(const ValueKey('scroll-speed-panel')),
          findsOneWidget,
        );
        expect(controller.speedWrites, 1);
        expect(controller.speed, expectedSpeed);
        expect(_speedSlider(tester).value, expectedSpeed);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('scroll-speed-panel')),
            matching: find.text(
              formatDuration(controller.duration / controller.speed),
            ),
          ),
          findsOneWidget,
        );

        // Callbacks saved before cancellation must remain inert after the
        // accessibility action starts and commits a new interaction.
        canceledSlider.onChangeStart!(1);
        canceledSlider.onChanged!(2);
        canceledSlider.onChangeEnd!(2);
        await tester.pumpAndSettle();
        expect(controller.speedWrites, 1);
        expect(controller.speed, expectedSpeed);
        expect(_speedSlider(tester).value, expectedSpeed);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'speed slider semantics follow duration and reopen after dismissal',
    (tester) async {
      if (capturePlayerVisuals) {
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
      final semantics = tester.ensureSemantics();
      try {
        final controller = _Controller();
        addTearDown(controller.dispose);
        await _pump(tester, controller);
        await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
        await tester.pumpAndSettle();

        final sliderFinder = find.byKey(const ValueKey('scroll-speed-slider'));
        expect(
          tester
              .getSemantics(sliderFinder)
              .getSemanticsData()
              .flagsCollection
              .isSlider,
          isTrue,
        );
        expect(
          tester.getSemantics(sliderFinder).getSemanticsData().value,
          contains('4:00'),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(sliderFinder),
          pointer: 42,
        );
        await gesture.moveBy(const Offset(0, -24));
        await tester.pump();
        final draftSpeedSlider = _speedSlider(tester);
        final draftSpeed = draftSpeedSlider.value;
        final draftSpeedLabel = draftSpeedSlider.label!;
        expect(draftSpeed, greaterThan(1));
        expect(controller.speedWrites, 0);
        expect(controller.speed, 1);
        final adjustedDuration = formatDuration(
          controller.duration / draftSpeed,
        );
        expect(
          tester.getSemantics(sliderFinder).getSemanticsData().value,
          contains(adjustedDuration),
        );
        expect(
          tester
              .widget<Semantics>(
                find.byKey(const ValueKey('scroll-speed-toggle-label')),
              )
              .properties
              .label,
          contains(draftSpeedLabel),
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('scroll-speed-panel')),
            matching: find.text(adjustedDuration),
          ),
          findsOneWidget,
        );
        if (capturePlayerVisuals) {
          await expectLater(
            find.byType(Overlay).first,
            matchesGoldenFile(
              '../../artifacts/player-speed-landscape-qualification/captures-v2/speed-live-preview-${defaultTargetPlatform.name}.png',
            ),
          );
        }

        await gesture.up();
        await tester.pumpAndSettle();
        expect(controller.speedWrites, 1);
        expect(controller.speed, closeTo(draftSpeed, 0.001));

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(sliderFinder, findsNothing);
        await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
        await tester.pumpAndSettle();
        expect(sliderFinder, findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('scroll-speed-panel')),
            matching: find.text(adjustedDuration),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.windows,
    }),
  );

  const capture = bool.fromEnvironment('CAPTURE_COMPACT_PLAYER');
  for (final scenario in [
    ('phone', const Size(390, 844), const Locale('en'), 1.0, Brightness.light),
    (
      'phone_large',
      const Size(320, 640),
      const Locale('en'),
      2.0,
      Brightness.light,
    ),
    (
      'phone_landscape',
      const Size(700, 360),
      const Locale('bg'),
      1.5,
      Brightness.light,
    ),
    (
      'phone_arabic',
      const Size(360, 780),
      const Locale('ar'),
      1.6,
      Brightness.dark,
    ),
    ('tablet', const Size(1024, 768), const Locale('uk'), 1.0, Brightness.dark),
    (
      'phone_fractional',
      const Size(360, 780),
      const Locale('en'),
      1.0,
      Brightness.light,
    ),
    (
      'phone_large_fractional',
      const Size(320, 640),
      const Locale('en'),
      2.0,
      Brightness.light,
    ),
    (
      'phone_quarter',
      const Size(360, 780),
      const Locale('en'),
      1.0,
      Brightness.light,
    ),
  ]) {
    testWidgets('compact player fits ${scenario.$1}', (tester) async {
      if (capture) {
        await tester.runAsync(() async {
          final font = scenario.$3.languageCode == 'ar'
              ? Future.value(
                  ByteData.sublistView(
                    await File(r'C:\Windows\Fonts\arial.ttf').readAsBytes(),
                  ),
                )
              : rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
          for (final family in ['Roboto', 'sans-serif']) {
            await (FontLoader(family)..addFont(font)).load();
          }
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
      }
      final controller = _Controller();
      if (scenario.$1.contains('fractional') ||
          scenario.$1.contains('quarter')) {
        controller.speed = scenario.$1.contains('quarter') ? 1.25 : .55;
        controller.songKey = 'D#min';
      }
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller,
        size: scenario.$2,
        locale: scenario.$3,
        scale: scenario.$4,
        brightness: scenario.$5,
      );
      expect(find.byKey(const ValueKey('player-seek-slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('start-lyric-scroll')), findsOneWidget);
      expect(find.byKey(const ValueKey('scroll-speed-slider')), findsNothing);
      final layoutError = tester.takeException();
      expect(
        layoutError,
        isNull,
        reason: layoutError is FlutterError
            ? layoutError.toDiagnosticsNode().toStringDeep()
            : null,
      );
      if (capture) {
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile(
            '../../artifacts/player-speed-landscape-qualification/captures-v2/compact-player-${scenario.$1}.png',
          ),
        );
        await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final speedPopupWidth = tester
            .getSize(
              find
                  .byWidgetPredicate(
                    (widget) => widget is PopupMenuItem<double>,
                  )
                  .first,
            )
            .width;
        final speedPopupRect = tester.getRect(
          find
              .byWidgetPredicate((widget) => widget is PopupMenuItem<double>)
              .first,
        );
        final isRtl = scenario.$3.languageCode == 'ar';
        if (isRtl) {
          expect(speedPopupRect.left, closeTo(8, 1));
        } else {
          expect(speedPopupRect.right, closeTo(scenario.$2.width - 8, 1));
        }
        await expectLater(
          find.byType(Overlay).first,
          matchesGoldenFile(
            '../../artifacts/player-speed-landscape-qualification/captures-v2/compact-player-${scenario.$1}-speed.png',
          ),
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        final keyMenu = find.byKey(const ValueKey('pitch-key-dropdown'));
        await tester.ensureVisible(keyMenu);
        final keyAnchor = tester.getRect(keyMenu);
        await tester.tap(keyMenu);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final keyPopupWidth = tester
            .getSize(find.byType(PopupMenuItem<String>).first)
            .width;
        final keyPopupRect = tester.getRect(
          find.byType(PopupMenuItem<String>).first,
        );
        expect(keyPopupWidth, speedPopupWidth);
        expect(keyPopupRect.left, lessThan(keyAnchor.right));
        expect(keyPopupRect.right, greaterThan(keyAnchor.left));
        expect(
          find.text(
            AppLocalizations.of(tester.element(keyMenu)).playerChordsNone,
          ),
          findsNothing,
        );
        final lastPitch = find.byKey(const ValueKey('transpose-pitch-11'));
        await tester.ensureVisible(lastPitch);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(lastPitch).bottom,
          lessThanOrEqualTo(scenario.$2.height),
        );
        await expectLater(
          find.byType(Overlay).first,
          matchesGoldenFile(
            '../../artifacts/player-speed-landscape-qualification/captures-v2/compact-player-${scenario.$1}-chords.png',
          ),
        );
      }
    });
  }
}
