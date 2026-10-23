import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/core/service.dart';

class Catalog implements LyricsProvider {
  final pending = <String, Completer<List<SongCandidate>>>{};
  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: 'genius',
    name: 'Catalog',
    capabilities: {'catalog', 'lyrics', 'search'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) => (pending[query] = Completer<List<SongCandidate>>()).future;
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: candidate,
    body: 'Our own lyrics',
    matchKind: MatchKind.sameSong,
  );
}

void main() {
  sqfliteFfiInit();
  late LibraryRepository repo;
  late AppController app;
  late Catalog catalog;
  setUp(() async {
    repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    catalog = Catalog();
    app = AppController(
      repository: repo,
      discovery: SourceDiscoveryService([catalog]),
    );
    await app.initialize();
  });
  tearDown(() async {
    app.dispose();
    await repo.close();
  });
  test('late previous catalog request cannot replace a new query', () async {
    final first = app.search('first'), second = app.search('second');
    final selected = SongCandidate(
      providerId: 'genius',
      id: '2',
      title: 'Second',
      artist: 'Us',
    );
    catalog.pending['second']!.complete([selected]);
    await second;
    catalog.pending['first']!.complete([
      SongCandidate(
        providerId: 'genius',
        id: '1',
        title: 'First',
        artist: 'Us',
      ),
    ]);
    await first;
    expect(app.suggestions.single.id, '2');
    expect(app.query, 'second');
    await app.selectCandidate(selected);
    expect(app.combined, isNotNull);
    final third = app.search('third');
    expect(app.combined, isNull);
    expect(app.selection, isNull);
    catalog.pending['third']!.complete([]);
    await third;
  });
  test(
    'conflicting file import preserves local edits and remaps set references',
    () async {
      final local = SongDocument(
        id: 'song',
        title: 'Ours',
        artist: 'Us',
        body: 'My edited words',
      );
      await app.saveSong(local);
      final imported = await app.importCollection(
        ImportedCollection(
          [
            SongDocument(
              id: 'song',
              title: 'Ours',
              artist: 'Us',
              body: 'Older words',
            ),
          ],
          [
            SetlistDocument(
              id: 'set',
              name: 'Incoming',
              entries: [SetlistEntry(id: 'entry', songId: 'song')],
            ),
          ],
        ),
      );
      expect(app.findSong('song')!.body, 'My edited words');
      expect(imported.songs.single.id, isNot('song'));
      expect(
        app.setlists.single.entries.single.songId,
        imported.songs.single.id,
      );
      expect(app.songs.length, 2);
    },
  );
  test('failed collection import is atomic', () async {
    await expectLater(
      app.importCollection(
        ImportedCollection(
          [SongDocument(id: 'new', title: 'New', artist: '', body: 'words')],
          [
            SetlistDocument(
              id: 'broken',
              name: 'Broken',
              entries: [
                SetlistEntry(
                  id: 'entry',
                  songId: 'new',
                  overrides: {'bad': Object()},
                ),
              ],
            ),
          ],
        ),
      ),
      throwsA(anything),
    );
    expect(await repo.listSongs(), isEmpty);
    expect(await repo.listSetlists(), isEmpty);
  });
  test('settings and complete songs survive controller recreation', () async {
    await app.setSetting('locale', 'uk');
    await app.importText('[ti:Original]\n[00:02]Own line');
    final next = AppController(
      repository: repo,
      discovery: SourceDiscoveryService([catalog]),
    );
    await next.initialize();
    expect(next.settings['locale'], 'uk');
    expect(next.songs.single.timingTracks.single.cues.single.startUs, 2000000);
    next.dispose();
  });
}
