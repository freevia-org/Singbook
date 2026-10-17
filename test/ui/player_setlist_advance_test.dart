import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late AppController app;
  late AppControllerAdapter controller;

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(repository: repository);
    await app.initialize();
    controller = AppControllerAdapter(app);
    await app.saveSong(
      SongDocument(
        id: 'song',
        title: 'Lanterns at Dawn',
        artist: 'Mira Vale',
        body: '[C]First line\n[G]Second line',
        metadata: const {'key': 'C', 'durationSeconds': 240},
      ),
    );
    await app.saveSetlist(
      SetlistDocument(
        id: 'setlist',
        name: 'Repeated song',
        entries: const [
          SetlistEntry(id: 'd-entry', songId: 'song', overrides: {'key': 'D'}),
          SetlistEntry(id: 'base-entry', songId: 'song'),
        ],
      ),
    );
    await controller.openSetlistEntry('setlist', 'd-entry');
  });

  tearDown(() async {
    controller.dispose();
    app.dispose();
    await repository.close();
  });

  testWidgets('an enabled tooltip button receives a long-press action', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: IconButton(
              tooltip: 'Next',
              onPressed: () {},
              onLongPress: () => presses++,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(IconButton));
    await _settle(tester, controller);
    expect(presses, 1);
  });

  testWidgets(
    'player expands fine speed controls and displays adjusted duration',
    (tester) async {
      await pumpShell(tester, controller);

      expect(find.text('Play'), findsOneWidget);
      expect(find.byKey(const ValueKey('scroll-speed-slider')), findsNothing);
      expect(find.text(l10nOf(tester).playerLyricsOnly), findsNothing);
      await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
      await _settle(tester, controller);
      final speedSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('scroll-speed-slider')),
      );
      expect(speedSlider.divisions, 15);
      expect(speedSlider.min, .5);
      expect(speedSlider.max, 2);
      expect(find.text('4:00'), findsOneWidget);

      speedSlider.onChanged!(.55);
      await tester.pump();
      expect(controller.state.playbackSpeed, .55);
      expect(find.text('7:16'), findsOneWidget);

      await controller.setPlaybackSpeed(1.5);
      await tester.pump();
      expect(controller.state.playbackSpeed, 1.5);
      expect(find.text('2:40'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await _settle(tester, controller);
      expect(find.byKey(const ValueKey('scroll-speed-slider')), findsNothing);
    },
  );

  testWidgets('pitch menu highlights the song key and can restore it', (
    tester,
  ) async {
    await pumpShell(tester, controller);
    expect(controller.state.readerKey, 'D');
    expect(find.byTooltip(l10nOf(tester).readerTranspose), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pitch-key-dropdown')));
    await _settle(tester, controller);
    final originalKey = find.text('C  ★');
    expect(originalKey, findsOneWidget);
    final originalItem = tester.widget<Text>(originalKey);
    expect(originalItem.style?.fontWeight, FontWeight.w700);

    await tester.tap(originalKey);
    await _settle(tester, controller);
    expect(controller.state.readerKey, 'C');
  });

  testWidgets('None is reversible and has no checkbox in the key menu', (
    tester,
  ) async {
    await pumpShell(tester, controller);
    final keyMenu = find.byKey(const ValueKey('pitch-key-dropdown'));
    final none = l10nOf(tester).playerChordsNone;
    expect(find.byType(Checkbox), findsNothing);
    expect(controller.state.showChords, isTrue);
    await tester.tap(keyMenu);
    await _settle(tester, controller);
    expect(find.byType(CheckedPopupMenuItem<String>), findsNothing);
    final noneOption = find.text(none);
    expect(
      tester.getSemantics(noneOption).flagsCollection.isSelected.toBoolOrNull(),
      isFalse,
    );
    await tester.tap(noneOption);
    await tester.runAsync(() => repository.getSetting('app'));
    await _settle(tester, controller);
    expect(controller.state.showChords, isFalse);
    expect(controller.state.readerKey, 'D');
    await tester.tap(keyMenu);
    await _settle(tester, controller);
    expect(find.byType(CheckedPopupMenuItem<String>), findsNothing);
    final selectedNone = find.text(none);
    expect(
      tester
          .getSemantics(selectedNone)
          .flagsCollection
          .isSelected
          .toBoolOrNull(),
      isTrue,
    );
    await tester.tap(selectedNone);
    await tester.runAsync(() => repository.getSetting('app'));
    await _settle(tester, controller);
    expect(controller.state.showChords, isTrue);
  });

  testWidgets('unknown key keeps semitone transpose controls available', (
    tester,
  ) async {
    await tester.runAsync(
      () => app.saveSong(
        SongDocument(
          id: 'song',
          title: 'Lanterns at Dawn',
          artist: 'Mira Vale',
          body: '[C]First line\n[G]Second line',
          metadata: const {'key': 'H', 'durationSeconds': 240},
        ),
      ),
    );
    await tester.runAsync(() => controller.openSong('song'));
    await pumpShell(tester, controller);

    expect(find.byKey(const ValueKey('pitch-key-dropdown')), findsOneWidget);
    final l10n = l10nOf(tester);
    final down = find.byTooltip(l10n.readerTransposeSemitones(-1));
    expect(down, findsOneWidget);
    await tester.tap(down);
    await tester.runAsync(controller.settlePlayerPreferences);
    await tester.pump();
    expect(controller.state.songLines.first.chords.single.symbol, 'B');
  });

  testWidgets('pitch dropdown handles lowercase minor and major key names', (
    tester,
  ) async {
    Future<void> setKey(String key) async {
      await tester.runAsync(
        () => app.saveSong(
          SongDocument(
            id: 'song',
            title: 'Lanterns at Dawn',
            artist: 'Mira Vale',
            body: '[C]First line\n[G]Second line',
            metadata: {'key': key, 'durationSeconds': 240},
          ),
        ),
      );
      await tester.runAsync(() => controller.openSong('song'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
    }

    await setKey('cmin');
    await pumpShell(tester, controller);
    await tester.tap(find.byKey(const ValueKey('pitch-key-dropdown')));
    await _settle(tester, controller);
    expect(find.text('cmin  ★'), findsOneWidget);
    expect(find.text('D♯m'), findsOneWidget);
    await tester.tap(find.text('D♯m'));
    await _settle(tester, controller);
    expect(controller.state.readerKey, 'D#min');

    await setKey('cmin');
    await tester.tap(find.byKey(const ValueKey('pitch-key-dropdown')));
    await _settle(tester, controller);
    await tester.tap(find.text('cmin  ★'));
    await _settle(tester, controller);

    await setKey('Cmaj');
    await tester.tap(find.byKey(const ValueKey('pitch-key-dropdown')));
    await _settle(tester, controller);
    expect(find.text('Cmaj  ★'), findsOneWidget);
    expect(find.text('D♯'), findsOneWidget);
    expect(find.text('D♯m'), findsNothing);
    await tester.tap(find.text('Cmaj  ★'));
    await _settle(tester, controller);

    await setKey('Cdim');
    await tester.tap(find.byKey(const ValueKey('pitch-key-dropdown')));
    await _settle(tester, controller);
    expect(find.text('Cdim  ★'), findsOneWidget);
    expect(find.text('D♯'), findsOneWidget);
    expect(find.text('D♯m'), findsNothing);
    await tester.tap(find.text('Cdim  ★'));
    await _settle(tester, controller);

    await setKey('CM');
    await tester.tap(find.byKey(const ValueKey('pitch-key-dropdown')));
    await _settle(tester, controller);
    expect(find.text('CM  ★'), findsOneWidget);
    expect(find.text('D♯'), findsOneWidget);
    expect(find.text('D♯m'), findsNothing);
  });

  testWidgets('compact scaled player keeps side controls in one row', (
    tester,
  ) async {
    await pumpShell(
      tester,
      controller,
      size: const Size(320, 700),
      textScale: 1.5,
    );

    expect(find.byKey(const ValueKey('start-lyric-scroll')), findsOneWidget);
    expect(find.byTooltip(l10nOf(tester).playerPreviousSong), findsOneWidget);
    expect(find.byTooltip(l10nOf(tester).playerNextSong), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap navigates songs when the setlist song has no sections', (
    tester,
  ) async {
    await pumpShell(tester, controller);
    final l10n = l10nOf(tester);
    final nextButton = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == l10n.playerNextSong,
    );
    final previousButton = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton && widget.tooltip == l10n.playerPreviousSong,
    );

    expect(controller.activeSetlistEntry?.id, 'd-entry');
    expect(controller.state.readerKey, 'D');
    expect(controller.state.playerSections, isEmpty);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pitch-key-dropdown')),
        matching: find.text('D'),
      ),
      findsOneWidget,
    );
    expect(nextButton, findsOneWidget);
    expect(previousButton, findsOneWidget);
    expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);
    expect(tester.widget<IconButton>(nextButton).onLongPress, isNotNull);

    await _advance(tester, controller, nextButton);
    await _pumpPlayer(tester);
    expect(controller.activeSetlistEntry?.id, 'base-entry');
    expect(controller.state.readerKey, 'C');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pitch-key-dropdown')),
        matching: find.text('C'),
      ),
      findsOneWidget,
    );

    await _advance(tester, controller, previousButton);
    await _pumpPlayer(tester);
    expect(controller.activeSetlistEntry?.id, 'd-entry');
    expect(controller.state.readerKey, 'D');
  });

  testWidgets(
    'long-press still advances songs when the setlist has no sections',
    (tester) async {
      await pumpShell(tester, controller);
      final l10n = l10nOf(tester);
      final nextButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton && widget.tooltip == l10n.playerNextSong,
      );

      await _advance(tester, controller, nextButton, longPress: true);
      await _pumpPlayer(tester);

      expect(
        controller.activeSetlistEntry?.id,
        'base-entry',
        reason: 'The long-press action must advance by entry identity.',
      );
      expect(controller.state.readerKey, 'C');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pitch-key-dropdown')),
          matching: find.text('C'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'section tap skips a section while long-press advances the song',
    (tester) async {
      await tester.runAsync(
        () => app.saveSong(
          SongDocument(
            id: 'song',
            title: 'Lanterns at Dawn',
            artist: 'Mira Vale',
            body: '[Verse]\n[C]First line\n[Chorus]\n[G]Second line',
            metadata: const {'key': 'C', 'durationSeconds': 120},
          ),
        ),
      );
      await pumpShell(tester, controller);
      final l10n = l10nOf(tester);
      final nextButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip == l10n.playerNextSectionSong,
      );

      expect(controller.state.playerSections, hasLength(2));
      await _advance(tester, controller, nextButton);
      await _pumpPlayer(tester);
      expect(controller.activeSetlistEntry?.id, 'd-entry');
      expect(controller.state.readerKey, 'D');
      expect(controller.state.progressSeconds, greaterThan(0));

      await _advance(tester, controller, nextButton, longPress: true);
      await _pumpPlayer(tester);
      expect(controller.activeSetlistEntry?.id, 'base-entry');
      expect(controller.state.readerKey, 'C');
    },
  );

  testWidgets('non-setlist section controls are hidden without sections', (
    tester,
  ) async {
    await tester.runAsync(() => controller.openSong('song'));
    await pumpShell(tester, controller);
    final l10n = l10nOf(tester);
    final previousButton = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton && widget.tooltip == l10n.playerPreviousSection,
    );
    final nextButton = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton && widget.tooltip == l10n.playerNextSection,
    );

    expect(controller.state.playerSections, isEmpty);
    for (final button in [previousButton, nextButton]) {
      expect(button, findsNothing);
    }
  });

  testWidgets('adapter nextSong reaches the same repeated base-key entry', (
    tester,
  ) async {
    await pumpShell(tester, controller);

    expect(controller.activeSetlistEntry?.id, 'd-entry');
    expect(controller.state.readerKey, 'D');
    await tester.runAsync(() async {
      await controller.nextSong();
      await controller.settleRecentRecords();
    });
    await _pumpPlayer(tester);

    expect(controller.activeSetlistEntry?.id, 'base-entry');
    expect(controller.state.readerKey, 'C');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pitch-key-dropdown')),
        matching: find.text('C'),
      ),
      findsOneWidget,
    );
  });

  test(
    'recognized section directives become reader and player section names',
    () async {
      const rawBody =
          '{comment: Verse 1}\n[C]First line\n{comment: Pre-Chorus}\n[G]Second line\n'
          '{comment: Chorus should be sung softly}\n{tempo: 96}';
      await app.saveSong(
        SongDocument(
          id: 'song',
          title: 'Lanterns at Dawn',
          artist: 'Mira Vale',
          body: rawBody,
          metadata: const {'key': 'C', 'durationSeconds': 120},
        ),
      );
      await controller.openSetlistEntry('setlist', 'd-entry');

      final state = controller.state;
      expect(state.songLines.map((line) => line.section).whereType<String>(), [
        'Verse 1',
        'Pre-Chorus',
      ]);
      expect(state.playerSections.map((section) => section.name), [
        'Verse 1',
        'Pre-Chorus',
      ]);
      expect(
        state.songLines.where((line) => line.id.startsWith('directive-')),
        hasLength(2),
      );
      expect(
        state.songLines
            .map((line) => line.id)
            .where((id) => id.startsWith('line-')),
        ['line-0', 'line-1'],
      );
      expect(app.findSong('song')!.body, rawBody);
    },
  );

  test(
    'new song resets prior progress while existing song edits preserve it',
    () async {
      await controller.openSong('song');
      await controller.seek(111);
      expect(controller.state.progressSeconds, 111);
      await controller.transpose(2);
      expect(controller.state.readerKey, 'D');

      await controller.createSong();
      expect(controller.state.route, VerseRoute.editor);
      expect(controller.state.progressSeconds, 0);
      await controller.saveLyricsEdit(
        '{title: New Song}\n{artist: Mira Vale}\n{key: C}\n{duration: 90}\n'
        '[C]New first line\n[G]New second line',
      );
      expect(controller.state.route, VerseRoute.reader);
      expect(controller.state.song!.title, 'New Song');
      expect(controller.state.progressSeconds, 0);
      expect(controller.state.readerKey, 'C');

      await controller.openSong('song');
      await controller.seek(111);
      await controller.editSong('song');
      await controller.saveLyricsEdit(
        controller.editableChordPro.replaceFirst(
          'First line',
          'Edited first line',
        ),
      );
      expect(controller.state.progressSeconds, 111);
    },
  );
}

Future<void> _pumpPlayer(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

/// Presses a player button. Next/Previous record the opened song in Recent
/// with a real database call; it must finish in `runAsync` or its lock-warning
/// timer would outlive the test.
Future<void> _advance(
  WidgetTester tester,
  AppControllerAdapter controller,
  Finder button, {
  bool longPress = false,
}) async {
  if (longPress) {
    await tester.longPress(button);
  } else {
    await tester.tap(button);
  }
  await tester.runAsync(controller.settleRecentRecords);
}

// SQLite work needs the real async zone; flush the new debounce before stepping
// the widget clock so a simulated timer cannot strand an in-flight DB future.
Future<void> _settle(
  WidgetTester tester,
  AppControllerAdapter controller,
) async {
  await tester.runAsync(controller.settlePlayerPreferences);
  await tester.pumpAndSettle();
}
