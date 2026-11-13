import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/source_version_browser.dart';
import 'package:singbook/ui/home/source_version_widgets.dart';
import 'package:singbook/ui/library_actions.dart';
import 'package:singbook/ui/song_search.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

import 'support/fake_controller.dart';

const _lines = [
  LyricLineData(id: 's', section: 'Verse 1', isBlank: true),
  LyricLineData(
    id: 'a',
    text: 'An opening line',
    chords: [LyricChord(graphemeOffset: 3, symbol: 'Am')],
  ),
  LyricLineData(id: 'b', text: 'A second line'),
];

SourceVersionData _version(
  String id, {
  bool usable = true,
  List<LyricLineData> lines = _lines,
}) => SourceVersionData(
  id: id,
  providerId: id,
  providerName: 'Source $id',
  title: 'An original test song',
  artist: 'The Testers',
  hasLyrics: usable,
  isUsableVersion: usable,
  canSave: usable,
  bodyLines: lines,
);

class _Comparison extends VerseUiController {
  _Comparison(this.versions, this.selected);

  List<SourceVersionData> versions;
  String selected;
  bool showChords = true;
  final saved = <String>[];

  void refresh() => notifyListeners();

  @override
  VerseUiState get state => VerseUiState(
    homeListMode: HomeListMode.online,
    query: 'Test song',
    showChords: showChords,
    comparison: SearchComparisonData(
      reference: const SearchReferenceData(
        id: 'song',
        title: 'Test song',
        artist: 'The Testers',
      ),
      suggested: null,
      alternatives: versions,
      selectedVersionId: selected,
    ),
  );

  @override
  void selectVersion(String versionId) {
    selected = versionId;
    notifyListeners();
  }

  @override
  Future<void> saveSelectedVersion() async => saved.add(selected);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _host(Widget home) => MaterialApp(
  localizationsDelegates: singbookLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: home),
);

FilledButton _saveButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.descendant(
    of: find.byKey(const ValueKey('version-selection-footer')),
    matching: find.bySubtype<FilledButton>(),
  ),
);

void main() {
  test('songMatchesQuery ignores case and diacritics in every field', () {
    const song = SongCardData(
      id: 'a',
      title: 'Éclair',
      artist: 'Zoë',
      album: 'Café',
    );
    expect(songMatchesQuery(song, 'eclair'), isTrue);
    expect(songMatchesQuery(song, 'zoe'), isTrue);
    expect(songMatchesQuery(song, 'cafe'), isTrue);
    expect(songMatchesQuery(song, ''), isTrue);
    expect(songMatchesQuery(song, 'tarte'), isFalse);
  });

  testWidgets('the setlist song picker finds an accented title', (
    tester,
  ) async {
    final controller = FakeUiController(
      (_) => const VerseUiState(
        songs: [
          SongCardData(id: 'song-1', title: 'Éclair au café'),
          SongCardData(id: 'song-2', title: 'Second Song'),
        ],
      ),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () =>
                showAddSongsToSetlist(context, controller, 'setlist-1'),
            child: const Text('Open picker'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ECLAIR  ');
    await tester.pump();

    expect(find.text('Éclair au café'), findsOneWidget);
    expect(find.text('Second Song'), findsNothing);
  });

  testWidgets('Save is disabled on a version it cannot act on', (tester) async {
    final controller = _Comparison([
      _version('a'),
      _version('b', usable: false),
    ], 'a');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(SourceVersionBrowser(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(_saveButton(tester).onPressed, isNotNull);

    // An explicitly selected version stays visible when it cannot be saved.
    controller.selectVersion('b');
    await tester.pumpAndSettle();

    expect(_saveButton(tester).onPressed, isNull);
    await tester.tap(
      find.byKey(const ValueKey('version-selection-footer')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(controller.saved, isEmpty);

    controller.selectVersion('a');
    await tester.pumpAndSettle();
    expect(_saveButton(tester).onPressed, isNotNull);
    await tester.tap(find.bySubtype<FilledButton>());
    await tester.pumpAndSettle();
    expect(controller.saved, ['a']);
  });

  testWidgets('preview lines are reused until their inputs change', (
    tester,
  ) async {
    final controller = _Comparison([_version('a')], 'a');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(SourceVersionBrowser(controller: controller)),
    );
    await tester.pumpAndSettle();
    Widget line() =>
        tester.widget(find.byKey(const ValueKey('preview-line-a')));
    final first = line();
    expect(find.byType(ChordLyricsLine), findsWidgets);

    // A provider update that leaves this version's lines alone.
    controller.refresh();
    await tester.pump();
    expect(identical(line(), first), isTrue);

    // A display setting rebuilds them.
    controller.showChords = false;
    controller.refresh();
    await tester.pump();
    expect(identical(line(), first), isFalse);
    expect(
      tester
          .widget<ChordLyricsLine>(
            find.descendant(
              of: find.byKey(const ValueKey('preview-line-a')),
              matching: find.byType(ChordLyricsLine),
            ),
          )
          .showChords,
      isFalse,
    );

    // New content for the same version replaces them.
    controller.versions = [
      _version(
        'a',
        lines: const [LyricLineData(id: 'a', text: 'A rewritten line')],
      ),
    ];
    controller.refresh();
    await tester.pump();
    expect(find.text('A rewritten line'), findsOneWidget);
    expect(find.text('An opening line'), findsNothing);
  });

  testWidgets('shared comparison helpers keep each caller\'s wording', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(
      contributionRoleLabel(l10n, 'lyrics', other: 'x'),
      l10n.providerCapabilityLyrics,
    );
    expect(
      contributionRoleLabel(l10n, 'chords', other: 'x'),
      l10n.providerCapabilityChords,
    );
    expect(
      contributionRoleLabel(l10n, 'timing', other: 'x'),
      l10n.playerTimedLyrics,
    );
    expect(contributionRoleLabel(l10n, 'metadata', other: 'x'), 'x');

    final same = _version('a');
    expect(
      countDistinctVersions([
        same,
        same,
        _version('b', usable: false),
      ], (version) => version.canSave),
      1,
    );
  });
}
