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
import 'package:singbook/providers/extra/wikibooks_liederbuch.dart';
import 'package:singbook/providers/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Invented song sheets; no publisher lyric text or captured response is shipped.
const _sheets = [
  (id: 7123, title: 'Morgenwind am Silberhang', chord: 'H', normalized: 'B'),
  (id: 7124, title: 'Blaue Laternen im Garten', chord: 'B', normalized: 'Bb'),
];

Map<String, Object?> _page(int index) {
  final sheet = _sheets[index];
  return {
    'parse': {
      'pageid': sheet.id,
      'title': 'Liederbuch/ ${sheet.title}',
      'revid': 98765 + index,
      'displaytitle': sheet.title,
      'categories': [
        {'category': 'Liederbuch/_Lieder'},
        {'category': 'Liederbuch/_Lieder_auf_Deutsch'},
      ],
      'properties': [],
      'text':
          '''
<div class="mw-parser-output">
<p>Text: Liora Fen (synthetic fixture)<br>Melodie: K. Tarel (synthetic fixture)</p>
<h2>Erste Strophe</h2>
<div class="poem"><p><span style="vertical-align:50%;font-family:sans-serif;font-weight:bold">[${sheet.chord}]</span>Sieben blaue Laternen leuchten.<br>Ein kupferner Mond bewacht den Garten.</p></div>
<ol class="references"><li><span class="reference-text">Invented source note.</span></li></ol>
</div>''',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test(
    'Wikibooks controller saves exact revision and rights across reopen and export',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'singbook-wikibooks-flow-',
      );
      final path = '${directory.path}/library.sqlite';
      var repository = await LibraryRepository.open(
        path: path,
        factory: databaseFactoryFfi,
      );
      final replies = <int, List<int>>{};
      var calls = 0;
      final transport = ProviderTransport(
        client: MockClient((request) async {
          calls++;
          expect(request.method, 'GET');
          expect(request.url.host, 'de.wikibooks.org');
          expect(request.url.path, '/w/api.php');
          final q = request.url.queryParameters;
          expect(q['formatversion'], '2');
          expect(q['maxlag'], '5');
          if (q['action'] == 'query') {
            expect(q['srlimit'], '10');
            final sheet = _sheets.singleWhere(
              (s) => q['srsearch'] == '${s.title} prefix:Liederbuch/',
            );
            return http.Response(
              jsonEncode({
                'query': {
                  'search': [
                    {
                      'pageid': sheet.id,
                      'ns': 0,
                      'title': 'Liederbuch/ ${sheet.title}',
                    },
                  ],
                },
              }),
              200,
            );
          }
          expect(q['action'], 'parse');
          final id = int.parse(q['pageid']!);
          final bytes = utf8.encode(
            jsonEncode(_page(_sheets.indexWhere((s) => s.id == id))),
          );
          replies[id] = bytes;
          return http.Response.bytes(bytes, 200);
        }),
        maxRetries: 0,
        hostInterval: Duration.zero,
      );
      AppController? app;
      try {
        final provider = WikibooksLiederbuchProvider(transport);
        app = AppController(
          repository: repository,
          discovery: SourceDiscoveryService([provider]),
        );
        await app.initialize();
        expect(await repository.listSongs(), isEmpty);
        expect(app.providerEnabled(provider.definition.id), false);
        await app.setProviderEnabled(provider.definition.id, true);
        app.settings['catalog'] = provider.definition.id;
        final savedDocuments = <String, Map<String, dynamic>>{};
        for (final sheet in _sheets) {
          await app.search(sheet.title);
          final candidate = app.suggestions.single;
          expect(candidate.id, '${sheet.id}');
          await app.selectCandidate(candidate);
          final result = app.results.single;
          expect(result.matchKind, MatchKind.sameSong);
          expect(result.body, contains('[${sheet.normalized}]Sieben'));
          expect(
            result.metadata['wikibooksRevisionId'],
            98765 + _sheets.indexOf(sheet),
          );
          expect(result.candidate.artist, isEmpty);
          expect(result.candidate.recordingIds, isEmpty);
          expect(result.timingTracks, isEmpty);

          final saved = await app.saveResult();
          final source = saved.sources.single;
          expect(source.body, result.body);
          expect(source.metadata, result.metadata);
          expect(source.extra, result.extra);
          expect(source.attribution, result.attribution);
          expect(source.attribution, contains('converted to ChordPro'));
          expect(source.extra['rights']['license'], 'unknown');
          expect(
            source.extra['rights']['permissions']['pageContributions'],
            'CC-BY-SA-4.0',
          );
          expect(
            source.extra['rights']['permissions']['underlyingLyricsAndMusic'],
            'unknown',
          );
          final original = source.extra['originalPayload'];
          expect(base64Decode(original['base64']), replies[sheet.id]);
          expect(
            original['sha256'],
            sha256.convert(replies[sheet.id]!).toString(),
          );
          final portable = ChordProCodec().decode(
            ChordProCodec().encode(saved),
          );
          expect(portable.sources.single.toJson(), source.toJson());
          expect(portable.body, saved.body);
          savedDocuments[saved.id] = saved.toJson();
        }
        expect(calls, 4);
        await app.setProviderEnabled(provider.definition.id, false);
        expect(await repository.listSongs(), hasLength(2));
        app.dispose();
        app = null;
        await repository.close();
        repository = await LibraryRepository.open(
          path: path,
          factory: databaseFactoryFfi,
        );
        final reopened = await repository.listSongs();
        expect(reopened, hasLength(2));
        for (final song in reopened) {
          expect(song.toJson(), savedDocuments[song.id]);
        }
        app = AppController(
          repository: repository,
          discovery: SourceDiscoveryService([
            WikibooksLiederbuchProvider(transport),
          ]),
        );
        await app.initialize();
        expect(app.providerEnabled(provider.definition.id), false);
        expect(app.songs, hasLength(2));
        expect(
          calls,
          4,
          reason:
              'Reopening saved documents and preferences needs no source request',
        );
      } finally {
        app?.dispose();
        await repository.close();
        await transport.close();
        // Only this test's freshly created, isolated database directory is removed.
        await directory.delete(recursive: true);
      }
    },
  );
}
