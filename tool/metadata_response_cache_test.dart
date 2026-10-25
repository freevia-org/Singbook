import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'src/metadata_response_cache.dart';
import 'package:singbook/providers/transport.dart';

void main() {
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('singbook-response-cache-');
  });
  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('online response is gzip cached and replayed offline', () async {
    var calls = 0;
    final client = MetadataResponseCacheClient(
      temp,
      offline: false,
      networkBudget: 1,
      inner: MockClient((_) async {
        calls++;
        return http.Response(
          'invented metadata',
          200,
          headers: {'content-type': 'text/plain', 'set-cookie': 'private'},
        );
      }),
    );
    final first = await client.get(Uri.https('example.invalid', '/artist'));
    expect(first.body, 'invented metadata');
    expect(jsonDecode(jsonEncode(client.counters))['networkAttempts'], 1);
    client.close();
    final files = await temp.list().toList();
    expect(files.where((f) => f.path.endsWith('.json.gz')), hasLength(1));
    final offline = MetadataResponseCacheClient(
      temp,
      offline: true,
      inner: MockClient((_) async {
        calls++;
        return http.Response('', 500);
      }),
    );
    final replay = await offline.get(Uri.https('example.invalid', '/artist'));
    expect(replay.body, 'invented metadata');
    expect(replay.headers.containsKey('set-cookie'), isFalse);
    expect(calls, 1);
    expect(offline.hits, 1);
    offline.close();
  });

  test('offline cache miss never invokes network', () async {
    var calls = 0;
    final client = MetadataResponseCacheClient(
      temp,
      offline: true,
      inner: MockClient((_) async {
        calls++;
        return http.Response('', 200);
      }),
    );
    await expectLater(
      client.get(Uri.https('example.invalid', '/missing')),
      throwsA(
        isA<ProviderException>().having((e) => e.code, 'code', 'unavailable'),
      ),
    );
    expect(calls, 0);
    expect(client.uncached, 1);
    client.close();
  });

  test('hard network cap counts actual attempts', () async {
    var calls = 0;
    final client = MetadataResponseCacheClient(
      temp,
      offline: false,
      networkBudget: 2,
      inner: MockClient((_) async {
        calls++;
        return http.Response('ok', 200);
      }),
    );
    await client.get(Uri.https('example.invalid', '/one'));
    await client.get(Uri.https('example.invalid', '/two'));
    await expectLater(
      client.get(Uri.https('example.invalid', '/three')),
      throwsA(isA<ProviderException>()),
    );
    expect(calls, 2);
    expect(client.networkAttempts, 2);
    expect(client.overBudget, 1);
    client.close();
  });

  test('refused status is not persisted', () async {
    final client = MetadataResponseCacheClient(
      temp,
      offline: false,
      networkBudget: 1,
      inner: MockClient((_) async => http.Response('try later', 503)),
    );
    await client.get(Uri.https('example.invalid', '/busy'));
    expect(await temp.list().toList(), isEmpty);
    expect(client.uncached, 1);
    client.close();
  });

  test(
    'safe redirect location is preserved, sensitive redirect is not cached',
    () async {
      final safe = MetadataResponseCacheClient(
        temp,
        offline: false,
        networkBudget: 1,
        inner: MockClient(
          (_) async => http.Response(
            '',
            302,
            headers: {'location': 'https://example.invalid/next?lang=en'},
          ),
        ),
      );
      final response = await safe.get(
        Uri.https('example.invalid', '/redirect'),
      );
      expect(
        response.headers['location'],
        'https://example.invalid/next?lang=en',
      );
      expect(
        (await temp.list().toList()).where((f) => f.path.endsWith('.json.gz')),
        hasLength(1),
      );
      safe.close();
      await temp.list().drain<void>();
      for (final entity in await temp.list().toList()) {
        await entity.delete();
      }
      final unsafe = MetadataResponseCacheClient(
        temp,
        offline: false,
        networkBudget: 1,
        inner: MockClient(
          (_) async => http.Response(
            '',
            302,
            headers: {
              'location': 'https://example.invalid/next?access_token=abc',
            },
          ),
        ),
      );
      await unsafe.get(Uri.https('example.invalid', '/redirect'));
      expect(await temp.list().toList(), isEmpty);
      unsafe.close();
    },
  );

  test(
    'root-relative redirect and target replay offline through transport',
    () async {
      var networkCalls = 0;
      final url = Uri.https(
        'www.songsterr.com',
        '/a/wsa/beyonce-halo-chords-s190194',
      );
      final onlineCache = MetadataResponseCacheClient(
        temp,
        offline: false,
        networkBudget: 2,
        inner: MockClient((request) async {
          networkCalls++;
          if (request.url.path == url.path) {
            return http.Response(
              '',
              301,
              headers: {
                'location': '/a/wsa/beyonce-knowles-halo-chords-s190194',
                'set-cookie': 'private=redirect-cookie',
              },
            );
          }
          return http.Response(
            'resolved chords',
            200,
            headers: {
              'content-type': 'text/plain',
              'set-cookie': 'private=target-cookie',
            },
          );
        }),
      );
      final onlineTransport = ProviderTransport(
        client: onlineCache,
        hostInterval: Duration.zero,
      );
      final onlineBody = await onlineTransport.getText(url);
      expect(onlineBody, 'resolved chords');
      expect(networkCalls, 2);
      expect(onlineCache.networkAttempts, 2);
      await onlineTransport.close();

      final persisted = <Map<String, dynamic>>[];
      final cacheFiles = await temp
          .list()
          .where((e) => e.path.endsWith('.json.gz'))
          .toList();
      for (final entity in cacheFiles) {
        final bytes = await (entity as File).readAsBytes();
        persisted.add(
          jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>,
        );
      }
      expect(persisted, hasLength(2));
      expect(
        persisted.every(
          (record) => !(record['headers'] as Map<String, dynamic>).containsKey(
            'set-cookie',
          ),
        ),
        isTrue,
      );
      expect(
        persisted.any(
          (record) =>
              (record['headers'] as Map<String, dynamic>)['location'] ==
              '/a/wsa/beyonce-knowles-halo-chords-s190194',
        ),
        isTrue,
      );

      final offlineCache = MetadataResponseCacheClient(temp, offline: true);
      final offlineTransport = ProviderTransport(
        client: offlineCache,
        hostInterval: Duration.zero,
      );
      final offlineBody = await offlineTransport.getText(url);
      expect(offlineBody, onlineBody);
      expect(offlineCache.hits, 2);
      expect(offlineCache.networkAttempts, 0);
      expect(offlineCache.uncached, 0);
      await offlineTransport.close();
    },
  );

  test(
    'unsafe root-relative and non-HTTPS redirect locations are not cached',
    () async {
      for (final location in [
        '/next?access_token=secret',
        '//evil.invalid/next',
        'http://example.invalid/next',
        r'/\evil.invalid/next',
        '/next#fragment',
        '/next\nX-Injected: yes',
      ]) {
        final client = MetadataResponseCacheClient(
          temp,
          offline: false,
          networkBudget: 1,
          inner: MockClient(
            (_) async =>
                http.Response('', 302, headers: {'location': location}),
          ),
        );
        await client.get(Uri.https('example.invalid', '/redirect'));
        expect(await temp.list().toList(), isEmpty, reason: location);
        expect(client.uncached, 1, reason: location);
        client.close();
      }
    },
  );

  test('live response preserves original headers and request', () async {
    final client = MetadataResponseCacheClient(
      temp,
      offline: false,
      networkBudget: 1,
      inner: MockClient(
        (_) async => http.Response(
          '',
          302,
          headers: {
            'location': 'https://example.invalid/next?access_token=private',
            'retry-after': '17',
          },
        ),
      ),
    );
    final request = http.Request(
      'GET',
      Uri.https('example.invalid', '/redirect'),
    );
    final response = await client.send(request);
    expect(response.request, same(request));
    expect(
      response.headers['location'],
      'https://example.invalid/next?access_token=private',
    );
    expect(response.headers['retry-after'], '17');
    client.close();
  });

  test(
    'legacy plaintext symlink is read only and cached response carries request',
    () async {
      final request = http.Request(
        'GET',
        Uri.https('example.invalid', '/legacy'),
      );
      final key = sha1
          .convert(utf8.encode('${request.method} ${request.url}\n'))
          .toString();
      final outside = await File(
        '${temp.parent.path}/legacy-${temp.uri.pathSegments.last}.json',
      ).create();
      await outside.writeAsString(
        jsonEncode({
          'status': 200,
          'headers': {'content-type': 'text/plain'},
          'body': base64Encode(utf8.encode('legacy')),
        }),
      );
      final link = Link('${temp.path}/$key.json');
      try {
        await link.create(outside.path);
      } on FileSystemException {
        await outside.delete();
        return; // Symlinks are unavailable in this test environment.
      }
      final before = await outside.readAsString();
      final client = MetadataResponseCacheClient(temp, offline: true);
      final response = await client.send(request);
      expect(response.request, same(request));
      expect(await response.stream.transform(utf8.decoder).join(), 'legacy');
      expect(await outside.readAsString(), before);
      client.close();
      await outside.delete();
    },
  );

  test('oversized streaming response fails at configured bound', () async {
    final client = MetadataResponseCacheClient(
      temp,
      offline: false,
      networkBudget: 1,
      maxResponseBytes: 4,
      inner: MockClient(
        (_) async => http.Response.bytes(utf8.encode('12345'), 200),
      ),
    );
    await expectLater(
      client.get(Uri.https('example.invalid', '/large')),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.code,
          'code',
          'invalid_response',
        ),
      ),
    );
    expect(await temp.list().toList(), isEmpty);
    client.close();
  });
}
