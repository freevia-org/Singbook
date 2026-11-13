import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/windows_http_client.dart';

void main() {
  group('Windows WinHTTP abort', () {
    // A raw loopback socket fixture: it observes the peer closing its
    // connection, which dart:io's HttpServer hides from response writers.
    late ServerSocket server;
    late WindowsHttpClient client;
    late Completer<void> arrived;
    late Completer<void> disconnected;
    final timers = <Timer>[];

    setUp(() async {
      arrived = Completer<void>();
      disconnected = Completer<void>();
      server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((socket) {
        var answered = false;
        void gone() {
          if (answered && !disconnected.isCompleted) disconnected.complete();
        }

        unawaited(socket.done.then<void>((_) {}, onError: (Object _) {}));
        socket.listen(
          (data) {
            if (answered) return;
            final head = latin1.decode(data);
            if (head.startsWith('GET /held ')) {
              answered = true;
              socket.write(
                'HTTP/1.1 200 OK\r\n'
                'Content-Type: application/octet-stream\r\n'
                'Transfer-Encoding: chunked\r\n\r\n',
              );
              void chunk() {
                try {
                  socket.write('400\r\n${'A' * 1024}\r\n');
                } on Object {
                  gone();
                }
              }

              chunk();
              if (!arrived.isCompleted) arrived.complete();
              // The body never ends: only an abort can finish this request.
              timers.add(
                Timer.periodic(const Duration(milliseconds: 20), (_) => chunk()),
              );
            } else {
              socket.write(
                'HTTP/1.1 200 OK\r\nContent-Length: 2\r\n'
                'Connection: close\r\n\r\nok',
              );
              unawaited(
                socket.flush().then<void>(
                  (_) => socket.destroy(),
                  onError: (Object _) {},
                ),
              );
            }
          },
          onDone: gone,
          onError: (Object _) => gone(),
          cancelOnError: true,
        );
      });
      client = WindowsHttpClient();
    });
    tearDown(() async {
      for (final timer in timers) {
        timer.cancel();
      }
      timers.clear();
      client.close();
      await server.close();
    });
    Uri url(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');

    test('abortTrigger fails the request and stops the native worker', () async {
      final abort = Completer<void>();
      final request = http.AbortableRequest(
        'GET',
        url('/held'),
        abortTrigger: abort.future,
      );
      final response = client.send(request);
      await arrived.future.timeout(const Duration(seconds: 10));
      abort.complete();
      await expectLater(
        response.timeout(const Duration(seconds: 2)),
        throwsA(isA<http.RequestAbortedException>()),
      );
      // The worker notices the flag between reads and closes its handles, so
      // the fixture sees the connection go away while the body is still open.
      await disconnected.future.timeout(const Duration(seconds: 10));
      // The client remains usable for later requests.
      expect((await client.get(url('/echo'))).body, 'ok');
    });

    test('a trigger that fires after completion is ignored', () async {
      final abort = Completer<void>();
      final request = http.AbortableRequest(
        'GET',
        url('/echo'),
        abortTrigger: abort.future,
      );
      final response = await client.send(request);
      expect(await response.stream.bytesToString(), 'ok');
      abort.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect((await client.get(url('/echo'))).body, 'ok');
    });
  }, skip: !Platform.isWindows);
}
