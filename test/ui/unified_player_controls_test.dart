import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/player/screen_awake.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_controller.dart';

const _body = '[Verse]\n[C]First original words\n[Chorus]\n[G]Original refrain';

class _LocalAwake implements ScreenAwake {
  int enables = 0;
  int disables = 0;

  @override
  Future<void> enable() async {
    enables++;
  }

  @override
  Future<void> disable() async {
    disables++;
  }
}

Future<void> _pumpPlayer(
  WidgetTester tester,
  AppControllerAdapter controller,
  ScreenAwake awake, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: singbookLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) =>
              PlayerScreen(controller: controller, screenAwake: awake),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _sliderSectionLabels(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .where(
      (text) =>
          text.semanticsLabel == 'Verse' || text.semanticsLabel == 'Chorus',
    )
    .map((text) => text.semanticsLabel!)
    .toList();

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late AppController app;
  late AppControllerAdapter ui;
  late _LocalAwake awake;

  Future<void> start() async {
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService(const []),
    );
    ui = AppControllerAdapter(app);
    await ui.initialize();
    awake = _LocalAwake();
  }

  Future<void> flush(WidgetTester tester) async {
    await tester.runAsync(() => repository.getSetting('app'));
    await tester.pumpAndSettle();
  }

  Future<void> openFixture(WidgetTester tester) async {
    await tester.runAsync(() async {
      await app.saveSong(
        SongDocument(
          id: 'original-player',
          title: 'Original panel fixture',
          artist: 'Original test artist',
          body: _body,
          metadata: const {'key': 'C', 'durationSeconds': 120},
          activeTimingTrackId: 'original-track',
          timingTracks: const [
            TimingTrack(
              id: 'original-track',
              sourceDocumentId: 'original-local-source',
              sourceLyrics: 'First original words\nOriginal refrain',
              format: 'lrc',
              status: TimingStatus.usable,
              cues: [
                TimingCue(
                  id: 'first',
                  occurrenceId: 'line-0',
                  text: 'First original words',
                  startUs: 10000000,
                ),
                TimingCue(
                  id: 'refrain',
                  occurrenceId: 'line-1',
                  text: 'Original refrain',
                  startUs: 70000000,
                ),
              ],
            ),
          ],
        ),
      );
      await ui.openSong('original-player');
      await ui.setTimingMode('timed');
    });
  }

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    await start();
  });

  tearDown(() async {
    await ui.settlePlayerPreferences();
    await repository.getSetting('app');
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  testWidgets(
    'hiding headings retains lyrics, slider labels, cues and seeking',
    (tester) async {
      await openFixture(tester);
      await _pumpPlayer(tester, ui, awake);
      final l10n = l10nOf(tester);
      final lyrics = find.descendant(
        of: find.byKey(const ValueKey('tablet-reader-content')),
        matching: find.byType(ListView),
      );
      expect(
        find.descendant(of: lyrics, matching: find.text(l10n.sectionVerse)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: lyrics, matching: find.text(l10n.sectionChorus)),
        findsOneWidget,
      );
      final labelsBefore = _sliderSectionLabels(tester);
      expect(labelsBefore, contains('Chorus'));
      final markersBefore = [
        for (final marker in ui.state.playerSections)
          (marker.name, marker.lineId, marker.startSeconds),
      ];
      expect(markersBefore.map((marker) => marker.$3), [10, 70]);
      final linesBefore = [
        for (final line in ui.state.songLines)
          (line.id, line.text, line.section),
      ];
      final trackBefore = app.songs.single.timingTracks.single.toJson();

      await tester.runAsync(() => ui.setShowSections(false));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: lyrics, matching: find.text(l10n.sectionVerse)),
        findsNothing,
      );
      expect(
        find.descendant(of: lyrics, matching: find.text(l10n.sectionChorus)),
        findsNothing,
      );
      expect(
        tester
            .widgetList<ChordLyricsLine>(find.byType(ChordLyricsLine))
            .map((line) => line.text),
        ['First original words', 'Original refrain'],
      );
      expect(_sliderSectionLabels(tester), labelsBefore);
      expect([
        for (final marker in ui.state.playerSections)
          (marker.name, marker.lineId, marker.startSeconds),
      ], markersBefore);
      expect([
        for (final line in ui.state.songLines)
          (line.id, line.text, line.section),
      ], linesBefore);
      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('player-seek-slider')),
      );
      slider.onChanged!(72);
      await tester.pumpAndSettle();
      expect(ui.playerPosition.value.seconds, 72);
      expect(
        ui.playerPosition.value.currentLineId,
        ui.state.playerSections.last.lineId,
      );
      final stored = await tester.runAsync(
        () => repository.getSong('original-player'),
      );
      expect(stored!.body, _body);
      expect(stored.timingTracks.single.toJson(), trackBefore);
      expect(stored.activeTimingTrackId, 'original-track');
      expect(tester.takeException(), isNull);
    },
  );

  for (final scenario in [
    ('portrait', const Size(390, 844)),
    ('compact landscape', const Size(900, 400)),
  ]) {
    testWidgets('tap and swipe collapse/restore controls in ${scenario.$1}', (
      tester,
    ) async {
      await openFixture(tester);
      await _pumpPlayer(tester, ui, awake, size: scenario.$2);
      final l10n = l10nOf(tester);
      final lyrics = find.byKey(const ValueKey('tablet-reader-content'));
      final expandedSize = tester.getSize(lyrics);
      if (scenario.$1 == 'compact landscape') {
        final header = tester.getRect(
          find.byKey(const ValueKey('player-landscape-header')),
        );
        expect(tester.getRect(lyrics).top, greaterThanOrEqualTo(header.bottom));
        expect(
          expandedSize.height,
          closeTo(scenario.$2.height - header.bottom, .1),
        );
        expect(find.text('Original panel fixture'), findsOneWidget);
        expect(
          tester.getRect(find.text('Original panel fixture')).bottom,
          lessThanOrEqualTo(tester.getRect(lyrics).top),
        );
      }
      final hide = find.byTooltip(l10n.playerCollapseControls);
      expect(tester.getSize(hide).height, greaterThanOrEqualTo(48));
      await tester.tap(hide);
      await flush(tester);

      expect(ui.state.playerControlsExpanded, isFalse);
      expect(find.byKey(const ValueKey('player-seek-slider')), findsNothing);
      final restore = find.byTooltip(l10n.playerExpandControls);
      expect(restore, findsOneWidget);
      expect(tester.getSize(restore).height, greaterThanOrEqualTo(48));
      final collapsedSize = tester.getSize(lyrics);
      if (scenario.$1 == 'portrait') {
        expect(collapsedSize.height, greaterThan(expandedSize.height));
      } else {
        expect(collapsedSize.width, greaterThan(expandedSize.width));
        expect(collapsedSize.height, closeTo(expandedSize.height, .1));
      }
      expect(
        tester.getRect(restore).bottom,
        lessThanOrEqualTo(scenario.$2.height),
      );

      await tester.drag(
        restore,
        scenario.$1 == 'portrait' ? const Offset(0, -80) : const Offset(-80, 0),
      );
      await flush(tester);
      expect(ui.state.playerControlsExpanded, isTrue);
      expect(find.byKey(const ValueKey('player-seek-slider')), findsOneWidget);

      await tester.drag(
        find.byTooltip(l10n.playerCollapseControls),
        scenario.$1 == 'portrait' ? const Offset(0, 80) : const Offset(80, 0),
      );
      await flush(tester);
      expect(ui.state.playerControlsExpanded, isFalse);
      final saved =
          await tester.runAsync(() => repository.getSetting('app')) as Map;
      expect(saved['playerControlsExpanded'], isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('collapsed choice survives a fresh controller and song opening', (
    tester,
  ) async {
    await openFixture(tester);
    await _pumpPlayer(tester, ui, awake);
    await tester.tap(find.byTooltip(l10nOf(tester).playerCollapseControls));
    await flush(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      ui.dispose();
      app.dispose();
      await start();
      await ui.openSong('original-player');
    });
    await _pumpPlayer(tester, ui, awake);
    expect(ui.state.playerControlsExpanded, isFalse);
    expect(find.byTooltip(l10nOf(tester).playerExpandControls), findsOneWidget);
    expect(find.byKey(const ValueKey('player-seek-slider')), findsNothing);
    await tester.tap(find.byTooltip(l10nOf(tester).playerExpandControls));
    await flush(tester);
    expect(ui.state.playerControlsExpanded, isTrue);
    expect(find.byKey(const ValueKey('player-seek-slider')), findsOneWidget);
  });

  testWidgets(
    'collapsing preserves running playback and its timing preferences',
    (tester) async {
      await openFixture(tester);
      await tester.runAsync(() => ui.setPlaybackSpeed(1.25));
      await _pumpPlayer(tester, ui, awake);
      await tester.tap(find.byKey(const ValueKey('start-lyric-scroll')));
      await tester.pump();
      expect(ui.state.isPlaying, isTrue);
      await tester.tap(find.byTooltip(l10nOf(tester).playerCollapseControls));
      await flush(tester);
      expect(ui.state.playerControlsExpanded, isFalse);
      expect(ui.state.isPlaying, isTrue);
      expect(ui.state.autoscroll, isTrue);
      expect(ui.state.timingMode, 'timed');
      expect(ui.state.playbackSpeed, 1.25);
      expect(awake.disables, 0);
      await tester.runAsync(ui.playPause);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'transpose popup has no visibility action and preserves hidden chords',
    (tester) async {
      await openFixture(tester);
      await tester.runAsync(() => ui.setShowChords(false));
      await _pumpPlayer(tester, ui, awake);
      final dropdown = find.byKey(const ValueKey('pitch-key-dropdown'));
      final menu = tester.widget<PopupMenuButton<String>>(dropdown);
      final values = menu
          .itemBuilder(tester.element(dropdown))
          .whereType<PopupMenuItem<String>>()
          .map((item) => item.value);
      expect(values, isNot(contains('no-chords')));
      expect(
        tester
            .widgetList<ChordLyricsLine>(find.byType(ChordLyricsLine))
            .every((line) => !line.showChords),
        isTrue,
      );

      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('transpose-pitch-2')));
      await tester.runAsync(ui.settlePlayerPreferences);
      await tester.pumpAndSettle();
      expect(ui.state.readerTranspose, 2);
      expect(ui.state.showChords, isFalse);
      expect(
        tester
            .widgetList<ChordLyricsLine>(find.byType(ChordLyricsLine))
            .every((line) => !line.showChords),
        isTrue,
      );
    },
  );

  testWidgets(
    'Settings Player exposes independent persisted chord and heading switches',
    (tester) async {
      ui.setTab(VerseTab.settings);
      await pumpShell(tester, ui);
      final l10n = l10nOf(tester);
      await tester.tap(find.byKey(const ValueKey('settings-menu-player')));
      await tester.pumpAndSettle();
      final chords = find.widgetWithText(
        SwitchListTile,
        l10n.editorChordsField,
      );
      final sections = find.widgetWithText(
        SwitchListTile,
        l10n.settingsPlayerSections,
      );
      expect(chords, findsOneWidget);
      expect(sections, findsOneWidget);

      await tester.ensureVisible(chords);
      await tester.tap(chords);
      await flush(tester);
      expect(ui.state.showChords, isFalse);
      expect(ui.state.showSections, isTrue);
      await tester.ensureVisible(sections);
      await tester.tap(sections);
      await flush(tester);
      expect(ui.state.showChords, isFalse);
      expect(ui.state.showSections, isFalse);
      final stored =
          await tester.runAsync(() => repository.getSetting('app')) as Map;
      expect(stored['showChords'], isFalse);
      expect(stored['showSections'], isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
