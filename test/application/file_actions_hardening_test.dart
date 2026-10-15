import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/painting.dart' show Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/models.dart';

Matcher formatError(String message) =>
    isA<FormatException>().having((e) => e.message, 'message', message);

/// Rewrites the declared uncompressed size in every central-directory record.
Uint8List patchDeclaredSize(Uint8List zip, int size) {
  final out = Uint8List.fromList(zip);
  final data = ByteData.sublistView(out);
  for (var i = 0; i + 46 < out.length; i++) {
    if (data.getUint32(i, Endian.little) == 0x02014b50) {
      data.setUint32(i + 24, size, Endian.little);
    }
  }
  return out;
}

Uint8List replaceBytes(Uint8List source, String from, String to) {
  assert(from.length == to.length);
  final out = Uint8List.fromList(source);
  final needle = ascii.encode(from), replacement = ascii.encode(to);
  for (var i = 0; i + needle.length <= out.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length && match; j++) {
      match = out[i + j] == needle[j];
    }
    if (match) out.setRange(i, i + needle.length, replacement);
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('backup size limits are symmetric', () {
    test('a backup of more than 1000 songs restores completely', () {
      final songs = [
        for (var i = 0; i < 1200; i++)
          SongDocument(id: 'id-$i', title: 'Song $i', artist: 'A', body: 'w$i'),
      ];
      final set = SetlistDocument(
        id: 's',
        name: 'All',
        entries: [
          for (var i = 0; i < 1200; i++)
            SetlistEntry(id: 'e$i', songId: 'id-$i'),
        ],
      );
      final restored = decodeLibraryPackage(encodeLibraryPackage(songs, [set]));
      expect(restored.songs, hasLength(1200));
      expect(restored.setlists.single.entries, hasLength(1200));
      expect(restored.songs.last.body, 'w1199');
    });

    test('an export that could not be restored fails early with a clear code',
        () {
      final songs = [
        for (var i = 0; i <= maxBackupSongs; i++)
          SongDocument(id: '$i', title: 't', artist: '', body: 'b'),
      ];
      expect(() => encodeLibraryPackage(songs, []), throwsA(formatError('backup_too_large')));
      expect(
        () => encodeLibraryPackage([], [
          SetlistDocument(id: 'x', name: 'n' * (maxBackupManifestBytes + 1)),
        ]),
        throwsA(formatError('backup_too_large')),
      );
    });

    test('a package larger than the package limit is refused up front', () {
      expect(
        () => decodeLibraryPackage(Uint8List(maxBackupBytes + 1)),
        throwsA(formatError('file_too_large')),
      );
    });
  });

  group('zip hardening', () {
    Uint8List bomb(int zeros) => Uint8List.fromList(
      ZipEncoder().encodeBytes(
        Archive()..add(ArchiveFile.bytes('manifest.json', Uint8List(zeros))),
      ),
    );

    test('a header that understates the size cannot make us inflate more', () {
      final zip = bomb(30 * 1024 * 1024);
      expect(zip.length, lessThan(200 * 1024), reason: 'precondition: tiny zip');
      expect(
        () => decodeLibraryPackage(patchDeclaredSize(zip, 100)),
        throwsA(formatError('invalid_archive')),
      );
    });

    test('a header that overstates the size is rejected before inflating', () {
      final zip = bomb(1000);
      expect(
        () => decodeLibraryPackage(patchDeclaredSize(zip, 0x7fffffff)),
        throwsA(formatError('invalid_archive')),
      );
    });

    test('an honest oversized manifest is refused by the actual size', () {
      expect(
        () => decodeLibraryPackage(bomb(maxBackupManifestBytes + 1)),
        throwsA(formatError('invalid_archive')),
      );
    });

    test('directory entries are accepted', () {
      final song = SongDocument(id: 'a', title: 'A', artist: '', body: 'words');
      final archive = ZipDecoder().decodeBytes(
        encodeLibraryPackage([song], []),
      );
      final withDirectory = Archive()..add(ArchiveFile.directory('songs/'));
      for (final file in archive) {
        withDirectory.add(file);
      }
      final restored = decodeLibraryPackage(
        Uint8List.fromList(ZipEncoder().encodeBytes(withDirectory)),
      );
      expect(restored.songs.single.id, 'a');
    });

    test('duplicate entry names are rejected', () {
      final songs = [
        for (final id in ['a', 'b'])
          SongDocument(id: id, title: id, artist: '', body: 'words $id'),
      ];
      final zip = Uint8List.fromList(encodeLibraryPackage(songs, []));
      expect(
        () => decodeLibraryPackage(replaceBytes(zip, 'songs/1.cho', 'songs/0.cho')),
        throwsA(formatError('invalid_archive')),
      );
    });

    test('only the full local-header signature identifies a zip', () {
      expect(looksLikeZip(ascii.encode('PK song title')), isFalse);
      expect(looksLikeZip([0x50, 0x4b]), isFalse);
      expect(looksLikeZip([0x50, 0x4b, 3, 4, 0]), isTrue);
      expect(
        () => decodeLibraryPackage(Uint8List.fromList(ascii.encode('PK text'))),
        throwsA(formatError('invalid_archive')),
      );
    });
  });

  group('text decoding', () {
    test('legacy Cyrillic Windows-1251 text is decoded, not rejected', () {
      // "Світло" is not representable in cp1251's Bulgarian subset, so use
      // Bulgarian "Светлина": bytes from the cp1251 table.
      final bytes = Uint8List.fromList([
        0xd1, 0xe2, 0xe5, 0xf2, 0xeb, 0xe8, 0xed, 0xe0, 0x20, 0xb3, // С в е т л и н а _ і
      ]);
      expect(decodeImportedText(bytes), 'Светлина і');
      final picked = PickedDocument('x.txt', bytes);
      expect(() => picked.text, throwsFormatException); // strict stays strict
      expect(picked.lenientText, 'Светлина і');
    });

    test('UTF-8 with BOM, UTF-16 and Latin-1 fallbacks', () {
      expect(decodeImportedText([0xef, 0xbb, 0xbf, 0x41]), 'A');
      expect(decodeImportedText([0xff, 0xfe, 0x41, 0x00, 0x42, 0x00]), 'AB');
      expect(decodeImportedText([0xfe, 0xff, 0x00, 0x41]), 'A');
      expect(decodeImportedText([0x63, 0x61, 0x66, 0xe9]), 'café');
      expect(() => decodeImportedText([0xff, 0xfe, 0x41]), throwsA(formatError('invalid_encoding')));
    });

    test('only a document whose root is <set> is a setlist', () {
      expect(looksLikeSetlistXml('<?xml version="1.0"?>\n<set name="x"/>'), isTrue);
      expect(looksLikeSetlistXml('﻿  <set>\n</set>'), isTrue);
      expect(looksLikeSetlistXml('<!-- c --><set name="a">'), isTrue);
      expect(looksLikeSetlistXml('I will <set > the table\nand <set>'), isFalse);
      expect(looksLikeSetlistXml('[C]Some <set a> lyric'), isFalse);
      expect(looksLikeSetlistXml('<settings/>'), isFalse);
    });
  });

  group('safeName', () {
    test('avoids Windows device names with or without extension', () {
      for (final name in ['CON', 'prn', 'Aux', 'NUL', 'COM1', 'lpt9', 'con.txt']) {
        expect(safeName(name), startsWith('_'), reason: name);
      }
      expect(safeName('Console'), 'Console');
      expect(safeName('COM10'), 'COM10');
      expect(safeName('  '), 'Singbook');
    });

    test('truncation never splits a surrogate pair', () {
      final name = safeName('😀' * 150);
      expect(name.runes, hasLength(100));
      expect(name.codeUnits, hasLength(200));
      expect(name.runes.every((r) => r == 0x1f600), isTrue);
      expect(safeName('${'a' * 99}.${'b' * 20}'), isNot(endsWith('.')));
    });
  });

  group('sharing leaves no temporary copies behind', () {
    late Directory temp;
    final song = SongDocument(id: 'a', title: 'Shared', artist: '', body: 'words');
    setUp(() async {
      temp = await Directory.systemTemp.createTemp('verse-share-test-');
    });
    tearDown(() async => temp.delete(recursive: true));
    Directory shareRoot() => Directory('${temp.path}/verse-share');
    int copies() => shareRoot().existsSync()
        ? shareRoot().listSync().whereType<Directory>().length
        : 0;

    test('the copy is removed once the platform reports completion', () async {
      List<String>? paths;
      final actions = VerseFileActions(
        temporaryDirectory: () async => temp,
        shareFiles: (params) async {
          paths = params.files!.map((f) => f.path).toList();
          expect(File(paths!.single).existsSync(), isTrue);
          return const ShareResult('ok', ShareResultStatus.success);
        },
      );
      await actions.shareSong(song, origin: const Rect.fromLTWH(0, 0, 1, 1));
      expect(File(paths!.single).existsSync(), isFalse);
      expect(copies(), 0);
    });

    test('a failed share cleans up and rethrows', () async {
      final actions = VerseFileActions(
        temporaryDirectory: () async => temp,
        shareFiles: (_) async => throw StateError('no share target'),
      );
      await expectLater(actions.shareSong(song), throwsStateError);
      expect(copies(), 0);
    });

    test('when the outcome is unknown the copy lives until the next share sweeps it',
        () async {
      final actions = VerseFileActions(
        temporaryDirectory: () async => temp,
        shareRetention: Duration.zero,
        shareFiles: (_) async =>
            const ShareResult('launched', ShareResultStatus.unavailable),
      );
      await actions.shareSong(song);
      expect(copies(), 1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await actions.shareSong(song);
      expect(copies(), 1, reason: 'the first copy was swept, the new one kept');
    });
  });
}
