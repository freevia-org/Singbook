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

SourceResult _source(
  String provider,
  String body, {
  MatchKind matchKind = MatchKind.sameSong,
}) => SourceResult(
  candidate: SongCandidate(
    providerId: provider,
    id: 'song',
    title: 'Harbor Lights',
    artist: 'Test Band',
  ),
  body: body,
  matchKind: matchKind,
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

SongDocument _preparedFixture(CombineRequest request) => SongDocument(
  id: 'prepared',
  title: request.candidate.title,
  artist: request.candidate.artist,
  body: request.results.single.body,
);

void main() {
  test('background isolate merge equals the direct merge', () async {
    final results = [_source('lyrics', _lyrics), _source('chart', _chart)];
    final direct = combineSources(_selected, results);
    final outcome = await CombineRunner().submit(_request(results));
    final background = outcome!.document!;
    expect(background.body, direct.body);
    expect(outcome.sourceHasLyrics, [true, true]);
    expect(outcome.documentContent, (hasLyrics: true, usable: true));
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
    final runner = CombineRunner();
    final outcome = await runner.submit(
      _request([
        _source('empty', '   '),
        _source('rejected', _lyrics, matchKind: MatchKind.rejected),
      ]),
    );
    expect(outcome!.document, isNull);
    expect(outcome.sourceHasLyrics, [false, true]);
    expect(outcome.documentContent, isNull);
    runner.release();
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
      // The running merge is delivered; the queued ones collapse to the newest.
      expect(await first, isNotNull);
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

  test('identical in-flight snapshots share one merge', () async {
    final gate = Completer<void>();
    final runner = CombineRunner(
      compute: (request) async {
        await gate.future;
        return computeCombine(request);
      },
    );
    final results = [_source('lyrics', _lyrics)];
    final preview = runner.submit(_request(results));
    final flush = runner.submit(_request([...results]));
    gate.complete();

    expect(await flush, same(await preview));
    expect(runner.startedRuns, 1);
    runner.release();
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

  test('discarded work cannot block or overwrite a new preview', () async {
    final old = Completer<CombineOutcome>();
    final next = Completer<CombineOutcome>();
    final queuedResult = Completer<CombineOutcome>();
    var calls = 0;
    final runner = CombineRunner(
      compute: (_) => [old, next, queuedResult][calls++].future,
    );
    final active = runner.submit(_request([_source('lyrics', _lyrics)]));
    final queued = runner.submit(_request([_source('chords', _chart)]));
    runner.discard();
    expect(await active, isNull);
    expect(await queued, isNull);

    final newRequest = _request([_source('lyrics2', _lyrics)]);
    final newPreview = runner.submit(newRequest);
    expect(calls, 2);
    final followUp = runner.submit(_request([_source('chords2', _chart)]));
    old.completeError(StateError('obsolete merge failed'));
    await Future<void>.delayed(Duration.zero);
    expect(calls, 2);
    next.complete(computeCombine(newRequest));
    expect((await newPreview)?.document, isNotNull);
    expect(calls, 3);
    queuedResult.complete(computeCombine(_request([_source('chords2', _chart)])));
    expect((await followUp)?.document, isNotNull);
  });

  test('discard can stop an isolate while it is starting', () async {
    final runner = CombineRunner();
    final starting = runner.submit(_request([_source('lyrics', _lyrics)]));
    runner.discard();
    expect(await starting, isNull);
    final next = await runner.submit(_request([_source('chords', _chart)]));
    expect(next?.document?.hasChords, isTrue);
    runner.release();
  });

  group('PreferredArrangementPreparer', () {
    test(
      'clearing speculative work immediately frees the next preparation',
      () async {
        final old = Completer<SongDocument>();
        final oldRequest = _request([_source('old', _lyrics)]);
        final newRequest = _request([_source('new', _chart)]);
        final preparer = PreferredArrangementPreparer(
          compute:
              (
                request, {
                required sourceId,
                required compact,
                required allowRejectedPreferredSource,
              }) async {
                if (sourceId == 'old:song') return old.future;
                return _preparedFixture(request);
              },
        );
        preparer.warm(oldRequest, sourceId: 'old:song', compact: true);
        preparer.clear();
        preparer.warm(newRequest, sourceId: 'new:song', compact: true);
        final next = preparer.claim(
          newRequest,
          sourceId: 'new:song',
          compact: true,
        );
        expect((await next!.timeout(const Duration(seconds: 5))).body, _chart);
        old.completeError(StateError('old speculative work failed'));
        await Future<void>.delayed(Duration.zero);
        expect(
          preparer.claim(newRequest, sourceId: 'new:song', compact: true),
          same(next),
        );
      },
    );

    test(
      'native preferred worker can restart after clearing during startup',
      () async {
        final preparer = PreferredArrangementPreparer();
        final old = _request([_source('old', _lyrics)]);
        final next = _request([_source('new', _chart)]);
        preparer.warm(old, sourceId: 'old:song', compact: true);
        preparer.clear();
        preparer.warm(next, sourceId: 'new:song', compact: true);
        final saved = await preparer.claim(
          next,
          sourceId: 'new:song',
          compact: true,
        );
        expect(saved?.hasChords, isTrue);
      },
    );

    test('warm and repeated claims share the exact in-flight future', () async {
      final gate = Completer<void>();
      var calls = 0;
      final request = _request([_source('lyrics', _lyrics)]);
      final preparer = PreferredArrangementPreparer(
        compute:
            (
              request, {
              required sourceId,
              required compact,
              required allowRejectedPreferredSource,
            }) async {
              calls++;
              await gate.future;
              return _preparedFixture(request);
            },
      );

      preparer.warm(request, sourceId: 'lyrics', compact: false);
      final first = preparer.claim(request, sourceId: 'lyrics', compact: false);
      final second = preparer.claim(
        _request([...request.results]),
        sourceId: 'lyrics',
        compact: false,
      );
      expect(first, isNotNull);
      expect(second, same(first));
      gate.complete();
      expect((await first!).body, _lyrics);
      expect(calls, 1);
    });

    test('only the newest unclaimed queued request is prepared', () async {
      final gates = <String, Completer<void>>{};
      final started = <String>[];
      final preparer = PreferredArrangementPreparer(
        compute:
            (
              request, {
              required sourceId,
              required compact,
              required allowRejectedPreferredSource,
            }) async {
              started.add(sourceId);
              final gate = gates.putIfAbsent(sourceId, Completer<void>.new);
              await gate.future;
              return _preparedFixture(request);
            },
      );
      final first = _request([_source('first', _lyrics)]);
      final middle = _request([_source('middle', _lyrics)]);
      final latest = _request([_source('latest', _lyrics)]);

      preparer.warm(first, sourceId: 'first', compact: false);
      preparer.warm(middle, sourceId: 'middle', compact: false);
      preparer.warm(latest, sourceId: 'latest', compact: false);
      expect(
        preparer.claim(middle, sourceId: 'middle', compact: false),
        isNull,
      );
      final latestFuture = preparer.claim(
        latest,
        sourceId: 'latest',
        compact: false,
      );
      gates['first']!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(started, ['first', 'latest']);
      gates['latest']!.complete();
      await latestFuture!;
    });

    test(
      'returning to the running choice discards the speculative successor',
      () async {
        final gate = Completer<void>();
        final started = <String>[];
        final preparer = PreferredArrangementPreparer(
          compute:
              (
                request, {
                required sourceId,
                required compact,
                required allowRejectedPreferredSource,
              }) async {
                started.add(sourceId);
                await gate.future;
                return _preparedFixture(request);
              },
        );
        final first = _request([_source('first', _lyrics)]);
        final later = _request([_source('later', _chart)]);
        preparer.warm(first, sourceId: 'first', compact: true);
        preparer.warm(later, sourceId: 'later', compact: true);
        preparer.warm(first, sourceId: 'first', compact: true);
        expect(preparer.claim(later, sourceId: 'later', compact: true), isNull);
        final chosen = preparer.claim(first, sourceId: 'first', compact: true)!;
        gate.complete();
        expect((await chosen).body, _lyrics);
        expect(started, ['first']);
      },
    );

    test('a claimed queued request cannot be replaced', () async {
      final gates = <String, Completer<void>>{};
      final started = <String>[];
      final preparer = PreferredArrangementPreparer(
        compute:
            (
              request, {
              required sourceId,
              required compact,
              required allowRejectedPreferredSource,
            }) async {
              started.add(sourceId);
              final gate = gates.putIfAbsent(sourceId, Completer<void>.new);
              await gate.future;
              return _preparedFixture(request);
            },
      );
      final first = _request([_source('first', _lyrics)]);
      final protected = _request([_source('protected', _lyrics)]);
      final later = _request([_source('later', _lyrics)]);

      preparer.warm(first, sourceId: 'first', compact: false);
      preparer.warm(protected, sourceId: 'protected', compact: false);
      final save = preparer.claim(
        protected,
        sourceId: 'protected',
        compact: false,
      );
      preparer.warm(later, sourceId: 'later', compact: false);
      expect(save, isNotNull);
      expect(preparer.claim(later, sourceId: 'later', compact: false), isNull);

      gates['first']!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(started, ['first', 'protected']);
      gates['protected']!.complete();
      await save!;
    });

    test(
      'clear invalidates reuse but preserves already claimed work',
      () async {
        final gate = Completer<void>();
        var calls = 0;
        final request = _request([_source('lyrics', _lyrics)]);
        final preparer = PreferredArrangementPreparer(
          compute:
              (
                request, {
                required sourceId,
                required compact,
                required allowRejectedPreferredSource,
              }) async {
                calls++;
                await gate.future;
                return _preparedFixture(request);
              },
        );
        preparer.warm(request, sourceId: 'lyrics', compact: false);
        final claimed = preparer.claim(
          request,
          sourceId: 'lyrics',
          compact: false,
        );
        preparer.clear();
        expect(
          preparer.claim(request, sourceId: 'lyrics', compact: false),
          isNull,
        );
        gate.complete();
        expect((await claimed!).body, contains('Amber lanterns'));
        expect(
          preparer.claim(request, sourceId: 'lyrics', compact: false),
          isNull,
        );
        expect(calls, 1);
      },
    );
  });
}
