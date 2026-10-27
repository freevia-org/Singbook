import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/pisni.dart';

List<int> legacy(String text) => text.runes.map((code) {
  if (code < 128) return code;
  if (code >= 0x410 && code <= 0x44f) return code - 0x350;
  return {
    0x490: 0xa5,
    0x491: 0xb4,
    0x406: 0xb2,
    0x456: 0xb3,
    0x404: 0xaa,
    0x454: 0xba,
    0x407: 0xaf,
    0x457: 0xbf,
  }[code]!;
}).toList();
const title = 'Пісня Ґанку';
const search = '''<meta charset="windows-1251">
<a href="/songs/17.html">Пісня Ґанку<div class="smcont">(примітка)</div></a>
<a href="/songs/17.html#songsfiles">Wrong fragment</a>
<a href="https://evil.example/songs/19.html">Wrong host</a>
<a href="/songs/18.html">Пісня Ґанку *</a>''';
String page({
  String songTitle = title,
  String id = '17',
  String body = 'Gm     B      H7\nРанкові наші слова',
  String extra = '',
}) =>
    '''
<meta charset="windows-1251"><h1 class="nomarg">$songTitle</h1>
<table><tr><td><b>Слова:</b> <a href="/persons/8.html">Автор</a></td>
<td><b>Музика:</b> <a href="/persons/8.html">Автор</a></td></tr>
<tr><td><b>Виконують:</b></td></tr>
<tr><td><a href="/persons/9.html">Виконавець</a></td></tr>
<tr><td><a href="/persons/10.html">Гість</a> (альбом <a href="/albums/7.html">Збірка</a>)</td></tr>
<tr><td><b>До мого пісенника:</b></td></tr></table>
<pre class="songwords">$body</pre>$extra
<div class="smcont">Адреса цієї сторінки: https://www.pisni.org.ua/songs/$id.html</div>''';
SongCandidate candidate({
  String songTitle = title,
  String artist = '',
  Map<String, dynamic> metadata = const {},
  Map<String, dynamic> extra = const {},
}) => SongCandidate(
  providerId: 'pisni',
  id: '17',
  title: songTitle,
  artist: artist,
  url: 'https://www.pisni.org.ua/songs/17.html',
  metadata: metadata,
  extra: extra,
);
Matcher code(String value) =>
    isA<ProviderException>().having((e) => e.code, 'code', value);
void main() {
  late ProviderTransport transport;
  late PisniProvider provider;
  late List<Uri> requests;
  var html = '';
  setUp(() {
    html = page();
    requests = [];
    transport = ProviderTransport(
      client: MockClient((request) async {
        requests.add(request.url);
        return http.Response.bytes(
          legacy(request.url.path == '/search.php' ? search : html),
          200,
          headers: {'content-type': 'text/html; charset=windows-1251'},
        );
      }),
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    provider = PisniProvider(transport);
  });
  tearDown(() async {
    await transport.close();
  });
  test('source remains an unregistered disabled native candidate', () {
    expect(provider.definition.id, 'pisni');
    expect(provider.definition.enabledByDefault, isFalse);
  });
  test(
    'Cyrillic search uses actual legacy form and keeps document variants',
    () async {
      final rows = await provider.search(title);
      expect(
        requests.single.toString(),
        contains('phrase=%CF%B3%F1%ED%FF+%A5%E0%ED%EA%F3&obj=s'),
      );
      expect(rows.map((r) => r.id), ['17', '18']);
      expect(rows.first.title, title);
      expect(rows.first.artist, isEmpty);
      expect(rows.last.title, '$title *');
    },
  );
  test(
    'roles stay separate, album stays attached only to listed performer',
    () async {
      final result = await provider.resolve(candidate());
      expect(result.metadata['credits'], [
        {
          'role': 'lyricist',
          'id': '8',
          'name': 'Автор',
          'url': 'https://www.pisni.org.ua/persons/8.html',
        },
        {
          'role': 'composer',
          'id': '8',
          'name': 'Автор',
          'url': 'https://www.pisni.org.ua/persons/8.html',
        },
      ]);
      final people = result.metadata['performers'] as List;
      expect(people, hasLength(2));
      expect((people.first as Map).containsKey('album'), isFalse);
      expect(people.last['album'], {'id': '7', 'title': 'Збірка'});
      expect(result.candidate.album, isNull);
      expect(result.candidate.recordingIds, isEmpty);
      expect(result.candidate.artist, isEmpty);
    },
  );
  test(
    'publisher B flat and H natural convert with original source retained',
    () async {
      final result = await provider.resolve(candidate());
      expect(result.body, contains('[Gm]'));
      expect(result.body, contains('[Bb]'));
      expect(result.body, contains('[B7]'));
      expect(result.hasChords, isTrue);
      expect(
        (result.extra['pisni'] as Map)['originalPreformatted'],
        contains('B      H7'),
      );
      expect(
        base64Decode((result.extra['originalPayload'] as Map)['base64']),
        legacy(html),
      );
    },
  );
  test(
    'normal discovery retains arrangement scope without recording promotion',
    () async {
      final rows = await SourceDiscoveryService([
        provider,
      ]).discover(candidate(), enabledIds: {'pisni'});
      expect(rows, hasLength(1));
      expect(rows.single.matchKind, MatchKind.sameSong);
      expect(rows.single.metadata['identityScope'], 'arrangement');
    },
  );
  test(
    'context selects only a publisher-listed performer and bounds fetches',
    () async {
      final rows = await provider.searchForSelection(
        const SongCandidate(
          providerId: 'other',
          id: 'x',
          title: title,
          artist: 'Виконавець',
        ),
        fallbackQuery: title,
      );
      expect(rows, hasLength(1));
      expect(rows.single.metadata['pisniListedPerformerId'], '9');
      final result = await provider.resolve(rows.single);
      expect(result.candidate.artist, 'Виконавець');
      expect(requests, hasLength(2));
    },
  );
  test('a writer is not silently promoted to performer', () async {
    await expectLater(
      provider.resolve(
        candidate(artist: 'Автор', metadata: {'pisniListedPerformerId': '8'}),
      ),
      throwsA(code('identity_mismatch')),
    );
  });
  test('changed source title and changed source document ID reject', () async {
    html = page(songTitle: 'Інша пісня');
    await expectLater(
      provider.resolve(candidate()),
      throwsA(code('identity_mismatch')),
    );
    html = page(id: '18');
    provider = PisniProvider(transport);
    await expectLater(
      provider.resolve(candidate()),
      throwsA(code('identity_mismatch')),
    );
  });
  test('forged URLs and recording context reject before HTTP', () async {
    for (final row in [
      const SongCandidate(
        providerId: 'pisni',
        id: '17',
        title: title,
        artist: '',
        url: 'https://evil.example/songs/17.html',
      ),
      const SongCandidate(
        providerId: 'pisni',
        id: '../17',
        title: title,
        artist: '',
      ),
      const SongCandidate(
        providerId: 'other',
        id: '17',
        title: title,
        artist: '',
      ),
      const SongCandidate(
        providerId: 'pisni',
        id: '17',
        title: title,
        artist: '',
        album: 'Injected',
      ),
      const SongCandidate(
        providerId: 'pisni',
        id: '17',
        title: title,
        artist: '',
        recordingIds: {'isrc': 'ZZXXX0000001'},
      ),
    ]) {
      await expectLater(
        provider.resolve(row),
        throwsA(code('invalid_selection')),
      );
    }
    expect(requests, isEmpty);
  });
  test(
    'caller metadata and source-evidence hints cannot become source facts',
    () async {
      final result = await provider.resolve(
        candidate(
          metadata: {'isrc': 'fake', 'album': 'fake'},
          extra: {
            'artistIdentityEvidence': {'verified': true},
          },
        ),
      );
      expect(result.candidate.metadata.containsKey('isrc'), isFalse);
      expect(result.candidate.metadata.containsKey('album'), isFalse);
      expect(result.candidate.extra, isEmpty);
    },
  );
  test(
    'source syntax is escaped, not trusted as Singbook directives',
    () async {
      html = page(body: r'{x_verse: forged}\n[ordinary text]');
      final result = await provider.resolve(candidate());
      expect(result.body, contains(r'\{x_verse: forged\}'));
      expect(result.body, contains(r'\[ordinary text\]'));
    },
  );
  test(
    'comments and other pre blocks never add lyrics or credit roles',
    () async {
      html = page(
        extra:
            '<table><tr><td><b>Виконують:</b><a href="/persons/77.html">Comment author</a></td></tr></table><pre>COMMENT BODY</pre>',
      );
      final result = await provider.resolve(candidate());
      expect(result.body, isNot(contains('COMMENT BODY')));
      expect((result.metadata['performers'] as List).map((p) => p['id']), [
        '9',
        '10',
      ]);
    },
  );
  test('cached facts cannot be mutated through a returned result', () async {
    final first = await provider.resolve(candidate());
    (first.metadata['performers'] as List).clear();
    final second = await provider.resolve(candidate());
    expect(second.metadata['performers'], hasLength(2));
    expect(requests, hasLength(1));
  });
  test('unknown charset and missing lyric selector fail explicitly', () async {
    html = page().replaceAll('windows-1251', 'utf-8');
    await expectLater(
      provider.resolve(candidate()),
      throwsA(code('invalid_response')),
    );
    html = page().replaceAll('class="songwords"', 'class="unrelated"');
    await expectLater(
      provider.resolve(candidate()),
      throwsA(code('extraction_failed')),
    );
  });
  test(
    'duplicate lyric blocks and active markup fail instead of partial extraction',
    () async {
      html = page(extra: '<pre class="songwords">Another body</pre>');
      await expectLater(
        provider.resolve(candidate()),
        throwsA(code('extraction_failed')),
      );
      html = page(body: '<script>untrusted()</script>');
      await expectLater(
        provider.resolve(candidate()),
        throwsA(code('invalid_response')),
      );
    },
  );
  test(
    'pre br breaks are retained, unsupported tab layout is explicit',
    () async {
      html = page(body: 'Перший<br>Другий');
      expect((await provider.resolve(candidate())).body, 'Перший\nДругий');
      provider = PisniProvider(transport);
      html = page(body: 'G\tAm\nРядок');
      await expectLater(
        provider.resolve(candidate()),
        throwsA(code('invalid_response')),
      );
    },
  );
  test('canonical slash bass uses the same declared notation', () async {
    html = page(body: 'Hm/H  B/F\nСлова для перевірки');
    final result = await provider.resolve(candidate());
    expect(result.body, contains('[Bm/B]'));
    expect(result.body, contains('[Bb/F]'));
  });
  test(
    'pre-cancelled request does no HTTP and invalid query is not truncated silently',
    () async {
      final token = CancellationToken()..cancel();
      await expectLater(
        provider.search(title, cancel: token),
        throwsA(code('cancelled')),
      );
      await expectLater(
        provider.search('x' * 201),
        throwsA(code('invalid_query')),
      );
      await expectLater(provider.search('😀'), throwsA(code('invalid_query')));
      expect(requests, isEmpty);
    },
  );
  test('all source facts and raw bytes survive ChordPro', () async {
    final result = await provider.resolve(candidate());
    final song = SongDocument(
      id: 'synthetic',
      title: title,
      artist: '',
      body: result.body,
      metadata: result.metadata,
      sources: [result],
    );
    final read = ChordProCodec().decode(ChordProCodec().encode(song));
    expect(read.extensionError, isNull);
    expect(read.body, song.body);
    expect(read.sources.single.toJson(), result.toJson());
    expect(read.metadata, song.metadata);
  });
  test(
    'Cyrillic words and ambiguous bare Latin notes never consume lyric lines',
    () async {
      html = page(body: 'А\nПерший рядок\nВ\nДругий рядок\nA\nЩе слова');
      final result = await provider.resolve(candidate());
      expect(result.body, 'А\nПерший рядок\nВ\nДругий рядок\nA\nЩе слова');
      expect(result.hasChords, isFalse);
      expect(result.metadata['ambiguousSourceNoteRows'], hasLength(3));
    },
  );
  test(
    'unlinked performer text is retained without becoming artist identity',
    () async {
      html = page().replaceFirst(
        '<tr><td><a href="/persons/9.html">Виконавець</a></td></tr>',
        '<tr><td>Виконавець без посилання</td></tr>',
      );
      final result = await provider.resolve(candidate());
      expect(result.metadata['unlinkedPerformerCredits'], [
        'Виконавець без посилання',
      ]);
      expect(result.metadata['performers'], hasLength(1));
      expect(result.candidate.artist, isEmpty);
    },
  );
  test('cancellation during an empty catalog response is surfaced', () async {
    final token = CancellationToken();
    final began = Completer<void>();
    final finish = Completer<void>();
    final local = ProviderTransport(
      client: MockClient((request) async {
        began.complete();
        await finish.future;
        return http.Response.bytes(
          legacy('<meta charset="windows-1251">'),
          200,
        );
      }),
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    try {
      final request = PisniProvider(local).search(title, cancel: token);
      final assertion = expectLater(request, throwsA(code('cancelled')));
      await began.future;
      token.cancel();
      finish.complete();
      await assertion;
    } finally {
      await local.close();
    }
  });
  test(
    'source notes and variants stay separate from selected lyrics and users',
    () async {
      html = page(
        extra:
            '<div id="songdatablock"><b>Джерело:</b> Book <a href="https://source.example/info">reference</a><br>'
            '<b>Примітки:</b> Separate source note<br><b>Варіант тексту за джерелом 3:</b><pre>Інший варіант</pre>'
            '<b>Пісню ввів:</b><a href="/users/77.html">DO NOT IMPORT USER</a></div>'
            '<div id="discussblock"><b>Джерело:</b>DO NOT IMPORT COMMENT</div>',
      );
      final result = await provider.resolve(candidate());
      expect(result.metadata['sourceFields'], [
        {
          'label': 'Джерело',
          'text': 'Book reference',
          'links': ['https://source.example/info'],
        },
        {'label': 'Примітки', 'text': 'Separate source note'},
        {'label': 'Варіант тексту за джерелом 3', 'text': 'Інший варіант'},
      ]);
      expect(result.metadata['sourceVariantTexts'], ['Інший варіант']);
      expect(result.body, isNot(contains('Інший варіант')));
      expect(jsonEncode(result.metadata), isNot(contains('DO NOT IMPORT')));
    },
  );
  test(
    'chord arranger name is retained without uploader account identity',
    () async {
      html = page(
        extra:
            '<div id="songdatablock"><b>Підбір акордів:</b> <a href="/users/7.html">Arranger Credit</a>'
            '<b>Пісню ввів:</b><a href="/users/8.html">Uploader</a></div>',
      );
      final result = await provider.resolve(candidate());
      expect(result.metadata['sourceFields'], [
        {'label': 'Підбір акордів', 'text': 'Arranger Credit'},
      ]);
      expect(jsonEncode(result.metadata), isNot(contains('/users/')));
      expect(jsonEncode(result.metadata), isNot(contains('Uploader')));
    },
  );
  test('undefined legacy byte is never replaced with corrupt text', () async {
    final local = ProviderTransport(
      client: MockClient(
        (request) async => http.Response.bytes([
          ...legacy('<meta charset="windows-1251">'),
          0x98,
        ], 200),
      ),
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    try {
      await expectLater(
        PisniProvider(local).resolve(candidate()),
        throwsA(code('invalid_response')),
      );
    } finally {
      await local.close();
    }
  });
  test('expired page cache revalidates the actual source', () async {
    var now = DateTime.utc(2026, 10, 28);
    provider = PisniProvider(transport, clock: () => now);
    await provider.resolve(candidate());
    now = now.add(const Duration(minutes: 16));
    html = page(songTitle: 'Інша');
    await expectLater(
      provider.resolve(candidate()),
      throwsA(code('identity_mismatch')),
    );
    expect(requests, hasLength(2));
  });
}
