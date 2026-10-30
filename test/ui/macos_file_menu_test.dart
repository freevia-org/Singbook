import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, TargetPlatform;
import 'package:flutter/material.dart' show Locale;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _channel = MethodChannel('org.freevia.singbook/file_menu');

Future<void> _fromNative(WidgetTester tester, String method) =>
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      _channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(method)),
      (_) {},
    );

Future<List<Map<Object?, Object?>>> _pumpMacOS(
  WidgetTester tester,
  FakeUiController controller, {
  Locale locale = const Locale('en'),
}) async {
  final updates = <Map<Object?, Object?>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
    call,
  ) async {
    if (call.method == 'update') {
      updates.add(Map<Object?, Object?>.from(call.arguments as Map));
    }
    return null;
  });
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _channel,
      null,
    ),
  );
  await pumpShell(tester, controller, locale: locale);
  return updates;
}

Future<void> _onMacOS(Future<void> Function() body) async {
  final previous = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = previous;
  }
}

void main() {
  testWidgets('library enables New and Import, not Save/Export/Print', (
    tester,
  ) async {
    await _onMacOS(() async {
      final controller = FakeUiController(
        (_) => VerseUiState(
          activeTab: VerseTab.home,
          homeListMode: HomeListMode.library,
        ),
      );
      addTearDown(controller.dispose);
      final updates = await _pumpMacOS(tester, controller);
      final menu = updates.last;
      expect(menu['title'], 'File');
      expect(menu['newSong'], 'New Song…');
      expect(menu['canCreate'], isTrue);
      expect(menu['canSave'], isFalse);
      expect(menu['canExport'], isFalse);

      await _fromNative(tester, 'newSong');
      await _fromNative(tester, 'import');
      await _fromNative(tester, 'print');
      expect(controller.calls, containsAllInOrder(['createSong']));
      expect(controller.calls, contains('importChordPro'));
      expect(controller.calls, isNot(contains('printSong')));
    });
  });

  testWidgets('reader exports and prints the open song', (tester) async {
    await _onMacOS(() async {
      final controller = FakeUiController(
        (_) => VerseUiState(
          route: VerseRoute.reader,
          song: const SongCardData(id: 'song-1', title: 'Lantern'),
        ),
      );
      addTearDown(controller.dispose);
      final updates = await _pumpMacOS(tester, controller);
      expect(updates.last['canExport'], isTrue);
      expect(updates.last['canSave'], isFalse);
      expect(updates.last['exportChordPro'], 'Export · ChordPro…');

      await _fromNative(tester, 'exportChordPro');
      await _fromNative(tester, 'exportPdf');
      await _fromNative(tester, 'print');
      expect(
        controller.calls,
        containsAll(['shareSong', 'shareSongPdf', 'printSong']),
      );
    });
  });

  testWidgets('editor enables Save only and ignores create/import', (
    tester,
  ) async {
    await _onMacOS(() async {
      final controller = FakeUiController(
        (_) => VerseUiState(route: VerseRoute.editor, editing: true),
      );
      addTearDown(controller.dispose);
      final updates = await _pumpMacOS(tester, controller);
      expect(updates.last['canSave'], isTrue);
      expect(updates.last['canCreate'], isFalse);
      expect(updates.last['canExport'], isFalse);
      await _fromNative(tester, 'newSong');
      await _fromNative(tester, 'import');
      expect(controller.calls, isNot(contains('createSong')));
      expect(controller.calls, isNot(contains('importChordPro')));
    });
  });

  testWidgets('labels are localized', (tester) async {
    await _onMacOS(() async {
      final controller = FakeUiController(
        (_) => VerseUiState(
          activeTab: VerseTab.home,
          homeListMode: HomeListMode.library,
        ),
      );
      addTearDown(controller.dispose);
      final updates = await _pumpMacOS(
        tester,
        controller,
        locale: const Locale('de'),
      );
      expect(updates.last['title'], 'Datei');
      expect(updates.last['newSong'], 'Neues Lied…');
    });
  });

  testWidgets('other platforms send nothing to the native menu', (
    tester,
  ) async {
    final controller = FakeUiController(
      (_) => VerseUiState(
        activeTab: VerseTab.home,
        homeListMode: HomeListMode.library,
      ),
    );
    addTearDown(controller.dispose);
    final updates = await _pumpMacOS(tester, controller);
    expect(updates, isEmpty);
  });
}
