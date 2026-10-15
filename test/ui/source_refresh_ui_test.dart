import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'support/fake_controller.dart';

class _RefreshController extends FakeUiController {
  _RefreshController()
    : super(
        (_) => const VerseUiState(
          activeTab: VerseTab.settings,
          providers: [
            ProviderSettingData(
              id: 'lrclib',
              name: 'LRCLIB',
              description: 'Lyrics',
              enabled: true,
            ),
          ],
        ),
      );
  Completer<bool> response = Completer<bool>();
  int refreshCalls = 0;
  @override
  Future<bool> refreshSources() {
    refreshCalls++;
    return response.future;
  }
}

void main() {
  const captureScreenshots = bool.fromEnvironment('CAPTURE_SOURCE_REFRESH');
  for (final scenario in [
    (const Size(390, 844), const Locale('en'), 1.0),
    (const Size(390, 844), const Locale('ar'), 1.6),
    (const Size(1024, 768), const Locale('uk'), 1.3),
  ]) {
    testWidgets(
      'source refresh shows progress and completion ${scenario.$2}/${scenario.$1}',
      (tester) async {
        if (captureScreenshots) {
          await tester.runAsync(() => _loadCaptureFonts(arabic: scenario.$2.languageCode == 'ar'));
        }
        final c = _RefreshController();
        addTearDown(c.dispose);
        await pumpShell(
          tester,
          c,
          size: scenario.$1,
          locale: scenario.$2,
          textScale: scenario.$3,
        );
        final refresh = find.byKey(const ValueKey('refresh-source-list'));
        await tester.scrollUntilVisible(
          refresh,
          300,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 30,
        );
        await tester.pumpAndSettle();
        expect(refresh, findsOneWidget);
        await tester.tap(refresh);
        await tester.pump();
        expect(c.refreshCalls, 1);
        expect(tester.widget<ListTile>(refresh).onTap, isNull);
        expect(
          find.descendant(
            of: refresh,
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        c.response.complete(true);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: refresh,
            matching: find.text(l10nOf(tester).actionDone),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        if (captureScreenshots) {
          await Scrollable.ensureVisible(
            tester.element(refresh),
            alignment: .2,
          );
          await tester.pumpAndSettle();
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
              final data = await pixels.toByteData(
                format: ui.ImageByteFormat.png,
              );
              return data?.buffer.asUint8List();
            } finally {
              pixels.dispose();
            }
          });
          expect(bytes, isNotNull);
          await tester.runAsync(() async {
            final file = File(
              'artifacts/source-refresh-${scenario.$2.languageCode}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!);
          });
        }
      },
    );
  }
  testWidgets('failed refresh offers retry and keeps source switches', (
    tester,
  ) async {
    final c = _RefreshController();
    addTearDown(c.dispose);
    await pumpShell(tester, c);
    final refresh = find.byKey(const ValueKey('refresh-source-list'));
    await tester.scrollUntilVisible(
      refresh,
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await tester.pumpAndSettle();
    expect(refresh, findsOneWidget);
    await tester.tap(refresh);
    c.response.complete(false);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: refresh,
        matching: find.text(l10nOf(tester).actionRetry),
      ),
      findsOneWidget,
    );
    expect(find.text('LRCLIB'), findsOneWidget);
    expect(tester.widget<ListTile>(refresh).onTap, isNotNull);
  });
}

Future<void> _loadCaptureFonts({required bool arabic}) async {
  final sansData = arabic
      ? ByteData.sublistView(
          await File(r'C:\Windows\Fonts\arial.ttf').readAsBytes(),
        )
      : await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
  final monoData = await rootBundle.load(
    'assets/fonts/NotoSansMono-Regular.ttf',
  );
  final sans = FontLoader('sans-serif')..addFont(Future.value(sansData));
  final roboto = FontLoader('Roboto')..addFont(Future.value(sansData));
  final fixture = FontLoader('NotoSansFixture')
    ..addFont(Future.value(sansData))
    ..addFont(Future.value(boldData));
  final monospace = FontLoader('monospace')..addFont(Future.value(monoData));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  final brand = FontLoader('SingbookBrand')
    ..addFont(rootBundle.load('assets/fonts/SingbookBrand-Bold.ttf'));
  final serif = FontLoader('SingbookSerif')
    ..addFont(rootBundle.load('assets/fonts/SingbookSerif-Bold.ttf'));
  await Future.wait([
    sans.load(),
    roboto.load(),
    fixture.load(),
    monospace.load(),
    icons.load(),
    brand.load(),
    serif.load(),
  ]);
}
