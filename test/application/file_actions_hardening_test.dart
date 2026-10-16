import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/painting.dart' show Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/timing.dart';

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

Uint8List markCentralEntryAsSymlink(Uint8List source, String name) {
  final out = Uint8List.fromList(source);
  final data = ByteData.sublistView(out);
  final encodedName = utf8.encode(name);
  for (var i = 0; i + 46 + encodedName.length <= out.length; i++) {
    if (data.getUint32(i, Endian.little) != 0x02014b50) continue;
    final nameLength = data.getUint16(i + 28, Endian.little);
    if (nameLength != encodedName.length) continue;
    var matches = true;
    for (var j = 0; j < nameLength; j++) {
      if (out[i + 46 + j] != encodedName[j]) matches = false;
    }
    if (!matches) continue;
    data.setUint16(i + 4, (3 << 8) | 20, Endian.little);
    data.setUint32(i + 38, 0xa1ff0000, Endian.little);
    return out;
  }
  throw StateError('central entry not found');
}

Uint8List backupWithTimestamp({
  required bool targetSong,
  required String field,
  required String value,
}) {
  final song = SongDocument(
    id: 'date-song',
    title: 'Date song',
    artist: 'Band',
    body: 'Words',
  );
  final setlist = SetlistDocument(
    id: 'date-setlist',
    name: 'Date setlist',
    entries: [SetlistEntry(id: 'date-entry', songId: song.id)],
  );
  final archive = ZipDecoder().decodeBytes(
    encodeLibraryPackage([song], [setlist]),
  );
  final manifestFile = archive.find('manifest.json')!;
  final manifest = jsonMap(jsonDecode(utf8.decode(manifestFile.content)));
  final replacementContent = <String, List<int>>{};
  if (targetSong) {
    const path = 'songs/0.json';
    final songFile = archive.find(path)!;
    final json = jsonMap(jsonDecode(utf8.decode(songFile.content)))
      ..[field] = value;
    final bytes = utf8.encode(jsonEncode(json));
    replacementContent[path] = bytes;
    final hashes = stringMap(manifest['hashes'])
      ..[path] = sha256.convert(bytes).toString();
    manifest['hashes'] = hashes;
  } else {
    final setlists = (manifest['setlists'] as List)
        .map((item) => jsonMap(item))
        .toList();
    setlists.single[field] = value;
    manifest['setlists'] = setlists;
  }
  replacementContent['manifest.json'] = utf8.encode(jsonEncode(manifest));
  final changed = Archive();
  for (final file in archive.files) {
    changed.add(
      ArchiveFile.bytes(
        file.name,
        replacementContent[file.name] ?? file.content,
      ),
    );
  }
  return Uint8List.fromList(ZipEncoder().encodeBytes(changed));
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

    test(
      'an export that could not be restored fails early with a clear code',
      () {
        final songs = [
          for (var i = 0; i <= maxBackupSongs; i++)
            SongDocument(id: '$i', title: 't', artist: '', body: 'b'),
        ];
        expect(
          () => encodeLibraryPackage(songs, []),
          throwsA(formatError('backup_too_large')),
        );
        expect(
          () => encodeLibraryPackage([], [
            SetlistDocument(id: 'x', name: 'n' * (maxBackupManifestBytes + 1)),
          ]),
          throwsA(formatError('backup_too_large')),
        );
      },
    );

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
      expect(
        zip.length,
        lessThan(200 * 1024),
        reason: 'precondition: tiny zip',
      );
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

    test(
      'a symlink with an oversized central size is rejected pre-inflate',
      () {
        final zip = ZipEncoder().encodeBytes(
          Archive()..add(ArchiveFile.bytes('manifest.json', Uint8List(512))),
        );
        final symlink = markCentralEntryAsSymlink(
          Uint8List.fromList(zip),
          'manifest.json',
        );
        final oversized = patchDeclaredSize(symlink, 0x7fffffff);
        expect(
          () => decodeLibraryPackage(oversized),
          throwsA(formatError('invalid_archive')),
        );
      },
    );

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
        () => decodeLibraryPackage(
          replaceBytes(zip, 'songs/1.json', 'songs/0.json'),
        ),
        throwsA(formatError('invalid_archive')),
      );
    });

    test('only the full local-header signature identifies a zip', () {
      expect(looksLikeZip(ascii.encode('PK song title')), isFalse);
      expect(looksLikeZip([0x50, 0x4b]), isFalse);
      expect(looksLikeZip([0x50, 0x4b, 3, 4, 0]), isTrue);
      expect(isLibraryPackageFileName('backup.ZIP'), isTrue);
      expect(isLibraryPackageFileName('Backup.lyrics-setlist'), isTrue);
      expect(isLibraryPackageFileName('song.cho'), isFalse);
      expect(
        () => decodeLibraryPackage(Uint8List.fromList(ascii.encode('PK text'))),
        throwsA(formatError('invalid_archive')),
      );
    });
  });

  group('portable backup preferences', () {
    test(
      'v1/v2 archives remain readable and v3 carries only validated keys',
      () {
        final song = SongDocument(
          id: 'one',
          title: 'One',
          artist: '',
          body: '[C]Words',
        );
        final legacyText = ChordProCodec().encode(song);
        final legacyBytes = utf8.encode(legacyText);
        final legacyPath = 'songs/0.cho';
        for (final version in [1, 2]) {
          final manifest = {
            'schemaVersion': version,
            'songs': {'one': legacyPath},
            'hashes': {legacyPath: sha256.convert(legacyBytes).toString()},
            'setlists': <Object>[],
            if (version == 2) 'preferences': <String, Object?>{},
          };
          final archive = Archive()
            ..add(ArchiveFile.bytes(legacyPath, legacyBytes))
            ..add(
              ArchiveFile.bytes(
                'manifest.json',
                utf8.encode(jsonEncode(manifest)),
              ),
            );
          final legacy = decodeLibraryPackage(
            Uint8List.fromList(ZipEncoder().encodeBytes(archive)),
          );
          expect(legacy.schemaVersion, version);
          expect(legacy.preferences, version == 1 ? isNull : isEmpty);
          expect(legacy.songs.single.id, 'one');
        }

        final portable = decodeLibraryPackage(
          encodeLibraryPackage(
            [song],
            [],
            preferences: {
              'themeMode': 'dark',
              'locale': 'uk',
              'providers': {'genius': false, 'youtubemusic': true},
              'oauthToken': 'must not be exported',
              'consent': {'accepted': true},
              'readerFontSize': 999,
            },
          ),
        );
        expect(portable.preferences, {
          'themeMode': 'dark',
          'locale': 'uk',
          'providers': {'genius': false, 'youtubemusic': true},
        });
        expect(portable.preferences, isNot(contains('oauthToken')));
        expect(portable.preferences, isNot(contains('consent')));
        expect(portable.schemaVersion, 3);
      },
    );

    test('v2 rejects unknown or malformed preference values', () {
      final manifest = utf8.encode(
        jsonEncode({
          'schemaVersion': 2,
          'songs': <String, String>{},
          'hashes': <String, String>{},
          'setlists': <Object>[],
          'preferences': {'oauthToken': 'secret'},
        }),
      );
      final archive = Archive()
        ..add(ArchiveFile.bytes('manifest.json', manifest));
      final bytes = Uint8List.fromList(ZipEncoder().encodeBytes(archive));
      expect(
        () => decodeLibraryPackage(bytes),
        throwsA(formatError('invalid_archive')),
      );
    });
  });

  group('opaque song backup sidecars', () {
    final opaque = SongDocument(
      id: 'opaque',
      title: 'Future song',
      artist: 'Band',
      body: 'A timed lyric',
      metadata: {'album': 'Album', 'tempo': 94},
      timingTracks: [
        parseLrc('[00:01]A timed lyric', sourceDocumentId: 'source'),
      ],
      extra: {
        'custom': {'kept': true},
      },
      preservedExtensions: ['{x_verse: unsupported opaque data}'],
      extensionError: 'Unsupported x_verse extension',
    );

    test('v3 round trip preserves every model field', () {
      final restored = decodeLibraryPackage(encodeLibraryPackage([opaque], []));
      expect(restored.schemaVersion, 3);
      expect(restored.songs.single.toJson(), opaque.toJson());
    });

    test('sidecar ID must match the manifest identity', () {
      final zip = encodeLibraryPackage([opaque], []);
      final archive = ZipDecoder().decodeBytes(zip);
      final manifest = jsonMap(
        jsonDecode(utf8.decode(archive.find('manifest.json')!.content)),
      );
      final json = jsonMap(
        jsonDecode(utf8.decode(archive.find('songs/0.json')!.content)),
      );
      json['id'] = 'forged';
      final forgedBytes = utf8.encode(jsonEncode(json));
      final hashes = stringMap(manifest['hashes']);
      hashes['songs/0.json'] = sha256.convert(forgedBytes).toString();
      manifest['hashes'] = hashes;
      final forged = Archive()
        ..add(ArchiveFile.bytes('songs/0.json', forgedBytes))
        ..add(
          ArchiveFile.bytes('manifest.json', utf8.encode(jsonEncode(manifest))),
        );
      expect(
        () => decodeLibraryPackage(
          Uint8List.fromList(ZipEncoder().encodeBytes(forged)),
        ),
        throwsA(formatError('invalid_archive_identity')),
      );
    });

    test('sidecar hash mismatch is rejected', () {
      final archive = ZipDecoder().decodeBytes(
        encodeLibraryPackage([opaque], []),
      );
      final manifest = jsonMap(
        jsonDecode(utf8.decode(archive.find('manifest.json')!.content)),
      );
      final sidecar = utf8
          .decode(archive.find('songs/0.json')!.content)
          .replaceFirst('Future song', 'Other song');
      final changed = Archive()
        ..add(ArchiveFile.bytes('songs/0.json', utf8.encode(sidecar)))
        ..add(
          ArchiveFile.bytes('manifest.json', utf8.encode(jsonEncode(manifest))),
        );
      expect(
        () => decodeLibraryPackage(
          Uint8List.fromList(ZipEncoder().encodeBytes(changed)),
        ),
        throwsA(formatError('invalid_archive_hash')),
      );
    });
  });

  group('backup timestamps', () {
    for (final field in ['createdAt', 'updatedAt']) {
      test('rejects an invalid song $field', () {
        expect(
          () => decodeLibraryPackage(
            backupWithTimestamp(
              targetSong: true,
              field: field,
              value: 'not-a-date',
            ),
          ),
          throwsA(formatError('invalid_archive')),
        );
      });

      test('rejects an invalid setlist $field', () {
        expect(
          () => decodeLibraryPackage(
            backupWithTimestamp(
              targetSong: false,
              field: field,
              value: 'not-a-date',
            ),
          ),
          throwsA(formatError('invalid_archive')),
        );
      });
    }

    test('preserves valid ISO timestamp forms for songs and setlists', () {
      final archive = ZipDecoder().decodeBytes(
        encodeLibraryPackage(
          [
            SongDocument(
              id: 'valid-dates',
              title: 'Valid dates',
              artist: '',
              body: 'Words',
              createdAt: DateTime.utc(2024, 1, 2, 3, 4, 5),
              updatedAt: DateTime.utc(2024, 1, 3, 3, 4, 5),
            ),
          ],
          [
            SetlistDocument(
              id: 'valid-setlist-dates',
              name: 'Valid dates',
              entries: [SetlistEntry(id: 'valid-entry', songId: 'valid-dates')],
              createdAt: DateTime.utc(2024, 1, 2, 3, 4, 5),
              updatedAt: DateTime.utc(2024, 1, 3, 3, 4, 5),
            ),
          ],
        ),
      );
      final manifest = jsonMap(
        jsonDecode(utf8.decode(archive.find('manifest.json')!.content)),
      );
      final song = jsonMap(
        jsonDecode(utf8.decode(archive.find('songs/0.json')!.content)),
      );
      song['createdAt'] = '2024-01-02 03:04:05Z';
      song['updatedAt'] = '2024-01-03T05:04:05+02:00';
      final songBytes = utf8.encode(jsonEncode(song));
      final hashes = stringMap(manifest['hashes'])
        ..['songs/0.json'] = sha256.convert(songBytes).toString();
      manifest['hashes'] = hashes;
      final setlists = (manifest['setlists'] as List)
          .map((item) => jsonMap(item))
          .toList();
      setlists.single['createdAt'] = '2024-01-02T03:04:05+00:00';
      setlists.single['updatedAt'] = '2024-01-03 03:04:05Z';
      manifest['setlists'] = setlists;
      final replacements = {
        'songs/0.json': songBytes,
        'manifest.json': utf8.encode(jsonEncode(manifest)),
      };
      final rewritten = Archive();
      for (final file in archive.files) {
        rewritten.add(
          ArchiveFile.bytes(file.name, replacements[file.name] ?? file.content),
        );
      }

      final restored = decodeLibraryPackage(
        Uint8List.fromList(ZipEncoder().encodeBytes(rewritten)),
      );
      expect(
        restored.songs.single.createdAt,
        DateTime.utc(2024, 1, 2, 3, 4, 5),
      );
      expect(
        restored.songs.single.updatedAt,
        DateTime.utc(2024, 1, 3, 3, 4, 5),
      );
      expect(
        restored.setlists.single.createdAt,
        DateTime.utc(2024, 1, 2, 3, 4, 5),
      );
      expect(
        restored.setlists.single.updatedAt,
        DateTime.utc(2024, 1, 3, 3, 4, 5),
      );
    });

    test('legacy setlist archives may omit their timestamps', () {
      final manifest = {
        'schemaVersion': 2,
        'songs': <String, String>{},
        'hashes': <String, String>{},
        'setlists': [
          {'id': 'legacy-setlist', 'name': 'Legacy', 'entries': <Object>[]},
        ],
        'preferences': <String, Object?>{},
      };
      final bytes = Uint8List.fromList(
        ZipEncoder().encodeBytes(
          Archive()..add(
            ArchiveFile.bytes(
              'manifest.json',
              utf8.encode(jsonEncode(manifest)),
            ),
          ),
        ),
      );
      expect(decodeLibraryPackage(bytes).setlists.single.id, 'legacy-setlist');
    });
  });

  group('text decoding', () {
    test('legacy Cyrillic Windows-1251 text is decoded, not rejected', () {
      // "Світло" is not representable in cp1251's Bulgarian subset, so use
      // Bulgarian "Светлина": bytes from the cp1251 table.
      final bytes = Uint8List.fromList([
        0xd1,
        0xe2,
        0xe5,
        0xf2,
        0xeb,
        0xe8,
        0xed,
        0xe0,
        0x20,
        0xb3, // С в е т л и н а _ і
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
      expect(
        () => decodeImportedText([0xff, 0xfe, 0x41]),
        throwsA(formatError('invalid_encoding')),
      );
    });

    test('only a document whose root is <set> is a setlist', () {
      expect(
        looksLikeSetlistXml('<?xml version="1.0"?>\n<set name="x"/>'),
        isTrue,
      );
      expect(looksLikeSetlistXml('﻿  <set>\n</set>'), isTrue);
      expect(looksLikeSetlistXml('<!-- c --><set name="a">'), isTrue);
      expect(
        looksLikeSetlistXml('I will <set > the table\nand <set>'),
        isFalse,
      );
      expect(looksLikeSetlistXml('[C]Some <set a> lyric'), isFalse);
      expect(looksLikeSetlistXml('<settings/>'), isFalse);
    });
  });

  group('safeName', () {
    test('avoids Windows device names with or without extension', () {
      for (final name in [
        'CON',
        'prn',
        'Aux',
        'NUL',
        'COM1',
        'lpt9',
        'con.txt',
      ]) {
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
    final song = SongDocument(
      id: 'a',
      title: 'Shared',
      artist: '',
      body: 'words',
    );
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

    test(
      'when the outcome is unknown the copy lives until the next share sweeps it',
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
        expect(
          copies(),
          1,
          reason: 'the first copy was swept, the new one kept',
        );
      },
    );
  });
}
