import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

VerseUiState _account({String? driveFolderName}) => VerseUiState(
  activeTab: VerseTab.settings,
  homeListMode: HomeListMode.recent,
  syncReady: true,
  syncSignedIn: true,
  accountName: 'singer@example.com',
  syncDriveFolderName: driveFolderName,
);

Future<void> _withMacOSPlatform(Future<void> Function() action) async {
  final previous = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  try {
    await action();
  } finally {
    debugDefaultTargetPlatformOverride = previous;
  }
}

Future<FakeUiController> _pumpMacOSAccount(
  WidgetTester tester, {
  String? driveFolderName,
}) async {
  final controller = FakeUiController(
    (_) => _account(driveFolderName: driveFolderName),
  );
  addTearDown(controller.dispose);
  await pumpShell(tester, controller, syncFocusRequest: 1);
  return controller;
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('configured macOS account can start visible folder selection', (
    tester,
  ) async {
    await _withMacOSPlatform(() async {
      final controller = await _pumpMacOSAccount(tester);
      expect(
        find.byKey(const ValueKey('account-drive-folder')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-import-drive-chordpro')),
        findsNothing,
      );

      await _tapKey(tester, 'account-drive-folder');
      await tester.tap(
        find.byKey(const ValueKey('account-drive-folder-confirm')),
      );
      await tester.pumpAndSettle();
      expect(controller.calls, contains('chooseSyncDriveFolder'));
    });
  });

  testWidgets('selected macOS Drive folder keeps import on the Songs screen', (
    tester,
  ) async {
    await _withMacOSPlatform(() async {
      await _pumpMacOSAccount(tester, driveFolderName: 'Singbook Library');
      expect(find.text('Singbook Library'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-import-drive-chordpro')),
        findsNothing,
      );
    });
  });
}
