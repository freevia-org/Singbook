import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../domain/models.dart';
import '../providers/native_client.dart';
import 'google_auth.dart';
import 'sync_protocol.dart';

/// One file of the Drive appDataFolder as returned by a metadata listing.
class DriveFile {
  const DriveFile({
    required this.id,
    required this.name,
    this.properties = const {},
    this.modifiedTime,
    this.version,
    this.size,
    this.md5Checksum,
    this.headRevisionId,
  });
  final String id, name;

  /// `appProperties`: `kind`, `hash` (sha-256 of the body) and `verseSchema`.
  final Map<String, String> properties;
  final DateTime? modifiedTime;

  /// Drive's monotonically increasing file version. Compared before an
  /// in-place update to detect a concurrent writer.
  final String? version;
  final int? size;
  final String? md5Checksum, headRevisionId;

  String? get hash => properties['hash'];
}

/// The cloud side of sync: a flat set of files addressed by id. In-place
/// updates keep the file id; Drive keeps older bodies as file revisions.
abstract interface class SyncCloudStore {
  /// Metadata of every sync file (no bodies).
  Future<List<DriveFile>> listFiles();

  /// Body of a file. A file that vanished is `remote_file_missing`; one over
  /// [maxSyncFileBytes] is `remote_file_too_large`.
  Future<String> readFile(String id);

  /// Current metadata of one file, or null when it no longer exists.
  Future<DriveFile?> getFile(String id);
  Future<DriveFile> createFile(
    String name,
    String content,
    Map<String, String> properties,
  );

  /// Replaces body and properties of an existing file. A file that vanished is
  /// `remote_file_missing`.
  Future<DriveFile> updateFile(
    String id,
    String content,
    Map<String, String> properties,
  );

  /// Deleting a file that no longer exists succeeds.
  Future<void> deleteFile(String id);
}

class _HttpFailure implements Exception {
  const _HttpFailure(this.status, this.code, this.retryable, [this.retryAfter]);
  final int status;
  final String code;
  final bool retryable;
  final Duration? retryAfter;
}

/// 403 reasons Google documents as transient rate limiting rather than a
/// permission problem: https://developers.google.com/workspace/drive/api/guides/handle-errors
const _retryableForbiddenReasons = {
  'rateLimitExceeded',
  'userRateLimitExceeded',
  'backendError',
  'sharingRateLimitExceeded',
};

final _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,200}$');
final _safeNamePattern = RegExp(r'^[A-Za-z0-9._~-]{1,255}$');

class DriveAppDataStore implements SyncCloudStore {
  DriveAppDataStore({
    required this.authorization,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 30),
    this.maxAttempts = 4,
    Duration Function(int attempt)? backoff,
  }) : _client = client ?? createNativeHttpClient(),
       _backoff = backoff ?? _defaultBackoff;
  final DriveAuthorization authorization;
  final http.Client _client;
  final Duration requestTimeout;
  final int maxAttempts;
  final Duration Function(int attempt) _backoff;
  static const maxFileBytes = maxSyncFileBytes;

  /// Upper bound for one listing (all pages).
  static const maxListedFiles = 2 * maxSyncItems;
  static const _maxErrorBodyBytes = 64 * 1024;
  static const _maxRetryAfter = Duration(seconds: 30);
  static const _fields =
      'id,name,modifiedTime,version,size,md5Checksum,headRevisionId,appProperties';

  static Duration _defaultBackoff(int attempt) =>
      Duration(milliseconds: 500 * (1 << attempt));

  /// [recover] runs before every retry of a non-idempotent request (a create).
  /// When it returns a body the earlier attempt actually succeeded.
  Future<String> _request(
    String method,
    Uri uri, {
    String? body,
    String? contentType,
    bool fileScoped = false,
    Future<String?> Function()? recover,
  }) async {
    var reauthorized = false;
    for (var attempt = 0; ; attempt++) {
      try {
        if (attempt > 0 && recover != null) {
          final found = await recover();
          if (found != null) return found;
        }
        final token = await authorization.accessToken();
        return await _send(
          method,
          uri,
          token,
          body: body,
          contentType: contentType,
        );
      } on _HttpFailure catch (failure) {
        final auth = authorization;
        if (failure.status == 401 &&
            !reauthorized &&
            auth is RefreshableAuthorization) {
          // The cached token was revoked or expired: obtain a fresh one once.
          reauthorized = true;
          await (auth as RefreshableAuthorization).refreshAccessToken();
          attempt--;
          continue;
        }
        if (failure.retryable && attempt + 1 < maxAttempts) {
          await Future<void>.delayed(failure.retryAfter ?? _backoff(attempt));
          continue;
        }
        if (fileScoped && failure.status == 404) {
          throw const SyncException('remote_file_missing');
        }
        throw SyncException(failure.code);
      }
    }
  }

  Future<String> _send(
    String method,
    Uri uri,
    String token, {
    String? body,
    String? contentType,
  }) async {
    final request = http.Request(method, uri)..followRedirects = false;
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = contentType ?? 'application/json';
      request.bodyBytes = utf8.encode(body);
    }
    try {
      // The deadline covers the whole upload: grow it with the body size
      // (about 100 kB/s minimum) so a big song on a slow link can finish.
      final sendTimeout =
          requestTimeout +
          Duration(seconds: body == null ? 0 : request.bodyBytes.length ~/ 100000);
      final response = await _client.send(request).timeout(sendTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorBody = await _readErrorBody(response);
        throw _classify(
          response.statusCode,
          errorBody,
          response.headers['retry-after'],
        );
      }
      final declared = response.contentLength;
      if (declared != null && declared > maxFileBytes) {
        throw const SyncException('remote_file_too_large');
      }
      final bytes = BytesBuilder(copy: false);
      await for (final part in response.stream.timeout(requestTimeout)) {
        if (bytes.length + part.length > maxFileBytes) {
          throw const SyncException('remote_file_too_large');
        }
        bytes.add(part);
      }
      return utf8.decode(bytes.takeBytes());
    } on SyncException {
      rethrow;
    } on _HttpFailure {
      rethrow;
    } on FormatException {
      throw const SyncException('invalid_remote_data');
    } catch (_) {
      throw const _HttpFailure(0, 'network', true);
    }
  }

  Future<String> _readErrorBody(http.StreamedResponse response) async {
    final bytes = BytesBuilder(copy: false);
    try {
      await for (final part in response.stream.timeout(requestTimeout)) {
        if (bytes.length + part.length > _maxErrorBodyBytes) break;
        bytes.add(part);
      }
    } catch (_) {}
    return utf8.decode(bytes.takeBytes(), allowMalformed: true);
  }

  _HttpFailure _classify(int status, String body, String? retryAfter) {
    final seconds = int.tryParse(retryAfter ?? '');
    final wait = seconds == null || seconds < 0
        ? null
        : Duration(seconds: seconds) > _maxRetryAfter
        ? _maxRetryAfter
        : Duration(seconds: seconds);
    switch (status) {
      case 401:
        return _HttpFailure(status, 'authorization_required', false);
      case 403:
        final reasons = <String>{};
        try {
          final error = jsonMap(jsonDecode(body))['error'];
          for (final item in jsonMap(error)['errors'] as List? ?? const []) {
            final reason = jsonMap(item)['reason'];
            if (reason is String) reasons.add(reason);
          }
        } catch (_) {}
        if (reasons.any(_retryableForbiddenReasons.contains)) {
          return _HttpFailure(status, 'rate_limited', true, wait);
        }
        if (reasons.contains('dailyLimitExceeded') ||
            reasons.contains('quotaExceeded')) {
          return _HttpFailure(status, 'rate_limited', false);
        }
        if (reasons.contains('storageQuotaExceeded')) {
          return _HttpFailure(status, 'storage_full', false);
        }
        return _HttpFailure(status, 'access_denied', false);
      case 429:
        return _HttpFailure(status, 'rate_limited', true, wait);
      default:
        return _HttpFailure(status, 'network', status >= 500, wait);
    }
  }

  static void _checkId(String id) {
    if (!_idPattern.hasMatch(id)) {
      throw const SyncException('invalid_remote_data');
    }
  }

  DriveFile _parse(Object? item) {
    final row = jsonMap(item);
    final id = row['id'], name = row['name'];
    if (id is! String || !_idPattern.hasMatch(id) || name is! String) {
      throw const SyncException('invalid_remote_data');
    }
    final size = row['size'];
    return DriveFile(
      id: id,
      name: name,
      properties: stringMap(row['appProperties']),
      modifiedTime: DateTime.tryParse(
        row['modifiedTime'] as String? ?? '',
      )?.toUtc(),
      version: row['version']?.toString(),
      size: size == null ? null : int.tryParse(size.toString()),
      md5Checksum: row['md5Checksum'] as String?,
      headRevisionId: row['headRevisionId'] as String?,
    );
  }

  static Uri _api(String path, [Map<String, String>? query]) =>
      Uri.https('www.googleapis.com', path, query);

  @override
  Future<List<DriveFile>> listFiles() async {
    final files = <DriveFile>[];
    String? page;
    do {
      final text = await _request(
        'GET',
        _api('/drive/v3/files', {
          'spaces': 'appDataFolder',
          'q':
              "appProperties has { key='verseSchema' and value='$syncSchema' } and trashed = false",
          'pageSize': '1000',
          'fields': 'nextPageToken,files($_fields)',
          'pageToken': ?page,
        }),
      );
      final data = jsonMap(jsonDecode(text));
      for (final item in data['files'] as List? ?? const []) {
        files.add(_parse(item));
      }
      if (files.length > maxListedFiles) {
        throw const SyncException('remote_library_too_large');
      }
      page = data['nextPageToken'] as String?;
    } while (page != null);
    return files;
  }

  @override
  Future<String> readFile(String id) async {
    _checkId(id);
    return _request(
      'GET',
      _api('/drive/v3/files/$id', {'alt': 'media'}),
      fileScoped: true,
    );
  }

  @override
  Future<DriveFile?> getFile(String id) async {
    _checkId(id);
    try {
      final text = await _request(
        'GET',
        _api('/drive/v3/files/$id', {'fields': _fields}),
        fileScoped: true,
      );
      return _parse(jsonDecode(text));
    } on SyncException catch (e) {
      if (e.code == 'remote_file_missing') return null;
      rethrow;
    }
  }

  @override
  Future<void> deleteFile(String id) async {
    _checkId(id);
    try {
      await _request('DELETE', _api('/drive/v3/files/$id'), fileScoped: true);
    } on SyncException catch (e) {
      if (e.code != 'remote_file_missing') rethrow;
    }
  }

  String _multipart(
    String boundary,
    JsonMap metadata,
    String content,
    String mime,
  ) =>
      '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${jsonEncode(metadata)}\r\n'
      '--$boundary\r\nContent-Type: $mime; charset=UTF-8\r\n\r\n$content\r\n--$boundary--';

  Map<String, String> _props(Map<String, String> properties) => {
    ...properties,
    'verseSchema': syncSchema,
  };

  void _checkSize(String content) {
    if (utf8.encode(content).length > maxFileBytes - 8192) {
      throw const SyncException('local_file_too_large');
    }
  }

  @override
  Future<DriveFile> createFile(
    String name,
    String content,
    Map<String, String> properties,
  ) async {
    if (!_safeNamePattern.hasMatch(name)) {
      throw const SyncException('invalid_local_data');
    }
    _checkSize(content);
    final boundary = 'verse_${newId()}';
    final mime = name.endsWith('.cho') ? 'text/plain' : 'application/json';
    final props = _props(properties);
    final text = await _request(
      'POST',
      _api('/upload/drive/v3/files', {
        'uploadType': 'multipart',
        'fields': _fields,
      }),
      body: _multipart(boundary, {
        'name': name,
        'parents': ['appDataFolder'],
        'mimeType': mime,
        'appProperties': props,
      }, content, mime),
      contentType: 'multipart/related; boundary=$boundary',
      // A create whose answer was lost may have succeeded: look for it before
      // posting again, so a retry does not leave a second file of that name.
      recover: () => _findCreated(name, props['hash']),
    );
    return _parse(jsonDecode(text));
  }

  Future<String?> _findCreated(String name, String? hash) async {
    try {
      final text = await _request(
        'GET',
        _api('/drive/v3/files', {
          'spaces': 'appDataFolder',
          'q':
              "name = '$name' and appProperties has { key='verseSchema' and value='$syncSchema' } and trashed = false",
          'pageSize': '10',
          'fields': 'files($_fields)',
        }),
      );
      final files = jsonMap(jsonDecode(text))['files'] as List? ?? const [];
      for (final item in files) {
        if (stringMap(jsonMap(item)['appProperties'])['hash'] == hash) {
          return jsonEncode(item);
        }
      }
    } catch (_) {
      // Looking is best effort; a duplicate is repaired by the next sync.
    }
    return null;
  }

  @override
  Future<DriveFile> updateFile(
    String id,
    String content,
    Map<String, String> properties,
  ) async {
    _checkId(id);
    _checkSize(content);
    final boundary = 'verse_${newId()}';
    final mime = properties['kind'] == 'song'
        ? 'text/plain'
        : 'application/json';
    // The body is identical on every attempt, so retrying is idempotent.
    final text = await _request(
      'PATCH',
      _api('/upload/drive/v3/files/$id', {
        'uploadType': 'multipart',
        'fields': _fields,
      }),
      body: _multipart(boundary, {
        'appProperties': _props(properties),
      }, content, mime),
      contentType: 'multipart/related; boundary=$boundary',
      fileScoped: true,
    );
    return _parse(jsonDecode(text));
  }

  void close() => _client.close();
}
