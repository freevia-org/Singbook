import 'dart:convert';
import 'dart:io' show Directory;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/models.dart';
import '../domain/chordpro.dart';
import '../domain/arrangement.dart';
import '../domain/song_identity.dart';
import '../domain/combine.dart';

const _replacementCarryMetadata = {'composer', 'lyricist', 'copyright'};

bool _hasMeaningfulMetadata(Object? value) =>
    value != null &&
    (value is! String || value.trim().isNotEmpty) &&
    (value is! Iterable || value.isNotEmpty) &&
    (value is! Map || value.isNotEmpty);

double? _validDuration(Object? value) {
  if (value is! num) return null;
  final seconds = value.toDouble();
  return seconds.isFinite && seconds > 0 && seconds <= 86400 ? seconds : null;
}

JsonMap _withoutInvalidDuration(JsonMap metadata) {
  final clean = {...metadata};
  if (metadata.containsKey('durationSeconds') &&
      _validDuration(metadata['durationSeconds']) == null) {
    clean.remove('durationSeconds');
  }
  return clean;
}

// Android's CursorWindow cannot return an oversized document as one row.
// Ordinary songs stay on the inline path; large documents cross the platform
// boundary as bounded blobs, without changing their stored ChordPro payload.
const _documentReadChunkSize = 128 * 1024;
const _boundedDocumentColumn =
    'CASE WHEN length(CAST(document AS BLOB)) <= $_documentReadChunkSize '
    'THEN document ELSE NULL END AS document';
const _boundedFullDocumentColumn =
    'CASE WHEN length(CAST(full_document AS BLOB)) <= $_documentReadChunkSize '
    'THEN full_document ELSE NULL END AS full_document';

String _localSongHash(String document, String? fullDocumentHash) =>
    fullDocumentHash == null
    ? sha256.convert(utf8.encode(document)).toString()
    : sha256
          .convert(utf8.encode('$document\u0000$fullDocumentHash'))
          .toString();

SongCandidate _sanitizeCandidateDuration(SongCandidate candidate) =>
    SongCandidate(
      providerId: candidate.providerId,
      id: candidate.id,
      title: candidate.title,
      artist: candidate.artist,
      album: candidate.album,
      url: candidate.url,
      durationSeconds: _validDuration(candidate.durationSeconds),
      metadata: _withoutInvalidDuration(candidate.metadata),
      recordingIds: candidate.recordingIds,
      extra: candidate.extra,
    );

SongDocument _sanitizeImportedDurations(SongDocument song) {
  final sources = song.sources.map((source) {
    return SourceResult(
      candidate: _sanitizeCandidateDuration(source.candidate),
      body: source.body,
      metadata: _withoutInvalidDuration(source.metadata),
      timingTracks: source.timingTracks,
      matchKind: source.matchKind,
      attribution: source.attribution,
      matchReason: source.matchReason,
      retrievedAt: source.retrievedAt,
      extra: source.extra,
    );
  }).toList();
  return SongDocument(
    id: song.id,
    title: song.title,
    artist: song.artist,
    body: song.body,
    metadata: _withoutInvalidDuration(song.metadata),
    sources: sources,
    timingTracks: song.timingTracks,
    favorite: song.favorite,
    createdAt: song.createdAt,
    updatedAt: song.updatedAt,
    selectedRecording: song.selectedRecording == null
        ? null
        : _sanitizeCandidateDuration(song.selectedRecording!),
    activeTimingTrackId: song.activeTimingTrackId,
    revision: song.revision,
    extra: song.extra,
    preservedExtensions: song.preservedExtensions,
    extensionError: song.extensionError,
  );
}

/// What this device and the cloud agreed on for one item the last time they
/// were in sync. Present = "we had synced it": a later absence on one side is a
/// deletion there, not "never existed". [kind] is `song` or `setlist`.
class SyncBaseline {
  const SyncBaseline({
    required this.kind,
    required this.id,
    required this.cloudHash,
    required this.localHash,
  });
  final String kind, id;

  /// Hash of the cloud file body at agreement.
  final String cloudHash;

  /// Hash of local song state at agreement. It may differ from [cloudHash]
  /// after normalisation or when an opaque extension has a local JSON sidecar.
  final String localHash;
  String get key => '$kind:$id';
}

class LibraryRepository {
  final Database database;
  final ChordProCodec _codec = ChordProCodec();
  LibraryRepository._(this.database);

  static Future<LibraryRepository> open({
    String? path,
    DatabaseFactory? factory,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final windows = defaultTargetPlatform == TargetPlatform.windows;
    final location =
        path ??
        (windows && factory == null
            ? paths.join(
                (await getApplicationSupportDirectory()).path,
                'databases',
                'verse_library.db',
              )
            : paths.join(
                await dbFactory.getDatabasesPath(),
                'verse_library.db',
              ));
    if (windows && factory == null && path == null) {
      await Directory(paths.dirname(location)).create(recursive: true);
    }
    final db = await dbFactory.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: 4,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE songs (id TEXT PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL, album TEXT, favorite INTEGER NOT NULL DEFAULT 0, document TEXT NOT NULL, content_hash TEXT NOT NULL, lyric_hash TEXT NOT NULL, source_identity TEXT, revision INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, search_text TEXT, full_document TEXT, full_document_hash TEXT)',
          );
          await db.execute(
            'CREATE INDEX songs_title_artist ON songs(title COLLATE NOCASE,artist COLLATE NOCASE)',
          );
          await db.execute(
            'CREATE INDEX songs_source ON songs(source_identity,lyric_hash)',
          );
          await db.execute(
            'CREATE TABLE setlists (id TEXT PRIMARY KEY, name TEXT NOT NULL, notes TEXT NOT NULL, favorite INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE setlist_entries (id TEXT PRIMARY KEY, setlist_id TEXT NOT NULL REFERENCES setlists(id) ON DELETE CASCADE, song_id TEXT NOT NULL REFERENCES songs(id) ON DELETE CASCADE, position INTEGER NOT NULL, overrides TEXT NOT NULL, UNIQUE(setlist_id,position))',
          );
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE activity (id TEXT PRIMARY KEY, object_id TEXT NOT NULL, object_kind TEXT NOT NULL, action TEXT NOT NULL, occurred_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE INDEX activity_order ON activity(occurred_at DESC,id DESC)',
          );
          await db.execute(
            'CREATE TABLE outbox (id TEXT PRIMARY KEY, object_id TEXT NOT NULL, object_kind TEXT NOT NULL, action TEXT NOT NULL, revision INTEGER, created_at TEXT NOT NULL)',
          );
          await _createSyncItems(db);
          await _createEntrySongIndex(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createSyncItems(db);
          if (oldVersion < 3) {
            await _addSearchText(db);
            await _createEntrySongIndex(db);
          }
          if (oldVersion < 4) {
            await db.execute('ALTER TABLE songs ADD COLUMN full_document TEXT');
            await db.execute(
              'ALTER TABLE songs ADD COLUMN full_document_hash TEXT',
            );
          }
        },
      ),
    );
    return LibraryRepository._(db);
  }

  /// Cascading song deletes and "which setlists use this song" look entries up
  /// by song_id.
  static Future<void> _createEntrySongIndex(Database db) async {
    final tables = await db.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'setlist_entries'",
    );
    if (tables.isEmpty) return;
    await db.execute(
      'CREATE INDEX IF NOT EXISTS setlist_entries_song ON setlist_entries(song_id)',
    );
  }

  /// Adds the normalized search column and fills it for existing songs.
  static Future<void> _addSearchText(Database db) async {
    await db.execute('ALTER TABLE songs ADD COLUMN search_text TEXT');
    final codec = ChordProCodec();
    final rows = await db.query(
      'songs',
      columns: ['id', 'title', 'artist', 'album'],
    );
    for (final row in rows) {
      String? lyrics;
      try {
        final document = await _readDocument(db, row['id'] as String);
        lyrics = plainLyrics(codec.decode(document).body);
      } on Object {
        lyrics = null;
      }
      await db.update(
        'songs',
        {
          'search_text': searchText(
            row['title'] as String,
            row['artist'] as String,
            row['album'] as String?,
            lyrics ?? '',
          ),
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  /// Case-folded text a search query is matched against. SQLite's LIKE and
  /// NOCASE only fold ASCII on many builds, so folding is done here with full
  /// Unicode lower-casing; chords and directives are excluded via [lyrics].
  static String searchText(
    String title,
    String artist,
    String? album,
    String lyrics,
  ) => [title, artist, album ?? '', lyrics].join('\n').toLowerCase();

  static Future<void> _createSyncItems(Database db) => db.execute(
    'CREATE TABLE IF NOT EXISTS sync_items (account TEXT NOT NULL, kind TEXT NOT NULL, item_id TEXT NOT NULL, cloud_hash TEXT NOT NULL, local_hash TEXT NOT NULL, PRIMARY KEY(account, kind, item_id))',
  );

  static String _likePattern(String query) =>
      '%${query.trim().toLowerCase().replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%';

  Future<List<SongDocument>> listSongs({
    String query = '',
    bool favoritesOnly = false,
    int? limit,
    int offset = 0,
  }) async {
    final clauses = <String>[], args = <Object?>[];
    if (favoritesOnly) clauses.add('favorite = 1');
    if (query.trim().isNotEmpty) {
      clauses.add('search_text LIKE ? ESCAPE \'\\\'');
      args.add(_likePattern(query));
    }
    return database.transaction((txn) async {
      final rows = await txn.query(
        'songs',
        columns: const [
          'id',
          'favorite',
          'revision',
          'created_at',
          'updated_at',
          'content_hash',
          'full_document_hash',
          _boundedDocumentColumn,
          _boundedFullDocumentColumn,
        ],
        where: clauses.isEmpty ? null : clauses.join(' AND '),
        whereArgs: args,
        orderBy: 'updated_at DESC, id',
        // An offset without a limit still has to skip rows (-1 = no limit).
        limit: limit ?? (offset > 0 ? -1 : null),
        offset: limit == null && offset <= 0 ? null : offset,
      );
      final songs = <SongDocument>[];
      for (final row in rows) {
        songs.add(await _readSong(txn, row));
      }
      return songs;
    });
  }

  /// Reads the complete library and app preferences from one SQLite snapshot.
  Future<
    ({
      List<SongDocument> songs,
      List<SetlistDocument> setlists,
      JsonMap appSettings,
      String libraryFingerprint,
    })
  >
  backupSnapshot() => database.transaction((txn) async {
    final songRows = await txn.query(
      'songs',
      columns: const [
        'id',
        'favorite',
        'revision',
        'created_at',
        'updated_at',
        'content_hash',
        'full_document_hash',
        _boundedDocumentColumn,
        _boundedFullDocumentColumn,
      ],
      orderBy: 'updated_at DESC,id',
    );
    final setlistRows = await txn.query(
      'setlists',
      orderBy: 'updated_at DESC,id',
    );
    final settingRows = await txn.query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: const ['app'],
      limit: 1,
    );
    return (
      songs: [for (final row in songRows) await _readSong(txn, row)],
      setlists: [for (final row in setlistRows) await _setlist(txn, row)],
      appSettings: settingRows.isEmpty
          ? <String, dynamic>{}
          : jsonMap(jsonDecode(settingRows.single['value'] as String)),
      libraryFingerprint: await _libraryFingerprint(txn),
    );
  });

  Future<String> _libraryFingerprint(DatabaseExecutor txn) async {
    final songRows = await txn.query(
      'songs',
      columns: const ['id', 'content_hash'],
      orderBy: 'id',
    );
    final setlistRows = await txn.query('setlists', orderBy: 'id');
    final setlists = [
      for (final row in setlistRows) (await _setlist(txn, row)).toJson(),
    ];
    final appSettings = await txn.query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: const ['app'],
      limit: 1,
    );
    return sha256
        .convert(
          utf8.encode(
            jsonEncode({
              'songs': [
                for (final row in songRows) [row['id'], row['content_hash']],
              ],
              'setlists': setlists,
              // The preview token also guards the settings row that restore
              // may rewrite, while keeping its contents out of the token.
              'appSettingsHash': appSettings.isEmpty
                  ? null
                  : sha256
                        .convert(
                          utf8.encode(appSettings.single['value'] as String),
                        )
                        .toString(),
            }),
          ),
        )
        .toString();
  }

  static Future<String> _readColumn(
    DatabaseExecutor executor,
    String id,
    String column,
  ) async {
    final lengthRows = await executor.rawQuery(
      'SELECT length(CAST($column AS BLOB)) AS byte_length FROM songs WHERE id = ?',
      [id],
    );
    if (lengthRows.isEmpty) throw StateError('Song document disappeared');
    final byteLength = lengthRows.single['byte_length'] as int;
    final bytes = BytesBuilder(copy: false);
    for (var start = 1; start <= byteLength; start += _documentReadChunkSize) {
      final rows = await executor.rawQuery(
        'SELECT substr(CAST($column AS BLOB), ?, ?) AS chunk FROM songs WHERE id = ?',
        [start, _documentReadChunkSize, id],
      );
      if (rows.isEmpty || rows.single['chunk'] is! Uint8List) {
        throw StateError('Could not read song document chunk');
      }
      bytes.add(rows.single['chunk'] as Uint8List);
    }
    // A chunk may end inside a multibyte character; decode only after joining.
    return utf8.decode(bytes.takeBytes());
  }

  static Future<String> _readDocument(DatabaseExecutor executor, String id) =>
      _readColumn(executor, id, 'document');

  Future<SongDocument> _readSong(
    DatabaseExecutor executor,
    Map<String, Object?> row,
  ) async {
    final storedDocument = row['document'];
    final document = storedDocument is String
        ? storedDocument
        : await _readDocument(executor, row['id'] as String);
    final fullDocument = row['full_document'];
    SongDocument song;
    if (fullDocument != null || row['full_document_hash'] != null) {
      final fullDocumentHash = row['full_document_hash'];
      if (fullDocumentHash is! String) {
        throw const FormatException('Invalid opaque song sidecar');
      }
      final json = fullDocument is String
          ? fullDocument
          : await _readColumn(executor, row['id'] as String, 'full_document');
      final actualHash = sha256.convert(utf8.encode(json)).toString();
      if (actualHash != fullDocumentHash ||
          row['content_hash'] != _localSongHash(document, actualHash)) {
        throw const FormatException('Invalid opaque song sidecar');
      }
      song = SongDocument.fromJson(jsonMap(jsonDecode(json)));
      if (song.id != row['id'] || song.extensionError == null) {
        throw const FormatException('Invalid opaque song sidecar');
      }
    } else {
      song = _codec.decode(document);
    }
    return song.copyWith(
      id: row['id'] as String,
      favorite: row['favorite'] == 1,
      revision: row['revision'] as int,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<SongDocument?> getSong(String id) async {
    return database.transaction((txn) async {
      final rows = await txn.query(
        'songs',
        columns: const [
          'id',
          'favorite',
          'revision',
          'created_at',
          'updated_at',
          'content_hash',
          'full_document_hash',
          _boundedDocumentColumn,
          _boundedFullDocumentColumn,
        ],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : _readSong(txn, rows.single);
    });
  }

  Future<({SongDocument song, String document, String hash})?>
  _validatedSongState(
    DatabaseExecutor txn,
    String id, {
    required bool requireSyncRepresentation,
  }) async {
    final rows = await txn.query(
      'songs',
      columns: const [
        'id',
        'favorite',
        'revision',
        'created_at',
        'updated_at',
        'content_hash',
        'full_document_hash',
        _boundedDocumentColumn,
        _boundedFullDocumentColumn,
      ],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final row = rows.single;
      final rawDocument = row['document'];
      final document = rawDocument is String
          ? rawDocument
          : await _readDocument(txn, id);
      final song = await _readSong(txn, row);
      final hasSidecar =
          row['full_document'] != null || row['full_document_hash'] != null;

      if (hasSidecar) {
        final storedSidecar = row['full_document'];
        final sidecar = storedSidecar is String
            ? storedSidecar
            : await _readColumn(txn, id, 'full_document');
        // Sidecars are emitted from SongDocument.toJson(). Requiring its
        // canonical shape catches fields from an unsupported schema that
        // fromJson would otherwise discard. ChordPro must match this complete
        // local representation.
        if (jsonEncode(song.toJson()) != sidecar ||
            _codec.encode(song) != document) {
          throw const FormatException('invalid_local_data');
        }
      } else {
        final decoded = _codec.decode(document);
        if (decoded.id != id ||
            row['content_hash'] !=
                sha256.convert(utf8.encode(document)).toString()) {
          throw const FormatException('invalid_local_data');
        }
      }
      if (song.id != id ||
          (requireSyncRepresentation && song.extensionError != null)) {
        throw const FormatException('invalid_local_data');
      }
      return (
        song: song,
        document: document,
        hash: row['content_hash'] as String,
      );
    } on Object {
      throw const FormatException('invalid_local_data');
    }
  }

  /// Validates every complete local song before sync plans remote or local
  /// mutations. Unsupported opaque extensions remain usable in backups, but
  /// cannot be represented by the strict raw ChordPro sync format.
  Future<void> validateSyncSongData() async {
    await database.transaction((txn) async {
      final ids = await txn.query('songs', columns: const ['id']);
      for (final row in ids) {
        await _validatedSongState(
          txn,
          row['id'] as String,
          requireSyncRepresentation: true,
        );
      }
    });
  }

  Future<void> saveSong(SongDocument song) async {
    final document = _codec.encode(song);
    await database.transaction((txn) async {
      await _writeSong(txn, song, document);
      await _queue(txn, song.id, 'song', 'save', song.revision);
    });
  }

  /// Atomic compare-and-set save. Inside one transaction the stored hash is
  /// compared with [expectedHash]; the song is written only when the stored
  /// song is absent, [expectedHash] is null or the hashes match. Returns false
  /// (and writes nothing) when the stored song differs, so the caller can keep
  /// the edit as a conflict copy without a check-then-write race.
  ///
  /// A null [expectedHash] normally means "write unconditionally". With
  /// [mustNotExist] it means the song must still be absent.
  /// [mustExist] refuses insertion if a song was deleted before this transaction.
  Future<bool> saveSongIfUnchanged(
    SongDocument song,
    String? expectedHash, {
    bool mustNotExist = false,
    bool mustExist = false,
  }) async {
    final document = _codec.encode(song);
    return database.transaction((txn) async {
      if (expectedHash != null || mustNotExist || mustExist) {
        final rows = await txn.query(
          'songs',
          columns: ['content_hash'],
          where: 'id = ?',
          whereArgs: [song.id],
          limit: 1,
        );
        if (mustExist && rows.isEmpty) return false;
        if (rows.isNotEmpty &&
            (expectedHash == null
                ? mustNotExist
                : rows.single['content_hash'] != expectedHash)) {
          return false;
        }
      }
      await _writeSong(txn, song, document);
      await _queue(txn, song.id, 'song', 'save', song.revision);
      return true;
    });
  }

  Future<void> _writeSong(
    DatabaseExecutor txn,
    SongDocument song,
    String document,
  ) async {
    final fullDocument = song.extensionError == null
        ? null
        : jsonEncode(song.toJson());
    final fullDocumentHash = fullDocument == null
        ? null
        : sha256.convert(utf8.encode(fullDocument)).toString();
    final values = {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.metadata['album']?.toString(),
      'favorite': song.favorite ? 1 : 0,
      'document': document,
      'content_hash': _localSongHash(document, fullDocumentHash),
      'full_document': fullDocument,
      'full_document_hash': fullDocumentHash,
      'lyric_hash': lyricOrderHash(song.body),
      'search_text': searchText(
        song.title,
        song.artist,
        song.metadata['album']?.toString(),
        plainLyrics(song.body),
      ),
      'source_identity': song.extra['selectedSourceId'] as String?,
      'revision': song.revision,
      'created_at': song.createdAt.toUtc().toIso8601String(),
      'updated_at': song.updatedAt.toUtc().toIso8601String(),
    };
    // UPDATE then INSERT avoids REPLACE deleting a song's setlist references.
    final updated = await txn.update(
      'songs',
      values,
      where: 'id = ?',
      whereArgs: [song.id],
    );
    if (updated == 0) await txn.insert('songs', values);
  }

  /// An explicit comparison Save replaces the preferred version in place.
  /// Keep this separate from file imports and stale-editor conflict handling.
  /// Matching and writing share one transaction, including concurrent saves.
  Future<SongDocument> saveChosenSong(SongDocument song) async {
    song = _sanitizeImportedDurations(song);
    final selected = song.selectedRecording;
    if (selected == null) {
      throw ArgumentError('Missing selected song reference');
    }
    return database.transaction((txn) async {
      final rows = await txn.query(
        'songs',
        columns: const [
          'id',
          'favorite',
          'revision',
          'created_at',
          'updated_at',
          'content_hash',
          'full_document_hash',
          _boundedDocumentColumn,
          _boundedFullDocumentColumn,
        ],
        orderBy: 'created_at, id',
      );
      SongDocument? existing;
      var bestPriority = 0;
      for (final row in rows) {
        // The persisted reference can differ from locally edited display
        // metadata. Resolve it from the same snapshot rather than trusting an
        // in-memory ID or filtering only on the visible title and artist.
        final stored = await _readSong(txn, row);
        final priority = librarySongMatchPriority(stored, selected);
        // Exact reference first; ties keep the earliest-created library ID.
        // Pre-existing duplicates are not deleted or silently consolidated.
        if (priority > bestPriority) {
          existing = stored;
          bestPriority = priority;
        }
      }
      if (existing == null) return (await _importSong(txn, song)).song;
      if (existing.extensionError != null) {
        throw const FormatException('invalid_local_data');
      }
      final sources = <String, SourceResult>{};
      String sourceKey(SourceResult source) =>
          '${source.id}:${sha256.convert(utf8.encode(source.body))}';
      final timingIds = {
        for (final track in song.timingTracks) track.id,
        for (final source in song.sources)
          for (final track in source.timingTracks) track.id,
      };
      TimingTrack archiveTrack(SourceResult source, TimingTrack track) {
        final originalId =
            track.extra['archivedOriginalTrackId'] as String? ?? track.id;
        final hash = sha256.convert(
          utf8.encode('${sourceKey(source)}\u0000$originalId'),
        );
        var id = 'history:${existing!.id}:$hash';
        while (!timingIds.add(id)) {
          id = '$id:history';
        }
        // Source timingTrackIds and the global codec track table must refer to
        // this historical payload, even if the provider reuses a track ID.
        return TimingTrack.fromJson({
          ...track.toJson(),
          'id': id,
          'archivedOriginalTrackId': originalId,
          'status': track.status == TimingStatus.usable
              ? TimingStatus.stale.name
              : track.status.name,
        });
      }

      for (final source in existing.sources) {
        // Retain source history/raw timing for Compare versions, but never
        // promote an archived version's timing onto the newly selected body.
        sources[sourceKey(source)] = source.copyWith(
          timingTracks: [
            for (final track in source.timingTracks)
              archiveTrack(source, track),
          ],
        );
      }
      for (final source in song.sources) {
        sources[sourceKey(source)] = source;
      }
      final existingOrigins = jsonMap(existing.extra['fieldOrigins']);
      final incomingOrigins = jsonMap(song.extra['fieldOrigins']);
      final incomingMetadata = {...song.metadata};
      incomingMetadata.removeWhere(
        (_, value) => !_hasMeaningfulMetadata(value),
      );
      bool incomingRemoval(String field) =>
          incomingOrigins[field] == 'user' &&
          !_hasMeaningfulMetadata(incomingMetadata[field]);
      final keyRemovalTombstone =
          incomingRemoval('key') ||
          (!_hasMeaningfulMetadata(existing.metadata['key']) &&
              existingOrigins['key'] == 'user');
      final recoveredKey =
          !_hasMeaningfulMetadata(incomingMetadata['key']) &&
              !keyRemovalTombstone
          ? sourcedArrangementKey(
              song.copyWith(
                sources: sources.values.toList(),
                metadata: incomingMetadata,
              ),
            )
          : null;
      final carriedMetadata = {
        // Composition credits may fill gaps. Recording and arrangement facts
        // must be established again for the selected version.
        for (final entry in existing.metadata.entries)
          if (_replacementCarryMetadata.contains(entry.key) &&
              !incomingRemoval(entry.key) &&
              !_hasMeaningfulMetadata(incomingMetadata[entry.key]) &&
              _hasMeaningfulMetadata(entry.value))
            entry.key: entry.value,
      };
      final replacementMetadata = {
        ...incomingMetadata,
        ...carriedMetadata,
        if (recoveredKey != null) 'key': recoveredKey.key,
        for (final entry in existing.metadata.entries)
          if (entry.key.startsWith('x_verse_player_')) entry.key: entry.value,
      };
      final incomingExtra = {...song.extra}
        ..remove('keySourceIds')
        ..remove('corroboratedKeySourceIds');
      final origins = {...incomingOrigins};
      final contributors = {...jsonMap(song.extra['fieldContributors'])};
      for (final field in carriedMetadata.keys) {
        origins.remove(field);
        contributors.remove(field);
        if (existingOrigins.containsKey(field)) {
          origins[field] = existingOrigins[field];
        }
        final prior = jsonMap(existing.extra['fieldContributors']);
        if (prior.containsKey(field)) contributors[field] = prior[field];
      }
      // A deliberate removal remains a user decision when the new version
      // also omits that field. A new nonempty value takes incoming authority.
      for (final field in {...existingOrigins.keys, ...incomingOrigins.keys}) {
        if (!const {'lyrics', 'chords', 'sections'}.contains(field) &&
            !_hasMeaningfulMetadata(incomingMetadata[field]) &&
            (incomingRemoval(field) ||
                (existingOrigins[field] == 'user' &&
                    !_hasMeaningfulMetadata(existing.metadata[field])))) {
          origins[field] = 'user';
          contributors.remove(field);
        }
      }
      if (!_hasMeaningfulMetadata(incomingMetadata['key'])) {
        origins.remove('key');
        contributors.remove('key');
        if (keyRemovalTombstone) origins['key'] = 'user';
        if (recoveredKey != null) {
          origins['key'] = recoveredKey.sourceIds.first;
          contributors['key'] = recoveredKey.sourceIds;
        }
      }
      final replacement = SongDocument(
        id: existing.id,
        title: song.title,
        artist: song.artist,
        body: song.body,
        metadata: replacementMetadata,
        favorite: existing.favorite,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now().toUtc(),
        revision: existing.revision + 1,
        selectedRecording: song.selectedRecording,
        sources: sources.values.toList(),
        timingTracks: song.timingTracks,
        activeTimingTrackId: song.activeTimingTrackId,
        extra: {
          // Preserve supported unknown payload fields, but clear old active
          // selection/provenance fields when the chosen version omits them.
          for (final entry in existing.extra.entries)
            if (!const {
              'selectedSourceId',
              'savedSourceId',
              'combinedSelection',
              'combinedFallbackSource',
              'fieldOrigins',
              'fieldContributors',
              'conflicts',
              'recommendation',
              'chordSourceIds',
              'pendingChordSourceIds',
              'excludedIncompleteSourceIds',
              'keySourceIds',
              'corroboratedKeySourceIds',
            }.contains(entry.key))
              entry.key: entry.value,
          ...incomingExtra,
          // Preserve incoming roles such as chords/sections, and attach old
          // provenance only to values that were actually carried forward.
          'fieldOrigins': origins,
          'fieldContributors': contributors,
          if (recoveredKey != null) 'keySourceIds': recoveredKey.sourceIds,
          if (_hasMeaningfulMetadata(incomingMetadata['key'])) ...{
            if (song.extra['keySourceIds'] is List)
              'keySourceIds': song.extra['keySourceIds'],
            if (song.extra['corroboratedKeySourceIds'] is List)
              'corroboratedKeySourceIds':
                  song.extra['corroboratedKeySourceIds'],
          },
          if (existing.extra['rawAssets'] is Map ||
              song.extra['rawAssets'] is Map)
            'rawAssets': {
              ...jsonMap(existing.extra['rawAssets']),
              ...jsonMap(song.extra['rawAssets']),
            },
        },
        preservedExtensions: {
          ...existing.preservedExtensions,
          ...song.preservedExtensions,
        }.toList(),
      );
      await _writeSong(txn, replacement, _codec.encode(replacement));
      await _queue(txn, replacement.id, 'song', 'save', replacement.revision);
      return replacement;
    });
  }

  Future<SongDocument> saveImportedSong(
    SongDocument song, {
    String? existingId,
  }) async {
    song = _sanitizeImportedDurations(song);
    return database.transaction((txn) async {
      final source = song.extra['selectedSourceId'];
      if (source is String || existingId != null) {
        final rows = await txn.query(
          'songs',
          columns: const [
            'id',
            'favorite',
            'revision',
            'created_at',
            'updated_at',
            'content_hash',
            'full_document_hash',
            _boundedDocumentColumn,
            _boundedFullDocumentColumn,
          ],
          where: existingId == null ? 'source_identity = ?' : 'id = ?',
          whereArgs: [existingId ?? source],
        );
        for (final row in rows) {
          final existing = await _readSong(txn, row);
          // An opaque (unreadable) extension block is written back verbatim, so
          // merged sources/timing would be reported as saved but never stored.
          if (existing.extensionError != null) continue;
          final fields = ['key', 'capo', 'tuning', 'tempo', 'timeSignature'];
          // Provider copies may differ only in line endings.
          String lf(String text) => text.replaceAll('\r\n', '\n');
          if (existingId != null ||
              lf(existing.body) == lf(song.body) &&
                  fields.every(
                    (f) => existing.metadata[f] == song.metadata[f],
                  )) {
            final sources = <String, SourceResult>{
              for (final source in existing.sources)
                '${source.id}:${sha256.convert(utf8.encode(source.body))}':
                    source,
            };
            for (final source in song.sources) {
              sources['${source.id}:${sha256.convert(utf8.encode(source.body))}'] =
                  source;
            }
            final sameLyrics =
                lyricOrderHash(existing.body) == lyricOrderHash(song.body);
            final tracks = <String, TimingTrack>{
              for (final track in song.timingTracks)
                track.id: !sameLyrics && track.status == TimingStatus.usable
                    ? track.copyWith(status: TimingStatus.stale)
                    : track,
              for (final track in existing.timingTracks) track.id: track,
            };
            final existingOrigins = jsonMap(existing.extra['fieldOrigins']);
            final incomingOrigins = jsonMap(song.extra['fieldOrigins']);
            final incomingSourceId = song.extra['savedSourceId'];
            final incomingSource = incomingSourceId is String
                ? song.sources
                      .where((item) => item.id == incomingSourceId)
                      .firstOrNull
                : null;
            final incomingDuration = incomingSource == null
                ? null
                : _validDuration(incomingSource.candidate.durationSeconds) ??
                      _validDuration(
                        incomingSource.metadata['durationSeconds'],
                      ) ??
                      _validDuration(
                        incomingSource.candidate.metadata['durationSeconds'],
                      );
            final existingDuration = _validDuration(
              existing.metadata['durationSeconds'],
            );
            bool sameDuration(double? a, double? b) =>
                a != null && b != null && (a - b).abs() < .001;
            final durationOrigin = existingOrigins['durationSeconds'];
            SourceResult? existingSourceResult;
            for (final item in existing.sources) {
              if (item.id == durationOrigin) {
                existingSourceResult = item;
                break;
              }
            }
            final existingDurationSource =
                existing.selectedRecording?.identity == durationOrigin
                ? existing.selectedRecording
                : existingSourceResult?.candidate;
            final provenExistingDuration =
                _validDuration(existingDurationSource?.durationSeconds) ??
                _validDuration(
                  existingSourceResult?.metadata['durationSeconds'],
                ) ??
                _validDuration(
                  existingDurationSource?.metadata['durationSeconds'],
                );
            final incomingDurationIsProven =
                incomingDuration != null &&
                incomingSourceId is String &&
                incomingOrigins['durationSeconds'] == incomingSourceId &&
                sameDuration(
                  incomingDuration,
                  _validDuration(song.metadata['durationSeconds']),
                );
            final shouldRefreshDuration =
                existingOrigins['durationSeconds'] != 'user' &&
                incomingDurationIsProven &&
                (existingDuration == null ||
                    sameDuration(existingDuration, provenExistingDuration));
            final mergedMetadata = {...song.metadata, ...existing.metadata};
            final mergedExtra = {
              ...song.extra,
              ...existing.extra,
              // Provenance maps merge key by key; the existing entry wins.
              for (final key in const ['fieldOrigins', 'conflicts'])
                if (song.extra[key] is Map || existing.extra[key] is Map)
                  key: {
                    ...jsonMap(song.extra[key]),
                    ...jsonMap(existing.extra[key]),
                  },
            };
            if (shouldRefreshDuration) {
              mergedMetadata['durationSeconds'] = incomingDuration;
              mergedExtra['fieldOrigins'] = {
                ...jsonMap(mergedExtra['fieldOrigins']),
                'durationSeconds': incomingSourceId,
              };
            }
            final merged = existing.copyWith(
              sources: sources.values.toList(),
              timingTracks: tracks.values.toList(),
              metadata: mergedMetadata,
              extra: mergedExtra,
            );
            await _writeSong(txn, merged, _codec.encode(merged));
            await _queue(txn, merged.id, 'song', 'save', merged.revision);
            return merged;
          }
        }
      }
      return (await _importSong(txn, song)).song;
    });
  }

  /// Writes an imported song without clobbering a different local song that
  /// shares its id: identical content is a no-op, differing content is stored
  /// as a separate copy under a fresh id (the local song is untouched).
  Future<({SongDocument song, bool forked})> _importSong(
    DatabaseExecutor txn,
    SongDocument song,
  ) async {
    final rows = await txn.query(
      'songs',
      columns: ['content_hash'],
      where: 'id = ?',
      whereArgs: [song.id],
      limit: 1,
    );
    var document = _codec.encode(song);
    var forked = false;
    if (rows.isNotEmpty) {
      final hash = sha256.convert(utf8.encode(document)).toString();
      if (rows.single['content_hash'] == hash) {
        return (song: song, forked: false);
      }
      song = song.copyWith(
        id: newId(),
        revision: song.revision,
        updatedAt: song.updatedAt,
      );
      document = _codec.encode(song);
      forked = true;
    }
    await _writeSong(txn, song, document);
    await _queue(txn, song.id, 'song', 'save', song.revision);
    return (song: song, forked: forked);
  }

  Future<void> deleteSong(String id) async {
    await database.transaction((txn) async {
      // Deleting a song cascades its setlist entries; the affected setlists
      // changed too, so they must be touched and synced.
      await _deleteSongTouchingSetlists(txn, id);
      await _queue(txn, id, 'song', 'delete', null);
    });
  }

  Future<void> _deleteSongTouchingSetlists(
    DatabaseExecutor txn,
    String id,
  ) async {
    final affected = await txn.rawQuery(
      'SELECT DISTINCT setlist_id FROM setlist_entries WHERE song_id = ?',
      [id],
    );
    await txn.delete('songs', where: 'id = ?', whereArgs: [id]);
    for (final row in affected) {
      final setlistId = row['setlist_id'] as String;
      await txn.update(
        'setlists',
        {'updated_at': DateTime.now().toUtc().toIso8601String()},
        where: 'id = ?',
        whereArgs: [setlistId],
      );
      await _queue(txn, setlistId, 'setlist', 'save', null);
    }
  }

  Future<List<SetlistDocument>> listSetlists({
    String query = '',
    bool favoritesOnly = false,
  }) async {
    final rows = await database.query(
      'setlists',
      where: favoritesOnly ? 'favorite = 1' : null,
      orderBy: 'updated_at DESC,id',
    );
    // Matched in Dart: SQLite LIKE only case-folds ASCII.
    final needle = query.trim().toLowerCase();
    final result = <SetlistDocument>[];
    for (final row in rows) {
      if (needle.isNotEmpty &&
          !(row['name'] as String).toLowerCase().contains(needle)) {
        continue;
      }
      result.add(await _setlist(database, row));
    }
    return result;
  }

  Future<SetlistDocument?> getSetlist(String id) async {
    final rows = await database.query(
      'setlists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _setlist(database, rows.single);
  }

  Future<SetlistDocument> _setlist(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final entries = await db.query(
      'setlist_entries',
      where: 'setlist_id = ?',
      whereArgs: [row['id']],
      orderBy: 'position',
    );
    return SetlistDocument(
      id: row['id'] as String,
      name: row['name'] as String,
      notes: row['notes'] as String,
      favorite: row['favorite'] == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      entries: entries
          .map(
            (e) => SetlistEntry(
              id: e['id'] as String,
              songId: e['song_id'] as String,
              overrides: jsonMap(jsonDecode(e['overrides'] as String)),
            ),
          )
          .toList(),
    );
  }

  Future<void> saveSetlist(SetlistDocument setlist) async {
    await database.transaction((txn) => _writeSetlist(txn, setlist));
  }

  /// Atomic compare-and-set counterpart of [saveSetlist]; see
  /// [saveSongIfUnchanged]. [expectedHash] is the hash of the setlist's JSON
  /// as returned by [getSetlistHash].
  Future<bool> saveSetlistIfUnchanged(
    SetlistDocument setlist,
    String? expectedHash, {
    bool mustNotExist = false,
  }) async =>
      await saveSetlistIfUnchangedWithHash(
        setlist,
        expectedHash,
        mustNotExist: mustNotExist,
      ) !=
      null;

  /// Atomic compare-and-set save that returns the hash of the exact persisted
  /// document, including any entry ids regenerated during the write. Returns
  /// null when the expected version does not match.
  Future<String?> saveSetlistIfUnchangedWithHash(
    SetlistDocument setlist,
    String? expectedHash, {
    bool mustNotExist = false,
  }) => database.transaction((txn) async {
    if (expectedHash != null || mustNotExist) {
      final rows = await txn.query(
        'setlists',
        where: 'id = ?',
        whereArgs: [setlist.id],
        limit: 1,
      );
      if (rows.isNotEmpty &&
          (expectedHash == null ||
              _setlistHashOf(await _setlist(txn, rows.single)) !=
                  expectedHash)) {
        return null;
      }
    }
    await _writeSetlist(txn, setlist);
    final rows = await txn.query(
      'setlists',
      where: 'id = ?',
      whereArgs: [setlist.id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _setlistHashOf(await _setlist(txn, rows.single));
  });

  /// Entry ids may be regenerated on write, so only name, notes, favorite and
  /// the ordered (song, overrides) pairs decide whether two setlists match.
  static bool _sameSetlistContent(SetlistDocument a, SetlistDocument b) =>
      a.name == b.name &&
      a.notes == b.notes &&
      a.favorite == b.favorite &&
      jsonEncode([
            for (final e in a.entries) [e.songId, e.overrides],
          ]) ==
          jsonEncode([
            for (final e in b.entries) [e.songId, e.overrides],
          ]);

  static String _setlistHashOf(SetlistDocument setlist) =>
      sha256.convert(utf8.encode(jsonEncode(setlist.toJson()))).toString();

  Future<void> _writeSetlist(
    DatabaseExecutor txn,
    SetlistDocument setlist, {
    bool queue = true,
  }) async {
    final values = {
      'id': setlist.id,
      'name': setlist.name,
      'notes': setlist.notes,
      'favorite': setlist.favorite ? 1 : 0,
      'created_at': setlist.createdAt.toUtc().toIso8601String(),
      'updated_at': setlist.updatedAt.toUtc().toIso8601String(),
    };
    final updated = await txn.update(
      'setlists',
      values,
      where: 'id = ?',
      whereArgs: [setlist.id],
    );
    if (updated == 0) await txn.insert('setlists', values);
    await txn.delete(
      'setlist_entries',
      where: 'setlist_id = ?',
      whereArgs: [setlist.id],
    );
    final usedIds = <String>{};
    for (var i = 0; i < setlist.entries.length; i++) {
      final entry = setlist.entries[i];
      // setlist_entries.id is a global primary key: an id already used by
      // another setlist (a duplicated or imported setlist) or repeated within
      // this one is regenerated instead of aborting the whole write.
      var entryId = entry.id;
      while (usedIds.contains(entryId) ||
          (await txn.query(
            'setlist_entries',
            columns: ['id'],
            where: 'id = ?',
            whereArgs: [entryId],
            limit: 1,
          )).isNotEmpty) {
        entryId = newId();
      }
      usedIds.add(entryId);
      await txn.insert('setlist_entries', {
        'id': entryId,
        'setlist_id': setlist.id,
        'song_id': entry.songId,
        'position': i,
        'overrides': jsonEncode(entry.overrides),
      });
    }
    if (queue) await _queue(txn, setlist.id, 'setlist', 'save', null);
  }

  Future<void> importCollection(
    List<SongDocument> songs,
    List<SetlistDocument> setlists, {
    JsonMap? appSettings,
    String? expectedLibraryFingerprint,
  }) async {
    if (songs.map((song) => song.id).toSet().length != songs.length ||
        setlists.map((setlist) => setlist.id).toSet().length !=
            setlists.length) {
      throw const FormatException(
        'Imported collection contains duplicate document IDs.',
      );
    }
    await database.transaction((txn) async {
      if (expectedLibraryFingerprint != null &&
          await _libraryFingerprint(txn) != expectedLibraryFingerprint) {
        throw const FormatException('stale_backup_preview');
      }
      final remapped = <String, String>{};
      for (final song in songs) {
        final result = await _importSong(txn, song);
        if (result.forked) remapped[song.id] = result.song.id;
      }
      for (final setlist in setlists) {
        // Entries follow the imported copy of a song that had to be forked;
        // entries whose song is in neither the file nor the library are
        // dropped rather than failing the whole import on the foreign key.
        final entries = <SetlistEntry>[];
        for (final e in setlist.entries) {
          final songId = remapped[e.songId] ?? e.songId;
          final present = await txn.query(
            'songs',
            columns: ['id'],
            where: 'id = ?',
            whereArgs: [songId],
            limit: 1,
          );
          if (present.isEmpty) continue;
          entries.add(
            SetlistEntry(id: e.id, songId: songId, overrides: e.overrides),
          );
        }
        var imported = SetlistDocument(
          id: setlist.id,
          name: setlist.name,
          notes: setlist.notes,
          favorite: setlist.favorite,
          createdAt: setlist.createdAt,
          updatedAt: setlist.updatedAt,
          entries: entries,
        );
        // A local setlist with the same id but different content is kept; the
        // imported one is stored as a separate copy (like songs).
        final existing = await txn.query(
          'setlists',
          where: 'id = ?',
          whereArgs: [setlist.id],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final local = await _setlist(txn, existing.single);
          if (_sameSetlistContent(local, imported)) continue;
          imported = SetlistDocument(
            id: newId(),
            name: imported.name,
            notes: imported.notes,
            favorite: imported.favorite,
            createdAt: imported.createdAt,
            updatedAt: imported.updatedAt,
            entries: imported.entries,
          );
        }
        await _writeSetlist(txn, imported);
      }
      if (appSettings != null) {
        await txn.insert('settings', {
          'key': 'app',
          'value': jsonEncode(appSettings),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Replaces all library documents in one transaction, retaining the IDs,
  /// duplicate setlist occurrences, entry order, and per-entry overrides.
  Future<void> replaceLibrary(
    List<SongDocument> songs,
    List<SetlistDocument> setlists, {
    JsonMap? appSettings,
    String? expectedLibraryFingerprint,
  }) async {
    final songIds = songs.map((song) => song.id).toSet();
    final setlistIds = setlists.map((setlist) => setlist.id).toSet();
    final entryIds = <String>{};
    if (songIds.length != songs.length ||
        setlistIds.length != setlists.length) {
      throw const FormatException('invalid_archive');
    }
    for (final setlist in setlists) {
      for (final entry in setlist.entries) {
        if (!entryIds.add(entry.id) || !songIds.contains(entry.songId)) {
          throw const FormatException('invalid_archive');
        }
      }
    }
    final encodedSongs = songs.map((source) {
      final song = _sanitizeImportedDurations(source);
      return (song: song, document: _codec.encode(song));
    }).toList();
    await database.transaction((txn) async {
      if (expectedLibraryFingerprint != null &&
          await _libraryFingerprint(txn) != expectedLibraryFingerprint) {
        throw const FormatException('stale_backup_preview');
      }
      final oldSetlists = await txn.query('setlists', columns: const ['id']);
      final oldSongs = await txn.query('songs', columns: const ['id']);
      for (final row in oldSetlists) {
        await _queue(txn, row['id'] as String, 'setlist', 'delete', null);
      }
      for (final row in oldSongs) {
        await _queue(txn, row['id'] as String, 'song', 'delete', null);
      }
      await txn.delete('setlists');
      await txn.delete('setlist_entries');
      await txn.delete('songs');
      for (final item in encodedSongs) {
        await _writeSong(txn, item.song, item.document);
        await _queue(txn, item.song.id, 'song', 'save', item.song.revision);
      }
      for (final setlist in setlists) {
        await _writeSetlist(txn, setlist);
      }
      if (appSettings != null) {
        await txn.insert('settings', {
          'key': 'app',
          'value': jsonEncode(appSettings),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<String?> getSongHash(String id) async {
    final rows = await database.query(
      'songs',
      columns: ['content_hash'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['content_hash'] as String;
  }

  Future<String?> getSetlistHash(String id) async {
    final setlist = await getSetlist(id);
    return setlist == null
        ? null
        : sha256.convert(utf8.encode(jsonEncode(setlist.toJson()))).toString();
  }

  /// Conditional sync writes protect local edits made while the network was busy.
  /// Missing expected IDs are rejected; explicit null means the object must not exist.
  ///
  /// With [syncAccount], the sync baseline of every item that was actually
  /// written or deleted is updated in the same transaction: a key (`song:<id>`
  /// or `setlist:<id>`) of [baselineCloudHashes] maps to the cloud hash that
  /// was applied, or to null to forget the item. The local hash recorded is the
  /// hash of the stored state, so an interrupted sync can never leave the
  /// baseline disagreeing with the library.
  Future<JsonMap> applySyncChanges(
    List<SongDocument> songs,
    List<SetlistDocument> setlists, {
    required Map<String, String?> expectedSongHashes,
    required Map<String, String?> expectedSetlistHashes,
    List<String> deletedSongIds = const [],
    List<String> deletedSetlistIds = const [],
    String? syncAccount,
    Map<String, String?> baselineCloudHashes = const {},
  }) async {
    final documents = {for (final song in songs) song.id: _codec.encode(song)};
    for (final song in songs) {
      final encoded = documents[song.id]!;
      final parsed = _codec.decode(encoded);
      if (song.extensionError != null ||
          parsed.extensionError != null ||
          parsed.id != song.id) {
        throw const FormatException('invalid_local_data');
      }
    }
    return database.transaction((txn) async {
      final savedSongs = <String>[],
          savedSetlists = <String>[],
          conflictSongs = <String>[],
          conflictSetlists = <String>[];
      final savedSongHashes = <String, String?>{},
          savedSetlistHashes = <String, String?>{};
      Future<bool> songUnchanged(String id) async {
        if (!expectedSongHashes.containsKey(id)) return false;
        final state = await _validatedSongState(
          txn,
          id,
          requireSyncRepresentation: true,
        );
        return state?.hash == expectedSongHashes[id];
      }

      Future<bool> setlistUnchanged(String id) async {
        if (!expectedSetlistHashes.containsKey(id)) return false;
        final rows = await txn.query(
          'setlists',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        final hash = rows.isEmpty
            ? null
            : sha256
                  .convert(
                    utf8.encode(
                      jsonEncode((await _setlist(txn, rows.single)).toJson()),
                    ),
                  )
                  .toString();
        return hash == expectedSetlistHashes[id];
      }

      for (final song in songs) {
        if (!await songUnchanged(song.id)) {
          conflictSongs.add(song.id);
          continue;
        }
        await _writeSong(txn, song, documents[song.id]!);
        savedSongs.add(song.id);
        savedSongHashes[song.id] = _localSongHash(
          documents[song.id]!,
          song.extensionError == null
              ? null
              : sha256
                    .convert(utf8.encode(jsonEncode(song.toJson())))
                    .toString(),
        );
      }
      // Deletions run before setlist saves so a saved setlist is validated
      // against the final song set and its stored state matches its hash.
      for (final id in deletedSetlistIds) {
        if (!await setlistUnchanged(id)) {
          conflictSetlists.add(id);
          continue;
        }
        await txn.delete('setlists', where: 'id = ?', whereArgs: [id]);
        savedSetlists.add(id);
        savedSetlistHashes[id] = null;
      }
      for (final id in deletedSongIds) {
        if (!await songUnchanged(id)) {
          conflictSongs.add(id);
          continue;
        }
        await _deleteSongTouchingSetlists(txn, id);
        savedSongs.add(id);
        savedSongHashes[id] = null;
      }
      for (final setlist in setlists) {
        if (!await setlistUnchanged(setlist.id)) {
          conflictSetlists.add(setlist.id);
          continue;
        }
        var missing = false;
        for (final entry in setlist.entries) {
          if ((await txn.query(
            'songs',
            columns: ['id'],
            where: 'id = ?',
            whereArgs: [entry.songId],
            limit: 1,
          )).isEmpty) {
            missing = true;
            break;
          }
        }
        if (missing) {
          conflictSetlists.add(setlist.id);
          continue;
        }
        // Applied from the cloud: already acknowledged, so never queued.
        await _writeSetlist(txn, setlist, queue: false);
        savedSetlists.add(setlist.id);
        // Hash the stored state (entry ids may have been regenerated).
        final stored = await txn.query(
          'setlists',
          where: 'id = ?',
          whereArgs: [setlist.id],
          limit: 1,
        );
        savedSetlistHashes[setlist.id] = sha256
            .convert(
              utf8.encode(
                jsonEncode((await _setlist(txn, stored.single)).toJson()),
              ),
            )
            .toString();
      }
      if (syncAccount != null) {
        for (final id in savedSongs) {
          final key = 'song:$id';
          if (!baselineCloudHashes.containsKey(key)) continue;
          await _writeBaseline(
            txn,
            syncAccount,
            'song',
            id,
            baselineCloudHashes[key],
            savedSongHashes[id],
          );
        }
        for (final id in savedSetlists) {
          final key = 'setlist:$id';
          if (!baselineCloudHashes.containsKey(key)) continue;
          await _writeBaseline(
            txn,
            syncAccount,
            'setlist',
            id,
            baselineCloudHashes[key],
            savedSetlistHashes[id],
          );
        }
      }
      return {
        'savedSongIds': savedSongs,
        'savedSetlistIds': savedSetlists,
        'savedSongHashes': savedSongHashes,
        'savedSetlistHashes': savedSetlistHashes,
        'conflictingSongIds': conflictSongs,
        'conflictingSetlistIds': conflictSetlists,
      };
    });
  }

  static Future<void> _writeBaseline(
    DatabaseExecutor txn,
    String account,
    String kind,
    String id,
    String? cloudHash,
    String? localHash,
  ) async {
    if (cloudHash == null || localHash == null) {
      await txn.delete(
        'sync_items',
        where: 'account = ? AND kind = ? AND item_id = ?',
        whereArgs: [account, kind, id],
      );
      return;
    }
    await txn.insert('sync_items', {
      'account': account,
      'kind': kind,
      'item_id': id,
      'cloud_hash': cloudHash,
      'local_hash': localHash,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Every baseline row of [account], keyed `kind:id`.
  Future<Map<String, SyncBaseline>> loadSyncBaselines(String account) async {
    final rows = await database.query(
      'sync_items',
      where: 'account = ?',
      whereArgs: [account],
    );
    return {
      for (final row in rows)
        '${row['kind']}:${row['item_id']}': SyncBaseline(
          kind: row['kind'] as String,
          id: row['item_id'] as String,
          cloudHash: row['cloud_hash'] as String,
          localHash: row['local_hash'] as String,
        ),
    };
  }

  /// Upserts [puts] and forgets [removeKeys] (`kind:id`) in one transaction.
  Future<void> writeSyncBaselines(
    String account, {
    Iterable<SyncBaseline> puts = const [],
    Iterable<String> removeKeys = const [],
  }) async {
    await database.transaction((txn) async {
      for (final put in puts) {
        await _writeBaseline(
          txn,
          account,
          put.kind,
          put.id,
          put.cloudHash,
          put.localHash,
        );
      }
      for (final key in removeKeys) {
        final split = key.indexOf(':');
        await _writeBaseline(
          txn,
          account,
          key.substring(0, split),
          key.substring(split + 1),
          null,
          null,
        );
      }
    });
  }

  /// Forgets all baselines, or all but those of [exceptAccount].
  Future<void> clearSyncBaselines({String? exceptAccount}) async {
    if (exceptAccount == null) {
      await database.delete('sync_items');
    } else {
      await database.delete(
        'sync_items',
        where: 'account <> ?',
        whereArgs: [exceptAccount],
      );
    }
  }

  /// The unchanged ChordPro document and local state hash of a song, or null.
  Future<({String document, String hash})?> getSongRaw(String id) async {
    return database.transaction((txn) async {
      final state = await _validatedSongState(
        txn,
        id,
        requireSyncRepresentation: false,
      );
      if (state == null) return null;
      return (document: state.document, hash: state.hash);
    });
  }

  /// Raw bytes for Drive sync. Unlike backup reads, sync is restricted to
  /// complete records whose identity survives a ChordPro encode/decode cycle.
  Future<({String document, String hash})?> getSyncSongRaw(String id) async {
    return database.transaction((txn) async {
      final state = await _validatedSongState(
        txn,
        id,
        requireSyncRepresentation: true,
      );
      if (state == null) return null;
      return (document: state.document, hash: state.hash);
    });
  }

  /// Id of the newest outbox row (0 when empty). Together with
  /// [clearOutboxThrough] it lets a completed sync acknowledge exactly the
  /// edits it started with, never one made while it ran.
  Future<int> outboxMark() async {
    final rows = await database.rawQuery('SELECT MAX(rowid) AS m FROM outbox');
    return (rows.single['m'] as int?) ?? 0;
  }

  Future<void> clearOutboxThrough(int mark) => database
      .delete('outbox', where: 'rowid <= ?', whereArgs: [mark])
      .then((_) {});

  Future<void> deleteSetlist(String id) async {
    await database.transaction((txn) async {
      await txn.delete('setlists', where: 'id = ?', whereArgs: [id]);
      await _queue(txn, id, 'setlist', 'delete', null);
    });
  }

  Future<dynamic> getSetting(String key) async {
    final rows = await database.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : jsonDecode(rows.single['value'] as String);
  }

  Future<void> setSetting(String key, dynamic value) async {
    final encoded = jsonEncode(value);
    await database.insert('settings', {
      'key': key,
      'value': encoded,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ActivityEntry>> listActivity({
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await database.query(
      'activity',
      orderBy: 'occurred_at DESC,id DESC',
      limit: limit.clamp(1, 500),
      offset: offset,
    );
    return rows
        .map(
          (r) => ActivityEntry(
            id: r['id'] as String,
            objectId: r['object_id'] as String,
            objectKind: r['object_kind'] as String,
            action: r['action'] as String,
            occurredAt: DateTime.parse(r['occurred_at'] as String),
          ),
        )
        .toList();
  }

  /// Returns the latest activity row for each existing song or setlist,
  /// ordered by its timestamp and then ID. [openCount] on each result counts
  /// all historical `opened` events for that object.
  Future<List<ActivityEntry>> listRecentActivity({
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await database.rawQuery(
      '''
      WITH activity_summary AS (
        SELECT
          object_kind,
          object_id,
          MAX(occurred_at) AS latest_at,
          SUM(CASE WHEN action = 'opened' THEN 1 ELSE 0 END) AS open_count
        FROM activity
        GROUP BY object_kind, object_id
      ), latest_ids AS (
        SELECT a.object_kind, a.object_id, MAX(a.id) AS latest_id
        FROM activity AS a
        JOIN activity_summary AS summary
          ON summary.object_kind = a.object_kind
          AND summary.object_id = a.object_id
          AND summary.latest_at = a.occurred_at
        GROUP BY a.object_kind, a.object_id
      )
      SELECT
        latest.id,
        latest.object_id,
        latest.object_kind,
        latest.action,
        latest.occurred_at,
        summary.open_count
      FROM latest_ids
      JOIN activity AS latest
        ON latest.id = latest_ids.latest_id
      JOIN activity_summary AS summary
        ON summary.object_kind = latest.object_kind
        AND summary.object_id = latest.object_id
      WHERE (latest.object_kind = 'song' AND EXISTS (
        SELECT 1 FROM songs AS s WHERE s.id = latest.object_id
      )) OR (latest.object_kind = 'setlist' AND EXISTS (
        SELECT 1 FROM setlists AS l WHERE l.id = latest.object_id
      ))
      ORDER BY latest.occurred_at DESC, latest.id DESC
      LIMIT ? OFFSET ?
      ''',
      [limit.clamp(1, 0x7fffffff), offset.clamp(0, 0x7fffffff)],
    );
    return rows
        .map(
          (r) => ActivityEntry(
            id: r['id'] as String,
            objectId: r['object_id'] as String,
            objectKind: r['object_kind'] as String,
            action: r['action'] as String,
            occurredAt: DateTime.parse(r['occurred_at'] as String),
            openCount: r['open_count'] as int,
          ),
        )
        .toList();
  }

  Future<void> addActivity(ActivityEntry entry) => database
      .insert('activity', {
        'id': entry.id,
        'object_id': entry.objectId,
        'object_kind': entry.objectKind,
        'action': entry.action,
        'occurred_at': entry.occurredAt.toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore)
      .then((_) {});
  Future<void> clearActivity() => database.delete('activity').then((_) {});
  Future<void> _queue(
    DatabaseExecutor db,
    String id,
    String kind,
    String action,
    int? revision,
  ) async {
    await db.insert('outbox', {
      'id': newId(),
      'object_id': id,
      'object_kind': kind,
      'action': action,
      'revision': revision,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> close() => database.close();
}

/// Writes related sync settings in one SQLite transaction. This is used for
/// state transitions whose partial persistence could make recovery destructive.
extension AtomicLibrarySettings on LibraryRepository {
  Future<void> setSettingsAtomically(Map<String, Object?> values) =>
      database.transaction((txn) async {
        for (final entry in values.entries) {
          await txn.insert('settings', {
            'key': entry.key,
            'value': jsonEncode(entry.value),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
}
