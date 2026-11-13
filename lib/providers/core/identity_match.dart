part of 'service.dart';

String normalizedIdentity(String text) => text
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();
final _remasterTitleSuffix = RegExp(
  r'\s*(?:\((?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?\)|\[(?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?\]|\s[-–—]\s(?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?)\s*$',
  caseSensitive: false,
);
String _titleKey(String title) =>
    normalizedIdentity(title.replaceFirst(_remasterTitleSuffix, ''));
Set<String> _publishedTitleKeys(String title) {
  final withoutRemaster = title.replaceFirst(_remasterTitleSuffix, '');
  return {
    for (final name in publishedNameVariants(withoutRemaster)) _titleKey(name),
  };
}

bool _samePublishedTitle(String first, String second) => _publishedTitleKeys(
  first,
).intersection(_publishedTitleKeys(second)).any((value) => value.isNotEmpty);
String arrangementTitle(String title) => title
    .replaceFirst(
      RegExp(
        r'\s*(?:\((?:(?:acoustic|live|unplugged|version)\s*)+\)|\[(?:(?:acoustic|live|unplugged|version)\s*)+\]|\s[-–—]\s(?:(?:acoustic|live|unplugged|version)\s*)+)\s*$',
        caseSensitive: false,
      ),
      '',
    )
    .trim();

bool sameSong(SongCandidate selected, SongCandidate result) {
  for (final id in selected.recordingIds.entries) {
    if (result.recordingIds.containsKey(id.key) &&
        result.recordingIds[id.key] != id.value) {
      return false;
    }
  }
  if (!_samePublishedTitle(selected.title, result.title) ||
      (normalizedIdentity(selected.artist) !=
              normalizedIdentity(result.artist) &&
          !publishedNamesMatch(selected.artist, result.artist) &&
          !sameGeniusPrimaryCredit(selected, result, normalizedIdentity) &&
          !sameReviewedChartArtist(selected, result) &&
          musicBrainzArtistCreditEvidence(
                selected,
                result,
                normalizedIdentity,
              ) ==
              null)) {
    return false;
  }
  final a = recordingVersionMarkers(selected.album ?? '', album: true),
      b = recordingVersionMarkers(result.album ?? '', album: true);
  if (a.difference(b).isNotEmpty || b.difference(a).isNotEmpty) {
    if (selected.album != null && result.album != null) return false;
    if (selected.identity != result.identity &&
        !recordingVersionMarkers(selected.title).containsAll({...a, ...b})) {
      return false;
    }
  }
  final sa = selected.durationSeconds, sb = result.durationSeconds;
  if (sa != null &&
      sb != null &&
      (sa - sb).abs() > math.min(15, math.max(8, sa * 0.02))) {
    return false;
  }
  return true;
}

/// Whether a chord site's arrangement may be [selected]'s song. Chord sites
/// may credit only the main artist ("Bob Marley" for "Bob Marley & The
/// Wailers") and drop a leading article ("House of the Rising Sun"); such
/// matches still need their lyrics to agree before they are used.
bool sameArrangement(
  SongCandidate selected,
  SongCandidate result,
  LyricsProvider provider,
) {
  final selectedArtist =
      reviewedChartArtistCredit(selected)?.canonicalName ?? selected.artist;
  final resultArtist =
      reviewedChartArtistCredit(result)?.canonicalName ?? result.artist;
  if (!provider.definition.capabilities.contains('chords') ||
      (!artistCreditsMatch(
            selectedArtist,
            resultArtist,
            (value) => normalizedIdentity(foldLyricVowelAccents(value)),
          ) &&
          !publishedNamesMatch(selectedArtist, resultArtist))) {
    return false;
  }
  for (final entry in selected.recordingIds.entries) {
    if (result.recordingIds.containsKey(entry.key) &&
        result.recordingIds[entry.key] != entry.value) {
      return false;
    }
  }
  final a = arrangementTitle(selected.title);
  var b = arrangementTitle(result.title);
  if (a != selected.title) {
    b = b.replaceFirst(RegExp(r'\s+acoustic$', caseSensitive: false), '');
  }
  String key(String title) => _titleKey(
    foldLyricVowelAccents(title),
  ).replaceFirst(RegExp(r'^(?:the|a|an) '), '');
  Set<String> publishedTitleKeys(String title) => {
    for (final name in publishedNameVariants(
      foldLyricVowelAccents(title).replaceFirst(_remasterTitleSuffix, ''),
    ))
      key(name),
  };
  return publishedTitleKeys(
    a,
  ).intersection(publishedTitleKeys(b)).any((value) => value.isNotEmpty);
}

bool _sameAlbum(SongCandidate a, SongCandidate b) =>
    a.album != null &&
    b.album != null &&
    normalizedIdentity(a.album!) == normalizedIdentity(b.album!);
bool _selectedHistoricalText(
  SongCandidate selected,
  SongCandidate result,
  String providerId,
) =>
    providerId == 'wikisource' &&
    selected.providerId == providerId &&
    result.providerId == providerId &&
    selected.id == result.id &&
    RegExp(r'^\d+$').hasMatch(selected.id) &&
    result.metadata['identityScope'] == 'historicalText' &&
    normalizedIdentity(selected.title) == normalizedIdentity(result.title) &&
    (selected.artist.trim().isEmpty ||
        normalizedIdentity(selected.artist) ==
            normalizedIdentity(result.artist));
double _rank(SongCandidate selection, SongCandidate song) =>
    (_sameAlbum(selection, song) ? 100 : 0) +
    (normalizedIdentity(selection.title) == normalizedIdentity(song.title)
        ? 20
        : 0) +
    (selection.durationSeconds != null && song.durationSeconds != null
        ? 40 - (selection.durationSeconds! - song.durationSeconds!).abs()
        : 0);
SourceResult _matched(
  SourceResult result,
  MatchKind kind,
  String reason, {
  JsonMap extra = const {},
}) => SourceResult(
  candidate: result.candidate,
  arrangementId: result.arrangementId,
  body: result.body,
  metadata: result.metadata,
  timingTracks: result.timingTracks,
  matchKind: kind,
  matchReason: reason,
  attribution: result.attribution,
  retrievedAt: result.retrievedAt,
  extra: {...result.extra, ...extra},
);
