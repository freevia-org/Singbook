import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/sync/sync_provider.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _captureDirectory = String.fromEnvironment('RELEASE35_SYNC_CAPTURE_DIR');
const _providerKey = ValueKey('account-sync-provider');
const _accountCardKey = ValueKey('settings-account-card');

class _Fixture {
  const _Fixture({
    required this.name,
    required this.platform,
    required this.size,
    required this.brightness,
    required this.locale,
    required this.textScale,
    required this.provider,
    required this.signedIn,
  });

  final String name;
  final TargetPlatform platform;
  final Size size;
  final Brightness brightness;
  final Locale locale;
  final double textScale;
  final SyncProvider provider;
  final bool signedIn;
}

final _fixtures = <_Fixture>[
  const _Fixture(
    name: 'phone_compact_dark_large_google',
    platform: TargetPlatform.iOS,
    size: Size(320, 640),
    brightness: Brightness.dark,
    locale: Locale('en'),
    textScale: 2,
    provider: SyncProvider.googleDrive,
    signedIn: false,
  ),
  const _Fixture(
    name: 'desktop_light_icloud',
    platform: TargetPlatform.macOS,
    size: Size(1280, 900),
    brightness: Brightness.light,
    locale: Locale('en'),
    textScale: 1,
    provider: SyncProvider.iCloud,
    signedIn: true,
  ),
  const _Fixture(
    name: 'desktop_arabic_rtl_dark_google',
    platform: TargetPlatform.macOS,
    size: Size(1280, 900),
    brightness: Brightness.dark,
    locale: Locale('ar'),
    textScale: 1.6,
    provider: SyncProvider.googleDrive,
    signedIn: true,
  ),
  const _Fixture(
    name: 'phone_landscape_bulgarian_icloud',
    platform: TargetPlatform.iOS,
    size: Size(700, 360),
    brightness: Brightness.light,
    locale: Locale('bg'),
    textScale: 1.5,
    provider: SyncProvider.iCloud,
    signedIn: false,
  ),
];

class _AccountController extends FakeUiController {
  _AccountController(this.fixture)
    : super((controller) => (controller as _AccountController)._state);

  final _Fixture fixture;

  VerseUiState get _state => VerseUiState(
    activeTab: VerseTab.settings,
    homeListMode: HomeListMode.recent,
    syncReady: true,
    syncSignedIn: fixture.signedIn,
    syncProvider: fixture.provider,
    appleSyncSupported: true,
    accountName: fixture.signedIn ? 'singer@example.com' : null,
    darkTheme: fixture.brightness == Brightness.dark
        ? AppThemeMode.dark
        : AppThemeMode.light,
    languageCode: fixture.locale.languageCode,
    palette: 'navy',
  );
}

Future<void> _loadCaptureFonts() async {
  final sans = FontLoader('NotoSansSyncCapture')
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  final arabic = FontLoader('SetlistArabic')
    ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([sans.load(), arabic.load(), icons.load()]);
}

Future<void> _capture(WidgetTester tester, _Fixture fixture) async {
  final controller = _AccountController(fixture);
  addTearDown(controller.dispose);
  final boundaryKey = GlobalKey();
  final theme =
      verseTheme(
        brightness: fixture.brightness,
        palette: 'navy',
        fontFamily: _captureDirectory.isNotEmpty
            ? 'NotoSansSyncCapture'
            : 'Roboto',
      ).copyWith(
        textTheme: verseTheme(
          brightness: fixture.brightness,
          palette: 'navy',
          fontFamily: _captureDirectory.isNotEmpty
              ? 'NotoSansSyncCapture'
              : 'Roboto',
        ).textTheme.apply(fontFamilyFallback: const ['SetlistArabic']),
      );

  tester.view.physicalSize = fixture.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final previousPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = fixture.platform;
  try {
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: fixture.locale,
          localizationsDelegates: singbookLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: resolveAppLocale,
          theme: theme,
          darkTheme: theme,
          themeMode: fixture.brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(fixture.textScale)),
            child: child!,
          ),
          home: VerseAppShell(
            controller: controller,
            files: VerseFileActions(),
            syncFocusRequest: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_accountCardKey), findsOneWidget);
    expect(find.byKey(_providerKey), findsOneWidget);
    final l10n = AppLocalizations.of(
      tester.element(find.byKey(_accountCardKey)),
    );
    expect(
      find.text(
        fixture.provider == SyncProvider.iCloud ? 'iCloud' : 'Google Drive',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        fixture.signedIn
            ? fixture.provider == SyncProvider.iCloud
                  ? l10n.accountDisconnectICloud
                  : l10n.accountSignOut
            : fixture.provider == SyncProvider.iCloud
            ? l10n.accountConnectICloud
            : l10n.accountSignInWithGoogle,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    if (_captureDirectory.isEmpty) return;
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$_captureDirectory/${fixture.name}.png');
        expect(file.existsSync(), isFalse, reason: 'preserve prior evidence');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
      } finally {
        image.dispose();
      }
    });
  } finally {
    debugDefaultTargetPlatformOverride = previousPlatform;
  }
}

void main() {
  for (final fixture in _fixtures) {
    testWidgets('release 35 sync visual ${fixture.name}', (tester) async {
      if (_captureDirectory.isNotEmpty) {
        await tester.runAsync(_loadCaptureFonts);
      }
      await _capture(tester, fixture);
    });
  }
}
