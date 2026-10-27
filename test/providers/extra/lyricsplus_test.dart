import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/providers/extra/lyricsplus.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/core/service.dart';

Map<String, dynamic> _catalogRow({
  String title = 'Example',
  String artist = 'Fixture Artist',
  String album = 'Catalog Album',
}) => {
  'id': {'deezer': '42'},
  'sourceId': '42',
  'title': title,
  'artist': artist,
  'album': album,
  'durationMs': 238000,
  'isrc': 'GBXXX1200001',
  'availability': ['Deezer'],
  'externalUrls': {'deezer': 'https://www.deezer.com/track/42'},
  'unrecognizedFact': {'keep': true},
};

Map<String, dynamic> _word(String text, int time, int duration) => {
  'text': text,
  'time': time,
  'duration': duration,
};

Map<String, dynamic> _line({
  String text = 'Synthetic words',
  int time = 1000,
  int duration = 2000,
  List<Map<String, dynamic>>? words,
}) => {
  'text': text,
  'time': time,
  'duration': duration,
  'syllabus':
      words ??
      [
        _word('Synthetic ', time, 800),
        _word('words', time + 800, duration - 800),
      ],
  'element': {'key': 'L1', 'singer': 'v1', 'songPartIndex': 0},
  'translation': {'lang': 'bg', 'text': 'Синтетичен текст'},
  'transliteration': {'lang': 'en', 'text': 'Synthetic transliteration'},
};

Map<String, dynamic> _payload({
  String title = 'Example',
  String artist = 'Fixture Artist',
  String album = 'Catalog Album',
  String sourceId = '12345',
  String source = 'Apple',
  List<Map<String, dynamic>>? lines,
}) => {
  'type': 'Word',
  'KpoeTools': 'synthetic-fixture',
  'metadata': {
    'source': source,
    'language': 'en',
    'totalDuration': '3:58.640',
    'songWriters': ['Fixture Writer'],
    'agents': {
      'v1': {'type': 'person', 'name': artist, 'alias': 'v1'},
    },
    'songParts': [
      {'name': 'Verse', 'time': 1000, 'duration': 2000},
    ],
  },
  'lyrics': lines ?? [_line()],
  'cached': 'Database',
  'processingTime': {
    'winnerSource': source.toLowerCase(),
    'selectedSongMetadata': {
      'source': source,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': 238.64,
      'songISRC': 'GBXXX1200001',
      'songPlatformId': sourceId,
    },
  },
};

Map<String, dynamic> _apple({
  String title = 'Example',
  String artist = 'Fixture Artist',
  String album = 'Actual Apple Album',
  int id = 12345,
  int duration = 238640,
}) => {
  'wrapperType': 'track',
  'kind': 'song',
  'trackId': id,
  'trackName': title,
  'artistName': artist,
  'collectionName': album,
  'trackTimeMillis': duration,
  'trackViewUrl': 'https://music.apple.com/us/album/example/111?i=$id',
  'artworkUrl100': 'https://is1-ssl.mzstatic.com/image/thumb/fixture/100.jpg',
  'country': 'USA',
  'primaryGenreName': 'Fixture',
  'releaseDate': '2020-01-01T00:00:00Z',
  'trackNumber': 3,
};

class _Harness {
  _Harness({
    List<Map<String, dynamic>>? rows,
    JsonMap? payload,
    JsonMap? apple,
  }) {
    catalog = rows ?? [_catalogRow()];
    lyrics = payload ?? _payload();
    actualApple = apple ?? _apple();
    transport = ProviderTransport(
      client: MockClient((request) async {
        requests.add(request);
        final Object data;
        if (request.url.host == 'lyricsplus.prjktla.my.id' &&
            request.url.path == '/v1/songlist/search') {
          data = {'results': catalog};
        } else if (request.url.host == 'lyricsplus.prjktla.my.id' &&
            request.url.path == '/v2/lyrics/get') {
          data = lyrics;
        } else if (request.url.host == 'itunes.apple.com' &&
            request.url.path == '/lookup') {
          data = {
            'resultCount': 1,
            'results': [actualApple],
          };
        } else {
          return http.Response('unexpected route', 404);
        }
        return http.Response.bytes(
          utf8.encode(jsonEncode(data)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    provider = LyricsPlusProvider(transport);
  }
  late List<Map<String, dynamic>> catalog;
  late JsonMap lyrics, actualApple;
  late ProviderTransport transport;
  late LyricsPlusProvider provider;
  final requests = <http.Request>[];
  Future<SongCandidate> selected() async =>
      (await provider.search('Example Fixture Artist')).first;
  Future<void> close() => transport.close();
}

final _identityFailure = throwsA(
  isA<ProviderException>().having((e) => e.code, 'code', 'identity_mismatch'),
);
final _timingFailure = throwsA(
  isA<ProviderException>().having(
    (e) => e.message,
    'message',
    'unsupported_timing',
  ),
);

void main() {
  test(
    'normal discovery accepts searched lyric documents without recording or timing authority',
    () async {
      const lyrics =
          'Copper lanterns shimmer across quiet water while distant mountain '
          'echoes carry another gentle melody home';
      final tokens = lyrics.split(' ');
      final h = _Harness(
        payload: _payload(
          lines: [
            _line(
              text: lyrics,
              words: [
                for (var i = 0; i < tokens.length; i++)
                  _word(
                    '${tokens[i]}${i == tokens.length - 1 ? '' : ' '}',
                    1000 + i * 100,
                    100,
                  ),
              ],
            ),
          ],
        ),
      );
      addTearDown(h.close);
      final selected = (await h.provider.search(
        'Example Fixture Artist',
      )).single;
      final checks = <ProviderCheck>[];
      final results = await SourceDiscoveryService([
        h.provider,
      ]).discover(selected, enabledIds: {'lyricsplus'}, onProgress: checks.add);
      expect(results, hasLength(1));
      final result = results.single;
      expect(result.id, selected.identity);
      expect(result.matchKind, MatchKind.sameSong);
      expect(result.body, lyrics);
      expect(result.candidate.recordingIds, isEmpty);
      expect(result.metadata['identityScope'], 'arrangement');
      expect(result.candidate.album, 'Actual Apple Album');
      expect(result.metadata['appleMusicIds'], ['12345']);
      expect(
        result.extra['lyricsplus']['catalogRows'][0]['album'],
        'Catalog Album',
      );
      expect(
        result.extra['lyricsplus']['catalogRows'][0]['isrc'],
        'GBXXX1200001',
      );
      expect(result.metadata.containsKey('isrc'), isFalse);
      final track = result.timingTracks.single;
      expect(track.status, TimingStatus.unverified);
      expect(track.recordingId, isNull);
      expect(track.extra['recordingEvidence'], 'sourceDemonstrationOnly');
      expect(track.sourceLyrics, lyrics);
      expect(
        track.cues.where((cue) => cue.graphemeStart != null),
        hasLength(tokens.length),
      );
      expect(checks.last.state, 'found');
      expect(checks.last.code, isNull);
      expect(checks.last.result?.id, selected.identity);
      expect(h.requests, hasLength(3));
    },
  );

  test(
    'search groups exact lyric identities and retains every catalog fact',
    () async {
      final first = _catalogRow();
      final second = _catalogRow(album: 'Other Catalog Album');
      final h = _Harness(
        rows: [
          first,
          second,
          _catalogRow(artist: 'Different Artist'),
        ],
      );
      addTearDown(h.close);
      final found = await h.provider.search('Example');
      expect(found, hasLength(2));
      expect(found.first.metadata['identityScope'], 'arrangement');
      expect(found.first.album, isNull);
      expect(found.first.durationSeconds, isNull);
      expect(found.first.recordingIds, isEmpty);
      expect(found.first.extra['lyricsplus']['catalogRows'], [first, second]);
      expect(found.first.id, startsWith('work-'));
      expect(h.requests.single.url.queryParameters, {'q': 'Example'});
    },
  );

  test(
    'resolution verifies an unsupplied Apple ID without promoting echoed IDs',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      final selected = await h.selected();
      final result = await h.provider.resolve(selected);
      expect(h.requests[1].url.queryParameters, {
        'title': 'Example',
        'artist': 'Fixture Artist',
      });
      expect(h.requests[2].url.host, 'itunes.apple.com');
      expect(h.requests[2].url.queryParameters, {
        'id': '12345',
        'country': 'US',
        'entity': 'song',
      });
      expect(result.candidate.id, selected.id);
      expect(result.candidate.album, 'Actual Apple Album');
      expect(result.candidate.durationSeconds, 238.64);
      expect(result.candidate.recordingIds, isEmpty);
      expect(result.matchKind, MatchKind.unverified);
      expect(result.metadata['identityScope'], 'arrangement');
      expect(result.metadata['appleMusicIds'], ['12345']);
      expect(result.metadata.containsKey('isrc'), isFalse);
      expect(
        result.extra['lyricsplus']['claimedSelectedSongMetadata']['songISRC'],
        'GBXXX1200001',
      );
      expect(
        result.extra['lyricsplus']['catalogRows'][0]['album'],
        'Catalog Album',
      );
      expect(result.timingTracks.single.status, TimingStatus.unverified);
      expect(result.timingTracks.single.recordingId, isNull);
      expect(
        result.timingTracks.single.extra['recordingEvidence'],
        'sourceDemonstrationOnly',
      );
      expect(result.extra['rights']['license'], 'unknown');
    },
  );

  test(
    'Billie Jean album mismatch is preserved as provenance, never rewritten as Deezer recording',
    () async {
      final h = _Harness(
        rows: [
          _catalogRow(
            title: 'Billie Jean',
            artist: 'Michael Jackson',
            album: "Michael Jackson's This Is It",
          ),
        ],
        payload: _payload(
          title: 'Billie Jean',
          artist: 'Michael Jackson',
          album: "Michael Jackson's This Is It",
          sourceId: '1883770432',
        ),
        apple: _apple(
          title: 'Billie Jean',
          artist: 'Michael Jackson',
          album: 'Michael: Songs From The Motion Picture',
          id: 1883770432,
        ),
      );
      addTearDown(h.close);
      final result = await h.provider.resolve(await h.selected());
      expect(result.candidate.album, 'Michael: Songs From The Motion Picture');
      expect(
        result.extra['lyricsplus']['catalogRows'][0]['album'],
        "Michael Jackson's This Is It",
      );
      expect(result.candidate.recordingIds, isEmpty);
      expect(result.matchKind, isNot(MatchKind.sameRecording));
    },
  );

  test(
    'Creep independently verified Apple metadata stays arrangement scoped',
    () async {
      final h = _Harness(
        rows: [
          _catalogRow(
            title: 'Creep',
            artist: 'Radiohead',
            album: 'Pablo Honey',
          ),
        ],
        payload: _payload(
          title: 'Creep',
          artist: 'Radiohead',
          album: 'Pablo Honey',
          sourceId: '1097862231',
        ),
        apple: _apple(
          title: 'Creep',
          artist: 'Radiohead',
          album: 'Pablo Honey',
          id: 1097862231,
        ),
      );
      addTearDown(h.close);
      final result = await h.provider.resolve(await h.selected());
      expect(result.candidate.album, 'Pablo Honey');
      expect(result.candidate.durationSeconds, 238.64);
      expect(result.metadata['appleMusicIds'], ['1097862231']);
      expect(result.candidate.recordingIds, isEmpty);
    },
  );

  test(
    'query echoes cannot rescue the wrong independently returned artist',
    () async {
      final h = _Harness(apple: _apple(artist: 'Someone Else'));
      addTearDown(h.close);
      await expectLater(
        h.provider.resolve(await h.selected()),
        _identityFailure,
      );
    },
  );

  test('a queried album constraint cannot be silently replaced', () async {
    final h = _Harness();
    addTearDown(h.close);
    final selected = await h.selected();
    final constrained = SongCandidate.fromJson({
      ...selected.toJson(),
      'album': 'Incompatible Selected Album',
    });
    await expectLater(h.provider.resolve(constrained), _identityFailure);
  });

  test(
    'an explicit studio winner cannot satisfy a conflicting live edition',
    () async {
      // A fresh provider is essential: changing an HTTP fixture after its
      // Apple ID has been cached cannot change the already verified source.
      final h = _Harness(
        rows: [_catalogRow(title: 'Example (Studio)')],
        payload: _payload(title: 'Example (Studio)'),
        apple: _apple(title: 'Example (Studio)'),
      );
      addTearDown(h.close);
      final selected = await h.selected();
      final edition = SongCandidate.fromJson({
        ...selected.toJson(),
        'metadata': {...selected.metadata, 'edition': 'live'},
      });
      await expectLater(h.provider.resolve(edition), _identityFailure);
    },
  );

  test(
    'missing or unsupported winning-source identity is explicitly unavailable',
    () async {
      final h = _Harness(payload: _payload(source: 'QQ'));
      addTearDown(h.close);
      await expectLater(
        h.provider.resolve(await h.selected()),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'unavailable'),
        ),
      );
      expect(
        h.requests.where((r) => r.url.host == 'itunes.apple.com'),
        isEmpty,
      );
    },
  );

  test(
    'missing winning-source ID cannot fall back to a request ISRC or catalog ID',
    () async {
      final h = _Harness(payload: _payload(sourceId: ''));
      addTearDown(h.close);
      await expectLater(
        h.provider.resolve(await h.selected()),
        throwsA(isA<ProviderException>()),
      );
      expect(
        h.requests.where((r) => r.url.host == 'itunes.apple.com'),
        isEmpty,
      );
    },
  );

  test(
    'independent Apple lookup must return the exact requested source ID',
    () async {
      final h = _Harness(apple: _apple(id: 99999));
      addTearDown(h.close);
      await expectLater(
        h.provider.resolve(await h.selected()),
        _identityFailure,
      );
    },
  );

  test(
    'successful document and official metadata lookups are reused without HTTP repeats',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      final selected = await h.selected();
      final first = await h.provider.resolve(selected);
      expect(identical(await h.provider.resolve(selected), first), isTrue);
      expect(h.requests, hasLength(3));
    },
  );

  test('cancelled requests do not return a cached source', () async {
    final h = _Harness();
    addTearDown(h.close);
    final selected = await h.selected();
    await h.provider.resolve(selected);
    final token = CancellationToken()..cancel();
    await expectLater(
      h.provider.resolve(selected, cancel: token),
      throwsA(
        isA<ProviderException>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
    expect(h.requests, hasLength(3));
  });

  test('V2 retains exact bytes, word spans, singer, parts and extensions', () {
    final line = _line();
    line['syllabus'][1]['isBackground'] = true;
    line['syllabus'][1]['synthetic'] = true;
    final bytes = utf8.encode(jsonEncode(_payload(lines: [line])));
    final track = parseLyricsPlusV2(
      bytes,
      sourceDocumentId: 'test:1',
      sourceDurationMs: 238640,
    );
    expect(base64Decode(track.extra['rawBytesBase64']), bytes);
    expect(track.sourceLyrics, 'Synthetic words');
    expect(track.granularity, 'word');
    expect(track.cues, hasLength(3));
    expect(track.cues.first.startUs, 1000000);
    expect(track.cues.first.endUs, 3000000);
    expect(track.cues.first.voice, 'v1');
    expect(
      track.cues.first.extra['lyricsplus']['translation'],
      line['translation'],
    );
    expect(
      track.cues.first.extra['lyricsplus']['transliteration'],
      line['transliteration'],
    );
    expect(track.cues.last.graphemeStart, 10);
    expect(track.cues.last.graphemeEnd, 15);
    expect(track.cues.last.extra['background'], isTrue);
    expect(track.cues.last.extra['synthetic'], isTrue);
    expect(track.extra['metadata']['songParts'], isNotEmpty);
  });

  test(
    'overlapping lines retain separate occurrences and original source times',
    () {
      final bytes = utf8.encode(
        jsonEncode(_payload(lines: [_line(), _line(time: 2000)])),
      );
      final track = parseLyricsPlusV2(
        bytes,
        sourceDocumentId: 'test:1',
        sourceDurationMs: 238640,
      );
      final lines = track.cues
          .where((cue) => cue.graphemeStart == null)
          .toList();
      expect(lines[0].endUs, greaterThan(lines[1].startUs));
      expect(lines.map((cue) => cue.occurrenceId), ['line-0', 'line-1']);
      expect(track.sourceLyrics, 'Synthetic words\nSynthetic words');
    },
  );

  test(
    'overlapping source timing and raw provenance survive ChordPro round trip',
    () async {
      final h = _Harness(
        payload: _payload(lines: [_line(duration: 4000), _line(time: 2000)]),
      );
      addTearDown(h.close);
      final result = await h.provider.resolve(await h.selected());
      final document = SongDocument(
        id: 'fixture',
        title: result.candidate.title,
        artist: result.candidate.artist,
        body: result.body,
        sources: [result],
        timingTracks: result.timingTracks,
        metadata: result.metadata,
      );
      final codec = ChordProCodec();
      final restored = codec.decode(codec.encode(document));
      expect(restored.extensionError, isNull);
      expect(restored.timingTracks.single.status, TimingStatus.unverified);
      expect(
        restored.timingTracks.single.cues.map((c) => c.toJson()),
        result.timingTracks.single.cues.map((c) => c.toJson()),
      );
      expect(
        restored.sources.single.extra['originalPayload'],
        result.extra['originalPayload'],
      );
      expect(restored.sources.single.candidate.recordingIds, isEmpty);
    },
  );

  test('Unicode word spans use graphemes while preserving whitespace', () {
    final line = _line(
      text: ' 🧑🏽‍🎤 song ',
      words: [
        _word(' ', 1000, 200),
        _word('🧑🏽‍🎤 ', 1200, 800),
        _word('song ', 2000, 1000),
      ],
    );
    final track = parseLyricsPlusV2(
      utf8.encode(jsonEncode(_payload(lines: [line]))),
      sourceDocumentId: 'test:1',
      sourceDurationMs: 238640,
    );
    expect(track.sourceLyrics, ' 🧑🏽‍🎤 song ');
    expect(track.cues[2].graphemeStart, 1);
    expect(track.cues[2].graphemeEnd, 3);
  });

  Map<String, dynamic> interleavedBackground() => _line(
    text: 'Lead main back echo tail',
    words: [
      _word('Lead ', 1000, 300),
      _word('main ', 2000, 300),
      {..._word('back ', 1500, 200), 'isBackground': true},
      {..._word('echo ', 1700, 200), 'isBackground': true},
      _word('tail', 2600, 300),
    ],
  );

  test(
    'background syllables may start earlier than preceding main lyric text',
    () {
      final bytes = utf8.encode(
        jsonEncode(_payload(lines: [interleavedBackground()])),
      );
      final track = parseLyricsPlusV2(
        bytes,
        sourceDocumentId: 'test:background',
        sourceDurationMs: 238640,
      );
      expect(track.sourceLyrics, 'Lead main back echo tail');
      expect(base64Decode(track.extra['rawBytesBase64']), bytes);
      final main = track.cues.singleWhere((cue) => cue.id == 'line-0:word-1');
      final background = track.cues.singleWhere(
        (cue) => cue.id == 'line-0:word-2',
      );
      expect(background.startUs, 1500000);
      expect(background.startUs, lessThan(main.startUs));
      expect(background.graphemeStart, 10);
      expect(background.graphemeEnd, 15);
      expect(background.extra['background'], isTrue);
      expect(background.extra['lyricsplus']['isBackground'], isTrue);
      expect(
        track.cues.indexOf(background),
        lessThan(track.cues.indexOf(main)),
      );
      expect(track.cues.last.graphemeEnd, 24);
    },
  );

  for (final failure in [
    'mainBackstep',
    'backgroundBackstep',
    'malformedFlag',
  ]) {
    test('interleaved layers still reject $failure', () {
      final line = interleavedBackground();
      final words = line['syllabus'] as List;
      switch (failure) {
        case 'mainBackstep':
          words[4]['time'] = 1900;
        case 'backgroundBackstep':
          words[3]['time'] = 1400;
        case 'malformedFlag':
          words[2]['isBackground'] = 'true';
      }
      expect(
        () => parseLyricsPlusV2(
          utf8.encode(jsonEncode(_payload(lines: [line]))),
          sourceDocumentId: 'test:background-invalid',
          sourceDurationMs: 238640,
        ),
        _timingFailure,
      );
    });
  }

  for (final kind in [
    'negative',
    'fractional',
    'outside',
    'textMismatch',
    'wrongDuration',
    'outOfOrder',
  ]) {
    test('V2 rejects $kind timing without fabricating a replacement', () {
      final payload = _payload();
      final line = payload['lyrics'][0];
      switch (kind) {
        case 'negative':
          line['time'] = -1;
        case 'fractional':
          line['time'] = 1.25;
        case 'outside':
          line['syllabus'][0]['time'] = 0;
        case 'textMismatch':
          line['syllabus'][0]['text'] = 'Other ';
        case 'wrongDuration':
          payload['metadata']['totalDuration'] = '9:59.000';
        case 'outOfOrder':
          payload['lyrics'].add(_line(time: 500));
      }
      expect(
        () => parseLyricsPlusV2(
          utf8.encode(jsonEncode(payload)),
          sourceDocumentId: 'test:1',
          sourceDurationMs: 238640,
        ),
        _timingFailure,
      );
    });
  }

  test('line-only data does not invent word segments', () {
    final payload = _payload();
    payload['type'] = 'Line';
    payload['lyrics'][0].remove('syllabus');
    final track = parseLyricsPlusV2(
      utf8.encode(jsonEncode(payload)),
      sourceDocumentId: 'test:1',
      sourceDurationMs: 238640,
    );
    expect(track.granularity, 'line');
    expect(track.cues, hasLength(1));
    expect(track.cues.single.graphemeStart, isNull);
  });

  test('oversized clock minutes produce a typed provider error', () {
    final payload = _payload();
    payload['metadata']['totalDuration'] =
        '${List.filled(10000, '9').join()}:00.000';
    expect(
      () => parseLyricsPlusV2(
        utf8.encode(jsonEncode(payload)),
        sourceDocumentId: 'test:oversized-clock',
        sourceDurationMs: 238640,
      ),
      throwsA(
        isA<ProviderException>()
            .having((e) => e.code, 'code', 'invalid_response')
            .having((e) => e.message, 'message', 'unsupported_timing'),
      ),
    );
  });

  test(
    'the 24-hour clock boundary is valid but an extra millisecond is not',
    () {
      final payload = _payload();
      payload['metadata']['totalDuration'] = '1440:00.000';
      final track = parseLyricsPlusV2(
        utf8.encode(jsonEncode(payload)),
        sourceDocumentId: 'test:maximum-clock',
        sourceDurationMs: 86400000,
      );
      expect(track.sourceLyrics, 'Synthetic words');
      expect(track.cues, hasLength(3));
      payload['metadata']['totalDuration'] = '1440:00.001';
      expect(
        () => parseLyricsPlusV2(
          utf8.encode(jsonEncode(payload)),
          sourceDocumentId: 'test:clock-over-limit',
          sourceDurationMs: 86400000,
        ),
        _timingFailure,
      );
    },
  );

  test(
    'documented None type preserves plain lyrics without inventing timing',
    () {
      final payload = _payload();
      payload['type'] = 'None';
      payload['lyrics'] = [
        {'text': 'Synthetic plain lyric'},
      ];
      final track = parseLyricsPlusV2(
        utf8.encode(jsonEncode(payload)),
        sourceDocumentId: 'test:plain',
        sourceDurationMs: 238640,
      );
      expect(track.sourceLyrics, 'Synthetic plain lyric');
      expect(track.status, TimingStatus.unsupported);
      expect(track.cues, isEmpty);
      expect(track.extra['timingAvailability'], 'none');
    },
  );
}
