import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/domain/timing.dart';

const selected = SongCandidate(
  providerId: 'catalog',
  id: 'song',
  title: 'Song',
  artist: 'Artist',
);
SourceResult source(
  String id,
  String body, {
  JsonMap metadata = const {},
  JsonMap candidateMetadata = const {},
  String? album,
  double? duration,
  MatchKind kind = MatchKind.sameSong,
  List<TimingTrack> tracks = const [],
}) => SourceResult(
  candidate: SongCandidate(
    providerId: id,
    id: 'song',
    title: 'Song',
    artist: 'Artist',
    album: album,
    durationSeconds: duration,
    metadata: candidateMetadata,
  ),
  body: body,
  metadata: metadata,
  matchKind: kind,
  timingTracks: tracks,
);

void main() {
  test('full lyrics outrank a shorter text with more provider line breaks', () {
    const full =
        'Amber lanterns glow above the quiet harbor and silver rain '
        'returns across the sleepy water until the morning brings a melody';
    final song = combineSources(selected, [
      source('full', full),
      source(
        'short',
        'Amber lanterns glow\nAbove the quiet harbor\nSilver rain returns',
      ),
    ]);
    expect(plainLyrics(song.body), full);
    expect(song.extra['selectedSourceId'], 'full:song');
  });

  test('chords align across split and joined provider lyric lines', () {
    const lyrics =
        'Amber lanterns glow above the quiet harbor\n'
        'Silver rain returns\nAcross the sleepy water\n'
        'The morning brings another distant melody';
    final song = combineSources(selected, [
      source('lyrics', lyrics),
      source(
        'chart',
        '[C]Amber lanterns glow\n[F]above the quiet harbor\n'
            '[Am]Silver rain returns [G]Across the sleepy water',
      ),
    ]);
    expect(plainLyrics(song.body), lyrics);
    expect(song.body, contains('[C]Amber lanterns glow [F]above'));
    expect(song.body, contains('[Am]Silver rain returns\n[G]Across'));
    expect(song.extra['chordSourceIds'], ['chart:song']);
  });

  test(
    'one partial phrase does not spread across different lyric contexts',
    () {
      const lyrics =
          'Amber lanterns glow above the river\n'
          'Amber lanterns glow beyond the station';
      final song = combineSources(selected, [
        source('lyrics', lyrics),
        source('chart', '[C]Amber lanterns glow'),
      ]);
      expect(plainLyrics(song.body), lyrics);
      expect(song.hasChords, false);
      expect(song.extra['chordSourceIds'], isNull);
      expect(song.sources.last.body, '[C]Amber lanterns glow');
    },
  );

  test('repeated partial placements need agreeing donor occurrences', () {
    const lyrics =
        'Amber lanterns glow above the river\n'
        'Amber lanterns glow beyond the station';
    final song = combineSources(selected, [
      source('lyrics', lyrics),
      source('chart', '[C]Amber lanterns glow\n[C]Amber lanterns glow'),
    ]);
    expect(plainLyrics(song.body), lyrics);
    expect(song.body, contains('[C]Amber lanterns glow above'));
    expect(song.body, contains('[C]Amber lanterns glow beyond'));
  });

  test('one cross-line phrase does not spread across repeated passages', () {
    const lyrics =
        'Amber lanterns glow\nAbove the quiet river\n'
        'Another verse returns tonight\n'
        'Amber lanterns glow\nAbove the quiet river\n'
        'The morning brings a final melody';
    final song = combineSources(selected, [
      source('lyrics', lyrics),
      source('chart', '[C]Amber lanterns glow above the quiet river'),
    ]);
    expect(plainLyrics(song.body), lyrics);
    expect(song.hasChords, false);
  });

  test('complete repeated lyric lines retain their existing chord overlay', () {
    const lyrics =
        'Amber lanterns glow\nAnother verse returns tonight\n'
        'Amber lanterns glow\nThe morning brings a final melody';
    final song = combineSources(selected, [
      source('lyrics', lyrics),
      source('chart', '[C]Amber lanterns glow'),
    ]);
    expect(plainLyrics(song.body), lyrics);
    expect(song.body.split('[C]').length - 1, 2);
  });

  test('repeated substring ambiguity stays bounded in a long lyric line', () {
    final lyrics = List.filled(
      4000,
      'Amber lanterns glow beside the river',
    ).join(' ');
    final watch = Stopwatch()..start();
    final song = combineSources(selected, [
      source('lyrics', lyrics),
      source('chart', '[C]Amber lanterns glow'),
    ]);
    expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
    expect(plainLyrics(song.body), lyrics);
    expect(song.hasChords, false);
  });

  test(
    'compatible charts fill different missing passages with both origins',
    () {
      const lyrics =
          'Amber lanterns glow\nSilver rain returns\n'
          'The morning brings another distant melody';
      final song = combineSources(selected, [
        source('lyrics', lyrics),
        source(
          'chart-a',
          '[C]Amber lanterns glow',
          metadata: {'key': 'C', 'capo': 0},
        ),
        source(
          'chart-b',
          '[F]Silver rain returns',
          metadata: {'key': 'C', 'capo': 0},
        ),
        source(
          'other-key',
          '[G]The morning brings another distant melody',
          metadata: {'key': 'G', 'capo': 0},
        ),
      ]);
      expect(plainLyrics(song.body), lyrics);
      expect(song.body, contains('[C]Amber'));
      expect(song.body, contains('[F]Silver'));
      expect(song.body, isNot(contains('[G]')));
      expect(song.extra['chordSourceIds'], ['chart-a:song', 'chart-b:song']);
      expect(
        contributingProviderIds(song),
        containsAll(['chart-a', 'chart-b']),
      );
    },
  );

  test(
    'a partly chorded base can gain missing chords after harmonic agreement',
    () {
      const lyrics =
          '[C]Amber lanterns glow\nSilver rain returns\n'
          'The morning brings another distant melody';
      final song = combineSources(selected, [
        source('base', lyrics),
        source('donor', '[C]Amber lanterns glow\n[F]Silver rain returns'),
      ]);
      expect(song.body, contains('[C]Amber lanterns glow\n[F]Silver'));
      expect(song.extra['chordSourceIds'], ['base:song', 'donor:song']);
    },
  );

  test('catalog key is not proof that two unknown chart setups agree', () {
    final song = combineSources(
      const SongCandidate(
        providerId: 'catalog',
        id: 'song',
        title: 'Song',
        artist: 'Artist',
        metadata: {'key': 'C'},
      ),
      [
        source(
          'lyrics',
          'Amber lanterns glow\nSilver rain returns\n'
              'Across the sleepy water until morning brings a melody',
        ),
        source('a', '[C]Amber lanterns glow'),
        source('b', '[F]Silver rain returns'),
      ],
    );
    expect(song.extra['chordSourceIds'], ['a:song']);
    expect(song.body, isNot(contains('[F]')));
  });

  test(
    'metadata collections add facts and retain their individual providers',
    () {
      final a = source(
        'a',
        'Amber lanterns glow\nSilver rain returns',
        metadata: {
          'composers': [
            {'name': 'Alex'},
          ],
          'credits': [
            {'role': 'Writer', 'name': 'Alex'},
          ],
        },
        kind: MatchKind.sameRecording,
      );
      final b = source(
        'b',
        '',
        metadata: {
          'identityScope': 'composition',
          'composers': [
            {'name': 'Alex'},
            {'name': 'Sam'},
          ],
          'lyricists': [
            {'name': 'Lee'},
          ],
          'publicationDates': ['1982-11-30'],
          'externalIdentifiers': {
            'catalog': ['work-1'],
          },
        },
        kind: MatchKind.sameSong,
      );
      final song = combineSources(selected, [a, b]);
      expect(song.metadata['composers'], [
        {'name': 'Alex'},
        {'name': 'Sam'},
      ]);
      expect(song.metadata['lyricists'], [
        {'name': 'Lee'},
      ]);
      expect(song.metadata['publicationDates'], ['1982-11-30']);
      expect(song.metadata['externalIdentifiers'], {
        'catalog': ['work-1'],
      });
      expect(song.extra['fieldOrigins']['composers'], 'a:song');
      expect(song.extra['fieldContributors']['composers'], [
        'a:song',
        'b:song',
      ]);
      expect(contributingProviderIds(song), containsAll(['a', 'b']));
      final decoded = ChordProCodec().decode(ChordProCodec().encode(song));
      expect(decoded.metadata, song.metadata);
      expect(
        decoded.extra['fieldContributors'],
        song.extra['fieldContributors'],
      );
      expect(
        decoded.sources.map((s) => s.toJson()),
        song.sources.map((s) => s.toJson()),
      );
    },
  );

  test('empty catalog collections do not suppress resolved metadata', () {
    final song = combineSources(
      const SongCandidate(
        providerId: 'catalog',
        id: 'song',
        title: 'Song',
        artist: 'Artist',
        metadata: {'credits': [], 'album': ''},
      ),
      [
        source(
          'catalog',
          'Amber lanterns glow',
          album: 'Album',
          kind: MatchKind.sameRecording,
          metadata: {
            'credits': [
              {'role': 'Writer', 'name': 'Alex'},
            ],
          },
        ),
      ],
    );
    expect(song.metadata['album'], 'Album');
    expect(song.metadata['credits'], isNotEmpty);
  });

  test('display duration validates legacy duration aliases', () {
    for (final invalid in [0, -1, double.infinity, double.nan, 86401]) {
      final song = combineSources(selected, [
        source(
          'catalog',
          'Amber lanterns glow',
          album: 'Album',
          kind: MatchKind.sameRecording,
        ),
        source(
          'youtube',
          'Amber lanterns glow',
          album: 'Album',
          metadata: {'duration': invalid},
        ),
      ]);
      expect(song.metadata, isNot(contains('duration')));
      expect(song.metadata, isNot(contains('durationSeconds')));
    }
  });

  test(
    'recording-compatible chord donor takes priority over more alternate anchors',
    () {
      const recording = SongCandidate(
        providerId: 'catalog',
        id: 'song',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        durationSeconds: 120,
      );
      final song = combineSources(recording, [
        source(
          'lyrics',
          'Amber lanterns glow\nSilver rain returns\n'
              'Across the sleepy water until morning brings a melody',
          album: 'Album',
          duration: 120,
          kind: MatchKind.sameRecording,
        ),
        source(
          'exact',
          '[C]Amber lanterns glow',
          album: 'Album',
          duration: 120,
          kind: MatchKind.sameRecording,
          metadata: {'key': 'C'},
        ),
        source(
          'alternate',
          '[G]Amber lanterns glow\n[D]Silver rain returns',
          metadata: {'key': 'G'},
        ),
      ]);
      expect(song.extra['chordSourceIds'], ['exact:song']);
      expect(song.body, contains('[C]Amber'));
      expect(song.body, isNot(contains('[D]')));
    },
  );

  test('large unmatched chart phrases finish within a bounded interval', () {
    final lyrics = List.generate(
      1200,
      (i) => 'Amber lanterns glow across the quiet harbor number $i',
    ).join('\n');
    final chart = List.generate(
      1200,
      (i) => '[C]Amber lanterns glow around a different mountain number $i',
    ).join('\n');
    final watch = Stopwatch()..start();
    final song = combineSources(selected, [
      source('lyrics', lyrics),
      source('chart', chart),
    ]);
    expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
    expect(song.hasChords, false);
    expect(plainLyrics(song.body), lyrics);
    expect(song.sources.last.body, chart);
  });

  test(
    'matching resolved album supplies missing duration without activating timing',
    () {
      const words = 'Amber lanterns glow\nSilver rain returns';
      final track = parseLrc(
        '[00:01]Amber lanterns glow\n[00:05]Silver rain returns',
        sourceDocumentId: 'youtube:song',
      );
      final song = combineSources(selected, [
        source('catalog', words, album: 'Album', kind: MatchKind.sameRecording),
        source(
          'youtube',
          words,
          album: 'Album',
          duration: 295,
          tracks: [track],
        ),
        source(
          'other-album',
          words,
          album: 'Live elsewhere',
          duration: 350,
          metadata: {
            'artworkUrl': 'https://example.test/wrong',
            'mediaLinks': [
              {'kind': 'audio', 'url': 'https://example.test/wrong-recording'},
            ],
          },
        ),
      ]);
      expect(song.metadata['durationSeconds'], 295);
      expect(song.extra['fieldOrigins']['durationSeconds'], 'youtube:song');
      expect(song.metadata['artworkUrl'], isNull);
      expect(song.metadata['mediaLinks'], isNull);
      expect(song.timingTracks.single.status, TimingStatus.unverified);
      expect(song.activeTimingTrackId, isNull);
    },
  );

  test(
    'conflicting recording and arrangement facts are retained as alternatives',
    () {
      final song = combineSources(
        const SongCandidate(
          providerId: 'catalog',
          id: 'song',
          title: 'Song',
          artist: 'Artist',
          album: 'Album',
          durationSeconds: 120,
        ),
        [
          source(
            'catalog',
            'Amber lanterns glow',
            album: 'Album',
            duration: 120,
            metadata: {'releaseDate': '1982-11-30'},
            kind: MatchKind.sameRecording,
          ),
          source(
            'other-recording',
            '',
            album: 'Other album',
            duration: 350,
            metadata: {
              'releaseDate': '2020-01-01',
              'artworkUrl': 'https://example.test/wrong',
            },
          ),
        ],
      );
      expect(song.metadata['durationSeconds'], 120);
      expect(song.metadata['releaseDate'], '1982-11-30');
      expect(song.metadata['artworkUrl'], isNull);
      expect(song.sources.last.metadata['releaseDate'], '2020-01-01');
    },
  );
}
