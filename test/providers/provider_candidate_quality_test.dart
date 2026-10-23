import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

const _title = 'Amber Lantern';
const _artist = 'Synthetic Ensemble';
const _short =
    'Paper lanterns float across the sleeping garden\n'
    'Silver rivers carry every quiet song';
const _full = '$_short\nMorning opens all the windows to the sky';

void main() {
  test(
    'a later compatible complete payload replaces partial lyrics and retains both originals',
    () async {
      final short = _candidate('a-short');
      final full = _candidate('b-full');
      final provider = _Provider([full, short]);
      final first = _payload(
        short,
        metadata: {'label': 'First synthetic label'},
      );
      final later = _payload(
        full,
        body: _full,
        metadata: {
          'label': 'Second synthetic label',
          'composers': ['Synthetic Writer'],
        },
      );
      final firstBefore = first.toJson();
      final laterBefore = later.toJson();
      final lookup = findMatchingSource(provider, _selection());
      (await provider.resolveAt(0)).response.complete(first);
      (await provider.resolveAt(1)).response.complete(later);
      final chosen = await lookup;
      expect(provider.resolved.map((request) => request.candidate.id), [
        'a-short',
        'b-full',
      ]);
      expect(chosen.id, full.identity);
      expect(chosen.body, _full);
      expect(chosen.metadata, later.metadata);
      expect(chosen.matchKind, MatchKind.sameSong);
      final alternative = _alternatives(chosen).single;
      expect(alternative.id, short.identity);
      expect(alternative.body, _short);
      expect(alternative.metadata, first.metadata);
      expect(alternative.extra['rawMarker'], first.extra['rawMarker']);
      expect(first.toJson(), firstBefore);
      expect(later.toJson(), laterBefore);
    },
  );

  test(
    'longer contradictory lyrics remain a raw alternative without replacing the first',
    () async {
      final first = _candidate('a-first');
      final other = _candidate('b-contradictory');
      final provider = _Provider([other, first]);
      const contradictory =
          'Different words describe a copper mountain\n'
          'Nothing in these verses repeats the earlier story\n'
          'Several extra lines only make this different text longer\n'
          'Raw length alone cannot establish the intended arrangement';
      final lookup = findMatchingSource(provider, _selection());
      (await provider.resolveAt(0)).response.complete(_payload(first));
      (await provider.resolveAt(1)).response.complete(
        _payload(
          other,
          body: contradictory,
          metadata: {'label': 'Other edition'},
        ),
      );
      final chosen = await lookup;
      expect(chosen.id, first.identity);
      expect(chosen.body, _short);
      expect(_alternatives(chosen).single.body, contradictory);
      expect(_alternatives(chosen).single.metadata['label'], 'Other edition');
      expect(chosen.metadata.containsKey('label'), isFalse);
    },
  );

  test(
    'an exact selected provider reference is pinned and never searches for replacements',
    () async {
      final selected = _candidate('pinned');
      final provider = _Provider([_candidate('otherwise-fuller')]);
      final lookup = findMatchingSource(provider, selected);
      final request = await provider.resolveAt(0);
      expect(request.candidate, same(selected));
      request.response.complete(_payload(selected));
      final chosen = await lookup;
      expect(chosen.id, selected.identity);
      expect(chosen.body, _short);
      expect(chosen.matchKind, MatchKind.sameRecording);
      expect(provider.searchQueries, isEmpty);
      expect(provider.resolved, hasLength(1));
      expect(chosen.extra.containsKey('providerAlternatives'), isFalse);
    },
  );

  test(
    'an unavailable or extraction-failed selected row never searches for a replacement',
    () async {
      for (final code in ['unavailable', 'extraction_failed']) {
        final selected = _candidate('pinned');
        final provider = _Provider([
          _candidate('replacement'),
        ], forbidSearch: true);
        final lookup = findMatchingSource(provider, selected);
        final rejected = expectLater(lookup, throwsA(_code(code)));
        (await provider.resolveAt(0)).response.completeError(
          ProviderException(code, 'synthetic selected-row lookup failed'),
        );
        await rejected;
        expect(provider.searchQueries, isEmpty);
        expect(provider.resolved.map((request) => request.candidate.id), [
          'pinned',
        ]);
      }
    },
  );

  test(
    'skipped selected instrumental lyricless or excluded rows never substitute another ID',
    () async {
      for (final scenario in [
        (
          metadata: <String, dynamic>{'instrumental': true},
          exclude: <String>{},
        ),
        (metadata: <String, dynamic>{'hasLyrics': false}, exclude: <String>{}),
        (metadata: <String, dynamic>{}, exclude: {'pinned'}),
      ]) {
        final provider = _Provider([
          _candidate('replacement'),
        ], forbidSearch: true);
        await expectLater(
          findMatchingSource(
            provider,
            _candidate('pinned', metadata: scenario.metadata),
            exclude: scenario.exclude,
          ),
          throwsA(_code('unavailable')),
        );
        expect(provider.searchQueries, isEmpty);
        expect(provider.resolved, isEmpty);
      }
    },
  );

  test(
    'a blank selected payload reports unavailable without trying another version',
    () async {
      for (final body in ['', ' \n ']) {
        final selected = _candidate('pinned');
        final provider = _Provider([
          _candidate('replacement'),
        ], forbidSearch: true);
        final lookup = findMatchingSource(provider, selected);
        final rejected = expectLater(lookup, throwsA(_code('unavailable')));
        (await provider.resolveAt(
          0,
        )).response.complete(_payload(selected, body: body));
        await rejected;
        expect(provider.searchQueries, isEmpty);
        expect(provider.resolved.map((request) => request.candidate.id), [
          'pinned',
        ]);
      }
    },
  );

  test(
    'a mismatched selected payload remains rejected raw evidence without substitution',
    () async {
      final selected = _candidate('pinned');
      for (final returned in [
        _candidate('different-id'),
        const SongCandidate(
          providerId: 'secondary',
          id: 'pinned',
          title: 'Different composition',
          artist: 'Different ensemble',
        ),
      ]) {
        final provider = _Provider([
          _candidate('replacement'),
        ], forbidSearch: true);
        final observed = <SourceResult>[];
        final lookup = findMatchingSource(
          provider,
          selected,
          onCandidate: observed.add,
        );
        (await provider.resolveAt(0)).response.complete(
          _payload(
            returned,
            metadata: {'rawFact': 'Keep this synthetic rejected response'},
          ),
        );
        final rejected = await lookup;
        expect(rejected.matchKind, MatchKind.rejected);
        expect(rejected.matchReason, 'identity_mismatch');
        expect(rejected.candidate.toJson(), returned.toJson());
        expect(rejected.body, _short);
        expect(
          rejected.metadata['rawFact'],
          'Keep this synthetic rejected response',
        );
        expect(observed, isEmpty);
        expect(provider.searchQueries, isEmpty);
        expect(provider.resolved.map((request) => request.candidate.id), [
          'pinned',
        ]);
      }
    },
  );

  test(
    'an accept-policy rejection of the selected row does not trigger replacement search',
    () async {
      final selected = _candidate('pinned');
      final provider = _Provider([
        _candidate('replacement'),
      ], forbidSearch: true);
      final validated = <SourceResult>[];
      final observed = <SourceResult>[];
      final lookup = findMatchingSource(
        provider,
        selected,
        accept: (source) {
          validated.add(source);
          return false;
        },
        onCandidate: observed.add,
      );
      final rejected = expectLater(lookup, throwsA(_code('unavailable')));
      (await provider.resolveAt(0)).response.complete(_payload(selected));
      await rejected;
      expect(validated.single.id, selected.identity);
      expect(validated.single.matchKind, MatchKind.sameRecording);
      expect(observed, isEmpty);
      expect(provider.searchQueries, isEmpty);
      expect(provider.resolved.map((request) => request.candidate.id), [
        'pinned',
      ]);
    },
  );

  test(
    'explicit bounded corroboration may exclude the pinned row and validate another ID',
    () async {
      final selected = _candidate('a-selected');
      final partial = _candidate('b-partial');
      final complete = _candidate('c-complete');
      final provider = _Provider(
        [complete, partial, selected],
        capabilities: const {'catalog', 'lyrics', 'chords'},
      );
      final lookup = findMatchingSource(
        provider,
        selected,
        allowSelectedProviderAlternatives: true,
        exclude: {selected.id},
        operationPrefix: 'corroboration',
        accept: (source) => source.body == _full,
      );
      (await provider.resolveAt(0)).response.complete(_payload(partial));
      (await provider.resolveAt(
        1,
      )).response.complete(_payload(complete, body: _full));
      final chosen = await lookup;
      expect(chosen.id, complete.identity);
      expect(chosen.body, _full);
      expect(provider.searchQueries, ['$_title $_artist']);
      expect(provider.resolved.map((request) => request.candidate.id), [
        'b-partial',
        'c-complete',
      ]);
      expect(provider.resolved.length, lessThanOrEqualTo(3));
    },
  );

  test(
    'Wikisource never explores other pages even when corroboration opt-in is supplied',
    () async {
      const selected = SongCandidate(
        providerId: 'wikisource',
        id: '7',
        title: _title,
        artist: _artist,
      );
      final provider = _Provider(
        const [
          SongCandidate(
            providerId: 'wikisource',
            id: '8',
            title: _title,
            artist: _artist,
          ),
        ],
        id: 'wikisource',
        forbidSearch: true,
      );
      await expectLater(
        findMatchingSource(
          provider,
          selected,
          allowSelectedProviderAlternatives: true,
          exclude: {'7'},
          operationPrefix: 'corroboration',
        ),
        throwsA(_code('unavailable')),
      );
      expect(provider.searchQueries, isEmpty);
      expect(provider.resolved, isEmpty);
    },
  );

  test(
    'candidate ID ties are stable and duplicate or skipped rows do not exceed three resolves',
    () async {
      final provider = _Provider([
        _candidate('e'),
        _candidate('d'),
        _candidate('c'),
        _candidate('b'),
        _candidate('a'),
        _candidate('a'),
        _candidate('0-instrumental', metadata: const {'instrumental': true}),
        _candidate('0-excluded'),
      ]);
      final lookup = findMatchingSource(
        provider,
        _selection(),
        exclude: {'0-excluded'},
      );
      for (var i = 0; i < 3; i++) {
        final request = await provider.resolveAt(i);
        request.response.complete(_payload(request.candidate));
      }
      final chosen = await lookup;
      expect(provider.resolved.map((request) => request.candidate.id), [
        'a',
        'b',
        'c',
      ]);
      expect(chosen.candidate.id, 'a');
      expect(_alternatives(chosen).map((source) => source.candidate.id), [
        'b',
        'c',
      ]);
      expect(provider.searchQueries, ['$_title $_artist']);
      expect(provider.resolved.length, lessThanOrEqualTo(3));
    },
  );

  test(
    'a later provider failure retains accepted lyrics and only safe diagnostics',
    () async {
      for (final failure in [
        (code: 'network', expected: 'network'),
        (code: 'synthetic_private_upstream_code', expected: 'provider_error'),
      ]) {
        final first = _candidate('a-accepted');
        final provider = _Provider([first, _candidate('b-fails')]);
        final operations = <ProviderOperation>[];
        final lookup = findMatchingSource(
          provider,
          _selection(),
          onOperation: operations.add,
        );
        (await provider.resolveAt(0)).response.complete(_payload(first));
        (await provider.resolveAt(1)).response.completeError(
          ProviderException(
            failure.code,
            'synthetic upstream detail must not enter saved diagnostics',
          ),
        );
        final chosen = await lookup;
        expect(chosen.id, first.identity);
        expect(chosen.body, _short);
        expect(chosen.extra['alternativeLookupFailure'], failure.expected);
        final serialized = jsonEncode(chosen.toJson());
        expect(serialized, isNot(contains('synthetic upstream detail')));
        expect(serialized, isNot(contains('synthetic_private_upstream_code')));
        expect(
          operations
              .where(
                (operation) =>
                    operation.phase == 'fetch' && operation.state == 'failed',
              )
              .single
              .code,
          failure.expected,
        );
        expect(provider.resolved, hasLength(2));
      }
    },
  );

  test(
    'cancellation during the last alternative cannot return an earlier accepted result',
    () async {
      final first = _candidate('a-first');
      final last = _candidate('b-last');
      final provider = _Provider([first, last]);
      final token = CancellationToken();
      final lookup = findMatchingSource(provider, _selection(), cancel: token);
      final rejected = expectLater(
        lookup,
        throwsA(
          isA<ProviderException>().having(
            (error) => error.code,
            'code',
            'cancelled',
          ),
        ),
      );
      (await provider.resolveAt(0)).response.complete(_payload(first));
      final pending = await provider.resolveAt(1);
      token.cancel();
      // The provider deliberately ignores cancellation and finishes anyway.
      pending.response.complete(_payload(last, body: _full));
      await rejected;
      expect(pending.cancel?.isCancelled, isTrue);
      expect(provider.resolved, hasLength(2));
    },
  );

  test(
    'raw recording evidence outranks fuller same-song text and display facts are not proof',
    () async {
      final first = _candidate('a-display-only');
      final verified = _candidate('b-recording');
      final otherDisplay = _candidate('c-display-only');
      final provider = _Provider([otherDisplay, verified, first]);
      final lookup = findMatchingSource(
        provider,
        _selection(album: 'Dawn Collection', duration: 120),
      );
      (await provider.resolveAt(0)).response.complete(
        _payload(
          first,
          body: _full,
          metadata: {'album': 'Dawn Collection', 'durationSeconds': 120},
        ),
      );
      final rawRecording = _candidate(
        'b-recording',
        album: 'Dawn Collection',
        duration: 121,
      );
      (await provider.resolveAt(1)).response.complete(
        _payload(rawRecording, body: _short.split('\n').first),
      );
      (await provider.resolveAt(2)).response.complete(
        _payload(
          otherDisplay,
          body: _full,
          metadata: {'album': 'Dawn Collection', 'durationSeconds': 120},
        ),
      );
      final chosen = await lookup;
      expect(provider.resolved.map((request) => request.candidate.id), [
        'a-display-only',
        'b-recording',
        'c-display-only',
      ]);
      expect(chosen.id, rawRecording.identity);
      expect(chosen.matchKind, MatchKind.sameRecording);
      expect(chosen.matchReason, 'same_recording');
      expect(chosen.candidate.album, 'Dawn Collection');
      expect(chosen.candidate.durationSeconds, 121);
      expect(chosen.body, _short.split('\n').first);
      final alternatives = _alternatives(chosen);
      expect(
        alternatives.map((source) => source.matchKind),
        everyElement(MatchKind.sameSong),
      );
      expect(
        alternatives.map((source) => source.candidate.album),
        everyElement(isNull),
      );
      expect(
        alternatives.map((source) => source.metadata['album']),
        everyElement('Dawn Collection'),
      );
    },
  );

  test(
    'real discovery returns a recording-preferred source and its typed fuller alternative',
    () async {
      final short = _candidate('a-recording');
      final full = _candidate('b-full');
      final provider = _Provider([full, short]);
      final checks = <ProviderCheck>[];
      final discovery = SourceDiscoveryService([provider]).discover(
        _selection(album: 'Dawn Collection', duration: 120),
        onProgress: checks.add,
      );
      final recording = _candidate(
        'a-recording',
        album: 'Dawn Collection',
        duration: 121,
      );
      (await provider.resolveAt(0)).response.complete(_payload(recording));
      final later = await provider.resolveAt(1);
      expect(
        checks.any((check) => check.result?.id == recording.identity),
        isTrue,
      );
      expect(
        later.response.isCompleted,
        isFalse,
        reason:
            'validated first lyrics are published before the next lookup finishes',
      );
      later.response.complete(_payload(full, body: _full));
      final results = await discovery;
      expect(results.map((source) => source.id).toSet(), {
        recording.identity,
        full.identity,
      });
      final selectedRecording = results.singleWhere(
        (source) => source.id == recording.identity,
      );
      final wholeLyrics = results.singleWhere(
        (source) => source.id == full.identity,
      );
      expect(selectedRecording.matchKind, MatchKind.sameRecording);
      expect(selectedRecording.body, _short);
      expect(wholeLyrics.matchKind, MatchKind.sameSong);
      expect(wholeLyrics.body, _full);
      expect(
        checks.last.result?.id,
        recording.identity,
        reason: 'the preferred recording remains the provider summary',
      );
      expect(checks.any((check) => check.result?.id == full.identity), isTrue);
      expect(provider.resolved, hasLength(2));
    },
  );

  test(
    'forged serialized alternatives cannot fabricate an active discovered candidate',
    () async {
      final actual = _candidate('actual');
      final forged = _payload(_candidate('never-resolved'), body: _full);
      final provider = _Provider([actual]);
      final checks = <ProviderCheck>[];
      final discovery = SourceDiscoveryService([
        provider,
      ]).discover(_selection(), onProgress: checks.add);
      (await provider.resolveAt(0)).response.complete(
        _payload(actual).copyWith(
          extra: {
            'rawMarker': 'actual-payload',
            'providerAlternatives': [forged.toJson()],
          },
        ),
      );
      final results = await discovery;
      expect(results.single.id, actual.identity);
      expect(results.single.body, _short);
      expect(checks.any((check) => check.result?.id == forged.id), isFalse);
      expect(provider.resolved.single.candidate.id, 'actual');
      expect(results.single.extra['rawMarker'], 'actual-payload');
    },
  );

  test(
    'typed observers see only validated progress and cannot erase the best candidate',
    () async {
      final first = _candidate('a-short');
      final full = _candidate('b-full');
      final invalid = _candidate('c-wrong-identity');
      final provider = _Provider([invalid, full, first]);
      final progress = <SourceResult>[];
      final alternatives = <SourceResult>[];
      final lookup = findMatchingSource(
        provider,
        _selection(),
        onCandidate: (source) {
          progress.add(source);
          throw StateError('synthetic observer failure');
        },
        onAlternative: (source) {
          alternatives.add(source);
          throw StateError('synthetic alternative observer failure');
        },
      );
      (await provider.resolveAt(0)).response.complete(_payload(first));
      final second = await provider.resolveAt(1);
      expect(progress.map((source) => source.id), [first.identity]);
      expect(alternatives, isEmpty);
      second.response.complete(_payload(full, body: _full));
      final third = await provider.resolveAt(2);
      expect(progress.map((source) => source.id), [
        first.identity,
        full.identity,
      ]);
      expect(
        progress.map((source) => source.matchKind),
        everyElement(MatchKind.sameSong),
      );
      expect(
        alternatives,
        isEmpty,
        reason:
            'qualified nonbest alternatives are emitted after choosing the best',
      );
      third.response.complete(
        _payload(
          const SongCandidate(
            providerId: 'secondary',
            id: 'c-wrong-identity',
            title: 'A different title',
            artist: 'A different ensemble',
          ),
        ),
      );
      final chosen = await lookup;
      expect(chosen.id, full.identity);
      expect(chosen.body, _full);
      expect(progress.map((source) => source.id), [
        first.identity,
        full.identity,
      ]);
      expect(alternatives.single.id, first.identity);
      expect(alternatives.single.body, _short);
    },
  );

  test(
    'real discovery preserves early lyrics and a later failed operation',
    () async {
      final accepted = _candidate('a-accepted');
      final provider = _Provider([accepted, _candidate('b-failed')]);
      final checks = <ProviderCheck>[];
      final discovery = SourceDiscoveryService([
        provider,
      ]).discover(_selection(), onProgress: checks.add);
      (await provider.resolveAt(0)).response.complete(_payload(accepted));
      final failed = await provider.resolveAt(1);
      expect(
        checks.any((check) => check.result?.id == accepted.identity),
        isTrue,
      );
      final secondFetch = checks.last.operations
          .lastWhere(
            (operation) =>
                operation.phase == 'fetch' && operation.state == 'pending',
          )
          .id;
      failed.response.completeError(
        const ProviderException(
          'network',
          'synthetic upstream detail must not become a diagnostic',
        ),
      );
      final results = await discovery;
      expect(results.single.id, accepted.identity);
      expect(results.single.body, _short);
      expect(results.single.extra['alternativeLookupFailure'], 'network');
      final operation = checks.last.operations.singleWhere(
        (item) => item.id == secondFetch,
      );
      expect(operation.state, 'failed');
      expect(operation.code, 'network');
      expect(
        checks
            .expand((check) => check.operations)
            .where(
              (operation) =>
                  operation.id == secondFetch && operation.state == 'completed',
            ),
        isEmpty,
      );
      expect(
        checks.last.operations.any((operation) => operation.state == 'failed'),
        isTrue,
      );
      expect(
        checks.last.operations.any((operation) => operation.state == 'pending'),
        isFalse,
      );
      expect(checks.last.result?.id, accepted.identity);
    },
  );

  test(
    'initial chord progress reaches final validation without eager alternatives',
    () async {
      final first = _candidate('a-chart');
      final provider = _Provider(
        [first, _candidate('b-failed')],
        capabilities: const {'catalog', 'lyrics', 'chords'},
      );
      final checks = <ProviderCheck>[];
      final discovery = SourceDiscoveryService([provider]).discover(
        const SongCandidate(
          providerId: 'primary',
          id: 'chosen',
          title: 'Amber Lantern (Acoustic)',
          artist: _artist,
        ),
        onProgress: checks.add,
      );
      const chart =
          '[C]Paper lanterns float across the sleeping garden\n'
          '[G]Silver rivers carry every quiet song';
      (await provider.resolveAt(
        0,
      )).response.complete(_payload(first, body: chart));
      final results = await discovery;
      expect(
        checks.any(
          (check) =>
              check.result?.id == first.identity &&
              check.result?.matchKind == MatchKind.sameSong,
        ),
        isTrue,
      );
      expect(provider.resolved.map((request) => request.candidate.id), [
        first.id,
      ]);
      expect(results.single.id, first.identity);
      expect(results.single.body, chart);
      expect(results.single.matchKind, MatchKind.rejected);
      expect(results.single.matchReason, 'uncorroborated_arrangement');
      expect(checks.last.result?.matchKind, MatchKind.rejected);
      expect(
        checks.last.operations.any(
          (operation) =>
              operation.phase == 'corroborate' && operation.state == 'rejected',
        ),
        isTrue,
      );
    },
  );

  test(
    'a canceled resolve throwing unavailable still reports cancellation',
    () async {
      final provider = _Provider([_candidate('only')]);
      final token = CancellationToken();
      final lookup = findMatchingSource(provider, _selection(), cancel: token);
      final rejected = expectLater(
        lookup,
        throwsA(
          isA<ProviderException>().having(
            (error) => error.code,
            'code',
            'cancelled',
          ),
        ),
      );
      final pending = await provider.resolveAt(0);
      token.cancel();
      pending.response.completeError(const ProviderException('unavailable'));
      await rejected;
      expect(provider.resolved, hasLength(1));
    },
  );
}

SongCandidate _selection({String? album, double? duration}) => SongCandidate(
  providerId: 'primary',
  id: 'chosen',
  title: _title,
  artist: _artist,
  album: album,
  durationSeconds: duration,
);

SongCandidate _candidate(
  String id, {
  String? album,
  double? duration,
  JsonMap metadata = const {},
}) => SongCandidate(
  providerId: 'secondary',
  id: id,
  title: _title,
  artist: _artist,
  album: album,
  durationSeconds: duration,
  metadata: metadata,
);

SourceResult _payload(
  SongCandidate candidate, {
  String body = _short,
  JsonMap metadata = const {},
}) => SourceResult(
  candidate: candidate,
  body: body,
  metadata: metadata,
  attribution: 'Synthetic provider attribution',
  extra: {'rawMarker': 'payload-${candidate.id}'},
);

List<SourceResult> _alternatives(SourceResult result) => [
  for (final raw in result.extra['providerAlternatives'] as List? ?? const [])
    SourceResult.fromJson(jsonMap(raw)),
];

Matcher _code(String code) =>
    isA<ProviderException>().having((error) => error.code, 'code', code);

class _Provider implements LyricsProvider {
  _Provider(
    this.candidates, {
    Set<String> capabilities = const {'catalog', 'lyrics'},
    String id = 'secondary',
    this.forbidSearch = false,
  }) : definition = ProviderDefinition(
         id: id,
         name: 'Synthetic $id provider',
         capabilities: capabilities,
       );
  final List<SongCandidate> candidates;
  final bool forbidSearch;
  final searchQueries = <String>[];
  final resolved = <_ResolveRequest>[];
  final _waiters = <int, Completer<_ResolveRequest>>{};

  @override
  final ProviderDefinition definition;

  Future<_ResolveRequest> resolveAt(int index) => index < resolved.length
      ? Future.value(resolved[index])
      : (_waiters[index] ??= Completer<_ResolveRequest>()).future;

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    searchQueries.add(query);
    if (forbidSearch) {
      throw StateError('A pinned version must not search for replacements');
    }
    return candidates;
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) {
    final request = _ResolveRequest(candidate, cancel);
    resolved.add(request);
    _waiters.remove(resolved.length - 1)?.complete(request);
    return request.response.future;
  }
}

class _ResolveRequest {
  _ResolveRequest(this.candidate, this.cancel);
  final SongCandidate candidate;
  final CancellationToken? cancel;
  final response = Completer<SourceResult>();
}
