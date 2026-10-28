import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  testWidgets(
    'compact version selection keeps its order and updates the visible preview',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final controller = _LiveFlowController(_comparisonState());
      addTearDown(controller.dispose);
      await _pumpHome(tester, controller);

      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const ValueKey('home-mode-scroll')), findsNothing);
      expect(find.byKey(const ValueKey('version-tabs')), findsOneWidget);

      final footer = find.byKey(const ValueKey('version-selection-footer'));
      final button = find.byKey(const ValueKey('save-open-lyrics'));
      final content = find.byType(VerseHomeScreen);
      expect(footer, findsOneWidget);
      expect(button, findsOneWidget);
      expect(
        tester.getRect(button).bottom,
        lessThanOrEqualTo(tester.getRect(content).bottom),
      );
      expect(find.text('First source preview'), findsOneWidget);

      final orderBefore = _rowOrder(tester);
      final secondRow = find.byKey(const ValueKey('version-row-second'));
      await tester.ensureVisible(secondRow);
      await tester.tap(secondRow);
      await tester.pumpAndSettle();

      expect(controller.state.comparison!.selectedVersionId, 'second');
      expect(find.text('Second source preview'), findsOneWidget);
      expect(find.text('First source preview').hitTestable(), findsNothing);
      expect(_rowOrder(tester), orderBefore);
      expect(
        tester.getRect(button).bottom,
        lessThanOrEqualTo(tester.getRect(content).bottom),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('deduplicated source keeps its count and selected alias', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const suggested = SourceVersionData(
      id: 'suggested',
      providerId: 'combined',
      providerName: 'Suggested',
      title: 'Signal Song',
      artist: 'The Signals',
      durationSeconds: 180,
      hasLyrics: true,
      isUsableVersion: true,
      sourceCount: 1,
      underlyingSourceId: 'raw-source',
      canSave: true,
      bodyPreview: [
        LyricLineData(id: 'suggested-preview', text: 'Suggested preview'),
      ],
    );
    const rawSource = SourceVersionData(
      id: 'raw-source',
      providerId: 'catalog',
      providerName: 'Catalog',
      title: 'Signal Song',
      artist: 'The Signals',
      durationSeconds: 180,
      hasLyrics: true,
      isUsableVersion: true,
      canSave: true,
      bodyPreview: [
        LyricLineData(id: 'raw-preview', text: 'Raw selected preview'),
      ],
    );
    const alternative = SourceVersionData(
      id: 'alternative',
      providerId: 'archive',
      providerName: 'Archive',
      title: 'Signal Song',
      artist: 'The Signals',
      durationSeconds: 180,
      hasLyrics: true,
      isUsableVersion: true,
      canSave: true,
      bodyPreview: [
        LyricLineData(id: 'alternative-preview', text: 'Archive preview'),
      ],
    );
    final controller = _LiveFlowController(
      const VerseUiState(
        homeListMode: HomeListMode.online,
        query: 'signal',
        comparison: SearchComparisonData(
          reference: SearchReferenceData(
            id: 'signal',
            title: 'Signal Song',
            artist: 'The Signals',
          ),
          suggested: suggested,
          alternatives: [rawSource, alternative],
          selectedVersionId: 'raw-source',
        ),
      ),
    );
    addTearDown(controller.dispose);
    await _pumpHome(tester, controller);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(VerseHomeScreen)),
    );
    final suggestedRow = find.byKey(const ValueKey('version-row-suggested'));
    final alternativeRow = find.byKey(
      const ValueKey('version-row-alternative'),
    );
    final rawRow = find.byKey(const ValueKey('version-row-raw-source'));
    expect(suggestedRow, findsNothing);
    expect(alternativeRow, findsOneWidget);
    expect(rawRow, findsOneWidget);
    expect(find.text(l10n.searchReadyVersions(2)), findsOneWidget);
    expect(tester.widget<ChoiceChip>(rawRow).selected, isTrue);
    expect(find.text('Raw selected preview'), findsOneWidget);
    final orderBefore = _rowOrder(tester);

    await tester.tap(alternativeRow);
    await tester.pumpAndSettle();
    expect(controller.state.comparison!.selectedVersionId, 'alternative');
    expect(find.text('Archive preview'), findsOneWidget);
    expect(find.text(l10n.searchReadyVersions(2)), findsOneWidget);
    expect(_rowOrder(tester), orderBefore);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('single-source combined and provider tabs count separately', (
    tester,
  ) async {
    const source = SourceVersionData(
      id: 'one',
      providerId: 'catalog',
      providerName: 'Catalog',
      title: 'Signal Song',
      artist: 'The Signals',
      hasLyrics: true,
      isUsableVersion: true,
      canSave: true,
    );
    const suggested = SourceVersionData(
      id: 'combined',
      providerId: 'combined',
      providerName: 'Catalog',
      title: 'Signal Song',
      artist: 'The Signals',
      sourceCount: 1,
      underlyingSourceId: 'one',
      hasLyrics: true,
      isUsableVersion: true,
      canSave: true,
    );
    const other = SourceVersionData(
      id: 'two',
      providerId: 'archive',
      providerName: 'Archive',
      title: 'Signal Song',
      artist: 'The Signals',
      hasLyrics: true,
      isUsableVersion: true,
      canSave: true,
    );
    final controller = _LiveFlowController(
      const VerseUiState(
        homeListMode: HomeListMode.online,
        query: 'signal',
        comparison: SearchComparisonData(
          reference: SearchReferenceData(
            id: 'signal',
            title: 'Signal Song',
            artist: 'The Signals',
          ),
          suggested: suggested,
          alternatives: [source],
          selectedVersionId: 'combined',
        ),
      ),
    );
    addTearDown(controller.dispose);
    await _pumpHome(tester, controller);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(VerseHomeScreen)),
    );
    expect(find.text(l10n.searchReadyVersions(2)), findsOneWidget);
    expect(find.byKey(const ValueKey('version-row-one')), findsOneWidget);
    controller._state = const VerseUiState(
      homeListMode: HomeListMode.online,
      query: 'signal',
      comparison: SearchComparisonData(
        reference: SearchReferenceData(
          id: 'signal',
          title: 'Signal Song',
          artist: 'The Signals',
        ),
        suggested: suggested,
        alternatives: [source, other],
        selectedVersionId: 'combined',
      ),
    );
    controller.notifyListeners();
    await tester.pump();
    expect(find.text(l10n.searchReadyVersions(3)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('version-row-two')));
    await tester.pump();
    expect(controller.state.comparison?.selectedVersionId, 'two');
    expect(find.text(l10n.searchReadyVersions(3)), findsOneWidget);
    expect(find.byKey(const ValueKey('version-row-one')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late combined contributors retain the explicit raw choice and raw order',
    (tester) async {
      const source = SourceVersionData(
        id: 'one',
        providerId: 'catalog',
        providerName: 'Catalog',
        title: 'Signal Song',
        artist: 'The Signals',
        hasLyrics: true,
        isUsableVersion: true,
        canSave: true,
        bodyPreview: [
          LyricLineData(id: 'raw', text: 'Explicit raw source lyrics'),
        ],
      );
      const other = SourceVersionData(
        id: 'two',
        providerId: 'archive',
        providerName: 'Archive',
        title: 'Signal Song',
        artist: 'The Signals',
        hasLyrics: true,
        isUsableVersion: true,
        canSave: true,
      );
      VerseUiState state(int count, [String selectedId = 'one']) =>
          VerseUiState(
            homeListMode: HomeListMode.online,
            query: 'signal',
            comparison: SearchComparisonData(
              reference: const SearchReferenceData(
                id: 'signal',
                title: 'Signal Song',
                artist: 'The Signals',
              ),
              suggested: SourceVersionData(
                id: 'combined',
                providerId: 'combined',
                providerName: 'Catalog',
                title: 'Signal Song',
                artist: 'The Signals',
                sourceCount: count,
                bodyPreview: const [
                  LyricLineData(
                    id: 'recipe',
                    text: 'Future combined recipe lyrics',
                  ),
                ],
                underlyingSourceId: count == 1 ? 'one' : null,
                hasLyrics: true,
                isUsableVersion: true,
                canSave: true,
              ),
              alternatives: const [source, other],
              selectedVersionId: selectedId,
            ),
          );
      final controller = _LiveFlowController(state(1, 'combined'));
      addTearDown(controller.dispose);
      await _pumpHome(tester, controller);
      await tester.tap(find.byKey(const ValueKey('version-row-one')));
      await tester.pumpAndSettle();
      expect(controller.state.comparison?.selectedVersionId, 'one');
      expect(find.text('Explicit raw source lyrics'), findsOneWidget);
      final raw = find.byKey(const ValueKey('version-row-one'));
      expect(
        _rowOrder(tester).indexOf('version-row-one'),
        lessThan(_rowOrder(tester).indexOf('version-row-two')),
      );
      controller._state = state(2);
      controller.notifyListeners();
      await tester.pump();
      expect(controller.state.comparison?.selectedVersionId, 'one');
      expect(find.text('Explicit raw source lyrics'), findsOneWidget);
      expect(tester.widget<ChoiceChip>(raw).selected, isTrue);
      expect(
        _rowOrder(tester).indexOf('version-row-one'),
        lessThan(_rowOrder(tester).indexOf('version-row-two')),
      );
      expect(
        find.byKey(const ValueKey('version-row-combined')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('version-row-combined')),
      );
      await tester.tap(find.byKey(const ValueKey('version-row-combined')));
      await tester.pumpAndSettle();
      expect(
        controller.state.comparison?.selectedVersionId,
        'combined',
        reason:
            'selection history=${controller.selectionHistory}; page=${tester.widget<PageView>(find.byKey(const ValueKey("version-preview-pages"))).controller?.page}',
      );
      expect(find.text('Future combined recipe lyrics'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unavailable sources are grouped and cannot be saved', (
    tester,
  ) async {
    const usable = SourceVersionData(
      id: 'usable',
      providerId: 'catalog',
      providerName: 'Catalog',
      title: 'Signal Song',
      artist: 'The Signals',
      hasLyrics: true,
      isUsableVersion: true,
      canSave: true,
      bodyPreview: [LyricLineData(id: 'usable-line', text: 'Available lyrics')],
    );
    const missing = SourceVersionData(
      id: 'missing',
      providerId: 'archive',
      providerName: 'Archive',
      title: 'Signal Song',
      artist: 'The Signals',
      hasLyrics: false,
    );
    final controller = _LiveFlowController(
      const VerseUiState(
        homeListMode: HomeListMode.online,
        comparison: SearchComparisonData(
          reference: SearchReferenceData(
            id: 'signal',
            title: 'Signal Song',
            artist: 'The Signals',
          ),
          suggested: usable,
          alternatives: [missing],
          providerChecks: [
            SearchProviderCheckData(
              id: 'archive',
              name: 'Archive',
              state: 'unavailable',
            ),
          ],
        ),
      ),
    );
    addTearDown(controller.dispose);
    await _pumpHome(tester, controller);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(VerseHomeScreen)),
    );
    await tester.tap(find.byKey(const ValueKey('source-checks-button')));
    await tester.pumpAndSettle();
    final archive = find.byKey(const ValueKey('discovery-provider-archive'));
    expect(archive, findsOneWidget);
    await tester.tap(archive);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('source-check-details-archive')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('source-check-details-archive')),
        matching: find.text(l10n.searchProviderUnavailable),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('save-open-lyrics')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'filtered empty state clears all version filters and cannot save',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final controller = _LiveFlowController(
        const VerseUiState(
          homeListMode: HomeListMode.online,
          query: 'signal',
          searchState: LoadState.loaded,
          searchFilters: SearchFilterData(
            chordsOnly: true,
            timedOnly: true,
            language: 'uk',
            durationBucket: 'short',
          ),
          comparison: SearchComparisonData(
            reference: SearchReferenceData(
              id: 'signal',
              title: 'Signal Song',
              artist: 'The Signals',
            ),
            suggested: null,
            alternatives: [
              SourceVersionData(
                id: 'lyrics-only',
                providerId: 'catalog',
                providerName: 'Catalog',
                title: 'Signal Song',
                artist: 'The Signals',
                hasLyrics: true,
                isUsableVersion: false,
              ),
            ],
          ),
        ),
      );
      addTearDown(controller.dispose);
      await _pumpHome(tester, controller);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(VerseHomeScreen)),
      );
      expect(
        find.byKey(const ValueKey('version-filters-empty')),
        findsOneWidget,
      );
      expect(find.text(l10n.emptyFiltered), findsOneWidget);
      expect(find.text(l10n.actionClear), findsOneWidget);
      expect(find.byKey(const ValueKey('save-open-lyrics')), findsNothing);

      await tester.tap(find.text(l10n.actionClear));
      await tester.pumpAndSettle();
      expect(controller.searchFilterChanges, [
        ('chordsOnly', false),
        ('timedOnly', false),
        ('language', ''),
        ('durationBucket', ''),
      ]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'filter changes during tab animation preserve selection and Clear restores pages',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const versions = [
        SourceVersionData(
          id: 'a',
          providerId: 'one',
          providerName: 'Source A',
          title: 'Signal Song',
          artist: 'The Signals',
          hasLyrics: true,
          hasChords: true,
          isUsableVersion: true,
          canSave: true,
          bodyPreview: [
            LyricLineData(id: 'a-preview', text: 'Source A preview'),
          ],
        ),
        SourceVersionData(
          id: 'b',
          providerId: 'two',
          providerName: 'Source B',
          title: 'Signal Song',
          artist: 'The Signals',
          hasLyrics: true,
          hasChords: true,
          isUsableVersion: true,
          canSave: true,
          bodyPreview: [
            LyricLineData(id: 'b-preview', text: 'Source B preview'),
          ],
        ),
        SourceVersionData(
          id: 'c',
          providerId: 'three',
          providerName: 'Source C',
          title: 'Signal Song',
          artist: 'The Signals',
          hasLyrics: true,
          hasChords: false,
          isUsableVersion: true,
          canSave: true,
          bodyPreview: [
            LyricLineData(id: 'c-preview', text: 'Source C preview'),
          ],
        ),
      ];
      const initial = VerseUiState(
        homeListMode: HomeListMode.online,
        query: 'signal',
        comparison: SearchComparisonData(
          reference: SearchReferenceData(
            id: 'signal',
            title: 'Signal Song',
            artist: 'The Signals',
          ),
          suggested: null,
          alternatives: versions,
          selectedVersionId: 'b',
        ),
      );
      final controller = _FilteringFlowController(initial, versions);
      addTearDown(controller.dispose);
      await _pumpHome(tester, controller);
      _assertActivePreview(tester, 'b', 'Source B preview');

      await tester.tap(find.byKey(const ValueKey('version-row-a')));
      await tester.pump(const Duration(milliseconds: 40));
      controller.setSearchFilter('chordsOnly', true);
      await tester.pumpAndSettle();
      expect(controller.state.comparison!.selectedVersionId, 'a');
      _assertActivePreview(tester, 'a', 'Source A preview');
      expect(find.byKey(const ValueKey('version-row-c')), findsNothing);

      controller.setSearchFilter('chordsOnly', false);
      await tester.pumpAndSettle();
      expect(controller.state.comparison!.selectedVersionId, 'a');
      _assertActivePreview(tester, 'a', 'Source A preview');
      expect(find.byKey(const ValueKey('version-row-c')), findsOneWidget);
      controller.setSearchFilter('chordsOnly', true);
      await tester.pumpAndSettle();
      expect(controller.state.comparison!.selectedVersionId, 'a');
      _assertActivePreview(tester, 'a', 'Source A preview');

      controller.setSearchFilter('timedOnly', true);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('version-filters-empty')),
        findsOneWidget,
      );
      expect(controller.state.comparison!.selected, isNull);
      expect(controller.state.comparison!.selectedVersionId, isNull);
      expect(find.byKey(const ValueKey('save-open-lyrics')), findsNothing);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(VerseHomeScreen)),
      );
      await tester.tap(find.text(l10n.actionClear));
      await tester.pumpAndSettle();
      expect(controller.state.searchFilters.chordsOnly, isFalse);
      expect(controller.state.searchFilters.timedOnly, isFalse);
      expect(controller.state.comparison!.selected?.id, 'a');
      _assertActivePreview(tester, 'a', 'Source A preview');
      expect(find.byKey(const ValueKey('version-row-c')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'filter rebuilds and zero matches preserve the active reading position',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final versions = [
        for (final id in ['a', 'b'])
          SourceVersionData(
            id: id,
            providerId: id,
            providerName: 'Source $id',
            title: 'Long song',
            artist: 'The Signals',
            hasLyrics: true,
            hasChords: id == 'a',
            isUsableVersion: true,
            canSave: true,
            bodyLines: [
              for (var i = 0; i < 60; i++)
                LyricLineData(id: '$id-$i', text: 'Source $id lyric line $i'),
            ],
          ),
      ];
      final controller = _FilteringFlowController(
        VerseUiState(
          homeListMode: HomeListMode.online,
          comparison: SearchComparisonData(
            reference: const SearchReferenceData(
              id: 'long-song',
              title: 'Long song',
              artist: 'The Signals',
            ),
            suggested: versions.first,
            alternatives: versions,
            selectedVersionId: 'a',
          ),
        ),
        versions,
      );
      addTearDown(controller.dispose);
      await _pumpHome(tester, controller);

      Finder activeScrollable() => find
          .descendant(
            of: find.descendant(
              of: find.byKey(const ValueKey('a')),
              matching: find.byKey(const ValueKey('full-preview-body')),
            ),
            matching: find.byType(Scrollable),
          )
          .first;
      final passage = find.descendant(
        of: find.byKey(const ValueKey('a')),
        matching: find.byKey(const ValueKey('preview-line-a-30')),
      );
      await tester.scrollUntilVisible(
        passage,
        250,
        scrollable: activeScrollable(),
      );
      await Scrollable.ensureVisible(tester.element(passage), alignment: .2);
      await tester.pumpAndSettle();
      final originalState = tester.state<ScrollableState>(activeScrollable());
      final offset = originalState.position.pixels;
      final passageTop = tester.getTopLeft(passage).dy;
      expect(offset, greaterThan(1000));

      void expectRestored() {
        final active = tester.state<ScrollableState>(activeScrollable());
        // Assert the rebuilt page, not a retained reference to the old page.
        expect(active, isNot(same(originalState)));
        expect(active.position.pixels, closeTo(offset, .01));
        expect(tester.getTopLeft(passage).dy, closeTo(passageTop, .01));
        expect(passage.hitTestable(), findsOneWidget);
      }

      controller.setSearchFilter('chordsOnly', true);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('version-row-b')), findsNothing);
      expectRestored();
      controller.setSearchFilter('chordsOnly', false);
      await tester.pumpAndSettle();
      expectRestored();

      controller.setSearchFilter('timedOnly', true);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('version-filters-empty')),
        findsOneWidget,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(VerseHomeScreen)),
      );
      await tester.tap(find.text(l10n.actionClear));
      await tester.pumpAndSettle();
      expectRestored();

      await tester.tap(find.byKey(const ValueKey('version-row-b')));
      await tester.pumpAndSettle();
      Finder sourceBScrollable() => find
          .descendant(
            of: find.descendant(
              of: find.byKey(const ValueKey('b')),
              matching: find.byKey(const ValueKey('full-preview-body')),
            ),
            matching: find.byType(Scrollable),
          )
          .first;
      final sourceBPassage = find.descendant(
        of: find.byKey(const ValueKey('b')),
        matching: find.byKey(const ValueKey('preview-line-b-45')),
      );
      await tester.scrollUntilVisible(
        sourceBPassage,
        250,
        scrollable: sourceBScrollable(),
      );
      await Scrollable.ensureVisible(
        tester.element(sourceBPassage),
        alignment: .2,
      );
      await tester.pumpAndSettle();
      final sourceBOffset = tester
          .state<ScrollableState>(sourceBScrollable())
          .position
          .pixels;
      expect(sourceBOffset, greaterThan(offset + 500));
      controller.setSearchFilter('chordsOnly', true);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('version-row-b')), findsNothing);
      expectRestored();
      controller.setSearchFilter('chordsOnly', false);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('version-row-b')));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(sourceBScrollable()).position.pixels,
        closeTo(sourceBOffset, .01),
      );
      expect(sourceBPassage.hitTestable(), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('version-row-a')));
      await tester.pump(const Duration(milliseconds: 40));
      controller.setSearchFilter('chordsOnly', true);
      await tester.pumpAndSettle();
      expectRestored();

      controller._state = VerseUiState(
        homeListMode: HomeListMode.online,
        comparison: SearchComparisonData(
          reference: const SearchReferenceData(
            id: 'different-song',
            title: 'Different song',
            artist: 'The Signals',
          ),
          suggested: versions.first,
          alternatives: versions,
          selectedVersionId: 'b',
        ),
      );
      controller.notifyListeners();
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(sourceBScrollable()).position.pixels,
        0,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final configuration in [
    (const Size(360, 640), 1.0, 'en'),
    (const Size(640, 360), 2.0, 'ar'),
  ]) {
    testWidgets('version info sheet preserves preview space $configuration', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = configuration.$1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const versions = [
        SourceVersionData(
          id: 'a',
          providerId: 'a',
          providerName: 'Source A',
          title: 'Signal Song',
          artist: 'The Signals',
          hasLyrics: true,
          hasChords: true,
          canSave: true,
          isUsableVersion: true,
          bodyPreview: [LyricLineData(id: 'a-line', text: 'Source A preview')],
        ),
        SourceVersionData(
          id: 'b',
          providerId: 'b',
          providerName: 'Source B',
          title: 'Signal Song',
          artist: 'The Signals',
          hasLyrics: true,
          canSave: true,
          isUsableVersion: true,
          bodyPreview: [LyricLineData(id: 'b-line', text: 'Source B preview')],
        ),
      ];
      final controller = _FilteringFlowController(
        const VerseUiState(
          homeListMode: HomeListMode.online,
          comparison: SearchComparisonData(
            reference: SearchReferenceData(
              id: 'signal',
              title: 'Signal Song',
              artist: 'The Signals',
            ),
            suggested: null,
            alternatives: versions,
            selectedVersionId: 'b',
          ),
        ),
        versions,
      );
      addTearDown(controller.dispose);
      await _pumpHome(
        tester,
        controller,
        scale: configuration.$2,
        language: configuration.$3,
      );
      final before = tester
          .getSize(find.byKey(const ValueKey('version-preview-pages')))
          .height;
      final l10n = AppLocalizations.of(
        tester.element(find.byType(VerseHomeScreen)),
      );
      await tester.tap(find.byKey(const ValueKey('version-info-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('version-info-sheet')), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.navClose));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('version-info-sheet')), findsNothing);
      expect(find.byKey(const ValueKey('version-row-b')), findsOneWidget);
      if (configuration.$2 > 1) {
        await tester.ensureVisible(
          find.descendant(
            of: find.byKey(const ValueKey('b')),
            matching: find.text('Source B preview'),
          ),
        );
        await tester.pumpAndSettle();
      }
      _assertActivePreview(tester, 'b', 'Source B preview');
      expect(
        tester
            .getSize(find.byKey(const ValueKey('version-preview-pages')))
            .height,
        closeTo(before, 1),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('large text comparison remains usable in landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(804, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _LiveFlowController(_comparisonState());
    addTearDown(controller.dispose);
    await _pumpHome(tester, controller, scale: 1.5);

    expect(
      find.byKey(const ValueKey('version-selection-footer')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('save-open-lyrics')), findsOneWidget);
    expect(find.byKey(const ValueKey('version-info-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('source-checks-button')), findsOneWidget);
    expect(find.text('First source preview').hitTestable(), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'native-shaped short landscape shows chords and match above Save',
    (tester) async {
      tester.view.devicePixelRatio = 2.625;
      tester.view.physicalSize = const Size(2400, 1080);
      tester.view.padding = const FakeViewPadding(
        left: 136,
        top: 74,
        right: 0,
        bottom: 63,
      );
      tester.view.viewPadding = const FakeViewPadding(
        left: 136,
        top: 74,
        right: 0,
        bottom: 63,
      );
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      final controller = _LiveFlowController(_denseLandscapeComparisonState());
      addTearDown(controller.dispose);
      final semantics = tester.ensureSemantics();
      try {
        await _pumpHome(tester, controller, productionFrame: true);

        final chord = find.bySemanticsLabel('E');
        final save = find.byKey(const ValueKey('save-open-lyrics'));
        expect(chord.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(chord).bottom,
          lessThanOrEqualTo(tester.getRect(save).top),
        );
        expect(
          find.text('Synthetic fixture is a title and duration match.')
              .hitTestable(),
          findsOneWidget,
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(VerseHomeScreen)),
        );
        expect(
          find.text(l10n.playerEstimatedPace).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('version-selection-footer')),
          findsOneWidget,
        );
        for (final key in [
          const ValueKey('version-info-button'),
          const ValueKey('source-checks-button'),
        ]) {
          final button = find.byKey(key);
          expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('tall landscape comparison keeps inline source contributions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _LiveFlowController(_landscapeComparisonState());
    addTearDown(controller.dispose);
    await _pumpHome(tester, controller);

    expect(find.textContaining('Catalog contributor').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('landscape preview keeps rich lyrics and contributor details', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(914, 411);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _LiveFlowController(_landscapeComparisonState());
    addTearDown(controller.dispose);
    final semantics = tester.ensureSemantics();
    try {
      await _pumpHome(tester, controller);

      final chord = find.bySemanticsLabel('E');
      final save = find.byKey(const ValueKey('save-open-lyrics'));
      expect(chord.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(chord).bottom,
        lessThanOrEqualTo(tester.getRect(save).top),
      );

      final lyric = find.text(
        'Original QA melody phrase 1 follows the harbor lights.',
      );
      await tester.ensureVisible(lyric);
      await tester.pumpAndSettle();
      expect(lyric.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(lyric).bottom,
        lessThanOrEqualTo(tester.getRect(save).top),
      );

      await tester.tap(find.byKey(const ValueKey('version-info-button')));
      await tester.pumpAndSettle();
      final sheet = find.byKey(const ValueKey('version-info-sheet'));
      expect(sheet, findsOneWidget);
      final provider = find.text('Catalog contributor');
      await tester.scrollUntilVisible(
        provider,
        120,
        scrollable: find.descendant(
          of: sheet,
          matching: find.byType(Scrollable),
        ).first,
        maxScrolls: 12,
      );
      await tester.pumpAndSettle();
      expect(provider.hitTestable(), findsOneWidget);
      expect(tester.getRect(provider).top, greaterThanOrEqualTo(tester.getRect(sheet).top));
      expect(tester.getRect(provider).bottom, lessThanOrEqualTo(tester.getRect(sheet).bottom));
      final contribution = find.ancestor(of: provider, matching: find.byType(Column)).first;
      final role = find.descendant(of: contribution, matching: find.byWidgetPredicate(
        (widget) => widget is SelectableText && widget.data == 'Lyrics',
      ));
      expect(role.hitTestable(), findsOneWidget);
      expect(tester.getRect(role).bottom, lessThanOrEqualTo(tester.getRect(sheet).bottom));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'reader falls back from timed mode without timing and offers scroll speed',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 804);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final controller = _LiveFlowController(
        const VerseUiState(
          route: VerseRoute.reader,
          song: SongCardData(id: 'song', title: 'Signal Song'),
          songLines: [
            LyricLineData(id: 'line-1', text: 'The first lyric line'),
            LyricLineData(id: 'line-2', text: 'The second lyric line'),
            LyricLineData(id: 'line-3', text: 'The third lyric line'),
          ],
          autoscroll: false,
          timingMode: 'timed',
          readerDurationEstimated: true,
          readerHasTiming: false,
          playbackSpeed: 1,
        ),
      );
      addTearDown(controller.dispose);

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
          home: Scaffold(body: PlayerScreen(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PlayerScreen)),
      );
      expect(find.text(l10n.playerLyricsOnly), findsNothing);
      expect(find.text('1:30'), findsOneWidget);
      expect(find.text(l10n.playerEstimatedDuration('1:30')), findsNothing);
      expect(find.text(l10n.playerEstimatedPace), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == l10n.playerEstimatedDuration('1:30'),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.playerPlay), findsOneWidget);
      expect(find.byKey(const ValueKey('scroll-speed-slider')), findsNothing);
      final speedToggle = find.byKey(const ValueKey('scroll-speed-toggle'));
      await tester.ensureVisible(speedToggle);
      await tester.pumpAndSettle();
      expect(speedToggle.hitTestable(), findsOneWidget);
      await tester.tap(speedToggle);
      await tester.pumpAndSettle();
      final speedSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('scroll-speed-slider')),
      );
      expect(speedSlider.divisions, isNull);
      expect(
        speedSlider.semanticFormatterCallback!(1.5),
        contains(l10n.playerScrollSpeed),
      );
      speedSlider.onChanged!(1.5);
      await tester.pump();
      expect(controller.selectedSpeed, 1.5);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('scroll-speed-panel')),
          matching: find.text('1:00'),
        ),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('start-lyric-scroll')));
      await tester.pump();
      expect(controller.autoscrollEnabled, isTrue);
      expect(controller.estimatedTimingRequested, isTrue);
      expect(controller.playbackStarted, isTrue);

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('speed-scaled timeline seeks to the matching song position', (
    tester,
  ) async {
    final controller = _LiveFlowController(
      const VerseUiState(
        route: VerseRoute.reader,
        song: SongCardData(id: 'song', title: 'Song', durationSeconds: 90),
        songLines: [LyricLineData(id: 'line', text: 'Lyric')],
        readerHasTiming: false,
        readerDurationEstimated: false,
        playbackSpeed: 1.5,
      ),
    );
    addTearDown(controller.dispose);
    await _pumpPlayer(tester, controller);

    expect(find.text('1:00'), findsOneWidget);
    final seek = tester.widget<Slider>(
      find.byKey(const ValueKey('player-seek-slider')),
    );
    seek.onChanged!(30);
    expect(controller.lastSeekSeconds, 45);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('timed lyrics still expose the active playback speed', (
    tester,
  ) async {
    final controller = _LiveFlowController(
      const VerseUiState(
        route: VerseRoute.reader,
        song: SongCardData(
          id: 'timed-song',
          title: 'Timed Song',
          durationSeconds: 90,
        ),
        songLines: [LyricLineData(id: 'line', text: 'Timed lyric')],
        readerHasTiming: true,
        readerDurationEstimated: false,
        playbackSpeed: .5,
      ),
    );
    addTearDown(controller.dispose);
    await _pumpPlayer(tester, controller);

    await tester.tap(find.byKey(const ValueKey('scroll-speed-toggle')));
    await tester.pumpAndSettle();
    final speedSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('scroll-speed-slider')),
    );
    expect(speedSlider.value, .5);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scroll-speed-panel')),
        matching: find.text('3:00'),
      ),
      findsOneWidget,
    );
    speedSlider.onChanged!(1.25);
    await tester.pump();
    expect(controller.selectedSpeed, 1.25);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scroll-speed-panel')),
        matching: find.text('1:12'),
      ),
      findsOneWidget,
    );
    expect(controller.selectedSpeed, 1.25);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reader offers available timing without leaving the song', (
    tester,
  ) async {
    final controller = _LiveFlowController(
      const VerseUiState(
        route: VerseRoute.reader,
        song: SongCardData(id: 'timed', title: 'Original timed fixture'),
        songLines: [LyricLineData(id: 'one', text: 'An original timed line')],
        readerTimingAvailable: true,
        timingMode: 'estimated',
      ),
    );
    await _pumpPlayer(tester, controller);
    final l10n = AppLocalizations.of(tester.element(find.byType(PlayerScreen)));
    expect(find.text(l10n.playerEstimatedPace), findsNothing);
    await tester.tap(find.byTooltip(l10n.songMenuLabel));
    await tester.pumpAndSettle();
    final timedLyrics = find.byWidgetPredicate(
      (widget) =>
          widget is CheckedPopupMenuItem<String> &&
          widget.value == 'timed-lyrics',
    );
    expect(timedLyrics, findsOneWidget);
    expect(
      tester.widget<CheckedPopupMenuItem<String>>(timedLyrics).checked,
      isFalse,
    );
    await tester.tap(find.text(l10n.playerTimedLyrics));
    await tester.pumpAndSettle();
    expect(controller.selectedTimingMode, 'timed');
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('speed value stays on one line at 2x in portrait and landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in const [Size(360, 804), Size(872, 393)]) {
      tester.view.physicalSize = size;
      final controller = _LiveFlowController(
        const VerseUiState(
          route: VerseRoute.reader,
          song: SongCardData(
            id: 'speed-song',
            title: 'Original test song',
            durationSeconds: 210,
          ),
          songLines: [
            LyricLineData(id: 'verse', text: 'An original test line'),
          ],
          playerSections: [
            PlayerSectionMarker(
              name: 'Verse',
              startSeconds: 0,
              lineId: 'verse',
            ),
          ],
          playbackSpeed: 1.05,
        ),
      );
      await _pumpPlayer(tester, controller, scale: 2);
      final value = find.byKey(const ValueKey('scroll-speed-value'));
      expect(find.text('1.05×'), findsOneWidget);
      final text = tester.widget<Text>(value);
      expect(text.maxLines, 1);
      expect(text.softWrap, false);
      await tester.ensureVisible(value);
      await tester.pumpAndSettle();
      expect(value.hitTestable(), findsOneWidget);
      final rect = tester.getRect(value);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });

  testWidgets('large text keeps section transport controls usable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = _LiveFlowController(
      const VerseUiState(
        route: VerseRoute.reader,
        song: SongCardData(id: 'song', title: 'Song'),
        songLines: [
          LyricLineData(id: 'intro', text: 'Intro lyric'),
          LyricLineData(id: 'verse', text: 'Verse lyric'),
          LyricLineData(id: 'chorus', text: 'Chorus lyric'),
        ],
        playerSections: [
          PlayerSectionMarker(name: 'Intro', startSeconds: 0, lineId: 'intro'),
          PlayerSectionMarker(name: 'Verse', startSeconds: 30, lineId: 'verse'),
          PlayerSectionMarker(
            name: 'Chorus',
            startSeconds: 60,
            lineId: 'chorus',
          ),
        ],
        readerDurationEstimated: true,
        readerHasTiming: false,
        playbackSpeed: 1,
      ),
    );
    addTearDown(controller.dispose);

    const profiles = [
      (size: Size(520, 390), scale: 1.5, locale: Locale('en')),
      (size: Size(440, 956), scale: 1.6, locale: Locale('ar')),
      (size: Size(956, 440), scale: 1.6, locale: Locale('ar')),
    ];
    for (final profile in profiles) {
      tester.view.physicalSize = profile.size;
      await _pumpPlayer(
        tester,
        controller,
        scale: profile.scale,
        locale: profile.locale,
      );
      final playerContext = tester.element(find.byType(PlayerScreen));
      final l10n = AppLocalizations.of(playerContext);
      expect(
        Localizations.localeOf(playerContext).languageCode,
        profile.locale.languageCode,
      );
      expect(
        Directionality.of(playerContext),
        profile.locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
      );
      final start = find.byKey(const ValueKey('start-lyric-scroll'));
      final previous = find.byTooltip(l10n.playerPreviousSection);
      final next = find.byTooltip(l10n.playerNextSection);
      final speed = find.byKey(const ValueKey('scroll-speed-toggle'));
      expect(
        previous,
        findsOneWidget,
        reason: '${profile.locale} ${profile.size}',
      );
      expect(next, findsOneWidget, reason: '${profile.locale} ${profile.size}');
      expect(
        speed,
        findsOneWidget,
        reason: '${profile.locale} ${profile.size}',
      );
      expect(
        start,
        findsOneWidget,
        reason: '${profile.locale} ${profile.size}',
      );
      for (final control in [previous, start, speed, next]) {
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        expect(control.hitTestable(), findsOneWidget);
        final rect = tester.getRect(control);
        expect(rect.left, greaterThanOrEqualTo(-1e-6));
        expect(rect.right, lessThanOrEqualTo(profile.size.width + 1e-6));
        expect(rect.top, greaterThanOrEqualTo(-1e-6));
        expect(rect.bottom, lessThanOrEqualTo(profile.size.height + 1e-6));
      }
      final label = find.descendant(of: start, matching: find.byType(Text));
      expect(
        tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
        isFalse,
      );
      final layoutError = tester.takeException();
      final playerRect = tester.getRect(find.byType(PlayerScreen));
      final controlsRect = tester.getRect(
        find.ancestor(of: start, matching: find.byType(SafeArea)).first,
      );
      expect(
        layoutError,
        isNull,
        reason:
            'profile=${profile.locale}/${profile.size}/${profile.scale}; '
            'player=$playerRect controls=$controlsRect; '
            '${layoutError is FlutterError ? layoutError.toStringDeep() : layoutError}',
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('landscape reader fits metadata with comparison in overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(872, 393);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewPadding);
    final controller = _LiveFlowController(
      const VerseUiState(
        route: VerseRoute.reader,
        song: SongCardData(
          id: 'song',
          title: 'Signal Song',
          artist: 'Artist Name',
          album: 'Album Name',
          durationSeconds: 247,
        ),
        songLines: [
          LyricLineData(id: 'line-1', text: 'The first lyric line'),
          LyricLineData(id: 'line-2', text: 'The second lyric line'),
          LyricLineData(id: 'line-3', text: 'The third lyric line'),
        ],
        readerSource: 'LRCLIB',
        readerCanCompareVersions: true,
        readerHasTiming: false,
        readerDurationEstimated: false,
        playbackSpeed: 1,
      ),
    );
    addTearDown(controller.dispose);

    await _pumpPlayer(tester, controller);
    final l10n = AppLocalizations.of(tester.element(find.byType(PlayerScreen)));
    expect(find.text('Artist Name'), findsOneWidget);
    expect(find.text(l10n.searchCompare), findsNothing);
    expect(find.text(l10n.playerLyricsOnly), findsNothing);
    final start = find.byKey(const ValueKey('start-lyric-scroll'));
    final speed = find.byKey(const ValueKey('scroll-speed-toggle'));
    expect(start, findsOneWidget);
    expect(speed, findsOneWidget);
    for (final control in [start, speed]) {
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      expect(control.hitTestable(), findsOneWidget);
      final rect = tester.getRect(control);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(872));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(393));
    }
    await _expectLandscapeSongInfo(tester, l10n);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('landscape reader keeps primary controls reachable with chords', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(872, 393);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewPadding);
    final controller = _LiveFlowController(
      const VerseUiState(
        route: VerseRoute.reader,
        song: SongCardData(
          id: 'song',
          title: 'Signal Song',
          artist: 'Artist Name',
          album: 'Album Name',
          durationSeconds: 247,
          hasChords: true,
        ),
        songLines: [
          LyricLineData(
            id: 'line-1',
            text: 'The first lyric line',
            chords: [LyricChord(graphemeOffset: 0, symbol: 'C')],
          ),
          LyricLineData(
            id: 'line-2',
            text: 'The second lyric line',
            chords: [LyricChord(graphemeOffset: 0, symbol: 'G')],
          ),
        ],
        playerSections: [
          PlayerSectionMarker(name: 'Verse', startSeconds: 0, lineId: 'line-1'),
          PlayerSectionMarker(
            name: 'Chorus',
            startSeconds: 60,
            lineId: 'line-2',
          ),
        ],
        readerSource: 'LRCLIB',
        readerCanCompareVersions: true,
        readerHasTiming: false,
        readerDurationEstimated: false,
        playbackSpeed: 1,
      ),
    );
    addTearDown(controller.dispose);

    await _pumpPlayer(tester, controller, scale: 1.5);
    final l10n = AppLocalizations.of(tester.element(find.byType(PlayerScreen)));
    final start = find.byKey(const ValueKey('start-lyric-scroll'));
    final speed = find.byKey(const ValueKey('scroll-speed-toggle'));
    final nextSection = find.byTooltip(l10n.playerNextSection);
    final chords = find.byKey(const ValueKey('pitch-key-dropdown'));
    expect(find.text('Artist Name'), findsOneWidget);
    expect(find.text(l10n.searchCompare), findsNothing);
    expect(start, findsOneWidget);
    expect(speed, findsOneWidget);
    expect(nextSection, findsOneWidget);
    expect(chords, findsOneWidget);
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    expect(start.hitTestable(), findsOneWidget);
    final startRect = tester.getRect(start);
    expect(startRect.top, greaterThanOrEqualTo(0));
    expect(startRect.bottom, lessThanOrEqualTo(393));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(chords);
    await tester.pumpAndSettle();
    final chordsRect = tester.getRect(chords);
    expect(chordsRect.top, greaterThanOrEqualTo(0));
    expect(chordsRect.bottom, lessThanOrEqualTo(393));
    expect(chords.hitTestable(), findsOneWidget);
    await _expectLandscapeSongInfo(tester, l10n);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('current lyric stays visible after rotating in landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 872);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewPadding);
    final lines = [
      for (var index = 0; index < 24; index++)
        LyricLineData(id: 'line-$index', text: 'Rotation lyric $index'),
    ];
    final controller = _LiveFlowController(
      VerseUiState(
        route: VerseRoute.reader,
        song: const SongCardData(
          id: 'song',
          title: 'Rotation Song',
          artist: 'Artist Name',
          album: 'Album Name',
          durationSeconds: 247,
          hasChords: true,
        ),
        songLines: lines,
        readerSource: 'LRCLIB',
        readerCanCompareVersions: true,
        readerHasTiming: false,
        currentLineId: 'line-18',
        progressSeconds: 183,
      ),
    );
    addTearDown(controller.dispose);
    controller._position.value = const PlayerPosition(183, 'line-18');

    await _pumpPlayer(tester, controller, scale: 1.5);
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(PlayerScreen)));
    expect(find.text('Artist Name · Album Name'), findsOneWidget);
    expect(find.textContaining('LRCLIB'), findsOneWidget);
    expect(find.text(l10n.searchCompare), findsNothing);
    final targetLine = find.text('Rotation lyric 18');
    final lyricsList = find.byType(ListView).last;
    expect(
      _isVisibleWithin(tester.getRect(targetLine), tester.getRect(lyricsList)),
      isTrue,
    );

    tester.view.physicalSize = const Size(872, 393);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    await tester.pumpAndSettle();
    expect(
      _isVisibleWithin(tester.getRect(targetLine), tester.getRect(lyricsList)),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

bool _isVisibleWithin(Rect child, Rect viewport) =>
    child.top >= viewport.top && child.bottom <= viewport.bottom;

void _assertActivePreview(WidgetTester tester, String id, String previewText) {
  final chip = find.byKey(ValueKey('version-row-$id'));
  expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
  final page = find.byKey(ValueKey(id));
  expect(page, findsOneWidget);
  expect(
    find.descendant(of: page, matching: find.text(previewText)).hitTestable(),
    findsOneWidget,
  );
}

List<String> _rowOrder(WidgetTester tester) {
  final tabs = find.byKey(const ValueKey('version-tabs'));
  return tester
      .widgetList<ChoiceChip>(
        find.descendant(of: tabs, matching: find.byType(ChoiceChip)),
      )
      .map((chip) => (chip.key as ValueKey).value as String)
      .toList();
}

VerseUiState _comparisonState() => const VerseUiState(
  homeListMode: HomeListMode.online,
  query: 'signal',
  searchState: LoadState.loaded,
  comparison: SearchComparisonData(
    reference: SearchReferenceData(
      id: 'signal',
      title: 'Signal Song',
      artist: 'The Signals',
    ),
    suggested: SourceVersionData(
      id: 'suggested',
      providerId: 'catalog',
      providerName: 'Catalog',
      title: 'Signal Song',
      artist: 'The Signals',
      hasLyrics: true,
      isUsableVersion: true,
      canSave: true,
      bodyPreview: [
        LyricLineData(id: 'first-preview', text: 'First source preview'),
      ],
    ),
    alternatives: [
      SourceVersionData(
        id: 'second',
        providerId: 'archive-a',
        providerName: 'Archive A',
        title: 'Signal Song',
        artist: 'The Signals',
        hasLyrics: true,
        isUsableVersion: true,
        canSave: true,
        bodyPreview: [
          LyricLineData(id: 'second-preview', text: 'Second source preview'),
        ],
      ),
      SourceVersionData(
        id: 'third',
        providerId: 'archive-b',
        providerName: 'Archive B',
        title: 'Signal Song',
        artist: 'The Signals',
        hasLyrics: true,
        isUsableVersion: true,
        canSave: true,
        bodyPreview: [
          LyricLineData(id: 'third-preview', text: 'Third source preview'),
        ],
      ),
    ],
  ),
);

VerseUiState _landscapeComparisonState() => const VerseUiState(
  homeListMode: HomeListMode.online,
  query: 'qa melody',
  searchState: LoadState.loaded,
  comparison: SearchComparisonData(
    reference: SearchReferenceData(
      id: 'qa-melody',
      title: 'QA’s Melody',
      artist: 'QA',
      album: 'Small Weather',
      durationSeconds: 240,
    ),
    suggested: SourceVersionData(
      id: 'qa-chord-chart',
      providerId: 'catalog',
      providerName: 'QA Chord Chart',
      title: 'QA’s Melody',
      artist: 'QA',
      album: 'Small Weather',
      durationSeconds: 240,
      hasLyrics: true,
      hasChords: true,
      sameRecording: true,
      sourceCount: 2,
      contributions: [
        SourceContributionData(
          providerName: 'Catalog contributor',
          roles: ['lyrics'],
        ),
      ],
      isUsableVersion: true,
      canSave: true,
      bodyPreview: [
        LyricLineData(id: 'qa-preview-lyric', text: 'Preview melody'),
      ],
      bodyLines: [
        LyricLineData(id: 'qa-intro', section: 'Intro', isBlank: true),
        LyricLineData(
          id: 'qa-instrumental-chord',
          chords: [LyricChord(graphemeOffset: 0, symbol: 'E')],
        ),
        LyricLineData(
          id: 'qa-first-lyric',
          text: 'Original QA melody phrase 1 follows the harbor lights.',
          chords: [LyricChord(graphemeOffset: 0, symbol: 'E')],
        ),
      ],
    ),
  ),
);

VerseUiState _denseLandscapeComparisonState() => const VerseUiState(
  homeListMode: HomeListMode.online,
  query: 'qa melody',
  searchState: LoadState.loaded,
  comparison: SearchComparisonData(
    reference: SearchReferenceData(
      id: 'qa-melody-dense',
      title: 'QA’s Melody',
      artist: 'QA',
      album: 'Small Weather',
      durationSeconds: 240,
    ),
    suggested: SourceVersionData(
      id: 'qa-chord-chart-dense',
      providerId: 'catalog',
      providerName: 'QA Chord Chart',
      title: 'QA’s Melody',
      artist: 'QA',
      album: 'Small Weather',
      durationSeconds: 240,
      hasLyrics: true,
      hasChords: true,
      matchSummary: 'Synthetic fixture is a title and duration match.',
      isUsableVersion: true,
      canSave: true,
      bodyPreview: [
        LyricLineData(id: 'dense-preview-lyric', text: 'Preview melody'),
      ],
      bodyLines: [
        LyricLineData(id: 'dense-intro', section: 'Intro', isBlank: true),
        LyricLineData(
          id: 'dense-instrumental-e',
          chords: [LyricChord(graphemeOffset: 0, symbol: 'E')],
        ),
        LyricLineData(
          id: 'dense-instrumental-a-e',
          chords: [LyricChord(graphemeOffset: 0, symbol: 'A/E')],
        ),
        LyricLineData(
          id: 'dense-instrumental-am-e',
          chords: [LyricChord(graphemeOffset: 0, symbol: 'Am/E')],
        ),
        LyricLineData(
          id: 'dense-first-lyric',
          text: 'Original QA melody phrase 1 follows the harbor lights.',
          chords: [LyricChord(graphemeOffset: 0, symbol: 'E')],
        ),
      ],
    ),
  ),
);

Future<void> _pumpHome(
  WidgetTester tester,
  _LiveFlowController controller, {
  double scale = 1,
  String language = 'en',
  bool productionFrame = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Scaffold(
          appBar: controller.state.comparison == null
              ? null
              : AppBar(
                  toolbarHeight: 48,
                  leading: const BackButton(),
                  title: const Text('Compare'),
                ),
          body: SafeArea(
            top: false,
            bottom: false,
            left: productionFrame,
            right: productionFrame,
            child: VerseHomeScreen(
              controller: controller,
              state: controller.state,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPlayer(
  WidgetTester tester,
  _LiveFlowController controller, {
  double scale = 1,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: PlayerScreen(controller: controller)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectLandscapeSongInfo(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.tap(find.byTooltip(l10n.songMenuLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.songInfo));
  await tester.pumpAndSettle();
  for (final detail in ['Album Name', 'LRCLIB']) {
    final value = find.text(detail);
    await tester.ensureVisible(value);
    await tester.pumpAndSettle();
    expect(value.hitTestable(), findsOneWidget);
  }
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(find.byType(PlayerScreen), findsOneWidget);
}

class _LiveFlowController extends VerseUiController {
  _LiveFlowController(this._state)
    : _position = ValueNotifier(PlayerPosition.zero);
  VerseUiState _state;
  final ValueNotifier<PlayerPosition> _position;
  bool autoscrollEnabled = false;
  bool estimatedTimingRequested = false;
  String? selectedTimingMode;
  bool playbackStarted = false;
  double? selectedSpeed;
  double? lastSeekSeconds;
  final searchFilterChanges = <(String, Object?)>[];
  final selectionHistory = <String>[];

  @override
  ValueListenable<PlayerPosition> get playerPosition => _position;

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  VerseUiState get state => _state;

  @override
  SongInfoData? songInfo(String id) {
    final song = _state.song;
    if (song == null || song.id != id) return null;
    return SongInfoData(
      title: song.title,
      artist: song.artist,
      fields: {if (song.album != null) 'album': song.album},
      sources: [
        if (_state.readerSource != null)
          SongInfoSourceData(providerName: _state.readerSource!),
      ],
    );
  }

  @override
  void selectVersion(String versionId) {
    selectionHistory.add(versionId);
    final comparison = _state.comparison!;
    _state = VerseUiState(
      homeListMode: _state.homeListMode,
      query: _state.query,
      searchState: _state.searchState,
      comparison: SearchComparisonData(
        reference: comparison.reference,
        suggested: comparison.suggested,
        alternatives: comparison.alternatives,
        selectedVersionId: versionId,
      ),
    );
    notifyListeners();
  }

  @override
  Future<void> setAutoscroll(bool enabled) async {
    autoscrollEnabled = enabled;
  }

  @override
  Future<void> setTimingMode(String mode) async {
    estimatedTimingRequested = mode == 'estimated';
    selectedTimingMode = mode;
  }

  @override
  Future<void> playPause() async {
    playbackStarted = true;
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    selectedSpeed = speed;
    _state = _PlaybackSpeedState(_state, speed);
    notifyListeners();
  }

  @override
  Future<void> seek(double seconds) async {
    lastSeekSeconds = seconds;
  }

  @override
  void setSearchFilter(String key, Object? value) {
    searchFilterChanges.add((key, value));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PlaybackSpeedState extends VerseUiState {
  _PlaybackSpeedState(VerseUiState state, this._playbackSpeed)
    : super.withPosition(state, state.progressSeconds, state.currentLineId);

  @override
  double get playbackSpeed => _playbackSpeed;

  final double _playbackSpeed;
}

/// A small adapter-like fixture: filtering changes both the filter state and
/// the returned candidate list, while preserving the controller's canonical
/// selected source identity when that source temporarily disappears.
class _FilteringFlowController extends _LiveFlowController {
  _FilteringFlowController(super.initial, this._allVersions)
    : _filters = initial.searchFilters;

  final List<SourceVersionData> _allVersions;
  SearchFilterData _filters;

  @override
  void selectVersion(String versionId) {
    selectionHistory.add(versionId);
    final comparison = _state.comparison!;
    _state = VerseUiState(
      homeListMode: _state.homeListMode,
      query: _state.query,
      searchState: _state.searchState,
      searchFilters: _filters,
      comparison: SearchComparisonData(
        reference: comparison.reference,
        suggested: comparison.suggested,
        alternatives: comparison.alternatives,
        selectedVersionId: versionId,
        discovering: comparison.discovering,
        providerChecks: comparison.providerChecks,
      ),
    );
    notifyListeners();
  }

  @override
  void setSearchFilter(String key, Object? value) {
    final field = key == 'field' ? value as String : _filters.field;
    final language = key == 'language' ? value as String : _filters.language;
    final chordsOnly = key == 'chordsOnly'
        ? value as bool
        : _filters.chordsOnly;
    final timedOnly = key == 'timedOnly' ? value as bool : _filters.timedOnly;
    final durationBucket = key == 'durationBucket'
        ? value as String
        : _filters.durationBucket;
    _filters = SearchFilterData(
      field: field,
      language: language,
      chordsOnly: chordsOnly,
      timedOnly: timedOnly,
      durationBucket: durationBucket,
    );
    final comparison = _state.comparison!;
    final filtered = _allVersions.where((version) {
      if (_filters.chordsOnly && !version.hasChords) return false;
      if (_filters.timedOnly && !version.hasTiming) return false;
      if (_filters.durationBucket == 'short' &&
          (version.durationSeconds == null || version.durationSeconds! > 180)) {
        return false;
      }
      return true;
    }).toList();
    _state = VerseUiState(
      homeListMode: _state.homeListMode,
      query: _state.query,
      searchState: _state.searchState,
      searchFilters: _filters,
      comparison: SearchComparisonData(
        reference: comparison.reference,
        suggested: filtered.isEmpty ? null : filtered.first,
        alternatives: filtered,
        selectedVersionId:
            filtered.any(
              (version) => version.id == comparison.selectedVersionId,
            )
            ? comparison.selectedVersionId
            : null,
        discovering: comparison.discovering,
        providerChecks: comparison.providerChecks,
      ),
    );
    notifyListeners();
  }
}
