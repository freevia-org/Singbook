import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/compact_chord_alignment.dart';
import 'package:singbook/domain/display_facts.dart';
import 'package:singbook/domain/lyric_word_identity.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/search_grouping.dart';
import 'package:singbook/domain/song_identity.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/domain/timing.dart';

const _chart = SourceResult(
  candidate: SongCandidate(
    providerId: 'chords',
    id: '/c/1',
    title: 'Song',
    artist: 'Artist',
  ),
  body: '[C]la',
  matchKind: MatchKind.rejected,
  matchReason: 'incomplete_or_different_lyrics',
);
const _lyrics = SourceResult(
  candidate: SongCandidate(
    providerId: 'lyrics',
    id: '7',
    title: 'Song',
    artist: 'Artist',
  ),
  body: 'la',
  matchKind: MatchKind.sameSong,
);

SongDocument _combined(Map<String, dynamic> extra, {String? key}) =>
    SongDocument(
      id: 'song',
      title: 'Song',
      artist: 'Artist',
      body: '[C]la',
      metadata: {'album': 'Album', 'key': ?key},
      sources: const [_lyrics, _chart],
      extra: {
        'selectedSourceId': _lyrics.id,
        'fieldOrigins': {'album': _chart.id},
        ...extra,
      },
    );

void main() {
  group('contributingProviderIds with malformed saved lists', () {
    test('well-formed lists still credit the rejected chart', () {
      expect(
        contributingProviderIds(
          _combined({
            'chordSourceIds': [_chart.id],
          }),
        ),
        {'lyrics', 'chords'},
      );
      expect(
        contributingProviderIds(
          _combined({
            'corroboratedKeySourceIds': [_chart.id],
          }, key: 'C'),
        ),
        {'lyrics', 'chords'},
      );
      expect(
        contributingProviderIds(
          _combined({
            'corroboratedKeySourceIds': [_chart.id],
          }),
        ),
        {'lyrics'},
        reason: 'a corroborated key only counts while the song has a key',
      );
    });

    for (final malformed in <Object>[
      'chords:/c/1',
      7,
      true,
      {'chords:/c/1': true},
    ]) {
      test('${malformed.runtimeType} instead of a list is no source', () {
        expect(
          contributingProviderIds(_combined({'chordSourceIds': malformed})),
          {'lyrics'},
        );
        expect(
          contributingProviderIds(
            _combined({'corroboratedKeySourceIds': malformed}, key: 'C'),
          ),
          {'lyrics'},
        );
        expect(
          contributingProviderIds(
            _combined({
              'chordSourceIds': malformed,
              'corroboratedKeySourceIds': [_chart.id],
            }, key: 'C'),
          ),
          {'lyrics', 'chords'},
        );
      });
    }
  });

  group('TTML nesting', () {
    test('paragraphs nested past the limit keep no expanded fallback', () {
      const depth = 3000;
      final raw =
          '<tt xmlns="http://www.w3.org/ns/ttml"><body>'
          '${'<p begin="1s">word '.padRight(19) * depth}${'</p>' * depth}'
          '</body></tt>';
      final track = parseTtml(raw, sourceDocumentId: 'file:deep');
      expect(track.status, TimingStatus.invalid);
      expect(track.cues, isEmpty);
      expect(track.sourceLyrics, isEmpty);
      expect(track.raw, raw);
    });

    test('a document at the limit still reports its text on failure', () {
      final track = parseTtml(
        '<tt xmlns="http://www.w3.org/ns/ttml"><body>'
        '<p begin="bogus">One line</p><p begin="2s">Another</p>'
        '</body></tt>',
        sourceDocumentId: 'file:bad-time',
      );
      expect(track.status, TimingStatus.invalid);
      expect(track.sourceLyrics, 'One line\nAnother');
    });

    test('nested timed spans keep one cue per word', () {
      final track = parseTtml(
        '<tt xmlns="http://www.w3.org/ns/ttml" '
        'xmlns:ttm="http://www.w3.org/ns/ttml#metadata"><body><div>'
        '<p begin="1.000" end="5.000">'
        '<span begin="1.000" end="3.000">'
        '<span begin="1.000" end="2.000">Hello</span> '
        '<span begin="2.000" end="3.000">there</span></span> '
        '<span begin="3.000" end="5.000">world</span>'
        '</p></div></body></tt>',
        sourceDocumentId: 'amll:1',
        profile: 'amll-ttml',
      );
      expect(track.status, TimingStatus.unverified);
      expect(
        track.cues
            .where((cue) => cue.graphemeStart != null)
            .map((cue) => cue.text),
        ['Hello', 'there', 'world'],
      );
    });
  });

  group('shared helpers', () {
    test('chordPitchClass covers every spelling transposition reads', () {
      const natural = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
      const accidentals = {
        '': 0,
        '#': 1,
        'b': -1,
        '##': 2,
        'bb': -2,
        '#b': 0,
        'b#': 0,
        '♯': 1,
        '♭': -1,
        '♯♯': 2,
        '♭♭': -2,
      };
      for (final note in natural.entries) {
        for (final accidental in accidentals.entries) {
          expect(
            chordPitchClass('${note.key}${accidental.key}'),
            (note.value + accidental.value) % 12,
            reason: '${note.key}${accidental.key}',
          );
        }
      }
      for (final invalid in ['', 'H', 'c', 'C###', 'Cm', 'C\n', '#C', 'C x']) {
        expect(chordPitchClass(invalid), isNull, reason: invalid);
      }
    });

    test('transposition keeps its spelling rules', () {
      expect(transposeChord('B#', 0), 'C');
      expect(transposeChord('Cb', 0), 'B');
      expect(transposeChord('Fb', 1), 'F');
      expect(transposeChord('E#', 0), 'F');
      expect(transposeChord('C##', 0), 'D');
      expect(transposeChord('Dbb', 0), 'C');
      expect(transposeChord('Bbm7/Db', 2), 'Cm7/Eb');
      expect(transposeChord('F#m7b5/A', -1), 'Fm7b5/G#');
      expect(transposeChord('N.C.', 5), 'N.C.');
      expect(transposeChord('C', -1), 'B');
      expect(transposeChord('C♯', 1), 'D');
    });

    test('normalizeNameIdentity is the comparison form every caller used', () {
      expect(
        normalizeNameIdentity("  Don’t Stop — Believin'! "),
        'dont stop believin',
      );
      expect(
        normalizeNameIdentity('Beyoncé / JAY‐Z (Live)'),
        'beyoncé jay z live',
      );
      expect(normalizeNameIdentity('...'), '');
      expect(
        librarySongIdentity("Don't Stop", 'Journey'),
        'journey\u0000dont stop',
      );
    });

    test('lyricIdentityWords drops directives, chords and accents', () {
      expect(
        lyricIdentityWords('{soc}\n[Am]Canción d’amor [G]\\[sic]\n{eoc}'),
        ['cancion', 'damor', 'sic'],
      );
    });

    test('foldLyricVowelAccents folds precomposed and combining accents', () {
      expect(foldLyricVowelAccents('ÁéÎöù ñ ç'), 'AeIou ñ ç');
      expect(foldLyricVowelAccents('áËñ'), 'aEñ');
      expect(foldLyricVowelAccents('plain ASCII 123'), 'plain ASCII 123');
    });

    test(
      'recordingIdsConflict is symmetric and ignores unshared namespaces',
      () {
        SongCandidate row(Map<String, String> ids) => SongCandidate(
          providerId: 'p',
          id: '1',
          title: 't',
          artist: 'a',
          recordingIds: ids,
        );
        final a = row({'isrc': 'X', 'mb': '1'});
        final b = row({'isrc': 'Y'});
        final c = row({'spotify': 'Z', 'mb': '1'});
        expect(recordingIdsConflict(a, b), isTrue);
        expect(recordingIdsConflict(b, a), isTrue);
        expect(recordingIdsConflict(a, c), isFalse);
        expect(recordingIdsConflict(c, a), isFalse);
        expect(recordingIdsConflict(row({}), a), isFalse);
      },
    );

    test('display facts read the row, then the source, then row metadata', () {
      const row = SongCandidate(
        providerId: 'p',
        id: '1',
        title: 't',
        artist: 'a',
        metadata: {
          'album': ' Row Meta ',
          'duration': 200,
          'durationSeconds': 0,
        },
      );
      expect(candidateAlbum(row), 'Row Meta');
      expect(candidateAlbum(row, {'album': 'Source'}), 'Source');
      expect(candidateDuration(row), 200);
      expect(candidateDuration(row, {'duration': 201}), 201);
      expect(candidateDuration(row, {'durationSeconds': 199.5}), 199.5);
      for (final invalid in [0, -1, 86401, double.nan, double.infinity, '3']) {
        expect(displaySeconds(invalid), isNull, reason: '$invalid');
      }
      expect(displaySeconds(86400), 86400);
    });
  });

  test('grouping gives the same groups whatever order shares its facts', () {
    SongCandidate row(
      String provider,
      String title, {
      String? album,
      String artist = 'Eric Clapton',
    }) => SongCandidate(
      providerId: provider,
      id: '$provider:$title:$album',
      title: title,
      artist: artist,
      album: album,
    );
    final rows = [
      row('a', 'Layla', album: 'Unplugged'),
      row('b', 'Layla (Acoustic Live)', album: 'Unplugged [Enhanced, HD]'),
      row('c', 'Layla', album: 'Layla and Other Assorted Love Songs'),
      row('d', 'Layla - Remastered 2011'),
      row('e', 'Layla (Live)', album: 'One More Car, One More Rider CD1'),
      row(
        'f',
        'Layla',
        album: 'Eric Clapton - MTV Unplugged',
        artist: 'Clapton, Eric',
      ),
      row('g', 'Layla (Karaoke)'),
    ];
    List<List<String>> shape(Iterable<SongCandidate> ranked) => [
      for (final group in groupSearchRecordings(ranked))
        [for (final member in group.members) member.providerId],
    ];
    final first = shape(rows);
    expect(shape(rows), first, reason: 'no state survives a grouping pass');
    expect(first, [
      ['a', 'b', 'f'],
      ['c', 'd'],
      ['e'],
      ['g'],
    ]);
    for (final a in rows) {
      for (final b in rows) {
        expect(
          sameSearchRecording(a, b),
          sameSearchRecording(b, a),
          reason: '${a.providerId} ${b.providerId}',
        );
      }
    }
  });

  test('compact alignment maps chords through accented and ASCII text', () {
    final target = parseArrangement('La canción de amor que yo canté');
    final chords = compactLineChords(
      target,
      '[Am]La can ción de a[G]mor que yo can[C]té',
    );
    expect(chords.keys, [0]);
    expect(
      [for (final anchor in chords[0]!) (anchor.offset, anchor.chord)],
      [(0, 'Am'), (15, 'G'), (29, 'C')],
    );
  });
}
