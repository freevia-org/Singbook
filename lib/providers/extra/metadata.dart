import 'dart:async';

import '../../domain/models.dart';
import '../../domain/metadata_artist_credit.dart';
import '../../domain/edition_identity.dart';
import '../provider.dart';
import 'common.dart';

/// The transport already sends the versioned Singbook User-Agent (with the
/// configured contact URL); no per-adapter override is needed.
const _metadataHeaders = <String, String>{};

class MusicBrainzProvider implements LyricsProvider {
  MusicBrainzProvider(
    this.transport, {
    this.artworkTimeout = const Duration(seconds: 4),
  });
  final ProviderTransport transport;

  /// Total optional-release budget, including queue waits and retries.
  final Duration artworkTimeout;
  // MusicBrainz requires <= 1 request/second per client. The shared transport's
  // generic host pacing is faster, so this adapter serializes its own requests.
  Future<void> _queue = Future.value();
  DateTime _next = DateTime.fromMillisecondsSinceEpoch(0);
  final _releaseDetails = <String, ({JsonMap data, DateTime expiresAt})>{};
  @override
  final definition = const ProviderDefinition(
    id: 'musicbrainz',
    name: 'MusicBrainz',
    capabilities: {'catalog', 'metadata', 'artwork'},
    accessMode: 'noncommercialApi',
    website: 'https://musicbrainz.org/',
    description: 'recordingMetadataOnly',
  );
  Future<JsonMap> _get(Uri url, CancellationToken? cancel) {
    final result = _queue.then((_) async {
      cancel?.throwIfCancelled();
      final wait = _next.difference(DateTime.now());
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      cancel?.throwIfCancelled();
      try {
        return jsonMap(
          await transport.requestJson(
            url,
            headers: _metadataHeaders,
            cancel: cancel,
          ),
        );
      } finally {
        _next = DateTime.now().add(const Duration(milliseconds: 1100));
      }
    });
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static final _musicBrainzIdPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  String? _musicBrainzId(Object? value) {
    if (value is! String || !_musicBrainzIdPattern.hasMatch(value)) return null;
    return value.toLowerCase();
  }

  ({String? id, String? code}) _selectRelease(
    JsonMap recording,
    SongCandidate selection,
  ) {
    if (selection.metadata.containsKey('musicbrainzReleaseId')) {
      final explicit = _musicBrainzId(
        selection.metadata['musicbrainzReleaseId'],
      );
      return explicit == null
          ? (id: null, code: 'invalid_explicit_release_id')
          : (id: explicit, code: null);
    }

    final raw = recording['releases'];
    if (raw is! List || raw.any((item) => item is! Map)) {
      return (id: null, code: 'release_list_invalid');
    }
    // MusicBrainz linked entities are capped at 25. A visible subset cannot
    // establish uniqueness, even when the desired title appears once in it.
    final reportedCount = recording['release-count'];
    if (raw.length >= 25 ||
        reportedCount is int && reportedCount > raw.length) {
      return (id: null, code: 'release_list_truncated');
    }
    final rows = maps(raw);
    final album = selection.album?.trim();
    final pool = album == null || album.isEmpty
        ? rows
        : rows
              .where(
                (release) =>
                    normalized(stringValue(release['title'])) ==
                    normalized(album),
              )
              .toList();
    if (pool.isEmpty) return (id: null, code: 'release_not_found');
    final ids = <String>{};
    for (final row in pool) {
      final id = _musicBrainzId(row['id']);
      if (id == null) return (id: null, code: 'invalid_release_id');
      ids.add(id);
    }
    if (ids.length != 1) return (id: null, code: 'release_ambiguous');
    return (id: ids.single, code: null);
  }

  Future<JsonMap> _releaseDetail(String id, CancellationToken? cancel) async {
    cancel?.throwIfCancelled();
    final cached = _releaseDetails[id];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      cancel?.throwIfCancelled();
      return cached.data;
    }
    final data = await _get(
      Uri.https('musicbrainz.org', '/ws/2/release/$id', {
        'fmt': 'json',
        'inc': 'recordings',
      }),
      cancel,
    );
    if (_musicBrainzId(data['id']) != id) {
      throw const ProviderException('invalid_response');
    }
    _releaseDetails[id] = (
      data: data,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
    if (_releaseDetails.length > 32) {
      _releaseDetails.remove(_releaseDetails.keys.first);
    }
    return data;
  }

  bool _releaseContainsRecording(JsonMap release, String recordingId) {
    final media = release['media'];
    if (media is! List || media.isEmpty || media.any((item) => item is! Map)) {
      return false;
    }
    var found = false;
    for (final medium in maps(media)) {
      final tracks = medium['tracks'];
      if (tracks is! List ||
          tracks.isEmpty ||
          tracks.any((item) => item is! Map)) {
        return false;
      }
      for (final track in maps(tracks)) {
        final recording = track['recording'];
        if (recording is! Map) return false;
        final trackRecordingId = _musicBrainzId(jsonMap(recording)['id']);
        if (trackRecordingId == null) return false;
        if (trackRecordingId == recordingId) found = true;
      }
    }
    return found;
  }

  Future<({String? url, String? album, JsonMap evidence})>
  _boundedCoverArtForRecording({
    required JsonMap recording,
    required String recordingId,
    required SongCandidate selection,
    required CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final child = CancellationToken();
    cancel?.cancelled.then((_) => child.cancel());
    try {
      return await _coverArtForRecording(
        recording: recording,
        recordingId: recordingId,
        selection: selection,
        cancel: child,
      ).timeout(
        artworkTimeout,
        onTimeout: () {
          child.cancel();
          throw const ProviderException('timeout');
        },
      );
    } on ProviderException catch (error) {
      // Only the caller can cancel the recording operation. An optional
      // deadline keeps already-resolved metadata usable and stops its child.
      cancel?.throwIfCancelled();
      return (
        url: null,
        album: null,
        evidence: {
          'status': 'omitted',
          'code': error.code,
          'recordingId': recordingId,
        },
      );
    } finally {
      child.cancel();
    }
  }

  Future<({String? url, String? album, JsonMap evidence})>
  _coverArtForRecording({
    required JsonMap recording,
    required String recordingId,
    required SongCandidate selection,
    required CancellationToken? cancel,
  }) async {
    final choice = _selectRelease(recording, selection);
    if (choice.id == null) {
      return (
        url: null,
        album: null,
        evidence: {
          'status': 'omitted',
          'code': choice.code,
          'recordingId': recordingId,
        },
      );
    }
    final releaseId = choice.id!;
    JsonMap? release;
    String? code;
    String? url;
    String? album;
    try {
      release = await _releaseDetail(releaseId, cancel);
      cancel?.throwIfCancelled();
      if (_musicBrainzId(release['id']) != releaseId) {
        code = 'release_id_mismatch';
      } else if (stringValue(release['title']).trim().isEmpty) {
        code = 'release_title_missing';
      } else if (selection.album?.trim().isNotEmpty == true &&
          normalized(stringValue(release['title'])) !=
              normalized(selection.album!)) {
        code = 'release_album_mismatch';
      } else if (!_releaseContainsRecording(release, recordingId)) {
        code = 'recording_not_on_release';
      } else {
        final coverArtArchive = jsonMap(release['cover-art-archive']);
        if (coverArtArchive['darkened'] == true) {
          code = 'darkened_front_art';
        } else if (coverArtArchive['artwork'] != true ||
            coverArtArchive['count'] is int &&
                (coverArtArchive['count'] as int) <= 0) {
          code = 'cover_art_unavailable';
        } else if (coverArtArchive['front'] != true) {
          code = 'front_art_unavailable';
        } else {
          // This fixed Cover Art Archive URL is handed to the existing image
          // renderer. ProviderTransport never fetches or follows its CDN hop.
          url = 'https://coverartarchive.org/release/$releaseId/front-500';
          album = stringValue(release['title']);
        }
      }
    } on ProviderException catch (error) {
      cancel?.throwIfCancelled();
      code = error.code;
    } catch (_) {
      cancel?.throwIfCancelled();
      code = 'invalid_response';
    }
    return (
      url: url,
      album: album,
      evidence: {
        'status': url == null ? 'omitted' : 'available',
        'code': ?code,
        'recordingId': recordingId,
        'releaseId': releaseId,
        if (release != null)
          'releaseEvidence': {
            'contentType': 'application/json',
            'provenance': 'normalized MusicBrainz release response',
            'data': release,
          },
      },
    );
  }

  SongCandidate _candidate(JsonMap r, {bool searchRecord = false}) {
    final credits = maps(r['artist-credit']);
    final artist = credits
        .map(
          (c) =>
              '${c['name'] ?? jsonMap(c['artist'])['name'] ?? ''}${c['joinphrase'] ?? ''}',
        )
        .join();
    final releases = maps(r['releases']);
    final albums = releases
        .map((r) => stringValue(r['title']))
        .where((s) => s.isNotEmpty)
        .toSet();
    final id = stringValue(r['id']);
    final length = r['length'];
    return SongCandidate(
      providerId: definition.id,
      id: id,
      title: stringValue(r['title']),
      artist: artist,
      album: albums.length == 1 ? albums.first : null,
      durationSeconds: length is num && length > 0 ? length / 1000 : null,
      url: 'https://musicbrainz.org/recording/$id',
      recordingIds: {'musicbrainz': id},
      extra: {if (searchRecord) 'musicbrainzSearchRecording': r},
      metadata: {
        ...sanitizeExtraMetadata({
          'identityScope': 'recording',
          if (r['isrcs'] is List) 'isrcs': r['isrcs'],
          if (stringValue(r['disambiguation']).isNotEmpty)
            'version': r['disambiguation'],
          'releases': releases
              .map(
                (r) => {
                  'id': r['id'],
                  'title': r['title'],
                  if (r['date'] != null) 'date': r['date'],
                  if (r['country'] != null) 'country': r['country'],
                  if (r['status'] != null) 'status': r['status'],
                  if (r['release-group'] != null)
                    'releaseGroup': r['release-group'],
                },
              )
              .toList(),
        }),
        // Join phrases carry structural whitespace and an empty final join.
        // Generic text cleanup would destroy that source evidence.
        'artistCredits': credits
            .take(8)
            .map(
              (c) => {
                'name': boundedText(
                  c['name'] ?? jsonMap(c['artist'])['name'],
                  max: 200,
                ),
                'musicbrainzId': boundedText(
                  jsonMap(c['artist'])['id'],
                  max: 36,
                ),
                'joinPhrase': c['joinphrase'] == null
                    ? ''
                    : c['joinphrase'] is String &&
                          (c['joinphrase'] as String).length <= 40
                    ? c['joinphrase']
                    : '?',
              },
            )
            .toList(),
      },
    );
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final data = await _get(
      Uri.https('musicbrainz.org', '/ws/2/recording/', {
        'query': query,
        'fmt': 'json',
        'limit': '12',
      }),
      cancel,
    );
    if (data['recordings'] is! List) {
      throw const ProviderException('invalid_response');
    }
    return maps(data['recordings'])
        .map((recording) => _candidate(recording, searchRecord: true))
        .where((c) => c.id.isNotEmpty && c.title.isNotEmpty)
        .toList();
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    var id = candidate.providerId == definition.id
        ? candidate.id
        : candidate.recordingIds['musicbrainz'];
    if (id == null) {
      String escaped(String s) => s.replaceAll(RegExp(r'["\\]'), ' ');
      final artistNames = candidate.artist
          .split(RegExp(r'\s+&\s+'))
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toList();
      // A compound credit's punctuation is not stable across catalogs. Query
      // each name without relying on its join phrase; post-search identity and
      // feature-credit checks below remain mandatory.
      final artists = artistNames.length > 1 && artistNames.length <= 8
          ? artistNames
                .map((name) => 'artistname:"${escaped(name)}"')
                .join(' AND ')
          : 'artist:"${escaped(candidate.artist)}"';
      final album = candidate.album?.trim();
      final query =
          'recording:"${escaped(candidate.title)}" AND $artists'
          '${album == null || album.isEmpty ? '' : ' AND release:"${escaped(album)}"'}';
      final matchesById = <String, SongCandidate>{};
      for (final found in await search(query, cancel: cancel)) {
        if (_songCandidateMatches(candidate, found)) {
          matchesById.putIfAbsent(found.id, () => found);
        }
      }
      final matches = matchesById.values.toList()
        ..sort((a, b) {
          final exactArtist =
              (normalized(a.artist) == normalized(candidate.artist) ? 0 : 1)
                  .compareTo(
                    normalized(b.artist) == normalized(candidate.artist)
                        ? 0
                        : 1,
                  );
          if (exactArtist != 0) return exactArtist;
          if (candidate.durationSeconds case final double length) {
            final distance = ((a.durationSeconds ?? length) - length)
                .abs()
                .compareTo(((b.durationSeconds ?? length) - length).abs());
            if (distance != 0) return distance;
          }
          return a.id.compareTo(b.id);
        });
      if (matches.isEmpty) throw const ProviderException('unavailable');
      if (matches.length > 1) {
        return _ambiguousSongRecordings(candidate, matches, cancel);
      }
      id = matches.single.id;
    }
    return _resolveRecording(candidate, id, cancel);
  }

  bool _songCandidateMatches(SongCandidate selection, SongCandidate found) =>
      normalized(found.title) == normalized(selection.title) &&
      (normalized(found.artist) == normalized(selection.artist) ||
          musicBrainzArtistCreditEvidence(selection, found, normalized) !=
              null) &&
      explicitEditionsCompatible(selection, found) &&
      (selection.durationSeconds == null ||
          found.durationSeconds == null ||
          (selection.durationSeconds! - found.durationSeconds!).abs() <= 2) &&
      (selection.album == null ||
          maps(found.metadata['releases']).any(
            (release) =>
                normalized(stringValue(release['title'])) ==
                normalized(selection.album!),
          ));

  SongCandidate _songScopedCandidate(SongCandidate native) => SongCandidate(
    providerId: native.providerId,
    id: native.id,
    title: native.title,
    artist: native.artist,
    album: native.album,
    durationSeconds: native.durationSeconds,
    url: native.url,
    recordingIds: native.recordingIds,
    metadata: {...native.metadata, 'identityScope': 'song'},
    extra: native.extra,
  );

  Future<SourceResult> _ambiguousSongRecordings(
    SongCandidate selection,
    List<SongCandidate> matches,
    CancellationToken? cancel,
  ) async {
    final donors = <SourceResult>[];
    for (var index = 0; index < matches.length; index++) {
      cancel?.throwIfCancelled();
      final candidate = matches[index];
      String? failure;
      if (index < 3) {
        try {
          donors.add(
            await _resolveRecording(
              selection,
              candidate.id,
              cancel,
              songMatch: true,
              searchCandidate: candidate,
            ),
          );
          continue;
        } on ProviderException catch (error) {
          cancel?.throwIfCancelled();
          failure = error.code;
        } catch (_) {
          cancel?.throwIfCancelled();
          failure = 'invalid_response';
        }
      }
      final scoped = _songScopedCandidate(candidate);
      donors.add(
        SourceResult(
          candidate: scoped,
          body: '',
          metadata: scoped.metadata,
          matchKind: MatchKind.sameSong,
          matchReason: 'matching_song_recording_search',
          attribution: 'MusicBrainz',
          extra: {
            ...sourceEvidence(
              candidate,
              license: 'CC0 core data; supplementary data retains source terms',
              licenseUrl: 'https://musicbrainz.org/doc/MusicBrainz_Database',
              attribution: 'MusicBrainz',
            ),
            'metadataOnly': true,
            'identityScope': 'song',
            'searchEvidenceOnly': true,
            'nativeCandidate': candidate.toJson(),
            'recordingDetail': {
              'state': index < 3 ? 'failed' : 'not_attempted',
              'code': failure ?? 'detail_budget',
            },
          },
        ),
      );
    }
    // Keep a successfully resolved donor visible when an earlier native
    // recording failed, without discarding the failed search observation.
    donors.sort((a, b) {
      final detail = (a.extra['searchEvidenceOnly'] == true ? 1 : 0).compareTo(
        b.extra['searchEvidenceOnly'] == true ? 1 : 0,
      );
      return detail != 0
          ? detail
          : matches
                .indexWhere((candidate) => candidate.id == a.candidate.id)
                .compareTo(
                  matches.indexWhere(
                    (candidate) => candidate.id == b.candidate.id,
                  ),
                );
    });
    final primary = donors.first;
    return primary.copyWith(
      extra: {
        ...primary.extra,
        'recordingMatch': 'ambiguous_song_recordings',
        'providerAlternatives': [
          for (final donor in donors.skip(1)) donor.toJson(),
        ],
        'recordingDetailBudget': 3,
      },
    );
  }

  Future<SourceResult> _resolveRecording(
    SongCandidate candidate,
    String id,
    CancellationToken? cancel, {
    bool songMatch = false,
    SongCandidate? searchCandidate,
  }) async {
    if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch(id)) {
      throw const ProviderException('invalid_response');
    }
    final data = await _get(
      Uri.https('musicbrainz.org', '/ws/2/recording/$id', {
        'fmt': 'json',
        'inc': 'artist-credits+releases+isrcs+url-rels+work-rels',
      }),
      cancel,
    );
    if (data['id'] != id) throw const ProviderException('invalid_response');
    final native = _candidate(data);
    if (songMatch && !_songCandidateMatches(candidate, native)) {
      throw const ProviderException('identity_mismatch');
    }
    final found = songMatch ? _songScopedCandidate(native) : native;
    final metadata = <String, dynamic>{
      ...found.metadata,
      if (found.durationSeconds != null)
        'durationSeconds': found.durationSeconds,
      if (found.album != null) 'album': found.album,
      if (data['isrcs'] is List) 'isrcs': data['isrcs'],
      'musicbrainzRecordingId': id,
      'relationships': maps(data['relations']),
      'mediaLinks': [
        for (final relation in maps(data['relations']))
          if (httpsLink(jsonMap(relation['url'])['resource'])
              case final String url)
            if (Uri.parse(url).host == 'open.spotify.com')
              {'kind': 'audio', 'url': url, 'label': 'Spotify'},
      ],
    };
    final ({String? url, String? album, JsonMap evidence}) coverArt = songMatch
        ? (
            url: null,
            album: null,
            evidence: {'status': 'omitted', 'code': 'song_recording_ambiguous'},
          )
        : await _boundedCoverArtForRecording(
            recording: data,
            recordingId: id,
            selection: candidate,
            cancel: cancel,
          );
    final resolvedCandidate = coverArt.url == null
        ? found
        : SongCandidate(
            providerId: found.providerId,
            id: found.id,
            title: found.title,
            artist: found.artist,
            album: coverArt.album,
            durationSeconds: found.durationSeconds,
            url: found.url,
            metadata: {
              ...found.metadata,
              'musicbrainzReleaseId': coverArt.evidence['releaseId'],
            },
            recordingIds: found.recordingIds,
            extra: found.extra,
          );
    final artworkAssets = coverArt.url == null
        ? const <JsonMap>[]
        : <JsonMap>[
            {
              'url': coverArt.url,
              'sourceUrl':
                  'https://musicbrainz.org/release/${coverArt.evidence['releaseId']}',
              'credit':
                  'Cover Art Archive (MusicBrainz release ${coverArt.evidence['releaseId']})',
              'recordingId': id,
              'releaseId': coverArt.evidence['releaseId'],
              'role': 'frontCoverPreview',
              'rights': {'status': 'unknown'},
            },
          ];
    return SourceResult(
      candidate: resolvedCandidate,
      body: '',
      metadata: {
        ...sanitizeExtraMetadata(metadata),
        'artistCredits': found.metadata['artistCredits'],
        if (coverArt.url != null) ...{
          'album': coverArt.album,
          'artworkUrl': coverArt.url,
          'musicbrainzReleaseId': coverArt.evidence['releaseId'],
          'artworkAssets': artworkAssets,
        },
      },
      matchKind: songMatch ? MatchKind.sameSong : MatchKind.unverified,
      matchReason: songMatch ? 'matching_song_recording' : null,
      attribution: 'MusicBrainz',
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        ...sourceEvidence(
          found,
          license: 'CC0 core data; supplementary data retains source terms',
          licenseUrl: 'https://musicbrainz.org/doc/MusicBrainz_Database',
          attribution: 'MusicBrainz',
          permissions: {'status': 'field_specific', 'coreData': 'CC0'},
        ),
        'metadataOnly': true,
        if (songMatch) ...{
          'identityScope': 'song',
          'nativeCandidate': native.toJson(),
          'nativeRecording': data,
          if (searchCandidate != null)
            'searchCandidate': searchCandidate.toJson(),
          'recordingDetail': {'state': 'resolved'},
        },
        'artistIdentityEvidence': ?musicBrainzArtistCreditEvidence(
          candidate,
          found,
          normalized,
        ),
        'coverArtArchive': coverArt.evidence,
        'capabilityChecks': {
          'artwork': {
            'status': coverArt.url == null
                ? 'unavailable'
                : 'location_verified',
            if (coverArt.evidence['code'] case final String code) 'code': code,
          },
        },
      },
    );
  }
}

List<dynamic> claimValues(JsonMap entity, String property) =>
    maps(jsonMap(entity['claims'])[property])
        .where((c) => c['rank'] != 'deprecated')
        .map((c) => jsonMap(jsonMap(c['mainsnak'])['datavalue'])['value'])
        .where((v) => v != null)
        .toList();
List<String> entityClaims(JsonMap entity, String property) =>
    claimValues(entity, property)
        .map((v) => stringValue(jsonMap(v)['id']))
        .where((id) => RegExp(r'^Q\d+$').hasMatch(id))
        .toList();
String entityLabel(JsonMap entity) {
  final labels = jsonMap(entity['labels']);
  return stringValue(jsonMap(labels['en'])['value']).isNotEmpty
      ? stringValue(jsonMap(labels['en'])['value'])
      : labels.values
                .map((v) => stringValue(jsonMap(v)['value']))
                .where((s) => s.isNotEmpty)
                .firstOrNull ??
            '';
}

String? _tonalKeyLabel(String label) {
  final match = RegExp(
    r'^([a-g])(?:\s*-?\s*(sharp|flat)|\s*([#♯b♭]))?\s*-?\s*(major|minor)$',
    caseSensitive: false,
  ).firstMatch(label.trim());
  if (match == null) return null;
  final accidental = switch (match.group(2)?.toLowerCase() ?? match.group(3)) {
    'sharp' || '#' || '♯' => '#',
    'flat' || 'b' || '♭' => 'b',
    _ => '',
  };
  return '${match.group(1)!.toUpperCase()}$accidental${match.group(4)!.toLowerCase() == 'minor' ? 'm' : ''}';
}

List<JsonMap> _keyAssertions(JsonMap entity, Map<String, JsonMap> labels) => [
  for (final statement in maps(jsonMap(entity['claims'])['P826']))
    {
      'statement': statement,
      if (stringValue(
            jsonMap(
              jsonMap(jsonMap(statement['mainsnak'])['datavalue'])['value'],
            )['id'],
          )
          case final String id when RegExp(r'^Q\d+$').hasMatch(id)) ...{
        'entityId': id,
        if (stringValue(jsonMap(jsonMap(labels[id]?['labels'])['en'])['value'])
            case final String label when label.isNotEmpty) ...{
          'label': label,
          if (_tonalKeyLabel(label) case final String key) 'normalizedKey': key,
        },
      },
    },
];

class WikidataProvider implements LyricsProvider {
  WikidataProvider(this.transport);
  final ProviderTransport transport;
  // Positive, bounded type evidence: composed musical work, song, or the
  // work/composition metaclass. Q2188189 is too broad (it includes albums and
  // films). Albums, films, recordings and untyped items
  // must not become compositions merely because their labels match a song.
  static const _compositionTypes = {'Q207628', 'Q7366', 'Q105543609'};
  static const _nonCompositionTypes = {
    'Q482994',
    'Q11424',
    'Q134556',
    'Q193018',
  };
  @override
  final definition = const ProviderDefinition(
    id: 'wikidata',
    name: 'Wikidata',
    capabilities: {'catalog', 'metadata'},
    website: 'https://www.wikidata.org/',
    description: 'compositionMetadataOnly',
  );
  Future<JsonMap> _api(
    Map<String, String> params,
    CancellationToken? cancel,
  ) async {
    final data = jsonMap(
      await transport.requestJson(
        Uri.https('www.wikidata.org', '/w/api.php', {
          'format': 'json',
          'maxlag': '5',
          ...params,
        }),
        headers: _metadataHeaders,
        cancel: cancel,
      ),
    );
    throwIfApiError(data);
    return data;
  }

  Future<Map<String, JsonMap>> _entities(
    List<String> ids,
    CancellationToken? cancel,
  ) async {
    final valid = ids
        .where((s) => RegExp(r'^Q\d+$').hasMatch(s))
        .toSet()
        .take(40)
        .toList();
    if (valid.isEmpty) return {};
    final data = await _api({
      'action': 'wbgetentities',
      'ids': valid.join('|'),
      'props': 'labels|descriptions|claims',
      'languages': 'en',
    }, cancel);
    return {
      for (final entry in jsonMap(data['entities']).entries)
        if (valid.contains(entry.key)) entry.key: jsonMap(entry.value),
    };
  }

  Future<List<SongCandidate>> _candidates(
    List<String> ids,
    CancellationToken? cancel, {
    bool includeKeySingles = false,
  }) async {
    final entities = await _entities(ids, cancel);
    bool isWork(JsonMap entity) {
      final types = entityClaims(entity, 'P31');
      return types.any(_compositionTypes.contains) &&
          !types.any(_nonCompositionTypes.contains);
    }

    bool isKeySingle(JsonMap entity) {
      final types = entityClaims(entity, 'P31');
      return includeKeySingles &&
          types.contains('Q134556') &&
          !types.any(const {'Q482994', 'Q11424', 'Q193018'}.contains) &&
          maps(jsonMap(entity['claims'])['P826']).isNotEmpty;
    }

    final works = entities.entries
        .where(
          (entry) =>
              entry.value['missing'] == null &&
              (isWork(entry.value) || isKeySingle(entry.value)),
        )
        .toList();
    if (works.isEmpty) return [];
    final typedWorks = works.where((entry) => isWork(entry.value)).toList();
    final related = typedWorks
        .map((entry) => entry.value)
        .expand(
          (e) => [
            ...entityClaims(e, 'P175'),
            ...entityClaims(e, 'P86'),
            ...entityClaims(e, 'P676'),
            ...entityClaims(e, 'P361'),
          ],
        )
        .toList();
    final labels = await _entities(related, cancel);
    final keyIds = typedWorks
        .expand(
          (entry) => maps(jsonMap(entry.value['claims'])['P826']).map(
            (statement) => stringValue(
              jsonMap(
                jsonMap(jsonMap(statement['mainsnak'])['datavalue'])['value'],
              )['id'],
            ),
          ),
        )
        .toList();
    var keyLabels = <String, JsonMap>{};
    try {
      // Optional labels use a separate bounded batch: an uncached key lookup
      // must not invalidate cached performer, composer or work metadata.
      keyLabels = await _entities(keyIds, cancel);
    } on ProviderException {
      cancel?.throwIfCancelled();
    }
    final singleIds = [
      for (final entry in works.where((entry) => !isWork(entry.value))) ...[
        ...entityClaims(entry.value, 'P175'),
        for (final statement in maps(jsonMap(entry.value['claims'])['P826']))
          stringValue(
            jsonMap(
              jsonMap(jsonMap(statement['mainsnak'])['datavalue'])['value'],
            )['id'],
          ),
      ],
    ];
    try {
      // Optional Single donors must not change the established work-label
      // request or make its existing metadata depend on a new cache entry.
      final singleLabels = await _entities(singleIds, cancel);
      labels.addAll(singleLabels);
      keyLabels.addAll(singleLabels);
    } on ProviderException {
      cancel?.throwIfCancelled();
    }

    return works
        .map((e) {
          final keyAssertions = _keyAssertions(e.value, keyLabels);
          final keys = keyAssertions
              .map((assertion) => assertion['normalizedKey'])
              .whereType<String>()
              .toSet()
              .toList();
          final artists = entityClaims(e.value, 'P175')
              .map((id) => entityLabel(labels[id] ?? {}))
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();
          final creators =
              {
                    ...entityClaims(e.value, 'P86'),
                    ...entityClaims(e.value, 'P676'),
                  }
                  .map((id) => entityLabel(labels[id] ?? {}))
                  .where((name) => name.isNotEmpty)
                  .toSet();
          var metadata = <String, dynamic>{
            'identityScope': 'composition',
            'wikidataId': e.key,
            'description': stringValue(
              jsonMap(jsonMap(e.value['descriptions'])['en'])['value'],
            ),
            'types': entityClaims(e.value, 'P31'),
            'performerIds': entityClaims(e.value, 'P175'),
            'performers': artists,
            'composers': entityClaims(e.value, 'P86')
                .map(
                  (id) => {
                    'wikidataId': id,
                    'name': entityLabel(labels[id] ?? {}),
                  },
                )
                .toList(),
            'lyricists': entityClaims(e.value, 'P676')
                .map(
                  (id) => {
                    'wikidataId': id,
                    'name': entityLabel(labels[id] ?? {}),
                  },
                )
                .toList(),
            'partOf': entityClaims(e.value, 'P361')
                .map(
                  (id) => {
                    'wikidataId': id,
                    'name': entityLabel(labels[id] ?? {}),
                  },
                )
                .toList(),
            'publicationDates': claimValues(e.value, 'P577'),
            'durationClaims': claimValues(e.value, 'P2047'),
            if (keys.length == 1) 'key': keys.single,
            if (keys.length > 1) 'keys': keys,
            'externalIdentifiers': {
              for (final entry in jsonMap(e.value['claims']).entries)
                if (maps(entry.value).any(
                  (c) => jsonMap(c['mainsnak'])['datatype'] == 'external-id',
                ))
                  entry.key: claimValues(e.value, entry.key),
            },
          };
          final files = claimValues(
            e.value,
            'P18',
          ).whereType<String>().toList();
          if (files.length == 1) {
            metadata['wikimediaCommonsFile'] = files.single;
          }
          final keySingle = !isWork(e.value);
          if (keySingle) {
            // Singles are useful song-level key evidence, not permission to
            // promote release, duration, artwork or recording identity facts.
            metadata = {
              'identityScope': 'song',
              'wikidataId': e.key,
              'types': entityClaims(e.value, 'P31'),
              'performerIds': entityClaims(e.value, 'P175'),
              'performers': artists,
              'performerAssertions': maps(jsonMap(e.value['claims'])['P175']),
              if (keys.length == 1) 'key': keys.single,
              if (keys.length > 1) 'keys': keys,
            };
          }
          return SongCandidate(
            providerId: definition.id,
            id: e.key,
            title: entityLabel(e.value),
            // Work authorship is independent of the many recordings/covers
            // linked through P175; retain performers separately as metadata.
            artist: (keySingle ? artists : creators).join(', '),
            url: 'https://www.wikidata.org/wiki/${e.key}',
            metadata: {
              ...sanitizeExtraMetadata(metadata),
              // Preserve complete source statements, including qualifiers and
              // references that exceed the generic metadata nesting depth.
              if (keyAssertions.isNotEmpty) 'keyAssertions': keyAssertions,
              if (keySingle)
                'performerAssertions': maps(jsonMap(e.value['claims'])['P175']),
            },
          );
        })
        .where((c) => c.title.isNotEmpty)
        .toList();
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) => _search(query, cancel);

  Future<List<SongCandidate>> _search(
    String query,
    CancellationToken? cancel, {
    bool includeKeySingles = false,
  }) async {
    final data = await _api({
      'action': 'wbsearchentities',
      'search': queryText(query),
      'language': 'en',
      // A title can rank albums, films and individual recordings before the
      // composition. Fetch a bounded page, then retain only typed works.
      'limit': '12',
      'type': 'item',
    }, cancel);
    final ids = maps(data['search']).map((r) => stringValue(r['id'])).toList();
    return _candidates(ids, cancel, includeKeySingles: includeKeySingles);
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final external = candidate.providerId != definition.id;
    final exactId = candidate.providerId == definition.id
        ? candidate.id
        : candidate.recordingIds['wikidata'] ??
              stringValue(candidate.metadata['wikidataId']);
    List<SongCandidate> found;
    if (exactId.isNotEmpty) {
      found = await _candidates([exactId], cancel, includeKeySingles: external);
    } else {
      found = await _search(
        candidate.title,
        cancel,
        includeKeySingles: external,
      );
    }
    if (external) {
      // A recording performer need not be the work's author. Require the
      // fetched work's own P175 evidence before associating it with that
      // performer; a caller-supplied work ID alone proves no association.
      found = found
          .map((work) => _forPerformer(work, candidate))
          .nonNulls
          .toList();
    } else if (exactId.isEmpty) {
      found = found
          .where(
            (r) =>
                normalized(r.title) == normalized(candidate.title) &&
                r.artist.isNotEmpty &&
                normalized(r.artist) == normalized(candidate.artist),
          )
          .toList();
    }
    if (found.isEmpty) throw const ProviderException('unavailable');
    if (!external && found.length != 1) {
      throw const ProviderException('ambiguous_match');
    }
    found.sort((a, b) {
      final work = (a.metadata['identityScope'] == 'composition' ? 0 : 1)
          .compareTo(b.metadata['identityScope'] == 'composition' ? 0 : 1);
      return work != 0 ? work : a.id.compareTo(b.id);
    });
    SourceResult document(SongCandidate result) => SourceResult(
      candidate: result,
      body: '',
      metadata: result.metadata,
      matchKind: external ? MatchKind.sameSong : MatchKind.unverified,
      attribution: 'Wikidata contributors',
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        ...sourceEvidence(
          result,
          license: 'CC0',
          licenseUrl: 'https://www.wikidata.org/wiki/Wikidata:Licensing',
          attribution: 'Wikidata contributors',
          permissions: {
            'status': 'source_declared',
            'offline': true,
            'redistribute': true,
          },
        ),
        'metadataOnly': true,
        'identityScope': result.metadata['identityScope'],
        if (external)
          'identityMatch': {'property': 'P175', 'performer': result.artist},
      },
    );
    final primary = document(found.first);
    return found.length == 1
        ? primary
        : primary.copyWith(
            extra: {
              ...primary.extra,
              'providerAlternatives': [
                for (final donor in found.skip(1)) document(donor).toJson(),
              ],
            },
          );
  }

  SongCandidate? _forPerformer(SongCandidate work, SongCandidate selected) {
    if (normalized(work.title) != normalized(selected.title) ||
        selected.artist.trim().isEmpty) {
      return null;
    }
    final matches = (work.metadata['performers'] as List? ?? const [])
        .whereType<String>()
        .where((name) => normalized(name) == normalized(selected.artist))
        .toSet();
    if (matches.length != 1) return null;
    return SongCandidate(
      providerId: work.providerId,
      id: work.id,
      title: work.title,
      artist: matches.single,
      url: work.url,
      metadata: work.metadata,
    );
  }
}

class WikimediaCommonsProvider implements LyricsProvider {
  WikimediaCommonsProvider(this.transport);
  final ProviderTransport transport;
  @override
  final definition = const ProviderDefinition(
    id: 'wikimediacommons',
    name: 'Wikimedia Commons',
    capabilities: {'metadata', 'artwork'},
    accessMode: 'exactEntity',
    website: 'https://commons.wikimedia.org/',
    description: 'exactFileArtworkOnly',
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    if (!query.startsWith('File:')) return [];
    final candidate = SongCandidate(
      providerId: definition.id,
      id: query,
      title: query.substring(5),
      artist: '',
      url: 'https://commons.wikimedia.org/wiki/${Uri.encodeComponent(query)}',
      metadata: {'wikimediaCommonsFile': query, 'identityScope': 'image'},
    );
    final resolved = await resolve(candidate, cancel: cancel);
    return [resolved.candidate];
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final file = stringValue(candidate.metadata['wikimediaCommonsFile']);
    if (file.isEmpty ||
        file.length > 512 ||
        file.contains('|') ||
        file.contains('\n')) {
      throw const ProviderException('identity_required');
    }
    final title = file.startsWith('File:') ? file : 'File:$file';
    final data = jsonMap(
      await transport.requestJson(
        Uri.https('commons.wikimedia.org', '/w/api.php', {
          'action': 'query',
          'format': 'json',
          'formatversion': '2',
          'maxlag': '5',
          'prop': 'imageinfo',
          'titles': title,
          'iiprop': 'url|extmetadata|mime|size|sha1',
          'iiurlwidth': '800',
        }),
        headers: _metadataHeaders,
        cancel: cancel,
      ),
    );
    throwIfApiError(data);
    final pages = maps(jsonMap(data['query'])['pages']);
    final page = pages.where((p) => p['missing'] != true).firstOrNull;
    final info = maps(page?['imageinfo']).firstOrNull;
    if (info == null) throw const ProviderException('unavailable');
    final ext = jsonMap(info['extmetadata']);
    String value(String key) => textValue(jsonMap(ext[key])['value']);
    final license = value('LicenseShortName');
    // Only license pages on known hosts are kept; anything else is dropped.
    final licenseUrl = httpsLink(
      value('LicenseUrl'),
      hosts: const {'creativecommons.org', 'wikimedia.org', 'wikipedia.org'},
    );
    final approved = RegExp(
      r'^(?:CC BY(?:-SA)?(?: [0-9.]+)?|CC0(?: [0-9.]+)?|Public domain)$',
      caseSensitive: false,
    ).hasMatch(license);
    if (!approved || value('Restrictions').isNotEmpty) {
      throw const ProviderException('rights_review_required');
    }
    const imageHosts = {'wikimedia.org'};
    final imageUrl =
        httpsLink(info['thumburl'], hosts: imageHosts) ??
        httpsLink(info['url'], hosts: imageHosts);
    if (imageUrl == null || !stringValue(info['mime']).startsWith('image/')) {
      throw const ProviderException('invalid_response');
    }
    final sourceUrl =
        httpsLink(info['descriptionurl']) ??
        'https://commons.wikimedia.org/wiki/${Uri.encodeComponent(title)}';
    final found = SongCandidate(
      providerId: definition.id,
      id: title,
      title: candidate.title,
      artist: candidate.artist,
      url: sourceUrl,
      metadata: {'identityScope': 'image', 'wikimediaCommonsFile': title},
    );
    final asset = {
      'url': imageUrl,
      'sourceUrl': sourceUrl,
      'license': license,
      'licenseUrl': ?licenseUrl,
      'author': boundedText(value('Artist'), max: 500),
      'credit': boundedText(value('Credit'), max: 500),
      'sha1': info['sha1'],
      'role': 'entityImage',
      'title': title,
      'mime': info['mime'],
    };
    return SourceResult(
      candidate: found,
      body: '',
      metadata: {
        'licensedImages': [asset],
      },
      attribution: [
        value('Artist'),
        value('Credit'),
      ].where((s) => s.isNotEmpty).join(' — '),
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        ...sourceEvidence(
          found,
          license: license,
          licenseUrl: licenseUrl,
          attribution: value('Artist'),
          permissions: {
            'status': 'source_declared',
            'offline': true,
            'attributionRequired': license.toLowerCase().startsWith('cc by'),
            'shareAlike': license.contains('-SA'),
          },
        ),
        'metadataOnly': true,
        'identityScope': 'image',
        'image': asset,
      },
    );
  }
}
