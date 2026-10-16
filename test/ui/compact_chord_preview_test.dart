import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

void main() {
  for (final configuration in [
    (320.0, 1.0, TextDirection.ltr),
    (140.0, 2.0, TextDirection.ltr),
    (140.0, 2.0, TextDirection.rtl),
  ]) {
    testWidgets(
      'compact instrumental preserves all painted chord ink $configuration',
      (tester) async {
        await (FontLoader('PreviewSans')
              ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf')))
            .load();
        final images = <ui.Image>[];
        addTearDown(() {
          for (final image in images) {
            image.dispose();
          }
        });
        for (final compact in [false, true]) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(configuration.$2),
                ),
                child: Directionality(
                  textDirection: configuration.$3,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: RepaintBoundary(
                      key: const ValueKey('painted-row'),
                      child: ColoredBox(
                        color: Colors.white,
                        child: SizedBox(
                          width: configuration.$1,
                          child: ChordLyricsLine(
                            text: '               ',
                            chords: const [
                              LyricChord(graphemeOffset: 0, symbol: 'F#m7'),
                              LyricChord(graphemeOffset: 5, symbol: 'A'),
                              LyricChord(graphemeOffset: 8, symbol: 'Esus4'),
                              LyricChord(graphemeOffset: 15, symbol: 'B7sus4'),
                            ],
                            showChords: true,
                            compactChordOnly: compact,
                            style: const TextStyle(
                              fontFamily: 'PreviewSans',
                              decoration: TextDecoration.none,
                              fontSize: 24,
                              height: 1.35,
                            ),
                            chordStyle: const TextStyle(
                              fontFamily: 'PreviewSans',
                              decoration: TextDecoration.none,
                              fontSize: 13,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('painted-row')),
          );
          images.add((await tester.runAsync(() => boundary.toImage()))!);
        }
        final normal = images.first;
        final compact = images.last;
        expect(compact.width, normal.width);
        expect(compact.height, lessThan(normal.height));
        final normalBytes = (await tester.runAsync(
          () => normal.toByteData(),
        ))!.buffer.asUint8List();
        final compactBytes = (await tester.runAsync(
          () => compact.toByteData(),
        ))!.buffer.asUint8List();
        expect(compactBytes, normalBytes.sublist(0, compactBytes.length));
        expect(
          normalBytes.skip(compactBytes.length).every((byte) => byte == 255),
          isTrue,
          reason:
              'Only a blank spacer may be removed, never painted chord pixels',
        );
        if (Platform.environment['SINGBOOK_CAPTURE_PREVIEWS'] == '1') {
          final directory = Directory('artifacts/swipe-preview')
            ..createSync(recursive: true);
          final png = await tester.runAsync(
            () => compact.toByteData(format: ui.ImageByteFormat.png),
          );
          File(
            '${directory.path}/compact-${configuration.$1}-${configuration.$2}-${configuration.$3.name}.png',
          ).writeAsBytesSync(png!.buffer.asUint8List());
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
