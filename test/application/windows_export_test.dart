import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:share_plus/share_plus.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';

class _SavedExport {
  _SavedExport(this.name, this.bytes, this.mime);
  final String name;
  final Uint8List bytes;
  final String mime;
}

/// Models file_picker's contract: null cancels without writing, and a saved
/// URI is returned only after its byte write has completed.
class _SaveDialog {
  _SaveDialog(this.directory);
  final Directory directory;
  final calls = <_SavedExport>[];
  bool cancel = false;
  Object? error;

  Future<Uri?> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    calls.add(_SavedExport(fileName, Uint8List.fromList(bytes), mimeType));
    if (error case final failure?) throw failure;
    if (cancel) return null;
    final file = File(paths.join(directory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.uri;
  }
}

class _FilePickerSave extends FilePickerPlatform {
  _FilePickerSave(this.dialog);
  final _SaveDialog dialog;

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) => dialog.save(fileName: fileName, bytes: bytes, mimeType: mimeType);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  late _SaveDialog dialog;
  late VerseFileActions files;

  final song = SongDocument(
    id: 'windows-export-song',
    title: 'Світло 夜',
    artist: 'Freevia fixture',
    metadata: const {'key': 'Em', 'capo': 2},
    body:
        '{start_of_intro}\n[Em] [C]\n{end_of_intro}\n\n'
        '{start_of_verse: 1}\n[Em]Світло вночі\n{end_of_verse}\n\n'
        '{start_of_chorus}\n[C]Наші слова\n{end_of_chorus}',
  );
  final setlist = SetlistDocument(
    id: 'windows-export-setlist',
    name: 'Вечірній сет',
    notes: 'Preserve complete backup notes',
    entries: const [
      SetlistEntry(id: 'first', songId: 'windows-export-song'),
      SetlistEntry(
        id: 'repeat',
        songId: 'windows-export-song',
        overrides: {'key': 'G', 'capo': 1},
      ),
    ],
  );

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('singbook-export-');
    final destination = Directory(paths.join(temporary.path, 'Пісні 夜'));
    await destination.create();
    dialog = _SaveDialog(destination);
    files = VerseFileActions(
      platform: TargetPlatform.windows,
      saveFile: dialog.save,
      temporaryDirectory: () async =>
          throw StateError('Windows Save As must not create share cache files'),
      shareFiles: (_) async =>
          throw StateError('Windows Save As must not open the share sheet'),
    );
  });

  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  Future<Uint8List> savedBytes(ShareResult result) async {
    expect(result.status, ShareResultStatus.success);
    final uri = Uri.parse(result.raw);
    expect(uri.scheme, 'file');
    final file = File.fromUri(uri);
    expect(file.parent.path, dialog.directory.path);
    final actual = await file.readAsBytes();
    expect(actual, orderedEquals(dialog.calls.single.bytes));
    return actual;
  }

  test(
    'Windows default delegates Save As to the installed file_picker API',
    () async {
      final originalPlatform = debugDefaultTargetPlatformOverride;
      final originalPicker = FilePickerPlatform.instance;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = originalPlatform;
        FilePickerPlatform.instance = originalPicker;
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      FilePickerPlatform.instance = _FilePickerSave(dialog);
      final native = VerseFileActions(
        shareFiles: (_) async => throw StateError('Windows must save locally'),
      );
      final bytes = await savedBytes(await native.shareSong(song));
      expect(bytes, orderedEquals(utf8.encode(ChordProCodec().encode(song))));
    },
  );

  test('Windows saves complete ChordPro bytes to a Unicode filename', () async {
    final result = await files.shareSong(song);
    final bytes = await savedBytes(result);
    expect(dialog.calls.single.name, '${song.title}.cho');
    expect(dialog.calls.single.mime, 'text/plain');
    expect(bytes, orderedEquals(utf8.encode(ChordProCodec().encode(song))));
    final decoded = ChordProCodec().decode(utf8.decode(bytes));
    expect(decoded.title, song.title);
    expect(decoded.body, song.body);
    expect(decoded.metadata['key'], 'Em');
  });

  test('Windows saves exact ordered setlist references with .osts', () async {
    final result = await files.shareSetlist(setlist, [song]);
    final bytes = await savedBytes(result);
    expect(dialog.calls.single.name, '${setlist.name}.osts');
    expect(dialog.calls.single.mime, 'application/xml');
    expect(
      bytes,
      orderedEquals(utf8.encode(encodeSetlistReferences(setlist, [song]))),
    );
  });

  test('Windows saves the generated song PDF bytes', () async {
    final bytes = await savedBytes(await files.shareSongPdf(song));
    expect(dialog.calls.single.name, '${song.title}.pdf');
    expect(dialog.calls.single.mime, 'application/pdf');
    final pdf = latin1.decode(bytes);
    expect(pdf, startsWith('%PDF-'));
    expect(pdf.trimRight(), endsWith('%%EOF'));
    expect(pdf, contains('/Count 1'));
  });

  test('Windows saves a PDF cover plus each repeated setlist entry', () async {
    final bytes = await savedBytes(
      await files.shareSetlistPdf(setlist, [song]),
    );
    expect(dialog.calls.single.name, '${setlist.name}.pdf');
    expect(dialog.calls.single.mime, 'application/pdf');
    final pdf = latin1.decode(bytes);
    expect(pdf, startsWith('%PDF-'));
    expect(pdf.trimRight(), endsWith('%%EOF'));
    expect(pdf, contains('/Count 3'));
  });

  test('Windows saves supplied full-backup bytes unchanged', () async {
    final package = encodeLibraryPackage([song], [setlist]);
    final bytes = await savedBytes(await files.shareBackupBytes(package));
    expect(
      dialog.calls.single.name,
      matches(RegExp(r'^Singbook-\d{4}-\d{2}-\d{2}\.lyrics-setlist$')),
    );
    expect(dialog.calls.single.mime, 'application/zip');
    expect(bytes, orderedEquals(package));
  });

  test('Windows generated backup restores songs and setlist entries', () async {
    final bytes = await savedBytes(await files.shareBackup([song], [setlist]));
    final restored = decodeLibraryPackage(bytes);
    expect(restored.songs.single.id, song.id);
    expect(restored.songs.single.body, song.body);
    expect(restored.setlists.single.id, setlist.id);
    expect(restored.setlists.single.notes, setlist.notes);
    expect(restored.setlists.single.entries.map((entry) => entry.id), [
      'first',
      'repeat',
    ]);
    expect(restored.setlists.single.entries.last.overrides, {
      'key': 'G',
      'capo': 1,
    });
  });

  test('canceling Save As does not save, share, or report success', () async {
    dialog.cancel = true;
    final result = await files.shareSong(song);
    expect(dialog.calls, hasLength(1));
    expect(result.status, ShareResultStatus.dismissed);
    expect(result.raw, isEmpty);
    expect(await dialog.directory.list().toList(), isEmpty);
  });

  test(
    'Save As write failure propagates without sharing or reporting success',
    () async {
      dialog.error = FileSystemException('Read-only destination');
      await expectLater(
        files.shareSong(song),
        throwsA(isA<FileSystemException>()),
      );
      expect(dialog.calls, hasLength(1));
      expect(await dialog.directory.list().toList(), isEmpty);
    },
  );

  test('Windows unsafe titles retain a usable export extension', () async {
    final reserved = song.copyWith(title: 'CON');
    await savedBytes(await files.shareSong(reserved));
    expect(dialog.calls.single.name, '_CON.cho');
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test('$platform retains native sharing and its actual outcome', () async {
      final shareRoot = Directory(paths.join(temporary.path, 'share-cache'));
      ShareParams? received;
      const nativeResult = ShareResult(
        'native-outcome',
        ShareResultStatus.unavailable,
      );
      final mobile = VerseFileActions(
        platform: platform,
        temporaryDirectory: () async => shareRoot,
        saveFile:
            ({required fileName, required bytes, required mimeType}) async =>
                throw StateError('Mobile must not invoke Windows Save As'),
        shareFiles: (params) async {
          received = params;
          expect(
            await params.files!.single.readAsBytes(),
            orderedEquals(utf8.encode(ChordProCodec().encode(song))),
          );
          return nativeResult;
        },
      );
      final result = await mobile.shareSong(song);
      expect(identical(result, nativeResult), isTrue);
      expect(received!.files!.single.name, '${song.title}.cho');
      expect(await File(received!.files!.single.path).exists(), isTrue);
      expect(dialog.calls, isEmpty);
    });
  }
}
