import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS clipboard preserves song and setlist plain text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('iOS clipboard QA'))),
    );
    await tester.pumpAndSettle();
    final song = SongDocument(
      id: 'ios-clipboard',
      title: 'Original iOS fixture',
      artist: 'Freevia QA',
      body: '[C]A lantern lights the road\n[G]We sing a new refrain',
    );
    final files = VerseFileActions();
    await files.copySong(song);
    final copiedSong = await Clipboard.getData('text/plain');
    expect(copiedSong?.text, contains('A lantern lights the road'));
    expect(copiedSong?.text, isNot(contains('{title:')));
    final setlist = SetlistDocument(
      id: 'ios-setlist',
      name: 'Original iOS setlist',
      entries: [
        SetlistEntry(id: 'first', songId: song.id),
        SetlistEntry(id: 'second', songId: song.id),
      ],
    );
    await files.copySetlist(setlist, [song]);
    final copiedSetlist = await Clipboard.getData('text/plain');
    expect(copiedSetlist?.text, startsWith(setlist.name));
    expect(
      RegExp('A lantern lights the road').allMatches(copiedSetlist!.text!),
      hasLength(2),
    );
  }, skip: !Platform.isIOS);

  testWidgets('iOS native PDF renderer handles the exported song', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final song = SongDocument(
        id: 'ios-pdf',
        title: 'Original PDF fixture',
        artist: 'Freevia QA',
        body: '[C]A lantern lights the road\n[G]We sing a new refrain',
      );
      final bytes = await createSongPdf([song]);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/singbook-ios-pdf-qa.pdf');
      try {
        await file.writeAsBytes(bytes, flush: true);
        final page = await Printing.raster(
          await file.readAsBytes(),
          pages: [0],
          dpi: 72,
        ).first;
        expect(page.width, greaterThan(100));
        expect(page.height, greaterThan(100));
        expect(await page.toPng(), isNotEmpty);
      } finally {
        if (await file.exists()) await file.delete();
      }
    });
  }, skip: !Platform.isIOS);
}
