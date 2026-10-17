import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/core/diagnostics.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

const _lyrics =
    'A paper satellite sails above the desk tonight\n'
    'Our quiet room remembers all the stories from the rain';

Matcher _errorCode(String code) =>
    isA<ProviderException>().having((error) => error.code, 'code', code);

class _Provider implements LyricsProvider {
  _Provider({
    required this.id,
    required this.selected,
    this.failure,
    this.resolveStarted,
    this.waitForResolve,
  });

  final String id;
  final SongCandidate selected;
  final ProviderException? failure;
  final Completer<void>? resolveStarted;
  final Future<SourceResult>? waitForResolve;

  @override
  ProviderDefinition get definition =>
      ProviderDefinition(id: id, name: id, capabilities: const {'lyrics'});

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [selected];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolveStarted?.complete();
    if (waitForResolve case final pending?) return pending;
    if (failure case final error?) throw error;
    return SourceResult(candidate: selected, body: _lyrics);
  }
}

void main() {
  test('operation IDs remain stable while a fetch becomes terminal', () async {
    const source = SongCandidate(
      providerId: 'fixture',
      id: '1',
      title: 'Paper Satellites',
      artist: 'Fixture Ensemble',
      url:
          'https://lyrics.example/private/token/path?token=private&campaign=test#fragment',
    );
    final updates = <ProviderCheck>[];
    await SourceDiscoveryService([
      _Provider(id: 'fixture', selected: source),
    ]).discover(source, onProgress: updates.add);

    final snapshots = [
      for (final update in updates)
        for (final operation in update.operations)
          if (operation.id == 'fixture:lookup:fetch:0') operation,
    ];
    final stateTransitions = <String>[];
    for (final snapshot in snapshots) {
      if (stateTransitions.isEmpty || stateTransitions.last != snapshot.state) {
        stateTransitions.add(snapshot.state);
      }
    }
    expect(stateTransitions, ['pending', 'completed']);
    expect(snapshots.map((operation) => operation.id).toSet(), {
      'fixture:lookup:fetch:0',
    });
    expect(
      updates.last.operations.where(
        (operation) => operation.state == 'pending',
      ),
      isEmpty,
    );
    expect(snapshots.last.sourceUrl, 'https://lyrics.example');
  });

  test(
    'safe provider codes are preserved and unknown codes are reduced',
    () async {
      const source = SongCandidate(
        providerId: 'fixture',
        id: '1',
        title: 'Paper Satellites',
        artist: 'Fixture Ensemble',
      );
      for (final codes in const {
        'timeout': 'timeout',
        'token_leaked_in_code': 'provider_error',
      }.entries) {
        final updates = <ProviderCheck>[];
        await SourceDiscoveryService([
          _Provider(
            id: 'fixture',
            selected: source,
            failure: ProviderException(codes.key),
          ),
        ]).discover(source, onProgress: updates.add);

        final finalCheck = updates.last;
        expect(finalCheck.state, 'failed');
        expect(finalCheck.code, codes.value);
        final fetch = finalCheck.operations.singleWhere(
          (operation) => operation.phase == 'fetch',
        );
        expect(fetch.state, 'failed');
        expect(fetch.code, codes.value);
      }
    },
  );

  test('cancellation suppresses late provider callbacks', () async {
    const source = SongCandidate(
      providerId: 'fixture',
      id: '1',
      title: 'Paper Satellites',
      artist: 'Fixture Ensemble',
    );
    final started = Completer<void>();
    final release = Completer<SourceResult>();
    final cancel = CancellationToken();
    final updates = <ProviderCheck>[];
    final discovery = SourceDiscoveryService([
      _Provider(
        id: 'fixture',
        selected: source,
        resolveStarted: started,
        waitForResolve: release.future,
      ),
    ]).discover(source, cancel: cancel, onProgress: updates.add);

    await started.future.timeout(const Duration(seconds: 2));
    cancel.cancel();
    final updatesAtCancellation = updates.length;
    release.complete(SourceResult(candidate: source, body: _lyrics));
    await expectLater(discovery, throwsA(_errorCode('cancelled')));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(updates, hasLength(updatesAtCancellation));
  });

  test('YouTube diagnostic URLs keep only a valid video ID', () async {
    const source = SongCandidate(
      providerId: 'fixture',
      id: '1',
      title: 'Paper Satellites',
      artist: 'Fixture Ensemble',
      url:
          'https://www.youtube.com/watch?v=Abc_123-xY0&list=private#private-fragment',
    );
    final updates = <ProviderCheck>[];
    await SourceDiscoveryService([
      _Provider(id: 'fixture', selected: source),
    ]).discover(source, onProgress: updates.add);

    final fetch = updates.last.operations.singleWhere(
      (operation) => operation.phase == 'fetch',
    );
    expect(fetch.sourceUrl, 'https://www.youtube.com/watch?v=Abc_123-xY0');
  });

  test('diagnostic URLs preserve paths only for supported public origins', () {
    expect(
      safeDiagnosticUrl(
        'https://genius.com/ada-lovelace-paper-satellites-lyrics?utm_source=private#private',
      ),
      'https://genius.com/ada-lovelace-paper-satellites-lyrics',
    );
    expect(
      safeDiagnosticUrl(
        'https://unknown.example/private/token/path?token=private#private',
      ),
      'https://unknown.example',
    );
  });
}
