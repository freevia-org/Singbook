import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

import '../../domain/combine.dart' show recordingCompatible;
import '../../domain/edition_identity.dart';
import '../../domain/models.dart';

/// Optional native dependency. Catalog JSON cannot invent a new lookup mode.
/// Wrappers return null when their compiled delegate needs no recording ID.
abstract interface class RecordingContextReceiver {
  String? get requiredRecordingIdNamespace;
}

/// An independently proved identifier handoff. This is lookup context, not a
/// claim that the receiving publisher supplied the donor's metadata.
class RecordingContextPlan {
  RecordingContextPlan._(
    SongCandidate original,
    SongCandidate selection,
    this.namespace,
    this.anchorSourceId,
    this.donorSourceId,
    this.witnesses,
  ) : originalIdentity = original.identity,
      _originalSnapshot = jsonDecode(jsonEncode(_canonical(original.toJson()))),
      _selectionJson = jsonEncode(selection.toJson()),
      _identifier = selection.recordingIds[namespace],
      _witnessSnapshots = {
        for (final witness in witnesses) witness.id: _witnessSnapshot(witness),
      };

  // Each caller gets its own context maps; a receiver cannot mutate the proof.
  SongCandidate get selection =>
      SongCandidate.fromJson(jsonDecode(_selectionJson) as JsonMap);
  final String _selectionJson;
  final String? _identifier;
  final Object? _originalSnapshot;
  final String originalIdentity;
  final String namespace;
  final String anchorSourceId, donorSourceId;
  final List<SourceResult> witnesses;
  final Map<String, _RecordingWitnessSnapshot> _witnessSnapshots;

  /// Recheck after every asynchronous lookup and synchronous progress callback.
  /// A source toggled off, withdrawn or changed cannot support a late result.
  bool isCurrent(
    Iterable<SourceResult> current, {
    required SongCandidate original,
    required bool Function(String providerId) eligible,
  }) {
    if (!_matchesProofSnapshot(_originalSnapshot, original.toJson()) ||
        witnesses.any((witness) => !eligible(witness.candidate.providerId))) {
      return false;
    }
    final seen = <String>{};
    for (final source in current) {
      final id = source.id;
      final snapshot = _witnessSnapshots[id];
      if (snapshot == null) continue;
      if (!_qualified(source) ||
          !_matchesProofSnapshot(snapshot.payload, source.toJson())) {
        return false;
      }
      seen.add(id);
    }
    return seen.length == _witnessSnapshots.length;
  }

  JsonMap get provenance => {
    'selectedIdentity': originalIdentity,
    'namespace': namespace,
    'identifier': _identifier,
    'anchorSourceId': anchorSourceId,
    'donorSourceId': donorSourceId,
    'witnesses': [
      for (final witness in witnesses)
        {
          'sourceId': witness.id,
          'providerId': witness.candidate.providerId,
          'sha256': _witnessSnapshots[witness.id]!.sha256,
          'identitySha256': _witnessSnapshots[witness.id]!.identitySha256,
        },
    ],
  };
}

/// Plan the dependent lookup from a captured snapshot. The discovery caller
/// must revalidate the returned witnesses against its live results.
Future<RecordingContextPlan?> prepareRecordingContext(
  SongCandidate original,
  List<SourceResult> sources, {
  required String namespace,
  required Set<String> eligible,
}) => Isolate.run(
  () => planRecordingContext(
    original,
    sources,
    namespace: namespace,
    eligible: eligible.contains,
  ),
  debugName: 'singbook-recording-context',
);

/// Derive one bounded receiver lookup from already fetched recording evidence.
/// Crucially, identity checks happen before adding the requested identifier.
/// Nothing here searches another catalog or upgrades a same-song result.
RecordingContextPlan? planRecordingContext(
  SongCandidate original,
  Iterable<SourceResult> sources, {
  required String namespace,
  required bool Function(String providerId) eligible,
}) {
  if (namespace != 'musicbrainz' ||
      original.recordingIds.containsKey(namespace) ||
      original.hasPendingMatchCheck) {
    return null;
  }
  final pool = sources
      .where(
        (source) => eligible(source.candidate.providerId) && _qualified(source),
      )
      .toList();
  final anchors = pool
      .where((source) => recordingCompatible(original, source))
      .toList();
  if (anchors.isEmpty) return null;

  final accepted = <({SourceResult anchor, SourceResult donor, String id})>[];
  for (final donor in pool) {
    final id = donor.candidate.recordingIds[namespace];
    if (donor.candidate.providerId != 'musicbrainz' ||
        donor.candidate.metadata['identityScope'] != 'recording' ||
        id == null ||
        !_mbid.hasMatch(id) ||
        donor.candidate.id.toLowerCase() != id.toLowerCase()) {
      continue;
    }
    for (final anchor in anchors) {
      // No derived ID may participate in these independent proofs.
      if (!recordingCompatible(anchor.candidate, donor) ||
          !_compatible(original, donor.candidate) ||
          !_compatible(anchor.candidate, donor.candidate) ||
          !_factsAgree([
            SourceResult(candidate: original, body: ''),
            anchor,
            donor,
          ]) ||
          !explicitEditionsCompatible(
            original,
            donor.candidate,
            metadata: donor.metadata,
            extra: donor.extra,
          ) ||
          !explicitEditionsCompatible(
            anchor.candidate,
            donor.candidate,
            selectedMetadata: anchor.metadata,
            selectedExtra: anchor.extra,
            metadata: donor.metadata,
            extra: donor.extra,
          )) {
        continue;
      }
      accepted.add((anchor: anchor, donor: donor, id: id.toLowerCase()));
    }
  }
  // Do not choose an arbitrary recording when independent donors disagree.
  if (accepted.map((pair) => pair.id).toSet().length != 1) return null;
  final witnesses = {
    for (final pair in accepted) ...[pair.anchor, pair.donor],
  }.toList()..sort((a, b) => a.id.compareTo(b.id));
  if (!_factsAgree([
    SourceResult(candidate: original, body: ''),
    ...witnesses,
  ])) {
    return null;
  }
  final duplicateHashes = Map<SourceResult, String>.identity();
  for (final first in witnesses) {
    for (final second in witnesses) {
      if (!_compatible(first.candidate, second.candidate) ||
          !explicitEditionsCompatible(
            first.candidate,
            second.candidate,
            selectedMetadata: first.metadata,
            selectedExtra: first.extra,
            metadata: second.metadata,
            extra: second.extra,
          ) ||
          first.id == second.id &&
              !identical(first, second) &&
              duplicateHashes.putIfAbsent(first, () => _sourceHash(first)) !=
                  duplicateHashes.putIfAbsent(
                    second,
                    () => _sourceHash(second),
                  )) {
        return null;
      }
    }
  }
  accepted.sort((a, b) {
    final anchor = a.anchor.id.compareTo(b.anchor.id);
    return anchor != 0 ? anchor : a.donor.id.compareTo(b.donor.id);
  });
  final pair = accepted.first;
  final context = SongCandidate.fromJson(
    jsonDecode(
          jsonEncode({
            ...original.toJson(),
            'album': original.album ?? pair.anchor.candidate.album,
            'durationSeconds':
                original.durationSeconds ??
                pair.anchor.candidate.durationSeconds,
            'recordingIds': {
              ...original.recordingIds,
              ...pair.anchor.candidate.recordingIds,
              namespace: pair.id,
            },
          }),
        )
        as JsonMap,
  );
  return RecordingContextPlan._(
    original,
    context,
    namespace,
    pair.anchor.id,
    pair.donor.id,
    List.unmodifiable(witnesses),
  );
}

final _mbid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool _qualified(SourceResult source) =>
    source.matchKind == MatchKind.sameRecording &&
    !source.hasPendingMatchCheck &&
    [
      source.candidate.metadata,
      source.candidate.extra,
      source.metadata,
      source.extra,
    ].every(
      (map) =>
          !map.containsKey('identityScope') ||
          map['identityScope'] == 'recording',
    );

bool _factsAgree(List<SourceResult> sources) {
  final albums = <String>{};
  final durations = <double>[];
  for (final source in sources) {
    if (source.candidate.album case final String album) {
      albums.add(_normalize(album));
    }
    if (source.candidate.durationSeconds case final double duration) {
      durations.add(duration);
    }
    for (final map in [
      source.candidate.metadata,
      source.candidate.extra,
      source.metadata,
      source.extra,
    ]) {
      if (map['album'] case final String album) {
        albums.add(_normalize(album));
      } else if (map['album'] != null) {
        return false;
      }
      for (final key in ['durationSeconds', 'duration']) {
        if (!map.containsKey(key) || map[key] == null) continue;
        if (map[key] is! num) return false;
        durations.add((map[key] as num).toDouble());
      }
    }
  }
  albums.remove('');
  if (albums.length > 1 ||
      durations.any(
        (value) => !value.isFinite || value <= 0 || value > 86400,
      )) {
    return false;
  }
  durations.sort();
  return durations.isEmpty || durations.last - durations.first <= 3;
}

bool _compatible(SongCandidate original, SongCandidate donor) {
  for (final entry in original.recordingIds.entries) {
    if (donor.recordingIds.containsKey(entry.key) &&
        donor.recordingIds[entry.key] != entry.value) {
      return false;
    }
  }
  if (original.album != null &&
      donor.album != null &&
      _normalize(original.album!) != _normalize(donor.album!)) {
    return false;
  }
  final a = original.durationSeconds, b = donor.durationSeconds;
  return (a == null || b == null || (a - b).abs() <= 3) &&
      explicitEditionsCompatible(original, donor);
}

String _normalize(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

String _sourceHash(SourceResult source) => sha256
    .convert(utf8.encode(jsonEncode(_canonical(source.toJson()))))
    .toString();

typedef _RecordingWitnessSnapshot = ({
  Object? payload,
  String sha256,
  String identitySha256,
});

_RecordingWitnessSnapshot _witnessSnapshot(SourceResult source) {
  final snapshot = source.toJson();
  final encoded = jsonEncode(_canonical(snapshot));
  return (
    payload: jsonDecode(encoded),
    sha256: sha256.convert(utf8.encode(encoded)).toString(),
    identitySha256: _recordingWitnessHash(source, snapshot),
  );
}

/// Match canonical JSON without sorting keys, encoding large bodies or raw
/// assets, or recalculating SHA-256 on each synchronous provider callback.
bool _matchesProofSnapshot(Object? snapshot, Object? live) {
  if (snapshot is Map && live is Map) {
    return snapshot.length == live.length &&
        snapshot.entries.every(
          (entry) =>
              live.containsKey(entry.key) &&
              _matchesProofSnapshot(entry.value, live[entry.key]),
        );
  }
  if (snapshot is List && live is List) {
    if (snapshot.length != live.length) return false;
    for (var i = 0; i < snapshot.length; i++) {
      if (!_matchesProofSnapshot(snapshot[i], live[i])) return false;
    }
    return true;
  }
  if (live is double) {
    return snapshot is double &&
        snapshot == live &&
        snapshot.isNegative == live.isNegative;
  }
  if (live is int) return snapshot is int && snapshot == live;
  if (live == null ||
      live is bool ||
      live is String ||
      live is List ||
      live is Map) {
    return snapshot == live;
  }
  // Keep supporting values accepted through Dart's JSON toJson protocol.
  return _matchesProofSnapshot(snapshot, jsonDecode(jsonEncode(live)));
}

/// Revalidate retained proof for presentation after controller merges or a
/// portable round trip. This does not promote estimates into musical truth.
bool recordingContextCompatible(
  SongCandidate original,
  SourceResult result,
  Iterable<SourceResult> sources, {
  required bool Function(String providerId) eligible,
}) {
  if (!eligible(result.candidate.providerId) ||
      result.matchKind != MatchKind.sameRecording ||
      result.hasPendingMatchCheck ||
      result.extra['recordingContext'] is! Map) {
    return false;
  }
  final plan = planRecordingContext(
    original,
    sources.where((source) => source.id != result.id),
    namespace: 'musicbrainz',
    eligible: eligible,
  );
  return plan != null &&
      result.candidate.recordingIds[plan.namespace] ==
          plan.selection.recordingIds[plan.namespace] &&
      jsonEncode(_canonical(_contextBinding(plan.provenance))) ==
          jsonEncode(
            _canonical(
              _contextBinding(result.extra['recordingContext'] as Map),
            ),
          ) &&
      recordingCompatible(plan.selection, result);
}

Map<String, Object?> _contextBinding(Map proof) => {
  for (final key in [
    'selectedIdentity',
    'namespace',
    'identifier',
    'anchorSourceId',
    'donorSourceId',
  ])
    key: proof[key],
  'witnesses': [
    if (proof['witnesses'] is List)
      for (final witness in proof['witnesses'] as List)
        if (witness is Map)
          {
            'sourceId': witness['sourceId'],
            'providerId': witness['providerId'],
            'identitySha256': witness['identitySha256'],
          },
  ],
};

// Controller merging archives old envelopes and may repeat an unchanged
// candidate fact in metadata. Normalize those containers only; active facts,
// source identity, body, raw payloads, editions and conflicts remain bound.
// Discovery's live mutation guard continues using the full _sourceHash.
String _recordingWitnessHash(SourceResult source, JsonMap snapshot) {
  final payload = {...snapshot};
  for (final key in [
    'previousSourceVersions',
    'unparsedSourceHistory',
    'metadataPayloadOrigins',
    'retainedPreviousPayload',
    'retrievedAt',
  ]) {
    payload.remove(key);
  }
  final metadata = {...source.metadata};
  final candidateFacts = {
    ...source.candidate.metadata,
    if (source.candidate.album != null) 'album': source.candidate.album,
    if (source.candidate.durationSeconds != null)
      'durationSeconds': source.candidate.durationSeconds,
  };
  metadata.removeWhere(
    (key, value) =>
        candidateFacts.containsKey(key) &&
        jsonEncode(_canonical(value)) ==
            jsonEncode(_canonical(candidateFacts[key])),
  );
  payload['metadata'] = metadata;
  return sha256
      .convert(utf8.encode(jsonEncode(_canonical(payload))))
      .toString();
}

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) return value.map(_canonical).toList();
  return value;
}
