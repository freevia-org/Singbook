import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _reference = SongCandidate(
  providerId: 'genius',
  id: 'original',
  title: 'Signal Song',
  artist: 'The Signals',
);
const _savedSource = SourceResult(
  candidate: SongCandidate(
    providerId: 'lrclib',
    id: 'recording',
    title: 'Signal Song',
    artist: 'The Signals',
    durationSeconds: 247,
  ),
  body: 'Our original opening line\nOur original second line',
  matchKind: MatchKind.sameSong,
);

void main() {
  sqfliteFfiInit();
  late LibraryRepository repository;
  late AppController app;
  late AppControllerAdapter ui;

  setUp(() async {
    repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    app = AppController(repository: repository);
    await app.initialize();
    ui = AppControllerAdapter(app);
  });
  tearDown(() async {
    ui.dispose();
    app.dispose();
    await repository.close();
  });

  Future<SongDocument> saveSource() async {
    app.selection = _reference;
    app.results = [_savedSource];
    app.combined = combineSources(_reference, app.results);
    return app.saveResult(source: _savedSource);
  }

  test('Recent groups visits, counts opens, and survives restart', () async {
    await app.saveSong(
      SongDocument(id: 'a', title: 'Alpha', artist: 'Us', body: 'Our words'),
    );
    await app.saveSong(
      SongDocument(id: 'b', title: 'Beta', artist: 'Us', body: 'More words'),
    );
    await ui.openSong('a');
    await ui.openSong('a');
    await ui.openSong('b');
    await ui.openSong('a');
    expect(ui.state.recent.map((item) => item.id), ['a', 'b']);
    expect(ui.state.recent.first.playCount, 3);
    expect((await repository.listActivity()).length, 4);
    ui.dispose();
    app.dispose();
    app = AppController(repository: repository);
    await app.initialize();
    ui = AppControllerAdapter(app);
    expect(ui.state.recent.map((item) => item.id), ['a', 'b']);
    expect(ui.state.recent.first.playCount, 3);
  });

  test('a ready version opens while discovery is still running', () async {
    ui.dispose();
    app.dispose();
    final provider = _DeferredProvider();
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([provider]),
    );
    await app.initialize();
    ui = AppControllerAdapter(app);

    final discovery = app.selectCandidate(
      _reference,
      cachedResults: [_savedSource],
    );
    expect(app.discovering, isTrue);
    app.selection = _reference;
    ui.selectVersion(_savedSource.id);
    await ui.saveSelectedVersion();
    expect(ui.state.route, VerseRoute.reader);
    expect(ui.state.song?.durationSeconds, 247);
    expect(app.discovering, isTrue);
    expect(app.songs.single.body, _savedSource.body);
    provider.ready.complete(
      const SourceResult(
        candidate: _reference,
        body: 'Another available version',
        matchKind: MatchKind.sameRecording,
      ),
    );
    await discovery;
  });

  test(
    'a pending chart remains selectable and saves with pending provenance',
    () async {
      const pendingChart = SourceResult(
        candidate: _reference,
        body: '[C]A provisional chart',
        matchKind: MatchKind.sameRecording,
        matchReason: 'same_recording',
      );
      ui.setHomeListMode(HomeListMode.online);
      ui.setQuery('Signal Song The Signals');
      await ui.submitSearch();
      app.suggestions = [_reference];
      await ui.selectReference(
        const SearchReferenceData(
          id: 'genius:original',
          title: 'Signal Song',
          artist: 'The Signals',
        ),
      );
      app.selection = _reference;
      app.results = [pendingChart];
      app.combined = combineSources(_reference, app.results);
      app.discovering = true;
      app.notifyListeners();
      expect(app.isSourceReady(pendingChart), isFalse);
      final pending = ui.state.comparison!.alternatives.single;
      expect(pending.matchSummary, 'pending');
      expect(pending.canSave, isTrue);
      ui.selectVersion(pendingChart.id);
      expect(ui.state.comparison?.selected?.matchSummary, 'pending');
      await ui.saveSelectedVersion();
      expect(ui.state.route, VerseRoute.reader);
      expect(app.songs.single.body, pendingChart.body);
      expect(app.songs.single.extra['savedSourceId'], pendingChart.id);
      expect(app.songs.single.sources.single.body, pendingChart.body);
    },
  );

  test(
    'an already saved chart can open during fresh chart validation',
    () async {
      const savedChart = SourceResult(
        candidate: _reference,
        body: '[C]Our saved chart',
        matchKind: MatchKind.sameSong,
      );
      app.selection = _reference;
      app.results = [savedChart];
      final saved = await app.saveResult(source: savedChart);
      expect(app.savedResultId(source: savedChart), saved.id);
      ui.setHomeListMode(HomeListMode.online);
      ui.setQuery('Signal Song The Signals');
      await ui.submitSearch();
      app.suggestions = [_reference];
      await ui.selectReference(
        const SearchReferenceData(
          id: 'genius:original',
          title: 'Signal Song',
          artist: 'The Signals',
        ),
      );
      app.discovering = true;
      app.results = [
        const SourceResult(
          candidate: _reference,
          body: '[C]An unvalidated refresh',
          matchKind: MatchKind.sameRecording,
          matchReason: 'same_recording',
        ),
      ];
      app.combined = combineSources(_reference, app.results);
      app.notifyListeners();
      ui.selectVersion(savedChart.id);
      expect(ui.state.comparison?.selected?.savedSongId, saved.id);
      await ui.saveSelectedVersion();
      expect(ui.state.song?.id, saved.id);
      expect(app.songs, hasLength(1));
      expect(app.songs.single.body, savedChart.body);
      expect(app.songs.single.sources.single.body, savedChart.body);
    },
  );

  test(
    'restoring source history deduplicates versions by source identity',
    () async {
      ui.dispose();
      app.dispose();
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([]),
      );
      await app.initialize();
      ui = AppControllerAdapter(app);
      await app.selectCandidate(
        _reference,
        cachedResults: [
          _savedSource,
          SourceResult(
            candidate: _savedSource.candidate,
            body: 'A newer source snapshot',
            matchKind: MatchKind.sameSong,
          ),
        ],
      );
      expect(app.results, hasLength(1));
      expect(app.results.single.body, 'A newer source snapshot');
    },
  );

  test(
    'Recent serializes paging, new visits and clearing without missing groups',
    () async {
      await repository.importCollection([
        for (var index = 0; index < 85; index++)
          SongDocument(
            id: 'song-$index',
            title: 'Song $index',
            artist: 'Us',
            body: 'Our words',
          ),
      ], []);
      for (var index = 0; index < 85; index++) {
        await repository.addActivity(
          ActivityEntry(
            id: 'visit-$index',
            objectId: 'song-$index',
            objectKind: 'song',
            action: 'opened',
            occurredAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: index)),
          ),
        );
      }
      ui.dispose();
      app.dispose();
      app = AppController(repository: repository);
      await app.initialize();
      ui = AppControllerAdapter(app);
      expect(app.recent, hasLength(40));
      await Future.wait([
        app.loadMoreRecent(),
        app.recordUse('song', 'song-0'),
      ]);
      expect(app.recent.first.objectId, 'song-0');
      await app.loadMoreRecent();
      expect(app.recent.map((entry) => entry.objectId).toSet(), hasLength(85));
      expect(app.recent, hasLength(85));
      expect(app.recent.first.openCount, 2);
      expect(app.hasMoreRecent, isFalse);
      app.hasMoreRecent = true;
      await Future.wait([app.loadMoreRecent(), app.clearHistory()]);
      expect(app.recent, isEmpty);
      expect(await repository.listActivity(), isEmpty);
      await app.recordUse('song', 'song-0');
      expect(app.recent.single.openCount, 1);
    },
  );

  test(
    'cold reopen restores comparison and keeps saved choice during refresh',
    () async {
      final saved = await saveSource();
      ui.dispose();
      app.dispose();
      final provider = _DeferredProvider();
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([provider]),
      );
      await app.initialize();
      ui = AppControllerAdapter(app);
      await ui.openSong(saved.id);
      expect(app.selection, isNull);
      expect(ui.state.readerCanCompareVersions, isTrue);
      final refresh = ui.compareCurrentSongVersions();
      expect(ui.state.route, VerseRoute.main);
      expect(ui.state.comparison?.discovering, isTrue);
      expect(ui.state.comparison?.reference.id, _reference.identity);
      expect(ui.state.comparison?.selectedVersionId, _savedSource.id);
      expect(ui.state.comparison?.alternatives.single.savedSongId, saved.id);
      expect(
        ui.state.comparison?.alternatives.single.bodyPreview.first.text,
        'Our original opening line',
      );
      provider.ready.complete(
        const SourceResult(
          candidate: _reference,
          body: 'Another available version',
          matchKind: MatchKind.sameRecording,
        ),
      );
      await refresh;
      expect(ui.state.comparison?.selectedVersionId, _savedSource.id);
      expect(ui.state.comparison?.alternatives, hasLength(2));
      expect(app.findSong(saved.id)?.body, _savedSource.body);
      await ui.saveSelectedVersion();
      expect(ui.state.route, VerseRoute.reader);
      expect(ui.state.song?.id, saved.id);
      expect(app.songs, hasLength(1));
    },
  );

  test(
    'saved comparison remains usable if refresh has no available source',
    () async {
      final saved = await saveSource();
      ui.dispose();
      app.dispose();
      final provider = _DeferredProvider();
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([provider]),
      );
      await app.initialize();
      ui = AppControllerAdapter(app);
      await ui.openSong(saved.id);
      final refresh = ui.compareCurrentSongVersions();
      provider.ready.completeError(const ProviderException('unavailable'));
      await refresh;
      expect(ui.state.comparison?.discovering, isFalse);
      expect(ui.state.comparison?.selectedVersionId, _savedSource.id);
      expect(ui.state.comparison?.noUsableLyrics, isFalse);
      expect(ui.state.comparison?.alternatives.single.savedSongId, saved.id);
    },
  );

  test('a combined saved choice reopens the same song after restart', () async {
    app.selection = _reference;
    app.results = [_savedSource];
    app.combined = combineSources(_reference, app.results);
    final saved = await app.saveResult();
    ui.dispose();
    app.dispose();
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([]),
    );
    await app.initialize();
    ui = AppControllerAdapter(app);
    await ui.openSong(saved.id);
    await ui.compareCurrentSongVersions();
    expect(ui.state.comparison?.selectedVersionId, 'combined');
    expect(ui.state.comparison?.selected?.savedSongId, saved.id);
    await ui.saveSelectedVersion();
    expect(ui.state.song?.id, saved.id);
    expect(app.songs, hasLength(1));
  });

  test(
    'changing query cancels restored comparison without stale navigation',
    () async {
      final saved = await saveSource();
      ui.dispose();
      app.dispose();
      final provider = _DeferredProvider();
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([provider]),
      );
      await app.initialize();
      ui = AppControllerAdapter(app);
      await ui.openSong(saved.id);
      final refresh = ui.compareCurrentSongVersions();
      ui.changeSearchSong();
      ui.setHomeListMode(HomeListMode.online);
      ui.setQuery('Different song');
      provider.ready.complete(
        const SourceResult(
          candidate: _reference,
          body: 'A late result',
          matchKind: MatchKind.sameRecording,
        ),
      );
      await refresh;
      expect(ui.state.query, 'Different song');
      expect(ui.state.comparison, isNull);
      expect(ui.state.route, VerseRoute.main);
      expect(app.findSong(saved.id)?.body, _savedSource.body);
    },
  );

  test(
    'ready save preserves duration sanitization for invalid provider values',
    () async {
      const source = SourceResult(
        candidate: SongCandidate(
          providerId: 'lrclib',
          id: 'invalid-duration',
          title: 'Signal Song',
          artist: 'The Signals',
          durationSeconds: double.infinity,
        ),
        body: 'Our original opening line',
        metadata: {'durationSeconds': 247},
        matchKind: MatchKind.sameSong,
      );
      app.selection = _reference;
      app.results = [source];
      app.discovering = true;
      final saved = await app.saveResult(source: source);
      expect(saved.metadata['durationSeconds'], 247);
      expect(saved.sources.single.candidate.durationSeconds, isNull);
    },
  );

  testWidgets(
    'ready-version CTA stays enabled while other sources are checking',
    (tester) async {
      final controller = _ReadyController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: VerseHomeScreen(
              controller: controller,
              state: controller.state,
            ),
          ),
        ),
      );
      await tester.pump();
      final cta = find.byKey(const ValueKey('save-open-lyrics'));
      expect(tester.widget<FilledButton>(cta).onPressed, isNotNull);
      expect(find.byKey(const ValueKey('discovery-progress')), findsOneWidget);
      await tester.tap(cta);
      expect(controller.opened, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}

class _DeferredProvider implements LyricsProvider {
  final ready = Completer<SourceResult>();
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'genius',
    name: 'Catalog',
    capabilities: {'catalog', 'lyrics'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_reference];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) => ready.future;
}

class _ReadyController extends VerseUiController {
  bool opened = false;
  @override
  VerseUiState get state => const VerseUiState(
    homeListMode: HomeListMode.online,
    comparison: SearchComparisonData(
      suggested: null,
      reference: SearchReferenceData(
        id: 'reference',
        title: 'Signal Song',
        artist: 'The Signals',
      ),
      discovering: true,
      selectedVersionId: 'ready',
      alternatives: [
        SourceVersionData(
          id: 'ready',
          providerId: 'lrclib',
          providerName: 'LRCLIB',
          title: 'Signal Song',
          artist: 'The Signals',
          hasLyrics: true,
          isUsableVersion: true,
          canSave: true,
          bodyPreview: [
            LyricLineData(id: 'line', text: 'Our original opening line'),
          ],
        ),
      ],
    ),
  );
  @override
  Future<void> saveSelectedVersion() async {
    opened = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
