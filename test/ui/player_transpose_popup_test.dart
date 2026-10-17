import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

import 'support/fake_controller.dart';

import '../../integration_test/support/transpose_popup_fixtures.dart';

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
  });

  tearDown(() async {
    await controller.settlePlayerPreferences();
    controller.dispose();
    app.dispose();
    await repository.close();
  });

  for (final fixture in transposePopupFixtures) {
    testWidgets('popup transposes, persists and restores ${fixture.name}', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await app.saveSong(
          SongDocument(
            id: 'song',
            title: fixture.name,
            artist: 'Original regression fixture',
            body: fixture.body,
            metadata: {if (fixture.key != null) 'key': fixture.key!},
          ),
        );
        await controller.openSong('song');
      });
      await pumpShell(tester, controller);
      final originalChords = _chords(controller.state);
      final originalAnchors = _anchors(controller.state);
      final dropdown = find.byKey(const ValueKey('pitch-key-dropdown'));
      final play = find.byKey(const ValueKey('start-lyric-scroll'));
      expect(
        tester.getRect(dropdown).right,
        lessThanOrEqualTo(tester.getRect(play).left),
      );
      expect(
        tester.getCenter(dropdown).dy,
        closeTo(tester.getCenter(play).dy, 1),
      );

      await _choose(
        tester,
        controller,
        fixture.pitch == null
            ? 'transpose-offset-2'
            : 'transpose-pitch-${(fixture.pitch! + 2) % 12}',
      );
      expect(_chords(controller.state), fixture.shifted);
      expect(_anchors(controller.state), originalAnchors);
      expect(controller.state.readerKey, fixture.shiftedKey);
      expect(controller.state.readerTranspose, 2);
      expect(
        VerseUiState.withPosition(controller.state, 1, null).readerTranspose,
        2,
      );
      final paintedChords = tester
          .widgetList<ChordLyricsLine>(find.byType(ChordLyricsLine))
          .expand((line) => line.chords)
          .map((chord) => chord.symbol)
          .toList();
      expect(paintedChords, fixture.shifted);

      final saved = await tester.runAsync(() => repository.getSong('song'));
      expect(saved!.body, fixture.body);
      expect(saved.metadata['key'], fixture.key);
      expect(saved.metadata['x_verse_player_transpose'], 2);
      await tester.runAsync(() => controller.openSong('song'));
      await tester.pumpAndSettle();
      expect(_chords(controller.state), fixture.shifted);
      expect(controller.state.readerTranspose, 2);
      if (fixture.pitch == null) {
        expect(
          find.descendant(of: dropdown, matching: find.text('+2')),
          findsOneWidget,
        );
      }

      await _choose(
        tester,
        controller,
        fixture.pitch == null
            ? 'transpose-offset--1'
            : 'transpose-pitch-${(fixture.pitch! + 11) % 12}',
      );
      expect(_chords(controller.state), fixture.down);
      expect(_anchors(controller.state), originalAnchors);
      expect(controller.state.readerTranspose, -1);

      // None hides chords; choosing a real transposition restores them, even
      // when choosing zero requires no additional shift.
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      final none = find.text(l10nOf(tester).playerChordsNone);
      await tester.ensureVisible(none);
      await tester.tap(none);
      await _settle(tester, controller);
      expect(controller.state.showChords, isFalse);
      await _choose(
        tester,
        controller,
        fixture.pitch == null
            ? 'transpose-offset-0'
            : 'transpose-pitch-${fixture.pitch}',
      );
      expect(controller.state.showChords, isTrue);
      expect(_chords(controller.state), originalChords);
      expect(controller.state.readerTranspose, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lyrics without chords have no transpose control', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await app.saveSong(
        SongDocument(
          id: 'plain',
          title: 'Plain lyrics',
          artist: 'Original regression fixture',
          body: 'An original line',
        ),
      );
      await controller.openSong('plain');
    });
    await pumpShell(tester, controller);
    expect(find.byKey(const ValueKey('pitch-key-dropdown')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

List<String> _chords(VerseUiState state) => state.songLines
    .expand((line) => line.chords)
    .map((chord) => chord.symbol)
    .toList();

List<int> _anchors(VerseUiState state) => state.songLines
    .expand((line) => line.chords)
    .map((chord) => chord.graphemeOffset)
    .toList();

Future<void> _choose(
  WidgetTester tester,
  AppControllerAdapter controller,
  String key,
) async {
  await tester.tap(find.byKey(const ValueKey('pitch-key-dropdown')));
  await tester.pumpAndSettle();
  final item = find.byKey(ValueKey(key));
  await tester.ensureVisible(item);
  await tester.tap(item);
  await _settle(tester, controller);
}

Future<void> _settle(
  WidgetTester tester,
  AppControllerAdapter controller,
) async {
  // Keep real SQLite futures outside the widget clock, including the
  // asynchronous show-chords preference written before transposition.
  await tester.runAsync(() async {
    await repositoryBarrier(controller);
    await controller.settlePlayerPreferences();
  });
  await tester.pumpAndSettle();
}

Future<void> repositoryBarrier(AppControllerAdapter controller) async {
  await controller.app.repository.getSetting('app');
}
