import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/localized_labels.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_controller.dart';

const _suspicious = 'remote_listing_suspicious';

VerseUiState _state({
  String? error,
  String? warning,
  int count = 7,
  bool autoscroll = true,
  bool? autoscrollPreference,
  String timingMode = 'estimated',
}) => VerseUiState(
  activeTab: VerseTab.settings,
  syncReady: true,
  syncSignedIn: true,
  accountName: 'sam@example.com',
  lastSyncErrorCode: error,
  syncWarningCode: warning,
  syncSuspiciousDeletionCount: count,
  autoscroll: autoscroll,
  autoscrollPreference: autoscrollPreference,
  timingMode: timingMode,
);

Future<FakeUiController> _pump(
  WidgetTester tester,
  VerseUiState Function() state, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = const Size(360, 780),
}) async {
  final c = FakeUiController((_) => state());
  addTearDown(c.dispose);
  await pumpShell(
    tester,
    c,
    locale: locale,
    textScale: textScale,
    size: size,
    syncFocusRequest: 1,
  );
  return c;
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

void main() {
  sqfliteFfiInit();

  group('suspicious remote deletions dialog', () {
    testWidgets('opens once, explains the count and defaults to keeping', (
      tester,
    ) async {
      final c = await _pump(tester, () => _state(error: _suspicious));
      final l10n = l10nOf(tester);

      expect(_key('remote-deletions-dialog'), findsOneWidget);
      expect(
        find.descendant(
          of: _key('remote-deletions-dialog'),
          matching: find.text(l10n.accountSuspiciousBody(7)),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.accountSuspiciousKeep), findsOneWidget);
      expect(find.text(l10n.accountSuspiciousDelete), findsOneWidget);
      expect(
        tester.widget<FilledButton>(_key('remote-deletions-keep')).autofocus,
        isTrue,
      );
      expect(c.calls, isNot(contains('confirmRemoteDeletions')));

      // Cancelling leaves the decision open and does not nag again.
      await _tap(tester, 'remote-deletions-cancel');
      expect(_key('remote-deletions-dialog'), findsNothing);
      c.refresh();
      await tester.pumpAndSettle();
      expect(_key('remote-deletions-dialog'), findsNothing);
      expect(c.calls, isNot(contains('keepLocalAfterRemoteDeletions')));
      expect(c.calls, isNot(contains('confirmRemoteDeletions')));

      // The Account card still offers it.
      final card = _key('account-error');
      await tester.ensureVisible(card);
      expect(
        find.descendant(
          of: card,
          matching: find.text(l10n.accountSuspiciousBody(7)),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.accountChooseAction));
      await tester.pumpAndSettle();
      expect(_key('remote-deletions-dialog'), findsOneWidget);
    });

    testWidgets('keep local uploads again without deleting anything', (
      tester,
    ) async {
      final c = await _pump(tester, () => _state(error: _suspicious));
      await _tap(tester, 'remote-deletions-keep');
      expect(c.calls, contains('keepLocalAfterRemoteDeletions'));
      expect(c.calls, isNot(contains('confirmRemoteDeletions')));
      expect(_key('remote-deletions-dialog'), findsNothing);
    });

    testWidgets('deleting needs a second confirmation that can be declined', (
      tester,
    ) async {
      final c = await _pump(tester, () => _state(error: _suspicious));
      final l10n = l10nOf(tester);

      await _tap(tester, 'remote-deletions-delete');
      expect(_key('remote-deletions-confirm-dialog'), findsOneWidget);
      expect(
        find.text(l10n.accountSuspiciousDeleteConfirmTitle(7)),
        findsOneWidget,
      );
      expect(c.calls, isNot(contains('confirmRemoteDeletions')));
      expect(
        tester
            .widget<TextButton>(_key('remote-deletions-confirm-cancel'))
            .autofocus,
        isTrue,
      );

      // Declining returns to the choices.
      await _tap(tester, 'remote-deletions-confirm-cancel');
      expect(_key('remote-deletions-confirm-dialog'), findsNothing);
      expect(_key('remote-deletions-dialog'), findsOneWidget);
      expect(c.calls, isNot(contains('confirmRemoteDeletions')));

      await _tap(tester, 'remote-deletions-delete');
      await _tap(tester, 'remote-deletions-confirm');
      expect(c.calls, contains('confirmRemoteDeletions'));
      expect(c.calls, isNot(contains('keepLocalAfterRemoteDeletions')));
      expect(_key('remote-deletions-dialog'), findsNothing);
    });

    testWidgets('prompts again for a new occurrence', (tester) async {
      var error = _suspicious;
      String? current() => error;
      final c = await _pump(
        tester,
        () => _state(error: current() == _suspicious ? _suspicious : null),
      );
      await _tap(tester, 'remote-deletions-cancel');
      error = 'network';
      c.refresh();
      await tester.pumpAndSettle();
      error = _suspicious;
      c.refresh();
      await tester.pumpAndSettle();
      expect(_key('remote-deletions-dialog'), findsOneWidget);
    });

    for (final width in [320.0, 411.0]) {
      testWidgets('lays out in Arabic (RTL) at ${width.toInt()} wide, 1.6x', (
        tester,
      ) async {
        await _pump(
          tester,
          () => _state(error: _suspicious, count: 120),
          locale: const Locale('ar'),
          textScale: 1.6,
          size: Size(width, 700),
        );
        final l10n = l10nOf(tester);
        expect(
          Directionality.of(tester.element(_key('remote-deletions-dialog'))),
          TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.accountSuspiciousKeep), findsOneWidget);
        for (final key in [
          'remote-deletions-keep',
          'remote-deletions-delete',
          'remote-deletions-cancel',
        ]) {
          await tester.ensureVisible(_key(key));
          expect(tester.takeException(), isNull);
          expect(
            tester.getRect(_key(key)).right,
            lessThanOrEqualTo(width + 0.5),
            reason: key,
          );
          expect(tester.getRect(_key(key)).left, greaterThanOrEqualTo(-0.5));
        }

        await _tap(tester, 'remote-deletions-delete');
        expect(_key('remote-deletions-confirm-dialog'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _tap(tester, 'remote-deletions-confirm-cancel');
        await _tap(tester, 'remote-deletions-cancel');

        // The card itself, right-to-left, without overflow.
        final card = _key('account-error');
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.descendant(
            of: card,
            matching: find.text(l10n.accountSuspiciousBody(120)),
          ),
          findsOneWidget,
        );
        expect(tester.getRect(card).right, lessThanOrEqualTo(width + 0.5));
        expect(tester.getRect(card).left, greaterThanOrEqualTo(-0.5));
      });
    }

    testWidgets('a skipped-file warning is neutral, not a failed sync', (
      tester,
    ) async {
      await _pump(tester, () => _state(warning: 'invalid_remote_data'));
      final l10n = l10nOf(tester);
      final warning = _key('account-warning');
      await tester.ensureVisible(warning);
      expect(find.text(l10n.accountSyncWarningTitle), findsOneWidget);
      expect(find.text(l10n.accountSyncWarningInvalid), findsOneWidget);
      expect(_key('account-error'), findsNothing);
      expect(_key('remote-deletions-dialog'), findsNothing);
    });
  });

  group('settings: default autoscroll switch', () {
    Future<SwitchListTile> pumpSwitch(
      WidgetTester tester,
      VerseUiState state,
    ) async {
      final c = FakeUiController((_) => state);
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-menu-player')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-player')));
      await tester.pumpAndSettle();
      final tile = find.widgetWithText(
        SwitchListTile,
        l10n.settingsDefaultAutoscroll,
      );
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      return tester.widget<SwitchListTile>(tile);
    }

    testWidgets('shows the stored preference while manual timing is off', (
      tester,
    ) async {
      final tile = await pumpSwitch(
        tester,
        _state(
          autoscroll: false,
          autoscrollPreference: true,
          timingMode: 'manual',
        ),
      );
      expect(tile.value, isTrue);
      expect(tile.onChanged, isNull);
    });

    testWidgets('follows the preference and changes it on tap', (tester) async {
      final c = FakeUiController(
        (_) => _state(autoscroll: false, autoscrollPreference: false),
      );
      addTearDown(c.dispose);
      await pumpShell(tester, c);
      final l10n = l10nOf(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-menu-player')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-menu-player')));
      await tester.pumpAndSettle();
      final tile = find.widgetWithText(
        SwitchListTile,
        l10n.settingsDefaultAutoscroll,
      );
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(c.calls, contains('setAutoscroll'));
    });
  });

  group('labels', () {
    test('every new sync code and notice reads as specific text', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        final generic = syncErrorText(l10n, 'something_unknown');
        for (final code in [
          'remote_listing_suspicious',
          'remote_changed',
          'invalid_local_data',
          'no_account_change',
        ]) {
          final text = syncErrorText(l10n, code);
          expect(text.message, isNotEmpty, reason: '$locale $code');
          expect(text.hint, isNotEmpty, reason: '$locale $code');
          if (locale.languageCode == 'en' ||
              locale.languageCode == 'bg' ||
              locale.languageCode == 'uk') {
            expect(text.message, isNot(generic.message), reason: '$locale');
          }
        }
        for (final notice in UiNotice.values) {
          expect(
            noticeMessage(l10n, notice),
            isNotEmpty,
            reason: '$locale $notice',
          );
        }
        for (final code in [
          'remote_file_too_large',
          'invalid_remote_data',
          'invalid_local_data',
          'local_file_too_large',
          'other',
        ]) {
          expect(syncWarningText(l10n, code).hint, isNotEmpty);
        }
      }
    });

    test('English wording of the new notices', () {
      final en = lookupAppLocalizations(const Locale('en'));
      expect(
        noticeMessage(en, UiNotice.exportPdfTooLarge),
        en.settingsExportPdfTooLarge,
      );
      expect(
        noticeMessage(en, UiNotice.timingTooLarge),
        en.settingsTimingTooLarge,
      );
      expect(
        noticeMessage(en, UiNotice.importDuplicateSongId),
        en.settingsImportDuplicateSongId,
      );
      expect(
        noticeMessage(en, UiNotice.syncSkipped),
        en.accountNoticeSyncSkipped,
      );
    });
  });

  group('adapter', () {
    late LibraryRepository repository;
    late AppController app;
    late AppControllerAdapter ui;
    late List<UiNotice> notices;
    late StreamSubscription<UiNotice> subscription;
    Future<void> Function(SongDocument)? failShare;
    Future<void> Function(SongDocument)? failPdf;
    Future<void> Function()? failImport;

    setUp(() async {
      failShare = failPdf = null;
      failImport = null;
      repository = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      app = AppController(repository: repository);
      await app.initialize();
      ui = AppControllerAdapter(
        app,
        onShareSong: (song) => failShare!(song),
        onShareSongPdf: (song) => failPdf!(song),
        onImport: () => failImport!(),
      );
      notices = [];
      subscription = ui.notices.listen(notices.add);
    });

    tearDown(() async {
      await subscription.cancel();
      ui.dispose();
      app.dispose();
      await repository.close();
    });

    SongDocument song(String id, {double? duration}) => SongDocument(
      id: id,
      title: 'Song $id',
      artist: 'Artist',
      body: '[C]First line\n[G]Second line',
      metadata: {'durationSeconds': ?duration},
    );

    test('playing again after the song ended restarts from zero', () async {
      await app.saveSong(song('a', duration: 10));
      await ui.openSong('a');
      await ui.playPause();
      expect(ui.state.isPlaying, isTrue);
      ui.advancePlayerBy(30);
      expect(ui.state.isPlaying, isFalse);
      expect(ui.playerPosition.value.seconds, 10);

      await ui.playPause();
      expect(ui.state.isPlaying, isTrue);
      expect(ui.playerPosition.value.seconds, 0);
      await ui.playPause(); // stop the timer
      expect(ui.state.isPlaying, isFalse);
    });

    test('pausing mid-song keeps the position', () async {
      await app.saveSong(song('a', duration: 100));
      await ui.openSong('a');
      await ui.seek(40);
      await ui.playPause();
      await ui.playPause();
      expect(ui.playerPosition.value.seconds, 40);
    });

    test(
      'autoscroll preference stays visible while manual timing is on',
      () async {
        await app.setSetting('autoscroll', true);
        await app.setSetting('timingMode', 'manual');
        expect(ui.state.autoscroll, isFalse);
        expect(ui.state.autoscrollPreference, isTrue);
        await ui.setAutoscroll(false);
        await app.setSetting('timingMode', 'estimated');
        expect(ui.state.autoscrollPreference, isFalse);
        expect(ui.state.autoscroll, isFalse);
        await ui.setAutoscroll(true);
        expect(ui.state.autoscrollPreference, isTrue);
        expect(ui.state.autoscroll, isTrue);
      },
    );

    group('setlist editing', () {
      SetlistDocument setlist(String name, {String id = 'set'}) =>
          SetlistDocument(
            id: id,
            name: name,
            entries: const [SetlistEntry(id: 'e1', songId: 'a')],
          );

      setUp(() async {
        await app.saveSong(song('a'));
        await app.saveSetlist(setlist('Original'));
      });

      test(
        'a save after a background change becomes a conflict copy',
        () async {
          await ui.editSetlist('set');
          // A sync rewrites the setlist while the editing form is open.
          await app.saveSetlist(setlist('Synced from phone'));
          notices.clear();

          await ui.saveSetlistDetails(
            name: 'Mine',
            notes: '',
            finishEditing: true,
          );

          await pumpEventQueue();

          expect(notices, contains(UiNotice.setlistSaveConflict));
          expect(
            app.setlists.firstWhere((item) => item.id == 'set').name,
            'Synced from phone',
          );
          expect(
            app.setlists.where((item) => item.name.startsWith('Mine')),
            hasLength(1),
          );
        },
      );

      test(
        'consecutive saves in one editing session do not conflict',
        () async {
          await ui.editSetlist('set');
          notices.clear();
          await ui.saveSetlistDetails(name: 'One', notes: '');
          await ui.saveSetlistDetails(name: 'Two', notes: 'n');
          await ui.removeSetlistEntry('set', 'e1', name: 'Three');

          await pumpEventQueue();

          expect(notices, isNot(contains(UiNotice.setlistSaveConflict)));
          expect(app.setlists, hasLength(1));
          expect(app.setlists.single.name, 'Three');
        },
      );

      test(
        'a fresh edit session starts from the current stored version',
        () async {
          await ui.editSetlist('set');
          await app.saveSetlist(setlist('Synced'));
          await ui.back();
          await ui.editSetlist('set');
          notices.clear();
          await ui.saveSetlistDetails(name: 'Mine', notes: '');
          await pumpEventQueue();
          expect(notices, isNot(contains(UiNotice.setlistSaveConflict)));
          expect(app.setlists.single.name, 'Mine');
        },
      );
    });

    test('next and previous record the opened song in Recent', () async {
      await app.saveSong(song('a'));
      await app.saveSong(song('b'));
      await app.saveSetlist(
        SetlistDocument(
          id: 'set',
          name: 'Set',
          entries: const [
            SetlistEntry(id: 'e1', songId: 'a'),
            SetlistEntry(id: 'e2', songId: 'b'),
          ],
        ),
      );
      await ui.openSetlistEntry('set', 'e1');
      final before = app.recent.length;

      await ui.nextSong();
      // Navigation happened before the record was stored.
      expect(ui.state.song?.id, 'b');
      await ui.settleRecentRecords();
      expect(app.recent.length, before + 1);
      expect(app.recent.first.objectId, 'b');
      expect(app.recent.first.objectKind, 'song');

      await ui.previousSong();
      await ui.settleRecentRecords();
      expect(app.recent.first.objectId, 'a');
      await pumpEventQueue();
      expect(notices, isEmpty);
    });

    test(
      'a failing Recent record is reported but does not block playback',
      () async {
        await app.saveSong(song('a'));
        await app.saveSong(song('b'));
        await app.saveSetlist(
          SetlistDocument(
            id: 'set',
            name: 'Set',
            entries: const [
              SetlistEntry(id: 'e1', songId: 'a'),
              SetlistEntry(id: 'e2', songId: 'b'),
            ],
          ),
        );
        await ui.openSetlistEntry('set', 'e1');
        await repository.database.execute('DROP TABLE activity');
        await ui.nextSong();
        await ui.settleRecentRecords();
        expect(ui.state.song?.id, 'b');
        await pumpEventQueue();
        expect(notices, contains(UiNotice.genericError));
      },
    );

    test('file errors map to specific notices', () async {
      await app.saveSong(song('a'));
      failPdf = (_) async => throw const FormatException('pdf_too_large');
      await ui.shareSongPdf('a');
      await pumpEventQueue();
      expect(notices.last, UiNotice.exportPdfTooLarge);

      failShare = (_) async =>
          throw const FormatException('Timing payload exceeds 3 MiB.');
      await ui.shareSong('a');
      await pumpEventQueue();
      expect(notices.last, UiNotice.timingTooLarge);

      failShare = (_) async => throw const FormatException('something else');
      await ui.shareSong('a');
      await pumpEventQueue();
      expect(notices.last, UiNotice.exportFailed);

      failImport = () async => throw const FormatException('duplicate_song_id');
      await ui.importChordPro();
      await pumpEventQueue();
      expect(notices.last, UiNotice.importDuplicateSongId);

      failImport = () async =>
          throw const FormatException('Timing payload exceeds 3 MiB.');
      await ui.importChordPro();
      await pumpEventQueue();
      expect(notices.last, UiNotice.timingTooLarge);

      failImport = () async => throw const FormatException('backup_too_large');
      await ui.importChordPro();
      await pumpEventQueue();
      expect(notices.last, UiNotice.importTooLarge);
    });

    test('a skipped-file sync result is a warning, not an error', () async {
      app.syncWarning = 'invalid_remote_data';
      app.syncError = 'invalid_remote_data';
      await app.setSetting('palette', 'navy');
      expect(ui.state.syncWarningCode, 'invalid_remote_data');
      expect(ui.state.lastSyncErrorCode, isNull);
      expect(ui.state.syncErrorCode, isNull);

      app.syncWarning = null;
      app.syncError = 'remote_changed';
      await app.setSetting('palette', 'navy');
      expect(ui.state.syncWarningCode, isNull);
      expect(ui.state.lastSyncErrorCode, 'remote_changed');
      expect(ui.state.syncSuspiciousDeletionCount, 0);
    });
  });
}
