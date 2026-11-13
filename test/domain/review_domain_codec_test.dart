import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';

/// SHA-256 of the file [_song] encoded to before the review changes. The
/// persisted `x_verse` payload must stay byte-identical.
const _goldenEncodingHash =
    'bb3e2df242df82d70710135e6d414b33b2b748595576467eded755690dd8c9a4';

SongDocument _song() {
  final lrc = parseLrc(
    '[offset:+100]\n'
    '[00:01.00]<00:01.00>Hello <00:01.50>world\n'
    '[00:03.00][00:09.00]Second line\n'
    '[00:05.25]Ünïcode 👍🏽 line',
    sourceDocumentId: 'lrclib:42',
    recordingId: 'rec-1',
  );
  final ttml = parseTtml(
    '<tt xmlns="http://www.w3.org/ns/ttml"><body><div>'
    '<p begin="1s" end="2s">Hello world</p>'
    '<p begin="3s" end="4s"><span begin="3s" end="3.5s">Second</span> '
    '<span begin="3.5s" end="4s">line</span></p>'
    '</div></body></tt>',
    sourceDocumentId: 'file:ttml',
  );
  const candidate = SongCandidate(
    providerId: 'lrclib',
    id: '42',
    title: 'Hello',
    artist: 'Someone',
    album: 'Greetings',
    durationSeconds: 12.5,
    metadata: {'artworkUrl': 'https://example.org/a.jpg'},
    recordingIds: {'isrc': 'X1'},
    extra: {'identityScope': 'recording'},
  );
  return SongDocument(
    id: 'song-1',
    title: 'Hello',
    artist: 'Someone',
    body: '{start_of_verse}\n[C]Hello [G]world\nSecond line\n{end_of_verse}',
    metadata: {'album': 'Greetings', 'capo': 2, 'label': 'Indie'},
    favorite: true,
    selectedRecording: candidate,
    activeTimingTrackId: lrc.id,
    revision: 7,
    createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
    updatedAt: DateTime.utc(2026, 5, 6, 7, 8, 9),
    timingTracks: [
      lrc.copyWith(status: TimingStatus.usable),
      ttml,
    ],
    sources: [
      SourceResult(
        candidate: candidate,
        body: 'Hello world\nSecond line',
        metadata: {'album': 'Greetings'},
        timingTracks: [lrc.copyWith(status: TimingStatus.usable)],
        matchKind: MatchKind.sameRecording,
        attribution: 'LRCLIB',
        retrievedAt: DateTime.utc(2026, 2, 3, 4, 5, 6),
        extra: {'note': 'kept'},
      ),
      const SourceResult(
        candidate: SongCandidate(
          providerId: 'chords',
          id: '/c/1',
          title: 'Hello',
          artist: 'Someone',
        ),
        body: '[C]Hello [G]world',
        matchKind: MatchKind.rejected,
        matchReason: 'incomplete_or_different_lyrics',
      ),
    ],
    extra: {
      'selectedSourceId': 'lrclib:42',
      'chordSourceIds': ['chords:/c/1'],
      'fieldOrigins': {'album': 'lrclib:42'},
    },
  );
}

/// The decoded `x_verse` JSON of [document] and a function writing an edited
/// copy back in the codec's own chunked layout.
(Map<String, dynamic>, String Function(Map<String, dynamic>)) _payload(
  String document,
) {
  final lines = document.split('\n');
  final chunk = RegExp(r'^\{x_verse_data: \d+/\d+ (.+)\}$');
  final encoded = lines
      .map((line) => chunk.firstMatch(line)?.group(1))
      .nonNulls
      .join();
  final json =
      jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(encoded))))
          as Map<String, dynamic>;
  String rebuild(Map<String, dynamic> edited) {
    final text = base64Url
        .encode(utf8.encode(jsonEncode(edited)))
        .replaceAll('=', '');
    final count = (text.length / ChordProCodec.chunkSize).ceil();
    final rest = lines.where((line) => !line.startsWith('{x_verse')).toList();
    final blank = rest.indexOf('');
    return [
      ...rest.take(blank),
      '{x_verse: 1 json-base64url $count}',
      for (var i = 0; i < count; i++)
        '{x_verse_data: ${i + 1}/$count ${text.substring(i * ChordProCodec.chunkSize, i + 1 == count ? text.length : (i + 1) * ChordProCodec.chunkSize)}}',
      ...rest.skip(blank),
    ].join('\n');
  }

  return (json, rebuild);
}

void main() {
  final codec = ChordProCodec();

  test('the encoded song file is byte-identical to the reviewed format', () {
    final encoded = codec.encode(_song());
    expect(
      sha256.convert(utf8.encode(encoded)).toString(),
      _goldenEncodingHash,
    );
  });

  test('decode then encode keeps every saved value', () {
    final encoded = codec.encode(_song());
    final decoded = codec.decode(encoded);
    expect(decoded.extensionError, isNull);
    // A reloaded song lists its raw assets first, as it always has; the
    // values are the same and a second round trip is byte-identical.
    final again = codec.encode(decoded);
    expect(_payload(again).$1, _payload(encoded).$1);
    List<String> outside(String file) => [
      for (final line in file.split('\n'))
        if (!line.startsWith('{x_verse')) line,
    ];
    expect(outside(again), outside(encoded));
    expect(codec.encode(codec.decode(again)), again);
    expect(decoded.activeTimingTrackId, _song().activeTimingTrackId);
    expect(decoded.timingTracks, hasLength(2));
    expect(decoded.timingTracks.first.cues, isNotEmpty);
    expect(decoded.sources.first.extra, {'note': 'kept'});
    expect(
      decoded.sources.first.retrievedAt,
      DateTime.utc(2026, 2, 3, 4, 5, 6),
    );
  });

  test('a source shares the parsed track instead of a second copy', () {
    final decoded = codec.decode(codec.encode(_song()));
    final own = decoded.timingTracks.first;
    final shared = decoded.sources.first.timingTracks.single;
    expect(identical(shared, own), isTrue);
    expect(jsonEncode(shared.toJson()), jsonEncode(own.toJson()));
    expect(decoded.sources.last.timingTracks, isEmpty);
  });

  test('a body edit still marks the shared source track stale', () {
    final encoded = codec.encode(_song());
    final decoded = codec.decode('$encoded\nAn added line');
    expect(decoded.timingTracks.first.status, TimingStatus.stale);
    expect(
      decoded.sources.first.timingTracks.single.status,
      TimingStatus.stale,
    );
    expect(decoded.activeTimingTrackId, isNull);
  });

  test('a source naming a missing track is still structural damage', () {
    final (json, rebuild) = _payload(codec.encode(_song()));
    ((json['sources'] as List).first as Map)['timingTrackIds'] = ['missing'];
    final decoded = codec.decode(rebuild(json));
    expect(decoded.extensionError, isNotNull);
    expect(decoded.sources, isEmpty);
    expect(decoded.timingTracks, isEmpty);
    expect(decoded.preservedExtensions, isNotEmpty);
  });

  test('an unreadable retrievedAt no longer discards sources and timing', () {
    final (json, rebuild) = _payload(codec.encode(_song()));
    ((json['sources'] as List).first as Map)['retrievedAt'] = 'not a date';
    final decoded = codec.decode(rebuild(json));
    expect(decoded.extensionError, isNull);
    expect(decoded.sources, hasLength(2));
    expect(decoded.sources.first.retrievedAt, isNull);
    expect(decoded.timingTracks, hasLength(2));
    expect(decoded.timingTracks.first.status, TimingStatus.usable);
  });

  test('the cue limits are the ones the parser enforces', () {
    expect(maxCueUs, 7 * 24 * 3600 * 1000000);
    final (json, rebuild) = _payload(codec.encode(_song()));
    final cues = ((json['timingTracks'] as List).first as Map)['cues'] as List;
    (cues.last as Map)['startUs'] = maxCueUs + 1;
    final decoded = codec.decode(rebuild(json));
    expect(decoded.extensionError, isNull);
    expect(decoded.timingTracks.first.status, TimingStatus.invalid);
    expect(decoded.timingTracks.first.cues, isEmpty);
    expect(decoded.timingTracks.last.cues, isNotEmpty);
  });
}
