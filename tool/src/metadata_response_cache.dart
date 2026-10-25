import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:singbook/providers/native_client.dart';
import 'package:singbook/providers/transport.dart';

/// Bounded, privacy-conscious HTTP response cache for metadata QA runs.
class MetadataResponseCacheClient extends http.BaseClient {
  MetadataResponseCacheClient(
    this.directory, {
    required this.offline,
    this.networkBudget = 0,
    http.Client? inner,
    this.maxResponseBytes = 16 * 1024 * 1024,
    this.jitter,
  }) : _inner = inner ?? createNativeHttpClient();

  final Directory directory;
  final bool offline;
  final int networkBudget;
  final int maxResponseBytes;
  final http.Client _inner;
  final math.Random? jitter;
  final Map<String, Future<void>> _writes = {};

  int hits = 0;
  int networkAttempts = 0;
  int uncached = 0;
  int overBudget = 0;
  final Map<int, int> statusCounts = {};

  Map<String, Object> get counters => {
    'hits': hits,
    'networkAttempts': networkAttempts,
    'uncached': uncached,
    'overBudget': overBudget,
    'statusCounts': {
      for (final entry in statusCounts.entries) '${entry.key}': entry.value,
    },
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.bodyBytes : <int>[];
    final keyInput = <int>[
      ...utf8.encode('${request.method} ${request.url}\n'),
      ...body,
    ];
    final key = sha1.convert(keyInput).toString();
    final cached = await _read(key);
    if (cached != null) {
      hits++;
      final delay = jitter;
      if (delay != null) {
        await Future<void>.delayed(Duration(milliseconds: delay.nextInt(5)));
      }
      return _response(cached, request: request);
    }
    if (offline) {
      uncached++;
      throw const ProviderException('unavailable', 'offline cache miss');
    }
    if (networkAttempts >= networkBudget) {
      overBudget++;
      throw const ProviderException('unavailable', 'network budget exhausted');
    }
    networkAttempts++;
    final response = await _inner.send(request);
    statusCounts.update(response.statusCode, (n) => n + 1, ifAbsent: () => 1);
    final bytes = <int>[];
    try {
      await for (final chunk in response.stream) {
        if (bytes.length + chunk.length > maxResponseBytes) {
          uncached++;
          throw const ProviderException(
            'invalid_response',
            'response too large',
          );
        }
        bytes.addAll(chunk);
      }
    } catch (_) {
      rethrow;
    }
    final liveRecord = _Record(
      response.statusCode,
      Map<String, String>.from(response.headers),
      bytes,
    );
    final persistedRecord = _Record(
      response.statusCode,
      _cacheHeaders(response.headers),
      bytes,
    );
    if (_cacheable(persistedRecord)) {
      try {
        await _write(key, persistedRecord);
      } catch (_) {
        // Cache persistence is best effort; the response remains usable.
      }
    } else {
      uncached++;
    }
    return _response(liveRecord, request: request);
  }

  Future<_Record?> _read(String key) async {
    for (final candidate in [
      File('${directory.path}/$key.json.gz'),
      File('${directory.path}/$key.json'),
    ]) {
      try {
        final type = await FileSystemEntity.type(
          candidate.path,
          followLinks: false,
        );
        // Compressed cache files are owned by this client and must never be links.
        // Old plaintext entries may be linked from a shared read-only cache.
        if (candidate.path.endsWith('.gz') &&
            type != FileSystemEntityType.file) {
          continue;
        }
        if (candidate.path.endsWith('.json') &&
            type != FileSystemEntityType.file &&
            type != FileSystemEntityType.link) {
          continue;
        }
        final input = candidate.openRead();
        final decodedStream = candidate.path.endsWith('.gz')
            ? input.transform(gzip.decoder)
            : input;
        final maxJsonBytes = ((maxResponseBytes + 2) ~/ 3) * 4 + 128 * 1024;
        final decoded = <int>[];
        await for (final chunk in decodedStream) {
          if (decoded.length + chunk.length > maxJsonBytes) {
            throw const FormatException('Oversized cache envelope');
          }
          decoded.addAll(chunk);
        }
        final map = jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;
        final body = base64Decode(map['body'] as String);
        if (body.length > maxResponseBytes) continue;
        final headers = <String, String>{};
        if (map['headers'] is Map) {
          (map['headers'] as Map).forEach((k, v) {
            if (v is String) headers[k.toString().toLowerCase()] = v;
          });
        }
        final record = _Record(map['status'] as int, headers, body);
        if (_cacheable(record)) return record;
      } catch (_) {
        // Corrupt or incompatible cache entry: treat as a miss.
      }
    }
    return null;
  }

  Future<void> _write(String key, _Record value) async {
    final previous = _writes[key];
    if (previous != null) {
      await previous;
      return;
    }
    final done = Completer<void>();
    _writes[key] = done.future;
    try {
      await _writeExclusive(key, value);
    } finally {
      done.complete();
      _writes.remove(key);
    }
  }

  Future<void> _writeExclusive(String key, _Record value) async {
    await directory.create(recursive: true);
    final target = File('${directory.path}/$key.json.gz');
    if (await FileSystemEntity.type(target.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      return;
    }
    final json = utf8.encode(
      jsonEncode({
        'status': value.status,
        'headers': value.headers,
        'body': base64Encode(value.body),
      }),
    );
    final bytes = gzip.encode(json);
    final temp = File(
      '${directory.path}/.$key.$pid.${math.Random().nextInt(1 << 32)}.tmp',
    );
    try {
      await temp.writeAsBytes(bytes, flush: true);
      if (await FileSystemEntity.type(target.path, followLinks: false) ==
          FileSystemEntityType.notFound) {
        await temp.rename(target.path);
      }
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  bool _cacheable(_Record value) {
    if ({200, 401, 403, 404, 410}.contains(value.status)) return true;
    if ({301, 302, 307, 308}.contains(value.status)) {
      return _safeLocation(value.headers['location']);
    }
    return false;
  }

  bool _safeLocation(String? location) {
    if (location == null) return false;
    // Root-relative redirects are safe to replay because ProviderTransport
    // resolves them against the original HTTPS request URL. Keep this narrow:
    // scheme-relative URLs, backslashes, and controls can be interpreted
    // differently by URI parsers and HTTP clients.
    final isRootRelative =
        location.startsWith('/') &&
        !location.startsWith('//') &&
        !location.contains('\\') &&
        !RegExp(r'[\x00-\x1f\x7f]').hasMatch(location);
    final uri = Uri.tryParse(location);
    if (uri == null || uri.hasFragment) return false;
    if (isRootRelative) {
      if (uri.hasScheme ||
          uri.hasAuthority ||
          uri.userInfo.isNotEmpty ||
          !uri.path.startsWith('/')) {
        return false;
      }
    } else if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return false;
    }
    final sensitive = RegExp(
      r'(token|key|secret|signature|auth|access_token)',
      caseSensitive: false,
    );
    return !uri.queryParameters.keys.any(sensitive.hasMatch);
  }

  Map<String, String> _cacheHeaders(Map<String, String> headers) {
    final result = <String, String>{};
    final type = headers['content-type'];
    if (type != null) result['content-type'] = type;
    final location = headers['location'];
    if (_safeLocation(location)) result['location'] = location!;
    return result;
  }

  http.StreamedResponse _response(
    _Record record, {
    http.BaseRequest? request,
  }) => http.StreamedResponse(
    Stream<List<int>>.value(record.body),
    record.status,
    headers: record.headers,
    request: request,
    isRedirect: {301, 302, 303, 307, 308}.contains(record.status),
  );

  @override
  void close() => _inner.close();
}

class _Record {
  const _Record(this.status, this.headers, this.body);
  final int status;
  final Map<String, String> headers;
  final List<int> body;
}
