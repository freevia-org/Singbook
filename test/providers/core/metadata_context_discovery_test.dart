import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

const _album = 'Paper Moons (Original Soundtrack)';
const _lyrics = '''
Paper boats drift past the orchard wall
Quiet windows catch the evening rain
We fold a map from yesterday's sky
And follow lanterns down the lane
''';

const _selection = SongCandidate(
  providerId: 'genius',
  id: 'genius-song-81',
  title: 'Lantern Map',
  artist: 'June Harbor',
  durationSeconds: 214,
  metadata: {'identityScope': 'recording'},
  recordingIds: {'isrc': 'ZZ-TEST-0081'},
);

SongCandidate _resolvedGenius() => const SongCandidate(
  providerId: 'genius',
  id: 'genius-song-81',
  title: 'Lantern Map',
  artist: 'June Harbor',
  album: _album,
  durationSeconds: 214,
  metadata: {'identityScope': 'recording'},
  recordingIds: {'isrc': 'ZZ-TEST-0081'},
);

class _Genius implements LyricsProvider {
  @override
  final definition = const ProviderDefinition(
    id: 'genius',
    name: 'Genius',
    capabilities: {'catalog', 'lyrics'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_resolvedGenius()];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(candidate: _resolvedGenius(), body: _lyrics);
}

class _MusicBrainz implements LyricsProvider {
  _MusicBrainz({this.initialError, this.holdContext = false});

  final String? initialError;
  final bool holdContext;
  final seen = <SongCandidate>[];
  final contextStarted = Completer<CancellationToken?>();
  final releaseContext = Completer<void>();

  @override
  final definition = const ProviderDefinition(
    id: 'musicbrainz',
    name: 'MusicBrainz',
    capabilities: {'metadata'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => const [];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    seen.add(candidate);
    if (seen.length == 1) {
      final error = initialError;
      if (error != null) throw ProviderException(error);
    } else {
      if (!contextStarted.isCompleted) contextStarted.complete(cancel);
      if (holdContext) await releaseContext.future;
      cancel?.throwIfCancelled();
    }
    final enriched = SongCandidate(
      providerId: 'musicbrainz',
      id: 'mb-recording-81',
      title: 'Lantern Map',
      artist: 'June Harbor',
      album: candidate.album,
      // Album and title corroborate the work, but this response carries no
      // recording ID or duration evidence that would justify promotion.
      durationSeconds: null,
      metadata: const {'identityScope': 'recording'},
      recordingIds: const {},
    );
    return SourceResult(
      candidate: enriched,
      body: '',
      metadata: const {'source': 'test'},
    );
  }
}

void main() {
  test(
    'retries an unavailable MusicBrainz lookup with the resolved Genius album',
    () async {
      final musicbrainz = _MusicBrainz(initialError: 'unavailable');
      final results = await SourceDiscoveryService([
        _Genius(),
        musicbrainz,
      ]).discover(_selection);

      expect(musicbrainz.seen, hasLength(2));
      expect(musicbrainz.seen.first.album, isNull);
      expect(musicbrainz.seen.last.providerId, 'genius');
      expect(musicbrainz.seen.last.id, _selection.id);
      expect(musicbrainz.seen.last.album, _album);
      final result = results.singleWhere(
        (item) => item.candidate.providerId == 'musicbrainz',
      );
      expect(result.candidate.album, _album);
      expect(result.matchKind, MatchKind.sameSong);
      expect(result.extra['resolvedRecordingContext'], {
        'providerId': 'genius',
        'candidateId': _selection.id,
        'album': _album,
      });
    },
  );

  test('does not retry a rate-limited MusicBrainz lookup', () async {
    final musicbrainz = _MusicBrainz(initialError: 'rate_limited');
    await SourceDiscoveryService([_Genius(), musicbrainz]).discover(_selection);

    expect(musicbrainz.seen, hasLength(1));
    expect(musicbrainz.seen.single.album, isNull);
  });

  test(
    'cancelling the reference cancels the contextual MusicBrainz retry',
    () async {
      final referenceCancellation = CancellationToken();
      final musicbrainz = _MusicBrainz(
        initialError: 'unavailable',
        holdContext: true,
      );
      final pending = SourceDiscoveryService([_Genius(), musicbrainz]).discover(
        _selection,
        providerCancellation: {'genius': referenceCancellation},
      );
      final token = await musicbrainz.contextStarted.future.timeout(
        const Duration(seconds: 2),
      );
      referenceCancellation.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(token?.isCancelled, isTrue);
      musicbrainz.releaseContext.complete();
      final results = await pending.timeout(const Duration(seconds: 2));
      expect(
        results.any((item) => item.candidate.providerId == 'musicbrainz'),
        isFalse,
      );
    },
  );
}
