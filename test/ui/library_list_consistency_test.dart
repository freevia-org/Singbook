import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';
import 'package:singbook/ui/widgets/verse_components.dart';

// Optional synthetic host screenshots; these are not Android captures.
const _captureOutput = String.fromEnvironment('SEARCH_RESULTS_CAPTURE_DIR');

void main() {
  setUpAll(() async {
    await (FontLoader('sans-serif')
          ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final scenario in [
    (const Size(360, 600), 1.0),
    (const Size(320, 640), 2.0),
  ]) {
    testWidgets('empty Library and creation stay reachable at $scenario', (
      tester,
    ) async {
      final controller = FakeUiController(
        (_) => const VerseUiState(
          homeListMode: HomeListMode.library,
          query: 'Unmatched fixture',
        ),
      );
      addTearDown(controller.dispose);
      await pumpShell(
        tester,
        controller,
        size: scenario.$1,
        textScale: scenario.$2,
      );
      final message = find.text(l10nOf(tester).songsEmptySearch);
      final create = find.byKey(const ValueKey('songs-create-shortcut'));
      expect(message, findsOneWidget);
      final scrollable = find
          .descendant(
            of: find.byKey(const PageStorageKey('songs-library-empty')),
            matching: find.byType(Scrollable),
          )
          .first;
      double scrollOffset() =>
          tester.state<ScrollableState>(scrollable).position.pixels;
      final messageBottom = tester.getRect(message).bottom + scrollOffset();
      // At large text sizes the creation row is beyond the lazy build range.
      await tester.scrollUntilVisible(create, 80, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(create, findsOneWidget);
      expect(
        messageBottom,
        lessThanOrEqualTo(tester.getRect(create).top + scrollOffset()),
      );
      expect(create.hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(message, -80, scrollable: scrollable);
      await tester.ensureVisible(message);
      await tester.pumpAndSettle();
      expect(message.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (_captureOutput.isNotEmpty) {
        await _captureLibrary(tester, scenario.$1, scenario.$2);
      }
      await tester.scrollUntilVisible(create, 80, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(create.hitTestable(), findsOneWidget);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(controller.calls, contains('createSong'));
    });
  }

  for (final count in [4, 9, 10]) {
    testWidgets('alphabet headings start at ten displayed songs: $count', (
      tester,
    ) async {
      final controller = FakeUiController(
        (_) => VerseUiState(
          activeTab: VerseTab.songs,
          homeListMode: HomeListMode.library,
          songs: [
            for (var i = 0; i < count; i++)
              SongCardData(
                id: '$i',
                title: '${String.fromCharCode(65 + i)} song',
              ),
          ],
        ),
      );
      addTearDown(controller.dispose);
      await pumpShell(tester, controller, size: const Size(1100, 900));
      expect(
        find.byType(VerseSectionLabel),
        count < 10 ? findsNothing : findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [360.0, 1100.0]) {
    testWidgets('creation follows songs as a matching row at $width', (
      tester,
    ) async {
      final controller = FakeUiController(
        (_) => const VerseUiState(
          activeTab: VerseTab.songs,
          homeListMode: HomeListMode.library,
          songs: [
            SongCardData(
              id: 'demo',
              title: 'Demo song',
              artist: 'Freevia Demo',
            ),
          ],
        ),
      );
      addTearDown(controller.dispose);
      await pumpShell(tester, controller, size: Size(width, 850));
      final song = find.byType(SongRow);
      final create = find.byKey(const ValueKey('songs-create-shortcut'));
      expect(
        tester.getRect(create).top,
        greaterThanOrEqualTo(tester.getRect(song).bottom),
      );
      expect(
        tester
            .getRect(
              find.descendant(of: create, matching: find.byType(InkWell)),
            )
            .width,
        closeTo(tester.getRect(song).width, 1),
      );
      expect(
        find.descendant(of: create, matching: find.byType(Card)),
        findsOneWidget,
      );
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(controller.calls, contains('createSong'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Songs and Setlists share Favorites and bottom create shortcuts',
    (tester) async {
      var state = const VerseUiState(
        activeTab: VerseTab.songs,
        homeListMode: HomeListMode.library,
        favoritesOnly: true,
        songs: [
          SongCardData(id: 'saved-song', title: 'Saved song', favorite: true),
          SongCardData(id: 'other-song', title: 'Other song'),
        ],
      );
      final controller = FakeUiController((_) => state);
      addTearDown(controller.dispose);

      await pumpShell(tester, controller);
      expect(find.text('Saved song'), findsOneWidget);
      expect(find.text('Other song'), findsNothing);
      expect(
        find.byKey(const ValueKey('favorites-filter-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('songs-create-shortcut')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('songs-create-shortcut')));
      await tester.pumpAndSettle();
      expect(controller.calls, contains('createSong'));

      state = const VerseUiState(
        activeTab: VerseTab.setlists,
        favoritesOnly: true,
        setlists: [
          SetlistCardData(
            id: 'saved-list',
            title: 'Saved rehearsal',
            favorite: true,
          ),
          SetlistCardData(id: 'other-list', title: 'Other rehearsal'),
        ],
      );
      controller.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Saved rehearsal'), findsOneWidget);
      expect(find.text('Other rehearsal'), findsNothing);
      expect(
        find.byKey(const ValueKey('favorites-filter-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('setlists-create-shortcut')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('setlists-create-shortcut')));
      await tester.pumpAndSettle();
      expect(
        controller.calls,
        contains('createSetlist(name: New setlist, songId: null)'),
      );
    },
  );

  testWidgets('Favorites remains visible in online Songs mode', (tester) async {
    final controller = FakeUiController(
      (_) => const VerseUiState(
        activeTab: VerseTab.home,
        homeListMode: HomeListMode.online,
      ),
    );
    addTearDown(controller.dispose);

    await pumpShell(tester, controller);

    expect(
      find.byKey(const ValueKey('favorites-filter-button')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(const ValueKey('favorites-filter-button')),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _captureLibrary(
  WidgetTester tester,
  Size size,
  double textScale,
) async {
  final boundary = tester
      .element(find.byType(Scaffold).first)
      .findAncestorRenderObjectOfType<RenderRepaintBoundary>();
  expect(boundary, isNotNull);
  expect(boundary!.size, size, reason: 'capture the complete app viewport');
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      final name =
          'library-empty-${size.width.toInt()}x${size.height.toInt()}'
          '-scale$textScale';
      final file = File('$_captureOutput/$name.png');
      final sidecar = File('$_captureOutput/$name.json');
      expect(file.existsSync(), isFalse, reason: 'never replace evidence');
      expect(sidecar.existsSync(), isFalse);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      await sidecar.writeAsString(
        jsonEncode({
          'screen': 'library-empty-search',
          'width': image.width,
          'height': image.height,
          'textScale': textScale,
          'locale': 'en',
          'evidenceKind': 'host_widget_screenshot',
          'syntheticContentOnly': true,
          'nativeAndroidVerified': false,
        }),
        flush: true,
      );
    } finally {
      image.dispose();
    }
  });
}
