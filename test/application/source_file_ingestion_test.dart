import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/domain/chordpro.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Synthetic ChordPro documents exercise the actual file-picker decoder.
  // They verify local ingestion, not access to either publisher's downloads.
  for (final fileName in ['ozbcoz-example.txt', 'worship-example.chordpro']) {
    test('$fileName preserves downloaded chord and credit fields', () {
      const text =
          '\uFEFF{title: Synthetic import}\r\n'
          '{artist: Example Writer}\r\n'
          '{key: D}\r\n{capo: 2}\r\n{time: 3/4}\r\n'
          '{composer: Example Composer}\r\n'
          '{copyright: Example credit retained}\r\n'
          '{comment: Verse}\r\n[D]An invented café [A]line\r\n';
      final file = PickedDocument(
        fileName,
        Uint8List.fromList(utf8.encode(text)),
      );
      final song = decodePickedSongs(file).single;
      expect(song.title, 'Synthetic import');
      expect(song.artist, 'Example Writer');
      expect(song.metadata['key'], 'D');
      expect(song.metadata['capo'].toString(), '2');
      expect(song.metadata['timeSignature'], '3/4');
      expect(song.metadata['composer'], 'Example Composer');
      expect(song.metadata['copyright'], 'Example credit retained');
      expect(song.body, contains('[D]An invented café [A]line'));

      final restored = decodeSongText(ChordProCodec().encode(song)).single;
      expect(restored.title, song.title);
      expect(restored.artist, song.artist);
      expect(restored.metadata, song.metadata);
      expect(restored.body, song.body);
    });
  }

  test('a downloaded collection keeps independent song identities', () {
    const text =
        '{t: First synthetic song}\n{artist: Writer One}\n'
        '[C]First invented line\n{new_song}\n'
        '{title: Second synthetic song}\n{artist: Writer Two}\n'
        '[G]Second invented line';
    final songs = decodePickedSongs(
      PickedDocument(
        'downloaded-collection.cho',
        Uint8List.fromList(utf8.encode(text)),
      ),
    );
    expect(songs.map((song) => song.title), [
      'First synthetic song',
      'Second synthetic song',
    ]);
    expect(songs.map((song) => song.artist), ['Writer One', 'Writer Two']);
    expect(songs.map((song) => song.id).toSet(), hasLength(2));
  });

  test('HTML challenge or login page is rejected as a song file', () {
    final file = PickedDocument(
      'download.txt',
      Uint8List.fromList(
        utf8.encode(
          '<!DOCTYPE html><html><body>Sign in to download</body></html>',
        ),
      ),
    );
    expect(() => decodePickedSongs(file), throwsFormatException);
  });
}
