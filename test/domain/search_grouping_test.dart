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

  test('different labels, albums and recordings stay apart', () {
    final groups = groupSearchRecordings([
      _row('a', title: 'Sample Song (Live)', album: 'Demo Album'),
      _row('b', title: 'Sample Song (Acoustic)', album: 'Demo Album'),
      // Without a label, a row joins a labelled group only on a known
      // matching album.
      _row('c', album: 'Demo Album', duration: 260),
      _row('d', album: 'Greatest Hits'),
      // Without label or album, e can only join an unlabelled group.
      _row('e', recordingIds: {'isrc': 'A'}),
      // f conflicts with e's recording ID.
      _row('f', recordingIds: {'isrc': 'B'}),
      _row('g', metadata: {'version': 'Studio'}, album: 'Demo Album'),
      _row('h', artist: 'Someone Else'),
    ]);
    expect(_ids(groups), [
      ['a:1', 'c:1'],
      ['b:1'],
      ['d:1', 'e:1'],
      ['f:1'],
      ['g:1'],
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

  test('arrangements from different providers still group by recording', () {
    final groups = groupSearchRecordings([
      _row('lrclib', album: 'Demo Album', duration: 200),
      _row(
        'chordsandtabs',
        id: '/songs/sample-a',
        metadata: {'identityScope': 'arrangement'},
      ),
      _row(
        'othercharts',
        id: 'chart-1',
        metadata: {'identityScope': 'arrangement'},
      ),
    ]);

    expect(_ids(groups), [
      ['lrclib:1', 'chordsandtabs:/songs/sample-a', 'othercharts:chart-1'],
    ]);
  });

  test('distinct same-provider arrangement identities stay selectable', () {
    final groups = groupSearchRecordings([
      _row(
        'chordsandtabs',
        id: '/songs/hey-jude-7',
        title: 'Hey Jude',
        artist: 'The Beatles',
        metadata: {'identityScope': 'arrangement'},
      ),
      _row(
        'chordsandtabs',
        id: '/songs/hey-jude-8',
        title: 'Hey Jude',
        artist: 'The Beatles',
        metadata: {'identityScope': 'arrangement'},
      ),
    ]);

    expect(_ids(groups), [
      ['chordsandtabs:/songs/hey-jude-7'],
      ['chordsandtabs:/songs/hey-jude-8'],
    ]);
  });

  test('duplicate arrangement identity deduplicates without changing rank', () {
    final groups = groupSearchRecordings([
      _row(
        'chordsandtabs',
        id: '/songs/hey-jude-7',
        title: 'Hey Jude',
        artist: 'The Beatles',
        metadata: {'identityScope': 'arrangement'},
      ),
      _row('lrclib', id: 'lyrics', title: 'Hey Jude', artist: 'The Beatles'),
      _row(
        'chordsandtabs',
        id: '/songs/hey-jude-7',
        title: 'Hey Jude',
        artist: 'The Beatles',
        metadata: {'identityScope': 'arrangement'},
      ),
    ]);

    expect(_ids(groups), [
      ['chordsandtabs:/songs/hey-jude-7', 'lrclib:lyrics'],
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

  test('parts, reprises and instrumentals stay apart', () {
    final groups = groupSearchRecordings([
      _row('a', title: 'Song', album: 'First Album', duration: 200),
      _row('b', title: 'Song (Leonard Cohen)', duration: 240),
      _row('c', title: 'Song - Remastered 2011'),
      _row('d', title: 'Song (Wedding Version)'),
      _row('e', title: 'Song (Reprise)'),
      _row('f', title: 'Song (Part 2)'),
      _row('g', title: 'Song (Instrumental)'),
      _row('h', title: 'Song', album: 'Other Album'),
    ]);
    expect(_ids(groups), [
      ['a:1', 'b:1', 'c:1'],
      // A labelled edition without an album is not folded into the album.
      ['d:1'],
      ['e:1'],
      ['f:1'],
      ['g:1'],
      ['h:1'],
    ]);
  });

  test('album name variants of one release match', () {
    final albums = [
      'Eric Clapton Unplugged',
      'Eric Clapton - MTV Unplugged',
      'Clapton Chronicles: Unplugged',
      'Eric Clapton Unplugged [Enhanced, HD]',
      'Unplugged [MFSL] [SACD]  (Live) [HD]',
      'Unplugged (Remastered Deluxe Edition) CD1',
      'Unplugged (Live)',
    ];
    final groups = groupSearchRecordings([
      for (final (index, album) in albums.indexed)
        _row(
          'p$index',
          title: index.isEven
              ? 'Lonely Stranger'
              : 'Lonely Stranger (Acoustic Live)',
          artist: 'Eric Clapton',
          album: album,
        ),
      _row(
        'inverted',
        title: 'Lonely Stranger',
        artist: 'Clapton, Eric',
        album: 'eric clapton unplugged',
      ),
      _row(
        'other',
        title: 'Lonely Stranger',
        artist: 'Eric Clapton',
        album: 'Pilgrim',
      ),
    ]);
    expect(groups.map((group) => group.members.length), [8, 1]);
    expect(
      sameSearchRecording(
        _row(
          'a',
          title: 'Lonely Stranger',
          artist: 'Eric Clapton',
          album: 'Clapton Chronicles: Unplugged',
        ),
        _row(
          'b',
          title: 'Lonely Stranger (Acoustic Live)',
          artist: 'Eric Clapton',
          album: 'Unplugged (Deluxe Edition) (Live)',
        ),
      ),
      isTrue,
    );
  });

  test('an album links labelled and unlabelled rows in any order', () {
    final groups = groupSearchRecordings([
      _row(
        'genius',
        title: 'Lonely Stranger (Acoustic Live)',
        artist: 'Eric Clapton',
      ),
      // No label or album: it meets the release through the LRCLIB row.
      _row('ultimateguitar', title: 'Lonely Stranger', artist: 'Eric Clapton'),
      // "Acoustic" fits within "Acoustic Live".
      _row(
        'ug-acoustic',
        title: 'Lonely Stranger',
        artist: 'Eric Clapton',
        metadata: {'recording': 'Acoustic'},
      ),
      _row(
        'lrclib',
        title: 'Lonely Stranger',
        artist: 'Eric Clapton',
        album: 'Eric Clapton Unplugged',
      ),
      _row(
        'youtubemusic',
        title: 'Lonely Stranger (Acoustic Live)',
        artist: 'Eric Clapton',
        album: 'Unplugged (Live)',
      ),
      _row('studio', title: 'Amazing Grace', artist: 'Judy Collins'),
      _row('live', title: 'Amazing Grace (Live)', artist: 'Judy Collins'),
    ], preferredProviderId: 'genius');
    expect(_ids(groups), [
      [
        'genius:1',
        'ultimateguitar:1',
        'ug-acoustic:1',
        'lrclib:1',
        'youtubemusic:1',
      ],
      // Without albums, a live take is not folded into the studio row.
      ['studio:1'],
      ['live:1'],
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
