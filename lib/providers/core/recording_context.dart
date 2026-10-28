import 'dart:convert';

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
      _originalHash = _candidateHash(original),
      _selectionJson = jsonEncode(selection.toJson()),
      _hashes = {
        for (final witness in witnesses) witness.id: _sourceHash(witness),
      };

  // Each caller gets its own context maps; a receiver cannot mutate the proof.
  SongCandidate get selection =>
      SongCandidate.fromJson(jsonDecode(_selectionJson) as JsonMap);
  final String _selectionJson, _originalHash;
  final String originalIdentity;
  final String namespace;
  final String anchorSourceId, donorSourceId;
  final List<SourceResult> witnesses;
  final Map<String, String> _hashes;

  /// Recheck after every asynchronous lookup and synchronous progress callback.
  /// A source toggled off, withdrawn or changed cannot support a late result.
  bool isCurrent(
    Iterable<SourceResult> current, {
    required SongCandidate original,
    required bool Function(String providerId) eligible,
  }) =>
      _candidateHash(original) == _originalHash &&
      witnesses.every(
        (witness) =>
            eligible(witness.candidate.providerId) &&
            current.any((source) => source.id == witness.id) &&
            current
                .where((source) => source.id == witness.id)
                .every(
                  (source) =>
                      source.id == witness.id &&
                      _qualified(source) &&
                      _sourceHash(source) == _hashes[witness.id],
                ),
      );

  JsonMap get provenance => {
    'selectedIdentity': originalIdentity,
    'namespace': namespace,
    'identifier': selection.recordingIds[namespace],
    'anchorSourceId': anchorSourceId,
    'donorSourceId': donorSourceId,
    'witnesses': [
      for (final witness in witnesses)
        {
          'sourceId': witness.id,
          'providerId': witness.candidate.providerId,
          'sha256': _hashes[witness.id],
        },
    ],
  };
}

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
  }.toList();
  if (!_factsAgree([
    SourceResult(candidate: original, body: ''),
    ...witnesses,
  ])) {
    return null;
  }
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
          first.id == second.id && _sourceHash(first) != _sourceHash(second)) {
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

String _sourceHash(SourceResult source) =>
    sha256.convert(utf8.encode(jsonEncode(source.toJson()))).toString();

String _candidateHash(SongCandidate candidate) =>
    sha256.convert(utf8.encode(jsonEncode(candidate.toJson()))).toString();
