import 'dart:convert';
import 'dart:math' as math;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../domain/models.dart';
import '../domain/timing.dart';
import 'core/common.dart' show plainToChordPro, sanitizeMetadata;
import 'provider.dart';
import 'sanitize.dart';
import 'source_catalog.dart';

/// A deliberately small adapter for catalogued, declarative JSON and HTML
/// sources. The catalog supplies data only: it cannot set request headers,
/// execute code, or relax the transport's URL/redirect rules.
class ConfigurableProvider implements LyricsProvider {
  ConfigurableProvider(this.entry, this.transport) {
    validateExtraction(entry);
  }

  final SourceCatalogEntry entry;
  final ProviderTransport transport;
  JsonMap get _extraction => entry.extraction!;

  @override
  ProviderDefinition get definition => entry.definition;

  /// Validate a catalog payload before a catalog update is committed. Callers
  /// can validate every entry first and only then apply the update atomically.
  static void validateExtraction(SourceCatalogEntry entry) {
    final extraction = entry.extraction;
    if (entry.adapter != 'json' && entry.adapter != 'html' ||
        extraction == null) {
      _badConfig();
    }
    _checkKeys(extraction, {'search', 'resolve', 'bodyFormat'});
    final search = _map(extraction['search']);
    final resolve = _map(extraction['resolve']);
    if (search == null || resolve == null) {
      _badConfig();
    }
    _validateRequest(search, isSearch: true, entry: entry);
    _validateRequest(resolve, isSearch: false, entry: entry);
    final format = extraction['bodyFormat'] ?? 'plain';
    if (!{'plain', 'chordpro', 'lrc', 'ttml', 'auto'}.contains(format)) {
      _badConfig();
    }
    if (entry.revision < 1 ||
        entry.hosts.isEmpty ||
        entry.attribution == null) {
      _badConfig();
    }
  }

  static void _validateRequest(
    JsonMap section, {
    required bool isSearch,
    required SourceCatalogEntry entry,
  }) {
    _checkKeys(
      section,
      isSearch
          ? {'url', 'response', 'itemsPath', 'itemSelector', 'fields'}
          : {'url', 'response', 'rootPath', 'fields'},
    );
    final rawUrl = section['url'];
    final response = section['response'];
    if (rawUrl is! String ||
        rawUrl.isEmpty ||
        rawUrl.length > 2048 ||
        !{'json', 'html'}.contains(response)) {
      _badConfig();
    }
    if (isSearch &&
        (response == 'json'
            ? section.containsKey('itemSelector')
            : section.containsKey('itemsPath'))) {
      _badConfig();
    }
    if (!isSearch && response == 'html' && section.containsKey('rootPath')) {
      _badConfig();
    }
    final tokens = RegExp(r'\{([^{}]+)\}').allMatches(rawUrl);
    final found = <String>{};
    for (final m in tokens) {
      final token = m[1]!;
      if (!{'query', 'id', 'title', 'artist', 'url'}.contains(token)) {
        _badConfig();
      }
      found.add(token);
    }
    if (rawUrl.replaceAll(RegExp(r'\{[^{}]+\}'), '').contains('{') ||
        rawUrl.replaceAll(RegExp(r'\{[^{}]+\}'), '').contains('}')) {
      _badConfig();
    }
    if (isSearch
        ? !found.contains('query')
        : !(found.contains('id') ||
              found.contains('url') ||
              (found.contains('title') && found.contains('artist')))) {
      _badConfig();
    }
    if (found.contains('url') && rawUrl != '{url}') _badConfig();
    if (rawUrl == '{url}') {
      if (isSearch) _badConfig();
    } else {
      if (!rawUrl.startsWith('https://')) _badConfig();
      final authority = RegExp(r'^https://([^/?#]+)').firstMatch(rawUrl)?[1];
      if (authority == null ||
          authority.contains('{') ||
          authority.contains('}')) {
        _badConfig();
      }
      final probe = rawUrl.replaceAllMapped(
        RegExp(r'\{([^{}]+)\}'),
        (m) => Uri.encodeComponent('safe-value'),
      );
      final uri = Uri.tryParse(probe);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.userInfo.isNotEmpty ||
          uri.host.isEmpty ||
          (uri.hasPort && uri.port != 443) ||
          !entry.hosts.contains(uri.host.toLowerCase()) ||
          safeHttpsUrl(uri.toString()) == null) {
        _badConfig();
      }
    }
    final fields = _map(section['fields']);
    if (fields == null) _badConfig();
    if (isSearch) {
      if (response == 'json') {
        if (!_validPath(section['itemsPath'])) _badConfig();
      } else if (!_validSelector(section['itemSelector'])) {
        _badConfig();
      }
      for (final key in ['id', 'title', 'artist']) {
        if (!_validField(fields[key], response as String)) _badConfig();
      }
      for (final key in ['url', 'album', 'durationSeconds']) {
        if (fields.containsKey(key) && !_validField(fields[key], response)) {
          _badConfig();
        }
      }
      _checkKeys(fields, {
        'id',
        'title',
        'artist',
        'url',
        'album',
        'durationSeconds',
      });
    } else {
      if (response == 'json' &&
          !_validPath(section['rootPath'], optional: true)) {
        _badConfig();
      }
      // Identity is required for every resolve adapter so returned content is
      // checked against the selected search result.
      final metadataFields = _map(fields['metadata']);
      if (metadataFields != null) {
        const metadataKeys = {
          'key',
          'timeSignature',
          'album',
          'genre',
          'language',
          'difficulty',
          'recording',
          'releaseDate',
          'capo',
          'tempo',
          'duration',
          'year',
          'tuning',
          'artworkUrl',
          'mediaLinks',
          'credits',
        };
        if (metadataFields.isEmpty ||
            metadataFields.keys.any((k) => !metadataKeys.contains(k))) {
          _badConfig();
        }
        for (final spec in metadataFields.values) {
          if (!_validField(spec, response as String)) {
            _badConfig();
          }
        }
      } else if (fields.containsKey('metadata')) {
        _badConfig();
      }
      final metadataOnly =
          entry.capabilities.contains('metadata') &&
          !entry.capabilities.contains('lyrics') &&
          !entry.capabilities.contains('chords');
      final autoFormat = (entry.extraction?['bodyFormat'] ?? 'plain') == 'auto';
      if (!metadataOnly || fields.containsKey('body')) {
        if (fields.containsKey('body') &&
            !_validField(fields['body'], response as String)) {
          _badConfig();
        }
        if (!fields.containsKey('body') && !metadataOnly) {
          _badConfig();
        }
      }
      if (autoFormat) {
        if (metadataOnly ||
            !_validField(fields['body'], response as String) ||
            !_validField(fields['format'], response)) {
          _badConfig();
        }
      }
      for (final key in ['title', 'artist']) {
        if (!_validField(fields[key], response as String)) _badConfig();
      }
      for (final key in ['album', 'durationSeconds']) {
        if (fields.containsKey(key) && !_validField(fields[key], response)) {
          _badConfig();
        }
      }
      _checkKeys(fields, {
        'body',
        'title',
        'artist',
        'album',
        'durationSeconds',
        if (autoFormat) 'format',
        'metadata',
      });
      if (metadataOnly && metadataFields == null) {
        _badConfig();
      }
    }
  }

  static bool _validField(dynamic value, String response) {
    return _validFieldAtDepth(value, response, 0);
  }

  static bool _validFieldAtDepth(dynamic value, String response, int depth) {
    if (depth > 4) return false;
    if (value is List) {
      return value.isNotEmpty &&
          value.length <= 8 &&
          value.every((part) => _validFieldAtDepth(part, response, depth + 1));
    }
    if (response == 'json') return _validPath(value);
    if (value is! Map) return false;
    final spec = Map<String, dynamic>.from(value);
    return spec.keys.every((k) => {'selector', 'attribute'}.contains(k)) &&
        _validSelector(spec['selector']) &&
        (spec['attribute'] == null ||
            (spec['attribute'] is String &&
                (spec['attribute'] as String).length <= 80 &&
                !RegExp(
                  r'''[\s<>"']''',
                ).hasMatch(spec['attribute'] as String)));
  }

  static bool _validPath(dynamic value, {bool optional = false}) {
    if (value == null) return optional;
    if (value is! String || value.isEmpty || value.length > 300) return false;
    return value
        .split('.')
        .every(
          (part) =>
              RegExp(r'^[A-Za-z_$][A-Za-z0-9_$-]{0,79}$').hasMatch(part) ||
              RegExp(r'^\d{1,6}$').hasMatch(part),
        );
  }

  static bool _validSelector(dynamic value) =>
      value is String &&
      value.isNotEmpty &&
      value.length <= 300 &&
      !RegExp(r'[{}<>]').hasMatch(value) &&
      _selectorParses(value);

  static bool _selectorParses(String selector) {
    try {
      html_parser.parse('').querySelector(selector);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _checkKeys(JsonMap value, Set<String> allowed) {
    if (value.keys.any((key) => !allowed.contains(key))) _badConfig();
  }

  static JsonMap? _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static Never _badConfig() =>
      throw const ProviderException('invalid_config', 'Unsafe extraction rule');

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final q = queryText(query);
    final section = _map(_extraction['search'])!;
    final url = _requestUrl(section['url'] as String, {'query': q});
    final source = await _fetch(url, section, cancel);
    final fields = _map(section['fields'])!;
    final candidates = <SongCandidate>[];
    var attempted = 0;
    if (source is List) {
      for (final row in source.take(100)) {
        attempted++;
        final parsed = _candidate(row, fields, 'json', url);
        if (parsed != null) candidates.add(parsed);
      }
    } else {
      final document = source as dom.Document;
      for (final row
          in document
              .querySelectorAll(section['itemSelector'] as String)
              .take(100)) {
        attempted++;
        final parsed = _candidate(row, fields, 'html', url);
        if (parsed != null) candidates.add(parsed);
      }
    }
    if (attempted > 0 && candidates.isEmpty) {
      throw const ProviderException(
        'extraction_failed',
        'No usable search rows',
      );
    }
    return candidates;
  }

  Future<dynamic> _fetch(
    String url,
    JsonMap section,
    CancellationToken? cancel,
  ) async {
    final text = await transport.getText(
      Uri.parse(url),
      cancel: cancel,
      allowedHosts: entry.hosts.toSet(),
    );
    throwIfBlocked(text);
    final response = section['response'] as String;
    if (response == 'json') {
      try {
        final data = jsonDecode(text);
        final path = section['itemsPath'];
        final value = path == null ? data : _path(data, path as String);
        if (value is! List) throw const FormatException();
        return value;
      } catch (_) {
        throw const ProviderException(
          'extraction_failed',
          'Expected JSON list',
        );
      }
    }
    return html_parser.parse(text);
  }

  SongCandidate? _candidate(
    dynamic row,
    JsonMap fields,
    String kind,
    String pageUrl,
  ) {
    final id = _string(_field(row, fields['id'], kind), max: 300);
    final title = _string(_field(row, fields['title'], kind), max: 300);
    final artist = _string(_field(row, fields['artist'], kind), max: 300);
    if (id == null || title == null || artist == null) return null;
    final rawUrl = _string(_field(row, fields['url'], kind), max: 2048);
    final candidateUrl = _candidateUrl(rawUrl, pageUrl);
    final album = _string(_field(row, fields['album'], kind), max: 300);
    final duration = _duration(_field(row, fields['durationSeconds'], kind));
    return SongCandidate(
      providerId: entry.id,
      id: id,
      title: title,
      artist: artist,
      album: album,
      durationSeconds: duration,
      url: candidateUrl,
      metadata: {
        'identityScope': 'composition',
        'rights': {'status': 'unknown'},
      },
      extra: {'sourceUrl': candidateUrl ?? pageUrl},
    );
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (candidate.providerId != entry.id) {
      final metadataOnly =
          definition.capabilities.contains('metadata') &&
          !definition.capabilities.contains('lyrics') &&
          !definition.capabilities.contains('chords');
      if (!metadataOnly) throw const ProviderException('invalid_selection');
      final title = candidate.title.trim();
      final artist = candidate.artist.trim();
      if (title.isEmpty || artist.isEmpty) {
        throw const ProviderException('invalid_selection');
      }
      final boundedArtist = artist.substring(0, math.min(100, artist.length));
      final boundedTitle = title.substring(
        0,
        math.min(199 - boundedArtist.length, title.length),
      );
      final matches =
          (await search('$boundedTitle $boundedArtist', cancel: cancel))
              .where(
                (result) =>
                    _identity(result.title) == _identity(title) &&
                    _identity(result.artist) == _identity(artist),
              )
              .toList();
      if (matches.length != 1) throw const ProviderException('unavailable');
      return resolve(matches.single, cancel: cancel);
    }
    final section = _map(_extraction['resolve'])!;
    final values = <String, String>{
      'id': candidate.id,
      'title': candidate.title,
      'artist': candidate.artist,
      if (candidate.url != null) 'url': candidate.url!,
    };
    final url = _requestUrl(
      section['url'] as String,
      values,
      candidate: candidate,
    );
    final kind = section['response'] as String;
    final document = await _fetchSection(url, kind, cancel);
    final fields = _map(section['fields'])!;
    final root = kind == 'json' && section['rootPath'] != null
        ? _path(document, section['rootPath'] as String)
        : document;
    final returnedTitle = _string(
      _field(root, fields['title'], kind),
      max: 300,
    );
    final returnedArtist = _string(
      _field(root, fields['artist'], kind),
      max: 300,
    );
    if (returnedTitle == null || returnedArtist == null) {
      throw const ProviderException(
        'extraction_failed',
        'Missing identity fields',
      );
    }
    if (_identity(returnedTitle) != _identity(candidate.title) ||
        _identity(returnedArtist) != _identity(candidate.artist)) {
      throw const ProviderException('identity_mismatch');
    }
    final metadataFields = _map(fields['metadata']);
    final metadata = <String, dynamic>{};
    if (metadataFields != null) {
      for (final field in metadataFields.entries) {
        final value = _field(root, field.value, kind);
        if (value != null) metadata[field.key] = value;
      }
    }
    final safeMetadata = sanitizeMetadata(metadata);
    final rawBody = fields.containsKey('body')
        ? _string(_field(root, fields['body'], kind, preserveBreaks: true))
        : null;
    if ((rawBody == null || rawBody.length > 512 * 1024) &&
        !(definition.capabilities.contains('metadata') &&
            !definition.capabilities.contains('lyrics') &&
            !definition.capabilities.contains('chords') &&
            safeMetadata.isNotEmpty)) {
      throw const ProviderException(
        'extraction_failed',
        'Missing body or safe metadata',
      );
    }
    final bodyFormat = _extraction['bodyFormat'] ?? 'plain';
    final resolvedFormat = bodyFormat == 'auto'
        ? _sourceBodyFormat(_field(root, fields['format'], kind))
        : bodyFormat as String;
    if (resolvedFormat == 'invalid') {
      throw const ProviderException(
        'extraction_failed',
        'Unsupported body format',
      );
    }
    var body = '';
    List<TimingTrack> timing = const [];
    if (rawBody == null) {
      body = '';
    } else if (resolvedFormat == 'lrc') {
      final track = parseLrc(rawBody, sourceDocumentId: candidate.identity);
      timing = [track];
      body = plainToChordPro(stripVerseDirectives(track.sourceLyrics));
    } else if (resolvedFormat == 'ttml') {
      final track = parseTtml(rawBody, sourceDocumentId: candidate.identity);
      timing = [track];
      body = plainToChordPro(stripVerseDirectives(track.sourceLyrics));
    } else if (resolvedFormat == 'chordpro') {
      body = _stripRemoteExtensions(stripVerseDirectives(rawBody));
    } else {
      body = plainToChordPro(
        _stripRemoteExtensions(stripVerseDirectives(rawBody)),
      );
    }
    if (body.trim().isEmpty &&
        !timing.any((t) => t.raw?.isNotEmpty == true) &&
        safeMetadata.isEmpty) {
      throw const ProviderException('unavailable');
    }
    final returnedAlbum =
        _string(_field(root, fields['album'], kind), max: 300) ??
        _string(safeMetadata['album']);
    final returnedDuration = _duration(
      _field(root, fields['durationSeconds'], kind),
    );
    final resultCandidate = SongCandidate(
      providerId: candidate.providerId,
      id: candidate.id,
      title: returnedTitle,
      artist: returnedArtist,
      album: returnedAlbum ?? candidate.album,
      durationSeconds: returnedDuration ?? candidate.durationSeconds,
      url: candidate.url ?? url,
      metadata: {
        ...safeMetadata,
        'identityScope': 'composition',
        'rights': {'status': 'unknown'},
      },
      extra: candidate.extra,
    );
    return SourceResult(
      candidate: resultCandidate,
      body: body,
      metadata: safeMetadata,
      timingTracks: timing,
      matchKind: MatchKind.unverified,
      attribution: entry.attribution,
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        'sourceUrl': candidate.url ?? url,
        'rights': {'status': 'unknown'},
        'extractionRevision': entry.revision,
        if (bodyFormat == 'lrc') 'timingOnly': body.isEmpty,
      },
    );
  }

  Future<dynamic> _fetchSection(
    String url,
    String kind,
    CancellationToken? cancel,
  ) async {
    final text = await transport.getText(
      Uri.parse(url),
      cancel: cancel,
      allowedHosts: entry.hosts.toSet(),
    );
    throwIfBlocked(text);
    if (kind == 'html') return html_parser.parse(text);
    try {
      return jsonDecode(text);
    } catch (_) {
      throw const ProviderException(
        'extraction_failed',
        'Expected JSON object',
      );
    }
  }

  String _requestUrl(
    String template,
    Map<String, String> values, {
    SongCandidate? candidate,
  }) {
    if (template == '{url}') {
      final url = candidate?.url;
      final safe = safeHttpsUrl(url);
      if (safe == null || !_exactHost(Uri.parse(safe).host)) {
        throw const ProviderException('invalid_url');
      }
      return safe;
    }
    final rendered = template.replaceAllMapped(RegExp(r'\{([^{}]+)\}'), (m) {
      final value = values[m[1]];
      if (value == null || value.length > 2000) {
        throw const ProviderException('invalid_url');
      }
      return Uri.encodeComponent(value);
    });
    final safe = safeHttpsUrl(rendered);
    if (safe == null || !_exactHost(Uri.parse(safe).host)) {
      throw const ProviderException('invalid_url');
    }
    return safe;
  }

  bool _exactHost(String host) => entry.hosts.contains(host.toLowerCase());

  String? _candidateUrl(String? value, String pageUrl) {
    if (value == null) return null;
    final parsed = Uri.tryParse(value);
    final absolute = parsed != null && parsed.hasScheme
        ? value
        : Uri.parse(pageUrl).resolve(value).toString();
    final safe = safeHttpsUrl(absolute);
    if (safe == null || !_exactHost(Uri.parse(safe).host)) return null;
    return safe;
  }

  dynamic _field(
    dynamic row,
    dynamic spec,
    String kind, {
    bool preserveBreaks = false,
  }) {
    if (spec == null) return null;
    if (spec is List) {
      for (final option in spec) {
        final value = _field(row, option, kind, preserveBreaks: preserveBreaks);
        if (value != null && value.toString().trim().isNotEmpty) return value;
      }
      return null;
    }
    if (kind == 'json') return _path(row, spec as String);
    final config = Map<String, dynamic>.from(spec as Map);
    final selector = config['selector'] as String;
    final nodes = switch (row) {
      dom.Document document => document.querySelectorAll(selector),
      dom.Element element => element.querySelectorAll(selector),
      _ => const <dom.Element>[],
    };
    if (nodes.isEmpty) return null;
    final attribute = config['attribute'] as String?;
    return nodes
        .map(
          (node) => attribute == null
              ? (preserveBreaks ? _htmlText(node) : node.text)
              : node.attributes[attribute],
        )
        .whereType<String>()
        .join(attribute == null ? '\n' : ' ')
        .trim();
  }

  String _htmlText(dom.Node node) {
    if (node is dom.Text) return node.data;
    if (node is dom.Element) {
      if (node.localName == 'br') return '\n';
      if (node.localName == 'script' || node.localName == 'style') return '';
      const blocks = {
        'address',
        'article',
        'blockquote',
        'div',
        'dl',
        'fieldset',
        'figcaption',
        'figure',
        'footer',
        'h1',
        'h2',
        'h3',
        'h4',
        'h5',
        'h6',
        'header',
        'li',
        'main',
        'ol',
        'p',
        'pre',
        'section',
        'table',
        'tr',
        'ul',
      };
      final children = node.nodes.map(_htmlText).join();
      return blocks.contains(node.localName) ? '\n$children\n' : children;
    }
    return node.nodes.map(_htmlText).join();
  }

  dynamic _path(dynamic value, String path) {
    dynamic current = value;
    for (final part in path.split('.')) {
      if (current is Map) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index == null || index < 0 || index >= current.length) return null;
        current = current[index];
      } else {
        return null;
      }
    }
    return current;
  }

  String? _string(dynamic value, {int max = 512 * 1024}) {
    if (value is! String && value is! num) return null;
    final text = value.toString().replaceAll('\r\n', '\n').trim();
    return text.isEmpty || text.length > max ? null : text;
  }

  double? _duration(dynamic value) {
    if (value is num && value.isFinite && value >= 0 && value <= 86400) {
      return value.toDouble();
    }
    final parsed = value is String ? double.tryParse(value) : null;
    return parsed != null && parsed.isFinite && parsed >= 0 && parsed <= 86400
        ? parsed
        : null;
  }

  static String _sourceBodyFormat(dynamic value) {
    if (value is! String) return 'invalid';
    final normalized = value.trim().toLowerCase();
    return {'plain', 'lrc', 'ttml'}.contains(normalized)
        ? normalized
        : 'invalid';
  }

  String _identity(String value) => value
      .toLowerCase()
      .replaceAll(RegExp("['‘’]"), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  String _stripRemoteExtensions(String value) => value.replaceAll(
    RegExp(
      r'\{\s*x_verse[a-z0-9_]*\b[^}]*\}',
      caseSensitive: false,
      dotAll: true,
    ),
    '',
  );
}
