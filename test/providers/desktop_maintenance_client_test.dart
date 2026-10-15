import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/core/youtube_music.dart';
import 'package:singbook/providers/provider.dart';

import '../../tool/source_maintenance.dart';

void main() {
  test('final headers replace proxy CONNECT and Early Hints headers', () {
    final headers = parseDesktopResponseHeaders(
      'HTTP/1.1 200 Connection established\r\n'
      'Proxy-Agent: synthetic-proxy\r\n\r\n'
      'HTTP/2 103\r\n'
      'Link: </early>; rel=preload\r\n'
      'Location: /not-the-final-location\r\n\r\n'
      'HTTP/2 302\r\n'
      'Location: https://consent.youtube.com/m?continue=synthetic\r\n'
      'Content-Type: text/html; charset=utf-8\r\n'
      'Retry-After: 9\r\n'
      'Vary: Accept-Encoding\r\n'
      'vary: Origin\r\n\r\n',
      302,
    );
    expect(headers, {
      'location': 'https://consent.youtube.com/m?continue=synthetic',
      'content-type': 'text/html; charset=utf-8',
      'retry-after': '9',
      'vary': 'Accept-Encoding, Origin',
    });
  });

  test('does not reuse an earlier header block for another final status', () {
    expect(
      parseDesktopResponseHeaders(
        'HTTP/1.1 200 Connection established\r\n'
        'Location: https://example.org/stale\r\n\r\n'
        'HTTP/2 103\r\nLink: </early>\r\n\r\n',
        302,
      ),
      isEmpty,
    );
  });

  test(
    'real curl preserves a same-host redirect for transport validation',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final paths = <String>[];
      server.listen((request) async {
        paths.add(request.uri.path);
        if (request.uri.path == '/start') {
          request.response
            ..statusCode = 302
            ..headers.set('location', '/final');
        } else {
          request.response
            ..headers.set('content-type', 'text/plain; charset=iso-8859-1')
            ..add([0x63, 0x61, 0x66, 0xe9]);
        }
        await request.response.close();
      });
      final transport = ProviderTransport(
        client: _LoopbackClient(
          DesktopMaintenanceClient(
            curlExecutable: Platform.isWindows ? 'curl.exe' : 'curl',
          ),
          Uri.parse('http://127.0.0.1:${server.port}/'),
        ),
        hostInterval: Duration.zero,
      );
      try {
        expect(
          await transport.getText(Uri.parse('https://example.org/start')),
          'caf\u00e9',
        );
        expect(paths, ['/start', '/final']);
      } finally {
        await transport.close();
        await server.close(force: true);
      }
    },
  );

  test(
    'real curl consent redirect reaches the adapter without being followed',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var calls = 0;
      server.listen((request) async {
        calls++;
        expect(request.headers.value('cookie'), isNull);
        request.response
          ..statusCode = 302
          ..headers.set(
            'location',
            'https://consent.youtube.com/m?continue=synthetic',
          )
          ..write('Synthetic consent redirect');
        await request.response.close();
      });
      final client = DesktopMaintenanceClient(
        curlExecutable: Platform.isWindows ? 'curl.exe' : 'curl',
      );
      final transport = ProviderTransport(
        client: _LoopbackClient(
          client,
          Uri.parse('http://127.0.0.1:${server.port}/'),
        ),
        hostInterval: Duration.zero,
      );
      try {
        await expectLater(
          YoutubeMusicProvider(transport).search('Synthetic song'),
          throwsA(
            isA<ProviderException>()
                .having((error) => error.code, 'code', 'blocked')
                .having(
                  (error) => error.message,
                  'message',
                  'consent_required',
                ),
          ),
        );
        expect(calls, 1);
      } finally {
        await transport.close();
        await server.close(force: true);
      }
    },
  );
}

/// Route the homepage to an isolated synthetic server; production still
/// validates the requested HTTPS host and rejects the cross-host redirect.
class _LoopbackClient extends http.BaseClient {
  _LoopbackClient(this.client, this.url);
  final http.Client client;
  final Uri url;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => client.send(
    http.Request(
      request.method,
      url.replace(path: request.url.path, query: request.url.query),
    )..headers.addAll(request.headers),
  );

  @override
  void close() => client.close();
}
