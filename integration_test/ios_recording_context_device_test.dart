// Native iOS recording-context routing and persistence qualification. All
// provider responses are synthetic; this does not claim live availability.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart' show deleteDatabase, getDatabasesPath;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/acousticbrainz.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/home/source_version_widgets.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/ios_screenshots.dart';

const _recordingId = 'b5d7d380-f43a-4c1f-a5de-694150b093ac';
const _selection = SongCandidate(
  providerId: 'genius',
  id: '81',
  title: 'Lantern Map',
  artist: 'June Harbor',
  durationSeconds: 214,
);
const _lyrics =
    'Paper boats drift past the orchard wall\n'
    'Quiet windows catch the evening rain\n'
    'We fold a map from yesterday sky\n'
    'And follow lanterns down the lane';

class _CatalogFixture implements LyricsProvider {
  @override
  final definition = const ProviderDefinition(
    id: 'genius',
    name: 'Genius fixture',
    capabilities: {'catalog', 'lyrics'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_selection];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: SongCandidate.fromJson({
      ..._selection.toJson(),
      'album': 'Paper Moons',
    }),
    body: _lyrics,
  );
}

class _RecordingDonor implements LyricsProvider {
  @override
  final definition = const ProviderDefinition(
    id: 'musicbrainz',
    name: 'MusicBrainz fixture',
    capabilities: {'metadata'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => throw StateError('Recording donor must not be searched');

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (candidate.album == null) {
      throw const ProviderException('unavailable');
    }
    return const SourceResult(
      candidate: SongCandidate(
        providerId: 'musicbrainz',
        id: _recordingId,
        title: 'Lantern Map',
        artist: 'June Harbor',
        album: 'Paper Moons',
        durationSeconds: 214,
        metadata: {'identityScope': 'recording'},
        recordingIds: {'musicbrainz': _recordingId},
      ),
      body: '',
      metadata: {'album': 'Paper Moons'},
    );
  }
}

Map<String, Object?> _sample(double bpm) => {
  'metadata': {
    'tags': {
      'musicbrainz_recordingid': [_recordingId],
      'title': ['Lantern Map'],
      'artist': ['June Harbor'],
      'album': ['Paper Moons'],
      'file_name': 'private-upload.flac',
    },
    'audio_properties': {'length': 214.0},
    'version': {'essentia': 'native-fixture-1'},
  },
  'rhythm': {'bpm': bpm},
  'tonal': {'key_key': 'D#', 'key_scale': 'minor', 'key_strength': .616},
};

http.Response _jsonResponse(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native recording donor routes channel 10 analysis through comparison, save and SQLite/ChordPro reopen',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_ios_recording_context_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      var repository = await LibraryRepository.open(path: databasePath);
      final requestPaths = <String>[];
      final transport = ProviderTransport(
        client: MockClient((request) async {
          expect(request.url.host, 'acousticbrainz.org');
          requestPaths.add(request.url.path);
          final payload = request.url.path.endsWith('/count')
              ? {
                  _recordingId: {'count': 148},
                  'mbid_mapping': <String, Object?>{},
                }
              : {
                  _recordingId: {'0': _sample(164.02), '1': _sample(163.975)},
                  'mbid_mapping': <String, Object?>{},
                };
          return _jsonResponse(payload);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final nativeAnalysis = AcousticBrainzProvider(
        transport,
        requestInterval: Duration.zero,
      );
      final catalog = SourceCatalog.parse(
        await rootBundle.loadString('config/source-catalog-v10.json'),
      );
      final analysisEntry = catalog.sources.singleWhere(
        (source) => source.id == 'acousticbrainz',
      );
      final configuredAnalysis = ConfiguredBuiltinProvider(
        analysisEntry,
        nativeAnalysis,
      );
      AppController? app;
      AppControllerAdapter? adapter;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        adapter?.dispose();
        app?.dispose();
        await tester.runAsync(() async {
          await transport.close();
          await repository.close();
          await deleteDatabase(databasePath);
        });
      });

      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([
          _CatalogFixture(),
          _RecordingDonor(),
          configuredAnalysis,
        ]),
      );
      await app.initialize();
      app.settings['catalog'] = 'genius';
      await app.setProviderEnabled('musicbrainz', true);
      await app.setProviderEnabled('acousticbrainz', true);
      adapter = AppControllerAdapter(app);
      // UI and test actions share one adapter. VerseApp creates another adapter
      // with independent query and selected-version state.
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: singbookLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
          home: VerseAppShell(controller: adapter, files: VerseFileActions()),
        ),
      );
      await tester.pumpAndSettle();

      adapter.setHomeListMode(HomeListMode.online);
      adapter.setQuery('Lantern Map');
      await adapter.submitSearch();
      expect(app.suggestions, hasLength(1));
      await adapter.selectReference(
        const SearchReferenceData(
          id: 'genius:81',
          title: 'Lantern Map',
          artist: 'June Harbor',
        ),
      );
      await tester.pumpAndSettle();

      final analysisResult = app.results.singleWhere(
        (result) => result.candidate.providerId == 'acousticbrainz',
      );
      expect(analysisResult.matchKind, MatchKind.sameRecording);
      expect(requestPaths, contains('/api/v1/count'));
      expect(requestPaths, contains('/api/v1/low-level'));
      final version = adapter.state.comparison!.alternatives.singleWhere(
        (item) => item.providerId == 'acousticbrainz',
      );
      expect(version.sameRecording, isTrue);
      expect(version.metadata['acousticbrainz'], isNotNull);
      expect(version.metadata.containsKey('key'), isFalse);
      expect(version.metadata.containsKey('tempo'), isFalse);
      expect(jsonEncode(version.metadata), isNot(contains('private-upload')));
      expect(
        ((analysisResult.metadata['acousticbrainz'] as Map)['samples'] as List)
            .map((sample) => (sample['tags'] as Map)['file_name']),
        ['private-upload.flac', 'private-upload.flac'],
        reason:
            'Original upload tags stay archived outside the safe UI projection',
      );

      adapter.selectVersion(version.id);
      await tester.pumpAndSettle();
      final analysisChip = find.byKey(
        ValueKey('version-row-${versionSelectionId(version)}'),
      );
      await tester.ensureVisible(analysisChip);
      await tester.tap(analysisChip);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('version-info-button')));
      await tester.pumpAndSettle();
      final sheet = find.byKey(const ValueKey('version-info-sheet'));
      expect(sheet, findsOneWidget);
      final scrollable = find
          .descendant(of: sheet, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.textContaining('164.02'),
        70,
        scrollable: scrollable,
      );
      expect(find.textContaining('164.02'), findsOneWidget);
      expect(find.textContaining(RegExp(r'D#m[\s\S]*164\.02')), findsOneWidget);
      expect(find.textContaining('private-upload'), findsNothing);
      expect(tester.takeException(), isNull);
      await captureIosCheckpoint('recording_context_analysis_details');
      final close = find.descendant(
        of: sheet,
        matching: find.byIcon(Icons.close_rounded),
      );
      await tester.scrollUntilVisible(close, -100, scrollable: scrollable);
      await tester.tap(close);
      await tester.pumpAndSettle();

      final primaryVersion = adapter.state.comparison!.alternatives.singleWhere(
        (item) => item.providerId == 'genius',
      );
      adapter.selectVersion(primaryVersion.id);
      await tester.pumpAndSettle();
      await adapter.saveSelectedVersion();
      await tester.pumpAndSettle();
      expect(adapter.state.song, isNotNull);
      final saved = (await repository.getSong(app.songs.single.id))!;
      expect(saved.body, _lyrics);
      final preserved = saved.sources.singleWhere(
        (source) => source.candidate.providerId == 'acousticbrainz',
      );
      expect(preserved.metadata['acousticbrainz'], isNotNull);
      expect(preserved.metadata, analysisResult.metadata);
      expect(preserved.extra, analysisResult.extra);
      final portable = ChordProCodec().decode(ChordProCodec().encode(saved));
      final portableAnalysis = portable.sources.singleWhere(
        (source) => source.candidate.providerId == 'acousticbrainz',
      );
      expect(portableAnalysis.toJson(), preserved.toJson());
      expect(portable.body, saved.body);

      await tester.pumpWidget(const SizedBox.shrink());
      adapter.dispose();
      adapter = null;
      app.dispose();
      app = null;
      await repository.close();
      repository = await LibraryRepository.open(path: databasePath);
      final reopened = (await repository.listSongs()).single;
      expect(reopened.id, saved.id);
      expect(reopened.body, saved.body);
      expect(
        reopened.sources
            .singleWhere(
              (source) => source.candidate.providerId == 'acousticbrainz',
            )
            .toJson(),
        preserved.toJson(),
      );
      expect(requestPaths, hasLength(2));
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
