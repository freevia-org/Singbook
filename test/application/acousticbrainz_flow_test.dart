import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/providers/core/recording_context.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/acousticbrainz.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _id = 'b5d7d380-f43a-4c1f-a5de-694150b093ac';
const _selection = SongCandidate(
  providerId: 'genius',
  id: '81',
  title: 'Lantern Map',
  artist: 'June Harbor',
  durationSeconds: 214,
);
const _lyrics =
    'Paper boats drift past the orchard wall\nQuiet windows catch the evening rain\nWe fold a map from yesterday sky\nAnd follow lanterns down the lane';

class _Catalog implements LyricsProvider {
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
  }) async => throw StateError('No speculative search');
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (candidate.album == null) throw const ProviderException('unavailable');
    return const SourceResult(
      candidate: SongCandidate(
        providerId: 'musicbrainz',
        id: _id,
        title: 'Lantern Map',
        artist: 'June Harbor',
        album: 'Paper Moons',
        durationSeconds: 214,
        metadata: {'identityScope': 'recording'},
        recordingIds: {'musicbrainz': _id},
      ),
      body: '',
      metadata: {'album': 'Paper Moons'},
    );
  }
}

Map<String, Object?> _sample(double bpm) => {
  'metadata': {
    'tags': {
      'musicbrainz_recordingid': [_id],
      'title': ['Lantern Map'],
      'artist': ['June Harbor'],
      'album': ['Paper Moons'],
      'file_name': 'private-upload.flac',
    },
    'audio_properties': {'length': 214.0},
    'version': {'essentia': 'fixture-1'},
  },
  'rhythm': {'bpm': bpm},
  'tonal': {'key_key': 'D#', 'key_scale': 'minor', 'key_strength': .616},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test(
    'ordinary controller flow exposes safe analysis and preserves exact source through SQLite and ChordPro',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'singbook-analysis-flow-',
      );
      final path = '${directory.path}/library.sqlite';
      var repo = await LibraryRepository.open(
        path: path,
        factory: databaseFactoryFfi,
      );
      final bodies = <List<int>>[];
      final transport = ProviderTransport(
        client: MockClient((request) async {
          expect(request.url.host, 'acousticbrainz.org');
          final bytes = utf8.encode(
            jsonEncode(
              request.url.path.endsWith('/count')
                  ? {
                      _id: {'count': 148},
                      'mbid_mapping': {},
                    }
                  : {
                      _id: {'0': _sample(164.02), '1': _sample(163.975)},
                      'mbid_mapping': {},
                    },
            ),
          );
          bodies.add(bytes);
          return http.Response.bytes(bytes, 200);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final native = AcousticBrainzProvider(
        transport,
        requestInterval: Duration.zero,
      );
      final catalog = SourceCatalog.parse(
        File('config/source-catalog-v10.json').readAsStringSync(),
      );
      final configured = ConfiguredBuiltinProvider(
        catalog.sources.singleWhere((s) => s.id == 'acousticbrainz'),
        native,
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
      var disposed = false;
      try {
        await app.initialize();
        app.settings['catalog'] = 'genius';
        ui.setHomeListMode(HomeListMode.online);
        ui.setQuery('Lantern Map');
        await ui.submitSearch();
        await ui.selectReference(
          const SearchReferenceData(
            id: 'genius:81',
            title: 'Lantern Map',
            artist: 'June Harbor',
          ),
        );
        expect(bodies, hasLength(2));
        final source = app.results.singleWhere(
          (s) => s.candidate.providerId == 'acousticbrainz',
        );
        expect(source.matchKind, MatchKind.sameRecording);
        final version = ui.state.comparison!.alternatives.singleWhere(
          (s) => s.providerId == 'acousticbrainz',
        );
        expect(
          version.sameRecording,
          true,
          reason: jsonEncode({
            'proof': source.extra['recordingContext'],
            'recomputed': planRecordingContext(
              app.selection!,
              app.results,
              namespace: 'musicbrainz',
              eligible: app.providerEnabled,
            )?.provenance,
            'witnesses': [
              for (final s in app.results.where(
                (s) => s.candidate.providerId != 'acousticbrainz',
              ))
                s.toJson(),
            ],
          }),
        );
        expect(version.metadata['acousticbrainz'], isNotNull);
        expect(jsonEncode(version.metadata), isNot(contains('private-upload')));
        expect(version.metadata.containsKey('key'), false);
        expect(version.metadata.containsKey('tempo'), false);
        final saved = await app.saveResult();
        final preserved = saved.sources.singleWhere(
          (s) => s.candidate.providerId == 'acousticbrainz',
        );
        expect(preserved.metadata, source.metadata);
        expect(preserved.extra, source.extra);
        final payloads = preserved.extra['originalPayloads'] as List;
        expect(base64Decode(payloads[0]['base64']), bodies[0]);
        expect(base64Decode(payloads[1]['base64']), bodies[1]);
        final portable = ChordProCodec().decode(ChordProCodec().encode(saved));
        expect(
          portable.sources
              .singleWhere((s) => s.candidate.providerId == 'acousticbrainz')
              .toJson(),
          preserved.toJson(),
        );
        ui.dispose();
        app.dispose();
        disposed = true;
        await repo.close();
        repo = await LibraryRepository.open(
          path: path,
          factory: databaseFactoryFfi,
        );
        final reopened = (await repo.listSongs()).single;
        expect(
          reopened.sources
              .singleWhere((s) => s.candidate.providerId == 'acousticbrainz')
              .toJson(),
          preserved.toJson(),
        );
        expect(reopened.body, contains('Paper boats'));
        expect(bodies, hasLength(2));
      } finally {
        // Disposing these notifiers twice is avoided when successful.
        if (!disposed) {
          ui.dispose();
          app.dispose();
        }
        await transport.close();
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
