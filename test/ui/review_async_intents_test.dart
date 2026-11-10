import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/combine_runner.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
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
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([]),
    );
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

  test(
    'saving a discovered chart opens while unrelated player preferences are pending',
    () async {
      final gate = gatePreferences();
      await ui.openSong('a');
      await ui.transpose(2);
      final pendingPreferences = ui.settlePlayerPreferences();
      await gate.started.future;
      try {
        await ui.back();
        const candidate = SongCandidate(
          providerId: 'fixture',
          id: 'new-song',
          title: 'New song',
          artist: 'Artist',
        );
        const result = SourceResult(
          candidate: candidate,
          body: '[G]Discovered words',
          matchKind: MatchKind.sameRecording,
        );
        await app.selectCandidate(candidate);
        app.results = [result];
        ui.selectVersion(result.id);

        await ui.saveSelectedVersion().timeout(const Duration(seconds: 5));
        expect(ui.state.route, VerseRoute.reader);
        expect(ui.state.song?.title, 'New song');
      } finally {
        gate.release();
        await pendingPreferences;
      }
      final previous = await repository.getPlayableSong('a');
      expect(previous?.metadata['x_verse_player_transpose'], 2);
    },
  );

  test(
    'resaving a chart opens with pending preferences before Recent is written',
    () async {
      final gate = gatePreferences();
      await ui.openSong('a');
      await ui.transpose(2);
      await ui.setPlaybackSpeed(.8);
      final pendingPreferences = ui.settlePlayerPreferences();
      await gate.started.future;

      Future<void>? recentLock;
      final releaseRecent = Completer<void>();
      void blockRecentAfterNavigation() {
        if (ui.state.route != VerseRoute.reader || recentLock != null) return;
        recentLock = repository.database.transaction(
          (_) => releaseRecent.future,
        );
      }

      try {
        await ui.back();
        const candidate = SongCandidate(
          providerId: 'fixture',
          id: 'a',
          title: 'Song a',
          artist: 'Artist',
        );
        const result = SourceResult(
          candidate: candidate,
          body: '[G]Discovered words',
          matchKind: MatchKind.sameRecording,
        );
        await app.selectCandidate(candidate, cachedResults: [result]);
        ui.selectVersion(result.id);
        ui.addListener(blockRecentAfterNavigation);

        await ui.saveSelectedVersion().timeout(const Duration(seconds: 5));
        expect(recentLock, isNotNull);
        expect(ui.state.route, VerseRoute.reader);
        expect(ui.state.song?.id, 'a');
        expect(ui.state.readerTranspose, 2);
        expect(ui.state.playbackSpeed, .8);
        final rendered = ui.state.songLines.singleWhere(
          (line) => line.text == 'Discovered words',
        );
        expect(rendered.chords.single.symbol, 'A');
      } finally {
        ui.removeListener(blockRecentAfterNavigation);
        releaseRecent.complete();
        gate.release();
        await recentLock;
        await pendingPreferences;
        await ui.settleRecentRecords();
      }
      final stored = await repository.getPlayableSong('a');
      expect(stored?.body, '[G]Discovered words');
      expect(stored?.metadata['x_verse_player_transpose'], 2);
      expect(stored?.metadata['x_verse_player_speed'], .8);
      expect(app.recent.first.objectId, 'a');
      expect(app.recent.first.openCount, 2);
    },
  );

  test('Save opens the reader with its active timing projection', () async {
    const candidate = SongCandidate(
      providerId: 'fixture',
      id: 'timed',
      title: 'Timed song',
      artist: 'Artist',
    );
    final result = SourceResult(
      candidate: candidate,
      body: [
        '[G]First line',
        'Second line',
        for (var i = 0; i < 40; i++) 'A lyric line numbered $i',
      ].join('\n'),
      matchKind: MatchKind.sameRecording,
    );
    app.preferredArrangementPreparer = PreferredArrangementPreparer(
      compute:
          (
            request, {
            required sourceId,
            required compact,
            required allowRejectedPreferredSource,
          }) async => SongDocument(
            id: 'timed',
            title: candidate.title,
            artist: candidate.artist,
            body: result.body,
            selectedRecording: candidate,
            activeTimingTrackId: 'track',
            timingTracks: const [
              TimingTrack(
                id: 'track',
                sourceDocumentId: 'fixture',
                sourceLyrics: 'First line\nSecond line',
                format: 'lrc',
                status: TimingStatus.usable,
                cues: [
                  TimingCue(
                    id: 'cue',
                    occurrenceId: 'line-1',
                    text: 'Second line',
                    startUs: 0,
                  ),
                ],
              ),
            ],
          ),
    );
    app.settings['timingMode'] = 'timed';
    await app.selectCandidate(candidate, cachedResults: [result]);
    ui.selectVersion(result.id);
    final durationsBeforeOpen = <double?>[];
    void inspectPublishedCard() {
      final state = ui.state;
      if (state.route != VerseRoute.main) return;
      for (final card in state.songs.where((song) => song.id == 'timed')) {
        durationsBeforeOpen.add(card.durationSeconds);
      }
    }

    ui.addListener(inspectPublishedCard);
    try {
      await ui.saveSelectedVersion();
    } finally {
      ui.removeListener(inspectPublishedCard);
    }
    await ui.settleRecentRecords();
    expect(durationsBeforeOpen, isNotEmpty);
    expect(durationsBeforeOpen, everyElement(isNull));
    expect(ui.state.route, VerseRoute.reader);
    expect(ui.state.currentLineId, 'line-1');
    expect(ui.state.song?.durationSeconds, closeTo(142.8, .001));
    expect(
      ui.state.songs.singleWhere((song) => song.id == 'timed').durationSeconds,
      closeTo(142.8, .001),
    );
    expect(ui.state.readerDurationEstimated, isTrue);
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
