import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';

void main() {
  sqfliteFfiInit();

  test('legacy fixture follows Author resolution, matcher rejection and explicit source save', () async {
    final expected = SongDocument.fromJson(jsonDecode(File(
      'test/fixtures/wikisource_legacy_saved_song.json',
    ).readAsStringSync()) as JsonMap);
    final transport = ProviderTransport(hostInterval: Duration.zero, maxRetries: 0,
      client: MockClient((request) async => _json(
        request.url.queryParameters['action'] == 'query'
          ? {'query': {'search': [
              {'pageid': 7, 'title': 'Example Text', 'snippet': 'Invented excerpt'},
            ]}}
          : {'parse': {
              'pageid': 7, 'title': 'Example Text', 'revid': 123,
              'templates': [{'title': 'Template:PD-old'}],
              'text': '<a href="/wiki/Author:Writer">Writer</a><div class="poem">'
                  'Invented opening words for a historical text<br>'
                  'Invented closing words kept exactly as saved</div>',
            }},
      )),
    );
    try {
      // This wrapper removes only V2 parsed-page fields, retaining the released
      // resolver shape. The actual shared matcher still rejects the author fill
      // without those fields, reproducing the old branch rather than inventing
      // a successful new import to seed the compatibility fixture.
      final provider = _LegacyResolver(WikisourceProvider(transport));
      final selected = (await provider.search('Example Text')).single;
      final resolved = await provider.resolve(selected);
      expect(selected.toJson(), expected.selectedRecording!.toJson());
      expect(resolved.candidate.artist, 'Writer');
      expect(sameSong(selected, resolved.candidate), isFalse);
      final rejected = await findMatchingSource(provider, selected);
      expect(rejected.matchKind, MatchKind.rejected);
      expect(rejected.matchReason, 'identity_mismatch');
      expect(rejected.toJson(), expected.sources.single.toJson());
      // The baseline allowed an explicit rejected source card to be saved.
      // Project its selected reference/body/source into the old serialized
      // document; do not run the new strict combine gate as a fake old saver.
      final oldExplicitSave = SongDocument(
        id: expected.id, title: selected.title, artist: selected.artist,
        body: rejected.body, sources: [rejected], selectedRecording: selected,
        favorite: expected.favorite, createdAt: expected.createdAt,
        updatedAt: expected.updatedAt, extra: expected.extra,
      );
      expect(oldExplicitSave.toJson(), expected.toJson());
      expect(SongDocument.fromJson(jsonDecode(jsonEncode(oldExplicitSave.toJson()))
          as JsonMap).sources.single.metadata.containsKey('resolvedPageId'), isFalse);
    } finally {
      await transport.close();
    }
  });

  test('search, select, combine, save, and reopen retain historical source facts', () async {
    final temporary = await Directory.systemTemp.createTemp('singbook-wikisource-');
    final databasePath = paths.join(temporary.path, 'library.sqlite');
    LibraryRepository? repository;
    AppController? app;
    ProviderTransport? transport;
    try {
      repository = await LibraryRepository.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );
      transport = _transport();
      final provider = WikisourceProvider(transport);
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([provider]),
      );
      await app.initialize();
      await app.setSetting('providers', {'wikisource': true});

      await app.search('Example Text');
      final selected = app.suggestions.single;
      expect(selected.artist, isEmpty);
      await app.selectCandidate(selected, searchQuery: 'Example Text');

      expect(app.results, hasLength(1));
      expect(app.results.single.matchKind, MatchKind.sameSong);
      expect(app.results.single.matchReason, 'explicit_historical_work');
      expect(app.combined, isNotNull);
      expect(app.combined!.artist, 'Writer');
      expect(app.combined!.selectedRecording!.artist, isEmpty);
      expect(recordingCompatible(selected, app.results.single), isFalse);

      final saved = await app.saveResult();
      expect(saved.artist, 'Writer');
      expect(saved.body, contains('invented short text'));
      expect(saved.sources.single.candidate.id, '7');
      expect(saved.sources.single.metadata['resolvedPageId'], '7');
      expect(saved.sources.single.metadata['revision'], 123);
      expect(saved.sources.single.metadata['copyrightTags'], ['Template:PD-old']);
      expect(saved.sources.single.extra['rights']['sourceId'], '7');

      app.dispose();
      app = null;
      await transport.close();
      transport = null;
      await repository.close();
      repository = null;

      final reopened = await LibraryRepository.open(
        path: databasePath,
        factory: databaseFactoryFfi,
      );
      try {
        final restored = await reopened.getSong(saved.id);
        expect(restored, isNotNull);
        expect(restored!.artist, 'Writer');
        expect(restored.body, saved.body);
        expect(restored.sources.single.candidate.id, '7');
        expect(restored.sources.single.metadata['resolvedPageId'], '7');
        expect(restored.sources.single.metadata['revision'], 123);
        expect(restored.sources.single.metadata['copyrightTags'], ['Template:PD-old']);
        expect(restored.sources.single.extra['rights']['sourceId'], '7');
        expect(recordingCompatible(selected, restored.sources.single), isFalse);
      } finally {
        await reopened.close();
      }
    } finally {
      app?.dispose();
      await transport?.close();
      await repository?.close();
      await temporary.delete(recursive: true);
    }
  });

  test('selected page without rights cannot produce a saveable result', () async {
    final repository = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    final transport = _transport(rights: false);
    final app = AppController(
      repository: repository,
      discovery: SourceDiscoveryService([WikisourceProvider(transport)]),
    );
    try {
      await app.initialize();
      await app.setSetting('providers', {'wikisource': true});
      await app.search('Example Text');
      await app.selectCandidate(app.suggestions.single);
      expect(app.results, isEmpty);
      expect(app.combined, isNull);
      await expectLater(app.saveResult(), throwsA(isA<FormatException>()));
    } finally {
      app.dispose();
      await transport.close();
      await repository.close();
    }
  });
}

class _LegacyResolver implements LyricsProvider {
  _LegacyResolver(this.inner);
  final WikisourceProvider inner;
  @override
  ProviderDefinition get definition => inner.definition;
  @override
  Future<List<SongCandidate>> search(String query, {CancellationToken? cancel}) =>
      inner.search(query, cancel: cancel);
  @override
  Future<SourceResult> resolve(SongCandidate candidate, {CancellationToken? cancel}) async {
    final source = await inner.resolve(candidate, cancel: cancel);
    final json = source.toJson();
    final found = json['candidate'] as JsonMap;
    for (final facts in [found['metadata'] as JsonMap, json['metadata'] as JsonMap]) {
      facts.remove('resolvedPageId');
      facts.remove('resolvedTitle');
    }
    json['retrievedAt'] = '2026-10-22T10:00:00.000Z';
    return SourceResult.fromJson(json);
  }
}

ProviderTransport _transport({bool rights = true}) => ProviderTransport(
  hostInterval: Duration.zero,
  maxRetries: 0,
  client: MockClient((request) async {
    if (request.url.queryParameters['action'] == 'query') {
      return _json({
        'query': {
          'search': [
            {
              'pageid': 7,
              'title': 'Example Text',
              'snippet': 'invented short excerpt',
            },
          ],
        },
      });
    }
    return _json({
      'parse': {
        'pageid': 7,
        'title': 'Example Text',
        'revid': 123,
        'templates': [if (rights) {'title': 'Template:PD-old'}],
        'text':
            '<a href="/wiki/Author:Writer">Writer</a><div class="poem">invented short text</div>',
      },
    });
  }),
);

http.Response _json(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json'},
);
