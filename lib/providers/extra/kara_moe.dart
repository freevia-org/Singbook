import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/models.dart';
import '../../domain/arrangement.dart' show lyricOrderHash;
import '../provider.dart';
import '../core/common.dart' show meaningfulLyrics, plainToChordPro;
import 'common.dart'
    show
        normalized,
        queryText,
        remoteChordPro,
        sanitizeExtraMetadata,
        sourceEvidence,
        throwIfBlocked;

/// Search and line-timing access to kara.moe's public API. A KID identifies a
/// karaoke arrangement/video, not the underlying studio recording.
class KaraMoeProvider implements LyricsProvider {
  KaraMoeProvider(
    this.transport, {
    this.requestInterval = const Duration(seconds: 1),
  });

  final ProviderTransport transport;
  final Duration requestInterval;
  Future<void> _queue = Future.value();
  DateTime _next = DateTime.fromMillisecondsSinceEpoch(0);

  static const _host = 'kara.moe';
  static const _hosts = {_host};
  static const _searchLimit = 2 * 1024 * 1024;
  static const _detailLimit = 512 * 1024;
  static const _maxCues = 10000;
  static const _maxUs = 604800000000;
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  final definition = const ProviderDefinition(
    id: 'karamoe',
    name: 'kara.moe',
    capabilities: {'catalog', 'lyrics', 'metadata', 'lineTiming'},
    accessMode: 'publicApi',
    website: 'https://kara.moe/',
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

  static Uri _searchUrl(String query) => Uri.https(_host, '/api/karas/search', {
    'filter': query,
    'from': '0',
    'size': '12',
  });

  static Uri _detailUrl(String uuid) => Uri.https(_host, '/api/karas/$uuid');

  Future<String> _detail(String uuid, CancellationToken? cancel) => _request(
    () => transport.getText(
      _detailUrl(uuid),
      cancel: cancel,
      maxBytes: _detailLimit,
      allowedHosts: _hosts,
    ),
    cancel,
  );

  static String _localizedTitle(dynamic value, dynamic language) {
    if (value is! Map) return '';
    final titles = <String, String>{};
    for (final entry in value.entries) {
      if (entry.key is String && entry.value is String) {
        final title = _clean(entry.value, 300);
        if (title.isNotEmpty) titles[entry.key as String] = title;
      }
    }
    final preferred = language is String ? titles[language] : null;
    if (preferred != null) return preferred;
    return titles.length == 1 ? titles.values.single : '';
  }

  static String _clean(Object? value, [int maxLength = 300]) {
    if (value is! String || value.length > maxLength) return '';
    return value
        .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<JsonMap> _objects(dynamic value, {int limit = 30}) =>
      value is List
      ? value
            .whereType<Map>()
            .take(limit)
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : const [];

  static List<String> _names(dynamic value, {int limit = 30}) => [
    for (final item in _objects(value, limit: limit))
      if (_clean(item['name'], 160).isNotEmpty) _clean(item['name'], 160),
  ];

  static List<String> _performers(Map<String, dynamic> data) {
    final singers = _names(data['singers']);
    return singers.isNotEmpty ? singers : _names(data['singergroups']);
  }

  SongCandidate _candidate(Map<String, dynamic> data, String uuid) {
    if (!_uuid.hasMatch(uuid) ||
        _clean(data['kid'], 64).toLowerCase() != uuid.toLowerCase()) {
      throw const ProviderException('identity_mismatch');
    }
    final title = _localizedTitle(
      data['titles'],
      data['titles_default_language'],
    );
    if (title.isEmpty) throw const ProviderException('invalid_response');
    final performers = _performers(data);
    final songwriters = _names(data['songwriters']);
    final authors = _names(data['authors']);
    final contributors = _names(data['creators']);
    final types = _names(data['songtypes']);
    final versions = _names(data['versions']);
    final collections = _names(data['collections']);
    final languages = _names(data['langs']);
    final sourceDuration =
        data['duration'] is num &&
            (data['duration'] as num).isFinite &&
            (data['duration'] as num) > 0 &&
            (data['duration'] as num) <= 86400
        ? (data['duration'] as num).toDouble()
        : null;
    final sourceYear =
        data['year'] is int &&
            (data['year'] as int) >= 1000 &&
            (data['year'] as int) <= 9999
        ? data['year'] as int
        : null;
    final sourceVersion = [
      ...types,
      ...versions,
    ].where((value) => value.isNotEmpty).toSet().join(' / ');
    final metadata = sanitizeExtraMetadata({
      'identityScope': 'arrangement',
      'karaokeMugenId': uuid.toLowerCase(),
      'sourceTitles': data['titles'],
      if (data['titles_aliases'] is List)
        'sourceTitleAliases': (data['titles_aliases'] as List)
            .map((v) => _clean(v))
            .where((v) => v.isNotEmpty)
            .take(30)
            .toList(),
      'sourceLanguageCode': _clean(data['titles_default_language'], 35),
      'sourceRepository': _clean(data['repository'], 120),
      'sourceModifiedAt': _clean(data['modified_at'], 80),
      'sourceSubtitleChecksum': _clean(data['subchecksum'], 64),
      if (languages.isNotEmpty) 'languages': languages,
      if (languages.length == 1) 'language': languages.single,
      'sourceVideoDurationSeconds': ?sourceDuration,
      'sourceVideoYear': ?sourceYear,
      if (types.isNotEmpty) 'sourceSongTypes': types,
      if (versions.isNotEmpty) 'sourceVersions': versions,
      if (collections.isNotEmpty) 'sourceCollections': collections,
      for (final field in const {
        'series': 'sourceSeries',
        'groups': 'sourceGroups',
        'families': 'sourceFamilies',
        'franchises': 'sourceFranchises',
        'genres': 'sourceGenres',
        'warnings': 'sourceWarnings',
        'origins': 'sourceOrigins',
        'platforms': 'sourcePlatforms',
        'misc': 'sourceTags',
        'singergroups': 'sourceSingerGroups',
      }.entries)
        if (_names(data[field.key]).isNotEmpty)
          field.value: _names(data[field.key]),
      if (performers.isNotEmpty) 'performers': performers,
      if (songwriters.isNotEmpty) 'songwriters': songwriters,
      if (authors.isNotEmpty) 'karaokeAuthors': authors,
      if (contributors.isNotEmpty) 'sourceCreators': contributors,
      if (sourceVersion.isNotEmpty) 'version': 'Karaoke video — $sourceVersion',
      'credits': [
        for (final name in performers) {'role': 'performer', 'name': name},
        for (final name in songwriters) {'role': 'songwriter', 'name': name},
        for (final name in authors) {'role': 'karaoke-author', 'name': name},
        for (final name in contributors)
          {'role': 'source-creator', 'name': name},
      ],
      'mediaLinks': [
        {
          'kind': 'source',
          'label': 'kara.moe',
          'url': _detailUrl(uuid).toString(),
        },
      ],
    });
    return SongCandidate(
      providerId: definition.id,
      id: uuid.toLowerCase(),
      title: title,
      artist: performers.join(' & '),
      // A video UUID is a provider-local arrangement identity, not a
      // recording ID. In particular it must not flow into recordingIds.
      url: _detailUrl(uuid).toString(),
      metadata: metadata,
    );
  }

  static int _timeUs(dynamic value) {
    if (value is! num || !value.isFinite || value < 0 || value > 604800) {
      throw const FormatException('Invalid karaoke timestamp.');
    }
    final micros = (value * 1000000).round();
    if (micros < 0 || micros > _maxUs) {
      throw const FormatException('Karaoke timestamp exceeds seven days.');
    }
    return micros;
  }

  static TimingTrack _parseTiming(String raw, String uuid, String lyrics) {
    final id =
        'karamoe:$uuid:${sha256.convert(utf8.encode(raw)).toString().substring(0, 20)}';
    try {
      if (utf8.encode(raw).length > _detailLimit) {
        throw const FormatException('Detail JSON exceeds the response limit.');
      }
      final parsed = jsonDecode(raw);
      if (parsed is! Map || parsed['lyrics'] is! List) {
        throw const ProviderException('unavailable');
      }
      final rows = parsed['lyrics'] as List;
      if (rows.isEmpty) throw const ProviderException('unavailable');
      if (rows.length > _maxCues) {
        throw const FormatException('Too many karaoke line cues.');
      }
      final cues = <TimingCue>[];
      final lines = <String>[];
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row is! Map || row['text'] is! String) {
          throw const FormatException('Malformed karaoke lyric row.');
        }
        final text = _clean(row['text'], 4000);
        if (text.isEmpty) {
          throw const FormatException('Empty karaoke lyric row.');
        }
        final start = _timeUs(row['start']);
        final end = _timeUs(row['end']);
        if (end <= start) {
          throw const FormatException('Invalid karaoke cue interval.');
        }
        lines.add(text);
        cues.add(
          TimingCue(
            id: '$id:$i',
            occurrenceId: 'line-$i',
            text: text,
            startUs: start,
            endUs: end,
            originalBegin: row['start'].toString(),
            originalEnd: row['end'].toString(),
          ),
        );
      }
      final body = lines.join('\n');
      if (body.length > 200000 || body != lyrics) {
        throw const FormatException('Lyric lines exceed supported size.');
      }
      // Source event order is retained in lyrics/occurrence IDs. Serialized
      // timing tracks require chronological cues even for interleaved events.
      cues.sort((a, b) {
        final time = a.startUs.compareTo(b.startUs);
        return time != 0
            ? time
            : int.parse(
                a.occurrenceId.substring(5),
              ).compareTo(int.parse(b.occurrenceId.substring(5)));
      });
      return TimingTrack(
        id: id,
        sourceDocumentId: 'karamoe:$uuid',
        sourceLyrics: body,
        format: 'json',
        raw: raw,
        status: TimingStatus.unverified,
        granularity: 'line',
        cues: cues,
        lyricHash: lyricOrderHash(body),
        extra: {
          'parserVersion': 'karaoke-mugen-json-1',
          'timingProfile': 'karaoke-video-lines',
          'recordingEvidence': 'sourceDemonstrationOnly',
          'sourceKID': uuid,
          'fullTextRetainedInRawJson': true,
        },
      );
    } on ProviderException {
      rethrow;
    } on FormatException {
      throw const ProviderException('invalid_response');
    } catch (_) {
      throw const ProviderException('invalid_response');
    }
  }

  static String _attribution(Map<String, dynamic> data) {
    final contributors = _names(data['creators'], limit: 10);
    final authors = _names(data['authors'], limit: 10);
    final parts = <String>['kara.moe — https://kara.moe'];
    if (contributors.isNotEmpty) {
      parts.add('source creators: ${contributors.join(', ')}');
    }
    if (authors.isNotEmpty) {
      parts.add('karaoke authors: ${authors.join(', ')}');
    }
    return parts.join('; ');
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final text = queryText(query);
    if (text.isEmpty) return const [];
    final raw = await _request(
      () => transport.getText(
        _searchUrl(text),
        cancel: cancel,
        maxBytes: _searchLimit,
        allowedHosts: _hosts,
      ),
      cancel,
    );
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throwIfBlocked(raw);
      throw const ProviderException('invalid_response');
    }
    if (decoded is! Map || decoded['content'] is! List) {
      throw const ProviderException('invalid_response');
    }
    final results = <SongCandidate>[];
    for (final row in (decoded['content'] as List).take(12)) {
      if (row is! Map) continue;
      try {
        final map = Map<String, dynamic>.from(row);
        final uuid = _clean(map['kid'], 64);
        results.add(_candidate(map, uuid));
      } catch (_) {
        // Search rows are independent; an incomplete hit should not hide the
        // other valid selections in the response.
      }
    }
    if ((decoded['content'] as List).isNotEmpty && results.isEmpty) {
      // A populated response with no readable identity is a schema problem,
      // rather than evidence that the requested song is unavailable.
      throw const ProviderException('invalid_response');
    }
    return results;
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final own = candidate.providerId == definition.id;
    final sourceUuid = own
        ? candidate.id
        : candidate.metadata['karaokeMugenId'];
    if (sourceUuid is! String || !_uuid.hasMatch(sourceUuid)) {
      throw ProviderException(own ? 'invalid_selection' : 'identity_required');
    }
    final uuid = sourceUuid.toLowerCase();
    final raw = await _detail(uuid, cancel);
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throwIfBlocked(raw);
      throw const ProviderException('invalid_response');
    }
    if (decoded is! Map) throw const ProviderException('invalid_response');
    final data = Map<String, dynamic>.from(decoded);
    final found = _candidate(data, uuid);
    if (normalized(found.title) != normalized(candidate.title) ||
        normalized(found.artist) != normalized(candidate.artist)) {
      throw const ProviderException('identity_mismatch');
    }
    final rowList = data['lyrics'];
    if (rowList is! List || rowList.isEmpty) {
      throw const ProviderException(
        'unavailable',
        'No lyric timing is available.',
      );
    }
    final sourceLines = <String>[];
    for (final row in rowList) {
      if (row is! Map || row['text'] is! String) {
        throw const ProviderException('invalid_response');
      }
      final line = _clean(row['text'], 4000);
      if (line.isEmpty) throw const ProviderException('invalid_response');
      sourceLines.add(line);
    }
    final lyricText = sourceLines.join('\n');
    if (lyricText.length > 200000) {
      throw const ProviderException('invalid_response');
    }
    final body = remoteChordPro(plainToChordPro(meaningfulLyrics(lyricText)));
    final track = _parseTiming(raw, uuid, lyricText);
    final attribution = _attribution(data);
    final contributorNames = _names(data['creators'], limit: 30);
    final karaokeAuthors = _names(data['authors'], limit: 30);
    return SourceResult(
      candidate: found,
      body: body,
      metadata: found.metadata,
      timingTracks: [track],
      matchKind: MatchKind.unverified,
      attribution: attribution,
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        ...sourceEvidence(
          found,
          revision: sha256.convert(utf8.encode(raw)).toString(),
          evidenceUrl: found.url,
          attribution: attribution,
          licenseUrl:
              'https://github.com/karamoe/karaokebase/blob/master/LICENSE.md',
          license:
              'ODbL database terms; included lyrics and synchronization rights are unverified per entry.',
          permissions: {
            'status': 'field_specific',
            'database': 'ODbL-1.0',
            'lyrics': 'unknown',
            'synchronization': 'varies-by-entry',
            'attributionRequired': true,
          },
          provenanceNote:
              'Kara.moe source-video timing and imported lyrics are kept as an arrangement. '
              'Database terms do not establish rights to each lyric or synchronization.',
        ),
        'originalPayload': {
          'contentType': 'application/json',
          'encoding': 'utf-8',
          'base64': base64Encode(utf8.encode(raw)),
        },
        'karaokeMugenId': uuid,
        'sourceSongTypes': found.metadata['sourceSongTypes'] ?? const [],
        'sourceVersions': found.metadata['sourceVersions'] ?? const [],
        'sourceCollections': found.metadata['sourceCollections'] ?? const [],
        if (contributorNames.isNotEmpty) 'sourceCreators': contributorNames,
        if (karaokeAuthors.isNotEmpty) 'karaokeAuthors': karaokeAuthors,
      },
    );
  }
}
