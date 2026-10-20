import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/native_client_flutter.dart';
import 'package:singbook/providers/transport.dart';

void main() {
  group('Windows native HTTP runtime', () {
    late _EarlyHintsServer server;
    late http.Client client;

    setUp(() async {
      server = await _EarlyHintsServer.start();
      client = createNativeHttpClient();
    });

    tearDown(() async {
      client.close();
      await server.close();
    });

    test('loopback fixture returns a normal final response', () async {
      final response = await client
          .get(server.url('/plain'))
          .timeout(const Duration(seconds: 5));

      expect(response.statusCode, 200);
      expect(response.body, 'final /plain — café');
      expect(response.headers['x-phase'], 'final');
    });

    test('103 is consumed before the final 200 body and headers', () async {
      final response = await client
          .get(server.url('/song'))
          .timeout(const Duration(seconds: 5));

      expect(response.statusCode, 200);
      expect(response.body, 'final /song — café');
      expect(response.headers['x-phase'], 'final');
      expect(response.headers['content-type'], 'text/plain; charset=utf-8');
      expect(response.headers, isNot(contains('x-early-only')));
      expect(response.headers, isNot(contains('location')));
    });

    test(
      '103 does not hide a redirect when automatic following is off',
      () async {
        final request = http.Request('GET', server.url('/redirect'))
          ..followRedirects = false;
        final streamed = await client
            .send(request)
            .timeout(const Duration(seconds: 5));
        final response = await http.Response.fromStream(streamed);

        expect(response.statusCode, 302);
        expect(response.headers['location'], '/final');
        expect(response.headers['x-phase'], 'redirect');
        expect(response.body, isEmpty);
        expect(server.requests.map((request) => request.path), ['/redirect']);
      },
    );

    test('repeated concurrent redirects return each final response', () async {
      for (var round = 0; round < 3; round++) {
        final replies = await Future.wait([
          for (var index = 0; index < 4; index++)
            client.get(server.url('/redirect?id=$round-$index')),
        ]).timeout(const Duration(seconds: 5));

        for (var index = 0; index < replies.length; index++) {
          expect(replies[index].statusCode, 200);
          expect(replies[index].body, 'final /final?id=$round-$index — café');
          expect(replies[index].headers['x-phase'], 'final');
          expect(replies[index].headers, isNot(contains('x-early-only')));
          expect(replies[index].headers, isNot(contains('location')));
        }
      }
      expect(server.requests, hasLength(24));
    });

    test(
      'provider transport consumes final headers and follows its redirect',
      () async {
        final transport = ProviderTransport(
          client: _LoopbackClient(client, server),
          hostInterval: Duration.zero,
          maxRetries: 0,
          timeout: const Duration(seconds: 5),
        );
        addTearDown(transport.close);

        final body = await transport.getText(
          Uri.parse('https://fixture.singbook.test/redirect?id=provider'),
          headers: {'X-Fixture-Request': 'preserved'},
        );

        expect(body, 'final /final?id=provider — café');
        expect(server.requests.map((request) => request.path), [
          '/redirect?id=provider',
          '/final?id=provider',
        ]);
        for (final request in server.requests) {
          expect(request.headers['x-fixture-request'], 'preserved');
          expect(request.headers['user-agent'], providerUserAgent);
        }
      },
    );
  }, skip: !Platform.isWindows);
}

// ProviderTransport requires HTTPS and port 443. Only this test client maps
// those public-shaped URLs to the raw loopback fixture; production URL and
// redirect validation still executes before every native request.
class _LoopbackClient extends http.BaseClient {
  _LoopbackClient(this.native, this.server);

  final http.Client native;
  final _EarlyHintsServer server;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final local =
        http.Request(
            request.method,
            server.url(request.url.path).replace(query: request.url.query),
          )
          ..followRedirects = request.followRedirects
          ..maxRedirects = request.maxRedirects
          ..headers.addAll(request.headers)
          ..bodyBytes = await request.finalize().toBytes();
    return native.send(local);
  }
}

typedef _ReceivedRequest = ({String path, Map<String, String> headers});

class _EarlyHintsServer {
  _EarlyHintsServer(this.listener);

  final ServerSocket listener;
  final Set<Socket> sockets = {};
  final List<_ReceivedRequest> requests = [];
  late final StreamSubscription<Socket> subscription;

  static Future<_EarlyHintsServer> start() async {
    final server = _EarlyHintsServer(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    );
    server.subscription = server.listener.listen(server._accept);
    return server;
  }

  Uri url(String path) => Uri.parse('http://127.0.0.1:${listener.port}$path');

  void _accept(Socket socket) {
    sockets.add(socket);
    final bytes = <int>[];
    var responded = false;
    socket.listen(
      (chunk) {
        if (responded) return;
        bytes.addAll(chunk);
        final header = latin1.decode(bytes);
        final end = header.indexOf('\r\n\r\n');
        if (end < 0) return;
        responded = true;
        final lines = header.substring(0, end).split('\r\n');
        final path = lines.first.split(' ')[1];
        final headers = <String, String>{};
        for (final line in lines.skip(1)) {
          final colon = line.indexOf(':');
          if (colon > 0) {
            headers[line.substring(0, colon).toLowerCase()] = line
                .substring(colon + 1)
                .trim();
          }
        }
        requests.add((path: path, headers: headers));
        unawaited(_respond(socket, path));
      },
      onDone: () {
        sockets.remove(socket);
        socket.destroy();
      },
      onError: (Object _) {
        sockets.remove(socket);
        socket.destroy();
      },
    );
  }

  Future<void> _respond(Socket socket, String path) async {
    final uri = Uri.parse(path);
    final redirect = uri.path == '/redirect';
    final body = redirect ? <int>[] : utf8.encode('final $path — café');
    final location = Uri(
      path: '/final',
      query: uri.hasQuery ? uri.query : null,
    ).toString();
    const earlyHints =
        'HTTP/1.1 103 Early Hints\r\n'
        'Link: </unused.css>; rel=preload; as=style\r\n'
        'Content-Type: text/plain; charset=iso-8859-1\r\n'
        'Location: /wrong\r\n'
        'X-Early-Only: informational\r\n'
        'X-Phase: early\r\n\r\n';
    try {
      socket.add(
        ascii.encode(
          '${uri.path == '/plain' ? '' : earlyHints}'
          'HTTP/1.1 ${redirect ? '302 Found' : '200 OK'}\r\n'
          '${redirect ? 'Location: $location\r\n' : ''}'
          'Content-Type: text/plain; charset=utf-8\r\n'
          'X-Phase: ${redirect ? 'redirect' : 'final'}\r\n'
          'Content-Length: ${body.length}\r\n'
          'Connection: close\r\n\r\n',
        ),
      );
      socket.add(body);
      await socket.flush();
      await socket.close();
    } on SocketException {
      // A client rejecting the informational response may close immediately.
    } finally {
      sockets.remove(socket);
      socket.destroy();
    }
  }

  Future<void> close() async {
    await subscription.cancel();
    await listener.close();
    for (final socket in sockets.toList()) {
      socket.destroy();
    }
    sockets.clear();
  }
}
