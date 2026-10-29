import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'arrangement.dart' show containsChords;
import 'models.dart';

final _versionHeading = RegExp(
  r'^(?:version|arrangement)\s*\d+$',
  caseSensitive: false,
);
final _titledVersionHeading = RegExp(
  r'^(.*?)\s*[\[(]\s*(?:version|arrangement)\s*\d+\s*[\])]$',
  caseSensitive: false,
);
final _capoLine = RegExp(
  r'^\s*capo\s*(?:[:=]\s*)?(\d+|[ivx]+)\s*(?:fret\w*)?\s*$|^\s*(\d+|[ivx]+)\s+capo\s*$',
  caseSensitive: false,
);
final _tuningLine = RegExp(
  r'^\s*tuning\s*[:=]\s*(.+?)\s*$',
  caseSensitive: false,
);
// "Tuned half step down - Eb Ab Db Gb Bb Eb" and similar retuning notes.
final _detunedLine = RegExp(
  r'^\s*(?:tuned\s+(?:down\s+)?(?:a\s+)?(?:half|1/2|whole|full)[\s-]*(?:step|tone)(?:\s+down)?|(?:half|1/2|whole)[\s-]*(?:step|tone)\s+down(?:\s+tuning)?)\b[\s:=\-–]*(.*?)\s*$',
  caseSensitive: false,
);
final _keyLine = RegExp(
  r'^\s*key(?:\s+of)?\s*[:=]\s*(.+?)\s*$',
  caseSensitive: false,
);
const _romanCapos = {
  'i': 1,
  'ii': 2,
  'iii': 3,
  'iv': 4,
  'v': 5,
  'vi': 6,
  'vii': 7,
  'viii': 8,
  'ix': 9,
  'x': 10,
  'xi': 11,
  'xii': 12,
};
const _arrangementFields = {'capo', 'key', 'tuning', 'timeSignature'};

/// The tuning a retuning note declares: its string notes when it lists
/// six, otherwise the note itself.
String? _detunedValue(String line) {
  final match = _detunedLine.firstMatch(line);
  if (match == null) return null;
  final notes = RegExp(
    r'[A-G][#b]?',
  ).allMatches(match.group(1)!).map((note) => note[0]!).toList();
  return notes.length == 6
      ? notes.join(' ')
      : line.trim().replaceAll(RegExp(r'[\[\]]'), '');
}

int? _capoValue(String line) {
  final match = _capoLine.firstMatch(line);
  if (match == null) return null;
  final label = (match.group(1) ?? match.group(2)!).toLowerCase();
  final value = int.tryParse(label) ?? _romanCapos[label];
  return value != null && value >= 0 && value <= 12 ? value : null;
}

String _headingTitle(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'\bchords\s*$'), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim()
    .replaceFirst(RegExp(r'^the\s+'), '');

bool _isVersionHeading(String line, String title) {
  var label = line.trim();
  if ((label.startsWith('[') && label.endsWith(']')) ||
      (label.startsWith('(') && label.endsWith(')'))) {
    label = label.substring(1, label.length - 1).trim();
  }
  if (_versionHeading.hasMatch(label)) return true;
  final titled = _titledVersionHeading.firstMatch(label);
  return titled != null &&
      _headingTitle(title).isNotEmpty &&
      _headingTitle(titled.group(1)!) == _headingTitle(title);
}

/// Splits a provider result that explicitly contains multiple complete charts.
/// Ordinary section labels (verse, chorus, bridge, etc.) never create a split.
/// Version headings, capo declarations and retuning notes ("tuned half step
/// down") delimit views; a song is not retuned midway. Later key or
/// "tuning:" annotations can describe a modulation and remain inside the same
/// chart.
/// The original result remains the canonical source payload; returned views
/// carry only their own chart text and parent references.
List<SourceResult> splitChartArrangements(SourceResult source) {
  if (source.arrangementId != null &&
          source.extra['retainedPayloadView'] != true ||
      source.body.length > 200000) {
    return const [];
  }
  final lines = source.body.replaceAll('\r\n', '\n').split('\n');
  final boundaries = <int>[];
  var segmentStart = 0;
  bool currentHasChords(int through) =>
      lines.skip(segmentStart).take(through - segmentStart).any(containsChords);

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (i > segmentStart &&
        currentHasChords(i) &&
        (_capoValue(line) != null ||
            _detunedValue(line) != null ||
            _isVersionHeading(line, source.candidate.title))) {
      boundaries.add(i);
      segmentStart = i;
    }
  }
  if (boundaries.isEmpty) return const [];

  final starts = [0, ...boundaries];
  final ends = [...boundaries, lines.length];
  final views = <SourceResult>[];
  final usedIds = <String>{};
  for (var part = 0; part < starts.length; part++) {
    final rawLines = lines.sublist(starts[part], ends[part]);
    final setup = <String, Object?>{};
    final bodyLines = <String>[];
    var chartStarted = false;
    for (final line in rawLines) {
      final capo = _capoValue(line);
      final tuning = _tuningLine.firstMatch(line);
      final key = _keyLine.firstMatch(line);
      if (!chartStarted && capo != null) {
        setup['capo'] = capo;
        continue;
      }
      if (!chartStarted && tuning != null) {
        setup['tuning'] = tuning.group(1)!.trim();
        continue;
      }
      final detuned = _detunedValue(line);
      if (!chartStarted && detuned != null) {
        setup['tuning'] = detuned;
        continue;
      }
      if (!chartStarted && key != null) {
        setup['key'] = key.group(1)!.trim();
        continue;
      }
      if (!chartStarted && _isVersionHeading(line, source.candidate.title)) {
        continue;
      }
      bodyLines.add(line);
      chartStarted = chartStarted || containsChords(line);
    }
    final viewBody = bodyLines.join('\n').trim();
    if (!containsChords(viewBody)) continue;
    // Page-level setup belongs to the initial chart. Later versions need their
    // own declarations; in particular an omitted key must not become a copy of
    // the first chart's key. Apply the same scope to candidate and resolved
    // metadata so discovery claims cannot reintroduce that inherited setup.
    final scopedSetup = <String, dynamic>{
      if (part > 0) 'capo': 0,
      if (part == 0)
        for (final metadata in [source.candidate.metadata, source.metadata])
          for (final key in _arrangementFields)
            if (metadata[key] != null && metadata[key] != '')
              key: metadata[key],
      ...setup,
    };
    JsonMap scopedMetadata(JsonMap original) => {
      for (final entry in original.entries)
        if (!_arrangementFields.contains(entry.key)) entry.key: entry.value,
      ...scopedSetup,
    };
    final metadata = scopedMetadata(source.metadata);
    final candidate = SongCandidate.fromJson({
      ...source.candidate.toJson(),
      'metadata': scopedMetadata(source.candidate.metadata),
    });
    final hashInput = jsonEncode({'body': viewBody, 'setup': scopedSetup});
    final arrangementId = sha256
        .convert(utf8.encode(hashInput))
        .toString()
        .substring(0, 16);
    if (!usedIds.add(arrangementId)) continue;
    final startLine = starts[part] + 1;
    final endLine = ends[part];
    views.add(
      SourceResult(
        candidate: candidate,
        body: viewBody,
        metadata: metadata,
        matchKind: source.matchKind,
        attribution: source.attribution,
        matchReason: source.matchReason,
        retrievedAt: source.retrievedAt,
        arrangementId: arrangementId,
        extra: {
          for (final entry in source.extra.entries)
            if (!const {
              'discoveryEvidence',
              'providerAlternatives',
              'originalPayload',
              'keyConsensus',
              'keyShift',
              'keyEstimate',
            }.contains(entry.key))
              entry.key: entry.value,
          'parentSourceId': source.id,
          'parentCandidate': source.candidate.toJson(),
          'arrangement': {
            'startLine': startLine,
            'endLine': endLine,
            'bodyHash': sha256.convert(utf8.encode(viewBody)).toString(),
            'setup': setup,
          },
        },
      ),
    );
  }
  return views.length >= 2 ? views : const [];
}
