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
    testWidgets(
      'estimated key remains visible in its localized dropdown at 2x: $locale',
      (tester) async {
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
        tester.view.physicalSize = const Size(360, 800);
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
        const prefix = '≈ ';
        expect(find.byTooltip('${l10n.playerEstimatedKey}: E'), findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('${prefix}E'),
        );
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(
            baseOffset: prefix.length,
            extentOffset: prefix.length + 1,
          ),
        );
        expect(
          boxes,
          isNotEmpty,
          reason: 'The key value must not be ellipsized',
        );
        for (final box in boxes) {
          expect(box.bottom, lessThanOrEqualTo(paragraph.size.height));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
