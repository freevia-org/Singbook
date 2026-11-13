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

part 'file_actions_text_import.dart';
part 'file_actions_rich_text.dart';
part 'file_actions_package.dart';
part 'file_actions_pdf.dart';

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
    } on PlatformException {
      // A platform that has the channel but cannot place HTML on the
      // clipboard still copies the plain text.
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
    _backupFileName(),
    bytes,
    'application/zip',
    'Singbook',
    origin,
  );

  static String _backupFileName() =>
      'Singbook-${DateTime.now().toIso8601String().substring(0, 10)}.lyrics-setlist';

  /// Writes a backup through the platform's save dialog so it can go to local
  /// storage or any document provider without a share target. Returns null
  /// when the user dismisses the dialog.
  Future<Uri?> saveBackupBytes(Uint8List bytes) => _saveFile(
    fileName: _backupFileName(),
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
      // the copy can go. Android reports success as soon as a target is
      // chosen, while the receiving app may still be reading the file (or
      // nothing at all, `unavailable`): only a dismissed chooser is known to
      // need no copy. Otherwise the next share or app start sweeps it.
      final finished = _platform == TargetPlatform.android
          ? result.status == ShareResultStatus.dismissed
          : result.status != ShareResultStatus.unavailable;
      if (finished) await _deleteQuietly(dir);
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


final _windowsReserved = RegExp(
  r'^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$',
  caseSensitive: false,
);

/// Longest stem in UTF-8 bytes. Android, Linux and Apple file systems limit a
/// name to 255 bytes; this leaves room for the extension.
const _maxSafeNameBytes = 240;

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
  if (utf8.encode(result).length > _maxSafeNameBytes) {
    final kept = <int>[];
    var bytes = 0;
    for (final rune in result.runes) {
      final size = rune < 0x80
          ? 1
          : rune < 0x800
          ? 2
          : rune < 0x10000
          ? 3
          : 4;
      if (bytes + size > _maxSafeNameBytes) break;
      bytes += size;
      kept.add(rune);
    }
    result = clean(String.fromCharCodes(kept));
  }
  if (result.isEmpty) return 'Singbook';
  // "CON" and "CON.cho" are both the console device on Windows.
  if (_windowsReserved.hasMatch(result.split('.').first.trim())) {
    result = '_$result';
  }
  return result;
}
