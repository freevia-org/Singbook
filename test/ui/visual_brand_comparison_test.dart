// Writes artifacts/singbook-brand-font-comparison.png (gitignored). Skips with
// a message when the candidate font is not present.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _bitterPath = 'assets/fonts/brand-candidates/Bitter-Bold.ttf';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final missing = File(_bitterPath).existsSync()
      ? null
      : 'skipped: $_bitterPath is not present';
  // ignore: avoid_print
  if (missing != null) print(missing);
  testWidgets('capture light and dark Singbook wordmark font comparison', (
    tester,
  ) async {
    final loaders =
        [
          ('SingbookBrand', 'assets/fonts/SingbookBrand-Bold.ttf'),
          ('SingbookSerif', 'assets/fonts/SingbookSerif-Bold.ttf'),
          ('BrandBoardSans', 'assets/fonts/NotoSans-Regular.ttf'),
        ].map((entry) async {
          final loader = FontLoader(entry.$1)
            ..addFont(rootBundle.load(entry.$2));
          await loader.load();
        });
    await Future.wait(loaders);
    final bitterLoader = FontLoader('BitterBrand')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(_bitterPath).readAsBytesSync(),
          ),
        ),
      );
    await bitterLoader.load();

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final boundaryKey = GlobalKey();
    const ink = Color(0xFF081B33);
    const paper = Color(0xFFF7F3E9);
    const blue = Color(0xFF315D82);
    const amber = Color(0xFFEFB746);
    const families = ['SingbookBrand', 'SingbookSerif', 'BitterBrand'];
    const names = ['Current · Libre Baskerville', 'Lora Bold', 'Bitter Bold'];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'BrandBoardSans'),
        home: Scaffold(
          backgroundColor: paper,
          body: RepaintBoundary(
            key: boundaryKey,
            child: Container(
              color: paper,
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Singbook brand font comparison',
                    style: TextStyle(
                      fontFamily: 'BrandBoardSans',
                      color: ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < families.length; i++) ...[
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 235,
                            child: Text(
                              names[i],
                              style: const TextStyle(
                                fontFamily: 'BrandBoardSans',
                                color: ink,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          _sample(families[i], paper, blue, ink, 'Light'),
                          const SizedBox(width: 14),
                          _sample(families[i], ink, paper, amber, 'Dark'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/branding/singbook-mark-foreground.png'),
        boundaryKey.currentContext!,
      ),
    );
    await tester.pump();
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('artifacts/singbook-brand-font-comparison.png')
        ..createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
  }, skip: missing != null);
}

Widget _sample(
  String family,
  Color background,
  Color foreground,
  Color amber,
  String theme,
) => Expanded(
  child: Container(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0x4064788A)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Row(
      children: [
        Container(
          width: 68,
          height: 68,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: foreground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset(
            'assets/branding/singbook-mark-foreground.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: family,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
                children: [
                  TextSpan(
                    text: 'Sing',
                    style: TextStyle(color: foreground),
                  ),
                  TextSpan(
                    text: 'book',
                    style: TextStyle(color: amber),
                  ),
                ],
              ),
            ),
            Text(
              '$theme · Split-color wordmark',
              style: TextStyle(
                color: foreground.withValues(alpha: .72),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);
