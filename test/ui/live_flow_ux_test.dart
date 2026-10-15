import 'package:flutter/material.dart';
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
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_off), findsNWidgets(2));

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
      expect(find.text('First source preview'), findsNothing);
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
      providerId: 'catalog',
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
    expect(suggestedRow, findsOneWidget);
    expect(alternativeRow, findsOneWidget);
    expect(find.byKey(const ValueKey('version-row-raw-source')), findsNothing);
    expect(find.text(l10n.searchSourceVersionsCount(3)), findsOneWidget);
    expect(
      find.descendant(
        of: suggestedRow,
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsOneWidget,
    );
    expect(find.text('Raw selected preview'), findsOneWidget);
    final orderBefore = [
      tester.getTopLeft(suggestedRow).dy,
      tester.getTopLeft(alternativeRow).dy,
    ];

    await tester.tap(alternativeRow);
    await tester.pumpAndSettle();
    expect(controller.state.comparison!.selectedVersionId, 'alternative');
    expect(find.text('Archive preview'), findsOneWidget);
    expect(find.text(l10n.searchSourceVersionsCount(3)), findsOneWidget);
    expect([
      tester.getTopLeft(suggestedRow).dy,
      tester.getTopLeft(alternativeRow).dy,
    ], orderBefore);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
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
      expect(find.text(l10n.playerLyricsOnly), findsOneWidget);
      expect(find.text(l10n.playerEstimatedDuration('1:30')), findsOneWidget);
      expect(find.text(l10n.playerEstimatedPace), findsOneWidget);
      expect(find.text(l10n.playerStartScroll), findsOneWidget);
      expect(find.byKey(const ValueKey('scroll-speed')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('start-lyric-scroll')));
      await tester.pump();
      expect(controller.autoscrollEnabled, isTrue);
      expect(controller.estimatedTimingRequested, isTrue);
      expect(controller.playbackStarted, isTrue);

      await tester.tap(find.byKey(const ValueKey('scroll-speed')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.5×').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(controller.selectedSpeed, 1.5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('large text keeps landscape section transport controls usable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(520, 390);
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

    await _pumpPlayer(tester, controller, scale: 1.5);
    final l10n = AppLocalizations.of(tester.element(find.byType(PlayerScreen)));
    final start = find.byKey(const ValueKey('start-lyric-scroll'));
    final previous = find.byTooltip(l10n.playerPreviousSection);
    final next = find.byTooltip(l10n.playerNextSection);
    final speed = find.byKey(const ValueKey('scroll-speed'));
    expect(previous, findsOneWidget);
    expect(next, findsOneWidget);
    expect(speed, findsOneWidget);
    expect(start, findsOneWidget);
    for (final control in [previous, start, speed, next]) {
      final rect = tester.getRect(control);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(520));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(390));
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
          'player=$playerRect controls=$controlsRect; '
          '${layoutError is FlutterError ? layoutError.toStringDeep() : layoutError}',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

List<String> _rowOrder(WidgetTester tester) {
  final rows = ['suggested', 'second', 'third'];
  final tops = {
    for (final id in rows)
      id: tester.getTopLeft(find.byKey(ValueKey('version-row-$id'))).dy,
  };
  return rows..sort((left, right) => tops[left]!.compareTo(tops[right]!));
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

Future<void> _pumpHome(
  WidgetTester tester,
  _LiveFlowController controller, {
  double scale = 1,
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
          body: VerseHomeScreen(
            controller: controller,
            state: controller.state,
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

class _LiveFlowController extends VerseUiController {
  _LiveFlowController(this._state);
  VerseUiState _state;
  bool autoscrollEnabled = false;
  bool estimatedTimingRequested = false;
  bool playbackStarted = false;
  double? selectedSpeed;

  @override
  VerseUiState get state => _state;

  @override
  void selectVersion(String versionId) {
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
  }

  @override
  Future<void> playPause() async {
    playbackStarted = true;
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    selectedSpeed = speed;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
