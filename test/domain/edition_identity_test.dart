import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/edition_identity.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';

const _words =
    'Amber lanterns glow across the quiet harbor\n'
    'Silver rain returns beneath the evening sky';

SongCandidate _candidate(
  String provider, {
  String title = 'Amber Song',
  JsonMap metadata = const {},
  JsonMap extra = const {},
}) => SongCandidate(
  providerId: provider,
  id: 'song',
  title: title,
  artist: 'Example Artist',
  album: 'Album',
  durationSeconds: 120,
  recordingIds: const {'isrc': 'same-recording-id'},
  metadata: metadata,
  extra: extra,
);

SourceResult _result(
  String provider, {
  String title = 'Amber Song',
  JsonMap candidateMetadata = const {},
  JsonMap metadata = const {},
  JsonMap extra = const {},
  String body = _words,
  bool timed = false,
}) => SourceResult(
  candidate: _candidate(provider, title: title, metadata: candidateMetadata),
  body: body,
  metadata: metadata,
  extra: extra,
  matchKind: MatchKind.sameRecording,
  timingTracks: timed
      ? [
          parseLrc(
            '[00:01]Amber lanterns glow across the quiet harbor\n'
            '[00:05]Silver rain returns beneath the evening sky',
            sourceDocumentId: '$provider:song',
          ),
        ]
      : const [],
);

void main() {
  test('two missing edition claims remain compatible', () {
    expect(explicitEditionsCompatible(_candidate('a'), _candidate('b')), true);
  });

  test('unknown edition does not invent a studio claim against known live', () {
    final unknown = _candidate('a');
    final live = _candidate('b', metadata: {'version': 'Live'});
    expect(explicitEditionsCompatible(unknown, live), true);
    expect(explicitEditionsCompatible(live, unknown), true);
  });

  test('equal labels normalize case punctuation and version boilerplate', () {
    expect(
      explicitEditionsCompatible(
        _candidate('a', metadata: {'version': '2011 Remastered Edition'}),
        _candidate('b', metadata: {'edition': '2011 - remastered version'}),
      ),
      true,
    );
  });

  test('the same specific live performance label remains compatible', () {
    expect(
      explicitEditionsCompatible(
        _candidate('a', metadata: {'version': 'Live at Example Hall 1994'}),
        _candidate('b', metadata: {'version': 'Live at Example Hall 1994'}),
      ),
      true,
    );
  });

  test('different named live performances remain conflicting editions', () {
    expect(
      explicitEditionsCompatible(
        _candidate('a', metadata: {'version': 'Live at Example Hall 1994'}),
        _candidate('b', metadata: {'version': 'Live at Other Hall 1994'}),
      ),
      false,
    );
  });

  test('explicit studio and live conflict despite equal recording IDs', () {
    final studio = _candidate('a', metadata: {'version': 'Studio'});
    final live = _candidate('b', metadata: {'version': 'Live'});
    expect(studio.recordingIds, live.recordingIds);
    expect(explicitEditionsCompatible(studio, live), false);
  });

  test('hidden source metadata and extras cannot override a studio claim', () {
    final studio = _candidate('a', metadata: {'version': 'Studio'});
    expect(
      explicitEditionsCompatible(
        studio,
        _candidate('b'),
        metadata: {'disambiguation': 'Live at Example Hall'},
      ),
      false,
    );
    expect(
      explicitEditionsCompatible(
        studio,
        _candidate('b'),
        extra: {'edition': 'Live'},
      ),
      false,
    );
  });

  test('mono and stereo are contradictory explicit mixes', () {
    expect(
      explicitEditionsCompatible(
        _candidate('a', title: 'Amber Song (Mono)'),
        _candidate('b', title: 'Amber Song [Stereo]'),
      ),
      false,
    );
  });

  test('dash and bracket edition qualifiers convey equivalent facts', () {
    expect(
      explicitEditionsCompatible(
        _candidate('a', title: 'Amber Song - Live Acoustic'),
        _candidate('b', title: 'Amber Song (Live Acoustic)'),
      ),
      true,
    );
  });

  test('ordinary title words do not become an invented edition qualifier', () {
    expect(
      explicitEditionsCompatible(
        _candidate('a', title: 'Live Forever'),
        _candidate('b', title: 'Live Forever', metadata: {'version': 'Studio'}),
      ),
      true,
    );
  });

  test('a live acoustic performance can carry compatible partial evidence', () {
    expect(
      explicitEditionsCompatible(
        _candidate('a', metadata: {'version': 'Live'}),
        _candidate(
          'b',
          metadata: {'version': 'Live', 'disambiguation': 'Acoustic'},
        ),
      ),
      true,
    );
  });

  test('multiple generic descriptors in one candidate are compatible', () {
    expect(
      explicitEditionsCompatible(
        _candidate('a', metadata: {'version': 'Live', 'edition': 'Acoustic'}),
        _candidate('b', metadata: {'version': 'Live acoustic'}),
      ),
      true,
    );
  });

  test(
    'internal unrelated named editions cannot be collapsed into one claim',
    () {
      expect(
        explicitEditionsCompatible(
          _candidate('a'),
          _candidate(
            'b',
            metadata: {
              'version': 'Live at Example Hall',
              'edition': 'Live at Other Hall',
            },
          ),
        ),
        false,
      );
    },
  );

  test(
    'unknown selection does not excuse internal title-live metadata-studio conflict',
    () {
      expect(
        explicitEditionsCompatible(
          _candidate('a'),
          _candidate(
            'b',
            title: 'Amber Song (Live)',
            metadata: {'version': 'Studio'},
          ),
        ),
        false,
      );
    },
  );

  test(
    'the same internally contradictory edition on both sides is not evidence',
    () {
      expect(
        explicitEditionsCompatible(
          _candidate(
            'a',
            title: 'Amber Song (Live)',
            metadata: {'version': 'Studio'},
          ),
          _candidate(
            'b',
            title: 'Amber Song (Live)',
            metadata: {'version': 'Studio'},
          ),
        ),
        false,
      );
    },
  );

  test('a single internally contradictory mono-stereo label is rejected', () {
    expect(
      explicitEditionsCompatible(
        _candidate('a'),
        _candidate('b', metadata: {'version': 'Mono stereo mix'}),
      ),
      false,
    );
  });

  test('candidate and resolved metadata cannot make contradictory claims', () {
    expect(
      explicitEditionsCompatible(
        _candidate('a'),
        _candidate('b', metadata: {'version': 'Studio'}),
        metadata: {'version': 'Live'},
      ),
      false,
    );
  });

  test(
    'both resolved source metadata are edition evidence when candidates are unknown',
    () {
      final first = _candidate('a'), second = _candidate('b');
      expect(
        explicitEditionsCompatible(
          first,
          second,
          selectedMetadata: {'version': 'Live'},
          metadata: {'version': 'Studio'},
        ),
        false,
      );
      expect(
        explicitEditionsCompatible(
          second,
          first,
          selectedMetadata: {'version': 'Studio'},
          metadata: {'version': 'Live'},
        ),
        false,
      );
    },
  );

  test('resolved metadata and extras conflict in both pairwise directions', () {
    final first = _candidate('a'), second = _candidate('b');
    expect(
      explicitEditionsCompatible(
        first,
        second,
        selectedMetadata: {'version': 'Live'},
        extra: {'version': 'Studio'},
      ),
      false,
    );
    expect(
      explicitEditionsCompatible(
        second,
        first,
        selectedExtra: {'version': 'Studio'},
        metadata: {'version': 'Live'},
      ),
      false,
    );
  });

  test(
    'unknown selected source metadata remains unknown against known editions',
    () {
      expect(
        explicitEditionsCompatible(
          _candidate('a'),
          _candidate('b'),
          selectedMetadata: {},
          extra: {'version': 'Live'},
        ),
        true,
      );
      expect(
        explicitEditionsCompatible(
          _candidate('a'),
          _candidate('b'),
          selectedExtra: {'version': 'Live'},
          metadata: {},
        ),
        true,
      );
    },
  );

  test(
    'compatible partial descriptors can be split across both resolved sources',
    () {
      expect(
        explicitEditionsCompatible(
          _candidate('a'),
          _candidate('b'),
          selectedMetadata: {'version': 'Live'},
          metadata: {'version': 'Live'},
          extra: {'edition': 'Acoustic'},
        ),
        true,
      );
      expect(
        explicitEditionsCompatible(
          _candidate('b'),
          _candidate('a'),
          selectedMetadata: {'version': 'Live'},
          selectedExtra: {'edition': 'Acoustic'},
          metadata: {'version': 'Live'},
        ),
        true,
      );
    },
  );

  test(
    'automatic combination rejects hidden live timing key and lyrics against studio',
    () {
      final selected = _candidate('primary', metadata: {'version': 'Studio'});
      final primary = _result(
        'primary',
        candidateMetadata: {'version': 'Studio'},
      );
      final live = _result(
        'live',
        candidateMetadata: {'version': 'Live'},
        metadata: {'key': 'D'},
        body: 'Different live performance lyrics',
        timed: true,
      );
      final song = combineSources(selected, [primary, live]);
      expect(song.body, contains('Amber lanterns glow'));
      expect(song.body, isNot(contains('Different live performance')));
      expect(song.sources, contains(live));
      expect(recordingCompatible(selected, live), false);
      expect(song.timingTracks.single.status, TimingStatus.unverified);
      expect(
        song.timingTracks.single.extra['binding']['recordingVerified'],
        false,
      );
      expect(song.activeTimingTrackId, isNull);
      expect(song.metadata['key'], isNull);
      expect(sourcedArrangementKey(song), isNull);
    },
  );

  test(
    'equal lyrics and shared ID cannot activate contradictory live timing or key',
    () {
      final selected = _candidate('primary', metadata: {'version': 'Studio'});
      final primary = _result(
        'primary',
        candidateMetadata: {'version': 'Studio'},
      );
      final live = _result(
        'live',
        metadata: {'disambiguation': 'Live', 'key': 'D'},
        timed: true,
      );
      final song = combineSources(selected, [primary, live]);
      expect(song.timingTracks.single.status, TimingStatus.unverified);
      expect(song.activeTimingTrackId, isNull);
      expect(song.metadata['key'], isNull);
      expect(sourcedArrangementKey(song), isNull);
    },
  );

  test(
    'explicit body choice remains possible without gaining conflicting recording timing',
    () {
      final selected = _candidate('primary', metadata: {'version': 'Studio'});
      final primary = _result(
        'primary',
        candidateMetadata: {'version': 'Studio'},
      );
      final live = _result(
        'live',
        candidateMetadata: {'version': 'Live'},
        timed: true,
        body: 'Different live performance lyrics\nAnother complete live line',
      );
      final song = combineSources(selected, [
        primary,
        live,
      ], preferredSourceId: live.id);
      expect(song.body, contains('Different live performance lyrics'));
      expect(song.extra['selectedSourceId'], live.id);
      expect(song.selectedRecording, same(selected));
      expect(song.timingTracks.single.status, TimingStatus.unverified);
      expect(song.activeTimingTrackId, isNull);
    },
  );

  test(
    'established same-recording proof still binds timing when edition is unknown',
    () {
      final selected = _candidate('primary');
      final primary = _result('primary');
      final known = _result(
        'known',
        candidateMetadata: {'version': 'Live'},
        timed: true,
      );
      final song = combineSources(selected, [
        primary,
        known,
      ], preferredSourceId: primary.id);
      expect(recordingCompatible(selected, known), true);
      expect(song.timingTracks.single.status, TimingStatus.usable);
      expect(
        song.timingTracks.single.extra['binding']['recordingVerified'],
        true,
      );
      expect(song.activeTimingTrackId, song.timingTracks.single.id);
    },
  );
}
