import 'dart:convert';
import 'dart:io' show gzip;
import 'package:html/dom.dart';
import '../../domain/models.dart';
import '../../domain/timing.dart';
import '../../domain/lyrics_variants.dart';
import '../provider.dart';
import 'common.dart';

const _maxPreservedLyricsVariant = 200000;

String? _preservedLyricsVariant(dynamic value) {
  if (value is! String) return null;
  if (value.length > _maxPreservedLyricsVariant) {
    throw const ProviderException('invalid_response');
  }
  return value;
}

SourceResult _withLyricsVariants(
  SourceResult result, {
  required JsonMap rawVariants,
  required String selected,
}) => result.copyWith(
  extra: {
    ...result.extra,
    'lyricsVariants': {...rawVariants, 'selected': selected},
  },
);

bool _canSupplyLyrics(TimingTrack track) =>
    track.status != TimingStatus.invalid &&
    track.status != TimingStatus.unsupported &&
    track.cues.isNotEmpty &&
    track.sourceLyrics.trim().isNotEmpty;

class GeniusProvider implements LyricsProvider {
  GeniusProvider(
    this.http, {
    this.token = const String.fromEnvironment('GENIUS_ACCESS_TOKEN'),
  });
  final ProviderTransport http;
  final String token;
  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: 'genius',
    name: 'Genius',
    capabilities: const {'catalog', 'lyrics', 'metadata'},
    enabledByDefault: token.trim().isNotEmpty,
    configured: token.trim().isNotEmpty,
    accessMode: 'app_token',
    website: 'https://genius.com',
  );
  Future<JsonMap> _api(String path, {CancellationToken? cancel}) async {
    if (token.trim().isEmpty) throw const ProviderException('not_configured');
    return object(
      await http.requestJson(
        Uri.parse('https://api.genius.com$path'),
        headers: {'Authorization': 'Bearer ${token.trim()}'},
        cancel: cancel,
      ),
    );
  }

  static SongCandidate parseSong(dynamic raw) {
    final data = object(raw), artist = jsonMap(object(raw)['primary_artist']);
    final url = httpsUrl(data['url']);
    if (url == null ||
        !{'genius.com', 'www.genius.com'}.contains(Uri.parse(url).host)) {
      throw const ProviderException('invalid_response');
    }
    final album = jsonMap(data['album']);
    final credits = <JsonMap>[];
    for (final entry in {
      'primary_artists': 'Artist',
      'featured_artists': 'Featured artist',
      'writer_artists': 'Writer',
      'producer_artists': 'Producer',
    }.entries) {
      for (final person in data[entry.key] is List ? data[entry.key] : []) {
        credits.add({'role': entry.value, 'name': jsonMap(person)['name']});
      }
    }
    for (final performance
        in data['custom_performances'] is List
            ? data['custom_performances']
            : []) {
      final p = jsonMap(performance);
      for (final person in p['artists'] is List ? p['artists'] : []) {
        credits.add({'role': p['label'], 'name': jsonMap(person)['name']});
      }
    }
    final meta = sanitizeMetadata({
      'album': album['name'],
      'artworkUrl':
          httpsUrl(album['cover_art_url'], hosts: geniusImageHosts) ??
          httpsUrl(data['song_art_image_url'], hosts: geniusImageHosts) ??
          httpsUrl(data['header_image_url'], hosts: geniusImageHosts),
      'releaseDate': data['release_date'],
      'language': data['language'],
      'credits': credits,
      'year': int.tryParse(
        (clean(data['release_date']) ?? '').split('-').first,
      ),
      'mediaLinks': [
        for (final m in data['media'] is List ? data['media'] : [])
          {
            'kind': jsonMap(m)['type'] ?? 'media',
            'label': jsonMap(m)['provider'],
            'url': jsonMap(m)['url'],
          },
        {
          'kind': 'audio',
          'label': 'Apple Music',
          'url': data['apple_music_player_url'],
        },
      ],
    });
    return SongCandidate(
      providerId: 'genius',
      id: numericId(data['id']),
      title: requiredText(data['title']),
      artist: requiredText(artist['name']),
      album: clean(album['name']),
      url: url,
      metadata: meta,
    );
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final data = await _api(
      '/search?${Uri(queryParameters: {'q': queryText(query)}).query}',
      cancel: cancel,
    );
    return parseRows(
      array(
        jsonMap(data['response'])['hits'],
      ).where((h) => jsonMap(h)['type'] == 'song'),
      (h) => parseSong(jsonMap(h)['result']),
    );
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final data = await _api(
      '/songs/${numericId(candidate.id)}',
      cancel: cancel,
    );
    final song = parseSong(jsonMap(data['response'])['song']);
    if (song.id != candidate.id) {
      throw const ProviderException('invalid_response');
    }
    final text = await http.getText(Uri.parse(song.url!), cancel: cancel);
    return lyricsResult(song, extractLyrics(text), attribution: 'Genius');
  }

  static String extractLyrics(String source) {
    final document = parseHtml(source);
    // Fallback selectors keep extraction working across Genius layout variants.
    var containers = <Element>[];
    for (final selector in const [
      '[data-lyrics-container="true"]',
      '[class*="Lyrics__Container"]',
      '.lyrics',
      '#lyrics-root',
    ]) {
      containers = document.querySelectorAll(selector);
      if (containers.isNotEmpty) break;
    }
    final parts = <String>[];
    for (final container in containers) {
      var parent = container.parent;
      var nested = false;
      while (parent != null) {
        if (parent.attributes['data-lyrics-container'] == 'true' ||
            (parent.attributes['class'] ?? '').contains('Lyrics__Container')) {
          nested = true;
        }
        parent = parent.parent;
      }
      if (nested) continue;
      if (htmlTooDeep(container)) continue;
      final node = container.clone(true);
      for (final removed in node.querySelectorAll(
        'script,style,noscript,iframe,svg,button,form,h1,h2,[hidden],[aria-hidden="true"],[data-exclude-from-selection="true"]',
      )) {
        removed.remove();
      }
      for (final br in node.querySelectorAll('br')) {
        br.replaceWith(Text('\n'));
      }
      for (final block in node.querySelectorAll('div,p')) {
        block.append(Text('\n'));
      }
      final text = node.text
          .replaceAll('\u00a0', ' ')
          .split('\n')
          .map((l) => l.trim())
          .join('\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      if (text.isNotEmpty) parts.add(text);
    }
    if (parts.isEmpty) {
      throwIfBlocked(source);
      throw const ProviderException('extraction_failed');
    }
    return meaningfulLyrics(parts.join('\n\n'));
  }
}

class LrclibProvider implements LyricsProvider {
  LrclibProvider(this.http);
  final ProviderTransport http;
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'lrclib',
    name: 'LRCLIB',
    capabilities: {'catalog', 'lyrics', 'lineTiming', 'metadata'},
    website: 'https://lrclib.net',
  );
  static SongCandidate parseSong(dynamic raw) {
    final data = object(raw), id = numericId(object(raw)['id']);
    return SongCandidate(
      providerId: 'lrclib',
      id: id,
      title: requiredText(data['trackName']),
      artist: requiredText(data['artistName']),
      album: clean(data['albumName']),
      durationSeconds: durationValue(data['duration']),
      url: 'https://lrclib.net/api/get/$id',
      metadata: {
        ...sanitizeMetadata({
          'album': data['albumName'],
          'duration': data['duration'],
        }),
        'instrumental': data['instrumental'] == true,
        'hasLyrics':
            clean(data['plainLyrics'], 200000) != null ||
            clean(data['syncedLyrics'], 200000) != null,
      },
    );
  }

  Future<JsonMap> record(String id, {CancellationToken? cancel}) async =>
      object(
        await http.requestJson(
          Uri.parse('https://lrclib.net/api/get/${numericId(id)}'),
          cancel: cancel,
        ),
      );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => parseRows(
    array(
      await http.requestJson(
        Uri.https('lrclib.net', '/api/search', {'q': queryText(query)}),
        cancel: cancel,
      ),
    ),
    parseSong,
  );
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final data = await record(candidate.id, cancel: cancel),
        song = parseSong(data);
    if (song.id != candidate.id) {
      throw const ProviderException('invalid_response');
    }
    final rawVariants = {
      'plain': ?_preservedLyricsVariant(data['plainLyrics']),
      'synced': ?_preservedLyricsVariant(data['syncedLyrics']),
    };
    final raw = clean(data['syncedLyrics'], 200000);
    final timing = raw == null
        ? null
        : parseLrc(
            raw,
            sourceDocumentId: song.identity,
            recordingId: song.identity,
          );
    final plain = clean(data['plainLyrics'], 200000) ?? '';
    final choices = <String>[
      if (timing != null && _canSupplyLyrics(timing)) timing.sourceLyrics,
    ];
    final selectedLyrics = preferCompatibleLyrics(plain, choices);
    final result = lyricsResult(
      song,
      selectedLyrics,
      timing: timing == null ? [] : [timing],
      attribution: 'LRCLIB',
    );
    return _withLyricsVariants(
      result,
      rawVariants: rawVariants,
      selected: choices.isNotEmpty && (plain.isEmpty || selectedLyrics != plain)
          ? 'synced'
          : 'plain',
    );
  }
}

class LyricsOvhProvider implements LyricsProvider {
  LyricsOvhProvider(this.http);
  final ProviderTransport http;
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'lyricsovh',
    name: 'Lyrics.ovh',
    capabilities: {'catalog', 'lyrics', 'metadata'},
    website: 'https://lyrics.ovh',
  );
  static String? _url(dynamic value, [Set<String>? hosts]) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    if (uri != null &&
        uri.scheme == 'http' &&
        {
          'www.deezer.com',
          'deezer.com',
          'api.deezer.com',
          'cdn-images.dzcdn.net',
          'cdnt-preview.dzcdn.net',
        }.contains(uri.host)) {
      return httpsUrl(uri.replace(scheme: 'https').toString(), hosts: hosts);
    }
    return httpsUrl(value, hosts: hosts);
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final data = object(
      await http.requestJson(
        Uri(
          scheme: 'https',
          host: 'api.lyrics.ovh',
          pathSegments: ['suggest', queryText(query)],
        ),
        cancel: cancel,
      ),
    );
    return parseRows(array(data['data']), (value) {
      final d = object(value), album = jsonMap(object(value)['album']);
      final song = SongCandidate(
        providerId: 'lyricsovh',
        id: numericId(d['id']),
        title: requiredText(d['title']),
        artist: requiredText(jsonMap(d['artist'])['name']),
        album: clean(album['title']),
        durationSeconds: durationValue(d['duration']),
        metadata: sanitizeMetadata({
          'album': album['title'],
          'duration': d['duration'],
          'recording': d['title_version'],
          'releaseDate': d['release_date'],
          'artworkUrl':
              _url(album['cover_xl'], deezerImageHosts) ??
              _url(album['cover_big'], deezerImageHosts) ??
              _url(album['cover_medium'], deezerImageHosts),
          'mediaLinks': [
            {'kind': 'audio', 'label': 'Deezer', 'url': _url(d['link'])},
            {
              'kind': 'preview',
              'label': 'Deezer preview',
              'url': _url(d['preview']),
            },
          ],
        }),
      );
      return copyCandidate(song, id: encodeSelection(song));
    });
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final selected = decodeSelection(candidate.id, 'lyricsovh');
    final url = Uri(
      scheme: 'https',
      host: 'api.lyrics.ovh',
      pathSegments: ['v1', selected.artist, selected.title],
    );
    final data = object(await http.requestJson(url, cancel: cancel));
    return lyricsResult(
      copyCandidate(selected, id: candidate.id, url: url.toString()),
      meaningfulLyrics(data['lyrics']),
      attribution: 'Lyrics.ovh',
    );
  }
}

class SyncLrcProvider implements LyricsProvider {
  SyncLrcProvider(this.http);
  final ProviderTransport http;
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'synclrc',
    name: 'SyncLRC',
    capabilities: {'catalog', 'lyrics', 'lineTiming', 'wordTiming', 'metadata'},
    website: 'https://synclrc.dev',
  );
  Future<List<JsonMap>> _records(
    String query, {
    CancellationToken? cancel,
  }) async {
    final data = object(
      await http.requestJson(
        // This API treats form-style '+' as a literal plus in search terms.
        Uri.https(
          'api.synclrc.dev',
          '/search',
        ).replace(query: 'q=${Uri.encodeComponent(queryText(query))}&limit=10'),
        cancel: cancel,
      ),
    );
    // Rows that are not objects are dropped individually.
    return [
      for (final row in array(data['results']))
        if (row is Map) object(row),
    ];
  }

  SongCandidate _song(JsonMap data, String query) {
    final id = requiredText(data['id']);
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(id)) {
      throw const ProviderException('invalid_response');
    }
    final lyrics = object(data['lyrics']);
    final song = SongCandidate(
      providerId: 'synclrc',
      id: id,
      title: requiredText(data['track']),
      artist: requiredText(data['artist']),
      album: clean(data['album']),
      durationSeconds: durationValue(data['duration']),
      url: 'https://synclrc.dev',
      metadata: {
        ...sanitizeMetadata({
          'album': data['album'],
          'duration': data['duration'],
        }),
        'query': query,
        'instrumental': data['instrumental'] == true,
        'hasLyrics': [
          'plain',
          'synced',
          'karaoke',
        ].any((k) => clean(lyrics[k], 200000) != null),
      },
    );
    return copyCandidate(song, id: encodeSelection(song));
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final rows = await _records(query, cancel: cancel);
    return parseRows(rows, (d) => _withRecord(object(d), query));
  }

  /// Largest compressed record (base64url characters) carried in a selection.
  /// The whole selection id is limited to 16384 characters and is itself
  /// base64url-encoded JSON, so this leaves room for the other fields.
  static const _recordLimit = 8000;

  /// SyncLRC has no get-by-id endpoint, so the chosen record travels inside
  /// the selection id (gzip + base64url) and resolve needs no second search.
  /// A record too large for the id is not carried; resolve then searches again.
  SongCandidate _withRecord(JsonMap row, String query) {
    final song = _song(row, query);
    final lyrics = object(row['lyrics']);
    final record = <String, Object?>{
      'id': row['id'],
      'track': row['track'],
      'artist': row['artist'],
      'album': row['album'],
      'duration': row['duration'],
      'instrumental': row['instrumental'] == true,
      'lyrics': {
        for (final k in ['plain', 'synced', 'karaoke'])
          if (lyrics[k] is String) k: lyrics[k],
      },
    };
    final blob = base64Url
        .encode(gzip.encode(utf8.encode(jsonEncode(record))))
        .replaceAll('=', '');
    if (blob.length > _recordLimit) return song;
    return copyCandidate(
      song,
      id: encodeSelection(
        SongCandidate(
          providerId: song.providerId,
          // `song.id` is already an encoded selection; the inner one is the
          // record id, as in a plain selection.
          id: requiredText(row['id']),
          title: song.title,
          artist: song.artist,
          album: song.album,
          durationSeconds: song.durationSeconds,
          url: song.url,
          metadata: {...song.metadata, _recordKey: blob},
        ),
      ),
    );
  }

  static const _recordKey = 'record';

  JsonMap? _carriedRecord(SongCandidate selected) {
    final blob = selected.metadata[_recordKey];
    if (blob is! String) return null;
    try {
      final data = object(
        jsonDecode(
          utf8.decode(gzip.decode(base64Url.decode(base64Url.normalize(blob)))),
        ),
      );
      return data['id'] == selected.id ? data : null;
    } catch (_) {
      return null;
    }
  }

  /// SyncLRC exposes only its search endpoint (its host also answers plain
  /// clients with a Cloudflare challenge, so no get-by-id route could be
  /// confirmed). When the selection carries the chosen record, resolve uses it
  /// directly. Otherwise (a record too large for the id) it searches again:
  /// first with the original query, then with an exact "title artist" query so
  /// the record is found even when the original query ranked it outside the
  /// top ten.
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final selected = decodeSelection(candidate.id, 'synclrc'),
        original = requiredText(selected.metadata['query'], 200);
    final carried = _carriedRecord(selected);
    if (carried != null) {
      final result = _resolveFrom([carried], original, candidate, selected);
      if (result != null) return result;
    }
    final exact = '${selected.title} ${selected.artist}';
    final queries = <String>{
      original,
      if (exact.trim().isNotEmpty && exact.length <= 200) exact,
    };
    for (final query in queries) {
      final result = _resolveFrom(
        await _records(query, cancel: cancel),
        query,
        candidate,
        selected,
      );
      if (result != null) return result;
    }
    throw const ProviderException('unavailable');
  }

  SourceResult? _resolveFrom(
    List<JsonMap> rows,
    String query,
    SongCandidate candidate,
    SongCandidate selected,
  ) {
    for (final row in rows) {
      if (row['id'] != selected.id) continue;
      final SongCandidate song;
      try {
        // The encoded id embeds the query, so keep the caller's selection id.
        song = copyCandidate(_song(row, query), id: candidate.id);
      } on ProviderException {
        continue;
      }
      final lyrics = object(row['lyrics']), timing = <TimingTrack>[];
      final rawVariants = {
        'plain': ?_preservedLyricsVariant(lyrics['plain']),
        'synced': ?_preservedLyricsVariant(lyrics['synced']),
        'karaoke': ?_preservedLyricsVariant(lyrics['karaoke']),
      };
      for (final field in ['synced', 'karaoke']) {
        final raw = clean(lyrics[field], 200000);
        if (raw != null && !timing.any((t) => t.raw == raw)) {
          timing.add(
            parseLrc(
              raw,
              sourceDocumentId: '${song.identity}:$field',
              recordingId: selected.identity,
            ),
          );
        }
      }
      final plain = clean(lyrics['plain'], 200000) ?? '';
      final choices = [
        for (final track in timing)
          if (_canSupplyLyrics(track)) track.sourceLyrics,
      ];
      final selectedLyrics = preferCompatibleLyrics(plain, choices);
      TimingTrack? chosenTrack;
      if (plain.isEmpty || selectedLyrics != plain) {
        for (final track in timing) {
          if (_canSupplyLyrics(track) && track.sourceLyrics == selectedLyrics) {
            chosenTrack = track;
            break;
          }
        }
      }
      final result = lyricsResult(
        song,
        selectedLyrics,
        timing: timing,
        attribution: 'SyncLRC',
      );
      return _withLyricsVariants(
        result,
        rawVariants: rawVariants,
        selected: chosenTrack != null
            ? (chosenTrack.sourceDocumentId.endsWith(':karaoke')
                  ? 'karaoke'
                  : 'synced')
            : 'plain',
      );
    }
    return null;
  }
}

class BetterLyricsProvider implements LyricsProvider {
  BetterLyricsProvider(this.http) : catalog = LrclibProvider(http);
  final ProviderTransport http;
  final LrclibProvider catalog;
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'betterlyrics',
    name: 'Better Lyrics',
    capabilities: {'catalog', 'lyrics', 'lineTiming', 'wordTiming', 'metadata'},
    website: 'https://better-lyrics.boidu.dev',
  );
  SongCandidate _song(SongCandidate s) => copyCandidate(
    s,
    providerId: 'betterlyrics',
    url: 'https://better-lyrics.boidu.dev',
    metadata: {...s.metadata}..remove('hasLyrics'),
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => (await catalog.search(query, cancel: cancel)).map(_song).toList();
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final song = _song(
      LrclibProvider.parseSong(
        await catalog.record(candidate.id, cancel: cancel),
      ),
    );
    if (song.id != candidate.id) {
      throw const ProviderException('invalid_response');
    }
    if (song.album == null || song.durationSeconds == null) {
      throw const ProviderException('unavailable');
    }
    final Object? response;
    try {
      response = await http.requestJson(
        Uri.https('api.betterlyrics.org', '/getLyrics', {
          's': song.title,
          'a': song.artist,
          'al': song.album!,
          'd': song.durationSeconds!.round().toString(),
        }),
        cancel: cancel,
      );
    } on ProviderException catch (e) {
      // Without an API key the service answers only songs it has cached; any
      // other song is refused, which means it is not available here.
      if (e.code == 'access_denied') {
        throw const ProviderException('unavailable');
      }
      rethrow;
    }
    final data = object(response);
    final raw = requiredText(data['ttml'], 200000);
    // Keep the original TTML and word/span cues; never flatten it to LRC.
    final timing = parseTtml(
      raw,
      sourceDocumentId: song.identity,
      recordingId: song.identity,
    );
    return lyricsResult(
      song,
      timing.sourceLyrics,
      timing: [timing],
      attribution: 'Better Lyrics',
    );
  }
}
