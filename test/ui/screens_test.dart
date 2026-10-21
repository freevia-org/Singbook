import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/library/songs_screen.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/adaptive_bottom_navigation.dart';

import 'support/fake_controller.dart';

class _InlineSetlistController extends FakeUiController {
  _InlineSetlistController()
    : super((controller) {
        final c = controller as _InlineSetlistController;
        return VerseUiState(
          route: VerseRoute.setlistDetail,
          editingSetlist: c.editing,
          activeSetlist: SetlistCardData(
            id: 'set',
            title: c.title,
            notes: c.notes,
            entries: const [
              SetlistEntryData(id: 'e1', songId: 's1', title: 'Alpha'),
            ],
          ),
        );
      });

  bool editing = false;
  String title = 'Sunday';
  final String notes = 'Keep stored but hidden';

  @override
  Future<void> editSetlist(String id) async {
    calls.add('editSetlist($id)');
    editing = true;
    refresh();
  }

  @override
  Future<void> saveSetlistDetails({
    required String name,
    required String notes,
    List<String>? entryOrder,
    bool finishEditing = false,
  }) async {
    calls.add('saveSetlistDetails($name, $notes, $entryOrder, $finishEditing)');
    if (name.trim().isNotEmpty) title = name;
    if (finishEditing) {
      editing = false;
      refresh();
    }
  }
}

class _QueryController extends FakeUiController {
  _QueryController(super.build);

  String query = '';

  @override
  void setQuery(String value) {
    query = value;
    calls.add('setQuery($value)');
    refresh();
  }
}

SongCardData _song(String id, String title, {bool favorite = false}) =>
    SongCardData(id: id, title: title, artist: 'Artist', favorite: favorite);

VerseUiState _songsTab(
  List<SongCardData> songs, {
  List<SetlistCardData>? sets,
  String query = '',
}) => VerseUiState(
  activeTab: VerseTab.songs,
  homeListMode: HomeListMode.library,
  query: query,
  songs: songs,
  setlists: sets ?? const [],
);

void main() {
  group('Songs', () {
    testWidgets('song import is on the Songs screen', (tester) async {
      final c = FakeUiController((_) => _songsTab([_song('1', 'Alpha')]));
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.settingsImportChordPro));
      await tester.pumpAndSettle();

      expect(c.calls, contains('importChordPro'));
    });

    testWidgets('the clear button empties the search field', (tester) async {
      final c = _QueryController(
        (controller) => _songsTab([
          _song('1', 'Alpha'),
          _song('2', 'Beta'),
        ], query: (controller as _QueryController).query),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text(l10n.songsEmptySearch), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.accessibilityClearSearch));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.byTooltip(l10n.accessibilityClearSearch), findsNothing);
    });

    testWidgets('index letters are labelled and jump to their section', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final songs = [
        for (final letter in 'ABCDEFGH'.split(''))
          for (var i = 0; i < 5; i++) _song('$letter$i', '$letter song $i'),
      ];
      final c = FakeUiController((_) => _songsTab(songs));
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      expect(
        find.bySemanticsLabel(l10n.songsJumpToLetter('H')),
        findsOneWidget,
      );
      final rail = tester.getRect(
        find.byKey(const ValueKey('songs-letter-rail')),
      );
      expect(rail.width, greaterThanOrEqualTo(44));

      final list = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      );
      expect(tester.state<ScrollableState>(list).position.pixels, 0);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('songs-letter-rail')),
          matching: find.text('H'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(list).position.pixels,
        greaterThan(0),
      );
      expect(find.text('H song 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    test('index letters keep whole characters and mark untitled songs', () {
      expect(songIndexLetter('apple'), 'A');
      expect(songIndexLetter('  zebra'), 'Z');
      expect(songIndexLetter(''), '#');
      expect(songIndexLetter('😀 Smile'), '😀');
      expect(songIndexLetter('éclair'), 'E');
    });

    for (final entry in {
      const Locale('en'): 'New setlist',
      const Locale('bg'): 'Нов списък',
      const Locale('uk'): 'Новий сетлист',
    }.entries) {
      testWidgets(
        'adding a song with no setlists creates a localized one (${entry.key})',
        (tester) async {
          final c = FakeUiController((_) => _songsTab([_song('s1', 'Alpha')]));
          addTearDown(c.dispose);
          await pumpShell(tester, c, locale: entry.key);
          final l10n = l10nOf(tester);
          expect(l10n.setlistCreate, isNotEmpty);

          await tester.tap(find.byTooltip(l10n.songMenuLabel).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.songAddToSetlist));
          await tester.pumpAndSettle();

          expect(
            c.calls,
            contains('createSetlist(name: ${l10n.setlistCreate}, songId: s1)'),
          );
          if (entry.key.languageCode != 'en') {
            expect(l10n.setlistCreate, isNot('New setlist'));
          }
        },
      );
    }

    testWidgets('adding to an existing setlist uses the chosen one', (
      tester,
    ) async {
      final c = FakeUiController(
        (_) => _songsTab(
          [_song('s1', 'Alpha')],
          sets: const [SetlistCardData(id: 'set1', title: 'Sunday')],
        ),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.tap(find.byTooltip(l10n.songMenuLabel).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.songAddToSetlist));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sunday'));
      await tester.pumpAndSettle();

      expect(c.calls, contains('addSongToSetlist(s1, set1)'));
      expect(
        c.calls.where((call) => call.startsWith('createSetlist')),
        isEmpty,
      );
    });
  });

  testWidgets('search submit stays in the field and Home has no add button', (
    tester,
  ) async {
    final c = FakeUiController(
      (_) => const VerseUiState(activeTab: VerseTab.home),
    );
    addTearDown(c.dispose);
    await pumpShell(tester, c);
    final l10n = l10nOf(tester);

    expect(find.byTooltip(l10n.searchSubmit), findsOneWidget);
    expect(find.byTooltip(l10n.searchFilters), findsNothing);
    expect(find.byTooltip(l10n.songsAdd), findsNothing);
    expect(find.text(l10n.searchSubmit), findsNothing);
  });

  testWidgets('Songs and Setlists search headers align with Home Favorites', (
    tester,
  ) async {
    var activeTab = VerseTab.home;
    final c = _QueryController(
      (controller) => VerseUiState(
        activeTab: activeTab,
        homeListMode: activeTab == VerseTab.songs
            ? HomeListMode.library
            : HomeListMode.recent,
        query: (controller as _QueryController).query,
      ),
    );
    addTearDown(c.dispose);
    await pumpShell(tester, c);
    final homeWidth = tester.getSize(find.byType(TextField).first).width;

    activeTab = VerseTab.songs;
    c.refresh();
    await tester.pumpAndSettle();
    final songsWidth = tester.getSize(find.byType(TextField).first).width;

    activeTab = VerseTab.setlists;
    c.refresh();
    await tester.pumpAndSettle();
    final setlistsWidth = tester.getSize(find.byType(TextField).first).width;

    expect(songsWidth, homeWidth);
    expect(setlistsWidth, homeWidth);
  });

  testWidgets('setlist import is on the Setlists screen', (tester) async {
    final c = FakeUiController(
      (_) => const VerseUiState(activeTab: VerseTab.setlists),
    );
    addTearDown(c.dispose);
    await pumpShell(tester, c);
    final l10n = l10nOf(tester);

    await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${l10n.settingsImportSetlist} (.osts)'));
    await tester.pumpAndSettle();

    expect(c.calls, contains('importSetlist'));
  });

  group('Editor', () {
    FakeUiController editor({bool isNew = true, String title = ''}) =>
        FakeUiController(
          (c) => VerseUiState(
            route: VerseRoute.editor,
            editing: true,
            editorDirty: c.dirty,
            editor: SongEditorData(songId: 'draft', isNew: isNew, title: title),
          ),
        );

    testWidgets('leaving with unsaved changes asks first', (tester) async {
      final c = editor();
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.enterText(find.byType(TextField).first, 'My song');
      await tester.pump();
      expect(c.calls, contains('setEditorDirty(true)'));

      await tester.tap(find.byTooltip(l10n.navBack));
      // The app waits for the Android IME hide transition before presenting
      // the discard prompt so the dialog is laid out at the full viewport.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsOneWidget);
      expect(find.text(l10n.editorUnsavedMessage), findsOneWidget);

      await tester.tap(find.text(l10n.editorKeepEditing));
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsNothing);
      expect(c.calls, isNot(contains('back')));

      // The system back gesture is intercepted the same way.
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsOneWidget);
      await tester.tap(find.text(l10n.actionDiscard));
      await tester.pumpAndSettle();
      expect(c.calls, contains('back'));
    });

    testWidgets('leaving an untouched editor needs no confirmation', (
      tester,
    ) async {
      final c = editor(isNew: false, title: 'Existing');
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.tap(find.byTooltip(l10n.navBack));
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsNothing);
      expect(c.calls, contains('back'));
    });

    testWidgets('reverting an edit clears the unsaved state', (tester) async {
      final c = editor(isNew: false, title: 'Existing');
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      await tester.enterText(find.byType(TextField).first, 'Changed');
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'Existing');
      await tester.pump();
      expect(
        c.calls.where((call) => call.startsWith('setEditorDirty')).toList(),
        ['setEditorDirty(true)', 'setEditorDirty(false)'],
      );
    });

    testWidgets('saving an empty new song explains what is missing', (
      tester,
    ) async {
      final c = editor();
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.tap(find.byTooltip(l10n.actionSave));
      await tester.pump();
      expect(find.text(l10n.editorFieldRequired), findsOneWidget);
      expect(
        c.calls.where((call) => call.startsWith('saveLyricsEdit')),
        isEmpty,
      );

      await tester.enterText(find.byType(TextField).first, 'My song');
      await tester.pump();
      expect(find.text(l10n.editorFieldRequired), findsNothing);

      await tester.tap(find.byTooltip(l10n.actionSave));
      // A valid save waits for the keyboard inset to clear before navigating.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(
        c.calls.singleWhere((call) => call.startsWith('saveLyricsEdit')),
        contains('{title: My song}'),
      );
    });
  });

  group('Setlists', () {
    testWidgets(
      'compact preview taps expand songs and label partial estimated totals',
      (tester) async {
        final c = FakeUiController(
          (_) => const VerseUiState(
            activeTab: VerseTab.setlists,
            setlists: [
              SetlistCardData(
                id: 'set',
                title: 'Sunday',
                songTitles: ['Alpha', 'Beta', 'Gamma'],
                durationSeconds: 360,
                durationEstimated: true,
                durationPartial: true,
              ),
            ],
          ),
        );
        addTearDown(c.dispose);
        await pumpShell(tester, c);
        final l10n = l10nOf(tester);
        expect(find.textContaining('Gamma'), findsNothing);
        expect(
          find.textContaining(l10n.setlistDurationPartial('~6:00')),
          findsOneWidget,
        );
        await tester.tap(find.text('Alpha · Beta'));
        await tester.pumpAndSettle();
        expect(find.text('1. Alpha\n2. Beta\n3. Gamma'), findsOneWidget);
        expect(c.calls, isEmpty);
        await tester.tap(find.text('1. Alpha\n2. Beta\n3. Gamma'));
        await tester.pumpAndSettle();
        expect(find.text('Alpha · Beta'), findsOneWidget);
      },
    );

    testWidgets('hidden notes do not affect setlist search', (tester) async {
      final c = FakeUiController(
        (_) => const VerseUiState(
          activeTab: VerseTab.setlists,
          setlists: [
            SetlistCardData(
              id: 'set',
              title: 'Sunday',
              notes: 'Hidden rehearsal note',
            ),
          ],
        ),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);
      final search = find.byType(TextField);

      await tester.enterText(search, 'rehearsal');
      await tester.pump();
      expect(find.text(l10n.setlistsEmptySearch), findsOneWidget);

      await tester.enterText(search, 'Sunday');
      await tester.pump();
      expect(
        find.descendant(of: find.byType(Card), matching: find.text('Sunday')),
        findsOneWidget,
      );
    });
  });

  group('Setlist detail', () {
    FakeUiController setlist({required bool editing}) => FakeUiController(
      (_) => VerseUiState(
        route: VerseRoute.setlistDetail,
        editingSetlist: editing,
        activeSetlist: const SetlistCardData(
          id: 'set',
          title: 'Sunday',
          notes: 'Old notes',
          entries: [
            SetlistEntryData(id: 'e1', songId: 's1', title: 'Alpha'),
            SetlistEntryData(id: 'e2', songId: 'gone', missing: true),
          ],
        ),
      ),
    );

    testWidgets('a song missing from the library can be removed', (
      tester,
    ) async {
      final c = _UndoSetlistController(
        (_) => const VerseUiState(
          route: VerseRoute.setlistDetail,
          activeSetlist: SetlistCardData(
            id: 'set',
            title: 'Sunday',
            entries: [
              SetlistEntryData(id: 'e2', songId: 'gone', missing: true),
            ],
          ),
        ),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      expect(find.text(l10n.setlistSongMissing), findsOneWidget);
      await _dragSetlistRowToDeleteBasket(tester, 'e2');
      expect(c.calls, ['removeSetlistEntry(set, e2, null, null)']);
      final undoLabel = l10n.actionUndo;
      expect(find.text(undoLabel), findsOneWidget);
      await tester.tap(find.text(undoLabel));
      await tester.pumpAndSettle();
      expect(c.calls.last, 'restore(e2)');
    });

    testWidgets(
      'editing the title preserves hidden notes when removing a song',
      (tester) async {
        final c = setlist(editing: true);
        addTearDown(c.dispose);
        await pumpShell(tester, c);
        final l10n = l10nOf(tester);

        await tester.enterText(find.byType(TextField).first, 'Typed name');
        expect(find.text(l10n.setlistNotes), findsNothing);
        expect(find.byType(TextField), findsOneWidget);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await _dragSetlistRowToDeleteBasket(tester, 'e1');
        expect(c.calls, ['removeSetlistEntry(set, e1, Typed name, Old notes)']);

        // The inline title remains while removal did not leave edit mode.
        expect(find.byType(TextField), findsOneWidget);
        await tester.tap(find.byTooltip(l10n.actionSave));
        await tester.pump();
        expect(c.calls.last, contains('Typed name, Old notes'));
        expect(c.calls.last, endsWith('true)'));
      },
    );

    testWidgets('tapping the setlist title edits it in place and hides notes', (
      tester,
    ) async {
      final c = _InlineSetlistController();
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.tap(find.text('Sunday'));
      await tester.pumpAndSettle();

      final nameField = find.byKey(const ValueKey('setlist-name-inline-field'));
      expect(nameField, findsOneWidget);
      expect(tester.widget<TextField>(nameField).controller!.text, 'Sunday');
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(l10n.setlistNotes), findsNothing);
      expect(find.text('Keep stored but hidden'), findsNothing);
      await tester.enterText(nameField, 'Sunday Set');
      await tester.tap(find.byTooltip(l10n.actionSave));
      await tester.pumpAndSettle();

      expect(
        c.calls.last,
        contains('saveSetlistDetails(Sunday Set, Keep stored but hidden'),
      );
      expect(c.editing, isFalse);
      expect(find.text('Sunday Set'), findsOneWidget);
    });

    testWidgets('the setlist pencil opens the same inline title editor', (
      tester,
    ) async {
      final c = _InlineSetlistController();
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.tap(find.byTooltip(l10n.actionEdit));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('setlist-name-inline-field')),
            )
            .controller!
            .text,
        'Sunday',
      );
      expect(find.text(l10n.setlistNotes), findsNothing);
      expect(c.calls, contains('editSetlist(set)'));
    });

    for (final missing in [false, true]) {
      testWidgets('entry menu removes without dragging, missing=$missing', (
        tester,
      ) async {
        final c = _UndoSetlistController(
          (_) => VerseUiState(
            route: VerseRoute.setlistDetail,
            activeSetlist: SetlistCardData(
              id: 'set',
              title: 'Sunday',
              entries: [
                SetlistEntryData(
                  id: 'entry',
                  songId: missing ? 'gone' : 'song',
                  title: 'Alpha',
                  missing: missing,
                ),
              ],
            ),
          ),
        );
        addTearDown(c.dispose);
        await pumpShell(tester, c);
        final l10n = l10nOf(tester);
        final menu = find.byTooltip(l10n.songMenuLabel);
        expect(menu, findsOneWidget);
        await tester.tap(menu);
        await tester.pumpAndSettle();
        final label = l10n.setlistRemoveSong(
          missing ? l10n.setlistSongMissing : 'Alpha',
        );
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(c.calls, ['removeSetlistEntry(set, entry, null, null)']);
        await tester.tap(find.text(l10n.actionUndo));
        await tester.pumpAndSettle();
        expect(c.calls.last, 'restore(entry)');
      });
    }

    testWidgets('releasing a row outside the basket keeps its entry', (
      tester,
    ) async {
      final c = setlist(editing: false);
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final row = find.byKey(const ValueKey('e1'));
      final gesture = await tester.startGesture(tester.getCenter(row));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(0, 5));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(c.calls, isEmpty);
      expect(find.byKey(const ValueKey('e1')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('setlist-delete-basket')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('setlist-delete-basket')))
            .height,
        0,
      );
    });
  });

  group('Settings', () {
    VerseUiState settings({double fontSize = 24}) => VerseUiState(
      activeTab: VerseTab.settings,
      lyricsFontSize: fontSize,
      providers: [
        for (var i = 0; i < 14; i++)
          ProviderSettingData(
            id: 'p$i',
            name: 'Provider $i',
            enabled: true,
            description: 'lyrics',
          ),
      ],
    );

    testWidgets('the cloud button brings the account section into view', (
      tester,
    ) async {
      final c = FakeUiController((_) => settings());
      addTearDown(c.dispose);
      var consumed = 0;
      await pumpShell(
        tester,
        c,
        syncFocusRequest: 1,
        onSyncFocusConsumed: () => consumed++,
      );
      final l10n = l10nOf(tester);

      final label = tester.getRect(find.text(l10n.accountTitle));
      expect(label.top, greaterThanOrEqualTo(0));
      expect(label.bottom, lessThanOrEqualTo(780));
      expect(consumed, 1);
    });

    testWidgets('the font size is saved once, when the drag ends', (
      tester,
    ) async {
      final c = FakeUiController((_) => settings());
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-menu-appearance')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-appearance')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Slider), const Offset(90, 0));
      await tester.pumpAndSettle();
      final saves = c.calls.where(
        (call) => call.startsWith('setLyricsFontSize'),
      );
      expect(saves, hasLength(1));
      expect(saves.single, isNot('setLyricsFontSize(24.0)'));
    });

    testWidgets('player switches describe themselves', (tester) async {
      final c = FakeUiController((_) => settings());
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-menu-player')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-player')));
      await tester.pumpAndSettle();
      final autoscrollHint = find.byTooltip(l10n.settingsDefaultAutoscrollHint);
      await tester.scrollUntilVisible(
        autoscrollHint,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.longPress(autoscrollHint);
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsDefaultAutoscrollHint), findsOneWidget);
      await tester.ensureVisible(
        find.byTooltip(l10n.settingsDefaultShowChordsHint),
      );
      await tester.longPress(
        find.byTooltip(l10n.settingsDefaultShowChordsHint),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsDefaultShowChordsHint), findsOneWidget);
      expect(find.text(l10n.playerTimingStatusReady), findsNothing);
      expect(find.text(l10n.playerTimingStatusEstimated), findsNothing);
    });

    testWidgets('dropdowns are labelled for screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      final c = FakeUiController((_) => settings());
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-menu-appearance')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-appearance')));
      await tester.pumpAndSettle();
      final semanticsOfLanguage = tester.getSemantics(
        find.byType(DropdownButton<String>).first,
      );
      expect(semanticsOfLanguage.label, contains(l10n.settingsLanguage));
      expect(semanticsOfLanguage.label, contains(l10n.settingsLanguageSystem));
      // The visible title is not announced a second time on its own.
      expect(
        find.bySemanticsLabel(l10n.settingsLanguage),
        findsNothing,
        reason: 'only the combined dropdown label exists',
      );
      semantics.dispose();
    });
  });

  group('Player', () {
    final lines = [
      for (var i = 0; i < 60; i++)
        LyricLineData(id: 'line-$i', text: 'Lyric number $i'),
    ];
    VerseUiState reader(
      FakeUiController c, {
      bool favorite = false,
      List<PlayerSectionMarker>? sections,
    }) => VerseUiState(
      route: VerseRoute.reader,
      song: SongCardData(
        id: 's',
        title: 'Test song',
        artist: 'Artist',
        durationSeconds: 200,
        favorite: favorite,
      ),
      songLines: lines,
      playerSections:
          sections ??
          const [
            PlayerSectionMarker(
              name: 'Verse 1',
              startSeconds: 0,
              lineId: 'line-0',
            ),
            PlayerSectionMarker(
              name: 'Chorus',
              startSeconds: 100,
              lineId: 'line-30',
            ),
          ],
      readerKey: 'D',
      readerCapo: '2',
    );

    testWidgets('transport, seek bar and subtitle', (tester) async {
      final c = FakeUiController(reader);
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      expect(find.textContaining('${l10n.editorKeyField}: D'), findsOneWidget);
      expect(find.textContaining('${l10n.editorCapoField}: 2'), findsOneWidget);
      expect(find.byTooltip(l10n.songFavoriteAdd), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('start-lyric-scroll')));
      expect(c.calls, contains('playPause'));

      await tester.drag(
        find.byKey(const ValueKey('player-seek-slider')),
        const Offset(120, 0),
      );
      await tester.pump();
      expect(c.calls.where((call) => call.startsWith('seek(')), isNotEmpty);
      expect(c.positionNotifier.value.seconds, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('section labels adapt to the player width', (tester) async {
      final c = FakeUiController(reader);
      addTearDown(c.dispose);

      for (final (width, textScale, firstLabel, secondLabel) in [
        (360.0, 1.0, 'V1', 'C'),
        (360.0, 2.0, 'V1', 'C'),
        (430.0, 1.0, 'V1', 'C'),
        (460.0, 1.0, 'V1', 'CH'),
        (800.0, 1.0, 'Verse 1', 'Chorus'),
      ]) {
        await pumpShell(
          tester,
          c,
          size: Size(width, 640),
          textScale: textScale,
        );
        expect(find.text(firstLabel), findsWidgets, reason: '$width dp');
        expect(find.text(secondLabel), findsOneWidget, reason: '$width dp');
        expect(tester.takeException(), isNull, reason: '$width dp');
      }
    });

    testWidgets('long localized section labels remain bounded', (tester) async {
      const longSection =
          'Приспів із надзвичайно довгою назвою для інструментального переходу, '
          'повторена ще раз для перевірки безпечного відображення на екрані';
      final c = FakeUiController(
        (c) => reader(
          c,
          sections: const [
            PlayerSectionMarker(
              name: longSection,
              startSeconds: 0,
              lineId: 'line-0',
            ),
            PlayerSectionMarker(
              name: 'Chorus',
              startSeconds: 53,
              lineId: 'line-30',
            ),
          ],
        ),
      );
      addTearDown(c.dispose);

      await pumpShell(tester, c, size: const Size(360, 640), textScale: 2);
      expect(find.text('ПІ'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.semanticsLabel == longSection,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await pumpShell(tester, c, size: const Size(800, 640), textScale: 2);
      expect(find.text(longSection), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.semanticsLabel == longSection,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the favorite button names its action', (tester) async {
      final c = FakeUiController((c) => reader(c, favorite: true));
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      expect(find.byTooltip(l10n.songFavoriteRemove), findsOneWidget);
      expect(find.byTooltip(l10n.songFavoriteAdd), findsNothing);
    });

    testWidgets('position updates highlight and scroll to the playing line', (
      tester,
    ) async {
      final c = FakeUiController(reader);
      addTearDown(c.dispose);
      await pumpShell(tester, c, size: const Size(360, 640));
      final list = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      );
      expect(tester.state<ScrollableState>(list).position.pixels, 0);

      c.positionNotifier.value = const PlayerPosition(150, 'line-40');
      await tester.pumpAndSettle();

      expect(
        tester.state<ScrollableState>(list).position.pixels,
        greaterThan(0),
      );
      expect(find.text('2:30'), findsOneWidget);
      FontWeight? weightOf(String text) =>
          (tester.widget<RichText>(find.text(text, findRichText: true)).text
                  as TextSpan)
              .style
              ?.fontWeight;
      expect(weightOf('Lyric number 40'), FontWeight.w400);
      expect(weightOf('Lyric number 39'), FontWeight.w400);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tick only rebuilds the player, not the controller state', (
      tester,
    ) async {
      var reads = 0;
      final c = FakeUiController((c) {
        reads++;
        return reader(c);
      });
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final before = reads;

      for (var second = 1; second <= 5; second++) {
        c.positionNotifier.value = PlayerPosition(second.toDouble(), 'line-0');
        await tester.pump();
      }
      // Each tick may read state once inside the player (cached in the
      // adapter), but never notifies the application shell.
      expect(reads - before, lessThanOrEqualTo(10));
      expect(find.text('0:05'), findsOneWidget);
    });
  });

  group('Shell', () {
    testWidgets('a notice is shown as a localized snackbar', (tester) async {
      final c = FakeUiController((_) => const VerseUiState());
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      c.emit(UiNotice.copied);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n.settingsCopied), findsOneWidget);

      c.emit(UiNotice.importTooLarge);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n.settingsImportTooLarge), findsOneWidget);
    });

    for (final locale in const [Locale('bg'), Locale('uk')]) {
      testWidgets('notices are localized in $locale', (tester) async {
        final c = FakeUiController((_) => const VerseUiState());
        addTearDown(c.dispose);
        await pumpShell(tester, c, locale: locale);
        final l10n = l10nOf(tester);
        c.emit(UiNotice.songDeleted);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(l10n.songDeleted), findsOneWidget);
        expect(l10n.songDeleted, isNot('Song deleted.'));
      });
    }

    testWidgets(
      'a landscape phone too short for the rail uses the bottom bar',
      (tester) async {
        final c = FakeUiController((_) => const VerseUiState());
        addTearDown(c.dispose);
        for (final size in const [Size(640, 280), Size(560, 280)]) {
          await pumpShell(tester, c, size: size);
          expect(
            find.byType(AdaptiveBottomNavigation),
            findsOneWidget,
            reason: '$size',
          );
          expect(
            find.byKey(const ValueKey('tablet-navigation-rail')),
            findsNothing,
            reason: '$size',
          );
          expect(tester.takeException(), isNull, reason: '$size');
        }
      },
    );

    testWidgets('iPhone landscape safe areas keep all navigation reachable', (
      tester,
    ) async {
      final c = FakeUiController((_) => const VerseUiState());
      addTearDown(c.dispose);
      tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 62, bottom: 34);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await pumpShell(tester, c, size: const Size(874, 372));
      expect(find.byType(AdaptiveBottomNavigation), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tablet-navigation-rail')),
        findsNothing,
      );
      final settings = find.descendant(
        of: find.byType(AdaptiveBottomNavigation),
        matching: find.text(l10nOf(tester).navSettings),
      );
      expect(settings.hitTestable(), findsOneWidget);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(c.calls, contains('setTab'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a landscape tablet or tall-enough phone gets the rail', (
      tester,
    ) async {
      final c = FakeUiController((_) => const VerseUiState());
      addTearDown(c.dispose);
      for (final size in const [
        Size(640, 360),
        Size(700, 480),
        Size(560, 400),
        Size(844, 600),
      ]) {
        await pumpShell(tester, c, size: size);
        expect(
          find.byKey(const ValueKey('tablet-navigation-rail')),
          findsOneWidget,
          reason: '$size',
        );
        expect(find.byType(NavigationBar), findsNothing, reason: '$size');
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('the rail is dropped when large text makes it too tall', (
      tester,
    ) async {
      final c = FakeUiController((_) => const VerseUiState());
      addTearDown(c.dispose);
      await pumpShell(tester, c, size: const Size(700, 340), textScale: 2);
      expect(find.byType(AdaptiveBottomNavigation), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tablet-navigation-rail')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _dragSetlistRowToDeleteBasket(
  WidgetTester tester,
  String entryId,
) async {
  final row = find.byKey(ValueKey(entryId));
  final gesture = await tester.startGesture(tester.getCenter(row));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();

  final basket = find.byKey(const ValueKey('setlist-delete-basket'));
  expect(basket, findsOneWidget);
  final target = tester.getCenter(basket);
  const steps = 8;
  final start = tester.getCenter(row);
  for (var step = 1; step <= steps; step++) {
    await gesture.moveTo(start + (target - start) * (step / steps));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

class _UndoSetlistController extends FakeUiController {
  _UndoSetlistController(super.build);

  @override
  Future<SetlistEntryRemovalData?> removeSetlistEntryWithUndo(
    String setlistId,
    String entryId, {
    String? name,
    String? notes,
  }) async {
    await removeSetlistEntry(setlistId, entryId, name: name, notes: notes);
    return SetlistEntryRemovalData(
      setlistId: setlistId,
      entryId: entryId,
      songId: 'gone',
      overrides: const {},
      index: 0,
    );
  }

  @override
  Future<void> restoreSetlistEntry(SetlistEntryRemovalData removed) async {
    calls.add('restore(${removed.entryId})');
  }
}
