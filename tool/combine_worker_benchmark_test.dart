import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/combine_runner.dart';
import 'package:singbook/domain/models.dart';

/// Fixture benchmark for the off-UI-thread merge: a heavy discovery (many
/// sources of a long song) must not stall the caller's isolate. Prints the
/// numbers so CI logs show them on every platform.
const _selected = SongCandidate(
  providerId: 'catalog',
  id: 'song',
  title: 'Harbor Lights',
  artist: 'Test Band',
);

String _lyrics(int lines) => [
  for (var i = 0; i < lines; i++)
    'Amber lantern number $i glows above the quiet harbor tonight',
].join('\n');

String _chart(int lines, int variant) => [
  for (var i = 0; i < lines; i++)
    '[${const ['Em', 'G', 'D', 'Am', 'C'][(i + variant) % 5]}]Amber lantern '
        'number $i glows above the [B7]quiet harbor tonight',
].join('\n');

SourceResult _source(String provider, String body) => SourceResult(
  candidate: SongCandidate(
    providerId: provider,
    id: 'song',
    title: 'Harbor Lights',
    artist: 'Test Band',
  ),
  body: body,
  matchKind: MatchKind.sameSong,
);

void main() {
  test('a heavy merge keeps the caller isolate responsive', () async {
    const lines = 120, charts = 12;
    final results = [
      _source('lyrics', _lyrics(lines)),
      for (var i = 0; i < charts; i++) _source('chart$i', _chart(lines, i)),
    ];
    final request = CombineRequest(
      candidate: _selected,
      results: results,
      historicalCacheUses: const [],
    );
    final runner = CombineRunner();
    // Spawn the worker first so the measurement excludes isolate start-up,
    // as in a discovery where earlier batches already ran.
    await runner.submit(
      CombineRequest(
        candidate: _selected,
        results: [results.first],
        historicalCacheUses: const [],
      ),
    );

    var maxGap = Duration.zero;
    var last = Stopwatch()..start();
    final ticker = Timer.periodic(const Duration(milliseconds: 5), (_) {
      if (last.elapsed > maxGap) maxGap = last.elapsed;
      last = Stopwatch()..start();
    });
    final clock = Stopwatch()..start();
    final outcome = await runner.submit(request);
    final merged = clock.elapsed;
    ticker.cancel();

    expect(outcome!.document, isNotNull);
    // ignore: avoid_print
    print(
      'combine benchmark: ${results.length} sources x $lines lines merged in '
      '${merged.inMilliseconds} ms, longest caller-isolate stall '
      '${maxGap.inMilliseconds} ms',
    );
    // Generous bound for shared CI runners; a merge on the caller's isolate
    // for this input stalls for the whole merge duration instead.
    expect(maxGap, lessThan(const Duration(milliseconds: 250)));
  });
}
