import 'library/collation.dart' show foldForSearch;
import 'verse_ui_state.dart';

/// Whether [song] is found by a local search for [foldedNeedle], which the
/// caller has already passed through [foldForSearch]. Title, artist and album
/// are searched, case and diacritics ignored ("eclair" finds "Éclair").
///
/// Every local song list uses this one rule, so a count, a list and the
/// decision to search online never disagree about what matches.
bool songMatchesQuery(SongCardData song, String foldedNeedle) => foldForSearch(
  '${song.title} ${song.artist} ${song.album ?? ''}',
).contains(foldedNeedle);
