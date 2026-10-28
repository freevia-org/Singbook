import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/providers/core/service.dart' show sameSong;

// Original fixture text; no provider lyrics are stored in the repository.
const _lyrics =
    'Amber lanterns glow above the quiet harbor\n'
    'Silver rain returns across the sleepy water\n'
    'Morning brings another distant melody';
const _chart = '[Em]Amber lanterns glow above the quiet harbor';
const _selected = SongCandidate(
  providerId: 'catalog',
  id: 'song',
  title: 'It’s Probably Me',
  artist: 'Sting',
);

SourceResult _source(
  String provider,
  String body, {
  String title = 'It’s Probably Me',
  String artist = 'Sting',
  MatchKind kind = MatchKind.sameSong,
  JsonMap metadata = const {},
}) => SourceResult(
  candidate: SongCandidate(
    providerId: provider,
    id: 'song',
    title: title,
    artist: artist,
  ),
  body: body,
  matchKind: kind,
  metadata: metadata,
);

void main() {
  for (final title in [
    "It's Probably Me",
    'Its Probably Me',
    'It‘s Probably Me',
  ]) {
    test('Combined includes chords discovery accepted for $title', () {
      final donor = _source('chart', _chart, title: title);
      expect(sameSong(_selected, donor.candidate), isTrue);
      final song = combineSources(_selected, [
        _source('lyrics', _lyrics),
        donor,
      ]);
      expect(plainLyrics(song.body), _lyrics);
      expect(song.body, contains(_chart));
      expect(song.extra['chordSourceIds'], [donor.id]);
      expect(contributingProviderIds(song), contains('chart'));
      final restored = ChordProCodec().decode(ChordProCodec().encode(song));
      expect(restored.body, song.body);
      expect(restored.hasChords, isTrue);
      expect(restored.extra['chordSourceIds'], [donor.id]);
    });
  }

  test('artist apostrophe variants use the same discovery identity', () {
    const selected = SongCandidate(
      providerId: 'catalog',
      id: 'song',
      title: 'Song',
      artist: 'Artist’s Band',
    );
    final donor = _source(
      'chart',
      _chart,
      title: 'Song',
      artist: 'Artists Band',
    );
    expect(sameSong(selected, donor.candidate), isTrue);
    final song = combineSources(selected, [
      _source('lyrics', _lyrics, title: 'Song', artist: 'Artist’s Band'),
      donor,
    ]);
    expect(song.hasChords, isTrue);
    expect(song.extra['chordSourceIds'], [donor.id]);
  });

  test(
    'complete chart retains every chord and instrumental row in Combined',
    () {
      const chart =
          '{comment: Intro}\n[Em] [Am] [B7]\n'
          '[Em]Amber lanterns glow above the quiet [Am]harbor\n'
          '[D]Silver rain returns across the sleepy [G]water\n'
          '[C]Morning brings another distant [B7]melody\n'
          '{comment: Outro}\n[Em] [Am] [B7] [Em]';
      final lyrics = _source('lyrics', _lyrics);
      final donor = _source('chart', chart, title: 'Its Probably Me');
      for (final sources in [
        [lyrics, donor],
        [donor, lyrics],
      ]) {
        final song = combineSources(_selected, sources);
        expect(song.body, chart);
        expect(plainLyrics(song.body), _lyrics);
        expect(song.extra['chordSourceIds'], [donor.id]);
        expect(song.extra['selectedSourceId'], donor.id);
      }
    },
  );

  test('apostrophe normalization does not join hyphenated words', () {
    const selected = SongCandidate(
      providerId: 'catalog',
      id: 'song',
      title: 'A-B',
      artist: 'Sting',
    );
    final song = combineSources(selected, [
      _source('lyrics', _lyrics, title: 'A-B'),
      _source('chart', _chart, title: 'AB'),
    ]);
    expect(song.body, _lyrics);
    expect(song.hasChords, isFalse);
  });

  test(
    'normalization does not erase meaningful word boundaries or identity',
    () {
      for (final donor in [
        _source('other-word', _chart, title: 'It s Probably Me'),
        _source('other-title', _chart, title: 'Probably Me'),
        _source('other-artist', _chart, artist: 'Another Artist'),
        _source(
          'rejected',
          _chart,
          title: 'Its Probably Me',
          kind: MatchKind.rejected,
        ),
      ]) {
        final song = combineSources(_selected, [
          _source('lyrics', _lyrics),
          donor,
        ]);
        expect(song.body, _lyrics);
        expect(song.hasChords, isFalse);
        expect(song.extra['chordSourceIds'], isNull);
      }
    },
  );

  test('apostrophe compatibility ranks a coherent chart setup and retains alternatives', () {
    final song = combineSources(_selected, [
      _source('lyrics', _lyrics, metadata: {'key': 'D', 'capo': 2}),
      _source(
        'chart',
        _chart,
        title: 'Its Probably Me',
        metadata: {'key': 'Em', 'capo': 0},
      ),
    ]);
    expect(song.body, '[Em]$_lyrics');
    expect(song.hasChords, isTrue);
    expect(song.metadata['key'], 'Em');
    expect(song.metadata['capo'], 0);
    final ranking = song.extra['evidenceRanking'] as Map;
    final claims = ranking['claims'] as List;
    expect(
      claims.any((claim) =>
          claim['field'] == 'metadata.key' && claim['value'] == 'Em'),
      isTrue,
    );
    expect(
      claims.any((claim) =>
          claim['field'] == 'metadata.key' && claim['value'] == 'D'),
      isTrue,
    );
    expect(
      (ranking['appliedFields'] as Map)['metadata.key']['value'],
      'Em',
    );
  });

  test('explicit lyrics version remains the chosen version', () {
    final lyrics = _source('lyrics', _lyrics);
    final song = combineSources(_selected, [
      lyrics,
      _source('chart', _chart, title: 'Its Probably Me'),
    ], preferredSourceId: lyrics.id);
    expect(song.body, _lyrics);
    expect(song.hasChords, isFalse);
  });

  test('edition and recording checks still apply to apostrophe variants', () {
    const selected = SongCandidate(
      providerId: 'catalog',
      id: 'song',
      title: 'It’s Probably Me',
      artist: 'Sting',
      durationSeconds: 240,
      recordingIds: {'isrc': 'recording-a'},
    );
    final live = _source('chart', _chart, title: 'Its Probably Me (Live)');
    expect(recordingCompatible(selected, live), isFalse);
    final conflict = SourceResult(
      candidate: const SongCandidate(
        providerId: 'chart',
        id: 'song',
        title: 'Its Probably Me',
        artist: 'Sting',
        durationSeconds: 240,
        recordingIds: {'isrc': 'recording-b'},
      ),
      body: _chart,
      matchKind: MatchKind.sameRecording,
    );
    expect(recordingCompatible(selected, conflict), isFalse);
  });
}
