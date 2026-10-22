import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  for (final locale in const [Locale('bg'), Locale('ar')]) {
    for (final size in const [Size(360, 800), Size(700, 360)]) {
      testWidgets('plain key and controls stay readable at 2x: $locale $size', (
        tester,
      ) async {
        for (final (family, asset) in [
          ('KeyLabelFixture', 'assets/fonts/NotoSans-Regular.ttf'),
          ('KeyLabelArabic', 'assets/fonts/NotoSansArabic-Regular.ttf'),
        ]) {
          await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
        }
        final controller = FakeUiController(
          (_) => const VerseUiState(
            route: VerseRoute.reader,
            song: SongCardData(
              id: 'key-study',
              title: 'Cadence study',
              artist: 'An intentionally long synthetic artist name',
              album: 'An intentionally long synthetic collection name',
              hasChords: true,
              durationSeconds: 240,
            ),
            readerKey: 'E',
            readerKeyEstimated: true,
            songLines: [
              LyricLineData(id: 'one', text: 'An original rehearsal phrase'),
            ],
          ),
        );
        addTearDown(controller.dispose);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final theme = verseTheme(
          brightness: Brightness.light,
          palette: 'navy',
          fontFamily: 'KeyLabelFixture',
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: singbookLocalizationsDelegates,
            theme: theme.copyWith(
              textTheme: theme.textTheme.apply(
                fontFamily: 'KeyLabelFixture',
                fontFamilyFallback: const ['KeyLabelArabic'],
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(body: PlayerScreen(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PlayerScreen)),
        );
        expect(find.byTooltip('${l10n.playerEstimatedKey}: E'), findsOneWidget);
        final keyLabel = find.byKey(const ValueKey('pitch-key-dropdown-label'));
        final semantics = tester.widget<Semantics>(keyLabel);
        expect(
          semantics.properties.label,
          '${l10n.readerTranspose}, ${l10n.playerEstimatedKey}: E',
        );
        expect(semantics.properties.button, isTrue);
        final keyText = find.descendant(of: keyLabel, matching: find.text('E'));
        expect(keyText, findsOneWidget);
        expect(find.text('≈ E'), findsNothing);
        final paragraph = tester.renderObject<RenderParagraph>(keyText);
        final boxes = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        );
        expect(
          boxes,
          isNotEmpty,
          reason: 'The key value must not be ellipsized',
        );
        for (final box in boxes) {
          expect(box.bottom, lessThanOrEqualTo(paragraph.size.height));
        }
        for (final control in [
          find.byKey(const ValueKey('pitch-key-dropdown')),
          find.byKey(const ValueKey('scroll-speed-toggle')),
          find.byKey(const ValueKey('start-lyric-scroll')),
        ]) {
          await Scrollable.ensureVisible(
            tester.element(control),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          expect(control.hitTestable(), findsOneWidget);
          expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
          final paragraphs = find.descendant(
            of: control,
            matching: find.byType(Text),
          );
          for (final element in paragraphs.evaluate()) {
            final text = element.renderObject! as RenderParagraph;
            expect(text.didExceedMaxLines, isFalse);
            final glyphs = text.getBoxesForSelection(
              TextSelection(
                baseOffset: 0,
                extentOffset: text.text.toPlainText().length,
              ),
            );
            expect(glyphs, isNotEmpty);
            for (final glyph in glyphs) {
              // Natural font ascent/descent can extend by a fractional pixel
              // beyond the rounded paragraph box. The whole glyph must remain
              // inside the actual button, including any FittedBox transform.
              final visibleGlyph = Rect.fromPoints(
                text.localToGlobal(Offset(glyph.left, glyph.top)),
                text.localToGlobal(Offset(glyph.right, glyph.bottom)),
              );
              final bounds = tester.getRect(control);
              final description =
                  '${text.text.toPlainText()}: $visibleGlyph in $bounds';
              expect(
                visibleGlyph.left,
                greaterThanOrEqualTo(bounds.left),
                reason: description,
              );
              expect(
                visibleGlyph.top,
                greaterThanOrEqualTo(bounds.top),
                reason: description,
              );
              expect(
                visibleGlyph.right,
                lessThanOrEqualTo(bounds.right),
                reason: description,
              );
              expect(
                visibleGlyph.bottom,
                lessThanOrEqualTo(bounds.bottom),
                reason: description,
              );
            }
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
