import 'dart:convert';

import '../../domain/models.dart';
import '../core/common.dart' show meaningfulLyrics, plainToChordPro;
import '../provider.dart';
import 'common.dart'
    show normalized, queryText, remoteChordPro, sanitizeExtraMetadata;

/// Fixed first-party provider identities for the VocaDB family APIs.
/// A database entry identifies a source song/version, not a confirmed
/// recording. Database metadata is CC BY 4.0; lyrics and artwork are excluded.
enum _Database {
  vocadb('vocadb', 'VocaDB', 'vocadb.net', 'vocadbSongId', 'vocadb'),
  touhoudb(
    'touhoudb',
    'TouhouDB',
    'touhoudb.com',
    'touhoudbSongId',
    'touhoudb',
  ),
  utaitedb(
    'utaitedb',
    'UtaiteDB',
    'utaitedb.net',
    'utaitedbSongId',
    'utaitedb',
  );

  const _Database(this.id, this.name, this.host, this.factKey, this.extraKey);
  final String id;
  final String name;
  final String host;
  final String factKey;
  final String extraKey;
}

abstract class _VocaDbFamilyProvider
    implements
        LyricsProvider,
        ContextualLyricsSearch,
        PublishedTitleAliasEvidence {
  _VocaDbFamilyProvider._(
    this._database,
    this.transport, {
    this.requestInterval = const Duration(seconds: 1),
    this.cacheLifetime = const Duration(minutes: 15),
  });

  final _Database _database;

  /// Public HTTPS API: https://wiki.vocadb.net/docs/public-api.
  /// A VocaDB-family entry identifies a source song/version, not a recording.
  final ProviderTransport transport;
  final Duration requestInterval;
  final Duration cacheLifetime;
  Future<void> _queue = Future.value();
  DateTime _next = DateTime.fromMillisecondsSinceEpoch(0);
  final _documents =
      <String, ({String raw, DateTime retrievedAt, DateTime expiresAt})>{};

  static const _fields =
      'Names,Artists,Albums,Bpm,CultureCodes,Lyrics,WebLinks';
  static const _maxBytes = 2 * 1024 * 1024;

  @override
  late final ProviderDefinition definition = ProviderDefinition(
    id: _database.id,
    name: _database.name,
    capabilities: const {'catalog', 'lyrics', 'metadata'},
    accessMode: 'publicApi',
    website: 'https://${_database.host}/',
  );

  String get _host => _database.host;

  Future<String> _get(Uri uri, CancellationToken? cancel) {
    final result = _queue.then((_) async {
      cancel?.throwIfCancelled();
      final wait = _next.difference(DateTime.now());
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      cancel?.throwIfCancelled();
      try {
        return await transport.getText(
          uri,
          maxBytes: _maxBytes,
          allowedHosts: {_host},
          cancel: cancel,
        );
      } finally {
        _next = DateTime.now().add(requestInterval);
      }
    });
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  JsonMap _object(Object? value) {
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw const ProviderException('invalid_response');
    }
    return Map<String, dynamic>.from(value);
  }

  JsonMap _decode(String raw) {
    try {
      return _object(jsonDecode(raw));
    } on FormatException {
      throw const ProviderException('invalid_response');
    }
  }

  String _text(Object? value, {int max = 500, bool multiline = false}) {
    if (value is! String ||
        value.trim().isEmpty ||
        value.length > max ||
        RegExp(
          r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f\u202a-\u202e\u2066-\u2069]',
        ).hasMatch(value) ||
        (!multiline && RegExp(r'[\t\r\n]').hasMatch(value))) {
      throw const ProviderException('invalid_response');
    }
    return value.trim();
  }

  String _id(Object? value) {
    final id = value is int ? value.toString() : value;
    if (id is! String || !RegExp(r'^[1-9][0-9]{0,9}$').hasMatch(id)) {
      throw const ProviderException('invalid_response');
    }
    return id;
  }

  List<JsonMap> _rows(Object? value, {int max = 100}) {
    if (value == null) return [];
    if (value is! List || value.length > max) {
      throw const ProviderException('invalid_response');
    }
    return value.map(_object).toList();
  }

  List<String> _cultures(Object? value) {
    if (value == null) return [];
    if (value is! List || value.length > 30) {
      throw const ProviderException('invalid_response');
    }
    return value.map((v) => _text(v, max: 40)).toList();
  }

  SongCandidate _candidate(JsonMap data) {
    if (data['deleted'] == true || data['mergedTo'] != null) {
      throw const ProviderException('unavailable');
    }
    final id = _id(data['id']);
    final title = _text(data['name'], max: 300);
    final artist = _text(data['artistString']);
    final names = _rows(data['names']);
    final aliases = names.map((row) => _text(row['value'], max: 300)).toList();
    final artists = _rows(data['artists']);
    final albums = _rows(data['albums']);
    final albumNames = albums.map((row) => _text(row['name'])).toSet();
    final cultures = _cultures(data['cultureCodes']);
    final length = data['lengthSeconds'];
    if (length != null && (length is! int || length < 0 || length >= 86400)) {
      throw const ProviderException('invalid_response');
    }
    final minimum = data['minMilliBpm'];
    final maximum = data['maxMilliBpm'];
    final fixedTempo =
        minimum is int &&
        maximum == minimum &&
        minimum >= 20000 &&
        minimum <= 500000;
    final metadata = sanitizeExtraMetadata({
      'identityScope': 'arrangement',
      _database.factKey: id,
      'sourceSongType': _text(data['songType'], max: 50),
      if (albumNames.length == 1) 'album': albumNames.single,
      if (length is int && length > 0) 'durationSeconds': length,
      if (fixedTempo) 'tempo': minimum / 1000,
      if (cultures.length == 1) 'language': cultures.single,
      // Roles are explicit source declarations. A vocalist, illustrator or
      // database editor must not be inferred to be the composer or lyricist.
      for (final role in const ['Composer', 'Lyricist'])
        if (artists.any(
          (row) =>
              (row['roles'] is String) &&
              (row['roles'] as String)
                  .split(',')
                  .map((v) => v.trim())
                  .contains(role),
        ))
          role.toLowerCase(): artists
              .where(
                (row) =>
                    row['roles'] is String &&
                    (row['roles'] as String)
                        .split(',')
                        .map((v) => v.trim())
                        .contains(role),
              )
              .map((row) => _text(row['name']))
              .join(', '),
    });
    return SongCandidate(
      providerId: definition.id,
      id: id,
      title: title,
      artist: artist,
      album: albumNames.length == 1 ? albumNames.single : null,
      durationSeconds: length is int && length > 0 ? length.toDouble() : null,
      url: 'https://$_host/S/$id',
      metadata: metadata,
      extra: {
        'sourceTitleAliases': aliases,
        'sourceNames': names,
        'sourceArtistRoles': artists,
        'sourceAlbums': albums,
        'sourceCultureCodes': cultures,
      },
    );
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) => _search(query, matchMode: 'Auto', sort: 'RatingScore', cancel: cancel);

  Future<List<SongCandidate>> _search(
    String query, {
    required String matchMode,
    required String sort,
    CancellationToken? cancel,
  }) async {
    final text = queryText(query);
    if (text.isEmpty) return [];
    final data = _decode(
      await _get(
        Uri.https(_host, '/api/songs', {
          'query': text,
          'fields': 'Names,Artists,Albums,Bpm,CultureCodes',
          'lang': 'English',
          'nameMatchMode': matchMode,
          'sort': sort,
          'maxResults': '12',
          'getTotalCount': 'false',
        }),
        cancel,
      ),
    );
    if (data['items'] is! List) {
      throw const ProviderException('invalid_response');
    }
    final rows = _rows(data['items'], max: 12);
    final candidates = <SongCandidate>[];
    for (final row in rows) {
      if (row['deleted'] == true || row['mergedTo'] != null) continue;
      candidates.add(_candidate(row));
    }
    return candidates;
  }

  bool _sameSelection(SongCandidate selected, SongCandidate found) {
    final aliases = found.extra['sourceTitleAliases'];
    final albums = found.extra['sourceAlbums'];
    if (aliases is! List || albums is! List) return false;
    return (selected.album == null ||
            selected.album!.trim().isEmpty ||
            albums.whereType<Map>().any(
              (row) =>
                  row['name'] is String &&
                  normalized(row['name'] as String) ==
                      normalized(selected.album!),
            )) &&
        (selected.durationSeconds == null ||
            found.durationSeconds == null ||
            (selected.durationSeconds! - found.durationSeconds!).abs() <= 3) &&
        (normalized(selected.title) == normalized(found.title) ||
            aliases.whereType<String>().any(
              (v) => normalized(v) == normalized(selected.title),
            )) &&
        normalized(selected.artist) == normalized(found.artist);
  }

  @override
  String? publishedTitleAliasForSelection(
    SongCandidate selection,
    SongCandidate candidate,
  ) {
    if (candidate.providerId != definition.id ||
        !_sameSelection(selection, candidate)) {
      return null;
    }
    final aliases = candidate.extra['sourceTitleAliases'];
    if (aliases is! List) return null;
    for (final alias in aliases.whereType<String>()) {
      if (normalized(alias) == normalized(selection.title) &&
          normalized(alias) != normalized(candidate.title)) {
        return alias;
      }
    }
    return null;
  }

  @override
  bool canReuseSearchForSelection(
    SongCandidate selection,
    List<SongCandidate> candidates,
  ) => candidates.any(
    (row) => row.providerId == definition.id && _sameSelection(selection, row),
  );

  @override
  Future<List<SongCandidate>> searchForSelection(
    SongCandidate selection, {
    required String fallbackQuery,
    CancellationToken? cancel,
  }) async {
    // The API query searches song names, not a concatenated artist credit.
    // Apply artist/album/duration checks to the complete structured rows, then
    // leave the normal service's independent identity checks in place.
    final title = queryText(selection.title);
    final query = title.isEmpty ? fallbackQuery : title;
    final rows = await _search(
      query,
      matchMode: 'Auto',
      sort: 'RatingScore',
      cancel: cancel,
    );
    final matches = rows
        .where((row) => _sameSelection(selection, row))
        .toList();
    if (matches.isNotEmpty) return matches;

    // RatingScore can crowd an exact arrangement out of a popular title's
    // first page. Try one bounded name-sorted exact query, then apply the same
    // complete title, artist, album and duration checks before returning it.
    final exactRows = await _search(
      query,
      matchMode: 'Exact',
      sort: 'Name',
      cancel: cancel,
    );
    return exactRows.where((row) => _sameSelection(selection, row)).toList();
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (candidate.providerId != definition.id) {
      throw const ProviderException('unavailable');
    }
    final id = _id(candidate.id);
    cancel?.throwIfCancelled();
    final entry = _documents[id];
    final cached = entry != null && DateTime.now().isBefore(entry.expiresAt)
        ? entry.raw
        : null;
    final raw =
        cached ??
        await _get(
          Uri.https(_host, '/api/songs/$id', {
            'fields': _fields,
            'lang': 'English',
          }),
          cancel,
        );
    cancel?.throwIfCancelled();
    final retrievedAt = cached == null
        ? DateTime.now().toUtc()
        : entry!.retrievedAt;
    final data = _decode(raw);
    final found = _candidate(data);
    if (found.id != id || !_sameSelection(candidate, found)) {
      throw const ProviderException('identity_mismatch');
    }
    final lyrics = _rows(data['lyrics'], max: 30);
    final originals = lyrics
        .where((row) => row['translationType'] == 'Original')
        .toList();
    if (originals.length != 1) {
      throw ProviderException(
        originals.isEmpty ? 'unavailable' : 'ambiguous_match',
      );
    }
    final original = originals.single;
    final lyricId = _id(original['id']);
    final text = _text(original['value'], max: 256 * 1024, multiline: true);
    final body = remoteChordPro(plainToChordPro(meaningfulLyrics(text)));
    if (body.trim().isEmpty) throw const ProviderException('unavailable');
    final attribution = '${_database.name} — ${found.url}';
    final result = SourceResult(
      candidate: found,
      body: body,
      metadata: found.metadata,
      attribution: attribution,
      retrievedAt: retrievedAt,
      extra: {
        'parserVersion': '${_database.id}-native-1',
        'sourceDocumentId': '${found.identity}:lyrics:$lyricId',
        'rights': {
          'source': definition.id,
          'sourceId': id,
          'sourceUrl': found.url,
          'license': 'unknown',
          'evidenceUrl': 'https://wiki.vocadb.net/docs/license',
          'attribution': attribution,
          'permissions': {
            'status': 'field_specific',
            'database': 'CC-BY-4.0',
            'lyrics': 'unknown',
            'artwork': 'unknown',
          },
          'provenanceNote':
              '${_database.name} database metadata is CC BY 4.0; third-party lyrics and images are expressly excluded. Metadata normalized for Singbook; original response and lyric source credits retained.',
        },
        'originalPayload': {
          'contentType': 'application/json',
          'encoding': 'utf-8',
          'base64': base64Encode(utf8.encode(raw)),
        },
        _database.extraKey: {
          'id': id,
          'version': data['version'],
          'publishDate': data['publishDate'],
          'names': found.extra['sourceNames'],
          'artists': found.extra['sourceArtistRoles'],
          'albums': found.extra['sourceAlbums'],
          'cultureCodes': found.extra['sourceCultureCodes'],
          'minMilliBpm': data['minMilliBpm'],
          'maxMilliBpm': data['maxMilliBpm'],
          'songType': data['songType'],
          'originalVersionId': data['originalVersionId'],
          'lyrics': lyrics,
          'selectedLyricId': lyricId,
          'webLinks': _rows(data['webLinks']),
        },
      },
    );
    if (cached == null) {
      _documents[id] = (
        raw: raw,
        retrievedAt: retrievedAt,
        expiresAt: DateTime.now().add(cacheLifetime),
      );
      if (_documents.length > 32) _documents.remove(_documents.keys.first);
    }
    return result;
  }
}

/// Native lyrics provider for VocaDB.
class VocaDbProvider extends _VocaDbFamilyProvider {
  VocaDbProvider(
    ProviderTransport transport, {
    Duration requestInterval = const Duration(seconds: 1),
    Duration cacheLifetime = const Duration(minutes: 15),
  }) : super._(
         _Database.vocadb,
         transport,
         requestInterval: requestInterval,
         cacheLifetime: cacheLifetime,
       );
}

/// Native lyrics provider for TouhouDB.
class TouhouDbProvider extends _VocaDbFamilyProvider {
  TouhouDbProvider(
    ProviderTransport transport, {
    Duration requestInterval = const Duration(seconds: 1),
    Duration cacheLifetime = const Duration(minutes: 15),
  }) : super._(
         _Database.touhoudb,
         transport,
         requestInterval: requestInterval,
         cacheLifetime: cacheLifetime,
       );
}

/// Native lyrics provider for UtaiteDB.
class UtaiteDbProvider extends _VocaDbFamilyProvider {
  UtaiteDbProvider(
    ProviderTransport transport, {
    Duration requestInterval = const Duration(seconds: 1),
    Duration cacheLifetime = const Duration(minutes: 15),
  }) : super._(
         _Database.utaitedb,
         transport,
         requestInterval: requestInterval,
         cacheLifetime: cacheLifetime,
       );
}
