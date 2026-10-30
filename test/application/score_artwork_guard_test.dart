import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/search_grouping.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

const _score = SongCandidate(
  providerId: 'mutopia',
  id: '4242:firstText',
  title: 'Lantern over the garden',
  artist: 'Example Composer',
  metadata: {'identityScope': 'arrangement', 'artistCreditRole': 'composer'},
);
const _recording = SongCandidate(
  providerId: 'recordings',
  id: 'recording-1',
  title: 'Lantern over the garden',
  artist: 'Example Composer',
  metadata: {'identityScope': 'recording'},
);
const _artwork = 'https://images.example/recording-art.jpg';

class _ArtworkCatalog implements LyricsProvider {
  int searches = 0;
  final searched = Completer<void>();
  @override
  final definition = const ProviderDefinition(
    id: 'lyricsovh',
    name: 'Artwork fixture',
    capabilities: {'catalog', 'metadata'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    searches++;
    if (!searched.isCompleted) searched.complete();
    return const [
      SongCandidate(
        providerId: 'lyricsovh',
        id: 'art-recording',
        title: 'Lantern over the garden',
        artist: 'Example Composer',
        metadata: {'artworkUrl': _artwork},
      ),
    ];
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw const ProviderException('unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test(
    'composer score streams never form a recording group or borrow artwork',
    () {
      final second = SongCandidate(
        providerId: 'mutopia',
        id: '4242:secondText',
        title: _score.title,
        artist: _score.artist,
        metadata: _score.metadata,
      );
      final groups = groupSearchRecordings([_score, second, _recording]);
      expect(groups, hasLength(3));
      expect(groups.every((group) => group.members.length == 1), isTrue);
      expect(sameSearchRecording(_score, _recording), isFalse);
      expect(sameSearchRecording(_score, _score), isFalse);
      const ordinaryChart = SongCandidate(
        providerId: 'chordie',
        id: 'chart-1',
        title: 'Lantern over the garden',
        artist: 'Example Composer',
        metadata: {'identityScope': 'arrangement'},
      );
      expect(sameSearchRecording(ordinaryChart, _recording), isTrue);
      expect(sameSearchRecording(_recording, _recording), isTrue);
    },
  );

  test(
    'ineligible score rows issue no artwork queries; recording rows still do',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'singbook-score-art-',
      );
      final repository = await LibraryRepository.open(
        path: '${directory.path}/library.db',
        factory: databaseFactoryFfi,
      );
      final provider = _ArtworkCatalog();
      final app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService([provider]),
      );
      try {
        await app.initialize();
        app.requestArtwork([_score]);
        await Future<void>.delayed(Duration.zero);
        expect(provider.searches, 0);
        expect(app.artworkLookups.containsKey(_score.identity), isFalse);
        app.requestArtwork([_recording]);
        await provider.searched.future.timeout(const Duration(seconds: 2));
        for (
          var i = 0;
          i < 20 && !app.artworkLookups.containsKey(_recording.identity);
          i++
        ) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(provider.searches, 1);
        expect(app.artworkLookups[_recording.identity], _artwork);
        expect(app.artworkLookups.containsKey(_score.identity), isFalse);
      } finally {
        app.dispose();
        await repository.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
