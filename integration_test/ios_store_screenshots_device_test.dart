// Original sample content in the actual app UI at the simulator's native size.
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
import 'support/ios_screenshots.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'App Store original-content screenshots',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_store_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final repository = await LibraryRepository.open(path: databasePath);
      final app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(const []),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await SystemChrome.setPreferredOrientations([]);
        app.dispose();
        await tester.runAsync(() async {
          await repository.close();
          await deleteDatabase(databasePath);
        });
      });
      const titles = [
        'Lanterns Before Sunrise',
        'Along the Quiet Road',
        'Carry the Morning',
        'A Song for the Journey',
      ];
      for (var i = 0; i < titles.length; i++) {
        await repository.saveSong(
          SongDocument(
            id: 'store-song-$i',
            title: titles[i],
            artist: 'Freevia Originals',
            body:
                '{key: C}\n{comment: Verse 1}\n[C]Lanterns mark the [G]road\n[Am]We carry songs at [F]dawn\n[C]Morning light will [G]guide us\n[F]As we travel [C]on\n\n{comment: Chorus}\n[F]Sing into the [C]morning\n[G]Let the new day [Am]rise\n[F]Every road a [C]story\n[G]Under open [C]skies',
          ),
        );
      }
      await repository.saveSetlist(
        SetlistDocument(
          id: 'store-set',
          name: 'Morning Rehearsal',
          entries: [
            for (var i = 0; i < titles.length; i++)
              SetlistEntry(id: 'store-entry-$i', songId: 'store-song-$i'),
          ],
        ),
      );
      await app.initialize();
      await app.setSetting('locale', 'en');
      await app.setSetting('themeMode', 'light');
      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();
      expect(
        tester.view.physicalSize.height,
        greaterThan(tester.view.physicalSize.width),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      await tester.tap(find.text(l10n.navSongs).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-mode-library')));
      await tester.pumpAndSettle();
      await captureIosCheckpoint('store_01_library');
      await tester.ensureVisible(find.text(titles.first));
      await tester.tap(find.text(titles.first));
      await tester.pumpAndSettle();
      await captureIosCheckpoint('store_02_reader');
      final keyPicker = find.byKey(const ValueKey('pitch-key-dropdown'));
      expect(keyPicker, findsOneWidget);
      await tester.tap(keyPicker);
      await tester.pumpAndSettle();
      final dMajor = find.byKey(const ValueKey('transpose-pitch-2'));
      expect(dMajor, findsOneWidget);
      await captureIosCheckpoint('store_02a_key_picker');
      await tester.tap(dMajor);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: keyPicker, matching: find.text('D')),
        findsOneWidget,
      );
      await captureIosCheckpoint('store_02b_transposed');
      await app.setSetting('themeMode', 'dark');
      await tester.pumpAndSettle();
      await captureIosCheckpoint('store_03_reader_dark');
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await app.setSetting('themeMode', 'light');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.navSetlists).first);
      await tester.pumpAndSettle();
      expect(find.text('Morning Rehearsal'), findsOneWidget);
      await captureIosCheckpoint('store_04_setlists');
      await tester.tap(find.text('Morning Rehearsal'));
      await tester.pumpAndSettle();
      for (var i = 0; i < titles.length; i++) {
        expect(find.byKey(ValueKey('store-entry-$i')), findsOneWidget);
      }
      await captureIosCheckpoint('store_04a_setlist_detail');
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
