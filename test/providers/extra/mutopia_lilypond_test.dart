import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/extra/mutopia_lilypond.dart';

void main() {
  group('parseMutopiaLilypond', () {
    test(
      'keeps attached lyric variables separate and preserves safe spans',
      () {
        final document = parseMutopiaLilypond(r'''
\version "2.18.2"
\header {
  title = "Invented Suite"
  mutopiatitle = "Invented Suite, No. 1"
  composer = "A. Example"
  poet = "B. Example"
  arranger = "C. Example"
  source = "Synthetic source"
  license = "Public Domain"
  date = "2025"
  footer = "Synthetic footer"
  tagline = "\\lyricmode { header decoy }"
}
% \lyricmode { comment decoy }
noise = #(begin "\\lyricmode { Scheme string decoy }")
italianWords = \lyricmode { lu -- na chia -- ra ri -- so _ __ piu' cal_mo~can_to }
englishWords = \lyricmode { "sun," "moon!" "quoted -- and _ kept" }
\score { << \new Voice = "voice" { c'4 }
  \new Lyrics \lyricsto "voice" \italianWords
  \new Lyrics \lyricsto "voice-two" \englishWords >> }
''');

        expect(document.version, '2.18.2');
        expect(document.title, 'Invented Suite');
        expect(document.mutopiatitle, 'Invented Suite, No. 1');
        expect(document.composer, 'A. Example');
        expect(document.poet, 'B. Example');
        expect(document.arranger, 'C. Example');
        expect(document.source, 'Synthetic source');
        expect(document.license, 'Public Domain');
        expect(document.date, '2025');
        expect(document.footer, 'Synthetic footer');
        expect(document.lyricStreams, hasLength(2));
        expect(document.lyricStreams[0].publisherVariable, 'italianWords');
        expect(document.lyricStreams[0].literalVoiceReference, 'voice');
        expect(document.lyricStreams[0].attachmentVerified, isFalse);
        expect(
          document.lyricStreams[0].text,
          "luna chiara riso piu' cal mo can to",
        );
        expect(document.lyricStreams[1].publisherVariable, 'englishWords');
        expect(document.lyricStreams[1].literalVoiceReference, 'voice-two');
        expect(document.lyricStreams[1].attachmentVerified, isFalse);
        expect(
          document.lyricStreams[1].text,
          'sun, moon! quoted -- and _ kept',
        );
        expect(document.lyricStreams[0].bodySpan.start, greaterThan(0));
        expect(
          document.lyricStreams[0].sourceSpan.end,
          greaterThan(document.lyricStreams[0].sourceSpan.start),
        );
        expect(
          document.lyricStreams[0].syllables[1].joinBefore,
          MutopiaLyricJoin.continuation,
        );
        expect(
          document.lyricStreams[0].syllables[9].joinBefore,
          MutopiaLyricJoin.tie,
        );
      },
    );

    test(
      'accepts a direct text lyric variable with bar checks and source newlines',
      () {
        final document = parseMutopiaLilypond(r'''
\header { title = "Another Invented Song" }
text = \lyricmode {
  \barNumberCheck #7
  \barNumberCheck 23
  paper -- lantern _
  drifts over
  quiet-water
}
''');
        expect(document.lyricStreams, hasLength(1));
        expect(document.lyricStreams.single.publisherVariable, 'text');
        expect(document.lyricStreams.single.literalVoiceReference, isNull);
        expect(document.lyricStreams.single.attachmentVerified, isFalse);
        expect(
          document.lyricStreams.single.text,
          'paperlantern drifts over quiet-water',
        );
      },
    );

    test('decodes quoted escapes without interpreting syntax characters', () {
      final document = parseMutopiaLilypond(r'''
quoted = \lyricmode { "don't" "quoted \"word\"" "under_score~and--marks" }
''');
      expect(
        document.lyricStreams.single.text,
        'don\'t quoted "word" under_score~and--marks',
      );
      expect(
        () => parseMutopiaLilypond(
          r'''words = \lyricmode { "unknown \q escape" }''',
        ),
        throwsA(isA<MutopiaFormatException>()),
      );
    });

    test('ignores nested block comments and Scheme quoted decoys', () {
      final document = parseMutopiaLilypond(r'''
%{ outer \lyricmode { decoy %{
  nested } \include "not-real.ly" %}
} %}
quoted = #'(begin { \lyricmode { decoy } "unterminated-looking text")
words = \lyricmode { "real words" }
''');
      expect(document.lyricStreams, hasLength(1));
      expect(document.lyricStreams.single.text, 'real words');
    });

    test('keeps punctuation music commands inert outside lyrics', () {
      final document = parseMutopiaLilypond(r'''
words = \lyricmode { quiet-water }
\score { c'4 \! \\ d'4 \new Lyrics \lyricsto "voice" \words }
''');
      expect(document.lyricStreams.single.text, 'quiet-water');
      expect(
        () => parseMutopiaLilypond(r'words = \lyricmode { quiet \! water }'),
        throwsA(isA<MutopiaFormatException>()),
      );
    });

    test(
      'does not claim a lexical voice reference is an active attachment',
      () {
        final document = parseMutopiaLilypond(r'''
words = \lyricmode { invented words }
unused = \new Lyrics \lyricsto "decoy-voice" \words
''');
        expect(
          document.lyricStreams.single.literalVoiceReference,
          'decoy-voice',
        );
        expect(document.lyricStreams.single.attachmentVerified, isFalse);
      },
    );

    test('rejects unresolved and ambiguously bound lyric variables', () {
      expect(
        () => parseMutopiaLilypond(r'\score { \lyricsto "voice" \missing }'),
        throwsA(isA<MutopiaFormatException>()),
      );
      expect(
        () => parseMutopiaLilypond(r'''
words = \lyricmode { invented }
\score { \lyricsto "one" \words \lyricsto "two" \words }
'''),
        throwsA(isA<MutopiaFormatException>()),
      );
      expect(
        () => parseMutopiaLilypond(r'''
words = \lyricmode { invented }
words = "shadowed"
'''),
        throwsA(isA<MutopiaFormatException>()),
      );
    });

    test('rejects unsupported lyrics entry routes', () {
      for (final source in [
        r'\addlyrics { inline words }',
        r'\lyrics { inline words }',
        r'\new Lyrics { inline words }',
        r'\context Lyrics { inline words }',
      ]) {
        expect(
          () => parseMutopiaLilypond(source),
          throwsA(isA<MutopiaFormatException>()),
        );
      }
    });

    test('reads only direct header scalar fields and rejects ambiguity', () {
      final document = parseMutopiaLilypond(r'''
\header { title = "Real title" markup = \markup { title = "Nested title" } }
words = \lyricmode { invented }
''');
      expect(document.title, 'Real title');
      expect(
        () => parseMutopiaLilypond(r'''
\header { title = "First" title = "Second" }
'''),
        throwsA(isA<MutopiaFormatException>()),
      );
      expect(
        () => parseMutopiaLilypond(r'''
\header { title = "First" }
\header { title = "Second" }
'''),
        throwsA(isA<MutopiaFormatException>()),
      );
      expect(
        () => parseMutopiaLilypond(r'''
\version "2.18.2"
\version "2.18.3"
'''),
        throwsA(isA<MutopiaFormatException>()),
      );
      expect(
        () => parseMutopiaLilypond(r'''
\score { \header { title = "Nested header" } }
'''),
        throwsA(isA<MutopiaFormatException>()),
      );
    });

    test('rejects unsupported dynamic bodies and external dependencies', () {
      expect(
        () => parseMutopiaLilypond(r'words = \lyricmode { \unknown invented }'),
        throwsA(isA<MutopiaFormatException>()),
      );
      expect(
        () => parseMutopiaLilypond(r'words = \lyricmode { #(make-lyrics) }'),
        throwsA(isA<MutopiaFormatException>()),
      );
      expect(
        () => parseMutopiaLilypond(r'\include "external.ly"'),
        throwsA(isA<MutopiaFormatException>()),
      );
    });

    test('rejects malformed braces, trailing hyphens, and oversized input', () {
      expect(
        () => parseMutopiaLilypond('words = \\lyricmode { truncated'),
        throwsA(isA<MutopiaFormatException>()),
      );
      expect(
        () => parseMutopiaLilypond(r'words = \lyricmode { invented -- }'),
        throwsA(isA<MutopiaFormatException>()),
      );
      for (final invalidCheck in [
        r'\barNumberCheck 7.2',
        r'\barNumberCheck -7',
        r'\barNumberCheck 1000000',
        r'\barNumberCheck 999999999999999999999999',
        r'\barNumberCheck #(next-number)',
      ]) {
        expect(
          () => parseMutopiaLilypond(
            'words = \\lyricmode { $invalidCheck word }',
          ),
          throwsA(isA<MutopiaFormatException>()),
        );
      }
      expect(
        () => parseMutopiaLilypond('%{ not closed'),
        throwsA(isA<MutopiaFormatException>()),
      );
      expect(
        () => parseMutopiaLilypond(List.filled(512 * 1024 + 1, 'x').join()),
        throwsA(isA<MutopiaFormatException>()),
      );
    });

    test('enforces aggregate decoded text and stream limits', () {
      final longBody = List.filled(40000, 'ab').join(' ');
      final twoStreams =
          'first = \\lyricmode { $longBody }\n'
          'second = \\lyricmode { $longBody }';
      expect(
        () => parseMutopiaLilypond(twoStreams),
        throwsA(isA<MutopiaFormatException>()),
      );

      final manyStreams = List.generate(
        33,
        (index) => 'lyric$index = \\lyricmode { word }',
      ).join('\n');
      expect(
        () => parseMutopiaLilypond(manyStreams),
        throwsA(isA<MutopiaFormatException>()),
      );
    });
  });
}
