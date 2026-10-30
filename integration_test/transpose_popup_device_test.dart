import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/widgets/chord_lyrics_line.dart';

import 'support/transpose_popup_fixtures.dart';
import 'support/ios_screenshots.dart';

const _skipScreenshots = bool.fromEnvironment('SINGBOOK_SKIP_SCREENSHOTS');
// iPad multitasking ignores orientation locks. The host rotates the simulator
// through Device Hub; the test still verifies real native dimensions.
const _hostRotation = bool.fromEnvironment('SINGBOOK_HOST_ROTATION');

typedef _TransposePopupFixture = ({
  String name,
  String? key,
  int? pitch,
  String body,
  List<String> original,
  List<String> shifted,
  String? shiftedKey,
  List<String> down,
});

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'native transpose popup changes and restores original chord charts',
    (tester) async {
      final temporaryDirectory = await getTemporaryDirectory();
      final databasePath = paths.join(
        temporaryDirectory.path,
        'singbook_transpose_popup_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      var repository = await LibraryRepository.open(path: databasePath);
      var app = AppController(repository: repository);
      await app.initialize();
      var controller = AppControllerAdapter(app);
      addTearDown(() async {
        await tester.runAsync(() async {
          await controller.settlePlayerPreferences();
        });
        controller.dispose();
        app.dispose();
        await tester.runAsync(() => repository.close());
        for (final suffix in ['', '-shm', '-wal', '-journal']) {
          final file = File('$databasePath$suffix');
          if (await file.exists()) await file.delete();
        }
      });

      await binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() async {
        await binding.setSurfaceSize(null);
        await SystemChrome.setPreferredOrientations([]);
      });

      await tester.pumpWidget(
        _playerApp(controller, logicalSize: const Size(360, 800)),
      );
      await tester.pumpAndSettle();

      for (var index = 0; index < transposePopupFixtures.length; index++) {
        final fixture = transposePopupFixtures[index];
        final songId = 'transpose-popup-$index';
        await tester.runAsync(() async {
          await app.saveSong(
            SongDocument(
              id: songId,
              title: fixture.name,
              artist: 'Original regression fixture',
              body: fixture.body,
              metadata: {if (fixture.key != null) 'key': fixture.key!},
            ),
          );
          await controller.openSong(songId);
        });
        await tester.pumpAndSettle();

        final dropdown = find.byKey(const ValueKey('pitch-key-dropdown'));
        final play = find.byKey(const ValueKey('start-lyric-scroll'));
        expect(dropdown, findsOneWidget, reason: fixture.name);
        expect(play, findsOneWidget, reason: fixture.name);
        await _expectChordValues(
          tester,
          controller,
          fixture.original,
          reason: fixture.name,
        );

        if (index == 0) {
          _expectDropdownBeforePlay(tester, dropdown, play);
          await _capture(binding, 'transpose_keyless_idle_360x800');
          await _openKeylessPopup(tester, dropdown);
          await _capture(binding, 'transpose_keyless_popup_360x800');
          await _closePopup(tester);
          await tester.runAsync(() => controller.transpose(2));
          await _settleNative(tester, controller, repository);
          await _expectChordValues(
            tester,
            controller,
            fixture.shifted,
            reason: fixture.name,
          );
          expect(controller.state.readerKey, fixture.shiftedKey);
          await _capture(binding, 'transpose_keyless_plus2_360x800');
        } else {
          await _selectTranspose(tester, controller, dropdown, fixture, 2);
          await _settleNative(tester, controller, repository);
          await _expectChordValues(
            tester,
            controller,
            fixture.shifted,
            reason: fixture.name,
          );
          expect(controller.state.readerKey, fixture.shiftedKey);
          if (fixture.pitch != null && index == 2) {
            await _capture(binding, 'transpose_known_plus2_360x800');
          }
        }

        final stored = await tester.runAsync(() => repository.getSong(songId));
        expect(stored!.body, fixture.body, reason: fixture.name);
        expect(
          stored.metadata.containsKey('key'),
          fixture.key != null,
          reason: fixture.name,
        );
        expect(stored.metadata['key'], fixture.key, reason: fixture.name);
        expect(stored.metadata['x_verse_player_transpose'], 2);
        if (index == 0) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            await controller.settlePlayerPreferences();
            controller.dispose();
            app.dispose();
            await repository.close();

            repository = await LibraryRepository.open(path: databasePath);
            app = AppController(repository: repository);
            await app.initialize();
            controller = AppControllerAdapter(app);
            await controller.openSong(songId);
          });
          await tester.pumpWidget(
            _playerApp(controller, logicalSize: const Size(360, 800)),
          );
          await tester.pumpAndSettle();
        } else {
          await tester.runAsync(() => controller.openSong(songId));
          await tester.pumpAndSettle();
        }
        final reopened = await tester.runAsync(
          () => repository.getSong(songId),
        );
        expect(reopened!.body, fixture.body, reason: fixture.name);
        expect(
          reopened.metadata.containsKey('key'),
          fixture.key != null,
          reason: fixture.name,
        );
        expect(reopened.metadata['key'], fixture.key, reason: fixture.name);
        await _expectChordValues(
          tester,
          controller,
          fixture.shifted,
          reason: fixture.name,
        );
        expect(controller.state.readerTranspose, 2, reason: fixture.name);
        expect(controller.state.readerKey, fixture.shiftedKey);

        await _selectTranspose(tester, controller, dropdown, fixture, -1);
        await _settleNative(tester, controller, repository);
        await _expectChordValues(
          tester,
          controller,
          fixture.down,
          reason: fixture.name,
        );
        await _selectTranspose(tester, controller, dropdown, fixture, 0);
        await _settleNative(tester, controller, repository);
        await _expectChordValues(
          tester,
          controller,
          fixture.original,
          reason: fixture.name,
        );
        expect(controller.state.readerTranspose, 0, reason: fixture.name);

        // The pitch popup preserves the separate Settings visibility choice.
        await tester.runAsync(() => controller.setShowChords(false));
        await _settleNative(tester, controller, repository);
        expect(controller.state.showChords, isFalse, reason: fixture.name);
        await _selectTranspose(tester, controller, dropdown, fixture, 0);
        await _settleNative(tester, controller, repository);
        // Choosing a key from the menu leaves lyrics-only mode, including the
        // current key; keyless songs only change the offset.
        expect(
          controller.state.showChords,
          fixture.pitch != null,
          reason: fixture.name,
        );
        await tester.runAsync(() => controller.setShowChords(true));
        await _settleNative(tester, controller, repository);
        expect(controller.state.showChords, isTrue, reason: fixture.name);
        await _expectChordValues(
          tester,
          controller,
          fixture.original,
          reason: fixture.name,
        );
        expect(tester.takeException(), isNull, reason: fixture.name);
      }

      // Check the compact controls and popup in landscape with a large Arabic
      // text scale. This exercises RTL popup positioning and scroll reachability.
      final keyless = transposePopupFixtures.first;
      await tester.runAsync(() => controller.openSong('transpose-popup-0'));
      await binding.setSurfaceSize(const Size(900, 400));
      await tester.pumpWidget(
        _playerApp(
          controller,
          locale: const Locale('ar'),
          textScale: 2,
          logicalSize: const Size(900, 400),
        ),
      );
      await tester.pumpAndSettle();
      final rtlDropdown = find.byKey(const ValueKey('pitch-key-dropdown'));
      final rtlPlay = find.byKey(const ValueKey('start-lyric-scroll'));
      expect(rtlDropdown, findsOneWidget);
      expect(rtlPlay, findsOneWidget);
      await _openKeylessPopup(tester, rtlDropdown);
      final noChords = find.byKey(const ValueKey('transpose-no-chords'));
      await tester.ensureVisible(noChords);
      expect(noChords.hitTestable(), findsOneWidget);
      await _capture(binding, 'transpose_rtl_large_landscape_popup_900x400');
      await _closePopup(tester);
      await tester.runAsync(() => controller.transpose(2));
      await _settleNative(tester, controller, repository);
      await _expectChordValues(
        tester,
        controller,
        keyless.shifted,
        reason: keyless.name,
      );
      await _capture(binding, 'transpose_rtl_large_landscape_plus2_900x400');
      expect(tester.takeException(), isNull);

      // Logical viewport fixtures above do not prove physical rotation. Clear
      // all overrides before checking the real Android view in each orientation.
      await binding.setSurfaceSize(null);
      await tester.pumpWidget(_playerApp(controller));
      for (final landscape in [false, true]) {
        if (_hostRotation) {
          await SystemChrome.setPreferredOrientations([]);
          debugPrint(
            'SINGBOOK_NATIVE_ROTATE:${landscape ? 'landscape' : 'portrait'}',
          );
        } else {
          await SystemChrome.setPreferredOrientations([
            landscape
                ? DeviceOrientation.landscapeLeft
                : DeviceOrientation.portraitUp,
          ]);
        }
        var rotated = false;
        final rotationAttempts = _hostRotation ? 480 : 40;
        for (var attempt = 0; attempt < rotationAttempts; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 250)),
          );
          await tester.pumpAndSettle();
          final size = tester.view.physicalSize;
          if ((landscape && size.width > size.height) ||
              (!landscape && size.height > size.width)) {
            rotated = true;
            break;
          }
        }
        expect(
          rotated,
          isTrue,
          reason: 'Actual native orientation must change',
        );
        final dropdown = find.byKey(const ValueKey('pitch-key-dropdown'));
        final play = find.byKey(const ValueKey('start-lyric-scroll'));
        _expectDropdownBeforePlay(tester, dropdown, play);
        final actualSize = tester.view.physicalSize;
        debugPrint(
          'TRANSPOSE_NATIVE_DIMENSIONS:${landscape ? 'landscape' : 'portrait'}:${actualSize.width}x${actualSize.height}',
        );
        await _capture(
          binding,
          'transpose_actual_${landscape ? 'landscape' : 'portrait'}_plus2',
        );
        await _openKeylessPopup(tester, dropdown);
        await _capture(
          binding,
          'transpose_actual_${landscape ? 'landscape' : 'portrait'}_popup',
        );
        await _closePopup(tester);
        await tester.runAsync(
          () => controller.transpose(-controller.state.readerTranspose),
        );
        await _settleNative(tester, controller, repository);
        await _expectChordValues(
          tester,
          controller,
          keyless.original,
          reason: keyless.name,
        );
        await _selectTranspose(tester, controller, dropdown, keyless, 2);
        await _settleNative(tester, controller, repository);
        await _expectChordValues(
          tester,
          controller,
          keyless.shifted,
          reason: keyless.name,
        );
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

Widget _playerApp(
  AppControllerAdapter controller, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size? logicalSize,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(size: logicalSize, textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: AnimatedBuilder(
    animation: controller,
    builder: (context, _) =>
        Scaffold(body: PlayerScreen(controller: controller)),
  ),
);

Future<void> _selectTranspose(
  WidgetTester tester,
  AppControllerAdapter controller,
  Finder dropdown,
  _TransposePopupFixture fixture,
  int offset,
) async {
  if (fixture.pitch == null) {
    // Without a known key the menu offers only lyrics-only mode and key
    // editing, so the offset is applied through the same controller action.
    await _openKeylessPopup(tester, dropdown);
    await _closePopup(tester);
    await tester.runAsync(
      () => controller.transpose(offset - controller.state.readerTranspose),
    );
    return;
  }
  final itemKey = 'transpose-pitch-${(fixture.pitch! + offset + 12) % 12}';
  await _openPopup(tester, dropdown, itemKey);
  await _selectPopupItem(tester, itemKey);
}

/// Opens the menu of a song whose key is not stored. The menu offers pitch
/// choices only when a key can be inferred from the chords, so only the
/// always-present lyrics-only item is asserted.
Future<void> _openKeylessPopup(WidgetTester tester, Finder dropdown) async {
  await _openPopup(tester, dropdown, 'transpose-no-chords');
  expect(find.byKey(const ValueKey('transpose-no-chords')), findsOneWidget);
}

Future<void> _closePopup(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('transpose-no-chords')), findsNothing);
}

Future<void> _openPopup(
  WidgetTester tester,
  Finder dropdown,
  String visibleItemKey,
) async {
  final anchor = tester.getRect(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final item = find.byKey(ValueKey(visibleItemKey));
  await tester.ensureVisible(item);
  expect(item, findsOneWidget);
  final popup = tester.getRect(item);
  expect(
    popup.left,
    lessThan(anchor.right),
    reason: 'Popup follows its trigger',
  );
  expect(
    popup.right,
    greaterThan(anchor.left),
    reason: 'Popup follows its trigger',
  );
}

Future<void> _selectPopupItem(WidgetTester tester, String itemKey) async {
  final item = find.byKey(ValueKey(itemKey));
  await tester.ensureVisible(item);
  expect(item.hitTestable(), findsOneWidget, reason: itemKey);
  await tester.tap(item);
}

Future<void> _settleNative(
  WidgetTester tester,
  AppControllerAdapter controller,
  LibraryRepository repository,
) async {
  await tester.runAsync(() async {
    await repository.getSetting('app');
    await controller.settlePlayerPreferences();
  });
  await tester.pumpAndSettle();
}

Future<void> _expectChordValues(
  WidgetTester tester,
  AppControllerAdapter controller,
  List<String> expected, {
  required String reason,
}) async {
  final lines = controller.state.songLines
      .where((line) => line.chords.isNotEmpty)
      .toList();
  expect(
    lines.expand((line) => line.chords).map((chord) => chord.symbol).toList(),
    expected,
    reason: reason,
  );
  final lyricList = find.byType(ListView);
  expect(lyricList, findsOneWidget);
  final scrollable = tester.state<ScrollableState>(
    find.descendant(of: lyricList, matching: find.byType(Scrollable)).first,
  );
  final originalOffset = scrollable.position.pixels;
  final seen = <String>{};
  try {
    scrollable.position.jumpTo(0);
    await tester.pumpAndSettle();
    // ListView builds only nearby lines. Check every line after bringing it
    // into view rather than mistaking virtualization for missing chords.
    for (var attempt = 0; attempt < 40; attempt++) {
      for (final widget in tester.widgetList<ChordLyricsLine>(
        find.byType(ChordLyricsLine),
      )) {
        if (widget.chords.isEmpty) continue;
        final line = lines.singleWhere((line) => line.text == widget.text);
        expect(
          widget.chords.map((chord) => chord.symbol).toList(),
          line.chords.map((chord) => chord.symbol).toList(),
          reason: '$reason: ${line.id}',
        );
        expect(
          widget.chords.map((chord) => chord.graphemeOffset).toList(),
          line.chords.map((chord) => chord.graphemeOffset).toList(),
          reason: reason,
        );
        seen.add(line.id);
      }
      if (seen.length == lines.length) break;
      await tester.drag(lyricList, const Offset(0, -120));
      await tester.pumpAndSettle();
    }
    expect(
      seen,
      containsAll(lines.map((line) => line.id)),
      reason:
          '$reason: every chord-bearing lyric line must be rendered and checked',
    );
  } finally {
    scrollable.position.jumpTo(
      originalOffset.clamp(0, scrollable.position.maxScrollExtent),
    );
    await tester.pumpAndSettle();
  }
}

void _expectDropdownBeforePlay(
  WidgetTester tester,
  Finder dropdown,
  Finder play,
) {
  final dropdownRect = tester.getRect(dropdown);
  final playRect = tester.getRect(play);
  expect(dropdownRect.right, lessThanOrEqualTo(playRect.left));
  expect(dropdownRect.center.dy, closeTo(playRect.center.dy, 1));
  final l10n = AppLocalizations.of(tester.element(play));
  expect(find.byTooltip(l10n.readerTransposeSemitones(-1)), findsNothing);
  expect(find.byTooltip(l10n.readerTransposeSemitones(1)), findsNothing);
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  if (_skipScreenshots) return;
  if (await captureIosCheckpoint(name)) return;
  binding.scheduleFrame();
  await binding.endOfFrame;
  debugPrint('SINGBOOK_E2E_CAPTURE:$name');
  await Future<void>.delayed(const Duration(seconds: 2));
}
