import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/sync_provider.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

VerseUiState _account({
  bool appleSyncSupported = true,
  bool signedIn = true,
  bool busy = false,
  SyncProvider provider = SyncProvider.iCloud,
  String? driveFolderName,
}) => VerseUiState(
  activeTab: VerseTab.settings,
  homeListMode: HomeListMode.recent,
  syncReady: true,
  syncSignedIn: signedIn,
  syncBusy: busy,
  syncProvider: provider,
  appleSyncSupported: appleSyncSupported,
  accountName: signedIn ? 'singer@example.com' : null,
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

class _ProviderRecordingController extends FakeUiController {
  _ProviderRecordingController(super.build);

  SyncProvider? selectedProvider;

  @override
  Future<void> selectSyncProvider(SyncProvider provider) async {
    selectedProvider = provider;
    calls.add('selectSyncProvider($provider)');
  }
}

Future<_ProviderRecordingController> _pumpAccount(
  WidgetTester tester,
  VerseUiState Function() state,
) async {
  final controller = _ProviderRecordingController((_) => state());
  addTearDown(controller.dispose);
  await pumpShell(tester, controller, syncFocusRequest: 1);
  return controller;
}

void main() {
  testWidgets('Apple provider selector appears only when supported', (
    tester,
  ) async {
    await _withMacOSPlatform(() async {
      await _pumpAccount(tester, () => _account(appleSyncSupported: false));
      expect(find.byKey(const ValueKey('account-sync-provider')), findsNothing);

      await _pumpAccount(tester, () => _account());
      expect(
        find.byKey(const ValueKey('account-sync-provider')),
        findsOneWidget,
      );
    });
  });

  testWidgets('provider selection reaches the controller', (tester) async {
    await _withMacOSPlatform(() async {
      final controller = await _pumpAccount(
        tester,
        () => _account(provider: SyncProvider.googleDrive),
      );
      await tester.tap(find.byKey(const ValueKey('account-sync-provider')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('iCloud').last);
      await tester.pumpAndSettle();

      expect(controller.selectedProvider, SyncProvider.iCloud);
      expect(
        controller.calls,
        contains('selectSyncProvider(SyncProvider.iCloud)'),
      );
    });
  });

  testWidgets(
    'iCloud shows connect and disconnect labels without Google rows',
    (tester) async {
      await _withMacOSPlatform(() async {
        var signedIn = false;
        final controller = await _pumpAccount(
          tester,
          () => _account(signedIn: signedIn),
        );
        expect(find.text('Connect iCloud'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('account-drive-folder')),
          findsNothing,
        );

        signedIn = true;
        controller.refresh();
        await tester.pumpAndSettle();
        expect(find.text('Disconnect iCloud'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('account-drive-folder')),
          findsNothing,
        );
      });
    },
  );

  testWidgets('provider selection is disabled while sync is busy', (
    tester,
  ) async {
    await _withMacOSPlatform(() async {
      var busy = false;
      final controller = await _pumpAccount(tester, () => _account(busy: busy));
      busy = true;
      controller.refresh();
      await tester.pump();
      final selector = tester.widget<DropdownButtonFormField<SyncProvider>>(
        find.byKey(const ValueKey('account-sync-provider')),
      );
      expect(selector.onChanged, isNull);
      expect(controller.selectedProvider, isNull);
    });
  });
}
