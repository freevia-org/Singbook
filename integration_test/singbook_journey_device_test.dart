import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:pdf/pdf.dart';
import 'package:sqflite/sqflite.dart' show deleteDatabase, getDatabasesPath;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_database.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/domain/timing.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/settings/settings_screen.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';
import 'support/ios_screenshots.dart';

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
      // The production entry point initializes sqflite_common_ffi on Windows.
      // This journey builds the controller directly, so mirror that startup
      // before asking sqflite for the isolated test database directory.
      initializeLibraryDatabase();
      final dbPath = paths.join(
        await getDatabasesPath(),
        'singbook_journey_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: dbPath);
      final controllers = <AppController>[];
      addTearDown(() async {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          for (final controller in controllers) {
            controller.dispose();
          }
          await tester.runAsync(() async {
            await repository.close();
            await deleteDatabase(dbPath);
          });
        }
      });
      final fixture = _JourneyFixture();
      final providers = _journeyProviders(fixture);
      final app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(providers),
      );
      controllers.add(app);
      await app.initialize();
      await app.setSetting('catalog', _catalogId);

      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(AppBar)));

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
      expect(
        find.byKey(const ValueKey('home-search-comparison-counts')),
        findsOneWidget,
      );
      expect(find.text(l10n.searchReadyVersions(0)), findsOneWidget);
      expect(_discoveryProgressCounter(), findsOneWidget);
      await _capture(binding, '11a_discovery_no_lyrics_progress');
      await _awaitDiscovery(tester, app, 'quiet-harbor');
      expect(find.byKey(const ValueKey('discovery-no-lyrics')), findsOneWidget);
      expect(find.text(l10n.searchDiscoveryNoLyrics), findsOneWidget);
      expect(find.text(l10n.searchDiscoveryRetry), findsOneWidget);
      await _openSourceChecks(tester);
      expect(find.text(l10n.searchSourcesUnavailableCount(6)), findsOneWidget);
      expect(
        app.checks.values.where((check) => check.state == 'failed'),
        hasLength(1),
      );
      expect(
        app.checks.values.where((check) => check.state == 'unavailable'),
        hasLength(5),
      );
      final sourceChecksScrollable = find
          .descendant(
            of: find.byKey(const ValueKey('source-checks-sheet')),
            matching: find.byType(Scrollable),
          )
          .first;
      final unavailableProvider = find.byKey(
        const ValueKey('discovery-provider-journey_unavailable'),
      );
      await tester.scrollUntilVisible(
        unavailableProvider,
        120,
        scrollable: sourceChecksScrollable,
      );
      expect(
        find.descendant(
          of: unavailableProvider,
          matching: find.text('Unavailable archive'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: unavailableProvider,
          matching: find.text(l10n.searchProviderUnavailable),
        ),
        findsOneWidget,
      );
      final failedProvider = find.byKey(
        const ValueKey('discovery-provider-journey_failed'),
      );
      await tester.scrollUntilVisible(
        failedProvider,
        120,
        scrollable: sourceChecksScrollable,
      );
      expect(
        find.descendant(
          of: failedProvider,
          matching: find.text('Failed archive'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: failedProvider,
          matching: find.text(l10n.searchProviderFailed),
        ),
        findsOneWidget,
      );
      await tester.tap(failedProvider);
      await tester.pumpAndSettle();
      final failedProviderDetails = find.byKey(
        const ValueKey('source-check-details-journey_failed'),
      );
      expect(failedProviderDetails, findsOneWidget);
      expect(
        find.descendant(
          of: failedProviderDetails,
          matching: find.text(l10n.searchCheckNetwork),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: failedProviderDetails,
          matching: find.text('network'),
        ),
        findsWidgets,
      );
      await _capture(binding, '11b_source_network_error_details');
      await tester.tap(
        find.descendant(
          of: failedProviderDetails,
          matching: find.byTooltip(l10n.navClose),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(binding, '11b_discovery_no_usable_lyrics');
      final retryLyrics = find.descendant(
        of: find.byKey(const ValueKey('source-checks-sheet')),
        matching: find.widgetWithText(TextButton, l10n.searchDiscoveryRetry),
      );
      expect(retryLyrics, findsOneWidget);
      await tester.ensureVisible(retryLyrics);
      await tester.tap(retryLyrics);
      await tester.pump();
      expect(find.byKey(const ValueKey('discovery-progress')), findsOneWidget);
      await _capture(binding, '11c_discovery_retry_progress');
      await _awaitDiscovery(tester, app, 'lanterns');
      expect(find.byKey(const ValueKey('discovery-no-lyrics')), findsNothing);
      expect(find.text(l10n.searchReadyVersions(4)), findsOneWidget);
      await _capture(binding, '11d_discovery_retry_success');

      // Select the real fixture match and capture source alternatives.
      await _search(tester, _title);
      expect(find.text(_title), findsNWidgets(2));
      await _capture(binding, '12_search_reference');
      await tester.tap(find.text(_title).last);
      await tester.pump();
      expect(find.byKey(const ValueKey('discovery-progress')), findsOneWidget);
      expect(_discoveryProgressCounter(), findsOneWidget);
      _expectReadyCountDisplayed(tester, l10n);
      await _capture(binding, '13_source_discovery_progress');
      await _awaitDiscovery(tester, app, 'lanterns-main');
      expect(find.text(l10n.searchReadyVersions(4)), findsOneWidget);
      expect(find.text(l10n.searchCombinedLabel), findsOneWidget);
      expect(find.text(l10n.searchContributions), findsOneWidget);
      final expectedContributors = contributingProviderIds(
        app.combined!,
      ).length;
      expect(expectedContributors, 4);
      expect(
        app.combined!.metadata['moodTags'],
        containsAll(['reflective', 'wistful']),
      );
      expect(app.combined!.metadata['externalIdentifiers'], {
        'catalog': ['original-work-1'],
        'isrc': ['ORIGINAL-QA-1'],
      });
      expect(contributingProviderIds(app.combined!), {
        _catalogId,
        _chordSourceId,
        _lyricSourceId,
        _timingOnlySourceId,
      });
      expect(find.textContaining('#'), findsNothing);
      await _capture(binding, '14_source_comparison');
      final comparisonCounts = find.byKey(
        const ValueKey('home-search-comparison-counts'),
      );
      await _scrollIntoView(tester, comparisonCounts);
      expect(
        tester.widget<Text>(comparisonCounts).data,
        l10n.searchReadyVersions(4),
      );
      await tester.tap(find.byKey(const ValueKey('version-info-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('version-info-sheet')), findsOneWidget);
      await _capture(binding, '15_source_version_info');
      final combinedVersion = tester
          .widget<VerseHomeScreen>(
            find.byType(VerseHomeScreen, skipOffstage: false),
          )
          .state
          .comparison!
          .suggested!;
      expect(combinedVersion.contributions, hasLength(4));
      final infoSheet = find.byKey(const ValueKey('version-info-sheet'));
      final infoScrollable = find
          .descendant(of: infoSheet, matching: find.byType(Scrollable))
          .first;
      for (final contribution in combinedVersion.contributions) {
        final providerName = find.descendant(
          of: infoSheet,
          matching: find.text(contribution.providerName),
        );
        await tester.scrollUntilVisible(
          providerName,
          120,
          scrollable: infoScrollable,
        );
        expect(providerName, findsOneWidget);
        final roles = contribution.roles
            .map(
              (role) => switch (role) {
                'lyrics' => l10n.providerCapabilityLyrics,
                'chords' => l10n.providerCapabilityChords,
                'timing' => l10n.playerTimedLyrics,
                _ => l10n.searchMetadata,
              },
            )
            .join(' · ');
        final contributionField = find
            .ancestor(of: providerName, matching: find.byType(Column))
            .first;
        final contributionRoles = find.descendant(
          of: contributionField,
          matching: find.textContaining(roles),
        );
        await tester.scrollUntilVisible(
          contributionRoles,
          120,
          scrollable: infoScrollable,
        );
        expect(contributionRoles, findsOneWidget);
      }
      final infoClose = find.descendant(
        of: infoSheet,
        matching: find.byTooltip(l10n.navClose),
      );
      await tester.scrollUntilVisible(
        infoClose,
        -120,
        scrollable: infoScrollable,
      );
      // The close tooltip can be laid out partly beyond the sheet's clipped
      // viewport on iOS. Tap the visible barrier strip above the sheet, then
      // prove it no longer obscures the comparison.
      final screenSize =
          tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(find.byType(ModalBarrier), findsWidgets);
      await tester.tapAt(Offset(screenSize.width / 2, 8));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('version-info-sheet')), findsNothing);
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
      final combinedChip = find.byKey(const ValueKey('version-row-combined'));
      expect(tester.widget<ChoiceChip>(combinedChip).selected, isTrue);
      await _capture(binding, '16a_combined_sources_inline_preview');
      final pages = find.byKey(const ValueKey('version-preview-pages'));
      final pageRect = tester.getRect(pages);
      final viewport = Offset.zero & screenSize;
      final visiblePageRect = pageRect.intersect(viewport);
      expect(visiblePageRect.width, greaterThan(1));
      expect(visiblePageRect.height, greaterThan(1));
      final swipeStart = Offset(
        visiblePageRect.left + visiblePageRect.width * .85,
        visiblePageRect.top + visiblePageRect.height * .55,
      );
      final swipeDistance = visiblePageRect.width * .65;
      await tester.dragFrom(swipeStart, Offset(-swipeDistance, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(combinedChip).selected, isFalse);
      await _capture(binding, '16b_swiped_provider_preview');
      await tester.dragFrom(
        Offset(
          visiblePageRect.left + visiblePageRect.width * .15,
          swipeStart.dy,
        ),
        Offset(swipeDistance, 0),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(combinedChip).selected, isTrue);
      final chordArchiveVersion = find.widgetWithText(
        ChoiceChip,
        'Chord archive',
      );
      await _ensureBelowPinnedHeader(tester, chordArchiveVersion);
      await tester.ensureVisible(chordArchiveVersion);
      await tester.tap(chordArchiveVersion);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(chordArchiveVersion).selected, isTrue);
      expect(find.text(l10n.actionSave), findsOneWidget);
      await _capture(binding, '16_source_alternatives');
      final openLyrics = find.byKey(const ValueKey('save-open-lyrics'));
      await tester.ensureVisible(openLyrics);
      await tester.tap(openLyrics);
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () =>
            app.songs.any((song) => song.body.contains('Lanterns guard')) &&
            find.byType(PlayerScreen).evaluate().isNotEmpty,
        'selected lyrics to persist and open in the reader',
      );

      // Reader and editor show real persisted content and controls.
      expect(
        find.textContaining('Lanterns guard the quiet road'),
        findsOneWidget,
      );
      final pitchSelector = find.byKey(const ValueKey('pitch-key-dropdown'));
      expect(pitchSelector, findsOneWidget);
      await _capture(binding, '18_reader_chords');
      await _waitForSnackBarToDismiss(tester);
      await tester.tap(pitchSelector);
      await tester.pumpAndSettle();
      final higherKey = find.widgetWithText(PopupMenuItem<String>, 'C♯');
      await tester.ensureVisible(higherKey);
      await tester.tap(higherKey);
      await tester.pumpAndSettle();
      final playerController = tester
          .widget<PlayerScreen>(find.byType(PlayerScreen))
          .controller;
      expect(playerController.state.readerKey, 'C#');
      final chordLines = find.byType(ChordLyricsLine);
      expect(
        tester
            .widgetList<ChordLyricsLine>(chordLines)
            .expand((line) => line.chords.map((chord) => chord.symbol)),
        containsAll(['C#', 'G#']),
      );
      // Visibility now belongs to Settings > Player, rather than the pitch
      // popup. This journey verifies reader rendering/persistence; the parity
      // feature suite exercises the actual Settings switch.
      await tester.runAsync(() => playerController.setShowChords(false));
      await tester.pumpAndSettle();
      await _waitForState(tester, () {
        final lines = tester.widgetList<ChordLyricsLine>(chordLines);
        return lines.isNotEmpty && lines.every((line) => !line.showChords);
      }, 'chord visibility to turn off');
      expect(
        tester
            .widgetList<ChordLyricsLine>(chordLines)
            .every((line) => !line.showChords),
        isTrue,
      );
      await tester.runAsync(() => playerController.setShowChords(true));
      await tester.pumpAndSettle();
      await _waitForState(tester, () {
        final lines = tester.widgetList<ChordLyricsLine>(chordLines);
        return lines.isNotEmpty && lines.every((line) => line.showChords);
      }, 'chord visibility to turn on');
      expect(
        tester
            .widgetList<ChordLyricsLine>(chordLines)
            .every((line) => line.showChords),
        isTrue,
      );
      final playPause = find.byKey(const ValueKey('start-lyric-scroll'));
      await tester.tap(playPause);
      await tester.pump();
      expect(
        find.descendant(of: playPause, matching: find.text(l10n.playerPause)),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 1));
      await _capture(binding, '18a_reader_playing');
      await tester.tap(playPause);
      await tester.pump();
      final seekSlider = find.byKey(const ValueKey('player-seek-slider'));
      await tester.drag(seekSlider, const Offset(75, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(seekSlider).value, greaterThan(0));
      await tester.tap(find.byTooltip(l10n.songMenuLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.actionEdit).last);
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
      await tester.tap(_saveButton(l10n));
      await tester.pumpAndSettle();
      await _waitForSavedReader(tester, app);
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
      await tester.tap(find.byTooltip(l10n.songMenuLabel).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.actionEdit).last);
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
      await _waitForSavedReader(tester, app);
      await _capture(binding, '19b_reader_after_discard');
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
      await tester.tap(_homeMode('library'));
      await tester.pumpAndSettle();
      expect(app.songs, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.menuTypeNewSong).last);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(app.songs, hasLength(1));
      await _capture(binding, '19c_after_cancel_new_song');
      final savedSongTitle = find
          .byWidgetPredicate(
            (widget) => widget is Text && widget.data == _title,
          )
          .first;
      await tester.ensureVisible(savedSongTitle);
      await tester.tap(savedSongTitle);
      await tester.pumpAndSettle();
      await _capture(binding, '19d_reopened_saved_song');
      await _waitForState(
        tester,
        () => find.byType(PlayerScreen).evaluate().isNotEmpty,
        'saved song reader to open',
      );
      await _scrollIntoView(tester, find.textContaining(_savedLine));
      expect(find.textContaining(_savedLine), findsOneWidget);
      await tester.tap(_iconButtonWithTooltip('Add to favorites'));
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () => app.songs.length == 1 && app.songs.single.favorite,
        'song favorite to persist',
      );

      // Return to the library after opening its reader, then check Home.
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () => app.recent.any((item) => item.openCount >= 2),
        'repeated song open to persist in Recent',
      );
      expect(find.text(_title), findsWidgets);
      expect(app.recent, isNotEmpty);
      expect(
        find.byKey(const ValueKey('header-overflow-menu')),
        findsOneWidget,
      );
      expect(find.text('Recent songs'), findsNothing);
      await tester.tap(find.text('Songs'));
      await tester.pumpAndSettle();
      await tester.tap(_homeMode('library'));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsWidgets);
      await _capture(binding, '20_library_populated');
      await tester.tap(_homeMode('recent'));
      await tester.pumpAndSettle();
      if (find.byTooltip('Clear search text').evaluate().isNotEmpty) {
        await tester.tap(_iconButtonWithTooltip('Clear search text'));
        await tester.pumpAndSettle();
      }
      // Repeated visits are grouped into one Recent row with an open count.
      expect(app.recent, hasLength(1));
      expect(app.recent.single.openCount, 2);
      _expectHomeModeCount('recent', 1);
      await _capture(binding, '21_home_recent_populated');
      await tester.tap(_homeMode('library'));
      await tester.pumpAndSettle();
      final favoritesFilter = find.descendant(
        of: find.byKey(const ValueKey('favorites-filter-button')),
        matching: find.byType(IconButton),
      );
      await tester.tap(favoritesFilter);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<VerseHomeScreen>(find.byType(VerseHomeScreen))
            .state
            .homeListMode
            .name,
        'library',
      );
      expect(
        tester
            .widget<VerseHomeScreen>(find.byType(VerseHomeScreen))
            .state
            .favoritesOnly,
        isTrue,
      );
      expect(find.text(_title), findsWidgets);
      _expectHomeModeCount('library', 1);
      // Counted tab labels retain stable mode keys.
      expect(_homeMode('library'), findsOneWidget);
      await _capture(binding, '22_home_favorites_populated');
      await tester.tap(favoritesFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setlists'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('setlists-create-shortcut')));
      await tester.pumpAndSettle();
      final setlistUi = tester
          .widget<VerseAppShell>(find.byType(VerseAppShell))
          .controller;
      final setlistName = find.byKey(
        const ValueKey('setlist-name-inline-field'),
      );
      await _waitForState(
        tester,
        () =>
            setlistUi.state.route == VerseRoute.setlistDetail &&
            setlistUi.state.editingSetlist &&
            setlistUi.state.activeSetlist != null &&
            app.setlists.isEmpty &&
            setlistName.evaluate().isNotEmpty &&
            find.text('Add songs').evaluate().isNotEmpty,
        'private new setlist draft to open in edit mode',
      );
      final draftSetlistId = setlistUi.state.activeSetlist!.id;
      expect(app.setlists, isEmpty);
      final unopenedStorage =
          (await tester.runAsync(() => repository.listSetlists()))!;
      expect(
        unopenedStorage,
        isEmpty,
        reason: 'Opening an untouched setlist must not write a placeholder.',
      );
      // Creation already opens the inline editor. A meaningful title is the
      // first write; no redundant Edit action or automatic storage is needed.
      await tester.enterText(setlistName, 'Dawn Set');
      await tester.tap(_saveButton(l10n));
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () =>
            app.setlists.length == 1 &&
            app.setlists.single.id == draftSetlistId &&
            app.setlists.single.name == 'Dawn Set' &&
            setlistUi.state.route == VerseRoute.setlistDetail &&
            !setlistUi.state.editingSetlist &&
            setlistUi.state.activeSetlist?.id == draftSetlistId &&
            find.text('Add songs').evaluate().isNotEmpty,
        'named setlist to persist once with its draft identity',
      );
      final namedStorage =
          (await tester.runAsync(() => repository.listSetlists()))!;
      expect(namedStorage, hasLength(1));
      expect(namedStorage.single.id, draftSetlistId);
      expect(namedStorage.single.name, 'Dawn Set');
      await tester.tap(find.text('Add songs'));
      final pickerSong = find.text(_title).last;
      await _waitForStableTarget(tester, pickerSong);
      await _scrollIntoView(tester, pickerSong);
      await tester.tap(pickerSong);
      await _waitForStableTarget(tester, pickerSong);
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
        reason:
            'The picker confirmation must stay above the on-screen keyboard.',
      );
      await _capture(binding, '22a_setlist_song_picker_keyboard');
      await _scrollIntoView(tester, addSelectedSongs);
      await tester.tap(addSelectedSongs);
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () => app.setlists.single.entries.length == 1,
        'first song to persist in the setlist',
      );
      expect(app.setlists.single.entries, hasLength(1));
      await tester.tap(find.text('Add songs'));
      final secondPickerSong = find.text(_title).last;
      await _waitForStableTarget(tester, secondPickerSong);
      await _scrollIntoView(tester, secondPickerSong);
      await tester.tap(secondPickerSong);
      await _waitForStableTarget(tester, secondPickerSong);
      await _scrollIntoView(tester, addSelectedSongs);
      await tester.tap(addSelectedSongs);
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () => app.setlists.single.entries.length == 2,
        'second song to persist in the setlist',
      );
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
      await _waitForState(
        tester,
        () => app.setlists.single.entries.any(
          (entry) =>
              entry.overrides['key'] == 'D' && entry.overrides['capo'] == 2,
        ),
        'setlist song key and capo overrides to persist',
      );
      await _capture(binding, '23_setlist_populated');
      await tester.tap(find.text(_title).first);
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () =>
            find.byType(PlayerScreen).evaluate().isNotEmpty &&
            tester
                    .widget<PlayerScreen>(find.byType(PlayerScreen))
                    .controller
                    .state
                    .readerKey ==
                'D#',
        'setlist entry reader to apply its key override',
      );
      final setlistPlayer = tester
          .widget<PlayerScreen>(find.byType(PlayerScreen))
          .controller;
      expect(setlistPlayer.state.readerKey, 'D#');
      await tester.tap(_iconButtonWithTooltip('Next song'));
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () => setlistPlayer.state.readerKey == 'C#',
        'next setlist entry to load',
      );
      expect(setlistPlayer.state.readerKey, 'C#');
      await tester.longPress(_iconButtonWithTooltip('Previous song'));
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () => setlistPlayer.state.readerKey == 'D#',
        'previous setlist entry to load',
      );
      expect(setlistPlayer.state.readerKey, 'D#');
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      final overrideEntryId = app.setlists.single.entries.first.id;
      final regularEntryId = app.setlists.single.entries.last.id;
      final firstRow = find.byKey(ValueKey(overrideEntryId));
      final lastRow = find.byKey(ValueKey(regularEntryId));
      expect(tester.widget(firstRow), isA<ReorderableDragStartListener>());
      final start = tester.getCenter(firstRow);
      final destination = tester.getCenter(lastRow);
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 600));
      // Send a continuous path like a finger drag. A single large pointer
      // jump can be interpreted as only one reorder slot by the native view.
      final target = destination + const Offset(0, 12);
      final step = (target - start) / 20;
      for (var index = 0; index < 20; index++) {
        await gesture.moveBy(step);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 150));
      final keyedRowsWhileHeld = find
          .byWidgetPredicate((widget) => widget is ReorderableDragStartListener)
          .evaluate()
          .map((element) => element.widget.key)
          .toList();
      debugPrint(
        'SINGBOOK_E2E_DRAG held start=$start destination=$destination '
        'keyedRows=$keyedRowsWhileHeld '
        'draggedKeyCount=${find.byKey(ValueKey(overrideEntryId)).evaluate().length}',
      );
      await _capture(binding, '23a_setlist_drag_held');
      await gesture.up();
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () =>
            app.setlists.single.entries.length == 2 &&
            app.setlists.single.entries.first.id == regularEntryId &&
            app.setlists.single.entries.last.id == overrideEntryId,
        'setlist reorder to persist',
      );
      expect(app.setlists.single.entries, hasLength(2));
      expect(app.setlists.single.entries.first.id, regularEntryId);
      expect(app.setlists.single.entries.last.id, overrideEntryId);
      expect(app.setlists.single.entries.last.overrides['key'], 'D');

      // Exercise the setlist delete confirmation through the card menu. A
      // duplicate gives us a disposable target while preserving the setlist
      // whose order and overrides are verified after remount below.
      await tester.tap(_iconButtonWithTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(
        _popupMenuWithTooltip(l10n.accessibilitySetlistMenu('Dawn Set')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () => app.setlists.length == 2,
        'duplicated setlist to persist',
      );
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
      await _waitForState(
        tester,
        () =>
            app.setlists.length == 1 &&
            app.setlists.single.id == originalSetlistId,
        'setlist deletion to persist',
      );
      expect(app.setlists, hasLength(1));
      expect(app.setlists.single.id, originalSetlistId);
      await _capture(binding, '23c_setlist_delete_confirmed');

      // Theme changes are visible and survive app persistence in the same DB.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await _capture(binding, '24_settings_light');
      final settingsUi = tester
          .widget<SettingsScreen>(find.byType(SettingsScreen))
          .controller;
      await tester.tap(find.byKey(const ValueKey('settings-menu-appearance')));
      await tester.pumpAndSettle();
      await _selectDropdown(tester, 'Theme', 'Dark');
      await _waitForState(
        tester,
        () =>
            app.settings['themeMode'] == 'dark' &&
            Theme.of(tester.element(find.byType(Scaffold).last)).brightness ==
                Brightness.dark,
        'dark theme to save and apply',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-player')));
      await tester.pumpAndSettle();
      await _selectDropdown(tester, 'Default scrolling mode', 'Timed lyrics');
      await _waitForState(
        tester,
        () =>
            app.settings['timingMode'] == 'timed' &&
            settingsUi.state.timingMode == 'timed',
        'timed lyric scrolling mode to save and apply',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-sources')));
      await tester.pumpAndSettle();
      final providerSwitch = find.widgetWithText(
        SwitchListTile,
        'Journey catalog',
      );
      await _scrollIntoView(tester, providerSwitch);
      expect(providerSwitch, findsOneWidget);
      await tester.tap(providerSwitch);
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () =>
            !app.providerEnabled(_catalogId) &&
            settingsUi.state.providers
                    .where((provider) => provider.id == _catalogId)
                    .firstOrNull
                    ?.enabled ==
                false,
        'catalog provider toggle to save and apply',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-appearance')));
      await tester.pumpAndSettle();
      await _selectDropdown(tester, 'App language', 'Українська');
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () =>
            app.settings['locale'] == 'uk' &&
            settingsUi.state.languageCode == 'uk',
        'Ukrainian locale to save and apply',
      );
      expect(
        Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
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
      controllers.add(restored);
      await tester.pumpWidget(VerseApp(controller: restored));
      await tester.pumpAndSettle();
      await _waitForState(
        tester,
        () =>
            restored.songs.length == 1 &&
            restored.setlists.length == 1 &&
            restored.settings['themeMode'] == 'dark' &&
            restored.settings['locale'] == 'uk' &&
            restored.settings['timingMode'] == 'timed' &&
            restored.settings['showChords'] == true &&
            !restored.providerEnabled(_catalogId),
        'saved settings and library to restore after app restart',
      );
      expect(restored.settings['themeMode'], 'dark');
      expect(restored.settings['locale'], 'uk');
      expect(restored.settings['timingMode'], 'timed');
      expect(restored.settings['showChords'], isTrue);
      expect(restored.providerEnabled(_catalogId), isFalse);
      expect(
        restored.songs.single.body,
        contains('Lanterns light the winding road'),
      );
      expect(restored.songs.single.body, contains(_savedLine));
      expect(restored.songs.single.favorite, isTrue);
      expect(restored.setlists.single.id, draftSetlistId);
      expect(restored.setlists.single.name, 'Dawn Set');
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
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  if (_skipScreenshots) return;
  if (await captureIosCheckpoint(name)) return;
  debugPrint('SINGBOOK_E2E_CAPTURE:$name');
  // The host driver watches logcat for this marker to capture the full device
  // frame (including Android status and navigation bars) before the next tap.
  await Future<void>.delayed(const Duration(seconds: 2));
}

Future<void> _waitForSavedReader(WidgetTester tester, AppController app) async {
  await _waitForState(
    tester,
    () {
      final editor = find.byKey(const ValueKey('editor-lyrics-input'));
      return app.songs.single.body.contains(_savedLine) &&
          find.byType(PlayerScreen).evaluate().isNotEmpty &&
          editor.evaluate().isEmpty;
    },
    'editor save to persist and return to the reader',
    timeout: const Duration(seconds: 60),
  );
}

Future<void> _waitForState(
  WidgetTester tester,
  bool Function() condition,
  String description, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  expect(condition(), isTrue, reason: 'Timed out waiting for $description');
}

Finder _iconButtonWithTooltip(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is IconButton && widget.tooltip == tooltip,
  description: 'IconButton with tooltip "$tooltip"',
);

Finder _saveButton(AppLocalizations l10n) => find.byWidgetPredicate(
  (widget) =>
      widget is IconButton &&
      widget.tooltip?.startsWith(l10n.actionSave) == true,
  description: 'Save icon button',
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

Finder _discoveryProgressCounter() => find.byWidgetPredicate(
  (widget) =>
      widget is Text && RegExp(r'^\d+/\d+$').hasMatch(widget.data ?? ''),
  description: 'discovery completed/total counter',
);

void _expectReadyCountDisplayed(WidgetTester tester, AppLocalizations l10n) {
  final count = tester
      .widget<Text>(find.byKey(const ValueKey('home-search-comparison-counts')))
      .data;
  expect([
    for (var value = 0; value <= 4; value++) l10n.searchReadyVersions(value),
  ], contains(count));
}

Future<void> _openSourceChecks(WidgetTester tester) async {
  final sourceChecks = find.byKey(const ValueKey('source-checks-button'));
  await _ensureBelowPinnedHeader(tester, sourceChecks);
  await tester.tap(sourceChecks);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('source-checks-sheet')), findsOneWidget);
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
  // The label may be a sibling of the dropdown in standard settings rows or
  // part of a compact InputDecorator on desktop. Both layouts expose the
  // control's label through Semantics, which keeps this lookup unambiguous.
  final labeledControl = find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
    description: 'settings control labeled "$label"',
  );
  final dropdown = find.descendant(
    of: labeledControl,
    matching: find.byWidgetPredicate((widget) => widget is DropdownButton),
  );
  expect(dropdown, findsOneWidget, reason: 'Dropdown for "$label".');
  await _ensureBelowPinnedHeader(tester, dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final option = find.text(value);
  // Long dropdowns such as the language picker lazily build only visible
  // options. Scroll the popup itself until the requested option is mounted.
  await tester.scrollUntilVisible(
    option,
    240,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(option.last);
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
  if (fields.evaluate().isEmpty) {
    // Comparison has its own full-height screen. Return through its visible
    // back action before starting another catalog search.
    final back = find.byType(BackButton);
    expect(back, findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();
  }
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
  await _waitForStableTarget(tester, target);
}

/// Wait for layout and keyboard insets to stop moving without requiring every
/// ticker to become idle. A focused iOS text field can keep scheduling caret
/// frames after its keyboard and viewport have settled.
Future<void> _waitForStableTarget(WidgetTester tester, Finder target) async {
  Rect? previousRect;
  double? previousInsets;
  var stableFrames = 0;
  for (var frame = 0; frame < 20 && stableFrames < 2; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
    final rect = tester.getRect(target);
    final insets = tester.view.viewInsets.bottom;
    final stable =
        previousRect != null &&
        _near(rect.left, previousRect.left) &&
        _near(rect.top, previousRect.top) &&
        _near(rect.right, previousRect.right) &&
        _near(rect.bottom, previousRect.bottom) &&
        previousInsets != null &&
        _near(insets, previousInsets);
    stableFrames = stable ? stableFrames + 1 : 0;
    previousRect = rect;
    previousInsets = insets;
  }
  expect(
    stableFrames,
    greaterThanOrEqualTo(2),
    reason: 'Target layout and keyboard insets should settle: $target',
  );
}

bool _near(double left, double right) => (left - right).abs() < 1;

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
    'mainContributorIds': contributingProviderIds(combined).toList()..sort(),
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
    capabilities: {'catalog', 'lyrics'},
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
    if (failure) throw const ProviderException('network');
    if (unavailable) throw const ProviderException('unavailable');
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final hasLyrics = fixture.returnLyricsFor(id, candidate.id);
    return SourceResult(
      candidate: candidate,
      body: hasLyrics ? body : '',
      metadata: {
        'key': 'C',
        'capo': 2,
        if (id == _chordSourceId) 'moodTags': ['reflective'],
        if (id == _lyricSourceId) 'moodTags': ['wistful'],
        if (id == _chordSourceId)
          'externalIdentifiers': {
            'catalog': ['original-work-1'],
          },
        if (id == _lyricSourceId)
          'externalIdentifiers': {
            'isrc': ['ORIGINAL-QA-1'],
          },
      },
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
