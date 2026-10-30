import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/sync_provider.dart';
import 'package:singbook/ui/account_avatar.dart';
import 'support/fake_controller.dart';
import 'package:singbook/ui/verse_ui_state.dart';

Future<void> _withPlatform(
  TargetPlatform platform,
  Future<void> Function() action,
) async {
  final previous = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = platform;
  try {
    await action();
  } finally {
    debugDefaultTargetPlatformOverride = previous;
  }
}

void main() {
  group('main header actions', () {
    testWidgets('home has no clear-history action and settings keeps it', (
      tester,
    ) async {
      var state = VerseUiState(
        recent: [
          RecentItemData(
            id: 'recent-song',
            title: 'Recent song',
            artist: 'Artist',
            occurredAt: DateTime(2026),
            isSetlist: false,
          ),
        ],
      );
      final controller = FakeUiController((_) => state);
      addTearDown(controller.dispose);
      await pumpShell(tester, controller);
      final l10n = l10nOf(tester);

      expect(find.text(l10n.homeHistoryClear), findsNothing);
      expect(find.text('Recent song'), findsOneWidget);

      state = VerseUiState(activeTab: VerseTab.settings);
      controller.refresh();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-menu-account')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-account')));
      await tester.pumpAndSettle();
      final settingsList = find.byType(ListView);
      expect(settingsList, findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(l10n.settingsClearHistory),
        200,
        scrollable: find
            .descendant(
              of: find.byType(Scaffold),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text(l10n.settingsClearHistory), findsOneWidget);
    });

    group('Songs import from Google Drive', () {
      Future<FakeUiController> pumpSongs(
        WidgetTester tester,
        VerseUiState state,
      ) async {
        final controller = FakeUiController((_) => state);
        addTearDown(controller.dispose);
        await pumpShell(tester, controller);
        await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
        await tester.pumpAndSettle();
        return controller;
      }

      const connected = VerseUiState(
        activeTab: VerseTab.songs,
        syncSignedIn: true,
        syncDriveFolderName: 'Singbook Library',
      );

      testWidgets(
        'is offered next to the file import and runs the Drive import',
        (tester) async {
          await _withPlatform(TargetPlatform.iOS, () async {
            final controller = await pumpSongs(tester, connected);
            final l10n = l10nOf(tester);
            expect(find.text(l10n.settingsImportChordPro), findsOneWidget);
            expect(find.text(l10n.accountImportChordPro), findsOneWidget);
            await tester.tap(find.byKey(const ValueKey('header-import-drive')));
            await tester.pumpAndSettle();
            expect(controller.calls, contains('importChordProFromDrive'));
            expect(controller.calls, isNot(contains('importChordPro')));
          });
        },
      );

      for (final entry in {
        'signed out': const VerseUiState(
          activeTab: VerseTab.songs,
          syncDriveFolderName: 'Singbook Library',
        ),
        'no visible folder': const VerseUiState(
          activeTab: VerseTab.songs,
          syncSignedIn: true,
        ),
        'iCloud': const VerseUiState(
          activeTab: VerseTab.songs,
          syncProvider: SyncProvider.iCloud,
          syncSignedIn: true,
          syncDriveFolderName: 'Singbook Library',
        ),
        'setlists tab': const VerseUiState(
          activeTab: VerseTab.setlists,
          syncSignedIn: true,
          syncDriveFolderName: 'Singbook Library',
        ),
      }.entries) {
        testWidgets('is hidden when ${entry.key}', (tester) async {
          await _withPlatform(TargetPlatform.iOS, () async {
            await pumpSongs(tester, entry.value);
            expect(
              find.byKey(const ValueKey('header-import-drive')),
              findsNothing,
            );
          });
        });
      }

      testWidgets('is hidden on platforms without the in-app Picker', (
        tester,
      ) async {
        await _withPlatform(TargetPlatform.windows, () async {
          await pumpSongs(tester, connected);
          expect(
            find.byKey(const ValueKey('header-import-drive')),
            findsNothing,
          );
        });
      });
    });

    testWidgets('song and setlist overflow entries call their actions', (
      tester,
    ) async {
      var state = const VerseUiState(activeTab: VerseTab.songs);
      final controller = FakeUiController((_) => state);
      addTearDown(controller.dispose);
      await pumpShell(tester, controller);
      final l10n = l10nOf(tester);

      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(PopupMenuItem<String>),
          matching: find.text(l10n.menuTypeNewSong),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.calls, contains('createSong'));

      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.settingsImportChordPro));
      await tester.pumpAndSettle();
      expect(controller.calls, contains('importChordPro'));
      final songsMenuLeft = tester
          .getRect(find.byKey(const ValueKey('header-overflow-menu')))
          .left;
      final songsCloudRight = tester
          .getRect(find.byKey(const ValueKey('cloud-button')))
          .right;

      state = const VerseUiState(activeTab: VerseTab.setlists);
      controller.refresh();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('add-header-button')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.setlistCreate), findsNWidgets(2));
      await tester.tap(find.text(l10n.setlistCreate).last);
      await tester.pumpAndSettle();
      expect(
        controller.calls,
        contains('createSetlist(name: ${l10n.setlistCreate}, songId: null)'),
      );

      expect(
        tester.getRect(find.byKey(const ValueKey('header-overflow-menu'))).left,
        songsMenuLeft,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('cloud-button'))).right,
        songsCloudRight,
      );
      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await tester.pumpAndSettle();
      final importSetlistLabel = '${l10n.settingsImportSetlist} (.osts)';
      expect(find.text(importSetlistLabel), findsOneWidget);
      await tester.tap(find.text(importSetlistLabel));
      await tester.pumpAndSettle();
      expect(controller.calls, contains('importSetlist'));
    });

    testWidgets(
      'signed-in account button uses the account photo in the same spot',
      (tester) async {
        var state = const VerseUiState(
          syncReady: true,
          syncSignedIn: true,
          accountPhotoUrl: 'https://example.test/avatar.jpg',
        );
        final controller = FakeUiController((_) => state);
        addTearDown(controller.dispose);
        await pumpShell(tester, controller);

        final button = find.byKey(const ValueKey('cloud-button'));
        final avatar = find.descendant(
          of: button,
          matching: find.byType(AccountAvatar),
        );
        expect(avatar, findsOneWidget);
        expect(
          tester.widget<AccountAvatar>(avatar).photoUrl,
          state.accountPhotoUrl,
        );
        expect(tester.widget<AccountAvatar>(avatar).size, 32);
        final homeRight = tester.getRect(button).right;

        for (final tab in [VerseTab.songs, VerseTab.setlists]) {
          state = VerseUiState(
            activeTab: tab,
            syncReady: true,
            syncSignedIn: true,
            accountPhotoUrl: 'https://example.test/avatar.jpg',
          );
          controller.refresh();
          await tester.pumpAndSettle();
          expect(tester.getRect(button).right, homeRight);
        }
      },
    );
  });

  testWidgets('About exposes webpage details and accessible resource links', (
    tester,
  ) async {
    final controller = FakeUiController(
      (_) => const VerseUiState(activeTab: VerseTab.settings),
    );
    addTearDown(controller.dispose);
    await pumpShell(tester, controller);
    final l10n = l10nOf(tester);

    final support = find.byKey(const ValueKey('settings-menu-support'));
    expect(support, findsOneWidget);
    expect(tester.widget<ListTile>(support).title, isA<Text>());
    expect(tester.widget<ListTile>(support).onTap, isNotNull);
    expect(
      find.descendant(of: support, matching: find.text(l10n.aboutSupport)),
      findsOneWidget,
    );
    final aboutTile = find.widgetWithText(ListTile, l10n.settingsAbout);
    final settingsList = find.byType(ListView);
    expect(settingsList, findsOneWidget);
    await tester.scrollUntilVisible(
      find.descendant(of: aboutTile, matching: find.text(l10n.settingsAbout)),
      200,
      scrollable: find
          .descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(aboutTile);
    await tester.pumpAndSettle();
    await tester.tap(aboutTile);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(l10n.aboutDetails), findsOneWidget);
    expect(find.widgetWithText(TextButton, l10n.aboutSupport), findsNothing);
    for (final label in [
      l10n.aboutWebsite,
      l10n.aboutSourceCode,
      l10n.settingsPrivacy,
      l10n.aboutPublisher,
    ]) {
      final link = find.widgetWithText(TextButton, label);
      expect(link, findsOneWidget);
      expect(tester.widget<TextButton>(link).onPressed, isNotNull);
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      final semantics = tester.getSemantics(link).getSemanticsData();
      expect(semantics.label, label);
      expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    }
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-menu-about')), findsOneWidget);
  });
}
