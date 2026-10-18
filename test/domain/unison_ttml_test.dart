import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/timing.dart';

const _unisonTtml =
    '<tt xmlns="http://www.w3.org/ns/ttml" timeBase="media" composer="https://composer.boidu.dev/ttml"><body><div><p begin="0:13.532" end="0:15.126"><span begin="0:13.532" end="0:13.930">First words</span><span begin="0:13.930" end="0:15.126">second words</span></p></div></body></tt>';

void main() {
  test('recognizes the current declared Unison composer namespace', () {
    final raw = _unisonTtml.replaceFirst(
      'composer="https://composer.boidu.dev/ttml"',
      'xmlns:composer="https://composer.betterlyrics.org/ttml"',
    );
    final track = parseTtml(raw, sourceDocumentId: 'unison:synthetic');
    expect(track.status.name, 'unverified');
    expect(track.raw, raw);
    expect(track.cues, hasLength(3));
    expect(track.granularity, 'word');
    expect(track.extra['timingProfile'], 'unison-ttml');
    expect(
      track.cues.firstWhere((cue) => cue.graphemeStart == 0).startUs,
      13532000,
    );
    for (final invalid in [
      raw.replaceFirst(' timeBase="media"', ''),
      raw.replaceFirst('composer.betterlyrics.org', 'unrecognized.example'),
    ]) {
      expect(
        parseTtml(invalid, sourceDocumentId: 'synthetic').status.name,
        'invalid',
      );
    }
  });

  test('recognizes only declared Unison absolute partial-clock TTML', () {
    final track = parseTtml(_unisonTtml, sourceDocumentId: 'unison:31');

    expect(track.status.name, 'unverified');
    expect(track.raw, _unisonTtml);
    expect(track.cues, hasLength(3));
    expect(track.granularity, 'word');
    expect(track.extra['timingProfile'], 'unison-ttml');
    expect(track.extra['parserVersion'], 'verse-ttml-3');

    final firstWord = track.cues.firstWhere((cue) => cue.graphemeStart == 0);
    expect(firstWord.startUs, 13532000);
    expect(firstWord.originalBegin, '0:13.532');
  });

  test(
    'requires both Unison root markers and leaves generic partial clocks invalid',
    () {
      final composerOnly = _unisonTtml.replaceFirst(' timeBase="media"', '');
      final timeBaseOnly = _unisonTtml.replaceFirst(
        ' composer="https://composer.boidu.dev/ttml"',
        '',
      );
      final generic = _unisonTtml
          .replaceFirst(' timeBase="media"', '')
          .replaceFirst(' composer="https://composer.boidu.dev/ttml"', '');

      for (final raw in [composerOnly, timeBaseOnly, generic]) {
        final track = parseTtml(raw, sourceDocumentId: 'unison:partial');
        expect(track.status.name, 'invalid');
        expect(track.cues, isEmpty);
        expect(track.raw, raw);
      }
    },
  );
}
