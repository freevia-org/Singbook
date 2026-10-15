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
        blockedPageReason;

String stringValue(Object? value) => value is String ? value.trim() : '';
String textValue(Object? value) =>
    html.parseFragment(stringValue(value)).text ?? '';
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
      if (n != null && n >= 0) result[key] = n;
    } else if (key == 'durationSeconds') {
      final parts = value.split(':');
      final n = parts.length == 2
          ? (double.tryParse(parts[0]) ?? 0) * 60 +
                (double.tryParse(parts[1]) ?? 0)
          : double.tryParse(value);
      if (n != null && n > 0 && n < 86400) result[key] = n;
    } else {
      result[key] = value;
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
