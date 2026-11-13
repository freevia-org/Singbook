import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/verse_app.dart' show singbookLocalizationsDelegates;
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/subpage_header.dart';

import 'support/fake_controller.dart';

/// Holds the text-size write open, like a slow settings store.
class _SlowFontController extends FakeUiController {
  _SlowFontController(super.build);
  final pending = <Completer<void>>[];

  @override
  Future<void> setLyricsFontSize(double size) {
    calls.add('setLyricsFontSize($size)');
    final completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }
}

const _songs = [
  SongCardData(id: 'b', title: 'Bravo', artist: 'Two'),
  SongCardData(id: 'a', title: 'Alpha', artist: 'One', favorite: true),
  SongCardData(id: 'e', title: 'Éclair', artist: 'Three'),
];

void main() {
  group('editor title', () {
    Future<FakeUiController> pumpNewSong(WidgetTester tester) async {
      final c = FakeUiController(
        (c) => VerseUiState(
          route: VerseRoute.editor,
          editing: true,
          editorDirty: c.dirty,
          editor: const SongEditorData(songId: '', isNew: true),
        ),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      return c;
    }

    testWidgets('made only of stripped characters is reported as missing', (
      tester,
    ) async {
      final c = await pumpNewSong(tester);
      final l10n = l10nOf(tester);
      await tester.enterText(
        find.widgetWithText(TextField, l10n.editorTitleField),
        '{ }',
      );
      await tester.pump();

      await tester.tap(find.byTooltip(l10n.actionSave));
      await tester.pump();

      expect(find.text(l10n.editorFieldRequired), findsOneWidget);
      expect(c.calls.where((call) => call.startsWith('saveLyricsEdit')), [
        // Nothing is sent: the stored title would have been empty.
      ]);

      // Typing a real title clears the error again.
      await tester.enterText(
        find.widgetWithText(TextField, l10n.editorTitleField),
        '{Morning} song',
      );
      await tester.pump();
      expect(find.text(l10n.editorFieldRequired), findsNothing);
    });
  });

  testWidgets('text-size slider keeps the chosen value while it is saved', (
    tester,
  ) async {
    final c = _SlowFontController(
      (_) => const VerseUiState(activeTab: VerseTab.settings),
    );
    addTearDown(c.dispose);
    await pumpShell(tester, c);
    await tester.tap(find.byKey(const ValueKey('settings-menu-appearance')));
    await tester.pumpAndSettle();

    Slider slider() => tester.widget<Slider>(find.byType(Slider));
    expect(slider().value, 24);

    slider().onChanged!(30);
    await tester.pump();
    slider().onChangeEnd!(30);
    await tester.pump();
    expect(c.calls, contains('setLyricsFontSize(30.0)'));
    // The stored size has not been published yet; no snap back to 24.
    expect(slider().value, 30);

    // A newer drag is not cleared by the older save completing.
    slider().onChanged!(34);
    await tester.pump();
    c.pending.first.complete();
    await tester.pump();
    expect(slider().value, 34);

    slider().onChangeEnd!(34);
    await tester.pump();
    c.pending.last.complete();
    await tester.pump();
    // This fake never changes its state, so the stored size shows again.
    expect(slider().value, 24);
  });

  group('songs list', () {
    testWidgets('follows the library, the filter and the favorites toggle', (
      tester,
    ) async {
      var songs = _songs;
      var favoritesOnly = false;
      final c = FakeUiController(
        (_) => VerseUiState(
          homeListMode: HomeListMode.library,
          songs: songs,
          favoritesOnly: favoritesOnly,
        ),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      double top(String title) => tester.getTopLeft(find.text(title)).dy;
      expect(top('Alpha'), lessThan(top('Bravo')));
      expect(top('Bravo'), lessThan(top('Éclair')));

      // The same list instance with another filter.
      favoritesOnly = true;
      c.refresh();
      await tester.pump();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsNothing);

      // A new list instance with the same filter.
      favoritesOnly = false;
      songs = [
        ..._songs,
        const SongCardData(id: 'c', title: 'Charlie', artist: 'Four'),
      ];
      c.refresh();
      await tester.pump();
      expect(top('Bravo'), lessThan(top('Charlie')));
      expect(top('Charlie'), lessThan(top('Éclair')));
    });
  });

  group('setlist name', () {
    Future<FakeUiController> pumpEditing(WidgetTester tester) async {
      final c = FakeUiController(
        (_) => const VerseUiState(
          route: VerseRoute.setlistDetail,
          editingSetlist: true,
          activeSetlist: SetlistCardData(id: 'list', title: 'Sunday'),
        ),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      return c;
    }

    testWidgets('typed but unsaved is discarded only after confirmation', (
      tester,
    ) async {
      final c = await pumpEditing(tester);
      final l10n = l10nOf(tester);
      await tester.enterText(
        find.byKey(const ValueKey('setlist-name-inline-field')),
        'Sunday evening',
      );
      await tester.pump();

      await tester.tap(find.byTooltip(l10n.navBack));
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsOneWidget);
      expect(c.calls, isNot(contains('back')));

      await tester.tap(find.text(l10n.editorKeepEditing));
      await tester.pumpAndSettle();
      expect(c.calls, isNot(contains('back')));
      expect(find.text('Sunday evening'), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.navBack));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.actionDiscard));
      await tester.pumpAndSettle();
      expect(c.calls, contains('back'));
    });

    testWidgets('unchanged or blank leaves without asking', (tester) async {
      final c = await pumpEditing(tester);
      final l10n = l10nOf(tester);

      await tester.tap(find.byTooltip(l10n.navBack));
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsNothing);
      expect(c.calls.where((call) => call == 'back'), hasLength(1));

      await tester.enterText(
        find.byKey(const ValueKey('setlist-name-inline-field')),
        '  ',
      );
      await tester.pump();
      await tester.tap(find.byTooltip(l10n.navBack));
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsNothing);
      expect(c.calls.where((call) => call == 'back'), hasLength(2));
    });
  });

  group('subpage header', () {
    Future<void> pumpHeader(WidgetTester tester, double scale) =>
        tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: singbookLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Column(
                children: [
                  SubpageHeader(
                    key: const ValueKey('header'),
                    title: 'Lanterns at Dawn',
                    onBack: () {},
                  ),
                ],
              ),
            ),
          ),
        );

    testWidgets('keeps its 52 dp bar at ordinary text sizes', (tester) async {
      for (final scale in [1.0, 1.3]) {
        await pumpHeader(tester, scale);
        expect(
          tester.getSize(find.byKey(const ValueKey('header'))).height,
          52,
          reason: 'scale $scale',
        );
      }
    });

    testWidgets('grows to fit one title line with very large text', (
      tester,
    ) async {
      await pumpHeader(tester, 3);
      final header = tester.getSize(find.byKey(const ValueKey('header')));
      final title = tester.getSize(find.text('Lanterns at Dawn'));
      expect(header.height, greaterThan(52));
      expect(title.height, lessThanOrEqualTo(header.height));
      expect(tester.takeException(), isNull);
    });
  });
}
