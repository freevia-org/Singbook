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
      expect(originalChords, fixture.original);
      final inferredPitch = _pitchClass(controller.state.readerKey);
      if (fixture.key == null) {
        expect(controller.state.readerKeyEstimated, fixture.shiftedKey != null);
        final original = await tester.runAsync(
          () => repository.getSong('song'),
        );
        expect(original!.metadata.containsKey('key'), isFalse);
      }
      final originalAnchors = _anchors(controller.state);
      final dropdown = find.byKey(const ValueKey('pitch-key-dropdown'));
      if (inferredPitch != null) {
        expect(
          find.descendant(
            of: dropdown,
            matching: find.text(controller.state.readerKey!),
          ),
          findsOneWidget,
        );
      }
      final menu = tester.widget<PopupMenuButton<String>>(dropdown);
      expect(
        menu
            .itemBuilder(tester.element(dropdown))
            .whereType<PopupMenuItem<String>>()
            .map((item) => item.value),
        inferredPitch == null
            ? ['edit-key']
            : [for (var pitch = 0; pitch < 12; pitch++) 'pitch-$pitch'],
      );
      if (inferredPitch == null) {
        expect(controller.state.readerKeyEstimated, isFalse);
        expect(menu.initialValue, isNull);
        return;
      }
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
        'transpose-pitch-${(inferredPitch + 2) % 12}',
      );
      expect(_chords(controller.state), fixture.shifted);
      expect(_anchors(controller.state), originalAnchors);
      expect(controller.state.readerKey, fixture.shiftedKey);
      expect(
        controller.state.readerKeyEstimated,
        fixture.key == null && fixture.shiftedKey != null,
      );
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
      if (fixture.key == null) {
        final savedAfterRestore = await tester.runAsync(
          () => repository.getSong('song'),
        );
        expect(savedAfterRestore!.metadata.containsKey('key'), isFalse);
      }

      await _choose(
        tester,
        controller,
        'transpose-pitch-${(inferredPitch + 11) % 12}',
      );
      expect(_chords(controller.state), fixture.down);
      expect(_anchors(controller.state), originalAnchors);
      expect(controller.state.readerTranspose, -1);

      expect(controller.state.showChords, isTrue);
      expect(_chords(controller.state), fixture.down);
      expect(controller.state.readerTranspose, -1);
      await _choose(tester, controller, 'transpose-pitch-$inferredPitch');
      expect(controller.state.showChords, isTrue);
      expect(_chords(controller.state), originalChords);
      expect(controller.state.readerTranspose, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final savedOffset in [-25, -18, -12, -7, -6, 6, 7, 12, 18, 25]) {
    testWidgets(
      'saved offset $savedOffset fits menu without rewriting transpose',
      (tester) async {
        const body = '[C]Morning [G/B]road\n[Am7]Homeward [Fmaj7]again';
        await tester.runAsync(() async {
          await app.saveSong(
            SongDocument(
              id: 'legacy',
              title: 'Saved transposition',
              artist: 'Original regression fixture',
              body: body,
              metadata: {'key': 'C', 'x_verse_player_transpose': savedOffset},
            ),
          );
          await controller.openSong('legacy');
        });
        await pumpShell(tester, controller);
        final originalChords = _chords(controller.state);
        final dropdown = find.byKey(const ValueKey('pitch-key-dropdown'));
        final menu = tester.widget<PopupMenuButton<String>>(dropdown);
        final currentPitch = _pitchClass(controller.state.readerKey)!;
        final originalPitch = (currentPitch - savedOffset % 12 + 12) % 12;
        expect(menu.initialValue, 'pitch-$currentPitch');
        expect(
          menu
              .itemBuilder(tester.element(dropdown))
              .whereType<PopupMenuItem<String>>()
              .map((item) => item.value),
          [for (var pitch = 0; pitch < 12; pitch++) 'pitch-$pitch'],
        );
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(ValueKey('transpose-pitch-$currentPitch')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.selected == true,
            ),
          ),
          findsOneWidget,
        );
        final unchanged = await tester.runAsync(
          () => repository.getSong('legacy'),
        );
        expect(unchanged!.metadata['x_verse_player_transpose'], savedOffset);
        expect(unchanged.metadata['key'], 'C');
        expect(unchanged.body, body);
        expect(controller.state.readerTranspose, savedOffset);
        expect(_chords(controller.state), originalChords);
        await tester.tap(find.byKey(ValueKey('transpose-pitch-$currentPitch')));
        await _settle(tester, controller);
        expect(controller.state.readerTranspose, savedOffset);
        expect(
          (await tester.runAsync(
            () => repository.getSong('legacy'),
          ))!.metadata['x_verse_player_transpose'],
          savedOffset,
        );
        await tester.tap(dropdown);
        await tester.pumpAndSettle();

        final targetTwo = (originalPitch + 2) % 12;
        var delta = (targetTwo - currentPitch + 12) % 12;
        if (delta > 6) delta -= 12;
        final changedOffset = savedOffset + delta;
        await tester.tap(find.byKey(ValueKey('transpose-pitch-$targetTwo')));
        await _settle(tester, controller);
        expect(controller.state.readerTranspose, changedOffset);
        expect(_chords(controller.state), ['D', 'A/C#', 'Bm7', 'Gmaj7']);
        final changed = await tester.runAsync(
          () => repository.getSong('legacy'),
        );
        expect(changed!.metadata['x_verse_player_transpose'], changedOffset);
        expect(changed.body, body);
        await tester.runAsync(() => controller.openSong('legacy'));
        await tester.pumpAndSettle();
        expect(controller.state.readerTranspose, changedOffset);
        await _choose(tester, controller, 'transpose-pitch-$originalPitch');
        expect(controller.state.readerTranspose, 0);
        expect(_chords(controller.state), ['C', 'G/B', 'Am7', 'Fmaj7']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('tritone note choice transposes and persists', (tester) async {
    await tester.runAsync(() async {
      await app.saveSong(
        SongDocument(
          id: 'endpoints',
          title: 'Transpose endpoints',
          artist: 'Original regression fixture',
          body: '[C]Morning [G/B]road\n[Am7]Homeward [Fmaj7]again',
          metadata: const {'key': 'C'},
        ),
      );
      await controller.openSong('endpoints');
    });
    await pumpShell(tester, controller);
    final pitch = _pitchClass(controller.state.readerKey)!;
    await _choose(tester, controller, 'transpose-pitch-${(pitch + 6) % 12}');
    expect(controller.state.readerTranspose.abs(), 6);
    expect(_chords(controller.state), ['F#', 'C#/F', 'D#m7', 'Bmaj7']);
    final saved = await tester.runAsync(() => repository.getSong('endpoints'));
    expect(saved!.metadata['x_verse_player_transpose'], 6);
    await _choose(tester, controller, 'transpose-pitch-$pitch');
    expect(controller.state.readerTranspose, 0);
    expect(_chords(controller.state), ['C', 'G/B', 'Am7', 'Fmaj7']);
    expect(tester.takeException(), isNull);
  });

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

int? _pitchClass(String? key) {
  if (key == null) return null;
  final match = RegExp(r'^\s*([A-Ga-g])([#b♯♭]?)').firstMatch(key);
  if (match == null) return null;
  final natural = const {
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  }[match.group(1)!.toUpperCase()]!;
  final accidental = match.group(2);
  return (natural +
          (accidental == '#' || accidental == '♯'
              ? 1
              : accidental == 'b' || accidental == '♭'
              ? -1
              : 0) +
          12) %
      12;
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
