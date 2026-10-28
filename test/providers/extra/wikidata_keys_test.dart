import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

Map<String, dynamic> _statement(String id, {String rank = 'normal'}) => {
  'id': 'Q1\$statement-$id',
  'rank': rank,
  'mainsnak': {
    'snaktype': 'value',
    'property': 'P826',
    'datatype': 'wikibase-item',
    'datavalue': {
      'value': {'id': id},
      'type': 'wikibase-entityid',
    },
  },
  'qualifiers': {
    'P518': [
      {'snaktype': 'somevalue', 'property': 'P518'},
    ],
  },
  'references': [
    {
      'hash': 'reference-$id',
      'snaks': {
        'P854': [
          {
            'snaktype': 'value',
            'property': 'P854',
            'datavalue': {
              'value': 'https://example.invalid/source/$id',
              'type': 'string',
            },
          },
        ],
      },
    },
  ],
};

const _selected = SongCandidate(
  providerId: 'wikidata',
  id: 'Q1',
  title: 'Example Song',
  artist: '',
);

ProviderTransport _transport(
  List<Map<String, dynamic>> statements,
  Map<String, String> labels,
  List<Uri> requests, {
  bool keyLabelsUnavailable = false,
  bool withComposer = false,
  void Function()? onKeyLabels,
}) => ProviderTransport(
  hostInterval: Duration.zero,
  client: MockClient((request) async {
    requests.add(request.url);
    final ids = (request.url.queryParameters['ids'] ?? '').split('|');
    expect(ids.length, lessThanOrEqualTo(40));
    if (ids.contains('Q2')) onKeyLabels?.call();
    if (keyLabelsUnavailable && ids.contains('Q2')) {
      return http.Response(
        jsonEncode({
          'error': {'code': 'badvalue'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    final entities = ids.contains('Q1')
        ? {
            'Q1': {
              'labels': {
                'en': {'value': 'Example Song'},
              },
              'claims': {
                'P31': [
                  {
                    'mainsnak': {
                      'datavalue': {
                        'value': {'id': 'Q7366'},
                      },
                    },
                  },
                ],
                'P826': statements,
                if (withComposer)
                  'P86': [
                    {
                      'mainsnak': {
                        'datavalue': {
                          'value': {'id': 'Q9'},
                        },
                      },
                    },
                  ],
              },
            },
          }
        : {
            for (final id in ids)
              if (labels.containsKey(id))
                id: {
                  'labels': {
                    'en': {'value': labels[id]},
                  },
                },
          };
    return http.Response(
      jsonEncode({'entities': entities}),
      200,
      headers: {'content-type': 'application/json'},
    );
  }),
);

Map<String, dynamic> _entityClaim(String id) => {
  'rank': 'normal',
  'mainsnak': {
    'datavalue': {
      'value': {'id': id},
    },
  },
};

ProviderTransport _songDonorTransport({
  List<String> types = const ['Q134556'],
  bool correctPerformer = true,
  bool correctTitle = true,
  bool withKey = true,
  bool multipleDonors = false,
  bool singleLabelsUnavailable = false,
}) {
  Map<String, dynamic> donor(String type, String key, {String? title}) => {
    'labels': {
      'en': {'value': title ?? 'Example Song'},
    },
    'claims': {
      'P31': [_entityClaim(type)],
      'P175': [_entityClaim(correctPerformer ? 'Q7' : 'Q8')],
      'P86': [_entityClaim('Q9')],
      if (withKey) 'P826': [_statement(key)],
      'P18': [
        {
          'mainsnak': {
            'datavalue': {'value': 'Artwork.jpg'},
          },
        },
      ],
      'P2047': [
        {
          'mainsnak': {
            'datavalue': {
              'value': {'amount': '+262'},
            },
          },
        },
      ],
    },
  };
  final entities = {
    'Q1': {
      ...donor('Q134556', 'Q2', title: correctTitle ? null : 'Different Song'),
      'claims': {
        ...(donor('Q134556', 'Q2')['claims'] as Map),
        'P31': types.map(_entityClaim).toList(),
      },
    },
    if (multipleDonors) 'Q10': donor('Q7366', 'Q3'),
    if (multipleDonors) 'Q11': donor('Q134556', 'Q4'),
    for (final entry in {
      'Q2': 'A major',
      'Q3': 'E minor',
      'Q4': 'D minor',
      'Q7': 'Performer',
      'Q8': 'Other Performer',
      'Q9': 'Composer',
    }.entries)
      entry.key: {
        'labels': {
          'en': {'value': entry.value},
        },
      },
  };
  return ProviderTransport(
    hostInterval: Duration.zero,
    client: MockClient((request) async {
      final ids = (request.url.queryParameters['ids'] ?? '').split('|');
      if (singleLabelsUnavailable &&
          ids.contains('Q2') &&
          !ids.contains('Q1')) {
        return http.Response(
          jsonEncode({
            'error': {'code': 'badvalue'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      expect(ids.length, lessThanOrEqualTo(40));
      final data = request.url.queryParameters['action'] == 'wbsearchentities'
          ? {
              'search': [
                {'id': 'Q1'},
                if (multipleDonors) {'id': 'Q11'},
                if (multipleDonors) {'id': 'Q10'},
              ],
            }
          : {
              'entities': {
                for (final id in ids)
                  if (entities.containsKey(id)) id: entities[id],
              },
            };
      return http.Response(
        jsonEncode(data),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}

const _externalSong = SongCandidate(
  providerId: 'catalog',
  id: 'recording',
  title: 'Example Song',
  artist: 'Performer',
);

void main() {
  test(
    'public catalog excludes a Single while external enrichment retains its key',
    () async {
      final transport = _songDonorTransport();
      final provider = WikidataProvider(transport);
      expect(await provider.search('Example Song'), isEmpty);
      final source = await findMatchingSource(provider, _externalSong);
      expect(source.matchKind, MatchKind.sameSong);
      expect(source.metadata['identityScope'], 'song');
      expect(source.extra['identityScope'], 'song');
      expect(source.metadata['key'], 'A');
      expect(source.metadata['performerAssertions'], [_entityClaim('Q7')]);
      expect(
        (source.metadata['keyAssertions'] as List).single['statement'],
        _statement('Q2'),
      );
      expect(source.candidate.recordingIds, isEmpty);
      expect(source.candidate.album, isNull);
      expect(source.candidate.durationSeconds, isNull);
      for (final field in [
        'composers',
        'lyricists',
        'partOf',
        'publicationDates',
        'durationClaims',
        'wikimediaCommonsFile',
        'artworkUrl',
        'album',
        'durationSeconds',
      ]) {
        expect(source.metadata, isNot(contains(field)), reason: field);
      }
      await transport.close();
    },
  );

  for (final invalid in [
    'performer',
    'title',
    'missing-key',
    'album',
    'film',
    'recording',
    'untyped',
  ]) {
    test(
      'Single key enrichment rejects $invalid despite a caller supplied ID',
      () async {
        final transport = _songDonorTransport(
          correctPerformer: invalid != 'performer',
          correctTitle: invalid != 'title',
          withKey: invalid != 'missing-key',
          types: switch (invalid) {
            'album' => ['Q482994'],
            'film' => ['Q11424'],
            'recording' => ['Q193018'],
            'untyped' => [],
            _ => ['Q134556'],
          },
        );
        await expectLater(
          WikidataProvider(transport).resolve(
            SongCandidate(
              providerId: _externalSong.providerId,
              id: _externalSong.id,
              title: _externalSong.title,
              artist: _externalSong.artist,
              metadata: {
                'wikidataId': 'Q1',
                'performers': ['Performer'],
              },
            ),
          ),
          throwsA(
            isA<ProviderException>().having(
              (error) => error.code,
              'code',
              'unavailable',
            ),
          ),
        );
        await transport.close();
      },
    );
  }

  test(
    'matching works and Singles retain every known same-song donor',
    () async {
      final transport = _songDonorTransport(multipleDonors: true);
      final provider = WikidataProvider(transport);
      expect((await provider.search('Example Song')).map((row) => row.id), [
        'Q10',
      ]);
      final source = await findMatchingSource(provider, _externalSong);
      expect(source.candidate.id, 'Q10');
      expect(source.metadata['identityScope'], 'composition');
      final donors = (source.extra['providerAlternatives'] as List)
          .map(
            (raw) =>
                SourceResult.fromJson(Map<String, dynamic>.from(raw as Map)),
          )
          .toList();
      expect(donors.map((donor) => donor.candidate.id), ['Q1', 'Q11']);
      expect(
        donors.every((donor) => donor.matchKind == MatchKind.sameSong),
        isTrue,
      );
      expect(
        donors.every((donor) => donor.metadata['identityScope'] == 'song'),
        isTrue,
      );
      expect(donors.map((donor) => donor.metadata['key']), ['A', 'Dm']);
      expect(
        donors.every((donor) => donor.metadata['keyAssertions'] is List),
        isTrue,
      );
      await transport.close();
    },
  );

  test(
    'optional Single labels cannot erase a known work key or creator',
    () async {
      final transport = _songDonorTransport(
        multipleDonors: true,
        singleLabelsUnavailable: true,
      );
      final source = await findMatchingSource(
        WikidataProvider(transport),
        _externalSong,
      );
      expect(source.candidate.id, 'Q10');
      expect(source.metadata['key'], 'Em');
      expect(source.metadata['composers'], [
        {'wikidataId': 'Q9', 'name': 'Composer'},
      ]);
      final donors = source.extra['providerAlternatives'] as List;
      expect(donors, hasLength(2));
      for (final raw in donors) {
        expect((raw as Map)['metadata']['keyAssertions'], isNotEmpty);
        expect(raw['metadata'], isNot(contains('key')));
      }
      await transport.close();
    },
  );

  for (final entry in {
    'A major': 'A',
    'E-flat minor': 'Ebm',
    'F♯ minor': 'F#m',
    'B flat major': 'Bb',
    'C-sharp-major': 'C#',
    'D minor': 'Dm',
  }.entries) {
    test('normalizes the literal tonal label ${entry.key}', () async {
      final statement = _statement('Q2');
      final requests = <Uri>[];
      final transport = _transport([statement], {'Q2': entry.key}, requests);
      final source = await WikidataProvider(transport).resolve(_selected);
      expect(source.metadata['key'], entry.value);
      expect(source.metadata, isNot(contains('keys')));
      expect(source.metadata['identityScope'], 'composition');
      expect(source.metadata['keyAssertions'], [
        {
          'statement': statement,
          'entityId': 'Q2',
          'label': entry.key,
          'normalizedKey': entry.value,
        },
      ]);
      expect(requests, hasLength(2));
      expect(requests.last.queryParameters['ids'], 'Q2');
      await transport.close();
    });
  }

  test(
    'retains multiple, deprecated and unsupported statements without a veto',
    () async {
      final statements = [
        _statement('Q2'),
        _statement('Q3', rank: 'preferred'),
        _statement('Q4', rank: 'deprecated'),
        _statement('Q5'),
        _statement('Q6'),
      ];
      final transport = _transport(statements, {
        'Q2': 'A major',
        'Q3': 'E-flat minor',
        'Q4': 'F♯ minor',
        'Q5': 'atonality',
        'Q6': 'D Dorian',
      }, []);
      final source = await WikidataProvider(transport).resolve(_selected);
      expect(source.metadata, isNot(contains('key')));
      expect(source.metadata['keys'], ['A', 'Ebm', 'F#m']);
      final assertions = source.metadata['keyAssertions'] as List;
      expect(
        assertions.map((raw) => (raw as Map)['statement']).toList(),
        statements,
      );
      expect((assertions[2] as Map)['normalizedKey'], 'F#m');
      expect((assertions[3] as Map)['label'], 'atonality');
      expect((assertions[3] as Map), isNot(contains('normalizedKey')));
      expect((assertions[4] as Map), isNot(contains('normalizedKey')));
      expect(source.candidate.metadata['keyAssertions'], assertions);
      await transport.close();
    },
  );

  test(
    'failed optional key labels preserve work identity and creator metadata',
    () async {
      final statement = _statement('Q2');
      final requests = <Uri>[];
      final transport = _transport(
        [statement],
        {'Q9': 'Composer'},
        requests,
        keyLabelsUnavailable: true,
        withComposer: true,
      );
      final source = await WikidataProvider(transport).resolve(_selected);
      expect(source.candidate.id, 'Q1');
      expect(source.candidate.title, 'Example Song');
      expect(source.candidate.artist, 'Composer');
      expect(source.metadata['composers'], [
        {'wikidataId': 'Q9', 'name': 'Composer'},
      ]);
      expect(source.metadata['keyAssertions'], [
        {'statement': statement, 'entityId': 'Q2'},
      ]);
      expect(source.metadata, isNot(contains('key')));
      expect(requests.map((uri) => uri.queryParameters['ids']), [
        'Q1',
        'Q9',
        'Q2',
      ]);
      await transport.close();
    },
  );

  test(
    'cancellation during optional key labels still cancels resolution',
    () async {
      final cancel = CancellationToken();
      final transport = _transport(
        [_statement('Q2')],
        {'Q2': 'A major'},
        [],
        onKeyLabels: cancel.cancel,
      );
      await expectLater(
        WikidataProvider(transport).resolve(_selected, cancel: cancel),
        throwsA(
          isA<ProviderException>().having(
            (error) => error.code,
            'code',
            'cancelled',
          ),
        ),
      );
      await transport.close();
    },
  );

  test(
    'missing labels retain raw statements without inventing a tonal key',
    () async {
      final statements = [_statement('Q2')];
      final transport = _transport(statements, {}, []);
      final source = await WikidataProvider(transport).resolve(_selected);
      expect(source.metadata, isNot(contains('key')));
      expect(source.metadata, isNot(contains('keys')));
      expect(source.metadata['keyAssertions'], [
        {'statement': statements.single, 'entityId': 'Q2'},
      ]);
      await transport.close();
    },
  );
}
