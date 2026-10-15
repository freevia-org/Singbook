import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/application/pdf_font_face.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/models.dart';

Matcher formatError(String message) =>
    isA<FormatException>().having((e) => e.message, 'message', message);

/// Windows-1251 bytes for [text] (ASCII plus the Cyrillic letters A..ya).
Uint8List cp1251(String text) => Uint8List.fromList([
  for (final rune in text.runes)
    if (rune < 0x80)
      rune
    else if (rune >= 0x0410 && rune <= 0x044f)
      0xc0 + rune - 0x0410
    else
      throw ArgumentError('not in test table: $rune'),
]);

PdfFontFace monoFace() => PdfFontFace.parse(
  File('assets/fonts/NotoSansMono-Regular.ttf').readAsBytesSync(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('setlist detection is linear', () {
    test('many comments and no <set> finish immediately', () {
      final text = '${'<!--a-->' * 5000}zzz';
      final watch = Stopwatch()..start();
      expect(looksLikeSetlistXml(text), isFalse);
      expect(looksLikeSetlistXml('${'<!--a-->\n' * 40}zzz'), isFalse);
      expect(looksLikeSetlistXml('${'<!--a-->' * 5000}<!-- open'), isFalse);
      expect(watch.elapsedMilliseconds, lessThan(200));
    });

    test('still accepts declarations, BOM and comments before <set>', () {
      expect(
        looksLikeSetlistXml(
          '﻿ <?xml version="1.0"?>\n<!-- a --> <!--b-->\n<set name="x">',
        ),
        isTrue,
      );
      expect(looksLikeSetlistXml('<set/>'), isTrue);
      expect(looksLikeSetlistXml('<settings/>'), isFalse);
      expect(looksLikeSetlistXml('<set'), isFalse);
    });
  });

  group('legacy text encodings', () {
    test('Windows-1252 punctuation is not left as C1 controls', () {
      final bytes = Uint8List.fromList([
        ...ascii.encode('don'),
        0x92,
        ...ascii.encode('t '),
        0x93,
        ...ascii.encode('hi'),
        0x94,
        0x20,
        0x96,
        0x20,
        0x85,
        0x20,
        0x80,
      ]);
      expect(decodeImportedText(bytes), 'don’t “hi” – … €');
      expect(
        decodeImportedText(bytes).runes.any((r) => r >= 0x80 && r <= 0x9f),
        isFalse,
      );
    });

    test('short accented Latin-1 text is not mistaken for Windows-1251', () {
      expect(decodeImportedText([0xc9, 0x74, 0xe9]), 'Été');
      expect(decodeImportedText([0x4e, 0x6f, 0xeb, 0x6c]), 'Noël');
    });

    test('real Cyrillic words still decode as Windows-1251', () {
      expect(decodeImportedText(cp1251('Светлина')), 'Светлина');
      expect(decodeImportedText(cp1251('A я и в')), isNot(contains('Ã')));
    });
  });

  group('timing file imports', () {
    final lrc =
        '[ti:Светлина]\n[ar:Тест]\n[00:01.00]Светлина идва\n[00:03.00]Слънце';

    test('a Windows-1251 .lrc keeps its lyrics and original bytes', () {
      final bytes = cp1251(lrc.replaceAll('Слънце', 'Слонце'));
      final song = decodePickedSongs(PickedDocument('song.lrc', bytes)).single;
      expect(song.title, 'Светлина');
      expect(song.body, 'Светлина идва\nСлонце');
      final track = song.timingTracks.single;
      expect(track.extra['rawEncoding'], 'windows-1251');
      expect(base64.decode(track.extra['rawBytesBase64'] as String), bytes);
    });

    test('a Windows-1251 .ttml is no longer silently blank', () {
      final ttml = cp1251(
        '<tt xmlns="http://www.w3.org/ns/ttml"><body><div>'
        '<p begin="00:00:01.000" end="00:00:02.000">Светлина</p>'
        '</div></body></tt>',
      );
      final song = decodePickedSongs(PickedDocument('s.ttml', ttml)).single;
      expect(song.body, contains('Светлина'));
    });

    test('UTF-16 .lrc imports and an empty .lrc is an error', () {
      final units = '[00:01.00]Hello'.codeUnits;
      final utf16 = Uint8List.fromList([
        0xff,
        0xfe,
        for (final unit in units) ...[unit & 0xff, unit >> 8],
      ]);
      expect(
        decodePickedSongs(PickedDocument('u.lrc', utf16)).single.body,
        'Hello',
      );
      expect(
        () => decodePickedSongs(
          PickedDocument('e.lrc', Uint8List.fromList(ascii.encode('[ti:x]'))),
        ),
        throwsFormatException,
      );
    });

    test('an oversize timing file is rejected', () {
      expect(
        () => decodePickedSongs(
          PickedDocument('big.lrc', Uint8List(maxImportBytes + 1)),
        ),
        throwsA(formatError('file_too_large')),
      );
    });
  });

  group('setlist entries print with their own key and capo', () {
    final song = SongDocument(
      id: 's',
      title: 'Song',
      artist: '',
      metadata: const {'key': 'C', 'capo': 0},
      body: '[C]Hello [G]world',
    );

    test('overrides are applied per entry', () {
      final set = SetlistDocument(
        id: 'set',
        name: 'Set',
        entries: const [
          SetlistEntry(id: 'plain', songId: 's'),
          SetlistEntry(
            id: 'd',
            songId: 's',
            overrides: {'key': 'D', 'capo': 2},
          ),
          SetlistEntry(id: 'flat', songId: 's', overrides: {'key': 'B♭'}),
          SetlistEntry(id: 'gone', songId: 'missing'),
        ],
      );
      final resolved = songsForSetlist(set, [song]);
      expect(resolved, hasLength(3));
      expect(resolved[0].body, '[C]Hello [G]world');
      expect(resolved[1].body, '[D]Hello [A]world');
      expect(resolved[1].metadata['key'], 'D');
      expect(resolved[1].metadata['capo'], 2);
      expect(resolved[2].body, '[A#]Hello [F]world');
      expect(resolved[2].metadata['key'], 'B♭');
      expect(
        song.body,
        '[C]Hello [G]world',
        reason: 'the stored song is untouched',
      );
    });
  });

  group('chords stay over their lyrics', () {
    final mono = monoFace();
    double lyricWidth(String text) =>
        text.runes.fold(0.0, (sum, r) => sum + mono.advance(r, 10));

    test('chord x equals the measured width of the lyric before it', () {
      final line = parseArrangement(
        '[C]Hello [G]world and [Am]aligned here',
      ).first;
      final rows = layoutChordedRowsForTest(line, [mono], 500);
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.chords.map((c) => c.chord), ['C', 'G', 'Am']);
      expect(row.chords[0].x, 0);
      expect(row.chords[1].x, closeTo(lyricWidth('Hello '), 0.001));
      expect(row.chords[2].x, closeTo(lyricWidth('Hello world and '), 0.001));
      // The old space padding put the third chord 15% too far left.
      expect(row.chords[2].x, greaterThan(15 * 5.1 + 5));
    });

    test('a long line wraps by width and each chord stays with its words', () {
      final words = List.generate(40, (i) => 'word$i');
      final body = words
          .asMap()
          .entries
          .map((e) => e.key % 5 == 0 ? '[Am]${e.value}' : e.value)
          .join(' ');
      final line = parseArrangement(body).first;
      final rows = layoutChordedRowsForTest(line, [mono], 150);
      expect(rows.length, greaterThan(3));
      expect(rows.map((r) => r.text).join(), line.text);
      expect(rows.expand((r) => r.chords), hasLength(8));
      for (final row in rows) {
        expect(lyricWidth(row.text), lessThanOrEqualTo(150));
        for (final chord in row.chords) {
          final index = row.chords.indexOf(chord);
          expect(chord.x, greaterThanOrEqualTo(0));
          if (index == 0) {
            // First chord of a row sits over a word start, not mid-word.
            final at = row.text.length > 1
                ? row.text.substring((chord.x / lyricWidth('a')).round())
                : '';
            expect(at, startsWith('word'));
          }
        }
      }
    });

    test('anchors count grapheme clusters, not UTF-16 units', () {
      final decomposed = 'é' * 3; // three clusters, six code points
      final line = parseArrangement('$decomposed[G]x').first;
      final rows = layoutChordedRowsForTest(line, [mono], 500);
      expect(
        rows.single.chords.single.x,
        closeTo(lyricWidth(decomposed), 0.001),
      );
    });
  });

  group('PDF fonts and scripts', () {
    test('Arabic, Hebrew, Devanagari and Thai embed their own fonts', () async {
      final song = SongDocument(
        id: 'scripts',
        title: 'مرحبا שלום नमस्ते สวัสดี',
        artist: 'F♯ − B♭',
        metadata: const {'key': 'F♯ minor', 'capo': '−2'},
        body:
            '[C]مرحبا بالعالم\nשלום עולם\n[G]नमस्ते दुनिया\nสวัสดีชาวโลก\n[Am]Plain Latin ♯ ♭ − line',
      );
      final bytes = await createSongPdf([song]);
      final text = latin1.decode(bytes, allowInvalid: true);
      for (final name in [
        'NotoSansArabic',
        'NotoSansHebrew',
        'NotoSansDevanagari',
        'NotoSansThai',
      ]) {
        expect(text, contains(name), reason: name);
      }
      expect(text, isNot(contains('NotoSansSC')), reason: 'CJK not needed');
    });

    test('Chinese, Japanese kana and Hangul embed the CJK subsets', () async {
      final song = SongDocument(
        id: 'cjk',
        title: '你好世界',
        artist: 'ひらがな カタカナ',
        body: '[C]你好，世界\n안녕하세요 세계\n[G]こんにちは世界',
      );
      final bytes = await createSongPdf([song]);
      final text = latin1.decode(bytes, allowInvalid: true);
      expect(text, contains('NotoSansSC'));
      expect(text, contains('NotoSansKR'));
      expect(await unprintableCharacters(['你好，世界 안녕하세요 こんにちは']), isEmpty);
    });

    test(
      'characters no bundled font has are reported, not dropped silently',
      () async {
        expect(
          await unprintableCharacters([
            'Plain ♯♭ − текст',
            'حرف',
            'א',
            'ก',
            'क',
          ]),
          isEmpty,
        );
        expect(
          await unprintableCharacters([
            'a\u{1F600}b',
            '\u{1F600}',
            'ab\u{10348}',
          ]),
          [0x10348, 0x1f600],
        );
        // Rendering such text still succeeds and says so on the page.
        final bytes = await createSongPdf([
          SongDocument(
            id: 'e',
            title: 'Smile \u{1F600}',
            artist: '',
            body: '[C]x \u{1F600}',
          ),
        ]);
        expect(latin1.decode(bytes, allowInvalid: true), contains('%PDF'));
      },
    );

    test('RTL lines render with chords listed above them', () async {
      final bytes = await createSongPdf([
        SongDocument(
          id: 'rtl',
          title: 'عربي',
          artist: '',
          body: '[C]مرحبا بك [G]في الأغنية',
        ),
      ]);
      expect(bytes.length, greaterThan(5000));
      expect(isRightToLeftText('مرحبا'), isTrue);
      expect(isRightToLeftText('hello مرحبا'), isFalse);
      expect(isRightToLeftText('12 ...'), isFalse);
    });

    test(
      'an export that would stall the app is refused with a clear error',
      () async {
        final body = List.filled(maxPdfLines + 1, 'la la la').join('\n');
        await expectLater(
          createSongPdf([
            SongDocument(id: 'big', title: 'Big', artist: '', body: body),
          ]),
          throwsA(formatError('pdf_too_large')),
        );
      },
    );

    test('a setlist with overrides builds for every page format', () async {
      final song = SongDocument(
        id: 'a',
        title: 'Song',
        artist: 'Artist',
        metadata: const {'key': 'C'},
        body: '{comment: Pre-Chorus}\n[C]Hello [G]world\n{comment: Play twice}',
      );
      final set = SetlistDocument(
        id: 's',
        name: 'Set',
        entries: const [
          SetlistEntry(id: 'e', songId: 'a', overrides: {'key': 'E'}),
        ],
      );
      final bytes = await createSongPdf(
        songsForSetlist(set, [song]),
        setlist: set,
      );
      expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    });
  });

  group('copy text keeps every section note', () {
    test('solo, pre-chorus, repeat notes and chorus markers are kept', () {
      final text = songPlainText(
        SongDocument(
          id: 'h',
          title: 'Headings',
          artist: '',
          body:
              '{comment: Pre-Chorus}\n[C]a\n{comment: Solo}\n{comment: Repeat x2}\n{chorus}\n{start_of_solo}\n[G]b\n{end_of_solo}\n{title: Ignored}',
        ),
      );
      expect(text, contains('Pre-Chorus'));
      expect(text, contains('Solo'));
      expect(text, contains('Repeat x2'));
      expect(text, contains('Chorus'));
      expect(text, isNot(contains('Ignored')));
      expect(text, isNot(contains('{')));
    });
  });

  group('backup packages', () {
    test(
      'two songs with one id are refused instead of an unrestorable zip',
      () {
        final a = SongDocument(id: 'x', title: 'A', artist: '', body: 'a');
        final b = SongDocument(id: 'x', title: 'B', artist: '', body: 'b');
        expect(
          () => encodeLibraryPackage([a, b], []),
          throwsA(formatError('duplicate_song_id')),
        );
      },
    );

    test('the background variants round-trip a library', () async {
      final song = SongDocument(id: 'x', title: 'A', artist: '', body: 'words');
      final bytes = await encodeLibraryPackageAsync([song], []);
      final restored = await decodeLibraryPackageAsync(bytes);
      expect(restored.songs.single.id, 'x');
      await expectLater(
        decodeLibraryPackageAsync(Uint8List.fromList([1, 2, 3, 4, 5])),
        throwsA(formatError('invalid_archive')),
      );
    });

    test('a forged entry count is rejected from the directory record', () {
      final song = SongDocument(id: 'x', title: 'A', artist: '', body: 'words');
      final zip = Uint8List.fromList(encodeLibraryPackage([song], []));
      final data = ByteData.sublistView(zip);
      for (var i = zip.length - 22; i >= 0; i--) {
        if (data.getUint32(i, Endian.little) == 0x06054b50) {
          data.setUint16(i + 10, 40000, Endian.little);
          break;
        }
      }
      expect(
        () => decodeLibraryPackage(zip),
        throwsA(formatError('invalid_archive')),
      );
    });
  });

  group('sharing exports', () {
    late Directory temp;
    setUp(() async {
      temp = await Directory.systemTemp.createTemp('verse-share-review-');
    });
    tearDown(() async => temp.delete(recursive: true));
    int copies() {
      final root = Directory('${temp.path}/verse-share');
      return root.existsSync()
          ? root.listSync().whereType<Directory>().length
          : 0;
    }

    test(
      'PDF and backup shares clean up after a reported completion',
      () async {
        final actions = VerseFileActions(
          temporaryDirectory: () async => temp,
          shareFiles: (params) async {
            expect(
              File(params.files!.single.path).lengthSync(),
              greaterThan(0),
            );
            return const ShareResult('ok', ShareResultStatus.success);
          },
        );
        final song = SongDocument(
          id: 'a',
          title: 'T',
          artist: '',
          body: '[C]x',
        );
        await actions.shareSongPdf(song);
        await actions.shareBackup([song], []);
        expect(copies(), 0);
      },
    );

    test(
      'cleanUpShareCache removes stale copies without a new share',
      () async {
        final actions = VerseFileActions(
          temporaryDirectory: () async => temp,
          shareRetention: Duration.zero,
          shareFiles: (_) async =>
              const ShareResult('launched', ShareResultStatus.unavailable),
        );
        await actions.shareSong(
          SongDocument(id: 'a', title: 'T', artist: '', body: 'x'),
        );
        expect(copies(), 1);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await actions.cleanUpShareCache();
        expect(copies(), 0);
      },
    );
  });
}
