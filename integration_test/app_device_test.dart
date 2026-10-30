import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart' show deleteDatabase, getDatabasesPath;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/verse_app.dart';
import 'support/ios_screenshots.dart';

const _skipScreenshots = bool.fromEnvironment('SINGBOOK_SKIP_SCREENSHOTS');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'app renders, rotates, and restores the saved library and settings',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'verse_device_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
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
            await deleteDatabase(databasePath);
          });
        }
      });
      final body = '[C]The room is warm tonight\n[G]We sing our own refrain';
      final track = bindImportedTiming(
        parseLrc(
          '[00:01.00]The room is warm tonight\n[00:03.00]We sing our own refrain',
          sourceDocumentId: 'device-song',
        ),
        body,
      );
      final song = SongDocument(
        id: 'device-song',
        title: 'Small Hours',
        artist: 'Freevia Test',
        body: body,
        timingTracks: [track],
        activeTimingTrackId: track.id,
      );
      for (var index = 0; index < 8; index++) {
        await repository.saveSong(
          SongDocument(
            id: 'tablet-song-$index',
            title: 'Z Song $index',
            artist: 'Freevia Test',
            body: 'An original line for a tablet layout test',
          ),
        );
      }
      await repository.saveSong(song);
      await repository.saveSetlist(
        SetlistDocument(
          id: 'device-setlist',
          name: 'Evening Set',
          entries: const [
            SetlistEntry(id: 'device-entry', songId: 'device-song'),
          ],
        ),
      );

      final controller = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(const []),
      );
      controllers.add(controller);
      await controller.initialize();
      await controller.setSetting('themeMode', 'dark');
      await controller.setSetting('locale', 'uk');
      await controller.setSetting('startupSongsView', 'library');

      await binding.setSurfaceSize(const Size(400, 850));
      final padding = FakeViewPadding(
        top: 24 * tester.view.devicePixelRatio,
        bottom: 24 * tester.view.devicePixelRatio,
      );
      tester.view.padding = padding;
      tester.view.viewPadding = padding;
      tester.view.viewInsets = FakeViewPadding.zero;
      addTearDown(() async {
        await binding.setSurfaceSize(null);
        tester.view.resetPadding();
        tester.view.resetViewPadding();
        tester.view.resetViewInsets();
      });

      var viewport = const Size(400, 850);
      var activeController = controller;
      Future<void> pumpViewport({Size? size, AppController? app}) async {
        if (size != null) {
          viewport = size;
          await binding.setSurfaceSize(size);
        }
        if (app != null) activeController = app;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData.fromView(tester.view).copyWith(size: viewport),
            child: VerseApp(controller: activeController),
          ),
        );
      }

      await pumpViewport();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Singbook'), findsOneWidget);
      expect(find.text('Small Hours'), findsWidgets);
      expect(
        Theme.of(tester.element(find.text('Singbook'))).brightness,
        Brightness.dark,
      );
      await _capture('populated_library_mobile_dark_ukrainian');

      // Test logical window sizes, including a tablet split-screen window.
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in const [
        Size(800, 1280),
        Size(1280, 800),
        Size(600, 960),
      ]) {
        await pumpViewport(size: size);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        if (size.width >= 800) {
          debugPrint(
            'VERSE_TABLET_LAYOUT size=$size '
            'rail=${tester.getSize(find.byType(NavigationRail).first)} '
            'list=${tester.getSize(find.byKey(const PageStorageKey('songs-library-list')))} '
            'firstSong=${tester.getTopLeft(find.text('Small Hours').first)}',
          );
          expect(
            find.byKey(const PageStorageKey('songs-library-list')),
            findsOneWidget,
          );
          // The library is a single alphabetical list; the lazily built
          // list may not have reached the Z titles on every viewport.
          final lastSong = find.text('Z Song 0');
          if (lastSong.evaluate().isNotEmpty) {
            expect(
              tester.getTopLeft(find.text('Small Hours').first).dy,
              lessThan(tester.getTopLeft(lastSong).dy),
            );
          }
        }
        expect(tester.takeException(), isNull, reason: 'Library at $size');
        final viewport = '${size.width.toInt()}x${size.height.toInt()}';
        await _capture('populated_library_$viewport');

        await tester.tap(find.text('Small Hours').first);
        await tester.pumpAndSettle();
        expect(find.textContaining('The room is warm tonight'), findsWidgets);
        final lyricsList = find.ancestor(
          of: find.textContaining('The room is warm tonight').first,
          matching: find.byType(ListView),
        );
        expect(tester.getSize(lyricsList).width, lessThanOrEqualTo(960));
        expect(tester.takeException(), isNull, reason: 'Reader at $size');
        await _capture('populated_reader_$viewport');

        // Edit lives in the player's song-actions menu.
        await tester.tap(
          find.descendant(
            of: find.byType(PlayerScreen),
            matching: find.byIcon(Icons.more_horiz_rounded),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is PopupMenuItem<String> && widget.value == 'edit',
          ),
        );
        await tester.pumpAndSettle();
        if (size.width >= 700) {
          final titleField = find.byWidgetPredicate(
            (widget) =>
                widget is TextField && widget.controller?.text == song.title,
          );
          final bodyField = find.byKey(const ValueKey('editor-lyrics-input'));
          expect(bodyField, findsOneWidget);
          expect(
            tester.getRect(titleField).bottom,
            lessThanOrEqualTo(tester.getRect(bodyField).top),
          );
          expect(tester.getSize(bodyField).width, greaterThan(300));
        }
        tester.view.viewInsets = FakeViewPadding(
          bottom: 300 * tester.view.devicePixelRatio,
        );
        await pumpViewport();
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Editor with keyboard at $size',
        );
        await _capture('populated_editor_keyboard_$viewport');
        tester.view.viewInsets = FakeViewPadding.zero;
        await pumpViewport();
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.queue_music_rounded).first);
        await tester.pumpAndSettle();
        expect(find.text('Evening Set'), findsWidgets);
        if (size.width >= 800) {
          expect(
            find.byKey(const ValueKey('setlists-library-list')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull, reason: 'Setlists at $size');
        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Settings at $size');
        await _capture('populated_settings_$viewport');
        await tester.tap(find.byIcon(Icons.music_note_rounded).first);
        await tester.pumpAndSettle();
      }
      tester.platformDispatcher.clearTextScaleFactorTestValue();

      await pumpViewport(size: const Size(850, 400));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final landscapeMetrics = MediaQuery.of(
        tester.element(find.byType(Scaffold).first),
      );
      debugPrint(
        'VERSE_LANDSCAPE_METRICS size=${landscapeMetrics.size} '
        'padding=${landscapeMetrics.padding} '
        'viewPadding=${landscapeMetrics.viewPadding} '
        'viewInsets=${landscapeMetrics.viewInsets}',
      );
      expect(find.text('Small Hours'), findsWidgets);
      await tester.tap(find.text('Small Hours').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('The room is warm tonight'), findsWidgets);

      await pumpViewport(size: const Size(400, 850));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('We sing our own refrain'), findsWidgets);
      await pumpViewport(size: const Size(850, 400));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('The room is warm tonight'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final restored = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(const []),
      );
      controllers.add(restored);
      await pumpViewport(app: restored);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(restored.settings['themeMode'], 'dark');
      expect(restored.settings['locale'], 'uk');
      expect(restored.findSong('device-song')?.body, body);
      expect(
        restored.findSong('device-song')?.timingTracks.single.raw,
        contains('[00:01.00]'),
      );
      expect(restored.setlists.single.entries.single.songId, 'device-song');
      expect(find.text('Small Hours'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

Future<void> _capture(String name) async {
  if (_skipScreenshots) return;
  if (await captureIosCheckpoint(name)) return;
  debugPrint('SINGBOOK_E2E_CAPTURE:$name');
  await Future<void>.delayed(const Duration(seconds: 2));
}
