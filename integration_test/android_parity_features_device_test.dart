// Native iOS coverage for the recent Android parity features. All data is
// original fixture content in a temporary SQLite library; no network is used.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart' show deleteDatabase, getDatabasesPath;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/format.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/settings/settings_screen.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

import 'support/ios_screenshots.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'unified Songs modes, startup preference, and Settings routes',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_ios_parity_modes_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
      AppController? app;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        app?.dispose();
        await tester.runAsync(() async {
          await repository.close();
          await deleteDatabase(databasePath);
        });
      });
      await repository.saveSong(_fixtureSong());
      app = _newController(repository);
      await app.initialize();
      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );

      await tester.tap(find.byKey(const ValueKey('home-mode-library')));
      await tester.pumpAndSettle();
      expect(find.text('Original Lantern Song'), findsOneWidget);
      await captureIosCheckpoint('parity_library_mode');
      await tester.tap(find.byKey(const ValueKey('home-mode-favorites')));
      await tester.pumpAndSettle();
      expect(find.text('Original Lantern Song'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('home-mode-recent')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.homeRecentEmpty), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-mode-online')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.searchCatalogEmptyQuery), findsOneWidget);
      expect(find.text(l10n.searchNoResults), findsNothing);

      await tester.tap(find.text(l10n.navSettings).first);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      final startup = find.byType(DropdownButton<String>).first;
      await tester.tap(startup);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.songsLibraryView).last);
      await tester.pumpAndSettle();
      await _waitFor(
        tester,
        () => app!.settings['startupSongsView'] == 'library',
      );

      for (final section in ['appearance', 'player', 'sources', 'about']) {
        final menu = find.byKey(ValueKey('settings-menu-$section'));
        await tester.ensureVisible(menu);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        expect(find.byType(BackButton), findsOneWidget);
        if (section == 'appearance') {
          final textSize = find.byType(Slider).first;
          await tester.ensureVisible(textSize);
          final originalSize = tester.widget<Slider>(textSize).value;
          await tester.drag(textSize, const Offset(40, 0));
          await tester.pumpAndSettle();
          expect(tester.widget<Slider>(textSize).value, isNot(originalSize));
        }
        if (section == 'player') {
          final showChords = find.widgetWithText(
            SwitchListTile,
            l10n.readerShowChords,
          );
          await tester.ensureVisible(showChords);
          await tester.tap(showChords);
          await tester.pumpAndSettle();
          await _waitFor(tester, () => app!.settings['showChords'] == false);
          await tester.tap(showChords);
          await tester.pumpAndSettle();
          await _waitFor(tester, () => app!.settings['showChords'] == true);
        }
        if (section == 'about') {
          final description = find.text(l10n.aboutDescription);
          await tester.ensureVisible(description);
          expect(description.hitTestable(), findsOneWidget);
        }
        await captureIosCheckpoint('parity_settings_$section');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('settings-menu-$section')), findsOneWidget);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      final restored = _newController(repository);
      app = restored;
      await restored.initialize();
      await tester.pumpWidget(VerseApp(controller: restored));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-mode-library')), findsOneWidget);
      expect(find.text('Original Lantern Song'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 8)),
  );

  testWidgets(
    'reader estimate, section seek, and unified player controls',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_ios_parity_player_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
      AppController? app;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        app?.dispose();
        await tester.runAsync(() async {
          await repository.close();
          await deleteDatabase(databasePath);
        });
      });
      await repository.saveSong(_fixtureSong());
      app = _newController(repository);
      await app.initialize();
      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      await tester.tap(find.byKey(const ValueKey('home-mode-library')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Original Lantern Song'));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(find.textContaining(l10n.playerEstimatedKey), findsOneWidget);
      final player = tester.widget<PlayerScreen>(find.byType(PlayerScreen));
      expect(player.controller.state.readerKeyEstimated, isTrue);
      expect(player.controller.state.readerKey, isNotNull);
      expect(player.controller.state.readerDurationEstimated, isTrue);
      final initialSeek = tester.widget<Slider>(
        find.byKey(const ValueKey('player-seek-slider')),
      );
      expect(initialSeek.max, greaterThan(0));
      expect(
        find.text(
          l10n.playerEstimatedDuration(formatDuration(initialSeek.max)),
        ),
        findsOneWidget,
      );
      await captureIosCheckpoint('parity_reader_estimated_metadata');

      final controlsHandle = find.bySemanticsLabel(l10n.playerCollapseControls);
      expect(controlsHandle, findsOneWidget);
      await tester.tap(controlsHandle);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(l10n.playerExpandControls), findsOneWidget);
      expect(find.byKey(const ValueKey('player-seek-slider')), findsNothing);
      await tester.tap(find.bySemanticsLabel(l10n.playerExpandControls));
      await tester.pumpAndSettle();

      final speedToggle = find.byKey(const ValueKey('scroll-speed-toggle'));
      await tester.tap(speedToggle);
      await tester.pumpAndSettle();
      final speedSlider = find.byKey(const ValueKey('scroll-speed-slider'));
      expect(speedSlider, findsOneWidget);
      await tester.drag(speedSlider, const Offset(45, 0));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerScreen>(find.byType(PlayerScreen))
            .controller
            .state
            .playbackSpeed,
        isNot(1.0),
      );
      await tester.tapAt(const Offset(10, 100));
      await tester.pumpAndSettle();
      expect(speedSlider, findsNothing);
      final seekSlider = find.byKey(const ValueKey('player-seek-slider'));
      await tester.drag(seekSlider, const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerScreen>(find.byType(PlayerScreen))
            .controller
            .playerPosition
            .value
            .seconds,
        greaterThan(0),
      );
      await captureIosCheckpoint('parity_reader_controls_adjusted');

      // The fixture has a named instrumental section so its timeline marker is
      // available for the same seek control used by the native reader.
      final scrollable = find
          .ancestor(
            of: find.byType(ChordLyricsLine).first,
            matching: find.byType(Scrollable),
          )
          .first;
      final instrumental = find.descendant(
        of: scrollable,
        matching: find.text(l10n.sectionInstrumental),
      );
      await tester.scrollUntilVisible(
        instrumental,
        180,
        scrollable: scrollable,
      );
      expect(instrumental, findsOneWidget);
      expect(
        player.controller.state.songLines.any(
          (line) =>
              line.section?.toLowerCase().contains('instrumental') ?? false,
        ),
        isTrue,
      );
      final instrumentalMarker = player.controller.state.playerSections
          .singleWhere(
            (marker) => marker.name.toLowerCase().contains('instrumental'),
          );
      final duration = seekSlider.evaluate().single.widget as Slider;
      final sliderRect = tester.getRect(seekSlider);
      final markerFraction =
          instrumentalMarker.startSeconds /
          (duration.max * player.controller.state.playbackSpeed);
      final sliderTheme = SliderTheme.of(tester.element(seekSlider)).copyWith(
        thumbShape: const RoundSliderThumbShape(),
        overlayShape: const RoundSliderOverlayShape(),
        trackHeight: 4,
      );
      final track = sliderTheme.trackShape!.getPreferredRect(
        parentBox: tester.renderObject<RenderBox>(seekSlider),
        sliderTheme: sliderTheme,
        isEnabled: true,
        isDiscrete: false,
      );
      final markerPosition = Offset(
        sliderRect.left + track.left + track.width * markerFraction + 1,
        sliderRect.top + track.center.dy,
      );
      await tester.tapAt(markerPosition);
      await tester.pumpAndSettle();
      expect(
        player.controller.playerPosition.value.currentLineId,
        instrumentalMarker.lineId,
      );
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 8)),
  );

  testWidgets(
    'setlist inline title and entry ordering; song delete guard',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_ios_parity_library_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
      AppController? app;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        app?.dispose();
        await tester.runAsync(() async {
          await repository.close();
          await deleteDatabase(databasePath);
        });
      });
      await repository.saveSong(_fixtureSong());
      await repository.saveSong(
        SongDocument(
          id: 'original-second-song',
          title: 'Original Second Song',
          artist: 'Original Test Artist',
          body: '[G]Another original lyric line',
        ),
      );
      await repository.saveSetlist(
        SetlistDocument(
          id: 'original-setlist',
          name: 'Original Rehearsal',
          entries: const [
            SetlistEntry(id: 'entry-one', songId: 'original-fixture'),
            SetlistEntry(id: 'entry-two', songId: 'original-second-song'),
          ],
        ),
      );
      app = _newController(repository);
      await app.initialize();
      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      await tester.tap(find.text(l10n.navSetlists).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Original Rehearsal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Original Rehearsal').first);
      await tester.pumpAndSettle();
      final title = find.byKey(const ValueKey('setlist-name-inline-field'));
      expect(title, findsOneWidget);
      await tester.enterText(title, 'Original Rehearsal Updated');
      await tester.tap(find.byTooltip(l10n.actionSave));
      await tester.pumpAndSettle();
      await _waitFor(
        tester,
        () => app!.setlists.single.name == 'Original Rehearsal Updated',
      );
      expect(app.setlists.single.name, 'Original Rehearsal Updated');
      await captureIosCheckpoint('parity_setlist_inline_title_saved');

      final firstEntry = find.byKey(const ValueKey('entry-one'));
      final secondEntry = find.byKey(const ValueKey('entry-two'));
      expect(firstEntry, findsOneWidget);
      expect(secondEntry, findsOneWidget);
      // Exercise the reorder actions exposed to VoiceOver by ReorderableListView.
      final localizations = WidgetsLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      final secondEntryNode = tester.getSemantics(secondEntry);
      final moveUpId = secondEntryNode
          .getSemanticsData()
          .customSemanticsActionIds!
          .singleWhere(
            (id) =>
                CustomSemanticsAction.getAction(id)?.label ==
                localizations.reorderItemUp,
          );
      tester
          .renderObject(secondEntry)
          .owner!
          .semanticsOwner!
          .performAction(
            secondEntryNode.id,
            SemanticsAction.customAction,
            moveUpId,
          );
      await tester.pumpAndSettle();
      await _waitFor(
        tester,
        () =>
            app!.setlists.single.entries.first.songId == 'original-second-song',
      );
      final movedEntryNode = tester.getSemantics(secondEntry);
      final moveDownId = movedEntryNode
          .getSemanticsData()
          .customSemanticsActionIds!
          .singleWhere(
            (id) =>
                CustomSemanticsAction.getAction(id)?.label ==
                localizations.reorderItemDown,
          );
      tester
          .renderObject(secondEntry)
          .owner!
          .semanticsOwner!
          .performAction(
            movedEntryNode.id,
            SemanticsAction.customAction,
            moveDownId,
          );
      await tester.pumpAndSettle();
      await _waitFor(
        tester,
        () => app!.setlists.single.entries.first.songId == 'original-fixture',
      );

      await tester.tap(find.byTooltip(l10n.navBack));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.navSongs).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-mode-library')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Original Lantern Song'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.songMenuLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.actionDelete).last);
      await tester.pumpAndSettle();
      expect(find.text(l10n.songDeleteConfirmTitle), findsOneWidget);
      await tester.tap(find.text(l10n.actionCancel));
      await tester.pumpAndSettle();
      expect(app.findSong('original-fixture'), isNotNull);
      await tester.tap(find.byTooltip(l10n.songMenuLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.actionDelete).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.actionDelete).last);
      await tester.pumpAndSettle();
      await _waitFor(tester, () => app!.findSong('original-fixture') == null);
      expect(app.findSong('original-fixture'), isNull);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

AppController _newController(LibraryRepository repository) => AppController(
  repository: repository,
  discovery: SourceDiscoveryService(const []),
);

SongDocument _fixtureSong() => SongDocument(
  id: 'original-fixture',
  title: 'Original Lantern Song',
  artist: 'Original Test Artist',
  body:
      '{comment: Verse}\n[C]Lanterns mark the winding road\n[G]We carry songs at dawn\n'
      '{comment: Instrumental}\n[C] [G] [Am] [F]\n{comment: Chorus}\n[C]Morning finds us singing',
);

Future<void> _waitFor(WidgetTester tester, bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  expect(condition(), isTrue, reason: 'Expected app state to settle.');
}
