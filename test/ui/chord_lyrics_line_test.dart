import 'dart:io' show Directory, File, Platform;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

const _testSansFamily = 'ChordLyricsTestSans';
const _testArabicFamily = 'ChordLyricsTestArabic';

// Keep exact comparisons on both hosts: bundled fonts still rasterize
// differently in the Windows and Linux Flutter test engines.
String _goldenPath(String name) =>
    'goldens/${Platform.isLinux ? 'linux/' : ''}chord_lyrics_line_$name.png';

const _lyricStyle = TextStyle(
  fontFamily: _testSansFamily,
  color: Color(0xff17243a),
  fontSize: 22,
  height: 1.35,
);
const _chordStyle = TextStyle(
  fontFamily: _testSansFamily,
  color: Color(0xff35678f),
  fontSize: 13,
  fontWeight: FontWeight.w700,
);
const _arabicStyle = TextStyle(
  fontFamily: _testArabicFamily,
  color: Color(0xff17243a),
  fontSize: 22,
  height: 1.35,
);

Future<void> _loadTestFonts() async {
  final sans = FontLoader(_testSansFamily)
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
  await sans.load();
  final arabic = FontLoader(_testArabicFamily)
    ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
  await arabic.load();
}

Widget _host(
  Widget child, {
  required double width,
  required double height,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      size: Size(width, height),
      textScaler: TextScaler.linear(scale),
    ),
    child: Directionality(
      textDirection: direction,
      child: Material(
        color: Colors.white,
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: width - 32, child: child),
          ),
        ),
      ),
    ),
  ),
);

ChordLyricsLine _line(
  String text,
  List<LyricChord> chords, {
  Key? key,
  TextStyle style = _lyricStyle,
}) => ChordLyricsLine(
  key: key,
  text: text,
  chords: chords,
  showChords: true,
  style: style,
  chordStyle: _chordStyle,
);

RenderParagraph _paragraph(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder);

Future<List<Rect>> _chordPixelComponents(
  WidgetTester tester,
  Finder finder,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
  final capturedImage = await tester.runAsync(
    () => boundary.toImage(pixelRatio: 1),
  );
  expect(capturedImage, isNotNull);
  final image = capturedImage!;
  try {
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    expect(data, isNotNull);
    final pixels = data!;
    final activeColumns = <int>[];
    for (var x = 0; x < image.width; x++) {
      var hasChordPixel = false;
      for (var y = 0; y < image.height && !hasChordPixel; y++) {
        final offset = (y * image.width + x) * 4;
        final red = pixels.getUint8(offset);
        final green = pixels.getUint8(offset + 1);
        final blue = pixels.getUint8(offset + 2);
        hasChordPixel = blue > red + 35 && blue > green + 15;
      }
      if (hasChordPixel) activeColumns.add(x);
    }
    final components = <Rect>[];
    for (var cursor = 0; cursor < activeColumns.length;) {
      final left = activeColumns[cursor];
      var right = left;
      cursor++;
      while (cursor < activeColumns.length &&
          activeColumns[cursor] == right + 1) {
        right = activeColumns[cursor++];
      }
      var top = image.height;
      var bottom = -1;
      for (var x = left; x <= right; x++) {
        for (var y = 0; y < image.height; y++) {
          final offset = (y * image.width + x) * 4;
          final red = pixels.getUint8(offset);
          final green = pixels.getUint8(offset + 1);
          final blue = pixels.getUint8(offset + 2);
          if (blue > red + 35 && blue > green + 15) {
            top = y < top ? y : top;
            bottom = y > bottom ? y : bottom;
          }
        }
      }
      components.add(
        Rect.fromLTRB(
          left.toDouble(),
          top.toDouble(),
          right + 1.0,
          bottom + 1.0,
        ),
      );
    }
    return components;
  } finally {
    image.dispose();
  }
}

Future<Rect> _chordPixelBounds(WidgetTester tester, Finder finder) async {
  final components = await _chordPixelComponents(tester, finder);
  expect(components, isNotEmpty, reason: 'chord pixels exist');
  return Rect.fromLTRB(
    components.map((rect) => rect.left).reduce((a, b) => a < b ? a : b),
    components.map((rect) => rect.top).reduce((a, b) => a < b ? a : b),
    components.map((rect) => rect.right).reduce((a, b) => a > b ? a : b),
    components.map((rect) => rect.bottom).reduce((a, b) => a > b ? a : b),
  );
}

Future<void> _saveChordCapture(
  WidgetTester tester,
  Finder finder,
  String name,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
  final saved = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return false;
      final directory = Directory('artifacts/chord-only-captures');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(data.buffer.asUint8List());
      return true;
    } finally {
      image.dispose();
    }
  });
  expect(saved, isTrue, reason: 'capture $name is saved for visual review');
}

List<Rect> _glyphBoxes(RenderParagraph paragraph, int start, int end) =>
    paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end),
        )
        .map((box) => box.toRect())
        .toList();

void _expectSameGraphemeBoxes(
  RenderParagraph expected,
  RenderParagraph actual,
  String text,
) {
  var offset = 0;
  for (final grapheme in text.characters) {
    final end = offset + grapheme.length;
    final expectedBoxes = _glyphBoxes(expected, offset, end);
    final actualBoxes = _glyphBoxes(actual, offset, end);
    expect(
      actualBoxes.length,
      expectedBoxes.length,
      reason: 'grapheme $offset',
    );
    for (var index = 0; index < expectedBoxes.length; index++) {
      const subpixelTolerance = .25;
      expect(
        actualBoxes[index].left,
        closeTo(expectedBoxes[index].left, subpixelTolerance),
        reason: 'grapheme $offset left edge',
      );
      expect(
        actualBoxes[index].right,
        closeTo(expectedBoxes[index].right, subpixelTolerance),
        reason: 'grapheme $offset right edge',
      );
      expect(
        actualBoxes[index].top,
        closeTo(expectedBoxes[index].top, subpixelTolerance),
        reason: 'grapheme $offset top edge',
      );
      expect(
        actualBoxes[index].bottom,
        closeTo(expectedBoxes[index].bottom, subpixelTolerance),
        reason: 'grapheme $offset bottom edge',
      );
    }
    offset = end;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadTestFonts();
  });

  testWidgets('chords preserve lyric glyph positions and natural wrapping', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const text = 'A bright orange melody carries onward with a quiet refrain';
    final anchors = [2, 17, 38];
    for (final scenario in [
      (width: 360.0, height: 760.0, scale: 1.0),
      (width: 360.0, height: 250.0, scale: 1.0),
      (width: 250.0, height: 720.0, scale: 1.0),
      (width: 250.0, height: 720.0, scale: 2.0),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(scenario.width, scenario.height);
      await tester.pumpWidget(
        _host(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Offstage(
                offstage: true,
                child: Text(
                  text,
                  key: const ValueKey('plain'),
                  style: _lyricStyle,
                ),
              ),
              const SizedBox(height: 12),
              RepaintBoundary(
                key: const ValueKey('captured-line'),
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: _line(text, [
                    for (var index = 0; index < anchors.length; index++)
                      LyricChord(
                        graphemeOffset: anchors[index],
                        symbol: ['C', 'Am', 'G'][index],
                      ),
                  ], key: const ValueKey('chord-line')),
                ),
              ),
            ],
          ),
          width: scenario.width,
          height: scenario.height,
          scale: scenario.scale,
        ),
      );

      final baseline = _paragraph(
        tester,
        find.byKey(const ValueKey('plain'), skipOffstage: false),
      );
      final chordText = _paragraph(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('chord-line')),
          matching: find.byType(Text),
        ),
      );
      expect(chordText.size.width, baseline.size.width);
      _expectSameGraphemeBoxes(baseline, chordText, text);

      final componentSize = tester.getSize(
        find.byKey(const ValueKey('chord-line')),
      );
      expect(componentSize.width, baseline.size.width);
      expect(componentSize.height, greaterThan(baseline.size.height));
      if (scenario.scale == 2) {
        expect(
          componentSize.height - baseline.size.height,
          greaterThan(3 * (_chordStyle.fontSize ?? 13)),
          reason: 'each chord on a wrapped visual line needs its own lane',
        );
        await expectLater(
          find.byKey(const ValueKey('captured-line')),
          matchesGoldenFile(_goldenPath('wrapped_large')),
        );
      } else if (scenario.width == 360 && scenario.height == 250) {
        await expectLater(
          find.byKey(const ValueKey('captured-line')),
          matchesGoldenFile(_goldenPath('landscape')),
        );
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('emoji, combining marks and RTL retain grapheme anchors', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const unicodeText = 'A👩🏽‍🎤e\u0301B sings softly';
    const rtlText = 'مرحبا بالعالم الهادئ';
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 760);
    await tester.pumpWidget(
      _host(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Offstage(
              offstage: true,
              child: Text(
                unicodeText,
                key: const ValueKey('unicode-plain'),
                style: _lyricStyle,
              ),
            ),
            _line(unicodeText, const [
              LyricChord(graphemeOffset: 1, symbol: 'D'),
              LyricChord(graphemeOffset: 3, symbol: 'Em'),
            ], key: const ValueKey('unicode-line')),
            const SizedBox(height: 20),
            Offstage(
              offstage: true,
              child: Text(
                rtlText,
                key: const ValueKey('rtl-plain'),
                style: _arabicStyle,
              ),
            ),
            RepaintBoundary(
              key: const ValueKey('unicode-rtl-capture'),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: _line(
                  rtlText,
                  const [
                    LyricChord(graphemeOffset: 0, symbol: 'Am'),
                    LyricChord(graphemeOffset: 7, symbol: 'G'),
                  ],
                  key: const ValueKey('rtl-line'),
                  style: _arabicStyle,
                ),
              ),
            ),
          ],
        ),
        width: 400,
        height: 760,
        direction: TextDirection.rtl,
      ),
    );

    expect(find.byKey(const ValueKey('unicode-line')), findsOneWidget);
    expect(find.byKey(const ValueKey('rtl-line')), findsOneWidget);
    _expectSameGraphemeBoxes(
      _paragraph(
        tester,
        find.byKey(const ValueKey('unicode-plain'), skipOffstage: false),
      ),
      _paragraph(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('unicode-line')),
          matching: find.byType(Text),
        ),
      ),
      unicodeText,
    );
    _expectSameGraphemeBoxes(
      _paragraph(
        tester,
        find.byKey(const ValueKey('rtl-plain'), skipOffstage: false),
      ),
      _paragraph(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('rtl-line')),
          matching: find.byType(Text),
        ),
      ),
      rtlText,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('unicode-line'))).height,
      greaterThan(0),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('rtl-line'))).height,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('unicode-rtl-capture')),
      matchesGoldenFile(_goldenPath('rtl')),
    );
  });

  testWidgets('transposed chord symbols keep the original lyric anchors', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const text = 'A simple melody carries onward';
    const original = [
      LyricChord(graphemeOffset: 0, symbol: 'C'),
      LyricChord(graphemeOffset: 9, symbol: 'Am'),
    ];
    const transposed = [
      LyricChord(graphemeOffset: 0, symbol: 'D'),
      LyricChord(graphemeOffset: 9, symbol: 'Bm'),
    ];
    await tester.pumpWidget(
      _host(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(text, original, key: const ValueKey('original')),
            _line(text, transposed, key: const ValueKey('transposed')),
          ],
        ),
        width: 400,
        height: 300,
      ),
    );

    final originalText = _paragraph(
      tester,
      find.descendant(
        of: find.byKey(const ValueKey('original')),
        matching: find.byType(Text),
      ),
    );
    final transposedText = _paragraph(
      tester,
      find.descendant(
        of: find.byKey(const ValueKey('transposed')),
        matching: find.byType(Text),
      ),
    );
    _expectSameGraphemeBoxes(originalText, transposedText, text);
    expect(
      original.map((chord) => chord.graphemeOffset),
      transposed.map((chord) => chord.graphemeOffset),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('original'))).height,
      closeTo(
        tester.getSize(find.byKey(const ValueKey('transposed'))).height,
        .01,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('nearby long chords use separate vertical collision rows', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const text = 'A bright melody carries onward';
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 320);
    await tester.pumpWidget(
      _host(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Offstage(
              offstage: true,
              child: Text(
                text,
                key: const ValueKey('collision-plain'),
                style: _lyricStyle,
              ),
            ),
            RepaintBoundary(
              key: const ValueKey('collision-capture'),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: _line(text, const [
                  LyricChord(graphemeOffset: 2, symbol: 'F#dim7'),
                  LyricChord(graphemeOffset: 3, symbol: 'Cmaj7'),
                  LyricChord(graphemeOffset: 18, symbol: 'Am'),
                ], key: const ValueKey('collision-line')),
              ),
            ),
          ],
        ),
        width: 360,
        height: 320,
      ),
    );

    final baseline = _paragraph(
      tester,
      find.byKey(const ValueKey('collision-plain'), skipOffstage: false),
    );
    final chordText = _paragraph(
      tester,
      find.descendant(
        of: find.byKey(const ValueKey('collision-line')),
        matching: find.byType(Text),
      ),
    );
    _expectSameGraphemeBoxes(baseline, chordText, text);
    expect(
      tester.getSize(find.byKey(const ValueKey('collision-line'))).height -
          baseline.size.height,
      greaterThan(2 * (_chordStyle.fontSize ?? 13)),
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('collision-capture')),
      matchesGoldenFile(_goldenPath('collision')),
    );
  });

  testWidgets('chord-only and whitespace rows keep their anchor spacing', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 340);
    await tester.pumpWidget(
      _host(
        RepaintBoundary(
          key: const ValueKey('chord-rows-capture'),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RepaintBoundary(
                  key: const ValueKey('chord-only-pixels'),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: _line('', const [
                      LyricChord(graphemeOffset: 0, symbol: 'C'),
                      LyricChord(graphemeOffset: 0, symbol: 'G'),
                    ], key: const ValueKey('chord-only')),
                  ),
                ),
                RepaintBoundary(
                  key: const ValueKey('space-only-pixels'),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: _line('          ', const [
                      LyricChord(graphemeOffset: 1, symbol: 'F'),
                      LyricChord(graphemeOffset: 6, symbol: 'G'),
                    ], key: const ValueKey('space-only')),
                  ),
                ),
                RepaintBoundary(
                  key: const ValueKey('rtl-space-pixels'),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: _line(
                        '          ',
                        const [
                          LyricChord(graphemeOffset: 1, symbol: 'F'),
                          LyricChord(graphemeOffset: 6, symbol: 'Am'),
                        ],
                        key: const ValueKey('rtl-space-only'),
                        style: _arabicStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        width: 360,
        height: 340,
      ),
    );

    final chordOnlySize = tester.getSize(
      find.byKey(const ValueKey('chord-only')),
    );
    expect(chordOnlySize.height, greaterThan(0));
    expect(
      chordOnlySize.height,
      lessThan(55),
      reason: 'coincident chord-only symbols share a horizontal row',
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('space-only'))).height,
      greaterThan(0),
    );
    final coincidentBounds = await _chordPixelBounds(
      tester,
      find.byKey(const ValueKey('chord-only-pixels')),
    );
    final spacedBounds = await _chordPixelBounds(
      tester,
      find.byKey(const ValueKey('space-only-pixels')),
    );
    final spacedComponents = await _chordPixelComponents(
      tester,
      find.byKey(const ValueKey('space-only-pixels')),
    );
    expect(spacedComponents, hasLength(2));
    expect(
      spacedBounds.width,
      greaterThan(coincidentBounds.width + 5),
      reason: 'F and G retain wider source gaps between their anchors',
    );
    expect(
      spacedBounds.height,
      lessThan(20),
      reason: 'the two whitespace-anchored chords share one baseline',
    );
    final spaceText = _paragraph(
      tester,
      find.descendant(
        of: find.byKey(const ValueKey('space-only')),
        matching: find.byType(Text),
      ),
    );
    final firstSpace = _glyphBoxes(spaceText, 1, 2).single;
    final sixthSpace = _glyphBoxes(spaceText, 6, 7).single;
    final captureOrigin = tester.getTopLeft(
      find.byKey(const ValueKey('space-only-pixels')),
    );
    final textOrigin = tester.getTopLeft(
      find.descendant(
        of: find.byKey(const ValueKey('space-only')),
        matching: find.byType(Text),
      ),
    );
    final textOffset = textOrigin.dx - captureOrigin.dx;
    expect(
      spacedComponents[0].left,
      closeTo(textOffset + firstSpace.left, 3),
      reason: 'F begins at the first selected prefix space',
    );
    expect(
      spacedComponents[1].left,
      closeTo(textOffset + sixthSpace.left, 3),
      reason: 'G begins at the sixth selected prefix space',
    );
    final rtlSpaceBounds = await _chordPixelBounds(
      tester,
      find.byKey(const ValueKey('rtl-space-pixels')),
    );
    expect(rtlSpaceBounds.width, greaterThan(20));
    expect(
      rtlSpaceBounds.height,
      lessThan(20),
      reason: 'RTL whitespace anchors remain on one baseline',
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('chord-rows-capture')),
      matchesGoldenFile(_goldenPath('chord_only')),
    );
  });

  testWidgets(
    'dense chord-only intro keeps its four-chord progression in one row',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(420, 180);
        await tester.pumpWidget(
          _host(
            RepaintBoundary(
              key: const ValueKey('dense-intro-capture'),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: _line('               ', const [
                  LyricChord(graphemeOffset: 0, symbol: 'F#m7'),
                  LyricChord(graphemeOffset: 5, symbol: 'A'),
                  LyricChord(graphemeOffset: 8, symbol: 'Esus4'),
                  LyricChord(graphemeOffset: 15, symbol: 'B7sus4'),
                ], key: const ValueKey('dense-intro-line')),
              ),
            ),
            width: 420,
            height: 180,
          ),
        );

        final bounds = await _chordPixelBounds(
          tester,
          find.byKey(const ValueKey('dense-intro-capture')),
        );
        await _saveChordCapture(
          tester,
          find.byKey(const ValueKey('dense-intro-capture')),
          'dense-ltr',
        );
        expect(
          bounds.height,
          lessThan(20),
          reason: 'all four chord labels fit on the same intro row',
        );
        expect(find.bySemanticsLabel('F#m7, A, Esus4, B7sus4'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'chord-only minimum gap follows chord font at 100 and 200 percent in LTR and RTL',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 160);

      for (final scale in [1.0, 2.0]) {
        for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
          await tester.pumpWidget(
            _host(
              RepaintBoundary(
                key: const ValueKey('font-relative-gap-capture'),
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Directionality(
                    textDirection: direction,
                    child: _line('', const [
                      LyricChord(graphemeOffset: 0, symbol: 'C'),
                      LyricChord(graphemeOffset: 0, symbol: 'G'),
                    ]),
                  ),
                ),
              ),
              width: 320,
              height: 120,
              scale: scale,
            ),
          );

          final components = await _chordPixelComponents(
            tester,
            find.byKey(const ValueKey('font-relative-gap-capture')),
          );
          expect(components, hasLength(2));
          final visibleGap = components[1].left - components[0].right;
          final spacing = TextPainter(
            text: const TextSpan(text: '  ', style: _chordStyle),
            textDirection: direction,
            textScaler: TextScaler.linear(scale),
          )..layout();
          final twoSpaceWidth = spacing.width;
          spacing.dispose();
          expect(
            visibleGap,
            greaterThanOrEqualTo(twoSpaceWidth - 1),
            reason:
                'two chord-font spaces remain visible at ${scale}x in $direction',
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('dense four-chord intro stays ordered at 200 percent', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(420, 220);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          RepaintBoundary(
            key: const ValueKey('dense-intro-200-capture'),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white),
              child: _line('               ', const [
                LyricChord(graphemeOffset: 0, symbol: 'F#m7'),
                LyricChord(graphemeOffset: 5, symbol: 'A'),
                LyricChord(graphemeOffset: 8, symbol: 'Esus4'),
                LyricChord(graphemeOffset: 15, symbol: 'B7sus4'),
              ], key: const ValueKey('dense-intro-200-line')),
            ),
          ),
          width: 420,
          height: 220,
          scale: 2,
        ),
      );
      final bounds = await _chordPixelBounds(
        tester,
        find.byKey(const ValueKey('dense-intro-200-capture')),
      );
      await _saveChordCapture(
        tester,
        find.byKey(const ValueKey('dense-intro-200-capture')),
        'dense-ltr-200',
      );
      expect(bounds.height, lessThan(25));
      expect(find.bySemanticsLabel('F#m7, A, Esus4, B7sus4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'narrow large-text chord-only rows wrap labels without clipping',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(180, 420);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            RepaintBoundary(
              key: const ValueKey('narrow-intro-capture'),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: _line('               ', const [
                  LyricChord(graphemeOffset: 0, symbol: 'F#add13(b9)/G'),
                  LyricChord(graphemeOffset: 5, symbol: 'A'),
                  LyricChord(graphemeOffset: 8, symbol: 'Esus4'),
                  LyricChord(graphemeOffset: 15, symbol: 'B7sus4'),
                ], key: const ValueKey('narrow-intro-line')),
              ),
            ),
            width: 180,
            height: 420,
            scale: 2,
          ),
        );

        final bounds = await _chordPixelBounds(
          tester,
          find.byKey(const ValueKey('narrow-intro-capture')),
        );
        await _saveChordCapture(
          tester,
          find.byKey(const ValueKey('narrow-intro-capture')),
          'narrow-large-text',
        );
        final lineSize = tester.getSize(
          find.byKey(const ValueKey('narrow-intro-line')),
        );
        expect(bounds.height, greaterThan(40));
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(lineSize.width));
        expect(
          find.bySemanticsLabel('F#add13(b9)/G, A, Esus4, B7sus4'),
          findsOneWidget,
          reason: 'wrapping keeps every complete chord symbol accessible',
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'RTL dense chord-only intro starts at the right and wraps inward',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(420, 420);
      await tester.pumpWidget(
        _host(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(
                key: const ValueKey('rtl-dense-wide-capture'),
                child: SizedBox(
                  width: 420,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: _line(
                        '               ',
                        const [
                          LyricChord(graphemeOffset: 0, symbol: 'F#m7'),
                          LyricChord(graphemeOffset: 5, symbol: 'A'),
                          LyricChord(graphemeOffset: 8, symbol: 'Esus4'),
                          LyricChord(graphemeOffset: 15, symbol: 'B7sus4'),
                        ],
                        key: const ValueKey('rtl-dense-wide-line'),
                      ),
                    ),
                  ),
                ),
              ),
              RepaintBoundary(
                key: const ValueKey('rtl-dense-narrow-capture'),
                child: SizedBox(
                  width: 140,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: _line(
                        '               ',
                        const [
                          LyricChord(
                            graphemeOffset: 0,
                            symbol: 'F#add13(b9)/G',
                          ),
                          LyricChord(graphemeOffset: 5, symbol: 'A'),
                          LyricChord(graphemeOffset: 8, symbol: 'Esus4'),
                          LyricChord(graphemeOffset: 15, symbol: 'B7sus4'),
                        ],
                        key: const ValueKey('rtl-dense-narrow-line'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          width: 420,
          height: 420,
          scale: 2,
        ),
      );

      final wideBounds = await _chordPixelBounds(
        tester,
        find.byKey(const ValueKey('rtl-dense-wide-capture')),
      );
      await _saveChordCapture(
        tester,
        find.byKey(const ValueKey('rtl-dense-wide-capture')),
        'dense-rtl',
      );
      final wideLineSize = tester.getSize(
        find.byKey(const ValueKey('rtl-dense-wide-line')),
      );
      expect(wideBounds.height, lessThan(25));
      expect(wideBounds.right, closeTo(wideLineSize.width, 3));

      final narrowBounds = await _chordPixelBounds(
        tester,
        find.byKey(const ValueKey('rtl-dense-narrow-capture')),
      );
      await _saveChordCapture(
        tester,
        find.byKey(const ValueKey('rtl-dense-narrow-capture')),
        'narrow-rtl',
      );
      final narrowLineSize = tester.getSize(
        find.byKey(const ValueKey('rtl-dense-narrow-line')),
      );
      expect(narrowBounds.height, greaterThan(wideBounds.height));
      expect(narrowBounds.left, greaterThanOrEqualTo(0));
      expect(narrowBounds.right, lessThanOrEqualTo(narrowLineSize.width));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('semantics include visible chords in lyric anchor order', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var showChords = true;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChordLyricsLine(
                  key: const ValueKey('spoken-line'),
                  text: 'Amazing grace always',
                  // Deliberately reverse input order; speech follows the lyric
                  // anchors and moves a mid-word chord to the word boundary.
                  chords: const [
                    LyricChord(graphemeOffset: 8, symbol: 'G'),
                    LyricChord(graphemeOffset: 3, symbol: 'C'),
                  ],
                  showChords: showChords,
                  style: _lyricStyle,
                  chordStyle: _chordStyle,
                ),
                ChordLyricsLine(
                  key: const ValueKey('spoken-override'),
                  text: 'Full lyric words',
                  chords: const [LyricChord(graphemeOffset: 0, symbol: 'Am')],
                  showChords: true,
                  style: _lyricStyle,
                  chordStyle: _chordStyle,
                  semanticsLabel: 'Custom spoken description',
                ),
                ChordLyricsLine(
                  key: const ValueKey('spoken-chord-only'),
                  text: '',
                  chords: const [
                    LyricChord(graphemeOffset: 0, symbol: 'C'),
                    LyricChord(graphemeOffset: 0, symbol: 'G'),
                  ],
                  showChords: true,
                  style: _lyricStyle,
                  chordStyle: _chordStyle,
                ),
                TextButton(
                  key: const ValueKey('toggle-spoken-chords'),
                  onPressed: () => setState(() => showChords = !showChords),
                  child: const Text('Toggle chords'),
                ),
              ],
            ),
          ),
          width: 360,
          height: 340,
        ),
      );

      expect(find.bySemanticsLabel('C Amazing G grace always'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Custom spoken description'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('C, G'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('toggle-spoken-chords')));
      await tester.pump();
      expect(find.bySemanticsLabel('Amazing grace always'), findsOneWidget);
      expect(find.bySemanticsLabel('C Amazing G grace always'), findsNothing);
      expect(
        find.bySemanticsLabel('Custom spoken description'),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'empty RTL chord-only rows place coincident chords at right edge',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 180);
      await tester.pumpWidget(
        _host(
          RepaintBoundary(
            key: const ValueKey('rtl-empty-chord-capture'),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: _line('', const [
                  LyricChord(graphemeOffset: 0, symbol: 'C'),
                  LyricChord(graphemeOffset: 0, symbol: 'G'),
                ], key: const ValueKey('rtl-empty-chord-line')),
              ),
            ),
          ),
          width: 360,
          height: 180,
        ),
      );

      final bounds = await _chordPixelBounds(
        tester,
        find.byKey(const ValueKey('rtl-empty-chord-capture')),
      );
      final components = await _chordPixelComponents(
        tester,
        find.byKey(const ValueKey('rtl-empty-chord-capture')),
      );
      expect(components, hasLength(2));
      expect(
        bounds.height,
        lessThan(20),
        reason: 'coincident chords share a row',
      );
      expect(
        components[0].right,
        lessThanOrEqualTo(components[1].left),
        reason: 'the coincident chord labels occupy separate horizontal slots',
      );
      expect(components[0].top, closeTo(components[1].top, 1));
      expect(components[0].bottom, closeTo(components[1].bottom, 1));
      expect(
        bounds.right,
        closeTo(
          tester
              .getSize(find.byKey(const ValueKey('rtl-empty-chord-line')))
              .width,
          3,
        ),
        reason:
            'empty RTL rows anchor the chord run at the available right edge',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
