import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/search_grouping.dart';

const _art = 'https://images.example/cover.jpg';

SongCandidate _row(
  String providerId, {
  String id = '1',
  String title = 'Sample Song',
  String artist = 'Test Artist',
  String? album,
  double? duration,
  String? artwork,
  JsonMap metadata = const {},
  Map<String, String> recordingIds = const {},
}) => SongCandidate(
  providerId: providerId,
  id: id,
  title: title,
  artist: artist,
  album: album,
  durationSeconds: duration,
  metadata: {...metadata, 'artworkUrl': ?artwork},
  recordingIds: recordingIds,
);

List<List<String>> _ids(List<SearchRecordingGroup> groups) => [
  for (final group in groups) [for (final row in group.members) row.identity],
];

void main() {
  test('one recording from several catalogs becomes one group', () {
    final groups = groupSearchRecordings([
      _row('betterlyrics', album: 'Demo Album', duration: 269),
      _row('genius', artwork: _art),
      _row('lrclib', album: 'demo album', duration: 270),
      _row('other', title: 'Another Song'),
    ], preferredProviderId: 'genius');

    expect(_ids(groups), [
      ['betterlyrics:1', 'genius:1', 'lrclib:1'],
      ['other:1'],
    ]);
    final group = groups.first;
    expect(group.representative.providerId, 'genius');
    expect(group.album, 'Demo Album');
    expect(group.durationSeconds, 269);
    expect(group.artworkUrl, _art);
  });

  test('without the preferred catalog the best ranked row is opened', () {
    final groups = groupSearchRecordings([
      _row('lrclib'),
      _row('lyricsovh'),
    ], preferredProviderId: 'genius');
    expect(groups.single.representative.providerId, 'lrclib');
  });

  test('different albums, editions and recordings stay apart', () {
    final groups = groupSearchRecordings([
      _row('a', album: 'Demo Album', duration: 200),
      _row('b', album: 'Greatest Hits', duration: 200),
      _row('c', album: 'Demo Album', duration: 260),
      _row('d', title: 'Sample Song (Live)'),
      _row('e', metadata: {'version': 'Live'}),
      _row('f', recordingIds: {'isrc': 'A'}),
      _row('g', recordingIds: {'isrc': 'B'}),
      _row('h', artist: 'Someone Else'),
    ]);
    expect(_ids(groups), [
      // Durations do not split one album's recording.
      ['a:1', 'c:1', 'f:1'],
      // g conflicts with f's recording ID, so it joins the next match.
      ['b:1', 'g:1'],
      ['d:1'],
      ['e:1'],
      ['h:1'],
    ]);
  });

  test('a row without album or duration joins the first matching group', () {
    final groups = groupSearchRecordings([
      _row('a', album: 'Demo Album'),
      _row('b', album: 'Greatest Hits'),
      _row('songsterr'),
    ]);
    expect(_ids(groups), [
      ['a:1', 'songsterr:1'],
      ['b:1'],
    ]);
  });

  test('historical text and non-recording rows are never grouped', () {
    final groups = groupSearchRecordings([
      _row('wikisource'),
      _row('wikisource', id: '2'),
      _row('a', metadata: {'identityScope': 'artist'}),
      _row('b', metadata: {'identityScope': 'artist'}),
      _row('c', metadata: {'pendingMatchCheck': true}),
      _row('d', metadata: {'pendingMatchCheck': true}),
      _row('e', title: ''),
      _row('f', title: ''),
    ]);
    expect(groups, hasLength(8));
  });

  test('a chord sheet joins its recording group', () {
    final groups = groupSearchRecordings([
      _row('lrclib', album: 'Demo Album', duration: 200),
      _row('chordie', metadata: {'identityScope': 'arrangement'}),
    ]);
    expect(_ids(groups), [
      ['lrclib:1', 'chordie:1'],
    ]);
  });

  test('only https artwork is shown', () {
    final groups = groupSearchRecordings([
      _row('a', artwork: 'http://images.example/cover.jpg'),
      _row('b', artwork: _art),
    ]);
    expect(groups.single.artworkUrl, _art);
  });

  test('a bracketed credit does not split a recording', () {
    final groups = groupSearchRecordings([
      _row('genius', title: 'Hallelujah'),
      _row('lrclib', title: 'Hallelujah', album: 'Hallelujah', duration: 269),
      _row(
        'lyricsovh',
        title: 'Hallelujah (Leonard Cohen)',
        album: 'Hallelujah - EP',
        duration: 268,
      ),
      _row('songsterr', id: '2', title: 'Hallelujah (Leonard Cohen)'),
      _row('a', title: 'Other (Part 2)'),
      _row('b', title: 'Other'),
    ], preferredProviderId: 'genius');
    expect(_ids(groups), [
      ['genius:1', 'lrclib:1', 'lyricsovh:1', 'songsterr:2'],
      ['a:1'],
      ['b:1'],
    ]);
    expect(groups.first.representative.title, 'Hallelujah');
  });

  test('bracketed editions and parts stay apart; durations do not', () {
    final groups = groupSearchRecordings([
      _row('a', title: 'Never Stop', album: 'Hallelujah', duration: 175),
      _row(
        'b',
        title: 'Never Stop (Wedding Version)',
        album: 'Hallelujah',
        duration: 175,
      ),
      _row('c', title: 'Song', album: 'First Album', duration: 200),
      _row('d', title: 'Song (Leonard Cohen)', duration: 240),
      _row('e', title: 'Song (Reprise)'),
      _row('f', title: 'Song (Leonard Cohen)', album: 'Other Album'),
      _row('g', title: 'Song', album: 'Other Album'),
    ]);
    expect(_ids(groups), [
      ['a:1'],
      ['b:1'],
      ['c:1', 'd:1'],
      ['e:1'],
      ['f:1', 'g:1'],
    ]);
  });

  test('EP and single suffixes do not split one release', () {
    final groups = groupSearchRecordings([
      _row('a', album: 'Hallelujah - EP', duration: 269),
      _row('b', album: 'Hallelujah (Single)', duration: 270),
      _row('c', album: 'Hallelujah', duration: 268),
    ]);
    expect(groups, hasLength(1));
  });
}
