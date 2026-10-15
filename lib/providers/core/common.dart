import 'dart:convert';
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
        blockedPageReason,
        geniusImageHosts,
        deezerImageHosts,
        youtubeImageHosts;

final _controlChars = RegExp(
  r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f\u202a-\u202e\u2066-\u2069]',
);

/// Normalises provider text: control and bidi-override characters are removed,
/// lone CR / U+2028 / U+2029 become line feeds, and the result is trimmed.
/// Over-length or blank values yield null.
String? clean(dynamic value, [int max = 300]) {
  if (value is! String || value.length > max) return null;
  final text = value
      .replaceAll(_controlChars, '')
      .replaceAll(RegExp(r'\r\n?|[\u2028\u2029]'), '\n')
      .trim();
  return text.isEmpty ? null : text;
}
Map<String, dynamic> object(dynamic value) {
  if (value is! Map) throw const ProviderException('invalid_response');
  return Map<String, dynamic>.from(value);
}

List<dynamic> array(dynamic value) {
  if (value is! List) throw const ProviderException('invalid_response');
  return value;
}

String requiredText(dynamic value, [int max = 300]) {
  var text = clean(value, max);
  if (text == null) {
    if (value is String && value.length > max && value.trim().isNotEmpty) {
      throw const ProviderException('invalid_response', 'too_large');
    }
    throw const ProviderException('invalid_response', 'Missing identity');
  }
  // Identity fields are single-line; long documents (lyrics, TTML) are not.
  if (max <= 1500) text = text.replaceAll(RegExp(r'\s*\n\s*'), ' ');
  return text;
}

String numericId(dynamic value) {
  final text = value.toString();
  if (!RegExp(r'^[1-9]\d{0,14}$').hasMatch(text)) {
    throw const ProviderException('invalid_response');
  }
  return text;
}

double? durationValue(dynamic value) =>
    value is num && value.isFinite && value > 0 && value <= 86400
    ? value.toDouble()
    : null;
/// https only, no userinfo, public-looking host; null (dropped) otherwise.
String? httpsUrl(dynamic value, {Set<String>? hosts}) =>
    safeHttpsUrl(value, hostSuffixes: hosts);

/// Parses result rows independently: a malformed row is skipped rather than
/// failing the whole list. If rows were present but none were usable the
/// response shape is wrong and `invalid_response` is thrown.
List<SongCandidate> parseRows(
  Iterable<dynamic> rows,
  SongCandidate Function(dynamic row) parse,
) {
  final results = <SongCandidate>[];
  var attempted = 0;
  for (final row in rows) {
    attempted++;
    try {
      results.add(parse(row));
    } on ProviderException {
      /* Skip malformed row. */
    } on FormatException {
      /* Skip malformed row. */
    } on TypeError {
      /* Skip malformed row. */
    }
  }
  if (attempted > 0 && results.isEmpty) {
    throw const ProviderException('invalid_response', 'No usable rows');
  }
  return results;
}

JsonMap sanitizeMetadata(JsonMap input) {
  final result = <String, dynamic>{};
  for (final key in [
    'key',
    'timeSignature',
    'album',
    'genre',
    'language',
    'difficulty',
    'recording',
    'releaseDate',
  ]) {
    final text = clean(input[key]);
    if (text != null) result[key] = text;
  }
  for (final e in {
    'capo': [0, 24],
    'tempo': [1, 500],
    'duration': [0, 86400],
    'year': [1000, 9999],
  }.entries) {
    final value = input[e.key];
    if (value is num &&
        value.isFinite &&
        value >= e.value[0] &&
        value <= e.value[1] &&
        (!['capo', 'year'].contains(e.key) || value == value.round())) {
      result[e.key] = value;
    }
  }
  final tuning = input['tuning'];
  if (tuning is List &&
      tuning.isNotEmpty &&
      tuning.length <= 12 &&
      tuning.every(
        (n) => n is String && RegExp(r'^[A-G][#b♯♭]?[0-9]?$').hasMatch(n),
      )) {
    result['tuning'] = tuning;
  }
  final art = httpsUrl(input['artworkUrl']);
  if (art != null) result['artworkUrl'] = art;
  if (input['mediaLinks'] is List) {
    final seen = <String>{};
    final links = <JsonMap>[];
    for (final raw in (input['mediaLinks'] as List).take(30)) {
      final link = jsonMap(raw), url = httpsUrl(jsonMap(raw)['url']);
      final kind = clean(link['kind'], 60);
      if (url != null && kind != null && seen.add(url)) {
        links.add({
          'kind': kind,
          'url': url,
          if (clean(link['label']) != null) 'label': clean(link['label']),
        });
      }
    }
    if (links.isNotEmpty) result['mediaLinks'] = links;
  }
  if (input['credits'] is List) {
    final seen = <String>{};
    final credits = <JsonMap>[];
    for (final raw in (input['credits'] as List).take(100)) {
      final c = jsonMap(raw),
          role = clean(jsonMap(raw)['role'], 100),
          name = clean(jsonMap(raw)['name']);
      if (role != null && name != null && seen.add('$role:$name')) {
        credits.add({'role': role, 'name': name});
      }
      // Metadata is intentionally limited to explicit source facts.
      if (c.isEmpty) continue;
    }
    if (credits.isNotEmpty) result['credits'] = credits;
  }
  return result;
}

String plainToChordPro(String plain) => plain
    .split('\n')
    .map((line) {
      final section = RegExp(r'^\[([^\]]+)\]$').firstMatch(line.trim());
      if (section != null) {
        return '{comment: ${section[1]!.replaceAll(RegExp(r'[{}]'), '')}}';
      }
      // Escape syntax so ordinary source text cannot become directives or chords.
      return line
          .replaceAll('\\', '\\\\')
          .replaceAll('[', r'\[')
          .replaceAll(']', r'\]')
          .replaceAll('{', r'\{')
          .replaceAll('}', r'\}');
    })
    .join('\n');
String meaningfulLyrics(dynamic value) {
  if (value is String && value.length > 200000) {
    throw const ProviderException('invalid_response', 'too_large');
  }
  final text = clean(value, 200000);
  if (text == null ||
      !text
          .split('\n')
          .any(
            (l) =>
                l.trim().isNotEmpty &&
                !RegExp(
                  r'^(?:\[?instrumental\]?|no lyrics(?: available)?|lyrics (?:unavailable|not found))\.?$',
                  caseSensitive: false,
                ).hasMatch(l.trim()),
          )) {
    throw const ProviderException('unavailable');
  }
  return text;
}

String encodeSelection(SongCandidate song) =>
    'v1.${base64Url.encode(utf8.encode(jsonEncode(song.toJson()))).replaceAll('=', '')}';
SongCandidate decodeSelection(String id, String provider) {
  try {
    if (!id.startsWith('v1.') || id.length > 16384) {
      throw const FormatException();
    }
    final song = SongCandidate.fromJson(
      object(
        jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(id.substring(3)))),
        ),
      ),
    );
    if (song.providerId != provider ||
        song.title.isEmpty ||
        song.artist.isEmpty) {
      throw const FormatException();
    }
    return song;
  } catch (_) {
    throw const ProviderException('invalid_selection');
  }
}

SongCandidate copyCandidate(
  SongCandidate song, {
  String? id,
  String? providerId,
  JsonMap? metadata,
  String? url,
}) => SongCandidate(
  providerId: providerId ?? song.providerId,
  id: id ?? song.id,
  title: song.title,
  artist: song.artist,
  album: song.album,
  durationSeconds: song.durationSeconds,
  url: url ?? song.url,
  metadata: metadata ?? song.metadata,
  recordingIds: song.recordingIds,
);
SourceResult lyricsResult(
  SongCandidate song,
  String lyrics, {
  List<TimingTrack> timing = const [],
  String? attribution,
}) {
  final timingOnly = lyrics.trim().isEmpty && timing.any((track) => track.raw?.isNotEmpty == true);
  return SourceResult(
    candidate: song,
    body: timingOnly ? '' : plainToChordPro(meaningfulLyrics(lyrics)),
    metadata: song.metadata,
    timingTracks: timing,
    attribution: attribution,
    retrievedAt: DateTime.now().toUtc(),
    extra: {
      'parserVersion': 'verse-core-1',
      'sourceDocumentId': song.identity,
      'rights': scrapedRights(song.url, attribution),
      if (timingOnly) 'timingOnly': true,
    },
  );
}

/// Conservative rights record for text fetched from third-party APIs or pages:
/// the source has not granted Singbook any redistribution license, so the status
/// stays `unknown` and sharing/exporting the text is the user's responsibility.
JsonMap scrapedRights(String? sourceUrl, String? attribution) => {
  'status': 'unknown',
  'sourceUrl': sourceUrl,
  'attribution': attribution,
  'note':
      'Retrieved from a third-party or unofficial source; no redistribution '
      'license is established. Sharing or exporting is the user\'s responsibility.',
};
