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

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(repository: repository);
    await app.initialize();
    ui = AppControllerAdapter(app);
  });

  tearDown(() async {
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  group('editSong', () {
    test('estimates a key for reader display without trusting or saving it', () async {
      const body = '[E]One line of melody\n[A/E]Another line singing\n'
          '[Am/E]A different color\n[C#m]Then the night\n[F#]Turns around\n'
          '[G#m]And comes back home\n[B]To where it began\n[B/A]Softly now\n'
          '[D/F#]The song returns\n[E]And settles down';
      await app.saveSong(_song('keyless', 'Keyless', body: body));
      await ui.openSong('keyless');

      expect(ui.displayedKey, isNull);
      expect(ui.state.readerKey, 'E');
      expect(ui.state.readerKeyEstimated, isTrue);
      expect(ui.state.song?.key, isNull);

      await ui.transpose(1);
      expect(ui.state.readerKey, 'F');
      expect(ui.displayedKey, isNull);
      await ui.settlePlayerPreferences();
      final saved = (await repository.getSong('keyless'))!;
      expect(saved.metadata.containsKey('key'), isFalse);
      expect(saved.body, body);
    });

    test('does not carry over another song\'s transpose or progress', () async {
      await app.saveSong(_song('a', 'Alpha', metadata: {'key': 'C'}));
      await app.saveSong(_song('b', 'Beta', metadata: {'key': 'C'}));
      await ui.openSong('a');
      await ui.transpose(2);
      await ui.seek(30);
      expect(ui.state.readerKey, 'D');

      await ui.editSong('b');

      expect(ui.state.song?.id, 'b');
      expect(ui.state.readerKey, 'C');
      expect(ui.playerPosition.value.seconds, 0);
    });

    test('keeps the transpose when editing the open song from its reader',
        () async {
      await app.saveSong(_song('a', 'Alpha', metadata: {'key': 'C'}));
      await ui.openSong('a');
      await ui.transpose(2);
      await ui.editSong('a');
      expect(ui.state.readerKey, 'D');
      await ui.back();
      expect(ui.state.route, VerseRoute.reader);
    });

    test('back from an editor opened on the list returns to the list',
        () async {
      await app.saveSong(_song('a', 'Alpha'));
      await ui.editSong('a');
      expect(ui.state.route, VerseRoute.editor);
      await ui.back();
      expect(ui.state.route, VerseRoute.main);
      expect(ui.state.song, isNull);
      expect(app.recent, isEmpty);
    });
  });

  group('setlist next/previous', () {
    Future<void> setUpSetlist() async {
      await app.saveSong(_song('a', 'Alpha'));
      await app.saveSong(_song('c', 'Gamma'));
      // The database forbids dangling references, but synced or imported
      // data can leave one in memory; simulate that.
      app.setlists = [
        SetlistDocument(
          id: 'set',
          name: 'Set',
          entries: const [
            SetlistEntry(id: 'e1', songId: 'a'),
            SetlistEntry(id: 'e2', songId: 'gone'),
            SetlistEntry(id: 'e3', songId: 'c'),
          ],
        ),
      ];
    }

    test('steps over a deleted song', () async {
      await setUpSetlist();
      await ui.openSetlistEntry('set', 'e1');
      await ui.nextSong();
      expect(ui.state.song?.id, 'c');
      expect(ui.state.songLines, isNotEmpty);

      await ui.previousSong();
      expect(ui.state.song?.id, 'a');
    });

    test('stays put when only missing songs remain ahead', () async {
      await setUpSetlist();
      app.setlists = [
        SetlistDocument(
          id: 'set',
          name: 'Set',
          entries: const [
            SetlistEntry(id: 'e1', songId: 'a'),
            SetlistEntry(id: 'e2', songId: 'gone'),
          ],
        ),
      ];
      await ui.openSetlistEntry('set', 'e1');
      await ui.nextSong();
      expect(ui.state.song?.id, 'a');
      expect(ui.state.songLines, isNotEmpty);
    });
  });

  group('malformed metadata', () {
    test('non-numeric duration, key, capo and tempo still render', () async {
      await app.saveSong(
        _song(
          'a',
          'Alpha',
          metadata: {
            'durationSeconds': 'abc',
            'key': 7,
            'album': 12,
            'capo': {'x': 1},
            'tempo': [],
            'artworkUrl': 5,
          },
        ),
      );
      await app.saveSong(
        _song('b', 'Beta', metadata: {'durationSeconds': '215.5'}),
      );
      await ui.openSong('a');

      final state = ui.state;
      expect(state.songs.map((s) => s.id), ['a', 'b']);
      expect(state.songs.first.durationSeconds, isNull);
      expect(state.songs.last.durationSeconds, 215.5);
      expect(state.songLines, isNotEmpty);
      expect(state.recent.map((r) => r.id), contains('a'));
      expect(state.song?.id, 'a');
    });
  });

  test('the song list is sorted by title without a full rescan', () async {
    for (var i = 20; i > 0; i--) {
      await app.saveSong(_song('s$i', 'Song ${i.toString().padLeft(2, '0')}'));
    }
    final titles = ui.state.songs.map((s) => s.title).toList();
    expect(titles, [...titles]..sort());
  });
}

SongDocument _song(
  String id,
  String title, {
  JsonMap metadata = const {},
  String body = '[C]First line\n[G]Second line',
}) => SongDocument(
  id: id,
  title: title,
  artist: 'Artist',
  body: body,
  metadata: metadata,
);
