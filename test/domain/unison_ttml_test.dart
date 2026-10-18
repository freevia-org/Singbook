import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/timing.dart';

const _unisonTtml =
    '<tt xmlns="http://www.w3.org/ns/ttml" timeBase="media" composer="https://composer.boidu.dev/ttml"><body><div><p begin="0:13.532" end="0:15.126"><span begin="0:13.532" end="0:13.930">First words</span><span begin="0:13.930" end="0:15.126">second words</span></p></div></body></tt>';

void main() {
  test('recognizes only declared Unison absolute partial-clock TTML', () {
    final track = parseTtml(_unisonTtml, sourceDocumentId: 'unison:31');

    expect(track.status.name, 'unverified');
    expect(track.raw, _unisonTtml);
    expect(track.cues, hasLength(3));
    expect(track.granularity, 'word');
    expect(track.extra['timingProfile'], 'unison-ttml');
    expect(track.extra['parserVersion'], 'verse-ttml-4');

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

  test(
    'current Composer namespace retains absolute media clock cues and raw TTML',
    () {
      const raw =
          '<tt xmlns="http://www.w3.org/ns/ttml" '
          'xmlns:ttp="http://www.w3.org/ns/ttml#parameter" '
          'xmlns:composer="https://composer.betterlyrics.org/ttml" '
          'ttp:timeBase="media"><body dur="2:10.984"><div>'
          '<p begin="0:13.532" end="0:15.126">'
          '<span begin="0:13.532" end="0:13.930">First words</span>'
          '<span begin="0:13.930" end="0:15.126">second words</span>'
          '</p></div></body></tt>';
      final track = parseTtml(raw, sourceDocumentId: 'unison:current');
      expect(track.status.name, 'unverified');
      expect(track.extra['timingProfile'], 'unison-ttml');
      expect(track.extra['parserVersion'], 'verse-ttml-4');
      expect(track.raw, raw);
      expect(track.cues, hasLength(3));
      expect(track.granularity, 'word');
      expect(track.cues.first.startUs, 13532000);
      expect(track.cues.last.endUs, 15126000);
      expect(track.cues.last.originalBegin, '0:13.930');

      for (final unsupported in [
        raw.replaceFirst(' ttp:timeBase="media"', ''),
        raw.replaceFirst(' ttp:timeBase="media"', ' ttp:timeBase="clock"'),
        raw.replaceFirst(
          'https://composer.betterlyrics.org/ttml',
          'https://example.org/ttml',
        ),
      ]) {
        final rejected = parseTtml(
          unsupported,
          sourceDocumentId: 'generic:current',
        );
        expect(rejected.status.name, 'invalid');
        expect(rejected.cues, isEmpty);
        expect(rejected.raw, unsupported);
      }
    },
  );
}
