import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

class _Controller extends FakeUiController {
  _Controller() : super((c) => (c as _Controller)._state);
  String tuning = '[E, A, D, G, B, E]';
  String? songKey = 'Em';
  double speed = 1;
  VerseUiState get _state => VerseUiState(
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
  Future<void> setPlaybackSpeed(double value) async {
    speed = value;
    refresh();
  }

  @override
  Future<void> compareCurrentSongVersions() async {
    calls.add('compare');
  }
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
      localizationsDelegates: singbookLocalizationsDelegates,
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
  testWidgets('missing key stays neutral with large text controls reachable', (
    tester,
  ) async {
    final controller = _Controller()..songKey = null;
    addTearDown(controller.dispose);
    await _pump(tester, controller, size: const Size(320, 640), scale: 2);
    final keyMenu = find.byKey(const ValueKey('pitch-key-dropdown'));
    expect(
      find.descendant(of: keyMenu, matching: find.text('C')),
      findsNothing,
    );
    expect(
      find.descendant(of: keyMenu, matching: find.text('—')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(keyMenu);
    await tester.pumpAndSettle();
    expect(find.byType(CheckedPopupMenuItem<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
      expect(find.textContaining('${l10n.editorKeyField}:'), findsNothing);
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
        tester.getRect(find.byKey(const ValueKey('start-lyric-scroll'))),
        playBefore,
      );
      await tester.drag(
        find.byKey(const ValueKey('scroll-speed-slider')),
        const Offset(0, -35),
      );
      await tester.pump();
      expect(controller.speed, isNot(1));
      expect(tester.takeException(), isNull);
    },
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
        await expectLater(
          find.byType(Overlay).first,
          matchesGoldenFile(
            '../../artifacts/compact-player-${scenario.$1}-speed.png',
          ),
        );
      }
    });
  }
}
