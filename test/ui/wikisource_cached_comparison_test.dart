import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  sqfliteFfiInit();

  for (final enabled in [false, true]) {
    for (final combined in [false, true]) {
      test('old explicit rejection reopens and re-saves with '
          '${enabled ? 'offline' : 'disabled'} provider / '
          '${combined ? 'combined' : 'source'} choice', () async {
        final provider = _ReplyProvider(() async {
          throw const ProviderException('network');
        });
        final h = await _LibraryHarness.open(provider: provider);
        addTearDown(h.close);
        final original = _fixture();
        await h.app.setSetting('providers', {'wikisource': enabled});
        await h.ui.openSong(original.id);
        await h.ui.compareCurrentSongVersions();
        expect(provider.calls, enabled ? 1 : 0);
        expect(h.app.combined, isNotNull);
        expect(h.app.combined!.body, original.body);
        expect(h.app.combined!.artist, 'Writer');
        expect(h.app.results.single.matchKind, MatchKind.rejected);
        expect(h.app.results.single.matchReason, 'identity_mismatch');
        expect(h.app.results.single.toJson(), original.sources.single.toJson());
        expect(recordingCompatible(h.app.selection!, h.app.results.single), isFalse);
        if (enabled) expect(h.app.checks['wikisource']!.code, 'network');
        // Comparing never rewrites the existing reader body or fills its author.
        expect((await h.repository.getSong(original.id))!.toJson(), original.toJson());
        h.ui.selectVersion(combined ? 'combined' : original.sources.single.id);
        await h.ui.saveSelectedVersion();
        expect(h.ui.state.route, VerseRoute.reader);
        expect(h.ui.state.song!.id, original.id);
        await h.reopen();
        final restored = await h.repository.getSong(original.id);
        expect(restored!.body, original.body);
        expect(restored.artist, 'Writer');
        expect(restored.selectedRecording!.toJson(), original.selectedRecording!.toJson());
        expect(restored.sources.single.toJson(), original.sources.single.toJson());
        expect(restored.sources.single.metadata.containsKey('resolvedPageId'), isFalse);
        expect(restored.sources.single.matchKind, MatchKind.rejected);
        expect((await h.repository.listSongs()), hasLength(1));
        expect((await h.repository.getSetlist('legacy-setlist'))!
            .entries.single.songId, original.id);
      });
    }
  }

  test('unproven equal-payload fresh result never displaces authorized cache', () async {
    final h = await _LibraryHarness.open(provider: _ReplyProvider(
      () async => SourceResult.fromJson(_fixture().sources.single.toJson()),
    ));
    addTearDown(h.close);
    await h.app.setSetting('providers', {'wikisource': true});
    final observedBodies = <String>[];
    void observe() {
      if (h.app.selection != null && h.app.results.isNotEmpty) {
        observedBodies.add(h.app.combined?.body ?? 'UNUSABLE');
      }
    }
    h.app.addListener(observe);
    await h.ui.openSong(_fixture().id);
    await h.ui.compareCurrentSongVersions();
    h.app.removeListener(observe);
    final check = h.app.checks['wikisource']!;
    expect(check.code, 'identity_mismatch');
    expect(check.result!.matchKind, MatchKind.rejected);
    expect(identical(check.result, h.app.results.single), isFalse);
    expect(observedBodies, isNotEmpty);
    expect(observedBodies, everyElement(_fixture().body));
    expect(h.app.combined!.body, _fixture().body);
    // Ordinary cachedResults do not carry repository provenance.
    await h.app.selectCandidate(_fixture().selectedRecording!,
      cachedResults: _fixture().sources,
    );
    expect(h.app.combined, isNull);
    await expectLater(h.app.saveResult(source: h.app.results.single,
      allowRejectedSource: true), throwsA(isA<FormatException>()));
  });

  test('proven fresh replacement uses its own page facts and retains old history', () async {
    final h = await _LibraryHarness.open(provider: _ReplyProvider(
      () async => _fresh(),
    ));
    addTearDown(h.close);
    await h.app.setSetting('providers', {'wikisource': true});
    await h.ui.openSong(_fixture().id);
    await h.ui.compareCurrentSongVersions();
    final fresh = h.app.results.single;
    expect(fresh.matchReason, 'explicit_historical_work');
    expect(fresh.metadata['revision'], 124);
    expect(h.app.combined!.body, fresh.body);
    final saved = await h.app.saveResult(source: fresh);
    expect(saved.id, _fixture().id);
    await h.reopen();
    final restored = (await h.repository.getSong(saved.id))!;
    expect(restored.body, _fresh().body);
    expect(restored.sources.any((source) => source.body == _fixture().body &&
        source.matchKind == MatchKind.rejected), isTrue);
    expect(restored.sources.any((source) => source.metadata['resolvedPageId'] == '7' &&
        source.metadata['revision'] == 124), isTrue);
  });

  for (final bad in ['page', 'edition', 'author', 'rights']) {
    test('fresh $bad mismatch leaves saved page available and exposes failure', () async {
      final h = await _LibraryHarness.open(provider: _ReplyProvider(() async {
        final json = _fresh().toJson();
        final candidate = json['candidate'] as JsonMap;
        switch (bad) {
          case 'page': candidate['id'] = '8'; break;
          case 'edition': candidate['title'] = 'Example Text (Other Edition)'; break;
          case 'author': candidate['artist'] = 'Other Writer'; break;
          case 'rights': json.remove('rights'); break;
        }
        return SourceResult.fromJson(json);
      }));
      addTearDown(h.close);
      await h.app.setSetting('providers', {'wikisource': true});
      // Known author guard is tested using an accepted legacy source whose
      // persisted reference already has that author, rather than author guessing.
      if (bad == 'author') {
        final json = _fixture().toJson();
        (json['selectedRecording'] as JsonMap)['artist'] = 'Writer';
        final source = (json['sources'] as List).single as JsonMap;
        source['matchKind'] = 'sameSong';
        source['matchReason'] = 'same_song';
        await h.repository.saveSong(SongDocument.fromJson(json));
        await h.reopen();
      }
      await h.ui.openSong(_fixture().id);
      await h.ui.compareCurrentSongVersions();
      expect(h.app.combined!.body, _fixture().body);
      expect(h.app.results.single.metadata.containsKey('resolvedPageId'), isFalse);
      expect(h.app.checks['wikisource']!.state, isNot('found'));
      expect(explicitHistoricalWorkMatches(
        h.app.selection!, h.app.checks['wikisource']!.result!,
      ), isFalse);
    });
  }

  for (final invalid in [
    'source missing', 'candidate missing', 'emitted missing', 'null', 'zero',
    'negative', 'string', 'double', 'candidate double', 'candidate mismatch',
    'source mismatch', 'emitted mismatch', 'emitted integer',
  ]) {
    test('invalid fresh $invalid revision retains cache during progress and final merge', () async {
      final h = await _LibraryHarness.open(provider: _ReplyProvider(() async {
        final json = _fresh().toJson();
        final found = (json['candidate'] as JsonMap)['metadata'] as JsonMap;
        final metadata = json['metadata'] as JsonMap;
        switch (invalid) {
          case 'source missing': metadata.remove('revision'); break;
          case 'candidate missing': found.remove('revision'); break;
          case 'emitted missing': json.remove('revision'); break;
          case 'null': metadata['revision'] = null; break;
          case 'zero': metadata['revision'] = 0; break;
          case 'negative': metadata['revision'] = -1; break;
          case 'string': metadata['revision'] = '124'; break;
          case 'double': metadata['revision'] = 124.0; break;
          case 'candidate double': found['revision'] = 124.0; break;
          case 'candidate mismatch': found['revision'] = 125; break;
          case 'source mismatch': metadata['revision'] = 125; break;
          case 'emitted mismatch': json['revision'] = '125'; break;
          case 'emitted integer': json['revision'] = 124; break;
        }
        final result = SourceResult.fromJson(json);
        // Revision alone is malformed. These remain the correct own-page facts
        // and rights so the case cannot accidentally retest a page mismatch.
        expect(result.candidate.id, '7');
        expect(result.candidate.title, 'Example Text');
        expect(result.metadata['resolvedPageId'], '7');
        expect(result.candidate.metadata['resolvedPageId'], '7');
        expect(result.extra['rights']['license'], 'Template:PD-old');
        return result;
      }));
      addTearDown(h.close);
      await h.app.setSetting('providers', {'wikisource': true});
      final bodies = <String>[];
      void observe() {
        if (h.app.results.isNotEmpty) {
          bodies.add(h.app.combined?.body ?? 'UNUSABLE');
        }
      }
      h.app.addListener(observe);
      await h.ui.openSong(_fixture().id);
      await h.ui.compareCurrentSongVersions();
      h.app.removeListener(observe);
      expect(bodies, isNotEmpty);
      expect(bodies, everyElement(_fixture().body));
      expect(h.app.results.single.toJson(), _fixture().sources.single.toJson());
      expect(h.app.combined!.body, _fixture().body);
      expect(h.app.checks['wikisource']!.state, 'failed');
      expect(h.app.checks['wikisource']!.code, 'validation_rejected');
      expect(explicitHistoricalWorkMatches(h.app.selection!,
        h.app.checks['wikisource']!.result!,
      ), isFalse);
      expect((await h.repository.getSong(_fixture().id))!.toJson(), _fixture().toJson());
    });
  }

  test('save captures cache origin before cancellation and late fresh completion', () async {
    final pending = Completer<SourceResult>();
    final provider = _ReplyProvider(() => pending.future);
    final h = await _LibraryHarness.open(provider: provider);
    addTearDown(h.close);
    await h.app.setSetting('providers', {'wikisource': true});
    await h.ui.openSong(_fixture().id);
    final refresh = h.ui.compareCurrentSongVersions();
    await provider.started.future;
    expect(h.app.discovering, isTrue);
    final save = h.app.saveResult(source: h.app.results.single,
      allowRejectedSource: true,
    );
    h.app.cancelSearch();
    pending.complete(_fresh());
    final saved = await save;
    await refresh;
    expect(saved.body, _fixture().body);
    expect(saved.sources.single.matchReason, 'identity_mismatch');
    expect(h.app.selection, isNull);
    expect(h.app.results, isEmpty);
    expect((await h.repository.getSong(saved.id))!.body, _fixture().body);
  });

  test('late repository read cannot open a cancelled saved comparison', () async {
    final h = await _LibraryHarness.open();
    addTearDown(h.close);
    final locked = Completer<void>();
    final unlock = Completer<void>();
    final transaction = h.repository.database.transaction((txn) async {
      locked.complete();
      await unlock.future;
    });
    await locked.future;
    final comparison = h.app.compareSavedSong(_fixture().id,
      expectedReference: _fixture().selectedRecording!,
    );
    h.app.cancelSearch();
    unlock.complete();
    await transaction;
    await comparison;
    expect(h.app.selection, isNull);
    expect(h.app.combined, isNull);
    expect(h.app.results, isEmpty);
  });

  test('mutating nested cache rights after authorization cannot be re-saved', () async {
    final h = await _LibraryHarness.open();
    addTearDown(h.close);
    await h.ui.openSong(_fixture().id);
    await h.ui.compareCurrentSongVersions();
    final source = h.app.results.single;
    (source.extra['rights'] as JsonMap)['license'] = 'changed after capture';
    await expectLater(h.app.saveResult(source: source, allowRejectedSource: true),
      throwsA(isA<FormatException>()));
    expect((await h.repository.getSong(_fixture().id))!
        .sources.single.extra['rights']['license'], 'Template:PD-old');
  });
}

SongDocument _fixture() => SongDocument.fromJson(jsonDecode(
  File('test/fixtures/wikisource_legacy_saved_song.json').readAsStringSync(),
) as JsonMap);

SourceResult _fresh() {
  final json = _fixture().sources.single.toJson();
  final candidate = json['candidate'] as JsonMap;
  for (final facts in [candidate['metadata'] as JsonMap, json['metadata'] as JsonMap]) {
    facts['resolvedPageId'] = '7';
    facts['resolvedTitle'] = 'Example Text';
    facts['revision'] = 124;
  }
  json['revision'] = '124';
  json['body'] = 'Fresh invented text returned for exactly the same historical page';
  json['matchKind'] = 'sameSong';
  json['matchReason'] = 'explicit_historical_work';
  return SourceResult.fromJson(json);
}

class _ReplyProvider implements LyricsProvider {
  _ReplyProvider(this.reply);
  final Future<SourceResult> Function() reply;
  final started = Completer<void>();
  int calls = 0;
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'wikisource', name: 'Wikisource', capabilities: {'catalog', 'lyrics'},
  );
  @override
  Future<List<SongCandidate>> search(String query, {CancellationToken? cancel}) async => [];
  @override
  Future<SourceResult> resolve(SongCandidate candidate, {CancellationToken? cancel}) {
    calls++;
    if (!started.isCompleted) started.complete();
    return reply();
  }
}

class _LibraryHarness {
  _LibraryHarness(this.directory, this.path, this.provider);
  final Directory directory;
  final String path;
  final _ReplyProvider? provider;
  late LibraryRepository repository;
  late AppController app;
  late AppControllerAdapter ui;

  static Future<_LibraryHarness> open({_ReplyProvider? provider}) async {
    final directory = await Directory.systemTemp.createTemp('singbook-old-wikisource-');
    final h = _LibraryHarness(directory, paths.join(directory.path, 'library.sqlite'), provider);
    final seed = await LibraryRepository.open(path: h.path, factory: databaseFactoryFfi);
    final old = _fixture();
    await seed.saveSong(old);
    await seed.saveSetlist(SetlistDocument(id: 'legacy-setlist', name: 'Keep this list',
      entries: [SetlistEntry(id: 'legacy-entry', songId: old.id)],
    ));
    await seed.close();
    await h._start();
    return h;
  }

  Future<void> _start() async {
    repository = await LibraryRepository.open(path: path, factory: databaseFactoryFfi);
    app = AppController(repository: repository,
      discovery: SourceDiscoveryService([if (provider != null) provider!]),
    );
    await app.initialize();
    ui = AppControllerAdapter(app);
  }

  Future<void> reopen() async {
    ui.dispose();
    app.dispose();
    await repository.close();
    await _start();
  }

  Future<void> close() async {
    ui.dispose();
    app.dispose();
    await repository.close();
    await directory.delete(recursive: true);
  }
}
