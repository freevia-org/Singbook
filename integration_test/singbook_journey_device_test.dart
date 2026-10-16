import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:pdf/pdf.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/domain/timing.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/settings/settings_screen.dart';

const _catalogId = 'journey_catalog';
const _skipScreenshots = bool.fromEnvironment('SINGBOOK_SKIP_SCREENSHOTS');
const _chordSourceId = 'journey_chords';
const _lyricSourceId = 'journey_lyrics';
const _timingOnlySourceId = 'journey_timing_only';
const _unavailableSourceId = 'journey_unavailable';
const _title = 'Lanterns at Dawn';
const _artist = 'The Paper Moons';
const _body =
    '[C]Lanterns guard the quiet road\n[G]We carry sparks into the dawn';
const _plainBody =
    'Lanterns guard the quiet road\nWe carry sparks into the dawn';
const _savedLine = 'The paper moon remembers every song';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native Singbook journey captures populated app screens',
    (tester) async {
      final dbPath = paths.join(
        await getDatabasesPath(),
        'singbook_journey_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: dbPath);
      final fixture = _JourneyFixture();
      final providers = _journeyProviders(fixture);
      final app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(providers),
      );
      await app.initialize();
      await app.setSetting('catalog', _catalogId);

      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();

      // Empty library/search states communicate counts and next actions without
      // repeating a section heading above the empty-state copy.
      _expectHomeModeCount('recent', 0);
      expect(find.text('Recent songs'), findsNothing);
      await _capture(binding, '00_home_recent_empty');
      await tester.tap(_homeMode('online'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a song or artist to search.'), findsOneWidget);
      expect(find.text('No results'), findsNothing);
      await _capture(binding, '01_online_search_idle');
      expect(
        tester
            .widget<VerseHomeScreen>(find.byType(VerseHomeScreen))
            .state
            .searchFilters
            .field,
        'all',
      );

      await _search(tester, _title);
      _expectHomeModeCount('online', 1);
      expect(find.text('Suggestions'), findsNothing);
      await _capture(binding, '02_search_one_result');

      await _search(tester, 'signal song');
      expect(app.query, 'signal song');
      expect(app.suggestions, hasLength(2));
      expect(
        tester
            .widget<VerseHomeScreen>(find.byType(VerseHomeScreen))
            .state
            .searchFilters
            .field,
        'all',
      );
      _expectHomeModeCount('online', 2);
      await _capture(binding, '03_search_two_results');

      await _search(tester, 'signal');
      expect(app.query, 'signal');
      expect(app.suggestions, hasLength(5));
      expect(
        tester
            .widget<VerseHomeScreen>(find.byType(VerseHomeScreen))
            .state
            .searchFilters
            .field,
        'all',
      );
      _expectHomeModeCount('online', 5);
      final lastSignalResult = find.text('Signal Song 5');
      await _scrollIntoView(tester, lastSignalResult);
      expect(lastSignalResult, findsOneWidget);
      await _capture(binding, '04_search_five_results');
      await _search(tester, 'fixtures');
      _expectHomeModeCount('online', 5);
      expect(
        tester
            .widget<VerseHomeScreen>(find.byType(VerseHomeScreen))
            .state
            .searchFilters
            .field,
        'all',
      );
      await _capture(binding, '05_search_catalog_results');

      await _search(tester, 'synthetic missing title');
      final missingTitleMessage = find.text(
        'No songs found. Try a different search.',
      );
      await _scrollIntoView(tester, missingTitleMessage);
      expect(missingTitleMessage, findsOneWidget);
      expect(
        find.text('No songs found. Try a different search.'),
        findsOneWidget,
      );
      await _capture(binding, '07_search_no_results');

      await _search(tester, 'retry');
      expect(find.text('Search could not be completed.'), findsOneWidget);
      expect(find.text('search_failed'), findsNothing);
      final retrySearch = find.text('Try again');
      await _scrollIntoView(tester, retrySearch);
      expect(retrySearch, findsOneWidget);
      await _capture(binding, '08_search_retry_error');
      await tester.tap(retrySearch);
      await tester.pumpAndSettle();
      await _scrollIntoView(tester, _homeMode('online'));
      _expectHomeModeCount('online', 1);
      await _capture(binding, '09_search_retry_success');

      await _focusSearchInput(tester);
      await tester.enterText(find.byType(TextField).first, 'cancel this query');
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'cancel this query',
      );
      await tester.pump();
      _expectVisibleQuery(tester, 'cancel this query');
      for (
        var attempt = 0;
        attempt < 50 && !fixture.cancelSearchStarted.isCompleted;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(fixture.cancelSearchStarted.isCompleted, isTrue);
      expect(app.searching, isTrue);
      final clearSearch = find.byTooltip('Clear search text');
      await tester.tap(clearSearch);
      await tester.pumpAndSettle();
      tester
          .widget<TextField>(find.byType(TextField).first)
          .focusNode
          ?.unfocus();
      await tester.pumpAndSettle();
      final idleSearchMessage = find.text('Enter a song or artist to search.');
      await _scrollIntoView(tester, idleSearchMessage);
      expect(idleSearchMessage, findsOneWidget);
      fixture.cancelSearchRelease.complete();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(idleSearchMessage, findsOneWidget);
      expect(find.text('No results'), findsNothing);
      await _capture(binding, '10_search_cancelled_to_idle');

      // A catalog match can exist without any usable lyric source. The
      // comparison explains that state, shows provider failures, and retries
      // discovery without returning to catalog search.
      await _search(tester, 'quiet harbor');
      _expectHomeModeCount('online', 1);
      await tester.tap(find.text('Quiet Harbor').last);
      await tester.pump();
      expect(find.byKey(const ValueKey('discovery-progress')), findsOneWidget);
      expect(find.textContaining('of 6 complete.'), findsOneWidget);
      await _capture(binding, '11a_discovery_no_lyrics_progress');
      await _awaitDiscovery(tester, app, 'quiet-harbor');
      expect(find.byKey(const ValueKey('discovery-no-lyrics')), findsOneWidget);
      expect(find.text('No usable lyrics found.'), findsOneWidget);
      expect(find.text('Retry lyrics search'), findsOneWidget);
      expect(find.text('6 sources unavailable'), findsOneWidget);
      debugPrint('SINGBOOK_E2E_NO_LYRICS_BEFORE_SOURCE_CHECKS_SCROLL');
      await _ensureBelowPinnedHeader(tester, find.text('Source checks'));
      debugPrint('SINGBOOK_E2E_NO_LYRICS_AFTER_SOURCE_CHECKS_SCROLL');
      await tester.tap(find.text('Source checks'));
      debugPrint('SINGBOOK_E2E_NO_LYRICS_AFTER_SOURCE_CHECKS_TAP');
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 2),
      );
      debugPrint('SINGBOOK_E2E_NO_LYRICS_AFTER_SOURCE_CHECKS_SETTLE');
      expect(find.text('Check failed'), findsOneWidget);
      expect(find.text('No usable lyrics'), findsWidgets);
      await _capture(binding, '11b_discovery_no_usable_lyrics');
      await _ensureBelowPinnedHeader(tester, find.text('Retry lyrics search'));
      await tester.tap(find.text('Retry lyrics search'));
      await tester.pump();
      expect(find.byKey(const ValueKey('discovery-progress')), findsOneWidget);
      await _capture(binding, '11c_discovery_retry_progress');
      await _awaitDiscovery(tester, app, 'lanterns');
      expect(find.byKey(const ValueKey('discovery-no-lyrics')), findsNothing);
      expect(find.text('3 source versions'), findsOneWidget);
      await _capture(binding, '11d_discovery_retry_success');
      await _ensureBelowPinnedHeader(tester, find.text('Source checks'));
      await tester.tap(find.text('Source checks'));
      await tester.pumpAndSettle();

      // Select the real fixture match and capture source alternatives.
      await _search(tester, _title);
      expect(find.text(_title), findsNWidgets(2));
      await _capture(binding, '12_search_reference');
      await tester.tap(find.text(_title).last);
      await tester.pump();
      expect(find.byKey(const ValueKey('discovery-progress')), findsOneWidget);
      expect(find.textContaining('of 6 complete.'), findsOneWidget);
      await _capture(binding, '13_source_discovery_progress');
      await _awaitDiscovery(tester, app, 'lanterns-main');
      expect(find.text('1 song match'), findsOneWidget);
      expect(find.text('3 source versions'), findsOneWidget);
      expect(find.text('Lyrics available'), findsWidgets);
      expect(find.text('2 sources unavailable'), findsOneWidget);
      final expectedContributors = contributingProviderIds(
        app.combined!,
      ).length;
      expect(expectedContributors, 2);
      expect(find.textContaining('Combined from 2 sources'), findsOneWidget);
      expect(find.textContaining('#'), findsNothing);
      await _capture(binding, '14_source_comparison');
      await tester.tap(find.byTooltip('Search options'));
      await tester.pumpAndSettle();
      final timedFilter = find.widgetWithText(FilterChip, 'Timed lyrics');
      expect(timedFilter, findsOneWidget);
      await _ensureBelowPinnedHeader(tester, timedFilter);
      await tester.tap(timedFilter);
      await tester.pumpAndSettle();
      final comparisonCounts = find.byKey(
        const ValueKey('home-search-comparison-counts'),
      );
      await _scrollIntoView(tester, comparisonCounts);
      expect(
        find.textContaining(RegExp(r'1 source\s+version')),
        findsOneWidget,
      );
      await _capture(binding, '15_source_timed_filter_one_version');
      await _ensureBelowPinnedHeader(tester, timedFilter);
      await tester.tap(timedFilter);
      await tester.pumpAndSettle();
      await _scrollIntoView(tester, comparisonCounts);
      expect(find.text('3 source versions'), findsOneWidget);
      final searchOptions = find.byTooltip('Search options');
      await _scrollIntoView(tester, searchOptions);
      await tester.tap(searchOptions);
      await tester.pumpAndSettle();
      final sourceChecks = find.text('Source checks');
      await _scrollIntoView(tester, sourceChecks);
      await tester.tap(sourceChecks);
      await tester.pumpAndSettle();
      expect(find.text('Check failed'), findsOneWidget);
      await _scrollIntoView(tester, sourceChecks);
      await tester.tap(sourceChecks);
      await tester.pumpAndSettle();
      expect(
        tester.view.viewInsets.bottom,
        0,
        reason: 'Opening a catalog result should dismiss the search keyboard.',
      );
      await _ensureBelowPinnedHeader(
        tester,
        find.textContaining('Lanterns guard the quiet road'),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Lanterns guard the quiet road'),
        findsOneWidget,
      );
      await _ensureBelowPinnedHeader(tester, find.text('Other matches'));
      await tester.tap(find.text('Other matches'));
      await tester.pumpAndSettle();
      final chordArchiveVersion = find.textContaining('Chord archive ·');
      expect(chordArchiveVersion, findsOneWidget);
      expect(find.text('Lyrics unavailable'), findsOneWidget);
      await _capture(binding, '16_source_alternatives');
      await _ensureBelowPinnedHeader(tester, chordArchiveVersion);
      await tester.tap(chordArchiveVersion);
      await tester.pumpAndSettle();
      expect(find.text('Choose this version'), findsOneWidget);
      await _ensureBelowPinnedHeader(tester, find.text('Choose this version'));
      await tester.pumpAndSettle();
      await _capture(binding, '17_source_preview_scrolled');
      await tester.tap(find.text('Choose this version'));
      await tester.pumpAndSettle();

      // Reader and editor show real persisted content and controls.
      expect(
        find.textContaining('Lanterns guard the quiet road'),
        findsOneWidget,
      );
      expect(find.byTooltip('Transpose by 1 semitone'), findsOneWidget);
      await _capture(binding, '18_reader_chords');
      await _waitForSnackBarToDismiss(tester);
      await tester.tap(_iconButtonWithTooltip('Transpose by 1 semitone'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Key: C#'), findsOneWidget);
      expect(find.text('C#'), findsOneWidget);
      expect(find.text('G#'), findsOneWidget);
      await tester.tap(_iconButtonWithTooltip('Hide chords'));
      await tester.pumpAndSettle();
      expect(find.text('C#'), findsNothing);
      expect(find.text('G#'), findsNothing);
      await tester.tap(_iconButtonWithTooltip('Show chords'));
      await tester.pumpAndSettle();
      expect(find.text('C#'), findsOneWidget);
      expect(find.text('G#'), findsOneWidget);
      await tester.tap(_iconButtonWithTooltip('Play lyric scrolling'));
      await tester.pump();
      expect(find.byTooltip('Pause lyric scrolling'), findsOneWidget);
      await tester.tap(_iconButtonWithTooltip('Pause lyric scrolling'));
      await tester.pump();
      await tester.drag(find.byType(Slider), const Offset(75, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byType(Slider)).value, greaterThan(0));
      await tester.tap(_iconButtonWithTooltip('Edit'));
      await tester.pumpAndSettle();
      final editorBody = find.byKey(const ValueKey('editor-lyrics-input'));
      await _scrollIntoView(tester, editorBody);
      await tester.tap(editorBody);
      await tester.pumpAndSettle();
      await _capture(binding, '19_editor_keyboard');
      await tester.enterText(
        editorBody,
        '[C]Lanterns light the winding road\n[G]We carry sparks into the dawn\n$_savedLine',
      );
      await tester.tap(_iconButtonWithTooltip('Save'));
      await tester.pumpAndSettle();
      expect(tester.view.viewInsets.bottom, 0);
      expect(
        app.songs.single.body,
        contains('Lanterns light the winding road'),
      );
      expect(app.songs.single.body, contains(_savedLine));
      final readerController = tester
          .widget<PlayerScreen>(find.byType(PlayerScreen))
          .controller;
      expect(
        readerController.state.songLines.map((line) => line.text).join('\n'),
        contains('Lanterns light the winding road'),
      );
      final savedReaderLine = find.textContaining(
        RegExp(r'Lanterns\s+light the winding road'),
      );
      await _scrollIntoView(tester, savedReaderLine);
      expect(savedReaderLine, findsOneWidget);
      expect(find.textContaining(_savedLine), findsOneWidget);
      await tester.tap(_iconButtonWithTooltip('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('editor-lyrics-input')),
        '[C]This change is cancelled',
      );
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('editor-lyrics-input')),
            )
            .controller!
            .text,
        '[C]This change is cancelled',
      );
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(
        app.songs.single.body,
        contains('Lanterns light the winding road'),
      );
      expect(app.songs.single.body, contains(_savedLine));
      expect(
        find.textContaining(RegExp(r'Lanterns\s+light the winding road')),
        findsOneWidget,
      );
      expect(find.text('This change is cancelled'), findsNothing);
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Songs'));
      await tester.pumpAndSettle();
      expect(app.songs, hasLength(1));
      await tester.tap(_iconButtonWithTooltip('Add song'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(app.songs, hasLength(1));
      await tester.tap(find.text(_title).first);
      await tester.pumpAndSettle();
      expect(find.textContaining(_savedLine), findsOneWidget);
      await tester.tap(_iconButtonWithTooltip('Add to favorites'));
      await tester.pumpAndSettle();

      // Return to the library after opening its reader, then check Home.
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsWidgets);
      expect(app.recent, isNotEmpty);
      expect(find.byTooltip('Add song'), findsOneWidget);
      expect(find.text('Recent songs'), findsNothing);
      await tester.tap(find.text('Songs'));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsWidgets);
      await _capture(binding, '20_library_populated');
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(_homeMode('recent'));
      await tester.pumpAndSettle();
      if (find.byTooltip('Clear search text').evaluate().isNotEmpty) {
        await tester.tap(_iconButtonWithTooltip('Clear search text'));
        await tester.pumpAndSettle();
      }
      // The import and the later library open each record a visit.
      expect(app.recent, hasLength(2));
      _expectHomeModeCount('recent', 2);
      await _capture(binding, '21_home_recent_populated');
      await tester.tap(_homeMode('favorites'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<VerseHomeScreen>(find.byType(VerseHomeScreen))
            .state
            .homeListMode
            .name,
        'favorites',
      );
      expect(find.text(_title), findsWidgets);
      _expectHomeModeCount('favorites', 1);
      // Counted tab labels retain stable mode keys.
      expect(_homeMode('favorites'), findsOneWidget);
      await _capture(binding, '22_home_favorites_populated');
      await tester.tap(find.text('Setlists'));
      await tester.pumpAndSettle();
      await tester.tap(_iconButtonWithTooltip('New setlist'));
      await tester.pumpAndSettle();
      await tester.tap(_iconButtonWithTooltip('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Dawn Set');
      await tester.tap(_iconButtonWithTooltip('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add songs'));
      await tester.pumpAndSettle();
      final pickerSong = find.text(_title).last;
      await _scrollIntoView(tester, pickerSong);
      await tester.tap(pickerSong);
      await tester.pumpAndSettle();
      final addSelectedSongs = find.ancestor(
        of: find.text('Add songs (1)'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      expect(addSelectedSongs, findsOneWidget);
      expect(
        tester.getRect(addSelectedSongs).bottom,
        lessThanOrEqualTo(
          (tester.view.physicalSize.height - tester.view.viewInsets.bottom) /
              tester.view.devicePixelRatio,
        ),
        reason: 'The picker confirmation must stay above the Android keyboard.',
      );
      await _capture(binding, '22a_setlist_song_picker_keyboard');
      await _scrollIntoView(tester, addSelectedSongs);
      await tester.tap(addSelectedSongs);
      await tester.pumpAndSettle();
      expect(app.setlists.single.entries, hasLength(1));
      await tester.tap(find.text('Add songs'));
      await tester.pumpAndSettle();
      final secondPickerSong = find.text(_title).last;
      await _scrollIntoView(tester, secondPickerSong);
      await tester.tap(secondPickerSong);
      await tester.pumpAndSettle();
      await _scrollIntoView(tester, addSelectedSongs);
      await tester.tap(addSelectedSongs);
      await tester.pumpAndSettle();
      expect(find.text(_title), findsNWidgets(2));
      expect(app.setlists.single.entries, hasLength(2));
      final firstEntryMenu = find.descendant(
        of: find.byKey(ValueKey(app.setlists.single.entries.first.id)),
        matching: find.byType(PopupMenuButton<String>),
      );
      expect(firstEntryMenu, findsOneWidget);
      await tester.tap(firstEntryMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Song-specific key and capo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'D');
      await tester.enterText(find.byType(TextField).last, '2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await _capture(binding, '23_setlist_populated');
      await tester.tap(find.text(_title).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Key: D'), findsOneWidget);
      await tester.tap(_iconButtonWithTooltip('Next song'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Key: C'), findsOneWidget);
      await tester.longPress(_iconButtonWithTooltip('Previous song'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Key: D'), findsOneWidget);
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      final overrideEntryId = app.setlists.single.entries.first.id;
      final regularEntryId = app.setlists.single.entries.last.id;
      final dragHandles = find.byIcon(Icons.drag_handle_rounded);
      final start = tester.getCenter(dragHandles.first);
      final destination = tester.getCenter(dragHandles.last);
      final gesture = await tester.startGesture(start);
      await tester.pump();
      // Send a continuous path like a finger drag. A single large pointer
      // jump can be interpreted as only one reorder slot by the native view.
      final target = destination + const Offset(0, 30);
      final step = (target - start) / 20;
      for (var index = 0; index < 20; index++) {
        await gesture.moveBy(step);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 150));
      final keyedRowsWhileHeld = find
          .byType(ListTile)
          .evaluate()
          .map((element) => (element.widget as ListTile).key)
          .toList();
      debugPrint(
        'SINGBOOK_E2E_DRAG held start=$start destination=$destination '
        'keyedRows=$keyedRowsWhileHeld '
        'draggedKeyCount=${find.byKey(ValueKey(overrideEntryId)).evaluate().length}',
      );
      await _capture(binding, '23a_setlist_drag_held');
      await gesture.up();
      await tester.pumpAndSettle();
      // The reorder callback persists asynchronously through SQLite; frame
      // settling alone does not guarantee that IO-backed controller state has
      // reloaded yet.
      await tester.runAsync(() async {
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (app.setlists.single.entries.first.id != regularEntryId &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pump();
      expect(app.setlists.single.entries, hasLength(2));
      expect(app.setlists.single.entries.first.id, regularEntryId);
      expect(app.setlists.single.entries.last.id, overrideEntryId);
      expect(app.setlists.single.entries.last.overrides['key'], 'D');

      // Exercise the setlist delete confirmation through the card menu. A
      // duplicate gives us a disposable target while preserving the setlist
      // whose order and overrides are verified after remount below.
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      expect(app.setlists, hasLength(2));
      final originalSetlistId = app.setlists
          .singleWhere((setlist) => setlist.name == 'Dawn Set')
          .id;
      final disposableSetlist = app.setlists.singleWhere(
        (setlist) => setlist.id != originalSetlistId,
      );
      final disposableMenu = _popupMenuWithTooltip(
        'Actions for ${disposableSetlist.name}',
      );
      await tester.tap(disposableMenu);
      await tester.pumpAndSettle();
      final deleteMenuItem = find.text('Delete').last;
      await _scrollIntoView(tester, deleteMenuItem);
      await tester.tap(deleteMenuItem);
      await tester.pumpAndSettle();
      expect(find.text('Delete setlist?'), findsOneWidget);
      await _capture(binding, '23b_setlist_delete_confirmation');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(app.setlists, hasLength(2));
      expect(
        app.setlists.any((setlist) => setlist.id == disposableSetlist.id),
        isTrue,
      );
      await tester.tap(disposableMenu);
      await tester.pumpAndSettle();
      await _scrollIntoView(tester, deleteMenuItem);
      await tester.tap(deleteMenuItem);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(app.setlists, hasLength(1));
      expect(app.setlists.single.id, originalSetlistId);
      await _capture(binding, '23c_setlist_delete_confirmed');

      // Theme changes are visible and survive app persistence in the same DB.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await _capture(binding, '24_settings_light');
      await _selectDropdown(tester, 'Theme', 'Dark');
      await _selectDropdown(tester, 'Default scrolling mode', 'Timed lyrics');
      final providerSwitch = find.widgetWithText(
        SwitchListTile,
        'Journey catalog',
      );
      await _scrollIntoView(tester, providerSwitch);
      expect(providerSwitch, findsOneWidget);
      await tester.tap(providerSwitch);
      await tester.pumpAndSettle();
      await _selectDropdown(tester, 'App language', 'Українська');
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );
      await _capture(binding, '25_settings_dark_ukrainian');
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final restored = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(_journeyProviders(fixture)),
      );
      await tester.pumpWidget(VerseApp(controller: restored));
      await tester.pumpAndSettle();
      expect(restored.settings['themeMode'], 'dark');
      expect(restored.settings['locale'], 'uk');
      expect(restored.settings['timingMode'], 'timed');
      expect(restored.providerEnabled(_catalogId), isFalse);
      expect(
        restored.songs.single.body,
        contains('Lanterns light the winding road'),
      );
      expect(restored.songs.single.body, contains(_savedLine));
      expect(restored.songs.single.favorite, isTrue);
      expect(restored.setlists.single.entries, hasLength(2));
      expect(restored.setlists.single.entries.last.overrides['key'], 'D');

      // Exercise the public import/export paths that normally hand off to an
      // operating-system picker or share sheet.
      final chordPro = restored.exportSong(restored.songs.single);
      final reimported = await restored.importDocument(
        PickedDocument(
          'roundtrip.cho',
          Uint8List.fromList(utf8.encode(chordPro)),
        ),
      );
      expect(reimported.songs.single.id, restored.songs.single.id);
      expect(restored.songs, hasLength(1));
      final backupBytes = encodeLibraryPackage(
        restored.songs,
        restored.setlists,
      );
      final backup = decodeLibraryPackage(backupBytes);
      expect(backup.songs.single.body, restored.songs.single.body);
      expect(backup.setlists.single.entries, hasLength(2));
      final importedBackup = await restored.importDocument(
        PickedDocument('journey.lyrics-setlist', backupBytes),
      );
      expect(importedBackup.setlists.single.entries, hasLength(2));
      expect(restored.setlists, hasLength(2));
      final pdf = await createSongPdf(
        restored.songs,
        format: PdfPageFormat.a4,
        setlist: importedBackup.setlists.single,
      );
      expect(utf8.decode(pdf.take(4).toList()), '%PDF');
      expect(pdf.length, greaterThan(10000));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await repository.close();
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  if (_skipScreenshots) return;
  debugPrint('SINGBOOK_E2E_CAPTURE:$name');
  // The host driver watches logcat for this marker to capture the full device
  // frame (including Android status and navigation bars) before the next tap.
  await Future<void>.delayed(const Duration(seconds: 2));
}

Finder _iconButtonWithTooltip(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is IconButton && widget.tooltip == tooltip,
  description: 'IconButton with tooltip "$tooltip"',
);

Finder _homeMode(String mode) => find.byKey(ValueKey('home-mode-$mode'));

void _expectHomeModeCount(String mode, int count) {
  expect(
    find.descendant(
      of: _homeMode(mode),
      matching: find.textContaining('($count)'),
    ),
    findsOneWidget,
  );
}

Finder _popupMenuWithTooltip(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is PopupMenuButton<String> && widget.tooltip == tooltip,
  description: 'PopupMenuButton with tooltip "$tooltip"',
);

Future<void> _waitForSnackBarToDismiss(WidgetTester tester) async {
  if (find.byType(SnackBar).evaluate().isEmpty) return;
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  expect(find.byType(SnackBar), findsNothing);
}

Future<void> _awaitDiscovery(
  WidgetTester tester,
  AppController app,
  String stage,
) async {
  debugPrint(
    'SINGBOOK_E2E_DISCOVERY_BEFORE:$stage '
    'selected=${app.selection?.title ?? 'none'} '
    'query=${app.query} checks=${_checkSummary(app)}',
  );
  final completed = await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (app.discovering && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return !app.discovering;
  });
  debugPrint(
    'SINGBOOK_E2E_DISCOVERY_AFTER:$stage completed=$completed '
    'selected=${app.selection?.title ?? 'none'} '
    'query=${app.query} checks=${_checkSummary(app)}',
  );
  expect(completed, isTrue, reason: '$stage discovery should finish in 15s.');
  await tester.pump();
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 2),
  );
}

String _checkSummary(AppController app) => app.checks.values
    .map((check) => '${check.providerId}:${check.state}:${check.code ?? '-'}')
    .join(',');

Future<void> _selectDropdown(
  WidgetTester tester,
  String label,
  String value,
) async {
  final labelFinder = find.text(label);
  await _scrollIntoView(tester, labelFinder);
  final fieldColumn = find
      .ancestor(of: labelFinder, matching: find.byType(Column))
      .first;
  final dropdown = find.descendant(
    of: fieldColumn,
    matching: find.byWidgetPredicate((widget) => widget is DropdownButton),
  );
  await _ensureBelowPinnedHeader(tester, dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String query) async {
  await _focusSearchInput(tester);
  await tester.enterText(find.byType(TextField).first, query);
  expect(
    tester.widget<TextField>(find.byType(TextField).first).controller!.text,
    query,
    reason: 'The search field should retain the entered query.',
  );
  await tester.pump();
  _expectVisibleQuery(tester, query);
  // Exercise the normal debounced search path; the native keyboard and
  // viewport have already settled before the query is entered.
  await tester.pump(const Duration(milliseconds: 400));
  for (var attempt = 0; attempt < 60; attempt++) {
    final app = tester.widget<VerseApp>(find.byType(VerseApp)).controller!;
    if (app.query == query && !app.searching) break;
    await tester.pump(const Duration(milliseconds: 100));
  }
  final app = tester.widget<VerseApp>(find.byType(VerseApp)).controller!;
  expect(app.query, query, reason: 'Debounced catalog query should submit.');
  expect(app.searching, isFalse, reason: 'Catalog search should complete.');
  tester.widget<TextField>(find.byType(TextField).first).focusNode?.unfocus();
  await tester.pumpAndSettle();
}

void _expectVisibleQuery(WidgetTester tester, String query) {
  expect(
    tester.widget<VerseHomeScreen>(find.byType(VerseHomeScreen)).state.query,
    query,
    reason: 'The Home search state should reflect the entered text.',
  );
}

Future<void> _focusSearchInput(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await _scrollIntoView(tester, fields);
  final field = fields.first;
  tester.widget<TextField>(field).focusNode!.requestFocus();
  // Wait for the native keyboard resize before entering text so the Search
  // field is ready to receive input.
  await tester.pumpAndSettle();
  expect(
    tester.widget<TextField>(field).focusNode!.hasFocus,
    isTrue,
    reason: 'Search input should receive focus before entering a query.',
  );
}

Future<void> _ensureBelowPinnedHeader(
  WidgetTester tester,
  Finder target,
) async {
  await Scrollable.ensureVisible(
    tester.element(target),
    // The app keeps a tall branded header pinned above the body. Place controls
    // well below it so they remain tappable on short landscape viewports.
    alignment: 0.65,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 2),
  );
}

Future<void> _scrollIntoView(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  if (target.evaluate().isNotEmpty) {
    await _ensureBelowPinnedHeader(tester, target);
    return;
  }

  // A target above the current offset may not be built by a lazy ListView.
  // Reset only the test viewport to the list's start, then use normal scroll
  // gestures to reveal lower controls.
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 240, scrollable: scrollable);
  }
  await _ensureBelowPinnedHeader(tester, target);
}

List<LyricsProvider> _journeyProviders(_JourneyFixture fixture) => [
  _JourneyCatalog(fixture),
  _JourneySource(
    id: _chordSourceId,
    name: 'Chord archive',
    capabilities: const {'lyrics', 'chords'},
    body: _body,
    fixture: fixture,
    delay: const Duration(seconds: 4),
  ),
  _JourneySource(
    id: _lyricSourceId,
    name: 'Lyric archive',
    capabilities: const {'lyrics'},
    body: _plainBody,
    fixture: fixture,
  ),
  _JourneySource(
    id: _timingOnlySourceId,
    name: 'Timing only',
    capabilities: const {'lyrics', 'timing'},
    body: '',
    timingOnly: true,
    fixture: fixture,
  ),
  _JourneySource(
    id: _unavailableSourceId,
    name: 'Unavailable archive',
    capabilities: const {'lyrics'},
    body: '',
    unavailable: true,
    fixture: fixture,
  ),
  _JourneySource(
    id: _failedSourceId,
    name: 'Failed archive',
    capabilities: const {'lyrics'},
    body: '',
    failure: true,
    fixture: fixture,
  ),
];

/// Runs the deterministic provider fixture without Flutter UI or a database.
/// The headless test uses this to validate expected counts before a device run.
Future<Map<String, Object>> runSingbookFixturePreflight() async {
  final fixture = _JourneyFixture();
  final discovery = SourceDiscoveryService(_journeyProviders(fixture));

  Future<({List<SourceResult> results, Map<String, ProviderCheck> checks})>
  runDiscovery(SongCandidate selection) async {
    final checks = <String, ProviderCheck>{};
    final results = await discovery.discover(
      selection,
      onProgress: (check) => checks[check.providerId] = check,
    );
    return (results: results, checks: checks);
  }

  final quietFirst = await runDiscovery(_JourneyCatalog.quietHarbor);
  final quietRetry = await runDiscovery(_JourneyCatalog.quietHarbor);
  final main = await runDiscovery(_JourneyCatalog.candidate);
  final combined = combineSources(_JourneyCatalog.candidate, main.results);
  int unavailableCount(Map<String, ProviderCheck> checks) =>
      checks.values.where((check) {
        if (check.state == 'failed' || check.state == 'unavailable') {
          return true;
        }
        final result = check.result;
        return result != null &&
            result.body.trim().isEmpty &&
            result.timingTracks.isEmpty;
      }).length;
  int usableCount(List<SourceResult> results) => results
      .where(
        (result) =>
            result.matchKind != MatchKind.rejected &&
            result.body.trim().isNotEmpty,
      )
      .length;

  return {
    'quietFirstUsable': usableCount(quietFirst.results),
    'quietFirstUnavailableCount': unavailableCount(quietFirst.checks),
    'quietFirstTimingOnlyTracks': quietFirst.results
        .where((result) => result.candidate.providerId == _timingOnlySourceId)
        .fold<int>(0, (count, result) => count + result.timingTracks.length),
    'quietRetryUsable': usableCount(quietRetry.results),
    'mainUsable': usableCount(main.results),
    'mainUnavailableCount': unavailableCount(main.checks),
    'mainContributors': contributingProviderIds(combined).length,
    'mainTimingOnlyState': main.checks[_timingOnlySourceId]?.state ?? 'missing',
    'mainUnavailableState':
        main.checks[_unavailableSourceId]?.state ?? 'missing',
    'mainFailureState': main.checks[_failedSourceId]?.state ?? 'missing',
  };
}

const _failedSourceId = 'journey_failed';

class _JourneyFixture {
  final cancelSearchStarted = Completer<void>();
  final cancelSearchRelease = Completer<void>();
  final Map<String, int> quietHarborAttempts = {};

  bool returnLyricsFor(String providerId, String candidateId) {
    if (candidateId != 'quiet-harbor') return true;
    final attempt = quietHarborAttempts.update(
      providerId,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    return attempt > 1;
  }
}

class _JourneyCatalog implements LyricsProvider {
  _JourneyCatalog(this.fixture);
  final _JourneyFixture fixture;
  var retryAttempts = 0;

  static const candidate = SongCandidate(
    providerId: _catalogId,
    id: 'lanterns-dawn',
    title: _title,
    artist: _artist,
    album: 'Paper Moons Demo',
    durationSeconds: 180,
  );
  static const quietHarbor = SongCandidate(
    providerId: _catalogId,
    id: 'quiet-harbor',
    title: 'Quiet Harbor',
    artist: 'Count Fixtures',
    album: 'Search Count Demo',
    durationSeconds: 160,
  );

  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: _catalogId,
    name: 'Journey catalog',
    capabilities: {'lyrics'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final normalized = query.toLowerCase().trim();
    if (normalized == 'cancel this query') {
      fixture.cancelSearchStarted.complete();
      await fixture.cancelSearchRelease.future;
      cancel?.throwIfCancelled();
      return [candidate];
    }
    if (normalized == 'retry' && retryAttempts++ == 0) {
      throw const ProviderException('search_failed');
    }
    if (normalized == 'retry') return [candidate];
    if (normalized.contains('quiet harbor')) return [quietHarbor];
    if (normalized == 'signal two') return _signalHits.take(2).toList();
    if (normalized == 'signal song') return _signalHits.take(2).toList();
    if (normalized == 'fixtures') return _signalHits;
    if (normalized == 'signal five' || normalized == 'signal') {
      return _signalHits;
    }
    if (normalized.contains('lanterns')) return [candidate];
    return const [];
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final hasLyrics = fixture.returnLyricsFor(
      candidate.providerId,
      candidate.id,
    );
    return SourceResult(
      candidate: candidate,
      body: hasLyrics ? _plainBody : '',
      metadata: const {'key': 'C'},
      matchKind: MatchKind.sameRecording,
      timingTracks: hasLyrics
          ? [
              bindImportedTiming(
                parseLrc(
                  '[00:01.00]Lanterns guard the quiet road\n[00:03.00]We carry sparks into the dawn',
                  sourceDocumentId: 'journey-timing',
                ),
                _plainBody,
              ),
            ]
          : const [],
    );
  }
}

final _signalHits = List<SongCandidate>.generate(
  5,
  (index) => SongCandidate(
    providerId: _catalogId,
    id: 'signal-${index + 1}',
    title: 'Signal Song ${index + 1}',
    artist: 'Count Fixtures',
    album: 'Search Count Demo',
    durationSeconds: 120 + index * 10,
    metadata: {
      'hasTiming': index < 2,
      'hasChords': index.isEven,
      'language': 'en',
    },
  ),
);

class _JourneySource implements LyricsProvider {
  const _JourneySource({
    required this.id,
    required this.name,
    required this.capabilities,
    required this.body,
    required this.fixture,
    this.timingOnly = false,
    this.unavailable = false,
    this.failure = false,
    this.delay = Duration.zero,
  });

  final String id, name, body;
  final Set<String> capabilities;
  final _JourneyFixture fixture;
  final bool timingOnly, unavailable, failure;
  final Duration delay;

  @override
  ProviderDefinition get definition =>
      ProviderDefinition(id: id, name: name, capabilities: capabilities);

  SongCandidate _candidate(String query) => SongCandidate(
    providerId: id,
    id: query.toLowerCase().contains('quiet harbor')
        ? 'quiet-harbor'
        : 'lanterns-dawn',
    title: query.toLowerCase().contains('quiet harbor')
        ? 'Quiet Harbor'
        : _title,
    artist: query.toLowerCase().contains('quiet harbor')
        ? 'Count Fixtures'
        : _artist,
    album: query.toLowerCase().contains('quiet harbor')
        ? 'Search Count Demo'
        : 'Paper Moons Demo',
    durationSeconds: query.toLowerCase().contains('quiet harbor') ? 160 : 180,
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => unavailable ? const [] : [_candidate(query)];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (failure) throw const ProviderException('network_error');
    if (unavailable) throw const ProviderException('unavailable');
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final hasLyrics = fixture.returnLyricsFor(id, candidate.id);
    return SourceResult(
      candidate: candidate,
      body: hasLyrics ? body : '',
      metadata: const {'key': 'C', 'capo': 2},
      timingTracks: timingOnly && hasLyrics
          ? [
              parseLrc(
                '[00:01.00]Unmatched timing-only cue',
                sourceDocumentId: 'journey-timing-only',
              ),
            ]
          : const [],
      matchKind: MatchKind.sameSong,
    );
  }
}
