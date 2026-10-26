import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/lrc_red.dart';
import 'package:singbook/providers/provider.dart';

const _isrc = 'USABC1234567';
const _raw = '''<tt xmlns="http://www.w3.org/ns/ttml"
 xmlns:lr="http://lrc.red/lyric-ttml-internal" lr:timing="Word">
 <body><div><p begin="19.764" end="22.0"><span begin="20.1" end="21.0">Fresh</span> words</p></div></body>
</tt>''';

Map<String, Object?> _row({Map<String, Object?> overrides = const {}}) => {
  'isrc': _isrc,
  'title': 'Invented Song',
  'artist': 'Invented Artist',
  'album': 'Synthetic Album',
  'duration': 180,
  'language': 'en',
  'released': '2024-05-06',
  'songwriters': ['Writer One'],
  'cover': 'https://lrc.red/s/$_isrc.webp',
  'files': {'ttml': 'https://lrc.red/s/$_isrc.ttml'},
  ...overrides,
};

SongCandidate _selected() => const SongCandidate(
  providerId: 'lrcred',
  id: _isrc,
  title: 'Invented Song',
  artist: 'Invented Artist',
  album: 'Synthetic Album',
  durationSeconds: 180,
  recordingIds: {'isrc': _isrc},
);

class _Harness {
  _Harness({
    Object? hits,
    bool omitHits = false,
    Map<String, Object?> detailOverrides = const {},
    String? raw = _raw,
  }) : client = MockClient((request) async {
         requests.add(request);
         if (request.url.path == '/search.json') {
           return http.Response(
             jsonEncode({
               if (!omitHits) 'hits': hits ?? [_row()],
             }),
             200,
             headers: {'content-type': 'application/json'},
           );
         }
         if (request.url.path == '/s/$_isrc.json') {
           return http.Response(
             jsonEncode(_row(overrides: detailOverrides)),
             200,
             headers: {'content-type': 'application/json'},
           );
         }
         if (request.url.path == '/s/$_isrc.ttml') {
           return http.Response(raw ?? '', 200);
         }
         return http.Response('unexpected remote request', 404);
       }) {
    transport = ProviderTransport(
      client: client,
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    provider = LrcRedProvider(transport, requestInterval: Duration.zero);
  }

  final MockClient client;
  late final ProviderTransport transport;
  late final LrcRedProvider provider;
  static final List<http.Request> requests = [];
  Future<void> close() => transport.close();
}

void main() {
  setUp(() => _Harness.requests.clear());

  test(
    'search sends contact identification and retains source attribution',
    () async {
      final h = _Harness();
      try {
        final rows = await h.provider.search('Invented Song');
        expect(rows, hasLength(1));
        expect(rows.single.recordingIds['isrc'], _isrc);
        expect(rows.single.url, 'https://lrc.red/s/$_isrc');
        expect(
          rows.single.metadata['mediaLinks'],
          contains(
            equals({
              'kind': 'source',
              'label': 'lrc.red',
              'url': 'https://lrc.red/s/$_isrc',
            }),
          ),
        );
        final request = _Harness.requests.single;
        expect(request.url.queryParameters['q'], 'Invented Song');
        expect(request.headers['user-agent'], contains('support@freevia.org'));
      } finally {
        await h.close();
      }
    },
  );

  test(
    'resolve preserves recording metadata, attribution, raw TTML and word cues',
    () async {
      final h = _Harness();
      try {
        final result = await h.provider.resolve(_selected());
        expect(result.body, 'Fresh words');
        expect(result.attribution, contains('lrc.red'));
        expect(result.candidate.recordingIds['isrc'], _isrc);
        expect(result.candidate.album, 'Synthetic Album');
        expect(result.candidate.durationSeconds, 180);
        expect(result.metadata['language'], 'en');
        expect(result.metadata['releaseDate'], '2024-05-06');
        expect(result.metadata['credits'], [
          {'role': 'songwriter', 'name': 'Writer One'},
        ]);
        expect(result.candidate.artworkUrl, 'https://lrc.red/s/$_isrc.webp');
        final track = result.timingTracks.single;
        expect(track.raw, _raw);
        expect(track.recordingId, 'lrcred:$_isrc');
        expect(track.sourceLyrics, 'Fresh words');
        expect(
          track.cues.map((cue) => cue.text),
          containsAll(['Fresh words', 'Fresh']),
        );
        expect(
          track.cues.singleWhere((cue) => cue.graphemeStart != null).startUs,
          20100000,
        );
      } finally {
        await h.close();
      }
    },
  );

  for (final change in <String, Object?>{
    'isrc': 'GBXYZ7654321',
    'title': 'Different Song',
    'artist': 'Different Artist',
    'album': 'Different Album',
    'duration': 240,
  }.entries) {
    test(
      'rejects detail identity mismatch in ${change.key} before fetching text',
      () async {
        final h = _Harness(detailOverrides: {change.key: change.value});
        try {
          await expectLater(
            h.provider.resolve(_selected()),
            throwsA(
              isA<ProviderException>().having(
                (e) => e.code,
                'code',
                'identity_mismatch',
              ),
            ),
          );
          expect(
            _Harness.requests.where((r) => r.url.path.endsWith('.ttml')),
            isEmpty,
          );
        } finally {
          await h.close();
        }
      },
    );
  }

  for (final url in [
    'https://evil.example/s/$_isrc.ttml',
    'http://lrc.red/s/$_isrc.ttml',
    'https://user@lrc.red/s/$_isrc.ttml',
    'https://lrc.red.evil.example/s/$_isrc.ttml',
    'https://lrc.red/s/OTHER.ttml',
    'https://lrc.red/s/$_isrc.ttml?download=1',
  ]) {
    test('rejects hostile TTML URL without remote text fetch: $url', () async {
      final h = _Harness(
        detailOverrides: {
          'files': {'ttml': url},
        },
      );
      try {
        await expectLater(
          h.provider.resolve(_selected()),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.code,
              'code',
              'invalid_response',
            ),
          ),
        );
        expect(
          _Harness.requests.where((r) => r.url.path.endsWith('.ttml')),
          isEmpty,
        );
      } finally {
        await h.close();
      }
    });
  }

  test('drops artwork URL on the wrong host', () async {
    final h = _Harness(
      detailOverrides: {'cover': 'https://evil.example/s/$_isrc.webp'},
    );
    try {
      final result = await h.provider.resolve(_selected());
      expect(result.candidate.artworkUrl, isNull);
    } finally {
      await h.close();
    }
  });

  test(
    'missing hits is a schema error and malformed rows do not hide good rows',
    () async {
      final missing = _Harness(omitHits: true);
      try {
        await expectLater(
          missing.provider.search('x'),
          throwsA(isA<ProviderException>()),
        );
      } finally {
        await missing.close();
      }
      final mixed = _Harness(
        hits: [
          null,
          {'title': 'incomplete'},
          _row(),
        ],
      );
      try {
        expect(await mixed.provider.search('x'), hasLength(1));
      } finally {
        await mixed.close();
      }
    },
  );

  test(
    'foreign candidate needs exact ISRC and cancellation before queue makes no HTTP request',
    () async {
      final h = _Harness();
      try {
        const foreign = SongCandidate(
          providerId: 'catalog',
          id: 'catalog-1',
          title: 'Invented Song',
          artist: 'Invented Artist',
        );
        await expectLater(
          h.provider.resolve(foreign),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.code,
              'code',
              'identity_required',
            ),
          ),
        );
        final token = CancellationToken()..cancel();
        await expectLater(
          h.provider.search('cancel me', cancel: token),
          throwsA(
            isA<ProviderException>().having((e) => e.code, 'code', 'cancelled'),
          ),
        );
        expect(_Harness.requests, isEmpty);
      } finally {
        await h.close();
      }
    },
  );

  test(
    'foreign candidate with exact ISRC resolves through recording identity',
    () async {
      final h = _Harness();
      try {
        const foreign = SongCandidate(
          providerId: 'catalog',
          id: 'catalog-1',
          title: 'Invented Song',
          artist: 'Invented Artist',
          album: 'Synthetic Album',
          durationSeconds: 180,
          recordingIds: {'isrc': _isrc},
        );
        final result = await h.provider.resolve(foreign);
        expect(result.body, 'Fresh words');
      } finally {
        await h.close();
      }
    },
  );

  test('malformed raw TTML becomes invalid_response', () async {
    final h = _Harness(raw: '<!DOCTYPE x [<!ENTITY e "bad">]><tt>&e;</tt>');
    try {
      await expectLater(
        h.provider.resolve(_selected()),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'invalid_response',
          ),
        ),
      );
    } finally {
      await h.close();
    }
  });
}
