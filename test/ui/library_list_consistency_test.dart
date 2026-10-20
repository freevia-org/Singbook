import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  testWidgets(
    'Songs and Setlists share Favorites and bottom create shortcuts',
    (tester) async {
      var state = const VerseUiState(
        activeTab: VerseTab.songs,
        homeListMode: HomeListMode.library,
        favoritesOnly: true,
        songs: [
          SongCardData(id: 'saved-song', title: 'Saved song', favorite: true),
          SongCardData(id: 'other-song', title: 'Other song'),
        ],
      );
      final controller = FakeUiController((_) => state);
      addTearDown(controller.dispose);

      await pumpShell(tester, controller);
      expect(find.text('Saved song'), findsOneWidget);
      expect(find.text('Other song'), findsNothing);
      expect(
        find.byKey(const ValueKey('favorites-filter-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('songs-create-shortcut')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('songs-create-shortcut')));
      await tester.pumpAndSettle();
      expect(controller.calls, contains('createSong'));

      state = const VerseUiState(
        activeTab: VerseTab.setlists,
        favoritesOnly: true,
        setlists: [
          SetlistCardData(
            id: 'saved-list',
            title: 'Saved rehearsal',
            favorite: true,
          ),
          SetlistCardData(id: 'other-list', title: 'Other rehearsal'),
        ],
      );
      controller.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Saved rehearsal'), findsOneWidget);
      expect(find.text('Other rehearsal'), findsNothing);
      expect(
        find.byKey(const ValueKey('favorites-filter-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('setlists-create-shortcut')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('setlists-create-shortcut')));
      await tester.pumpAndSettle();
      expect(
        controller.calls,
        contains('createSetlist(name: New setlist, songId: null)'),
      );
    },
  );

  testWidgets('Favorites remains visible in online Songs mode', (tester) async {
    final controller = FakeUiController(
      (_) => const VerseUiState(
        activeTab: VerseTab.home,
        homeListMode: HomeListMode.online,
      ),
    );
    addTearDown(controller.dispose);

    await pumpShell(tester, controller);

    expect(
      find.byKey(const ValueKey('favorites-filter-button')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(const ValueKey('favorites-filter-button')),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });
}
