import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/extra/common.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';

Matcher _code(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);

ProviderTransport _transport(
  Future<http.Response> Function(http.Request) handle,
) => ProviderTransport(
  client: MockClient(handle),
  hostInterval: Duration.zero,
  maxRetries: 0,
);

http.Response _json(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Rejected by `Uri.parse`, so resolving it used to throw FormatException.
const _malformedHref = 'http://[::1';

const _seanIndex =
    '<a href="$_malformedHref">Broken</a>'
    '<a href="/songs_and_poems/example/">Example</a>';
const _filkIndex =
    '<ul><li><a href="$_malformedHref">Broken</a>'
    '<a href="/songs/pages/a__Example.html">Example</a> (Author)'
    '<a href="/songs/Chordpro/a__Example.pro">file</a></li></ul>';

List<int> _windows1251(String text) => text.runes.map((code) {
  if (code < 128) return code;
  if (code >= 0x410 && code <= 0x44f) return code - 0x350;
  return const {0x490: 0xa5, 0x456: 0xb3, 0x457: 0xbf, 0x454: 0xba}[code]!;
}).toList();

void main() {
  test('the malformed fixture reference really is unparseable', () {
    expect(Uri.tryParse(_malformedHref), isNull);
    expect(resolvedUri(Uri.parse('https://example.org/'), _malformedHref), isNull);
    expect(
      resolvedUri(Uri.parse('https://example.org/a/'), '../b').toString(),
      'https://example.org/b',
    );
  });

  group('an empty catalog page is a failure and is never cached', () {
    test('Sean McGrath', () async {
      var empty = true;
      var requests = 0;
      final transport = _transport((r) async {
        requests++;
        return http.Response(empty ? '<p>Maintenance</p>' : _seanIndex, 200);
      });
      addTearDown(transport.close);
      final provider = SeanMcGrathProvider(transport);
      await expectLater(
        provider.search('Example'),
        throwsA(_code('extraction_failed')),
      );
      empty = false;
      expect((await provider.search('Example')).single.title, 'Example');
      // The successful catalog is cached.
      expect((await provider.search('Example')).single.title, 'Example');
      expect(requests, 2);
    });

    test('Open Filk Songbook', () async {
      var empty = true;
      var requests = 0;
      final transport = _transport((r) async {
        requests++;
        return http.Response(empty ? '<ul></ul>' : _filkIndex, 200);
      });
      addTearDown(transport.close);
      final provider = OpenFilkProvider(transport);
      await expectLater(
        provider.search('Example'),
        throwsA(_code('extraction_failed')),
      );
      empty = false;
      expect((await provider.search('Example')).single.artist, 'Author');
      expect((await provider.search('Author')).single.title, 'Example');
      expect(requests, 2);
    });
  });

  group('one malformed link does not fail a page', () {
    test('Sean McGrath index and song page', () async {
      final transport = _transport((r) async {
        if (r.url.path == '/songs_and_poems/') {
          return http.Response(_seanIndex, 200);
        }
        if (r.url.path.startsWith('/assets/chordpro/')) {
          return http.Response('{title: Example}\n[C]Synthetic words', 200);
        }
        return http.Response(
          '<a href="$_malformedHref">Broken</a>'
          '<a href="/assets/chordpro/example.pro">ChordPro</a>',
          200,
        );
      });
      addTearDown(transport.close);
      final provider = SeanMcGrathProvider(transport);
      final row = (await provider.search('Example')).single;
      expect(row.id, '/songs/example/');
      expect((await provider.resolve(row)).body, contains('Synthetic words'));
    });

    test('Open Filk Songbook index', () async {
      final transport = _transport(
        (r) async => http.Response(_filkIndex, 200),
      );
      addTearDown(transport.close);
      final row = (await OpenFilkProvider(transport).search('Example')).single;
      expect(row.id, '/songs/Chordpro/a__Example.pro');
      expect(
        row.metadata['sourcePageUrl'],
        'https://filksongbook.com/songs/pages/a__Example.html',
      );
      expect(row.metadata.containsKey('mediaLinks'), isFalse);
    });

    test('Chordie result page', () async {
      final transport = _transport(
        (r) async => http.Response(
          '<a href="$_malformedHref"><span>Broken</span><span>Row</span></a>'
          '<a href="/chord.pere/o.test/e.pro"><span>Example</span>'
          '<span>Writer</span></a>',
          200,
        ),
      );
      addTearDown(transport.close);
      final row = (await ChordieProvider(transport).search('Example')).single;
      expect(row.title, 'Example');
      expect(row.artist, 'Writer');
    });
  });

  group('one unusable search row does not fail the search', () {
    Map<String, dynamic> vocaSong(int id, String artist) => {
      'id': id,
      'name': 'Invented Song $id',
      'artistString': artist,
      'songType': 'Original',
    };

    test('VocaDB family', () async {
      var items = <Object?>[
        vocaSong(1, ''),
        'not an object',
        vocaSong(2, 'Invented Producer'),
        {...vocaSong(3, 'Removed'), 'deleted': true},
      ];
      final transport = _transport((r) async => _json({'items': items}));
      addTearDown(transport.close);
      final provider = VocaDbProvider(
        transport,
        requestInterval: Duration.zero,
      );
      final rows = await provider.search('Invented');
      expect(rows.map((row) => row.id), ['2']);
      expect(rows.single.artist, 'Invented Producer');

      // Deleted or merged rows alone are still an ordinary empty result.
      items = [
        {...vocaSong(3, 'Removed'), 'deleted': true},
      ];
      expect(await provider.search('Invented'), isEmpty);
      // A populated page without one readable row is a schema failure.
      items = [vocaSong(1, '')];
      await expectLater(
        provider.search('Invented'),
        throwsA(_code('invalid_response')),
      );
    });

    test('LyricsPlus', () async {
      var rows = <Object?>[
        {'title': 'Invented Song', 'artist': ''},
        7,
        {'title': 'Invented Song', 'artist': 'Invented Artist'},
        {'title': 'Invented Song', 'artist': 'Invented Artist', 'isrc': 'X'},
      ];
      final transport = _transport((r) async => _json({'results': rows}));
      addTearDown(transport.close);
      final provider = LyricsPlusProvider(transport);
      final found = (await provider.search('Invented')).single;
      expect(found.artist, 'Invented Artist');
      final evidence = found.extra['lyricsplus'] as Map;
      expect(evidence['catalogRows'], hasLength(2));
      expect(evidence['catalogResponseSha256'], hasLength(64));

      rows = [];
      expect(await provider.search('Invented'), isEmpty);
      rows = [
        {'title': '', 'artist': 'Invented Artist'},
      ];
      await expectLater(
        provider.search('Invented'),
        throwsA(_code('invalid_response')),
      );
    });

    test('Wikisource skips rows without a page identity', () async {
      final transport = _transport(
        (r) async => _json({
          'query': {
            'search': [
              {'title': 'No Page'},
              {'pageid': 0, 'title': 'Zero'},
              {'pageid': 9},
              {'pageid': 12, 'title': 'Example Text'},
            ],
          },
        }),
      );
      addTearDown(transport.close);
      final rows = await WikisourceProvider(transport).search('Example');
      expect(rows.map((row) => row.id), ['12']);
      expect(rows.single.url, 'https://en.wikisource.org/?curid=12');
    });
  });

  test(
    'Pisni contextual search continues past one unreadable same-title page',
    () async {
      const title = 'Пісня Ґанку';
      String page(String id) =>
          '<meta charset="windows-1251"><h1 class="nomarg">$title</h1>'
          '<table><tr><td><b>Виконують:</b></td></tr>'
          '<tr><td><a href="/persons/9.html">Виконавець</a></td></tr></table>'
          '<pre class="songwords">Ранкові наші слова</pre>'
          '<div class="smcont">Адреса цієї сторінки: '
          'https://www.pisni.org.ua/songs/$id.html</div>';
      final requested = <String>[];
      var broken = const {'/songs/17.html'};
      final transport = _transport((r) async {
        requested.add(r.url.path);
        final String body;
        if (r.url.path == '/search.php') {
          body =
              '<meta charset="windows-1251">'
              '<a href="/songs/17.html">$title</a>'
              '<a href="/songs/18.html">$title *</a>';
        } else if (broken.contains(r.url.path)) {
          body = '<meta charset="windows-1251"><h1>$title</h1>';
        } else {
          body = page(r.url.pathSegments.last.replaceAll('.html', ''));
        }
        return http.Response.bytes(
          _windows1251(body),
          200,
          headers: {'content-type': 'text/html; charset=windows-1251'},
        );
      });
      addTearDown(transport.close);
      const selection = SongCandidate(
        providerId: 'other',
        id: 'x',
        title: title,
        artist: 'Виконавець',
      );
      final rows = await PisniProvider(
        transport,
      ).searchForSelection(selection, fallbackQuery: title);
      expect(rows.single.id, '18');
      expect(rows.single.artist, 'Виконавець');
      expect(requested, ['/search.php', '/songs/17.html', '/songs/18.html']);

      // With no readable variant the original failure is still reported.
      broken = const {'/songs/17.html', '/songs/18.html'};
      await expectLater(
        PisniProvider(
          transport,
        ).searchForSelection(selection, fallbackQuery: title),
        throwsA(_code('extraction_failed')),
      );
    },
  );

  group('WorshipCommons catalog', () {
    Map<String, dynamic> row(String id, String title, [String? writer]) => {
      'id': id,
      'title': title,
      'writer': ?writer,
      'license': 'PD',
      'status': 'approved',
      'chordPro': '[C]Synthetic words',
    };

    test('overlapping first searches download the registry once', () async {
      var requests = 0;
      final transport = _transport((r) async {
        requests++;
        return _json({
          'rows': [row('a', 'Example Song', 'Author'), row('b', 'Other')],
        });
      });
      addTearDown(transport.close);
      final provider = WorshipCommonsProvider(transport);
      final results = await Future.wait([
        provider.search('Example'),
        provider.search('Other'),
        provider.search('Author'),
      ]);
      expect(results.map((rows) => rows.single.id), ['a', 'b', 'a']);
      expect(requests, 1);
    });

    test('a missing writer is not searchable as the word null', () async {
      final transport = _transport(
        (r) async => _json({
          'rows': [row('b', 'Other')],
        }),
      );
      addTearDown(transport.close);
      final provider = WorshipCommonsProvider(transport);
      expect(await provider.search('null'), isEmpty);
      expect((await provider.search('other')).single.artist, isEmpty);
    });

    test('a failed or cancelled load is not cached', () async {
      var fail = true;
      final transport = _transport(
        (r) async => fail
            ? http.Response('not json', 200)
            : _json({
                'rows': [row('a', 'Example Song', 'Author')],
              }),
      );
      addTearDown(transport.close);
      final provider = WorshipCommonsProvider(transport);
      await expectLater(
        provider.search('Example'),
        throwsA(_code('invalid_response')),
      );
      fail = false;
      final cancelled = CancellationToken()..cancel();
      await expectLater(
        provider.search('Example', cancel: cancelled),
        throwsA(_code('cancelled')),
      );
      expect((await provider.search('Example')).single.id, 'a');
    });
  });

  test('Wikidata looks up labels beyond one 40-id batch', () async {
    JsonMap claim(String id) => {
      'mainsnak': {
        'datavalue': {
          'value': {'id': id},
        },
      },
    };
    final performers = [for (var i = 1001; i <= 1045; i++) 'Q$i'];
    final batches = <List<String>>[];
    final transport = _transport((r) async {
      final query = r.url.queryParameters;
      if (query['action'] == 'wbsearchentities') {
        return _json({
          'search': [
            {'id': 'Q1'},
          ],
        });
      }
      final ids = query['ids']!.split('|');
      batches.add(ids);
      return _json({
        'entities': {
          for (final id in ids)
            id: id == 'Q1'
                ? {
                    'labels': {
                      'en': {'value': 'Invented Standard'},
                    },
                    'claims': {
                      'P31': [claim('Q7366')],
                      'P175': performers.map(claim).toList(),
                      'P86': [claim('Q900')],
                    },
                  }
                : {
                    'labels': {
                      'en': {
                        'value': id == 'Q900' ? 'Invented Composer' : 'P $id',
                      },
                    },
                  },
        },
      });
    });
    addTearDown(transport.close);
    final found = (await WikidataProvider(transport).search('Standard')).single;
    expect(batches.map((ids) => ids.length), [1, 40, 6]);
    expect(batches.last.last, 'Q900');
    // The composer followed 45 performers and used to lose its label.
    expect(found.artist, 'Invented Composer');
  });

  test('MusicBrainz accepts a recording id in any letter case', () async {
    const lower = '0a1b2c3d-0000-4000-8000-00000000abcd';
    final paths = <String>[];
    final transport = _transport((r) async {
      paths.add(r.url.path);
      return _json({
        'id': lower,
        'title': 'Invented Song',
        'artist-credit': [
          {'name': 'Invented Artist'},
        ],
      });
    });
    addTearDown(transport.close);
    final provider = MusicBrainzProvider(transport);
    final result = await provider.resolve(
      SongCandidate(
        providerId: 'other',
        id: 'x',
        title: 'Invented Song',
        artist: 'Invented Artist',
        recordingIds: {'musicbrainz': lower.toUpperCase()},
      ),
    );
    expect(paths, ['/ws/2/recording/$lower']);
    expect(result.candidate.id, lower);
    expect(result.metadata['musicbrainzRecordingId'], lower);
    await expectLater(
      provider.resolve(
        const SongCandidate(
          providerId: 'musicbrainz',
          id: '------------------------------------',
          title: 'Invented Song',
          artist: 'Invented Artist',
        ),
      ),
      throwsA(_code('invalid_response')),
    );
    expect(paths, hasLength(1));
  });

  group('shared helpers', () {
    test('escapeChordPro matches the adapters\' former escaping', () {
      const text = r'a\b [C] {t: x} # c';
      expect(
        escapeChordPro(text),
        text
            .replaceAll('\\', '\\\\')
            .replaceAll('[', r'\[')
            .replaceAll(']', r'\]')
            .replaceAll('{', r'\{')
            .replaceAll('}', r'\}'),
      );
      expect(escapeChordPro(text), r'a\\b \[C\] \{t: x\} # c');
      expect(escapeChordPro(text, hash: true), r'a\\b \[C\] \{t: x\} \# c');
    });

    test('utf8Exceeds agrees with the encoded length', () {
      for (final text in ['', 'abc', 'ééé', '日本語', 'a😀b', 'x' * 40]) {
        for (var limit = 0; limit <= 45; limit++) {
          expect(
            utf8Exceeds(text, limit),
            utf8.encode(text).length > limit,
            reason: '$text / $limit',
          );
        }
      }
    });

    test('identity and id helpers keep their former rules', () {
      expect(normalizedIdentity("Don’t  Stop-Me"), 'dont stop me');
      expect(mbidOrNull('0A1B2C3D-0000-4000-8000-00000000ABCD'), isNotNull);
      expect(mbidOrNull('------------------------------------'), isNull);
      expect(mbidOrNull(7), isNull);
      expect(() => strictObject({1: 'x'}), throwsA(_code('invalid_response')));
      expect(() => strictObject([]), throwsA(_code('invalid_response')));
      expect(strictObject({'a': 1}), {'a': 1});
      expect(queryMatches('stop DON', 'Don stop me'), isTrue);
      expect(queryMatches('  ', 'anything'), isFalse);
      expect(
        tokensMatch(queryTokens('stop don'), normalized('Don stop me')),
        isTrue,
      );
    });

    test('PacedQueue spaces requests and releases a cancelled waiter', () async {
      final queue = PacedQueue(const Duration(seconds: 5));
      final order = <int>[];
      await queue.run(() async => order.add(1), null);
      final cancel = CancellationToken();
      final watch = Stopwatch()..start();
      final waiting = queue.run(() async => order.add(2), cancel);
      cancel.cancel();
      await expectLater(waiting, throwsA(_code('cancelled')));
      expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
      expect(order, [1]);

      final fast = PacedQueue(const Duration(milliseconds: 60));
      final stamps = <Duration>[];
      final timer = Stopwatch()..start();
      await Future.wait([
        for (var i = 0; i < 3; i++)
          fast.run(() async => stamps.add(timer.elapsed), null),
      ]);
      expect(stamps, hasLength(3));
      expect(stamps[1] - stamps[0], greaterThanOrEqualTo(
        const Duration(milliseconds: 50),
      ));
      expect(stamps[2] - stamps[1], greaterThanOrEqualTo(
        const Duration(milliseconds: 50),
      ));
    });

    test('CatalogLoader shares one load and never caches a failure', () async {
      final loader = CatalogLoader<List<int>>();
      var calls = 0;
      Future<List<int>> fetch() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (calls == 1) throw const ProviderException('network');
        return [calls];
      }

      final first = loader.load(fetch, null);
      final second = loader.load(fetch, null);
      final third = loader.load(fetch, null);
      await expectLater(first, throwsA(_code('network')));
      expect(await second, [2]);
      expect(await third, [2]);
      expect(await loader.load(fetch, null), [2]);
      expect(calls, 2);
    });
  });
}
