import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/library/songs_screen.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

SongCardData _song(String id, String title, {bool favorite = false}) =>
    SongCardData(id: id, title: title, artist: 'Artist', favorite: favorite);

VerseUiState _songsTab(List<SongCardData> songs, {List<SetlistCardData>? sets}) =>
    VerseUiState(
      activeTab: VerseTab.songs,
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

      await tester.tap(find.byTooltip(l10n.settingsImportChordPro));
      await tester.pump();

      expect(c.calls, contains('importChordPro'));
    });

    testWidgets('the clear button empties the search field', (tester) async {
      final c = FakeUiController(
        (_) => _songsTab([_song('1', 'Alpha'), _song('2', 'Beta')]),
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

      expect(find.bySemanticsLabel(l10n.songsJumpToLetter('H')), findsOneWidget);
      final rail = tester.getRect(find.byKey(const ValueKey('songs-letter-rail')));
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
      expect(tester.state<ScrollableState>(list).position.pixels, greaterThan(0));
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
      expect(c.calls.where((call) => call.startsWith('createSetlist')), isEmpty);
    });
  });

  testWidgets('search submit is an icon inside the search field', (tester) async {
    final c = FakeUiController(
      (_) => const VerseUiState(activeTab: VerseTab.home),
    );
    addTearDown(c.dispose);
    await pumpShell(tester, c);
    final l10n = l10nOf(tester);

    expect(find.byTooltip(l10n.searchSubmit), findsOneWidget);
    expect(find.byTooltip(l10n.searchFilters), findsNothing);
    await tester.tap(find.byTooltip(l10n.songsAdd));
    await tester.pump();
    expect(c.calls, contains('createSong'));
    expect(find.text(l10n.searchSubmit), findsNothing);
  });

  testWidgets('Home, Songs, and Setlists search fields share the same width', (
    tester,
  ) async {
    var activeTab = VerseTab.home;
    final c = FakeUiController((_) => VerseUiState(activeTab: activeTab));
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

    await tester.tap(find.byTooltip(l10n.settingsImportSetlist));
    await tester.pump();

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
      expect(c.calls.where((call) => call.startsWith('saveLyricsEdit')), isEmpty);

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
      final c = setlist(editing: false);
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text(l10n.setlistSongMissing), findsOneWidget);
      await tester.tap(
        find.byTooltip(l10n.setlistRemoveSong(l10n.setlistSongMissing)),
      );
      await tester.pump();
      expect(c.calls, ['removeSetlistEntry(set, e2, null, null)']);
    });

    testWidgets('typed name and notes travel with a removal while editing', (
      tester,
    ) async {
      final c = setlist(editing: true);
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.enterText(find.byType(TextField).first, 'Typed name');
      await tester.enterText(find.byType(TextField).last, 'Typed notes');
      await tester.tap(find.byTooltip(l10n.setlistRemoveSong('Alpha')));
      await tester.pump();
      expect(c.calls, ['removeSetlistEntry(set, e1, Typed name, Typed notes)']);

      // The fields are still on screen: removal did not leave edit mode.
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.tap(find.byTooltip(l10n.actionSave));
      await tester.pump();
      expect(c.calls.last, contains('Typed name, Typed notes'));
      expect(c.calls.last, endsWith('true)'));
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

      await tester.drag(find.byType(Slider), const Offset(90, 0));
      await tester.pumpAndSettle();
      final saves = c.calls.where((call) => call.startsWith('setLyricsFontSize'));
      expect(saves, hasLength(1));
      expect(saves.single, isNot('setLyricsFontSize(24.0)'));
    });

    testWidgets('player switches describe themselves', (tester) async {
      final c = FakeUiController((_) => settings());
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      await tester.scrollUntilVisible(
        find.text(l10n.settingsDefaultAutoscrollHint),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l10n.settingsDefaultAutoscrollHint), findsOneWidget);
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
    }) =>
        VerseUiState(
          route: VerseRoute.reader,
          song: SongCardData(
            id: 's',
            title: 'Test song',
            artist: 'Artist',
            durationSeconds: 200,
            favorite: favorite,
          ),
          songLines: lines,
          playerSections: sections ?? const [
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
      expect(find.byTooltip(l10n.songFavoriteAdd), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('start-lyric-scroll')));
      expect(c.calls, contains('playPause'));

      await tester.drag(find.byType(Slider), const Offset(120, 0));
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
        (430.0, 1.0, 'V1', 'CH'),
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

      await pumpShell(
        tester,
        c,
        size: const Size(360, 640),
        textScale: 2,
      );
      expect(find.text('ПІ'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.semanticsLabel == longSection,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await pumpShell(
        tester,
        c,
        size: const Size(800, 640),
        textScale: 2,
      );
      expect(find.text(longSection), findsWidgets);
      expect(find.text('Chorus'), findsNothing);
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

      expect(tester.state<ScrollableState>(list).position.pixels, greaterThan(0));
      expect(find.text('2:30'), findsOneWidget);
      FontWeight? weightOf(String text) => (tester
              .widget<RichText>(find.text(text, findRichText: true))
              .text as TextSpan)
          .style
          ?.fontWeight;
      expect(weightOf('Lyric number 40'), FontWeight.w600);
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

    testWidgets('a landscape phone too short for the rail uses the bottom bar', (
      tester,
    ) async {
      final c = FakeUiController((_) => const VerseUiState());
      addTearDown(c.dispose);
      for (final size in const [Size(640, 360), Size(560, 340)]) {
        await pumpShell(tester, c, size: size);
        expect(find.byType(NavigationBar), findsOneWidget, reason: '$size');
        expect(
          find.byKey(const ValueKey('tablet-navigation-rail')),
          findsNothing,
          reason: '$size',
        );
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('a landscape tablet or tall-enough phone gets the rail', (
      tester,
    ) async {
      final c = FakeUiController((_) => const VerseUiState());
      addTearDown(c.dispose);
      for (final size in const [Size(700, 480), Size(560, 400), Size(844, 600)]) {
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
      await pumpShell(tester, c, size: const Size(700, 440), textScale: 2);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
