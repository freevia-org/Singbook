import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/source_contributions.dart';

void main() {
  SourceResult source(String provider, String id, {bool rejected = false}) =>
      SourceResult(
        candidate: SongCandidate(
          providerId: provider,
          id: id,
          title: 'Demo',
          artist: 'Us',
        ),
        body: 'Original demo words',
        matchKind: rejected ? MatchKind.rejected : MatchKind.sameRecording,
      );

  test(
    'counts contributors rather than every retained provenance document',
    () {
      final lyrics = source('lyrics', 'one');
      final rejected = source('wrong', 'two', rejected: true);
      final unused = source('alternative', 'three');
      final song = SongDocument(
        id: 'song',
        title: 'Demo',
        artist: 'Us',
        body: lyrics.body,
        sources: [lyrics, rejected, unused],
        extra: {'selectedSourceId': lyrics.id},
      );
      expect(contributingProviderIds(song), {'lyrics'});
      expect(song.sources, hasLength(3));
    },
  );

  test(
    'counts metadata contributors and deduplicates documents per provider',
    () {
      final lyrics = source('shared', 'lyrics');
      final metadata = source('shared', 'metadata');
      const catalog = SongCandidate(
        providerId: 'catalog',
        id: 'hit',
        title: 'Demo',
        artist: 'Us',
      );
      final song = SongDocument(
        id: 'song',
        title: 'Demo',
        artist: 'Us',
        body: lyrics.body,
        selectedRecording: catalog,
        sources: [lyrics, metadata],
        metadata: const {'key': 'C', 'album': 'Demo album', 'genre': null},
        extra: {
          'selectedSourceId': lyrics.id,
          'fieldOrigins': {
            'key': metadata.id,
            'album': catalog.identity,
            'genre': 'unused:one',
          },
        },
      );
      expect(contributingProviderIds(song), {'shared', 'catalog'});
    },
  );

  test('only usable timing contributes to the combined version count', () {
    final lyrics = source('lyrics', 'one');
    final timed = source('timing', 'two');
    final unverified = source('unverified', 'three');
    TimingTrack track(SourceResult source, TimingStatus status) => TimingTrack(
      id: source.id,
      sourceDocumentId: source.id,
      sourceLyrics: lyrics.body,
      format: 'lrc',
      cues: [
        TimingCue(
          id: 'cue',
          occurrenceId: 'line-0',
          text: lyrics.body,
          startUs: 1000000,
        ),
      ],
      status: status,
      extra: {
        'binding': {'sourceId': source.id},
      },
    );
    final song = SongDocument(
      id: 'song',
      title: 'Demo',
      artist: 'Us',
      body: lyrics.body,
      sources: [lyrics, timed, unverified],
      extra: {'selectedSourceId': lyrics.id},
      timingTracks: [
        track(timed, TimingStatus.usable),
        track(unverified, TimingStatus.unverified),
      ],
    );
    expect(contributingProviderIds(song), {'lyrics', 'timing'});
  });

  test('additional values in one metadata collection count their provider', () {
    final primary = source('primary', 'one');
    final additional = source('additional', 'two');
    final song = SongDocument(
      id: 'song',
      title: 'Demo',
      artist: 'Us',
      body: primary.body,
      sources: [primary, additional],
      metadata: {
        'composers': ['Alex', 'Sam'],
      },
      extra: {
        'selectedSourceId': primary.id,
        'fieldOrigins': {'composers': primary.id},
        'fieldContributors': {
          'composers': [primary.id, additional.id],
        },
      },
    );
    expect(contributingProviderIds(song), {'primary', 'additional'});
  });

  test('section donors count as combined contributors', () {
    final lyrics = source('lyrics', 'one');
    final sections = source('structure', 'two');
    final song = SongDocument(
      id: 'song',
      title: 'Demo',
      artist: 'Us',
      body: lyrics.body,
      sources: [lyrics, sections],
      extra: {
        'selectedSourceId': lyrics.id,
        'sectionSourceIds': [sections.id],
      },
    );
    expect(contributingProviderIds(song), {'lyrics', 'structure'});
  });
}
