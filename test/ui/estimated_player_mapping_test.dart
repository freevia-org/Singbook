import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/player_section_timeline.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const chordOnly = LyricLineData(
    id: 'chord-only',
    chords: [LyricChord(graphemeOffset: 0, symbol: 'C')],
  );

  const songLines = <LyricLineData>[
    LyricLineData(id: 'intro-heading', section: 'Intro', isBlank: true),
    chordOnly,
    LyricLineData(
      id: 'intro-chord-two',
      chords: [LyricChord(graphemeOffset: 0, symbol: 'F')],
    ),
    LyricLineData(
      id: 'intro-chord-three',
      chords: [LyricChord(graphemeOffset: 0, symbol: 'G')],
    ),
    LyricLineData(
      id: 'intro-chord-four',
      chords: [LyricChord(graphemeOffset: 0, symbol: 'Am')],
    ),
    LyricLineData(id: 'intro-blank', isBlank: true),
    LyricLineData(id: 'intro-lyric', text: 'Intro words'),
    LyricLineData(id: 'intro-lyric-two', text: 'More intro words'),
    LyricLineData(id: 'verse-heading', section: 'Verse 1', isBlank: true),
    LyricLineData(
      id: 'verse-chord-only',
      chords: [LyricChord(graphemeOffset: 0, symbol: 'G')],
    ),
    LyricLineData(id: 'verse-one', text: 'First verse'),
    LyricLineData(id: 'verse-two', text: 'Second verse'),
    LyricLineData(id: 'chorus-heading', section: 'Chorus', isBlank: true),
    LyricLineData(id: 'chorus-one', text: 'Refrain'),
    LyricLineData(id: 'chorus-two', text: 'Refrain again'),
    LyricLineData(id: 'bridge-heading', section: 'Bridge', isBlank: true),
    LyricLineData(id: 'bridge-blank', isBlank: true),
    LyricLineData(id: 'bridge-one', text: 'Bridge words'),
  ];

  group('estimated player mapping', () {
    test(
      'timed markers exclude synthetic instrumental boundaries and sort cues',
      () {
        const lines = [
          LyricLineData(id: 'intro', section: 'Intro', isBlank: true),
          LyricLineData(id: 'verse', section: 'Verse', isBlank: true),
          LyricLineData(id: 'a', text: 'Verse lyric'),
          LyricLineData(id: 'bridge', section: 'Bridge', isBlank: true),
          LyricLineData(id: 'chorus', section: 'Chorus', isBlank: true),
          LyricLineData(id: 'b', text: 'Chorus lyric'),
          LyricLineData(id: 'outro', section: 'Outro', isBlank: true),
        ];
        final markers = buildPlayerSectionMarkers(
          lines: lines,
          durationSeconds: 100,
          timedLineStarts: const {'a': 90, 'b': 95},
          useEstimatedFallback: false,
        );
        expect(markers.map((marker) => marker.name), ['Verse', 'Chorus']);
        expect(markers.map((marker) => marker.startSeconds), [90, 95]);
        final reordered = buildPlayerSectionMarkers(
          lines: lines,
          durationSeconds: 100,
          timedLineStarts: const {'a': 95, 'b': 90},
          useEstimatedFallback: false,
        );
        expect(reordered.map((marker) => marker.lineId), ['b', 'a']);
        expect(
          buildPlayerSectionMarkers(
            lines: lines,
            durationSeconds: 100,
            useEstimatedFallback: false,
          ),
          isEmpty,
        );
      },
    );

    test(
      'lyric-free intro, bridge and outro occupy seekable estimated slots',
      () {
        const lines = [
          LyricLineData(id: 'intro', section: 'Intro', isBlank: true),
          chordOnly,
          LyricLineData(id: 'verse', section: 'Verse', isBlank: true),
          LyricLineData(id: 'a', text: 'First lyric'),
          LyricLineData(id: 'b', text: 'Second lyric'),
          LyricLineData(id: 'bridge', section: 'Bridge', isBlank: true),
          LyricLineData(id: 'blank', isBlank: true),
          LyricLineData(id: 'chorus', section: 'Chorus', isBlank: true),
          LyricLineData(id: 'c', text: 'Chorus lyric'),
          LyricLineData(id: 'outro', section: 'Outro', isBlank: true),
        ];
        const events = ['intro', 'a', 'b', 'bridge', 'c', 'outro'];
        for (var index = 0; index < events.length; index++) {
          expect(
            estimatedLineStartSeconds(lines, events[index], 120),
            index * 20,
          );
          expect(
            estimatedLineIdAtPosition(
              lines,
              progressSeconds: index * 20 + 19.9,
              durationSeconds: 120,
            ),
            events[index],
          );
        }
        final markers = buildPlayerSectionMarkers(
          lines: lines,
          durationSeconds: 120,
        );
        expect(markers.map((marker) => marker.startSeconds), [
          0,
          20,
          60,
          80,
          100,
        ]);
        expect(markers.map((marker) => marker.lineId), [
          'intro',
          'a',
          'bridge',
          'c',
          'outro',
        ]);
        expect(
          playerSectionSkipTarget(
            markers: markers,
            progressSeconds: 85,
            durationSeconds: 120,
            direction: 1,
          ),
          100,
        );
        expect(
          playerSectionSkipTarget(
            markers: markers,
            progressSeconds: 102,
            durationSeconds: 120,
            direction: -1,
          ),
          80,
        );
      },
    );

    test(
      'uses lyric rows only and agrees with section markers at boundaries',
      () {
        final timeline = estimatedTimelineLines(songLines);
        expect(timeline.map((line) => line.id), [
          'intro-lyric',
          'intro-lyric-two',
          'verse-one',
          'verse-two',
          'chorus-one',
          'chorus-two',
          'bridge-one',
        ]);

        const duration = 262.0;
        final markers = buildPlayerSectionMarkers(
          lines: songLines,
          durationSeconds: duration,
        );
        expect(markers.map((marker) => marker.lineId), [
          'intro-lyric',
          'verse-one',
          'chorus-one',
          'bridge-one',
        ]);

        for (final marker in markers) {
          expect(
            estimatedLineStartSeconds(songLines, marker.lineId, duration),
            marker.startSeconds,
            reason: 'section seek and highlight must share one line boundary',
          );
          expect(
            estimatedLineIdAtPosition(
              songLines,
              progressSeconds: marker.startSeconds,
              durationSeconds: duration,
            ),
            marker.lineId,
          );
        }

        for (var index = 1; index < markers.length; index++) {
          final marker = markers[index];
          final preceding =
              timeline[timeline.indexWhere((line) => line.id == marker.lineId) -
                  1];
          expect(
            estimatedLineIdAtPosition(
              songLines,
              progressSeconds: marker.startSeconds - .001,
              durationSeconds: duration,
            ),
            preceding.id,
            reason: 'just before a boundary, the preceding lyric stays active',
          );
        }
      },
    );

    test('handles chordless, all-chord, empty and invalid-duration inputs', () {
      const chordless = [
        LyricLineData(id: 'one', text: 'One'),
        LyricLineData(id: 'two', text: 'Two'),
      ];
      expect(estimatedTimelineLines(chordless).map((line) => line.id), [
        'one',
        'two',
      ]);
      expect(
        estimatedLineIdAtPosition(
          chordless,
          progressSeconds: 60,
          durationSeconds: 120,
        ),
        isNotNull,
      );

      const allChord = [chordOnly];
      expect(estimatedTimelineLines(allChord), isEmpty);
      expect(estimatedLineStartSeconds(allChord, 'chord-only', 120), isNull);
      expect(
        estimatedLineIdAtPosition(
          allChord,
          progressSeconds: 0,
          durationSeconds: 120,
        ),
        isNull,
      );
      expect(estimatedTimelineLines(const []), isEmpty);
      expect(estimatedLineStartSeconds(const [], 'missing', 120), isNull);
      expect(
        estimatedLineIdAtPosition(
          const [],
          progressSeconds: 0,
          durationSeconds: 120,
        ),
        isNull,
      );

      for (final duration in [0.0, -1.0, double.nan, double.infinity]) {
        expect(estimatedLineStartSeconds(chordless, 'one', duration), isNull);
        expect(
          estimatedLineIdAtPosition(
            chordless,
            progressSeconds: 0,
            durationSeconds: duration,
          ),
          isNull,
        );
      }
    });
  });

  group('adapter estimated highlighting', () {
    late LibraryRepository repository;
    late AppController app;
    late AppControllerAdapter ui;

    setUp(() async {
      repository = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      app = AppController(
        repository: repository,
        discovery: SourceDiscoveryService(const []),
      );
      await app.initialize();
      ui = AppControllerAdapter(app);
    });

    tearDown(() async {
      ui.dispose();
      app.dispose();
      await repository.close();
    });

    test(
      'active recording cues do not inherit estimated instrumental markers',
      () async {
        const body =
            '[Intro]\n[C]\n[Verse]\nVerse lyric\n[Bridge]\n[G]\n[Chorus]\nChorus lyric\n[Outro]';
        await app.saveSong(
          SongDocument(
            id: 'timed-sections',
            title: 'Cue boundary',
            artist: 'Test artist',
            body: body,
            metadata: const {'durationSeconds': 100},
            activeTimingTrackId: 'track',
            timingTracks: const [
              TimingTrack(
                id: 'track',
                sourceDocumentId: 'fixture',
                sourceLyrics: 'Verse lyric\nChorus lyric',
                format: 'lrc',
                status: TimingStatus.usable,
                cues: [
                  TimingCue(
                    id: 'a',
                    occurrenceId: 'line-0',
                    text: 'Verse lyric',
                    startUs: 90000000,
                  ),
                  TimingCue(
                    id: 'b',
                    occurrenceId: 'line-1',
                    text: 'Chorus lyric',
                    startUs: 95000000,
                  ),
                ],
              ),
            ],
          ),
        );
        await ui.openSong('timed-sections');
        await ui.setTimingMode('timed');
        expect(ui.state.playerSections.map((marker) => marker.name), [
          'Verse',
          'Chorus',
        ]);
        expect(ui.state.playerSections.map((marker) => marker.startSeconds), [
          90,
          95,
        ]);
        await ui.seek(90);
        expect(ui.state.currentLineId, ui.state.playerSections.first.lineId);
        await ui.setTimingMode('estimated');
        expect(ui.state.playerSections.map((marker) => marker.name), [
          'Intro',
          'Verse',
          'Bridge',
          'Chorus',
          'Outro',
        ]);
        expect((await repository.getSong('timed-sections'))!.body, body);
      },
    );

    test('section seek boundary highlights the section opening lyric', () async {
      await app.saveSong(
        SongDocument(
          id: 'estimated-section-seek',
          title: 'Section Boundary',
          artist: 'Test Artist',
          body:
              '[Intro]\n[C]\n[D]\n[Em]\n[F]\nIntro words\nMore intro words\n\n[Verse 1]\n[G]\nFirst verse\nSecond verse\n\n[Chorus]\n[D]\nRefrain\nRefrain again\n\n[Bridge]\n[A]\nBridge words',
          metadata: {'durationSeconds': 262},
        ),
      );
      await ui.openSong('estimated-section-seek');

      final initial = ui.state;
      final marker = initial.playerSections.firstWhere(
        (section) => section.name == 'Verse 1',
      );
      await ui.seek(marker.startSeconds);
      expect(ui.state.currentLineId, marker.lineId);

      final timeline = estimatedTimelineLines(initial.songLines);
      final lineIndex = timeline.indexWhere((line) => line.id == marker.lineId);
      expect(lineIndex, greaterThan(0));
      await ui.seek(marker.startSeconds - .001);
      expect(ui.state.currentLineId, timeline[lineIndex - 1].id);

      await ui.setTimingMode('manual');
      await ui.seek(marker.startSeconds);
      expect(ui.state.currentLineId, isNull);
    });
  });
}
