// Opt-in print canary: flutter test test/application/print_brand_preview.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verse_mobile/application/file_actions.dart';
import 'package:verse_mobile/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'render the Singbook print brand with original multilingual fixtures',
    () async {
      final songs = [
        SongDocument(
          id: 'print-one',
          title: 'Small Hours / Тихі години',
          artist: 'Freevia Test',
          body:
              '{start_of_verse}\n[C]The room is warm tonight\n[G]We sing our own refrain\n\n[Am]Наші слова звучать разом\n[F]Нашите думи звучат заедно\n{end_of_verse}',
        ),
        SongDocument(
          id: 'print-two',
          title: 'Morning Light / Утринна светлина',
          artist: 'Freevia Test',
          body:
              '[D]An open window lets the daylight in\n[A]We turn the page and start again',
        ),
      ];
      final bytes = await createSongPdf(
        songs,
        setlist: SetlistDocument(
          id: 'print-set',
          name: 'Songs to share / Пісні разом',
          notes: 'An original setlist for Singbook print validation.',
        ),
      );
      final output = File('artifacts/Singbook-print-preview.pdf');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes);
      expect(bytes.length, greaterThan(10000));
    },
  );
}
