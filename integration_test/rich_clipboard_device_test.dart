import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android clipboard advertises rich HTML and plain text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Clipboard QA'))),
    );
    await tester.pumpAndSettle();
    final files = VerseFileActions();
    final song = SongDocument(
      id: 'qa-clipboard',
      title: 'Original clipboard fixture',
      artist: 'QA',
      body: '[C]An original line\n[G]Another original line',
    );
    await files.copySong(song);
    final types = await const MethodChannel(
      'org.freevia.singbook/rich_clipboard',
    ).invokeListMethod<String>('debugMimeTypes');
    final receipt = await const MethodChannel(
      'org.freevia.singbook/rich_clipboard',
    ).invokeMapMethod<String, dynamic>('debugWriteReceipt');
    debugPrint('CLIPBOARD_NATIVE_RECEIPT $receipt; retainedTypes=$types');
    expect(types, containsAll(['text/plain', 'text/html']));
    final text = await Clipboard.getData('text/plain');
    expect(text?.text?.contains('An original line') ?? false, isTrue);
    expect(text?.text?.contains('{title:') ?? false, isFalse);
    final setlist = SetlistDocument(
      id: 'qa-setlist',
      name: 'QA setlist',
      entries: [
        SetlistEntry(id: 'one', songId: song.id),
        SetlistEntry(id: 'two', songId: song.id),
      ],
    );
    await files.copySetlist(setlist, [song]);
    final setText = await Clipboard.getData('text/plain');
    expect(setText?.text?.startsWith('QA setlist') ?? false, isTrue);
    expect(RegExp('An original line').allMatches(setText!.text!).length, 2);
    expect(
      await const MethodChannel(
        'org.freevia.singbook/rich_clipboard',
      ).invokeListMethod<String>('debugMimeTypes'),
      contains('text/html'),
    );
  });
}
