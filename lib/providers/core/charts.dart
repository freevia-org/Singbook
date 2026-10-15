import 'dart:convert';
import 'package:html/dom.dart' as dom;
import '../../domain/models.dart';
import '../provider.dart';
import 'common.dart';

class _Line {
  _Line(this.text, [this.chords = const []]);
  String text;
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

String _chartPath(String value, String provider, {bool selection = false}) {
  final origin = provider == 'songsterr'
      ? 'https://www.songsterr.com'
      : 'https://tabs.ultimate-guitar.com';
  final uri = Uri.parse(origin).resolve(value);
  final path = provider == 'songsterr'
      ? uri.path.replaceFirst(RegExp(r'-tab-s(?=\d+$)'), '-chords-s')
      : uri.path;
  final pattern = provider == 'songsterr'
      ? RegExp(
          r"^/a/wsa/[a-z0-9_%'-]+-chords-s([1-9]\d{0,14})$",
          caseSensitive: false,
        )
      : RegExp(
          r"^/tab/[a-z0-9_%'-]+/[a-z0-9_%'-]+-chords-([1-9]\d{0,14})$",
          caseSensitive: false,
        );
  if (value.length > 1500 ||
      uri.origin != origin ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      !pattern.hasMatch(path) ||
      RegExp(r'%2f|%5c|%00', caseSensitive: false).hasMatch(path) ||
      (selection && value != path)) {
    throw ProviderException(
      selection ? 'invalid_selection' : 'invalid_response',
    );
  }
  return path;
}

String _pathId(String path) => RegExp(r'(\d+)$').firstMatch(path)![1]!;

class SongsterrProvider implements LyricsProvider {
  SongsterrProvider(this.http);
  final ProviderTransport http;
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'songsterr',
    name: 'Songsterr',
    capabilities: {'catalog', 'lyrics', 'chords', 'metadata'},
    accessMode: 'public_page',
    website: 'https://www.songsterr.com',
  );
  static JsonMap _state(String source, [dom.Document? parsed]) {
    try {
      final document = parsed ?? parseHtml(source);
      // The type attribute is optional in fallback markup.
      final node =
          document.querySelector('script#state[type="application/json"]') ??
          document.querySelector('script#state');
      return object(jsonDecode(node?.text ?? ''));
    } catch (_) {
      throwIfBlocked(source);
      throw const ProviderException('extraction_failed');
    }
  }

  static SongCandidate _song(
    JsonMap data,
    String path, {
    JsonMap metadata = const {},
  }) => SongCandidate(
    providerId: 'songsterr',
    id: path,
    title: requiredText(data['title']),
    artist: requiredText(data['artist']),
    album: clean(metadata['album']),
    url: 'https://www.songsterr.com$path',
    metadata: metadata,
  );
  static List<SongCandidate> parseSearch(String source) {
    final doc = parseHtml(source),
        state = _state(source, doc),
        paths = <String, String>{};
    for (final a in doc.querySelectorAll('a[href]')) {
      try {
        final path = _chartPath(a.attributes['href']!, 'songsterr');
        paths[_pathId(path)] = path;
      } catch (_) {
        /* Non-chart link. */
      }
    }
    final results = <SongCandidate>[], seen = <String>{};
    for (final raw in array(
      jsonMap(jsonMap(state['songs'])['songs'])['list'],
    ).take(200)) {
      final entry = jsonMap(raw),
          id = jsonMap(raw)['songId'].toString(),
          path = paths[jsonMap(raw)['songId'].toString()];
      if (path == null ||
          entry['hasChords'] != true ||
          entry['isJunk'] == true ||
          !seen.add(id)) {
        continue;
      }
      try {
        results.add(_song(entry, path));
      } on ProviderException {
        /* Ignore incomplete hit. */
      }
    }
    return results;
  }

  static String _chord(dynamic raw) {
    final data = object(raw),
        root = jsonMap(object(raw)['baseNote'])['name'],
        bass = jsonMap(object(raw)['firstNote'])['name'];
    final suffix = jsonMap(data['chordType'])['suffix'];
    if (root is! String ||
        bass is! String ||
        suffix is! String ||
        !RegExp(r'^[A-G](?:#|b|♯|♭){0,2}$').hasMatch(root) ||
        !RegExp(r'^[A-G](?:#|b|♯|♭){0,2}$').hasMatch(bass) ||
        !RegExp(r'^[A-Za-z0-9#b♯♭()+−°øΔ-]{0,40}$').hasMatch(suffix)) {
      throw const ProviderException('invalid_response');
    }
    return '$root$suffix${root != bass ? '/$bass' : ''}';
  }

  static SourceResult parsePage(String source, String requestedId) {
    final path = _chartPath(requestedId, 'songsterr', selection: true),
        document = parseHtml(source),
        state = _state(source, document);
    final current = jsonMap(jsonMap(state['chords'])['current']);
    if (current['songId'].toString() != _pathId(path)) {
      throw const ProviderException('invalid_response', 'Different chart');
    }
    final canonical = document
        .querySelector('link[rel="canonical"]')
        ?.attributes['href'];
    if (canonical != null &&
        _pathId(_chartPath(canonical, 'songsterr')) != _pathId(path)) {
      throw const ProviderException('invalid_response');
    }
    final rows = array(jsonMap(state['chordpro'])['current']);
    if (rows.isEmpty) throw const ProviderException('unavailable');
    if (rows.length > 5000) throw const ProviderException('invalid_response');
    final lines = <_Line>[],
        metadata = <String, dynamic>{
          'mediaLinks': <JsonMap>[
            {
              'kind': 'sheet',
              'label': 'Songsterr',
              'url': 'https://www.songsterr.com$path',
            },
          ],
        };
    var lyricRows = 0, lyricCharacters = 0, anchorCount = 0;
    for (final raw in rows) {
      final row = object(raw), type = object(raw)['type'];
      if (type == 'line') {
        final pieces = array(row['line']).map(jsonMap).toList();
        if (pieces.length > 1000) {
          throw const ProviderException('invalid_response');
        }
        var text = '', lyricText = '';
        final anchors = <({int offset, String symbol})>[];
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece['type'] == 'chord') {
            var symbol = _chord(piece['chord']);
            if (i + 2 < pieces.length &&
                pieces[i + 1]['type'] == 'noise' &&
                pieces[i + 1]['text'] == '/' &&
                pieces[i + 2]['type'] == 'chord') {
              final bass = _chord(pieces[i + 2]['chord']);
              if (RegExp(r'^[A-G][#b♯♭]?$').hasMatch(bass) &&
                  !symbol.contains('/')) {
                symbol += '/$bass';
                i += 2;
              }
            }
            if (i + 1 < pieces.length &&
                pieces[i + 1]['type'] == 'noise' &&
                pieces[i + 1]['text'] is String) {
              final suffix = RegExp(
                r'^(?:[-+](?:5|9|11|13)|\((?:add|no|sus)?[b#]?\d{1,2}\))(?=\s|$)',
              ).firstMatch(pieces[i + 1]['text'] as String);
              if (suffix != null) {
                symbol += suffix[0]!;
                pieces[i + 1] = {
                  ...pieces[i + 1],
                  'text': (pieces[i + 1]['text'] as String).substring(
                    suffix[0]!.length,
                  ),
                };
              }
            }
            anchors.add((offset: text.length, symbol: symbol));
          } else if (piece['type'] == 'text' || piece['type'] == 'noise') {
            final value = piece['text'];
            if (value is! String ||
                value.length > 20000 ||
                RegExp(r'[\r\n\x00-\x08\x0b-\x1f\x7f]').hasMatch(value)) {
              throw const ProviderException('invalid_response');
            }
            final normalized = value
                .replaceAll('\t', '    ')
                .replaceAll('\u00a0', ' ');
            text += normalized;
            if (piece['type'] == 'text') lyricText += normalized;
          } else {
            throw const ProviderException(
              'invalid_response',
              'Unknown chart content',
            );
          }
        }
        if (text.length > 20000 || anchors.length > 300) {
          throw const ProviderException('invalid_response');
        }
        lines.add(_Line(text, anchors));
        anchorCount += anchors.length;
        if (RegExp(r'\p{L}', unicode: true).hasMatch(lyricText)) {
          lyricRows++;
          lyricCharacters += lyricText.trim().length;
        }
      } else if (type == 'section' || type == 'comment') {
        final label = clean(row['text'])?.replaceAll(RegExp(r'\s*\n\s*'), ' ');
        if (label != null) lines.add(_Line('[$label]'));
      } else {
        if (!{
          'tuning',
          'capo',
          'key',
          'tempo',
          'time',
          'timeSignature',
          'title',
          'artist',
          'album',
          'subtitle',
        }.contains(type)) {
          throw const ProviderException(
            'invalid_response',
            'Unknown chart content',
          );
        }
        final value = clean(row['text']);
        if (value == null) continue;
        if (type == 'album' || type == 'key') metadata[type as String] = value;
        if (type == 'capo') metadata['capo'] = int.tryParse(value);
        if (type == 'tempo') {
          metadata['tempo'] = double.tryParse(
            value.replaceFirst(RegExp(r'\s*bpm$', caseSensitive: false), ''),
          );
        }
        if (type == 'time' || type == 'timeSignature') {
          metadata['timeSignature'] = value;
        }
        if (type == 'tuning') {
          final notes = RegExp(r'\(([^()]*)\)').firstMatch(value)?[1] ?? value;
          final pattern = RegExp(r'[A-G](?:#|b|♯|♭)?[0-8]?');
          if (notes
              .replaceAll(pattern, '')
              .replaceAll(RegExp(r'[\s,\-]'), '')
              .isEmpty) {
            metadata['tuning'] = pattern
                .allMatches(notes)
                .map((m) => m[0]!)
                .toList();
          }
        }
      }
    }
    if (lyricRows < 2 || lyricCharacters < 30 || anchorCount == 0) {
      throw const ProviderException('unavailable');
    }
    if (anchorCount > 10000 ||
        lines.fold<int>(0, (sum, line) => sum + line.text.length) > 200000) {
      throw const ProviderException('invalid_response');
    }
    final meta = jsonMap(jsonMap(state['meta'])['current']);
    if (meta['songId'].toString() == current['songId'].toString()) {
      for (final video
          in (meta['videos'] is List ? meta['videos'] as List : []).take(12)) {
        final v = jsonMap(video), id = jsonMap(video)['videoId'];
        if (v['status'] == 'done' &&
            id is String &&
            RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) {
          (metadata['mediaLinks'] as List).add({
            'kind': 'video',
            'label': 'YouTube',
            'url': 'https://www.youtube.com/watch?v=$id',
          });
        }
      }
    }
    final song = _song(current, path, metadata: sanitizeMetadata(metadata));
    return SourceResult(
      candidate: song,
      body: lines.map((l) => l.chordPro).join('\n'),
      metadata: song.metadata,
      attribution: 'Songsterr',
      retrievedAt: DateTime.now().toUtc(),
      extra: {'rights': scrapedRights(song.url, 'Songsterr')},
    );
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => parseSearch(
    await http.getText(
      Uri.https('www.songsterr.com', '/', {'pattern': queryText(query)}),
      cancel: cancel,
    ),
  );
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final path = _chartPath(candidate.id, 'songsterr', selection: true);
    return parsePage(
      await http.getText(
        Uri.parse('https://www.songsterr.com$path'),
        cancel: cancel,
      ),
      path,
    );
  }
}

class UltimateGuitarProvider implements LyricsProvider {
  UltimateGuitarProvider(this.http);
  final ProviderTransport http;
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'ultimateguitar',
    name: 'Ultimate Guitar',
    capabilities: {'catalog', 'lyrics', 'chords', 'metadata'},
    accessMode: 'public_page',
    website: 'https://www.ultimate-guitar.com',
  );
  static JsonMap _data(String source, [dom.Document? parsed]) {
    try {
      final nodes = (parsed ?? parseHtml(source)).querySelectorAll(
        '.js-store[data-content]',
      );
      // Prefer the single store node; if the layout has several, use the first
      // whose store.page.data is an object.
      for (final node in nodes) {
        try {
          return object(
            jsonMap(
              jsonMap(
                object(jsonDecode(node.attributes['data-content']!))['store'],
              )['page'],
            )['data'],
          );
        } catch (_) {
          continue;
        }
      }
      throw const FormatException();
    } catch (_) {
      throwIfBlocked(source);
      throw const ProviderException('extraction_failed');
    }
  }

  static SongCandidate _song(
    JsonMap tab,
    String path, {
    JsonMap metadata = const {},
  }) => SongCandidate(
    providerId: 'ultimateguitar',
    id: path,
    title: requiredText(tab['song_name']),
    artist: requiredText(tab['artist_name']),
    url: 'https://tabs.ultimate-guitar.com$path',
    metadata: metadata,
  );
  static List<SongCandidate> parseSearch(String source) {
    final results = <SongCandidate>[], seen = <String>{};
    for (final raw in array(_data(source)['results']).take(200)) {
      final tab = jsonMap(raw);
      if (tab['type'] != 'Chords' ||
          tab['tab_access_type'] != 'public' ||
          (tab['marketing_type'] != null && tab['marketing_type'] != '')) {
        continue;
      }
      try {
        final path = _chartPath(
          requiredText(tab['tab_url'], 1500),
          'ultimateguitar',
        );
        if (_pathId(path) != tab['id'].toString() || !seen.add(path)) continue;
        results.add(_song(tab, path, metadata: _metadata(tab, {}, path)));
      } on ProviderException {
        /* Ignore malformed search row. */
      }
    }
    return results;
  }

  static bool _section(String value) => RegExp(
    r'^\[(?:intro|verse|chorus|pre[- ]chorus|post[- ]chorus|bridge|outro|refrain|hook|solo|interlude|instrumental|coda)\b[^\]]{0,100}\]$',
    caseSensitive: false,
  ).hasMatch(value.trim());
  static bool _hasWords(String value) =>
      RegExp(r'\p{L}{2}', unicode: true).hasMatch(value) &&
      !_section(value) &&
      !RegExp(
        r'^(?:intro|outro|solo|interlude|instrumental|repeat|play|strum(?:ming)?|capo|tuning|key|chords?|end(?:ing)?|fade out)\b',
        caseSensitive: false,
      ).hasMatch(value.trim()) &&
      !RegExp(
        r'^\s*(?:[A-Geb]?\|)?[-|x\d~hpbr/\\]{4,}',
        caseSensitive: false,
      ).hasMatch(value);
  static const _accidentals = '#b♯♭';
  static const _chordWords = [
    'maj', 'min', 'dim', 'aug', 'sus', 'add', 'omit', 'no', 'M', 'm', 'Δ', 'ø',
    '°',
  ];

  /// Linear-time chord grammar (no regex backtracking on hostile input):
  /// root, any run of suffix tokens, optional slash bass, or N.C.
  static bool _validChord(String s) {
    if (s.length > 60) return false;
    if (const {'NC', 'N.C', 'NC.', 'N.C.'}.contains(s)) return true;
    var i = 0;
    bool isRoot(int c) => c >= 0x41 && c <= 0x47;
    bool isDigit(int c) => c >= 0x30 && c <= 0x39;
    // Accidentals up to two long, starting at [from]; returns the end index.
    int accidentals(int from) {
      var j = from;
      while (j < s.length && j - from < 2 && _accidentals.contains(s[j])) {
        j++;
      }
      return j;
    }

    if (s.isEmpty || !isRoot(s.codeUnitAt(0))) return false;
    i = accidentals(1);
    const symbols = '#b♯♭+−-';
    const parenChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789#b♯♭,+−-';
    while (i < s.length) {
      final c = s.codeUnitAt(i);
      if (isDigit(c)) {
        while (i < s.length && isDigit(s.codeUnitAt(i))) {
          i++;
        }
        continue;
      }
      if (symbols.contains(s[i])) {
        i++;
        continue;
      }
      if (c == 0x28) {
        final close = s.indexOf(')', i + 1);
        if (close < 0 || close - i - 1 < 1 || close - i - 1 > 20) return false;
        for (var k = i + 1; k < close; k++) {
          if (!parenChars.contains(s[k])) return false;
        }
        i = close + 1;
        continue;
      }
      if (c == 0x2f) {
        final rest = s.substring(i + 1);
        if (rest.startsWith('9')) {
          i += 2;
          continue;
        }
        if (rest.startsWith('11') || rest.startsWith('13')) {
          i += 3;
          continue;
        }
        break;
      }
      String? word;
      for (final w in _chordWords) {
        if (s.startsWith(w, i)) {
          word = w;
          break;
        }
      }
      if (word == null) return false;
      i += word.length;
    }
    if (i == s.length) return true;
    // Optional slash bass note.
    if (s.codeUnitAt(i) != 0x2f || i + 1 >= s.length) return false;
    if (!isRoot(s.codeUnitAt(i + 1))) return false;
    return accidentals(i + 2) == s.length;
  }

  static String _expand(String value, int start) {
    final result = StringBuffer();
    var length = 0;
    for (final unit in value.codeUnits) {
      if (unit == 0x09) {
        final pad = 8 - ((start + length) % 8);
        result.write(' ' * pad);
        length += pad;
      } else {
        result.writeCharCode(unit);
        length++;
      }
    }
    return result.toString();
  }

  static _UgRow _row(String raw) {
    final source = raw.replaceAll(
      RegExp(r'\[\/?tab\]', caseSensitive: false),
      '',
    );
    var cursor = 0, displayed = '', residual = '', inline = '';
    final positions = <({int offset, String symbol})>[],
        inlinePositions = <({int offset, String symbol})>[];
    for (final match in RegExp(
      r'\[ch\]([^\[\]\r\n]+)\[/ch\]',
      caseSensitive: false,
    ).allMatches(source)) {
      final before = source.substring(cursor, match.start),
          symbol = match[1]!.trim();
      if (!_validChord(symbol)) {
        throw const ProviderException('invalid_response');
      }
      final padding = _expand(before, displayed.length);
      displayed += padding;
      residual += padding;
      inline += _expand(before, inline.length);
      positions.add((offset: displayed.length, symbol: symbol));
      inlinePositions.add((offset: inline.length, symbol: symbol));
      displayed += match[1]!;
      residual += ' ' * match[1]!.length;
      cursor = match.end;
    }
    final tail = source.substring(cursor);
    displayed += _expand(tail, displayed.length);
    residual += _expand(tail, residual.length);
    inline += _expand(tail, inline.length);
    if (RegExp(r'\[\/?(?:ch|tab)\b', caseSensitive: false).hasMatch(inline) ||
        RegExp(r'[\x00-\x08\x0b-\x1f\x7f]').hasMatch(inline)) {
      throw const ProviderException('invalid_response');
    }
    return _UgRow(
      displayed.trimRight(),
      residual.trimRight(),
      inline.trimRight(),
      positions,
      inlinePositions,
      raw.toLowerCase().contains('[tab]'),
      raw.toLowerCase().contains('[/tab]'),
    );
  }

  static _Line _anchor(
    String value,
    List<({int offset, String symbol})> anchors,
  ) {
    var text = value.padRight(
      anchors.isEmpty ? value.length : anchors.last.offset,
    );
    return _Line(
      text,
      anchors.map((a) {
        var offset = a.offset;
        if (offset > 0 &&
            offset < text.length &&
            text.codeUnitAt(offset - 1) >= 0xd800 &&
            text.codeUnitAt(offset - 1) <= 0xdbff &&
            text.codeUnitAt(offset) >= 0xdc00 &&
            text.codeUnitAt(offset) <= 0xdfff) {
          offset++;
        }
        return (offset: offset, symbol: a.symbol);
      }).toList(),
    );
  }

  static String parseText(String content) {
    if (content.isEmpty || content.length > 200000) {
      throw const ProviderException('invalid_response');
    }
    final rawLines = content.replaceAll(RegExp(r'\r\n?'), '\n').split('\n');
    // Markup is removed per row, so allow slack over the 20000-char row cap but
    // reject before any per-character work on absurd lines.
    if (rawLines.any((l) => l.length > 40000)) {
      throw const ProviderException('invalid_response');
    }
    final rows = rawLines.map(_row).toList();
    final firstChord = rows.indexWhere((r) => r.positions.isNotEmpty);
    if (firstChord < 0) throw const ProviderException('unavailable');
    final firstSection = rows.indexWhere(
      (r) => _section(r.text) && !r.text.toLowerCase().startsWith('[coda'),
    );
    final start = firstSection >= 0 && firstSection <= firstChord
        ? firstSection
        : firstChord;
    final lines = <_Line>[];
    var lyricRows = 0, lyricCharacters = 0, count = 0;
    for (var i = start; i < rows.length; i++) {
      final row = rows[i];
      if (row.text.length > 20000 || row.positions.length > 300) {
        throw const ProviderException('invalid_response');
      }
      if (row.positions.isEmpty) {
        lines.add(_Line(row.text));
        continue;
      }
      count += row.positions.length;
      final next = i + 1 < rows.length ? rows[i + 1] : null;
      if (_hasWords(row.residual)) {
        lines.add(_anchor(row.inline, row.inlinePositions));
        lyricRows++;
        lyricCharacters += row.inline.trim().length;
      } else if (row.residual.trim().isEmpty &&
          next != null &&
          next.positions.isEmpty &&
          (_hasWords(next.text) ||
              row.opensTab &&
                  next.closesTab &&
                  RegExp(r'\p{L}{2}', unicode: true).hasMatch(next.text) &&
                  !_section(next.text))) {
        lines.add(_anchor(next.text, row.positions));
        lyricRows++;
        lyricCharacters += next.text.trim().length;
        i++;
      } else {
        lines.add(_anchor(row.residual, row.positions));
      }
    }
    if (count > 10000 || lines.length > 5000) {
      throw const ProviderException('invalid_response');
    }
    if (lyricRows < 2 || lyricCharacters < 30) {
      throw const ProviderException('unavailable');
    }
    return lines.map((l) => l.chordPro).join('\n').trim();
  }

  static JsonMap _metadata(JsonMap tab, JsonMap view, String path) {
    final meta = jsonMap(view['meta']),
        covers = jsonMap(jsonMap(tab['album_cover'])['web_album_cover']);
    final recording = jsonMap(tab['recording']);
    final preamble = <String, dynamic>{}, conflicts = <String>{};
    void add(String field, dynamic value) {
      if (conflicts.contains(field)) return;
      if (preamble.containsKey(field) &&
          jsonEncode(preamble[field]) != jsonEncode(value)) {
        preamble.remove(field);
        conflicts.add(field);
      } else {
        preamble[field] = value;
      }
    }

    final content = clean(jsonMap(view['wiki_tab'])['content'], 200000);
    if (content != null) {
      for (final raw in content.split('\n')) {
        // Preamble facts are short; never run the matchers on hostile lines.
        if (raw.length > 200) continue;
        final line = raw.trim();
        if (_section(line) || line.contains('[ch]')) break;
        RegExpMatch? match;
        if ((match = RegExp(
              r'^capo[ \t]{0,10}[:=-]?[ \t]{0,10}(?:on\s+(?:the\s+)?)?(\d{1,2})(?:st|nd|rd|th)?(?:\s+fret)?[.!]?$',
              caseSensitive: false,
            ).firstMatch(line)) !=
            null) {
          add('capo', int.parse(match![1]!));
        } else if (RegExp(
          r'^(?:capo\s*[:=-]\s*(?:none|no capo)|no capo)[.!]?$',
          caseSensitive: false,
        ).hasMatch(line)) {
          add('capo', 0);
        } else if ((match = RegExp(
              r'^(?:song\s+)?key\s*[:=-]\s*([A-G][#b♯♭]?(?:m|maj|min| major| minor)?)[.]?$',
              caseSensitive: false,
            ).firstMatch(line)) !=
            null) {
          add('key', match![1]);
        } else if ((match = RegExp(
              r'^(?:guitar\s+)?tuning\s*[:=-]\s*(.+)$',
              caseSensitive: false,
            ).firstMatch(line)) !=
            null) {
          final notes =
              RegExp(r'\(([^()]*)\)\s*$').firstMatch(match![1]!)?[1] ??
              match[1]!;
          add('tuning', notes.trim().split(RegExp(r'[\s,-]+')));
        } else if ((match = RegExp(
              r'^(?:tempo\s*[:=-]\s*(\d{1,3}(?:\.\d+)?)\s*(?:bpm)?|bpm\s*[:=-]\s*(\d{1,3}(?:\.\d+)?))$',
              caseSensitive: false,
            ).firstMatch(line)) !=
            null) {
          add('tempo', double.tryParse(match![1] ?? match[2]!));
        } else if ((match = RegExp(
              r'^time\s+signature\s*[:=-]\s*([1-9]\d?/(?:1|2|4|8|16|32|64))$',
              caseSensitive: false,
            ).firstMatch(line)) !=
            null) {
          add('timeSignature', match![1]);
        }
      }
    }
    final structured = sanitizeMetadata({
      'key': meta['tonality'] ?? tab['tonality_name'],
      'capo': meta['capo'],
      'tuning': clean(jsonMap(meta['tuning'])['value'])?.split(RegExp(r'\s+')),
      'difficulty':
          view['ug_difficulty'] ?? meta['difficulty'] ?? tab['difficulty'],
      'artworkUrl':
          httpsUrl(covers['large']) ??
          httpsUrl(covers['medium']) ??
          httpsUrl(covers['small']),
      'genre': view['song_genre'],
      'recording': [
        if (recording['is_acoustic'] == 1) 'Acoustic',
        if (clean(recording['performance']) != null)
          clean(recording['performance'])!,
      ].join(' · '),
      'mediaLinks': [
        {
          'kind': 'sheet',
          'label': 'Ultimate Guitar',
          'url': 'https://tabs.ultimate-guitar.com$path',
        },
        for (final url
            in recording['video_urls'] is List ? recording['video_urls'] : [])
          {'kind': 'video', 'label': 'Recording video', 'url': url},
      ],
      'credits': [
        {'role': 'Transcriber', 'name': tab['username']},
      ],
    });
    return sanitizeMetadata({...preamble, ...structured});
  }

  static SourceResult parsePage(String source, String requestedId) {
    final path = _chartPath(requestedId, 'ultimateguitar', selection: true),
        document = parseHtml(source),
        data = _data(source, document);
    final tab = object(data['tab']), view = object(data['tab_view']);
    if (tab['id'].toString() != _pathId(path) ||
        _pathId(
              _chartPath(requiredText(tab['tab_url'], 1500), 'ultimateguitar'),
            ) !=
            _pathId(path)) {
      throw const ProviderException('invalid_response');
    }
    final canonical = document
        .querySelector('link[rel="canonical"]')
        ?.attributes['href'];
    if (canonical != null &&
        _pathId(_chartPath(canonical, 'ultimateguitar')) != _pathId(path)) {
      throw const ProviderException('invalid_response');
    }
    if (tab['type'] != 'Chords' ||
        tab['tab_access_type'] != 'public' ||
        view['blocked'] == true) {
      throw const ProviderException('unavailable');
    }
    final body = parseText(
      requiredText(jsonMap(view['wiki_tab'])['content'], 200000),
    );
    final song = _song(tab, path, metadata: _metadata(tab, view, path));
    return SourceResult(
      candidate: song,
      body: body,
      metadata: song.metadata,
      attribution: 'Ultimate Guitar',
      retrievedAt: DateTime.now().toUtc(),
      extra: {'rights': scrapedRights(song.url, 'Ultimate Guitar')},
    );
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => parseSearch(
    await http.getText(
      Uri.https('www.ultimate-guitar.com', '/search.php', {
        'search_type': 'title',
        'value': queryText(query),
      }),
      cancel: cancel,
    ),
  );
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final path = _chartPath(candidate.id, 'ultimateguitar', selection: true);
    return parsePage(
      await http.getText(
        Uri.parse('https://tabs.ultimate-guitar.com$path'),
        cancel: cancel,
      ),
      path,
    );
  }
}

class _UgRow {
  const _UgRow(
    this.text,
    this.residual,
    this.inline,
    this.positions,
    this.inlinePositions,
    this.opensTab,
    this.closesTab,
  );
  final String text, residual, inline;
  final List<({int offset, String symbol})> positions, inlinePositions;
  final bool opensTab, closesTab;
}
