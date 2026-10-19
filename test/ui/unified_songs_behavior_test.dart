import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/adaptive_bottom_navigation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_controller.dart';

const _candidate = SongCandidate(
  providerId: 'genius',
  id: 'original-fixture',
  title: 'Original Lantern Song',
  artist: 'Original Test Artist',
);

/// Records the actual AppController search boundary without any transport.
class _CountingDiscovery extends SourceDiscoveryService {
  _CountingDiscovery() : super(const []);

  final searches = <String>[];
  Completer<List<SongCandidate>>? pending;

  @override
  Future<List<SongCandidate>> search(
    String query, {
    String providerId = 'genius',
    CancellationToken? cancel,
  }) async {
    searches.add(query);
    if (pending != null) return pending!.future;
    return const [_candidate];
  }
}

Future<void> _drainSearch() => Future<void>.delayed(Duration.zero);

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late AppController app;
  late AppControllerAdapter ui;
  late _CountingDiscovery discovery;

  Future<void> start() async {
    discovery = _CountingDiscovery();
    app = AppController(repository: repository, discovery: discovery);
    ui = AppControllerAdapter(app);
    await ui.initialize();
  }

  Future<void> restart() async {
    // Flush the durable settings boundary before simulating a fresh app.
    await repository.getSetting('app');
    ui.dispose();
    app.dispose();
    await start();
  }

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    await start();
  });

  tearDown(() async {
    await repository.getSetting('app');
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  for (final mode in [
    HomeListMode.recent,
    HomeListMode.library,
    HomeListMode.favorites,
  ]) {
    test('typing and submitting in ${mode.name} stays local', () async {
      ui.setHomeListMode(mode);
      ui.setQuery('Original Lantern');
      await ui.submitSearch();
      // Longer than the Online debounce: catches an accidentally armed timer.
      await Future<void>.delayed(const Duration(milliseconds: 450));

      expect(ui.state.homeListMode, mode);
      expect(ui.state.query, 'Original Lantern');
      expect(discovery.searches, isEmpty);
      expect(app.query, isEmpty);
      expect(app.searching, isFalse);
    });
  }

  test(
    'explicit Online transition searches the shared local query once',
    () async {
      ui.setHomeListMode(HomeListMode.library);
      ui.setQuery('Original Lantern');
      expect(discovery.searches, isEmpty);

      ui.setHomeListMode(HomeListMode.online);
      await _drainSearch();

      expect(ui.state.homeListMode, HomeListMode.online);
      expect(discovery.searches, ['Original Lantern']);
      expect(ui.state.autocomplete.single.id, _candidate.identity);

      ui.setHomeListMode(HomeListMode.online);
      ui.setHomeListMode(HomeListMode.recent);
      ui.setHomeListMode(HomeListMode.online);
      await _drainSearch();
      expect(discovery.searches, ['Original Lantern']);
    },
  );

  test(
    'Online submit explicitly refreshes while returning to its view does not',
    () async {
      ui.setHomeListMode(HomeListMode.online);
      ui.setQuery('Original Lantern');
      await ui.submitSearch();
      expect(discovery.searches, ['Original Lantern']);

      ui.setHomeListMode(HomeListMode.favorites);
      ui.setHomeListMode(HomeListMode.online);
      await _drainSearch();
      expect(discovery.searches, hasLength(1));

      await ui.submitSearch();
      expect(discovery.searches, ['Original Lantern', 'Original Lantern']);
    },
  );

  test(
    'returning to an in-flight Online search does not duplicate it',
    () async {
      final pending = Completer<List<SongCandidate>>();
      discovery.pending = pending;
      ui.setQuery('Original Lantern');
      ui.setHomeListMode(HomeListMode.online);
      expect(discovery.searches, ['Original Lantern']);

      ui.setHomeListMode(HomeListMode.library);
      ui.setHomeListMode(HomeListMode.online);
      expect(discovery.searches, hasLength(1));

      pending.complete(const [_candidate]);
      await _drainSearch();
      expect(ui.state.autocomplete.single.id, _candidate.identity);
      expect(app.searching, isFalse);
    },
  );

  test(
    'leaving Online cancels its pending debounce without losing the query',
    () async {
      ui.setHomeListMode(HomeListMode.online);
      ui.setQuery('Original Lantern');
      ui.setHomeListMode(HomeListMode.library);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(discovery.searches, isEmpty);
      expect(ui.state.query, 'Original Lantern');

      ui.setHomeListMode(HomeListMode.online);
      await _drainSearch();
      expect(discovery.searches, ['Original Lantern']);
    },
  );

  test(
    'Recent is the default despite legacy last bottom-destination values',
    () async {
      await app.setSetting('defaultView', 'settings');
      await restart();

      expect(ui.state.activeTab, VerseTab.home);
      expect(ui.state.homeListMode, HomeListMode.recent);
      expect(ui.state.startupSongsView, 'recent');
      expect(discovery.searches, isEmpty);
    },
  );

  for (final mode in HomeListMode.values) {
    test(
      'explicit startup ${mode.name} survives reopening independently of navigation',
      () async {
        await ui.setStartupSongsView(mode.name);
        ui.setHomeListMode(HomeListMode.favorites);
        ui.setTab(VerseTab.settings);
        await restart();

        expect(ui.state.activeTab, VerseTab.home);
        expect(ui.state.homeListMode, mode);
        expect(ui.state.startupSongsView, mode.name);
        expect(discovery.searches, isEmpty);
      },
    );

    test(
      'Last opened restores ${mode.name} after a fresh adapter and controller',
      () async {
        await ui.setStartupSongsView('last');
        ui.setHomeListMode(mode);
        ui.setTab(VerseTab.setlists);
        final saved = await repository.getSetting('app') as Map;
        expect(saved['lastSongsView'], mode.name);

        await restart();
        expect(ui.state.activeTab, VerseTab.home);
        expect(ui.state.homeListMode, mode);
        expect(ui.state.startupSongsView, 'last');
        expect(discovery.searches, isEmpty);
      },
    );
  }

  test(
    'invalid startup or last-view preferences fall back to Recent',
    () async {
      await app.setSetting('startupSongsView', 'not-a-view');
      await restart();
      expect(ui.state.startupSongsView, 'recent');
      expect(ui.state.homeListMode, HomeListMode.recent);

      await app.setSetting('startupSongsView', 'last');
      await app.setSetting('lastSongsView', 'settings');
      await restart();
      expect(ui.state.startupSongsView, 'last');
      expect(ui.state.homeListMode, HomeListMode.recent);
    },
  );

  test(
    'legacy Songs route opens Library and conflict review clears unrelated search',
    () async {
      ui.setQuery('Unrelated catalog query');
      ui.setTab(VerseTab.songs);
      expect(ui.state.activeTab, VerseTab.home);
      expect(ui.state.homeListMode, HomeListMode.library);

      ui.reviewSyncConflicts();
      expect(ui.state.activeTab, VerseTab.home);
      expect(ui.state.homeListMode, HomeListMode.library);
      expect(ui.state.songsConflictFilter, isTrue);
      expect(ui.state.query, isEmpty);
      expect(discovery.searches, isEmpty);
    },
  );

  for (final scenario in [
    ('phone', const Size(360, 780), 1.0, const Locale('en')),
    ('large-text phone', const Size(320, 780), 2.0, const Locale('en')),
    (
      'large-text Bulgarian phone',
      const Size(320, 780),
      2.0,
      const Locale('bg'),
    ),
    ('RTL phone', const Size(360, 780), 1.6, const Locale('ar')),
  ]) {
    testWidgets('three visible destinations remain usable on ${scenario.$1}', (
      tester,
    ) async {
      await pumpShell(
        tester,
        ui,
        size: scenario.$2,
        textScale: scenario.$3,
        locale: scenario.$4,
      );
      final l10n = l10nOf(tester);
      final navigation = find.byType(AdaptiveBottomNavigation);
      final widget = tester.widget<AdaptiveBottomNavigation>(navigation);
      expect(widget.labels, [
        l10n.navSongs,
        l10n.navSetlists,
        l10n.navSettings,
      ]);
      expect(widget.icons, hasLength(3));
      expect(widget.selectedIndex, 0);
      expect(find.text(l10n.navHome), findsNothing);
      expect(tester.takeException(), isNull);
      if (find
          .byKey(const ValueKey('two-row-navigation'))
          .evaluate()
          .isNotEmpty) {
        for (var index = 0; index < 3; index++) {
          expect(
            find.byKey(ValueKey('navigation-tile-$index')),
            findsOneWidget,
          );
        }
        expect(find.byKey(const ValueKey('navigation-tile-3')), findsNothing);
      }

      await tester.tap(
        find.descendant(of: navigation, matching: find.text(l10n.navSetlists)),
      );
      await tester.pumpAndSettle();
      expect(ui.state.activeTab, VerseTab.setlists);

      await tester.tap(
        find.descendant(of: navigation, matching: find.text(l10n.navSettings)),
      );
      await tester.pumpAndSettle();
      expect(ui.state.activeTab, VerseTab.settings);

      await tester.tap(
        find.descendant(of: navigation, matching: find.text(l10n.navSongs)),
      );
      await tester.pumpAndSettle();
      expect(ui.state.activeTab, VerseTab.home);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tablet rail also has exactly Songs, Setlists and Settings', (
    tester,
  ) async {
    await pumpShell(tester, ui, size: const Size(900, 1200));
    final l10n = l10nOf(tester);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(3));
    expect(
      rail.destinations.map((destination) => (destination.label as Text).data),
      [l10n.navSongs, l10n.navSetlists, l10n.navSettings],
    );
    expect(find.byType(AdaptiveBottomNavigation), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
