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
