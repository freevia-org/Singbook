import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:verse_mobile/sync/google_drive_sync.dart';
import 'support.dart';

void main() {
  group('DriveAppDataStore transport', () {
    DriveAppDataStore store(
      http.Client client, {
      DriveAuthorization? auth,
      int attempts = 4,
      Duration timeout = const Duration(seconds: 5),
    }) => DriveAppDataStore(
      authorization: auth ?? (FakeAuth()..connected = true),
      client: client,
      maxAttempts: attempts,
      requestTimeout: timeout,
      backoff: (_) => Duration.zero,
    );
    const emptyList = '{"files":[]}';

    test('listFiles follows every page and passes the page token', () async {
      final tokens = <String?>[];
      final s = store(
        MockClient((r) async {
          tokens.add(r.url.queryParameters['pageToken']);
          return r.url.queryParameters['pageToken'] == null
              ? http.Response(
                  '{"files":[{"id":"a","name":"n1","appProperties":{"kind":"song"}}],"nextPageToken":"T2"}',
                  200,
                )
              : http.Response(
                  '{"files":[{"id":"b","name":"n2","appProperties":{"kind":"song"}}]}',
                  200,
                );
        }),
      );
      final files = await s.listFiles();
      expect(files.map((f) => f.id), ['a', 'b']);
      expect(tokens, [null, 'T2']);
      expect(files.first.properties['kind'], 'song');
    });

    test('listing projects metadata only and keeps version and time', () async {
      Uri? seen;
      final s = store(
        MockClient((r) async {
          seen = r.url;
          return http.Response(
            '{"files":[{"id":"a","name":"song-x.cho","version":"42","size":"1234","md5Checksum":"m","headRevisionId":"rev1","appProperties":{"kind":"song","hash":"h"},"modifiedTime":"2026-03-04T05:06:07.000Z"},{"id":"b","name":"m"}]}',
            200,
          );
        }),
      );
      final files = await s.listFiles();
      expect(files.first.modifiedTime, DateTime.utc(2026, 3, 4, 5, 6, 7));
      expect(files.first.version, '42');
      expect(files.first.size, 1234);
      expect(files.first.headRevisionId, 'rev1');
      expect(files.first.hash, 'h');
      expect(files.last.modifiedTime, isNull);
      expect(seen!.queryParameters['spaces'], 'appDataFolder');
      expect(seen!.queryParameters['q'], contains("key='verseSchema'"));
      expect(seen!.queryParameters['fields'], contains('headRevisionId'));
    });

    test('an id that is not a plain Drive id is never trusted', () async {
      final s = store(
        MockClient(
          (r) async =>
              http.Response('{"files":[{"id":"../x","name":"n"}]}', 200),
        ),
      );
      await expectLater(s.listFiles(), throwsA(syncError('invalid_remote_data')));
      await expectLater(s.readFile('a/b'), throwsA(syncError('invalid_remote_data')));
      await expectLater(s.getFile('a b'), throwsA(syncError('invalid_remote_data')));
      await expectLater(
        s.updateFile('x?y', 'c', {'kind': 'song'}),
        throwsA(syncError('invalid_remote_data')),
      );
    });

    test('401 re-authorizes exactly once and retries with the new token',
        () async {
      final auth = RefreshableFakeAuth()..connected = true;
      final seen = <String?>[];
      final s = store(
        MockClient((r) async {
          seen.add(r.headers['Authorization']);
          return r.headers['Authorization'] == 'Bearer fresh-token'
              ? http.Response(emptyList, 200)
              : http.Response('', 401);
        }),
        auth: auth,
      );
      expect(await s.listFiles(), isEmpty);
      expect(auth.refreshes, 1);
      expect(seen, ['Bearer stale-token', 'Bearer fresh-token']);
    });

    test('a 401 that persists after re-authorizing is reported, not looped',
        () async {
      final auth = RefreshableFakeAuth()..connected = true;
      var calls = 0;
      final s = store(
        MockClient((r) async {
          calls++;
          return http.Response('', 401);
        }),
        auth: auth,
      );
      await expectLater(s.listFiles(), throwsA(syncError('authorization_required')));
      expect(auth.refreshes, 1);
      expect(calls, 2);
    });

    test('401 without a refreshable authorization fails immediately', () async {
      var calls = 0;
      final s = store(
        MockClient((r) async {
          calls++;
          return http.Response('', 401);
        }),
      );
      await expectLater(s.listFiles(), throwsA(syncError('authorization_required')));
      expect(calls, 1);
    });

    test('403 rate-limit reasons are retried; real denial is not', () async {
      var calls = 0;
      final limited = store(
        MockClient((r) async {
          calls++;
          return calls < 3
              ? http.Response(
                  '{"error":{"errors":[{"reason":"userRateLimitExceeded"}]}}',
                  403,
                )
              : http.Response(emptyList, 200);
        }),
      );
      expect(await limited.listFiles(), isEmpty);
      expect(calls, 3);
      calls = 0;
      final denied = store(
        MockClient((r) async {
          calls++;
          return http.Response(
            '{"error":{"errors":[{"reason":"insufficientPermissions"}]}}',
            403,
          );
        }),
      );
      await expectLater(denied.listFiles(), throwsA(syncError('access_denied')));
      expect(calls, 1);
      final full = store(
        MockClient(
          (r) async => http.Response(
            '{"error":{"errors":[{"reason":"storageQuotaExceeded"}]}}',
            403,
          ),
        ),
      );
      await expectLater(full.listFiles(), throwsA(syncError('storage_full')));
      final unparsable = store(
        MockClient((r) async => http.Response('<html>no</html>', 403)),
      );
      await expectLater(unparsable.listFiles(), throwsA(syncError('access_denied')));
    });

    test('429 and 5xx back off a bounded number of times', () async {
      var calls = 0;
      final recovering = store(
        MockClient((r) async {
          calls++;
          return calls == 1
              ? http.Response('', 429, headers: {'retry-after': '0'})
              : calls == 2
              ? http.Response('', 503)
              : http.Response(emptyList, 200);
        }),
      );
      expect(await recovering.listFiles(), isEmpty);
      expect(calls, 3);
      calls = 0;
      final failing = store(
        MockClient((r) async {
          calls++;
          return http.Response('', 500);
        }),
        attempts: 3,
      );
      await expectLater(failing.listFiles(), throwsA(syncError('network')));
      expect(calls, 3);
      calls = 0;
      final throttled = store(
        MockClient((r) async {
          calls++;
          return http.Response('', 429);
        }),
        attempts: 2,
      );
      await expectLater(throttled.listFiles(), throwsA(syncError('rate_limited')));
      expect(calls, 2);
      calls = 0;
      final missing = store(
        MockClient((r) async {
          calls++;
          return http.Response('', 404);
        }),
      );
      await expectLater(missing.listFiles(), throwsA(syncError('network')));
      expect(calls, 1, reason: '4xx other than 401/403/429 is not transient');
    });

    test('delete is idempotent, a vanished file reads as remote_file_missing',
        () async {
      final methods = <String>[];
      final s = store(
        MockClient((r) async {
          methods.add('${r.method} ${r.url.path}');
          return r.method == 'DELETE' && r.url.path.endsWith('/gone')
              ? http.Response('', 404)
              : r.method == 'DELETE'
              ? http.Response('', 204)
              : http.Response('', 404);
        }),
      );
      await s.deleteFile('here');
      await s.deleteFile('gone');
      expect(methods, ['DELETE /drive/v3/files/here', 'DELETE /drive/v3/files/gone']);
      await expectLater(s.readFile('gone'), throwsA(syncError('remote_file_missing')));
      await expectLater(s.deleteFile('bad/id'), throwsA(syncError('invalid_remote_data')));
    });

    test('a request that never answers times out and is retried', () async {
      var calls = 0;
      final s = store(
        MockClient((r) {
          calls++;
          return Completer<http.Response>().future;
        }),
        attempts: 2,
        timeout: const Duration(milliseconds: 30),
      );
      await expectLater(s.listFiles(), throwsA(syncError('network')));
      expect(calls, 2);
    });

    test('uploads are retried too and still return the new file', () async {
      var calls = 0;
      final s = store(
        MockClient((r) async {
          calls++;
          if (r.method == 'GET') return http.Response(emptyList, 200);
          return calls == 1
              ? http.Response('', 503)
              : http.Response('{"id":"created","name":"setlist-x.json"}', 200);
        }),
      );
      final file = await s.createFile('setlist-x.json', '{}', {'kind': 'setlist'});
      expect(file.id, 'created');
    });

    test('create and update send appDataFolder metadata, hash and schema',
        () async {
      final requests = <http.Request>[];
      final s = store(
        MockClient((r) async {
          requests.add(r);
          return http.Response(
            '{"id":"f1","name":"song-x.cho","version":"2"}',
            200,
          );
        }),
      );
      final created = await s.createFile('song-x.cho', '{title: T}', {
        'kind': 'song',
        'hash': 'abc',
      });
      expect(created.version, '2');
      await s.updateFile('f1', '{title: T2}', {'kind': 'song', 'hash': 'def'});
      expect(requests[0].method, 'POST');
      expect(requests[0].url.path, '/upload/drive/v3/files');
      expect(requests[0].body, contains('appDataFolder'));
      expect(requests[0].body, contains('"verseSchema":"2"'));
      expect(requests[0].body, contains('"hash":"abc"'));
      expect(requests[0].headers['Authorization'], 'Bearer test-token');
      expect(requests[0].body, isNot(contains('test-token')));
      expect(requests[1].method, 'PATCH');
      expect(requests[1].url.path, '/upload/drive/v3/files/f1');
      expect(
        requests[1].body,
        isNot(contains('appDataFolder')),
        reason: 'an update never re-parents the file',
      );
      expect(requests[1].body, contains('{title: T2}'));
    });

    test('an update of a file that vanished is remote_file_missing', () async {
      final s = store(MockClient((r) async => http.Response('', 404)));
      await expectLater(
        s.updateFile('gone', 'c', {'kind': 'song'}),
        throwsA(syncError('remote_file_missing')),
      );
      expect(await s.getFile('gone'), isNull);
    });

    test('a create whose answer was lost is found again, not duplicated',
        () async {
      var posts = 0;
      final s = store(
        MockClient((r) async {
          if (r.method == 'POST') {
            posts++;
            return http.Response('', 503); // the server may have stored it
          }
          return http.Response(
            '{"files":[{"id":"made","name":"song-x.cho","appProperties":{"hash":"abc"}}]}',
            200,
          );
        }),
      );
      final file = await s.createFile('song-x.cho', 'x', {
        'kind': 'song',
        'hash': 'abc',
      });
      expect(file.id, 'made');
      expect(posts, 1, reason: 'the retry found the first attempt');
    });

    test('an unsafe file name is refused before any request', () async {
      var calls = 0;
      final s = store(
        MockClient((r) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        s.createFile("x' or '1'='1", 'c', {'kind': 'song'}),
        throwsA(syncError('invalid_local_data')),
      );
      expect(calls, 0);
    });

    test('a response larger than the limit is rejected, not buffered',
        () async {
      final s = store(
        MockClient.streaming(
          (r, body) async => http.StreamedResponse(
            Stream.fromIterable([
              for (var i = 0; i < 17; i++) List.filled(1024 * 1024, 65),
            ]),
            200,
          ),
        ),
      );
      await expectLater(
        s.readFile('big'),
        throwsA(syncError('remote_file_too_large')),
      );
    });
  });

  group('GoogleDriveAuth', () {
    test('a failed initialization is retried instead of cached forever',
        () async {
      final gate = InitializationGate();
      var calls = 0;
      await expectLater(
        gate.run(() async {
          calls++;
          throw StateError('offline');
        }),
        throwsStateError,
      );
      await gate.run(() async => calls++);
      expect(calls, 2);
      await gate.run(() async => calls++);
      expect(calls, 2, reason: 'a success is remembered');
    });

    test('restore never throws, whatever the platform does', () async {
      final auth = GoogleDriveAuth(
        serverClientId: 'x.apps.googleusercontent.com',
        iosClientId: 'x.apps.googleusercontent.com',
        configuredOverride: true,
      );
      expect(await auth.restore(), isFalse);
      await expectLater(auth.connect(), throwsA(isA<SyncException>()));
    });

    test('without client ids sign-in is honestly not configured', () async {
      final auth = GoogleDriveAuth(serverClientId: '', iosClientId: '');
      expect(auth.configured, isFalse);
      expect(auth.isConnected, isFalse);
      expect(await auth.restore(), isFalse);
      await expectLater(auth.connect(), throwsA(syncError('not_configured')));
      await expectLater(auth.accessToken(), throwsA(syncError('not_signed_in')));
      await auth.disconnect(); // never throws
    });
  });

  group('file names', () {
    test('plain ids are used as they are', () {
      expect(syncFileName('song', 'abc-123_X'), 'song-abc-123_X.cho');
      expect(syncFileName('setlist', 'l1'), 'setlist-l1.json');
      expect(
        parseSyncFileName('song-abc-123_X.cho'),
        (kind: 'song', id: 'abc-123_X'),
      );
    });

    test('other ids are carried as base64url and round trip', () {
      for (final id in ['a b', 'ü', 'x/y', 'a.b', 'ж' * 40]) {
        final name = syncFileName('song', id);
        expect(name, startsWith('song-~'));
        expect(RegExp(r'^[A-Za-z0-9._~-]+$').hasMatch(name), isTrue);
        expect(parseSyncFileName(name), (kind: 'song', id: id));
      }
    });

    test('ids that cannot be represented are refused', () {
      expect(() => syncFileName('song', ''), throwsA(syncError('invalid_local_data')));
      expect(
        () => syncFileName('song', 'ж' * 100),
        throwsA(syncError('invalid_local_data')),
      );
      expect(
        () => syncFileName('folder', 'a'),
        throwsA(syncError('invalid_local_data')),
      );
    });

    test('foreign, mismatched or non canonical names are not items', () {
      for (final name in [
        'song-a.json',
        'setlist-a.cho',
        'song-.cho',
        'song-a b.cho',
        'song-~.cho',
        'song-~YQ.cho', // "a" encoded: must be spelled plainly
        'song-~!!.cho',
        'x.cho',
        'verse-manifest-abc.json',
        'song-${'a' * 200}.cho',
      ]) {
        expect(parseSyncFileName(name), isNull, reason: name);
      }
    });

    test('conflict ids are deterministic', () {
      final h = syncHash('x');
      expect(conflictDocumentId('s', h), conflictDocumentId('s', h));
      expect(conflictDocumentId('s', h), isNot(conflictDocumentId('t', h)));
    });
  });
}
