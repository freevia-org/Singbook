import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verse_mobile/application/file_actions.dart';
import 'package:verse_mobile/domain/chordpro.dart';
import 'package:verse_mobile/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('timing import shares as exactly one self-contained ChordPro', () {
    final song = decodeSongText(
      '[ti:Our song]\n[ar:Us]\n[00:01.25]Our first line\n[00:03.40]Our next line',
      fileName: 'ours.lrc',
    ).single;
    expect(song.title, 'Our song');
    final text = ChordProCodec().encode(song);
    final restored = decodeSongText(text).single;
    expect(restored.timingTracks.single.raw, contains('[00:01.25]'));
    expect(restored.timingTracks.single.cues.first.startUs, 1250000);
    expect(restored.body, 'Our first line\nOur next line');
  });
  test(
    'complete library package preserves repeated set entries and song payload',
    () {
      final song = decodeSongText('[ti:Song]\n[00:01]Original words').single;
      final set = SetlistDocument(
        id: 'set1',
        name: 'Twice',
        entries: [
          SetlistEntry(id: 'e1', songId: song.id),
          SetlistEntry(id: 'e2', songId: song.id, overrides: {'capo': 2}),
        ],
      );
      final archive = encodeLibraryPackage([song], [set]);
      final restored = decodeLibraryPackage(archive);
      expect(restored.songs.single.id, song.id);
      expect(
        restored.songs.single.timingTracks.single.raw,
        song.timingTracks.single.raw,
      );
      expect(restored.setlists.single.entries.map((e) => e.id), ['e1', 'e2']);
      expect(restored.setlists.single.entries.last.overrides['capo'], 2);
    },
  );
  test('package rejects altered song before import', () {
    final song = SongDocument(
      id: 'a',
      title: 'A',
      artist: '',
      body: 'Original words',
    );
    final original = ZipDecoder().decodeBytes(encodeLibraryPackage([song], []));
    final changed = Archive();
    for (final file in original) {
      changed.add(
        file.name.endsWith('.cho')
            ? ArchiveFile.string(file.name, 'changed')
            : file,
      );
    }
    expect(
      () => decodeLibraryPackage(ZipEncoder().encodeBytes(changed)),
      throwsFormatException,
    );
  });
  test(
    'package rejects traversal and XML never resolves ambiguous song references',
    () {
      final archive = Archive()..add(ArchiveFile.string('../escape', 'x'));
      expect(
        () => decodeLibraryPackage(ZipEncoder().encodeBytes(archive)),
        throwsFormatException,
      );
      final songs = [
        for (final id in ['a', 'b'])
          SongDocument(id: id, title: 'Same', artist: 'Me', body: 'words'),
      ];
      expect(
        () => decodeSetlistReferences(
          '<set><slide_groups><slide_group type="song" name="Same"/></slide_groups></set>',
          songs,
        ),
        throwsFormatException,
      );
      expect(
        () => decodeSetlistReferences('<!DOCTYPE set><set/>', songs),
        throwsFormatException,
      );
    },
  );
  test('OpenSong reference export preserves order and overrides', () {
    final song = SongDocument(
      id: 'a',
      title: 'Сонце & light',
      artist: 'Us',
      body: '[C]Our own words',
    );
    final set = SetlistDocument(
      id: 's',
      name: 'Our set',
      notes: 'A note',
      entries: [
        SetlistEntry(id: 'one', songId: 'a'),
        SetlistEntry(id: 'two', songId: 'a', overrides: {'key': 'D'}),
      ],
    );
    final text = encodeSetlistReferences(set, [song]);
    final restored = decodeSetlistReferences(text, [song]);
    expect(restored.name, 'Our set');
    expect(restored.notes, 'A note');
    expect(restored.entries.map((e) => e.songId), ['a', 'a']);
    expect(restored.entries.last.overrides['key'], 'D');
  });
  test('blank and unsupported imports cannot produce a phantom song', () {
    expect(() => decodeSongText(' \n'), throwsFormatException);
    expect(() => decodeSongText('<html>Error</html>'), throwsFormatException);
    expect(
      () => PickedDocument('invalid', Uint8List.fromList([0xff, 0xfe])).text,
      throwsFormatException,
    );
    expect(safeName('../my/song:'), isNot(contains('/')));
  });
  test(
    'offline PDF renders Cyrillic and starts each set song on a page',
    () async {
      final song = SongDocument(
        id: 'a',
        title: 'Світло / Светлина',
        artist: 'Verse',
        body: '[C]Наші слова\n[G]Нашите думи',
      );
      final bytes = await createSongPdf([
        song,
        song,
      ], setlist: SetlistDocument(id: 's', name: 'Set'));
      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
      expect(bytes.length, greaterThan(10000));
    },
  );
}
