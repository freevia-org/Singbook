import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/chart_arrangements.dart';
import 'package:singbook/domain/models.dart';

const _candidate = SongCandidate(
  providerId: 'chart-provider',
  id: 'provider-chart-42',
  title: 'Example Song',
  artist: 'Example Artist',
  url: 'https://example.invalid/chart/42',
  metadata: {'capo': 1, 'difficulty': 'intermediate'},
);

SourceResult _source(String body) => SourceResult(
  candidate: _candidate,
  body: body,
  metadata: _candidate.metadata,
  matchKind: MatchKind.sameSong,
  extra: const {
    'discoveryEvidence': {
      'acceptedPayloads': ['parent raw payload'],
    },
  },
);

void main() {
  test('splits explicit capo and version boundaries into stable views', () {
    const body = '''Capo I
[C]amber harbor
The Example Song chords (version 2)
Capo IV
[G]silver hillside
[Am]quiet garden
Arrangement 3
Capo VI
Key: D
Tuning: D A D G B E
[D]morning meadow
[A]gentle river''';
    final parent = _source(body);
    final views = splitChartArrangements(parent);

    expect(views, hasLength(3));
    expect(views.map((view) => view.metadata['capo']), [1, 4, 6]);
    expect(views[2].metadata['key'], 'D');
    expect(views[2].metadata['tuning'], 'D A D G B E');
    expect(views.map((view) => view.body), [
      '[C]amber harbor',
      '[G]silver hillside\n[Am]quiet garden',
      '[D]morning meadow\n[A]gentle river',
    ]);
    expect(views.map((view) => view.arrangementId).toSet(), hasLength(3));
    expect(views.map((view) => view.id).toSet(), hasLength(3));
    for (final view in views) {
      expect(view.candidate.id, _candidate.id);
      expect(view.candidate.identity, _candidate.identity);
      expect(view.candidate.url, _candidate.url);
      expect(view.extra['parentSourceId'], _candidate.identity);
      expect(view.extra['parentCandidate'], _candidate.toJson());
      expect(view.extra, isNot(contains('discoveryEvidence')));
      expect(view.timingTracks, isEmpty);
      final restored = SourceResult.fromJson(view.toJson());
      expect(restored.arrangementId, view.arrangementId);
      expect(restored.id, view.id);
      expect(restored.candidate.identity, _candidate.identity);
    }
    expect(parent.body, body);
    expect(parent.extra['discoveryEvidence'], isNotNull);
  });

  test('does not split ordinary verse, chorus, or bridge labels', () {
    final source = _source('''[Verse 1]
[C]quiet lantern
[Chorus]
[G]open window
[Bridge]
[Am]silver morning''');
    expect(splitChartArrangements(source), isEmpty);
  });

  test('does not interpret prose mentioning versions as chart headings', () {
    final source = _source('''[C]quiet lantern
I remember version 2 of our summer
[G]open window
Someone else (version 3)
[Am]silver morning''');
    expect(splitChartArrangements(source), isEmpty);
  });

  test('recognizes standalone bracketed version headings', () {
    final views = splitChartArrangements(
      _source('[C]first garden\n[Version 2]\n[G]second garden'),
    );
    expect(views, hasLength(2));
    expect(views[1].body, '[G]second garden');
  });

  test(
    'invalid capo labels neither split nor disappear from derived views',
    () {
      const invalid = ['Capo IIV', 'Capo VX', 'Capo 13', 'Capo 99'];
      for (final line in invalid) {
        final body = '[C]quiet lantern\n$line\n[G]open window';
        expect(splitChartArrangements(_source(body)), isEmpty, reason: line);
        final views = splitChartArrangements(
          _source('$body\nArrangement 2\n[Am]second garden'),
        );
        expect(views, hasLength(2), reason: line);
        expect(views[0].body, body, reason: line);
        expect(views[0].metadata['capo'], 1, reason: line);
      }
    },
  );

  test('accepts open position and canonical Roman capos through twelve', () {
    final views = splitChartArrangements(
      _source('Capo 0\n[C]first garden\nCapo XII\n[G]second garden'),
    );
    expect(views, hasLength(2));
    expect(views.map((view) => view.metadata['capo']), [0, 12]);
  });

  test(
    'view identities depend on scoped setup and survive version reordering',
    () {
      const first = 'Capo I\n[C]quiet lantern\n[G]open window';
      const second = 'Capo IV\n[C]quiet lantern\n[G]open window';
      final forward = splitChartArrangements(
        _source('$first\nArrangement 2\n$second'),
      );
      final reverse = splitChartArrangements(
        _source('$second\nArrangement 2\n$first'),
      );
      expect(
        forward.map((view) => view.id).toSet(),
        reverse.map((view) => view.id).toSet(),
      );
      expect(forward.map((view) => view.id).toSet(), hasLength(2));
    },
  );

  test('new version without explicit capo defaults to open position', () {
    final views = splitChartArrangements(
      _source('''[C]first garden
Example Song (version 2)
[G]second garden'''),
    );
    expect(views, hasLength(2));
    expect(views[0].metadata['capo'], 1);
    expect(views[1].metadata['capo'], 0);
    expect(views[0].candidate.metadata['capo'], 1);
    expect(views[1].candidate.metadata['capo'], 0);
  });

  test(
    'later views do not inherit first-chart setup through either metadata',
    () {
      final candidate = SongCandidate.fromJson({
        ..._candidate.toJson(),
        'metadata': {
          ..._candidate.metadata,
          'key': 'Dm',
          'tuning': 'D A D G B E',
          'timeSignature': '3/4',
          'publisher': 'Example Publisher',
        },
      });
      final parent = SourceResult(
        candidate: candidate,
        body: '''[Dm]first garden
Arrangement 2
Capo VI
[Am]second garden
Arrangement 3
Capo IV
Key: E
Tuning: E A D G B E
[C]third garden''',
        metadata: {
          'key': 'Dm',
          'capo': 1,
          'tuning': 'D A D G B E',
          'timeSignature': '3/4',
          'difficulty': 'advanced',
        },
        matchKind: MatchKind.sameSong,
      );
      final views = splitChartArrangements(parent);
      expect(views, hasLength(3));
      for (final metadata in [views[0].metadata, views[0].candidate.metadata]) {
        expect(metadata['key'], 'Dm');
        expect(metadata['capo'], 1);
        expect(metadata['tuning'], 'D A D G B E');
        expect(metadata['timeSignature'], '3/4');
      }
      for (final metadata in [views[1].metadata, views[1].candidate.metadata]) {
        expect(metadata['capo'], 6);
        expect(metadata, isNot(contains('key')));
        expect(metadata, isNot(contains('tuning')));
        expect(metadata, isNot(contains('timeSignature')));
      }
      for (final metadata in [views[2].metadata, views[2].candidate.metadata]) {
        expect(metadata['capo'], 4);
        expect(metadata['key'], 'E');
        expect(metadata['tuning'], 'E A D G B E');
      }
      for (final view in views) {
        expect(view.candidate.id, candidate.id);
        expect(view.candidate.url, candidate.url);
        expect(view.candidate.metadata['publisher'], 'Example Publisher');
        expect(view.metadata['difficulty'], 'advanced');
        expect(view.extra['parentCandidate'], candidate.toJson());
      }
      expect(parent.candidate.metadata['key'], 'Dm');
      expect(parent.metadata['tuning'], 'D A D G B E');
    },
  );

  test('does not split a single chart or an already-derived view', () {
    final single = _source('[C]one quiet garden');
    expect(splitChartArrangements(single), isEmpty);
    final derived = SourceResult(
      candidate: _candidate,
      body: '[C]first\nArrangement 2\n[G]second',
      arrangementId: 'already-derived',
    );
    expect(splitChartArrangements(derived), isEmpty);
  });
}
