import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/sync/google_drive_sync.dart';

import 'support.dart';

class _HangingAuth extends FakeAuth {
  int requests = 0;
  @override
  Future<String> accessToken() {
    requests++;
    return Completer<String>().future;
  }
}

final _codec = ChordProCodec();

void main() {
  late MemoryCloud cloud;
  late Device a;
  setUp(() async {
    cloud = MemoryCloud();
    a = await Device.create(cloud);
  });
  tearDown(() => a.close());

  Future<void> saveLinkedSong(String id) async {
    final candidate = SongCandidate(
      providerId: 'catalog',
      id: id,
      title: 'Linked',
      artist: 'Artist',
    );
    await a.repo.beginDiscoverySession(
      candidateIdentity: candidate.identity,
      generation: 1,
    );
    await a.repo.stageDiscoverySources(
      candidateIdentity: candidate.identity,
      generation: 1,
      sources: [
        SourceResult(
          candidate: candidate,
          arrangementId: 'one',
          body: '[C]First source',
        ),
        SourceResult(
          candidate: candidate,
          arrangementId: 'two',
          body: '[G]Second source',
        ),
      ],
    );
    await a.repo.saveChosenSongFast(
      SongDocument(
        id: id,
        title: 'Linked',
        artist: 'Artist',
        body: '[C]Playable chart',
        selectedRecording: candidate,
      ),
      candidateIdentity: candidate.identity,
      discoveryGeneration: 1,
      existingSongId: null,
      expectedExistingHash: null,
    );
  }

  group('a song with linked evidence', () {
    test(
      'whose baseline was lost is linked again, not duplicated',
      () async {
        await saveLinkedSong('linked');
        expect((await a.sync.sync()).uploaded, 1);
        final account = syncHash('person-a');
        final localHash = await a.repo.getSongHash('linked');
        final cloudBody = cloud.body('song-linked.cho')!;
        // The local hash of such a song is not the hash of its sync file.
        expect(localHash, isNot(syncHash(cloudBody)));

        await a.repo.clearSyncBaselines();
        cloud.resetCounters();
        final report = await a.sync.sync();

        expect(report.conflicts, 0);
        expect(report.uploaded, 0);
        expect(report.downloaded, 0);
        expect(cloud.writes, 0);
        expect(await a.songIds(), ['linked']);
        expect(cloud.names, ['song-linked.cho']);
        expect(cloud.body('song-linked.cho'), cloudBody);
        expect(await a.repo.getSongHash('linked'), localHash);
        final baseline = (await a.repo.loadSyncBaselines(
          account,
        ))['song:linked'];
        expect(baseline, isNotNull);
        expect(baseline!.cloudHash, syncHash(cloudBody));
        expect(baseline.localHash, localHash);

        cloud.resetCounters();
        expect((await a.sync.sync()).isNoop, isTrue);
        expect(cloud.reads + cloud.writes, 0);
        // Three syncs, each hydrating evidence in background isolates.
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      'that really differs from the cloud still keeps both versions',
      () async {
        await saveLinkedSong('linked');
        await a.sync.sync();
        await a.repo.clearSyncBaselines();
        final other = SongDocument(
          id: 'linked',
          title: 'Linked',
          artist: 'Artist',
          body: '[D]Edited elsewhere',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026, 2),
        );
        cloud.put('song-linked.cho', _codec.encode(other));

        final report = await a.sync.sync();

        expect(report.conflicts, 1);
        expect(await a.songIds(), hasLength(2));
        expect(await a.bodies(), {'[C]Playable chart', '[D]Edited elsewhere'});
      },
    );
  });

  test('adopting an account stores its binding and the replace decision '
      'together', () async {
    await a.saveSong('s', 'one');
    await a.sync.sync();
    await a.sync.disconnect();
    a.auth.id = 'person-b';
    await a.sync.connect();
    expect(await a.sync.hasAccountMismatch(), isTrue);

    await a.sync.adoptAccount(mergeLocal: false);

    final account = syncHash('person-b');
    expect(await a.repo.getSetting('sync.account'), {
      'id': account,
      'email': 'person-b@example.test',
    });
    expect(await a.repo.getSetting('sync.replacePending'), {
      'account': account,
      'keys': ['song:s'],
    });

    await a.sync.disconnect();
    a.auth.id = 'person-a';
    await a.sync.connect();
    await a.sync.adoptAccount(mergeLocal: true);
    expect(await a.repo.getSetting('sync.replacePending'), isNull);
    expect(
      (await a.repo.getSetting('sync.account') as Map)['id'],
      syncHash('person-a'),
    );
  });

  test('a local edit made while its upload is prepared waits for the next '
      'sync without a warning', () async {
    await a.saveSong('s', 'one');
    await a.sync.sync();
    await a.editSong('s', 'two');
    var edited = false;
    cloud.hook = (op, _) async {
      if (op == 'get' && !edited) {
        edited = true;
        await a.editSong('s', 'three');
      }
    };
    cloud.resetCounters();

    final report = await a.sync.sync();

    expect(report.skipCodes, isEmpty);
    expect(report.pending, 1);
    expect(report.uploaded, 0);
    expect(cloud.gets, 1);
    expect(cloud.writes, 0);

    cloud.hook = null;
    expect((await a.sync.sync()).uploaded, 1);
    expect(cloud.body('song-s.cho'), contains('three'));
  });

  test('an unreadable externally edited file is skipped; the rest of the '
      'visible folder still syncs', () async {
    final good = _codec.encode(
      SongDocument(
        id: 'good',
        title: 'Good',
        artist: 'Artist',
        body: 'fine',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    Map<String, Object?> meta(
      String id,
      String name,
      String body,
      String md5,
    ) => {
      'id': id,
      'name': name,
      'version': '1',
      'size': '${utf8.encode(body).length}',
      'md5Checksum': md5,
      'modifiedTime': '2026-03-04T05:06:07.000Z',
      'parents': ['visible-folder'],
      'appProperties': {
        'kind': 'song',
        'verseSchema': '2',
        'hash': syncHash(body),
        // The good file is untouched; the bad one was edited in Drive.
        'md5': id == 'bad' ? 'before-edit' : md5,
      },
    };
    final files = [
      meta('bad', 'song-bad.cho', 'x', 'after-edit'),
      meta('goodfile', 'song-good.cho', good, 'same'),
    ];
    final store = DriveAppDataStore(
      authorization: a.auth,
      folderId: 'visible-folder',
      backoff: (_) => Duration.zero,
      client: MockClient((request) async {
        final path = request.url.path;
        if (path == '/drive/v3/files/visible-folder') {
          return http.Response(
            '{"id":"visible-folder","name":"Singbook","mimeType":"application/vnd.google-apps.folder","trashed":false}',
            200,
          );
        }
        if (path == '/drive/v3/files') {
          return http.Response(jsonEncode({'files': files}), 200);
        }
        if (path == '/drive/v3/files/bad') {
          // Saved in another encoding: not valid UTF-8.
          return http.Response.bytes([0xff, 0xfe, 0xfd], 200);
        }
        if (path == '/drive/v3/files/goodfile') {
          return request.url.queryParameters['alt'] == 'media'
              ? http.Response.bytes(utf8.encode(good), 200)
              : http.Response(jsonEncode(files[1]), 200);
        }
        return http.Response('{}', 404);
      }),
    );
    final sync = GoogleDriveSyncService(
      repository: a.repo,
      auth: a.auth,
      store: store,
      concurrency: 1,
    );

    final report = await sync.sync();

    expect(report.skipCodes, ['invalid_remote_data']);
    expect(report.downloaded, 1);
    expect(await a.songIds(), ['good']);
  });

  test(
    'a network failure while reading an edited file still stops the sync',
    () async {
      final store = DriveAppDataStore(
        authorization: a.auth,
        folderId: 'visible-folder',
        maxAttempts: 1,
        backoff: (_) => Duration.zero,
        client: MockClient((request) async {
          final path = request.url.path;
          if (path == '/drive/v3/files/visible-folder') {
            return http.Response(
              '{"id":"visible-folder","name":"Singbook","mimeType":"application/vnd.google-apps.folder","trashed":false}',
              200,
            );
          }
          if (path == '/drive/v3/files') {
            return http.Response(
              jsonEncode({
                'files': [
                  {
                    'id': 'edited',
                    'name': 'song-edited.cho',
                    'version': '1',
                    'md5Checksum': 'after-edit',
                    'appProperties': {
                      'kind': 'song',
                      'verseSchema': '2',
                      'hash': syncHash('x'),
                      'md5': 'before-edit',
                    },
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('{}', 503);
        }),
      );
      final sync = GoogleDriveSyncService(
        repository: a.repo,
        auth: a.auth,
        store: store,
        concurrency: 1,
      );

      await expectLater(sync.sync(), throwsA(syncError('network')));
    },
  );

  test(
    'a platform token request that never answers ends as a network error',
    () async {
      final auth = _HangingAuth()..connected = true;
      var sent = 0;
      final store = DriveAppDataStore(
        authorization: auth,
        maxAttempts: 2,
        tokenTimeout: const Duration(milliseconds: 20),
        backoff: (_) => Duration.zero,
        client: MockClient((request) async {
          sent++;
          return http.Response('{"files":[]}', 200);
        }),
      );

      await expectLater(store.listFiles(), throwsA(syncError('network')));

      expect(auth.requests, 2);
      expect(sent, 0);
    },
  );
}
