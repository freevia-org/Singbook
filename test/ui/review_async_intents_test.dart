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
  late bool uiDisposed;

  _PreferenceGate gatePreferences() {
    ui.dispose();
    uiDisposed = true;
    final gate = _PreferenceGate(app);
    ui = AppControllerAdapter(app, onSavePlayerPreferences: gate.write);
    uiDisposed = false;
    return gate;
  }

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(repository: repository);
    await app.initialize();
    ui = AppControllerAdapter(app);
    uiDisposed = false;
    await _saveSong(app, 'a');
    await _saveSong(app, 'b');
    await _saveSong(app, 'c');
    await app.saveSetlist(
      SetlistDocument(
        id: 'set',
        name: 'Set',
        entries: const [SetlistEntry(id: 'entry', songId: 'a')],
      ),
    );
  });

  tearDown(() async {
    if (!uiDisposed) {
      await ui.settlePlayerPreferences();
      ui.dispose();
    }
    app.dispose();
    await repository.close();
  });

  test('a later setlist navigation invalidates a pending song open', () async {
    final gate = gatePreferences();
    await ui.openSong('a');
    await ui.transpose(2);

    final opening = ui.openSong('b');
    await gate.started.future;
    await ui.openSetlist('set');
    gate.release();
    await opening;

    expect(ui.state.route, VerseRoute.setlistDetail);
    expect(ui.state.activeSetlist?.id, 'set');
  });

  test('a later Create Song action invalidates a pending editSong', () async {
    final gate = gatePreferences();
    await ui.openSong('a');
    await ui.transpose(2);

    final editing = ui.editSong('b');
    await gate.started.future;
    await ui.createSong();
    final draftId = ui.state.song?.id;
    gate.release();
    await editing;

    expect(ui.state.route, VerseRoute.editor);
    expect(ui.state.editor?.isNew, isTrue);
    expect(ui.state.song?.id, draftId);
    expect(ui.state.song?.id, isNot('b'));
  });

  test('back invalidates a pending song open', () async {
    final gate = gatePreferences();
    await ui.openSong('a');
    await ui.transpose(2);

    final opening = ui.openSong('b');
    await gate.started.future;
    await ui.back();
    gate.release();
    await opening;

    expect(ui.state.route, VerseRoute.main);
    expect(ui.state.song, isNull);
  });

  test(
    'back invalidates a setlist next action waiting on preference flush',
    () async {
      final gate = gatePreferences();
      await _saveAdvanceSetlist(app);
      await ui.openSetlistEntry('advance', 'first');
      await ui.transpose(2);

      final advancing = ui.nextSong();
      await gate.started.future;
      await ui.back();
      gate.release();
      await advancing;

      expect(ui.state.route, VerseRoute.setlistDetail);
      expect(ui.state.activeSetlist?.id, 'advance');
    },
  );

  test('new setlist navigation invalidates a pending next action', () async {
    final gate = gatePreferences();
    await _saveAdvanceSetlist(app);
    await ui.openSetlistEntry('advance', 'first');
    await ui.transpose(2);

    final advancing = ui.nextSong();
    await gate.started.future;
    await ui.openSetlist('set');
    gate.release();
    await advancing;

    expect(ui.state.route, VerseRoute.setlistDetail);
    expect(ui.state.activeSetlist?.id, 'set');
  });

  test('the latest song open wins when both wait on the same flush', () async {
    final gate = gatePreferences();
    await ui.openSong('a');
    await ui.transpose(2);

    final older = ui.openSong('b');
    await gate.started.future;
    final newer = ui.openSong('c');
    gate.release();
    await Future.wait([older, newer]);

    expect(ui.state.route, VerseRoute.reader);
    expect(ui.state.song?.id, 'c');
  });

  test(
    'dispose invalidates an open waiting for its preference flush',
    () async {
      final gate = gatePreferences();
      await ui.openSong('a');
      await ui.transpose(2);

      final opening = ui.openSong('b');
      await gate.started.future;
      ui.dispose();
      uiDisposed = true;
      gate.release();
      await opening;

      expect(ui.state.route, VerseRoute.reader);
      expect(ui.state.song?.id, 'a');
    },
  );

  test('a normal navigation flush preserves reader preferences', () async {
    await ui.openSong('a');
    await ui.transpose(2);

    await ui.openSong('b');

    final saved = (await repository.getSong('a'))!;
    expect(saved.metadata['x_verse_player_transpose'], 2);
    expect(ui.state.song?.id, 'b');
  });

  test('a completed old editor save leaves a newer draft intact', () async {
    await ui.editSong('a');
    final transactionEntered = Completer<void>();
    final releaseTransaction = Completer<void>();
    final blocker = repository.database.transaction((_) async {
      transactionEntered.complete();
      await releaseTransaction.future;
    });
    await transactionEntered.future;

    final saving = ui.saveLyricsEdit(
      '{title: Updated}\n{artist: Artist}\n\n[D]Saved',
    );
    await ui.back();
    await ui.createSong();
    final draftId = ui.state.song?.id;
    releaseTransaction.complete();
    await blocker;
    await saving;

    expect((await repository.getSong('a'))?.body, '[D]Saved');
    expect(ui.state.route, VerseRoute.editor);
    expect(ui.state.editor?.isNew, isTrue);
    expect(ui.state.song?.id, draftId);
  });

  test(
    'an editor save completing after dispose does not mutate adapter state',
    () async {
      await ui.editSong('a');
      final transactionEntered = Completer<void>();
      final releaseTransaction = Completer<void>();
      final blocker = repository.database.transaction((_) async {
        transactionEntered.complete();
        await releaseTransaction.future;
      });
      await transactionEntered.future;

      final saving = ui.saveLyricsEdit(
        '{title: Updated}\n{artist: Artist}\n\n[D]Saved',
      );
      ui.dispose();
      uiDisposed = true;
      releaseTransaction.complete();
      await blocker;
      await saving;

      expect((await repository.getSong('a'))?.body, '[D]Saved');
      expect(ui.state.route, VerseRoute.editor);
      expect(ui.state.song?.id, 'a');
    },
  );

  test('conflicted setlist removal has no undo or success outcome', () async {
    await ui.editSetlist('set');
    final notices = <UiNotice>[];
    final subscription = ui.notices.listen(notices.add);
    await app.saveSetlist(
      SetlistDocument(
        id: 'set',
        name: 'Synced',
        entries: const [SetlistEntry(id: 'entry', songId: 'a')],
      ),
    );
    notices.clear();

    final removed = await ui.removeSetlistEntryWithUndo('set', 'entry');
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(removed, isNull);
    expect(app.setlists.firstWhere((item) => item.id == 'set').name, 'Synced');
    expect(
      app.setlists.firstWhere((item) => item.id == 'set').entries,
      hasLength(1),
    );
    expect(
      app.setlists,
      hasLength(2),
    ); // The attempted edit is retained safely.
    expect(notices, contains(UiNotice.setlistSaveConflict));
  });

  test('an in-place setlist removal still returns undo data', () async {
    await ui.openSetlist('set');

    final removed = await ui.removeSetlistEntryWithUndo('set', 'entry');

    expect(removed?.entryId, 'entry');
    expect(app.setlists.single.entries, isEmpty);
  });
}

class _PreferenceGate {
  _PreferenceGate(this.app);

  final AppController app;
  final started = Completer<void>();
  final _release = Completer<void>();

  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  Future<void> write(String id, int transpose, double speed) async {
    if (!started.isCompleted) started.complete();
    await _release.future;
    await app.savePlayerPreferences(
      id,
      transpose: transpose,
      playbackSpeed: speed,
    );
  }
}

Future<void> _saveSong(AppController app, String id) => app.saveSong(
  SongDocument(id: id, title: 'Song $id', artist: 'Artist', body: '[C]Words'),
);

Future<void> _saveAdvanceSetlist(AppController app) => app.saveSetlist(
  SetlistDocument(
    id: 'advance',
    name: 'Advance',
    entries: const [
      SetlistEntry(id: 'first', songId: 'a'),
      SetlistEntry(id: 'second', songId: 'b'),
    ],
  ),
);
