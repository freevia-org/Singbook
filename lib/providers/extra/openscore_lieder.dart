import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/models.dart';
import '../provider.dart';
import 'common.dart';

/// Publisher-provided lyric text extracted from the OpenScore Lieder scores.
/// Composer credits identify compositions, never performers or recordings.
/// This source-only adapter is not registered in any released catalog.
class OpenScoreLiederProvider implements LyricsProvider {
  OpenScoreLiederProvider(this.transport, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ProviderTransport transport;
  final DateTime Function() _clock;
  static const indexUrl =
      'https://raw.githubusercontent.com/OpenScore/Lieder/main/data/index.html';
  static const _repository = 'https://github.com/OpenScore/Lieder';
  static const _maxIndexBytes = 2 * 1024 * 1024;
  static const _maxLyricsBytes = 256 * 1024;
  static const _cacheLifetime = Duration(hours: 24);

  List<SongCandidate>? _catalog;
  DateTime? _expiresAt;
  Future<List<SongCandidate>>? _loading;

  @override
  final definition = const ProviderDefinition(
    id: 'openscorelieder',
    name: 'OpenScore Lieder',
    capabilities: {'catalog', 'lyrics', 'metadata'},
    enabledByDefault: false,
    accessMode: 'publicRepository',
    website: _repository,
  );

  Future<List<SongCandidate>> _load(CancellationToken? cancel) async {
    cancel?.throwIfCancelled();
    if (_catalog != null && _clock().isBefore(_expiresAt!)) return _catalog!;
    if (cancel != null) {
      // A changing search owns its cancellation. It must not join a request
      // that an older caller can abort, or keep waiting after it is canceled.
      final result = await _downloadCatalog(cancel);
      cancel.throwIfCancelled();
      _catalog = result;
      _expiresAt = _clock().add(_cacheLifetime);
      return result;
    }
    final pending = _loading;
    if (pending != null) {
      return pending;
    }
    final future = _downloadCatalog(null);
    _loading = future;
    try {
      final result = await future;
      // A failed/aborted refresh never replaces a previously usable snapshot.
      _catalog = result;
      _expiresAt = _clock().add(_cacheLifetime);
      return result;
    } finally {
      if (identical(_loading, future)) _loading = null;
    }
  }

  Future<List<SongCandidate>> _downloadCatalog(
    CancellationToken? cancel,
  ) async {
    final bytes = await transport.getBytes(
      Uri.parse(indexUrl),
      allowedHosts: {'raw.githubusercontent.com'},
      maxBytes: _maxIndexBytes,
      cancel: cancel,
    );
    cancel?.throwIfCancelled();
    final String source;
    try {
      source = utf8.decode(bytes);
    } on FormatException {
      throw const ProviderException('invalid_response');
    }
    return parseCatalog(source, indexSha256: sha256.convert(bytes).toString());
  }

  /// Parses the publisher's generated catalog; it never follows script, media,
  /// IMSLP, Lieder.net or MuseScore download links.
  static List<SongCandidate> parseCatalog(
    String source, {
    required String indexSha256,
  }) {
    if (utf8.encode(source).length > _maxIndexBytes ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(indexSha256)) {
      throw const ProviderException('invalid_response');
    }
    final doc = parseHtml(source);
    final tables = doc.querySelectorAll('table#catalogue');
    if (tables.length != 1) throw const ProviderException('extraction_failed');
    final table = tables.single;
    final headers = table
        .querySelectorAll('thead th')
        .map((e) => e.text.trim());
    if (headers.join('|') !=
        'Composer|Set|Song|Lyricist|Language|Score|External') {
      throw const ProviderException('extraction_failed');
    }
    final rows = table.querySelectorAll('tbody tr');
    if (rows.isEmpty || rows.length > 5000) {
      throw const ProviderException('invalid_response');
    }
    final byId = <String, SongCandidate>{};
    final conflicts = <String>{};
    for (final row in rows) {
      final cells = row.children.where((e) => e.localName == 'td').toList();
      if (cells.length != 7) throw const ProviderException('extraction_failed');
      final values = cells.take(5).map((e) => e.text.trim()).toList();
      if (values.any(
        (v) => v.length > 500 || v.contains(RegExp(r'[\r\n\x00]')),
      )) {
        throw const ProviderException('invalid_response');
      }
      final composer = values[0], title = values[2];
      if (composer.isEmpty || title.isEmpty) continue;
      final targets = <String, ({String id, String path})>{};
      for (final link in cells[5].querySelectorAll('a[href]')) {
        final target = _scoreTarget(link.attributes['href']!);
        if (target != null) targets['${target.id}:${target.path}'] = target;
      }
      if (targets.length != 1) continue;
      final target = targets.values.single;
      final id = target.id;
      if (conflicts.contains(id)) continue;
      final credits = <JsonMap>[
        {'role': 'Composer', 'name': composer},
        if (values[3].isNotEmpty) {'role': 'Lyricist', 'name': values[3]},
      ];
      final references = <JsonMap>[];
      for (final cell in [cells[5], cells[6]]) {
        final links = cell.querySelectorAll('a[href]');
        if (links.length > 10) {
          throw const ProviderException('invalid_response');
        }
        for (final link in links) {
          final url = httpsLink(link.attributes['href']);
          if (url != null && url.length <= 2500) {
            references.add({'label': boundedText(link.text), 'url': url});
          }
        }
      }
      final candidate = SongCandidate(
        providerId: 'openscorelieder',
        id: id,
        title: title,
        artist: composer,
        url: Uri(
          scheme: 'https',
          host: 'github.com',
          pathSegments: [
            'OpenScore',
            'Lieder',
            'blob',
            'main',
            ...target.path.split('/'),
          ],
        ).toString(),
        metadata: {
          'identityScope': 'composition',
          'artistCreditRole': 'composer',
          'composer': composer,
          if (values[3].isNotEmpty) 'lyricist': values[3],
          if (values[4].isNotEmpty) 'language': values[4],
          if (values[1].isNotEmpty && values[1] != '—')
            'sourceWorkSet': values[1],
          'credits': credits,
          'openScoreId': id,
          'openScoreTextPath': target.path,
          'openScoreCatalogSha256': indexSha256,
          'openScoreCatalogFields': {
            'composer': values[0],
            'workSet': values[1],
            'title': values[2],
            'lyricist': values[3],
            'language': values[4],
          },
          'openScoreReferences': references,
          'lyricsProvenance': 'automatically_extracted_from_score_parts',
        },
      );
      final prior = byId[id];
      if (prior != null &&
          jsonEncode(prior.toJson()) != jsonEncode(candidate.toJson())) {
        byId.remove(id);
        conflicts.add(id);
      } else {
        byId[id] = candidate;
      }
    }
    if (byId.isEmpty) throw const ProviderException('extraction_failed');
    return List.unmodifiable(byId.values);
  }

  static ({String id, String path})? _scoreTarget(String value) {
    if (value.length > 2500) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'raw.githubusercontent.com' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasFragment ||
        uri.query != 'raw=true') {
      return null;
    }
    final List<String> segments;
    try {
      segments = uri.pathSegments;
    } on FormatException {
      return null;
    }
    final prefix = segments.take(3).join('/');
    final List<String> path;
    if (prefix == 'OpenScore/Lieder/main') {
      path = segments.skip(3).toList();
    } else if (segments.take(5).join('/') ==
        'OpenScore/Lieder/refs/heads/main') {
      path = segments.skip(5).toList();
    } else {
      return null;
    }
    if (path.length != 5 ||
        path[0] != 'scores' ||
        path.any(
          (p) =>
              p.isEmpty ||
              p == '.' ||
              p == '..' ||
              p.contains(RegExp(r'[/\\\x00-\x1f\x7f]')),
        )) {
      return null;
    }
    final match = RegExp(
      r'^lc([1-9]\d{0,11})\.(?:mscz|mxl)$',
    ).firstMatch(path.last);
    if (match == null) return null;
    path[path.length - 1] = 'lc${match[1]}.txt';
    return (id: match[1]!, path: path.join('/'));
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final checked = queryText(query);
    final catalog = await _load(cancel);
    cancel?.throwIfCancelled();
    return catalog
        .where(
          (c) => queryMatches(
            checked,
            '${c.title} ${c.artist} ${c.metadata['lyricist'] ?? ''}',
          ),
        )
        .take(30)
        .toList();
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (candidate.providerId != definition.id ||
        !RegExp(r'^[1-9]\d{0,11}$').hasMatch(candidate.id)) {
      throw const ProviderException('user_selection_required');
    }
    final catalog = await _load(cancel);
    final matches = catalog.where((c) => c.id == candidate.id).toList();
    if (matches.length != 1) throw const ProviderException('unavailable');
    final found = matches.single;
    if (normalized(found.title) != normalized(candidate.title) ||
        normalized(found.artist) != normalized(candidate.artist)) {
      throw const ProviderException('identity_mismatch');
    }
    // Only the freshly validated catalog supplies the URL/path and source facts.
    final path = found.metadata['openScoreTextPath'] as String;
    final url = Uri(
      scheme: 'https',
      host: 'raw.githubusercontent.com',
      pathSegments: ['OpenScore', 'Lieder', 'main', ...path.split('/')],
    );
    final bytes = await transport.getBytes(
      url,
      allowedHosts: {'raw.githubusercontent.com'},
      maxBytes: _maxLyricsBytes,
      cancel: cancel,
    );
    cancel?.throwIfCancelled();
    final String original;
    try {
      original = utf8.decode(bytes);
    } on FormatException {
      throw const ProviderException('invalid_response');
    }
    if (original.contains(RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]')) ||
        RegExp(
          r'<(?:!doctype|html|script|body)\b',
          caseSensitive: false,
        ).hasMatch(original)) {
      throw const ProviderException('invalid_response');
    }
    requireSongText(original);
    // Every source character is lyric text, including whole bracketed lines,
    // hashes and directive-shaped poetry. Escape rather than interpret/drop it.
    final body = original.trim().replaceAllMapped(
      RegExp(r'[\\\[\]{}#]'),
      (m) => '\\${m[0]}',
    );
    final attribution = '${found.artist}; OpenScore Lieder contributors';
    return SourceResult(
      candidate: found,
      body: body,
      metadata: found.metadata,
      attribution: attribution,
      retrievedAt: _clock().toUtc(),
      extra: {
        ...sourceEvidence(
          found,
          license: 'CC0-1.0 (publisher corpus dedication)',
          licenseUrl: '$_repository/blob/main/LICENSE.txt',
          attribution: attribution,
          evidenceUrl: '$_repository/blob/main/README.md',
          permissions: {
            'status': 'source_declared_underlying_rights_unverified',
          },
          provenanceNote:
              'Publisher text is automatically extracted from score parts. Composer credit is not a performer; no recording identity, timing, chord analysis or blanket underlying-poem clearance is inferred.',
        ),
        'parserVersion': 'openscore-lieder-1',
        'sourceUrl': url.toString(),
        'originalPayload': {
          'contentType': 'text/plain',
          'encoding': 'utf-8',
          'base64': base64Encode(bytes),
          'sha256': sha256.convert(bytes).toString(),
          'httpBodyBytesExact': true,
        },
      },
    );
  }
}
