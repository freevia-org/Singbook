import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';

void main() {
  test(
    'Android saveBackupBytes uses the save dialog, not the share sheet',
    () async {
      final calls = <({String name, Uint8List bytes, String mime})>[];
      final files = VerseFileActions(
        platform: TargetPlatform.android,
        saveFile:
            ({required fileName, required bytes, required mimeType}) async {
              calls.add((name: fileName, bytes: bytes, mime: mimeType));
              return Uri.parse('content://documents/backup');
            },
        shareFiles: (_) async => throw StateError('must not share'),
      );

      final uri = await files.saveBackupBytes(Uint8List.fromList([1, 2, 3]));

      expect(uri, Uri.parse('content://documents/backup'));
      expect(
        calls.single.name,
        matches(r'^Singbook-\d{4}-\d{2}-\d{2}\.lyrics-setlist$'),
      );
      expect(calls.single.bytes, [1, 2, 3]);
      expect(calls.single.mime, 'application/zip');
    },
  );

  test('dismissed save dialog returns null', () async {
    final files = VerseFileActions(
      platform: TargetPlatform.android,
      saveFile:
          ({required fileName, required bytes, required mimeType}) async =>
              null,
    );
    expect(await files.saveBackupBytes(Uint8List(1)), isNull);
  });
}
