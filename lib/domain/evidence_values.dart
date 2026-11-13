/// Value tests and text normalizations shared by source evidence collection,
/// combination and source history merging. Each was previously written out
/// separately in those libraries; they must agree for one source to be judged
/// the same way at every stage.
library;

/// Whether [value] states something: not null, blank text, or an empty
/// collection. Zero and `false` are stated values.
bool hasEvidenceValue(Object? value) =>
    value != null &&
    (value is! String || value.trim().isNotEmpty) &&
    (value is! Iterable || value.isNotEmpty) &&
    (value is! Map || value.isNotEmpty);

final _notLetterOrNumber = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
final _apostrophes = RegExp("['‘’]");

/// [text] in lower case with every run of characters that are neither
/// letters nor numbers replaced by one space.
String normalizedEvidenceText(String text) =>
    text.toLowerCase().replaceAll(_notLetterOrNumber, ' ').trim();

/// [normalizedEvidenceText] for names and titles: catalogs and charts often
/// omit apostrophes ("It's" / "Its"), so they are dropped rather than
/// treated as a word boundary.
String identityEvidenceText(String text) =>
    normalizedEvidenceText(text.replaceAll(_apostrophes, ''));
