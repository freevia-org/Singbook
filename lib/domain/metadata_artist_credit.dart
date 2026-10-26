import 'edition_identity.dart';
import 'lyric_word_identity.dart';
import 'models.dart';

/// Establishes structured performer-credit agreement between a Genius song
/// and a MusicBrainz recording. This is credit evidence only; it does not
/// establish that the two rows identify the same recording.
JsonMap? musicBrainzArtistCreditEvidence(
  SongCandidate a,
  SongCandidate b,
  String Function(String) normalize,
) {
  final genius = a.providerId == 'genius' ? a : b;
  final musicBrainz = a.providerId == 'musicbrainz' ? a : b;
  if (genius.providerId != 'genius' ||
      musicBrainz.providerId != 'musicbrainz' ||
      genius == musicBrainz ||
      !RegExp(r'^[1-9][0-9]{0,17}$').hasMatch(genius.id) ||
      !RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      ).hasMatch(musicBrainz.id) ||
      musicBrainz.recordingIds['musicbrainz'] != musicBrainz.id ||
      musicBrainz.metadata['identityScope'] != 'recording' ||
      !explicitEditionsCompatible(genius, musicBrainz)) {
    return null;
  }
  for (final entry in genius.recordingIds.entries) {
    if (musicBrainz.recordingIds.containsKey(entry.key) &&
        musicBrainz.recordingIds[entry.key] != entry.value) {
      return null;
    }
  }
  for (final entry in musicBrainz.recordingIds.entries) {
    if (genius.recordingIds.containsKey(entry.key) &&
        genius.recordingIds[entry.key] != entry.value) {
      return null;
    }
  }
  if (genius.album != null && musicBrainz.album != null) {
    final first = recordingVersionMarkers(genius.album!, album: true);
    final second = recordingVersionMarkers(musicBrainz.album!, album: true);
    if (first.difference(second).isNotEmpty ||
        second.difference(first).isNotEmpty) {
      return null;
    }
  }

  final raw = musicBrainz.metadata['artistCredits'];
  if (raw is! List || raw.isEmpty || raw.length > 8) return null;
  final nodes = <JsonMap>[];
  final ids = <String>{};
  final normalizedNames = <String>{};
  final primary = <String>[];
  final featured = <String>[];
  final rawParts = <String>[];
  var featureMode = false;
  for (final item in raw) {
    if (item is! Map ||
        item['name'] is! String ||
        item['musicbrainzId'] is! String ||
        item['joinPhrase'] is! String) {
      return null;
    }
    final name = (item['name'] as String).trim();
    final id = (item['musicbrainzId'] as String).trim();
    final phrase = item['joinPhrase'] as String;
    if (name.isEmpty ||
        name.length > 200 ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(id) ||
        !ids.add(id)) {
      return null;
    }
    rawParts.add((item['name'] as String) + phrase);
    nodes.add({
      'name': item['name'],
      'musicbrainzId': item['musicbrainzId'],
      'joinPhrase': phrase,
    });
    final n = normalize(foldLyricVowelAccents(name));
    if (n.isEmpty || !normalizedNames.add(n)) return null;
    (featureMode ? featured : primary).add(n);
    if (phrase.trim().isEmpty) continue;
    if (RegExp(
      r'^(?:&|/|and)$',
      caseSensitive: false,
    ).hasMatch(phrase.trim())) {
      if (featureMode && phrase.trim() != '&') return null;
    } else if (RegExp(
      r'^(?:feat\.?|ft\.?|featuring)$',
      caseSensitive: false,
    ).hasMatch(phrase.trim())) {
      featureMode = true;
    } else {
      return null;
    }
  }
  if ((raw.last as Map)['joinPhrase'] != '' || primary.isEmpty) return null;
  // MusicBrainz's raw display credit is the concatenation of the supplied
  // names and join phrases; reject truncated or rewritten source evidence.
  if (rawParts.join() != musicBrainz.artist) return null;

  final credits = genius.metadata['credits'];
  if (credits is! List) return null;
  final geniusPrimary = <String>[];
  final geniusFeatured = <String>[];
  final seenGeniusPrimary = <String>{};
  final seenGeniusFeatured = <String>{};
  if (credits.length > 128) return null;
  for (final item in credits) {
    if (item is! Map || item['role'] is! String || item['name'] is! String) {
      return null;
    }
    final name = (item['name'] as String).trim();
    if (name.isEmpty || name.length > 200) return null;
    if (item['role'] == 'Artist') {
      final canonical = normalize(foldLyricVowelAccents(name));
      if (canonical.isEmpty ||
          !seenGeniusPrimary.add(canonical) ||
          geniusPrimary.length >= 8) {
        return null;
      }
      geniusPrimary.add(canonical);
    }
    if (item['role'] == 'Featured artist') {
      final canonical = normalize(foldLyricVowelAccents(name));
      if (canonical.isEmpty ||
          !seenGeniusFeatured.add(canonical) ||
          geniusFeatured.length >= 8) {
        return null;
      }
      geniusFeatured.add(canonical);
    }
  }
  final canonicalPrimary = primary;
  if (geniusPrimary.isEmpty ||
      normalize(foldLyricVowelAccents(geniusPrimary.join(' & '))) !=
          normalize(foldLyricVowelAccents(genius.artist)) ||
      normalize(foldLyricVowelAccents(canonicalPrimary.join(' & '))) !=
          normalize(foldLyricVowelAccents(geniusPrimary.join(' & '))) ||
      featured
          .map((name) => normalize(foldLyricVowelAccents(name)))
          .any((n) => !geniusFeatured.contains(n))) {
    return null;
  }
  return {
    'method': 'musicbrainz-artist-credit',
    'scope': 'artist-credit-only',
    'geniusCandidateId': genius.id,
    'geniusArtistCredit': genius.artist,
    'musicbrainzRecordingId': musicBrainz.id,
    'musicbrainzArtistCredits': nodes,
    'primaryArtists': primary,
    'featuredArtists': featured,
    'geniusPrimaryArtists': geniusPrimary,
    'geniusFeaturedArtists': geniusFeatured,
  };
}
