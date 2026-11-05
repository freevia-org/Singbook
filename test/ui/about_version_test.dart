import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/app_version.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _packageInfoChannel = MethodChannel(
  'dev.fluttercommunity.plus/package_info',
);

void main() {
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_packageInfoChannel, null);
  });

  testWidgets(
    'About falls back while loading and on failure, then shows installed version',
    (tester) async {
      final failedPackageInfo = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_packageInfoChannel, (call) async {
            expect(call.method, 'getAll');
            return failedPackageInfo.future;
          });

      final controller = FakeUiController(
        (_) => const VerseUiState(activeTab: VerseTab.settings),
      );
      addTearDown(controller.dispose);
      await pumpShell(tester, controller);
      await _openAbout(tester);

      final l10n = l10nOf(tester);
      final versionText = find.byKey(
        const ValueKey('about-installed-version'),
      );
      expect(
        tester.widget<Text>(versionText).data,
        l10n.appVersion(singbookVersion),
      );

      failedPackageInfo.completeError(
        PlatformException(code: 'unavailable'),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(versionText).data,
        l10n.appVersion(singbookVersion),
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      final loadedPackageInfo = Completer<Object?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_packageInfoChannel, (call) async {
            expect(call.method, 'getAll');
            return loadedPackageInfo.future;
          });
      await _openAbout(tester);
      expect(
        tester.widget<Text>(versionText).data,
        l10n.appVersion(singbookVersion),
      );

      loadedPackageInfo.complete({
        'appName': 'Singbook',
        'packageName': 'org.freevia.singbook',
        'version': '9.8.7',
        'buildNumber': '456',
        'buildSignature': 'test-signature',
        'installerStore': null,
        'installTime': null,
        'updateTime': null,
      });
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(versionText).data,
        l10n.appVersion('9.8.7+456'),
      );
    },
  );
}

Future<void> _openAbout(WidgetTester tester) async {
  final aboutTile = find.byKey(const ValueKey('settings-menu-about'));
  await tester.scrollUntilVisible(
    aboutTile,
    200,
    scrollable: find
        .descendant(
          of: find.byType(Scaffold),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(aboutTile);
  await tester.pumpAndSettle();
}
