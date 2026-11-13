part of 'combine.dart';

final _literalChordTokenPattern = RegExp(
  chordPattern.pattern.replaceFirst(r'(?<!\\)', ''),
);

String _escapeLiteralChordTokens(String text) {
  final output = StringBuffer();
  var cursor = 0;
  for (final match in _literalChordTokenPattern.allMatches(text)) {
    output.write(_escapeBackslashes(text.substring(cursor, match.start)));
    output.write('\\');
    output.write(match[0]);
    cursor = match.end;
  }
  output.write(_escapeBackslashes(text.substring(cursor)));
  return output.toString();
}

String _escapeBackslashes(String text) => text.replaceAll('\\', '\\\\');

final _normalizedLineLetterOrNumber = RegExp(r'[\p{L}\p{N}]', unicode: true);

({String text, List<int> offsets}) _normalizedLine(String text) {
  // Most lyric text is ASCII. Avoid building grapheme and RegExp objects for
  // every character while retaining the same normalized-to-original offsets.
  if (text.codeUnits.every((unit) => unit < 0x80)) {
    final normalized = StringBuffer();
    final offsets = <int>[];
    var pendingSeparator = false;
    for (var index = 0; index < text.length; index++) {
      var unit = text.codeUnitAt(index);
      if (unit >= 0x41 && unit <= 0x5a) unit += 0x20;
      final isLetterOrNumber =
          (unit >= 0x61 && unit <= 0x7a) || (unit >= 0x30 && unit <= 0x39);
      if (!isLetterOrNumber) {
        if (normalized.isNotEmpty) pendingSeparator = true;
        continue;
      }
      if (pendingSeparator && normalized.isNotEmpty) {
        normalized.write(' ');
        offsets.add(index);
      }
      normalized.writeCharCode(unit);
      offsets.add(index);
      pendingSeparator = false;
    }
    return (text: normalized.toString(), offsets: offsets);
  }

  final normalized = StringBuffer();
  final offsets = <int>[];
  var pendingSeparator = false;
  final graphemes = text.characters.toList();
  for (var index = 0; index < graphemes.length; index++) {
    final lowered = graphemes[index].toLowerCase().characters;
    final kept = lowered.where(_normalizedLineLetterOrNumber.hasMatch).toList();
    if (kept.isEmpty) {
      if (normalized.isNotEmpty) pendingSeparator = true;
      continue;
    }
    if (pendingSeparator && normalized.isNotEmpty) {
      normalized.write(' ');
      offsets.add(index);
    }
    for (final character in kept) {
      normalized.write(character);
      offsets.addAll(List.filled(character.length, index));
    }
    pendingSeparator = false;
  }
  return (text: normalized.toString(), offsets: offsets);
}

/// Match lyric phrases rather than provider line breaks. Every character in
/// the comparison stream retains its location in the unchanged base lyrics.
Map<int, List<ChordAnchor>> _phraseChords(
  List<ArrangementLine> target,
  String chart,
) {
  final text = StringBuffer();
  final locations = <({int line, int offset})>[];
  final normalizedLines = <int, String>{};
  for (var line = 0; line < target.length; line++) {
    if (target[line].directive) continue;
    final normalized = _normalizedLine(target[line].text);
    normalizedLines[line] = normalized.text;
    if (normalized.text.isEmpty) continue;
    if (text.isNotEmpty) {
      text.write(' ');
      locations.add((line: line, offset: 0));
    }
    text.write(normalized.text);
    locations.addAll([
      for (final offset in normalized.offsets) (line: line, offset: offset),
    ]);
  }
  final haystack = text.toString();
  final words = RegExp(r'\S+').allMatches(haystack).toList();
  final phraseIndex = <int, Map<String, List<int>>>{};
  List<int> startsFor(String phrase) {
    final tokens = phrase.split(' ');
    // Four-word keys avoid scanning every repeated three-word opening while
    // remaining a necessary prefix for every valid full-phrase occurrence.
    final count = tokens.length.clamp(1, 4);
    final index = phraseIndex.putIfAbsent(count, () {
      final value = <String, List<int>>{};
      for (var i = 0; i + count <= words.length; i++) {
        final key = haystack.substring(
          words[i].start,
          words[i + count - 1].end,
        );
        value.putIfAbsent(key, () => []).add(words[i].start);
      }
      return value;
    });
    return index[tokens.take(count).join(' ')] ?? const [];
  }

  final phrases = <String, List<ArrangementLine>>{};
  for (final line in parseArrangement(chart)) {
    final phrase = _normalizedLine(line.text).text;
    if (line.directive || line.chords.isEmpty || phrase.isEmpty) continue;
    phrases.putIfAbsent(phrase, () => []).add(line);
  }
  final result = <int, List<ChordAnchor>>{};
  // Text already given chords by a phrase; another placement may not overlap
  // it, or two readings of one passage ("na na na ...") would interleave.
  final claimed = <(int, int)>[];
  bool overlapsClaimed(int start, int end) =>
      claimed.any((range) => start < range.$2 && range.$1 < end);
  // Bound synchronous matching even for deliberately repetitive documents.
  // Unplaced chart data remains in the original source document.
  var comparisonBudget = (haystack.length + chart.length) * 8;
  phrasesLoop:
  for (final entry in phrases.entries) {
    // Repeated words can have different harmonies in different sections.
    if (entry.value.map(_chordSignature).toSet().length != 1) continue;
    final donor = entry.value.first;
    final normalized = _normalizedLine(donor.text);
    final matches = <({int start, int end, bool wholeLine})>[];
    for (final start in startsFor(entry.key)) {
      comparisonBudget -= entry.key.length;
      if (comparisonBudget < 0) break phrasesLoop;
      final end = start + entry.key.length;
      if (!haystack.startsWith(entry.key, start) ||
          (start > 0 && haystack[start - 1] != ' ') ||
          (end < haystack.length && haystack[end] != ' ')) {
        continue;
      }
      final first = locations[start];
      final last = locations[end - 1];
      final wholeLine =
          first.line == last.line && normalizedLines[first.line] == entry.key;
      // Short phrases require a whole-line match; common one-word fragments
      // are insufficient evidence for a chord placement inside another line.
      if (entry.key.split(' ').length < 3 && !wholeLine) {
        continue;
      }
      // Overlapping occurrences of one phrase are one passage.
      if (matches.isNotEmpty && start < matches.last.end) continue;
      matches.add((start: start, end: end, wholeLine: wholeLine));
    }
    // A single partial phrase does not identify which of several different
    // passages shares its harmony. Require enough agreeing donor occurrences
    // for those placements. Complete repeated lyric lines retain the existing
    // whole-line overlay behavior.
    final ambiguous = matches.length > entry.value.length;
    for (final match in matches) {
      if (ambiguous && !match.wholeLine) continue;
      final start = match.start, end = match.end;
      if (overlapsClaimed(start, end)) continue;
      claimed.add((start, end));
      for (final chord in donor.chords) {
        var index = normalized.offsets
            .where((offset) => offset < chord.offset)
            .length;
        while (index < normalized.text.length &&
            normalized.text[index] == ' ') {
          index++;
        }
        final atEnd = index >= normalized.text.length;
        final location = locations[atEnd ? end - 1 : start + index];
        final offset = location.offset + (atEnd ? 1 : 0);
        final line = target[location.line];
        if (line.chords.isNotEmpty ||
            (offset > 0 &&
                line.text.characters.elementAt(offset - 1) == '\\')) {
          continue;
        }
        final anchors = result.putIfAbsent(location.line, () => []);
        if (!anchors.any((a) => a.offset == offset && a.chord == chord.chord)) {
          anchors.add(ChordAnchor(offset, chord.chord));
        }
      }
    }
  }
  result.removeWhere((_, anchors) {
    final byOffset = <int, Set<String>>{};
    for (final anchor in anchors) {
      byOffset.putIfAbsent(anchor.offset, () => {}).add(anchor.chord);
    }
    return byOffset.values.any((chords) => chords.length > 1);
  });
  return result;
}

String _chordSignature(ArrangementLine line) {
  final graphemes = line.text.characters.toList();
  return line.chords
      .map((chord) {
        final prefix = _normalizedLine(
          graphemes.take(chord.offset.clamp(0, graphemes.length)).join(),
        );
        return '${prefix.text.length}:${chord.chord}';
      })
      .join('|');
}

/// Section kinds whose later instances usually repeat an earlier one's
/// harmony.
const _repeatingSections = {'verse', 'chorus', 'pre-chorus', 'refrain'};

/// Charts often give chords for the first verse only ("same as verse 1"). A
/// lyric line without chords in a later section takes the chords of the same
/// line in the most recent earlier section of the same kind (verse, chorus,
/// pre-chorus, refrain) with as many lyric lines, if that line has chords.
/// Chords keep their relative word positions. Lines with escapes or
/// non-plain characters are left alone.
({String body, int lines}) _fillRepeatedSections(
  String body, {
  bool requireMatchingLyrics = false,
}) {
  final raw = body.split('\n');
  final parsed = parseArrangement(body);
  final sections = <({String kind, List<int> lyrics})>[];
  String? kind;
  var lyrics = <int>[];
  void close() {
    if (kind != null && lyrics.isNotEmpty) {
      sections.add((kind: kind, lyrics: lyrics));
    }
    lyrics = <int>[];
  }

  for (var i = 0; i < parsed.length; i++) {
    final label = sectionLabelForLine(parsed[i]);
    if (label != null) {
      close();
      kind = label.toLowerCase().replaceAll(RegExp(r'\s*\d+$'), '').trim();
      continue;
    }
    if (parsed[i].directive) {
      if (RegExp(r'^\s*\{(end_of_|eo)').hasMatch(parsed[i].text)) {
        close();
        kind = null;
      }
      continue;
    }
    if (parsed[i].text.trim().isEmpty) continue;
    lyrics.add(i);
  }
  close();
  var filled = 0;
  for (var s = 0; s < sections.length; s++) {
    final target = sections[s];
    if (!_repeatingSections.contains(target.kind)) continue;
    final models = sections
        .take(s)
        .where(
          (section) =>
              section.kind == target.kind &&
              section.lyrics.length == target.lyrics.length,
        )
        .toList();
    if (models.isEmpty) continue;
    for (var n = 0; n < target.lyrics.length; n++) {
      final index = target.lyrics[n];
      final to = parsed[index];
      if (to.chords.isNotEmpty) continue;
      // The most recent earlier section of this kind with chords on this
      // line; none when such sections disagree on its chords.
      final chorded = models
          .where((section) => parsed[section.lyrics[n]].chords.isNotEmpty)
          .toList();
      if (chorded.isEmpty ||
          chorded
                  .map(
                    (section) => parsed[section.lyrics[n]].chords
                        .map((chord) => chord.chord)
                        .join(' '),
                  )
                  .toSet()
                  .length >
              1) {
        continue;
      }
      final model = chorded.last;
      final from = parsed[model.lyrics[n]];
      if (raw[index].contains('\\') ||
          to.text.characters.length != to.text.length ||
          from.text.characters.length != from.text.length) {
        continue;
      }
      final fromWords = _lineWords(from.text), toWords = _lineWords(to.text);
      if (fromWords.isEmpty || toWords.isEmpty) continue;
      if (requireMatchingLyrics &&
          _repeatKey(from.text) != _repeatKey(to.text)) {
        continue;
      }
      final anchors = <ChordAnchor>[];
      for (final chord in from.chords) {
        final word = fromWords.indexWhere((w) => chord.offset < w.end);
        final position = word < 0
            ? toWords.length - 1
            : fromWords.length == 1
            ? 0
            : (word * (toWords.length - 1) / (fromWords.length - 1)).round();
        anchors.add(
          ChordAnchor(
            word < 0 ? to.text.length : toWords[position].start,
            chord.chord,
          ),
        );
      }
      final buffer = StringBuffer();
      var cursor = 0;
      for (final chord
          in anchors..sort((a, b) => a.offset.compareTo(b.offset))) {
        buffer.write(
          _escapeLiteralChordTokens(to.text.substring(cursor, chord.offset)),
        );
        buffer.write('[${chord.chord}]');
        cursor = chord.offset;
      }
      buffer.write(_escapeLiteralChordTokens(to.text.substring(cursor)));
      raw[index] = buffer.toString();
      filled++;
    }
  }
  return (body: raw.join('\n'), lines: filled);
}

final _wordToken = RegExp(r"[\p{L}\p{N}']+", unicode: true);

/// A line's words, lower case and without apostrophes; a dropped "g"
/// ("darlin'") is restored, as charts and lyrics spell it either way.
List<({String word, int start, int end})> _lineWords(String text) => [
  for (final match in _wordToken.allMatches(text))
    (
      word: foldLyricVowelAccents(
        match[0]!.toLowerCase(),
      ).replaceFirst(RegExp(r"in'$"), 'ing').replaceAll("'", ''),
      start: match.start,
      end: match.end,
    ),
];

typedef _Words = List<({String word, int start, int end})>;

/// Vocables sung around the lyrics that charts often leave out.
const _interjections = {
  'oh',
  'ooh',
  'oooh',
  'ah',
  'ahh',
  'aah',
  'uh',
  'whoa',
  'woah',
  'woo',
  'yeah',
  'yeh',
  'hey',
  'na',
  'la',
  'da',
  'doo',
  'dum',
  'ba',
  'sha',
  'mm',
  'mmm',
  'hmm',
  'ha',
  'oh-oh',
  'ay',
  'ayy',
  'eh',
  'o',
};

/// [line]'s chords moved onto words [to] through word alignment [pairs]
/// (from-index, to-index): each chord's target word index and offset inside
/// that word, or a null index for a chord after the last word. An unaligned
/// chord word borrows the position of the nearest aligned word that keeps
/// the chords in order.
List<(int?, int, String)> _mapChordWords(
  ArrangementLine line,
  _Words from,
  _Words to,
  List<(int, int)> pairs, {
  Map<int, int> trailingWordOverrides = const {},
}) {
  final aligned = {for (final (a, b) in pairs) a: b};
  final anchors = <(int?, int, String)>[];
  // Chords keep their order: a chord never lands before the previous one,
  // or on its word unless both sat on one chart word.
  int? previous, previousWord;
  var ended = false;
  for (final chord in line.chords) {
    final override = trailingWordOverrides[chord.offset];
    final index =
        override ?? from.indexWhere((word) => chord.offset < word.end);
    if (index < 0 || ended) {
      ended = true;
      anchors.add((null, 0, chord.chord));
      continue;
    }
    bool free(int probe) =>
        probe >= 0 &&
        probe < from.length &&
        aligned.containsKey(probe) &&
        (previous == null ||
            aligned[probe]! > previous ||
            (index == previousWord && aligned[probe] == previous));
    // The nearest free aligned word; the earlier one on a tie.
    int? probe;
    for (
      var distance = 0;
      distance < from.length && probe == null;
      distance++
    ) {
      if (free(index - distance)) {
        probe = index - distance;
      } else if (free(index + distance)) {
        probe = index + distance;
      }
    }
    if (probe == null) {
      // No aligned word left: the chord follows the line's last word.
      if (previous == null) continue;
      ended = true;
      anchors.add((null, 0, chord.chord));
      continue;
    }
    final target = to[aligned[probe]!];
    final inWord = probe == index
        ? (override == null
                  ? chord.offset - from[index].start
                  : from[index].end - from[index].start)
              .clamp(0, target.end - target.start)
        : 0;
    previous = aligned[probe]!;
    previousWord = index;
    anchors.add((previous, inWord, chord.chord));
  }
  return anchors;
}

/// The share of words two lines have in order. A line of four or more words
/// written almost entirely inside a longer one (at most 2.5 times as long),
/// as charts that write a repeated phrase once or break lines differently
/// do, counts as the weakest acceptable similarity, 0.8.
double _lineSimilarity(_Words a, _Words b, List<(int, int)> pairs) {
  final longer = a.length > b.length ? a.length : b.length;
  final shorter = a.length > b.length ? b.length : a.length;
  final overall = pairs.length / longer;
  if (overall >= .8) return overall;
  return shorter >= 4 && longer <= shorter * 2.5 && pairs.length / shorter >= .9
      ? .8
      : overall;
}

/// Chart lines placed on [target] lines by word alignment, where exact
/// phrase placement found none. Line similarity is the share of words in
/// order (longest common subsequence); 80% is required. Lyric words the
/// chart never writes (ad-libs, backing vocals) are left out of the
/// comparison when most of a line's words remain.
///
/// First the chart and the lyrics are aligned line by line in order (a
/// sequence alignment), so a lyric repeated with different chords in
/// different sections takes the chords of its own section. A chart line may
/// cover two adjacent lyric lines, as charts that join short lines do. Lyric
/// lines left over (a chorus the chart writes once) then take the chords of
/// the single closest chart line; equally close chart lines with different
/// chords place nothing. A lyric line of fewer than three words takes part
/// only joined with the next line; chart lines of fewer than three words,
/// and lines whose offsets are not plain characters, are skipped.
Map<int, List<ChordAnchor>> _fuzzyLineChords(
  List<ArrangementLine> target,
  String chart,
) {
  bool plainText(String text) => text.characters.length == text.length;
  final parsedDonors = parseArrangement(chart);
  final wordCache = <String, _Words>{};
  _Words lineWords(String text) =>
      wordCache.putIfAbsent(text, () => _lineWords(text));
  final donors =
      <
        ({
          ArrangementLine line,
          _Words words,
          Map<int, int> trailingWordOverrides,
        })
      >[];
  final donorRanges = <(int, int)>[];
  for (var i = 0; i < parsedDonors.length; i++) {
    final line = parsedDonors[i];
    if (line.directive || line.chords.isEmpty || !plainText(line.text)) {
      continue;
    }
    final words = lineWords(line.text);
    if (words.length < 3 || words.length > 40) continue;
    donors.add((line: line, words: words, trailingWordOverrides: const {}));
    donorRanges.add((i, i + 1));
  }
  final eligibleTargets = <({int index, _Words words})>[];
  for (var i = 0; i < target.length; i++) {
    final line = target[i];
    if (line.directive || !plainText(line.text)) continue;
    final words = lineWords(line.text);
    if (words.isNotEmpty && words.length <= 40) {
      eligibleTargets.add((index: i, words: words));
    }
  }
  final targetLineCount = eligibleTargets.length;
  if (targetLineCount == 0) return const {};
  final donorLimit = 40000 ~/ targetLineCount;
  if (donors.length > donorLimit) return const {};
  final contextDonors =
      <
        ({
          ArrangementLine line,
          _Words words,
          Map<int, int> trailingWordOverrides,
        })
      >[];
  final contextRanges = <(int, int)>[];
  // Chord charts often split one lyric paragraph into several very short
  // rows. Compare bounded adjacent runs as one word stream, retaining each
  // chord's offset within that stream. Only short, chorded rows participate;
  // blank lines, directives, long rows, and non-plain grapheme offsets break
  // the context so unrelated sections cannot lend placement evidence.
  for (var start = 0; start < parsedDonors.length; start++) {
    final first = parsedDonors[start];
    if (first.directive ||
        first.chords.isEmpty ||
        !plainText(first.text) ||
        lineWords(first.text).length > 6 ||
        lineWords(first.text).isEmpty) {
      continue;
    }
    final text = StringBuffer();
    final chords = <ChordAnchor>[];
    var joinedLength = 0;
    var wordCount = 0;
    final internalTrailingWordOverrides = <int, int>{};
    var previousTrailingWordOverrides = <int, int>{};
    for (var end = start; end < parsedDonors.length && end < start + 8; end++) {
      final line = parsedDonors[end];
      final words = lineWords(line.text);
      if (line.directive ||
          line.chords.isEmpty ||
          !plainText(line.text) ||
          words.isEmpty ||
          words.length > 6) {
        break;
      }
      if (end > start) {
        text.write(' ');
        joinedLength++;
        internalTrailingWordOverrides.addAll(previousTrailingWordOverrides);
      }
      final lineStart = joinedLength;
      final firstWordIndex = wordCount;
      text.write(line.text);
      joinedLength += line.text.length;
      wordCount += words.length;
      chords.addAll(
        line.chords.map(
          (chord) => ChordAnchor(lineStart + chord.offset, chord.chord),
        ),
      );
      previousTrailingWordOverrides = {
        for (final chord in line.chords)
          if (chord.offset == line.text.length)
            lineStart + chord.offset: firstWordIndex + words.length - 1,
      };
      if (end > start && wordCount >= 3) {
        final combined = ArrangementLine(
          text.toString(),
          List.unmodifiable(chords),
        );
        contextDonors.add((
          line: combined,
          words: lineWords(combined.text),
          trailingWordOverrides: Map.unmodifiable(
            internalTrailingWordOverrides,
          ),
        ));
        contextRanges.add((start, end + 1));
      }
    }
  }
  // Keep context candidates from the whole chart when the DP work budget is
  // tight. Taking only the first candidates biases chord coverage toward the
  // start of a long song. The even sample preserves a spread across the full
  // source order while keeping donors × target lines within the old budget.
  final availableContexts = donorLimit - donors.length;
  if (contextDonors.length <= availableContexts) {
    donors.addAll(contextDonors);
    donorRanges.addAll(contextRanges);
  } else if (availableContexts > 0) {
    for (var i = 0; i < availableContexts; i++) {
      final index = ((i + .5) * contextDonors.length / availableContexts)
          .floor();
      donors.add(contextDonors[index]);
      donorRanges.add(contextRanges[index]);
    }
  }
  final donorOrder = [for (var i = 0; i < donors.length; i++) i]
    ..sort((a, b) {
      final byStart = donorRanges[a].$1.compareTo(donorRanges[b].$1);
      if (byStart != 0) return byStart;
      final byEnd = donorRanges[a].$2.compareTo(donorRanges[b].$2);
      return byEnd != 0 ? byEnd : a.compareTo(b);
    });
  final orderedDonors = [for (final i in donorOrder) donors[i]];
  final orderedRanges = [for (final i in donorOrder) donorRanges[i]];
  donors
    ..clear()
    ..addAll(orderedDonors);
  donorRanges
    ..clear()
    ..addAll(orderedRanges);
  final vocabulary = {
    for (final donor in donors)
      for (final word in donor.words) word.word,
  };
  _Words known(_Words words) {
    // Interjections the chart never writes ("doo doo", "oh") always go.
    final sung = [
      for (final word in words)
        if (vocabulary.contains(word.word) ||
            !_interjections.contains(word.word))
          word,
    ];
    final kept = [
      for (final word in sung)
        if (vocabulary.contains(word.word)) word,
    ];
    if (kept.length >= 3 && kept.length >= words.length * .6) return kept;
    return sung.length >= 3 ? sung : words;
  }

  // Lines of one or two words take part only joined with the next line.
  final lyrics = [
    for (final target in eligibleTargets)
      (index: target.index, words: known(target.words)),
  ];
  if (donors.isEmpty ||
      lyrics.isEmpty ||
      donors.length * lyrics.length > 40000) {
    return const {};
  }
  // Build each adjacent lyric window once. Every donor compares against
  // the same windows, and the alignment traverses those scores repeatedly.
  final windows = List.generate(lyrics.length, (start) {
    final spans = <_Words>[lyrics[start].words];
    for (var end = start + 1; end < lyrics.length && end < start + 3; end++) {
      if (lyrics[end].index != lyrics[end - 1].index + 1) break;
      spans.add([...spans.last, ...lyrics[end].words]);
    }
    return spans;
  });
  bool joinable(int l, int span) => span <= windows[l].length;
  _Words wordsOf(int l, int span) => windows[l][span - 1];
  final pairsOf = <(int, int, int), List<(int, int)>>{};
  List<(int, int)> pairs(int d, int l, int span) => pairsOf.putIfAbsent((
    d,
    l,
    span,
  ), () => _alignWords(donors[d].words, wordsOf(l, span)));
  // Cache the thresholded scores, including misses, in a bounded table.
  final scoreCount = donors.length * lyrics.length * 3;
  final similarities = Float64List(scoreCount)..fillRange(0, scoreCount, -1);
  double similarity(int d, int l, [int span = 1]) {
    if (!joinable(l, span)) return 0;
    final words = wordsOf(l, span);
    if (words.length < 3) return 0;
    final index = (d * lyrics.length + l) * 3 + span - 1;
    final cached = similarities[index];
    if (cached >= 0) return cached;
    final value = _lineSimilarity(donors[d].words, words, pairs(d, l, span));
    return similarities[index] = value >= .8 ? value : 0;
  }

  // A containment match (most of one line inside a longer one) is weaker:
  // it needs anchors like an ambiguous line and never fills leftovers.
  bool contained(int d, int l, [int span = 1]) {
    final words = wordsOf(l, span).length;
    final longer = donors[d].words.length > words
        ? donors[d].words.length
        : words;
    return pairs(d, l, span).length / longer < .8;
  }

  // Ordered alignment: maximise the summed similarity of matched lyric
  // lines. Joining two lines counts for both, but only when it fits better
  // than either line alone and is not a containment match.
  final rows = donors.length, columns = lyrics.length;
  double joined(int d, int l, int span) {
    final value = similarity(d, l, span);
    if (span < 2 || value == 0 || contained(d, l, span)) return 0;
    for (var part = 0; part < span; part++) {
      if (value <= similarity(d, l + part)) return 0;
    }
    return value;
  }

  final score = List.generate(rows + 1, (_) => List.filled(columns + 2, 0.0));
  for (var d = rows - 1; d >= 0; d--) {
    for (var l = columns - 1; l >= 0; l--) {
      final match = similarity(d, l);
      var best = score[d + 1][l] > score[d][l + 1]
          ? score[d + 1][l]
          : score[d][l + 1];
      if (match > 0 && match + score[d + 1][l + 1] > best) {
        best = match + score[d + 1][l + 1];
      }
      for (var span = 2; span <= 3 && l + span <= columns; span++) {
        final context = joined(d, l, span);
        if (context > 0 && span * context + score[d + 1][l + span] > best) {
          best = span * context + score[d + 1][l + span];
        }
      }
      score[d][l] = best;
    }
  }
  // Chart text written more than once with different chords is ambiguous;
  // order may resolve it only between unambiguous matches on both sides.
  final signatures = <String, Set<String>>{};
  for (final donor in donors) {
    signatures
        .putIfAbsent(_repeatKey(donor.line.text), () => {})
        .add(_chordSignature(donor.line));
  }
  bool ambiguousDonor(int d) =>
      signatures[_repeatKey(donors[d].line.text)]!.length > 1;
  var matched = <(int, int, int)>[];
  // The same lyric text left uncovered elsewhere makes the place where a
  // match lands as arbitrary as an ambiguous chart line.
  final covered = <int>{};
  final texts = <(int, int), String>{};
  String textOf(int l, int span) => texts.putIfAbsent((
    l,
    span,
  ), () => wordsOf(l, span).map((word) => word.word).join(' '));
  bool repeatedElsewhere(int l, int span) {
    final text = textOf(l, span);
    for (var other = 0; other < columns; other++) {
      if (other == l ||
          !joinable(other, span) ||
          List.generate(
            span,
            (i) => i,
          ).any((i) => covered.contains(other + i))) {
        continue;
      }
      if (textOf(other, span) == text) return true;
    }
    return false;
  }

  bool weak((int, int, int) match) =>
      ambiguousDonor(match.$1) ||
      contained(match.$1, match.$2, match.$3) ||
      repeatedElsewhere(match.$2, match.$3);
  var d = 0, l = 0;
  while (d < rows && l < columns) {
    final match = similarity(d, l);
    var span = 1;
    var contextScore = match > 0 ? match + score[d + 1][l + 1] : -1.0;
    for (
      var candidateSpan = 2;
      candidateSpan <= 3 && l + candidateSpan <= columns;
      candidateSpan++
    ) {
      final candidate = joined(d, l, candidateSpan);
      final candidateScore =
          candidateSpan * candidate + score[d + 1][l + candidateSpan];
      if (candidate > 0 && candidateScore > contextScore) {
        span = candidateSpan;
        contextScore = candidateScore;
      }
    }
    if (span > 1 && score[d][l] == contextScore) {
      matched.add((d, l, span));
      d++;
      l += span;
    } else if (match > 0 && score[d][l] == contextScore) {
      matched.add((d, l, 1));
      d++;
      l++;
    } else if (score[d + 1][l] >= score[d][l + 1]) {
      d++;
    } else {
      l++;
    }
  }
  // Original chart rows and their combined contexts can describe the same
  // source passage. Keep ownership of each source interval with one match so
  // an overlapping virtual row cannot lend the same chord evidence twice.
  final owned = <(int, int, int)>[];
  for (final match in matched) {
    final range = donorRanges[match.$1];
    final overlap = owned.where((other) {
      final prior = donorRanges[other.$1];
      return range.$1 < prior.$2 && prior.$1 < range.$2;
    }).toList();
    if (overlap.isEmpty) {
      owned.add(match);
      continue;
    }
    double scoreFor((int, int, int) value) =>
        similarity(value.$1, value.$2, value.$3);
    final best = overlap
        .map(scoreFor)
        .fold(scoreFor(match), (a, b) => a > b ? a : b);
    if (scoreFor(match) != best) continue;
    if (overlap.any((other) => scoreFor(other) == best)) {
      owned.removeWhere(overlap.contains);
      continue;
    }
    owned.removeWhere(overlap.contains);
    owned.add(match);
  }
  matched = owned;
  matched.sort((a, b) {
    final source = donorRanges[a.$1].$1.compareTo(donorRanges[b.$1].$1);
    return source != 0 ? source : a.$2.compareTo(b.$2);
  });
  for (final (_, l, span) in matched) {
    covered.addAll(List.generate(span, (i) => l + i));
  }
  final result = <int, List<ChordAnchor>>{};
  void place(int d, int l, int span) {
    final words = wordsOf(l, span);
    final boundaries = <int>[];
    var count = 0;
    for (var part = 0; part < span; part++) {
      count += lyrics[l + part].words.length;
      boundaries.add(count);
    }
    for (final (word, inWord, chord) in _mapChordWords(
      donors[d].line,
      donors[d].words,
      words,
      pairs(d, l, span),
      trailingWordOverrides: donors[d].trailingWordOverrides,
    )) {
      // Chords after the last word stay at the end of the last line.
      final localWord = word ?? words.length - 1;
      var part = boundaries.indexWhere((boundary) => localWord < boundary);
      if (part < 0) part = span - 1;
      final priorBoundary = part == 0 ? 0 : boundaries[part - 1];
      final line = lyrics[l + part].index;
      final offset = word == null
          ? target[line].text.length
          : lyrics[l + part].words[word - priorBoundary].start + inWord;
      result.putIfAbsent(line, () => []).add(ChordAnchor(offset, chord));
    }
  }

  final abstainedLyrics = <int>{};
  // [covered] is complete here, so a match's weakness no longer changes.
  final weakMatches = List<bool?>.filled(matched.length, null);
  bool weakAt(int index) => weakMatches[index] ??= weak(matched[index]);
  bool strongIn(int from, int to) {
    for (var index = from; index < to; index++) {
      if (!weakAt(index)) return true;
    }
    return false;
  }

  for (var m = 0; m < matched.length; m++) {
    final (d, l, span) = matched[m];
    // Another chart line between the neighbouring matches that fits this
    // lyric equally well with different chords makes the choice arbitrary.
    final low = m == 0 ? 0 : matched[m - 1].$1 + 1;
    final high = m + 1 == matched.length ? rows : matched[m + 1].$1;
    final value = similarity(d, l, span);
    var tied = false;
    for (var other = low; other < high && !tied; other++) {
      tied =
          other != d &&
          similarity(other, l, span) == value &&
          _chordSignature(donors[other].line) !=
              _chordSignature(donors[d].line);
    }
    if (tied) {
      abstainedLyrics.addAll(List.generate(span, (i) => lyrics[l + i].index));
      continue;
    }
    if (weakAt(m) &&
        (!strongIn(0, m) || !strongIn(m + 1, matched.length))) {
      abstainedLyrics.addAll(List.generate(span, (i) => lyrics[l + i].index));
      continue;
    }
    place(d, l, span);
  }
  // Leftover lyric lines: the single closest chart line, if unambiguous.
  // A source interval selected by the ordered alignment is never recycled for
  // a leftover line, even when placement abstains because that match is weak
  // or ambiguous. Otherwise one chord phrase could be reused elsewhere.
  final placedRanges = <(int, int)>[
    for (final (d, _, _) in matched) donorRanges[d],
  ];
  for (var l = 0; l < columns; l++) {
    if (result.containsKey(lyrics[l].index) ||
        abstainedLyrics.contains(lyrics[l].index)) {
      continue;
    }
    var best = -1;
    var bestScore = 0.0;
    var ambiguous = false;
    for (var d = 0; d < rows; d++) {
      final range = donorRanges[d];
      if (placedRanges.any(
        (used) => range.$1 < used.$2 && used.$1 < range.$2,
      )) {
        continue;
      }
      final value = similarity(d, l);
      if (value == 0 || contained(d, l)) continue;
      if (value > bestScore) {
        best = d;
        bestScore = value;
        ambiguous = false;
      } else if (value == bestScore &&
          _chordSignature(donors[d].line) !=
              _chordSignature(donors[best].line)) {
        ambiguous = true;
      }
    }
    if (best < 0 || ambiguous) continue;
    place(best, l, 1);
    placedRanges.add(donorRanges[best]);
  }
  result.removeWhere((_, anchors) => anchors.isEmpty);
  return result;
}

/// Index pairs of the longest common subsequence of two word lists.
List<(int, int)> _alignWords(
  List<({String word, int start, int end})> a,
  List<({String word, int start, int end})> b,
) {
  final pairs = <(int, int)>[];
  var prefix = 0;
  // The existing traceback always takes equal leading words diagonally.
  // Leave only the unmatched suffixes for the dynamic program.
  while (prefix < a.length &&
      prefix < b.length &&
      a[prefix].word == b[prefix].word) {
    pairs.add((prefix, prefix));
    prefix++;
  }
  final rows = a.length - prefix, columns = b.length - prefix;
  if (rows == 0 || columns == 0) return pairs;

  final table = List.generate(rows + 1, (_) => List.filled(columns + 1, 0));
  for (var i = rows - 1; i >= 0; i--) {
    for (var j = columns - 1; j >= 0; j--) {
      table[i][j] = a[prefix + i].word == b[prefix + j].word
          ? table[i + 1][j + 1] + 1
          : math.max(table[i + 1][j], table[i][j + 1]);
    }
  }
  var i = 0, j = 0;
  while (i < rows && j < columns) {
    if (a[prefix + i].word == b[prefix + j].word) {
      pairs.add((prefix + i, prefix + j));
      i++;
      j++;
    } else if (table[i + 1][j] >= table[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return pairs;
}

final _bracketed = RegExp(r'\([^()]*\)|\[[^\[\]]*\]');

/// A lyric line's words outside brackets, for finding repeats of a line.
String _repeatKey(String text) => _norm(text.replaceAll(_bracketed, ' '));

/// [chords] placed on [from] moved to the same words of [to], whose words
/// outside brackets are the same. Null when a chord cannot be placed.
List<ChordAnchor>? _retargetChords(
  String from,
  String to,
  List<ChordAnchor> chords,
) {
  List<({int start, int end})> words(String text) {
    final masked = text.replaceAllMapped(
      _bracketed,
      (match) => ' ' * match[0]!.length,
    );
    return [
      for (final match in RegExp(r'\S+').allMatches(masked))
        (start: match.start, end: match.end),
    ];
  }

  final source = words(from), target = words(to);
  if (source.isEmpty || source.length != target.length) return null;
  final fromCharacters = from.characters.length == from.length;
  final toCharacters = to.characters.length == to.length;
  // Offsets count grapheme clusters; only plain lines map one to one.
  if (!fromCharacters || !toCharacters) return null;
  final moved = <ChordAnchor>[];
  for (final chord in chords) {
    var index = source.indexWhere((word) => chord.offset < word.end);
    if (index < 0) {
      moved.add(ChordAnchor(to.length, chord.chord));
      continue;
    }
    final inWord = (chord.offset - source[index].start).clamp(
      0,
      target[index].end - target[index].start,
    );
    moved.add(ChordAnchor(target[index].start + inWord, chord.chord));
  }
  return moved;
}

/// Exact whole-line contexts for charts whose rows subdivide lyric paragraphs.
/// Complete contexts provide exact evidence independently of fuzzy alignment.
/// Source intervals may support repeated identical contexts, but cannot lend
/// overlapping evidence to different contexts. Conflicting occurrences abstain.
Map<int, List<ChordAnchor>> _exactContextChords(
  List<ArrangementLine> target,
  String chart,
) {
  if (chart.length > 200000 || target.length > 5000) return const {};
  final source = parseArrangement(chart);
  bool usable(ArrangementLine line) =>
      !line.directive &&
      sectionLabelForLine(line) == null &&
      line.text.length <= 2000 &&
      line.text.characters.length == line.text.length &&
      _lineWords(line.text).isNotEmpty;
  final groups =
      <
        String,
        ({
          List<(int, int, String)> anchors,
          String signature,
          List<(int, int)> ranges,
        })
      >{};
  final ambiguous = <String>{};
  var budget = 100000;
  for (var start = 0; start < source.length; start++) {
    final tokens = <String>[];
    final anchors = <(int, int, String)>[];
    for (var end = start; end < source.length && end < start + 8; end++) {
      final line = source[end];
      if (!usable(line)) break;
      final words = _lineWords(line.text);
      if (tokens.length + words.length > 80) break;
      budget -= words.length;
      if (budget < 0) return const {};
      for (final chord in line.chords) {
        final next = words.indexWhere((word) => chord.offset < word.end);
        final word = next < 0 ? words.length - 1 : next;
        final inside = next < 0
            ? words[word].end - words[word].start
            : (chord.offset - words[word].start).clamp(
                0,
                words[word].end - words[word].start,
              );
        anchors.add((tokens.length + word, inside, chord.chord));
      }
      tokens.addAll(words.map((word) => word.word));
      if (end == start ||
          tokens.length < 12 ||
          tokens.toSet().length < 6 ||
          anchors.isEmpty) {
        continue;
      }
      final key = tokens.join(' ');
      final signature = jsonEncode(
        anchors.map((a) => [a.$1, a.$2, a.$3]).toList(),
      );
      final prior = groups[key];
      if (prior != null) {
        if (prior.signature != signature) ambiguous.add(key);
        prior.ranges.add((start, end + 1));
      } else {
        groups[key] = (
          anchors: List.of(anchors),
          signature: signature,
          ranges: [(start, end + 1)],
        );
      }
    }
  }
  final matches =
      <
        ({
          String key,
          int start,
          int end,
          List<({int line, int start, int end})> words,
        })
      >[];
  for (var start = 0; start < target.length; start++) {
    final tokens = <String>[];
    final locations = <({int line, int start, int end})>[];
    for (var end = start; end < target.length && end < start + 3; end++) {
      if (!usable(target[end])) break;
      final words = _lineWords(target[end].text);
      if (tokens.length + words.length > 80) break;
      budget -= words.length;
      if (budget < 0) return const {};
      tokens.addAll(words.map((word) => word.word));
      locations.addAll(
        words.map((word) => (line: end, start: word.start, end: word.end)),
      );
      final key = tokens.join(' ');
      if (groups.containsKey(key) && !ambiguous.contains(key)) {
        matches.add((
          key: key,
          start: start,
          end: end + 1,
          words: List.of(locations),
        ));
      }
    }
  }
  matches.sort((a, b) {
    final length = b.words.length.compareTo(a.words.length);
    return length != 0 ? length : a.start.compareTo(b.start);
  });
  final claimedLines = <int>{};
  final used = <({int start, int end, String key})>[];
  final result = <int, List<ChordAnchor>>{};
  for (final match in matches) {
    if (List.generate(
      match.end - match.start,
      (i) => match.start + i,
    ).any(claimedLines.contains)) {
      continue;
    }
    final group = groups[match.key]!;
    final available = group.ranges.where(
      (range) => !used.any(
        (prior) =>
            prior.key != match.key &&
            range.$1 < prior.end &&
            prior.start < range.$2,
      ),
    );
    if (available.isEmpty) continue;
    final mapped = <int, List<ChordAnchor>>{};
    var conflict = false;
    for (final (word, inside, chord) in group.anchors) {
      final location = match.words[word];
      final offset =
          location.start + inside.clamp(0, location.end - location.start);
      final line = mapped.putIfAbsent(location.line, () => []);
      if (line.any(
        (anchor) => anchor.offset == offset && anchor.chord != chord,
      )) {
        conflict = true;
        break;
      }
      if (!line.any(
        (anchor) => anchor.offset == offset && anchor.chord == chord,
      )) {
        line.add(ChordAnchor(offset, chord));
      }
    }
    if (conflict) continue;
    result.addAll(mapped);
    claimedLines.addAll(
      List.generate(match.end - match.start, (i) => match.start + i),
    );
    final range = available.first;
    used.add((start: range.$1, end: range.$2, key: match.key));
  }
  return result;
}
