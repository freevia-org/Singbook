import 'dart:convert';
import 'dart:io' show Directory;
import 'dart:isolate';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/models.dart';
import '../domain/chordpro.dart';
import '../domain/arrangement.dart';
import '../domain/song_identity.dart';
import '../domain/combine.dart';
import '../domain/source_result_merge.dart';

Map<String, Object?> _songRow(SongDocument song, String document) {
  final fullDocument = song.extensionError == null
      ? null
      : jsonEncode(song.toJson());
  final fullDocumentHash = fullDocument == null
      ? null
      : sha256.convert(utf8.encode(fullDocument)).toString();
  final documentHash = _localSongHash(document, fullDocumentHash);
  return {
    'id': song.id,
    'title': song.title,
    'artist': song.artist,
    'album': song.metadata['album']?.toString(),
    'favorite': song.favorite ? 1 : 0,
    'document': document,
    'document_hash': documentHash,
    'evidence_hash': '',
    'content_hash': documentHash,
    'full_document': fullDocument,
    'full_document_hash': fullDocumentHash,
    'lyric_hash': lyricOrderHash(song.body),
    'search_text': LibraryRepository.searchText(
      song.title,
      song.artist,
      song.metadata['album']?.toString(),
      plainLyrics(song.body),
    ),
    'source_identity': song.extra['selectedSourceId'] as String?,
    'revision': song.revision,
    'created_at': song.createdAt.toUtc().toIso8601String(),
    'updated_at': song.updatedAt.toUtc().toIso8601String(),
  };
}

typedef _StagedDiscoverySource = ({
  String id,
  String payload,
  String hash,
  int order,
});

List<_StagedDiscoverySource> _encodeDiscoveryBatch(List<SourceResult> sources) {
  final observations = <({String id, JsonMap snapshot, String hash})?>[];
  final latest = <String, int>{};
  final snapshots =
      Map<
        SourceResult,
        ({String id, JsonMap snapshot, String hash})
      >.identity();
  for (final source in sources) {
    final observation = snapshots.putIfAbsent(source, () {
      final snapshot = source.toJson();
      return (
        id: source.id,
        snapshot: snapshot,
        hash: sourceArchiveFingerprint(snapshot),
      );
    });
    final snapshot = observation.snapshot;
    final previousIndex = latest[observation.id];
    if (previousIndex != null && snapshot.containsKey('discoveryEvidence')) {
      final previous = observations[previousIndex]!;
      // The provider can publish a chart before its final provenance arrives.
      // Drop that provisional observation only if the final chart is equal
      // and the earlier observation has no evidence of its own.
      if (!previous.snapshot.containsKey('discoveryEvidence') &&
          !previous.snapshot.containsKey('previousSourceVersions') &&
          previous.hash ==
              sourceArchiveFingerprint(
                {...snapshot}
                  ..remove('discoveryEvidence')
                  ..remove('previousSourceVersions'),
              )) {
        observations[previousIndex] = null;
      }
    }
    latest[observation.id] = observations.length;
    observations.add(observation);
  }
  // The archive keeps the first payload and insertion order. Comparison
  // follows the last observation, even if a provider returns to older text.
  final distinct = <(String, String), _StagedDiscoverySource>{};
  var order = 0;
  for (final observation in observations.nonNulls) {
    final key = (observation.id, observation.hash);
    distinct[key] = (
      id: observation.id,
      payload: distinct[key]?.payload ?? jsonEncode(observation.snapshot),
      hash: observation.hash,
      order: ++order,
    );
  }
  return distinct.values.toList(growable: false);
}

Future<List<_StagedDiscoverySource>> _prepareDiscoveryBatch(
  List<SourceResult> sources,
) => Isolate.run(() => _encodeDiscoveryBatch(sources));

Future<String> _hashEvidenceIndex(
  List<Map<String, Object?>> evidence,
  List<Map<String, Object?>> versions,
) => Isolate.run(() {
  // Keep the ordered encoding stable for existing rows and sync peers.
  final index = {
    'evidence': [
      for (final row in evidence)
        [row['candidate_identity'], row['source_id'], row['payload_hash']],
    ],
    'versions': [
      for (final row in versions)
        if (row['kind'] == 0) row['hash'],
    ],
    for (final row in versions)
      if (row['kind'] == 1) 'importedHistory': row['hash'],
  };
  return sha256.convert(utf8.encode(jsonEncode(index))).toString();
});

const _mergeDiagnosticsKey = 'libraryMergeDiagnosticsHash';
const _mergeDiagnosticFields = ['conflicts', 'fieldContributors'];

class _MissingStagedMergeDiagnostics implements Exception {
  const _MissingStagedMergeDiagnostics();
}

typedef _MergeDiagnostics = ({String payload, String hash});

({SongDocument song, _MergeDiagnostics? diagnostics}) _splitMergeDiagnostics(
  SongDocument song,
) {
  final extra = {...song.extra};
  final fields = {
    for (final key in _mergeDiagnosticFields)
      if (extra.containsKey(key)) key: extra.remove(key),
  };
  if (fields.isEmpty) return (song: song, diagnostics: null);
  final diagnostics = _encodeMergeDiagnostics(fields);
  extra[_mergeDiagnosticsKey] = diagnostics.hash;
  return (
    song: song.copyWith(
      extra: extra,
      revision: song.revision,
      updatedAt: song.updatedAt,
    ),
    diagnostics: diagnostics,
  );
}

_MergeDiagnostics _encodeMergeDiagnostics(JsonMap fields) {
  Object? ordered(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: ordered(value[key])};
    }
    if (value is List) return value.map(ordered).toList();
    return value;
  }

  final payload = jsonEncode(ordered(fields));
  final hash = sha256.convert(utf8.encode(payload)).toString();
  return (payload: payload, hash: hash);
}

Future<_MergeDiagnostics> _prepareMergeDiagnostics(JsonMap fields) =>
    Isolate.run(
      () => _encodeMergeDiagnostics(fields),
      debugName: 'singbook-stage-merge-diagnostics',
    );

typedef _ArchivedSongPayload = ({
  String hash,
  String documentHash,
  String document,
  String? fullDocument,
  String? fullHash,
});

typedef _StoredSourcePayload = ({String payload, String hash, int generation});

Future<SongDocument> _restoreStoredEvidence(
  SongDocument current,
  List<_ArchivedSongPayload> versions,
  List<_StoredSourcePayload> sources, {
  required bool latestSourcesOnly,
  ({String payload, String hash})? importedHistory,
  required Map<String, String> diagnosticPayloads,
}) => Isolate.run(() {
  SongDocument restoreDiagnostics(SongDocument song) {
    final hash = song.extra[_mergeDiagnosticsKey];
    if (hash == null) return song;
    final payload = diagnosticPayloads[hash];
    if (payload == null ||
        sha256.convert(utf8.encode(payload)).toString() != hash) {
      throw const FormatException('invalid_local_data');
    }
    final extra = {...song.extra}..remove(_mergeDiagnosticsKey);
    extra.addAll(jsonMap(jsonDecode(payload)));
    return song.copyWith(
      extra: extra,
      revision: song.revision,
      updatedAt: song.updatedAt,
    );
  }

  current = restoreDiagnostics(current);
  final byId = <String, SourceResult>{};
  final tokens = <String, String>{};
  SourceResult archivedView(SourceResult source, String token) => SourceResult(
    candidate: source.candidate,
    arrangementId: '${source.arrangementId ?? source.id}#history=$token',
    body: source.body,
    metadata: source.metadata,
    timingTracks: source.timingTracks,
    matchKind: MatchKind.rejected,
    attribution: source.attribution,
    matchReason: 'superseded_version',
    retrievedAt: source.retrievedAt,
    extra: {...source.extra, 'archivedSourceVersion': true},
  );
  void addSource(SourceResult source, String token) {
    final prior = byId[source.id];
    if (prior == null) {
      byId[source.id] = source;
      tokens[source.id] = token;
    } else if (prior.matchKind == MatchKind.rejected &&
        source.matchKind != MatchKind.rejected) {
      if (prior.body != source.body) {
        final history = archivedView(prior, tokens[source.id] ?? 'previous');
        byId[history.id] = history;
      }
      byId[source.id] = source;
      tokens[source.id] = token;
    } else {
      byId[source.id] = mergeSourceResult(prior, source);
      tokens[source.id] = token;
    }
  }

  for (final source in current.sources) {
    addSource(source, 'current');
  }
  final savedVersions = <String, JsonMap>{};
  void retainVersions(Object? snapshots) {
    if (snapshots is! List) return;
    for (final item in snapshots.whereType<Map>()) {
      final snapshot = jsonMap(item);
      final digest = sha256
          .convert(utf8.encode(jsonEncode(snapshot)))
          .toString();
      savedVersions.putIfAbsent(digest, () => snapshot);
    }
  }

  if (!latestSourcesOnly) {
    retainVersions(current.extra['previousSavedVersions']);
  }
  if (importedHistory != null) {
    final (:payload, :hash) = importedHistory;
    if (sha256.convert(utf8.encode(payload)).toString() != hash) {
      throw const FormatException('invalid_local_data');
    }
    final history = jsonMap(jsonDecode(payload));
    for (final item in (history['sources'] as List).whereType<Map>()) {
      final source = SourceResult.fromJson(jsonMap(item));
      if (!latestSourcesOnly || source.extra['archivedSourceVersion'] != true) {
        addSource(source, 'imported');
      }
    }
    if (!latestSourcesOnly) retainVersions(history['previousSavedVersions']);
  }
  for (final version in versions) {
    final contentHash = version.hash;
    final document = version.document;
    final full = version.fullDocument;
    final fullHash = version.fullHash;
    if (version.documentHash != _localSongHash(document, fullHash)) {
      throw const FormatException('invalid_local_data');
    }
    if (full != null &&
        sha256.convert(utf8.encode(full)).toString() != fullHash) {
      throw const FormatException('invalid_local_data');
    }
    final prior = restoreDiagnostics(
      full == null
          ? ChordProCodec().decode(document)
          : SongDocument.fromJson(jsonMap(jsonDecode(full))),
    );
    retainVersions(prior.extra['previousSavedVersions']);
    final snapshot = prior.toJson();
    snapshot['extra'] = {...prior.extra}..remove('previousSavedVersions');
    retainVersions([snapshot]);
    for (final source in prior.sources) {
      addSource(source, 'version-${contentHash.substring(0, 12)}');
    }
  }
  for (final evidence in sources) {
    final payload = evidence.payload;
    final hash = evidence.hash;
    final snapshot = jsonMap(jsonDecode(payload));
    if (sourceArchiveFingerprint(snapshot) != hash &&
        sha256.convert(utf8.encode(payload)).toString() != hash) {
      throw const FormatException('invalid_local_data');
    }
    final source = SourceResult.fromJson(snapshot);
    if (latestSourcesOnly) {
      byId[source.id] = source.candidate.providerId == 'wikisource'
          ? source
          : source.copyWith(
              extra: {...source.extra}
                ..remove('previousSourceVersions')
                ..remove('unparsedSourceHistory')
                ..remove('discoveryEvidence'),
            );
      continue;
    }
    addSource(
      source,
      'generation-${evidence.generation}-${hash.substring(0, 12)}',
    );
  }
  return current.copyWith(
    sources: byId.values.toList(growable: false),
    extra: {
      ...current.extra,
      if (savedVersions.isNotEmpty)
        'previousSavedVersions': savedVersions.values.toList(growable: false),
    },
    revision: current.revision,
    updatedAt: current.updatedAt,
  );
}, debugName: 'singbook-restore-evidence');

Future<
  ({
    Map<String, Object?> row,
    String payload,
    String hash,
    _MergeDiagnostics? diagnostics,
  })
>
_prepareImportedHistory(SongDocument song) => Isolate.run(() {
  final extra = {...song.extra};
  final versions = extra.remove('previousSavedVersions');
  final playable = song.copyWith(
    sources: const [],
    extra: extra,
    revision: song.revision,
    updatedAt: song.updatedAt,
  );
  final payload = jsonEncode({
    'sources': song.sources.map((source) => source.toJson()).toList(),
    'previousSavedVersions': ?versions,
  });
  final split = _splitMergeDiagnostics(playable);
  return (
    row: _songRow(split.song, ChordProCodec().encode(split.song)),
    diagnostics: split.diagnostics,
    payload: payload,
    hash: sha256.convert(utf8.encode(payload)).toString(),
  );
}, debugName: 'singbook-import-history');

Future<Map<String, Object?>> _prepareSongRow(SongDocument song) =>
    Isolate.run(() => _songRow(song, ChordProCodec().encode(song)));

bool _sameJsonValue(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every(
          (key) => b.containsKey(key) && _sameJsonValue(a[key], b[key]),
        );
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameJsonValue(a[i], b[i])) return false;
    }
    return true;
  }
  return a.runtimeType == b.runtimeType && a == b;
}

/// Prepare the chosen chart and its search index without carrying archived
/// source bodies into the worker. A repeat Save can still attach new evidence.
Future<
  ({
    SongDocument song,
    Map<String, Object?>? row,
    _MergeDiagnostics? diagnostics,
    bool useStagedDiagnostics,
  })
>
_prepareChosenSongRow({
  required SongDocument song,
  required SongDocument? prior,
  required bool priorHasSources,
  required DateTime now,
  required String candidateIdentity,
  required String? stagedDiagnosticsHash,
}) => Isolate.run(() {
  final incoming = _sanitizeImportedDurations(song, includeSources: false);
  return _buildChosenSongRow(
    incoming,
    prior,
    priorHasSources: priorHasSources,
    now: now,
    candidateIdentity: candidateIdentity,
    stagedDiagnosticsHash: stagedDiagnosticsHash,
  );
}, debugName: 'singbook-chosen-chart');

({
  SongDocument song,
  Map<String, Object?>? row,
  _MergeDiagnostics? diagnostics,
  bool useStagedDiagnostics,
})
_buildChosenSongRow(
  SongDocument song,
  SongDocument? prior, {
  required bool priorHasSources,
  required DateTime now,
  required String candidateIdentity,
  required String? stagedDiagnosticsHash,
}) {
  final activeTimingId = song.activeTimingTrackId;
  final activeTiming = activeTimingId == null
      ? null
      : song.timingTracks
            .where((track) => track.id == activeTimingId)
            .firstOrNull;
  final playableTimingTracks = activeTiming != null
      ? [activeTiming]
      : song.timingTracks
            .where((track) => track.origin == 'user')
            .toList(growable: false);
  final incomingMetadata = {...song.metadata};
  final priorMetadata =
      prior?.metadata.entries ?? const <MapEntry<String, dynamic>>[];
  final priorOrigins = jsonMap(prior?.extra['fieldOrigins']);
  final incomingOrigins = jsonMap(song.extra['fieldOrigins']);
  bool removedByUser(String field) =>
      incomingOrigins[field] == 'user' &&
      !_hasMeaningfulMetadata(incomingMetadata[field]);
  final carry = <String, dynamic>{
    for (final entry in priorMetadata)
      if (_replacementCarryMetadata.contains(entry.key) &&
          !removedByUser(entry.key) &&
          !_hasMeaningfulMetadata(incomingMetadata[entry.key]) &&
          _hasMeaningfulMetadata(entry.value))
        entry.key: entry.value,
    for (final entry in priorMetadata)
      if (priorOrigins[entry.key] == 'user' &&
          !removedByUser(entry.key) &&
          !_hasMeaningfulMetadata(incomingMetadata[entry.key]))
        entry.key: entry.value,
  };
  final origins = {...incomingOrigins};
  for (final field in carry.keys) {
    final origin = priorOrigins[field];
    if (origin != null && !incomingOrigins.containsKey(field)) {
      origins[field] = origin;
    }
  }
  const replacedActiveKeys = {
    'selectedSourceId',
    'savedSourceId',
    'combinedSelection',
    'combinedFallbackSource',
    'fieldOrigins',
    'fieldContributors',
    'conflicts',
    'recommendation',
    'chordSourceIds',
    'pendingChordSourceIds',
    'excludedIncompleteSourceIds',
    'keySourceIds',
    'corroboratedKeySourceIds',
    'previousSavedVersions',
    'previousSourceVersions',
    'evidenceRanking',
    'allSourceDiagnostics',
    _mergeDiagnosticsKey,
  };
  final previousContributors = jsonMap(prior?.extra['fieldContributors']);
  final useStagedDiagnostics =
      stagedDiagnosticsHash != null &&
      !carry.keys.any(previousContributors.containsKey);
  final retainedDiagnostics = prior?.extra[_mergeDiagnosticsKey];
  final retainsExistingDiagnostics =
      retainedDiagnostics != null &&
      retainedDiagnostics == song.extra[_mergeDiagnosticsKey] &&
      prior?.body == song.body &&
      !_mergeDiagnosticFields.any(song.extra.containsKey);
  final incomingExtra = {...song.extra}
    ..remove('previousSavedVersions')
    ..remove('previousSourceVersions')
    ..remove('evidenceRanking')
    ..remove('allSourceDiagnostics')
    ..remove(_mergeDiagnosticsKey);
  if (useStagedDiagnostics) {
    incomingExtra.remove('conflicts');
    incomingExtra.remove('fieldContributors');
    incomingExtra[_mergeDiagnosticsKey] = stagedDiagnosticsHash;
  }
  final extra = {
    if (retainsExistingDiagnostics) _mergeDiagnosticsKey: retainedDiagnostics,
    for (final entry
        in prior?.extra.entries ?? const <MapEntry<String, dynamic>>[])
      if (!replacedActiveKeys.contains(entry.key)) entry.key: entry.value,
    ...incomingExtra,
    'fieldOrigins': origins,
    if (!useStagedDiagnostics && !retainsExistingDiagnostics)
      'fieldContributors': {
        for (final field in carry.keys)
          if (previousContributors[field] != null)
            field: previousContributors[field],
        ...jsonMap(song.extra['fieldContributors']),
      },
    if (prior?.extra['rawAssets'] is Map || song.extra['rawAssets'] is Map)
      'rawAssets': {
        ...jsonMap(prior?.extra['rawAssets']),
        ...jsonMap(song.extra['rawAssets']),
      },
    if (candidateIdentity.isNotEmpty)
      'libraryEvidenceIdentity': candidateIdentity,
  };
  final saved = song.copyWith(
    id: prior?.id ?? song.id,
    favorite: prior?.favorite ?? song.favorite,
    createdAt: prior?.createdAt ?? song.createdAt,
    updatedAt: now,
    revision: (prior?.revision ?? 0) + 1,
    metadata: {
      ...incomingMetadata,
      ...carry,
      for (final entry in priorMetadata)
        if (entry.key.startsWith('x_verse_player_')) entry.key: entry.value,
    },
    sources: const [],
    // Timing used by the selected chart remains active. Other source timing
    // is in the durable evidence rows and never competes with this track.
    timingTracks: playableTimingTracks,
    activeTimingTrackId: activeTiming?.id,
    clearActiveTiming: activeTiming == null,
    extra: extra,
  );
  final split = _splitMergeDiagnostics(saved);
  final playable = split.song;
  final canCompare =
      prior != null &&
      !priorHasSources &&
      prior.body.length == playable.body.length &&
      prior.timingTracks.length == playable.timingTracks.length;
  // Ignore only the write-generated revision and clock when deciding whether
  // to replace a chart. Reuse the prior representation for both comparisons.
  late final priorChart = prior!.toJson()
    ..remove('revision')
    ..remove('updatedAt');
  bool sameChart(SongDocument candidate) =>
      canCompare &&
      _sameJsonValue(
        candidate.toJson()
          ..remove('revision')
          ..remove('updatedAt'),
        priorChart,
      );

  Map<String, Object?>? row;
  if (!sameChart(playable)) {
    final codec = ChordProCodec();
    final document = codec.encode(playable);
    // Cold library reads normalize ChordPro headers and timing assets.
    if (!canCompare ||
        prior.body != playable.body ||
        !sameChart(codec.decode(document))) {
      row = _songRow(playable, document);
    }
  }
  return (
    song: playable,
    row: row,
    diagnostics: split.diagnostics,
    useStagedDiagnostics: useStagedDiagnostics,
  );
}

Future<String> _encodeSyncSong(SongDocument song) =>
    Isolate.run(() => ChordProCodec().encode(song));

Future<SongDocument> _decodeLargeSong(String document) =>
    Isolate.run(() => ChordProCodec().decode(document));

Future<(SongDocument, Map<String, Object?>)?> _prepareImportedMerge(
  SongDocument existing,
  SongDocument song, {
  required bool explicitMatch,
}) => Isolate.run(() {
  // An opaque (unreadable) extension block is written back verbatim, so
  // merged sources/timing would be reported as saved but never stored.
  if (existing.extensionError != null) return null;
  final fields = ['key', 'capo', 'tuning', 'tempo', 'timeSignature'];
  // Provider copies may differ only in line endings.
  String lf(String text) => text.replaceAll('\r\n', '\n');
  if (!explicitMatch &&
      (lf(existing.body) != lf(song.body) ||
          fields.any(
            (field) => existing.metadata[field] != song.metadata[field],
          ))) {
    return null;
  }
  final sources = <String, SourceResult>{
    for (final source in existing.sources)
      '${source.id}:${sourcePayloadFingerprint(source)}': source,
  };
  final sameLyrics = lyricOrderHash(existing.body) == lyricOrderHash(song.body);
  final tracks = <String, TimingTrack>{
    for (final track in existing.timingTracks) track.id: track,
  };
  final timingByPayload = <String, TimingTrack>{
    for (final track in tracks.values) timingPayloadFingerprint(track): track,
  };
  TimingTrack retainTrack(TimingTrack track) {
    final payload = timingPayloadFingerprint(track);
    final prior = timingByPayload[payload];
    if (prior != null) return prior;
    final collision = tracks.containsKey(track.id);
    var archiveId = 'history:${existing.id}:$payload';
    while (tracks.containsKey(archiveId)) {
      archiveId = '$archiveId:history';
    }
    final retained = collision
        ? TimingTrack.fromJson({
            ...track.toJson(),
            'id': archiveId,
            'archivedOriginalTrackId':
                track.extra['archivedOriginalTrackId'] ?? track.id,
            'status': track.status == TimingStatus.usable
                ? TimingStatus.stale.name
                : track.status.name,
          })
        : !sameLyrics && track.status == TimingStatus.usable
        ? track.copyWith(status: TimingStatus.stale)
        : track;
    tracks[retained.id] = retained;
    timingByPayload[payload] = retained;
    return retained;
  }

  for (final source in song.sources) {
    final key = '${source.id}:${sourcePayloadFingerprint(source)}';
    final previous = sources[key];
    if (previous != null) {
      sources[key] = mergeSourceResult(source, previous);
    } else {
      sources[key] = source.copyWith(
        timingTracks: source.timingTracks.map(retainTrack).toList(),
      );
    }
  }
  for (final track in song.timingTracks) {
    retainTrack(track);
  }
  final existingOrigins = jsonMap(existing.extra['fieldOrigins']);
  final incomingOrigins = jsonMap(song.extra['fieldOrigins']);
  final incomingSourceId = song.extra['savedSourceId'];
  final incomingSource = incomingSourceId is String
      ? song.sources.where((item) => item.id == incomingSourceId).firstOrNull
      : null;
  final incomingDuration = incomingSource == null
      ? null
      : _validDuration(incomingSource.candidate.durationSeconds) ??
            _validDuration(incomingSource.metadata['durationSeconds']) ??
            _validDuration(
              incomingSource.candidate.metadata['durationSeconds'],
            );
  final existingDuration = _validDuration(existing.metadata['durationSeconds']);
  bool sameDuration(double? a, double? b) =>
      a != null && b != null && (a - b).abs() < .001;
  final durationOrigin = existingOrigins['durationSeconds'];
  SourceResult? existingSourceResult;
  for (final item in existing.sources) {
    if (item.id == durationOrigin) {
      existingSourceResult = item;
      break;
    }
  }
  final existingDurationSource =
      existing.selectedRecording?.identity == durationOrigin
      ? existing.selectedRecording
      : existingSourceResult?.candidate;
  final provenExistingDuration =
      _validDuration(existingDurationSource?.durationSeconds) ??
      _validDuration(existingSourceResult?.metadata['durationSeconds']) ??
      _validDuration(existingDurationSource?.metadata['durationSeconds']);
  final incomingDurationIsProven =
      incomingDuration != null &&
      incomingSourceId is String &&
      incomingOrigins['durationSeconds'] == incomingSourceId &&
      sameDuration(
        incomingDuration,
        _validDuration(song.metadata['durationSeconds']),
      );
  final shouldRefreshDuration =
      existingOrigins['durationSeconds'] != 'user' &&
      incomingDurationIsProven &&
      (existingDuration == null ||
          sameDuration(existingDuration, provenExistingDuration));
  final mergedMetadata = {...song.metadata, ...existing.metadata};
  final mergedOrigins = {...incomingOrigins, ...existingOrigins};
  for (final field in existingOrigins.keys) {
    if (existingOrigins[field] == 'user' &&
        !_hasMeaningfulMetadata(existing.metadata[field])) {
      // An absent user-owned field is an intentional removal, not a
      // missing provider fact to refill on the next import.
      mergedMetadata.remove(field);
    }
  }
  for (final entry in song.metadata.entries) {
    if (existingOrigins[entry.key] == 'user' ||
        !_hasMeaningfulMetadata(entry.value)) {
      continue;
    }
    if (!_hasMeaningfulMetadata(existing.metadata[entry.key])) {
      mergedMetadata[entry.key] = entry.value;
      if (incomingOrigins.containsKey(entry.key)) {
        mergedOrigins[entry.key] = incomingOrigins[entry.key];
      } else {
        mergedOrigins.remove(entry.key);
      }
    } else if (!const {'tuning', 'arrangement'}.contains(entry.key) &&
        existing.metadata[entry.key] is List &&
        entry.value is List) {
      final seen = <String>{};
      mergedMetadata[entry.key] = [
        for (final value in [
          ...existing.metadata[entry.key] as List,
          ...entry.value as List,
        ])
          if (seen.add(jsonEncode(value))) value,
      ];
    }
  }
  final mergedExtra = {
    for (final entry in song.extra.entries)
      if (entry.key != _mergeDiagnosticsKey) entry.key: entry.value,
    ...existing.extra,
    'fieldOrigins': mergedOrigins,
    for (final key in const ['conflicts'])
      if (song.extra[key] is Map || existing.extra[key] is Map)
        key: {...jsonMap(song.extra[key]), ...jsonMap(existing.extra[key])},
  };
  if (shouldRefreshDuration) {
    mergedMetadata['durationSeconds'] = incomingDuration;
    mergedExtra['fieldOrigins'] = {
      ...jsonMap(mergedExtra['fieldOrigins']),
      'durationSeconds': incomingSourceId,
    };
  }
  final mergedContributors = <String, dynamic>{};
  for (final field in {
    ...jsonMap(existing.extra['fieldContributors']).keys,
    ...jsonMap(song.extra['fieldContributors']).keys,
  }) {
    final values = <String>{};
    if (existingOrigins[field] == 'user') {
      final priorContributors = jsonMap(
        existing.extra['fieldContributors'],
      )[field];
      if (priorContributors is List) {
        mergedContributors[field] = [...priorContributors];
      }
      continue;
    }
    for (final document in [existing, song]) {
      final fieldValues = jsonMap(document.extra['fieldContributors'])[field];
      final fact = document.metadata[field];
      final chosen = mergedMetadata[field];
      final contributes =
          jsonEncode(fact) == jsonEncode(chosen) ||
          (fact is List &&
              chosen is List &&
              fact.any(
                (value) =>
                    chosen.any((item) => jsonEncode(item) == jsonEncode(value)),
              ));
      if (fieldValues is! List ||
          !_hasMeaningfulMetadata(fact) ||
          !contributes) {
        continue;
      }
      values.addAll(fieldValues.whereType<String>());
    }
    if (values.isNotEmpty) {
      mergedContributors[field] = values.toList()..sort();
    }
  }
  mergedExtra['fieldContributors'] = mergedContributors;
  final merged = existing.copyWith(
    sources: sources.values.toList(),
    timingTracks: tracks.values.toList(),
    metadata: mergedMetadata,
    extra: mergedExtra,
  );
  return (merged, _songRow(merged, ChordProCodec().encode(merged)));
});

Future<(SongDocument, Map<String, Object?>)> _prepareChosenReplacement(
  SongDocument existing,
  SongDocument song,
) => Isolate.run(() {
  final replacement = _replaceChosenSong(existing, song);
  return (
    replacement,
    _songRow(replacement, ChordProCodec().encode(replacement)),
  );
});

SongDocument _replaceChosenSong(SongDocument existing, SongDocument song) {
  final sources = <String, SourceResult>{};
  String sourceKey(SourceResult source) =>
      '${source.id}:${sourcePayloadFingerprint(source)}';
  final timingIds = {
    for (final track in song.timingTracks) track.id,
    for (final source in song.sources)
      for (final track in source.timingTracks) track.id,
  };
  TimingTrack archiveTrack(String sourcePayload, TimingTrack track) {
    final originalId =
        track.extra['archivedOriginalTrackId'] as String? ?? track.id;
    final hash = sha256.convert(utf8.encode('$sourcePayload\u0000$originalId'));
    var id = 'history:${existing.id}:$hash';
    while (!timingIds.add(id)) {
      id = '$id:history';
    }
    // Source timingTrackIds and the global codec track table must refer to
    // this historical payload, even if the provider reuses a track ID.
    return TimingTrack.fromJson({
      ...track.toJson(),
      'id': id,
      'archivedOriginalTrackId': originalId,
      'status': track.status == TimingStatus.usable
          ? TimingStatus.stale.name
          : track.status.name,
    });
  }

  for (final source in existing.sources) {
    // Retain source history/raw timing for Compare versions, but never
    // promote an archived version's timing onto the newly selected body.
    final key = sourceKey(source);
    sources[key] = source.copyWith(
      timingTracks: [
        for (final track in source.timingTracks) archiveTrack(key, track),
      ],
    );
  }
  for (final source in song.sources) {
    final key = sourceKey(source);
    final previous = sources[key];
    sources[key] = previous == null
        ? source
        : mergeSourceResult(previous, source);
  }
  final existingOrigins = jsonMap(existing.extra['fieldOrigins']);
  final incomingOrigins = jsonMap(song.extra['fieldOrigins']);
  final incomingMetadata = {...song.metadata};
  incomingMetadata.removeWhere((_, value) => !_hasMeaningfulMetadata(value));
  bool incomingRemoval(String field) =>
      incomingOrigins[field] == 'user' &&
      !_hasMeaningfulMetadata(incomingMetadata[field]);
  final keyRemovalTombstone =
      incomingRemoval('key') ||
      (!_hasMeaningfulMetadata(existing.metadata['key']) &&
          existingOrigins['key'] == 'user');
  final recoveredKey =
      !_hasMeaningfulMetadata(incomingMetadata['key']) && !keyRemovalTombstone
      ? sourcedArrangementKey(
          song.copyWith(
            sources: sources.values.toList(),
            metadata: incomingMetadata,
          ),
        )
      : null;
  final carriedMetadata = {
    // Composition credits may fill gaps. Recording and arrangement facts
    // must be established again for the selected version.
    for (final entry in existing.metadata.entries)
      if (_replacementCarryMetadata.contains(entry.key) &&
          !incomingRemoval(entry.key) &&
          !_hasMeaningfulMetadata(incomingMetadata[entry.key]) &&
          _hasMeaningfulMetadata(entry.value))
        entry.key: entry.value,
  };
  final replacementMetadata = {
    ...incomingMetadata,
    ...carriedMetadata,
    if (recoveredKey != null) 'key': recoveredKey.key,
    for (final entry in existing.metadata.entries)
      if (entry.key.startsWith('x_verse_player_')) entry.key: entry.value,
  };
  final incomingExtra = {...song.extra}
    ..remove('keySourceIds')
    ..remove('corroboratedKeySourceIds');
  final origins = {...incomingOrigins};
  final contributors = {...jsonMap(song.extra['fieldContributors'])};
  for (final field in carriedMetadata.keys) {
    origins.remove(field);
    contributors.remove(field);
    if (existingOrigins.containsKey(field)) {
      origins[field] = existingOrigins[field];
    }
    final prior = jsonMap(existing.extra['fieldContributors']);
    if (prior.containsKey(field)) contributors[field] = prior[field];
  }
  // A deliberate removal remains a user decision when the new version
  // also omits that field. A new nonempty value takes incoming authority.
  for (final field in {...existingOrigins.keys, ...incomingOrigins.keys}) {
    if (!const {'lyrics', 'chords', 'sections'}.contains(field) &&
        !_hasMeaningfulMetadata(incomingMetadata[field]) &&
        (incomingRemoval(field) ||
            (existingOrigins[field] == 'user' &&
                !_hasMeaningfulMetadata(existing.metadata[field])))) {
      origins[field] = 'user';
      contributors.remove(field);
    }
  }
  if (!_hasMeaningfulMetadata(incomingMetadata['key'])) {
    origins.remove('key');
    contributors.remove('key');
    if (keyRemovalTombstone) origins['key'] = 'user';
    if (recoveredKey != null) {
      origins['key'] = recoveredKey.sourceIds.first;
      contributors['key'] = recoveredKey.sourceIds;
    }
  }
  return SongDocument(
    id: existing.id,
    title: song.title,
    artist: song.artist,
    body: song.body,
    metadata: replacementMetadata,
    favorite: existing.favorite,
    createdAt: existing.createdAt,
    updatedAt: DateTime.now().toUtc(),
    revision: existing.revision + 1,
    selectedRecording: song.selectedRecording,
    sources: sources.values.toList(),
    timingTracks: song.timingTracks,
    activeTimingTrackId: song.activeTimingTrackId,
    extra: {
      // Preserve supported unknown payload fields, but clear old active
      // selection/provenance fields when the chosen version omits them.
      for (final entry in existing.extra.entries)
        if (!const {
          'selectedSourceId',
          'savedSourceId',
          'combinedSelection',
          'combinedFallbackSource',
          'fieldOrigins',
          'fieldContributors',
          'conflicts',
          'recommendation',
          'chordSourceIds',
          'pendingChordSourceIds',
          'excludedIncompleteSourceIds',
          'keySourceIds',
          'corroboratedKeySourceIds',
        }.contains(entry.key))
          entry.key: entry.value,
      ...incomingExtra,
      // Preserve incoming roles such as chords/sections, and attach old
      // provenance only to values that were actually carried forward.
      'fieldOrigins': origins,
      'fieldContributors': contributors,
      'previousSavedVersions': retainedSavedVersions(existing, song),
      if (recoveredKey != null) 'keySourceIds': recoveredKey.sourceIds,
      if (_hasMeaningfulMetadata(incomingMetadata['key'])) ...{
        if (song.extra['keySourceIds'] is List)
          'keySourceIds': song.extra['keySourceIds'],
        if (song.extra['corroboratedKeySourceIds'] is List)
          'corroboratedKeySourceIds': song.extra['corroboratedKeySourceIds'],
      },
      if (existing.extra['rawAssets'] is Map || song.extra['rawAssets'] is Map)
        'rawAssets': {
          ...jsonMap(existing.extra['rawAssets']),
          ...jsonMap(song.extra['rawAssets']),
        },
    },
    preservedExtensions: {
      ...existing.preservedExtensions,
      ...song.preservedExtensions,
    }.toList(),
  );
}

const _replacementCarryMetadata = {'composer', 'lyricist', 'copyright'};

bool _hasMeaningfulMetadata(Object? value) =>
    value != null &&
    (value is! String || value.trim().isNotEmpty) &&
    (value is! Iterable || value.isNotEmpty) &&
    (value is! Map || value.isNotEmpty);

double? _validDuration(Object? value) {
  if (value is! num) return null;
  final seconds = value.toDouble();
  return seconds.isFinite && seconds > 0 && seconds <= 86400 ? seconds : null;
}

JsonMap _withoutInvalidDuration(JsonMap metadata) {
  final clean = {...metadata};
  if (metadata.containsKey('durationSeconds') &&
      _validDuration(metadata['durationSeconds']) == null) {
    clean.remove('durationSeconds');
  }
  return clean;
}

// Android's CursorWindow cannot return an oversized document as one row.
// Ordinary songs stay on the inline path; large documents cross the platform
// boundary as bounded blobs, without changing their stored ChordPro payload.
const _documentReadChunkSize = 128 * 1024;
const _boundedDocumentColumn =
    'CASE WHEN length(CAST(document AS BLOB)) <= $_documentReadChunkSize '
    'THEN document ELSE NULL END AS document';
const _boundedFullDocumentColumn =
    'CASE WHEN length(CAST(full_document AS BLOB)) <= $_documentReadChunkSize '
    'THEN full_document ELSE NULL END AS full_document';

/// Columns every playable-song read needs. Oversized documents come back as
/// NULL and are then read in chunks.
const _songReadColumns = [
  'id',
  'favorite',
  'revision',
  'created_at',
  'updated_at',
  'content_hash',
  'full_document_hash',
  _boundedDocumentColumn,
  _boundedFullDocumentColumn,
];
const _songSnapshotColumns = [..._songReadColumns, 'document_hash'];
const _songStateColumns = [..._songSnapshotColumns, 'evidence_hash'];

/// Local state hash of a song: its document hash, extended by the hash of the
/// evidence linked to it when there is any.
String _aggregateHash(String documentHash, String evidenceHash) =>
    evidenceHash.isEmpty
    ? documentHash
    : sha256
          .convert(utf8.encode('$documentHash\u0000$evidenceHash'))
          .toString();

/// Hash of a setlist as compared by conditional writes and by sync.
String setlistContentHash(SetlistDocument setlist) =>
    sha256.convert(utf8.encode(jsonEncode(setlist.toJson()))).toString();

Map<String, String> _encodeSyncSongs(List<SongDocument> songs) {
  final codec = ChordProCodec();
  final documents = {for (final song in songs) song.id: codec.encode(song)};
  for (final song in songs) {
    final parsed = codec.decode(documents[song.id]!);
    if (song.extensionError != null ||
        parsed.extensionError != null ||
        parsed.id != song.id) {
      throw const FormatException('invalid_local_data');
    }
  }
  return documents;
}

bool _isSmallSyncBatch(List<SongDocument> songs) {
  if (songs.length > 2) return false;
  var bytes = 0;
  for (final song in songs) {
    bytes += song.body.length;
  }
  return bytes < 64 * 1024;
}

/// Encodes songs applied by sync and checks that each survives the ChordPro
/// round trip with its identity. A pulled batch goes to a worker isolate; one
/// or two small songs stay inline (see [_isSmallSyncBatch]), where an isolate
/// costs more than the work and would delay the transaction past other writes
/// queued right behind the call.
Future<Map<String, String>> _encodeSyncBatchInIsolate(
  List<SongDocument> songs,
) => Isolate.run(
  () => _encodeSyncSongs(songs),
  debugName: 'singbook-sync-encode',
);

String _localSongHash(
  String document,
  String? fullDocumentHash, {
  String evidenceHash = '',
  String? documentHash,
}) {
  if (evidenceHash.isEmpty) {
    return fullDocumentHash == null
        ? sha256.convert(utf8.encode(document)).toString()
        : sha256
              .convert(utf8.encode('$document\u0000$fullDocumentHash'))
              .toString();
  }
  // Keep the existing local payload hash as the base. New evidence can then
  // change the local hash without rereading or re-encoding a large document.
  final payloadHash =
      documentHash ??
      (fullDocumentHash == null
          ? sha256.convert(utf8.encode(document)).toString()
          : sha256
                .convert(utf8.encode('$document\u0000$fullDocumentHash'))
                .toString());
  return _aggregateHash(payloadHash, evidenceHash);
}

SongCandidate _sanitizeCandidateDuration(SongCandidate candidate) =>
    SongCandidate(
      providerId: candidate.providerId,
      id: candidate.id,
      title: candidate.title,
      artist: candidate.artist,
      album: candidate.album,
      url: candidate.url,
      durationSeconds: _validDuration(candidate.durationSeconds),
      metadata: _withoutInvalidDuration(candidate.metadata),
      recordingIds: candidate.recordingIds,
      extra: candidate.extra,
    );

SongDocument _sanitizeImportedDurations(
  SongDocument song, {
  bool includeSources = true,
}) {
  final sources = includeSources
      ? [
          for (final source in song.sources)
            SourceResult(
              candidate: _sanitizeCandidateDuration(source.candidate),
              arrangementId: source.arrangementId,
              body: source.body,
              metadata: _withoutInvalidDuration(source.metadata),
              timingTracks: source.timingTracks,
              matchKind: source.matchKind,
              attribution: source.attribution,
              matchReason: source.matchReason,
              retrievedAt: source.retrievedAt,
              extra: source.extra,
            ),
        ]
      : const <SourceResult>[];
  return SongDocument(
    id: song.id,
    title: song.title,
    artist: song.artist,
    body: song.body,
    metadata: _withoutInvalidDuration(song.metadata),
    sources: sources,
    timingTracks: song.timingTracks,
    favorite: song.favorite,
    createdAt: song.createdAt,
    updatedAt: song.updatedAt,
    selectedRecording: song.selectedRecording == null
        ? null
        : _sanitizeCandidateDuration(song.selectedRecording!),
    activeTimingTrackId: song.activeTimingTrackId,
    revision: song.revision,
    extra: song.extra,
    preservedExtensions: song.preservedExtensions,
    extensionError: song.extensionError,
  );
}

/// What this device and the cloud agreed on for one item the last time they
/// were in sync. Present = "we had synced it": a later absence on one side is a
/// deletion there, not "never existed". [kind] is `song` or `setlist`.
class SyncBaseline {
  const SyncBaseline({
    required this.kind,
    required this.id,
    required this.cloudHash,
    required this.localHash,
  });
  final String kind, id;

  /// Hash of the cloud file body at agreement.
  final String cloudHash;

  /// Hash of local song state at agreement. It may differ from [cloudHash]
  /// after normalisation or when an opaque extension has a local JSON sidecar.
  final String localHash;
  String get key => '$kind:$id';
}

class LibraryRepository {
  final Database database;
  final ChordProCodec _codec = ChordProCodec();
  LibraryRepository._(this.database);

  static Future<LibraryRepository> open({
    String? path,
    DatabaseFactory? factory,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final windows =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    final location =
        path ??
        (windows && factory == null
            ? paths.join(
                (await getApplicationSupportDirectory()).path,
                'databases',
                'verse_library.db',
              )
            : paths.join(
                await dbFactory.getDatabasesPath(),
                'verse_library.db',
              ));
    if (windows && factory == null && path == null) {
      await Directory(paths.dirname(location)).create(recursive: true);
    }
    final db = await dbFactory.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: 11,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE songs (id TEXT PRIMARY KEY, title TEXT NOT NULL, artist TEXT NOT NULL, album TEXT, favorite INTEGER NOT NULL DEFAULT 0, document TEXT NOT NULL, document_hash TEXT NOT NULL, evidence_hash TEXT NOT NULL DEFAULT \'\', content_hash TEXT NOT NULL, lyric_hash TEXT NOT NULL, source_identity TEXT, revision INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, search_text TEXT, full_document TEXT, full_document_hash TEXT)',
          );
          await db.execute(
            'CREATE INDEX songs_title_artist ON songs(title COLLATE NOCASE,artist COLLATE NOCASE)',
          );
          await db.execute(
            'CREATE INDEX songs_source ON songs(source_identity,lyric_hash)',
          );
          await db.execute(
            'CREATE TABLE setlists (id TEXT PRIMARY KEY, name TEXT NOT NULL, notes TEXT NOT NULL, favorite INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE setlist_entries (id TEXT PRIMARY KEY, setlist_id TEXT NOT NULL REFERENCES setlists(id) ON DELETE CASCADE, song_id TEXT NOT NULL REFERENCES songs(id) ON DELETE CASCADE, position INTEGER NOT NULL, overrides TEXT NOT NULL, UNIQUE(setlist_id,position))',
          );
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE activity (id TEXT PRIMARY KEY, object_id TEXT NOT NULL, object_kind TEXT NOT NULL, action TEXT NOT NULL, occurred_at TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE INDEX activity_order ON activity(occurred_at DESC,id DESC)',
          );
          await db.execute(
            'CREATE TABLE outbox (id TEXT PRIMARY KEY, object_id TEXT NOT NULL, object_kind TEXT NOT NULL, action TEXT NOT NULL, revision INTEGER, created_at TEXT NOT NULL)',
          );
          await _createSyncItems(db);
          await _createEntrySongIndex(db);
          await _createEvidenceTables(db);
          await _createImportedHistoryTable(db);
          await _createMergeDiagnosticTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createSyncItems(db);
          if (oldVersion < 3) {
            await _addSearchText(db);
            await _createEntrySongIndex(db);
          }
          if (oldVersion < 4) {
            await db.execute('ALTER TABLE songs ADD COLUMN full_document TEXT');
            await db.execute(
              'ALTER TABLE songs ADD COLUMN full_document_hash TEXT',
            );
          }
          if (oldVersion < 5) {
            await db.execute('ALTER TABLE songs ADD COLUMN document_hash TEXT');
            await db.execute(
              "ALTER TABLE songs ADD COLUMN evidence_hash TEXT NOT NULL DEFAULT ''",
            );
            await db.execute('UPDATE songs SET document_hash = content_hash');
            await _createEvidenceTables(db);
          }
          if (oldVersion < 6) await _createImportedHistoryTable(db);
          if (oldVersion >= 5 && oldVersion < 7) {
            await db.execute(
              'ALTER TABLE discovery_evidence ADD COLUMN observed_generation INTEGER',
            );
            await db.execute(
              'ALTER TABLE discovery_evidence ADD COLUMN observed_order INTEGER',
            );
          }
          if (oldVersion >= 5 && oldVersion < 8) {
            await db.execute('DROP INDEX IF EXISTS discovery_evidence_song');
            await _createEvidenceSongIndex(db);
          }
          if (oldVersion < 11) await _upgradeMergeDiagnosticTables(db);
        },
      ),
    );
    return LibraryRepository._(db);
  }

  static Future<void> _createEvidenceTables(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS discovery_sessions (candidate_identity TEXT PRIMARY KEY, generation INTEGER NOT NULL, song_id TEXT REFERENCES songs(id) ON DELETE SET NULL, sealed INTEGER NOT NULL DEFAULT 0)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS discovery_evidence (candidate_identity TEXT NOT NULL, source_id TEXT NOT NULL, payload_hash TEXT NOT NULL, generation INTEGER NOT NULL, payload TEXT NOT NULL, song_id TEXT REFERENCES songs(id) ON DELETE CASCADE, updated_at TEXT NOT NULL, observed_generation INTEGER, observed_order INTEGER, PRIMARY KEY(candidate_identity, source_id, payload_hash))',
    );
    await _createEvidenceSongIndex(db);
    await db.execute(
      'CREATE TABLE IF NOT EXISTS song_versions (song_id TEXT NOT NULL REFERENCES songs(id) ON DELETE CASCADE, content_hash TEXT NOT NULL, document TEXT NOT NULL, document_hash TEXT NOT NULL, full_document TEXT, full_document_hash TEXT, favorite INTEGER NOT NULL, revision INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, archived_at TEXT NOT NULL, PRIMARY KEY(song_id, content_hash))',
    );
  }

  static Future<void> _createEvidenceSongIndex(DatabaseExecutor db) =>
      db.execute(
        'CREATE INDEX IF NOT EXISTS discovery_evidence_song '
        'ON discovery_evidence(song_id, source_id)',
      );

  static Future<void> _createImportedHistoryTable(DatabaseExecutor db) =>
      db.execute(
        'CREATE TABLE IF NOT EXISTS song_imported_history ('
        'song_id TEXT PRIMARY KEY REFERENCES songs(id) ON DELETE CASCADE, '
        'payload TEXT NOT NULL, payload_hash TEXT NOT NULL)',
      );

  static Future<void> _createMergeDiagnosticTables(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS merge_diagnostic_payloads ('
      'payload_hash TEXT PRIMARY KEY, payload TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS song_merge_diagnostics ('
      'song_id TEXT NOT NULL REFERENCES songs(id) ON DELETE CASCADE, '
      'payload_hash TEXT NOT NULL REFERENCES merge_diagnostic_payloads(payload_hash), '
      'PRIMARY KEY(song_id,payload_hash))',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS discovery_merge_diagnostics ('
      'candidate_identity TEXT NOT NULL, generation INTEGER NOT NULL, '
      'payload_hash TEXT NOT NULL REFERENCES merge_diagnostic_payloads(payload_hash), '
      'created_at TEXT NOT NULL, PRIMARY KEY(candidate_identity,generation,payload_hash))',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS discovery_merge_diagnostics_created '
      'ON discovery_merge_diagnostics(created_at)',
    );
    for (final table in [
      'song_merge_diagnostics',
      'discovery_merge_diagnostics',
    ]) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS ${table}_payload ON $table(payload_hash)',
      );
      await db.execute(
        'CREATE TRIGGER IF NOT EXISTS ${table}_collect_payload AFTER DELETE ON $table '
        'BEGIN DELETE FROM merge_diagnostic_payloads WHERE payload_hash = OLD.payload_hash '
        'AND NOT EXISTS (SELECT 1 FROM song_merge_diagnostics WHERE payload_hash = OLD.payload_hash) '
        'AND NOT EXISTS (SELECT 1 FROM discovery_merge_diagnostics WHERE payload_hash = OLD.payload_hash); END',
      );
    }
  }

  static Future<void> _upgradeMergeDiagnosticTables(DatabaseExecutor db) async {
    final legacy = <String, String>{
      'song_merge_diagnostics': 'song_id,payload_hash',
      'discovery_merge_diagnostics':
          'candidate_identity,generation,payload_hash,created_at',
    };
    final migrated = <String, String>{};
    for (final entry in legacy.entries) {
      final columns = await db.rawQuery('PRAGMA table_info(${entry.key})');
      if (columns.any((column) => column['name'] == 'payload')) {
        await db.execute(
          'ALTER TABLE ${entry.key} RENAME TO ${entry.key}_legacy',
        );
        migrated[entry.key] = entry.value;
      }
    }
    await _createMergeDiagnosticTables(db);
    for (final entry in migrated.entries) {
      final old = '${entry.key}_legacy';
      await db.execute(
        'INSERT OR IGNORE INTO merge_diagnostic_payloads(payload_hash,payload) '
        'SELECT payload_hash,payload FROM $old',
      );
      final mismatch = await db.rawQuery(
        'SELECT 1 FROM $old AS legacy '
        'JOIN merge_diagnostic_payloads AS stored ON stored.payload_hash = legacy.payload_hash '
        'WHERE stored.payload != legacy.payload LIMIT 1',
      );
      if (mismatch.isNotEmpty) {
        throw const FormatException('invalid_local_data');
      }
      await db.execute(
        'INSERT INTO ${entry.key}(${entry.value}) SELECT ${entry.value} FROM $old',
      );
      await db.execute('DROP TABLE $old');
    }
  }

  Future<String?> stageMergeDiagnostics(
    SongDocument document, {
    required String candidateIdentity,
    required int generation,
  }) async {
    final fields = {
      for (final key in _mergeDiagnosticFields)
        if (document.extra.containsKey(key)) key: document.extra[key],
    };
    if (fields.isEmpty) return null;
    final diagnostics = await _prepareMergeDiagnostics(fields);
    await database.transaction((txn) async {
      await _storeMergeDiagnostics(txn, diagnostics);
      await txn.insert('discovery_merge_diagnostics', {
        'candidate_identity': candidateIdentity,
        'generation': generation,
        'payload_hash': diagnostics.hash,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
    return diagnostics.hash;
  }

  Future<void> _linkStagedMergeDiagnostics(
    DatabaseExecutor txn, {
    required String songId,
    required String candidateIdentity,
    required int generation,
    required String hash,
  }) async {
    await txn.rawInsert(
      'INSERT OR IGNORE INTO song_merge_diagnostics(song_id,payload_hash) '
      'SELECT ?,payload_hash FROM discovery_merge_diagnostics '
      'WHERE candidate_identity = ? AND generation = ? AND payload_hash = ?',
      [songId, candidateIdentity, generation, hash],
    );
    final stored = await txn.query(
      'song_merge_diagnostics',
      columns: const ['payload_hash'],
      where: 'song_id = ? AND payload_hash = ?',
      whereArgs: [songId, hash],
      limit: 1,
    );
    if (stored.isEmpty) throw const _MissingStagedMergeDiagnostics();
  }

  Future<void> _storeMergeDiagnostics(
    DatabaseExecutor txn,
    _MergeDiagnostics diagnostics,
  ) async {
    await txn.insert('merge_diagnostic_payloads', {
      'payload_hash': diagnostics.hash,
      'payload': diagnostics.payload,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _writeMergeDiagnostics(
    DatabaseExecutor txn,
    String songId,
    _MergeDiagnostics? diagnostics,
  ) async {
    if (diagnostics == null) return;
    await _storeMergeDiagnostics(txn, diagnostics);
    await txn.insert('song_merge_diagnostics', {
      'song_id': songId,
      'payload_hash': diagnostics.hash,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Begins (or resumes) durable discovery for one recording identity. A
  /// previously saved song remains linked while each new generation replaces
  /// the active generation token.
  Future<void> beginDiscoverySession({
    required String candidateIdentity,
    required int generation,
  }) => database.transaction((txn) async {
    final rows = await txn.query(
      'discovery_sessions',
      columns: const ['generation', 'song_id'],
      where: 'candidate_identity = ?',
      whereArgs: [candidateIdentity],
      limit: 1,
    );
    if (rows.isNotEmpty && (rows.single['generation'] as int) > generation) {
      return;
    }
    final songId = rows.isNotEmpty && rows.single['generation'] == generation
        ? rows.single['song_id'] as String?
        : null;
    final session = {
      'candidate_identity': candidateIdentity,
      'generation': generation,
      'song_id': songId,
      'sealed': 0,
    };
    if (rows.isEmpty) {
      await txn.insert('discovery_sessions', session);
    } else {
      await txn.update(
        'discovery_sessions',
        session,
        where: 'candidate_identity = ?',
        whereArgs: [candidateIdentity],
      );
    }
    // Unattached evidence is a durable resume cache, but bound its lifetime.
    final cutoff = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    await txn.delete(
      'discovery_evidence',
      where: 'song_id IS NULL AND updated_at < ?',
      whereArgs: [cutoff],
    );
    await txn.delete(
      'discovery_merge_diagnostics',
      where: 'created_at < ?',
      whereArgs: [cutoff],
    );
  });

  /// Stores accepted provider evidence before Save. Payload encoding and
  /// hashing happen off the UI isolate; one transaction batches all sources
  /// published in a discovery update.
  Future<String?> stageDiscoverySources({
    required String candidateIdentity,
    required int generation,
    required List<SourceResult> sources,
  }) async {
    if (sources.isEmpty) return null;
    final staged = await _prepareDiscoveryBatch(sources);
    return database.transaction((txn) async {
      final sessions = await txn.rawQuery(
        'SELECT session.generation, session.song_id, session.sealed, '
        'songs.content_hash FROM discovery_sessions AS session '
        'LEFT JOIN songs ON songs.id = session.song_id '
        'WHERE session.candidate_identity = ?',
        [candidateIdentity],
      );
      if (sessions.isEmpty ||
          sessions.single['generation'] != generation ||
          sessions.single['sealed'] == 1) {
        return null;
      }
      final sessionSongId = sessions.single['song_id'] as String?;
      final order = await txn.rawQuery(
        'SELECT MAX(observed_order) AS last_order FROM discovery_evidence '
        'WHERE candidate_identity = ? AND observed_generation = ?',
        [candidateIdentity, generation],
      );
      final lastObservedOrder = order.single['last_order'] as int? ?? 0;
      final known =
          <(String, String), ({String? songId, int? generation, int? order})>{};
      final keys = staged.map((item) => (item.id, item.hash)).toList();
      // Bound the number of parameters for SQLite builds with the legacy cap.
      const lookupBatchSize = 128;
      for (var start = 0; start < keys.length; start += lookupBatchSize) {
        final end = (start + lookupBatchSize).clamp(0, keys.length);
        final chunk = keys.sublist(start, end);
        final placeholders = List.filled(chunk.length, '(?,?)').join(',');
        final existing = await txn.rawQuery(
          'WITH incoming(source_id, payload_hash) AS (VALUES $placeholders) '
          'SELECT e.source_id, e.payload_hash, e.song_id, '
          'e.observed_generation, e.observed_order FROM incoming '
          'JOIN discovery_evidence AS e ON e.candidate_identity = ? '
          'AND e.source_id = incoming.source_id '
          'AND e.payload_hash = incoming.payload_hash',
          [
            for (final (source, hash) in chunk) ...[source, hash],
            candidateIdentity,
          ],
        );
        for (final row in existing) {
          known[(row['source_id'] as String, row['payload_hash'] as String)] = (
            songId: row['song_id'] as String?,
            generation: row['observed_generation'] as int?,
            order: row['observed_order'] as int?,
          );
        }
      }
      final batch = txn.batch();
      final updatedAt = DateTime.now().toUtc().toIso8601String();
      var linkedNewEvidence = false;
      for (final item in staged) {
        final observedOrder = lastObservedOrder + item.order;
        final previous = known[(item.id, item.hash)];
        // Keep the first payload and archive order. Comparison uses the
        // latest observation even when a provider returns to old content.
        if (previous == null) {
          batch.insert('discovery_evidence', {
            'candidate_identity': candidateIdentity,
            'source_id': item.id,
            'generation': generation,
            'payload': item.payload,
            'payload_hash': item.hash,
            'song_id': sessionSongId,
            'updated_at': updatedAt,
            'observed_generation': generation,
            'observed_order': observedOrder,
          });
          linkedNewEvidence |= sessionSongId != null;
          continue;
        }
        // A session may claim unattached evidence, but must leave another
        // song's history and hash intact.
        if ((sessionSongId != null &&
                previous.songId != null &&
                previous.songId != sessionSongId) ||
            (previous.generation ?? generation) > generation ||
            (previous.generation == generation &&
                (previous.order == null || previous.order! >= observedOrder))) {
          continue;
        }
        final linked = previous.songId == null && sessionSongId != null;
        linkedNewEvidence |= linked;
        batch.rawUpdate(
          'UPDATE discovery_evidence SET observed_generation = ?, observed_order = ?, '
          'song_id = COALESCE(song_id, ?) WHERE candidate_identity = ? AND source_id = ? '
          'AND payload_hash = ?',
          [
            generation,
            observedOrder,
            sessionSongId,
            candidateIdentity,
            item.id,
            item.hash,
          ],
        );
      }
      await batch.commit(noResult: true);
      return linkedNewEvidence
          ? _refreshEvidenceHash(txn, sessionSongId!)
          : sessions.single['content_hash'] as String?;
    });
  }

  Future<void> sealDiscoverySession({
    required String candidateIdentity,
    required int generation,
  }) => database
      .update(
        'discovery_sessions',
        {'sealed': 1},
        where: 'candidate_identity = ? AND generation = ?',
        whereArgs: [candidateIdentity, generation],
      )
      .then((_) {});

  Future<String> _computeEvidenceHash(
    DatabaseExecutor txn,
    String songId,
  ) async {
    final evidence = await txn.query(
      'discovery_evidence',
      columns: const ['candidate_identity', 'source_id', 'payload_hash'],
      where: 'song_id = ?',
      whereArgs: [songId],
      orderBy: 'candidate_identity,source_id,payload_hash',
    );
    final versions = await txn.rawQuery(
      'SELECT content_hash AS hash, 0 AS kind FROM song_versions WHERE song_id = ? '
      'UNION ALL SELECT payload_hash AS hash, 1 AS kind FROM song_imported_history WHERE song_id = ? '
      'ORDER BY kind, hash',
      [songId, songId],
    );
    if (evidence.isEmpty && versions.isEmpty) return '';
    return _hashEvidenceIndex(evidence, versions);
  }

  Future<String?> _refreshEvidenceHash(
    DatabaseExecutor txn,
    String songId, {
    bool queue = true,
  }) async {
    final rows = await txn.query(
      'songs',
      columns: const [
        'document_hash',
        'evidence_hash',
        'content_hash',
        'revision',
      ],
      where: 'id = ?',
      whereArgs: [songId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    final evidenceHash = await _computeEvidenceHash(txn, songId);
    if (row['evidence_hash'] == evidenceHash) {
      return row['content_hash'] as String;
    }
    final baseHash = row['document_hash'] as String;
    final contentHash = _aggregateHash(baseHash, evidenceHash);
    await txn.update(
      'songs',
      {'evidence_hash': evidenceHash, 'content_hash': contentHash},
      where: 'id = ?',
      whereArgs: [songId],
    );
    if (queue) {
      await _queue(txn, songId, 'song', 'save', row['revision'] as int);
    }
    return contentHash;
  }

  /// Cascading song deletes and "which setlists use this song" look entries up
  /// by song_id.
  static Future<void> _createEntrySongIndex(Database db) async {
    final tables = await db.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'setlist_entries'",
    );
    if (tables.isEmpty) return;
    await db.execute(
      'CREATE INDEX IF NOT EXISTS setlist_entries_song ON setlist_entries(song_id)',
    );
  }

  /// Adds the normalized search column and fills it for existing songs.
  static Future<void> _addSearchText(Database db) async {
    await db.execute('ALTER TABLE songs ADD COLUMN search_text TEXT');
    final codec = ChordProCodec();
    final rows = await db.query(
      'songs',
      columns: ['id', 'title', 'artist', 'album'],
    );
    for (final row in rows) {
      String? lyrics;
      try {
        final document = await _readDocument(db, row['id'] as String);
        lyrics = plainLyrics(codec.decode(document).body);
      } on Object {
        lyrics = null;
      }
      await db.update(
        'songs',
        {
          'search_text': searchText(
            row['title'] as String,
            row['artist'] as String,
            row['album'] as String?,
            lyrics ?? '',
          ),
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  /// Case-folded text a search query is matched against. SQLite's LIKE and
  /// NOCASE only fold ASCII on many builds, so folding is done here with full
  /// Unicode lower-casing; chords and directives are excluded via [lyrics].
  static String searchText(
    String title,
    String artist,
    String? album,
    String lyrics,
  ) => [title, artist, album ?? '', lyrics].join('\n').toLowerCase();

  static Future<void> _createSyncItems(Database db) => db.execute(
    'CREATE TABLE IF NOT EXISTS sync_items (account TEXT NOT NULL, kind TEXT NOT NULL, item_id TEXT NOT NULL, cloud_hash TEXT NOT NULL, local_hash TEXT NOT NULL, PRIMARY KEY(account, kind, item_id))',
  );

  static String _likePattern(String query) =>
      '%${query.trim().toLowerCase().replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%';

  Future<List<SongDocument>> listSongs({
    String query = '',
    bool favoritesOnly = false,
    int? limit,
    int offset = 0,
  }) async {
    final clauses = <String>[], args = <Object?>[];
    if (favoritesOnly) clauses.add('favorite = 1');
    if (query.trim().isNotEmpty) {
      clauses.add('search_text LIKE ? ESCAPE \'\\\'');
      args.add(_likePattern(query));
    }
    return database.transaction((txn) async {
      final rows = await txn.query(
        'songs',
        columns: _songReadColumns,
        where: clauses.isEmpty ? null : clauses.join(' AND '),
        whereArgs: args,
        orderBy: 'updated_at DESC, id',
        // An offset without a limit still has to skip rows (-1 = no limit).
        limit: limit ?? (offset > 0 ? -1 : null),
        offset: limit == null && offset <= 0 ? null : offset,
      );
      final songs = <SongDocument>[];
      for (final row in rows) {
        songs.add(await _hydrateSongEvidence(txn, await _readSong(txn, row)));
      }
      return songs;
    });
  }

  /// Reads all library documents and song content hashes from one SQLite
  /// snapshot. Hashes stay paired with the exact song payloads returned here,
  /// including opaque sidecars that require chunked reads.
  Future<
    ({
      List<SongDocument> songs,
      List<SetlistDocument> setlists,
      Map<String, String> songHashes,
    })
  >
  librarySnapshot() => database.transaction((txn) async {
    final songRows = await txn.query(
      'songs',
      columns: _songSnapshotColumns,
      orderBy: 'updated_at DESC, id',
    );
    final setlistRows = await txn.query(
      'setlists',
      orderBy: 'updated_at DESC,id',
    );
    return (
      songs: [for (final row in songRows) await _readSong(txn, row)],
      setlists: [for (final row in setlistRows) await _setlist(txn, row)],
      songHashes: {
        for (final row in songRows)
          row['id'] as String:
              row['document_hash'] as String? ?? row['content_hash'] as String,
      },
    );
  });

  /// Reads the complete library and app preferences from one SQLite snapshot.
  Future<
    ({
      List<SongDocument> songs,
      List<SetlistDocument> setlists,
      JsonMap appSettings,
      String libraryFingerprint,
    })
  >
  backupSnapshot() => database.transaction((txn) async {
    final songRows = await txn.query(
      'songs',
      columns: _songSnapshotColumns,
      orderBy: 'updated_at DESC,id',
    );
    final setlistRows = await txn.query(
      'setlists',
      orderBy: 'updated_at DESC,id',
    );
    final settingRows = await txn.query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: const ['app'],
      limit: 1,
    );
    return (
      songs: [
        for (final row in songRows)
          await _hydrateSongEvidence(txn, await _readSong(txn, row)),
      ],
      setlists: [for (final row in setlistRows) await _setlist(txn, row)],
      appSettings: settingRows.isEmpty
          ? <String, dynamic>{}
          : jsonMap(jsonDecode(settingRows.single['value'] as String)),
      libraryFingerprint: await _libraryFingerprint(txn),
    );
  });

  Future<String> _libraryFingerprint(DatabaseExecutor txn) async {
    final songRows = await txn.query(
      'songs',
      columns: const ['id', 'content_hash'],
      orderBy: 'id',
    );
    final setlistRows = await txn.query('setlists', orderBy: 'id');
    final setlists = [
      for (final row in setlistRows) (await _setlist(txn, row)).toJson(),
    ];
    final appSettings = await txn.query(
      'settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: const ['app'],
      limit: 1,
    );
    return sha256
        .convert(
          utf8.encode(
            jsonEncode({
              'songs': [
                for (final row in songRows) [row['id'], row['content_hash']],
              ],
              'setlists': setlists,
              // The preview token also guards the settings row that restore
              // may rewrite, while keeping its contents out of the token.
              'appSettingsHash': appSettings.isEmpty
                  ? null
                  : sha256
                        .convert(
                          utf8.encode(appSettings.single['value'] as String),
                        )
                        .toString(),
            }),
          ),
        )
        .toString();
  }

  static Future<String> _readColumn(
    DatabaseExecutor executor,
    String id,
    String column,
  ) => _readTableText(
    executor,
    'songs',
    column,
    'id = ?',
    [id],
    missing: 'Song document disappeared',
    unreadable: 'Could not read song document chunk',
  );

  static Future<String> _readTableText(
    DatabaseExecutor executor,
    String table,
    String column,
    String where,
    List<Object?> args, {
    String missing = 'Evidence row disappeared',
    String unreadable = 'Could not read evidence chunk',
  }) async {
    // Callers use fixed internal identifiers; values remain bound parameters.
    final lengthRows = await executor.rawQuery(
      'SELECT length(CAST($column AS BLOB)) AS byte_length FROM $table WHERE $where',
      args,
    );
    if (lengthRows.isEmpty) throw StateError(missing);
    final byteLength = lengthRows.single['byte_length'] as int;
    final bytes = BytesBuilder(copy: false);
    for (var start = 1; start <= byteLength; start += _documentReadChunkSize) {
      final rows = await executor.rawQuery(
        'SELECT substr(CAST($column AS BLOB), ?, ?) AS chunk FROM $table WHERE $where',
        [start, _documentReadChunkSize, ...args],
      );
      if (rows.isEmpty || rows.single['chunk'] is! Uint8List) {
        throw StateError(unreadable);
      }
      bytes.add(rows.single['chunk'] as Uint8List);
    }
    return utf8.decode(bytes.takeBytes());
  }

  static Future<String> _readDocument(DatabaseExecutor executor, String id) =>
      _readColumn(executor, id, 'document');

  Future<SongDocument> _readSong(
    DatabaseExecutor executor,
    Map<String, Object?> row,
  ) async {
    final storedDocument = row['document'];
    final document = storedDocument is String
        ? storedDocument
        : await _readDocument(executor, row['id'] as String);
    final fullDocument = row['full_document'];
    SongDocument song;
    if (fullDocument != null || row['full_document_hash'] != null) {
      final fullDocumentHash = row['full_document_hash'];
      if (fullDocumentHash is! String) {
        throw const FormatException('Invalid opaque song sidecar');
      }
      final json = fullDocument is String
          ? fullDocument
          : await _readColumn(executor, row['id'] as String, 'full_document');
      final actualHash = sha256.convert(utf8.encode(json)).toString();
      if (actualHash != fullDocumentHash ||
          row['content_hash'] != _localSongHash(document, actualHash)) {
        throw const FormatException('Invalid opaque song sidecar');
      }
      song = SongDocument.fromJson(jsonMap(jsonDecode(json)));
      if (song.id != row['id'] || song.extensionError == null) {
        throw const FormatException('Invalid opaque song sidecar');
      }
    } else {
      song = document.length > _documentReadChunkSize
          ? await _decodeLargeSong(document)
          : _codec.decode(document);
    }
    return song.copyWith(
      id: row['id'] as String,
      favorite: row['favorite'] == 1,
      revision: row['revision'] as int,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<SongDocument?> getPlayableSong(String id) async {
    return database.transaction((txn) async {
      final rows = await txn.query(
        'songs',
        columns: _songReadColumns,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return rows.isEmpty ? null : _readSong(txn, rows.single);
    });
  }

  /// Returns the compact current chart plus version/source evidence retained
  /// outside `songs.document`. Compare, backup and sync consumers opt in to
  /// this hydrated representation; player/library reads stay small.
  Future<SongDocument?> getSongWithEvidence(String id) => _readSavedSong(id);

  Future<SongDocument?> getSongForComparison(String id) =>
      _readSavedSong(id, latestSourcesOnly: true);

  Future<SongDocument?> _readSavedSong(
    String id, {
    bool latestSourcesOnly = false,
  }) => database.transaction((txn) async {
    final rows = await txn.query(
      'songs',
      columns: _songReadColumns,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final song = await _readSong(txn, rows.single);
    return _hydrateSongEvidence(
      txn,
      song,
      latestSourcesOnly:
          latestSourcesOnly &&
          song.selectedRecording?.providerId != 'wikisource' &&
          song.extra.containsKey('libraryEvidenceIdentity'),
    );
  });

  /// Existing repository callers expect a complete editable model. New hot UI
  /// paths use [getPlayableSong] explicitly.
  Future<SongDocument?> getSong(String id) => getSongWithEvidence(id);

  Future<SongDocument> _hydrateSongEvidence(
    DatabaseExecutor txn,
    SongDocument current, {
    bool latestSourcesOnly = false,
  }) async {
    final versions = <_ArchivedSongPayload>[];
    final archived = latestSourcesOnly
        ? const <Map<String, Object?>>[]
        : await txn.query(
            'song_versions',
            columns: const [
              'content_hash',
              'document_hash',
              'favorite',
              'revision',
              'created_at',
              'updated_at',
              'full_document_hash',
              _boundedDocumentColumn,
              _boundedFullDocumentColumn,
            ],
            where: 'song_id = ?',
            whereArgs: [current.id],
            orderBy: 'archived_at, content_hash',
          );
    for (final row in archived) {
      final contentHash = row['content_hash'] as String;
      final stored = row['document'];
      final document = stored is String
          ? stored
          : await _readTableText(
              txn,
              'song_versions',
              'document',
              'song_id = ? AND content_hash = ?',
              [current.id, contentHash],
            );
      final fullStored = row['full_document'];
      final fullHash = row['full_document_hash'] as String?;
      final full = fullStored is String
          ? fullStored
          : fullHash == null
          ? null
          : await _readTableText(
              txn,
              'song_versions',
              'full_document',
              'song_id = ? AND content_hash = ?',
              [current.id, contentHash],
            );
      versions.add((
        hash: contentHash,
        documentHash: row['document_hash'] as String,
        document: document,
        fullDocument: full,
        fullHash: fullHash,
      ));
    }
    final sources = <_StoredSourcePayload>[];
    final staged = await txn.query(
      'discovery_evidence',
      columns: const [
        'candidate_identity',
        'source_id',
        'payload_hash',
        'generation',
        'updated_at',
        'CASE WHEN length(CAST(payload AS BLOB)) <= $_documentReadChunkSize THEN payload ELSE NULL END AS payload',
      ],
      where: latestSourcesOnly
          ? 'rowid IN (SELECT (SELECT latest.rowid FROM discovery_evidence AS latest '
                'WHERE latest.song_id = ? AND latest.source_id = source_ids.source_id '
                'ORDER BY COALESCE(latest.observed_generation,latest.generation) DESC, '
                'COALESCE(latest.observed_order,0) DESC, latest.updated_at DESC, latest.rowid DESC LIMIT 1) '
                'FROM (SELECT DISTINCT source_id FROM discovery_evidence WHERE song_id = ?) AS source_ids)'
          : 'song_id = ?',
      whereArgs: [current.id, if (latestSourcesOnly) current.id],
      orderBy: 'generation,updated_at,rowid',
    );
    final imported = await txn.query(
      'song_imported_history',
      columns: const [
        'payload_hash',
        'CASE WHEN length(CAST(payload AS BLOB)) <= $_documentReadChunkSize THEN payload ELSE NULL END AS payload',
      ],
      where: 'song_id = ?',
      whereArgs: [current.id],
      limit: 1,
    );
    final importedHistory = imported.isEmpty
        ? null
        : (
            payload:
                imported.single['payload'] as String? ??
                await _readTableText(
                  txn,
                  'song_imported_history',
                  'payload',
                  'song_id = ?',
                  [current.id],
                ),
            hash: imported.single['payload_hash'] as String,
          );
    final activeDiagnostics = current.extra[_mergeDiagnosticsKey];
    final diagnostics = activeDiagnostics == null && archived.isEmpty
        ? const <Map<String, Object?>>[]
        : await txn.rawQuery(
            'SELECT ref.payload_hash, '
            'CASE WHEN length(CAST(blob.payload AS BLOB)) <= $_documentReadChunkSize '
            'THEN blob.payload ELSE NULL END AS payload '
            'FROM song_merge_diagnostics AS ref '
            'JOIN merge_diagnostic_payloads AS blob ON blob.payload_hash = ref.payload_hash '
            'WHERE ref.song_id = ?${archived.isEmpty ? ' AND ref.payload_hash = ?' : ''}',
            [current.id, if (archived.isEmpty) activeDiagnostics],
          );
    if (archived.isEmpty &&
        staged.isEmpty &&
        importedHistory == null &&
        activeDiagnostics == null) {
      return current;
    }
    final diagnosticPayloads = <String, String>{};
    for (final row in diagnostics) {
      final hash = row['payload_hash'] as String;
      diagnosticPayloads[hash] =
          row['payload'] as String? ??
          await _readTableText(
            txn,
            'merge_diagnostic_payloads',
            'payload',
            'payload_hash = ?',
            [hash],
          );
    }
    for (final row in staged) {
      final identity = row['candidate_identity'] as String;
      final sourceId = row['source_id'] as String;
      final hash = row['payload_hash'] as String;
      final payload =
          row['payload'] as String? ??
          await _readTableText(
            txn,
            'discovery_evidence',
            'payload',
            'candidate_identity = ? AND source_id = ? AND payload_hash = ?',
            [identity, sourceId, hash],
          );
      sources.add((
        payload: payload,
        hash: hash,
        generation: row['generation'] as int,
      ));
    }
    return _restoreStoredEvidence(
      current,
      versions,
      sources,
      latestSourcesOnly: latestSourcesOnly,
      importedHistory: importedHistory,
      diagnosticPayloads: diagnosticPayloads,
    );
  }

  Future<({SongDocument song, String document, String hash, bool linked})?>
  _validatedSongState(
    DatabaseExecutor txn,
    String id, {
    required bool requireSyncRepresentation,
    bool hydrateEvidence = true,
  }) async {
    final rows = await txn.query(
      'songs',
      columns: _songStateColumns,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final row = rows.single;
      final rawDocument = row['document'];
      final document = rawDocument is String
          ? rawDocument
          : await _readDocument(txn, id);
      final fullDocumentHash = row['full_document_hash'] as String?;
      final documentHash = _localSongHash(document, fullDocumentHash);
      final evidenceHash = row['evidence_hash'] as String;
      final contentHash = row['content_hash'] as String;
      final expectedHash = evidenceHash.isEmpty
          ? documentHash
          : _localSongHash(
              document,
              fullDocumentHash,
              evidenceHash: evidenceHash,
              documentHash: documentHash,
            );
      if ((row['document_hash'] ?? contentHash) != documentHash ||
          contentHash != expectedHash) {
        throw const FormatException('invalid_local_data');
      }
      SongDocument song;
      final hasSidecar =
          row['full_document'] != null || row['full_document_hash'] != null;

      if (hasSidecar) {
        song = await _readSong(txn, {
          ...row,
          'document': document,
          'content_hash': documentHash,
        });
        final storedSidecar = row['full_document'];
        final sidecar = storedSidecar is String
            ? storedSidecar
            : await _readColumn(txn, id, 'full_document');
        // Sidecars are emitted from SongDocument.toJson(). Requiring its
        // canonical shape catches fields from an unsupported schema that
        // fromJson would otherwise discard. ChordPro must match this complete
        // local representation.
        if (jsonEncode(song.toJson()) != sidecar ||
            _codec.encode(song) != document) {
          throw const FormatException('invalid_local_data');
        }
      } else {
        song = document.length > _documentReadChunkSize
            ? await _decodeLargeSong(document)
            : _codec.decode(document);
      }
      if (song.id != id ||
          (requireSyncRepresentation && song.extensionError != null)) {
        throw const FormatException('invalid_local_data');
      }
      final linked =
          evidenceHash.isNotEmpty ||
          song.extra.containsKey(_mergeDiagnosticsKey);
      if (requireSyncRepresentation && linked) {
        if (evidenceHash.isNotEmpty &&
            await _computeEvidenceHash(txn, id) != evidenceHash) {
          throw const FormatException('invalid_local_data');
        }
        // A validate-only caller checks the evidence index above and has no
        // use for the evidence itself.
        if (hydrateEvidence) song = await _hydrateSongEvidence(txn, song);
      }
      return (
        song: song,
        document: document,
        hash: contentHash,
        linked: linked,
      );
    } on Object {
      throw const FormatException('invalid_local_data');
    }
  }

  /// Validates every complete local song before sync plans remote or local
  /// mutations. Unsupported opaque extensions remain usable in backups, but
  /// cannot be represented by the strict raw ChordPro sync format.
  ///
  /// [validated] is an optional memo of one sync run (song id -> content hash
  /// already validated). A song whose stored content hash still equals its
  /// entry is not read again; songs validated here are added to it.
  Future<void> validateSyncSongData({Map<String, String>? validated}) async {
    await database.transaction((txn) async {
      final rows = await txn.query(
        'songs',
        columns: const ['id', 'content_hash'],
      );
      final present = <String>{};
      for (final row in rows) {
        final id = row['id'] as String;
        present.add(id);
        final known = validated?[id];
        if (known != null && known == row['content_hash']) continue;
        final state = await _validatedSongState(
          txn,
          id,
          requireSyncRepresentation: true,
          hydrateEvidence: false,
        );
        if (state != null) validated?[id] = state.hash;
      }
      validated?.removeWhere((id, _) => !present.contains(id));
    });
  }

  Future<void> saveSong(SongDocument song) async {
    final document = _codec.encode(song);
    await database.transaction((txn) async {
      await _writeSong(txn, song, document);
      await _queue(txn, song.id, 'song', 'save', song.revision);
    });
  }

  /// Atomic compare-and-set save. Inside one transaction the stored hash is
  /// compared with [expectedHash]; the song is written only when the stored
  /// song is absent, [expectedHash] is null or the hashes match. Returns false
  /// (and writes nothing) when the stored song differs, so the caller can keep
  /// the edit as a conflict copy without a check-then-write race.
  ///
  /// A null [expectedHash] normally means "write unconditionally". With
  /// [mustNotExist] it means the song must still be absent.
  /// [mustExist] refuses insertion if a song was deleted before this transaction.
  Future<bool> saveSongIfUnchanged(
    SongDocument song,
    String? expectedHash, {
    bool mustNotExist = false,
    bool mustExist = false,
  }) async {
    final document = _codec.encode(song);
    return database.transaction((txn) async {
      if (expectedHash != null || mustNotExist || mustExist) {
        final rows = await txn.query(
          'songs',
          columns: ['content_hash', 'document_hash'],
          where: 'id = ?',
          whereArgs: [song.id],
          limit: 1,
        );
        if (mustExist && rows.isEmpty) return false;
        if (rows.isNotEmpty &&
            (expectedHash == null
                ? mustNotExist
                : (rows.single['document_hash'] ??
                          rows.single['content_hash']) !=
                      expectedHash)) {
          return false;
        }
      }
      await _writeSong(txn, song, document);
      await _queue(txn, song.id, 'song', 'save', song.revision);
      return true;
    });
  }

  /// Updates the playable document without sealing its discovery session.
  /// Playback settings do not change which source evidence belongs to a chart.
  Future<({String hash, bool favorite})?> savePlaybackPreferencesIfUnchanged(
    SongDocument song,
    String expectedHash,
  ) async {
    final row = await _prepareSongRow(song);
    return database.transaction((txn) async {
      final current = await txn.query(
        'songs',
        columns: const ['document_hash', 'content_hash', 'favorite'],
        where: 'id = ?',
        whereArgs: [song.id],
        limit: 1,
      );
      if (current.isEmpty ||
          (current.single['document_hash'] ?? current.single['content_hash']) !=
              expectedHash) {
        return null;
      }
      row['favorite'] = current.single['favorite'];
      await _upsertSongRow(txn, row);
      await _queue(txn, song.id, 'song', 'save', song.revision);
      return (
        hash: row['document_hash'] as String,
        favorite: row['favorite'] == 1,
      );
    });
  }

  Future<SongDocument> _withoutForeignDiagnosticsPointer(
    DatabaseExecutor txn,
    SongDocument song,
  ) async {
    final hash = song.extra[_mergeDiagnosticsKey];
    if (hash == null) return song;
    final rows = await txn.query(
      'song_merge_diagnostics',
      columns: const ['payload_hash'],
      where: 'song_id = ? AND payload_hash = ?',
      whereArgs: [song.id, if (hash is String) hash else ''],
      limit: 1,
    );
    if (rows.isNotEmpty) return song;
    return song.copyWith(
      extra: {...song.extra}..remove(_mergeDiagnosticsKey),
      revision: song.revision,
      updatedAt: song.updatedAt,
    );
  }

  Future<void> _writeSong(
    DatabaseExecutor txn,
    SongDocument song,
    String document,
  ) async {
    final original = song;
    if (song.extra.containsKey(_mergeDiagnosticsKey)) {
      song = await _withoutForeignDiagnosticsPointer(txn, song);
    }
    final hasImportedHistory =
        song.sources.isNotEmpty ||
        song.extra.containsKey('previousSavedVersions');
    final imported =
        song.extensionError == null &&
            song.extra['libraryEvidenceIdentity'] is String &&
            (hasImportedHistory ||
                _mergeDiagnosticFields.any(song.extra.containsKey))
        ? await _prepareImportedHistory(song)
        : null;
    final row =
        imported?.row ??
        (identical(original, song)
            ? _songRow(song, document)
            : await _prepareSongRow(song));
    final previous = await txn.query(
      'songs',
      columns: const ['evidence_hash'],
      where: 'id = ?',
      whereArgs: [song.id],
      limit: 1,
    );
    final evidenceHash = previous.isEmpty
        ? ''
        : previous.single['evidence_hash'] as String? ?? '';
    row['evidence_hash'] = evidenceHash;
    final baseHash = row['document_hash'] as String;
    row['content_hash'] = _aggregateHash(baseHash, evidenceHash);
    await _upsertSongRow(txn, row);
    await _writeMergeDiagnostics(txn, song.id, imported?.diagnostics);
    if (imported != null && hasImportedHistory) {
      await txn.insert('song_imported_history', {
        'song_id': song.id,
        'payload': imported.payload,
        'payload_hash': imported.hash,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await _refreshEvidenceHash(txn, song.id, queue: false);
    }

    // A normal edit, sync apply, or delete must seal any in-flight discovery
    // link. Late provider callbacks may remain staged, but cannot mutate a
    // song after the user has changed its active ChordPro.
    await txn.update(
      'discovery_sessions',
      {'song_id': null, 'sealed': 1},
      where: 'song_id = ?',
      whereArgs: [song.id],
    );
  }

  Future<void> _upsertSongRow(
    DatabaseExecutor txn,
    Map<String, Object?> values,
  ) async {
    final existing = await txn.query(
      'songs',
      columns: const ['evidence_hash'],
      where: 'id = ?',
      whereArgs: [values['id']],
      limit: 1,
    );
    final previousEvidenceHash = existing.isEmpty
        ? ''
        : existing.single['evidence_hash'] as String? ?? '';
    if (previousEvidenceHash.isNotEmpty &&
        (values['evidence_hash'] as String? ?? '').isEmpty) {
      final baseHash = values['document_hash'] as String?;
      if (baseHash != null) {
        values['evidence_hash'] = previousEvidenceHash;
        values['content_hash'] = _aggregateHash(baseHash, previousEvidenceHash);
      }
    }
    // UPDATE then INSERT avoids REPLACE deleting a song's setlist references.
    final updated = await txn.update(
      'songs',
      values,
      where: 'id = ?',
      whereArgs: [values['id']],
    );
    if (updated == 0) await txn.insert('songs', values);
  }

  /// An explicit comparison Save replaces the preferred version in place.
  /// Keep this separate from file imports and stale-editor conflict handling.
  /// Matching and writing share one transaction, including concurrent saves.
  /// Persists only the selected playable chart. Discovery provenance and
  /// previous documents stay in linked sidecar tables, so a Save does not
  /// rebuild one multi-megabyte ChordPro extension on the foreground path.
  /// [onChartPrepared] may start reader work, but the chart is uncommitted
  /// until this future returns. A transaction retry can supply a new chart.
  Future<({SongDocument song, String contentHash, bool changed})>
  saveChosenSongFast(
    SongDocument song, {
    required String candidateIdentity,
    required int discoveryGeneration,
    required String? existingSongId,
    required String? expectedExistingHash,
    SongDocument? existingSnapshot,
    String? stagedDiagnosticsHash,
    Future<void>? evidenceReady,
    void Function(SongDocument)? onChartPrepared,
  }) async {
    if (song.selectedRecording == null) {
      throw ArgumentError('Missing selected song reference');
    }
    if ((existingSongId == null) != (existingSnapshot == null)) {
      throw ArgumentError(
        'Existing song snapshot and id must be supplied together',
      );
    }
    if (existingSongId != null &&
        (existingSnapshot!.id != existingSongId ||
            expectedExistingHash == null)) {
      throw ArgumentError('Existing song identity/hash mismatch');
    }
    if (existingSnapshot?.extensionError != null) {
      throw const FormatException('invalid_local_data');
    }
    final now = DateTime.now().toUtc();
    final prior = existingSnapshot;
    SongDocument? playableSnapshot(SongDocument? document) =>
        document == null || document.sources.isEmpty
        ? document
        : document.copyWith(
            sources: const [],
            revision: document.revision,
            updatedAt: document.updatedAt,
          );
    final prepared = await _prepareChosenSongRow(
      song: playableSnapshot(song)!,
      prior: playableSnapshot(prior),
      priorHasSources: prior?.sources.isNotEmpty ?? false,
      now: now,
      candidateIdentity: candidateIdentity,
      stagedDiagnosticsHash: stagedDiagnosticsHash,
    );
    final preparedRow = prepared.row;
    final saved = prepared.song;
    onChartPrepared?.call(preparedRow == null ? prior! : saved);
    // Prepare the chart while discovery finishes staging the accepted
    // evidence. The write must link that evidence in the same transaction.
    await evidenceReady;
    return database
        .transaction((txn) async {
          Map<String, Object?>? current;
          if (existingSongId != null) {
            final rows = await txn.query(
              'songs',
              columns: const [
                'id',
                'content_hash',
                'document_hash',
                'favorite',
                'revision',
                'created_at',
                'updated_at',
              ],
              where: 'id = ?',
              whereArgs: [existingSongId],
              limit: 1,
            );
            if (rows.isEmpty ||
                (rows.single['document_hash'] ?? rows.single['content_hash']) !=
                    expectedExistingHash) {
              throw StateError('save_conflict');
            }
            current = rows.single;
            if (preparedRow != null) {
              await txn.rawInsert(
                'INSERT OR IGNORE INTO song_versions(song_id,content_hash,document,document_hash,full_document,full_document_hash,favorite,revision,created_at,updated_at,archived_at) '
                'SELECT id,COALESCE(document_hash,content_hash),document,COALESCE(document_hash,content_hash),full_document,full_document_hash,favorite,revision,created_at,updated_at,? FROM songs WHERE id = ?',
                [now.toIso8601String(), existingSongId],
              );
            }
          } else {
            final collision = await txn.query(
              'songs',
              columns: const ['id'],
              where: 'id = ?',
              whereArgs: [saved.id],
              limit: 1,
            );
            if (collision.isNotEmpty) throw StateError('save_conflict');
          }
          if (preparedRow != null) {
            preparedRow['evidence_hash'] = '';
            preparedRow['content_hash'] = preparedRow['document_hash'];
            preparedRow['favorite'] =
                current?['favorite'] ?? preparedRow['favorite'];
            // Insert the song before attaching evidence with a foreign key to it.
            await _upsertSongRow(txn, preparedRow);
            if (prepared.useStagedDiagnostics) {
              await _linkStagedMergeDiagnostics(
                txn,
                songId: saved.id,
                candidateIdentity: candidateIdentity,
                generation: discoveryGeneration,
                hash: stagedDiagnosticsHash!,
              );
            } else {
              await _writeMergeDiagnostics(txn, saved.id, prepared.diagnostics);
            }
          }
          await txn.update(
            'discovery_sessions',
            {'song_id': saved.id},
            where: 'candidate_identity = ? AND generation = ?',
            whereArgs: [candidateIdentity, discoveryGeneration],
          );
          final linked = await txn.update(
            'discovery_evidence',
            {'song_id': saved.id},
            where:
                'candidate_identity = ? AND generation <= ? AND song_id IS NULL',
            whereArgs: [candidateIdentity, discoveryGeneration],
          );
          if (preparedRow == null) {
            if (linked > 0) await _refreshEvidenceHash(txn, saved.id);
            return (
              song: prior!,
              contentHash: expectedExistingHash!,
              changed: linked > 0,
            );
          }
          final evidenceHash = await _computeEvidenceHash(txn, saved.id);
          final baseHash = preparedRow['document_hash'] as String;
          final aggregateHash = _aggregateHash(baseHash, evidenceHash);
          await txn.update(
            'songs',
            {'evidence_hash': evidenceHash, 'content_hash': aggregateHash},
            where: 'id = ?',
            whereArgs: [saved.id],
          );
          await _queue(txn, saved.id, 'song', 'save', saved.revision);
          return (song: prepared.song, contentHash: baseHash, changed: true);
        })
        .onError<_MissingStagedMergeDiagnostics>((_, _) {
          // Expired staging must not strand an open comparison. The failed
          // transaction has rolled back, so recheck the same expected chart
          // before storing diagnostics from the captured merge.
          return saveChosenSongFast(
            song,
            candidateIdentity: candidateIdentity,
            discoveryGeneration: discoveryGeneration,
            existingSongId: existingSongId,
            expectedExistingHash: expectedExistingHash,
            existingSnapshot: existingSnapshot,
            onChartPrepared: onChartPrepared,
          );
        });
  }

  Future<SongDocument> saveChosenSong(SongDocument song) async {
    song = _sanitizeImportedDurations(song);
    final selected = song.selectedRecording;
    if (selected == null) {
      throw ArgumentError('Missing selected song reference');
    }
    return database.transaction((txn) async {
      final rows = await txn.query(
        'songs',
        columns: _songReadColumns,
        orderBy: 'created_at, id',
      );
      SongDocument? existing;
      var bestPriority = 0;
      for (final row in rows) {
        // The persisted reference can differ from locally edited display
        // metadata. Resolve it from the same snapshot rather than trusting an
        // in-memory ID or filtering only on the visible title and artist.
        final stored = await _readSong(txn, row);
        final priority = librarySongMatchPriority(stored, selected);
        // Exact reference first; ties keep the earliest-created library ID.
        // Pre-existing duplicates are not deleted or silently consolidated.
        if (priority > bestPriority) {
          existing = stored;
          bestPriority = priority;
        }
      }
      if (existing == null) {
        return (await _importSong(txn, song, prepareInBackground: true)).song;
      }
      if (existing.extensionError != null) {
        throw const FormatException('invalid_local_data');
      }
      final (replacement, row) = await _prepareChosenReplacement(
        existing,
        song,
      );
      await _upsertSongRow(txn, row);
      await _queue(txn, replacement.id, 'song', 'save', replacement.revision);
      return replacement;
    });
  }

  Future<SongDocument> saveImportedSong(
    SongDocument song, {
    String? existingId,
  }) async {
    song = _sanitizeImportedDurations(song);
    return database.transaction((txn) async {
      final source = song.extra['selectedSourceId'];
      if (source is String || existingId != null) {
        final rows = await txn.query(
          'songs',
          columns: _songReadColumns,
          where: existingId == null ? 'source_identity = ?' : 'id = ?',
          whereArgs: [existingId ?? source],
        );
        for (final row in rows) {
          final existing = await _readSong(txn, row);
          final prepared = await _prepareImportedMerge(
            existing,
            song,
            explicitMatch: existingId != null,
          );
          if (prepared == null) continue;
          final (merged, preparedRow) = prepared;
          await _upsertSongRow(txn, preparedRow);
          await _queue(txn, merged.id, 'song', 'save', merged.revision);
          return merged;
        }
      }
      return (await _importSong(txn, song)).song;
    });
  }

  /// Writes an imported song without clobbering a different local song that
  /// shares its id: identical content is a no-op, differing content is stored
  /// as a separate copy under a fresh id (the local song is untouched).
  Future<({SongDocument song, bool forked})> _importSong(
    DatabaseExecutor txn,
    SongDocument song, {
    bool prepareInBackground = false,
  }) async {
    if (song.extra.containsKey(_mergeDiagnosticsKey)) {
      song = await _withoutForeignDiagnosticsPointer(txn, song);
    }
    final rows = await txn.query(
      'songs',
      columns: ['document_hash', 'content_hash'],
      where: 'id = ?',
      whereArgs: [song.id],
      limit: 1,
    );
    var row = prepareInBackground ? await _prepareSongRow(song) : null;
    var document = row?['document'] as String? ?? _codec.encode(song);
    var forked = false;
    if (rows.isNotEmpty) {
      final hash = sha256.convert(utf8.encode(document)).toString();
      if ((rows.single['document_hash'] ?? rows.single['content_hash']) ==
          hash) {
        return (song: song, forked: false);
      }
      song = song.copyWith(
        id: newId(),
        revision: song.revision,
        updatedAt: song.updatedAt,
      );
      if (song.extra.containsKey(_mergeDiagnosticsKey)) {
        song = await _withoutForeignDiagnosticsPointer(txn, song);
      }
      row = prepareInBackground ? await _prepareSongRow(song) : null;
      document = row?['document'] as String? ?? _codec.encode(song);
      forked = true;
    }
    if (row == null) {
      await _writeSong(txn, song, document);
    } else {
      await _upsertSongRow(txn, row);
    }
    await _queue(txn, song.id, 'song', 'save', song.revision);
    return (song: song, forked: forked);
  }

  Future<void> deleteSong(String id) async {
    await database.transaction((txn) async {
      // Deleting a song cascades its setlist entries; the affected setlists
      // changed too, so they must be touched and synced.
      await _deleteSongTouchingSetlists(txn, id);
      await _queue(txn, id, 'song', 'delete', null);
    });
  }

  Future<void> _deleteSongTouchingSetlists(
    DatabaseExecutor txn,
    String id,
  ) async {
    final affected = await txn.rawQuery(
      'SELECT DISTINCT setlist_id FROM setlist_entries WHERE song_id = ?',
      [id],
    );
    await txn.delete('songs', where: 'id = ?', whereArgs: [id]);
    for (final row in affected) {
      final setlistId = row['setlist_id'] as String;
      await txn.update(
        'setlists',
        {'updated_at': DateTime.now().toUtc().toIso8601String()},
        where: 'id = ?',
        whereArgs: [setlistId],
      );
      await _queue(txn, setlistId, 'setlist', 'save', null);
    }
  }

  Future<List<SetlistDocument>> listSetlists({
    String query = '',
    bool favoritesOnly = false,
  }) async {
    final rows = await database.query(
      'setlists',
      where: favoritesOnly ? 'favorite = 1' : null,
      orderBy: 'updated_at DESC,id',
    );
    // Matched in Dart: SQLite LIKE only case-folds ASCII.
    final needle = query.trim().toLowerCase();
    final result = <SetlistDocument>[];
    for (final row in rows) {
      if (needle.isNotEmpty &&
          !(row['name'] as String).toLowerCase().contains(needle)) {
        continue;
      }
      result.add(await _setlist(database, row));
    }
    return result;
  }

  Future<SetlistDocument?> getSetlist(String id) async {
    final rows = await database.query(
      'setlists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _setlist(database, rows.single);
  }

  Future<SetlistDocument> _setlist(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final entries = await db.query(
      'setlist_entries',
      where: 'setlist_id = ?',
      whereArgs: [row['id']],
      orderBy: 'position',
    );
    return SetlistDocument(
      id: row['id'] as String,
      name: row['name'] as String,
      notes: row['notes'] as String,
      favorite: row['favorite'] == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      entries: entries
          .map(
            (e) => SetlistEntry(
              id: e['id'] as String,
              songId: e['song_id'] as String,
              overrides: jsonMap(jsonDecode(e['overrides'] as String)),
            ),
          )
          .toList(),
    );
  }

  Future<void> saveSetlist(SetlistDocument setlist) async {
    await database.transaction((txn) => _writeSetlist(txn, setlist));
  }

  /// Atomic compare-and-set counterpart of [saveSetlist]; see
  /// [saveSongIfUnchanged]. [expectedHash] is the hash of the setlist's JSON
  /// as returned by [getSetlistHash]. [mustExist] refuses to recreate a
  /// setlist deleted since the expected hash was captured.
  Future<bool> saveSetlistIfUnchanged(
    SetlistDocument setlist,
    String? expectedHash, {
    bool mustNotExist = false,
    bool mustExist = false,
  }) async =>
      await saveSetlistIfUnchangedWithHash(
        setlist,
        expectedHash,
        mustNotExist: mustNotExist,
        mustExist: mustExist,
      ) !=
      null;

  /// Atomic compare-and-set save that returns the hash of the exact persisted
  /// document, including any entry ids regenerated during the write. Returns
  /// null when the expected version does not match.
  Future<String?> saveSetlistIfUnchangedWithHash(
    SetlistDocument setlist,
    String? expectedHash, {
    bool mustNotExist = false,
    bool mustExist = false,
  }) => database.transaction((txn) async {
    if (expectedHash != null || mustNotExist || mustExist) {
      final rows = await txn.query(
        'setlists',
        where: 'id = ?',
        whereArgs: [setlist.id],
        limit: 1,
      );
      if (mustExist && rows.isEmpty) return null;
      if (rows.isNotEmpty &&
          (expectedHash == null
              ? mustNotExist
              : _setlistHashOf(await _setlist(txn, rows.single)) !=
                    expectedHash)) {
        return null;
      }
    }
    await _writeSetlist(txn, setlist);
    final rows = await txn.query(
      'setlists',
      where: 'id = ?',
      whereArgs: [setlist.id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _setlistHashOf(await _setlist(txn, rows.single));
  });

  /// Entry ids may be regenerated on write, so only name, notes, favorite and
  /// the ordered (song, overrides) pairs decide whether two setlists match.
  static bool _sameSetlistContent(SetlistDocument a, SetlistDocument b) =>
      a.name == b.name &&
      a.notes == b.notes &&
      a.favorite == b.favorite &&
      jsonEncode([
            for (final e in a.entries) [e.songId, e.overrides],
          ]) ==
          jsonEncode([
            for (final e in b.entries) [e.songId, e.overrides],
          ]);

  static String _setlistHashOf(SetlistDocument setlist) =>
      setlistContentHash(setlist);

  Future<void> _writeSetlist(
    DatabaseExecutor txn,
    SetlistDocument setlist, {
    bool queue = true,
  }) async {
    final values = {
      'id': setlist.id,
      'name': setlist.name,
      'notes': setlist.notes,
      'favorite': setlist.favorite ? 1 : 0,
      'created_at': setlist.createdAt.toUtc().toIso8601String(),
      'updated_at': setlist.updatedAt.toUtc().toIso8601String(),
    };
    final updated = await txn.update(
      'setlists',
      values,
      where: 'id = ?',
      whereArgs: [setlist.id],
    );
    if (updated == 0) await txn.insert('setlists', values);
    await txn.delete(
      'setlist_entries',
      where: 'setlist_id = ?',
      whereArgs: [setlist.id],
    );
    final usedIds = <String>{};
    for (var i = 0; i < setlist.entries.length; i++) {
      final entry = setlist.entries[i];
      // setlist_entries.id is a global primary key: an id already used by
      // another setlist (a duplicated or imported setlist) or repeated within
      // this one is regenerated instead of aborting the whole write.
      var entryId = entry.id;
      while (usedIds.contains(entryId) ||
          (await txn.query(
            'setlist_entries',
            columns: ['id'],
            where: 'id = ?',
            whereArgs: [entryId],
            limit: 1,
          )).isNotEmpty) {
        entryId = newId();
      }
      usedIds.add(entryId);
      await txn.insert('setlist_entries', {
        'id': entryId,
        'setlist_id': setlist.id,
        'song_id': entry.songId,
        'position': i,
        'overrides': jsonEncode(entry.overrides),
      });
    }
    if (queue) await _queue(txn, setlist.id, 'setlist', 'save', null);
  }

  Future<void> importCollection(
    List<SongDocument> songs,
    List<SetlistDocument> setlists, {
    JsonMap? appSettings,
    String? expectedLibraryFingerprint,
  }) async {
    if (songs.map((song) => song.id).toSet().length != songs.length ||
        setlists.map((setlist) => setlist.id).toSet().length !=
            setlists.length) {
      throw const FormatException(
        'Imported collection contains duplicate document IDs.',
      );
    }
    await database.transaction((txn) async {
      if (expectedLibraryFingerprint != null &&
          await _libraryFingerprint(txn) != expectedLibraryFingerprint) {
        throw const FormatException('stale_backup_preview');
      }
      final remapped = <String, String>{};
      for (final song in songs) {
        final result = await _importSong(txn, song);
        if (result.forked) remapped[song.id] = result.song.id;
      }
      for (final setlist in setlists) {
        // Entries follow the imported copy of a song that had to be forked;
        // entries whose song is in neither the file nor the library are
        // dropped rather than failing the whole import on the foreign key.
        final entries = <SetlistEntry>[];
        for (final e in setlist.entries) {
          final songId = remapped[e.songId] ?? e.songId;
          final present = await txn.query(
            'songs',
            columns: ['id'],
            where: 'id = ?',
            whereArgs: [songId],
            limit: 1,
          );
          if (present.isEmpty) continue;
          entries.add(
            SetlistEntry(id: e.id, songId: songId, overrides: e.overrides),
          );
        }
        var imported = SetlistDocument(
          id: setlist.id,
          name: setlist.name,
          notes: setlist.notes,
          favorite: setlist.favorite,
          createdAt: setlist.createdAt,
          updatedAt: setlist.updatedAt,
          entries: entries,
        );
        // A local setlist with the same id but different content is kept; the
        // imported one is stored as a separate copy (like songs).
        final existing = await txn.query(
          'setlists',
          where: 'id = ?',
          whereArgs: [setlist.id],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final local = await _setlist(txn, existing.single);
          if (_sameSetlistContent(local, imported)) continue;
          imported = SetlistDocument(
            id: newId(),
            name: imported.name,
            notes: imported.notes,
            favorite: imported.favorite,
            createdAt: imported.createdAt,
            updatedAt: imported.updatedAt,
            entries: imported.entries,
          );
        }
        await _writeSetlist(txn, imported);
      }
      if (appSettings != null) {
        await txn.insert('settings', {
          'key': 'app',
          'value': jsonEncode(appSettings),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Replaces all library documents in one transaction, retaining the IDs,
  /// duplicate setlist occurrences, entry order, and per-entry overrides.
  Future<void> replaceLibrary(
    List<SongDocument> songs,
    List<SetlistDocument> setlists, {
    JsonMap? appSettings,
    String? expectedLibraryFingerprint,
  }) async {
    final songIds = songs.map((song) => song.id).toSet();
    final setlistIds = setlists.map((setlist) => setlist.id).toSet();
    final entryIds = <String>{};
    if (songIds.length != songs.length ||
        setlistIds.length != setlists.length) {
      throw const FormatException('invalid_archive');
    }
    for (final setlist in setlists) {
      for (final entry in setlist.entries) {
        if (!entryIds.add(entry.id) || !songIds.contains(entry.songId)) {
          throw const FormatException('invalid_archive');
        }
      }
    }
    final encodedSongs = songs.map((source) {
      final song = _sanitizeImportedDurations(source);
      return (song: song, document: _codec.encode(song));
    }).toList();
    await database.transaction((txn) async {
      if (expectedLibraryFingerprint != null &&
          await _libraryFingerprint(txn) != expectedLibraryFingerprint) {
        throw const FormatException('stale_backup_preview');
      }
      final oldSetlists = await txn.query('setlists', columns: const ['id']);
      final oldSongs = await txn.query('songs', columns: const ['id']);
      for (final row in oldSetlists) {
        await _queue(txn, row['id'] as String, 'setlist', 'delete', null);
      }
      for (final row in oldSongs) {
        await _queue(txn, row['id'] as String, 'song', 'delete', null);
      }
      await txn.delete('setlists');
      await txn.delete('setlist_entries');
      await txn.delete('songs');
      for (final item in encodedSongs) {
        await _writeSong(txn, item.song, item.document);
        await _queue(txn, item.song.id, 'song', 'save', item.song.revision);
      }
      for (final setlist in setlists) {
        await _writeSetlist(txn, setlist);
      }
      if (appSettings != null) {
        await txn.insert('settings', {
          'key': 'app',
          'value': jsonEncode(appSettings),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<String?> getSongHash(String id) async {
    final rows = await database.query(
      'songs',
      columns: ['content_hash'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['content_hash'] as String;
  }

  /// Stable hash of the active ChordPro document used by edit sessions.
  /// Linked discovery evidence may update the aggregate sync hash without
  /// invalidating an editor that is changing only the playable chart.
  Future<String?> getSongEditHash(String id) async {
    final rows = await database.query(
      'songs',
      columns: const ['document_hash', 'content_hash'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.single['document_hash'] as String? ??
        rows.single['content_hash'] as String;
  }

  Future<String?> getSetlistHash(String id) async {
    final setlist = await getSetlist(id);
    return setlist == null ? null : setlistContentHash(setlist);
  }

  /// Conditional sync writes protect local edits made while the network was busy.
  /// Missing expected IDs are rejected; explicit null means the object must not exist.
  ///
  /// With [syncAccount], the sync baseline of every item that was actually
  /// written or deleted is updated in the same transaction: a key (`song:<id>`
  /// or `setlist:<id>`) of [baselineCloudHashes] maps to the cloud hash that
  /// was applied, or to null to forget the item. The local hash recorded is the
  /// hash of the stored state, so an interrupted sync can never leave the
  /// baseline disagreeing with the library.
  Future<JsonMap> applySyncChanges(
    List<SongDocument> songs,
    List<SetlistDocument> setlists, {
    required Map<String, String?> expectedSongHashes,
    required Map<String, String?> expectedSetlistHashes,
    List<String> deletedSongIds = const [],
    List<String> deletedSetlistIds = const [],
    String? syncAccount,
    Map<String, String?> baselineCloudHashes = const {},
  }) async {
    final documents = _isSmallSyncBatch(songs)
        ? _encodeSyncSongs(songs)
        : await _encodeSyncBatchInIsolate(songs);
    return database.transaction((txn) async {
      final savedSongs = <String>[],
          savedSetlists = <String>[],
          conflictSongs = <String>[],
          conflictSetlists = <String>[];
      final savedSongHashes = <String, String?>{},
          savedSetlistHashes = <String, String?>{};
      Future<bool> songUnchanged(String id) async {
        if (!expectedSongHashes.containsKey(id)) return false;
        final state = await _validatedSongState(
          txn,
          id,
          requireSyncRepresentation: true,
        );
        return state?.hash == expectedSongHashes[id];
      }

      Future<bool> setlistUnchanged(String id) async {
        if (!expectedSetlistHashes.containsKey(id)) return false;
        final rows = await txn.query(
          'setlists',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        final hash = rows.isEmpty
            ? null
            : setlistContentHash(await _setlist(txn, rows.single));
        return hash == expectedSetlistHashes[id];
      }

      for (final song in songs) {
        if (!await songUnchanged(song.id)) {
          conflictSongs.add(song.id);
          continue;
        }
        await _writeSong(txn, song, documents[song.id]!);
        savedSongs.add(song.id);
        final storedHash = await txn.query(
          'songs',
          columns: const ['content_hash'],
          where: 'id = ?',
          whereArgs: [song.id],
          limit: 1,
        );
        savedSongHashes[song.id] = storedHash.single['content_hash'] as String;
      }
      // Deletions run before setlist saves so a saved setlist is validated
      // against the final song set and its stored state matches its hash.
      for (final id in deletedSetlistIds) {
        if (!await setlistUnchanged(id)) {
          conflictSetlists.add(id);
          continue;
        }
        await txn.delete('setlists', where: 'id = ?', whereArgs: [id]);
        savedSetlists.add(id);
        savedSetlistHashes[id] = null;
      }
      for (final id in deletedSongIds) {
        if (!await songUnchanged(id)) {
          conflictSongs.add(id);
          continue;
        }
        await _deleteSongTouchingSetlists(txn, id);
        savedSongs.add(id);
        savedSongHashes[id] = null;
      }
      for (final setlist in setlists) {
        if (!await setlistUnchanged(setlist.id)) {
          conflictSetlists.add(setlist.id);
          continue;
        }
        var missing = false;
        for (final entry in setlist.entries) {
          if ((await txn.query(
            'songs',
            columns: ['id'],
            where: 'id = ?',
            whereArgs: [entry.songId],
            limit: 1,
          )).isEmpty) {
            missing = true;
            break;
          }
        }
        if (missing) {
          conflictSetlists.add(setlist.id);
          continue;
        }
        // Applied from the cloud: already acknowledged, so never queued.
        await _writeSetlist(txn, setlist, queue: false);
        savedSetlists.add(setlist.id);
        // Hash the stored state (entry ids may have been regenerated).
        final stored = await txn.query(
          'setlists',
          where: 'id = ?',
          whereArgs: [setlist.id],
          limit: 1,
        );
        savedSetlistHashes[setlist.id] = setlistContentHash(
          await _setlist(txn, stored.single),
        );
      }
      if (syncAccount != null) {
        for (final id in savedSongs) {
          final key = 'song:$id';
          if (!baselineCloudHashes.containsKey(key)) continue;
          await _writeBaseline(
            txn,
            syncAccount,
            'song',
            id,
            baselineCloudHashes[key],
            savedSongHashes[id],
          );
        }
        for (final id in savedSetlists) {
          final key = 'setlist:$id';
          if (!baselineCloudHashes.containsKey(key)) continue;
          await _writeBaseline(
            txn,
            syncAccount,
            'setlist',
            id,
            baselineCloudHashes[key],
            savedSetlistHashes[id],
          );
        }
      }
      return {
        'savedSongIds': savedSongs,
        'savedSetlistIds': savedSetlists,
        'savedSongHashes': savedSongHashes,
        'savedSetlistHashes': savedSetlistHashes,
        'conflictingSongIds': conflictSongs,
        'conflictingSetlistIds': conflictSetlists,
      };
    });
  }

  static Future<void> _writeBaseline(
    DatabaseExecutor txn,
    String account,
    String kind,
    String id,
    String? cloudHash,
    String? localHash,
  ) async {
    if (cloudHash == null || localHash == null) {
      await txn.delete(
        'sync_items',
        where: 'account = ? AND kind = ? AND item_id = ?',
        whereArgs: [account, kind, id],
      );
      return;
    }
    await txn.insert('sync_items', {
      'account': account,
      'kind': kind,
      'item_id': id,
      'cloud_hash': cloudHash,
      'local_hash': localHash,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Every baseline row of [account], keyed `kind:id`.
  Future<Map<String, SyncBaseline>> loadSyncBaselines(String account) async {
    final rows = await database.query(
      'sync_items',
      where: 'account = ?',
      whereArgs: [account],
    );
    return {
      for (final row in rows)
        '${row['kind']}:${row['item_id']}': SyncBaseline(
          kind: row['kind'] as String,
          id: row['item_id'] as String,
          cloudHash: row['cloud_hash'] as String,
          localHash: row['local_hash'] as String,
        ),
    };
  }

  /// Upserts [puts] and forgets [removeKeys] (`kind:id`) in one transaction.
  Future<void> writeSyncBaselines(
    String account, {
    Iterable<SyncBaseline> puts = const [],
    Iterable<String> removeKeys = const [],
  }) async {
    await database.transaction((txn) async {
      for (final put in puts) {
        await _writeBaseline(
          txn,
          account,
          put.kind,
          put.id,
          put.cloudHash,
          put.localHash,
        );
      }
      for (final key in removeKeys) {
        final split = key.indexOf(':');
        await _writeBaseline(
          txn,
          account,
          key.substring(0, split),
          key.substring(split + 1),
          null,
          null,
        );
      }
    });
  }

  /// Forgets all baselines, or all but those of [exceptAccount].
  Future<void> clearSyncBaselines({String? exceptAccount}) async {
    if (exceptAccount == null) {
      await database.delete('sync_items');
    } else {
      await database.delete(
        'sync_items',
        where: 'account <> ?',
        whereArgs: [exceptAccount],
      );
    }
  }

  /// The unchanged ChordPro document and local state hash of a song, or null.
  Future<({String document, String hash})?> getSongRaw(String id) async {
    return database.transaction((txn) async {
      final state = await _validatedSongState(
        txn,
        id,
        requireSyncRepresentation: false,
      );
      if (state == null) return null;
      return (document: state.document, hash: state.hash);
    });
  }

  /// Raw bytes for Drive sync. Unlike backup reads, sync is restricted to
  /// complete records whose identity survives a ChordPro encode/decode cycle.
  Future<({String document, String hash})?> getSyncSongRaw(String id) async {
    final state = await database.transaction(
      (txn) => _validatedSongState(txn, id, requireSyncRepresentation: true),
    );
    if (state == null) return null;
    // Encoding can be expensive even after the consistent database read.
    // Leave the transaction before the background codec builds the wire file.
    final document = state.linked
        ? await _encodeSyncSong(state.song)
        : state.document;
    return (document: document, hash: state.hash);
  }

  /// Id of the newest outbox row (0 when empty). Together with
  /// [clearOutboxThrough] it lets a completed sync acknowledge exactly the
  /// edits it started with, never one made while it ran.
  Future<int> outboxMark() async {
    final rows = await database.rawQuery('SELECT MAX(rowid) AS m FROM outbox');
    return (rows.single['m'] as int?) ?? 0;
  }

  Future<void> clearOutboxThrough(int mark) => database
      .delete('outbox', where: 'rowid <= ?', whereArgs: [mark])
      .then((_) {});

  Future<void> deleteSetlist(String id) async {
    await database.transaction((txn) async {
      await txn.delete('setlists', where: 'id = ?', whereArgs: [id]);
      await _queue(txn, id, 'setlist', 'delete', null);
    });
  }

  Future<dynamic> getSetting(String key) async {
    final rows = await database.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : jsonDecode(rows.single['value'] as String);
  }

  Future<void> setSetting(String key, dynamic value) async {
    final encoded = jsonEncode(value);
    await database.insert('settings', {
      'key': key,
      'value': encoded,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ActivityEntry>> listActivity({
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await database.query(
      'activity',
      orderBy: 'occurred_at DESC,id DESC',
      limit: limit.clamp(1, 500),
      offset: offset,
    );
    return rows
        .map(
          (r) => ActivityEntry(
            id: r['id'] as String,
            objectId: r['object_id'] as String,
            objectKind: r['object_kind'] as String,
            action: r['action'] as String,
            occurredAt: DateTime.parse(r['occurred_at'] as String),
          ),
        )
        .toList();
  }

  /// Returns the latest activity row for each existing song or setlist,
  /// ordered by its timestamp and then ID. [openCount] on each result counts
  /// all historical `opened` events for that object.
  Future<List<ActivityEntry>> listRecentActivity({
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await database.rawQuery(
      '''
      WITH activity_summary AS (
        SELECT
          object_kind,
          object_id,
          MAX(occurred_at) AS latest_at,
          SUM(CASE WHEN action = 'opened' THEN 1 ELSE 0 END) AS open_count
        FROM activity
        GROUP BY object_kind, object_id
      ), latest_ids AS (
        SELECT a.object_kind, a.object_id, MAX(a.id) AS latest_id
        FROM activity AS a
        JOIN activity_summary AS summary
          ON summary.object_kind = a.object_kind
          AND summary.object_id = a.object_id
          AND summary.latest_at = a.occurred_at
        GROUP BY a.object_kind, a.object_id
      )
      SELECT
        latest.id,
        latest.object_id,
        latest.object_kind,
        latest.action,
        latest.occurred_at,
        summary.open_count
      FROM latest_ids
      JOIN activity AS latest
        ON latest.id = latest_ids.latest_id
      JOIN activity_summary AS summary
        ON summary.object_kind = latest.object_kind
        AND summary.object_id = latest.object_id
      WHERE (latest.object_kind = 'song' AND EXISTS (
        SELECT 1 FROM songs AS s WHERE s.id = latest.object_id
      )) OR (latest.object_kind = 'setlist' AND EXISTS (
        SELECT 1 FROM setlists AS l WHERE l.id = latest.object_id
      ))
      ORDER BY latest.occurred_at DESC, latest.id DESC
      LIMIT ? OFFSET ?
      ''',
      [limit.clamp(1, 0x7fffffff), offset.clamp(0, 0x7fffffff)],
    );
    return rows
        .map(
          (r) => ActivityEntry(
            id: r['id'] as String,
            objectId: r['object_id'] as String,
            objectKind: r['object_kind'] as String,
            action: r['action'] as String,
            occurredAt: DateTime.parse(r['occurred_at'] as String),
            openCount: r['open_count'] as int,
          ),
        )
        .toList();
  }

  Future<void> addActivity(ActivityEntry entry) => database
      .insert('activity', {
        'id': entry.id,
        'object_id': entry.objectId,
        'object_kind': entry.objectKind,
        'action': entry.action,
        'occurred_at': entry.occurredAt.toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore)
      .then((_) {});
  Future<void> clearActivity() => database.delete('activity').then((_) {});
  Future<void> _queue(
    DatabaseExecutor db,
    String id,
    String kind,
    String action,
    int? revision,
  ) async {
    await db.insert('outbox', {
      'id': newId(),
      'object_id': id,
      'object_kind': kind,
      'action': action,
      'revision': revision,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> close() => database.close();
}

/// Writes related sync settings in one SQLite transaction. This is used for
/// state transitions whose partial persistence could make recovery destructive.
extension AtomicLibrarySettings on LibraryRepository {
  Future<void> setSettingsAtomically(Map<String, Object?> values) =>
      database.transaction((txn) async {
        for (final entry in values.entries) {
          await txn.insert('settings', {
            'key': entry.key,
            'value': jsonEncode(entry.value),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
}
