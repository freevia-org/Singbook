import 'edition_identity.dart';
import 'models.dart';

String _identity(String value) => value
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

String? _album(SongCandidate candidate) {
  for (final value in [candidate.album, candidate.metadata['album']]) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

double? _seconds(Object? value) {
  if (value is! num) return null;
  final seconds = value.toDouble();
  return seconds.isFinite && seconds > 0 && seconds <= 86400 ? seconds : null;
}

double? _duration(SongCandidate candidate) =>
    _seconds(candidate.durationSeconds) ??
    _seconds(candidate.metadata['durationSeconds']) ??
    _seconds(candidate.metadata['duration']);

String? _artwork(SongCandidate candidate) {
  final value = candidate.metadata['artworkUrl'];
  final uri = value is String ? Uri.tryParse(value.trim()) : null;
  return uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? (value as String).trim()
      : null;
}

/// Words that only describe a release's packaging or format, so
/// "Unplugged (Remastered Deluxe Edition) CD1" names the same album as
/// "Unplugged".
const _albumNoise = {
  'the',
  'a',
  'an',
  'and',
  'of',
  'deluxe',
  'edition',
  'expanded',
  'remaster',
  'remastered',
  'anniversary',
  'enhanced',
  'hd',
  'explicit',
  'bonus',
  'version',
  'ep',
  'single',
  'mtv',
};

/// Album words without bracketed qualifiers ("[HD]", "(Deluxe Edition)"),
/// disc numbers, packaging words or the artist's own name.
Set<String> _albumWords(String album, String artist) {
  final artistWords = _identity(artist).split(' ').toSet();
  return _identity(album.replaceAll(RegExp(r'[(\[][^()\[\]]*[)\]]'), ' '))
      .split(' ')
      .where(
        (word) =>
            word.isNotEmpty &&
            !_albumNoise.contains(word) &&
            !artistWords.contains(word) &&
            !RegExp(r'^(?:cd|disc|disk)\d*$').hasMatch(word),
      )
      .toSet();
}

/// Albums match when either is unknown or one's words contain the other's:
/// "Eric Clapton - MTV Unplugged", "Clapton Chronicles: Unplugged" and
/// "Unplugged [Enhanced, HD]" all contain "Unplugged".
bool _albumsCompatible(String? a, String? b, String artist) {
  if (a == null || b == null) return true;
  final first = _albumWords(a, artist), second = _albumWords(b, artist);
  if (first.isEmpty || second.isEmpty) return true;
  return first.length <= second.length
      ? second.containsAll(first)
      : first.containsAll(second);
}

/// Bracket or dash qualifiers that name a different song or a recording
/// without the sung lyrics. These stay part of the title.
final _distinctWords = RegExp(
  r'\b(?:part|pt|reprise|interlude|intro|outro|medley|vol(?:ume)?|instrumental|karaoke)\b',
  caseSensitive: false,
);

/// Edition qualifiers: rows with different labels stay apart, while a row
/// without any label may join a labelled group, as absence is unknown.
final _editionWord = RegExp(
  r'\b(?:live|acoustic|remix|demo|remaster(?:ed)?|mix|edit|mono|stereo|session|unplugged|cover|studio|version)\b',
  caseSensitive: false,
);

/// Edition words that do not distinguish a recording: "(Album Version)",
/// "- Remastered 2011" and "(Radio Edit)" keep only their telling words.
const _labelIgnore = {
  'version',
  'remaster',
  'remastered',
  'album',
  'original',
  'single',
  'digital',
  'edit',
  'the',
  'a',
};

final _qualifier = RegExp(r'\s*[(\[]([^()\[\]]*)[)\]]|\s+[-–—]\s+(.+)$');

/// Title identity without credits ("(Leonard Cohen)", "(feat. Someone)") or
/// edition qualifiers ("(Acoustic Live)", "- Remastered 2011"). Parts,
/// reprises, instrumentals and karaoke stay, as they name another recording.
String _baseTitle(String title) => _identity(
  title.replaceAllMapped(_qualifier, (match) {
    final inner = match[1] ?? match[2]!;
    return _distinctWords.hasMatch(inner) ? match[0]! : '';
  }),
);

/// Telling words of edition qualifiers in the title and of version, edition
/// or recording fields: "(Acoustic Live)" gives {acoustic, live}, "(Wedding
/// Version)" gives {wedding}, "- Remastered 2011" gives none.
Set<String> _labels(SongCandidate candidate) {
  final labels = <String>{};
  void add(String text) {
    if (!_editionWord.hasMatch(text)) return;
    for (final word in _identity(text).split(' ')) {
      if (word.isNotEmpty &&
          !_labelIgnore.contains(word) &&
          !RegExp(r'^\d+$').hasMatch(word)) {
        labels.add(word);
      }
    }
  }

  for (final match in _qualifier.allMatches(candidate.title)) {
    add(match[1] ?? match[2]!);
  }
  for (final map in [candidate.metadata, candidate.extra]) {
    for (final key in ['version', 'edition', 'recording']) {
      if (map[key] is String) add(map[key] as String);
    }
  }
  return labels;
}

/// Whether two non-empty label sets name one edition: one contains the other,
/// so "Acoustic" fits "Acoustic Live" while "Live" and "Acoustic" stay apart.
bool _labelsMatch(Set<String> a, Set<String> b) =>
    a.isNotEmpty && b.isNotEmpty && (a.containsAll(b) || b.containsAll(a));

/// Whether two rows' labels and albums allow one recording. Matching labels
/// (or none on either side) need only compatible albums. A labelled and an
/// unlabelled row ("Lonely Stranger (Acoustic Live)" and "Lonely Stranger")
/// also need both albums known and matching, so a live take is not folded
/// into a studio row on title alone. Disjoint labels never match.
bool _factsCompatible(
  Set<String> labels,
  String? album,
  Set<String> otherLabels,
  String? otherAlbum,
  String artist,
) {
  final equal =
      (labels.isEmpty && otherLabels.isEmpty) ||
      _labelsMatch(labels, otherLabels);
  if (!equal && labels.isNotEmpty && otherLabels.isNotEmpty) return false;
  if (!equal && (album == null || otherAlbum == null)) return false;
  return _albumsCompatible(album, otherAlbum, artist);
}

bool _idsConflict(SongCandidate a, SongCandidate b) =>
    a.recordingIds.entries.any(
      (e) =>
          b.recordingIds.containsKey(e.key) && b.recordingIds[e.key] != e.value,
    );

bool _isArrangement(SongCandidate candidate) =>
    candidate.metadata['identityScope'] == 'arrangement' ||
    candidate.extra['identityScope'] == 'arrangement';

/// Distinct charts from one provider are separate selectable arrangements,
/// even when their title and artist describe the same song.
bool _arrangementIdsConflict(SongCandidate a, SongCandidate b) =>
    a.providerId == b.providerId &&
    _isArrangement(a) &&
    _isArrangement(b) &&
    a.id != b.id;

/// Artist identity as a sorted word set, so "Clapton, Eric" and "Eric
/// Clapton" match.
String _artistKey(String artist) =>
    (_identity(artist).split(' ')
          ..removeWhere((w) => w.isEmpty)
          ..sort())
        .join(' ');

String? _titleKey(SongCandidate row) {
  final artist = _artistKey(row.artist);
  final base = _baseTitle(row.title);
  final title = base.isNotEmpty ? base : _identity(row.title);
  return _ungroupable(row) || title.isEmpty || artist.isEmpty
      ? null
      : '$title\u0000$artist';
}

/// Whether two search rows name the same recording by the rules
/// [groupSearchRecordings] uses. The artwork lookup uses it to accept a hit.
bool sameSearchRecording(SongCandidate a, SongCandidate b) {
  final key = _titleKey(a);
  return key != null &&
      key == _titleKey(b) &&
      _factsCompatible(
        _labels(a),
        _album(a),
        _labels(b),
        _album(b),
        a.artist,
      ) &&
      !_idsConflict(a, b) &&
      explicitEditionsCompatible(a, b);
}

/// Rows that never join a group: they name something other than one
/// recording, or still await a match check. A chord sheet ("arrangement")
/// may join the recording group of its song.
bool _ungroupable(SongCandidate candidate) {
  const scopes = {'historicalText', 'composition', 'work', 'artist', 'image'};
  return candidate.providerId == 'wikisource' ||
      scopes.contains(candidate.metadata['identityScope']) ||
      scopes.contains(candidate.extra['identityScope']) ||
      candidate.metadata['pendingMatchCheck'] == true ||
      candidate.extra['pendingMatchCheck'] == true;
}

/// One recording found by one or more catalogs in a search.
class SearchRecordingGroup {
  SearchRecordingGroup._(this.members, this.representative);

  /// Every row of this recording, in search rank order.
  final List<SongCandidate> members;

  /// The row opened for the group: the preferred catalog's row when the
  /// group has one, otherwise the best ranked row.
  final SongCandidate representative;

  /// Display facts: the representative's own value, else the first member's.
  /// Members never disagree on a known album (see [groupSearchRecordings]);
  /// catalogs may report slightly different durations for one recording.
  String? get album =>
      _album(representative) ?? members.map(_album).nonNulls.firstOrNull;
  double? get durationSeconds =>
      _duration(representative) ?? members.map(_duration).nonNulls.firstOrNull;
  String? get artworkUrl =>
      _artwork(representative) ?? members.map(_artwork).nonNulls.firstOrNull;

  /// The row a tap opens: the representative with the album and length the
  /// row shows.
  SongCandidate get selection => withRowFacts(
    representative,
    album: album,
    durationSeconds: durationSeconds,
  );
}

/// Metadata keys holding a search row's displayed album and length, read
/// only when the combined song states none of its own.
const rowAlbumKey = 'searchRowAlbum', rowDurationKey = 'searchRowDuration';

/// [candidate] with a search row's displayed [album] and [durationSeconds]
/// where it has none of its own, so the opened song keeps the facts shown in
/// search. A group's members never disagree on a known album. They are
/// display facts only: discovery and matching never read them, as another
/// member's album or length is not this row's identity.
SongCandidate withRowFacts(
  SongCandidate candidate, {
  String? album,
  double? durationSeconds,
}) {
  final addAlbum = _album(candidate) == null && album != null;
  final addDuration =
      _duration(candidate) == null && _seconds(durationSeconds) != null;
  if (!addAlbum && !addDuration) return candidate;
  return SongCandidate(
    providerId: candidate.providerId,
    id: candidate.id,
    title: candidate.title,
    artist: candidate.artist,
    album: candidate.album,
    durationSeconds: candidate.durationSeconds,
    url: candidate.url,
    metadata: {
      ...candidate.metadata,
      rowAlbumKey: ?(addAlbum ? album : null),
      rowDurationKey: ?(addDuration ? durationSeconds : null),
    },
    recordingIds: candidate.recordingIds,
    extra: candidate.extra,
  );
}

class _Group {
  _Group(this.key, SongCandidate row, int index) {
    add(row, index);
  }

  /// Title without credits or edition qualifiers, and artist; null for a row
  /// kept alone.
  final String? key;
  final members = <({SongCandidate row, int index})>[];
  String? album;
  Set<String> labels = const {};

  int get first => members.first.index;

  void add(SongCandidate row, int index) {
    if (_isArrangement(row) &&
        members.any(
          (member) =>
              _isArrangement(member.row) &&
              member.row.providerId == row.providerId &&
              member.row.id == row.id,
        )) {
      return;
    }
    members.add((row: row, index: index));
    album ??= _album(row);
    // Every member's label fits within the union, the group's most specific
    // edition.
    labels = {...labels, ..._labels(row)};
  }

  bool compatibleWith(SongCandidate row) => !members.any(
    (member) =>
        _idsConflict(member.row, row) ||
        _arrangementIdsConflict(member.row, row) ||
        !explicitEditionsCompatible(member.row, row),
  );

  bool accepts(SongCandidate row) =>
      _factsCompatible(labels, album, _labels(row), _album(row), row.artist) &&
      compatibleWith(row);

  bool canMerge(_Group other, {required bool mixLabels}) =>
      other.key == key &&
      (mixLabels ||
          (labels.isEmpty && other.labels.isEmpty) ||
          _labelsMatch(labels, other.labels)) &&
      _factsCompatible(
        labels,
        album,
        other.labels,
        other.album,
        members.first.row.artist,
      ) &&
      other.members.every((member) => compatibleWith(member.row));
}

/// Collapses search rows that name the same recording into one group, keeping
/// the rows' rank order (a group sits where its best ranked row was).
///
/// Rows join a group when their title and artist match, ignoring credits and
/// edition qualifiers in the title, and their albums match or one is unknown.
/// Album names match loosely: packaging qualifiers, disc numbers and the
/// artist's name are ignored, and one album's words may contain the other's.
/// Edition labels ("Live", "Acoustic") must agree when both rows have one; a
/// row without a label joins a labelled group only when both albums are known
/// and match. Parts, reprises, instrumentals and karaoke stay apart, as do
/// conflicting recording IDs.
/// Durations never split a group: catalogs report one recording with
/// different lengths. A row without an album joins the first matching group.
///
/// Grouping only shapes the list: every row keeps its identity, and the
/// representative is what a tap opens. Historical text and non-recording
/// scopes stay alone; a chord sheet may join its song's group.
List<SearchRecordingGroup> groupSearchRecordings(
  Iterable<SongCandidate> ranked, {
  String? preferredProviderId,
}) {
  final groups = <_Group>[];
  var index = 0;
  for (final row in ranked) {
    final key = _titleKey(row);
    final group = key == null
        ? null
        : groups
              .where((group) => group.key == key && group.accepts(row))
              .firstOrNull;
    if (group != null) {
      group.add(row, index++);
    } else {
      groups.add(_Group(key, row, index++));
    }
  }
  // Rows can arrive in any order. First join groups with the same labels,
  // so album-less rows meet their release; then let a known matching album
  // link labelled and unlabelled groups. Earlier groups absorb later ones.
  for (final mixLabels in const [false, true]) {
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].key == null) continue;
      for (var j = i + 1; j < groups.length; j++) {
        if (!groups[i].canMerge(groups[j], mixLabels: mixLabels)) continue;
        for (final member in groups[j].members) {
          groups[i].add(member.row, member.index);
        }
        groups.removeAt(j);
        j = i;
      }
    }
  }
  return [
    for (final group in groups..sort((a, b) => a.first.compareTo(b.first)))
      () {
        final members = [
          for (final member
              in group.members..sort((a, b) => a.index.compareTo(b.index)))
            member.row,
        ];
        return SearchRecordingGroup._(
          List.unmodifiable(members),
          members
                  .where((member) => member.providerId == preferredProviderId)
                  .firstOrNull ??
              members.first,
        );
      }(),
  ];
}

final _searchToken = RegExp(r'[\p{L}\p{N}]+', unicode: true);

Set<String> _searchTokens(String text) =>
    _searchToken.allMatches(text.toLowerCase()).map((m) => m[0]!).toSet();

/// Words in a title's qualifier ("(Piano Version)", "- Karaoke") that mark
/// another performance than the original recording.
const _otherPerformanceWords = {
  'instrumental',
  'karaoke',
  'cover',
  'tribute',
  'remix',
  'lullaby',
  'acapella',
  'nightcore',
  'sped',
  'slowed',
  'piano',
  'backing',
  'originally',
  'translation',
  'traducción',
  'traduction',
  'tradução',
  'übersetzung',
  'romanized',
};

/// Words in an artist name that mark a tribute, karaoke or lullaby act.
const _otherPerformerWords = {
  'karaoke',
  'tribute',
  'lullaby',
  'covers',
  'instrumental',
};

const _artistStopWords = {'the', 'and', 'a'};

/// How well [candidate] answers a search for [query]; higher is better.
///
/// Each query word counts once, whether the title or the artist has it;
/// a word only in the title's qualifier counts half unless the artist also
/// matched, so a credit does not make another singer's cover a match. Title
/// words the query lacks
/// count against a row; artist words the query
/// lacks count only when the artist matched at all, so a query without an
/// artist does not favour short names. A cover, karaoke track, translation
/// page or other performance the query did not ask for ranks well below the
/// original: "Let It Be (Beatles Instrumental Version)" by another act must
/// not outrank "Let It Be" by The Beatles for "let it be beatles".
int searchRelevance(SongCandidate candidate, String query) {
  final tokens = _searchTokens(query);
  if (tokens.isEmpty) return 0;
  final title = _searchTokens(candidate.title.replaceAll(_qualifier, ' '));
  final qualifiers = <String>{
    for (final match in _qualifier.allMatches(candidate.title))
      ..._searchTokens(match[1] ?? match[2]!),
  };
  final artist = _searchTokens(candidate.artist);
  final artistMatched = artist.any(tokens.contains);
  // A qualifier may be a subtitle ("Lanterns (Over Quiet Water)") or a
  // credit ("Imagine (John Lennon)" by another singer). It counts fully when
  // the artist matched the query too, half otherwise; a performance word the
  // query asks for ("karaoke") always counts.
  var score = 0;
  for (final token in tokens) {
    if (title.contains(token) || artist.contains(token)) {
      score += 4;
    } else if (qualifiers.contains(token)) {
      score += artistMatched || _otherPerformanceWords.contains(token) ? 4 : 2;
    }
  }
  score -=
      title.difference(tokens).length +
      qualifiers.difference(tokens).difference(title).length;
  if (artistMatched) {
    score -= artist.difference(tokens).difference(_artistStopWords).length;
  }
  score -=
      4 *
      {
        ...qualifiers.where(_otherPerformanceWords.contains),
        ...artist.where(_otherPerformerWords.contains),
      }.where((word) => !tokens.contains(word)).length;
  if (_translationAccount(candidate.artist) && !tokens.contains('genius')) {
    score -= 8;
  }
  return score;
}

/// Genius publishes translations under accounts such as "Genius English
/// Translations" or "Genius Romanizations"; "Perfume Genius" is an artist.
bool _translationAccount(String artist) {
  final words = artist.toLowerCase().split(RegExp(r'\s+'));
  return words.length > 1 &&
      words.first == 'genius' &&
      words.skip(1).any((word) => _translationStem.hasMatch(word));
}

final _translationStem = RegExp(
  r'^(?:transl|tradu|übersetz|roman|prevod|çeviri|tłumacz|перевод|vertal|översätt|oversæt|overset|käänn|fordít|preklad|překlad|terjemah|dịch|번역|翻訳|翻译)',
);
