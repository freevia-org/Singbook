part of 'combine.dart';

/// Resolve every payload already returned by discovery without another fetch.
/// The original envelope remains intact, including failed search observations.
List<SourceResult> _sourceDocuments(
  List<SourceResult> input,
  List<SourceResult> observations,
) {
  final documents = <String, SourceResult>{};
  final occurrences = <String, int>{};
  for (final source in input) {
    documents[source.id] = source;
    occurrences.update(source.id, (count) => count + 1, ifAbsent: () => 1);
  }
  // Only an ID observed more than once keeps its separate observations.
  final snapshots = <String, List<JsonMap>>{};
  for (final source in input) {
    if (occurrences[source.id]! < 2) continue;
    snapshots.putIfAbsent(source.id, () => []).add(source.toJson());
  }
  for (final source in observations) {
    if (source.extra['searchEvidenceOnly'] == true) continue;
    documents.putIfAbsent(source.id, () => source);
  }
  for (final entry in snapshots.entries) {
    final source = documents[entry.key]!;
    documents[entry.key] = source.copyWith(
      extra: {...source.extra, 'sourceEvidenceSnapshots': entry.value},
    );
  }
  return documents.values.toList();
}

List<SourceResult> _retainedSourceEvidence(
  SongCandidate selected,
  List<SourceResult> input,
) {
  final result = <SourceResult>[];
  final seen = <String>{};
  final seenPayloads = <String>{};
  final retainedObjects = Set<SourceResult>.identity();
  final currentById = {for (final source in input) source.id: source};
  // A source is fingerprinted with and without its discovery envelope;
  // serialize it once for both.
  final serialized = Map<SourceResult, JsonMap>.identity();
  String fingerprint(SourceResult source, {bool payloadOnly = false}) {
    final values = {
      ...serialized.putIfAbsent(source, () => source.toJson()),
    };
    if (payloadOnly) {
      values.remove('discoveryEvidence');
      values.remove('providerAlternatives');
    }
    try {
      return _bodyHash(jsonEncode(values));
    } on Object {
      return _bodyHash(values.toString());
    }
  }

  void add(SourceResult source, {bool snapshot = false}) {
    if (!retainedObjects.add(source)) return;
    String? payloadFingerprint;
    if (snapshot) {
      payloadFingerprint = fingerprint(source, payloadOnly: true);
      if (seenPayloads.contains(payloadFingerprint)) return;
    }
    final current = currentById[source.id];
    if (source.arrangementId == null &&
        current != null &&
        source.body.trim().isNotEmpty &&
        source.body != current.body) {
      payloadFingerprint = null;
      final viewId =
          'snapshot-${_bodyHash(jsonEncode({
            'body': source.body,
            'metadata': {...source.candidate.metadata, ...source.metadata},
          })).substring(0, 16)}';
      source = SourceResult(
        candidate: source.candidate,
        body: source.body,
        metadata: source.metadata,
        timingTracks: source.timingTracks,
        matchKind: source.matchKind,
        attribution: source.attribution,
        matchReason: source.matchReason,
        retrievedAt: source.retrievedAt,
        arrangementId: viewId,
        extra: {
          ...source.extra,
          'parentSourceId': source.id,
          'parentCandidate': source.candidate.toJson(),
          'retainedPayloadView': true,
        },
      );
    }
    final hasEnvelope =
        source.extra.containsKey('discoveryEvidence') ||
        source.extra.containsKey('providerAlternatives');
    final fullFingerprint = hasEnvelope
        ? fingerprint(source)
        : payloadFingerprint ?? fingerprint(source);
    if (seen.add(fullFingerprint)) {
      seenPayloads.add(
        hasEnvelope
            ? payloadFingerprint ?? fingerprint(source, payloadOnly: true)
            : fullFingerprint,
      );
      result.add(source);
    }
  }

  void payload(Object? raw, {String? rejectedReason}) {
    if (raw is! Map || raw['candidate'] is! Map) return;
    try {
      final data = jsonMap(raw);
      final candidate = SongCandidate.fromJson(jsonMap(data['candidate']));
      final arrangementId = data['arrangementId'];
      final observedId = arrangementId is String
          ? '${candidate.identity}#arrangement=$arrangementId'
          : candidate.identity;
      final current = currentById[observedId];
      if (current != null) {
        // Discovery snapshots precede chart corroboration. Apply the current
        // derived context to every view of this ID; retain published/raw facts.
        for (final key in const [
          'keyConsensus',
          'keyShift',
          'keyEstimate',
          'keyRecording',
          'pendingMatchCheck',
          'requiresLyricsAgreement',
          'requiresRecordingLyricsAgreement',
          'alternatePerformerChart',
          'lyricRepresentation',
          'lyricRepresentationEvidence',
          'partialLyricSupport',
        ]) {
          data.remove(key);
          if (current.extra.containsKey(key)) data[key] = current.extra[key];
        }
      }
      // A terminal rejection supersedes an earlier tentative acceptance of
      // this same source. The original observation stays in its envelope.
      final currentRejection = current?.matchKind == MatchKind.rejected;
      add(
        SourceResult.fromJson({
          ...data,
          if (rejectedReason != null) 'matchKind': MatchKind.rejected.name,
          'matchReason': ?rejectedReason,
          if (currentRejection) 'matchKind': MatchKind.rejected.name,
          if (currentRejection) 'matchReason': current!.matchReason,
          if (current?.hasPendingMatchCheck == true) 'pendingMatchCheck': true,
        }),
        snapshot: true,
      );
    } on Object {
      // Malformed envelopes remain preserved on the original source. They
      // cannot safely become a resolved source document.
    }
  }

  // Canonical resolved results must precede every discovery observation. An
  // earlier provider envelope can mention a later result's ID; that preview
  // must not supply the body or setup used to check the resolved chart.
  for (final source in currentById.values) {
    add(source);
  }
  for (final source in input) {
    add(source);
  }
  for (final source in input) {
    final envelope = jsonMap(source.extra['discoveryEvidence']);
    for (final raw in _listOrEmpty(source.extra['sourceEvidenceSnapshots'])) {
      payload(raw);
    }
    for (final raw in _listOrEmpty(envelope['acceptedPayloads'])) {
      payload(raw);
    }
    for (final raw in _listOrEmpty(envelope['rejectedPayloads'])) {
      final entry = jsonMap(raw);
      final reason = entry['reason'];
      payload(
        entry['payload'],
        rejectedReason: reason is String ? reason : null,
      );
    }
    for (final raw in _listOrEmpty(source.extra['providerAlternatives'])) {
      payload(raw);
    }
    for (final raw in _listOrEmpty(envelope['searchCandidates'])) {
      final candidate = jsonMap(jsonMap(raw)['candidate']);
      if (candidate.isEmpty) continue;
      try {
        final observation = SongCandidate.fromJson(candidate);
        final chartProvider =
            source.hasChords ||
            (envelope['capabilities'] is List &&
                (envelope['capabilities'] as List).contains('chords'));
        add(
          SourceResult(
            candidate: observation,
            body: '',
            matchKind: MatchKind.unverified,
            extra: {
              'searchEvidenceOnly': true,
              'discoveredBy': source.id,
              'searchArrangementMatch':
                  chartProvider &&
                  observation.providerId == source.candidate.providerId &&
                  _sameArrangedSong(selected, observation),
            },
          ),
        );
      } on Object {
        // The unparsed search observation is still in its discovery envelope.
      }
    }
  }
  final interpreted = <SourceResult>[];
  final viewsById = <String, SourceResult>{};
  for (final source in result) {
    if (source.arrangementId != null &&
        source.extra['retainedPayloadView'] != true) {
      viewsById.putIfAbsent(source.id, () => source);
      continue;
    }
    final views = splitChartArrangements(source);
    if (views.isEmpty) {
      interpreted.add(source);
      continue;
    }
    interpreted.add(
      source.copyWith(
        extra: {
          ...source.extra,
          'hasArrangementViews': true,
          'arrangementViewIds': views.map((view) => view.id).toList(),
        },
      ),
    );
    for (final view in views) {
      viewsById.putIfAbsent(view.id, () => view);
    }
  }
  return [...interpreted, ...viewsById.values];
}

const _rankedArrangementFields = {
  'key',
  'capo',
  'tuning',
  'tempo',
  'timeSignature',
  'difficulty',
  'arrangement',
};
const _rankedRecordingFields = {
  'album',
  'artworkUrl',
  'duration',
  'durationSeconds',
  'mediaLinks',
  'recording',
  'releaseDate',
  'releaseDateDisplay',
  'recordingLocation',
  'recordingId',
  'recordingIds',
  'isrc',
  'isrcs',
  'musicbrainzRecordingId',
  'musicbrainzReleaseId',
  'relationships',
  'year',
};
const _rankedControlFields = {
  'identityScope',
  'query',
  'record',
  'rights',
  'url',
  'providerId',
  'id',
  'title',
  'artist',
  'lyrics',
  'body',
  'hasLyrics',
  'pendingMatchCheck',
  'sourceId',
  'timingTracks',
  'fieldOrigins',
  'fieldContributors',
  'conflicts',
  'evidenceOrigin',
  'sourceOrigin',
  'lineageId',
  'sourceLineageId',
  'providerLineage',
};

Iterable<JsonMap> _recordingAnalyses(SourceResult source) sync* {
  final primary = jsonMap(source.extra['keyRecording']);
  if (primary.isEmpty) return;
  yield primary;
  for (final raw
      in primary['alternatives'] is List
          ? primary['alternatives'] as List
          : const []) {
    if (raw is! Map) continue;
    yield {
      ...jsonMap(raw),
      for (final field in const [
        'recordingScope',
        'selectedIdentity',
        'identifierSourceIds',
        'identifierProviders',
      ])
        if (primary.containsKey(field)) field: primary[field],
    };
  }
}

bool _recordingKeyBound(
  SongCandidate selected,
  List<SourceResult> sources,
  JsonMap recording,
  _MergeScoreCache scores,
) {
  if (recording['recordingScope'] == 'song') return false;
  final ids = _listOrEmpty(recording['ids']).whereType<String>().toSet();
  if (ids.isEmpty) return false;
  if (recording['selectedIdentity'] == selected.identity) return true;
  return ids.any(scores.knownRecordingIds(sources).contains);
}

/// Every recording identifier known for [selected]: its own, and those of
/// the [sources] that are the same recording.
Set<String> _collectKnownRecordingIds(
  SongCandidate selected,
  List<SourceResult> sources,
  _MergeScoreCache scores,
) {
  final known = <String>{...selected.recordingIds.values};
  void addMetadata(JsonMap metadata) {
    if (metadata['isrc'] is String) known.add(metadata['isrc'] as String);
    if (metadata['isrcs'] is List) {
      known.addAll((metadata['isrcs'] as List).whereType<String>());
    }
    for (final raw
        in metadata['mediaLinks'] is List
            ? metadata['mediaLinks'] as List
            : const []) {
      final url = jsonMap(raw)['url'];
      final uri = url is String ? Uri.tryParse(url) : null;
      if (uri?.host == 'open.spotify.com' &&
          uri!.pathSegments.length >= 2 &&
          uri.pathSegments[uri.pathSegments.length - 2] == 'track') {
        known.add(uri.pathSegments.last);
      }
    }
  }

  addMetadata(selected.metadata);
  for (final source in sources.where(scores.sameRecording)) {
    known.addAll(source.candidate.recordingIds.values);
    addMetadata(source.candidate.metadata);
    addMetadata(source.metadata);
  }
  return known;
}

/// Keep the published setup and offer a separately labelled playable setup
/// for a bound recording key. Only the capo changes; source text stays exact.
/// Conflicting recording signatures produce competing options, never a veto.
List<SourceResult> _recordingArrangementViews(
  SongCandidate selected,
  List<SourceResult> sources,
  _MergeScoreCache scores,
) {
  final targets = <String>[];
  for (final source in sources) {
    for (final recording in _recordingAnalyses(source)) {
      final key = recording['key'];
      if (key is String &&
          _keyIdentity(key) != null &&
          (_recordingKeyBound(selected, sources, recording, scores) ||
              const {
                    MatchKind.sameSong,
                    MatchKind.sameRecording,
                  }.contains(source.matchKind) &&
                  _sameArrangedSong(selected, source.candidate))) {
        targets.add(key);
      }
    }
  }
  targets.sort();
  final signatures = <String>[];
  for (final target in targets) {
    if (!signatures.any((key) => _keyDistance(key, target) == 0)) {
      signatures.add(target);
    }
  }
  final views = <String, SourceResult>{};
  for (final target in signatures) {
    final bound = sources.any(
      (source) => _recordingAnalyses(source).any((recording) {
        final key = recording['key'];
        return key is String &&
            _keyDistance(key, target) == 0 &&
            _recordingKeyBound(selected, sources, recording, scores);
      }),
    );
    for (final source in sources) {
      if (!source.hasChords ||
          source.extra['hasArrangementViews'] == true ||
          source.extra['recordingArrangement'] is Map ||
          source.extra['searchEvidenceOnly'] == true ||
          source.hasPendingMatchCheck ||
          !const {
            MatchKind.sameSong,
            MatchKind.sameRecording,
          }.contains(source.matchKind) ||
          !_sameArrangedSong(selected, source.candidate) ||
          !explicitEditionsCompatible(
            selected,
            source.candidate,
            metadata: source.metadata,
            extra: source.extra,
          ) ||
          source.extra['keyShift'] is int && source.extra['keyShift'] != 0) {
        continue;
      }
      // Published key declarations remain independent competitors. Derive a
      // setup only where the chart has no literal key to contradict or rewrite.
      if (_keyIdentity(_setupValue(source, selected, 'key')) != null) continue;
      final hypotheses = rankChordKeyCandidates(source.body);
      if (hypotheses.isEmpty) continue;
      final oldCapo = _capoOf(_setupValue(source, selected, 'capo'));
      final sounding = transposeChord(hypotheses.first.key, oldCapo);
      final shift = _keyDistance(sounding, target);
      if (shift == null ||
          shift == 0 ||
          _chartSupportsSoundingKey(source, selected, target, scores)) {
        continue;
      }
      final newCapo = (oldCapo + shift) % 12;
      final descriptor = {
        'parentSourceId': source.id,
        'bodyHash': _bodyHash(source.body),
        'publishedCapo': oldCapo,
        'capo': newCapo,
        'recordingKey': target,
        'recordingScope': bound ? 'recording' : 'song',
        'basis': bound
            ? 'bound_recording_key_and_chart_harmony'
            : 'same_song_key_and_chart_harmony',
      };
      final id =
          'recording-${_bodyHash(jsonEncode(descriptor)).substring(0, 16)}';
      final view = SourceResult(
        candidate: SongCandidate.fromJson({
          ...source.candidate.toJson(),
          'metadata': {...source.candidate.metadata, 'capo': newCapo},
        }),
        body: source.body,
        metadata: {...source.metadata, 'capo': newCapo},
        matchKind: MatchKind.sameSong,
        matchReason: source.matchReason,
        attribution: source.attribution,
        retrievedAt: source.retrievedAt,
        arrangementId: id,
        extra: {
          for (final entry in source.extra.entries)
            if (!const {
              'discoveryEvidence',
              'providerAlternatives',
              'originalPayload',
              'sourceEvidenceSnapshots',
              'keyConsensus',
              'keyShift',
              'keyEstimate',
              'keyRecording',
            }.contains(entry.key))
              entry.key: entry.value,
          'parentSourceId': source.id,
          'parentCandidate': source.candidate.toJson(),
          'recordingArrangement': descriptor,
        },
      );
      views.putIfAbsent(view.id, () => view);
    }
  }
  return views.values.toList();
}

bool _chartSupportsSoundingKey(
  SourceResult source,
  SongCandidate selected,
  String key,
  _MergeScoreCache scores,
) {
  final body = scores.correctedBody(source);
  final capo = _capoOf(_setupValue(source, selected, 'capo'));
  final shape = transposeChord(key, (12 - capo) % 12);
  if (scores.supportsTonic(body, shape)) return true;
  final estimate = scores.estimateFor(body);
  if (estimate != null) {
    return _keyDistance(transposeChord(estimate.key, capo), key) == 0;
  }
  return scores
      .hypothesesFor(body)
      .take(3)
      .any((candidate) => _keyDistance(candidate.key, shape) == 0);
}

String _withoutChordAnchors(String body) {
  final raw = body.split('\n');
  final lines = parseArrangement(body);
  return [
    for (var i = 0; i < lines.length; i++)
      lines[i].chords.isEmpty
          ? raw[i]
          : _escapeLiteralChordTokens(lines[i].text),
  ].join('\n');
}
