import 'dart:convert';
import '../../domain/models.dart';
import '../provider.dart';
import 'common.dart';

/// Public YouTube Music web responses. No logged-in cookies or player scraping.
class YoutubeMusicProvider implements LyricsProvider {
  YoutubeMusicProvider(this.http);
  final ProviderTransport http;
  // Fixed anonymous accept marker used by yt-dlp. It carries no
  // account/session data and is sent only to the exact Music endpoints below.
  static const _requestHeaders = {'Cookie': 'SOCS=CAI'};
  JsonMap? _configuration;
  DateTime? _expires;
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'youtubemusic',
    name: 'YouTube Music',
    capabilities: {'catalog', 'lyrics', 'metadata'},
    accessMode: 'public_web',
    website: 'https://music.youtube.com',
  );
  Future<JsonMap>? _pending;

  bool get _hasFreshConfig {
    return _configuration != null && _expires!.isAfter(DateTime.now());
  }

  /// Overlapping callers share one homepage download.
  Future<JsonMap> _config(CancellationToken? cancel, [int retries = 0]) async {
    cancel?.throwIfCancelled();
    if (_hasFreshConfig) return _configuration!;
    if (_pending == null) {
      late final Future<JsonMap> load;
      load = _loadConfig(cancel).whenComplete(() {
        if (identical(_pending, load)) {
          _pending = null;
        }
      });
      _pending = load;
    }
    try {
      return await _pending!;
    } on ProviderException catch (error) {
      // If the caller that started a shared homepage request was cancelled,
      // let other live callers make a fresh anonymous request.
      if (error.code == 'cancelled' &&
          cancel?.isCancelled != true &&
          retries < 2) {
        return _config(cancel, retries + 1);
      }
      rethrow;
    }
  }

  Future<JsonMap> _loadConfig(CancellationToken? cancel) async {
    final String source;
    try {
      source = await http.getText(
        Uri.parse('https://music.youtube.com/'),
        headers: _requestHeaders,
        cancel: cancel,
      );
    } on ProviderException catch (e) {
      if (e.code == 'redirect' && e.message.contains('consent.')) {
        throw const ProviderException('blocked', 'consent_required');
      }
      rethrow;
    }
    JsonMap? config;
    for (final match in RegExp(
      r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;',
      dotAll: true,
    ).allMatches(source)) {
      try {
        final data = object(jsonDecode(match[1]!));
        if (data['INNERTUBE_CLIENT_VERSION'] != null ||
            jsonMap(
                  jsonMap(data['INNERTUBE_CONTEXT'])['client'],
                )['clientVersion'] !=
                null) {
          config = data;
          break;
        }
      } catch (_) {
        /* Read JSON, never execute site JavaScript. */
      }
    }
    if (config == null) {
      final reason = blockedPageReason(source);
      if (reason != null) throw ProviderException('blocked', reason);
      // Fallback for layouts that no longer wrap the config in ytcfg.set(...).
      final loose = RegExp(
        r'"INNERTUBE_CLIENT_VERSION"\s*:\s*"([A-Za-z0-9._-]{1,100})"',
      ).firstMatch(source)?[1];
      if (loose != null) config = {'INNERTUBE_CLIENT_VERSION': loose};
    }
    final client = jsonMap(jsonMap(config?['INNERTUBE_CONTEXT'])['client']);
    final upgrade =
        source.contains('/img/on_platform_logo_dark.svg') &&
        source.contains('google.com/chrome/index.html');
    final date = DateTime.now()
        .toUtc()
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');
    final version =
        config?['INNERTUBE_CLIENT_VERSION'] ??
        client['clientVersion'] ??
        (upgrade ? '1.$date.01.00' : null);
    final visitor = config?['VISITOR_DATA'] ?? client['visitorData'];
    if (version is! String ||
        !RegExp(r'^[A-Za-z0-9._-]{1,100}$').hasMatch(version) ||
        (visitor != null &&
            (visitor is! String ||
                visitor.length > 4096 ||
                RegExp(r'[\r\n]').hasMatch(visitor)))) {
      throwIfBlocked(source);
      throw const ProviderException('extraction_failed');
    }
    _configuration = {'version': version, 'visitor': ?visitor};
    _expires = DateTime.now().add(const Duration(hours: 1));
    return _configuration!;
  }

  Future<JsonMap> _request(
    String endpoint,
    JsonMap fields,
    CancellationToken? cancel,
  ) async {
    final cached = _hasFreshConfig;
    try {
      return await _send(endpoint, fields, cancel);
    } on ProviderException catch (e) {
      // A rotated client version fails with a client error: forget the cached
      // value, and retry once with a freshly fetched one.
      const keep = {'cancelled', 'timeout', 'rate_limited', 'blocked'};
      if (keep.contains(e.code)) rethrow;
      _configuration = null;
      if (cached) return _send(endpoint, fields, cancel);
      rethrow;
    }
  }

  Future<JsonMap> _send(
    String endpoint,
    JsonMap fields,
    CancellationToken? cancel,
  ) async {
    final config = await _config(cancel);
    final response = object(
      await http.requestJson(
        Uri.parse('https://music.youtube.com/youtubei/v1/$endpoint?alt=json'),
        method: 'POST',
        headers: {
          ..._requestHeaders,
          'Origin': 'https://music.youtube.com',
          if (config['visitor'] != null)
            'X-Goog-Visitor-Id': config['visitor'] as String,
        },
        body: {
          ...fields,
          'context': {
            'client': {
              'clientName': 'WEB_REMIX',
              'clientVersion': config['version'],
              'hl': 'en',
            },
            'user': {},
          },
        },
        cancel: cancel,
      ),
    );
    if (response['error'] != null) {
      throw const ProviderException('invalid_response');
    }
    return response;
  }

  static String? _runs(dynamic raw, [int max = 300]) {
    final data = jsonMap(raw);
    if (data['simpleText'] is String) return clean(data['simpleText'], max);
    if (data['runs'] is! List) return null;
    return clean(
      (data['runs'] as List)
          .map((r) => jsonMap(r)['text'] is String ? jsonMap(r)['text'] : '')
          .join(),
      max,
    );
  }

  static String? _type(JsonMap endpoint) =>
      jsonMap(
            jsonMap(
              endpoint['browseEndpointContextSupportedConfigs'],
            )['browseEndpointContextMusicConfig'],
          )['pageType']
          as String?;
  static bool _artist(JsonMap endpoint) =>
      _type(endpoint) == 'MUSIC_PAGE_TYPE_ARTIST' ||
      (_type(endpoint) == null &&
          endpoint['browseId'] is String &&
          (endpoint['browseId'] as String).startsWith('UC'));
  static ({String? artist, String? album}) _byline(dynamic raw) {
    final rows = jsonMap(raw)['runs'] is List
        ? jsonMap(raw)['runs'] as List
        : [];
    final artists = <String>{}, albums = <String>{};
    for (final row in rows) {
      final run = jsonMap(row),
          endpoint = jsonMap(
            jsonMap(jsonMap(row)['navigationEndpoint'])['browseEndpoint'],
          );
      final label = clean(run['text']);
      if (label != null && _artist(endpoint)) artists.add(label);
      if (label != null && _type(endpoint) == 'MUSIC_PAGE_TYPE_ALBUM') {
        albums.add(label);
      }
    }
    if (albums.length > 1) throw const ProviderException('invalid_response');
    final separator = rows.indexWhere((r) => clean(jsonMap(r)['text']) == '•');
    final firstGroup = separator > 0 ? rows.take(separator).toList() : [];
    final firstIsArtist =
        firstGroup.isNotEmpty &&
        firstGroup.every(
          (r) =>
              jsonMap(r)['navigationEndpoint'] == null ||
              _artist(
                jsonMap(
                  jsonMap(jsonMap(r)['navigationEndpoint'])['browseEndpoint'],
                ),
              ),
        );
    return (
      artist: firstIsArtist
          ? _runs({'runs': firstGroup})
          : clean(artists.join(', ')),
      album: albums.firstOrNull,
    );
  }

  static double? _duration(String? value) {
    if (value == null ||
        !RegExp(r'^(?:\d{1,2}:)?\d{1,3}:\d{2}$').hasMatch(value.trim())) {
      return null;
    }
    final parts = value.split(':').map(int.parse).toList();
    if (parts.skip(1).any((p) => p >= 60)) return null;
    return durationValue(parts.fold<int>(0, (sum, p) => sum * 60 + p));
  }

  static SongCandidate _song(
    String id,
    String? title,
    String? artist,
    String? album,
    double? seconds,
    dynamic thumbnails,
  ) {
    if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ||
        title == null ||
        artist == null) {
      throw const ProviderException('invalid_response');
    }
    final thumbs =
        (thumbnails is List ? thumbnails : [])
            .map(jsonMap)
            .where((t) => httpsUrl(t['url'], hosts: youtubeImageHosts) != null)
            .toList()
          ..sort(
            (a, b) => ((b['width'] as num?) ?? 0).compareTo(
              (a['width'] as num?) ?? 0,
            ),
          );
    final url = 'https://music.youtube.com/watch?v=$id';
    return SongCandidate(
      providerId: 'youtubemusic',
      id: id,
      title: title,
      artist: artist,
      album: album,
      durationSeconds: seconds,
      url: url,
      metadata: sanitizeMetadata({
        'album': album,
        'duration': seconds,
        'artworkUrl': thumbs.firstOrNull?['url'],
        'mediaLinks': [
          {'kind': 'audio', 'label': 'YouTube Music', 'url': url},
        ],
      }),
    );
  }

  static List<SongCandidate> parseSearch(JsonMap data) {
    final contents = jsonMap(data['contents']);
    final tabs = jsonMap(contents['tabbedSearchResultsRenderer'])['tabs'];
    final root = tabs is List && tabs.isNotEmpty
        ? jsonMap(jsonMap(jsonMap(tabs.first)['tabRenderer'])['content'])
        : contents;
    final sections = array(jsonMap(root['sectionListRenderer'])['contents']);
    final results = <SongCandidate>[], seen = <String>{};
    var skipped = 0;
    for (final section in sections) {
      final s = jsonMap(section),
          items =
              jsonMap(jsonMap(section)['musicShelfRenderer'])['contents'] ??
              jsonMap(s['itemSectionRenderer'])['contents'];
      if (items is! List) continue;
      for (final item in items) {
        final row = jsonMap(jsonMap(item)['musicResponsiveListItemRenderer']);
        if (row.isEmpty) continue;
        final columns = array(row['flexColumns'])
            .map(
              (c) => jsonMap(
                jsonMap(c)['musicResponsiveListItemFlexColumnRenderer'],
              )['text'],
            )
            .toList();
        if (columns.length < 2) {
          skipped++;
          continue;
        }
        final runs = jsonMap(columns[0])['runs'] is List
            ? jsonMap(columns[0])['runs'] as List
            : [];
        JsonMap watch = {};
        for (final r in runs) {
          final w = jsonMap(
            jsonMap(jsonMap(r)['navigationEndpoint'])['watchEndpoint'],
          );
          if (w.isNotEmpty) {
            watch = w;
            break;
          }
        }
        final id =
            jsonMap(row['playlistItemData'])['videoId'] ?? watch['videoId'];
        if (id is! String ||
            (watch['videoId'] != null && watch['videoId'] != id)) {
          skipped++;
          continue;
        }
        final videoType = jsonMap(
          jsonMap(
            watch['watchEndpointMusicSupportedConfigs'],
          )['watchEndpointMusicConfig'],
        )['musicVideoType'];
        if (videoType != null && videoType != 'MUSIC_VIDEO_TYPE_ATV') continue;
        if (row['musicItemRendererDisplayPolicy'] ==
            'MUSIC_ITEM_RENDERER_DISPLAY_POLICY_GREY_OUT') {
          continue;
        }
        final ({String? artist, String? album}) by;
        try {
          by = _byline(columns[1]);
        } on ProviderException {
          skipped++;
          continue;
        }
        double? duration;
        for (final r
            in jsonMap(columns[1])['runs'] is List
                ? jsonMap(columns[1])['runs']
                : []) {
          duration ??= _duration(clean(jsonMap(r)['text']));
        }
        if (seen.add(id)) {
          try {
            results.add(
              _song(
                id,
                _runs(columns[0]),
                by.artist,
                by.album,
                duration,
                jsonMap(
                  jsonMap(
                    jsonMap(row['thumbnail'])['musicThumbnailRenderer'],
                  )['thumbnail'],
                )['thumbnails'],
              ),
            );
          } on ProviderException {
            skipped++;
          }
        }
      }
    }
    // A malformed row is skipped; only a response with no usable row at all
    // means the shape changed.
    if (results.isEmpty && skipped > 0) {
      throw const ProviderException('invalid_response', 'No usable rows');
    }
    return results.take(20).toList();
  }

  static ({SongCandidate song, String browseId}) parseSelected(
    JsonMap data,
    String id,
  ) {
    final tabs = array(
      jsonMap(
        jsonMap(
          jsonMap(
            jsonMap(
              data['contents'],
            )['singleColumnMusicWatchNextResultsRenderer'],
          )['tabbedRenderer'],
        )['watchNextTabbedResultsRenderer'],
      )['tabs'],
    );
    if (tabs.isEmpty) throw const ProviderException('invalid_response');
    final tabContent = jsonMap(
      jsonMap(jsonMap(tabs.first)['tabRenderer'])['content'],
    );
    final queueContent = jsonMap(
      jsonMap(tabContent['musicQueueRenderer'])['content'],
    );
    final queue = jsonMap(queueContent['playlistPanelRenderer'])['contents'];
    final selected = array(queue)
        .map(
          (item) => jsonMap(
            jsonMap(item)['playlistPanelVideoRenderer'] ??
                jsonMap(
                  jsonMap(
                    jsonMap(item)['playlistPanelVideoWrapperRenderer'],
                  )['primaryRenderer'],
                )['playlistPanelVideoRenderer'],
          ),
        )
        .where((r) => r['selected'] == true)
        .toList();
    if (selected.length != 1 || selected.single['videoId'] != id) {
      throw const ProviderException('invalid_response', 'Different recording');
    }
    final row = selected.single,
        by = _byline(selected.single['longBylineText']);
    final song = _song(
      id,
      _runs(row['title']),
      by.artist ?? _runs(row['shortBylineText']),
      by.album,
      _duration(_runs(row['lengthText'])),
      jsonMap(row['thumbnail'])['thumbnails'],
    );
    final lyrics = <JsonMap>[];
    for (final raw in tabs) {
      final tab = jsonMap(jsonMap(raw)['tabRenderer']),
          endpoint = jsonMap(
            jsonMap(
              jsonMap(jsonMap(raw)['tabRenderer'])['endpoint'],
            )['browseEndpoint'],
          );
      if (tab['unselectable'] != true &&
          _type(endpoint) == 'MUSIC_PAGE_TYPE_TRACK_LYRICS') {
        lyrics.add(endpoint);
      }
    }
    if (lyrics.isEmpty) throw const ProviderException('unavailable');
    if (lyrics.length != 1) throw const ProviderException('invalid_response');
    final browse = lyrics.single['browseId'];
    if (browse is! String ||
        !RegExp(r'^MPLY[A-Za-z0-9_-]{1,200}$').hasMatch(browse)) {
      throw const ProviderException('invalid_response');
    }
    return (song: song, browseId: browse);
  }

  static ({String lyrics, String? attribution}) parseLyrics(JsonMap data) {
    final sections = jsonMap(
      jsonMap(data['contents'])['sectionListRenderer'],
    )['contents'];
    if (sections is! List) throw const ProviderException('unavailable');
    final shelves = sections
        .map((s) => jsonMap(jsonMap(s)['musicDescriptionShelfRenderer']))
        .where((s) => s.isNotEmpty)
        .toList();
    if (shelves.isEmpty) throw const ProviderException('unavailable');
    if (shelves.length != 1) throw const ProviderException('invalid_response');
    return (
      lyrics: meaningfulLyrics(_runs(shelves.single['description'], 200000)),
      attribution:
          _runs(shelves.single['footer'], 1000) ?? _runs(shelves.single, 1000),
    );
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => parseSearch(
    await _request('search', {
      'query': queryText(query),
      'params': 'EgWKAQIIAWoMEA4QChADEAQQCRAF',
    }, cancel),
  );
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(candidate.id)) {
      throw const ProviderException('invalid_selection');
    }
    final selected = parseSelected(
      await _request('next', {
        'videoId': candidate.id,
        'playlistId': 'RDAMVM${candidate.id}',
        'enablePersistentPlaylistPanel': true,
        'isAudioOnly': true,
        'tunerSettingValue': 'AUTOMIX_SETTING_NORMAL',
        'watchEndpointMusicSupportedConfigs': {
          'watchEndpointMusicConfig': {
            'hasPersistentPlaylistPanel': true,
            'musicVideoType': 'MUSIC_VIDEO_TYPE_ATV',
          },
        },
      }, cancel),
      candidate.id,
    );
    final lyrics = parseLyrics(
      await _request('browse', {'browseId': selected.browseId}, cancel),
    );
    return lyricsResult(
      selected.song,
      lyrics.lyrics,
      attribution: lyrics.attribution ?? 'YouTube Music',
    );
  }
}
