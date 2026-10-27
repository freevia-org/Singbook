import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/providers/extra/startjamming.dart';
import 'package:singbook/providers/provider.dart';

const _id = 'test-song';
const _songId = 'test_song';
const _title = 'Test Song';
const _searchUri = 'https://www.startjamming.com/api/songs/search';
const _apiUrl =
    'https://www.startjamming.com/api/songs/test-song/full?for=agent';
const _humanUrl = 'https://www.startjamming.com/song/test-song';
const _searchEtag = '"search-test-song"';
const _detailEtag = '"full-test-song"';

Map<String, Object?> _searchRow({Map<String, Object?> overrides = const {}}) =>
    {
      'id': _id,
      'canonical_id': _id,
      'song_id': _songId,
      'slug': _id,
      'title': _title,
      'url': _humanUrl,
      'api_url': _apiUrl,
      'type': 'vocal',
      'key': 'C',
      'match_type': 'title_exact',
      'score': 1.0,
      ...overrides,
    };

Map<String, Object?> _detail({
  Map<String, Object?> topOverrides = const {},
  Map<String, Object?> arrangementOverrides = const {},
}) => {
  'id': _id,
  'canonical_id': _id,
  'song_id': _songId,
  'slug': _id,
  'title': _title,
  'url': _humanUrl,
  'api_url': _apiUrl,
  'type': 'vocal',
  'key': 'C',
  'signature': 'waltz',
  'tempo': 92,
  'demo': ['https://www.youtube.com/watch?v=abcdefghijk'],
  'featured_demo': [
    'https://www.youtube.com/watch?v=abcdefghijk',
    'https://evil.example/watch?v=abcdefghijk',
  ],
  'lyrics': 'Verse line\n<chorus>Chorus {text} [brackets]</chorus>',
  'arrangement': {
    'song_id': _songId,
    'title': _title,
    'original_key': 'C',
    'target_key': 'C',
    'signature': '3/4',
    'default_beats_per_measure': 3,
    'sections': [
      {
        'name': 'A',
        'repeats': 2,
        'measures': [
          {
            'index': 0,
            'source': 'C / /',
            'beats': ['C', 'C', null],
            'display': 'C / /',
            'beat_count': 3,
            'has_rest': true,
          },
          {
            'index': 1,
            'source': 'G / /',
            'beats': ['G', 'G', 'G'],
            'display': 'G / /',
            'beat_count': 3,
            'has_rest': false,
          },
        ],
      },
    ],
    'backing_track_progression': ['C / /', 'C / /', 'G / /', 'G / /'],
    'unique_chords': ['C', 'G'],
    ...arrangementOverrides,
  },
  ...topOverrides,
};

class _Harness {
  _Harness({
    Map<String, Object?>? search,
    Map<String, Object?>? detail,
    String? searchEtag = _searchEtag,
    String? detailEtag = _detailEtag,
    DateTime Function()? clock,
  }) {
    client = MockClient((request) async {
      _requests.add(request);
      final isSearch = request.url.path == '/api/songs/search';
      if (isSearch) {
        expect(request.url.host, 'www.startjamming.com');
        expect(request.url.queryParameters['for'], 'agent');
        expect(request.url.queryParameters['q'], 'Test Song');
        expect(request.url.queryParameters['limit'], '8');
        final tag = searchEtag;
        if (request.headers['if-none-match'] == tag && tag != null) {
          return http.Response('', 304, headers: {'etag': tag});
        }
        return http.Response(
          jsonEncode(search ?? _searchRow()),
          200,
          headers: {
            'content-type': 'application/json; charset=utf-8',
            'etag': ?tag,
          },
        );
      }
      if (request.url.toString() == _apiUrl) {
        final tag = detailEtag;
        if (request.headers['if-none-match'] == tag && tag != null) {
          return http.Response('', 304, headers: {'etag': tag});
        }
        return http.Response(
          jsonEncode(detail ?? _detail()),
          200,
          headers: {
            'content-type': 'application/json; charset=utf-8',
            'etag': ?tag,
          },
        );
      }
      return http.Response('unexpected', 404);
    });
    transport = ProviderTransport(
      client: client,
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    provider = StartJammingProvider(
      transport,
      clock: clock,
      cacheLifetime: const Duration(minutes: 15),
    );
  }

  late final MockClient client;
  final List<http.Request> _requests = [];
  List<http.Request> get requests => _requests;
  late final ProviderTransport transport;
  late final StartJammingProvider provider;

  Future<void> close() => transport.close();
}

Matcher _failure(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);

void main() {
  test(
    'search accepts exact top-level hits and keeps canonical identity',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      final results = await h.provider.search('Test Song');
      expect(results, hasLength(1));
      final candidate = results.single;
      expect(candidate.id, _id);
      expect(candidate.title, _title);
      expect(candidate.artist, '');
      expect(candidate.url, _humanUrl);
      expect(candidate.metadata['identityScope'], 'arrangement');
      expect(candidate.recordingIds, isEmpty);
      expect(h.requests.single.url.toString(), startsWith(_searchUri));
      expect(h.requests.single.headers['user-agent'], contains('Singbook/'));
    },
  );

  test(
    'search accepts bounded results arrays and rejects invalid IDs/URLs',
    () async {
      final rowsHarness = _Harness(
        search: {
          'results': [_searchRow()],
        },
      );
      addTearDown(rowsHarness.close);
      expect(await rowsHarness.provider.search('Test Song'), hasLength(1));

      for (final change in <String, Object?>{
        'id': '../test-song',
        'song_id': 'other_song',
        'url': 'https://evil.example/song/test-song',
        'api_url':
            'https://www.startjamming.com.evil/api/songs/test-song/full?for=agent',
      }.entries) {
        final h = _Harness(
          search: _searchRow(overrides: {change.key: change.value}),
        );
        addTearDown(h.close);
        await expectLater(
          h.provider.search('Test Song'),
          throwsA(anyOf(_failure('invalid_response'), _failure('invalid_url'))),
        );
      }
    },
  );

  test(
    'detail renders lyrics and chord-only measures without aligning them',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      final candidate = (await h.provider.search('Test Song')).single;
      final result = await h.provider.resolve(candidate);
      expect(result.body, contains('Verse line'));
      expect(result.body, contains(r'\{text\}'));
      expect(result.body, contains(r'\[brackets\]'));
      expect(result.body, contains('{start_of_chorus}'));
      expect(result.body, contains('{end_of_chorus}'));
      expect(lyricLines(result.body), [
        'Verse line',
        'Chorus {text} [brackets]',
      ]);
      expect(
        result.body,
        contains('Chord progression (not aligned to lyrics)'),
      );
      expect(result.body, contains('Section A (repeat 2x)'));
      expect(result.body, contains('[C] [C] [N.C.]'));
      expect(result.body, contains('[G] [G] [G]'));
      expect(result.metadata['key'], 'C');
      expect(result.metadata['timeSignature'], '3/4');
      expect(result.metadata['tempo'], 92.0);
      expect(result.metadata['mediaLinks'], [
        {
          'kind': 'youtube',
          'label': 'Demo video',
          'url': 'https://www.youtube.com/watch?v=abcdefghijk',
        },
      ]);
      expect(result.extra['startjamming']['sourceSignature'], 'waltz');
      expect(result.timingTracks, isEmpty);
      expect(result.candidate.recordingIds, isEmpty);
      expect(result.attribution, 'Start Jamming — $_humanUrl');
      expect(result.extra['rights']['license'], 'unknown');
      expect(result.extra['startjamming']['artist'], isNull);
      expect(
        result.extra['startjamming']['rawFullJson']['arrangement']['song_id'],
        _songId,
      );
      expect(result.extra['originalPayload']['httpBodyBytesExact'], true);
      expect(result.extra['originalPayload']['wireExact'], false);
      final bytes = base64Decode(
        result.extra['originalPayload']['base64'] as String,
      );
      expect(utf8.decode(bytes), jsonEncode(_detail()));
    },
  );

  test('instrumental arrangement resolves without fabricated lyrics', () async {
    final detail = _detail(topOverrides: {'lyrics': null});
    final h = _Harness(detail: detail);
    addTearDown(h.close);
    final candidate = (await h.provider.search('Test Song')).single;
    final result = await h.provider.resolve(candidate);
    expect(result.body, isNot(contains('Verse line')));
    expect(result.body, contains('Chord progression (not aligned to lyrics)'));
    expect(result.body, contains('[N.C.]'));
  });

  test('chorus tags never merge directives or split lyric lines', () async {
    for (final text in [
      'First line\n<chorus>Second line\nThird line</chorus>\nLast line',
      'First line\n<chorus>\nSecond line\nThird line\n</chorus>\nLast line',
      'First line\nSecond <chorus>line\nThird</chorus> line\nLast line',
    ]) {
      final h = _Harness(detail: _detail(topOverrides: {'lyrics': text}));
      addTearDown(h.close);
      final result = await h.provider.resolve(
        (await h.provider.search('Test Song')).single,
      );
      expect(lyricLines(result.body), [
        'First line',
        'Second line',
        'Third line',
        'Last line',
      ]);
    }
    for (final text in [
      '<chorus>Missing close',
      '</chorus>Unexpected close',
      '<chorus>Nested <chorus>text</chorus></chorus>',
    ]) {
      final h = _Harness(detail: _detail(topOverrides: {'lyrics': text}));
      addTearDown(h.close);
      await expectLater(
        h.provider.resolve((await h.provider.search('Test Song')).single),
        throwsA(_failure('invalid_response')),
      );
    }
  });

  test(
    'renders every labeled lyric variant without choosing a preferred one',
    () async {
      final detail = _detail(
        topOverrides: {
          'lyrics': ['First language line', 'Second language line'],
          'lyrics_alternates': [
            {'index': 0, 'label': 'Language One'},
            {'index': 1, 'label': 'Language Two'},
          ],
        },
      );
      final h = _Harness(detail: detail);
      addTearDown(h.close);
      final candidate = (await h.provider.search('Test Song')).single;
      final result = await h.provider.resolve(candidate);
      expect(result.body, contains('Lyrics variant 1: Language One'));
      expect(result.body, contains('Lyrics variant 2: Language Two'));
      expect(result.body, contains('First language line'));
      expect(result.body, contains('Second language line'));
      final variants = result.extra['startjamming']['lyricsVariants'] as List;
      expect(variants, hasLength(2));
      expect(variants.map((v) => v['text']), [
        'First language line',
        'Second language line',
      ]);
    },
  );

  test(
    'chooses normalized arrangement key, not first multi-arrangement key',
    () async {
      final detail = _detail(
        topOverrides: {
          'key': ['G', 'Am'],
        },
        arrangementOverrides: {'target_key': 'C', 'original_key': 'C'},
      );
      final h = _Harness(detail: detail);
      addTearDown(h.close);
      final candidate = (await h.provider.search('Test Song')).single;
      final result = await h.provider.resolve(candidate);
      expect(result.metadata['key'], 'C');
      expect(result.extra['startjamming']['rawFullJson']['key'], ['G', 'Am']);
    },
  );

  test(
    'rejects malformed chord grammar and inconsistent measure shapes',
    () async {
      for (final badMeasure in [
        {
          'beats': ['C garbage'],
          'beat_count': 1,
          'has_rest': false,
        },
        {
          'beats': [' C '],
          'beat_count': 1,
          'has_rest': false,
        },
        {
          'beats': ['C', null],
          'beat_count': 2,
          'has_rest': false,
        },
        {
          'beats': ['C'],
          'beat_count': 2,
          'has_rest': false,
        },
        {
          'beats': ['C'],
          'beat_count': 1,
          'has_rest': false,
          'source': {
            'deep': {
              'too': {
                'many': {
                  'nested': {
                    'objects': {'here': true},
                  },
                },
              },
            },
          },
        },
      ]) {
        final detail = _detail(
          arrangementOverrides: {
            'sections': [
              {
                'name': 'A',
                'repeats': 1,
                'measures': [badMeasure],
              },
            ],
          },
        );
        final h = _Harness(detail: detail);
        addTearDown(h.close);
        final candidate = (await h.provider.search('Test Song')).single;
        await expectLater(
          h.provider.resolve(candidate),
          throwsA(_failure('invalid_response')),
        );
      }
    },
  );

  test(
    'rejects contradictory detail identity and foreign selected candidates',
    () async {
      final h = _Harness(
        detail: _detail(topOverrides: {'canonical_id': 'other-song'}),
      );
      addTearDown(h.close);
      final candidate = (await h.provider.search('Test Song')).single;
      await expectLater(
        h.provider.resolve(candidate),
        throwsA(_failure('invalid_response')),
      );
      await expectLater(
        h.provider.resolve(
          const SongCandidate(
            providerId: 'another-source',
            id: _id,
            title: _title,
            artist: '',
          ),
        ),
        throwsA(_failure('unavailable')),
      );
    },
  );

  test(
    'ETag cache revalidates after expiry and preserves original bytes/time',
    () async {
      var now = DateTime.utc(2026, 10, 27, 12);
      final h = _Harness(clock: () => now);
      addTearDown(h.close);
      final candidate = (await h.provider.search('Test Song')).single;
      final first = await h.provider.resolve(candidate);
      final firstRetrievedAt = first.retrievedAt;
      final firstPayload = first.extra['originalPayload']['base64'];
      expect(h.requests, hasLength(2));

      now = now.add(const Duration(minutes: 16));
      await h.provider.search('Test Song');
      final refreshed = await h.provider.resolve(candidate);
      expect(h.requests, hasLength(4));
      expect(h.requests[2].headers['if-none-match'], _searchEtag);
      expect(h.requests[3].headers['if-none-match'], _detailEtag);
      expect(refreshed.retrievedAt, firstRetrievedAt);
      expect(refreshed.extra['startjamming']['validatedAt'], isNotNull);
      expect(refreshed.extra['originalPayload']['base64'], firstPayload);
    },
  );

  test('cancellation before search prevents a request', () async {
    final h = _Harness();
    addTearDown(h.close);
    final cancel = CancellationToken()..cancel();
    await expectLater(
      h.provider.search('Test Song', cancel: cancel),
      throwsA(_failure('cancelled')),
    );
    expect(h.requests, isEmpty);
  });
}
