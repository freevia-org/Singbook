// Opt-in PDF preview: flutter test test/application/print_brand_preview.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verse_mobile/application/file_actions.dart';
import 'package:verse_mobile/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render a content-only shared lyrics preview', () async {
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
          'copyright': '© 2026 Sample Lyricist. Sample lyrics for preview.',
        },
        body:
            '{comment: Verse 1}\n[C]The room is warm tonight\n[G]We sing our own refrain\n[Am]The city fades beyond the door\n[F]We find our place again\n[E7]\n{start_of_chorus}\n[F]Carry the light through the dark\n[C]Hold every note in your heart\n[Am]When morning comes, we will still be here\n[G]Singing the song we share\n{end_of_chorus}\n{comment: Verse 2}\n[C]Our voices travel through the night\n[G]And meet beneath the morning sky\n[Am]Наші слова звучать разом\n[F]Нашите думи звучат заедно',
      ),
    ];
    final bytes = await createSongPdf(songs);
    final output = File('output/pdf/Shared-lyrics-preview.pdf');
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes);
    expect(bytes.length, greaterThan(10000));
  });
}
