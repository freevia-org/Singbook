part of 'service.dart';

/// Chord providers whose charts are transcribed against the recording itself
/// (Songsterr's tabs play in sync with the original audio), unlike user
/// arrangements that are often written in a singer's key.
const _recordingTranscriptions = {'songsterr'};

typedef _LyricPair = ({
  SongCandidate chart,
  SongCandidate reference,
  String chartBody,
  String referenceBody,
  bool alternatePerformer,
  bool shortRecording,
});
typedef _LyricScore = ({
  bool agrees,
  bool scriptAlternative,
  bool contextualPartial,
  bool loose,
});

typedef _LyricReferenceFacts = ({
  int words,
  bool short,
  bool hasLyrics,
  bool hasChords,
});

Future<_LyricReferenceFacts> _scoreLyricReference(String body) =>
    Isolate.run(() {
      final hasChords = containsChords(body);
      return (
        words: hasChords ? 0 : _words(body).toSet().length,
        short: !hasChords && isShortRecordingLyricBody(body),
        hasLyrics: plainLyrics(body).trim().isNotEmpty,
        hasChords: hasChords,
      );
    }, debugName: 'singbook-source-body-facts');

Future<List<_LyricScore>> _scoreLyricPairs(List<_LyricPair> pairs) =>
    Isolate.run(() => [for (final pair in pairs) _scoreLyricPair(pair)]);

_LyricScore _scoreLyricPair(_LyricPair pair) {
  final strict = _agreement(
    pair.chartBody,
    pair.referenceBody,
    allowShortRecordingReference: pair.shortRecording,
  );
  final script = publishedLyricScriptAlternative(
    pair.reference,
    pair.chart,
    pair.referenceBody,
    pair.chartBody,
  );
  final partial =
      pair.alternatePerformer &&
      !strict &&
      contextualChartLyricsMatch(
        pair.chartBody,
        pair.referenceBody,
        allowPartial: true,
      );
  final agrees = strict || script || partial;
  return (
    agrees: agrees,
    scriptAlternative: script,
    contextualPartial: partial,
    loose:
        !agrees &&
        (_partialAgreement(pair.chartBody, pair.referenceBody) ||
            _noisyAgreement(pair.chartBody, pair.referenceBody)),
  );
}

Object? _chartSetup(SourceResult source, String field) =>
    source.metadata[field] ?? source.candidate.metadata[field];

/// The only chart facts the key workers read. Whole results also carry their
/// discovery evidence and alternatives, which would be copied per isolate hop.
typedef _KeyChart = ({
  String body,
  Object? capo,
  Object? key,
  String providerId,
});

List<_KeyChart> _keyCharts(List<SourceResult> sources) => [
  for (final source in sources)
    (
      body: source.body,
      capo: _chartSetup(source, 'capo'),
      key: _chartSetup(source, 'key'),
      providerId: source.candidate.providerId,
    ),
];

Future<bool> _needsChordKeyCheck(List<SourceResult> charts, String? measured) =>
    _needsChordKeyCheckFor(_keyCharts(charts), measured);

Future<bool> _needsChordKeyCheckFor(List<_KeyChart> charts, String? measured) =>
    Isolate.run(() {
      final first = charts.first;
      return charts
              .skip(1)
              .any(
                (chart) =>
                    (soundingTransposition(
                          first.body,
                          first.capo,
                          chart.body,
                          chart.capo,
                        ) ??
                        0) !=
                    0,
              ) ||
          charts.any((chart) {
            final declared = chart.key;
            return declared is String &&
                declared.trim().isNotEmpty &&
                !declaredKeyFitsChords(
                  chart.body,
                  declared.trim(),
                  chart.capo,
                );
          }) ||
          measured != null &&
              charts.any((chart) {
                final key = soundingChartKey(chart.body, chart.capo);
                return key != null && !keysAgree(key, measured);
              });
    });

Future<bool> _scoreKeyVoteLyrics(
  String body,
  List<String> charts,
  String? reference,
  bool shortReference,
) => Isolate.run(
  () => reference == null
      ? charts.any(
          (chart) => _agreement(body, chart) || _partialAgreement(body, chart),
        )
      : _agreement(
              body,
              reference,
              allowShortRecordingReference: shortReference,
            ) ||
            _partialAgreement(body, reference) ||
            _noisyAgreement(body, reference),
);

Future<({List<int?> shifts, String? keyEstimate})?> _scoreChordKeys(
  List<SourceResult> sources,
  int acceptedCount,
  String? recordingKey,
) => _scoreChordKeysFor(_keyCharts(sources), acceptedCount, recordingKey);

Future<({List<int?> shifts, String? keyEstimate})?> _scoreChordKeysFor(
  List<_KeyChart> sources,
  int acceptedCount,
  String? recordingKey,
) => Isolate.run(() {
  final bodies = [for (final source in sources) source.body];
  final capos = [for (final source in sources) source.capo];
  final outcome = chordKeyVerdict(
    bodies,
    recordingKey: recordingKey,
    capos: capos,
    declaredKeys: [
      for (final source in sources)
        if (source.key case final String key) key else null,
    ],
    anchors: [
      for (var n = 0; n < sources.length; n++)
        n < acceptedCount &&
            _recordingTranscriptions.contains(sources[n].providerId),
    ],
  );
  if (outcome == null) return null;
  final estimates = <String>{};
  for (var n = 0; n < bodies.length; n++) {
    final shift = outcome.shifts[n];
    if (shift == null) continue;
    final body = bodies[n];
    final shapes = estimateChordKey(
      shift == 0 ? body : transposeBody(body, shift),
    )?.key;
    if (shapes == null) continue;
    final capo = capos[n];
    final frets = capo is num ? capo.toInt() : int.tryParse('${capo ?? ''}');
    estimates.add(
      frets == null || frets <= 0 ? shapes : transposeChord(shapes, frets),
    );
  }
  return (
    shifts: outcome.shifts,
    keyEstimate: estimates.length == 1
        ? estimates.single
        : estimates.isEmpty && outcome.recordingAgrees
        ? recordingKey
        : null,
  );
});

List<String> _words(String body) => normalizedIdentity(
  foldLyricVowelAccents(body)
      .replaceAll(RegExp(r'\{[^}\n]*\}'), ' ')
      .replaceAll(RegExp(r'(?<!\\)\[[^\]\n]*\]'), ''),
).split(' ').where((w) => w.isNotEmpty).toList();
bool _agreement(
  String chart,
  String reference, {
  bool allowShortRecordingReference = false,
}) {
  if (allowShortRecordingReference &&
      shortRecordingLyricAgreement(chart, reference)) {
    return true;
  }
  return contextualChartLyricsMatch(chart, reference);
}

/// A chord chart can carry the whole song among notes that are not lyrics:
/// chords typed as text, tab and strumming notation, links, capo or tuning
/// instructions and commentary. Judge only its lyric-like lines (three or
/// more words, at least 70% of them in the reference): they must cover most
/// of the reference's words in the same order. A different song with the
/// same title has no such lines.
bool _noisyAgreement(String chart, String reference) {
  final referenceWords = _words(reference);
  final vocabulary = referenceWords.toSet();
  if (vocabulary.length < 12) return false;
  final lyricWords = <String>[];
  var lyricLines = 0;
  for (final line in chart.split('\n')) {
    final words = _words(line);
    if (words.length < 3) continue;
    final known = words.where(vocabulary.contains).length;
    if (known / words.length < .7) continue;
    lyricLines++;
    lyricWords.addAll(words);
  }
  if (lyricLines < 4) return false;
  final covered = lyricWords.toSet().intersection(vocabulary);
  if (covered.length / vocabulary.length < .6) return false;
  Set<String> bigrams(List<String> values) => {
    for (var i = 1; i < values.length; i++) '${values[i - 1]} ${values[i]}',
  };
  final pairs = bigrams(lyricWords);
  return pairs.isNotEmpty &&
      pairs.intersection(bigrams(referenceWords)).length / pairs.length >= .75;
}

bool _partialAgreement(String chart, String reference) {
  final words = _words(chart), referenceWords = _words(reference);
  final unique = words.toSet(), referenceUnique = referenceWords.toSet();
  final common = unique.intersection(referenceUnique);
  if (common.length < 12 || common.length / unique.length < .90) return false;
  Set<String> bigrams(List<String> values) => {
    for (var i = 1; i < values.length; i++) '${values[i - 1]} ${values[i]}',
  };
  final pairs = bigrams(words);
  return pairs.isNotEmpty &&
      pairs.intersection(bigrams(referenceWords)).length / pairs.length >= .75;
}
