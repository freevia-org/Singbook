import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

SongCardData _song(String id, String title) =>
    SongCardData(id: id, title: title, artist: 'Artist');

SetlistCardData _setlist(String id, String title) => SetlistCardData(
  id: id,
  title: title,
  songTitles: const ['One', 'Two', 'Three'],
  songIds: const ['1', '2', '3'],
);

VerseUiState _settings({
  String timingMode = 'estimated',
  bool autoscroll = true,
  String palette = 'navy',
  String fontFamily = 'system',
  String? languageCode,
}) => VerseUiState(
  activeTab: VerseTab.settings,
  timingMode: timingMode,
  autoscroll: autoscroll,
  palette: palette,
  fontFamily: fontFamily,
  languageCode: languageCode,
);

class _LibraryFilterController extends FakeUiController {
  _LibraryFilterController()
    : super(
        (controller) => VerseUiState(
          activeTab: VerseTab.home,
          homeListMode: HomeListMode.library,
          query: (controller as _LibraryFilterController).query,
          songs: [_song('1', 'Éclair'), _song('2', 'Zebra')],
        ),
      );
  String query = '';
  @override
  void setQuery(String value) {
    query = value;
    refresh();
  }
}

void main() {
  group('Songs list', () {
    testWidgets('is ordered and indexed by the alphabet, not code units', (
      tester,
    ) async {
      final titles = [
        'Яблуко',
        'Їжак',
        'Гора',
        'Диня',
        'Ехо',
        'Єнот',
        'Ґанок',
        'Іній',
      ];
      final c = FakeUiController(
        (_) => VerseUiState(
          activeTab: VerseTab.songs,
          homeListMode: HomeListMode.library,
          songs: [for (final (i, t) in titles.indexed) _song('$i', t)],
        ),
      );
      addTearDown(c.dispose);
      await pumpShell(
        tester,
        c,
        locale: const Locale('uk'),
        size: const Size(360, 1600),
      );

      double top(String title) => tester.getTopLeft(find.text(title)).dy;
      final ordered = [...titles]..sort((a, b) => top(a).compareTo(top(b)));
      expect(ordered, [
        'Гора',
        'Ґанок',
        'Диня',
        'Ехо',
        'Єнот',
        'Іній',
        'Їжак',
        'Яблуко',
      ]);

      final rail = find.byKey(const ValueKey('songs-letter-rail'));
      final letters = tester
          .widgetList<Text>(
            find.descendant(of: rail, matching: find.byType(Text)),
          )
          .map((text) => text.data)
          .toList();
      expect(letters, ['Г', 'Ґ', 'Д', 'Е', 'Є', 'І', 'Ї', 'Я']);
    });

    testWidgets('accented Latin titles share the base letter section', (
      tester,
    ) async {
      final c = FakeUiController(
        (_) => VerseUiState(
          activeTab: VerseTab.songs,
          homeListMode: HomeListMode.library,
          songs: [
            _song('1', 'Zebra'),
            _song('2', 'Éclair'),
            _song('3', 'Eagle'),
            _song('4', 'Apple'),
          ],
        ),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      expect(find.text('E'), findsOneWidget, reason: 'one section header');
      expect(find.text('É'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Eagle')).dy,
        lessThan(tester.getTopLeft(find.text('Éclair')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Éclair')).dy,
        lessThan(tester.getTopLeft(find.text('Zebra')).dy),
      );
    });

    testWidgets('search ignores accents, case and surrounding spaces', (
      tester,
    ) async {
      final c = _LibraryFilterController();
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      await tester.enterText(find.byType(TextField), '  ECLAIR ');
      await tester.pump();
      expect(find.text('Éclair'), findsOneWidget);
      expect(find.text('Zebra'), findsNothing);
    });
  });

  group('Setlists', () {
    VerseUiState tab({int count = 2}) => VerseUiState(
      activeTab: VerseTab.setlists,
      setlists: [for (var i = 0; i < count; i++) _setlist('$i', 'List $i')],
    );

    testWidgets('card actions are at least 48dp tall', (tester) async {
      final c = FakeUiController((_) => tab(count: 1));
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      final title = find.ancestor(
        of: find.text('List 0'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(title.first).height, greaterThanOrEqualTo(48));
      final summary = find.ancestor(
        of: find.textContaining('3'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(summary.first).height, greaterThanOrEqualTo(48));
    });

    testWidgets('the expand control names and reports its state', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final c = FakeUiController((_) => tab(count: 1));
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      expect(
        find.bySemanticsLabel(l10n.accessibilityExpandSetlist('List 0')),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Icons.expand_more_rounded));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(l10n.accessibilityCollapseSetlist('List 0')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(l10n.accessibilityExpandSetlist('List 0')),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('full-width setlist rows stack in Arabic and English', (
      tester,
    ) async {
      final c = FakeUiController((_) => tab());
      addTearDown(c.dispose);
      await pumpShell(
        tester,
        c,
        size: const Size(900, 700),
        locale: const Locale('ar'),
      );
      expect(
        tester.getTopLeft(find.text('List 0')).dy,
        lessThan(tester.getTopLeft(find.text('List 1')).dy),
        reason: 'setlists follow the same vertical order in RTL',
      );

      await pumpShell(tester, c, size: const Size(900, 700));
      expect(
        tester.getTopLeft(find.text('List 0')).dy,
        lessThan(tester.getTopLeft(find.text('List 1')).dy),
      );
    });
  });

  group('Setlist detail', () {
    late String title;
    late String notes;
    late bool editing;
    FakeUiController make() => FakeUiController(
      (_) => VerseUiState(
        route: VerseRoute.setlistDetail,
        editingSetlist: editing,
        activeSetlist: SetlistCardData(
          id: 'set',
          title: title,
          notes: notes,
          entries: const [
            SetlistEntryData(id: 'e1', songId: 's1', title: 'Alpha'),
          ],
        ),
      ),
    );

    setUp(() {
      title = 'Sunday';
      notes = 'Old notes';
      editing = false;
    });

    String field(WidgetTester tester, int index) => tester
        .widget<TextField>(find.byType(TextField).at(index))
        .controller!
        .text;

    testWidgets('inline editing starts from the latest synced name', (
      tester,
    ) async {
      final c = make();
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      // A sync changes the stored setlist while the screen is open.
      title = 'Sunday (synced)';
      notes = 'Newer notes';
      c.refresh();
      await tester.pumpAndSettle();

      editing = true;
      c.refresh();
      await tester.pumpAndSettle();
      expect(field(tester, 0), 'Sunday (synced)');
      expect(find.byType(TextField), findsOneWidget);

      final l10n = l10nOf(tester);
      expect(find.text(l10n.setlistNotes), findsNothing);
      await tester.tap(find.byTooltip(l10n.actionSave));
      await tester.pump();
      expect(
        c.calls.last,
        startsWith('saveSetlistDetails(Sunday (synced), Newer notes'),
      );
    });

    testWidgets('sync does not replace the inline title or hidden notes', (
      tester,
    ) async {
      editing = true;
      final c = make();
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      await tester.enterText(find.byType(TextField).first, 'Typed title');
      notes = 'Remote notes';
      c.refresh();
      await tester.pumpAndSettle();
      expect(field(tester, 0), 'Typed title');
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.byTooltip(l10nOf(tester).actionSave));
      await tester.pump();
      expect(
        c.calls.last,
        startsWith('saveSetlistDetails(Typed title, Remote notes'),
      );
    });
  });

  group('Settings', () {
    testWidgets('default autoscroll is disabled while timing is manual', (
      tester,
    ) async {
      var state = _settings(timingMode: 'manual', autoscroll: false);
      final c = FakeUiController((_) => state);
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-menu-player')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-player')));
      await tester.pumpAndSettle();
      final tile = find.widgetWithText(
        SwitchListTile,
        l10n.settingsPlayerAutoscroll,
      );
      final settingsList = find.byType(ListView);
      expect(settingsList, findsOneWidget);
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find
            .descendant(of: settingsList, matching: find.byType(Scrollable))
            .first,
      );
      expect(tester.widget<SwitchListTile>(tile).onChanged, isNull);

      state = _settings();
      c.refresh();
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(tile).onChanged, isNotNull);
    });

    testWidgets('values that are not on offer do not break the dropdowns', (
      tester,
    ) async {
      final c = FakeUiController(
        (_) => _settings(
          palette: 'neon',
          fontFamily: 'comic',
          timingMode: 'laser',
          languageCode: 'xx',
        ),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      expect(tester.takeException(), isNull);
      final l10n = l10nOf(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-menu-appearance')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-appearance')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsSystemShort), findsWidgets);
    });

    for (final (size, scale) in const [
      (Size(640, 360), 1.0),
      (Size(640, 360), 2.0),
      (Size(360, 640), 2.0),
    ]) {
      testWidgets(
        'the About page scrolls instead of overflowing ($size x$scale)',
        (tester) async {
          final c = FakeUiController((_) => _settings());
          addTearDown(c.dispose);
          await pumpShell(tester, c, size: size, textScale: scale);
          final l10n = l10nOf(tester);

          final about = find.widgetWithText(ListTile, l10n.settingsAbout);
          final settingsList = find.byType(ListView);
          expect(settingsList, findsOneWidget);
          final aboutTitle = find.descendant(
            of: about,
            matching: find.text(l10n.settingsAbout),
          );
          await tester.scrollUntilVisible(
            aboutTitle,
            200,
            scrollable: find
                .descendant(
                  of: find.byType(Scaffold),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(aboutTitle);
          await tester.pumpAndSettle();
          await tester.tap(aboutTitle);
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          expect(tester.takeException(), isNull);
          expect(find.byType(SingleChildScrollView), findsOneWidget);
          expect(find.text(l10n.settingsAbout), findsOneWidget);
        },
      );
    }
  });
}
