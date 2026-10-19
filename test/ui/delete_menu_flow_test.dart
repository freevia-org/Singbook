import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const menuSong = SongCardData(
  id: 'owned-song',
  title: 'Owned song',
  artist: 'Local fixture',
  durationSeconds: 120,
);
const menuSetlist = SetlistCardData(
  id: 'owned-setlist',
  title: 'Owned setlist',
  songTitles: ['Owned song'],
  songIds: ['owned-song'],
  entries: [
    SetlistEntryData(id: 'entry', songId: 'owned-song', title: 'Owned song'),
  ],
);

VerseUiState menuState(String screen, {bool draft = false}) => VerseUiState(
  route: screen == 'player'
      ? VerseRoute.reader
      : screen == 'editor'
      ? VerseRoute.editor
      : screen == 'setlist-edit'
      ? VerseRoute.setlistDetail
      : VerseRoute.main,
  activeTab: screen == 'songs'
      ? VerseTab.songs
      : screen == 'setlists'
      ? VerseTab.setlists
      : VerseTab.home,
  homeListMode: screen == 'songs' ? HomeListMode.library : HomeListMode.recent,
  songs: const [menuSong],
  setlists: const [menuSetlist],
  recent: [
    RecentItemData(
      id: screen == 'recent-setlist' ? menuSetlist.id : menuSong.id,
      title: screen == 'recent-setlist' ? menuSetlist.title : menuSong.title,
      occurredAt: DateTime.utc(2026),
      isSetlist: screen == 'recent-setlist',
    ),
  ],
  song: menuSong,
  songLines: const [LyricLineData(id: 'line', text: 'A synthetic local lyric')],
  readerCanCompareVersions: true,
  readerTimingAvailable: true,
  timingMode: 'timed',
  activeSetlist: menuSetlist,
  editingSetlist: screen == 'setlist-edit',
  editing: screen == 'editor',
  editor: screen == 'editor'
      ? SongEditorData(
          songId: menuSong.id,
          isNew: draft,
          title: menuSong.title,
          artist: menuSong.artist,
          body: 'Typed lyric',
        )
      : null,
);

class MenuController extends FakeUiController {
  MenuController(String screen, {bool draft = false})
    : super((_) => menuState(screen, draft: draft));
  final deletedSongs = <String>[];
  final deletedSetlists = <String>[];
  @override
  Future<void> deleteSong(String id) async => deletedSongs.add(id);
  @override
  Future<void> deleteSetlist(String id) async => deletedSetlists.add(id);
}

Future<void> openActionMenu(WidgetTester tester, String screen) async {
  final l10n = l10nOf(tester);
  final tooltip = screen.startsWith('recent') || screen == 'setlists'
      ? screen == 'recent-setlist' || screen == 'setlists'
            ? l10n.accessibilitySetlistMenu(menuSetlist.title)
            : l10n.accessibilitySongMenu(menuSong.title)
      : screen.startsWith('setlist')
      ? l10n.setlistMenuLabel
      : l10n.songMenuLabel;
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

List<String> renderedMenuActions(WidgetTester tester) => tester
    .widgetList<PopupMenuItem<String>>(
      find.byWidgetPredicate((w) => w is PopupMenuItem<String>),
    )
    .map((w) => w.value!)
    .toList();

void main() {
  for (final screen in [
    'recent-song',
    'songs',
    'setlists',
    'player',
    'editor',
    'setlist-edit',
  ]) {
    testWidgets('$screen preserves available actions and common export order', (
      tester,
    ) async {
      final controller = MenuController(screen);
      addTearDown(controller.dispose);
      await pumpShell(tester, controller, size: const Size(390, 844));
      await openActionMenu(tester, screen);
      final actions = renderedMenuActions(tester);
      if (screen == 'editor') {
        expect(actions, ['delete']);
        expect(find.byType(PopupMenuDivider), findsNothing);
      } else {
        expect(
          actions.where({'share', 'share_pdf', 'copy', 'print'}.contains),
          ['share', 'share_pdf', 'copy', 'print'],
        );
        if (!screen.startsWith('recent')) {
          expect(actions.last, 'delete');
        }
        if (screen.startsWith('recent')) {
          expect(actions, isNot(contains('delete')));
        }
        if (screen == 'songs' || screen == 'setlists') {
          expect(actions.first, 'edit');
        }
        if (screen == 'player') {
          expect(actions.take(4), ['info', 'compare', 'timed-lyrics', 'add']);
          final checked = tester.widget<CheckedPopupMenuItem<String>>(
            find.byWidgetPredicate((w) => w is CheckedPopupMenuItem<String>),
          );
          expect(checked.checked, isTrue);
        }
        final entries = tester
            .widgetList<PopupMenuEntry<String>>(
              find.byWidgetPredicate((w) => w is PopupMenuEntry<String>),
            )
            .toList();
        expect(entries.first, isNot(isA<PopupMenuDivider>()));
        expect(entries.last, isNot(isA<PopupMenuDivider>()));
        for (var i = 1; i < entries.length; i++) {
          expect(
            entries[i] is PopupMenuDivider &&
                entries[i - 1] is PopupMenuDivider,
            isFalse,
          );
        }
      }
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Songs Recent excludes setlists while the Setlists menu remains available',
    (tester) async {
      final controller = MenuController('recent-setlist');
      addTearDown(controller.dispose);
      await pumpShell(tester, controller, size: const Size(390, 844));
      expect(
        find.byKey(const ValueKey('recent-setlist-row-owned-setlist')),
        findsNothing,
      );
      expect(
        find.byTooltip(
          l10nOf(tester).accessibilitySetlistMenu(menuSetlist.title),
        ),
        findsNothing,
      );
      expect(controller.calls, isEmpty);
    },
  );

  for (final screen in ['player', 'editor', 'setlist-edit']) {
    testWidgets(
      '$screen confirms deletion and cancellation preserves typed data',
      (tester) async {
        final controller = MenuController(screen);
        addTearDown(controller.dispose);
        await pumpShell(tester, controller, size: const Size(390, 844));
        if (screen != 'player') {
          await tester.enterText(
            find.byType(TextField).first,
            'Unsaved sentinel',
          );
          await tester.pump();
        }
        final l10n = l10nOf(tester);
        await openActionMenu(tester, screen);
        final delete = find.widgetWithText(
          PopupMenuItem<String>,
          l10n.actionDelete,
        );
        await tester.ensureVisible(delete);
        await tester.tap(delete);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(controller.deletedSongs, isEmpty);
        expect(controller.deletedSetlists, isEmpty);
        await tester.tap(find.text(l10n.actionCancel));
        await tester.pumpAndSettle();
        if (screen != 'player') {
          expect(
            tester
                .widget<TextField>(find.byType(TextField).first)
                .controller!
                .text,
            'Unsaved sentinel',
          );
        }
        expect(controller.deletedSongs, isEmpty);
        expect(controller.deletedSetlists, isEmpty);
        await openActionMenu(tester, screen);
        final again = find.widgetWithText(
          PopupMenuItem<String>,
          l10n.actionDelete,
        );
        await tester.ensureVisible(again);
        await tester.tap(again);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, l10n.actionDelete));
        await tester.pumpAndSettle();
        expect(
          screen == 'setlist-edit'
              ? controller.deletedSetlists
              : controller.deletedSongs,
          [screen == 'setlist-edit' ? menuSetlist.id : menuSong.id],
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('an unsaved editor draft has no persistent Delete action', (
    tester,
  ) async {
    final controller = MenuController('editor', draft: true);
    addTearDown(controller.dispose);
    await pumpShell(tester, controller);
    final l10n = l10nOf(tester);
    expect(find.byTooltip(l10n.songMenuLabel), findsNothing);
    expect(find.byTooltip(l10n.actionSave), findsOneWidget);
  });
}
