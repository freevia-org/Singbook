import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/source_version_browser.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _capture = bool.fromEnvironment('CAPTURE_COMPARISON_DETAILS');

const _version = SourceVersionData(
  id: 'fixture',
  providerId: 'fixture',
  providerName: 'Lyrics archive',
  title: 'Paper Satellites',
  artist: 'Fixture Ensemble',
  album: 'Evening sketches',
  durationSeconds: 214,
  hasLyrics: true,
  hasChords: true,
  canSave: true,
  isUsableVersion: true,
  matchSummary: 'same_song',
  sourceUrl: 'https://lyrics.example/paper-satellites',
  metadata: {
    'key': 'D',
    'capo': '2',
    'composers': ['Ada Hart', 'Sam Rivers'],
    'year': '2024',
  },
  bodyLines: [
    LyricLineData(id: 'verse', section: 'Verse 1', isBlank: true),
    LyricLineData(id: 'line-1', text: 'A paper satellite sails above the desk'),
    LyricLineData(id: 'line-2', text: 'Our quiet room remembers the rain'),
  ],
);

Future<void> _step(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _image(WidgetTester tester, String name) async {
  if (!_capture) return;
  await expectLater(
    find.byType(Overlay).first,
    matchesGoldenFile('../../artifacts/comparison-details/$name.png'),
  );
}

void main() {
  for (final configuration in [
    ('phone', const Size(360, 780), 1.0, 'en', Brightness.light),
    ('large-text', const Size(360, 780), 1.6, 'en', Brightness.light),
    ('rtl-dark', const Size(390, 844), 1.2, 'ar', Brightness.dark),
    ('landscape', const Size(640, 360), 2.0, 'en', Brightness.light),
    ('desktop-landscape', const Size(1440, 900), 1.0, 'en', Brightness.light),
  ]) {
    testWidgets('all checks open and live errors expand ${configuration.$1}', (
      tester,
    ) async {
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
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = configuration.$2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var failed = false;
      final controller = FakeUiController(
        (_) => VerseUiState(
          comparison: SearchComparisonData(
            reference: const SearchReferenceData(
              id: 'song',
              title: 'Paper Satellites',
              artist: 'Fixture Ensemble',
            ),
            suggested: null,
            alternatives: const [_version],
            selectedVersionId: 'fixture',
            discovering: !failed,
            providerChecks: [
              const SearchProviderCheckData(
                id: 'ready',
                name: 'Lyrics archive',
                state: 'found',
              ),
              const SearchProviderCheckData(
                id: 'empty',
                name: 'Chord library',
                state: 'unavailable',
              ),
              SearchProviderCheckData(
                id: 'checking',
                name: 'Timing source',
                state: failed ? 'failed' : 'pending',
                code: failed ? 'rate_limited' : null,
                operations: [
                  SearchProviderOperationData(
                    id: 'timing-search',
                    phase: 'search',
                    state: failed ? 'failed' : 'pending',
                    code: failed ? 'rate_limited' : null,
                    query: 'Paper Satellites Fixture Ensemble',
                    elapsedMilliseconds: failed ? 1234 : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      addTearDown(controller.dispose);
      final theme = verseTheme(brightness: configuration.$5, palette: 'navy');
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: Locale(configuration.$4),
          localizationsDelegates: singbookLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: configuration.$4 == 'ar'
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
            ).copyWith(textScaler: TextScaler.linear(configuration.$3)),
            child: child!,
          ),
          home: Scaffold(
            body: SafeArea(child: SourceVersionBrowser(controller: controller)),
          ),
        ),
      );
      await _step(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(SourceVersionBrowser)),
      );
      expect(find.byKey(const ValueKey('version-source-menu')), findsNothing);
      expect(find.byKey(const ValueKey('preview-sections')), findsNothing);
      await _image(tester, '${configuration.$1}-comparison');
      await tester.tap(find.byKey(const ValueKey('version-info-button')));
      await _step(tester);
      final info = find.byKey(const ValueKey('version-info-sheet'));
      expect(
        find.descendant(of: info, matching: find.text('Lyrics archive')),
        findsOneWidget,
      );
      await _image(tester, '${configuration.$1}-info');
      await tester.tap(
        find.descendant(of: info, matching: find.byTooltip(l10n.navClose)),
      );
      await _step(tester);
      await tester.tap(find.byKey(const ValueKey('source-checks-button')));
      await _step(tester);
      if (configuration.$1 == 'desktop-landscape') {
        final checksSheet = find.byKey(const ValueKey('source-checks-sheet'));
        final draggableSheet = find
            .ancestor(
              of: checksSheet,
              matching: find.byType(DraggableScrollableSheet),
            )
            .first;
        expect(
          tester
              .widget<DraggableScrollableSheet>(draggableSheet)
              .initialChildSize,
          .85,
        );
        final constraintsBuilder = find
            .ancestor(of: checksSheet, matching: find.byType(LayoutBuilder))
            .first;
        final availableHeight = tester
            .renderObject<RenderBox>(constraintsBuilder)
            .constraints
            .maxHeight;
        expect(
          tester.getSize(checksSheet).height,
          closeTo(availableHeight * .85, 1),
          reason:
              'Desktop landscape details should use 85% of available height.',
        );
      }
      await _image(tester, '${configuration.$1}-checks');
      for (final id in ['ready', 'empty', 'checking']) {
        final sheet = find.byKey(const ValueKey('source-checks-sheet'));
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('discovery-provider-$id')),
          80,
          scrollable: find
              .descendant(of: sheet, matching: find.byType(Scrollable))
              .first,
        );
        await tester.tap(find.byKey(ValueKey('discovery-provider-$id')));
        await _step(tester);
        final details = find.byKey(ValueKey('source-check-details-$id'));
        expect(details, findsOneWidget);
        if (id == 'checking') {
          failed = true;
          controller.refresh();
          await _step(tester);
          final operation = find.byKey(
            const ValueKey('source-operation-timing-search'),
          );
          await tester.scrollUntilVisible(
            operation,
            100,
            scrollable: find
                .descendant(of: details, matching: find.byType(Scrollable))
                .first,
          );
          final tile = tester.widget<ExpansionTile>(
            find.descendant(
              of: operation,
              matching: find.byType(ExpansionTile),
            ),
          );
          expect(tile.initiallyExpanded, isTrue);
          await _image(tester, '${configuration.$1}-operation');
          expect(
            find.descendant(of: operation, matching: find.text('rate_limited')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.descendant(of: details, matching: find.byTooltip(l10n.navClose)),
          -120,
          scrollable: find
              .descendant(of: details, matching: find.byType(Scrollable))
              .first,
        );
        await tester.tap(
          find.descendant(of: details, matching: find.byTooltip(l10n.navClose)),
        );
        await _step(tester);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
