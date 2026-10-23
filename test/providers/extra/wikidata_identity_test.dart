import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/core/service.dart';
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

  for (final lookup in ['title', 'metadataId', 'recordingId']) {
    test('enrichment uses fetched P175 evidence through $lookup', () async {
      final transport = _transport(types: ['Q7366']);
      final result = await findMatchingSource(
        WikidataProvider(transport),
        _external(
          workId: lookup == 'title' ? null : 'Q1',
          recordingId: lookup == 'recordingId',
        ),
      );
      expect(result.matchKind, MatchKind.sameSong);
      expect(result.candidate.id, 'Q1');
      expect(result.candidate.artist, 'Cover Performer');
      expect(result.metadata['identityScope'], 'composition');
      expect(result.metadata['composers'], [
        {'wikidataId': 'Q2', 'name': 'Writer'},
      ]);
      expect(result.metadata['lyricists'], [
        {'wikidataId': 'Q2', 'name': 'Writer'},
      ]);
      expect(result.metadata['performerIds'], contains('Q3'));
      expect(result.extra['identityMatch'], {
        'property': 'P175',
        'performer': 'Cover Performer',
      });
      expect(result.metadata.containsKey('releaseDate'), isFalse);
      expect(result.candidate.recordingIds, isEmpty);
      await transport.close();
    });
  }

  for (final exact in [false, true]) {
    for (final invalid in [
      'unrelated',
      'missing',
      'unlabelled',
      'creatorOnly',
    ]) {
      test(
        'enrichment rejects $invalid performer; explicit ID=$exact',
        () async {
          final transport = _transport(
            types: ['Q7366'],
            performerIds: switch (invalid) {
              'missing' => [],
              'unlabelled' => ['Q4'],
              'creatorOnly' => ['Q3'],
              _ => ['Q2', 'Q3'],
            },
          );
          await expectLater(
            findMatchingSource(
              WikidataProvider(transport),
              _external(
                workId: exact ? 'Q1' : null,
                artist: invalid == 'unrelated'
                    ? 'Unrelated Performer'
                    : invalid == 'creatorOnly'
                    ? 'Writer'
                    : 'Cover Performer',
                // Caller claims cannot replace fetched performer evidence.
                metadata: const {
                  'performers': ['Cover Performer', 'Writer'],
                },
              ),
            ),
            throwsA(_code('unavailable')),
          );
          await transport.close();
        },
      );
    }
  }

  test('an explicit work ID does not excuse a different title', () async {
    final transport = _transport(types: ['Q7366']);
    await expectLater(
      findMatchingSource(
        WikidataProvider(transport),
        _external(workId: 'Q1', title: 'Different Work'),
      ),
      throwsA(_code('unavailable')),
    );
    await transport.close();
  });

  test('performer evidence does not fill in an unknown work author', () async {
    final transport = _transport(types: ['Q7366'], withCreators: false);
    final result = await findMatchingSource(
      WikidataProvider(transport),
      _external(workId: 'Q1'),
    );
    expect(result.matchKind, MatchKind.sameSong);
    expect(result.candidate.artist, 'Cover Performer');
    expect(result.metadata['composers'], isEmpty);
    expect(result.metadata['lyricists'], isEmpty);
    await transport.close();
  });

  test(
    'two matching works stay ambiguous instead of taking the first',
    () async {
      final transport = _transport(types: ['Q7366'], workIds: ['Q1', 'Q9']);
      await expectLater(
        findMatchingSource(WikidataProvider(transport), _external()),
        throwsA(_code('ambiguous_match')),
      );
      final exact = await findMatchingSource(
        WikidataProvider(transport),
        _external(workId: 'Q9'),
      );
      expect(exact.candidate.id, 'Q9');
      expect(exact.matchKind, MatchKind.sameSong);
      await transport.close();
    },
  );

  test(
    'performer enrichment still rejects an album with the right name',
    () async {
      final transport = _transport(types: ['Q482994']);
      await expectLater(
        findMatchingSource(
          WikidataProvider(transport),
          _external(workId: 'Q1'),
        ),
        throwsA(_code('unavailable')),
      );
      await transport.close();
    },
  );

  test(
    'own catalog selection keeps its work author on exact resolve',
    () async {
      final transport = _transport(types: ['Q7366']);
      final result = await findMatchingSource(
        WikidataProvider(transport),
        _selected,
      );
      expect(result.candidate.artist, 'Writer');
      expect(result.matchKind, MatchKind.sameSong);
      expect(result.extra.containsKey('identityMatch'), isFalse);
      await transport.close();
    },
  );

  test('cancelled external enrichment starts no HTTP request', () async {
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
      findMatchingSource(
        WikidataProvider(transport),
        _external(),
        cancel: cancellation,
      ),
      throwsA(isA<ProviderException>()),
    );
    expect(calls, 0);
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

SongCandidate _external({
  String? workId,
  bool recordingId = false,
  String title = 'Example',
  String artist = 'Cover Performer',
  Map<String, dynamic> metadata = const {},
}) => SongCandidate(
  providerId: 'external',
  id: 'recording',
  title: title,
  artist: artist,
  metadata: {
    ...metadata,
    if (workId != null && !recordingId) 'wikidataId': workId,
  },
  recordingIds: {if (workId != null && recordingId) 'wikidata': workId},
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
  String? returnedId,
  bool busy = false,
  bool withCreators = true,
  List<String> workIds = const ['Q1'],
  List<String> performerIds = const ['Q2', 'Q2', 'Q3'],
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
          for (final id in workIds) {'id': id},
        ],
      });
    }
    final requested = (request.url.queryParameters['ids'] ?? '').split('|');
    if (requested.any(workIds.contains)) {
      return _json({
        'entities': {
          for (final id in requested.where(workIds.contains))
            (returnedId ?? id): {
              'labels': {
                'en': {'value': 'Example'},
              },
              'claims': {
                'P31': types.map(_claim).toList(),
                if (withCreators) 'P86': [_claim('Q2')],
                if (withCreators) 'P676': [_claim('Q2')],
                'P175': performerIds.map(_claim).toList(),
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
