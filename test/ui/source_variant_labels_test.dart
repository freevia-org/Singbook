import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/home/source_version_widgets.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/verse_components.dart';

import 'support/fake_controller.dart';

const _capture = bool.fromEnvironment('CAPTURE_MUTOPIA_VARIANTS');
const _references = [
  SearchReferenceData(
    id: 'mutopia:4242:firstText',
    providerId: 'mutopia',
    providerName: 'Mutopia',
    title: 'Lantern over the garden',
    artist: 'Example Composer',
    sourceVariantLabel: 'firstText',
  ),
  SearchReferenceData(
    id: 'mutopia:4242:secondText',
    providerId: 'mutopia',
    providerName: 'Mutopia',
    title: 'Lantern over the garden',
    artist: 'Example Composer',
    sourceVariantLabel: 'secondText',
  ),
];

class _Controller extends FakeUiController {
  _Controller()
    : super(
        (_) => const VerseUiState(
          homeListMode: HomeListMode.online,
          query: 'Lantern',
          autocomplete: _references,
          searchState: LoadState.loaded,
        ),
      );
  SearchReferenceData? selected;
  @override
  Future<void> selectReference(SearchReferenceData reference) async {
    selected = reference;
  }
}

void main() {
  for (final config in [
    ('phone', const Size(360, 780), 1.0, 'en', Brightness.light),
    ('large-text', const Size(360, 780), 1.8, 'en', Brightness.light),
    ('rtl-dark', const Size(390, 844), 1.2, 'ar', Brightness.dark),
    ('landscape', const Size(640, 360), 1.6, 'en', Brightness.light),
    ('uk-dark', const Size(390, 844), 1.2, 'uk', Brightness.dark),
  ]) {
    testWidgets('named source streams remain selectable ${config.$1}', (
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
      final controller = _Controller();
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
                    fontFamilyFallback: const ['Roboto'],
                  ),
                )
              : theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(config.$3)),
            child: child!,
          ),
          home: Scaffold(
            body: VerseHomeScreen(
              controller: controller,
              state: controller.state,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scrollable = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      final first = find.byKey(
        const ValueKey('online-reference-mutopia:4242:firstText'),
      );
      await tester.scrollUntilVisible(first, 80, scrollable: scrollable);
      expect(
        find.descendant(of: first, matching: find.text('first Text')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: first,
          matching: find.text('Lantern over the garden'),
        ),
        findsOneWidget,
      );
      final second = find.byKey(
        const ValueKey('online-reference-mutopia:4242:secondText'),
      );
      await tester.scrollUntilVisible(second, 80, scrollable: scrollable);
      await tester.ensureVisible(second);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: second, matching: find.text('second Text')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: second,
          matching: find.text('Lantern over the garden'),
        ),
        findsOneWidget,
      );
      if (_capture) {
        await expectLater(
          find.byType(Overlay).first,
          matchesGoldenFile(
            '../../artifacts/qualification/variants/search-${config.$1}.png',
          ),
        );
      }
      await tester.tap(second);
      await tester.pumpAndSettle();
      expect(controller.selected?.id, 'mutopia:4242:secondText');
      expect(controller.selected?.title, 'Lantern over the garden');
      expect(controller.selected?.album, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('saved row and version names preserve the stream choice', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: singbookLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SongRow(
            song: const SongCardData(
              id: 'saved-stream',
              title: 'Same work title',
              artist: 'Example Composer',
              sourceVariantLabel: 'secondText',
            ),
            accessibilityLabel: 'Same work title, Example Composer',
            favoriteAddLabel: 'Favorite',
            favoriteRemoveLabel: 'Unfavorite',
            menuLabel: 'Actions',
            showFavorite: false,
            onOpen: () => opened = true,
          ),
        ),
      ),
    );
    expect(find.text('Same work title'), findsOneWidget);
    expect(find.text('second Text'), findsOneWidget);
    await tester.tap(find.text('second Text'));
    expect(opened, isTrue);
    final l10n = AppLocalizations.of(tester.element(find.byType(SongRow)));
    SourceVersionData version(
      String provider,
      String label, {
      String id = 'source',
    }) => SourceVersionData(
      id: id,
      providerId: provider,
      providerName: 'Source',
      title: 'Same work title',
      artist: 'Example Composer',
      metadata: {'sourceVariantLabel': label},
    );
    expect(
      versionName(l10n, version('mutopia', 'secondText')),
      'Source · second Text',
    );
    expect(versionName(l10n, version('lrclib', 'secondText')), 'Source');
    expect(versionName(l10n, version('mutopia', 'unsafe\nlabel')), 'Source');
    expect(
      versionName(l10n, version('mutopia', 'secondText', id: 'combined')),
      l10n.searchCombinedLabel,
    );
  });
}
