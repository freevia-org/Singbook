import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final song = SongDocument(
    id: 'a',
    title: 'Shared',
    artist: '',
    body: '[C]words',
  );

  group('temporary share copies', () {
    late Directory temp;
    setUp(() async {
      temp = await Directory.systemTemp.createTemp('singbook-share-review-');
    });
    tearDown(() async => temp.delete(recursive: true));
    int copies() {
      final root = Directory('${temp.path}/verse-share');
      return root.existsSync()
          ? root.listSync().whereType<Directory>().length
          : 0;
    }

    VerseFileActions actions(
      TargetPlatform platform,
      ShareResultStatus status, {
      Duration retention = const Duration(hours: 1),
    }) => VerseFileActions(
      temporaryDirectory: () async => temp,
      platform: platform,
      shareRetention: retention,
      shareFiles: (params) async {
        expect(File(params.files!.single.path).existsSync(), isTrue);
        return ShareResult('target', status);
      },
    );

    test(
      'Android keeps the copy after a target was chosen: it may still be read',
      () async {
        final android = actions(
          TargetPlatform.android,
          ShareResultStatus.success,
        );
        await android.shareSong(song, origin: const Rect.fromLTWH(0, 0, 1, 1));
        expect(copies(), 1);
      },
    );

    test('Android removes the copy when the chooser was dismissed', () async {
      await actions(
        TargetPlatform.android,
        ShareResultStatus.dismissed,
      ).shareSong(song);
      expect(copies(), 0);
    });

    test('a kept Android copy is swept by the next share or app start', () async {
      final android = actions(
        TargetPlatform.android,
        ShareResultStatus.success,
        retention: Duration.zero,
      );
      await android.shareSong(song);
      expect(copies(), 1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await android.cleanUpShareCache();
      expect(copies(), 0);
    });

    test('iOS still removes the copy once the share sheet has finished', () async {
      for (final status in [
        ShareResultStatus.success,
        ShareResultStatus.dismissed,
      ]) {
        await actions(TargetPlatform.iOS, status).shareSong(song);
        expect(copies(), 0);
      }
      await actions(
        TargetPlatform.iOS,
        ShareResultStatus.unavailable,
      ).shareSong(song);
      expect(copies(), 1);
    });
  });

  group('rich clipboard', () {
    const channel = MethodChannel('org.freevia.singbook/rich_clipboard');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<String> plainCopies;

    setUp(() {
      plainCopies = [];
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          plainCopies.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
    });
    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('a platform failure falls back to plain text', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'clipboard_failed'),
      );
      await VerseFileActions().copySong(song);
      expect(plainCopies, [songPlainText(song)]);
    });

    test('a missing plugin still falls back to plain text', () async {
      messenger.setMockMethodCallHandler(channel, null);
      await VerseFileActions().copySong(song);
      expect(plainCopies, [songPlainText(song)]);
    });

    test('a working rich clipboard is used on its own', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      await VerseFileActions().copySong(song);
      expect(calls.single.method, 'setHtmlText');
      expect((calls.single.arguments as Map)['html'], songRichHtml(song));
      expect(plainCopies, isEmpty);
    });
  });
}
