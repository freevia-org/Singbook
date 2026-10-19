import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_controller.dart';

void main() {
  testWidgets('Recent and Library intersect Favorites with the query', (
    tester,
  ) async {
    final time = DateTime(2026, 10, 20);
    final recents = [
      RecentItemData(
        id: 'amber-favorite',
        title: 'Amber Song',
        artist: 'North',
        occurredAt: time,
        favorite: true,
        isSetlist: false,
      ),
      RecentItemData(
        id: 'amber-other',
        title: 'Amber Ballad',
        artist: 'South',
        occurredAt: time.subtract(const Duration(days: 1)),
        favorite: false,
        isSetlist: false,
      ),
      RecentItemData(
        id: 'blue-favorite',
        title: 'Blue Song',
        artist: 'North',
        occurredAt: time.subtract(const Duration(days: 2)),
        favorite: true,
        isSetlist: false,
      ),
    ];
    final songs = [
      const SongCardData(
        id: 'amber-favorite',
        title: 'Amber Song',
        artist: 'North',
        favorite: true,
      ),
      const SongCardData(
        id: 'amber-other',
        title: 'Amber Ballad',
        artist: 'South',
      ),
      const SongCardData(
        id: 'blue-favorite',
        title: 'Blue Song',
        artist: 'North',
        favorite: true,
      ),
    ];

    Future<FakeUiController> show(HomeListMode mode) async {
      final controller = FakeUiController(
        (_) => VerseUiState(
          homeListMode: mode,
          favoritesOnly: true,
          query: 'Amber',
          recent: recents,
          songs: songs,
        ),
      );
      await pumpShell(tester, controller, size: const Size(360, 780));
      return controller;
    }

    var controller = await show(HomeListMode.recent);
    expect(
      find.byKey(const ValueKey('recent-row-amber-favorite')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('recent-row-amber-other')), findsNothing);
    expect(
      find.byKey(const ValueKey('recent-row-blue-favorite')),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();

    controller = await show(HomeListMode.library);
    expect(find.text('Amber Song'), findsOneWidget);
    expect(find.text('Amber Ballad'), findsNothing);
    expect(find.text('Blue Song'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets(
    'three tabs fit a 320dp English phone without horizontal scrolling',
    (tester) async {
      final controller = FakeUiController(
        (_) => const VerseUiState(homeListMode: HomeListMode.recent),
      );
      addTearDown(controller.dispose);

      await pumpShell(tester, controller, size: const Size(320, 780));

      expect(find.byKey(const ValueKey('home-mode-recent')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-mode-library')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-mode-online')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-mode-favorites')), findsNothing);
      expect(find.byKey(const ValueKey('home-mode-scroll')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Favorites startup and legacy lastFavorites restore as Library filter',
    () async {
      sqfliteFfiInit();
      final repository = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      AppController? app;
      AppControllerAdapter? ui;

      Future<void> start() async {
        app = AppController(
          repository: repository,
          discovery: SourceDiscoveryService(const []),
        );
        ui = AppControllerAdapter(app!);
        await ui!.initialize();
      }

      try {
        await start();
        await ui!.setStartupSongsView('favorites');
        ui!.dispose();
        app!.dispose();
        await start();
        expect(ui!.state.homeListMode, HomeListMode.library);
        expect(ui!.state.favoritesOnly, isTrue);

        await ui!.setStartupSongsView('last');
        ui!.setHomeListMode(HomeListMode.recent);
        expect(ui!.state.favoritesOnly, isTrue);
        await repository.getSetting('app');
        ui!.dispose();
        app!.dispose();
        await start();
        expect(ui!.state.homeListMode, HomeListMode.recent);
        expect(ui!.state.favoritesOnly, isTrue);

        await ui!.setStartupSongsView('recent');
        ui!.dispose();
        app!.dispose();
        await start();
        expect(ui!.state.homeListMode, HomeListMode.recent);
        expect(ui!.state.favoritesOnly, isFalse);

        await ui!.setStartupSongsView('last');
        await app!.setSetting('lastSongsView', 'favorites');
        ui!.dispose();
        app!.dispose();
        await start();
        expect(ui!.state.homeListMode, HomeListMode.library);
        expect(ui!.state.favoritesOnly, isTrue);
      } finally {
        ui?.dispose();
        app?.dispose();
        await repository.close();
      }
    },
  );
}
