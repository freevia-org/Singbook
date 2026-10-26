import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/roswell.dart';
import 'package:singbook/providers/provider.dart';

const _base = 'https://www.roswellmusicjam.com';
const _songA = 'Amazing Song';
const _songB = 'Another Song';

String _doc(
  String title,
  String artist,
  String body, {
  String book = 'Book One',
}) =>
    '{title: $title}\n'
    '{artist: $artist}\n'
    '{album: $book}\n'
    '{book: $book}\n'
    '{key: D}\n'
    '{capo: 2}\n'
    '{tempo: 96}\n'
    '{composer: Composer One}\n'
    '{lyricist: Lyricist One}\n'
    '$body\n';

Uint8List _zip(Map<String, String> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    archive.add(ArchiveFile.string(entry.key, entry.value));
  }
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

Uint8List _withCorruptCentralDirectoryCrc(Uint8List input) {
  final bytes = Uint8List.fromList(input);
  for (var i = 0; i <= bytes.length - 22; i++) {
    if (bytes[i] == 0x50 &&
        bytes[i + 1] == 0x4b &&
        bytes[i + 2] == 0x01 &&
        bytes[i + 3] == 0x02) {
      bytes[i + 16] ^= 0x01;
      return bytes;
    }
  }
  throw StateError('Synthetic ZIP central directory not found.');
}

Uint8List _duplicateNames() {
  // Archive.add replaces duplicate keys, so make the two directory/local
  // filenames identical only after encoding a genuine two-entry archive.
  final bytes = _zip({
    'one.chordpro': _doc(_songA, 'Artist A', '[D]Words'),
    'two.chordpro': _doc(_songB, 'Artist B', '[G]Other'),
  });
  final from = utf8.encode('two.chordpro');
  final to = utf8.encode('one.chordpro');
  var replaced = 0;
  for (var i = 0; i <= bytes.length - from.length; i++) {
    if (List.generate(
      from.length,
      (j) => bytes[i + j],
    ).asMap().entries.every((e) => e.value == from[e.key])) {
      bytes.setRange(i, i + to.length, to);
      replaced++;
    }
  }
  expect(replaced, 2);
  return bytes;
}

const _latestPath = '/_files/archives/rmj-all-chordpro-20261025_120000-EST.zip';
const _olderPath = '/_files/archives/rmj-all-chordpro-20261024_120000-EST.zip';
const _latestHref = '$_latestPath?dn=rmj-all-chordpro-20261025_120000-EST.zip';
const _olderHref = '$_olderPath?dn=rmj-all-chordpro-20261024_120000-EST.zip';

String _html(List<String> links) =>
    '<html><body>${links.map((href) => '<a href="$href">book</a>').join()}</body></html>';

class _Harness {
  _Harness({
    required Uint8List latest,
    Uint8List? older,
    String? page,
    Duration cacheLifetime = const Duration(hours: 24),
  }) {
    client = MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/songbooks') {
        return http.Response(
          page ?? _html([_latestHref, _olderHref]),
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      }
      if (request.url.path == _latestPath) {
        return http.Response.bytes(latest, 200);
      }
      if (request.url.path == _olderPath && older != null) {
        return http.Response.bytes(older, 200);
      }
      return http.Response('unexpected request', 404);
    });
    transport = ProviderTransport(
      client: client,
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    provider = RoswellMusicJamProvider(transport, cacheLifetime: cacheLifetime);
  }

  late final MockClient client;
  late final ProviderTransport transport;
  late final RoswellMusicJamProvider provider;
  final List<http.Request> requests = [];
  Future<void> close() => transport.close();
}

SongCandidate _foreign(String title, String artist) => SongCandidate(
  providerId: 'other',
  id: 'other-id',
  title: title,
  artist: artist,
);

void main() {
  test(
    'latest dated publisher archive is selected; arbitrary links are ignored',
    () async {
      final accepted = _zip({
        'amazing-song.chordpro': _doc(_songA, 'Artist A', '[D]Words'),
      });
      final ignored = _zip({
        'another-song.chordpro': _doc(_songB, 'Artist B', '[G]Old'),
      });
      final h = _Harness(
        latest: accepted,
        older: ignored,
        page: _html([
          _olderHref,
          _latestHref,
          'https://evil.example$_latestHref',
          '/_files/archives/not-rmj-all-chordpro-20261027_120000-EST.zip',
          '$_latestPath?download=1',
        ]),
      );
      try {
        final found = await h.provider.search(_songA);
        expect(found.map((c) => c.title), [_songA]);
        expect(h.requests.map((r) => r.url.path), ['/songbooks', _latestPath]);
        expect(
          h.requests.every((r) => r.url.host == 'www.roswellmusicjam.com'),
          isTrue,
        );
        expect(
          h.requests.last.url.queryParameters['dn'],
          'rmj-all-chordpro-20261025_120000-EST.zip',
        );
      } finally {
        await h.close();
      }
    },
  );

  test(
    'search and resolve share one archive load and preserve chart metadata and provenance',
    () async {
      final bytes = _zip({
        'amazing-song.chordpro':
            '${_doc(_songA, 'Artist A', '[D]Words\n[G]More')}{x_verse: forged}',
        'another-song.chordpro': _doc(
          _songB,
          'Artist B',
          '[C]Other',
          book: 'Book Two',
        ),
      });
      final h = _Harness(latest: bytes);
      try {
        final found = await h.provider.search('Amazing Song Artist A');
        expect(found, hasLength(1));
        final candidate = found.single;
        expect(candidate.providerId, 'roswellmusicjam');
        expect(candidate.id, 'amazing-song.chordpro');
        expect(candidate.url, '$_base/songbooks');
        expect(candidate.metadata['identityScope'], 'arrangement');
        final result = await h.provider.resolve(candidate);
        expect(h.requests.map((r) => r.url.path), ['/songbooks', _latestPath]);
        expect(result.body, contains('[D]Words'));
        expect(result.body, contains('[G]More'));
        expect(result.body, contains('{key: D}'));
        expect(result.body, contains('{capo: 2}'));
        expect(result.body, contains('{tempo: 96}'));
        expect(result.metadata['album'], 'Book One');
        expect(result.metadata['sourceCollections'], contains('Book One'));
        expect(result.metadata['key'], 'D');
        expect(result.metadata['capo'], 2);
        expect(result.metadata['tempo'], 96);
        expect(
          result.metadata['credits'],
          containsAll([
            equals({'role': 'composer', 'name': 'Composer One'}),
            equals({'role': 'lyricist', 'name': 'Lyricist One'}),
          ]),
        );
        expect(result.attribution, contains('Roswell Music Jam'));
        expect(
          (result.extra['rights'] as Map)['permissions'],
          containsPair('status', 'unknown'),
        );
        expect(result.extra['originalPayload'], isA<Map>());
        final payload = result.extra['originalPayload'] as Map;
        expect(payload['contentType'], 'text/chordpro');
        expect(payload['encoding'], 'utf-8');
        final original = utf8.decode(base64Decode(payload['base64'] as String));
        expect(original, contains('{title: $_songA}'));
        expect(original, contains('[D]Words'));
        expect(original, contains('{x_verse: forged}'));
        expect(result.body, isNot(contains('x_verse')));
        expect(result.body, isNot(contains('sourceDocumentId')));
        final second = await h.provider.resolve(
          (await h.provider.search(_songB)).single,
        );
        expect(second.candidate.artist, 'Artist B');
        expect(second.body, contains('[C]Other'));
        expect(second.metadata['album'], 'Book Two');
        expect(second.metadata['key'], 'D');
        expect(second.metadata['capo'], 2);
        expect(second.metadata['tempo'], 96);
        expect(
          second.metadata['credits'],
          contains(equals({'role': 'composer', 'name': 'Composer One'})),
        );
      } finally {
        await h.close();
      }
    },
  );

  test(
    'concurrent searches share a single archive request and 24h cache',
    () async {
      final h = _Harness(
        latest: _zip({'one.chordpro': _doc(_songA, 'Artist A', '[D]Words')}),
      );
      try {
        final both = await Future.wait([
          h.provider.search(_songA),
          h.provider.search(_songA),
        ]);
        expect(both, everyElement(hasLength(1)));
        expect(
          h.requests.where((r) => r.url.path == _latestPath),
          hasLength(1),
        );
        await h.provider.resolve(both.first.single);
        expect(
          h.requests.where((r) => r.url.path == _latestPath),
          hasLength(1),
        );
      } finally {
        await h.close();
      }
    },
  );

  test('zero cache lifetime refreshes between search and resolve', () async {
    final h = _Harness(
      latest: _zip({'one.chordpro': _doc(_songA, 'Artist A', '[D]Words')}),
      cacheLifetime: Duration.zero,
    );
    try {
      final candidate = (await h.provider.search(_songA)).single;
      await h.provider.resolve(candidate);
      expect(h.requests.where((r) => r.url.path == '/songbooks'), hasLength(2));
      expect(h.requests.where((r) => r.url.path == _latestPath), hasLength(2));
    } finally {
      await h.close();
    }
  });

  test(
    'a new release updates the same chart without changing prior evidence',
    () async {
      final oldRaw = '\uFEFF${_doc(_songA, 'Artist A', '[D]Original words')}';
      final newRaw = _doc(_songA, 'Artist A', '[G]Updated words');
      var current = _zip({'one.chordpro': oldRaw});
      var unavailable = false;
      final transport = ProviderTransport(
        client: MockClient(
          (r) async => r.url.path == '/songbooks'
              ? http.Response(_html([_latestHref]), 200)
              : unavailable
              ? http.Response('', 403)
              : http.Response.bytes(current, 200),
        ),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      final provider = RoswellMusicJamProvider(
        transport,
        cacheLifetime: Duration.zero,
      );
      try {
        final candidate = (await provider.search(_songA)).single;
        final previous = await provider.resolve(candidate);
        final snapshot = jsonEncode(previous.toJson());
        expect(
          base64Decode(previous.extra['originalPayload']['base64']),
          utf8.encode(oldRaw),
        );
        unavailable = true;
        await expectLater(
          provider.resolve(candidate),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.code,
              'code',
              'access_denied',
            ),
          ),
        );
        unavailable = false;
        current = _zip({'one.chordpro': newRaw});
        final refreshed = await provider.resolve(candidate);
        expect(refreshed.candidate.id, candidate.id);
        expect(refreshed.body, contains('[G]Updated words'));
        expect(
          refreshed.metadata['sourceArchiveSha256'],
          isNot(previous.metadata['sourceArchiveSha256']),
        );
        expect(jsonEncode(previous.toJson()), snapshot);
        expect(
          utf8.decode(
            base64Decode(refreshed.extra['originalPayload']['base64']),
          ),
          newRaw,
        );
      } finally {
        await transport.close();
      }
    },
  );

  test(
    'own candidates reject stale identity; foreign candidates require unique exact title and artist',
    () async {
      final h = _Harness(
        latest: _zip({
          'one.chordpro': _doc(_songA, 'Artist A', '[D]Words'),
          'two.chordpro': _doc(_songA, 'Artist A', '[G]Alternate'),
          'three.chordpro': _doc(_songB, 'Artist B', '[C]Other'),
        }),
      );
      try {
        final own = (await h.provider.search(_songA)).first;
        final stale = SongCandidate(
          providerId: own.providerId,
          id: own.id,
          title: 'Different Title',
          artist: own.artist,
        );
        await expectLater(
          h.provider.resolve(stale),
          throwsA(isA<ProviderException>()),
        );
        await expectLater(
          h.provider.resolve(_foreign(_songA, 'Artist A')),
          throwsA(isA<ProviderException>()),
        );
        final exact = (await h.provider.search(_songB)).single;
        final foreign = await h.provider.resolve(
          _foreign(exact.title, exact.artist),
        );
        expect(foreign.candidate.title, _songB);
        await expectLater(
          h.provider.resolve(_foreign(_songB, 'Wrong Artist')),
          throwsA(isA<ProviderException>()),
        );
      } finally {
        await h.close();
      }
    },
  );

  test(
    'missing artist is retained as missing and is not inferred for foreign matches',
    () async {
      final h = _Harness(
        latest: _zip({'untitled.chordpro': '{title: $_songA}\n[C]Words'}),
      );
      try {
        final results = await h.provider.search(_songA);
        expect(results, hasLength(1));
        expect(results.single.artist, isEmpty);
        await expectLater(
          h.provider.resolve(_foreign(_songA, 'Invented Artist')),
          throwsA(isA<ProviderException>()),
        );
      } finally {
        await h.close();
      }
    },
  );

  test('malformed page and malformed ZIP fail as provider errors', () async {
    for (final h in [
      _Harness(
        latest: _zip({'one.chordpro': _doc(_songA, 'Artist A', '[D]Words')}),
        page: '<html>no links</html>',
      ),
      _Harness(latest: Uint8List.fromList(utf8.encode('not a zip'))),
    ]) {
      try {
        await expectLater(
          h.provider.search(_songA),
          throwsA(isA<ProviderException>()),
        );
      } finally {
        await h.close();
      }
    }
  });

  test(
    'rejects traversal, nested archives, duplicate entries, and corrupt CRC archives',
    () async {
      final valid = {'one.chordpro': _doc(_songA, 'Artist A', '[D]Words')};
      final traversal = _zip({
        '../one.chordpro': _doc(_songA, 'Artist A', '[D]Words'),
      });
      final nested = _zip({
        'folder/one.chordpro': _doc(_songA, 'Artist A', '[D]Words'),
      });
      final duplicate = _duplicateNames();
      final corrupt = _withCorruptCentralDirectoryCrc(_zip(valid));
      final largeChart = _zip({'large.chordpro': 'x' * (512 * 1024 + 1)});
      final tooManyExpandedBytes = _zip({
        for (var i = 0; i < 33; i++) 'song-$i.chordpro': 'x' * (512 * 1024),
      });
      for (final bytes in [
        traversal,
        nested,
        duplicate,
        corrupt,
        largeChart,
        tooManyExpandedBytes,
      ]) {
        final h = _Harness(latest: bytes);
        try {
          await expectLater(
            h.provider.search(_songA),
            throwsA(isA<ProviderException>()),
          );
        } finally {
          await h.close();
        }
      }
    },
  );

  test(
    'cancelled lookup does not poison a previously valid archive cache',
    () async {
      final h = _Harness(
        latest: _zip({'one.chordpro': _doc(_songA, 'Artist A', '[D]Words')}),
      );
      try {
        final first = await h.provider.search(_songA);
        final requestsBeforeCancel = h.requests.length;
        final token = CancellationToken()..cancel();
        await expectLater(
          h.provider.search(_songA, cancel: token),
          throwsA(isA<ProviderException>()),
        );
        final again = await h.provider.search(_songA);
        expect(again.single.id, first.single.id);
        expect(h.requests, hasLength(requestsBeforeCancel));
      } finally {
        await h.close();
      }
    },
  );
}
