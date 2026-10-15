import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';

void main() {
  final codec = ChordProCodec();
  SongDocument song({
    String body = 'Hello',
    List<TimingTrack> tracks = const [],
    JsonMap extra = const {},
    JsonMap metadata = const {},
  }) => SongDocument(
    id: 's',
    title: 'T',
    artist: 'A',
    body: body,
    timingTracks: tracks,
    extra: extra,
    metadata: metadata,
  );

  group('LRC', () {
    test('positive offset shifts earlier and negative results clamp to 0', () {
      final shifted = parseLrc(
        '[offset:500]\n[00:01]a\n[00:00.2]b',
        sourceDocumentId: 'x',
      );
      expect(shifted.status, isNot(TimingStatus.invalid));
      expect(shifted.cues.map((c) => c.startUs), [0, 500000]);
    });

    test('equal timestamps keep source order beyond 32 cues', () {
      final raw = [for (var i = 0; i < 60; i++) '[00:05.00]L$i'].join('\n');
      final track = parseLrc(raw, sourceDocumentId: 'x');
      expect(track.cues.map((c) => c.text), [
        for (var i = 0; i < 60; i++) 'L$i',
      ]);
      expect(track.sourceLyrics.split('\n').first, 'L0');
      expect(track.sourceLyrics.split('\n').last, 'L59');
    });

    test('huge minute values yield an invalid track instead of throwing', () {
      const raw = '[99999999999999999999:01]Hello';
      final track = parseLrc(raw, sourceDocumentId: 'x');
      expect(track.status, TimingStatus.invalid);
      expect(track.raw, raw);
      final bytes = parseTimingBytes(
        utf8.encode(raw),
        sourceDocumentId: 'x',
        format: 'lrc',
      );
      expect(bytes.status, TimingStatus.invalid);
      final word = parseLrc(
        '[00:01]<99999999999999999999:01>Hello',
        sourceDocumentId: 'x',
      );
      expect(word.status, TimingStatus.invalid);
    });

    test('word markers shift per repeated timestamp', () {
      final track = parseLrc(
        '[00:10][00:30]<00:10.5>Hello <00:11>world',
        sourceDocumentId: 'x',
      );
      final words = track.cues.where((c) => c.graphemeStart != null).toList();
      expect(words.map((c) => c.startUs), [
        10500000,
        11000000,
        30500000,
        31000000,
      ]);
      expect(words.map((c) => c.occurrenceId), [
        'line-0',
        'line-0',
        'line-1',
        'line-1',
      ]);
    });
  });

  group('TTML', () {
    test('tickRate defaults to 1 tick per second without a frameRate', () {
      final t = parseTtml(
        '<tt><body><p begin="10t" end="20t">X</p></body></tt>',
        sourceDocumentId: 'x',
      );
      expect(t.cues.single.startUs, 10000000);
      expect(t.cues.single.endUs, 20000000);
      final framed = parseTtml(
        '<tt xmlns:ttp="urn:test" ttp:frameRate="25"><body><p begin="25t" end="50t">X</p></body></tt>',
        sourceDocumentId: 'x',
      );
      expect(framed.cues.single.startUs, 1000000);
    });

    test('child beginning after parent end is clamped, not fatal', () {
      final t = parseTtml(
        '<tt><body><div begin="0s" end="5s"><p begin="8s" end="9s">A</p><p begin="1s" end="2s">B</p></div></body></tt>',
        sourceDocumentId: 'x',
      );
      expect(t.status, TimingStatus.unverified);
      expect(t.cues.first.text, 'B'); // sorted by start
      expect(t.cues.last.startUs, 5000000);
      expect(t.cues.last.endUs, 5000000);
    });

    test('paragraph without any timing does not get an invented 0s cue', () {
      final t = parseTtml(
        '<tt><body><div><p>Header</p><p begin="3s" end="4s">Line</p></div></body></tt>',
        sourceDocumentId: 'x',
      );
      expect(t.sourceLyrics, 'Header\nLine');
      expect(t.cues.single.text, 'Line');
      expect(t.cues.single.occurrenceId, 'line-1');
      expect(t.cues.single.startUs, 3000000);
    });

    test('untimed paragraph with timed spans starts at its first span', () {
      final t = parseTtml(
        '<tt><body><div><p><span begin="2s" end="3s">Hi</span> <span begin="3s" end="4s">there</span></p></div></body></tt>',
        sourceDocumentId: 'x',
      );
      expect(t.cues.first.startUs, 2000000);
      expect(t.cues.first.endUs, 4000000);
    });
  });

  group('ChordPro codec', () {
    test('mid-song and repeated directives stay in the body', () {
      const source =
          '{title: T}\n{artist: A}\n{key: G}\n{key: C}\n\nVerse\n{key: A}\n{capo: 2}\nChorus';
      final decoded = codec.decode(source);
      expect(decoded.metadata['key'], 'G');
      expect(decoded.body, contains('{key: C}'));
      expect(decoded.body, contains('{key: A}'));
      expect(decoded.body, contains('{capo: 2}'));
      expect(decoded.metadata.containsKey('capo'), isFalse);
      final again = codec.decode(codec.encode(decoded));
      expect(again.body, decoded.body);
      expect(again.metadata['key'], 'G');
    });

    test('body x_ directives are not hoisted out of position', () {
      final decoded = codec.decode(
        '{title: T}\n{x_head: 1}\n\nOne\n{x_mid: 2}\nTwo',
      );
      expect(decoded.body, 'One\n{x_mid: 2}\nTwo');
      expect(decoded.preservedExtensions, ['{x_head: 1}']);
    });

    test('body starting with a metadata directive keeps it after round trip', () {
      final original = song(body: '{key: A}\nHello');
      final decoded = codec.decode(codec.encode(original));
      expect(decoded.body, '{key: A}\nHello');
    });

    test('unreferenced rawAssets are pruned on encode', () {
      final stale = {
        'deadbeef': {'encoding': 'base64', 'bytes': 'AAAA'},
      };
      final empty = codec.decode(
        codec.encode(song(extra: {'rawAssets': stale})),
      );
      expect(empty.extra.containsKey('rawAssets'), isFalse);
      final track = parseLrc('[00:01]Hello', sourceDocumentId: 'x:1');
      final kept = codec.decode(
        codec.encode(song(tracks: [track], extra: {'rawAssets': stale})),
      );
      expect((kept.extra['rawAssets'] as Map).keys, hasLength(1));
      expect(kept.extra['rawAssets'], isNot(contains('deadbeef')));
      expect(kept.timingTracks.single.raw, '[00:01]Hello');
    });

    test('multi-chunk x_verse_data round trips', () {
      final raw = [
        for (var i = 0; i < 1500; i++)
          '[${(i ~/ 60).toString().padLeft(2, '0')}:${(i % 60).toString().padLeft(2, '0')}]Line number $i',
      ].join('\n');
      final track = parseLrc(raw, sourceDocumentId: 'big:1');
      final encoded = codec.encode(
        song(body: track.sourceLyrics, tracks: [track]),
      );
      final chunks = encoded
          .split('\n')
          .where((l) => l.startsWith('{x_verse_data:'))
          .length;
      expect(chunks, greaterThan(2));
      final decoded = codec.decode(encoded);
      expect(decoded.extensionError, isNull);
      expect(decoded.timingTracks.single.raw, raw);
      expect(decoded.timingTracks.single.cues, hasLength(1500));
    });

    test('SongCandidate keeps unknown fields', () {
      final candidate = SongCandidate.fromJson({
        'providerId': 'p',
        'id': '1',
        'title': 't',
        'artist': 'a',
        'futureField': {'x': 1},
      });
      expect(candidate.extra['futureField'], {'x': 1});
      expect(candidate.toJson()['futureField'], {'x': 1});
      expect(SongCandidate.fromJson(candidate.toJson()).extra, candidate.extra);
    });
  });

  group('arrangement', () {
    test('chord alterations containing b do not force flats', () {
      expect(transposeChord('C#7b9', 2), 'D#7b9');
      expect(transposeChord('Bb7b9', 3), 'Db7b9');
      expect(transposeChord('C/Bb', 2), 'D/C');
      expect(transposeChord('Cadd9', 1), 'C#add9');
    });

    test('equal recordingIds maps do not stale usable timing', () {
      final track = parseLrc(
        '[00:01]Hello',
        sourceDocumentId: 'x',
      ).copyWith(status: TimingStatus.usable);
      final original = song(
        tracks: [track],
        metadata: {
          'recordingIds': {'mbid': '1'},
        },
      );
      final edited = editSong(
        original,
        metadata: {
          'recordingIds': {'mbid': '1'},
        },
      );
      expect(edited.timingTracks.single.status, TimingStatus.usable);
      final changed = editSong(
        original,
        metadata: {
          'recordingIds': {'mbid': '2'},
        },
      );
      expect(changed.timingTracks.single.status, TimingStatus.stale);
    });
  });

  group('combine', () {
    SongCandidate candidate(String title, String artist) =>
        SongCandidate(providerId: 'p', id: '1', title: title, artist: artist);
    SourceResult result(SongCandidate c) => SourceResult(
      candidate: c,
      body: 'x',
      matchKind: MatchKind.sameSong,
    );

    test('parenthetical stripping respects word boundaries', () {
      final selected = candidate('Song', 'Artist');
      expect(
        recordingCompatible(selected, result(candidate('Song (Deliver)', 'Artist'))),
        isFalse,
      );
      expect(
        recordingCompatible(selected, result(candidate('Song (Alive)', 'Artist'))),
        isFalse,
      );
      expect(
        recordingCompatible(
          candidate('Song (Live)', 'Artist'),
          result(candidate('Song (Live)', 'Artist')),
        ),
        isTrue,
      );
    });

    test('two empty titles or artists are not the same song', () {
      expect(
        recordingCompatible(candidate('', ''), result(candidate('', ''))),
        isFalse,
      );
      expect(
        recordingCompatible(candidate('Song', ''), result(candidate('Song', ''))),
        isFalse,
      );
    });
  });
}
