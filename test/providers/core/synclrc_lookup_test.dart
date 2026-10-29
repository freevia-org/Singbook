import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/core/catalogs.dart';
import 'package:singbook/providers/core/common.dart' show encodeSelection;
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/source_catalog.dart';

const selection = SongCandidate(
  providerId: 'genius',
  id: 'fixture',
  title: 'Paper Satellites',
  artist: 'Fixture Ensemble',
  album: 'Studio',
  durationSeconds: 214,
);
const sourceId = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const plain =
    'A paper satellite sails above the desk tonight\nOur quiet room remembers all the stories from the rain';
const synced =
    '[00:01.00]A paper satellite sails above the desk tonight\n[00:03.00]Our quiet room remembers all the stories from the rain';
const karaoke =
    '[00:01.00]<00:01.00>A <00:01.20>paper satellite sails above the desk tonight\n[00:03.00]<00:03.00>Our <00:03.30>quiet room remembers all the stories from the rain';

Map<String, dynamic> record({double duration = 214}) => {
  'id': sourceId,
  'track': selection.title,
  'artist': selection.artist,
  'album': selection.album,
  'duration': duration,
  'instrumental': false,
  'plain': plain,
  'synced': synced,
  'karaoke': karaoke,
};
Map<String, dynamic> searchRow() => {
  ...record(),
  'lyrics': {'plain': plain, 'synced': synced, 'karaoke': karaoke},
};
SongCandidate sourceSelection({String id = sourceId}) => SongCandidate(
  providerId: 'synclrc',
  id: id,
  title: selection.title,
  artist: selection.artist,
  album: selection.album,
  durationSeconds: selection.durationSeconds,
);
Matcher code(String expected) =>
    isA<ProviderException>().having((e) => e.code, 'code', expected);
ProviderTransport transport(http.Response Function(http.Request) respond) =>
    ProviderTransport(
      client: MockClient((request) async => respond(request)),
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
http.Response json(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);
ConfiguredBuiltinProvider configured(LyricsProvider provider) =>
    ConfiguredBuiltinProvider(
      SourceCatalog.parse(
        File('config/source-catalog-v2.json').readAsStringSync(),
      ).sources.singleWhere((entry) => entry.id == 'synclrc'),
      provider,
    );

void main() {
  test(
    'configured app discovery uses separate song fields, not a literal combined search',
    () async {
      final paths = <String>[];
      final wire = transport((request) {
        paths.add(request.url.path);
        if (request.url.path == '/search') {
          return json({'results': [], 'total': 0});
        }
        expect(request.url.queryParameters['track'], selection.title);
        expect(request.url.queryParameters['artist'], selection.artist);
        expect(request.url.queryParameters['album'], selection.album);
        expect(double.parse(request.url.queryParameters['duration']!), 214);
        expect(request.url.query, contains('Paper%20Satellites'));
        expect(request.url.query, isNot(contains('+')));
        return json(record());
      });
      final result = await findMatchingSource(
        configured(SyncLrcProvider(wire)),
        selection,
      );
      expect(paths, ['/lyrics']);
      expect(result.matchKind, MatchKind.sameRecording);
      expect(result.candidate.artist, selection.artist);
      expect(result.candidate.durationSeconds, 214);
      expect(
        result.timingTracks.map((track) => track.raw),
        containsAll([synced, karaoke]),
      );
      await wire.close();
    },
  );

  test('a small duration difference stays a song-level alternative', () async {
    final wire = transport((_) => json(record(duration: 219)));
    final result = await findMatchingSource(
      configured(SyncLrcProvider(wire)),
      selection,
    );
    expect(result.candidate.durationSeconds, 219);
    expect(result.matchKind, MatchKind.sameSong);
    await wire.close();
  });

  test(
    'a large duration difference is preserved and rejected by discovery',
    () async {
      final wire = transport((_) => json(record(duration: 259)));
      final provider = SyncLrcProvider(wire);
      final returned = (await provider.searchForSelection(
        selection,
        fallbackQuery: 'Paper Satellites Fixture Ensemble',
      )).single;
      expect(returned.durationSeconds, 259);
      await expectLater(
        findMatchingSource(configured(provider), selection),
        throwsA(code('unavailable')),
      );
      await wire.close();
    },
  );

  test('wrong artist from contextual lookup is rejected', () async {
    final wire = transport(
      (_) => json({...record(), 'artist': 'Different Performer'}),
    );
    await expectLater(
      findMatchingSource(configured(SyncLrcProvider(wire)), selection),
      throwsA(code('identity_mismatch')),
    );
    await wire.close();
  });

  test(
    'access denial and throttling do not trigger alternate requests',
    () async {
      for (final status in [403, 429]) {
        var count = 0;
        final wire = transport((_) {
          count++;
          return json({}, status);
        });
        await expectLater(
          findMatchingSource(configured(SyncLrcProvider(wire)), selection),
          throwsA(code(status == 403 ? 'access_denied' : 'rate_limited')),
        );
        expect(count, 1);
        await wire.close();
      }
    },
  );

  test('canonical lookup preserves the explicit selection identity', () async {
    final wire = transport((request) {
      expect(request.url.path, '/lyrics/$sourceId');
      return json(record());
    });
    final result = await SyncLrcProvider(wire).resolve(sourceSelection());
    expect(result.id, 'synclrc:$sourceId');
    expect(
      result.timingTracks.map((track) => track.raw),
      containsAll([synced, karaoke]),
    );
    await wire.close();
  });

  test(
    'canonical ID cannot silently change artist, release or duration',
    () async {
      for (final changed in [
        {'id': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'},
        {'track': 'Other Song'},
        {'artist': 'Other Artist'},
        {'album': 'Other Edition'},
        {'duration': 214.7},
      ]) {
        final wire = transport((_) => json({...record(), ...changed}));
        await expectLater(
          SyncLrcProvider(wire).resolve(sourceSelection()),
          throwsA(code('identity_mismatch')),
        );
        await wire.close();
      }
    },
  );

  test(
    'legacy carried selection still resolves without a network fetch',
    () async {
      var requests = 0;
      final wire = transport((request) {
        requests++;
        expect(request.url.path, '/search');
        return json({
          'results': [searchRow()],
        });
      });
      final provider = SyncLrcProvider(wire);
      final selected = (await provider.search(selection.title)).single;
      final result = await provider.resolve(selected);
      expect(result.id, selected.identity);
      expect(requests, 1);
      await wire.close();
    },
  );

  test(
    'uncarried legacy selection uses canonical lookup without changing its ID',
    () async {
      final encoded = encodeSelection(
        SongCandidate(
          providerId: 'synclrc',
          id: sourceId,
          title: selection.title,
          artist: selection.artist,
          album: selection.album,
          durationSeconds: selection.durationSeconds,
          metadata: {'query': 'Paper Satellites Fixture Ensemble'},
        ),
      );
      final wire = transport((request) {
        expect(request.url.path, '/lyrics/$sourceId');
        return json(record());
      });
      final selected = sourceSelection(id: encoded);
      final result = await SyncLrcProvider(wire).resolve(selected);
      expect(result.id, selected.identity);
      await wire.close();
    },
  );

  test('malformed legacy IDs fail before any request', () async {
    var requests = 0;
    final wire = transport((_) {
      requests++;
      return json({});
    });
    final encoded = encodeSelection(
      SongCandidate(
        providerId: 'synclrc',
        id: '../other',
        title: selection.title,
        artist: selection.artist,
        metadata: {'query': 'Paper Satellites'},
      ),
    );
    await expectLater(
      SyncLrcProvider(wire).resolve(sourceSelection(id: encoded)),
      throwsA(code('invalid_selection')),
    );
    expect(requests, 0);
    await wire.close();
  });

  test('missing flat variants are a schema failure', () async {
    final data = record()
      ..remove('plain')
      ..remove('synced')
      ..remove('karaoke');
    final wire = transport((_) => json(data));
    await expectLater(
      SyncLrcProvider(wire).resolve(sourceSelection()),
      throwsA(code('invalid_response')),
    );
    await wire.close();
  });

  test('cancellation stops an in-flight contextual lookup', () async {
    final entered = Completer<void>();
    final response = Completer<http.Response>();
    final cancel = CancellationToken();
    final wire = ProviderTransport(
      client: MockClient((request) {
        entered.complete();
        return response.future;
      }),
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    final future = SyncLrcProvider(wire).searchForSelection(
      selection,
      fallbackQuery: 'Paper Satellites Fixture Ensemble',
      cancel: cancel,
    );
    await entered.future;
    cancel.cancel();
    await expectLater(future, throwsA(code('cancelled')));
    response.complete(json(record()));
    await wire.close();
  });

  test('malformed bare IDs never become URI paths', () async {
    var requests = 0;
    final wire = transport((_) {
      requests++;
      return json(record());
    });
    await expectLater(
      SyncLrcProvider(wire).resolve(sourceSelection(id: '../other')),
      throwsA(code('invalid_selection')),
    );
    expect(requests, 0);
    await wire.close();
  });

  test(
    'context lookup and carried resolve retain returned album and duration',
    () async {
      var requests = 0;
      final wire = transport((_) {
        requests++;
        return json({...record(duration: 219), 'album': 'Returned Collection'});
      });
      final provider = SyncLrcProvider(wire);
      final returned = (await provider.searchForSelection(
        selection,
        fallbackQuery: 'Paper Satellites Fixture Ensemble',
      )).single;
      expect(returned.album, 'Returned Collection');
      expect(returned.durationSeconds, 219);
      final resolved = await provider.resolve(returned);
      expect(resolved.candidate.album, 'Returned Collection');
      expect(resolved.candidate.durationSeconds, 219);
      expect(requests, 1);
      await wire.close();
    },
  );

  test(
    'new recording context retries an empty or mismatched cached lookup',
    () async {
      for (final cached in <List<SongCandidate>>[
        [],
        [
          const SongCandidate(
            providerId: 'synclrc',
            id: 'old',
            title: 'Paper Satellites',
            artist: 'Fixture Ensemble',
            album: 'Earlier Collection',
            durationSeconds: 200,
          ),
        ],
      ]) {
        var requests = 0;
        final wire = transport((_) {
          requests++;
          return json(record());
        });
        final result = await findMatchingSource(
          configured(SyncLrcProvider(wire)),
          selection,
          searchedCandidates: cached,
        );
        expect(result.matchKind, MatchKind.sameRecording);
        expect(requests, 1);
        await wire.close();
      }
    },
  );

  test('a cached exact contextual result avoids another request', () async {
    var requests = 0;
    final wire = transport((_) {
      requests++;
      return json(record());
    });
    final provider = configured(SyncLrcProvider(wire));
    final rows = await provider.searchForSelection(
      selection,
      fallbackQuery: 'Paper Satellites Fixture Ensemble',
    );
    final result = await findMatchingSource(
      provider,
      selection,
      searchedCandidates: rows,
    );
    expect(result.matchKind, MatchKind.sameRecording);
    expect(requests, 1);
    await wire.close();
  });

  test(
    'catalog wrapper preserves ordinary search for other implementations',
    () async {
      final provider = PlainSearch();
      await configured(
        provider,
      ).searchForSelection(selection, fallbackQuery: 'original fallback');
      expect(provider.query, 'original fallback');
      expect(
        configured(provider).canReuseSearchForSelection(selection, []),
        true,
      );
    },
  );
}

class PlainSearch implements LyricsProvider {
  String? query;
  @override
  final definition = const ProviderDefinition(id: 'synclrc', name: 'Fixture');
  @override
  Future<List<SongCandidate>> search(
    String value, {
    CancellationToken? cancel,
  }) async {
    query = value;
    return [];
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw UnimplementedError();
}
