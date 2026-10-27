import 'dart:convert';

import '../../domain/models.dart';
import '../../domain/timing.dart';
import '../provider.dart';
import '../core/common.dart'
    show clean, meaningfulLyrics, parseRows, plainToChordPro;
import 'common.dart'
    show normalized, queryText, sanitizeExtraMetadata, throwIfBlocked;

/// Bounded adapter for the public AMLL TTML lyrics database API.
/// Numeric document IDs identify lyric documents, not verified recordings.
class AmllProvider implements LyricsProvider, ContextualLyricsSearch {
  AmllProvider(
    this.transport, {
    this.requestInterval = const Duration(milliseconds: 150),
  });

  final ProviderTransport transport;
  final Duration requestInterval;
  Future<void> _queue = Future.value();
  DateTime _next = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, String> _documents = {};

  static const _host = 'api.amll.dev';
  static const _hosts = {_host};
  static const _maxBytes = 1024 * 1024;
  static const _maxId = 9007199254740991;
  static const _arrayLimit = 30;
  static const _maxLyricBytes = 512 * 1024;

  @override
  final definition = const ProviderDefinition(
    id: 'amll',
    name: 'AMLL Lyrics Database',
    capabilities: {'catalog', 'lyrics', 'metadata', 'lineTiming', 'wordTiming'},
    accessMode: 'publicApi',
    website: 'https://api.amll.dev/',
    enabledByDefault: false,
  );

  Future<T> _request<T>(Future<T> Function() send, CancellationToken? cancel) {
    final result = _queue.then((_) async {
      cancel?.throwIfCancelled();
      final wait = _next.difference(DateTime.now());
      if (wait > Duration.zero) {
        if (cancel == null) {
          await Future<void>.delayed(wait);
        } else {
          await Future.any([Future<void>.delayed(wait), cancel.cancelled]);
        }
      }
      cancel?.throwIfCancelled();
      try {
        return await send();
      } finally {
        _next = DateTime.now().add(requestInterval);
      }
    });
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static int _id(Object? value) {
    final int? id = value is int
        ? value
        : value is String && RegExp(r'^[1-9]\d{0,15}$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    if (id == null || id < 1 || id > _maxId || value is double) {
      throw const ProviderException('invalid_response');
    }
    return id;
  }

  static String _text(Object? value, {int max = 300}) {
    final valueClean = clean(value, max);
    if (value is String && value.length > max) {
      throw const ProviderException('invalid_response', 'too_large');
    }
    return valueClean ?? '';
  }

  static List<String> _names(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is! List || value.length > _arrayLimit) {
      throw const ProviderException('invalid_response');
    }
    final out = <String>[];
    for (final item in value) {
      final name = _text(item, max: 200);
      if (name.isEmpty) {
        throw const ProviderException('invalid_response');
      }
      out.add(name);
    }
    return out;
  }

  static String _filename(Object? value) {
    final filename = _text(value, max: 240);
    if (!RegExp(
      r'^[A-Za-z0-9][A-Za-z0-9._ -]*\.ttml$',
      caseSensitive: false,
    ).hasMatch(filename)) {
      throw const ProviderException('invalid_response');
    }
    return filename;
  }

  static String _artistIdentity(String value) => normalized(value);

  SongCandidate _candidate(Object? input, {required bool includeLyrics}) {
    if (input is! Map) {
      throw const ProviderException('invalid_response');
    }
    final data = Map<String, dynamic>.from(input);
    final id = _id(data['id']);
    // Current search rows omit format (as well as lyrics). Detail must still
    // declare TTML; an explicit contradictory search format is never accepted.
    if (data['format'] != 'ttml' &&
        (includeLyrics || data.containsKey('format'))) {
      throw const ProviderException('invalid_response');
    }
    final filename = _filename(data['filename']);
    final titles = _names(data, 'musicNames');
    final artists = _names(data, 'artistNames');
    if (titles.isEmpty || artists.isEmpty) {
      throw const ProviderException('invalid_response');
    }
    final albums = _names(data, 'albumNames');
    final ids = <String, List<String>>{};
    for (final field in const [
      'ncmMusicIds',
      'qqMusicIds',
      'appleMusicIds',
      'spotifyIds',
      'isrcs',
      'authorIds',
      'authorUsernames',
    ]) {
      ids[field] = _names(data, field);
    }
    if (includeLyrics && data['lyrics'] is! String) {
      throw const ProviderException('invalid_response');
    }
    final metadata = sanitizeExtraMetadata({
      // The ID identifies a lyric arrangement, not a verified audio recording.
      'identityScope': 'arrangement',
      'documentKind': 'lyricDocument',
      if (albums.isNotEmpty) 'album': albums.first,
      'sourceTitleAliases': titles,
      'albumAliases': albums,
      ...ids,
      if (data['format'] == 'ttml') 'format': 'ttml',
      'filename': filename,
      'mediaLinks': [
        {
          'kind': 'source',
          'label': 'AMLL Lyrics Database',
          'url': 'https://api.amll.dev/v1/lyrics/get?id=$id',
        },
      ],
    });
    return SongCandidate(
      providerId: definition.id,
      id: '$id',
      title: titles.first,
      artist: artists.join(' & '),
      album: albums.isNotEmpty ? albums.first : null,
      url: 'https://api.amll.dev/v1/lyrics/get?id=$id',
      metadata: metadata,
      extra: {
        'sourceTitleAliases': titles,
        'sourceArtistNames': artists,
        'sourceAlbumNames': albums,
        ...ids,
        'filename': filename,
      },
    );
  }

  Future<Map<String, dynamic>> _json(Uri uri, CancellationToken? cancel) async {
    final raw = await _request(
      () => transport.getText(
        uri,
        cancel: cancel,
        maxBytes: _maxBytes,
        allowedHosts: _hosts,
      ),
      cancel,
    );
    cancel?.throwIfCancelled();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['status'] != 200 ||
          decoded['data'] is! Map) {
        throw const ProviderException('invalid_response');
      }
      return Map<String, dynamic>.from(decoded['data'] as Map);
    } on ProviderException {
      rethrow;
    } catch (_) {
      throwIfBlocked(raw);
      throw const ProviderException('invalid_response');
    }
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final q = queryText(query);
    if (q.isEmpty) {
      return const [];
    }
    return _search({'q': q}, cancel);
  }

  @override
  bool canReuseSearchForSelection(
    SongCandidate selection,
    List<SongCandidate> candidates,
  ) => candidates.any(
    (row) =>
        row.providerId == definition.id && _selectionMatches(selection, row),
  );

  @override
  Future<List<SongCandidate>> searchForSelection(
    SongCandidate selection, {
    required String fallbackQuery,
    CancellationToken? cancel,
  }) {
    final title = clean(selection.title);
    if (title == null) return search(fallbackQuery, cancel: cancel);
    final artist = clean(selection.artist);
    // A combined collaboration credit is not one API artistName. Search the
    // title, then retain the service's full identity validation in that case.
    final collaboration =
        artist != null &&
        RegExp(
          r'\s(?:&|feat\.?|ft\.?|featuring)\s|,',
          caseSensitive: false,
        ).hasMatch(artist);
    return _search({
      'musicName': title,
      if (artist != null && !collaboration) 'artistName': artist,
      if (clean(selection.album) case final String album) 'albumName': album,
    }, cancel);
  }

  Future<List<SongCandidate>> _search(
    Map<String, String> parameters,
    CancellationToken? cancel,
  ) async {
    final data = await _json(
      Uri.https(_host, '/v1/lyrics/search', {
        ...parameters,
        'page': '1',
        'pageSize': '30',
      }),
      cancel,
    );
    if (data['items'] is! List || data['pagination'] is! Map) {
      throw const ProviderException('invalid_response');
    }
    final rows = data['items'] as List;
    if (rows.length > 30) {
      throw const ProviderException('invalid_response');
    }
    return parseRows(rows, (row) => _candidate(row, includeLyrics: false));
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (candidate.providerId != definition.id) {
      throw const ProviderException('invalid_selection');
    }
    final int id;
    try {
      id = _id(candidate.id);
    } on ProviderException {
      throw const ProviderException('invalid_selection');
    }
    final key = '$id';
    cancel?.throwIfCancelled();
    var raw = _documents[key];
    final wasCached = raw != null;
    raw ??= await _fetchDocument(key, cancel);
    cancel?.throwIfCancelled();
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const ProviderException('invalid_response');
    }
    if (decoded is! Map ||
        decoded['status'] != 200 ||
        decoded['data'] is! Map) {
      throw const ProviderException('invalid_response');
    }
    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    final found = _candidate(data, includeLyrics: true);
    if (found.id != key || !_selectionMatches(candidate, found)) {
      throw const ProviderException('identity_mismatch');
    }
    final ttml = data['lyrics'] as String;
    if (utf8.encode(ttml).length > _maxLyricBytes || ttml.trim().isEmpty) {
      throw const ProviderException('invalid_response');
    }
    final parsed = parseTtml(
      ttml,
      sourceDocumentId: found.identity,
      profile: 'amll-ttml',
    );
    final track = parsed.copyWith(
      extra: {
        ...parsed.extra,
        'recordingEvidence': 'sourceDemonstrationOnly',
        'sourceTimeline': 'AMLL lyric document; audio alignment unverified',
      },
    );
    if ({
          TimingStatus.invalid,
          TimingStatus.unsupported,
        }.contains(track.status) ||
        track.cues.isEmpty ||
        track.sourceLyrics.trim().isEmpty) {
      throw const ProviderException('invalid_response', 'unsupported_timing');
    }
    if (!wasCached) {
      _documents[key] = raw;
      if (_documents.length > 32) {
        _documents.remove(_documents.keys.first);
      }
    }
    final attribution =
        'AMLL TTML Database — ${found.extra['authorUsernames'] is List ? (found.extra['authorUsernames'] as List).join(', ') : 'contributors'} — ${found.url}';
    final extra = <String, dynamic>{
      'parserVersion': 'amll-native-1',
      'sourceDocumentId': found.identity,
      'rights': {
        'source': 'amll',
        'sourceId': key,
        'sourceUrl': found.url,
        'license': 'unknown',
        'evidenceUrl': 'https://amll.dev/guides/overview/eco',
        'provenanceNote':
            'The publisher states that its contributed database is CC0-1.0; '
            'this does not establish rights in underlying lyrics.',
        'attribution': attribution,
        'permissions': {
          'status': 'field_specific',
          'database': 'CC0-1.0',
          'lyrics': 'unknown',
          'attributionPolicy': 'Retained by Singbook',
        },
      },
      'originalPayload': {
        'contentType': 'application/json',
        'encoding': 'utf-8',
        'base64': base64Encode(utf8.encode(raw)),
      },
      'amll': {
        'id': key,
        'filename': found.extra['filename'],
        'musicNames': found.extra['sourceTitleAliases'],
        'artistNames': found.extra['sourceArtistNames'],
        'albumNames': found.extra['sourceAlbumNames'],
        for (final field in const [
          'ncmMusicIds',
          'qqMusicIds',
          'appleMusicIds',
          'spotifyIds',
          'isrcs',
          'authorIds',
          'authorUsernames',
        ])
          field: found.extra[field],
      },
    };
    return SourceResult(
      candidate: found,
      body: plainToChordPro(meaningfulLyrics(track.sourceLyrics)),
      metadata: found.metadata,
      timingTracks: [track],
      matchKind: MatchKind.unverified,
      attribution: attribution,
      retrievedAt: DateTime.now().toUtc(),
      extra: extra,
    );
  }

  Future<String> _fetchDocument(String id, CancellationToken? cancel) async {
    final raw = await _request(
      () => transport.getText(
        Uri.https(_host, '/v1/lyrics/get', {'id': id}),
        cancel: cancel,
        maxBytes: _maxBytes,
        allowedHosts: _hosts,
      ),
      cancel,
    );
    cancel?.throwIfCancelled();
    return raw;
  }

  static bool _selectionMatches(SongCandidate selected, SongCandidate found) {
    final aliases = found.extra['sourceTitleAliases'];
    if (aliases is! List || aliases.any((name) => name is! String)) {
      return false;
    }
    if (!aliases.any(
      (title) => normalized(title) == normalized(selected.title),
    )) {
      return false;
    }
    final selectedRaw = selected.extra['sourceArtistNames'];
    if (selectedRaw is List && selectedRaw.any((value) => value is! String)) {
      return false;
    }
    final foundRaw = found.extra['sourceArtistNames'];
    if (foundRaw is! List || foundRaw.any((value) => value is! String)) {
      return false;
    }
    final selectedArtists =
        (selectedRaw is List
                ? selectedRaw.cast<String>()
                : selected.artist.split(' & '))
            .map(_artistIdentity)
            .toList()
          ..sort();
    final foundArtists = foundRaw.cast<String>().map(_artistIdentity).toList()
      ..sort();
    if (selectedArtists.length != foundArtists.length ||
        selectedArtists.join('|') != foundArtists.join('|')) {
      return false;
    }
    if (selected.album != null) {
      final albums = found.extra['sourceAlbumNames'];
      if (albums is! List || albums.any((name) => name is! String)) {
        return false;
      }
      if (!albums.any(
        (album) => normalized(album) == normalized(selected.album!),
      )) {
        return false;
      }
    }
    return true;
  }
}
