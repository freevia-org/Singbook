import 'models.dart';

final _apostrophes = RegExp("['‘’]");
final _nameSeparators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Comparison-only identity of a title, artist or album: lower case, without
/// apostrophes, every other run of punctuation or spacing as one space.
/// Never shown and never stored as a name.
String normalizeNameIdentity(String value) => value
    .toLowerCase()
    .replaceAll(_apostrophes, '')
    .replaceAll(_nameSeparators, ' ')
    .trim();

/// A conservative library key: punctuation/case can vary between providers,
/// but artist names and edition words (live, remix, acoustic, etc.) stay intact.
String? librarySongIdentity(String title, String artist) {
  final name = normalizeNameIdentity(title),
      performer = normalizeNameIdentity(artist);
  return name.isEmpty || performer.isEmpty ? null : '$performer\u0000$name';
}

/// An exact persisted search reference outranks display-name matching. Conflict
/// copies remain independent documents and are never replacement targets.
bool librarySongHasReference(SongDocument song, String identity) =>
    librarySongReferenceKeys(song).contains(identity);

Iterable<String> librarySongReferenceKeys(SongDocument song) sync* {
  if (song.extra['syncConflict'] != null) return;
  if (song.selectedRecording?.identity case final reference?) yield reference;
  if (song.extra['combinedSelection'] case final String combined) {
    yield combined;
  }
}

bool librarySongHasName(SongDocument song, String identity) =>
    librarySongNameKeys(song).contains(identity);

Iterable<String> librarySongNameKeys(SongDocument song) sync* {
  if (song.extra['syncConflict'] != null) return;
  final reference = song.selectedRecording;
  yield* librarySongNames(
    (song.title, song.artist),
    reference == null ? null : (reference.title, reference.artist),
  );
}

Iterable<String> librarySongNames(
  (String, String) display,
  (String, String)? reference,
) sync* {
  final name = librarySongIdentity(display.$1, display.$2);
  if (name != null) yield name;
  if (reference != null && reference != display) {
    final referenceName = librarySongIdentity(reference.$1, reference.$2);
    if (referenceName != null && referenceName != name) yield referenceName;
  }
}

int librarySongMatchPriority(SongDocument song, SongCandidate selected) {
  if (selected.providerId.trim().isNotEmpty &&
      selected.id.trim().isNotEmpty &&
      librarySongHasReference(song, selected.identity)) {
    return 2;
  }
  final identity = librarySongIdentity(selected.title, selected.artist);
  return identity != null && librarySongHasName(song, identity) ? 1 : 0;
}
