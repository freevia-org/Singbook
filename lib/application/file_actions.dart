import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;
import 'package:archive/archive.dart';
import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';
import '../domain/arrangement.dart';
import '../domain/chordpro.dart';
import '../domain/models.dart';
import '../domain/timing.dart';

/// Largest single text/timing file accepted by an import.
const maxImportBytes = 24 * 1024 * 1024;

/// Backup package limits. Export and import share these constants, so a backup
/// this app can write is always one it can restore (and vice versa).
const maxBackupBytes = 64 * 1024 * 1024;
const maxBackupSongs = 10000;
const maxBackupUncompressedBytes = 256 * 1024 * 1024;
const maxBackupManifestBytes = 16 * 1024 * 1024;
const _maxBackupDirectoryEntries = 64;

/// True only for the full local-file-header signature `PK\x03\x04`; a text file
/// whose title merely starts with "PK" is not an archive.
bool looksLikeZip(List<int> bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x50 &&
    bytes[1] == 0x4b &&
    bytes[2] == 0x03 &&
    bytes[3] == 0x04;

// Windows-1251 0x80..0xBF; 0xC0..0xFF map linearly to U+0410..U+044F.
const _cp1251Upper = <int>[
  0x0402, 0x0403, 0x201A, 0x0453, 0x201E, 0x2026, 0x2020, 0x2021, //
  0x20AC, 0x2030, 0x0409, 0x2039, 0x040A, 0x040C, 0x040B, 0x040F,
  0x0452, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
  0x0098, 0x2122, 0x0459, 0x203A, 0x045A, 0x045C, 0x045B, 0x045F,
  0x00A0, 0x040E, 0x045E, 0x0408, 0x00A4, 0x0490, 0x00A6, 0x00A7,
  0x0401, 0x00A9, 0x0404, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x0407,
  0x00B0, 0x00B1, 0x0406, 0x0456, 0x0491, 0x00B5, 0x00B6, 0x00B7,
  0x0451, 0x2116, 0x0454, 0x00BB, 0x0458, 0x0405, 0x0455, 0x0457,
];

String _decodeUtf16(List<int> bytes, {required bool bigEndian}) {
  if (bytes.length.isOdd) throw const FormatException('invalid_encoding');
  final units = <int>[
    for (var i = 0; i < bytes.length; i += 2)
      bigEndian
          ? (bytes[i] << 8) | bytes[i + 1]
          : bytes[i] | (bytes[i + 1] << 8),
  ];
  return String.fromCharCodes(units);
}

/// Decodes imported text without failing on common legacy encodings: UTF-8
/// (with or without BOM), UTF-16 with BOM, then Windows-1251 for Cyrillic
/// (Bulgarian/Ukrainian) text, otherwise Latin-1.
String decodeImportedText(List<int> bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xfe) {
    return _decodeUtf16(bytes.sublist(2), bigEndian: false);
  }
  if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) {
    return _decodeUtf16(bytes.sublist(2), bigEndian: true);
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    // Not UTF-8: fall through to single-byte encodings.
  }
  // Cyrillic letters are 0xC0..0xFF in Windows-1251, which in Latin-1 would be
  // accented vowels. Choose by the share of such bytes among all letters.
  var cyrillic = 0, letters = 0;
  for (final byte in bytes) {
    if (byte >= 0xc0) {
      cyrillic++;
      letters++;
    } else if (byte >= 0x80 ||
        (byte >= 0x41 && byte <= 0x5a) ||
        (byte >= 0x61 && byte <= 0x7a)) {
      letters++;
    }
  }
  if (cyrillic > 0 && cyrillic * 2 >= letters) {
    return String.fromCharCodes([
      for (final byte in bytes)
        if (byte < 0x80)
          byte
        else if (byte < 0xc0)
          _cp1251Upper[byte - 0x80]
        else
          0x0410 + (byte - 0xc0),
    ]);
  }
  return latin1.decode(bytes);
}

/// Matches a document whose root element is `<set>`, after an optional BOM,
/// XML declaration and comments. Lyrics that merely mention `<set>` elsewhere
/// are not setlists.
final _setlistRoot = RegExp(
  r'^﻿?\s*(?:<\?xml[^>]*\?>\s*)?(?:<!--.*?-->\s*)*<set(?=[\s>/])',
  dotAll: true,
);
bool looksLikeSetlistXml(String text) => _setlistRoot.hasMatch(text);

/// Imports timing without implying that the user's file identifies a recording.
List<SongDocument> decodeSongText(String input, {String? fileName}) {
  if (utf8.encode(input).length > maxImportBytes) {
    throw const FormatException('file_too_large');
  }
  final text = input.replaceFirst('\uFEFF', '');
  if (text.trim().isEmpty) throw const FormatException('empty_file');
  final title = fileName == null
      ? text.split('\n').first.trim()
      : paths.basenameWithoutExtension(fileName);
  if (RegExp(r'^\s*\[\d+:\d{2}(?:\.\d+)?\]', multiLine: true).hasMatch(text) ||
      RegExp(r'<(?:\w+:)?tt(?:\s|>)').hasMatch(text)) {
    final id = newId();
    final rawTrack = parseTimingBytes(
      utf8.encode(input),
      sourceDocumentId: 'import:$id',
      format: text.trimLeft().startsWith('<') ? 'ttml' : 'lrc',
    );
    final track = bindImportedTiming(rawTrack, rawTrack.sourceLyrics);
    if (track.status == TimingStatus.invalid) {
      throw const FormatException('invalid_timing');
    }
    final lrcTitle = RegExp(
      r'\[ti:([^\]]+)\]',
      caseSensitive: false,
    ).firstMatch(text)?.group(1);
    final artist =
        RegExp(
          r'\[ar:([^\]]+)\]',
          caseSensitive: false,
        ).firstMatch(text)?.group(1) ??
        '';
    return [
      SongDocument(
        id: id,
        title: lrcTitle ?? title,
        artist: artist,
        body: track.sourceLyrics,
        timingTracks: [track],
        activeTimingTrackId: track.status == TimingStatus.usable
            ? track.id
            : null,
        extra: {'importedFile': fileName},
      ),
    ];
  }
  if (text.trimLeft().startsWith('<')) {
    throw const FormatException('unsupported_file');
  }
  final parts = text.split(RegExp(r'^\s*\{new_song\}\s*$', multiLine: true));
  if (parts.length > 1000) throw const FormatException('too_many_songs');
  return parts.where((part) => part.trim().isNotEmpty).map((part) {
    final song = ChordProCodec().decode(part);
    return song.title.isEmpty
        ? song.copyWith(title: title, revision: song.revision)
        : song;
  }).toList();
}

class PickedDocument {
  const PickedDocument(this.name, this.bytes);
  final String name;
  final Uint8List bytes;

  /// Strict UTF-8; throws [FormatException] for anything else.
  String get text => utf8.decode(bytes);

  /// Tolerant decoding used by imports (see [decodeImportedText]).
  String get lenientText => decodeImportedText(bytes);
}

List<SongDocument> decodePickedSongs(PickedDocument file) {
  final extension = paths.extension(file.name).toLowerCase();
  if (extension != '.lrc' && extension != '.ttml') {
    return decodeSongText(file.lenientText, fileName: file.name);
  }
  final id = newId();
  final raw = parseTimingBytes(
    file.bytes,
    sourceDocumentId: 'import:$id',
    format: extension.substring(1),
  );
  final track = bindImportedTiming(raw, raw.sourceLyrics);
  if (track.status == TimingStatus.invalid) {
    throw const FormatException('invalid_timing');
  }
  final title =
      RegExp(
        r'\[ti:([^\]]+)\]',
        caseSensitive: false,
      ).firstMatch(track.raw ?? '')?.group(1) ??
      paths.basenameWithoutExtension(file.name);
  final artist =
      RegExp(
        r'\[ar:([^\]]+)\]',
        caseSensitive: false,
      ).firstMatch(track.raw ?? '')?.group(1) ??
      '';
  return [
    SongDocument(
      id: id,
      title: title,
      artist: artist,
      body: track.sourceLyrics,
      timingTracks: [track],
      activeTimingTrackId: track.status == TimingStatus.usable
          ? track.id
          : null,
      extra: {'importedFile': file.name},
    ),
  ];
}

/// Native file and print integrations; all songs use the same complete .cho.
class VerseFileActions {
  VerseFileActions({
    Future<Directory> Function()? temporaryDirectory,
    Future<ShareResult> Function(ShareParams)? shareFiles,
    this.shareRetention = const Duration(hours: 1),
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _shareFiles =
           shareFiles ?? ((params) => SharePlus.instance.share(params));
  final Future<Directory> Function() _temporaryDirectory;
  final Future<ShareResult> Function(ShareParams) _shareFiles;

  /// Temporary share copies older than this are removed before the next share.
  final Duration shareRetention;

  Future<PickedDocument?> pickDocument() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    if ((file.lengthSync() ?? 0) > maxBackupBytes) {
      throw const FormatException('file_too_large');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (bytes.length + chunk.length > maxBackupBytes) {
        throw const FormatException('file_too_large');
      }
      bytes.add(chunk);
    }
    return PickedDocument(file.name, bytes.takeBytes());
  }

  /// Copy the same readable lyric and chord layout used by the print document.
  Future<void> copySong(SongDocument song) =>
      Clipboard.setData(ClipboardData(text: songPlainText(song)));

  Future<void> copySetlist(SetlistDocument setlist, List<SongDocument> songs) =>
      Clipboard.setData(ClipboardData(text: setlistPlainText(setlist, songs)));

  Future<ShareResult> shareSong(SongDocument song, {Rect? origin}) => _share(
    '${safeName(song.title)}.cho',
    utf8.encode(ChordProCodec().encode(song)),
    'text/plain',
    song.title,
    origin,
  );

  Future<ShareResult> shareSetlist(
    SetlistDocument setlist,
    List<SongDocument> songs, {
    Rect? origin,
  }) => _share(
    '${safeName(setlist.name)}.osts',
    utf8.encode(encodeSetlistReferences(setlist, songs)),
    'application/xml',
    setlist.name,
    origin,
  );

  Future<ShareResult> shareSongPdf(SongDocument song, {Rect? origin}) async =>
      _share(
        '${safeName(song.title)}.pdf',
        await createSongPdf([song]),
        'application/pdf',
        song.title,
        origin,
      );

  Future<ShareResult> shareSetlistPdf(
    SetlistDocument setlist,
    List<SongDocument> songs, {
    Rect? origin,
  }) async => _share(
    '${safeName(setlist.name)}.pdf',
    await createSongPdf(_songsInSetlist(setlist, songs), setlist: setlist),
    'application/pdf',
    setlist.name,
    origin,
  );

  Future<ShareResult> shareBackup(
    List<SongDocument> songs,
    List<SetlistDocument> setlists, {
    Rect? origin,
  }) => _share(
    'Singbook-${DateTime.now().toIso8601String().substring(0, 10)}.lyrics-setlist',
    encodeLibraryPackage(songs, setlists),
    'application/zip',
    'Singbook',
    origin,
  );

  Future<ShareResult> _share(
    String name,
    List<int> bytes,
    String mime,
    String title,
    Rect? origin,
  ) async {
    final root = Directory(
      paths.join((await _temporaryDirectory()).path, 'verse-share'),
    );
    await _sweepShareDirectories(root);
    final dir = Directory(paths.join(root.path, newId()));
    await dir.create(recursive: true);
    final file = File(paths.join(dir.path, name));
    try {
      await file.writeAsBytes(bytes, flush: true);
      final result = await _shareFiles(
        ShareParams(
          files: [XFile(file.path, mimeType: mime)],
          title: title,
          sharePositionOrigin: origin ?? const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
      // Where the platform reports the outcome the share sheet is finished and
      // the copy can go. Android only reports that the chooser was launched, so
      // the receiving app may still be reading it; the next share sweeps it.
      if (result.status != ShareResultStatus.unavailable) {
        await _deleteQuietly(dir);
      }
      return result;
    } catch (_) {
      await _deleteQuietly(dir);
      rethrow;
    }
  }

  Future<void> _sweepShareDirectories(Directory root) async {
    try {
      if (!await root.exists()) return;
      final cutoff = DateTime.now().subtract(shareRetention);
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) continue;
        final modified = (await entity.stat()).modified;
        if (!modified.isAfter(cutoff)) await _deleteQuietly(entity);
      }
    } catch (_) {
      // Cleaning old temporary copies must never block sharing.
    }
  }

  Future<void> _deleteQuietly(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  Future<void> printSong(SongDocument song) async {
    await Printing.layoutPdf(
      name: safeName(song.title),
      onLayout: (format) => createSongPdf([song], format: format),
    );
  }

  Future<void> printSetlist(
    SetlistDocument setlist,
    List<SongDocument> songs,
  ) async {
    final ordered = _songsInSetlist(setlist, songs);
    await Printing.layoutPdf(
      name: safeName(setlist.name),
      onLayout: (format) =>
          createSongPdf(ordered, format: format, setlist: setlist),
    );
  }
}

List<SongDocument> _songsInSetlist(
  SetlistDocument setlist,
  List<SongDocument> songs,
) {
  final byId = {for (final song in songs) song.id: song};
  return setlist.entries
      .map((entry) => byId[entry.songId])
      .whereType<SongDocument>()
      .toList();
}

/// Plain text counterpart to the song PDF: title, artist, chord rows, lyrics.
String songPlainText(SongDocument song) {
  final out = StringBuffer(song.title);
  if (song.artist.isNotEmpty) out.write('\n${song.artist}');
  out.writeln('\n');
  for (final line in parseArrangement(song.body)) {
    if (line.directive) continue;
    if (line.chords.isNotEmpty) out.writeln(_chordRow(line));
    out.writeln(line.text);
  }
  final copyright = song.metadata['copyright'];
  if (copyright is String && copyright.isNotEmpty) {
    out.write('\n$copyright\n');
  }
  return out.toString().trimRight();
}

String setlistPlainText(SetlistDocument setlist, List<SongDocument> songs) {
  final out = StringBuffer(setlist.name);
  if (setlist.notes.isNotEmpty) out.write('\n${setlist.notes}');
  final ordered = _songsInSetlist(setlist, songs);
  for (var index = 0; index < ordered.length; index++) {
    final song = ordered[index];
    out.write('\n\n${index + 1}. ${song.title}');
    if (song.artist.isNotEmpty) out.write(' — ${song.artist}');
  }
  return out.toString();
}

final _windowsReserved = RegExp(
  r'^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$',
  caseSensitive: false,
);

/// A file-name stem that is safe on Android, iOS and Windows: no separators or
/// control characters, no reserved device names, no trailing dot/space, and
/// truncated by code point so a surrogate pair is never split.
String safeName(String value) {
  String clean(String input) => input
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f\x7f]'), '_')
      .replaceAll(RegExp(r'[. ]+$'), '')
      .trim();
  var result = clean(value);
  if (result.runes.length > 100) {
    result = clean(String.fromCharCodes(result.runes.take(100)));
  }
  if (result.isEmpty) return 'Singbook';
  // "CON" and "CON.cho" are both the console device on Windows.
  if (_windowsReserved.hasMatch(result.split('.').first.trim())) {
    result = '_$result';
  }
  return result;
}

String encodeSetlistReferences(
  SetlistDocument setlist,
  List<SongDocument> songs,
) {
  final byId = {for (final song in songs) song.id: song};
  final xml = XmlBuilder()..processing('xml', 'version="1.0" encoding="UTF-8"');
  xml.element(
    'set',
    attributes: {'name': setlist.name},
    nest: () {
      xml.element(
        'slide_groups',
        nest: () {
          for (final entry in setlist.entries) {
            final song = byId[entry.songId];
            if (song == null) continue;
            xml.element(
              'slide_group',
              attributes: {'name': song.title, 'type': 'song'},
              nest: () {
                xml.element(
                  'verse_reference',
                  attributes: {'songId': song.id, 'entryId': entry.id},
                  nest: () {
                    xml.element('artist', nest: song.artist);
                    xml.element('overrides', nest: jsonEncode(entry.overrides));
                  },
                );
              },
            );
          }
        },
      );
      if (setlist.notes.isNotEmpty) xml.element('notes', nest: setlist.notes);
    },
  );
  return xml.buildDocument().toXmlString(pretty: true);
}

Uint8List encodeLibraryPackage(
  List<SongDocument> songs,
  List<SetlistDocument> setlists,
) {
  // Fail before doing any work when the result could not be restored.
  if (songs.length > maxBackupSongs) {
    throw const FormatException('backup_too_large');
  }
  final archive = Archive();
  final names = <String, String>{};
  final hashes = <String, String>{};
  var uncompressed = 0;
  for (final song in songs) {
    final name = 'songs/${names.length}.cho';
    names[song.id] = name;
    final text = ChordProCodec().encode(song);
    final encoded = utf8.encode(text);
    if (encoded.length > maxImportBytes) {
      throw const FormatException('backup_too_large');
    }
    uncompressed += encoded.length;
    hashes[name] = sha256.convert(encoded).toString();
    archive.add(ArchiveFile.bytes(name, encoded));
  }
  final manifest = utf8.encode(
    jsonEncode({
      'schemaVersion': 1,
      'songs': names,
      'hashes': hashes,
      'setlists': setlists.map((s) => s.toJson()).toList(),
    }),
  );
  uncompressed += manifest.length;
  if (manifest.length > maxBackupManifestBytes ||
      uncompressed > maxBackupUncompressedBytes) {
    throw const FormatException('backup_too_large');
  }
  archive.add(ArchiveFile.bytes('manifest.json', manifest));
  final bytes = ZipEncoder().encodeBytes(archive);
  if (bytes.length > maxBackupBytes) {
    throw const FormatException('backup_too_large');
  }
  return bytes;
}

class ImportedCollection {
  const ImportedCollection(this.songs, this.setlists);
  final List<SongDocument> songs;
  final List<SetlistDocument> setlists;
}

bool _safeEntryName(String name) =>
    name.isNotEmpty &&
    name.length <= 512 &&
    !name.contains('..') &&
    !name.contains('\\') &&
    !name.startsWith('/') &&
    !name.contains(':') &&
    !name.contains('\x00');

/// Reads one entry and enforces [limit] on the bytes actually produced. The
/// declared size in the zip header is attacker controlled, so it is only a
/// cheap early rejection: package:archive (>= 4.5) never decodes past the
/// declared size, and the result must equal it exactly; a header that lies in
/// either direction is rejected rather than trusted.
Uint8List _readEntry(ArchiveFile file, int limit, List<int> budget) {
  if (file.size < 0 || file.size > limit) {
    throw const FormatException('invalid_archive');
  }
  final Uint8List data;
  try {
    data = file.content;
  } catch (_) {
    // ArchiveException is a FormatException; expose only our stable code.
    throw const FormatException('invalid_archive');
  }
  if (data.length > limit || data.length != file.size) {
    throw const FormatException('invalid_archive');
  }
  budget[0] += data.length;
  if (budget[0] > maxBackupUncompressedBytes) {
    throw const FormatException('invalid_archive');
  }
  return data;
}

/// Complete validation precedes any database writes. No archive paths are extracted.
ImportedCollection decodeLibraryPackage(Uint8List bytes) {
  if (bytes.length > maxBackupBytes) {
    throw const FormatException('file_too_large');
  }
  if (!looksLikeZip(bytes)) throw const FormatException('invalid_archive');
  final decoder = ZipDecoder();
  final Archive archive;
  try {
    archive = decoder.decodeBytes(bytes);
  } catch (_) {
    throw const FormatException('invalid_archive');
  }
  final headerNames = decoder.directory.fileHeaders
      .map((header) => header.filename)
      .toList();
  // The decoder silently keeps only the first of two entries with one name;
  // a duplicate would make validated and extracted content differ.
  if (archive.length > maxBackupSongs + 1 + _maxBackupDirectoryEntries ||
      headerNames.length != archive.length ||
      headerNames.toSet().length != headerNames.length) {
    throw const FormatException('invalid_archive');
  }
  var declared = 0, directories = 0, files = 0;
  for (final file in archive) {
    if (file.isSymbolicLink || !_safeEntryName(file.name)) {
      throw const FormatException('invalid_archive');
    }
    if (file.isDirectory) {
      // Directory entries are harmless: nothing is ever extracted to disk.
      if (++directories > _maxBackupDirectoryEntries) {
        throw const FormatException('invalid_archive');
      }
      continue;
    }
    files++;
    declared += file.size;
    if (file.size < 0 ||
        file.size > maxImportBytes ||
        declared > maxBackupUncompressedBytes) {
      throw const FormatException('invalid_archive');
    }
  }
  final manifestFile = archive.find('manifest.json');
  if (manifestFile == null ||
      !manifestFile.isFile ||
      manifestFile.size > maxBackupManifestBytes) {
    throw const FormatException('invalid_archive');
  }
  final budget = [0];
  final manifest = jsonMap(
    jsonDecode(
      utf8.decode(_readEntry(manifestFile, maxBackupManifestBytes, budget)),
    ),
  );
  if (manifest['schemaVersion'] != 1 ||
      manifest['songs'] is! Map ||
      manifest['setlists'] is! List) {
    throw const FormatException('unsupported_archive');
  }
  final songs = <SongDocument>[];
  final expected = stringMap(manifest['songs']);
  final hashes = stringMap(manifest['hashes']);
  if (expected.length > maxBackupSongs) {
    throw const FormatException('invalid_archive');
  }
  for (final entry in expected.entries) {
    final file = archive.find(entry.value);
    if (file == null ||
        !file.isFile ||
        !_safeEntryName(entry.value) ||
        !entry.value.endsWith('.cho')) {
      throw const FormatException('invalid_archive');
    }
    final data = _readEntry(file, maxImportBytes, budget);
    if (hashes[entry.value] != sha256.convert(data).toString()) {
      throw const FormatException('invalid_archive_hash');
    }
    file.closeSync();
    final song = ChordProCodec().decode(decodeImportedText(data));
    if (song.id != entry.key) {
      throw const FormatException('invalid_archive_identity');
    }
    songs.add(song);
  }
  if (expected.values.toSet().length != expected.length ||
      files != songs.length + 1) {
    throw const FormatException('invalid_archive');
  }
  final setlists = (manifest['setlists'] as List)
      .map((s) => SetlistDocument.fromJson(jsonMap(s)))
      .toList();
  if (setlists.map((s) => s.id).toSet().length != setlists.length ||
      setlists.any(
        (s) => s.entries.any((e) => !expected.containsKey(e.songId)),
      )) {
    throw const FormatException('missing_song_references');
  }
  return ImportedCollection(songs, setlists);
}

SetlistDocument decodeSetlistReferences(
  String text,
  List<SongDocument> songs, {
  String? fileName,
}) {
  if (utf8.encode(text).length > maxImportBytes ||
      RegExp(r'<!\s*(?:DOCTYPE|ENTITY)', caseSensitive: false).hasMatch(text)) {
    throw const FormatException('invalid_xml');
  }
  final document = XmlDocument.parse(text);
  if (document.rootElement.name.local != 'set') {
    throw const FormatException('unsupported_file');
  }
  final entries = <SetlistEntry>[];
  for (final group in document.findAllElements('slide_group')) {
    if (group.getAttribute('type') != 'song') continue;
    final reference = group.getElement('verse_reference');
    final id = reference?.getAttribute('songId');
    final artist = reference?.getElement('artist')?.innerText;
    final exact = songs.where((s) => s.id == id).toList();
    final matches = exact.isNotEmpty
        ? exact
        : songs
              .where(
                (s) =>
                    s.title == group.getAttribute('name') &&
                    (artist == null || s.artist == artist),
              )
              .toList();
    if (matches.length != 1) {
      throw const FormatException('missing_song_references');
    }
    final overrides = reference?.getElement('overrides')?.innerText;
    entries.add(
      SetlistEntry(
        id: newId(),
        songId: matches.single.id,
        overrides: overrides == null ? {} : jsonMap(jsonDecode(overrides)),
      ),
    );
  }
  if (entries.length > 10000) throw const FormatException('too_many_songs');
  return SetlistDocument(
    // Derived from the file text, so importing the same file twice yields the
    // same identity and the controller can recognise it.
    id: 'osts-${sha256.convert(utf8.encode(text)).toString().substring(0, 32)}',
    name:
        document.rootElement.getAttribute('name') ??
        (fileName == null
            ? 'Singbook'
            : paths.basenameWithoutExtension(fileName)),
    entries: entries,
    notes: document.rootElement.getElement('notes')?.innerText ?? '',
  );
}

Future<Uint8List> createSongPdf(
  List<SongDocument> songs, {
  PdfPageFormat format = PdfPageFormat.a4,
  SetlistDocument? setlist,
}) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
  );
  final mono = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSansMono-Regular.ttf'),
  );
  const navy = PdfColor.fromInt(0xff173454);
  const muted = PdfColor.fromInt(0xff5f6b78);
  const paleBlue = PdfColor.fromInt(0xfff1f5f9);
  List<String> metadataLines(SongDocument song) {
    final values = <String>[];
    void add(String label, Object? raw) {
      final value = raw?.toString().trim();
      if (value != null && value.isNotEmpty) values.add('$label: $value');
    }

    add('Album', song.metadata['album']);
    add('Year', song.metadata['year']);
    add('Key', song.metadata['key']);
    add('Capo', song.metadata['capo']);
    add('Tuning', song.metadata['tuning']);
    final tempo = song.metadata['tempo'];
    if (tempo != null && tempo.toString().trim().isNotEmpty) {
      add('Tempo', '${tempo.toString().trim()} BPM');
    }
    add('Time', song.metadata['timeSignature']);
    final duration = song.metadata['durationSeconds'];
    if (duration is num && duration > 0) {
      final seconds = duration.round();
      add(
        'Duration',
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
      );
    }
    add('Composer', song.metadata['composer']);
    add('Lyricist', song.metadata['lyricist']);
    return values;
  }

  String songKeywords(SongDocument song) => [
    song.title,
    if (song.artist.trim().isNotEmpty) song.artist.trim(),
    'lyrics',
    if (song.hasChords) 'chords',
    for (final key in const [
      'album',
      'year',
      'key',
      'capo',
      'tuning',
      'tempo',
      'composer',
      'lyricist',
    ])
      if (song.metadata[key]?.toString().trim().isNotEmpty == true)
        song.metadata[key].toString().trim(),
  ].join(', ');
  final songCredits = songs.length == 1
      ? {
          for (final key in const ['composer', 'lyricist'])
            if (songs.single.metadata[key] is String &&
                (songs.single.metadata[key] as String).trim().isNotEmpty)
              (songs.single.metadata[key] as String).trim(),
        }.join('; ')
      : '';
  final document = pw.Document(
    title: setlist?.name ?? songs.map((song) => song.title).join(', '),
    author: songCredits.isEmpty ? null : songCredits,
    subject: setlist == null
        ? songs.any((song) => song.hasChords)
              ? 'Song lyrics and chords'
              : 'Song lyrics'
        : songs.any((song) => song.hasChords)
        ? 'Setlist with song lyrics and chords'
        : 'Setlist with song lyrics',
    keywords: songs.length == 1
        ? songKeywords(songs.single)
        : 'setlist, lyrics, chords',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  if (setlist != null) {
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        maxPages: 1000,
        build: (context) => [
          pw.Text(
            setlist.name,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: navy,
            ),
          ),
          if (setlist.notes.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2, bottom: 4),
              child: pw.Text(
                setlist.notes,
                style: const pw.TextStyle(fontSize: 9, color: muted),
              ),
            ),
          for (var i = 0; i < songs.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Text(
                '${i + 1}. ${songs[i].title}${songs[i].artist.trim().isEmpty ? '' : ' — ${songs[i].artist.trim()}'}',
                style: const pw.TextStyle(fontSize: 10),
                overflow: pw.TextOverflow.span,
              ),
            ),
        ],
      ),
    );
  }
  for (var songIndex = 0; songIndex < songs.length; songIndex++) {
    final song = songs[songIndex];
    final lines = parseArrangement(song.body);
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        maxPages: 1000,
        build: (context) => [
          pw.Text(
            song.title,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ..._pdfSongBody(
            lines,
            context: context,
            format: format,
            metadata: [
              if (song.artist.trim().isNotEmpty)
                'Artist: ${song.artist.trim()}',
              ...metadataLines(song),
            ],
            mono: mono,
            navy: navy,
            muted: muted,
            paleBlue: paleBlue,
          ),
        ],
      ),
    );
  }
  return document.save();
}

List<pw.Widget> _pdfSongBody(
  List<ArrangementLine> lines, {
  required pw.Context context,
  required PdfPageFormat format,
  required List<String> metadata,
  required pw.Font mono,
  required PdfColor navy,
  required PdfColor muted,
  required PdfColor paleBlue,
}) {
  final lyricRows = <pw.Widget>[];
  for (final line in lines) {
    if (line.directive && _pdfSectionHeading(line.text) != null) {
      lyricRows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 5, bottom: 2),
          child: pw.Text(
            _pdfSectionHeading(line.text)!,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: muted,
            ),
          ),
        ),
      );
    } else if (!line.directive &&
        line.text.trim().isEmpty &&
        line.chords.isEmpty) {
      lyricRows.add(pw.SizedBox(height: 5));
    } else if (!line.directive) {
      for (final chunk in _pdfLineChunks(line)) {
        lyricRows.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 0.8),
            child: pw.Inseparable(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (chunk.chords.isNotEmpty)
                    pw.Text(
                      _chordRow(chunk),
                      style: pw.TextStyle(
                        font: mono,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: navy,
                      ),
                    ),
                  pw.Text(
                    chunk.text.isEmpty ? ' ' : chunk.text,
                    style: pw.TextStyle(font: mono, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  final metadataWidgets = <pw.Widget>[];
  for (final value in metadata) {
    final chunks = _pdfTextChunks(value);
    for (var index = 0; index < chunks.length; index++) {
      metadataWidgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 0.8),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: pw.BoxDecoration(
            color: paleBlue,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(
            index == 0 ? chunks[index] : '(continued) ${chunks[index]}',
            style: pw.TextStyle(fontSize: 8, color: navy),
          ),
        ),
      );
    }
  }

  if (metadataWidgets.isEmpty) return lyricRows;

  final margin = pw.PageTheme(
    pageFormat: format,
  ).margin!.resolve(pw.TextDirection.ltr);
  final contentWidth = format.width - margin.horizontal;
  final columnWidth = contentWidth - 10;
  final lyricWidth = columnWidth * .7;
  final metadataWidth = columnWidth * .3;
  // Measure actual font wrapping at the printed width. Keep each block well
  // below a fresh page so MultiPage can paginate it as one unit. The sidebar
  // flows independently; lyrics fill its height instead of leaving a fixed
  // opening gap or imposing their own row heights on metadata fields.
  final maxBlockHeight = (format.height - margin.vertical) * .65;
  double measuredHeight(pw.Widget widget, double width) {
    widget.layout(context, pw.BoxConstraints(minWidth: width, maxWidth: width));
    return widget.box!.height;
  }

  final lyricHeights = [
    for (final row in lyricRows) measuredHeight(row, lyricWidth),
  ];
  final metadataHeights = [
    for (final widget in metadataWidgets) measuredHeight(widget, metadataWidth),
  ];
  var lyricIndex = 0;
  var metadataIndex = 0;
  final blocks = <pw.Widget>[];
  while (metadataIndex < metadataWidgets.length) {
    final metadataStart = metadataIndex;
    var metadataHeight = 0.0;
    do {
      metadataHeight += metadataHeights[metadataIndex++];
    } while (metadataIndex < metadataWidgets.length &&
        metadataHeight + metadataHeights[metadataIndex] <= maxBlockHeight);

    final lyricStart = lyricIndex;
    var lyricHeight = 0.0;
    while (lyricIndex < lyricRows.length &&
        lyricHeight + lyricHeights[lyricIndex] <= maxBlockHeight &&
        (lyricIndex == lyricStart ||
            lyricHeight + lyricHeights[lyricIndex] <= metadataHeight)) {
      lyricHeight += lyricHeights[lyricIndex++];
    }
    blocks.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 7,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: lyricRows.sublist(lyricStart, lyricIndex),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: metadataWidgets.sublist(metadataStart, metadataIndex),
            ),
          ),
        ],
      ),
    );
  }
  blocks.addAll(lyricRows.skip(lyricIndex));
  return blocks;
}

/// Break exceptional single ChordPro rows into bounded continuations so each
/// chord/lyric pair can stay together and still fit on a page. The limit is a
/// conservative text-size bound, not a page-height estimate; ordinary lines
/// remain unchanged. Chunk boundaries prefer whitespace and never split a
/// grapheme cluster when a long unbroken token needs splitting.
const _pdfTextChunkLength = 320;

List<ArrangementLine> _pdfLineChunks(ArrangementLine line) {
  final chunks = _pdfTextChunks(line.text);
  if (chunks.length == 1) return [line];

  final result = <ArrangementLine>[];
  var start = 0;
  for (var index = 0; index < chunks.length; index++) {
    final text = chunks[index];
    final end = start + text.length;
    final anchors = line.chords
        .where(
          (anchor) =>
              anchor.offset >= start &&
              (anchor.offset < end ||
                  (index == chunks.length - 1 && anchor.offset == end)),
        )
        .map((anchor) => ChordAnchor(anchor.offset - start, anchor.chord))
        .toList(growable: false);
    result.add(ArrangementLine(text, anchors));
    start = end;
  }
  return result;
}

List<String> _pdfTextChunks(String value) {
  if (value.length <= _pdfTextChunkLength) return [value];

  final chunks = <String>[];
  var start = 0;
  while (value.length - start > _pdfTextChunkLength) {
    final limit = start + _pdfTextChunkLength;
    final whitespace = RegExp(r'\s').allMatches(value.substring(start, limit));
    final lastWhitespace = whitespace.isEmpty ? null : whitespace.last;
    var end = lastWhitespace == null ? start : start + lastWhitespace.end;
    if (end <= start) {
      end = start;
      for (final grapheme in value.substring(start).characters) {
        if (end + grapheme.length - start > _pdfTextChunkLength) break;
        end += grapheme.length;
      }
    }
    if (end <= start) {
      end = start + value.substring(start).characters.first.length;
    }
    chunks.add(value.substring(start, end));
    start = end;
  }
  chunks.add(value.substring(start));
  return chunks;
}

String _chordRow(ArrangementLine line) {
  final row = StringBuffer();
  for (final anchor in line.chords) {
    final padding = anchor.offset - row.length;
    if (padding > 0) {
      row.write(' ' * padding);
    } else if (row.isNotEmpty) {
      row.write(' ');
    }
    row.write(anchor.chord);
  }
  return row.toString();
}

String? _pdfSectionHeading(String directive) {
  final match = RegExp(
    r'^\{(?:start_of_)?([a-z_]+)(?::\s*([^}]+))?\}$',
    caseSensitive: false,
  ).firstMatch(directive.trim());
  if (match == null) return null;
  final name = match.group(1)!.replaceAll('_', ' ').toLowerCase();
  final detail = match.group(2)?.trim();
  const labels = {
    'verse': 'Verse',
    'chorus': 'Chorus',
    'bridge': 'Bridge',
    'pre chorus': 'Pre-Chorus',
    'intro': 'Intro',
    'outro': 'Outro',
    'interlude': 'Interlude',
    'tag': 'Tag',
    'ending': 'Ending',
  };
  if (name == 'comment' && detail != null && detail.isNotEmpty) {
    final kind = detail.split(RegExp(r'\s+')).first.toLowerCase();
    if (labels.containsKey(kind)) return detail;
  }
  final label = labels[name];
  if (label == null) return null;
  return detail == null || detail.isEmpty ? label : '$label · $detail';
}
