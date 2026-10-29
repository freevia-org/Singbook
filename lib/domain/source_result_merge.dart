import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'lyrics_variants.dart';
import 'arrangement.dart';
import 'edition_identity.dart';
import 'models.dart';

const _historyKey = 'previousSourceVersions';

Object? _ordered(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _ordered(value[key])};
  }
  if (value is List) return value.map(_ordered).toList();
  return value;
}

String _json(Object? value) => jsonEncode(_ordered(value));

JsonMap _timingPayload(TimingTrack track) =>
    {
        ...track.toJson(),
        'id': track.extra['archivedOriginalTrackId'] ?? track.id,
      }
      ..remove('archivedOriginalTrackId')
      ..remove('status')
      ..remove('binding');

String timingPayloadFingerprint(TimingTrack track) =>
    sha256.convert(utf8.encode(_json(_timingPayload(track)))).toString();

/// Content identity includes metadata and raw timing, not only lyric text.
/// Archiving a timing track must not create a new historical payload on every
/// subsequent save. Retrieval timestamps and the history container are not
/// changes to the source's actual facts.
String sourcePayloadFingerprint(SourceResult source) {
  final payload = {...source.toJson()}
    ..remove(_historyKey)
    ..remove('unparsedSourceHistory')
    ..remove('metadataPayloadOrigins')
    ..remove('retrievedAt')
    ..remove('retainedPreviousPayload');
  payload['timingTracks'] = [
    for (final track in source.timingTracks) _timingPayload(track),
  ];
  return sha256.convert(utf8.encode(_json(payload))).toString();
}

bool _present(Object? value) =>
    value != null &&
    (value is! String || value.trim().isNotEmpty) &&
    (value is! Iterable || value.isNotEmpty) &&
    (value is! Map || value.isNotEmpty);

String _identity(String value) => value
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

bool _sameEvidence(SourceResult a, SourceResult b) {
  if (a.id != b.id ||
      _identity(a.candidate.title) != _identity(b.candidate.title) ||
      _identity(a.candidate.artist) != _identity(b.candidate.artist)) {
    return false;
  }
  for (final entry in a.candidate.recordingIds.entries) {
    final other = b.candidate.recordingIds[entry.key];
    if (other != null && other != entry.value) return false;
  }
  final leftAlbum = a.candidate.album, rightAlbum = b.candidate.album;
  if (leftAlbum != null &&
      rightAlbum != null &&
      _identity(leftAlbum) != _identity(rightAlbum)) {
    return false;
  }
  final left = a.candidate.durationSeconds;
  final right = b.candidate.durationSeconds;
  if (!explicitEditionsCompatible(
    a.candidate,
    b.candidate,
    selectedMetadata: a.metadata,
    selectedExtra: a.extra,
    metadata: b.metadata,
    extra: b.extra,
  )) {
    return false;
  }
  return left == null || right == null || (left - right).abs() <= 3;
}

bool _addsCompatibleArrangement(SourceResult previous, SourceResult incoming) {
  final before = parseArrangement(previous.body);
  final after = parseArrangement(incoming.body);
  final oldLines = before
      .where((line) => !line.directive && line.text.trim().isNotEmpty)
      .toList();
  final newLines = after
      .where((line) => !line.directive && line.text.trim().isNotEmpty)
      .toList();
  if (oldLines.length != newLines.length || oldLines.isEmpty) return false;
  for (final field in ['key', 'capo', 'tuning', 'timeSignature']) {
    final oldValue =
        previous.metadata[field] ?? previous.candidate.metadata[field];
    final newValue =
        incoming.metadata[field] ?? incoming.candidate.metadata[field];
    if (_present(oldValue) &&
        _present(newValue) &&
        _json(oldValue) != _json(newValue)) {
      return false;
    }
    if (previous.hasChords && _present(oldValue) != _present(newValue)) {
      return false;
    }
  }
  var addsChords = false;
  for (var i = 0; i < oldLines.length; i++) {
    if (_identity(oldLines[i].text) != _identity(newLines[i].text)) {
      return false;
    }
    for (final chord in oldLines[i].chords) {
      if (!newLines[i].chords.any(
        (other) => other.offset == chord.offset && other.chord == chord.chord,
      )) {
        return false;
      }
    }
    if (newLines[i].chords.length > oldLines[i].chords.length) {
      addsChords = true;
    }
  }
  final oldSections = before
      .where((line) => line.directive)
      .map((line) => line.text)
      .toList();
  final newSections = after
      .where((line) => line.directive)
      .map((line) => line.text)
      .toList();
  if (oldSections.any((section) => !newSections.contains(section))) {
    return false;
  }
  return addsChords || newSections.length > oldSections.length;
}

bool _conflictingSetup(SourceResult previous, SourceResult incoming) =>
    const ['key', 'capo', 'tuning', 'timeSignature'].any((field) {
      final oldValue =
          previous.metadata[field] ?? previous.candidate.metadata[field];
      final newValue =
          incoming.metadata[field] ?? incoming.candidate.metadata[field];
      return _present(oldValue) &&
          _present(newValue) &&
          _json(oldValue) != _json(newValue);
    });

bool _preservesArrangement(SourceResult previous, SourceResult incoming) {
  final oldLines = parseArrangement(previous.body);
  final newLines = parseArrangement(incoming.body);
  var cursor = 0;
  for (final line in oldLines.where(
    (line) => !line.directive && line.text.trim().isNotEmpty,
  )) {
    while (cursor < newLines.length &&
        (newLines[cursor].directive ||
            _identity(newLines[cursor].text) != _identity(line.text))) {
      cursor++;
    }
    if (cursor == newLines.length) return false;
    if (line.chords.any(
      (chord) => !newLines[cursor].chords.any(
        (other) => other.offset == chord.offset && other.chord == chord.chord,
      ),
    )) {
      return false;
    }
    cursor++;
  }
  final sections = newLines
      .where((line) => line.directive)
      .map((line) => line.text)
      .toList();
  for (final section in oldLines.where((line) => line.directive)) {
    if (!sections.remove(section.text)) return false;
  }
  return true;
}

bool _compatibleScopes(SourceResult previous, SourceResult incoming) {
  Set<String> scopes(SourceResult source) => {
    for (final map in [
      source.candidate.metadata,
      source.candidate.extra,
      source.metadata,
      source.extra,
    ])
      if (map['identityScope'] is String) map['identityScope'] as String,
  };
  const restricted = {
    'composition',
    'work',
    'artist',
    'image',
    'historicalText',
    'arrangement',
  };
  final old = scopes(previous), fresh = scopes(incoming);
  if (old.any(restricted.contains) || fresh.any(restricted.contains)) {
    return false;
  }
  return true;
}

int _authority(SourceResult source) => source.hasPendingMatchCheck
    ? 0
    : switch (source.matchKind) {
        MatchKind.sameRecording => 3,
        MatchKind.sameSong => 2,
        MatchKind.unverified => 1,
        MatchKind.rejected => -1,
      };

JsonMap _historyPayload(SourceResult source) => {...source.toJson()}
  ..remove(_historyKey)
  ..remove('unparsedSourceHistory')
  ..remove('retainedPreviousPayload');

/// Combines successive payloads for the same provider reference. A final
/// rejection always withdraws authority. A transient blank/partial update
/// cannot erase already accepted lyrics or facts, and all distinct payloads
/// remain recoverable without granting archived data active timing authority.
SourceResult mergeSourceResult(SourceResult previous, SourceResult incoming) {
  if (previous.id != incoming.id) return incoming;
  final sameEvidence = _sameEvidence(previous, incoming);
  SourceResult chosen = incoming;
  if (sameEvidence && incoming.matchKind != MatchKind.rejected) {
    final oldRank = _authority(previous), newRank = _authority(incoming);
    if (oldRank > newRank ||
        (oldRank >= 1 &&
            previous.body.trim().isNotEmpty &&
            incoming.body.trim().isEmpty)) {
      chosen = previous;
    } else if (oldRank >= 1 && newRank == oldRank) {
      final fuller = preferCompatibleLyrics(previous.body, [incoming.body]);
      // Different, non-corroborated lyric text remains an alternative. Newer
      // arrival and raw length alone do not establish a better arrangement.
      if ((previous.body == incoming.body &&
              previous.timingTracks.isNotEmpty &&
              incoming.timingTracks.isEmpty) ||
          _conflictingSetup(previous, incoming) ||
          !_preservesArrangement(previous, incoming) ||
          (fuller != incoming.body &&
              previous.body != incoming.body &&
              !_addsCompatibleArrangement(previous, incoming))) {
        chosen = previous;
      }
    }
  }

  final facts = <String, dynamic>{...chosen.metadata};
  final payloadOrigins = {...jsonMap(chosen.extra['metadataPayloadOrigins'])};
  final conflicts = {...jsonMap(chosen.extra['metadataConflicts'])};
  final other = identical(chosen, previous) ? incoming : previous;
  if (sameEvidence &&
      _compatibleScopes(previous, incoming) &&
      _authority(chosen) >= 2 &&
      _authority(other) >= 2 &&
      incoming.matchKind != MatchKind.rejected) {
    const displayFields = {
      'album',
      'artworkUrl',
      'durationSeconds',
      'credits',
      'artistCredits',
      'composer',
      'lyricist',
      'language',
      'genres',
      'releaseDate',
      'year',
    };
    final otherFacts = {
      for (final entry in other.candidate.metadata.entries)
        if (displayFields.contains(entry.key)) entry.key: entry.value,
      if (other.candidate.album != null) 'album': other.candidate.album,
      if (other.candidate.durationSeconds != null)
        'durationSeconds': other.candidate.durationSeconds,
      ...other.metadata,
    };
    for (final entry in otherFacts.entries) {
      if (const {
        'identityScope',
        'recordingIds',
        'record',
        'query',
        'rights',
        'providerId',
        'id',
        'title',
        'artist',
        'body',
        'lyrics',
        'timingTracks',
      }.contains(entry.key)) {
        continue;
      }
      if (const {
            'key',
            'capo',
            'tuning',
            'timeSignature',
            'tempo',
            'difficulty',
            'arrangement',
          }.contains(entry.key) &&
          chosen.body != other.body &&
          (chosen.hasChords ||
              other.hasChords ||
              _conflictingSetup(chosen, other) ||
              preferCompatibleLyrics(other.body, [chosen.body]) !=
                  chosen.body)) {
        continue;
      }
      if (!_present(entry.value)) continue;
      if (!_present(facts[entry.key])) {
        facts[entry.key] = entry.value;
        payloadOrigins[entry.key] =
            jsonMap(other.extra['metadataPayloadOrigins'])[entry.key] ??
            sourcePayloadFingerprint(other);
      } else if (!const {
            'key',
            'capo',
            'tuning',
            'timeSignature',
            'tempo',
            'difficulty',
            'arrangement',
          }.contains(entry.key) &&
          facts[entry.key] is List &&
          entry.value is List) {
        final values = <String, dynamic>{};
        for (final value in [
          ...facts[entry.key] as List,
          ...entry.value as List,
        ]) {
          values.putIfAbsent(_json(value), () => value);
        }
        final keys = values.keys.toList()..sort();
        facts[entry.key] = [for (final key in keys) values[key]];
      } else if (_json(facts[entry.key]) != _json(entry.value)) {
        final values = <String, dynamic>{};
        for (final value in [
          if (conflicts[entry.key] is List)
            ...conflicts[entry.key] as List
          else if (conflicts[entry.key] != null)
            conflicts[entry.key],
          facts[entry.key],
          entry.value,
        ]) {
          values.putIfAbsent(_json(value), () => value);
        }
        final keys = values.keys.toList()..sort();
        conflicts[entry.key] = [for (final key in keys) values[key]];
      }
    }
  }

  final history = <String, JsonMap>{};
  final inertHistory = <String, dynamic>{};
  for (final source in [previous, incoming]) {
    final inert = source.extra['unparsedSourceHistory'];
    if (inert is List) {
      for (final item in inert) {
        inertHistory.putIfAbsent(_json(item), () => item);
      }
    } else if (inert != null) {
      inertHistory.putIfAbsent(_json(inert), () => inert);
    }
    final container = source.extra[_historyKey];
    final values = container is List ? container : [?container];
    for (final raw in values) {
      try {
        if (raw is! Map) throw const FormatException('Invalid source history');
        final payload = jsonMap(raw);
        final archived = SourceResult.fromJson(payload);
        history.putIfAbsent(sourcePayloadFingerprint(archived), () => payload);
      } catch (_) {
        // Unknown/imported history is recoverable data, never active evidence.
        inertHistory.putIfAbsent(_json(raw), () => raw);
      }
    }
    history.putIfAbsent(
      sourcePayloadFingerprint(source),
      () => _historyPayload(source),
    );
  }
  final result = SourceResult(
    candidate: chosen.candidate,
    arrangementId: chosen.arrangementId,
    body: chosen.body,
    metadata: facts,
    timingTracks: chosen.timingTracks,
    matchKind: chosen.matchKind,
    attribution: chosen.attribution,
    matchReason: chosen.matchReason,
    retrievedAt: chosen.retrievedAt,
    extra: {
      ...chosen.extra,
      if (conflicts.isNotEmpty) 'metadataConflicts': conflicts,
      if (payloadOrigins.isNotEmpty) 'metadataPayloadOrigins': payloadOrigins,
      if (identical(chosen, previous) &&
          sourcePayloadFingerprint(previous) !=
              sourcePayloadFingerprint(incoming))
        'retainedPreviousPayload': true,
    },
  );
  history.remove(sourcePayloadFingerprint(result));
  final keys = history.keys.toList()..sort();
  return result.copyWith(
    extra: {
      ...result.extra,
      if (keys.isNotEmpty || result.extra.containsKey(_historyKey))
        _historyKey: [for (final key in keys) history[key]],
      if (inertHistory.isNotEmpty)
        'unparsedSourceHistory': inertHistory.values.toList(),
    },
  );
}

JsonMap _savedTimingState(SongDocument song) {
  final payloads =
      song.timingTracks.map(timingPayloadFingerprint).toSet().toList()..sort();
  final active = song.timingTracks
      .where((track) => track.id == song.activeTimingTrackId)
      .firstOrNull;
  return {
    'payloads': payloads,
    'activePayload': active == null ? null : timingPayloadFingerprint(active),
    if (song.activeTimingTrackId != null && active == null)
      'unresolvedActiveId': song.activeTimingTrackId,
  };
}

/// Explicit version replacement still chooses the incoming version. Keep the
/// replaced document recoverable, including manual lyrics/metadata that were
/// never a provider SourceResult. These snapshots are never active evidence.
List<JsonMap> retainedSavedVersions(
  SongDocument previous,
  SongDocument incoming,
) {
  const key = 'previousSavedVersions';
  final history = <String, JsonMap>{};
  void retain(JsonMap snapshot) {
    final comparison = {...snapshot}
      ..remove('updatedAt')
      ..remove('revision');
    history.putIfAbsent(_json(comparison), () => snapshot);
  }

  for (final document in [previous, incoming]) {
    final oldHistory = document.extra[key];
    if (oldHistory is List) {
      for (final item in oldHistory) {
        if (item is Map) retain(jsonMap(item));
      }
    }
  }
  final prior = previous.toJson();
  prior['extra'] = {...previous.extra}..remove(key);
  final changed =
      previous.title != incoming.title ||
      previous.artist != incoming.artist ||
      previous.body != incoming.body ||
      _json(previous.metadata) != _json(incoming.metadata) ||
      _json(previous.selectedRecording?.toJson()) !=
          _json(incoming.selectedRecording?.toJson()) ||
      _json(_savedTimingState(previous)) !=
          _json(_savedTimingState(incoming)) ||
      incoming.extra.entries.any(
        (entry) =>
            entry.key != key &&
            previous.extra.containsKey(entry.key) &&
            _json(previous.extra[entry.key]) != _json(entry.value),
      );
  if (changed) retain(prior);
  return history.values.toList(growable: false);
}
