// Opt-in PDF preview: flutter test test/application/print_brand_preview.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render a setlist PDF preview with populated and sparse metadata', () async {
    final songs = [
      SongDocument(
        id: 'print-one',
        title: 'Small Hours',
        artist: 'Sample Artist',
        metadata: const {
          'album': 'Sample Album',
          'year': 2026,
          'key': 'C',
          'capo': 2,
          'tuning': 'Standard',
          'tempo': 92,
          'timeSignature': '4/4',
          'durationSeconds': 184,
          'composer': 'Sample Composer',
          'lyricist': 'Sample Lyricist',
          'copyright': 'UNVERIFIED_CREDIT_SHOULD_NOT_PRINT',
        },
        body:
            '{comment: Verse 1}\n[C]The room is warm tonight\n[G]We sing our own refrain\n[Am]The city fades beyond the door\n[F]We find our place again\n[E7]\n{start_of_chorus}\n[F]Carry the light through the dark\n[C]Hold every note in your heart\n[Am]When morning comes, we will still be here\n[G]Singing the song we share\n{end_of_chorus}\n{comment: Verse 2}\n[C]Our voices travel through the night\n[G]And meet beneath the morning sky\n[Am]Наші слова звучать разом\n[F]Нашите думи звучат заедно',
      ),
      SongDocument(
        id: 'print-two',
        title: 'Morning Sky',
        artist: '',
        body:
            '{comment: Verse 1}\n[G]The first light finds the avenue\n[D]A quiet day is coming through\n[Em]We raise our voices, clear and bright\n[C]And greet the morning light\n\n{start_of_chorus}\n[G]Sing on, sing on\n[D]The night is gone\n[Em]Our song will carry on\n[C]Sing on, sing on\n{end_of_chorus}',
      ),
    ];
    final setlist = SetlistDocument(
      id: 'sample-setlist',
      name: 'Evening Set',
      notes: 'A short acoustic set',
      entries: const [
        SetlistEntry(id: 'entry-one', songId: 'print-one'),
        SetlistEntry(id: 'entry-two', songId: 'print-two'),
      ],
    );
    final bytes = await createSongPdf(songs, setlist: setlist);
    final output = File('output/pdf/Setlist-preview.pdf');
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes);
    expect(bytes.length, greaterThan(10000));

    final standaloneBytes = await createSongPdf([songs.first]);
    final standaloneOutput = File('output/pdf/Standalone-song-review.pdf');
    await standaloneOutput.parent.create(recursive: true);
    await standaloneOutput.writeAsBytes(standaloneBytes);

    final emptySetlist = SetlistDocument(
      id: 'empty-setlist',
      name: 'Empty Set',
      notes: 'Songs can be added later.',
      entries: const [],
    );
    final emptyBytes = await createSongPdf([], setlist: emptySetlist);
    final emptyOutput = File('output/pdf/Empty-setlist-review.pdf');
    await emptyOutput.parent.create(recursive: true);
    await emptyOutput.writeAsBytes(emptyBytes);
    expect(emptyBytes.length, greaterThan(1000));

    final longListSongs = List.generate(
      12,
      (index) => songs[index % songs.length].copyWith(
        id: 'long-list-${index + 1}',
        title:
            'Song ${index + 1}: A Longer Song Title That Wraps Comfortably on the Setlist Page',
      ),
    );
    final longList = SetlistDocument(
      id: 'long-list',
      name: 'Long Evening Set',
      entries: [
        for (var i = 0; i < longListSongs.length; i++)
          SetlistEntry(
            id: 'long-list-entry-${i + 1}',
            songId: longListSongs[i].id,
          ),
      ],
    );
    final longListOutput = File('output/pdf/Long-setlist-cover-review.pdf');
    await longListOutput.parent.create(recursive: true);
    await longListOutput.writeAsBytes(
      await createSongPdf(longListSongs, setlist: longList),
    );

    final longText = List.filled(450, 'melody').join(' ');
    final longSong = SongDocument(
      id: 'long-song',
      title: 'A Longer Song for Pagination Review',
      artist: 'Sample Artist with a Longer Display Name',
      metadata: {
        'album': 'BEGIN_LONG_METADATA $longText END_LONG_METADATA',
        'year': 2026,
        'key': 'C sharp minor',
        'capo': 4,
        'tuning': 'D A D G A D alternate tuning',
        'tempo': 92,
        'timeSignature': '12/8',
        'durationSeconds': 284,
        'composer': 'A Composer with a Longer Name',
        'lyricist': 'A Lyricist with a Longer Name',
      },
      body:
          '[C]BEGIN_LONG_LYRIC $longText [G]MIDDLE_LONG_LYRIC $longText [Am]END_LONG_LYRIC\n${List.generate(52, (i) => '[C]Line ${i + 1} carries the melody across the quiet night').join('\n')}',
    );
    final longBytes = await createSongPdf([longSong]);
    final longOutput = File('output/pdf/Setlist-long-song-review.pdf');
    await longOutput.parent.create(recursive: true);
    await longOutput.writeAsBytes(longBytes);
    for (final entry in {
      'a5': PdfPageFormat.a5,
      'letter': PdfPageFormat.letter,
    }.entries) {
      await File(
        'output/pdf/Long-song-${entry.key}-review.pdf',
      ).writeAsBytes(await createSongPdf([longSong], format: entry.value));
    }
  });
}
