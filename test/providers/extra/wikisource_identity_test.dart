import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';

void main() {
  test(
    'own selected historical text accepts resolved author, never recording',
    () async {
      final transport = _transport();
      final provider = WikisourceProvider(transport);
      final selected = (await provider.search('Example Text')).single;
      expect(selected.artist, isEmpty);

      final result = await findMatchingSource(provider, selected);
      expect(result.matchKind, MatchKind.sameSong);
      expect(result.matchReason, 'explicit_historical_work');
      expect(result.extra.containsKey('requiresLyricsAgreement'), isFalse);
      expect(result.candidate.artist, 'Writer');
      expect(result.metadata['identityScope'], 'historicalText');
      expect(result.metadata['copyrightTags'], ['Template:PD-old']);
      expect(result.attribution, contains('Writer'));
      await transport.close();
    },
  );

  test(
    'explicit author remains exact and known author mismatch is rejected',
    () async {
      final transport = _transport();
      final provider = WikisourceProvider(transport);
      final selected = (await provider.search('Example Text')).single;
      final known = SongCandidate(
        providerId: selected.providerId,
        id: selected.id,
        title: selected.title,
        artist: 'Writer',
        metadata: selected.metadata,
      );
      expect(
        (await findMatchingSource(provider, known)).matchKind,
        MatchKind.sameSong,
      );

      final wrong = SongCandidate(
        providerId: selected.providerId,
        id: selected.id,
        title: selected.title,
        artist: 'Different Writer',
        metadata: selected.metadata,
      );
      expect(
        (await findMatchingSource(provider, wrong)).matchKind,
        MatchKind.rejected,
      );
      await transport.close();
    },
  );

  for (final invalid in [null, 0, -1, 123.0, 123.5, '123', false]) {
    test(
      'parse revision must be a positive integer: $invalid (${invalid.runtimeType})',
      () async {
        final transport = _transport(parseOverrides: {'revid': invalid});
        try {
          final provider = WikisourceProvider(transport);
          final selected = (await provider.search('Example Text')).single;
          await expectLater(
            provider.resolve(selected),
            throwsA(
              isA<ProviderException>().having(
                (e) => e.code,
                'code',
                'invalid_response',
              ),
            ),
          );
        } finally {
          await transport.close();
        }
      },
    );
  }

  test('missing parse revision cannot produce fresh page proof', () async {
    final transport = _transport(omitRevision: true);
    try {
      final provider = WikisourceProvider(transport);
      final selected = (await provider.search('Example Text')).single;
      await expectLater(
        findMatchingSource(provider, selected),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'invalid_response',
          ),
        ),
      );
    } finally {
      await transport.close();
    }
  });

  test(
    'cross-provider candidate and forged historical scope do not weaken matching',
    () async {
      final transport = _transport();
      final provider = WikisourceProvider(transport);
      final external = SongCandidate(
        providerId: 'musicbrainz',
        id: 'r1',
        title: 'Example Text',
        artist: '',
        metadata: const {'identityScope': 'historicalText'},
      );
      final crossProvider = await findMatchingSource(provider, external);
      expect(crossProvider.matchKind, MatchKind.rejected);

      final forged = FakeProvider(
        const ProviderDefinition(
          id: 'other',
          name: 'Other',
          capabilities: {'catalog', 'lyrics'},
        ),
      );
      final forgedResult = await findMatchingSource(
        forged,
        SongCandidate(
          providerId: 'other',
          id: '1',
          title: 'Example Text',
          artist: '',
          metadata: const {'identityScope': 'historicalText'},
        ),
      );
      expect(forgedResult.matchKind, MatchKind.rejected);
      expect(forgedResult.candidate.artist, 'Different Author');
      await transport.close();
    },
  );

  for (final response in [
    {'pageid': 8, 'title': 'Example Text'},
    {'pageid': 7, 'title': 'Different Text'},
    {'pageid': 7, 'title': 'Example Text: Collected Edition'},
  ]) {
    test(
      'rejects parse response with wrong page or title: $response',
      () async {
        final transport = _transport(parseOverrides: response);
        final provider = WikisourceProvider(transport);
        final selected = (await provider.search('Example Text')).single;
        await expectLater(
          findMatchingSource(provider, selected),
          throwsA(isA<ProviderException>()),
        );
        await transport.close();
      },
    );
  }

  test(
    'rights absence blocks import; another edition page is never selected',
    () async {
      final noRights = _transport(rights: false);
      final provider = WikisourceProvider(noRights);
      final selected = (await provider.search('Example Text')).single;
      await expectLater(
        findMatchingSource(provider, selected),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'rights_review_required',
          ),
        ),
      );
      await noRights.close();

      final editionTransport = _transport();
      final editionProvider = WikisourceProvider(editionTransport);
      final otherPage = SongCandidate(
        providerId: 'wikisource',
        id: '99',
        title: 'Example Text',
        artist: '',
        metadata: const {'identityScope': 'historicalText'},
      );
      await expectLater(
        findMatchingSource(editionProvider, otherPage),
        throwsA(isA<ProviderException>()),
      );
      await editionTransport.close();
    },
  );

  test('disambiguation pages require a specific work selection', () async {
    final transport = _transport(disambiguation: true);
    final provider = WikisourceProvider(transport);
    final selected = (await provider.search('Example Text')).single;
    await expectLater(
      findMatchingSource(provider, selected),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.code,
          'code',
          'select_specific_work',
        ),
      ),
    );
    await transport.close();
  });

  test(
    'own page selection cannot fall back to another same-titled page',
    () async {
      final actions = <String?>[];
      final transport = _transport(
        searchPageId: 8,
        unavailableFirstParse: true,
        onRequest: (request) =>
            actions.add(request.url.queryParameters['action']),
      );
      final provider = WikisourceProvider(transport);
      const selected = SongCandidate(
        providerId: 'wikisource',
        id: '7',
        title: 'Example Text',
        artist: '',
        metadata: {'identityScope': 'historicalText'},
      );
      await expectLater(
        findMatchingSource(provider, selected),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'unavailable'),
        ),
      );
      expect(actions, ['parse']);
      await transport.close();
    },
  );

  test('pre-cancelled lookup performs no HTTP request', () async {
    var calls = 0;
    final transport = ProviderTransport(
      hostInterval: Duration.zero,
      client: MockClient((_) async {
        calls++;
        return _json({});
      }),
    );
    final cancellation = CancellationToken()..cancel();
    await expectLater(
      findMatchingSource(
        WikisourceProvider(transport),
        const SongCandidate(
          providerId: 'wikisource',
          id: '7',
          title: 'Example Text',
          artist: '',
          metadata: {'identityScope': 'historicalText'},
        ),
        cancel: cancellation,
      ),
      throwsA(
        isA<ProviderException>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
    expect(calls, 0);
    await transport.close();
  });
}

class FakeProvider implements LyricsProvider {
  FakeProvider(this.definition);
  @override
  final ProviderDefinition definition;
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: SongCandidate(
      providerId: candidate.providerId,
      id: candidate.id,
      title: candidate.title,
      artist: 'Different Author',
      metadata: const {
        'identityScope': 'historicalText',
        'resolvedPageId': '1',
        'resolvedTitle': 'Example Text',
        'copyrightTags': ['invented'],
      },
    ),
    body: 'invented short text',
    metadata: candidate.metadata,
  );
}

ProviderTransport _transport({
  bool rights = true,
  bool disambiguation = false,
  Map<String, Object?>? parseOverrides,
  int searchPageId = 7,
  bool unavailableFirstParse = false,
  bool omitRevision = false,
  void Function(http.Request request)? onRequest,
}) {
  var parseCalls = 0;
  return ProviderTransport(
    hostInterval: Duration.zero,
    client: MockClient((request) async {
      onRequest?.call(request);
      if (request.url.queryParameters['action'] == 'query') {
        return _json({
          'query': {
            'search': [
              {
                'pageid': searchPageId,
                'title': 'Example Text',
                'snippet': 'short invented excerpt',
              },
            ],
          },
        });
      }
      parseCalls++;
      if (unavailableFirstParse && parseCalls == 1) {
        return _json({
          'error': {'code': 'missingtitle'},
        });
      }
      return _json({
        'parse': {
          'pageid': searchPageId,
          'title': 'Example Text',
          if (!omitRevision) 'revid': 123,
          'templates': [
            if (rights) {'title': 'Template:PD-old'},
            if (disambiguation) {'title': 'Template:Disambiguation'},
          ],
          'text':
              '<div class="poem">invented short text</div><a href="/wiki/Author:Writer">Writer</a>',
          ...?parseOverrides,
        },
      });
    }),
  );
}

http.Response _json(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);
