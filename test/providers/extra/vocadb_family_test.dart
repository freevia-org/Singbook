import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/vocadb.dart';
import 'package:singbook/providers/provider.dart';

Map<String, dynamic> entry({int id = 23}) => {
  'id': id,
  'name': 'Fictional family song',
  'artistString': 'Invented Circle',
  'songType': 'Original',
  'names': [
    {'language': 'English', 'value': 'Fictional family song'},
    {'language': 'English', 'value': 'Fictional alias'},
  ],
  'artists': [
    {'name': 'Invented Composer', 'roles': 'Composer'},
  ],
  'albums': [
    {'name': 'Imaginary Album'},
  ],
  'cultureCodes': ['en'],
  'lengthSeconds': 120,
  'version': 2,
  'originalVersionId': 999,
  'lyrics': [
    {
      'id': 5,
      'translationType': 'Translation',
      'value': 'Invented translation body',
      'source': 'Invented translator',
    },
    {
      'id': 6,
      'translationType': 'Original',
      'value': 'Invented original body',
      'source': 'Invented lyricist',
    },
  ],
  'webLinks': [],
};

http.Response response(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ProviderTransport transport(
  Future<http.Response> Function(http.Request) handler,
) => ProviderTransport(
  client: MockClient(handler),
  hostInterval: Duration.zero,
  maxRetries: 0,
);

typedef ProviderMaker = LyricsProvider Function(ProviderTransport transport);

void main() {
  final variants =
      <({String id, String name, String host, ProviderMaker make})>[
        (
          id: 'touhoudb',
          name: 'TouhouDB',
          host: 'touhoudb.com',
          make: TouhouDbProvider.new,
        ),
        (
          id: 'utaitedb',
          name: 'UtaiteDB',
          host: 'utaitedb.net',
          make: UtaiteDbProvider.new,
        ),
      ];

  for (final variant in variants) {
    test(
      '${variant.id} is a fixed identity and retains native source facts',
      () async {
        final requests = <http.Request>[];
        final t = transport((request) async {
          requests.add(request);
          if (request.url.path == '/api/songs') {
            return response({
              'items': [entry()],
            });
          }
          return response(entry());
        });
        final p = variant.make(t);
        addTearDown(t.close);

        expect(p.definition.id, variant.id);
        expect(p.definition.name, variant.name);
        expect(p.definition.website, 'https://${variant.host}/');
        final found = (await p.search('Fictional family song')).single;
        expect(requests.single.url.host, variant.host);
        expect(found.providerId, variant.id);
        expect(found.url, 'https://${variant.host}/S/23');
        expect(found.metadata['${variant.id}SongId'], '23');

        final result = await p.resolve(found);
        expect(requests.last.url.host, variant.host);
        expect(requests.last.url.path, '/api/songs/23');
        expect(result.body, contains('Invented original body'));
        expect(result.body, isNot(contains('Invented translation body')));
        expect(
          result.attribution,
          '${variant.name} — https://${variant.host}/S/23',
        );
        expect(result.extra['parserVersion'], '${variant.id}-native-1');
        expect(result.extra[variant.id]['originalVersionId'], 999);
        expect(result.extra[variant.id]['lyrics'], entry()['lyrics']);
        expect(result.extra['rights']['source'], variant.id);
        expect(
          result.extra['rights']['evidenceUrl'],
          'https://wiki.vocadb.net/docs/license',
        );
        expect(result.extra['rights']['permissions']['database'], 'CC-BY-4.0');
        expect(result.extra['rights']['permissions']['lyrics'], 'unknown');
        expect(result.extra.containsKey('vocadb'), false);
      },
    );

    test(
      '${variant.id} contextual lookup uses title and checks artist, album, duration',
      () async {
        final t = transport((request) async {
          expect(request.url.queryParameters['query'], 'Fictional family song');
          return response({
            'items': [entry()],
          });
        });
        final p = variant.make(t);
        addTearDown(t.close);
        const ref = SongCandidate(
          providerId: 'other',
          id: 'local',
          title: 'Fictional family song',
          artist: 'Invented Circle',
          album: 'Imaginary Album',
          durationSeconds: 121,
        );
        final rows = await (p as ContextualLyricsSearch).searchForSelection(
          ref,
          fallbackQuery: 'must not replace title search',
        );
        expect(rows, hasLength(1));
        expect(
          (p as ContextualLyricsSearch).canReuseSearchForSelection(ref, rows),
          true,
        );
        for (final mismatch in [
          const SongCandidate(
            providerId: 'other',
            id: 'local',
            title: 'Fictional family song',
            artist: 'Different Circle',
            album: 'Imaginary Album',
            durationSeconds: 121,
          ),
          const SongCandidate(
            providerId: 'other',
            id: 'local',
            title: 'Fictional family song',
            artist: 'Invented Circle',
            album: 'Different Album',
            durationSeconds: 121,
          ),
          const SongCandidate(
            providerId: 'other',
            id: 'local',
            title: 'Fictional family song',
            artist: 'Invented Circle',
            album: 'Imaginary Album',
            durationSeconds: 130,
          ),
        ]) {
          expect(
            (p as ContextualLyricsSearch).canReuseSearchForSelection(
              mismatch,
              rows,
            ),
            false,
          );
        }
      },
    );
  }

  test(
    'wrong provider identity is rejected before HTTP and versions never trigger parent fetch',
    () async {
      var calls = 0;
      final p = TouhouDbProvider(
        transport((_) async {
          calls++;
          return response(entry());
        }),
      );
      addTearDown(p.transport.close);
      await expectLater(
        p.resolve(
          const SongCandidate(
            providerId: 'utaitedb',
            id: '23',
            title: 'Fictional family song',
            artist: 'Invented Circle',
          ),
        ),
        throwsA(isA<ProviderException>()),
      );
      expect(calls, 0);
      final result = await p.resolve(
        const SongCandidate(
          providerId: 'touhoudb',
          id: '23',
          title: 'Fictional family song',
          artist: 'Invented Circle',
        ),
      );
      expect(calls, 1);
      expect(result.extra['touhoudb']['originalVersionId'], 999);
    },
  );

  test(
    'same numeric IDs stay isolated across hosts and cached rows revalidate identity',
    () async {
      var touhouCalls = 0;
      var utaiteCalls = 0;
      final touhou = TouhouDbProvider(
        transport((_) async {
          touhouCalls++;
          return response(entry()..['name'] = 'Fictional family song');
        }),
      );
      final utaite = UtaiteDbProvider(
        transport((_) async {
          utaiteCalls++;
          return response(entry()..['name'] = 'Different fictional song');
        }),
      );
      addTearDown(touhou.transport.close);
      addTearDown(utaite.transport.close);
      const touhouPick = SongCandidate(
        providerId: 'touhoudb',
        id: '23',
        title: 'Fictional family song',
        artist: 'Invented Circle',
      );
      const utaitePick = SongCandidate(
        providerId: 'utaitedb',
        id: '23',
        title: 'Different fictional song',
        artist: 'Invented Circle',
      );
      await touhou.resolve(touhouPick);
      await utaite.resolve(utaitePick);
      await touhou.resolve(touhouPick);
      expect(touhouCalls, 1);
      expect(utaiteCalls, 1);
      await expectLater(
        touhou.resolve(
          const SongCandidate(
            providerId: 'touhoudb',
            id: '23',
            title: 'Wrong fictional song',
            artist: 'Invented Circle',
          ),
        ),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'identity_mismatch',
          ),
        ),
      );
      expect(touhouCalls, 1);
    },
  );

  for (final count in [0, 2]) {
    test('zero or multiple Original rows remain explicit ($count)', () async {
      final data = entry();
      final original = (data['lyrics'] as List).last;
      data['lyrics'] = List.generate(count, (_) => original);
      final p = UtaiteDbProvider(transport((_) async => response(data)));
      addTearDown(p.transport.close);
      await expectLater(
        p.resolve(
          const SongCandidate(
            providerId: 'utaitedb',
            id: '23',
            title: 'Fictional family song',
            artist: 'Invented Circle',
          ),
        ),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            count == 0 ? 'unavailable' : 'ambiguous_match',
          ),
        ),
      );
    });
  }

  test(
    'malicious alias, controls, and extension-like lyrics retain existing defenses',
    () async {
      final badAlias = entry()
        ..['names'] = [
          {'value': 'Fictional\u202esong'},
        ];
      final badProvider = UtaiteDbProvider(
        transport((_) async => response(badAlias)),
      );
      addTearDown(badProvider.transport.close);
      await expectLater(
        badProvider.search('fictional'),
        throwsA(isA<ProviderException>()),
      );

      final badTitle = entry()..['name'] = 'Fictional\nsong';
      final badTitleProvider = UtaiteDbProvider(
        transport(
          (_) async => response({
            'items': [badTitle],
          }),
        ),
      );
      addTearDown(badTitleProvider.transport.close);
      await expectLater(
        badTitleProvider.search('fictional'),
        throwsA(isA<ProviderException>()),
      );

      final injected = entry();
      (injected['lyrics'] as List).last['value'] =
          '{x_verse: attacker}\nInvented body';
      final p = TouhouDbProvider(transport((_) async => response(injected)));
      addTearDown(p.transport.close);
      final result = await p.resolve(
        const SongCandidate(
          providerId: 'touhoudb',
          id: '23',
          title: 'Fictional family song',
          artist: 'Invented Circle',
        ),
      );
      expect(
        result.body,
        isNot(matches(RegExp(r'^\{x_verse:', multiLine: true))),
      );
    },
  );

  test(
    'context lookup makes one Exact/Name fallback after rating results miss full identity',
    () async {
      final requests = <http.Request>[];
      final p = UtaiteDbProvider(
        transport((request) async {
          requests.add(request);
          if (request.url.queryParameters['nameMatchMode'] == 'Auto') {
            return response({
              'items': List.generate(
                12,
                (index) =>
                    entry(id: 100 + index)
                      ..['artistString'] = 'Popular cover artist $index',
              ),
            });
          }
          return response({
            'items': [entry(id: 51300)],
          });
        }),
      );
      addTearDown(p.transport.close);
      const selection = SongCandidate(
        providerId: 'library',
        id: 'recording',
        title: 'Fictional family song',
        artist: 'Invented Circle',
        album: 'Imaginary Album',
        durationSeconds: 120,
      );

      final rows = await p.searchForSelection(
        selection,
        fallbackQuery: 'should not be used',
      );

      expect(rows, hasLength(1));
      expect(rows.single.id, '51300');
      expect(
        requests.map((request) => request.url.queryParameters['nameMatchMode']),
        ['Auto', 'Exact'],
      );
      expect(requests.map((request) => request.url.queryParameters['sort']), [
        'RatingScore',
        'Name',
      ]);
      for (final request in requests) {
        expect(request.url.queryParameters['query'], 'Fictional family song');
        expect(request.url.queryParameters['maxResults'], '12');
      }
    },
  );

  test(
    'context lookup skips fallback on an exact full-context first-page match',
    () async {
      var calls = 0;
      final p = TouhouDbProvider(
        transport((request) async {
          calls++;
          expect(request.url.queryParameters['nameMatchMode'], 'Auto');
          expect(request.url.queryParameters['sort'], 'RatingScore');
          return response({
            'items': [entry()],
          });
        }),
      );
      addTearDown(p.transport.close);
      const selection = SongCandidate(
        providerId: 'library',
        id: 'recording',
        title: 'Fictional family song',
        artist: 'Invented Circle',
      );

      final rows = await p.searchForSelection(
        selection,
        fallbackQuery: 'should not be used',
      );

      expect(rows, hasLength(1));
      expect(calls, 1);
    },
  );

  test(
    'context lookup does not fallback after a denied or malformed first request',
    () async {
      for (final failWith in ['denied', 'malformed']) {
        var calls = 0;
        final p = UtaiteDbProvider(
          transport((_) async {
            calls++;
            if (failWith == 'denied') {
              throw http.ClientException('synthetic denied request');
            }
            return http.Response('not-json', 200);
          }),
        );
        addTearDown(p.transport.close);
        await expectLater(
          p.searchForSelection(
            const SongCandidate(
              providerId: 'library',
              id: 'recording',
              title: 'Fictional family song',
              artist: 'Invented Circle',
            ),
            fallbackQuery: 'Fictional family song',
          ),
          throwsA(isA<ProviderException>()),
        );
        expect(calls, 1, reason: '$failWith must not trigger a second request');
      }
    },
  );

  test(
    'ordinary search stays Auto, RatingScore, and capped at twelve',
    () async {
      final p = TouhouDbProvider(
        transport((request) async {
          expect(request.url.queryParameters['nameMatchMode'], 'Auto');
          expect(request.url.queryParameters['sort'], 'RatingScore');
          expect(request.url.queryParameters['maxResults'], '12');
          return response({'items': []});
        }),
      );
      addTearDown(p.transport.close);
      expect(await p.search('Fictional family song'), isEmpty);
    },
  );
}
