import '../../domain/models.dart';
import '../provider.dart';
import 'common.dart';

/// The transport already sends the versioned Singbook User-Agent (with the
/// configured contact URL); no per-adapter override is needed.
const _metadataHeaders = <String, String>{};

class MusicBrainzProvider implements LyricsProvider {
  MusicBrainzProvider(this.transport);
  final ProviderTransport transport;
  // MusicBrainz requires <= 1 request/second per client. The shared transport's
  // generic host pacing is faster, so this adapter serializes its own requests.
  Future<void> _queue = Future.value();
  DateTime _next = DateTime.fromMillisecondsSinceEpoch(0);
  @override
  final definition = const ProviderDefinition(
    id: 'musicbrainz',
    name: 'MusicBrainz',
    capabilities: {'catalog', 'metadata'},
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

  SongCandidate _candidate(JsonMap r) {
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
      metadata: sanitizeExtraMetadata({
        'identityScope': 'recording',
        if (stringValue(r['disambiguation']).isNotEmpty)
          'version': r['disambiguation'],
        'artistCredits': credits
            .map(
              (c) => {
                'name': c['name'],
                'musicbrainzId': jsonMap(c['artist'])['id'],
              },
            )
            .toList(),
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
        .map(_candidate)
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
      final matches =
          (await search(
                'recording:"${escaped(candidate.title)}" AND artist:"${escaped(candidate.artist)}"',
                cancel: cancel,
              ))
              .where(
                (c) =>
                    normalized(c.title) == normalized(candidate.title) &&
                    normalized(c.artist) == normalized(candidate.artist),
              )
              .where(
                (c) =>
                    candidate.durationSeconds == null ||
                    c.durationSeconds == null ||
                    (candidate.durationSeconds! - c.durationSeconds!).abs() <=
                        2,
              )
              .where(
                (c) =>
                    candidate.album == null ||
                    maps(c.metadata['releases']).any(
                      (r) =>
                          normalized(stringValue(r['title'])) ==
                          normalized(candidate.album!),
                    ),
              )
              .toList();
      if (matches.isEmpty) throw const ProviderException('unavailable');
      if (matches.length != 1) throw const ProviderException('ambiguous_match');
      id = matches.single.id;
    }
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
    final found = _candidate(data);
    final metadata = <String, dynamic>{
      ...found.metadata,
      if (found.durationSeconds != null)
        'durationSeconds': found.durationSeconds,
      if (found.album != null) 'album': found.album,
      if (data['isrcs'] is List) 'isrcs': data['isrcs'],
      'musicbrainzRecordingId': id,
      'relationships': maps(data['relations']),
    };
    return SourceResult(
      candidate: found,
      body: '',
      metadata: sanitizeExtraMetadata(metadata),
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
    CancellationToken? cancel,
  ) async {
    final entities = await _entities(ids, cancel);
    final works = entities.entries
        .where(
          (entry) =>
              entry.value['missing'] == null &&
              entityClaims(
                entry.value,
                'P31',
              ).any(_compositionTypes.contains) &&
              !entityClaims(
                entry.value,
                'P31',
              ).any(_nonCompositionTypes.contains),
        )
        .toList();
    if (works.isEmpty) return [];
    final related = works
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
    return works
        .map((e) {
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
          final metadata = <String, dynamic>{
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
          return SongCandidate(
            providerId: definition.id,
            id: e.key,
            title: entityLabel(e.value),
            // Work authorship is independent of the many recordings/covers
            // linked through P175; retain performers separately as metadata.
            artist: creators.join(', '),
            url: 'https://www.wikidata.org/wiki/${e.key}',
            metadata: sanitizeExtraMetadata(metadata),
          );
        })
        .where((c) => c.title.isNotEmpty)
        .toList();
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
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
    return _candidates(ids, cancel);
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final exactId = candidate.providerId == definition.id
        ? candidate.id
        : candidate.recordingIds['wikidata'] ??
              stringValue(candidate.metadata['wikidataId']);
    List<SongCandidate> found;
    if (exactId.isNotEmpty) {
      found = await _candidates([exactId], cancel);
    } else {
      found = (await search(candidate.title, cancel: cancel))
          .where(
            (r) =>
                normalized(r.title) == normalized(candidate.title) &&
                r.artist.isNotEmpty &&
                normalized(r.artist) == normalized(candidate.artist),
          )
          .toList();
    }
    if (found.isEmpty) throw const ProviderException('unavailable');
    if (found.length != 1) throw const ProviderException('ambiguous_match');
    final result = found.single;
    return SourceResult(
      candidate: result,
      body: '',
      metadata: result.metadata,
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
        'identityScope': 'composition',
      },
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
