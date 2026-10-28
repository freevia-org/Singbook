import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/core/recording_context.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';

const _mbid = 'b5d7d380-f43a-4c1f-a5de-694150b093ac';
const _selection = SongCandidate(
  providerId: 'genius',
  id: 'selected-81',
  title: 'Lantern Map',
  artist: 'June Harbor',
  durationSeconds: 214,
);
const _lyrics = '''Paper boats drift past the orchard wall
Quiet windows catch the evening rain
We fold a map from yesterday's sky
And follow lanterns down the lane''';

SongCandidate _song(String provider, String id, {String? mbid}) =>
    SongCandidate(
      providerId: provider,
      id: id,
      title: _selection.title,
      artist: _selection.artist,
      album: 'Paper Moons',
      durationSeconds: 214,
      metadata: provider == 'genius'
          ? const {}
          : const {'identityScope': 'recording'},
      recordingIds: mbid == null ? const {} : {'musicbrainz': mbid},
    );

class _Genius implements LyricsProvider {
  @override
  final definition = const ProviderDefinition(
    id: 'genius',
    name: 'Genius',
    capabilities: {'lyrics'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async =>
      SourceResult(candidate: _song('genius', _selection.id), body: _lyrics);
}

class _MusicBrainz implements LyricsProvider {
  _MusicBrainz({this.initialError = 'unavailable'});
  final String? initialError;
  final seen = <SongCandidate>[];
  @override
  final definition = const ProviderDefinition(
    id: 'musicbrainz',
    name: 'MusicBrainz',
    capabilities: {'metadata'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => throw StateError('No speculative donor search');
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    seen.add(candidate);
    if (seen.length == 1 && initialError != null) {
      throw ProviderException(initialError!);
    }
    return SourceResult(
      candidate: _song('musicbrainz', _mbid, mbid: _mbid),
      body: '',
      metadata: const {'album': 'Paper Moons'},
    );
  }
}

class _Receiver implements LyricsProvider, RecordingContextReceiver {
  _Receiver({this.hold = false, this.error, this.resultMbid = _mbid});
  final bool hold;
  final String? error;
  final String? resultMbid;
  final seen = <SongCandidate>[];
  final started = Completer<CancellationToken?>();
  final release = Completer<void>();
  @override
  String get requiredRecordingIdNamespace => 'musicbrainz';
  @override
  final definition = const ProviderDefinition(
    id: 'analysis-fixture',
    name: 'Analysis',
    capabilities: {'metadata'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => throw StateError('Receiver must not search by title');
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    seen.add(candidate);
    if (!started.isCompleted) started.complete(cancel);
    if (hold) await release.future; // Intentionally ignores cancellation.
    cancel?.throwIfCancelled();
    if (error != null) throw ProviderException(error!);
    return SourceResult(
      candidate: _song(definition.id, _mbid, mbid: resultMbid),
      body: '',
      metadata: const {'analysis': 'unverified'},
    );
  }
}

LyricsProvider _configured(_Receiver receiver) => ConfiguredBuiltinProvider(
  SourceCatalogEntry.fromJson({
    'id': receiver.definition.id,
    'name': 'Configured analysis',
    'adapter': 'builtin',
    'status': 'active',
    'revision': 1,
    'capabilities': ['metadata'],
    'enabledByDefault': true,
    'accessMode': 'public',
    'website': 'https://example.org/',
    'hosts': <String>[],
  }),
  receiver,
);

void main() {
  for (final resultMbid in [null, '099b148e-fe99-4b79-be6e-5078e4bb7415']) {
    test(
      'receiver must demonstrate the exact consumed recording ID ($resultMbid)',
      () async {
        final receiver = _Receiver(resultMbid: resultMbid);
        final results = await SourceDiscoveryService([
          _Genius(),
          _MusicBrainz(),
          receiver,
        ]).discover(_selection);
        expect(receiver.seen, hasLength(1));
        expect(
          results.any(
            (s) =>
                s.candidate.providerId == receiver.definition.id &&
                s.matchKind != MatchKind.rejected,
          ),
          false,
        );
      },
    );
  }

  test(
    'operation callback withdrawing donor prevents receiver invocation',
    () async {
      final receiver = _Receiver(), token = CancellationToken();
      await SourceDiscoveryService([
        _Genius(),
        _MusicBrainz(),
        receiver,
      ]).discover(
        _selection,
        providerCancellation: {'musicbrainz': token},
        onProgress: (check) {
          if (check.providerId == receiver.definition.id &&
              check.operations.any(
                (op) => op.phase == 'metadata' && op.state == 'pending',
              )) {
            token.cancel();
          }
        },
      );
      expect(receiver.seen, isEmpty);
    },
  );

  for (final useToken in [false, true]) {
    test(
      'pre-late opt-out terminalizes a pending receiver (token=$useToken)',
      () async {
        final receiver = _Receiver(), token = CancellationToken();
        final enabled = {'genius', 'musicbrainz', receiver.definition.id};
        final checks = <ProviderCheck>[];
        await SourceDiscoveryService([
          _Genius(),
          _MusicBrainz(),
          receiver,
        ]).discover(
          _selection,
          enabledIds: enabled,
          providerCancellation: {if (useToken) receiver.definition.id: token},
          onProgress: (check) {
            checks.add(check);
            if (check.providerId == 'genius' && check.state == 'found') {
              if (useToken) {
                token.cancel();
              } else {
                enabled.remove(receiver.definition.id);
              }
            }
          },
        );
        expect(receiver.seen, isEmpty);
        expect(
          checks.lastWhere((c) => c.providerId == receiver.definition.id).state,
          'cancelled',
        );
      },
    );
  }

  for (final configured in [false, true]) {
    test(
      'one late recording lookup after resolved donor (configured=$configured)',
      () async {
        final receiver = _Receiver(), mb = _MusicBrainz();
        final results = await SourceDiscoveryService([
          _Genius(),
          mb,
          configured ? _configured(receiver) : receiver,
        ]).discover(_selection);
        expect(mb.seen, hasLength(2));
        expect(receiver.seen, hasLength(1));
        expect(receiver.seen.single.identity, _selection.identity);
        expect(receiver.seen.single.recordingIds, {'musicbrainz': _mbid});
        final found = results.singleWhere(
          (s) => s.candidate.providerId == receiver.definition.id,
        );
        expect(found.matchKind, MatchKind.sameRecording);
        expect(
          (found.extra['recordingContext'] as Map)['selectedIdentity'],
          _selection.identity,
        );
        expect(_selection.recordingIds, isEmpty);
      },
    );
  }

  test(
    'existing selected MBID uses only the ordinary initial lookup',
    () async {
      final receiver = _Receiver();
      await SourceDiscoveryService([receiver]).discover(
        SongCandidate.fromJson({
          ..._selection.toJson(),
          'recordingIds': {'musicbrainz': _mbid},
        }),
      );
      expect(receiver.seen, hasLength(1));
    },
  );

  for (final initialError in [null, 'rate_limited', 'blocked', 'timeout']) {
    test(
      'no receiver or extra donor lookup for initial $initialError outcome',
      () async {
        final receiver = _Receiver(),
            mb = _MusicBrainz(initialError: initialError);
        await SourceDiscoveryService([
          _Genius(),
          mb,
          receiver,
        ]).discover(_selection);
        expect(mb.seen, hasLength(1));
        expect(receiver.seen, isEmpty);
      },
    );
  }

  for (final disabled in ['musicbrainz', 'analysis-fixture']) {
    test('disabled $disabled does not trigger contextual calls', () async {
      final receiver = _Receiver(), mb = _MusicBrainz();
      await SourceDiscoveryService([_Genius(), mb, receiver]).discover(
        _selection,
        enabledIds: {'genius', 'musicbrainz', 'analysis-fixture'}
          ..remove(disabled),
      );
      expect(receiver.seen, isEmpty);
    });
  }

  for (final dependency in ['genius', 'musicbrainz', 'analysis-fixture']) {
    test(
      'cancelling $dependency during late lookup is prompt and suppresses result',
      () async {
        final token = CancellationToken(), receiver = _Receiver(hold: true);
        final pending = SourceDiscoveryService([
          _Genius(),
          _MusicBrainz(),
          receiver,
        ]).discover(_selection, providerCancellation: {dependency: token});
        final child = await receiver.started.future.timeout(
          const Duration(seconds: 2),
        );
        token.cancel();
        final results = await pending.timeout(const Duration(seconds: 1));
        expect(child!.isCancelled, isTrue);
        expect(
          results.any(
            (s) =>
                s.candidate.providerId == receiver.definition.id &&
                s.matchKind != MatchKind.rejected,
          ),
          isFalse,
        );
        receiver.release.complete();
      },
    );
  }

  test(
    'global cancellation completes even if receiver ignores its token',
    () async {
      final token = CancellationToken(), receiver = _Receiver(hold: true);
      final pending = SourceDiscoveryService([
        _Genius(),
        _MusicBrainz(),
        receiver,
      ]).discover(_selection, cancel: token);
      await receiver.started.future.timeout(const Duration(seconds: 2));
      token.cancel();
      await expectLater(
        pending.timeout(const Duration(seconds: 1)),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      receiver.release.complete();
    },
  );

  for (final phase in ['pending', 'found']) {
    test(
      'progress callback disabling donor at receiver $phase invalidates its proof',
      () async {
        final token = CancellationToken(), receiver = _Receiver();
        final checks = <ProviderCheck>[];
        final results =
            await SourceDiscoveryService([
              _Genius(),
              _MusicBrainz(),
              receiver,
            ]).discover(
              _selection,
              providerCancellation: {'musicbrainz': token},
              onProgress: (check) {
                checks.add(check);
                if (check.providerId == receiver.definition.id &&
                    check.state == phase &&
                    (phase == 'found' ||
                        checks
                                .where(
                                  (c) =>
                                      c.providerId == receiver.definition.id &&
                                      c.state == 'pending',
                                )
                                .length ==
                            2)) {
                  token.cancel();
                }
              },
            );
        expect(receiver.seen.length, phase == 'pending' ? 0 : 1);
        expect(
          results.any(
            (s) =>
                s.candidate.providerId == receiver.definition.id &&
                s.matchKind != MatchKind.rejected,
          ),
          isFalse,
        );
        if (phase == 'found') {
          expect(
            checks.any(
              (c) =>
                  c.providerId == receiver.definition.id &&
                  c.result?.matchKind == MatchKind.rejected,
            ),
            isTrue,
          );
        }
      },
    );
  }

  test('late receiver rate limit has no retry or donor requery', () async {
    final receiver = _Receiver(error: 'rate_limited'), mb = _MusicBrainz();
    final checks = <ProviderCheck>[];
    await SourceDiscoveryService([
      _Genius(),
      mb,
      receiver,
    ]).discover(_selection, onProgress: checks.add);
    expect(receiver.seen, hasLength(1));
    expect(mb.seen, hasLength(2));
    expect(
      checks.lastWhere((c) => c.providerId == receiver.definition.id).code,
      'rate_limited',
    );
  });

  test(
    'late receiver timeout is bounded and does not issue a second request',
    () async {
      final receiver = _Receiver(hold: true);
      await SourceDiscoveryService([_Genius(), _MusicBrainz(), receiver])
          .discover(
            _selection,
            alternativeTimeout: const Duration(milliseconds: 20),
          )
          .timeout(const Duration(seconds: 2));
      expect(receiver.seen, hasLength(1));
      receiver.release.complete();
    },
  );
}
