import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/ui/app_controller_adapter.dart';

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
    await ui.settlePlayerPreferences();
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  test('an in-flight preference write flushes the latest pair once', () async {
    await _saveSong(app, 'a');
    await ui.openSong('a');

    final transactionEntered = Completer<void>();
    final releaseTransaction = Completer<void>();
    final blocker = repository.database.transaction((_) async {
      transactionEntered.complete();
      await releaseTransaction.future;
    });
    await transactionEntered.future;

    await ui.transpose(2);
    await ui.setPlaybackSpeed(1.4);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final firstFlush = ui.settlePlayerPreferences();

    // The flush is blocked behind the transaction. Later input must replace
    // the queued values without starting a competing write from an old pair.
    await ui.transpose(-1);
    await ui.setPlaybackSpeed(.8);
    final secondFlush = ui.settlePlayerPreferences();

    releaseTransaction.complete();
    await blocker;
    await Future.wait([firstFlush, secondFlush]);

    final saved = await repository.getSong('a');
    expect(saved!.metadata['x_verse_player_transpose'], 1);
    expect(saved.metadata['x_verse_player_speed'], .8);
    expect((await repository.listSongs()).map((song) => song.id), ['a']);
  });

  test('a newer revision retries after an in-flight save fails', () async {
    await _saveSong(app, 'a');
    ui.dispose();

    final firstStarted = Completer<void>();
    final releaseFirst = Completer<void>();
    var calls = 0;
    var activeCalls = 0;
    var maxActiveCalls = 0;
    ui = AppControllerAdapter(
      app,
      onSavePlayerPreferences: (id, transpose, speed) async {
        calls++;
        activeCalls++;
        if (activeCalls > maxActiveCalls) maxActiveCalls = activeCalls;
        try {
          if (calls == 1) {
            firstStarted.complete();
            await releaseFirst.future;
            throw StateError('temporary write failure');
          }
          await app.savePlayerPreferences(
            id,
            transpose: transpose,
            playbackSpeed: speed,
          );
        } finally {
          activeCalls--;
        }
      },
    );
    await ui.openSong('a');
    await ui.transpose(2);

    final originalFlush = ui.settlePlayerPreferences();
    await firstStarted.future;
    await ui.transpose(1);
    await ui.setPlaybackSpeed(.8);
    // The newer debounce reuses the in-flight flush. Once that write fails,
    // the drain must still notice and save the newer revision.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    releaseFirst.complete();
    await originalFlush;

    final saved = (await repository.getSong('a'))!;
    expect(calls, 2);
    expect(maxActiveCalls, 1);
    expect(saved.metadata['x_verse_player_transpose'], 3);
    expect(saved.metadata['x_verse_player_speed'], .8);
  });

  test('a debounced write stays with its song after switching songs', () async {
    await _saveSong(app, 'a');
    await _saveSong(app, 'b');
    await ui.openSong('a');

    final transactionEntered = Completer<void>();
    final releaseTransaction = Completer<void>();
    final blocker = repository.database.transaction((_) async {
      transactionEntered.complete();
      await releaseTransaction.future;
    });
    await transactionEntered.future;

    await ui.transpose(3);
    await ui.setPlaybackSpeed(1.25);
    // Let the debounced save enter the database and hold it there while the
    // reader changes songs.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final pendingSongAWrite = ui.settlePlayerPreferences();
    final openingSongB = ui.openSong('b');

    releaseTransaction.complete();
    await blocker;
    await openingSongB;
    await pendingSongAWrite;

    await ui.transpose(-2);
    await ui.setPlaybackSpeed(.75);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await ui.settlePlayerPreferences();

    final songA = (await repository.getSong('a'))!;
    final songB = (await repository.getSong('b'))!;
    expect(songA.metadata['x_verse_player_transpose'], 3);
    expect(songA.metadata['x_verse_player_speed'], 1.25);
    expect(songB.metadata['x_verse_player_transpose'], -2);
    expect(songB.metadata['x_verse_player_speed'], .75);
  });

  test('saved preferences reload when a song is opened again', () async {
    await _saveSong(app, 'a');
    await ui.openSong('a');
    await ui.transpose(4);
    await ui.setPlaybackSpeed(1.5);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await ui.settlePlayerPreferences();

    await ui.openSong('a');
    expect(ui.state.readerKey, 'E');
    expect(ui.state.playbackSpeed, 1.5);

    ui.dispose();
    app.dispose();
    app = AppController(repository: repository);
    await app.initialize();
    ui = AppControllerAdapter(app);
    await ui.openSong('a');
    expect(ui.state.readerKey, 'E');
    expect(ui.state.playbackSpeed, 1.5);
  });

  test(
    'preference updates preserve newer song data and favorite state',
    () async {
      await _saveSong(app, 'a');
      await ui.openSong('a');
      await ui.transpose(2);
      await ui.setPlaybackSpeed(1.2);

      final current = app.findSong('a')!;
      await app.saveSong(
        current.copyWith(
          body: '[D]Updated lyric',
          metadata: {...current.metadata, 'newMetadata': 'kept'},
          favorite: true,
        ),
      );
      await ui.settlePlayerPreferences();

      final saved = (await repository.getSong('a'))!;
      expect(saved.body, '[D]Updated lyric');
      expect(saved.favorite, isTrue);
      expect(saved.metadata['newMetadata'], 'kept');
      expect(saved.metadata['x_verse_player_transpose'], 2);
      expect(saved.metadata['x_verse_player_speed'], 1.2);
    },
  );

  test(
    'editing waits for queued preferences before taking its save hash',
    () async {
      await _saveSong(app, 'a');
      await ui.openSong('a');
      await ui.transpose(2);
      await ui.setPlaybackSpeed(1.2);

      await ui.editSong('a');
      await ui.saveLyricsEdit(
        ui.editableChordPro.replaceFirst('Original lyric', 'Edited lyric'),
      );

      final saved = (await repository.getSong('a'))!;
      expect(saved.body, '[C]Edited lyric');
      expect(saved.metadata['x_verse_player_transpose'], 2);
      expect(saved.metadata['x_verse_player_speed'], 1.2);
      expect((await repository.listSongs()).map((song) => song.id), ['a']);
    },
  );

  test(
    'leaving the reader still flushes its captured song preferences',
    () async {
      await _saveSong(app, 'a');
      await ui.openSong('a');
      await ui.transpose(-3);
      await ui.setPlaybackSpeed(.9);

      await ui.back();
      await ui.settlePlayerPreferences();

      final saved = (await repository.getSong('a'))!;
      expect(saved.metadata['x_verse_player_transpose'], -3);
      expect(saved.metadata['x_verse_player_speed'], .9);
    },
  );

  test('a pending preference update cannot resurrect a deleted song', () async {
    await _saveSong(app, 'a');
    await ui.openSong('a');
    await ui.transpose(2);
    await ui.setPlaybackSpeed(1.2);
    await app.deleteSong('a');

    await ui.settlePlayerPreferences();

    expect(await repository.getSong('a'), isNull);
    expect((await repository.listSongs()), isEmpty);
  });

  test('compare-and-set can require the song to still exist', () async {
    await _saveSong(app, 'a');
    final original = (await repository.getSong('a'))!;
    final originalHash = await repository.getSongHash('a');
    await repository.deleteSong('a');
    final deleteOutboxMark = await repository.outboxMark();

    expect(
      await repository.saveSongIfUnchanged(
        original,
        originalHash,
        mustExist: true,
      ),
      isFalse,
    );
    expect(await repository.getSong('a'), isNull);
    expect(await repository.outboxMark(), deleteOutboxMark);
  });

  test('must-exist still permits an existing row with a null hash', () async {
    await _saveSong(app, 'a');
    final original = (await repository.getSong('a'))!;

    expect(
      await repository.saveSongIfUnchanged(
        original.copyWith(body: '[D]Updated lyric'),
        null,
        mustExist: true,
      ),
      isTrue,
    );
    expect((await repository.getSong('a'))!.body, '[D]Updated lyric');
  });

  test('invalid stored player preferences fall back to defaults', () async {
    await _saveSong(
      app,
      'a',
      metadata: const {
        'key': 'C',
        'x_verse_player_transpose': 'not an integer',
        'x_verse_player_speed': 4.0,
      },
    );

    await ui.openSong('a');

    expect(ui.state.readerKey, 'C');
    expect(ui.state.playbackSpeed, 1);
  });
}

Future<void> _saveSong(
  AppController app,
  String id, {
  JsonMap metadata = const {'key': 'C'},
}) async {
  await app.saveSong(
    SongDocument(
      id: id,
      title: 'Song $id',
      artist: 'Test Artist',
      body: '[C]Original lyric',
      metadata: metadata,
    ),
  );
}
