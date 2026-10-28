import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/transport.dart';

Matcher errorCode(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);

ProviderTransport wire(
  Future<http.BaseResponse> Function(http.BaseRequest) handler, {
  int maxBytes = 4 * 1024 * 1024,
  int maxRetries = 2,
  Duration maxRetryDelay = const Duration(seconds: 8),
  Set<String> redirectHosts = const {},
}) => ProviderTransport(
  client: _Client(handler),
  hostInterval: Duration.zero,
  timeout: const Duration(seconds: 2),
  maxBytes: maxBytes,
  maxRetries: maxRetries,
  retryBaseDelay: const Duration(milliseconds: 1),
  maxRetryDelay: maxRetryDelay,
  redirectHosts: redirectHosts,
);

class _Client extends http.BaseClient {
  _Client(this.handler);
  final Future<http.BaseResponse> Function(http.BaseRequest) handler;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return response is http.StreamedResponse
        ? response
        : http.StreamedResponse(
            http.ByteStream.fromBytes((response as http.Response).bodyBytes),
            response.statusCode,
            headers: response.headers,
            contentLength: response.bodyBytes.length,
          );
  }
}

http.Response redirect(String location, [int code = 302]) =>
    http.Response('', code, headers: {'location': location});

void main() {
  group('response size', () {
    test('streaming body without Content-Length is still capped', () async {
      var chunks = 0;
      final t = wire((request) async {
        Stream<List<int>> body() async* {
          for (var i = 0; i < 100; i++) {
            chunks++;
            yield List.filled(10, 65);
          }
        }

        // No contentLength: only the streaming bound can stop this.
        return http.StreamedResponse(body(), 200);
      }, maxBytes: 35);
      await expectLater(
        t.getText(Uri.parse('https://example.org/')),
        throwsA(errorCode('invalid_response')),
      );
      expect(chunks, lessThan(100), reason: 'reading stops at the cap');
      await t.close();
    });
    test('per-request maxBytes can raise the default but not the ceiling', () async {
      final t = wire((_) async => http.Response('x' * 50, 200), maxBytes: 20);
      await expectLater(
        t.getText(Uri.parse('https://example.org/')),
        throwsA(errorCode('invalid_response')),
      );
      expect(
        (await t.getText(Uri.parse('https://example.org/'), maxBytes: 100))
            .length,
        50,
      );
      await t.close();
    });
  });

  group('invalid input', () {
    test('invalid URLs and a closed transport are failed Futures', () async {
      final t = wire((_) async => http.Response('ok', 200));
      late Future<String> bad;
      expect(
        () => bad = t.requestText(Uri.parse('http://example.org/')),
        returnsNormally,
      );
      await expectLater(bad, throwsA(errorCode('invalid_url')));
      late Future<String> userinfo;
      expect(
        () => userinfo = t.requestText(Uri.parse('https://u:p@example.org/')),
        returnsNormally,
      );
      await expectLater(userinfo, throwsA(errorCode('invalid_url')));
      await t.close();
      late Future<String> closed;
      expect(
        () => closed = t.requestText(Uri.parse('https://example.org/')),
        returnsNormally,
      );
      await expectLater(closed, throwsA(errorCode('transport_closed')));
    });
  });

  group('publisher request windows', () {
    test('an exhausted successful window paces its host only', () async {
      final clock = Stopwatch()..start();
      final attempts = <String, int>{};
      final t = wire((request) async {
        attempts[request.url.host + request.url.path] =
            clock.elapsedMicroseconds;
        return http.Response(
          'ok',
          200,
          headers: request.url.path == '/quota'
              ? {'X-RateLimit-Remaining': '0', 'X-RateLimit-Reset-In': '1'}
              : {},
        );
      });
      try {
        expect(await t.getText(Uri.parse('https://example.org/quota')), 'ok');
        final next = t.getText(Uri.parse('https://example.org/next'));
        expect(
          await t.getText(Uri.parse('https://other.example.org/free')),
          'ok',
        );
        expect(await next, 'ok');
        expect(attempts, hasLength(3));
        expect(
          attempts['other.example.org/free']!,
          lessThan(attempts['example.org/next']!),
        );
        expect(
          attempts['example.org/next']! - attempts['example.org/quota']!,
          greaterThanOrEqualTo(950000),
        );
      } finally {
        await t.close();
      }
    });

    test('429 reset window without Retry-After paces the retry', () async {
      final clock = Stopwatch()..start();
      final attempts = <int>[];
      final t = wire((_) async {
        attempts.add(clock.elapsedMicroseconds);
        return attempts.length == 1
            ? http.Response('busy', 429, headers: {'x-ratelimit-reset-in': '1'})
            : http.Response('ok', 200);
      });
      try {
        expect(await t.getText(Uri.parse('https://example.org/')), 'ok');
        expect(attempts, hasLength(2));
        expect(attempts[1] - attempts[0], greaterThanOrEqualTo(950000));
      } finally {
        await t.close();
      }
    });

    for (final headers in [
      {'retry-after': '0', 'x-ratelimit-reset-in': '1'},
      {'retry-after': '1', 'x-ratelimit-reset-in': '0'},
    ]) {
      test('the longer publisher delay wins: $headers', () async {
        final clock = Stopwatch()..start();
        final attempts = <int>[];
        final t = wire((_) async {
          attempts.add(clock.elapsedMicroseconds);
          return attempts.length == 1
              ? http.Response('busy', 429, headers: headers)
              : http.Response('ok', 200);
        });
        try {
          expect(await t.getText(Uri.parse('https://example.org/')), 'ok');
          expect(attempts, hasLength(2));
          expect(attempts[1] - attempts[0], greaterThanOrEqualTo(950000));
        } finally {
          await t.close();
        }
      });
    }

    test(
      'a reset beyond the retry budget is retained without a retry',
      () async {
        var calls = 0;
        final t = wire((_) async {
          calls++;
          return http.Response(
            'busy',
            429,
            headers: {'retry-after': '0', 'x-ratelimit-reset-in': '86401'},
          );
        }, maxRetryDelay: const Duration(seconds: 5));
        try {
          await expectLater(
            t.getText(Uri.parse('https://example.org/')),
            throwsA(errorCode('rate_limited')),
          );
          expect(calls, 1);
        } finally {
          await t.close();
        }
      },
    );

    test(
      'non-exhausted, malformed and conflicting windows do not delay success',
      () async {
        for (final headers in [
          {'x-ratelimit-remaining': '1', 'x-ratelimit-reset-in': '3600'},
          {'x-ratelimit-remaining': '-1', 'x-ratelimit-reset-in': '3600'},
          {'x-ratelimit-remaining': 'unknown', 'x-ratelimit-reset-in': '3600'},
          {'x-ratelimit-remaining': '0', 'x-ratelimit-reset-in': '-1'},
          {'x-ratelimit-remaining': '0', 'x-ratelimit-reset-in': '1.5'},
          {'x-ratelimit-remaining': '0', 'x-ratelimit-reset-in': 'NaN'},
          {
            'x-ratelimit-remaining': '0',
            'x-ratelimit-reset-in': '99999999999999999999999999',
          },
          {
            'x-ratelimit-remaining': '0',
            'X-RateLimit-Remaining': '1',
            'x-ratelimit-reset-in': '3600',
          },
        ]) {
          var calls = 0;
          final t = wire((_) async {
            calls++;
            return http.Response('ok', 200, headers: headers);
          });
          try {
            await t.getText(Uri.parse('https://example.org/'));
            expect(
              await t
                  .getText(Uri.parse('https://example.org/next'))
                  .timeout(const Duration(seconds: 1)),
              'ok',
            );
            expect(calls, 2);
          } finally {
            await t.close();
          }
        }
      },
    );

    test(
      'headers retain the window when reading the body is cancelled',
      () async {
        final body = StreamController<List<int>>();
        final headersReceived = Completer<void>();
        final cancel = CancellationToken();
        final clock = Stopwatch()..start();
        final attempts = <int>[];
        final t = wire((_) async {
          attempts.add(clock.elapsedMicroseconds);
          if (attempts.length == 1) {
            headersReceived.complete();
            return http.StreamedResponse(
              body.stream,
              200,
              headers: {
                'x-ratelimit-remaining': '0',
                'x-ratelimit-reset-in': '1',
              },
            );
          }
          return http.Response('ok', 200);
        });
        try {
          final first = expectLater(
            t.getText(Uri.parse('https://example.org/first'), cancel: cancel),
            throwsA(errorCode('cancelled')),
          );
          await headersReceived.future;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          cancel.cancel();
          await first;
          await body.close();
          expect(await t.getText(Uri.parse('https://example.org/next')), 'ok');
          expect(attempts, hasLength(2));
          expect(attempts[1] - attempts[0], greaterThanOrEqualTo(950000));
        } finally {
          await t.close();
        }
      },
    );

    test(
      'close interrupts a queued window wait without another send',
      () async {
        var calls = 0;
        final t = wire((_) async {
          calls++;
          return http.Response(
            'ok',
            200,
            headers: {
              'x-ratelimit-remaining': '0',
              'x-ratelimit-reset-in': '3600',
            },
          );
        });
        try {
          await t.getText(Uri.parse('https://example.org/first'));
          final queued = expectLater(
            t.getText(Uri.parse('https://example.org/next')),
            throwsA(errorCode('transport_closed')),
          );
          await Future<void>.delayed(Duration.zero);
          await t.close().timeout(const Duration(seconds: 1));
          await queued;
          expect(calls, 1);
        } finally {
          await t.close();
        }
      },
    );
  });

  group('rate limits', () {
    test('Retry-After survives cancellation of an optional retry', () async {
      final firstResponse = Completer<void>();
      final cancel = CancellationToken();
      final clock = Stopwatch()..start();
      final attempts = <int>[];
      final t = wire((request) async {
        attempts.add(clock.elapsedMicroseconds);
        if (attempts.length == 1) {
          firstResponse.complete();
          return http.Response('busy', 503, headers: {'retry-after': '1'});
        }
        return http.Response('ok', 200);
      });
      try {
        final first = expectLater(
          t.getText(Uri.parse('https://example.org/art'), cancel: cancel),
          throwsA(errorCode('cancelled')),
        );
        await firstResponse.future;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        cancel.cancel();
        await first;
        expect(
          await t.getText(Uri.parse('https://example.org/recording')),
          'ok',
        );
        expect(attempts, hasLength(2), reason: 'no cancelled retry is sent');
        expect(attempts[1] - attempts[0], greaterThanOrEqualTo(950000));
      } finally {
        await t.close();
      }
    });
    test(
      'exhausted retry budget preserves cooldown without blocking other hosts',
      () async {
        final clock = Stopwatch()..start();
        final attempts = <String, int>{};
        final t = wire((request) async {
          attempts[request.url.host + request.url.path] =
              clock.elapsedMicroseconds;
          return request.url.path == '/limited'
              ? http.Response('busy', 429, headers: {'retry-after': '1'})
              : http.Response('ok', 200);
        }, maxRetries: 0);
        try {
          await expectLater(
            t.getText(Uri.parse('https://example.org/limited')),
            throwsA(errorCode('rate_limited')),
          );
          final next = t.getText(Uri.parse('https://example.org/next'));
          expect(
            await t.getText(Uri.parse('https://other.example.org/free')),
            'ok',
          );
          expect(await next, 'ok');
          expect(
            attempts['other.example.org/free']!,
            lessThan(attempts['example.org/next']!),
          );
          expect(
            attempts['example.org/next']! - attempts['example.org/limited']!,
            greaterThanOrEqualTo(950000),
          );
        } finally {
          await t.close();
        }
      },
    );
    test('SyncLRC routes and immediate retries share the 30/min queue', () async {
      final clock = Stopwatch()..start();
      final attempts = <int>[];
      final t = wire((_) async {
        attempts.add(clock.elapsedMicroseconds);
        return attempts.length == 1
            ? http.Response('slow down', 429, headers: {'retry-after': '0'})
            : http.Response('ok', 200);
      });
      try {
        expect(
          await Future.wait([
            t.getText(Uri.parse('https://api.synclrc.dev/search?q=fixture')),
            t.getText(
              Uri.parse(
                'https://api.synclrc.dev/lyrics/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              ),
            ),
          ]),
          ['ok', 'ok'],
        );
        expect(attempts, hasLength(3));
        for (var i = 1; i < attempts.length; i++) {
          expect(attempts[i] - attempts[i - 1], greaterThanOrEqualTo(2000000));
        }
      } finally {
        await t.close();
      }
    });
    test('MusicBrainz apex and www requests share one paced queue', () async {
      final clock = Stopwatch()..start();
      final attempts = <int>[];
      final t = wire((_) async {
        attempts.add(clock.elapsedMicroseconds);
        return http.Response('ok', 200);
      });
      try {
        expect(
          await Future.wait([
            t.getText(Uri.parse('https://musicbrainz.org/ws/2/recording')),
            t.getText(Uri.parse('https://www.musicbrainz.org/ws/2/recording')),
          ]),
          ['ok', 'ok'],
        );
        expect(attempts[1] - attempts[0], greaterThanOrEqualTo(1000000));
      } finally {
        await t.close();
      }
    });
    test(
      '503 (MusicBrainz rate limiting) maps to rate_limited after bounded retries',
      () async {
        var calls = 0;
        final clock = Stopwatch()..start();
        final attempts = <int>[];
        final t = wire((_) async {
          calls++;
          attempts.add(clock.elapsedMicroseconds);
          return http.Response('busy', 503, headers: {'retry-after': '0'});
        });
        await expectLater(
          t.getText(Uri.parse('https://musicbrainz.org/')),
          throwsA(errorCode('rate_limited')),
        );
        expect(calls, 3, reason: 'one request plus two retries');
        for (var i = 1; i < attempts.length; i++) {
          expect(
            attempts[i] - attempts[i - 1],
            greaterThanOrEqualTo(1000000),
            reason:
                'Retries also count toward MusicBrainz one-request-per-second limit',
          );
        }
        await t.close();
      },
    );
    test('a 429 with Retry-After recovers on the retry', () async {
      var calls = 0;
      final t = wire((_) async {
        calls++;
        return calls == 1
            ? http.Response('slow down', 429, headers: {'retry-after': '0'})
            : http.Response('ok', 200);
      });
      expect(await t.getText(Uri.parse('https://example.org/')), 'ok');
      expect(calls, 2);
      await t.close();
    });
    test('Retry-After beyond the cap is not waited for', () async {
      var calls = 0;
      final t = wire(
        (_) async {
          calls++;
          return http.Response('later', 429, headers: {'retry-after': '3600'});
        },
        maxRetryDelay: const Duration(seconds: 5),
      );
      await expectLater(
        t.getText(Uri.parse('https://example.org/')),
        throwsA(errorCode('rate_limited')),
      );
      expect(calls, 1);
      await t.close();
    });
    test('other 5xx and non-GET requests are not retried', () async {
      var calls = 0;
      final t = wire((_) async {
        calls++;
        return http.Response('boom', calls <= 1 ? 500 : 503);
      });
      await expectLater(
        t.getText(Uri.parse('https://example.org/a')),
        throwsA(errorCode('network')),
      );
      expect(calls, 1);
      calls = 1;
      await expectLater(
        t.requestJson(
          Uri.parse('https://example.org/b'),
          method: 'POST',
          body: {'a': 1},
        ),
        throwsA(errorCode('rate_limited')),
      );
      expect(calls, 2, reason: 'a POST gets exactly one attempt');
      await t.close();
    });
    test('cf-mitigated responses are reported as blocked', () async {
      final t = wire(
        (_) async =>
            http.Response('', 403, headers: {'cf-mitigated': 'challenge'}),
      );
      await expectLater(
        t.getText(Uri.parse('https://example.org/')),
        throwsA(
          isA<ProviderException>()
              .having((e) => e.code, 'code', 'blocked')
              .having((e) => e.message, 'message', 'cloudflare'),
        ),
      );
      await t.close();
    });
  });

  group('redirects', () {
    test('same-host redirects are followed and re-validated', () async {
      final seen = <String>[];
      final t = wire((request) async {
        seen.add(request.url.toString());
        return request.url.path == '/old'
            ? redirect('/new')
            : http.Response('landed', 200);
      });
      expect(await t.getText(Uri.parse('https://example.org/old')), 'landed');
      expect(seen, ['https://example.org/old', 'https://example.org/new']);
      await t.close();
    });
    test('www and apex twins are treated as the same site', () async {
      final t = wire((request) async => request.url.host == 'example.org'
          ? redirect('https://www.example.org/x')
          : http.Response('www', 200));
      expect(await t.getText(Uri.parse('https://example.org/')), 'www');
      await t.close();
    });
    test('cross-host, plaintext and malformed redirects are refused', () async {
      for (final location in [
        'https://evil.example/steal',
        'http://example.org/downgrade',
        'https://user:pw@example.org/x',
        'https://example.org:8443/x',
        '',
      ]) {
        var calls = 0;
        final t = wire((_) async {
          calls++;
          return redirect(location);
        });
        await expectLater(
          t.getText(Uri.parse('https://example.org/')),
          throwsA(errorCode('redirect')),
          reason: location,
        );
        expect(calls, 1, reason: 'never follows $location');
        await t.close();
      }
    });
    test('hop count is bounded at three', () async {
      var calls = 0;
      final t = wire((_) async {
        calls++;
        return redirect('/hop$calls');
      });
      await expectLater(
        t.getText(Uri.parse('https://example.org/')),
        throwsA(errorCode('redirect')),
      );
      expect(calls, 4, reason: 'original request plus three hops');
      await t.close();
      var three = 0;
      final ok = wire((request) async {
        three++;
        return three <= 3 ? redirect('/next$three') : http.Response('end', 200);
      });
      expect(await ok.getText(Uri.parse('https://example.org/')), 'end');
      await ok.close();
    });
    test('Authorization survives same-host hops, never reaches another host', () async {
      final auth = <String, String?>{};
      final t = wire((request) async {
        auth[request.url.toString()] = request.headers['Authorization'];
        if (request.url.path == '/a') return redirect('/b');
        if (request.url.path == '/b') return redirect('https://cdn.example.net/c');
        return http.Response('done', 200);
      }, redirectHosts: {'cdn.example.net'});
      await t.getText(
        Uri.parse('https://example.org/a'),
        headers: {'Authorization': 'Bearer secret', 'Cookie': 'a=b'},
      );
      expect(auth['https://example.org/a'], 'Bearer secret');
      expect(auth['https://example.org/b'], 'Bearer secret');
      expect(auth['https://cdn.example.net/c'], isNull);
      await t.close();
    });
    test('cross-host redirect is refused unless allowlisted, and never leaks the token', () async {
      final hosts = <String>[];
      final t = wire((request) async {
        hosts.add(request.url.host);
        return redirect('https://other.example.net/');
      });
      await expectLater(
        t.getText(
          Uri.parse('https://example.org/'),
          headers: {'Authorization': 'Bearer secret'},
        ),
        throwsA(errorCode('redirect')),
      );
      expect(hosts, ['example.org']);
      await t.close();
    });
    test('a redirect on POST becomes a body-less GET', () async {
      final seen = <String>[];
      final t = wire((request) async {
        seen.add('${request.method} ${request.url.path}');
        return request.url.path == '/post'
            ? redirect('/done', 303)
            : http.Response('{}', 200);
      });
      await t.requestJson(
        Uri.parse('https://example.org/post'),
        method: 'POST',
        body: {'a': 1},
      );
      expect(seen, ['POST /post', 'GET /done']);
      await t.close();
    });
    test('consent redirect target is named in the error for adapters', () async {
      final t = wire((_) async => redirect('https://consent.youtube.com/x'));
      await expectLater(
        t.getText(Uri.parse('https://music.youtube.com/')),
        throwsA(
          isA<ProviderException>()
              .having((e) => e.code, 'code', 'redirect')
              .having((e) => e.message, 'message', contains('consent.')),
        ),
      );
      await t.close();
    });
  });

  group('decoding and identity', () {
    test('Content-Type charset is honoured, UTF-8 is the fallback', () async {
      http.Response bytes(List<int> body, String? type) => http.Response.bytes(
        body,
        200,
        headers: {'content-type': ?type},
      );
      final cases = <(List<int>, String?, String)>[
        ([0x63, 0x61, 0x66, 0xE9], 'text/html; charset=ISO-8859-1', 'café'),
        ([0x93, 0x68, 0x69, 0x94], 'text/plain; charset="windows-1252"', '“hi”'),
        (utf8.encode('café'), 'text/html; charset=utf-8', 'café'),
        (utf8.encode('café'), 'text/html', 'café'),
        (utf8.encode('café'), 'text/html; charset=unknown-9', 'café'),
        ([0xEF, 0xBB, 0xBF, ...utf8.encode('{"a":1}')], null, '{"a":1}'),
      ];
      for (final c in cases) {
        final t = wire((_) async => bytes(c.$1, c.$2));
        expect(await t.getText(Uri.parse('https://example.org/')), c.$3);
        await t.close();
      }
    });
    test('User-Agent carries the version and an API operator contact', () async {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(
        r'^version:\s*(\d+\.\d+\.\d+)',
        multiLine: true,
      ).firstMatch(pubspec)![1];
      expect(singbookVersion, version);
      String? agent;
      final t = wire((request) async {
        agent = request.headers['User-Agent'];
        return http.Response('ok', 200);
      });
      await t.getText(Uri.parse('https://example.org/'));
      expect(agent, startsWith('Singbook/$version'));
      expect(singbookContactUrl, isNotEmpty);
      expect(agent, contains('(+$singbookContactUrl)'));
      if (const String.fromEnvironment('SINGBOOK_CONTACT_URL') == '') {
        expect(singbookContactUrl, 'https://github.com/freevia-org/Singbook');
      }
      expect(agent, isNot(contains('freevia.org')));
      await t.close();
    });
  });
}
