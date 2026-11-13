import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';

/// Everything the UI reads from the cached library, in order.
Map<String, Object?> _cacheOf(AppController controller) => {
  'songs': [
    for (final song in controller.songs)
      {'json': jsonEncode(song.toJson()), 'hash': controller.songHash(song.id)},
  ],
  'setlists': [
    for (final setlist in controller.setlists)
      {
        'json': jsonEncode(setlist.toJson()),
        'hash': controller.setlistHash(setlist.id),
      },
  ],
};

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late _CountingRepository counting;
  late AppController controller;

  AppController open() => AppController(
    repository: counting,
    discovery: SourceDiscoveryService(const []),
  );

  /// What a controller that reads the whole library from scratch publishes.
  Future<Map<String, Object?>> fullReload() async {
    final fresh = AppController(
      repository: repository,
      discovery: SourceDiscoveryService(const []),
    );
    try {
      await fresh.initialize();
      return _cacheOf(fresh);
    } finally {
      fresh.dispose();
    }
  }

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    counting = _CountingRepository(repository);
    for (var i = 0; i < 6; i++) {
      await repository.saveSong(
        SongDocument(
          id: 'song-$i',
          title: 'Song $i',
          artist: 'Artist',
          body: '[C]Line $i\n[G]More',
          updatedAt: DateTime.utc(2026, 1, 1 + i),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
    }
    for (var i = 0; i < 3; i++) {
      await repository.saveSetlist(
        SetlistDocument(
          id: 'set-$i',
          name: 'Set $i',
          entries: [SetlistEntry(id: 'entry-$i', songId: 'song-$i')],
          updatedAt: DateTime.utc(2026, 2, 1 + i),
          createdAt: DateTime.utc(2026, 2, 1),
        ),
      );
    }
    controller = open();
    await controller.initialize();
    counting.snapshots = 0;
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  group('a favorite toggle patches one song', () {
    test('and publishes exactly what a full reload would', () async {
      final untouched = controller.findSong('song-4')!;
      for (final id in ['song-2', 'song-5', 'song-0', 'song-2']) {
        await controller.toggleFavorite(controller.findSong(id)!);
        expect(_cacheOf(controller), await fullReload(), reason: id);
      }
      expect(controller.findSong('song-5')!.favorite, isTrue);
      expect(controller.findSong('song-2')!.favorite, isFalse);
      expect(counting.snapshots, 0, reason: 'the library was not re-read');
      expect(identical(controller.findSong('song-4'), untouched), isTrue);
    });

    test('keeps the display keys of the song', () async {
      final before = controller.findSong('song-1')!;
      final keys = controller.displayKeysFor(before);
      expect(keys, isNotNull);
      final revision = controller.songDisplayKeysRevision;
      await controller.toggleFavorite(before);
      final after = controller.findSong('song-1')!;
      expect(identical(after, before), isFalse);
      expect(controller.displayKeysFor(after), keys);
      expect(controller.songDisplayKeysRevision, greaterThan(revision));
    });

    test('the patched hash is the one a later save is checked against', () async {
      await controller.toggleFavorite(controller.findSong('song-3')!);
      final toggled = controller.findSong('song-3')!;
      expect(
        await controller.saveSong(toggled.copyWith(body: 'Edited')),
        isTrue,
        reason: 'no conflict copy after an in-place favorite patch',
      );
      expect(controller.songs.where((song) => song.id.contains('conflict')), [
      ]);
      expect(controller.songs, hasLength(6));
      expect(_cacheOf(controller), await fullReload());
    });

    test('falls back to a full reload when the row cannot be read', () async {
      counting.failPlayableReads = true;
      // The toggle itself reads the playable song; make only the patch fail.
      counting.playableReadsBeforeFailure = 1;
      await controller.toggleFavorite(controller.findSong('song-2')!);
      expect(counting.snapshots, 1);
      counting.failPlayableReads = false;
      expect(controller.findSong('song-2')!.favorite, isTrue);
      expect(_cacheOf(controller), await fullReload());
    });

    test('a song deleted elsewhere still clears the stale cache', () async {
      final stale = controller.findSong('song-2')!;
      await repository.deleteSong(stale.id);
      await controller.toggleFavorite(stale);
      expect(controller.findSong(stale.id), isNull);
      expect(_cacheOf(controller), await fullReload());
    });
  });

  group('setlist writes refresh only the setlists', () {
    test('and publish exactly what a full reload would', () async {
      final songsBefore = controller.songs;

      await controller.addToSetlist('song-3', 'set-0');
      expect(_cacheOf(controller), await fullReload(), reason: 'add');

      await controller.toggleSetlistFavorite(
        controller.setlists.firstWhere((set) => set.id == 'set-1'),
      );
      expect(_cacheOf(controller), await fullReload(), reason: 'favorite');

      final edited = controller.setlists.firstWhere((set) => set.id == 'set-2');
      expect(
        await controller.saveSetlist(
          SetlistDocument(
            id: edited.id,
            name: 'Renamed',
            notes: 'notes',
            entries: edited.entries,
            favorite: edited.favorite,
            createdAt: edited.createdAt,
          ),
        ),
        isTrue,
      );
      expect(_cacheOf(controller), await fullReload(), reason: 'save');

      expect(
        await controller.saveSetlist(SetlistDocument(id: 'new', name: 'New')),
        isTrue,
      );
      expect(_cacheOf(controller), await fullReload(), reason: 'create');

      // A stale base hash stores a conflict copy next to the original.
      expect(
        await controller.saveSetlist(
          SetlistDocument(id: 'set-2', name: 'Stale edit'),
          baseHash: 'stale',
        ),
        isFalse,
      );
      expect(controller.setlists, hasLength(5));
      expect(_cacheOf(controller), await fullReload(), reason: 'conflict');

      await controller.deleteSetlist('set-0');
      expect(controller.setlists.any((set) => set.id == 'set-0'), isFalse);
      expect(_cacheOf(controller), await fullReload(), reason: 'delete');

      expect(counting.snapshots, 0, reason: 'the library was not re-read');
      expect(identical(controller.songs, songsBefore), isTrue);
    });

    test('concurrent setlist writes all end up published', () async {
      await Future.wait([
        controller.addToSetlist('song-1', 'set-0'),
        controller.addToSetlist('song-2', 'set-1'),
        controller.saveSetlist(SetlistDocument(id: 'other', name: 'Other')),
        controller.deleteSetlist('set-2'),
      ]);
      expect(_cacheOf(controller), await fullReload());
    });

    test('a setlist write during a library reload reloads the library', () async {
      await repository.saveSong(
        SongDocument(id: 'external', title: 'External', artist: '', body: 'x'),
      );
      await Future.wait([
        controller.toggleFavorite(controller.findSong('song-0')!),
        controller.saveSong(
          SongDocument(id: 'fresh', title: 'Fresh', artist: '', body: 'y'),
        ),
        controller.addToSetlist('song-4', 'set-1'),
      ]);
      expect(_cacheOf(controller), await fullReload());
    });

    test('falls back to a full reload when the list cannot be read', () async {
      counting.failSetlistLists = true;
      await controller.addToSetlist('song-3', 'set-0');
      counting.failSetlistLists = false;
      expect(counting.snapshots, 1);
      expect(_cacheOf(controller), await fullReload());
    });
  });

  group('a refresh that fails after a committed write', () {
    test('does not turn the save into an error or a later conflict', () async {
      final original = controller.findSong('song-1')!;
      counting.failSnapshots = 1;

      expect(
        await controller.saveSong(original.copyWith(body: 'First edit')),
        isTrue,
        reason: 'the write committed',
      );
      expect(controller.lastErrorCode, isNull);
      expect(controller.findSong('song-1')!.body, 'First edit');

      // The editor saves again from what the controller now publishes.
      expect(
        await controller.saveSong(
          controller.findSong('song-1')!.copyWith(body: 'Second edit'),
        ),
        isTrue,
      );
      expect((await repository.getSong('song-1'))!.body, 'Second edit');
      expect(
        (await repository.listSongs()).where(
          (song) => song.extra['syncConflict'] != null,
        ),
        isEmpty,
        reason: 'no conflict copy of the user\'s own save',
      );
      expect(_cacheOf(controller), await fullReload());
    });

    test('still reports a write that really failed', () async {
      counting.failSaves = true;
      await expectLater(
        controller.saveSong(
          controller.findSong('song-1')!.copyWith(body: 'Lost'),
        ),
        throwsStateError,
      );
      expect(controller.lastErrorCode, isNotNull);
      expect((await repository.getSong('song-1'))!.body, isNot('Lost'));
    });
  });
}

/// The real repository, counting library reads and failing on request.
class _CountingRepository implements LibraryRepository {
  _CountingRepository(this.delegate);

  final LibraryRepository delegate;
  int snapshots = 0, failSnapshots = 0;
  bool failPlayableReads = false, failSetlistLists = false, failSaves = false;
  int playableReadsBeforeFailure = 0;

  @override
  Database get database => delegate.database;

  @override
  Future<dynamic> getSetting(String key) => delegate.getSetting(key);

  @override
  Future<
    ({
      List<SongDocument> songs,
      List<SetlistDocument> setlists,
      Map<String, String> songHashes,
    })
  >
  librarySnapshot() {
    snapshots++;
    if (failSnapshots > 0) {
      failSnapshots--;
      throw StateError('snapshot unavailable');
    }
    return delegate.librarySnapshot();
  }

  @override
  Future<bool> saveSongIfUnchanged(
    SongDocument song,
    String? expectedHash, {
    bool mustNotExist = false,
    bool mustExist = false,
  }) {
    if (failSaves) throw StateError('write failed');
    return delegate.saveSongIfUnchanged(
      song,
      expectedHash,
      mustNotExist: mustNotExist,
      mustExist: mustExist,
    );
  }

  @override
  Future<void> saveSong(SongDocument song) => delegate.saveSong(song);

  @override
  Future<String?> getSongEditHash(String id) => delegate.getSongEditHash(id);

  @override
  Future<SongDocument?> getPlayableSong(String id) {
    if (failPlayableReads && playableReadsBeforeFailure-- <= 0) {
      throw StateError('row unavailable');
    }
    return delegate.getPlayableSong(id);
  }

  @override
  Future<List<SetlistDocument>> listSetlists({
    String query = '',
    bool favoritesOnly = false,
  }) {
    if (failSetlistLists) throw StateError('setlists unavailable');
    return delegate.listSetlists(query: query, favoritesOnly: favoritesOnly);
  }

  @override
  Future<SetlistDocument?> getSetlist(String id) => delegate.getSetlist(id);

  @override
  Future<void> saveSetlist(SetlistDocument setlist) =>
      delegate.saveSetlist(setlist);

  @override
  Future<bool> saveSetlistIfUnchanged(
    SetlistDocument setlist,
    String? expectedHash, {
    bool mustNotExist = false,
    bool mustExist = false,
  }) => delegate.saveSetlistIfUnchanged(
    setlist,
    expectedHash,
    mustNotExist: mustNotExist,
    mustExist: mustExist,
  );

  @override
  Future<String?> saveSetlistIfUnchangedWithHash(
    SetlistDocument setlist,
    String? expectedHash, {
    bool mustNotExist = false,
    bool mustExist = false,
  }) => delegate.saveSetlistIfUnchangedWithHash(
    setlist,
    expectedHash,
    mustNotExist: mustNotExist,
    mustExist: mustExist,
  );

  @override
  Future<void> deleteSetlist(String id) => delegate.deleteSetlist(id);

  @override
  Future<List<ActivityEntry>> listRecentActivity({
    int limit = 50,
    int offset = 0,
  }) => delegate.listRecentActivity(limit: limit, offset: offset);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
