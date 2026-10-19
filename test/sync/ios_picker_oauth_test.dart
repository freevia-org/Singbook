import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/ios_drive_file_access.dart';
import 'package:singbook/sync/sync_protocol.dart';

const channel = MethodChannel('org.freevia.singbook/oauth_browser');
const clientId = '123-example.apps.googleusercontent.com';
const callback = 'com.googleusercontent.apps.123-example:/oauthredirect';
Matcher error(String code) =>
    isA<SyncException>().having((e) => e.code, 'code', code);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'folder Picker requests only drive.file and binds code to PKCE',
    () async {
      Uri? request;
      messenger.setMockMethodCallHandler(channel, (call) async {
        final args = call.arguments as Map;
        request = Uri.parse(args['url'] as String);
        expect(
          args['callbackScheme'],
          'com.googleusercontent.apps.123-example',
        );
        return Uri.parse(callback)
            .replace(
              queryParameters: {
                'state': request!.queryParameters['state']!,
                'code': 'authorization-code',
                'picked_file_ids': 'folder-123',
              },
            )
            .toString();
      });
      final grant = await IOSPickerOAuthFlow().pickDriveFiles(
        clientId: clientId,
        accountEmail: 'singer@example.com',
        folders: true,
      );
      final q = request!.queryParameters;
      expect(q['scope'], 'https://www.googleapis.com/auth/drive.file');
      expect(q['include_granted_scopes'], 'false');
      expect(q['prompt'], 'consent');
      expect(q['trigger_onepick'], 'true');
      expect(q['allow_folder_selection'], 'true');
      expect(q['mimetypes'], 'application/vnd.google-apps.folder');
      expect(q['redirect_uri'], callback);
      expect(
        q['code_challenge'],
        base64Url
            .encode(sha256.convert(utf8.encode(grant.verifier)).bytes)
            .replaceAll('=', ''),
      );
      expect(grant.fileIds, ['folder-123']);
    },
  );

  for (final bad in [
    'wrong-state',
    'wrong-scheme',
    'duplicate-code',
    'fragment',
  ]) {
    test('rejects callback $bad before token exchange', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        final q = Uri.parse(
          (call.arguments as Map)['url'] as String,
        ).queryParameters;
        var response = Uri.parse(callback)
            .replace(
              queryParameters: {
                'state': bad == 'wrong-state' ? 'attacker' : q['state']!,
                'code': 'code',
                'picked_file_ids': 'file-1',
              },
            )
            .toString();
        if (bad == 'wrong-scheme') {
          response = response.replaceFirst(
            'com.googleusercontent.apps.123-example',
            'other',
          );
        }
        if (bad == 'duplicate-code') response += '&code=other';
        if (bad == 'fragment') response += '#data';
        return response;
      });
      await expectLater(
        IOSPickerOAuthFlow().pickDriveFiles(
          clientId: clientId,
          accountEmail: 'singer@example.com',
        ),
        throwsA(error('drive_file_authorization_required')),
      );
    });
  }

  test(
    'cancellation invalidates late success; concurrent picker rejected',
    () async {
      final completion = Completer<String>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'cancel') return null;
        final q = Uri.parse(
          (call.arguments as Map)['url'] as String,
        ).queryParameters;
        unawaited(
          Future<void>(
            () => completion.complete(
              Uri.parse(callback)
                  .replace(
                    queryParameters: {
                      'state': q['state']!,
                      'code': 'late',
                      'picked_file_ids': 'file',
                    },
                  )
                  .toString(),
            ),
          ),
        );
        return completion.future;
      });
      final flow = IOSPickerOAuthFlow();
      final pending = flow.pickDriveFiles(
        clientId: clientId,
        accountEmail: 'singer@example.com',
      );
      await expectLater(
        flow.pickDriveFiles(
          clientId: clientId,
          accountEmail: 'singer@example.com',
        ),
        throwsA(error('sync_in_progress')),
      );
      flow.cancel();
      await expectLater(pending, throwsA(error('cancelled')));
    },
  );

  test('native cancellation remains cancellation', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'cancelled'),
    );
    await expectLater(
      IOSPickerOAuthFlow().pickDriveFiles(
        clientId: clientId,
        accountEmail: 'singer@example.com',
      ),
      throwsA(error('cancelled')),
    );
  });
}
