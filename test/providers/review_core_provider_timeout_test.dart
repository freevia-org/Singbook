import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

const _selection = SongCandidate(
  providerId: 'catalog',
  id: 'selected',
  title: 'The Amber Song',
  artist: 'Example Artist',
);
const _lyrics =
    'Amber lanterns glow across the quiet harbor\n'
    'Silver rain returns beneath the evening sky\n'
    'Morning opens every window on the distant shore';

/// Its first row resolves; its second never answers until it is cancelled.
class _StallingWords implements LyricsProvider {
  final resolved = <String>[];
  final stalled = Completer<CancellationToken>();

  @override
  final definition = const ProviderDefinition(
    id: 'words',
    name: 'Words',
    capabilities: {'catalog', 'lyrics'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => const [
    SongCandidate(
      providerId: 'words',
      id: 'a',
      title: 'The Amber Song',
      artist: 'Example Artist',
    ),
    SongCandidate(
      providerId: 'words',
      id: 'b',
      title: 'The Amber Song',
      artist: 'Example Artist',
    ),
  ];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolved.add(candidate.id);
    if (candidate.id == 'a') {
      return SourceResult(candidate: candidate, body: _lyrics);
    }
    stalled.complete(cancel!);
    await cancel.cancelled;
    throw const ProviderException('cancelled');
  }
}

/// Credits the song without its leading article, so the chart is only an
/// arrangement match and needs a live lyric reference to be accepted.
class _ArrangementChart implements LyricsProvider {
  @override
  final definition = const ProviderDefinition(
    id: 'chart',
    name: 'Chart',
    capabilities: {'catalog', 'lyrics', 'chords'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => const [
    SongCandidate(
      providerId: 'chart',
      id: 'arrangement',
      title: 'Amber Song',
      artist: 'Example Artist',
    ),
  ];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(candidate: candidate, body: '[C]$_lyrics');
}

void main() {
  test('a timed-out provider fails as timeout and keeps its accepted result', () async {
    final words = _StallingWords(), chart = _ArrangementChart();
    final tokens = {'words': CancellationToken(), 'chart': CancellationToken()};
    final checks = <ProviderCheck>[];
    final results = await SourceDiscoveryService([words, chart])
        .discover(
          _selection,
          enabledIds: {'words', 'chart'},
          providerCancellation: tokens,
          providerTimeout: const Duration(milliseconds: 200),
          alternativeTimeout: const Duration(seconds: 2),
          onProgress: checks.add,
        )
        .timeout(const Duration(seconds: 10));

    expect(words.resolved, ['a', 'b']);
    // The stalled request itself was stopped ...
    expect((await words.stalled.future).isCancelled, isTrue);
    // ... without withdrawing the source on the caller's behalf.
    expect(tokens['words']!.isCancelled, isFalse);
    expect(tokens['chart']!.isCancelled, isFalse);

    final wordChecks = checks.where((check) => check.providerId == 'words');
    expect(
      wordChecks.any(
        (check) => check.state == 'failed' && check.code == 'timeout',
      ),
      isTrue,
    );
    expect(wordChecks.last.state, 'failed');
    expect(wordChecks.last.code, 'timeout');
    expect(wordChecks.last.result?.candidate.id, 'a');

    final reference = results.singleWhere(
      (result) => result.candidate.providerId == 'words',
    );
    expect(reference.candidate.id, 'a');
    expect(reference.matchKind, isNot(MatchKind.rejected));
    // The earlier lyrics still corroborate the arrangement-only chart.
    final arrangement = results.singleWhere(
      (result) => result.candidate.providerId == 'chart',
    );
    expect(arrangement.extra['requiresLyricsAgreement'], isTrue);
    expect(arrangement.matchKind, isNot(MatchKind.rejected));
  });
}
