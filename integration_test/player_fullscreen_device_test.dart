import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import '../test/ui/support/fake_controller.dart';

const _skipScreenshots = bool.fromEnvironment('SINGBOOK_SKIP_SCREENSHOTS');
const _hostRotation =
    bool.fromEnvironment('SINGBOOK_HOST_ROTATION') ||
    bool.fromEnvironment('PLAYER40_HOST_ROTATION');

/// Native runner qualification: no platform overrides, fixed viewports, database,
/// or fullscreen/system-channel mocks. Only the chart data is an in-memory fixture.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final captureSession = DateTime.now().microsecondsSinceEpoch.toString();

  testWidgets(
    'native fullscreen transitions preserve the reader and controls',
    (tester) async {
      final mobile = Platform.isAndroid || Platform.isIOS;
      final desktop = Platform.isMacOS || Platform.isWindows;
      expect(
        mobile || desktop,
        isTrue,
        reason:
            'Run on a supported native Android, iOS, macOS or Windows target',
      );
      expect(
        !desktop || _skipScreenshots,
        isTrue,
        reason:
            'Desktop lanes must use SINGBOOK_SKIP_SCREENSHOTS=true; '
            'integration_test screenshot capture is mobile-only',
      );

      final nativeErrors = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message?.contains('Player fullscreen unavailable:') ?? false) {
          nativeErrors.add(message!);
        }
        previousDebugPrint(message, wrapWidth: wrapWidth);
      };
      addTearDown(() => debugPrint = previousDebugPrint);

      final controller = FakeUiController(
        (_) => VerseUiState(
          route: VerseRoute.reader,
          song: const SongCardData(
            id: 'native-fullscreen-original-chart',
            title: 'Original fullscreen regression chart',
            artist: 'Freevia QA',
            durationSeconds: 180,
            hasChords: true,
          ),
          readerKey: 'C',
          playerControlsExpanded: true,
          songLines: [
            for (var i = 0; i < 40; i++)
              LyricLineData(id: 'line-$i', text: 'Original rehearsal line $i'),
          ],
        ),
      );
      addTearDown(controller.dispose);
      if (mobile) addTearDown(() => SystemChrome.setPreferredOrientations([]));
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: singbookLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
          home: VerseAppShell(
            controller: controller,
            files: VerseFileActions(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (Platform.isAndroid && !_skipScreenshots) {
        await binding.convertFlutterSurfaceToImage();
        await tester.pump();
      }

      Future<void> waitFor(
        bool Function() condition,
        String reason, {
        Duration timeout = const Duration(seconds: 15),
      }) async {
        final deadline = DateTime.now().add(timeout);
        while (!condition()) {
          expect(
            nativeErrors,
            isEmpty,
            reason: 'Native fullscreen channel failed',
          );
          expect(DateTime.now().isBefore(deadline), isTrue, reason: reason);
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(
          nativeErrors,
          isEmpty,
          reason: 'Native fullscreen channel failed',
        );
      }

      Future<void> capture(String name) async {
        if (_skipScreenshots) return;
        await tester.pump(const Duration(milliseconds: 250));
        final bytes = await binding.takeScreenshot(name);
        final support = await getApplicationSupportDirectory();
        final directory = Directory(
          '${support.path}/player-fullscreen-captures/$captureSession',
        );
        await directory.create(recursive: true);
        await File(
          '${directory.path}/$name.png',
        ).writeAsBytes(bytes, flush: true);
        binding.reportData?.remove('screenshots');
        debugPrint('PLAYER_FULLSCREEN_NATIVE_CAPTURE:$captureSession:$name');
      }

      Future<void> orientation(bool landscape) async {
        debugPrint(
          'PLAYER_FULLSCREEN_NATIVE_ROTATE:'
          '${landscape ? 'landscape' : 'portrait'}',
        );
        if (!_hostRotation) {
          await SystemChrome.setPreferredOrientations([
            landscape
                ? DeviceOrientation.landscapeLeft
                : DeviceOrientation.portraitUp,
          ]);
        }
        await waitFor(
          () =>
              (tester.view.physicalSize.width >
                  tester.view.physicalSize.height) ==
              landscape,
          'The real native window did not reach the requested orientation',
          timeout: Duration(seconds: _hostRotation ? 120 : 20),
        );
        debugPrint(
          'PLAYER_FULLSCREEN_NATIVE_WINDOW:${tester.view.physicalSize}',
        );
      }

      final enter = find.byKey(const ValueKey('player-enter-fullscreen'));
      final exit = find.byKey(const ValueKey('player-exit-fullscreen'));
      final cog = find.byKey(const ValueKey('player-settings-button'));
      final panel = find.byKey(const ValueKey('player-controls-panel'));
      final lyrics = find.byKey(const ValueKey('tablet-reader-content'));
      final profiles = mobile ? [false, true] : [false];
      for (final landscape in profiles) {
        final profile = desktop
            ? 'desktop'
            : landscape
            ? 'landscape'
            : 'portrait';
        if (mobile) await orientation(landscape);
        expect(enter.hitTestable(), findsOneWidget);
        expect(cog.hitTestable(), findsOneWidget);
        expect(
          find.descendant(of: mobile ? panel : lyrics, matching: cog),
          findsOneWidget,
        );
        final cogRect = tester.getRect(cog);
        expect(cogRect.width, greaterThanOrEqualTo(48));
        expect(cogRect.height, greaterThanOrEqualTo(48));
        if (mobile) {
          expect(tester.getRect(panel).contains(cogRect.center), isTrue);
          expect(
            tester
                .getSize(find.byKey(const ValueKey('player-seek-slider')))
                .height,
            greaterThanOrEqualTo(48),
          );
        }
        await capture('${profile}_normal');
        final cycles = desktop ? 6 : 3;
        for (var cycle = 0; cycle < cycles; cycle++) {
          final normalSize = tester.view.physicalSize;
          await tester.tap(enter);
          await tester.pumpAndSettle();
          expect(nativeErrors, isEmpty, reason: 'Native enter request failed');
          expect(exit.hitTestable(), findsOneWidget);
          expect(cog.hitTestable(), mobile ? findsNothing : findsOneWidget);
          expect(panel.hitTestable(), findsNothing);
          if (desktop) {
            await waitFor(
              () => tester.view.physicalSize != normalSize,
              'Desktop native fullscreen did not change the real window size',
            );
            debugPrint(
              'PLAYER_FULLSCREEN_NATIVE_RESIZE:'
              '$normalSize->${tester.view.physicalSize}',
            );
          }
          if (cycle == cycles - 1) {
            // Mobile system-bar visibility additionally needs host WindowInsets
            // sampling. The original Android qualification records that evidence.
            debugPrint('PLAYER_FULLSCREEN_NATIVE_DWELL:$profile');
            await capture('${profile}_fullscreen');
          }
          for (var sample = 0; sample < 10; sample++) {
            await tester.pump(const Duration(milliseconds: 200));
            expect(
              exit.hitTestable(),
              findsOneWidget,
              reason:
                  '$profile fullscreen changed in cycle $cycle sample $sample',
            );
            expect(enter, findsNothing);
            expect(
              nativeErrors,
              isEmpty,
              reason: 'Native fullscreen channel failed',
            );
            expect(tester.takeException(), isNull);
          }
          await tester.tap(exit);
          await tester.pumpAndSettle();
          expect(nativeErrors, isEmpty, reason: 'Native exit request failed');
          if (desktop) {
            await waitFor(
              () =>
                  (tester.view.physicalSize.width - normalSize.width).abs() <=
                      2 &&
                  (tester.view.physicalSize.height - normalSize.height).abs() <=
                      2,
              'Desktop native window did not restore its original size',
            );
          }
          expect(enter.hitTestable(), findsOneWidget);
          expect(cog.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await capture('${profile}_restored');
        debugPrint(
          'PLAYER_FULLSCREEN_NATIVE_PROFILE_PASS:$profile:$cycles cycles',
        );
      }
      expect(nativeErrors, isEmpty);
      debugPrint(
        'PLAYER_FULLSCREEN_NATIVE_EXECUTED_PASS:${Platform.operatingSystem}',
      );
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
