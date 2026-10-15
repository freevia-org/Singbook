import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';

void main() {
  late LibraryRepository repository;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() => repository.close());

  Future<void> saveSong(String id, String title) => repository.saveSong(
    SongDocument(id: id, title: title, artist: 'Artist', body: 'Lyrics'),
  );

  Future<void> add(
    String id,
    String objectId, {
    String kind = 'song',
    String action = 'opened',
    required DateTime at,
  }) => repository.addActivity(
    ActivityEntry(
      id: id,
      objectId: objectId,
      objectKind: kind,
      action: action,
      occurredAt: at,
    ),
  );

  test(
    'groups repeated opens across days and paginates by song group',
    () async {
      await saveSong('song-a', 'Same title');
      await saveSong('song-b', 'Same title');
      await add('a-old', 'song-a', at: DateTime.utc(2026, 4, 1));
      await add('b-open', 'song-b', at: DateTime.utc(2026, 4, 2));
      await add('a-new', 'song-a', at: DateTime.utc(2026, 4, 3));
      await add('a-newer', 'song-a', at: DateTime.utc(2026, 4, 4));

      final firstPage = await repository.listRecentActivity(limit: 1);
      final secondPage = await repository.listRecentActivity(
        limit: 1,
        offset: 1,
      );

      expect(firstPage.map((entry) => entry.id), ['a-newer']);
      expect(firstPage.single.openCount, 3);
      expect(secondPage.map((entry) => entry.id), ['b-open']);
      expect(secondPage.single.openCount, 1);
      expect(await repository.listRecentActivity(offset: 2), isEmpty);
    },
  );

  test(
    'orders equal timestamps by ID and keeps kind in the object key',
    () async {
      await saveSong('shared', 'Song');
      await repository.saveSetlist(SetlistDocument(id: 'shared', name: 'List'));
      await add('song-z-old', 'shared', at: DateTime.utc(2026, 5, 1));
      await add('song-a-old', 'shared', at: DateTime.utc(2026, 5, 2));
      await add(
        'list-old',
        'shared',
        kind: 'setlist',
        at: DateTime.utc(2026, 5, 2),
      );
      await add('song-z-latest', 'shared', at: DateTime.utc(2026, 5, 3));
      await add('song-z-tie', 'shared', at: DateTime.utc(2026, 5, 3));
      await add(
        'list-latest',
        'shared',
        kind: 'setlist',
        action: 'view',
        at: DateTime.utc(2026, 5, 3),
      );

      final recent = await repository.listRecentActivity();

      expect(recent.map((entry) => entry.id), ['song-z-tie', 'list-latest']);
      expect(recent.map((entry) => entry.objectKind), ['song', 'setlist']);
      expect(recent.map((entry) => entry.openCount), [4, 1]);
      expect(recent.last.action, 'view');
    },
  );

  test(
    'filters deleted objects while retaining their raw activity history',
    () async {
      await saveSong('deleted-song', 'Deleted');
      await repository.saveSetlist(
        SetlistDocument(id: 'deleted-list', name: 'Deleted list'),
      );
      await saveSong('present-song', 'Present');
      await add('gone-song-open', 'deleted-song', at: DateTime.utc(2026, 6, 1));
      await add(
        'gone-list-open',
        'deleted-list',
        kind: 'setlist',
        at: DateTime.utc(2026, 6, 2),
      );
      await add('present-open', 'present-song', at: DateTime.utc(2026, 6, 3));
      await repository.deleteSong('deleted-song');
      await repository.deleteSetlist('deleted-list');

      final recent = await repository.listRecentActivity();
      final raw = await repository.listActivity();

      expect(recent.map((entry) => entry.objectId), ['present-song']);
      expect(raw.map((entry) => entry.id), [
        'present-open',
        'gone-list-open',
        'gone-song-open',
      ]);
    },
  );
}
