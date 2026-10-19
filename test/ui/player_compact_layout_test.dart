import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
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
  @override
  VerseUiState get state => VerseUiState(
    route: VerseRoute.reader,
    song: SongCardData(
      id: 'song',
      title: 'Lanterns at Dawn',
      artist: 'Mira Vale',
      album: 'Quiet Rooms',
      key: songKey,
      hasChords: true,
      durationSeconds: 240,
    ),
    readerKey: songKey,
    readerTuning: tuning,
    readerSource: 'Original fixture source',
    readerCanCompareVersions: true,
    playbackSpeed: speed,
    showChords: showChords,
    playerControlsExpanded: playerControlsExpanded,
    lyricHighlightStyle: highlightStyle,
    songLines: const [
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
  Future<void> setPlaybackSpeed(double value) async {
    speed = value;
    notifyListeners();
  }

  @override
  Future<void> compareCurrentSongVersions() async {
    calls.add('compare');
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
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
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
          builder: (context, _) => PlayerScreen(controller: controller),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
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
          if (scenario.$4.languageCode == 'ar') {
            expect(key.left, greaterThanOrEqualTo(play.right));
          } else {
            expect(key.right, lessThanOrEqualTo(play.left));
          }
          expect(key.center.dy, closeTo(play.center.dy, 1));
          expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
          expect(find.byIcon(Icons.add_circle_outline), findsNothing);
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          final shift = find.byKey(const ValueKey('transpose-offset-2'));
          expect(shift, findsOneWidget);
          await tester.ensureVisible(shift);
          final popup = tester.getRect(shift);
          expect(popup.left, lessThan(key.right));
          expect(popup.right, greaterThan(key.left));
          expect(tester.getRect(shift).top, greaterThanOrEqualTo(0));
          expect(
            tester.getRect(shift).bottom,
            lessThanOrEqualTo(scenario.$2.height),
          );
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
    expect(tester.takeException(), isNull);
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
      expect(
        find.descendant(of: keyMenu, matching: find.text('0')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(keyMenu);
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(keyMenu));
      expect(find.text(l10n.playerChordsNone), findsNothing);
      expect(find.byKey(const ValueKey('transpose-offset--6')), findsOneWidget);
      expect(find.byKey(const ValueKey('transpose-offset-6')), findsOneWidget);
      expect(find.byType(CheckedPopupMenuItem<String>), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

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
      await tester.drag(
        find.byKey(const ValueKey('scroll-speed-slider')),
        const Offset(0, -35),
      );
      await tester.pump();
      expect(controller.speed, isNot(1));
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
            '../../artifacts/compact-player-${scenario.$1}.png',
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
            '../../artifacts/compact-player-${scenario.$1}-speed.png',
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
            '../../artifacts/compact-player-${scenario.$1}-chords.png',
          ),
        );
      }
    });
  }
}
