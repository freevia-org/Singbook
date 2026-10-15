import 'package:flutter/widgets.dart';

/// Dependency-free, locale-tolerant text folding and collation for song
/// titles.
///
/// Dart compares strings by UTF-16 code unit, which files "Éclair" after "Zebra"
/// and the Ukrainian "Їжак" after "Яблуко". These helpers fold Latin and Greek
/// diacritics to their base letters and give Cyrillic a single alphabetical
/// order that suits Bulgarian, Russian and Ukrainian, so titles sort the way a
/// reader expects without tying the order to the active UI locale.

const _latinFolds = <String, String>{
  'a': 'àáâãäåāăąǎǻạảấầẩẫậắằẳẵặ',
  'ae': 'æǽ',
  'c': 'çćĉċč',
  'd': 'ďđ',
  'e': 'èéêëēĕėęěẹẻẽếềểễệ',
  'g': 'ĝğġģ',
  'h': 'ĥħ',
  'i': 'ìíîïĩīĭįıỉị',
  'j': 'ĵ',
  'k': 'ķ',
  'l': 'ĺļľŀł',
  'n': 'ñńņňŉ',
  'o': 'òóôõöøōŏőǒǿơọỏốồổỗộớờởỡợ',
  'oe': 'œ',
  'r': 'ŕŗř',
  's': 'śŝşšș',
  'ss': 'ß',
  't': 'ţťțŧ',
  'u': 'ùúûüũūŭůűųǔưụủứừửữự',
  'w': 'ŵ',
  'y': 'ýÿŷỳỵỷỹ',
  'z': 'źżž',
  // Greek tonos and dialytika, and the final sigma.
  'α': 'ά',
  'ε': 'έ',
  'η': 'ή',
  'ι': 'ίϊΐ',
  'ο': 'ό',
  'υ': 'ύϋΰ',
  'ω': 'ώ',
  'σ': 'ς',
};

final Map<int, String> _foldTable = () {
  final table = <int, String>{};
  _latinFolds.forEach((base, chars) {
    for (final rune in chars.runes) {
      table[rune] = base;
    }
  });
  return table;
}();

/// One alphabet covering Bulgarian, Russian and Ukrainian; each language's own
/// alphabet is a subsequence of it.
const _cyrillicOrder = 'абвгґдеёєжзиіїйклмнопрстуфхцчшщъыьэюя';

final Map<int, int> _cyrillicRank = () {
  final table = <int, int>{};
  var rank = 0;
  for (final rune in _cyrillicOrder.runes) {
    table[rune] = 0x0430 + rank++;
  }
  return table;
}();

bool _isCombiningMark(int rune) => rune >= 0x0300 && rune <= 0x036F;

/// Lower-cases [text], removes diacritics and trims it, for comparing what a
/// person typed with what a title contains ("eclair" finds "Éclair").
String foldForSearch(String text) {
  final buffer = StringBuffer();
  for (final rune in text.trim().toLowerCase().runes) {
    if (_isCombiningMark(rune)) continue;
    buffer.write(_foldTable[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}

/// A key whose plain code-unit order is the display order of [title]:
/// punctuation and digits first, then letters with diacritics folded, with
/// Cyrillic in alphabet order.
String collationKey(String title) {
  final buffer = StringBuffer();
  for (final rune in title.trim().toLowerCase().runes) {
    if (_isCombiningMark(rune)) continue;
    final cyrillic = _cyrillicRank[rune];
    if (cyrillic != null) {
      buffer.writeCharCode(cyrillic);
      continue;
    }
    buffer.write(_foldTable[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}

/// Orders titles the way [collationKey] does, then by the accented spelling so
/// "Cafe" comes before "Café", and finally by [a] versus [b] as typed.
int compareTitles(String a, String b) {
  final byKey = collationKey(a).compareTo(collationKey(b));
  if (byKey != 0) return byKey;
  final byAccent = a.trim().toLowerCase().compareTo(b.trim().toLowerCase());
  return byAccent != 0 ? byAccent : a.compareTo(b);
}

/// Sorts [items] by [title] using [compareTitles]; stable for equal titles.
List<T> sortedByTitle<T>(Iterable<T> items, String Function(T item) title) {
  final decorated = [
    for (final (index, item) in items.indexed)
      (
        index: index,
        item: item,
        key: collationKey(title(item)),
        accented: title(item).trim().toLowerCase(),
      ),
  ];
  decorated.sort((a, b) {
    final byKey = a.key.compareTo(b.key);
    if (byKey != 0) return byKey;
    final byAccent = a.accented.compareTo(b.accented);
    return byAccent != 0 ? byAccent : a.index.compareTo(b.index);
  });
  return [for (final entry in decorated) entry.item];
}

/// The index letter of [title]: its first character with diacritics folded and
/// upper-cased ("Éclair" -> "E", "Їжак" -> "Ї"); `#` for an untitled song.
String titleIndexLetter(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return '#';
  final first = trimmed.characters.first;
  final buffer = StringBuffer();
  for (final rune in first.toLowerCase().runes) {
    if (_isCombiningMark(rune)) continue;
    buffer.write(_foldTable[rune] ?? String.fromCharCode(rune));
  }
  final folded = buffer.toString();
  if (folded.isEmpty) return first.toUpperCase();
  // "ß" folds to "ss" and "æ" to "ae"; the section is the first letter.
  return folded.characters.first.toUpperCase();
}
