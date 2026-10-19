import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  sqfliteFfiInit();
  late LibraryRepository repo;
  late AppController app;
  late AppControllerAdapter ui;
  late List<String> preferences;
  setUp(() async {
    repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(
      repository: repo,
      discovery: SourceDiscoveryService([]),
    );
    await app.initialize();
    for (final id in ['active', 'other']) {
      await app.saveSong(
        SongDocument(
          id: id,
          title: id,
          artist: 'Fixture',
          body: 'A lyric',
          metadata: {'durationSeconds': 120},
        ),
      );
    }
    await app.saveSetlist(
      SetlistDocument(
        id: 'set',
        name: 'Set',
        entries: const [SetlistEntry(id: 'entry', songId: 'active')],
      ),
    );
    preferences = [];
    ui = AppControllerAdapter(
      app,
      onSavePlayerPreferences: (id, transpose, speed) async {
        preferences.add(id);
      },
    );
  });
  tearDown(() async {
    ui.dispose();
    app.dispose();
    await repo.close();
  });

  test(
    'deleting active playback stops its clock and drops pending preferences',
    () async {
      await ui.openSetlistEntry('set', 'entry');
      await ui.playPause();
      await ui.transpose(2);
      expect(ui.state.isPlaying, isTrue);
      await ui.deleteSong('active');
      await ui.settlePlayerPreferences();
      expect(ui.state.isPlaying, isFalse);
      expect(ui.state.progressSeconds, 0);
      expect(ui.state.route, VerseRoute.main);
      expect(ui.currentSong, isNull);
      expect(ui.activeSetlistEntry, isNull);
      expect(preferences, isEmpty);
      expect(await repo.getSong('active'), isNull);
      expect(await repo.getSong('other'), isNotNull);
    },
  );

  test('deleting an unrelated song preserves the active player', () async {
    await ui.openSong('active');
    await ui.playPause();
    await ui.deleteSong('other');
    expect(ui.state.isPlaying, isTrue);
    expect(ui.currentSong!.id, 'active');
    expect(ui.state.route, VerseRoute.reader);
  });

  test('successful editor deletion clears stale editor state', () async {
    await ui.editSong('active');
    ui.setEditorDirty(true);
    await ui.deleteSong('active');
    expect(ui.state.editing, isFalse);
    expect(ui.state.editorDirty, isFalse);
    expect(ui.state.editor, isNull);
    expect(ui.state.route, VerseRoute.main);
    await ui.editSong('other');
    expect(ui.state.editor!.songId, 'other');
    expect(ui.state.editorDirty, isFalse);
  });

  test(
    'a failed song deletion preserves the editor and persisted song',
    () async {
      await ui.editSong('active');
      ui.setEditorDirty(true);
      await repo.database.execute(
        "CREATE TRIGGER refuse_delete BEFORE DELETE ON songs BEGIN SELECT RAISE(ABORT, 'test-only'); END",
      );
      await ui.deleteSong('active');
      expect(ui.state.route, VerseRoute.editor);
      expect(ui.state.editor!.songId, 'active');
      expect(ui.state.editorDirty, isTrue);
      expect(ui.state.editing, isTrue);
      expect(await repo.getSong('active'), isNotNull);
    },
  );

  test('a failed active player deletion keeps playback running', () async {
    await ui.openSong('active');
    await ui.playPause();
    await repo.database.execute(
      "CREATE TRIGGER refuse_delete BEFORE DELETE ON songs BEGIN SELECT RAISE(ABORT, 'test-only'); END",
    );
    await ui.deleteSong('active');
    expect(ui.state.isPlaying, isTrue);
    expect(ui.currentSong!.id, 'active');
  });

  test(
    'setlist deletion clears editing state while retaining library songs',
    () async {
      await ui.editSetlist('set');
      await ui.deleteSetlist('set');
      expect(ui.state.editingSetlist, isFalse);
      expect(ui.state.activeSetlist, isNull);
      expect(ui.state.route, VerseRoute.main);
      expect(await repo.listSongs(), hasLength(2));
      expect(await repo.getSetlist('set'), isNull);
    },
  );

  test('failed setlist deletion preserves setlist editing', () async {
    await ui.editSetlist('set');
    await repo.database.execute(
      "CREATE TRIGGER refuse_delete BEFORE DELETE ON setlists BEGIN SELECT RAISE(ABORT, 'test-only'); END",
    );
    await ui.deleteSetlist('set');
    expect(ui.state.editingSetlist, isTrue);
    expect(ui.state.activeSetlist!.id, 'set');
    expect(ui.state.route, VerseRoute.setlistDetail);
  });
}
