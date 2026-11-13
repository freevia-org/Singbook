import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sync_protocol.dart';

final _clientIdWithDots = RegExp(
  r'^[A-Za-z0-9._-]+\.apps\.googleusercontent\.com$',
);
final _clientIdWithoutDots = RegExp(
  r'^[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$',
);
final _driveIdCharacters = RegExp(r'^[A-Za-z0-9_-]+$');

/// Whether [value] has the shape of a Google OAuth client id. The custom
/// scheme flow derives a URL scheme from the id and passes
/// `allowDots: false`.
bool isGoogleClientId(String value, {bool allowDots = true}) =>
    (allowDots ? _clientIdWithDots : _clientIdWithoutDots).hasMatch(value);

/// Whether [value] is a plausible Drive file or folder id of at most
/// [maxLength] characters. Each caller keeps its own limit.
bool isDriveId(String value, {required int maxLength}) =>
    value.isNotEmpty &&
    value.length <= maxLength &&
    _driveIdCharacters.hasMatch(value);

/// Google's OAuth token endpoint for an installed (public) client, shared by
/// the account grant and the separate Drive file grant.
///
/// The two grants differ in how strictly they read a response; those
/// differences are parameters rather than being unified here.
class GoogleOAuthTokenClient {
  GoogleOAuthTokenClient({
    required this.client,
    required this.clientId,
    required this.invalidGrant,
    required this.clock,
    this.clientSecret = '',
    this.malformedBodyIsNetwork = false,
    this.exactBearerTokenType = true,
    this.timeout = const Duration(seconds: 30),
  });

  final http.Client client;
  final String clientId, clientSecret;

  /// The caller's own exception for `invalid_grant` (a revoked or expired
  /// grant), so each grant can recognise and clean up its own session.
  final SyncException Function() invalidGrant;
  final DateTime Function() clock;

  /// True: a body that is not a JSON object is reported as `network`.
  /// False: decoding it throws, and the caller decides what that means.
  final bool malformedBodyIsNetwork;

  /// True: `token_type` must be exactly `Bearer`. False: any letter case.
  final bool exactBearerTokenType;
  final Duration timeout;

  /// Posts [body] to the token endpoint and returns the decoded response.
  /// Never includes the remote error description in app state or logs.
  Future<Map<String, dynamic>> request(Map<String, String> body) async {
    final response = await client
        .post(
          Uri.https('oauth2.googleapis.com', '/token'),
          body: {
            'client_id': clientId,
            if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
            ...body,
          },
        )
        .timeout(timeout);
    final Map<String, dynamic> value;
    if (malformedBodyIsNetwork) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const SyncException('network');
      }
      value = decoded;
    } else {
      value = jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode != 200) {
      if (value['error'] == 'invalid_grant') throw invalidGrant();
      if (value['error'] == 'invalid_client') {
        throw const SyncException('oauth_client_configuration');
      }
      // An explicit response that diagnoses a missing client_secret is a
      // client configuration error. Desktop OAuth secrets are optional in
      // general; do not infer this from a generic invalid_request.
      final errorDescription = value['error_description'];
      if (value['error'] == 'invalid_request' &&
          errorDescription is String &&
          errorDescription.toLowerCase().contains('client_secret')) {
        throw const SyncException('oauth_client_configuration');
      }
      throw const SyncException('network');
    }
    return value;
  }

  String accessToken(Map<String, dynamic> tokens) {
    final token = tokens['access_token'];
    final type = tokens['token_type'];
    final bearer = exactBearerTokenType
        ? type == 'Bearer'
        : type is String && type.toLowerCase() == 'bearer';
    if (token is! String || token.isEmpty || !bearer) {
      throw const SyncException('network');
    }
    return token;
  }

  /// Expiry of a token response in milliseconds since the epoch.
  int expiry(Map<String, dynamic> tokens) {
    final seconds = tokens['expires_in'];
    if (seconds is! int || seconds <= 0 || seconds > 86400) {
      throw const SyncException('network');
    }
    return clock().add(Duration(seconds: seconds)).millisecondsSinceEpoch;
  }
}
