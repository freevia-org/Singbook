// ignore_for_file: avoid_print
// Opt-in smoke probe. Emits metadata/counts only, never song text or tokens.
import 'package:verse_mobile/providers/extra/extra_providers.dart';
import 'package:verse_mobile/providers/provider.dart';

Future<void> main() async {
  final transport = ProviderTransport();
  final cases = <LyricsProvider, String>{
    WorshipCommonsProvider(transport): 'Amazing Grace',
    SeanMcGrathProvider(transport): 'Be Here Soon',
    OpenFilkProvider(transport): 'Everything',
    ChordieProvider(transport): 'The Seventh Stranger',
    MusicBrainzProvider(transport): 'recording:"Wonderwall" AND artist:"Oasis"',
    WikidataProvider(transport): 'Wonderwall',
    WikisourceProvider(transport): 'Auld Lang Syne Burns',
  };
  for (final entry in cases.entries) {
    try {
      final rows = await entry.key.search(entry.value);
      if (rows.isEmpty) {
        print('${entry.key.definition.id}: zero catalog rows');
        continue;
      }
      final r = await entry.key.resolve(rows.first);
      print(
        '${entry.key.definition.id}: rows=${rows.length}; title=${r.candidate.title}; bodyChars=${r.body.length}; chords=${r.hasChords}; tracks=${r.timingTracks.length}; metadata=${r.metadata.keys.join(',')}',
      );
    } catch (e) {
      print('${entry.key.definition.id}: $e');
    }
  }
  await transport.close();
}
