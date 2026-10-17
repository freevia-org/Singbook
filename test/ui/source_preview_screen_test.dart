import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/home/source_preview_screen.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

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
  SourceVersionData? suggested;
  String selected = 'a';
  int saves = 0;
  String? savedVersionId;
  bool opened = false;
  List<SearchProviderCheckData> providerChecks = const [];
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
      suggested: suggested,
      alternatives: versions,
      selectedVersionId: selected,
      discovering: false,
      providerChecks: providerChecks,
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
    savedVersionId = selected;
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
  testWidgets('a blocked YouTube source has no consent or browser action', (
    tester,
  ) async {
    const capture = bool.fromEnvironment('CAPTURE_YOUTUBE_REMOVAL');
    if (capture) {
      for (final family in ['Roboto', 'sans-serif']) {
        await (FontLoader(family)
              ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf')))
            .load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
    final controller = _Controller()
      ..providerChecks = const [
        SearchProviderCheckData(
          id: 'youtubemusic',
          name: 'YouTube Music',
          state: 'failed',
        ),
      ];
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    expect(find.byType(SourcePreviewScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('version-source-menu')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('review-youtube-music-consent')),
      findsNothing,
    );
    expect(find.text('Review Google consent'), findsNothing);
    expect(find.textContaining('cookie choice'), findsNothing);
    expect(controller.selected, 'a');
    expect(controller.saves, 0);
    expect(find.byType(SourcePreviewScreen), findsOneWidget);
    if (capture) {
      await expectLater(
        find.byType(Overlay).first,
        matchesGoldenFile('../../artifacts/youtube-source-options.png'),
      );
    }
    expect(
      tester
          .widget<DraggableScrollableSheet>(
            find.byType(DraggableScrollableSheet),
          )
          .initialChildSize,
      lessThan(.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('match details do not repeat the match label', (tester) async {
    final controller = _Controller()
      ..versions = [
        const SourceVersionData(
          id: 'same-song',
          providerId: 'catalog',
          providerName: 'Catalog',
          title: 'Test song',
          artist: 'The Testers',
          matchSummary: 'same_song',
          hasLyrics: true,
          isUsableVersion: true,
          canSave: true,
          bodyLines: [LyricLineData(id: 'line', text: 'Line')],
        ),
      ]
      ..selected = 'same-song';
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SourcePreviewScreen)),
    );
    expect(find.text(l10n.searchMatchSameSong), findsOneWidget);
    expect(find.text(l10n.searchVersionDetails), findsOneWidget);

    await tester.tap(find.text(l10n.searchVersionDetails));
    await tester.pumpAndSettle();
    expect(find.text(l10n.searchMatchSameSong), findsOneWidget);
    expect(find.text(l10n.searchVersionDetails), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tabs switch the selected source without saving', (tester) async {
    final controller = _Controller();
    controller.selected = 'b';
    controller.suggested = const SourceVersionData(
      id: 'combined',
      providerId: 'combined',
      providerName: 'Lyrics A',
      title: 'Test song',
      artist: 'The Testers',
      sourceCount: 1,
      underlyingSourceId: 'a',
      hasLyrics: true,
      isUsableVersion: true,
      canSave: true,
      bodyLines: [
        LyricLineData(id: 'facade-section', section: 'Verse 1', isBlank: true),
        LyricLineData(id: 'facade-line', text: 'An opening line'),
      ],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.byKey(const ValueKey('version-row-a')));
    await tester.pumpAndSettle();
    expect(controller.selected, 'a');
    expect(find.text('Lyrics A'), findsWidgets);
    expect(
      find.textContaining('A fourth line beyond the summary'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('version-row-b')));
    await tester.pumpAndSettle();
    expect(controller.selected, 'b');
    expect(controller.saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching versions preserves the later repeated chorus', (
    tester,
  ) async {
    final controller = _Controller();
    final lines = [
      for (var chorus = 0; chorus < 3; chorus++) ...[
        LyricLineData(id: 'chorus-$chorus', section: 'Chorus', isBlank: true),
        for (var line = 0; line < 12; line++)
          LyricLineData(
            id: 'chorus-$chorus-line-$line',
            text: 'Repeated chorus lyric $line',
          ),
      ],
    ];
    controller.versions = [
      for (final id in ['a', 'b'])
        SourceVersionData(
          id: id,
          providerId: id,
          providerName: id,
          title: 'Repeated choruses',
          artist: 'Test Artist',
          hasLyrics: true,
          isUsableVersion: true,
          canSave: true,
          bodyLines: lines,
          bodyPreview: [lines[1]],
        ),
    ];
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    final initialPage = find.byKey(const ValueKey('a'));
    final initialBody = find.descendant(
      of: initialPage,
      matching: find.byKey(const ValueKey('full-preview-body')),
    );
    final initialScrollable = find
        .descendant(of: initialBody, matching: find.byType(Scrollable))
        .first;
    final later = find.byKey(const ValueKey('preview-line-chorus-2'));
    final initialLater = find.descendant(of: initialPage, matching: later);
    await tester.scrollUntilVisible(
      initialLater,
      200,
      scrollable: initialScrollable,
    );
    await Scrollable.ensureVisible(tester.element(initialLater), alignment: 0);
    await tester.pump();
    final initialPosition = tester
        .state<ScrollableState>(initialScrollable)
        .position;
    expect(initialPosition.pixels, greaterThan(1000));
    await tester.tap(find.byKey(const ValueKey('version-row-b')));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(controller.selected, 'b');
    final activePage = find.byKey(const ValueKey('b'));
    final activeBody = find.descendant(
      of: activePage,
      matching: find.byKey(const ValueKey('full-preview-body')),
    );
    final activeScrollable = find
        .descendant(of: activeBody, matching: find.byType(Scrollable))
        .first;
    final activeLater = find.descendant(of: activePage, matching: later);
    expect(
      tester.state<ScrollableState>(activeScrollable).position.pixels,
      greaterThan(1000),
    );
    expect(activeLater.hitTestable(), findsOneWidget);
    expect(controller.saves, 0);
  });

  testWidgets(
    'single-source alias preview matches the version that will save',
    (tester) async {
      final controller = _Controller()
        ..selected = 'combined'
        ..versions = [
          SourceVersionData(
            id: 'a',
            providerId: 'raw',
            providerName: 'Raw source',
            title: 'Raw recording',
            artist: 'The Testers',
            durationSeconds: 180,
            hasLyrics: true,
            isUsableVersion: true,
            canSave: true,
            bodyLines: const [
              LyricLineData(id: 'raw-body', text: 'Raw arrangement'),
            ],
          ),
          _version('b'),
        ]
        ..suggested = const SourceVersionData(
          id: 'combined',
          providerId: 'combined',
          providerName: 'Combined source',
          title: 'Combined recording',
          artist: 'The Testers',
          durationSeconds: 247,
          sourceCount: 1,
          underlyingSourceId: 'a',
          hasLyrics: true,
          isUsableVersion: true,
          canSave: true,
          bodyLines: [
            LyricLineData(id: 'combined-body', text: 'Combined arrangement'),
          ],
        );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      expect(controller.selected, 'combined');
      expect(find.text('Combined arrangement').hitTestable(), findsOneWidget);
      expect(find.text('Raw arrangement').hitTestable(), findsNothing);
      await tester.tap(find.byKey(const ValueKey('preview-save-open')));
      await tester.pumpAndSettle();
      expect(controller.savedVersionId, 'combined');
      expect(controller.saves, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('swiping changes selected identity without saving', (
    tester,
  ) async {
    final controller = _Controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.drag(
      find.byKey(const ValueKey('version-preview-pages')),
      Offset(
        -tester
                .getSize(find.byKey(const ValueKey('version-preview-pages')))
                .width *
            .8,
        0,
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.selected, 'b');
    expect(find.text('Lyrics B'), findsWidgets);
    expect(controller.saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a swipe can interrupt tab animation and later swipes still select',
    (tester) async {
      final controller = _Controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller));
      final pages = find.byKey(const ValueKey('version-preview-pages'));
      final distance = tester.getSize(pages).width * .8;
      await tester.tap(find.byKey(const ValueKey('version-row-b')));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.drag(pages, Offset(distance, 0));
      await tester.pumpAndSettle();
      expect(controller.selected, 'a');
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('version-row-a')))
            .selected,
        isTrue,
      );
      await tester.drag(pages, Offset(-distance, 0));
      await tester.pumpAndSettle();
      expect(controller.selected, 'b');
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('version-row-b')))
            .selected,
        isTrue,
      );
      expect(controller.saves, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a vanished selected source cannot save another version', (
    tester,
  ) async {
    final controller = _Controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    controller.versions = [_version('b')];
    controller.notifyListeners();
    await tester.pumpAndSettle();
    expect(controller.selected, 'a');
    expect(
      find.text('This version can’t be used. Choose another version.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('preview-save-open')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('preview-save-open')));
    expect(controller.saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('section menu jumps to a section in the full preview', (
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
        bodyLines: [
          for (var i = 0; i < 14; i++)
            LyricLineData(id: 'before-$i', text: 'Earlier lyric $i'),
          const LyricLineData(
            id: 'target-section',
            section: 'Chorus',
            isBlank: true,
          ),
          const LyricLineData(id: 'target-lyric', text: 'Jumped to chorus'),
        ],
      ),
    ];
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.byKey(const ValueKey('preview-sections')));
    await tester.pumpAndSettle();
    expect(find.text('Chorus'), findsWidgets);
    await tester.tap(find.text('Chorus').last);
    await tester.pumpAndSettle();
    expect(find.text('Jumped to chorus'), findsOneWidget);
    expect(controller.saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('instrumental chord gaps stay compact in the full preview', (
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
          LyricLineData(id: 'start', text: 'Opening lyric'),
          LyricLineData(id: 'before-gap', isBlank: true),
          LyricLineData(
            id: 'instrumental',
            isBlank: true,
            chords: [LyricChord(graphemeOffset: 0, symbol: 'Am')],
          ),
          LyricLineData(id: 'after-gap', isBlank: true),
          LyricLineData(id: 'end', text: 'Closing lyric'),
        ],
      ),
    ];
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('preview-line-before-gap')))
          .height,
      lessThan(10),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('preview-line-after-gap')))
          .height,
      lessThan(10),
    );
    expect(find.text('Opening lyric'), findsOneWidget);
    expect(find.text('Closing lyric'), findsOneWidget);
    expect(controller.saves, 0);
  });

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
      // Chords are painted above the uninterrupted text. Preserve both the
      // symbol and its exact lyric anchor when wiring the preview renderer.
      final chordLine = tester.widget<ChordLyricsLine>(
        find.descendant(
          of: find.byKey(const ValueKey('preview-line-a')),
          matching: find.byType(ChordLyricsLine),
        ),
      );
      expect(chordLine.text, 'An opening line');
      expect(chordLine.showChords, isTrue);
      expect(
        chordLine.chords.map((chord) => (chord.symbol, chord.graphemeOffset)),
        [('Am', 3)],
      );
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
      await tester.tap(find.byKey(const ValueKey('version-row-b')));
      await tester.pumpAndSettle();
      expect(controller.selected, 'b');
      expect(find.text('Lyrics B'), findsWidgets);
      expect(find.text('Checking this version…'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('preview-save-open')),
            )
            .onPressed,
        isNotNull,
      );
      expect(controller.saves, 0);
      await tester.tap(find.byKey(const ValueKey('version-row-a')));
      await tester.pumpAndSettle();
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
    await tester.tap(find.byKey(const ValueKey('version-source-menu')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        AppLocalizations.of(
          tester.element(find.byType(VerseHomeScreen)),
        ).searchFullPreview,
      ),
    );
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
    (const Size(804, 360), 'ar', 2.0),
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
