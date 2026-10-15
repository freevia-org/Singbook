import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verse_mobile/l10n/generated/app_localizations.dart';
import 'package:verse_mobile/ui/home/home_screen.dart';
import 'package:verse_mobile/ui/theme/verse_theme.dart';
import 'package:verse_mobile/ui/verse_ui_state.dart';

void main() {
  testWidgets('localized count messages preserve numeric counts and plurals', (
    tester,
  ) async {
    const counts = [0, 1, 2, 5, 21];
    const expectedResults = {
      'en': ['No results', '1 result', '2 results', '5 results', '21 results'],
      'bg': [
        'Няма резултати',
        '1 резултат',
        '2 резултата',
        '5 резултата',
        '21 резултата',
      ],
      'uk': [
        'Немає результатів',
        '1 результат',
        '2 результати',
        '5 результатів',
        '21 результат',
      ],
    };
    const expectedItems = {
      'en': [
        '0 items shown',
        '1 item shown',
        '2 items shown',
        '5 items shown',
        '21 items shown',
      ],
      'bg': [
        'Показани са 0 елемента',
        'Показан е 1 елемент',
        'Показани са 2 елемента',
        'Показани са 5 елемента',
        'Показани са 21 елемента',
      ],
      'uk': [
        'Показано 0 елементів',
        'Показано 1 елемент',
        'Показано 2 елементи',
        'Показано 5 елементів',
        'Показано 21 елемент',
      ],
    };
    const expectedCombined = {
      'en': [
        'Combined from 0 sources',
        'Combined from 1 source',
        'Combined from 2 sources',
        'Combined from 5 sources',
        'Combined from 21 sources',
      ],
      'bg': [
        'Обединено от 0 източника',
        'Обединено от 1 източник',
        'Обединено от 2 източника',
        'Обединено от 5 източника',
        'Обединено от 21 източника',
      ],
      'uk': [
        'Об’єднано з 0 джерел',
        'Об’єднано з 1 джерела',
        'Об’єднано з 2 джерел',
        'Об’єднано з 5 джерел',
        'Об’єднано з 21 джерела',
      ],
    };
    const expectedSongMatches = {
      'en': [
        '0 song matches',
        '1 song match',
        '2 song matches',
        '5 song matches',
        '21 song matches',
      ],
      'bg': [
        '0 съвпадения на песни',
        '1 съвпадение на песен',
        '2 съвпадения на песни',
        '5 съвпадения на песни',
        '21 съвпадения на песни',
      ],
      'uk': [
        '0 збігів пісень',
        '1 збіг пісні',
        '2 збіги пісень',
        '5 збігів пісень',
        '21 збіг пісні',
      ],
    };
    const expectedVersions = {
      'en': [
        '0 source versions',
        '1 source version',
        '2 source versions',
        '5 source versions',
        '21 source versions',
      ],
      'bg': [
        '0 версии от източници',
        '1 версия от източник',
        '2 версии от източници',
        '5 версии от източници',
        '21 версии от източници',
      ],
      'uk': [
        '0 версій джерел',
        '1 версія джерела',
        '2 версії джерел',
        '5 версій джерел',
        '21 версія джерела',
      ],
    };
    const expectedProviderFound = {
      'en': 'Match found',
      'bg': 'Намерено съвпадение',
      'uk': 'Знайдено збіг',
    };

    for (final locale in const [Locale('en'), Locale('bg'), Locale('uk')]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final key = locale.languageCode;
              expect(l10n.searchProviderFound, expectedProviderFound[key]);
              expect(l10n.searchProviderFound, isNot(contains('Lyrics')));
              for (var index = 0; index < counts.length; index++) {
                final count = counts[index];
                expect(
                  l10n.searchResultCount(count),
                  expectedResults[key]![index],
                );
                expect(
                  l10n.homeItemsShownCount(count),
                  expectedItems[key]![index],
                );
                expect(
                  l10n.searchCombinedFromSources(count),
                  expectedCombined[key]![index],
                );
                expect(
                  l10n.searchSongMatchCount(count),
                  expectedSongMatches[key]![index],
                );
                expect(
                  l10n.searchSourceVersionsCount(count),
                  expectedVersions[key]![index],
                );
                for (final label in [
                  l10n.searchResultCount(count),
                  l10n.homeItemsShownCount(count),
                  l10n.searchCombinedFromSources(count),
                  l10n.searchSongMatchCount(count),
                  l10n.searchSourceVersionsCount(count),
                ]) {
                  expect(label, isNot(contains('#')));
                  if (count > 0) expect(label, contains('$count'));
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }
  });

  testWidgets('home history count reflects displayed filtered items', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 804);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final now = DateTime(2026, 10, 14);
    final controller = _VisualHomeController(
      VerseUiState(
        query: 'Signal',
        recent: [
          RecentItemData(
            id: 'signal-1',
            title: 'Signal Song One',
            occurredAt: now,
            isSetlist: false,
          ),
          RecentItemData(
            id: 'setlist-signal',
            title: 'Signal rehearsal',
            occurredAt: now,
            isSetlist: true,
          ),
          RecentItemData(
            id: 'other',
            title: 'Another Song',
            occurredAt: now,
            isSetlist: false,
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await _pumpHome(tester, controller: controller);
    final l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
    expect(find.text('${l10n.searchRecentTab} (2)'), findsOneWidget);
    expect(find.text(l10n.homeItemsShownCount(2)), findsNothing);
    expect(find.byKey(const ValueKey('recent-row-other')), findsNothing);
    expect(find.text(l10n.homeRecentSongs), findsNothing);
    expect(tester.takeException(), isNull);

    controller._state = VerseUiState(
      homeListMode: HomeListMode.favorites,
      songs: [
        const SongCardData(
          id: 'favorite-song',
          title: 'Favorite song',
          favorite: true,
        ),
        const SongCardData(id: 'other-song', title: 'Other song'),
      ],
      setlists: [
        SetlistCardData(
          id: 'favorite-setlist',
          title: 'Favorite setlist',
          favorite: true,
          modifiedAt: now,
        ),
      ],
    );
    controller.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('${l10n.searchFavoritesTab} (2)'), findsOneWidget);
    expect(find.text(l10n.homeItemsShownCount(2)), findsNothing);
    expect(find.text(l10n.homeFavorites), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'online states count catalog hits and source versions separately',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 804);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const reference = SearchReferenceData(
        id: 'signal',
        title: 'Signal Song',
        artist: 'The Signals',
      );
      const suggested = SourceVersionData(
        id: 'source-1',
        providerId: 'catalog',
        providerName: 'Catalog',
        title: 'Signal Song',
        artist: 'The Signals',
        sourceCount: 5,
        hasLyrics: true,
        isUsableVersion: true,
        bodyPreview: [
          LyricLineData(id: 'suggested-line', text: 'Signal again'),
        ],
      );
      const alternative1 = SourceVersionData(
        id: 'source-2',
        providerId: 'archive-a',
        providerName: 'Archive A',
        title: 'Signal Song',
        artist: 'The Signals',
        hasLyrics: true,
        isUsableVersion: true,
        bodyPreview: [
          LyricLineData(id: 'archive-a-line', text: 'Signal again'),
        ],
      );
      const alternative2 = SourceVersionData(
        id: 'source-3',
        providerId: 'archive-b',
        providerName: 'Archive B',
        title: 'Signal Song',
        artist: 'The Signals',
        hasLyrics: true,
        isUsableVersion: true,
        bodyPreview: [
          LyricLineData(id: 'archive-b-line', text: 'Signal again'),
        ],
      );
      final controller = _VisualHomeController(
        const VerseUiState(
          homeListMode: HomeListMode.online,
          query: 'signal',
          searchState: LoadState.loaded,
          comparison: SearchComparisonData(
            reference: reference,
            suggested: suggested,
            alternatives: [alternative1, alternative2],
          ),
        ),
      );
      addTearDown(controller.dispose);
      await _pumpHome(tester, controller: controller);
      final l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
      expect(find.text('${l10n.searchOnlineTab} (1)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-search-comparison-counts')),
        findsOneWidget,
      );
      expect(find.text(l10n.searchSongMatchCount(1)), findsOneWidget);
      expect(find.text(l10n.searchSourceVersionsCount(3)), findsOneWidget);
      final combinedSourcesLabel = l10n.searchCombinedFromSources(5);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data?.contains(combinedSourcesLabel) == true,
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.searchAutocompleteLabel), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('online result counts match visible list and empty states', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 804);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final refs = [
      for (var index = 0; index < 5; index++)
        SearchReferenceData(
          id: 'signal-$index',
          title: 'Signal Song $index',
          artist: 'The Signals',
        ),
    ];
    final controller = _VisualHomeController();
    addTearDown(controller.dispose);

    for (final count in [1, 2, 5]) {
      controller._state = VerseUiState(
        homeListMode: HomeListMode.online,
        query: 'signal',
        searchState: LoadState.loaded,
        autocomplete: refs.take(count).toList(),
      );
      controller.notifyListeners();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
          home: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Scaffold(
              body: VerseHomeScreen(
                controller: controller,
                state: controller.state,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
      expect(find.text('${l10n.searchOnlineTab} ($count)'), findsOneWidget);
      expect(find.text(l10n.searchResultCount(count)), findsNothing);
      expect(find.text(l10n.searchAutocompleteLabel), findsNothing);
      expect(tester.takeException(), isNull);
    }

    controller._state = const VerseUiState(
      homeListMode: HomeListMode.online,
      query: 'signal',
      searchState: LoadState.loaded,
    );
    controller.notifyListeners();
    await tester.pumpAndSettle();
    var l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
    expect(find.text(l10n.searchResultCount(0)), findsOneWidget);
    expect(find.text(l10n.searchNoResults), findsOneWidget);

    controller._state = const VerseUiState(
      homeListMode: HomeListMode.online,
      searchState: LoadState.idle,
    );
    controller.notifyListeners();
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
    expect(find.text(l10n.searchCatalogEmptyQuery), findsOneWidget);
    expect(find.text(l10n.searchResultCount(0)), findsNothing);
    expect(find.text(l10n.searchAutocompleteLabel), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'online catalog filters only offer fields the catalog can check',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 804);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = _VisualHomeController(
        const VerseUiState(
          homeListMode: HomeListMode.online,
          searchFiltersExpanded: true,
          searchFilters: SearchFilterData(
            field: 'lyrics',
            chordsOnly: true,
            timedOnly: true,
            language: 'uk',
          ),
        ),
      );
      addTearDown(controller.dispose);

      await _pumpHome(
        tester,
        controller: controller,
        locale: const Locale('uk'),
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
      final searchField = tester.widget<TextField>(find.byType(TextField));
      expect(searchField.decoration!.hintText, l10n.searchCatalogHint);
      expect(
        find.byKey(const ValueKey('online-filter-limit-hint')),
        findsOneWidget,
      );
      expect(find.text(l10n.searchCatalogFilterHint), findsOneWidget);
      expect(find.text(l10n.searchFilterLyrics), findsNothing);
      expect(find.text(l10n.searchFilterChords), findsNothing);
      expect(find.text(l10n.searchFilterTimed), findsNothing);
      expect(find.text(l10n.searchFilterLanguage), findsNothing);
      expect(find.text(l10n.searchCatalogEmptyQuery), findsOneWidget);
      final metadataDropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: find.byType(DropdownButtonFormField<String>),
          matching: find.byType(DropdownButton<String>),
        ),
      );
      expect(metadataDropdown.value, 'all');
      expect(metadataDropdown.items!.map((item) => item.value), [
        'all',
        'title',
        'artist',
      ]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('discovery progress and no-lyrics retry have visible states', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 804);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const reference = SearchReferenceData(
      id: 'signal',
      title: 'Signal Song',
      artist: 'The Signals',
    );
    final controller = _VisualHomeController(
      const VerseUiState(
        homeListMode: HomeListMode.online,
        query: 'signal',
        searchState: LoadState.loaded,
        comparison: SearchComparisonData(
          reference: reference,
          suggested: null,
          discovering: true,
          providerChecks: [
            SearchProviderCheckData(
              id: 'catalog',
              name: 'Catalog',
              state: 'pending',
            ),
            SearchProviderCheckData(
              id: 'archive',
              name: 'Archive',
              state: 'found',
            ),
          ],
        ),
      ),
    );
    addTearDown(controller.dispose);
    await _pumpHome(tester, controller: controller);
    var l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
    expect(find.byKey(const ValueKey('discovery-progress')), findsOneWidget);
    expect(find.text(l10n.searchDiscoveryProgress(1, 2)), findsOneWidget);
    expect(
      find.byKey(const ValueKey('discovery-provider-checks')),
      findsOneWidget,
    );

    controller._state = const VerseUiState(
      homeListMode: HomeListMode.online,
      query: 'signal',
      searchState: LoadState.loaded,
      comparison: SearchComparisonData(
        reference: reference,
        suggested: null,
        noUsableLyrics: true,
        providerChecks: [
          SearchProviderCheckData(
            id: 'archive',
            name: 'Archive',
            state: 'unavailable',
          ),
        ],
      ),
    );
    controller.notifyListeners();
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
    expect(find.byKey(const ValueKey('discovery-no-lyrics')), findsOneWidget);
    expect(find.text(l10n.searchDiscoveryNoLyricsDetails), findsOneWidget);
    expect(find.text(l10n.searchSourcesUnavailableCount(1)), findsOneWidget);
    await tester.tap(find.text(l10n.searchDiscoveryRetry));
    await tester.pump();
    expect(controller.retryRequested, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'home mode labels stay on one line at phone and large text sizes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = _VisualHomeController();
      addTearDown(controller.dispose);

      for (final locale in const [Locale('en'), Locale('bg'), Locale('uk')]) {
        for (final scale in const [1.0, 1.3, 1.5, 2.0]) {
          for (final size in const [
            Size(320, 700),
            Size(360, 804),
            Size(393, 873),
          ]) {
            tester.view.physicalSize = size;
            await _pumpHome(
              tester,
              locale: locale,
              scale: scale,
              controller: controller,
            );

            final selector = find.byKey(const ValueKey('home-mode-scroll'));
            expect(selector, findsOneWidget, reason: '$locale/$scale/$size');
            expect(
              tester.takeException(),
              isNull,
              reason: '$locale/$scale/$size',
            );

            for (final mode in HomeListMode.values) {
              final segment = find.byKey(ValueKey('home-mode-${mode.name}'));
              expect(segment, findsOneWidget, reason: '$locale/$scale/$size');
              final label = find.descendant(
                of: segment,
                matching: find.byType(Text),
              );
              expect(label, findsOneWidget);
              final paragraph = tester.renderObject<RenderParagraph>(label);
              final text = tester.widget<Text>(label);
              final metrics = TextPainter(
                text: TextSpan(text: text.data, style: text.style),
                textDirection: TextDirection.ltr,
                textScaler: TextScaler.linear(scale),
                maxLines: text.maxLines,
              )..layout(maxWidth: paragraph.size.width);
              expect(paragraph.maxLines, 1);
              expect(metrics.computeLineMetrics(), hasLength(1));
              expect(paragraph.didExceedMaxLines, isFalse);
            }

            final search = tester.getRect(find.byType(TextField));
            final modes = tester.getRect(selector);
            expect(
              search.bottom,
              lessThan(modes.top),
              reason: 'header overlap',
            );
            expect(search.left, greaterThanOrEqualTo(0));
            expect(search.right, lessThanOrEqualTo(size.width));
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'all home modes can be selected and selected segment is revealed',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 804);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = _VisualHomeController();
      addTearDown(controller.dispose);
      await _pumpHome(tester, controller: controller);

      for (final mode in HomeListMode.values) {
        final segment = find.byKey(ValueKey('home-mode-${mode.name}'));
        await tester.ensureVisible(segment);
        await tester.tap(segment);
        await tester.pumpAndSettle();
        expect(controller.state.homeListMode, mode);
        final selected = tester.widget<Semantics>(
          find.descendant(
            of: segment,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.selected == true,
            ),
          ),
        );
        expect(selected.properties.selected, isTrue);
        final segmentRect = tester.getRect(
          find.byKey(ValueKey('home-mode-${mode.name}')),
        );
        final scrollRect = tester.getRect(
          find.byKey(const ValueKey('home-mode-scroll')),
        );
        expect(segmentRect.left, greaterThanOrEqualTo(scrollRect.left));
        expect(segmentRect.right, lessThanOrEqualTo(scrollRect.right));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('home modes wrap visibly and remain tappable at 2x text', (
    tester,
  ) async {
    final font = FontLoader('NotoSansHome')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    await font.load();

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 804);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = _VisualHomeController();
    addTearDown(controller.dispose);
    await _pumpHome(
      tester,
      scale: 2,
      controller: controller,
      fontFamily: 'NotoSansHome',
    );

    final selector = find.byKey(const ValueKey('home-mode-scroll'));
    final selectorRect = tester.getRect(selector);
    expect(selectorRect.right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);

    for (final mode in HomeListMode.values) {
      final segment = find.byKey(ValueKey('home-mode-${mode.name}'));
      final rect = tester.getRect(segment);
      expect(rect.left, greaterThanOrEqualTo(selectorRect.left));
      expect(rect.right, lessThanOrEqualTo(selectorRect.right));
      final label = find.descendant(of: segment, matching: find.byType(Text));
      final paragraph = tester.renderObject<RenderParagraph>(label);
      expect(paragraph.maxLines, 1);
      expect(paragraph.didExceedMaxLines, isFalse);

      await tester.tap(segment);
      await tester.pumpAndSettle();
      expect(controller.state.homeListMode, mode);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'home search and selector remain laid out with keyboard and landscape',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(804, 360);
      final controller = _VisualHomeController();
      addTearDown(controller.dispose);
      await _pumpHome(
        tester,
        controller: controller,
        locale: const Locale('uk'),
      );
      await tester.tap(find.byType(TextField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('home-mode-scroll')), findsOneWidget);
      final search = tester.getRect(find.byType(TextField));
      final selector = tester.getRect(
        find.byKey(const ValueKey('home-mode-scroll')),
      );
      expect(search.bottom, lessThan(selector.top));
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'search query resets to its start after submit and suggestion selection',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 804);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const reference = SearchReferenceData(
        id: 'lanterns',
        title: 'Lanterns at Dawn',
        artist: 'The Paper Moons',
      );
      final controller = _VisualHomeController(
        const VerseUiState(
          homeListMode: HomeListMode.online,
          searchState: LoadState.loaded,
          autocomplete: [reference],
        ),
      );
      addTearDown(controller.dispose);
      await _pumpHome(tester, controller: controller);

      const query =
          'A very long search query that extends well beyond the visible field';
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();
      var editable = tester.widget<EditableText>(find.byType(EditableText));
      final queryScroll = editable.scrollController!;
      expect(editable.focusNode.hasFocus, isTrue);
      expect(queryScroll.offset, greaterThan(0));

      final l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
      await tester.tap(find.byTooltip(l10n.searchSubmit));
      await tester.pumpAndSettle();
      editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, query);
      expect(editable.focusNode.hasFocus, isFalse);
      expect(queryScroll.offset, 0);
      expect(controller.searchSubmitted, isTrue);

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();
      expect(queryScroll.offset, greaterThan(0));
      await tester.tap(find.text(reference.title));
      await tester.pumpAndSettle();
      editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, query);
      expect(editable.focusNode.hasFocus, isFalse);
      expect(queryScroll.offset, 0);
      expect(controller.selectedReferenceId, reference.id);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('populated home rows fit at the compact large-text phone size', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 804);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = _VisualHomeController(
      VerseUiState(
        recent: [
          for (var index = 0; index < 8; index++)
            RecentItemData(
              id: 'song-$index',
              title: 'A Very Long Song Title $index with Several Words',
              artist: 'A Long Artist Name for Narrow Screens',
              subtitle: 'Album Name · 4:23',
              occurredAt: DateTime(
                2026,
                10,
                14,
              ).subtract(Duration(days: index)),
              isSetlist: false,
            ),
        ],
      ),
    );
    addTearDown(controller.dispose);
    await _pumpHome(
      tester,
      controller: controller,
      locale: const Locale('bg'),
      scale: 1.3,
    );

    expect(
      find.text('A Very Long Song Title 0 with Several Words'),
      findsOneWidget,
    );
    final layoutError = tester.takeException();
    expect(
      layoutError,
      isNull,
      reason: layoutError is FlutterError
          ? layoutError.toStringDeep()
          : '$layoutError',
    );
    void checkVisibleRows() {
      var checkedRows = 0;
      for (var index = 0; index < 8; index++) {
        final row = find.byKey(ValueKey('recent-row-song-$index'));
        if (row.evaluate().isEmpty) continue;
        final rect = tester.getRect(row);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
        checkedRows++;
      }
      expect(checkedRows, greaterThan(0));
    }

    checkVisibleRows();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    checkVisibleRows();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double scale = 1,
  String fontFamily = 'sans-serif',
  _VisualHomeController? controller,
}) async {
  final homeController = controller ?? _VisualHomeController();
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: verseTheme(
        brightness: Brightness.light,
        palette: 'navy',
        fontFamily: fontFamily,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: AnimatedBuilder(
        animation: homeController,
        builder: (context, _) => Scaffold(
          body: VerseHomeScreen(
            controller: homeController,
            state: homeController.state,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _VisualHomeController extends VerseUiController {
  _VisualHomeController([VerseUiState? initialState])
    : _state = initialState ?? const VerseUiState();
  VerseUiState _state;
  bool searchSubmitted = false;
  bool retryRequested = false;
  String? selectedReferenceId;

  @override
  VerseUiState get state => _state;

  @override
  void setQuery(String value) {
    _state = VerseUiState(
      homeListMode: _state.homeListMode,
      query: value,
      autocomplete: _state.autocomplete,
      searchState: _state.searchState,
    );
    notifyListeners();
  }

  @override
  Future<void> submitSearch() async {
    searchSubmitted = true;
  }

  @override
  Future<void> selectReference(SearchReferenceData reference) async {
    selectedReferenceId = reference.id;
  }

  @override
  Future<void> retrySelectedSongDiscovery() async {
    retryRequested = true;
  }

  @override
  void setHomeListMode(HomeListMode mode) {
    _state = VerseUiState(
      homeListMode: mode,
      recent: _state.recent,
      songs: _state.songs,
      setlists: _state.setlists,
    );
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #submitSearch ||
        invocation.memberName == #loadMoreRecent) {
      return Future<void>.value();
    }
    return null;
  }
}
