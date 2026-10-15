import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/application/youtube_music_consent_entry.dart';
import 'package:singbook/providers/transport.dart';

String chooser({
  String region = 'BG',
  String language = 'bg',
  String? target,
}) => Uri.https('consent.youtube.com', '/m', {
  'continue': target ?? 'https://music.youtube.com/?cbrd=1',
  'gl': region,
  'm': '0',
  'pc': 'ytm',
  'cm': '2',
  'hl': language,
  'src': '1',
}).toString();

class _Client extends MockClient {
  _Client(super.handler);
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  test(
    'anonymous fixed-host probe uses only Google-issued region/language',
    () async {
      for (final region in ['BG', 'DE']) {
        final client = _Client((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), 'https://music.youtube.com/');
          expect(request.followRedirects, isFalse);
          expect(request.headers['user-agent'], providerUserAgent);
          expect(request.headers['cookie'], isNull);
          expect(request.headers['authorization'], isNull);
          return http.Response(
            '',
            302,
            headers: {
              'location': chooser(region: region, language: 'en-GB'),
              'set-cookie': 'SID=must-not-copy; Secure',
            },
          );
        });
        final entry = await resolveYoutubeMusicConsentEntry(client: client);
        expect(entry.host, 'consent.youtube.com');
        expect(entry.path, '/m');
        expect(entry.queryParameters['gl'], region);
        expect(entry.queryParameters['hl'], 'en-GB');
        expect(
          entry.queryParameters['continue'],
          'https://music.youtube.com/?cbrd=1',
        );
        expect(entry.queryParameters.keys.toSet(), {
          'continue',
          'gl',
          'm',
          'pc',
          'cm',
          'hl',
          'src',
        });
        expect(client.closed, isTrue);
      }
    },
  );

  test('ambiguous or foreign chooser/return locations fail closed', () async {
    for (final location in [
      '${chooser()}&gl=US',
      '${chooser()}&token=must-not-copy',
      chooser().replaceFirst(
        'consent.youtube.com',
        'consent.youtube.com.evil.org',
      ),
      chooser().replaceFirst('https:', 'http:'),
      chooser().replaceFirst('consent.youtube.com', 'user@consent.youtube.com'),
      chooser().replaceFirst('consent.youtube.com', 'consent.youtube.com:8443'),
      chooser().replaceFirst('/m?', '/save?'),
      chooser(region: ''),
      chooser(region: 'bg'),
      chooser(language: 'invalid language'),
      chooser(target: 'https://music.youtube.com.evil.org/'),
      chooser(target: 'https://user@music.youtube.com/'),
      chooser(target: 'https://music.youtube.com/account'),
      chooser(target: 'https://music.youtube.com/?next=https://evil.org/'),
      chooser(target: 'https://music.youtube.com/?cbrd=1&cbrd=1'),
      chooser(target: 'https://music.youtube.com/#account'),
    ]) {
      final client = _Client(
        (_) async => http.Response('', 302, headers: {'location': location}),
      );
      await expectLater(
        resolveYoutubeMusicConsentEntry(client: client),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'invalid_response',
          ),
        ),
      );
      expect(client.closed, isTrue);
    }
  });

  test(
    'public homepage without chooser does not invent a consent choice',
    () async {
      final client = _Client(
        (_) async => http.Response('public homepage', 200),
      );
      await expectLater(
        resolveYoutubeMusicConsentEntry(client: client),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'blocked'),
        ),
      );
      expect(client.closed, isTrue);
    },
  );

  test(
    'deadline closes the anonymous probe without waiting for its body',
    () async {
      final pending = Completer<http.Response>();
      final client = _Client((_) => pending.future);
      await expectLater(
        resolveYoutubeMusicConsentEntry(
          client: client,
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'timeout'),
        ),
      );
      expect(client.closed, isTrue);
      pending.complete(http.Response('', 200));
    },
  );
}
