import 'package:singbook/domain/models.dart';

String normalizeCorpusText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

String corpusArtistIdentity(String value) =>
    normalizeCorpusText(value).replaceFirst(RegExp(r'^the '), '');

/// A reviewed catalog alias selects one specific public record. It is not an
/// accuracy reference and does not establish a master recording or lyric gold.
/// Title/artist checks prevent a stale ID from silently selecting another act.
bool matchesCorpusCandidate(
  Map<String, dynamic> song,
  SongCandidate candidate,
) {
  final binding = song['catalogSelection'];
  if (binding is Map) {
    final evidence = binding['evidence'];
    if (evidence is! List || evidence.isEmpty) return false;
    return binding['providerId'] == candidate.providerId &&
        binding['candidateId'] == candidate.id &&
        normalizeCorpusText('${binding['title']}') ==
            normalizeCorpusText(candidate.title) &&
        corpusArtistIdentity('${binding['artist']}') ==
            corpusArtistIdentity(candidate.artist);
  }
  return normalizeCorpusText(song['title'] as String) ==
          normalizeCorpusText(candidate.title) &&
      corpusArtistIdentity(song['artist'] as String) ==
          corpusArtistIdentity(candidate.artist);
}

/// Independent review binds a reference to an actual catalog result or ISRC;
/// a status flag alone must not certify a stale ID or another performance.
bool corpusRecordingReferenceMatches(
  Map<String, dynamic> song,
  SongCandidate candidate,
) {
  if (!matchesCorpusCandidate(song, candidate)) return false;
  final expected = song['expected'];
  if (expected is! Map) return false;
  final reference = expected['recordingReference'];
  if (reference is! Map || reference['status'] != 'verified') return false;
  final evidence = reference['evidence'];
  if (evidence is! List ||
      evidence.isEmpty ||
      !evidence.every((item) => item is String && item.trim().isNotEmpty)) {
    return false;
  }
  final provider = reference['providerId'];
  final id = reference['candidateId'];
  final isrc = reference['isrc'];
  return (provider is String &&
          provider.isNotEmpty &&
          id is String &&
          id.isNotEmpty &&
          provider == candidate.providerId &&
          id == candidate.id) ||
      (isrc is String &&
          isrc.isNotEmpty &&
          isrc == candidate.recordingIds['isrc']);
}

/// A reviewed edition is evidence separate from a literal catalog title.
/// Require the same recording binding and exactly the reviewed target scope.
bool corpusReviewedEditionMatches(
  Map<String, dynamic> song,
  SongCandidate candidate,
) {
  final edition = song['recordingEdition'];
  if (edition is! String ||
      edition.trim().isEmpty ||
      song['recordingEditionStatus'] != 'verified' ||
      !corpusRecordingReferenceMatches(song, candidate)) {
    return false;
  }
  final reference = (song['expected'] as Map)['recordingReference'] as Map;
  return reference['recordingEdition'] == edition;
}
