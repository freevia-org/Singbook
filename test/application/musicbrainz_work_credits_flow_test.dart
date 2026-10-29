import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/metadata.dart';
import 'package:singbook/providers/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _LyricCatalog implements LyricsProvider {
  _LyricCatalog(this.selection);
  final SongCandidate selection;
  @override
  final definition = const ProviderDefinition(
    id: 'genius',
    name: 'Invented lyric catalog',
    capabilities: {'catalog', 'lyrics'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [selection];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: selection,
    body:
        'Invented lanterns drift across the bay\nPaper gardens catch the evening rain\nWe fold a map beside the orchard wall\nAnd watch the silver leaves return again',
  );
}

/// Shared by the synthetic regression and private retained-response qualification.
/// Never opens a default library or makes a network request.
Future<Map<String, Object?>> qualifyWorkCreditPersistence({
  required List<int> responseBytes,
  required Map<String, List<String>> expectedAuthors,
}) async {
  final data = jsonDecode(utf8.decode(responseBytes)) as Map<String, dynamic>;
  final artist = (data['artist-credit'] as List)
      .map((c) => '${c['name'] ?? c['artist']['name']}${c['joinphrase'] ?? ''}')
      .join();
  final selection = SongCandidate(
    providerId: 'genius',
    id: 'invented-reference-${data['id']}',
    title: data['title'],
    artist: artist,
    durationSeconds: (data['length'] as num) / 1000,
    recordingIds: {'musicbrainz': data['id']},
  );
  final directory = await Directory.systemTemp.createTemp(
    'singbook-work-credit-flow-',
  );
  final path = '${directory.path}/isolated.sqlite';
  var repository = await LibraryRepository.open(
    path: path,
    factory: databaseFactoryFfi,
  );
  var calls = 0;
  var catalogReplies = 0;
  var recordingReplays = 0;
  final transport = ProviderTransport(
    client: MockClient((request) async {
      calls++;
      expect(request.url.host, 'musicbrainz.org');
      if (request.url.path == '/ws/2/recording/') {
        catalogReplies++;
        return http.Response(
          jsonEncode({
            'recordings': [
              {
                'id': data['id'],
                'title': data['title'],
                'length': data['length'],
                'artist-credit': data['artist-credit'],
                'releases': [],
              },
            ],
          }),
          200,
        );
      }
      recordingReplays++;
      expect(request.url.path, '/ws/2/recording/${data['id']}');
      expect(
        request.url.queryParameters['inc']!.split('+'),
        containsAll(['work-rels', 'work-level-rels', 'artist-rels']),
      );
      return http.Response.bytes(responseBytes, 200);
    }),
    hostInterval: Duration.zero,
    maxRetries: 0,
  );
  AppController? app;
  try {
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([
        _LyricCatalog(selection),
        MusicBrainzProvider(transport),
      ]),
    );
    await app.initialize();
    expect(await repository.listSongs(), isEmpty);
    app.settings['catalog'] = 'genius';
    await app.search(selection.title);
    await app.selectCandidate(
      app.suggestions.singleWhere((s) => s.providerId == 'genius'),
    );
    final source = app.results.singleWhere(
      (s) => s.candidate.providerId == 'musicbrainz',
    );
    expect(catalogReplies, 1);
    expect(recordingReplays, 1);
    expect(calls, 2);
    expect(source.candidate.recordingIds['musicbrainz'], data['id']);
    expect(source.candidate.artist, artist);
    final saved = await app.saveResult();
    for (final field in ['writers', 'composers', 'lyricists']) {
      final expected = expectedAuthors[field];
      if (expected == null) {
        expect(saved.metadata[field], isNull);
      } else {
        // Combined display values have deterministic order; source ordering
        // is checked separately through the exact saved source document.
        expect(saved.metadata[field], unorderedEquals(expected));
      }
    }
    final preserved = saved.sources.singleWhere(
      (s) => s.candidate.providerId == 'musicbrainz',
    );
    expect(preserved.metadata, source.metadata);
    expect(preserved.extra, source.extra);
    expect(preserved.attribution, source.attribution);
    final portable = ChordProCodec().decode(ChordProCodec().encode(saved));
    expect(portable.metadata, saved.metadata);
    expect(
      portable.sources
          .singleWhere((s) => s.candidate.providerId == 'musicbrainz')
          .toJson(),
      preserved.toJson(),
    );
    final savedJson = saved.toJson();
    await app.setProviderEnabled('musicbrainz', false);
    expect(await repository.listSongs(), hasLength(1));
    app.dispose();
    app = null;
    await repository.close();
    repository = await LibraryRepository.open(
      path: path,
      factory: databaseFactoryFfi,
    );
    final reopened = (await repository.listSongs()).single;
    expect(reopened.toJson(), savedJson);
    app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([
        _LyricCatalog(selection),
        MusicBrainzProvider(transport),
      ]),
    );
    await app.initialize();
    expect(app.providerEnabled('musicbrainz'), false);
    expect(app.songs.single.toJson(), savedJson);
    expect(
      calls,
      2,
      reason: 'Reopening and disabling a source requires no lookup',
    );
    return {
      'recordingId': data['id'],
      'status': 'passed',
      'mockReplayRequests': calls,
      'recordingResponseReplays': recordingReplays,
      'syntheticCatalogReplies': catalogReplies,
      'networkRequests': 0,
      'responseSha256': sha256.convert(responseBytes).toString(),
      'sourceMetadataSha256': sha256
          .convert(utf8.encode(jsonEncode(source.metadata)))
          .toString(),
      'savedSongId': saved.id,
      'workCount': (source.metadata['musicbrainzWorks'] as List).length,
      'authorCounts': {
        for (final e in expectedAuthors.entries) e.key: e.value.length,
      },
      'combinedAuthorsMatched': true,
      'sqliteReopenExact': true,
      'portableMetadataAndSourceExact': true,
      'disabledPreferenceReopened': true,
      'userLibraryAccessed': false,
    };
  } finally {
    app?.dispose();
    await repository.close();
    await transport.close();
    // Only the newly created, isolated test database directory is removed.
    await directory.delete(recursive: true);
  }
}

Map<String, Object?> _fixture({bool ambiguous = false}) => {
  'id': '11111111-1111-4111-8111-111111111111',
  'title': 'Lantern Harbor',
  'length': 180000,
  'artist-credit': [
    {
      'name': 'Mira Vale',
      'artist': {'id': '33333333-3333-4333-8333-333333333333'},
    },
  ],
  'releases': [],
  'relations': [
    for (var w = 0; w < (ambiguous ? 2 : 1); w++)
      {
        'target-type': 'work',
        'type': 'performance',
        'direction': 'forward',
        'attributes': [],
        'work': {
          'id': '22222222-2222-4222-8222-22222222222$w',
          'title': 'Lantern Harbor',
          'relations': [
            for (final role in ['writer', 'composer', 'lyricist'])
              {
                'target-type': 'artist',
                'type': role,
                'direction': 'backward',
                'attributes': [],
                'artist': {
                  'id':
                      '44444444-4444-4444-8444-44444444444${['writer', 'composer', 'lyricist'].indexOf(role)}',
                  'name': 'Invented $role',
                },
              },
          ],
        },
      },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  for (final ambiguous in [false, true]) {
    test(
      'controller retains ${ambiguous ? 'ambiguous scoped works without flat credits' : 'unambiguous work authors'} through SQLite and ChordPro',
      () async {
        await qualifyWorkCreditPersistence(
          responseBytes: utf8.encode(
            jsonEncode(_fixture(ambiguous: ambiguous)),
          ),
          expectedAuthors: ambiguous
              ? {}
              : {
                  'writers': ['Invented writer'],
                  'composers': ['Invented composer'],
                  'lyricists': ['Invented lyricist'],
                },
        );
      },
    );
  }
}
