import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/arrangement.dart' as arrangement;
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/home/source_version_browser.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

const _candidate = SongCandidate(
  providerId: 'startjamming',
  id: 'instrumental-fixture',
  title: 'Instrumental Fixture',
  artist: '',
  url: 'https://www.startjamming.com/song/instrumental-fixture',
  metadata: {'identityScope': 'arrangement'},
);
const _body = '{start_of_part: A}\n[G] [C] [D7]\n{end_of_part}';

class _Provider implements LyricsProvider {
  const _Provider({this.candidate = _candidate, this.chords = true});

  final SongCandidate candidate;
  final bool chords;

  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: candidate.providerId,
    name: chords ? 'Start Jamming' : 'Lyrics fixture',
    capabilities: {
      if (chords) 'catalog',
      'lyrics',
      if (chords) 'chords',
      'metadata',
    },
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [candidate];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw UnimplementedError();
}

/// Supplies already validated discovery outcomes to exercise presentation and
/// persistence independently of the provider's HTTP/identity regression suite.
class _Discovery extends SourceDiscoveryService {
  _Discovery(
    this.result, {
    SongCandidate selection = _candidate,
    this.additionalResults = const [],
  }) : super([
         _Provider(candidate: selection),
         for (final source in additionalResults)
           _Provider(candidate: source.candidate, chords: false),
       ]);
  final SourceResult result;
  final List<SourceResult> additionalResults;

  @override
  Future<List<SourceResult>> discover(
    SongCandidate selection, {
    Set<String>? enabledIds,
    void Function(ProviderCheck)? onProgress,
    CancellationToken? cancel,
    Map<String, CancellationToken> providerCancellation = const {},
    Duration alternativeTimeout = const Duration(seconds: 30),
  }) async {
    final results = [result, ...additionalResults];
    for (final source in results) {
      onProgress?.call(
        ProviderCheck(
          providerId: source.candidate.providerId,
          state: 'found',
          result: source,
        ),
      );
    }
    return results;
  }
}

void main() {
  sqfliteFfiInit();

  Future<(LibraryRepository, AppController, AppControllerAdapter)> open(
    SourceResult result, {
    SongCandidate selection = _candidate,
    List<SourceResult> additionalResults = const [],
  }) async {
    final repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    final app = AppController(
      repository: repository,
      discovery: _Discovery(
        result,
        selection: selection,
        additionalResults: additionalResults,
      ),
    );
    await app.initialize();
    app.settings['catalog'] = selection.providerId;
    final ui = AppControllerAdapter(app);
    addTearDown(() async {
      ui.dispose();
      app.dispose();
      await repository.close();
    });
    ui.setHomeListMode(HomeListMode.online);
    ui.setQuery(selection.title);
    await ui.submitSearch();
    await ui.selectReference(
      SearchReferenceData(
        id: selection.identity,
        title: selection.title,
        artist: selection.artist,
      ),
    );
    return (repository, app, ui);
  }

  for (final selectedVersion in ['combined', _candidate.identity]) {
    test(
      'chord-only $selectedVersion opens and persists without lyrics',
      () async {
        final (repository, app, ui) = await open(
          SourceResult(
            candidate: _candidate,
            body: _body,
            matchKind: MatchKind.sameSong,
            metadata: const {'key': 'G', 'identityScope': 'arrangement'},
          ),
        );
        final comparison = ui.state.comparison!;
        expect(comparison.noUsableLyrics, isFalse);
        for (final version in [
          comparison.suggested!,
          comparison.alternatives.single,
        ]) {
          expect(version.hasLyrics, isFalse);
          expect(version.hasChords, isTrue);
          expect(version.isUsableVersion, isTrue);
          expect(version.canSave, isTrue);
          expect(version.artist, isEmpty);
        }

        ui.selectVersion(selectedVersion);
        await ui.saveSelectedVersion();
        expect(ui.state.route, VerseRoute.reader);
        expect(app.songs, hasLength(1));
        final saved = (await repository.getSong(app.songs.single.id))!;
        expect(saved.artist, isEmpty);
        expect(saved.hasChords, isTrue);
        expect(arrangement.plainLyrics(saved.body).trim(), isEmpty);
        expect(saved.sources.single.candidate.identity, _candidate.identity);
        expect(saved.sources.single.body, _body);
        expect(saved.metadata['key'], 'G');
        expect(ui.state.songLines.expand((line) => line.chords), isNotEmpty);
        await ui.openSong(saved.id);
        expect(ui.state.route, VerseRoute.reader);
        expect(ui.state.song!.id, saved.id);
      },
    );
  }

  test(
    'matching lyrics remain suggested while own chord-only chart can be explicitly saved',
    () async {
      const selected = SongCandidate(
        providerId: 'startjamming',
        id: 'mixed-fixture',
        title: 'Mixed Fixture',
        artist: 'Fixture Ensemble',
        metadata: {'identityScope': 'arrangement'},
      );
      const lyricCandidate = SongCandidate(
        providerId: 'lyrics-fixture',
        id: 'mixed-lyrics',
        title: 'Mixed Fixture',
        artist: 'Fixture Ensemble',
      );
      const lyrics =
          'Silver lanterns follow quiet rivers through the valley beneath a golden morning sky\n'
          'Every distant hillside keeps a melody that brings the wandering travelers home';
      final chart = SourceResult(
        candidate: selected,
        body: _body,
        matchKind: MatchKind.sameSong,
        metadata: const {'key': 'G', 'identityScope': 'arrangement'},
      );
      final lyricResult = SourceResult(
        candidate: lyricCandidate,
        body: lyrics,
        matchKind: MatchKind.sameSong,
      );
      final (repository, app, ui) = await open(
        chart,
        selection: selected,
        additionalResults: [lyricResult],
      );
      final comparison = ui.state.comparison!;
      expect(comparison.selectedVersionId, 'combined');
      expect(comparison.suggested!.hasLyrics, isTrue);
      expect(comparison.suggested!.isUsableVersion, isTrue);
      expect(arrangement.plainLyrics(app.combined!.body).trim(), lyrics);
      expect(app.combined!.extra['selectedSourceId'], lyricResult.id);
      final defaultCombined = app.combined;

      final rawChart = comparison.alternatives.singleWhere(
        (version) => version.id == chart.id,
      );
      expect(rawChart.hasLyrics, isFalse);
      expect(rawChart.hasChords, isTrue);
      expect(rawChart.isUsableVersion, isTrue);
      expect(rawChart.canSave, isTrue);

      ui.selectVersion(rawChart.id);
      expect(ui.state.comparison!.selectedVersionId, chart.id);
      expect(ui.state.comparison!.suggested!.hasLyrics, isTrue);
      expect(identical(app.combined, defaultCombined), isTrue);
      expect(app.combined!.extra['selectedSourceId'], lyricResult.id);
      await ui.saveSelectedVersion();
      expect(ui.state.route, VerseRoute.reader);
      final saved = (await repository.getSong(app.songs.single.id))!;
      expect(saved.extra['selectedSourceId'], chart.id);
      expect(saved.artist, selected.artist);
      expect(saved.hasChords, isTrue);
      expect(arrangement.plainLyrics(saved.body).trim(), isEmpty);
      expect(
        saved.sources.singleWhere((source) => source.id == chart.id).body,
        _body,
      );
      expect(app.combined!.extra['selectedSourceId'], lyricResult.id);
      expect(arrangement.plainLyrics(app.combined!.body).trim(), lyrics);
    },
  );

  final invalid = <String, SourceResult>{
    'metadata-only': SourceResult(
      candidate: _candidate,
      body: '',
      matchKind: MatchKind.sameSong,
      metadata: const {'key': 'G'},
    ),
    'directive-only': SourceResult(
      candidate: _candidate,
      body: '{key: G}\n{start_of_part: A}\n{end_of_part}',
      matchKind: MatchKind.sameSong,
    ),
    'chord label inside a comment': SourceResult(
      candidate: _candidate,
      body: '{comment: Try [C] later}\n{key: G}',
      matchKind: MatchKind.sameSong,
    ),
    'rejected chart': SourceResult(
      candidate: _candidate,
      body: _body,
      matchKind: MatchKind.rejected,
    ),
    'unverified chart': SourceResult(
      candidate: _candidate,
      body: _body,
      matchKind: MatchKind.unverified,
    ),
    'pending chart': SourceResult(
      candidate: _candidate,
      body: _body,
      matchKind: MatchKind.sameSong,
      extra: const {'pendingMatchCheck': true},
    ),
    'foreign chart': SourceResult(
      candidate: const SongCandidate(
        providerId: 'startjamming',
        id: 'other-arrangement',
        title: 'Instrumental Fixture',
        artist: '',
        metadata: {'identityScope': 'arrangement'},
      ),
      body: _body,
      matchKind: MatchKind.sameSong,
    ),
    'same-ID changed title': SourceResult(
      candidate: const SongCandidate(
        providerId: 'startjamming',
        id: 'instrumental-fixture',
        title: 'Different Instrumental',
        artist: '',
        metadata: {'identityScope': 'arrangement'},
      ),
      body: _body,
      matchKind: MatchKind.sameSong,
    ),
  };
  for (final entry in invalid.entries) {
    test('${entry.key} is not promoted to a usable instrumental', () async {
      final (_, app, ui) = await open(entry.value);
      final comparison = ui.state.comparison!;
      expect(comparison.noUsableLyrics, isTrue);
      expect(comparison.suggested, isNull);
      expect(app.combined, isNull);
      final raw = comparison.alternatives.single;
      expect(raw.hasLyrics, isFalse);
      expect(raw.isUsableVersion, isFalse);
      expect(raw.canSave, isFalse);
      ui.selectVersion(raw.id);
      await ui.saveSelectedVersion();
      expect(app.songs, isEmpty);
      expect(ui.state.route, isNot(VerseRoute.reader));
    });
  }

  testWidgets(
    'instrumental comparison counts a ready chart and Save opens it',
    (tester) async {
      const version = SourceVersionData(
        id: 'startjamming:instrumental-fixture',
        providerId: 'startjamming',
        providerName: 'Start Jamming',
        title: 'Instrumental Fixture',
        artist: '',
        hasChords: true,
        isUsableVersion: true,
        canSave: true,
        bodyLines: [
          LyricLineData(
            id: 'chords',
            chords: [LyricChord(graphemeOffset: 0, symbol: 'G')],
          ),
        ],
      );
      final controller = FakeUiController(
        (_) => const VerseUiState(
          comparison: SearchComparisonData(
            reference: SearchReferenceData(
              id: 'startjamming:instrumental-fixture',
              title: 'Instrumental Fixture',
              artist: '',
            ),
            suggested: null,
            alternatives: [version],
            selectedVersionId: 'startjamming:instrumental-fixture',
          ),
        ),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: singbookLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SourceVersionBrowser(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(SourceVersionBrowser)),
      );
      expect(find.text(l10n.searchReadyVersions(0)), findsNothing);
      expect(find.text(l10n.searchReadyVersions(1)), findsOneWidget);
      expect(find.text(l10n.providerCapabilityLyrics), findsNothing);
      expect(
        find.byKey(const ValueKey('version-preview-pages')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('save-open-lyrics')));
      await tester.pumpAndSettle();
      expect(controller.calls, contains('saveSelectedVersion'));
      expect(tester.takeException(), isNull);
    },
  );
}
