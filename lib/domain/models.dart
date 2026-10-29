import 'dart:convert';
import 'dart:math';
import 'arrangement.dart' show containsChords;

typedef JsonMap = Map<String, dynamic>;

String newId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

enum MatchKind { sameRecording, sameSong, unverified, rejected }

enum TimingStatus {
  usable,
  unverified,
  incompatible,
  stale,
  unsupported,
  invalid,
}

class ProviderDefinition {
  final String id, name, accessMode;
  final Set<String> capabilities;
  final bool enabledByDefault;

  /// Whether required app configuration is available; never contains credentials.
  final bool configured;
  final String? description, website;
  const ProviderDefinition({
    required this.id,
    required this.name,
    this.capabilities = const {},
    this.accessMode = 'public',
    this.enabledByDefault = true,
    this.configured = true,
    this.description,
    this.website,
  });
}

class SongCandidate {
  final String providerId, id, title, artist;
  final String? album, url;
  final double? durationSeconds;
  final JsonMap metadata;
  final Map<String, String> recordingIds;
  final JsonMap extra;
  const SongCandidate({
    required this.providerId,
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.durationSeconds,
    this.url,
    this.metadata = const {},
    this.recordingIds = const {},
    this.extra = const {},
  });
  String get identity => '$providerId:$id';
  String? get artworkUrl => metadata['artworkUrl'] as String?;
  bool get hasPendingMatchCheck =>
      metadata['pendingMatchCheck'] == true ||
      extra['pendingMatchCheck'] == true;
  JsonMap toJson() => {
    ...extra,
    'providerId': providerId,
    'id': id,
    'title': title,
    'artist': artist,
    if (album != null) 'album': album,
    if (url != null) 'url': url,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (metadata.isNotEmpty) 'metadata': metadata,
    if (recordingIds.isNotEmpty) 'recordingIds': recordingIds,
  };
  factory SongCandidate.fromJson(JsonMap j) => SongCandidate(
    providerId: j['providerId'] as String,
    id: j['id'] as String,
    title: j['title'] as String,
    artist: j['artist'] as String,
    album: j['album'] as String?,
    url: j['url'] as String?,
    durationSeconds: (j['durationSeconds'] as num?)?.toDouble(),
    metadata: jsonMap(j['metadata']),
    recordingIds: stringMap(j['recordingIds']),
    extra: {...j}
      ..removeWhere(
        (k, _) => {
          'providerId',
          'id',
          'title',
          'artist',
          'album',
          'url',
          'durationSeconds',
          'metadata',
          'recordingIds',
        }.contains(k),
      ),
  );
}

class TimingCue {
  final String id, occurrenceId, text;
  final int startUs;
  final int? endUs, graphemeStart, graphemeEnd;
  final String? voice, originalBegin, originalEnd;
  final JsonMap extra;
  const TimingCue({
    required this.id,
    required this.occurrenceId,
    required this.text,
    required this.startUs,
    this.endUs,
    this.graphemeStart,
    this.graphemeEnd,
    this.voice,
    this.originalBegin,
    this.originalEnd,
    this.extra = const {},
  });
  JsonMap toJson() => {
    ...extra,
    'id': id,
    'occurrenceId': occurrenceId,
    'text': text,
    'startUs': startUs,
    if (endUs != null) 'endUs': endUs,
    if (graphemeStart != null) 'graphemeStart': graphemeStart,
    if (graphemeEnd != null) 'graphemeEnd': graphemeEnd,
    if (voice != null) 'voice': voice,
    if (originalBegin != null) 'originalBegin': originalBegin,
    if (originalEnd != null) 'originalEnd': originalEnd,
  };
  factory TimingCue.fromJson(JsonMap j) => TimingCue(
    id: j['id'] as String,
    occurrenceId: j['occurrenceId'] as String,
    text: j['text'] as String,
    startUs: j['startUs'] as int,
    endUs: j['endUs'] as int?,
    graphemeStart: j['graphemeStart'] as int?,
    graphemeEnd: j['graphemeEnd'] as int?,
    voice: j['voice'] as String?,
    originalBegin: j['originalBegin'] as String?,
    originalEnd: j['originalEnd'] as String?,
    extra: {...j}
      ..removeWhere(
        (k, _) => {
          'id',
          'occurrenceId',
          'text',
          'startUs',
          'endUs',
          'graphemeStart',
          'graphemeEnd',
          'voice',
          'originalBegin',
          'originalEnd',
        }.contains(k),
      ),
  );
}

class TimingTrack {
  final String id, sourceDocumentId, sourceLyrics, format;
  final String? raw, recordingId, language, voice, lyricHash;
  final List<TimingCue> cues;
  final TimingStatus status;
  final String origin, granularity;
  final JsonMap extra;
  const TimingTrack({
    required this.id,
    required this.sourceDocumentId,
    required this.sourceLyrics,
    required this.format,
    this.raw,
    this.recordingId,
    this.language,
    this.voice,
    this.lyricHash,
    this.cues = const [],
    this.status = TimingStatus.unverified,
    this.origin = 'provider',
    this.granularity = 'line',
    this.extra = const {},
  });
  TimingTrack copyWith({
    TimingStatus? status,
    String? lyricHash,
    String? origin,
    JsonMap? extra,
    List<TimingCue>? cues,
  }) => TimingTrack(
    id: id,
    sourceDocumentId: sourceDocumentId,
    sourceLyrics: sourceLyrics,
    format: format,
    raw: raw,
    recordingId: recordingId,
    language: language,
    voice: voice,
    lyricHash: lyricHash ?? this.lyricHash,
    cues: cues ?? this.cues,
    status: status ?? this.status,
    origin: origin ?? this.origin,
    granularity: granularity,
    extra: extra ?? this.extra,
  );
  JsonMap toJson() => {
    ...extra,
    'id': id,
    'sourceDocumentId': sourceDocumentId,
    'sourceLyrics': sourceLyrics,
    'format': format,
    if (raw != null) 'raw': raw,
    if (recordingId != null) 'recordingId': recordingId,
    if (language != null) 'language': language,
    if (voice != null) 'voice': voice,
    if (lyricHash != null) 'lyricHash': lyricHash,
    'cues': cues.map((c) => c.toJson()).toList(),
    'status': status.name,
    'origin': origin,
    'granularity': granularity,
  };
  factory TimingTrack.fromJson(JsonMap j) => TimingTrack(
    id: j['id'] as String,
    sourceDocumentId: j['sourceDocumentId'] as String,
    sourceLyrics: j['sourceLyrics'] as String,
    format: j['format'] as String,
    raw: j['raw'] as String?,
    recordingId: j['recordingId'] as String?,
    language: j['language'] as String?,
    voice: j['voice'] as String?,
    lyricHash: j['lyricHash'] as String?,
    cues: (j['cues'] as List? ?? [])
        .map((c) => TimingCue.fromJson(jsonMap(c)))
        .toList(),
    status: TimingStatus.values.byName(j['status'] as String? ?? 'unverified'),
    origin: j['origin'] as String? ?? 'provider',
    granularity: j['granularity'] as String? ?? 'line',
    extra: {...j}
      ..removeWhere(
        (k, _) => {
          'id',
          'sourceDocumentId',
          'sourceLyrics',
          'format',
          'raw',
          'recordingId',
          'language',
          'voice',
          'lyricHash',
          'cues',
          'status',
          'origin',
          'granularity',
        }.contains(k),
      ),
  );
}

class SourceResult {
  final SongCandidate candidate;
  final String body;
  final JsonMap metadata;
  final List<TimingTrack> timingTracks;
  final MatchKind matchKind;
  final String? attribution, matchReason;
  final String? arrangementId;
  final DateTime? retrievedAt;
  final JsonMap extra;
  const SourceResult({
    required this.candidate,
    required this.body,
    this.metadata = const {},
    this.timingTracks = const [],
    this.matchKind = MatchKind.unverified,
    this.attribution,
    this.matchReason,
    this.arrangementId,
    this.retrievedAt,
    this.extra = const {},
  });
  String get id => arrangementId == null
      ? candidate.identity
      : '${candidate.identity}#arrangement=$arrangementId';
  bool get hasChords => containsChords(body);
  bool get hasPendingMatchCheck =>
      candidate.hasPendingMatchCheck ||
      metadata['pendingMatchCheck'] == true ||
      extra['pendingMatchCheck'] == true;
  SourceResult copyWith({List<TimingTrack>? timingTracks, JsonMap? extra}) =>
      SourceResult(
        candidate: candidate,
        body: body,
        metadata: metadata,
        timingTracks: timingTracks ?? this.timingTracks,
        matchKind: matchKind,
        attribution: attribution,
        matchReason: matchReason,
        arrangementId: arrangementId,
        retrievedAt: retrievedAt,
        extra: extra ?? this.extra,
      );
  JsonMap toJson() => {
    ...extra,
    'candidate': candidate.toJson(),
    'body': body,
    'metadata': metadata,
    'timingTracks': timingTracks.map((t) => t.toJson()).toList(),
    'matchKind': matchKind.name,
    if (arrangementId != null) 'arrangementId': arrangementId,
    if (attribution != null) 'attribution': attribution,
    if (matchReason != null) 'matchReason': matchReason,
    if (retrievedAt != null)
      'retrievedAt': retrievedAt!.toUtc().toIso8601String(),
  };
  factory SourceResult.fromJson(JsonMap j) => SourceResult(
    candidate: SongCandidate.fromJson(jsonMap(j['candidate'])),
    body: j['body'] as String,
    metadata: jsonMap(j['metadata']),
    timingTracks: (j['timingTracks'] as List? ?? [])
        .map((t) => TimingTrack.fromJson(jsonMap(t)))
        .toList(),
    matchKind: MatchKind.values.byName(
      j['matchKind'] as String? ?? 'unverified',
    ),
    attribution: j['attribution'] as String?,
    matchReason: j['matchReason'] as String?,
    arrangementId: j['arrangementId'] as String?,
    retrievedAt: j['retrievedAt'] == null
        ? null
        : DateTime.parse(j['retrievedAt'] as String),
    extra: {...j}
      ..removeWhere(
        (k, _) => {
          'candidate',
          'body',
          'metadata',
          'timingTracks',
          'matchKind',
          'attribution',
          'matchReason',
          'arrangementId',
          'retrievedAt',
        }.contains(k),
      ),
  );
}

class SongDocument {
  final String id, title, artist, body;
  final JsonMap metadata;
  final List<SourceResult> sources;
  final List<TimingTrack> timingTracks;
  final bool favorite;
  final DateTime createdAt, updatedAt;
  final SongCandidate? selectedRecording;
  final String? activeTimingTrackId;
  final int revision;
  final JsonMap extra;
  final List<String> preservedExtensions;
  final String? extensionError;
  SongDocument({
    required this.id,
    required this.title,
    required this.artist,
    required this.body,
    this.metadata = const {},
    this.sources = const [],
    this.timingTracks = const [],
    this.favorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.selectedRecording,
    this.activeTimingTrackId,
    this.revision = 1,
    this.extra = const {},
    this.preservedExtensions = const [],
    this.extensionError,
  }) : createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? DateTime.now().toUtc();
  bool get hasChords => containsChords(body);
  SongDocument copyWith({
    String? id,
    String? title,
    String? artist,
    String? body,
    JsonMap? metadata,
    List<SourceResult>? sources,
    List<TimingTrack>? timingTracks,
    bool? favorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? revision,
    JsonMap? extra,
    String? activeTimingTrackId,
    bool clearActiveTiming = false,
  }) => SongDocument(
    id: id ?? this.id,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    body: body ?? this.body,
    metadata: metadata ?? this.metadata,
    sources: sources ?? this.sources,
    timingTracks: timingTracks ?? this.timingTracks,
    favorite: favorite ?? this.favorite,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? DateTime.now().toUtc(),
    selectedRecording: selectedRecording,
    activeTimingTrackId: clearActiveTiming
        ? null
        : activeTimingTrackId ?? this.activeTimingTrackId,
    revision: revision ?? this.revision + 1,
    extra: extra ?? this.extra,
    preservedExtensions: preservedExtensions,
    extensionError: extensionError,
  );

  JsonMap toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'body': body,
    'metadata': metadata,
    'sources': sources.map((source) => source.toJson()).toList(),
    'timingTracks': timingTracks.map((track) => track.toJson()).toList(),
    'favorite': favorite,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'selectedRecording': selectedRecording?.toJson(),
    'activeTimingTrackId': activeTimingTrackId,
    'revision': revision,
    'extra': extra,
    'preservedExtensions': preservedExtensions,
    'extensionError': extensionError,
  };

  factory SongDocument.fromJson(JsonMap json) => SongDocument(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    body: json['body'] as String,
    metadata: jsonMap(json['metadata']),
    sources: (json['sources'] as List? ?? [])
        .map((source) => SourceResult.fromJson(jsonMap(source)))
        .toList(),
    timingTracks: (json['timingTracks'] as List? ?? [])
        .map((track) => TimingTrack.fromJson(jsonMap(track)))
        .toList(),
    favorite: json['favorite'] as bool? ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    selectedRecording: json['selectedRecording'] == null
        ? null
        : SongCandidate.fromJson(jsonMap(json['selectedRecording'])),
    activeTimingTrackId: json['activeTimingTrackId'] as String?,
    revision: json['revision'] as int? ?? 1,
    extra: jsonMap(json['extra']),
    preservedExtensions: (json['preservedExtensions'] as List? ?? [])
        .map((line) => line as String)
        .toList(),
    extensionError: json['extensionError'] as String?,
  );
}

class SetlistEntry {
  final String id, songId;
  final JsonMap overrides;
  const SetlistEntry({
    required this.id,
    required this.songId,
    this.overrides = const {},
  });
  JsonMap toJson() => {
    'id': id,
    'songId': songId,
    if (overrides.isNotEmpty) 'overrides': overrides,
  };
  factory SetlistEntry.fromJson(JsonMap json) => SetlistEntry(
    id: json['id'] as String,
    songId: json['songId'] as String,
    overrides: jsonMap(json['overrides']),
  );
}

class SetlistDocument {
  final String id, name, notes;
  final bool favorite;
  final List<SetlistEntry> entries;
  final DateTime createdAt, updatedAt;
  SetlistDocument({
    required this.id,
    required this.name,
    this.notes = '',
    this.favorite = false,
    this.entries = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? DateTime.now().toUtc();
  SetlistDocument copyWith({
    String? id,
    String? name,
    String? notes,
    bool? favorite,
    List<SetlistEntry>? entries,
  }) => SetlistDocument(
    id: id ?? this.id,
    name: name ?? this.name,
    notes: notes ?? this.notes,
    favorite: favorite ?? this.favorite,
    entries: entries ?? this.entries,
    createdAt: createdAt,
  );
  JsonMap toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'favorite': favorite,
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
  factory SetlistDocument.fromJson(JsonMap json) => SetlistDocument(
    id: json['id'] as String,
    name: json['name'] as String,
    notes: json['notes'] as String? ?? '',
    favorite: json['favorite'] as bool? ?? false,
    entries: (json['entries'] as List? ?? [])
        .map((entry) => SetlistEntry.fromJson(jsonMap(entry)))
        .toList(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}

class ActivityEntry {
  final String id, objectId, objectKind, action;
  final DateTime occurredAt;
  final int openCount;
  const ActivityEntry({
    required this.id,
    required this.objectId,
    required this.objectKind,
    required this.action,
    required this.occurredAt,
    this.openCount = 1,
  });
}

JsonMap jsonMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
Map<String, String> stringMap(dynamic value) => value is Map
    ? value.map((k, v) => MapEntry(k.toString(), v.toString()))
    : {};
JsonMap cloneJson(JsonMap value) => jsonMap(jsonDecode(jsonEncode(value)));
