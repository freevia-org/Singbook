import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/models.dart';

// The pattern the importer used before it was replaced by a linear scan.
final _legacyNewSong = RegExp(r'^\s*\{new_song\}\s*$', multiLine: true);

int _mainIsolateRuns = 0;

int _failsWithRangeError() {
  _mainIsolateRuns++;
  return <int>[][1];
}

void main() {
  group('multi-song split', () {
    test('matches the former regular expression on hand-picked inputs', () {
      const inputs = [
        '',
        '{new_song}',
        'a',
        'a\n{new_song}\nb',
        'a\r\n{new_song}\r\nb',
        'a\n\n\n  {new_song}  \n\n\nb',
        '{new_song}\n\n{new_song}',
        '{new_song}\n{new_song}\n{new_song}',
        'a {new_song}\nb',
        'a\n{new_song} b\nc',
        'a\n{new_song}{new_song}\nb',
        '\n\n{new_song}',
        '{new_song}\n\n',
        'a\n\t{new_song} \n {new_song} b',
        'a\r{new_song}\rb',
        ' {new_song} ',
        'x\n \n {new_song}\n \n y\n{new_song}',
        '{title: One}\nla\n{new_song}\n{title: Two}\nla',
        'a\n{NEW_SONG}\nb',
        'a\n{new_song}\n\n{new_song} x\n{new_song}\nb',
      ];
      for (final input in inputs) {
        expect(
          splitNewSongSections(input),
          input.split(_legacyNewSong),
          reason: jsonEncode(input),
        );
      }
    });

    test('matches the former regular expression on generated inputs', () {
      const pieces = [
        '{new_song}',
        '{new_song}',
        '\n',
        '\n',
        '\r\n',
        '\r',
        ' ',
        '\t',
        ' ',
        ' ',
        '﻿',
        'la',
        '{title: T}',
        '{new_song',
        'new_song}',
      ];
      final random = Random(20261111);
      for (var round = 0; round < 4000; round++) {
        final input = [
          for (var i = random.nextInt(14); i > 0; i--)
            pieces[random.nextInt(pieces.length)],
        ].join();
        expect(
          splitNewSongSections(input),
          input.split(_legacyNewSong),
          reason: jsonEncode(input),
        );
      }
    });

    test('the songs of a multi-song file are unchanged', () {
      final songs = decodeSongText(
        '{title: One}\nfirst\n\n  {new_song}  \n\n{title: Two}\nsecond\n'
        '{new_song}\n{title: Three}\nthird',
      );
      expect(songs.map((song) => song.title), ['One', 'Two', 'Three']);
      expect(songs.map((song) => song.body.trim()), [
        'first',
        'second',
        'third',
      ]);
    });
  });

  group('import patterns stay linear on runs of blank lines', () {
    // Each of these took seconds to minutes with `^\s*` under multiLine.
    final blank = '\n' * 200000;

    test('plain and multi-song text', () {
      final watch = Stopwatch()..start();
      final songs = decodeSongText('${blank}words$blank{new_song}${blank}more');
      watch.stop();
      expect(songs, hasLength(2));
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('the split alone', () {
      final watch = Stopwatch()..start();
      final parts = splitNewSongSections('${blank}x$blank{new_song}${blank}y');
      watch.stop();
      expect(parts, hasLength(2));
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('timed text with LRC tags', () {
      final watch = Stopwatch()..start();
      final songs = decodeSongText(
        '[ti:Blank]$blank[00:01.00]first line\n[00:03.00]second line$blank',
        fileName: 'blank.lrc',
      );
      watch.stop();
      expect(songs.single.title, 'Blank');
      expect(songs.single.timingTracks, hasLength(1));
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('a picked .lrc file', () {
      final watch = Stopwatch()..start();
      final songs = decodePickedSongs(
        PickedDocument(
          'blank.lrc',
          Uint8List.fromList(
            utf8.encode('[ar:Someone]$blank[00:01.00]first line$blank'),
          ),
        ),
      );
      watch.stop();
      expect(songs.single.artist, 'Someone');
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });

  group('timing detection and LRC tags', () {
    test('an indented timestamp after blank lines is still timing', () {
      final songs = decodeSongText(
        'intro\n\n\n \t[00:01.00]first\n[00:02.00]second',
        fileName: 'a.txt',
      );
      expect(songs.single.timingTracks, hasLength(1));
    });

    test('a timestamp in the middle of a line is not timing', () {
      final songs = decodeSongText('{title: T}\nwords [00:01.00] words');
      expect(songs.single.timingTracks, isEmpty);
    });

    test('indented tags after blank lines are read', () {
      final songs = decodeSongText(
        '\n\n  [ti: Indented]  \n\n\t[ar:Artist]\n[00:01.00]line',
        fileName: 'a.lrc',
      );
      expect(songs.single.title, 'Indented');
      expect(songs.single.artist, 'Artist');
    });
  });

  group('large files decode like small ones', () {
    test('the async wrappers return what the direct decoders return', () async {
      final filler = 'la la la la la la la la la la\n' * 6000;
      final text = '{title: Big}\n$filler{new_song}\n{title: Second}\n$filler';
      expect(text.length, greaterThan(128 * 1024));
      final direct = decodeSongText(text, fileName: 'big.cho');
      final background = await decodeSongTextAsync(text, fileName: 'big.cho');
      expect(background.map((song) => song.title), ['Big', 'Second']);
      expect(
        background.map((song) => song.body),
        direct.map((song) => song.body),
      );

      final lrc = PickedDocument(
        'big.lrc',
        Uint8List.fromList(
          utf8.encode(
            '[ti:Timed]\n${[for (var i = 0; i < 9000; i++) '[${(i ~/ 60).toString().padLeft(2, '0')}:${(i % 60).toString().padLeft(2, '0')}.00]line number $i'].join('\n')}',
          ),
        ),
      );
      expect(lrc.bytes.length, greaterThan(128 * 1024));
      final timed = await decodePickedSongsAsync(lrc);
      expect(timed.single.title, 'Timed');
      expect(timed.single.body, decodePickedSongs(lrc).single.body);

      expect(
        await decodeImportedTextAsync(Uint8List.fromList(utf8.encode(text))),
        text,
      );
    });
  });

  group('setlist references', () {
    SongDocument song(String id, String title, [String artist = '']) =>
        SongDocument(id: id, title: title, artist: artist, body: 'x');

    String osts(Iterable<String> groups) =>
        '<set name="Set"><slide_groups>${groups.join()}</slide_groups></set>';
    String group(String name, {String? id, String? artist}) =>
        '<slide_group name="$name" type="song"><verse_reference'
        '${id == null ? '' : ' songId="$id"'} entryId="e">'
        '${artist == null ? '' : '<artist>$artist</artist>'}'
        '<overrides>{}</overrides></verse_reference></slide_group>';

    final library = [
      song('1', 'Alpha', 'A'),
      song('2', 'Beta', 'B'),
      song('3', 'Beta', 'C'),
    ];

    test('ids win, then title and artist', () {
      final set = decodeSetlistReferences(
        osts([
          group('Renamed', id: '2'),
          group('Alpha', id: 'gone'),
          group('Beta', artist: 'C'),
        ]),
        library,
      );
      expect(set.entries.map((entry) => entry.songId), ['2', '1', '3']);
    });

    test('an ambiguous or unknown title is refused', () {
      for (final groups in [
        [group('Beta')],
        [group('Unknown')],
        [group('Alpha', artist: 'Someone else')],
      ]) {
        expect(
          () => decodeSetlistReferences(osts(groups), library),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              'missing_song_references',
            ),
          ),
        );
      }
    });

    test('the entry limit is enforced while reading, in linear time', () {
      final big = [for (var i = 0; i < 4000; i++) song('s$i', 'Title $i')];
      final watch = Stopwatch()..start();
      final set = decodeSetlistReferences(
        osts([for (var i = 0; i < 10000; i++) group('x', id: 's${i % 4000}')]),
        big,
      );
      watch.stop();
      expect(set.entries, hasLength(10000));
      expect(watch.elapsed, lessThan(const Duration(seconds: 20)));
      expect(
        () => decodeSetlistReferences(
          osts([for (var i = 0; i < 10001; i++) group('x', id: 's1')]),
          big,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'too_many_songs',
          ),
        ),
      );
    });

    test('a large file resolves the same way off the main isolate', () async {
      final text = osts([
        for (var i = 0; i < 1500; i++) group('Alpha', id: '1'),
      ]);
      expect(text.length, greaterThan(128 * 1024));
      final direct = decodeSetlistReferences(text, library, fileName: 'a.osts');
      final background = await decodeSetlistReferencesAsync(
        text,
        library,
        fileName: 'a.osts',
      );
      expect(background.id, direct.id);
      expect(background.name, direct.name);
      expect(
        background.entries.map((entry) => entry.songId),
        direct.entries.map((entry) => entry.songId),
      );
    });
  });

  group('background work', () {
    test('a RangeError from the work is not retried on the caller', () async {
      _mainIsolateRuns = 0;
      await expectLater(
        runInBackgroundForTest(_failsWithRangeError),
        throwsA(isA<RangeError>()),
      );
      expect(
        _mainIsolateRuns,
        0,
        reason: 'the failed job must not run again on the calling isolate',
      );
    });

    test('values and other errors pass through unchanged', () async {
      expect(await runInBackgroundForTest(() => 6 * 7), 42);
      expect(await runInBackgroundForTest(() async => 'done'), 'done');
      await expectLater(
        runInBackgroundForTest<int>(
          () => throw const FormatException('backup_too_large'),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'backup_too_large',
          ),
        ),
      );
    });
  });

  group('safeName', () {
    test('a long CJK or emoji title fits a 255-byte file name', () {
      for (final title in ['歌' * 150, '😀' * 150, 'я' * 150, '歌😀a' * 60]) {
        final name = safeName(title);
        expect(utf8.encode('$name.lyrics-setlist').length, lessThan(256));
        expect(name, isNotEmpty);
        // Still whole code points of the original title.
        expect(title.startsWith(name), isTrue, reason: title);
      }
    });

    test('names that already fit are unchanged', () {
      expect(safeName('a' * 100), 'a' * 100);
      expect(safeName('я' * 100), 'я' * 100);
      expect(safeName('歌' * 80), '歌' * 80);
    });
  });
}
