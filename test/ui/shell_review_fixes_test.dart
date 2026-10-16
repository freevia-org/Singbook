import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/format.dart';
import 'package:singbook/ui/localized_labels.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:singbook/ui/widgets/verse_components.dart';

import 'support/fake_controller.dart';

VerseUiState _homeState() => VerseUiState(
  recent: [
    for (var day = 0; day < 12; day++)
      RecentItemData(
        id: 'song-$day',
        title: 'Song $day',
        artist: 'Artist',
        occurredAt: DateTime.now().subtract(Duration(days: day)),
        isSetlist: false,
      ),
  ],
);

void main() {
  group('locale resolution', () {
    final supported = AppLocalizations.supportedLocales;

    test('unsupported languages fall back to English, not the first locale', () {
      expect(supported.first.languageCode, 'ar');
      for (final code in ['sw', 'he', 'th', 'fa', 'bn']) {
        expect(resolveAppLocale(Locale(code), supported), const Locale('en'));
      }
      expect(resolveAppLocale(null, supported), const Locale('en'));
    });

    test('exact and language matches win', () {
      expect(resolveAppLocale(const Locale('mt'), supported).languageCode, 'mt');
      expect(
        resolveAppLocale(const Locale('de', 'CH'), supported).languageCode,
        'de',
      );
      expect(resolveAppLocale(const Locale('ar'), supported).languageCode, 'ar');
      expect(
        resolveAppLocale(const Locale('zh', 'TW'), supported).languageCode,
        'zh',
      );
    });

    testWidgets('a device in an unsupported language opens in English', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('sw')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final app = AppController(
        repository: _BrokenRepository(),
        discovery: SourceDiscoveryService(const []),
      );
      addTearDown(app.dispose);

      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();

      expect(find.text('Your library could not be opened.'), findsOneWidget);
      final context = tester.element(find.byType(Scaffold).first);
      expect(Directionality.of(context), TextDirection.ltr);
      expect(Localizations.localeOf(context), const Locale('en'));
    });

    testWidgets('an explicit app language wins over the device language', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('sw')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('mt'),
          localizationsDelegates: singbookLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: resolveAppLocale,
          home: const Scaffold(),
        ),
      );
      final context = tester.element(find.byType(Scaffold));
      expect(Localizations.localeOf(context).languageCode, 'mt');
    });
  });

  group('date formatting', () {
    test('a locale without date symbols falls back instead of throwing', () {
      expect(
        () => DateFormat.yMMMMd('mt').format(DateTime(2026, 3, 4)),
        throwsA(anything),
        reason: 'precondition: Maltese date data is not loaded',
      );
      final label = formatLocalizedDate(
        DateFormat.yMMMMd,
        DateTime(2026, 3, 4),
        'mt',
      );
      expect(label, contains('2026'));
      expect(
        formatLocalizedDate(DateFormat.MMMd, DateTime(2026, 3, 4), 'zz_ZZ'),
        isNotEmpty,
      );
    });

    testWidgets('Home renders history in every supported locale', (
      tester,
    ) async {
      for (final locale in AppLocalizations.supportedLocales) {
        final c = FakeUiController((_) => _homeState());
        addTearDown(c.dispose);
        await pumpShell(tester, c, locale: locale, textScale: 2);
        expect(tester.takeException(), isNull, reason: locale.toString());
        expect(find.text('Song 0'), findsWidgets, reason: locale.toString());
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('right-to-left layout', () {
    testWidgets('the day timeline and clear link follow the reading direction', (
      tester,
    ) async {
      Future<(double, double)> measure(Locale locale) async {
        final c = FakeUiController((_) => _homeState());
        addTearDown(c.dispose);
        await pumpShell(tester, c, locale: locale);
        final l10n = l10nOf(tester);
        final timeline = tester
            .getCenter(find.byKey(const ValueKey('recent-history-timeline')))
            .dx;
        final clear = tester.getCenter(find.text(l10n.homeHistoryClear)).dx;
        await tester.pumpWidget(const SizedBox.shrink());
        return (timeline, clear);
      }

      final (enTimeline, enClear) = await measure(const Locale('en'));
      expect(enTimeline, greaterThan(180));
      expect(enClear, greaterThan(180));
      final (arTimeline, arClear) = await measure(const Locale('ar'));
      expect(arTimeline, lessThan(180));
      expect(arClear, lessThan(180));
    });

    testWidgets('the app bar mark and wordmark start on the right in Arabic', (
      tester,
    ) async {
      final c = FakeUiController((_) => _homeState());
      addTearDown(c.dispose);
      await pumpShell(tester, c, locale: const Locale('ar'));
      final mark = tester.getRect(find.byType(SingbookMark).first);
      expect(mark.center.dx, greaterThan(180));
      final brand = tester.getRect(
        find.byKey(const ValueKey('appbar-brand-title')),
      );
      expect(brand.right, lessThanOrEqualTo(mark.left));
    });
  });

  testWidgets('main tabs keep clear of horizontal display cutouts', (
    tester,
  ) async {
    final c = FakeUiController((_) => _homeState());
    addTearDown(c.dispose);
    tester.view.padding = const FakeViewPadding(left: 48, right: 32);
    tester.view.viewPadding = const FakeViewPadding(left: 48, right: 32);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await pumpShell(tester, c, size: const Size(740, 360));
    final field = tester.getRect(find.byType(TextField).first);
    expect(field.left, greaterThanOrEqualTo(48));
    expect(field.right, lessThanOrEqualTo(740 - 32));
  });

  group('back navigation', () {
    testWidgets('Back from a root tab navigates to Home without exiting', (
      tester,
    ) async {
      final c = FakeUiController(
        (_) => const VerseUiState(activeTab: VerseTab.settings),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);

      unawaited(tester.binding.handlePopRoute());
      await tester.pumpAndSettle();

      expect(c.calls, contains('setTab'));
      expect(c.calls, isNot(contains('back')));
      expect(find.byType(VerseAppShell), findsOneWidget);
    });

    testWidgets('Home requires a second Back press to exit', (tester) async {
      final c = FakeUiController((_) => _homeState());
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      unawaited(tester.binding.handlePopRoute());
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(l10n.appExitBackAgain), findsOneWidget);
      expect(find.byType(VerseAppShell), findsOneWidget);
      final popScope = find.byWidgetPredicate(
        (widget) => widget is PopScope<Object?>,
      );
      expect(tester.widget<PopScope<Object?>>(popScope).canPop, isTrue);

      unawaited(tester.binding.handlePopRoute());
      await tester.pumpAndSettle();
      // The app's root route remains mounted in a widget test; allowing the
      // platform pop is what exits the native app in production.
      expect(find.byType(VerseAppShell), findsOneWidget);
    });

    testWidgets('repeated back gestures show a single discard prompt', (
      tester,
    ) async {
      final c = FakeUiController(
        (c) => const VerseUiState(
          route: VerseRoute.editor,
          editing: true,
          editorDirty: true,
          editor: SongEditorData(songId: 's', isNew: false, title: 'T'),
        ),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);

      unawaited(tester.binding.handlePopRoute());
      unawaited(tester.binding.handlePopRoute());
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsOneWidget);

      await tester.tap(find.text(l10n.actionDiscard));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(c.calls.where((call) => call == 'back'), hasLength(1));

      // The guard is released afterwards.
      unawaited(tester.binding.handlePopRoute());
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.text(l10n.editorUnsavedTitle), findsOneWidget);
    });
  });

  group('artwork', () {
    testWidgets('remote images are decoded at tile size and fall back', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VerseArtwork(url: 'http://localhost/none.jpg', size: 48),
          ),
        ),
      );
      final provider = tester.widget<Image>(find.byType(Image)).image;
      expect(provider, isA<ResizeImage>());
      expect((provider as ResizeImage).width, 96);
      expect(provider.height, 96);
    });
  });

  group('shell notices and sync button', () {
    testWidgets('every notice is announced in a localized snackbar', (
      tester,
    ) async {
      final c = FakeUiController((_) => const VerseUiState());
      addTearDown(c.dispose);
      await pumpShell(tester, c, locale: const Locale('ar'));
      final l10n = l10nOf(tester);
      for (final notice in UiNotice.values) {
        c.emit(notice);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(noticeMessage(l10n, notice)),
          ),
          findsOneWidget,
          reason: notice.name,
        );
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold).first),
        ).clearSnackBars();
        await tester.pump(const Duration(milliseconds: 400));
      }
    });

    testWidgets('the cloud button tooltip follows the sync state', (
      tester,
    ) async {
      var state = const VerseUiState();
      final c = FakeUiController((_) => state);
      addTearDown(c.dispose);
      await pumpShell(tester, c, settle: false);
      final l10n = l10nOf(tester);

      String? tooltip() => tester
          .widget<IconButton>(find.byKey(const ValueKey('cloud-button')))
          .tooltip;
      Future<String?> with_(VerseUiState next) async {
        state = next;
        c.refresh();
        await tester.pump();
        return tooltip();
      }

      expect(tooltip(), l10n.accountTitle);
      expect(
        await with_(const VerseUiState(syncReady: true)),
        l10n.accountStatusSignedOut,
      );
      expect(
        await with_(
          const VerseUiState(
            syncReady: true,
            syncSignedIn: true,
            lastSyncErrorCode: 'x',
          ),
        ),
        l10n.accountStatusError,
      );
      expect(
        await with_(
          VerseUiState(
            syncReady: true,
            syncSignedIn: true,
            lastSyncAt: DateTime(2026),
          ),
        ),
        l10n.accountStatusSynced,
      );
    });
  });
}

class _BrokenRepository implements LibraryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('secret path');
}
