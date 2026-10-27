import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/vocadb.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';

const _canonical = 'Fictional Song';
const _artist = 'Invented Producer feat. Invented Voice';
const _japanese = '架空の歌';
const _romaji = 'Kakuu no Uta';

Map<String, dynamic> _entry({
  int id = 501,
  String title = _canonical,
  String artist = _artist,
  String album = 'Imaginary Album',
  List<String> aliases = const [_canonical, _japanese, _romaji],
}) => {
  'id': id,
  'name': title,
  'artistString': artist,
  'songType': 'Original',
  'names': [
    for (final value in aliases) {'language': 'English', 'value': value},
  ],
  'artists': [
    {'name': 'Invented Producer', 'roles': 'Composer'},
  ],
  'albums': [
    {'id': 15, 'name': album},
  ],
  'cultureCodes': ['ja'],
  'lengthSeconds': 201,
  'version': 1,
  'lyrics': [
    {
      'id': 72,
      'translationType': 'Original',
      'value': 'Invented first line\nInvented second line',
      'source': 'Invented lyricist',
    },
  ],
  'webLinks': [],
};

http.Response _response(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ProviderTransport _transport(
  Future<http.Response> Function(http.Request) handler,
) => ProviderTransport(
  client: MockClient(handler),
  hostInterval: Duration.zero,
  maxRetries: 0,
);

ConfiguredBuiltinProvider _configured(LyricsProvider delegate) =>
    ConfiguredBuiltinProvider(
      SourceCatalogEntry.fromJson({
        'id': 'vocadb',
        'name': 'VocaDB',
        'adapter': 'builtin',
        'status': 'active',
        'revision': 1,
        'capabilities': ['catalog', 'lyrics', 'metadata'],
        'enabledByDefault': true,
        'accessMode': 'publicApi',
        'website': 'https://vocadb.net/',
        'hosts': <String>[],
      }),
      delegate,
    );

const _selectionArtistAlbumDuration = SongCandidate(
  providerId: 'library',
  id: 'recording-local',
  title: _japanese,
  artist: _artist,
  album: 'Imaginary Album',
  durationSeconds: 201,
);

class _StaticAliasProvider implements LyricsProvider {
  _StaticAliasProvider(this.candidate);

  final SongCandidate candidate;

  @override
  final definition = const ProviderDefinition(
    id: 'vocadb',
    name: 'VocaDB test delegate',
    capabilities: {'catalog', 'lyrics'},
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
  }) async => SourceResult(candidate: candidate, body: 'Invented lyric body');
}

class _ConflictingRecordingIdProvider
    implements LyricsProvider, PublishedTitleAliasEvidence {
  @override
  final definition = const ProviderDefinition(
    id: 'publisher',
    name: 'Publisher test provider',
    capabilities: {'catalog', 'lyrics'},
  );

  final candidate = const SongCandidate(
    providerId: 'publisher',
    id: '502',
    title: _canonical,
    artist: _artist,
    recordingIds: {'musicbrainz': 'different-recording'},
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
  }) async => SourceResult(candidate: candidate, body: 'Invented lyric body');

  @override
  String? publishedTitleAliasForSelection(
    SongCandidate selection,
    SongCandidate candidate,
  ) => candidate.providerId == definition.id && selection.title == _japanese
      ? _japanese
      : null;
}

class _DetailEditionAliasProvider
    implements LyricsProvider, PublishedTitleAliasEvidence {
  _DetailEditionAliasProvider({
    this.metadata = const {},
    this.extra = const {},
  });
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> extra;
  @override
  final definition = const ProviderDefinition(
    id: 'publisher',
    name: 'Publisher test provider',
    capabilities: {'catalog', 'lyrics'},
  );
  final candidate = const SongCandidate(
    providerId: 'publisher',
    id: '503',
    title: _canonical,
    artist: _artist,
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
  }) async => SourceResult(
    candidate: candidate,
    body: 'Invented lyric body',
    metadata: metadata,
    extra: extra,
  );
  @override
  String? publishedTitleAliasForSelection(
    SongCandidate selection,
    SongCandidate candidate,
  ) => '$_japanese (Studio)';
}

void main() {
  for (final alias in [_japanese, _romaji]) {
    test(
      'configured VocaDB provider matches published alias $alias without rewriting source',
      () async {
        final transport = _transport((request) async {
          if (request.url.path == '/api/songs') {
            return _response({
              'items': [_entry()],
            });
          }
          return _response(_entry());
        });
        final configured = _configured(
          VocaDbProvider(transport, requestInterval: Duration.zero),
        );
        addTearDown(transport.close);
        final selection = SongCandidate(
          providerId: 'library',
          id: 'recording-local',
          title: alias,
          artist: _artist,
          album: 'Imaginary Album',
          durationSeconds: 201,
        );

        final result = await findMatchingSource(configured, selection);

        expect(result.matchKind, MatchKind.sameSong);
        expect(result.candidate.title, _canonical);
        expect(result.candidate.metadata['vocadbSongId'], '501');
        expect(result.candidate.extra['sourceTitleAliases'], [
          _canonical,
          _japanese,
          _romaji,
        ]);
        expect(result.candidate.recordingIds, isEmpty);
        expect(result.timingTracks, isEmpty);
        expect(result.extra['sourceTitleAliasEvidence'], {
          'sourceId': '501',
          'canonicalTitle': _canonical,
          'selectedTitle': alias,
          'publishedAlias': alias,
        });
        expect(result.extra['requiresLyricsAgreement'], isNot(true));
      },
    );
  }

  test(
    'wrong artist, album, duration, or edition do not gain alias matching',
    () async {
      for (final selection in [
        const SongCandidate(
          providerId: 'library',
          id: 'local',
          title: _japanese,
          artist: 'Wrong Invented Artist',
          album: 'Imaginary Album',
          durationSeconds: 201,
        ),
        const SongCandidate(
          providerId: 'library',
          id: 'local',
          title: _japanese,
          artist: _artist,
          album: 'Wrong Imaginary Album',
          durationSeconds: 201,
        ),
        const SongCandidate(
          providerId: 'library',
          id: 'local',
          title: _japanese,
          artist: _artist,
          album: 'Imaginary Album',
          durationSeconds: 250,
        ),
        const SongCandidate(
          providerId: 'library',
          id: 'local',
          title: _japanese,
          artist: _artist,
          album: 'Imaginary Album (Remastered)',
          durationSeconds: 201,
        ),
      ]) {
        final transport = _transport((request) async {
          return _response({
            'items': [_entry()],
          });
        });
        final configured = _configured(
          VocaDbProvider(transport, requestInterval: Duration.zero),
        );
        addTearDown(transport.close);
        await expectLater(
          findMatchingSource(configured, selection),
          throwsA(isA<ProviderException>()),
        );
      }
    },
  );

  test(
    'unpublished foreign title cannot match through contextual title search',
    () async {
      final transport = _transport(
        (request) async => _response({
          'items': [_entry()],
        }),
      );
      final configured = _configured(
        VocaDbProvider(transport, requestInterval: Duration.zero),
      );
      addTearDown(transport.close);
      await expectLater(
        findMatchingSource(
          configured,
          const SongCandidate(
            providerId: 'library',
            id: 'local',
            title: 'Unpublished invented title',
            artist: _artist,
          ),
        ),
        throwsA(isA<ProviderException>()),
      );
    },
  );

  test(
    'declarative alias metadata cannot spoof optional publisher evidence',
    () async {
      const candidate = SongCandidate(
        providerId: 'vocadb',
        id: '501',
        title: _canonical,
        artist: _artist,
        extra: {
          'sourceTitleAliases': [_canonical, _japanese],
        },
      );
      final configured = _configured(_StaticAliasProvider(candidate));
      expect(configured, isA<PublishedTitleAliasEvidence>());
      expect(
        (configured as PublishedTitleAliasEvidence)
            .publishedTitleAliasForSelection(
              _selectionArtistAlbumDuration,
              candidate,
            ),
        isNull,
      );
      await expectLater(
        findMatchingSource(configured, _selectionArtistAlbumDuration),
        throwsA(isA<ProviderException>()),
      );
    },
  );

  test(
    'conflicting recording IDs remain disqualifying for an alias title',
    () async {
      final provider = _ConflictingRecordingIdProvider();
      await expectLater(
        findMatchingSource(
          provider,
          const SongCandidate(
            providerId: 'library',
            id: 'local',
            title: _japanese,
            artist: _artist,
            recordingIds: {'musicbrainz': 'selected-recording'},
          ),
        ),
        throwsA(isA<ProviderException>()),
      );
    },
  );

  test(
    'published alias cannot erase a contradictory canonical title edition',
    () async {
      final transport = _transport(
        (request) async => _response({
          'items': [
            _entry(
              title: '$_canonical (Live)',
              aliases: const ['$_japanese (Studio)'],
            ),
          ],
        }),
      );
      addTearDown(transport.close);
      await expectLater(
        findMatchingSource(
          _configured(
            VocaDbProvider(transport, requestInterval: Duration.zero),
          ),
          const SongCandidate(
            providerId: 'library',
            id: 'local',
            title: '$_japanese (Studio)',
            artist: _artist,
          ),
        ),
        throwsA(isA<ProviderException>()),
      );
    },
  );

  for (final facts in ['metadata', 'extra']) {
    test(
      'resolved $facts edition cannot be hidden by a published alias',
      () async {
        final provider = _DetailEditionAliasProvider(
          metadata: facts == 'metadata' ? {'edition': 'Live'} : const {},
          extra: facts == 'extra' ? {'edition': 'Live'} : const {},
        );
        final result = await findMatchingSource(
          provider,
          const SongCandidate(
            providerId: 'library',
            id: 'local',
            title: '$_japanese (Studio)',
            artist: _artist,
          ),
        );
        expect(result.matchKind, MatchKind.rejected);
        expect(result.matchReason, 'identity_mismatch');
        expect(result.extra.containsKey('sourceTitleAliasEvidence'), isFalse);
      },
    );
  }

  test(
    'alias removed from resolved detail is rejected after successful search',
    () async {
      var detailRequested = false;
      final transport = _transport((request) async {
        if (request.url.path == '/api/songs') {
          return _response({
            'items': [_entry()],
          });
        }
        detailRequested = true;
        return _response(_entry(aliases: const [_canonical]));
      });
      final configured = _configured(
        VocaDbProvider(transport, requestInterval: Duration.zero),
      );
      addTearDown(transport.close);
      final result = await findMatchingSource(
        configured,
        _selectionArtistAlbumDuration,
      );
      expect(detailRequested, isTrue);
      expect(result.matchKind, MatchKind.rejected);
      expect(result.matchReason, 'identity_mismatch');
      expect(result.extra.containsKey('sourceTitleAliasEvidence'), isFalse);
    },
  );
}
