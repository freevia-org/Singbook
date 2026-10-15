import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';

void main() {
  final codec = ChordProCodec();
  TimingTrack track(String id) => TimingTrack(
    id: id,
    sourceDocumentId: 'src',
    sourceLyrics: 'Hello',
    format: 'lrc',
    cues: [
      TimingCue(id: 'c$id', occurrenceId: 'line-0', text: 'Hello', startUs: 1),
    ],
    status: TimingStatus.usable,
  );
  SourceResult source(List<TimingTrack> tracks) => SourceResult(
    candidate: const SongCandidate(
      providerId: 'p',
      id: '1',
      title: 'T',
      artist: 'A',
    ),
    body: 'Hello',
    timingTracks: tracks,
  );
  SongDocument song() => SongDocument(
    id: 's',
    title: 'T',
    artist: 'A',
    body: 'Hello',
    sources: [
      source([track('a'), track('b')]),
    ],
    timingTracks: [track('a'), track('b'), track('own')],
    activeTimingTrackId: 'a',
  );

  test('removing only from song.timingTracks is resurrected (the old bug)', () {
    final s = song();
    final naive = s.copyWith(
      timingTracks: s.timingTracks.where((t) => t.id != 'a').toList(),
    );
    final back = codec.decode(codec.encode(naive));
    expect(back.timingTracks.map((t) => t.id), contains('a'));
  });

  test('removeTimingTrack removes from song and sources and survives encode', () {
    final removed = removeTimingTrack(song(), 'a');
    expect(removed.timingTracks.map((t) => t.id), ['b', 'own']);
    expect(removed.sources.single.timingTracks.map((t) => t.id), ['b']);
    expect(removed.activeTimingTrackId, isNull);
    final back = codec.decode(codec.encode(removed));
    expect(back.extensionError, isNull);
    expect(back.timingTracks.map((t) => t.id).toSet(), {'b', 'own'});
    expect(back.sources.single.timingTracks.map((t) => t.id), ['b']);
    expect(back.activeTimingTrackId, isNull);
  });

  test('removing an unrelated or unknown track keeps the active one', () {
    final s = song();
    expect(identical(removeTimingTrack(s, 'zzz'), s), isTrue);
    expect(removeTimingTrack(s, 'own').activeTimingTrackId, 'a');
  });

  test('a dangling active track id never invalidates the timing payload', () {
    final s = song().copyWith(activeTimingTrackId: 'gone');
    final back = codec.decode(codec.encode(s));
    expect(back.extensionError, isNull);
    expect(back.timingTracks, hasLength(3));
    expect(back.activeTimingTrackId, isNull);
  });
}
