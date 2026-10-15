import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verse_mobile/application/app_controller.dart';
import 'package:verse_mobile/application/file_actions.dart';
import 'package:verse_mobile/data/library_repository.dart';
import 'package:verse_mobile/domain/models.dart';
import 'package:verse_mobile/l10n/generated/app_localizations.dart';
import 'package:verse_mobile/providers/core/service.dart';
import 'package:verse_mobile/ui/app_controller_adapter.dart';
import 'package:verse_mobile/ui/theme/verse_theme.dart';
import 'package:verse_mobile/ui/verse_app.dart';

void main() {
  for (final scale in [1.3, 2.0]) {
    testWidgets('setlist row fits 360dp viewport at text scale $scale', (
      tester,
    ) async {
      final fixture = _SetlistFixture();
      final app = fixture.app;
      final controller = AppControllerAdapter(app);
      await controller.openSetlist(fixture.setlist.id);
      await _pumpShell(tester, controller, textScale: scale);

      for (final id in ['entry-one', 'entry-two']) {
        final row = find.byKey(ValueKey(id));
        final rect = tester.getRect(row);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
        final handle = find.descendant(
          of: row,
          matching: find.byType(ReorderableDragStartListener),
        );
        expect(tester.getRect(handle).width, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
      await _dispose(tester, controller, app);
    });
  }

  testWidgets('setlist drag handle reorders repeated song entries', (
    tester,
  ) async {
    final fixture = _SetlistFixture();
    final app = fixture.app;
    final controller = AppControllerAdapter(app);
    await controller.openSetlist(fixture.setlist.id);
    await _pumpShell(tester, controller);

    final firstHandle = find.descendant(
      of: find.byKey(const ValueKey('entry-one')),
      matching: find.byType(ReorderableDragStartListener),
    );
    expect(firstHandle, findsOneWidget);
    final firstCenter = tester.getCenter(firstHandle);
    final lastCenter = tester.getCenter(
      find.byKey(const ValueKey('entry-two')),
    );
    expect(tester.getRect(firstHandle).width, greaterThanOrEqualTo(48));

    final gesture = await tester.startGesture(firstCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump(const Duration(milliseconds: 100));
    final start = firstCenter + const Offset(0, 30);
    final target = lastCenter + const Offset(0, 30);
    const steps = 20;
    for (var step = 1; step <= steps; step++) {
      await gesture.moveTo(
        start + Offset(0, (target.dy - start.dy) * step / steps),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(fixture.repository.savedOrders, hasLength(1));
    expect(
      fixture.repository.setlists.single.entries.map((entry) => entry.id),
      ['entry-two', 'entry-one'],
    );
    expect(tester.takeException(), isNull);
    await _dispose(tester, controller, app);
  });

  testWidgets('setlist accessibility reorder action persists entry order', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final fixture = _SetlistFixture();
    final app = fixture.app;
    final controller = AppControllerAdapter(app);
    await controller.openSetlist(fixture.setlist.id);
    await _pumpShell(tester, controller);

    final row = find.byKey(const ValueKey('entry-one'));
    final node = tester.getSemantics(row);
    final actionIds = node.getSemanticsData().customSemanticsActionIds!;
    final downActionId = actionIds.singleWhere(
      (id) => CustomSemanticsAction.getAction(id)?.label == 'Move down',
    );
    tester.renderObject(row).owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.customAction,
      downActionId,
    );
    await tester.pumpAndSettle();

    expect(fixture.repository.savedOrders, hasLength(1));
    expect(
      fixture.repository.setlists.single.entries.map((entry) => entry.id),
      ['entry-two', 'entry-one'],
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await _dispose(tester, controller, app);
  });
}

Future<void> _pumpShell(
  WidgetTester tester,
  AppControllerAdapter controller, {
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 804);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) =>
            VerseAppShell(controller: controller, files: VerseFileActions()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _dispose(
  WidgetTester tester,
  AppControllerAdapter controller,
  AppController app,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
  app.dispose();
}

class _SetlistFixture {
  _SetlistFixture() {
    final song = SongDocument(
      id: 'song-shared',
      title: 'Shared song',
      artist: 'The Testers',
      body: '[C]Words for everyone',
    );
    repository.songs.add(song);
    repository.setlists.add(setlist);
    app.songs = [song];
    app.setlists = [setlist];
  }

  final repository = _MemoryLibraryRepository();
  final setlist = SetlistDocument(
    id: 'setlist-reorder',
    name: 'Reorder test',
    entries: const [
      SetlistEntry(id: 'entry-one', songId: 'song-shared'),
      SetlistEntry(
        id: 'entry-two',
        songId: 'song-shared',
        overrides: {'key': 'Dm'},
      ),
    ],
  );

  late final AppController app = AppController(
    repository: repository,
    discovery: SourceDiscoveryService(const []),
  );
}

class _MemoryLibraryRepository implements LibraryRepository {
  final List<SongDocument> songs = [];
  final List<SetlistDocument> setlists = [];
  final List<List<String>> savedOrders = [];

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
  Future<void> addActivity(ActivityEntry entry) async {}

  @override
  Future<SetlistDocument?> getSetlist(String id) async =>
      setlists.where((item) => item.id == id).firstOrNull;

  @override
  Future<void> saveSetlist(SetlistDocument setlist) async {
    final index = setlists.indexWhere((item) => item.id == setlist.id);
    if (index < 0) {
      setlists.add(setlist);
    } else {
      setlists[index] = setlist;
    }
    savedOrders.add(setlist.entries.map((entry) => entry.id).toList());
  }

  @override
  Future<bool> saveSetlistIfUnchanged(
    SetlistDocument setlist,
    String? expectedHash,
  ) async {
    await saveSetlist(setlist);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
