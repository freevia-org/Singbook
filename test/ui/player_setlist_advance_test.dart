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
    await tester.pumpAndSettle();
    expect(presses, 1);
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
    expect(find.textContaining('${l10n.editorKeyField}: D'), findsOneWidget);
    expect(nextButton, findsOneWidget);
    expect(previousButton, findsOneWidget);
    expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);
    expect(tester.widget<IconButton>(nextButton).onLongPress, isNotNull);

    await tester.tap(nextButton);
    await _pumpPlayer(tester);
    expect(controller.activeSetlistEntry?.id, 'base-entry');
    expect(controller.state.readerKey, 'C');
    expect(find.textContaining('${l10n.editorKeyField}: C'), findsOneWidget);

    await tester.tap(previousButton);
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

      await tester.longPress(nextButton);
      await _pumpPlayer(tester);

      expect(
        controller.activeSetlistEntry?.id,
        'base-entry',
        reason: 'The long-press action must advance by entry identity.',
      );
      expect(controller.state.readerKey, 'C');
      expect(find.textContaining('${l10n.editorKeyField}: C'), findsOneWidget);
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
      await tester.tap(nextButton);
      await _pumpPlayer(tester);
      expect(controller.activeSetlistEntry?.id, 'd-entry');
      expect(controller.state.readerKey, 'D');
      expect(controller.state.progressSeconds, greaterThan(0));

      await tester.longPress(nextButton);
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
    final l10n = l10nOf(tester);

    expect(controller.activeSetlistEntry?.id, 'd-entry');
    expect(controller.state.readerKey, 'D');
    await controller.nextSong();
    await _pumpPlayer(tester);

    expect(controller.activeSetlistEntry?.id, 'base-entry');
    expect(controller.state.readerKey, 'C');
    expect(find.textContaining('${l10n.editorKeyField}: C'), findsOneWidget);
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
