import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/windows_http_client.dart';

void main() {
  group('Windows WinHTTP client', () {
    late HttpServer server;
    late HttpServer destination;
    late WindowsHttpClient client;
    late List<
      ({
        String method,
        String path,
        Map<String, String> headers,
        List<int> body,
      })
    >
    received;
    late Completer<void> arrived;
    late Completer<void> release;

    Future<void> respond(HttpRequest request) async {
      final body = await request.fold<List<int>>(
        [],
        (all, chunk) => all..addAll(chunk),
      );
      final headers = <String, String>{};
      request.headers.forEach(
        (name, values) => headers[name] = values.join(','),
      );
      received.add((
        method: request.method,
        path: request.uri.path,
        headers: headers,
        body: body,
      ));
      try {
        if (request.uri.path == '/held') {
          if (!arrived.isCompleted) arrived.complete();
          await release.future;
        }
        if (request.uri.path == '/redirect' || request.uri.path == '/loop') {
          request.response.statusCode = int.parse(
            request.uri.queryParameters['status'] ?? '302',
          );
          request.response.headers.set(
            'location',
            request.uri.path == '/loop'
                ? '/loop'
                : request.uri.queryParameters['to'] ?? '/echo',
          );
        } else {
          request.response.headers.contentType = ContentType.binary;
          request.response.headers.add('X-Repeated', 'one');
          request.response.headers.add('X-Repeated', 'two');
          request.response.add(body.isEmpty ? [0, 128, 255, 13, 10] : body);
        }
        await request.response.close();
      } on HttpException {
        // Closing the client may close the request before the fixture replies.
      } on SocketException {
        // A bounded worker finishes native cleanup after cancellation.
      }
    }

    setUp(() async {
      received = [];
      arrived = Completer<void>();
      release = Completer<void>();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      destination = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) => unawaited(respond(request)));
      destination.listen((request) => unawaited(respond(request)));
      client = WindowsHttpClient();
    });
    tearDown(() async {
      client.close();
      if (!release.isCompleted) release.complete();
      await server.close(force: true);
      await destination.close(force: true);
    });
    Uri url(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');

    test(
      'POST binary body, request headers and repeated response headers survive',
      () async {
        final bytes = [0, 1, 128, 255, ...utf8.encode('café — тест')];
        final response = await client.post(
          url('/echo'),
          body: bytes,
          headers: {
            'X-Fixture': 'preserved',
            'Content-Type': 'application/octet-stream',
          },
        );
        expect(response.statusCode, 200);
        expect(response.bodyBytes, bytes);
        expect(received.single.method, 'POST');
        expect(received.single.body, bytes);
        expect(received.single.headers['x-fixture'], 'preserved');
        expect(response.headers['x-repeated']!.replaceAll(' ', ''), 'one,two');
      },
    );

    test('307 and 308 preserve exact method and body', () async {
      for (final status in [307, 308]) {
        received.clear();
        final response = await client.post(
          url('/redirect?status=$status'),
          body: [0, 255, 128],
        );
        expect(response.bodyBytes, [0, 255, 128]);
        expect(received.map((entry) => entry.method), ['POST', 'POST']);
        expect(received.last.body, [0, 255, 128]);
      }
    });

    test('301, 302 and 303 change redirected POST into bodyless GET', () async {
      for (final status in [301, 302, 303]) {
        received.clear();
        await client.post(url('/redirect?status=$status'), body: 'original');
        expect(received.map((entry) => entry.method), ['POST', 'GET']);
        expect(received.last.body, isEmpty);
        expect(received.last.headers, isNot(contains('content-type')));
      }
    });

    test(
      'cross-origin redirect strips credentials while preserving ordinary headers',
      () async {
        final to = Uri.parse('http://127.0.0.1:${destination.port}/echo');
        await client.get(
          url('/redirect').replace(queryParameters: {'to': to.toString()}),
          headers: {
            'Authorization': 'Bearer synthetic',
            'Cookie': 'synthetic=1',
            'Proxy-Authorization': 'synthetic',
            'X-Fixture': 'preserved',
          },
        );
        expect(received, hasLength(2));
        expect(received.first.headers['authorization'], 'Bearer synthetic');
        for (final header in [
          'authorization',
          'cookie',
          'proxy-authorization',
        ]) {
          expect(received.last.headers, isNot(contains(header)));
        }
        expect(received.last.headers['x-fixture'], 'preserved');
      },
    );

    test(
      'manual redirect mode exposes response and maxRedirects is enforced',
      () async {
        final manual = http.Request('GET', url('/redirect'))
          ..followRedirects = false;
        final response = await client.send(manual);
        expect(response.statusCode, 302);
        expect(response.headers['location'], '/echo');
        expect(response.isRedirect, isTrue);
        expect(received, hasLength(1));
        received.clear();
        final loop = http.Request('GET', url('/loop'))..maxRedirects = 2;
        await expectLater(
          client.send(loop),
          throwsA(isA<http.ClientException>()),
        );
        expect(received, hasLength(3));
      },
    );

    test(
      'close settles in-flight requests and rejects subsequent requests',
      () async {
        final pending = client.get(url('/held'));
        final failed = expectLater(
          pending,
          throwsA(isA<http.ClientException>()),
        );
        await arrived.future.timeout(const Duration(seconds: 5));
        client.close();
        await failed.timeout(const Duration(seconds: 2));
        await expectLater(
          client.get(url('/echo')),
          throwsA(isA<http.ClientException>()),
        );
        release.complete();
      },
    );

    test(
      'connection failures become ClientException without leaking URL secrets',
      () async {
        final unused = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port = unused.port;
        await unused.close();
        await expectLater(
          client.get(
            Uri.parse('http://127.0.0.1:$port/private?token=synthetic'),
          ),
          throwsA(
            isA<http.ClientException>().having(
              (e) => e.message,
              'safe diagnostics',
              isNot(contains('synthetic')),
            ),
          ),
        );
      },
    );
  }, skip: !Platform.isWindows);
}
