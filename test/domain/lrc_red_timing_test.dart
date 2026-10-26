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
