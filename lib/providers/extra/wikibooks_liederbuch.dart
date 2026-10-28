import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:html/dom.dart' as dom;

import '../../domain/arrangement.dart' show chordPattern;
import '../../domain/models.dart';
import '../provider.dart';
import 'common.dart';

/// Individual, revision-attributed song sheets from the German Wikibooks book.
/// This source-only proposal is deliberately absent from the compiled registry.
class WikibooksLiederbuchProvider implements LyricsProvider {
  WikibooksLiederbuchProvider(this.transport, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ProviderTransport transport;
  final DateTime Function() _clock;
  static const _host = 'de.wikibooks.org';
  static const _prefix = 'Liederbuch/';
  static const _license = 'https://creativecommons.org/licenses/by-sa/4.0/';
  static const _maxResponseBytes = 2 * 1024 * 1024;
  static const _maxCacheBytes = 4 * 1024 * 1024;
  static const _lifetime = Duration(minutes: 15);
  final _cache = <String, _WikiBytes>{};
  var _cacheBytes = 0;

  @override
  final definition = const ProviderDefinition(
    id: 'wikibooksliederbuch',
    name: 'Wikibooks Liederbuch',
    capabilities: {'catalog', 'lyrics', 'chords', 'metadata'},
    enabledByDefault: false,
    accessMode: 'publicApi',
    website: 'https://de.wikibooks.org/wiki/Liederbuch',
  );

  Future<_WikiReply> _api(
    Map<String, String> parameters,
    CancellationToken? cancel,
  ) async {
    cancel?.throwIfCancelled();
    final uri = Uri.https(_host, '/w/api.php', {
      'format': 'json',
      'formatversion': '2',
      'maxlag': '5',
      ...parameters,
    });
    final previous = _cache[uri.toString()];
    late final Uint8List bytes;
    late final DateTime at;
    if (previous != null && _clock().isBefore(previous.expiresAt)) {
      bytes = previous.bytes;
      at = previous.at;
    } else {
      // Each cold caller owns its cancellation; no transport future is shared.
      bytes = await transport.getBytes(
        uri,
        allowedHosts: {_host},
        maxBytes: _maxResponseBytes,
        cancel: cancel,
      );
      at = _clock().toUtc();
    }
    cancel?.throwIfCancelled();
    late final JsonMap data;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const ProviderException('invalid_response');
      }
      _validateJson(decoded);
      data = decoded;
    } on FormatException {
      throw const ProviderException('invalid_response');
    } on StackOverflowError {
      throw const ProviderException('invalid_response');
    }
    throwIfApiError(data);
    return _WikiReply(uri, bytes, data, at);
  }

  void _remember(_WikiReply reply) {
    final key = reply.uri.toString();
    final revision = jsonMap(reply.data['parse'])['revid'];
    final old = _cache[key];
    if (old != null &&
        old.revision != null &&
        revision is int &&
        revision < old.revision!) {
      return;
    }
    if (old != null) _cacheBytes -= old.bytes.length;
    _cache.remove(key);
    _cache[key] = _WikiBytes(
      reply.bytes,
      reply.at,
      reply.at.add(_lifetime),
      revision is int ? revision : null,
    );
    _cacheBytes += reply.bytes.length;
    while (_cache.length > 16 || _cacheBytes > _maxCacheBytes) {
      _cacheBytes -= _cache.remove(_cache.keys.first)!.bytes.length;
    }
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final phrase = queryText(query);
    final reply = await _api({
      'action': 'query',
      'list': 'search',
      'srsearch': '$phrase prefix:$_prefix',
      'srnamespace': '0',
      'srlimit': '10',
    }, cancel);
    final rows = jsonMap(reply.data['query'])['search'];
    if (rows is! List || rows.length > 10) {
      throw const ProviderException('invalid_response');
    }
    final found = <int, SongCandidate>{};
    final conflicting = <int>{};
    for (final row in rows) {
      if (row is! Map || row['ns'] != 0 || !_pageId(row['pageid'])) continue;
      final pageId = row['pageid'] as int;
      final pageTitle = row['title'];
      final title = _songTitle(pageTitle);
      if (title == null || conflicting.contains(pageId)) continue;
      final previous = found[pageId];
      if (previous != null && previous.metadata['wikibooksPageTitle'] != pageTitle) {
        found.remove(pageId);
        conflicting.add(pageId);
        continue;
      }
      found[pageId] = SongCandidate(
        providerId: definition.id,
        id: pageId.toString(),
        title: title,
        artist: '',
        url: _pageUrl(pageId),
        metadata: {
          'identityScope': 'arrangement',
          'wikibooksPageId': pageId,
          'wikibooksPageTitle': pageTitle,
        },
        extra: {'wikibooksSearchRow': Map<String, dynamic>.from(row)},
      );
    }
    cancel?.throwIfCancelled();
    _remember(reply);
    return found.values.toList();
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final pageId = int.tryParse(candidate.id);
    if (candidate.providerId != definition.id ||
        !RegExp(r'^[1-9]\d{0,9}$').hasMatch(candidate.id) ||
        !_pageId(pageId) ||
        candidate.title.trim().isEmpty) {
      throw const ProviderException('user_selection_required');
    }
    final reply = await _api({
      'action': 'parse',
      'pageid': pageId.toString(),
      'prop': 'text|revid|categories|properties|displaytitle',
    }, cancel);
    final parsed = jsonMap(reply.data['parse']);
    final title = _songTitle(parsed['title']);
    if (parsed['pageid'] != pageId ||
        title == null ||
        title != candidate.title.trim()) {
      throw const ProviderException('identity_mismatch');
    }
    final revision = parsed['revid'];
    final rawCategories = parsed['categories'];
    final html = parsed['text'];
    if (revision is! int || revision <= 0 ||
        rawCategories is! List || rawCategories.length > 200 ||
        html is! String || utf8.encode(html).length > _maxResponseBytes) {
      throw const ProviderException('invalid_response');
    }
    final categories = <String>[];
    for (final item in rawCategories) {
      if (item is! Map || item['category'] is! String) {
        throw const ProviderException('invalid_response');
      }
      categories.add(_text(item['category'] as String, max: 300));
    }
    final normalizedCategories = categories.map(_category).toSet();
    if (!normalizedCategories.contains('Liederbuch/ Lieder')) {
      throw const ProviderException('unavailable');
    }
    final german = normalizedCategories.contains('Liederbuch/ Lieder auf Deutsch');
    final english = normalizedCategories.contains('Liederbuch/ Lieder auf Englisch');
    final notation = german && !english
        ? 'german'
        : english && !german
        ? 'international'
        : 'unverified';
    final document = parseHtml(html);
    final poems = document.querySelectorAll('.poem')
        .where((poem) => !_hasPoemAncestor(poem)).toList();
    if (poems.isEmpty) throw const ProviderException('unavailable');
    if (poems.length > 20 || poems.any((p) => htmlTooDeep(p, 80))) {
      throw const ProviderException('invalid_response');
    }
    final blocks = <JsonMap>[];
    final unparsed = <JsonMap>[];
    final headings = <dom.Element, String>{};
    String? sectionHeading;
    for (final element in document.querySelectorAll('h1,h2,h3,h4,h5,h6,.poem')) {
      if (_hasPoemAncestor(element)) continue;
      if (element.classes.contains('poem')) {
        if (sectionHeading != null) headings[element] = sectionHeading;
      } else {
        final clone = element.clone(true);
        for (final editLink in clone.querySelectorAll('.mw-editsection')) {
          editLink.remove();
        }
        sectionHeading = _text(clone.text, max: 500);
      }
    }
    for (var index = 0; index < poems.length; index++) {
      final body = _poemBody(poems[index], notation, index, unparsed);
      if (body.isEmpty) continue;
      blocks.add({
        'index': index,
        if (headings[poems[index]] case final heading?) 'sourceHeading': heading,
        'body': body,
      });
    }
    final sections = <String>[];
    String? previousHeading;
    for (final block in blocks) {
      final heading = block['sourceHeading'] as String?;
      if (heading != null && heading.isNotEmpty && heading != title && heading != previousHeading) {
        sections.add(_comment(heading));
      }
      sections.add(block['body'] as String);
      previousHeading = heading;
    }
    final body = sections.join('\n\n');
    if (body.isEmpty) throw const ProviderException('unavailable');
    if (body.length > 256 * 1024) throw const ProviderException('invalid_response');
    requireSongText(body);
    final credits = _sourceCredits(document);
    final pageTitle = parsed['title'] as String;
    final url = _pageUrl(pageId!);
    final permalink = Uri.https(_host, '/w/index.php', {
      'title': pageTitle,
      'oldid': revision.toString(),
    }).toString();
    final metadata = <String, dynamic>{
      'identityScope': 'arrangement',
      'wikibooksPageId': pageId,
      'wikibooksPageTitle': pageTitle,
      'wikibooksRevisionId': revision,
      'wikibooksCategories': categories,
      'sourceChordNotation': notation,
      if (german && !english) 'language': 'de',
      if (english && !german) 'language': 'en',
      ...credits,
    };
    final found = SongCandidate(
      providerId: definition.id,
      id: pageId.toString(),
      title: title,
      artist: '',
      url: url,
      metadata: metadata,
    );
    final attribution =
        'Wikibooks contributors — $pageTitle — revision $revision — $permalink; '
        'page contributions: CC BY-SA 4.0 ($_license); '
        'lyric/chord markup converted to ChordPro; original API response retained';
    final evidence = sourceEvidence(
      found,
      license: 'unknown',
      attribution: attribution,
      revision: revision.toString(),
      evidenceUrl: permalink,
      permissions: {
        'status': 'field_specific',
        'pageContributions': 'CC-BY-SA-4.0',
        'pageContributionsLicenseUrl': _license,
        'underlyingLyricsAndMusic': 'unknown',
      },
      provenanceNote:
          'The Wikibooks contribution license is distinct from underlying '
          'song rights. Lyrics, chord markup and layout are normalized into '
          'ChordPro with source credits and exact original bytes retained. '
          'No performer, recording, verified timing or musical accuracy is inferred.',
    );
    (evidence['rights'] as Map<String, dynamic>)['revision'] = revision;
    final result = SourceResult(
      candidate: found,
      body: body,
      metadata: metadata,
      attribution: attribution,
      retrievedAt: reply.at,
      extra: {
        ...evidence,
        'parserVersion': 'wikibooks-liederbuch-1',
        'sourceUrl': url,
        'originalPayload': {
          'contentType': 'application/json',
          'encoding': 'utf-8',
          'base64': base64Encode(reply.bytes),
          'sha256': sha256.convert(reply.bytes).toString(),
          'httpBodyBytesExact': true,
        },
        'unparsedChordAnnotations': unparsed,
        'wikibooks': {
          'pageId': pageId,
          'pageTitle': pageTitle,
          'revision': revision,
          'permalink': permalink,
          'historyUrl': Uri.https(_host, '/w/index.php', {
            'title': pageTitle,
            'action': 'history',
          }).toString(),
          'categories': categories,
          'properties': parsed['properties'],
          'lyricBlocks': blocks,
          'footnotes': [
            for (final note in document.querySelectorAll('.references .reference-text').take(20))
              _text(note.text, max: 4000),
          ],
          'contributionLicense': 'CC-BY-SA-4.0',
          'contributionLicenseUrl': _license,
        },
      },
    );
    cancel?.throwIfCancelled();
    _remember(reply);
    return result;
  }
}

bool _pageId(Object? value) => value is int && value > 0 && value <= 0xffffffff;

String _pageUrl(int id) => Uri.https('de.wikibooks.org', '/', {
  'curid': id.toString(),
}).toString();

String? _songTitle(Object? value) {
  if (value is! String || value.length > 400 || !value.startsWith('Liederbuch/')) return null;
  if (RegExp(r'[\x00-\x1f\x7f#\[\]{}<>|]').hasMatch(value)) return null;
  final title = value.substring('Liederbuch/'.length).trim();
  return title.isEmpty || title.length > 300 ? null : title;
}

String _category(String value) => value.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

String _text(String value, {int max = 1000}) {
  if (value.length > max || RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(value)) {
    throw const ProviderException('invalid_response');
  }
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _literal(String value) => value.replaceAllMapped(
  RegExp(r'[\\\[\]{}#]'),
  (match) => '\\${match[0]}',
);

String _comment(String value) =>
    '{comment: ${value.replaceAll(RegExp(r'[{}\\\r\n]'), ' ')}}';

bool _hasPoemAncestor(dom.Element element) {
  for (dom.Node? parent = element.parentNode; parent != null; parent = parent.parentNode) {
    if (parent is dom.Element && parent.classes.contains('poem')) return true;
  }
  return false;
}

bool _chordTemplate(dom.Element element) {
  if (element.localName != 'span') return false;
  final style = (element.attributes['style'] ?? '').toLowerCase().replaceAll(RegExp(r'\s'), '');
  return style.contains('vertical-align:50%') &&
      style.contains('font-family:sans-serif') && style.contains('font-weight:bold');
}

bool _layoutBracket(dom.Element element) {
  if (element.localName != 'span' || !{'[', ']'}.contains(element.text.trim())) return false;
  final style = (element.attributes['style'] ?? '').toLowerCase().replaceAll(RegExp(r'\s'), '');
  return style.contains('font-size:0.1em') &&
      (style.contains('color:#fff;') || style.endsWith('color:#fff') ||
       style.contains('color:white;') || style.endsWith('color:white'));
}

String? _chord(String bracket, String notation) {
  final match = RegExp(r'^\[([^\]\r\n]{1,60})\]$').firstMatch(bracket.trim());
  if (match == null) return null;
  final original = match[1]!;
  bool valid(String value) {
    final text = '[$value]';
    final full = chordPattern.firstMatch(text);
    return full != null && full.start == 0 && full.end == text.length;
  }
  final withoutH = original.replaceAllMapped(
    RegExp(r'(^|/)H'),
    (m) => '${m[1]}B',
  );
  if (notation == 'international') {
    if (withoutH != original && valid(withoutH)) {
      throw const ProviderException('unsupported_chord_notation');
    }
    return valid(original) ? original : null;
  }
  if (notation == 'unverified') {
    if (RegExp(r'(^|/)[BH]').hasMatch(original) && valid(withoutH)) {
      throw const ProviderException('unsupported_chord_notation');
    }
    return valid(original) ? original : null;
  }
  if (RegExp(r'(^|/)B[#b♯♭]').hasMatch(original) && valid(withoutH)) {
    throw const ProviderException('unsupported_chord_notation');
  }
  final german = original.replaceAllMapped(
    RegExp(r'(^|/)([HB])'),
    (m) => '${m[1]}${m[2] == 'H' ? 'B' : 'Bb'}',
  );
  return valid(german) ? german : null;
}

String _poemBody(dom.Element poem, String notation, int block, List<JsonMap> unparsed) {
  final output = StringBuffer();
  void walk(dom.Node node) {
    if (node is dom.Text) {
      if (RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(node.data)) {
        throw const ProviderException('invalid_response');
      }
      output.write(_literal(node.data.replaceAll(RegExp(r'\s+'), ' ')));
      return;
    }
    if (node is! dom.Element) return;
    final tag = node.localName;
    if (tag == 'nav' || node.attributes['role'] == 'navigation') return;
    if ({'script', 'style', 'iframe', 'form', 'object', 'embed', 'svg', 'math', 'img'}.contains(tag)) {
      throw const ProviderException('invalid_response');
    }
    if (_layoutBracket(node) || (tag == 'sup' && node.classes.contains('reference'))) return;
    if ({'h1', 'h2', 'h3', 'h4', 'h5', 'h6'}.contains(tag)) {
      output.write('\n${_comment(_text(node.text, max: 500))}\n');
      return;
    }
    if (tag == 'br') {
      output.write('\n');
      return;
    }
    if (_chordTemplate(node)) {
      final raw = node.text.trim();
      final chord = _chord(raw, notation);
      if (chord == null) {
        unparsed.add({'block': block, 'sourceToken': raw});
        output.write(_literal(raw));
      } else {
        output.write('[$chord]');
      }
      return;
    }
    for (final child in node.nodes) {
      walk(child);
    }
    if ({'p', 'dl', 'dd', 'dt', 'div', 'blockquote', 'li'}.contains(tag)) output.write('\n\n');
  }
  walk(poem);
  return output.toString()
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n[ \t]+'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

JsonMap _sourceCredits(dom.Document document) {
  final headers = <String>[];
  final fields = <String, List<String>>{};
  final creditLinks = <JsonMap>[];
  final labels = RegExp(r'\b(Alternativtitel:|Text:|Melodie:|Bearbeitung:|bearbeitet\s+von)\s*', caseSensitive: false);
  for (final paragraph in document.querySelectorAll('p')) {
    if (_hasPoemAncestor(paragraph)) continue;
    if (!paragraph.text.contains('Text:') || !paragraph.text.contains('Melodie:')) continue;
    final text = _text(paragraph.text, max: 8192);
    if (headers.length >= 8) throw const ProviderException('invalid_response');
    headers.add(text);
    for (final anchor in paragraph.querySelectorAll('a[href]')) {
      final label = _text(anchor.text, max: 500);
      final url = resolvedLink(Uri.https('de.wikibooks.org', '/'), anchor.attributes['href']);
      if (label.isNotEmpty && url != null && creditLinks.length < 40) {
        creditLinks.add({'label': label, 'url': url});
      }
    }
    final matches = labels.allMatches(text).toList();
    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      final key = match[1]!.toLowerCase().replaceAll(':', '').replaceAll(RegExp(r'\s+'), ' ');
      final value = text.substring(match.end, index + 1 < matches.length ? matches[index + 1].start : text.length).trim();
      if (value.isNotEmpty) (fields[key] ??= []).add(value);
    }
  }
  final textCredits = (fields['text'] ?? const <String>[]).toSet().toList();
  final melodyCredits = (fields['melodie'] ?? const <String>[]).toSet().toList();
  final arrangers = [...?fields['bearbeitung'], ...?fields['bearbeitet von']]
      .expand((value) => value.split(RegExp(r'\s+(?:und|&)\s+')))
      .map((value) => value.trim()).where((value) => value.isNotEmpty).toSet().toList();
  return {
    if (headers.isNotEmpty) 'sourceHeaderBlocks': headers,
    if (creditLinks.isNotEmpty) 'sourceCreditLinks': creditLinks,
    if (textCredits.length == 1) 'sourceTextCredit': textCredits.single,
    if (textCredits.length > 1) 'sourceTextCredits': textCredits,
    if (melodyCredits.length == 1) 'sourceMelodyCredit': melodyCredits.single,
    if (melodyCredits.length > 1) 'sourceMelodyCredits': melodyCredits,
    if (arrangers.isNotEmpty) 'sourceArrangerCredits': arrangers,
    if (fields['alternativtitel'] case final values?) 'sourceAlternativeTitles': values.toSet().toList(),
  };
}

void _validateJson(Object? value) {
  final pending = <(Object?, int)>[(value, 0)];
  var count = 0;
  while (pending.isNotEmpty) {
    final (item, depth) = pending.removeLast();
    if (++count > 20000 || depth > 16) throw const ProviderException('invalid_response');
    if (item is Map) {
      for (final child in item.values) pending.add((child, depth + 1));
    } else if (item is List) {
      for (final child in item) pending.add((child, depth + 1));
    }
  }
}

class _WikiReply {
  _WikiReply(this.uri, this.bytes, this.data, this.at);
  final Uri uri;
  final Uint8List bytes;
  final JsonMap data;
  final DateTime at;
}

class _WikiBytes {
  _WikiBytes(this.bytes, this.at, this.expiresAt, this.revision);
  final Uint8List bytes;
  final DateTime at, expiresAt;
  final int? revision;
}
