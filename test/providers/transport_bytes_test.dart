import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/transport.dart';

Matcher _code(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);

class _Client extends http.BaseClient {
  _Client(this.handler);
  final Future<http.BaseResponse> Function(http.BaseRequest) handler;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    if (response is http.StreamedResponse) return response;
    final full = response as http.Response;
    return http.StreamedResponse(
      http.ByteStream.fromBytes(full.bodyBytes),
      full.statusCode,
      headers: full.headers,
      contentLength: full.bodyBytes.length,
    );
  }
}

ProviderTransport _transport(
  Future<http.BaseResponse> Function(http.BaseRequest) handler, {
  int maxBytes = 1024,
  int maxRetries = 0,
  Set<String> redirectHosts = const {},
}) => ProviderTransport(
  client: _Client(handler),
  hostInterval: Duration.zero,
  timeout: const Duration(seconds: 2),
  maxBytes: maxBytes,
  maxRetries: maxRetries,
  retryBaseDelay: Duration.zero,
  maxRetryDelay: Duration.zero,
  redirectHosts: redirectHosts,
);

http.Response _redirect(String location) =>
    http.Response('', 302, headers: {'location': location});

void main() {
  test(
    'returns binary bytes unchanged even when they are not valid UTF-8',
    () async {
      final bytes = Uint8List.fromList([0x50, 0x4b, 0xff, 0xfe, 0x00]);
      final transport = _transport(
        (_) async => http.Response.bytes(bytes, 200),
      );
      try {
        expect(
          await transport.getBytes(Uri.parse('https://files.example/a.zip')),
          bytes,
        );
      } finally {
        await transport.close();
      }
    },
  );

  test('enforces declared and streamed response size limits', () async {
    final declared = _transport(
      (_) async => http.StreamedResponse(
        const Stream<List<int>>.empty(),
        200,
        contentLength: 20,
      ),
      maxBytes: 10,
    );
    try {
      await expectLater(
        declared.getBytes(Uri.parse('https://files.example/a.zip')),
        throwsA(_code('invalid_response')),
      );
    } finally {
      await declared.close();
    }

    var chunks = 0;
    final streamed = _transport((_) async {
      Stream<List<int>> source() async* {
        for (var i = 0; i < 20; i++) {
          chunks++;
          yield List.filled(4, i);
        }
      }

      return http.StreamedResponse(source(), 200);
    }, maxBytes: 10);
    try {
      await expectLater(
        streamed.getBytes(Uri.parse('https://files.example/a.zip')),
        throwsA(_code('invalid_response')),
      );
      expect(chunks, lessThan(20));
    } finally {
      await streamed.close();
    }
  });

  test(
    'enforces allowed hosts on initial request and redirect destinations',
    () async {
      var calls = 0;
      final deniedInitial = _transport((_) async {
        calls++;
        return http.Response.bytes([1], 200);
      });
      try {
        await expectLater(
          deniedInitial.getBytes(
            Uri.parse('https://evil.example/a'),
            allowedHosts: {'files.example'},
          ),
          throwsA(_code('invalid_url')),
        );
        expect(calls, 0);
      } finally {
        await deniedInitial.close();
      }

      final deniedRedirect = _transport((request) async {
        calls++;
        return _redirect('https://cdn.example/a.zip');
      }, redirectHosts: {'cdn.example'});
      try {
        await expectLater(
          deniedRedirect.getBytes(
            Uri.parse('https://files.example/a.zip'),
            allowedHosts: {'files.example'},
          ),
          throwsA(_code('redirect')),
        );
        expect(calls, 1);
      } finally {
        await deniedRedirect.close();
      }
    },
  );

  test('allowed cross-host redirect strips credentials', () async {
    final seen = <http.BaseRequest>[];
    final transport = _transport((request) async {
      seen.add(request);
      return request.url.host == 'files.example'
          ? _redirect('https://cdn.example/archive.zip')
          : http.Response.bytes([1, 2, 3], 200);
    }, redirectHosts: {'cdn.example'});
    try {
      final bytes = await transport.getBytes(
        Uri.parse('https://files.example/archive.zip'),
        headers: {
          'Authorization': 'Bearer private',
          'Cookie': 'session=private',
          'X-Note': 'ok',
        },
        allowedHosts: {'files.example', 'cdn.example'},
      );
      expect(bytes, [1, 2, 3]);
      expect(seen[0].headers['authorization'], 'Bearer private');
      expect(seen[1].headers.containsKey('authorization'), isFalse);
      expect(seen[1].headers.containsKey('cookie'), isFalse);
      expect(seen[1].headers['x-note'], 'ok');
    } finally {
      await transport.close();
    }
  });

  test(
    'cancellation before queue prevents HTTP and closed transport rejects requests',
    () async {
      var calls = 0;
      final transport = _transport((_) async {
        calls++;
        return http.Response.bytes([1], 200);
      });
      final token = CancellationToken()..cancel();
      await expectLater(
        transport.getBytes(
          Uri.parse('https://files.example/a.zip'),
          cancel: token,
        ),
        throwsA(_code('cancelled')),
      );
      expect(calls, 0);
      await transport.close();
      await expectLater(
        transport.getBytes(Uri.parse('https://files.example/a.zip')),
        throwsA(_code('transport_closed')),
      );
    },
  );

  test('cancelling an in-flight byte request aborts its caller', () async {
    final entered = Completer<void>();
    final release = Completer<http.BaseResponse>();
    final transport = _transport((_) {
      if (!entered.isCompleted) entered.complete();
      return release.future;
    });
    final token = CancellationToken();
    final request = transport.getBytes(
      Uri.parse('https://files.example/a.zip'),
      cancel: token,
    );
    await entered.future;
    token.cancel();
    await expectLater(request, throwsA(_code('cancelled')));
    release.complete(http.Response.bytes([1, 2, 3], 200));
    await transport.close();
  });

  test(
    'retries a retryable GET and returns the successful binary body',
    () async {
      var calls = 0;
      final transport = _transport((_) async {
        calls++;
        return calls == 1
            ? http.Response('', 503, headers: {'retry-after': '0'})
            : http.Response.bytes([0x50, 0x4b, 0x00], 200);
      }, maxRetries: 1);
      try {
        expect(
          await transport.getBytes(Uri.parse('https://files.example/a.zip')),
          [0x50, 0x4b, 0x00],
        );
        expect(calls, 2);
      } finally {
        await transport.close();
      }
    },
  );
}
