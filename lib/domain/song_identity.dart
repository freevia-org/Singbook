import 'models.dart';

/// A conservative library key: punctuation/case can vary between providers,
/// but artist names and edition words (live, remix, acoustic, etc.) stay intact.
String? librarySongIdentity(String title, String artist) {
  String normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp("['‘’]"), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();
  final name = normalize(title), performer = normalize(artist);
  return name.isEmpty || performer.isEmpty ? null : '$performer\u0000$name';
}

/// An exact persisted search reference outranks display-name matching. Conflict
/// copies remain independent documents and are never replacement targets.
int librarySongMatchPriority(SongDocument song, SongCandidate selected) {
  if (song.extra['syncConflict'] != null) return 0;
  final reference = song.selectedRecording;
  if (selected.providerId.trim().isNotEmpty &&
      selected.id.trim().isNotEmpty &&
      (reference?.identity == selected.identity ||
          song.extra['combinedSelection'] == selected.identity)) {
    return 2;
  }
  final identity = librarySongIdentity(selected.title, selected.artist);
  if (identity == null) return 0;
  return librarySongIdentity(song.title, song.artist) == identity ||
          reference != null &&
              librarySongIdentity(reference.title, reference.artist) == identity
      ? 1
      : 0;
}
