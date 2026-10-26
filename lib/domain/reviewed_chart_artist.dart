import 'models.dart';
import 'edition_identity.dart';
import 'lyric_word_identity.dart';

/// A reviewed, provider-specific chart artist alias.
///
/// The name association is supported by Sony Music's Beyoncé artist biography
/// and the Columbia-distributed "Halo" credits. Songsterr artist IDs 87340 and
/// 6487 are observations from its cached search and resolved-page payloads
/// (2026-10-26); the label evidence does not attest to those provider IDs.
/// This identifies a credited performer for chart reconciliation only. It is
/// not recording identity or proof that two performances are the same.
class ReviewedChartArtistCredit {
  const ReviewedChartArtistCredit({
    required this.canonicalName,
    required this.sourceName,
    required this.providerArtistId,
    required this.providerSongId,
    required this.evidenceUrls,
  });

  final String canonicalName;
  final String sourceName;
  final String providerArtistId;
  final String providerSongId;
  final List<String> evidenceUrls;

  Map<String, Object> toJson() => {
    'canonicalName': canonicalName,
    'sourceName': sourceName,
    'providerArtistId': providerArtistId,
    'providerSongId': providerSongId,
    'evidenceUrls': evidenceUrls,
  };
}

const _sonyArtistBio = 'https://www.sonymusic.fr/artist/beyonce/';
const _columbiaHaloCredit = 'https://music.youtube.com/watch?v=Ws0sCcEf-XQ';
const _evidenceUrls = [_sonyArtistBio, _columbiaHaloCredit];

const _reviewedSongsterrArtistNames = <String, String>{
  '87340': 'Beyoncé',
  '6487': 'Beyonce Knowles',
};

/// Returns curated identity evidence only for explicitly reviewed chart data.
/// Unknown providers, IDs, names, or malformed chart paths stay unmatched.
ReviewedChartArtistCredit? reviewedChartArtistCredit(SongCandidate candidate) {
  if (candidate.providerId != 'songsterr') return null;
  final artistId = candidate.extra['providerArtistId'];
  final songId = candidate.extra['providerSongId'];
  if (artistId is! String || !_isPositiveDecimalId(artistId)) return null;
  if (songId is! String || !_isPositiveDecimalId(songId)) return null;
  final expectedName = _reviewedSongsterrArtistNames[artistId];
  if (expectedName == null ||
      _normalize(candidate.artist) != _normalize(expectedName)) {
    return null;
  }
  final pathSongId = _songsterrSongId(candidate.id);
  if (pathSongId == null || pathSongId != songId) return null;
  return ReviewedChartArtistCredit(
    canonicalName: 'Beyoncé',
    sourceName: candidate.artist,
    providerArtistId: artistId,
    providerSongId: songId,
    evidenceUrls: _evidenceUrls,
  );
}

/// Whether two candidates are the same reviewed Songsterr chart credit.
///
/// A shared chart ID alone is insufficient: both candidates must carry an
/// explicitly reviewed artist ID/name pair, and their complete chart IDs and
/// titles must agree. This is performer-credit reconciliation only.
bool sameReviewedChartArtist(SongCandidate first, SongCandidate second) {
  if (first.title.trim().isEmpty ||
      second.title.trim().isEmpty ||
      !explicitEditionsCompatible(first, second) ||
      first.providerId != second.providerId ||
      first.id != second.id ||
      _normalizeTitle(first.title) != _normalizeTitle(second.title)) {
    return false;
  }
  for (final entry in first.recordingIds.entries) {
    if (second.recordingIds.containsKey(entry.key) &&
        second.recordingIds[entry.key] != entry.value) {
      return false;
    }
  }
  final firstCredit = reviewedChartArtistCredit(first);
  final secondCredit = reviewedChartArtistCredit(second);
  return firstCredit != null &&
      secondCredit != null &&
      _normalize(firstCredit.canonicalName) ==
          _normalize(secondCredit.canonicalName);
}

bool _isPositiveDecimalId(String value) =>
    RegExp(r'^[1-9][0-9]{0,14}$').hasMatch(value);

String? _songsterrSongId(String id) {
  if (id.length > 1500 ||
      id.contains('\\') ||
      id.contains('?') ||
      id.contains('#') ||
      RegExp(r'%2f|%5c|%00', caseSensitive: false).hasMatch(id)) {
    return null;
  }
  final match = RegExp(
    r"^/a/wsa/[a-z0-9_%'-]+-chords-s([1-9][0-9]{0,14})$",
    caseSensitive: false,
  ).firstMatch(id);
  return match?.group(1);
}

String _normalize(String value) => foldLyricVowelAccents(value.toLowerCase());

String _normalizeTitle(String value) => _normalize(value);
