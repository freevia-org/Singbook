import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/recording_context.dart';

const _id = 'b5d7d380-f43a-4c1f-a5de-694150b093ac';
const _otherId = '099b148e-fe99-4b79-be6e-5078e4bb7415';
const _original = SongCandidate(
  providerId: 'genius',
  id: 'selection-81',
  title: 'Lantern Map',
  artist: 'June Harbor',
  durationSeconds: 214,
  metadata: {'identityScope': 'recording'},
);

SongCandidate _candidate({
  String providerId = 'musicbrainz',
  String id = _id,
  String title = 'Lantern Map',
  String? album = 'Paper Moons',
  double? duration = 214,
  Map<String, String>? ids,
  JsonMap metadata = const {'identityScope': 'recording'},
}) => SongCandidate(
  providerId: providerId,
  id: id,
  title: title,
  artist: 'June Harbor',
  album: album,
  durationSeconds: duration,
  recordingIds: ids ?? {'musicbrainz': id},
  metadata: metadata,
);

SourceResult _anchor({double duration = 214, JsonMap metadata = const {}}) =>
    SourceResult(
      candidate: _candidate(
        providerId: 'genius',
        id: _original.id,
        ids: const {},
        duration: duration,
      ),
      body: 'Paper boats drift past the orchard wall',
      metadata: metadata,
      matchKind: MatchKind.sameRecording,
    );

SourceResult _donor({
  SongCandidate? candidate,
  MatchKind kind = MatchKind.sameRecording,
  JsonMap metadata = const {},
  JsonMap extra = const {},
}) => SourceResult(
  candidate: candidate ?? _candidate(),
  body: '',
  metadata: metadata,
  extra: {'metadataOnly': true, ...extra},
  matchKind: kind,
);

RecordingContextPlan? _plan(
  List<SourceResult> sources, {
  SongCandidate original = _original,
  Set<String> disabled = const {},
}) => planRecordingContext(
  original,
  sources,
  namespace: 'musicbrainz',
  eligible: (id) => !disabled.contains(id),
);

void main() {
  test(
    'a conflicting duplicate witness cannot hide beside the pinned result',
    () {
      final anchor = _anchor(), donor = _donor();
      final plan = _plan([anchor, donor])!;
      final conflict = _donor(metadata: const {'album': 'Another Album'});
      expect(
        plan.isCurrent(
          [anchor, donor, conflict],
          original: _original,
          eligible: (_) => true,
        ),
        isFalse,
      );
      expect(
        _plan([
          anchor,
          _donor(metadata: const {'album': 42}),
        ]),
        isNull,
      );
    },
  );

  test('accepts the actual legacy unscoped Genius recording anchor', () {
    final anchor = SourceResult(
      candidate: _candidate(
        providerId: 'genius',
        id: _original.id,
        ids: const {},
        metadata: const {},
      ),
      body: 'Paper boats drift past the orchard wall',
      matchKind: MatchKind.sameRecording,
    );
    expect(_plan([anchor, _donor()]), isNotNull);
  });

  test(
    'one independently qualified direct recording donor needs no lyric query',
    () {
      final original = SongCandidate.fromJson({
        ..._original.toJson(),
        'album': 'Paper Moons',
      });
      expect(_plan([_donor()], original: original), isNotNull);
    },
  );

  test('same MBID does not hide conflicting identifier witnesses', () {
    final original = SongCandidate.fromJson({
      ..._original.toJson(),
      'album': 'Paper Moons',
    });
    final a = SourceResult(
      candidate: _candidate(
        providerId: 'source-a',
        id: 'a',
        ids: const {'isrc': 'TEST-A'},
      ),
      body: '',
      matchKind: MatchKind.sameRecording,
    );
    final b = SourceResult(
      candidate: _candidate(
        providerId: 'source-b',
        id: 'b',
        ids: const {'isrc': 'TEST-B'},
      ),
      body: '',
      matchKind: MatchKind.sameRecording,
    );
    final donor = _donor();
    expect(_plan([a, b, donor], original: original), isNull);
    expect(_plan([donor, b, a], original: original), isNull);
  });

  test('hash binds mutable original and derived lookup maps are isolated', () {
    final ids = <String, String>{};
    final original = SongCandidate(
      providerId: _original.providerId,
      id: _original.id,
      title: _original.title,
      artist: _original.artist,
      durationSeconds: 214,
      recordingIds: ids,
    );
    final sources = [_anchor(), _donor()];
    final plan = _plan(sources, original: original)!;
    plan.selection.recordingIds['musicbrainz'] = _otherId;
    expect(plan.selection.recordingIds['musicbrainz'], _id);
    expect(
      plan.isCurrent(sources, original: original, eligible: (_) => true),
      isTrue,
    );
    ids['isrc'] = 'TEST-CHANGED';
    expect(
      plan.isCurrent(sources, original: original, eligible: (_) => true),
      isFalse,
    );
  });

  test(
    'extra facts and out-of-range durations cannot bypass triple consistency',
    () {
      for (final extra in [
        {'album': 'Another Album'},
        {'durationSeconds': 220},
        {'durationSeconds': 86401},
      ]) {
        expect(_plan([_anchor(), _donor(extra: extra)]), isNull);
      }
    },
  );

  test(
    'bridges an independently resolved recording without mutating selection',
    () {
      final anchor = _anchor(), donor = _donor();
      final plan = _plan([anchor, donor])!;
      expect(plan.selection.identity, _original.identity);
      expect(plan.selection.album, 'Paper Moons');
      expect(plan.selection.recordingIds, {'musicbrainz': _id});
      expect(_original.album, isNull);
      expect(_original.recordingIds, isEmpty);
      expect(plan.provenance['selectedIdentity'], _original.identity);
      expect(plan.witnesses, [anchor, donor]);
      for (final witness in plan.provenance['witnesses'] as List) {
        expect(witness['sha256'], matches(RegExp(r'^[0-9a-f]{64}$')));
      }
      expect(
        plan.isCurrent(
          [anchor, donor],
          original: _original,
          eligible: (_) => true,
        ),
        isTrue,
      );
    },
  );

  test('does not add a late pass when selected MBID already exists', () {
    final original = SongCandidate.fromJson({
      ..._original.toJson(),
      'recordingIds': {'musicbrainz': _id},
    });
    expect(_plan([_anchor(), _donor()], original: original), isNull);
  });

  test(
    'does not manufacture context from the selection or unanchored donor',
    () {
      expect(_plan([]), isNull);
      // Matching title and duration without an album/shared ID is insufficient.
      expect(_plan([_donor()]), isNull);
      expect(_plan([_anchor()]), isNull);
    },
  );

  for (final kind in [
    MatchKind.sameSong,
    MatchKind.unverified,
    MatchKind.rejected,
  ]) {
    test('does not upgrade a ${kind.name} donor', () {
      expect(_plan([_anchor(), _donor(kind: kind)]), isNull);
    });
  }

  for (final scope in [
    'composition',
    'arrangement',
    'song',
    'image',
    'historicalText',
  ]) {
    test(
      'rejects conflicting $scope scope even with a shared recording ID',
      () {
        expect(
          _plan([
            _anchor(),
            _donor(metadata: {'identityScope': scope}),
          ]),
          isNull,
        );
      },
    );
  }

  test('does not accept an arbitrary provider as the canonical MB donor', () {
    expect(
      _plan([_anchor(), _donor(candidate: _candidate(providerId: 'other'))]),
      isNull,
    );
  });

  test('rejects an absent, malformed or mismatched canonical MBID', () {
    for (final candidate in [
      _candidate(ids: const {}),
      _candidate(ids: const {'musicbrainz': 'not-an-id'}),
      _candidate(ids: const {'musicbrainz': _otherId}),
    ]) {
      expect(_plan([_anchor(), _donor(candidate: candidate)]), isNull);
    }
  });

  test('conflicting qualified donors cannot be resolved by source order', () {
    final a = _donor(), b = _donor(candidate: _candidate(id: _otherId));
    expect(_plan([_anchor(), a, b]), isNull);
    expect(_plan([b, a, _anchor()]), isNull);
  });

  test('direct endpoint check rejects cumulative three-second drift', () {
    expect(
      _plan([
        _anchor(duration: 217),
        _donor(candidate: _candidate(duration: 220)),
      ]),
      isNull,
    );
  });

  test(
    'an ID conflict is not hidden by a resolved anchor omitting that ID',
    () {
      final original = SongCandidate.fromJson({
        ..._original.toJson(),
        'recordingIds': {'isrc': 'TEST-A'},
      });
      expect(
        _plan([
          _anchor(),
          _donor(
            candidate: _candidate(
              ids: const {'musicbrainz': _id, 'isrc': 'TEST-B'},
            ),
          ),
        ], original: original),
        isNull,
      );
    },
  );

  test('rejects editions contradicted only in donor response metadata', () {
    expect(
      _plan([
        _anchor(metadata: const {'version': 'studio'}),
        _donor(metadata: const {'version': 'live'}),
      ]),
      isNull,
    );
  });

  test('does not ignore conflicting repeated duration or album facts', () {
    for (final metadata in [
      {'durationSeconds': 225},
      {'duration': double.nan},
      {'album': 'Another Album'},
    ]) {
      expect(_plan([_anchor(), _donor(metadata: metadata)]), isNull);
    }
  });

  test('pending identity proof cannot donate or anchor context', () {
    expect(
      _plan([
        _anchor(),
        _donor(extra: const {'pendingMatchCheck': true}),
      ]),
      isNull,
    );
    expect(
      _plan([
        _anchor(metadata: const {'pendingMatchCheck': true}),
        _donor(),
      ]),
      isNull,
    );
  });

  for (final disabled in ['genius', 'musicbrainz']) {
    test('opt-out of $disabled invalidates planning and a completed plan', () {
      final sources = [_anchor(), _donor()];
      expect(_plan(sources, disabled: {disabled}), isNull);
      final plan = _plan(sources)!;
      expect(
        plan.isCurrent(
          sources,
          original: _original,
          eligible: (id) => id != disabled,
        ),
        isFalse,
      );
    });
  }

  test('withdrawal and later mutation of a witness invalidate its proof', () {
    final metadata = <String, dynamic>{'album': 'Paper Moons'};
    final anchor = _anchor(), donor = _donor(metadata: metadata);
    final plan = _plan([anchor, donor])!;
    expect(
      plan.isCurrent([anchor], original: _original, eligible: (_) => true),
      isFalse,
    );
    metadata['album'] = 'A Different Release';
    expect(
      plan.isCurrent(
        [anchor, donor],
        original: _original,
        eligible: (_) => true,
      ),
      isFalse,
    );
  });

  test(
    'safe handoff retains only anchor context, never donor estimates or tags',
    () {
      final plan = _plan([
        _anchor(),
        _donor(
          metadata: const {
            'key': 'D',
            'bpm': 111,
            'privateTag': 'uploaded-file',
          },
        ),
      ])!;
      expect(plan.selection.metadata, _original.metadata);
      expect(plan.selection.extra, _original.extra);
      expect(plan.provenance.toString(), isNot(contains('uploaded-file')));
    },
  );
}
