import 'dart:convert';

import 'package:html/dom.dart' as dom;

import '../../domain/models.dart';
import '../../domain/arrangement.dart' show chordPattern;
import '../core/common.dart';
import '../extra/common.dart' show normalized, sourceEvidence;
import '../provider.dart';

const _host = 'www.chords-and-tabs.net';
const _base = 'https://$_host';
const _maxSearchResults = 100;
const _maxChartRows = 2000;
const _maxBodyCharacters = 512 * 1024;
const _maxPageBytes = 1024 * 1024;
final _songPathPattern = RegExp(
  r"^/song/name/[a-z0-9_%'-]+$",
  caseSensitive: false,
);
const _accentFold = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
};

String _matchText(String value) => normalized(value).replaceAllMapped(
  RegExp('[${_accentFold.keys.join()}]'),
  (match) => _accentFold[match[0]]!,
);

bool _matchesQuery(String query, String text) {
  final haystack = _matchText(text);
  final tokens = _matchText(
    query,
  ).split(' ').where((token) => token.isNotEmpty);
  return tokens.isNotEmpty && tokens.every(haystack.contains);
}

/// Public chart and lyric pages on Chords and Tabs.
///
/// Search results and charts are user-submitted. A page is accepted only when
/// its own title and artist match the selected result and its chart contains
/// chord-positioned, word-bearing song lines.
class ChordsAndTabsProvider implements LyricsProvider {
  ChordsAndTabsProvider(this.transport);

  final ProviderTransport transport;

  @override
  final definition = const ProviderDefinition(
    id: 'chordsandtabs',
    name: 'Chords and Tabs',
    capabilities: {'catalog', 'lyrics', 'chords', 'metadata'},
    accessMode: 'publicPage',
    website: _base,
  );

  static String _checkedPath(String value) {
    final uri = Uri.tryParse(value);
    final path = uri == null ? value : uri.path;
    if (value.length > 1500 ||
        uri == null ||
        (uri.isAbsolute
            ? (uri.origin != _base || uri.userInfo.isNotEmpty)
            : (uri.hasAuthority || uri.scheme.isNotEmpty)) ||
        uri.hasQuery ||
        uri.hasFragment ||
        !_songPathPattern.hasMatch(path) ||
        RegExp(r'%2f|%5c|%00|%2e', caseSensitive: false).hasMatch(path)) {
      throw const ProviderException('invalid_selection');
    }
    return path;
  }

  static List<SongCandidate> parseSearch(String source, String query) {
    final document = parseHtml(source);
    final results = <SongCandidate>[];
    final seen = <String>{};
    final anchors = document.querySelectorAll('a[href]');
    if (anchors.length > 10000) {
      throw const ProviderException('invalid_response');
    }
    for (final anchor in anchors) {
      final pathValue = anchor.attributes['href'];
      if (pathValue == null) continue;
      String path;
      try {
        path = _checkedPath(pathValue);
      } on ProviderException {
        continue;
      }
      final labels = anchor.querySelectorAll('.songtype');
      if (labels.isEmpty ||
          !labels.any(
            (label) =>
                label.classes.contains('typechords') ||
                label.classes.contains('typeukulele'),
          )) {
        // Tabs and bass tabs do not provide the chord-and-lyric chart format.
        continue;
      }
      final heading = anchor.querySelector('b');
      final titleLine = clean(heading?.text, 500);
      if (titleLine == null) continue;
      final divider = titleLine.indexOf(' - ');
      if (divider <= 0 || divider + 3 >= titleLine.length) continue;
      final artist = titleLine.substring(0, divider).trim();
      final title = titleLine.substring(divider + 3).trim();
      if (artist.isEmpty ||
          title.isEmpty ||
          !_matchesQuery(query, '$artist $title') ||
          !seen.add(path)) {
        continue;
      }
      results.add(
        SongCandidate(
          providerId: 'chordsandtabs',
          id: path,
          title: title,
          artist: artist,
          url: '$_base$path',
          metadata: const {'identityScope': 'arrangement'},
        ),
      );
      if (results.length >= _maxSearchResults) break;
    }
    if (results.isEmpty) throwIfBlocked(source);
    return results;
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final cleanQuery = queryText(query.replaceAll(RegExp(r'\s+'), ' '));
    // The site's POST form redirects to this GET route. Use the resulting
    // public route directly so ordinary redirect policy and caching apply.
    final uri = Uri.parse(
      '$_base/songs/search/${Uri.encodeComponent(cleanQuery)}',
    );
    final source = await transport.getText(
      uri,
      cancel: cancel,
      maxBytes: _maxPageBytes,
      allowedHosts: {_host},
    );
    return parseSearch(source, cleanQuery);
  }

  static SourceResult parsePage(String source, SongCandidate selected) {
    if (selected.providerId != 'chordsandtabs') {
      throw const ProviderException('invalid_selection');
    }
    final path = _checkedPath(selected.id);
    final expectedUrl = '$_base$path';
    if (selected.url != expectedUrl) {
      throw const ProviderException('invalid_selection');
    }
    final document = parseHtml(source);
    final canonical = document
        .querySelector('link[rel="canonical"]')
        ?.attributes['href'];
    if (canonical != null && _checkedPath(canonical) != path) {
      throw const ProviderException('identity_mismatch');
    }

    final header = document.querySelector('h1');
    if (header == null) throw const ProviderException('extraction_failed');
    final schema = _musicRecording(document);
    final pageTitle = clean(schema?['name']) ?? _titleFromHeading(header);
    final pageArtist =
        clean(
          (schema?['byArtist'] is Map)
              ? jsonMap(schema!['byArtist'])['name']
              : null,
        ) ??
        _artistFromHeading(header);
    if (pageTitle == null || pageArtist == null) {
      throw const ProviderException('extraction_failed');
    }
    if (_matchText(pageTitle) != _matchText(selected.title) ||
        _matchText(pageArtist) != _matchText(selected.artist)) {
      throw const ProviderException('identity_mismatch');
    }

    final chartType = document.querySelector('.songtype');
    if (chartType == null ||
        !(chartType.classes.contains('typechords') ||
            chartType.classes.contains('typeukulele'))) {
      throw const ProviderException('unavailable');
    }
    final chart = document.querySelector('#snippet--snippetXteView');
    if (chart == null) throw const ProviderException('extraction_failed');
    final rows = chart.querySelectorAll('.song');
    if (rows.isEmpty || rows.length > _maxChartRows) {
      throw const ProviderException('unavailable');
    }

    final lines = <_ChartLine>[];
    for (final row in rows) {
      if (row.text.length > 10000) {
        throw const ProviderException('invalid_response');
      }
      lines.addAll(_parseSongRow(row));
      if (lines.length > 10000) {
        throw const ProviderException('invalid_response');
      }
    }
    final lyricLines = lines.where((line) => _hasWords(line.text)).toList();
    if (lyricLines.isEmpty ||
        !lyricLines.any((line) => line.chords.isNotEmpty)) {
      throw const ProviderException('unavailable');
    }

    final body = lines.map((line) => line.chordPro).join('\n');
    if (body.trim().isEmpty || body.length > _maxBodyCharacters) {
      throw const ProviderException('invalid_response');
    }
    final metadata = _explicitMetadata(document);
    final candidate = SongCandidate(
      providerId: selected.providerId,
      id: selected.id,
      title: selected.title,
      artist: selected.artist,
      album: selected.album,
      url: expectedUrl,
      metadata: {...selected.metadata, ...metadata},
    );
    const attribution = 'Chords and Tabs';
    return SourceResult(
      candidate: candidate,
      body: body,
      metadata: candidate.metadata,
      attribution: attribution,
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        ...sourceEvidence(
          candidate,
          attribution: attribution,
          provenanceNote:
              'Read from a public chart page; redistribution permission is '
              'unknown. Sharing or exporting the text is the user\'s '
              'responsibility.',
        ),
        'chartInstrument': chartType.classes.contains('typeukulele')
            ? 'ukulele'
            : 'guitar',
      },
    );
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final path = _checkedPath(candidate.id);
    if (candidate.url != '$_base$path') {
      throw const ProviderException('invalid_selection');
    }
    final source = await transport.getText(
      Uri.https(_host, path),
      cancel: cancel,
      maxBytes: _maxPageBytes,
      allowedHosts: {_host},
    );
    cancel?.throwIfCancelled();
    return parsePage(source, candidate);
  }
}

Map<String, dynamic>? _musicRecording(dom.Document document) {
  for (final script in document.querySelectorAll(
    'script[type="application/ld+json"]',
  )) {
    try {
      final decoded = jsonDecode(script.text);
      if (decoded is Map && decoded['@type'] == 'MusicRecording') {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is List) {
        for (final value in decoded.whereType<Map>()) {
          if (value['@type'] == 'MusicRecording') {
            return Map<String, dynamic>.from(value);
          }
        }
      }
    } catch (_) {
      // Fall back to the visible heading when optional JSON-LD is malformed.
    }
  }
  return null;
}

String? _titleFromHeading(dom.Element heading) {
  final byline = heading.querySelector('a')?.text.trim();
  final text = clean(heading.text, 500);
  if (text == null) return null;
  if (byline == null || byline.isEmpty) {
    final divider = text.indexOf(' - ');
    return divider > 0 ? text.substring(divider + 3).trim() : null;
  }
  final rest = text
      .replaceFirst(byline, '')
      .replaceFirst(RegExp(r'^\s*-\s*'), '')
      .trim();
  return rest.isEmpty ? null : rest;
}

String? _artistFromHeading(dom.Element heading) {
  final byline = clean(heading.querySelector('a')?.text, 300);
  if (byline != null) return byline;
  final text = clean(heading.text, 500);
  final divider = text?.indexOf(' - ') ?? -1;
  return divider > 0 ? text!.substring(0, divider).trim() : null;
}

bool _hasWords(String value) =>
    RegExp(r'\p{L}{2}', unicode: true).hasMatch(value) &&
    !RegExp(
      r'^\s*(?:[A-Geb]?\|)?[-|x\d~hpbr/\\]{4,}',
      caseSensitive: false,
    ).hasMatch(value) &&
    !RegExp(
      r'^\s*(?:intro|outro|solo|interlude|instrumental|repeat|strum(?:ming)?|capo|tuning|key|chords?|end(?:ing)?|fade out)\b',
      caseSensitive: false,
    ).hasMatch(value.trim());

List<_ChartLine> _parseSongRow(dom.Element row) {
  final lines = <_ChartLine>[];
  var text = StringBuffer();
  var chords = <({int offset, String symbol})>[];

  void flush() {
    final value = text.toString().replaceAll(RegExp(r'[ \t]+$'), '');
    if (value.trim().isNotEmpty || chords.isNotEmpty) {
      lines.add(_ChartLine(value, chords));
    }
    text = StringBuffer();
    chords = <({int offset, String symbol})>[];
  }

  void appendText(String value) {
    final pieces = value.split('\n');
    for (var i = 0; i < pieces.length; i++) {
      if (pieces[i].isNotEmpty) text.write(pieces[i]);
      if (i + 1 < pieces.length) flush();
    }
  }

  void visit(dom.Node node) {
    if (node is dom.Text) {
      appendText(node.data.replaceAll('\r', ''));
      return;
    }
    if (node is! dom.Element) return;
    if (node.localName == 'br') {
      flush();
      return;
    }
    if (node.localName == 'sup') {
      final symbol = node.text.trim();
      final wrapped = '[$symbol]';
      final match = chordPattern.firstMatch(wrapped);
      if (symbol.length <= 128 &&
          match?.start == 0 &&
          match?.end == wrapped.length) {
        chords.add((offset: text.length, symbol: symbol));
        return;
      }
    }
    for (final child in node.nodes) {
      visit(child);
    }
  }

  for (final child in row.nodes) {
    visit(child);
  }
  flush();
  return lines;
}

JsonMap _explicitMetadata(dom.Document document) {
  final result = <String, dynamic>{};
  for (final badge in document.querySelectorAll('.x-badge')) {
    final value = clean(badge.text, 100);
    if (value == null) continue;
    final key = RegExp(
      r'^Key:\s*([A-G](?:#|b|♯|♭)?m?)$',
      caseSensitive: false,
    ).firstMatch(value);
    if (key != null) result['key'] = key[1];
    final capo = RegExp(
      r'^Capo:\s*(\d{1,2})$',
      caseSensitive: false,
    ).firstMatch(value);
    if (capo != null) result['capo'] = int.tryParse(capo[1]!);
    final tuning = RegExp(
      r'^Tuning:\s*([A-Ga-g#b♯♭0-9 ]{1,50})$',
    ).firstMatch(value);
    if (tuning != null) {
      final notes = tuning[1]!
          .trim()
          .split(RegExp(r'\s+'))
          .map((note) => '${note[0].toUpperCase()}${note.substring(1)}')
          .toList();
      result['tuning'] = notes;
    }
  }
  return sanitizeMetadata(result);
}

class _ChartLine {
  const _ChartLine(this.text, this.chords);
  final String text;
  final List<({int offset, String symbol})> chords;

  String get chordPro {
    final out = StringBuffer();
    var cursor = 0;
    for (final chord in chords) {
      final offset = chord.offset.clamp(cursor, text.length);
      out.write(plainToChordPro(text.substring(cursor, offset)));
      out.write('[${chord.symbol}]');
      cursor = offset;
    }
    out.write(plainToChordPro(text.substring(cursor)));
    return out.toString();
  }
}
