import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/comparison_details.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _capture = bool.fromEnvironment('CAPTURE_ACOUSTICBRAINZ_DETAILS');
const _version = SourceVersionData(
  id: 'acousticbrainz:recording',
  providerId: 'acousticbrainz',
  providerName: 'AcousticBrainz',
  title: 'Lantern Map',
  artist: 'June Harbor',
  sourceUrl: 'https://acousticbrainz.org/',
  metadata: {
    'acousticbrainz': {
      'recordingMbid': 'b5d7d380-f43a-4c1f-a5de-694150b093ac',
      'submissionCount': 148,
      'musicalAccuracy': 'unverified',
      'samples': [
        {
          'submissionOffset': 0,
          'estimatedBpm': 164.02,
          'estimatedKey': {'tonic': 'D#', 'scale': 'minor', 'strength': .616},
          'estimateStatus': 'unverified',
        },
        {
          'submissionOffset': 1,
          'estimatedBpm': 163.975,
          'estimatedKey': {'tonic': 'F', 'scale': 'major', 'strength': .7},
          'estimateStatus': 'unverified',
        },
      ],
    },
  },
);

void main() {
  for (final config in [
    ('phone', const Size(360, 780), 1.0, 'en', Brightness.light),
    ('large-text', const Size(360, 780), 1.8, 'en', Brightness.light),
    ('rtl-dark', const Size(390, 844), 1.2, 'ar', Brightness.dark),
    ('landscape', const Size(640, 360), 1.6, 'en', Brightness.light),
    ('uk-dark', const Size(390, 844), 1.2, 'uk', Brightness.dark),
  ]) {
    testWidgets('source estimates stay labelled and readable ${config.$1}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = config.$2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      if (_capture) {
        for (final family in ['Roboto', 'sans-serif']) {
          await (FontLoader(family)
                ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf')))
              .load();
        }
        await (FontLoader('NotoSansArabic')..addFont(
              rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      }
      final controller = FakeUiController((_) => const VerseUiState());
      addTearDown(controller.dispose);
      final theme = verseTheme(brightness: config.$5, palette: 'navy');
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: Locale(config.$4),
          localizationsDelegates: singbookLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: config.$4 == 'ar'
              ? theme.copyWith(
                  textTheme: theme.textTheme.apply(
                    fontFamily: 'NotoSansArabic',
                    fontFamilyFallback: const ['Roboto', 'sans-serif'],
                  ),
                )
              : theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(config.$3)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showComparisonVersionInfo(
                    context,
                    controller: controller,
                    version: _version,
                  ),
                  child: const Text('Open details'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open details'));
      await tester.pumpAndSettle();
      final sheet = find.byKey(const ValueKey('version-info-sheet'));
      final l10n = AppLocalizations.of(tester.element(sheet));
      await tester.scrollUntilVisible(
        find.text(l10n.sourceAnalysisHeading),
        80,
        scrollable: find
            .descendant(of: sheet, matching: find.byType(Scrollable))
            .first,
      );
      expect(find.text(l10n.sourceAnalysisHeading), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(l10n.sourceAnalysisCoverage(2, 148)),
        50,
        scrollable: find
            .descendant(of: sheet, matching: find.byType(Scrollable))
            .first,
      );
      expect(find.text(l10n.sourceAnalysisCoverage(2, 148)), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('164.02'),
        50,
        scrollable: find
            .descendant(of: sheet, matching: find.byType(Scrollable))
            .first,
      );
      expect(find.textContaining('164.02'), findsOneWidget);
      expect(find.textContaining('D#m'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('163.975'),
        50,
        scrollable: find
            .descendant(of: sheet, matching: find.byType(Scrollable))
            .first,
      );
      expect(find.textContaining('163.975'), findsOneWidget);
      expect(find.textContaining('uploaded-file'), findsNothing);
      expect(tester.takeException(), isNull);
      if (_capture) {
        await expectLater(
          find.byType(Overlay).first,
          matchesGoldenFile(
            '../../artifacts/acousticbrainz-details/${config.$1}.png',
          ),
        );
      }
    });
  }
}
