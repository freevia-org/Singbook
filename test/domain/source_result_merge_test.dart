import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart' show plainLyrics;
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/source_result_merge.dart';
import 'package:singbook/domain/timing.dart';

const _body =
    'Amber lanterns cross the silent harbor tonight\n'
    'Silver windows catch the morning sunlight again';
const _fuller =
    'Amber lanterns cross the silent harbor tonight\n'
    'One more quiet verse returns before the dawn\n'
    'Silver windows catch the morning sunlight again';
const _chart =
    '{start_of_verse}\n'
    '[C]Amber lanterns cross the silent harbor tonight\n'
    '[G]Silver windows catch the morning sunlight again\n'
    '{end_of_verse}';
const _candidate = SongCandidate(
  providerId: 'fixture',
  id: 'hit',
  title: 'Amber Song',
  artist: 'Example Artist',
);

TimingTrack _track(String raw) =>
    parseLrc(raw, sourceDocumentId: 'fixture:hit');

SourceResult _source({
  SongCandidate candidate = _candidate,
  String body = _body,
  JsonMap metadata = const {},
  JsonMap extra = const {},
  MatchKind kind = MatchKind.sameSong,
  List<TimingTrack> tracks = const [],
  String? reason,
  DateTime? retrievedAt,
}) => SourceResult(
  candidate: candidate,
  body: body,
  metadata: metadata,
  extra: extra,
  matchKind: kind,
  timingTracks: tracks,
  matchReason: reason,
  retrievedAt: retrievedAt,
  attribution: 'Synthetic fixture attribution',
);

List<JsonMap> _history(SourceResult source) =>
    (source.extra['previousSourceVersions'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => jsonMap(value))
        .toList();

void main() {
  test(
    'resolved-only contradictory editions cannot borrow each others accepted evidence',
    () {
      final previous = _source(
        metadata: {'version': 'Studio', 'album': 'Studio Facts'},
        tracks: [_track('[00:01]$_body')],
      );
      final incoming = _source(body: '', metadata: {'version': 'Live'});
      final merged = mergeSourceResult(previous, incoming);
      expect(merged.body, incoming.body);
      expect(merged.metadata, incoming.metadata);
      expect(merged.timingTracks, isEmpty);
      expect(
        _history(
          merged,
        ).any((payload) => jsonMap(payload['metadata'])['version'] == 'Studio'),
        true,
      );
    },
  );

  test(
    'pending evidence in every raw map cannot donate accepted display facts',
    () {
      final previous = _source();
      for (var location = 0; location < 4; location++) {
        final pending = <String, dynamic>{'pendingMatchCheck': true};
        final incoming = _source(
          body: '',
          candidate: SongCandidate(
            providerId: 'fixture',
            id: 'hit',
            title: 'Amber Song',
            artist: 'Example Artist',
            album: 'Unvalidated Album',
            durationSeconds: 120,
            metadata: location == 0 ? pending : const {},
            extra: location == 1 ? pending : const {},
          ),
          metadata: location == 2 ? pending : const {},
          extra: location == 3 ? pending : const {},
        );
        final merged = mergeSourceResult(previous, incoming);
        expect(merged.candidate, same(previous.candidate));
        expect(merged.metadata, isEmpty);
        expect(merged.body, previous.body);
        expect(
          _history(merged).any(
            (payload) =>
                jsonMap(payload['candidate'])['album'] == 'Unvalidated Album',
          ),
          isTrue,
        );
      }
    },
  );

  test(
    'late blank cannot erase accepted lyrics facts attribution or raw timing',
    () {
      final track = _track('[00:01]$_body');
      final previous = _source(
        metadata: {
          'album': 'Known Album',
          'writers': ['A'],
        },
        tracks: [track],
      );
      final incoming = _source(
        body: '',
        metadata: {'album': '', 'writers': []},
      );
      final merged = mergeSourceResult(previous, incoming);
      expect(merged.body, previous.body);
      expect(merged.metadata, previous.metadata);
      expect(merged.candidate, same(previous.candidate));
      expect(merged.timingTracks.single, same(track));
      expect(merged.attribution, previous.attribution);
      expect(_history(merged).any((payload) => payload['body'] == ''), isTrue);
    },
  );

  test(
    'unverified and pending updates cannot inherit prior accepted authority',
    () {
      final track = _track('[00:01]$_body');
      final previous = _source(
        metadata: {'album': 'Known Album'},
        tracks: [track],
      );
      for (final incoming in [
        _source(
          body: _fuller,
          kind: MatchKind.unverified,
          metadata: {
            'key': 'D',
            'artworkUrl': 'https://example.test/unverified.jpg',
          },
        ),
        _source(
          body: _fuller,
          extra: {'pendingMatchCheck': true},
          metadata: {
            'key': 'D',
            'artworkUrl': 'https://example.test/pending.jpg',
          },
        ),
      ]) {
        final merged = mergeSourceResult(previous, incoming);
        expect(merged.body, previous.body);
        expect(merged.matchKind, previous.matchKind);
        expect(merged.metadata, previous.metadata);
        expect(merged.timingTracks.single, same(track));
        expect(
          _history(merged).any((payload) => payload['body'] == _fuller),
          isTrue,
        );
      }
    },
  );

  test(
    'same-rank partial lyrics cannot truncate a complete accepted payload',
    () {
      final previous = _source(
        body: _fuller,
        metadata: {
          'credits': ['A'],
        },
      );
      final merged = mergeSourceResult(previous, _source(body: _body));
      expect(merged.body, _fuller);
      expect(merged.metadata['credits'], ['A']);
      expect(
        _history(merged).any((payload) => payload['body'] == _body),
        isTrue,
      );
    },
  );

  test(
    'identical accepted lyrics retain old timing when a refresh omits tracks',
    () {
      final track = _track('[00:01]$_body');
      final previous = _source(
        tracks: [track],
        metadata: {
          'writers': ['A'],
        },
      );
      const fresh = SongCandidate(
        providerId: 'fixture',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
        album: 'Album',
        durationSeconds: 120,
      );
      final incoming = _source(
        candidate: fresh,
        metadata: {
          'credits': ['B'],
        },
      );
      final merged = mergeSourceResult(previous, incoming);
      expect(merged.body, previous.body);
      expect(merged.matchKind, previous.matchKind);
      expect(merged.candidate, same(previous.candidate));
      expect(merged.candidate.album, isNull);
      expect(merged.candidate.durationSeconds, isNull);
      expect(merged.timingTracks.single, same(track));
      expect(merged.metadata['credits'], ['B']);
      expect(merged.metadata['album'], 'Album');
      expect(
        _history(merged).any(
          (payload) =>
              payload['candidate']['album'] == 'Album' &&
              (payload['timingTracks'] as List).isEmpty,
        ),
        isTrue,
      );
    },
  );

  test(
    'stronger recording evidence never inherits earlier timing from sparse evidence',
    () {
      final track = _track('[00:01]$_body');
      final previous = _source(tracks: [track]);
      const stronger = SongCandidate(
        providerId: 'fixture',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
        album: 'Album',
        durationSeconds: 120,
        recordingIds: {'isrc': 'NEW-PROOF'},
      );
      final incoming = _source(
        candidate: stronger,
        kind: MatchKind.sameRecording,
      );
      final merged = mergeSourceResult(previous, incoming);
      expect(merged.candidate, same(stronger));
      expect(merged.matchKind, MatchKind.sameRecording);
      expect(merged.timingTracks, isEmpty);
      expect(
        _history(merged).any(
          (payload) => (payload['timingTracks'] as List).any(
            (raw) => raw['raw'] == track.raw,
          ),
        ),
        isTrue,
      );
    },
  );

  test(
    'compatible fuller lyric variant upgrades as one whole source payload',
    () {
      final oldTrack = _track('[00:01]$_body');
      final newTrack = _track('[00:02]$_fuller');
      final merged = mergeSourceResult(
        _source(tracks: [oldTrack]),
        _source(body: _fuller, tracks: [newTrack]),
      );
      expect(merged.body, _fuller);
      expect(merged.timingTracks.single, same(newTrack));
      expect(_history(merged).single['body'], _body);
      expect(_history(merged).single['timingTracks'][0]['raw'], oldTrack.raw);
    },
  );

  test(
    'same lyrics with newly supplied chords and sections upgrade safely',
    () {
      final oldTrack = _track('[00:01]$_body');
      final newTrack = _track('[00:02]$_body');
      final merged = mergeSourceResult(
        _source(tracks: [oldTrack]),
        _source(body: _chart, tracks: [newTrack]),
      );
      expect(plainLyrics(merged.body), plainLyrics(_body));
      expect(merged.body, _chart);
      expect(merged.hasChords, isTrue);
      expect(merged.timingTracks.single, same(newTrack));
      expect(_history(merged).single['body'], _body);
    },
  );

  test(
    'conflicting chord placements or arrangement setup cannot replace chosen data',
    () {
      final oldChart = _chart;
      final changedChords = _chart
          .replaceAll('[C]', '[D]')
          .replaceAll('[G]', '[A]');
      final previous = _source(
        body: oldChart,
        metadata: {
          'capo': 0,
          'tuning': ['E', 'A', 'D', 'G', 'B', 'E'],
        },
      );
      for (final incoming in [
        _source(body: changedChords, metadata: previous.metadata),
        _source(
          body: _chart,
          metadata: {
            'capo': 3,
            'tuning': ['D', 'A', 'D', 'G', 'B', 'E'],
          },
        ),
      ]) {
        final merged = mergeSourceResult(previous, incoming);
        expect(merged.body, oldChart);
        expect(merged.metadata['capo'], 0);
        expect(merged.metadata['tuning'], previous.metadata['tuning']);
        expect(_history(merged), isNotEmpty);
      }
    },
  );

  test(
    'identical tuning arrays retain order repeated pitches and atomic conflicts',
    () {
      const standard = ['E', 'A', 'D', 'G', 'B', 'E'];
      const alternate = ['D', 'A', 'D', 'G', 'B', 'E'];
      final previous = _source(body: _chart, metadata: {'tuning': standard});
      final identical = mergeSourceResult(
        previous,
        _source(body: _chart, metadata: {'tuning': standard}),
      );
      expect(identical.metadata['tuning'], standard);
      expect((identical.metadata['tuning'] as List).length, 6);
      expect(identical.extra['metadataConflicts'], isNull);
      final conflicting = mergeSourceResult(
        previous,
        _source(body: _chart, metadata: {'tuning': alternate}),
      );
      expect(conflicting.metadata['tuning'], standard);
      expect(
        conflicting.extra['metadataConflicts']['tuning'],
        containsAll([standard, alternate]),
      );
      expect(
        _history(conflicting).any(
          (payload) =>
              jsonEncode(payload['metadata']['tuning']) ==
              jsonEncode(alternate),
        ),
        isTrue,
      );
    },
  );

  test(
    'fuller lyrics cannot erase earlier chord offsets or section directives',
    () {
      final oldTrack = _track('[00:01]$_body');
      final previous = _source(body: _chart, tracks: [oldTrack]);
      const missingSections =
          '[C]Amber lanterns cross the silent harbor tonight\n'
          'One more quiet verse returns before the dawn\n'
          '[G]Silver windows catch the morning sunlight again';
      const changedOffset =
          '{start_of_verse}\n'
          'Amber [C]lanterns cross the silent harbor tonight\n'
          'One more quiet verse returns before the dawn\n'
          '[G]Silver windows catch the morning sunlight again\n'
          '{end_of_verse}';
      for (final body in [_fuller, missingSections, changedOffset]) {
        final merged = mergeSourceResult(previous, _source(body: body));
        expect(merged.body, _chart);
        expect(merged.timingTracks.single, same(oldTrack));
        expect(
          _history(merged).any((payload) => payload['body'] == body),
          isTrue,
        );
      }
    },
  );

  test('fuller chart preserving original chords and sections can upgrade', () {
    const fullerChart =
        '{start_of_verse}\n'
        '[C]Amber lanterns cross the silent harbor tonight\n'
        '[Am]One more quiet verse returns before the dawn\n'
        '[G]Silver windows catch the morning sunlight again\n'
        '{end_of_verse}';
    final incomingTrack = _track('[00:02]$_fuller');
    final merged = mergeSourceResult(
      _source(body: _chart),
      _source(body: fullerChart, tracks: [incomingTrack]),
    );
    expect(merged.body, fullerChart);
    expect(merged.timingTracks.single, same(incomingTrack));
    expect(_history(merged).single['body'], _chart);
  });

  test(
    'section-only additions preserve existing chord positions and setup',
    () {
      final withoutSections = _chart
          .replaceAll('{start_of_verse}\n', '')
          .replaceAll('\n{end_of_verse}', '');
      final previous = _source(body: withoutSections, metadata: {'capo': 2});
      final incoming = _source(body: _chart, metadata: {'capo': 2});
      final merged = mergeSourceResult(previous, incoming);
      expect(merged.body, _chart);
      expect(merged.metadata['capo'], 2);
      expect(_history(merged).single['body'], withoutSections);
    },
  );

  test(
    'restricted scopes in any raw location cannot donate through old authority',
    () {
      final previous = _source(metadata: {'existingFact': 'trusted'});
      const donated = {
        'album': 'Restricted Album',
        'durationSeconds': 120,
        'artworkUrl': 'https://example.test/restricted.jpg',
        'credits': ['Unproven'],
      };
      for (final scope in [
        'composition',
        'work',
        'artist',
        'image',
        'historicalText',
        'arrangement',
      ]) {
        for (final location in [
          'candidateMetadata',
          'candidateExtra',
          'sourceMetadata',
          'sourceExtra',
        ]) {
          final candidate = SongCandidate(
            providerId: 'fixture',
            id: 'hit',
            title: 'Amber Song',
            artist: 'Example Artist',
            metadata: location == 'candidateMetadata'
                ? {'identityScope': scope}
                : const {},
            extra: location == 'candidateExtra'
                ? {'identityScope': scope}
                : const {},
          );
          final incoming = _source(
            candidate: candidate,
            body: '',
            metadata: {
              ...donated,
              if (location == 'sourceMetadata') 'identityScope': scope,
            },
            extra: {if (location == 'sourceExtra') 'identityScope': scope},
          );
          final merged = mergeSourceResult(previous, incoming);
          expect(merged.body, previous.body, reason: '$scope in $location');
          expect(
            merged.metadata,
            previous.metadata,
            reason: '$scope in $location',
          );
          expect(merged.candidate, same(previous.candidate));
          expect(
            _history(merged).single['metadata']['album'],
            'Restricted Album',
          );
        }
      }
    },
  );

  test(
    'compatible recording scopes still permit accepted missing display facts',
    () {
      final previous = _source(
        metadata: {'existingFact': 'trusted'},
        candidate: const SongCandidate(
          providerId: 'fixture',
          id: 'hit',
          title: 'Amber Song',
          artist: 'Example Artist',
          metadata: {'identityScope': 'recording'},
        ),
      );
      final incoming = _source(
        body: '',
        metadata: {
          'identityScope': 'recording',
          'album': 'Album',
          'credits': ['A'],
        },
      );
      final merged = mergeSourceResult(previous, incoming);
      expect(merged.candidate, same(previous.candidate));
      expect(merged.body, previous.body);
      expect(merged.metadata, {
        'existingFact': 'trusted',
        'album': 'Album',
        'credits': ['A'],
      });
      expect(
        merged.extra['metadataPayloadOrigins']['album'],
        sourcePayloadFingerprint(incoming),
      );
    },
  );

  test(
    'fresh candidate display facts survive while raw recording evidence stays sparse',
    () {
      const selected = SongCandidate(
        providerId: 'selected',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
      );
      final track = _track(
        '[00:01]Amber lanterns cross the silent harbor tonight\n'
        '[00:04]Silver windows catch the morning sunlight again',
      );
      final previous = _source(tracks: [track]);
      const freshCandidate = SongCandidate(
        providerId: 'fixture',
        id: 'hit',
        title: 'Amber Song',
        artist: 'Example Artist',
        album: 'Album',
        durationSeconds: 120,
        metadata: {'artworkUrl': 'https://example.test/album.jpg', 'key': 'D'},
      );
      final merged = mergeSourceResult(
        previous,
        _source(candidate: freshCandidate, body: ''),
      );
      final corroborating = _source(
        body: '',
        candidate: const SongCandidate(
          providerId: 'other',
          id: 'hit',
          title: 'Amber Song',
          artist: 'Example Artist',
          album: 'Album',
          durationSeconds: 120,
        ),
      );
      final song = combineSources(selected, [merged, corroborating]);
      expect(merged.candidate, same(previous.candidate));
      expect(merged.candidate.album, isNull);
      expect(merged.candidate.durationSeconds, isNull);
      expect(merged.timingTracks.single, same(track));
      expect(song.metadata['album'], 'Album');
      expect(song.metadata['durationSeconds'], 120);
      expect(song.metadata['artworkUrl'], 'https://example.test/album.jpg');
      expect(song.metadata['key'], isNull);
      expect(recordingCompatible(selected, merged), isFalse);
      expect(song.selectedRecording, same(selected));
      expect(song.activeTimingTrackId, isNull);
      expect(song.timingTracks.single.status, TimingStatus.unverified);
    },
  );

  test(
    'authoritative rejection withdraws current authority and archives accepted payload',
    () {
      final previous = _source(metadata: {'album': 'Old Album'});
      final incoming = _source(
        body: '',
        kind: MatchKind.rejected,
        reason: 'identity_mismatch',
      );
      final merged = mergeSourceResult(previous, incoming);
      expect(merged.matchKind, MatchKind.rejected);
      expect(merged.matchReason, 'identity_mismatch');
      expect(merged.body, '');
      expect(merged.metadata, isEmpty);
      expect(_history(merged).single['matchKind'], MatchKind.sameSong.name);
      expect(_history(merged).single['body'], previous.body);
    },
  );

  test(
    'fingerprints distinguish metadata candidate facts and raw timing with identical lyrics',
    () {
      final original = _source(
        metadata: {'album': 'First'},
        tracks: [_track('[00:01]$_body')],
      );
      final variants = [
        _source(metadata: {'album': 'Second'}, tracks: original.timingTracks),
        _source(metadata: original.metadata, tracks: [_track('[00:02]$_body')]),
        _source(
          metadata: original.metadata,
          tracks: original.timingTracks,
          candidate: const SongCandidate(
            providerId: 'fixture',
            id: 'hit',
            title: 'Amber Song',
            artist: 'Example Artist',
            album: 'Candidate Album',
          ),
        ),
      ];
      final fingerprints = [
        original,
        ...variants,
      ].map(sourcePayloadFingerprint).toSet();
      expect(fingerprints, hasLength(4));
    },
  );

  test(
    'archive IDs derived status binding timestamps and history do not change fingerprints',
    () {
      final track = _track('[00:01]$_body');
      final original = _source(
        tracks: [track],
        retrievedAt: DateTime.utc(2020),
      );
      final archivedTrack = TimingTrack.fromJson({
        ...track.toJson(),
        'id': 'history:saved:hash',
        'archivedOriginalTrackId': track.id,
        'status': TimingStatus.stale.name,
        'binding': {'recordingVerified': false},
      });
      final archived = _source(
        tracks: [archivedTrack],
        retrievedAt: DateTime.utc(2025),
        extra: {
          'previousSourceVersions': [original.toJson()],
          'retainedPreviousPayload': true,
        },
      );
      expect(
        sourcePayloadFingerprint(archived),
        sourcePayloadFingerprint(original),
      );
      expect(
        timingPayloadFingerprint(archivedTrack),
        timingPayloadFingerprint(track),
      );
      expect(
        archived.timingTracks.single.raw,
        original.timingTracks.single.raw,
      );
    },
  );

  test(
    'malformed history containers entries and conflict values remain inert and recoverable',
    () {
      for (final extra in <JsonMap>[
        {
          'previousSourceVersions': {'unknown': 'container-sentinel'},
        },
        {'previousSourceVersions': 'container-sentinel'},
        {
          'previousSourceVersions': [
            {'invalid': 'entry-sentinel'},
            'scalar-entry-sentinel',
          ],
        },
        {
          'metadataConflicts': {'album': 'conflict-sentinel'},
        },
      ]) {
        final previous = _source(
          body: _fuller,
          metadata: {'album': 'Known'},
          extra: extra,
        );
        final incoming = _source(metadata: {'album': 'Other'});
        final merged = mergeSourceResult(previous, incoming);
        expect(merged.body, _fuller);
        expect(merged.matchKind, MatchKind.sameSong);
        expect(merged.metadata['album'], 'Known');
        final encoded = jsonEncode(merged.toJson());
        for (final marker in [
          'container-sentinel',
          'entry-sentinel',
          'scalar-entry-sentinel',
          'conflict-sentinel',
        ]) {
          if (jsonEncode(extra).contains(marker)) {
            expect(encoded, contains(marker));
          }
        }
        expect(SourceResult.fromJson(jsonDecode(encoded)).body, _fuller);
      }
    },
  );

  test(
    'chosen scalar values keep priority while list facts union and conflicts persist',
    () {
      final previous = _source(
        metadata: {
          'label': 'Previous',
          'writers': ['B', 'A'],
        },
      );
      final incoming = _source(
        metadata: {
          'label': 'Incoming',
          'writers': ['C', 'A'],
        },
      );
      final forward = mergeSourceResult(previous, incoming);
      final reverse = mergeSourceResult(incoming, previous);
      expect(forward.metadata['label'], 'Incoming');
      expect(reverse.metadata['label'], 'Previous');
      expect(forward.metadata['writers'], ['A', 'B', 'C']);
      expect(reverse.metadata['writers'], ['A', 'B', 'C']);
      expect(forward.extra['metadataConflicts']['label'], [
        'Incoming',
        'Previous',
      ]);
      expect(reverse.extra['metadataConflicts']['label'], [
        'Incoming',
        'Previous',
      ]);
    },
  );

  test(
    'raw snapshots roundtrip without recursive history or repeated identical growth',
    () {
      final previous = _source(
        metadata: {'album': 'Album'},
        tracks: [_track('[00:01]$_body')],
      );
      final incoming = _source(
        body: '',
        metadata: {
          'credits': ['A'],
        },
      );
      final once = mergeSourceResult(previous, incoming);
      final twice = mergeSourceResult(once, incoming);
      final restored = SourceResult.fromJson(
        jsonDecode(jsonEncode(twice.toJson())),
      );
      expect(sourcePayloadFingerprint(twice), sourcePayloadFingerprint(once));
      expect(_history(twice).length, _history(once).length);
      expect(restored.toJson(), twice.toJson());
      expect(
        _history(
          twice,
        ).every((payload) => !payload.containsKey('previousSourceVersions')),
        isTrue,
      );
      expect(_history(twice).map((payload) => payload['body']), contains(''));
      expect(
        _history(twice).any(
          (payload) => (payload['timingTracks'] as List).any(
            (track) => track['raw'] == previous.timingTracks.single.raw,
          ),
        ),
        isTrue,
      );
    },
  );

  test(
    'conflicting recording identity cannot borrow accepted facts or timing',
    () {
      final previous = _source(
        metadata: {'oldOnly': 'previous'},
        tracks: [_track('[00:01]$_body')],
        candidate: const SongCandidate(
          providerId: 'fixture',
          id: 'hit',
          title: 'Amber Song',
          artist: 'Example Artist',
          album: 'Old',
          durationSeconds: 120,
          recordingIds: {'isrc': 'OLD'},
        ),
      );
      final incoming = _source(
        metadata: {'newOnly': 'incoming'},
        candidate: const SongCandidate(
          providerId: 'fixture',
          id: 'hit',
          title: 'Amber Song',
          artist: 'Example Artist',
          album: 'New',
          durationSeconds: 180,
          recordingIds: {'isrc': 'NEW'},
        ),
      );
      final merged = mergeSourceResult(previous, incoming);
      expect(merged.candidate, same(incoming.candidate));
      expect(merged.metadata, incoming.metadata);
      expect(merged.timingTracks, isEmpty);
      expect(_history(merged).single['metadata'], previous.metadata);
    },
  );
}
