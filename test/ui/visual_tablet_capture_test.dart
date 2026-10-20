import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/library/setlists_screen.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _screens = [
  'library',
  'setlists',
  'reader',
  'editor_keyboard',
  'settings',
  'settings_ukrainian',
  'home_keyboard',
];
const _viewports = <String, Size>{
  'tablet_portrait': Size(800, 1280),
  'tablet_landscape': Size(1280, 800),
  'desktop_wide': Size(1920, 1080),
};

const _requiredFiles = [
  'assets/fonts/NotoSans-Regular.ttf',
  'assets/fonts/NotoSans-Bold.ttf',
  'assets/fonts/NotoSansMono-Regular.ttf',
  'assets/fonts/SingbookBrand-Bold.ttf',
  'assets/fonts/SingbookSerif-Bold.ttf',
  'assets/branding/singbook-mark-foreground.png',
];

/// Captures are written to the gitignored `artifacts/` directory. When a
/// prerequisite file is missing the captures are skipped with this message
/// instead of failing the suite.
String? _skipReason() {
  final missing = [
    for (final path in _requiredFiles)
      if (!File(path).existsSync()) path,
  ];
  return missing.isEmpty ? null : 'skipped: missing ${missing.join(', ')}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final reason = _skipReason();
  // ignore: avoid_print
  if (reason != null) print(reason);
  final skip = reason != null;

  testWidgets('single setlist stays centered without overflow at wide breakpoints', (
    tester,
  ) async {
    final (fixture, controller) = (await tester.runAsync(() async {
      final fixture = _Fixture();
      return (fixture, AppControllerAdapter(fixture.app));
    }))!;
    addTearDown(controller.dispose);
    addTearDown(fixture.app.dispose);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: singbookLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: _captureTheme(brightness: Brightness.light),
        home: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Scaffold(
            body: SetlistsScreen(controller: controller),
          ),
        ),
      ),
    );

    for (final width in [900.0, 991.0, 999.0, 1000.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pump();
      final card = find.byKey(const ValueKey('setlist-card-tablet-setlist'));
      final rect = tester.getRect(card);
      expect(rect.left, greaterThanOrEqualTo(0), reason: 'width $width');
      expect(rect.right, lessThanOrEqualTo(width), reason: 'width $width');
      expect(rect.center.dx, closeTo(width / 2, 0.5), reason: 'width $width');
      expect(tester.takeException(), isNull, reason: 'width $width');
    }

    fixture.app.setlists = [
      ...fixture.app.setlists,
      fixture.app.setlists.single.copyWith(
        id: 'tablet-setlist-second',
        name: 'Songs for the Short Road',
      ),
    ];
    controller.setTab(VerseTab.songs);
    controller.setTab(VerseTab.setlists);
    tester.view.physicalSize = const Size(1000, 800);
    await tester.pump();
    final first = tester.getRect(
      find.byKey(const ValueKey('setlist-card-tablet-setlist')),
    );
    final second = tester.getRect(
      find.byKey(const ValueKey('setlist-card-tablet-setlist-second')),
    );
    expect(second.left - first.right, closeTo(8, 0.5));
    expect(tester.takeException(), isNull);
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  }, skip: skip);

  testWidgets(
    'landscape reader scrolls the final lyric above persistent player controls',
    (tester) async {
      await _loadFonts();
      final output = Directory('artifacts/singbook-layout-captures')
        ..createSync(recursive: true);
      final boundaryKey = GlobalKey();
      // Keep the controller's queued futures in the same real async zone as
      // openSong; a queue created in FakeAsync cannot complete inside runAsync.
      final (fixture, controller) = (await tester.runAsync(() async {
        final fixture = _Fixture();
        return (fixture, AppControllerAdapter(fixture.app));
      }))!;
      final brightness = ValueNotifier(Brightness.light);
      final locale = ValueNotifier(const Locale('en'));
      addTearDown(brightness.dispose);
      addTearDown(locale.dispose);
      addTearDown(controller.dispose);
      addTearDown(fixture.app.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      await tester.runAsync(() => controller.openSong(fixture.song.id));
      await _pumpShell(
        tester,
        controller,
        boundaryKey: boundaryKey,
        brightness: brightness,
        locale: locale,
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/branding/singbook-mark-foreground.png'),
          boundaryKey.currentContext!,
        ),
      );
      await tester.pump();

      final reader = find.byKey(const ValueKey('tablet-reader-content'));
      final scrollable = find.descendant(
        of: reader,
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      final finalLyric = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('For friends who come again'),
        description: 'final original lyric line',
      );
      expect(finalLyric, findsOneWidget);
      final lyricRect = tester.getRect(finalLyric);
      final slider = find.byKey(const ValueKey('player-seek-slider'));
      expect(slider, findsOneWidget);
      final sliderRect = tester.getRect(slider);
      expect(lyricRect.height, greaterThan(0));
      expect(lyricRect.bottom, lessThanOrEqualTo(sliderRect.top));
      final playButton = find.byIcon(Icons.play_arrow_rounded);
      expect(playButton, findsOneWidget);
      _insideViewport(tester, playButton, const Size(1280, 800));
      expect(tester.takeException(), isNull);

      final boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        File(
          '${output.path}${Platform.pathSeparator}tablet_landscape_light_reader_scrolled.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      });
      await tester.pump();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    },
    skip: skip,
  );

  testWidgets('capture populated tablet UI across routes, themes and sizes', (
    tester,
  ) async {
    await _loadFonts();
    final output = Directory('artifacts/singbook-layout-captures')
      ..createSync(recursive: true);
    final boundaryKey = GlobalKey();
    // Match the real async zone used by the controller operations below.
    final (fixture, controller) = (await tester.runAsync(() async {
      final fixture = _Fixture();
      return (fixture, AppControllerAdapter(fixture.app));
    }))!;
    final brightness = ValueNotifier(Brightness.light);
    final locale = ValueNotifier(const Locale('en'));
    addTearDown(brightness.dispose);
    addTearDown(locale.dispose);
    addTearDown(controller.dispose);
    addTearDown(fixture.app.dispose);
    controller.setTab(VerseTab.songs);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = _viewports.values.first;
    await _pumpShell(
      tester,
      controller,
      boundaryKey: boundaryKey,
      brightness: brightness,
      locale: locale,
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/branding/singbook-mark-foreground.png'),
        boundaryKey.currentContext!,
      ),
    );
    await tester.pump();

    for (final viewportEntry in _viewports.entries) {
      for (final themeBrightness in [Brightness.light, Brightness.dark]) {
        for (final screen in _screens) {
          // ignore: avoid_print
          print(
            'responsive capture start ${viewportEntry.key} ${themeBrightness.name} $screen',
          );
          tester.view.physicalSize = viewportEntry.value;
          tester.view.viewInsets = screen.endsWith('_keyboard')
              ? const FakeViewPadding(bottom: 320)
              : FakeViewPadding.zero;
          if (brightness.value != themeBrightness) {
            brightness.value = themeBrightness;
          }
          locale.value = screen == 'settings_ukrainian'
              ? const Locale('uk')
              : const Locale('en');
          FocusManager.instance.primaryFocus?.unfocus();

          switch (screen) {
            case 'library':
              controller.setTab(VerseTab.songs);
            case 'setlists':
              controller.setTab(VerseTab.setlists);
            case 'reader':
              await tester.runAsync(() => controller.openSong(fixture.song.id));
            case 'editor_keyboard':
              await tester.runAsync(() => controller.editSong(fixture.song.id));
            case 'settings':
            case 'settings_ukrainian':
              controller.setTab(VerseTab.settings);
            case 'home_keyboard':
              controller.setTab(VerseTab.home);
              break;
          }
          // ignore: avoid_print
          print(
            'tablet route selected ${viewportEntry.key} ${themeBrightness.name} $screen',
          );

          await tester.pump();
          // Theme interpolation can finish before the descendant buttons'
          // own foreground animations. Wait for both before capturing glyphs.
          // Fields are focused below, after this bounded settle completes.
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 3),
          );
          expect(
            Theme.of(boundaryKey.currentContext!).brightness,
            themeBrightness,
            reason: '${viewportEntry.key} ${themeBrightness.name} $screen',
          );
          // ignore: avoid_print
          print(
            'responsive capture pumped ${viewportEntry.key} ${themeBrightness.name} $screen',
          );

          if (screen.endsWith('_keyboard')) {
            final textFields = find.byType(TextField);
            expect(textFields, findsWidgets, reason: screen);
            await tester.tap(textFields.last, warnIfMissed: false);
            // Focused fields animate their caret continuously, so settle has no
            // stable end state; a bounded frame lets keyboard insets/layout land.
            await tester.pump(const Duration(milliseconds: 250));
          }

          final boundary =
              boundaryKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          expect(
            boundary.size.width,
            viewportEntry.value.width,
            reason: screen,
          );
          expect(
            boundary.size.height,
            lessThanOrEqualTo(viewportEntry.value.height),
          );
          expect(boundary.size.height, greaterThan(300), reason: screen);
          _assertRouteGeometry(tester, screen, viewportEntry.value);
          expect(tester.takeException(), isNull, reason: screen);

          final themeName = themeBrightness == Brightness.light
              ? 'light'
              : 'dark';
          final filename = '${viewportEntry.key}_${themeName}_$screen.png';
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            File('${output.path}${Platform.pathSeparator}$filename')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png!.buffer.asUint8List());
          });
          await tester.pump();
          // ignore: avoid_print
          print(
            'responsive capture saved ${viewportEntry.key} ${themeBrightness.name} $screen',
          );
        }
      }
    }

    expect(
      output.listSync().whereType<File>().where(
        (file) => !file.path.endsWith('reader_scrolled.png'),
      ),
      hasLength(42),
    );
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
    tester.view.resetViewInsets();
  }, skip: skip);
}

Future<void> _loadFonts() async {
  final sansFixture = FontLoader('NotoSansFixture')
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
  final sansAndroid = FontLoader('sans-serif')
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
  final robotoAlias = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
  final mono = FontLoader('monospace')
    ..addFont(rootBundle.load('assets/fonts/NotoSansMono-Regular.ttf'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  final brand = FontLoader('SingbookBrand')
    ..addFont(rootBundle.load('assets/fonts/SingbookBrand-Bold.ttf'));
  final songbookSerif = FontLoader('SingbookSerif')
    ..addFont(rootBundle.load('assets/fonts/SingbookSerif-Bold.ttf'));
  await Future.wait([
    sansFixture.load(),
    sansAndroid.load(),
    robotoAlias.load(),
    mono.load(),
    materialIcons.load(),
    brand.load(),
    songbookSerif.load(),
  ]);
}

Future<void> _pumpShell(
  WidgetTester tester,
  AppControllerAdapter controller, {
  required GlobalKey boundaryKey,
  required ValueNotifier<Brightness> brightness,
  required ValueNotifier<Locale> locale,
}) async {
  await tester.pumpWidget(
    AnimatedBuilder(
      animation: Listenable.merge([brightness, locale]),
      builder: (context, _) => MaterialApp(
        localizationsDelegates: singbookLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale.value,
        theme: _captureTheme(brightness: Brightness.light),
        darkTheme: _captureTheme(brightness: Brightness.dark),
        themeMode: brightness.value == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => RepaintBoundary(
            key: boundaryKey,
            child: VerseAppShell(
              controller: controller,
              files: VerseFileActions(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 250));
}

ThemeData _captureTheme({required Brightness brightness}) {
  final theme = verseTheme(
    brightness: brightness,
    palette: 'navy',
    fontFamily: 'NotoSansFixture',
  );
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'NotoSansFixture'),
  );
}

void _assertRouteGeometry(WidgetTester tester, String screen, Size viewport) {
  switch (screen) {
    case 'library':
      final grid = find.byKey(const PageStorageKey('songs-library-grid'));
      expect(grid, findsOneWidget);
      _insideViewport(tester, grid, viewport);
    case 'setlists':
      final card = find.byKey(const ValueKey('setlist-card-tablet-setlist'));
      expect(card, findsOneWidget);
      _insideViewport(tester, card, viewport);
      if (viewport.width >= 1280) {
        final frame = find.byKey(const ValueKey('tablet-content-frame'));
        final cardRect = tester.getRect(card);
        final frameRect = tester.getRect(frame);
        expect(cardRect.width, greaterThanOrEqualTo(900));
        expect(cardRect.center.dx, closeTo(frameRect.center.dx, 5));
      }
    case 'reader':
      final lyric = find.textContaining('When morning spills across the hills');
      expect(lyric, findsOneWidget);
      _insideViewport(tester, lyric, viewport);
    case 'editor_keyboard':
      final lyricsField = find.byType(TextField).last;
      _insideViewport(tester, lyricsField, viewport);
    case 'settings':
    case 'settings_ukrainian':
      for (final section in [
        'appearance',
        'player',
        'sources',
        'account',
        'about',
      ]) {
        final menu = find.byKey(ValueKey('settings-menu-$section'));
        expect(menu, findsOneWidget);
        _insideViewport(tester, menu, viewport);
      }
    case 'home_keyboard':
      final search = find.byType(TextField).first;
      _insideViewport(tester, search, viewport);
  }
}

void _insideViewport(WidgetTester tester, Finder finder, Size viewport) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(viewport.width));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(viewport.height));
}

class _Fixture {
  final repository = _MemoryRepository();
  late final SongDocument song = SongDocument(
    id: 'tablet-song',
    title: 'Lanterns at Dawn',
    artist: 'Mira Vale',
    metadata: const {'key': 'G', 'tempo': 92},
    body: '''[Verse 1]
[C]When morning spills across the hills
[G]We raise a song in time
[Am]The quiet road remembers us
[F]And every bell can shine

[Chorus]
[C]Carry the light, carry it home
[G]Over the river and stone
[Am]Wherever the turning seasons roam
[F]Carry the light, carry it home

[Verse 2]
[C]The windows wake, the kettle sings
[G]The garden gathers rain
[Am]We leave a place beside the fire
[F]For friends who come again
''',
  );

  late final AppController app = AppController(
    repository: repository,
    discovery: SourceDiscoveryService(const []),
  );

  _Fixture() {
    repository.songs.add(song);
    final titles = [
      'A Window Full of Rain',
      'The Road Between the Pines',
      'Small Fires in the Valley',
      'Every Quiet River',
      'A Map of Open Skies',
      'The Lantern Keeper',
      'Where the Bluebells Grow',
      'A Place at the Table',
    ];
    for (var index = 0; index < titles.length; index++) {
      repository.songs.add(
        song.copyWith(
          id: 'tablet-song-${index + 2}',
          title: titles[index],
          artist: ['Jonah Reed', 'Mira Vale', 'Northbound'][index % 3],
        ),
      );
    }
    repository.setlists.add(
      SetlistDocument(
        id: 'tablet-setlist',
        name: 'Songs for the Long Road',
        notes: 'A small set for an evening together.',
        entries: const [
          SetlistEntry(id: 'tablet-entry', songId: 'tablet-song'),
        ],
      ),
    );
    app.songs = repository.songs;
    app.setlists = repository.setlists;
    app.recent = [
      ActivityEntry(
        id: 'tablet-activity',
        objectId: song.id,
        objectKind: 'song',
        action: 'open',
        occurredAt: DateTime.utc(2026, 10, 14),
      ),
    ];
  }
}

class _MemoryRepository implements LibraryRepository {
  final List<SongDocument> songs = [];
  final List<SetlistDocument> setlists = [];
  final List<ActivityEntry> activity = [];

  @override
  Future<List<SongDocument>> listSongs({
    String query = '',
    bool favoritesOnly = false,
    int? limit,
    int offset = 0,
  }) async => songs;

  @override
  Future<List<SetlistDocument>> listSetlists({
    String query = '',
    bool favoritesOnly = false,
  }) async => setlists;

  @override
  Future<List<ActivityEntry>> listActivity({
    int? limit,
    int offset = 0,
  }) async => [];

  @override
  Future<void> addActivity(ActivityEntry entry) async => activity.add(entry);

  @override
  Future<List<ActivityEntry>> listRecentActivity({
    int limit = 50,
    int offset = 0,
  }) async {
    final ordered = [...activity]
      ..sort((a, b) {
        final time = b.occurredAt.compareTo(a.occurredAt);
        return time == 0 ? b.id.compareTo(a.id) : time;
      });
    final counts = <(String, String), int>{};
    final latest = <(String, String), ActivityEntry>{};
    for (final entry in ordered) {
      final key = (entry.objectKind, entry.objectId);
      latest.putIfAbsent(key, () => entry);
      if (entry.action == 'opened') counts[key] = (counts[key] ?? 0) + 1;
    }
    return latest.entries.skip(offset).take(limit).map((item) {
      final entry = item.value;
      return ActivityEntry(
        id: entry.id,
        objectId: entry.objectId,
        objectKind: entry.objectKind,
        action: entry.action,
        occurredAt: entry.occurredAt,
        openCount: counts[item.key] ?? 0,
      );
    }).toList();
  }

  @override
  Future<void> setSetting(String key, Object? value) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
