import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/arrangement.dart';

void main() {
  test(
    'review song keeps full structure, metadata and chords after round trip',
    () {
      final codec = ChordProCodec();
      final song = codec.decode(
        File('docs/testflight-fixtures/harbor-road.cho').readAsStringSync(),
      );
      expect(song.title, 'Harbor Road');
      expect(song.metadata['key'], 'G');
      final labels = parseArrangement(
        song.body,
      ).map(sectionLabelForLine).whereType<String>().toList();
      expect(labels, [
        'Intro',
        'Verse 1',
        'Pre-Chorus',
        'Chorus',
        'Verse 2',
        'Chorus',
        'Bridge',
        'Chorus',
        'Outro',
      ]);
      expect(song.body, contains('[Em]'));
      expect(song.body, contains('[Am]'));
      expect(codec.decode(codec.encode(song)).body, song.body);
    },
  );
}
