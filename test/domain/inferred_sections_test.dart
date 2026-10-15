import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';

void main() {
  List<String> headings(String body) => parseArrangement(
    body,
  ).map(sectionLabelForLine).whereType<String>().toList();

  test(
    'repeated paragraphs become chorus and unique paragraphs stay verses',
    () {
      const body =
          'Morning birds\nWake the sky\n\nSing with me\nTogether now\n\n'
          'Evening stars\nLight the way\n\nSing with me\nTogether now';
      final inferred = inferSectionDirectives(body);
      expect(headings(inferred), ['Verse 1', 'Chorus', 'Verse 2', 'Chorus']);
      expect(lyricLines(inferred), lyricLines(body));
      expect(lyricOrderHash(inferred), lyricOrderHash(body));
      expect(inferSectionDirectives(inferred), inferred);
    },
  );

  test('comparison normalizes case punctuation CRLF and chords only', () {
    const body =
        '[C]Sing, WITH me!\r\n\r\nA quiet verse\r\n\r\n'
        '[G]sing with me';
    final inferred = inferSectionDirectives(body);
    expect(headings(inferred), ['Chorus', 'Verse 1', 'Chorus']);
    expect(inferred, contains('[C]Sing, WITH me!'));
    expect(inferred, contains('[G]sing with me'));
    expect(lyricOrderHash(inferred), lyricOrderHash(body));
  });

  test('unique paragraphs become separately navigable numbered verses', () {
    expect(headings(inferSectionDirectives('First light\n\nQuiet night')), [
      'Verse 1',
      'Verse 2',
    ]);
  });

  test('a single lyric block and directive-only blocks add no sections', () {
    for (final body in [
      'One line\nSecond line',
      '{title: Example}\n\nOnly lyric block\n\n{comment: credits}',
      '{title: Example}\n\n{comment: credits}',
      '[C]\n\n[G]',
    ]) {
      expect(inferSectionDirectives(body), body);
    }
  });

  test('explicit section headings and long directives are byte preserved', () {
    for (final marker in [
      '[Verse 1]',
      '{comment: Chorus}',
      '{start_of_verse: 1}',
      '{start_of_verse: Custom label}',
      '{start_of_chorus}',
      '{chorus}',
    ]) {
      final body = '$marker\r\nFirst line\r\n\r\nOther line';
      expect(inferSectionDirectives(body), body, reason: marker);
    }
  });

  test('explicit abbreviated ChordPro sections are byte preserved', () {
    for (final marker in ['soc', 'eoc', 'sov', 'eov', 'sob', 'eob']) {
      final body = '{$marker}\nFirst line\n\nOther line';
      expect(inferSectionDirectives(body), body, reason: marker);
    }
  });

  test('abbreviated starts provide navigation labels and ends do not', () {
    const body =
        '{SOV}\nOne verse\n{eov}\n\n{soc}\nSing\n{eoc}\n'
        '\n{sob}\nBridge text\n{eob}';
    expect(headings(body), ['Verse', 'Chorus', 'Bridge']);
    expect(inferSectionDirectives(body), body);
  });

  test(
    'combined inferred body preserves source provenance and word timing',
    () {
      const candidate = SongCandidate(
        providerId: 'fixture',
        id: 'one',
        title: 'Birds',
        artist: 'Example',
        durationSeconds: 30,
      );
      const body = 'Café birds\n\nQuiet sky\n\nCafé birds';
      const raw =
          '<tt><body><p begin="1s" end="3s">'
          '<span begin="0s" end="1s">Café</span> birds</p>'
          '<p begin="4s" end="6s">Quiet sky</p>'
          '<p begin="7s" end="9s">Café birds</p></body></tt>';
      final track = parseTtml(raw, sourceDocumentId: candidate.identity);
      final source = SourceResult(
        candidate: candidate,
        body: body,
        matchKind: MatchKind.sameRecording,
        timingTracks: [track],
      );
      final combined = combineSources(candidate, [source]);
      expect(headings(combined.body), ['Chorus', 'Verse 1', 'Chorus']);
      expect(combined.sources.single.body, body);
      expect(lyricOrderHash(combined.body), lyricOrderHash(body));
      final retained = combined.timingTracks.single;
      expect(retained.status, TimingStatus.usable);
      expect(combined.activeTimingTrackId, retained.id);
      expect(retained.raw, raw);
      expect(
        retained.cues.map((cue) => cue.toJson()).toList(),
        track.cues.map((cue) => cue.toJson()).toList(),
      );
      expect(
        retained.extra['binding']['occurrences'],
        timingOccurrenceMap(track, combined.body),
      );
      final codec = ChordProCodec();
      final reopened = codec.decode(codec.encode(combined));
      expect(reopened.body, combined.body);
      expect(reopened.sources.single.body, body);
      expect(reopened.timingTracks.single.raw, raw);
      expect(reopened.timingTracks.single.cues.length, retained.cues.length);
    },
  );
}
