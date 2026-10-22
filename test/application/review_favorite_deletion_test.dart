import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

class _EmptyProvider implements LyricsProvider {
  @override
  ProviderDefinition get definition =>
      const ProviderDefinition(id: 'empty', name: 'Empty');

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw UnimplementedError();
}

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late AppController controller;

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    controller = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([_EmptyProvider()]),
    );
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test(
    'missing song favorite toggle clears a stale cache without a new write',
    () async {
      final stale = SongDocument(
        id: 'song',
        title: 'Song',
        artist: 'Artist',
        body: 'Words',
      );
      await controller.saveSong(stale);
      expect(controller.findSong(stale.id), isNotNull);
      await repository.deleteSong(stale.id);
      final deletionMark = await repository.outboxMark();

      await controller.toggleFavorite(stale);

      expect(await repository.getSong(stale.id), isNull);
      expect(controller.findSong(stale.id), isNull);
      expect(await repository.outboxMark(), deletionMark);
    },
  );

  test(
    'missing setlist favorite toggle clears a stale cache without a new write',
    () async {
      final stale = SetlistDocument(id: 'setlist', name: 'Set');
      await controller.saveSetlist(stale);
      expect(controller.setlists.any((item) => item.id == stale.id), isTrue);
      await repository.deleteSetlist(stale.id);
      final deletionMark = await repository.outboxMark();

      await controller.toggleSetlistFavorite(stale);

      expect(await repository.getSetlist(stale.id), isNull);
      expect(controller.setlists.any((item) => item.id == stale.id), isFalse);
      expect(await repository.outboxMark(), deletionMark);
    },
  );

  test(
    'favorite toggles use current stored values for stale snapshots',
    () async {
      final song = SongDocument(
        id: 'song',
        title: 'Song',
        artist: 'Artist',
        body: 'Words',
      );
      final setlist = SetlistDocument(id: 'setlist', name: 'Set');
      await repository.saveSong(song);
      await repository.saveSetlist(setlist);
      await repository.saveSong(song.copyWith(favorite: true));
      await repository.saveSetlist(setlist.copyWith(favorite: true));

      await controller.toggleFavorite(song);
      await controller.toggleSetlistFavorite(setlist);

      expect((await repository.getSong(song.id))!.favorite, isFalse);
      expect((await repository.getSetlist(setlist.id))!.favorite, isFalse);
    },
  );

  test('mustExist setlist CAS does not insert an absent setlist', () async {
    final result = await repository.saveSetlistIfUnchanged(
      SetlistDocument(id: 'setlist', name: 'Stale'),
      null,
      mustExist: true,
    );

    expect(result, isFalse);
    expect(await repository.getSetlist('setlist'), isNull);
  });

  test(
    'mustExist song CAS cannot recreate after a hashed read and delete',
    () async {
      final song = SongDocument(
        id: 'song',
        title: 'Song',
        artist: 'Artist',
        body: 'Words',
      );
      await repository.saveSong(song);
      final hash = await repository.getSongHash(song.id);
      final stale = await repository.getSong(song.id);
      await repository.deleteSong(song.id);
      final deletionMark = await repository.outboxMark();

      final written = await repository.saveSongIfUnchanged(
        stale!.copyWith(favorite: true),
        hash,
        mustExist: true,
      );

      expect(written, isFalse);
      expect(await repository.getSong(song.id), isNull);
      expect(await repository.outboxMark(), deletionMark);
    },
  );

  test(
    'mustExist setlist CAS cannot recreate after a hashed read and delete',
    () async {
      final setlist = SetlistDocument(id: 'setlist', name: 'Set');
      await repository.saveSetlist(setlist);
      final hash = await repository.getSetlistHash(setlist.id);
      final stale = await repository.getSetlist(setlist.id);
      await repository.deleteSetlist(setlist.id);
      final deletionMark = await repository.outboxMark();

      final written = await repository.saveSetlistIfUnchanged(
        stale!.copyWith(favorite: true),
        hash,
        mustExist: true,
      );

      expect(written, isFalse);
      expect(await repository.getSetlist(setlist.id), isNull);
      expect(await repository.outboxMark(), deletionMark);
    },
  );

  test(
    'stale song editor save preserves an external deletion as a conflict copy',
    () async {
      final song = SongDocument(
        id: 'song',
        title: 'Song',
        artist: 'Artist',
        body: 'Words',
      );
      await controller.saveSong(song);
      await repository.deleteSong(song.id);
      final deletionMark = await repository.outboxMark();

      expect(await controller.saveSong(song.copyWith(body: 'Edited')), isFalse);

      expect(await repository.getSong(song.id), isNull);
      expect(await repository.outboxMark(), greaterThan(deletionMark));
      final conflict = (await repository.listSongs()).single;
      expect(conflict.body, 'Edited');
      expect(conflict.extra['syncConflict']['originalId'], song.id);
    },
  );

  test(
    'stale setlist editor save preserves an external deletion as a conflict copy',
    () async {
      final setlist = SetlistDocument(id: 'setlist', name: 'Set');
      await controller.saveSetlist(setlist);
      await repository.deleteSetlist(setlist.id);
      final deletionMark = await repository.outboxMark();

      expect(
        await controller.saveSetlist(setlist.copyWith(name: 'Edited')),
        isFalse,
      );

      expect(await repository.getSetlist(setlist.id), isNull);
      expect(await repository.outboxMark(), greaterThan(deletionMark));
      final conflict = (await repository.listSetlists()).single;
      expect(conflict.name, startsWith('Edited ['));
    },
  );

  test(
    'explicit song base hash survives a local cache reload after deletion',
    () async {
      final song = SongDocument(
        id: 'song',
        title: 'Song',
        artist: 'Artist',
        body: 'Words',
      );
      await controller.saveSong(song);
      final baseHash = await repository.getSongHash(song.id);
      await controller.deleteSong(song.id);

      expect(
        await controller.saveSong(
          song.copyWith(body: 'Edited'),
          baseHash: baseHash,
        ),
        isFalse,
      );
      expect(await repository.getSong(song.id), isNull);
      expect((await repository.listSongs()).single.body, 'Edited');
    },
  );

  test(
    'explicit setlist base hash survives a local cache reload after deletion',
    () async {
      final setlist = SetlistDocument(id: 'setlist', name: 'Set');
      await controller.saveSetlist(setlist);
      final baseHash = await repository.getSetlistHash(setlist.id);
      await controller.deleteSetlist(setlist.id);

      expect(
        await controller.saveSetlist(
          setlist.copyWith(name: 'Edited'),
          baseHash: baseHash,
        ),
        isFalse,
      );
      expect(await repository.getSetlist(setlist.id), isNull);
      expect(
        (await repository.listSetlists()).single.name,
        startsWith('Edited ['),
      );
    },
  );
}
