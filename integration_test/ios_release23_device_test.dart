// Native iOS coverage for release 0.2.9+23. Uses a temporary library and
// original fixture content; no provider or account access is needed.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart' show deleteDatabase, getDatabasesPath;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/player/section_labels.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

import 'support/ios_screenshots.dart';

const _hostRotation = bool.fromEnvironment('SINGBOOK_HOST_ROTATION');
const _songId = 'release23-original-song';
const _setlistId = 'release23-original-setlist';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'release 23 native modes, setlist gestures, and timeline labels',
    (tester) async {
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_release23_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
      AppController? app;
      addTearDown(() async {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          app?.dispose();
          await SystemChrome.setPreferredOrientations([]);
          await tester.runAsync(() async {
            await repository.close();
            await deleteDatabase(databasePath);
          });
        }
      });

      await repository.saveSong(
        SongDocument(
          id: _songId,
          title: 'Original Release Song',
          artist: 'Freevia Original QA',
          body:
              '{comment: Intro}\n[C]Lanterns guide the morning road\n'
              '{comment: Verse 1}\n[G]We carry songs into the dawn\n'
              '{comment: Chorus}\n[F]The road is bright and clear',
          metadata: const {'key': 'C', 'durationSeconds': 180},
        ),
      );
      await repository.saveSong(
        SongDocument(
          id: 'release23-second-song',
          title: 'Original Second Song',
          artist: 'Freevia Original QA',
          body: '[Verse]\n[D]Another original line',
          metadata: const {'key': 'D', 'durationSeconds': 90},
        ),
      );
      await repository.saveSetlist(
        SetlistDocument(
          id: _setlistId,
          name: 'Original Release Set',
          entries: const [
            SetlistEntry(
              id: 'release23-c-entry',
              songId: _songId,
              overrides: {'key': 'C'},
            ),
            SetlistEntry(
              id: 'release23-second-entry',
              songId: 'release23-second-song',
            ),
            SetlistEntry(
              id: 'release23-g-entry',
              songId: _songId,
              overrides: {'key': 'G'},
            ),
          ],
        ),
      );
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(const []),
      );
      await app.initialize();
      await app.setSetting('startupSongsView', 'library');
      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      await _rotate(tester, false);
      await tester.tap(find.byKey(const ValueKey('home-mode-library')));
      await tester.pumpAndSettle();
      expect(find.text('${l10n.songsLibraryView}(2)'), findsOneWidget);
      await captureIosCheckpoint('release23_en_light_portrait_mode_count');

      // A standalone reader keeps its song when the same horizontal gesture
      // is made without an active setlist.
      await tester.tap(find.text(l10n.navSongs).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-mode-library')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Original Second Song'));
      await tester.pumpAndSettle();
      await _waitForLyrics(tester);
      final standaloneLyrics = find.byKey(
        const ValueKey('tablet-reader-content'),
      );
      await tester.drag(standaloneLyrics, const Offset(-140, 0));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original Second Song'), findsOneWidget);
      expect(find.text('Original Release Song'), findsNothing);

      // Open the setlist again and exercise both directions across repeated
      // entries with different key overrides, plus the two list boundaries.
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.navSetlists).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Original Release Set'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Original Release Song').first);
      await tester.pumpAndSettle();
      await _waitForLyrics(tester);
      final setlistLyrics = find.byKey(const ValueKey('tablet-reader-content'));
      final player = tester
          .widget<PlayerScreen>(find.byType(PlayerScreen))
          .controller;
      expect(player.state.readerKey, 'C');
      await tester.drag(setlistLyrics, const Offset(-140, 0));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original Second Song'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('tablet-reader-content')),
        const Offset(-140, 0),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original Release Song'), findsOneWidget);
      expect(player.state.readerKey, 'G');
      await tester.drag(
        find.byKey(const ValueKey('tablet-reader-content')),
        const Offset(-140, 0),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original Release Song'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('tablet-reader-content')),
        const Offset(140, 0),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original Second Song'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('tablet-reader-content')),
        const Offset(140, 0),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original Release Song'), findsOneWidget);
      expect(player.state.readerKey, 'C');
      await tester.drag(
        find.byKey(const ValueKey('tablet-reader-content')),
        const Offset(140, 0),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Original Release Song'), findsOneWidget);
      await captureIosCheckpoint(
        'release23_en_light_portrait_swipe_boundaries',
      );

      // In landscape and with large Ukrainian text, check rendered section
      // labels against their semantic names and capture the native window.
      await app.setSetting('themeMode', 'dark');
      await app.setSetting('locale', 'uk');
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      await tester.pumpAndSettle();
      await _rotate(tester, true);
      void verifyTimelineLabels() {
        final updatedL10n = AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        );
        expect(player.state.playerSections, isNotEmpty);
        final labels = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.semanticsLabel != null &&
              player.state.playerSections.any(
                (s) =>
                    localizedSectionName(updatedL10n, s.name) ==
                    widget.semanticsLabel,
              ),
        );
        expect(labels, findsWidgets);
        for (final element in labels.evaluate()) {
          final label = element.widget as Text;
          final render = element.renderObject as RenderBox;
          final painter = TextPainter(
            text: TextSpan(text: label.data, style: label.style),
            textDirection: Directionality.of(element),
            textScaler: MediaQuery.textScalerOf(element),
            locale: Localizations.localeOf(element),
            maxLines: 1,
          )..layout();
          expect(
            painter.width,
            lessThanOrEqualTo(render.size.width + 1),
            reason: 'Timeline label must fit its measured native box',
          );
          expect(label.overflow, TextOverflow.visible);
          painter.dispose();
        }
      }

      verifyTimelineLabels();
      await captureIosCheckpoint('release23_uk_dark_150_landscape_timeline');
      await app.setSetting('locale', 'ar');
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      await tester.pumpAndSettle();
      verifyTimelineLabels();
      await captureIosCheckpoint('release23_ar_dark_160_landscape_timeline');
      final arabicL10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      final seekColumn = find
          .ancestor(
            of: find.byKey(const ValueKey('player-seek-slider')),
            matching: find.byType(Column),
          )
          .first;
      final headingText = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.semanticsLabel == null &&
            widget.data ==
                localizedSectionName(
                  arabicL10n,
                  player.state.playerSections.first.name,
                ),
      );
      final heading = find.descendant(of: seekColumn, matching: headingText);
      expect(heading, findsOneWidget);
      await tester.ensureVisible(heading);
      await tester.pumpAndSettle();
      final controlsViewport = find
          .ancestor(of: heading, matching: find.byType(Scrollable))
          .first;
      final viewportRect = tester.getRect(controlsViewport);
      final headingRect = tester.getRect(heading);
      expect(headingRect.top, greaterThanOrEqualTo(viewportRect.top - 1));
      expect(headingRect.bottom, lessThanOrEqualTo(viewportRect.bottom + 1));
      await captureIosCheckpoint('release23_ar_dark_160_heading_revealed');
      await _rotate(tester, false);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

Future<void> _waitForLyrics(WidgetTester tester) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (find.byType(ChordLyricsLine).evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }
  expect(find.byType(ChordLyricsLine), findsWidgets);
}

Future<void> _rotate(WidgetTester tester, bool landscape) async {
  if (_hostRotation) {
    await SystemChrome.setPreferredOrientations([]);
    debugPrint(
      'SINGBOOK_NATIVE_ROTATE:${landscape ? 'landscape' : 'portrait'}',
    );
  } else {
    await SystemChrome.setPreferredOrientations([
      landscape
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.portraitUp,
    ]);
  }
  for (var attempt = 0; attempt < (_hostRotation ? 480 : 40); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pumpAndSettle();
    final size = tester.view.physicalSize;
    if (landscape ? size.width > size.height : size.height > size.width) {
      debugPrint('SINGBOOK_NATIVE_WINDOW:${size.width}x${size.height}');
      return;
    }
  }
  fail(
    'Native window did not rotate to ${landscape ? 'landscape' : 'portrait'}',
  );
}
