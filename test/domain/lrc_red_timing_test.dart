import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/timing.dart';
import 'package:singbook/domain/models.dart';

const _prefix = '''<tt xmlns="http://www.w3.org/ns/ttml"
 xmlns:lr="http://lrc.red/lyric-ttml-internal" lr:timing="Word">
 <body><div>''';
const _suffix = '</div></body></tt>';

TimingTrack parse(String body, {String? profile}) => parseTtml(
  '$_prefix$body$_suffix',
  sourceDocumentId: 'fixture',
  profile: profile,
);

void main() {
  test('opaque source IDs do not multiply into oversized timing payloads', () {
    final source = 'provider:${List.filled(8442, 'x').join()}';
    final raw = [
      for (var i = 0; i < 300; i++)
        '[${i ~/ 60}:${(i % 60).toString().padLeft(2, '0')}.000]'
            '<${i ~/ 60}:${(i % 60).toString().padLeft(2, '0')}.000>Amber '
            '<${i ~/ 60}:${(i % 60).toString().padLeft(2, '0')}.200>harbor '
            '<${i ~/ 60}:${(i % 60).toString().padLeft(2, '0')}.400>morning',
    ].join('\n');
    TimingTrack parseSource(String id) => parseTimingBytes(
      utf8.encode(raw),
      sourceDocumentId: id,
      recordingId: 'recording-fixture',
      format: 'lrc',
    );
    final track = parseSource(source);
    final reference = parseSource('fixture');
    expect(track.status, TimingStatus.unverified);
    expect(track.format, 'enhanced-lrc');
    expect(track.cues, hasLength(1200));
    expect(track.id.length, lessThan(100));
    expect(track.cues.every((cue) => cue.id.length < 110), isTrue);
    expect(track.sourceDocumentId, source);
    expect(track.recordingId, 'recording-fixture');
    expect(track.raw, raw);
    expect(track.sourceLyrics, reference.sourceLyrics);
    expect(track.extra, reference.extra);
    expect(
      track.cues.map((cue) => {...cue.toJson()}..remove('id')).toList(),
      reference.cues.map((cue) => {...cue.toJson()}..remove('id')).toList(),
    );
    expect(
      utf8.encode(jsonEncode(track.toJson())).length,
      lessThan(600 * 1024),
    );
    expect(parseSource(source).toJson(), track.toJson());
    expect(parseSource('${source}y').id, isNot(track.id));
    final restored = TimingTrack.fromJson(
      jsonMap(jsonDecode(jsonEncode(track.toJson()))),
    );
    expect(restored.toJson(), track.toJson());
  });

  test('normal generated IDs and legacy loaded IDs stay unchanged', () {
    const raw = '[00:01.000]Amber harbor';
    final normal = parseLrc(raw, sourceDocumentId: 'fixture');
    expect(
      normal.id,
      'fixture:${sha256.convert(utf8.encode(raw)).toString().substring(0, 20)}',
    );
    final boundary = List.filled(256, 's').join();
    expect(
      parseLrc(raw, sourceDocumentId: boundary).id,
      startsWith('$boundary:'),
    );
    final legacyId = 'provider:${List.filled(8442, 'x').join()}:historic';
    final payload = {
      ...normal.toJson(),
      'id': legacyId,
      'sourceDocumentId': legacyId,
      'cues': [
        {...normal.cues.single.toJson(), 'id': '$legacyId:0'},
      ],
    };
    final loaded = TimingTrack.fromJson(payload);
    expect(loaded.id, legacyId);
    expect(loaded.cues.single.id, '$legacyId:0');
    expect(loaded.toJson(), payload);
  });

  test(
    'inactive byte imports also bound generated IDs and preserve provenance',
    () {
      final source = List.filled(8442, 'x').join();
      final unsupported = parseTimingBytes(
        [0xff],
        sourceDocumentId: source,
        format: 'lrc',
        recordingId: 'recording-fixture',
      );
      expect(unsupported.id.length, lessThan(140));
      expect(unsupported.sourceDocumentId, source);
      expect(unsupported.recordingId, 'recording-fixture');
      expect(unsupported.extra['rawBytesBase64'], base64.encode([0xff]));
      expect(unsupported.status, TimingStatus.unsupported);
      final oversized = parseTimingBytes(
        List.filled(maxTimingBytes + 1, 0),
        sourceDocumentId: source,
        format: 'lrc',
      );
      expect(oversized.id.length, lessThan(140));
      expect(oversized.sourceDocumentId, source);
      expect(oversized.status, TimingStatus.invalid);
    },
  );

  test(
    'explicit profile supports bare seconds, short clocks, and absolute children',
    () {
      final track = parse(
        '<p begin="19.764" end="24.000"><span begin="20.100" end="21.2">Hi</span> there</p>'
        '<p begin="1:02.250">Again</p>'
        '<p begin="0">Zero</p>',
        profile: 'lrc-red',
      );
      expect(track.status, TimingStatus.unverified);
      expect(track.sourceLyrics, 'Hi there\nAgain\nZero');
      expect(
        track.cues.singleWhere((cue) => cue.text == 'Hi there').startUs,
        19764000,
      );
      final word = track.cues.singleWhere((cue) => cue.graphemeStart != null);
      expect(word.startUs, 20100000);
      expect(word.graphemeStart, 0);
      expect(word.graphemeEnd, 2);
      expect(
        track.cues.singleWhere((cue) => cue.text == 'Again').startUs,
        62250000,
      );
      expect(track.cues.singleWhere((cue) => cue.text == 'Zero').startUs, 0);
      expect(track.extra['timingProfile'], 'lrc-red-ttml');
      expect(track.raw, contains('19.764'));
    },
  );

  test('profile is explicit and generic children remain parent-relative', () {
    const input =
        '<tt xmlns="http://www.w3.org/ns/ttml" '
        'xmlns:lr="http://lrc.red/lyric-ttml-internal" lr:timing="Word">'
        '<body><div><p begin="10s" end="30s"><span begin="12s" end="13s">One</span></p></div></body></tt>';
    final generic = parseTtml(input, sourceDocumentId: 'fixture');
    final selected = parseTtml(
      input,
      sourceDocumentId: 'fixture',
      profile: 'lrc-red',
    );
    expect(
      generic.cues.singleWhere((cue) => cue.graphemeStart != null).startUs,
      22000000,
    );
    expect(
      selected.cues.singleWhere((cue) => cue.graphemeStart != null).startUs,
      12000000,
    );
    final defaultBareSeconds = parseTtml(
      '<tt xmlns="http://www.w3.org/ns/ttml"><body><div><p begin="19.764">Bare</p></div></body></tt>',
      sourceDocumentId: 'fixture',
    );
    expect(defaultBareSeconds.status, TimingStatus.invalid);
    expect(
      parseTtml(
        input.replaceFirst(' lr:timing="Word"', ''),
        sourceDocumentId: 'fixture',
        profile: 'lrc-red',
      ).status,
      TimingStatus.invalid,
    );
    final w3c = parseTtml(
      '<tt xmlns="http://www.w3.org/ns/ttml"><body><div><p begin="10s">'
      '<span begin="2s">One</span></p></div></body></tt>',
      sourceDocumentId: 'fixture',
    );
    expect(
      w3c.cues.singleWhere((cue) => cue.graphemeStart != null).startUs,
      12000000,
    );
  });

  test('rejects dangerous XML, malformed clocks, and inconsistent ranges', () {
    for (final body in [
      '<!DOCTYPE tt [<!ENTITY x "bad">]><tt/>',
      '<p begin="1:99.2">Bad</p>',
      '<p begin="2s" end="3s"><span begin="4s">Late</span></p>',
      '<p begin="604801">Late</p>',
      '<p begin="NaNs">Bad</p>',
    ]) {
      expect(
        parse(body, profile: 'lrc-red').status,
        TimingStatus.invalid,
        reason: body,
      );
    }
  });
}
