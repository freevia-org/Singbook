import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/published_name_alias.dart';

const _selected = SongCandidate(
  providerId: 'genius',
  id: 'native-song',
  title: '上を向いて歩こう (SUKIYAKI)',
  artist: '坂本九 (Kyu Sakamoto)',
);

const _latinSource = SongCandidate(
  providerId: 'chordsandtabs',
  id: 'latin-chart',
  title: 'Sukiyaki',
  artist: 'Kyu Sakamoto',
);

const _nativeLyrics =
    '青い雨が静かな窓を叩く\n'
    '遠い灯りが川辺に揺れる\n'
    '白い船が朝の霧を進む\n'
    '小さな庭に夏の花が咲く';

const _latinLyrics =
    'Aoi ame ga shizuka na mado wo tataku\n'
    'Tooi akari ga kawabe ni yureru\n'
    'Shiroi fune ga asa no kiri wo susumu\n'
    'Chiisana niwa ni natsu no hana ga saku';

void main() {
  test('accepts only an explicitly published Latin alias', () {
    expect(publishedNameVariants('上を向いて歩こう (SUKIYAKI)'), [
      '上を向いて歩こう (SUKIYAKI)',
      'SUKIYAKI',
    ]);
    expect(publishedNamesMatch('上を向いて歩こう (SUKIYAKI)', 'Sukiyaki'), isTrue);
    expect(publishedNamesMatch('坂本九 (Kyu Sakamoto)', 'Kyu Sakamoto'), isTrue);
    expect(publishedNamesMatch('坂本九', 'Kyu Sakamoto'), isFalse);
  });

  test('does not treat qualifiers or Latin-only parentheses as aliases', () {
    for (final qualifier in [
      'Version',
      'Live',
      'Acoustic',
      'Translation',
      'Translated',
      'feat. Kyu Sakamoto',
      'Remix',
    ]) {
      final name = '上を向いて歩こう ($qualifier)';
      expect(publishedNameVariants(name), [name], reason: qualifier);
    }
    for (final name in [
      'Sukiyaki (Kyu Sakamoto)',
      '上を向いて歩こう (すきやき)',
      '上を向いて歩こう (Sukiyaki) live',
    ]) {
      expect(publishedNameVariants(name), [name], reason: name);
    }
  });

  test('accepts a matching Latin-script lyric representation', () {
    expect(
      publishedLyricScriptAlternative(
        _selected,
        _latinSource,
        _nativeLyrics,
        _latinLyrics,
      ),
      isTrue,
    );
  });

  test(
    'script alternative requires aliases, matching identity, and scripts',
    () {
      final cases = <(String, SongCandidate, SongCandidate, String, String)>[
        (
          'no published alias',
          _selected,
          const SongCandidate(
            providerId: 'genius',
            id: 'unaliased',
            title: '上を向いて歩こう',
            artist: '坂本九 (Kyu Sakamoto)',
          ),
          _nativeLyrics,
          _latinLyrics,
        ),
        (
          'different performer',
          _selected,
          const SongCandidate(
            providerId: 'chordsandtabs',
            id: 'wrong-performer',
            title: 'Sukiyaki',
            artist: '別の歌手 (Another Singer)',
          ),
          _nativeLyrics,
          _latinLyrics,
        ),
        (
          'conflicting recording identifiers',
          const SongCandidate(
            providerId: 'genius',
            id: 'selected-isrc',
            title: '上を向いて歩こう (SUKIYAKI)',
            artist: '坂本九 (Kyu Sakamoto)',
            recordingIds: {'isrc': 'USAAA0000001'},
          ),
          const SongCandidate(
            providerId: 'chordsandtabs',
            id: 'wrong-isrc',
            title: 'Sukiyaki',
            artist: 'Kyu Sakamoto',
            recordingIds: {'isrc': 'USAAA0000002'},
          ),
          _nativeLyrics,
          _latinLyrics,
        ),
        (
          'conflicting editions',
          const SongCandidate(
            providerId: 'genius',
            id: 'selected-studio',
            title: '上を向いて歩こう (SUKIYAKI)',
            artist: '坂本九 (Kyu Sakamoto)',
            album: 'Studio Album',
          ),
          const SongCandidate(
            providerId: 'chordsandtabs',
            id: 'live-edition',
            title: 'Sukiyaki',
            artist: 'Kyu Sakamoto',
            album: 'Live at Harbor',
          ),
          _nativeLyrics,
          _latinLyrics,
        ),
        (
          'both lyric bodies are already Latin script',
          _selected,
          _latinSource,
          _latinLyrics,
          'A different invented refrain uses unrelated words for every line',
        ),
        (
          'translation qualifier is not a published song-title alias',
          const SongCandidate(
            providerId: 'genius',
            id: 'translation-label',
            title: '上を向いて歩こう (English Translation)',
            artist: '坂本九 (Kyu Sakamoto)',
          ),
          const SongCandidate(
            providerId: 'chordsandtabs',
            id: 'latin-chart',
            title: 'Sukiyaki',
            artist: 'Kyu Sakamoto',
          ),
          _nativeLyrics,
          _latinLyrics,
        ),
      ];

      for (final (reason, selected, source, referenceBody, sourceBody)
          in cases) {
        expect(
          publishedLyricScriptAlternative(
            selected,
            source,
            referenceBody,
            sourceBody,
          ),
          isFalse,
          reason: reason,
        );
      }
    },
  );
}
