import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/metadata_enrichment.dart';
import 'package:singbook/domain/models.dart';

const _art = 'https://images.example/cover.jpg';

SongCandidate _song(
  String providerId, {
  String title = 'Sample Song',
  String artist = 'Test Artist',
  String? album,
  double? duration,
  String? artwork,
  JsonMap metadata = const {},
  Map<String, String> recordingIds = const {},
}) => SongCandidate(
  providerId: providerId,
  id: providerId,
  title: title,
  artist: artist,
  album: album,
  durationSeconds: duration,
  metadata: {...metadata, 'artworkUrl': ?artwork},
  recordingIds: recordingIds,
);

void main() {
  test('fills missing album, duration and artwork from the same song', () {
    final display = displayMetadataFor(_song('genius', artwork: _art), [
      _song('lrclib', album: 'Demo Album', duration: 201),
    ]);
    expect(display.album, 'Demo Album');
    expect(display.durationSeconds, 201);
    expect(display.artworkUrl, _art);
    expect(display.isComplete, isTrue);
  });

  test('never replaces facts the result already has', () {
    final display = displayMetadataFor(
      _song('lrclib', album: 'Demo Album', duration: 200),
      [_song('lyricsovh', album: 'demo album', duration: 202, artwork: _art)],
    );
    expect(display.album, 'Demo Album');
    expect(display.durationSeconds, 200);
    expect(display.artworkUrl, _art);
  });

  test('skips other songs, versions, albums, durations and recordings', () {
    final target = _song(
      'lrclib',
      album: 'Demo Album',
      duration: 200,
      recordingIds: {'isrc': 'A'},
    );
    final display = displayMetadataFor(target, [
      _song('a', title: 'Another Song', artwork: _art),
      _song('b', artist: 'Someone Else', artwork: _art),
      _song('c', title: 'Sample Song (Live)', artwork: _art),
      _song('d', album: 'Greatest Hits', artwork: _art),
      _song('e', duration: 260, artwork: _art),
      _song('f', artwork: _art, recordingIds: {'isrc': 'B'}),
      _song('g', artwork: _art, metadata: {'identityScope': 'image'}),
    ]);
    expect(display.artworkUrl, isNull);
  });

  test('keeps artwork and duration with the first known release', () {
    final display = displayMetadataFor(_song('genius'), [
      _song('lrclib', album: 'Demo Album', duration: 200),
      _song('youtube', album: 'Greatest Hits', duration: 200, artwork: _art),
      _song('lyricsovh', album: 'Demo Album', artwork: '$_art?demo'),
    ]);
    expect(display.album, 'Demo Album');
    expect(display.artworkUrl, '$_art?demo');
  });

  test('prefers donors from the result\'s own album', () {
    final display = displayMetadataFor(_song('lrclib', album: 'Demo Album'), [
      _song('genius', artwork: '$_art?song'),
      _song('lyricsovh', album: 'Demo Album', artwork: '$_art?album'),
    ]);
    expect(display.artworkUrl, '$_art?album');
  });

  test('ignores artwork that is not an https URL', () {
    final display = displayMetadataFor(
      _song('genius', artwork: 'http://images.example/cover.jpg'),
    );
    expect(display.artworkUrl, isNull);
  });
}
