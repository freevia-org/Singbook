import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

const _selection = SongCandidate(
  providerId: 'chart',
  id: 'selected',
  title: 'Amber Song',
  artist: 'Example Artist',
);
const _lyrics =
    'Amber lanterns glow across the quiet harbor\n'
    'Silver rain returns beneath the evening sky\n'
    'Morning opens every window on the distant shore';
const _wrongChart =
    '[C]Different words describe a mountain beside an empty forest\n'
    '[G]Another traveler crosses valleys underneath a copper moon';

class _HeldCorroborationChart implements LyricsProvider {
  final retryStarted = Completer<CancellationToken>();
  final retryResponse = Completer<List<SongCandidate>>();
  final resolved = <String>[];
  int searches = 0;

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
  }) {
    searches++;
    if (!retryStarted.isCompleted) retryStarted.complete(cancel!);
    // Simulates a transport which completes its HTTP response after cancellation.
    // Discovery must retire its token and reject this late candidate before resolve.
    return retryResponse.future;
  }

  void releaseRetry() {
    if (!retryResponse.isCompleted) {
      retryResponse.complete(const [
        SongCandidate(
          providerId: 'chart',
          id: 'alternative',
          title: 'Amber Song',
          artist: 'Example Artist',
        ),
      ]);
    }
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolved.add(candidate.id);
    return SourceResult(
      candidate: candidate,
      body: candidate.id == 'selected' ? _wrongChart : '[C]$_lyrics',
    );
  }
}

class _ReferenceProvider implements LyricsProvider {
  final resolved = <String>[];

  @override
  final definition = const ProviderDefinition(
    id: 'reference',
    name: 'Reference',
    capabilities: {'catalog', 'lyrics'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => const [
    SongCandidate(
      providerId: 'reference',
      id: 'words',
      title: 'Amber Song',
      artist: 'Example Artist',
    ),
  ];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolved.add(candidate.id);
    return SourceResult(candidate: candidate, body: _lyrics);
  }
}

void main() {
  test(
    'provider cancellation retires a held corroboration retry without canceling peers',
    () async {
      final chart = _HeldCorroborationChart(), reference = _ReferenceProvider();
      final chartCancel = CancellationToken(),
          referenceCancel = CancellationToken();
      final checks = <ProviderCheck>[];
      final discovery = SourceDiscoveryService([chart, reference]).discover(
        _selection,
        providerCancellation: {
          'chart': chartCancel,
          'reference': referenceCancel,
        },
        alternativeTimeout: const Duration(seconds: 3),
        onProgress: checks.add,
      );
      try {
        final retryToken = await chart.retryStarted.future.timeout(
          const Duration(seconds: 2),
        );
        expect(chart.resolved, ['selected']);
        expect(reference.resolved, ['words']);
        expect(
          checks.any(
            (check) =>
                check.providerId == 'reference' && check.state == 'found',
          ),
          true,
        );
        expect(retryToken.isCancelled, false);
        chartCancel.cancel();
        await retryToken.cancelled.timeout(const Duration(seconds: 1));
        expect(referenceCancel.isCancelled, false);
        chart.releaseRetry();
        final results = await discovery.timeout(const Duration(seconds: 2));
        expect(chart.searches, 1);
        expect(
          chart.resolved,
          ['selected'],
          reason: 'a late retry response cannot trigger another resolve',
        );
        expect(
          results.any((source) => source.candidate.id == 'alternative'),
          false,
        );
        expect(
          results
              .singleWhere(
                (source) => source.candidate.providerId == 'reference',
              )
              .body,
          _lyrics,
        );
        expect(referenceCancel.isCancelled, false);
      } finally {
        chartCancel.cancel();
        chart.releaseRetry();
        try {
          await discovery.timeout(const Duration(seconds: 4));
        } catch (_) {
          // Drain the owned fake future even if the regression assertion failed.
        }
      }
    },
  );

  test(
    'cancellation after initial chart publication prevents any corroboration search',
    () async {
      final chart = _HeldCorroborationChart(), reference = _ReferenceProvider();
      final chartCancel = CancellationToken(),
          referenceCancel = CancellationToken();
      final discovery = SourceDiscoveryService([chart, reference]).discover(
        _selection,
        providerCancellation: {
          'chart': chartCancel,
          'reference': referenceCancel,
        },
        alternativeTimeout: const Duration(seconds: 2),
        onProgress: (check) {
          if (check.providerId == 'chart' && check.result != null) {
            chartCancel.cancel();
          }
        },
      );
      try {
        final results = await discovery.timeout(const Duration(seconds: 3));
        expect(chartCancel.isCancelled, true);
        expect(referenceCancel.isCancelled, false);
        expect(chart.searches, 0);
        expect(chart.retryStarted.isCompleted, false);
        expect(chart.resolved, ['selected']);
        expect(reference.resolved, ['words']);
        expect(
          results
              .singleWhere(
                (source) => source.candidate.providerId == 'reference',
              )
              .body,
          _lyrics,
        );
      } finally {
        chartCancel.cancel();
        chart.releaseRetry();
        try {
          await discovery.timeout(const Duration(seconds: 3));
        } catch (_) {
          // Release a retry started by a regressed implementation as well.
        }
      }
    },
  );
}
