import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../domain/edition_identity.dart';
import '../../domain/models.dart' show JsonMap;
import '../provider.dart';
import '../core/recording_context.dart';
import 'common.dart' show normalized;

/// Recording-ID enrichment. Uploaded analysis is evidence about a submission,
/// not verified musical truth, recording alignment, or an authoritative offset.
class AcousticBrainzProvider
    implements
        LyricsProvider,
        ContextualLyricsSearch,
        RecordingContextReceiver {
  AcousticBrainzProvider(
    this.transport, {
    DateTime Function()? clock,
    this.requestInterval = const Duration(milliseconds: 1100),
  }) : _clock = clock ?? DateTime.now;

  final ProviderTransport transport;
  final DateTime Function() _clock;
  final Duration requestInterval;
  final _cache = <String, _ArchiveRecording>{};
  DateTime _nextRequest = DateTime.fromMillisecondsSinceEpoch(0);
  static const _host = 'acousticbrainz.org';
  static const _limit = 512 * 1024;
  static const _features =
      'metadata.tags;rhythm.bpm;tonal.key_key;tonal.key_scale;tonal.key_strength';
  static final _mbid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  final definition = const ProviderDefinition(
    id: 'acousticbrainz',
    name: 'AcousticBrainz',
    capabilities: {'metadata'},
    accessMode: 'publicApi',
    enabledByDefault: false,
    website: 'https://acousticbrainz.org/',
  );

  static String? _recordingId(String? value) =>
      value != null && _mbid.hasMatch(value) ? value.toLowerCase() : null;

  @override
  String get requiredRecordingIdNamespace => 'musicbrainz';

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    // There is no documented title search. Do not launch another catalog's
    // search, invent an MBID, or interpret a source URL as an API target.
    final id = _recordingId(query.trim());
    if (id == null) return [];
    return [_candidate(await _load(id, cancel))];
  }

  @override
  bool canReuseSearchForSelection(
    SongCandidate selection,
    List<SongCandidate> candidates,
  ) => false;

  @override
  Future<List<SongCandidate>> searchForSelection(
    SongCandidate selection, {
    required String fallbackQuery,
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final id = _selectionId(selection);
    if (id == null) return [];
    _checkSelectionText(selection);
    final recording = await _load(id, cancel);
    _validateContext(selection, recording);
    return [_candidate(recording)];
  }

  String? _selectionId(SongCandidate candidate) {
    final id = _recordingId(candidate.recordingIds['musicbrainz']);
    if (candidate.recordingIds.containsKey('musicbrainz') && id == null) {
      throw const ProviderException('invalid_selection');
    }
    if (candidate.providerId != definition.id) return id;
    final own = _recordingId(candidate.id);
    if (own == null || id != null && own != id) {
      throw const ProviderException('invalid_selection');
    }
    if (candidate.url != null && candidate.url != 'https://$_host/$own') {
      throw const ProviderException('invalid_selection');
    }
    return own;
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final id = _selectionId(candidate);
    if (id == null) {
      throw const ProviderException(
        'unavailable',
        'recording_context_required',
      );
    }
    _checkSelectionText(candidate);
    final recording = await _load(id, cancel);
    _validateContext(candidate, recording);
    cancel?.throwIfCancelled();
    final resolved = _candidate(recording);
    return SourceResult(
      candidate: resolved,
      body: '',
      metadata: resolved.metadata,
      retrievedAt: recording.at,
      attribution: 'AcousticBrainz contributors — https://$_host/$id',
      extra: {
        'parserVersion': 'acousticbrainz-native-candidate-1',
        'sourceDocumentId': 'acousticbrainz:recording:$id',
        'metadataOnly': true,
        'rights': {
          'source': definition.id,
          'sourceId': id,
          'sourceUrl': resolved.url,
          'license': 'CC0',
          'evidenceUrl': 'https://acousticbrainz.org/',
          'scope': 'publisher analysis corpus; no audio, lyrics or artwork',
        },
        'originalPayloads': [
          _payload('submissionCount', recording.countBytes),
          _payload('sampledLowLevel', recording.analysisBytes),
        ],
      },
    );
  }

  SongCandidate _candidate(_ArchiveRecording recording) => SongCandidate(
    providerId: definition.id,
    id: recording.id,
    title: recording.title,
    artist: recording.artist,
    url: 'https://$_host/${recording.id}',
    // Uploaded album and file length stay submission facts, not donated release
    // packaging/duration. Supplied context is still checked against both.
    recordingIds: {'musicbrainz': recording.id},
    metadata: {
      'identityScope': 'recording',
      'metadataOnly': true,
      'recordingEvidence': 'publisherSubmittedFileTags',
      'acousticbrainz': {
        'recordingMbid': recording.id,
        'submissionCount': recording.count,
        'sampledOffsets': List<int>.generate(
          recording.samples.length,
          (i) => i,
        ),
        'sampleLimit': 2,
        'allSubmissionsRetrieved': recording.count == recording.samples.length,
        'selectionPolicy': 'bounded first two submission offsets; no authority',
        'musicalAccuracy': 'unverified',
        'audioAlignment': 'unverified',
        'samples': _copy(recording.samples),
      },
    },
  );

  void _validateContext(SongCandidate selection, _ArchiveRecording recording) {
    _checkSelectionText(selection);
    final actual = _candidate(recording);
    if (normalized(selection.title) != normalized(actual.title) ||
        normalized(selection.artist) != normalized(actual.artist) ||
        !explicitEditionsCompatible(selection, actual)) {
      throw const ProviderException('identity_mismatch');
    }
    for (final sample in recording.samples) {
      final album = selection.album;
      final tags = sample['tags'] as JsonMap;
      if (album != null && album.trim().isNotEmpty) {
        final found = _singleTag(tags, 'album', required: false);
        if (found == null || normalized(album) != normalized(found)) {
          throw const ProviderException('identity_mismatch');
        }
      }
      final duration = selection.durationSeconds;
      if (duration != null &&
          (!duration.isFinite ||
              duration <= 0 ||
              (duration - (sample['audioLengthSeconds'] as num)).abs() > 2)) {
        throw const ProviderException('identity_mismatch');
      }
    }
  }

  Future<_ArchiveRecording> _load(String id, CancellationToken? cancel) async {
    cancel?.throwIfCancelled();
    final cached = _cache[id];
    final now = _clock().toUtc();
    if (cached != null &&
        !now.isBefore(cached.at) &&
        now.difference(cached.at) < const Duration(minutes: 15)) {
      return cached;
    }
    final countBytes = await _get('/api/v1/count', {
      'recording_ids': id,
    }, cancel);
    final counts = _object(_decode(countBytes));
    final countRow = counts[id];
    if (countRow == null) throw const ProviderException('unavailable');
    final count = _object(countRow)['count'];
    if (count is! int || count < 1 || count > 1000000) _invalid();
    final offsets = List<int>.generate(math.min(count, 2), (i) => i);
    final analysisBytes = await _get('/api/v1/low-level', {
      'recording_ids': offsets.map((offset) => '$id:$offset').join(';'),
      'features': _features,
    }, cancel);
    final response = _object(_decode(analysisBytes));
    final raw = response[id];
    if (raw == null) throw const ProviderException('unavailable');
    final documents = _object(raw);
    if (documents.length != offsets.length ||
        offsets.any((offset) => !documents.containsKey('$offset'))) {
      _invalid();
    }
    final samples = <JsonMap>[
      for (final offset in offsets) _sample(id, offset, documents['$offset']),
    ];
    final firstTags = samples.first['tags'] as JsonMap;
    final title = _singleTag(firstTags, 'title')!;
    final artist = _singleTag(firstTags, 'artist')!;
    for (final sample in samples) {
      final tags = sample['tags'] as JsonMap;
      if (normalized(_singleTag(tags, 'title')!) != normalized(title) ||
          normalized(_singleTag(tags, 'artist')!) != normalized(artist)) {
        throw const ProviderException('identity_mismatch');
      }
    }
    cancel?.throwIfCancelled();
    final result = _ArchiveRecording(
      id,
      title,
      artist,
      count,
      samples,
      countBytes,
      analysisBytes,
      _clock().toUtc(),
    );
    _cache[id] = result;
    if (_cache.length > 32) _cache.remove(_cache.keys.first);
    return result;
  }

  Future<Uint8List> _get(
    String path,
    Map<String, String> query,
    CancellationToken? cancel,
  ) async {
    cancel?.throwIfCancelled();
    final now = DateTime.now();
    final reserved = _nextRequest.isAfter(now) ? _nextRequest : now;
    var wait = reserved.difference(now);
    if (requestInterval.isNegative ||
        requestInterval > const Duration(seconds: 5) ||
        wait > const Duration(seconds: 15)) {
      throw const ProviderException('provider_busy');
    }
    _nextRequest = reserved.add(requestInterval);
    // Bounded cancellation polling avoids retaining callbacks on a long-lived
    // token after each completed pacing wait. Canceled reservations stay spaced.
    while (wait > Duration.zero) {
      final slice = Duration(
        milliseconds: math.min(wait.inMilliseconds + 1, 50),
      );
      await Future<void>.delayed(slice);
      cancel?.throwIfCancelled();
      wait -= slice;
    }
    return transport.getBytes(
      Uri.https(_host, path, query),
      cancel: cancel,
      maxBytes: _limit,
      allowedHosts: {_host},
    );
  }
}

JsonMap _payload(String role, List<int> bytes) => {
  'role': role,
  'contentType': 'application/json',
  'encoding': 'utf-8',
  'base64': base64Encode(bytes),
  'sha256': sha256.convert(bytes).toString(),
  'httpBodyBytesExact': true,
};

void _checkSelectionText(SongCandidate selection) {
  if (selection.title.trim().isEmpty ||
      selection.artist.trim().isEmpty ||
      selection.title.length > 500 ||
      selection.artist.length > 500) {
    throw const ProviderException('invalid_selection');
  }
}

JsonMap _sample(String id, int offset, Object? value) {
  final document = _object(value);
  final metadata = _object(document['metadata']);
  final tags = _object(metadata['tags']);
  if (tags.length > 128) _invalid();
  for (final entry in tags.entries) {
    // The retained API documents encode file_name as a scalar, unlike the
    // list-valued identity/credit tags. Retain it without interpreting a path.
    if (entry.key == 'file_name' && entry.value is String) {
      if ((entry.value as String).length > 4096) _invalid();
      continue;
    }
    if (entry.key.length > 128 ||
        entry.value is! List ||
        (entry.value as List).length > 64 ||
        (entry.value as List).any((v) => v is! String || v.length > 4096)) {
      _invalid();
    }
  }
  if (_singleTag(tags, 'musicbrainz_recordingid')?.toLowerCase() != id) {
    throw const ProviderException('identity_mismatch');
  }
  _singleTag(tags, 'title');
  _singleTag(tags, 'artist');
  final length = _number(
    _object(metadata['audio_properties'])['length'],
    86400,
  );
  final version = _object(metadata['version']);
  if (version.isEmpty ||
      version.length > 32 ||
      version.values.any((v) => v is! String || v.length > 512)) {
    _invalid();
  }
  final rhythm = _object(document['rhythm']);
  final tonal = _object(document['tonal']);
  final bpm = _number(rhythm['bpm'], 1000);
  final key = tonal['key_key'];
  final scale = tonal['key_scale'];
  final strength = tonal['key_strength'];
  if (!const {
        'A',
        'A#',
        'Bb',
        'B',
        'C',
        'C#',
        'Db',
        'D',
        'D#',
        'Eb',
        'E',
        'F',
        'F#',
        'Gb',
        'G',
        'G#',
        'Ab',
      }.contains(key) ||
      !const {'major', 'minor'}.contains(scale) ||
      strength is! num ||
      !strength.isFinite ||
      strength < 0 ||
      strength > 1) {
    _invalid();
  }
  return {
    'submissionOffset': offset,
    'tags': _copy(tags),
    'audioLengthSeconds': length,
    'extractorVersion': _copy(version),
    'estimatedBpm': bpm,
    'estimatedKey': {'tonic': key, 'scale': scale, 'strength': strength},
    'estimateStatus': 'unverified',
  };
}

String? _singleTag(JsonMap tags, String name, {bool required = true}) {
  final value = tags[name];
  if (!required && value == null) return null;
  if (value is! List ||
      value.length != 1 ||
      value.single is! String ||
      (value.single as String).trim().isEmpty ||
      (value.single as String).length > 500) {
    _invalid();
  }
  return value.single as String;
}

num _number(Object? value, num max) {
  if (value is! num || !value.isFinite || value <= 0 || value > max) _invalid();
  return value;
}

JsonMap _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) _invalid();
  return Map<String, dynamic>.from(value);
}

Object? _decode(List<int> bytes) {
  try {
    return jsonDecode(utf8.decode(bytes));
  } on FormatException {
    _invalid();
  }
}

dynamic _copy(Object? value) => jsonDecode(jsonEncode(value));
Never _invalid() => throw const ProviderException('invalid_response');

class _ArchiveRecording {
  _ArchiveRecording(
    this.id,
    this.title,
    this.artist,
    this.count,
    this.samples,
    this.countBytes,
    this.analysisBytes,
    this.at,
  );
  final String id, title, artist;
  final int count;
  final List<JsonMap> samples;
  final Uint8List countBytes, analysisBytes;
  final DateTime at;
}
