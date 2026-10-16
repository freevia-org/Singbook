import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_controller.dart';
import 'package:singbook/ui/verse_ui_state.dart';

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
      await tester.scrollUntilVisible(
        find.text(l10n.settingsClearHistory),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l10n.settingsClearHistory), findsOneWidget);
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
      await tester.tap(find.text(l10n.menuTypeNewSong));
      await tester.pumpAndSettle();
      expect(controller.calls, contains('createSong'));

      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.settingsImportChordPro));
      await tester.pumpAndSettle();
      expect(controller.calls, contains('importChordPro'));

      state = const VerseUiState(activeTab: VerseTab.setlists);
      controller.refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('header-overflow-menu')));
      await tester.pumpAndSettle();
      final importSetlistLabel = '${l10n.settingsImportSetlist} (.osts)';
      expect(find.text(importSetlistLabel), findsOneWidget);
      await tester.tap(find.text(importSetlistLabel));
      await tester.pumpAndSettle();
      expect(controller.calls, contains('importSetlist'));
    });

    testWidgets(
      'signed-in account button uses a person icon in the same spot',
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
        expect(
          find.descendant(
            of: button,
            matching: find.byIcon(Icons.person_outline_rounded),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: button, matching: find.byType(Image)),
          findsNothing,
        );
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

  testWidgets(
    'About exposes readable details and tappable privacy/support links',
    (tester) async {
      final controller = FakeUiController(
        (_) => const VerseUiState(activeTab: VerseTab.settings),
      );
      addTearDown(controller.dispose);
      await pumpShell(tester, controller);
      final l10n = l10nOf(tester);

      final aboutTile = find.widgetWithText(ListTile, l10n.settingsAbout);
      await tester.scrollUntilVisible(
        aboutTile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(aboutTile);
      await tester.pumpAndSettle();

      expect(find.text(l10n.aboutDetails), findsOneWidget);
      for (final label in [l10n.settingsPrivacy, l10n.aboutSupport]) {
        final link = find.widgetWithText(TextButton, label);
        expect(link, findsOneWidget);
        expect(tester.widget<TextButton>(link).onPressed, isNotNull);
        final semantics = tester.getSemantics(link).getSemanticsData();
        expect(semantics.label, label);
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
      }
    },
  );
}
