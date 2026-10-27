import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/vocadb.dart';
import 'package:singbook/providers/provider.dart';

Map<String, dynamic> song() => {
  'id': 123,
  'name': 'Invented Song',
  'artistString': 'Invented Producer feat. Invented Voice',
  'songType': 'Original',
  'names': [
    {'language': 'English', 'value': 'Invented Song'},
    {'language': 'Japanese', 'value': '架空の歌'},
  ],
  'artists': [
    {'name': 'Invented Producer', 'roles': 'Composer, Illustrator, Lyricist'},
    {'name': 'Invented Voice', 'roles': 'Default', 'categories': 'Vocalist'},
    {'name': 'Supporting Voice', 'roles': 'Default', 'isSupport': true},
  ],
  'albums': [
    {'id': 4, 'name': 'First Album'},
    {'id': 5, 'name': 'Another Album'},
  ],
  'cultureCodes': ['ja'],
  'lengthSeconds': 201,
  'minMilliBpm': 125500,
  'maxMilliBpm': 125500,
  'version': 7,
  'lyrics': [
    {
      'id': 78,
      'translationType': 'Translation',
      'cultureCodes': ['en'],
      'value': 'Invented translation',
      'source': 'Invented Translator',
    },
    {
      'id': 79,
      'translationType': 'Original',
      'cultureCodes': ['ja'],
      'value': 'An invented first line\nA second invented line',
      'source': 'Invented Original Author',
      'url': 'https://example.org/song',
    },
    {
      'id': 80,
      'translationType': 'Romanized',
      'value': 'Invented romanization',
    },
  ],
};

const selected = SongCandidate(
  providerId: 'vocadb',
  id: '123',
  title: 'Invented Song',
  artist: 'Invented Producer feat. Invented Voice',
);
http.Response response(Object data, {int status = 200}) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
VocaDbProvider provider(
  Future<http.Response> Function(http.Request) handler, {
  Duration cacheLifetime = const Duration(minutes: 15),
}) => VocaDbProvider(
  ProviderTransport(
    client: MockClient(handler),
    hostInterval: Duration.zero,
    maxRetries: 0,
  ),
  requestInterval: Duration.zero,
  cacheLifetime: cacheLifetime,
);
Matcher failure(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);

void main() {
  test(
    'search uses a bounded documented rating sort and preserves identity aliases and artist roles',
    () async {
      final p = provider((r) async {
        expect(r.url.host, 'vocadb.net');
        expect(r.url.path, '/api/songs');
        expect(r.url.queryParameters['sort'], 'RatingScore');
        expect(r.url.queryParameters['maxResults'], '12');
        expect(r.url.queryParameters['getTotalCount'], 'false');
        expect(r.url.queryParameters['fields'], isNot(contains('Lyrics')));
        return response({
          'items': [song()],
        });
      });
      addTearDown(p.transport.close);
      final c = (await p.search('Invented Song')).single;
      expect(c.id, '123');
      expect(c.album, isNull);
      expect(c.recordingIds, isEmpty);
      expect(c.metadata['identityScope'], 'arrangement');
      expect(c.extra['sourceTitleAliases'], ['Invented Song', '架空の歌']);
      expect(c.extra['sourceArtistRoles'], song()['artists']);
    },
  );

  test(
    'selects the unique original regardless of array order, retains all variants and exact JSON',
    () async {
      final data = song();
      final p = provider((_) async => response(data));
      addTearDown(p.transport.close);
      final result = await p.resolve(selected);
      expect(result.body, contains('An invented first line'));
      expect(result.body, isNot(contains('Invented translation')));
      expect(result.metadata['composer'], 'Invented Producer');
      expect(result.metadata['lyricist'], 'Invented Producer');
      expect(result.metadata['tempo'], 125.5);
      expect(result.metadata['language'], 'ja');
      expect(result.metadata.containsKey('artworkUrl'), false);
      expect(result.timingTracks, isEmpty);
      expect(result.extra['vocadb']['lyrics'], data['lyrics']);
      expect(result.extra['vocadb']['artists'], data['artists']);
      expect(result.extra['vocadb']['albums'], data['albums']);
      expect(
        jsonDecode(
          utf8.decode(base64Decode(result.extra['originalPayload']['base64'])),
        ),
        data,
      );
      expect(result.extra['rights']['permissions']['database'], 'CC-BY-4.0');
      expect(result.extra['rights']['permissions']['lyrics'], 'unknown');
      expect(result.attribution, contains('https://vocadb.net/S/123'));
    },
  );

  test(
    'does not invent a composer from default vocalist roles or a point tempo from a range',
    () async {
      final data = song()
        ..['artists'] = [
          {'name': 'Voice', 'roles': 'Default', 'categories': 'Vocalist'},
        ]
        ..['maxMilliBpm'] = 130000;
      final p = provider((_) async => response(data));
      addTearDown(p.transport.close);
      final result = await p.resolve(selected);
      expect(result.metadata.containsKey('composer'), false);
      expect(result.metadata.containsKey('tempo'), false);
      expect(result.extra['vocadb']['minMilliBpm'], 125500);
      expect(result.extra['vocadb']['maxMilliBpm'], 130000);
    },
  );

  for (final count in [0, 2]) {
    test(
      'rejects $count original variants rather than silently choosing a translation or first original',
      () async {
        final data = song();
        final original = (data['lyrics'] as List)[1];
        data['lyrics'] = [for (var i = 0; i < count; i++) original];
        final p = provider((_) async => response(data));
        addTearDown(p.transport.close);
        await expectLater(
          p.resolve(selected),
          throwsA(failure(count == 0 ? 'unavailable' : 'ambiguous_match')),
        );
      },
    );
  }

  test(
    'success cache revalidates selection identity and cancellation, and never caches access failures',
    () async {
      var requests = 0;
      final p = provider((_) async {
        requests++;
        return requests == 1 ? response({}, status: 403) : response(song());
      });
      addTearDown(p.transport.close);
      await expectLater(p.resolve(selected), throwsA(isA<ProviderException>()));
      final first = await p.resolve(selected);
      final cached = await p.resolve(selected);
      expect(cached.retrievedAt, first.retrievedAt);
      expect(requests, 2);
      await expectLater(
        p.resolve(
          const SongCandidate(
            providerId: 'vocadb',
            id: '123',
            title: 'Wrong Song',
            artist: 'Invented Producer feat. Invented Voice',
          ),
        ),
        throwsA(failure('identity_mismatch')),
      );
      await expectLater(
        p.resolve(
          const SongCandidate(
            providerId: 'vocadb',
            id: '123',
            title: 'Invented Song',
            artist: 'Invented Producer feat. Invented Voice',
            album: 'Wrong Album',
          ),
        ),
        throwsA(failure('identity_mismatch')),
      );
      final cancel = CancellationToken()..cancel();
      await expectLater(
        p.resolve(selected, cancel: cancel),
        throwsA(failure('cancelled')),
      );
      expect(requests, 2);
    },
  );

  test('mutable document cache expires and fetches a new version', () async {
    var requests = 0;
    final p = provider(
      (_) async => response(song()..['version'] = ++requests),
      cacheLifetime: Duration.zero,
    );
    addTearDown(p.transport.close);
    expect((await p.resolve(selected)).extra['vocadb']['version'], 1);
    expect((await p.resolve(selected)).extra['vocadb']['version'], 2);
  });

  test(
    'rejects deleted, merged, wrong-ID, oversized and injected lyric responses',
    () async {
      for (final patch in [
        {'deleted': true},
        {'mergedTo': 987},
        {'id': 124},
        {
          'names': List.generate(101, (_) => {'value': 'Name'}),
        },
      ]) {
        final p = provider((_) async => response(song()..addAll(patch)));
        try {
          await expectLater(
            p.resolve(selected),
            throwsA(isA<ProviderException>()),
          );
        } finally {
          await p.transport.close();
        }
      }
      final data = song();
      (data['lyrics'] as List)[1]['value'] =
          '{x_verse: injected}\nAn invented line';
      final p = provider((_) async => response(data));
      addTearDown(p.transport.close);
      expect(
        (await p.resolve(selected)).body,
        isNot(matches(RegExp(r'^\{x_verse:', multiLine: true))),
      );
    },
  );
}
