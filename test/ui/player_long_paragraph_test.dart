import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/player/player_lyric_line.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

class _Controller extends FakeUiController {
  _Controller(this.lines, String active)
    : super((controller) => (controller as _Controller)._state) {
    positionNotifier.value = PlayerPosition(0, active);
  }

  final List<LyricLineData> lines;
  VerseUiState get _state => VerseUiState(
    route: VerseRoute.reader,
    song: const SongCardData(
      id: 'test',
      title: 'Long paragraph',
      durationSeconds: 90,
    ),
    songLines: lines,
    lyricsFontSize: 24,
    playerControlsExpanded: false,
  );
}

Future<void> _pump(
  WidgetTester tester,
  _Controller controller,
  Size size, {
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: singbookLocalizationsDelegates,
      supportedLocales: const [Locale('en')],
      theme: verseTheme(
        brightness: Brightness.light,
        palette: 'navy',
        fontFamily: 'Roboto',
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: PlayerScreen(controller: controller)),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _line(String id) => find.byWidgetPredicate(
  (widget) => widget is PlayerLyricLine && widget.line.id == id,
);

void main() {
  for (final spec in [
    (const Size(390, 800), 1.0),
    (const Size(800, 390), 1.0),
    (const Size(900, 1200), 1.6),
  ]) {
    testWidgets(
      'oversized lyric paragraph opens with its beginning visible ${spec.$1}/${spec.$2}',
      (tester) async {
        final controller = _Controller([
          LyricLineData(
            id: 'long',
            text: List.filled(160, 'A quiet line of words.').join(' '),
          ),
        ], 'long');
        addTearDown(controller.dispose);
        await _pump(tester, controller, spec.$1, scale: spec.$2);
        final viewport = tester.getRect(
          find.byKey(const ValueKey('player-lyrics-scroll')),
        );
        final paragraph = tester.getRect(_line('long'));
        expect(paragraph.height, greaterThan(viewport.height));
        expect(
          paragraph.top,
          greaterThanOrEqualTo(viewport.top - 1),
          reason:
              'At the start of a long paragraph, its first words must remain in view.',
        );
        expect(paragraph.top, lessThan(viewport.top + 48));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'an offscreen oversized paragraph reveals its beginning after seek',
    (tester) async {
      final controller = _Controller([
        ...List.generate(
          35,
          (index) => LyricLineData(
            id: 'prefix-$index',
            text: 'Earlier lyric line $index',
          ),
        ),
        LyricLineData(
          id: 'long',
          text: List.filled(160, 'A quiet line of words.').join(' '),
        ),
      ], 'long');
      addTearDown(controller.dispose);
      await _pump(tester, controller, const Size(390, 800));
      final viewport = tester.getRect(
        find.byKey(const ValueKey('player-lyrics-scroll')),
      );
      final paragraph = tester.getRect(_line('long'));
      expect(paragraph.height, greaterThan(viewport.height));
      expect(paragraph.top, greaterThanOrEqualTo(viewport.top - 1));
      expect(paragraph.top, lessThan(viewport.top + 48));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ordinary current lines still align within the reading area', (
    tester,
  ) async {
    final controller = _Controller(
      List.generate(
        40,
        (index) =>
            LyricLineData(id: 'line-$index', text: 'Short lyric line $index'),
      ),
      'line-20',
    );
    addTearDown(controller.dispose);
    await _pump(tester, controller, const Size(390, 800));
    final viewport = tester.getRect(
      find.byKey(const ValueKey('player-lyrics-scroll')),
    );
    final current = tester.getRect(_line('line-20'));
    expect(current.top, greaterThan(viewport.top + viewport.height * .2));
    expect(current.bottom, lessThan(viewport.top + viewport.height * .65));
    expect(tester.takeException(), isNull);
  });
}
