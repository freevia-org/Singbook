import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:verse_mobile/application/app_controller.dart';
import 'package:verse_mobile/data/library_repository.dart';
import 'package:verse_mobile/domain/models.dart';
import 'package:verse_mobile/domain/timing.dart';
import 'package:verse_mobile/providers/core/service.dart';
import 'package:verse_mobile/ui/verse_app.dart';

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
      await controller.initialize();
      await controller.setSetting('themeMode', 'dark');
      await controller.setSetting('locale', 'uk');
      await controller.setSetting('defaultView', 'songs');

      if (!_skipScreenshots) {
        debugPrint('SINGBOOK_DEVICE surface_conversion_start');
        await binding.convertFlutterSurfaceToImage();
        debugPrint('SINGBOOK_DEVICE surface_conversion_done');
      }
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 850);
      final originalPadding = tester.view.padding;
      final originalViewPadding = tester.view.viewPadding;
      final originalViewInsets = tester.view.viewInsets;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewInsets = FakeViewPadding.zero;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.padding = originalPadding;
        tester.view.viewPadding = originalViewPadding;
        tester.view.viewInsets = originalViewInsets;
      });

      await tester.pumpWidget(VerseApp(controller: controller));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Singbook'), findsOneWidget);
      expect(find.text('Small Hours'), findsWidgets);
      expect(
        Theme.of(tester.element(find.text('Singbook'))).brightness,
        Brightness.dark,
      );
      await _capture(binding, 'populated_library_mobile_dark_ukrainian');

      // Test logical window sizes, including a tablet split-screen window.
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in const [
        Size(800, 1280),
        Size(1280, 800),
        Size(600, 960),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        if (size.width >= 800) {
          debugPrint(
            'VERSE_TABLET_LAYOUT size=$size '
            'rail=${tester.getSize(find.byType(NavigationRail).first)} '
            'grid=${tester.getSize(find.byKey(const ValueKey('tablet-songs-grid')))} '
            'firstSong=${tester.getTopLeft(find.text('Small Hours').first)}',
          );
          expect(
            find.byKey(const ValueKey('tablet-songs-grid')),
            findsOneWidget,
          );
          expect(
            tester.getTopLeft(find.text('Small Hours').first).dx,
            lessThan(tester.getTopLeft(find.text('Z Song 0')).dx),
          );
        }
        expect(tester.takeException(), isNull, reason: 'Library at $size');
        final viewport = '${size.width.toInt()}x${size.height.toInt()}';
        await _capture(binding, 'populated_library_$viewport');

        await tester.tap(find.text('Small Hours').first);
        await tester.pumpAndSettle();
        expect(find.textContaining('The room is warm tonight'), findsWidgets);
        final lyricsList = find.ancestor(
          of: find.textContaining('The room is warm tonight').first,
          matching: find.byType(ListView),
        );
        expect(tester.getSize(lyricsList).width, lessThanOrEqualTo(960));
        expect(tester.takeException(), isNull, reason: 'Reader at $size');
        await _capture(binding, 'populated_reader_$viewport');

        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
        if (size.width >= 700) {
          expect(
            find.byKey(const ValueKey('tablet-editor-split')),
            findsOneWidget,
          );
          final titleField = find.byWidgetPredicate(
            (widget) =>
                widget is TextField && widget.controller?.text == song.title,
          );
          final bodyField = find.byWidgetPredicate(
            (widget) => widget is TextField && widget.controller?.text == body,
          );
          expect(
            tester.getRect(titleField).right,
            lessThan(tester.getRect(bodyField).left),
          );
        }
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Editor with keyboard at $size',
        );
        await _capture(binding, 'populated_editor_keyboard_$viewport');
        tester.view.viewInsets = FakeViewPadding.zero;
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
            find.byKey(const ValueKey('tablet-setlists-grid')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull, reason: 'Setlists at $size');
        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Settings at $size');
        await _capture(binding, 'populated_settings_$viewport');
        await tester.tap(find.byIcon(Icons.music_note_rounded).first);
        await tester.pumpAndSettle();
      }
      tester.platformDispatcher.clearTextScaleFactorTestValue();

      tester.view.physicalSize = const Size(850, 400);
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

      tester.view.physicalSize = const Size(400, 850);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('We sing our own refrain'), findsWidgets);
      tester.view.physicalSize = const Size(850, 400);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('The room is warm tonight'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final restored = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(const []),
      );
      await tester.pumpWidget(VerseApp(controller: restored));
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
  final image = await binding.takeScreenshot(name);
  debugPrint('SINGBOOK_E2E_CAPTURE:$name');
  await Future<void>.delayed(const Duration(seconds: 2));
  expect(image, isNotEmpty, reason: 'Screenshot $name should be captured');
}
