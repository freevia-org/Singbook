import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/transport.dart';

Matcher _code(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);

class _Client extends http.BaseClient {
  _Client(this.handler);
  final http.Response Function(http.BaseRequest) handler;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = handler(request);
    return http.StreamedResponse(
      http.ByteStream.fromBytes(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      contentLength: response.bodyBytes.length,
    );
  }
}

ProviderTransport _wire(http.Response Function(http.BaseRequest) handler) =>
    ProviderTransport(
      client: _Client(handler),
      hostInterval: Duration.zero,
      timeout: const Duration(seconds: 2),
      retryBaseDelay: const Duration(milliseconds: 1),
      maxRetryDelay: const Duration(seconds: 2),
    );

void main() {
  test('a cooldown beyond the retry cap fails later requests at once', () async {
    final calls = <String>[];
    final t = _wire((request) {
      calls.add(request.url.host + request.url.path);
      return request.url.path == '/limited'
          ? http.Response('later', 429, headers: {'retry-after': '3600'})
          : http.Response('ok', 200);
    });
    try {
      await expectLater(
        t.getText(Uri.parse('https://example.org/limited')),
        throwsA(_code('rate_limited')),
      );
      // No token and no outer timeout: this used to sleep for the whole hour
      // inside the host queue, with later requests stacked behind it.
      final clock = Stopwatch()..start();
      await expectLater(
        t.getText(Uri.parse('https://example.org/next')),
        throwsA(_code('rate_limited')),
      );
      await expectLater(
        t.getText(Uri.parse('https://example.org/again')),
        throwsA(_code('rate_limited')),
      );
      expect(clock.elapsed, lessThan(const Duration(seconds: 1)));
      expect(calls, ['example.org/limited']);
      // Other hosts are unaffected.
      expect(await t.getText(Uri.parse('https://other.example.org/')), 'ok');
    } finally {
      await t.close();
    }
  });

  test('an exhausted window on a successful response fails fast too', () async {
    var calls = 0;
    final t = _wire((_) {
      calls++;
      return http.Response(
        'ok',
        200,
        headers: {'x-ratelimit-remaining': '0', 'x-ratelimit-reset-in': '600'},
      );
    });
    try {
      expect(await t.getText(Uri.parse('https://example.org/first')), 'ok');
      await expectLater(
        t.getText(Uri.parse('https://example.org/next')),
        throwsA(_code('rate_limited')),
      );
      expect(calls, 1);
    } finally {
      await t.close();
    }
  });

  test('a cooldown within the retry cap is still waited for', () async {
    final clock = Stopwatch()..start();
    final attempts = <int>[];
    final t = _wire((_) {
      attempts.add(clock.elapsedMilliseconds);
      return http.Response(
        'ok',
        200,
        headers: attempts.length == 1
            ? {'x-ratelimit-remaining': '0', 'x-ratelimit-reset-in': '1'}
            : const {},
      );
    });
    try {
      await t.getText(Uri.parse('https://example.org/first'));
      expect(await t.getText(Uri.parse('https://example.org/next')), 'ok');
      expect(attempts, hasLength(2));
      expect(attempts[1] - attempts[0], greaterThanOrEqualTo(950));
    } finally {
      await t.close();
    }
  });
}
