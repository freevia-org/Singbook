import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/acousticbrainz_analysis.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/comparison_details.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _analysisMetadata = <String, Object?>{
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
};

const _capture = bool.fromEnvironment('CAPTURE_SOURCE_CHECKS_ANALYSIS');
const _configurations = [
  ('phone', Size(360, 780), 1.0, 'en', Brightness.light),
  ('large-text', Size(360, 780), 1.8, 'en', Brightness.light),
  ('rtl-dark', Size(390, 844), 1.2, 'ar', Brightness.dark),
  ('landscape', Size(640, 360), 1.6, 'en', Brightness.light),
  ('uk-dark', Size(390, 844), 1.2, 'uk', Brightness.dark),
];

SearchComparisonData _comparison(
  AcousticBrainzAnalysis? analysis, {
  String referenceId = 'fixture:selection',
}) => SearchComparisonData(
  reference: SearchReferenceData(
    id: referenceId,
    title: 'Lantern Map',
    artist: 'June Harbor',
  ),
  suggested: null,
  providerChecks: [
    SearchProviderCheckData(
      id: 'acousticbrainz',
      name: 'AcousticBrainz',
      state: 'found',
      recordingAnalysis: analysis,
      operations: const [
        SearchProviderOperationData(
          id: 'analysis-fetch',
          phase: 'metadata',
          state: 'found',
          query: 'Lantern Map June Harbor',
          resultCount: 1,
        ),
      ],
    ),
  ],
);

Future<void> _loadCaptureFonts() async {
  for (final family in ['Roboto', 'sans-serif']) {
    await (FontLoader(
      family,
    )..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))).load();
  }
  await (FontLoader('NotoSansArabic')
        ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf')))
      .load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

Future<void> _pumpChecksRoute(
  WidgetTester tester,
  FakeUiController controller, {
  required Size size,
  required double textScale,
  required String locale,
  required Brightness brightness,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  if (_capture) await _loadCaptureFonts();
  final theme = verseTheme(brightness: brightness, palette: 'navy');
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(locale),
      localizationsDelegates: singbookLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: locale == 'ar'
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
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showComparisonSourceChecks(context, controller: controller),
            child: const Text('Open source checks'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open source checks'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('discovery-provider-acousticbrainz')),
  );
  await tester.pumpAndSettle();
}

void main() {
  final analysis = AcousticBrainzAnalysis.fromMetadata(
    'acousticbrainz',
    _analysisMetadata,
  );

  for (final config in _configurations) {
    testWidgets('provider check analysis is safe and readable ${config.$1}', (
      tester,
    ) async {
      expect(analysis, isNotNull);
      final controller = FakeUiController(
        (_) => VerseUiState(comparison: _comparison(analysis)),
      );
      addTearDown(controller.dispose);
      await _pumpChecksRoute(
        tester,
        controller,
        size: config.$2,
        textScale: config.$3,
        locale: config.$4,
        brightness: config.$5,
      );

      final details = find.byKey(
        const ValueKey('source-check-details-acousticbrainz'),
      );
      final l10n = AppLocalizations.of(tester.element(details));
      final scrollable = find
          .descendant(of: details, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.text(l10n.sourceAnalysisHeading),
        70,
        scrollable: scrollable,
      );
      expect(find.text(l10n.sourceAnalysisHeading), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(l10n.sourceAnalysisCoverage(2, 148)),
        50,
        scrollable: scrollable,
      );
      expect(find.text(l10n.sourceAnalysisCoverage(2, 148)), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('164.02'),
        50,
        scrollable: scrollable,
      );
      expect(find.textContaining('164.02'), findsOneWidget);
      expect(find.textContaining('D#m'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('163.975'),
        50,
        scrollable: scrollable,
      );
      expect(find.textContaining('163.975'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(l10n.searchCheckOperations),
        50,
        scrollable: scrollable,
      );
      expect(find.text(l10n.searchCheckOperations), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);
      final operation = find.byKey(
        const ValueKey('source-operation-analysis-fetch'),
      );
      await tester.ensureVisible(operation);
      await tester.pumpAndSettle();
      await tester.tap(operation);
      await tester.pumpAndSettle();
      expect(find.text('Lantern Map June Harbor'), findsOneWidget);

      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(l10n.providerCapabilityLyrics), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.textContaining('file_name'), findsNothing);
      expect(find.textContaining('musicbrainz_recordingid'), findsNothing);
      expect(
        find.textContaining('synthetic-private-upload.flac'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      if (_capture) {
        await tester.scrollUntilVisible(
          find.text(l10n.sourceAnalysisHeading),
          -80,
          scrollable: scrollable,
        );
        await tester.ensureVisible(find.text(l10n.sourceAnalysisHeading));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(Overlay).first,
          matchesGoldenFile(
            '../../artifacts/qualification/screenshots/source-checks-analysis-${config.$1}.png',
          ),
        );
      }
    });
  }

  testWidgets(
    'live analysis withdraws on navigation but check history remains',
    (tester) async {
      expect(analysis, isNotNull);
      var comparison = _comparison(analysis);
      final controller = FakeUiController(
        (_) => VerseUiState(comparison: comparison),
      );
      addTearDown(controller.dispose);
      await _pumpChecksRoute(
        tester,
        controller,
        size: const Size(360, 780),
        textScale: 1,
        locale: 'en',
        brightness: Brightness.light,
      );

      final details = find.byKey(
        const ValueKey('source-check-details-acousticbrainz'),
      );
      final l10n = AppLocalizations.of(tester.element(details));
      final scrollable = find
          .descendant(of: details, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.text(l10n.sourceAnalysisHeading),
        70,
        scrollable: scrollable,
      );
      expect(find.text(l10n.sourceAnalysisHeading), findsOneWidget);
      final operation = find.byKey(
        const ValueKey('source-operation-analysis-fetch'),
      );
      await tester.ensureVisible(operation);
      await tester.pumpAndSettle();
      expect(operation, findsOneWidget);

      comparison = _comparison(null, referenceId: 'fixture:next-selection');
      controller.refresh();
      await tester.pumpAndSettle();
      expect(find.text(l10n.sourceAnalysisHeading), findsNothing);
      expect(find.text(l10n.sourceAnalysisCoverage(2, 148)), findsNothing);
      expect(
        find.byKey(const ValueKey('source-operation-analysis-fetch')),
        findsOneWidget,
      );
      expect(find.text(l10n.searchCheckOperations), findsOneWidget);
      expect(find.textContaining('private-upload'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
