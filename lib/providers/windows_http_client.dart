import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;

/// Uses Windows' maintained HTTP/TLS stack, including informational responses,
/// certificate validation and system proxy discovery. Native work stays off the
/// UI isolate. Each request owns its session, connections and cookie boundary.
class WindowsHttpClient extends http.BaseClient {
  final _pending = <Completer<http.StreamedResponse>, Pointer<Uint8>?>{};
  bool _closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (_closed) {
      return Future.error(http.ClientException('Client is closed'));
    }
    final result = Completer<http.StreamedResponse>();
    _pending[result] = null;
    unawaited(_send(request, result));
    return result.future;
  }

  Future<void> _send(
    http.BaseRequest request,
    Completer<http.StreamedResponse> result,
  ) async {
    Pointer<Uint8>? cancellation;
    try {
      final body = await request.finalize().toBytes();
      if (result.isCompleted) return;
      cancellation = calloc<Uint8>();
      _pending[result] = cancellation;
      final data = _NativeRequest(
        request.url.toString(),
        request.method,
        Map.of(request.headers),
        body,
        request.followRedirects,
        request.maxRedirects,
      );
      final response = await _inWorker(data, cancellation.address);
      if (!result.isCompleted) {
        result.complete(
          http.StreamedResponse(
            Stream.value(response.body),
            response.status,
            request: request,
            headers: response.headers,
            reasonPhrase: response.reason,
            contentLength: response.body.length,
            isRedirect: response.isRedirect,
            persistentConnection: false,
          ),
        );
      }
    } catch (error) {
      if (!result.isCompleted) {
        result.completeError(
          error is http.ClientException
              ? error
              : http.ClientException('Windows HTTP request failed'),
        );
      }
    } finally {
      // The worker has closed all native handles before its result arrives.
      // Never kill an isolate executing FFI or free its cancellation byte early.
      if (cancellation != null) calloc.free(cancellation);
      _pending.remove(result);
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    for (final entry in _pending.entries) {
      entry.value?.value = 1;
      if (!entry.key.isCompleted) {
        entry.key.completeError(http.ClientException('Client is closed'));
      }
    }
  }
}

class _NativeRequest {
  const _NativeRequest(
    this.url,
    this.method,
    this.headers,
    this.body,
    this.followRedirects,
    this.maxRedirects,
  );
  final String url, method;
  final Map<String, String> headers;
  final Uint8List body;
  final bool followRedirects;
  final int maxRedirects;
}

class _NativeResponse {
  const _NativeResponse(this.status, this.reason, this.headers, this.body);
  final int status;
  final String reason;
  final Map<String, String> headers;
  final Uint8List body;
  bool get isRedirect =>
      const [301, 302, 303, 307, 308].contains(status) &&
      headers.containsKey('location');
}

// Only primitives and byte arrays cross this boundary; no client/FFI object or
// library handle is captured. The DLL is opened lazily inside Windows workers.
Future<_NativeResponse> _inWorker(_NativeRequest data, int cancellation) =>
    Isolate.run(() => _perform(data, cancellation));

const _maxResponseBytes = 64 * 1024 * 1024;
const _sensitive = {
  'authorization',
  'cookie',
  'proxy-authorization',
  'x-goog-visitor-id',
  'host',
};

_NativeResponse _perform(_NativeRequest data, int cancellationAddress) {
  if (!Platform.isWindows) {
    throw http.ClientException('Windows HTTP is only available on Windows');
  }
  final cancelled = Pointer<Uint8>.fromAddress(cancellationAddress);
  final native = _WinHttp();
  var url = Uri.parse(data.url);
  var method = data.method;
  var body = data.body;
  final headers = Map<String, String>.of(data.headers);
  void checkCancelled() {
    if (cancelled.value != 0) throw http.ClientException('Client is closed');
  }

  for (var redirects = 0; ; redirects++) {
    checkCancelled();
    if ((url.scheme != 'https' && url.scheme != 'http') ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty) {
      throw http.ClientException('Unsupported HTTP URL');
    }
    final response = _oneRequest(
      native,
      url,
      method,
      headers,
      body,
      checkCancelled,
    );
    if (!data.followRedirects || !response.isRedirect) return response;
    if (redirects >= data.maxRedirects) {
      throw http.ClientException('Redirect limit exceeded');
    }
    final next = url.resolve(response.headers['location']!);
    // Never follow a secure response down to plaintext automatically.
    if (url.scheme == 'https' && next.scheme != 'https') {
      throw http.ClientException('Insecure HTTP redirect refused');
    }
    if (url.scheme != next.scheme ||
        url.host != next.host ||
        url.port != next.port) {
      headers.removeWhere((key, _) => _sensitive.contains(key.toLowerCase()));
    }
    if (((response.status == 301 || response.status == 302) &&
            method == 'POST') ||
        (response.status == 303 && method != 'HEAD')) {
      method = 'GET';
      body = Uint8List(0);
      headers.removeWhere(
        (key, _) => const {
          'content-type',
          'content-length',
          'transfer-encoding',
        }.contains(key.toLowerCase()),
      );
    }
    url = next;
  }
}

_NativeResponse _oneRequest(
  _WinHttp native,
  Uri url,
  String method,
  Map<String, String> headers,
  Uint8List body,
  void Function() checkCancelled,
) {
  return using((arena) {
    Pointer<Void> session = nullptr;
    Pointer<Void> connection = nullptr;
    Pointer<Void> request = nullptr;
    void check(int success) {
      if (success == 0) {
        // Native error numbers are safe diagnostics; URLs, headers and tokens
        // are deliberately excluded from exception text.
        throw http.ClientException('Windows HTTP error ${native.lastError()}');
      }
      checkCancelled();
    }

    void option(Pointer<Void> handle, int name, int value) {
      final storage = arena<Uint32>()..value = value;
      check(native.setOption(handle, name, storage.cast(), sizeOf<Uint32>()));
    }

    try {
      session = native.open(
        'Singbook'.toNativeUtf16(allocator: arena),
        4,
        nullptr,
        nullptr,
        0,
      ); // WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY.
      if (session == nullptr) check(0);
      check(native.setTimeouts(session, 15000, 15000, 15000, 15000));
      // TLS 1.2/1.3 with normal OS trust and hostname checks. Never set
      // SECURITY_FLAG_IGNORE_* or install a certificate exception callback.
      final protocols = arena<Uint32>()..value = 0x00000800 | 0x00002000;
      if (native.setOption(session, 84, protocols.cast(), sizeOf<Uint32>()) ==
          0) {
        // Older Windows 10 builds do not expose TLS 1.3. Keep TLS 1.2 as the
        // minimum rather than weakening certificate or protocol validation.
        if (native.lastError() != 87) check(0);
        option(session, 84, 0x00000800);
      }
      connection = native.connect(
        session,
        url.host.toNativeUtf16(allocator: arena),
        url.port,
        0,
      );
      if (connection == nullptr) check(0);
      final target =
          '${url.path.isEmpty ? '/' : url.path}'
          '${url.hasQuery ? '?${url.query}' : ''}';
      request = native.openRequest(
        connection,
        method.toNativeUtf16(allocator: arena),
        target.toNativeUtf16(allocator: arena),
        nullptr,
        nullptr,
        nullptr,
        url.scheme == 'https' ? 0x80000000 : 0,
      );
      if (request == nullptr) check(0);
      // Explicitly disable native redirect/cookie/authentication automation.
      // App code owns redirects and credentials, including every intermediate
      // hop. WinHTTP still handles 1xx protocol responses internally.
      option(request, 63, 1 | 2 | 4);
      option(
        request,
        77,
        2,
      ); // Never automatically send Windows login credentials.
      option(request, 91, 64 * 1024);
      option(request, 118, 3); // Bounded streaming gzip/deflate decompression.
      final outgoing = StringBuffer();
      for (final header in headers.entries) {
        if (!RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$").hasMatch(header.key) ||
            header.value.contains(RegExp(r'[\r\n\x00]'))) {
          throw http.ClientException('Invalid HTTP header');
        }
        if (const {
          'content-length',
          'transfer-encoding',
        }.contains(header.key.toLowerCase())) {
          continue; // WinHTTP frames the exact buffered body length.
        }
        outgoing.write('${header.key}: ${header.value}\r\n');
      }
      final headerText = outgoing.toString();
      final Pointer<Uint8> payload = body.isEmpty
          ? nullptr
          : arena<Uint8>(body.length);
      if (body.isNotEmpty) payload.asTypedList(body.length).setAll(0, body);
      check(
        native.sendRequest(
          request,
          headerText.toNativeUtf16(allocator: arena),
          headerText.length,
          payload.cast(),
          body.length,
          body.length,
          0,
        ),
      );
      check(native.receiveResponse(request, nullptr));
      final status = arena<Uint32>();
      final length = arena<Uint32>()..value = sizeOf<Uint32>();
      check(
        native.queryHeaders(
          request,
          19 | 0x20000000,
          nullptr,
          status.cast(),
          length,
          nullptr,
        ),
      );
      final size = arena<Uint32>();
      native.queryHeaders(request, 22, nullptr, nullptr, size, nullptr);
      if (size.value == 0 || size.value > 64 * 1024) {
        throw http.ClientException('Invalid HTTP response headers');
      }
      final raw = arena<Uint16>((size.value + 1) ~/ 2);
      check(
        native.queryHeaders(request, 22, nullptr, raw.cast(), size, nullptr),
      );
      final lines = raw
          .cast<Utf16>()
          .toDartString(length: size.value ~/ 2)
          .split('\r\n');
      final reason = lines.first.split(' ').skip(2).join(' ');
      final responseHeaders = <String, String>{};
      for (final line in lines.skip(1)) {
        final colon = line.indexOf(':');
        if (colon <= 0) continue;
        final key = line.substring(0, colon).trim().toLowerCase();
        final value = line.substring(colon + 1).trim();
        responseHeaders.update(
          key,
          (old) => '$old,$value',
          ifAbsent: () => value,
        );
      }
      final builder = BytesBuilder(copy: false);
      final buffer = arena<Uint8>(64 * 1024);
      final read = arena<Uint32>();
      while (true) {
        checkCancelled();
        check(native.readData(request, buffer.cast(), 64 * 1024, read));
        if (read.value == 0) break;
        if (builder.length + read.value > _maxResponseBytes) {
          throw http.ClientException('HTTP response exceeds 64 MiB');
        }
        builder.add(Uint8List.fromList(buffer.asTypedList(read.value)));
      }
      if (const {
        'gzip',
        'deflate',
      }.contains(responseHeaders['content-encoding'])) {
        responseHeaders.remove('content-encoding');
        responseHeaders.remove('content-length');
      }
      return _NativeResponse(
        status.value,
        reason,
        responseHeaders,
        builder.takeBytes(),
      );
    } finally {
      if (request != nullptr) native.close(request);
      if (connection != nullptr) native.close(connection);
      if (session != nullptr) native.close(session);
    }
  });
}

// All DWORD/BOOL arguments are fixed 32-bit even on x64; handles and the
// WinHttpSendRequest context are pointer-sized. Signatures follow winhttp.h.
class _WinHttp {
  final _dll = DynamicLibrary.open('winhttp.dll');
  late final open = _dll
      .lookupFunction<
        Pointer<Void> Function(
          Pointer<Utf16>,
          Uint32,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Uint32,
        ),
        Pointer<Void> Function(
          Pointer<Utf16>,
          int,
          Pointer<Utf16>,
          Pointer<Utf16>,
          int,
        )
      >('WinHttpOpen');
  late final connect = _dll
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Utf16>, Uint16, Uint32),
        Pointer<Void> Function(Pointer<Void>, Pointer<Utf16>, int, int)
      >('WinHttpConnect');
  late final openRequest = _dll
      .lookupFunction<
        Pointer<Void> Function(
          Pointer<Void>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Pointer<Utf16>>,
          Uint32,
        ),
        Pointer<Void> Function(
          Pointer<Void>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Pointer<Utf16>>,
          int,
        )
      >('WinHttpOpenRequest');
  late final setTimeouts = _dll
      .lookupFunction<
        Int32 Function(Pointer<Void>, Int32, Int32, Int32, Int32),
        int Function(Pointer<Void>, int, int, int, int)
      >('WinHttpSetTimeouts');
  late final setOption = _dll
      .lookupFunction<
        Int32 Function(Pointer<Void>, Uint32, Pointer<Void>, Uint32),
        int Function(Pointer<Void>, int, Pointer<Void>, int)
      >('WinHttpSetOption');
  late final sendRequest = _dll
      .lookupFunction<
        Int32 Function(
          Pointer<Void>,
          Pointer<Utf16>,
          Uint32,
          Pointer<Void>,
          Uint32,
          Uint32,
          UintPtr,
        ),
        int Function(
          Pointer<Void>,
          Pointer<Utf16>,
          int,
          Pointer<Void>,
          int,
          int,
          int,
        )
      >('WinHttpSendRequest');
  late final receiveResponse = _dll
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Void>),
        int Function(Pointer<Void>, Pointer<Void>)
      >('WinHttpReceiveResponse');
  late final queryHeaders = _dll
      .lookupFunction<
        Int32 Function(
          Pointer<Void>,
          Uint32,
          Pointer<Utf16>,
          Pointer<Void>,
          Pointer<Uint32>,
          Pointer<Uint32>,
        ),
        int Function(
          Pointer<Void>,
          int,
          Pointer<Utf16>,
          Pointer<Void>,
          Pointer<Uint32>,
          Pointer<Uint32>,
        )
      >('WinHttpQueryHeaders');
  late final readData = _dll
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Void>, Uint32, Pointer<Uint32>),
        int Function(Pointer<Void>, Pointer<Void>, int, Pointer<Uint32>)
      >('WinHttpReadData');
  late final close = _dll
      .lookupFunction<
        Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('WinHttpCloseHandle');
  late final lastError = DynamicLibrary.open(
    'kernel32.dll',
  ).lookupFunction<Uint32 Function(), int Function()>('GetLastError');
}
