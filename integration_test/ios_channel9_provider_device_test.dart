// Native iOS qualification for the channel 8 Chords and Tabs provider and the
// explicitly disabled channel 9 OpenScore adapter. HTTP is fixture-only.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart' show deleteDatabase, getDatabasesPath;
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/arrangement.dart' show plainLyrics;
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/extra/openscore_lieder.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/transport.dart';
import 'package:singbook/ui/player/player_screen.dart';
import 'package:singbook/ui/verse_app.dart';

import 'support/ios_screenshots.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'channel 9 keeps Chords and Tabs active through native search, save and ChordPro roundtrip',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_ios_channel9_chords_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      var repository = await LibraryRepository.open(path: databasePath);
      final requests = <http.Request>[];
      final transport = ProviderTransport(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.startsWith('/songs/search/')) {
            return http.Response(_chordsSearchPage, 200);
          }
          if (request.url.path == '/song/name/artist-test-song') {
            return http.Response(_chordsPage, 200);
          }
          // Includes the controller's catalog refresh. It is intentionally
          // unavailable in this fixture-only test; no HTTP reaches the net.
          return http.Response('fixture route unavailable', 503);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      AppController? app;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        app?.dispose();
        await tester.runAsync(() async {
          await transport.close();
          await repository.close();
          await deleteDatabase(databasePath);
        });
      });

      app = AppController(repository: repository, transport: transport);
      await app.initialize();
      final channel9 = app.discovery.catalogClient!.runtime.catalog!;
      final chartEntry = channel9.sources.singleWhere(
        (source) => source.id == 'chordsandtabs',
      );
      expect(chartEntry.isActive, isTrue);
      expect(chartEntry.enabledByDefault, isTrue);
      expect(
        app.discovery.catalogClient!.runtime.providers.any(
          (provider) => provider.definition.id == 'chordsandtabs',
        ),
        isTrue,
      );
      expect(await app.setSearchCatalog('chordsandtabs'), isTrue);

      await tester.pumpWidget(VerseApp(controller: app));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-mode-online')));
      await tester.pumpAndSettle();
      final search = find.byType(TextField).first;
      await tester.tap(search);
      await tester.enterText(search, 'Test Song');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(app.suggestions, hasLength(1));
      expect(app.suggestions.single.providerId, 'chordsandtabs');

      await tester.tap(find.text('Test Song').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('home-search-comparison-counts')),
        findsOneWidget,
      );
      expect(
        app.results.any(
          (source) =>
              source.candidate.providerId == 'chordsandtabs' &&
              source.body == '[C]Morning light[G7] shines.\n[F]Bright skies.',
        ),
        isTrue,
      );
      await captureIosCheckpoint('channel9_chordsandtabs_comparison');
      final save = find.byKey(const ValueKey('save-open-lyrics'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsOneWidget);

      await captureIosCheckpoint('channel9_chordsandtabs_reader');
      final saved = app.songs.single;
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      app = null;
      await repository.close();
      repository = await LibraryRepository.open(path: databasePath);
      final databaseSong = (await repository.getSong(saved.id))!;
      final chartSource = databaseSong.sources.singleWhere(
        (source) => source.candidate.providerId == 'chordsandtabs',
      );
      expect(
        databaseSong.body,
        '[C]Morning light[G7] shines.\n[F]Bright skies.',
      );
      expect(chartSource.body, databaseSong.body);
      expect(chartSource.attribution, 'Chords and Tabs');
      expect(chartSource.metadata['identityScope'], 'arrangement');
      expect(chartSource.metadata['sourceChartType'], 'chords');
      expect(chartSource.metadata['key'], 'C');
      expect(chartSource.extra['parserVersion'], 'chordsandtabs-2');
      expect(chartSource.extra['pageIdentityEvidence'], {
        'basis': 'publisher_canonical',
        'url': 'https://www.chords-and-tabs.net/song/name/artist-test-song',
      });
      expect(
        chartSource.extra['originalPayload']['httpBodyBytesExact'],
        isTrue,
      );
      expect(
        utf8.decode(
          base64Decode(
            chartSource.extra['originalPayload']['base64'] as String,
          ),
        ),
        _chordsPage,
      );
      expect(
        requests.any(
          (request) => request.url.path == '/song/name/artist-test-song',
        ),
        isTrue,
      );

      final codec = ChordProCodec();
      final portable = codec.decode(codec.encode(databaseSong));
      final portableSource = portable.sources.singleWhere(
        (source) => source.candidate.providerId == 'chordsandtabs',
      );
      expect(portable.body, databaseSong.body);
      expect(portableSource.body, chartSource.body);
      expect(portableSource.attribution, chartSource.attribution);
      expect(portableSource.metadata, chartSource.metadata);
      expect(portableSource.extra['rights'], chartSource.extra['rights']);
      expect(
        portableSource.extra['originalPayload'],
        chartSource.extra['originalPayload'],
      );
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 4)),
  );

  testWidgets(
    'explicit OpenScore source preserves composition credit, scoped rights and original text in SQLite and ChordPro',
    (tester) async {
      final databasePath = paths.join(
        await getDatabasesPath(),
        'singbook_ios_channel9_openscore_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      var repository = await LibraryRepository.open(path: databasePath);
      final requests = <http.Request>[];
      final transport = ProviderTransport(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.pathSegments.last == 'index.html' &&
              request.url.host == 'raw.githubusercontent.com') {
            return http.Response(_openScoreIndex, 200);
          }
          if (request.url.pathSegments.last == 'lc123.txt' &&
              request.url.host == 'raw.githubusercontent.com') {
            return http.Response(_openScoreLyrics, 200);
          }
          return http.Response('unexpected fixture path', 404);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await transport.close();
          await repository.close();
          await deleteDatabase(databasePath);
        });
      });

      final catalog9 = SourceCatalog.parse(
        await rootBundle.loadString('config/source-catalog-v9.json'),
      );
      final disabledEntry = catalog9.sources.singleWhere(
        (source) => source.id == 'openscorelieder',
      );
      expect(disabledEntry.status, 'disabled');
      expect(disabledEntry.enabledByDefault, isFalse);

      // This explicit provider call qualifies the adapter without claiming
      // channel 9 exposes it to ordinary discovery or the UI.
      final provider = OpenScoreLiederProvider(transport);
      final candidate = (await provider.search('A Test Song')).single;
      final source = await findMatchingSource(provider, candidate);
      final combined = combineSources(candidate, [
        source,
      ], preferredSourceId: source.id);
      final codec = ChordProCodec();
      final portable = codec.decode(codec.encode(combined));
      await repository.saveSong(portable);
      await repository.close();
      repository = await LibraryRepository.open(path: databasePath);
      final reopened = (await repository.getSong(portable.id))!;
      final retained = reopened.sources.singleWhere(
        (item) => item.candidate.providerId == 'openscorelieder',
      );
      final rights = retained.extra['rights'] as Map;

      expect(source.candidate.metadata['identityScope'], 'composition');
      expect(source.candidate.metadata['artistCreditRole'], 'composer');
      expect(source.candidate.metadata['credits'], [
        {'role': 'Composer', 'name': 'Writer, Example'},
        {'role': 'Lyricist', 'name': 'A Poet'},
      ]);
      expect(source.candidate.recordingIds, isEmpty);
      expect(source.hasChords, isFalse);
      expect(plainLyrics(reopened.body), _openScoreLyrics.trim());
      expect(retained.body, source.body);
      expect(
        retained.attribution,
        'Writer, Example; OpenScore Lieder contributors',
      );
      expect(rights['license'], 'unknown');
      expect(rights['permissions'], {
        'status': 'field_specific',
        'corpus': 'CC0-1.0',
        'corpusLicenseScope': 'publisher_contributed_corpus',
        'corpusLicenseUrl':
            'https://github.com/OpenScore/Lieder/blob/main/LICENSE.txt',
        'lyrics': 'unknown',
        'underlyingPoemsAndTranslations': 'unknown',
      });
      expect(retained.metadata, source.metadata);
      expect(
        retained.extra['originalPayload'],
        source.extra['originalPayload'],
      );
      expect(
        retained.extra['originalPayload']['base64'],
        base64Encode(utf8.encode(_openScoreLyrics)),
      );
      expect(
        retained.extra['originalPayload']['sha256'],
        sha256.convert(utf8.encode(_openScoreLyrics)).toString(),
      );
      expect(requests, hasLength(2));
      expect(requests.map((request) => request.url.host).toSet(), {
        'raw.githubusercontent.com',
      });
      expect(requests.map((request) => request.url.pathSegments.last), [
        'index.html',
        'lc123.txt',
      ]);
      expect(
        requests.last.url.pathSegments,
        Uri.parse(
          'https://raw.githubusercontent.com$_openScoreTextPath',
        ).pathSegments,
      );
    },
    skip: !Platform.isIOS,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

const _chordsSearchPage = '''
<form role="search" action="/songs/search/" method="post">
  <input name="search">
</form>
<a href="/song/name/artist-test-song">
  <span class="songtype typechords">chords</span>
  <b>Artist - Test Song</b>
</a>
''';

const _chordsPage = '''
<!doctype html>
<html><head>
<link rel="canonical" href="https://www.chords-and-tabs.net/song/name/artist-test-song">
<script type="application/ld+json">{"@type":"MusicRecording","name":"Test Song","byArtist":{"@type":"MusicGroup","name":"Artist"}}</script>
</head><body>
<h1><a>Artist</a> - Test Song</h1>
<span class="songtype typechords">chords</span>
<div id="snippet--snippetXteView" class="xte-view">
<span class="x-badge">Key: C</span>
<span class="x-badge">Tuning: E A D G B E</span>
<div class="song"><sup>C</sup>Morning light<sup>G7</sup> shines.</div>
<div class="song"><sup>F</sup>Bright skies.</div>
</div>
</body></html>
''';

const _openScoreTextPath =
    '/OpenScore/Lieder/main/scores/Writer%2C_Example/Example_cycle/A_Test_Song/lc123.txt';

const _openScoreLyrics =
    '[Chorus]\n{x_verse: literal poem line}\nMorning light across the sea,\nQuiet evening welcomes me.\n';

const _openScoreIndex = '''<html><table id="catalogue"><thead><tr>
<th>Composer</th><th>Set</th><th>Song</th><th>Lyricist</th>
<th>Language</th><th>Score</th><th>External</th></tr></thead>
<tbody><tr><td>Writer, Example</td><td>Example cycle</td><td>A Test Song</td>
<td>A Poet</td><td>EN</td><td>
<a href="https://raw.githubusercontent.com/OpenScore/Lieder/refs/heads/main/scores/Writer%2C_Example/Example_cycle/A_Test_Song/lc123.mscz?raw=true">MuseScore</a>
</td><td><a href="https://musescore.com/score/123">External</a></td></tr></tbody>
</table></html>''';
