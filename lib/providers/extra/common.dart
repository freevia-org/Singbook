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
bool queryMatches(String query, String text) =>
    tokensMatch(queryTokens(query), normalized(text));

/// Normalised search tokens of [query]; compute once per search, not per row.
List<String> queryTokens(String query) =>
    normalized(query).split(' ').where((t) => t.isNotEmpty).toList();

/// [queryMatches] for precomputed [tokens] and an already [normalized]
/// haystack.
bool tokensMatch(List<String> tokens, String normalizedHaystack) =>
    tokens.isNotEmpty && tokens.every(normalizedHaystack.contains);

/// [normalized] identity that also ignores straight and curly apostrophes.
String normalizedIdentity(String value) => value
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

/// A JSON object with string keys, or `invalid_response`.
JsonMap strictObject(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const ProviderException('invalid_response');
  }
  return Map<String, dynamic>.from(value);
}

final _chordProSyntax = RegExp(r'[\\\[\]{}]');
final _chordProSyntaxAndHash = RegExp(r'[\\\[\]{}#]');

/// Backslash-escapes ChordPro syntax so source text stays literal lyric text.
/// [hash] also escapes `#`, which starts a ChordPro comment line.
String escapeChordPro(String text, {bool hash = false}) => text.replaceAllMapped(
  hash ? _chordProSyntaxAndHash : _chordProSyntax,
  (match) => '\\${match[0]}',
);

/// MusicBrainz identifiers and other canonical 8-4-4-4-12 hexadecimal UUIDs.
final uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Lower-cased MusicBrainz identifier, or null when [value] is not one.
String? mbidOrNull(Object? value) =>
    value is String && uuidPattern.hasMatch(value) ? value.toLowerCase() : null;

/// Whether [text] needs more than [limit] bytes as UTF-8, without encoding it
/// when its UTF-16 length already decides the answer.
bool utf8Exceeds(String text, int limit) {
  if (text.length > limit) return true;
  if (text.length * 3 <= limit) return false;
  return utf8.encode(text).length > limit;
}

/// Resolves an untrusted, possibly relative reference against [base]. A
/// malformed reference yields null instead of a [FormatException].
Uri? resolvedUri(Uri base, String? reference) {
  if (reference == null) return null;
  final parsed = Uri.tryParse(reference);
  if (parsed == null) return null;
  try {
    return base.resolveUri(parsed);
  } on FormatException {
    return null;
  } on StateError {
    return null;
  } on ArgumentError {
    return null;
  }
}

/// https on one of [hosts], without userinfo or a non-default port.
bool isPlainHttpsUrl(Uri uri, Set<String> hosts) =>
    uri.scheme == 'https' &&
    hosts.contains(uri.host) &&
    uri.userInfo.isEmpty &&
    (!uri.hasPort || uri.port == 443);

/// Serialises one adapter's requests and keeps [interval] between them, for
/// publishers whose documented limit is stricter than the transport's host
/// pacing. A cancelled caller stops waiting immediately; its slot is skipped.
class PacedQueue {
  PacedQueue(this.interval);
  final Duration interval;
  Future<void> _queue = Future.value();
  DateTime _next = DateTime.fromMillisecondsSinceEpoch(0);

  Future<T> run<T>(Future<T> Function() send, CancellationToken? cancel) {
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
        _next = DateTime.now().add(interval);
      }
    });
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}

/// A lazily loaded in-memory catalog. Loads are serialised, so overlapping
/// callers download once: a caller queued behind a successful load reuses its
/// value, and a failed or cancelled load is never cached. Each load runs with
/// its own caller's cancellation; a cancelled caller stops waiting at once.
class CatalogLoader<T extends Object> {
  T? _value;
  Future<void> _queue = Future.value();

  Future<T> load(Future<T> Function() fetch, CancellationToken? cancel) {
    final result = _queue.then((_) async {
      cancel?.throwIfCancelled();
      return _value ??= await fetch();
    });
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    if (cancel == null) return result;
    return Future.any([
      result,
      cancel.cancelled.then<T>((_) {
        throw const ProviderException('cancelled');
      }),
    ]);
  }
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
      !isPlainHttpsUrl(uri, hosts) ||
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

/// Control and bidi-override characters never kept in source text.
final sourceControlChars = RegExp(
  r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f\u202a-\u202e\u2066-\u2069]',
);

/// Single-line, control-free, length-capped text from an untrusted source;
/// empty string when [value] is not usable text.
String boundedText(Object? value, {int max = 300}) {
  if (value is! String) return '';
  var text = value
      .replaceAll(sourceControlChars, '')
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
