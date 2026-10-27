import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

const _selected = SongCandidate(
  providerId: 'catalog',
  id: 'song',
  title: 'Quiet Harbor',
  artist: 'Example Artist',
  recordingIds: {'isrc': 'US-AAA-26-00001'},
);

SourceResult _source(
  String provider,
  String body, {
  MatchKind kind = MatchKind.sameSong,
  bool recording = false,
}) => SourceResult(
  candidate: SongCandidate(
    providerId: provider,
    id: 'song',
    title: 'Quiet Harbor',
    artist: 'Example Artist',
    recordingIds: recording ? {'isrc': 'US-AAA-26-00001'} : const {},
  ),
  body: body,
  matchKind: kind,
);

String _flatten(String lyrics) => lyrics.replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  test('maps adjacent short chart lines into their joined lyric paragraph', () {
    const lyrics = 'Amber lanterns glow above the quiet harbor tonight';
    const chart = '[C]Amber lanterns\n[G]glow above\n[Am]the quiet\n[F]harbor';
    final combined = combineSources(_selected, [
      _source('lyrics', lyrics),
      _source('chart', chart),
    ]);
    expect(_flatten(plainLyrics(combined.body)), _flatten(lyrics));
    final lines = parseArrangement(combined.body);
    expect(lines.single.chords.map((a) => (a.chord, a.offset)).toList(), [
      ('C', lyrics.indexOf('Amber')),
      ('G', lyrics.indexOf('glow')),
      ('Am', lyrics.indexOf('the')),
      ('F', lyrics.indexOf('harbor')),
    ]);
    expect(combined.extra['chordSourceIds'], isNotEmpty);
  });

  test('a chord after a short donor row stays after that row when joined', () {
    const lyrics = 'Amber lanterns glow above quiet water tonight';
    const chart = '[C]Amber lanterns[G]\n[Am]glow above [F]quiet water tonight';
    final combined = combineSources(_selected, [
      _source('lyrics', lyrics),
      _source('chart', chart),
    ]);
    expect(_flatten(plainLyrics(combined.body)), _flatten(lyrics));
    final lines = parseArrangement(combined.body);
    final positions = <String, bool>{};
    for (final line in lines) {
      for (final anchor in line.chords) {
        positions[anchor.chord] = switch (anchor.chord) {
          'C' => line.text.startsWith('Amber') && anchor.offset == 0,
          'G' =>
            line.text.endsWith('lanterns') && anchor.offset == line.text.length,
          'Am' => line.text.startsWith('glow') && anchor.offset == 0,
          'F' => anchor.offset == line.text.indexOf('quiet'),
          _ => false,
        };
      }
    }
    expect(positions, {'C': true, 'G': true, 'Am': true, 'F': true});
  });

  test('long charts retain short-row context across the full song', () {
    final lyricLines = <String>[];
    final chartRows = <String>[];
    for (var section = 0; section < 80; section++) {
      final words = List.generate(16, (word) => 'section${section}word$word');
      lyricLines.add(words.join(' '));
      for (var row = 0; row < words.length; row += 2) {
        chartRows.add('[C]${words[row]} [G]${words[row + 1]}');
      }
    }
    final lyrics = lyricLines.join('\n');
    final combined = combineSources(_selected, [
      _source('lyrics', lyrics, kind: MatchKind.sameRecording, recording: true),
      _source('chart', chartRows.join('\n')),
    ]);
    expect(_flatten(plainLyrics(combined.body)), _flatten(lyrics));
    final placed = parseArrangement(combined.body);
    final contentLines = placed.where((line) => line.text.trim().isNotEmpty);
    expect(contentLines.first.chords, isNotEmpty);
    expect(contentLines.last.chords, isNotEmpty);
  });

  test('maps an eight-row chart context onto three joined lyric lines', () {
    const first =
        'Amber lanterns shimmer above quiet water while distant bells carry softly across the valley at sunrise again';
    const second =
        'Silver windows reflect golden sunlight as gentle breezes move through gardens beside old stone bridges each morning';
    final words = [...first.split(' '), ...second.split(' ')];
    expect(words, hasLength(34));
    final lyrics =
        '${words.take(11).join(' ')}\n'
        '${words.skip(11).take(12).join(' ')}\n'
        '${words.skip(23).join(' ')}\n'
        'always';
    const lengths = [2, 4, 5, 6, 2, 4, 5, 6];
    const chords = ['C', 'G', 'Am', 'F', 'C', 'G', 'Am', 'F'];
    var cursor = 0;
    final chartRows = <String>[];
    for (var i = 0; i < lengths.length; i++) {
      final row = words.skip(cursor).take(lengths[i]).join(' ');
      final rowWords = row.split(' ');
      chartRows.add(
        '[${chords[i]}]${rowWords.take(rowWords.length - 1).join(' ')} '
        '[${chords[(i + 1) % chords.length]}]${rowWords.last}',
      );
      cursor += lengths[i];
    }
    final chart = chartRows.join('\n');
    final combined = combineSources(_selected, [
      _source('lyrics', lyrics, kind: MatchKind.sameRecording, recording: true),
      _source('chart', chart),
    ]);
    expect(plainLyrics(combined.body), lyrics);
    final placed = parseArrangement(combined.body);
    expect(placed.take(3).map((line) => line.chords.length), [6, 6, 4]);
    expect(placed.last.chords, isEmpty);
    final targetLines = lyrics.split('\n');
    final targetLocations = <(int, int)>[];
    for (var lineIndex = 0; lineIndex < targetLines.length; lineIndex++) {
      for (final word in RegExp(r'\S+').allMatches(targetLines[lineIndex])) {
        targetLocations.add((lineIndex, word.start));
      }
    }
    final expectedAnchors = <(String, int, int)>{};
    cursor = 0;
    for (var i = 0; i < lengths.length; i++) {
      for (final chordAtWord in [
        (chords[i], cursor),
        (chords[(i + 1) % chords.length], cursor + lengths[i] - 1),
      ]) {
        final (lineIndex, offset) = targetLocations[chordAtWord.$2];
        expectedAnchors.add((chordAtWord.$1, lineIndex, offset));
      }
      cursor += lengths[i];
    }
    final actualAnchors = <(String, int, int)>{};
    for (var lineIndex = 0; lineIndex < placed.length; lineIndex++) {
      actualAnchors.addAll(
        placed[lineIndex].chords.map(
          (anchor) => (anchor.chord, lineIndex, anchor.offset),
        ),
      );
    }
    expect(actualAnchors, expectedAnchors);
    expect(combined.extra['chordSourceIds'], ['chart:song']);
  });

  test('contexts stop at directives and blank lines', () {
    const target = 'amber lanterns shimmer above quiet water tonight always';
    for (final boundary in ['{comment: Verse}', '']) {
      final chart =
          '[C]amber lanterns\n[G]shimmer above\n$boundary\n'
          '[Am]quiet water\n[F]tonight';
      final combined = combineSources(_selected, [
        _source('lyrics', target),
        _source('chart', chart),
      ]);
      expect(plainLyrics(combined.body), target);
      expect(combined.hasChords, isFalse, reason: 'boundary=$boundary');
    }
  });

  test('a shared short fragment cannot place chords inside a longer line', () {
    const target = 'amber lanterns shimmer above quiet water tonight';
    final combined = combineSources(_selected, [
      _source('lyrics', target),
      _source('chart', '[C]amber lanterns'),
    ]);
    expect(plainLyrics(combined.body), target);
    expect(combined.hasChords, isFalse);
  });

  test('non-plain grapheme offsets do not enter adjacent contexts', () {
    const target = 'amber lanterns shimmer above quiet water tonight always 🎵';
    const chart =
        '[C]amber lanterns\n[G]shimmer above\n[Am]quiet water\n[F]tonight 🎵';
    final combined = combineSources(_selected, [
      _source('lyrics', target),
      _source('chart', chart),
    ]);
    expect(plainLyrics(combined.body), target);
    expect(combined.hasChords, isFalse);
  });

  test('repeated contexts with different harmonies remain unresolved', () {
    const passage =
        'Amber lanterns shimmer above quiet water while distant bells carry';
    const target = '$passage\n$passage tonight';
    const chart =
        '[C]Amber lanterns shimmer above quiet water [G]while distant bells carry\n'
        '[D]Amber lanterns shimmer above quiet water [A]while distant bells carry';
    final combined = combineSources(_selected, [
      _source('lyrics', target),
      _source('chart', chart),
    ]);
    expect(plainLyrics(combined.body), target);
    expect(combined.hasChords, isFalse);
  });
}
