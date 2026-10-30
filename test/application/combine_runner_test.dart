import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/combine_runner.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

const _selected = SongCandidate(
  providerId: 'catalog',
  id: 'song',
  title: 'Harbor Lights',
  artist: 'Test Band',
);

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

const _lyrics =
    'Amber lanterns glow above the quiet harbor\n'
    'Silver rain returns across the sleepy water\n'
    'Morning brings another distant melody';
const _chart = '[Em]Amber lanterns glow above the quiet harbor';

CombineRequest _request(List<SourceResult> results) => CombineRequest(
  candidate: _selected,
  results: results,
  historicalCacheUses: const [],
);

void main() {
  test('background isolate merge equals the direct merge', () async {
    final results = [_source('lyrics', _lyrics), _source('chart', _chart)];
    final direct = combineSources(_selected, results);
    final outcome = await CombineRunner().submit(_request(results));
    final background = outcome!.document!;
    expect(background.body, direct.body);
    // Every merge mints a fresh id and timestamps; everything else must match.
    expect(
      background.toJson()
        ..remove('id')
        ..remove('createdAt')
        ..remove('updatedAt'),
      direct.toJson()
        ..remove('id')
        ..remove('createdAt')
        ..remove('updatedAt'),
    );
    expect(background.extra['chordSourceIds'], direct.extra['chordSourceIds']);
    expect(
      background.sources.map((s) => s.id),
      direct.sources.map((s) => s.id),
    );
  });

  test('no usable source yields no document', () async {
    final outcome = await CombineRunner().submit(
      _request([_source('empty', '   ')]),
    );
    expect(outcome!.document, isNull);
  });

  test(
    'queued requests coalesce to the newest and stale ones are ignored',
    () async {
      final gates = <Completer<void>>[];
      final computed = <int>[];
      final runner = CombineRunner(
        compute: (request) async {
          computed.add(request.results.length);
          final gate = Completer<void>();
          gates.add(gate);
          await gate.future;
          return computeCombine(request);
        },
      );
      List<SourceResult> sources(int n) => [
        _source('lyrics', _lyrics),
        for (var i = 1; i < n; i++) _source('chart$i', _chart),
      ];
      final first = runner.submit(_request(sources(1)));
      await Future<void>.delayed(Duration.zero);
      final second = runner.submit(_request(sources(2)));
      final third = runner.submit(_request(sources(3)));
      final fourth = runner.submit(_request(sources(4)));
      gates.single.complete();
      // The first run began before the newer submissions, so it is stale.
      expect(await first, isNull);
      expect(await second, isNull);
      expect(await third, isNull);
      await Future<void>.delayed(Duration.zero);
      gates.last.complete();
      final latest = await fourth;
      expect(latest, isNotNull);
      expect(computed, [1, 4]);
      expect(runner.startedRuns, 2);
    },
  );

  test('a failed stale run does not fail the newest request', () async {
    var calls = 0;
    final gate = Completer<void>();
    final runner = CombineRunner(
      compute: (request) async {
        if (++calls == 1) {
          await gate.future;
          throw StateError('boom');
        }
        return computeCombine(request);
      },
    );
    final first = runner.submit(_request([_source('lyrics', _lyrics)]));
    await Future<void>.delayed(Duration.zero);
    final second = runner.submit(_request([_source('lyrics', _lyrics)]));
    gate.complete();
    expect(await first, isNull);
    expect((await second)!.document, isNotNull);
  });

  test('an error from the newest request reaches its caller', () async {
    final runner = CombineRunner(compute: (_) async => throw StateError('x'));
    await expectLater(
      runner.submit(_request([_source('lyrics', _lyrics)])),
      throwsStateError,
    );
  });

  test('the worker survives batches and restarts after release', () async {
    final runner = CombineRunner();
    final first = await runner.submit(_request([_source('lyrics', _lyrics)]));
    final second = await runner.submit(
      _request([_source('lyrics', _lyrics), _source('chart', _chart)]),
    );
    expect(first!.document!.hasChords, isFalse);
    expect(second!.document!.hasChords, isTrue);
    runner.release();
    final third = await runner.submit(_request([_source('chart', _chart)]));
    expect(third!.document, isNotNull);
    runner.release();
  });

  test('release waits for a running merge', () async {
    final gate = Completer<void>();
    var released = false;
    final runner = CombineRunner(
      compute: (request) async {
        await gate.future;
        return computeCombine(request);
      },
      onRelease: () => released = true,
    );
    final run = runner.submit(_request([_source('lyrics', _lyrics)]));
    await Future<void>.delayed(Duration.zero);
    runner.release();
    expect(released, isFalse);
    gate.complete();
    expect((await run)!.document, isNotNull);
    expect(released, isTrue);
  });
}
