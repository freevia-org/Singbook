// Full native windows: no logical surface or physical-size overrides.
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
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

import 'support/ios_screenshots.dart';

const _hostRotation = bool.fromEnvironment('SINGBOOK_HOST_ROTATION');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'iOS native windows render the app across appearance and rotation',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_native_layout_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
      final app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(const []),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await SystemChrome.setPreferredOrientations([]);
        app.dispose();
        await tester.runAsync(() async {
          await repository.close();
          await deleteDatabase(databasePath);
        });
      });
      for (var i = 0; i < 9; i++) {
        await repository.saveSong(
          SongDocument(
            id: 'native-layout-$i',
            title: i == 0 ? 'A Lantern Original' : 'Rehearsal Song $i',
            artist: 'Freevia Original QA',
            body: [
              '[C]Morning light along the road',
              '[G]نحمل ضوء الصباح',
              for (var line = 1; line <= 24; line++)
                '[C]Lantern verse $line along the quiet road',
              '[G]Final lantern line',
            ].join('\n'),
          ),
        );
      }
      await repository.saveSetlist(
        SetlistDocument(
          id: 'native-layout-set',
          name: 'QA Rehearsal',
          entries: [SetlistEntry(id: 'entry', songId: 'native-layout-0')],
        ),
      );
      await app.initialize();
      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();
      for (final profile in [
        (theme: 'light', locale: 'en', scale: 1.0),
        (theme: 'dark', locale: 'uk', scale: 1.5),
        (theme: 'dark', locale: 'ar', scale: 1.6),
      ]) {
        tester.platformDispatcher.textScaleFactorTestValue = profile.scale;
        await app.setSetting('themeMode', profile.theme);
        await app.setSetting('locale', profile.locale);
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(Scaffold).first),
        );
        for (final landscape in [false, true]) {
          await _rotate(tester, landscape);
          final prefix =
              'native_${profile.locale}_${profile.theme}_${profile.scale}_${landscape ? 'landscape' : 'portrait'}';
          // Screenshot checkpoint names use a filesystem-safe alphabet.
          final name = prefix.replaceAll('.', '_');
          await tester.tap(find.text(l10n.navSongs).first);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('home-mode-library')));
          await tester.pumpAndSettle();
          expect(find.text('A Lantern Original'), findsOneWidget);
          await tester.ensureVisible(find.text('A Lantern Original'));
          await tester.pumpAndSettle();
          expect(find.text('A Lantern Original').hitTestable(), findsOneWidget);
          await captureIosCheckpoint('${name}_library');
          await tester.tap(find.text('A Lantern Original'));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Morning light along the road'),
            findsWidgets,
          );
          await captureIosCheckpoint('${name}_reader');
          final lastLine = find.byWidgetPredicate(
            (widget) =>
                widget is ChordLyricsLine &&
                widget.text.contains('Final lantern line'),
          );
          final readerScroll = find
              .ancestor(
                of: find.byType(ChordLyricsLine).first,
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            lastLine,
            250,
            scrollable: readerScroll,
            maxScrolls: 80,
          );
          await tester.pumpAndSettle();
          expect(lastLine.hitTestable(), findsOneWidget);
          await captureIosCheckpoint('${name}_reader_scrolled');
          await tester.tap(find.byIcon(Icons.edit_outlined).first);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('editor-lyrics-input')),
            findsOneWidget,
          );
          await captureIosCheckpoint('${name}_editor');
          final duration = find.widgetWithText(
            TextField,
            l10n.editorDurationField,
          );
          await tester.ensureVisible(duration);
          await tester.pumpAndSettle();
          expect(duration.hitTestable(), findsOneWidget);
          await captureIosCheckpoint('${name}_editor_metadata_scrolled');
          await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.navSetlists).first);
          await tester.pumpAndSettle();
          expect(find.text('QA Rehearsal'), findsOneWidget);
          await tester.ensureVisible(find.text('QA Rehearsal'));
          await tester.pumpAndSettle();
          expect(find.text('QA Rehearsal').hitTestable(), findsOneWidget);
          await captureIosCheckpoint('${name}_setlists');
          await tester.tap(find.text(l10n.navSettings).first);
          await tester.pumpAndSettle();
          await captureIosCheckpoint('${name}_settings');
          expect(tester.takeException(), isNull);
        }
      }
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 15)),
  );
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
