import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/acousticbrainz_analysis.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/acousticbrainz.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _recordingId = 'b5d7d380-f43a-4c1f-a5de-694150b093ac';
const _otherRecordingId = '854a65ca-9e30-4a0a-90b1-e35f2cf21711';
const _selection = SongCandidate(
  providerId: 'genius',
  id: 'fixture-81',
  title: 'Lantern Map',
  artist: 'June Harbor',
  durationSeconds: 214,
);
const _inventedLyrics =
    'Paper boats drift by the orchard wall\n'
    'Quiet windows catch a silver rain\n'
    'We fold a map from yesterday sky\n'
    'And follow lanterns down the lane';

class _Catalog implements LyricsProvider {
  @override
  final definition = const ProviderDefinition(
    id: 'genius',
    name: 'Synthetic catalog',
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
    candidate: SongCandidate(
      providerId: 'genius',
      id: _selection.id,
      title: _selection.title,
      artist: _selection.artist,
      album: 'Paper Moons',
      durationSeconds: 214,
    ),
    body: _inventedLyrics,
  );
}

class _RecordingDonor implements LyricsProvider {
  @override
  final definition = const ProviderDefinition(
    id: 'musicbrainz',
    name: 'Synthetic recording index',
    capabilities: {'metadata'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => throw StateError('No speculative lookup expected');

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (candidate.album == null) throw const ProviderException('unavailable');
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

Map<String, Object?> _sample(double bpm, {String recordingId = _recordingId}) =>
    {
      'metadata': {
        'tags': {
          'musicbrainz_recordingid': [recordingId],
          'title': ['Lantern Map'],
          'artist': ['June Harbor'],
          'album': ['Paper Moons'],
          'file_name': 'synthetic-private-upload.flac',
        },
        'audio_properties': {'length': 214.0},
        'version': {'essentia': 'fixture-only'},
      },
      'rhythm': {'bpm': bpm},
      'tonal': {'key_key': 'D#', 'key_scale': 'minor', 'key_strength': .616},
    };

SourceResult _copyResult(
  SourceResult source, {
  SongCandidate? candidate,
  MatchKind? matchKind,
  JsonMap? metadata,
}) => SourceResult(
  candidate: candidate ?? source.candidate,
  body: source.body,
  metadata: metadata ?? source.metadata,
  timingTracks: source.timingTracks,
  matchKind: matchKind ?? source.matchKind,
  attribution: source.attribution,
  matchReason: source.matchReason,
  arrangementId: source.arrangementId,
  retrievedAt: source.retrievedAt,
  extra: source.extra,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test(
    'ordinary discovery projects only live matching recording analysis into source checks',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'singbook-source-check-analysis-',
      );
      final repo = await LibraryRepository.open(
        path: '${directory.path}/library.sqlite',
        factory: databaseFactoryFfi,
      );
      final transport = ProviderTransport(
        client: MockClient((request) async {
          expect(request.url.host, 'acousticbrainz.org');
          final body = jsonEncode(
            request.url.path.endsWith('/count')
                ? {
                    _recordingId: {'count': 148},
                    'mbid_mapping': {},
                  }
                : {
                    _recordingId: {'0': _sample(164.02), '1': _sample(163.975)},
                    'mbid_mapping': {},
                  },
          );
          return http.Response(body, 200);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final acousticbrainz = AcousticBrainzProvider(
        transport,
        requestInterval: Duration.zero,
      );
      final catalog = SourceCatalog.parse(
        File('config/source-catalog-v10.json').readAsStringSync(),
      );
      final configured = ConfiguredBuiltinProvider(
        catalog.sources.singleWhere((source) => source.id == 'acousticbrainz'),
        acousticbrainz,
      );
      final app = AppController(
        repository: repo,
        discovery: SourceDiscoveryService([
          _Catalog(),
          _RecordingDonor(),
          configured,
        ]),
      );
      final ui = AppControllerAdapter(app);
      try {
        await app.initialize();
        app.settings['catalog'] = 'genius';
        ui.setHomeListMode(HomeListMode.online);
        ui.setQuery('Lantern Map');
        await ui.submitSearch();
        await ui.selectReference(
          const SearchReferenceData(
            id: 'genius:fixture-81',
            title: 'Lantern Map',
            artist: 'June Harbor',
          ),
        );

        expect(app.selection!.recordingIds['musicbrainz'], isNull);
        expect(
          app.results.any(
            (source) => source.candidate.providerId == 'musicbrainz',
          ),
          isTrue,
        );
        final acousticResult = app.results.singleWhere(
          (source) => source.candidate.providerId == 'acousticbrainz',
        );
        expect(acousticResult.matchKind, MatchKind.sameRecording);
        final comparison = ui.state.comparison!;
        final check = comparison.providerChecks.singleWhere(
          (item) => item.id == 'acousticbrainz',
        );
        final analysis = check.recordingAnalysis;
        expect(check.state, 'found');
        expect(analysis, isNotNull);
        expect(analysis!.recordingId, _recordingId);
        expect(analysis.submissionCount, 148);
        expect(analysis.samples, hasLength(2));
        final originalSelection = app.selection!;
        expect(
          AcousticBrainzAnalysis.fromMetadata(
            'acousticbrainz',
            acousticResult.candidate.metadata,
          ),
          isNotNull,
        );
        expect(acousticResult.body, isEmpty);
        expect(acousticResult.candidate.metadata.containsKey('key'), isFalse);
        expect(acousticResult.candidate.metadata.containsKey('tempo'), isFalse);

        final originalCheck = app.checks['acousticbrainz']!;
        final originalWitnessCheck = app.checks['musicbrainz']!;
        final originalResult = acousticResult;
        final musicBrainzWitness = app.results.singleWhere(
          (source) => source.candidate.providerId == 'musicbrainz',
        );

        void refreshProjection() => ui.setSearchFilter('language', '');
        void expectNoAnalysis(String reason) {
          refreshProjection();
          final current = ui.state.comparison!.providerChecks
              .where((item) => item.id == 'acousticbrainz')
              .toList();
          expect(current, hasLength(1), reason: reason);
          expect(current.single.recordingAnalysis, isNull, reason: reason);
        }

        app.selection = const SongCandidate(
          providerId: 'genius',
          id: 'fixture-other-recording',
          title: 'Lantern Map',
          artist: 'June Harbor',
        );
        expectNoAnalysis('analysis from a previous selection must be stale');
        app.selection = originalSelection;

        final rawMetadata = Map<String, Object?>.from(
          originalResult.candidate.metadata,
        );
        rawMetadata.remove('acousticbrainz');
        final missingAnalysis = _copyResult(
          originalResult,
          metadata: Map<String, Object?>.from(originalResult.metadata)
            ..remove('acousticbrainz'),
          candidate: SongCandidate(
            providerId: originalResult.candidate.providerId,
            id: originalResult.candidate.id,
            title: originalResult.candidate.title,
            artist: originalResult.candidate.artist,
            album: originalResult.candidate.album,
            durationSeconds: originalResult.candidate.durationSeconds,
            url: originalResult.candidate.url,
            metadata: rawMetadata,
            recordingIds: originalResult.candidate.recordingIds,
          ),
        );
        app.results = [
          for (final source in app.results)
            if (source.id == originalResult.id) missingAnalysis else source,
        ];
        app.checks['acousticbrainz'] = ProviderCheck(
          providerId: 'acousticbrainz',
          state: 'found',
          result: missingAnalysis,
          operations: originalCheck.operations,
        );
        expectNoAnalysis('missing analyzed MBID must not project estimates');

        final wrongMetadata = Map<String, Object?>.from(
          originalResult.candidate.metadata,
        );
        final wrongAnalysis = Map<String, Object?>.from(
          wrongMetadata['acousticbrainz']! as Map,
        )..['recordingMbid'] = _otherRecordingId;
        wrongMetadata['acousticbrainz'] = wrongAnalysis;
        final wrongIdResult = _copyResult(
          originalResult,
          metadata: {
            ...originalResult.metadata,
            'acousticbrainz': wrongAnalysis,
          },
          candidate: SongCandidate(
            providerId: originalResult.candidate.providerId,
            id: originalResult.candidate.id,
            title: originalResult.candidate.title,
            artist: originalResult.candidate.artist,
            album: originalResult.candidate.album,
            durationSeconds: originalResult.candidate.durationSeconds,
            url: originalResult.candidate.url,
            metadata: wrongMetadata,
            recordingIds: originalResult.candidate.recordingIds,
          ),
        );
        app.results = [
          for (final source in app.results)
            if (source.id == originalResult.id) wrongIdResult else source,
        ];
        app.checks['acousticbrainz'] = ProviderCheck(
          providerId: 'acousticbrainz',
          state: 'found',
          result: wrongIdResult,
          operations: originalCheck.operations,
        );
        expectNoAnalysis('analysis MBID must match the checked recording');

        app.results = [
          for (final source in app.results)
            if (source.id == originalResult.id) originalResult else source,
        ];
        app.checks['acousticbrainz'] = ProviderCheck(
          providerId: 'acousticbrainz',
          state: 'pending',
          result: originalResult,
          operations: originalCheck.operations,
        );
        expectNoAnalysis('pending checks must not carry estimates');

        final rejectedResult = _copyResult(
          originalResult,
          matchKind: MatchKind.rejected,
        );
        app.results = [
          for (final source in app.results)
            if (source.id == originalResult.id) rejectedResult else source,
        ];
        app.checks['acousticbrainz'] = ProviderCheck(
          providerId: 'acousticbrainz',
          state: 'found',
          result: rejectedResult,
          operations: originalCheck.operations,
        );
        expectNoAnalysis('rejected source must not carry estimates');

        app.results = [
          for (final source in app.results)
            if (source.id != originalResult.id) source,
        ];
        app.checks['acousticbrainz'] = ProviderCheck(
          providerId: 'acousticbrainz',
          state: 'found',
          result: originalResult,
          operations: originalCheck.operations,
        );
        expectNoAnalysis('stale source is not a current projection');

        app.results = [...app.results, originalResult];

        final rejectedWitness = _copyResult(
          musicBrainzWitness,
          matchKind: MatchKind.rejected,
        );
        app.results = [
          for (final source in app.results)
            if (source.id == musicBrainzWitness.id) rejectedWitness else source,
        ];
        expectNoAnalysis('rejected witness must invalidate projection');

        final pendingWitnessMetadata = Map<String, dynamic>.from(
          musicBrainzWitness.candidate.metadata,
        )..['pendingMatchCheck'] = true;
        final pendingWitness = _copyResult(
          musicBrainzWitness,
          candidate: SongCandidate(
            providerId: musicBrainzWitness.candidate.providerId,
            id: musicBrainzWitness.candidate.id,
            title: musicBrainzWitness.candidate.title,
            artist: musicBrainzWitness.candidate.artist,
            album: musicBrainzWitness.candidate.album,
            durationSeconds: musicBrainzWitness.candidate.durationSeconds,
            metadata: pendingWitnessMetadata,
            recordingIds: musicBrainzWitness.candidate.recordingIds,
          ),
        );
        app.results = [
          for (final source in app.results)
            if (source.id == musicBrainzWitness.id) pendingWitness else source,
        ];
        expectNoAnalysis('pending witness must invalidate projection');

        app.results = [
          for (final source in app.results)
            if (source.id == musicBrainzWitness.id)
              musicBrainzWitness
            else
              source,
        ];
        app.checks['musicbrainz'] = ProviderCheck(
          providerId: 'musicbrainz',
          state: 'cancelled',
          result: musicBrainzWitness,
          operations: originalWitnessCheck.operations,
        );
        expectNoAnalysis('cancelled witness check must invalidate projection');
        app.checks['musicbrainz'] = originalWitnessCheck;

        app.results = app.results
            .where((source) => source.id != musicBrainzWitness.id)
            .toList();
        expectNoAnalysis(
          'missing live recording witness must invalidate projection',
        );

        app.results = [...app.results, musicBrainzWitness];
        app.checks['acousticbrainz'] = ProviderCheck(
          providerId: 'acousticbrainz',
          state: 'cancelled',
          result: originalResult,
          operations: originalCheck.operations,
        );
        expectNoAnalysis('cancelled source checks must not carry estimates');

        app.checks['acousticbrainz'] = originalCheck;
        final providerSettings = Map<String, Object?>.from(
          app.settings['providers'] as Map? ?? const {},
        )..['musicbrainz'] = false;
        app.settings = {...app.settings, 'providers': providerSettings};
        expectNoAnalysis(
          'disabled recording witness must invalidate projection',
        );

        providerSettings['musicbrainz'] = true;
        providerSettings['acousticbrainz'] = false;
        app.settings = {...app.settings, 'providers': providerSettings};
        refreshProjection();
        final disabled = ui.state.comparison!.providerChecks
            .where((item) => item.id == 'acousticbrainz')
            .toList();
        expect(disabled, hasLength(1));
        expect(disabled.single.recordingAnalysis, isNull);
        expect(disabled.single.operations, isNotEmpty);
      } finally {
        ui.dispose();
        app.dispose();
        await transport.close();
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
