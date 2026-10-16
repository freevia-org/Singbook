import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/error_reporting.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/sync/google_drive_sync.dart';
import '../sync/support.dart';

class QuietCatalog implements LyricsProvider {
  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: 'genius',
    name: 'Catalog',
    capabilities: {'lyrics', 'search'},
  );
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

SourceDiscoveryService discovery() => SourceDiscoveryService([QuietCatalog()]);

PickedDocument doc(String name, List<int> bytes) =>
    PickedDocument(name, Uint8List.fromList(bytes));

class _PendingRestoreAuth extends FakeAuth {
  final completion = Completer<bool>();
  bool restoring = false;

  @override
  Future<bool> restore() async {
    restoring = true;
    return connected = await completion.future;
  }
}

class _GatedRestoreSync extends GoogleDriveSyncService {
  _GatedRestoreSync({
    required super.repository,
    required DriveAuthorization auth,
  }) : super(auth: auth, store: MemoryCloud());

  final lastSuccess = Completer<DateTime?>();
  int lastSuccessCalls = 0;
  int mismatchChecks = 0;

  @override
  Future<DateTime?> lastSuccessfulSync() {
    lastSuccessCalls++;
    return lastSuccess.future;
  }

  @override
  Future<bool> hasAccountMismatch() async {
    mismatchChecks++;
    return false;
  }
}

void main() {
  sqfliteFfiInit();
  late LibraryRepository repo;
  late AppController app;
  setUp(() async {
    repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(repository: repo, discovery: discovery());
    await app.initialize();
  });
  tearDown(() async {
    app.dispose();
    await repo.close();
  });

  group('sync lifecycle', () {
    test('syncNow before initialize is a handled state, not a crash', () async {
      final fresh = AppController(discovery: discovery());
      await fresh.syncNow();
      await fresh.connectSync();
      expect(fresh.syncError, 'not_initialized');
      expect(fresh.syncBusy, isFalse);
      expect(fresh.lastMessage!.code, 'not_initialized');
      expect(fresh.lastMessage!.operation, 'sync');
      fresh.dispose();
    });

    test('a failing session restore cannot break initialize', () async {
      final auth = FakeAuth()..restoreError = StateError('keystore unavailable');
      final other = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final guarded = AppController(
        repository: other,
        discovery: discovery(),
        sync: GoogleDriveSyncService(
          repository: other,
          auth: auth,
          store: MemoryCloud(),
        ),
      );
      await guarded.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(guarded.initialized, isTrue);
      expect(guarded.syncError, 'sync_failed');
      guarded.dispose();
      await other.close();
    });

    test(
      'local startup does not wait for optional account restoration',
      () async {
        final auth = _PendingRestoreAuth();
        final guarded = AppController(
          repository: repo,
          discovery: discovery(),
          sync: GoogleDriveSyncService(
            repository: repo,
            auth: auth,
            store: MemoryCloud(),
          ),
        );
        addTearDown(guarded.dispose);
        await guarded.initialize().timeout(const Duration(seconds: 1));
        expect(guarded.initialized, isTrue);
        expect(auth.restoring, isTrue);
        expect(auth.completion.isCompleted, isFalse);
        expect(guarded.syncConnected, isFalse);
        auth.completion.complete(false);
        await Future<void>.delayed(Duration.zero);
        expect(guarded.syncError, isNull);
      },
    );

    test('late account restoration cannot access a disposed library', () async {
      final auth = _PendingRestoreAuth();
      final other = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final guarded = AppController(
        repository: other,
        discovery: discovery(),
        sync: GoogleDriveSyncService(
          repository: other,
          auth: auth,
          store: MemoryCloud(),
        ),
      );
      await guarded.initialize().timeout(const Duration(seconds: 1));
      guarded.dispose();
      await other.close();
      auth.completion.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(guarded.syncError, isNull);
    });

    test(
      'disposal during restored account metadata stops later repository reads',
      () async {
        final dir = await Directory.systemTemp.createTemp('verse-restore-');
        addTearDown(() => dir.delete(recursive: true));
        final other = await LibraryRepository.open(
          path: '${dir.path}/library.sqlite',
          factory: databaseFactoryFfi,
        );
        final auth = FakeAuth()..connected = true;
        final sync = _GatedRestoreSync(repository: other, auth: auth);
        final guarded = AppController(
          repository: other,
          discovery: discovery(),
          sync: sync,
        );
        await guarded.initialize();
        for (var i = 0; i < 1000 && sync.lastSuccessCalls == 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(sync.lastSuccessCalls, 1);
        guarded.dispose();
        await other.close();
        sync.lastSuccess.complete(DateTime.now().toUtc());
        await Future<void>.delayed(Duration.zero);
        expect(sync.mismatchChecks, 0);
        expect(guarded.lastSyncAt, isNull);
        expect(guarded.syncError, isNull);
      },
    );

    test('dispose during an in-flight sync neither throws nor touches the controller',
        () async {
      // Seed the cloud from a second device so the sync has something to read.
      final cloud = MemoryCloud();
      final remote = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      await remote.saveSong(
        SongDocument(id: 'remote', title: 'R', artist: '', body: 'words'),
      );
      final remoteAuth = FakeAuth();
      await remoteAuth.connect();
      await GoogleDriveSyncService(
        repository: remote,
        auth: remoteAuth,
        store: cloud,
      ).sync();
      final auth = FakeAuth();
      await auth.connect();
      final gate = Completer<void>();
      cloud.hook = (op, _) => op == 'read' ? gate.future : null;
      // An in-memory path is shared by every open, so use a real file.
      final dir = await Directory.systemTemp.createTemp('verse-ctl-');
      addTearDown(() => dir.delete(recursive: true));
      final local = await LibraryRepository.open(
        path: '${dir.path}/local.sqlite',
        factory: databaseFactoryFfi,
      );
      final controller = AppController(
        repository: local,
        discovery: discovery(),
        sync: GoogleDriveSyncService(
          repository: local,
          auth: auth,
          store: cloud,
        ),
      );
      await controller.initialize();
      var notifications = 0;
      controller.addListener(() => notifications++);
      final running = controller.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.syncBusy, isTrue);
      final seen = notifications;
      controller.dispose();
      gate.complete();
      await running;
      await controller.syncIdle;
      expect(notifications, seen, reason: 'no notifications after dispose');
      await remote.close();
      await local.close();
    });
  });

  group('failures are reported with stable codes', () {
    test('import failures set lastMessage and still throw to the caller',
        () async {
      await expectLater(
        app.importDocument(doc('bad.zip', [0x50, 0x4b, 3, 4, 1, 2, 3])),
        throwsFormatException,
      );
      expect(app.lastErrorCode, 'invalid_archive');
      expect(app.lastMessage!.operation, 'import');
      app.clearMessage();
      expect(app.lastMessage, isNull);
      await expectLater(
        app.importDocument(doc('empty.txt', utf8.encode('  \n'))),
        throwsFormatException,
      );
      expect(app.lastErrorCode, 'empty_file');
    });

    test('every new message notifies even when the code repeats', () async {
      var count = 0;
      app.messages.addListener(() => count++);
      app.postMessage('x');
      app.postMessage('x');
      expect(count, 2);
    });

    test('guarded turns an exception into a message', () async {
      final value = await app.guarded<int>('share', () async => throw StateError('no_result'));
      expect(value, isNull);
      expect(app.lastMessage!.code, 'no_result');
      expect(app.lastMessage!.operation, 'share');
      expect(await app.guarded<int>('share', () async => 3), 3);
    });

    test('errorCodeFor never exposes raw exception text', () {
      expect(AppController.errorCodeFor(const SyncException('rate_limited')), 'rate_limited');
      expect(AppController.errorCodeFor(const FormatException('Unexpected character at secret=abc')), 'invalid_file');
      expect(AppController.errorCodeFor(ArchiveException('boom')), 'invalid_archive');
      expect(AppController.errorCodeFor(Exception('token=abc')), 'unknown_error');
    });

    test('addToSetlist with a vanished setlist is a handled failure', () async {
      expect(await app.addToSetlist('song', 'gone'), isFalse);
      expect(app.lastMessage!.code, 'setlist_missing');
      await app.saveSong(
        SongDocument(id: 'song', title: 'S', artist: '', body: 'b'),
      );
      await app.saveSetlist(SetlistDocument(id: 'set', name: 'Set'));
      // Written behind the controller's back: the cache does not know it.
      await repo.saveSetlist(SetlistDocument(id: 'hidden', name: 'Hidden'));
      expect(await app.addToSetlist('song', 'hidden'), isTrue);
      expect((await repo.getSetlist('hidden'))!.entries, hasLength(1));
      expect(await app.addToSetlist('song', 'set'), isTrue);
    });
  });

  group('writes do not clobber background changes', () {
    final base = SongDocument(id: 'song', title: 'T', artist: '', body: 'first');
    test('a stale save is kept as a conflict copy and the newer version survives',
        () async {
      await app.saveSong(base);
      final snapshot = app.findSong('song')!;
      // A background sync replaces the song; the controller has not reloaded.
      await repo.saveSong(snapshot.copyWith(body: 'from sync'));
      final saved = await app.saveSong(snapshot.copyWith(body: 'my edit'));
      expect(saved, isFalse);
      expect(app.lastMessage!.code, 'save_conflict');
      expect(app.lastMessage!.isError, isFalse);
      expect((await repo.getSong('song'))!.body, 'from sync');
      final bodies = (await repo.listSongs()).map((s) => s.body).toSet();
      expect(bodies, {'from sync', 'my edit'});
    });

    test('an explicit baseHash detects a change the cache already absorbed',
        () async {
      await app.saveSong(base);
      final started = app.songHash('song')!;
      final snapshot = app.findSong('song')!;
      await repo.saveSong(snapshot.copyWith(body: 'from sync'));
      await app.initialize(); // refresh the cache to the newer stored version
      expect(app.findSong('song')!.body, 'from sync');
      expect(
        await app.saveSong(snapshot.copyWith(body: 'late'), baseHash: started),
        isFalse,
      );
      expect((await repo.getSong('song'))!.body, 'from sync');
    });

    test('an unchanged song saves in place', () async {
      await app.saveSong(base);
      expect(
        await app.saveSong(app.findSong('song')!.copyWith(body: 'second')),
        isTrue,
      );
      expect(await repo.listSongs(), hasLength(1));
      expect(app.lastMessage, isNull);
    });

    test('toggleFavorite applies to the stored song, not the stale snapshot',
        () async {
      await app.saveSong(base);
      final snapshot = app.findSong('song')!;
      await repo.saveSong(snapshot.copyWith(body: 'from sync'));
      await app.toggleFavorite(snapshot);
      final stored = (await repo.getSong('song'))!;
      expect(stored.favorite, isTrue);
      expect(stored.body, 'from sync');
    });

    test('a stale setlist save is kept beside the newer stored setlist',
        () async {
      await app.saveSetlist(SetlistDocument(id: 'set', name: 'Original'));
      final snapshot = app.setlists.single;
      await repo.saveSetlist(
        SetlistDocument(id: 'set', name: 'From sync', createdAt: snapshot.createdAt),
      );
      final saved = await app.saveSetlist(
        SetlistDocument(id: 'set', name: 'My edit', createdAt: snapshot.createdAt),
      );
      expect(saved, isFalse);
      final names = (await repo.listSetlists()).map((s) => s.name).toList();
      expect(names, contains('From sync'));
      expect(names.where((n) => n.startsWith('My edit')), hasLength(1));
    });

    test('findSong is the cache; loadSong is the database', () async {
      await repo.saveSong(base);
      expect(app.findSong('song'), isNull);
      expect((await app.loadSong('song'))!.body, 'first');
    });
  });

  group('imports', () {
    final one = SongDocument(id: 'one', title: 'One', artist: 'A', body: 'First words');
    final two = SongDocument(id: 'two', title: 'Two', artist: 'A', body: 'Second words');
    final set = SetlistDocument(
      id: 'set',
      name: 'Evening',
      entries: [
        SetlistEntry(id: 'e1', songId: 'one'),
        SetlistEntry(id: 'e2', songId: 'two', overrides: {'capo': 2}),
      ],
    );

    test('importing the same backup twice creates nothing the second time',
        () async {
      final bytes = encodeLibraryPackage([one, two], [set]);
      await app.importDocument(doc('backup.lyrics-setlist', bytes));
      expect(app.songs, hasLength(2));
      expect(app.setlists, hasLength(1));
      final outbox = (await repo.database.query('outbox')).length;
      await app.importDocument(doc('backup.lyrics-setlist', bytes));
      expect(app.songs, hasLength(2));
      expect(app.setlists, hasLength(1));
      expect((await repo.database.query('outbox')).length, outbox);
    });

    test('a user-edited imported setlist is not overwritten by a re-import',
        () async {
      final bytes = encodeLibraryPackage([one, two], [set]);
      await app.importDocument(doc('b.lyrics-setlist', bytes));
      final imported = app.setlists.single;
      await app.saveSetlist(
        SetlistDocument(
          id: imported.id,
          name: 'Renamed by user',
          entries: imported.entries,
          createdAt: imported.createdAt,
        ),
      );
      await app.importDocument(doc('b.lyrics-setlist', bytes));
      expect(app.setlists.single.name, 'Renamed by user');
    });

    test('a conflicting song is imported as one stable copy, however often',
        () async {
      await app.saveSong(one);
      final different = one.copyWith(body: 'Edited elsewhere');
      for (var i = 0; i < 3; i++) {
        await app.importCollection(ImportedCollection([different], [set.copyOnly('one')]));
      }
      expect(app.songs, hasLength(2));
      expect(app.setlists, hasLength(1));
    });

    test('the same OpenSong setlist file imports once', () async {
      await app.saveSong(one);
      final text = encodeSetlistReferences(
        SetlistDocument(id: 'x', name: 'File set', entries: [SetlistEntry(id: 'q', songId: 'one')]),
        [one],
      );
      await app.importDocument(doc('a.osts', utf8.encode(text)));
      await app.importDocument(doc('a.osts', utf8.encode(text)));
      expect(app.setlists, hasLength(1));
    });

    test('a text song whose title starts with PK is a song, not a zip', () async {
      final result = await app.importDocument(
        doc('pk.txt', utf8.encode('PK Anthem\n[C]Hello world')),
      );
      expect(result.songs.single.title, isNotEmpty);
      expect(app.songs, hasLength(1));
    });

    test('lyrics that mention <set> are a song, not a setlist', () async {
      await app.importDocument(
        doc('lyrics.txt', utf8.encode('Verse\nI <set> the table\n<set a>')),
      );
      expect(app.songs, hasLength(1));
      expect(app.setlists, isEmpty);
    });

    test('Windows-1251 and UTF-16 text files import', () async {
      await app.importDocument(
        doc('cp1251.txt', [0xd1, 0xe2, 0xe5, 0xf2, 0xeb, 0xe8, 0xed, 0xe0, 0x0a, 0xd1, 0xe2, 0xe5, 0xf2]),
      );
      expect(app.songs.single.body, contains('Светлина'));
      final units = '[C]Hello UTF16'.codeUnits;
      await app.importDocument(
        doc('u16.txt', [0xff, 0xfe, for (final u in units) ...[u & 0xff, u >> 8]]),
      );
      expect(app.songs.map((s) => s.body), contains(contains('Hello UTF16')));
    });

    test('a backup with directory entries and more than 1000 songs restores', () async {
      final songs = [
        for (var i = 0; i < 1100; i++)
          SongDocument(id: 's$i', title: 'T$i', artist: '', body: 'b$i'),
      ];
      final archive = ZipDecoder().decodeBytes(encodeLibraryPackage(songs, []));
      final withDir = Archive()..add(ArchiveFile.directory('songs/'));
      for (final f in archive) {
        withDir.add(f);
      }
      await app.importDocument(
        doc('big.zip', Uint8List.fromList(ZipEncoder().encodeBytes(withDir))),
      );
      expect(app.songs, hasLength(1100));
    });
  });

  group('outbox', () {
    test('repeated saves are coalesced to the newest row per object', () async {
      var song = SongDocument(id: 'busy', title: 'B', artist: '', body: '0');
      for (var i = 1; i <= 120; i++) {
        song = song.copyWith(body: '$i');
        await repo.saveSong(song);
      }
      await repo.saveSong(SongDocument(id: 'other', title: 'O', artist: '', body: 'x'));
      expect((await repo.database.query('outbox')).length, greaterThan(100));
      expect(await app.compactOutbox(), greaterThan(100));
      final rows = await repo.database.query('outbox');
      expect(rows.map((r) => r['object_id']).toSet(), {'busy', 'other'});
      expect(rows, hasLength(2));
    });

    test('controller writes keep the queue bounded without syncing', () async {
      var song = SongDocument(id: 'busy', title: 'B', artist: '', body: '0');
      for (var i = 1; i <= 120; i++) {
        song = song.copyWith(body: '$i');
        await app.saveSong(song);
      }
      expect((await repo.database.query('outbox')).length, lessThan(70));
    });
  });

  group('global error handlers', () {
    test('redaction removes tokens, keys and addresses', () {
      const secret =
          'GET https://x/y?access_token=ya29.AbCdEf&key=AIzaSyA1234567890123456789012 '
          'Authorization: Bearer ya29.a0AfH6SMB user=me@example.com';
      final clean = redactSecrets(secret);
      for (final leak in ['ya29', 'AIza', 'me@example.com', 'AbCdEf']) {
        expect(clean, isNot(contains(leak)));
      }
      expect(clean, contains('access_token='));
      expect(redactSecrets('plain message'), 'plain message');
    });

    test('redaction removes bare Google refresh tokens and client secrets', () {
      final clean = redactSecrets(
        'failed 1//0gAbCdEfGhIjKlMnOpQrStUv and GOCSPX-abc_DEF-123456 end',
      );
      expect(clean, isNot(contains('1//0g')));
      expect(clean, isNot(contains('GOCSPX')));
      expect(clean, contains('end'));
    });

    test('handlers log a redacted line and swallow the error', () {
      final previousFlutter = FlutterError.onError;
      final previousPlatform = PlatformDispatcher.instance.onError;
      addTearDown(() {
        FlutterError.onError = previousFlutter;
        PlatformDispatcher.instance.onError = previousPlatform;
      });
      final lines = <String>[];
      installErrorHandlers(sink: lines.add);
      FlutterError.onError!(
        FlutterErrorDetails(exception: Exception('boom Bearer ya29.secret')),
      );
      expect(
        PlatformDispatcher.instance.onError!(
          StateError('token=hunter2'),
          StackTrace.current,
        ),
        isTrue,
      );
      expect(lines, hasLength(2));
      expect(lines.join('\n'), isNot(contains('ya29')));
      expect(lines.join('\n'), isNot(contains('hunter2')));
      expect(lines.first, contains('boom'));
    });
  });
}

extension on SetlistDocument {
  /// A copy referencing only [songId], for import tests.
  SetlistDocument copyOnly(String songId) => SetlistDocument(
    id: id,
    name: name,
    entries: [SetlistEntry(id: 'only', songId: songId)],
  );
}
