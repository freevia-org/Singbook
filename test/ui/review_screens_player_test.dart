import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/player/screen_awake.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

import 'support/fake_controller.dart';

class _FakeAwake implements ScreenAwake {
  final events = <String>[];

  @override
  Future<void> enable() async => events.add('enable');

  @override
  Future<void> disable() async => events.add('disable');
}

const _sections = [
  PlayerSectionMarker(name: 'Verse 1', startSeconds: 0, lineId: 'a'),
  PlayerSectionMarker(name: 'Chorus', startSeconds: 50, lineId: 'b'),
  PlayerSectionMarker(name: 'Verse 2', startSeconds: 120, lineId: 'c'),
];

const _lines = [
  LyricLineData(id: 'a', text: 'First line'),
  LyricLineData(id: 'b', text: 'Second line'),
  LyricLineData(id: 'c', text: 'Third line'),
];

/// A reader inside a setlist. [progress] is what the state reported when the
/// screen was last built; the live position comes from the position notifier.
VerseUiState _setlistReader({double progress = 0, bool playing = false}) =>
    VerseUiState(
      route: VerseRoute.reader,
      song: const SongCardData(
        id: 's',
        title: 'Test song',
        artist: 'Artist',
        durationSeconds: 200,
      ),
      songLines: _lines,
      playerSections: _sections,
      progressSeconds: progress,
      isPlaying: playing,
      activeSetlist: const SetlistCardData(id: 'list', title: 'Sunday'),
    );

void main() {
  late ScreenAwake originalAwake;
  setUp(() {
    originalAwake = defaultScreenAwake;
    defaultScreenAwake = _FakeAwake();
  });
  tearDown(() => defaultScreenAwake = originalAwake);

  group('setlist transport uses the live position', () {
    testWidgets('Previous restarts the section after an unbuilt seek', (
      tester,
    ) async {
      // The state still reports the start of the song, as it does between
      // rebuilds: position changes are published only through the notifier.
      final c = FakeUiController((_) => _setlistReader());
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      c.positionNotifier.value = const PlayerPosition(70, null);
      await tester.pump();
      c.calls.clear();

      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      await tester.pump();

      expect(c.calls, isNot(contains('previousSong')));
      // 70 s is 20 s into the chorus, so Previous returns to its start.
      expect(c.calls, ['seek(50.0)']);
    });

    testWidgets('Previous still opens the previous song near the start', (
      tester,
    ) async {
      final c = FakeUiController((_) => _setlistReader(progress: 90));
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      // The stale state says 90 s; the live position is back at the start.
      c.positionNotifier.value = const PlayerPosition(1, null);
      await tester.pump();
      c.calls.clear();

      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      await tester.pump();

      expect(c.calls, ['previousSong']);
    });

    testWidgets('Next advances the setlist once the live position ended', (
      tester,
    ) async {
      final c = FakeUiController((_) => _setlistReader());
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      c.positionNotifier.value = const PlayerPosition(200, null);
      await tester.pump();
      c.calls.clear();

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump();

      expect(c.calls, ['nextSong']);
    });

    testWidgets('Next skips to the following section mid-song', (tester) async {
      final c = FakeUiController((_) => _setlistReader(progress: 200));
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      c.positionNotifier.value = const PlayerPosition(10, null);
      await tester.pump();
      c.calls.clear();

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump();

      expect(c.calls, ['seek(50.0)']);
    });
  });

  testWidgets('wake lock survives an unfocused but visible window', (
    tester,
  ) async {
    final awake = _FakeAwake();
    defaultScreenAwake = awake;
    final c = FakeUiController((_) => _setlistReader(playing: true));
    addTearDown(c.dispose);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await pumpShell(tester, c);
    expect(awake.events, ['enable']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(awake.events, ['enable']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(awake.events, ['enable', 'disable']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(awake.events, ['enable', 'disable', 'enable']);
  });

  group('chord line layout', () {
    const chords = [
      LyricChord(graphemeOffset: 0, symbol: 'G'),
      LyricChord(graphemeOffset: 6, symbol: 'C'),
    ];

    Widget line(String text, {double fontSize = 20, double width = 300}) =>
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: ChordLyricsLine(
                  text: text,
                  chords: chords,
                  showChords: true,
                  style: TextStyle(fontSize: fontSize),
                  chordStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        );

    CustomPainter painter(WidgetTester tester) => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(ChordLyricsLine),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;

    testWidgets('is reused when a rebuild changes none of its inputs', (
      tester,
    ) async {
      await tester.pumpWidget(line('Hello world'));
      final first = painter(tester);
      final size = tester.getSize(find.byType(ChordLyricsLine));

      await tester.pumpWidget(line('Hello world'));
      final second = painter(tester);

      expect(identical(first, second), isFalse);
      expect(second.shouldRepaint(first), isFalse);
      expect(tester.getSize(find.byType(ChordLyricsLine)), size);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is recomputed when text, style or width change', (
      tester,
    ) async {
      await tester.pumpWidget(line('Hello world'));
      var previous = painter(tester);
      final size = tester.getSize(find.byType(ChordLyricsLine));

      await tester.pumpWidget(line('Hello there world'));
      expect(painter(tester).shouldRepaint(previous), isTrue);
      previous = painter(tester);

      await tester.pumpWidget(line('Hello there world', fontSize: 30));
      expect(painter(tester).shouldRepaint(previous), isTrue);
      expect(
        tester.getSize(find.byType(ChordLyricsLine)).height,
        greaterThan(size.height),
      );
      previous = painter(tester);

      await tester.pumpWidget(
        line('Hello there world', fontSize: 30, width: 120),
      );
      expect(painter(tester).shouldRepaint(previous), isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
