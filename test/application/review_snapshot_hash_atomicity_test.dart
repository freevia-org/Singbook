import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';

void main() {
  sqfliteFfiInit();

  test('reload never pairs stale song content with a newer hash', () async {
    final repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    final original = _song('Original');
    final newer = _song('External edit');
    await repository.saveSong(original);
    final originalHash = await repository.getSongHash(original.id);
    final interleaving = _SnapshotInterleavingRepository(repository)
      ..afterSnapshot = () => repository.saveSong(newer);
    final controller = AppController(
      repository: interleaving,
      discovery: SourceDiscoveryService(const []),
    );

    try {
      await controller.initialize();

      expect(controller.findSong(original.id)?.body, original.body);
      expect(controller.songHash(original.id), originalHash);

      final saved = await controller.saveSong(
        original.copyWith(body: 'User edit'),
        baseHash: controller.songHash(original.id),
      );
      expect(saved, isFalse);
      expect((await repository.getSong(original.id))?.body, newer.body);
    } finally {
      controller.dispose();
      await repository.close();
    }
  });
}

SongDocument _song(String body) => SongDocument(
  id: 'snapshot-song',
  title: 'Snapshot song',
  artist: 'Test artist',
  body: body,
);

/// Interleaves a direct database edit after the atomic snapshot is returned,
/// reproducing the point-in-time gap before AppController publishes that data.
class _SnapshotInterleavingRepository implements LibraryRepository {
  _SnapshotInterleavingRepository(this.delegate);

  final LibraryRepository delegate;
  Future<void> Function()? afterSnapshot;

  @override
  Database get database => delegate.database;

  @override
  Future<dynamic> getSetting(String key) => delegate.getSetting(key);

  @override
  Future<void> saveSong(SongDocument song) => delegate.saveSong(song);

  @override
  Future<bool> saveSongIfUnchanged(
    SongDocument song,
    String? expectedHash, {
    bool mustNotExist = false,
    bool mustExist = false,
  }) => delegate.saveSongIfUnchanged(
    song,
    expectedHash,
    mustNotExist: mustNotExist,
    mustExist: mustExist,
  );

  @override
  Future<
    ({
      List<SongDocument> songs,
      List<SetlistDocument> setlists,
      Map<String, String> songHashes,
    })
  >
  librarySnapshot() async {
    final snapshot = await delegate.librarySnapshot();
    final interleave = afterSnapshot;
    afterSnapshot = null;
    await interleave?.call();
    return snapshot;
  }

  @override
  Future<List<SongDocument>> listSongs({
    String query = '',
    bool favoritesOnly = false,
    int? limit,
    int offset = 0,
  }) async {
    final songs = await delegate.listSongs(
      query: query,
      favoritesOnly: favoritesOnly,
      limit: limit,
      offset: offset,
    );
    return songs;
  }

  @override
  Future<List<SetlistDocument>> listSetlists({
    String query = '',
    bool favoritesOnly = false,
  }) => delegate.listSetlists(query: query, favoritesOnly: favoritesOnly);

  @override
  Future<List<ActivityEntry>> listRecentActivity({
    int limit = 50,
    int offset = 0,
  }) => delegate.listRecentActivity(limit: limit, offset: offset);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
