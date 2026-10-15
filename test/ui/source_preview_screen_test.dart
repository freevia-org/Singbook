import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/home/source_preview_screen.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _lines = [
  LyricLineData(id: 's', section: 'Verse 1', isBlank: true),
  LyricLineData(
    id: 'a',
    text: 'An opening line',
    chords: [LyricChord(graphemeOffset: 3, symbol: 'Am')],
  ),
  LyricLineData(id: 'b', text: 'A second line'),
  LyricLineData(id: 'c', text: 'A third line'),
  LyricLineData(id: 'd', text: 'A fourth line beyond the summary'),
];

SourceVersionData _version(String id, {bool ready = true}) => SourceVersionData(
  id: id,
  providerId: id,
  providerName: id == 'a' ? 'Lyrics A' : 'Lyrics B',
  title: 'An original test song',
  artist: 'The Testers',
  hasLyrics: true,
  hasChords: true,
  isUsableVersion: true,
  isChecking: !ready,
  canSave: ready,
  bodyLines: _lines,
  bodyPreview: _lines.sublist(1, 4),
);

class _Controller extends VerseUiController {
  List<SourceVersionData> versions = [
    _version('a'),
    _version('b', ready: false),
  ];
  String selected = 'a';
  int saves = 0;
  bool opened = false;
  @override
  VerseUiState get state => VerseUiState(
    route: opened ? VerseRoute.reader : VerseRoute.main,
    homeListMode: HomeListMode.online,
    query: 'Test song',
    comparison: SearchComparisonData(
      reference: const SearchReferenceData(
        id: 'song',
        title: 'Test song',
        artist: 'The Testers',
      ),
      suggested: null,
      alternatives: versions,
      selectedVersionId: selected,
      discovering: true,
    ),
  );
  @override
  void selectVersion(String versionId) {
    selected = versionId;
    notifyListeners();
  }

  @override
  Future<void> saveSelectedVersion() async {
    saves++;
    opened = true;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(
  _Controller controller, {
  Widget? home,
  String language = 'en',
  double scale = 1,
}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home ?? SourcePreviewScreen(controller: controller),
);

void main() {
  testWidgets('leading setup notes remain expandable while lyrics come first', (
    tester,
  ) async {
    final controller = _Controller();
    controller.versions = [
      SourceVersionData(
        id: 'a',
        providerId: 'a',
        providerName: 'Lyrics A',
        title: 'Test song',
        artist: 'The Testers',
        hasLyrics: true,
        isUsableVersion: true,
        canSave: true,
        bodyLines: const [
          LyricLineData(
            id: 'setup',
            text: 'A9sus4 x05435',
            isArrangementNote: true,
          ),
          ..._lines,
        ],
        bodyPreview: _lines.sublist(1, 4),
      ),
    ];
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    expect(find.textContaining('opening line'), findsOneWidget);
    expect(find.textContaining('A9sus4 x05435'), findsNothing);
    await tester.ensureVisible(find.text('Arrangement notes'));
    await tester.tap(find.text('Arrangement notes'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('A9sus4 x05435'), findsOneWidget);
    expect(controller.saves, 0);
  });

  testWidgets(
    'full preview contains sections, positioned chords and lyrics beyond three lines',
    (tester) async {
      final controller = _Controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      expect(find.text('Verse 1'), findsOneWidget);
      expect(find.text('Am'), findsOneWidget);
      expect(
        find.textContaining('A fourth line beyond the summary'),
        findsOneWidget,
      );
      expect(controller.saves, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'next previews a pending version without saving; previous restores choice',
    (tester) async {
      final controller = _Controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      await tester.tap(find.byKey(const ValueKey('preview-next')));
      await tester.pump();
      expect(controller.selected, 'b');
      expect(find.text('Lyrics B'), findsOneWidget);
      expect(find.text('Checking this version…'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('preview-save-open')),
            )
            .onPressed,
        isNull,
      );
      expect(controller.saves, 0);
      await tester.tap(find.byKey(const ValueKey('preview-previous')));
      await tester.pump();
      expect(controller.selected, 'a');
      expect(controller.saves, 0);
    },
  );

  testWidgets('contributions show only the roles supplied by each source', (
    tester,
  ) async {
    final controller = _Controller();
    controller.versions = [
      const SourceVersionData(
        id: 'combined',
        providerId: 'combined',
        providerName: '',
        title: 'Test song',
        artist: 'The Testers',
        sourceCount: 2,
        hasLyrics: true,
        canSave: true,
        bodyLines: _lines,
        contributions: [
          SourceContributionData(
            providerName: 'Chart source',
            roles: ['lyrics', 'chords'],
          ),
          SourceContributionData(
            providerName: 'Catalog source',
            roles: ['metadata'],
          ),
        ],
      ),
    ];
    controller.selected = 'combined';
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    expect(find.text('Sources used'), findsOneWidget);
    expect(find.text('Chart source · Lyrics, Chords'), findsOneWidget);
    expect(find.text('Catalog source · Song details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full preview opens from comparison and closes without a save', (
    tester,
  ) async {
    final controller = _Controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        controller,
        home: Scaffold(
          body: VerseHomeScreen(
            controller: controller,
            state: controller.state,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-full-preview')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SourcePreviewScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(SourcePreviewScreen), findsNothing);
    expect(controller.saves, 0);
  });

  for (final configuration in [
    (const Size(360, 640), 'en', 2.0),
    (const Size(640, 360), 'en', 2.0),
    (const Size(800, 1000), 'uk', 1.0),
    (const Size(640, 360), 'ar', 2.0),
  ]) {
    testWidgets(
      'preview fits ${configuration.$1} ${configuration.$2} ${configuration.$3} text',
      (tester) async {
        tester.view.physicalSize = configuration.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _Controller();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _app(controller, language: configuration.$2, scale: configuration.$3),
        );
        expect(find.byKey(const ValueKey('preview-save-open')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
