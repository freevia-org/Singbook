import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import '../domain/arrangement.dart'
    show containsChords, parseArrangement, plainLyrics;
import '../domain/chord_key_estimate.dart' show estimateChordKey;
import '../domain/combine.dart';
import '../domain/models.dart';
import '../domain/source_result_merge.dart';

/// One merge request. Everything here is sendable to another isolate; the
/// object graph is copied as a single message, so identity between [results]
/// and the sources held by [historicalCacheUses] is preserved.
class CombineRequest {
  const CombineRequest({
    required this.candidate,
    required this.results,
    required this.historicalCacheUses,
    this.knownSourceLyrics,
  });
  final SongCandidate candidate;
  final List<SourceResult> results;
  final List<HistoricalCacheUse> historicalCacheUses;
  final List<bool?>? knownSourceLyrics;

  bool hasSameInputs(CombineRequest other) =>
      identical(candidate, other.candidate) &&
      _sameObjects(results, other.results) &&
      _sameObjects(historicalCacheUses, other.historicalCacheUses);

  static bool _sameObjects(List<Object> a, List<Object> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }
}

/// [document] is null when no source is usable or the merge rejected its input
/// with a [FormatException].
class CombineOutcome {
  const CombineOutcome(
    this.document, {
    this.usableChordOnlyIds = const {},
    this.sourceHasLyrics,
    this.documentContent,
    this.documentHasChords,
  });
  final SongDocument? document;
  final Set<String> usableChordOnlyIds;
  final List<bool>? sourceHasLyrics;
  final bool? documentHasChords;
  final ({bool hasLyrics, bool usable})? documentContent;
}

bool _hasChartChords(String body) => parseArrangement(
  body,
).any((line) => !line.directive && line.chords.isNotEmpty);

/// The merge itself, free of controller state so it can run on any isolate.
CombineOutcome computeCombine(CombineRequest request) {
  final candidate = request.candidate;
  final uses = request.historicalCacheUses;
  final sourceHasLyrics = [
    for (final (index, result) in request.results.indexed)
      request.knownSourceLyrics?[index] ??
          plainLyrics(result.body).trim().isNotEmpty,
  ];
  final usable = request.results.indexed.any((entry) {
    final (index, result) = entry;
    return (result.matchKind != MatchKind.rejected ||
            uses.any((use) => use.allows(candidate, result))) &&
        (sourceHasLyrics[index] || _hasChartChords(result.body));
  });
  if (!usable) {
    // Rejected payloads remain inspectable as alternatives. Only an explicit
    // source save may opt into a rejected arrangement; automatic recombination
    // must not restore authority withdrawn by final checks.
    return CombineOutcome(null, sourceHasLyrics: sourceHasLyrics);
  }
  SongDocument? document;
  try {
    // A verified own arrangement may contain only chord rows. The prefilter
    // above is a content check; combineSources still decides identity,
    // readiness, editions and whether the chart is eligible without a lyric
    // base.
    document = combineSources(
      candidate,
      request.results,
      historicalCacheUses: uses,
    );
  } on FormatException {
    // An explicitly selected chart can still be usable on its own.
  }
  final chordOnlyIds = <String>{};
  for (final (index, source) in request.results.indexed) {
    if (source.candidate.identity != candidate.identity ||
        source.candidate.metadata['identityScope'] != 'arrangement' ||
        source.hasPendingMatchCheck ||
        (source.matchKind != MatchKind.sameSong &&
            source.matchKind != MatchKind.sameRecording) ||
        sourceHasLyrics[index] ||
        !_hasChartChords(source.body)) {
      continue;
    }
    try {
      if (combineSources(candidate, [
        source,
      ], preferredSourceId: source.id).hasChords) {
        chordOnlyIds.add(source.id);
      }
    } on FormatException {
      // A chart that cannot be saved must not appear ready to open.
    }
  }
  final hasLyrics =
      document != null && plainLyrics(document.body).trim().isNotEmpty;
  return CombineOutcome(
    document,
    usableChordOnlyIds: chordOnlyIds,
    sourceHasLyrics: sourceHasLyrics,
    documentHasChords: document?.hasChords,
    documentContent: document == null
        ? null
        : (
            hasLyrics: hasLyrics,
            usable: hasLyrics || _hasChartChords(document.body),
          ),
  );
}

/// Runs a captured save independently of the replaceable discovery queue.
Future<SongDocument> combineForSave(
  CombineRequest request, {
  required String? preferredSourceId,
  required bool allowRejectedPreferredSource,
  required Set<int> pendingSources,
  bool compactExplicitSave = false,
}) => Isolate.run(
  () => _combineForSave(
    request,
    preferredSourceId: preferredSourceId,
    allowRejectedPreferredSource: allowRejectedPreferredSource,
    pendingSources: pendingSources,
    compactExplicitSave: compactExplicitSave,
  ),
  debugName: 'singbook-save-combine',
);

SongDocument _combineForSave(
  CombineRequest request, {
  required String? preferredSourceId,
  required bool allowRejectedPreferredSource,
  required Set<int> pendingSources,
  required bool compactExplicitSave,
}) {
  final results = [
    for (var index = 0; index < request.results.length; index++)
      if (pendingSources.contains(index))
        request.results[index].copyWith(
          timingTracks: const [],
          extra: {...request.results[index].extra, 'pendingMatchCheck': true},
        )
      else
        request.results[index],
  ];
  if (preferredSourceId != null) {
    final preferred = results
        .where((item) => item.id == preferredSourceId)
        .firstOrNull;
    if (preferred == null ||
        (preferred.matchKind == MatchKind.rejected &&
            !allowRejectedPreferredSource) ||
        preferred.body.trim().isEmpty) {
      throw StateError('invalid_source');
    }
  }
  return combineSources(
    request.candidate,
    results,
    preferredSourceId: preferredSourceId,
    allowRejectedPreferredSource: allowRejectedPreferredSource,
    compactExplicitSave: compactExplicitSave,
    historicalCacheUses: request.historicalCacheUses,
  );
}

typedef PreparedSavedComparison = ({
  SongCandidate reference,
  List<SourceResult> sources,
  List<({bool hasLyrics, bool hasChords})> facts,
  List<HistoricalCacheUse> uses,
  SongDocument? savedCombined,
  ({bool hasLyrics, bool hasChords, bool usable})? combinedFacts,
});

Future<PreparedSavedComparison> prepareSavedComparison(
  SongDocument stored,
  SongCandidate expectedReference,
) => Isolate.run(() {
  final reference =
      stored.selectedRecording ??
      stored.sources
          .where((source) => source.id == stored.extra['selectedSourceId'])
          .firstOrNull
          ?.candidate ??
      stored.sources
          .where(
            (source) =>
                source.matchKind != MatchKind.rejected &&
                plainLyrics(source.body).trim().isNotEmpty,
          )
          .firstOrNull
          ?.candidate;
  if (stored.extensionError != null ||
      reference == null ||
      _comparisonKey(reference.toJson()) !=
          _comparisonKey(expectedReference.toJson())) {
    throw const FormatException('invalid_local_data');
  }

  // Normalize the nested payload maps once in the worker. The proof binds
  // to the same normalized source instances returned to the comparison.
  final sources = {
    for (final source in stored.sources)
      source.id: SourceResult.fromJson(
        _copyCachedPayload(source.toJson()) as JsonMap,
      ),
  }.values.toList();
  final savedCombined =
      reference.providerId != 'wikisource' &&
          stored.extra['combinedSelection'] == reference.identity &&
          stored.extra['savedSourceId'] == null
      ? stored
      : null;
  final combinedHasLyrics =
      savedCombined != null &&
      plainLyrics(savedCombined.body).trim().isNotEmpty;
  return (
    reference: reference,
    sources: sources,
    facts: [
      for (final source in sources)
        (
          hasLyrics: plainLyrics(source.body).trim().isNotEmpty,
          hasChords: source.hasChords,
        ),
    ],
    savedCombined: savedCombined,
    combinedFacts: savedCombined == null
        ? null
        : (
            hasLyrics: combinedHasLyrics,
            hasChords: savedCombined.hasChords,
            usable: combinedHasLyrics || _hasChartChords(savedCombined.body),
          ),
    uses: [
      if (reference.providerId == 'wikisource')
        for (final source in sources)
          if (source.candidate.providerId == 'wikisource')
            ?HistoricalCacheUse.fromLibrarySnapshot(stored, reference, source),
    ],
  );
}, debugName: 'singbook-cached-evidence');

String _comparisonKey(Object? value) {
  Object? ordered(Object? item) {
    if (item is Map) {
      final keys = item.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: ordered(item[key])};
    }
    if (item is List) return item.map(ordered).toList();
    return item;
  }

  return jsonEncode(ordered(value));
}

Object? _copyCachedPayload(Object? value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key as String: _copyCachedPayload(entry.value),
    };
  }
  if (value is List) return value.map(_copyCachedPayload).toList();
  return value;
}

typedef SourceUpdateBatch = ({
  Map<String, SourceResult> replacements,
  Map<int, String> revokedUses,
  Map<String, bool> lyricPresence,
  Map<String, bool> chordPresence,
});

/// Consolidates payload history and timing for each repeated source in order.
Future<SourceUpdateBatch> mergeSourceUpdates(
  SongCandidate selected,
  Map<String, SourceResult> existing,
  List<SourceResult> incoming,
  List<HistoricalCacheUse> historicalUses,
) => Isolate.run(() {
  final replacements = <String, SourceResult>{};
  final revokedUses = <int, String>{};
  for (final source in incoming) {
    final previous = replacements[source.id] ?? existing[source.id];
    if (identical(previous, source)) continue;
    if (previous == null) {
      replacements[source.id] = source;
      continue;
    }
    final authorizations = [
      for (var i = 0; i < historicalUses.length; i++)
        if (!revokedUses.containsKey(i) &&
            historicalUses[i].allows(selected, previous))
          i,
    ];
    if (authorizations.isNotEmpty &&
        !explicitHistoricalWorkMatches(selected, source)) {
      continue;
    }
    for (final i in authorizations) {
      revokedUses[i] = source.id;
    }
    replacements[source.id] = mergeSourceResult(previous, source);
  }
  return (
    replacements: replacements,
    revokedUses: revokedUses,
    lyricPresence: {
      for (final entry in replacements.entries)
        entry.key: plainLyrics(entry.value.body).trim().isNotEmpty,
    },
    chordPresence: {
      for (final entry in replacements.entries)
        entry.key: containsChords(entry.value.body),
    },
  );
}, debugName: 'singbook-source-updates');

typedef SongDisplayKeys = ({String? sourceKey, String? estimate});

Future<Map<String, SongDisplayKeys>> scoreSongDisplayKeys(
  List<SongDocument> songs,
) => Isolate.run(() {
  final keys = <String, SongDisplayKeys>{};
  for (final song in songs) {
    try {
      final sourceKey = song.sources.isEmpty
          ? null
          : sourcedArrangementKey(song)?.key;
      keys[song.id] = (
        sourceKey: sourceKey,
        estimate: sourceKey == null
            ? rankedChordKeyEstimate(song) ??
                  (song.hasChords ? estimateChordKey(song.body)?.key : null) ??
                  checkedChordKeyEstimate(song)
            : null,
      );
    } catch (_) {
      // Optional display hints cannot block a library with malformed evidence.
      keys[song.id] = (sourceKey: null, estimate: null);
    }
  }
  return keys;
}, debugName: 'singbook-library-keys');

/// A long-lived isolate that runs merges. Staying alive between the batches of
/// one discovery keeps its parse caches warm; [dispose] ends it.
class CombineWorker {
  Isolate? _isolate;
  SendPort? _send;
  ReceivePort? _receive;
  Future<void>? _starting;
  final _ready = Completer<SendPort?>();
  bool _disposed = false;
  final _pending = <int, Completer<CombineOutcome>>{};
  int _nextId = 0;

  Future<CombineOutcome> run(CombineRequest request) => _run(request);

  Future<CombineOutcome> _run(
    CombineRequest request, {
    _PreparationMode? preferred,
  }) async {
    if (_disposed) throw StateError('combine worker disposed');
    await (_starting ??= _start());
    final send = _send;
    if (_disposed || send == null) throw StateError('combine worker disposed');
    final id = ++_nextId;
    final completer = Completer<CombineOutcome>();
    _pending[id] = completer;
    send.send([id, request, preferred]);
    return completer.future;
  }

  Future<void> _start() async {
    final receive = ReceivePort();
    receive.listen((message) {
      if (message is SendPort) {
        if (!_ready.isCompleted) _ready.complete(message);
        return;
      }
      final reply = message as List;
      final completer = _pending.remove(reply[0] as int);
      if (completer == null) return;
      if (reply.length == 4) {
        completer.completeError(reply[2] as Object, reply[3] as StackTrace);
      } else if (reply[2] != null) {
        completer.completeError(StateError(reply[2] as String));
      } else {
        completer.complete(reply[1] as CombineOutcome);
      }
    });
    _receive = receive;
    final isolate = await Isolate.spawn(
      _workerMain,
      receive.sendPort,
      debugName: 'singbook-combine',
    );
    if (_disposed) {
      isolate.kill(priority: Isolate.immediate);
      return;
    }
    _isolate = isolate;
    _send = await _ready.future;
  }

  void dispose() {
    _disposed = true;
    if (!_ready.isCompleted) _ready.complete(null);
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
    final args = message as List;
    final preferred = args[2] as _PreparationMode?;
    try {
      final request = args[1] as CombineRequest;
      if (preferred == null) {
        main.send([args[0], computeCombine(request), null]);
        return;
      }
      final document = _combineForSave(
        request,
        preferredSourceId: preferred.sourceId,
        allowRejectedPreferredSource: preferred.allowRejectedPreferredSource,
        pendingSources: const {},
        compactExplicitSave: preferred.compact,
      );
      Isolate.exit(main, [args[0], CombineOutcome(document), null]);
    } catch (error, stack) {
      if (preferred != null) {
        Isolate.exit(main, [args[0], null, error, stack]);
      }
      main.send([args[0], null, '$error\n$stack']);
    }
  });
}

/// Runs merges one at a time off the caller's isolate and keeps only the
/// newest queued request: while one merge is running, any number of later
/// submissions collapse into the last one, which starts as soon as the running
/// merge finishes. A submission replaced while still queued completes with
/// null so callers ignore it, and so does a failure that a newer request
/// already supersedes.
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
  int _generation = 0;
  bool _running = false, _releaseWhenIdle = false;
  _Queued? _queued, _active;

  /// Number of merges actually started; useful for tests and diagnostics.
  int startedRuns = 0;

  Future<CombineOutcome> _compute(CombineRequest request) =>
      (_custom ?? (_worker ??= CombineWorker()).run)(request);

  Future<CombineOutcome?> submit(CombineRequest request) {
    final latest = _queued ?? _active;
    if (latest != null && latest.request.hasSameInputs(request)) {
      _releaseWhenIdle = false;
      return latest.completer.future;
    }
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

  /// Abandon previews for a discovery the user has left. Its running merge
  /// must not delay previews for a different song.
  void discard() {
    if (!_running && _queued == null && _worker == null) return;
    ++_generation;
    _queued?.completer.complete(null);
    _active?.completer.complete(null);
    _queued = _active = null;
    _running = false;
    _releaseNow();
  }

  void _releaseNow() {
    _releaseWhenIdle = false;
    _worker?.dispose();
    _worker = null;
    onRelease?.call();
  }

  Future<void> _drain() async {
    final generation = _generation;
    _running = true;
    try {
      while (_queued != null) {
        final entry = _queued!;
        _queued = null;
        _active = entry;
        startedRuns++;
        try {
          final outcome = await _compute(entry.request);
          if (generation != _generation) return;
          // A finished merge is valid even if newer sources queued behind
          // it; showing it now is what makes the first result fast.
          entry.completer.complete(outcome);
        } catch (error, stack) {
          if (generation != _generation) return;
          if (entry.id == _latest) {
            entry.completer.completeError(error, stack);
          } else {
            entry.completer.complete(null);
          }
        } finally {
          if (generation == _generation) _active = null;
        }
      }
    } finally {
      if (generation == _generation) {
        _running = false;
        if (_releaseWhenIdle) _releaseNow();
      }
    }
  }
}

class _Queued {
  _Queued(this.id, this.request);
  final int id;
  final CombineRequest request;
  final completer = Completer<CombineOutcome?>();
}

typedef ArrangementPreparationCompute =
    Future<SongDocument> Function(
      CombineRequest request, {
      required String sourceId,
      required bool compact,
      required bool allowRejectedPreferredSource,
    });

typedef _PreparationMode = ({
  String sourceId,
  bool compact,
  bool allowRejectedPreferredSource,
});

/// Speculatively prepares the chart most likely to be saved during discovery.
/// It runs no more than one merge at a time and keeps only the newest
/// unclaimed queued request. A save that claims a queued item pins it until it
/// starts, so subsequent discovery updates cannot replace work the user is
/// already waiting for.
class PreferredArrangementPreparer {
  PreferredArrangementPreparer({this.compute});

  final ArrangementPreparationCompute? compute;
  _Preparation? _running;
  _Preparation? _queued;
  _Preparation? _completed;
  int _generation = 0;

  /// Starts or coalesces speculative work. Errors are left on the claimable
  /// future, with a separate listener preventing unclaimed errors escaping.
  void warm(
    CombineRequest request, {
    required String sourceId,
    required bool compact,
    bool allowRejectedPreferredSource = false,
    void Function(SongDocument)? onPrepared,
  }) {
    final mode = (
      sourceId: sourceId,
      compact: compact,
      allowRejectedPreferredSource: allowRejectedPreferredSource,
    );
    if (_matches(_queued, request, mode)) return;
    if (_matches(_running, request, mode) ||
        _matches(_completed, request, mode)) {
      discardSpeculation();
      return;
    }
    if (_queued?.claimed == true) return;
    final item = _Preparation(request, mode, _generation);
    if (onPrepared != null) {
      unawaited(item.future.then<void>(onPrepared, onError: (Object _) {}));
    }
    if (_running == null) {
      _start(item);
    } else {
      _queued = item;
    }
  }

  /// Returns only work that already exists; this call never starts a merge.
  Future<SongDocument>? claim(
    CombineRequest request, {
    required String sourceId,
    required bool compact,
    bool allowRejectedPreferredSource = false,
  }) {
    final mode = (
      sourceId: sourceId,
      compact: compact,
      allowRejectedPreferredSource: allowRejectedPreferredSource,
    );
    if (_matches(_completed, request, mode)) {
      return _completed!.future;
    }
    if (_matches(_running, request, mode)) {
      _running!.claimed = true;
      return _running!.future;
    }
    if (_matches(_queued, request, mode)) {
      _queued!.claimed = true;
      return _queued!.future;
    }
    return null;
  }

  /// Drops unclaimed queued work and, when requested, unclaimed running work.
  /// A completed matching result remains reusable.
  void discardSpeculation({bool interruptRunning = false}) {
    if (_queued case final queued? when !queued.claimed) {
      _queued = null;
    }
    if (_running case final running?
        when interruptRunning && !running.claimed) {
      running.worker?.dispose();
      _running = null;
      _startQueued();
    }
  }

  /// Ends this discovery's reuse window. Claimed work remains alive, while
  /// unclaimed work is discarded so a different song can prepare immediately.
  void clear() {
    _generation++;
    _completed = null;
    discardSpeculation(interruptRunning: true);
  }

  bool _matches(
    _Preparation? item,
    CombineRequest request,
    _PreparationMode mode,
  ) =>
      item != null &&
      item.generation == _generation &&
      item.mode == mode &&
      item.request.hasSameInputs(request);

  void _start(_Preparation item) {
    _running = item;
    () async {
      final compute = this.compute;
      final worker = compute == null ? CombineWorker() : null;
      item.worker = worker;
      try {
        final document = compute == null
            ? (await worker!._run(item.request, preferred: item.mode)).document!
            : await compute(
                item.request,
                sourceId: item.mode.sourceId,
                compact: item.mode.compact,
                allowRejectedPreferredSource:
                    item.mode.allowRejectedPreferredSource,
              );
        if (identical(_running, item) && item.generation == _generation) {
          _completed = item;
        }
        item.completer.complete(document);
      } catch (error, stack) {
        item.completer.completeError(error, stack);
      } finally {
        worker?.dispose();
        if (identical(_running, item)) {
          _running = null;
          _startQueued();
        }
      }
    }();
  }

  void _startQueued() {
    final next = _queued;
    if (next == null) return;
    _queued = null;
    _start(next);
  }
}

class _Preparation {
  _Preparation(this.request, this.mode, this.generation) {
    // Warm-up often has no Save attached yet; retain the error for claim(),
    // but make sure a speculative failure is handled in the meantime.
    future.then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }

  final CombineRequest request;
  final _PreparationMode mode;
  final int generation;
  final completer = Completer<SongDocument>();
  CombineWorker? worker;
  bool claimed = false;
  Future<SongDocument> get future => completer.future;
}
