import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/catalog_search.dart';
import 'package:singbook/providers/provider.dart';

ProviderDefinition _definition(
  String id, {
  bool configured = true,
  Set<String> capabilities = const {'catalog'},
  String accessMode = 'public',
}) => ProviderDefinition(
  id: id,
  name: id,
  configured: configured,
  capabilities: capabilities,
  accessMode: accessMode,
);

SongCandidate _row(String provider, String id) => SongCandidate(
  providerId: provider,
  id: id,
  title: 'A Shared Title',
  artist: 'A Shared Artist',
);

Matcher _code(String code) =>
    isA<ProviderException>().having((error) => error.code, 'code', code);

class _PendingSearch {
  final calls = <String>[];
  final tokens = <String, CancellationToken>{};
  final pending = <String, Completer<List<SongCandidate>>>{};

  Future<List<SongCandidate>> search(String id, CancellationToken cancel) {
    calls.add(id);
    tokens[id] = cancel;
    final completion = Completer<List<SongCandidate>>();
    pending[id] = completion;
    return completion.future;
  }

  void complete(String id, [List<SongCandidate>? rows]) {
    pending[id]!.complete(rows ?? [_row(id, '1')]);
  }
}

void main() {
  test(
    'unions raw rows without merging recording identity or metadata',
    () async {
      const primary = SongCandidate(
        providerId: 'genius',
        id: '1',
        title: 'A Shared Title',
        artist: 'A Shared Artist',
        metadata: {'artworkUrl': 'https://example.org/primary.jpg'},
      );
      const alternate = SongCandidate(
        providerId: 'lrclib',
        id: '2',
        title: 'A Shared Title (Live)',
        artist: 'A Shared Artist',
        album: 'Live Album',
        durationSeconds: 350,
        recordingIds: {'isrc': 'DIFFERENT'},
        metadata: {'artworkUrl': 'https://example.org/live.jpg'},
      );
      final calls = <String>[];
      final result = await searchCatalogsTogether(
        'A Shared Title',
        definitions: [_definition('lrclib'), _definition('genius')],
        primaryProviderId: 'genius',
        enabledIds: {'genius', 'lrclib'},
        search: (id, _) async {
          calls.add(id);
          return [id == 'genius' ? primary : alternate];
        },
      );
      expect(calls, ['genius', 'lrclib']);
      expect(result, [same(primary), same(alternate)]);
      expect(primary.album, isNull);
      expect(primary.durationSeconds, isNull);
      expect(primary.recordingIds, isEmpty);
      expect(primary.artworkUrl, 'https://example.org/primary.jpg');
    },
  );

  test('Genius failure returns usable secondary catalog results', () async {
    final fallback = _row('lrclib', '2');
    final result = await searchCatalogsTogether(
      'query',
      definitions: [_definition('genius'), _definition('lrclib')],
      primaryProviderId: 'genius',
      enabledIds: {'genius', 'lrclib'},
      search: (id, _) async {
        if (id == 'genius') {
          throw const ProviderException('blocked');
        }
        return [fallback];
      },
    );
    expect(result, [same(fallback)]);
  });

  test('an empty primary still returns secondary matches', () async {
    final result = await searchCatalogsTogether(
      'query',
      definitions: [_definition('genius'), _definition('lrclib')],
      primaryProviderId: 'genius',
      enabledIds: {'genius', 'lrclib'},
      search: (id, _) async => id == 'genius' ? [] : [_row(id, '2')],
    );
    expect(result.single.identity, 'lrclib:2');
  });

  test(
    'filters missing tokens, disabled and non-catalog metadata adapters',
    () async {
      final calls = <String>[];
      await searchCatalogsTogether(
        'query',
        definitions: [
          _definition('genius', configured: false),
          _definition('lrclib'),
          _definition('disabled'),
          _definition('metadata', capabilities: {'metadata'}),
          _definition('musicbrainz', capabilities: {'catalog', 'metadata'}),
        ],
        primaryProviderId: 'lrclib',
        enabledIds: {'lrclib', 'genius', 'metadata', 'musicbrainz'},
        search: (id, _) async {
          calls.add(id);
          return [_row(id, '1')];
        },
      );
      expect(calls, ['lrclib', 'musicbrainz']);
    },
  );

  test('does not silently replace an ineligible explicit primary', () async {
    final calls = <String>[];
    await expectLater(
      searchCatalogsTogether(
        'query',
        definitions: [
          _definition('genius', configured: false),
          _definition('lrclib'),
        ],
        primaryProviderId: 'genius',
        enabledIds: {'genius', 'lrclib'},
        search: (id, _) async {
          calls.add(id);
          return [];
        },
      ),
      throwsA(_code('not_configured')),
    );
    expect(calls, isEmpty);
  });

  test(
    'completion order cannot reorder provider or original row ranks',
    () async {
      final pending = _PendingSearch();
      final result = searchCatalogsTogether(
        'query',
        definitions: [
          _definition('z'),
          _definition('primary'),
          _definition('a'),
        ],
        primaryProviderId: 'primary',
        enabledIds: {'z', 'primary', 'a'},
        search: pending.search,
      );
      expect(pending.calls, ['primary', 'a', 'z']);
      pending.complete('z', [_row('z', '8')]);
      pending.complete('a', [_row('a', '3'), _row('a', '1')]);
      pending.complete('primary', [_row('primary', '9'), _row('primary', '2')]);
      expect((await result).map((row) => row.identity), [
        'primary:9',
        'primary:2',
        'a:3',
        'a:1',
        'z:8',
      ]);
    },
  );

  test(
    'deduplicates exact provider IDs only and rejects spoofed providers',
    () async {
      final first = _row('primary', 'same');
      final result = await searchCatalogsTogether(
        'query',
        definitions: [_definition('primary'), _definition('secondary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'secondary'},
        search: (id, _) async => id == 'primary'
            ? [first, _row('primary', 'same'), _row('secondary', 'spoof')]
            : [_row('primary', 'spoof'), _row('secondary', 'same')],
      );
      expect(result.map((row) => row.identity), [
        'primary:same',
        'secondary:same',
      ]);
      expect(result.first, same(first));
    },
  );

  test(
    'historical primary never queries another historical or song catalog',
    () async {
      final calls = <String>[];
      await searchCatalogsTogether(
        'query',
        definitions: [
          _definition('wikisource', accessMode: 'publicDomainText'),
          _definition('other-history', accessMode: 'publicDomainText'),
          _definition('genius'),
        ],
        primaryProviderId: 'wikisource',
        enabledIds: {'wikisource', 'other-history', 'genius'},
        search: (id, _) async {
          calls.add(id);
          return [_row(id, '1')];
        },
      );
      expect(calls, ['wikisource']);
    },
  );

  test('ordinary primary excludes historical text catalogs', () async {
    final calls = <String>[];
    await searchCatalogsTogether(
      'query',
      definitions: [
        _definition('wikisource', accessMode: 'publicDomainText'),
        _definition('genius'),
      ],
      primaryProviderId: 'genius',
      enabledIds: {'wikisource', 'genius'},
      search: (id, _) async {
        calls.add(id);
        return [_row(id, '1')];
      },
    );
    expect(calls, ['genius']);
  });

  test(
    'stable Wikisource ID stays isolated when access mode says public',
    () async {
      for (final primary in ['wikisource', 'genius']) {
        final calls = <String>[];
        final result = await searchCatalogsTogether(
          'query',
          definitions: [_definition('wikisource'), _definition('genius')],
          primaryProviderId: primary,
          enabledIds: {'wikisource', 'genius'},
          search: (id, _) async {
            calls.add(id);
            return [_row(id, '1')];
          },
        );
        expect(calls, [primary]);
        expect(result.single.providerId, primary);
      }
    },
  );

  test(
    'preserves the original primary error when no catalog has results',
    () async {
      const failure = ProviderException('rate_limited');
      await expectLater(
        searchCatalogsTogether(
          'query',
          definitions: [_definition('primary'), _definition('secondary')],
          primaryProviderId: 'primary',
          enabledIds: {'primary', 'secondary'},
          search: (id, _) async {
            if (id == 'primary') {
              throw failure;
            }
            throw const ProviderException('network');
          },
        ),
        throwsA(same(failure)),
      );
    },
  );

  test(
    'isolates secondary errors and queries duplicate definitions once',
    () async {
      final calls = <String>[];
      final result = await searchCatalogsTogether(
        'query',
        definitions: [
          _definition('primary'),
          _definition('secondary'),
          _definition('primary'),
        ],
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'secondary'},
        search: (id, _) async {
          calls.add(id);
          if (id == 'secondary') {
            throw StateError('secondary failed');
          }
          return [_row(id, '1')];
        },
      );
      expect(calls, ['primary', 'secondary']);
      expect(result.single.identity, 'primary:1');
    },
  );

  test(
    'an empty healthy primary with failed secondary returns no matches',
    () async {
      expect(
        await searchCatalogsTogether(
          'query',
          definitions: [_definition('primary'), _definition('secondary')],
          primaryProviderId: 'primary',
          enabledIds: {'primary', 'secondary'},
          search: (id, _) async {
            if (id == 'secondary') {
              throw const ProviderException('blocked');
            }
            return [];
          },
        ),
        isEmpty,
      );
    },
  );

  test('already cancelled search schedules nothing', () async {
    var calls = 0;
    await expectLater(
      searchCatalogsTogether(
        'query',
        definitions: [_definition('primary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary'},
        cancel: CancellationToken()..cancel(),
        search: (_, _) async {
          calls++;
          return [];
        },
      ),
      throwsA(_code('cancelled')),
    );
    expect(calls, 0);
  });

  test(
    'parent cancellation aborts children and prevents queued and late rows',
    () async {
      final pending = _PendingSearch();
      final cancel = CancellationToken();
      final result = searchCatalogsTogether(
        'query',
        definitions: [_definition('primary'), _definition('secondary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'secondary'},
        cancel: cancel,
        concurrency: 1,
        search: pending.search,
      );
      final assertion = expectLater(result, throwsA(_code('cancelled')));
      cancel.cancel();
      await assertion;
      expect(pending.tokens['primary']!.isCancelled, isTrue);
      pending.complete('primary');
      await Future<void>.delayed(Duration.zero);
      expect(pending.calls, ['primary']);
    },
  );

  testWidgets(
    'one whole timeout returns completed partial rows and stops queue',
    (tester) async {
      final pending = _PendingSearch();
      final statuses = <(String, String, String?)>[];
      final result = searchCatalogsTogether(
        'query',
        definitions: ['primary', 'a', 'b', 'c'].map(_definition).toList(),
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'a', 'b', 'c'},
        timeout: const Duration(seconds: 8),
        concurrency: 2,
        search: pending.search,
        onStatus: (id, state, code) => statuses.add((id, state, code)),
      );
      expect(pending.calls, ['primary', 'a']);
      await tester.pump(const Duration(seconds: 6));
      pending.complete('primary');
      await tester.pump();
      expect(pending.calls, ['primary', 'a', 'b']);
      await tester.pump(const Duration(seconds: 2));
      final rows = await result;
      expect(rows.map((row) => row.identity), ['primary:1']);
      expect(pending.tokens['a']!.isCancelled, isTrue);
      expect(pending.tokens['b']!.isCancelled, isTrue);
      pending.complete('a');
      pending.complete('b');
      await tester.pump();
      expect(pending.calls, ['primary', 'a', 'b']);
      expect(rows.map((row) => row.identity), ['primary:1']);
      expect(() => rows.add(_row('c', 'late')), throwsUnsupportedError);
      expect(statuses, [
        ('primary', 'pending', null),
        ('a', 'pending', null),
        ('primary', 'completed', null),
        ('b', 'pending', null),
        ('a', 'timeout', 'timeout'),
        ('b', 'timeout', 'timeout'),
        ('c', 'not_attempted', 'timeout'),
      ]);
    },
  );

  testWidgets('publishes a fast primary before a slow secondary completes', (
    tester,
  ) async {
    final pending = _PendingSearch();
    final snapshots = <List<SongCandidate>>[];
    var finished = false;
    final result =
        searchCatalogsTogether(
          'query',
          definitions: [_definition('primary'), _definition('secondary')],
          primaryProviderId: 'primary',
          enabledIds: {'primary', 'secondary'},
          search: pending.search,
          onProgress: snapshots.add,
        ).then((rows) {
          finished = true;
          return rows;
        });
    pending.complete('primary');
    await tester.pump();
    expect(finished, isFalse);
    expect(snapshots.single.single.identity, 'primary:1');
    expect(() => snapshots.single.clear(), throwsUnsupportedError);
    pending.complete('secondary');
    await tester.pump();
    expect((await result).map((row) => row.identity), [
      'primary:1',
      'secondary:1',
    ]);
    expect(snapshots.first.map((row) => row.identity), ['primary:1']);
    expect(snapshots, hasLength(2));
  });

  testWidgets(
    'secondary-first snapshots retain rows when primary arrives late',
    (tester) async {
      final pending = _PendingSearch();
      final snapshots = <List<SongCandidate>>[];
      final primary = _row('primary', 'p');
      final secondary = _row('secondary', 's');
      final result = searchCatalogsTogether(
        'query',
        definitions: [_definition('primary'), _definition('secondary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'secondary'},
        search: pending.search,
        onProgress: snapshots.add,
      );
      pending.complete('secondary', [secondary]);
      await tester.pump();
      expect(snapshots.single, [same(secondary)]);
      pending.complete('primary', [primary]);
      await tester.pump();
      expect(await result, [same(primary), same(secondary)]);
      expect(snapshots, hasLength(2));
      expect(snapshots.first, [same(secondary)]);
      expect(snapshots.last, [same(primary), same(secondary)]);
    },
  );

  testWidgets(
    'cancellation reports active and queued states without late callbacks',
    (tester) async {
      final pending = _PendingSearch();
      final cancel = CancellationToken();
      final snapshots = <List<SongCandidate>>[];
      final statuses = <(String, String, String?)>[];
      final result = searchCatalogsTogether(
        'query',
        definitions: [_definition('primary'), _definition('secondary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'secondary'},
        concurrency: 1,
        cancel: cancel,
        search: pending.search,
        onProgress: snapshots.add,
        onStatus: (id, state, code) => statuses.add((id, state, code)),
      );
      final assertion = expectLater(result, throwsA(_code('cancelled')));
      cancel.cancel();
      await tester.pump();
      await assertion;
      expect(statuses, [
        ('primary', 'pending', null),
        ('primary', 'cancelled', 'cancelled'),
        ('secondary', 'not_attempted', 'cancelled'),
      ]);
      pending.complete('primary');
      await tester.pump();
      expect(snapshots, isEmpty);
      expect(statuses, hasLength(3));
      expect(pending.calls, ['primary']);
    },
  );

  test(
    'statuses expose only stable error codes without exception text',
    () async {
      final statuses = <(String, String, String?)>[];
      await searchCatalogsTogether(
        'query',
        definitions: ['primary', 'a', 'b', 'c'].map(_definition).toList(),
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'a', 'b', 'c'},
        search: (id, _) async {
          if (id == 'a') {
            throw const ProviderException('blocked', 'private upstream body');
          }
          if (id == 'b') {
            throw const ProviderException('unknown_private_value');
          }
          if (id == 'c') {
            throw StateError('private exception text');
          }
          return [_row(id, '1')];
        },
        onStatus: (id, state, code) => statuses.add((id, state, code)),
      );
      expect(statuses, contains(('a', 'failed', 'blocked')));
      expect(statuses, contains(('b', 'failed', 'provider_error')));
      expect(statuses, contains(('c', 'failed', 'provider_error')));
      expect(statuses.toString(), isNot(contains('private')));
    },
  );

  test(
    'observer exceptions cannot fail a usable source or stall the queue',
    () async {
      final calls = <String>[];
      final result = await searchCatalogsTogether(
        'query',
        definitions: [_definition('primary'), _definition('secondary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'secondary'},
        concurrency: 1,
        search: (id, _) async {
          calls.add(id);
          return [_row(id, '1')];
        },
        onProgress: (_) => throw StateError('observer failed'),
        onStatus: (_, _, _) => throw StateError('observer failed'),
      );
      expect(calls, ['primary', 'secondary']);
      expect(result, hasLength(2));
    },
  );

  testWidgets(
    'timeout without results is explicit even if transport ignores cancellation',
    (tester) async {
      final pending = _PendingSearch();
      final result = searchCatalogsTogether(
        'query',
        definitions: [_definition('primary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary'},
        timeout: const Duration(seconds: 1),
        search: pending.search,
      );
      final assertion = expectLater(result, throwsA(_code('timeout')));
      await tester.pump(const Duration(seconds: 1));
      await assertion;
      expect(pending.tokens['primary']!.isCancelled, isTrue);
      pending.complete('primary');
      await tester.pump();
    },
  );

  testWidgets(
    'a failed primary remains the error if remaining catalogs time out',
    (tester) async {
      final pending = _PendingSearch();
      const failure = ProviderException('blocked');
      final result = searchCatalogsTogether(
        'query',
        definitions: [_definition('primary'), _definition('secondary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'secondary'},
        timeout: const Duration(seconds: 1),
        search: (id, cancel) {
          if (id == 'primary') {
            throw failure;
          }
          return pending.search(id, cancel);
        },
      );
      final assertion = expectLater(result, throwsA(same(failure)));
      await tester.pump(const Duration(seconds: 1));
      await assertion;
      expect(pending.tokens['secondary']!.isCancelled, isTrue);
      pending.complete('secondary');
      await tester.pump();
    },
  );

  testWidgets(
    'parent cancellation rejects even already completed partial rows',
    (tester) async {
      final pending = _PendingSearch();
      final cancel = CancellationToken();
      final result = searchCatalogsTogether(
        'query',
        definitions: [_definition('primary'), _definition('secondary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'secondary'},
        cancel: cancel,
        search: pending.search,
      );
      pending.complete('primary');
      await tester.pump();
      final assertion = expectLater(result, throwsA(_code('cancelled')));
      cancel.cancel();
      await tester.pump();
      await assertion;
      expect(pending.tokens['secondary']!.isCancelled, isTrue);
      pending.complete('secondary');
      await tester.pump();
    },
  );

  test(
    'clamps excessive concurrency at four and cancels without starting more',
    () async {
      final pending = _PendingSearch();
      final cancel = CancellationToken();
      final result = searchCatalogsTogether(
        'query',
        definitions: ['primary', 'a', 'b', 'c', 'd'].map(_definition).toList(),
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'a', 'b', 'c', 'd'},
        concurrency: 100,
        cancel: cancel,
        search: pending.search,
      );
      expect(pending.calls, ['primary', 'a', 'b', 'c']);
      final assertion = expectLater(result, throwsA(_code('cancelled')));
      cancel.cancel();
      await assertion;
      expect(pending.tokens.values.every((token) => token.isCancelled), isTrue);
      for (final id in pending.calls) {
        pending.complete(id);
      }
      await Future<void>.delayed(Duration.zero);
      expect(pending.calls, ['primary', 'a', 'b', 'c']);
    },
  );

  test('zero concurrency remains a bounded one-worker queue', () async {
    final pending = _PendingSearch();
    final result = searchCatalogsTogether(
      'query',
      definitions: [_definition('primary'), _definition('secondary')],
      primaryProviderId: 'primary',
      enabledIds: {'primary', 'secondary'},
      concurrency: 0,
      search: pending.search,
    );
    expect(pending.calls, ['primary']);
    pending.complete('primary');
    await Future<void>.delayed(Duration.zero);
    expect(pending.calls, ['primary', 'secondary']);
    pending.complete('secondary');
    expect(await result, hasLength(2));
  });

  test('an already expired deadline makes no provider requests', () async {
    var calls = 0;
    await expectLater(
      searchCatalogsTogether(
        'query',
        definitions: [_definition('primary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary'},
        timeout: Duration.zero,
        search: (_, _) async {
          calls++;
          return [];
        },
      ),
      throwsA(_code('timeout')),
    );
    expect(calls, 0);
  });

  testWidgets(
    'cancelling an active secondary preserves primary and other catalog work',
    (tester) async {
      final pending = _PendingSearch();
      final secondaryCancel = CancellationToken();
      final snapshots = <List<SongCandidate>>[];
      final statuses = <(String, String, String?)>[];
      var finished = false;
      final result =
          searchCatalogsTogether(
            'query',
            definitions: [
              'primary',
              'secondary',
              'tail',
            ].map(_definition).toList(),
            primaryProviderId: 'primary',
            enabledIds: {'primary', 'secondary', 'tail'},
            concurrency: 2,
            providerCancellation: {'secondary': secondaryCancel},
            search: pending.search,
            onProgress: snapshots.add,
            onStatus: (id, state, code) => statuses.add((id, state, code)),
          ).then((rows) {
            finished = true;
            return rows;
          });
      expect(pending.calls, ['primary', 'secondary']);
      expect(pending.tokens['secondary'], same(secondaryCancel));
      pending.complete('primary');
      await tester.pump();
      expect(snapshots.single.single.identity, 'primary:1');
      expect(pending.calls, ['primary', 'secondary', 'tail']);
      secondaryCancel.cancel();
      await tester.pump();
      expect(finished, isFalse);
      expect(statuses, contains(('secondary', 'cancelled', 'cancelled')));
      expect(pending.tokens['tail']!.isCancelled, isFalse);
      pending.complete('secondary');
      await tester.pump();
      expect(snapshots, hasLength(1));
      pending.complete('tail');
      await tester.pump();
      expect((await result).map((row) => row.identity), [
        'primary:1',
        'tail:1',
      ]);
      expect(snapshots.last.map((row) => row.identity), [
        'primary:1',
        'tail:1',
      ]);
      expect(statuses.where((status) => status.$1 == 'secondary').toList(), [
        ('secondary', 'pending', null),
        ('secondary', 'cancelled', 'cancelled'),
      ]);
    },
  );

  testWidgets(
    'a queued cancelled provider is reported without making its request',
    (tester) async {
      final pending = _PendingSearch();
      final secondaryCancel = CancellationToken();
      final statuses = <(String, String, String?)>[];
      final result = searchCatalogsTogether(
        'query',
        definitions: ['primary', 'secondary', 'tail'].map(_definition).toList(),
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'secondary', 'tail'},
        concurrency: 1,
        providerCancellation: {'secondary': secondaryCancel},
        search: pending.search,
        onStatus: (id, state, code) => statuses.add((id, state, code)),
      );
      expect(pending.calls, ['primary']);
      secondaryCancel.cancel();
      pending.complete('primary');
      await tester.pump();
      expect(pending.calls, ['primary', 'tail']);
      expect(statuses.where((status) => status.$1 == 'secondary').toList(), [
        ('secondary', 'cancelled', 'cancelled'),
      ]);
      pending.complete('tail');
      await tester.pump();
      expect((await result).map((row) => row.identity), [
        'primary:1',
        'tail:1',
      ]);
    },
  );

  testWidgets(
    'late transport errors after provider cancellation are consumed',
    (tester) async {
      final pending = _PendingSearch();
      final secondaryCancel = CancellationToken();
      final snapshots = <List<SongCandidate>>[];
      final statuses = <(String, String, String?)>[];
      final result = searchCatalogsTogether(
        'query',
        definitions: [_definition('primary'), _definition('secondary')],
        primaryProviderId: 'primary',
        enabledIds: {'primary', 'secondary'},
        providerCancellation: {'secondary': secondaryCancel},
        search: pending.search,
        onProgress: snapshots.add,
        onStatus: (id, state, code) => statuses.add((id, state, code)),
      );
      pending.complete('primary');
      await tester.pump();
      secondaryCancel.cancel();
      await tester.pump();
      expect((await result).single.identity, 'primary:1');
      final statusCount = statuses.length;
      final progressCount = snapshots.length;
      pending.pending['secondary']!.completeError(
        StateError('late transport failure'),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(statuses, hasLength(statusCount));
      expect(snapshots, hasLength(progressCount));
      expect(statuses, contains(('secondary', 'cancelled', 'cancelled')));
    },
  );
}
