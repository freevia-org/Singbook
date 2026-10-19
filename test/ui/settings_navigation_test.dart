import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/settings/settings_screen.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

Finder menu(String section) => find.byKey(ValueKey('settings-menu-$section'));

Future<void> open(WidgetTester tester, String section) async {
  await tester.ensureVisible(menu(section));
  await tester.pumpAndSettle();
  await tester.tap(menu(section));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Settings is a compact menu and native Back returns to it', (
    tester,
  ) async {
    final c = FakeUiController(
      (_) => const VerseUiState(activeTab: VerseTab.settings),
    );
    addTearDown(c.dispose);
    await pumpShell(tester, c);
    final l10n = l10nOf(tester);
    expect(find.byType(ListTile), findsNWidgets(5));
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text(l10n.settingsClearHistory), findsNothing);
    for (final section in ['appearance', 'player', 'sources', 'account']) {
      await open(tester, section);
      expect(find.byType(BackButton), findsOneWidget);
      expect(menu(section), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(menu(section), findsOneWidget);
      expect(c.calls, isNot(contains('setTab')));
    }
  });

  testWidgets(
    'account groups sync, backup/restore and confirmed clear history',
    (tester) async {
      final c = FakeUiController(
        (_) =>
            const VerseUiState(activeTab: VerseTab.settings, syncReady: true),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SettingsScreen(
              controller: c,
              backupSection: const Card(
                child: ListTile(
                  key: ValueKey('backup-controls'),
                  title: Text('Local backup fixture'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      expect(find.byKey(const ValueKey('backup-controls')), findsNothing);
      await open(tester, 'account');
      expect(find.byKey(const ValueKey('account-sign-in')), findsOneWidget);
      expect(find.byKey(const ValueKey('backup-controls')), findsOneWidget);
      final clear = find.byKey(const ValueKey('settings-clear-history'));
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsClearHistoryConfirm), findsOneWidget);
      await tester.tap(find.text(l10n.actionCancel));
      await tester.pumpAndSettle();
      expect(c.calls, isNot(contains('clearHistory')));
      await tester.tap(clear);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.actionClear));
      await tester.pumpAndSettle();
      expect(c.calls.where((call) => call == 'clearHistory'), hasLength(1));
    },
  );

  testWidgets('cloud entry opens account directly and consumes once', (
    tester,
  ) async {
    final c = FakeUiController(
      (_) => const VerseUiState(activeTab: VerseTab.settings, syncReady: true),
    );
    addTearDown(c.dispose);
    var consumed = 0;
    await pumpShell(
      tester,
      c,
      syncFocusRequest: 1,
      onSyncFocusConsumed: () => consumed++,
    );
    expect(find.byKey(const ValueKey('account-sign-in')), findsOneWidget);
    expect(consumed, 1);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(menu('account'), findsOneWidget);
    expect(consumed, 1);
  });

  testWidgets('open account updates and follows navigation to the library', (
    tester,
  ) async {
    var state = const VerseUiState(
      activeTab: VerseTab.settings,
      syncReady: true,
    );
    final c = FakeUiController((_) => state);
    addTearDown(c.dispose);
    await pumpShell(tester, c);
    await open(tester, 'account');
    state = const VerseUiState(
      activeTab: VerseTab.settings,
      syncReady: true,
      syncSignedIn: true,
      accountName: 'User',
    );
    c.refresh();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-sign-in')), findsNothing);
    expect(find.byKey(const ValueKey('account-sync-now')), findsOneWidget);
    state = const VerseUiState(activeTab: VerseTab.songs);
    c.refresh();
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);
    expect(find.byKey(const ValueKey('account-sync-now')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('en'),
    const Locale('uk'),
    const Locale('ar'),
  ]) {
    testWidgets('section menus and Back fit $locale at large text', (
      tester,
    ) async {
      final c = FakeUiController(
        (_) => const VerseUiState(activeTab: VerseTab.settings),
      );
      addTearDown(c.dispose);
      await pumpShell(
        tester,
        c,
        locale: locale,
        textScale: 2,
        size: const Size(320, 640),
      );
      await open(tester, 'account');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(menu('appearance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
