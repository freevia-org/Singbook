import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/settings/search_catalog_selector.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

// Opt in with --dart-define=CATALOG_SELECTOR_CAPTURE_DIR=<fresh-directory>.
// These synthetic host widget captures need visual inspection; they are not
// Android screenshots or committed goldens. Existing evidence is never replaced.
const _captureOutput = String.fromEnvironment('CATALOG_SELECTOR_CAPTURE_DIR');

// Use registered provider IDs, with names that are deliberately different from
// their IDs so a selection cannot accidentally submit a display label.
const _recordings = ProviderSettingData(
  id: 'lrclib',
  name: 'LRCLIB',
  enabled: true,
);
const _historicalTexts = ProviderSettingData(
  id: 'wikisource',
  name: 'Wikisource',
  enabled: true,
);
const _catalogs = [_recordings, _historicalTexts];
const _historicalReference = SearchReferenceData(
  id: 'wikisource:synthetic-lantern-poem',
  title: 'Lanterns over the garden',
  artist: 'Synthetic author',
  isHistoricalText: true,
);
const _recordingReference = SearchReferenceData(
  id: 'lrclib:synthetic-lantern-song',
  title: 'Lanterns in the hall',
  artist: 'Synthetic band',
  album: 'Synthetic album',
  durationSeconds: 123,
);

Finder get _selector => find.byKey(const ValueKey('search-catalog-selector'));

void main() {
  testWidgets('the search screen has no catalog selector in any mode', (
    tester,
  ) async {
    final controller = _CatalogController(mode: HomeListMode.recent);
    addTearDown(controller.dispose);
    await _pumpHome(tester, controller);
    for (final mode in const ['library', 'online', 'recent']) {
      expect(_selector, findsNothing);
      await tester.tap(find.byKey(ValueKey('home-mode-$mode')));
      await tester.pumpAndSettle();
    }
    expect(_selector, findsNothing);
    expect(controller.catalogSelections, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog selector in settings uses its localized label', (
    tester,
  ) async {
    final controller = _CatalogController();
    addTearDown(controller.dispose);
    await _pumpSelector(tester, controller, locale: const Locale('uk'));
    expect(_selector, findsOneWidget);
    expect(find.text(_l10n(tester).searchSourceLabel), findsOneWidget);
    expect(_selectedId(tester), 'lrclib');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'normal source menu selection submits the registered ID and keeps query',
    (tester) async {
      final controller = _CatalogController(query: 'Lanterns');
      addTearDown(controller.dispose);
      await _pumpSelector(tester, controller);

      await tester.tap(_selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wikisource').last);
      await tester.pumpAndSettle();

      expect(controller.catalogSelections, ['wikisource']);
      expect(controller.state.searchCatalogId, 'wikisource');
      expect(_selectedId(tester), 'wikisource');
      expect(controller.state.query, 'Lanterns');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed catalog preference restores visible choice and normal menu retries',
    (tester) async {
      final controller = _FailingCatalogController();
      addTearDown(controller.dispose);
      await _pumpSelector(tester, controller);
      _expectVisibleCatalog(tester, 'lrclib', 'LRCLIB');

      await tester.tap(_selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wikisource').last);
      await tester.pumpAndSettle();

      expect(controller.catalogSelections, ['wikisource']);
      expect(controller.writeErrors, hasLength(1));
      expect(
        controller.writeErrors.single.message,
        'Synthetic catalog preference write failed',
      );
      expect(controller.durableId, 'lrclib');
      expect(controller.state.searchCatalogId, 'lrclib');
      // Check the actual DropdownButton and the text the user can hit. A
      // corrected state getter alone can leave a stale visible menu choice.
      _expectVisibleCatalog(tester, 'lrclib', 'LRCLIB');
      expect(
        find
            .descendant(of: _selector, matching: find.text('Wikisource'))
            .hitTestable(),
        findsNothing,
      );
      expect(controller.state.query, 'Lanterns');
      expect(tester.takeException(), isNull);

      // Retrying the same choice must work through the real popup. Calling the
      // controller directly would miss a stale control suppressing this path.
      await tester.tap(_selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wikisource').last);
      await tester.pumpAndSettle();

      expect(controller.catalogSelections, ['wikisource', 'wikisource']);
      expect(controller.writeErrors, hasLength(1));
      expect(controller.durableId, 'wikisource');
      expect(controller.state.searchCatalogId, 'wikisource');
      _expectVisibleCatalog(tester, 'wikisource', 'Wikisource');
      expect(controller.state.query, 'Lanterns');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalog control follows external selection and availability fallback',
    (tester) async {
      final controller = _CatalogController(query: 'Lanterns');
      addTearDown(controller.dispose);
      await _pumpSelector(tester, controller);
      expect(_selectedId(tester), 'lrclib');

      // A settings refresh can change the effective selection without a menu tap.
      controller.updateCatalogs(_catalogs, selectedId: 'wikisource');
      await tester.pumpAndSettle();
      expect(_selectedId(tester), 'wikisource');
      expect(tester.takeException(), isNull);

      // The selected catalog disappears and the controller supplies its fallback.
      controller.updateCatalogs([_recordings], selectedId: 'lrclib');
      await tester.pumpAndSettle();
      expect(_selectedId(tester), 'lrclib');
      expect(tester.takeException(), isNull);

      // Nullable selection must clear the old visible value on the same screen.
      controller.updateCatalogs(_catalogs, selectedId: null);
      await tester.pumpAndSettle();
      expect(_selectedId(tester), isNull);
      expect(tester.takeException(), isNull);

      controller.updateCatalogs([_historicalTexts], selectedId: 'wikisource');
      await tester.pumpAndSettle();
      expect(_selectedId(tester), 'wikisource');
      expect(controller.state.query, 'Lanterns');
      expect(controller.catalogSelections, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'no available catalogs hides the control and survives availability changes',
    (tester) async {
      final controller = _CatalogController(
        catalogs: const [],
        selectedId: null,
      );
      addTearDown(controller.dispose);
      await _pumpSelector(tester, controller);
      expect(_selector, findsNothing);
      expect(find.text(_l10n(tester).searchSourceLabel), findsNothing);

      controller.updateCatalogs(_catalogs, selectedId: 'wikisource');
      await tester.pumpAndSettle();
      expect(_selectedId(tester), 'wikisource');

      controller.updateCatalogs(const [], selectedId: null);
      await tester.pumpAndSettle();
      expect(_selector, findsNothing);
      expect(controller.catalogSelections, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in const [Locale('en'), Locale('bg'), Locale('uk')]) {
    testWidgets('historical catalog result describes text licensing in $locale', (
      tester,
    ) async {
      final controller = _CatalogController(
        query: 'Lanterns',
        selectedId: 'wikisource',
        references: const [_historicalReference, _recordingReference],
      );
      addTearDown(controller.dispose);
      await _pumpHome(tester, controller, locale: locale);
      final l10n = _l10n(tester);
      final historicalRow = _resultRow(_historicalReference.title);
      final recordingRow = _resultRow(_recordingReference.title);

      expect(
        find.descendant(
          of: historicalRow,
          matching: find.text(l10n.providerDescHistoricalTextPerWorkLicense),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: recordingRow,
          matching: find.text(l10n.providerDescHistoricalTextPerWorkLicense),
        ),
        findsNothing,
      );
      expect(_recordingReference.isHistoricalText, isFalse);
      // Text references must not acquire recording, timing or invented duration
      // claims from the recording catalog alongside them.
      for (final claim in [
        l10n.searchRecordingMatch,
        l10n.searchMatchExact,
        l10n.searchSelectedRecording,
        l10n.searchTimingAvailable,
        l10n.providerCapabilityTiming,
      ]) {
        expect(
          find.descendant(of: historicalRow, matching: find.text(claim)),
          findsNothing,
        );
      }
      expect(
        find.descendant(
          of: historicalRow,
          matching: find.textContaining('2:03'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: recordingRow,
          matching: find.textContaining('2:03'),
        ),
        findsOneWidget,
      );
      await tester.tap(historicalRow);
      await tester.pumpAndSettle();
      expect(controller.openedReferences, [_historicalReference]);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scenario in const [
    ('narrow_portrait', Size(320, 640), Locale('en'), 1.0, Brightness.light),
    ('compact_landscape', Size(640, 320), Locale('bg'), 1.5, Brightness.light),
    ('large_text', Size(320, 640), Locale('uk'), 2.0, Brightness.dark),
    ('rtl', Size(360, 780), Locale('ar'), 1.6, Brightness.light),
  ]) {
    testWidgets('catalog selector stays usable in ${scenario.$1}', (
      tester,
    ) async {
      await tester.runAsync(_loadFixtureFonts);
      final controller = _CatalogController(
        query: 'Lanterns',
        selectedId: 'wikisource',
        references: const [_historicalReference],
      );
      addTearDown(controller.dispose);
      final boundaryKey = GlobalKey();
      await _pumpSelector(
        tester,
        controller,
        size: scenario.$2,
        locale: scenario.$3,
        textScale: scenario.$4,
        brightness: scenario.$5,
        boundaryKey: boundaryKey,
      );

      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(_selector)),
        scenario.$3.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
      );
      await tester.ensureVisible(_selector);
      await tester.pumpAndSettle();
      final button = find.descendant(
        of: _selector,
        matching: find.byType(DropdownButton<String>),
      );
      final target = tester.getRect(button);
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
      expect(target.left, greaterThanOrEqualTo(0));
      expect(target.right, lessThanOrEqualTo(scenario.$2.width));
      expect(target.top, greaterThanOrEqualTo(0));
      expect(target.bottom, lessThanOrEqualTo(scenario.$2.height));
      expect(button.hitTestable(), findsOneWidget);
      if (_captureOutput.isNotEmpty) {
        await _capture(
          tester,
          boundaryKey,
          '${scenario.$1}-closed',
          scenario.$3,
          scenario.$4,
        );
      }

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final option = find.text('LRCLIB').last;
      expect(option.hitTestable(), findsOneWidget);
      if (_captureOutput.isNotEmpty) {
        await _capture(
          tester,
          boundaryKey,
          '${scenario.$1}-menu',
          scenario.$3,
          scenario.$4,
        );
      }
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(controller.catalogSelections, ['lrclib']);
      expect(_selectedId(tester), 'lrclib');
      expect(controller.state.query, 'Lanterns');
      expect(tester.takeException(), isNull);
    });
  }
}

Finder _resultRow(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ListTile));

String? _selectedId(WidgetTester tester) => tester
    .widget<DropdownButton<String>>(
      find.descendant(
        of: _selector,
        matching: find.byType(DropdownButton<String>),
      ),
    )
    .value;

void _expectVisibleCatalog(WidgetTester tester, String id, String name) {
  expect(_selectedId(tester), id);
  final button = find.descendant(
    of: _selector,
    matching: find.byType(DropdownButton<String>),
  );
  expect(
    find.descendant(of: button, matching: find.text(name)).hitTestable(),
    findsOneWidget,
  );
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

Future<void> _pumpHome(
  WidgetTester tester,
  _CatalogController controller, {
  Size size = const Size(360, 780),
  Locale locale = const Locale('en'),
}) => _pumpHost(
  tester,
  controller,
  (state) => VerseHomeScreen(controller: controller, state: state),
  size: size,
  locale: locale,
);

/// The selector as Settings > Sources hosts it: padded inside a scroll view.
Future<void> _pumpSelector(
  WidgetTester tester,
  _CatalogController controller, {
  Size size = const Size(360, 780),
  Locale locale = const Locale('en'),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  GlobalKey? boundaryKey,
}) => _pumpHost(
  tester,
  controller,
  (state) => ListView(
    padding: const EdgeInsets.all(16),
    children: [SearchCatalogSelector(controller: controller, state: state)],
  ),
  size: size,
  locale: locale,
  textScale: textScale,
  brightness: brightness,
  boundaryKey: boundaryKey,
);

Future<void> _pumpHost(
  WidgetTester tester,
  _CatalogController controller,
  Widget Function(VerseUiState state) body, {
  Size size = const Size(360, 780),
  Locale locale = const Locale('en'),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  GlobalKey? boundaryKey,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final theme = verseTheme(
    brightness: brightness,
    palette: 'navy',
    fontFamily: 'CatalogFixtureSans',
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundaryKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: singbookLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(
            fontFamily: 'CatalogFixtureSans',
            fontFamilyFallback: const ['CatalogFixtureArabic'],
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Scaffold(body: body(controller.state)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _loadFixtureFonts() async {
  await (FontLoader('CatalogFixtureSans')
        ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf')))
      .load();
  await (FontLoader('CatalogFixtureArabic')
        ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf')))
      .load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String name,
  Locale locale,
  double textScale,
) async {
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(data, isNotNull);
      final file = File('$_captureOutput/$name.png');
      final sidecar = File('$_captureOutput/$name.json');
      expect(file.existsSync(), isFalse, reason: 'never overwrite evidence');
      expect(sidecar.existsSync(), isFalse, reason: 'never overwrite sidecars');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
      await sidecar.writeAsString(
        jsonEncode({
          'screen': 'settings-catalog-selector-$name',
          'width': image.width,
          'height': image.height,
          'locale': locale.toLanguageTag(),
          'textScale': textScale,
          'evidenceKind': 'host_widget_screenshot',
          'syntheticContentOnly': true,
          'nativeAndroidVerified': false,
        }),
        flush: true,
      );
    } finally {
      image.dispose();
    }
  });
}

class _CatalogController extends VerseUiController {
  _CatalogController({
    this.mode = HomeListMode.online,
    this.query = '',
    this.catalogs = _catalogs,
    this.selectedId = 'lrclib',
    this.references = const [],
  });

  HomeListMode mode;
  String query;
  List<ProviderSettingData> catalogs;
  String? selectedId;
  final List<SearchReferenceData> references;
  final catalogSelections = <String>[];
  final openedReferences = <SearchReferenceData>[];

  @override
  VerseUiState get state => VerseUiState(
    homeListMode: mode,
    query: query,
    searchCatalogs: catalogs,
    searchCatalogId: selectedId,
    autocomplete: references,
    searchState: LoadState.loaded,
  );

  void updateCatalogs(
    List<ProviderSettingData> value, {
    required String? selectedId,
  }) {
    catalogs = value;
    this.selectedId = selectedId;
    notifyListeners();
  }

  @override
  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  @override
  void setHomeListMode(HomeListMode value) {
    mode = value;
    notifyListeners();
  }

  @override
  Future<void> setSearchCatalog(String id) async {
    catalogSelections.add(id);
    selectedId = id;
    notifyListeners();
  }

  @override
  Future<void> selectReference(SearchReferenceData reference) async {
    openedReferences.add(reference);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// This harness models the UI contract of a preference write: retain the durable
// choice until asynchronous persistence succeeds, then allow a successful retry.
// Real repository write failures and overlapping writes are adapter tests' job.
class _FailingCatalogController extends _CatalogController {
  _FailingCatalogController() : super(query: 'Lanterns');

  String durableId = 'lrclib';
  final writeErrors = <StateError>[];

  @override
  Future<void> setSearchCatalog(String id) async {
    catalogSelections.add(id);
    final attempt = catalogSelections.length;
    notifyListeners();
    // A quick storage failure can complete before a frame renders. The actual
    // visible choice must stay durable even when those updates coalesce.
    await Future<void>.delayed(Duration.zero);
    if (attempt == 1) {
      writeErrors.add(StateError('Synthetic catalog preference write failed'));
      notifyListeners();
      return;
    }
    durableId = id;
    selectedId = id;
    notifyListeners();
  }
}
