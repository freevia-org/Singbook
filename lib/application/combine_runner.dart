import 'dart:async';
import 'dart:isolate';
import '../domain/arrangement.dart' show parseArrangement, plainLyrics;
import '../domain/combine.dart';
import '../domain/models.dart';

/// One merge request. Everything here is sendable to another isolate; the
/// object graph is copied as a single message, so identity between [results]
/// and the sources held by [historicalCacheUses] is preserved.
class CombineRequest {
  const CombineRequest({
    required this.candidate,
    required this.results,
    required this.historicalCacheUses,
  });
  final SongCandidate candidate;
  final List<SourceResult> results;
  final List<HistoricalCacheUse> historicalCacheUses;
}

/// [document] is null when no source is usable or the merge rejected its input
/// with a [FormatException].
class CombineOutcome {
  const CombineOutcome(this.document);
  final SongDocument? document;
}

/// The merge itself, free of controller state so it can run on any isolate.
CombineOutcome computeCombine(CombineRequest request) {
  final candidate = request.candidate;
  final uses = request.historicalCacheUses;
  final usable = request.results.any(
    (r) =>
        (r.matchKind != MatchKind.rejected ||
            uses.any((use) => use.allows(candidate, r))) &&
        (plainLyrics(r.body).trim().isNotEmpty ||
            parseArrangement(
              r.body,
            ).any((line) => !line.directive && line.chords.isNotEmpty)),
  );
  if (!usable) {
    // Rejected payloads remain inspectable as alternatives. Only an explicit
    // source save may opt into a rejected arrangement; automatic recombination
    // must not restore authority withdrawn by final checks.
    return const CombineOutcome(null);
  }
  try {
    // A verified own arrangement may contain only chord rows. The prefilter
    // above is a content check; combineSources still decides identity,
    // readiness, editions and whether the chart is eligible without a lyric
    // base.
    return CombineOutcome(
      combineSources(candidate, request.results, historicalCacheUses: uses),
    );
  } on FormatException {
    return const CombineOutcome(null);
  }
}

/// A long-lived isolate that runs merges. Staying alive between the batches of
/// one discovery keeps its parse caches warm; [dispose] ends it.
class CombineWorker {
  Isolate? _isolate;
  SendPort? _send;
  ReceivePort? _receive;
  Future<void>? _starting;
  final _pending = <int, Completer<CombineOutcome>>{};
  int _nextId = 0;

  Future<CombineOutcome> run(CombineRequest request) async {
    await (_starting ??= _start());
    final id = ++_nextId;
    final completer = Completer<CombineOutcome>();
    _pending[id] = completer;
    _send!.send([id, request]);
    return completer.future;
  }

  Future<void> _start() async {
    final receive = ReceivePort();
    final ready = Completer<SendPort>();
    receive.listen((message) {
      if (message is SendPort) {
        ready.complete(message);
        return;
      }
      final reply = message as List;
      final completer = _pending.remove(reply[0] as int);
      if (completer == null) return;
      if (reply[2] != null) {
        completer.completeError(StateError(reply[2] as String));
      } else {
        completer.complete(reply[1] as CombineOutcome);
      }
    });
    _receive = receive;
    _isolate = await Isolate.spawn(
      _workerMain,
      receive.sendPort,
      debugName: 'singbook-combine',
    );
    _send = await ready.future;
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receive?.close();
    _isolate = null;
    _receive = null;
    _send = null;
    _starting = null;
    final pending = _pending.values.toList();
    _pending.clear();
    for (final completer in pending) {
      completer.completeError(StateError('combine worker disposed'));
    }
  }
}

void _workerMain(SendPort main) {
  final inbox = ReceivePort();
  main.send(inbox.sendPort);
  inbox.listen((message) {
    final request = message as List;
    try {
      main.send([
        request[0],
        computeCombine(request[1] as CombineRequest),
        null,
      ]);
    } catch (error, stack) {
      main.send([request[0], null, '$error\n$stack']);
    }
  });
}

/// Runs merges one at a time off the caller's isolate and keeps only the
/// newest queued request: while one merge is running, any number of later
/// submissions collapse into the last one. A submission that was replaced, or
/// that finished after a newer one arrived, completes with null so callers
/// ignore it.
class CombineRunner {
  /// Without [compute], merges run on a [CombineWorker] that is created on
  /// first use and ended by [release]. A custom [compute] suits tests.
  CombineRunner({
    Future<CombineOutcome> Function(CombineRequest request)? compute,
    this.onRelease,
  }) : _custom = compute;

  final Future<CombineOutcome> Function(CombineRequest request)? _custom;
  final void Function()? onRelease;
  CombineWorker? _worker;
  int _latest = 0;
  bool _running = false, _releaseWhenIdle = false;
  _Queued? _queued;

  /// Number of merges actually started; useful for tests and diagnostics.
  int startedRuns = 0;

  Future<CombineOutcome> _compute(CombineRequest request) =>
      (_custom ?? (_worker ??= CombineWorker()).run)(request);

  Future<CombineOutcome?> submit(CombineRequest request) {
    final entry = _Queued(++_latest, request);
    _queued?.completer.complete(null);
    _queued = entry;
    _releaseWhenIdle = false;
    if (!_running) _drain();
    return entry.completer.future;
  }

  /// Ends the worker once nothing is queued or running. A later [submit]
  /// starts a fresh worker with cold caches.
  void release() {
    if (_running || _queued != null) {
      _releaseWhenIdle = true;
    } else {
      _releaseNow();
    }
  }

  void _releaseNow() {
    _releaseWhenIdle = false;
    _worker?.dispose();
    _worker = null;
    onRelease?.call();
  }

  Future<void> _drain() async {
    _running = true;
    try {
      while (_queued != null) {
        final entry = _queued!;
        _queued = null;
        startedRuns++;
        try {
          final outcome = await _compute(entry.request);
          entry.completer.complete(entry.id == _latest ? outcome : null);
        } catch (error, stack) {
          if (entry.id == _latest) {
            entry.completer.completeError(error, stack);
          } else {
            entry.completer.complete(null);
          }
        }
      }
    } finally {
      _running = false;
      if (_releaseWhenIdle) _releaseNow();
    }
  }
}

class _Queued {
  _Queued(this.id, this.request);
  final int id;
  final CombineRequest request;
  final completer = Completer<CombineOutcome?>();
}
