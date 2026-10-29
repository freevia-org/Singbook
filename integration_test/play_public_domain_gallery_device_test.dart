// Manual Google Play gallery capture from the v0.2.26 source tree.
// The only lyric text is documented public-domain material; no mock providers.
import 'dart:io';

import 'package:flutter/material.dart';
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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('capture public-domain Singbook gallery', (tester) async {
    final databasePath = paths.join(
      await getDatabasesPath(),
      'singbook_play_gallery_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final repository = await LibraryRepository.open(path: databasePath);
    final app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService(const []),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.runAsync(() async {
        await repository.close();
        await deleteDatabase(databasePath);
      });
    });

    // Text from the public-domain Library of Congress sources documented in
    // docs/play-store/public-domain-gallery.md. Chords are generic examples,
    // not transcriptions of a modern arrangement.
    await repository.saveSong(SongDocument(
      id: 'pd-auld-lang-syne',
      title: 'Auld Lang Syne',
      artist: 'Robert Burns',
      body: '{key: C}\n{comment: Public-domain text · Library of Congress}\n'
          '{start_of_verse}\n[C]Should auld acquaintance be forgot,\n'
          '[G]And never brought to mind?\n'
          '{end_of_verse}\n{start_of_chorus}\n'
          '[F]For auld lang syne, my dear,\n'
          '[C]For auld lang syne\n'
          '{end_of_chorus}',
    ));
    await repository.saveSong(SongDocument(
      id: 'pd-amazing-grace',
      title: 'Amazing Grace',
      artist: 'John Newton',
      body: '{key: C}\n{comment: 1779 text · Library of Congress}\n'
          '{start_of_verse}\n[C]Amazing grace! how sweet the sound\n'
          '{end_of_verse}\n{start_of_chorus}\n[F]C  F  G  C\n'
          '{end_of_chorus}',
    ));
    await repository.saveSetlist(SetlistDocument(
      id: 'pd-rehearsal',
      name: 'Public-domain rehearsal',
      entries: [
        SetlistEntry(id: 'pd-set-1', songId: 'pd-auld-lang-syne'),
        SetlistEntry(id: 'pd-set-2', songId: 'pd-amazing-grace'),
      ],
    ));
    await app.initialize();
    await app.setSetting('locale', 'en');
    await app.setSetting('themeMode', 'light');
    await tester.pumpWidget(VerseApp(controller: app));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));

    await tester.tap(find.text(l10n.navSongs).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-mode-library')));
    await tester.pumpAndSettle();
    expect(find.text('Auld Lang Syne'), findsOneWidget);
    await _capture('01-library');

    await tester.enterText(find.byType(TextField).first, 'Auld');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    expect(find.text('Auld Lang Syne'), findsOneWidget);
    await _capture('02-local-search');

    await tester.enterText(find.byType(TextField).first, '');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auld Lang Syne').first);
    await tester.pumpAndSettle();
    await _capture('03-reader');

    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.navSetlists).first);
    await tester.pumpAndSettle();
    expect(find.text('Public-domain rehearsal'), findsOneWidget);
    await _capture('04-setlists');

    await tester.tap(find.text(l10n.navSettings).first);
    await tester.pumpAndSettle();
    final appearance = find.byKey(const ValueKey('settings-menu-appearance'));
    await tester.ensureVisible(appearance);
    await tester.tap(appearance);
    await tester.pumpAndSettle();
    await _capture('05-appearance');
    expect(tester.takeException(), isNull);
  }, skip: !Platform.isAndroid, timeout: const Timeout(Duration(minutes: 6)));
}

Future<void> _capture(String name) async {
  debugPrint('SINGBOOK_E2E_CAPTURE:$name');
  // The existing host driver watches logcat and captures native pixels.
  await Future<void>.delayed(const Duration(seconds: 2));
}
