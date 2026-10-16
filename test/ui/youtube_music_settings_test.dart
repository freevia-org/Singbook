import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/settings/youtube_music_consent_section.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

class _ConsentController extends FakeUiController {
  _ConsentController()
    : super(
        (controller) => VerseUiState(
          activeTab: VerseTab.settings,
          providers: [
            ProviderSettingData(
              id: 'youtubemusic',
              name: 'YouTube Music',
              enabled: (controller as _ConsentController).enabled,
            ),
          ],
        ),
      );
  bool saved = false;
  bool enabled = true;
  @override
  Future<void> setProviderEnabled(String id, bool value) async {
    expect(id, 'youtubemusic');
    enabled = value;
    refresh();
  }

  int captures = 0, clears = 0;
  @override
  bool get youtubeMusicConsentSupported => true;
  @override
  bool get youtubeMusicConsentSaved => saved;
  @override
  Future<bool> completeYoutubeMusicConsent() async {
    captures++;
    saved = true;
    refresh();
    return true;
  }

  @override
  Future<bool> clearYoutubeMusicConsent() async {
    clears++;
    saved = false;
    refresh();
    return true;
  }
}

void main() {
  const capture = bool.fromEnvironment('CAPTURE_YOUTUBE_CONSENT');
  for (final scenario in [
    (const Size(390, 844), const Locale('en'), 1.0),
    (const Size(390, 844), const Locale('bg'), 1.6),
    (const Size(1024, 768), const Locale('uk'), 1.3),
    (const Size(390, 844), const Locale('ar'), 1.6),
  ]) {
    testWidgets('YouTube Music has only a source switch ${scenario.$2}', (
      tester,
    ) async {
      if (capture) {
        await tester.runAsync(
          () => _fonts(arabic: scenario.$2.languageCode == 'ar'),
        );
      }
      final controller = _ConsentController();
      addTearDown(controller.dispose);
      await pumpShell(
        tester,
        controller,
        size: scenario.$1,
        locale: scenario.$2,
        textScale: scenario.$3,
      );
      final panel = find.widgetWithText(SwitchListTile, 'YouTube Music');
      await tester.scrollUntilVisible(
        panel,
        250,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      expect(find.byType(YoutubeMusicConsentSection), findsNothing);
      expect(find.text(l10nOf(tester).youtubeConsentOpen), findsNothing);
      expect(find.text(l10nOf(tester).youtubeConsentHint), findsNothing);
      expect(find.text(l10nOf(tester).youtubeConsentClear), findsNothing);
      expect(controller.captures, 0);
      expect(controller.clears, 0);
      expect(tester.takeException(), isNull);
      if (capture) {
        await Scrollable.ensureVisible(tester.element(panel), alignment: .1);
        await tester.pumpAndSettle();
        await _capture(tester, 'youtube-simple-${scenario.$2.languageCode}');
      }
      await Scrollable.ensureVisible(tester.element(panel), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(panel);
      await tester.pumpAndSettle();
      expect(controller.enabled, isFalse);
      expect(controller.clears, 0);
      await tester.tap(panel);
      await tester.pumpAndSettle();
      expect(controller.enabled, isTrue);
      expect(controller.captures, 0);
      expect(find.text(l10nOf(tester).youtubeConsentSaved), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find
        .ancestor(
          of: find.byType(Scaffold).first,
          matching: find.byType(RepaintBoundary),
        )
        .first,
  );
  final bytes = await tester.runAsync(() async {
    final pixels = await boundary.toImage(pixelRatio: 1);
    try {
      return (await pixels.toByteData(
        format: ui.ImageByteFormat.png,
      ))?.buffer.asUint8List();
    } finally {
      pixels.dispose();
    }
  });
  expect(bytes, isNotNull);
  await tester.runAsync(() async {
    final file = File('artifacts/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!);
  });
}

Future<void> _fonts({required bool arabic}) async {
  final sansData = arabic
      ? ByteData.sublistView(
          await File(r'C:\Windows\Fonts\arial.ttf').readAsBytes(),
        )
      : await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  await Future.wait([
    (FontLoader('sans-serif')..addFont(Future.value(sansData))).load(),
    (FontLoader('Roboto')..addFont(Future.value(sansData))).load(),
    (FontLoader('NotoSansFixture')
          ..addFont(Future.value(sansData))
          ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf')))
        .load(),
    (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
    (FontLoader(
      'SingbookBrand',
    )..addFont(rootBundle.load('assets/fonts/SingbookBrand-Bold.ttf'))).load(),
    (FontLoader(
      'SingbookSerif',
    )..addFont(rootBundle.load('assets/fonts/SingbookSerif-Bold.ttf'))).load(),
  ]);
}
