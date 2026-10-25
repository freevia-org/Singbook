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
