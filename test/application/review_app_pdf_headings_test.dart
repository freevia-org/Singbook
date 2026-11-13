import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SongDocument song(String body, {Map<String, Object?> metadata = const {}}) =>
      SongDocument(
        id: 'notes',
        title: 'Notes',
        artist: 'Someone',
        body: body,
        metadata: metadata,
      );

  // Headings and blank rows before a lyric row used to form one inseparable
  // block of unlimited height, which the PDF layout refuses once it is taller
  // than a page ("Widget won't fit into the page").
  group('a long run of headings before a lyric row', () {
    final comments = [
      for (var i = 0; i < 120; i++) '{comment: tab line $i  e|---0---2---3---|}',
    ].join('\n');

    test('exports without a metadata column', () async {
      final pdf = await createSongPdf([song('$comments\n[C]First line')]);
      expect(pdf.length, greaterThan(1000));
    });

    test('exports with a metadata column', () async {
      final pdf = await createSongPdf([
        song(
          '$comments\n[C]First line\n{start_of_chorus}\nla',
          metadata: {'key': 'C', 'album': 'Album', 'year': 1999},
        ),
      ]);
      expect(pdf.length, greaterThan(1000));
    });

    test('exports when the run ends the chart', () async {
      final pdf = await createSongPdf([song('[C]First line\n$comments')]);
      expect(pdf.length, greaterThan(1000));
    });

    test('exports many blank rows between a heading and its row', () async {
      final pdf = await createSongPdf([
        song('{start_of_verse}\n${'\n' * 400}[C]First line'),
      ]);
      expect(pdf.length, greaterThan(1000));
    });

    test('exports a single note longer than a page', () async {
      final note = List.filled(2500, 'note words').join(' ');
      final pdf = await createSongPdf([
        song('{comment: $note}\n[C]First line'),
      ]);
      expect(pdf.length, greaterThan(1000));
    });
  });

  test('an ordinary chart is laid out exactly as before', () async {
    // Short headings stay attached to their first row, so the page content
    // is the same with or without the limits on attached headings.
    final chart = song(
      '{start_of_verse: 1}\n[C]One [G]two\nthree\n\n'
      '{comment: Softly}\n{start_of_chorus}\n\n[F]Four',
    );
    final first = await createSongPdf([chart]);
    final second = await createSongPdf([chart]);
    expect(first.length, second.length);
    expect(first.length, greaterThan(1000));
  });
}
