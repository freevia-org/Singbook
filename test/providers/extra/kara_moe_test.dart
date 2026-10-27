import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/extra/kara_moe.dart';
import 'package:singbook/providers/provider.dart';

const _uuid = 'b18a3a2c-4428-4a3c-9f7a-b432a9020174';
const _line1 = 'Moonlight paints a silver river';
const _line2 = 'We follow stars beyond the harbor';

Map<String, Object?> _row({
  String? kid,
  String title = 'Invented Karaoke Song',
  String artist = 'Invented Performer',
  List<Object?>? lyrics,
}) => {
  'kid': kid ?? _uuid,
  'titles': {'eng': title},
  'titles_default_language': 'eng',
  'singers': [
    {'name': artist},
  ],
  'songwriters': [
    {'name': 'Invented Writer'},
  ],
  'authors': [
    {'name': 'Invented Karaoke Author'},
  ],
  'creators': [
    {'name': 'Invented Contributor'},
  ],
  'songtypes': [
    {'name': 'ED'},
  ],
  'versions': [
    {'name': 'TV size'},
  ],
  'collections': [
    {'name': 'Synthetic Collection'},
  ],
  'langs': [
    {'name': 'English'},
  ],
  'duration': 143,
  'year': 2021,
  'mediafile': 'https://kara.moe/never-fetch-video.webm',
  'karafile': 'https://kara.moe/never-fetch-song.kar',
  'lyrics': ?lyrics,
};

Map<String, Object?> _lyricLine(
  String text,
  num start,
  num end, {
  List<Object?>? fullText,
}) => {
  'start': start,
  'end': end,
  'text': text,
  'fullText':
      fullText ??
      [
        {
          'tags': [
            {'k': 23},
            {'kf': 17},
          ],
          'text': text,
          'drawing': null,
        },
      ],
};

final _lines = <Object?>[
  _lyricLine(_line1, 12.345, 15.25),
  _lyricLine(_line2, 15.25, 19.5),
];

SongCandidate _candidate({
  String providerId = 'karamoe',
  String id = _uuid,
  String title = 'Invented Karaoke Song',
  String artist = 'Invented Performer',
  JsonMap metadata = const {},
}) => SongCandidate(
  providerId: providerId,
  id: id,
  title: title,
  artist: artist,
  metadata: metadata,
);

class _Harness {
  _Harness({Map<String, Object?>? detail, String? detailRaw, Object? search}) {
    client = MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/api/karas/search') {
        return http.Response(
          jsonEncode(
            search ??
                {
                  'content': [_row()],
                },
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path == '/api/karas/$_uuid') {
        return http.Response(
          detailRaw ?? jsonEncode(detail ?? _row(lyrics: _lines)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('unexpected request', 404);
    });
    transport = ProviderTransport(
      client: client,
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    provider = KaraMoeProvider(transport, requestInterval: Duration.zero);
  }

  late final MockClient client;
  late final ProviderTransport transport;
  late final KaraMoeProvider provider;
  final List<http.Request> requests = [];
  Future<void> close() => transport.close();
}

Matcher _code(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);

void main() {
  test(
    'populated but unreadable identities are schema failures, not empty search',
    () async {
      final h = _Harness(
        search: {
          'content': [
            {'new_id_field': _uuid},
          ],
        },
      );
      try {
        await expectLater(
          h.provider.search('Invented'),
          throwsA(_code('invalid_response')),
        );
      } finally {
        await h.close();
      }
    },
  );

  test(
    'interleaved source events retain lyric occurrences with ordered timing cues',
    () async {
      final h = _Harness(
        detail: _row(
          lyrics: [_lyricLine(_line1, 10, 12), _lyricLine(_line2, 2, 4)],
        ),
      );
      try {
        final track = (await h.provider.resolve(
          _candidate(),
        )).timingTracks.single;
        expect(track.sourceLyrics, '$_line1\n$_line2');
        expect(track.cues.map((c) => c.startUs), [2000000, 10000000]);
        expect(track.cues.map((c) => c.occurrenceId), ['line-1', 'line-0']);
      } finally {
        await h.close();
      }
    },
  );

  test(
    'publisher default title wins over an English alias and source facts keep their roles',
    () async {
      final row = _row()
        ..['titles'] = {
          'eng': 'Invented English Title',
          'qro': 'Invented Romanized Title',
        }
        ..['titles_default_language'] = 'qro'
        ..['titles_aliases'] = ['Another source title']
        ..['series'] = [
          {'name': 'Synthetic Series'},
        ]
        ..['warnings'] = [
          {'name': 'Spoiler'},
        ];
      final h = _Harness(
        search: {
          'content': [row],
        },
      );
      try {
        final candidate = (await h.provider.search('Invented')).single;
        expect(candidate.title, 'Invented Romanized Title');
        expect(
          candidate.metadata['sourceTitles']['eng'],
          'Invented English Title',
        );
        expect(candidate.metadata['sourceTitleAliases'], [
          'Another source title',
        ]);
        expect(candidate.metadata['sourceSeries'], ['Synthetic Series']);
        expect(candidate.metadata['sourceWarnings'], ['Spoiler']);
        expect(candidate.metadata['sourceCreators'], ['Invented Contributor']);
        expect(
          candidate.metadata['credits'],
          contains(
            equals({'role': 'source-creator', 'name': 'Invented Contributor'}),
          ),
        );
        expect(candidate.metadata['language'], 'English');
      } finally {
        await h.close();
      }
    },
  );

  test(
    'an HTML challenge remains an access block rather than a schema regression',
    () async {
      final h = _Harness(
        detailRaw: '<html><title>Just a moment</title></html>',
      );
      try {
        await expectLater(
          h.provider.resolve(_candidate()),
          throwsA(_code('blocked')),
        );
      } finally {
        await h.close();
      }
    },
  );

  test(
    'search uses documented query and returns arrangement-scoped KID metadata',
    () async {
      final h = _Harness();
      try {
        final results = await h.provider.search('Invented Karaoke Song');
        expect(results, hasLength(1));
        final candidate = results.single;
        expect(candidate.providerId, 'karamoe');
        expect(candidate.id, _uuid);
        expect(candidate.url, 'https://kara.moe/api/karas/$_uuid');
        expect(candidate.metadata['identityScope'], 'arrangement');
        expect(candidate.metadata['karaokeMugenId'], _uuid);
        expect(candidate.metadata['sourceVideoDurationSeconds'], 143);
        expect(candidate.metadata['sourceVideoYear'], 2021);
        expect(candidate.metadata.containsKey('year'), isFalse);
        expect(candidate.metadata.containsKey('album'), isFalse);
        expect(candidate.durationSeconds, isNull);
        expect(candidate.album, isNull);
        expect(candidate.recordingIds, isEmpty);
        expect(candidate.metadata['performers'], ['Invented Performer']);
        expect(candidate.metadata['songwriters'], ['Invented Writer']);
        expect(candidate.metadata['sourceSongTypes'], ['ED']);
        expect(candidate.metadata['sourceVersions'], ['TV size']);
        expect(candidate.metadata['version'], contains('Karaoke video'));
        final request = h.requests.single;
        expect(request.url.scheme, 'https');
        expect(request.url.host, 'kara.moe');
        expect(request.url.queryParameters, {
          'filter': 'Invented Karaoke Song',
          'from': '0',
          'size': '12',
        });
      } finally {
        await h.close();
      }
    },
  );

  test(
    'resolve preserves line cues, raw tagged JSON, and rights provenance',
    () async {
      final detail = _row(lyrics: _lines);
      final raw = jsonEncode(detail);
      final h = _Harness(detail: detail);
      try {
        final selected = (await h.provider.search(
          'Invented Karaoke Song',
        )).single;
        final result = await h.provider.resolve(selected);
        expect(result.candidate.id, _uuid);
        expect(result.candidate.metadata['identityScope'], 'arrangement');
        expect(result.body, '$_line1\n$_line2');
        expect(result.timingTracks, hasLength(1));
        final track = result.timingTracks.single;
        expect(track.format, 'json');
        expect(track.raw, raw);
        expect(track.status, TimingStatus.unverified);
        expect(track.granularity, 'line');
        expect(track.sourceLyrics, '$_line1\n$_line2');
        expect(track.cues, hasLength(2));
        expect(track.cues.map((cue) => cue.text), [_line1, _line2]);
        expect(track.cues.first.startUs, 12345000);
        expect(track.cues.first.endUs, 15250000);
        expect(track.cues.every((cue) => cue.graphemeStart == null), isTrue);
        expect(track.extra['parserVersion'], 'karaoke-mugen-json-1');
        expect(track.extra['recordingEvidence'], 'sourceDemonstrationOnly');
        expect(track.extra['sourceKID'], _uuid);
        expect(track.extra['fullTextRetainedInRawJson'], isTrue);
        final restored = jsonDecode(track.raw!) as Map<String, dynamic>;
        expect(restored['lyrics'][0]['fullText'][0]['tags'], [
          {'k': 23},
          {'kf': 17},
        ]);
        expect(result.attribution, contains('Invented Contributor'));
        expect(result.attribution, contains('Invented Karaoke Author'));
        expect(result.extra['originalPayload'], isA<Map>());
        final original = result.extra['originalPayload'] as Map;
        expect(original['contentType'], 'application/json');
        expect(utf8.decode(base64Decode(original['base64'] as String)), raw);
        final rights = (result.extra['rights'] as Map)['permissions'] as Map;
        expect(rights['database'], 'ODbL-1.0');
        expect(rights['lyrics'], 'unknown');
        expect(rights['synchronization'], 'varies-by-entry');
        expect(h.requests.map((r) => r.url.path), [
          '/api/karas/search',
          '/api/karas/$_uuid',
        ]);
      } finally {
        await h.close();
      }
    },
  );

  test(
    'foreign candidate needs explicit valid karaokeMugenId; KID is never recording identity',
    () async {
      final h = _Harness();
      try {
        await expectLater(
          h.provider.resolve(
            _candidate(providerId: 'catalog', id: 'catalog-1'),
          ),
          throwsA(_code('identity_required')),
        );
        expect(h.requests, isEmpty);
        final foreign = _candidate(
          providerId: 'catalog',
          id: 'catalog-1',
          metadata: {'karaokeMugenId': _uuid},
        );
        final result = await h.provider.resolve(foreign);
        expect(result.candidate.id, _uuid);
        expect(result.candidate.recordingIds, isEmpty);
      } finally {
        await h.close();
      }
    },
  );

  test(
    'rejects own UUID title or artist mismatch and unsafe foreign UUIDs',
    () async {
      final badDetail = _Harness(
        detail: _row(title: 'A Different Synthetic Song'),
      );
      try {
        await expectLater(
          badDetail.provider.resolve(_candidate()),
          throwsA(_code('identity_mismatch')),
        );
        expect(badDetail.requests.map((r) => r.url.path), [
          '/api/karas/$_uuid',
        ]);
      } finally {
        await badDetail.close();
      }

      final badArtist = _Harness(detail: _row(artist: 'Different Performer'));
      try {
        await expectLater(
          badArtist.provider.resolve(_candidate()),
          throwsA(_code('identity_mismatch')),
        );
      } finally {
        await badArtist.close();
      }

      final unsafe = _Harness();
      try {
        await expectLater(
          unsafe.provider.resolve(
            _candidate(
              providerId: 'catalog',
              metadata: {'karaokeMugenId': 'https://evil.example/x'},
            ),
          ),
          throwsA(_code('identity_required')),
        );
        expect(unsafe.requests, isEmpty);
      } finally {
        await unsafe.close();
      }
    },
  );

  for (final invalid in <String, Object?>{
    'negative start': _lyricLine('Synthetic line', -0.1, 1),
    'end before start': _lyricLine('Synthetic line', 2, 1),
    'empty interval': _lyricLine('Synthetic line', 2, 2),
    'beyond seven days': _lyricLine('Synthetic line', 0, 604801),
    'missing end': {'start': 0, 'text': 'Synthetic line'},
    'missing text': {'start': 0, 'end': 1},
  }.entries) {
    test('rejects invalid line timing: ${invalid.key}', () async {
      final detail = _row(lyrics: [invalid.value]);
      final h = _Harness(detail: detail);
      try {
        await expectLater(
          h.provider.resolve(_candidate()),
          throwsA(anyOf(_code('invalid_response'), isA<FormatException>())),
        );
      } finally {
        await h.close();
      }
    });
  }

  test('rejects nonfinite JSON timestamps', () async {
    final raw = jsonEncode(
      _row(lyrics: [_lyricLine('Synthetic line', 0, 1)]),
    ).replaceFirst('"start":0', '"start":NaN');
    final h = _Harness(detailRaw: raw);
    try {
      await expectLater(
        h.provider.resolve(_candidate()),
        throwsA(_code('invalid_response')),
      );
    } finally {
      await h.close();
    }
  });

  test(
    'rejects excessive cue counts before returning a partial track',
    () async {
      final tooMany = List<Object?>.generate(
        10001,
        (_) => {'start': 1, 'end': 2, 'text': 'x'},
      );
      final h = _Harness(detail: _row(lyrics: tooMany));
      try {
        await expectLater(
          h.provider.resolve(_candidate()),
          throwsA(anyOf(_code('invalid_response'), isA<FormatException>())),
        );
      } finally {
        await h.close();
      }
    },
  );

  test(
    'metadata-only detail is unavailable and no media files are fetched',
    () async {
      final detail = _row()..remove('lyrics');
      final h = _Harness(detail: detail);
      try {
        await expectLater(
          h.provider.resolve(_candidate()),
          throwsA(_code('unavailable')),
        );
        expect(h.requests.map((r) => r.url.path), ['/api/karas/$_uuid']);
      } finally {
        await h.close();
      }
    },
  );

  test(
    'uses performer group only when no singer names exist; songwriter is not performer',
    () async {
      final row = _row()..remove('singers');
      row['singergroups'] = [
        {'name': 'Synthetic Vocal Group'},
      ];
      final h = _Harness(
        search: {
          'content': [row],
        },
      );
      try {
        final result = await h.provider.search('Synthetic Song');
        expect(result.single.artist, 'Synthetic Vocal Group');
        expect(result.single.artist, isNot('Invented Writer'));
      } finally {
        await h.close();
      }
    },
  );

  test(
    'malformed search schema fails and pre-cancelled lookup sends no request',
    () async {
      final malformed = _Harness(search: {'hits': []});
      try {
        await expectLater(
          malformed.provider.search('Synthetic Song'),
          throwsA(_code('invalid_response')),
        );
      } finally {
        await malformed.close();
      }

      final cancelled = _Harness();
      try {
        final token = CancellationToken()..cancel();
        await expectLater(
          cancelled.provider.search('Synthetic Song', cancel: token),
          throwsA(_code('cancelled')),
        );
        expect(cancelled.requests, isEmpty);
      } finally {
        await cancelled.close();
      }
    },
  );
}
