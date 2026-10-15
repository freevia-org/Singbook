import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/library/editor_screen.dart';
import 'package:singbook/ui/player/screen_awake.dart';
import 'package:singbook/ui/player/section_labels.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

class _FakeAwake implements ScreenAwake {
  _FakeAwake({this.fail = false});
  final bool fail;
  final events = <String>[];

  @override
  Future<void> enable() async {
    events.add('enable');
    if (fail) throw PlatformException(code: 'unsupported');
  }

  @override
  Future<void> disable() async {
    events.add('disable');
    if (fail) throw PlatformException(code: 'unsupported');
  }
}

final _lines = [
  for (var i = 0; i < 60; i++)
    LyricLineData(id: 'line-$i', text: 'Lyric number $i'),
];

VerseUiState _reader({
  bool playing = false,
  bool autoscroll = true,
  double? duration = 200,
  bool durationEstimated = false,
  List<LyricLineData>? lines,
  List<PlayerSectionMarker>? sections,
  VerseRoute route = VerseRoute.reader,
  String artist = 'Artist',
}) => VerseUiState(
  route: route,
  song: SongCardData(
    id: 's',
    title: 'Test song',
    artist: artist,
    durationSeconds: duration,
  ),
  songLines: lines ?? _lines,
  isPlaying: playing,
  autoscroll: autoscroll,
  readerDurationEstimated: durationEstimated,
  playerSections:
      sections ??
      const [
        PlayerSectionMarker(name: 'Verse 1', startSeconds: 0, lineId: 'line-0'),
        PlayerSectionMarker(
          name: 'Chorus',
          startSeconds: 100,
          lineId: 'line-30',
        ),
      ],
);

void main() {
  group('Editor numeric fields', () {
    VerseUiState editorState({
      String duration = '',
      String tempo = '',
      String capo = '',
    }) => VerseUiState(
      route: VerseRoute.editor,
      editor: SongEditorData(
        songId: 's',
        isNew: false,
        title: 'Song',
        duration: duration,
        tempo: tempo,
        capo: capo,
      ),
    );

    Future<void> save(WidgetTester tester, AppLocalizations l10n) async {
      await tester.tap(find.byTooltip(l10n.actionSave));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
    }

    for (final locale in const [
      Locale('en'),
      Locale('uk'),
      Locale('ar'),
      Locale('de'),
    ]) {
      testWidgets('free text duration is rejected, never saved ($locale)', (
        tester,
      ) async {
        final c = FakeUiController((_) => editorState());
        addTearDown(c.dispose);
        await pumpShell(tester, c, locale: locale);
        final l10n = l10nOf(tester);
        final duration = find.widgetWithText(
          TextField,
          l10n.editorDurationField,
        );

        for (final garbage in const [
          'about 4 min',
          '1:02:03',
          'PT3M',
          '3:75',
        ]) {
          await tester.enterText(duration, garbage);
          await tester.pump();
          await save(tester, l10n);
          expect(
            find.text(l10n.editorDurationInvalid),
            findsOneWidget,
            reason: garbage,
          );
          expect(
            c.calls.where((call) => call.startsWith('saveLyricsEdit')),
            isEmpty,
            reason: garbage,
          );
        }

        // Correcting the text clears the error and the save goes through.
        await tester.enterText(duration, '3:45');
        await tester.pump();
        expect(find.text(l10n.editorDurationInvalid), findsNothing);
        await save(tester, l10n);
        expect(
          c.calls.singleWhere((call) => call.startsWith('saveLyricsEdit')),
          contains('{duration: 3:45}'),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('seconds, decimals and an empty duration are accepted', (
      tester,
    ) async {
      final c = FakeUiController((_) => editorState());
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);
      await tester.enterText(
        find.widgetWithText(TextField, l10n.editorDurationField),
        '225.5',
      );
      await tester.pump();
      await save(tester, l10n);
      expect(
        c.calls.singleWhere((call) => call.startsWith('saveLyricsEdit')),
        contains('{duration: 225.5}'),
      );
    });

    testWidgets('tempo and capo must be numbers', (tester) async {
      final c = FakeUiController((_) => editorState());
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);
      await tester.enterText(
        find.widgetWithText(TextField, l10n.editorTempoField),
        'fast',
      );
      await tester.enterText(
        find.widgetWithText(TextField, l10n.editorCapoField),
        'II',
      );
      await tester.pump();
      await save(tester, l10n);
      expect(find.text(l10n.editorNumberInvalid), findsNWidgets(2));
      expect(
        c.calls.where((call) => call.startsWith('saveLyricsEdit')),
        isEmpty,
      );

      await tester.enterText(
        find.widgetWithText(TextField, l10n.editorTempoField),
        '96',
      );
      await tester.enterText(
        find.widgetWithText(TextField, l10n.editorCapoField),
        '2',
      );
      await tester.pump();
      await save(tester, l10n);
      expect(
        c.calls.singleWhere((call) => call.startsWith('saveLyricsEdit')),
        allOf(contains('{tempo: 96}'), contains('{capo: 2}')),
      );
    });

    testWidgets('an unchanged stored value never blocks saving', (
      tester,
    ) async {
      final c = FakeUiController((_) => editorState(duration: '3 min'));
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);
      await tester.enterText(find.byType(TextField).first, 'Renamed');
      await tester.pump();
      await save(tester, l10n);
      expect(
        c.calls.where((call) => call.startsWith('saveLyricsEdit')),
        hasLength(1),
      );
    });

    test('validators', () {
      for (final ok in ['', ' ', '0', '225', '225.5', '3:45', '0:07', '12:5']) {
        expect(isValidEditorDuration(ok), isTrue, reason: ok);
      }
      for (final bad in [
        '3 min',
        '3m45s',
        '1:02:03',
        '3:60',
        ':30',
        'PT3M',
        '-5',
        '3,5',
      ]) {
        expect(isValidEditorDuration(bad), isFalse, reason: bad);
      }
      expect(isValidEditorNumber('96'), isTrue);
      expect(isValidEditorNumber(''), isTrue);
      expect(isValidEditorNumber('9x'), isFalse);
    });
  });

  group('Player wake lock', () {
    late ScreenAwake original;
    setUp(() => original = defaultScreenAwake);
    tearDown(() => defaultScreenAwake = original);

    testWidgets('is held exactly while the song plays', (tester) async {
      final awake = _FakeAwake();
      defaultScreenAwake = awake;
      var playing = false;
      final c = FakeUiController((_) => _reader(playing: playing));
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      expect(awake.events, isEmpty);

      playing = true;
      c.refresh();
      await tester.pump();
      c.refresh();
      await tester.pump();
      expect(awake.events, ['enable']);

      playing = false;
      c.refresh();
      await tester.pump();
      expect(awake.events, ['enable', 'disable']);
    });

    testWidgets('is released when the app pauses and retaken on return', (
      tester,
    ) async {
      final awake = _FakeAwake();
      defaultScreenAwake = awake;
      final c = FakeUiController((_) => _reader(playing: true));
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      expect(awake.events, ['enable']);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(awake.events, ['enable', 'disable']);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(awake.events, ['enable', 'disable', 'enable']);
    });

    testWidgets('is released when the player is left', (tester) async {
      final awake = _FakeAwake();
      defaultScreenAwake = awake;
      var route = VerseRoute.reader;
      final c = FakeUiController((_) => _reader(playing: true, route: route));
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      expect(awake.events, ['enable']);

      route = VerseRoute.main;
      c.refresh();
      await tester.pumpAndSettle();
      expect(awake.events, ['enable', 'disable']);
    });

    testWidgets('a failing plugin never breaks the player', (tester) async {
      final awake = _FakeAwake(fail: true);
      defaultScreenAwake = awake;
      final c = FakeUiController((_) => _reader(playing: true));
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      expect(awake.events, ['enable']);
      expect(tester.takeException(), isNull);
    });
  });

  group('Player', () {
    testWidgets('play after the song ended starts again from the start', (
      tester,
    ) async {
      final c = FakeUiController((_) => _reader());
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      c.positionNotifier.value = const PlayerPosition(200, 'line-59');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('start-lyric-scroll')));
      await tester.pump();
      expect(c.calls.where((c) => c == 'seek(0.0)' || c == 'playPause'), [
        'seek(0.0)',
        'playPause',
      ]);
    });

    testWidgets('play mid-song keeps the position', (tester) async {
      final c = FakeUiController((_) => _reader());
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      c.positionNotifier.value = const PlayerPosition(80, 'line-20');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('start-lyric-scroll')));
      await tester.pump();
      expect(c.calls.where((call) => call.startsWith('seek(')), isEmpty);
      expect(c.calls, contains('playPause'));
    });

    testWidgets('an estimated duration is labelled, not shown as real', (
      tester,
    ) async {
      final c = FakeUiController(
        (_) => _reader(duration: null, durationEstimated: true),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);
      // 60 lines are estimated at 3:24; it must only appear as an estimate.
      expect(find.text(l10n.playerEstimatedDuration('3:24')), findsOneWidget);
      expect(find.text('3:24'), findsNothing);
      expect(find.text('3:20'), findsNothing);
    });

    testWidgets('a real duration is shown', (tester) async {
      final c = FakeUiController((_) => _reader());
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      expect(find.text('3:20'), findsOneWidget);
    });

    testWidgets('dragging the lyrics seeks while autoscroll is on', (
      tester,
    ) async {
      final c = FakeUiController((_) => _reader(autoscroll: true));
      addTearDown(c.dispose);
      await pumpShell(tester, c, size: const Size(360, 640));

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(c.calls.where((call) => call.startsWith('seek(')), isNotEmpty);
      expect(c.positionNotifier.value.seconds, greaterThan(0));
    });

    testWidgets('a fling keeps following the lyrics until they settle', (
      tester,
    ) async {
      final c = FakeUiController((_) => _reader(autoscroll: true));
      addTearDown(c.dispose);
      await pumpShell(tester, c, size: const Size(360, 640));

      await tester.fling(find.byType(ListView), const Offset(0, -300), 3500);
      await tester.pumpAndSettle();
      // The drag alone covers about the first dozen lines; the position had to
      // follow the ballistic part to end up far down the song.
      expect(c.positionNotifier.value.seconds, greaterThan(60));
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.position.pixels, greaterThan(1000));
    });

    testWidgets('scrolling does not seek when autoscroll is off', (
      tester,
    ) async {
      final c = FakeUiController((_) => _reader(autoscroll: false));
      addTearDown(c.dispose);
      await pumpShell(tester, c, size: const Size(360, 640));

      await tester.fling(find.byType(ListView), const Offset(0, -300), 3500);
      await tester.pumpAndSettle();
      expect(c.calls.where((call) => call.startsWith('seek(')), isEmpty);
      expect(c.positionNotifier.value.seconds, 0);
    });

    testWidgets('holding the seek thumb ignores clock ticks', (tester) async {
      final c = FakeUiController((_) => _reader());
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      final slider = find.byType(Slider);
      final gesture = await tester.startGesture(tester.getCenter(slider));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      final held = tester.widget<Slider>(slider).value;
      expect(held, greaterThan(0));

      c.positionNotifier.value = PlayerPosition(held + 30, 'line-40');
      await tester.pump();
      expect(tester.widget<Slider>(slider).value, held);

      await gesture.up();
      await tester.pump();
    });

    for (final (locale, chorus, preChorus) in const [
      (Locale('en'), 'Chorus', 'Pre-Chorus 2'),
      (Locale('uk'), 'Приспів', 'Передприспів 2'),
      (Locale('de'), 'Refrain', 'Pre-Chorus 2'),
      (Locale('ar'), 'اللازمة', 'ما قبل اللازمة 2'),
    ]) {
      testWidgets('section names follow the language ($locale)', (
        tester,
      ) async {
        final lines = [
          const LyricLineData(id: 'sec-0', section: 'Pre-Chorus 2'),
          ..._lines,
        ];
        final c = FakeUiController(
          (_) => _reader(
            lines: lines,
            sections: const [
              PlayerSectionMarker(
                name: 'Chorus',
                startSeconds: 0,
                lineId: 'line-0',
              ),
            ],
          ),
        );
        addTearDown(c.dispose);
        await pumpShell(tester, c, size: const Size(800, 640), locale: locale);

        expect(find.text(preChorus), findsOneWidget);
        // The current section above the slider and its marker label.
        expect(find.text(chorus), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('custom section headings are shown as written', (tester) async {
      final lines = [
        const LyricLineData(id: 'sec-0', section: 'Приспів із виходом'),
        ..._lines,
      ];
      final c = FakeUiController((_) => _reader(lines: lines));
      addTearDown(c.dispose);
      await pumpShell(tester, c, locale: const Locale('de'));
      expect(find.text('Приспів із виходом'), findsOneWidget);
    });

    test('section parsing and abbreviations', () {
      expect(parseSectionName('Pre-Chorus 2')?.kind, 'pre-chorus');
      expect(parseSectionName('prechorus')?.kind, 'pre-chorus');
      expect(parseSectionName('Verse 1 (x2)')?.rest, ' 1 (x2)');
      expect(parseSectionName('Versefoo'), isNull);
      expect(parseSectionName('Приспів'), isNull);
    });

    testWidgets('the metadata line starts at the reading edge in Arabic', (
      tester,
    ) async {
      final c = FakeUiController((_) => _reader(artist: 'Singer'));
      addTearDown(c.dispose);
      await pumpShell(
        tester,
        c,
        locale: const Locale('ar'),
        size: const Size(360, 640),
      );
      expect(
        Directionality.of(tester.element(find.text('Singer'))),
        TextDirection.rtl,
      );
      expect(tester.getTopRight(find.text('Singer')).dx, greaterThan(300));

      await pumpShell(tester, c, size: const Size(360, 640));
      expect(tester.getTopLeft(find.text('Singer')).dx, lessThan(60));
    });
  });
}
