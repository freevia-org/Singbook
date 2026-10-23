import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';

void main() {
  for (final types in [
    <String>[],
    ['Q482994'],
    ['Q11424'],
    ['Q2188189'],
    ['Q999999'],
    ['Q7366', 'Q482994'],
  ]) {
    test(
      'rejects non-composition types $types in search and exact resolve',
      () async {
        final transport = _transport(types: types);
        final provider = WikidataProvider(transport);
        expect(await provider.search('Example'), isEmpty);
        await expectLater(
          provider.resolve(_selected),
          throwsA(_code('unavailable')),
        );
        await transport.close();
      },
    );
  }

  for (final type in ['Q7366', 'Q207628', 'Q105543609']) {
    test(
      'accepts explicit composition type $type and separates cover performers',
      () async {
        final transport = _transport(types: [type]);
        final provider = WikidataProvider(transport);
        final rows = await provider.search('Example');
        expect(rows.single.id, 'Q1');
        expect(rows.single.artist, 'Writer');
        final result = await provider.resolve(rows.single);
        expect(result.candidate.artist, 'Writer');
        expect(result.metadata['identityScope'], 'composition');
        expect(result.metadata['performers'], ['Writer', 'Cover Performer']);
        expect(result.metadata['composers'], [
          {'wikidataId': 'Q2', 'name': 'Writer'},
        ]);
        expect(result.metadata.containsKey('releaseDate'), isFalse);
        await transport.close();
      },
    );
  }

  test('exact-ID resolve cannot accept another returned entity', () async {
    final transport = _transport(types: ['Q7366'], returnedId: 'Q9');
    await expectLater(
      WikidataProvider(transport).resolve(_selected),
      throwsA(_code('unavailable')),
    );
    await transport.close();
  });

  test(
    'unknown work author stays unknown instead of using a cover performer',
    () async {
      final transport = _transport(types: ['Q7366'], withCreators: false);
      final result = await WikidataProvider(transport).resolve(_selected);
      expect(result.candidate.artist, isEmpty);
      expect(result.metadata['composers'], isEmpty);
      expect(result.metadata['performers'], ['Writer', 'Cover Performer']);
      await transport.close();
    },
  );

  test('maxlag remains a retryable busy response', () async {
    final transport = _transport(types: ['Q7366'], busy: true);
    await expectLater(
      WikidataProvider(transport).search('Example'),
      throwsA(_code('provider_busy')),
    );
    await transport.close();
  });

  test('cancelled lookup never starts an HTTP request', () async {
    var calls = 0;
    final transport = ProviderTransport(
      client: MockClient((_) async {
        calls++;
        return _json({});
      }),
      hostInterval: Duration.zero,
    );
    final cancellation = CancellationToken()..cancel();
    await expectLater(
      WikidataProvider(transport).search('Example', cancel: cancellation),
      throwsA(isA<ProviderException>()),
    );
    expect(calls, 0);
    await transport.close();
  });
}

const _selected = SongCandidate(
  providerId: 'wikidata',
  id: 'Q1',
  title: 'Example',
  artist: 'Writer',
);

Matcher _code(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);

Map<String, dynamic> _claim(String id) => {
  'mainsnak': {
    'datavalue': {
      'value': {'id': id},
    },
  },
};

http.Response _json(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);

ProviderTransport _transport({
  required List<String> types,
  String returnedId = 'Q1',
  bool busy = false,
  bool withCreators = true,
}) => ProviderTransport(
  hostInterval: Duration.zero,
  client: MockClient((request) async {
    expect(request.url.queryParameters['maxlag'], '5');
    if (busy) {
      return _json({
        'error': {'code': 'maxlag'},
      });
    }
    if (request.url.queryParameters['action'] == 'wbsearchentities') {
      return _json({
        'search': [
          {'id': 'Q1'},
        ],
      });
    }
    if (request.url.queryParameters['ids'] == 'Q1') {
      return _json({
        'entities': {
          returnedId: {
            'labels': {
              'en': {'value': 'Example'},
            },
            'claims': {
              'P31': types.map(_claim).toList(),
              if (withCreators) 'P86': [_claim('Q2')],
              if (withCreators) 'P676': [_claim('Q2')],
              'P175': [_claim('Q2'), _claim('Q2'), _claim('Q3')],
            },
          },
        },
      });
    }
    return _json({
      'entities': {
        'Q2': {
          'labels': {
            'en': {'value': 'Writer'},
          },
        },
        'Q3': {
          'labels': {
            'en': {'value': 'Cover Performer'},
          },
        },
      },
    });
  }),
);
