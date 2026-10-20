import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/sync/desktop_oauth_flow.dart';
import 'package:singbook/sync/google_auth.dart';
import 'package:singbook/sync/sync_protocol.dart';
import 'package:singbook/sync/windows_drive_file_access.dart';
import 'package:singbook/sync/windows_google_auth.dart';

const _scope = 'https://www.googleapis.com/auth/drive.file';
const _clientId = 'desktop.apps.googleusercontent.com';

class _Identity implements DriveAuthorization {
  @override
  bool configured = true;
  @override
  bool isConnected = true;
  @override
  String? accountId = 'primary-account';
  @override
  String? accountEmail = 'singer@example.com';
  int connects = 0, restores = 0, disconnects = 0;
  @override
  Future<void> connect() async {
    connects++;
  }

  @override
  Future<bool> restore() async {
    restores++;
    return isConnected;
  }

  @override
  Future<void> disconnect() async {
    disconnects++;
    isConnected = false;
  }

  @override
  Future<String> accessToken() async => 'appdata-token-not-for-picker';
}

class _Vault implements DesktopCredentialStore {
  final values = <String, String>{};
  int reads = 0, writes = 0;
  Completer<void>? readGate, writeGate;
  Completer<void>? readStarted, writeStarted;
  @override
  Future<String?> read(String key) async {
    reads++;
    final saved = values[key];
    if (readStarted?.isCompleted == false) readStarted!.complete();
    await readGate?.future;
    return saved;
  }

  @override
  Future<void> write(String key, String value) async {
    writes++;
    expect(utf8.encode(value).length, lessThanOrEqualTo(2560));
    if (writeStarted?.isCompleted == false) writeStarted!.complete();
    await writeGate?.future;
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

Matcher _error(String code) =>
    isA<SyncException>().having((error) => error.code, 'code', code);

Future<void> _callback(Uri authorization, Map<String, String> result) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse(authorization.queryParameters['redirect_uri']!)
        .replace(
          queryParameters: {
            'state': authorization.queryParameters['state']!,
            ...result,
          },
        );
    final response = await (await client.getUrl(uri)).close();
    expect(response.statusCode, 200);
    await response.drain<void>();
  } finally {
    client.close(force: true);
  }
}

void main() {
  test(
    'malformed and disconnected untrusted callbacks leave consent active',
    () async {
      final guarded = DesktopOAuthFlow(
        openBrowser: (uri) async {
          final redirect = Uri.parse(uri.queryParameters['redirect_uri']!);
          final client = HttpClient();
          try {
            for (final path in ['/wrong', redirect.path]) {
              final malformed = redirect.replace(path: path, query: 'bad=%FF');
              final response = await (await client.getUrl(malformed)).close();
              expect(response.statusCode, 400);
              await response.drain<void>();
            }
            final socket = await Socket.connect(redirect.host, redirect.port);
            socket.write(
              'GET ${redirect.path}?state=wrong HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n',
            );
            await socket.flush();
            socket.destroy();
            await _callback(uri, {
              'code': 'valid',
              'picked_file_ids': 'folder',
            });
          } finally {
            client.close(force: true);
          }
          return true;
        },
      );
      final grant = await guarded.pickDriveFiles(
        clientId: _clientId,
        accountEmail: 'singer@example.com',
        folders: true,
      );
      expect(grant.code, 'valid');
      expect(grant.fileIds, ['folder']);
    },
  );

  late _Identity identity;
  late _Vault vault;
  late MockClient client;
  late DesktopOAuthFlow flow;
  late WindowsDriveFileAccess access;
  late DateTime now;
  late List<Uri> launches;
  late List<String> selectedIds;
  String? pickerError, exchangeError, refreshError, tokenErrorDescription;
  bool malformedTokenErrorDescription = false;
  late String grantedScope, aboutEmail, permissionId, refreshToken;
  late String folderMime;
  late bool folderTrashed;
  int exchanges = 0, renewals = 0;
  Completer<void>? exchangeGate, renewalGate, aboutGate;
  Completer<void>? exchangeStarted, renewalStarted, aboutStarted;

  WindowsDriveFileAccess instance({String clientId = _clientId}) =>
      WindowsDriveFileAccess(
        identity: identity,
        clientId: clientId,
        clientSecret: 'desktop-secret',
        credentials: vault,
        flow: flow,
        client: client,
        clock: () => now,
      );

  setUp(() {
    identity = _Identity();
    vault = _Vault();
    now = DateTime.utc(2026, 10, 19);
    launches = [];
    selectedIds = ['selected-folder'];
    pickerError = exchangeError = refreshError = tokenErrorDescription = null;
    malformedTokenErrorDescription = false;
    grantedScope = _scope;
    aboutEmail = 'singer@example.com';
    permissionId = 'drive-permission-a';
    refreshToken = 'file-refresh-token';
    folderMime = 'application/vnd.google-apps.folder';
    folderTrashed = false;
    exchanges = renewals = 0;
    exchangeGate = renewalGate = aboutGate = null;
    exchangeStarted = renewalStarted = aboutStarted = null;
    flow = DesktopOAuthFlow(
      openBrowser: (uri) async {
        launches.add(uri);
        if (pickerError != null) {
          await _callback(uri, {'error': pickerError!});
        } else {
          await _callback(uri, {
            'code': 'file-code',
            'picked_file_ids': selectedIds.join(','),
          });
        }
        return true;
      },
    );
    client = MockClient((request) async {
      expect(request.url.scheme, 'https');
      if (request.url.path == '/drive/v3/files/selected-folder') {
        expect(request.headers['Authorization'], 'Bearer picked-file-token');
        return http.Response(
          jsonEncode({
            'id': 'selected-folder',
            'mimeType': folderMime,
            'trashed': folderTrashed,
          }),
          200,
        );
      }
      if (request.url.path == '/drive/v3/about') {
        expect(request.url.host, 'www.googleapis.com');
        expect(
          request.url.queryParameters['fields'],
          'user(emailAddress,permissionId)',
        );
        expect(
          request.headers['Authorization'],
          isNot('Bearer appdata-token-not-for-picker'),
        );
        if (aboutStarted?.isCompleted == false) aboutStarted!.complete();
        await aboutGate?.future;
        return http.Response(
          jsonEncode({
            'user': {'emailAddress': aboutEmail, 'permissionId': permissionId},
          }),
          200,
        );
      }
      expect(request.url.host, 'oauth2.googleapis.com');
      expect(request.url.path, '/token');
      final params = Uri.splitQueryString(request.body);
      expect(params['client_id'], _clientId);
      expect(params['client_secret'], 'desktop-secret');
      final refreshing = params['grant_type'] == 'refresh_token';
      if (refreshing) {
        renewals++;
        expect(params['refresh_token'], 'file-refresh-token');
        if (renewalStarted?.isCompleted == false) renewalStarted!.complete();
        await renewalGate?.future;
      } else {
        exchanges++;
        expect(params['grant_type'], 'authorization_code');
        expect(params['code'], 'file-code');
        expect(
          params['redirect_uri'],
          launches.last.queryParameters['redirect_uri'],
        );
        final challenge = base64Url
            .encode(
              sha256.convert(ascii.encode(params['code_verifier']!)).bytes,
            )
            .replaceAll('=', '');
        expect(challenge, launches.last.queryParameters['code_challenge']);
        if (exchangeStarted?.isCompleted == false) exchangeStarted!.complete();
        await exchangeGate?.future;
      }
      final error = refreshing ? refreshError : exchangeError;
      if (error != null) {
        return http.Response(
          jsonEncode({
            'error': error,
            if (tokenErrorDescription != null)
              'error_description': tokenErrorDescription,
            if (malformedTokenErrorDescription) 'error_description': 7,
          }),
          400,
        );
      }
      return http.Response(
        jsonEncode({
          'access_token': refreshing
              ? 'renewed-file-token'
              : 'picked-file-token',
          if (!refreshing) 'refresh_token': refreshToken,
          'expires_in': 3600,
          'token_type': 'Bearer',
          if (!refreshing) 'scope': grantedScope,
        }),
        200,
      );
    });
    access = instance();
  });

  test(
    'folder Picker uses narrow native OAuth, PKCE and same-account grant',
    () async {
      expect(
        await access.pickFolder(accountEmail: identity.accountEmail),
        'selected-folder',
      );
      final query = launches.single.queryParameters;
      expect(query['scope'], _scope);
      expect(query['trigger_onepick'], 'true');
      expect(query['prompt'], 'consent');
      expect(query['include_granted_scopes'], 'false');
      expect(query['allow_folder_selection'], 'true');
      expect(query['mimetypes'], 'application/vnd.google-apps.folder');
      expect(query['allow_multiple'], isNull);
      expect(query['login_hint'], identity.accountEmail);
      expect(await access.fileAuthorization.accessToken(), 'picked-file-token');
      expect(access.fileAuthorization, same(access.fileAuthorization));
      expect(access.fileAuthorization, isA<RefreshableAuthorization>());
      expect(exchanges, 1);
      expect(renewals, 0);
      final saved = jsonDecode(vault.values.values.single) as Map;
      expect(saved, {
        'id': identity.accountId,
        'email': identity.accountEmail,
        'permissionId': permissionId,
        'refreshToken': 'file-refresh-token',
      });
      expect(vault.values.keys.single, startsWith('google_drive_file_'));
      expect(vault.values.values.single, isNot(contains('picked-file-token')));
      expect(vault.values.values.single, isNot(contains('selected-folder')));
    },
  );

  test(
    'file Picker allows multiple IDs using the same file authorization',
    () async {
      selectedIds = ['file-one', 'file-two', 'file-one'];
      expect(await access.pickChordProFiles(), ['file-one', 'file-two']);
      expect(launches.single.queryParameters['allow_multiple'], 'true');
      expect(launches.single.queryParameters['allow_folder_selection'], isNull);
      expect(await access.fileAuthorization.accessToken(), 'picked-file-token');
      expect(identity.connects, 0);
    },
  );

  test('missing file consent never opens a browser in background', () async {
    expect(await access.fileAuthorization.restore(), isTrue);
    expect(identity.restores, 1);
    await expectLater(
      access.fileAuthorization.accessToken(),
      throwsA(_error('drive_file_authorization_required')),
    );
    expect(launches, isEmpty);
    expect(exchanges, 0);
    expect(vault.values, isEmpty);
  });

  test(
    'wrong account or changed permission ID cannot replace a previous grant',
    () async {
      await access.pickFolder();
      final saved = Map<String, String>.from(vault.values);
      aboutEmail = 'different@example.com';
      await expectLater(
        access.pickFolder(),
        throwsA(_error('drive_file_authorization_required')),
      );
      expect(vault.values, saved);
      expect(await access.fileAuthorization.accessToken(), 'picked-file-token');
      aboutEmail = identity.accountEmail!;
      permissionId = 'different-permission';
      now = now.add(const Duration(hours: 2));
      await expectLater(
        access.fileAuthorization.accessToken(),
        throwsA(_error('drive_file_authorization_required')),
      );
      expect(vault.values, saved);
    },
  );

  test(
    'ordinary files and trashed folders cannot replace a usable folder grant',
    () async {
      await access.pickFolder();
      final saved = Map<String, String>.from(vault.values);
      folderMime = 'text/plain';
      await expectLater(
        access.pickFolder(),
        throwsA(_error('folder_not_selected')),
      );
      folderMime = 'application/vnd.google-apps.folder';
      folderTrashed = true;
      await expectLater(
        access.pickFolder(),
        throwsA(_error('folder_not_selected')),
      );
      expect(vault.values, saved);
      expect(await access.fileAuthorization.accessToken(), 'picked-file-token');
    },
  );

  test(
    'requested account mismatch rejects before browser or token exchange',
    () async {
      await expectLater(
        access.pickFolder(accountEmail: 'other@example.com'),
        throwsA(_error('drive_file_authorization_required')),
      );
      expect(launches, isEmpty);
      expect(exchanges, 0);
    },
  );

  test('canceled Picker preserves previous file grant', () async {
    await access.pickFolder();
    final saved = Map<String, String>.from(vault.values);
    pickerError = 'access_denied';
    await expectLater(access.pickFolder(), throwsA(_error('cancelled')));
    expect(vault.values, saved);
    expect(await access.fileAuthorization.accessToken(), 'picked-file-token');
    expect(exchanges, 1);
  });

  test(
    'code-exchange configuration failure preserves previous grant',
    () async {
      await access.pickFolder();
      final saved = Map<String, String>.from(vault.values);
      exchangeError = 'invalid_client';
      await expectLater(access.pickFolder(), throwsA(_error('not_configured')));
      expect(vault.values, saved);
      expect(await access.fileAuthorization.accessToken(), 'picked-file-token');
    },
  );

  test(
    'scope expansion, missing identity and oversized grant fail before storing',
    () async {
      await access.pickFolder();
      final saved = Map<String, String>.from(vault.values);
      grantedScope = '$_scope openid';
      await expectLater(
        access.pickFolder(),
        throwsA(_error('drive_file_authorization_required')),
      );
      grantedScope = _scope;
      permissionId = '';
      await expectLater(
        access.pickFolder(),
        throwsA(_error('drive_file_authorization_required')),
      );
      permissionId = 'drive-permission-a';
      refreshToken = 'x' * 2600;
      await expectLater(
        access.pickFolder(),
        throwsA(_error('drive_file_authorization_required')),
      );
      expect(vault.values, saved);
    },
  );

  test(
    'restart restores only refresh grant and renews without browser',
    () async {
      await access.pickFolder();
      final restarted = instance();
      expect(
        await restarted.fileAuthorization.accessToken(),
        'renewed-file-token',
      );
      expect(renewals, 1);
      expect(launches, hasLength(1));
      expect(vault.values.values.single, isNot(contains('renewed-file-token')));
    },
  );

  test(
    'explicit refresh rejects a cached access token without opening consent',
    () async {
      await access.pickFolder();
      final renewable = access.fileAuthorization as RefreshableAuthorization;
      expect(await renewable.refreshAccessToken(), 'renewed-file-token');
      expect(renewals, 1);
      expect(launches, hasLength(1));
      expect(
        await access.fileAuthorization.accessToken(),
        'renewed-file-token',
      );
      expect(renewals, 1);
    },
  );

  test('desktop client secret is optional for the file token exchange', () async {
    final noSecret = WindowsDriveFileAccess(
      identity: identity,
      clientId: _clientId,
      credentials: vault,
      flow: flow,
      client: MockClient((request) async {
        if (request.url.path == '/drive/v3/files/selected-folder') {
          return http.Response(
            '{"id":"selected-folder","mimeType":"application/vnd.google-apps.folder","trashed":false}',
            200,
          );
        }
        if (request.url.path == '/token') {
          final params = Uri.splitQueryString(request.body);
          expect(params, isNot(contains('client_secret')));
          return http.Response(
            jsonEncode({
              'access_token': 'public-client-token',
              'refresh_token': 'public-client-refresh',
              'scope': _scope,
              'expires_in': 3600,
              'token_type': 'Bearer',
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'user': {
              'emailAddress': identity.accountEmail,
              'permissionId': permissionId,
            },
          }),
          200,
        );
      }),
      clock: () => now,
    );
    expect(await noSecret.pickFolder(), 'selected-folder');
    expect(
      await noSecret.fileAuthorization.accessToken(),
      'public-client-token',
    );
  });

  test('explicit missing client_secret response maps to configuration error',
      () async {
    exchangeError = 'invalid_request';
    tokenErrorDescription = 'Missing required parameter: CLIENT_SECRET';
    await expectLater(
      access.pickFolder(),
      throwsA(_error('not_configured')),
    );
    expect(vault.values, isEmpty);
  });

  test('generic invalid_request remains an exchange error', () async {
    exchangeError = 'invalid_request';
    await expectLater(access.pickFolder(), throwsA(_error('network')));
    expect(vault.values, isEmpty);
  });

  test('unrelated invalid_request description remains an exchange error',
      () async {
    exchangeError = 'invalid_request';
    tokenErrorDescription = 'Authorization code rejected';
    await expectLater(access.pickFolder(), throwsA(_error('network')));
    expect(vault.values, isEmpty);
  });

  test('non-string invalid_request description remains an exchange error',
      () async {
    exchangeError = 'invalid_request';
    malformedTokenErrorDescription = true;
    await expectLater(access.pickFolder(), throwsA(_error('network')));
    expect(vault.values, isEmpty);
  });

  test(
    'concurrent startup calls coalesce vault read and silent renewal',
    () async {
      await access.pickFolder();
      final before = vault.reads;
      vault.readGate = Completer<void>();
      vault.readStarted = Completer<void>();
      final restarted = instance();
      final requests = List.generate(
        6,
        (_) => restarted.fileAuthorization.accessToken(),
      );
      await vault.readStarted!.future;
      vault.readGate!.complete();
      expect(await Future.wait(requests), everyElement('renewed-file-token'));
      expect(vault.reads - before, 1);
      expect(renewals, 1);
      expect(launches, hasLength(1));
    },
  );

  test('invalid_grant clears only the current matching file grant', () async {
    await access.pickFolder();
    vault.values['unrelated-appdata'] = 'preserve';
    now = now.add(const Duration(hours: 2));
    refreshError = 'invalid_grant';
    await expectLater(
      access.fileAuthorization.accessToken(),
      throwsA(_error('drive_file_authorization_required')),
    );
    expect(vault.values, {'unrelated-appdata': 'preserve'});
    refreshError = null;
    await expectLater(
      access.fileAuthorization.accessToken(),
      throwsA(_error('drive_file_authorization_required')),
    );
    expect(renewals, 1);
    expect(launches, hasLength(1));
  });

  for (final error in ['invalid_client', 'temporarily_unavailable']) {
    test('$error on refresh preserves grant for a silent retry', () async {
      await access.pickFolder();
      final saved = Map<String, String>.from(vault.values);
      now = now.add(const Duration(hours: 2));
      refreshError = error;
      await expectLater(
        access.fileAuthorization.accessToken(),
        throwsA(
          _error(error == 'invalid_client' ? 'not_configured' : 'network'),
        ),
      );
      expect(vault.values, saved);
      refreshError = null;
      expect(
        await access.fileAuthorization.accessToken(),
        'renewed-file-token',
      );
      expect(launches, hasLength(1));
    });
  }

  test(
    'sign-out during about verification exposes no IDs or persisted grant',
    () async {
      aboutGate = Completer<void>();
      aboutStarted = Completer<void>();
      final picking = access.pickFolder();
      final failure = expectLater(picking, throwsA(_error('cancelled')));
      await aboutStarted!.future;
      await access.clearAccount();
      identity.isConnected = false;
      aboutGate!.complete();
      await failure;
      expect(vault.values, isEmpty);
      await expectLater(
        access.fileAuthorization.accessToken(),
        throwsA(_error('not_signed_in')),
      );
    },
  );

  test(
    'account change during renewal cannot expose its old token to new account',
    () async {
      await access.pickFolder();
      final saved = Map<String, String>.from(vault.values);
      now = now.add(const Duration(hours: 2));
      renewalGate = Completer<void>();
      renewalStarted = Completer<void>();
      final renewal = access.fileAuthorization.accessToken();
      final failure = expectLater(renewal, throwsA(_error('cancelled')));
      await renewalStarted!.future;
      identity.accountId = 'second-account';
      identity.accountEmail = 'second@example.com';
      renewalGate!.complete();
      await failure;
      await expectLater(
        access.fileAuthorization.accessToken(),
        throwsA(_error('drive_file_authorization_required')),
      );
      expect(vault.values, saved);
      expect(launches, hasLength(1));
    },
  );

  test('clearing during saved-grant restore prevents resurrection', () async {
    await access.pickFolder();
    vault.readGate = Completer<void>();
    vault.readStarted = Completer<void>();
    final restarted = instance();
    final restoring = restarted.fileAuthorization.accessToken();
    final failure = expectLater(restoring, throwsA(_error('cancelled')));
    await vault.readStarted!.future;
    await restarted.clearAccount();
    identity.isConnected = false;
    vault.readGate!.complete();
    await failure;
    expect(vault.values, isEmpty);
    expect(renewals, 0);
  });

  test(
    'cancel during vault replacement rolls back the previous file grant',
    () async {
      await access.pickFolder();
      final saved = Map<String, String>.from(vault.values);
      refreshToken = 'new-file-refresh-token';
      vault.writeGate = Completer<void>();
      vault.writeStarted = Completer<void>();
      final replacing = access.pickFolder();
      final failure = expectLater(replacing, throwsA(_error('cancelled')));
      await vault.writeStarted!.future;
      access.cancel();
      vault.writeGate!.complete();
      await failure;
      expect(vault.values, saved);
      expect(await access.fileAuthorization.accessToken(), 'picked-file-token');
    },
  );

  test(
    'clear during vault replacement deletes after rollback without resurrection',
    () async {
      await access.pickFolder();
      refreshToken = 'new-file-refresh-token';
      vault.writeGate = Completer<void>();
      vault.writeStarted = Completer<void>();
      final replacing = access.pickFolder();
      final failure = expectLater(replacing, throwsA(_error('cancelled')));
      await vault.writeStarted!.future;
      final clearing = access.clearAccount();
      identity.isConnected = false;
      vault.writeGate!.complete();
      await failure;
      await clearing;
      expect(vault.values, isEmpty);
    },
  );

  test(
    'account and desktop-client namespaces cannot restore another grant',
    () async {
      await access.pickFolder();
      final otherClient = instance(
        clientId: 'other.apps.googleusercontent.com',
      );
      await expectLater(
        otherClient.fileAuthorization.accessToken(),
        throwsA(_error('drive_file_authorization_required')),
      );
      identity.accountId = 'another-account';
      await expectLater(
        instance().fileAuthorization.accessToken(),
        throwsA(_error('drive_file_authorization_required')),
      );
      expect(launches, hasLength(1));
      expect(renewals, 0);
    },
  );
}
