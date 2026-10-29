import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';

const _namespace = 'http://music.apple.com/lyric-ttml-internal';

String document(String body) =>
    '<tt xmlns="http://www.w3.org/ns/ttml" '
    'xmlns:custom="$_namespace" custom:timing="Word">'
    '<body><div>$body</div></body></tt>';

TimingTrack parse(String raw, {String? profile = 'amll-ttml'}) =>
    parseTtml(raw, sourceDocumentId: 'amll:fixture', profile: profile);

void main() {
  test('AMLL bare seconds are absolute and retain exact source precision', () {
    // Clock values from a public AMLL document; synthetic words only.
    final raw = document(
      '<p begin="0.115" end="2.813">'
      '<span begin="0.115" end="0.237">One</span> '
      '<span begin="0.237" end="2.813">two</span></p>',
    );
    final track = parse(raw);
    expect(track.status, TimingStatus.unverified);
    expect(track.granularity, 'word');
    expect(track.raw, raw);
    expect(track.extra['timingProfile'], 'amll-ttml');
    final line = track.cues.singleWhere((c) => c.graphemeStart == null);
    final words = track.cues.where((c) => c.graphemeStart != null).toList();
    expect((line.startUs, line.endUs), (115000, 2813000));
    expect((words[0].startUs, words[0].endUs), (115000, 237000));
    expect(words[1].startUs, words[0].endUs);
    expect(words[0].originalBegin, '0.115');
    expect(words[0].graphemeStart, 0);
    expect(words[0].graphemeEnd, 3);
  });

  test('AMLL short clocks have absolute children and adjacent words', () {
    final track = parse(
      document(
        '<p begin="00:09.929" end="00:12.237">'
        '<span begin="00:09.929" end="00:10.076">One</span> '
        '<span begin="00:10.076" end="00:12.237">two</span></p>',
      ),
    );
    expect(track.status, TimingStatus.unverified);
    final line = track.cues.singleWhere((c) => c.graphemeStart == null);
    final words = track.cues.where((c) => c.graphemeStart != null).toList();
    expect((line.startUs, line.endUs), (9929000, 12237000));
    expect((words[0].startUs, words[0].endUs), (9929000, 10076000));
    expect(words[1].startUs, 10076000);
  });

  test(
    'explicit profile permits older unmarked files and validates any marker',
    () {
      final valid = document('<p begin="0.115">One</p>');
      expect(parse(valid).status, TimingStatus.unverified);
      expect(
        parse(valid.replaceAll('custom:timing="Word"', '')).status,
        TimingStatus.unverified,
      );
      expect(
        parse(
          valid.replaceAll('custom:timing="Word"', 'custom:timing="Line"'),
        ).status,
        TimingStatus.unverified,
      );
      for (final raw in [
        valid.replaceAll(_namespace, 'https://example.org/wrong'),
        valid.replaceAll('custom:timing="Word"', 'timing="Word"'),
        valid.replaceAll('custom:timing="Word"', 'custom:timing="Other"'),
        valid.replaceAll(_namespace, 'http://lrc.red/lyric-ttml-internal'),
        valid.replaceAll(
          'xmlns="http://www.w3.org/ns/ttml"',
          'xmlns="https://example.org/not-ttml"',
        ),
      ]) {
        expect(parse(raw).status, TimingStatus.invalid);
      }
      expect(parse(valid, profile: 'lrc-red').status, TimingStatus.invalid);
      expect(parse(valid, profile: null).status, TimingStatus.invalid);
    },
  );

  test('AMLL marker alone does not change generic W3C relative semantics', () {
    final raw = document(
      '<p begin="10s" end="30s"><span begin="12s" end="13s">One</span></p>',
    );
    final generic = parse(raw, profile: null);
    final amll = parse(raw);
    expect(generic.cues.last.startUs, 22000000);
    expect(amll.cues.last.startUs, 12000000);
    expect(generic.id, isNot(amll.id));
    expect(generic.extra['timingProfile'], 'w3c-ttml');
  });

  test('auxiliary text stays raw; background words retain voice and position', () {
    final raw = document(
      '<p xmlns:ttm="http://www.w3.org/ns/ttml#metadata" ttm:agent="v1" begin="1" end="4">'
      '<span begin="1" end="2">One</span> '
      '<span ttm:role="x-translation">Translation</span>'
      '<span ttm:role="x-roman"><span begin="2" end="3">Romanization</span></span>'
      '<span ttm:role="x-bg" ttm:agent="v2" begin="2" end="4">'
      '<span begin="2" end="3">(two)</span>'
      '<span ttm:role="x-translation">Background translation</span></span></p>',
    );
    final track = parse(raw);
    expect(track.status, TimingStatus.unverified);
    expect(track.raw, raw);
    expect(track.sourceLyrics, 'One\n(two)');
    final words = track.cues.where((c) => c.graphemeStart != null).toList();
    expect(words, hasLength(2));
    expect(words.map((w) => w.voice), ['v1', 'v2']);
    expect(words.map((w) => w.startUs), [1000000, 2000000]);
    expect((words[1].graphemeStart, words[1].graphemeEnd), (0, 5));
    expect(words[1].extra['voiceRole'], 'background');
  });

  test('background lines can outlast foreground without clamping raw clocks', () {
    final raw = document(
      '<p xmlns:ttm="http://www.w3.org/ns/ttml#metadata" ttm:agent="v1" begin="1" end="2">'
      '<span begin="1" end="2">One</span>'
      '<span ttm:role="x-bg" begin="3" end="4">'
      '<span begin="3" end="4">Two</span></span></p>',
    ).replaceFirst('<body>', '<body dur="5">');
    final track = parse(raw);
    expect(track.status, TimingStatus.unverified);
    final lines = track.cues.where((c) => c.graphemeStart == null).toList();
    expect(lines, hasLength(2));
    expect((lines[0].startUs, lines[0].endUs), (1000000, 2000000));
    expect((lines[1].startUs, lines[1].endUs), (3000000, 4000000));
    expect(lines[1].voice, 'v1');
    expect(lines[1].extra['voiceRole'], 'background');
    expect(track.raw, raw);
    expect(
      parse(raw.replaceFirst('dur="5"', 'dur="2"')).status,
      TimingStatus.invalid,
    );
  });

  test(
    'unimplemented Ruby stays unsupported with original document retained',
    () {
      final raw = document(
        '<p begin="1" end="2"><span xmlns:tts="http://www.w3.org/ns/ttml#styling" '
        'tts:ruby="container">Synthetic</span></p>',
      );
      final track = parse(raw);
      expect(track.status, TimingStatus.unsupported);
      expect(track.raw, raw);
      expect(
        parse(
          raw.replaceFirst('tts:ruby="container"', 'tts:ruby="none"'),
        ).status,
        TimingStatus.unverified,
      );
    },
  );

  test('rejects malformed clocks, impossible child ranges, and unsafe XML', () {
    for (final body in [
      '<p begin="1:99.2">Bad</p>',
      '<p begin="604801">Late</p>',
      '<p begin="NaN">Bad</p>',
      '<p begin="2" end="3"><span begin="4">Late</span></p>',
      '<p begin="2" end="3"><span begin="2" end="4">Late</span></p>',
      '<!DOCTYPE tt [<!ENTITY x "bad">]><tt/>',
    ]) {
      expect(parse(document(body)).status, TimingStatus.invalid, reason: body);
    }
  });
}
