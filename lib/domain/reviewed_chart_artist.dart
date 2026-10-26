import 'models.dart';
import 'edition_identity.dart';
import 'lyric_word_identity.dart';

/// A reviewed, provider-specific chart artist alias.
///
/// Each supported credit below binds an observed provider ID/name pair to
/// separately reviewed artist evidence; external biographies do not attest to
/// provider IDs. Raw source names and IDs remain available in the evidence.
/// This identifies a credited performer for chart reconciliation only. It is
/// not recording identity or proof that two performances are the same.
class ReviewedChartArtistCredit {
  const ReviewedChartArtistCredit({
    required this.canonicalName,
    required this.sourceName,
    required this.providerArtistId,
    required this.providerSongId,
    required this.evidenceUrls,
    this.providerChartId,
  });

  final String canonicalName;
  final String sourceName;
  final String providerArtistId;
  final String providerSongId;
  final List<String> evidenceUrls;
  final String? providerChartId;

  Map<String, Object> toJson() => {
    'canonicalName': canonicalName,
    'sourceName': sourceName,
    'providerArtistId': providerArtistId,
    'providerSongId': providerSongId,
    'evidenceUrls': evidenceUrls,
    'providerChartId': ?providerChartId,
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
  if (candidate.providerId == 'ultimateguitar') {
    return _panchosCredit(candidate);
  }
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

// Group-name association is documented by the ensemble history and LA Phil's
// artist biography. The ID/name association is observed in UG search and page
// payloads (2026-10-26), not attested by those external sources. Changing
// membership and different recordings remain distinct under the normal guards.
ReviewedChartArtistCredit? _panchosCredit(SongCandidate candidate) {
  final artistId = candidate.extra['providerArtistId'];
  final songId = candidate.extra['providerSongId'];
  final chartId = candidate.extra['providerChartId'];
  if (artistId != '325614' ||
      songId is! String ||
      !_isPositiveDecimalId(songId) ||
      chartId is! String ||
      !_isPositiveDecimalId(chartId) ||
      !const {
        'los panchos',
        'trio los panchos',
        'los panchos (trio los panchos)',
      }.contains(_normalize(candidate.artist))) {
    return null;
  }
  final path = candidate.id;
  if (path.length > 1500 ||
      path.contains('\\') ||
      RegExp(r'%2f|%5c|%00', caseSensitive: false).hasMatch(path)) {
    return null;
  }
  final match = RegExp(
    r"^/tab/(?:[a-z0-9_%'-]+/[a-z0-9_%'-]+-chords-)?([1-9][0-9]{0,14})$",
    caseSensitive: false,
  ).firstMatch(path);
  if (match?.group(1) != chartId) return null;
  return ReviewedChartArtistCredit(
    canonicalName: 'Los Panchos',
    sourceName: candidate.artist,
    providerArtistId: artistId as String,
    providerSongId: songId,
    providerChartId: chartId,
    evidenceUrls: const [
      'https://www.eltriolospanchos.com/historia-del-trio/',
      'https://www.laphil.com/people/los-panchos',
    ],
  );
}

/// Whether two candidates are the same reviewed provider chart credit.
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
      firstCredit.providerSongId == secondCredit.providerSongId &&
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
