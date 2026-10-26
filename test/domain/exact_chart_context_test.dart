import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

// Invented text; the selected recording's wording is always authoritative.
const _words =
    'Amber lanterns shimmer above quiet water while distant bells '
    'carry softly across the valley at sunrise again Silver windows reflect '
    'golden sunlight as gentle breezes move through gardens beside old stone '
    'bridges each morning';
const _selected = SongCandidate(
  providerId: 'lyrics',
  id: 'recording',
  title: 'Harbor',
  artist: 'Example',
  recordingIds: {'isrc': 'USAAA2600001'},
);

String _lyrics() {
  final words = _words.split(' ');
  return '${words.take(11).join(' ')}\n'
      '${words.skip(11).take(12).join(' ')}\n'
      '${words.skip(23).join(' ')}\n\n'
      'Later the sailors gather near the lighthouse and welcome every traveler home';
}

String _chart({String firstChord = 'C', bool boundary = false}) {
  final words = _words.split(' ');
  const lengths = [2, 4, 5, 6, 2, 4, 5, 6];
  const chords = ['C', 'G', 'Am', 'F', 'C', 'G', 'Am', 'F'];
  var at = 0;
  final rows = <String>[];
  for (var i = 0; i < lengths.length; i++) {
    if (boundary && i == 4) rows.add('{comment: distinct section}');
    rows.add(
      '[${i == 0 ? firstChord : chords[i]}]'
      '${words.skip(at).take(lengths[i]).join(' ')}',
    );
    at += lengths[i];
  }
  return rows.join('\n');
}

SongDocument _combine(String lyrics, String chart) =>
    combineSources(_selected, [
      SourceResult(
        candidate: _selected,
        body: lyrics,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'chart',
          id: 'chart',
          title: 'Harbor',
          artist: 'Example',
        ),
        body: chart,
        matchKind: MatchKind.sameSong,
      ),
    ]);

void main() {
  test(
    'whole adjacent contexts recover chords across provider line breaks',
    () {
      final lyrics = _lyrics();
      final combined = _combine(lyrics, _chart());
      expect(plainLyrics(combined.body), plainLyrics(lyrics));
      expect(parseArrangement(combined.body).expand((l) => l.chords).length, 8);
    },
  );
  test('identical complete contexts can repeat with the same harmony', () {
    final lyrics = '${_lyrics()}\n\n${_lyrics()}';
    final combined = _combine(lyrics, _chart());
    expect(plainLyrics(combined.body), plainLyrics(lyrics));
    expect(parseArrangement(combined.body).expand((l) => l.chords).length, 16);
  });
  test('a word change cannot borrow the short first-row chord', () {
    final lyrics = _lyrics().replaceFirst('Amber', 'Different');
    final combined = _combine(lyrics, _chart());
    final first = parseArrangement(
      combined.body,
    ).firstWhere((l) => l.text.contains('Different lanterns'));
    expect(first.chords.where((c) => c.offset == 0), isEmpty);
    expect(plainLyrics(combined.body), plainLyrics(lyrics));
  });
  test('a bracketed section label is not a sung context word', () {
    const lyrics =
        'Amber lanterns glow above quiet water bridge gentle sailors cross the harbor tonight';
    const chart =
        '[C]Amber lanterns\n[G]glow above quiet water\n[Bridge]\n[Am]gentle sailors cross the harbor tonight';
    final combined = _combine(lyrics, chart);
    final line = parseArrangement(
      combined.body,
    ).firstWhere((l) => l.text.contains('Amber lanterns'));
    expect(line.chords.where((anchor) => anchor.offset == 0), isEmpty);
    expect(plainLyrics(combined.body), lyrics);
  });
  test('non-plain grapheme contexts retain safe existing placements only', () {
    final lyrics = _lyrics()
        .split('\n')
        .map((line) => line.isEmpty ? line : '🎵 $line')
        .join('\n');
    final combined = _combine(lyrics, _chart());
    final first = parseArrangement(
      combined.body,
    ).firstWhere((l) => l.text.contains('Amber lanterns'));
    expect(first.chords.where((c) => c.offset <= 2 && c.chord == 'C'), isEmpty);
    expect(plainLyrics(combined.body), plainLyrics(lyrics));
  });
  test('conflicting source occurrences do not invent a first chord', () {
    final combined = _combine(
      _lyrics(),
      '${_chart()}\n\n${_chart(firstChord: 'D')}',
    );
    expect(plainLyrics(combined.body), plainLyrics(_lyrics()));
    expect(
      parseArrangement(combined.body).first.chords.where((c) => c.offset == 0),
      isEmpty,
    );
  });
  test('a source section boundary cannot be crossed to complete context', () {
    final combined = _combine(_lyrics(), _chart(boundary: true));
    expect(plainLyrics(combined.body), plainLyrics(_lyrics()));
    expect(
      parseArrangement(combined.body).first.chords.where((c) => c.offset == 0),
      isEmpty,
    );
  });
  test('trailing source chord stays after its own word in a joined line', () {
    final chart = _chart().replaceFirst(
      'Amber lanterns\n',
      'Amber lanterns[D]\n',
    );
    final combined = _combine(_lyrics(), chart);
    final first = parseArrangement(
      combined.body,
    ).firstWhere((l) => !l.directive && l.text.contains('Amber lanterns'));
    final trailing = first.text.indexOf('lanterns') + 'lanterns'.length;
    expect(
      first.chords.map((a) => '${a.offset}:${a.chord}'),
      contains('$trailing:D'),
    );
    expect(plainLyrics(combined.body), plainLyrics(_lyrics()));
  });
  test(
    'overlapping source intervals cannot support different target contexts',
    () {
      final words =
          '$_words Pale clouds wander beyond mountain ridges while small birds awaken under bright stars before dawn returns again'
              .split(' ');
      expect(words, hasLength(51));
      const lengths = [2, 4, 5, 6, 2, 4, 5, 6, 2, 4, 5, 6];
      final chart = <String>[];
      var cursor = 0;
      for (final length in lengths) {
        chart.add('[C]${words.skip(cursor).take(length).join(' ')}');
        cursor += length;
      }
      String wrap(int start) =>
          '${words.skip(start).take(11).join(' ')}\n'
          '${words.skip(start + 11).take(12).join(' ')}\n'
          '${words.skip(start + 23).take(11).join(' ')}';
      final lyrics = '${wrap(0)}\n\n${wrap(17)}';
      final combined = _combine(lyrics, chart.join('\n'));
      final lines = parseArrangement(
        combined.body,
      ).where((l) => !l.directive && l.text.trim().isNotEmpty).toList();
      expect(lines.first.chords.any((a) => a.offset == 0), isTrue);
      expect(
        lines[3].chords.map((a) => '${a.offset}:${a.chord}'),
        isNot(contains('0:C')),
      );
      expect(plainLyrics(combined.body), plainLyrics(lyrics));
    },
  );
}
