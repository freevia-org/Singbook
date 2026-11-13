import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late AppController app;
  late AppControllerAdapter ui;
  late List<UiNotice> notices;
  late StreamSubscription<UiNotice> subscription;
  var repositoryClosed = false;

  setUp(() async {
    repositoryClosed = false;
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(repository: repository);
    await app.initialize();
    ui = AppControllerAdapter(app);
    notices = [];
    subscription = ui.notices.listen(notices.add);
  });

  tearDown(() async {
    await subscription.cancel();
    ui.dispose();
    app.dispose();
    if (!repositoryClosed) await repository.close();
  });

  // Notices travel through a broadcast stream, one event-loop turn later.
  Future<void> flushNotices() => Future<void>.delayed(Duration.zero);

  Future<void> closeRepository() async {
    repositoryClosed = true;
    await repository.close();
  }

  group('library duration estimates', () {
    test('a reload does not estimate unchanged charts again', () async {
      for (final id in ['a', 'b', 'c']) {
        await app.saveSong(_song(id, 'Song $id'));
      }
      final before = {
        for (final card in ui.state.songs) card.id: card.durationSeconds,
      };
      expect(before.values, everyElement(isNotNull));
      final estimated = ui.chartEstimateCount;
      expect(estimated, 3);

      // Any write reloads the library and replaces every song instance.
      await app.saveSetlist(SetlistDocument(id: 'set', name: 'Set'));
      final songsAfterReload = app.songs;
      final after = {
        for (final card in ui.state.songs) card.id: card.durationSeconds,
      };

      expect(identical(songsAfterReload, app.songs), isTrue);
      expect(after, before);
      expect(ui.chartEstimateCount, estimated);
    });

    test('an edited chart is estimated again, and only that one', () async {
      await app.saveSong(_song('a', 'Alpha'));
      await app.saveSong(_song('b', 'Beta'));
      final before = ui.state.songs
          .firstWhere((card) => card.id == 'a')
          .durationSeconds;
      final estimated = ui.chartEstimateCount;

      final longer = [
        for (var line = 0; line < 80; line++) 'Another line number $line',
      ].join('\n');
      await app.saveSong(app.findSong('a')!.copyWith(body: longer));

      final after = ui.state.songs
          .firstWhere((card) => card.id == 'a')
          .durationSeconds;
      expect(after, greaterThan(before!));
      expect(ui.chartEstimateCount, estimated + 1);
    });

    test('a deleted song leaves no estimate behind for a reused id', () async {
      await app.saveSong(_song('a', 'Alpha'));
      final short = ui.state.songs.single.durationSeconds;
      await ui.deleteSong('a');
      expect(ui.state.songs, isEmpty);

      final longer = [
        for (var line = 0; line < 80; line++) 'Another line number $line',
      ].join('\n');
      await app.saveSong(_song('a', 'Alpha', body: longer));

      expect(ui.state.songs.single.durationSeconds, greaterThan(short!));
    });
  });

  group('openSetlist', () {
    test('shows the setlist before the visit is stored', () async {
      await app.saveSetlist(SetlistDocument(id: 's', name: 'Set'));
      var notified = 0;
      ui.addListener(() => notified++);

      final opening = ui.openSetlist('s');

      expect(notified, 1);
      expect(ui.state.route, VerseRoute.setlistDetail);
      expect(ui.state.activeSetlist?.id, 's');
      await opening;
      expect(app.recent.single.objectId, 's');
    });

    test('a failed history write is reported and still navigates', () async {
      await app.saveSetlist(SetlistDocument(id: 's', name: 'Set'));
      await closeRepository();

      await ui.openSetlist('s');
      await flushNotices();

      expect(ui.state.route, VerseRoute.setlistDetail);
      expect(notices, [UiNotice.genericError]);
    });
  });

  group('addSongToSetlist', () {
    test('reports a setlist that no longer exists', () async {
      await app.saveSong(_song('a', 'Alpha'));

      await ui.addSongToSetlist('a', 'gone');
      await flushNotices();

      expect(notices, [UiNotice.genericError]);
    });

    test('stays silent when the song was added', () async {
      await app.saveSong(_song('a', 'Alpha'));
      await app.saveSetlist(SetlistDocument(id: 's', name: 'Set'));

      await ui.addSongToSetlist('a', 's');

      expect(notices, isEmpty);
      expect(ui.state.setlists.single.songIds, ['a']);
    });
  });

  group('editSong', () {
    test('stops playback of the open song and keeps its position', () async {
      await app.saveSong(_song('a', 'Alpha'));
      await ui.openSong('a');
      await ui.playPause();
      ui.advancePlayerBy(5);
      expect(ui.state.isPlaying, isTrue);

      await ui.editSong('a');

      expect(ui.state.route, VerseRoute.editor);
      expect(ui.state.isPlaying, isFalse);
      expect(ui.playerPosition.value.seconds, 5);
      // No timer is left to move the position behind the editor.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(ui.playerPosition.value.seconds, 5);
    });
  });

  group('settings', () {
    test('a failed write is reported instead of thrown', () async {
      await closeRepository();
      var notified = 0;
      ui.addListener(() => notified++);

      await ui.setShowChords(false);
      await ui.setThemeMode(AppThemeMode.dark);
      await ui.setStartupSongsView('library');
      await flushNotices();

      expect(notices, List.filled(3, UiNotice.genericError));
      // The screen is brought in step with the value the controller holds.
      expect(notified, 3);
      expect(ui.state.showChords, isFalse);
      expect(ui.state.darkTheme, AppThemeMode.dark);
    });

    test('a successful write stays silent', () async {
      await ui.setShowChords(false);

      expect(notices, isEmpty);
      expect(ui.state.showChords, isFalse);
    });
  });

  group('recent rows', () {
    test('keep their identity across unrelated notifications', () async {
      await app.saveSong(_song('a', 'Alpha'));
      await ui.openSong('a');
      await ui.back();
      final recent = ui.state.recent;
      expect(recent.single.id, 'a');

      ui.setFavoritesOnly(true);
      ui.setQuery('alp');

      expect(identical(ui.state.recent, recent), isTrue);
    });

    test('follow the library and the history', () async {
      await app.saveSong(_song('a', 'Alpha'));
      await app.saveSong(_song('b', 'Beta'));
      await ui.openSong('a');
      await ui.back();
      expect(ui.state.recent.map((item) => item.id), ['a']);
      expect(ui.state.recent.single.favorite, isFalse);

      await ui.toggleSongFavorite('a');
      expect(ui.state.recent.single.favorite, isTrue);

      await ui.openSong('b');
      await ui.back();
      expect(ui.state.recent.map((item) => item.id), ['b', 'a']);

      await ui.deleteSong('a');
      expect(ui.state.recent.map((item) => item.id), ['b']);
    });
  });

  group('local search', () {
    test('an accented title counts as a local match', () async {
      await app.saveSong(_song('a', 'Éclair au café'));
      ui.setHomeListMode(HomeListMode.library);
      ui.setQuery('eclair');

      await ui.submitSearch();

      // A visible local match keeps the search local.
      expect(ui.state.homeListMode, HomeListMode.library);
    });
  });
}

SongDocument _song(
  String id,
  String title, {
  String body = 'A line of the song\nAnother line of it',
}) => SongDocument(id: id, title: title, artist: 'Artist', body: body);
