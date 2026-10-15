import 'dart:convert';
import 'models.dart';
import 'arrangement.dart';
import 'timing.dart' show timingOccurrenceMap;

String _norm(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();
double? _validDuration(Object? value) {
  if (value is! num) return null;
  final seconds = value.toDouble();
  return seconds.isFinite && seconds > 0 && seconds <= 86400 ? seconds : null;
}

String _version(String title) => RegExp(
  r'\b(live|acoustic|remix|instrumental|karaoke|demo)\b',
  caseSensitive: false,
).allMatches(title).map((m) => m.group(0)!.toLowerCase()).join(' ');
String _baseTitle(String title) => _norm(
  title.replaceAll(
    RegExp(
      r'\s*[\(\[][^\)\]]*\b(?:live|acoustic|remix|instrumental|karaoke|demo|remaster)\b[^\)\]]*[\)\]]',
      caseSensitive: false,
    ),
    '',
  ),
);
bool _sameSong(SongCandidate a, SongCandidate b) {
  final artist = _norm(a.artist), title = _baseTitle(a.title);
  // Two unknown (empty) artists or titles are not evidence of the same song.
  if (artist.isEmpty || title.isEmpty) return false;
  return artist == _norm(b.artist) && title == _baseTitle(b.title);
}

bool _hasRecordingIdentityScope(SongCandidate candidate) =>
    candidate.metadata['identityScope'] == 'recording';
bool _demonstrationTimingSelected(
  SongCandidate selected,
  SourceResult source,
  TimingTrack track,
) =>
    track.extra['recordingEvidence'] != 'sourceDemonstrationOnly' ||
    (_hasRecordingIdentityScope(selected) &&
        (selected.identity == source.candidate.identity ||
            selected.recordingIds.entries.any(
              (e) => source.candidate.recordingIds[e.key] == e.value,
            )));
bool recordingCompatible(SongCandidate selected, SourceResult result) {
  if (result.matchKind == MatchKind.rejected ||
      !_sameSong(selected, result.candidate)) {
    return false;
  }
  final found = result.candidate;
  if (_version(selected.title) != _version(found.title)) return false;
  for (final entry in selected.recordingIds.entries) {
    if (found.recordingIds.containsKey(entry.key) &&
        found.recordingIds[entry.key] != entry.value) {
      return false;
    }
  }
  if (selected.durationSeconds != null &&
      found.durationSeconds != null &&
      (selected.durationSeconds! - found.durationSeconds!).abs() > 3) {
    return false;
  }
  // Provider identity can name a composition, work, artist, or image. Only
  // treat identical candidate IDs as recording evidence when that identity
  // is explicitly scoped to a recording (or is a legacy unscoped ID).
  final selectedScope = selected.metadata['identityScope'];
  final foundScope = found.metadata['identityScope'];
  const nonRecordingScopes = {'composition', 'work', 'artist', 'image'};
  if (selected.identity == found.identity &&
      !nonRecordingScopes.contains(selectedScope) &&
      !nonRecordingScopes.contains(foundScope)) {
    return true;
  }
  if (selected.recordingIds.entries.any(
    (e) => found.recordingIds[e.key] == e.value,
  )) {
    return true;
  }
  return result.matchKind == MatchKind.sameRecording &&
      selected.album != null &&
      found.album != null &&
      _norm(selected.album!) == _norm(found.album!) &&
      selected.durationSeconds != null &&
      found.durationSeconds != null;
}

bool _completeChart(String chart, String reference) {
  List<String> words(String value) =>
      _norm(plainLyrics(value)).split(' ').where((w) => w.isNotEmpty).toList();
  final a = words(chart), b = words(reference);
  if (a.length < 12 || b.length < 12) return true;
  Map<String, int> counts(List<String> list) {
    final m = <String, int>{};
    for (final x in list) {
      m[x] = (m[x] ?? 0) + 1;
    }
    return m;
  }

  double coverage(List<String> left, List<String> right) {
    final available = counts(right);
    var matched = 0;
    for (final word in left) {
      if ((available[word] ?? 0) > 0) {
        matched++;
        available[word] = available[word]! - 1;
      }
    }
    return matched / left.length;
  }

  List<String> bigrams(List<String> values) => [
    for (var i = 0; i < values.length - 1; i++) '${values[i]} ${values[i + 1]}',
  ];
  return coverage(a, b) >= .80 &&
      coverage(b, a) >= .85 &&
      coverage(bigrams(a), bigrams(b)) >= .65 &&
      coverage(bigrams(b), bigrams(a)) >= .65;
}

SongDocument combineSources(
  SongCandidate selected,
  List<SourceResult> results, {
  String? preferredSourceId,
}) {
  final matching = results
      .where(
        (s) =>
            s.matchKind != MatchKind.rejected &&
            _sameSong(s.candidate, selected),
      )
      .toList();
  final accepted = matching
      .where((s) => plainLyrics(s.body).trim().isNotEmpty)
      .toList();
  if (accepted.isEmpty) {
    throw const FormatException('No matching lyrics are available to save.');
  }
  final references =
      accepted
          .where((s) => !s.hasChords && s.matchKind != MatchKind.unverified)
          .toList()
        ..sort(
          (a, b) =>
              plainLyrics(b.body).length.compareTo(plainLyrics(a.body).length),
        );
  final eligible = accepted
      .where(
        (source) =>
            !source.hasChords ||
            references.isEmpty ||
            _completeChart(source.body, references.first.body),
      )
      .toList();
  if (eligible.isEmpty) {
    throw const FormatException('No complete matching lyrics are available.');
  }
  int rank(SourceResult s) =>
      (s.hasChords ? 1000 : 0) +
      (recordingCompatible(selected, s)
          ? 200
          : s.matchKind == MatchKind.sameSong
          ? 100
          : 0) +
      (s.timingTracks.isNotEmpty ? 30 : 0) +
      (lyricLines(s.body).length.clamp(0, 100));
  eligible.sort((a, b) => rank(b).compareTo(rank(a)));
  final preferred = eligible.where((s) => s.id == preferredSourceId);
  if (preferredSourceId != null && preferred.isEmpty) {
    throw const FormatException(
      'The selected source does not contain a complete matching arrangement.',
    );
  }
  final best = preferred.isEmpty ? eligible.first : preferred.first;
  const arrangementFields = {
    'key',
    'capo',
    'tuning',
    'tempo',
    'timeSignature',
    'difficulty',
    'arrangement',
  };
  final metadata = <String, dynamic>{
    ...selected.metadata,
    if (selected.album != null) 'album': selected.album,
  };
  final selectedDuration =
      _validDuration(selected.durationSeconds) ??
      _validDuration(selected.metadata['durationSeconds']);
  if (selectedDuration == null) {
    metadata.remove('durationSeconds');
  } else {
    metadata['durationSeconds'] = selectedDuration;
  }
  metadata.removeWhere((key, _) => arrangementFields.contains(key));
  final origins = <String, dynamic>{
    for (final k in metadata.keys) k: selected.identity,
  };
  final conflicts = <String, dynamic>{};
  // An explicit version choice should carry the duration shown on that
  // version card. Automatic combination keeps the selected catalog record's
  // metadata as the default, as it has no user-selected source to prefer.
  if (preferredSourceId != null) {
    final preferredDuration =
        _validDuration(best.candidate.durationSeconds) ??
        _validDuration(best.metadata['durationSeconds']);
    if (preferredDuration != null) {
      metadata['durationSeconds'] = preferredDuration;
      origins['durationSeconds'] = best.id;
    }
  }
  const songFields = {
    'genre',
    'language',
    'composer',
    'lyricist',
    'writers',
    'copyright',
    'license',
    'licenseUrl',
    'attribution',
  };
  for (final source in [best, ...matching.where((s) => s.id != best.id)]) {
    final facts = {
      ...source.candidate.metadata,
      if (source.candidate.album != null) 'album': source.candidate.album,
      if (_validDuration(source.candidate.durationSeconds) != null)
        'durationSeconds': _validDuration(source.candidate.durationSeconds),
      ...source.metadata,
    };
    final sourceDuration = _validDuration(facts['durationSeconds']);
    if (facts.containsKey('durationSeconds') && sourceDuration == null) {
      facts.remove('durationSeconds');
    } else if (sourceDuration != null) {
      facts['durationSeconds'] = sourceDuration;
    }
    final sameRecording = recordingCompatible(selected, source);
    for (final entry in facts.entries) {
      if (entry.value == null || entry.value == '') continue;
      final isArrangement = arrangementFields.contains(entry.key);
      if (isArrangement && source.id != best.id) continue;
      if (!isArrangement && !songFields.contains(entry.key) && !sameRecording) {
        continue;
      }
      if (isArrangement ||
          !metadata.containsKey(entry.key) ||
          metadata[entry.key] == null) {
        metadata[entry.key] = entry.value;
        origins[entry.key] = source.id;
      } else if (jsonEncode(metadata[entry.key]) != jsonEncode(entry.value)) {
        (conflicts[entry.key] ??= <dynamic>[]).add({
          'sourceId': source.id,
          'value': entry.value,
        });
      }
    }
  }
  final tracks = <String, TimingTrack>{};
  for (final source in results) {
    for (final track in source.timingTracks) {
      if (tracks.containsKey(track.id)) continue;
      var status = track.status;
      if (status != TimingStatus.invalid &&
          status != TimingStatus.unsupported) {
        status = source.matchKind == MatchKind.rejected
            ? TimingStatus.incompatible
            : !_demonstrationTimingSelected(selected, source, track)
            ? TimingStatus.unverified
            : !recordingCompatible(selected, source)
            ? TimingStatus.unverified
            : lyricOrderHash(track.sourceLyrics) != lyricOrderHash(best.body)
            ? TimingStatus.incompatible
            : TimingStatus.usable;
      }
      tracks[track.id] = track.copyWith(
        status: status,
        lyricHash: lyricOrderHash(track.sourceLyrics),
        extra: {
          ...track.extra,
          'binding': {
            'arrangementLyricHash': lyricOrderHash(best.body),
            'sourceId': source.id,
            'recordingVerified':
                recordingCompatible(selected, source) &&
                _demonstrationTimingSelected(selected, source, track),
            if (status == TimingStatus.usable)
              'occurrences': timingOccurrenceMap(track, best.body),
          },
        },
      );
    }
  }
  final usable = tracks.values.where((t) => t.status == TimingStatus.usable);
  return SongDocument(
    id: newId(),
    title: selected.title,
    artist: selected.artist,
    body: best.body,
    metadata: metadata,
    sources: results,
    timingTracks: tracks.values.toList(),
    selectedRecording: selected,
    activeTimingTrackId: usable.isEmpty ? null : usable.first.id,
    extra: {
      'selectedSourceId': best.id,
      'fieldOrigins': origins,
      if (conflicts.isNotEmpty) 'conflicts': conflicts,
      'recommendation': best.hasChords
          ? 'Matching lyrics with a complete chord arrangement.'
          : 'Best matching available lyrics.',
      'excludedIncompleteSourceIds': accepted
          .where((s) => !eligible.contains(s))
          .map((s) => s.id)
          .toList(),
    },
  );
}
