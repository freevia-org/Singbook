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

  testWidgets(
    'iOS Keychain isolates, updates and deletes file grants',
    (tester) async {
      const channel = MethodChannel('org.freevia.singbook/secure_credentials');
      final key = 'qa-file-grant-${DateTime.now().microsecondsSinceEpoch}';
      addTearDown(() => channel.invokeMethod<void>('delete', {'key': key}));
      expect(await channel.invokeMethod<String>('read', {'key': key}), isNull);
      await channel.invokeMethod<void>('write', {
        'key': key,
        'value': 'original-qa-only',
      });
      expect(
        await channel.invokeMethod<String>('read', {'key': key}),
        'original-qa-only',
      );
      await channel.invokeMethod<void>('write', {
        'key': key,
        'value': 'updated-qa-only',
      });
      expect(
        await channel.invokeMethod<String>('read', {'key': key}),
        'updated-qa-only',
      );
      await channel.invokeMethod<void>('delete', {'key': key});
      expect(await channel.invokeMethod<String>('read', {'key': key}), isNull);
    },
    skip: !Platform.isIOS,
  );

  testWidgets(
    'iOS OAuth rejects unconfigured callbacks without opening browser',
    (tester) async {
      const channel = MethodChannel('org.freevia.singbook/oauth_browser');
      await expectLater(
        channel.invokeMethod<String>('authorize', {
          'url': 'https://accounts.google.com/o/oauth2/v2/auth',
          'callbackScheme': 'unregistered-qa-scheme',
        }),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'not_configured',
          ),
        ),
      );
    },
    skip: !Platform.isIOS,
  );

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
    const clipboardChannel = MethodChannel(
      'org.freevia.singbook/rich_clipboard',
    );
    await files.copySong(song);
    final songReceipt = await clipboardChannel.invokeMapMethod<String, dynamic>(
      'debugClipboardReceipt',
    );
    expect(
      songReceipt?['storedTypes'],
      containsAll(['public.plain-text', 'public.html']),
    );
    expect(songReceipt?['plainText'], songPlainText(song));
    expect(songReceipt?['html'], songRichHtml(song));
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
    final setlistReceipt = await clipboardChannel
        .invokeMapMethod<String, dynamic>('debugClipboardReceipt');
    expect(
      setlistReceipt?['storedTypes'],
      containsAll(['public.plain-text', 'public.html']),
    );
    expect(setlistReceipt?['plainText'], setlistPlainText(setlist, [song]));
    expect(setlistReceipt?['html'], setlistRichHtml(setlist, [song]));
    final copiedSetlist = await Clipboard.getData('text/plain');
    expect(copiedSetlist?.text, startsWith(setlist.name));
    expect(
      RegExp('A lantern lights the road').allMatches(copiedSetlist!.text!),
      hasLength(2),
    );
    await expectLater(
      clipboardChannel.invokeMethod<void>('setHtmlText', {
        'text': 'missing html',
      }),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'invalid_arguments',
        ),
      ),
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
