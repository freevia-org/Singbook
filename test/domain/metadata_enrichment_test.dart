import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/metadata_enrichment.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/domain/timing.dart';

const _selected = SongCandidate(
  providerId: 'primary',
  id: 'hit',
  title: 'Amber Song',
  artist: 'Example Artist',
);
const _words = 'Amber lanterns glow\nSilver rain returns';

SourceResult _source(
  String provider, {
  String id = 'hit',
  String title = 'Amber Song',
  String artist = 'Example Artist',
  String? album = 'Album',
  double? duration = 120,
  JsonMap metadata = const {},
  JsonMap candidateMetadata = const {'identityScope': 'recording'},
  JsonMap extra = const {},
  Map<String, String> recordingIds = const {},
  MatchKind kind = MatchKind.sameSong,
  String body = '',
  List<TimingTrack> tracks = const [],
}) => SourceResult(
  candidate: SongCandidate(
    providerId: provider,
    id: id,
    title: title,
    artist: artist,
    album: album,
    durationSeconds: duration,
    metadata: candidateMetadata,
    recordingIds: recordingIds,
  ),
  body: body,
  metadata: metadata,
  extra: extra,
  matchKind: kind,
  timingTracks: tracks,
);

SourceResult _lyrics() => _source(
  'primary',
  album: null,
  duration: null,
  candidateMetadata: const {},
  body: _words,
  kind: MatchKind.sameRecording,
);

SongDocument _document(
  List<SourceResult> sources, {
  SongCandidate selected = _selected,
  JsonMap metadata = const {},
  JsonMap extra = const {},
}) => SongDocument(
  id: 'saved-id',
  title: selected.title,
  artist: selected.artist,
  body: '[C]Amber lanterns glow\n[G]Silver rain returns',
  selectedRecording: selected,
  sources: sources,
  metadata: metadata,
  extra: extra,
  revision: 9,
  favorite: true,
  createdAt: DateTime.utc(2020),
  updatedAt: DateTime.utc(2021),
);

SongDocument _enrich(SongDocument song) =>
    enrichCombinedDisplayMetadata(song, isSameRecording: recordingCompatible);

void main() {
  test(
    'two independent matching sources fill sparse display metadata and credits',
    () {
      final first = _source(
        'a',
        metadata: {
          'artworkUrl': 'https://example.test/a.jpg',
          'composers': ['Alice'],
          'producers': ['Pat'],
        },
      );
      final second = _source(
        'b',
        duration: 122,
        metadata: {
          'composers': ['Alice', 'Bob'],
        },
      );
      final song = combineSources(_selected, [_lyrics(), first, second]);
      expect(song.metadata['album'], 'Album');
      expect(song.metadata['durationSeconds'], 120);
      expect(song.metadata['artworkUrl'], 'https://example.test/a.jpg');
      expect(song.metadata['composers'], ['Alice', 'Bob']);
      expect(song.metadata['producers'], ['Pat']);
      expect(song.extra['fieldOrigins']['album'], first.id);
      expect(song.extra['fieldContributors']['composers'], [
        first.id,
        second.id,
      ]);
      expect(contributingProviderIds(song), containsAll(['primary', 'a', 'b']));
      expect(song.selectedRecording, same(_selected));
      expect(_selected.album, isNull);
      expect(_selected.durationSeconds, isNull);
      expect(song.body, contains('Amber lanterns glow'));
    },
  );

  test('provenance and alternatives survive SongDocument JSON roundtrip', () {
    final song = _enrich(
      _document([
        _source('a', metadata: {'artworkUrl': 'https://example.test/a.jpg'}),
        _source('b', metadata: {'artworkUrl': 'https://example.test/b.jpg'}),
      ]),
    );
    final restored = SongDocument.fromJson(
      jsonDecode(jsonEncode(song.toJson())),
    );
    expect(restored.toJson(), song.toJson());
    expect(song.metadata['artworkUrl'], 'https://example.test/a.jpg');
    expect(song.extra['conflicts']['artworkUrl'], [
      {'sourceId': 'a:hit', 'value': 'https://example.test/a.jpg'},
      {'sourceId': 'b:hit', 'value': 'https://example.test/b.jpg'},
    ]);
  });

  test(
    'display enrichment preserves arrangement identity timestamps and raw sources',
    () {
      final original = _document([_source('a'), _source('b')]);
      final song = _enrich(original);
      expect(song.id, original.id);
      expect(song.revision, original.revision);
      expect(song.createdAt, original.createdAt);
      expect(song.updatedAt, original.updatedAt);
      expect(song.favorite, original.favorite);
      expect(song.body, original.body);
      expect(song.sources, same(original.sources));
      expect(song.selectedRecording, same(original.selectedRecording));
      expect(song.timingTracks, same(original.timingTracks));
      expect(song.activeTimingTrackId, original.activeTimingTrackId);
      expect(original.metadata, isEmpty);
      expect(original.extra, isEmpty);
    },
  );

  test(
    'known selected and manually edited fields retain priority over donors',
    () {
      final song = _enrich(
        _document(
          [_source('a'), _source('b')],
          metadata: {
            'album': 'Chosen Album',
            'durationSeconds': 119,
            'artworkUrl': 'https://example.test/manual.jpg',
            'composers': ['Me'],
          },
          extra: {
            'fieldOrigins': {
              'album': _selected.identity,
              'durationSeconds': _selected.identity,
              'artworkUrl': 'user',
              'composers': 'user',
            },
          },
        ),
      );
      expect(song.metadata['album'], 'Chosen Album');
      expect(song.metadata['durationSeconds'], 119);
      expect(song.metadata['artworkUrl'], 'https://example.test/manual.jpg');
      expect(song.metadata['composers'], ['Me']);
    },
  );

  test(
    'invalid automatic artwork upgrades using proven evidence with prior claim retained',
    () {
      final song = _enrich(
        _document(
          [
            _source(
              'a',
              metadata: {'artworkUrl': 'https://example.test/new.jpg'},
            ),
            _source('b'),
          ],
          metadata: {'artworkUrl': 'http://example.test/old.jpg'},
          extra: {
            'fieldOrigins': {'artworkUrl': 'old:hit'},
          },
        ),
      );
      expect(song.metadata['artworkUrl'], 'https://example.test/new.jpg');
      expect(
        song.extra['conflicts']['artworkUrl'],
        anyElement(
          equals({
            'sourceId': 'old:hit',
            'value': 'http://example.test/old.jpg',
          }),
        ),
      );
    },
  );

  test('source ordering does not decide display metadata or provenance', () {
    final sources = [
      _source(
        'z',
        metadata: {
          'artworkUrl': 'https://example.test/z.jpg',
          'writers': ['Z'],
        },
      ),
      _source(
        'a',
        metadata: {
          'artworkUrl': 'https://example.test/a.jpg',
          'writers': ['A'],
        },
      ),
    ];
    final forward = _enrich(_document(sources));
    final reverse = _enrich(_document(sources.reversed.toList()));
    expect(forward.metadata, reverse.metadata);
    expect(forward.extra, reverse.extra);
  });

  test(
    'invalid automatic duration upgrades without changing selected identity',
    () {
      final song = _enrich(
        _document(
          [_source('a'), _source('b')],
          metadata: {'durationSeconds': -1},
          extra: {
            'fieldOrigins': {'durationSeconds': 'old:hit'},
          },
        ),
      );
      expect(song.metadata['durationSeconds'], 120);
      expect(song.selectedRecording!.durationSeconds, isNull);
      expect(
        song.extra['conflicts']['durationSeconds'],
        anyElement(equals({'sourceId': 'old:hit', 'value': -1})),
      );
    },
  );

  test(
    'late blank metadata cannot remove previously enriched facts or chords',
    () {
      final initial = _enrich(
        _document([
          _source('a', metadata: {'artworkUrl': 'https://example.test/a.jpg'}),
          _source('b'),
        ]),
      );
      final late = initial.copyWith(
        sources: [
          ...initial.sources,
          _source(
            'c',
            album: null,
            duration: null,
            metadata: {'artworkUrl': '', 'credits': []},
          ),
        ],
      );
      final result = _enrich(late);
      expect(result.metadata, initial.metadata);
      expect(result.body, initial.body);
      expect(result.selectedRecording, same(initial.selectedRecording));
    },
  );

  test(
    'existing display album is a negative guard and never recording proof',
    () {
      final song = _enrich(
        _document(
          [
            _source(
              'a',
              album: 'Other album',
              metadata: {'artworkUrl': 'https://example.test/wrong.jpg'},
            ),
            _source('b', album: 'Other album'),
          ],
          metadata: {'album': 'Manual album'},
          extra: {
            'fieldOrigins': {'album': 'user'},
          },
        ),
      );
      expect(song.metadata, {'album': 'Manual album'});
      final sparse = _enrich(
        _document([_source('a')], metadata: {'album': 'Album'}),
      );
      expect(sparse.metadata['durationSeconds'], isNull);
    },
  );

  test('single title and artist match cannot fill a sparse recording', () {
    expect(_enrich(_document([_source('a')])).metadata, isEmpty);
  });

  test(
    'multiple documents from one provider are not independent corroboration',
    () {
      expect(
        _enrich(_document([_source('a'), _source('a', id: 'other')])).metadata,
        isEmpty,
      );
    },
  );

  test(
    'conflicting album groups remain unchosen on a sparse selected record',
    () {
      expect(
        _enrich(
          _document([
            _source('a'),
            _source('b'),
            _source('c', album: 'Other album'),
          ]),
        ).metadata,
        isEmpty,
      );
    },
  );

  test('conflicting durations cannot establish sparse consensus', () {
    expect(
      _enrich(_document([_source('a'), _source('b', duration: 150)])).metadata,
      isEmpty,
    );
  });

  test('conflicting donor recording IDs cannot establish sparse consensus', () {
    expect(
      _enrich(
        _document([
          _source('a', recordingIds: {'isrc': 'first'}),
          _source('b', recordingIds: {'isrc': 'second'}),
        ]),
      ).metadata,
      isEmpty,
    );
  });

  for (final placement in ['candidate', 'metadata', 'extra']) {
    test(
      'sparse consensus rejects opposing $placement editions in both arrival orders',
      () {
        SourceResult edition(String provider, String version) => _source(
          provider,
          candidateMetadata: {
            'identityScope': 'recording',
            if (placement == 'candidate') 'version': version,
          },
          metadata: {
            'artworkUrl': 'https://example.test/$provider.jpg',
            if (placement == 'metadata') 'version': version,
          },
          extra: {if (placement == 'extra') 'version': version},
        );
        final live = edition('live', 'Live'),
            studio = edition('studio', 'Studio');
        for (final order in [
          [live, studio],
          [studio, live],
        ]) {
          final original = _document(order);
          final song = _enrich(original);
          expect(song.metadata, isEmpty);
          expect(song.sources, same(original.sources));
          expect(song.selectedRecording, same(_selected));
          expect(song.selectedRecording!.album, isNull);
          expect(song.selectedRecording!.durationSeconds, isNull);
        }
      },
    );
  }

  test(
    'sparse consensus compares resolved metadata against resolved extras',
    () {
      final live = _source(
        'a',
        metadata: {
          'version': 'Live',
          'composers': ['Live Credit'],
        },
      );
      final studio = _source(
        'b',
        extra: {'version': 'Studio'},
        metadata: {
          'composers': ['Studio Credit'],
        },
      );
      expect(live.candidate.metadata, isNot(contains('version')));
      expect(studio.candidate.metadata, isNot(contains('version')));
      for (final order in [
        [live, studio],
        [studio, live],
      ]) {
        expect(_enrich(_document(order)).metadata, isEmpty);
      }
    },
  );

  test(
    'sparse unknown and compatible known edition evidence can still corroborate',
    () {
      final known = _source(
        'a',
        metadata: {
          'version': 'Live',
          'artworkUrl': 'https://example.test/live.jpg',
        },
      );
      final unknown = _source('b');
      for (final order in [
        [known, unknown],
        [unknown, known],
      ]) {
        final song = _enrich(_document(order));
        expect(song.metadata['album'], 'Album');
        expect(song.metadata['durationSeconds'], 120);
        expect(song.metadata['artworkUrl'], 'https://example.test/live.jpg');
        expect(song.selectedRecording, same(_selected));
      }
    },
  );

  test(
    'sparse compatible live-acoustic donor descriptors corroborate in either order',
    () {
      final live = _source('a', metadata: {'version': 'Live'});
      final acoustic = _source(
        'b',
        extra: {'edition': 'Acoustic'},
        candidateMetadata: {'identityScope': 'recording', 'version': 'Live'},
        metadata: {'artworkUrl': 'https://example.test/live-acoustic.jpg'},
      );
      for (final order in [
        [live, acoustic],
        [acoustic, live],
      ]) {
        final song = _enrich(_document(order));
        expect(song.metadata['album'], 'Album');
        expect(
          song.metadata['artworkUrl'],
          'https://example.test/live-acoustic.jpg',
        );
        expect(song.selectedRecording!.durationSeconds, isNull);
      }
    },
  );

  test(
    'album-only display proof cannot unite contradictory donor editions',
    () {
      const selected = SongCandidate(
        providerId: 'primary',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
        album: 'Album',
      );
      final live = _source(
        'a',
        metadata: {
          'version': 'Live',
          'artworkUrl': 'https://example.test/live.jpg',
        },
      );
      final studio = _source(
        'b',
        extra: {'version': 'Studio'},
        metadata: {
          'artistCredits': [
            {'name': 'Studio Performer', 'musicbrainzId': 'studio-artist'},
          ],
        },
      );
      for (final order in [
        [live, studio],
        [studio, live],
      ]) {
        final song = _enrich(_document(order, selected: selected));
        expect(song.metadata, isEmpty);
        expect(song.selectedRecording, same(selected));
        expect(song.sources, order);
      }
    },
  );

  for (final placement in ['candidate', 'resolved']) {
    test(
      'verified recording IDs cannot unite contradictory $placement donor editions',
      () {
        const selected = SongCandidate(
          providerId: 'primary',
          id: 'hit',
          title: 'Amber Song',
          artist: 'Example Artist',
          album: 'Album',
          durationSeconds: 120,
          recordingIds: {'isrc': 'shared'},
        );
        final live = _source(
          'a',
          recordingIds: {'isrc': 'shared'},
          candidateMetadata: {
            'identityScope': 'recording',
            if (placement == 'candidate') 'version': 'Live',
          },
          metadata: {
            'artworkUrl': 'https://example.test/live.jpg',
            if (placement == 'resolved') 'version': 'Live',
          },
        );
        final studio = _source(
          'b',
          recordingIds: {'isrc': 'shared'},
          candidateMetadata: {
            'identityScope': 'recording',
            if (placement == 'candidate') 'version': 'Studio',
          },
          extra: {if (placement == 'resolved') 'version': 'Studio'},
        );
        expect(recordingCompatible(selected, live), true);
        expect(recordingCompatible(selected, studio), true);
        for (final order in [
          [live, studio],
          [studio, live],
        ]) {
          final song = _enrich(_document(order, selected: selected));
          expect(song.metadata, isEmpty);
          expect(song.selectedRecording, same(selected));
          expect(song.sources, order);
        }
      },
    );
  }

  test(
    'verified ID display evidence keeps unknown and partial-descriptor positives',
    () {
      const selected = SongCandidate(
        providerId: 'primary',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
        recordingIds: {'isrc': 'shared'},
      );
      final live = _source(
        'a',
        recordingIds: {'isrc': 'shared'},
        metadata: {
          'version': 'Live',
          'artworkUrl': 'https://example.test/live.jpg',
        },
      );
      final unknown = _source('b', recordingIds: {'isrc': 'shared'});
      final acoustic = _source(
        'c',
        recordingIds: {'isrc': 'shared'},
        metadata: {'version': 'Live'},
        extra: {'edition': 'Acoustic'},
      );
      for (final peer in [unknown, acoustic]) {
        for (final order in [
          [live, peer],
          [peer, live],
        ]) {
          final song = _enrich(_document(order, selected: selected));
          expect(song.metadata['artworkUrl'], 'https://example.test/live.jpg');
          expect(song.metadata['album'], 'Album');
          expect(song.selectedRecording, same(selected));
        }
      }
    },
  );

  test(
    'shared recording proof recovers display fields from a single source',
    () {
      const selected = SongCandidate(
        providerId: 'primary',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
        recordingIds: {'isrc': 'same'},
      );
      final song = _enrich(
        _document([
          _source(
            'a',
            recordingIds: {'isrc': 'same'},
            metadata: {'artworkUrl': 'https://example.test/a.jpg'},
          ),
        ], selected: selected),
      );
      expect(song.metadata['album'], 'Album');
      expect(song.metadata['artworkUrl'], 'https://example.test/a.jpg');
    },
  );

  test('MusicBrainz shaped artist credits enrich a sparse selected album', () {
    const selected = SongCandidate(
      providerId: 'primary',
      id: 'hit',
      title: 'Amber Song',
      artist: 'Example Artist',
      album: 'Album',
    );
    const primaryCredit = {
      'name': 'Example Artist',
      'musicbrainzId': 'artist-1',
    };
    const additionalCredit = {
      'name': 'Guest Performer',
      'musicbrainzId': 'artist-2',
    };
    final musicBrainz = _source(
      'musicbrainz',
      recordingIds: {'musicbrainz': 'recording-1'},
      candidateMetadata: {
        'identityScope': 'recording',
        'artistCredits': [primaryCredit, additionalCredit],
      },
    );
    final song = combineSources(selected, [_lyrics(), musicBrainz]);
    expect(recordingCompatible(selected, musicBrainz), false);
    expect(song.metadata['artistCredits'], [primaryCredit, additionalCredit]);
    expect(song.extra['fieldOrigins']['artistCredits'], musicBrainz.id);
    expect(song.extra['fieldContributors']['artistCredits'], [musicBrainz.id]);
    final restored = SongDocument.fromJson(
      jsonDecode(jsonEncode(song.toJson())),
    );
    expect(restored.metadata['artistCredits'], song.metadata['artistCredits']);
    expect(restored.extra['fieldContributors']['artistCredits'], [
      musicBrainz.id,
    ]);
  });

  test('contradictory edition facts reject same-title same-album donors', () {
    const selected = SongCandidate(
      providerId: 'primary',
      id: 'hit',
      title: 'Amber Song',
      artist: 'Example Artist',
      album: 'Album',
      metadata: {'version': 'Studio mono'},
    );
    for (final facts in [
      {'version': 'Live'},
      {'version': 'Club remix'},
      {'disambiguation': 'Live at Example Hall'},
      {'edition': '2011 remaster'},
      {'recording': 'Stereo'},
    ]) {
      final candidateVersion = _source(
        'a',
        candidateMetadata: {'identityScope': 'recording', ...facts},
      );
      final sourceVersion = _source('b', metadata: facts);
      expect(
        _enrich(
          _document([candidateVersion, sourceVersion], selected: selected),
        ).metadata,
        isEmpty,
      );
    }
  });

  test(
    'conflicting selected candidate and resolved version facts never establish consensus',
    () {
      const selected = SongCandidate(
        providerId: 'primary',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
        album: 'Album',
        metadata: {'version': 'Studio'},
      );
      final conflicting = _source(
        'a',
        candidateMetadata: {'identityScope': 'recording', 'version': 'Studio'},
        metadata: {'version': 'Live'},
      );
      final other = _source(
        'b',
        candidateMetadata: {'identityScope': 'recording', 'version': 'Live'},
      );
      expect(
        _enrich(_document([conflicting, other], selected: selected)).metadata,
        isEmpty,
      );
    },
  );

  test('the same explicit recording version can recover display metadata', () {
    const selected = SongCandidate(
      providerId: 'primary',
      id: 'hit',
      title: 'Amber Song',
      artist: 'Example Artist',
      album: 'Album',
      metadata: {'version': 'Studio'},
    );
    final donor = _source(
      'a',
      candidateMetadata: {'identityScope': 'recording', 'version': 'studio'},
      metadata: {'artworkUrl': 'https://example.test/studio.jpg'},
    );
    expect(
      _enrich(_document([donor], selected: selected)).metadata['artworkUrl'],
      'https://example.test/studio.jpg',
    );
  });

  test(
    'a title live qualifier cannot be overridden by contradictory studio metadata',
    () {
      const selected = SongCandidate(
        providerId: 'primary',
        id: 'hit',
        title: 'Amber Song (Live)',
        artist: 'Example Artist',
        album: 'Album',
        metadata: {'version': 'Studio'},
      );
      final donor = _source(
        'a',
        title: 'Amber Song (Live)',
        candidateMetadata: {'identityScope': 'recording', 'version': 'Studio'},
      );
      expect(_enrich(_document([donor], selected: selected)).metadata, isEmpty);
    },
  );

  test(
    'unknown selected edition permits proven MusicBrainz credit enrichment',
    () {
      const selected = SongCandidate(
        providerId: 'primary',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
        recordingIds: {'musicbrainz': 'same-id'},
      );
      const credit = {'name': 'Example Artist', 'musicbrainzId': 'artist-id'};
      final donor = _source(
        'musicbrainz',
        recordingIds: {'musicbrainz': 'same-id'},
        candidateMetadata: {
          'identityScope': 'recording',
          'version': 'Studio',
          'artistCredits': [credit],
        },
      );
      final song = _enrich(_document([donor], selected: selected));
      expect(recordingCompatible(selected, donor), true);
      expect(song.metadata['album'], 'Album');
      expect(song.metadata['artistCredits'], [credit]);
    },
  );

  test(
    'compatible partial live-acoustic descriptors retain original album proof',
    () {
      const selected = SongCandidate(
        providerId: 'primary',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
        album: 'Album',
        metadata: {'version': 'Live'},
      );
      final donor = _source(
        'a',
        candidateMetadata: {
          'identityScope': 'recording',
          'version': 'Live',
          'edition': 'Acoustic',
        },
        metadata: {'artworkUrl': 'https://example.test/live-acoustic.jpg'},
      );
      final song = _enrich(_document([donor], selected: selected));
      expect(
        song.metadata['artworkUrl'],
        'https://example.test/live-acoustic.jpg',
      );
      expect(song.metadata['durationSeconds'], 120);
    },
  );

  test(
    'unknown selected edition cannot excuse internally conflicting source facts',
    () {
      final donor = _source(
        'a',
        candidateMetadata: {'identityScope': 'recording', 'version': 'Studio'},
        metadata: {'disambiguation': 'Live'},
      );
      final song = _enrich(_document([donor, _source('b')]));
      expect(song.metadata, isEmpty);
    },
  );

  test(
    'original known album can recover display fields without timing proof',
    () {
      const selected = SongCandidate(
        providerId: 'primary',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
        album: 'Album',
      );
      final donor = _source(
        'a',
        metadata: {'artworkUrl': 'https://example.test/a.jpg'},
      );
      final song = _enrich(_document([donor], selected: selected));
      expect(song.metadata['durationSeconds'], 120);
      expect(song.metadata['artworkUrl'], 'https://example.test/a.jpg');
      expect(recordingCompatible(selected, donor), false);
    },
  );

  test('known selected recording ID and duration conflicts reject donors', () {
    const selected = SongCandidate(
      providerId: 'primary',
      id: 'hit',
      title: 'Amber Song',
      artist: 'Example Artist',
      album: 'Album',
      durationSeconds: 120,
      recordingIds: {'isrc': 'same'},
    );
    expect(
      _enrich(
        _document([
          _source('a', recordingIds: {'isrc': 'wrong'}),
          _source('b', duration: 150),
        ], selected: selected),
      ).metadata,
      isEmpty,
    );
  });

  for (final scope in [
    'historicalText',
    'composition',
    'work',
    'artist',
    'image',
    'arrangement',
  ]) {
    test('$scope scope cannot donate recording display fields', () {
      final song = _enrich(
        _document([
          _source('a', candidateMetadata: {'identityScope': scope}),
          _source('b', candidateMetadata: {'identityScope': scope}),
        ]),
      );
      expect(song.metadata, isEmpty);
    });
  }

  test(
    'near titles explicit edition differences and artist differences are rejected',
    () {
      for (final donor in [
        _source('a', title: 'Amber Songs'),
        _source('a', title: 'Amber Song (Live)'),
        _source('a', title: 'Amber Song - 2011 Remaster'),
        _source('a', artist: 'Someone Else'),
      ]) {
        expect(_enrich(_document([donor, _source('b')])).metadata, isEmpty);
      }
    },
  );

  test('pending rejected and unverified sources do not corroborate', () {
    for (final donor in [
      _source('a', extra: {'pendingMatchCheck': true}),
      _source('a', kind: MatchKind.rejected),
      _source('a', kind: MatchKind.unverified),
    ]) {
      expect(_enrich(_document([donor, _source('b')])).metadata, isEmpty);
    }
  });

  test('inconsistent raw album or duration aliases cannot donate', () {
    for (final donor in [
      _source('a', metadata: {'album': 'Other album'}),
      _source('a', metadata: {'durationSeconds': 150}),
    ]) {
      expect(_enrich(_document([donor, _source('b')])).metadata, isEmpty);
    }
  });

  test('artwork accepts only credential-free HTTPS source URLs', () {
    for (final url in [
      'http://example.test/a',
      'https://user:secret@example.test/a',
      'file:///private/a',
      'data:image/png;base64,x',
      'not a URL',
    ]) {
      final song = _enrich(
        _document([
          _source('a', metadata: {'artworkUrl': url}),
          _source('b'),
        ]),
      );
      expect(song.metadata['album'], 'Album');
      expect(song.metadata['artworkUrl'], isNull);
    }
  });

  test(
    'filled display fields never upgrade third-party timing or key identity',
    () {
      final timed = _source(
        'a',
        body: _words,
        metadata: {'key': 'D', 'capo': 4},
        tracks: [
          parseLrc(
            '[00:01]Amber lanterns glow\n[00:04]Silver rain returns',
            sourceDocumentId: 'a:hit',
          ),
        ],
      );
      final song = combineSources(_selected, [
        _lyrics(),
        timed,
        _source('b'),
      ], preferredSourceId: 'primary:hit');
      expect(song.metadata['album'], 'Album');
      expect(song.metadata['durationSeconds'], 120);
      expect(song.selectedRecording!.album, isNull);
      expect(song.selectedRecording!.durationSeconds, isNull);
      expect(recordingCompatible(song.selectedRecording!, timed), false);
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
}
