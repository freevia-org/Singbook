import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

const _recordingId = 'synthetic-recording-081';
const _conflictingRecordingId = 'different-synthetic-recording';
const _releaseId = 'synthetic-release-024';
const _title = 'Invented Lantern Song';
const _artist = 'Synthetic Ensemble';
const _album = 'Synthetic Evening Collection';
const _artworkUrl =
    'https://coverartarchive.org/release/synthetic-release-024/front-500';
Map<String, dynamic> _releaseJsonFor(String recordingId) => {
  'id': _releaseId,
  'title': _album,
  'cover-art-archive': {
    'artwork': true,
    'front': true,
    'darkened': false,
    'count': 1,
  },
  'media': [
    {
      'tracks': [
        {
          'recording': {'id': recordingId},
        },
      ],
    },
  ],
};

final _releaseJson = _releaseJsonFor(_recordingId);

class _SyntheticLyrics implements LyricsProvider {
  _SyntheticLyrics(this.selected);

  final SongCandidate selected;
  final resolved = <SongCandidate>[];

  @override
  final definition = const ProviderDefinition(
    id: 'syntheticlyrics',
    name: 'Synthetic Lyrics',
    capabilities: {'catalog', 'lyrics'},
  );

  SongCandidate get _candidate => SongCandidate(
    providerId: definition.id,
    id: 'synthetic-lyric-row',
    title: selected.title,
    artist: selected.artist,
    durationSeconds: 201,
    recordingIds: selected.recordingIds,
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_candidate];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolved.add(candidate);
    return SourceResult(
      candidate: _candidate,
      body: 'Invented first line\nInvented second line',
      matchKind: MatchKind.sameSong,
      attribution: 'Synthetic lyric attribution',
      extra: {'lyricPayloadMarker': 'synthetic-lyrics-only'},
    );
  }
}

class _SyntheticMusicBrainz implements LyricsProvider {
  _SyntheticMusicBrainz({required this.conflictingRecordingId});

  final bool conflictingRecordingId;
  final resolved = <SongCandidate>[];

  @override
  final definition = const ProviderDefinition(
    id: 'musicbrainz',
    name: 'MusicBrainz synthetic metadata',
    capabilities: {'catalog', 'metadata'},
    accessMode: 'noncommercialApi',
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => const [];

  @override
  Future<SourceResult> resolve(
    SongCandidate selection, {
    CancellationToken? cancel,
  }) async {
    resolved.add(selection);
    final recording = conflictingRecordingId
        ? _conflictingRecordingId
        : _recordingId;
    final releaseJson = _releaseJsonFor(recording);
    final candidate = SongCandidate(
      providerId: definition.id,
      id: recording,
      title: selection.title,
      artist: selection.artist,
      album: _album,
      durationSeconds: 201,
      recordingIds: {'musicbrainz': recording},
      metadata: {
        'identityScope': 'recording',
        'musicbrainzRecordingId': recording,
        'releases': [
          {'id': _releaseId, 'title': _album},
        ],
        'musicbrainzReleaseId': _releaseId,
      },
    );
    return SourceResult(
      candidate: candidate,
      body: '',
      metadata: {
        'identityScope': 'recording',
        'album': _album,
        'durationSeconds': 201,
        'artworkUrl': _artworkUrl,
        'musicbrainzReleaseId': _releaseId,
        'artworkAssets': [
          {
            'url': _artworkUrl,
            'sourceUrl': 'https://musicbrainz.org/release/$_releaseId',
            'credit': 'Cover Art Archive synthetic credit',
            'recordingId': _recordingId,
            'releaseId': _releaseId,
            'role': 'frontCoverPreview',
            'rights': {'status': 'unknown'},
          },
        ],
      },
      attribution: 'MusicBrainz synthetic recording metadata',
      extra: {
        'metadataOnly': true,
        'coverArtArchive': {
          'status': 'available',
          'recordingId': _recordingId,
          'releaseId': _releaseId,
          'releaseEvidence': {
            'contentType': 'application/json',
            'provenance': 'normalized MusicBrainz release response',
            'data': releaseJson,
          },
        },
        'musicBrainzCreditMarker': 'synthetic-source-credit',
      },
    );
  }
}

class _Harness {
  _Harness(this.directory, this.repository, this.app);

  final Directory directory;
  final LibraryRepository repository;
  final AppController app;
  bool _appDisposed = false;
  bool _repositoryClosed = false;

  Future<void> closeForReopen() async {
    if (!_appDisposed) {
      app.dispose();
      _appDisposed = true;
    }
    if (!_repositoryClosed) {
      await repository.close();
      _repositoryClosed = true;
    }
  }

  Future<void> close() async {
    await closeForReopen();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}

Future<_Harness> _openHarness({required bool conflictingRecordingId}) async {
  final directory = await Directory.systemTemp.createTemp(
    'singbook-musicbrainz-artwork-',
  );
  final repository = await LibraryRepository.open(
    path: '${directory.path}${Platform.pathSeparator}library.db',
    factory: databaseFactoryFfi,
  );
  final selected = SongCandidate(
    providerId: 'catalog',
    id: 'synthetic-selected-record',
    title: _title,
    artist: _artist,
    durationSeconds: 201,
    // Known recording identity lets only the bound metadata source donate art.
    recordingIds: const {'musicbrainz': _recordingId},
    metadata: const {'identityScope': 'recording'},
  );
  final providers = [
    _SyntheticLyrics(selected),
    _SyntheticMusicBrainz(conflictingRecordingId: conflictingRecordingId),
  ];
  final app = AppController(
    repository: repository,
    discovery: SourceDiscoveryService(providers),
  );
  await app.initialize();
  return _Harness(directory, repository, app);
}

void main() {
  sqfliteFfiInit();

  test(
    'resolved release artwork, source evidence, and lyrics survive save, reopen, and ChordPro roundtrip',
    () async {
      final h = await _openHarness(conflictingRecordingId: false);
      LibraryRepository? reopenedRepository;
      addTearDown(() async {
        if (reopenedRepository != null) await reopenedRepository.close();
        await h.close();
      });
      final selection = SongCandidate(
        providerId: 'catalog',
        id: 'synthetic-selected-record',
        title: _title,
        artist: _artist,
        durationSeconds: 201,
        recordingIds: const {'musicbrainz': _recordingId},
        metadata: const {'identityScope': 'recording'},
      );

      await h.app.selectCandidate(selection);
      final lyricSource = h.app.results.singleWhere(
        (source) => source.candidate.providerId == 'syntheticlyrics',
      );
      final metadataSource = h.app.results.singleWhere(
        (source) => source.candidate.providerId == 'musicbrainz',
      );
      expect(metadataSource.matchKind, MatchKind.sameRecording);
      expect(metadataSource.metadata['artworkUrl'], _artworkUrl);
      expect(metadataSource.metadata['musicbrainzReleaseId'], _releaseId);
      expect(metadataSource.metadata['artworkAssets'].single['rights'], {
        'status': 'unknown',
      });
      expect(
        metadataSource.extra['coverArtArchive']['releaseEvidence']['data'],
        _releaseJson,
      );

      final liveCombined = h.app.combined!;
      expect(liveCombined.body, 'Invented first line\nInvented second line');
      expect(liveCombined.metadata['album'], _album);
      expect(liveCombined.metadata['artworkUrl'], _artworkUrl);
      expect(liveCombined.metadata['musicbrainzReleaseId'], _releaseId);
      expect(liveCombined.extra['fieldOrigins']['album'], metadataSource.id);
      expect(
        liveCombined.extra['fieldOrigins']['artworkUrl'],
        metadataSource.id,
      );
      expect(liveCombined.selectedRecording!.recordingIds, {
        'musicbrainz': _recordingId,
      });
      expect(liveCombined.timingTracks, isEmpty);
      expect(liveCombined.sources.map((source) => source.id).toSet(), {
        lyricSource.id,
        metadataSource.id,
      });
      final combinedMetadataSource = liveCombined.sources.singleWhere(
        (source) => source.id == metadataSource.id,
      );
      expect(combinedMetadataSource.attribution, metadataSource.attribution);
      expect(combinedMetadataSource.metadata, metadataSource.metadata);
      expect(combinedMetadataSource.extra, metadataSource.extra);
      expect(
        combinedMetadataSource.metadata['artworkAssets'].single['rights'],
        {'status': 'unknown'},
      );

      // Saving the selected lyric version still combines its matching metadata
      // donor through AppController's production selected-source save path.
      final saved = await h.app.saveResult(source: lyricSource);
      expect(saved.extra['savedSourceId'], lyricSource.id);
      expect(saved.metadata['artworkUrl'], _artworkUrl);
      final savedMetadataSource = saved.sources.singleWhere(
        (source) => source.id == metadataSource.id,
      );
      expect(savedMetadataSource.attribution, metadataSource.attribution);
      expect(savedMetadataSource.metadata, metadataSource.metadata);
      expect(savedMetadataSource.extra, metadataSource.extra);

      final hashBeforeClose = await h.repository.getSongHash(saved.id);
      final savedJson = saved.toJson();
      await h.closeForReopen();

      reopenedRepository = await LibraryRepository.open(
        path: '${h.directory.path}${Platform.pathSeparator}library.db',
        factory: databaseFactoryFfi,
      );
      final reopened = (await reopenedRepository.getSong(saved.id))!;
      expect(reopened.toJson(), savedJson);
      expect(await reopenedRepository.getSongHash(saved.id), hashBeforeClose);
      final reopenedMetadataSource = reopened.sources.singleWhere(
        (source) => source.id == metadataSource.id,
      );
      expect(reopenedMetadataSource.metadata, metadataSource.metadata);
      expect(reopenedMetadataSource.extra, metadataSource.extra);
      expect(
        reopenedMetadataSource
            .extra['coverArtArchive']['releaseEvidence']['data'],
        _releaseJson,
      );

      final exported = ChordProCodec().encode(reopened);
      final decoded = ChordProCodec().decode(exported);
      expect(decoded.metadata['artworkUrl'], _artworkUrl);
      expect(decoded.metadata['musicbrainzReleaseId'], _releaseId);
      expect(decoded.extra['fieldOrigins']['artworkUrl'], metadataSource.id);
      expect(decoded.sources.map((source) => source.id).toSet(), {
        lyricSource.id,
        metadataSource.id,
      });
      final chordProMetadataSource = decoded.sources.singleWhere(
        (source) => source.id == metadataSource.id,
      );
      expect(chordProMetadataSource.metadata, metadataSource.metadata);
      expect(chordProMetadataSource.extra, metadataSource.extra);
      expect(
        chordProMetadataSource
            .extra['coverArtArchive']['releaseEvidence']['data'],
        _releaseJson,
      );
      expect(decoded.timingTracks, isEmpty);
      expect(decoded.selectedRecording!.recordingIds, {
        'musicbrainz': _recordingId,
      });
    },
  );

  test(
    'a conflicting MusicBrainz recording retains source evidence but does not donate artwork',
    () async {
      final h = await _openHarness(conflictingRecordingId: true);
      addTearDown(h.close);
      final selection = SongCandidate(
        providerId: 'catalog',
        id: 'synthetic-selected-record',
        title: _title,
        artist: _artist,
        durationSeconds: 201,
        recordingIds: const {'musicbrainz': _recordingId},
        metadata: const {'identityScope': 'recording'},
      );
      await h.app.selectCandidate(selection);
      final lyricSource = h.app.results.singleWhere(
        (source) => source.candidate.providerId == 'syntheticlyrics',
      );
      final metadataSource = h.app.results.singleWhere(
        (source) => source.candidate.providerId == 'musicbrainz',
      );
      expect(metadataSource.matchKind, MatchKind.rejected);
      expect(metadataSource.metadata['artworkUrl'], _artworkUrl);
      expect(
        metadataSource.extra['coverArtArchive']['releaseEvidence']['data'],
        _releaseJsonFor(_conflictingRecordingId),
      );
      expect(h.app.combined!.metadata.containsKey('artworkUrl'), false);
      expect(
        h.app.combined!.extra['fieldOrigins'].containsKey('artworkUrl'),
        false,
      );

      final saved = await h.app.saveResult(source: lyricSource);
      expect(saved.metadata.containsKey('artworkUrl'), false);
      final retained = saved.sources.singleWhere(
        (source) => source.id == metadataSource.id,
      );
      expect(retained.matchKind, MatchKind.rejected);
      expect(retained.metadata['artworkUrl'], _artworkUrl);
      expect(retained.extra, metadataSource.extra);
      expect(retained.metadata, metadataSource.metadata);
    },
  );
}
