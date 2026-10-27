import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/transport.dart';
import 'transport_test.dart' as fixture;

void main() {
  final url = Uri.parse('https://lyrics.example.org/song/one');
  test(
    'conditional JSON returns parsed bytes and safe ETag then accepts a matching304',
    () async {
      var calls = 0;
      final transport = fixture.wire((request) async {
        calls++;
        expect(request.headers['accept'], 'application/json');
        if (calls == 1) {
          expect(request.headers['if-none-match'], isNull);
          return http.Response(
            '{"id":"one"}',
            200,
            headers: {'etag': '"song-one"', 'set-cookie': 'not-exposed=1'},
          );
        }
        expect(request.headers['if-none-match'], '"song-one"');
        return http.Response(
          'not JSON',
          304,
          headers: {'etag': 'W/"song-one"'},
        );
      });
      try {
        final first = await transport.getConditionalJson(url);
        expect(first.value, {'id': 'one'});
        expect(first.etag, '"song-one"');
        expect(first.notModified, false);
        expect(utf8.decode(first.bytes!), '{"id":"one"}');
        expect(() => first.bytes![0] = 0, throwsUnsupportedError);
        final second = await transport.getConditionalJson(
          url,
          etag: first.etag,
        );
        expect(second.value, isNull);
        expect(second.etag, 'W/"song-one"');
        expect(second.notModified, true);
        expect(second.bytes, isNull);
        expect(calls, 2);
      } finally {
        await transport.close();
      }
    },
  );
  test('ordinary and unconditioned304 remain rejected', () async {
    final transport = fixture.wire((r) async => http.Response('', 304));
    try {
      await expectLater(
        transport.getText(url),
        throwsA(fixture.errorCode('redirect')),
      );
      await expectLater(
        transport.getConditionalJson(url),
        throwsA(fixture.errorCode('redirect')),
      );
    } finally {
      await transport.close();
    }
  });
  test('malformed request ETag is a failed Future before any HTTP', () async {
    var calls = 0;
    final transport = fixture.wire((r) async {
      calls++;
      return http.Response('{}', 200);
    });
    try {
      for (final tag in [
        'unquoted',
        '"safe"\r\nCookie: secret',
        '"${'x' * 513}"',
        '"quote"inside"',
      ]) {
        await expectLater(
          transport.getConditionalJson(url, etag: tag),
          throwsA(fixture.errorCode('invalid_response')),
        );
      }
      expect(calls, 0);
    } finally {
      await transport.close();
    }
  });
  test(
    'invalid response tags are discarded on200 but cannot validate304',
    () async {
      var status = 200;
      var tag = 'unquoted';
      final transport = fixture.wire(
        (r) async => http.Response('{}', status, headers: {'etag': tag}),
      );
      try {
        expect((await transport.getConditionalJson(url)).etag, isNull);
        status = 304;
        for (tag in ['unquoted', '"different"']) {
          await expectLater(
            transport.getConditionalJson(url, etag: '"original"'),
            throwsA(fixture.errorCode('invalid_response')),
          );
        }
      } finally {
        await transport.close();
      }
    },
  );
  test(
    '304 may omit ETag, and200 still decodes charset and enforces response limits',
    () async {
      var status = 304;
      final transport = fixture.wire(
        (r) async => status == 304
            ? http.Response('', 304)
            : http.Response.bytes(
                latin1.encode('{"name":"café"}'),
                200,
                headers: {
                  'content-type': 'application/json; charset=iso-8859-1',
                },
              ),
      );
      try {
        final unchanged = await transport.getConditionalJson(
          url,
          etag: '"old"',
        );
        expect(unchanged.etag, '"old"');
        expect(unchanged.notModified, true);
        status = 200;
        expect((await transport.getConditionalJson(url)).value, {
          'name': 'café',
        });
        await expectLater(
          transport.getConditionalJson(url, maxBytes: 5),
          throwsA(fixture.errorCode('invalid_response')),
        );
      } finally {
        await transport.close();
      }
    },
  );
  test('conditional GET keeps host policy and pre-send cancellation', () async {
    var calls = 0;
    final transport = fixture.wire((r) async {
      calls++;
      return fixture.redirect('https://other.example.org/song');
    });
    try {
      await expectLater(
        transport.getConditionalJson(
          url,
          etag: '"old"',
          allowedHosts: {url.host},
        ),
        throwsA(fixture.errorCode('redirect')),
      );
      expect(calls, 1);
      final cancel = CancellationToken()..cancel();
      await expectLater(
        transport.getConditionalJson(url, cancel: cancel),
        throwsA(fixture.errorCode('cancelled')),
      );
      expect(calls, 1);
    } finally {
      await transport.close();
    }
  });
}
