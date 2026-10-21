import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  sqfliteFfiInit();
  for (final failSave in [false, true]) {
    testWidgets('song edit from setlist protects draft, failSave=$failSave', (
      tester,
    ) async {
      late LibraryRepository repository;
      late AppController app;
      await tester.runAsync(() async {
        repository = await LibraryRepository.open(
          path: inMemoryDatabasePath,
          factory: databaseFactoryFfi,
        );
        await repository.saveSong(
          SongDocument(
            id: 'song',
            title: 'Shared song',
            artist: 'Fixture',
            body: '[C]Words',
          ),
        );
        await repository.saveSetlist(
          SetlistDocument(
            id: 'set',
            name: 'Reorder test',
            notes: 'Stored private note',
            entries: const [SetlistEntry(id: 'entry-one', songId: 'song')],
          ),
        );
        app = AppController(repository: repository);
        await app.initialize();
      });
      final controller = AppControllerAdapter(app);
      await controller.editSetlist('set');
      await _pumpShell(tester, controller);
      await tester.enterText(find.byType(TextField).first, 'Typed title');
      expect(find.byType(TextField), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      if (failSave) {
        await tester.runAsync(
          () => repository.saveSetlist(
            SetlistDocument(
              id: 'set',
              name: 'External update',
              entries: const [SetlistEntry(id: 'entry-one', songId: 'song')],
            ),
          ),
        );
      }
      final menu = find.descendant(
        of: find.byKey(const ValueKey('entry-one')),
        matching: find.byType(PopupMenuButton<String>),
      );
      await tester.tap(menu);
      await tester.pumpAndSettle();
      final editAction = find.byWidgetPredicate(
        (widget) => widget is PopupMenuItem<String> && widget.value == 'edit',
      );
      expect(editAction, findsOneWidget);
      Navigator.of(tester.element(editAction)).pop();
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        // Invoke the exposed menu action in the real async zone so the FFI
        // repository work is not held by the widget test's fake clock.
        tester.widget<PopupMenuButton<String>>(menu).onSelected!('edit');
        for (var attempt = 0; attempt < 100; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (controller.state.route == VerseRoute.editor ||
              app.setlists.length > 1) {
            return;
          }
        }
        throw StateError('Setlist draft save did not finish');
      });
      await tester.pumpAndSettle();
      if (failSave) {
        expect(controller.state.route, VerseRoute.setlistDetail);
        expect(
          app.setlists.singleWhere((set) => set.id == 'set').name,
          'External update',
        );
        expect(
          app.setlists.singleWhere((set) => set.id != 'set').notes,
          'Stored private note',
        );
        expect(find.text('Typed title'), findsOneWidget);
        expect(find.text('Stored private note'), findsNothing);
      } else {
        expect(controller.state.route, VerseRoute.editor);
        expect(app.setlists.single.name, 'Typed title');
        expect(app.setlists.single.notes, 'Stored private note');
      }
      await _dispose(tester, controller, app);
      await tester.runAsync(repository.close);
    });
  }

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
        expect(tester.widget(row), isA<ReorderableDelayedDragStartListener>());
        final rect = tester.getRect(row);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
        expect(tester.getRect(row).width, greaterThan(0));
      }
      expect(tester.takeException(), isNull);
      await _dispose(tester, controller, app);
    });
  }

  testWidgets('setlist row drag reorders repeated song entries', (
    tester,
  ) async {
    final fixture = _SetlistFixture();
    final app = fixture.app;
    final controller = AppControllerAdapter(app);
    await controller.openSetlist(fixture.setlist.id);
    await _pumpShell(tester, controller);

    final firstHandle = find.byKey(const ValueKey('entry-one'));
    expect(
      tester.widget(firstHandle),
      isA<ReorderableDelayedDragStartListener>(),
    );
    final firstCenter = tester.getCenter(firstHandle);
    expect(tester.getRect(firstHandle).width, greaterThan(48));
    final lastCenter = tester.getCenter(
      find.byKey(const ValueKey('entry-two')),
    );

    final gesture = await tester.startGesture(firstCenter);
    await tester.pump(const Duration(milliseconds: 600));
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
    tester
        .renderObject(row)
        .owner!
        .semanticsOwner!
        .performAction(node.id, SemanticsAction.customAction, downActionId);
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
      localizationsDelegates: singbookLocalizationsDelegates,
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
    String? expectedHash, {
    bool mustNotExist = false,
  }) async =>
      await saveSetlistIfUnchangedWithHash(
        setlist,
        expectedHash,
        mustNotExist: mustNotExist,
      ) !=
      null;

  @override
  Future<String?> saveSetlistIfUnchangedWithHash(
    SetlistDocument setlist,
    String? expectedHash, {
    bool mustNotExist = false,
  }) async {
    // This in-memory fixture models an unconditional successful write; the
    // repository CAS behavior is covered by conditional_writes_test.dart.
    await saveSetlist(setlist);
    return _hashSetlist(setlist);
  }

  String _hashSetlist(SetlistDocument setlist) =>
      sha256.convert(utf8.encode(jsonEncode(setlist.toJson()))).toString();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
