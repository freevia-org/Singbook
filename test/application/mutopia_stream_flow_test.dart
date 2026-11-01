import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/mutopia.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

const _editionId = '501';
const _workTitle = 'Distant Lantern';
const _composer = 'Ada Example';
const _firstWords = 'paper boats drift softly';
const _secondWords = 'quiet windows catch rain';

String _searchRow(String lilypondUrl) =>
    '''<table class="table-bordered result-table"><tbody>
<tr><td>$_workTitle</td><td>by $_composer</td><td></td><td></td></tr>
<tr><td>for Voice, Piano</td><td></td><td>Classical</td><td>C. Example</td></tr>
<tr><td>An invented vocal score, Example Press.</td>
<td><a href="../legal.html#publicdomain">Public Domain</a></td>
<td><a href="piece-info.cgi?id=$_editionId">More Information</a></td>
<td>2026/10/30</td></tr>
<tr><td><a href="$lilypondUrl">.ly file</a></td><td></td><td></td><td></td></tr>
<tr><td>A4 .ps file (gzipped)</td><td>A4 .pdf file</td>
<td>Letter .ps file (gzipped)</td><td>Letter .pdf file</td></tr>
</tbody></table>''';

String _searchPage(String lilypondUrl) =>
    '<html><body><table class="outer-table"><tbody>'
    '<tr><td>${_searchRow(lilypondUrl)}</td></tr>'
    '</tbody></table></body></html>';

String _detailPage(String lilypondUrl) =>
    '''<html><body>
<h2>$_workTitle</h2><h4>by $_composer</h4>
<table class="table table-bordered result-table"><tbody>
<tr><td><b>Instrument(s):</b> Voice, Piano</td><td><b>Style:</b> Classical</td></tr>
<tr><td></td><td><b>Arranger(s):</b> C. Example</td></tr>
<tr><td><b>Opus:</b> Not known</td><td><b>Date of composition:</b> Not known</td></tr>
<tr><td><b>Source:</b> An invented vocal score, Example Press.</td>
<td><b>Copyright:</b> <a href="../legal.html#publicdomain">Public Domain</a>
<a href="http://creativecommons.org/licenses/publicdomain/"></a></td></tr>
<tr><td><b>Last updated:</b> 2026/Oct/30. View change history</td>
<td><b>Music ID Number:</b> Mutopia-2026/10/30-$_editionId</td></tr>
<tr><td><b>Typeset using:</b> LilyPond, version 2.18.2</td><td></td></tr>
</tbody></table>
<table class="table table-bordered result-table"><tbody>
<tr><td><b>Download:</b></td></tr>
<tr><td><a href="$lilypondUrl">LilyPond file</a></td><td>MIDI file</td></tr>
</tbody></table></body></html>''';

String _lilypond() => r'''\version "2.18.2"
\header {
  title = "Distant Lantern"
  mutopiatitle = "Distant Lantern"
  composer = "Ada Example"
  poet = "B. Invented"
  arranger = "C. Example"
  source = "An invented vocal score, Example Press."
  license = "Public Domain"
  footer = "Mutopia-2026/10/30-501"
}
firstLyrics = \lyricmode { paper boats drift softly }
secondLyrics = \lyricmode { quiet windows catch rain }
\score {
  \new Lyrics \lyricsto "voice" \firstLyrics
  \new Lyrics \lyricsto "voice" \secondLyrics
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'named Mutopia lyric streams remain distinct through save and reopen',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp(
        'singbook-mutopia-flow-',
      );
      final path = '${directory.path}${Platform.pathSeparator}library.sqlite';
      var repository = await LibraryRepository.open(
        path: path,
        factory: databaseFactoryFfi,
      );
      final lilypondUrl =
          'https://www.mutopiaproject.org/ftp/Example/Distant/Distant.ly';
      final searchBytes = utf8.encode(_searchPage(lilypondUrl));
      final detailBytes = utf8.encode(_detailPage(lilypondUrl));
      final lilypondBytes = utf8.encode(_lilypond());
      final transport = ProviderTransport(
        client: MockClient((request) async {
          if (request.url.host != 'www.mutopiaproject.org') {
            fail('Unexpected host ${request.url.host}');
          }
          if (request.url.path == '/cgibin/make-table.cgi') {
            return http.Response.bytes(searchBytes, 200);
          }
          if (request.url.path == '/cgibin/piece-info.cgi') {
            expect(request.url.queryParameters['id'], _editionId);
            return http.Response.bytes(detailBytes, 200);
          }
          if (request.url == Uri.parse(lilypondUrl)) {
            return http.Response.bytes(lilypondBytes, 200);
          }
          fail('Unexpected Mutopia fixture URL ${request.url}');
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final provider = MutopiaProvider(transport);
      final app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([provider]),
      );
      final ui = AppControllerAdapter(app);
      var disposed = false;
      try {
        await app.initialize();
        await app.setProviderEnabled('mutopia', true);
        await app.setSearchCatalog('mutopia');
        ui.setHomeListMode(HomeListMode.online);
        ui.setQuery(_workTitle);
        await ui.submitSearch();

        expect(ui.state.searchCatalogId, 'mutopia');
        final references = ui.state.autocomplete;
        expect(references, hasLength(2));
        expect(references.map((item) => item.title).toSet(), {_workTitle});
        expect(references.map((item) => item.artist).toSet(), {_composer});
        expect(references.map((item) => item.sourceVariantLabel).toSet(), {
          'firstLyrics',
          'secondLyrics',
        });
        expect(references.map((item) => item.id).toSet(), {
          'mutopia:$_editionId:firstLyrics',
          'mutopia:$_editionId:secondLyrics',
        });

        final secondReference = references.singleWhere(
          (item) => item.sourceVariantLabel == 'secondLyrics',
        );
        await ui.selectReference(secondReference);
        expect(app.selection?.id, '$_editionId:secondLyrics');
        final source = app.results.single;
        expect(source.id, 'mutopia:$_editionId:secondLyrics');
        expect(source.matchKind, MatchKind.sameSong);
        expect(source.matchKind, isNot(MatchKind.sameRecording));
        expect(source.body, _secondWords);
        expect(source.body, isNot(contains(_firstWords)));
        expect(source.candidate.metadata['sourceVariantLabel'], 'secondLyrics');
        expect(source.candidate.metadata['identityScope'], 'arrangement');
        expect(source.candidate.recordingIds, isEmpty);
        expect(source.hasChords, isFalse);
        expect(source.timingTracks, isEmpty);
        expect(source.metadata.containsKey('language'), isFalse);
        expect(source.metadata.containsKey('key'), isFalse);
        expect(source.metadata.containsKey('tempo'), isFalse);
        expect(source.candidate.metadata.containsKey('language'), isFalse);
        expect(source.candidate.metadata.containsKey('key'), isFalse);
        expect(source.candidate.metadata.containsKey('tempo'), isFalse);
        final pendingSource = source.copyWith(
          extra: {...source.extra, 'pendingMatchCheck': true},
        );
        app.results = [pendingSource];
        ui.setSearchFilter('language', '');
        expect(
          ui.state.comparison!.alternatives
              .singleWhere((item) => item.id == source.id)
              .canSave,
          isFalse,
        );
        await expectLater(
          app.saveResult(source: pendingSource),
          throwsStateError,
        );
        expect(await repository.listSongs(), isEmpty);
        app.results = [source];
        ui.setSearchFilter('language', '');

        final selectedVersion = ui.state.comparison!.alternatives.singleWhere(
          (item) => item.id == source.id,
        );
        expect(selectedVersion.metadata['sourceVariantLabel'], 'secondLyrics');
        expect(selectedVersion.hasChords, isFalse);
        expect(selectedVersion.hasTiming, isFalse);
        expect(selectedVersion.metadata.containsKey('language'), isFalse);
        expect(selectedVersion.metadata.containsKey('key'), isFalse);
        expect(selectedVersion.metadata.containsKey('tempo'), isFalse);
        expect(
          selectedVersion.bodyLines.map((line) => line.text).join('\n'),
          _secondWords,
        );

        // An adapter should display a label only when publisher identity fields
        // agree. Keep each forged candidate based on the real found source.
        final originalResults = List<SourceResult>.of(app.results);
        for (final altered in <SongCandidate>[
          SongCandidate.fromJson({
            ...source.candidate.toJson(),
            'metadata': {
              ...source.candidate.metadata,
              'sourceVariantLabel': 'firstLyrics',
            },
          }),
          SongCandidate.fromJson({
            ...source.candidate.toJson(),
            'metadata': {
              ...source.candidate.metadata,
              'mutopiaEditionId': '502',
            },
          }),
          SongCandidate.fromJson({
            ...source.candidate.toJson(),
            'metadata': {
              ...source.candidate.metadata,
              'identityScope': 'composition',
            },
          }),
          SongCandidate.fromJson({
            ...source.candidate.toJson(),
            'providerId': 'fixture',
          }),
        ]) {
          app.results = [
            SourceResult(
              candidate: altered,
              body: source.body,
              metadata: source.metadata,
              timingTracks: source.timingTracks,
              matchKind: source.matchKind,
              extra: source.extra,
            ),
          ];
          app.notifyListeners();
          final projections = ui.state.comparison!.alternatives.where(
            (item) => item.providerId == altered.providerId,
          );
          expect(
            projections.every(
              (item) => item.metadata['sourceVariantLabel'] == null,
            ),
            isTrue,
          );
        }
        app.results = originalResults;
        app.notifyListeners();

        ui.selectVersion(source.id);
        expect(ui.state.comparison!.selectedVersionId, source.id);
        await ui.saveSelectedVersion();
        final secondSong = ui.state.song;
        expect(secondSong, isNotNull);
        expect(ui.state.route, VerseRoute.reader);
        expect(secondSong!.sourceVariantLabel, 'secondLyrics');
        expect(ui.state.readerKey, isNull);
        expect(ui.state.readerTempo, isNull);
        expect(ui.state.readerTimingAvailable, isFalse);
        expect(
          ui.state.songLines.map((line) => line.text).join('\n'),
          _secondWords,
        );
        final secondSaved = app.songs.singleWhere(
          (item) => item.id == secondSong.id,
        );
        expect(secondSaved.body, _secondWords);
        expect(secondSaved.selectedRecording?.id, source.candidate.id);
        final secondCard = ui.state.songs.singleWhere(
          (item) => item.id == secondSong.id,
        );
        expect(secondCard.sourceVariantLabel, 'secondLyrics');
        expect(secondSaved.sources.single.id, source.id);

        final storedSecondSource = secondSaved.sources.single;
        final payloads = storedSecondSource.extra['originalPayloads'] as List;
        expect(payloads, hasLength(2));
        expect(payloads[0]['sha256'], sha256.convert(detailBytes).toString());
        expect(payloads[1]['sha256'], sha256.convert(lilypondBytes).toString());
        expect(base64Decode(payloads[0]['base64'] as String), detailBytes);
        expect(base64Decode(payloads[1]['base64'] as String), lilypondBytes);
        final streamProof =
            (storedSecondSource.extra['mutopia'] as Map)['streams'] as List;
        expect(streamProof, hasLength(2));
        expect(streamProof.map((item) => item['publisherVariable']).toSet(), {
          'firstLyrics',
          'secondLyrics',
        });
        expect(
          streamProof.singleWhere(
            (item) => item['publisherVariable'] == 'firstLyrics',
          )['text'],
          _firstWords,
        );
        expect(
          streamProof.singleWhere(
            (item) => item['publisherVariable'] == 'secondLyrics',
          )['text'],
          _secondWords,
        );

        final chordPro = ChordProCodec().encode(secondSaved);
        final portableSecond = ChordProCodec().decode(chordPro);
        expect(portableSecond.body, _secondWords);
        expect(portableSecond.selectedRecording?.id, source.candidate.id);
        expect(
          portableSecond.sources
              .singleWhere((item) => item.id == source.id)
              .toJson(),
          storedSecondSource.toJson(),
        );

        // An explicit Save updates the preferred version of the same work in
        // place. The earlier text and source evidence must remain archived.
        ui.changeSearchSong();
        ui.setQuery('Distant Lantern lyrics');
        await ui.submitSearch();
        final firstReference = ui.state.autocomplete.singleWhere(
          (item) => item.sourceVariantLabel == 'firstLyrics',
        );
        await ui.selectReference(firstReference);
        expect(app.selection?.id, '$_editionId:firstLyrics');
        final firstSource = app.results.single;
        expect(firstSource.id, 'mutopia:$_editionId:firstLyrics');
        expect(firstSource.body, _firstWords);
        expect(app.combined?.body, _firstWords);
        expect(firstSource.body, isNot(contains(_secondWords)));
        final firstVersion = ui.state.comparison!.alternatives.singleWhere(
          (item) => item.id == firstSource.id,
        );
        expect(firstVersion.metadata['sourceVariantLabel'], 'firstLyrics');
        ui.selectVersion(firstVersion.id);
        await ui.saveSelectedVersion();
        final firstSaved = app.songs.singleWhere(
          (item) => item.id == ui.state.song!.id,
        );

        expect(firstSaved.id, secondSaved.id);
        expect(firstSaved.body, _firstWords);
        expect(firstSaved.selectedRecording?.id, firstSource.candidate.id);
        expect(firstSaved.sources, hasLength(2));
        final archivedSecond = firstSaved.sources.singleWhere(
          (item) => item.id == source.id,
        );
        expect(archivedSecond.body, _secondWords);
        expect(archivedSecond.extra, storedSecondSource.extra);
        expect(firstSaved.extra['previousSavedVersions'], isNotEmpty);
        expect(app.songs, hasLength(1));
        expect(ui.state.songs.map((item) => item.sourceVariantLabel).toSet(), {
          'firstLyrics',
        });

        ui.dispose();
        app.dispose();
        disposed = true;
        await repository.close();
        repository = await LibraryRepository.open(
          path: path,
          factory: databaseFactoryFfi,
        );
        final reopenedSongs = await repository.listSongs();
        expect(reopenedSongs, hasLength(1));
        final reopenedSecond = reopenedSongs.singleWhere(
          (item) => item.id == secondSaved.id,
        );
        expect(reopenedSecond.body, _firstWords);
        expect(reopenedSecond.selectedRecording?.id, firstSource.candidate.id);
        final reopenedSecondSource = reopenedSecond.sources.singleWhere(
          (item) => item.id == source.id,
        );
        expect(reopenedSecondSource.id, source.id);
        expect(reopenedSecondSource.extra, storedSecondSource.extra);
        expect(
          ChordProCodec()
              .decode(ChordProCodec().encode(reopenedSecond))
              .sources
              .singleWhere((item) => item.id == source.id)
              .extra,
          storedSecondSource.extra,
        );
        final reopenedFirst = reopenedSongs.singleWhere(
          (item) => item.id == firstSaved.id,
        );
        expect(reopenedFirst.body, _firstWords);
        expect(
          reopenedFirst.sources.any((item) => item.id == firstSource.id),
          isTrue,
        );
        final restoredApp = AppController(
          repository: repository,
          discovery: SourceDiscoveryService([provider]),
        );
        final restoredUi = AppControllerAdapter(restoredApp);
        try {
          await restoredUi.initialize();
          await restoredUi.openSong(reopenedFirst.id);
          await restoredUi.compareCurrentSongVersions();
          expect(restoredApp.combined?.body, _firstWords);
          final archivedVersion = restoredUi.state.comparison!.alternatives
              .singleWhere((item) => item.id == source.id);
          expect(
            archivedVersion.metadata['sourceVariantLabel'],
            'secondLyrics',
          );
          expect(
            archivedVersion.bodyLines.map((line) => line.text).join(' '),
            contains(_secondWords),
          );
          restoredUi.selectVersion(archivedVersion.id);
          await restoredUi.saveSelectedVersion();
          final switched = await repository.getSong(reopenedFirst.id);
          expect(switched!.body, _secondWords);
          expect(switched.selectedRecording?.id, source.candidate.id);
          expect(restoredUi.state.song?.sourceVariantLabel, 'secondLyrics');
          expect(
            switched.sources.any(
              (item) => item.id == firstSource.id && item.body == _firstWords,
            ),
            isTrue,
          );
          expect(await repository.listSongs(), hasLength(1));
        } finally {
          restoredUi.dispose();
          restoredApp.dispose();
        }
      } finally {
        if (!disposed) {
          ui.dispose();
          app.dispose();
        }
        await transport.close();
        await repository.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
