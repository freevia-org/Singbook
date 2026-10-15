import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/sync/google_drive_sync.dart';
import 'support.dart';

void main() {
  sqfliteFfiInit();
  test('data applied from the cloud is not queued for upload again', () async {
    final temp = await Directory.systemTemp.createTemp('verse-echo-');
    final a = await LibraryRepository.open(
      path: '${temp.path}/a.sqlite',
      factory: databaseFactoryFfi,
    );
    final b = await LibraryRepository.open(
      path: '${temp.path}/b.sqlite',
      factory: databaseFactoryFfi,
    );
    addTearDown(() async {
      await a.close();
      await b.close();
      await temp.delete(recursive: true);
    });
    final cloud = MemoryCloud();
    final syncA = GoogleDriveSyncService(
      repository: a,
      auth: FakeAuth(),
      store: cloud,
    );
    final syncB = GoogleDriveSyncService(
      repository: b,
      auth: FakeAuth(),
      store: cloud,
    );
    await syncA.connect();
    await syncB.connect();
    await a.saveSong(SongDocument(id: 's', title: 'T', artist: 'A', body: 'x'));
    await a.saveSetlist(
      SetlistDocument(
        id: 'l',
        name: 'Set',
        entries: [const SetlistEntry(id: 'e', songId: 's')],
      ),
    );
    await syncA.sync();
    expect(await a.database.query('outbox'), isEmpty);
    await syncB.sync();
    expect((await b.listSetlists()).single.name, 'Set');
    expect(
      await b.database.query('outbox'),
      isEmpty,
      reason: 'a remote change must not look like a local edit',
    );
    final again = await syncB.sync();
    expect(again.uploaded, 0);
    expect(again.downloaded, 0);
    expect(await b.database.query('outbox'), isEmpty);
  });
}
