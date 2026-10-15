import 'dart:convert';
import 'package:crypto/crypto.dart';

class SyncException implements Exception {
  const SyncException(this.code);
  final String code;
  @override
  String toString() => 'SyncException($code)';
}

String syncHash(String content) =>
    sha256.convert(utf8.encode(content)).toString();

/// Value of the `verseSchema` file property. Files without it are not ours.
const syncSchema = '2';

/// A remote file larger than this is never downloaded or applied.
const maxSyncFileBytes = 16 * 1024 * 1024;

/// Songs plus setlists, local and remote. Beyond this sync stops with
/// `remote_library_too_large` / `library_too_large` and changes nothing.
const maxSyncItems = 20000;

final _hashPattern = RegExp(r'^[a-f0-9]{64}$');
bool isSyncHash(Object? value) => value is String && _hashPattern.hasMatch(value);

final _plainId = RegExp(r'^[A-Za-z0-9_-]{1,160}$');
final _fileName = RegExp(r'^(song|setlist)-([A-Za-z0-9_~-]{1,170})\.(cho|json)$');

String _encodeId(String id) {
  if (_plainId.hasMatch(id)) return id;
  final bytes = utf8.encode(id);
  if (id.isEmpty || bytes.length > 120) throw const SyncException('invalid_local_data');
  return '~${base64Url.encode(bytes).replaceAll('=', '')}';
}

/// Cloud file name of an item: `song-<id>.cho` or `setlist-<id>.json`. An id
/// outside `[A-Za-z0-9_-]` (or longer than 160) is carried as `~` + base64url,
/// so every name uses a safe charset. Throws `invalid_local_data` when an id
/// cannot be represented at all.
String syncFileName(String kind, String id) {
  if (kind != 'song' && kind != 'setlist') {
    throw const SyncException('invalid_local_data');
  }
  return '$kind-${_encodeId(id)}.${kind == 'song' ? 'cho' : 'json'}';
}

/// Parses a cloud file name; null for anything that is not a canonical item
/// name (foreign files, odd encodings). Never trust a name beyond this check.
({String kind, String id})? parseSyncFileName(String name) {
  final match = _fileName.firstMatch(name);
  if (match == null) return null;
  final kind = match.group(1)!, part = match.group(2)!, ext = match.group(3)!;
  if ((kind == 'song') != (ext == 'cho')) return null;
  String id;
  if (part.startsWith('~')) {
    try {
      final body = part.substring(1);
      final padded = body.padRight((body.length + 3) ~/ 4 * 4, '=');
      id = utf8.decode(base64Url.decode(padded));
    } catch (_) {
      return null;
    }
  } else {
    id = part;
  }
  try {
    if (_encodeId(id) != part) return null; // non canonical spelling
  } on SyncException {
    return null;
  }
  return (kind: kind, id: id);
}

String conflictDocumentId(String originalId, String hash) =>
    'conflict-${syncHash(originalId).substring(0, 16)}-${hash.substring(0, 24)}';

class SyncReport {
  const SyncReport({
    this.uploaded = 0,
    this.downloaded = 0,
    this.conflicts = 0,
    this.deletedLocal = 0,
    this.deletedRemote = 0,
    this.skipped = 0,
    this.pending = 0,
    this.skipCodes = const [],
  });

  /// Files written to the cloud (created or updated in place).
  final int uploaded;

  /// Items created or updated in the local library from the cloud.
  final int downloaded;

  /// Concurrent edits kept as a separate local copy.
  final int conflicts;

  /// Local items removed because they were deleted elsewhere, and cloud files
  /// removed because they were deleted here.
  final int deletedLocal, deletedRemote;

  /// Items left untouched because the remote file was unusable (too large,
  /// corrupted, ...). They are retried by the next sync; see [skipCodes].
  final int skipped;

  /// Items not applied because the local library changed meanwhile; the next
  /// sync decides them again.
  final int pending;
  final List<String> skipCodes;

  /// Nothing was written anywhere.
  bool get isNoop =>
      uploaded == 0 &&
      downloaded == 0 &&
      conflicts == 0 &&
      deletedLocal == 0 &&
      deletedRemote == 0;
}
