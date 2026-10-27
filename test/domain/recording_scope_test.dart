import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';

void main() {
  const catalogCandidate = SongCandidate(
    providerId: 'worshipcommons',
    id: 'song-1',
    title: 'Amazing Grace',
    artist: 'John Newton',
    metadata: {'identityScope': 'composition'},
  );

  SourceResult worshipSource({Map<String, String> recordingIds = const {}}) {
    final track = parseLrc(
      '[00:01]Amazing grace',
      sourceDocumentId: catalogCandidate.identity,
    ).copyWith(extra: const {'recordingEvidence': 'sourceDemonstrationOnly'});
    return SourceResult(
      candidate: SongCandidate(
        providerId: catalogCandidate.providerId,
        id: catalogCandidate.id,
        title: catalogCandidate.title,
        artist: catalogCandidate.artist,
        metadata: catalogCandidate.metadata,
        recordingIds: recordingIds,
      ),
      body: 'Amazing grace',
      matchKind: MatchKind.sameRecording,
      timingTracks: [track],
    );
  }

  test('composition identity does not establish recording compatibility', () {
    final source = worshipSource();
    expect(recordingCompatible(catalogCandidate, source), isFalse);

    final document = combineSources(catalogCandidate, [source]);
    expect(document.timingTracks.single.status, TimingStatus.unverified);
    expect(document.activeTimingTrackId, isNull);
    expect(
      document.timingTracks.single.extra['binding']['recordingVerified'],
      isFalse,
    );
    expect(document.timingTracks.single.raw, '[00:01]Amazing grace');
  });

  test(
    'demonstration timing can activate with explicit matching recording ID',
    () {
      const selectedRecording = SongCandidate(
        providerId: 'musicbrainz',
        id: 'recording-1',
        title: 'Amazing Grace',
        artist: 'John Newton',
        metadata: {'identityScope': 'recording'},
        recordingIds: {'musicbrainz': 'recording-1'},
      );
      final source = worshipSource(
        recordingIds: const {'musicbrainz': 'recording-1'},
      );

      expect(recordingCompatible(selectedRecording, source), isTrue);
      final document = combineSources(selectedRecording, [source]);
      expect(document.timingTracks.single.status, TimingStatus.usable);
      expect(document.activeTimingTrackId, document.timingTracks.single.id);
      expect(
        document.timingTracks.single.extra['binding']['recordingVerified'],
        isTrue,
      );
    },
  );

  for (final historicalLocation in [
    'selected scope',
    'candidate scope',
    'source metadata scope',
    'source extra scope',
    'selected Wikisource provider',
    'candidate Wikisource provider',
  ]) {
    test('explicit recording ID cannot authorize $historicalLocation', () {
      final selectedJson = cloneJson(
        const SongCandidate(
          providerId: 'musicbrainz',
          id: 'recording-1',
          title: 'Amazing Grace',
          artist: 'John Newton',
          metadata: {'identityScope': 'recording'},
          recordingIds: {'musicbrainz': 'recording-1'},
        ).toJson(),
      );
      final sourceJson = cloneJson(
        worshipSource(
          recordingIds: const {'musicbrainz': 'recording-1'},
        ).toJson(),
      );
      final candidate = sourceJson['candidate'] as JsonMap;
      switch (historicalLocation) {
        case 'selected scope':
          (selectedJson['metadata'] as JsonMap)['identityScope'] =
              'historicalText';
          break;
        case 'candidate scope':
          (candidate['metadata'] as JsonMap)['identityScope'] =
              'historicalText';
          break;
        case 'source metadata scope':
          (sourceJson['metadata'] as JsonMap)['identityScope'] =
              'historicalText';
          break;
        case 'source extra scope':
          sourceJson['identityScope'] = 'historicalText';
          break;
        case 'selected Wikisource provider':
          selectedJson['providerId'] = 'wikisource';
          break;
        case 'candidate Wikisource provider':
          candidate['providerId'] = 'wikisource';
          break;
      }
      final selected = SongCandidate.fromJson(selectedJson);
      final source = SourceResult.fromJson(sourceJson);
      expect(selected.recordingIds['musicbrainz'], 'recording-1');
      expect(source.candidate.recordingIds['musicbrainz'], 'recording-1');
      expect(recordingCompatible(selected, source), isFalse);
      if (historicalLocation == 'candidate Wikisource provider') {
        // A provider label with no validated own-page proof is not an import.
        expect(
          () => combineSources(selected, [source]),
          throwsA(isA<FormatException>()),
        );
      } else {
        final document = combineSources(selected, [source]);
        expect(document.timingTracks.single.status, TimingStatus.unverified);
        expect(document.activeTimingTrackId, isNull);
        expect(
          document.timingTracks.single.extra['binding']['recordingVerified'],
          isFalse,
        );
        expect(document.timingTracks.single.raw, '[00:01]Amazing grace');
      }
    });
  }

  for (final scope in ['composition', 'work', 'artist', 'image']) {
    for (final location in ['source metadata', 'source extra']) {
      test(
        'same candidate ID with $scope in $location is not recording proof',
        () {
          const selected = SongCandidate(
            providerId: 'catalog',
            id: 'shared-identity',
            title: 'Amazing Grace',
            artist: 'John Newton',
          );
          const candidate = SongCandidate(
            providerId: 'catalog',
            id: 'shared-identity',
            title: 'Amazing Grace',
            artist: 'John Newton',
          );
          final source = SourceResult(
            candidate: candidate,
            body: 'Amazing grace',
            matchKind: MatchKind.sameSong,
            metadata: location == 'source metadata'
                ? {'identityScope': scope}
                : const {},
            extra: location == 'source extra'
                ? {'identityScope': scope}
                : const {},
          );

          expect(recordingCompatible(selected, source), isFalse);
        },
      );
    }
  }
}
