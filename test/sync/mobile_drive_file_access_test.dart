import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/google_auth.dart';
import 'package:singbook/sync/google_drive_folder_picker.dart';
import 'package:singbook/sync/mobile_drive_file_access.dart';
import 'package:singbook/sync/platform_drive_auth.dart';
import 'package:singbook/sync/sync_protocol.dart';

class _Identity implements DriveAuthorization {
  @override
  bool configured = true;
  @override
  bool isConnected = true;
  @override
  String? accountId = 'account-a';
  @override
  String? accountEmail = 'singer@example.com';
  int connects = 0, restores = 0, disconnects = 0;
  @override
  Future<void> connect() async {
    connects++;
    isConnected = true;
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
  Future<String> accessToken() =>
      throw StateError('primary token is not a file token');
}

class _Picker extends GoogleDriveFolderPicker {
  final emails = <String?>[];
  int folders = 0, files = 0;
  Completer<void>? gate, started;
  SyncException? failure;
  List<String> ids = ['one', 'two', 'one'];
  Future<void> _wait(String? email) async {
    emails.add(email);
    if (started?.isCompleted == false) started!.complete();
    await gate?.future;
    final error = failure;
    if (error != null) throw error;
  }

  @override
  Future<String> pickFolder({String? accountEmail}) async {
    folders++;
    await _wait(accountEmail);
    return 'folder';
  }

  @override
  Future<List<String>> pickChordProFiles({String? accountEmail}) async {
    files++;
    await _wait(accountEmail);
    return ids;
  }
}

class _FileAuthorization
    implements DriveAuthorization, RefreshableAuthorization {
  _FileAuthorization(this.identity, this.request);
  final DriveAuthorization identity;
  final Future<String> Function(bool, DriveAuthorization) request;
  @override
  bool get configured => identity.configured;
  @override
  bool get isConnected => identity.isConnected;
  @override
  String? get accountId => identity.accountId;
  @override
  String? get accountEmail => identity.accountEmail;
  @override
  Future<String> accessToken() => request(false, identity);
  @override
  Future<String> refreshAccessToken() => request(true, identity);
  @override
  Future<void> connect() => throw StateError('use primary lifecycle');
  @override
  Future<bool> restore() => throw StateError('use primary lifecycle');
  @override
  Future<void> disconnect() => throw StateError('use primary lifecycle');
}

Matcher _error(String code) =>
    isA<SyncException>().having((error) => error.code, 'code', code);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('org.freevia.singbook/rich_clipboard');
  late _Identity identity;
  late _Picker picker;
  late MobileDriveFileAccess access;
  late List<DriveAuthorization> delegates;
  late List<bool> forces;
  Completer<String>? tokenGate;
  Completer<void>? tokenStarted;

  setUp(() {
    identity = _Identity();
    picker = _Picker();
    delegates = [];
    forces = [];
    tokenGate = null;
    tokenStarted = null;
    access = MobileDriveFileAccess(
      identity: identity,
      picker: picker,
      platformOverride: TargetPlatform.android,
      isWebOverride: false,
      authorizationBuilder: (pinned) {
        delegates.add(pinned);
        return _FileAuthorization(pinned, (force, account) async {
          forces.add(force);
          if (tokenStarted?.isCompleted == false) tokenStarted!.complete();
          final gate = tokenGate;
          if (gate != null) return await gate.future;
          return 'file-${account.accountId}-${forces.length}';
        });
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'folder/files pass the primary email and use one stable renewable file facade',
    () async {
      final fileAuth = access.fileAuthorization;
      expect(
        await access.pickFolder(accountEmail: 'SINGER@example.com'),
        'folder',
      );
      expect(await access.pickChordProFiles(), ['one', 'two']);
      expect(picker.emails, [identity.accountEmail, identity.accountEmail]);
      expect(access.fileAuthorization, same(fileAuth));
      expect(fileAuth, isA<RefreshableAuthorization>());
      expect(await fileAuth.accessToken(), 'file-account-a-1');
      expect(delegates.single.accountId, identity.accountId);
      expect(delegates.single.accountEmail, identity.accountEmail);
      expect(identity.connects, 0);
      expect(identity.disconnects, 0);
    },
  );

  test(
    'each completed token request constructs a fresh pinned delegate; force is forwarded',
    () async {
      expect(await access.fileAuthorization.accessToken(), 'file-account-a-1');
      expect(await access.fileAuthorization.accessToken(), 'file-account-a-2');
      expect(
        await (access.fileAuthorization as RefreshableAuthorization)
            .refreshAccessToken(),
        'file-account-a-3',
      );
      expect(delegates, hasLength(3));
      expect(forces, [false, false, true]);
      expect(picker.emails, isEmpty);
    },
  );

  test(
    'real file wrapper is paired with the pinned email and has no retained local cache',
    () async {
      var requests = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'driveFileAccessToken');
            expect(
              (call.arguments as Map)['accountEmail'],
              identity.accountEmail,
            );
            return 'native-file-${++requests}';
          });
      final nativeAdapter = MobileDriveFileAccess(
        identity: identity,
        picker: picker,
        platformOverride: TargetPlatform.android,
        isWebOverride: false,
      );
      expect(await nativeAdapter.pickFolder(), 'folder');
      expect(
        await nativeAdapter.fileAuthorization.accessToken(),
        'native-file-1',
      );
      expect(
        await nativeAdapter.fileAuthorization.accessToken(),
        'native-file-2',
      );
      expect(requests, 2);
    },
  );

  test(
    'concurrent token requests coalesce only within the current account epoch',
    () async {
      tokenGate = Completer<String>();
      tokenStarted = Completer<void>();
      final requests = List.generate(
        6,
        (_) => access.fileAuthorization.accessToken(),
      );
      await tokenStarted!.future;
      expect(delegates, hasLength(1));
      tokenGate!.complete('shared-file-token');
      expect(await Future.wait(requests), everyElement('shared-file-token'));
      expect(delegates, hasLength(1));
    },
  );

  test(
    'canceled Picker preserves primary connection and subsequent file authorization',
    () async {
      expect(await access.fileAuthorization.accessToken(), 'file-account-a-1');
      picker.failure = const SyncException('cancelled');
      await expectLater(access.pickFolder(), throwsA(_error('cancelled')));
      expect(identity.isConnected, isTrue);
      expect(identity.disconnects, 0);
      expect(await access.fileAuthorization.accessToken(), 'file-account-a-2');
    },
  );

  test(
    'expected account mismatch fails before opening Picker or requesting a token',
    () async {
      await expectLater(
        access.pickFolder(accountEmail: 'other@example.com'),
        throwsA(_error('drive_file_authorization_required')),
      );
      expect(picker.emails, isEmpty);
      expect(delegates, isEmpty);
    },
  );

  test('account switch while Picker is open exposes no selected IDs', () async {
    picker.gate = Completer<void>();
    picker.started = Completer<void>();
    final choosing = access.pickChordProFiles();
    final failure = expectLater(choosing, throwsA(_error('cancelled')));
    await picker.started!.future;
    identity.accountId = 'account-b';
    identity.accountEmail = 'second@example.com';
    picker.gate!.complete();
    await failure;
  });

  test(
    'account switch during a token request cannot cache or expose its old token',
    () async {
      tokenGate = Completer<String>();
      tokenStarted = Completer<void>();
      final request = access.fileAuthorization.accessToken();
      final failure = expectLater(request, throwsA(_error('cancelled')));
      await tokenStarted!.future;
      final oldPinned = delegates.single;
      identity.accountId = 'account-b';
      identity.accountEmail = 'second@example.com';
      expect(oldPinned.accountId, 'account-a');
      expect(oldPinned.accountEmail, 'singer@example.com');
      expect(oldPinned.isConnected, isFalse);
      tokenGate!.complete('old-token');
      await failure;
      tokenGate = null;
      expect(await access.fileAuthorization.accessToken(), 'file-account-b-2');
    },
  );

  test(
    'service invalidation cancels a same-account reconnect race without deleting grants',
    () async {
      tokenGate = Completer<String>();
      tokenStarted = Completer<void>();
      final request = access.fileAuthorization.accessToken();
      final failure = expectLater(request, throwsA(_error('cancelled')));
      await tokenStarted!.future;
      invalidatePlatformDriveFileAccess(access);
      identity.isConnected = false;
      identity.isConnected = true;
      tokenGate!.complete('stale-token');
      await failure;
      tokenGate = null;
      expect(await access.fileAuthorization.accessToken(), 'file-account-a-2');
      expect(identity.disconnects, 0);
    },
  );

  test(
    'file facade lifecycle forwards to primary and cancels in-flight requests',
    () async {
      tokenGate = Completer<String>();
      tokenStarted = Completer<void>();
      final request = access.fileAuthorization.accessToken();
      final failure = expectLater(request, throwsA(_error('cancelled')));
      await tokenStarted!.future;
      await access.fileAuthorization.disconnect();
      tokenGate!.complete('stale-token');
      await failure;
      expect(identity.disconnects, 1);
      expect(access.fileAuthorization.isConnected, isFalse);
      await access.fileAuthorization.connect();
      expect(identity.connects, 1);
      expect(await access.fileAuthorization.restore(), isTrue);
      expect(identity.restores, 1);
    },
  );

  test(
    'a busy Picker cannot open a second flow; malformed or empty IDs fail closed',
    () async {
      picker.gate = Completer<void>();
      picker.started = Completer<void>();
      final choosing = access.pickFolder();
      await picker.started!.future;
      await expectLater(
        access.pickChordProFiles(),
        throwsA(_error('sync_in_progress')),
      );
      picker.gate!.complete();
      expect(await choosing, 'folder');
      picker.ids = ['bad/id'];
      await expectLater(
        access.pickChordProFiles(),
        throwsA(_error('folder_picker_failed')),
      );
      picker.ids = [];
      await expectLater(
        access.pickChordProFiles(),
        throwsA(_error('cancelled')),
      );
    },
  );

  test('unconfigured and signed-out primary cannot open a Picker', () async {
    identity.configured = false;
    await expectLater(access.pickFolder(), throwsA(_error('not_configured')));
    identity.configured = true;
    identity.isConnected = false;
    await expectLater(
      access.fileAuthorization.accessToken(),
      throwsA(_error('not_signed_in')),
    );
    await expectLater(access.pickFolder(), throwsA(_error('not_signed_in')));
    expect(picker.emails, isEmpty);
    expect(delegates, isEmpty);
  });

  test(
    'non-Android and web adapters never call a picker, authorization or channel',
    () async {
      for (final platform in [
        TargetPlatform.iOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        final unsupported = MobileDriveFileAccess(
          identity: identity,
          picker: picker,
          platformOverride: platform,
          isWebOverride: false,
          authorizationBuilder: (_) => throw StateError('must not construct'),
        );
        expect(unsupported.fileAuthorization.configured, isFalse);
        await expectLater(
          unsupported.pickFolder(),
          throwsA(_error('folder_picker_unavailable')),
        );
        await expectLater(
          unsupported.fileAuthorization.accessToken(),
          throwsA(_error('folder_picker_unavailable')),
        );
      }
      final web = MobileDriveFileAccess(
        identity: identity,
        picker: picker,
        platformOverride: TargetPlatform.android,
        isWebOverride: true,
      );
      await expectLater(
        web.pickChordProFiles(),
        throwsA(_error('folder_picker_unavailable')),
      );
      expect(picker.emails, isEmpty);
    },
  );
}
