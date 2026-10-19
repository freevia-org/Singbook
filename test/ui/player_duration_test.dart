import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/ui/player_duration.dart';
import 'package:singbook/ui/player_section_timeline.dart';
import 'package:singbook/ui/verse_ui_state.dart';

SongCandidate candidate(
  String provider,
  String id, {
  double? duration,
  String title = 'Fixture song',
  String artist = 'Fixture artist',
  String? album,
  JsonMap metadata = const {},
  Map<String, String> ids = const {},
}) => SongCandidate(
  providerId: provider,
  id: id,
  title: title,
  artist: artist,
  durationSeconds: duration,
  album: album,
  metadata: metadata,
  recordingIds: ids,
);
SourceResult claim(
  String provider,
  double duration, {
  String id = 'one',
  String title = 'Fixture song',
  String artist = 'Fixture artist',
  String? album,
  JsonMap metadata = const {},
  MatchKind match = MatchKind.sameSong,
  JsonMap extra = const {},
}) => SourceResult(
  candidate: candidate(
    provider,
    id,
    duration: duration,
    title: title,
    artist: artist,
    album: album,
    metadata: metadata,
  ),
  body: 'Fixture lyrics',
  matchKind: match,
  extra: extra,
);
SongDocument song({
  JsonMap metadata = const {},
  SongCandidate? selected,
  List<SourceResult> sources = const [],
  List<TimingTrack> tracks = const [],
}) => SongDocument(
  id: 'owned',
  title: 'Fixture song',
  artist: 'Fixture artist',
  body: 'Fixture lyrics',
  metadata: metadata,
  selectedRecording: selected,
  sources: sources,
  timingTracks: tracks,
  activeTimingTrackId: tracks.isEmpty ? null : tracks.first.id,
);

void main() {
  final selected = candidate('selected', 'one');
  test('explicit duration wins without evaluating chart estimate', () {
    final result = resolvePlayerDuration(
      song(
        metadata: {'durationSeconds': 250},
        selected: candidate('selected', 'one', duration: 300),
      ),
      estimate: () => throw StateError('must be lazy'),
    );
    expect(result.seconds, 250);
    expect(result.estimated, isFalse);
  });
  test('selected and exactly bound source recording durations are known', () {
    expect(
      resolvePlayerDuration(
        song(selected: candidate('selected', 'one', duration: 301)),
        estimate: () => 90,
      ).kind,
      PlayerDurationKind.selectedRecording,
    );
    final result = resolvePlayerDuration(
      song(selected: selected, sources: [claim('selected', 302)]),
      estimate: () => 90,
    );
    expect(result.seconds, 302);
    expect(result.kind, PlayerDurationKind.recordingSource);
  });
  test(
    'independent compatible catalog agreement remains estimated and unsaved',
    () {
      final input = song(
        selected: selected,
        sources: [
          claim('a', 327),
          claim('a', 327, id: 'duplicate'),
          claim('b', 328),
        ],
      );
      final before = input.toJson();
      final result = resolvePlayerDuration(input, estimate: () => 90);
      expect(result.seconds, 327.5);
      expect(result.kind, PlayerDurationKind.catalogEstimate);
      expect(input.toJson(), before);
      expect(input.metadata['durationSeconds'], isNull);
    },
  );
  final abstentions = <String, List<SourceResult>>{
    'one provider repeated': [
      claim('a', 300),
      claim('a', 301, id: 'duplicate'),
    ],
    'durations disagree': [claim('a', 300), claim('b', 310)],
    'provider internally conflicts': [
      claim('a', 300),
      claim('a', 320, id: 'duplicate'),
      claim('b', 300),
    ],
    'different artist': [claim('a', 300), claim('b', 300, artist: 'Other')],
    'different title edition': [
      claim('a', 300),
      claim('b', 300, title: 'Fixture song live'),
    ],
    'conflicting albums': [
      claim('a', 300, album: 'Studio'),
      claim('b', 300, album: 'Concert'),
    ],
    'conflicting editions': [
      claim('a', 300, metadata: {'edition': 'acoustic'}),
      claim('b', 300, metadata: {'edition': 'studio'}),
    ],
    'composition scope': [
      claim('a', 300),
      claim('b', 300, metadata: {'identityScope': 'composition'}),
    ],
    'pending match': [
      claim('a', 300),
      claim('b', 300, extra: {'pendingMatchCheck': true}),
    ],
    'unverified match': [
      claim('a', 300),
      claim('b', 300, match: MatchKind.unverified),
    ],
  };
  for (final entry in abstentions.entries) {
    test('catalog abstains for ${entry.key}', () {
      final result = resolvePlayerDuration(
        song(selected: selected, sources: entry.value),
        estimate: () => 123,
      );
      expect(result.seconds, 123);
      expect(result.kind, PlayerDurationKind.chartEstimate);
    });
  }
  test('usable cue is an estimate floor without changing exact timestamps', () {
    final input = song(
      tracks: [
        const TimingTrack(
          id: 'track',
          sourceDocumentId: 'owned',
          sourceLyrics: 'Fixture lyrics',
          format: 'lrc',
          status: TimingStatus.usable,
          cues: [
            TimingCue(
              id: 'cue',
              occurrenceId: 'line',
              text: 'Fixture lyrics',
              startUs: 301123456,
              endUs: 310654321,
            ),
          ],
        ),
      ],
    );
    final before = input.toJson();
    expect(
      resolvePlayerDuration(input, estimate: () => 90).seconds,
      310.654321,
    );
    expect(input.toJson(), before);
  });
  test(
    'formatting and lyric accompaniment do not inflate chart event duration',
    () {
      final lyrics = [
        for (var i = 0; i < 40; i++)
          LyricLineData(id: 'line-$i', text: 'Lyric $i'),
      ];
      final formatted = [
        for (final line in lyrics) ...[
          LyricLineData(id: 'blank-${line.id}', isBlank: true),
          LyricLineData(
            id: 'note-${line.id}',
            text: 'Capo 2',
            isArrangementNote: true,
          ),
          LyricLineData(
            id: 'chord-${line.id}',
            chords: const [LyricChord(graphemeOffset: 0, symbol: 'C')],
          ),
          line,
        ],
      ];
      expect(estimateChartDuration(lyrics), 136);
      expect(estimateChartDuration(formatted), 136);
    },
  );
  test('repeated instrumental progression reserves a longer seekable slot', () {
    const lines = [
      LyricLineData(id: 'intro', section: 'Intro'),
      LyricLineData(
        id: 'chord',
        text: 'x4',
        chords: [LyricChord(graphemeOffset: 0, symbol: 'C')],
      ),
      LyricLineData(id: 'verse', section: 'Verse'),
      LyricLineData(id: 'lyric', text: 'Words'),
    ];
    final starts = estimatedLineStartTimes(lines, 120);
    expect(starts, {'intro': 0.0, 'lyric': 90.0});
    expect(
      estimatedLineIdAtPosition(
        lines,
        progressSeconds: 89,
        durationSeconds: 120,
      ),
      'intro',
    );
    expect(
      buildPlayerSectionMarkers(
        lines: lines,
        durationSeconds: 120,
      ).last.startSeconds,
      90,
    );
  });
}
