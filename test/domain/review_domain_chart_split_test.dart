import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/chart_arrangements.dart';
import 'package:singbook/domain/models.dart';

SourceResult _source(String body) => SourceResult(
  candidate: const SongCandidate(
    providerId: 'chords',
    id: '/c/1',
    title: 'Random Song',
    artist: 'Someone',
  ),
  body: body,
);

enum _Kind { chords, lyric, blank, boundary, setup }

/// The segmentation rule as it was written before the running flag: a
/// version, capo or retuning line starts a new chart when any earlier line of
/// the current chart has chords. Rescans the segment for every line.
List<(int, int)> _expectedViews(List<_Kind> kinds) {
  final boundaries = <int>[];
  var segmentStart = 0;
  for (var i = 0; i < kinds.length; i++) {
    if (i > segmentStart &&
        kinds.sublist(segmentStart, i).contains(_Kind.chords) &&
        kinds[i] == _Kind.boundary) {
      boundaries.add(i);
      segmentStart = i;
    }
  }
  if (boundaries.isEmpty) return const [];
  final starts = [0, ...boundaries], ends = [...boundaries, kinds.length];
  final views = [
    for (var part = 0; part < starts.length; part++)
      if (kinds.sublist(starts[part], ends[part]).contains(_Kind.chords))
        (starts[part] + 1, ends[part]),
  ];
  return views.length >= 2 ? views : const [];
}

void main() {
  test('random charts split exactly where the rescanning rule did', () {
    final random = Random(20261111);
    const boundaryLines = [
      'Capo 2',
      'Capo: 3',
      'capo iv',
      'Version 2',
      '[Arrangement 3]',
      'Random Song (version 4)',
      'Tuned half step down',
      'Whole step down tuning',
    ];
    const setupLines = ['Tuning: DADGAD', 'Key: G', 'Key of: Am'];
    var split = 0;
    for (var round = 0; round < 400; round++) {
      final kinds = <_Kind>[];
      final lines = <String>[];
      final length = random.nextInt(45);
      for (var i = 0; i < length; i++) {
        final roll = random.nextInt(20);
        final kind = roll < 5
            ? _Kind.chords
            : roll < 11
            ? _Kind.lyric
            : roll < 13
            ? _Kind.blank
            : roll < 18
            ? _Kind.boundary
            : _Kind.setup;
        kinds.add(kind);
        lines.add(switch (kind) {
          // Unique text, so no two charts collapse into one arrangement ID.
          _Kind.chords => '[C]unique$round x$i [G7]words',
          _Kind.lyric => 'plain words $round $i',
          _Kind.blank => '',
          _Kind.boundary => boundaryLines[random.nextInt(boundaryLines.length)],
          _Kind.setup => setupLines[random.nextInt(setupLines.length)],
        });
      }
      final crlf = round.isOdd;
      final views = splitChartArrangements(
        _source(lines.join(crlf ? '\r\n' : '\n')),
      );
      final actual = [
        for (final view in views)
          (
            (view.extra['arrangement'] as Map)['startLine'] as int,
            (view.extra['arrangement'] as Map)['endLine'] as int,
          ),
      ];
      final expected = _expectedViews(kinds);
      expect(actual, expected, reason: 'round $round:\n${lines.join('\n')}');
      if (expected.isNotEmpty) split++;
    }
    // The generator must exercise real splits, not only the empty result.
    expect(split, greaterThan(100));
  });

  test('a later chart keeps its own setup and the first keeps the page', () {
    final views = splitChartArrangements(
      _source(
        'Capo 2\n[C]First [G]chart\nplain\n'
        'Version 2\nCapo 5\n[D]Second [A]chart',
      ),
    );
    expect(views, hasLength(2));
    expect(views.first.metadata['capo'], 2);
    expect(views.first.body, '[C]First [G]chart\nplain');
    expect(views.last.metadata['capo'], 5);
    expect(views.last.body, '[D]Second [A]chart');
  });

  test('a long body without chords is scanned once', () {
    // 100,000 lines: rescanning the segment for each line took minutes.
    final body = List.filled(100000, 'a').join('\n');
    expect(body.length, lessThanOrEqualTo(200000));
    final watch = Stopwatch()..start();
    expect(splitChartArrangements(_source(body)), isEmpty);
    expect(watch.elapsed, lessThan(const Duration(seconds: 20)));
  });
}
