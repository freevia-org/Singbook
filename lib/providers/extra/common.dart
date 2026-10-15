import 'dart:convert';
import 'package:html/parser.dart' as html;
import '../../domain/models.dart';
import '../sanitize.dart';
import '../transport.dart';

export '../sanitize.dart'
    show
        queryText,
        safeHttpsUrl,
        stripVerseDirectives,
        throwIfBlocked,
        htmlTooDeep,
        parseHtml,
        blockedPageReason;

String stringValue(Object? value) => value is String ? value.trim() : '';
String textValue(Object? value) {
  try {
    final fragment = html.parseFragment(stringValue(value));
    return htmlTooDeep(fragment) ? '' : fragment.text ?? '';
  } on StackOverflowError {
    return '';
  }
}
List<JsonMap> maps(Object? value) => value is List
    ? value.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
    : [];
String normalized(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r"[^\p{L}\p{N}]+", unicode: true), ' ')
    .trim();
bool queryMatches(String query, String text) {
  final haystack = normalized(text);
  final tokens = normalized(query).split(' ').where((t) => t.isNotEmpty);
  return tokens.isNotEmpty && tokens.every(haystack.contains);
}

/// Maps a MediaWiki API `error` object to a typed failure: replication lag
/// (`maxlag`) is a retryable `provider_busy`, anything else is `unavailable`.
void throwIfApiError(JsonMap data) {
  final error = data['error'];
  if (error == null) return;
  final code = error is Map ? error['code'] : null;
  throw ProviderException(code == 'maxlag' ? 'provider_busy' : 'unavailable');
}

Uri checkedUrl(String value, Set<String> hosts, {String? prefix}) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      !hosts.contains(uri.host) ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443) ||
      (prefix != null && !uri.path.startsWith(prefix))) {
    throw const ProviderException('invalid_url');
  }
  return uri;
}

/// Outbound link from an untrusted source: https, no userinfo, public host.
/// Returns null (the value is dropped) otherwise.
String? httpsLink(Object? value, {Set<String>? hosts}) =>
    safeHttpsUrl(stringValue(value), hostSuffixes: hosts);

/// Resolves a possibly relative catalog reference against [base] and applies
/// [httpsLink]; non-string input is dropped instead of throwing.
String? resolvedLink(Uri base, Object? value, {Set<String>? hosts}) {
  final s = stringValue(value);
  if (s.isEmpty || s.length > 2048) return null;
  final u = Uri.tryParse(s);
  if (u == null) return null;
  return httpsLink(base.resolveUri(u).toString(), hosts: hosts);
}

final _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');
bool isYoutubeId(String value) => _youtubeId.hasMatch(value);

String directive(String key, Object? value) {
  final s = value?.toString().replaceAll(RegExp(r'[{}\r\n]'), ' ').trim() ?? '';
  return s.isEmpty ? '' : '{$key: $s}\n';
}

/// Facts stay attached to their precise source, including unknown permissions.
JsonMap sourceEvidence(
  SongCandidate candidate, {
  String? license,
  String? licenseUrl,
  String? attribution,
  String? original,
  String? revision,
  String? evidenceUrl,
  JsonMap? permissions,
  String? provenanceNote,
}) => {
  'parserVersion': 'verse-extra-1',
  'sourceDocumentId': candidate.identity,
  'rights': {
    'source': candidate.providerId,
    'sourceId': candidate.id,
    if (candidate.url != null) 'sourceUrl': candidate.url,
    'license': ?license,
    'licenseUrl': ?licenseUrl,
    'attribution': ?attribution,
    'evidenceUrl': ?evidenceUrl,
    'permissions': permissions ?? {'status': 'unknown'},
    'provenanceNote': ?provenanceNote,
  },
  'revision': ?revision,
  if (original != null)
    'originalPayload': {
      'contentType': 'text/chordpro',
      'encoding': 'utf-8',
      'base64': base64Encode(utf8.encode(original)),
    },
};

JsonMap chordProMetadata(String document) {
  final result = <String, dynamic>{};
  final aliases = {
    'key': 'key',
    'capo': 'capo',
    'tempo': 'tempo',
    'time': 'timeSignature',
    'album': 'album',
    'year': 'year',
    'duration': 'durationSeconds',
    'tuning': 'tuning',
    'composer': 'composer',
    'lyricist': 'lyricist',
    'copyright': 'copyright',
  };
  for (final match in RegExp(
    r'^\{([^:{}]+):\s*([^{}]*)\}\s*$',
    multiLine: true,
  ).allMatches(document)) {
    final key = aliases[match[1]!.toLowerCase().trim()];
    if (key == null) continue;
    final value = match[2]!.trim();
    if (value.isEmpty) continue;
    if (key == 'tempo') {
      // Accepts "92", "92.5" and "92 bpm"; stored as int when whole.
      final n = double.tryParse(
        RegExp(r'^\d+(?:\.\d+)?').firstMatch(value)?[0] ?? '',
      );
      if (n != null && n.isFinite && n > 0 && n <= 500) {
        result[key] = n == n.roundToDouble() ? n.round() : n;
      }
    } else if (key == 'capo' || key == 'year') {
      final n = int.tryParse(value);
      if (n != null && n >= 0 && (key == 'year' ? n >= 1000 && n <= 9999 : n <= 24)) {
        result[key] = n;
      }
    } else if (key == 'durationSeconds') {
      final parts = value.split(':');
      final n = parts.length == 2
          ? (double.tryParse(parts[0]) ?? 0) * 60 +
                (double.tryParse(parts[1]) ?? 0)
          : double.tryParse(value);
      if (n != null && n > 0 && n < 86400) result[key] = n;
    } else {
      final text = boundedText(value, max: 500);
      if (text.isNotEmpty) result[key] = text;
    }
  }
  return result;
}

String? chordProTitle(String document, String key) {
  final names = key == 'title'
      ? '(?:title|t)'
      : key == 'artist'
      ? '(?:artist|a)'
      : key;
  return RegExp(
    '^\\{$names:\\s*([^{}\\r\\n]+)\\}',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(document)?[1]?.trim();
}

final _metadataControls = RegExp(
  r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f\u202a-\u202e\u2066-\u2069]',
);

/// Single-line, control-free, length-capped text from an untrusted source;
/// empty string when [value] is not usable text.
String boundedText(Object? value, {int max = 300}) {
  if (value is! String) return '';
  var text = value
      .replaceAll(_metadataControls, '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text.length > max) {
    text = text.substring(0, max);
    final last = text.codeUnitAt(text.length - 1);
    if (last >= 0xd800 && last <= 0xdbff) {
      text = text.substring(0, text.length - 1);
    }
    text = text.trimRight();
  }
  return text;
}

Object? _boundedValue(Object? value, int depth) {
  if (value is String) {
    final text = boundedText(value, max: 500);
    return text.isEmpty ? null : text;
  }
  if (value is num) return value.isFinite && value.abs() < 1e15 ? value : null;
  if (value is bool) return value;
  if (depth >= 6) return null;
  if (value is List) {
    return value
        .take(30)
        .map((v) => _boundedValue(v, depth + 1))
        .nonNulls
        .toList();
  }
  if (value is Map) {
    final out = <String, dynamic>{};
    for (final entry in value.entries.take(50)) {
      final key = boundedText(entry.key.toString(), max: 80);
      final v = _boundedValue(entry.value, depth + 1);
      if (key.isNotEmpty && v != null) out[key] = v;
    }
    return out;
  }
  return null;
}

num? _ranged(Object? value, num min, num max, {bool whole = false}) {
  final n = value is String ? num.tryParse(value.trim()) : value;
  if (n is! num || !n.isFinite || n < min || n > max) return null;
  if (whole && n != n.round()) return null;
  return n;
}

/// Bounds metadata from a non-core provider before it is stored: known numeric
/// facts are range-checked (capo 0-24, tempo 1-500, years 1000-9999), media
/// links are normalised to `{kind, label?, url}` with safe https URLs, and every
/// other value is limited in type, nesting depth, list/map size and text length.
JsonMap sanitizeExtraMetadata(JsonMap input) {
  final result = <String, dynamic>{};
  const numeric = {
    'capo': (0, 24, true),
    'tempo': (1, 500, false),
    'year': (1000, 9999, true),
    'compositionYear': (1000, 9999, true),
    'durationSeconds': (0, 86400, false),
  };
  for (final entry in input.entries) {
    final key = boundedText(entry.key, max: 80);
    if (key.isEmpty) continue;
    if (key == 'mediaLinks') {
      final links = <JsonMap>[];
      final seen = <String>{};
      for (final raw in maps(entry.value).take(30)) {
        final url = httpsLink(raw['url']);
        final kind = boundedText(raw['kind'] ?? raw['type'], max: 60);
        final label = boundedText(raw['label']);
        if (url != null && kind.isNotEmpty && seen.add(url)) {
          links.add({'kind': kind, 'url': url, if (label.isNotEmpty) 'label': label});
        }
      }
      if (links.isNotEmpty) result[key] = links;
      continue;
    }
    final rule = numeric[key];
    if (rule != null) {
      final n = _ranged(entry.value, rule.$1, rule.$2, whole: rule.$3);
      if (n != null) result[key] = n;
      continue;
    }
    if (key == 'artworkUrl' ||
        key == 'sourceIllustrationUrl' ||
        key == 'originalSourceUrl' ||
        key == 'sourcePageUrl') {
      final url = httpsLink(entry.value);
      if (url != null) result[key] = url;
      continue;
    }
    final v = _boundedValue(entry.value, 0);
    if (v != null) result[key] = v;
  }
  return result;
}

/// Remote ChordPro must not carry Singbook's own provenance, rights or timing
/// extensions. Call before [requireSongText] on every remote body.
String remoteChordPro(String text) => stripVerseDirectives(text);

void requireSongText(String text) {
  if (text.length > 512 * 1024 ||
      text.trim().isEmpty ||
      RegExp(r'<(?:!doctype|html|body)', caseSensitive: false).hasMatch(text)) {
    throw const ProviderException('invalid_response');
  }
}
