import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:verse_mobile/domain/models.dart';
import 'package:verse_mobile/domain/arrangement.dart';
import 'package:verse_mobile/domain/chordpro.dart';
import 'package:verse_mobile/domain/timing.dart';
import 'package:verse_mobile/domain/combine.dart';

void main() {
  final codec = ChordProCodec();
  SongDocument song({
    String body = '[C]Hello 👩🏽‍🎤\n[F]Hello 👩🏽‍🎤',
    List<TimingTrack> tracks = const [],
  }) => SongDocument(
    id: 'song-1',
    title: 'Example',
    artist: 'Artist',
    body: body,
    timingTracks: tracks,
    metadata: {'capo': 0, 'durationSeconds': 123.5, 'custom': 'retained'},
    extra: {
      'future': {'nested': true},
    },
  );
  test('one file preserves Unicode chords unknown fields and zero capo', () {
    final original = song();
    final decoded = codec.decode(codec.encode(original));
    expect(decoded.body, original.body);
    expect(decoded.metadata, original.metadata);
    expect(decoded.extra['future'], {'nested': true});
    expect(decoded.id, original.id);
  });
  test('raw timing retained exactly and normalized cues roundtrip', () {
    const raw =
        '[offset:20]\r\n[00:01.10]Hello 👩🏽‍🎤\r\n[00:02.2]Hello 👩🏽‍🎤';
    final track = parseLrc(
      raw,
      sourceDocumentId: 'lrclib:1',
    ).copyWith(status: TimingStatus.usable);
    final decoded = codec.decode(codec.encode(song(tracks: [track])));
    expect(decoded.timingTracks.single.raw, raw);
    // LRC [offset:+n] makes lyrics appear n ms sooner (timestamp minus offset).
    expect(decoded.timingTracks.single.cues.first.startUs, 1080000);
    expect(decoded.timingTracks.single.cues.first.endUs, isNull);
    expect(
      decoded.timingTracks.single.cues[0].occurrenceId,
      isNot(decoded.timingTracks.single.cues[1].occurrenceId),
    );
  });
  test('malformed extension stays opaque and does not produce second header', () {
    const source =
        '{title: Example}\n{x_verse: 1 json-base64url 2}\n{x_verse_data: 1/2 abcd}\n\n[C]Hello';
    final imported = codec.decode(source);
    expect(imported.extensionError, isNotNull);
    final output = codec.encode(imported.copyWith(title: 'Changed'));
    expect(RegExp(r'\{x_verse:').allMatches(output).length, 1);
    expect(output, contains('{x_verse_data: 1/2 abcd}'));
    expect(imported.timingTracks, isEmpty);
  });
  test('future blocks and unknown extension spelling survive', () {
    final imported = codec.decode(
      '{title: Old}\n{x_verse: 7 zstd 1}\n{x_verse_data: 1/1 ABC}\n{x_other: value}\n\nA lyric',
    );
    final output = codec.encode(imported);
    expect(output, contains('{x_verse: 7 zstd 1}'));
    expect(output, contains('{x_other: value}'));
  });
  test('chunk duplicates rejected without partially activating timing', () {
    final encoded = codec.encode(
      song(
        body: 'line',
        tracks: [parseLrc('[00:01]line', sourceDocumentId: 'x:1')],
      ),
    );
    final dataLine = encoded
        .split('\n')
        .firstWhere((line) => line.startsWith('{x_verse_data'));
    final broken = encoded.replaceFirst(dataLine, '$dataLine\n$dataLine');
    final result = codec.decode(broken);
    expect(result.extensionError, isNotNull);
    expect(result.timingTracks, isEmpty);
  });
  test('valid JSON with wrong known field types remains opaque', () {
    final json = base64Url
        .encode(utf8.encode('{"schemaVersion":1,"id":3,"revision":1}'))
        .replaceAll('=', '');
    final decoded = codec.decode(
      '{x_verse: 1 json-base64url 1}\n{x_verse_data: 1/1 $json}\nhello',
    );
    expect(decoded.extensionError, isNotNull);
  });
  test(
    'external text edit marks active timing stale while chords remain compatible',
    () {
      final track = parseLrc(
        '[00:01]Hello',
        sourceDocumentId: 'x:1',
      ).copyWith(status: TimingStatus.usable);
      final original = song(
        body: '[C]Hello',
        tracks: [track],
      ).copyWith(activeTimingTrackId: track.id);
      final encoded = codec.encode(original);
      expect(
        codec
            .decode(encoded.replaceFirst('[C]Hello', '[F]Hello'))
            .timingTracks
            .single
            .status,
        TimingStatus.usable,
      );
      final changed = codec.decode(
        encoded.replaceFirst('[C]Hello', '[C]Goodbye'),
      );
      expect(changed.timingTracks.single.status, TimingStatus.stale);
      expect(changed.activeTimingTrackId, isNull);
    },
  );
  test(
    'editor preserves chord-only timing and stales repeated-line removal',
    () {
      final track = parseLrc(
        '[00:01]Hello\n[00:02]Hello',
        sourceDocumentId: 'x:1',
      ).copyWith(status: TimingStatus.usable);
      final original = song(body: '[C]Hello\n[F]Hello', tracks: [track]);
      expect(
        editSong(
          original,
          body: '[G]Hello\n[F]Hello',
        ).timingTracks.single.status,
        TimingStatus.usable,
      );
      expect(
        editSong(original, body: '[C]Hello').timingTracks.single.status,
        TimingStatus.stale,
      );
    },
  );
  test(
    'section labels are not chords and transposition preserves labels/slash bass',
    () {
      expect(containsChords('[Chorus]\n[Bridge]\n[Acoustic]'), isFalse);
      expect(
        transposeBody('[Chorus]\n[C/E]Hello [Bbmaj7]there', 2),
        '[Chorus]\n[D/F#]Hello [Cmaj7]there',
      );
    },
  );
  test(
    'chord anchors count graphemes across emoji and combining characters',
    () {
      final line = parseArrangement('👩🏽‍🎤[C]e\u0301[F]Hi').single;
      expect(line.text, '👩🏽‍🎤e\u0301Hi');
      expect(line.chords.map((c) => c.offset), [1, 2]);
    },
  );
  test('chorus references expand as distinct performance occurrences', () {
    const body =
        '{start_of_chorus}\n[C]Repeat\n{end_of_chorus}\nBetween\n{chorus}';
    expect(lyricLines(body), ['Repeat', 'Between', 'Repeat']);
    expect(
      lyricOrderHash(body),
      isNot(lyricOrderHash(body.replaceAll('{chorus}', ''))),
    );
  });
  test('broader chord qualities and escaped literal brackets are distinct', () {
    const body = r'[C6/9]One [Am6-9]two [B♭ø]three \[C\] \{literal\}';
    expect(parseArrangement(body).single.chords.map((c) => c.chord), [
      'C6/9',
      'Am6-9',
      'B♭ø',
    ]);
    expect(plainLyrics(body), 'One two three [C] {literal}');
    expect(
      transposeBody(body, 2),
      r'[D6/9]One [Bm6-9]two [Cø]three \[C\] \{literal\}',
    );
  });
  test(
    'invalid normalized timing does not corrupt the surrounding song extension',
    () {
      // Seconds >= 60 are unrepresentable (negative offsets now clamp to 0).
      const raw = '[00:75]Hello';
      final track = parseLrc(raw, sourceDocumentId: 'bad:1');
      expect(track.status, TimingStatus.invalid);
      final restored = codec.decode(
        codec.encode(song(body: 'Hello', tracks: [track])),
      );
      expect(restored.extensionError, isNull);
      expect(restored.timingTracks.single.raw, raw);
      expect(restored.timingTracks.single.status, TimingStatus.invalid);
      expect(restored.timingTracks.single.cues, isEmpty);
    },
  );
  test('enhanced LRC uses grapheme offsets and records word timestamps', () {
    final track = parseLrc(
      '[00:01]<00:01>👩🏽‍🎤 <00:02>Hello',
      sourceDocumentId: 'x:1',
    );
    expect(track.granularity, 'word');
    expect(track.cues.last.graphemeStart, 2);
    expect(track.cues.last.startUs, 2000000);
  });
  test(
    'imported file timeline is usable with exact lyrics and preserves gap mapping',
    () {
      final track = parseLrc(
        '[00:01]Hello\n[00:02]\n[00:03]World',
        sourceDocumentId: 'import:1',
      );
      final bound = bindImportedTiming(track, '[C]Hello\n[G]World');
      expect(bound.status, TimingStatus.usable);
      expect(bound.origin, 'user');
      expect(bound.extra['binding']['recordingVerified'], isFalse);
      expect(bound.extra['binding']['occurrences'], [
        {'source': 'line-0', 'target': 'line-0'},
        {'source': 'line-2', 'target': 'line-1'},
      ]);
      expect(
        bindImportedTiming(track, 'Different').status,
        TimingStatus.incompatible,
      );
    },
  );
  test(
    'plain TTML is retained without inventing zero-time synchronization',
    () {
      final track = parseTtml(
        '<tt><body><div><p>Hello</p></div></body></tt>',
        sourceDocumentId: 'import:2',
      );
      expect(track.sourceLyrics, 'Hello');
      expect(track.status, TimingStatus.unsupported);
      expect(
        bindImportedTiming(track, track.sourceLyrics).status,
        TimingStatus.unsupported,
      );
    },
  );
  test('multiple LRC timestamps expand in performance order', () {
    final track = parseLrc(
      '[00:10][00:30]Repeat\n[00:20]Between',
      sourceDocumentId: 'x:1',
    );
    expect(track.sourceLyrics, 'Repeat\nBetween\nRepeat');
    expect(track.cues.map((c) => c.occurrenceId), [
      'line-0',
      'line-1',
      'line-2',
    ]);
  });
  test('TTML resolves parents and retains word ends with raw source', () {
    const raw =
        '<tt xmlns="http://www.w3.org/ns/ttml"><body begin="2s"><div><p begin="1s" dur="4s"><span begin="500ms" dur="1s">Hello</span> <span begin="2s">world</span></p></div></body></tt>';
    final track = parseTtml(raw, sourceDocumentId: 'better:1');
    expect(track.status, TimingStatus.unverified);
    expect(track.sourceLyrics, 'Hello world');
    expect(track.cues.first.startUs, 3000000);
    expect(track.cues.first.endUs, 7000000);
    expect(track.cues[1].startUs, 3500000);
    expect(track.cues[1].endUs, 4500000);
    expect(track.raw, raw);
  });
  test('TTML frames and ticks normalize accurately', () {
    final t = parseTtml(
      '<tt xmlns:ttp="urn:test" ttp:frameRate="25" ttp:tickRate="100"><body><p begin="00:00:01:12" end="200t">Test</p></body></tt>',
      sourceDocumentId: 'x',
    );
    expect(t.cues.single.startUs, 1480000);
    expect(t.cues.single.endUs, 2000000);
  });
  test(
    'Apple lyric profile keeps child clocks absolute and accepts partial clocks',
    () {
      const raw =
          '<tt xmlns:itunes="http://itunes.apple.com/lyric-ttml-extensions"><body dur="02:00.000"><div begin="00:10.000" end="00:30.000"><p begin="00:12.000" end="00:15.000"><span begin="00:12.500" end="00:14.000">Hello</span></p></div></body></tt>';
      final track = parseTtml(raw, sourceDocumentId: 'better:1');
      expect(track.status, TimingStatus.unverified);
      expect(track.cues.first.startUs, 12000000);
      expect(track.cues.last.startUs, 12500000);
      expect(track.cues.last.endUs, 14000000);
      expect(track.extra['timingProfile'], 'apple-lyrics');
    },
  );
  test('nonUTF8 timing bytes are retained exactly in one song', () {
    final bytes = latin1.encode('[00:01]Café');
    final track = parseTimingBytes(
      bytes,
      sourceDocumentId: 'import:1',
      format: 'lrc',
      encoding: 'latin1',
    );
    expect(track.sourceLyrics, 'Café');
    final imported = codec.decode(
      codec.encode(song(body: 'Café', tracks: [track])),
    );
    expect(
      base64.decode(
        imported.timingTracks.single.extra['rawBytesBase64'] as String,
      ),
      bytes,
    );
    final unsupported = parseTimingBytes(
      bytes,
      sourceDocumentId: 'import:2',
      format: 'lrc',
    );
    expect(unsupported.status, TimingStatus.unsupported);
    expect(base64.decode(unsupported.extra['rawBytesBase64'] as String), bytes);
  });
  test('unsupported TTML sequence retained inactive and entities rejected', () {
    final seq = parseTtml(
      '<tt><body timeContainer="seq"><p begin="1s">One</p></body></tt>',
      sourceDocumentId: 'x',
    );
    expect(seq.status, TimingStatus.unsupported);
    final entity = parseTtml(
      '<!DOCTYPE tt SYSTEM "file:///secret"><tt><body/></tt>',
      sourceDocumentId: 'x',
    );
    expect(entity.status, TimingStatus.invalid);
    expect(entity.raw, contains('DOCTYPE'));
  });

  const selected = SongCandidate(
    providerId: 'genius',
    id: '1',
    title: 'Song',
    artist: 'Artist',
    album: 'Album',
    durationSeconds: 120,
  );
  SourceResult source(
    String id,
    String body, {
    String? album = 'Album',
    double duration = 120,
    MatchKind kind = MatchKind.sameRecording,
    List<TimingTrack> tracks = const [],
    JsonMap metadata = const {},
  }) => SourceResult(
    candidate: SongCandidate(
      providerId: id,
      id: '1',
      title: 'Song',
      artist: 'Artist',
      album: album,
      durationSeconds: duration,
    ),
    body: body,
    matchKind: kind,
    timingTracks: tracks,
    metadata: metadata,
  );
  test(
    'combine keeps chart text, safe metadata, conflicts and applicable timing',
    () {
      final timed = parseLrc(
        '[00:01]Hello\n[00:02]world',
        sourceDocumentId: 'lrclib:1',
      );
      final result = combineSources(selected, [
        source(
          'ug',
          '[C]Hello\n[F]world',
          kind: MatchKind.sameSong,
          metadata: {'key': 'C', 'capo': 0, 'durationSeconds': 999},
        ),
        source(
          'lrclib',
          'Hello\nworld',
          tracks: [timed],
          metadata: {
            'artworkUrl': 'https://example.test/a',
            'durationSeconds': 121,
          },
        ),
      ]);
      expect(result.body, '[C]Hello\n[F]world');
      expect(result.metadata['durationSeconds'], 120);
      expect(result.metadata['capo'], 0);
      expect(result.metadata['artworkUrl'], 'https://example.test/a');
      expect(result.extra['conflicts'], contains('durationSeconds'));
      expect(result.timingTracks.single.status, TimingStatus.usable);
    },
  );
  test(
    'complete chord chart wins over matching long lyrics and retains timing',
    () {
      const lyrics =
          'amber lanterns drift across the quiet harbor\n'
          'silver rain is tracing patterns on the water\n'
          'sleepy gulls circle low above the waiting boats\n'
          'morning paints the shore with orange light again';
      const raw =
          '[00:01.00]amber lanterns drift across the quiet harbor\n'
          '[00:07.00]silver rain is tracing patterns on the water\n'
          '[00:13.00]sleepy gulls circle low above the waiting boats\n'
          '[00:19.00]morning paints the shore with orange light again';
      final timed = parseLrc(raw, sourceDocumentId: 'lrclib:1');
      final result = combineSources(selected, [
        source(
          'ug',
          '[Am]amber lanterns drift across the quiet harbor\n'
              '[F]silver rain is tracing patterns on the water\n'
              '[C]sleepy gulls circle low above the waiting boats\n'
              '[G]morning paints the shore with orange light again',
          kind: MatchKind.sameSong,
        ),
        source('lrclib', lyrics, tracks: [timed]),
      ]);

      expect(result.body, contains('[Am]'));
      expect(result.extra['selectedSourceId'], 'ug:1');
      expect(result.timingTracks.single.raw, raw);
    },
  );
  test('mismatched recording and lyrics timing retained but not activated', () {
    final result = combineSources(selected, [
      source('ug', '[C]Different words', kind: MatchKind.sameSong),
      source(
        'lrclib',
        'Hello',
        duration: 150,
        tracks: [parseLrc('[00:01]Hello', sourceDocumentId: 'lrclib:1')],
      ),
    ]);
    expect(result.timingTracks, isNotEmpty);
    expect(result.activeTimingTrackId, isNull);
    expect(result.timingTracks.single.status, isNot(TimingStatus.usable));
  });
  test('partial chord chart does not outrank a fuller matched lyric', () {
    const full =
        'one two three four five six seven eight nine ten eleven twelve\nthirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour';
    final result = combineSources(selected, [
      source(
        'ug',
        '[C]one two three four five six seven eight nine ten eleven twelve',
        kind: MatchKind.sameSong,
      ),
      source('lrclib', full),
    ]);
    expect(result.body, full);
    expect(result.extra['excludedIncompleteSourceIds'], contains('ug:1'));
    expect(
      () => combineSources(selected, [
        source(
          'ug',
          '[C]one two three four five six seven eight nine ten eleven twelve',
          kind: MatchKind.sameSong,
        ),
        source('lrclib', full),
      ], preferredSourceId: 'ug:1'),
      throwsFormatException,
    );
  });
  test(
    'choosing source never falls back silently when the requested source is absent',
    () {
      expect(
        () => combineSources(selected, [
          source('lyrics', 'Hello'),
        ], preferredSourceId: 'missing'),
        throwsFormatException,
      );
    },
  );
  test(
    'cross-provider title match without recording evidence leaves timing unverified',
    () {
      final result = combineSources(selected, [
        source(
          'lrclib',
          'Hello',
          album: null,
          tracks: [parseLrc('[00:01]Hello', sourceDocumentId: 'lrclib:1')],
        ),
      ]);
      expect(result.timingTracks.single.status, TimingStatus.unverified);
    },
  );
  test(
    'same raw payload and normalized track are not duplicated in extension',
    () {
      final t = parseLrc('[00:01]Hello', sourceDocumentId: 'lrclib:1');
      final original = combineSources(selected, [
        source('lrclib', 'Hello', tracks: [t]),
      ]);
      final encoded = codec.encode(original);
      final decoded = codec.decode(encoded);
      expect(decoded.timingTracks.length, 1);
      expect(decoded.sources.single.timingTracks.single.raw, t.raw);
      expect(decoded.timingTracks.single.status, TimingStatus.usable);
    },
  );
  test(
    'metadata-only result contributes verified recording facts with origins',
    () {
      final result = combineSources(selected, [
        source('lyrics', 'Hello'),
        source(
          'musicbrainz',
          '',
          metadata: {
            'artworkUrl': 'https://example.test/cover',
            'releaseDate': '2020-01-01',
          },
        ),
      ]);
      expect(result.metadata['artworkUrl'], 'https://example.test/cover');
      expect(result.extra['fieldOrigins']['artworkUrl'], 'musicbrainz:1');
      expect(result.sources, hasLength(2));
    },
  );
  test('wrong recording metadata does not enrich selected record', () {
    final result = combineSources(selected, [
      source('lyrics', 'Hello'),
      source(
        'musicbrainz',
        '',
        duration: 999,
        metadata: {'artworkUrl': 'wrong', 'durationSeconds': 999},
      ),
    ]);
    expect(result.metadata['artworkUrl'], isNull);
    expect(result.metadata['durationSeconds'], 120);
  });
  test('same artist different title does not become a matching chart', () {
    final wrong = SourceResult(
      candidate: const SongCandidate(
        providerId: 'ug',
        id: '2',
        title: 'Other song',
        artist: 'Artist',
      ),
      body: '[C]Wrong words',
      matchKind: MatchKind.sameSong,
    );
    expect(
      combineSources(selected, [source('lyrics', 'Hello'), wrong]).body,
      'Hello',
    );
  });
}
