import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'native_client.dart';

/// Codes are stable UI/localization keys; upstream body text is never an error.
///
/// Notable codes: `rate_limited` (HTTP 429/503), `blocked` (bot wall, consent
/// page or Cloudflare challenge; the message says which), `extraction_failed`
/// (page layout no longer matches), `redirect` (refused or malformed redirect).
class ProviderException implements Exception {
  const ProviderException(this.code, [this.message = '']);
  final String code;
  final String message;
  @override
  String toString() =>
      'ProviderException($code${message.isEmpty ? '' : ': $message'})';
}

class CancellationToken {
  final Completer<void> _done = Completer<void>();
  bool get isCancelled => _done.isCompleted;
  Future<void> get cancelled => _done.future;
  void cancel() {
    if (!isCancelled) _done.complete();
  }

  void throwIfCancelled() {
    if (isCancelled) throw const ProviderException('cancelled');
  }
}

/// Application version sent in the User-Agent. Keep in sync with the
/// `version:` line in pubspec.yaml (a unit test enforces this).
const singbookVersion = '0.2.0';

/// Optional contact URL for API operators (MusicBrainz and Wikimedia policies
/// ask for one). Supply `SINGBOOK_CONTACT_URL` in config/local.defines.json; no
/// placeholder address is invented when it is absent.
const singbookContactUrl = String.fromEnvironment('SINGBOOK_CONTACT_URL');
const providerUserAgent = singbookContactUrl == ''
    ? 'Singbook/$singbookVersion (on-device songbook)'
    : 'Singbook/$singbookVersion (+$singbookContactUrl)';

/// Absolute ceiling for any single response, including per-request overrides.
const _hardMaxBytes = 16 * 1024 * 1024;
const _sensitiveHeaders = {
  'authorization',
  'cookie',
  'proxy-authorization',
  'x-goog-visitor-id',
};

/// One queue per host avoids bursts across adapters sharing a catalog.
/// Denials are surfaced. Redirects are followed manually (max 3 hops) only to
/// the same host (or its www/apex twin) or an explicitly allowlisted HTTPS
/// host, and credentials are never forwarded to another host.
class ProviderTransport {
  ProviderTransport({
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
    this.hostInterval = const Duration(milliseconds: 300),
    this.maxBytes = 4 * 1024 * 1024,
    this.maxRetries = 2,
    this.retryBaseDelay = const Duration(milliseconds: 500),
    this.maxRetryDelay = const Duration(seconds: 8),
    this.redirectHosts = const {},
  }) : _client = client ?? createNativeHttpClient();
  final http.Client _client;
  final Duration timeout;
  final Duration hostInterval;
  final int maxBytes;

  /// Bounded retries (GET only) for 429/503, with exponential backoff or the
  /// server's `Retry-After` seconds. A wait above [maxRetryDelay] is not retried.
  final int maxRetries;
  final Duration retryBaseDelay;
  final Duration maxRetryDelay;

  /// Extra hosts a redirect may lead to, in addition to the request's own host.
  final Set<String> redirectHosts;
  final Map<String, Future<void>> _queues = {};
  final Map<String, DateTime> _next = {};
  final Set<Future<void>> _inFlight = {};
  final Map<Future<void>, void Function()> _aborters = {};
  bool _closed = false;
  Future<void>? _closing;

  Future<String> getText(
    Uri url, {
    Map<String, String> headers = const {},
    CancellationToken? cancel,
    int? maxBytes,
    Set<String>? allowedHosts,
  }) => requestText(url, headers: headers, cancel: cancel, maxBytes: maxBytes,
      allowedHosts: allowedHosts);

  Future<dynamic> requestJson(
    Uri url, {
    String method = 'GET',
    Map<String, String> headers = const {},
    Object? body,
    CancellationToken? cancel,
    int? maxBytes,
  }) async {
    final text = await requestText(
      url,
      method: method,
      headers: {'Accept': 'application/json', ...headers},
      body: body,
      cancel: cancel,
      maxBytes: maxBytes,
    );
    try {
      return jsonDecode(text);
    } catch (_) {
      throw const ProviderException('invalid_response', 'Invalid JSON');
    }
  }

  static bool _validUrl(Uri url) =>
      url.scheme == 'https' &&
      url.host.isNotEmpty &&
      url.userInfo.isEmpty &&
      (!url.hasPort || url.port == 443);

  /// An async function: validation failures are failed Futures, never
  /// synchronous throws.
  Future<String> requestText(
    Uri url, {
    String method = 'GET',
    Map<String, String> headers = const {},
    Object? body,
    CancellationToken? cancel,
    int? maxBytes,
    Set<String>? allowedHosts,
  }) async {
    if (_closed) throw const ProviderException('transport_closed');
    if (!_validUrl(url)) throw const ProviderException('invalid_url');
    final hostPolicy = allowedHosts == null ? null : Set<String>.unmodifiable(allowedHosts);
    if (hostPolicy != null && !hostPolicy.contains(url.host)) {
      throw const ProviderException('invalid_url');
    }
    cancel?.throwIfCancelled();
    final limit = (maxBytes ?? this.maxBytes).clamp(1, _hardMaxBytes);
    final previous = _queues[url.host] ?? Future<void>.value();
    final result = previous.then(
      (_) => _run(url, method, headers, body, cancel, limit, hostPolicy),
    );
    _queues[url.host] = result.then<void>((_) {}, onError: (Object _) {});
    return _cancellable(result, cancel);
  }

  bool _redirectAllowed(Uri origin, Uri target) {
    if (!_validUrl(target)) return false;
    final a = origin.host, b = target.host;
    return a == b ||
        'www.$a' == b ||
        'www.$b' == a ||
        redirectHosts.contains(b);
  }

  Future<void> _pace(String host, CancellationToken? cancel) async {
    final wait = (_next[host] ?? DateTime.now()).difference(DateTime.now());
    if (wait > Duration.zero) {
      await _cancellable(Future<void>.delayed(wait), cancel);
    }
    if (_closed) throw const ProviderException('transport_closed');
    cancel?.throwIfCancelled();
  }

  Future<String> _run(
    Uri start,
    String method,
    Map<String, String> headers,
    Object? body,
    CancellationToken? cancel,
    int limit,
    Set<String>? allowedHosts,
  ) async {
    if (_closed) throw const ProviderException('transport_closed');
    cancel?.throwIfCancelled();
    var url = start, verb = method, payload = body;
    var sent = {...headers};
    var hops = 0, retries = 0;
    while (true) {
      await _pace(url.host, cancel);
      final reply = await _once(url, verb, sent, payload, cancel, limit);
      final code = reply.status;
      if (code >= 200 && code < 300) return reply.text!;
      if ({301, 302, 303, 307, 308}.contains(code)) {
        final location = reply.headers['location'];
        final parsed = location == null || location.trim().isEmpty
            ? null
            : Uri.tryParse(location.trim());
        if (parsed == null) throw ProviderException('redirect', 'HTTP $code');
        final target = url.resolveUri(parsed);
        if (!_redirectAllowed(start, target) ||
            allowedHosts != null && !allowedHosts.contains(target.host) ||
            ++hops > 3) {
          throw ProviderException(
            'redirect',
            'HTTP $code -> ${target.host.isEmpty ? '?' : target.host}',
          );
        }
        if (target.host != url.host) {
          sent = {
            for (final e in sent.entries)
              if (!_sensitiveHeaders.contains(e.key.toLowerCase()))
                e.key: e.value,
          };
        }
        if (code == 303 || ((code == 301 || code == 302) && verb == 'POST')) {
          verb = 'GET';
          payload = null;
          sent = {
            for (final e in sent.entries)
              if (e.key.toLowerCase() != 'content-type') e.key: e.value,
          };
        }
        url = target;
        continue;
      }
      if ((code == 429 || code == 503) &&
          verb == 'GET' &&
          retries < maxRetries) {
        final asked = int.tryParse(reply.headers['retry-after']?.trim() ?? '');
        final delay = asked != null
            ? Duration(seconds: asked.clamp(0, 86400))
            : retryBaseDelay * (1 << retries);
        if (delay <= maxRetryDelay) {
          retries++;
          await _cancellable(Future<void>.delayed(delay), cancel);
          if (_closed) throw const ProviderException('transport_closed');
          continue;
        }
      }
      throw ProviderException(
        reply.headers.containsKey('cf-mitigated')
            ? 'blocked'
            : switch (code) {
                401 || 403 => 'access_denied',
                404 => 'unavailable',
                // MusicBrainz and others answer 503 when rate limiting.
                429 || 503 => 'rate_limited',
                >= 300 && < 400 => 'redirect',
                _ => 'network',
              },
        // A Cloudflare challenge is reported with the same reason the body
        // classifier uses, so the UI can explain it.
        reply.headers.containsKey('cf-mitigated') ? 'cloudflare' : 'HTTP $code',
      );
    }
  }

  Future<_Reply> _once(
    Uri url,
    String method,
    Map<String, String> headers,
    Object? body,
    CancellationToken? cancel,
    int limit,
  ) async {
    final abort = Completer<void>();
    void abortRequest() {
      if (!abort.isCompleted) abort.complete();
    }

    final request =
        http.AbortableRequest(method, url, abortTrigger: abort.future)
          ..followRedirects = false
          ..headers.addAll({'User-Agent': providerUserAgent, ...headers});
    if (body != null) {
      request.headers['Content-Type'] ??= 'application/json';
      request.body = body is String ? body : jsonEncode(body);
    }
    try {
      final Future<_Reply> operation = () async {
        final response = await _client.send(request);
        final code = response.statusCode;
        if (code < 200 || code >= 300) {
          await response.stream.listen((_) {}).cancel();
          return (status: code, headers: response.headers, text: null);
        }
        if ((response.contentLength ?? 0) > limit) {
          await response.stream.listen((_) {}).cancel();
          throw const ProviderException(
            'invalid_response',
            'Response too large',
          );
        }
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          cancel?.throwIfCancelled();
          if (bytes.length + chunk.length > limit) {
            throw const ProviderException(
              'invalid_response',
              'Response too large',
            );
          }
          bytes.add(chunk);
        }
        return (
          status: code,
          headers: response.headers,
          text: _decode(bytes.takeBytes(), response.headers['content-type']),
        );
      }();
      _track(operation, abortRequest);
      return await _cancellable(
        operation,
        cancel,
        onCancel: abortRequest,
      ).timeout(
        timeout,
        onTimeout: () {
          abortRequest();
          throw const ProviderException('timeout');
        },
      );
    } on ProviderException {
      rethrow;
    } catch (_) {
      cancel?.throwIfCancelled();
      throw const ProviderException('network');
    } finally {
      _next[url.host] = DateTime.now().add(hostInterval);
    }
  }

  /// Honours the Content-Type charset (UTF-8, ISO-8859-1/ASCII, Windows-1252);
  /// a missing or unsupported charset falls back to UTF-8.
  static String _decode(Uint8List bytes, String? contentType) {
    final charset = RegExp(
      r'charset\s*=\s*"?([A-Za-z0-9_.:-]+)',
      caseSensitive: false,
    ).firstMatch(contentType ?? '')?[1]?.toLowerCase();
    final String text;
    switch (charset) {
      case 'iso-8859-1' || 'latin1' || 'latin-1' || 'us-ascii' || 'ascii':
        text = latin1.decode(bytes, allowInvalid: true);
      case 'windows-1252' || 'cp1252':
        text = String.fromCharCodes(bytes.map((b) => _cp1252[b] ?? b));
      default:
        text = utf8.decode(bytes, allowMalformed: true);
    }
    return text.startsWith('﻿') ? text.substring(1) : text;
  }

  Future<T> _cancellable<T>(
    Future<T> future,
    CancellationToken? cancel, {
    void Function()? onCancel,
  }) {
    if (cancel == null) return future;
    cancel.throwIfCancelled();
    return Future.any([
      future,
      cancel.cancelled.then<T>((_) {
        onCancel?.call();
        throw const ProviderException('cancelled');
      }),
    ]);
  }

  void _track(Future<dynamic> operation, void Function() abort) {
    late final Future<void> tracked;
    tracked = operation
        .then<void>((_) {}, onError: (Object _, StackTrace _) {})
        .whenComplete(() {
          _inFlight.remove(tracked);
          _aborters.remove(tracked);
        });
    _inFlight.add(tracked);
    _aborters[tracked] = abort;
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _closed = true;
    for (final abort in _aborters.values.toList()) {
      abort();
    }
    // Queue futures settle as in-flight calls finish, or skip requests that
    // had not started before close. Native clients may still be cleaning up
    // after their callers have already observed a timeout or cancellation.
    await Future.wait([..._queues.values, ..._inFlight]);
    _client.close();
  }
}

typedef _Reply = ({int status, Map<String, String> headers, String? text});

const _cp1252 = {
  0x80: 0x20AC,
  0x82: 0x201A,
  0x83: 0x0192,
  0x84: 0x201E,
  0x85: 0x2026,
  0x86: 0x2020,
  0x87: 0x2021,
  0x88: 0x02C6,
  0x89: 0x2030,
  0x8A: 0x0160,
  0x8B: 0x2039,
  0x8C: 0x0152,
  0x8E: 0x017D,
  0x91: 0x2018,
  0x92: 0x2019,
  0x93: 0x201C,
  0x94: 0x201D,
  0x95: 0x2022,
  0x96: 0x2013,
  0x97: 0x2014,
  0x98: 0x02DC,
  0x99: 0x2122,
  0x9A: 0x0161,
  0x9B: 0x203A,
  0x9C: 0x0153,
  0x9E: 0x017E,
  0x9F: 0x0178,
};
