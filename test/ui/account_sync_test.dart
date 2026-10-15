import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verse_mobile/l10n/generated/app_localizations.dart';
import 'package:verse_mobile/l10n/generated/app_localizations_bg.dart';
import 'package:verse_mobile/l10n/generated/app_localizations_en.dart';
import 'package:verse_mobile/l10n/generated/app_localizations_uk.dart';
import 'package:verse_mobile/ui/localized_labels.dart';
import 'package:verse_mobile/ui/theme/verse_theme.dart';
import 'package:verse_mobile/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';
import 'theme_contrast_test.dart' show contrastRatio;

/// Every machine code the engine can report, plus one it cannot.
const _codes = [
  'not_configured',
  'not_signed_in',
  'authorization_required',
  'access_denied',
  'rate_limited',
  'storage_full',
  'network',
  'account_changed',
  'remote_library_too_large',
  'sign_in_failed',
  'sync_failed',
  'something_new_and_unknown',
];

VerseUiState _account({
  VerseTab tab = VerseTab.settings,
  bool ready = true,
  bool signedIn = true,
  bool busy = false,
  String? name = 'sam@example.com',
  DateTime? syncedAt,
  int conflicts = 0,
  String? error,
  String? rawError,
  bool autoSync = true,
  bool songsConflictFilter = false,
  List<SongCardData> songs = const [],
}) => VerseUiState(
  activeTab: tab,
  syncReady: ready,
  syncSignedIn: signedIn,
  syncBusy: busy,
  accountName: name,
  accountError: rawError,
  lastSyncAt: syncedAt,
  lastSyncConflicts: conflicts,
  lastSyncErrorCode: error,
  autoSyncEnabled: autoSync,
  songsConflictFilter: songsConflictFilter,
  songs: songs,
);

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<FakeUiController> _pump(
  WidgetTester tester,
  VerseUiState Function() state, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = const Size(360, 780),
  bool focusAccount = true,
}) async {
  final busy = state().syncBusy;
  final c = FakeUiController((_) => state());
  addTearDown(c.dispose);
  await pumpShell(
    tester,
    c,
    locale: locale,
    textScale: textScale,
    size: size,
    syncFocusRequest: focusAccount ? 1 : 0,
    settle: !busy,
  );
  return c;
}

void main() {
  group('Account states', () {
    testWidgets('not configured explains what is needed', (tester) async {
      await _pump(tester, () => _account(ready: false, signedIn: false));
      final l10n = l10nOf(tester);
      expect(find.text(l10n.accountUnavailableTitle), findsOneWidget);
      expect(find.text(l10n.accountUnavailable), findsOneWidget);
      expect(find.byKey(const ValueKey('account-sign-in')), findsNothing);
      expect(find.byKey(const ValueKey('account-sync-now')), findsNothing);
    });

    testWidgets('signed out shows the benefits and signs in', (tester) async {
      final c = await _pump(tester, () => _account(signedIn: false));
      final l10n = l10nOf(tester);
      expect(find.text(l10n.accountSignedOutBenefits), findsOneWidget);
      expect(find.text(l10n.accountSignInWithGoogle), findsOneWidget);
      await _tapKey(tester, 'account-sign-in');
      expect(c.calls, contains('signInForSync'));
    });

    testWidgets('signing in shows progress and cannot be repeated', (
      tester,
    ) async {
      final c = await _pump(tester, () => _account(signedIn: false, busy: true));
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('account-sign-in')),
      );
      expect(button.onPressed, isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('account-sign-in')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(c.calls, isNot(contains('signInForSync')));
    });

    testWidgets('a sign-in failure is explained while signed out', (
      tester,
    ) async {
      await _pump(tester, () => _account(signedIn: false, error: 'sign_in_failed'));
      final l10n = l10nOf(tester);
      expect(find.text(l10n.syncErrorSignInFailed), findsOneWidget);
      expect(find.text(l10n.syncErrorSignInFailedHint), findsOneWidget);
    });

    testWidgets('signed in shows the account and that it never synced', (
      tester,
    ) async {
      await _pump(tester, () => _account());
      final l10n = l10nOf(tester);
      expect(find.text('sam@example.com'), findsOneWidget);
      expect(find.text(l10n.accountNeverSynced), findsOneWidget);
    });

    testWidgets('signed in shows a relative last-synced time', (tester) async {
      await _pump(
        tester,
        () => _account(
          syncedAt: DateTime.now().subtract(const Duration(minutes: 5, seconds: 3)),
        ),
      );
      expect(find.text('Synced 5 minutes ago'), findsOneWidget);
    });

    testWidgets('sync now runs the sync and is disabled while busy', (
      tester,
    ) async {
      var busy = false;
      final c = await _pump(tester, () => _account(busy: busy));
      final l10n = l10nOf(tester);
      await _tapKey(tester, 'account-sync-now');
      expect(c.calls.where((call) => call == 'syncNow'), hasLength(1));

      busy = true;
      c.refresh();
      await tester.pump();
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const ValueKey('account-sync-now')),
      );
      expect(button.onPressed, isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('account-sync-now')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.accountSyncing), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('account-sync-now')),
          warnIfMissed: false);
      expect(c.calls.where((call) => call == 'syncNow'), hasLength(1));
    });

    testWidgets('the auto-sync switch reports the new value', (tester) async {
      var auto = true;
      final c = await _pump(tester, () => _account(autoSync: auto));
      expect(
        tester.widget<SwitchListTile>(find.byKey(const ValueKey('account-auto-sync'))).value,
        isTrue,
      );
      await _tapKey(tester, 'account-auto-sync');
      expect(c.calls, contains('setAutoSync(false)'));
      auto = false;
      c.refresh();
      await tester.pump();
      await _tapKey(tester, 'account-auto-sync');
      expect(c.calls, contains('setAutoSync(true)'));
    });

    testWidgets('signing out asks first and keeps songs on the device', (
      tester,
    ) async {
      final c = await _pump(tester, () => _account());
      final l10n = l10nOf(tester);
      await _tapKey(tester, 'account-sign-out');
      expect(find.text(l10n.accountSignOutTitle), findsOneWidget);
      expect(find.text(l10n.accountSignOutBody), findsOneWidget);
      expect(c.calls, isNot(contains('signOutFromSync')));

      await tester.tap(find.text(l10n.actionCancel));
      await tester.pumpAndSettle();
      expect(c.calls, isNot(contains('signOutFromSync')));

      await _tapKey(tester, 'account-sign-out');
      await tester.tap(find.byKey(const ValueKey('account-sign-out-confirm')));
      await tester.pumpAndSettle();
      expect(c.calls, contains('signOutFromSync'));
    });

    testWidgets('using a different account signs out then in', (tester) async {
      final c = await _pump(tester, () => _account());
      await _tapKey(tester, 'account-use-different');
      expect(
        c.calls.where((call) => call.endsWith('ForSync') || call.startsWith('signOut')),
        ['signOutFromSync', 'signInForSync'],
      );
    });
  });

  group('Conflicts', () {
    final copy = const SongCardData(
      id: 'conflict-abc',
      title: 'Amazing Grace',
      isConflictCopy: true,
    );

    testWidgets('are counted, explained, and can be reviewed', (tester) async {
      final c = await _pump(tester, () => _account(conflicts: 2, songs: [copy]));
      final l10n = l10nOf(tester);
      expect(find.text(l10n.accountConflictsTitle(2)), findsOneWidget);
      expect(find.text(l10n.accountConflictsBody), findsOneWidget);
      await tester.tap(find.text(l10n.accountReviewConflicts));
      expect(c.calls, contains('reviewSyncConflicts'));
    });

    testWidgets('show only the count when no copy is in the library', (
      tester,
    ) async {
      await _pump(tester, () => _account(conflicts: 1));
      final l10n = l10nOf(tester);
      expect(find.text(l10n.accountConflictsTitle(1)), findsOneWidget);
      expect(find.text(l10n.accountReviewConflicts), findsNothing);
    });

    testWidgets('no conflicts means no notice', (tester) async {
      await _pump(tester, () => _account());
      expect(find.byKey(const ValueKey('account-conflicts')), findsNothing);
    });

    testWidgets('the songs list can be limited to conflict copies', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        () => _account(
          tab: VerseTab.songs,
          songsConflictFilter: true,
          songs: [
            copy,
            const SongCardData(id: 's1', title: 'Normal Song'),
          ],
        ),
        focusAccount: false,
      );
      final l10n = l10nOf(tester);
      expect(find.text(l10n.songsConflictFilterActive), findsOneWidget);
      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('Normal Song'), findsNothing);
      expect(find.textContaining(l10n.songsConflictBadge), findsOneWidget);
      await tester.tap(find.text(l10n.songsConflictFilterClear));
      expect(c.calls, contains('clearConflictFilter'));
    });

    testWidgets('an empty conflict filter says so', (tester) async {
      await _pump(
        tester,
        () => _account(
          tab: VerseTab.songs,
          songsConflictFilter: true,
          songs: const [SongCardData(id: 's1', title: 'Normal Song')],
        ),
        focusAccount: false,
      );
      expect(find.text(l10nOf(tester).songsConflictEmpty), findsOneWidget);
    });
  });

  group('Sync errors', () {
    for (final locale in const [Locale('en'), Locale('bg'), Locale('uk')]) {
      testWidgets('every code has a localized message in $locale', (
        tester,
      ) async {
        String? code;
        await _pump(tester, () => _account(error: code), locale: locale);
        final l10n = l10nOf(tester);
        final english = AppLocalizationsEn();
        final seen = <String>{};
        for (final value in _codes) {
          final text = syncErrorText(l10n, value);
          expect(text.message, isNotEmpty, reason: value);
          expect(text.hint, isNotEmpty, reason: value);
          expect(seen.add(text.message), value == 'something_new_and_unknown' ? isFalse : isTrue,
              reason: '$value has its own message');
          if (locale.languageCode != 'en') {
            final en = syncErrorText(english, value);
            expect(text.message, isNot(en.message), reason: '$value untranslated');
            expect(text.hint, isNot(en.hint), reason: '$value untranslated');
          }
        }
        // And each is what the Account section actually shows.
        final controller = FakeUiController((_) => _account(error: code));
        addTearDown(controller.dispose);
        for (final value in _codes) {
          code = value;
          await pumpShell(tester, controller, locale: locale, syncFocusRequest: 1);
          // account_changed also opens its dialog; leave it for its own test.
          if (value == 'account_changed') continue;
          final text = syncErrorText(l10n, value);
          expect(find.text(text.message), findsOneWidget, reason: value);
          expect(find.text(text.hint), findsOneWidget, reason: value);
        }
      });
    }

    testWidgets('raw exception text is never shown', (tester) async {
      await _pump(
        tester,
        () => _account(rawError: 'SocketException: secret host 10.0.0.1'),
      );
      expect(find.textContaining('SocketException'), findsNothing);
      expect(find.textContaining('10.0.0.1'), findsNothing);
      expect(find.text(l10nOf(tester).syncErrorGeneric), findsOneWidget);
    });

    testWidgets('sign-in errors offer to sign in again', (tester) async {
      for (final code in const [
        'authorization_required',
        'access_denied',
        'not_signed_in',
      ]) {
        final c = await _pump(tester, () => _account(error: code));
        await tester.tap(find.text(l10nOf(tester).accountSignInAgain));
        expect(c.calls, contains('signInForSync'), reason: code);
      }
    });

    testWidgets('transient errors offer to try again', (tester) async {
      for (final code in const [
        'network',
        'rate_limited',
        'storage_full',
        'remote_library_too_large',
        'sync_failed',
        'something_new_and_unknown',
      ]) {
        final c = await _pump(tester, () => _account(error: code));
        await tester.tap(find.text(l10nOf(tester).actionRetry));
        expect(c.calls, contains('syncNow'), reason: code);
      }
    });

    testWidgets('an unconfigured build offers no retry', (tester) async {
      await _pump(tester, () => _account(error: 'not_configured'));
      expect(find.text(l10nOf(tester).actionRetry), findsNothing);
    });

    testWidgets('the error clears while a new sync runs', (tester) async {
      await _pump(tester, () => _account(error: 'network', busy: true));
      expect(find.byKey(const ValueKey('account-error')), findsNothing);
    });
  });

  group('Account change', () {
    testWidgets('asks how to continue and applies each choice', (tester) async {
      var error = 'account_changed';
      final c = await _pump(
        tester,
        () => _account(error: error),
        focusAccount: false,
      );
      final l10n = l10nOf(tester);
      expect(find.byKey(const ValueKey('account-change-dialog')), findsOneWidget);
      expect(find.text(l10n.accountChangedTitle), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('account-change-merge')));
      await tester.pumpAndSettle();
      expect(c.calls, contains('adoptAccount(mergeLocal: true)'));
      expect(find.byKey(const ValueKey('account-change-dialog')), findsNothing);

      // The stop is unresolved: no nagging until it clears and returns.
      c.refresh();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('account-change-dialog')), findsNothing);

      error = 'network';
      c.refresh();
      await tester.pumpAndSettle();
      error = 'account_changed';
      c.refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-change-replace')));
      await tester.pumpAndSettle();
      expect(c.calls, contains('adoptAccount(mergeLocal: false)'));

      error = 'sync_failed';
      c.refresh();
      await tester.pumpAndSettle();
      error = 'account_changed';
      c.refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-change-sign-out')));
      await tester.pumpAndSettle();
      expect(c.calls, contains('signOutFromSync'));
    });

    testWidgets('can be reopened from the Account section', (tester) async {
      final c = await _pump(
        tester,
        () => _account(error: 'account_changed'),
      );
      await tester.tap(find.byKey(const ValueKey('account-change-sign-out')));
      await tester.pumpAndSettle();
      c.calls.clear();
      await tester.tap(find.text(l10nOf(tester).accountChooseAction));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('account-change-dialog')), findsOneWidget);
    });

    testWidgets('fits a narrow screen at large text', (tester) async {
      for (final locale in const [Locale('en'), Locale('bg'), Locale('uk')]) {
        await _pump(
          tester,
          () => _account(error: 'account_changed'),
          locale: locale,
          textScale: 2,
        );
        expect(tester.takeException(), isNull, reason: '$locale');
        for (final key in const [
          'account-change-merge',
          'account-change-replace',
          'account-change-sign-out',
        ]) {
          final finder = find.byKey(ValueKey(key));
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
        }
      }
    });
  });

  group('Header cloud button', () {
    Future<void> expectTooltip(
      WidgetTester tester,
      VerseUiState state,
      String Function(AppLocalizations) tooltip,
    ) async {
      await _pump(tester, () => state, focusAccount: false);
      final l10n = l10nOf(tester);
      expect(
        tester.widget<IconButton>(find.byKey(const ValueKey('cloud-button'))).tooltip,
        tooltip(l10n),
      );
      expect(find.byTooltip(tooltip(l10n)), findsOneWidget);
    }

    testWidgets('reflects each sync state', (tester) async {
      await expectTooltip(
        tester,
        _account(ready: false, signedIn: false),
        (l) => l.accountTitle,
      );
      await expectTooltip(
        tester,
        _account(signedIn: false),
        (l) => l.accountStatusSignedOut,
      );
      await expectTooltip(
        tester,
        _account(syncedAt: DateTime.now()),
        (l) => l.accountStatusSynced,
      );
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
      await expectTooltip(tester, _account(), (l) => l.accountStatusSignedIn);
      await expectTooltip(
        tester,
        _account(busy: true, syncedAt: DateTime.now()),
        (l) => l.accountStatusSyncing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('cloud-button')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await expectTooltip(
        tester,
        _account(error: 'network'),
        (l) => l.accountStatusError,
      );
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('is a 48dp target that opens the account section', (
      tester,
    ) async {
      final c = FakeUiController((_) => _account(tab: VerseTab.home));
      addTearDown(c.dispose);
      var opened = 0;
      await pumpShell(tester, c, onOpenSyncSettings: () => opened++);
      final size = tester.getSize(find.byKey(const ValueKey('cloud-button')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byKey(const ValueKey('cloud-button')));
      expect(opened, 1);
    });
  });

  group('App lifecycle', () {
    testWidgets('resuming tells the controller', (tester) async {
      final c = await _pump(tester, () => _account());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(c.calls, isNot(contains('onAppResumed')));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(c.calls.where((call) => call == 'onAppResumed'), hasLength(1));
    });

    testWidgets('the observer is removed with the shell', (tester) async {
      final c = await _pump(tester, () => _account());
      await tester.pumpWidget(const SizedBox());
      c.calls.clear();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(c.calls, isEmpty);
    });
  });

  group('Notices', () {
    const syncNotices = [
      UiNotice.syncSucceeded,
      UiNotice.syncFailed,
      UiNotice.syncConflictsFound,
      UiNotice.signedIn,
      UiNotice.signedOut,
    ];

    for (final locale in const [Locale('en'), Locale('bg'), Locale('uk')]) {
      testWidgets('are shown as snackbars in $locale', (tester) async {
        final c = FakeUiController((_) => _account());
        addTearDown(c.dispose);
        await pumpShell(tester, c, locale: locale);
        final l10n = l10nOf(tester);
        final texts = {
          UiNotice.syncSucceeded: l10n.accountSynced,
          UiNotice.syncFailed: l10n.accountSyncFailed,
          UiNotice.syncConflictsFound: l10n.accountNoticeConflicts,
          UiNotice.signedIn: l10n.accountNoticeSignedIn,
          UiNotice.signedOut: l10n.accountNoticeSignedOut,
        };
        for (final notice in syncNotices) {
          c.emit(notice);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.text(texts[notice]!), findsOneWidget, reason: '$notice');
        }
      });
    }
  });

  group('Last synced label', () {
    final now = DateTime(2026, 10, 15, 12);

    test('English', () {
      final l10n = AppLocalizationsEn();
      expect(lastSyncedLabel(l10n, null, now), 'Never synced');
      expect(lastSyncedLabel(l10n, now, now), 'Synced just now');
      expect(
        lastSyncedLabel(l10n, now.subtract(const Duration(minutes: 1)), now),
        'Synced 1 minute ago',
      );
      expect(
        lastSyncedLabel(l10n, now.subtract(const Duration(hours: 3)), now),
        'Synced 3 hours ago',
      );
      expect(
        lastSyncedLabel(l10n, now.subtract(const Duration(days: 2, hours: 5)), now),
        'Synced 2 days ago',
      );
    });

    test('Ukrainian uses the right plural forms', () {
      final l10n = AppLocalizationsUk();
      String at(Duration d) => lastSyncedLabel(l10n, now.subtract(d), now);
      expect(at(const Duration(minutes: 21)), 'Синхронізовано 21 хвилину тому');
      expect(at(const Duration(minutes: 22)), 'Синхронізовано 22 хвилини тому');
      expect(at(const Duration(minutes: 25)), 'Синхронізовано 25 хвилин тому');
      expect(at(const Duration(hours: 5)), 'Синхронізовано 5 годин тому');
      expect(at(const Duration(days: 2)), 'Синхронізовано 2 дні тому');
    });

    test('Bulgarian', () {
      final l10n = AppLocalizationsBg();
      expect(
        lastSyncedLabel(l10n, now.subtract(const Duration(minutes: 5)), now),
        'Синхронизирано преди 5 минути',
      );
    });
  });

  group('Layout at 2x text on a 360dp phone', () {
    final copy = const SongCardData(
      id: 'conflict-abc',
      title: 'Copy',
      isConflictCopy: true,
    );
    final states = <String, VerseUiState Function()>{
      'unavailable': () => _account(ready: false, signedIn: false),
      'signed out': () => _account(signedIn: false),
      'signed out, failed': () =>
          _account(signedIn: false, error: 'sign_in_failed'),
      'signing in': () => _account(signedIn: false, busy: true),
      'signed in': () => _account(syncedAt: DateTime.now()),
      'busy': () => _account(busy: true),
      'conflicts': () => _account(
        syncedAt: DateTime.now(),
        conflicts: 12,
        songs: [copy],
      ),
      'long name, error': () => _account(
        name: 'a.very.long.address.for.a.musician@subdomain.example-organisation.org',
        error: 'remote_library_too_large',
        conflicts: 3,
        songs: [copy],
      ),
    };

    for (final locale in const [Locale('en'), Locale('bg'), Locale('uk')]) {
      for (final entry in states.entries) {
        testWidgets('${entry.key} in $locale fits', (tester) async {
          await _pump(tester, entry.value, locale: locale, textScale: 2);
          expect(tester.takeException(), isNull);
          final card = find.byKey(const ValueKey('account-signed-in'));
          if (card.evaluate().isNotEmpty) {
            for (final key in const [
              'account-sync-now',
              'account-auto-sync',
              'account-use-different',
              'account-sign-out',
            ]) {
              final finder = find.byKey(ValueKey(key));
              await tester.ensureVisible(finder);
              await tester.pump(const Duration(milliseconds: 300));
              final rect = tester.getRect(finder);
              expect(rect.height, greaterThanOrEqualTo(48), reason: key);
              expect(rect.left, greaterThanOrEqualTo(0), reason: key);
              expect(rect.right, lessThanOrEqualTo(360), reason: key);
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('keeps the same layout on a tablet', (tester) async {
      await _pump(
        tester,
        () => _account(conflicts: 2, error: 'storage_full', songs: [copy]),
        size: const Size(900, 1200),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('account-error')), findsOneWidget);
    });
  });

  group('Contrast', () {
    test('callout text reaches 4.5:1 in every theme', () {
      for (final brightness in Brightness.values) {
        for (final palette in versePalettes) {
          final scheme = verseTheme(
            brightness: brightness,
            palette: palette.name,
          ).colorScheme;
          expect(
            contrastRatio(scheme.onErrorContainer, scheme.errorContainer),
            greaterThanOrEqualTo(4.5),
            reason: 'error ${palette.name} ${brightness.name}',
          );
          expect(
            contrastRatio(scheme.onTertiaryContainer, scheme.tertiaryContainer),
            greaterThanOrEqualTo(4.5),
            reason: 'conflict ${palette.name} ${brightness.name}',
          );
        }
      }
    });
  });
}
