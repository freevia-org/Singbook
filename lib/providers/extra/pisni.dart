import 'dart:convert';
import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'package:html/dom.dart' as dom;
import '../../domain/arrangement.dart' show chordPattern;
import '../provider.dart';
import 'common.dart';

/// A document/arrangement catalog, never a recording authority. Deliberately
/// unregistered until native, catalog, persistence and app qualification pass.
class PisniProvider implements LyricsProvider, ContextualLyricsSearch {
  PisniProvider(this.transport, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final ProviderTransport transport;
  final DateTime Function() _clock;
  final _pages = <String, _Page>{};
  static const _host = 'www.pisni.org.ua';
  static final _id = RegExp(r'^[1-9]\d{0,9}$');
  static const _limit = 1024 * 1024;
  static const notationEvidence = 'https://www.pisni.org.ua/articles/11.html';
  @override
  final definition = const ProviderDefinition(
    id: 'pisni',
    name: 'Українські пісні',
    capabilities: {'catalog', 'lyrics', 'chords', 'metadata'},
    accessMode: 'publicPage',
    enabledByDefault: false,
    website: 'https://www.pisni.org.ua/',
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final q = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (q.isEmpty || q.length > 200) {
      throw const ProviderException('invalid_query');
    }
    // The observed publisher form has maxlength20 and Windows-1251 charset.
    // A broad prefix is a lookup hint; full identity is checked at resolution.
    final seed = q.characters.take(20).toString();
    final uri = Uri.parse(
      'https://$_host/search.php?phrase=${_form(seed)}&obj=s',
    );
    final bytes = await transport.getBytes(
      uri,
      cancel: cancel,
      maxBytes: _limit,
      allowedHosts: {_host},
    );
    cancel?.throwIfCancelled();
    final text = _decode(bytes);
    throwIfBlocked(text);
    final doc = parseHtml(text);
    final found = <String, SongCandidate>{};
    for (final anchor in doc.querySelectorAll('a[href]')) {
      cancel?.throwIfCancelled();
      final id = _linkId(anchor.attributes['href'], 'songs');
      if (id == null || found.containsKey(id)) continue;
      final copy = anchor.clone(true);
      // Editorial subtitle is a separate DOM node, not part of the title.
      final editorial = copy.querySelector('.smcont')?.text.trim();
      copy.querySelectorAll('.smcont').forEach((node) => node.remove());
      final title = _identity(copy.text);
      if (title.isEmpty) continue;
      found[id] = SongCandidate(
        providerId: 'pisni',
        id: id,
        title: title,
        artist: '',
        url: _url(id),
        metadata: {
          'identityScope': 'arrangement',
          'language': 'uk',
          if (editorial != null && editorial.isNotEmpty)
            'sourceEditorialDescription': editorial,
        },
        extra: {
          'pisni': {
            'searchResponseSha256': sha256.convert(bytes).toString(),
            'searchQuery': q,
            'wireQuery': seed,
          },
        },
      );
      if (found.length == 12) break;
    }
    cancel?.throwIfCancelled();
    return found.values.toList();
  }

  @override
  bool canReuseSearchForSelection(
    SongCandidate selection,
    List<SongCandidate> candidates,
  ) => false;

  @override
  Future<List<SongCandidate>> searchForSelection(
    SongCandidate selection, {
    required String fallbackQuery,
    CancellationToken? cancel,
  }) async {
    final rows = await search(selection.title, cancel: cancel);
    if (selection.artist.trim().isEmpty) return rows;
    final found = <SongCandidate>[];
    // No document crawl: inspect at most three exact-title source variants.
    for (final row
        in rows
            .where((r) => normalized(r.title) == normalized(selection.title))
            .take(3)) {
      final page = await _page(row.id, cancel);
      if (normalized(page.title) != normalized(row.title)) continue;
      for (final performer in page.performers) {
        if (normalized(performer['name'] as String) !=
            normalized(selection.artist)) {
          continue;
        }
        found.add(
          SongCandidate(
            providerId: 'pisni',
            id: row.id,
            title: page.title,
            artist: performer['name'] as String,
            url: row.url,
            metadata: {
              ...row.metadata,
              'pisniListedPerformerId': performer['id'],
              'artistCreditScope': 'publisherListedPerformer',
            },
            extra: row.extra,
          ),
        );
      }
      // Discovery resolves one source version. Once a listed performer has an
      // exact document match, do not fetch other same-title arrangements.
      if (found.isNotEmpty) break;
    }
    return found;
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    if (candidate.providerId != 'pisni' ||
        !_id.hasMatch(candidate.id) ||
        candidate.recordingIds.isNotEmpty ||
        candidate.album != null ||
        candidate.durationSeconds != null ||
        (candidate.url != null && candidate.url != _url(candidate.id))) {
      throw const ProviderException('invalid_selection');
    }
    final page = await _page(candidate.id, cancel);
    if (normalized(page.title) != normalized(candidate.title)) {
      throw const ProviderException('identity_mismatch');
    }
    if (candidate.artist.isNotEmpty) {
      final id = candidate.metadata['pisniListedPerformerId'];
      if (!page.performers.any(
        (p) =>
            p['id'] == id &&
            normalized(p['name'] as String) == normalized(candidate.artist),
      )) {
        throw const ProviderException('identity_mismatch');
      }
    } else if (candidate.metadata.containsKey('pisniListedPerformerId')) {
      throw const ProviderException('identity_mismatch');
    }
    final metadata = <String, dynamic>{
      'identityScope': 'arrangement',
      'language': 'uk',
      'credits': jsonDecode(jsonEncode(page.credits)),
      'performers': jsonDecode(jsonEncode(page.performers)),
      'unlinkedPerformerCredits': [...page.unlinkedPerformerCredits],
      'sourceFields': jsonDecode(jsonEncode(page.sourceFields)),
      'sourceVariantTexts': [...page.variantTexts],
      'sourceChordNotation': 'pisni-german',
      'chordNotation': 'english',
      'notationEvidenceUrl': notationEvidence,
      'sourceDocumentKind': 'sharedSongArrangement',
      'ambiguousSourceNoteRows': _ambiguousRows(page.originalBody),
    };
    final attribution = 'Українські пісні — ${_url(candidate.id)}';
    cancel?.throwIfCancelled();
    return SourceResult(
      candidate: SongCandidate(
        providerId: 'pisni',
        id: candidate.id,
        title: page.title,
        artist: candidate.artist,
        url: _url(candidate.id),
        metadata: {
          ...metadata,
          if (candidate.artist.isNotEmpty) ...{
            'pisniListedPerformerId':
                candidate.metadata['pisniListedPerformerId'],
            'artistCreditScope': 'publisherListedPerformer',
          },
        },
      ),
      body: _chordPro(page.originalBody),
      metadata: metadata,
      attribution: attribution,
      retrievedAt: page.at,
      extra: {
        'parserVersion': 'pisni-native-1',
        'sourceDocumentId': 'pisni:song:${candidate.id}',
        'rights': {
          'source': 'pisni',
          'sourceId': candidate.id,
          'sourceUrl': _url(candidate.id),
          'license': 'unknown',
          'attribution': attribution,
          'permissions': {'status': 'unknown'},
          'evidenceUrl': 'https://www.pisni.org.ua/articles/34.html',
        },
        'originalPayload': {
          'contentType': 'text/html',
          'encoding': 'windows-1251',
          'base64': base64Encode(page.bytes),
          'httpBodyBytesExact': true,
        },
        'pisni': {
          'originalPreformatted': page.originalBody,
          'sourcePageSha256': sha256.convert(page.bytes).toString(),
          'performersAreRecordingEvidence': false,
          'notationEvidenceUrl': notationEvidence,
          'sourceNotationRetained': true,
        },
      },
    );
  }

  Future<_Page> _page(String id, CancellationToken? cancel) async {
    if (!_id.hasMatch(id)) throw const ProviderException('invalid_selection');
    cancel?.throwIfCancelled();
    final prior = _pages[id];
    if (prior != null &&
        !_clock().isBefore(prior.at) &&
        _clock().difference(prior.at) < const Duration(minutes: 15)) {
      return prior;
    }
    final bytes = await transport.getBytes(
      Uri.parse(_url(id)),
      cancel: cancel,
      maxBytes: _limit,
      allowedHosts: {_host},
    );
    final text = _decode(bytes);
    throwIfBlocked(text);
    final doc = parseHtml(text);
    final headings = doc.querySelectorAll('h1');
    final bodies = doc.querySelectorAll('pre.songwords');
    if (headings.length != 1 || bodies.length != 1) {
      throw const ProviderException('extraction_failed');
    }
    final title = _identity(headings.single.text);
    final body = _preText(bodies.single);
    final addresses = doc
        .querySelectorAll('div.smcont')
        .where((node) => node.text.trim().startsWith('Адреса цієї сторінки:'))
        .toList();
    if (addresses.length != 1 ||
        addresses.single.text.trim() != 'Адреса цієї сторінки: ${_url(id)}') {
      throw const ProviderException('identity_mismatch');
    }
    if (title.isEmpty || body.trim().isEmpty || body.length > 200 * 1024) {
      throw const ProviderException('invalid_response');
    }
    // Inspect the bounded header only: comments, media and user profiles below
    // the lyric block must never become artist or song metadata.
    final begin = text.toLowerCase().indexOf('<h1');
    final end = text.toLowerCase().indexOf('<pre', begin);
    if (begin < 0 || end < begin || end - begin > 64 * 1024) {
      throw const ProviderException('invalid_response');
    }
    final header = parseHtml(text.substring(begin, end));
    final credits = <Map<String, dynamic>>[];
    final performers = <Map<String, dynamic>>[];
    final unlinked = <String>[];
    var performerRows = false;
    for (final row
        in header
            .querySelectorAll('tr')
            .where((r) => r.querySelector('tr') == null)) {
      final labels = row
          .querySelectorAll('b')
          .map((b) => b.text.trim())
          .toList();
      if (labels.any((s) => s == 'Виконують:' || s == 'Виконує:')) {
        performerRows = true;
      } else if (labels.any((s) => s.endsWith(':'))) {
        performerRows = false;
      }
      for (final cell in row.querySelectorAll('td')) {
        final label = cell.querySelector('b')?.text.trim();
        final role = label == 'Слова:'
            ? 'lyricist'
            : label == 'Музика:'
            ? 'composer'
            : null;
        if (role == null) continue;
        final names = _people(cell);
        if (names.isEmpty) {
          final plain = _identity(cell.text.replaceFirst(label!, ''));
          if (plain.isNotEmpty) credits.add({'role': role, 'name': plain});
        } else {
          credits.addAll(names.map((p) => {'role': role, ...p}));
        }
      }
      if (credits.length > 60) {
        throw const ProviderException('invalid_response');
      }
      if (!performerRows) continue;
      final people = _people(row);
      final albums = row
          .querySelectorAll('a[href]')
          .where((a) => _linkId(a.attributes['href'], 'albums') != null)
          .toList();
      if (people.isEmpty &&
          !labels.any((s) => s == 'Виконують:' || s == 'Виконує:')) {
        final text = _identity(row.text);
        if (text.isNotEmpty) unlinked.add(text);
      }
      // An album is attached only to one explicitly listed performer row.
      for (final person in people) {
        performers.add({
          ...person,
          if (people.length == 1 && albums.length == 1)
            'album': {
              'id': _linkId(albums.single.attributes['href'], 'albums'),
              'title': _identity(albums.single.text),
            },
        });
      }
      if (performers.length > 40 || unlinked.length > 40) {
        throw const ProviderException('invalid_response');
      }
    }
    final page = _Page(
      title,
      body,
      bytes.toList(),
      _clock(),
      credits,
      performers,
      unlinked,
      _sourceFields(doc.querySelector('#songdatablock')),
      [
        for (final pre in doc.querySelectorAll('#songdatablock pre').take(8))
          _preText(pre),
      ],
    );
    cancel?.throwIfCancelled();
    _pages[id] = page;
    if (_pages.length > 24) _pages.remove(_pages.keys.first);
    return page;
  }

  static List<Map<String, dynamic>> _people(dom.Element node) => [
    for (final anchor in node.querySelectorAll('a[href]'))
      if (_linkId(anchor.attributes['href'], 'persons') case final id?)
        if (_identity(anchor.text).isNotEmpty)
          {
            'id': id,
            'name': _identity(anchor.text),
            'url': 'https://$_host/persons/$id.html',
          },
  ];
  static String _url(String id) => 'https://$_host/songs/$id.html';
  static String? _linkId(String? href, String kind) {
    if (href == null || href.length > 200) return null;
    final uri = Uri.tryParse(href);
    if (uri == null ||
        uri.hasFragment ||
        uri.hasQuery ||
        uri.userInfo.isNotEmpty ||
        (uri.hasScheme && uri.scheme != 'https') ||
        (uri.hasAuthority && (uri.host != _host || uri.hasPort))) {
      return null;
    }
    return RegExp('^/$kind/([1-9]\\d{0,9})\\.html\$').firstMatch(uri.path)?[1];
  }

  static String _identity(String text) =>
      text.length > 500 ? '' : boundedText(text, max: 500);
}

String _preText(dom.Node node) {
  if (node is dom.Text) return node.data;
  if (node is dom.Element && node.localName == 'br') return '\n';
  if (node is dom.Element &&
      {'script', 'style', 'iframe', 'form'}.contains(node.localName)) {
    throw const ProviderException('invalid_response');
  }
  return node.nodes.map(_preText).join();
}

String _escape(String text) => text
    .replaceAll('\\', '\\\\')
    .replaceAll('[', r'\[')
    .replaceAll(']', r'\]')
    .replaceAll('{', r'\{')
    .replaceAll('}', r'\}');

class _Page {
  _Page(
    this.title,
    this.originalBody,
    this.bytes,
    this.at,
    this.credits,
    this.performers,
    this.unlinkedPerformerCredits,
    this.sourceFields,
    this.variantTexts,
  );
  final String title, originalBody;
  final List<int> bytes;
  final DateTime at;
  final List<Map<String, dynamic>> credits, performers;
  final List<String> unlinkedPerformerCredits;
  final List<Map<String, dynamic>> sourceFields;
  final List<String> variantTexts;
}

List<Map<String, dynamic>> _sourceFields(dom.Element? block) {
  if (block == null) return [];
  if (block.text.length > 64 * 1024) {
    throw const ProviderException('invalid_response');
  }
  const labels = {
    'Ключові слова',
    'Підбір акордів',
    'Рік написаня',
    'Рік написання',
    'Джерело',
    'Примітки',
    'Варіант тексту за джерелом 3',
    'Стаття про авторство цієї пісні',
  };
  final result = <Map<String, dynamic>>[];
  String? current;
  var text = StringBuffer();
  var links = <String>[];
  void flush() {
    if (current != null && text.toString().trim().isNotEmpty) {
      result.add({
        'label': current,
        'text': text.toString().trim(),
        if (links.isNotEmpty) 'links': links.toSet().toList(),
      });
    }
    current = null;
    text = StringBuffer();
    links = [];
  }

  void walk(dom.Node node) {
    if (node is dom.Element) {
      final value = node.text.trim();
      if (node.localName == 'b' && value.endsWith(':')) {
        flush();
        final label = value.substring(0, value.length - 1);
        if (labels.contains(label)) current = label;
        return;
      }
      if (node.localName == 'a') {
        if (current == 'Підбір акордів') {
          // A linked account name is a musical credit only when the URL
          // identifies an actual publisher account, not an off-site lookalike.
          if (_isUserLink(node.attributes['href'])) text.write(node.text);
          return;
        }
        if (_isUserLink(node.attributes['href'])) {
          return;
        }
        final link = resolvedLink(
          Uri.parse('https://www.pisni.org.ua/'),
          node.attributes['href'],
        );
        if (current != null && link != null) links.add(link);
      }
      if ({'script', 'style', 'iframe', 'form'}.contains(node.localName)) {
        return;
      }
      if (node.localName == 'br' && current != null) text.write('\n');
    }
    if (node is dom.Text && current != null) text.write(node.data);
    for (final child in node.nodes) {
      walk(child);
    }
  }

  walk(block);
  flush();
  return result;
}

bool _isUserLink(String? href) {
  if (href == null || href.length > 200) return false;
  // Match the original attribute: Uri normalizes an explicit HTTPS port 443.
  final match = RegExp(
    r'^(?:https://www\.pisni\.org\.ua)?/users/[1-9]\d{0,9}\.html$',
  ).firstMatch(href);
  return match != null && match.end == href.length;
}

// Explicit Windows-1251 table, with the undefined byte rejected. No lossy
// UTF-8/Latin-1 fallback may corrupt Ukrainian identities or original text.
const _high = <int>[
  0x402,
  0x403,
  0x201a,
  0x453,
  0x201e,
  0x2026,
  0x2020,
  0x2021,
  0x20ac,
  0x2030,
  0x409,
  0x2039,
  0x40a,
  0x40c,
  0x40b,
  0x40f,
  0x452,
  0x2018,
  0x2019,
  0x201c,
  0x201d,
  0x2022,
  0x2013,
  0x2014,
  -1,
  0x2122,
  0x459,
  0x203a,
  0x45a,
  0x45c,
  0x45b,
  0x45f,
  0xa0,
  0x40e,
  0x45e,
  0x408,
  0xa4,
  0x490,
  0xa6,
  0xa7,
  0x401,
  0xa9,
  0x404,
  0xab,
  0xac,
  0xad,
  0xae,
  0x407,
  0xb0,
  0xb1,
  0x406,
  0x456,
  0x491,
  0xb5,
  0xb6,
  0xb7,
  0x451,
  0x2116,
  0x454,
  0xbb,
  0x458,
  0x405,
  0x455,
  0x457,
];
String _decode(List<int> bytes) {
  final result = <int>[];
  for (final byte in bytes) {
    final code = byte < 128
        ? byte
        : byte >= 192
        ? byte + 0x350
        : _high[byte - 128];
    if (code < 0) throw const ProviderException('invalid_response', 'charset');
    result.add(code);
  }
  final text = String.fromCharCodes(result);
  if (!RegExp(
    r'charset\s*=\s*["\x27]?windows-1251',
    caseSensitive: false,
  ).hasMatch(text.substring(0, text.length.clamp(0, 4096)))) {
    throw const ProviderException('invalid_response', 'charset');
  }
  return text;
}

String _form(String text) {
  final result = StringBuffer();
  for (final code in text.runes) {
    final index = _high.indexOf(code);
    final byte = code < 128
        ? code
        : code >= 0x410 && code <= 0x44f
        ? code - 0x350
        : index >= 0
        ? index + 128
        : -1;
    if (byte < 0) throw const ProviderException('invalid_query', 'charset');
    if (byte == 32) {
      result.write('+');
    } else if (byte >= 65 && byte <= 90 ||
        byte >= 97 && byte <= 122 ||
        byte >= 48 && byte <= 57 ||
        '-_.~'.codeUnits.contains(byte)) {
      result.writeCharCode(byte);
    } else {
      result.write('%${byte.toRadixString(16).padLeft(2, '0').toUpperCase()}');
    }
  }
  return result.toString();
}

String? _chord(String source) {
  final match = RegExp(r'^([A-GH])([#b♯♭Ь]?)(.*)$').firstMatch(source);
  if (match == null || source.length > 40) return null;
  String root = match[1]!;
  var accidental = match[2]!.replaceAll('Ь', 'b');
  if (root == 'B' && accidental.isNotEmpty) return null;
  root = root == 'B'
      ? 'Bb'
      : root == 'H'
      ? 'B'
      : root;
  var suffix = match[3]!;
  final slash = suffix.indexOf('/');
  if (slash >= 0) {
    final bass = _chord(suffix.substring(slash + 1));
    if (bass == null || !RegExp(r'^[A-G][#b♯♭]*$').hasMatch(bass)) return null;
    suffix = '${suffix.substring(0, slash)}/$bass';
  }
  final result = '$root$accidental$suffix';
  final checked = chordPattern.firstMatch('[$result]');
  return checked?.start == 0 && checked?.end == result.length + 2
      ? result
      : null;
}

List<Map<String, dynamic>> _ambiguousRows(String source) {
  final result = <Map<String, dynamic>>[];
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (RegExp(r'^[A-GHАВСЕН]$').hasMatch(lines[i].trimRight())) {
      result.add({
        'line': i,
        'sourceText': lines[i],
        'handling': 'literal_preserved_not_transposed',
      });
      if (result.length > 64) {
        throw const ProviderException('invalid_response', 'ambiguous_layout');
      }
    }
  }
  return result;
}

List<({int column, String chord})>? _chords(String line) {
  final matches = RegExp(r'\S+').allMatches(line).toList();
  if (matches.isEmpty) return null;
  // Cyrillic letters are words, not Latin chord aliases. A bare unindented
  // Latin note can also be a lyric: preserve it rather than consume its line.
  if (matches.length == 1 &&
      matches.single.start == 0 &&
      RegExp(r'^[A-GH]$').hasMatch(matches.single[0]!)) {
    return null;
  }
  final result = <({int column, String chord})>[];
  for (final match in matches) {
    final token = match[0]!;
    if (RegExp(r'^[|/:\-]+$').hasMatch(token)) continue;
    final chord = _chord(token);
    if (chord == null) return null;
    result.add((
      column: line.substring(0, match.start).characters.length,
      chord: chord,
    ));
  }
  return result.isEmpty ? null : result;
}

String _chordPro(String source) {
  final lines = source
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  if (lines.any((line) => line.length > 4000 || line.contains('\t'))) {
    throw const ProviderException('invalid_response', 'unsupported_layout');
  }
  final output = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final row = _chords(lines[i]);
    if (row == null) {
      output.add(_escape(lines[i]));
      continue;
    }
    if (i + 1 < lines.length &&
        lines[i + 1].trim().isNotEmpty &&
        _chords(lines[i + 1]) == null) {
      final lyric = lines[++i].characters.toList();
      final rendered = StringBuffer();
      var at = 0;
      for (final token in row) {
        final column = token.column.clamp(0, lyric.length);
        rendered.write(_escape(lyric.sublist(at, column).join()));
        rendered.write('[${token.chord}]');
        at = column;
      }
      rendered.write(_escape(lyric.sublist(at).join()));
      output.add(rendered.toString());
    } else {
      var at = 0;
      final rendered = StringBuffer();
      for (final token in RegExp(r'\S+').allMatches(lines[i])) {
        rendered.write(_escape(lines[i].substring(at, token.start)));
        final chord = _chord(token[0]!);
        rendered.write(chord == null ? _escape(token[0]!) : '[$chord]');
        at = token.end;
      }
      rendered.write(_escape(lines[i].substring(at)));
      output.add(rendered.toString());
    }
  }
  return output.join('\n');
}
