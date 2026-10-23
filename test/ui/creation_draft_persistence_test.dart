import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

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
    await repository.database.execute('CREATE TEMP TABLE inserted_lists (id TEXT)');
    await repository.database.execute('''
      CREATE TEMP TRIGGER record_setlist_insert AFTER INSERT ON main.setlists
      BEGIN INSERT INTO inserted_lists (id) VALUES (NEW.id); END
    ''');
  });

  tearDown(() async {
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  Future<int> inserts() async => (await repository.database.rawQuery(
    'SELECT COUNT(*) AS total FROM inserted_lists',
  )).single['total'] as int;

  Future<void> saveSong(String id) => app.saveSong(
    SongDocument(id: id, title: 'Song $id', artist: 'Fixture', body: '[C]Words'),
  );

  for (final leaveWithTab in [false, true]) {
    test('opening and leaving a setlist creates nothing (tab=$leaveWithTab)', () async {
      await ui.createSetlist(name: 'New setlist');
      final id = ui.state.activeSetlist!.id;
      expect(ui.state.route, VerseRoute.setlistDetail);
      expect(app.setlists, isEmpty);
      expect(await repository.getSetlist(id), isNull);
      await ui.saveSetlistDetails(name: 'New setlist', notes: '', finishEditing: true);
      expect(app.setlists, isEmpty, reason: 'untouched Save is not a write');
      if (leaveWithTab) {
        ui.setTab(VerseTab.home);
      } else {
        await ui.back();
      }
      expect(ui.state.activeSetlist, isNull);
      expect(await repository.listSetlists(), isEmpty);
      expect(await inserts(), 0);
    });
  }

  test('first rename writes one item and existing edits keep its identity', () async {
    await ui.createSetlist(name: 'New setlist');
    final id = ui.state.activeSetlist!.id;
    await ui.saveSetlistDetails(name: 'Evening', notes: '', finishEditing: true);
    expect(app.setlists.single.id, id);
    expect((await repository.getSetlist(id))!.name, 'Evening');
    expect(await inserts(), 1);
    await ui.editSetlist(id);
    await ui.saveSetlistDetails(name: 'Evening revised', notes: 'Acoustic');
    expect(app.setlists.single.id, id);
    expect((await repository.getSetlist(id))!.notes, 'Acoustic');
    expect(await inserts(), 1, reason: 'later saves update the same document');
  });

  test('empty picker leaves draft private; first song then multiple adds keep one setlist', () async {
    await saveSong('a');
    await saveSong('b');
    await ui.createSetlist(name: 'New setlist');
    final id = ui.state.activeSetlist!.id;
    // The picker saves the inline form before opening, even if cancelled.
    await ui.saveSetlistDetails(name: 'New setlist', notes: '');
    expect(await repository.listSetlists(), isEmpty);
    expect(await inserts(), 0);
    await ui.addSongToSetlist('a', id);
    expect(app.setlists.single.id, id);
    expect(app.setlists.single.entries.map((e) => e.songId), ['a']);
    expect(await inserts(), 1);
    await ui.addSongToSetlist('b', id);
    expect(app.setlists.single.entries.map((e) => e.songId), ['a', 'b']);
    expect(await inserts(), 1);
  });

  test('invalid song and deleting a draft never insert a placeholder', () async {
    await ui.createSetlist(name: 'New setlist');
    final id = ui.state.activeSetlist!.id;
    await ui.addSongToSetlist('missing', id);
    expect(await repository.listSetlists(), isEmpty);
    await ui.deleteSetlist(id);
    expect(ui.state.route, VerseRoute.main);
    expect(await inserts(), 0);
  });

  test('explicit favorite can be saved and is retained', () async {
    await ui.createSetlist(name: 'New setlist');
    final id = ui.state.activeSetlist!.id;
    await ui.toggleSetlistFavorite(id);
    expect(app.setlists, isEmpty, reason: 'favorite is initially a draft edit');
    await ui.saveSetlistDetails(name: 'New setlist', notes: '', finishEditing: true);
    expect((await repository.getSetlist(id))!.favorite, isTrue);
    expect(await inserts(), 1);
  });

  test('simultaneous first saves preserve both edits with CAS conflict handling', () async {
    await ui.createSetlist(name: 'New setlist');
    final id = ui.state.activeSetlist!.id;
    final entered = Completer<void>();
    final release = Completer<void>();
    final blocker = repository.database.transaction((_) async {
      entered.complete();
      await release.future;
    });
    await entered.future;
    final first = ui.saveSetlistDetails(name: 'First', notes: 'One');
    final second = ui.saveSetlistDetails(name: 'Second', notes: 'Two');
    release.complete();
    await blocker;
    await Future.wait([first, second]);
    final stored = await repository.listSetlists();
    expect(stored, hasLength(2));
    final original = stored.singleWhere((value) => value.id == id);
    expect(original.name, anyOf('First', 'Second'));
    expect(stored.map((value) => value.notes), containsAll(['One', 'Two']));
    expect(stored.where((value) => value.id != id), hasLength(1));
    expect(await inserts(), 2, reason: 'one original and one preserved conflict');
  });

  test('new song rejects titleless template and discards on leaving', () async {
    await ui.createSong();
    final id = ui.state.editor!.songId;
    expect(app.songs, isEmpty);
    await ui.saveLyricsEdit('{title: }\n\n{start_of_verse}\n[C]Example\n{end_of_verse}');
    expect(await repository.getSong(id), isNull);
    expect(ui.state.route, VerseRoute.editor);
    await ui.back();
    expect(app.songs, isEmpty);
    expect(ui.state.route, VerseRoute.main);
  });

  test('named new song persists once under its draft ID', () async {
    await ui.createSong();
    final id = ui.state.editor!.songId;
    await ui.saveLyricsEdit('{title: My song}\n\n[C]My lyrics');
    expect(app.songs.single.id, id);
    expect((await repository.getSong(id))!.body, '[C]My lyrics');
    expect(ui.state.route, VerseRoute.reader);
  });
}
