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

      final document = combineSources(selectedRecording, [source]);
      expect(document.timingTracks.single.status, TimingStatus.usable);
      expect(document.activeTimingTrackId, document.timingTracks.single.id);
      expect(
        document.timingTracks.single.extra['binding']['recordingVerified'],
        isTrue,
      );
    },
  );
}
