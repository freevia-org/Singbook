import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/transport.dart';
import 'package:singbook/ui/verse_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'macOS sandbox permits native HTTPS catalog refresh',
    (tester) async {
      await tester.runAsync(() async {
        final transport = ProviderTransport();
        try {
          final catalog = await transport.requestJson(
            Uri.parse(
              'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog.json',
            ),
          );
          expect(catalog['schemaVersion'], 1);
          expect(catalog['sources'], isNotEmpty);
        } finally {
          await transport.close();
        }
      });
    },
    skip:
        !Platform.isMacOS ||
        !const bool.fromEnvironment('SINGBOOK_MACOS_LIVE_NETWORK'),
  );

  testWidgets('macOS native Keychain and OAuth bridge', (tester) async {
    const credentials = MethodChannel(
      'org.freevia.singbook/secure_credentials',
    );
    final key = 'macos-qa-${DateTime.now().microsecondsSinceEpoch}';
    addTearDown(() => credentials.invokeMethod<void>('delete', {'key': key}));
    expect(
      await credentials.invokeMethod<String>('read', {'key': key}),
      isNull,
    );
    for (final value in ['synthetic-first', 'synthetic-updated']) {
      await credentials.invokeMethod<void>('write', {
        'key': key,
        'value': value,
      });
      expect(
        await credentials.invokeMethod<String>('read', {'key': key}),
        value,
      );
    }
    await credentials.invokeMethod<void>('delete', {'key': key});
    expect(
      await credentials.invokeMethod<String>('read', {'key': key}),
      isNull,
    );
    await expectLater(
      const MethodChannel(
        'org.freevia.singbook/oauth_browser',
      ).invokeMethod<String>('authorize', {
        'url': 'https://accounts.google.com/o/oauth2/v2/auth',
        'callbackScheme': 'unregistered-qa-scheme',
      }),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'not_configured',
        ),
      ),
    );
  }, skip: !Platform.isMacOS);

  testWidgets('macOS native persistence, PDF and visual profiles', (
    tester,
  ) async {
    final support = await getApplicationSupportDirectory();
    final directory = await Directory(
      '${support.path}/macos-qa',
    ).create(recursive: true);
    final session = DateTime.now().microsecondsSinceEpoch;
    final databasePath = '${directory.path}/isolated-$session.db';
    final song = SongDocument(
      id: 'macos-original',
      title: 'A Lantern Original',
      artist: 'Freevia QA',
      body:
          '[C]Morning light along the road\n[G]We sing a new refrain\n[C]نحمل ضوء الصباح',
    );
    var repository = await LibraryRepository.open(path: databasePath);
    await repository.saveSong(song);
    await repository.close();
    repository = await LibraryRepository.open(path: databasePath);
    final songs = await repository.listSongs();
    expect(songs.single.id, song.id);
    expect(songs.single.body, song.body);
    final app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService(const []),
    );
    await app.initialize();
    final captureKey = GlobalKey();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      app.dispose();
      await tester.runAsync(() async {
        await repository.close();
        for (final suffix in ['', '-wal', '-shm']) {
          final file = File('$databasePath$suffix');
          if (await file.exists()) await file.delete();
        }
      });
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: VerseApp(controller: app),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final path = '${directory.path}/$session-$name.png';
      await File(path).writeAsBytes(data.buffer.asUint8List());
      image.dispose();
      debugPrint('MACOS_QA_CAPTURE:$path');
    }

    for (final profile in [
      (locale: 'en', theme: 'light', scale: 1.0, size: const Size(1280, 800)),
      (locale: 'uk', theme: 'dark', scale: 1.5, size: const Size(800, 600)),
      (locale: 'ar', theme: 'dark', scale: 1.6, size: const Size(390, 720)),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = profile.size;
      await tester.binding.setSurfaceSize(profile.size);
      await app.setSetting('locale', profile.locale);
      await app.setSetting('themeMode', profile.theme);
      tester.platformDispatcher.textScaleFactorTestValue = profile.scale;
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-mode-library')));
      await tester.pumpAndSettle();
      expect(find.text(song.title), findsOneWidget);
      await capture('${profile.locale}-${profile.theme}-library');
      await tester.tap(find.text(song.title));
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        find.byType(ChordLyricsLine).evaluate().isEmpty && attempt < 40;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
      }
      expect(find.byType(ChordLyricsLine), findsWidgets);
      await capture('${profile.locale}-${profile.theme}-reader');
      final l10n = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      await tester.tap(find.byTooltip(l10n.navBack).first);
      await tester.pumpAndSettle();
    }
    await tester.runAsync(() async {
      final bytes = await createSongPdf([song]);
      final raster = await Printing.raster(bytes, pages: [0], dpi: 72).first;
      expect(raster.width, greaterThan(100));
      expect(await raster.toPng(), isNotEmpty);
    });
  }, skip: !Platform.isMacOS);
}
