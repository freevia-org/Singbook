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
        (_) => const VerseUiState(
          activeTab: VerseTab.settings,
          providers: [
            ProviderSettingData(
              id: 'youtubemusic',
              name: 'YouTube Music',
              enabled: true,
            ),
          ],
        ),
      );
  bool saved = false;
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
    testWidgets('settings session wiring and layout ${scenario.$2}', (
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
      final panel = find.byKey(const ValueKey('youtube-music-consent'));
      await tester.scrollUntilVisible(
        panel,
        250,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      final section = tester.widget<YoutubeMusicConsentSection>(
        find.byType(YoutubeMusicConsentSection),
      );
      expect(section.labels.connect, l10nOf(tester).youtubeConsentOpen);
      expect(section.labels.explanation, l10nOf(tester).youtubeConsentHint);
      expect(await section.onComplete(), isTrue);
      await tester.pumpAndSettle();
      expect(controller.captures, 1);
      expect(find.text(l10nOf(tester).youtubeConsentSaved), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (capture) {
        await Scrollable.ensureVisible(tester.element(panel), alignment: .1);
        await tester.pumpAndSettle();
        await _capture(
          tester,
          'youtube-consent-${scenario.$2.languageCode}-intro',
        );
        if (scenario.$3 > 1.4) {
          await Scrollable.ensureVisible(
            tester.element(find.byKey(const ValueKey('youtube-consent-clear'))),
            alignment: .75,
          );
          await tester.pumpAndSettle();
          await _capture(
            tester,
            'youtube-consent-${scenario.$2.languageCode}-controls',
          );
        }
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('youtube-consent-clear')),
      );
      await tester.tap(find.byKey(const ValueKey('youtube-consent-clear')));
      await tester.pumpAndSettle();
      expect(controller.clears, 1);
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
