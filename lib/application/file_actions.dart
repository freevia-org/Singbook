import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, visibleForTesting;
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
import 'pdf_font_face.dart';

/// Largest single text/timing file accepted by an import.
const maxImportBytes = 24 * 1024 * 1024;

enum ImportIntent { any, songs, setlists }

/// Backup package limits. Export and import share these constants, so a backup
/// this app can write is always one it can restore (and vice versa).
const maxBackupBytes = 64 * 1024 * 1024;
const maxBackupSongs = 10000;
const maxBackupUncompressedBytes = 256 * 1024 * 1024;
const maxBackupManifestBytes = 16 * 1024 * 1024;
const _maxBackupDirectoryEntries = 64;

/// Only portable display and reader preferences are copied by local backup.
/// Account, provider-consent, session, and sync state are intentionally absent.
const backupPreferenceKeys = <String>{
  'themeMode',
  'palette',
  'fontFamily',
  'readerFontSize',
  'locale',
  'showChords',
  'showSections',
  'playerControlsExpanded',
  'autoscroll',
  'timingMode',
  'defaultView',
  'startupSongsView',
  'lastSongsView',
  'lastSongsFavoritesOnly',
  'catalog',
  'providers',
};

/// True only for the full local-file-header signature `PK\x03\x04`; a text file
/// whose title merely starts with "PK" is not an archive.
bool looksLikeZip(List<int> bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x50 &&
    bytes[1] == 0x4b &&
    bytes[2] == 0x03 &&
    bytes[3] == 0x04;

/// Backup suffixes carry archive intent even when the file has a damaged or
/// missing ZIP signature. Callers should reject them as invalid archives
/// instead of passing their bytes to the permissive lyric text decoder.
bool isLibraryPackageFileName(String name) {
  final basename = paths.basename(name).toLowerCase();
  return basename.endsWith('.zip') || basename.endsWith('.lyrics-setlist');
}

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

// Windows-1252 0x80..0x9F; the five undefined slots keep their C1 code point.
const _cp1252Upper = <int>[
  0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
  0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F,
  0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
  0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178,
];

class _DecodedText {
  const _DecodedText(this.text, this.encoding);
  final String text;

  /// Lower-case name of the detected encoding ("utf-8", "utf-16le", ...).
  final String encoding;
}

_DecodedText _decodeImported(List<int> bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xfe) {
    return _DecodedText(
      _decodeUtf16(bytes.sublist(2), bigEndian: false),
      'utf-16le',
    );
  }
  if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) {
    return _DecodedText(
      _decodeUtf16(bytes.sublist(2), bigEndian: true),
      'utf-16be',
    );
  }
  try {
    return _DecodedText(utf8.decode(bytes), 'utf-8');
  } on FormatException {
    // Not UTF-8: fall through to single-byte encodings.
  }
  // Cyrillic letters are 0xC0..0xFF in Windows-1251, which in Latin-1 would be
  // accented vowels. Cyrillic words are runs of such bytes, whereas accented
  // Latin letters are almost always isolated between ASCII letters, so only
  // bytes in runs of two or more count towards Cyrillic.
  var cyrillic = 0, letters = 0, run = 0, inTag = false;
  for (var i = 0; i < bytes.length; i++) {
    final byte = bytes[i];
    // Markup (TTML/XML tag names and attributes) is ASCII whatever the text
    // language is, so it must not dilute the share of Cyrillic letters.
    if (byte == 0x3c) {
      inTag = true;
    } else if (byte == 0x3e) {
      inTag = false;
    }
    if (byte >= 0xc0) {
      letters++;
      run++;
      if (run == 2) {
        cyrillic += 2;
      } else if (run > 2) {
        cyrillic++;
      }
      continue;
    }
    run = 0;
    if (byte >= 0x80 ||
        (!inTag &&
            ((byte >= 0x41 && byte <= 0x5a) ||
                (byte >= 0x61 && byte <= 0x7a)))) {
      letters++;
    }
  }
  if (cyrillic > 0 && cyrillic * 2 >= letters) {
    return _DecodedText(
      String.fromCharCodes([
        for (final byte in bytes)
          if (byte < 0x80)
            byte
          else if (byte < 0xc0)
            _cp1251Upper[byte - 0x80]
          else
            0x0410 + (byte - 0xc0),
      ]),
      'windows-1251',
    );
  }
  return _DecodedText(
    String.fromCharCodes([
      for (final byte in bytes)
        if (byte >= 0x80 && byte < 0xa0) _cp1252Upper[byte - 0x80] else byte,
    ]),
    'windows-1252',
  );
}

/// Decodes imported text without failing on common legacy encodings: UTF-8
/// (with or without BOM), UTF-16 with BOM, then Windows-1251 for Cyrillic
/// (Bulgarian/Ukrainian) text, otherwise Windows-1252 (a superset of Latin-1
/// that also maps curly quotes, dashes and the euro sign).
String decodeImportedText(List<int> bytes) => _decodeImported(bytes).text;

/// Matches a document whose root element is `<set>`, after an optional BOM,
/// XML declaration and comments. Lyrics that merely mention `<set>` elsewhere
/// are not setlists. This is a linear scan on purpose: a regular expression
/// with a repeated comment group backtracks exponentially on a crafted file.
bool looksLikeSetlistXml(String text) {
  var i = 0;
  final n = text.length;
  bool space(int unit) =>
      unit == 0x20 || unit == 0x09 || unit == 0x0a || unit == 0x0d;
  void skipSpace() {
    while (i < n && space(text.codeUnitAt(i))) {
      i++;
    }
  }

  if (i < n && text.codeUnitAt(i) == 0xfeff) i++;
  skipSpace();
  if (text.startsWith('<?xml', i)) {
    final end = text.indexOf('?>', i + 5);
    if (end < 0) return false;
    i = end + 2;
    skipSpace();
  }
  while (text.startsWith('<!--', i)) {
    final end = text.indexOf('-->', i + 4);
    if (end < 0) return false;
    i = end + 3;
    skipSpace();
  }
  if (!text.startsWith('<set', i)) return false;
  i += 4;
  if (i >= n) return false;
  final next = text.codeUnitAt(i);
  return space(next) || next == 0x3e /* > */ || next == 0x2f /* / */;
}

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
    final metadata = _lrcMetadata(text);
    final lrcTitle = metadata.remove('_title')?.toString();
    final artist = metadata.remove('_artist')?.toString() ?? '';
    return [
      SongDocument(
        id: id,
        title: lrcTitle ?? title,
        artist: artist,
        body: track.sourceLyrics,
        metadata: metadata,
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
  if (file.bytes.length > maxImportBytes) {
    throw const FormatException('file_too_large');
  }
  final id = newId();
  // parseTimingBytes only understands UTF-8 and UTF-16. A Windows-1251 or
  // Windows-1252 file is transcoded for parsing, while the original bytes and
  // their detected encoding stay on the track so provenance is not lost.
  final decoded = _decodeImported(file.bytes);
  final legacy = decoded.encoding.startsWith('windows-');
  var raw = parseTimingBytes(
    legacy ? utf8.encode(decoded.text) : file.bytes,
    sourceDocumentId: 'import:$id',
    format: extension.substring(1),
  );
  if (raw.status == TimingStatus.unsupported) {
    throw const FormatException('invalid_timing');
  }
  if (legacy) {
    raw = raw.copyWith(
      extra: {
        ...raw.extra,
        'rawBytesBase64': base64.encode(file.bytes),
        'rawByteHash': sha256.convert(file.bytes).toString(),
        'rawEncoding': decoded.encoding,
      },
    );
  }
  final track = bindImportedTiming(raw, raw.sourceLyrics);
  if (track.status == TimingStatus.invalid) {
    throw const FormatException('invalid_timing');
  }
  if (track.sourceLyrics.trim().isEmpty) {
    throw const FormatException('empty_file');
  }
  final metadata = _lrcMetadata(track.raw ?? '');
  final title =
      metadata.remove('_title')?.toString() ??
      paths.basenameWithoutExtension(file.name);
  final artist = metadata.remove('_artist')?.toString() ?? '';
  return [
    SongDocument(
      id: id,
      title: title,
      artist: artist,
      body: track.sourceLyrics,
      metadata: metadata,
      timingTracks: [track],
      activeTimingTrackId: track.status == TimingStatus.usable
          ? track.id
          : null,
      extra: {'importedFile': file.name},
    ),
  ];
}

Map<String, Object?> _lrcMetadata(String text) {
  String? tag(String name) {
    for (final match in RegExp(
      r'^\s*\[' + name + r':([^\]]*)\]\s*$',
      caseSensitive: false,
      multiLine: true,
    ).allMatches(text)) {
      final value = match.group(1)!.trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  final metadata = <String, Object?>{};
  final title = tag('ti');
  final artist = tag('ar');
  final album = tag('al');
  final lyricist = tag('au');
  final length = tag('length');
  if (title != null) metadata['_title'] = title;
  if (artist != null) metadata['_artist'] = artist;
  if (album != null) metadata['album'] = album;
  if (lyricist != null) metadata['lyricist'] = lyricist;
  if (length != null) {
    final duration = _parseLrcLength(length);
    if (duration != null) metadata['durationSeconds'] = duration;
  }
  return metadata;
}

double? _parseLrcLength(String value) {
  final match = RegExp(
    r'^(?:(\d+):)?(\d{1,2}):(\d{2})(?:\.(\d+))?$',
  ).firstMatch(value.trim());
  if (match == null) return null;
  final hours = int.tryParse(match.group(1) ?? '0');
  final minutes = int.tryParse(match.group(2)!);
  final seconds = int.tryParse(match.group(3)!);
  final fraction = match.group(4);
  if (hours == null ||
      minutes == null ||
      seconds == null ||
      minutes > 59 && match.group(1) != null ||
      seconds > 59) {
    return null;
  }
  final fractionalSeconds = fraction == null
      ? 0.0
      : double.tryParse('0.$fraction') ?? 0.0;
  final total = hours * 3600 + minutes * 60 + seconds + fractionalSeconds;
  return total > 0 && total <= 86400 ? total : null;
}

/// Native file and print integrations; all songs use the same complete .cho.
class VerseFileActions {
  VerseFileActions({
    Future<Directory> Function()? temporaryDirectory,
    Future<ShareResult> Function(ShareParams)? shareFiles,
    Future<Uri?> Function({
      required String fileName,
      required Uint8List bytes,
      required String mimeType,
    })?
    saveFile,
    TargetPlatform? platform,
    this.shareRetention = const Duration(hours: 1),
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _platform = platform ?? defaultTargetPlatform,
       _saveFile = saveFile ?? FilePicker.saveFile,
       _shareFiles =
           shareFiles ?? ((params) => SharePlus.instance.share(params));
  final Future<Directory> Function() _temporaryDirectory;
  final Future<ShareResult> Function(ShareParams) _shareFiles;
  final TargetPlatform _platform;
  final Future<Uri?> Function({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  })
  _saveFile;

  static const MethodChannel _richClipboardChannel = MethodChannel(
    'org.freevia.singbook/rich_clipboard',
  );

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

  /// Copy full song contents as HTML with a plain-text fallback.
  Future<void> copySong(SongDocument song) => _copyRichText(
    label: song.title,
    text: songPlainText(song),
    html: songRichHtml(song),
  );

  /// Copy the setlist cover and every song's complete contents, in entry order.
  Future<void> copySetlist(SetlistDocument setlist, List<SongDocument> songs) =>
      _copyRichText(
        label: setlist.name,
        text: setlistPlainText(setlist, songs),
        html: setlistRichHtml(setlist, songs),
      );

  Future<void> _copyRichText({
    required String label,
    required String text,
    required String html,
  }) async {
    try {
      await _richClipboardChannel.invokeMethod<void>('setHtmlText', {
        'label': label,
        'text': text,
        'html': html,
      });
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

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
  }) async => shareBackupBytes(
    await encodeLibraryPackageAsync(songs, setlists),
    origin: origin,
  );

  Future<ShareResult> shareBackupBytes(
    Uint8List bytes, {
    Rect? origin,
  }) => _share(
    'Singbook-${DateTime.now().toIso8601String().substring(0, 10)}.lyrics-setlist',
    bytes,
    'application/zip',
    'Singbook',
    origin,
  );

  /// Writes a backup through the platform's save dialog so it can go to local
  /// storage or any document provider without a share target. Returns null
  /// when the user dismisses the dialog.
  Future<Uri?> saveBackupBytes(Uint8List bytes) => _saveFile(
    fileName:
        'Singbook-${DateTime.now().toIso8601String().substring(0, 10)}.lyrics-setlist',
    bytes: bytes,
    mimeType: 'application/zip',
  );

  /// Removes stale temporary share copies. Android reports no outcome for a
  /// share, so its copies are otherwise only swept by the next share; call
  /// this at app start or resume too.
  Future<void> cleanUpShareCache() async => _sweepShareDirectories(
    Directory(paths.join((await _temporaryDirectory()).path, 'verse-share')),
  );

  Future<ShareResult> _share(
    String name,
    List<int> bytes,
    String mime,
    String title,
    Rect? origin,
  ) async {
    // A desktop backup/export must work without an installed share target.
    // file_picker writes these bytes after the native Save As confirmation,
    // including overwrite confirmation and the suggested file's extension.
    if (_platform == TargetPlatform.windows ||
        _platform == TargetPlatform.linux ||
        _platform == TargetPlatform.macOS) {
      final saved = await _saveFile(
        fileName: name,
        bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        mimeType: mime,
      );
      return saved == null
          ? const ShareResult('', ShareResultStatus.dismissed)
          : ShareResult(saved.toString(), ShareResultStatus.success);
    }
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

/// The songs of [setlist] in order, each with its entry's key and capo
/// overrides applied (chords transposed to the override key), exactly as the
/// reader shows them. Entries whose song is missing are skipped.
List<SongDocument> _songsInSetlist(
  SetlistDocument setlist,
  List<SongDocument> songs,
) {
  final byId = {for (final song in songs) song.id: song};
  return [
    for (final entry in setlist.entries)
      if (byId[entry.songId] case final song?)
        _applyEntryOverrides(song, entry),
  ];
}

/// Same name as the song list the PDF/print/copy paths use, for tests.
@visibleForTesting
List<SongDocument> songsForSetlist(
  SetlistDocument setlist,
  List<SongDocument> songs,
) => _songsInSetlist(setlist, songs);

int? _keyPitch(String key) {
  final match = RegExp(r'^\s*([A-G])([#b♯♭]?)').firstMatch(key);
  if (match == null) return null;
  const pitches = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  final accidental = match.group(2);
  final shift = accidental == '#' || accidental == '♯'
      ? 1
      : accidental == 'b' || accidental == '♭'
      ? -1
      : 0;
  return (pitches[match.group(1)]! + shift + 12) % 12;
}

SongDocument _applyEntryOverrides(SongDocument song, SetlistEntry entry) {
  final key = entry.overrides['key']?.toString().trim() ?? '';
  final capo = entry.overrides['capo'];
  final hasCapo = capo != null && capo.toString().trim().isNotEmpty;
  if (key.isEmpty && !hasCapo) return song;
  final metadata = Map<String, Object?>.from(song.metadata);
  var body = song.body;
  if (key.isNotEmpty) {
    final from = _keyPitch(song.metadata['key']?.toString() ?? '');
    final to = _keyPitch(key);
    if (from != null && to != null && from != to) {
      body = transposeBody(body, (to - from + 12) % 12);
    }
    metadata['key'] = key;
  }
  if (hasCapo) metadata['capo'] = capo;
  return song.copyWith(body: body, metadata: metadata);
}

List<String> _songMetadataLines(SongDocument song) {
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

/// Plain text counterpart to the song PDF: title, metadata, chord rows, lyrics.
String songPlainText(SongDocument song) {
  final out = StringBuffer(song.title);
  if (song.artist.trim().isNotEmpty) {
    out.write('\nArtist: ${song.artist.trim()}');
  }
  for (final value in _songMetadataLines(song)) {
    out.write('\n$value');
  }
  out.write('\n\n${_songBodyPlainText(song)}');
  return out.toString().trimRight();
}

String setlistPlainText(SetlistDocument setlist, List<SongDocument> songs) {
  final out = StringBuffer(setlist.name);
  final ordered = _songsInSetlist(setlist, songs);
  for (var index = 0; index < ordered.length; index++) {
    final song = ordered[index];
    out.write('\n\n${index + 1}. ${song.title}');
    if (song.artist.trim().isNotEmpty) out.write(' — ${song.artist.trim()}');
  }
  for (final song in ordered) {
    out.write('\n\n${songPlainText(song)}');
  }
  return out.toString().trimRight();
}

String _songBodyPlainText(SongDocument song) {
  final out = StringBuffer();
  for (final line in parseArrangement(song.body)) {
    if (line.directive) {
      final heading = _pdfSectionHeading(line.text);
      if (heading != null) {
        if (out.isNotEmpty) out.write('\n');
        out.writeln(heading);
      }
      continue;
    }
    if (line.chords.isNotEmpty) out.writeln(_chordRow(line));
    out.writeln(line.text);
  }
  return out.toString().trimRight();
}

String _htmlEscape(String value) => const HtmlEscape().convert(value);

/// Receiving apps (Excel, Word, Outlook) collapse runs of spaces in HTML, which
/// destroys chord alignment. Non-breaking spaces survive in all of them; keep
/// the first space of a run breakable unless [all] is set.
String _htmlPreserveSpaces(String escaped, {bool all = false}) => all
    ? escaped.replaceAll(' ', '&nbsp;')
    : escaped.replaceAllMapped(
        RegExp(' {2,}'),
        (m) => ' ${'&nbsp;' * (m.group(0)!.length - 1)}',
      );

String _songBodyRichHtml(SongDocument song) {
  final out = StringBuffer();
  for (final line in parseArrangement(song.body)) {
    if (line.directive) {
      final heading = _pdfSectionHeading(line.text);
      if (heading != null) out.write('<h2>${_htmlEscape(heading)}</h2>');
      continue;
    }
    if (line.text.trim().isEmpty && line.chords.isEmpty) {
      out.write('<br>');
      continue;
    }
    if (line.chords.isNotEmpty) {
      out.write(
        '<div class="chords"><code style="white-space:pre">'
        '${_htmlPreserveSpaces(_htmlEscape(_chordRow(line)), all: true)}'
        '</code></div>',
      );
    }
    out.write(
      '<p>${_htmlPreserveSpaces(_htmlEscape(line.text.isEmpty ? ' ' : line.text))}</p>',
    );
  }
  return out.toString();
}

String songRichHtml(SongDocument song) =>
    '<!doctype html><html><body><article>'
    '<h1>${_htmlEscape(song.title)}</h1>'
    '${song.artist.trim().isEmpty ? '' : '<p><strong>Artist:</strong> ${_htmlEscape(song.artist.trim())}</p>'}'
    '${_songMetadataLines(song).map((line) => '<p class="metadata">${_htmlEscape(line)}</p>').join()}'
    '${_songBodyRichHtml(song)}'
    '</article></body></html>';

String setlistRichHtml(SetlistDocument setlist, List<SongDocument> songs) {
  final ordered = _songsInSetlist(setlist, songs);
  final out = StringBuffer(
    '<!doctype html><html><body><article><h1>${_htmlEscape(setlist.name)}</h1>',
  );
  for (var index = 0; index < ordered.length; index++) {
    final song = ordered[index];
    out.write(
      '<p class="setlist-entry">${index + 1}. ${_htmlEscape(song.title)}',
    );
    if (song.artist.trim().isNotEmpty) {
      out.write(' — ${_htmlEscape(song.artist.trim())}');
    }
    out.write('</p>');
  }
  for (final song in ordered) {
    out.write('<section><h1>${_htmlEscape(song.title)}</h1>');
    if (song.artist.trim().isNotEmpty) {
      out.write(
        '<p><strong>Artist:</strong> ${_htmlEscape(song.artist.trim())}</p>',
      );
    }
    for (final value in _songMetadataLines(song)) {
      out.write('<p class="metadata">${_htmlEscape(value)}</p>');
    }
    out.write(_songBodyRichHtml(song));
    out.write('</section>');
  }
  out.write('</article></body></html>');
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
  List<SetlistDocument> setlists, {
  Map<String, Object?>? preferences,
}) {
  // Fail before doing any work when the result could not be restored.
  if (songs.length > maxBackupSongs) {
    throw const FormatException('backup_too_large');
  }
  final archive = Archive();
  final names = <String, String>{};
  final hashes = <String, String>{};
  var uncompressed = 0;
  for (final song in songs) {
    // Entry names come from a running index, so two songs with one id can
    // never share a slot and produce an archive the manifest does not describe.
    if (names.containsKey(song.id)) {
      throw const FormatException('duplicate_song_id');
    }
    final name = 'songs/${names.length}.json';
    names[song.id] = name;
    final encoded = utf8.encode(jsonEncode(_songBackupJson(song)));
    if (encoded.length > maxImportBytes) {
      throw const FormatException('backup_too_large');
    }
    uncompressed += encoded.length;
    hashes[name] = sha256.convert(encoded).toString();
    archive.add(ArchiveFile.bytes(name, encoded));
  }
  final safePreferences = preferences == null
      ? null
      : selectBackupPreferences(preferences);
  final manifest = utf8.encode(
    jsonEncode({
      'schemaVersion': 3,
      'songs': names,
      'hashes': hashes,
      'setlists': setlists.map((s) => s.toJson()).toList(),
      'preferences': ?safePreferences,
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
  const ImportedCollection(
    this.songs,
    this.setlists, {
    this.preferences,
    this.schemaVersion = 1,
  });
  final List<SongDocument> songs;
  final List<SetlistDocument> setlists;

  /// Null when the package did not include portable preferences.
  final Map<String, Object?>? preferences;
  final int schemaVersion;
}

JsonMap _songBackupJson(SongDocument song) => song.toJson();

SongDocument _songFromBackupJson(Object? value) {
  if (value is! Map) throw const FormatException('invalid_archive');
  final raw = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) throw const FormatException('invalid_archive');
    raw[entry.key as String] = entry.value;
  }
  const requiredStringKeys = {
    'id',
    'title',
    'artist',
    'body',
    'createdAt',
    'updatedAt',
  };
  const allowedKeys = {
    'id',
    'title',
    'artist',
    'body',
    'metadata',
    'sources',
    'timingTracks',
    'favorite',
    'createdAt',
    'updatedAt',
    'selectedRecording',
    'activeTimingTrackId',
    'revision',
    'extra',
    'preservedExtensions',
    'extensionError',
  };
  if (requiredStringKeys.any((key) => raw[key] is! String) ||
      raw.keys.any((key) => !allowedKeys.contains(key)) ||
      raw['metadata'] is! Map ||
      raw['sources'] is! List ||
      raw['timingTracks'] is! List ||
      raw['favorite'] is! bool ||
      raw['revision'] is! int ||
      raw['extra'] is! Map ||
      raw['preservedExtensions'] is! List ||
      (raw['activeTimingTrackId'] != null &&
          raw['activeTimingTrackId'] is! String) ||
      (raw['extensionError'] != null && raw['extensionError'] is! String) ||
      (raw['selectedRecording'] != null && raw['selectedRecording'] is! Map)) {
    throw const FormatException('invalid_archive');
  }
  if (!_validBackupTimestamp(raw['createdAt']) ||
      !_validBackupTimestamp(raw['updatedAt'])) {
    throw const FormatException('invalid_archive');
  }
  try {
    return SongDocument.fromJson(raw);
  } on FormatException {
    rethrow;
  } on Object {
    throw const FormatException('invalid_archive');
  }
}

bool _validBackupTimestamp(Object? value) =>
    value is String && DateTime.tryParse(value) != null;

void _validateSetlistBackupTimestamps(
  JsonMap value, {
  required bool requireFields,
}) {
  for (final key in const ['createdAt', 'updatedAt']) {
    final timestamp = value[key];
    if ((requireFields && !_validBackupTimestamp(timestamp)) ||
        (!requireFields &&
            timestamp != null &&
            !_validBackupTimestamp(timestamp))) {
      throw const FormatException('invalid_archive');
    }
  }
}

enum BackupRestoreMode { merge, replace }

class BackupPreview {
  const BackupPreview({
    required this.schemaVersion,
    required this.songCount,
    required this.setlistCount,
    required this.includedPreferenceKeys,
    required this.identicalSongCount,
    required this.conflictingSongCount,
    required this.identicalSetlistCount,
    required this.conflictingSetlistCount,
    required this.token,
  });
  final int schemaVersion;
  final int songCount, setlistCount;
  final List<String> includedPreferenceKeys;
  final int identicalSongCount, conflictingSongCount;
  final int identicalSetlistCount, conflictingSetlistCount;
  final String token;
  bool get hasPreferences => includedPreferenceKeys.isNotEmpty;
  int get conflictCount => conflictingSongCount + conflictingSetlistCount;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.mode,
    required this.importedSongCount,
    required this.importedSetlistCount,
    required this.preferencesRestored,
  });
  final BackupRestoreMode mode;
  final int importedSongCount, importedSetlistCount;
  final bool preferencesRestored;
}

Map<String, Object?> selectBackupPreferences(Map<String, Object?> settings) {
  final result = <String, Object?>{};
  for (final key in backupPreferenceKeys) {
    if (!settings.containsKey(key)) continue;
    final value = settings[key];
    if (_validBackupPreference(key, value)) result[key] = value;
  }
  return result;
}

bool _validBackupPreference(String key, Object? value) => switch (key) {
  'themeMode' => const {'system', 'light', 'dark'}.contains(value),
  'palette' => const {'navy', 'sage', 'ocean', 'clay', 'plum'}.contains(value),
  'fontFamily' => const {
    'system',
    'serif',
    'mono',
    'lora',
    'nunito',
    'sourceSans',
  }.contains(value),
  'readerFontSize' =>
    value is num && value.isFinite && value >= 18 && value <= 36,
  'locale' =>
    value == null || value is String && RegExp(r'^[a-z]{2,3}$').hasMatch(value),
  'showChords' ||
  'showSections' ||
  'playerControlsExpanded' ||
  'lastSongsFavoritesOnly' ||
  'autoscroll' => value is bool,
  'timingMode' => const {'estimated', 'timed', 'manual'}.contains(value),
  'defaultView' => const {
    'home',
    'songs',
    'setlists',
    'settings',
  }.contains(value),
  'startupSongsView' => const {
    'recent',
    'library',
    'favorites',
    'online',
    'last',
  }.contains(value),
  'lastSongsView' => const {
    'recent',
    'library',
    'favorites',
    'online',
  }.contains(value),
  'catalog' =>
    value is String && RegExp(r'^[a-z][a-z0-9_-]{0,63}$').hasMatch(value),
  'providers' =>
    value is Map &&
        value.entries.every(
          (entry) =>
              entry.key is String &&
              RegExp(
                r'^[a-z][a-z0-9_-]{0,63}$',
              ).hasMatch(entry.key as String) &&
              entry.value is bool,
        ),
  _ => false,
};

Map<String, Object?> _decodeBackupPreferences(Object? value) {
  if (value is! Map) throw const FormatException('invalid_archive');
  final raw = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) throw const FormatException('invalid_archive');
    raw[entry.key as String] = entry.value;
  }
  if (raw.keys.any((key) => !backupPreferenceKeys.contains(key)) ||
      raw.entries.any(
        (entry) => !_validBackupPreference(entry.key, entry.value),
      )) {
    throw const FormatException('invalid_archive');
  }
  return raw;
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

/// [encodeLibraryPackage] on a background isolate, for large libraries.
Future<Uint8List> encodeLibraryPackageAsync(
  List<SongDocument> songs,
  List<SetlistDocument> setlists, {
  Map<String, Object?>? preferences,
}) => _runInBackground(
  () => encodeLibraryPackage(songs, setlists, preferences: preferences),
);

/// [decodeLibraryPackage] on a background isolate, for large backups.
Future<ImportedCollection> decodeLibraryPackageAsync(Uint8List bytes) =>
    _runInBackground(() => decodeLibraryPackage(bytes));

/// Runs [work] on a worker isolate so zip, hashing and PDF layout never block
/// frames. Falls back to the calling isolate only when the arguments cannot be
/// sent to another isolate; errors thrown by [work] are rethrown unchanged.
Future<T> _runInBackground<T>(FutureOr<T> Function() work) async {
  try {
    return await Isolate.run(work);
  } on IsolateSpawnException {
    return work();
  } on ArgumentError {
    return work();
  }
}

/// Validates central-directory sizes and file kinds before ZipDecoder can
/// allocate entry content. This app never emits ZIP64 archives, so rejecting
/// ZIP64 records also keeps their unbounded size fields out of the decoder.
void _preflightZipDirectory(Uint8List bytes) {
  Never invalid() => throw const FormatException('invalid_archive');
  if (bytes.length < 22) invalid();
  final data = ByteData.sublistView(bytes);
  final earliest = bytes.length > 22 + 0xffff ? bytes.length - 22 - 0xffff : 0;
  var endOffset = -1;
  for (var i = bytes.length - 22; i >= earliest; i--) {
    if (data.getUint32(i, Endian.little) != 0x06054b50) continue;
    final commentLength = data.getUint16(i + 20, Endian.little);
    if (i + 22 + commentLength == bytes.length) {
      endOffset = i;
      break;
    }
  }
  if (endOffset < 0) invalid();
  if (endOffset >= 20 &&
      data.getUint32(endOffset - 20, Endian.little) == 0x07064b50) {
    invalid(); // ZIP64 end-of-central-directory locator.
  }
  final diskNumber = data.getUint16(endOffset + 4, Endian.little);
  final centralDisk = data.getUint16(endOffset + 6, Endian.little);
  final entriesOnDisk = data.getUint16(endOffset + 8, Endian.little);
  final entryCount = data.getUint16(endOffset + 10, Endian.little);
  final centralSize = data.getUint32(endOffset + 12, Endian.little);
  final centralOffset = data.getUint32(endOffset + 16, Endian.little);
  if (diskNumber != 0 ||
      centralDisk != 0 ||
      entriesOnDisk != entryCount ||
      entryCount == 0xffff ||
      centralSize == 0xffffffff ||
      centralOffset == 0xffffffff ||
      entryCount > maxBackupSongs + 1 + _maxBackupDirectoryEntries ||
      centralOffset + centralSize != endOffset) {
    invalid();
  }

  var cursor = centralOffset;
  var fileCount = 0, directoryCount = 0;
  var compressedTotal = 0, uncompressedTotal = 0;
  for (var i = 0; i < entryCount; i++) {
    if (cursor < 0 ||
        cursor + 46 > endOffset ||
        data.getUint32(cursor, Endian.little) != 0x02014b50) {
      invalid();
    }
    final madeBy = data.getUint16(cursor + 4, Endian.little);
    final flags = data.getUint16(cursor + 8, Endian.little);
    final method = data.getUint16(cursor + 10, Endian.little);
    final compressedSize = data.getUint32(cursor + 20, Endian.little);
    final uncompressedSize = data.getUint32(cursor + 24, Endian.little);
    final nameLength = data.getUint16(cursor + 28, Endian.little);
    final extraLength = data.getUint16(cursor + 30, Endian.little);
    final commentLength = data.getUint16(cursor + 32, Endian.little);
    final startDisk = data.getUint16(cursor + 34, Endian.little);
    final externalAttributes = data.getUint32(cursor + 38, Endian.little);
    final localOffset = data.getUint32(cursor + 42, Endian.little);
    final recordEnd = cursor + 46 + nameLength + extraLength + commentLength;
    if (recordEnd > endOffset ||
        nameLength == 0 ||
        compressedSize == 0xffffffff ||
        uncompressedSize == 0xffffffff ||
        startDisk != 0 ||
        localOffset == 0xffffffff ||
        localOffset >= centralOffset ||
        (flags & 0x41) != 0 || // encrypted / strong encryption
        (method != 0 && method != 8)) {
      invalid();
    }
    final hostSystem = madeBy >> 8;
    final unixMode = externalAttributes >> 16;
    if (hostSystem == 3 && (unixMode & 0xf000) == 0xa000) {
      invalid(); // Symlink entries are never needed in a library package.
    }

    final nameBytes = bytes.sublist(cursor + 46, cursor + 46 + nameLength);
    String name;
    try {
      name = utf8.decode(nameBytes);
    } on FormatException {
      invalid();
    }
    if (!_safeEntryName(name)) invalid();
    var extraCursor = cursor + 46 + nameLength;
    final extraEnd = extraCursor + extraLength;
    while (extraCursor < extraEnd) {
      if (extraCursor + 4 > extraEnd) invalid();
      final extraId = data.getUint16(extraCursor, Endian.little);
      final fieldLength = data.getUint16(extraCursor + 2, Endian.little);
      extraCursor += 4;
      if (extraCursor + fieldLength > extraEnd || extraId == 0x0001) {
        invalid(); // ZIP64 size/offset extension.
      }
      extraCursor += fieldLength;
    }

    final isDirectory = name.endsWith('/');
    if (isDirectory) {
      directoryCount++;
      if (uncompressedSize != 0) invalid();
    } else {
      fileCount++;
      if (uncompressedSize > maxImportBytes) invalid();
    }
    compressedTotal += compressedSize;
    uncompressedTotal += uncompressedSize;
    if (directoryCount > _maxBackupDirectoryEntries ||
        fileCount > maxBackupSongs + 1 ||
        compressedTotal > maxBackupBytes ||
        uncompressedTotal > maxBackupUncompressedBytes) {
      invalid();
    }
    cursor = recordEnd;
  }
  if (cursor != endOffset) invalid();
}

/// Complete validation precedes any database writes. No archive paths are extracted.
ImportedCollection decodeLibraryPackage(Uint8List bytes) {
  if (bytes.length > maxBackupBytes) {
    throw const FormatException('file_too_large');
  }
  if (!looksLikeZip(bytes)) throw const FormatException('invalid_archive');
  _preflightZipDirectory(bytes);
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
  final schemaVersion = manifest['schemaVersion'];
  if ((schemaVersion != 1 && schemaVersion != 2 && schemaVersion != 3) ||
      manifest['songs'] is! Map ||
      manifest['setlists'] is! List) {
    throw const FormatException('unsupported_archive');
  }
  final preferences =
      schemaVersion == 2 ||
          (schemaVersion == 3 && manifest.containsKey('preferences'))
      ? _decodeBackupPreferences(manifest['preferences'])
      : null;
  final songs = <SongDocument>[];
  final expected = stringMap(manifest['songs']);
  final hashes = stringMap(manifest['hashes']);
  if (expected.length > maxBackupSongs) {
    throw const FormatException('invalid_archive');
  }
  for (final entry in expected.entries) {
    final extension = schemaVersion == 3 ? '.json' : '.cho';
    final file = archive.find(entry.value);
    if (file == null ||
        !file.isFile ||
        !_safeEntryName(entry.value) ||
        !entry.value.endsWith(extension)) {
      throw const FormatException('invalid_archive');
    }
    final data = _readEntry(file, maxImportBytes, budget);
    if (hashes[entry.value] != sha256.convert(data).toString()) {
      throw const FormatException('invalid_archive_hash');
    }
    file.closeSync();
    final SongDocument song;
    if (schemaVersion == 3) {
      try {
        song = _songFromBackupJson(jsonDecode(utf8.decode(data)));
      } on FormatException catch (error) {
        if (error.message == 'invalid_archive') rethrow;
        throw const FormatException('invalid_archive');
      } on Object {
        throw const FormatException('invalid_archive');
      }
    } else {
      song = ChordProCodec().decode(decodeImportedText(data));
    }
    if (song.id != entry.key) {
      throw const FormatException('invalid_archive_identity');
    }
    songs.add(song);
  }
  if (expected.values.toSet().length != expected.length ||
      files != songs.length + 1) {
    throw const FormatException('invalid_archive');
  }
  final setlists = (manifest['setlists'] as List).map((value) {
    final json = jsonMap(value);
    _validateSetlistBackupTimestamps(json, requireFields: schemaVersion == 3);
    return SetlistDocument.fromJson(json);
  }).toList();
  final entryIds = <String>{};
  if (setlists.map((s) => s.id).toSet().length != setlists.length ||
      setlists.any(
        (s) => s.entries.any(
          (e) => !expected.containsKey(e.songId) || !entryIds.add(e.id),
        ),
      )) {
    throw const FormatException('missing_song_references');
  }
  return ImportedCollection(
    songs,
    setlists,
    preferences: preferences,
    schemaVersion: schemaVersion as int,
  );
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

// ---------------------------------------------------------------------------
// PDF export
// ---------------------------------------------------------------------------

const _lyricSize = 10.0;
const _chordSize = 8.5;

/// Largest number of lyric lines one export may lay out. Beyond this the work
/// would stall a phone for minutes and exhaust memory.
const maxPdfLines = 60000;

const _regularAsset = 'assets/fonts/NotoSans-Regular.ttf';
const _boldAsset = 'assets/fonts/NotoSans-Bold.ttf';
const _monoAsset = 'assets/fonts/NotoSansMono-Regular.ttf';

/// Scripts the Latin/Cyrillic/Greek Noto Sans fonts cannot draw. Each is a
/// separate regular-weight file; the CJK pair is large, so it is only loaded
/// (and only embedded in the PDF) when the text needs it.
const _scriptFallbackAssets = [
  'assets/fonts/NotoSansArabic-Regular.ttf',
  'assets/fonts/NotoSansHebrew-Regular.ttf',
  'assets/fonts/NotoSansDevanagari-Regular.ttf',
  'assets/fonts/NotoSansThai-Regular.ttf',
];
const _cjkFallbackAssets = [
  'assets/fonts/NotoSansSC-Subset-Regular.ttf',
  'assets/fonts/NotoSansKR-Hangul-Regular.ttf',
];

// CJK symbols and ideographs, kana, Hangul, compatibility and full-width forms.
final _cjkPattern = RegExp(r'[⺀-힯豈-﫿＀-￯]');

final _fontAssetCache = <String, Future<Uint8List>>{};

Future<Uint8List> _fontAsset(String path) {
  return _fontAssetCache.putIfAbsent(path, () async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      _fontAssetCache.remove(path);
      rethrow;
    }
  });
}

/// Font files for one PDF job (plain bytes, so they can cross isolates).
class _PdfFontBytes {
  const _PdfFontBytes(this.regular, this.bold, this.mono, this.fallbacks);
  final Uint8List regular, bold, mono;
  final List<Uint8List> fallbacks;
}

class _PdfFonts {
  _PdfFonts(_PdfFontBytes bytes)
    : regular = pw.Font.ttf(ByteData.sublistView(bytes.regular)),
      bold = pw.Font.ttf(ByteData.sublistView(bytes.bold)),
      mono = pw.Font.ttf(ByteData.sublistView(bytes.mono)),
      _fallbackFonts = [
        for (final data in bytes.fallbacks)
          pw.Font.ttf(ByteData.sublistView(data)),
      ] {
    final regularFace = PdfFontFace.parse(bytes.regular);
    final monoFace = PdfFontFace.parse(bytes.mono);
    final faces = [for (final data in bytes.fallbacks) PdfFontFace.parse(data)];
    sansFaces = [regularFace, monoFace, ...faces];
    monoFaces = [monoFace, regularFace, ...faces];
  }

  final pw.Font regular, bold, mono;
  final List<pw.Font> _fallbackFonts;

  /// Coverage chains in drawing order (primary font first), used both to
  /// measure text and to find characters no bundled font can draw.
  late final List<PdfFontFace> sansFaces, monoFaces;

  /// Fonts the pdf package tries, in order, for a character the style's own
  /// font lacks. Mono comes first because only it has the sharp/flat signs
  /// and the true minus sign that key and capo fields use.
  List<pw.Font> get fallback => [mono, regular, ..._fallbackFonts];

  pw.TextStyle sans({
    double? fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
  }) => pw.TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontFallback: fallback,
  );

  pw.TextStyle monospace({
    required double fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
  }) => pw.TextStyle(
    font: mono,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontFallback: fallback,
  );
}

/// Replaces characters that no bundled font can draw with U+FFFD and removes
/// invisible format characters, remembering what was replaced so the PDF can
/// say so. The pdf package would otherwise draw an empty box silently.
class _Sanitizer {
  final Set<int> missing = {};

  static bool _ignorable(int rune) =>
      (rune >= 0x200b && rune <= 0x200f) ||
      (rune >= 0x2028 && rune <= 0x202e) ||
      (rune >= 0x2060 && rune <= 0x2064) ||
      (rune >= 0xfe00 && rune <= 0xfe0f) ||
      rune == 0xfeff;

  String clean(String text, List<PdfFontFace> chain) {
    final out = StringBuffer();
    for (final rune in text.runes) {
      if (rune == 0x0a) {
        out.writeCharCode(rune);
      } else if (rune == 0x09) {
        out.write('    ');
      } else if (rune < 0x20 || rune == 0x7f || _ignorable(rune)) {
        continue;
      } else if (chain.any((face) => face.supports(rune))) {
        out.writeCharCode(rune);
      } else {
        missing.add(rune);
        out.writeCharCode(0xfffd);
      }
    }
    return out.toString();
  }

  /// One line for the page, or null when everything could be drawn.
  String? get notice {
    if (missing.isEmpty) return null;
    final sample = (missing.toList()..sort())
        .take(4)
        .map((rune) => 'U+${rune.toRadixString(16).toUpperCase()}')
        .join(', ');
    final more = missing.length > 4 ? ', ...' : '';
    return 'Note: ${missing.length} character(s) in this text are not '
        'available in the PDF fonts and are shown as \u{FFFD} ($sample$more).';
  }
}

double _measure(String text, List<PdfFontFace> chain, double size) {
  var width = 0.0;
  for (final rune in text.runes) {
    for (final face in chain) {
      if (face.supports(rune)) {
        width += face.advance(rune, size);
        break;
      }
    }
  }
  return width;
}

final _letter = RegExp(r'\p{L}', unicode: true);
final _rtlLetter = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]', unicode: true);

/// True when most letters of [text] belong to a right-to-left script.
bool isRightToLeftText(String text) {
  var letters = 0, rtl = 0;
  for (final match in _letter.allMatches(text)) {
    letters++;
    if (_rtlLetter.hasMatch(match.group(0)!)) rtl++;
  }
  return letters > 0 && rtl * 2 > letters;
}

class _ChordPlacement {
  const _ChordPlacement(this.x, this.label);
  final double x;
  final String label;
}

class _LineChunk {
  const _LineChunk(this.text, this.chords, {this.rtl = false});
  final String text;
  final List<_ChordPlacement> chords;
  final bool rtl;
}

/// Splits one chorded lyric line into rows that fit [maxWidth] and positions
/// each chord at the measured width of the lyric before it. Chords (8.5 pt)
/// and lyrics (10 pt) share one monospaced face but not one column pitch, so
/// padding with spaces drifts; absolute positions do not. Offsets in
/// [ArrangementLine.chords] count grapheme clusters, so rows are cut on
/// cluster boundaries and chords keep their anchor.
List<_LineChunk> _layoutChordedLine(
  ArrangementLine line,
  _Sanitizer sanitizer,
  List<PdfFontFace> chain,
  double maxWidth,
) {
  if (isRightToLeftText(line.text)) {
    // Syllable anchoring is not defined for bidirectional text: list the
    // chords above the line instead of placing them over wrong letters.
    final labels = [
      for (final anchor in line.chords) sanitizer.clean(anchor.chord, chain),
    ];
    final texts = _pdfTextChunks(sanitizer.clean(line.text, chain));
    return [
      for (var index = 0; index < texts.length; index++)
        _LineChunk(texts[index], [
          if (index == 0 && labels.isNotEmpty)
            _ChordPlacement(0, labels.join('   ')),
        ], rtl: true),
    ];
  }
  final graphemes = [
    for (final cluster in line.text.characters) sanitizer.clean(cluster, chain),
  ];
  final widths = [
    for (final cluster in graphemes) _measure(cluster, chain, _lyricSize),
  ];
  final limit = maxWidth * 0.995;
  final minGap = _measure(' ', chain, _chordSize);
  final chunks = <_LineChunk>[];
  var start = 0;
  do {
    var width = 0.0, end = start, lastBreak = -1;
    while (end < graphemes.length) {
      if (width + widths[end] > limit && end > start) break;
      width += widths[end];
      end++;
      final cluster = graphemes[end - 1];
      if (cluster.isNotEmpty && cluster.trim().isEmpty) lastBreak = end;
    }
    if (end < graphemes.length && lastBreak > start) end = lastBreak;
    final last = end >= graphemes.length;
    final placements = <_ChordPlacement>[];
    var previousEnd = -minGap;
    for (final anchor in line.chords) {
      final at = anchor.offset;
      if (at < start || (!last && at >= end)) continue;
      final offset = at > end ? end : at;
      var x = 0.0;
      for (var i = start; i < offset; i++) {
        x += widths[i];
      }
      final label = sanitizer.clean(anchor.chord, chain);
      final labelWidth = _measure(label, chain, _chordSize);
      // Keep neighbours apart, and keep the final chord on the page.
      if (x < previousEnd + minGap) x = previousEnd + minGap;
      if (x + labelWidth > limit) {
        final shifted = limit - labelWidth;
        x = shifted > previousEnd + minGap ? shifted : previousEnd + minGap;
      }
      placements.add(_ChordPlacement(x, label));
      previousEnd = x + labelWidth;
    }
    chunks.add(_LineChunk(graphemes.sublist(start, end).join(), placements));
    start = end;
  } while (start < graphemes.length);
  return chunks;
}

/// Row text and chord x positions (points) for [line] as the PDF lays them
/// out, for tests.
@visibleForTesting
List<({String text, List<({double x, String chord})> chords})>
layoutChordedRowsForTest(
  ArrangementLine line,
  List<PdfFontFace> chain,
  double maxWidth,
) => [
  for (final chunk in _layoutChordedLine(line, _Sanitizer(), chain, maxWidth))
    (
      text: chunk.text,
      chords: [for (final c in chunk.chords) (x: c.x, chord: c.label)],
    ),
];

/// Everything a PDF job needs, as plain data that can cross isolates.
class _PdfJob {
  _PdfJob(this.songs, this.format, this.setlist, this.fonts);
  final List<SongDocument> songs;
  final PdfPageFormat format;
  final SetlistDocument? setlist;
  final _PdfFontBytes fonts;
}

/// Only what printing reads, so large timing payloads are not copied between
/// isolates.
SongDocument _printable(SongDocument song) => SongDocument(
  id: song.id,
  title: song.title,
  artist: song.artist,
  body: song.body,
  metadata: song.metadata,
);

bool _hasCjk(SongDocument song) =>
    _cjkPattern.hasMatch(song.title) ||
    _cjkPattern.hasMatch(song.artist) ||
    _cjkPattern.hasMatch(song.body) ||
    song.metadata.values.any((value) => _cjkPattern.hasMatch('$value'));

/// Code points in [texts] that no bundled PDF font can draw (they print as a
/// visible U+FFFD with a note on the page). Lets a caller warn before export.
Future<List<int>> unprintableCharacters(Iterable<String> texts) async {
  final all = texts.toList();
  final needsCjk = all.any(_cjkPattern.hasMatch);
  final chain = [
    PdfFontFace.parse(await _fontAsset(_regularAsset)),
    PdfFontFace.parse(await _fontAsset(_monoAsset)),
    for (final path in [
      ..._scriptFallbackAssets,
      if (needsCjk) ..._cjkFallbackAssets,
    ])
      PdfFontFace.parse(await _fontAsset(path)),
  ];
  final sanitizer = _Sanitizer();
  for (final text in all) {
    sanitizer.clean(text, chain);
  }
  return sanitizer.missing.toList()..sort();
}

Future<Uint8List> createSongPdf(
  List<SongDocument> songs, {
  PdfPageFormat format = PdfPageFormat.a4,
  SetlistDocument? setlist,
}) async {
  final needsCjk =
      songs.any(_hasCjk) ||
      (setlist != null && _cjkPattern.hasMatch(setlist.name));
  final fonts = _PdfFontBytes(
    await _fontAsset(_regularAsset),
    await _fontAsset(_boldAsset),
    await _fontAsset(_monoAsset),
    [
      for (final path in [
        ..._scriptFallbackAssets,
        if (needsCjk) ..._cjkFallbackAssets,
      ])
        await _fontAsset(path),
    ],
  );
  final job = _PdfJob(
    [for (final song in songs) _printable(song)],
    format,
    setlist,
    fonts,
  );
  return _runInBackground(() => _buildSongPdf(job));
}

Future<Uint8List> _buildSongPdf(_PdfJob job) async {
  final songs = job.songs;
  final format = job.format;
  final setlist = job.setlist;
  final fonts = _PdfFonts(job.fonts);
  const navy = PdfColor.fromInt(0xff173454);
  const muted = PdfColor.fromInt(0xff5f6b78);
  const paleBlue = PdfColor.fromInt(0xfff1f5f9);
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
    theme: pw.ThemeData.withFont(
      base: fonts.regular,
      bold: fonts.bold,
      fontFallback: fonts.fallback,
    ),
  );
  if (setlist != null) {
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        maxPages: 1000,
        build: (context) {
          final sanitizer = _Sanitizer();
          String clean(String text) => sanitizer.clean(text, fonts.sansFaces);
          final widgets = <pw.Widget>[
            pw.Text(
              clean(setlist.name),
              style: fonts.sans(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: navy,
              ),
            ),
            for (var i = 0; i < songs.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  clean(
                    '${i + 1}. ${songs[i].title}${songs[i].artist.trim().isEmpty ? '' : ' — ${songs[i].artist.trim()}'}',
                  ),
                  style: fonts.sans(fontSize: 22),
                  overflow: pw.TextOverflow.span,
                ),
              ),
          ];
          final notice = sanitizer.notice;
          if (notice != null) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  notice,
                  style: fonts.sans(fontSize: 8, color: muted),
                ),
              ),
            );
          }
          return widgets;
        },
      ),
    );
  }
  var totalLines = 0;
  for (var songIndex = 0; songIndex < songs.length; songIndex++) {
    final song = songs[songIndex];
    final lines = parseArrangement(song.body);
    totalLines += lines.length;
    if (totalLines > maxPdfLines) {
      throw const FormatException('pdf_too_large');
    }
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        maxPages: 1000,
        build: (context) {
          final sanitizer = _Sanitizer();
          final title = sanitizer.clean(song.title, fonts.sansFaces);
          final body = _pdfSongBody(
            lines,
            context: context,
            format: format,
            metadata: [
              if (song.artist.trim().isNotEmpty)
                'Artist: ${song.artist.trim()}',
              ..._songMetadataLines(song),
            ],
            fonts: fonts,
            sanitizer: sanitizer,
            navy: navy,
            muted: muted,
            paleBlue: paleBlue,
          );
          final notice = sanitizer.notice;
          return [
            pw.Text(
              title,
              style: fonts.sans(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (notice != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  notice,
                  style: fonts.sans(fontSize: 8, color: muted),
                ),
              ),
            ...body,
          ];
        },
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
  required _PdfFonts fonts,
  required _Sanitizer sanitizer,
  required PdfColor navy,
  required PdfColor muted,
  required PdfColor paleBlue,
}) {
  final margin = pw.PageTheme(
    pageFormat: format,
  ).margin!.resolve(pw.TextDirection.ltr);
  final contentWidth = format.width - margin.horizontal;
  final columnWidth = contentWidth - 10;
  final lyricWidth = metadata.isEmpty ? contentWidth : columnWidth * .7;
  final metadataWidth = columnWidth * .3;
  final chordStyle = fonts.monospace(
    fontSize: _chordSize,
    fontWeight: pw.FontWeight.bold,
    color: navy,
  );

  pw.Widget lyricRow(_LineChunk chunk) {
    pw.Widget? chordRow;
    if (chunk.chords.isNotEmpty) {
      if (chunk.rtl) {
        chordRow = pw.SizedBox(
          width: lyricWidth,
          child: pw.Text(
            chunk.chords.first.label,
            style: chordStyle,
            textAlign: pw.TextAlign.right,
            softWrap: false,
          ),
        );
      } else {
        var previousEnd = 0.0;
        final cells = <pw.Widget>[];
        for (final chord in chunk.chords) {
          cells
            ..add(pw.SizedBox(width: chord.x - previousEnd))
            ..add(pw.Text(chord.label, style: chordStyle, softWrap: false));
          previousEnd =
              chord.x + _measure(chord.label, fonts.monoFaces, _chordSize);
        }
        chordRow = pw.Row(mainAxisSize: pw.MainAxisSize.min, children: cells);
      }
    }
    final lyric = pw.Text(
      chunk.text.isEmpty ? ' ' : chunk.text,
      style: fonts.monospace(fontSize: _lyricSize),
      textDirection: chunk.rtl ? pw.TextDirection.rtl : null,
      textAlign: chunk.rtl ? pw.TextAlign.right : null,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 0.8),
      child: pw.Inseparable(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            ?chordRow,
            chunk.rtl ? pw.SizedBox(width: lyricWidth, child: lyric) : lyric,
          ],
        ),
      ),
    );
  }

  final lyricRows = <pw.Widget>[];
  final pendingHeadings = <pw.Widget>[];
  final pendingSpacing = <pw.Widget>[];
  void appendBodyRows(List<pw.Widget> rows) {
    if (pendingHeadings.isEmpty || rows.isEmpty) {
      lyricRows.addAll(rows);
      return;
    }
    lyricRows.add(
      pw.Inseparable(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [...pendingHeadings, ...pendingSpacing, rows.first],
        ),
      ),
    );
    lyricRows.addAll(rows.skip(1));
    pendingHeadings.clear();
    pendingSpacing.clear();
  }

  for (final line in lines) {
    final heading = line.directive ? _pdfSectionHeading(line.text) : null;
    if (heading != null) {
      pendingHeadings.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 5, bottom: 2),
          child: pw.Text(
            sanitizer.clean(heading, fonts.sansFaces),
            style: fonts.sans(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: muted,
            ),
          ),
        ),
      );
      continue;
    } else if (!line.directive &&
        line.text.trim().isEmpty &&
        line.chords.isEmpty) {
      final spacing = pw.SizedBox(height: 5);
      if (pendingHeadings.isEmpty) {
        lyricRows.add(spacing);
      } else {
        pendingSpacing.add(spacing);
      }
    } else if (!line.directive) {
      final chunks = line.chords.isEmpty
          ? [
              for (final text in _pdfTextChunks(
                sanitizer.clean(line.text, fonts.monoFaces),
              ))
                _LineChunk(text, const [], rtl: isRightToLeftText(text)),
            ]
          : _layoutChordedLine(line, sanitizer, fonts.monoFaces, lyricWidth);
      appendBodyRows(chunks.map(lyricRow).toList());
    }
  }
  // Preserve meaningful terminal headings and notes even when no body row
  // follows them; the PDF should match the arrangement the user authored.
  lyricRows
    ..addAll(pendingHeadings)
    ..addAll(pendingSpacing);

  final metadataWidgets = <pw.Widget>[];
  for (final value in metadata) {
    final chunks = _pdfTextChunks(sanitizer.clean(value, fonts.sansFaces));
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
            style: fonts.sans(fontSize: 8, color: navy),
          ),
        ),
      );
    }
  }

  if (metadataWidgets.isEmpty) return lyricRows;

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

/// Break exceptional single rows into bounded continuations so each piece can
/// stay together and still fit on a page. The limit is a conservative text-size
/// bound, not a page-height estimate; ordinary text remains unchanged. Chunk
/// boundaries prefer whitespace and never split a grapheme cluster when a long
/// unbroken token needs splitting. Chorded lines are cut by measured width
/// instead (see [_layoutChordedLine]).
const _pdfTextChunkLength = 320;

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

/// Directive names that carry free text which the reader shows as a note.
const _commentDirectives = {
  'comment',
  'c',
  'comment italic',
  'ci',
  'comment box',
  'cb',
};

const _sectionLabels = {
  'verse': 'Verse',
  'chorus': 'Chorus',
  'bridge': 'Bridge',
  'pre chorus': 'Pre-Chorus',
  'post chorus': 'Post-Chorus',
  'intro': 'Intro',
  'outro': 'Outro',
  'interlude': 'Interlude',
  'instrumental': 'Instrumental',
  'solo': 'Solo',
  'refrain': 'Refrain',
  'hook': 'Hook',
  'breakdown': 'Breakdown',
  'coda': 'Coda',
  'tag': 'Tag',
  'ending': 'Ending',
  // ChordPro short forms.
  'sov': 'Verse',
  'soc': 'Chorus',
  'sob': 'Bridge',
};

/// Heading or note text for a directive line, or null when it prints nothing.
/// Section directives and every `{comment: ...}` (the reader shows them all)
/// produce text; metadata directives and `{end_of_...}` do not.
String? _pdfSectionHeading(String directive) {
  final match = RegExp(
    r'^\{\s*(?:start_of_)?([a-z_]+)\s*(?::\s*([^}]*))?\}$',
    caseSensitive: false,
  ).firstMatch(directive.trim());
  if (match == null) return null;
  final name = match.group(1)!.replaceAll('_', ' ').toLowerCase();
  final detail = match.group(2)?.trim();
  if (_commentDirectives.contains(name)) {
    return detail == null || detail.isEmpty ? null : detail;
  }
  final label = _sectionLabels[name];
  if (label == null) return null;
  if (detail == null || detail.isEmpty) return label;
  if (detail.toLowerCase().startsWith(label.toLowerCase())) return detail;
  return '$label · $detail';
}
