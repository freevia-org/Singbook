part of 'file_actions.dart';

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
  final ({T? value, Object? error, StackTrace? stack}) outcome;
  try {
    // The worker reports its own failure as data. An [ArgumentError] (which
    // includes every [RangeError]) thrown by [work] must not be mistaken for
    // an unsendable argument and repeat the whole job on the calling isolate.
    outcome = await Isolate.run(() async {
      try {
        return (value: await work(), error: null, stack: null);
      } catch (error, stack) {
        return (value: null, error: error, stack: stack);
      }
    });
  } on IsolateSpawnException {
    return work();
  } on ArgumentError {
    return work();
  }
  final error = outcome.error;
  if (error != null) {
    Error.throwWithStackTrace(error, outcome.stack ?? StackTrace.current);
  }
  return outcome.value as T;
}

/// [_runInBackground], for tests.
@visibleForTesting
Future<T> runInBackgroundForTest<T>(FutureOr<T> Function() work) =>
    _runInBackground(work);

/// Inputs below this size decode in less than a frame; an isolate start would
/// cost more than it saves.
const _inlineImportBytes = 128 * 1024;

/// [decodeSongText] off the calling isolate for inputs large enough to matter.
Future<List<SongDocument>> decodeSongTextAsync(
  String input, {
  String? fileName,
}) async => input.length <= _inlineImportBytes
    ? decodeSongText(input, fileName: fileName)
    : _runInBackground(() => decodeSongText(input, fileName: fileName));

/// [decodePickedSongs] off the calling isolate for large files.
Future<List<SongDocument>> decodePickedSongsAsync(PickedDocument file) async =>
    file.bytes.length <= _inlineImportBytes
    ? decodePickedSongs(file)
    : _runInBackground(() => decodePickedSongs(file));

/// [decodeSetlistReferences] off the calling isolate for large files. Only the
/// identity of each library song crosses the isolate boundary.
Future<SetlistDocument> decodeSetlistReferencesAsync(
  String text,
  List<SongDocument> songs, {
  String? fileName,
}) async {
  if (text.length <= _inlineImportBytes) {
    return decodeSetlistReferences(text, songs, fileName: fileName);
  }
  final identities = [
    for (final song in songs)
      SongDocument(
        id: song.id,
        title: song.title,
        artist: song.artist,
        body: '',
      ),
  ];
  return _runInBackground(
    () => decodeSetlistReferences(text, identities, fileName: fileName),
  );
}

/// [PickedDocument.lenientText] off the calling isolate for large files.
Future<String> decodeImportedTextAsync(Uint8List bytes) async =>
    bytes.length <= _inlineImportBytes
    ? decodeImportedText(bytes)
    : _runInBackground(() => decodeImportedText(bytes));

/// Stable identity derived from [seed], shared by every import path.
String stableImportId(String seed) =>
    'imp-${sha256.convert(utf8.encode(seed)).toString().substring(0, 32)}';

/// How an incoming song relates to the stored song with the same id: [same]
/// content, or the stable id its conflicting copy is stored under.
typedef ImportedSongVerdict = ({bool same, String? conflictId});

List<ImportedSongVerdict> _compareImportedSongs(
  List<(SongDocument existing, SongDocument incoming)> pairs,
) {
  final codec = ChordProCodec();
  return [
    for (final (existing, incoming) in pairs)
      () {
        final incomingText = codec.encode(incoming);
        final opaque =
            existing.extensionError != null || incoming.extensionError != null;
        // An opaque x_verse block deliberately stays byte-for-byte intact
        // when ChordPro cannot decode it. Compare its complete model too, or
        // metadata held only in the local backup sidecar would be silently
        // discarded.
        final incomingJson = opaque ? jsonEncode(incoming.toJson()) : null;
        if (codec.encode(existing) == incomingText &&
            (!opaque || jsonEncode(existing.toJson()) == incomingJson)) {
          return (same: true, conflictId: null);
        }
        return (
          same: false,
          // Derived from the content, so a repeated import finds its earlier
          // copy instead of adding another.
          conflictId: stableImportId(
            'song:${incoming.id}:${incoming.extensionError == null ? incomingText : incomingJson}',
          ),
        );
      }(),
  ];
}

/// Compares each incoming song with the stored song of the same id. Every
/// comparison serializes both documents, so more than a few run on a worker
/// isolate instead of blocking frames.
Future<List<ImportedSongVerdict>> compareImportedSongs(
  List<(SongDocument existing, SongDocument incoming)> pairs,
) async => pairs.length <= 4
    ? _compareImportedSongs(pairs)
    : _runInBackground(() => _compareImportedSongs(pairs));

/// [decodeLibraryPackage] plus the SHA-256 of the package, both computed on
/// the worker isolate.
Future<({ImportedCollection collection, String packageHash})>
decodeLibraryPackageWithHashAsync(Uint8List bytes) => _runInBackground(
  () => (
    collection: decodeLibraryPackage(bytes),
    packageHash: sha256.convert(bytes).toString(),
  ),
);

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
  final textBytes = utf8.encode(text);
  if (textBytes.length > maxImportBytes ||
      RegExp(r'<!\s*(?:DOCTYPE|ENTITY)', caseSensitive: false).hasMatch(text)) {
    throw const FormatException('invalid_xml');
  }
  final document = XmlDocument.parse(text);
  if (document.rootElement.name.local != 'set') {
    throw const FormatException('unsupported_file');
  }
  // Indexed once: a scan of the library per entry is quadratic for a long
  // setlist against a large library.
  final byId = <String, List<SongDocument>>{};
  final byTitle = <String, List<SongDocument>>{};
  for (final song in songs) {
    (byId[song.id] ??= []).add(song);
    (byTitle[song.title] ??= []).add(song);
  }
  final entries = <SetlistEntry>[];
  for (final group in document.findAllElements('slide_group')) {
    if (group.getAttribute('type') != 'song') continue;
    final reference = group.getElement('verse_reference');
    final id = reference?.getAttribute('songId');
    final artist = reference?.getElement('artist')?.innerText;
    final exact = byId[id] ?? const <SongDocument>[];
    final matches = exact.isNotEmpty
        ? exact
        : [
            for (final s
                in byTitle[group.getAttribute('name')] ??
                    const <SongDocument>[])
              if (artist == null || s.artist == artist) s,
          ];
    if (matches.length != 1) {
      throw const FormatException('missing_song_references');
    }
    if (entries.length >= 10000) throw const FormatException('too_many_songs');
    final overrides = reference?.getElement('overrides')?.innerText;
    entries.add(
      SetlistEntry(
        id: newId(),
        songId: matches.single.id,
        overrides: overrides == null ? {} : jsonMap(jsonDecode(overrides)),
      ),
    );
  }
  return SetlistDocument(
    // Derived from the file text, so importing the same file twice yields the
    // same identity and the controller can recognise it.
    id: 'osts-${sha256.convert(textBytes).toString().substring(0, 32)}',
    name:
        document.rootElement.getAttribute('name') ??
        (fileName == null
            ? 'Singbook'
            : paths.basenameWithoutExtension(fileName)),
    entries: entries,
    notes: document.rootElement.getElement('notes')?.innerText ?? '',
  );
}
