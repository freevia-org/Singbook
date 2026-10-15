import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';

/// Regression tests for the R1 domain review (robustness, limits, data loss).
void main() {
  final codec = ChordProCodec();
  const bom = '﻿';

  String wrap(Map<String, dynamic> payload) {
    final data = base64Url
        .encode(utf8.encode(jsonEncode(payload)))
        .replaceAll('=', '');
    return '{title: T}\n{x_verse: 1 json-base64url 1}\n'
        '{x_verse_data: 1/1 $data}\n\nBody';
  }

  group('R1-01 chord regex', () {
    test('unterminated chord with a long digit run fails fast', () {
      final watch = Stopwatch()..start();
      final line = '[C${'1' * 60}!';
      expect(chordPattern.hasMatch(line), isFalse);
      expect(containsChords('Hello $line world'), isFalse);
      expect(lyricLines(line), [line]);
      expect(chordPattern.hasMatch('[Cadd${'9' * 80}!'), isFalse);
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('real chords still match', () {
      for (final chord in [
        'C',
        'F#m7b5',
        'Cmaj7',
        'Bb',
        'C/G',
        'G13',
        'Dsus4',
        'Cadd9',
        'C7(b9)',
        'C-7',
        'N.C.',
      ]) {
        expect(chordPattern.hasMatch('[$chord]'), isTrue, reason: chord);
      }
    });
  });

  group('R1-02/04/13/18 LRC', () {
    test('timestamps x word markers cannot explode', () {
      final watch = Stopwatch()..start();
      final tags = [for (var i = 0; i < 500; i++) '[00:${10 + i % 40}.00]'];
      final words = [for (var i = 0; i < 500; i++) '<00:01.00>w$i'];
      final track = parseLrc(
        '${tags.join()}${words.join(' ')}',
        sourceDocumentId: 'x',
      );
      expect(track.status, TimingStatus.invalid);
      expect(track.cues, isEmpty);
      expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
    });

    test('many word markers on one line are bounded and linear', () {
      final watch = Stopwatch()..start();
      final words = [for (var i = 0; i < 20000; i++) '<00:01.00>w$i'];
      final track = parseLrc(
        '[00:01.00]${words.join(' ')}',
        sourceDocumentId: 'x',
      );
      expect(track.cues.length, lessThanOrEqualTo(100000));
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('word grapheme offsets stay exact', () {
      final track = parseLrc(
        '[00:01.00]<00:01.00>a 👩🏽‍🎤 <00:02.00>bc',
        sourceDocumentId: 'x',
      );
      final words = track.cues.where((c) => c.graphemeStart != null).toList();
      expect(words.map((c) => (c.graphemeStart, c.graphemeEnd)), [
        (0, 3),
        (4, 6),
      ]);
    });

    test('a bracketed time inside the lyric text is text', () {
      final track = parseLrc(
        '[00:01.00]Meet me at [12:30] tonight',
        sourceDocumentId: 'x',
      );
      expect(track.sourceLyrics, 'Meet me at [12:30] tonight');
      expect(track.cues, hasLength(1));
      expect(track.cues.single.startUs, 1000000);
    });

    test('repeated leading timestamps still expand', () {
      final track = parseLrc(
        '[00:01.00][00:05.00]Chorus',
        sourceDocumentId: 'x',
      );
      expect(track.cues.map((c) => c.startUs), [1000000, 5000000]);
    });

    test('huge offset is clamped instead of overflowing', () {
      final track = parseLrc(
        '[offset:9223372036854775807]\n[00:01.00]a',
        sourceDocumentId: 'x',
      );
      expect(track.extra['offsetUs'], 86400000 * 1000);
      expect(track.extra['offsetUs'], isPositive);
    });
  });

  group('R1-04 TTML', () {
    test('many timed spans in one paragraph parse in linear time', () {
      final watch = Stopwatch()..start();
      final spans = [
        for (var i = 0; i < 16000; i++)
          '<span begin="${i ~/ 1000}.${i % 1000}s">w$i </span>',
      ].join();
      final track = parseTtml(
        '<tt xmlns="http://www.w3.org/ns/ttml"><body><div>'
        '<p begin="0s">$spans</p></div></body></tt>',
        sourceDocumentId: 'x',
      );
      expect(track.status, TimingStatus.unverified);
      expect(track.cues.length, greaterThan(16000));
      expect(watch.elapsed, lessThan(const Duration(seconds: 8)));
    });

    test('dur alone counts as timing', () {
      final track = parseTtml(
        '<tt xmlns="http://www.w3.org/ns/ttml"><body><div>'
        '<p dur="2s">Hello</p></div></body></tt>',
        sourceDocumentId: 'x',
      );
      expect(track.status, TimingStatus.unverified);
      expect(track.extra['parseError'], isNull);
    });

    test('profile and recording take part in the track id', () {
      const doc =
          '<tt xmlns="http://www.w3.org/ns/ttml"><body><div>'
          '<p begin="1s" end="2s">Hello</p></div></body></tt>';
      final a = parseTtml(doc, sourceDocumentId: 'x');
      final b = parseTtml(doc, sourceDocumentId: 'x', recordingId: 'r1');
      final c = parseTtml(doc, sourceDocumentId: 'x', profile: 'apple-lyrics');
      expect({a.id, b.id, c.id}, hasLength(3));
      expect(parseTtml(doc, sourceDocumentId: 'x').id, a.id);
    });
  });

  group('R1-03 timing validation keeps the document', () {
    const outOfRange = 604800000001; // just beyond the 7 day bound
    TimingTrack badTrack() => TimingTrack(
      id: 't:bad',
      sourceDocumentId: 't',
      sourceLyrics: 'Hello',
      format: 'ttml',
      raw: '<tt/>',
      status: TimingStatus.unverified,
      cues: const [
        TimingCue(
          id: 't:bad:0',
          occurrenceId: 'line-0',
          text: 'Hello',
          startUs: outOfRange,
        ),
      ],
    );

    test('TTML beyond the 7 day bound is rejected by the parser', () {
      final track = parseTtml(
        '<tt xmlns="http://www.w3.org/ns/ttml"><body><div>'
        '<p begin="200:00:00.000" end="200:00:05.000">Hi</p>'
        '</div></body></tt>',
        sourceDocumentId: 'x',
      );
      expect(track.status, TimingStatus.invalid);
      expect(track.cues, isEmpty);
      expect(track.raw, contains('200:00:00'));
    });

    test('out of range cues mark only the track invalid', () {
      final original = SongDocument(
        id: 'keep-me',
        title: 'T',
        artist: 'A',
        body: 'Hello',
        favorite: true,
        revision: 7,
        createdAt: DateTime.utc(2020, 1, 2),
        metadata: {'custom': 'x'},
        extra: {'future': 1},
        timingTracks: [badTrack()],
      );
      final decoded = codec.decode(codec.encode(original));
      expect(decoded.id, 'keep-me');
      expect(decoded.favorite, isTrue);
      expect(decoded.revision, 7);
      expect(decoded.createdAt, DateTime.utc(2020, 1, 2));
      expect(decoded.metadata['custom'], 'x');
      expect(decoded.extra['future'], 1);
      expect(decoded.extensionError, isNull);
      final track = decoded.timingTracks.single;
      expect(track.status, TimingStatus.invalid);
      expect(track.cues, isEmpty);
      expect(track.raw, '<tt/>');
      // It is readable again on the next round trip.
      final again = codec.decode(codec.encode(decoded));
      expect(again.id, 'keep-me');
      expect(again.extensionError, isNull);
    });

    test('structural damage still keeps id, favorite, metadata and extra', () {
      final dup = {
        'id': 't:1',
        'sourceDocumentId': 't',
        'sourceLyrics': '',
        'format': 'lrc',
        'cues': [],
      };
      final decoded = codec.decode(
        wrap({
          'schemaVersion': 1,
          'id': 'keep-me',
          'revision': 4,
          'favorite': true,
          'metadata': {'custom': 'x'},
          'future': 1,
          'timingTracks': [dup, dup],
        }),
      );
      expect(decoded.extensionError, isNotNull);
      expect(decoded.id, 'keep-me');
      expect(decoded.favorite, isTrue);
      expect(decoded.revision, 4);
      expect(decoded.metadata['custom'], 'x');
      expect(decoded.extra['future'], 1);
      expect(decoded.timingTracks, isEmpty);
      // The opaque block is still written back verbatim.
      expect(codec.encode(decoded), contains('{x_verse: 1 json-base64url 1}'));
    });
  });

  group('R1-14 staleness reaches source copies', () {
    test('an externally edited body stales source track copies', () {
      final track = parseLrc(
        '[00:01]Hello',
        sourceDocumentId: 'x:1',
      ).copyWith(status: TimingStatus.usable);
      final source = SourceResult(
        candidate: const SongCandidate(
          providerId: 'p',
          id: '1',
          title: 'T',
          artist: 'A',
        ),
        body: 'Hello',
        timingTracks: [track],
      );
      final original = SongDocument(
        id: 's',
        title: 'T',
        artist: 'A',
        body: 'Hello',
        sources: [source],
        timingTracks: [track],
        activeTimingTrackId: track.id,
      );
      final decoded = codec.decode(
        codec.encode(original).replaceFirst('\n\nHello', '\n\nHello again'),
      );
      expect(decoded.timingTracks.single.status, TimingStatus.stale);
      expect(
        decoded.sources.single.timingTracks.single.status,
        TimingStatus.stale,
      );
      expect(decoded.activeTimingTrackId, isNull);
    });
  });

  group('R1-05 parseArrangement', () {
    test('offsets are correct with escapes and emoji', () {
      final line = parseArrangement(r'ab[C]c\[d[G]👩🏽‍🎤[Am]x').single;
      expect(line.text, r'abc[d👩🏽‍🎤x');
      expect(line.chords.map((c) => (c.offset, c.chord)), [
        (2, 'C'),
        (5, 'G'),
        (6, 'Am'),
      ]);
    });

    test('a long single line is linear', () {
      final watch = Stopwatch()..start();
      final line = parseArrangement('[C]a' * 8000).single;
      expect(line.chords, hasLength(8000));
      expect(line.chords.last.offset, 7999);
      expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
    });
  });

  group('R1-06 oversize timing payloads', () {
    test('are rejected without retaining bytes and the song still saves', () {
      final bytes = List<int>.filled(4 * 1024 * 1024, 65);
      final track = parseTimingBytes(
        bytes,
        sourceDocumentId: 'big',
        format: 'lrc',
      );
      expect(track.status, TimingStatus.invalid);
      expect(track.extra['parseError'], contains('MiB'));
      expect(track.extra.containsKey('rawBytesBase64'), isFalse);
      expect(track.raw, isNull);
      final song = SongDocument(
        id: 's',
        title: 'T',
        artist: 'A',
        body: 'x',
        timingTracks: [track],
      );
      expect(() => codec.encode(song), returnsNormally);
    });

    test('a maximum size valid LRC still fits in a song file', () {
      final line = '[00:01.00]${'a' * 180}\n';
      final text = line * (2 * 1024 * 1024 ~/ line.length);
      final track = parseTimingBytes(
        utf8.encode(text),
        sourceDocumentId: 'big',
        format: 'lrc',
      );
      final song = SongDocument(
        id: 's',
        title: 'T',
        artist: 'A',
        body: 'x',
        timingTracks: [track],
      );
      expect(() => codec.encode(song), returnsNormally);
    });
  });

  group('R1-07 expansion limit', () {
    test('many references to one asset are refused', () {
      final text = 'a' * (1024 * 1024);
      final bytes = utf8.encode(text);
      final hash = sha256.convert(bytes).toString();
      final tracks = [
        for (var i = 0; i < 64; i++)
          {
            'id': 't:$i',
            'sourceDocumentId': 't',
            'sourceLyrics': '',
            'format': 'lrc',
            'rawRef': hash,
            'cues': [],
          },
      ];
      final watch = Stopwatch()..start();
      final decoded = codec.decode(
        wrap({
          'schemaVersion': 1,
          'id': 's',
          'revision': 1,
          'timingTracks': tracks,
          'rawAssets': {
            hash: {
              'encoding': 'base64',
              'contentType': 'text/plain',
              'bytes': base64.encode(bytes),
            },
          },
        }),
      );
      expect(decoded.extensionError, isNotNull);
      expect(decoded.timingTracks, isEmpty);
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('a few references still decode', () {
      final bytes = utf8.encode('[00:01]Hello');
      final hash = sha256.convert(bytes).toString();
      final decoded = codec.decode(
        wrap({
          'schemaVersion': 1,
          'id': 's',
          'revision': 1,
          'timingTracks': [
            for (var i = 0; i < 3; i++)
              {
                'id': 't:$i',
                'sourceDocumentId': 't',
                'sourceLyrics': '',
                'format': 'lrc',
                'rawRef': hash,
                'cues': [],
              },
          ],
          'rawAssets': {
            hash: {
              'encoding': 'base64',
              'contentType': 'text/plain',
              'bytes': base64.encode(bytes),
            },
          },
        }),
      );
      expect(decoded.extensionError, isNull);
      expect(
        decoded.timingTracks.map((t) => t.raw),
        everyElement('[00:01]Hello'),
      );
    });
  });

  group('R1-08 edition qualifiers in titles', () {
    const selected = SongCandidate(
      providerId: 'genius',
      id: '1',
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
    );
    for (final title in [
      'Bohemian Rhapsody (Remastered 2011)',
      'Bohemian Rhapsody - Remastered 2011',
      'Bohemian Rhapsody - Live',
      'Bohemian Rhapsody - 2011 Mix',
      'Bohemian Rhapsody – Remastered',
    ]) {
      test('"$title" matches the base song', () {
        final result = combineSources(selected, [
          SourceResult(
            candidate: SongCandidate(
              providerId: 'p',
              id: '2',
              title: title,
              artist: 'Queen',
            ),
            body: 'Is this the real life',
            matchKind: MatchKind.sameSong,
          ),
        ]);
        expect(result.body, 'Is this the real life');
      });
    }

    test('different songs are still different', () {
      expect(
        () => combineSources(selected, [
          SourceResult(
            candidate: const SongCandidate(
              providerId: 'p',
              id: '2',
              title: 'Bohemian Rhapsody Part Two',
              artist: 'Queen',
            ),
            body: 'x',
            matchKind: MatchKind.sameSong,
          ),
        ]),
        throwsFormatException,
      );
    });
  });

  group('R1-19 byte order mark', () {
    test('only a leading BOM is removed from a song file', () {
      final withBom = codec.decode('$bom{title: T}\n\nA${bom}B');
      expect(withBom.title, 'T');
      expect(withBom.body, 'A${bom}B');
      final inner = codec.decode('{title: T}\n\nA${bom}B');
      expect(inner.body, 'A${bom}B');
    });

    test('only a leading BOM is removed from timing bytes', () {
      final bytes = utf8.encode('[00:01.00]A${bom}B');
      final track = parseTimingBytes(
        bytes,
        sourceDocumentId: 'x',
        format: 'lrc',
      );
      expect(track.sourceLyrics, 'A${bom}B');
    });
  });

  group('R1-21 transposition', () {
    test('directive lines are left alone', () {
      final out = transposeBody(
        '{comment: Capo [D] shape}\n[C]Hello [G]world',
        2,
      );
      expect(out, '{comment: Capo [D] shape}\n[D]Hello [A]world');
    });
  });

  group('R1-11 encode limit', () {
    test('a body that decode would refuse is refused on save', () {
      final song = SongDocument(
        id: 's',
        title: 'T',
        artist: 'A',
        body: 'x' * (25 * 1024 * 1024),
      );
      expect(() => codec.encode(song), throwsFormatException);
    });
  });
}
