import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/sync/google_drive_sync.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';
import '../sync/support.dart';

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

  Future<void> saveTwoSongs() async {
    await app.saveSong(_song('a', 'Alpha'));
    await app.saveSong(_song('b', 'Beta'));
  }

  group('state cache', () {
    test('repeated reads reuse one state until something changes', () async {
      await saveTwoSongs();
      final first = ui.state;
      final builds = ui.stateBuildCount;
      for (var i = 0; i < 20; i++) {
        expect(identical(ui.state, first), isTrue);
        ui.state.songs;
        ui.state.recent;
      }
      expect(ui.stateBuildCount, builds, reason: 'no recomputation');

      ui.toggleSearchFilters();
      final changed = ui.state;
      expect(changed.searchFiltersExpanded, isTrue);
      expect(ui.stateBuildCount, builds + 1);
      expect(identical(ui.state, changed), isTrue);
      expect(ui.stateBuildCount, builds + 1);
    });

    test('a controller change invalidates the cached state', () async {
      await saveTwoSongs();
      final before = ui.state.songs.length;
      final builds = ui.stateBuildCount;
      await app.saveSong(_song('c', 'Gamma'));
      expect(ui.state.songs.length, before + 1);
      expect(ui.stateBuildCount, greaterThan(builds));
    });

    test('playback ticks and seeks do not notify or rebuild state', () async {
      await app.saveSong(_song('a', 'Alpha', body: _longBody));
      await ui.openSong('a');
      final base = ui.state;
      final builds = ui.stateBuildCount;
      var notifications = 0;
      ui.addListener(() => notifications++);
      final positions = <PlayerPosition>[];
      ui.playerPosition.addListener(
        () => positions.add(ui.playerPosition.value),
      );

      await ui.seek(10);
      await ui.seek(40);
      expect(notifications, 0);
      expect(ui.stateBuildCount, builds);
      expect(ui.state.progressSeconds, 40);
      expect(ui.state.currentLineId, isNotNull);
      // The large lists are shared, not rebuilt.
      expect(identical(ui.state.songLines, base.songLines), isTrue);
      expect(identical(ui.state.songs, base.songs), isTrue);
      expect(positions, hasLength(2));

      await ui.playPause();
      notifications = 0;
      ui.advancePlayerBy(3);
      ui.advancePlayerBy(3);
      expect(notifications, 0);
      expect(ui.stateBuildCount, builds + 1, reason: 'only play toggled');
      expect(ui.state.progressSeconds, 46);
      await ui.playPause();
      expect(ui.state.isPlaying, isFalse);
    });

    test('playing stops at the end and playback needs an open song', () async {
      await ui.playPause();
      expect(ui.state.isPlaying, isFalse);

      await app.saveSong(
        _song('a', 'Alpha', metadata: const {'durationSeconds': 10}),
      );
      await ui.openSong('a');
      await ui.playPause();
      expect(ui.state.isPlaying, isTrue);
      ui.advancePlayerBy(30);
      expect(ui.state.progressSeconds, 10);
      expect(ui.state.isPlaying, isFalse);
    });
  });

  group('setlists', () {
    test(
      'creating a setlist with a song adds it under the given name',
      () async {
        await saveTwoSongs();
        await ui.createSetlist(name: 'Nouveau', songId: 'a');
        final setlist = app.setlists.single;
        expect(setlist.name, 'Nouveau');
        expect(setlist.entries.map((e) => e.songId), ['a']);
        expect(ui.state.route, VerseRoute.main, reason: 'stays where it was');
      },
    );

    test('creating without a song opens the new setlist', () async {
      await ui.createSetlist(name: 'Fresh');
      expect(ui.state.route, VerseRoute.setlistDetail);
      expect(ui.state.activeSetlist?.title, 'Fresh');
    });

    test('duplicates use the supplied localized name', () async {
      await saveTwoSongs();
      await ui.createSetlist(name: 'Set', songId: 'a');
      await ui.duplicateSetlist(
        app.setlists.single.id,
        copyName: 'Set (копие)',
      );
      expect(
        app.setlists.map((s) => s.name),
        containsAll(['Set', 'Set (копие)']),
      );
    });

    test(
      'saving details while editing keeps edit mode and typed text',
      () async {
        await saveTwoSongs();
        await app.addToSetlist('a', await _newSetlist(app));
        await app.addToSetlist('b', app.setlists.single.id);
        final setlist = app.setlists.single;
        await ui.editSetlist(setlist.id);
        expect(ui.state.editingSetlist, isTrue);

        final order = setlist.entries
            .map((e) => e.id)
            .toList()
            .reversed
            .toList();
        await ui.saveSetlistDetails(
          name: 'Typed name',
          notes: 'Typed notes',
          entryOrder: order,
        );
        expect(
          ui.state.editingSetlist,
          isTrue,
          reason: 'reorder keeps editing',
        );
        expect(app.setlists.single.name, 'Typed name');
        expect(app.setlists.single.notes, 'Typed notes');
        expect(app.setlists.single.entries.map((e) => e.id), order);

        await ui.removeSetlistEntry(
          setlist.id,
          order.first,
          name: 'Typed again',
          notes: 'More notes',
        );
        expect(ui.state.editingSetlist, isTrue);
        expect(app.setlists.single.name, 'Typed again');
        expect(app.setlists.single.notes, 'More notes');
        expect(app.setlists.single.entries, hasLength(1));

        await ui.saveSetlistDetails(name: ' ', notes: 'x', finishEditing: true);
        expect(ui.state.editingSetlist, isFalse);
        expect(
          app.setlists.single.name,
          'Typed again',
          reason: 'blank keeps name',
        );
      },
    );

    test(
      'undo restores a removed entry with its id, position, and overrides',
      () async {
        await saveTwoSongs();
        await app.saveSong(_song('c', 'Gamma'));
        await app.saveSong(_song('d', 'Delta'));
        await app.saveSetlist(
          SetlistDocument(
            id: 'undo-list',
            name: 'Undo list',
            entries: const [
              SetlistEntry(id: 'first', songId: 'a'),
              SetlistEntry(
                id: 'removed',
                songId: 'b',
                overrides: {
                  'key': 'D',
                  'capo': 2,
                  'repeat': 3,
                  'note': 'intro',
                },
              ),
              SetlistEntry(id: 'last', songId: 'c'),
            ],
          ),
        );

        final removed = await ui.removeSetlistEntryWithUndo(
          'undo-list',
          'removed',
        );
        expect(removed, isNotNull);
        expect(app.setlists.single.entries.map((entry) => entry.id), [
          'first',
          'last',
        ]);

        // A change made while the Undo action is visible must be kept.
        await app.addToSetlist('d', 'undo-list');
        final addedEntryId = app.setlists.single.entries.last.id;

        await ui.restoreSetlistEntry(removed!);
        final entries = app.setlists.single.entries;
        expect(entries.map((entry) => entry.id), [
          'first',
          'removed',
          'last',
          addedEntryId,
        ]);
        expect(entries[1].songId, 'b');
        expect(entries[1].overrides, {
          'key': 'D',
          'capo': 2,
          'repeat': 3,
          'note': 'intro',
        });
      },
    );

    test(
      'entry overrides keep other overrides and clear emptied ones',
      () async {
        await app.saveSong(_song('a', 'Alpha'));
        await app.saveSetlist(
          SetlistDocument(
            id: 's',
            name: 'S',
            entries: const [
              SetlistEntry(
                id: 'e',
                songId: 'a',
                overrides: {'key': 'D', 'capo': 2, 'note': 'keep'},
              ),
            ],
          ),
        );
        await ui.openSetlist('s');
        await ui.saveSetlistEntryOverrides('s', 'e', key: '', capo: '3');
        final overrides = app.setlists.single.entries.single.overrides;
        expect(overrides, {'capo': 3, 'note': 'keep'});
        final entry = ui.state.activeSetlist!.entries.single;
        expect(entry.keyOverride, isNull);
        expect(entry.capoOverride, '3');
      },
    );

    test('entries whose song is gone are reported as missing', () async {
      await app.saveSong(_song('a', 'Alpha'));
      await app.saveSetlist(
        SetlistDocument(
          id: 's',
          name: 'S',
          entries: const [SetlistEntry(id: 'e1', songId: 'a')],
        ),
      );
      // The database forbids dangling references, but synced or imported data
      // can leave one in memory; simulate that.
      app.setlists = [
        SetlistDocument(
          id: 's',
          name: 'S',
          entries: const [
            SetlistEntry(id: 'e1', songId: 'a'),
            SetlistEntry(id: 'e2', songId: 'gone'),
          ],
        ),
      ];
      ui.toggleSearchFilters();
      final card = ui.state.setlists.single;
      expect(card.songTitles, ['Alpha', '']);
      expect(card.entries.map((e) => e.missing), [false, true]);

      await ui.openSetlist('s');
      await ui.removeSetlistEntry('s', 'e2');
      expect(app.setlists.single.entries.map((e) => e.id), ['e1']);
      expect(ui.state.setlists.single.entries.any((e) => e.missing), isFalse);
    });
  });

  group('history paging', () {
    test('overlapping loads fetch one page', () async {
      for (var i = 0; i < 100; i++) {
        await app.saveSong(_song('song-$i', 'Song $i'));
        await repository.addActivity(
          ActivityEntry(
            id: 'activity-$i',
            objectId: 'song-$i',
            objectKind: 'song',
            action: 'opened',
            occurredAt: DateTime.utc(2025, 1, 1).add(Duration(minutes: i)),
          ),
        );
      }
      app.recent = [];
      app.hasMoreRecent = true;
      final seenLoading = <bool>[];
      ui.addListener(() => seenLoading.add(ui.state.loadingMoreRecent));

      final first = ui.loadMoreRecent();
      final second = ui.loadMoreRecent();
      expect(ui.state.loadingMoreRecent, isTrue);
      await Future.wait([first, second]);

      expect(app.recent, hasLength(40));
      expect(ui.state.loadingMoreRecent, isFalse);
      expect(seenLoading, contains(true));
    });
  });

  group('notices', () {
    test('file actions report copy and failure outcomes', () async {
      await app.saveSong(_song('a', 'Alpha'));
      var copies = 0;
      final adapter = AppControllerAdapter(
        app,
        onCopySong: (_) async => copies++,
        onShareSong: (_) async => throw StateError('no share target'),
        onImport: () async => throw const FormatException('file_too_large'),
      );
      final notices = <UiNotice>[];
      final sub = adapter.notices.listen(notices.add);

      await adapter.copySongChordPro('a');
      await adapter.shareSong('a');
      await adapter.importChordPro();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      adapter.dispose();

      expect(copies, 1);
      expect(notices, [
        UiNotice.copied,
        UiNotice.exportFailed,
        UiNotice.importTooLarge,
      ]);
    });

    test('import errors map to specific notices', () async {
      final cases = <Object, UiNotice>{
        const FormatException('unsupported_file'): UiNotice.importUnsupported,
        const FormatException('empty_file'): UiNotice.importFailed,
        StateError('boom'): UiNotice.importFailed,
      };
      for (final entry in cases.entries) {
        final adapter = AppControllerAdapter(
          app,
          onImport: () async => throw entry.key,
        );
        final notices = <UiNotice>[];
        final sub = adapter.notices.listen(notices.add);
        await adapter.importChordPro();
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        adapter.dispose();
        expect(notices, [entry.value], reason: '${entry.key}');
      }
    });

    test(
      'dismissing the Drive picker is neither a banner nor a notice',
      () async {
        final sync = _DismissedPickerSync(repository);
        final cancelling = AppController(repository: repository, sync: sync);
        await cancelling.initialize();
        final adapter = AppControllerAdapter(cancelling);
        final notices = <UiNotice>[];
        final sub = adapter.notices.listen(notices.add);

        await adapter.chooseSyncDriveFolder();
        await adapter.importChordProFromDrive();
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        expect(sync.calls, 2);
        expect(notices, isEmpty);
        expect(adapter.state.accountError, isNull);
        expect(adapter.state.lastSyncErrorCode, isNull);
        adapter.dispose();
        cancelling.dispose();
      },
    );

    test('a failed Drive action still reports its error', () async {
      final sync = _DismissedPickerSync(repository, code: 'network');
      final failing = AppController(repository: repository, sync: sync);
      await failing.initialize();
      final adapter = AppControllerAdapter(failing);
      final notices = <UiNotice>[];
      final sub = adapter.notices.listen(notices.add);

      await adapter.chooseSyncDriveFolder();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(notices, [UiNotice.syncFailed]);
      expect(adapter.state.accountError, 'network');
      adapter.dispose();
      failing.dispose();
    });

    test('deleting a song and a setlist is reported', () async {
      await saveTwoSongs();
      await ui.createSetlist(name: 'Set', songId: 'a');
      final notices = <UiNotice>[];
      final sub = ui.notices.listen(notices.add);

      await ui.deleteSong('b');
      await ui.deleteSetlist(app.setlists.single.id);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(notices, [UiNotice.songDeleted, UiNotice.setlistDeleted]);
      expect(app.findSong('b'), isNull);
    });

    test(
      'saving the editor reports success and keeps validation to the UI',
      () async {
        await app.saveSong(_song('a', 'Alpha'));
        await ui.editSong('a');
        expect(ui.state.editor?.title, 'Alpha');
        expect(ui.state.editor?.isNew, isFalse);
        ui.setEditorDirty(true);
        expect(ui.state.editorDirty, isTrue);
        final notices = <UiNotice>[];
        final sub = ui.notices.listen(notices.add);

        await ui.saveLyricsEdit('{title: Alpha 2}\n{artist: A}\n\n[C]Words');
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        expect(notices, [UiNotice.editorSaved]);
        // Edited from the list, so saving returns to the list, not a reader.
        expect(ui.state.route, VerseRoute.main);
        expect(ui.state.song, isNull);
        expect(ui.state.editorDirty, isFalse);
        expect(ui.state.editor, isNull);
        expect(app.findSong('a')?.title, 'Alpha 2');
      },
    );

    test('back from a dirty new-song editor discards the draft', () async {
      await ui.createSong();
      expect(ui.state.route, VerseRoute.editor);
      expect(ui.state.editor?.isNew, isTrue);
      ui.setEditorDirty(true);
      await ui.back();
      expect(ui.state.route, VerseRoute.main);
      expect(ui.state.editorDirty, isFalse);
      expect(app.songs, isEmpty);
    });
  });

  test('async work finishing after dispose does not notify', () async {
    final adapter = AppControllerAdapter(app);
    final pending = adapter.submitSearch();
    adapter.dispose();
    await pending;
    // No "used after being disposed" error and no leaked notifications.
    expect(adapter.notices, isNotNull);
  });
}

Future<String> _newSetlist(AppController app) async {
  // This fixture needs a stored setlist, not the creation form's private draft.
  await app.saveSetlist(SetlistDocument(id: 'stored-setlist', name: 'Set'));
  return 'stored-setlist';
}

const _longBody =
    '[C]One\n[G]Two\n[Am]Three\n[F]Four\n[C]Five\n[G]Six\n[Am]Seven\n[F]Eight';

SongDocument _song(
  String id,
  String title, {
  String body = '[C]First line\n[G]Second line',
  JsonMap metadata = const {},
}) => SongDocument(
  id: id,
  title: title,
  artist: 'Artist',
  body: body,
  metadata: metadata,
);

/// A sync service whose Drive actions end the way the system picker does
/// when it is dismissed: by throwing a sync error code.
class _DismissedPickerSync extends GoogleDriveSyncService {
  _DismissedPickerSync(LibraryRepository repository, {this.code = 'cancelled'})
    : super(
        repository: repository,
        auth: FakeAuth()..connected = true,
        store: MemoryCloud(),
      );

  final String code;
  int calls = 0;

  @override
  DriveFolderInfo? get selectedDriveFolder =>
      const DriveFolderInfo(id: 'folder', name: 'Folder');
  @override
  set selectedDriveFolder(DriveFolderInfo? value) {}

  @override
  Future<DriveFolderInfo> chooseVisibleDriveFolder() async {
    calls++;
    throw SyncException(code);
  }

  @override
  Future<int> importChordProFilesFromDrive() async {
    calls++;
    throw SyncException(code);
  }
}
