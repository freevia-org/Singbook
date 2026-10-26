import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/kara_moe.dart';
import 'package:singbook/providers/transport.dart';

const _kid = '12345678-1234-4234-8234-123456789abc';
Map<String, dynamic> _tag(String name) => {'name': name};
Map<String, dynamic> _row() => {
  'kid': _kid,
  'titles': {'eng': 'Amber Lantern'},
  'titles_default_language': 'eng',
  'singers': [_tag('Synthetic Ensemble')],
  'singergroups': [],
  'songwriters': [_tag('Synthetic Writer')],
  'authors': [_tag('Synthetic Synchronizer')],
  'langs': [_tag('eng')],
  'songtypes': [_tag('MV')],
  'versions': [_tag('Cover')],
  'collections': [_tag('West')],
  'series': [],
  'genres': [],
  'duration': 91,
  'year': 2026,
  'repository': 'kara.moe',
  'lyrics_infos': [
    {'default': true, 'version': 'Default', 'filename': '$_kid.ass'},
  ],
  'lyrics': [
    {
      'start': 1.25,
      'end': 3.5,
      'text': 'Paper lanterns float across the sleeping garden',
      'fullText': [
        {
          'tags': [
            {'k': 225},
          ],
          'text': 'Paper lanterns float across the sleeping garden',
          'drawing': [],
        },
      ],
    },
    {
      'start': 4,
      'end': 6.5,
      'text': 'Silver rivers carry every quiet song',
      'fullText': [
        {
          'tags': [
            {'kf': 250},
          ],
          'text': 'Silver rivers carry every quiet song',
          'drawing': [],
        },
      ],
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  test(
    'karaoke video facts and timing retain scope through search, save and export',
    () async {
      final row = _row(), raw = jsonEncode(_row());
      var calls = 0;
      final transport = ProviderTransport(
        client: MockClient((r) async {
          calls++;
          return r.url.path.endsWith('/search')
              ? http.Response(
                  jsonEncode({
                    'content': [row],
                  }),
                  200,
                )
              : http.Response(raw, 200);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final provider = KaraMoeProvider(
        transport,
        requestInterval: Duration.zero,
      );
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      await repo.setSetting('app', {
        'providers': {'karamoe': true},
      });
      final app = AppController(
        repository: repo,
        discovery: SourceDiscoveryService([provider]),
      );
      try {
        await app.initialize();
        await app.search('Amber Lantern Synthetic Ensemble');
        final candidate = app.suggestions.single;
        expect(candidate.id, _kid);
        expect(candidate.artist, 'Synthetic Ensemble');
        expect(candidate.recordingIds, isEmpty);
        expect(candidate.album, isNull);
        expect(candidate.durationSeconds, isNull);
        await app.selectCandidate(candidate);
        final source = app.results.single;
        expect(source.metadata['sourceVideoYear'], 2026);
        expect(source.metadata['sourceVideoDurationSeconds'], 91);
        expect(source.metadata.containsKey('year'), false);
        expect(source.metadata.containsKey('durationSeconds'), false);
        expect(source.timingTracks.single.raw, raw);
        expect(
          source.timingTracks.single.extra['recordingEvidence'],
          'sourceDemonstrationOnly',
        );
        expect(source.timingTracks.single.status, isNot(TimingStatus.usable));
        final recording = SongCandidate(
          providerId: 'catalog',
          id: 'studio-recording',
          title: candidate.title,
          artist: candidate.artist,
          album: 'Studio Album',
          durationSeconds: 240,
          metadata: {'identityScope': 'recording'},
          recordingIds: {'synthetic': 'studio-take'},
        );
        final combined = combineSources(recording, [source]);
        expect(
          combined.timingTracks.any((t) => t.status == TimingStatus.usable),
          false,
        );
        expect(combined.activeTimingTrackId, isNull);
        final saved = await app.saveResult(source: source);
        expect((await repo.listSongs()).length, 1);
        final stored = (await repo.getSong(saved.id))!;
        expect(stored.id, saved.id);
        expect(
          stored.sources.single.extra['originalPayload'],
          source.extra['originalPayload'],
        );
        expect(stored.sources.single.timingTracks.single.raw, raw);
        final exported = ChordProCodec().decode(app.exportSong(stored));
        expect(exported.body, stored.body);
        expect(
          exported.sources.single.toJson(),
          stored.sources.single.toJson(),
        );
        expect(
          exported.timingTracks.any((t) => t.status == TimingStatus.usable),
          false,
        );
        expect(calls, 2);
      } finally {
        app.dispose();
        await transport.close();
        await repo.close();
      }
    },
  );
}
