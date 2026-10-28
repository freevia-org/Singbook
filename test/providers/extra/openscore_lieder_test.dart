import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/openscore_lieder.dart';
import 'package:singbook/providers/provider.dart';

const _hash =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _lyrics = 'Morning light across the sea,\nQuiet evening welcomes me.\n';

String _row({
  String id = '123',
  String title = 'A Test Song',
  String composer = 'Writer, Example',
  String? link,
}) =>
    '''
<tr><td>$composer</td><td>Example cycle</td><td>$title</td>
<td>A Poet</td><td>EN</td><td>
<a href="${link ?? 'https://raw.githubusercontent.com/OpenScore/Lieder/refs/heads/main/scores/Writer%2C_Example/Example_cycle/A_Test_Song/lc$id.mscz?raw=true'}">MuseScore</a>
</td><td><a href="https://musescore.com/score/$id">External</a></td></tr>''';

String _index([String? rows]) => '''<html><table id="catalogue"><thead><tr>
<th>Composer</th><th>Set</th><th>Song</th><th>Lyricist</th>
<th>Language</th><th>Score</th><th>External</th></tr></thead>
<tbody>${rows ?? _row()}</tbody></table></html>''';

ProviderTransport _transport(
  FutureOr<http.Response> Function(http.Request) handler,
) => ProviderTransport(
  client: MockClient((request) async => await handler(request)),
  maxRetries: 0,
  hostInterval: Duration.zero,
);

void main() {
  test(
    'catalog keeps composer/lyricist roles and cycle without invented recording',
    () {
      final c = OpenScoreLiederProvider.parseCatalog(
        _index(),
        indexSha256: _hash,
      ).single;
      expect(c.id, '123');
      expect(c.title, 'A Test Song');
      expect(c.metadata['identityScope'], 'composition');
      expect(c.metadata['artistCreditRole'], 'composer');
      expect(c.metadata['credits'], [
        {'role': 'Composer', 'name': 'Writer, Example'},
        {'role': 'Lyricist', 'name': 'A Poet'},
      ]);
      expect(c.metadata['sourceWorkSet'], 'Example cycle');
      expect(c.metadata['openScoreCatalogFields']['lyricist'], 'A Poet');
      expect(c.metadata['openScoreReferences'], hasLength(2));
      expect(c.album, isNull);
      expect(c.recordingIds, isEmpty);
      expect(c.metadata['openScoreTextPath'], endsWith('/lc123.txt'));
      expect(Uri.parse(c.url!).fragment, isEmpty);
    },
  );

  test(
    'catalog accepts both publisher ref forms and coalesces matching score links',
    () {
      final row = _row().replaceFirst(
        '</td><td><a href=',
        '<a href="https://raw.githubusercontent.com/OpenScore/Lieder/main/scores/Writer%2C_Example/Example_cycle/A_Test_Song/lc123.mxl?raw=true">XML</a></td><td><a href=',
      );
      expect(
        OpenScoreLiederProvider.parseCatalog(_index(row), indexSha256: _hash),
        hasLength(1),
      );
    },
  );

  test(
    'conflicting same-ID rows are omitted instead of choosing the first',
    () {
      final rows = _row() + _row(title: 'Different work') + _row(id: '456');
      final found = OpenScoreLiederProvider.parseCatalog(
        _index(rows),
        indexSha256: _hash,
      );
      expect(found.map((c) => c.id), ['456']);
    },
  );

  for (final bad in [
    'https://evil.example/OpenScore/Lieder/main/scores/a/b/c/lc123.mscz?raw=true',
    'https://raw.githubusercontent.com/Other/Lieder/main/scores/a/b/c/lc123.mscz?raw=true',
    'https://raw.githubusercontent.com/OpenScore/Lieder/main/scores/a/b/c/lc0.mscz?raw=true',
    'https://raw.githubusercontent.com/OpenScore/Lieder/main/scores/a/b%2Fc/d/lc123.mscz?raw=true',
    'https://raw.githubusercontent.com/OpenScore/Lieder/main/scores/a/%FF/c/lc123.mscz?raw=true',
    'https://raw.githubusercontent.com/OpenScore/Lieder/main/scores/a/b/c/lc123.mscz?raw=true&raw=true',
    'https://raw.githubusercontent.com/OpenScore/Lieder/main/scores/a/b/c/lc123.mscz?raw=true#fragment',
  ]) {
    test('untrusted score reference is not made into a lyric target: $bad', () {
      final found = OpenScoreLiederProvider.parseCatalog(
        _index(_row(link: bad) + _row(id: '456')),
        indexSha256: _hash,
      );
      expect(found.map((c) => c.id), ['456']);
    });
  }

  test(
    'search and two resolves reuse one index and never download score/media',
    () async {
      final seen = <Uri>[];
      final transport = _transport((req) {
        seen.add(req.url);
        return http.Response(
          req.url.path.endsWith('/index.html')
              ? _index(_row() + _row(id: '456', title: 'Another Test Song'))
              : _lyrics,
          200,
        );
      });
      addTearDown(transport.close);
      final provider = OpenScoreLiederProvider(transport);
      final hits = await provider.search('Test Song');
      for (final hit in hits) {
        final result = await provider.resolve(hit);
        expect(result.body, _lyrics.trim());
        expect(result.metadata, hit.metadata);
        expect(result.timingTracks, isEmpty);
        expect(result.hasChords, isFalse);
        expect(
          result.extra['originalPayload']['base64'],
          base64Encode(utf8.encode(_lyrics)),
        );
        expect(result.extra['originalPayload']['httpBodyBytesExact'], isTrue);
        expect(
          result.extra['rights']['permissions']['status'],
          'source_declared_underlying_rights_unverified',
        );
      }
      expect(seen, hasLength(3));
      expect(seen.every((u) => u.host == 'raw.githubusercontent.com'), isTrue);
      expect(seen.skip(1).every((u) => u.path.endsWith('.txt')), isTrue);
      expect((await provider.search('A Poet')), hasLength(2));
      expect(seen, hasLength(3));
    },
  );

  test(
    'resolve uses canonical catalog facts, ignoring forged URL and recording metadata',
    () async {
      final seen = <Uri>[];
      final transport = _transport((req) {
        seen.add(req.url);
        return http.Response(
          req.url.path.endsWith('/index.html') ? _index() : _lyrics,
          200,
        );
      });
      addTearDown(transport.close);
      final result = await OpenScoreLiederProvider(transport).resolve(
        const SongCandidate(
          providerId: 'openscorelieder',
          id: '123',
          title: 'A Test Song',
          artist: 'Writer, Example',
          url: 'https://evil.example/lyric',
          album: 'Invented album',
          durationSeconds: 9,
          recordingIds: {'isrc': 'invented'},
          metadata: {'tempo': 180, 'openScoreTextPath': '../evil.txt'},
        ),
      );
      expect(seen.last.path, endsWith('/A_Test_Song/lc123.txt'));
      expect(result.candidate.recordingIds, isEmpty);
      expect(result.candidate.album, isNull);
      expect(result.candidate.durationSeconds, isNull);
      expect(result.metadata.containsKey('tempo'), isFalse);
    },
  );

  test('mismatching title fails before a lyric request', () async {
    var requests = 0;
    final transport = _transport((req) {
      requests++;
      return http.Response(_index(), 200);
    });
    addTearDown(transport.close);
    await expectLater(
      OpenScoreLiederProvider(transport).resolve(
        const SongCandidate(
          providerId: 'openscorelieder',
          id: '123',
          title: 'Other title',
          artist: 'Writer, Example',
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
    expect(requests, 1);
  });

  test(
    'a foreign selection cannot trigger speculative automatic lookup',
    () async {
      final transport = _transport(
        (req) => throw StateError('unexpected request'),
      );
      addTearDown(transport.close);
      await expectLater(
        OpenScoreLiederProvider(transport).resolve(
          const SongCandidate(
            providerId: 'other',
            id: '123',
            title: 'A Test Song',
            artist: 'Writer, Example',
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
    },
  );

  test(
    'ordinary matcher accepts own selected composition but never as a recording',
    () async {
      final transport = _transport(
        (req) => http.Response(
          req.url.path.endsWith('/index.html') ? _index() : _lyrics,
          200,
        ),
      );
      addTearDown(transport.close);
      final provider = OpenScoreLiederProvider(transport);
      final selected = (await provider.search('A Test Song')).single;
      final result = await findMatchingSource(provider, selected);
      expect(result.matchKind, MatchKind.sameSong);
      expect(result.candidate.recordingIds, isEmpty);
    },
  );

  test('HTML and invalid UTF8 cannot pass as plaintext lyrics', () async {
    for (final bad in [
      utf8.encode('<html><body>not a lyric</body></html>'),
      [0xc3, 0x28],
    ]) {
      final transport = _transport(
        (req) => req.url.path.endsWith('/index.html')
            ? http.Response(_index(), 200)
            : http.Response.bytes(bad, 200),
      );
      final provider = OpenScoreLiederProvider(transport);
      final selected = (await provider.search('A Test Song')).single;
      await expectLater(
        provider.resolve(selected),
        throwsA(isA<ProviderException>()),
      );
      await transport.close();
    }
  });

  test('changed catalog header is an extraction failure', () {
    expect(
      () => OpenScoreLiederProvider.parseCatalog(
        _index().replaceFirst('<th>Composer</th>', '<th>Performer</th>'),
        indexSha256: _hash,
      ),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.code,
          'code',
          'extraction_failed',
        ),
      ),
    );
  });

  test(
    'literal bracket/directive/comment-looking lyric lines remain text',
    () async {
      const text =
          '[Chorus]\n{x_verse: a literal poem line}\n# A literal hash line\n[C] A literal chord-shaped word\n';
      final transport = _transport(
        (req) => http.Response(
          req.url.path.endsWith('/index.html') ? _index() : text,
          200,
        ),
      );
      addTearDown(transport.close);
      final provider = OpenScoreLiederProvider(transport);
      final selected = (await provider.search('A Test Song')).single;
      final result = await provider.resolve(selected);
      expect(plainLyrics(result.body), text.trim());
      expect(result.hasChords, isFalse);
      expect(result.body, isNot(contains('{comment:')));
    },
  );

  test(
    'cancellation after response is surfaced and leaves no cached catalog',
    () async {
      var calls = 0;
      final token = CancellationToken();
      final transport = _transport((req) {
        calls++;
        if (calls == 1) token.cancel();
        return http.Response(_index(), 200);
      });
      addTearDown(transport.close);
      final provider = OpenScoreLiederProvider(transport);
      await expectLater(
        provider.search('Test', cancel: token),
        throwsA(isA<ProviderException>()),
      );
      expect(await provider.search('Test'), hasLength(1));
      expect(calls, 2);
    },
  );
}
