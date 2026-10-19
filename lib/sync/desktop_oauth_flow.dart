import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

import 'sync_protocol.dart';

/// A single system-browser authorization with a loopback-only callback.
/// Codes, state and PKCE verifiers never enter application logs or storage.
class DesktopOAuthFlow {
  DesktopOAuthFlow({
    Future<bool> Function(Uri)? openBrowser,
    this.timeout = const Duration(minutes: 3),
  }) : _openBrowser = openBrowser ?? _launchBrowser;

  final Future<bool> Function(Uri) _openBrowser;
  final Duration timeout;
  HttpServer? _server;
  Completer<({String code, String verifier, String redirectUri})>? _pending;

  static Future<bool> _launchBrowser(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static String _random() {
    final random = Random.secure();
    return base64Url
        .encode(List.generate(32, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }

  Future<({String code, String verifier, String redirectUri})> authorize({
    required String clientId,
    required List<String> scopes,
  }) async {
    if (_pending != null) throw const SyncException('sync_busy');
    final pending =
        Completer<({String code, String verifier, String redirectUri})>();
    _pending = pending;
    // Attach an error observer before cancellation can occur during bind/launch.
    final response = pending.future.timeout(
      timeout,
      onTimeout: () => throw const SyncException('cancelled'),
    );
    unawaited(response.then<void>((_) {}, onError: (Object _) {}));
    try {
      final binding = HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(
        binding.then<void>((server) async {
          if (!identical(_pending, pending)) await server.close(force: true);
        }, onError: (Object _) {}),
      );
      final server = await Future.any<HttpServer>([
        binding,
        response.then<HttpServer>(
          (_) => throw const SyncException('cancelled'),
        ),
      ]);
      _server = server;
      final state = _random();
      final verifier = _random();
      final callbackPath = '/oauth/${_random()}';
      final redirectUri = 'http://127.0.0.1:${server.port}$callbackPath';
      server.listen(
        (request) async {
          final query = request.uri.queryParametersAll;
          if (request.method != 'GET' ||
              request.uri.path != callbackPath ||
              query['state']?.length != 1 ||
              query['state']!.single != state ||
              pending.isCompleted) {
            request.response.statusCode = HttpStatus.badRequest;
            await request.response.close();
            return;
          }
          final code = query['code'];
          final error = query['error'];
          request.response.headers.contentType = ContentType.html;
          request.response.headers.set('Cache-Control', 'no-store');
          request.response.headers.set(
            'Content-Security-Policy',
            "default-src 'none'",
          );
          request.response.write(
            '<!doctype html><meta charset="utf-8"><title>Singbook</title><p>Singbook ✓</p>',
          );
          await request.response.close();
          if (pending.isCompleted) return;
          if (error != null) {
            pending.completeError(
              SyncException(
                error.singleOrNull == 'access_denied'
                    ? 'cancelled'
                    : 'sign_in_failed',
              ),
            );
          } else if (code?.length == 1 && code!.single.isNotEmpty) {
            pending.complete((
              code: code.single,
              verifier: verifier,
              redirectUri: redirectUri,
            ));
          } else {
            pending.completeError(const SyncException('sign_in_failed'));
          }
        },
        onError: (Object _) {
          if (!pending.isCompleted) {
            pending.completeError(const SyncException('network'));
          }
        },
      );
      if (pending.isCompleted) return await response;
      final url = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scopes.join(' '),
        'state': state,
        'code_challenge': base64Url
            .encode(sha256.convert(ascii.encode(verifier)).bytes)
            .replaceAll('=', ''),
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent select_account',
      });
      final launchAndResponse = () async {
        if (!await _openBrowser(url))
          throw const SyncException('sign_in_failed');
        return await response;
      }();
      return await Future.any([response, launchAndResponse]);
    } on SyncException {
      rethrow;
    } catch (_) {
      throw const SyncException('sign_in_failed');
    } finally {
      await _server?.close(force: true);
      _server = null;
      _pending = null;
      if (!pending.isCompleted) {
        pending.completeError(const SyncException('cancelled'));
      }
    }
  }

  void cancel() {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const SyncException('cancelled'));
    }
  }
}
