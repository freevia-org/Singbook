import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/extra/mutopia.dart';
import 'package:singbook/providers/provider.dart';

const _licenseHref = 'http://creativecommons.org/licenses/publicdomain/';

String _searchRow({
  required String id,
  required String title,
  required String composer,
  required String lilypondUrl,
  String license = 'Public Domain',
  String source = 'An invented vocal score, Example Press.',
  String updated = '2026/10/30',
  String instrument = 'Voice, Piano',
}) =>
    '''<table class="table-bordered result-table"><tbody>
<tr><td>$title</td><td>by $composer</td><td></td><td></td></tr>
<tr><td>for $instrument</td><td></td><td>Classical</td><td>Example Arranger</td></tr>
<tr><td>$source</td><td><a href="../legal.html#publicdomain">$license</a></td>
<td><a href="piece-info.cgi?id=$id">More Information</a></td><td>$updated</td></tr>
<tr><td><a href="$lilypondUrl">.ly file</a></td><td></td><td></td><td></td></tr>
<tr><td>A4 .ps file (gzipped)</td><td>A4 .pdf file</td>
<td>Letter .ps file (gzipped)</td><td>Letter .pdf file</td></tr>
</tbody></table>''';

String _searchPage(Iterable<String> rows) =>
    '<html><body><table class="outer-table"><tbody>'
    '${rows.map((row) => '<tr><td>$row</td></tr>').join()}'
    '</tbody></table></body></html>';

String _emptySearch() =>
    '<html><body><table class="outer-table"><tbody><div '
    'class="alert alert-info" role="alert">'
    'Sorry, no matches were found for your search criteria.'
    '</div></tbody></table></body></html>';

String _lilypond({
  required String id,
  required String title,
  String composer = 'Ada Example',
  String license = 'Public Domain',
  String firstLyrics = 'lu -- na chia -- ra',
  String secondLyrics = 'silver river',
  bool thirdStream = false,
}) =>
    '''\\version "2.18.2"
\\header {
  title = "$title"
  mutopiatitle = "$title"
  composer = "$composer"
  poet = "B. Invented"
  arranger = "C. Example"
  source = "An invented vocal score, Example Press."
  license = "$license"
  footer = "Mutopia-2026/10/30-$id"
}
firstLyrics = \\lyricmode { $firstLyrics }
secondLyrics = \\lyricmode { $secondLyrics }
\\score {
  \\new Lyrics \\lyricsto "voice" \\firstLyrics
  \\new Lyrics \\lyricsto "voice" \\secondLyrics
}
${thirdStream ? 'text = \\lyricmode { gentle dawn }' : ''}
''';

String _detailPage({
  required String id,
  required String title,
  String composer = 'Ada Example',
  String license = 'Public Domain',
  String? lilypondUrl,
  String source = 'An invented vocal score, Example Press.',
}) {
  final lily =
      lilypondUrl ?? 'https://www.mutopiaproject.org/ftp/Example/Work/Work.ly';
  return '''<html><body>
<h2>$title</h2><h4>by $composer</h4>
<table class="table table-bordered result-table"><tbody>
<tr><td><b>Instrument(s):</b> Voice, Piano</td><td><b>Style:</b> Classical</td></tr>
<tr><td></td><td><b>Arranger(s):</b> C. Example</td></tr>
<tr><td><b>Opus:</b> Not known</td><td><b>Date of composition:</b> Not known</td></tr>
<tr><td><b>Source:</b> $source</td><td><b>Copyright:</b> <a href="../legal.html#publicdomain">$license</a><a href="$_licenseHref"></a></td></tr>
<tr><td><b>Last updated:</b> 2026/Oct/30. View change history</td><td><b>Music ID Number:</b> Mutopia-2026/10/30-$id</td></tr>
<tr><td><b>Typeset using:</b> LilyPond, version 2.18.2</td><td></td></tr>
</tbody></table>
<table class="table table-bordered result-table"><tbody>
<tr><td><b>Download:</b></td></tr>
<tr><td><a href="$lily">LilyPond file</a></td><td>MIDI file</td></tr>
</tbody></table></body></html>''';
}

ProviderTransport _transport(
  FutureOr<http.Response> Function(http.Request request) handler,
) => ProviderTransport(
  client: MockClient((request) async => await handler(request)),
  maxRetries: 0,
  hostInterval: Duration.zero,
);

http.Response _response(String body) => http.Response(
  body,
  200,
  headers: const {'content-type': 'text/html; charset=utf-8'},
);

String _pathFor(String id) =>
    'https://www.mutopiaproject.org/ftp/Example/$id/Work$id.ly';

void main() {
  for (final allBlank in [false, true]) {
    test(
      'blank lyric placeholders are unavailable, not selectable ($allBlank)',
      () async {
        final transport = _transport(
          (request) => _response(
            request.url.path.endsWith('make-table.cgi')
                ? _searchPage([
                    _searchRow(
                      id: '101',
                      title: 'Bright River',
                      composer: 'A. Example',
                      lilypondUrl: _pathFor('101'),
                    ),
                  ])
                : _lilypond(
                    id: '101',
                    title: 'Bright River',
                    firstLyrics: '__ _',
                    secondLyrics: allBlank ? '__' : 'silver river',
                  ),
          ),
        );
        addTearDown(transport.close);
        final candidates = await MutopiaProvider(
          transport,
        ).search('Bright River');
        expect(
          candidates.map((candidate) => candidate.id),
          allBlank ? isEmpty : ['101:secondLyrics'],
        );
      },
    );
  }

  test(
    'explicit vocal rows precede instrumental rows within request budget',
    () async {
      final fetched = <String>[];
      final transport = _transport((request) {
        if (request.url.path.endsWith('make-table.cgi')) {
          return _response(
            _searchPage([
              for (final id in ['101', '102', '103'])
                _searchRow(
                  id: id,
                  title: 'Bright River',
                  composer: 'A. Example',
                  lilypondUrl: _pathFor(id),
                  instrument: 'Piano',
                ),
              _searchRow(
                id: '104',
                title: 'Bright River',
                composer: 'A. Example',
                lilypondUrl: _pathFor('104'),
              ),
            ]),
          );
        }
        final id = request.url.pathSegments[2];
        fetched.add(id);
        return _response(
          _lilypond(
            id: id,
            title: 'Bright River',
            firstLyrics: id == '104' ? 'silver river' : '__',
            secondLyrics: '__',
          ),
        );
      });
      addTearDown(transport.close);
      final candidates = await MutopiaProvider(
        transport,
      ).search('Bright River');
      expect(candidates.single.id, '104:firstLyrics');
      expect(fetched.first, '104');
      expect(fetched, hasLength(3));
    },
  );
  test('undocumented byte encodings are rejected instead of guessed', () async {
    final transport = _transport((_) => http.Response.bytes([0x80], 200));
    addTearDown(transport.close);
    await expectLater(
      MutopiaProvider(transport).search('Bright River'),
      throwsA(
        isA<ProviderException>().having(
          (error) => error.code,
          'code',
          'invalid_response',
        ),
      ),
    );
  });
  test('definition is opt-in and restricted to public-domain text', () {
    final transport = _transport((_) => _response(''));
    addTearDown(transport.close);
    final definition = MutopiaProvider(transport).definition;
    expect(definition.id, 'mutopia');
    expect(definition.capabilities, {'catalog', 'lyrics', 'metadata'});
    expect(definition.enabledByDefault, isFalse);
    expect(definition.accessMode, 'publicDomainText');
  });

  test(
    'search retains each named stream as its own score-edition candidate',
    () async {
      final firstUrl = _pathFor('101');
      final secondUrl = _pathFor('102');
      final rows = [
        _searchRow(
          id: '101',
          title: 'Bright River',
          composer: 'A. Example',
          lilypondUrl: firstUrl,
        ),
        _searchRow(
          id: '102',
          title: 'Quiet Morning',
          composer: 'A. Example',
          lilypondUrl: secondUrl,
        ),
      ];
      final requests = <Uri>[];
      final transport = _transport((request) {
        requests.add(request.url);
        if (request.url.path == '/cgibin/make-table.cgi') {
          return _response(_searchPage(rows));
        }
        if (request.url == Uri.parse(firstUrl)) {
          return _response(
            _lilypond(id: '101', title: 'Bright River', thirdStream: false),
          );
        }
        if (request.url == Uri.parse(secondUrl)) {
          return _response(
            _lilypond(
              id: '102',
              title: 'Quiet Morning',
              firstLyrics: 'soft light',
              thirdStream: true,
            ),
          );
        }
        fail('unexpected request ${request.url}');
      });
      addTearDown(transport.close);

      final found = await MutopiaProvider(transport).search('Bright River');
      expect(found.map((c) => c.id), [
        '101:firstLyrics',
        '101:secondLyrics',
        '102:firstLyrics',
        '102:secondLyrics',
        '102:text',
      ]);
      expect(requests.first.path, '/cgibin/make-table.cgi');
      expect(requests.first.queryParameters, {'searchingfor': 'Bright River'});
      expect(requests.where((uri) => uri.path.endsWith('.ly')), hasLength(2));
      expect(found.first.metadata['identityScope'], 'arrangement');
      expect(found.first.metadata['artistCreditRole'], 'composer');
      expect(found.first.metadata['sourceVariantLabel'], 'firstLyrics');
      expect(found.first.metadata.containsKey('language'), isFalse);
      expect(found.first.recordingIds, isEmpty);
      expect(found.first.artist, 'Ada Example');
    },
  );

  test('search downloads at most three eligible editions', () async {
    final rows = <String>[];
    for (var id = 101; id <= 104; id++) {
      rows.add(
        _searchRow(
          id: '$id',
          title: 'Work $id',
          composer: 'A. Example',
          lilypondUrl: _pathFor('$id'),
        ),
      );
    }
    final downloaded = <String>[];
    final transport = _transport((request) {
      if (request.url.path == '/cgibin/make-table.cgi') {
        return _response(_searchPage(rows));
      }
      if (request.url.path.endsWith('.ly')) {
        final id = request.url.pathSegments[2];
        downloaded.add(id);
        return _response(_lilypond(id: id, title: 'Work $id'));
      }
      fail('unexpected request ${request.url}');
    });
    addTearDown(transport.close);
    final found = await MutopiaProvider(transport).search('Work');
    expect(downloaded, ['101', '102', '103']);
    expect(found.map((c) => c.metadata['mutopiaEditionId']).toSet(), {
      '101',
      '102',
      '103',
    });
  });

  test('publisher initials match all corresponding name components', () async {
    final purcellUrl = _pathFor('103');
    final mozartUrl = _pathFor('104');
    final transport = _transport((request) {
      if (request.url.path == '/cgibin/make-table.cgi') {
        return _response(
          _searchPage([
            _searchRow(
              id: '103',
              title: 'Candle Song',
              composer: 'H. Purcell (1658–1695)',
              lilypondUrl: purcellUrl,
            ),
            _searchRow(
              id: '104',
              title: 'Cloud Song',
              composer: 'W. A. Mozart (1756–1791)',
              lilypondUrl: mozartUrl,
            ),
          ]),
        );
      }
      if (request.url == Uri.parse(purcellUrl)) {
        return _response(
          _lilypond(
            id: '103',
            title: 'Candle Song',
            composer: 'Henry Purcell (1659-1695)',
          ),
        );
      }
      if (request.url == Uri.parse(mozartUrl)) {
        return _response(
          _lilypond(
            id: '104',
            title: 'Cloud Song',
            composer: 'Wolfgang Amadeus Mozart (1756-1791)',
          ),
        );
      }
      if (request.url.path == '/cgibin/piece-info.cgi' &&
          request.url.queryParameters['id'] == '103') {
        return _response(
          _detailPage(
            id: '103',
            title: 'Candle Song',
            composer: 'H. Purcell (1658–1695)',
            lilypondUrl: purcellUrl,
          ),
        );
      }
      fail('unexpected request ${request.url}');
    });
    addTearDown(transport.close);
    final found = await MutopiaProvider(transport).search('Example');
    expect(found.map((c) => c.metadata['mutopiaEditionId']).toSet(), {
      '103',
      '104',
    });
    final purcell = found.firstWhere(
      (c) => c.metadata['mutopiaEditionId'] == '103',
    );
    expect(purcell.metadata['searchComposer'], 'H. Purcell (1658–1695)');
    expect(purcell.metadata['composer'], 'Henry Purcell (1659-1695)');
    final result = await MutopiaProvider(transport).resolve(purcell);
    expect(result.metadata['detailComposer'], 'H. Purcell (1658–1695)');
    expect(result.metadata['composer'], 'Henry Purcell (1659-1695)');
  });

  for (final aliases in [
    ('Johann Sebastian Bach', 'Johann Christoph Bach'),
    ('Henry Purcell', 'Harry Purcell'),
  ]) {
    test(
      'composer matching rejects full-name aliases: ${aliases.$1}',
      () async {
        final lilyUrl = _pathFor('105');
        final transport = _transport((request) {
          if (request.url.path == '/cgibin/make-table.cgi') {
            return _response(
              _searchPage([
                _searchRow(
                  id: '105',
                  title: 'Invented Work',
                  composer: aliases.$1,
                  lilypondUrl: lilyUrl,
                ),
              ]),
            );
          }
          if (request.url == Uri.parse(lilyUrl)) {
            return _response(
              _lilypond(
                id: '105',
                title: 'Invented Work',
                composer: aliases.$2,
              ),
            );
          }
          fail('unexpected request ${request.url}');
        });
        addTearDown(transport.close);
        await expectLater(
          MutopiaProvider(transport).search('Invented Work'),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.code,
              'code',
              'extraction_failed',
            ),
          ),
        );
      },
    );
  }

  test(
    'empty search is recognized while an unknown layout is rejected',
    () async {
      final emptyTransport = _transport((_) => _response(_emptySearch()));
      addTearDown(emptyTransport.close);
      expect(await MutopiaProvider(emptyTransport).search('missing'), isEmpty);

      final brokenTransport = _transport(
        (_) => _response('<html><body>changed</body></html>'),
      );
      addTearDown(brokenTransport.close);
      await expectLater(
        MutopiaProvider(brokenTransport).search('missing'),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'extraction_failed',
          ),
        ),
      );
    },
  );

  test(
    'non-public-domain listing rows are omitted before source fetch',
    () async {
      final requests = <Uri>[];
      final transport = _transport((request) {
        requests.add(request.url);
        return _response(
          _searchPage([
            _searchRow(
              id: '101',
              title: 'Private Edition',
              composer: 'A. Example',
              lilypondUrl: _pathFor('101'),
              license: 'Unknown',
            ),
          ]),
        );
      });
      addTearDown(transport.close);
      expect(
        await MutopiaProvider(transport).search('Private Edition'),
        isEmpty,
      );
      expect(requests, hasLength(1));
    },
  );

  for (final badUrl in [
    'https://attacker.example/ftp/Example/Work.ly',
    'https://www.mutopiaproject.org/ftp/Example%2fWork.ly',
    'https://www.mutopiaproject.org:444/ftp/Example/Work.ly',
    'https://user@www.mutopiaproject.org/ftp/Example/Work.ly',
    'https://www.mutopiaproject.org/ftp/../Work.ly',
    'https://www.mutopiaproject.org/ftp/Example/Work.ly?download=1',
  ]) {
    test('untrusted LilyPond URL is refused: $badUrl', () async {
      final transport = _transport(
        (_) => _response(
          _searchPage([
            _searchRow(
              id: '101',
              title: 'Bright River',
              composer: 'A. Example',
              lilypondUrl: badUrl,
            ),
          ]),
        ),
      );
      addTearDown(transport.close);
      await expectLater(
        MutopiaProvider(transport).search('Bright River'),
        throwsA(isA<ProviderException>()),
      );
    });
  }

  test(
    'duplicate edition IDs fail instead of selecting a conflicting row',
    () async {
      final transport = _transport(
        (_) => _response(
          _searchPage([
            _searchRow(
              id: '101',
              title: 'Bright River',
              composer: 'A. Example',
              lilypondUrl: _pathFor('101'),
            ),
            _searchRow(
              id: '101',
              title: 'Different Work',
              composer: 'A. Example',
              lilypondUrl: _pathFor('101'),
            ),
          ]),
        ),
      );
      addTearDown(transport.close);
      await expectLater(
        MutopiaProvider(transport).search('Bright River'),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'extraction_failed',
          ),
        ),
      );
    },
  );

  test('oversized identity text is rejected instead of truncated', () async {
    final oversizedTitle = List.filled(301, 'A').join();
    final transport = _transport(
      (_) => _response(
        _searchPage([
          _searchRow(
            id: '101',
            title: oversizedTitle,
            composer: 'A. Example',
            lilypondUrl: _pathFor('101'),
          ),
        ]),
      ),
    );
    addTearDown(transport.close);
    await expectLater(
      MutopiaProvider(transport).search('Bright River'),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.code,
          'code',
          'invalid_response',
        ),
      ),
    );
  });

  for (final badId in ['01', '../101', '101&other=1', '101%2f102']) {
    test('non-canonical More Information ID is refused: $badId', () async {
      final row = _searchRow(
        id: badId,
        title: 'Bright River',
        composer: 'A. Example',
        lilypondUrl: _pathFor('101'),
      );
      final transport = _transport((_) => _response(_searchPage([row])));
      addTearDown(transport.close);
      await expectLater(
        MutopiaProvider(transport).search('Bright River'),
        throwsA(isA<ProviderException>()),
      );
    });
  }

  test(
    'resolve ignores caller URL and binds only the requested literal stream',
    () async {
      final lilyUrl = _pathFor('101');
      final seen = <Uri>[];
      final transport = _transport((request) {
        seen.add(request.url);
        if (request.url.path == '/cgibin/make-table.cgi') {
          return _response(
            _searchPage([
              _searchRow(
                id: '101',
                title: 'Bright River',
                composer: 'A. Example',
                lilypondUrl: lilyUrl,
              ),
            ]),
          );
        }
        if (request.url == Uri.parse(lilyUrl)) {
          return _response(
            _lilypond(
              id: '101',
              title: 'Bright River',
              firstLyrics: '"bright [moon]" "hash#mark" "brace{value}"',
            ),
          );
        }
        if (request.url.path == '/cgibin/piece-info.cgi') {
          return _response(
            _detailPage(id: '101', title: 'Bright River', lilypondUrl: lilyUrl),
          );
        }
        fail('unexpected request ${request.url}');
      });
      addTearDown(transport.close);
      final provider = MutopiaProvider(transport);
      final candidates = await provider.search('Bright River');
      final original = candidates.first;
      final forged = SongCandidate(
        providerId: original.providerId,
        id: original.id,
        title: original.title,
        artist: original.artist,
        url: 'https://attacker.example/lyric',
        metadata: {'language': 'fr', 'key': 'G', 'tempo': 220},
        recordingIds: {'isrc': 'invented'},
      );
      final result = await provider.resolve(forged);

      expect(result.id, 'mutopia:101:firstLyrics');
      expect(result.body, r'bright \[moon\] hash\#mark brace\{value\}');
      expect(result.body, isNot(contains('silver river')));
      expect(result.candidate.metadata['sourceVariantLabel'], 'firstLyrics');
      expect(result.matchKind, MatchKind.sameSong);
      expect(result.matchKind, isNot(MatchKind.sameRecording));
      expect(result.timingTracks, isEmpty);
      expect(result.hasChords, isFalse);
      expect(result.metadata.containsKey('language'), isFalse);
      expect(result.metadata.containsKey('key'), isFalse);
      expect(result.metadata.containsKey('tempo'), isFalse);
      expect(result.candidate.recordingIds, isEmpty);
      expect(seen.any((uri) => uri.host == 'attacker.example'), isFalse);
      expect(
        seen.where((uri) => uri.path == '/cgibin/piece-info.cgi'),
        hasLength(1),
      );
      expect(result.extra['mutopia']['streams'], hasLength(2));
      expect(
        result.extra['mutopia']['streams'][0]['publisherVariable'],
        'firstLyrics',
      );
      expect(
        result.extra['mutopia']['streams'][0]['attachmentVerified'],
        isFalse,
      );
      expect(result.extra['mutopia']['streams'][0]['text'], contains('[moon]'));
      expect(
        result.extra['mutopia']['streams'][1]['publisherVariable'],
        'secondLyrics',
      );
      expect(result.extra['rights']['sourceId'], '101');
      expect(result.extra['rights']['license'], 'Public Domain');
      expect(
        result.extra['rights']['permissions']['scope'],
        contains('edition'),
      );
    },
  );

  test(
    'resolve rejects candidate identity mismatch before fetching LilyPond',
    () async {
      final lilyUrl = _pathFor('101');
      final seen = <Uri>[];
      final transport = _transport((request) {
        seen.add(request.url);
        if (request.url.path == '/cgibin/make-table.cgi') {
          return _response(
            _searchPage([
              _searchRow(
                id: '101',
                title: 'Bright River',
                composer: 'A. Example',
                lilypondUrl: lilyUrl,
              ),
            ]),
          );
        }
        if (request.url == Uri.parse(lilyUrl)) {
          return _response(_lilypond(id: '101', title: 'Bright River'));
        }
        if (request.url.path == '/cgibin/piece-info.cgi') {
          return _response(
            _detailPage(id: '101', title: 'Other Work', lilypondUrl: lilyUrl),
          );
        }
        fail('unexpected request ${request.url}');
      });
      addTearDown(transport.close);
      final provider = MutopiaProvider(transport);
      final candidate = (await provider.search('Bright River')).first;
      await expectLater(
        provider.resolve(
          SongCandidate(
            providerId: candidate.providerId,
            id: candidate.id,
            title: candidate.title,
            artist: candidate.artist,
          ),
        ),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'identity_mismatch',
          ),
        ),
      );
      expect(seen.where((uri) => uri.path.endsWith('.ly')), hasLength(1));
    },
  );

  test(
    'resolve rejects overlong publisher stream identifiers before fetching',
    () async {
      var requests = 0;
      final transport = _transport((_) {
        requests++;
        return _response('');
      });
      addTearDown(transport.close);
      final overlongVariable = List.filled(65, 'a').join();
      await expectLater(
        MutopiaProvider(transport).resolve(
          SongCandidate(
            providerId: 'mutopia',
            id: '101:$overlongVariable',
            title: 'Bright River',
            artist: 'Ada Example',
          ),
        ),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.code,
            'code',
            'user_selection_required',
          ),
        ),
      );
      expect(requests, 0);
    },
  );

  test('detail, header, footer and publisher license must agree', () async {
    for (final scenario in [
      (
        'wrong footer',
        'Mutopia-2026/10/30-102',
        'Public Domain',
        'Public Domain',
      ),
      (
        'wrong header title',
        'Mutopia-2026/10/30-101',
        'Public Domain',
        'Public Domain',
      ),
      (
        'unknown header license',
        'Mutopia-2026/10/30-101',
        'Unknown',
        'Public Domain',
      ),
      (
        'unknown detail license',
        'Mutopia-2026/10/30-101',
        'Public Domain',
        'Unknown',
      ),
    ]) {
      final lilyUrl = _pathFor('101');
      var resolving = false;
      final transport = _transport((request) {
        if (request.url.path == '/cgibin/make-table.cgi') {
          return _response(
            _searchPage([
              _searchRow(
                id: '101',
                title: 'Bright River',
                composer: 'A. Example',
                lilypondUrl: lilyUrl,
              ),
            ]),
          );
        }
        if (request.url == Uri.parse(lilyUrl)) {
          final title = resolving && scenario.$1 == 'wrong header title'
              ? 'Wrong Title'
              : 'Bright River';
          return _response(
            _lilypond(
              id: resolving && scenario.$2.endsWith('102') ? '102' : '101',
              title: title,
              license: resolving ? scenario.$3 : 'Public Domain',
            ),
          );
        }
        if (request.url.path == '/cgibin/piece-info.cgi') {
          return _response(
            _detailPage(
              id: '101',
              title: 'Bright River',
              license: scenario.$4,
              lilypondUrl: lilyUrl,
            ),
          );
        }
        fail('unexpected request ${request.url}');
      });
      addTearDown(transport.close);
      final provider = MutopiaProvider(transport);
      final candidate = (await provider.search('Bright River')).first;
      resolving = true;
      await expectLater(
        provider.resolve(candidate),
        throwsA(isA<ProviderException>()),
      );
    }
  });

  test(
    'original HTML and LilyPond response bytes are hashed and retained',
    () async {
      final lilyUrl = _pathFor('101');
      final detail = _detailPage(
        id: '101',
        title: 'Bright River',
        lilypondUrl: lilyUrl,
      );
      final lily = _lilypond(id: '101', title: 'Bright River');
      final transport = _transport((request) {
        if (request.url.path == '/cgibin/make-table.cgi') {
          return _response(
            _searchPage([
              _searchRow(
                id: '101',
                title: 'Bright River',
                composer: 'A. Example',
                lilypondUrl: lilyUrl,
              ),
            ]),
          );
        }
        if (request.url == Uri.parse(lilyUrl)) return _response(lily);
        if (request.url.path == '/cgibin/piece-info.cgi') {
          return _response(detail);
        }
        fail('unexpected request ${request.url}');
      });
      addTearDown(transport.close);
      final provider = MutopiaProvider(transport);
      final candidate = (await provider.search('Bright River')).first;
      final result = await provider.resolve(candidate);
      final payloads = result.extra['originalPayloads'] as List;
      expect(payloads, hasLength(2));
      final htmlPayload = payloads[0] as Map;
      final lilyPayload = payloads[1] as Map;
      final htmlBytes = base64Decode(htmlPayload['base64'] as String);
      final lilyBytes = base64Decode(lilyPayload['base64'] as String);
      expect(utf8.decode(htmlBytes), detail);
      expect(utf8.decode(lilyBytes), lily);
      expect(htmlPayload['sha256'], sha256.convert(htmlBytes).toString());
      expect(lilyPayload['sha256'], sha256.convert(lilyBytes).toString());
      expect(htmlPayload['contentType'], 'text/html');
      expect(lilyPayload['contentType'], 'text/x-lilypond');
      expect(htmlPayload['httpBodyBytesExact'], isTrue);
      expect(htmlPayload['wireExact'], isFalse);
    },
  );

  test(
    'cancelled searches and resolutions stop before further requests',
    () async {
      var requests = 0;
      final transport = _transport((_) {
        requests++;
        return _response(_emptySearch());
      });
      addTearDown(transport.close);
      final provider = MutopiaProvider(transport);
      final searchToken = CancellationToken()..cancel();
      await expectLater(
        provider.search('Bright River', cancel: searchToken),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      expect(requests, 0);
      final resolveToken = CancellationToken()..cancel();
      await expectLater(
        provider.resolve(
          const SongCandidate(
            providerId: 'mutopia',
            id: '101:firstLyrics',
            title: 'Bright River',
            artist: 'Ada Example',
          ),
          cancel: resolveToken,
        ),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      expect(requests, 0);
    },
  );

  test(
    'cancellation during the source fetch prevents candidate projection',
    () async {
      final token = CancellationToken();
      final lilyUrl = _pathFor('101');
      final transport = _transport((request) {
        if (request.url.path == '/cgibin/make-table.cgi') {
          return _response(
            _searchPage([
              _searchRow(
                id: '101',
                title: 'Bright River',
                composer: 'A. Example',
                lilypondUrl: lilyUrl,
              ),
            ]),
          );
        }
        if (request.url == Uri.parse(lilyUrl)) {
          token.cancel();
          return _response(_lilypond(id: '101', title: 'Bright River'));
        }
        fail('unexpected request ${request.url}');
      });
      addTearDown(transport.close);
      await expectLater(
        MutopiaProvider(transport).search('Bright River', cancel: token),
        throwsA(
          isA<ProviderException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
    },
  );

  test('large search response is rejected by transport bounds', () async {
    final oversized = List.filled(512 * 1024 + 1, 'x').join();
    final transport = _transport((_) => http.Response(oversized, 200));
    addTearDown(transport.close);
    await expectLater(
      MutopiaProvider(transport).search('Bright River'),
      throwsA(isA<ProviderException>()),
    );
  });
}
