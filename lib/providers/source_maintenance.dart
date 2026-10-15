import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/models.dart';
import 'provider.dart';
import 'source_catalog.dart';

/// Runs deterministic health probes against the current provider contracts.
/// Reports contain source/probe identity and shape metadata, never song text.
class SourceMaintenanceHarness {
  SourceMaintenanceHarness({required Iterable<LyricsProvider> providers})
    : _providers = {
        for (final provider in providers) provider.definition.id: provider,
      };

  final Map<String, LyricsProvider> _providers;

  Future<JsonMap> run(
    SourceCatalog catalog, {
    bool offline = false,
    Set<String>? sourceIds,
  }) async {
    final reports = <JsonMap>[];
    for (final entry in catalog.sources) {
      if (sourceIds != null && !sourceIds.contains(entry.id)) continue;
      reports.add(await _source(entry, offline: offline));
    }
    final catalogIds = catalog.sources.map((entry) => entry.id).toSet();
    for (final provider in _providers.values) {
      final definition = provider.definition;
      if (catalogIds.contains(definition.id) ||
          sourceIds != null && !sourceIds.contains(definition.id)) {
        continue;
      }
      reports.add({
        'id': definition.id,
        'name': definition.name,
        'status': 'coverage_gap',
        'reason': 'catalog_entry_missing',
      });
    }
    final counts = <String, int>{};
    for (final source in reports) {
      final status = source['status'] as String;
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return {
      'schemaVersion': 1,
      'catalogRevision': catalog.revision,
      'measuredAt': DateTime.now().toUtc().toIso8601String(),
      'offline': offline,
      'summary': counts,
      'sources': reports,
    };
  }

  Future<JsonMap> _source(
    SourceCatalogEntry entry, {
    required bool offline,
  }) async {
    final base = <String, dynamic>{'id': entry.id, 'name': entry.name};
    if (!entry.isActive) {
      return {
        ...base,
        'status': entry.status,
        'probes': [
          for (final probe in entry.probes)
            {'id': probe['id'], 'status': entry.status},
        ],
      };
    }
    if (entry.capabilities.contains('fileImport') &&
        !entry.capabilities.contains('catalog')) {
      return {
        ...base,
        'status': 'import_only',
        'probes': [
          for (final probe in entry.probes)
            {'id': probe['id'], 'status': 'import_only'},
        ],
      };
    }
    if (entry.probes.isEmpty) {
      return {...base, 'status': 'coverage_gap', 'reason': 'missing_probe'};
    }
    if (offline) {
      return {
        ...base,
        'status': 'offline_unverified',
        'probes': [
          for (final probe in entry.probes)
            {'id': probe['id'], 'status': 'offline_unverified'},
        ],
      };
    }
    final provider = _providers[entry.id];
    if (provider == null) {
      return {
        ...base,
        'status': 'coverage_gap',
        'reason': 'provider_missing',
        'probes': [
          for (final probe in entry.probes)
            {
              'id': probe['id'],
              'status': 'coverage_gap',
              'reason': 'provider_missing',
            },
        ],
      };
    }
    final probeReports = <JsonMap>[];
    for (final probe in entry.probes) {
      probeReports.add(await _probe(entry, provider, probe));
    }
    final statuses = probeReports.map((p) => p['status'] as String).toSet();
    final status = statuses.length == 1 && statuses.single == 'healthy'
        ? 'healthy'
        : statuses.contains('changed_schema')
        ? 'changed_schema'
        : statuses.contains('identity_mismatch')
        ? 'identity_mismatch'
        : statuses.contains('not_configured')
        ? 'not_configured'
        : statuses.contains('blocked')
        ? 'blocked'
        : statuses.contains('unavailable')
        ? 'unavailable'
        : statuses.contains('transient_error')
        ? 'transient_error'
        : statuses.contains('coverage_gap')
        ? 'coverage_gap'
        : 'unavailable';
    return {...base, 'status': status, 'probes': probeReports};
  }

  Future<JsonMap> _probe(
    SourceCatalogEntry entry,
    LyricsProvider provider,
    JsonMap probe,
  ) async {
    final cancel = CancellationToken();
    final timer = Timer(const Duration(seconds: 40), cancel.cancel);
    try {
      return await _runProbe(entry, provider, probe, cancel).timeout(
        const Duration(seconds: 45),
        onTimeout: () => {
          'id': probe['id']?.toString() ?? 'unknown',
          'status': 'transient_error',
          'reason': 'probe_timeout',
        },
      );
    } finally {
      timer.cancel();
    }
  }

  Future<JsonMap> _runProbe(
    SourceCatalogEntry entry,
    LyricsProvider provider,
    JsonMap probe,
    CancellationToken cancel,
  ) async {
    final id = probe['id']?.toString() ?? 'unknown';
    try {
      final expectedTitle = _normalized(probe['expectedTitle']?.toString());
      final expectedArtist = _normalized(probe['expectedArtist']?.toString());
      final expectedAlbum = _normalized(probe['expectedAlbum']?.toString());
      final expectedDuration =
          (probe['expectedDurationSeconds'] as num?)?.toDouble();
      SongCandidate selected;
      final candidateJson = probe['candidate'];
      if (candidateJson is Map) {
        selected = SongCandidate.fromJson(
          Map<String, dynamic>.from(candidateJson),
        );
      } else {
        final query = probe['query'];
        if (query is! String ||
            query.trim().isEmpty ||
            expectedTitle == null && expectedArtist == null) {
          return {
            'id': id,
            'status': 'coverage_gap',
            'reason': 'probe_identity_missing',
          };
        }
        final candidates = await provider.search(query, cancel: cancel);
        final matches = candidates
            .where(
              (candidate) =>
                  candidate.providerId == entry.id &&
                  (expectedTitle == null ||
                      _normalized(candidate.title) == expectedTitle) &&
                  (expectedArtist == null ||
                      _normalized(candidate.artist) == expectedArtist) &&
                  (expectedAlbum == null ||
                      _normalized(candidate.album) == expectedAlbum) &&
                  (expectedDuration == null ||
                      _durationMatches(candidate.durationSeconds, expectedDuration)),
            )
            .toList();
        if (matches.length != 1) {
          return {
            'id': id,
            'status': matches.isEmpty ? 'identity_mismatch' : 'coverage_gap',
            'reason': matches.isEmpty
                ? 'expected_candidate_not_found'
                : 'ambiguous_candidate',
          };
        }
        selected = matches.single;
      }
      if (selected.providerId != entry.id) {
        return {
          'id': id,
          'status': 'identity_mismatch',
          'reason': 'candidate_provider_mismatch',
        };
      }
      if (expectedTitle != null &&
              _normalized(selected.title) != expectedTitle ||
          expectedArtist != null &&
              _normalized(selected.artist) != expectedArtist ||
          expectedAlbum != null &&
              _normalized(selected.album) != expectedAlbum ||
          expectedDuration != null &&
              !_durationMatches(selected.durationSeconds, expectedDuration)) {
        return {
          'id': id,
          'status': 'identity_mismatch',
          'reason': 'candidate_identity_mismatch',
        };
      }
      final result = await provider.resolve(selected, cancel: cancel);
      final shapeError = _shapeError(result);
      if (shapeError != null) {
        return {'id': id, 'status': 'changed_schema', 'reason': shapeError};
      }
      if (result.id != selected.identity ||
          _normalized(result.candidate.title) != _normalized(selected.title) ||
          _normalized(result.candidate.artist) !=
              _normalized(selected.artist) ||
          result.matchKind == MatchKind.rejected) {
        return {
          'id': id,
          'status': 'identity_mismatch',
          'reason': 'resolved_candidate_changed',
        };
      }
      if (expectedTitle != null &&
              _normalized(result.candidate.title) != expectedTitle ||
          expectedArtist != null &&
              _normalized(result.candidate.artist) != expectedArtist ||
          expectedAlbum != null &&
              _normalized(result.candidate.album) != expectedAlbum ||
          expectedDuration != null &&
              !_durationMatches(result.candidate.durationSeconds, expectedDuration)) {
        return {
          'id': id,
          'status': 'identity_mismatch',
          'reason': 'resolved_identity_mismatch',
        };
      }
      final required = (probe['requiredFields'] as List? ?? const [])
          .cast<String>()
          .toSet();
      final missing = <String>[];
      if ((required.contains('body') ||
              entry.capabilities.contains('lyrics')) &&
          result.body.trim().isEmpty) {
        missing.add('body');
      }
      if (required.contains('metadata') && result.metadata.isEmpty) {
        missing.add('metadata');
      }
      if (required.contains('timing') && result.timingTracks.isEmpty) {
        missing.add('timing');
      }
      if (required.contains('timing') &&
          result.timingTracks.any((track) => track.raw == null)) {
        missing.add('timingRaw');
      }
      if (required.contains('lineTiming') &&
          !result.timingTracks.any(
            (track) => {'line', 'word'}.contains(track.granularity),
          )) {
        missing.add('lineTiming');
      }
      if (required.contains('wordTiming') &&
          !result.timingTracks.any((track) => track.granularity == 'word')) {
        missing.add('wordTiming');
      }
      if (required.contains('chords') && !result.hasChords) {
        missing.add('chords');
      }
      if (missing.isNotEmpty) {
        return {
          'id': id,
          'status': 'changed_schema',
          'reason': 'required_fields_missing',
          'missingFields': missing,
        };
      }
      final absentMetadataPaths =
          (probe['requiredMetadataFields'] as List? ?? const [])
              .cast<String>()
              .where((path) => !_hasMetadataPath(result.metadata, path))
              .toList();
      if (absentMetadataPaths.isNotEmpty) {
        return {
          'id': id,
          'status': 'changed_schema',
          'reason': 'required_metadata_fields_missing',
          'missingMetadataFields': absentMetadataPaths,
        };
      }
      return {
        'id': id,
        'status': 'healthy',
        'candidateId': _reportedCandidateId(
          result.candidate.providerId,
          result.candidate.id,
        ),
        'providerId': result.candidate.providerId,
        'bodyCharacters': result.body.length,
        'metadataFields': result.metadata.keys.toList()..sort(),
        'timingTrackCount': result.timingTracks.length,
        'timingGranularities': result.timingTracks
            .map((track) => track.granularity)
            .toSet()
            .toList()
          ..sort(),
        'timingRawRetained': result.timingTracks.every(
          (track) => track.raw == null || track.toJson()['raw'] == track.raw,
        ),
        'hasChords': result.hasChords,
      };
    } catch (error) {
      return {'id': id, ..._classify(error)};
    }
  }

  String? _shapeError(SourceResult result) {
    if (result.candidate.id.isEmpty || result.candidate.title.trim().isEmpty) {
      return 'candidate_shape_invalid';
    }
    try {
      final encoded = jsonEncode(result.toJson());
      final decoded = SourceResult.fromJson(jsonDecode(encoded) as JsonMap);
      if (decoded.candidate.providerId != result.candidate.providerId ||
          decoded.candidate.id != result.candidate.id) {
        return 'candidate_identity_roundtrip_changed';
      }
      if (decoded.candidate.title != result.candidate.title ||
          decoded.candidate.artist != result.candidate.artist) {
        return 'candidate_labels_roundtrip_changed';
      }
      if (decoded.body != result.body) return 'body_roundtrip_changed';
      if (decoded.metadata.length != result.metadata.length ||
          !decoded.metadata.keys.toSet().containsAll(result.metadata.keys)) {
        return 'metadata_roundtrip_changed';
      }
      if (decoded.timingTracks.length != result.timingTracks.length) {
        return 'timing_count_roundtrip_changed';
      }
      for (var i = 0; i < result.timingTracks.length; i++) {
        final actual = result.timingTracks[i];
        final restored = decoded.timingTracks[i];
        if (restored.raw != actual.raw) {
          return 'timing_raw_lost';
        }
        if (restored.format != actual.format ||
            restored.granularity != actual.granularity ||
            restored.sourceLyrics != actual.sourceLyrics ||
            restored.cues.length != actual.cues.length) {
          return 'timing_shape_changed';
        }
      }
    } catch (_) {
      return 'result_shape_invalid';
    }
    return null;
  }

  Map<String, dynamic> _classify(Object error) {
    if (error is ProviderException) {
      final code = error.code;
      if (code == 'not_configured') {
        return {'status': 'not_configured', 'reason': code};
      }
      if (code == 'identity_mismatch') {
        return {'status': 'identity_mismatch', 'reason': code};
      }
      if (code == 'file_import_required') {
        return {'status': 'import_only', 'reason': code};
      }
      if (code == 'blocked' || code == 'access_denied' || code == 'forbidden') {
        return {'status': 'blocked', 'reason': code};
      }
      if (code == 'unavailable' || code == 'not_found' || code == 'gone') {
        return {'status': 'unavailable', 'reason': code};
      }
      if (code == 'invalid_response' ||
          code == 'extraction_failed' ||
          code == 'schema_changed') {
        return {'status': 'changed_schema', 'reason': code};
      }
      if (code == 'cancelled' ||
          code == 'rate_limited' ||
          code == 'timeout' ||
          code == 'network' ||
          code == 'network_error' ||
          code == 'provider_busy' ||
          code == 'transient') {
        return {'status': 'transient_error', 'reason': code};
      }
      return {'status': 'unavailable', 'reason': code};
    }
    return {'status': 'transient_error', 'reason': 'network_or_runtime_error'};
  }

  String? _normalized(String? value) =>
      value?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  bool _durationMatches(double? actual, double expected) =>
      actual != null && (actual - expected).abs() <= 0.5;

  bool _hasMetadataPath(JsonMap metadata, String path) {
    dynamic value = metadata;
    for (final segment in path.split('.')) {
      if (value is Map && value.containsKey(segment)) {
        value = value[segment];
      } else if (value is List) {
        final index = int.tryParse(segment);
        if (index == null) return false;
        if (index < 0 || index >= value.length) return false;
        value = value[index];
      } else {
        return false;
      }
      if (value == null || value is String && value.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  String _reportedCandidateId(String providerId, String id) {
    final safe = switch (providerId) {
      'genius' || 'lrclib' || 'lyricsovh' || 'unison' =>
        RegExp(r'^\d{1,32}$').hasMatch(id),
      'musicbrainz' => RegExp(r'^[a-f0-9-]{36}$').hasMatch(id),
      'wikidata' => RegExp(r'^Q\d{1,20}$').hasMatch(id),
      'songsterr' || 'ultimateguitar' || 'chordie' || 'seanmcgrathmusic' =>
        id.length <= 80 && RegExp(r'^/[A-Za-z0-9._~/-]+$').hasMatch(id),
      'wikimediacommons' =>
        id.length <= 100 && RegExp(r'^File:[A-Za-z0-9 _.,()\x27-]+$').hasMatch(id),
      _ => false,
    };
    if (safe) return id;
    final digest = sha256.convert(utf8.encode('$providerId:$id')).toString();
    return 'sha256:${digest.substring(0, 16)}';
  }
}
